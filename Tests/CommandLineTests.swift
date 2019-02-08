//
//  CommandLineTests.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 10/01/2017.
//  Copyright 2017 Nick Lockwood
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/SwiftFormat
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import XCTest
@testable import SwiftFormat

private let projectDirectory = URL(fileURLWithPath: #file)
    .deletingLastPathComponent().deletingLastPathComponent()

private let rulesFile: String = {
    let readmeURL = projectDirectory.appendingPathComponent("Rules.md")
    return try! String(contentsOf: readmeURL, encoding: .utf8)
}()

class CommandLineTests: XCTestCase {
    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS)
            let thisClass = type(of: self)
            let linuxCount = thisClass.__allTests.count
            let darwinCount = thisClass.defaultTestSuite.testCaseCount
            XCTAssertEqual(linuxCount, darwinCount, "run swift test --generate-linuxmain")
        #endif
    }

    // MARK: pipe

    func testPipe() {
        CLI.print = { message, _ in
            XCTAssertEqual(message, "func foo() {\n    bar()\n}\n")
        }
        var readCount = 0
        CLI.readLine = {
            readCount += 1
            switch readCount {
            case 1:
                return "func foo()\n"
            case 2:
                return "{\n"
            case 3:
                return "bar()\n"
            case 4:
                return "}"
            default:
                return nil
            }
        }
        _ = processArguments([""], in: "")
    }

    // MARK: help

    func testHelpLineLength() {
        CLI.print = { message, _ in
            message.components(separatedBy: "\n").forEach { line in
                XCTAssertLessThanOrEqual(line.count, 80, line)
            }
        }
        printHelp(as: .content)
        printOptions(as: .content)
        for rule in FormatRules.all {
            try! printRuleInfo(for: rule.name!, as: .content)
        }
    }

    func testHelpOptionsImplemented() {
        CLI.print = { message, _ in
            if message.hasPrefix("--") {
                let name = String(message["--".endIndex ..< message.endIndex]).components(separatedBy: " ")[0]
                XCTAssertTrue(commandLineArguments.contains(name), name)
            }
        }
        printHelp(as: .content)
    }

    func testHelpOptionsDocumented() {
        var arguments = Set(commandLineArguments).subtracting(deprecatedArguments)
        CLI.print = { allHelpMessage, _ in
            allHelpMessage
                .components(separatedBy: "\n")
                .forEach { message in
                    if message.hasPrefix("--") {
                        let name = String(message["--".endIndex ..< message.endIndex]).components(separatedBy: " ")[0]
                        XCTAssert(arguments.contains(name), name)
                        arguments.remove(name)
                    }
                }
        }
        printHelp(as: .content)
        printOptions(as: .content)
        XCTAssert(arguments.isEmpty, "\(arguments.joined(separator: ","))")
    }

    // MARK: documentation

    func testAllRulesInReadme() {
        for ruleName in FormatRules.byName.keys {
            XCTAssertTrue(rulesFile.contains("## \(ruleName)"), ruleName)
        }
    }

    func testNoInvalidRulesInReadme() {
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

    func testAllOptionsInReadme() {
        let arguments = Set(formattingArguments).subtracting(deprecatedArguments)
        for argument in arguments {
            XCTAssertTrue(rulesFile.contains("`--\(argument)`") || rulesFile.contains("`--\(argument) "), argument)
        }
    }

    func testNoInvalidOptionsInReadme() {
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

    // MARK: cache

    func testHashIsFasterThanFormatting() throws {
        let sourceFile = URL(fileURLWithPath: #file)
        let source = try String(contentsOf: sourceFile, encoding: .utf8)
        let hash = computeHash(source + ";")

        let hashTime = timeEvent { _ = computeHash(source) == hash }
        let formatTime = try timeEvent { _ = try format(source) }
        XCTAssertLessThan(hashTime, formatTime)
    }

    func testCacheHit() throws {
        let input = "let foo = bar"
        XCTAssertEqual(computeHash(input), computeHash(input))
    }

    func testCacheMiss() throws {
        let input = "let foo = bar"
        let output = "let foo = bar\n"
        XCTAssertNotEqual(computeHash(input), computeHash(output))
    }

    func testCachePotentialFalsePositive() throws {
        let input = "let foo = bar;"
        let output = "let foo = bar\n"
        XCTAssertNotEqual(computeHash(input), computeHash(output))
    }

    func testCachePotentialFalsePositive2() throws {
        let input = """
        import Foo
        import Bar

        """
        let output = """
        import Bar
        import Foo

        """
        XCTAssertNotEqual(computeHash(input), computeHash(output))
    }

    // MARK: end-to-end formatting

    func testFormatting() {
        CLI.print = { _, _ in }
        #if swift(>=4.1.5)
            let args = ". --dryrun"
        #else
            let args = ". --dryrun --disable redundantSelf" // redundantSelf crashes Xcode 9.4 in debug mode
        #endif

        XCTAssertEqual(CLI.run(in: projectDirectory.path, with: args), .ok)
    }

    // MARK: rules

    func testRulesNotMarkedAsDisabled() {
        CLI.print = { message, _ in
            XCTAssert(!message.contains("(disabled)") ||
                FormatRules.disabledByDefault.contains(where: { message.contains($0) }))
        }
        XCTAssertEqual(CLI.run(in: projectDirectory.path, with: "--rules"), .ok)
    }

    // MARK: quiet mode

    func testQuietModeNoOutput() {
        CLI.print = { message, _ in
            XCTFail(message)
        }
        XCTAssertEqual(CLI.run(in: projectDirectory.path, with: "--quiet --dryrun"), .ok)
    }

    func testQuietModeAllowsContent() {
        CLI.print = { message, type in
            XCTAssertEqual(type, .content, message)
        }
        XCTAssertEqual(CLI.run(in: projectDirectory.path, with: "--quiet --help"), .ok)
    }

    func testQuietModeAllowsErrors() {
        CLI.print = { message, type in
            XCTAssertEqual(type, .error, message)
        }
        XCTAssertEqual(CLI.run(in: projectDirectory.path, with: "foobar.swift --quiet"), .error)
    }

    // MARK: split input paths

    func testSplitInputPaths() {
        CLI.print = { message, type in
            XCTAssertEqual(type, .error, message)
        }
        XCTAssertEqual(CLI.run(in: projectDirectory.path, with: "Sources --dryrun Tests --rules indent"), .error)
    }
}
