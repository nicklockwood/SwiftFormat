//
//  PreferContainsOverFilterIsEmptyTests.swift
//  SwiftFormatTests
//
//  Created by Jon Parise on 7/2/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation
import XCTest
@testable import SwiftFormat

final class PreferContainsOverFilterIsEmptyTests: XCTestCase {
    func testConvertFilterIsEmptyToNegatedContains() {
        let input = """
        let allRead = messages.filter { $0.isUnread }.isEmpty
        """

        let output = """
        let allRead = !messages.contains(where: { $0.isUnread })
        """

        testFormatting(for: input, output, rule: .preferContainsOverFilterIsEmpty)
    }

    func testConvertParenFilterIsEmptyToNegatedContains() {
        let input = """
        let allRead = messages.filter({ $0.isUnread }).isEmpty
        """

        let output = """
        let allRead = !messages.contains(where: { $0.isUnread })
        """

        testFormatting(for: input, output, rule: .preferContainsOverFilterIsEmpty)
    }

    func testConvertNegatedFilterIsEmptyCancelsNegation() {
        let input = """
        let hasUnread = !messages.filter { $0.isUnread }.isEmpty
        """

        // The existing `!` and the `filter { }.isEmpty` -> `!contains` negation cancel out.
        let output = """
        let hasUnread = messages.contains(where: { $0.isUnread })
        """

        testFormatting(for: input, output, rule: .preferContainsOverFilterIsEmpty)
    }

    func testConvertNegatedParenFilterIsEmptyCancelsNegation() {
        let input = """
        let hasUnread = !messages.filter({ $0.isUnread }).isEmpty
        """

        let output = """
        let hasUnread = messages.contains(where: { $0.isUnread })
        """

        testFormatting(for: input, output, rule: .preferContainsOverFilterIsEmpty)
    }

    func testConvertInIfConditionInsertsNegation() {
        let input = """
        if messages.filter({ $0.isUnread }).isEmpty {
            markAllRead()
        }
        """

        // The trailing `{` opens the `if` body, not a closure, so `.isEmpty` is still a property.
        let output = """
        if !messages.contains(where: { $0.isUnread }) {
            markAllRead()
        }
        """

        testFormatting(for: input, output, rule: .preferContainsOverFilterIsEmpty)
    }

    func testConvertNegatedInIfConditionCancelsNegation() {
        let input = """
        if !messages.filter { $0.isUnread }.isEmpty {
            showBadge()
        }
        """

        let output = """
        if messages.contains(where: { $0.isUnread }) {
            showBadge()
        }
        """

        testFormatting(for: input, output, rule: .preferContainsOverFilterIsEmpty)
    }

    func testConvertChainedReceiver() {
        let input = """
        let empty = model.items.values.filter { $0.isActive }.isEmpty
        """

        let output = """
        let empty = !model.items.values.contains(where: { $0.isActive })
        """

        testFormatting(for: input, output, rule: .preferContainsOverFilterIsEmpty)
    }

    func testConvertPreservesCommentInsideClosure() {
        let input = """
        let allRead = messages.filter { /* unread only */ $0.isUnread }.isEmpty
        """

        let output = """
        let allRead = !messages.contains(where: { /* unread only */ $0.isUnread })
        """

        testFormatting(for: input, output, rule: .preferContainsOverFilterIsEmpty)
    }

    func testConvertWhenIsEmptyFollowedByInfixOperator() {
        // A trailing *infix* operator (unlike a postfix/member) is safe: the inserted prefix `!`
        // binds tighter, so `!contains(...) == expected` matches the original `isEmpty == expected`.
        let input = """
        let match = messages.filter { $0.isUnread }.isEmpty == expected
        """

        let output = """
        let match = !messages.contains(where: { $0.isUnread }) == expected
        """

        testFormatting(for: input, output, rule: .preferContainsOverFilterIsEmpty)
    }

