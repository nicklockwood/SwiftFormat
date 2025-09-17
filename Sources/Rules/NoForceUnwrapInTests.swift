// Created by Cal Stephens on 2025-09-16.
// Copyright © 2025 Airbnb Inc. All rights reserved.

import Foundation

public extension FormatRule {
    static let noForceUnwrapInTests = FormatRule(
        help: "Use XCTUnwrap or #require in test cases, rather than force unwrapping.",
        disabledByDefault: true,
        orderAfter: [.urlMacro, .noForceTryInTests, .throwingTests]
    ) { formatter in
        guard let testFramework = formatter.detectTestingFramework() else {
            return
        }

        // Find all of the test case functions in this file
        var testCases = [AutoUpdatingIndex]()
        formatter.forEach(.keyword("func")) { funcKeywordIndex, _ in
            guard let functionDecl = formatter.parseFunctionDeclaration(keywordIndex: funcKeywordIndex),
                  functionDecl.returnType == nil
            else { return }

            switch testFramework {
            case .xcTest:
                guard functionDecl.name?.starts(with: "test") == true else { return }
            case .swiftTesting:
                guard formatter.modifiersForDeclaration(at: funcKeywordIndex, contains: "@Test") else { return }
            }

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

                // Only convert the `!` if we are within the function body
                guard formatter.isInFunctionBody(of: functionDecl, at: forceUnwrapOperator.index) else {
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

                guard let expressionRange = formatter.parseExpressionRangeContainingForceUnwrap(forceUnwrapOperator.index, in: functionDecl) else {
                    continue
                }

                // Convert all eligible ! operators in this expression to ? operators
                convertForceUnwrapsInExpression: for i in expressionRange.range.reversed() {
                    guard formatter.tokens[i] == .operator("!", .postfix),
                          formatter.isInFunctionBody(of: functionDecl, at: i)
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

                /// Whether or not the expression needs to be wrapped in `XCTUnwrap` / `#require`
                var needsUnwrapMethod = true

                // If this expression is the LHS of an assignment operator, changing `foo!.bar = baaz` to `foo?.bar = baaz` is a safe change as-is
                if let tokenAfterExpression = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: expressionRange.upperBound),
                   formatter.tokens[tokenAfterExpression] == .operator("=", .infix)
                {
                    needsUnwrapMethod = false
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
        -       @Test func myFeature() {
        -           let myValue = foo.bar!.value as! Value
        -           let otherValue = (foo! as! Other).bar
        -           otherValue.manager!.prepare()
        -           #expect(myValue.property! == other)
        +       @Test func myFeature() throws {
        +           let myValue = try #require(foo.bar?.value as? Value)
        +           let otherValue = try #require((foo as? Other)?.bar)
        +           otherValue.manager?.prepare()
        +           #expect(try #require(myValue.property) == other)
              }
            }

            import XCTest

            class MyFeatureTests: XCTestCase {
        -       func testMyFeature() {
        -           let myValue = foo.bar!.value as! Value
        -           let otherValue = (foo! as! Other).bar
        -           XCTAssertEqual(myValue.property, "foo")
        +       func testMyFeature() throws {
        +           let myValue = try XCTUnwrap(foo.bar?.value as? Value)
        +           let otherValue = try XCTUnwrap((foo as? Other)?.bar)
        +           XCTAssertEqual(try XCTUnwrap(myValue.property), otherValue)
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
        // `try` isn't allowed on the RHS of an operator, and multiple nested operators is too complicated.
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
               let functionDecl,
               isInFunctionBody(of: functionDecl, at: i),
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
                tokens[i] == .operator("!", .postfix) && isInFunctionBody(of: functionDecl, at: i) && i < infixIndex
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

    // If the given token is an `as` token, finds the direct outer paren scope that could potentially contain a method chain on the result of the cast.
    // For example, `(foo as! Bar).quux` returns the `.quux` component.
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
