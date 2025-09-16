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

            // Find all force unwrap operators and process unique expressions from right to left
            // Using AutoUpdatingIndex to handle token insertions
            var foundAnyForceUnwraps = false

            var currentIndex = bodyRange.upperBound.autoUpdating(in: formatter)
            let bodyStart = bodyRange.lowerBound

            while currentIndex.index >= bodyStart {
                let index = currentIndex.index
                defer { currentIndex.index -= 1 }

                if index >= formatter.tokens.count {
                    continue
                }

                guard formatter.tokens[index] == .operator("!", .postfix) else {
                    continue
                }

                // Only convert the `!` if we are within the function body
                guard formatter.isInFunctionBody(of: functionDecl, at: index) else {
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
                guard var expressionRange = formatter.parseExpressionRange(containing: index) else {
                    continue
                }

                // If there are infix operators like == or +, only handle the lhs of the first operator.
                // `try` isn't allowed on the RHS of an operator, and multiple nested operators is too complicated.
                // Note: `as` is not considered an infix operator for this purpose
                var infixOperatorIndices: [Int] = []
                for i in expressionRange {
                    // Skip 'as' keyword - it's not a real infix operator for our purposes
                    if formatter.tokens[i] == .keyword("as") {
                        continue
                    }

                    if formatter.tokens[i].isOperator(ofType: .infix),
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
                            expressionRange = absoluteRange
                            foundValidExpression = true
                            break
                        }
                    }

                    if !foundValidExpression {
                        continue
                    }
                }

                // Trim whitespace from the end of the expression range
                var trimmedExpressionRange = expressionRange
                while trimmedExpressionRange.upperBound >= trimmedExpressionRange.lowerBound,
                      formatter.tokens[trimmedExpressionRange.upperBound].isSpaceOrLinebreak
                {
                    trimmedExpressionRange = trimmedExpressionRange.lowerBound ... (trimmedExpressionRange.upperBound - 1)
                }
                expressionRange = trimmedExpressionRange

                // Check if the expression ends with a force unwrap
                let expressionEndsWithForceUnwrap = formatter.tokens[expressionRange.upperBound] == .operator("!", .postfix) &&
                    formatter.isInFunctionBody(of: functionDecl, at: expressionRange.upperBound)

                // Convert all ! operators in this expression to ? operators
                for i in expressionRange {
                    if formatter.tokens[i] == .operator("!", .postfix),
                       formatter.isInFunctionBody(of: functionDecl, at: i)
                    {
                        formatter.replaceToken(at: i, with: .operator("?", .postfix))
                    }
                }

                // The range to wrap depends on whether the expression ends with !
                let rangeToWrap: Range<Int>
                if expressionEndsWithForceUnwrap {
                    // If it ends with !, wrap everything except the final !
                    rangeToWrap = expressionRange.lowerBound ..< expressionRange.upperBound
                    // Remove the final ! (which was converted to ? above, so we need to remove the ?)
                    formatter.removeToken(at: expressionRange.upperBound)
                } else {
                    // If it doesn't end with !, wrap the entire expression
                    rangeToWrap = expressionRange.lowerBound ..< (expressionRange.upperBound + 1)
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
                formatter.insert(wrapperTokens, at: rangeToWrap.lowerBound)
                formatter.insert(.endOfScope(")"), at: rangeToWrap.upperBound + wrapperTokens.count)

                foundAnyForceUnwraps = true
            }

            // If we found any force unwraps, add a `throws` if it doesn't already exist
            guard foundAnyForceUnwraps else { return }
            formatter.addThrowsEffect(to: functionDecl)
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
