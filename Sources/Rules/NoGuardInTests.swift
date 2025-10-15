//
//  NoGuardInTests.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 6/12/25.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let noGuardInTests = FormatRule(
        help: """
        Convert guard statements in unit tests to `try #require(...)` / `#expect(...)`
        or `try XCTUnwrap(...)` / `XCTAssert(...)`.
        """,
        disabledByDefault: true,
        sharedOptions: ["linebreaks"]
    ) { formatter in
        guard let testFramework = formatter.detectTestingFramework() else {
            return
        }

        formatter.forEach(.keyword("func")) { funcKeywordIndex, _ in
            guard let functionDecl = formatter.parseFunctionDeclaration(keywordIndex: funcKeywordIndex),
                  formatter.isTestFunction(at: funcKeywordIndex, in: functionDecl, for: testFramework),
                  let bodyRange = functionDecl.bodyRange
            else { return }

            // Track if we made any changes that require adding throws
            var addedTryStatement = false

            // Process guard statements in reverse order to avoid index shifting issues
            for guardIndex in bodyRange.reversed() {
                guard formatter.tokens[guardIndex] == .keyword("guard") else { continue }

                // Only process if we are in the function body (not in a closure or nested function)
                guard formatter.isInFunctionBody(of: functionDecl, at: guardIndex) else { continue }

                // Parse the guard conditions
                let conditions = formatter.parseConditionalStatement(at: guardIndex)
                guard !conditions.isEmpty else { continue }

                // Find the else block
                guard let elseBraceIndex = formatter.index(of: .startOfScope("{"), after: guardIndex),
                      let prevTokenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: elseBraceIndex),
                      formatter.tokens[prevTokenIndex] == .keyword("else"),
                      let endOfElseScope = formatter.endOfScope(at: elseBraceIndex)
                else {
                    continue
                }

                // Check if the else block matches our pattern
                let elseBodyTokens = formatter.tokens[(elseBraceIndex + 1) ..< endOfElseScope]
                    .filter { !$0.isSpaceOrCommentOrLinebreak }

                let isValidElseBlock: Bool = {
                    // Common case: just return
                    if elseBodyTokens.count == 1, elseBodyTokens[0] == .keyword("return") {
                        return true
                    }

                    // Must end with return
                    guard elseBodyTokens.last == .keyword("return") else { return false }

                    switch testFramework {
                    case .xcTest:
                        // XCTFail(...); return
                        return elseBodyTokens.count >= 3 && elseBodyTokens[0 ... 1].string == "XCTFail("
                    case .swiftTesting:
                        // Issue.record(...); return
                        return elseBodyTokens.count >= 5 && elseBodyTokens[0 ... 3].string == "Issue.record("
                    }
                }()

                guard isValidElseBlock else { continue }

                // Preserve the assertion message (if any)
                let assertionMessage: [Token] = {
                    guard let startIndex = formatter.index(of: .startOfScope("("), after: elseBraceIndex),
                          let endIndex = formatter.endOfScope(at: startIndex),
                          formatter.index(after: startIndex, where: { $0.isStringDelimiter }) != nil
                    else {
                        return []
                    }
                    return [.delimiter(","), .space(" ")] + formatter.tokens[startIndex + 1 ..< endIndex]
                }()

                // Check for variable shadowing
                let scopeStart = bodyRange.lowerBound
                let searchRange = scopeStart ..< guardIndex

                let shadowedIdentifiers = Set<String>(searchRange.compactMap { i in
                    let token = formatter.tokens[i]

                    // Check for let/var declarations
                    if token == .keyword("let") || token == .keyword("var"),
                       let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i),
                       case let .identifier(name) = formatter.tokens[nextIndex]
                    {
                        return name
                    }

                    // Check for function parameters
                    if case let .identifier(name) = token,
                       i > 0,
                       let prevNonSpace = formatter.index(of: .nonSpaceOrLinebreak, before: i),
                       formatter.tokens[prevNonSpace] == .delimiter(",") || formatter.tokens[prevNonSpace] == .startOfScope("(")
                    {
                        return name
                    }

                    return nil
                })

                // Check if we should skip this guard due to cases that can't be
                // represented with #require or #expect
                let shouldSkip = conditions.contains { condition in
                    // Skip if any condition contains await
                    if condition.range.contains(where: { formatter.tokens[$0] == .keyword("await") }) {
                        return true
                    }

                    switch condition {
                    case let .optionalBinding(_, property):
                        // Skip if variable shadowing
                        return shadowedIdentifiers.contains(property.identifier)
                    case .patternMatching:
                        // Skip if pattern matching
                        return true
                    case .booleanExpression:
                        return false
                    }
                }

                guard !shouldSkip else { continue }

                // Now we can safely transform all conditions
                let unwrapFunctionName = testFramework == .xcTest ? "XCTUnwrap" : "#require"
                let assertFunctionName = testFramework == .xcTest ? "XCTAssert" : "#expect"
                let linebreakToken = formatter.linebreakToken(for: guardIndex)
                let indent = formatter.currentIndentForLine(at: guardIndex)

                var replacementStatements: [Token] = []

                for (index, condition) in conditions.enumerated() {
                    if index > 0 {
                        replacementStatements.append(linebreakToken)
                        replacementStatements.append(.space(indent))
                    }

                    switch condition {
                    case let .optionalBinding(range, property):
                        // Transform let/var binding - preserve the original keyword
                        let introducerKeyword = formatter.tokens[property.introducerIndex]
                        replacementStatements.append(contentsOf: [
                            introducerKeyword,
                            .space(" "),
                            .identifier(property.identifier),
                        ])

                        // Add type annotation if present
                        if let colonIndex = property.colonIndex, let type = property.type {
                            // Include from colon to end of type
                            let typeTokens = formatter.tokens[colonIndex ... type.range.upperBound]
                            replacementStatements.append(contentsOf: typeTokens)
                        }

                        // Get the expression part (after the = if present, or just the identifier)
                        var expressionTokens: [Token] = []
                        if let valueInfo = property.value {
                            expressionTokens = Array(formatter.tokens[valueInfo.expressionRange])
                        } else {
                            // For shorthand like `let foo`, use the identifier as the expression
                            expressionTokens = [.identifier(property.identifier)]
                        }

                        replacementStatements.append(contentsOf: [
                            .space(" "),
                            .operator("=", .infix),
                            .space(" "),
                            .keyword("try"),
                            .space(" "),
                            .identifier(unwrapFunctionName),
                            .startOfScope("("),
                        ])
                        replacementStatements.append(contentsOf: expressionTokens)
                        replacementStatements.append(contentsOf: assertionMessage)
                        replacementStatements.append(.endOfScope(")"))
                        addedTryStatement = true

                    case let .booleanExpression(range):
                        // Transform boolean condition to assertion
                        let conditionTokens = formatter.tokens[range]
                        replacementStatements.append(.identifier(assertFunctionName))
                        replacementStatements.append(.startOfScope("("))
                        replacementStatements.append(contentsOf: conditionTokens)
                        replacementStatements.append(contentsOf: assertionMessage)
                        replacementStatements.append(.endOfScope(")"))

                    case .patternMatching:
                        // This should have been filtered out earlier
                        assertionFailure("Pattern matching conditions should have been filtered")
                    }
                }

                formatter.replaceTokens(in: guardIndex ... endOfElseScope, with: replacementStatements)
            }

            // If we added try XCTUnwrap or try #require, ensure the function has throws
            if addedTryStatement {
                formatter.addThrowsEffect(to: functionDecl)
            }
        }
    } examples: {
        """
        ```diff
          import XCTest

          final class SomeTestCase: XCTestCase {
        -     func test_something() {
        +     func test_something() throws {
        -         guard let value = optionalValue, value.matchesCondition else {
        -             XCTFail()
        -             return
        -         }
        +         let value = try XCTUnwrap(optionalValue)
        +         XCTAssert(value.matchesCondition)
              }
          }
        ```

        ```diff
          import Testing

          struct SomeTests {
              @Test
              func something() throws {
        -         guard let value = optionalValue, value.matchesCondition else {
        -             return
        -         }
        +         let value = try #require(optionalValue)
        +         #expect(value.matchesCondition)
              }
          }
        ```
        """
    }
}
