//
//  ConsecutiveBlankLinesTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 8/30/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class ConsecutiveBlankLinesTests: XCTestCase {
    func testConsecutiveBlankLines() {
        let input = """
        foo


        bar
        """
        let output = """
        foo

        bar
        """
        testFormatting(for: input, output, rule: .consecutiveBlankLines)
    }

    func testConsecutiveBlankLinesAtEndOfFile() {
        let input = """
        foo


        """
        let output = """
        foo

        """
        testFormatting(for: input, output, rule: .consecutiveBlankLines)
    }

    func testConsecutiveBlankLinesAtStartOfFile() {
        let input = """



        foo
        """
        let output = """


        foo
        """
        testFormatting(for: input, output, rule: .consecutiveBlankLines)
    }

    func testConsecutiveBlankLinesInsideStringLiteral() {
        let input = """
        \"\"\"
        hello


        world
        \"\"\"
        """
        testFormatting(for: input, rule: .consecutiveBlankLines)
    }

    func testConsecutiveBlankLinesAtStartOfStringLiteral() {
        let input = """
        \"\"\"


        hello world
        \"\"\"
        """
        testFormatting(for: input, rule: .consecutiveBlankLines)
    }

    func testConsecutiveBlankLinesAfterStringLiteral() {
        let input = """
        \"\"\"
        hello world
        \"\"\"


        foo()
        """
        let output = """
        \"\"\"
        hello world
        \"\"\"

        foo()
        """
        testFormatting(for: input, output, rule: .consecutiveBlankLines)
    }

    func testFragmentWithTrailingLinebreaks() {
        let input = """
        func foo() {}



        """
        let output = """
        func foo() {}


        """
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
        let input = """
        foo


        bar
        """
        XCTAssertEqual(try lint(input, rules: [.consecutiveBlankLines]), [
            .init(line: 3, rule: .consecutiveBlankLines, filePath: nil, isMove: false),
        ])
    }
}
