//
//  MetadataTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 11/03/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

private let swiftFormatVersion: String = {
    let string = try! String(contentsOf: projectURL)
    let start = string.range(of: "MARKETING_VERSION = ")!.upperBound
    let end = string.range(of: ";", range: start ..< string.endIndex)!.lowerBound
    return String(string[start ..< end])
}()

private let changelogTitles: [Substring] = {
    let changelog = try! String(contentsOf: changeLogURL, encoding: .utf8)
    var range = changelog.startIndex ..< changelog.endIndex
    var matches = [Substring]()
    while let match = changelog.range(
        of: "## \\[[^]]+\\]\\([^)]+\\) \\([^)]+\\)",
        options: .regularExpression,
        range: range
    ) {
        matches.append(changelog[match])
        range = match.upperBound ..< changelog.endIndex
    }
    return matches
}()

class MetadataTests: XCTestCase {
    // MARK: generate Rules.md

    // NOTE: if test fails, just run it again locally to update rules file
    func testGenerateRulesDocumentation() throws {
        var result = "# Default Rules (enabled by default)\n"
        for rule in FormatRules.default {
            result += "\n* [\(rule.name)](#\(rule.name))"
        }

        result += "\n\n# Opt-in Rules (disabled by default)\n"
        for rule in FormatRules.disabledByDefault {
            guard !rule.isDeprecated else {
                continue
            }
            result += "\n* [\(rule.name)](#\(rule.name))"
        }

        let deprecatedRules = FormatRules.all.filter(\.isDeprecated)
        if !deprecatedRules.isEmpty {
            result += "\n\n# Deprecated Rules (do not use)\n"
            for rule in deprecatedRules {
                result += "\n* [\(rule.name)](#\(rule.name))"
            }
        }

        result += "\n\n----------"
        for rule in FormatRules.all {
            result += "\n\n## \(rule.name)\n\n\(rule.help)"
            if let message = rule.deprecationMessage {
                result += "\n\n*Note: \(rule.name) rule is deprecated. \(message)*"
                continue
            }
            if !rule.options.isEmpty {
                result += "\n\nOption | Description\n--- | ---"
                for option in rule.options {
                    let descriptor = Descriptors.byName[option]!
                    guard !descriptor.isDeprecated else {
                        continue
                    }
                    result += "\n`--\(option)` | \(descriptor.help)"
                }
            }
            if let examples = rule.examples {
                result += "\n\n" + """
                <details>
                <summary>Examples</summary>

                \(examples)

                </details>
                <br/>
                """
            }
        }
        result += "\n"
        let oldRules = try String(contentsOf: rulesURL)
        XCTAssertEqual(result, oldRules)
        try result.write(to: rulesURL, atomically: true, encoding: .utf8)
    }

    // MARK: rules

    func testAllRulesInRulesFile() {
        for ruleName in FormatRules.byName.keys {
            XCTAssertTrue(rulesFile.contains("## \(ruleName)"), """
            Rules.md does not contain \(ruleName) rule (run MetadataTests again to fix)
            """)
        }
    }

    func testNoInvalidRulesInRulesFile() {
        let ruleNames = Set(FormatRules.byName.keys)
        var range = rulesFile.startIndex ..< rulesFile.endIndex
        while let match = rulesFile.range(of: "\\*[a-zA-Z]+\\* - ", options: .regularExpression, range: range, locale: nil) {
            let lower = rulesFile.index(after: match.lowerBound)
            let upper = rulesFile.index(match.upperBound, offsetBy: -4)
            let ruleName = String(rulesFile[lower ..< upper])
            XCTAssertTrue(ruleNames.contains(ruleName), ruleName)
            range = match.upperBound ..< range.upperBound
        }
    }

    func testRuleHelpLinesEndInPeriod() {
        for rule in FormatRules.all {
            XCTAssert(rule.help.hasSuffix(".") || rule.help.hasSuffix(".)"),
                      "\(rule.name) rule help does not end in a period")
        }
    }

    func testRuleExampleDiffsAreValid() throws {
        for rule in FormatRules.all {
            guard let examples = rule.examples else { continue }

            // Parse all diff code blocks in the examples and validate they don't have unbalanced tokens
            let codeBlocks: [MarkdownCodeBlock]
            do {
                codeBlocks = try parseCodeBlocks(fromMarkdown: examples, language: "diff")
            } catch {
                XCTFail("Error parsing ```diff code blocks in \(rule.name) rule examples: \(error)")
                continue
            }

            // Collect all invalid lines for this rule
            var invalidLines: [Int] = []

            // Validate diff formatting for each code block
            for codeBlock in codeBlocks {
                let lines = codeBlock.text.components(separatedBy: .newlines)
                for (lineIndex, line) in lines.enumerated() {
                    guard !line.isEmpty else { continue }

                    // Check diff formatting: first column must be space/+/-, second column must be space
                    let firstChar = line.first!
                    let secondChar = line.count >= 2 ? line[line.index(line.startIndex, offsetBy: 1)] : " "

                    let isValidDiffLine = (firstChar == " " || firstChar == "+" || firstChar == "-") &&
                        (line.count < 2 || secondChar == " ")

                    if !isValidDiffLine {
                        invalidLines.append(lineIndex + 1)
                    }
                }
            }

            XCTAssert(
                invalidLines.isEmpty,
                """
                \(rule.name) rule has invalid example diff formatting. \ 
                Each line must start with space/+/- followed by a space.
                """
            )
        }
    }

