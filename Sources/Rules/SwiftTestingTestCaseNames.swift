// Created by Cal Stephens on 2/19/25.
// Copyright © 2025 Airbnb Inc. All rights reserved.

import Foundation

public extension FormatRule {
    static let swiftTestingTestCaseNames = FormatRule(
        help: "In Swift Testing, don't prefix @Test methods with 'test', and use raw identifier test function names.",
        options: ["test-case-name-format"]
    ) { formatter in
        guard formatter.hasImport("Testing") else { return }

        formatter.forEach(.keyword("func")) { funcKeywordIndex, _ in
            guard formatter.modifiersForDeclaration(at: funcKeywordIndex, contains: "@Test") else { return }

            formatter.removeTestPrefix(fromFunctionAt: funcKeywordIndex)

            switch formatter.options.testCaseNameFormat {
            case .rawIdentifiers:
                guard formatter.options.swiftVersion >= "6.2" else { return }
                formatter.convertToRawIdentifier(forTestFunctionAt: funcKeywordIndex)

            case .preserve:
                break
            }
        }
    } examples: {
        """
        ```diff
          import Testing

          struct MyFeatureTests {
        -     @Test func testMyFeatureHasNoBugs() {
        +     @Test func `my feature has no bugs`() {
                  let myFeature = MyFeature()
                  myFeature.runAction()
                  #expect(!myFeature.hasBugs, "My feature has no bugs")
                  #expect(myFeature.crashes.isEmpty, "My feature doesn't crash")
                  #expect(myFeature.crashReport == nil)
              }

        -     @Test func `test feature works as expected`(_ feature: Feature) {
        +     @Test func `feature works as expected`(_ feature: Feature) {
                let myFeature = MyFeature()
                myFeature.run(feature)
                #expect(myFeature.worksAsExpected)
            }
          }
        ```
        """
    }
}

extension Formatter {
    /// Converts a `@Test` function name to use a raw identifier (backtick-quoted name with spaces).
    /// If the `@Test` attribute has a display name, uses that as the function name and removes it from the attribute.
    /// Otherwise, converts the camelCase/underscore function name to a space-separated raw identifier.
    func convertToRawIdentifier(forTestFunctionAt funcKeywordIndex: Int) {
        guard let methodNameIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: funcKeywordIndex),
              tokens[methodNameIndex].isIdentifier
        else { return }

        let methodName = tokens[methodNameIndex].string

        // Check if the @Test attribute has a display name argument
        if var displayName = testDisplayName(forDeclarationAt: funcKeywordIndex) {
            // Remove any existing backticks from the test name, since raw identifiers cant contain backticks
            displayName = displayName.replacingOccurrences(of: "`", with: "")

            let newMethodName = "`\(displayName)`"
            updateFunctionName(forFunctionAt: funcKeywordIndex, to: newMethodName)
            removeTestDisplayNameString(forDeclarationAt: funcKeywordIndex)
        } else {
            // Convert the method name to a raw identifier
            let baseName = methodName.camelCaseToWords()
            guard !baseName.isEmpty, baseName != methodName else { return }

            let newMethodName = "`\(baseName)`"
            guard tokens[methodNameIndex] != .identifier(newMethodName) else { return }

            updateFunctionName(forFunctionAt: funcKeywordIndex, to: newMethodName)
        }
    }

    /// Extracts the display name string from a `@Test("display name")` attribute, if present.
    func testDisplayName(forDeclarationAt funcKeywordIndex: Int) -> String? {
        // Walk backwards from `func` to find `@Test`
        var testAttrIndex: Int?
        _ = modifiersForDeclaration(at: funcKeywordIndex, contains: { index, modifier in
            if modifier.hasPrefix("@Test(") || modifier.hasPrefix("@Test (") {
                testAttrIndex = index
                return true
            }
            return false
        })

        guard let attrIndex = testAttrIndex,
              let parenStart = index(of: .startOfScope("("), after: attrIndex),
              let firstToken = index(of: .nonSpaceOrCommentOrLinebreak, after: parenStart),
              tokens[firstToken] == .startOfScope("\"")
        else { return nil }

        // Collect string content between the opening and closing quotes
        guard let stringEnd = endOfScope(at: firstToken) else { return nil }

        // Extract the string literal content (between the quotes)
        var displayName = ""
        for i in (firstToken + 1) ..< stringEnd {
            displayName += tokens[i].string
        }

        return displayName.isEmpty ? nil : displayName
    }

    /// Removes the display name from a `@Test("display name")` or `@Test("display name", ...)` attribute.
    func removeTestDisplayNameString(forDeclarationAt funcKeywordIndex: Int) {
        var testAttrIndex: Int?
        _ = modifiersForDeclaration(at: funcKeywordIndex, contains: { index, modifier in
            if modifier.hasPrefix("@Test(") || modifier.hasPrefix("@Test (") {
                testAttrIndex = index
                return true
            }
            return false
        })

        guard let attrIndex = testAttrIndex,
              let parenStart = index(of: .startOfScope("("), after: attrIndex),
              let firstToken = index(of: .nonSpaceOrCommentOrLinebreak, after: parenStart),
              tokens[firstToken] == .startOfScope("\""),
              let stringEnd = endOfScope(at: firstToken)
        else { return }

        let parenEnd = endOfScope(at: parenStart)!

        // Check if there are additional arguments after the display name
        if let nextToken = index(of: .nonSpaceOrCommentOrLinebreak, after: stringEnd),
           tokens[nextToken] == .delimiter(",")
        {
            // Remove from the string start through the comma and any trailing space
            let removeEnd = index(of: .nonSpaceOrComment, after: nextToken) ?? (nextToken + 1)
            removeTokens(in: firstToken ..< removeEnd)
        } else {
            // This is the only argument — remove the entire parentheses
            // Also remove any space between @Test and (
            let removeStart = (index(of: .nonSpaceOrComment, after: attrIndex) == parenStart)
                ? (attrIndex + 1) : parenStart
            removeTokens(in: removeStart ... parenEnd)
        }
    }
}

extension String {
    /// Converts a method name (camelCase, underscore-separated, or already-backticked) to space-separated words.
    /// Returns an empty string if conversion isn't possible.
    func camelCaseToWords() -> String {
        let baseName = self

        // Handle existing raw identifiers: `some name` -> some name
        if baseName.hasPrefix("`"), baseName.hasSuffix("`") {
            return String(baseName.dropFirst().dropLast())
        }

        guard !baseName.isEmpty, baseName.first?.isLetter == true else { return "" }

        // Split on underscores and camelCase boundaries, then join with spaces
        var words: [String] = []
        for segment in baseName.split(separator: "_") {
            words.append(contentsOf: String(segment).splitCamelCase())
        }

        return words.joined(separator: " ").lowercased()
    }

    /// Splits a camelCase string into individual words.
    func splitCamelCase() -> [String] {
        var words: [String] = []
        var currentWord = ""

        for char in self {
            if char.isUppercase, !currentWord.isEmpty {
                words.append(currentWord)
                currentWord = String(char)
            } else {
                currentWord.append(char)
            }
        }

        if !currentWord.isEmpty {
            words.append(currentWord)
        }

        return words
    }
}
