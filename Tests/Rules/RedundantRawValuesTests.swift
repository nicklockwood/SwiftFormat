//
//  RedundantRawValuesTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 12/22/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class RedundantRawValuesTests: XCTestCase {
    func testRemoveRedundantRawString() {
        let input = """
        enum Foo: String {
            case bar = \"bar\"
            case baz = \"baz\"
        }
        """
        let output = """
        enum Foo: String {
            case bar
            case baz
        }
        """
        testFormatting(for: input, output, rule: .redundantRawValues)
    }

    func testRemoveCommaDelimitedCaseRawStringCases() {
        let input = """
        enum Foo: String { case bar = \"bar\", baz = \"baz\" }
        """
        let output = """
        enum Foo: String { case bar, baz }
        """
        testFormatting(for: input, output, rule: .redundantRawValues,
                       exclude: [.wrapEnumCases])
    }

    func testRemoveBacktickCaseRawStringCases() {
        let input = """
        enum Foo: String { case `as` = \"as\", `let` = \"let\" }
        """
        let output = """
        enum Foo: String { case `as`, `let` }
        """
        testFormatting(for: input, output, rule: .redundantRawValues,
                       exclude: [.wrapEnumCases])
    }

    func testNoRemoveRawStringIfNameDoesntMatch() {
        let input = """
        enum Foo: String {
            case bar = \"foo\"
        }
        """
        testFormatting(for: input, rule: .redundantRawValues)
    }
}
