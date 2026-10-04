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

    func testDoesNotMergeGuardsSeparatedByComment() {
        let input = """
        guard isValid else { return }

        // Enabling may perform additional work.
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

    func testDoesNotMergeGuardsThatCallXCTFail() {
        let input = """
        guard let e1 = p1.error else { return XCTFail() }
        guard let e2 = p2.error else { return XCTFail() }
        guard case PMKError.badInput = e1 else { return XCTFail() }
        guard case PMKError.badInput = e2 else { return XCTFail() }
        """
        testFormatting(for: input, rule: .repeatedGuard)
    }

    func testDoesNotMergeGuardsThatCallDiagnosticFunction() {
        let input = """
        guard isValid else { fatalError() }
        guard isEnabled else { fatalError() }
        """
        testFormatting(for: input, rule: .repeatedGuard)
    }

    func testDoesNotMergeGuardsThatCallCustomFailureHelper() {
        let input = """
        guard isValid else { return fail() }
        guard isEnabled else { return fail() }
        """
        testFormatting(for: input, rule: .repeatedGuard)
    }

    func testDoesNotMergeGuardsThatCreateError() {
        let input = """
        guard isValid else { throw ValidationError() }
        guard isEnabled else { throw ValidationError() }
        """
        testFormatting(for: input, rule: .repeatedGuard)
    }

    func testDoesNotMergeGuardsWithSourceLocationExpression() {
        let input = """
        guard isValid else { return #line }
        guard isEnabled else { return #line }
        """
        testFormatting(for: input, rule: .repeatedGuard)
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
