//
//  PreferRequire.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 11/6/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let preferRequire = FormatRule(
        help: """
        Prefer Test APIs for unwrapping optionals over `if let` and `guard let`.
        For XCTest, use `XCTUnwrap` instead of `guard let ... else { XCTFail() }` or `guard let ... else { return }`.
        For Swift Testing, use `#require` instead of `guard let ... else { return }` or `guard let ... else { Issue.record(); return }`.
        """,
        disabledByDefault: true
    ) { formatter in
        let testFramework: TestingFramework

        if formatter.hasImport("Testing") {
            testFramework = .Testing
        } else if formatter.hasImport("XCTest") {
            testFramework = .XCTest
        } else {
            return
        }

        formatter.forEach(.keyword("func")) { funcKeywordIndex, _ in
            guard let functionDecl = formatter.parseFunctionDeclaration(keywordIndex: funcKeywordIndex)
            else { return }

            switch testFramework {
            case .XCTest:
                guard functionDecl.name?.starts(with: "test") == true else { return }
            case .Testing:
                guard formatter.modifiersForDeclaration(at: funcKeywordIndex, contains: "@Test") else { return }
            }

            guard let bodyRange = functionDecl.bodyRange else { return }

            // Track if we made any changes that require adding throws
            var addedTryStatement = false

            // Process guard statements in reverse order to avoid index shifting issues
            for guardIndex in bodyRange.reversed() {
                guard formatter.tokens[guardIndex] == .keyword("guard") else { continue }

                // Only process if we are not within a closure, where it's not safe to add throws
                if formatter.isInClosure(at: guardIndex) { continue }

                // Parse the guard conditions
                guard let parsedGuard = formatter.parseGuardOrIfConditions(at: guardIndex),
                      let elseBraceIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: parsedGuard.elseIndex),
                      formatter.tokens[elseBraceIndex] == .startOfScope("{"),
                      let endOfElseScope = formatter.endOfScope(at: elseBraceIndex)
                else {
                    continue
                }

                // Check the content of the else block
                let elseBodyRange = (elseBraceIndex + 1) ..< endOfElseScope
                let elseBodyTokens = formatter.tokens[elseBodyRange].filter { !$0.isSpaceOrCommentOrLinebreak }

                // Determine if this else block matches our pattern
                let matchesPattern: Bool
                switch testFramework {
                case .XCTest:
                    matchesPattern = (elseBodyTokens.count >= 3 &&
                        elseBodyTokens[0] == .identifier("XCTFail") &&
                        elseBodyTokens[1] == .startOfScope("(")) ||
                        (elseBodyTokens.count == 1 &&
                        elseBodyTokens[0] == .keyword("return"))
                case .Testing:
                    matchesPattern = (elseBodyTokens.count == 1 &&
                        elseBodyTokens[0] == .keyword("return")) ||
                        (elseBodyTokens.count >= 5 &&
                        elseBodyTokens[0] == .identifier("Issue") &&
                        elseBodyTokens[1] == .operator(".", .infix) &&
                        elseBodyTokens[2] == .identifier("record") &&
                        elseBodyTokens[3] == .startOfScope("(") &&
                        elseBodyTokens.last == .keyword("return"))
                }

                guard matchesPattern else { continue }

                // Find the first let binding that we can transform
                guard let targetConditionIndex = parsedGuard.conditions.firstIndex(where: { $0.isLetBinding && $0.identifier != nil && $0.expression != nil }),
                      let identifier = parsedGuard.conditions[targetConditionIndex].identifier,
                      let expressionRange = parsedGuard.conditions[targetConditionIndex].expression
                else {
                    continue
                }

                // Build the replacement statement
                let expressionTokens = formatter.tokens[expressionRange]
                var replacementStatement: [Token]

                switch testFramework {
                case .XCTest:
                    replacementStatement = [
                        .keyword("let"),
                        .space(" "),
                        .identifier(identifier),
                        .space(" "),
                        .operator("=", .infix),
                        .space(" "),
                        .keyword("try"),
                        .space(" "),
                        .identifier("XCTUnwrap"),
                        .startOfScope("("),
                    ]
                    replacementStatement.append(contentsOf: expressionTokens)
                    replacementStatement.append(.endOfScope(")"))

                case .Testing:
                    replacementStatement = [
                        .keyword("let"),
                        .space(" "),
                        .identifier(identifier),
                        .space(" "),
                        .operator("=", .infix),
                        .space(" "),
                        .keyword("try"),
                        .space(" "),
                        .identifier("#require"),
                        .startOfScope("("),
                    ]
                    replacementStatement.append(contentsOf: expressionTokens)
                    replacementStatement.append(.endOfScope(")"))
                }

                // Handle the transformation
                if parsedGuard.conditions.count == 1 {
                    // Single condition - replace the entire guard
                    formatter.replaceTokens(in: guardIndex ... endOfElseScope, with: replacementStatement)
                } else {
                    // Multiple conditions - build complete replacement
                    let linebreakToken = formatter.linebreakToken(for: guardIndex)
                    let indent = formatter.currentIndentForLine(at: guardIndex)

                    // Build the new content: unwrap statement + modified guard
                    var newTokens: [Token] = []

                    // Add the unwrap/require statement
                    newTokens.append(contentsOf: replacementStatement)
                    newTokens.append(linebreakToken)
                    newTokens.append(.space(indent))

                    // Add guard keyword
                    newTokens.append(.keyword("guard"))
                    newTokens.append(.space(" "))

                    // Add remaining conditions
                    var isFirst = true
                    for (index, condition) in parsedGuard.conditions.enumerated() {
                        if index == targetConditionIndex {
                            continue // Skip the transformed condition
                        }

                        if !isFirst {
                            newTokens.append(.delimiter(","))

                            // Check if next condition starts on new line
                            if condition.startIndex > 0, formatter.tokens[condition.startIndex - 1].isLinebreak {
                                newTokens.append(linebreakToken)
                                // Copy indentation
                                var i = condition.startIndex - 2
                                while i >= 0, formatter.tokens[i].isSpace {
                                    newTokens.append(formatter.tokens[i])
                                    i -= 1
                                }
                            } else {
                                newTokens.append(.space(" "))
                            }
                        }
                        isFirst = false

                        // Copy the condition tokens
                        for i in condition.startIndex ... condition.endIndex {
                            newTokens.append(formatter.tokens[i])
                        }
                    }

                    // Add else clause and body
                    newTokens.append(.space(" "))
                    for i in parsedGuard.elseIndex ... endOfElseScope {
                        newTokens.append(formatter.tokens[i])
                    }

                    // Replace the entire guard statement
                    formatter.replaceTokens(in: guardIndex ... endOfElseScope, with: newTokens)
                }

                addedTryStatement = true

                // Only transform one guard per rule execution
                // The formatter will run the rule again if needed
                break
            }

            // If we added try XCTUnwrap or try #require, ensure the function has throws
            if addedTryStatement,
               !functionDecl.effects.contains("throws")
            {
                // If there are effects, we need to add throws in the right position
                if let effectsRange = functionDecl.effectsRange {
                    // If async is present, we need to ensure correct order: async throws
                    if functionDecl.effects.contains("async") {
                        // Find the async keyword and insert throws after it
                        for i in effectsRange {
                            if formatter.tokens[i] == .identifier("async") {
                                formatter.insert([.space(" "), .keyword("throws")], at: i + 1)
                                break
                            }
                        }
                    } else {
                        // Otherwise add it to the end
                        formatter.insert([.keyword("throws"), .space(" ")], at: effectsRange.upperBound)
                    }
                } else {
                    // If there are no effects, add after the arguments.
                    formatter.insert([.space(" "), .keyword("throws")], at: functionDecl.argumentsRange.upperBound + 1)
                }
            }
        }
    } examples: {
        """
        ```diff
        import XCTest

        final class SomeTestCase: XCTestCase {
        -   func test_something() {
        +   func test_something() throws {
        -     guard let value = optionalValue else {
        -       XCTFail()
        -     }
        +     let value = try XCTUnwrap(optionalValue)
          }
        }
        ```

        ```diff
        import XCTest

        final class SomeTestCase: XCTestCase {
        -   func test_something() {
        +   func test_something() throws {
        -     guard let value = optionalValue else {
        -       return
        -     }
        +     let value = try XCTUnwrap(optionalValue)
          }
        }
        ```

        ```diff
        import Testing

        struct SomeTests {
          @Test
          func something() throws {
        -   guard let value = optionalValue else {
        -     return
        -   }
        +   let value = try #require(optionalValue)
          }
        }
        ```

        ```diff
        import Testing

        struct SomeTests {
          @Test
        -   func something() {
        +   func something() throws {
        -     guard let value = optionalValue else {
        -       Issue.record("Expected value")
        -       return
        -     }
        +     let value = try #require(optionalValue)
          }
        }
        ```
        """
    }
}
