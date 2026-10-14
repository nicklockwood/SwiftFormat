// Created by Cal Stephens on 2025-09-16.
// Copyright © 2025 Airbnb Inc. All rights reserved.

import Foundation

public extension FormatRule {
    static let noForceUnwrapInTests = FormatRule(
        help: "Use XCTUnwrap or #require in test cases, rather than force unwrapping.",
        orderAfter: [.urlMacro, .noForceTryInTests, .throwingTests]
    ) { formatter in
        guard let testFramework = formatter.detectTestingFramework() else {
            return
        }

        // Find all of the test case functions in this file
        var testCases = [AutoUpdatingIndex]()
        formatter.forEach(.keyword("func")) { funcKeywordIndex, _ in
            guard let functionDecl = formatter.parseFunctionDeclaration(keywordIndex: funcKeywordIndex),
                  formatter.isTestCase(at: funcKeywordIndex, in: functionDecl, for: testFramework)
            else { return }

            testCases.append(funcKeywordIndex.autoUpdating(in: formatter))
        }

        guard !testCases.isEmpty else { return }

        // Collect all of the force unwrap operators. Doing this in its own `forEach`
        // ensures that `disable:next` directives are supported at individual `!` indices.
        var forceUnwrapOperators = [AutoUpdatingIndex]()
        formatter.forEach(.operator("!", .postfix)) { forceUnwrapOperator, _ in
            forceUnwrapOperators.append(forceUnwrapOperator.autoUpdating(in: formatter))
        }

        for testCase in testCases {
            guard let functionDecl = formatter.parseFunctionDeclaration(keywordIndex: testCase.index),
                  let bodyRange = functionDecl.bodyRange
            else { return }

            let forceUnwrapOperators = forceUnwrapOperators.filter { bodyRange.contains($0.index) }
            var convertedAnyForceUnwrapOperators = false

            for forceUnwrapOperator in forceUnwrapOperators {
                guard formatter.tokens[forceUnwrapOperator] == .operator("!", .postfix) else {
                    continue
                }

                // Re-parse the function declaration, since converting previous force unwraps changes its body range
                guard let functionDecl = formatter.parseFunctionDeclaration(keywordIndex: testCase.index) else {
                    continue
                }

                // Only convert the `!` if we are within the function body
                guard formatter.tryKeywordSupported(at: forceUnwrapOperator.index, in: functionDecl) else {
                    continue
                }

                // Preserve `try!`s, this is handled separately by the `noForceTryInTests` rule
                if let previousToken = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: forceUnwrapOperator),
                   formatter.tokens[previousToken] == .keyword("try")
                {
                    continue
                }

                // Skip if this is an implicitly unwrapped optional type annotation (e.g., let foo: Foo!)
                // Look for the pattern: (let|var) identifier : Type !
                if let colonIndex = formatter.lastIndex(of: .delimiter(":"), in: 0 ..< forceUnwrapOperator.index),
                   let _ = formatter.lastIndex(of: .keyword, in: 0 ..< colonIndex, if: { ["let", "var"].contains($0.string) })
                {
                    // Make sure there are no assignment operators between the colon and the !
                    // This distinguishes type annotations from variable assignments with IUO types
                    let hasAssignment = formatter.index(of: .operator("=", .infix), in: colonIndex ..< forceUnwrapOperator.index) != nil
                    if !hasAssignment {
                        continue
                    }
                }

                let infixOperand = formatter.parseInfixOperandContainingForceUnwrap(forceUnwrapOperator.index)

                guard let expressionRange = infixOperand?.autoUpdating(in: formatter)
                    ?? formatter.parseExpressionRangeContainingForceUnwrap(forceUnwrapOperator.index, in: functionDecl)
                else {
                    continue
                }

                // Convert all eligible ! operators in this expression to ? operators
                convertForceUnwrapsInExpression: for i in expressionRange.range.reversed() {
                    guard formatter.tokens[i] == .operator("!", .postfix),
                          formatter.tryKeywordSupported(at: i, in: functionDecl)
                    else { continue }

                    // Check if this force unwrap is in a function call or subscript call subexpression within this expression.
                    // If so, skip it. The `XCTUnwrap` / `#require` for the outer expression doesn't apply in this subexpression.
                    var currentStartOfScope = i

                    while let scopeStart = formatter.startOfScope(at: currentStartOfScope) {
                        // If we've gone outside the expression range, then we know this is not part of some subexpression.
                        if !expressionRange.range.contains(scopeStart) {
                            break
                        }

                        // Check if this is a function call or subscript call by looking at the token before the scope
                        if let prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: scopeStart) {
                            let prevToken = formatter.tokens[prevIndex]
                            if prevToken.isIdentifier || prevToken.isOperator(ofType: .postfix) || prevToken.isEndOfScope {
                                // Skip this operator, and continue to the next one.
                                continue convertForceUnwrapsInExpression
                            }
                        }

                        // Move to the next outer scope
                        currentStartOfScope = scopeStart
                    }

                    // If we are about to convert an `as!` to an `as?`, and the as? is part of a broader expression with a chained value
                    // like `(foo as! Bar).baaz`, we have to add an extra `?` after the enclosing parens: `(foo as? Bar)?.baaz`.
                    if let previousToken = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i),
                       formatter.tokens[previousToken] == .keyword("as"),
                       let tokenAfterAsParenScope = formatter.parseTokenAfterForceCastParenScope(asIndex: previousToken)
                    {
                        formatter.insert(.operator("?", .postfix), at: tokenAfterAsParenScope)
                    }

                    // If this is the last token in the expression, or the next token is is / as operator, remove the `!`
                    // rather than replacing it with a `?`.
                    var shouldRemoveForceUnwrap = false
                    if let nextToken = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i) {
                        if ["is", "as"].contains(formatter.tokens[nextToken].string) || !expressionRange.range.contains(nextToken) {
                            shouldRemoveForceUnwrap = true
                        }
                    } else {
                        shouldRemoveForceUnwrap = true
                    }

