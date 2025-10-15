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
        help: """
        Validate that test case members have the correct access control and naming.
        For XCTest: test methods should have 'test' prefix and be internal.
        For Swift Testing: test methods should have @Test attribute and be internal.
        Helper methods and properties should be private.
        """,
        disabledByDefault: true
    ) { formatter in
        guard let testFramework = formatter.detectTestingFramework() else {
            return
        }

        // Collect all identifiers referenced in the file
        // Count occurrences - if > 1, the identifier is referenced somewhere
        let identifierCounts = formatter.tokens.reduce(into: [String: Int]()) { counts, token in
            if case let .identifier(name) = token {
                counts[name, default: 0] += 1
            }
        }

        let declarations = formatter.parseDeclarations()

        // Valid test suffixes for identifying test types
        let testSuffixes = ["Test", "Tests", "TestCase", "TestCases", "Suite"]

        let testClasses = declarations.compactMap(\.asTypeDeclaration).filter { typeDecl in
            guard let name = typeDecl.name else { return false }

            // Don't apply to classes that contain "Base" (they're likely meant to be subclassed)
            if name.contains("Base") {
                return false
            }

            // Don't apply to classes with a doc comment like "Base class for XYZ functionality"
            if let docCommentRange = typeDecl.docCommentRange {
                let subclassRelatedTerms = ["base", "subclass"]
                let docComment = formatter.tokens[docCommentRange].string.lowercased()

                for term in subclassRelatedTerms {
                    if docComment.contains(term) {
                        return false
                    }
                }
            }

            switch testFramework {
            case .xcTest:
                // For XCTest, only process classes (not structs)
                guard typeDecl.keyword == "class" else { return false }

                let conformsToXCTestCase = typeDecl.conformances.contains { $0.conformance.string == "XCTestCase" }
                let hasTestSuffix = testSuffixes.contains { name.hasSuffix($0) }
                let hasOtherConformances = typeDecl.conformances.contains { $0.conformance.string != "XCTestCase" }

                // If it has conformances other than XCTestCase, skip it entirely
                // (methods could be protocol requirements)
                if hasOtherConformances {
                    return false
                }

                // If it conforms to XCTestCase only, include it
                if conformsToXCTestCase {
                    return true
                }

                // If it has a test suffix and no conformances, check if it has test-like functions
                // (we'll add XCTestCase conformance later)
                if hasTestSuffix, typeDecl.conformances.isEmpty {
                    return formatter.hasTestLikeFunction(in: typeDecl)
                }

                // Otherwise, exclude it
                return false

            case .swiftTesting:
                // For Swift Testing, apply to classes/structs with specific test suffixes
                // but only if they have test-like functions
                if testSuffixes.contains(where: { name.hasSuffix($0) }) {
                    return formatter.hasTestLikeFunction(in: typeDecl)
                }
                return false
            }
        }

        for testClass in testClasses {
            // For XCTest, add XCTestCase conformance if missing and it has a test suffix
            if testFramework == .xcTest {
                formatter.ensureXCTestCaseConformance(testClass, testSuffixes: testSuffixes)
            }

            // The test class itself should be internal unless marked as open
            formatter.validateTestTypeAccessControl(testClass)

            // Process each member of the test class
            for member in testClass.body {
                switch member.keyword {
                case "func":
                    formatter.validateTestFunction(member, in: testClass, for: testFramework, identifierCounts: identifierCounts)

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
    /// Checks if a type has at least one function that looks like a test (no arguments, no return type).
    func hasTestLikeFunction(in typeDecl: TypeDeclaration) -> Bool {
        for member in typeDecl.body where member.keyword == "func" {
            guard let functionDecl = parseFunctionDeclaration(keywordIndex: member.keywordIndex) else {
                continue
            }

            // Check if it has test-like signature (no args, no return type)
            if functionDecl.arguments.isEmpty, functionDecl.returnType == nil {
                return true
            }
        }
        return false
    }

    /// Validates that a test type (class/struct) or its initializer has internal access control.
    func validateTestTypeAccessControl(_ declaration: Declaration) {
        // If marked as open, leave it as is
        if declaration.modifiers.contains("open") {
            return
        }

        // Remove any non-internal, non-open ACL modifiers
        removeACLModifiers(from: declaration, except: ["internal", "open"])
    }

    /// Validates a function in a test class has the correct naming and access control.
    func validateTestFunction(_ function: Declaration, in _: TypeDeclaration, for framework: TestingFramework, identifierCounts: [String: Int]) {
        guard let functionDecl = parseFunctionDeclaration(keywordIndex: function.keywordIndex) else {
            return
        }

        let modifiers = function.modifiers

        // Skip if it's an override, has @objc, or is static (might be called from outside)
        if modifiers.contains("override") || modifiers.contains("@objc") || modifiers.contains("static") {
            return
        }

        // Check if function name is referenced elsewhere in the file
        guard let nameIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: function.keywordIndex),
              case let .identifier(name) = tokens[nameIndex]
        else { return }

        // If method has a disabled test prefix, keep it internal but don't add test attributes/prefix
        let disabledTestPrefixes = ["disable_", "disabled_", "skip_", "skipped_", "x_"]
        if disabledTestPrefixes.contains(where: { name.hasPrefix($0) }) {
            validateTestMethodAccessControl(function)
            return
        }

        let isReferenced = identifierCounts[name, default: 0] > 1

        // Determine if this should be a test method based on signature and whether it's referenced
        let hasTestSignature = functionDecl.arguments.isEmpty && functionDecl.returnType == nil
        let shouldBeTest = hasTestSignature && !isReferenced

        if shouldBeTest {
            // For XCTest, ensure test methods have "test" prefix
            if framework == .xcTest {
                ensureTestPrefix(function, identifierCounts: identifierCounts)
            }

            // For Swift Testing, ensure test methods have @Test attribute
            if framework == .swiftTesting {
                ensureTestAttribute(function)
            }

            // Test methods should be internal
            validateTestMethodAccessControl(function)
        } else {
            // Non-test methods (including referenced methods) should be private
            // Skip if already has appropriate access control
            if modifiers.contains("private") || modifiers.contains("fileprivate") {
                return
            }

            // Make it private
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

    /// Ensures a test method has internal access control (removes public/private modifiers).
    func validateTestMethodAccessControl(_ declaration: Declaration) {
        // If marked as open, leave it as is
        if declaration.modifiers.contains("open") {
            return
        }

        // Remove any explicit ACL modifiers except internal and open
        removeACLModifiers(from: declaration, except: ["internal", "open"])
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

    /// Ensures a function has a "test" prefix.
    func ensureTestPrefix(_ function: Declaration, identifierCounts: [String: Int]) {
        guard let nameIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: function.keywordIndex),
              case let .identifier(name) = tokens[nameIndex]
        else { return }

        // If it already has a "test" prefix, do nothing
        if name.hasPrefix("test") {
            return
        }

        // If the method is referenced elsewhere in the file, don't add prefix
        // A count > 1 means it appears in the definition and at least one other place
        if let count = identifierCounts[name], count > 1 {
            return
        }

        // Add "test" prefix to the function name
        let newName = "test" + name.prefix(1).uppercased() + name.dropFirst()
        replaceToken(at: nameIndex, with: .identifier(newName))
    }

    /// Ensures a function has the @Test attribute.
    func ensureTestAttribute(_ function: Declaration) {
        // Check if the function already has @Test attribute
        if modifiersForDeclaration(at: function.keywordIndex, contains: "@Test") {
            return
        }

        // Add @Test attribute before the function
        let insertIndex = startOfModifiers(at: function.keywordIndex, includingAttributes: true)
        insert(tokenize("@Test "), at: insertIndex)
    }

    /// Ensures a class has XCTestCase conformance if it has a test suffix but doesn't already conform.
    func ensureXCTestCaseConformance(_ typeDecl: TypeDeclaration, testSuffixes: [String]) {
        // Only apply to classes (not structs, enums, etc.)
        guard typeDecl.keyword == "class" else { return }

        // Check if the class name has a test suffix
        guard let name = typeDecl.name,
              testSuffixes.contains(where: { name.hasSuffix($0) })
        else { return }

        // Check if already conforms to XCTestCase
        let alreadyConforms = typeDecl.conformances.contains { $0.conformance.string == "XCTestCase" }
        guard !alreadyConforms else { return }

        // Find where to insert the conformance
        // Look for the opening brace of the class body
        guard let openBraceIndex = index(of: .startOfScope("{"), after: typeDecl.keywordIndex),
              let nameIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: typeDecl.keywordIndex),
              case .identifier = tokens[nameIndex]
        else { return }

        // Check if there's already a colon (for existing conformances/superclass)
        if index(of: .delimiter(":"), in: nameIndex ..< openBraceIndex) != nil {
            // There's already a conformance list, which could include a base class
            // Since we can't reliably distinguish between a base class and protocols,
            // we conservatively skip adding XCTestCase to avoid creating invalid code
            // (a class can only have one superclass in Swift)
            return
        } else {
            // No existing conformances, add ": XCTestCase" before the opening brace
            // Find the last token before the opening brace (ignoring whitespace/comments)
            guard let insertIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: openBraceIndex) else { return }
            insert(tokenize(": XCTestCase"), at: insertIndex + 1)
        }
    }
}
