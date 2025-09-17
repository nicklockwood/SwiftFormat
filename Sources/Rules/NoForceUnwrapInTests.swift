// Created by Cal Stephens on 2025-09-16.
// Copyright © 2025 Airbnb Inc. All rights reserved.

import Foundation

public extension FormatRule {
    static let noForceUnwrapInTests = FormatRule(
        help: "Replace force unwrap operators `!` in test functions with safer alternatives like `XCTUnwrap` or `#require`.",
        disabledByDefault: true
    ) { formatter in
        guard let testFramework = formatter.detectTestingFramework() else {
            return
        }

        formatter.forEach(.keyword("func")) { funcKeywordIndex, _ in
            guard let functionDecl = formatter.parseFunctionDeclaration(keywordIndex: funcKeywordIndex)
            else { return }

            switch testFramework {
            case .xcTest:
                guard functionDecl.name?.starts(with: "test") == true else { return }
            case .swiftTesting:
                guard formatter.modifiersForDeclaration(at: funcKeywordIndex, contains: "@Test") else { return }
            }

            guard let bodyRange = functionDecl.bodyRange else { return }

            // Find all force unwrap operators in the function body
            var foundAnyForceUnwraps = false

            var currentIndex = bodyRange.upperBound.autoUpdating(in: formatter)

            while currentIndex.index >= bodyRange.lowerBound {
                let index = currentIndex.index
                defer { currentIndex.index -= 1 }

                guard formatter.tokens[index] == .operator("!", .postfix) else {
                    continue
                }

                // Only convert the `!` if we are within the function body
                guard formatter.isInFunctionBody(of: functionDecl, at: index) else {
                    continue
                }

                // Preserve `try!`s, this is handled separately by the `throwingTests` rule
                if let previousToken = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: index),
                   formatter.tokens[previousToken] == .keyword("try")
                {
                    continue
                }

                // Skip if this is an implicitly unwrapped optional type annotation (e.g., let foo: Foo!)
                // Look for the pattern: (let|var) identifier : Type !
                if let colonIndex = formatter.lastIndex(of: .delimiter(":"), in: 0 ..< index),
                   let _ = formatter.lastIndex(of: .keyword, in: 0 ..< colonIndex, if: { ["let", "var"].contains($0.string) })
                {
                    // Make sure there are no assignment operators between the colon and the !
                    // This distinguishes type annotations from variable assignments with IUO types
                    let hasAssignment = formatter.index(of: .operator("=", .infix), in: colonIndex ..< index) != nil
                    if !hasAssignment {
                        continue
                    }
                }

                // Parse the expression containing this force unwrap operator
                guard var expressionRange = formatter.parseExpressionRange(containing: index)?.autoUpdating(in: formatter) else {
                    continue
                }

                // If there are infix operators in the expression, only handle the lhs of the first operator.
                // `try` isn't allowed on the RHS of an operator, and multiple nested operators is too complicated.
                var infixOperatorIndices: [Int] = []
                for i in expressionRange.range {
                    // Handle any infix operator, including operator-like keywords like `is` and `as`.
                    // However don't exclude `as!`, which we want to handle by converting to `as?`.
                    let treatAsInfixOperator = {
                        if formatter.tokens[i].isOperator(ofType: .infix) || formatter.tokens[i] == .keyword("is") {
                            return true
                        }

                        if formatter.tokens[i] == .keyword("as"),
                           let nextToken = formatter.index(of: .nonSpaceOrLinebreak, after: i),
                           formatter.tokens[nextToken] != .operator("!", .postfix)
                        {
                            return true
                        }

                        return false
                    }()

                    if treatAsInfixOperator,
                       formatter.isInFunctionBody(of: functionDecl, at: i),
                       formatter.tokens[i] != .operator(".", .infix)
                    {
                        infixOperatorIndices.append(i)
                    }
                }

                if let infixIndex = infixOperatorIndices.first {
                    // Use a sub-formatter for the LHS so we can parse just the expression in that subrange
                    let lhsTokens = Array(formatter.tokens[expressionRange.lowerBound ..< infixIndex])
                    let lhsFormatter = Formatter(lhsTokens)

                    // Find force unwraps on the LHS only
                    let lhsForceUnwraps = (expressionRange.lowerBound ..< infixIndex).filter {
                        formatter.tokens[$0] == .operator("!", .postfix) && formatter.isInFunctionBody(of: functionDecl, at: $0)
                    }

                    // Find the first force unwrap in the LHS and get its expression range
                    var foundValidExpression = false
                    for forceUnwrapIndex in lhsForceUnwraps {
                        // Convert the absolute index to the sub-formatter's relative index
                        let relativeIndex = forceUnwrapIndex - expressionRange.lowerBound

                        // Get the expression range in the sub-formatter
                        if let subExpressionRange = lhsFormatter.parseExpressionRange(containing: relativeIndex) {
                            // Convert the sub-formatter range back to absolute indices
                            let absoluteRange = (subExpressionRange.lowerBound + expressionRange.lowerBound) ... (subExpressionRange.upperBound + expressionRange.lowerBound)
                            expressionRange = absoluteRange.autoUpdating(in: formatter)
                            foundValidExpression = true
                            break
                        }
                    }

                    if !foundValidExpression {
                        continue
                    }
                }

                // Convert all ! operators in this expression to ? operators
                for i in expressionRange.range.reversed() {
                    guard formatter.tokens[i] == .operator("!", .postfix),
                          formatter.isInFunctionBody(of: functionDecl, at: i)
                    else { continue }

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

                    // If we converted an `as!` to an `as?`, and the as? is part of a broader expression with a chained value
                    // like `(foo as! Bar).baaz`, we have to add an extra `?` after the enclosing parens: `(foo as? Bar)?.baaz`.
                    if let previousToken = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i),
                       formatter.tokens[previousToken] == .keyword("as"),
                       let containingScopeIndex = formatter.startOfScope(at: previousToken),
                       formatter.tokens[containingScopeIndex] == .startOfScope("("),
                       let endOfScope = formatter.endOfScope(at: containingScopeIndex),
                       let tokenAfterParenScope = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: endOfScope),
                       formatter.tokens[tokenAfterParenScope].isOperator,
                       expressionRange.range.contains(tokenAfterParenScope)
                    {
                        formatter.insert(.operator("?", .postfix), at: tokenAfterParenScope)
                    }
                }

