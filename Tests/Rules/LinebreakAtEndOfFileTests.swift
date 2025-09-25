//
//  LinebreakAtEndOfFileTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 8/22/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class LinebreakAtEndOfFileTests: XCTestCase {
    func testLinebreakAtEndOfFile() {
        let input = """
        foo
        bar
        """
        let output = """
        foo
        bar

        """
        testFormatting(for: input, output, rule: .linebreakAtEndOfFile)
    }

    func testNoLinebreakAtEndOfFragment() {
        let input = """
        foo
        bar
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: .linebreakAtEndOfFile, options: options)
    }
}
