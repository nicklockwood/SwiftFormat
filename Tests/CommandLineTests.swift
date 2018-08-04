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

@testable import SwiftFormat
import XCTest

private var readme: String = {
    let directoryURL = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent()
    let readmeURL = directoryURL.appendingPathComponent("README.md")
    return try! String(contentsOf: readmeURL, encoding: .utf8)
}()

class CommandLineTests: XCTestCase {
    // MARK: arg parser

    func testParseSimpleArguments() {
        let input = "hello world"
        let output = ["", "hello", "world"]
        XCTAssertEqual(parseArguments(input), output)
    }

    func testParseEscapedSpace() {
        let input = "hello\\ world"
        let output = ["", "hello world"]
        XCTAssertEqual(parseArguments(input), output)
    }

    func testParseEscapedN() {
        let input = "hello\\nworld"
        let output = ["", "hellonworld"]
        XCTAssertEqual(parseArguments(input), output)
    }

    func testParseQuoteArguments() {
        let input = "\"hello world\""
        let output = ["", "hello world"]
        XCTAssertEqual(parseArguments(input), output)
    }

    func testParseEscapedQuote() {
        let input = "hello \\\"world\\\""
        let output = ["", "hello", "\"world\""]
        XCTAssertEqual(parseArguments(input), output)
    }

    func testParseEscapedQuoteInString() {
        let input = "\"hello \\\"world\\\"\""
        let output = ["", "hello \"world\""]
        XCTAssertEqual(parseArguments(input), output)
    }

    func testParseQuotedEscapedN() {
        let input = "\"hello\\nworld\""
        let output = ["", "hello\\nworld"]
        XCTAssertEqual(parseArguments(input), output)
    }

    // MARK: arg preprocessor

    func testPreprocessArguments() {
        let input = ["", "foo", "bar", "-o", "baz", "-i", "4", "-l", "cr", "-s", "inline"]
        let output = ["0": "", "1": "foo", "2": "bar", "output": "baz", "indent": "4", "linebreaks": "cr", "semicolons": "inline"]
        XCTAssertEqual(try preprocessArguments(input, [
            "output",
            "indent",
            "linebreaks",
            "semicolons",
        ]), output)
    }

    func testEmptyArgsAreRecognized() {
        let input = ["", "--help", "--version"]
        let output = ["0": "", "help": "", "version": ""]
        XCTAssertEqual(try preprocessArguments(input, [
            "help",
            "version",
        ]), output)
    }

    // MARK: format options to arguments

    func testCommandLineArgumentsHaveValidNames() {
        let arguments = commandLineArguments(for: .default)
        for key in arguments.keys {
            XCTAssertTrue(commandLineArguments.contains(key), "\(key) is not a valid argument name")
        }
    }

    func testCommandLineArgumentsAreCorrect() {
        let options = FormatOptions.default
        let output = ["allman": "false", "wraparguments": "preserve", "self": "remove", "header": "ignore", "fractiongrouping": "disabled", "binarygrouping": "4,8", "octalgrouping": "4,8", "patternlet": "hoist", "indentcase": "false", "trimwhitespace": "always", "decimalgrouping": "3,6", "exponentgrouping": "disabled", "commas": "always", "wrapcollections": "preserve", "semicolons": "inline", "indent": "4", "exponentcase": "lowercase", "operatorfunc": "spaced", "elseposition": "same-line", "empty": "void", "ranges": "spaced", "hexliteralcase": "uppercase", "linebreaks": "lf", "hexgrouping": "4,8", "comments": "indent", "ifdef": "indent", "stripunusedargs": "always"]
        XCTAssertEqual(commandLineArguments(for: options), output)
    }

    // MARK: format arguments to options

    func testFormattingArgumentsAreAllImplemented() throws {
        CLI.print = { _, _ in }
        for key in formattingArguments {
            guard let value = commandLineArguments(for: .default)[key] else {
                XCTAssert(deprecatedArguments.contains(key))
                continue
            }
            XCTAssert(!deprecatedArguments.contains(key), key)
            _ = try formatOptionsFor([key: value])
        }
    }

    func testEmptyFormatOptions() throws {
        XCTAssertNil(try formatOptionsFor([:]))
        XCTAssertNil(try formatOptionsFor(["--disable": "void"]))
    }

    // MARK: format options to arguments

