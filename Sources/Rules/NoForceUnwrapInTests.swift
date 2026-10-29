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

                guard let expressionRange = formatter.parseExpressionRangeContainingForceUnwrap(forceUnwrapOperator.index) else {
                    continue
                }

                // A key path like `\.[id: 0]!` can't contain `try`, so its force unwraps can't be converted
                if formatter.tokens[expressionRange.lowerBound] == .operator("\\", .prefix) {
                    continue
                }

                // An operator's RHS cannot start with `try`, so insert it at the start of the full expression.
                let fullExpressionRange = formatter.parseForceUnwrapExpressionRange(containing: expressionRange.lowerBound)
                let tryInsertionIndex = (fullExpressionRange?.lowerBound ?? expressionRange.lowerBound).autoUpdating(in: formatter)
                let isOperatorRHS = tryInsertionIndex.index < expressionRange.lowerBound
                if isOperatorRHS, !formatter.canUnwrapOperatorOperand(in: expressionRange.range) {
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

                // Whether or not the expression needs to be wrapped in `XCTUnwrap` / `#require`
                var needsUnwrapMethod = true

                // If this expression is the LHS of an assignment operator, changing `foo!.bar = baaz` to `foo?.bar = baaz` is a safe change as-is
                if let tokenAfterExpression = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: expressionRange.upperBound),
                   formatter.tokens[tokenAfterExpression] == .operator("=", .infix)
                {
                    needsUnwrapMethod = false
                }

                // If this expression is followed by ==, changing `foo!.bar == bar` to `foo?.bar == bar` is a safe change as-is,
                // unless it is the RHS of another operator that requires a non-optional value.
                if !isOperatorRHS,
                   let tokenAfterExpression = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: expressionRange.upperBound),
                   formatter.tokens[tokenAfterExpression] == .operator("==", .infix)
                {
                    needsUnwrapMethod = false
                }

                // If this expression is within XCTAssertEqual or XCTAssertNil, changing `foo!.bar` to `foo?.bar` is a safe change as-is,
                // as long as this isn't a subexpression within a parent operator expression.
                if !isOperatorRHS,
                   let containingParenScope = formatter.startOfScope(at: expressionRange.lowerBound),
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

                    var wrapperTokens: [Token]
                    switch testFramework {
                    case .xcTest:
                        wrapperTokens = [.keyword("try"), .space(" "), .identifier("XCTUnwrap"), .startOfScope("(")]
                    case .swiftTesting:
                        wrapperTokens = [.keyword("try"), .space(" "), .keyword("#require"), .startOfScope("(")]
                    }

                    if isOperatorRHS {
                        wrapperTokens.removeFirst(2)
                    }

                    let insertionIndex = startsWithPrefixOperator ? expressionRange.lowerBound + 1 : expressionRange.lowerBound

                    // Since we're processing right to left, we can insert without worrying about shifting indices
                    formatter.insert(.endOfScope(")"), at: expressionRange.upperBound + 1)
                    formatter.insert(wrapperTokens, at: insertionIndex)

                    if startsWithPrefixOperator, !isOperatorRHS {
                        formatter.insert(.endOfScope(")"), at: expressionRange.upperBound + 1)
                        formatter.insert(.startOfScope("("), at: insertionIndex)
                    }

                    if isOperatorRHS, formatter.tokens[tryInsertionIndex] != .keyword("try") {
                        formatter.insert([.keyword("try"), .space(" ")], at: tryInsertionIndex)
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
    func parseExpressionRangeContainingForceUnwrap(_ forceUnwrapIndex: Int) -> AutoUpdatingRange? {
        // Parse the expression containing this force unwrap operator
        guard var expressionRange = parseForceUnwrapExpressionRange(containing: forceUnwrapIndex)?.autoUpdating(in: self) else {
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

        // If there are infix operators, unwrap only the operand containing the force unwrap.
        //
        // Handle any infix operator, including operator-like keywords like `is` and `as`.
        // However don't exclude `as!`, which we want to handle by converting to `as?`.
        let treatAsInfixOperator = { (token: Token, index: Int) in
            if token.isOperator(ofType: .infix), token != .operator(".", .infix) {
                return true
            }

            if token == .keyword("is") {
                return true
            }

            if token == .keyword("as"),
               let nextToken = self.index(of: .nonSpaceOrLinebreak, after: index),
               self.tokens[nextToken] != .operator("!", .postfix)
            {
                return true
            }

            return false
        }

        let firstInfixOperator = expressionRange.range.first(where: { i in
            if treatAsInfixOperator(tokens[i], i),
               startOfScope(at: i) == startOfScope(at: expressionRange.lowerBound)
            {
                return true
            }

            return false
        })

        // Ternaries and force casts apply to more than one operand, so don't split them.
        if let infixIndex = firstInfixOperator {
            // `await` can cover async calls in any operand, but unwrap autoclosures are synchronous.
            if tokens[expressionRange.lowerBound ..< infixIndex].contains(.keyword("await")) {
                return nil
            }
            if expressionRange.range.contains(where: { i in
                startOfScope(at: i) == startOfScope(at: expressionRange.lowerBound)
                    && (tokens[i] == .operator("?", .infix)
                        || (tokens[i] == .keyword("as") && next(.nonSpaceOrCommentOrLinebreak, after: i) == .operator("!", .postfix)))
            }) {
                return nil
            }

            // The RHS of a cast or type check is a type, not a value to unwrap.
            if ["as", "is"].contains(tokens[infixIndex].string),
               let typeStart = index(of: .nonSpaceOrCommentOrLinebreak, after: infixIndex),
               let type = parseType(at: typeStart), type.range.contains(forceUnwrapIndex)
            {
                return nil
            }

            // Parse the operand containing this unwrap in isolation from the rest of the expression.
            let operandRange = forceUnwrapIndex < infixIndex
                ? expressionRange.lowerBound ..< infixIndex
                : (infixIndex + 1) ..< (expressionRange.upperBound + 1)
            let operandFormatter = Formatter(Array(tokens[operandRange]))
            let relativeIndex = forceUnwrapIndex - operandRange.lowerBound
            guard let subExpressionRange = operandFormatter.parseExpressionRangeContainingForceUnwrap(relativeIndex) else {
                return nil
            }

            let absoluteRange = (subExpressionRange.lowerBound + operandRange.lowerBound) ... (subExpressionRange.upperBound + operandRange.lowerBound)
            expressionRange = absoluteRange.autoUpdating(in: self)
        }

        return expressionRange
    }

    /// Finds the whole expression without joining a parenthesized statement to the previous line.
    func parseForceUnwrapExpressionRange(containing index: Int) -> ClosedRange<Int>? {
        guard let range = parseExpressionRange(containing: index) else { return nil }
        var start = range.lowerBound
        var previous = start
        while let next = self.index(of: .nonSpaceOrCommentOrLinebreak, after: previous), next <= index {
            if tokens[next] == .startOfScope("("),
               startOfScope(at: next) == startOfScope(at: start),
               !onSameLine(previous, next),
               tokens[previous].isEndOfScope || tokens[previous].isIdentifier
            {
                start = next
            }
            previous = next
        }
        // The reverse expression parser can omit keywords before a grouped expression.
        while let previous = self.index(of: .nonSpaceOrCommentOrLinebreak, before: start),
              onSameLine(previous, start),
              ["try", "await"].contains(tokens[previous].string) || tokens[previous].isOperator(ofType: .prefix)
        {
            start = previous
        }
        return start ... range.upperBound
    }

    /// Only optional chains can be collapsed into one synchronous unwrap call.
    func canUnwrapOperatorOperand(in range: ClosedRange<Int>) -> Bool {
        if tokens[range].contains(where: {
            [.keyword("await"), .keyword("try"), .keyword("#require"), .operator("?", .infix)].contains($0)
        }) {
            return false
        }
        return !range.contains { i in
            guard tokens[i] == .operator("!", .postfix),
                  let previous = index(of: .nonSpaceOrCommentOrLinebreak, before: i),
                  let next = index(of: .nonSpaceOrCommentOrLinebreak, after: i),
                  range.contains(next)
            else { return false }
            return tokens[previous] == .keyword("as") || ![".", "(", "["].contains(tokens[next].string)
        }
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
