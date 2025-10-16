//
//  ValidateTestCases.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 10/15/25.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let validateTestCases = FormatRule(
        help: "Ensure test case methods have the correct `test` prefix or `@Test` attribute.",
        disabledByDefault: true
    ) { formatter in
        guard let testFramework = formatter.detectTestingFramework() else {
            return
        }

        let declarations = formatter.parseDeclarations()
        let testClasses = declarations.compactMap(\.asTypeDeclaration).filter { typeDecl in
            formatter.isSimpleTestSuite(typeDecl, for: testFramework)
        }

        for testClass in testClasses {
            for member in testClass.body where member.keyword == "func" {
                if formatter.isLikelyTestCase(member, for: testFramework) {
                    switch testFramework {
                    case .xcTest:
                        formatter.addTestPrefixIfNeeded(member)
                    case .swiftTesting:
                        formatter.addTestAttributeIfNeeded(member)
                    }
                }
            }
        }
    } examples: {
        """
        ```diff
          import XCTest

          final class MyTests: XCTestCase {
        -     func myFeatureWorksCorrectly() {
        +     func testMyFeatureWorksCorrectly() {
                  XCTAssertTrue(myFeature.worksCorrectly)
              }
          }
        ```

        ```diff
          import Testing

          struct MyFeatureTests {
        -     func testMyFeatureWorksCorrectly() {
        +     @Test func myFeatureWorksCorrectly() {
                  #expect(myFeature.worksCorrectly)
              }

        -     func myFeatureHasNoBugs() {
        +     @Test func myFeatureHasNoBugs() {
                  #expect(myFeature.hasNoBugs)
              }
          }
        ```
        """
    }
}

extension Formatter {
    /// Determines if a function should be treated as a test case, even if it's currently missing
    /// its `test` prefix or `@Test` attribute.
    func isLikelyTestCase(
        _ function: Declaration,
        for framework: TestingFramework
    ) -> Bool {
        guard let functionDecl = parseFunctionDeclaration(keywordIndex: function.keywordIndex) else {
            return false
        }

        let modifiers = function.modifiers

        // Skip if it's an override, has @objc, or is static (might be called from outside)
        if modifiers.contains("override") || modifiers.contains("@objc") || modifiers.contains("static") {
            return false
        }

        // Get function name
        guard let nameIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: function.keywordIndex),
              case let .identifier(name) = tokens[nameIndex]
        else { return false }

        // If method has a disabled test prefix, it's not a test
        if hasDisabledPrefix(name) {
            return false
        }

        // Skip if it's explicitly private (definitely not a test)
        if modifiers.contains("private") || modifiers.contains("fileprivate") {
            return false
        }

        // Check if this is already marked as a test
        let hasTestAttribute = modifiers.contains("@Test")

        // A function with test signature (no params, no return type) should be treated as a test
        let hasTestSignature = functionDecl.arguments.isEmpty && functionDecl.returnType == nil

        // For Swift Testing: treat as test if it has @Test or test signature
        if framework == .swiftTesting {
            return hasTestAttribute || hasTestSignature
        }

        // For XCTest: treat as test if it has test signature AND isn't referenced elsewhere
        // Check if the function name appears more than once (definition + at least one reference)
        var occurrences = 0
        for token in tokens {
            if case let .identifier(existingName) = token, existingName == name {
                occurrences += 1
                if occurrences > 1 {
                    // Found at least 2 occurrences (definition + reference), so it's a helper method
                    return false
                }
            }
        }

        return hasTestSignature
    }

    /// Ensures a function has a "test" prefix.
    func addTestPrefixIfNeeded(_ function: Declaration) {
        guard let nameIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: function.keywordIndex),
              case let .identifier(name) = tokens[nameIndex]
        else { return }

        // If it already has a "test" prefix, do nothing
        if name.hasPrefix("test") {
            return
        }

        // Check if the new name would create a collision
        let newName = "test" + name.prefix(1).uppercased() + name.dropFirst()
        let existingIdentifiers = Set(tokens.compactMap { token -> String? in
            if case let .identifier(name) = token {
                return name
            }
            return nil
        })

        // If the new name already exists elsewhere, don't rename
        if existingIdentifiers.contains(newName) {
            return
        }

        // Add "test" prefix to the function name
        replaceToken(at: nameIndex, with: .identifier(newName))
    }

    /// Ensures a function has the @Test attribute.
    func addTestAttributeIfNeeded(_ function: Declaration) {
        // Check if the function already has @Test attribute
        if modifiersForDeclaration(at: function.keywordIndex, contains: "@Test") {
            return
        }

        // Add @Test attribute before the function
        let insertIndex = startOfModifiers(at: function.keywordIndex, includingAttributes: true)
        insert(tokenize("@Test "), at: insertIndex)
    }
}
