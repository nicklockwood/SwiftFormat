//
//  TodosTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 8/23/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class TodosTests: XCTestCase {
    func testMarkIsUpdated() {
        let input = "// MARK foo"
        let output = "// MARK: foo"
        testFormatting(for: input, output, rule: .todos)
    }

    func testTodoIsUpdated() {
        let input = "// TODO foo"
        let output = "// TODO: foo"
        testFormatting(for: input, output, rule: .todos)
    }

    func testFixmeIsUpdated() {
        let input = "//    FIXME foo"
        let output = "//    FIXME: foo"
        testFormatting(for: input, output, rule: .todos)
    }

    func testMarkWithColonSeparatedBySpace() {
        let input = "// MARK : foo"
        let output = "// MARK: foo"
        testFormatting(for: input, output, rule: .todos)
    }

    func testMarkWithTripleSlash() {
        let input = "/// MARK: foo"
        let output = "// MARK: foo"
        testFormatting(for: input, output, rule: .todos)
    }

    func testTodoReplacedInMiddleOfCommentBlock() {
        let input = """
        // Some comment
        // todo : foo
        // Some more comment
        """
        let output = """
        // Some comment
        // TODO: foo
        // Some more comment
        """
        testFormatting(for: input, output, rule: .todos)
    }

    func testTodoNotReplacedInMiddleOfDocBlock() {
        let input = """
        /// Some docs
        /// TODO: foo
        /// Some more docs
        """
        testFormatting(for: input, rule: .todos, exclude: [.docComments])
    }

    func testTodoNotReplacedAtStartOfDocBlock() {
        let input = """
        /// TODO: foo
        /// Some docs
        """
        testFormatting(for: input, rule: .todos, exclude: [.docComments])
    }

    func testTodoNotReplacedAtEndOfDocBlock() {
        let input = """
        /// Some docs
        /// TODO: foo
        """
        testFormatting(for: input, rule: .todos, exclude: [.docComments])
    }

    func testMarkWithNoSpaceAfterColon() {
        // NOTE: this was an unintended side-effect, but I like it
        let input = "// MARK:foo"
        let output = "// MARK: foo"
        testFormatting(for: input, output, rule: .todos)
    }

    func testMarkInsideMultilineComment() {
        let input = "/* MARK foo */"
        let output = "/* MARK: foo */"
        testFormatting(for: input, output, rule: .todos)
    }

    func testNoExtraSpaceAddedAfterTodo() {
        let input = "/* TODO: */"
        testFormatting(for: input, rule: .todos)
    }

    func testLowercaseMarkColonIsUpdated() {
        let input = "// mark: foo"
        let output = "// MARK: foo"
        testFormatting(for: input, output, rule: .todos)
    }

    func testMixedCaseMarkColonIsUpdated() {
        let input = "// Mark: foo"
        let output = "// MARK: foo"
        testFormatting(for: input, output, rule: .todos)
    }

    func testLowercaseMarkIsNotUpdated() {
        let input = "// mark as read"
        testFormatting(for: input, rule: .todos)
    }

    func testMixedCaseMarkIsNotUpdated() {
        let input = "// Mark as read"
        testFormatting(for: input, rule: .todos)
    }

    func testLowercaseMarkDashIsUpdated() {
        let input = "// mark - foo"
        let output = "// MARK: - foo"
        testFormatting(for: input, output, rule: .todos)
    }

    func testSpaceAddedBeforeMarkDash() {
        let input = "// MARK:- foo"
        let output = "// MARK: - foo"
        testFormatting(for: input, output, rule: .todos)
    }

    func testSpaceAddedAfterMarkDash() {
        let input = "// MARK: -foo"
        let output = "// MARK: - foo"
        testFormatting(for: input, output, rule: .todos)
    }

    func testSpaceAddedAroundMarkDash() {
        let input = "// MARK:-foo"
        let output = "// MARK: - foo"
        testFormatting(for: input, output, rule: .todos)
    }

    func testSpaceNotAddedAfterMarkDashAtEndOfString() {
        let input = "// MARK: -"
        testFormatting(for: input, rule: .todos)
    }
}
