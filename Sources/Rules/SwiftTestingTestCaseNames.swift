// Created by Cal Stephens on 2/19/25.
// Copyright © 2025 Airbnb Inc. All rights reserved.

import Foundation

public extension FormatRule {
    static let swiftTestingTestCaseNames = FormatRule(
        help: "Format Swift Testing @Test and @Suite names.",
        options: ["test-case-name-format", "suite-name-format"]
    ) { formatter in
        guard formatter.hasImport("Testing") else { return }

        formatter.forEach(.keyword("func")) { funcKeywordIndex, _ in
            guard formatter.modifiersForDeclaration(at: funcKeywordIndex, contains: "@Test") else { return }

            formatter.removeTestPrefix(fromFunctionAt: funcKeywordIndex)

            switch formatter.options.testCaseNameFormat {
            case .rawIdentifiers:
                guard formatter.options.swiftVersion >= "6.2" else { return }
                formatter.convertToRawIdentifier(forDeclarationAt: funcKeywordIndex, macroName: "@Test", upperCamelCase: false)

            case .standardIdentifiers:
                formatter.convertToStandardIdentifier(forDeclarationAt: funcKeywordIndex, macroName: "@Test", upperCamelCase: false)

            case .preserve:
                break
            }
        }

        let typeKeywords: [String] = ["struct", "class", "actor", "enum"]
        formatter.parseDeclarations().forEachRecursiveDeclaration { declaration in
            guard typeKeywords.contains(declaration.keyword) else { return }
            guard declaration.hasModifier("@Suite")
                || declaration.body?.contains(where: { $0.keyword == "func" && $0.hasModifier("@Test") }) == true
            else { return }

            let keywordIndex = declaration.keywordIndex
            switch formatter.options.suiteNameFormat {
            case .rawIdentifiers:
                guard formatter.options.swiftVersion >= "6.2" else { return }
                formatter.convertToRawIdentifier(forDeclarationAt: keywordIndex, macroName: "@Suite", upperCamelCase: true)

            case .standardIdentifiers:
                formatter.convertToStandardIdentifier(forDeclarationAt: keywordIndex, macroName: "@Suite", upperCamelCase: true)

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
    /// Converts a declaration name to use a raw identifier (backtick-quoted name with spaces).
    /// If the macro attribute has a display name, uses that as the name and removes it from the attribute.
    /// Otherwise, converts the camelCase/underscore name to a space-separated raw identifier.
    func convertToRawIdentifier(forDeclarationAt keywordIndex: Int, macroName: String, upperCamelCase _: Bool) {
        guard let nameIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: keywordIndex),
              tokens[nameIndex].isIdentifier
        else { return }

        let name = tokens[nameIndex].string

        // Check if the macro attribute has a display name argument
        if var displayName = macroDisplayName(forDeclarationAt: keywordIndex, macroName: macroName) {
            // Remove any existing backticks from the name, since raw identifiers can't contain backticks
            displayName = displayName.replacingOccurrences(of: "`", with: "")

            let newName = "`\(displayName)`"
            updateDeclarationName(forDeclarationAt: keywordIndex, to: newName)
            removeMacroDisplayNameString(forDeclarationAt: keywordIndex, macroName: macroName)
        } else {
            // Convert the name to a raw identifier
            let baseName = name.camelCaseToWords()
            guard !baseName.isEmpty, baseName != name else { return }

            let newName = "`\(baseName)`"
            guard tokens[nameIndex] != .identifier(newName) else { return }

            updateDeclarationName(forDeclarationAt: keywordIndex, to: newName)
        }
    }

    /// Converts a raw identifier declaration name to a standard identifier, and removes
    /// any display name string from the macro attribute.
    func convertToStandardIdentifier(forDeclarationAt keywordIndex: Int, macroName: String, upperCamelCase: Bool) {
        // Remove display name string from the macro attribute if present
        removeMacroDisplayNameString(forDeclarationAt: keywordIndex, macroName: macroName)

        guard let nameIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: keywordIndex),
              tokens[nameIndex].isIdentifier
        else { return }

        let name = tokens[nameIndex].string

        // Only convert raw identifiers (backtick-quoted names)
        guard name.hasPrefix("`"), name.hasSuffix("`") else { return }

        let rawName = String(name.dropFirst().dropLast())
        let newName = rawName.wordsToIdentifier(upperCamelCase: upperCamelCase)
        guard !newName.isEmpty, newName != name else { return }

        updateDeclarationName(forDeclarationAt: keywordIndex, to: newName)
    }

    /// Extracts the display name string from a macro attribute like `@Test("display name")` or `@Suite("display name")`.
    func macroDisplayName(forDeclarationAt keywordIndex: Int, macroName: String) -> String? {
        var macroAttrIndex: Int?
        _ = modifiersForDeclaration(at: keywordIndex, contains: { index, modifier in
            if modifier.hasPrefix("\(macroName)(") || modifier.hasPrefix("\(macroName) (") {
                macroAttrIndex = index
                return true
            }
            return false
        })

        guard let attrIndex = macroAttrIndex,
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

    /// Removes the display name from a macro attribute like `@Test("display name")` or `@Suite("display name", ...)`.
    func removeMacroDisplayNameString(forDeclarationAt keywordIndex: Int, macroName: String) {
        var macroAttrIndex: Int?
        _ = modifiersForDeclaration(at: keywordIndex, contains: { index, modifier in
            if modifier.hasPrefix("\(macroName)(") || modifier.hasPrefix("\(macroName) (") {
                macroAttrIndex = index
                return true
            }
            return false
        })

        guard let attrIndex = macroAttrIndex,
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
            // Also remove any space between the macro and (
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

        // Merge a lone single lowercase leading character with a following all-uppercase word.
        // This handles acronym-first names after test prefix removal, e.g. "uUID" (from "testUUID") → "UUID".
        if words.count >= 2,
           words[0].count == 1,
           words[0].first?.isLowercase == true,
           words[1].allSatisfy(\.isUppercase)
        {
            words = [words[0].uppercased() + words[1]] + Array(words.dropFirst(2))
        }

        // Lowercase each word, but preserve all-uppercase words (acronyms like UUID, URL, ABC).
        return words.map { $0.allSatisfy(\.isUppercase) ? $0 : $0.lowercased() }.joined(separator: " ")
    }

    /// Splits a camelCase string into individual words, treating consecutive uppercase letters as acronyms.
    /// For example: "UUIDIsValid" → ["UUID", "Is", "Valid"], "alphabetStartsWithABC" → ["alphabet", "Starts", "With", "ABC"].
    func splitCamelCase() -> [String] {
        var words: [String] = []
        var currentWord = ""
        let chars = Array(self)

        for i in 0 ..< chars.count {
            let char = chars[i]
            let nextChar = i + 1 < chars.count ? chars[i + 1] : nil

            if char.isUppercase {
                if currentWord.isEmpty {
                    currentWord.append(char)
                } else if currentWord.last!.isLowercase {
                    // Lower→Upper transition: start a new word
                    words.append(currentWord)
                    currentWord = String(char)
                } else if let next = nextChar, next.isLowercase {
                    // Uppercase sequence followed by lowercase: this char starts a new word
                    // e.g. "UUIDIs" → "UUID" + "Is"
                    words.append(currentWord)
                    currentWord = String(char)
                } else {
                    // Continue accumulating the uppercase sequence (acronym)
                    currentWord.append(char)
                }
            } else {
                currentWord.append(char)
            }
        }

        if !currentWord.isEmpty {
            words.append(currentWord)
        }

        return words
    }

    /// Converts a space-separated string to a standard identifier (camelCase or UpperCamelCase).
    /// For example: "my test case" -> "myTestCase" (lowerCamelCase) or "MyTestCase" (upperCamelCase).
    func wordsToIdentifier(upperCamelCase: Bool) -> String {
        let words = split(separator: " ").map(String.init)
        guard !words.isEmpty else { return "" }

        var result = ""
        for (index, word) in words.enumerated() {
            guard !word.isEmpty else { continue }
            if index == 0, !upperCamelCase {
                result += word.prefix(1).lowercased() + word.dropFirst()
            } else {
                result += word.prefix(1).uppercased() + word.dropFirst()
            }
        }
        return result
    }
}
