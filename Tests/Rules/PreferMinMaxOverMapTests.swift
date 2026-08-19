//
//  PreferMinMaxOverMapTests.swift
//  SwiftFormatTests
//
//  Created by Jon Parise on 8/19/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation
import XCTest
@testable import SwiftFormat

final class PreferMinMaxOverMapTests: XCTestCase {
    func testConvertMapMinToMin() {
        let input = """
        let minY = vertices.map { $0.y }.min()
        """

        let output = """
        let minY = vertices.min { $0.y < $1.y }?.y
        """

        testFormatting(for: input, output, rule: .preferMinMaxOverMap)
    }

    func testConvertMapMaxToMax() {
        let input = """
        let maxX = boxes.map { $0.maxX }.max()
        """

        let output = """
        let maxX = boxes.max { $0.maxX < $1.maxX }?.maxX
        """

        testFormatting(for: input, output, rule: .preferMinMaxOverMap)
    }

    func testConvertMapMinWithForceUnwrap() {
        let input = """
        let minY = vertices.map { $0.y }.min()!
        """

        let output = """
        let minY = vertices.min { $0.y < $1.y }!.y
        """

        testFormatting(for: input, output, rule: .preferMinMaxOverMap)
    }

    func testConvertMapMinWithNilCoalescing() {
        let input = """
        let floorOffset = amenities.map { $0.box.minY }.min() ?? 0
        """

        let output = """
        let floorOffset = amenities.min { $0.box.minY < $1.box.minY }?.box.minY ?? 0
        """

        testFormatting(for: input, output, rule: .preferMinMaxOverMap)
    }

    func testConvertMapMaxWithMultiLevelChain() {
        let input = """
        let floorOffset = amenities.map { $0.box.minY }.max()
        """

        let output = """
        let floorOffset = amenities.max { $0.box.minY < $1.box.minY }?.box.minY
        """

        testFormatting(for: input, output, rule: .preferMinMaxOverMap)
    }

    func testConvertChainedReceiver() {
        let input = """
        let minY = model.scene.vertices.map { $0.y }.min()
        """

        let output = """
        let minY = model.scene.vertices.min { $0.y < $1.y }?.y
        """

        testFormatting(for: input, output, rule: .preferMinMaxOverMap)
    }

    func testPreservesComputedExpressionBody() {
        let input = """
        let area = boxes.map { $0.width * $0.height }.max()
        """

        testFormatting(for: input, rule: .preferMinMaxOverMap)
    }

    func testPreservesFunctionCallBody() {
        let input = """
        let value = boxes.map { transform($0) }.max()
        """

        testFormatting(for: input, rule: .preferMinMaxOverMap)
    }

    func testPreservesIdentityMap() {
        let input = """
        let smallest = values.map { $0 }.min()
        """

        testFormatting(for: input, rule: .preferMinMaxOverMap)
    }

    func testPreservesNamedClosureParameter() {
        let input = """
        let minY = vertices.map { item in item.y }.min()
        """

        testFormatting(for: input, rule: .preferMinMaxOverMap)
    }

    func testPreservesMinWithExplicitArgument() {
        let input = """
        let smallest = values.map { $0.y }.min(by: { $0 < $1 })
        """

        testFormatting(for: input, rule: .preferMinMaxOverMap)
    }

    func testPreservesMaxWithExplicitArgument() {
        let input = """
        let largest = values.map { $0.y }.max(by: { $0 < $1 })
        """

        testFormatting(for: input, rule: .preferMinMaxOverMap)
    }

    func testPreservesTrailingAccessorAfterMin() {
        let input = """
        let description = values.map { $0.y }.min().debugDescription
        """

        testFormatting(for: input, rule: .preferMinMaxOverMap)
    }

    func testPreservesTrailingSubscriptAfterMin() {
        let input = """
        let first = values.map { $0.points }.min()[0]
        """

        testFormatting(for: input, rule: .preferMinMaxOverMap)
    }

    func testPreservesNonTrailingClosureMapCall() {
        let input = """
        let minY = vertices.map(projection).min()
        """

        testFormatting(for: input, rule: .preferMinMaxOverMap)
    }

    func testPreservesFirstAfterMap() {
        let input = """
        let firstY = vertices.map { $0.y }.first
        """

        testFormatting(for: input, rule: .preferMinMaxOverMap)
    }

    func testPreservesCommentInsideClosure() {
        let input = """
        let minY = vertices.map { /* projection */ $0.y }.min()
        """

        testFormatting(for: input, rule: .preferMinMaxOverMap)
    }

    func testPreservesCommentBetweenMapAndAccessor() {
        let input = """
        let minY = vertices.map { $0.y } /* comment */ .min()
        """

        testFormatting(for: input, rule: .preferMinMaxOverMap)
    }
}
