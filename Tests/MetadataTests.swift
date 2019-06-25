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

private let rulesURL =
    projectDirectory.appendingPathComponent("Rules.md")

private let rulesFile =
    try! String(contentsOf: rulesURL, encoding: .utf8)

class MetadataTests: XCTestCase {
    // MARK: generate Rules.md

    func testGenerateRulesDocumentation() throws {
        var result = "# Rules\n"
        for rule in FormatRules.all {
            result += "\n* [\(rule.name!)](#\(rule.name!))"
        }
        result += "\n\n----------"
        for rule in FormatRules.all {
            result += "\n\n## \(rule.name!)\n\n\(rule.help)"
            if !rule.options.isEmpty {
                result += "\n\nOption | Description\n--- | ---"
                for option in rule.options {
                    let help = FormatOptions.Descriptor.byName[option]!.help
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
        try result.write(to: rulesURL, atomically: true, encoding: .utf8)
    }

    // MARK: rules

    func testAllRulesInRulesFile() {
        for ruleName in FormatRules.byName.keys {
            XCTAssertTrue(rulesFile.contains("## \(ruleName)"), "Rules.md does not contain \(ruleName) rule")
        }
    }

    func testNoInvalidRulesInRulesFile() {
        let ruleNames = Set(FormatRules.byName.keys)
        var range = rulesFile.startIndex ..< rulesFile.endIndex
        while let match = rulesFile.range(of: "\\*[a-zA-Z]+\\* - ", options: .regularExpression, range: range, locale: nil) {
            let lower = rulesFile.index(after: match.lowerBound)
            let upper = rulesFile.index(match.upperBound, offsetBy: -4)
            let ruleName: String = String(rulesFile[lower ..< upper])
            XCTAssertTrue(ruleNames.contains(ruleName), ruleName)
            range = match.upperBound ..< range.upperBound
        }
    }

    func testRuleHelpLinesEndInPeriod() {
        for rule in FormatRules.all {
            XCTAssert(rule.help.hasSuffix(".") || rule.help.hasSuffix(".)"),
                      "\(rule.name!) rule help does not end in a period")
        }
    }

    // MARK: options

    func testRulesOptions() throws {
        var optionsByProperty = [String: String]()
        for descriptor in FormatOptions.Descriptor.formatting where !descriptor.isDeprecated {
            optionsByProperty[descriptor.propertyName] = descriptor.argumentName
        }
        let rulesFile = projectDirectory.appendingPathComponent("Sources/Rules.swift")
        let rulesSource = try String(contentsOf: rulesFile, encoding: .utf8)
        let tokens = tokenize(rulesSource)
        let formatter = Formatter(tokens)
        var referencedOptions = [String]()
        var rulesByOption = [String: String]()
        formatter.forEach(.identifier("FormatRule")) { i, _ in
            guard formatter.next(.nonSpaceOrLinebreak, after: i) == .startOfScope("("),
                case let .identifier(name)? = formatter.last(.identifier, before: i),
                let scopeStart = formatter.index(of: .startOfScope("{"), after: i),
                let scopeEnd = formatter.index(of: .endOfScope("}"), after: scopeStart),
                let rule = FormatRules.byName[name] else {
                return
            }
            for option in rule.options {
                if let oldName = rulesByOption[option] {
                    XCTFail("\(option) set as (non-shared) option for both \(name) and \(oldName)")
                }
                rulesByOption[option] = name
            }
            let allOptions = rule.options + rule.sharedOptions
            for index in scopeStart + 1 ..< scopeEnd {
                switch formatter.tokens[index].token {
                case let .identifier(name) where [
                    "spaceEquivalentToWidth",
                    "spaceEquivalentToTokens",
                    "tokenLength",
                    "lineLength",
                ].contains(name) &&
                    formatter.token(at: index - 1) == .operator(".", .infix) &&
                    formatter.token(at: index - 2) == .identifier("formatter"):
                    XCTAssert(allOptions.contains("indent"), "indent not listed in \(name) rule")
                    XCTAssert(allOptions.contains("tabwidth"), "indent not listed in \(name) rule")
                    referencedOptions += ["indent", "tabwidth"]
                case .identifier("options") where
                    formatter.token(at: index - 1) == .operator(".", .infix) &&
                    formatter.token(at: index - 2) == .identifier("formatter") &&
                    formatter.token(at: index + 1) == .operator(".", .infix):
                    if case let .identifier(property)? = formatter.token(at: index + 2),
                        let option = optionsByProperty[property] {
                        XCTAssert(allOptions.contains(option), "\(option) not listed in \(name) rule")
                        referencedOptions.append(option)
                    }
                default:
                    continue
                }
            }
            for option in allOptions {
                XCTAssert(referencedOptions.contains(option), "\(option) not used in \(name) rule")
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
        let arguments = Set(commandLineArguments).subtracting(deprecatedArguments)
        var range = rulesFile.startIndex ..< rulesFile.endIndex
        while let match = rulesFile.range(of: "`--[a-zA-Z]+[` ]", options: .regularExpression, range: range, locale: nil) {
            let lower = rulesFile.index(match.lowerBound, offsetBy: 3)
            let upper = rulesFile.index(before: match.upperBound)
            let argument: String = String(rulesFile[lower ..< upper])
            XCTAssertTrue(arguments.contains(argument), argument)
            range = match.upperBound ..< range.upperBound
        }
    }

    // MARK: examples

    func testAllExamplesMatchRule() {
        for key in FormatRules.examplesByName.keys {
            XCTAssertNotNil(FormatRules.byName[key], "Examples includes entry for unknown rule 'key'")
        }
    }
}