    // MARK: options

    func testRulesOptions() throws {
        var allOptions = Set(formattingArguments).subtracting(deprecatedArguments)
        var allSharedOptions = allOptions
        var optionsByProperty = [String: OptionDescriptor]()
        for descriptor in Descriptors.formatting.reversed() {
            optionsByProperty[descriptor.propertyName] = descriptor
        }
        for rulesFile in allRuleFiles {
            let rulesSource = try String(contentsOf: rulesFile, encoding: .utf8)
            let tokens = tokenize(rulesSource)
            let formatter = Formatter(tokens)
            var rulesByOption = [String: String]()
            formatter.forEach(.identifier("FormatRule")) { i, _ in
                guard let nextToken = formatter.next(.nonSpaceOrComment, after: i),
                      [.startOfScope("("), .operator("=", .infix)].contains(nextToken),
                      case let .identifier(name)? = formatter.last(.identifier, before: i),
                      let scopeStart = formatter.index(of: .startOfScope("{"), after: i),
                      let rule = FormatRules.byName[name]
                else {
                    return
                }
                for option in rule.options where !rule.isDeprecated {
                    if let oldName = rulesByOption[option] {
                        XCTFail("\(option) set as (non-shared) option for both \(name) and \(oldName)")
                    }
                    rulesByOption[option] = name
                }
                let ruleOptions = rule.options + rule.sharedOptions
                allOptions.subtract(rule.options)
                allSharedOptions.subtract(ruleOptions)
                var referencedOptions = [OptionDescriptor]()
                for index in scopeStart + 1 ..< formatter.tokens.count {
                    switch formatter.tokens[index] {
                    // Find all of the options called via `options.optionName`
                    case .identifier("options") where formatter.token(at: index + 1) == .operator(".", .infix):
                        if case let .identifier(property)? = formatter.token(at: index + 2),
                           let option = optionsByProperty[property]
                        {
                            referencedOptions.append(option)
                        }
                    // Special-case shared helpers that also access options on the formatter
                    case .identifier("spaceEquivalentToWidth"),
                         .identifier("spaceEquivalentToTokens"):
                        referencedOptions += [
                            Descriptors.indent, Descriptors.tabWidth, Descriptors.smartTabs,
                        ]
                    case .identifier("tokenLength"):
                        referencedOptions += [Descriptors.indent, Descriptors.tabWidth]
                    case .identifier("lineLength"):
                        referencedOptions += [
                            Descriptors.indent, Descriptors.tabWidth, Descriptors.assetLiteralWidth,
                        ]
                    case .identifier("isCommentedCode"):
                        referencedOptions.append(Descriptors.indent)
                    case .identifier("insertLinebreak"), .identifier("linebreakToken"):
                        referencedOptions.append(Descriptors.linebreak)
                    case .identifier("wrapCollectionsAndArguments"):
                        referencedOptions += [
                            Descriptors.wrapArguments, Descriptors.wrapParameters, Descriptors.wrapCollections,
                            Descriptors.closingParenPosition, Descriptors.callSiteClosingParenPosition,
                            Descriptors.linebreak, Descriptors.truncateBlankLines,
                            Descriptors.indent, Descriptors.tabWidth, Descriptors.smartTabs, Descriptors.maxWidth,
                            Descriptors.assetLiteralWidth, Descriptors.wrapReturnType, Descriptors.wrapEffects,
                            Descriptors.wrapConditions, Descriptors.wrapTypealiases, Descriptors.wrapTernaryOperators,
                            Descriptors.wrapStringInterpolation,
                        ]
                    case .identifier("wrapStatementBody"):
                        referencedOptions += [Descriptors.indent, Descriptors.linebreak]
                    case .identifier("indexWhereLineShouldWrapInLine"), .identifier("indexWhereLineShouldWrap"):
                        referencedOptions += [
                            Descriptors.indent, Descriptors.tabWidth, Descriptors.assetLiteralWidth,
                            Descriptors.noWrapOperators,
                        ]
                    case .identifier("removeSelf"):
                        referencedOptions += [
                            Descriptors.selfRequired,
                        ]
                    case .identifier("typeLengthExceedsOrganizationThreshold"):
                        referencedOptions += [
                            Descriptors.organizeClassThreshold,
                            Descriptors.organizeStructThreshold,
                            Descriptors.organizeEnumThreshold,
                            Descriptors.organizeExtensionThreshold,
                        ]
                    default:
                        continue
                    }
                }

                for option in referencedOptions {
                    XCTAssert(ruleOptions.contains(option.argumentName) || option.isDeprecated,
                              "\(option.argumentName) not listed in \(name) rule")
                }
                for argName in ruleOptions {
                    XCTAssert(referencedOptions.contains { $0.argumentName == argName },
                              "\(argName) not used in \(name) rule")
                }
            }
        }

        XCTAssert(allSharedOptions.isEmpty, "Options \(allSharedOptions.joined(separator: ",")) not shared by any rule)")
        XCTAssert(allOptions.isEmpty, "Options \(allSharedOptions.joined(separator: ",")) not owned by any rule)")
    }

