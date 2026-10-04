//
//  ForWhereTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 04/10/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class ForWhereTests: XCTestCase {
    func testMovesSingleIfConditionIntoForWhereClause() {
        let input = """
        for child in visibleChildren {
            if !child.buildPreview(progress) {
                return false
            }
        }
        """
        let output = """
        for child in visibleChildren where !child.buildPreview(progress) {
            return false
        }
        """
        testFormatting(for: input, output, rule: .forWhere)
    }

    func testMovesSingleLineIfConditionIntoForWhereClause() {
        let input = """
        for child in visibleChildren { if child.isVisible { render(child) } }
        """
        let output = """
        for child in visibleChildren where child.isVisible { render(child) }
        """
        let allRulesOutput = """
        for child in visibleChildren where child.isVisible {
            render(child)
        }
        """
        testFormatting(for: input, [output, allRulesOutput], rules: [.forWhere])
    }

    func testJoinsMultipleBooleanConditionsWithAndOperator() {
        let input = """
        for child in visibleChildren {
            if child.isVisible, child.isEnabled {
                render(child)
            }
        }
        """
        let output = """
        for child in visibleChildren where child.isVisible && child.isEnabled {
            render(child)
        }
        """
        testFormatting(for: input, output, rule: .forWhere)
    }

    func testRunsAfterAndOperatorRule() {
        let input = """
        for child in visibleChildren {
            if child.isVisible && child.isEnabled {
                render(child)
            }
        }
        """
        let output = """
        for child in visibleChildren where child.isVisible && child.isEnabled {
            render(child)
        }
        """
        testFormatting(for: input, [output], rules: [.andOperator, .forWhere])
    }

    func testAdjustsIndentationInNestedScope() {
        let input = """
        func renderChildren() {
            for child in visibleChildren {
                if child.isVisible {
                    render(child)
                }
            }
        }
        """
        let output = """
        func renderChildren() {
            for child in visibleChildren where child.isVisible {
                render(child)
            }
        }
        """
        testFormatting(for: input, output, rule: .forWhere)
    }

    func testPreservesCommentsInIfBody() {
        let input = """
        for child in visibleChildren {
            if child.isVisible {
                // Render visible children.
                render(child)
            }
        }
        """
        let output = """
        for child in visibleChildren where child.isVisible {
            // Render visible children.
            render(child)
        }
        """
        testFormatting(for: input, output, rule: .forWhere)
    }

    func testHandlesClosureInForLoopSequence() {
        let input = """
        for child in children.filter({ $0.isVisible }) {
            if child.isEnabled {
                render(child)
            }
        }
        """
        let output = """
        for child in children.filter({ $0.isVisible }) where child.isEnabled {
            render(child)
        }
        """
        testFormatting(for: input, output, rule: .forWhere)
    }

    func testDoesNotChangeForLoopWithExistingWhereClause() {
        let input = """
        for child in visibleChildren where child.isVisible {
            if child.isEnabled {
                render(child)
            }
        }
        """
        testFormatting(for: input, rule: .forWhere)
    }

    func testDoesNotChangeIfWithElseBranch() {
        let input = """
        for child in visibleChildren {
            if child.isVisible {
                render(child)
            } else {
                hide(child)
            }
        }
        """
        testFormatting(for: input, rule: .forWhere)
    }

    func testDoesNotChangeLoopWithStatementBeforeIf() {
        let input = """
        for child in visibleChildren {
            prepare(child)
            if child.isVisible {
                render(child)
            }
        }
        """
        testFormatting(for: input, rule: .forWhere)
    }

    func testDoesNotChangeLoopWithStatementAfterIf() {
        let input = """
        for child in visibleChildren {
            if child.isVisible {
                render(child)
            }
            finish(child)
        }
        """
        testFormatting(for: input, rule: .forWhere)
    }

    func testDoesNotMoveOptionalBindingIntoWhereClause() {
        let input = """
        for child in visibleChildren {
            if let preview = child.preview {
                render(preview)
            }
        }
        """
        testFormatting(for: input, rule: .forWhere)
    }

    func testDoesNotMovePatternMatchingConditionIntoWhereClause() {
        let input = """
        for child in visibleChildren {
            if case let .visible(preview) = child {
                render(preview)
            }
        }
        """
        testFormatting(for: input, rule: .forWhere)
    }

    func testDoesNotMoveAvailabilityConditionIntoWhereClause() {
        let input = """
        for child in visibleChildren {
            if #available(iOS 26, *) {
                render(child)
            }
        }
        """
        testFormatting(for: input, rule: .forWhere)
    }

    func testDoesNotRemoveCommentBeforeIf() {
        let input = """
        for child in visibleChildren {
            // Only render visible children.
            if child.isVisible {
                render(child)
            }
        }
        """
        testFormatting(for: input, rule: .forWhere)
    }

    func testDoesNotMoveCommentedCondition() {
        let input = """
        for child in visibleChildren {
            if /* cached */ child.isVisible {
                render(child)
            }
        }
        """
        testFormatting(for: input, rule: .forWhere)
    }

    func testPreservesCommentInForLoopSequence() {
        let input = """
        for child in /* cached */ visibleChildren {
            if child.isVisible {
                render(child)
            }
        }
        """
        let output = """
        for child in /* cached */ visibleChildren where child.isVisible {
            render(child)
        }
        """
        testFormatting(for: input, output, rule: .forWhere)
    }

    func testDoesNotMoveCommentBetweenSequenceAndLoopBody() {
        let input = """
        for child in visibleChildren /* cached */ {
            if child.isVisible {
                render(child)
            }
        }
        """
        testFormatting(for: input, rule: .forWhere)
    }

    func testDoesNotRemoveCommentAfterIf() {
        let input = """
        for child in visibleChildren {
            if child.isVisible {
                render(child)
            }
            // Finished rendering.
        }
        """
        testFormatting(for: input, rule: .forWhere)
    }

    func testPreservesCommentsOutsideForLoop() {
        let input = """
        // Render the visible children.
        for child in visibleChildren {
            if child.isVisible {
                render(child)
            }
        }

        // Rendering complete.
        """
        let output = """
        // Render the visible children.
        for child in visibleChildren where child.isVisible {
            render(child)
        }

        // Rendering complete.
        """
        testFormatting(for: input, output, rule: .forWhere)
    }

    func testDoesNotMoveMultilineCondition() {
        let input = """
        for child in visibleChildren {
            if child.isVisible,
               child.isEnabled {
                render(child)
            }
        }
        """
        testFormatting(for: input, rule: .forWhere, exclude: [.wrapMultilineStatementBraces])
    }

    func testDoesNotMoveConditionWithTrailingClosure() {
        let input = """
        for child in visibleChildren {
            if child.values.contains { $0.isValid } {
                render(child)
            }
        }
        """
        testFormatting(for: input, rule: .forWhere)
    }

    func testDoesNotChangeMultilineStringIndentation() {
        let input = #"""
        for value in values {
            if value.isValid {
                print("""
                value
                """)
            }
        }
        """#
        testFormatting(for: input, rule: .forWhere)
    }
}
