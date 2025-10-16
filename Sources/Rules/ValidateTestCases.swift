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
        Ensure test methods have appropriate naming conventions.
        For XCTest: test methods should have 'test' prefix.
        For Swift Testing: test methods should have @Test attribute.
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
        let testClasses = declarations.compactMap(\.asTypeDeclaration).filter { typeDecl in
            formatter.isLikelyTestCase(typeDecl, for: testFramework)
        }

        for testClass in testClasses {
            // If the type has an init with parameters, it's not a test suite
            let hasParameterizedInit = testClass.body.contains { member in
                guard member.keyword == "init",
                      let initDecl = formatter.parseFunctionDeclaration(keywordIndex: member.keywordIndex)
                else { return false }
                return !initDecl.arguments.isEmpty
            }
            if hasParameterizedInit {
                continue
            }

            // Process each member of the test class
            for member in testClass.body {
                if member.keyword == "func" {
                    formatter.validateTestNaming(member, for: testFramework, identifierCounts: identifierCounts)
                }
            }
        }
    } examples: {
        """
        ```diff
          import XCTest

          final class MyTests: XCTestCase {
        -     func example() {
        +     func testExample() {
                  XCTAssertTrue(true)
              }
          }
        ```

        ```diff
          import Testing

          struct MyFeatureTests {
        -     func featureWorks() {
        +     @Test func featureWorks() {
                  #expect(true)
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

    /// Determines if a type declaration is likely a test case based on naming, structure, and framework conventions.
    /// Returns true if the type should be processed as a test suite.
    func isLikelyTestCase(_ typeDecl: TypeDeclaration, for testFramework: TestingFramework) -> Bool {
        guard let name = typeDecl.name else { return false }

        // Don't apply to classes that contain "Base" (they're likely meant to be subclassed)
        if name.contains("Base") {
            return false
        }

        // Don't apply to classes with a doc comment like "Base class for XYZ functionality"
        if let docCommentRange = typeDecl.docCommentRange {
            let subclassRelatedTerms = ["base", "subclass"]
            let docComment = tokens[docCommentRange].string.lowercased()

            for term in subclassRelatedTerms {
                if docComment.contains(term) {
                    return false
                }
            }
        }

        // Valid test suffixes for identifying test types
        let testSuffixes = ["Test", "Tests", "TestCase", "TestCases", "Suite"]

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
            if hasTestSuffix, typeDecl.conformances.isEmpty {
                return hasTestLikeFunction(in: typeDecl)
            }

            // Otherwise, exclude it
            return false

        case .swiftTesting:
            // For Swift Testing, apply to classes/structs with specific test suffixes
            // but only if they have test-like functions
            if testSuffixes.contains(where: { name.hasSuffix($0) }) {
                return hasTestLikeFunction(in: typeDecl)
            }
            return false
        }
    }

    /// Validates a function in a test class has the correct naming conventions.
    func validateTestNaming(_ function: Declaration, for framework: TestingFramework, identifierCounts: [String: Int]) {
        // Use the shared helper to determine if this should be treated as a test
        if shouldBeTreatedAsTest(function, for: framework, identifierCounts: identifierCounts) {
            // For XCTest, ensure test methods have "test" prefix
            if framework == .xcTest {
                ensureTestPrefix(function, identifierCounts: identifierCounts)
            }

            // For Swift Testing, ensure test methods have @Test attribute
            if framework == .swiftTesting {
                ensureTestAttribute(function)
            }
        }
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
}