    func testFileHeaderOptionToArguments() throws {
        let options = FormatOptions(fileHeader: "//  Hello World\n//  Goodbye World")
        let arguments = commandLineArguments(for: options, excludingDefaults: true)
        XCTAssertEqual(arguments["header"], "//  Hello World\\n//  Goodbye World")
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

    // MARK: input paths

    func testExpandPathWithRelativePath() {
        XCTAssertEqual(
            expandPath("relpath/to/file.swift", in: "/dir").path,
            "/dir/relpath/to/file.swift"
        )
    }

    func testExpandPathWithFullPath() {
        XCTAssertEqual(
            expandPath("/full/path/to/file.swift", in: "/dir").path,
            "/full/path/to/file.swift"
        )
    }

    func testExpandPathWithUserPath() {
        XCTAssertEqual(
            expandPath("~/file.swift", in: "/dir").path,
            NSString(string: "~/file.swift").expandingTildeInPath
        )
    }

    // MARK: help

    func testHelpLineLength() {
        CLI.print = { message, _ in
            message.components(separatedBy: "\n").forEach { line in
                XCTAssertLessThanOrEqual(line.count, 80, line)
            }
        }
        printHelp()
    }

    func testHelpOptionsImplemented() {
        CLI.print = { message, _ in
            if message.hasPrefix("--") {
                let name = String(message["--".endIndex ..< message.endIndex]).components(separatedBy: " ")[0]
                XCTAssertTrue(commandLineArguments.contains(name), name)
            }
        }
        printHelp()
    }

    func testHelpOptionsDocumented() {
        var arguments = Set(commandLineArguments)
        deprecatedArguments.forEach { arguments.remove($0) }
        CLI.print = { allHelpMessage, _ in
            allHelpMessage
                .components(separatedBy: "\n")
                .forEach { message in
                    if message.hasPrefix("--") {
                        let name = String(message["--".endIndex ..< message.endIndex]).components(separatedBy: " ")[0]
                        arguments.remove(name)
                    }
                }
        }
        printHelp()
        XCTAssert(arguments.isEmpty, "\(arguments.joined(separator: ","))")
    }

    // MARK: documentation

    func testAllRulesInReadme() {
        for ruleName in FormatRules.byName.keys {
            XCTAssertTrue(readme.contains("***\(ruleName)*** - "), ruleName)
        }
    }

    func testNoInvalidRulesInReadme() {
        let ruleNames = Set(FormatRules.byName.keys)
        var range = readme.startIndex ..< readme.endIndex
        while let match = readme.range(of: "\\*[a-zA-Z]+\\* - ", options: .regularExpression, range: range, locale: nil) {
            let lower = readme.index(after: match.lowerBound)
            let upper = readme.index(match.upperBound, offsetBy: -4)
            let ruleName: String = String(readme[lower ..< upper])
            XCTAssertTrue(ruleNames.contains(ruleName), ruleName)
            range = match.upperBound ..< range.upperBound
        }
    }

    func testAllOptionsInReadme() {
        var arguments = Set(formattingArguments)
        deprecatedArguments.forEach { arguments.remove($0) }
        for argument in arguments {
            XCTAssertTrue(readme.contains("`--\(argument)`"), argument)
        }
    }

    func testNoInvalidOptionsInReadme() {
        let arguments = Set(commandLineArguments)
        var range = readme.startIndex ..< readme.endIndex
        while let match = readme.range(of: "`--[a-zA-Z]+`", options: .regularExpression, range: range, locale: nil) {
            let lower = readme.index(match.lowerBound, offsetBy: 3)
            let upper = readme.index(before: match.upperBound)
            let argument: String = String(readme[lower ..< upper])
            XCTAssertTrue(arguments.contains(argument), argument)
            range = match.upperBound ..< range.upperBound
        }
    }

    // MARK: config file parsing

    func testParseArgumentsContainingBlankLines() {
        let config = """
        --allman true

        --rules braces,fileHeader
        """
        let data = Data(config.utf8)
        do {
            let args = try parseConfigFile(data)
            XCTAssertEqual(args.count, 2)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testParseArgumentsContainingValuelessKeys() throws {
        let config = """
        --allman true
        --help
        --version
        --rules braces
        """
        let data = Data(config.utf8)
        do {
            let args = try parseConfigFile(data)
            XCTAssertEqual(args.count, 4)
            XCTAssertEqual(args["allman"], "true")
            XCTAssertEqual(args["help"], "")
            XCTAssertEqual(args["version"], "")
            XCTAssertEqual(args["rules"], "braces")
        } catch {
            XCTFail("\(error)")
        }
    }

    func testParseArgumentsContainingAnonymousValues() throws {
        let config = """
        hello
        --allman true
        """
        let data = Data(config.utf8)
        XCTAssertThrowsError(try parseConfigFile(data)) { error in
            guard case let FormatError.options(message) = error else {
                XCTFail("\(error)")
                return
            }
            XCTAssert(message.contains("hello"))
        }
    }

    func testParseArgumentsContainingSpaces() throws {
        let config = "--rules braces, fileHeader, consecutiveSpaces"
        let data = Data(config.utf8)
        let args = try parseConfigFile(data)
        XCTAssertEqual(args.count, 1)
        XCTAssertEqual(args["rules"], "braces, fileHeader, consecutiveSpaces")
    }

    func testParseArgumentsContainingEscapedCharacters() throws {
        let config = "--header hello\\ world\\ngoodbye\\ world"
        let data = Data(config.utf8)
        let args = try parseConfigFile(data)
        XCTAssertEqual(args.count, 1)
        XCTAssertEqual(args["header"], "hello world\\ngoodbye world")
    }

    func testParseArgumentsContainingQuotedCharacters() throws {
        let config = """
        --header "hello world\\ngoodbye world"
        """
        let data = Data(config.utf8)
        let args = try parseConfigFile(data)
        XCTAssertEqual(args.count, 1)
        XCTAssertEqual(args["header"], "hello world\\ngoodbye world")
    }

    // MARK: config file serialization

    func testSerializeFileHeaderContainingSpace() throws {
        let options = FormatOptions(fileHeader: "// hello world")
        let config = serialize(rules: nil, options: options, excludingDefaults: true)
        XCTAssertEqual(config, "--header \"// hello world\"")
    }

    func testSerializeFileHeaderContainingEscapedSpace() throws {
        let options = FormatOptions(fileHeader: "// hello\\ world")
        let config = serialize(rules: nil, options: options, excludingDefaults: true)
        XCTAssertEqual(config, "--header \"// hello\\ world\"")
    }

    func testSerializeFileHeaderContainingLinebreak() throws {
        let options = FormatOptions(fileHeader: "//hello\nworld")
        let config = serialize(rules: nil, options: options, excludingDefaults: true)
        XCTAssertEqual(config, "--header //hello\\nworld")
    }

    func testSerializeFileHeaderContainingLinebreakAndSpaces() throws {
        let options = FormatOptions(fileHeader: "// hello\n// world")
        let config = serialize(rules: nil, options: options, excludingDefaults: true)
        XCTAssertEqual(config, "--header \"// hello\\n// world\"")
    }

    // MARK: config file merging

    func testMergeFormatOptionArguments() throws {
        let args = ["allman": "false", "commas": "always"]
        let config = ["allman": "true", "binarygrouping": "4,8"]
        let result = try mergeArguments(args, into: config)
        for (key, value) in result {
            // args take precedence over config
            XCTAssertEqual(value, args[key] ?? config[key])
        }
        for key in Set(args.keys).union(config.keys) {
            // all keys should be present in result
            XCTAssertNotNil(result[key])
        }
    }

    func testMergeRules() throws {
        let args = ["rules": "braces,fileHeader"]
        let config = ["rules": "consecutiveSpaces,braces"]
        let result = try mergeArguments(args, into: config)
        let rules = try parseRules(result["rules"]!)
        XCTAssertEqual(Set(rules), Set(["braces", "fileHeader"]))
    }

    func testMergeEmptyRules() throws {
        let args = ["rules": ""]
        let config = ["rules": "consecutiveSpaces,braces"]
        let result = try mergeArguments(args, into: config)
        let rules = try parseRules(result["rules"]!)
        XCTAssertEqual(Set(rules), Set(["consecutiveSpaces", "braces"]))
    }

    func testMergeEnableRules() throws {
        let args = ["enable": "braces,fileHeader"]
        let config = ["enable": "consecutiveSpaces,braces"]
        let result = try mergeArguments(args, into: config)
        let enabled = try parseRules(result["enable"]!)
        XCTAssertEqual(Set(enabled), Set(["braces", "consecutiveSpaces", "fileHeader"]))
    }

    func testMergeDisableRules() throws {
        let args = ["disable": "braces,fileHeader"]
        let config = ["disable": "consecutiveSpaces,braces"]
        let result = try mergeArguments(args, into: config)
        let disabled = try parseRules(result["disable"]!)
        XCTAssertEqual(Set(disabled), Set(["braces", "consecutiveSpaces", "fileHeader"]))
    }

    func testRulesArgumentOverridesAllConfigRules() throws {
        let args = ["rules": "braces,fileHeader"]
        let config = ["rules": "consecutiveSpaces", "disable": "braces", "enable": "redundantSelf"]
        let result = try mergeArguments(args, into: config)
        let disabled = try parseRules(result["rules"]!)
        XCTAssertEqual(Set(disabled), Set(["braces", "fileHeader"]))
        XCTAssertNil(result["enabled"])
        XCTAssertNil(result["disabled"])
    }

    func testEnabledArgumentOverridesConfigRules() throws {
        let args = ["enable": "braces"]
        let config = ["rules": "fileHeader", "disable": "consecutiveSpaces,braces"]
        let result = try mergeArguments(args, into: config)
        let rules = try parseRules(result["rules"]!)
        XCTAssertEqual(Set(rules), Set(["fileHeader"]))
        let enabled = try parseRules(result["enable"]!)
        XCTAssertEqual(Set(enabled), Set(["braces"]))
        let disabled = try parseRules(result["disable"]!)
        XCTAssertEqual(Set(disabled), Set(["consecutiveSpaces"]))
    }

    func testDisableArgumentOverridesConfigRules() throws {
        let args = ["disable": "braces"]
        let config = ["rules": "braces,fileHeader", "enable": "consecutiveSpaces,braces"]
        let result = try mergeArguments(args, into: config)
        let rules = try parseRules(result["rules"]!)
        XCTAssertEqual(Set(rules), Set(["fileHeader"]))
        let enabled = try parseRules(result["enable"]!)
        XCTAssertEqual(Set(enabled), Set(["consecutiveSpaces"]))
        let disabled = try parseRules(result["disable"]!)
        XCTAssertEqual(Set(disabled), Set(["braces"]))
    }
}
