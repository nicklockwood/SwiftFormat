//
//  ConsecutiveBlankLinesTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class ConsecutiveBlankLinesTests: XCTestCase {
    func testConsecutiveBlankLines() {
        let input = "foo\n\n    \nbar"
        let output = "foo\n\nbar"
        testFormatting(for: input, output, rule: .consecutiveBlankLines)
    }

    func testConsecutiveBlankLinesAtEndOfFile() {
        let input = "foo\n\n"
        let output = "foo\n"
        testFormatting(for: input, output, rule: .consecutiveBlankLines)
    }

    func testConsecutiveBlankLinesAtStartOfFile() {
        let input = "\n\n\nfoo"
        let output = "\n\nfoo"
        testFormatting(for: input, output, rule: .consecutiveBlankLines)
    }

    func testConsecutiveBlankLinesInsideStringLiteral() {
        let input = "\"\"\"\nhello\n\n\nworld\n\"\"\""
        testFormatting(for: input, rule: .consecutiveBlankLines)
    }

    func testConsecutiveBlankLinesAtStartOfStringLiteral() {
        let input = "\"\"\"\n\n\nhello world\n\"\"\""
        testFormatting(for: input, rule: .consecutiveBlankLines)
    }

    func testConsecutiveBlankLinesAfterStringLiteral() {
        let input = "\"\"\"\nhello world\n\"\"\"\n\n\nfoo()"
        let output = "\"\"\"\nhello world\n\"\"\"\n\nfoo()"
        testFormatting(for: input, output, rule: .consecutiveBlankLines)
    }

    func testFragmentWithTrailingLinebreaks() {
        let input = "func foo() {}\n\n\n"
        let output = "func foo() {}\n\n"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: .consecutiveBlankLines, options: options)
    }

    func testConsecutiveBlankLinesNoInterpolation() {
        let input = """
        \"\"\"
        AAA
        ZZZ



        \"\"\"
        """
        testFormatting(for: input, rule: .consecutiveBlankLines)
    }

    func testConsecutiveBlankLinesAfterInterpolation() {
        let input = """
        \"\"\"
        AAA
        \\(interpolated)



        \"\"\"
        """
        testFormatting(for: input, rule: .consecutiveBlankLines)
    }

    func testLintingConsecutiveBlankLinesReportsCorrectLine() {
        let input = "foo\n   \n\nbar"
        XCTAssertEqual(try lint(input, rules: [.consecutiveBlankLines]), [
            .init(line: 3, rule: .consecutiveBlankLines, filePath: nil),
        ])
    }
}