    func testAllOptionsInRulesFile() {
        let arguments = Set(formattingArguments).subtracting(deprecatedArguments)
        for argument in arguments {
            XCTAssertTrue(rulesFile.contains("`--\(argument)`") || rulesFile.contains("`--\(argument) "), argument)
        }
    }

    func testNoInvalidOptionsInRulesFile() {
        let arguments = Set(commandLineArguments)
        var range = rulesFile.startIndex ..< rulesFile.endIndex
        while let match = rulesFile.range(of: "`--[a-zA-Z-]+[` ]", options: .regularExpression, range: range, locale: nil) {
            let lower = rulesFile.index(match.lowerBound, offsetBy: 3)
            let upper = rulesFile.index(before: match.upperBound)
            let argument = String(rulesFile[lower ..< upper])
            XCTAssertTrue(arguments.contains(argument), argument)
            range = match.upperBound ..< range.upperBound
        }
    }

    func testArgumentNamesAreLowercase() {
        let arguments = Set(commandLineArguments).subtracting(deprecatedArguments)
        for argument in arguments {
            XCTAssertEqual(argument, argument.lowercased())
        }
    }

    // MARK: keywords

    func testContextualKeywordsReferencedCorrectly() throws {
        let filesToVerify = allRuleFiles + [
            projectDirectory.appendingPathComponent("Sources/ParsingHelpers.swift"),
            projectDirectory.appendingPathComponent("Sources/FormattingHelpers.swift"),
        ]

        for sourceFile in filesToVerify {
            let fileSource = try String(contentsOf: sourceFile, encoding: .utf8)
            let tokens = tokenize(fileSource)
            let formatter = Formatter(tokens)
            let keywords = swiftKeywords + ["actor", "macro"]
            formatter.forEach(.identifier("keyword")) { i, _ in
                guard formatter.token(at: i - 1) == .operator(".", .prefix),
                      let parenIndex = formatter.index(of: .nonSpaceOrComment, after: i, if: {
                          $0 == .startOfScope("(")
                      }),
                      let endIndex = formatter.endOfScope(at: parenIndex),
                      let stringIndex = formatter.index(of: .nonSpaceOrComment, in: parenIndex + 1 ..< endIndex, if: {
                          $0.isStringDelimiter
                      }),
                      case let .stringBody(keyword) = formatter.next(
                          .nonSpaceOrCommentOrLinebreak,
                          in: stringIndex + 1 ..< endIndex
                      )
                else {
                    return
                }
                guard keywords.contains(keyword) || keyword.hasPrefix("#") || keyword.hasPrefix("@") else {
                    let line = formatter.originalLine(at: i)
                    XCTFail("'\(keyword)' referenced on line \(line) of '\(sourceFile)' is not a valid Swift keyword. "
                        + "Contextual keywords should be referenced with `.identifier(...)`")
                    return
                }
            }
        }
    }

    // MARK: releases

    func testLatestVersionInChangelog() throws {
        let changelog = try String(contentsOf: changeLogURL, encoding: .utf8)
        XCTAssertTrue(changelog.contains("[\(SwiftFormat.version)]"), "CHANGELOG.md does not mention latest release")
        XCTAssertTrue(changelog.contains("(https://github.com/nicklockwood/SwiftFormat/releases/tag/\(SwiftFormat.version))"),
                      "CHANGELOG.md does not include correct link for latest release")
    }

    func testLatestVersionInPodspec() throws {
        let podspec = try String(contentsOf: podspecURL, encoding: .utf8)
        XCTAssertTrue(podspec.contains("\"version\": \"\(SwiftFormat.version)\""), "Podspec version does not match latest release")
        XCTAssertTrue(podspec.contains("\"tag\": \"\(SwiftFormat.version)\""), "Podspec tag does not match latest release")
    }

