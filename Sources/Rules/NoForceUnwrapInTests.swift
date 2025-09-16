// Created by Cal Stephens on 2025-09-16
// Copyright © 2025 Airbnb Inc. All rights reserved.

import Foundation

public extension FormatRule {
    static let noForceUnwrapInTests = FormatRule(
        help: "Replace force unwraps with `try XCTUnwrap(...)` / `try #require(...)` in test functions.",
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

            var foundAnyForceUnwraps = false

            // Find all expressions that contain force unwraps, starting from assignment operators
            for index in bodyRange {
                guard formatter.tokens[index] == .operator("=", .infix) else { continue }

                // Look for expression after assignment
                guard let expressionStart = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index),
                      let expressionRange = formatter.parseExpressionRange(startingAt: expressionStart) else { continue }

                // Check if this expression contains any force unwraps
                let containsForceUnwraps = expressionRange.contains { i in
                    formatter.tokens[i] == .operator("!", .postfix)
                }

                guard containsForceUnwraps else { continue }
                guard formatter.isInFunctionBody(of: functionDecl, at: expressionStart) else { continue }

                let unwrapFunctionName = testFramework == .xcTest ? "XCTUnwrap" : "#require"

                // Clean the expression by converting ! to ? except the final one, and as! to as?
                let cleanedTokens = formatter.cleanExpressionTokens(in: expressionRange)

                let newTokens: [Token] = [
                    .keyword("try"),
                    .space(" "),
                    .identifier(unwrapFunctionName),
                    .startOfScope("("),
                ] + cleanedTokens + [
                    .endOfScope(")"),
                ]

                // Replace the entire expression
                formatter.replaceTokens(in: expressionRange, with: newTokens)
                foundAnyForceUnwraps = true
            }

            // Handle function call arguments and return statements - process remaining force unwraps
            for index in bodyRange {
                guard formatter.tokens[index] == .operator("!", .postfix) else { continue }
                guard formatter.isInFunctionBody(of: functionDecl, at: index) else { continue }

                // Skip if this force unwrap is already part of an assignment expression we processed
                var skipThis = false
                for assignmentIndex in bodyRange {
                    guard formatter.tokens[assignmentIndex] == .operator("=", .infix) else { continue }
                    if let exprStart = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: assignmentIndex),
                       let exprRange = formatter.parseExpressionRange(startingAt: exprStart),
                       exprRange.contains(index) {
                        skipThis = true
                        break
                    }
                }
                guard !skipThis else { continue }

                let unwrapFunctionName = testFramework == .xcTest ? "XCTUnwrap" : "#require"

                // Simple approach: just replace "identifier!" with "try XCTUnwrap(identifier)"
                if let prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: index),
                   case .identifier(let name) = formatter.tokens[prevIndex] {

                    let newTokens: [Token] = [
                        .keyword("try"),
                        .space(" "),
                        .identifier(unwrapFunctionName),
                        .startOfScope("("),
                        .identifier(name),
                        .endOfScope(")"),
                    ]

                    // Replace identifier and !
                    formatter.replaceTokens(in: prevIndex...index, with: newTokens)
                    foundAnyForceUnwraps = true
                }
            }

            guard foundAnyForceUnwraps else { return }
            formatter.addThrowsEffect(to: functionDecl)
        }
    } examples: {
        """
        ```diff
            import Testing

            struct MyFeatureTests {
        -       @Test func doSomething() {
        +       @Test func doSomething() throws {
        -           let value = optionalValue!
        +           let value = try #require(optionalValue)
              }
            }

            import XCTest

            class MyFeatureTests: XCTestCase {
        -       func test_doSomething() {
        +       func test_doSomething() throws {
        -           let value = optionalValue!
        +           let value = try XCTUnwrap(optionalValue)
              }
            }
        ```
        """
    }
}

extension Formatter {
    /// Check if a given index is inside a XCTUnwrap or #require function call
    func isInsideUnwrapCall(at index: Int, unwrapFunction: String) -> Bool {
        var currentIndex = index
        var parenDepth = 0

        while currentIndex > 0 {
            currentIndex -= 1
            let token = tokens[currentIndex]

            if token == .endOfScope(")") {
                parenDepth += 1
            } else if token == .startOfScope("(") {
                parenDepth -= 1
                if parenDepth < 0 {
                    // We've found the opening paren, check if it's preceded by our unwrap function
                    if let prevIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, before: currentIndex) {
                        let prevToken = tokens[prevIndex]
                        if case .identifier(unwrapFunction) = prevToken {
                            return true
                        }
                    }
                    break
                }
            }
        }

