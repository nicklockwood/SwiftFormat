//
//  LexerTests.swift
//  ParsingTests
//
//  Created by Nick Lockwood on 03/09/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import Parsing

class LexerTests: XCTestCase {

    // MARK: identifiers

    func testLetters() {
        let input = "abc dfe"
        let tokens: [Token] = [.identifier("abc"), .identifier("dfe")]
        XCTAssertEqual(try tokenize(input), tokens)
    }

    func testLettersAndNumbers() {
        let input = "a1234b"
        let tokens: [Token] = [.identifier("a1234b")]
        XCTAssertEqual(try tokenize(input), tokens)
    }

    func testInvalidIdentifier() {
        let input = "a123_4b"
        XCTAssertThrowsError(try tokenize(input)) { error in
            XCTAssertEqual(error as? LexerError, .unrecognizedInput("_4b"))
        }
    }

    // MARK: strings

    func testSimpleString() {
        let input = "\"abcd\""
        let tokens: [Token] = [.string("abcd")]
        XCTAssertEqual(try tokenize(input), tokens)
    }

    func testUnicodeString() {
        let input = "\"😂\""
        let tokens: [Token] = [.string("😂")]
        XCTAssertEqual(try tokenize(input), tokens)
    }

    func testEmptyString() {
        let input = "\"\""
        let tokens: [Token] = [.string("")]
        XCTAssertEqual(try tokenize(input), tokens)
    }

    func testStringWithEscapedQuotes() {
        let input = "\"\\\"hello\\\"\""
        let tokens: [Token] = [.string("\"hello\"")]
        XCTAssertEqual(try tokenize(input), tokens)
    }

    func testStringWithEscapedBackslash() {
        let input = "\"foo\\\\bar\""
        let tokens: [Token] = [.string("foo\\bar")]
        XCTAssertEqual(try tokenize(input), tokens)
    }

    func testUnterminatedString() {
        let input = "\"hello"
        XCTAssertThrowsError(try tokenize(input)) { error in
            XCTAssertEqual(error as? LexerError, .unrecognizedInput("\"hello"))
        }
    }

    func testUnterminatedEscapedQuote() {
        let input = "\"hello\\\""
        XCTAssertThrowsError(try tokenize(input)) { error in
            XCTAssertEqual(error as? LexerError, .unrecognizedInput("\"hello\\\""))
        }
    }

    // MARK: numbers

    func testZero() {
        let input = "0"
        let tokens: [Token] = [.number(0)]
        XCTAssertEqual(try tokenize(input), tokens)
    }

    func testDigit() {
        let input = "5"
        let tokens: [Token] = [.number(5)]
        XCTAssertEqual(try tokenize(input), tokens)
    }

    func testMultidigit() {
        let input = "50"
        let tokens: [Token] = [.number(50)]
        XCTAssertEqual(try tokenize(input), tokens)
    }

    func testLeadingZero() {
        let input = "05"
        let tokens: [Token] = [.number(5)]
        XCTAssertEqual(try tokenize(input), tokens)
    }

    func testDecimal() {
        let input = "0.5"
        let tokens: [Token] = [.number(0.5)]
        XCTAssertEqual(try tokenize(input), tokens)
    }

    func testLeadingDecimalPoint() {
        let input = ".56"
        let tokens: [Token] = [.number(0.56)]
        XCTAssertEqual(try tokenize(input), tokens)
    }

    func testTrailingDecimalPoint() {
        let input = "56."
        let tokens: [Token] = [.number(56)]
        XCTAssertEqual(try tokenize(input), tokens)
    }

    func testTooManyDecimalPoints() {
        let input = "0.5.6"
        XCTAssertThrowsError(try tokenize(input)) { error in
            XCTAssertEqual(error as? LexerError, .unrecognizedInput("0.5.6"))
        }
    }

    // MARK: operators

    func testOperators() {
        let input = "a = 4 + b"
        let tokens: [Token] = [
            .identifier("a"), .assign, .number(4), .plus, .identifier("b"),
        ]
        XCTAssertEqual(try tokenize(input), tokens)
    }

    // MARK: statements

    func testDeclaration() {
        let input = """
        let foo = 5
        let bar = "hello"
        let baz = foo
        """
        let tokens: [Token] = [
            .let, .identifier("foo"), .assign, .number(5),
            .let, .identifier("bar"), .assign, .string("hello"),
            .let, .identifier("baz"), .assign, .identifier("foo"),
        ]
        XCTAssertEqual(try tokenize(input), tokens)
    }

    func testPrintStatement() {
        let input = """
        print foo
        print 5
        print "hello" + "world"
        """
        let tokens: [Token] = [
            .print, .identifier("foo"),
            .print, .number(5),
            .print, .string("hello"), .plus, .string("world"),
        ]
        XCTAssertEqual(try tokenize(input), tokens)
    }
}
