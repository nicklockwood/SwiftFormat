//
//  LinebreaksTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 8/25/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class LinebreaksTests: XCTestCase {
    func testCarriageReturn() {
        let input = "foo\rbar"
        let output = "foo\nbar"
        testFormatting(for: input, output, rule: .linebreaks)
    }

    func testCarriageReturnLinefeed() {
        let input = "foo\r\nbar"
        let output = "foo\nbar"
        testFormatting(for: input, output, rule: .linebreaks)
    }

    func testVerticalTab() {
        let input = "foo\u{000B}bar"
        let output = "foo\nbar"
        testFormatting(for: input, output, rule: .linebreaks)
    }

    func testFormfeed() {
        let input = "foo\u{000C}bar"
        let output = "foo\nbar"
        testFormatting(for: input, output, rule: .linebreaks)
    }
}
