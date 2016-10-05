//
//  TokenizerTests.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 12/08/2016.
//  Copyright 2016 Charcoal Design
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/SwiftFormat
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

import XCTest
@testable import SwiftFormat

class TokenizerTests: XCTestCase {

    // MARK: Invalid input

    func testInvalidToken() {
        let input = "let `foo = bar"
        let output = [
            Token(.identifier, "let"),
            Token(.whitespace, " "),
            Token(.error, "`foo = bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnclosedBraces() {
        let input = "func foo() {"
        let output = [
            Token(.identifier, "func"),
            Token(.whitespace, " "),
            Token(.identifier, "foo"),
            Token(.startOfScope, "("),
            Token(.endOfScope, ")"),
            Token(.whitespace, " "),
            Token(.startOfScope, "{"),
            Token(.error, ""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnclosedSingleLineComment() {
        let input = "// comment"
        let output = [
            Token(.startOfScope, "//"),
            Token(.whitespace, " "),
            Token(.commentBody, "comment"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnclosedMultilineComment() {
        let input = "/* comment"
        let output = [
            Token(.startOfScope, "/*"),
            Token(.whitespace, " "),
            Token(.commentBody, "comment"),
            Token(.error, ""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnclosedString() {
        let input = "\"Hello World"
        let output = [
            Token(.startOfScope, "\""),
            Token(.stringBody, "Hello World"),
            Token(.error, ""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnbalancedScopes() {
        let input = "array.map({ return $0 )"
        let output = [
            Token(.identifier, "array"),
            Token(.symbol, "."),
            Token(.identifier, "map"),
            Token(.startOfScope, "("),
            Token(.startOfScope, "{"),
            Token(.whitespace, " "),
            Token(.identifier, "return"),
            Token(.whitespace, " "),
            Token(.identifier, "$0"),
            Token(.whitespace, " "),
            Token(.error, ")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Whitespace

    func testSpaces() {
        let input = "    "
        let output = [
            Token(.whitespace, "    "),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSpacesAndTabs() {
        let input = "  \t  \t"
        let output = [
            Token(.whitespace, "  \t  \t"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Strings

    func testEmptyString() {
        let input = "\"\""
        let output = [
            Token(.startOfScope, "\""),
            Token(.endOfScope, "\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSimpleString() {
        let input = "\"foo\""
        let output = [
            Token(.startOfScope, "\""),
            Token(.stringBody, "foo"),
            Token(.endOfScope, "\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testStringWithEscape() {
        let input = "\"hello\\tworld\""
        let output = [
            Token(.startOfScope, "\""),
            Token(.stringBody, "hello\\tworld"),
            Token(.endOfScope, "\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testStringWithEscapedQuotes() {
        let input = "\"\\\"nice\\\" to meet you\""
        let output = [
            Token(.startOfScope, "\""),
            Token(.stringBody, "\\\"nice\\\" to meet you"),
            Token(.endOfScope, "\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testStringWithEscapedLogic() {
        let input = "\"hello \\(name)\""
        let output = [
            Token(.startOfScope, "\""),
            Token(.stringBody, "hello \\"),
            Token(.startOfScope, "("),
            Token(.identifier, "name"),
            Token(.endOfScope, ")"),
            Token(.endOfScope, "\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testStringWithEscapedBackslash() {
        let input = "\"\\\\\""
        let output = [
            Token(.startOfScope, "\""),
            Token(.stringBody, "\\\\"),
            Token(.endOfScope, "\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Single-line comments

    func testSingleLineComment() {
        let input = "//foo"
        let output = [
            Token(.startOfScope, "//"),
            Token(.commentBody, "foo"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSingleLineCommentWithSpace() {
        let input = "// foo "
        let output = [
            Token(.startOfScope, "//"),
            Token(.whitespace, " "),
            Token(.commentBody, "foo"),
            Token(.whitespace, " "),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSingleLineCommentWithLinebreak() {
        let input = "//foo\nbar"
        let output = [
            Token(.startOfScope, "//"),
            Token(.commentBody, "foo"),
            Token(.linebreak, "\n"),
            Token(.identifier, "bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Multiline comments

    func testSingleLineMultilineComment() {
        let input = "/*foo*/"
        let output = [
            Token(.startOfScope, "/*"),
            Token(.commentBody, "foo"),
            Token(.endOfScope, "*/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSingleLineMultilineCommentWithSpace() {
        let input = "/* foo */"
        let output = [
            Token(.startOfScope, "/*"),
            Token(.whitespace, " "),
            Token(.commentBody, "foo"),
            Token(.whitespace, " "),
            Token(.endOfScope, "*/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testMultilineComment() {
        let input = "/*foo\nbar*/"
        let output = [
            Token(.startOfScope, "/*"),
            Token(.commentBody, "foo"),
            Token(.linebreak, "\n"),
            Token(.commentBody, "bar"),
            Token(.endOfScope, "*/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testMultilineCommentWithWhitespace() {
        let input = "/*foo\n  bar*/"
        let output = [
            Token(.startOfScope, "/*"),
            Token(.commentBody, "foo"),
            Token(.linebreak, "\n"),
            Token(.whitespace, "  "),
            Token(.commentBody, "bar"),
            Token(.endOfScope, "*/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNestedComments() {
        let input = "/*foo/*bar*/baz*/"
        let output = [
            Token(.startOfScope, "/*"),
            Token(.commentBody, "foo"),
            Token(.startOfScope, "/*"),
            Token(.commentBody, "bar"),
            Token(.endOfScope, "*/"),
            Token(.commentBody, "baz"),
            Token(.endOfScope, "*/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNestedCommentsWithWhitespace() {
        let input = "/* foo /* bar */ baz */"
        let output = [
            Token(.startOfScope, "/*"),
            Token(.whitespace, " "),
            Token(.commentBody, "foo"),
            Token(.whitespace, " "),
            Token(.startOfScope, "/*"),
            Token(.whitespace, " "),
            Token(.commentBody, "bar"),
            Token(.whitespace, " "),
            Token(.endOfScope, "*/"),
            Token(.whitespace, " "),
            Token(.commentBody, "baz"),
            Token(.whitespace, " "),
            Token(.endOfScope, "*/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Numbers

    func testZero() {
        let input = "0"
        let output = [Token(.number, "0")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSmallInteger() {
        let input = "5"
        let output = [Token(.number, "5")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testLargeInteger() {
        let input = "12345678901234567890"
        let output = [Token(.number, "12345678901234567890")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNegativeInteger() {
        let input = "-7"
        let output = [
            Token(.symbol, "-"),
            Token(.number, "7"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSmallFloat() {
        let input = "0.2"
        let output = [Token(.number, "0.2")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testLargeFloat() {
        let input = "1234.567890"
        let output = [Token(.number, "1234.567890")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNegativeFloat() {
        let input = "-0.34"
        let output = [
            Token(.symbol, "-"),
            Token(.number, "0.34"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testExponential() {
        let input = "1234e5"
        let output = [Token(.number, "1234e5")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testPositiveExponential() {
        let input = "0.123e+4"
        let output = [Token(.number, "0.123e+4")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNegativeExponential() {
        let input = "0.123e-4"
        let output = [Token(.number, "0.123e-4")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCapitalExponential() {
        let input = "0.123E-4"
        let output = [Token(.number, "0.123E-4")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testLeadingZeros() {
        let input = "0005"
        let output = [Token(.number, "0005")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testBinary() {
        let input = "0b101010"
        let output = [Token(.number, "0b101010")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testOctal() {
        let input = "0o52"
        let output = [Token(.number, "0o52")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testHex() {
        let input = "0x2A"
        let output = [Token(.number, "0x2A")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testHexadecimalPower() {
        let input = "0xC3p0"
        let output = [Token(.number, "0xC3p0")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnderscoresInInteger() {
        let input = "1_23_4_"
        let output = [Token(.number, "1_23_4_")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnderscoresInFloat() {
        let input = "0_.1_2_"
        let output = [Token(.number, "0_.1_2_")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnderscoresInExponential() {
        let input = "0.1_2_e-3"
        let output = [Token(.number, "0.1_2_e-3")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnderscoresInBinary() {
        let input = "0b0000_0000_0001"
        let output = [Token(.number, "0b0000_0000_0001")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnderscoresInOctal() {
        let input = "0o123_456"
        let output = [Token(.number, "0o123_456")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnderscoresInHex() {
        let input = "0xabc_def"
        let output = [Token(.number, "0xabc_def")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNoLeadingUnderscoreInInteger() {
        let input = "_12345"
        let output = [Token(.identifier, "_12345")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNoLeadingUnderscoreInHex() {
        let input = "0x_12345"
        let output = [Token(.error, "0x_12345")]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Identifiers

    func testFoo() {
        let input = "foo"
        let output = [Token(.identifier, "foo")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testDollar0() {
        let input = "$0"
        let output = [Token(.identifier, "$0")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testDollar() {
        // Note: support for this is deprecated in Swift 3
        let input = "$"
        let output = [Token(.identifier, "$")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testFooDollar() {
        let input = "foo$"
        let output = [Token(.identifier, "foo$")]
        XCTAssertEqual(tokenize(input), output)
    }

    func test_() {
        let input = "_"
        let output = [Token(.identifier, "_")]
        XCTAssertEqual(tokenize(input), output)
    }

    func test_foo() {
        let input = "_foo"
        let output = [Token(.identifier, "_foo")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testFoo_bar() {
        let input = "foo_bar"
        let output = [Token(.identifier, "foo_bar")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testAtFoo() {
        let input = "@foo"
        let output = [Token(.identifier, "@foo")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testHashFoo() {
        let input = "#foo"
        let output = [Token(.identifier, "#foo")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnicode() {
        let input = "µsec"
        let output = [Token(.identifier, "µsec")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testEmoji() {
        let input = "💩"
        let output = [Token(.identifier, "💩")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testBacktickEscapedClass() {
        let input = "`class`"
        let output = [Token(.identifier, "`class`")]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Operators

    func testBasicOperator() {
        let input = "+="
        let output = [Token(.symbol, "+=")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testDivide() {
        let input = "a / b"
        let output = [
            Token(.identifier, "a"),
            Token(.whitespace, " "),
            Token(.symbol, "/"),
            Token(.whitespace, " "),
            Token(.identifier, "b"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCustomOperator() {
        let input = "~="
        let output = [Token(.symbol, "~=")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSequentialOperators() {
        let input = "a *= -b"
        let output = [
            Token(.identifier, "a"),
            Token(.whitespace, " "),
            Token(.symbol, "*="),
            Token(.whitespace, " "),
            Token(.symbol, "-"),
            Token(.identifier, "b"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testDotPrefixedOperator() {
        let input = "..."
        let output = [Token(.symbol, "...")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnicodeOperator() {
        let input = "≥"
        let output = [Token(.symbol, "≥")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testOperatorFollowedByComment() {
        let input = "a +/* b */"
        let output = [
            Token(.identifier, "a"),
            Token(.whitespace, " "),
            Token(.symbol, "+"),
            Token(.startOfScope, "/*"),
            Token(.whitespace, " "),
            Token(.commentBody, "b"),
            Token(.whitespace, " "),
            Token(.endOfScope, "*/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testOperatorPrecededByComment() {
        let input = "/* a */-b"
        let output = [
            Token(.startOfScope, "/*"),
            Token(.whitespace, " "),
            Token(.commentBody, "a"),
            Token(.whitespace, " "),
            Token(.endOfScope, "*/"),
            Token(.symbol, "-"),
            Token(.identifier, "b"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testOperatorMayContainDotIfStartsWithDot() {
        let input = ".*.."
        let output = [Token(.symbol, ".*..")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testOperatorMayNotContainDotUnlessStartsWithDot() {
        let input = "*.."
        let output = [
            Token(.symbol, "*"),
            Token(.symbol, ".."),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: chevrons (might be operators or generics)

    func testLessThanGreaterThan() {
        let input = "a<b == a>c"
        let output = [
            Token(.identifier, "a"),
            Token(.symbol, "<"),
            Token(.identifier, "b"),
            Token(.whitespace, " "),
            Token(.symbol, "=="),
            Token(.whitespace, " "),
            Token(.identifier, "a"),
            Token(.symbol, ">"),
            Token(.identifier, "c"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testBitshift() {
        let input = "a>>b"
        let output = [
            Token(.identifier, "a"),
            Token(.symbol, ">>"),
            Token(.identifier, "b"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testTripleShift() {
        let input = "a>>>b"
        let output = [
            Token(.identifier, "a"),
            Token(.symbol, ">>>"),
            Token(.identifier, "b"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testTripleShiftEquals() {
        let input = "a>>=b"
        let output = [
            Token(.identifier, "a"),
            Token(.symbol, ">>="),
            Token(.identifier, "b"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testBitshiftThatLooksLikeAGeneric() {
        let input = "a<b, b<c, d>>e"
        let output = [
            Token(.identifier, "a"),
            Token(.symbol, "<"),
            Token(.identifier, "b"),
            Token(.symbol, ","),
            Token(.whitespace, " "),
            Token(.identifier, "b"),
            Token(.symbol, "<"),
            Token(.identifier, "c"),
            Token(.symbol, ","),
            Token(.whitespace, " "),
            Token(.identifier, "d"),
            Token(.symbol, ">>"),
            Token(.identifier, "e"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testBasicGeneric() {
        let input = "Foo<Bar, Baz>"
        let output = [
            Token(.identifier, "Foo"),
            Token(.startOfScope, "<"),
            Token(.identifier, "Bar"),
            Token(.symbol, ","),
            Token(.whitespace, " "),
            Token(.identifier, "Baz"),
            Token(.endOfScope, ">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNestedGenerics() {
        let input = "Foo<Bar<Baz>>"
        let output = [
            Token(.identifier, "Foo"),
            Token(.startOfScope, "<"),
            Token(.identifier, "Bar"),
            Token(.startOfScope, "<"),
            Token(.identifier, "Baz"),
            Token(.endOfScope, ">"),
            Token(.endOfScope, ">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testFunctionThatLooksLikeGenericType() {
        let input = "y<CGRectGetMaxY(r)"
        let output = [
            Token(.identifier, "y"),
            Token(.symbol, "<"),
            Token(.identifier, "CGRectGetMaxY"),
            Token(.startOfScope, "("),
            Token(.identifier, "r"),
            Token(.endOfScope, ")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericClassDeclaration() {
        let input = "class Foo<T,U> {}"
        let output = [
            Token(.identifier, "class"),
            Token(.whitespace, " "),
            Token(.identifier, "Foo"),
            Token(.startOfScope, "<"),
            Token(.identifier, "T"),
            Token(.symbol, ","),
            Token(.identifier, "U"),
            Token(.endOfScope, ">"),
            Token(.whitespace, " "),
            Token(.startOfScope, "{"),
            Token(.endOfScope, "}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericSubclassDeclaration() {
        let input = "class Foo<T,U>: Bar"
        let output = [
            Token(.identifier, "class"),
            Token(.whitespace, " "),
            Token(.identifier, "Foo"),
            Token(.startOfScope, "<"),
            Token(.identifier, "T"),
            Token(.symbol, ","),
            Token(.identifier, "U"),
            Token(.endOfScope, ">"),
            Token(.symbol, ":"),
            Token(.whitespace, " "),
            Token(.identifier, "Bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericFunctionDeclaration() {
        let input = "func foo<T>(bar:T)"
        let output = [
            Token(.identifier, "func"),
            Token(.whitespace, " "),
            Token(.identifier, "foo"),
            Token(.startOfScope, "<"),
            Token(.identifier, "T"),
            Token(.endOfScope, ">"),
            Token(.startOfScope, "("),
            Token(.identifier, "bar"),
            Token(.symbol, ":"),
            Token(.identifier, "T"),
            Token(.endOfScope, ")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericClassInit() {
        let input = "foo = Foo<Int,String>()"
        let output = [
            Token(.identifier, "foo"),
            Token(.whitespace, " "),
            Token(.symbol, "="),
            Token(.whitespace, " "),
            Token(.identifier, "Foo"),
            Token(.startOfScope, "<"),
            Token(.identifier, "Int"),
            Token(.symbol, ","),
            Token(.identifier, "String"),
            Token(.endOfScope, ">"),
            Token(.startOfScope, "("),
            Token(.endOfScope, ")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericFollowedByDot() {
        let input = "Foo<Bar>.baz()"
        let output = [
            Token(.identifier, "Foo"),
            Token(.startOfScope, "<"),
            Token(.identifier, "Bar"),
            Token(.endOfScope, ">"),
            Token(.symbol, "."),
            Token(.identifier, "baz"),
            Token(.startOfScope, "("),
            Token(.endOfScope, ")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testConstantThatLooksLikeGenericType() {
        let input = "(y<Pi)"
        let output = [
            Token(.startOfScope, "("),
            Token(.identifier, "y"),
            Token(.symbol, "<"),
            Token(.identifier, "Pi"),
            Token(.endOfScope, ")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testTupleOfBoolsThatLooksLikeGeneric() {
        let input = "(Foo<T,U>V)"
        let output = [
            Token(.startOfScope, "("),
            Token(.identifier, "Foo"),
            Token(.symbol, "<"),
            Token(.identifier, "T"),
            Token(.symbol, ","),
            Token(.identifier, "U"),
            Token(.symbol, ">"),
            Token(.identifier, "V"),
            Token(.endOfScope, ")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericClassInitThatLooksLikeTuple() {
        let input = "(Foo<String,Int>(Bar))"
        let output = [
            Token(.startOfScope, "("),
            Token(.identifier, "Foo"),
            Token(.startOfScope, "<"),
            Token(.identifier, "String"),
            Token(.symbol, ","),
            Token(.identifier, "Int"),
            Token(.endOfScope, ">"),
            Token(.startOfScope, "("),
            Token(.identifier, "Bar"),
            Token(.endOfScope, ")"),
            Token(.endOfScope, ")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCustomChevronOperatorThatLooksLikeGeneric() {
        let input = "Foo<Bar,Baz>>>5"
        let output = [
            Token(.identifier, "Foo"),
            Token(.symbol, "<"),
            Token(.identifier, "Bar"),
            Token(.symbol, ","),
            Token(.identifier, "Baz"),
            Token(.symbol, ">>>"),
            Token(.number, "5"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericAsFunctionType() {
        let input = "Foo<Bar,Baz>->Void"
        let output = [
            Token(.identifier, "Foo"),
            Token(.startOfScope, "<"),
            Token(.identifier, "Bar"),
            Token(.symbol, ","),
            Token(.identifier, "Baz"),
            Token(.endOfScope, ">"),
            Token(.symbol, "->"),
            Token(.identifier, "Void"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericContainingArrayType() {
        let input = "Foo<[Bar],Baz>"
        let output = [
            Token(.identifier, "Foo"),
            Token(.startOfScope, "<"),
            Token(.startOfScope, "["),
            Token(.identifier, "Bar"),
            Token(.endOfScope, "]"),
            Token(.symbol, ","),
            Token(.identifier, "Baz"),
            Token(.endOfScope, ">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericContainingTupleType() {
        let input = "Foo<(Bar,Baz)>"
        let output = [
            Token(.identifier, "Foo"),
            Token(.startOfScope, "<"),
            Token(.startOfScope, "("),
            Token(.identifier, "Bar"),
            Token(.symbol, ","),
            Token(.identifier, "Baz"),
            Token(.endOfScope, ")"),
            Token(.endOfScope, ">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericContainingArrayAndTupleType() {
        let input = "Foo<[Bar],(Baz)>"
        let output = [
            Token(.identifier, "Foo"),
            Token(.startOfScope, "<"),
            Token(.startOfScope, "["),
            Token(.identifier, "Bar"),
            Token(.endOfScope, "]"),
            Token(.symbol, ","),
            Token(.startOfScope, "("),
            Token(.identifier, "Baz"),
            Token(.endOfScope, ")"),
            Token(.endOfScope, ">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericFollowedByIn() {
        let input = "Foo<Bar,Baz> in"
        let output = [
            Token(.identifier, "Foo"),
            Token(.startOfScope, "<"),
            Token(.identifier, "Bar"),
            Token(.symbol, ","),
            Token(.identifier, "Baz"),
            Token(.endOfScope, ">"),
            Token(.whitespace, " "),
            Token(.identifier, "in"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testOptionalGenericType() {
        let input = "Foo<T?,U>"
        let output = [
            Token(.identifier, "Foo"),
            Token(.startOfScope, "<"),
            Token(.identifier, "T"),
            Token(.symbol, "?"),
            Token(.symbol, ","),
            Token(.identifier, "U"),
            Token(.endOfScope, ">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testTrailingOptionalGenericType() {
        let input = "Foo<T?>"
        let output = [
            Token(.identifier, "Foo"),
            Token(.startOfScope, "<"),
            Token(.identifier, "T"),
            Token(.symbol, "?"),
            Token(.endOfScope, ">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNestedOptionalGenericType() {
        let input = "Foo<Bar<T?>>"
        let output = [
            Token(.identifier, "Foo"),
            Token(.startOfScope, "<"),
            Token(.identifier, "Bar"),
            Token(.startOfScope, "<"),
            Token(.identifier, "T"),
            Token(.symbol, "?"),
            Token(.endOfScope, ">"),
            Token(.endOfScope, ">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCustomOperatorStartingWithOpenChevron() {
        let input = "foo<--bar"
        let output = [
            Token(.identifier, "foo"),
            Token(.symbol, "<--"),
            Token(.identifier, "bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCustomOperatorEndingWithCloseChevron() {
        let input = "foo-->bar"
        let output = [
            Token(.identifier, "foo"),
            Token(.symbol, "-->"),
            Token(.identifier, "bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGreaterThanLessThanOperator() {
        let input = "foo><bar"
        let output = [
            Token(.identifier, "foo"),
            Token(.symbol, "><"),
            Token(.identifier, "bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testLessThanGreaterThanOperator() {
        let input = "foo<>bar"
        let output = [
            Token(.identifier, "foo"),
            Token(.symbol, "<>"),
            Token(.identifier, "bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericFollowedByAssign() {
        let input = "let foo: Bar<Baz> = 5"
        let output = [
            Token(.identifier, "let"),
            Token(.whitespace, " "),
            Token(.identifier, "foo"),
            Token(.symbol, ":"),
            Token(.whitespace, " "),
            Token(.identifier, "Bar"),
            Token(.startOfScope, "<"),
            Token(.identifier, "Baz"),
            Token(.endOfScope, ">"),
            Token(.whitespace, " "),
            Token(.symbol, "="),
            Token(.whitespace, " "),
            Token(.number, "5"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericInFailableInit() {
        let input = "init?<T>()"
        let output = [
            Token(.identifier, "init"),
            Token(.symbol, "?"),
            Token(.startOfScope, "<"),
            Token(.identifier, "T"),
            Token(.endOfScope, ">"),
            Token(.startOfScope, "("),
            Token(.endOfScope, ")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testInfixQuestionMarkChevronOperator() {
        let input = "operator ?< {}"
        let output = [
            Token(.identifier, "operator"),
            Token(.whitespace, " "),
            Token(.symbol, "?<"),
            Token(.whitespace, " "),
            Token(.startOfScope, "{"),
            Token(.endOfScope, "}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSortAscending() {
        let input = "sort(by: <)"
        let output = [
            Token(.identifier, "sort"),
            Token(.startOfScope, "("),
            Token(.identifier, "by"),
            Token(.symbol, ":"),
            Token(.whitespace, " "),
            Token(.symbol, "<"),
            Token(.endOfScope, ")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSortDescending() {
        let input = "sort(by: >)"
        let output = [
            Token(.identifier, "sort"),
            Token(.startOfScope, "("),
            Token(.identifier, "by"),
            Token(.symbol, ":"),
            Token(.whitespace, " "),
            Token(.symbol, ">"),
            Token(.endOfScope, ")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: optionals

    func testAssignOptional() {
        let input = "Int?=nil"
        let output = [
            Token(.identifier, "Int"),
            Token(.symbol, "?"),
            Token(.symbol, "="),
            Token(.identifier, "nil"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testQuestionMarkEqualOperator() {
        let input = "foo ?= bar"
        let output = [
            Token(.identifier, "foo"),
            Token(.whitespace, " "),
            Token(.symbol, "?="),
            Token(.whitespace, " "),
            Token(.identifier, "bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: case statements

    func testSingleLineEnum() {
        let input = "enum Foo {case Bar, Baz}"
        let output = [
            Token(.identifier, "enum"),
            Token(.whitespace, " "),
            Token(.identifier, "Foo"),
            Token(.whitespace, " "),
            Token(.startOfScope, "{"),
            Token(.identifier, "case"),
            Token(.whitespace, " "),
            Token(.identifier, "Bar"),
            Token(.symbol, ","),
            Token(.whitespace, " "),
            Token(.identifier, "Baz"),
            Token(.endOfScope, "}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSingleLineGenericEnum() {
        let input = "enum Foo<T> {case Bar, Baz}"
        let output = [
            Token(.identifier, "enum"),
            Token(.whitespace, " "),
            Token(.identifier, "Foo"),
            Token(.startOfScope, "<"),
            Token(.identifier, "T"),
            Token(.endOfScope, ">"),
            Token(.whitespace, " "),
            Token(.startOfScope, "{"),
            Token(.identifier, "case"),
            Token(.whitespace, " "),
            Token(.identifier, "Bar"),
            Token(.symbol, ","),
            Token(.whitespace, " "),
            Token(.identifier, "Baz"),
            Token(.endOfScope, "}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testMultilineLineEnum() {
        let input = "enum Foo {\ncase Bar\ncase Baz\n}"
        let output = [
            Token(.identifier, "enum"),
            Token(.whitespace, " "),
            Token(.identifier, "Foo"),
            Token(.whitespace, " "),
            Token(.startOfScope, "{"),
            Token(.linebreak, "\n"),
            Token(.identifier, "case"),
            Token(.whitespace, " "),
            Token(.identifier, "Bar"),
            Token(.linebreak, "\n"),
            Token(.identifier, "case"),
            Token(.whitespace, " "),
            Token(.identifier, "Baz"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchStatement() {
        let input = "switch x {\ncase 1:\nbreak\ncase 2:\nbreak\ndefault:\nbreak\n}"
        let output = [
            Token(.identifier, "switch"),
            Token(.whitespace, " "),
            Token(.identifier, "x"),
            Token(.whitespace, " "),
            Token(.startOfScope, "{"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "case"),
            Token(.whitespace, " "),
            Token(.number, "1"),
            Token(.startOfScope, ":"),
            Token(.linebreak, "\n"),
            Token(.identifier, "break"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "case"),
            Token(.whitespace, " "),
            Token(.number, "2"),
            Token(.startOfScope, ":"),
            Token(.linebreak, "\n"),
            Token(.identifier, "break"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "default"),
            Token(.startOfScope, ":"),
            Token(.linebreak, "\n"),
            Token(.identifier, "break"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchCaseIsDictionaryStatement() {
        let input = "switch x {\ncase foo is [Key: Value]:\nbreak\ndefault:\nbreak\n}"
        let output = [
            Token(.identifier, "switch"),
            Token(.whitespace, " "),
            Token(.identifier, "x"),
            Token(.whitespace, " "),
            Token(.startOfScope, "{"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "case"),
            Token(.whitespace, " "),
            Token(.identifier, "foo"),
            Token(.whitespace, " "),
            Token(.identifier, "is"),
            Token(.whitespace, " "),
            Token(.startOfScope, "["),
            Token(.identifier, "Key"),
            Token(.symbol, ":"),
            Token(.whitespace, " "),
            Token(.identifier, "Value"),
            Token(.endOfScope, "]"),
            Token(.startOfScope, ":"),
            Token(.linebreak, "\n"),
            Token(.identifier, "break"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "default"),
            Token(.startOfScope, ":"),
            Token(.linebreak, "\n"),
            Token(.identifier, "break"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchCaseContainingCaseIdentifier() {
        let input = "switch x {\ncase 1:\nfoo.case\ndefault:\nbreak\n}"
        let output = [
            Token(.identifier, "switch"),
            Token(.whitespace, " "),
            Token(.identifier, "x"),
            Token(.whitespace, " "),
            Token(.startOfScope, "{"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "case"),
            Token(.whitespace, " "),
            Token(.number, "1"),
            Token(.startOfScope, ":"),
            Token(.linebreak, "\n"),
            Token(.identifier, "foo"),
            Token(.symbol, "."),
            Token(.identifier, "case"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "default"),
            Token(.startOfScope, ":"),
            Token(.linebreak, "\n"),
            Token(.identifier, "break"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchCaseContainingDefaultIdentifier() {
        let input = "switch x {\ncase 1:\nfoo.default\ndefault:\nbreak\n}"
        let output = [
            Token(.identifier, "switch"),
            Token(.whitespace, " "),
            Token(.identifier, "x"),
            Token(.whitespace, " "),
            Token(.startOfScope, "{"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "case"),
            Token(.whitespace, " "),
            Token(.number, "1"),
            Token(.startOfScope, ":"),
            Token(.linebreak, "\n"),
            Token(.identifier, "foo"),
            Token(.symbol, "."),
            Token(.identifier, "default"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "default"),
            Token(.startOfScope, ":"),
            Token(.linebreak, "\n"),
            Token(.identifier, "break"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchCaseContainingIfCase() {
        let input = "switch x {\ncase 1:\nif case x = y {}\ndefault:\nbreak\n}"
        let output = [
            Token(.identifier, "switch"),
            Token(.whitespace, " "),
            Token(.identifier, "x"),
            Token(.whitespace, " "),
            Token(.startOfScope, "{"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "case"),
            Token(.whitespace, " "),
            Token(.number, "1"),
            Token(.startOfScope, ":"),
            Token(.linebreak, "\n"),
            Token(.identifier, "if"),
            Token(.whitespace, " "),
            Token(.identifier, "case"),
            Token(.whitespace, " "),
            Token(.identifier, "x"),
            Token(.whitespace, " "),
            Token(.symbol, "="),
            Token(.whitespace, " "),
            Token(.identifier, "y"),
            Token(.whitespace, " "),
            Token(.startOfScope, "{"),
            Token(.endOfScope, "}"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "default"),
            Token(.startOfScope, ":"),
            Token(.linebreak, "\n"),
            Token(.identifier, "break"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchCaseContainingGuardCase() {
        let input = "switch x {\ncase 1:\nguard case x = y else {}\ndefault:\nbreak\n}"
        let output = [
            Token(.identifier, "switch"),
            Token(.whitespace, " "),
            Token(.identifier, "x"),
            Token(.whitespace, " "),
            Token(.startOfScope, "{"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "case"),
            Token(.whitespace, " "),
            Token(.number, "1"),
            Token(.startOfScope, ":"),
            Token(.linebreak, "\n"),
            Token(.identifier, "guard"),
            Token(.whitespace, " "),
            Token(.identifier, "case"),
            Token(.whitespace, " "),
            Token(.identifier, "x"),
            Token(.whitespace, " "),
            Token(.symbol, "="),
            Token(.whitespace, " "),
            Token(.identifier, "y"),
            Token(.whitespace, " "),
            Token(.identifier, "else"),
            Token(.whitespace, " "),
            Token(.startOfScope, "{"),
            Token(.endOfScope, "}"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "default"),
            Token(.startOfScope, ":"),
            Token(.linebreak, "\n"),
            Token(.identifier, "break"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchFollowedByEnum() {
        let input = "switch x {\ncase y: break\ndefault: break\n}\nenum Foo {\ncase z\n}"
        let output = [
            Token(.identifier, "switch"),
            Token(.whitespace, " "),
            Token(.identifier, "x"),
            Token(.whitespace, " "),
            Token(.startOfScope, "{"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "case"),
            Token(.whitespace, " "),
            Token(.identifier, "y"),
            Token(.startOfScope, ":"),
            Token(.whitespace, " "),
            Token(.identifier, "break"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "default"),
            Token(.startOfScope, ":"),
            Token(.whitespace, " "),
            Token(.identifier, "break"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "}"),
            Token(.linebreak, "\n"),
            Token(.identifier, "enum"),
            Token(.whitespace, " "),
            Token(.identifier, "Foo"),
            Token(.whitespace, " "),
            Token(.startOfScope, "{"),
            Token(.linebreak, "\n"),
            Token(.identifier, "case"),
            Token(.whitespace, " "),
            Token(.identifier, "z"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchCaseContainingSwitchIdentifierFollowedByEnum() {
        let input = "switch x {\ncase 1:\nfoo.switch\ndefault:\nbreak\n}\nenum Foo {\ncase z\n}"
        let output = [
            Token(.identifier, "switch"),
            Token(.whitespace, " "),
            Token(.identifier, "x"),
            Token(.whitespace, " "),
            Token(.startOfScope, "{"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "case"),
            Token(.whitespace, " "),
            Token(.number, "1"),
            Token(.startOfScope, ":"),
            Token(.linebreak, "\n"),
            Token(.identifier, "foo"),
            Token(.symbol, "."),
            Token(.identifier, "switch"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "default"),
            Token(.startOfScope, ":"),
            Token(.linebreak, "\n"),
            Token(.identifier, "break"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "}"),
            Token(.linebreak, "\n"),
            Token(.identifier, "enum"),
            Token(.whitespace, " "),
            Token(.identifier, "Foo"),
            Token(.whitespace, " "),
            Token(.startOfScope, "{"),
            Token(.linebreak, "\n"),
            Token(.identifier, "case"),
            Token(.whitespace, " "),
            Token(.identifier, "z"),
            Token(.linebreak, "\n"),
            Token(.endOfScope, "}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: linebreaks

    func testLF() {
        let input = "foo\nbar"
        let output = [
            Token(.identifier, "foo"),
            Token(.linebreak, "\n"),
            Token(.identifier, "bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCR() {
        let input = "foo\rbar"
        let output = [
            Token(.identifier, "foo"),
            Token(.linebreak, "\r"),
            Token(.identifier, "bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCRLF() {
        let input = "foo\r\nbar"
        let output = [
            Token(.identifier, "foo"),
            Token(.linebreak, "\r\n"),
            Token(.identifier, "bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCRLFAfterComment() {
        let input = "//foo\r\n//bar"
        let output = [
            Token(.startOfScope, "//"),
            Token(.commentBody, "foo"),
            Token(.linebreak, "\r\n"),
            Token(.startOfScope, "//"),
            Token(.commentBody, "bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCRLFInMultilineComment() {
        let input = "/*foo\r\nbar*/"
        let output = [
            Token(.startOfScope, "/*"),
            Token(.commentBody, "foo"),
            Token(.linebreak, "\r\n"),
            Token(.commentBody, "bar"),
            Token(.endOfScope, "*/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }
}
