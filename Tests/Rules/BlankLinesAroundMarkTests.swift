//
//  BlankLinesAroundMarkTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 11/29/17.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class BlankLinesAroundMarkTests: XCTestCase {
    func testInsertBlankLinesAroundMark() {
        let input = """
        let foo = "foo"
        // MARK: bar
        let bar = "bar"
        """
        let output = """
        let foo = "foo"

        // MARK: bar

        let bar = "bar"
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMark)
    }

    func testNoInsertExtraBlankLinesAroundMark() {
        let input = """
        let foo = "foo"

        // MARK: bar

        let bar = "bar"
        """
        testFormatting(for: input, rule: .blankLinesAroundMark)
    }

    func testInsertBlankLineAfterMarkAtStartOfFile() {
        let input = """
        // MARK: bar
        let bar = "bar"
        """
        let output = """
        // MARK: bar

        let bar = "bar"
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMark)
    }

    func testInsertBlankLineBeforeMarkAtEndOfFile() {
        let input = """
        let foo = "foo"
        // MARK: bar
        """
        let output = """
        let foo = "foo"

        // MARK: bar
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMark)
    }

    func testInsertBlankLineBeforeMarkAtStartOfScope() {
        let input = """
        do {
            // MARK: foo

            let foo = "foo"
        }
        """
        let output = """
        do {

            // MARK: foo

            let foo = "foo"
        }
        """
        // When only blankLinesAroundMark runs (without blankLinesAtStartOfScope), a blank line is
        // inserted before the MARK. The second output (input) represents what happens when all rules
        // run together, where blankLinesAtStartOfScope removes the blank line at the start of scope.
        testFormatting(for: input, [output, input], rules: [.blankLinesAroundMark])
    }

    func testInsertBlankLineBeforeMarkAtStartOfScopeWithTrailingComment() {
        let input = """
        struct Foo { // some comment here
            // MARK: bar

            let string: String
        }
        """
        let output = """
        struct Foo { // some comment here

            // MARK: bar

            let string: String
        }
        """
        // When only blankLinesAroundMark runs (without blankLinesAtStartOfScope), a blank line is
        // inserted before the MARK. The second output (input) represents what happens when all rules
        // run together, where blankLinesAtStartOfScope removes the blank line at the start of scope.
        testFormatting(for: input, [output, input], rules: [.blankLinesAroundMark])
    }

    func testNoInsertBlankLineBeforeMarkAtStartOfScopeWhenBlankLinesAtStartOfScopeEnabled() {
        let input = """
        do {
            // MARK: foo

            let foo = "foo"
        }
        """
        testFormatting(for: input, rules: [.blankLinesAroundMark, .blankLinesAtStartOfScope])
    }

    func testNoInsertBlankLineBeforeMarkAtStartOfTypeBodyWithRemoveOption() {
        let input = """
        struct Foo {
            // MARK: bar

            let string: String
        }
        """
        testFormatting(for: input, rules: [.blankLinesAroundMark, .blankLinesAtStartOfScope])
    }

    func testInsertBlankLineBeforeMarkAtStartOfTypeBodyWithInsertOption() {
        let input = """
        struct Foo {
            // MARK: bar

            let string: String
        }
        """
        let output = """
        struct Foo {

            // MARK: bar

            let string: String
        }
        """
        let outputAllRules = """
        struct Foo {

            // MARK: bar

            let string: String

        }
        """
        let options = FormatOptions(typeBlankLines: .insert)
        testFormatting(for: input, [output, outputAllRules], rules: [.blankLinesAroundMark, .blankLinesAtStartOfScope], options: options)
    }

    func testNoInsertBlankLineAfterMarkAtEndOfScope() {
        let input = """
        do {
            let foo = "foo"

            // MARK: foo
        }
        """
        testFormatting(for: input, rule: .blankLinesAroundMark)
    }

    func testInsertBlankLinesJustBeforeMarkNotAfter() {
        let input = """
        let foo = "foo"
        // MARK: bar
        let bar = "bar"
        """
        let output = """
        let foo = "foo"

        // MARK: bar
        let bar = "bar"
        """
        let options = FormatOptions(lineAfterMarks: false)
        testFormatting(for: input, output, rule: .blankLinesAroundMark, options: options)
    }

    func testNoInsertExtraBlankLinesAroundMarkWithNoBlankLineAfterMark() {
        let input = """
        let foo = "foo"

        // MARK: bar
        let bar = "bar"
        """
        let options = FormatOptions(lineAfterMarks: false)
        testFormatting(for: input, rule: .blankLinesAroundMark, options: options)
    }

    func testNoInsertBlankLineAfterMarkAtStartOfFile() {
        let input = """
        // MARK: bar
        let bar = "bar"
        """
        let options = FormatOptions(lineAfterMarks: false)
        testFormatting(for: input, rule: .blankLinesAroundMark, options: options)
    }
}
