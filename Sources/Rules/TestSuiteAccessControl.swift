//
//  TestSuiteAccessControl.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 10/15/25.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let testSuiteAccessControl = FormatRule(
        help: "Test methods should have the configured visibility (default internal), and other properties / functions in a test suite should be private.",
        disabledByDefault: true,
        options: ["test-visibility"]
    ) { formatter in
        guard let testFramework = formatter.detectTestingFramework() else {
            return
        }

        // Determine the effective test visibility based on options and framework.
        // XCTest requires test methods to be at least internal so the runtime can discover them.
        let configuredVisibility = formatter.options.testVisibility
        let effectiveTestVisibility: Visibility
        if testFramework == .xcTest,
           configuredVisibility == .private || configuredVisibility == .fileprivate
        {
            effectiveTestVisibility = .internal
        } else {
            effectiveTestVisibility = configuredVisibility
        }

        let declarations = formatter.parseDeclarations()
        let testClasses = declarations.compactMap(\.asTypeDeclaration).filter { typeDecl in
            formatter.isSimpleTestSuite(typeDecl, for: testFramework)
        }

        for testClass in testClasses {
            // The test class itself should have the configured visibility unless marked as open
            formatter.ensureTestDeclarationAccessControl(testClass, visibility: effectiveTestVisibility)

            // Process each member of the test class
            for member in testClass.body {
                switch member.keyword {
                case "func":
                    formatter.validateTestFunctionAccessControl(member, for: testFramework, testVisibility: effectiveTestVisibility)

                case "init":
                    // Initializers should have the configured visibility unless marked as open
                    formatter.ensureTestDeclarationAccessControl(member, visibility: effectiveTestVisibility)

                case "let", "var":
                    // Properties should be private unless they have special attributes
                    formatter.validateTestProperty(member, for: testFramework)

                default:
                    break
                }
            }
        }
    } examples: {
        """
        ```diff
          import XCTest

          final class MyTests: XCTestCase {
        -     public func testExample() {
        +     func testExample() {
                  XCTAssertTrue(true)
              }

        -     func helperMethod() {
        +     private func helperMethod() {
                  // helper code
              }
          }
        ```

        ```diff
          import Testing

          struct MyFeatureTests {
        -     @Test public func featureWorks() {
        +     @Test func featureWorks() {
                  #expect(true)
              }

        -     func helperMethod() {
        +     private func helperMethod() {
                  // helper code
              }
          }
        ```
        """
    }
}

extension Formatter {
    /// Validates that a test type (class/struct) or its initializer has the required access control.
    func ensureTestDeclarationAccessControl(_ declaration: Declaration, visibility: Visibility) {
        // If marked as open, leave it as is
        if declaration.modifiers.contains("open") {
            return
        }

        ensureAccessControl(declaration, visibility: visibility)
    }

    /// Validates that a function in a test class has the correct access control.
    func validateTestFunctionAccessControl(_ function: Declaration, for framework: TestingFramework, testVisibility: Visibility) {
        guard let functionDecl = parseFunctionDeclaration(keywordIndex: function.keywordIndex) else {
            return
        }

        let modifiers = function.modifiers

        // Skip if it's an override, has @objc, or is static (might be called from outside)
        if modifiers.contains("override") || modifiers.contains("@objc") || modifiers.contains("static") {
            return
        }

        // Get function name
        guard let nameIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: function.keywordIndex),
              case let .identifier(name) = tokens[nameIndex]
        else { return }

        let treatAsTestCase = isTestCase(at: function.keywordIndex, in: functionDecl, for: framework)
            || hasDisabledPrefix(name)

        if treatAsTestCase {
            // For XCTest: Skip if it's already private/fileprivate (respect explicit access control)
            if framework == .xcTest, modifiers.contains("private") || modifiers.contains("fileprivate") {
                return
            }
            // Test methods should have the configured test visibility
            ensureTestDeclarationAccessControl(function, visibility: testVisibility)
        } else {
            // Non-test methods should be private (but skip if already private/fileprivate)
            if modifiers.contains("private") || modifiers.contains("fileprivate") {
                return
            }
            ensurePrivateAccessControl(function)
        }
    }

    /// Validates that a property in a test class is private.
    func validateTestProperty(_ property: Declaration, for _: TestingFramework) {
        let modifiers = property.modifiers

        // Skip if already private
        if modifiers.contains("private") || modifiers.contains("fileprivate") {
            return
        }

        // Skip if it's static (might be shared state)
        if modifiers.contains("static") {
            return
        }

        // Skip if it has @objc or override
        if modifiers.contains("@objc") || modifiers.contains("override") {
            return
        }

        // Make it private
        ensurePrivateAccessControl(property)
    }

    /// Ensures a declaration has the specified access control level.
    func ensureAccessControl(_ declaration: Declaration, visibility: Visibility) {
        // internal is the default (implicit) visibility in Swift
        if visibility == .internal {
            // Remove any explicit non-internal, non-open ACL modifiers
            removeACLModifiers(from: declaration, except: ["internal", "open"])
            return
        }

        // If already at the right visibility, do nothing
        if declaration.modifiers.contains(visibility.rawValue) {
            return
        }

        // Look for an existing ACL modifier to replace
        for aclModifier in _FormatRules.aclModifiers where aclModifier != "open" {
            if let modifierIndex = indexOfModifier(aclModifier, forDeclarationAt: declaration.keywordIndex) {
                replaceToken(at: modifierIndex, with: .keyword(visibility.rawValue))
                return
            }
        }

        // No ACL modifier exists, so add the visibility before the keyword
        insert([.keyword(visibility.rawValue), .space(" ")], at: declaration.keywordIndex)
    }

    /// Removes ACL modifiers from a declaration, except for the specified exceptions.
    func removeACLModifiers(from declaration: Declaration, except exceptions: [String]) {
        for aclModifier in _FormatRules.aclModifiers where !exceptions.contains(aclModifier) {
            if let modifierIndex = indexOfModifier(aclModifier, forDeclarationAt: declaration.keywordIndex) {
                // Remove the modifier and its trailing space
                if let nextIndex = index(of: .nonSpace, after: modifierIndex), nextIndex > modifierIndex + 1 {
                    removeTokens(in: modifierIndex ... (modifierIndex + 1))
                } else {
                    removeToken(at: modifierIndex)
                }
            }
        }
    }

    /// Ensures a declaration has private access control.
    func ensurePrivateAccessControl(_ declaration: Declaration) {
        let modifiers = declaration.modifiers

        // If already private, do nothing
        if modifiers.contains("private") || modifiers.contains("fileprivate") {
            return
        }

        // Remove any existing ACL modifier
        for aclModifier in _FormatRules.aclModifiers {
            if let modifierIndex = indexOfModifier(aclModifier, forDeclarationAt: declaration.keywordIndex) {
                // Replace the modifier with "private"
                replaceToken(at: modifierIndex, with: .keyword("private"))
                return
            }
        }

        // No ACL modifier exists, so add "private" before the keyword
        insert([.keyword("private"), .space(" ")], at: declaration.keywordIndex)
    }
}
