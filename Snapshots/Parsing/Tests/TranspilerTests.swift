//
//  TranspilerTests.swift
//  ParsingTests
//
//  Created by Nick Lockwood on 19/03/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import Parsing

class TranspilerTests: XCTestCase {

    func testDeclaration() throws {
        let input = "let foo = 5 + 6 + 7"
        let program = try parse(input)
        let context = Context()
        XCTAssertNoThrow(try program[0].transpile(in: context))
        XCTAssertEqual(context.variables, ["foo": .number])
        XCTAssertEqual(context.output, "let foo = 5.0 + 6.0 + 7.0\n")
    }

    func testPrintString() throws {
        let input = """
        print "hello world"
        """
        let program = try parse(input)
        let output = try transpile(program)
        XCTAssertEqual(output, "print(\"hello world\")\n")
    }

    func testPrintStringWithEscapedQuotes() throws {
        let input = """
        print "hello \\"Nick\\""
        """
        let program = try parse(input)
        let output = try transpile(program)
        XCTAssertEqual(output, "print(\"hello \\\"Nick\\\"\")\n")
    }

    func testPrintInteger() throws {
        let input = "print 57"
        let program = try parse(input)
        let output = try transpile(program)
        XCTAssertEqual(output, "print(57.0)\n")
    }

    func testPrintFloat() throws {
        let input = "print 0.4"
        let program = try parse(input)
        let output = try transpile(program)
        XCTAssertEqual(output, "print(0.4)\n")
    }

    func testPrintStringPlusNumber() throws {
        let input = """
        print "mambo no. " + 5
        """
        let program = try parse(input)
        let output = try transpile(program)
        XCTAssertEqual(output, """
        print("\\("mambo no. ")\\(5.0)")

        """)
    }

    func testPrintNumberPlusString() throws {
        let input = """
        print 3 + " is a magic number"
        """
        let program = try parse(input)
        let output = try transpile(program)
        XCTAssertEqual(output, """
        print("\\(3.0)\\(" is a magic number")")

        """)
    }

    func testPrintVariable() throws {
        let input = """
        let foo = "bar"
        print foo
        """
        let program = try parse(input)
        let output = try transpile(program)
        XCTAssertEqual(output, """
        let foo = "bar"
        print(foo)

        """)
    }

    func testPrintUnknownVariable() throws {
        let input = "print foo"
        let program = try parse(input)
        XCTAssertThrowsError(try transpile(program)) { error in
            XCTAssertEqual(error as? TranspilerError, .undefinedVariable("foo"))
        }
    }
}
