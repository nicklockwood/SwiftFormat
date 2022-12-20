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

    func testForwardBackslashOperator() {
        let input = "infix operator /\\"
        let output: [Token] = [
            .identifier("infix"),
            .space(" "),
            .keyword("operator"),
            .space(" "),
            .operator("/", .none),
            .operator("\\", .none),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Hashbang

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
            .linebreak("\n", 1),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testHashbangAfterFirstLine() {
        let input = "//Hello World\n#!/usr/bin/swift \n"
        let output: [Token] = [
            .startOfScope("//"),
            .commentBody("Hello World"),
            .linebreak("\n", 1),
            .error("#!/usr/bin/swift"),
            .space(" "),
            .linebreak("\n", 2),
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

    func testUnterminatedString() {
        let input = "\"foo"
        let output: [Token] = [
            .startOfScope("\""),
            .stringBody("foo"),
            .error(""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnterminatedString2() {
        let input = "\"foo\nbar"
        let output: [Token] = [
            .startOfScope("\""),
            .stringBody("foo"),
            .error(""),
            .linebreak("\n", 1),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnterminatedString3() {
        let input = "\"foo\n\""
        let output: [Token] = [
            .startOfScope("\""),
            .stringBody("foo"),
            .error(""),
            .linebreak("\n", 1),
            .startOfScope("\""),
            .error(""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Multiline strings

    func testSimpleMultilineString() {
        let input = "\"\"\"\n    hello\n    world\n    \"\"\""
        let output: [Token] = [
            .startOfScope("\"\"\""),
            .linebreak("\n", 1),
            .space("    "),
            .stringBody("hello"),
            .linebreak("\n", 2),
            .space("    "),
            .stringBody("world"),
            .linebreak("\n", 3),
            .space("    "),
            .endOfScope("\"\"\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testIndentedSimpleMultilineString() {
        let input = "\"\"\"\n    hello\n    world\n\"\"\""
        let output: [Token] = [
            .startOfScope("\"\"\""),
            .linebreak("\n", 1),
            .stringBody("    hello"),
            .linebreak("\n", 2),
            .stringBody("    world"),
            .linebreak("\n", 3),
            .endOfScope("\"\"\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testEmptyMultilineString() {
        let input = "\"\"\"\n\"\"\""
        let output: [Token] = [
            .startOfScope("\"\"\""),
            .linebreak("\n", 1),
            .endOfScope("\"\"\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testMultilineStringWithEscapedLinebreak() {
        let input = "\"\"\"\n    hello \\\n    world\n\"\"\""
        let output: [Token] = [
            .startOfScope("\"\"\""),
            .linebreak("\n", 1),
            .stringBody("    hello \\"),
            .linebreak("\n", 2),
            .stringBody("    world"),
            .linebreak("\n", 3),
            .endOfScope("\"\"\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testMultilineStringStartingWithInterpolation() {
        let input = "    \"\"\"\n    \\(String(describing: 1))\n    \"\"\""
        let output: [Token] = [
            .space("    "),
            .startOfScope("\"\"\""),
            .linebreak("\n", 1),
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
            .linebreak("\n", 2),
            .space("    "),
            .endOfScope("\"\"\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testMultilineStringWithMultilineInterpolation() {
        let input = """
        \"\""
        \\(
            6
        )
        \"\""
        """
        let output: [Token] = [
            .startOfScope("\"\"\""),
            .linebreak("\n", 1),
            .stringBody("\\"),
            .startOfScope("("),
            .linebreak("\n", 2),
            .space("    "),
            .number("6", .integer),
            .linebreak("\n", 3),
            .endOfScope(")"),
            .linebreak("\n", 4),
            .endOfScope("\"\"\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testIndentMultilineStringWithMultilineNestedInterpolation() {
        let input = """
        \"\""
            foo
                \\(bar {
                    \"\""
                        baz
                    \"\""
                })
            quux
        \"\""
        """
        let output: [Token] = [
            .startOfScope("\"\"\""),
            .linebreak("\n", 1),
            .stringBody("    foo"),
            .linebreak("\n", 2),
            .stringBody("        \\"),
            .startOfScope("("),
            .identifier("bar"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 3),
            .space("            "),
            .startOfScope("\"\"\""),
            .linebreak("\n", 4),
            .space("            "),
            .stringBody("    baz"),
            .linebreak("\n", 5),
            .space("            "),
            .endOfScope("\"\"\""),
            .linebreak("\n", 6),
            .space("        "),
            .endOfScope("}"),
            .endOfScope(")"),
            .linebreak("\n", 7),
            .stringBody("    quux"),
            .linebreak("\n", 8),
            .endOfScope("\"\"\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testIndentMultilineStringWithMultilineNestedInterpolation2() {
        let input = """
        \"\""
            foo
                \\(bar {
                    \"\""
                        baz
                    \"\""
                    }
                )
            quux
        \"\""
        """
        let output: [Token] = [
            .startOfScope("\"\"\""),
            .linebreak("\n", 1),
            .stringBody("    foo"),
            .linebreak("\n", 2),
            .stringBody("        \\"),
            .startOfScope("("),
            .identifier("bar"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 3),
            .space("            "),
            .startOfScope("\"\"\""),
            .linebreak("\n", 4),
            .space("            "),
            .stringBody("    baz"),
            .linebreak("\n", 5),
            .space("            "),
            .endOfScope("\"\"\""),
            .linebreak("\n", 6),
            .space("            "),
            .endOfScope("}"),
            .linebreak("\n", 7),
            .space("        "),
            .endOfScope(")"),
            .linebreak("\n", 8),
            .stringBody("    quux"),
            .linebreak("\n", 9),
            .endOfScope("\"\"\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testMultilineStringWithEscapedTripleQuote() {
        let input = "\"\"\"\n\\\"\"\"\n\"\"\""
        let output: [Token] = [
            .startOfScope("\"\"\""),
            .linebreak("\n", 1),
            .stringBody("\\\"\"\""),
            .linebreak("\n", 2),
            .endOfScope("\"\"\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Raw strings

    func testEmptyRawString() {
        let input = "#\"\"#"
        let output: [Token] = [
            .startOfScope("#\""),
            .endOfScope("\"#"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testEmptyDoubleRawString() {
        let input = "##\"\"##"
        let output: [Token] = [
            .startOfScope("##\""),
            .endOfScope("\"##"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnbalancedRawString() {
        let input = "##\"\"#"
        let output: [Token] = [
            .startOfScope("##\""),
            .stringBody("\"#"),
            .error(""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnbalancedRawString2() {
        let input = "#\"\"##"
        let output: [Token] = [
            .startOfScope("#\""),
            .endOfScope("\"#"),
            .error("#"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testRawStringContainingUnescapedQuote() {
        let input = "#\" \" \"#"
        let output: [Token] = [
            .startOfScope("#\""),
            .stringBody(" \" "),
            .endOfScope("\"#"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testRawStringContainingJustASingleUnescapedQuote() {
        let input = "#\"\"\"#"
        let output: [Token] = [
            .startOfScope("#\""),
            .stringBody("\""),
            .endOfScope("\"#"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testRawStringContainingUnhashedBackslash() {
        let input = "#\"\\\"#"
        let output: [Token] = [
            .startOfScope("#\""),
            .stringBody("\\"),
            .endOfScope("\"#"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testRawStringContainingHashedEscapeSequence() {
        let input = "#\"\\#n\"#"
        let output: [Token] = [
            .startOfScope("#\""),
            .stringBody("\\#n"),
            .endOfScope("\"#"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testRawStringContainingUnderhashedEscapeSequence() {
        let input = "##\"\\#n\"##"
        let output: [Token] = [
            .startOfScope("##\""),
            .stringBody("\\#n"),
            .endOfScope("\"##"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testRawStringContainingUnhashedInterpolation() {
        let input = "#\"\\(5)\"#"
        let output: [Token] = [
            .startOfScope("#\""),
            .stringBody("\\(5)"),
            .endOfScope("\"#"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testRawStringContainingHashedInterpolation() {
        let input = "#\"\\#(5)\"#"
        let output: [Token] = [
            .startOfScope("#\""),
            .stringBody("\\#"),
            .startOfScope("("),
            .number("5", .integer),
            .endOfScope(")"),
            .endOfScope("\"#"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testRawStringContainingUnderhashedInterpolation() {
        let input = "##\"\\#(5)\"##"
        let output: [Token] = [
            .startOfScope("##\""),
            .stringBody("\\#(5)"),
            .endOfScope("\"##"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Multiline raw strings

    func testSimpleMultilineRawString() {
        let input = "#\"\"\"\n    hello\n    world\n    \"\"\"#"
        let output: [Token] = [
            .startOfScope("#\"\"\""),
            .linebreak("\n", 1),
            .space("    "),
            .stringBody("hello"),
            .linebreak("\n", 2),
            .space("    "),
            .stringBody("world"),
            .linebreak("\n", 3),
            .space("    "),
            .endOfScope("\"\"\"#"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testMultilineRawStringContainingUnhashedInterpolation() {
        let input = "#\"\"\"\n    \\(5)\n    \"\"\"#"
        let output: [Token] = [
            .startOfScope("#\"\"\""),
            .linebreak("\n", 1),
            .space("    "),
            .stringBody("\\(5)"),
            .linebreak("\n", 2),
            .space("    "),
            .endOfScope("\"\"\"#"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testMultilineRawStringContainingHashedInterpolation() {
        let input = "#\"\"\"\n    \\#(5)\n    \"\"\"#"
        let output: [Token] = [
            .startOfScope("#\"\"\""),
            .linebreak("\n", 1),
            .space("    "),
            .stringBody("\\#"),
            .startOfScope("("),
            .number("5", .integer),
            .endOfScope(")"),
            .linebreak("\n", 2),
            .space("    "),
            .endOfScope("\"\"\"#"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testMultilineRawStringContainingUnderhashedInterpolation() {
        let input = "##\"\"\"\n    \\#(5)\n    \"\"\"##"
        let output: [Token] = [
            .startOfScope("##\"\"\""),
            .linebreak("\n", 1),
            .space("    "),
            .stringBody("\\#(5)"),
            .linebreak("\n", 2),
            .space("    "),
            .endOfScope("\"\"\"##"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Regex literals

    func testSingleLineRegexLiteral() {
        let input = "let regex = /(\\w+)\\s\\s+(\\S+)\\s\\s+((?:(?!\\s\\s).)*)\\s\\s+(.*)/"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("regex"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .startOfScope("/"),
            .stringBody("(\\w+)\\s\\s+(\\S+)\\s\\s+((?:(?!\\s\\s).)*)\\s\\s+(.*)"),
            .endOfScope("/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testAnchoredSingleLineRegexLiteral() {
        let input = "let _ = /^foo$/"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("_"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .startOfScope("/"),
            .stringBody("^foo$"),
            .endOfScope("/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSingleLineRegexLiteralStartingWithEscapeSequence() {
        let input = "let regex = /\\w+/"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("regex"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .startOfScope("/"),
            .stringBody("\\w+"),
            .endOfScope("/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSingleLineRegexLiteralWithEscapedParens() {
        let input = "let regex = /\\(foo\\)/"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("regex"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .startOfScope("/"),
            .stringBody("\\(foo\\)"),
            .endOfScope("/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSingleLineRegexLiteralPrecededByTry() {
        let input = "let regex = try /foo/"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("regex"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .keyword("try"),
            .space(" "),
            .startOfScope("/"),
            .stringBody("foo"),
            .endOfScope("/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSingleLineRegexLiteralPrecededByOptionalTry() {
        let input = "let regex = try? /foo/"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("regex"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .keyword("try"),
            .operator("?", .postfix),
            .space(" "),
            .startOfScope("/"),
            .stringBody("foo"),
            .endOfScope("/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testRegexLiteralInArray() {
        let input = "[/foo/]"
        let output: [Token] = [
            .startOfScope("["),
            .startOfScope("/"),
            .stringBody("foo"),
            .endOfScope("/"),
            .endOfScope("]"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testRegexLiteralAfterLabel() {
        let input = "foo(of: /http|https/)"
        let output: [Token] = [
            .identifier("foo"),
            .startOfScope("("),
            .identifier("of"),
            .delimiter(":"),
            .space(" "),
            .startOfScope("/"),
            .stringBody("http|https"),
            .endOfScope("/"),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testHashedSingleLineRegexLiteral() {
        let input = "let regex = #/foo/bar/#"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("regex"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .startOfScope("#/"),
            .stringBody("foo/bar"),
            .endOfScope("/#"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testMultilineRegexLiteral() {
        let input = """
        let regex = #/
        foo
        /#
        """
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("regex"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .startOfScope("#/"),
            .linebreak("\n", 1),
            .stringBody("foo"),
            .linebreak("\n", 2),
            .endOfScope("/#"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testMultilineRegexLiteral2() {
        let input = """
        let regex = ##/
        foo
        bar
        /##
        """
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("regex"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .startOfScope("##/"),
            .linebreak("\n", 1),
            .stringBody("foo"),
            .linebreak("\n", 2),
            .stringBody("bar"),
            .linebreak("\n", 3),
            .endOfScope("/##"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testPrefixPostfixSlashOperatorNotPermitted() {
        let input = "let x = /0; let y = 1/"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .startOfScope("/"),
            .stringBody("0; let y = 1"),
            .endOfScope("/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testInlineSlashPairTreatedAsOperators() {
        let input = "x+/y/+z"
        let output: [Token] = [
            .identifier("x"),
            .operator("+/", .infix),
            .identifier("y"),
            .operator("/+", .infix),
            .identifier("z"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCasePathTreatedAsOperator() {
        let input = "let foo = /Foo.bar"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .operator("/", .prefix),
            .identifier("Foo"),
            .operator(".", .infix),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCasePathTreatedAsOperator2() {
        let input = "let foo = /Foo.bar\nbaz"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .operator("/", .prefix),
            .identifier("Foo"),
            .operator(".", .infix),
            .identifier("bar"),
            .linebreak("\n", 2),
            .identifier("baz"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCasePathInParenthesesTreatedAsOperator() {
        let input = "foo(/Foo.bar)"
        let output: [Token] = [
            .identifier("foo"),
            .startOfScope("("),
            .operator("/", .prefix),
            .identifier("Foo"),
            .operator(".", .infix),
            .identifier("bar"),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testDivideOperatorInParenthesesTreatedAsOperator() {
        let input = "return (/)\n"
        let output: [Token] = [
            .keyword("return"),
            .space(" "),
            .startOfScope("("),
            .operator("/", .none),
            .endOfScope(")"),
            .linebreak("\n", 2),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testPrefixSlashCaretOperator() {
        let input = "let _ = /^foo"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("_"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .operator("/^", .prefix),
            .identifier("foo"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testPrefixSlashQueryOperator() {
        let input = "let _ = /?foo"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("_"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .operator("/?", .prefix),
            .identifier("foo"),
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
            .linebreak("\n", 1),
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
            .linebreak("\n", 1),
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
            .linebreak("\n", 1),
            .space("  "),
            .commentBody("bar"),
            .endOfScope("*/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCommentIndentingWithTrailingClose() {
        let input = "/* foo\n */"
        let output: [Token] = [
            .startOfScope("/*"),
            .space(" "),
            .commentBody("foo"),
            .linebreak("\n", 1),
            .space(" "),
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

    func testPreformattedMultilineComment() {
        let input = """
        /*
         func foo() {
           if bar {
             print(baz)
           }
         }
         */
        """
        let output: [Token] = [
            .startOfScope("/*"),
            .linebreak("\n", 1),
            .space(" "),
            .commentBody("func foo() {"),
            .linebreak("\n", 2),
            .space(" "),
            .commentBody("  if bar {"),
            .linebreak("\n", 3),
            .space(" "),
            .commentBody("    print(baz)"),
            .linebreak("\n", 4),
            .space(" "),
            .commentBody("  }"),
            .linebreak("\n", 5),
            .space(" "),
            .commentBody("}"),
            .linebreak("\n", 6),
            .space(" "),
            .endOfScope("*/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testPreformattedMultilineComment2() {
        let input = """
        /**
        func foo() {
            bar()
        }
        */
        """
        let output: [Token] = [
            .startOfScope("/*"),
            .commentBody("*"),
            .linebreak("\n", 1),
            .commentBody("func foo() {"),
            .linebreak("\n", 2),
            .commentBody("    bar()"),
            .linebreak("\n", 3),
            .commentBody("}"),
            .linebreak("\n", 4),
            .endOfScope("*/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testIndentedNestedMultilineComment() {
        let input = """
        /*
         func foo() {
             /*
              * Nested comment
              */
             bar {}
         }
         */
        """
        let output: [Token] = [
            .startOfScope("/*"),
            .linebreak("\n", 1),
            .space(" "),
            .commentBody("func foo() {"),
            .linebreak("\n", 2),
            .space(" "),
            .commentBody("    "),
            .startOfScope("/*"),
            .linebreak("\n", 3),
            .space(" "),
            .commentBody("     * Nested comment"),
            .linebreak("\n", 4),
            .space(" "),
            .commentBody("     "),
            .endOfScope("*/"),
            .linebreak("\n", 5),
            .space(" "),
            .commentBody("    bar {}"),
            .linebreak("\n", 6),
            .space(" "),
            .commentBody("}"),
            .linebreak("\n", 7),
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

    #if os(macOS)
        func testEmoji() {
            let input = "🙃"
            let output: [Token] = [.identifier("🙃")]
            XCTAssertEqual(tokenize(input), output)
        }
    #endif

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

    func testNamespacedAttribute() {
        let input = "@OuterType.Wrapper"
        let output: [Token] = [
            .keyword("@OuterType"),
            .operator(".", .infix),
            .identifier("Wrapper"),
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

    func testKeywordAsClosureLabel() {
        let input = "foo.if(bar) { bar } else: { baz }"
        let output: [Token] = [
            .identifier("foo"),
            .operator(".", .infix),
            .identifier("if"),
            .startOfScope("("),
            .identifier("bar"),
            .endOfScope(")"),
            .space(" "),
            .startOfScope("{"),
            .space(" "),
            .identifier("bar"),
            .space(" "),
            .endOfScope("}"),
            .space(" "),
            .identifier("else"),
            .delimiter(":"),
            .space(" "),
            .startOfScope("{"),
            .space(" "),
            .identifier("baz"),
            .space(" "),
            .endOfScope("}"),
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

    func testXcodeToken() {
        let input = """
        test(image: <#T##UIImage#>)
        """
        let output: [Token] = [
            .identifier("test"),
            .startOfScope("("),
            .identifier("image"),
            .delimiter(":"),
            .space(" "),
            .identifier("<#T##UIImage#>"),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testXcodeWithArrayAndClosureToken() {
        let input = """
        monkey(smelly: <#T##Bool#>, happy: <#T##Bool#>, names: <#T##[String]#>, throw💩: <#T##((Int) -> Void)##((Int) -> Void)##(Int) -> Void#>)
        """
        let output: [Token] = [
            .identifier("monkey"),
            .startOfScope("("),
            .identifier("smelly"),
            .delimiter(":"),
            .space(" "),
            .identifier("<#T##Bool#>"),
            .delimiter(","),
            .space(" "),
            .identifier("happy"),
            .delimiter(":"),
            .space(" "),
            .identifier("<#T##Bool#>"),
            .delimiter(","),
            .space(" "),
            .identifier("names"),
            .delimiter(":"),
            .space(" "),
            .identifier("<#T##[String]#>"),
            .delimiter(","),
            .space(" "),
            .identifier("throw💩"),
            .delimiter(":"),
            .space(" "),
            .identifier("<#T##((Int) -> Void)##((Int) -> Void)##(Int) -> Void#>"),
            .endOfScope(")"),
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

    func testAngleBracketSuffixedOperator() {
        let input = "..<"
        let output: [Token] = [.operator("..<", .none)]
        XCTAssertEqual(tokenize(input), output)
    }

    func testAngleBracketSuffixedOperator2() {
        let input = "a..<b"
        let output: [Token] = [
            .identifier("a"),
            .operator("..<", .infix),
            .identifier("b"),
        ]
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
            .linebreak("\n", 1),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testInfixOperatorAfterLinebreak() {
        let input = "foo\n+ bar"
        let output: [Token] = [
            .identifier("foo"),
            .linebreak("\n", 1),
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
        let input = "foo - .bar"
        let output: [Token] = [
            .identifier("foo"),
            .space(" "),
            .operator("-", .infix),
            .space(" "),
            .operator(".", .prefix),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testPostfixOperatorBeforeMember() {
        let input = "foo′.bar"
        let output: [Token] = [
            .identifier("foo"),
            .operator("′", .postfix),
            .operator(".", .infix),
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

    func testLessThanGreaterThanFollowedByOperator() {
        let input = "a > -x, a<x, b > -y, b<y"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator(">", .infix),
            .space(" "),
            .operator("-", .prefix),
            .identifier("x"),
            .delimiter(","),
            .space(" "),
            .identifier("a"),
            .operator("<", .infix),
            .identifier("x"),
            .delimiter(","),
            .space(" "),
            .identifier("b"),
            .space(" "),
            .operator(">", .infix),
            .space(" "),
            .operator("-", .prefix),
            .identifier("y"),
            .delimiter(","),
            .space(" "),
            .identifier("b"),
            .operator("<", .infix),
            .identifier("y"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericTypeAmpersandProtocol() {
        let input = "Foo<Int> & Bar"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Int"),
            .endOfScope(">"),
            .space(" "),
            .operator("&", .infix),
            .space(" "),
            .identifier("Bar"),
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

    func testGenericDeclarationWithoutSpace() {
        let input = "let foo: Foo<String,Int>=[]"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("foo"),
            .delimiter(":"),
            .space(" "),
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("String"),
            .delimiter(","),
            .identifier("Int"),
            .endOfScope(">"),
            .operator("=", .infix),
            .startOfScope("["),
            .endOfScope("]"),
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

    func testChevronOperatorDoesntBreakScopeStack() {
        let input = "if a << b != 0 { let foo = bar() }"
        let output: [Token] = [
            .keyword("if"),
            .space(" "),
            .identifier("a"),
            .space(" "),
            .operator("<<", .infix),
            .space(" "),
            .identifier("b"),
            .space(" "),
            .operator("!=", .infix),
            .space(" "),
            .number("0", .integer),
            .space(" "),
            .startOfScope("{"),
            .space(" "),
            .keyword("let"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("bar"),
            .startOfScope("("),
            .endOfScope(")"),
            .space(" "),
            .endOfScope("}"),
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
            .linebreak("\n", 1),
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

    func testGenericTypeFollowedByAndOperator() {
        let input = "Foo<Bar> && baz"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Bar"),
            .endOfScope(">"),
            .space(" "),
            .operator("&&", .infix),
            .space(" "),
            .identifier("baz"),
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
            .linebreak("\n", 1),
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

    func testIfLessThanGreaterThanExpression() {
        let input = "if x < (y + z), y > (z * w) {}"
        let output: [Token] = [
            .keyword("if"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .operator("<", .infix),
            .space(" "),
            .startOfScope("("),
            .identifier("y"),
            .space(" "),
            .operator("+", .infix),
            .space(" "),
            .identifier("z"),
            .endOfScope(")"),
            .delimiter(","),
            .space(" "),
            .identifier("y"),
            .space(" "),
            .operator(">", .infix),
            .space(" "),
            .startOfScope("("),
            .identifier("z"),
            .space(" "),
            .operator("*", .infix),
            .space(" "),
            .identifier("w"),
            .endOfScope(")"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
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
            .linebreak("\n", 1),
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

    func testLessThanEnumCase() {
        let input = "XCTAssertFalse(.never < .never)"
        let output: [Token] = [
            .identifier("XCTAssertFalse"),
            .startOfScope("("),
            .operator(".", .prefix),
            .identifier("never"),
            .space(" "),
            .operator("<", .infix),
            .space(" "),
            .operator(".", .prefix),
            .identifier("never"),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testLessThanGreaterThanEnumCase() {
        let input = "if foo < .bar, baz > .quux"
        let output: [Token] = [
            .keyword("if"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .operator("<", .infix),
            .space(" "),
            .operator(".", .prefix),
            .identifier("bar"),
            .delimiter(","),
            .space(" "),
            .identifier("baz"),
            .space(" "),
            .operator(">", .infix),
            .space(" "),
            .operator(".", .prefix),
            .identifier("quux"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericResultBuilder() {
        let input = "func foo(@SomeResultBuilder<Self> builder: () -> Void) {}"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("foo"),
            .startOfScope("("),
            .keyword("@SomeResultBuilder"),
            .startOfScope("<"),
            .identifier("Self"),
            .endOfScope(">"),
            .space(" "),
            .identifier("builder"),
            .delimiter(":"),
            .space(" "),
            .startOfScope("("),
            .endOfScope(")"),
            .space(" "),
            .operator("->", .infix),
            .space(" "),
            .identifier("Void"),
            .endOfScope(")"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericResultBuilder2() {
        let input = "func foo(@SomeResultBuilder<Store<MainState>> builder: () -> Void) {}"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("foo"),
            .startOfScope("("),
            .keyword("@SomeResultBuilder"),
            .startOfScope("<"),
            .identifier("Store"),
            .startOfScope("<"),
            .identifier("MainState"),
            .endOfScope(">"),
            .endOfScope(">"),
            .space(" "),
            .identifier("builder"),
            .delimiter(":"),
            .space(" "),
            .startOfScope("("),
            .endOfScope(")"),
            .space(" "),
            .operator("->", .infix),
            .space(" "),
            .identifier("Void"),
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
            .linebreak("\n", 1),
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
            .linebreak("\n", 1),
            .keyword("case"),
            .space(" "),
            .identifier("Bar"),
            .linebreak("\n", 2),
            .keyword("case"),
            .space(" "),
            .identifier("Baz"),
            .linebreak("\n", 3),
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
            .linebreak("\n", 1),
            .endOfScope("case"),
            .space(" "),
            .number("1", .integer),
            .startOfScope(":"),
            .linebreak("\n", 2),
            .keyword("break"),
            .linebreak("\n", 3),
            .endOfScope("case"),
            .space(" "),
            .number("2", .integer),
            .startOfScope(":"),
            .linebreak("\n", 4),
            .keyword("break"),
            .linebreak("\n", 5),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n", 6),
            .keyword("break"),
            .linebreak("\n", 7),
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
            .linebreak("\n", 1),
            .endOfScope("case"),
            .operator(".", .prefix),
            .identifier("foo"),
            .delimiter(","),
            .linebreak("\n", 2),
            .operator(".", .prefix),
            .identifier("bar"),
            .startOfScope(":"),
            .linebreak("\n", 3),
            .keyword("break"),
            .linebreak("\n", 4),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n", 5),
            .keyword("break"),
            .linebreak("\n", 6),
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
            .linebreak("\n", 1),
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
            .linebreak("\n", 2),
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
            .linebreak("\n", 1),
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
            .linebreak("\n", 2),
            .keyword("break"),
            .linebreak("\n", 3),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n", 4),
            .keyword("break"),
            .linebreak("\n", 5),
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
            .linebreak("\n", 1),
            .endOfScope("case"),
            .space(" "),
            .number("1", .integer),
            .startOfScope(":"),
            .linebreak("\n", 2),
            .identifier("foo"),
            .operator(".", .infix),
            .identifier("case"),
            .linebreak("\n", 3),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n", 4),
            .keyword("break"),
            .linebreak("\n", 5),
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
            .linebreak("\n", 1),
            .endOfScope("case"),
            .space(" "),
            .number("1", .integer),
            .startOfScope(":"),
            .linebreak("\n", 2),
            .identifier("foo"),
            .operator(".", .infix),
            .identifier("default"),
            .linebreak("\n", 3),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n", 4),
            .keyword("break"),
            .linebreak("\n", 5),
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
            .linebreak("\n", 1),
            .endOfScope("case"),
            .space(" "),
            .number("1", .integer),
            .startOfScope(":"),
            .linebreak("\n", 2),
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
            .linebreak("\n", 3),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n", 4),
            .keyword("break"),
            .linebreak("\n", 5),
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
            .linebreak("\n", 1),
            .endOfScope("case"),
            .space(" "),
            .number("1", .integer),
            .startOfScope(":"),
            .linebreak("\n", 2),
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
            .linebreak("\n", 3),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n", 4),
            .keyword("break"),
            .linebreak("\n", 5),
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
            .linebreak("\n", 1),
            .endOfScope("case"),
            .space(" "),
            .number("1", .integer),
            .startOfScope(":"),
            .linebreak("\n", 2),
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
            .linebreak("\n", 3),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n", 4),
            .keyword("break"),
            .linebreak("\n", 5),
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
            .linebreak("\n", 1),
            .endOfScope("case"),
            .space(" "),
            .identifier("y"),
            .startOfScope(":"),
            .space(" "),
            .keyword("break"),
            .linebreak("\n", 2),
            .endOfScope("default"),
            .startOfScope(":"),
            .space(" "),
            .keyword("break"),
            .linebreak("\n", 3),
            .endOfScope("}"),
            .linebreak("\n", 4),
            .keyword("enum"),
            .space(" "),
            .identifier("Foo"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 5),
            .keyword("case"),
            .space(" "),
            .identifier("z"),
            .linebreak("\n", 6),
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
            .linebreak("\n", 1),
            .endOfScope("case"),
            .space(" "),
            .number("1", .integer),
            .startOfScope(":"),
            .linebreak("\n", 2),
            .identifier("foo"),
            .operator(".", .infix),
            .identifier("switch"),
            .linebreak("\n", 3),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n", 4),
            .keyword("break"),
            .linebreak("\n", 5),
            .endOfScope("}"),
            .linebreak("\n", 6),
            .keyword("enum"),
            .space(" "),
            .identifier("Foo"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 7),
            .keyword("case"),
            .space(" "),
            .identifier("z"),
            .linebreak("\n", 8),
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
            .linebreak("\n", 1),
            .endOfScope("case"),
            .space(" "),
            .number("0", .integer),
            .space(" "),
            .operator("..<", .infix),
            .space(" "),
            .number("2", .integer),
            .startOfScope(":"),
            .linebreak("\n", 2),
            .keyword("break"),
            .linebreak("\n", 3),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n", 4),
            .keyword("break"),
            .linebreak("\n", 5),
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
            .linebreak("\n", 1),
            .endOfScope("case"),
            .space(" "),
            .identifier("y"),
            .startOfScope(":"),
            .linebreak("\n", 2),
            .keyword("enum"),
            .space(" "),
            .identifier("Foo"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 3),
            .keyword("case"),
            .space(" "),
            .identifier("z"),
            .linebreak("\n", 4),
            .endOfScope("}"),
            .linebreak("\n", 5),
            .keyword("break"),
            .linebreak("\n", 6),
            .endOfScope("default"),
            .startOfScope(":"),
            .space(" "),
            .keyword("break"),
            .linebreak("\n", 7),
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
            .linebreak("\n", 1),
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
            .linebreak("\n", 2),
            .keyword("break"),
            .linebreak("\n", 3),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n", 4),
            .keyword("break"),
            .linebreak("\n", 5),
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
            .linebreak("\n", 1),
            .keyword("case"),
            .space(" "),
            .identifier("bar"),
            .linebreak("\n", 2),
            .startOfScope("#if"),
            .space(" "),
            .identifier("baz"),
            .linebreak("\n", 3),
            .keyword("case"),
            .space(" "),
            .identifier("baz"),
            .linebreak("\n", 4),
            .endOfScope("#endif"),
            .linebreak("\n", 5),
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
            .linebreak("\n", 1),
            .endOfScope("case"),
            .space(" "),
            .identifier("bar"),
            .startOfScope(":"),
            .linebreak("\n", 2),
            .keyword("break"),
            .linebreak("\n", 3),
            .startOfScope("#if"),
            .space(" "),
            .identifier("baz"),
            .linebreak("\n", 4),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n", 5),
            .keyword("break"),
            .linebreak("\n", 6),
            .endOfScope("#endif"),
            .linebreak("\n", 7),
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
            .linebreak("\n", 1),
            .startOfScope("#if"),
            .space(" "),
            .identifier("baz"),
            .linebreak("\n", 2),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n", 3),
            .keyword("break"),
            .linebreak("\n", 4),
            .keyword("#else"),
            .linebreak("\n", 5),
            .endOfScope("case"),
            .space(" "),
            .identifier("bar"),
            .startOfScope(":"),
            .linebreak("\n", 6),
            .keyword("break"),
            .linebreak("\n", 7),
            .endOfScope("#endif"),
            .linebreak("\n", 8),
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
            .linebreak("\n", 1),
            .startOfScope("#if"),
            .space(" "),
            .identifier("baz"),
            .linebreak("\n", 2),
            .endOfScope("case"),
            .space(" "),
            .identifier("foo"),
            .startOfScope(":"),
            .linebreak("\n", 3),
            .keyword("break"),
            .linebreak("\n", 4),
            .endOfScope("#endif"),
            .linebreak("\n", 5),
            .endOfScope("case"),
            .space(" "),
            .identifier("bar"),
            .startOfScope(":"),
            .linebreak("\n", 6),
            .keyword("break"),
            .linebreak("\n", 7),
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

    func testUncheckedSendableEnum() {
        let input = "enum Foo: @unchecked Sendable { case bar }"
        let output: [Token] = [
            .keyword("enum"),
            .space(" "),
            .identifier("Foo"),
            .delimiter(":"),
            .space(" "),
            .keyword("@unchecked"),
            .space(" "),
            .identifier("Sendable"),
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

    func testForCaseLetPreceededByAwait() {
        let input = "func forGroup(_ group: TaskGroup<String?>) async { for await case let value? in group { print(value.description) } }"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("forGroup"),
            .startOfScope("("),
            .identifier("_"),
            .space(" "),
            .identifier("group"),
            .delimiter(":"),
            .space(" "),
            .identifier("TaskGroup"),
            .startOfScope("<"),
            .identifier("String"),
            .operator("?", .postfix),
            .endOfScope(">"),
            .endOfScope(")"),
            .space(" "),
            .identifier("async"),
            .space(" "),
            .startOfScope("{"),
            .space(" "),
            .keyword("for"),
            .space(" "),
            .keyword("await"),
            .space(" "),
            .keyword("case"),
            .space(" "),
            .keyword("let"),
            .space(" "),
            .identifier("value"),
            .operator("?", .postfix),
            .space(" "),
            .keyword("in"),
            .space(" "),
            .identifier("group"),
            .space(" "),
            .startOfScope("{"),
            .space(" "),
            .identifier("print"),
            .startOfScope("("),
            .identifier("value"),
            .operator(".", .infix),
            .identifier("description"),
            .endOfScope(")"),
            .space(" "),
            .endOfScope("}"),
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

    func testIfdefPrefixDot() {
        let input = """
        foo
        #if bar
        .bar
        #else
        .baz
        #endif
        .quux
        """
        let output: [Token] = [
            .identifier("foo"),
            .linebreak("\n", 1),
            .startOfScope("#if"),
            .space(" "),
            .identifier("bar"),
            .linebreak("\n", 2),
            .operator(".", .infix),
            .identifier("bar"),
            .linebreak("\n", 3),
            .keyword("#else"),
            .linebreak("\n", 4),
            .operator(".", .infix),
            .identifier("baz"),
            .linebreak("\n", 5),
            .endOfScope("#endif"),
            .linebreak("\n", 6),
            .operator(".", .infix),
            .identifier("quux"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: linebreaks

    func testLF() {
        let input = "foo\nbar"
        let output: [Token] = [
            .identifier("foo"),
            .linebreak("\n", 1),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCR() {
        let input = "foo\rbar"
        let output: [Token] = [
            .identifier("foo"),
            .linebreak("\r", 1),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCRLF() {
        let input = "foo\r\nbar"
        let output: [Token] = [
            .identifier("foo"),
            .linebreak("\r\n", 1),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCRLFAfterComment() {
        let input = "//foo\r\n//bar"
        let output: [Token] = [
            .startOfScope("//"),
            .commentBody("foo"),
            .linebreak("\r\n", 1),
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
            .linebreak("\r\n", 1),
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

    // MARK: await

    func testAwaitExpression() {
        let input = "let foo = await bar()"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .keyword("await"),
            .space(" "),
            .identifier("bar"),
            .startOfScope("("),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testAwaitFunction() {
        let input = "func await()"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("await"),
            .startOfScope("("),
            .endOfScope(")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testAwaitClass() {
        let input = "class await {}"
        let output: [Token] = [
            .keyword("class"),
            .space(" "),
            .identifier("await"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testAwaitProperty() {
        let input = "let await = 5"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("await"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .number("5", .integer),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: actors

    func testActorType() {
        let input = "actor Foo {}"
        let output: [Token] = [
            .keyword("actor"),
            .space(" "),
            .identifier("Foo"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testActorProperty() {
        let input = "let actor = {}"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("actor"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testActorProperty2() {
        let input = "actor = 5"
        let output: [Token] = [
            .identifier("actor"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .number("5", .integer),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testActorProperty3() {
        let input = """
        self.actor = actor
        self.bar = bar
        """
        let output: [Token] = [
            .identifier("self"),
            .operator(".", .infix),
            .identifier("actor"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("actor"),
            .linebreak("\n", 1),
            .identifier("self"),
            .operator(".", .infix),
            .identifier("bar"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testActorLabel() {
        let input = "init(actor: Actor) {}"
        let output: [Token] = [
            .keyword("init"),
            .startOfScope("("),
            .identifier("actor"),
            .delimiter(":"),
            .space(" "),
            .identifier("Actor"),
            .endOfScope(")"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testActorVariable() {
        let input = "let foo = actor\nlet bar = foo"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("actor"),
            .linebreak("\n", 1),
            .keyword("let"),
            .space(" "),
            .identifier("bar"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("foo"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: some / any

    func testSomeView() {
        let input = "var body: some View {}"
        let output: [Token] = [
            .keyword("var"),
            .space(" "),
            .identifier("body"),
            .delimiter(":"),
            .space(" "),
            .identifier("some"),
            .space(" "),
            .identifier("View"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testAnyView() {
        let input = "var body: any View {}"
        let output: [Token] = [
            .keyword("var"),
            .space(" "),
            .identifier("body"),
            .delimiter(":"),
            .space(" "),
            .identifier("any"),
            .space(" "),
            .identifier("View"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSomeAnimal() {
        let input = "func feed(_ animal: some Animal) {}"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("feed"),
            .startOfScope("("),
            .identifier("_"),
            .space(" "),
            .identifier("animal"),
            .delimiter(":"),
            .space(" "),
            .identifier("some"),
            .space(" "),
            .identifier("Animal"),
            .endOfScope(")"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testAnyAnimal() {
        let input = "func feed(_ animal: any Animal) {}"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("feed"),
            .startOfScope("("),
            .identifier("_"),
            .space(" "),
            .identifier("animal"),
            .delimiter(":"),
            .space(" "),
            .identifier("any"),
            .space(" "),
            .identifier("Animal"),
            .endOfScope(")"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testAnyAnimalArray() {
        let input = "let animals: [any Animal]"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("animals"),
            .delimiter(":"),
            .space(" "),
            .startOfScope("["),
            .identifier("any"),
            .space(" "),
            .identifier("Animal"),
            .endOfScope("]"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }
}
