//
//  RedundantRawValuesTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class RedundantRawValuesTests: XCTestCase {
    func testRemoveRedundantRawString() {
        let input = "enum Foo: String {\n    case bar = \"bar\"\n    case baz = \"baz\"\n}"
        let output = "enum Foo: String {\n    case bar\n    case baz\n}"
        testFormatting(for: input, output, rule: .redundantRawValues)
    }

    func testRemoveCommaDelimitedCaseRawStringCases() {
        let input = "enum Foo: String { case bar = \"bar\", baz = \"baz\" }"
        let output = "enum Foo: String { case bar, baz }"
        testFormatting(for: input, output, rule: .redundantRawValues,
                       exclude: [.wrapEnumCases])
    }

    func testRemoveBacktickCaseRawStringCases() {
        let input = "enum Foo: String { case `as` = \"as\", `let` = \"let\" }"
        let output = "enum Foo: String { case `as`, `let` }"
        testFormatting(for: input, output, rule: .redundantRawValues,
                       exclude: [.wrapEnumCases])
    }

    func testNoRemoveRawStringIfNameDoesntMatch() {
        let input = "enum Foo: String {\n    case bar = \"foo\"\n}"
        testFormatting(for: input, rule: .redundantRawValues)
    }
}