        return false
    }

    /// Find the expression range around a force unwrap that should be wrapped together
    /// This handles cases like: optionalValue! as! String -> optionalValue as? String
    func findUnwrappableExpressionRange(around forceUnwrapIndex: Int) -> ClosedRange<Int> {
        var start = forceUnwrapIndex
        var end = forceUnwrapIndex

        // Walk backwards to find expression start
        while start > 0 {
            let prevIndex = start - 1
            let prevToken = tokens[prevIndex]

            if prevToken.isSpaceOrCommentOrLinebreak {
                start = prevIndex
                continue
            }

            // Include parts of the expression that should be unwrapped together
            switch prevToken {
            case .identifier, .number, .stringBody:
                start = prevIndex
            case .startOfScope("["), .endOfScope("]"), .startOfScope("("), .endOfScope(")"):
                start = prevIndex
            case .operator(".", .infix), .operator("?", .postfix):
                start = prevIndex
            default:
                break
            }
        }

        // Walk forwards to include as! or similar patterns
        while end < tokens.count - 1 {
            let nextIndex = end + 1
            let nextToken = tokens[nextIndex]

            if nextToken.isSpaceOrCommentOrLinebreak {
                end = nextIndex
            } else if case .keyword("as") = nextToken {
                // Include "as" keyword
                end = nextIndex
                // Look for the following ! to include as!
                if let asNextIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: nextIndex),
                   asNextIndex < tokens.count,
                   tokens[asNextIndex] == .operator("!", .postfix) {
                    end = asNextIndex
                    // Include the type after as!
                    if let typeIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: asNextIndex),
                       typeIndex < tokens.count {
                        end = typeIndex
                    }
                }
            } else {
                break
            }
        }

        return start...end
    }

    /// Find the range that contains the unwrappable expression around a force unwrap
    /// For (someDict["key"]! as SomeType).property, this should return just someDict["key"]!
    func findUnwrappableRange(around forceUnwrapIndex: Int) -> ClosedRange<Int> {
        var start = forceUnwrapIndex
        var end = forceUnwrapIndex

        // Walk backwards to find the start of the unwrappable expression
        while start > 0 {
            let prevIndex = start - 1
            let prevToken = tokens[prevIndex]

            // Skip whitespace and comments
            if prevToken.isSpaceOrCommentOrLinebreak {
                start = prevIndex
                continue
            }

            // Include tokens that are part of the core unwrappable expression
            switch prevToken {
            case .identifier, .number, .stringBody, .endOfScope("]"), .endOfScope(")"):
                start = prevIndex
            case .startOfScope("["), .startOfScope("("):
                start = prevIndex
            case .operator(".", .infix):
                start = prevIndex
            case .operator("?", .postfix):
                start = prevIndex
            default:
                // Stop at anything else (operators, keywords, etc.)
                break
            }
        }

        // Walk forwards but be conservative - only include trailing whitespace
        while end < tokens.count - 1 {
            let nextIndex = end + 1
            let nextToken = tokens[nextIndex]

            if nextToken.isSpaceOrCommentOrLinebreak {
                end = nextIndex
            } else {
                break
            }
        }

        return start...end
    }

    /// Find the start of an expression by walking backwards from a given index
    func findExpressionStart(before index: Int) -> Int? {
        var currentIndex = index

        // Walk backwards to find expression boundaries
        while currentIndex > 0 {
            let previousIndex = currentIndex - 1
            let token = tokens[previousIndex]

            // Stop at statement boundaries
            if token == .endOfScope("}") || token == .delimiter(";") || token.isLinebreak {
                break
            }

            // Stop at assignment operators
            if case .operator("=", .infix) = token {
                return self.index(of: .nonSpaceOrCommentOrLinebreak, after: previousIndex)
            }

            // Stop at function call boundaries
            if case .startOfScope("(") = token,
               let prevTokenIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, before: previousIndex),
               case .identifier = tokens[prevTokenIndex] {
                return previousIndex
            }

            // Stop at return statements
            if case .keyword("return") = token {
                return self.index(of: .nonSpaceOrCommentOrLinebreak, after: previousIndex)
            }

            currentIndex = previousIndex
        }

        return currentIndex
    }

    /// Clean expression tokens by converting force unwraps and force casts to safe equivalents
    func cleanExpressionTokens(in range: ClosedRange<Int>) -> [Token] {
        var result: [Token] = []
        var processedIndices = Set<Int>()

        for i in range {
            if processedIndices.contains(i) {
                continue
            }

            let token = tokens[i]

            if case .keyword("as") = token {
                // Check if this is followed by ! (force cast)
                if let nextNonSpaceIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: i),
                   nextNonSpaceIndex <= range.upperBound,
                   tokens[nextNonSpaceIndex] == .operator("!", .postfix) {
                    // Convert as! to as?
                    result.append(.keyword("as"))
                    result.append(.operator("?", .postfix))
                    processedIndices.insert(nextNonSpaceIndex) // Mark the ! as processed
                } else {
                    result.append(token)
                }
            } else if token == .operator("!", .postfix) {
                // Check if this force unwrap should become optional chaining
                if let nextNonSpaceIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: i),
                   nextNonSpaceIndex <= range.upperBound,
                   tokens[nextNonSpaceIndex] == .operator(".", .infix) {
                    result.append(.operator("?", .postfix))
                }
                // Otherwise skip the force unwrap (final one is handled by wrapper)
            } else {
                result.append(token)
            }
        }

        return result
    }
}