    func testVersionConstantUpdated() {
        XCTAssertEqual(SwiftFormat.version, swiftFormatVersion)
    }

    func testChangelogDatesAreAscending() throws {
        var lastDate: Date?
        let dateParser = DateFormatter()
        dateParser.timeZone = TimeZone(identifier: "UTC")
        dateParser.locale = Locale(identifier: "en_GB")
        dateParser.dateFormat = " (yyyy-MM-dd)"
        for title in changelogTitles {
            let dateRange = try XCTUnwrap(title.range(of: " \\([^)]+\\)$", options: .regularExpression))
            let dateString = String(title[dateRange])
            let date = try XCTUnwrap(dateParser.date(from: dateString))
            if let lastDate, date > lastDate {
                XCTFail("\(title) has newer date than subsequent version (\(date) vs \(lastDate))")
                return
            }
            lastDate = date
        }
    }
}

/// The cached result from the first run of `generateRuleRegistryIfNecessary()`
private var cachedGenerateRuleRegistryResult: Result<Void, Error>?

extension _FormatRules {
    /// Generates `RuleRegistry.generated.swift` if it hasn't been generated yet for this test run.
    func generateRuleRegistryIfNecessary() throws {
        switch cachedGenerateRuleRegistryResult {
        case .success:
            break

        case let .failure(error):
            throw error

        case .none:
            do {
                try generateRuleRegistry()
                cachedGenerateRuleRegistryResult = .success(())
            } catch {
                cachedGenerateRuleRegistryResult = .failure(error)
                throw error
            }
        }
    }

    private func generateRuleRegistry() throws {
        let validatedRules = try validatedRuleNames()
        let ruleRegistryContent = generateRuleRegistryContent(for: validatedRules)
        let currentRuleRegistryContent = try String(contentsOf: ruleRegistryURL)

        if ruleRegistryContent != currentRuleRegistryContent {
            try ruleRegistryContent.write(to: ruleRegistryURL, atomically: true, encoding: .utf8)
            fatalError("Updated rule registry. You can now re-run the test case or test suite.")
        }
    }

    /// Finds all of the rules defines in `Sources/Rules` and validates that it matches the
    /// expected scheme, where each file defines exactly one `FormatRule` with the same name.
    private func validatedRuleNames() throws -> [String] {
        try allRuleFiles.map { ruleFile in
            let titleCaseRuleName = ruleFile.lastPathComponent.replacingOccurrences(of: ".swift", with: "")
            var camelCaseRuleName = titleCaseRuleName.first!.lowercased() + titleCaseRuleName.dropFirst()
            if titleCaseRuleName == "URLMacro" {
                camelCaseRuleName = "urlMacro"
            }
            try validateRuleImplementation(for: camelCaseRuleName, in: ruleFile)
            return camelCaseRuleName
        }
    }

    /// Generates the content of the `RuleRegistry.generated.swift` file
    private func generateRuleRegistryContent(for rules: [String]) -> String {
        var ruleRegistryContents = """
        //
        //  RuleRegistry.generated.swift
        //  SwiftFormat
        //
        //  Created by Cal Stephens on 7/27/24.
        //  Copyright © 2024 Nick Lockwood. All rights reserved.
        //

        /// All of the rules defined in the Rules directory.
        /// **Generated automatically when running tests. Do not modify.**
        let ruleRegistry: [String: FormatRule] = [\n
        """

        for rule in rules.sorted() {
            ruleRegistryContents.append("""
                "\(rule)": .\(rule),\n
            """)
        }

        ruleRegistryContents.append("""
        ]\n
        """)

        return ruleRegistryContents
    }

    /// Validates that the given file defines exactly one `FormatRule` with the expected name
    private func validateRuleImplementation(for expectedRuleName: String, in file: URL) throws {
        let fileContents = try String(contentsOf: file)
        let formatter = Formatter(tokenize(fileContents))

        // Find all rules defined in the file, like `let ruleName = FormatRule(` or `let ruleName: FormatRule = ...`.
        var definedRules: [String] = []
        formatter.forEach(.identifier("FormatRule")) { index, _ in
            guard let nextToken = formatter.next(.nonSpaceOrComment, after: index),
                  [.startOfScope("("), .operator("=", .infix)].contains(nextToken),
                  let declarationKeyword = formatter.indexOfLastSignificantKeyword(at: index),
                  let ruleNameIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: declarationKeyword)
            else { return }

            definedRules.append(formatter.tokens[ruleNameIndex].string)
        }

        if definedRules != [expectedRuleName] {
            fatalError("""
            \(file.lastPathComponent) must define a single FormatRule named \(expectedRuleName). Currently defines rules: \(definedRules).
            """)
        }
    }
}
