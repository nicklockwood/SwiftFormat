//
//  CodeOrganizationTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 8/3/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class CodeOrganizationTests: XCTestCase {
    func testRuleFileCodeOrganization() throws {
        for ruleFile in allRuleFiles {
            let fileName = ruleFile.lastPathComponent
            let titleCaseRuleName = fileName.replacingOccurrences(of: ".swift", with: "")
            var ruleName = titleCaseRuleName.first!.lowercased() + titleCaseRuleName.dropFirst()
            if titleCaseRuleName == "URLMacro" {
                ruleName = "urlMacro"
            }

            let content = try String(contentsOf: ruleFile)
            let formatter = Formatter(tokenize(content))
            let declarations = formatter.parseDeclarations()
            let extensions = declarations.filter { $0.keyword == "extension" }

            for extensionDecl in extensions {
                let extendedType = extensionDecl.name!
                let extensionVisibility = extensionDecl.visibility() ?? .internal

                if extendedType == "FormatRule" {
                    XCTAssertEqual(extensionVisibility, .public, """
                    Rule implementation in \(fileName) should be public.
                    """)

                    for bodyDeclaration in extensionDecl.body ?? [] {
                        XCTAssertEqual(bodyDeclaration.name, ruleName, """
                        A FormatRule named \(ruleName) should be the only declaration in \
                        the FormatRule extension in \(fileName).
                        """)

                        let declarationVisibility = bodyDeclaration.visibility() ?? extensionVisibility
                        XCTAssertEqual(declarationVisibility, .public, """
                        Rule implementation in \(fileName) should be public.
                        """)
                    }
                    continue
                }

                XCTAssertEqual(extensionVisibility, .internal, """
                \(extendedType) extension in \(fileName) should be internal, \
                to improve discoverability of helpers.
                """)

                for bodyDeclaration in extensionDecl.body ?? [] {
                    let declarationVisibility = bodyDeclaration.visibility() ?? extensionVisibility
                    XCTAssertEqual(declarationVisibility, .internal, """
                    \(bodyDeclaration.name!) helper in \(fileName) should be internal, \
                    to improve discoverability of helpers.
                    """)
                }
            }
        }
    }

    func testRuleFileHelpersNotUsedByOtherRules() throws {
        // Collect the name of all of the helpers defined in individual rule files
        var allRuleFileHelpers: [(name: String, fileName: String, funcArgLabels: [String?]?)] = []

        for ruleFile in allRuleFiles {
            let fileName = ruleFile.lastPathComponent
            let content = try String(contentsOf: ruleFile)
            let formatter = Formatter(tokenize(content))

            for declaration in formatter.parseDeclarations() {
                guard declaration.keyword == "extension", let extendedType = declaration.name, extendedType != "FormatRule" else {
                    continue
                }

                for bodyDeclaration in declaration.body ?? [] {
                    guard let helperName = bodyDeclaration.name else { continue }

                    var helperFuncArgLabels: [String?]? = nil
                    if bodyDeclaration.keyword == "func", let startOfScope = formatter.index(of: .startOfScope("("), after: bodyDeclaration.range.lowerBound) {
                        helperFuncArgLabels = formatter.parseFunctionDeclarationArguments(startOfScope: startOfScope).map(\.externalLabel)
                    }

                    allRuleFileHelpers.append((name: helperName, fileName: fileName, funcArgLabels: helperFuncArgLabels))
                }
            }
        }

        // Verify that none of the helpers defined in rule files are used in other files
        let ruleFileHelperNames = Set(allRuleFileHelpers.map(\.name))

        for file in allSourceFiles {
            let fileName = file.lastPathComponent
            let content = try String(contentsOf: file)
            let formatter = Formatter(tokenize(content))

            formatter.forEach(.identifier) { index, identifierToken in
                let identifier = identifierToken.string

                guard ruleFileHelperNames.contains(identifier) else { return }

                // If this is a function call, parse the labels to disambiguate
                // between methods with the same base name
                var functionCallArguments: [String?]?
                if let functionCallStartOfScope = formatter.index(of: .startOfScope("("), after: index) {
                    functionCallArguments = formatter.parseFunctionCallArguments(startOfScope: functionCallStartOfScope).map(\.label)
                }

                guard let matchingHelper = allRuleFileHelpers.first(where: { helper in
                    helper.name == identifier
                        && helper.funcArgLabels == functionCallArguments
                }), matchingHelper.fileName != fileName
                else { return }

                let fullHelperName: String
                if let argumentLabels = matchingHelper.funcArgLabels {
                    let argumentLabelStrings = argumentLabels.map { label -> String in
                        if let label {
                            return label + ":"
                        } else {
                            return "_:"
                        }
                    }

                    fullHelperName = matchingHelper.name + "(" + argumentLabelStrings.joined() + ")"
                } else {
                    fullHelperName = matchingHelper.name
                }

                XCTFail("""
                \(fullHelperName) helper defined in \(matchingHelper.fileName) is also used in \(fileName). \
                Shared helpers should be defined in a shared file like FormattingHelpers.swift,
                ParsingHelpers.swift, or DeclarationHelpers.swift.
                """)
            }
        }
    }

    func testRuleTestFilesHaveMatchingRule() {
        let allRuleNames = Set(allRuleFiles.map { ruleFile -> String in
            let fileName = ruleFile.lastPathComponent
            let titleCaseRuleName = fileName.replacingOccurrences(of: ".swift", with: "")
            var ruleName = titleCaseRuleName.first!.lowercased() + titleCaseRuleName.dropFirst()
            if titleCaseRuleName == "URLMacro" {
                ruleName = "urlMacro"
            }
            return ruleName
        })

        for testFile in allRuleTestFiles {
            let testFileName = testFile.lastPathComponent
            let expectedTestClassName = testFileName.replacingOccurrences(of: ".swift", with: "")
            let titleCaseRuleName = expectedTestClassName.hasSuffix("Tests") ? String(expectedTestClassName.dropLast(5)) : expectedTestClassName
            var ruleName = titleCaseRuleName.first!.lowercased() + titleCaseRuleName.dropFirst()
            if titleCaseRuleName == "URLMacro" {
                ruleName = "urlMacro"
            }

            XCTAssert(allRuleNames.contains(ruleName), """
            \(testFileName) has no matching rule named \(ruleName).
            """)
        }
    }

    func testAllTestClassesMatchFileName() throws {
        for testFile in allTestFiles {
            let testFileName = testFile.lastPathComponent
            let content = try String(contentsOf: testFile)
            let formatter = Formatter(tokenize(content))
            let declarations = formatter.parseDeclarations()

            guard let testClass = declarations.first(where: { declaration in
                let rangeBeforeKeyword = declaration.range.lowerBound ..< declaration.keywordIndex
                return declaration.keyword == "class"
                    && formatter.tokens[rangeBeforeKeyword].contains(.identifier("XCTestCase"))
            }) else { continue }

            let expectedTestClassName = testFileName.replacingOccurrences(of: ".swift", with: "")

            XCTAssertEqual(testClass.name!, expectedTestClassName, """
            class \(testClass.name!) and file \(testFileName) should have same name.
            """)
        }
    }

    func testTestCasesUseMultiLineStrings() throws {
        for ruleTestFile in allRuleTestFiles {
            let content = try String(contentsOf: ruleTestFile)
            let formatter = Formatter(tokenize(content))
            var hasChanges = false

            formatter.forEach(.keyword) { index, keyword in
                guard ["let", "var"].contains(keyword.string),
                      let propertyDeclaration = formatter.parsePropertyDeclaration(atIntroducerIndex: index),
                      let valueRange = propertyDeclaration.value?.expressionRange,
                      formatter.tokens[valueRange.lowerBound] == .startOfScope("\""),
                      let endOfString = formatter.endOfScope(at: valueRange.lowerBound)
                else { return }

                let startOfString = valueRange.lowerBound
                let stringBodyRange = (startOfString + 1) ..< endOfString

                let stringContent = formatter.tokens[stringBodyRange].map(\.string).joined()
                let currentIndent = formatter.currentIndentForLine(at: startOfString)
                let convertedContent = stringContent.replacingOccurrences(of: "\\n", with: "\n\(currentIndent)")

                let newTokens: [Token] = [
                    .startOfScope("\"\"\""),
                    .linebreak("\n", 0),
                    .space(currentIndent),
                    .stringBody(convertedContent),
                    .linebreak("\n", 0),
                    .space(currentIndent),
                    .endOfScope("\"\"\""),
                ]

                formatter.replaceTokens(in: startOfString ... endOfString, with: newTokens)
                hasChanges = true
            }

            if hasChanges {
                try formatter.tokens.string.write(to: ruleTestFile, atomically: true, encoding: .utf8)
                XCTFail("Updated test cases in \(ruleTestFile.lastPathComponent) to use multi-line strings.")
            }
        }
    }
}