                    // Convert `try!`s within the unwrap expression to `try` instead of `try?`
                    if let previousToken = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i),
                       formatter.tokens[previousToken] == .keyword("try")
                    {
                        shouldRemoveForceUnwrap = true
                    }

                    if shouldRemoveForceUnwrap {
                        formatter.removeToken(at: i)
                    } else {
                        formatter.replaceToken(at: i, with: .operator("?", .postfix))
                    }
                }

                // An operand on the RHS of an operator is covered by the `try` at the start of the expression
                if infixOperand != nil {
                    // Use the token the tokenizer produces for `#require`, so later operands in this expression still parse
                    let wrapperTokens: [Token]
                    switch testFramework {
                    case .xcTest:
                        wrapperTokens = [.identifier("XCTUnwrap"), .startOfScope("(")]
                    case .swiftTesting:
                        wrapperTokens = [.keyword("#require"), .startOfScope("(")]
                    }

                    // Unlike `try XCTUnwrap(...)`, `-XCTUnwrap(...)` is valid, so insert after any prefix operator
                    let startsWithPrefixOperator = formatter.tokens[expressionRange.lowerBound].isOperator(ofType: .prefix)
                        && formatter.tokens[expressionRange.lowerBound] != .operator(".", .prefix)
                    let insertionIndex = startsWithPrefixOperator ? expressionRange.lowerBound + 1 : expressionRange.lowerBound

                    formatter.insert(.endOfScope(")"), at: expressionRange.upperBound + 1)
                    formatter.insert(wrapperTokens, at: insertionIndex)

                    convertedAnyForceUnwrapOperators = true
                    continue
                }

                // Whether or not the expression needs to be wrapped in `XCTUnwrap` / `#require`
                var needsUnwrapMethod = true

                // If this expression is the LHS of an assignment operator, changing `foo!.bar = baaz` to `foo?.bar = baaz` is a safe change as-is
                if let tokenAfterExpression = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: expressionRange.upperBound),
                   formatter.tokens[tokenAfterExpression] == .operator("=", .infix)
                {
                    needsUnwrapMethod = false
                }

                // If this expression is followed by ==, changing `foo!.bar == bar` to `foo?.bar == bar` is a safe change as-is
                if let tokenAfterExpression = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: expressionRange.upperBound),
                   formatter.tokens[tokenAfterExpression] == .operator("==", .infix)
                {
                    needsUnwrapMethod = false
                }

                // If this expression is within XCTAssertEqual or XCTAssertNil, changing `foo!.bar` to `foo?.bar` is a safe change as-is,
                // as long as this isn't a subexpression within a parent operator expression.
                if let containingParenScope = formatter.startOfScope(at: expressionRange.lowerBound),
                   formatter.tokens[containingParenScope] == .startOfScope("("),
                   let functionNameIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: containingParenScope),
                   formatter.tokens[functionNameIndex].isIdentifier,
                   let tokenAfterExpression = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: expressionRange.upperBound),
                   !formatter.tokens[tokenAfterExpression].isOperator
                {
                    let functionName = formatter.tokens[functionNameIndex].string
                    if functionName == "XCTAssertNil" {
                        needsUnwrapMethod = false
                    } else if functionName == "XCTAssertEqual" {
                        // Ensure this is `XCTAssertEqual(_:_:)`, not `XCTAssertEqual(_:_:accuracy:)` (which doesn't support optionals)
                        let arguments = formatter.parseFunctionCallArguments(startOfScope: containingParenScope)
                        if arguments.count == 2 {
                            needsUnwrapMethod = false
                        }
                    }
                }

                // If this expression is a standalone method call like `foo!.bar()`, then `foo?.bar()` works perfectly well.
                // Heuristic: If the scope containing this code is a code block, and the previous token is part of a completely
                // separate expression (or, the start of the function body), then this is a standalone expression.
                if let startOfScopeContainingExpression = formatter.startOfScope(at: expressionRange.lowerBound),
                   formatter.tokens[startOfScopeContainingExpression] == .startOfScope("{"),
                   let tokenBeforeExpression = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: expressionRange.lowerBound),
                   !formatter.tokens[tokenBeforeExpression].isOperator
                {
                    if tokenBeforeExpression == functionDecl.bodyRange?.lowerBound {
                        needsUnwrapMethod = false
                    }

                    if let previousExpressionRange = formatter.parseExpressionRange(endingAt: tokenBeforeExpression),
                       !previousExpressionRange.overlaps(expressionRange.range)
                    {
                        needsUnwrapMethod = false
                    }
                }

                // Wrap the expression in `try XCTUnwrap(...)` or `try #require(...)`
                if needsUnwrapMethod {
                    // If the expression starts with a prefix operator like !, we have to wrap the try expression in parens.
                    // `!try XCTUnwrap(...)` is not valid -- it needs to be `!(try XCTUnwrap(...))`.
                    let startsWithPrefixOperator = formatter.tokens[expressionRange.lowerBound].isOperator(ofType: .prefix)
                        && formatter.tokens[expressionRange.lowerBound] != .operator(".", .prefix)

                    let wrapperTokens: [Token]
                    switch testFramework {
                    case .xcTest:
                        wrapperTokens = [.keyword("try"), .space(" "), .identifier("XCTUnwrap"), .startOfScope("(")]
                    case .swiftTesting:
                        wrapperTokens = [.keyword("try"), .space(" "), .operator("#", .prefix), .identifier("require"), .startOfScope("(")]
                    }

                    let insertionIndex = startsWithPrefixOperator ? expressionRange.lowerBound + 1 : expressionRange.lowerBound

                    // Since we're processing right to left, we can insert without worrying about shifting indices
                    formatter.insert(.endOfScope(")"), at: expressionRange.upperBound + 1)
                    formatter.insert(wrapperTokens, at: insertionIndex)

                    if startsWithPrefixOperator {
                        formatter.insert(.endOfScope(")"), at: expressionRange.upperBound + 1)
                        formatter.insert(.startOfScope("("), at: insertionIndex)
                    }

                    convertedAnyForceUnwrapOperators = true
                }
            }

            // If we found any force unwraps, add a `throws` if it doesn't already exist
            if convertedAnyForceUnwrapOperators {
                formatter.addThrowsEffect(to: functionDecl)
            }
        }
    } examples: {
        """
        ```diff
          import Testing

          struct MyFeatureTests {
        -     @Test func myFeature() {
        -         let value = foo.bar!.value
        +     @Test func myFeature() throws {
        +         let value = try #require(foo.bar?.value)
              }
          }
        ```

        ```diff
          import XCTest

          class MyFeatureTests: XCTestCase {
        -     func testMyFeature() {
        -         let value = foo.bar!.value
        +     func testMyFeature() throws {
        +         let value = try XCTUnwrap(foo.bar?.value)
              }
          }
        ```
        """
    }
}

