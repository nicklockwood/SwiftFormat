//
//  ArgumentsTests.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 07/08/2018.
//  Copyright © 2018 Nick Lockwood.
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

class ArgumentsTests: XCTestCase {
    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS)
            let thisClass = type(of: self)
            let linuxCount = thisClass.__allTests.count
            let darwinCount = thisClass.defaultTestSuite.testCaseCount
            XCTAssertEqual(linuxCount, darwinCount, "run swift test --generate-linuxmain")
        #endif
    }

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

    func testCommentedLine() {
        let input = "#hello"
        let output = [""]
        XCTAssertEqual(parseArguments(input, ignoreComments: false), output)
    }

    func testCommentInLine() {
        let input = "hello#world"
        let output = ["", "hello"]
        XCTAssertEqual(parseArguments(input, ignoreComments: false), output)
    }

    func testCommentAfterSpace() {
        let input = "hello #world"
        let output = ["", "hello"]
        XCTAssertEqual(parseArguments(input, ignoreComments: false), output)
    }

    func testCommentBeforeSpace() {
        let input = "hello# world"
        let output = ["", "hello"]
        XCTAssertEqual(parseArguments(input, ignoreComments: false), output)
    }

    func testCommentContainingSpace() {
        let input = "hello #wide world"
        let output = ["", "hello"]
        XCTAssertEqual(parseArguments(input, ignoreComments: false), output)
    }

    func testEscapedComment() {
        let input = "hello \\#world"
        let output = ["", "hello", "#world"]
        XCTAssertEqual(parseArguments(input, ignoreComments: false), output)
    }

    func testQuotedComment() {
        let input = "hello \"#world\""
        let output = ["", "hello", "#world"]
        XCTAssertEqual(parseArguments(input, ignoreComments: false), output)
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
        for key in argumentsFor(.default).keys {
            XCTAssertTrue(optionsArguments.contains(key), "\(key) is not a valid argument name")
        }
    }

    func testCommandLineArgumentsAreCorrect() {
        let output = ["allman": "false", "wraparguments": "preserve", "stripunusedargs": "always", "self": "remove", "header": "ignore", "importgrouping": "alphabetized", "fractiongrouping": "disabled", "binarygrouping": "4,8", "octalgrouping": "4,8", "indentcase": "false", "trimwhitespace": "always", "decimalgrouping": "3,6", "exponentgrouping": "disabled", "patternlet": "hoist", "commas": "always", "wrapcollections": "preserve", "semicolons": "inline", "indent": "4", "exponentcase": "lowercase", "operatorfunc": "spaced", "symlinks": "ignore", "elseposition": "same-line", "empty": "void", "ranges": "spaced", "hexliteralcase": "uppercase", "linebreaks": "lf", "hexgrouping": "4,8", "comments": "indent", "ifdef": "indent", "closingparen": "balanced", "selfrequired": ""]
        XCTAssertEqual(argumentsFor(.default), output)
    }

    func testFormattingArgumentsAreAllImplemented() throws {
        CLI.print = { _, _ in }
        for key in formattingArguments {
            guard let value = argumentsFor(.default)[key] else {
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

    func testFileHeaderOptionToArguments() throws {
        let options = FormatOptions(fileHeader: "//  Hello World\n//  Goodbye World")
        let args = argumentsFor(Options(formatOptions: options), excludingDefaults: true)
        XCTAssertEqual(args["header"], "//  Hello World\\n//  Goodbye World")
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

    func testParseIgnoreFileHeader() throws {
        let config = "--header ignore"
        let data = Data(config.utf8)
        let args = try parseConfigFile(data)
        let options = try Options(args, in: "/")
        XCTAssertEqual(options.formatOptions?.fileHeader, .ignore)
    }

    func testParseUppercaseIgnoreFileHeader() throws {
        let config = "--header IGNORE"
        let data = Data(config.utf8)
        let args = try parseConfigFile(data)
        let options = try Options(args, in: "/")
        XCTAssertEqual(options.formatOptions?.fileHeader, .ignore)
    }

    // MARK: config file serialization

    // file header comment encoding

    func testSerializeFileHeaderContainingSpace() throws {
        let options = Options(formatOptions: FormatOptions(fileHeader: "// hello world"))
        let config = serialize(options: options, excludingDefaults: true)
        XCTAssertEqual(config, "--header \"// hello world\"")
    }

    func testSerializeFileHeaderContainingEscapedSpace() throws {
        let options = Options(formatOptions: FormatOptions(fileHeader: "// hello\\ world"))
        let config = serialize(options: options, excludingDefaults: true)
        XCTAssertEqual(config, "--header \"// hello\\ world\"")
    }

    func testSerializeFileHeaderContainingLinebreak() throws {
        let options = Options(formatOptions: FormatOptions(fileHeader: "//hello\nworld"))
        let config = serialize(options: options, excludingDefaults: true)
        XCTAssertEqual(config, "--header //hello\\nworld")
    }

    func testSerializeFileHeaderContainingLinebreakAndSpaces() throws {
        let options = Options(formatOptions: FormatOptions(fileHeader: "// hello\n// world"))
        let config = serialize(options: options, excludingDefaults: true)
        XCTAssertEqual(config, "--header \"// hello\\n// world\"")
    }

    // trailing separator

    func testSerializeOptionsDisabledDefaultRulesEnabledIsEmpty() throws {
        let rules = allRules.subtracting(FormatRules.disabledByDefault)
        let config: String = serialize(options: Options(formatOptions: nil, rules: rules))
        XCTAssertEqual(config, "")
    }

    func testSerializeOptionsDisabledAllRulesEnabledNoTerminatingSeparator() throws {
        let rules = allRules
        let config: String = serialize(options: Options(formatOptions: nil, rules: rules))
        XCTAssertFalse(config.contains("--disable"))
        XCTAssertNotEqual(config.last, "\n")
    }

    func testSerializeOptionsDisabledSomeRulesDisabledNoTerminatingSeparator() throws {
        let rules = Set(allRules.prefix(3)).subtracting(FormatRules.disabledByDefault)
        let config: String = serialize(options: Options(formatOptions: nil, rules: rules))
        XCTAssertTrue(config.contains("--disable"))
        XCTAssertFalse(config.contains("--enable"))
        XCTAssertNotEqual(config.last, "\n")
    }

    func testSerializeOptionsEnabledDefaultRulesEnabledNoTerminatingSeparator() throws {
        let rules = allRules.subtracting(FormatRules.disabledByDefault)
        let config: String = serialize(options: Options(formatOptions: .default, rules: rules))
        XCTAssertNotEqual(config, "")
        XCTAssertFalse(config.contains("--disable"))
        XCTAssertFalse(config.contains("--enable"))
        XCTAssertNotEqual(config.last, "\n")
    }

    func testSerializeOptionsEnabledAllRulesEnabledNoTerminatingSeparator() throws {
        let rules = allRules
        let config: String = serialize(options: Options(formatOptions: .default, rules: rules))
        XCTAssertFalse(config.contains("--disable"))
        XCTAssertNotEqual(config.last, "\n")
    }

    func testSerializeOptionsEnabledSomeRulesDisabledNoTerminatingSeparator() throws {
        let rules = Set(allRules.prefix(3)).subtracting(FormatRules.disabledByDefault)
        let config: String = serialize(options: Options(formatOptions: .default, rules: rules))
        XCTAssertTrue(config.contains("--disable"))
        XCTAssertFalse(config.contains("--enable"))
        XCTAssertNotEqual(config.last, "\n")
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

    func testMergeExcludedURLs() throws {
        let args = ["exclude": "foo,bar"]
        let config = ["exclude": "bar,baz"]
        let result = try mergeArguments(args, into: config)
        XCTAssertEqual(result["exclude"], "bar,baz,foo")
    }

    func testMergeRules() throws {
        let args = ["rules": "braces,fileHeader"]
        let config = ["rules": "consecutiveSpaces,braces"]
        let result = try mergeArguments(args, into: config)
        let rules = try parseRules(result["rules"]!)
        XCTAssertEqual(rules, ["braces", "fileHeader"])
    }

    func testMergeEmptyRules() throws {
        let args = ["rules": ""]
        let config = ["rules": "consecutiveSpaces,braces"]
        let result = try mergeArguments(args, into: config)
        let rules = try parseRules(result["rules"]!)
        XCTAssertEqual(Set(rules), Set(["braces", "consecutiveSpaces"]))
    }

    func testMergeEnableRules() throws {
        let args = ["enable": "braces,fileHeader"]
        let config = ["enable": "consecutiveSpaces,braces"]
        let result = try mergeArguments(args, into: config)
        let enabled = try parseRules(result["enable"]!)
        XCTAssertEqual(enabled, ["braces", "consecutiveSpaces", "fileHeader"])
    }

    func testMergeDisableRules() throws {
        let args = ["disable": "braces,fileHeader"]
        let config = ["disable": "consecutiveSpaces,braces"]
        let result = try mergeArguments(args, into: config)
        let disabled = try parseRules(result["disable"]!)
        XCTAssertEqual(disabled, ["braces", "consecutiveSpaces", "fileHeader"])
    }

    func testRulesArgumentOverridesAllConfigRules() throws {
        let args = ["rules": "braces,fileHeader"]
        let config = ["rules": "consecutiveSpaces", "disable": "braces", "enable": "redundantSelf"]
        let result = try mergeArguments(args, into: config)
        let disabled = try parseRules(result["rules"]!)
        XCTAssertEqual(disabled, ["braces", "fileHeader"])
        XCTAssertNil(result["enabled"])
        XCTAssertNil(result["disabled"])
    }

    func testEnabledArgumentOverridesConfigRules() throws {
        let args = ["enable": "braces"]
        let config = ["rules": "fileHeader", "disable": "consecutiveSpaces,braces"]
        let result = try mergeArguments(args, into: config)
        let rules = try parseRules(result["rules"]!)
        XCTAssertEqual(rules, ["fileHeader"])
        let enabled = try parseRules(result["enable"]!)
        XCTAssertEqual(enabled, ["braces"])
        let disabled = try parseRules(result["disable"]!)
        XCTAssertEqual(disabled, ["consecutiveSpaces"])
    }

    func testDisableArgumentOverridesConfigRules() throws {
        let args = ["disable": "braces"]
        let config = ["rules": "braces,fileHeader", "enable": "consecutiveSpaces,braces"]
        let result = try mergeArguments(args, into: config)
        let rules = try parseRules(result["rules"]!)
        XCTAssertEqual(rules, ["fileHeader"])
        let enabled = try parseRules(result["enable"]!)
        XCTAssertEqual(enabled, ["consecutiveSpaces"])
        let disabled = try parseRules(result["disable"]!)
        XCTAssertEqual(disabled, ["braces"])
    }

    func testMergeSelfRequiredOptions() throws {
        let args = ["selfrequired": "log,assert"]
        let config = ["selfrequired": "expect"]
        let result = try mergeArguments(args, into: config)
        let selfRequired = parseCommaDelimitedList(result["selfrequired"]!)
        XCTAssertEqual(selfRequired, ["assert", "expect", "log"])
    }

    // MARK: Options parsing

    func testParseEmptyOptions() throws {
        let options = try Options([:], in: "")
        XCTAssertNil(options.formatOptions)
        XCTAssertNil(options.fileOptions)
        XCTAssertEqual(options.rules, allRules.subtracting(FormatRules.disabledByDefault))
    }

    func testParseExcludesURLsFileOption() throws {
        let options = try Options(["exclude": "foo bar, baz"], in: "/dir")
        let paths = options.fileOptions?.excludedGlobs.map { $0.description } ?? []
        XCTAssertEqual(paths, ["/dir/foo bar", "/dir/baz"])
    }
}
