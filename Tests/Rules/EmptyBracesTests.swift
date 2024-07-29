//
//  EmptyBracesTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class EmptyBracesTests: XCTestCase {
    func testLinebreaksRemovedInsideBraces() {
        let input = "func foo() {\n  \n }"
        let output = "func foo() {}"
        testFormatting(for: input, output, rule: .emptyBraces)
    }

    func testCommentNotRemovedInsideBraces() {
        let input = "func foo() { // foo\n}"
        testFormatting(for: input, rule: .emptyBraces)
    }

    func testEmptyBracesNotRemovedInDoCatch() {
        let input = """
        do {
        } catch is FooError {
        } catch {}
        """
        testFormatting(for: input, rule: .emptyBraces)
    }

    func testEmptyBracesNotRemovedInIfElse() {
        let input = """
        if bar {
        } else if foo {
        } else {}
        """
        testFormatting(for: input, rule: .emptyBraces)
    }

    func testSpaceRemovedInsideEmptybraces() {
        let input = "foo { }"
        let output = "foo {}"
        testFormatting(for: input, output, rule: .emptyBraces)
    }

    func testSpaceAddedInsideEmptyBracesWithSpacedConfiguration() {
        let input = "foo {}"
        let output = "foo { }"
        let options = FormatOptions(emptyBracesSpacing: .spaced)
        testFormatting(for: input, output, rule: .emptyBraces, options: options)
    }

    func testLinebreaksRemovedInsideBracesWithSpacedConfiguration() {
        let input = "func foo() {\n  \n }"
        let output = "func foo() { }"
        let options = FormatOptions(emptyBracesSpacing: .spaced)
        testFormatting(for: input, output, rule: .emptyBraces, options: options)
    }

    func testCommentNotRemovedInsideBracesWithSpacedConfiguration() {
        let input = "func foo() { // foo\n}"
        let options = FormatOptions(emptyBracesSpacing: .spaced)
        testFormatting(for: input, rule: .emptyBraces, options: options)
    }

    func testEmptyBracesSpaceNotRemovedInDoCatchWithSpacedConfiguration() {
        let input = """
        do {
        } catch is FooError {
        } catch { }
        """
        let options = FormatOptions(emptyBracesSpacing: .spaced)
        testFormatting(for: input, rule: .emptyBraces, options: options)
    }

    func testEmptyBracesSpaceNotRemovedInIfElseWithSpacedConfiguration() {
        let input = """
        if bar {
        } else if foo {
        } else { }
        """
        let options = FormatOptions(emptyBracesSpacing: .spaced)
        testFormatting(for: input, rule: .emptyBraces, options: options)
    }

    func testEmptyBracesLinebreakNotRemovedInIfElseWithLinebreakConfiguration() {
        let input = """
        if bar {
        } else if foo {
        } else {
        }
        """
        let options = FormatOptions(emptyBracesSpacing: .linebreak)
        testFormatting(for: input, rule: .emptyBraces, options: options)
    }

    func testEmptyBracesLinebreakIndentedCorrectly() {
        let input = """
        func foo() {
            if bar {
            } else if foo {
            } else {
            }
        }
        """
        let options = FormatOptions(emptyBracesSpacing: .linebreak)
        testFormatting(for: input, rule: .emptyBraces, options: options)
    }
}
