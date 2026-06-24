//
//  PreferFlatMapTests.swift
//  SwiftFormatTests
//
//  Created by Jon Parise on 6/24/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation
import XCTest
@testable import SwiftFormat

final class PreferFlatMapTests: XCTestCase {
    func testConvertMapReduceTrailingClosureToFlatMap() {
        let input = """
        sections.map { $0.items }.reduce([], +)
        """

        let output = """
        sections.flatMap { $0.items }
        """

        testFormatting(for: input, output, rule: .preferFlatMap)
    }

    func testConvertMapReduceParenClosureToFlatMap() {
        let input = """
        sections.map({ $0.items }).reduce([], +)
        """

        let output = """
        sections.flatMap({ $0.items })
        """

        // Exclude `trailingClosures`, which would otherwise rewrite the
        // preserved paren-closure form into a trailing closure.
        testFormatting(for: input, output, rule: .preferFlatMap, exclude: [.trailingClosures])
    }

    func testConvertMultilineMapReduce() {
        let input = """
        actionGroups
            .map { group in
                group.actionRows
            }
            .reduce([], +)
        """

        let output = """
        actionGroups
            .flatMap { group in
                group.actionRows
            }
        """

        testFormatting(for: input, output, rule: .preferFlatMap)
    }

    func testConvertNestedMapReduce() {
        let input = """
        groups.map { group in
            group.rows.map { $0.cells }.reduce([], +)
        }.reduce([], +)
        """

        let output = """
        groups.flatMap { group in
            group.rows.flatMap { $0.cells }
        }
        """

        testFormatting(for: input, output, rule: .preferFlatMap)
    }

    func testConvertPreservesChainedCallAfterReduce() {
        let input = """
        sections.map { $0.items }.reduce([], +).count
        """

        let output = """
        sections.flatMap { $0.items }.count
        """

        testFormatting(for: input, output, rule: .preferFlatMap)
    }

    func testPreservesCompactMapReduce() {
        let input = """
        sections.compactMap { $0.items }.reduce([], +)
        """

        testFormatting(for: input, rule: .preferFlatMap)
    }

    func testPreservesCommentBetweenMapAndReduce() {
        let input = """
        sections.map { $0.items } // flatten
            .reduce([], +)
        """

        testFormatting(for: input, rule: .preferFlatMap)
    }

    func testPreservesCommentInsideReduce() {
        let input = """
        sections.map { $0.items }.reduce(/* seed */ [], +)
        """

        // Exclude `spaceAroundComments`, which would otherwise insert a space
        // after the open paren; the point here is that `preferFlatMap` itself
        // leaves the commented `reduce` call untouched.
        testFormatting(for: input, rule: .preferFlatMap, exclude: [.spaceAroundComments])
    }

    func testPreservesReduceWithNonEmptySeed() {
        let input = """
        values.map { $0.count }.reduce(0, +)
        """

        testFormatting(for: input, rule: .preferFlatMap)
    }

    func testPreservesReduceWithNonEmptyArraySeed() {
        let input = """
        sections.map { $0.items }.reduce([defaultItem], +)
        """

        testFormatting(for: input, rule: .preferFlatMap)
    }

    func testPreservesReduceWithDifferentOperator() {
        let input = """
        sets.map { $0.elements }.reduce([], -)
        """

        testFormatting(for: input, rule: .preferFlatMap)
    }

    func testPreservesReduceWithClosureCombinator() {
        let input = """
        sections.map { $0.items }.reduce([]) { $0 + $1 }
        """

        testFormatting(for: input, rule: .preferFlatMap)
    }

    func testPreservesStandaloneMap() {
        let input = """
        sections.map { $0.items }
        """

        testFormatting(for: input, rule: .preferFlatMap)
    }

    func testPreservesMapFollowedByOtherCall() {
        let input = """
        sections.map { $0.items }.filter { !$0.isEmpty }
        """

        testFormatting(for: input, rule: .preferFlatMap)
    }
}
