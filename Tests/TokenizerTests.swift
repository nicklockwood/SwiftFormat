//
//  TokenizerTests.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 12/08/2016.
//  Copyright 2016 Nick Lockwood
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

import SwiftFormat
import XCTest

class TokenizerTests: XCTestCase {
    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS)
            let thisClass = type(of: self)
            let linuxCount = thisClass.__allTests.count
            let darwinCount = thisClass.defaultTestSuite.testCaseCount
            XCTAssertEqual(linuxCount, darwinCount, "run swift test --generate-linuxmain")
        #endif
    }

    // MARK: Invalid input

    func testInvalidToken() {
        let input = "let `foo = bar"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .error("`foo"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnclosedBraces() {
        let input = "func foo() {"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("foo"),
            .startOfScope("("),
            .endOfScope(")"),
            .space(" "),
            .startOfScope("{"),
            .error(""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnclosedMultilineComment() {
        let input = "/* comment"
        let output: [Token] = [
            .startOfScope("/*"),
            .space(" "),
            .commentBody("comment"),
            .error(""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnclosedString() {
        let input = "\"Hello World"
        let output: [Token] = [
            .startOfScope("\""),
            .stringBody("Hello World"),
            .error(""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnbalancedScopes() {
        let input = "array.map({ return $0 )"
        let output: [Token] = [
            .identifier("array"),
            .operator(".", .infix),
            .identifier("map"),
            .startOfScope("("),
            .startOfScope("{"),
            .space(" "),
            .keyword("return"),
            .space(" "),
            .identifier("$0"),
            .space(" "),
            .error(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: hashbang

    func testHashbangOnItsOwnInFile() {
        let input = "#!/usr/bin/swift"
        let output: [Token] = [
            .startOfScope("#!"),
            .commentBody("/usr/bin/swift"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testHashbangAtStartOfFile() {
        let input = "#!/usr/bin/swift \n"
        let output: [Token] = [
            .startOfScope("#!"),
            .commentBody("/usr/bin/swift"),
            .space(" "),
            .linebreak("\n"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testHashbangAfterFirstLine() {
        let input = "//Hello World\n#!/usr/bin/swift \n"
        let output: [Token] = [
            .startOfScope("//"),
            .commentBody("Hello World"),
            .linebreak("\n"),
            .error("#!/usr/bin/swift"),
            .space(" "),
            .linebreak("\n"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Unescaping

    func testUnescapeInteger() {
        let input = Token.number("1_000_000_000", .integer)
        let output = "1000000000"
        XCTAssertEqual(input.unescaped(), output)
    }

    func testUnescapeDecimal() {
        let input = Token.number("1_000.00_5", .decimal)
        let output = "1000.005"
        XCTAssertEqual(input.unescaped(), output)
    }

    func testUnescapeBinary() {
        let input = Token.number("0b010_1010_101", .binary)
        let output = "0101010101"
        XCTAssertEqual(input.unescaped(), output)
    }

    func testUnescapeHex() {
        let input = Token.number("0xFF_764Ep1_345", .hex)
        let output = "FF764Ep1345"
        XCTAssertEqual(input.unescaped(), output)
    }

    func testUnescapeIdentifier() {
        let input = Token.identifier("`for`")
        let output = "for"
        XCTAssertEqual(input.unescaped(), output)
    }

    func testUnescapeLinebreak() {
        let input = Token.stringBody("Hello\\nWorld")
        let output = "Hello\nWorld"
        XCTAssertEqual(input.unescaped(), output)
    }

    func testUnescapeQuotedString() {
        let input = Token.stringBody("\\\"Hello World\\\"")
        let output = "\"Hello World\""
        XCTAssertEqual(input.unescaped(), output)
    }

    func testUnescapeUnicodeLiterals() {
        let input = Token.stringBody("\\u{1F1FA}\\u{1F1F8}")
        let output = "\u{1F1FA}\u{1F1F8}"
        XCTAssertEqual(input.unescaped(), output)
    }

    // MARK: Space

    func testSpaces() {
        let input = "    "
        let output: [Token] = [
            .space("    "),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSpacesAndTabs() {
        let input = "  \t  \t"
        let output: [Token] = [
            .space("  \t  \t"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Strings

    func testEmptyString() {
        let input = "\"\""
        let output: [Token] = [
            .startOfScope("\""),
            .endOfScope("\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSimpleString() {
        let input = "\"foo\""
        let output: [Token] = [
            .startOfScope("\""),
            .stringBody("foo"),
            .endOfScope("\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testStringWithEscape() {
        let input = "\"hello\\tworld\""
        let output: [Token] = [
            .startOfScope("\""),
            .stringBody("hello\\tworld"),
            .endOfScope("\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testStringWithEscapedQuotes() {
        let input = "\"\\\"nice\\\" to meet you\""
        let output: [Token] = [
            .startOfScope("\""),
            .stringBody("\\\"nice\\\" to meet you"),
            .endOfScope("\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testStringWithEscapedLogic() {
        let input = "\"hello \\(name)\""
        let output: [Token] = [
            .startOfScope("\""),
            .stringBody("hello \\"),
            .startOfScope("("),
            .identifier("name"),
            .endOfScope(")"),
            .endOfScope("\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testStringWithEscapedBackslash() {
        let input = "\"\\\\\""
        let output: [Token] = [
            .startOfScope("\""),
            .stringBody("\\\\"),
            .endOfScope("\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Multiline strings

    func testSimpleMultilineString() {
        let input = "\"\"\"\n    hello\n    world\n    \"\"\""
        let output: [Token] = [
            .startOfScope("\"\"\""),
            .linebreak("\n"),
            .space("    "),
            .stringBody("hello"),
            .linebreak("\n"),
            .space("    "),
            .stringBody("world"),
            .linebreak("\n"),
            .space("    "),
            .endOfScope("\"\"\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testIndentedSimpleMultilineString() {
        let input = "\"\"\"\n    hello\n    world\n\"\"\""
        let output: [Token] = [
            .startOfScope("\"\"\""),
            .linebreak("\n"),
            .stringBody("    hello"),
            .linebreak("\n"),
            .stringBody("    world"),
            .linebreak("\n"),
            .endOfScope("\"\"\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testEmptyMultilineString() {
        let input = "\"\"\"\n\"\"\""
        let output: [Token] = [
            .startOfScope("\"\"\""),
            .linebreak("\n"),
            .endOfScope("\"\"\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testMultilineStringWithEscapedLinebreak() {
        let input = "\"\"\"\n    hello \\\n    world\n\"\"\""
        let output: [Token] = [
            .startOfScope("\"\"\""),
            .linebreak("\n"),
            .stringBody("    hello \\"),
            .linebreak("\n"),
            .stringBody("    world"),
            .linebreak("\n"),
            .endOfScope("\"\"\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testMultilineStringStartingWithInterpolation() {
        let input = "    \"\"\"\n    \\(String(describing: 1))\n    \"\"\""
        let output: [Token] = [
            .space("    "),
            .startOfScope("\"\"\""),
            .linebreak("\n"),
            .space("    "),
            .stringBody("\\"),
            .startOfScope("("),
            .identifier("String"),
            .startOfScope("("),
            .identifier("describing"),
            .delimiter(":"),
            .space(" "),
            .number("1", .integer),
            .endOfScope(")"),
            .endOfScope(")"),
            .linebreak("\n"),
            .space("    "),
            .endOfScope("\"\"\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Single-line comments

    func testSingleLineComment() {
        let input = "//foo"
        let output: [Token] = [
            .startOfScope("//"),
            .commentBody("foo"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSingleLineCommentWithSpace() {
        let input = "// foo "
        let output: [Token] = [
            .startOfScope("//"),
            .space(" "),
            .commentBody("foo"),
            .space(" "),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSingleLineCommentWithLinebreak() {
        let input = "//foo\nbar"
        let output: [Token] = [
            .startOfScope("//"),
            .commentBody("foo"),
            .linebreak("\n"),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Multiline comments

    func testSingleLineMultilineComment() {
        let input = "/*foo*/"
        let output: [Token] = [
            .startOfScope("/*"),
            .commentBody("foo"),
            .endOfScope("*/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSingleLineMultilineCommentWithSpace() {
        let input = "/* foo */"
        let output: [Token] = [
            .startOfScope("/*"),
            .space(" "),
            .commentBody("foo"),
            .space(" "),
            .endOfScope("*/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testMultilineComment() {
        let input = "/*foo\nbar*/"
        let output: [Token] = [
            .startOfScope("/*"),
            .commentBody("foo"),
            .linebreak("\n"),
            .commentBody("bar"),
            .endOfScope("*/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testMultilineCommentWithSpace() {
        let input = "/*foo\n  bar*/"
        let output: [Token] = [
            .startOfScope("/*"),
            .commentBody("foo"),
            .linebreak("\n"),
            .space("  "),
            .commentBody("bar"),
            .endOfScope("*/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNestedComments() {
        let input = "/*foo/*bar*/baz*/"
        let output: [Token] = [
            .startOfScope("/*"),
            .commentBody("foo"),
            .startOfScope("/*"),
            .commentBody("bar"),
            .endOfScope("*/"),
            .commentBody("baz"),
            .endOfScope("*/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNestedCommentsWithSpace() {
        let input = "/* foo /* bar */ baz */"
        let output: [Token] = [
            .startOfScope("/*"),
            .space(" "),
            .commentBody("foo"),
            .space(" "),
            .startOfScope("/*"),
            .space(" "),
            .commentBody("bar"),
            .space(" "),
            .endOfScope("*/"),
            .space(" "),
            .commentBody("baz"),
            .space(" "),
            .endOfScope("*/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Numbers

    func testZero() {
        let input = "0"
        let output: [Token] = [.number("0", .integer)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSmallInteger() {
        let input = "5"
        let output: [Token] = [.number("5", .integer)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testLargeInteger() {
        let input = "12345678901234567890"
        let output: [Token] = [.number("12345678901234567890", .integer)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNegativeInteger() {
        let input = "-7"
        let output: [Token] = [
            .operator("-", .prefix),
            .number("7", .integer),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testInvalidInteger() {
        let input = "123abc"
        let output: [Token] = [
            .number("123", .integer),
            .error("abc"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSmallFloat() {
        let input = "0.2"
        let output: [Token] = [.number("0.2", .decimal)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testLargeFloat() {
        let input = "1234.567890"
        let output: [Token] = [.number("1234.567890", .decimal)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNegativeFloat() {
        let input = "-0.34"
        let output: [Token] = [
            .operator("-", .prefix),
            .number("0.34", .decimal),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testExponential() {
        let input = "1234e5"
        let output: [Token] = [.number("1234e5", .decimal)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testPositiveExponential() {
        let input = "0.123e+4"
        let output: [Token] = [.number("0.123e+4", .decimal)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNegativeExponential() {
        let input = "0.123e-4"
        let output: [Token] = [.number("0.123e-4", .decimal)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCapitalExponential() {
        let input = "0.123E-4"
        let output: [Token] = [.number("0.123E-4", .decimal)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testInvalidExponential() {
        let input = "123.e5"
        let output: [Token] = [
            .number("123", .integer),
            .operator(".", .infix),
            .identifier("e5"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testLeadingZeros() {
        let input = "0005"
        let output: [Token] = [.number("0005", .integer)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testBinary() {
        let input = "0b101010"
        let output: [Token] = [.number("0b101010", .binary)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testOctal() {
        let input = "0o52"
        let output: [Token] = [.number("0o52", .octal)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testHex() {
        let input = "0x2A"
        let output: [Token] = [.number("0x2A", .hex)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testHexadecimalPower() {
        let input = "0xC3p0"
        let output: [Token] = [.number("0xC3p0", .hex)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCapitalHexadecimalPower() {
        let input = "0xC3P0"
        let output: [Token] = [.number("0xC3P0", .hex)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNegativeHexadecimalPower() {
        let input = "0xC3p-5"
        let output: [Token] = [.number("0xC3p-5", .hex)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testFloatHexadecimalPower() {
        let input = "0xC.3p0"
        let output: [Token] = [.number("0xC.3p0", .hex)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testFloatNegativeHexadecimalPower() {
        let input = "0xC.3p-5"
        let output: [Token] = [.number("0xC.3p-5", .hex)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnderscoresInInteger() {
        let input = "1_23_4_"
        let output: [Token] = [.number("1_23_4_", .integer)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnderscoresInFloat() {
        let input = "0_.1_2_"
        let output: [Token] = [.number("0_.1_2_", .decimal)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnderscoresInExponential() {
        let input = "0.1_2_e-3"
        let output: [Token] = [.number("0.1_2_e-3", .decimal)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnderscoresInBinary() {
        let input = "0b0000_0000_0001"
        let output: [Token] = [.number("0b0000_0000_0001", .binary)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnderscoresInOctal() {
        let input = "0o123_456"
        let output: [Token] = [.number("0o123_456", .octal)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnderscoresInHex() {
        let input = "0xabc_def"
        let output: [Token] = [.number("0xabc_def", .hex)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnderscoresInHexadecimalPower() {
        let input = "0xabc_p5"
        let output: [Token] = [.number("0xabc_p5", .hex)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnderscoresInFloatHexadecimalPower() {
        let input = "0xa.bc_p5"
        let output: [Token] = [.number("0xa.bc_p5", .hex)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNoLeadingUnderscoreInInteger() {
        let input = "_12345"
        let output: [Token] = [.identifier("_12345")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNoLeadingUnderscoreInHex() {
        let input = "0x_12345"
        let output: [Token] = [.error("0x_12345")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testHexPropertyAccess() {
        let input = "0x123.ee"
        let output: [Token] = [
            .number("0x123", .hex),
            .operator(".", .infix),
            .identifier("ee"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testInvalidHexadecimal() {
        let input = "0x123.0"
        let output: [Token] = [
            .error("0x123.0"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testAnotherInvalidHexadecimal() {
        let input = "0x123.0p"
        let output: [Token] = [
            .error("0x123.0p"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testInvalidOctal() {
        let input = "0o1235678"
        let output: [Token] = [
            .number("0o123567", .octal),
            .error("8"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Identifiers & keywords

    func testFoo() {
        let input = "foo"
        let output: [Token] = [.identifier("foo")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testDollar0() {
        let input = "$0"
        let output: [Token] = [.identifier("$0")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testDollar() {
        // Note: support for this is deprecated in Swift 3
        let input = "$"
        let output: [Token] = [.identifier("$")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testFooDollar() {
        let input = "foo$"
        let output: [Token] = [.identifier("foo$")]
        XCTAssertEqual(tokenize(input), output)
    }

    func test_() {
        let input = "_"
        let output: [Token] = [.identifier("_")]
        XCTAssertEqual(tokenize(input), output)
    }

    func test_foo() {
        let input = "_foo"
        let output: [Token] = [.identifier("_foo")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testFoo_bar() {
        let input = "foo_bar"
        let output: [Token] = [.identifier("foo_bar")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testAtFoo() {
        let input = "@foo"
        let output: [Token] = [.keyword("@foo")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testHashFoo() {
        let input = "#foo"
        let output: [Token] = [.keyword("#foo")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnicode() {
        let input = "µsec"
        let output: [Token] = [.identifier("µsec")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testEmoji() {
        let input = "💩"
        let output: [Token] = [.identifier("💩")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testBacktickEscapedClass() {
        let input = "`class`"
        let output: [Token] = [.identifier("`class`")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testDotPrefixedKeyword() {
        let input = ".default"
        let output: [Token] = [
            .operator(".", .prefix),
            .identifier("default"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testKeywordsAsArgumentLabelNames() {
        let input = "foo(for: bar, if: baz)"
        let output: [Token] = [
            .identifier("foo"),
            .startOfScope("("),
            .identifier("for"),
            .delimiter(":"),
            .space(" "),
            .identifier("bar"),
            .delimiter(","),
            .space(" "),
            .identifier("if"),
            .delimiter(":"),
            .space(" "),
            .identifier("baz"),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testKeywordsAsArgumentLabelNames2() {
        let input = "foo(case: bar, default: baz)"
        let output: [Token] = [
            .identifier("foo"),
            .startOfScope("("),
            .identifier("case"),
            .delimiter(":"),
            .space(" "),
            .identifier("bar"),
            .delimiter(","),
            .space(" "),
            .identifier("default"),
            .delimiter(":"),
            .space(" "),
            .identifier("baz"),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testKeywordsAsArgumentLabelNames3() {
        let input = "foo(switch: bar, case: baz)"
        let output: [Token] = [
            .identifier("foo"),
            .startOfScope("("),
            .identifier("switch"),
            .delimiter(":"),
            .space(" "),
            .identifier("bar"),
            .delimiter(","),
            .space(" "),
            .identifier("case"),
            .delimiter(":"),
            .space(" "),
            .identifier("baz"),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testKeywordAsInternalArgumentLabelName() {
        let input = "func foo(all in: Array)"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("foo"),
            .startOfScope("("),
            .identifier("all"),
            .space(" "),
            .identifier("in"),
            .delimiter(":"),
            .space(" "),
            .identifier("Array"),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testKeywordAsExternalArgumentLabelName() {
        let input = "func foo(in array: Array)"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("foo"),
            .startOfScope("("),
            .identifier("in"),
            .space(" "),
            .identifier("array"),
            .delimiter(":"),
            .space(" "),
            .identifier("Array"),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testKeywordAsBothArgumentLabelNames() {
        let input = "func foo(for in: Array)"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("foo"),
            .startOfScope("("),
            .identifier("for"),
            .space(" "),
            .identifier("in"),
            .delimiter(":"),
            .space(" "),
            .identifier("Array"),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testKeywordAsSubscriptLabels() {
        let input = "foo[for: bar]"
        let output: [Token] = [
            .identifier("foo"),
            .startOfScope("["),
            .identifier("for"),
            .delimiter(":"),
            .space(" "),
            .identifier("bar"),
            .endOfScope("]"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNumberedTupleVariableMember() {
        let input = "foo.2"
        let output: [Token] = [
            .identifier("foo"),
            .operator(".", .infix),
            .identifier("2"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNumberedTupleExpressionMember() {
        let input = "(1,2).1"
        let output: [Token] = [
            .startOfScope("("),
            .number("1", .integer),
            .delimiter(","),
            .number("2", .integer),
            .endOfScope(")"),
            .operator(".", .infix),
            .identifier("1"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Operators

    func testBasicOperator() {
        let input = "+="
        let output: [Token] = [.operator("+=", .none)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testDivide() {
        let input = "a / b"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator("/", .infix),
            .space(" "),
            .identifier("b"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCustomOperator() {
        let input = "~="
        let output: [Token] = [.operator("~=", .none)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCustomOperator2() {
        let input = "a <> b"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator("<>", .infix),
            .space(" "),
            .identifier("b"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCustomOperator3() {
        let input = "a |> b"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator("|>", .infix),
            .space(" "),
            .identifier("b"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCustomOperator4() {
        let input = "a <<>> b"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator("<<>>", .infix),
            .space(" "),
            .identifier("b"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSequentialOperators() {
        let input = "a *= -b"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator("*=", .infix),
            .space(" "),
            .operator("-", .prefix),
            .identifier("b"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testDotPrefixedOperator() {
        let input = "..."
        let output: [Token] = [.operator("...", .none)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnicodeOperator() {
        let input = "≥"
        let output: [Token] = [.operator("≥", .none)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testOperatorFollowedByComment() {
        let input = "a+/* b */b"
        let output: [Token] = [
            .identifier("a"),
            .operator("+", .postfix),
            .startOfScope("/*"),
            .space(" "),
            .commentBody("b"),
            .space(" "),
            .endOfScope("*/"),
            .identifier("b"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testOperatorPrecededBySpaceFollowedByComment() {
        let input = "a +/* b */b"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator("+", .infix),
            .startOfScope("/*"),
            .space(" "),
            .commentBody("b"),
            .space(" "),
            .endOfScope("*/"),
            .identifier("b"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testOperatorPrecededByComment() {
        let input = "a/* a */-b"
        let output: [Token] = [
            .identifier("a"),
            .startOfScope("/*"),
            .space(" "),
            .commentBody("a"),
            .space(" "),
            .endOfScope("*/"),
            .operator("-", .prefix),
            .identifier("b"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testOperatorPrecededByCommentFollowedBySpace() {
        let input = "a/* a */- b"
        let output: [Token] = [
            .identifier("a"),
            .startOfScope("/*"),
            .space(" "),
            .commentBody("a"),
            .space(" "),
            .endOfScope("*/"),
            .operator("-", .infix),
            .space(" "),
            .identifier("b"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testOperatorMayContainDotIfStartsWithDot() {
        let input = ".*.."
        let output: [Token] = [.operator(".*..", .none)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testOperatorMayNotContainDotUnlessStartsWithDot() {
        let input = "*.."
        let output: [Token] = [
            .operator("*", .prefix), // TODO: should be postfix
            .operator("..", .none),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testOperatorStitchingDoesNotCreateIllegalToken() {
        let input = "a*..b"
        let output: [Token] = [
            .identifier("a"),
            .operator("*", .postfix),
            .operator("..", .infix),
            .identifier("b"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNullCoalescingOperator() {
        let input = "foo ?? bar"
        let output: [Token] = [
            .identifier("foo"),
            .space(" "),
            .operator("??", .infix),
            .space(" "),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testTernary() {
        let input = "a ? b() : c"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator("?", .infix),
            .space(" "),
            .identifier("b"),
            .startOfScope("("),
            .endOfScope(")"),
            .space(" "),
            .operator(":", .infix),
            .space(" "),
            .identifier("c"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testTernaryWithOddSpacing() {
        let input = "a ?b(): c"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator("?", .infix),
            .identifier("b"),
            .startOfScope("("),
            .endOfScope(")"),
            .operator(":", .infix),
            .space(" "),
            .identifier("c"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testInfixOperatorBeforeLinebreak() {
        let input = "foo +\nbar"
        let output: [Token] = [
            .identifier("foo"),
            .space(" "),
            .operator("+", .infix),
            .linebreak("\n"),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testInfixOperatorAfterLinebreak() {
        let input = "foo\n+ bar"
        let output: [Token] = [
            .identifier("foo"),
            .linebreak("\n"),
            .operator("+", .infix),
            .space(" "),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testInfixOperatorBeforeComment() {
        let input = "foo +/**/bar"
        let output: [Token] = [
            .identifier("foo"),
            .space(" "),
            .operator("+", .infix),
            .startOfScope("/*"),
            .endOfScope("*/"),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testInfixOperatorAfterComment() {
        let input = "foo/**/+ bar"
        let output: [Token] = [
            .identifier("foo"),
            .startOfScope("/*"),
            .endOfScope("*/"),
            .operator("+", .infix),
            .space(" "),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testPrefixMinusBeforeMember() {
        let input = "-.foo"
        let output: [Token] = [
            .operator("-", .prefix),
            .operator(".", .prefix),
            .identifier("foo"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testInfixMinusBeforeMember() {
        let input = "foo-.bar"
        let output: [Token] = [
            .identifier("foo"),
            .operator("-", .infix),
            .operator(".", .prefix),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNotOperator() {
        let input = "!foo"
        let output: [Token] = [
            .operator("!", .prefix),
            .identifier("foo"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNotOperatorAfterKeyword() {
        let input = "return !foo"
        let output: [Token] = [
            .keyword("return"),
            .space(" "),
            .operator("!", .prefix),
            .identifier("foo"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testStringDotMethod() {
        let input = "\"foo\".isEmpty"
        let output: [Token] = [
            .startOfScope("\""),
            .stringBody("foo"),
            .endOfScope("\""),
            .operator(".", .infix),
            .identifier("isEmpty"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testStringAssignment() {
        let input = "foo = \"foo\""
        let output: [Token] = [
            .identifier("foo"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .startOfScope("\""),
            .stringBody("foo"),
            .endOfScope("\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testInfixNotEqualsInParens() {
        let input = "(!=)"
        let output: [Token] = [
            .startOfScope("("),
            .operator("!=", .none),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: chevrons (might be operators or generics)

    func testLessThanGreaterThan() {
        let input = "a<b == a>c"
        let output: [Token] = [
            .identifier("a"),
            .operator("<", .infix),
            .identifier("b"),
            .space(" "),
            .operator("==", .infix),
            .space(" "),
            .identifier("a"),
            .operator(">", .infix),
            .identifier("c"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCustomChevronOperatorFollowedByParen() {
        let input = "foo <?> (bar)"
        let output: [Token] = [
            .identifier("foo"),
            .space(" "),
            .operator("<?>", .infix),
            .space(" "),
            .startOfScope("("),
            .identifier("bar"),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testRightShift() {
        let input = "a>>b"
        let output: [Token] = [
            .identifier("a"),
            .operator(">>", .infix),
            .identifier("b"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testLeftShift() {
        let input = "a<<b"
        let output: [Token] = [
            .identifier("a"),
            .operator("<<", .infix),
            .identifier("b"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testTripleShift() {
        let input = "a>>>b"
        let output: [Token] = [
            .identifier("a"),
            .operator(">>>", .infix),
            .identifier("b"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testRightShiftEquals() {
        let input = "a>>=b"
        let output: [Token] = [
            .identifier("a"),
            .operator(">>=", .infix),
            .identifier("b"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testLeftShiftInsideTernary() {
        let input = "foo ? bar<<24 : 0"
        let output: [Token] = [
            .identifier("foo"),
            .space(" "),
            .operator("?", .infix),
            .space(" "),
            .identifier("bar"),
            .operator("<<", .infix),
            .number("24", .integer),
            .space(" "),
            .operator(":", .infix),
            .space(" "),
            .number("0", .integer),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testBitshiftThatLooksLikeAGeneric() {
        let input = "a<b, b<c, d>>e"
        let output: [Token] = [
            .identifier("a"),
            .operator("<", .infix),
            .identifier("b"),
            .delimiter(","),
            .space(" "),
            .identifier("b"),
            .operator("<", .infix),
            .identifier("c"),
            .delimiter(","),
            .space(" "),
            .identifier("d"),
            .operator(">>", .infix),
            .identifier("e"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testBasicGeneric() {
        let input = "Foo<Bar, Baz>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Bar"),
            .delimiter(","),
            .space(" "),
            .identifier("Baz"),
            .endOfScope(">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNestedGenerics() {
        let input = "Foo<Bar<Baz>>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Bar"),
            .startOfScope("<"),
            .identifier("Baz"),
            .endOfScope(">"),
            .endOfScope(">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testFunctionThatLooksLikeGenericType() {
        let input = "y<CGRectGetMaxY(r)"
        let output: [Token] = [
            .identifier("y"),
            .operator("<", .infix),
            .identifier("CGRectGetMaxY"),
            .startOfScope("("),
            .identifier("r"),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericClassDeclaration() {
        let input = "class Foo<T,U> {}"
        let output: [Token] = [
            .keyword("class"),
            .space(" "),
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("T"),
            .delimiter(","),
            .identifier("U"),
            .endOfScope(">"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericSubclassDeclaration() {
        let input = "class Foo<T,U>: Bar"
        let output: [Token] = [
            .keyword("class"),
            .space(" "),
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("T"),
            .delimiter(","),
            .identifier("U"),
            .endOfScope(">"),
            .delimiter(":"),
            .space(" "),
            .identifier("Bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericFunctionDeclaration() {
        let input = "func foo<T>(bar:T)"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("foo"),
            .startOfScope("<"),
            .identifier("T"),
            .endOfScope(">"),
            .startOfScope("("),
            .identifier("bar"),
            .delimiter(":"),
            .identifier("T"),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericClassInit() {
        let input = "foo = Foo<Int,String>()"
        let output: [Token] = [
            .identifier("foo"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Int"),
            .delimiter(","),
            .identifier("String"),
            .endOfScope(">"),
            .startOfScope("("),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericFollowedByDot() {
        let input = "Foo<Bar>.baz()"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Bar"),
            .endOfScope(">"),
            .operator(".", .infix),
            .identifier("baz"),
            .startOfScope("("),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testConstantThatLooksLikeGenericType() {
        let input = "(y<Pi)"
        let output: [Token] = [
            .startOfScope("("),
            .identifier("y"),
            .operator("<", .infix),
            .identifier("Pi"),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testTupleOfBoolsThatLooksLikeGeneric() {
        let input = "(Foo<T,U>V)"
        let output: [Token] = [
            .startOfScope("("),
            .identifier("Foo"),
            .operator("<", .infix),
            .identifier("T"),
            .delimiter(","),
            .identifier("U"),
            .operator(">", .infix),
            .identifier("V"),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testTupleOfBoolsThatReallyLooksLikeGeneric() {
        let input = "(Foo<T,U>=V)"
        let output: [Token] = [
            .startOfScope("("),
            .identifier("Foo"),
            .operator("<", .infix),
            .identifier("T"),
            .delimiter(","),
            .identifier("U"),
            .operator(">=", .infix),
            .identifier("V"),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericDeclarationThatLooksLikeTwoExpressions() {
        let input = "let d: a < b, b > = c"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("d"),
            .delimiter(":"),
            .space(" "),
            .identifier("a"),
            .space(" "),
            .startOfScope("<"),
            .space(" "),
            .identifier("b"),
            .delimiter(","),
            .space(" "),
            .identifier("b"),
            .space(" "),
            .endOfScope(">"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("c"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericClassInitThatLooksLikeTuple() {
        let input = "(Foo<String,Int>(Bar))"
        let output: [Token] = [
            .startOfScope("("),
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("String"),
            .delimiter(","),
            .identifier("Int"),
            .endOfScope(">"),
            .startOfScope("("),
            .identifier("Bar"),
            .endOfScope(")"),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCustomChevronOperatorThatLooksLikeGeneric() {
        let input = "Foo<Bar,Baz>>>5"
        let output: [Token] = [
            .identifier("Foo"),
            .operator("<", .infix),
            .identifier("Bar"),
            .delimiter(","),
            .identifier("Baz"),
            .operator(">>>", .infix),
            .number("5", .integer),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericAsFunctionType() {
        let input = "Foo<Bar,Baz>->Void"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Bar"),
            .delimiter(","),
            .identifier("Baz"),
            .endOfScope(">"),
            .operator("->", .infix),
            .identifier("Void"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericContainingFunctionType() {
        let input = "Foo<(Bar)->Baz>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .startOfScope("("),
            .identifier("Bar"),
            .endOfScope(")"),
            .operator("->", .infix),
            .identifier("Baz"),
            .endOfScope(">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericContainingFunctionTypeWithMultipleArguments() {
        let input = "Foo<(Bar,Baz)->Quux>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .startOfScope("("),
            .identifier("Bar"),
            .delimiter(","),
            .identifier("Baz"),
            .endOfScope(")"),
            .operator("->", .infix),
            .identifier("Quux"),
            .endOfScope(">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericContainingMultipleFunctionTypes() {
        let input = "Foo<(Bar)->Void,(Baz)->Void>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .startOfScope("("),
            .identifier("Bar"),
            .endOfScope(")"),
            .operator("->", .infix),
            .identifier("Void"),
            .delimiter(","),
            .startOfScope("("),
            .identifier("Baz"),
            .endOfScope(")"),
            .operator("->", .infix),
            .identifier("Void"),
            .endOfScope(">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericContainingArrayType() {
        let input = "Foo<[Bar],Baz>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .startOfScope("["),
            .identifier("Bar"),
            .endOfScope("]"),
            .delimiter(","),
            .identifier("Baz"),
            .endOfScope(">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericContainingTupleType() {
        let input = "Foo<(Bar,Baz)>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .startOfScope("("),
            .identifier("Bar"),
            .delimiter(","),
            .identifier("Baz"),
            .endOfScope(")"),
            .endOfScope(">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericContainingArrayAndTupleType() {
        let input = "Foo<[Bar],(Baz)>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .startOfScope("["),
            .identifier("Bar"),
            .endOfScope("]"),
            .delimiter(","),
            .startOfScope("("),
            .identifier("Baz"),
            .endOfScope(")"),
            .endOfScope(">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericFollowedByIn() {
        let input = "Foo<Bar,Baz> in"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Bar"),
            .delimiter(","),
            .identifier("Baz"),
            .endOfScope(">"),
            .space(" "),
            .keyword("in"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testOptionalGenericType() {
        let input = "Foo<T?,U>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("T"),
            .operator("?", .postfix),
            .delimiter(","),
            .identifier("U"),
            .endOfScope(">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testTrailingOptionalGenericType() {
        let input = "Foo<T?>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("T"),
            .operator("?", .postfix),
            .endOfScope(">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNestedOptionalGenericType() {
        let input = "Foo<Bar<T?>>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Bar"),
            .startOfScope("<"),
            .identifier("T"),
            .operator("?", .postfix),
            .endOfScope(">"),
            .endOfScope(">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testDeeplyNestedGenericType() {
        let input = "Foo<Bar<Baz<Quux>>>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Bar"),
            .startOfScope("<"),
            .identifier("Baz"),
            .startOfScope("<"),
            .identifier("Quux"),
            .endOfScope(">"),
            .endOfScope(">"),
            .endOfScope(">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericFollowedByGreaterThan() {
        let input = "Foo<T>\na=b>c"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("T"),
            .endOfScope(">"),
            .linebreak("\n"),
            .identifier("a"),
            .operator("=", .infix),
            .identifier("b"),
            .operator(">", .infix),
            .identifier("c"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericFollowedByElipsis() {
        let input = "foo<T>(bar: Baz<T>...)"
        let output: [Token] = [
            .identifier("foo"),
            .startOfScope("<"),
            .identifier("T"),
            .endOfScope(">"),
            .startOfScope("("),
            .identifier("bar"),
            .delimiter(":"),
            .space(" "),
            .identifier("Baz"),
            .startOfScope("<"),
            .identifier("T"),
            .endOfScope(">"),
            .operator("...", .postfix),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericOperatorFunction() {
        let input = "func ==<T>()"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .operator("==", .none),
            .startOfScope("<"),
            .identifier("T"),
            .endOfScope(">"),
            .startOfScope("("),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericCustomOperatorFunction() {
        let input = "func ∘<T,U>()"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .operator("∘", .none),
            .startOfScope("<"),
            .identifier("T"),
            .delimiter(","),
            .identifier("U"),
            .endOfScope(">"),
            .startOfScope("("),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericTypeContainingAmpersand() {
        let input = "Foo<Bar: Baz & Quux>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Bar"),
            .delimiter(":"),
            .space(" "),
            .identifier("Baz"),
            .space(" "),
            .operator("&", .infix),
            .space(" "),
            .identifier("Quux"),
            .endOfScope(">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCustomOperatorStartingWithOpenChevron() {
        let input = "foo<--bar"
        let output: [Token] = [
            .identifier("foo"),
            .operator("<--", .infix),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCustomOperatorEndingWithCloseChevron() {
        let input = "foo-->bar"
        let output: [Token] = [
            .identifier("foo"),
            .operator("-->", .infix),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGreaterThanLessThanOperator() {
        let input = "foo><bar"
        let output: [Token] = [
            .identifier("foo"),
            .operator("><", .infix),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testLessThanGreaterThanOperator() {
        let input = "foo<>bar"
        let output: [Token] = [
            .identifier("foo"),
            .operator("<>", .infix),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericFollowedByAssign() {
        let input = "let foo: Bar<Baz> = 5"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("foo"),
            .delimiter(":"),
            .space(" "),
            .identifier("Bar"),
            .startOfScope("<"),
            .identifier("Baz"),
            .endOfScope(">"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .number("5", .integer),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericInFailableInit() {
        let input = "init?<T>()"
        let output: [Token] = [
            .keyword("init"),
            .operator("?", .postfix),
            .startOfScope("<"),
            .identifier("T"),
            .endOfScope(">"),
            .startOfScope("("),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testInfixEqualsOperatorWithSpace() {
        let input = "operator == {}"
        let output: [Token] = [
            .keyword("operator"),
            .space(" "),
            .operator("==", .none),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testInfixEqualsOperatorWithoutSpace() {
        let input = "operator =={}"
        let output: [Token] = [
            .keyword("operator"),
            .space(" "),
            .operator("==", .none),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testInfixQuestionMarkChevronOperatorWithSpace() {
        let input = "operator ?< {}"
        let output: [Token] = [
            .keyword("operator"),
            .space(" "),
            .operator("?<", .none),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testInfixQuestionMarkChevronOperatorWithoutSpace() {
        let input = "operator ?<{}"
        let output: [Token] = [
            .keyword("operator"),
            .space(" "),
            .operator("?<", .none),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testInfixEqualsDoubleChevronOperator() {
        let input = "infix operator =<<"
        let output: [Token] = [
            .identifier("infix"),
            .space(" "),
            .keyword("operator"),
            .space(" "),
            .operator("=<<", .none),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testInfixEqualsDoubleChevronGenericFunction() {
        let input = "func =<<<T>()"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .operator("=<<", .none),
            .startOfScope("<"),
            .identifier("T"),
            .endOfScope(">"),
            .startOfScope("("),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testHalfOpenRangeFollowedByComment() {
        let input = "1..<5\n//comment"
        let output: [Token] = [
            .number("1", .integer),
            .operator("..<", .infix),
            .number("5", .integer),
            .linebreak("\n"),
            .startOfScope("//"),
            .commentBody("comment"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSortAscending() {
        let input = "sort(by: <)"
        let output: [Token] = [
            .identifier("sort"),
            .startOfScope("("),
            .identifier("by"),
            .delimiter(":"),
            .space(" "),
            .operator("<", .none),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSortDescending() {
        let input = "sort(by: >)"
        let output: [Token] = [
            .identifier("sort"),
            .startOfScope("("),
            .identifier("by"),
            .delimiter(":"),
            .space(" "),
            .operator(">", .none),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericsWithWhereClause() {
        let input = "<A where A.B == C>"
        let output: [Token] = [
            .startOfScope("<"),
            .identifier("A"),
            .space(" "),
            .keyword("where"),
            .space(" "),
            .identifier("A"),
            .operator(".", .infix),
            .identifier("B"),
            .space(" "),
            .operator("==", .infix),
            .space(" "),
            .identifier("C"),
            .endOfScope(">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericsWithInfixOperator() {
        let input = "Foo<Bar> || Foo<Baz>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Bar"),
            .endOfScope(">"),
            .space(" "),
            .operator("||", .infix),
            .space(" "),
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Baz"),
            .endOfScope(">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testIfLessThanIfGreaterThan() {
        let input = "if x < 0 {}\nif y > (0) {}"
        let output: [Token] = [
            .keyword("if"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .operator("<", .infix),
            .space(" "),
            .number("0", .integer),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
            .linebreak("\n"),
            .keyword("if"),
            .space(" "),
            .identifier("y"),
            .space(" "),
            .operator(">", .infix),
            .space(" "),
            .startOfScope("("),
            .number("0", .integer),
            .endOfScope(")"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: optionals

    func testAssignOptional() {
        let input = "Int?=nil"
        let output: [Token] = [
            .identifier("Int"),
            .operator("?", .postfix),
            .operator("=", .infix),
            .identifier("nil"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testQuestionMarkEqualOperator() {
        let input = "foo ?= bar"
        let output: [Token] = [
            .identifier("foo"),
            .space(" "),
            .operator("?=", .infix),
            .space(" "),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testOptionalChaining() {
        let input = "foo!.bar"
        let output: [Token] = [
            .identifier("foo"),
            .operator("!", .postfix),
            .operator(".", .infix),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testMultipleOptionalChaining() {
        let input = "foo?!?.bar"
        let output: [Token] = [
            .identifier("foo"),
            .operator("?", .postfix),
            .operator("!", .postfix),
            .operator("?", .postfix),
            .operator(".", .infix),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSplitLineOptionalChaining() {
        let input = "foo?\n    .bar"
        let output: [Token] = [
            .identifier("foo"),
            .operator("?", .postfix),
            .linebreak("\n"),
            .space("    "),
            .operator(".", .infix),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: case statements

    func testSingleLineEnum() {
        let input = "enum Foo {case Bar, Baz}"
        let output: [Token] = [
            .keyword("enum"),
            .space(" "),
            .identifier("Foo"),
            .space(" "),
            .startOfScope("{"),
            .keyword("case"),
            .space(" "),
            .identifier("Bar"),
            .delimiter(","),
            .space(" "),
            .identifier("Baz"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSingleLineGenericEnum() {
        let input = "enum Foo<T> {case Bar, Baz}"
        let output: [Token] = [
            .keyword("enum"),
            .space(" "),
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("T"),
            .endOfScope(">"),
            .space(" "),
            .startOfScope("{"),
            .keyword("case"),
            .space(" "),
            .identifier("Bar"),
            .delimiter(","),
            .space(" "),
            .identifier("Baz"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testMultilineLineEnum() {
        let input = "enum Foo {\ncase Bar\ncase Baz\n}"
        let output: [Token] = [
            .keyword("enum"),
            .space(" "),
            .identifier("Foo"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n"),
            .keyword("case"),
            .space(" "),
            .identifier("Bar"),
            .linebreak("\n"),
            .keyword("case"),
            .space(" "),
            .identifier("Baz"),
            .linebreak("\n"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchStatement() {
        let input = "switch x {\ncase 1:\nbreak\ncase 2:\nbreak\ndefault:\nbreak\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n"),
            .endOfScope("case"),
            .space(" "),
            .number("1", .integer),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("break"),
            .linebreak("\n"),
            .endOfScope("case"),
            .space(" "),
            .number("2", .integer),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("break"),
            .linebreak("\n"),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("break"),
            .linebreak("\n"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchStatementWithEnumCases() {
        let input = "switch x {\ncase.foo,\n.bar:\nbreak\ndefault:\nbreak\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n"),
            .endOfScope("case"),
            .operator(".", .prefix),
            .identifier("foo"),
            .delimiter(","),
            .linebreak("\n"),
            .operator(".", .prefix),
            .identifier("bar"),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("break"),
            .linebreak("\n"),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("break"),
            .linebreak("\n"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchCaseContainingDictionaryDefault() {
        let input = "switch x {\ncase y: foo[\"z\", default: []]\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n"),
            .endOfScope("case"),
            .space(" "),
            .identifier("y"),
            .startOfScope(":"),
            .space(" "),
            .identifier("foo"),
            .startOfScope("["),
            .startOfScope("\""),
            .stringBody("z"),
            .endOfScope("\""),
            .delimiter(","),
            .space(" "),
            .identifier("default"),
            .delimiter(":"),
            .space(" "),
            .startOfScope("["),
            .endOfScope("]"),
            .endOfScope("]"),
            .linebreak("\n"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchCaseIsDictionaryStatement() {
        let input = "switch x {\ncase foo is [Key: Value]:\nbreak\ndefault:\nbreak\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n"),
            .endOfScope("case"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .keyword("is"),
            .space(" "),
            .startOfScope("["),
            .identifier("Key"),
            .delimiter(":"),
            .space(" "),
            .identifier("Value"),
            .endOfScope("]"),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("break"),
            .linebreak("\n"),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("break"),
            .linebreak("\n"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchCaseContainingCaseIdentifier() {
        let input = "switch x {\ncase 1:\nfoo.case\ndefault:\nbreak\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n"),
            .endOfScope("case"),
            .space(" "),
            .number("1", .integer),
            .startOfScope(":"),
            .linebreak("\n"),
            .identifier("foo"),
            .operator(".", .infix),
            .identifier("case"),
            .linebreak("\n"),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("break"),
            .linebreak("\n"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchCaseContainingDefaultIdentifier() {
        let input = "switch x {\ncase 1:\nfoo.default\ndefault:\nbreak\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n"),
            .endOfScope("case"),
            .space(" "),
            .number("1", .integer),
            .startOfScope(":"),
            .linebreak("\n"),
            .identifier("foo"),
            .operator(".", .infix),
            .identifier("default"),
            .linebreak("\n"),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("break"),
            .linebreak("\n"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchCaseContainingIfCase() {
        let input = "switch x {\ncase 1:\nif case x = y {}\ndefault:\nbreak\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n"),
            .endOfScope("case"),
            .space(" "),
            .number("1", .integer),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("if"),
            .space(" "),
            .keyword("case"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("y"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
            .linebreak("\n"),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("break"),
            .linebreak("\n"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchCaseContainingIfCaseCommaCase() {
        let input = "switch x {\ncase 1:\nif case w = x, case y = z {}\ndefault:\nbreak\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n"),
            .endOfScope("case"),
            .space(" "),
            .number("1", .integer),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("if"),
            .space(" "),
            .keyword("case"),
            .space(" "),
            .identifier("w"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("x"),
            .delimiter(","),
            .space(" "),
            .keyword("case"),
            .space(" "),
            .identifier("y"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("z"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
            .linebreak("\n"),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("break"),
            .linebreak("\n"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchCaseContainingGuardCase() {
        let input = "switch x {\ncase 1:\nguard case x = y else {}\ndefault:\nbreak\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n"),
            .endOfScope("case"),
            .space(" "),
            .number("1", .integer),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("guard"),
            .space(" "),
            .keyword("case"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("y"),
            .space(" "),
            .keyword("else"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
            .linebreak("\n"),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("break"),
            .linebreak("\n"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchFollowedByEnum() {
        let input = "switch x {\ncase y: break\ndefault: break\n}\nenum Foo {\ncase z\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n"),
            .endOfScope("case"),
            .space(" "),
            .identifier("y"),
            .startOfScope(":"),
            .space(" "),
            .keyword("break"),
            .linebreak("\n"),
            .endOfScope("default"),
            .startOfScope(":"),
            .space(" "),
            .keyword("break"),
            .linebreak("\n"),
            .endOfScope("}"),
            .linebreak("\n"),
            .keyword("enum"),
            .space(" "),
            .identifier("Foo"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n"),
            .keyword("case"),
            .space(" "),
            .identifier("z"),
            .linebreak("\n"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchCaseContainingSwitchIdentifierFollowedByEnum() {
        let input = "switch x {\ncase 1:\nfoo.switch\ndefault:\nbreak\n}\nenum Foo {\ncase z\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n"),
            .endOfScope("case"),
            .space(" "),
            .number("1", .integer),
            .startOfScope(":"),
            .linebreak("\n"),
            .identifier("foo"),
            .operator(".", .infix),
            .identifier("switch"),
            .linebreak("\n"),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("break"),
            .linebreak("\n"),
            .endOfScope("}"),
            .linebreak("\n"),
            .keyword("enum"),
            .space(" "),
            .identifier("Foo"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n"),
            .keyword("case"),
            .space(" "),
            .identifier("z"),
            .linebreak("\n"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchCaseContainingRangeOperator() {
        let input = "switch x {\ncase 0 ..< 2:\nbreak\ndefault:\nbreak\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n"),
            .endOfScope("case"),
            .space(" "),
            .number("0", .integer),
            .space(" "),
            .operator("..<", .infix),
            .space(" "),
            .number("2", .integer),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("break"),
            .linebreak("\n"),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("break"),
            .linebreak("\n"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testEnumDeclarationInsideSwitchCase() {
        let input = "switch x {\ncase y:\nenum Foo {\ncase z\n}\nbreak\ndefault: break\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n"),
            .endOfScope("case"),
            .space(" "),
            .identifier("y"),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("enum"),
            .space(" "),
            .identifier("Foo"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n"),
            .keyword("case"),
            .space(" "),
            .identifier("z"),
            .linebreak("\n"),
            .endOfScope("}"),
            .linebreak("\n"),
            .keyword("break"),
            .linebreak("\n"),
            .endOfScope("default"),
            .startOfScope(":"),
            .space(" "),
            .keyword("break"),
            .linebreak("\n"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testDefaultAfterWhereCondition() {
        let input = "switch foo {\ncase _ where baz < quux:\nbreak\ndefault:\nbreak\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n"),
            .endOfScope("case"),
            .space(" "),
            .identifier("_"),
            .space(" "),
            .keyword("where"),
            .space(" "),
            .identifier("baz"),
            .space(" "),
            .operator("<", .infix),
            .space(" "),
            .identifier("quux"),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("break"),
            .linebreak("\n"),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("break"),
            .linebreak("\n"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testEnumWithConditionalCase() {
        let input = "enum Foo {\ncase bar\n#if baz\ncase baz\n#endif\n}"
        let output: [Token] = [
            .keyword("enum"),
            .space(" "),
            .identifier("Foo"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n"),
            .keyword("case"),
            .space(" "),
            .identifier("bar"),
            .linebreak("\n"),
            .startOfScope("#if"),
            .space(" "),
            .identifier("baz"),
            .linebreak("\n"),
            .keyword("case"),
            .space(" "),
            .identifier("baz"),
            .linebreak("\n"),
            .endOfScope("#endif"),
            .linebreak("\n"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchWithConditionalCase() {
        let input = "switch foo {\ncase bar:\nbreak\n#if baz\ndefault:\nbreak\n#endif\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n"),
            .endOfScope("case"),
            .space(" "),
            .identifier("bar"),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("break"),
            .linebreak("\n"),
            .startOfScope("#if"),
            .space(" "),
            .identifier("baz"),
            .linebreak("\n"),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("break"),
            .linebreak("\n"),
            .endOfScope("#endif"),
            .linebreak("\n"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchWithConditionalCase2() {
        let input = "switch foo {\n#if baz\ndefault:\nbreak\n#else\ncase bar:\nbreak\n#endif\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n"),
            .startOfScope("#if"),
            .space(" "),
            .identifier("baz"),
            .linebreak("\n"),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("break"),
            .linebreak("\n"),
            .keyword("#else"),
            .linebreak("\n"),
            .endOfScope("case"),
            .space(" "),
            .identifier("bar"),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("break"),
            .linebreak("\n"),
            .endOfScope("#endif"),
            .linebreak("\n"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchWithConditionalCase3() {
        let input = "switch foo {\n#if baz\ncase foo:\nbreak\n#endif\ncase bar:\nbreak\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n"),
            .startOfScope("#if"),
            .space(" "),
            .identifier("baz"),
            .linebreak("\n"),
            .endOfScope("case"),
            .space(" "),
            .identifier("foo"),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("break"),
            .linebreak("\n"),
            .endOfScope("#endif"),
            .linebreak("\n"),
            .endOfScope("case"),
            .space(" "),
            .identifier("bar"),
            .startOfScope(":"),
            .linebreak("\n"),
            .keyword("break"),
            .linebreak("\n"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericEnumCase() {
        let input = "enum Foo<T>: Bar where T: Bar { case bar }"
        let output: [Token] = [
            .keyword("enum"),
            .space(" "),
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("T"),
            .endOfScope(">"),
            .delimiter(":"),
            .space(" "),
            .identifier("Bar"),
            .space(" "),
            .keyword("where"),
            .space(" "),
            .identifier("T"),
            .delimiter(":"),
            .space(" "),
            .identifier("Bar"),
            .space(" "),
            .startOfScope("{"),
            .space(" "),
            .keyword("case"),
            .space(" "),
            .identifier("bar"),
            .space(" "),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCaseEnumValueWithoutSpaces() {
        let input = "switch x { case.foo:break }"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .space(" "),
            .endOfScope("case"),
            .operator(".", .prefix),
            .identifier("foo"),
            .startOfScope(":"),
            .keyword("break"),
            .space(" "),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: dot prefix

    func testEnumValueInDictionaryLiteral() {
        let input = "[.foo:.bar]"
        let output: [Token] = [
            .startOfScope("["),
            .operator(".", .prefix),
            .identifier("foo"),
            .delimiter(":"),
            .operator(".", .prefix),
            .identifier("bar"),
            .endOfScope("]"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: linebreaks

    func testLF() {
        let input = "foo\nbar"
        let output: [Token] = [
            .identifier("foo"),
            .linebreak("\n"),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCR() {
        let input = "foo\rbar"
        let output: [Token] = [
            .identifier("foo"),
            .linebreak("\r"),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCRLF() {
        let input = "foo\r\nbar"
        let output: [Token] = [
            .identifier("foo"),
            .linebreak("\r\n"),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCRLFAfterComment() {
        let input = "//foo\r\n//bar"
        let output: [Token] = [
            .startOfScope("//"),
            .commentBody("foo"),
            .linebreak("\r\n"),
            .startOfScope("//"),
            .commentBody("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCRLFInMultilineComment() {
        let input = "/*foo\r\nbar*/"
        let output: [Token] = [
            .startOfScope("/*"),
            .commentBody("foo"),
            .linebreak("\r\n"),
            .commentBody("bar"),
            .endOfScope("*/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: keypaths

    func testNamespacedKeyPath() {
        let input = "let foo = \\Foo.bar"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .operator("\\", .prefix),
            .identifier("Foo"),
            .operator(".", .infix),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testAnonymousKeyPath() {
        let input = "let foo = \\.bar"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .operator("\\", .prefix),
            .operator(".", .prefix),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testAnonymousSubscriptKeyPath() {
        let input = "let foo = \\.[0].bar"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .operator("\\", .prefix),
            .operator(".", .prefix),
            .startOfScope("["),
            .number("0", .integer),
            .endOfScope("]"),
            .operator(".", .infix),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }
}
