//
//  PreferFirstWhereTests.swift
//  SwiftFormatTests
//
//  Created by Jon Parise on 6/25/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation
import XCTest
@testable import SwiftFormat

final class PreferFirstWhereTests: XCTestCase {
    func testConvertFilterParenClosureToFirstWhere() {
        let input = """
        planets.filter({ $0.hasMoons }).first
        """

        let output = """
        planets.first(where: { $0.hasMoons })
        """

        testFormatting(for: input, output, rule: .preferFirstWhere)
    }

    func testConvertFilterTrailingClosureToFirstWhere() {
        let input = """
        planets.filter { $0.hasMoons }.first
        """

        let output = """
        planets.first(where: { $0.hasMoons })
        """

        testFormatting(for: input, output, rule: .preferFirstWhere)
    }

    func testConvertMultilineFilter() {
        let input = """
        planets
            .filter { planet in
                planet.hasMoons
            }
            .first
        """

        // The rule converts the `filter` call in place and drops the trailing `.first`, leaving the
        // `first(where:)` where `filter` was (the now-empty `.first` line is removed).
        let output = """
        planets
            .first(where: { planet in
                planet.hasMoons
            })
        """

        testFormatting(for: input, output, rule: .preferFirstWhere)
    }

    func testConvertNestedFilterFirst() {
        let input = """
        systems.filter { system in
            system.planets.filter { $0.hasMoons }.first != nil
        }.first
        """

        let output = """
        systems.first(where: { system in
            system.planets.first(where: { $0.hasMoons }) != nil
        })
        """

        // Exclude `preferContainsOverFirst`, which would further rewrite the inner
        // `first(where:) != nil` into `contains(where:)`; this test isolates `preferFirstWhere`.
        testFormatting(for: input, output, rule: .preferFirstWhere, exclude: [.preferContainsOverFirst])
    }

    func testConvertPreservesOptionalChainAfterFirst() {
        let input = """
        planets.filter { $0.hasMoons }.first?.name
        """

        let output = """
        planets.first(where: { $0.hasMoons })?.name
        """

        testFormatting(for: input, output, rule: .preferFirstWhere)
    }

    func testConvertPreservesNilCoalescingAfterFirst() {
        let input = """
        planets.filter { $0.hasMoons }.first ?? defaultPlanet
        """

        let output = """
        planets.first(where: { $0.hasMoons }) ?? defaultPlanet
        """

        testFormatting(for: input, output, rule: .preferFirstWhere)
    }

    func testConvertPreservesForceUnwrapAfterFirst() {
        let input = """
        planets.filter { $0.hasMoons }.first!
        """

        let output = """
        planets.first(where: { $0.hasMoons })!
        """

        testFormatting(for: input, output, rule: .preferFirstWhere)
    }

    func testPreservesCommentBetweenFilterAndFirst() {
        let input = """
        planets
            .filter { $0.hasMoons }
            // pick the first
            .first
        """

        testFormatting(for: input, rule: .preferFirstWhere)
    }

    func testConvertPreservesCommentInsideClosure() {
        let input = """
        planets.filter { /* gas giants */ $0.hasMoons }.first
        """

        let output = """
        planets.first(where: { /* gas giants */ $0.hasMoons })
        """

        testFormatting(for: input, output, rule: .preferFirstWhere)
    }

    func testPreservesFirstMethodWithWhere() {
        let input = """
        planets.filter { $0.hasMoons }.first(where: { $0.isHabitable })
        """

        testFormatting(for: input, rule: .preferFirstWhere)
    }

    func testPreservesFirstMethodWithCount() {
        let input = """
        planets.filter { $0.hasMoons }.first(3)
        """

        testFormatting(for: input, rule: .preferFirstWhere)
    }

    func testPreservesStandaloneFilter() {
        let input = """
        planets.filter { $0.hasMoons }
        """

        testFormatting(for: input, rule: .preferFirstWhere)
    }

    func testPreservesFilterFollowedByOtherProperty() {
        let input = """
        planets.filter { $0.hasMoons }.count
        """

        testFormatting(for: input, rule: .preferFirstWhere)
    }

    func testPreservesFilterFollowedByLast() {
        let input = """
        planets.filter { $0.hasMoons }.last
        """

        testFormatting(for: input, rule: .preferFirstWhere)
    }
}
