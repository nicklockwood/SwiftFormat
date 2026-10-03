//
//  RepeatedGuardTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 10/3/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class RepeatedGuardTests: XCTestCase {
    func testMergesConsecutiveGuardsWithSameBody() {
        let input = """
        guard isValid else { return }
        guard isEnabled else { return }
        """
        let output = """
        guard isValid, isEnabled else { return }
        """
        testFormatting(for: input, output, rule: .repeatedGuard)
    }

    func testMergesMoreThanTwoConsecutiveGuards() {
        let input = """
        guard isValid else { return }
        guard isEnabled else { return }
        guard isAuthorized else { return }
        """
        let output = """
        guard isValid, isEnabled, isAuthorized else { return }
        """
        testFormatting(for: input, output, rule: .repeatedGuard)
    }

    func testMergesGuardsWithDependentOptionalBindings() {
        let input = """
        guard let user else { throw LoginError.invalidUser }
        guard let account = user.account else { throw LoginError.invalidUser }
        """
        let output = """
        guard let user, let account = user.account else { throw LoginError.invalidUser }
        """
        testFormatting(for: input, output, rule: .repeatedGuard)
    }

    func testMergesEquivalentMultilineBodies() {
        let input = """
        guard isValid else { return }
        guard isEnabled else {
            return
        }
        """
        let output = """
        guard isValid, isEnabled else {
            return
        }
        """
        testFormatting(for: input, output, rule: .repeatedGuard)
    }

    func testDoesNotMergeGuardsWithDifferentBodies() {
        let input = """
        guard isValid else { return }
        guard isEnabled else { throw ValidationError.disabled }
        """
        testFormatting(for: input, rule: .repeatedGuard)
    }

    func testMergesGuardsSeparatedByComment() {
        let input = """
        guard isValid else { return }

        // Enabling may perform additional work.
        guard isEnabled else { return }
        """
        let output = """
        guard isValid,
              // Enabling may perform additional work.
              isEnabled
        else { return }
        """
        testFormatting(for: input, output, rule: .repeatedGuard)
    }

    func testMergesWhenFirstGuardHasComment() {
        let input = """
        // The value must be valid.
        guard isValid else { return }
        guard isEnabled else { return }
        """
        let output = """
        guard
            // The value must be valid.
            isValid,
            isEnabled
        else { return }
        """
        testFormatting(for: input, output, rule: .repeatedGuard)
    }

    func testMergesWhenBothGuardsHaveComments() {
        let input = """
        // The value must be valid.
        guard isValid else { return }
        // The feature must be enabled.
        guard isEnabled else { return }
        """
        let output = """
        guard
            // The value must be valid.
            isValid,
            // The feature must be enabled.
            isEnabled
        else { return }
        """
        testFormatting(for: input, output, rule: .repeatedGuard)
    }

    func testMergesMoreThanTwoGuardsSeparatedByComments() {
        let input = """
        guard isValid else { return }
        // Enabling may perform additional work.
        guard isEnabled else { return }
        // Authorization may perform additional work.
        guard isAuthorized else { return }
        """
        let output = """
        guard isValid,
              // Enabling may perform additional work.
              isEnabled,
              // Authorization may perform additional work.
              isAuthorized
        else { return }
        """
        testFormatting(for: input, output, rule: .repeatedGuard)
    }

    func testDoesNotMoveTrailingCommentFromPreviousGuard() {
        let input = """
        guard isValid else { return } // Validates the input.

        guard isEnabled else { return }
        """
        testFormatting(
            for: input,
            rule: .repeatedGuard,
            exclude: [.blankLinesAfterGuardStatements]
        )
    }

    func testDoesNotMergeAcrossFormattingDirective() {
        let input = """
        guard isValid else { return }

        // swiftformat:disable:next repeatedGuard
        guard isEnabled else { return }
        """
        testFormatting(for: input, rule: .repeatedGuard)
    }

    func testDoesNotMergeGuardBodiesContainingComments() {
        let input = """
        guard isValid else {
            // Preserve the reason for returning.
            return
        }

        guard isEnabled else {
            // Preserve the reason for returning.
            return
        }
        """
        testFormatting(
            for: input,
            rule: .repeatedGuard,
            exclude: [.blankLinesAfterGuardStatements, .blankLinesBetweenScopes]
        )
    }

    func testMergesGuardsThatRedeclareBinding() {
        let input = """
        guard let value = firstValue else { return }
        guard let value = secondValue else { return }
        """
        let output = """
        guard let value = firstValue, let value = secondValue else { return }
        """
        testFormatting(for: input, output, rule: .repeatedGuard)
    }

    func testDoesNotMergeWhenBodyReferencesBindingFromFirstGuard() {
        let input = """
        let value = 0
        guard let value = optionalValue else { print(value); return }
        guard isValid else { print(value); return }
        """
        testFormatting(for: input, rule: .repeatedGuard)
    }

    func testMergesPatternMatchingGuards() {
        let input = """
        guard case let .success(value) = firstResult else { return }
        guard case let .success(otherValue) = secondResult else { return }
        """
        let output = """
        guard case let .success(value) = firstResult, case let .success(otherValue) = secondResult else { return }
        """
        testFormatting(for: input, output, rule: .repeatedGuard)
    }

    func testDoesNotMergeWhenBodyReferencesBindingFromFirstPattern() {
        let input = """
        let value = 0
        guard case let .success(value) = result else { print(value); return }
        guard isValid else { print(value); return }
        """
        testFormatting(for: input, rule: .repeatedGuard)
    }
}
