//
//  PreferLazyMapTests.swift
//  SwiftFormatTests
//
//  Created by Jon Parise on 8/19/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation
import XCTest
@testable import SwiftFormat

final class PreferLazyMapTests: XCTestCase {
    func testInsertsLazyBeforeMin() {
        let input = """
        let minY = vertices.map { $0.y }.min()
        """

        let output = """
        let minY = vertices.lazy.map { $0.y }.min()
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyBeforeMax() {
        let input = """
        let maxX = boxes.map { $0.maxX }.max()
        """

        let output = """
        let maxX = boxes.lazy.map { $0.maxX }.max()
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyBeforeMinWithComparator() {
        let input = """
        let earliest = events.map { $0.date }.min(by: { $0 < $1 })
        """

        let output = """
        let earliest = events.lazy.map { $0.date }.min(by: { $0 < $1 })
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyBeforeReduce() {
        let input = """
        let total = items.map { $0.price }.reduce(0, +)
        """

        let output = """
        let total = items.lazy.map { $0.price }.reduce(0, +)
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyBeforeJoined() {
        let input = """
        let names = users.map { $0.name }.joined(separator: ", ")
        """

        let output = """
        let names = users.lazy.map { $0.name }.joined(separator: ", ")
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyBeforeContains() {
        let input = """
        let hasZero = items.map { $0.count }.contains(0)
        """

        let output = """
        let hasZero = items.lazy.map { $0.count }.contains(0)
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyBeforeContainsWhere() {
        let input = """
        let hasEmpty = rows.map { $0.title }.contains(where: { $0.isEmpty })
        """

        let output = """
        let hasEmpty = rows.lazy.map { $0.title }.contains(where: { $0.isEmpty })
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyBeforeAllSatisfy() {
        let input = """
        let allPositive = items.map { $0.value }.allSatisfy { $0 > 0 }
        """

        let output = """
        let allPositive = items.lazy.map { $0.value }.allSatisfy { $0 > 0 }
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyBeforeFirstWhere() {
        let input = """
        let firstEmpty = rows.map { $0.title }.first(where: { $0.isEmpty })
        """

        let output = """
        let firstEmpty = rows.lazy.map { $0.title }.first(where: { $0.isEmpty })
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyBeforeMinWithTrailingClosure() {
        let input = """
        let earliest = events.map { $0.date }.min { $0 < $1 }
        """

        let output = """
        let earliest = events.lazy.map { $0.date }.min { $0 < $1 }
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyBeforeFirstWithTrailingClosure() {
        let input = """
        let firstEmpty = rows.map { $0.title }.first { $0.isEmpty }
        """

        let output = """
        let firstEmpty = rows.lazy.map { $0.title }.first { $0.isEmpty }
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyWithForceUnwrap() {
        let input = """
        let minY = vertices.map { $0.y }.min()!
        """

        let output = """
        let minY = vertices.lazy.map { $0.y }.min()!
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyWithNilCoalescing() {
        let input = """
        let floorOffset = amenities.map { $0.box.minY }.min() ?? 0
        """

        let output = """
        let floorOffset = amenities.lazy.map { $0.box.minY }.min() ?? 0
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyForComputedExpressionBody() {
        let input = """
        let area = boxes.map { $0.width * $0.height }.max()
        """

        let output = """
        let area = boxes.lazy.map { $0.width * $0.height }.max()
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyForNamedClosureParameter() {
        let input = """
        let minY = vertices.map { item in item.y }.min()
        """

        let output = """
        let minY = vertices.lazy.map { item in item.y }.min()
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyForChainedReceiver() {
        let input = """
        let minY = model.scene.vertices.map { $0.y }.min()
        """

        let output = """
        let minY = model.scene.vertices.lazy.map { $0.y }.min()
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testPreservesFirstProperty() {
        let input = """
        let firstY = vertices.map { $0.y }.first
        """

        testFormatting(for: input, rule: .preferLazyMap)
    }

    func testPreservesAlreadyLazyReceiver() {
        let input = """
        let minY = vertices.lazy.map { $0.y }.min()
        """

        testFormatting(for: input, rule: .preferLazyMap)
    }

    func testPreservesSorted() {
        let input = """
        let sortedYs = vertices.map { $0.y }.sorted()
        """

        testFormatting(for: input, rule: .preferLazyMap)
    }

    func testPreservesCount() {
        let input = """
        let count = vertices.map { $0.y }.count
        """

        testFormatting(for: input, rule: .preferLazyMap)
    }

    func testPreservesUncalledMinReference() {
        let input = """
        let findMin = vertices.map { $0.y }.min
        """

        testFormatting(for: input, rule: .preferLazyMap)
    }

    func testPreservesNonTrailingClosureMapCall() {
        let input = """
        let minY = vertices.map(projection).min()
        """

        testFormatting(for: input, rule: .preferLazyMap)
    }
}
