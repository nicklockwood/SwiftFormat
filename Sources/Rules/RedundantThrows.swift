//
//  RedundantThrows.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 2025-09-16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let redundantThrows = FormatRule(
        help: "Remove redundant `throws` keyword from function declarations that don't throw any errors.",
        orderAfter: [.noForceUnwrapInTests, .noForceTryInTests, .noGuardInTests, .throwingTests],
        options: ["redundant-throws"]
    ) { formatter in
        let testFramework = formatter.detectTestingFramework()
        if formatter.options.redundantThrows == .testsOnly, testFramework == nil {
            return
        }

        formatter.forEach(.keyword) { keywordIndex, keyword in
            guard case let .keyword(keyword) = keyword, ["func", "init", "subscript"].contains(keyword),
                  let functionDecl = formatter.parseFunctionDeclaration(keywordIndex: keywordIndex),
                  functionDecl.effects.contains(where: { $0.hasPrefix("throws") }),
                  let bodyRange = functionDecl.bodyRange
            else { return }

            // Don't modify override functions - they need to match their parent's signature
            if formatter.modifiersForDeclaration(at: keywordIndex, contains: "override") {
                return
            }

            if formatter.options.redundantThrows == .testsOnly {
                // Only process test functions
                guard keyword == "func", let testFramework,
                      formatter.isTestCase(at: keywordIndex, in: functionDecl, for: testFramework)
                else { return }
            }

            // Check if the function body contains any try keywords (excluding try! and try?) or throw statements
            var bodyContainsThrowingCode = false
            for index in bodyRange {
                if formatter.tokens[index] == .keyword("try") {
                    // Check if this try is followed by ! or ? (which means it doesn't need throws)
                    if let nextTokenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index),
                       formatter.tokens[nextTokenIndex].isUnwrapOperator
                    {
                        continue // Skip try! and try?
                    }

                    // Only count try keywords that are directly in this function's body
                    // (not in nested closures or functions)
                    if formatter.isInFunctionBody(of: functionDecl, at: index) {
                        bodyContainsThrowingCode = true
                        break
                    }
                } else if formatter.tokens[index] == .keyword("throw") {
                    // Only count throw statements that are directly in this function's body
                    // (not in nested closures or functions)
                    if formatter.isInFunctionBody(of: functionDecl, at: index) {
                        bodyContainsThrowingCode = true
                        break
                    }
                }
            }

            // If the body doesn't contain any throwing code, remove the throws
            if !bodyContainsThrowingCode {
                formatter.removeEffect("throws", from: functionDecl)
            }
        }
    } examples: {
        """
        ```diff
          // With --redundant-throws tests-only (default)
          import Testing

        - @Test func myFeature() throws {
        + @Test func myFeature() throws {
              #expect(foo == 1)
          }

          import XCTest

          class TestCase: XCTestCase {
        -     func testMyFeature() throws {
        +     func testMyFeature() {
                  XCTAssertEqual(foo, 1)
              }
          }
        ```

        Also supports `--redundant-throws always`.
        This will cause warnings anywhere the updated method is called with `try`, since `try` is now redundant at the callsite.

        ```diff
          // With --redundant-throws always
        - func myNonThrowingMethod() throws -> Int {
        + func myNonThrowingMethod() -> Int {
              return 0
          }

          // Possibly elsewhere in codebase:
          let value = try myNonThrowingMethod()
        +             `- warning: no calls to throwing functions occur within 'try' expression
        ```
        """
    }
}