extension Formatter {
    /// Parses the expression range containing the given force unwrap index
    func parseExpressionRangeContainingForceUnwrap(
        _ forceUnwrapIndex: Int,
        in functionDecl: FunctionDeclaration?
    )
        -> AutoUpdatingRange?
    {
        // Parse the expression containing this force unwrap operator
        guard var expressionRange = parseExpressionRange(containing: forceUnwrapIndex)?.autoUpdating(in: self) else {
            return nil
        }

        while let asIndexNeedingExpansion = expressionRange.range.first(where: {
            guard let tokenAfterForceCastParenScope = parseTokenAfterForceCastParenScope(asIndex: $0) else { return false }
            return !expressionRange.range.contains(tokenAfterForceCastParenScope)
        }) {
            guard let tokenAfterForceCastParenScope = parseTokenAfterForceCastParenScope(asIndex: asIndexNeedingExpansion),
                  let expandedExpressionRange = parseExpressionRange(containing: tokenAfterForceCastParenScope)?.autoUpdating(in: self)
            else { return nil }

            expressionRange = expandedExpressionRange
        }

        // If there are infix operators in the expression, only handle the lhs of the first operator.
        // Force unwraps on the RHS are handled by `parseInfixOperandContainingForceUnwrap`.
        let firstInfixOperator = expressionRange.range.first(where: { i in
            if isInfixOperatorSeparatingOperands(at: i),
               let functionDecl,
               tryKeywordSupported(at: i, in: functionDecl),
               tokens[i] != .operator(".", .infix)
            {
                return true
            }

            return false
        })

        // Use only a valid subexpression from the LHS. To do this we parse the expression range only within a subformatter for the LHS.
        if let infixIndex = firstInfixOperator, let functionDecl {
            let lhsTokens = Array(tokens[expressionRange.lowerBound ..< infixIndex])
            let lhsFormatter = Formatter(lhsTokens)
            let lhsFormatterOffset = expressionRange.lowerBound

            guard let lhsForceUnwrapIndex = expressionRange.range.first(where: { i in
                tokens[i] == .operator("!", .postfix) && tryKeywordSupported(at: i, in: functionDecl) && i < infixIndex
            }) else { return nil }

            // Convert the absolute index to the sub-formatter's relative index
            let relativeIndex = lhsForceUnwrapIndex - lhsFormatterOffset

            // Get the expression range in the sub-formatter
            guard let subExpressionRange = lhsFormatter.parseExpressionRangeContainingForceUnwrap(relativeIndex, in: nil) else {
                return nil
            }

            // Convert the sub-formatter range back to absolute indices
            let absoluteRange = (subExpressionRange.lowerBound + expressionRange.lowerBound) ... (subExpressionRange.upperBound + expressionRange.lowerBound)
            expressionRange = absoluteRange.autoUpdating(in: self)
        }

        return expressionRange
    }

