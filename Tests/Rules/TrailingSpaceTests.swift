//
//  TrailingSpaceTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 11/24/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class TrailingSpaceTests: XCTestCase {
    // truncateBlankLines = true

    func testTrailingSpace() {
        let input = """
        foo\("    ")
        bar
        """
        let output = """
        foo
        bar
        """
        testFormatting(for: input, output, rule: .trailingSpace)
    }

    func testTrailingSpaceAtEndOfFile() {
        let input = """
        foo\("    ")
        """
        let output = """
        foo
        """
        testFormatting(for: input, output, rule: .trailingSpace)
    }

    func testTrailingSpaceInMultilineComments() {
        let input = """
        /* foo\("    ")
         bar  */
        """
        let output = """
        /* foo
         bar  */
        """
        testFormatting(for: input, output, rule: .trailingSpace)
    }

    func testTrailingSpaceInSingleLineComments() {
        let input = """
        // foo\("    ")
        // bar  
        """
        let output = """
        // foo
        // bar
        """
        testFormatting(for: input, output, rule: .trailingSpace)
    }

    func testTruncateBlankLine() {
        let input = """
        foo {
            // bar
        \("    ")
            // baz
        }
        """
        let output = """
        foo {
            // bar

            // baz
        }
        """
        testFormatting(for: input, output, rule: .trailingSpace)
    }

    func testTrailingSpaceInArray() {
        let input = """
        let foo = [
            1,
        \("    ")
            2,
        ]
        """
        let output = """
        let foo = [
            1,

            2,
        ]
        """
        testFormatting(for: input, output, rule: .trailingSpace, exclude: [.redundantSelf])
    }

    func testMultilineStringWithTrailingSpaces() {
        let input = """
        let foo = \"\"\"\u{20}\u{20}
        there is a space here\u{20}
        \"\"\"\u{20}
        """
        let output = """
        let foo = \"\"\"
        there is a space here\u{20}
        \"\"\"
        """
        testFormatting(for: input, output, rule: .trailingSpace)
    }

    func testMultilineStringWithLeadingSpaceAfterInterpolation() {
        let input = """
        let foo = \"\"\"
        \\(foo)    bar
        \"\"\"
        """
        testFormatting(for: input, rule: .trailingSpace)
    }

    func testMultilineStringWhiteSpaceNotRemovedFromBlankLines() {
        let input = """
        func test() {
            let foo = \"\"\"
            Test
            \u{20}
            \"\"\"
        }
        """
        testFormatting(for: input, rule: .trailingSpace)
    }

    // truncateBlankLines = false

    func testNoTruncateBlankLine() {
        let input = """
        foo {
            // bar
        \("    ")
            // baz
        }
        """
        let options = FormatOptions(truncateBlankLines: false)
        testFormatting(for: input, rule: .trailingSpace, options: options)
    }

    func testMultilineStringWhiteSpaceNotAddedToBlankLines() {
        let input = """
        func test() {
        \tlet foo = \"\"\"
        \tTest
        \t
        \t\"\"\"
        }
        """
        let options = FormatOptions(indent: "\t", truncateBlankLines: false)
        testFormatting(for: input, rule: .trailingSpace, options: options)
    }
}
