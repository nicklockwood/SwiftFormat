//
//  MetadataTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 11/03/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

private let projectDirectory = URL(fileURLWithPath: #file)
    .deletingLastPathComponent().deletingLastPathComponent()

private let projectURL = projectDirectory
    .appendingPathComponent("SwiftFormat.xcodeproj")
    .appendingPathComponent("project.pbxproj")

private let changeLogURL =
    projectDirectory.appendingPathComponent("CHANGELOG.md")

private let podspecURL =
    projectDirectory.appendingPathComponent("SwiftFormat.podspec.json")

private let rulesURL =
    projectDirectory.appendingPathComponent("Rules.md")

private let rulesFile =
    try! String(contentsOf: rulesURL, encoding: .utf8)

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
        for rule in FormatRules.named(FormatRules.disabledByDefault) {
            guard !rule.isDeprecated else {
                continue
            }
            result += "\n* [\(rule.name)](#\(rule.name))"
        }

        let deprecatedRules = FormatRules.all.filter { $0.isDeprecated }
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
                    let help = Descriptors.byName[option]!.help
                    result += "\n`--\(option)` | \(help)"
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

    // MARK: options

    func testRulesOptions() throws {
        var optionsByProperty = [String: OptionDescriptor]()
        for descriptor in Descriptors.formatting.reversed() {
            optionsByProperty[descriptor.propertyName] = descriptor
        }
        let rulesFile = projectDirectory.appendingPathComponent("Sources/Rules.swift")
        let rulesSource = try String(contentsOf: rulesFile, encoding: .utf8)
        let tokens = tokenize(rulesSource)
        let formatter = Formatter(tokens)
        var rulesByOption = [String: String]()
        formatter.forEach(.identifier("FormatRule")) { i, _ in
            guard formatter.next(.nonSpaceOrLinebreak, after: i) == .startOfScope("("),
                  case let .identifier(name)? = formatter.last(.identifier, before: i),
                  let scopeStart = formatter.index(of: .startOfScope("{"), after: i),
                  let scopeEnd = formatter.index(of: .endOfScope("}"), after: scopeStart),
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
            let allOptions = rule.options + rule.sharedOptions
            var referencedOptions = [OptionDescriptor]()
            for index in scopeStart + 1 ..< scopeEnd {
                guard formatter.token(at: index - 1) == .operator(".", .infix),
                      formatter.token(at: index - 2) == .identifier("formatter")
                else {
                    continue
                }
                switch formatter.tokens[index] {
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
                        Descriptors.closingParenOnSameLine, Descriptors.linebreak, Descriptors.truncateBlankLines,
                        Descriptors.indent, Descriptors.tabWidth, Descriptors.smartTabs, Descriptors.maxWidth,
                        Descriptors.assetLiteralWidth, Descriptors.wrapReturnType, Descriptors.wrapEffects,
                        Descriptors.wrapConditions, Descriptors.wrapTypealiases, Descriptors.wrapTernaryOperators, Descriptors.conditionsWrap,
                    ]
                case .identifier("indexWhereLineShouldWrapInLine"), .identifier("indexWhereLineShouldWrap"):
                    referencedOptions += [
                        Descriptors.indent, Descriptors.tabWidth, Descriptors.assetLiteralWidth,
                        Descriptors.noWrapOperators,
                    ]
                case .identifier("modifierOrder"):
                    referencedOptions.append(Descriptors.modifierOrder)
                case .identifier("options") where formatter.token(at: index + 1) == .operator(".", .infix):
                    if case let .identifier(property)? = formatter.token(at: index + 2),
                       let option = optionsByProperty[property]
                    {
                        referencedOptions.append(option)
                    }
                case .identifier("organizeType"):
                    referencedOptions += [
                        Descriptors.categoryMarkComment,
                        Descriptors.markCategories,
                        Descriptors.beforeMarks,
                        Descriptors.lifecycleMethods,
                        Descriptors.organizeTypes,
                        Descriptors.organizeStructThreshold,
                        Descriptors.organizeClassThreshold,
                        Descriptors.organizeEnumThreshold,
                        Descriptors.organizeExtensionThreshold,
                        Descriptors.lineAfterMarks,
                    ]
                case .identifier("removeSelf"):
                    referencedOptions += [
                        Descriptors.selfRequired,
                    ]
                default:
                    continue
                }
            }

            for option in referencedOptions {
                XCTAssert(allOptions.contains(option.argumentName) || option.isDeprecated,
                          "\(option.argumentName) not listed in \(name) rule")
            }
            for argName in allOptions {
                XCTAssert(referencedOptions.contains { $0.argumentName == argName },
                          "\(argName) not used in \(name) rule")
            }
        }
        // TODO: check all options are used
        // TODO: check all shared options are set as non-shared for at least one rule
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
        while let match = rulesFile.range(of: "`--[a-zA-Z]+[` ]", options: .regularExpression, range: range, locale: nil) {
            let lower = rulesFile.index(match.lowerBound, offsetBy: 3)
            let upper = rulesFile.index(before: match.upperBound)
            let argument = String(rulesFile[lower ..< upper])
            XCTAssertTrue(arguments.contains(argument), argument)
            range = match.upperBound ..< range.upperBound
        }
    }

    func testArgumentNamesAreValidLength() {
        let arguments = Set(commandLineArguments).subtracting(deprecatedArguments)
        for argument in arguments {
            XCTAssert(argument.count <= Options.maxArgumentNameLength)
        }
    }

    // MARK: examples

    func testAllExamplesMatchRule() {
        for key in FormatRules.examplesByName.keys {
            XCTAssertNotNil(FormatRules.byName[key], "Examples includes entry for unknown rule '\(key)'")
        }
    }

    // MARK: order

    func testRuleOrderNamesAreValid() {
        for rule in FormatRules.all {
            for name in rule.orderAfter {
                XCTAssert(FormatRules.byName[name] != nil, "\(name) rule does not exist")
            }
        }
    }

    // MARK: releases

    func testLatestVersionInChangelog() {
        let changelog = try! String(contentsOf: changeLogURL, encoding: .utf8)
        XCTAssertTrue(changelog.contains("[\(SwiftFormat.version)]"), "CHANGELOG.md does not mention latest release")
        XCTAssertTrue(changelog.contains("(https://github.com/nicklockwood/SwiftFormat/releases/tag/\(SwiftFormat.version))"),
                      "CHANGELOG.md does not include correct link for latest release")
    }

    func testLatestVersionInPodspec() {
        let podspec = try! String(contentsOf: podspecURL, encoding: .utf8)
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
            if let lastDate = lastDate, date > lastDate {
                XCTFail("\(title) has newer date than subsequent version (\(date) vs \(lastDate))")
                return
            }
            lastDate = date
        }
    }
}
