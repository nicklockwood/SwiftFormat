//
//  WrapConditionalBodiesTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 11/6/21.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class WrapConditionalBodiesTests: XCTestCase {
    func testGuardReturnWraps() {
        let input = "guard let foo = bar else { return }"
        let output = """
        guard let foo = bar else {
            return
        }
        """
        testFormatting(for: input, output, rule: .wrapConditionalBodies)
    }

    func testEmptyGuardReturnWithSpaceDoesNothing() {
        let input = "guard let foo = bar else { }"
        testFormatting(for: input, rule: .wrapConditionalBodies,
                       exclude: [.emptyBraces])
    }

    func testEmptyGuardReturnWithoutSpaceDoesNothing() {
        let input = "guard let foo = bar else {}"
        testFormatting(for: input, rule: .wrapConditionalBodies,
                       exclude: [.emptyBraces])
    }

    func testGuardReturnWithValueWraps() {
        let input = "guard let foo = bar else { return baz }"
        let output = """
        guard let foo = bar else {
            return baz
        }
        """
        testFormatting(for: input, output, rule: .wrapConditionalBodies)
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
        testFormatting(for: input, output, rule: .wrapConditionalBodies)
    }

    func testGuardContinueWithNoSpacesToCleanupWraps() {
        let input = "guard let foo = bar else {continue}"
        let output = """
        guard let foo = bar else {
            continue
        }
        """
        testFormatting(for: input, output, rule: .wrapConditionalBodies)
    }

    func testGuardReturnWrapsSemicolonDelimitedStatements() {
        let input = "guard let foo = bar else { var baz = 0; let boo = 1; fatalError() }"
        let output = """
        guard let foo = bar else {
            var baz = 0; let boo = 1; fatalError()
        }
        """
        testFormatting(for: input, output, rule: .wrapConditionalBodies)
    }

    func testGuardReturnWrapsSemicolonDelimitedStatementsWithNoSpaces() {
        let input = "guard let foo = bar else {var baz=0;let boo=1;fatalError()}"
        let output = """
        guard let foo = bar else {
            var baz=0;let boo=1;fatalError()
        }
        """
        testFormatting(for: input, output, rule: .wrapConditionalBodies,
                       exclude: [.spaceAroundOperators])
    }

    func testGuardReturnOnNewlineUnchanged() {
        let input = """
        guard let foo = bar else {
            return
        }
        """
        testFormatting(for: input, rule: .wrapConditionalBodies)
    }

    func testGuardCommentSameLineUnchanged() {
        let input = """
        guard let foo = bar else { // Test comment
            return
        }
        """
        testFormatting(for: input, rule: .wrapConditionalBodies)
    }

    func testGuardMultilineCommentSameLineUnchanged() {
        let input = "guard let foo = bar else { /* Test comment */ return }"
        let output = """
        guard let foo = bar else { /* Test comment */
            return
        }
        """
        testFormatting(for: input, output, rule: .wrapConditionalBodies)
    }

    func testGuardTwoMultilineCommentsSameLine() {
        let input = "guard let foo = bar else { /* Test comment 1 */ return /* Test comment 2 */ }"
        let output = """
        guard let foo = bar else { /* Test comment 1 */
            return /* Test comment 2 */
        }
        """
        testFormatting(for: input, output, rule: .wrapConditionalBodies)
    }

    func testNestedGuardElseIfStatementsPutOnNewline() {
        let input = "guard let foo = bar else { if qux { return quux } else { return quuz } }"
        let output = """
        guard let foo = bar else {
            if qux {
                return quux
            } else {
                return quuz
            }
        }
        """
        testFormatting(for: input, output, rule: .wrapConditionalBodies)
    }

    func testNestedGuardElseGuardStatementPutOnNewline() {
        let input = "guard let foo = bar else { guard qux else { return quux } }"
        let output = """
        guard let foo = bar else {
            guard qux else {
                return quux
            }
        }
        """
        testFormatting(for: input, output, rule: .wrapConditionalBodies)
    }

    func testGuardWithClosureOnlyWrapsElseBody() {
        let input = "guard foo { $0.bar } else { return true }"
        let output = """
        guard foo { $0.bar } else {
            return true
        }
        """
        testFormatting(for: input, output, rule: .wrapConditionalBodies, exclude: [.blankLinesAfterGuardStatements])
    }

    func testIfElseReturnsWrap() {
        let input = "if foo { return bar } else if baz { return qux } else { return quux }"
        let output = """
        if foo {
            return bar
        } else if baz {
            return qux
        } else {
            return quux
        }
        """
        testFormatting(for: input, output, rule: .wrapConditionalBodies)
    }

    func testIfElseBodiesWrap() {
        let input = "if foo { bar } else if baz { qux } else { quux }"
        let output = """
        if foo {
            bar
        } else if baz {
            qux
        } else {
            quux
        }
        """
        testFormatting(for: input, output, rule: .wrapConditionalBodies)
    }

    func testIfElsesWithClosuresDontWrapClosures() {
        let input = "if foo { $0.bar } { baz } else if qux { $0.quux } { quuz } else { corge }"
        let output = """
        if foo { $0.bar } {
            baz
        } else if qux { $0.quux } {
            quuz
        } else {
            corge
        }
        """
        testFormatting(for: input, output, rule: .wrapConditionalBodies)
    }

    func testEmptyIfElseBodiesWithSpaceDoNothing() {
        let input = "if foo { } else if baz { } else { }"
        testFormatting(for: input, rule: .wrapConditionalBodies,
                       exclude: [.emptyBraces])
    }

    func testEmptyIfElseBodiesWithoutSpaceDoNothing() {
        let input = "if foo {} else if baz {} else {}"
        testFormatting(for: input, rule: .wrapConditionalBodies,
                       exclude: [.emptyBraces])
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

        testFormatting(for: input, output, rule: .wrapConditionalBodies,
                       exclude: [.braces, .indent, .elseOnSameLine])
    }

    func testIfElseBracesStartingOnDifferentLines() {
        let input = """
        if foo
            { return bar }
        else if baz
            { return qux }
        else
            { return quux }
        """
        let output = """
        if foo
            {
                return bar
            }
        else if baz
            {
                return qux
            }
        else
            {
                return quux
            }
        """
        testFormatting(for: input, output, rule: .wrapConditionalBodies,
                       exclude: [.braces, .indent, .elseOnSameLine])
    }

    func testInsideStringLiteralDoesNothing() {
        let input = """
        "\\(list.map { if $0 % 2 == 0 { return 0 } else { return 1 } })"
        """
        testFormatting(for: input, rule: .wrapConditionalBodies)
    }

    func testInsideMultilineStringLiteral() {
        let input = """
        let foo = \"""
        \\(list.map { if $0 % 2 == 0 { return 0 } else { return 1 } })
        \"""
        """
        let output = """
        let foo = \"""
        \\(list.map { if $0 % 2 == 0 {
            return 0
        } else {
            return 1
        } })
        \"""
        """
        testFormatting(for: input, output, rule: .wrapConditionalBodies)
    }
}
