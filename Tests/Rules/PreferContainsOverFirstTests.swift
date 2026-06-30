//
//  PreferContainsOverFirstTests.swift
//  SwiftFormatTests
//
//  Created by Jon Parise on 6/29/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation
import XCTest
@testable import SwiftFormat

final class PreferContainsOverFirstTests: XCTestCase {
    func testConvertFirstWhereNotEqualNil() {
        let input = """
        let hasNegative = numbers.first(where: { $0 < 0 }) != nil
        """

        let output = """
        let hasNegative = numbers.contains(where: { $0 < 0 })
        """

        testFormatting(for: input, output, rule: .preferContainsOverFirst)
    }

    func testConvertFirstWhereEqualNilNegated() {
        let input = """
        let noNegative = numbers.first(where: { $0 < 0 }) == nil
        """

        let output = """
        let noNegative = !numbers.contains(where: { $0 < 0 })
        """

        testFormatting(for: input, output, rule: .preferContainsOverFirst)
    }

    func testConvertFirstIndexWhereNotEqualNil() {
        let input = """
        let exists = numbers.firstIndex(where: { $0 < 0 }) != nil
        """

        let output = """
        let exists = numbers.contains(where: { $0 < 0 })
        """

        testFormatting(for: input, output, rule: .preferContainsOverFirst)
    }

    func testConvertFirstIndexWhereEqualNilNegated() {
        let input = """
        let missing = numbers.firstIndex(where: { $0 < 0 }) == nil
        """

        let output = """
        let missing = !numbers.contains(where: { $0 < 0 })
        """

        testFormatting(for: input, output, rule: .preferContainsOverFirst)
    }

    func testConvertTrailingClosureFirstNotEqualNil() {
        let input = """
        let hasNegative = numbers.first { $0 < 0 } != nil
        """

        let output = """
        let hasNegative = numbers.contains(where: { $0 < 0 })
        """

        testFormatting(for: input, output, rule: .preferContainsOverFirst)
    }

    func testConvertTrailingClosureFirstEqualNilNegated() {
        let input = """
        let noNegative = numbers.first { $0 < 0 } == nil
        """

        let output = """
        let noNegative = !numbers.contains(where: { $0 < 0 })
        """

        testFormatting(for: input, output, rule: .preferContainsOverFirst)
    }

    func testConvertTrailingClosureReceiverEqualNilNegated() {
        let input = """
        let noMatch = numbers.filter { $0 > 0 }.first(where: { $0 > 5 }) == nil
        """

        // The negating `!` must precede the whole receiver chain (including the leading
        // `.filter { ... }` trailing closure), not land between the closure's `}` and `.contains`.
        let output = """
        let noMatch = !numbers.filter { $0 > 0 }.contains(where: { $0 > 5 })
        """

        testFormatting(for: input, output, rule: .preferContainsOverFirst)
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

        testFormatting(for: input, output, rule: .preferContainsOverFirst)
    }

    func testPreservesCommentBetweenAccessorAndTrailingClosure() {
        let input = """
        let hasNegative = numbers.first /* pick */ { $0 < 0 } != nil
        """

        testFormatting(for: input, rule: .preferContainsOverFirst)
    }

    func testConvertWithChainedReceiver() {
        let input = """
        let exists = model.items.values.first(where: { $0.isActive }) != nil
        """

        let output = """
        let exists = model.items.values.contains(where: { $0.isActive })
        """

        testFormatting(for: input, output, rule: .preferContainsOverFirst)
    }

    func testNegationInCompoundBooleanOnlyNegatesReceiver() {
        let input = """
        if foo && numbers.first(where: { $0 < 0 }) == nil {}
        """

        let output = """
        if foo && !numbers.contains(where: { $0 < 0 }) {}
        """

        // Exclude `andOperator`, which rewrites `&&` to a comma in `if` conditions; the point here
        // is that the `!` negates only the `numbers` receiver, not `foo`.
        testFormatting(for: input, output, rule: .preferContainsOverFirst, exclude: [.andOperator])
    }

    func testPreservesFirstWhereNotComparedToNil() {
        let input = """
        let firstNegative = numbers.first(where: { $0 < 0 })
        """

        testFormatting(for: input, rule: .preferContainsOverFirst)
    }

    func testPreservesFirstWhereComparedToOtherValue() {
        let input = """
        let match = numbers.first(where: { $0 < 0 }) != other
        """

        testFormatting(for: input, rule: .preferContainsOverFirst)
    }

    func testPreservesFirstIndexOf() {
        let input = """
        let exists = numbers.firstIndex(of: 5) != nil
        """

        testFormatting(for: input, rule: .preferContainsOverFirst)
    }

    func testPreservesFirstProperty() {
        let input = """
        let exists = numbers.first != nil
        """

        testFormatting(for: input, rule: .preferContainsOverFirst)
    }

    func testPreservesOptionalChainedReceiver() {
        let input = """
        let exists = model?.numbers.first(where: { $0 < 0 }) == nil
        """

        testFormatting(for: input, rule: .preferContainsOverFirst)
    }

    func testPreservesOptionalChainedReceiverNotEqualNil() {
        // `model?.numbers.first(where:) != nil` is `Bool` (false when `model` is nil), but
        // `model?.numbers.contains(where:)` is `Bool?` (nil when `model` is nil) — a different
        // type and value — so the `!= nil` direction must also bail on optional chaining.
        let input = """
        let exists = model?.numbers.first(where: { $0 < 0 }) != nil
        """

        testFormatting(for: input, rule: .preferContainsOverFirst)
    }
}