    func testPreservesCommentBetweenFilterAndTrailingClosure() {
        // A comment between `filter` and its trailing `{` would be dropped when the closure is moved
        // into `(where: ...)`, so bail.
        let input = """
        let allRead = messages.filter /* pred */ { $0.isUnread }.isEmpty
        """

        testFormatting(for: input, rule: .preferContainsOverFilterIsEmpty)
    }

    func testPreservesOptionalChainedReceiver() {
        // `messages?.filter { ... }.isEmpty` is `Bool?`; `messages?.contains(where:)` is also `Bool?`
        // but the negation semantics of the whole expression differ, so bail to be safe.
        let input = """
        let allRead = messages?.filter { $0.isUnread }.isEmpty
        """

        testFormatting(for: input, rule: .preferContainsOverFilterIsEmpty)
    }

    func testPreservesForceUnwrappedReceiver() {
        let input = """
        let allRead = messages!.filter { $0.isUnread }.isEmpty
        """

        testFormatting(for: input, rule: .preferContainsOverFilterIsEmpty)
    }

    func testPreservesFilterWithStoredPredicate() {
        // Not a literal closure argument, so there's no closure to move into `contains(where:)`.
        let input = """
        let allRead = messages.filter(isUnread).isEmpty
        """

        testFormatting(for: input, rule: .preferContainsOverFilterIsEmpty)
    }

    func testPreservesFilterFollowedByOtherProperty() {
        let input = """
        let n = messages.filter { $0.isUnread }.count
        """

        testFormatting(for: input, rule: .preferContainsOverFilterIsEmpty)
    }

    func testPreservesBareIsEmptyWithoutFilter() {
        let input = """
        let empty = messages.isEmpty
        """

        testFormatting(for: input, rule: .preferContainsOverFilterIsEmpty)
    }

    func testPreservesFilterIsEmptyMethodCall() {
        // `.isEmpty()` as a method call (hypothetical custom type) isn't the Collection property.
        let input = """
        let empty = messages.filter { $0.isUnread }.isEmpty()
        """

        testFormatting(for: input, rule: .preferContainsOverFilterIsEmpty)
    }

    func testPreservesTrailingMemberAfterIsEmpty() {
        // A trailing `.description` would be captured by the inserted prefix `!`
        // (`!contains(...).description` == `!String`), so bail.
        let input = """
        let text = messages.filter { $0.isUnread }.isEmpty.description
        """

        testFormatting(for: input, rule: .preferContainsOverFilterIsEmpty)
    }

    func testPreservesTrailingForceUnwrapAfterIsEmpty() {
        // A trailing postfix `!` binds tighter than the inserted prefix `!`, so bail.
        let input = """
        let b = obj.flags.filter { $0 }.isEmpty!
        """

        testFormatting(for: input, rule: .preferContainsOverFilterIsEmpty)
    }

    func testNegationInsertedAtOwnStatementNotPriorStatementEndingInScope() {
        // The expression is a bare statement following one that ends in a closing `}`. The inserted
        // `!` must land before `xs` on its own line, not be carried into the previous statement.
        let input = """
        perform { work() }
        xs.filter { $0.isUnread }.isEmpty
        """

        let output = """
        perform { work() }
        !xs.contains(where: { $0.isUnread })
        """

        testFormatting(for: input, output, rule: .preferContainsOverFilterIsEmpty)
    }

    func testNegationCancellationNotStolenFromPriorStatement() {
        // The previous statement's own prefix `!` must not be mistaken for this expression's leading
        // negation and deleted. `xs.filter{}.isEmpty` (no leading `!`) gets a fresh `!`.
        let input = """
        let a = !flag
        xs.filter { $0.isUnread }.isEmpty
        """

        let output = """
        let a = !flag
        !xs.contains(where: { $0.isUnread })
        """

        testFormatting(for: input, output, rule: .preferContainsOverFilterIsEmpty)
    }
}
