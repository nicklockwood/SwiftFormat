//
//  WrapSingleLineStringsTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 9/30/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class WrapSingleLineStringsTests: XCTestCase {
    func testWrapsSingleLineString() {
        let input = """
        let message = "one two three four five"
        """
        let output = #"""
        let message = """
            one two three \
            four five
            """
        """#

        testFormatting(for: input, output, rule: .wrapSingleLineStrings,
                       options: FormatOptions(maxWidth: 20, indentStrings: true))
    }

    func testWrapsStringWithoutIndentWhenIndentStringsDisabled() {
        let input = """
        let value = "one two three four"
        """
        let output = #"""
        let value = """
        one two three \
        four
        """
        """#

        testFormatting(for: input, output, rule: .wrapSingleLineStrings,
                       options: FormatOptions(maxWidth: 15))
    }

    func testDoesNotWrapStringThatFits() {
        let input = """
        let message = "one two three"
        """

        testFormatting(for: input, rule: .wrapSingleLineStrings,
                       options: FormatOptions(maxWidth: 30))
    }

    func testDoesNotRewrapMultilineString() {
        let input = #"""
        let message = """
            one two three four five six
            """
        """#

        testFormatting(for: input, rule: .wrapSingleLineStrings,
                       options: FormatOptions(maxWidth: 20, indentStrings: true))
    }

    func testWrapsStringInterpolationAsAnAtomicSegment() {
        let input = #"""
        let message = "one two \(value) three four"
        """#
        let output = #"""
        let message = """
            one two \
            \(value) \
            three four
            """
        """#

        testFormatting(for: input, output, rule: .wrapSingleLineStrings,
                       options: FormatOptions(maxWidth: 17, indentStrings: true))
    }

    func testWrapsRawString() {
        let input = ##"""
        let message = #"one two three four five"#
        """##
        let output = ##"""
        let message = #"""
            one two three \#
            four five
            """#
        """##

        testFormatting(for: input, output, rule: .wrapSingleLineStrings,
                       options: FormatOptions(maxWidth: 20, indentStrings: true))
    }

    func testDoesNotWrapRegexLiteral() {
        let input = #"""
        let regex = /one two three four five/
        """#

        testFormatting(for: input, rule: .wrapSingleLineStrings,
                       options: FormatOptions(maxWidth: 20))
    }

    func testDoesNotWrapLongWord() {
        let input = """
        let value = "averylongwordwithnobreakpoint"
        """

        testFormatting(for: input, rule: .wrapSingleLineStrings,
                       options: FormatOptions(maxWidth: 20))
    }
}
