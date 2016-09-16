//
//  TokenizerTests.swift
//  SwiftFormat
//
//  Version 0.9.5
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
            Token(.Identifier, "let"),
            Token(.Whitespace, " "),
            Token(.Error, "`foo = bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnclosedBraces() {
        let input = "func foo() {"
        let output = [
            Token(.Identifier, "func"),
            Token(.Whitespace, " "),
            Token(.Identifier, "foo"),
            Token(.StartOfScope, "("),
            Token(.EndOfScope, ")"),
            Token(.Whitespace, " "),
            Token(.StartOfScope, "{"),
            Token(.Error, ""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnclosedSingleLineComment() {
        let input = "// comment"
        let output = [
            Token(.StartOfScope, "//"),
            Token(.Whitespace, " "),
            Token(.CommentBody, "comment"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnclosedMultilineComment() {
        let input = "/* comment"
        let output = [
            Token(.StartOfScope, "/*"),
            Token(.Whitespace, " "),
            Token(.CommentBody, "comment"),
            Token(.Error, ""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnclosedString() {
        let input = "\"Hello World"
        let output = [
            Token(.StartOfScope, "\""),
            Token(.StringBody, "Hello World"),
            Token(.Error, ""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnbalancedScopes() {
        let input = "array.map({ return $0 )"
        let output = [
            Token(.Identifier, "array"),
            Token(.Operator, "."),
            Token(.Identifier, "map"),
            Token(.StartOfScope, "("),
            Token(.StartOfScope, "{"),
            Token(.Whitespace, " "),
            Token(.Identifier, "return"),
            Token(.Whitespace, " "),
            Token(.Identifier, "$0"),
            Token(.Whitespace, " "),
            Token(.Error, ")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Whitespace

    func testSpaces() {
        let input = "    "
        let output = [
            Token(.Whitespace, "    "),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSpacesAndTabs() {
        let input = "  \t  \t"
        let output = [
            Token(.Whitespace, "  \t  \t"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Strings

    func testEmptyString() {
        let input = "\"\""
        let output = [
            Token(.StartOfScope, "\""),
            Token(.EndOfScope, "\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSimpleString() {
        let input = "\"foo\""
        let output = [
            Token(.StartOfScope, "\""),
            Token(.StringBody, "foo"),
            Token(.EndOfScope, "\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testStringWithEscape() {
        let input = "\"hello\\tworld\""
        let output = [
            Token(.StartOfScope, "\""),
            Token(.StringBody, "hello\\tworld"),
            Token(.EndOfScope, "\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testStringWithEscapedQuotes() {
        let input = "\"\\\"nice\\\" to meet you\""
        let output = [
            Token(.StartOfScope, "\""),
            Token(.StringBody, "\\\"nice\\\" to meet you"),
            Token(.EndOfScope, "\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testStringWithEscapedLogic() {
        let input = "\"hello \\(name)\""
        let output = [
            Token(.StartOfScope, "\""),
            Token(.StringBody, "hello \\"),
            Token(.StartOfScope, "("),
            Token(.Identifier, "name"),
            Token(.EndOfScope, ")"),
            Token(.EndOfScope, "\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testStringWithEscapedBackslash() {
        let input = "\"\\\\\""
        let output = [
            Token(.StartOfScope, "\""),
            Token(.StringBody, "\\\\"),
            Token(.EndOfScope, "\""),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Single-line comments

    func testSingleLineComment() {
        let input = "//foo"
        let output = [
            Token(.StartOfScope, "//"),
            Token(.CommentBody, "foo"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSingleLineCommentWithSpace() {
        let input = "// foo "
        let output = [
            Token(.StartOfScope, "//"),
            Token(.Whitespace, " "),
            Token(.CommentBody, "foo"),
            Token(.Whitespace, " "),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSingleLineCommentWithLinebreak() {
        let input = "//foo\nbar"
        let output = [
            Token(.StartOfScope, "//"),
            Token(.CommentBody, "foo"),
            Token(.Linebreak, "\n"),
            Token(.Identifier, "bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Multiline comments

    func testSingleLineMultilineComment() {
        let input = "/*foo*/"
        let output = [
            Token(.StartOfScope, "/*"),
            Token(.CommentBody, "foo"),
            Token(.EndOfScope, "*/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSingleLineMultilineCommentWithSpace() {
        let input = "/* foo */"
        let output = [
            Token(.StartOfScope, "/*"),
            Token(.Whitespace, " "),
            Token(.CommentBody, "foo"),
            Token(.Whitespace, " "),
            Token(.EndOfScope, "*/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testMultilineComment() {
        let input = "/*foo\nbar*/"
        let output = [
            Token(.StartOfScope, "/*"),
            Token(.CommentBody, "foo"),
            Token(.Linebreak, "\n"),
            Token(.CommentBody, "bar"),
            Token(.EndOfScope, "*/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testMultilineCommentWithWhitespace() {
        let input = "/*foo\n  bar*/"
        let output = [
            Token(.StartOfScope, "/*"),
            Token(.CommentBody, "foo"),
            Token(.Linebreak, "\n"),
            Token(.Whitespace, "  "),
            Token(.CommentBody, "bar"),
            Token(.EndOfScope, "*/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNestedComments() {
        let input = "/*foo/*bar*/baz*/"
        let output = [
            Token(.StartOfScope, "/*"),
            Token(.CommentBody, "foo"),
            Token(.StartOfScope, "/*"),
            Token(.CommentBody, "bar"),
            Token(.EndOfScope, "*/"),
            Token(.CommentBody, "baz"),
            Token(.EndOfScope, "*/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNestedCommentsWithWhitespace() {
        let input = "/* foo /* bar */ baz */"
        let output = [
            Token(.StartOfScope, "/*"),
            Token(.Whitespace, " "),
            Token(.CommentBody, "foo"),
            Token(.Whitespace, " "),
            Token(.StartOfScope, "/*"),
            Token(.Whitespace, " "),
            Token(.CommentBody, "bar"),
            Token(.Whitespace, " "),
            Token(.EndOfScope, "*/"),
            Token(.Whitespace, " "),
            Token(.CommentBody, "baz"),
            Token(.Whitespace, " "),
            Token(.EndOfScope, "*/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Numbers

    func testZero() {
        let input = "0"
        let output = [Token(.Number, "0")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSmallInteger() {
        let input = "5"
        let output = [Token(.Number, "5")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testLargeInteger() {
        let input = "12345678901234567890"
        let output = [Token(.Number, "12345678901234567890")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNegativeInteger() {
        let input = "-7"
        let output = [
            Token(.Operator, "-"),
            Token(.Number, "7"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSmallFloat() {
        let input = "0.2"
        let output = [Token(.Number, "0.2")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testLargeFloat() {
        let input = "1234.567890"
        let output = [Token(.Number, "1234.567890")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNegativeFloat() {
        let input = "-0.34"
        let output = [
            Token(.Operator, "-"),
            Token(.Number, "0.34"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testExponential() {
        let input = "1234e5"
        let output = [Token(.Number, "1234e5")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testPositiveExponential() {
        let input = "0.123e+4"
        let output = [Token(.Number, "0.123e+4")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNegativeExponential() {
        let input = "0.123e-4"
        let output = [Token(.Number, "0.123e-4")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCapitalExponential() {
        let input = "0.123E-4"
        let output = [Token(.Number, "0.123E-4")]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Identifiers

    func testFoo() {
        let input = "foo"
        let output = [Token(.Identifier, "foo")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testDollar0() {
        let input = "$0"
        let output = [Token(.Identifier, "$0")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testDollar() {
        // Note: support for this is deprecated in Swift 3
        let input = "$"
        let output = [Token(.Identifier, "$")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testFooDollar() {
        let input = "foo$"
        let output = [Token(.Identifier, "foo$")]
        XCTAssertEqual(tokenize(input), output)
    }

    func test_() {
        let input = "_"
        let output = [Token(.Identifier, "_")]
        XCTAssertEqual(tokenize(input), output)
    }

    func test_foo() {
        let input = "_foo"
        let output = [Token(.Identifier, "_foo")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testFoo_bar() {
        let input = "foo_bar"
        let output = [Token(.Identifier, "foo_bar")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testAtFoo() {
        let input = "@foo"
        let output = [Token(.Identifier, "@foo")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testHashFoo() {
        let input = "#foo"
        let output = [Token(.Identifier, "#foo")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnicode() {
        let input = "µsec"
        let output = [Token(.Identifier, "µsec")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testEmoji() {
        let input = "💩"
        let output = [Token(.Identifier, "💩")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testBacktickEscapedClass() {
        let input = "`class`"
        let output = [Token(.Identifier, "`class`")]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: Operators

    func testBasicOperator() {
        let input = "+="
        let output = [Token(.Operator, "+=")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testDivide() {
        let input = "a / b"
        let output = [
            Token(.Identifier, "a"),
            Token(.Whitespace, " "),
            Token(.Operator, "/"),
            Token(.Whitespace, " "),
            Token(.Identifier, "b"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCustomOperator() {
        let input = "~="
        let output = [Token(.Operator, "~=")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSequentialOperators() {
        let input = "a *= -b"
        let output = [
            Token(.Identifier, "a"),
            Token(.Whitespace, " "),
            Token(.Operator, "*="),
            Token(.Whitespace, " "),
            Token(.Operator, "-"),
            Token(.Identifier, "b"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testDotPrefixedOperator() {
        let input = "..."
        let output = [Token(.Operator, "...")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testUnicodeOperator() {
        let input = "≥"
        let output = [Token(.Operator, "≥")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testOperatorFollowedByComment() {
        let input = "a +/* b */"
        let output = [
            Token(.Identifier, "a"),
            Token(.Whitespace, " "),
            Token(.Operator, "+"),
            Token(.StartOfScope, "/*"),
            Token(.Whitespace, " "),
            Token(.CommentBody, "b"),
            Token(.Whitespace, " "),
            Token(.EndOfScope, "*/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testOperatorPrecededByComment() {
        let input = "/* a */-b"
        let output = [
            Token(.StartOfScope, "/*"),
            Token(.Whitespace, " "),
            Token(.CommentBody, "a"),
            Token(.Whitespace, " "),
            Token(.EndOfScope, "*/"),
            Token(.Operator, "-"),
            Token(.Identifier, "b"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testOperatorMayContainDotIfStartsWithDot() {
        let input = ".*.."
        let output = [Token(.Operator, ".*..")]
        XCTAssertEqual(tokenize(input), output)
    }

    func testOperatorMayNotContainDotUnlessStartsWithDot() {
        let input = "*.."
        let output = [
            Token(.Operator, "*"),
            Token(.Operator, ".."),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: chevrons (might be operators or generics)

    func testLessThanGreaterThan() {
        let input = "a<b == a>c"
        let output = [
            Token(.Identifier, "a"),
            Token(.Operator, "<"),
            Token(.Identifier, "b"),
            Token(.Whitespace, " "),
            Token(.Operator, "=="),
            Token(.Whitespace, " "),
            Token(.Identifier, "a"),
            Token(.Operator, ">"),
            Token(.Identifier, "c"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testBitshift() {
        let input = "a>>b"
        let output = [
            Token(.Identifier, "a"),
            Token(.Operator, ">>"),
            Token(.Identifier, "b"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testTripleShift() {
        let input = "a>>>b"
        let output = [
            Token(.Identifier, "a"),
            Token(.Operator, ">>>"),
            Token(.Identifier, "b"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testTripleShiftEquals() {
        let input = "a>>=b"
        let output = [
            Token(.Identifier, "a"),
            Token(.Operator, ">>="),
            Token(.Identifier, "b"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testBitshiftThatLooksLikeAGeneric() {
        let input = "a<b, b<c, d>>e"
        let output = [
            Token(.Identifier, "a"),
            Token(.Operator, "<"),
            Token(.Identifier, "b"),
            Token(.Operator, ","),
            Token(.Whitespace, " "),
            Token(.Identifier, "b"),
            Token(.Operator, "<"),
            Token(.Identifier, "c"),
            Token(.Operator, ","),
            Token(.Whitespace, " "),
            Token(.Identifier, "d"),
            Token(.Operator, ">>"),
            Token(.Identifier, "e"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testBasicGeneric() {
        let input = "Foo<Bar, Baz>"
        let output = [
            Token(.Identifier, "Foo"),
            Token(.StartOfScope, "<"),
            Token(.Identifier, "Bar"),
            Token(.Operator, ","),
            Token(.Whitespace, " "),
            Token(.Identifier, "Baz"),
            Token(.EndOfScope, ">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNestedGenerics() {
        let input = "Foo<Bar<Baz>>"
        let output = [
            Token(.Identifier, "Foo"),
            Token(.StartOfScope, "<"),
            Token(.Identifier, "Bar"),
            Token(.StartOfScope, "<"),
            Token(.Identifier, "Baz"),
            Token(.EndOfScope, ">"),
            Token(.EndOfScope, ">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testFunctionThatLooksLikeGenericType() {
        let input = "y<CGRectGetMaxY(r)"
        let output = [
            Token(.Identifier, "y"),
            Token(.Operator, "<"),
            Token(.Identifier, "CGRectGetMaxY"),
            Token(.StartOfScope, "("),
            Token(.Identifier, "r"),
            Token(.EndOfScope, ")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericClassDeclaration() {
        let input = "class Foo<T,U> {}"
        let output = [
            Token(.Identifier, "class"),
            Token(.Whitespace, " "),
            Token(.Identifier, "Foo"),
            Token(.StartOfScope, "<"),
            Token(.Identifier, "T"),
            Token(.Operator, ","),
            Token(.Identifier, "U"),
            Token(.EndOfScope, ">"),
            Token(.Whitespace, " "),
            Token(.StartOfScope, "{"),
            Token(.EndOfScope, "}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericSubclassDeclaration() {
        let input = "class Foo<T,U>: Bar"
        let output = [
            Token(.Identifier, "class"),
            Token(.Whitespace, " "),
            Token(.Identifier, "Foo"),
            Token(.StartOfScope, "<"),
            Token(.Identifier, "T"),
            Token(.Operator, ","),
            Token(.Identifier, "U"),
            Token(.EndOfScope, ">"),
            Token(.Operator, ":"),
            Token(.Whitespace, " "),
            Token(.Identifier, "Bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericFunctionDeclaration() {
        let input = "func foo<T>(bar:T)"
        let output = [
            Token(.Identifier, "func"),
            Token(.Whitespace, " "),
            Token(.Identifier, "foo"),
            Token(.StartOfScope, "<"),
            Token(.Identifier, "T"),
            Token(.EndOfScope, ">"),
            Token(.StartOfScope, "("),
            Token(.Identifier, "bar"),
            Token(.Operator, ":"),
            Token(.Identifier, "T"),
            Token(.EndOfScope, ")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericClassInit() {
        let input = "foo = Foo<Int,String>()"
        let output = [
            Token(.Identifier, "foo"),
            Token(.Whitespace, " "),
            Token(.Operator, "="),
            Token(.Whitespace, " "),
            Token(.Identifier, "Foo"),
            Token(.StartOfScope, "<"),
            Token(.Identifier, "Int"),
            Token(.Operator, ","),
            Token(.Identifier, "String"),
            Token(.EndOfScope, ">"),
            Token(.StartOfScope, "("),
            Token(.EndOfScope, ")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericFollowedByDot() {
        let input = "Foo<Bar>.baz()"
        let output = [
            Token(.Identifier, "Foo"),
            Token(.StartOfScope, "<"),
            Token(.Identifier, "Bar"),
            Token(.EndOfScope, ">"),
            Token(.Operator, "."),
            Token(.Identifier, "baz"),
            Token(.StartOfScope, "("),
            Token(.EndOfScope, ")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testConstantThatLooksLikeGenericType() {
        let input = "(y<Pi)"
        let output = [
            Token(.StartOfScope, "("),
            Token(.Identifier, "y"),
            Token(.Operator, "<"),
            Token(.Identifier, "Pi"),
            Token(.EndOfScope, ")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testTupleOfBoolsThatLooksLikeGeneric() {
        let input = "(Foo<T,U>V)"
        let output = [
            Token(.StartOfScope, "("),
            Token(.Identifier, "Foo"),
            Token(.Operator, "<"),
            Token(.Identifier, "T"),
            Token(.Operator, ","),
            Token(.Identifier, "U"),
            Token(.Operator, ">"),
            Token(.Identifier, "V"),
            Token(.EndOfScope, ")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericClassInitThatLooksLikeTuple() {
        let input = "(Foo<String,Int>(Bar))"
        let output = [
            Token(.StartOfScope, "("),
            Token(.Identifier, "Foo"),
            Token(.StartOfScope, "<"),
            Token(.Identifier, "String"),
            Token(.Operator, ","),
            Token(.Identifier, "Int"),
            Token(.EndOfScope, ">"),
            Token(.StartOfScope, "("),
            Token(.Identifier, "Bar"),
            Token(.EndOfScope, ")"),
            Token(.EndOfScope, ")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCustomChevronOperatorThatLooksLikeGeneric() {
        let input = "Foo<Bar,Baz>>>5"
        let output = [
            Token(.Identifier, "Foo"),
            Token(.Operator, "<"),
            Token(.Identifier, "Bar"),
            Token(.Operator, ","),
            Token(.Identifier, "Baz"),
            Token(.Operator, ">>>"),
            Token(.Number, "5"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericAsFunctionType() {
        let input = "Foo<Bar,Baz>->Void"
        let output = [
            Token(.Identifier, "Foo"),
            Token(.StartOfScope, "<"),
            Token(.Identifier, "Bar"),
            Token(.Operator, ","),
            Token(.Identifier, "Baz"),
            Token(.EndOfScope, ">"),
            Token(.Operator, "->"),
            Token(.Identifier, "Void"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericContainingArrayType() {
        let input = "Foo<[Bar],Baz>"
        let output = [
            Token(.Identifier, "Foo"),
            Token(.StartOfScope, "<"),
            Token(.StartOfScope, "["),
            Token(.Identifier, "Bar"),
            Token(.EndOfScope, "]"),
            Token(.Operator, ","),
            Token(.Identifier, "Baz"),
            Token(.EndOfScope, ">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericContainingTupleType() {
        let input = "Foo<(Bar,Baz)>"
        let output = [
            Token(.Identifier, "Foo"),
            Token(.StartOfScope, "<"),
            Token(.StartOfScope, "("),
            Token(.Identifier, "Bar"),
            Token(.Operator, ","),
            Token(.Identifier, "Baz"),
            Token(.EndOfScope, ")"),
            Token(.EndOfScope, ">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericContainingArrayAndTupleType() {
        let input = "Foo<[Bar],(Baz)>"
        let output = [
            Token(.Identifier, "Foo"),
            Token(.StartOfScope, "<"),
            Token(.StartOfScope, "["),
            Token(.Identifier, "Bar"),
            Token(.EndOfScope, "]"),
            Token(.Operator, ","),
            Token(.StartOfScope, "("),
            Token(.Identifier, "Baz"),
            Token(.EndOfScope, ")"),
            Token(.EndOfScope, ">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericFollowedByIn() {
        let input = "Foo<Bar,Baz> in"
        let output = [
            Token(.Identifier, "Foo"),
            Token(.StartOfScope, "<"),
            Token(.Identifier, "Bar"),
            Token(.Operator, ","),
            Token(.Identifier, "Baz"),
            Token(.EndOfScope, ">"),
            Token(.Whitespace, " "),
            Token(.Identifier, "in"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testOptionalGenericType() {
        let input = "Foo<T?,U>"
        let output = [
            Token(.Identifier, "Foo"),
            Token(.StartOfScope, "<"),
            Token(.Identifier, "T"),
            Token(.Operator, "?"),
            Token(.Operator, ","),
            Token(.Identifier, "U"),
            Token(.EndOfScope, ">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testTrailingOptionalGenericType() {
        let input = "Foo<T?>"
        let output = [
            Token(.Identifier, "Foo"),
            Token(.StartOfScope, "<"),
            Token(.Identifier, "T"),
            Token(.Operator, "?"),
            Token(.EndOfScope, ">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testNestedOptionalGenericType() {
        let input = "Foo<Bar<T?>>"
        let output = [
            Token(.Identifier, "Foo"),
            Token(.StartOfScope, "<"),
            Token(.Identifier, "Bar"),
            Token(.StartOfScope, "<"),
            Token(.Identifier, "T"),
            Token(.Operator, "?"),
            Token(.EndOfScope, ">"),
            Token(.EndOfScope, ">"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCustomOperatorStartingWithOpenChevron() {
        let input = "foo<--bar"
        let output = [
            Token(.Identifier, "foo"),
            Token(.Operator, "<--"),
            Token(.Identifier, "bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCustomOperatorEndingWithCloseChevron() {
        let input = "foo-->bar"
        let output = [
            Token(.Identifier, "foo"),
            Token(.Operator, "-->"),
            Token(.Identifier, "bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGreaterThanLessThanOperator() {
        let input = "foo><bar"
        let output = [
            Token(.Identifier, "foo"),
            Token(.Operator, "><"),
            Token(.Identifier, "bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testLessThanGreaterThanOperator() {
        let input = "foo<>bar"
        let output = [
            Token(.Identifier, "foo"),
            Token(.Operator, "<>"),
            Token(.Identifier, "bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericFollowedByAssign() {
        let input = "let foo: Bar<Baz> = 5"
        let output = [
            Token(.Identifier, "let"),
            Token(.Whitespace, " "),
            Token(.Identifier, "foo"),
            Token(.Operator, ":"),
            Token(.Whitespace, " "),
            Token(.Identifier, "Bar"),
            Token(.StartOfScope, "<"),
            Token(.Identifier, "Baz"),
            Token(.EndOfScope, ">"),
            Token(.Whitespace, " "),
            Token(.Operator, "="),
            Token(.Whitespace, " "),
            Token(.Number, "5"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testGenericInFailableInit() {
        let input = "init?<T>()"
        let output = [
            Token(.Identifier, "init"),
            Token(.Operator, "?"),
            Token(.StartOfScope, "<"),
            Token(.Identifier, "T"),
            Token(.EndOfScope, ">"),
            Token(.StartOfScope, "("),
            Token(.EndOfScope, ")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testInfixQuestionMarkChevronOperator() {
        let input = "operator ?< {}"
        let output = [
            Token(.Identifier, "operator"),
            Token(.Whitespace, " "),
            Token(.Operator, "?<"),
            Token(.Whitespace, " "),
            Token(.StartOfScope, "{"),
            Token(.EndOfScope, "}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSortAscending() {
        let input = "sort(by: <)"
        let output = [
            Token(.Identifier, "sort"),
            Token(.StartOfScope, "("),
            Token(.Identifier, "by"),
            Token(.Operator, ":"),
            Token(.Whitespace, " "),
            Token(.Operator, "<"),
            Token(.EndOfScope, ")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSortDescending() {
        let input = "sort(by: >)"
        let output = [
            Token(.Identifier, "sort"),
            Token(.StartOfScope, "("),
            Token(.Identifier, "by"),
            Token(.Operator, ":"),
            Token(.Whitespace, " "),
            Token(.Operator, ">"),
            Token(.EndOfScope, ")"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: case statements

    func testSingleLineEnum() {
        let input = "enum Foo {case Bar, Baz}"
        let output = [
            Token(.Identifier, "enum"),
            Token(.Whitespace, " "),
            Token(.Identifier, "Foo"),
            Token(.Whitespace, " "),
            Token(.StartOfScope, "{"),
            Token(.Identifier, "case"),
            Token(.Whitespace, " "),
            Token(.Identifier, "Bar"),
            Token(.Operator, ","),
            Token(.Whitespace, " "),
            Token(.Identifier, "Baz"),
            Token(.EndOfScope, "}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSingleLineGenericEnum() {
        let input = "enum Foo<T> {case Bar, Baz}"
        let output = [
            Token(.Identifier, "enum"),
            Token(.Whitespace, " "),
            Token(.Identifier, "Foo"),
            Token(.StartOfScope, "<"),
            Token(.Identifier, "T"),
            Token(.EndOfScope, ">"),
            Token(.Whitespace, " "),
            Token(.StartOfScope, "{"),
            Token(.Identifier, "case"),
            Token(.Whitespace, " "),
            Token(.Identifier, "Bar"),
            Token(.Operator, ","),
            Token(.Whitespace, " "),
            Token(.Identifier, "Baz"),
            Token(.EndOfScope, "}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testMultilineLineEnum() {
        let input = "enum Foo {\ncase Bar\ncase Baz\n}"
        let output = [
            Token(.Identifier, "enum"),
            Token(.Whitespace, " "),
            Token(.Identifier, "Foo"),
            Token(.Whitespace, " "),
            Token(.StartOfScope, "{"),
            Token(.Linebreak, "\n"),
            Token(.Identifier, "case"),
            Token(.Whitespace, " "),
            Token(.Identifier, "Bar"),
            Token(.Linebreak, "\n"),
            Token(.Identifier, "case"),
            Token(.Whitespace, " "),
            Token(.Identifier, "Baz"),
            Token(.Linebreak, "\n"),
            Token(.EndOfScope, "}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchStatement() {
        let input = "switch x {\ncase 1:\nbreak\ncase 2:\nbreak\ndefault:\nbreak\n}"
        let output = [
            Token(.Identifier, "switch"),
            Token(.Whitespace, " "),
            Token(.Identifier, "x"),
            Token(.Whitespace, " "),
            Token(.StartOfScope, "{"),
            Token(.Linebreak, "\n"),
            Token(.EndOfScope, "case"),
            Token(.Whitespace, " "),
            Token(.Number, "1"),
            Token(.StartOfScope, ":"),
            Token(.Linebreak, "\n"),
            Token(.Identifier, "break"),
            Token(.Linebreak, "\n"),
            Token(.EndOfScope, "case"),
            Token(.Whitespace, " "),
            Token(.Number, "2"),
            Token(.StartOfScope, ":"),
            Token(.Linebreak, "\n"),
            Token(.Identifier, "break"),
            Token(.Linebreak, "\n"),
            Token(.EndOfScope, "default"),
            Token(.StartOfScope, ":"),
            Token(.Linebreak, "\n"),
            Token(.Identifier, "break"),
            Token(.Linebreak, "\n"),
            Token(.EndOfScope, "}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchCaseIsDictionaryStatement() {
        let input = "switch x {\ncase foo is [Key: Value]:\nbreak\ndefault:\nbreak\n}"
        let output = [
            Token(.Identifier, "switch"),
            Token(.Whitespace, " "),
            Token(.Identifier, "x"),
            Token(.Whitespace, " "),
            Token(.StartOfScope, "{"),
            Token(.Linebreak, "\n"),
            Token(.EndOfScope, "case"),
            Token(.Whitespace, " "),
            Token(.Identifier, "foo"),
            Token(.Whitespace, " "),
            Token(.Identifier, "is"),
            Token(.Whitespace, " "),
            Token(.StartOfScope, "["),
            Token(.Identifier, "Key"),
            Token(.Operator, ":"),
            Token(.Whitespace, " "),
            Token(.Identifier, "Value"),
            Token(.EndOfScope, "]"),
            Token(.StartOfScope, ":"),
            Token(.Linebreak, "\n"),
            Token(.Identifier, "break"),
            Token(.Linebreak, "\n"),
            Token(.EndOfScope, "default"),
            Token(.StartOfScope, ":"),
            Token(.Linebreak, "\n"),
            Token(.Identifier, "break"),
            Token(.Linebreak, "\n"),
            Token(.EndOfScope, "}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchCaseContainingCaseIdentifier() {
        let input = "switch x {\ncase 1:\nfoo.case\ndefault:\nbreak\n}"
        let output = [
            Token(.Identifier, "switch"),
            Token(.Whitespace, " "),
            Token(.Identifier, "x"),
            Token(.Whitespace, " "),
            Token(.StartOfScope, "{"),
            Token(.Linebreak, "\n"),
            Token(.EndOfScope, "case"),
            Token(.Whitespace, " "),
            Token(.Number, "1"),
            Token(.StartOfScope, ":"),
            Token(.Linebreak, "\n"),
            Token(.Identifier, "foo"),
            Token(.Operator, "."),
            Token(.Identifier, "case"),
            Token(.Linebreak, "\n"),
            Token(.EndOfScope, "default"),
            Token(.StartOfScope, ":"),
            Token(.Linebreak, "\n"),
            Token(.Identifier, "break"),
            Token(.Linebreak, "\n"),
            Token(.EndOfScope, "}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchCaseContainingDefaultIdentifier() {
        let input = "switch x {\ncase 1:\nfoo.default\ndefault:\nbreak\n}"
        let output = [
            Token(.Identifier, "switch"),
            Token(.Whitespace, " "),
            Token(.Identifier, "x"),
            Token(.Whitespace, " "),
            Token(.StartOfScope, "{"),
            Token(.Linebreak, "\n"),
            Token(.EndOfScope, "case"),
            Token(.Whitespace, " "),
            Token(.Number, "1"),
            Token(.StartOfScope, ":"),
            Token(.Linebreak, "\n"),
            Token(.Identifier, "foo"),
            Token(.Operator, "."),
            Token(.Identifier, "default"),
            Token(.Linebreak, "\n"),
            Token(.EndOfScope, "default"),
            Token(.StartOfScope, ":"),
            Token(.Linebreak, "\n"),
            Token(.Identifier, "break"),
            Token(.Linebreak, "\n"),
            Token(.EndOfScope, "}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchCaseContainingIfCase() {
        let input = "switch x {\ncase 1:\nif case x = y {}\ndefault:\nbreak\n}"
        let output = [
            Token(.Identifier, "switch"),
            Token(.Whitespace, " "),
            Token(.Identifier, "x"),
            Token(.Whitespace, " "),
            Token(.StartOfScope, "{"),
            Token(.Linebreak, "\n"),
            Token(.EndOfScope, "case"),
            Token(.Whitespace, " "),
            Token(.Number, "1"),
            Token(.StartOfScope, ":"),
            Token(.Linebreak, "\n"),
            Token(.Identifier, "if"),
            Token(.Whitespace, " "),
            Token(.Identifier, "case"),
            Token(.Whitespace, " "),
            Token(.Identifier, "x"),
            Token(.Whitespace, " "),
            Token(.Operator, "="),
            Token(.Whitespace, " "),
            Token(.Identifier, "y"),
            Token(.Whitespace, " "),
            Token(.StartOfScope, "{"),
            Token(.EndOfScope, "}"),
            Token(.Linebreak, "\n"),
            Token(.EndOfScope, "default"),
            Token(.StartOfScope, ":"),
            Token(.Linebreak, "\n"),
            Token(.Identifier, "break"),
            Token(.Linebreak, "\n"),
            Token(.EndOfScope, "}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testSwitchCaseContainingGuardCase() {
        let input = "switch x {\ncase 1:\nguard case x = y else {}\ndefault:\nbreak\n}"
        let output = [
            Token(.Identifier, "switch"),
            Token(.Whitespace, " "),
            Token(.Identifier, "x"),
            Token(.Whitespace, " "),
            Token(.StartOfScope, "{"),
            Token(.Linebreak, "\n"),
            Token(.EndOfScope, "case"),
            Token(.Whitespace, " "),
            Token(.Number, "1"),
            Token(.StartOfScope, ":"),
            Token(.Linebreak, "\n"),
            Token(.Identifier, "guard"),
            Token(.Whitespace, " "),
            Token(.Identifier, "case"),
            Token(.Whitespace, " "),
            Token(.Identifier, "x"),
            Token(.Whitespace, " "),
            Token(.Operator, "="),
            Token(.Whitespace, " "),
            Token(.Identifier, "y"),
            Token(.Whitespace, " "),
            Token(.Identifier, "else"),
            Token(.Whitespace, " "),
            Token(.StartOfScope, "{"),
            Token(.EndOfScope, "}"),
            Token(.Linebreak, "\n"),
            Token(.EndOfScope, "default"),
            Token(.StartOfScope, ":"),
            Token(.Linebreak, "\n"),
            Token(.Identifier, "break"),
            Token(.Linebreak, "\n"),
            Token(.EndOfScope, "}"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    // MARK: linebreaks

    func testLF() {
        let input = "foo\nbar"
        let output = [
            Token(.Identifier, "foo"),
            Token(.Linebreak, "\n"),
            Token(.Identifier, "bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCR() {
        let input = "foo\rbar"
        let output = [
            Token(.Identifier, "foo"),
            Token(.Linebreak, "\r"),
            Token(.Identifier, "bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCRLF() {
        let input = "foo\r\nbar"
        let output = [
            Token(.Identifier, "foo"),
            Token(.Linebreak, "\r\n"),
            Token(.Identifier, "bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCRLFAfterComment() {
        let input = "//foo\r\n//bar"
        let output = [
            Token(.StartOfScope, "//"),
            Token(.CommentBody, "foo"),
            Token(.Linebreak, "\r\n"),
            Token(.StartOfScope, "//"),
            Token(.CommentBody, "bar"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }

    func testCRLFInMultilineComment() {
        let input = "/*foo\r\nbar*/"
        let output = [
            Token(.StartOfScope, "/*"),
            Token(.CommentBody, "foo"),
            Token(.Linebreak, "\r\n"),
            Token(.CommentBody, "bar"),
            Token(.EndOfScope, "*/"),
        ]
        XCTAssertEqual(tokenize(input), output)
    }
}
