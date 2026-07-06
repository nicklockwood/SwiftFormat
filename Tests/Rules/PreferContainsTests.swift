//
//  PreferContainsTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/5/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation
import XCTest
@testable import SwiftFormat

final class PreferContainsTests: XCTestCase {
    // MARK: - filter(_:).isEmpty

    func testConvertFilterIsEmptyToNegatedContains() {
        let input = """
        let allRead = messages.filter { $0.isUnread }.isEmpty
        """

        let output = """
        let allRead = !messages.contains(where: { $0.isUnread })
        """

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testConvertParenFilterIsEmptyToNegatedContains() {
        let input = """
        let allRead = messages.filter({ $0.isUnread }).isEmpty
        """

        let output = """
        let allRead = !messages.contains(where: { $0.isUnread })
        """

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testConvertNegatedFilterIsEmptyCancelsNegation() {
        let input = """
        let hasUnread = !messages.filter { $0.isUnread }.isEmpty
        """

        // The existing `!` and the `filter { }.isEmpty` -> `!contains` negation cancel out.
        let output = """
        let hasUnread = messages.contains(where: { $0.isUnread })
        """

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testConvertNegatedParenFilterIsEmptyCancelsNegation() {
        let input = """
        let hasUnread = !messages.filter({ $0.isUnread }).isEmpty
        """

        let output = """
        let hasUnread = messages.contains(where: { $0.isUnread })
        """

        testFormatting(for: input, output, rule: .preferContains)
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

        testFormatting(for: input, output, rule: .preferContains)
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

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testConvertChainedReceiver() {
        let input = """
        let empty = model.items.values.filter { $0.isActive }.isEmpty
        """

        let output = """
        let empty = !model.items.values.contains(where: { $0.isActive })
        """

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testConvertPreservesCommentInsideClosure() {
        let input = """
        let allRead = messages.filter { /* unread only */ $0.isUnread }.isEmpty
        """

        let output = """
        let allRead = !messages.contains(where: { /* unread only */ $0.isUnread })
        """

        testFormatting(for: input, output, rule: .preferContains)
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

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testPreservesCommentBetweenFilterAndTrailingClosure() {
        // A comment between `filter` and its trailing `{` would be dropped when the closure is moved
        // into `(where: ...)`, so bail.
        let input = """
        let allRead = messages.filter /* pred */ { $0.isUnread }.isEmpty
        """

        testFormatting(for: input, rule: .preferContains)
    }

    func testPreservesOptionalChainedReceiverFilterIsEmpty() {
        // `messages?.filter { ... }.isEmpty` is `Bool?`; `messages?.contains(where:)` is also `Bool?`
        // but the negation semantics of the whole expression differ, so bail to be safe.
        let input = """
        let allRead = messages?.filter { $0.isUnread }.isEmpty
        """

        testFormatting(for: input, rule: .preferContains)
    }

    func testPreservesForceUnwrappedReceiverFilterIsEmpty() {
        let input = """
        let allRead = messages!.filter { $0.isUnread }.isEmpty
        """

        testFormatting(for: input, rule: .preferContains)
    }

    func testPreservesFilterWithStoredPredicate() {
        // Not a literal closure argument, so there's no closure to move into `contains(where:)`.
        let input = """
        let allRead = messages.filter(isUnread).isEmpty
        """

        testFormatting(for: input, rule: .preferContains)
    }

    func testPreservesFilterFollowedByOtherProperty() {
        let input = """
        let n = messages.filter { $0.isUnread }.count
        """

        testFormatting(for: input, rule: .preferContains)
    }

    func testPreservesBareIsEmptyWithoutFilter() {
        let input = """
        let empty = messages.isEmpty
        """

        testFormatting(for: input, rule: .preferContains)
    }

    func testPreservesFilterIsEmptyMethodCall() {
        // `.isEmpty()` as a method call (hypothetical custom type) isn't the Collection property.
        let input = """
        let empty = messages.filter { $0.isUnread }.isEmpty()
        """

        testFormatting(for: input, rule: .preferContains)
    }

    func testPreservesTrailingMemberAfterIsEmpty() {
        // A trailing `.description` would be captured by the inserted prefix `!`
        // (`!contains(...).description` == `!String`), so bail.
        let input = """
        let text = messages.filter { $0.isUnread }.isEmpty.description
        """

        testFormatting(for: input, rule: .preferContains)
    }

    func testPreservesTrailingForceUnwrapAfterIsEmpty() {
        // A trailing postfix `!` binds tighter than the inserted prefix `!`, so bail.
        let input = """
        let b = obj.flags.filter { $0 }.isEmpty!
        """

        testFormatting(for: input, rule: .preferContains)
    }

    func testFilterIsEmptyNegationInsertedAtOwnStatementNotPriorStatementEndingInScope() {
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

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testFilterIsEmptyNegationCancellationNotStolenFromPriorStatement() {
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

        testFormatting(for: input, output, rule: .preferContains)
    }

    // MARK: - first(where:) / firstIndex(where:) != nil

    func testConvertFirstWhereNotEqualNil() {
        let input = """
        let hasNegative = numbers.first(where: { $0 < 0 }) != nil
        """

        let output = """
        let hasNegative = numbers.contains(where: { $0 < 0 })
        """

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testConvertFirstWhereEqualNilNegated() {
        let input = """
        let noNegative = numbers.first(where: { $0 < 0 }) == nil
        """

        let output = """
        let noNegative = !numbers.contains(where: { $0 < 0 })
        """

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testConvertFirstIndexWhereNotEqualNil() {
        let input = """
        let exists = numbers.firstIndex(where: { $0 < 0 }) != nil
        """

        let output = """
        let exists = numbers.contains(where: { $0 < 0 })
        """

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testConvertFirstIndexWhereEqualNilNegated() {
        let input = """
        let missing = numbers.firstIndex(where: { $0 < 0 }) == nil
        """

        let output = """
        let missing = !numbers.contains(where: { $0 < 0 })
        """

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testConvertTrailingClosureFirstNotEqualNil() {
        let input = """
        let hasNegative = numbers.first { $0 < 0 } != nil
        """

        let output = """
        let hasNegative = numbers.contains(where: { $0 < 0 })
        """

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testConvertTrailingClosureFirstEqualNilNegated() {
        let input = """
        let noNegative = numbers.first { $0 < 0 } == nil
        """

        let output = """
        let noNegative = !numbers.contains(where: { $0 < 0 })
        """

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testConvertTrailingClosureReceiverEqualNilNegatedFirst() {
        let input = """
        let noMatch = numbers.filter { $0 > 0 }.first(where: { $0 > 5 }) == nil
        """

        // The negating `!` must precede the whole receiver chain (including the leading
        // `.filter { ... }` trailing closure), not land between the closure's `}` and `.contains`.
        let output = """
        let noMatch = !numbers.filter { $0 > 0 }.contains(where: { $0 > 5 })
        """

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testConvertTrailingClosureWithLinebreakBeforeBrace() {
        let input = """
        let hasNegative = numbers.first
            { $0 < 0 } != nil
        """

        // A linebreak between `first` and its trailing `{` is collapsed when the closure is
        // wrapped into `(where: ...)`, rather than leaving a stray newline before the `(`.
        let output = """
        let hasNegative = numbers.contains(where: { $0 < 0 })
        """

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testPreservesCommentBetweenAccessorAndTrailingClosure() {
        let input = """
        let hasNegative = numbers.first /* pick */ { $0 < 0 } != nil
        """

        testFormatting(for: input, rule: .preferContains)
    }

    func testConvertWithChainedReceiver() {
        let input = """
        let exists = model.items.values.first(where: { $0.isActive }) != nil
        """

        let output = """
        let exists = model.items.values.contains(where: { $0.isActive })
        """

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testNegationInCompoundBooleanOnlyNegatesReceiverFirst() {
        let input = """
        if foo && numbers.first(where: { $0 < 0 }) == nil {}
        """

        let output = """
        if foo && !numbers.contains(where: { $0 < 0 }) {}
        """

        // Exclude `andOperator`, which rewrites `&&` to a comma in `if` conditions; the point here
        // is that the `!` negates only the `numbers` receiver, not `foo`.
        testFormatting(for: input, output, rule: .preferContains, exclude: [.andOperator])
    }

    func testPreservesFirstWhereNotComparedToNil() {
        let input = """
        let firstNegative = numbers.first(where: { $0 < 0 })
        """

        testFormatting(for: input, rule: .preferContains)
    }

    func testPreservesFirstWhereComparedToOtherValue() {
        let input = """
        let match = numbers.first(where: { $0 < 0 }) != other
        """

        testFormatting(for: input, rule: .preferContains)
    }

    func testPreservesFirstIndexOf() {
        let input = """
        let exists = numbers.firstIndex(of: 5) != nil
        """

        testFormatting(for: input, rule: .preferContains)
    }

    func testPreservesFirstProperty() {
        let input = """
        let exists = numbers.first != nil
        """

        testFormatting(for: input, rule: .preferContains)
    }

    func testPreservesOptionalChainedReceiverFirst() {
        let input = """
        let exists = model?.numbers.first(where: { $0 < 0 }) == nil
        """

        testFormatting(for: input, rule: .preferContains)
    }

    func testPreservesOptionalChainedReceiverNotEqualNilFirst() {
        // `model?.numbers.first(where:) != nil` is `Bool` (false when `model` is nil), but
        // `model?.numbers.contains(where:)` is `Bool?` (nil when `model` is nil) — a different
        // type and value — so the `!= nil` direction must also bail on optional chaining.
        let input = """
        let exists = model?.numbers.first(where: { $0 < 0 }) != nil
        """

        testFormatting(for: input, rule: .preferContains)
    }

    func testFirstNegationInsertedAtOwnStatementNotPriorStatementEndingInScope() {
        // The `== nil` expression is a bare statement following another statement that ends in a
        // closing `}`. The negating `!` must be inserted before `numbers` on its own line, not
        // carried up into the previous statement's expression.
        let input = """
        perform { work() }
        numbers.first(where: { $0 < 0 }) == nil
        """

        let output = """
        perform { work() }
        !numbers.contains(where: { $0 < 0 })
        """

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testFirstNegationInsertedAtOwnStatementNotPriorStatementEndingInIdentifier() {
        // Same boundary issue where the previous statement ends in a bare identifier: the walk must
        // stop at the `identifier` <newline> `numbers` juxtaposition, not treat `state` as part of
        // the receiver chain.
        let input = """
        refresh.state
        numbers.first(where: { $0 < 0 }) == nil
        """

        let output = """
        refresh.state
        !numbers.contains(where: { $0 < 0 })
        """

        testFormatting(for: input, output, rule: .preferContains)
    }

    // MARK: - range(of:) != nil

    func testConvertRangeNotEqualNilToContains() {
        let input = """
        text.range(of: "needle") != nil
        """

        let output = """
        text.contains("needle")
        """

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testConvertRangeEqualNilToNotContains() {
        let input = """
        text.range(of: "needle") == nil
        """

        let output = """
        !text.contains("needle")
        """

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testConvertWithReceiverChainNegated() {
        let input = """
        if model.title.range(of: query) == nil {}
        """

        let output = """
        if !model.title.contains(query) {}
        """

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testConvertInsideCondition() {
        let input = """
        if text.range(of: "needle") != nil {
            handle()
        }
        """

        let output = """
        if text.contains("needle") {
            handle()
        }
        """

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testConvertWithDataReceiver() {
        let input = """
        body.range(of: Data(phone.utf8)) != nil
        """

        let output = """
        body.contains(Data(phone.utf8))
        """

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testPreservesRangeWithAdditionalArguments() {
        let input = """
        text.range(of: "needle", options: .caseInsensitive) != nil
        """

        testFormatting(for: input, rule: .preferContains)
    }

    func testConvertArgumentContainingNestedCommas() {
        let input = """
        text.range(of: makeNeedle(a, b)) != nil
        """

        let output = """
        text.contains(makeNeedle(a, b))
        """

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testPreservesRangeNotComparedToNil() {
        let input = """
        let r = text.range(of: "needle")
        """

        testFormatting(for: input, rule: .preferContains)
    }

    func testPreservesRangeComparedToOtherValue() {
        let input = """
        text.range(of: "needle") != other
        """

        testFormatting(for: input, rule: .preferContains)
    }

    func testPreservesRangeWithoutOfLabel() {
        let input = """
        array.range(in: bounds) != nil
        """

        testFormatting(for: input, rule: .preferContains)
    }

    func testNegationInCompoundBooleanOnlyNegatesReceiverRange() {
        let input = """
        if foo && text.range(of: x) == nil {}
        """

        let output = """
        if foo && !text.contains(x) {}
        """

        // Exclude `andOperator`, which would rewrite `&&` to a comma in the `if` condition;
        // the point here is that the `!` negates only the `text` receiver, not `foo`.
        testFormatting(for: input, output, rule: .preferContains, exclude: [.andOperator])
    }

    func testConvertNotEqualNilInCompoundBoolean() {
        let input = """
        if foo && text.range(of: x) != nil {}
        """

        let output = """
        if foo && text.contains(x) {}
        """

        testFormatting(for: input, output, rule: .preferContains, exclude: [.andOperator])
    }

    func testPreservesOptionalChainedReceiverRange() {
        let input = """
        text?.range(of: x) != nil
        """

        testFormatting(for: input, rule: .preferContains)
    }

    func testPreservesOptionalChainedReceiverInChain() {
        let input = """
        items.first?.name.range(of: "z") == nil
        """

        testFormatting(for: input, rule: .preferContains)
    }

    func testConvertGenericReceiverNegated() {
        let input = """
        Box<Item>().range(of: x) == nil
        """

        let output = """
        !Box<Item>().contains(x)
        """

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testConvertSubscriptReceiverNegated() {
        let input = """
        items[index].range(of: x) == nil
        """

        let output = """
        !items[index].contains(x)
        """

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testPreservesLeadingDotReceiver() {
        let input = """
        let b: Bool = .text.range(of: x) == nil
        """

        testFormatting(for: input, rule: .preferContains)
    }

    func testPreservesPrefixOperatorBeforeReceiver() {
        let input = """
        let n = -value.range(of: x) == nil
        """

        testFormatting(for: input, rule: .preferContains)
    }

    func testPreservesCommentInsideRangeCall() {
        let input = """
        text.range(of: /* needle */ "needle") != nil
        """

        // Exclude `spaceAroundComments`, which would otherwise reformat the comment
        // spacing; the point here is that `preferContains` leaves the
        // commented call untouched.
        testFormatting(for: input, rule: .preferContains, exclude: [.spaceAroundComments])
    }

    func testConvertTrailingClosureReceiverEqualNilNegatedRange() {
        let input = """
        let missing = items.map { $0.name }.joined().range(of: "x") == nil
        """

        // The negating `!` must precede the whole receiver chain, including the leading
        // `.map { ... }` trailing closure, rather than landing between the closure's `}`
        // and the chained call.
        let output = """
        let missing = !items.map { $0.name }.joined().contains("x")
        """

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testRangeNegationInsertedAtOwnStatementNotPriorStatementEndingInScope() {
        // The `== nil` expression is a bare statement following another statement that ends in a
        // closing `}`. The negating `!` must be inserted before `text` on its own line, not carried
        // up into the previous statement's expression.
        let input = """
        perform { work() }
        text.range(of: "x") == nil
        """

        let output = """
        perform { work() }
        !text.contains("x")
        """

        testFormatting(for: input, output, rule: .preferContains)
    }

    func testRangeNegationInsertedAtOwnStatementNotPriorStatementEndingInIdentifier() {
        // Same boundary issue where the previous statement ends in a bare identifier: the walk must
        // stop at the `identifier` <newline> `text` juxtaposition, not treat `state` as part of the
        // receiver chain.
        let input = """
        refresh.state
        text.range(of: "x") == nil
        """

        let output = """
        refresh.state
        !text.contains("x")
        """

        testFormatting(for: input, output, rule: .preferContains)
    }
}
