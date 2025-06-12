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
        // Helper function to check if else block matches our pattern
        func isValidElseBlock(in range: Range<Int>, for framework: TestingFramework, formatter: Formatter) -> Bool {
            let tokens = formatter.tokens[range].filter { !$0.isSpaceOrCommentOrLinebreak }
            
            switch framework {
            case .XCTest:
                // Matches: XCTFail(...) or return
                return (tokens.count >= 3 &&
                    tokens[0] == .identifier("XCTFail") &&
                    tokens[1] == .startOfScope("(")) ||
                    (tokens.count == 1 &&
                    tokens[0] == .keyword("return"))
            case .Testing:
                // Matches: return or Issue.record(...); return
                return (tokens.count == 1 &&
                    tokens[0] == .keyword("return")) ||
                    (tokens.count >= 5 &&
                    tokens[0] == .identifier("Issue") &&
                    tokens[1] == .operator(".", .infix) &&
                    tokens[2] == .identifier("record") &&
                    tokens[3] == .startOfScope("(") &&
                    tokens.last == .keyword("return"))
            }
        }
        
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

                // Check if the else block matches our pattern
                let elseBodyRange = (elseBraceIndex + 1) ..< endOfElseScope
                guard isValidElseBlock(in: elseBodyRange, for: testFramework, formatter: formatter) else {
                    continue
                }

                // Check if all conditions are let bindings that can be transformed
                let transformableConditions = parsedGuard.conditions.enumerated().compactMap { (index, condition) -> (index: Int, identifier: String, expression: ClosedRange<Int>)? in
                    guard condition.isLetBinding,
                          let identifier = condition.identifier,
                          let expression = condition.expression
                    else { return nil }
                    return (index, identifier, expression)
                }
                
                guard !transformableConditions.isEmpty else { continue }
                
                // Check for variable shadowing for any transformable identifier
                let scopeStart = bodyRange.lowerBound
                let searchRange = scopeStart ..< guardIndex
                var shadowedIdentifiers = Set<String>()
                
                for i in searchRange {
                    // Check for let/var declarations
                    if formatter.tokens[i] == .keyword("let") || formatter.tokens[i] == .keyword("var"),
                       let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i),
                       case let .identifier(name) = formatter.tokens[nextIndex]
                    {
                        shadowedIdentifiers.insert(name)
                    }
                    
                    // Check for function parameters
                    if case let .identifier(name) = formatter.tokens[i],
                       i > 0,
                       let prevNonSpace = formatter.index(of: .nonSpaceOrLinebreak, before: i),
                       formatter.tokens[prevNonSpace] == .delimiter(",") || formatter.tokens[prevNonSpace] == .startOfScope("(")
                    {
                        shadowedIdentifiers.insert(name)
                    }
                }
                
                // Filter out shadowed identifiers
                let validTransformations = transformableConditions.filter { !shadowedIdentifiers.contains($0.identifier) }
                guard !validTransformations.isEmpty else { continue }

                // Determine strategy: transform all at once if all can be transformed, otherwise one at a time
                let allCanBeTransformed = parsedGuard.conditions.allSatisfy { condition in
                    condition.isLetBinding && validTransformations.contains { $0.index == parsedGuard.conditions.firstIndex(of: condition) }
                }
                
                if allCanBeTransformed && parsedGuard.conditions.count == validTransformations.count {
                    // All conditions can be transformed - do them all at once
                    let functionName = testFramework == .XCTest ? "XCTUnwrap" : "#require"
                    let linebreakToken = formatter.linebreakToken(for: guardIndex)
                    let indent = formatter.currentIndentForLine(at: guardIndex)
                    
                    var replacementStatements: [Token] = []
                    
                    for (i, transformation) in validTransformations.enumerated() {
                        if i > 0 {
                            replacementStatements.append(linebreakToken)
                            replacementStatements.append(.space(indent))
                        }
                        
                        let expressionTokens = formatter.tokens[transformation.expression]
                        replacementStatements.append(contentsOf: [
                            .keyword("let"),
                            .space(" "),
                            .identifier(transformation.identifier),
                            .space(" "),
                            .operator("=", .infix),
                            .space(" "),
                            .keyword("try"),
                            .space(" "),
                            .identifier(functionName),
                            .startOfScope("("),
                        ])
                        replacementStatements.append(contentsOf: expressionTokens)
                        replacementStatements.append(.endOfScope(")"))
                    }
                    
                    formatter.replaceTokens(in: guardIndex ... endOfElseScope, with: replacementStatements)
                    addedTryStatement = true
                } else if let firstValid = validTransformations.first {
                    // Transform just the first valid one
                    let expressionTokens = formatter.tokens[firstValid.expression]
                    let functionName = testFramework == .XCTest ? "XCTUnwrap" : "#require"
                    
                    let replacementStatement = [
                        .keyword("let"),
                        .space(" "),
                        .identifier(firstValid.identifier),
                        .space(" "),
                        .operator("=", .infix),
                        .space(" "),
                        .keyword("try"),
                        .space(" "),
                        .identifier(functionName),
                        .startOfScope("("),
                    ] + expressionTokens + [.endOfScope(")")]

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
                            if index == firstValid.index {
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
                }

                // Only transform one guard per rule execution
                // The formatter will run the rule again if needed
                break
            }

            // If we added try XCTUnwrap or try #require, ensure the function has throws
            if addedTryStatement, !functionDecl.effects.contains("throws") {
                if let effectsRange = functionDecl.effectsRange {
                    // If async is present, insert throws after it to maintain correct order: async throws
                    if let asyncIndex = formatter.index(of: .identifier("async"), in: effectsRange.lowerBound ..< effectsRange.upperBound + 1) {
                        formatter.insert([.space(" "), .keyword("throws")], at: asyncIndex + 1)
                    } else {
                        // Otherwise add it to the end of effects
                        formatter.insert([.keyword("throws"), .space(" ")], at: effectsRange.upperBound)
                    }
                } else {
                    // If there are no effects, add after the arguments
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
