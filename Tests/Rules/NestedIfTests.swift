//
//  NestedIfTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 10/3/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class NestedIfTests: XCTestCase {
    func testMergesNestedIfStatements() {
        let input = """
        if isValid {
            if isEnabled {
                performAction()
            }
        }
        """
        let output = """
        if isValid, isEnabled {
            performAction()
        }
        """
        testFormatting(for: input, output, rule: .nestedIf)
    }

    func testMergesMoreThanTwoNestedIfStatements() {
        let input = """
        if isValid {
            if isEnabled {
                if isAuthorized {
                    performAction()
                }
            }
        }
        """
        let output = """
        if isValid, isEnabled, isAuthorized {
            performAction()
        }
        """
        testFormatting(for: input, output, rule: .nestedIf)
    }

    func testMergesDependentOptionalBindings() {
        let input = """
        if let user {
            if let account = user.account {
                show(account)
            }
        }
        """
        let output = """
        if let user, let account = user.account {
            show(account)
        }
        """
        testFormatting(for: input, output, rule: .nestedIf)
    }

    func testMergesSingleLineNestedIfStatements() {
        let input = """
        if isValid { if isEnabled { performAction() } }
        """
        let output = """
        if isValid, isEnabled { performAction() }
        """
        testFormatting(for: input, output, rule: .nestedIf)
    }

    func testMergesMultilineNestedIfConditions() {
        let input = """
        if isValid {
            if isEnabled,
               isAuthorized {
                performAction()
            }
        }
        """
        let output = """
        if isValid, isEnabled,
           isAuthorized {
            performAction()
        }
        """
        testFormatting(
            for: input,
            output,
            rule: .nestedIf,
            exclude: [.wrapMultilineStatementBraces]
        )
    }

    func testPreservesCommentsInNestedBody() {
        let input = """
        if isValid {
            if isEnabled {
                // Enabling may perform additional work.
                performAction()
            }
        }
        """
        let output = """
        if isValid, isEnabled {
            // Enabling may perform additional work.
            performAction()
        }
        """
        testFormatting(for: input, output, rule: .nestedIf)
    }

    func testDoesNotMergeIfOuterStatementHasElseBranch() {
        let input = """
        if isValid {
            if isEnabled {
                performAction()
            }
        } else {
            handleInvalidState()
        }
        """
        testFormatting(for: input, rule: .nestedIf)
    }

    func testDoesNotMergeIfNestedStatementHasElseBranch() {
        let input = """
        if isValid {
            if isEnabled {
                performAction()
            } else {
                handleDisabledState()
            }
        }
        """
        testFormatting(for: input, rule: .nestedIf)
    }

    func testDoesNotMergeIfOuterBodyHasAnotherStatement() {
        let input = """
        if isValid {
            prepare()
            if isEnabled {
                performAction()
            }
        }
        """
        testFormatting(for: input, rule: .nestedIf)
    }

    func testMovesCommentBeforeNestedIfToCondition() {
        let input = """
        if isValid {
            // Enabling may perform additional work.
            if isEnabled {
                performAction()
            }
        }
        """
        let output = """
        if isValid,
           // Enabling may perform additional work.
           isEnabled
        {
            performAction()
        }
        """
        testFormatting(for: input, output, rule: .nestedIf)
    }

    func testPreservesCommentBeforeOuterIf() {
        let input = """
        // Only perform the action when both conditions are met.
        if isValid {
            if isEnabled {
                performAction()
            }
        }
        """
        let output = """
        // Only perform the action when both conditions are met.
        if isValid, isEnabled {
            performAction()
        }
        """
        testFormatting(for: input, output, rule: .nestedIf)
    }

    func testPreservesCommentsBeforeOuterAndNestedIf() {
        let input = """
        // The value must be valid.
        if isValid {
            // The feature must be enabled.
            if isEnabled {
                performAction()
            }
        }
        """
        let output = """
        // The value must be valid.
        if isValid,
           // The feature must be enabled.
           isEnabled
        {
            performAction()
        }
        """
        testFormatting(for: input, output, rule: .nestedIf)
    }

    func testMovesMultipleCommentsBeforeNestedIfToCondition() {
        let input = """
        if isValid {
            // The feature must be enabled.
            // Enabling may perform additional work.
            if isEnabled {
                performAction()
            }
        }
        """
        let output = """
        if isValid,
           // The feature must be enabled.
           // Enabling may perform additional work.
           isEnabled
        {
            performAction()
        }
        """
        testFormatting(for: input, output, rule: .nestedIf)
    }

    func testMovesCommentsAtMultipleNestingLevelsToConditions() {
        let input = """
        if isValid {
            // The feature must be enabled.
            if isEnabled {
                // The user must be authorized.
                if isAuthorized {
                    performAction()
                }
            }
        }
        """
        let output = """
        if isValid,
           // The feature must be enabled.
           isEnabled,
           // The user must be authorized.
           isAuthorized
        {
            performAction()
        }
        """
        testFormatting(for: input, output, rule: .nestedIf)
    }

    func testPreservesTrailingCommentInOuterBody() {
        let input = """
        if isValid {
            if isEnabled {
                performAction()
            }
            // End validation.
        }
        """
        let output = """
        if isValid, isEnabled {
            performAction()
            // End validation.
        }
        """
        testFormatting(for: input, output, rule: .nestedIf)
    }

    func testPreservesTrailingCommentAfterNestedClosingBrace() {
        let input = """
        if isValid {
            if isEnabled {
                performAction()
            } // End validation.
        }
        """
        let output = """
        if isValid, isEnabled {
            performAction()
            // End validation.
        }
        """
        testFormatting(for: input, output, rule: .nestedIf)
    }

    func testMergesIfConditionsThatRedeclareBinding() {
        let input = """
        if let value = firstValue {
            if let value = transform(value) {
                print(value)
            }
        }
        """
        let output = """
        if let value = firstValue, let value = transform(value) {
            print(value)
        }
        """
        testFormatting(for: input, output, rule: .nestedIf)
    }

    func testMergesPatternMatchingConditions() {
        let input = """
        if case let .success(value) = result {
            if case let .success(otherValue) = otherResult {
                print(value, otherValue)
            }
        }
        """
        let output = """
        if case let .success(value) = result, case let .success(otherValue) = otherResult {
            print(value, otherValue)
        }
        """
        testFormatting(for: input, output, rule: .nestedIf)
    }

    func testDoesNotMergeNestedIfInResultBuilder() {
        let input = """
        @ViewBuilder var body: some View {
            if isValid {
                if isEnabled {
                    Text("Enabled")
                }
            }
        }
        """
        testFormatting(for: input, rule: .nestedIf)
    }

    func testDoesNotMergeNestedIfContainingMultilineString() {
        let input = #"""
        if isValid {
            if isEnabled {
                let message = """
                Enabled
                """
                print(message)
            }
        }
        """#
        testFormatting(for: input, rule: .nestedIf)
    }
}
