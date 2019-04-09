//
//  InterpreterTests.swift
//  ParsingTests
//
//  Created by Nick Lockwood on 04/09/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import Parsing

class InterpreterTests: XCTestCase {

    func testDeclaration() throws {
        let input = "let foo = 5 + 6 + 7"
        let program = try parse(input)
        let environment = Environment()
        XCTAssertNoThrow(try program[0].evaluate(in: environment))
        XCTAssertEqual(environment.variables, ["foo": .number(18)])
    }

    func testPrintString() throws {
        let input = """
        print "hello world"
        """
        let program = try parse(input)
        let output = try evaluate(program)
        XCTAssertEqual(output, "hello world\n")
    }

    func testPrintStringWithEscapedQuotes() throws {
        let input = """
        print "hello \\"Nick\\""
        """
        let program = try parse(input)
        let output = try evaluate(program)
        XCTAssertEqual(output, "hello \"Nick\"\n")
    }

    func testPrintInteger() throws {
        let input = "print 57"
        let program = try parse(input)
        let output = try evaluate(program)
        XCTAssertEqual(output, "57\n")
    }

    func testPrintFloat() throws {
        let input = "print 0.4"
        let program = try parse(input)
        let output = try evaluate(program)
        XCTAssertEqual(output, "0.4\n")
    }

    func testPrintStringPlusNumber() throws {
        let input = """
        print "mambo no. " + 5
        """
        let program = try parse(input)
        let output = try evaluate(program)
        XCTAssertEqual(output, "mambo no. 5\n")
    }

    func testPrintNumberPlusString() throws {
        let input = """
        print 3 + " is a magic number"
        """
        let program = try parse(input)
        let output = try evaluate(program)
        XCTAssertEqual(output, "3 is a magic number\n")
    }

    func testPrintVariable() throws {
        let input = """
        let foo = "bar"
        print foo
        """
        let program = try parse(input)
        let output = try evaluate(program)
        XCTAssertEqual(output, "bar\n")
    }

    func testPrintUnknownVariable() throws {
        let input = "print foo"
        let program = try parse(input)
        XCTAssertThrowsError(try evaluate(program)) { error in
            XCTAssertEqual(error as? RuntimeError, .undefinedVariable("foo"))
        }
    }
}
