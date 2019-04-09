//
//  FormatterTests.swift
//  ParsingTests
//
//  Created by Nick Lockwood on 04/09/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import Parsing

class FormatterTests: XCTestCase {

    func testFormatting() throws {
        let input = """
        let foo = 5 + 6
        let bar = "hello\\\\world"
        let baz = "goodbye \\"world\\""
        print foo + bar + baz
        """
        let program = try parse(input)
        let output = format(program)
        XCTAssertEqual(output, input + "\n")
    }
}
