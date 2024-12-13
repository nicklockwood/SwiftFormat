//
// NoCommentedAssertionsTests.swift
//  SwiftFormatTests
//
// Created by manny_lopez on 12/12/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class NoCommentedAssertionsTests: XCTestCase {
    func testCommentedAssert() {
        let input = "// assert(false)"
        let output = "assert(false)"
        testFormatting(for: input, output, rule: .noCommentedAssertions, exclude: [.assertionFailures])
    }

    func testCommentedAssertWithMessage() {
        let input = "// assert(false, \"Not allowed\")"
        let output = "assert(false, \"Not allowed\")"
        testFormatting(for: input, output, rule: .noCommentedAssertions, exclude: [.assertionFailures])
    }

    func testCommentedAssertionFailure() {
        let input = "// assertionFailure()"
        let output = "assertionFailure()"
        testFormatting(for: input, output, rule: .noCommentedAssertions)
    }

    func testCommentedAssertionFailureWithMessage() {
        let input = "// assertionFailure(\"test\")"
        let output = "assertionFailure(\"test\")"
        testFormatting(for: input, output, rule: .noCommentedAssertions)
    }

    func testCommentedAssertComment() {
        let input = "// Asserts that"
        testFormatting(for: input, rule: .noCommentedAssertions)
    }

    func testCommentedAssertCommentLowercase() {
        let input = "// asserts that"
        testFormatting(for: input, rule: .noCommentedAssertions)
    }

    // TODO: The following test cases fail

    func testCommentedAssertMultiComment() {
        let input = "/// assert(false)"
        let output = "assert(false)"
        testFormatting(for: input, output, rule: .noCommentedAssertions, exclude: [.assertionFailures])
    }

    func testCommentedAssertWithinComment() {
        let input = """
        // Some documentation:
        // ```
        // assert(tree.byteSize == endOfFile.utf8Offset)
        // ```
        """
        testFormatting(for: input, rule: .noCommentedAssertions, exclude: [.assertionFailures])
    }
}
