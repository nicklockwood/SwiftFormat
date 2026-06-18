//
//  WrapGuardStatementBodiesTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 6/10/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class WrapGuardStatementBodiesTests: XCTestCase {
    func testGuardReturnWraps() {
        let input = """
        guard let foo = bar else { return }
        """
        let output = """
        guard let foo = bar else {
            return
        }
        """
        testFormatting(for: input, output, rule: .wrapGuardStatementBodies)
    }

    func testEmptyGuardReturnWithSpaceDoesNothing() {
        let input = """
        guard let foo = bar else { }
        """
        testFormatting(for: input, rule: .wrapGuardStatementBodies,
                       exclude: [.emptyBraces])
    }

    func testEmptyGuardReturnWithoutSpaceDoesNothing() {
        let input = """
        guard let foo = bar else {}
        """
        testFormatting(for: input, rule: .wrapGuardStatementBodies,
                       exclude: [.emptyBraces])
    }

    func testGuardReturnWithValueWraps() {
        let input = """
        guard let foo = bar else { return baz }
        """
        let output = """
        guard let foo = bar else {
            return baz
        }
        """
        testFormatting(for: input, output, rule: .wrapGuardStatementBodies)
    }

    func testGuardBodyWithClosingBraceAlreadyOnNewlineWraps() {
        let input = """
        guard foo else { return
        }
        """
        let output = """
        guard foo else {
            return
        }
        """
        testFormatting(for: input, output, rule: .wrapGuardStatementBodies)
    }

    func testGuardContinueWithNoSpacesToCleanupWraps() {
        let input = """
        guard let foo = bar else {continue}
        """
        let output = """
        guard let foo = bar else {
            continue
        }
        """
        testFormatting(for: input, output, rule: .wrapGuardStatementBodies)
    }

    func testGuardReturnWrapsSemicolonDelimitedStatements() {
        let input = """
        guard let foo = bar else { var baz = 0; let boo = 1; fatalError() }
        """
        let output = """
        guard let foo = bar else {
            var baz = 0; let boo = 1; fatalError()
        }
        """
        testFormatting(for: input, output, rule: .wrapGuardStatementBodies)
    }

    func testGuardReturnOnNewlineUnchanged() {
        let input = """
        guard let foo = bar else {
            return
        }
        """
        testFormatting(for: input, rule: .wrapGuardStatementBodies)
    }

    func testGuardCommentSameLineUnchanged() {
        let input = """
        guard let foo = bar else { // Test comment
            return
        }
        """
        testFormatting(for: input, rule: .wrapGuardStatementBodies)
    }

    func testGuardMultilineCommentSameLineWraps() {
        let input = """
        guard let foo = bar else { /* Test comment */ return }
        """
        let output = """
        guard let foo = bar else { /* Test comment */
            return
        }
        """
        testFormatting(for: input, output, rule: .wrapGuardStatementBodies)
    }

    func testNestedGuardElseIfStatementsPutOnNewline() {
        let input = """
        guard let foo = bar else { if qux { return quux } else { return quuz } }
        """
        let output = """
        guard let foo = bar else {
            if qux { return quux } else { return quuz }
        }
        """
        testFormatting(for: input, output, rule: .wrapGuardStatementBodies,
                       exclude: [.wrapIfStatementBodies])
    }

    func testNestedGuardElseGuardStatementPutOnNewline() {
        let input = """
        guard let foo = bar else { guard qux else { return quux } }
        """
        let output = """
        guard let foo = bar else {
            guard qux else {
                return quux
            }
        }
        """
        testFormatting(for: input, output, rule: .wrapGuardStatementBodies)
    }

    func testGuardWithClosureOnlyWrapsElseBody() {
        let input = """
        guard foo { $0.bar } else { return true }
        """
        let output = """
        guard foo { $0.bar } else {
            return true
        }
        """
        testFormatting(for: input, output, rule: .wrapGuardStatementBodies, exclude: [.blankLinesAfterGuardStatements])
    }

    func testGuardElseBraceStartingOnDifferentLine() {
        let input = """
        guard foo else
            { return bar }
        """
        let output = """
        guard foo else
            {
                return bar
            }
        """
        testFormatting(for: input, output, rule: .wrapGuardStatementBodies,
                       exclude: [.braces, .indent, .elseOnSameLine])
    }

    func testDoesNotWrapIfStatementBodies() {
        let input = """
        if foo { return bar }
        """
        testFormatting(for: input, rule: .wrapGuardStatementBodies,
                       exclude: [.wrapIfStatementBodies])
    }
}
