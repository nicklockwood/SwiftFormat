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
    func testFlatteningElseEnablesConditionalReturnExpression() {
        let input = """
        func getValue(value: Int?, error: SampleError?) throws(SampleError) -> Int {
            if let value {
                return value
            } else {
                if let error {
                    throw error
                } else {
                    throw .unavailable
                }
            }
        }
        """
        let output = """
        func getValue(value: Int?, error: SampleError?) throws(SampleError) -> Int {
            if let value {
                value
            } else if let error {
                throw error
            } else {
                throw .unavailable
            }
        }
        """
        // Initialize the rule registry so dependency ordering is set even when this test runs in isolation.
        let rules = FormatRules.named(["ifExpressions", "conditionalAssignment", "redundantReturn", "nestedIf"])
        var options = FormatOptions(swiftVersion: "6.0")
        options.enabledRules = Set(rules.map(\.name))
        // Verify conversion in one pass, without relying on the formatter's repeated passes.
        let formatter = Formatter(tokenize(input), options: options)
        for rule in rules.sorted() {
            rule.apply(with: formatter)
        }
        XCTAssertEqual(sourceCode(for: formatter.tokens), output)
        testFormatting(for: input, [output], rules: rules, options: options)
    }

    func testFlattensElseWithThrowingIf() {
        let input = """
        if let value {
            return value // Keep this comment
        } else {
            if let error {
                throw error
            } else {
                throw .unavailable
            }
        }
        """
        let output = """
        if let value {
            return value // Keep this comment
        } else if let error {
            throw error
        } else {
            throw .unavailable
        }
        """
        testFormatting(for: input, output, rule: .nestedIf)
    }

    func testFlattensRepeatedElseIf() {
        let input = """
        if first {
            one()
        } else if second {
            two()
        } else {
            if third {
                // Preserve the branch comment
                three()
            } else {
                if fourth {
                    four()
                }
            }
        }
        """
        let output = """
        if first {
            one()
        } else if second {
            two()
        } else if third {
            // Preserve the branch comment
            three()
        } else if fourth {
            four()
        }
        """
        testFormatting(for: input, output, rule: .nestedIf)
    }

    func testPreservesElseWithLeadingComment() {
        let input = """
        if first {
            one()
        } else {
            // Explain the fallback
            if second {
                two()
            }
        }
        """
        testFormatting(for: input, rule: .nestedIf)
    }

    func testPreservesElseWithTrailingComment() {
        let input = """
        if first {
            one()
        } else {
            if second {
                two()
            }
            // Explain the end
        }
        """
        testFormatting(for: input, rule: .nestedIf)
    }

    func testPreservesElseWithOtherStatement() {
        let input = """
        if first {
            one()
        } else {
            if second {
                two()
            }
            finish()
        }
        """
        testFormatting(for: input, rule: .nestedIf)
    }

    func testPreservesElseWithDeclaration() {
        let input = """
        if first {
            one()
        } else {
            let second = enabled
            if second {
                two()
            }
        }
        """
        testFormatting(for: input, rule: .nestedIf)
    }

    func testPreservesElseIfInResultBuilder() {
        let input = """
        @ViewBuilder var body: some View {
            if first {
                Text("one")
            } else {
                if second {
                    Text("two")
                }
            }
        }
        """
        testFormatting(for: input, rule: .nestedIf)
    }

    func testPreservesNestedElseInIfExpression() {
        let input = """
        let value =
            if first {
                1
            } else {
                if second {
                    2
                } else {
                    3
                }
            }
        """
        testFormatting(for: input, rule: .nestedIf, options: FormatOptions(swiftVersion: "5.9"))
    }

    func testPreservesGuardElseIf() {
        let input = """
        guard first else {
            if second {
                two()
            }
            return
        }
        """
        testFormatting(for: input, rule: .nestedIf)
    }

    func testFlattensElseIfWithWrappedConditions() {
        let input = """
        if first {
            one()
        } else {
            if second,
               third
            {
                two()
            }
        }
        """
        let output = """
        if first {
            one()
        } else if second,
                  third
        {
            two()
        }
        """
        testFormatting(for: input, [output], rules: [.nestedIf, .indent])
    }

    func testPreservesElseIfWithFormattingDirective() {
        let input = """
        if first {
            one()
        } else {
            if second {
                // swiftformat:disable:next redundantSelf
                self.two()
            }
        }
        """
        testFormatting(for: input, rule: .nestedIf)
    }

    func testPreservesElseIfContainingMultilineString() {
        let input = #"""
        if first {
            one()
        } else {
            if second {
                print("""
                two
                """)
            }
        }
        """#
        testFormatting(for: input, rule: .nestedIf)
    }

    func testDoesNotWrapForLinebreaksInsideClosure() {
        let input = """
        if values.contains(where: {
            $0.isValid
        }) {
            if isEnabled {
                performAction()
            }
        }
        """
        let output = """
        if values.contains(where: {
            $0.isValid
        }), isEnabled {
            performAction()
        }
        """
        testFormatting(for: input, output, rule: .nestedIf)
    }

    func testMergesConditionsWithFirstWrapped() {
        let input = """
        if isValid,
           isAuthorized {
            if isEnabled {
                performAction()
            }
        }
        """
        let output = """
        if isValid,
           isAuthorized,
           isEnabled
        {
            performAction()
        }
        """
        testFormatting(for: input, [output], rules: [.nestedIf, .wrapMultilineStatementBraces, .elseOnSameLine])
    }

    func testMergesConditionsWithSecondWrapped() {
        let input = """
        if isValid {
            if isEnabled,
               isAuthorized {
                performAction()
            }
        }
        """
        let output = """
        if isValid,
           isEnabled,
           isAuthorized
        {
            performAction()
        }
        """
        testFormatting(for: input, [output], rules: [.nestedIf, .wrapMultilineStatementBraces, .elseOnSameLine])
    }

    func testMergesConditionsWithBothWrapped() {
        let input = """
        if isValid,
           isAuthorized {
            if isEnabled,
               isReady {
                performAction()
            }
        }
        """
        let output = """
        if isValid,
           isAuthorized,
           isEnabled,
           isReady
        {
            performAction()
        }
        """
        testFormatting(for: input, [output], rules: [.nestedIf, .wrapMultilineStatementBraces, .elseOnSameLine])
    }

    func testMergesConditionsWithBeforeFirst() {
        let input = """
        if
            isValid,
            isAuthorized {
            if isEnabled {
                performAction()
            }
        }
        """
        let output = """
        if
            isValid,
            isAuthorized,
            isEnabled
        {
            performAction()
        }
        """
        testFormatting(for: input, [output], rules: [.nestedIf, .wrapMultilineStatementBraces, .elseOnSameLine])
    }

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
        if isValid,
           isEnabled,
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