    /// Whether the token at the given index is an infix operator between two operands,
    /// including operator-like keywords like `is` and `as`, but not `as!`,
    /// which we want to handle by converting to `as?`.
    func isInfixOperatorSeparatingOperands(at index: Int) -> Bool {
        let token = tokens[index]

        if token.isOperator(ofType: .infix), token != .operator(".", .infix) {
            return true
        }

        if token == .keyword("is") {
            return true
        }

        if token == .keyword("as"),
           let nextToken = self.index(of: .nonSpaceOrLinebreak, after: index),
           tokens[nextToken] != .operator("!", .postfix)
        {
            return true
        }

        return false
    }

    /// If the given force unwrap is in an operand on the RHS of an infix operator, in an expression on a single line
    /// that starts with `try` (but not `try await`), returns the range of that operand. The `try` covers the whole expression, so the operand
    /// can be wrapped in `XCTUnwrap(...)` / `#require(...)` without its own `try`, which isn't allowed on the RHS of an operator.
    /// Returns `nil` for ternary expressions and expressions containing `as!`, which applies to everything on its left
    /// (`a + b as! T` is `(a + b) as! T`).
    func parseInfixOperandContainingForceUnwrap(_ forceUnwrapIndex: Int) -> ClosedRange<Int>? {
        guard let expressionRange = parseExpressionRange(containing: forceUnwrapIndex) else { return nil }

        // Find the operators between the operands of the expression, skipping over nested scopes
        var infixOperators = [Int]()
        var startOfExpression = expressionRange.lowerBound
        var endOfExpression = expressionRange.upperBound
        var index = expressionRange.lowerBound
        while index <= endOfExpression {
            if tokens[index] == .operator("=", .infix) {
                // The parsed range can include the target of an assignment, which isn't part of the expression
                guard index < forceUnwrapIndex,
                      let nextIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, after: index)
                else {
                    endOfExpression = index - 1
                    break
                }
                infixOperators.removeAll()
                startOfExpression = nextIndex
            } else if tokens[index].isStartOfScope, let endOfScope = endOfScope(at: index) {
                if (index ... endOfScope).contains(forceUnwrapIndex) {
                    return nil
                }
                index = endOfScope
            } else if tokens[index] == .operator("?", .infix) {
                return nil
            } else if tokens[index] == .keyword("as"),
                      let nextIndex = self.index(of: .nonSpaceOrLinebreak, after: index),
                      tokens[nextIndex] == .operator("!", .postfix)
            {
                return nil
            } else if isInfixOperatorSeparatingOperands(at: index) {
                infixOperators.append(index)
            }

            guard let nextIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, after: index) else { break }
            index = nextIndex
        }

        guard let operatorBeforeOperand = infixOperators.last(where: { $0 < forceUnwrapIndex }),
              let startOfOperand = self.index(of: .nonSpaceOrCommentOrLinebreak, after: operatorBeforeOperand)
        else { return nil }

        // The RHS of `as` and `is` is a type, where `!` declares an implicitly unwrapped optional
        if [.keyword("as"), .keyword("is")].contains(tokens[operatorBeforeOperand]) {
            return nil
        }

        var endOfOperand = endOfExpression
        if let operatorAfterOperand = infixOperators.first(where: { $0 > forceUnwrapIndex }),
           let lastTokenOfOperand = self.index(of: .nonSpaceOrCommentOrLinebreak, before: operatorAfterOperand)
        {
            endOfOperand = lastTokenOfOperand
        }

        // `XCTUnwrap` / `#require` take a synchronous autoclosure, so can't wrap an `await`,
        // and a nested ternary's force unwraps can't be converted to optional chaining.
        // An operand that already contains a `try` or `#require` (inserted elsewhere in this rule as
        // `#` and `require`) can't be wrapped again, since nesting `#require` is a recursive macro expansion.
        if tokens[startOfOperand ... endOfOperand].contains(where: {
            [.keyword("await"), .operator("?", .infix), .keyword("try"), .keyword("#require"), .operator("#", .prefix)].contains($0)
        }) {
            return nil
        }

        // Converting `!` to `?` only works within an optional chain, so `foo!!`
        // and `(foo as! Bar?)!` can't be unwrapped with a single `XCTUnwrap`
        let hasNestedForceUnwrap = (startOfOperand ..< endOfOperand).contains { i in
            guard tokens[i] == .operator("!", .postfix),
                  let previousIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, before: i),
                  let nextIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, after: i)
            else { return false }

            return tokens[previousIndex] == .keyword("as") || ![".", "(", "["].contains(tokens[nextIndex].string)
        }

        if hasNestedForceUnwrap {
            return nil
        }

        // The expression range may not include prefix operators and the `try` and `await` keywords at its start
        while let previousIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, before: startOfExpression),
              [.keyword("try"), .keyword("await")].contains(tokens[previousIndex]) || tokens[previousIndex].isOperator(ofType: .prefix)
        {
            startOfExpression = previousIndex
        }

        // Where the parsed range doesn't match the statement, such as when the range stopped
        // after an infix operator or ran on from a previous line, we can't tell if the `try` covers the operand
        if let previousIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, before: startOfExpression),
           isInfixOperatorSeparatingOperands(at: previousIndex),
           tokens[previousIndex] != .operator("=", .infix)
        {
            return nil
        }

        if tokens[startOfExpression ... endOfOperand].contains(where: \.isLinebreak) {
            return nil
        }

        // `try?` and `try!` would change how a failed unwrap is handled. A `try await` expression
        // may have async calls in the operand, which can't be moved into the autoclosure.
        guard tokens[startOfExpression] == .keyword("try"),
              let tokenAfterTry = self.index(of: .nonSpaceOrCommentOrLinebreak, after: startOfExpression),
              !tokens[tokenAfterTry].isUnwrapOperator,
              tokens[tokenAfterTry] != .keyword("await")
        else { return nil }

        return startOfOperand ... endOfOperand
    }

    /// If the given token is an `as` token, finds the direct outer paren scope that could potentially contain a method chain on the result of the cast.
    /// For example, `(foo as! Bar).quux` returns the `.quux` component.
    func parseTokenAfterForceCastParenScope(asIndex: Int) -> Int? {
        guard tokens[asIndex] == .keyword("as"),
              let tokenAfterAs = index(of: .nonSpaceOrCommentOrLinebreak, after: asIndex),
              tokens[tokenAfterAs] == .operator("!", .postfix),
              let containingScopeIndex = startOfScope(at: asIndex),
              tokens[containingScopeIndex] == .startOfScope("("),
              let endOfScope = endOfScope(at: containingScopeIndex),
              let tokenAfterParenScope = index(of: .nonLinebreak, after: endOfScope),
              tokens[tokenAfterParenScope].isOperator || tokens[tokenAfterParenScope].isStartOfScope
        else { return nil }

        return tokenAfterParenScope
    }
}
