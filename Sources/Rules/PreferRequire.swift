//
//  PreferRequire.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 6/12/25.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    // a better name could be noGuardInTests?
    static let preferRequire = FormatRule(
        help: """
        Prefer Test APIs for unwrapping optionals over `if let` and `guard let`.
        For XCTest, use `XCTUnwrap` instead of `guard let ... else { XCTFail() }` or `guard let ... else { return }`.
        For Swift Testing, use `#require` instead of `guard let ... else { return }` or `guard let ... else { Issue.record(); return }`.
        """,
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
                let elseBodyTokens = formatter.tokens[(elseBraceIndex + 1) ..< endOfElseScope]
                    .filter { !$0.isSpaceOrCommentOrLinebreak }

                switch testFramework {
                case .xcTest:
                    // Matches: return or XCTFail(...); return
                    guard (elseBodyTokens.count == 1 && elseBodyTokens[0].string == "return") ||
                        (elseBodyTokens.count >= 3 && elseBodyTokens[0 ... 1].string == "XCTFail(") && elseBodyTokens.last == .keyword("return")
                    else { continue }

                case .swiftTesting:
                    // Matches: return or Issue.record(...); return
                    guard (elseBodyTokens.count == 1 && elseBodyTokens[0].string == "return") ||
                        (elseBodyTokens.count >= 5 && elseBodyTokens[0 ... 3].string == "Issue.record(" && elseBodyTokens.last == .keyword("return"))
                    else { continue }
                }

                // Check for variable shadowing
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

                // Check if any let bindings have shadowing issues
                var hasShadowingIssues = false
                for condition in parsedGuard.conditions where condition.isLetBinding {
                    if let identifier = condition.identifier, shadowedIdentifiers.contains(identifier) {
                        hasShadowingIssues = true
                        break
                    }
                }

                // If there's any shadowing, skip this guard entirely
                guard !hasShadowingIssues else {
                    continue
                }

                // Check if any condition contains a case pattern
                var hasCasePattern = false
                for condition in parsedGuard.conditions {
                    // Check if the condition starts with 'case'
                    if formatter.tokens[condition.startIndex] == .keyword("case") {
                        hasCasePattern = true
                        break
                    }
                }

                // If there's a case pattern, skip this guard entirely
                guard !hasCasePattern else { continue }

                // Check if any condition contains await
                var hasAwait = false
                for condition in parsedGuard.conditions {
                    // Check if the condition contains 'await' keyword
                    for i in condition.startIndex ... condition.endIndex {
                        if formatter.tokens[i] == .keyword("await") {
                            hasAwait = true
                            break
                        }
                    }
                    if hasAwait { break }
                }

                // If there's await in any condition, skip this guard entirely
                guard !hasAwait else { continue }

                // Now we can safely transform all conditions
                let unwrapFunctionName = testFramework == .xcTest ? "XCTUnwrap" : "#require"
                let assertFunctionName = testFramework == .xcTest ? "XCTAssert" : "#expect"
                let linebreakToken = formatter.linebreakToken(for: guardIndex)
                let indent = formatter.currentIndentForLine(at: guardIndex)

                var replacementStatements: [Token] = []
                var needsLinebreak = false

                for (index, condition) in parsedGuard.conditions.enumerated() {
                    if needsLinebreak {
                        replacementStatements.append(linebreakToken)
                        replacementStatements.append(.space(indent))
                    }
                    needsLinebreak = true

                    if condition.isLetBinding,
                       let identifier = condition.identifier,
                       let expression = condition.expression
                    {
                        // Transform let binding
                        let expressionTokens = formatter.tokens[expression]

                        replacementStatements.append(contentsOf: [
                            .keyword("let"),
                            .space(" "),
                            .identifier(identifier),
                        ])

                        // Add type annotation if present
                        if let typeAnnotation = condition.typeAnnotation {
                            let typeTokens = formatter.tokens[typeAnnotation]
                            replacementStatements.append(contentsOf: typeTokens)
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
                        replacementStatements.append(.endOfScope(")"))
                    } else {
                        // Transform boolean condition to assertion
                        let conditionTokens = formatter.tokens[condition.startIndex ... condition.endIndex]
                        replacementStatements.append(.identifier(assertFunctionName))
                        replacementStatements.append(.startOfScope("("))
                        replacementStatements.append(contentsOf: conditionTokens)
                        replacementStatements.append(.endOfScope(")"))
                    }
                }

                formatter.replaceTokens(in: guardIndex ... endOfElseScope, with: replacementStatements)
                addedTryStatement = true

                // Only transform one guard per rule execution
                // The formatter will run the rule again if needed
                break
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
