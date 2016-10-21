//
//  OptionsTests.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 21/10/2016.
//  Copyright © 2016 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class OptionsTests: XCTestCase {

    func testInferLinebreaks() {
        let input = "foo\nbar\r\nbaz\rquux\r\n"
        let output = "\r\n"
        let options = inferOptions(tokenize(input))
        XCTAssertEqual(options.linebreak, output)
    }

    func testInferSpaceAroundRangeOperators() {
        let input = "let foo = 0 ..< bar\n;let baz = 1...quux"
        let output = true
        let options = inferOptions(tokenize(input))
        XCTAssertEqual(options.spaceAroundRangeOperators, output)
    }

    func testInferNoSpaceAroundRangeOperators() {
        let input = "let foo = 0..<bar\n;let baz = 1...quux"
        let output = false
        let options = inferOptions(tokenize(input))
        XCTAssertEqual(options.spaceAroundRangeOperators, output)
    }

    func testInferUseVoid() {
        let input = "func foo(bar: () -> (Void), baz: ()->(), quux: () -> Void) {}"
        let output = true
        let options = inferOptions(tokenize(input))
        XCTAssertEqual(options.useVoid, output)
    }

    func testInferDontUseVoid() {
        let input = "func foo(bar: () -> (), baz: ()->(), quux: () -> Void) {}"
        let output = false
        let options = inferOptions(tokenize(input))
        XCTAssertEqual(options.useVoid, output)
    }

    func testInferTrailingCommas() {
        let input = "let foo = [\nbar,\n]\n let baz = [\nquux\n]"
        let output = true
        let options = inferOptions(tokenize(input))
        XCTAssertEqual(options.trailingCommas, output)
    }

    func testInferNoTrailingCommas() {
        let input = "let foo = [\nbar\n]\n let baz = [\nquux\n]"
        let output = false
        let options = inferOptions(tokenize(input))
        XCTAssertEqual(options.trailingCommas, output)
    }
}
