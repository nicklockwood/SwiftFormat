//
//  LinebreakAtEndOfFileTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 8/22/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class LinebreakAtEndOfFileTests: XCTestCase {
    func testLinebreakAtEndOfFile() {
        let input = "foo\nbar"
        let output = "foo\nbar\n"
        testFormatting(for: input, output, rule: .linebreakAtEndOfFile)
    }

    func testNoLinebreakAtEndOfFragment() {
        let input = "foo\nbar"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: .linebreakAtEndOfFile, options: options)
    }
}
