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
        help: """
        Ensure test methods are internal and helper methods/properties are private.
        For XCTest: test methods with 'test' prefix should be internal.
        For Swift Testing: test methods with @Test attribute should be internal.
        Helper methods and properties should be private.
        """,
        disabledByDefault: true
    ) { formatter in
        guard let testFramework = formatter.detectTestingFramework() else {
            return
        }

        let declarations = formatter.parseDeclarations()
        let testClasses = declarations.compactMap(\.asTypeDeclaration).filter { typeDecl in
            formatter.isLikelyTestCase(typeDecl, for: testFramework)
        }

        for testClass in testClasses {
            // Skip types with parameterized initializers (not test suites)
            guard !formatter.hasParameterizedInitializer(testClass) else { continue }

            // The test class itself should be internal unless marked as open
            formatter.validateTestTypeAccessControl(testClass)

            // Process each member of the test class
            for member in testClass.body {
                switch member.keyword {
                case "func":
                    formatter.validateTestFunctionAccessControl(member, for: testFramework)

                case "init":
                    // Initializers should be internal unless marked as open
                    formatter.validateTestTypeAccessControl(member)

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

        -     public func helperMethod() {
        +     private func helperMethod() {
                  // helper code
              }

        -     var someProperty: String = ""
        +     private var someProperty: String = ""
          }
        ```

        ```diff
          import Testing

          struct MyFeatureTests {
        -     public func featureWorks() {
        +     @Test func featureWorks() {
                  #expect(true)
              }

        -     public func helperMethod() {
        +     private func helperMethod() {
                  // helper code
              }
          }
        ```
        """
    }
}

extension Formatter {
    /// Validates that a test type (class/struct) or its initializer has internal access control.
    func validateTestTypeAccessControl(_ declaration: Declaration) {
        // If marked as open, leave it as is
        if declaration.modifiers.contains("open") {
            return
        }

        // Remove any non-internal, non-open ACL modifiers
        removeACLModifiers(from: declaration, except: ["internal", "open"])
    }

    /// Validates that a function in a test class has the correct access control.
    func validateTestFunctionAccessControl(_ function: Declaration, for framework: TestingFramework) {
        guard let functionDecl = parseFunctionDeclaration(keywordIndex: function.keywordIndex) else {
            return
        }

        let modifiers = function.modifiers

        // Skip if it's already private/fileprivate (respect explicit access control)
        if modifiers.contains("private") || modifiers.contains("fileprivate") {
            return
        }

        // Skip if it's an override, has @objc, or is static (might be called from outside)
        if modifiers.contains("override") || modifiers.contains("@objc") || modifiers.contains("static") {
            return
        }

        // Get function name
        guard let nameIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: function.keywordIndex),
              case let .identifier(name) = tokens[nameIndex]
        else { return }

        // If method has a disabled test prefix, keep it internal
        if hasDisabledTestPrefix(name) {
            validateTestMethodAccessControl(function)
            return
        }

        // Check if this is already marked as a test
        let hasTestAttribute = modifiers.contains("@Test")
        let hasTestPrefix = name.hasPrefix("test")

        // For access control, only functions that already have test markers should be internal
        // For XCTest: must have test prefix AND test signature (no params, no return)
        // For Swift Testing: must have @Test attribute
        let hasTestSignature = functionDecl.arguments.isEmpty && functionDecl.returnType == nil
        let isTest: Bool
        if framework == .swiftTesting {
            // For Swift Testing, only @Test functions are tests
            isTest = hasTestAttribute
        } else {
            // For XCTest, must have both test prefix and test signature
            isTest = hasTestPrefix && hasTestSignature
        }

        if isTest {
            // Test methods should be internal
            validateTestMethodAccessControl(function)
        } else {
            // Non-test methods should be private
            ensurePrivateAccessControl(function)
        }
    }

    /// Ensures a test method has internal access control (removes public/private modifiers).
    func validateTestMethodAccessControl(_ declaration: Declaration) {
        // If marked as open, leave it as is
        if declaration.modifiers.contains("open") {
            return
        }

        // Remove any explicit ACL modifiers except internal and open
        removeACLModifiers(from: declaration, except: ["internal", "open"])
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
