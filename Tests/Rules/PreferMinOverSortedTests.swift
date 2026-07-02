//
//  PreferMinOverSortedTests.swift
//  SwiftFormatTests
//
//  Created by Jon Parise on 6/26/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation
import XCTest
@testable import SwiftFormat

final class PreferMinOverSortedTests: XCTestCase {
    func testConvertSortedFirstToMin() {
        let input = """
        let smallest = values.sorted().first
        """

        let output = """
        let smallest = values.min()
        """

        testFormatting(for: input, output, rule: .preferMinOverSorted)
    }

    func testPreservesSortedLast() {
        // `sorted().last` is intentionally NOT rewritten to `max()`: on comparator ties,
        // `sorted().last` returns the last tied element while `max()` returns the first maximal
        // one, so the rewrite would not be behavior-preserving.
        let input = """
        let largest = values.sorted().last
        """

        testFormatting(for: input, rule: .preferMinOverSorted)
    }

    func testPreservesSortedByLast() {
        let input = """
        let latest = events.sorted(by: { $0.date < $1.date }).last
        """

        testFormatting(for: input, rule: .preferMinOverSorted)
    }

    func testPreservesSortedReversedFirst() {
        // `sorted().reversed().first` is equivalent to `sorted().last`, not `min()`, so it must NOT
        // be rewritten — same tie-breaking divergence from `max()` as `.last` (see testPreservesSortedLast).
        let input = """
        let largest = values.sorted().reversed().first
        """

        testFormatting(for: input, rule: .preferMinOverSorted)
    }

    func testConvertSortedByFirstToMinBy() {
        let input = """
        let earliest = events.sorted(by: { $0.date < $1.date }).first
        """

        let output = """
        let earliest = events.min(by: { $0.date < $1.date })
        """

        testFormatting(for: input, output, rule: .preferMinOverSorted)
    }

    func testConvertSortedByOperatorReference() {
        let input = """
        let smallest = values.sorted(by: <).first
        """

        let output = """
        let smallest = values.min(by: <)
        """

        testFormatting(for: input, output, rule: .preferMinOverSorted)
    }

    func testConvertSortedByThrowingComparatorFirst() {
        let input = """
        let earliest = try events.sorted(by: throwingComparator).first
        """

        let output = """
        let earliest = try events.min(by: throwingComparator)
        """

        testFormatting(for: input, output, rule: .preferMinOverSorted)
    }

    func testConvertChainedReceiver() {
        let input = """
        let first = model.scores.values.sorted().first
        """

        let output = """
        let first = model.scores.values.min()
        """

        testFormatting(for: input, output, rule: .preferMinOverSorted)
    }

    func testPreservesSortedWithoutAccessor() {
        let input = """
        let ordered = values.sorted()
        """

        testFormatting(for: input, rule: .preferMinOverSorted)
    }

    func testPreservesSortedFirstWhere() {
        let input = """
        let match = values.sorted().first(where: { $0 > 0 })
        """

        testFormatting(for: input, rule: .preferMinOverSorted)
    }

    func testConvertSortedFirstWithOptionalChainSubscript() {
        // `.first?[0]` is a property access followed by an optional-chained subscript; `min()?[0]`
        // is equivalent (both yield the smallest element, then subscript into it).
        let input = """
        let top = values.sorted().first?[0]
        """

        let output = """
        let top = values.min()?[0]
        """

        testFormatting(for: input, output, rule: .preferMinOverSorted)
    }

    func testPreservesSortedFollowedByOtherAccessor() {
        let input = """
        let n = values.sorted().count
        """

        testFormatting(for: input, rule: .preferMinOverSorted)
    }

    func testPreservesSortedWithExtraArguments() {
        let input = """
        let first = values.sorted(by: areInOrder, stable: true).first
        """

        testFormatting(for: input, rule: .preferMinOverSorted)
    }

    func testPreservesPrefixedSortedAccessor() {
        let input = """
        let count = values.sorted().firstIndex(of: x)
        """

        testFormatting(for: input, rule: .preferMinOverSorted)
    }

    func testConvertSortedFirstInIfLetBinding() {
        let input = """
        if let smallest = values.sorted().first {
            use(smallest)
        }
        """

        // The trailing `{` here begins the `if` body, not a closure, so `.first` is still a
        // property access and should be rewritten.
        let output = """
        if let smallest = values.min() {
            use(smallest)
        }
        """

        testFormatting(for: input, output, rule: .preferMinOverSorted)
    }

    func testConvertSortedFirstInWhileLetBinding() {
        let input = """
        while let smallest = values.sorted().first {
            values.removeFirst()
        }
        """

        let output = """
        while let smallest = values.min() {
            values.removeFirst()
        }
        """

        testFormatting(for: input, output, rule: .preferMinOverSorted)
    }

    func testPreservesSortedFirstTrailingClosure() {
        let input = """
        let match = values.sorted().first { $0 > 0 }
        """

        // Here the `{` is a trailing closure on `first`, so it's `first(where:)`, not the
        // `.first` property, and must be left untouched.
        testFormatting(for: input, rule: .preferMinOverSorted)
    }
}
