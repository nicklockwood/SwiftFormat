//
//  IfCaseTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 10/23/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class IfCaseTests: XCTestCase {
    func testSingleIfCase() {
        let input = """
        if case let .success(value) = result {
            print(value)
        }
        """
        let output = """
        switch result {
        case let .success(value):
            print(value)
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: .ifCase)
    }

    func testIfCaseElse() {
        let input = """
        if case .loading = state {
            showSpinner()
        } else {
            hideSpinner()
        }
        """
        let output = """
        switch state {
        case .loading:
            showSpinner()
        default:
            hideSpinner()
        }
        """
        testFormatting(for: input, output, rule: .ifCase)
    }

    func testElseIfCaseWithoutElse() {
        let input = """
        if case .loading = state {
            showSpinner()
        } else if case let .loaded(value) = state {
            show(value)
        }
        """
        let output = """
        switch state {
        case .loading:
            showSpinner()
        case let .loaded(value):
            show(value)
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: .ifCase)
    }

    func testElseIfCaseWithElse() {
        let input = """
        if case .loading = state {
            showSpinner()
        } else if case let .loaded(value) = state {
            show(value)
        } else if case let .failed(error) = state {
            show(error)
        } else {
            reset()
        }
        """
        let output = """
        switch state {
        case .loading:
            showSpinner()
        case let .loaded(value):
            show(value)
        case let .failed(error):
            show(error)
        default:
            reset()
        }
        """
        testFormatting(for: input, output, rule: .ifCase)
    }

    func testIfCaseExpression() {
        let input = """
        let value =
            if case let .success(value) = result {
                value
            } else {
                fallback
            }
        """
        let output = """
        let value =
            switch result {
            case let .success(value):
                value
            default:
                fallback
            }
        """
        testFormatting(for: input, output, rule: .ifCase, options: FormatOptions(swiftVersion: "5.9"))
    }

    func testIfCaseElseIfExpression() {
        let input = """
        func describe(_ state: State) -> String {
            if case .loading = state {
                "Loading"
            } else if case .loaded = state {
                "Loaded"
            } else {
                "Unknown"
            }
        }
        """
        let output = """
        func describe(_ state: State) -> String {
            switch state {
            case .loading:
                "Loading"
            case .loaded:
                "Loaded"
            default:
                "Unknown"
            }
        }
        """
        testFormatting(for: input, output, rule: .ifCase, options: FormatOptions(swiftVersion: "5.9"))
    }

    func testSingleLineBranches() {
        let input = """
        if case .loading = state { showSpinner() } else { hideSpinner() }
        """
        let output = """
        switch state {
        case .loading:
            showSpinner()
        default:
            hideSpinner()
        }
        """
        testFormatting(for: input, output, rule: .ifCase)
    }

    func testEmptyBranches() {
        let input = """
        if case .loading = state {} else if case .loaded = state {} else {}
        """
        let output = """
        switch state {
        case .loading:
            break
        case .loaded:
            break
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: .ifCase)
    }

    func testEmptySingleIfCase() {
        let input = """
        if case .loading = state {}
        """
        let output = """
        switch state {
        case .loading:
            break
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: .ifCase)
    }

    func testPreservesBodyComments() {
        let input = """
        if case let .success(value) = result {
            // Keep this comment.
            print(value) // And this one.
        } else {
            // Nothing to do.
        }
        """
        let output = """
        switch result {
        case let .success(value):
            // Keep this comment.
            print(value) // And this one.
        default:
            // Nothing to do.
            break
        }
        """
        testFormatting(for: input, output, rule: .ifCase)
    }

    func testTuplePattern() {
        let input = """
        if case let (.some(first), .some(second)) = pair {
            print(first, second)
        }
        """
        let output = """
        switch pair {
        case let (.some(first), .some(second)):
            print(first, second)
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: .ifCase)
    }

    func testOptionalPatternAndFunctionSubject() {
        let input = """
        if case let value? = fetchValue() {
            print(value)
        }
        """
        let output = """
        switch fetchValue() {
        case let value?:
            print(value)
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: .ifCase)
    }

    func testNestedIfCase() {
        let input = """
        if case let .success(value) = result {
            if case .ready = value.state {
                process(value)
            }
        }
        """
        let output = """
        switch result {
        case let .success(value):
            switch value.state {
            case .ready:
                process(value)
            default:
                break
            }
        default:
            break
        }
        """
        let outputWithSpacing = output.replacingOccurrences(of: "\n    }\ndefault:", with: "\n    }\n\ndefault:")
        testFormatting(for: input, [output, outputWithSpacing], rules: [.ifCase])
    }

    func testConsecutiveIfCases() {
        let input = """
        if case .loading = state {
            showSpinner()
        }

        if case .loaded = state {
            hideSpinner()
        }
        """
        let output = """
        switch state {
        case .loading:
            showSpinner()
        default:
            break
        }

        switch state {
        case .loaded:
            hideSpinner()
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: .ifCase)
    }

    func testIndentedCases() {
        let input = """
        for result in results {
            if case let .success(value) = result {
                if value.isValid {
                    print(value)
                }
            } else {
                retry()
            }
        }
        """
        let output = """
        for result in results {
            switch result {
                case let .success(value):
                    if value.isValid {
                        print(value)
                    }
                default:
                    retry()
            }
        }
        """
        let outputWithSpacing = output.replacingOccurrences(of: "\n        default:", with: "\n\n        default:")
        testFormatting(for: input, [output, outputWithSpacing], rules: [.ifCase], options: FormatOptions(indentCase: true))
    }

    func testContinueInLoop() {
        let input = """
        for state in states {
            if case .loading = state {
                continue
            }
            process(state)
        }
        """
        let output = """
        for state in states {
            switch state {
            case .loading:
                continue
            default:
                break
            }
            process(state)
        }
        """
        testFormatting(for: input, output, rule: .ifCase)
    }

    func testLabeledBreakInLoop() {
        let input = """
        outer: for state in states {
            if case .loading = state {
                break outer
            }
        }
        """
        let output = """
        outer: for state in states {
            switch state {
            case .loading:
                break outer
            default:
                break
            }
        }
        """
        testFormatting(for: input, output, rule: .ifCase)
    }

    func testBreakInNestedLoop() {
        let input = """
        if case let .success(values) = result {
            for value in values where value.isValid {
                break
            }
        }
        """
        let output = """
        switch result {
        case let .success(values):
            for value in values where value.isValid {
                break
            }
        default:
            break
        }
        """
        let outputWithSpacing = output.replacingOccurrences(of: "\n    }\ndefault:", with: "\n    }\n\ndefault:")
        testFormatting(for: input, [output, outputWithSpacing], rules: [.ifCase])
    }

    func testDoesNotConvertBooleanCondition() {
        let input = """
        if isLoading {
            showSpinner()
        }
        """
        testFormatting(for: input, rule: .ifCase)
    }

    func testDoesNotConvertMixedConditions() {
        let input = """
        if case let .success(value) = result, value.isValid {
            print(value)
        }
        """
        testFormatting(for: input, rule: .ifCase)
    }

    func testDoesNotConvertMixedElseIfCondition() {
        let input = """
        if case .loading = state {
            showSpinner()
        } else if isReady {
            showContent()
        } else if case .loaded = state {
            hideSpinner()
        }
        """
        testFormatting(for: input, rule: .ifCase)
    }

    func testDoesNotConvertElseIfAfterBooleanCondition() {
        let input = """
        if isReady {
            showContent()
        } else if case .loading = state {
            showSpinner()
        }
        """
        testFormatting(for: input, rule: .ifCase)
    }

    func testDoesNotConvertMultipleCaseConditions() {
        let input = """
        if case .loading = state, case .ready = otherState {
            showSpinner()
        }
        """
        testFormatting(for: input, rule: .ifCase)
    }

    func testDoesNotConvertDifferentSubjects() {
        let input = """
        if case .loading = state {
            showSpinner()
        } else if case .loaded = otherState {
            hideSpinner()
        }
        """
        testFormatting(for: input, rule: .ifCase)
    }

    func testDoesNotMergeRepeatedCalls() {
        let input = """
        if case .loading = fetchState() {
            showSpinner()
        } else if case .loaded = fetchState() {
            hideSpinner()
        }
        """
        testFormatting(for: input, rule: .ifCase)
    }

    func testDoesNotRedirectLoopBreak() {
        let input = """
        for state in states {
            if case .loading = state {
                break
            }
        }
        """
        testFormatting(for: input, rule: .ifCase)
    }

    func testDoesNotRedirectNestedConditionalBreak() {
        let input = """
        for state in states {
            if case .loading = state {
                if shouldStop {
                    break
                }
            }
        }
        """
        testFormatting(for: input, rule: .ifCase)
    }

    func testDoesNotRedirectElseBreak() {
        let input = """
        for state in states {
            if case .loading = state {
                showSpinner()
            } else {
                break
            }
        }
        """
        testFormatting(for: input, rule: .ifCase)
    }

    func testDoesNotRedirectSwitchBreak() {
        let input = """
        switch outerState {
        case .ready:
            if case .loading = state {
                break
            }
            process(state)

        default:
            break
        }
        """
        testFormatting(for: input, rule: .ifCase)
    }

    func testDoesNotRemoveHeaderComments() {
        let input = """
        if case .loading = state /* keep this */ {
            showSpinner()
        }
        """
        testFormatting(for: input, rule: .ifCase)
    }

    func testDoesNotRemoveCommentsBetweenBranches() {
        let input = """
        if case .loading = state {
            showSpinner()
        }
        // Keep this comment.
        else {
            hideSpinner()
        }
        """
        testFormatting(for: input, rule: .ifCase, exclude: [.elseOnSameLine])
    }

    func testDoesNotConvertNonexhaustiveResultBuilder() {
        let input = """
        var body: some View {
            if case .loading = state {
                ProgressView()
            }
        }
        """
        testFormatting(for: input, rule: .ifCase)
    }

    func testIfCaseInSingleLineString() {
        let input = #"""
        let description = "Value: \(if case .loading = state { "Loading" } else { "Ready" })"
        """#
        testFormatting(for: input, rule: .ifCase, options: FormatOptions(swiftVersion: "5.9"))
    }

    func testDoesNotRedirectBreakBeforeAnotherStatement() {
        let input = """
        for state in states {
            if case .loading = state {
                break
                process(state)
            }
        }
        """
        testFormatting(for: input, rule: .ifCase)
    }

    func testExhaustiveResultBuilder() {
        let input = """
        var body: some View {
            if case .loading = state {
                ProgressView()
            } else {
                Text("Ready")
            }
        }
        """
        let output = """
        var body: some View {
            switch state {
            case .loading:
                ProgressView()
            default:
                Text("Ready")
            }
        }
        """
        testFormatting(for: input, output, rule: .ifCase)
    }

    func testIfCaseInFunctionReturningBool() {
        let input = """
        func isLoading(_ state: State) -> Bool {
            if case .loading = state {
                return true
            }
            return false
        }
        """
        let output = """
        func isLoading(_ state: State) -> Bool {
            switch state {
            case .loading:
                return true
            default:
                return false
            }
        }
        """
        testFormatting(for: input, output, rule: .ifCase)
    }

    func testDoesNotRedirectConditionallyCompiledBreak() {
        let input = """
        for state in states {
            if case .loading = state {
                #if DEBUG
                    process(state)
                #else
                    break
                #endif
            }
        }
        """
        testFormatting(for: input, rule: .ifCase)
    }

    func testDoesNotConvertResultBuilderWithEmptyElse() {
        let input = """
        @ViewBuilder
        func content() -> some View {
            if case .loading = state {
                ProgressView()
            } else {}
        }
        """
        testFormatting(for: input, rule: .ifCase)
    }

    func testDoesNotConvertTypedPattern() {
        let input = """
        if case let value: Any = number {
            print(value)
        }
        """
        testFormatting(for: input, rule: .ifCase)
    }

    func testLabeledAssociatedValue() {
        let input = """
        if case let .loaded(value: value) = state {
            show(value)
        }
        """
        let output = """
        switch state {
        case let .loaded(value: value):
            show(value)
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: .ifCase)
    }

    func testTrailingReturnInComputedPropertyWithRedundantReturn() {
        let input = """
        var isUnique: Bool {
            if case let .unique(bool) = metadata {
                return bool
            }
            return false
        }
        """
        let output = """
        var isUnique: Bool {
            switch metadata {
            case let .unique(bool):
                bool
            default:
                false
            }
        }
        """
        testFormatting(for: input, [output], rules: [.ifCase, .redundantReturn], options: FormatOptions(swiftVersion: "5.9"))
    }

    func testTrailingReturnAfterEarlierStatement() {
        let input = """
        func isRecognized(_ error: Error) -> Bool {
            if error is UITestError {
                return true
            }
            if case UIHelperError.uiElementNotFound = error {
                return true
            }
            return false
        }
        """
        let output = """
        func isRecognized(_ error: Error) -> Bool {
            if error is UITestError {
                return true
            }
            switch error {
            case UIHelperError.uiElementNotFound:
                return true
            default:
                return false
            }
        }
        """
        testFormatting(for: input, [output], rules: [.ifCase, .redundantReturn], options: FormatOptions(swiftVersion: "5.9"))
    }

    func testTrailingReturnWithMultipleReturningCases() {
        let input = """
        func describe(_ state: State) -> String {
            if case let .loaded(value) = state {
                log(value)
                return value.description
            } else if case let .failed(error) = state {
                return error.description
            }
            return "Loading"
        }
        """
        let output = """
        func describe(_ state: State) -> String {
            switch state {
            case let .loaded(value):
                log(value)
                return value.description
            case let .failed(error):
                return error.description
            default:
                return "Loading"
            }
        }
        """
        let outputWithSpacing = output
            .replacingOccurrences(of: "\n    case let .failed", with: "\n\n    case let .failed")
            .replacingOccurrences(of: "\n    default:", with: "\n\n    default:")
        testFormatting(for: input, [output, outputWithSpacing], rules: [.ifCase])
    }

    func testTrailingReturnWithCommentsAndMultilineExpression() {
        let input = """
        func describe(_ state: State) -> String {
            if case let .loaded(value) = state {
                return value.description
            }
            // Explain the fallback.
            return describe(
                state,
                fallback: true
            ) // Keep this comment.
        }
        """
        let output = """
        func describe(_ state: State) -> String {
            switch state {
            case let .loaded(value):
                return value.description
            default:
                // Explain the fallback.
                return describe(
                    state,
                    fallback: true
                ) // Keep this comment.
            }
        }
        """
        testFormatting(for: input, output, rule: .ifCase)
    }

    func testDoesNotAbsorbReturnWhenCaseFallsThrough() {
        let input = """
        func isLoading(_ state: State) -> Bool {
            if case .loading = state {
                showSpinner()
            }
            return false
        }
        """
        let output = """
        func isLoading(_ state: State) -> Bool {
            switch state {
            case .loading:
                showSpinner()
            default:
                break
            }
            return false
        }
        """
        testFormatting(for: input, output, rule: .ifCase)
    }

    func testDoesNotAbsorbReturnWhenOnlySomeCasesReturn() {
        let input = """
        func isLoading(_ state: State) -> Bool {
            if case .loading = state {
                return true
            } else if case .loaded = state {
                hideSpinner()
            }
            return false
        }
        """
        let output = """
        func isLoading(_ state: State) -> Bool {
            switch state {
            case .loading:
                return true
            case .loaded:
                hideSpinner()
            default:
                break
            }
            return false
        }
        """
        testFormatting(for: input, output, rule: .ifCase)
    }

    func testDoesNotAbsorbReturnWhenBranchOnlyConditionallyReturns() {
        let input = """
        func isLoading(_ state: State) -> Bool {
            if case .loading = state {
                if isReady {
                    return true
                }
            }
            return false
        }
        """
        let output = """
        func isLoading(_ state: State) -> Bool {
            switch state {
            case .loading:
                if isReady {
                    return true
                }
            default:
                break
            }
            return false
        }
        """
        let outputWithSpacing = output.replacingOccurrences(of: "\n    default:", with: "\n\n    default:")
        testFormatting(for: input, [output, outputWithSpacing], rules: [.ifCase])
    }

    func testDoesNotAbsorbReturnFollowedByAnotherStatement() {
        let input = """
        func isLoading(_ state: State) -> Bool {
            if case .loading = state {
                return true
            }
            return false
            log(state)
        }
        """
        let output = """
        func isLoading(_ state: State) -> Bool {
            switch state {
            case .loading:
                return true
            default:
                break
            }
            return false
            log(state)
        }
        """
        testFormatting(for: input, output, rule: .ifCase)
    }

    func testTrailingReturnInSubscriptWithRedundantReturn() {
        let input = """
        subscript(_ metadata: Metadata) -> Bool {
            if case let .unique(bool) = metadata {
                return bool
            }
            return false
        }
        """
        let output = """
        subscript(_ metadata: Metadata) -> Bool {
            switch metadata {
            case let .unique(bool):
                bool
            default:
                false
            }
        }
        """
        testFormatting(for: input, [output], rules: [.ifCase, .redundantReturn], options: FormatOptions(swiftVersion: "5.9"))
    }

    func testTrailingReturnInFunctionBeforeSwitchExpressions() {
        let input = """
        func isUnique(_ metadata: Metadata) -> Bool {
            if case let .unique(bool) = metadata {
                return bool
            }
            return false
        }
        """
        let output = """
        func isUnique(_ metadata: Metadata) -> Bool {
            switch metadata {
            case let .unique(bool):
                return bool
            default:
                return false
            }
        }
        """
        testFormatting(for: input, [output], rules: [.ifCase, .redundantReturn], options: FormatOptions(swiftVersion: "5.8"))
    }

    func testTrailingReturnWithIndentedCases() {
        let input = """
        func isUnique(_ metadata: Metadata) -> Bool {
            if case let .unique(bool) = metadata {
                return bool
            }
            return check(
                metadata
            )
        }
        """
        let output = """
        func isUnique(_ metadata: Metadata) -> Bool {
            switch metadata {
                case let .unique(bool):
                    return bool
                default:
                    return check(
                        metadata
                    )
            }
        }
        """
        testFormatting(for: input, output, rule: .ifCase, options: FormatOptions(indentCase: true))
    }
}
