//
//  ParserTests.swift
//  ParsingTests
//
//  Created by Nick Lockwood on 03/09/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import Parsing

class ParserTests: XCTestCase {

    // MARK: declarations

    func testDeclareWithNumber() {
        let input = "let foo = 5"
        let program: [Statement] = [
            .declaration(name: "foo", value: .number(5)),
        ]
        XCTAssertEqual(try parse(input), program)
    }

    func testDeclareWithString() {
        let input = "let foo = \"foo\""
        let program: [Statement] = [
            .declaration(name: "foo", value: .string("foo")),
        ]
        XCTAssertEqual(try parse(input), program)
    }

    func testDeclareWithVariable() {
        let input = "let foo = bar"
        let program: [Statement] = [
            .declaration(name: "foo", value: .variable("bar")),
        ]
        XCTAssertEqual(try parse(input), program)
    }

    func testDeclareWithAddition() {
        let input = "let foo = 1 + 2"
        let program: [Statement] = [
            .declaration(name: "foo", value: .addition(
                lhs: .number(1),
                rhs: .number(2)
            )),
        ]
        XCTAssertEqual(try parse(input), program)
    }

    func testMissingDeclareValue() {
        let input = "let foo ="
        XCTAssertThrowsError(try parse(input)) { error in
            XCTAssertEqual(error as? ParserError, .unexpectedToken(.let))
        }
    }

    func testMissingDeclareVariable() {
        let input = "let = bar"
        XCTAssertThrowsError(try parse(input)) { error in
            XCTAssertEqual(error as? ParserError, .unexpectedToken(.let))
        }
    }

    // MARK: print statements

    func testPrintNumber() {
        let input = "print 5.5"
        let program: [Statement] = [
            .print(.number(5.5)),
        ]
        XCTAssertEqual(try parse(input), program)
    }

    func testMissingPrintValue() {
        let input = "print"
        XCTAssertThrowsError(try parse(input)) { error in
            XCTAssertEqual(error as? ParserError, .unexpectedToken(.print))
        }
    }

    func testMissingOperand() {
        let input = "print 5 +"
        XCTAssertThrowsError(try parse(input)) { error in
            XCTAssertEqual(error as? ParserError, .unexpectedToken(.plus))
        }
    }
}