                // Build the wrapper tokens based on the test framework
                let wrapperTokens: [Token]
                switch testFramework {
                case .xcTest:
                    wrapperTokens = [.keyword("try"), .space(" "), .identifier("XCTUnwrap"), .startOfScope("(")]
                case .swiftTesting:
                    wrapperTokens = [.keyword("try"), .space(" "), .operator("#", .prefix), .identifier("require"), .startOfScope("(")]
                }

                // Since we're processing right to left, we can insert without worrying about shifting indices
                formatter.insert(.endOfScope(")"), at: expressionRange.upperBound + 1)
                formatter.insert(wrapperTokens, at: expressionRange.lowerBound)

                foundAnyForceUnwraps = true
            }

            // If we found any force unwraps, add a `throws` if it doesn't already exist
            if foundAnyForceUnwraps {
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
        -           #expect(myValue.property! == "foo")
        +       @Test func myFeature() throws {
        +           let myValue = try #require(foo.bar?.value as? Value)
        +           #expect(try #require(myValue.property) == "foo")
              }
            }

            import XCTest

            class MyFeatureTests: XCTestCase {
        -       func testMyFeature() {
        -           let myValue = foo.bar!.value as! Value
        -           XCTAssertEqual(myValue.property, "foo")
        +       func testMyFeature() throws {
        +           let myValue = try XCTUnwrap(foo.bar?.value as? Value)
        +           XCTAssertEqual(try XCTUnwrap(myValue.property), "foo")
              }
            }
        ```
        """
    }
}
