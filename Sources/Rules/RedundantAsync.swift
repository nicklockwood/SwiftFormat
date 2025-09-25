//
//  RedundantAsync.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 2025-09-18.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let redundantAsync = FormatRule(
        help: "Remove redundant `async` keyword from function declarations that don't contain any await expressions.",
        disabledByDefault: true,
        options: ["redundant-async"]
    ) { formatter in
        let testFramework = formatter.detectTestingFramework()
        if formatter.options.redundantAsync == .testsOnly, testFramework == nil {
            return
        }

        formatter.forEach(.keyword) { keywordIndex, keyword in
            guard case let .keyword(keyword) = keyword,
                  ["func", "init", "subscript"].contains(keyword),
                  let functionDecl = formatter.parseFunctionDeclaration(keywordIndex: keywordIndex),
                  functionDecl.effects.contains(where: { $0.hasPrefix("async") }),
                  let bodyRange = functionDecl.bodyRange
            else { return }

            // Don't modify override functions - they need to match their parent's signature
            if formatter.modifiersForDeclaration(at: keywordIndex, contains: "override") {
                return
            }

            if formatter.options.redundantAsync == .testsOnly {
                // Only process test functions
                guard keyword == "func", let testFramework,
                      formatter.isTestFunction(at: keywordIndex, in: functionDecl, for: testFramework)
                else { return }
            }

            // Check if the function body contains any await keywords
            var bodyContainsAwait = false
            for index in bodyRange {
                if formatter.tokens[index] == .keyword("await") {
                    // Only count await keywords that are directly in this function's body
                    // (not in nested closures or functions)
                    if formatter.isInFunctionBody(of: functionDecl, at: index) {
                        bodyContainsAwait = true
                        break
                    }
                }
            }

            // If the body doesn't contain any await, remove the async
            if !bodyContainsAwait {
                formatter.removeEffect("async", from: functionDecl)
            }
        }
    } examples: {
        """
        ```diff
          // With --redundant-async tests-only (default)
          import Testing

        - @Test func myFeature() async {
        + @Test func myFeature() {
              #expect(foo == 1)
          }

          import XCTest

          class TestCase: XCTestCase {
        -     func testMyFeature() async {
        +     func testMyFeature() {
                  XCTAssertEqual(foo, 1)
              }
          }
        ```

        Also supports `--redundant-async always`.
        This will cause warnings anywhere the updated method is called with `await`, since `await` is now redundant at the callsite.

        ```diff
          // With --redundant-async always
        - func myNonAsyncMethod() async -> Int {
        + func myNonAsyncMethod() -> Int {
              return 0
          }

          // Possibly elsewhere in codebase:
          let value = await myNonAsyncMethod()
        +             `- warning: no 'async' operations occur within 'await' expression
        ```
        """
    }
}
