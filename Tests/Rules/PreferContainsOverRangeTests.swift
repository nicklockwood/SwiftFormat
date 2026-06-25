//
//  PreferContainsOverRangeTests.swift
//  SwiftFormatTests
//
//  Created by Jon Parise on 6/25/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation
import XCTest
@testable import SwiftFormat

final class PreferContainsOverRangeTests: XCTestCase {
    func testConvertRangeNotEqualNilToContains() {
        let input = """
        text.range(of: "needle") != nil
        """

        let output = """
        text.contains("needle")
        """

        testFormatting(for: input, output, rule: .preferContainsOverRange)
    }

    func testConvertRangeEqualNilToNotContains() {
        let input = """
        text.range(of: "needle") == nil
        """

        let output = """
        !text.contains("needle")
        """

        testFormatting(for: input, output, rule: .preferContainsOverRange)
    }

    func testConvertWithReceiverChainNegated() {
        let input = """
        if model.title.range(of: query) == nil {}
        """

        let output = """
        if !model.title.contains(query) {}
        """

        testFormatting(for: input, output, rule: .preferContainsOverRange)
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

        testFormatting(for: input, output, rule: .preferContainsOverRange)
    }

    func testConvertWithDataReceiver() {
        let input = """
        body.range(of: Data(phone.utf8)) != nil
        """

        let output = """
        body.contains(Data(phone.utf8))
        """

        testFormatting(for: input, output, rule: .preferContainsOverRange)
    }

    func testPreservesRangeWithAdditionalArguments() {
        let input = """
        text.range(of: "needle", options: .caseInsensitive) != nil
        """

        testFormatting(for: input, rule: .preferContainsOverRange)
    }

    func testConvertArgumentContainingNestedCommas() {
        let input = """
        text.range(of: makeNeedle(a, b)) != nil
        """

        let output = """
        text.contains(makeNeedle(a, b))
        """

        testFormatting(for: input, output, rule: .preferContainsOverRange)
    }

    func testPreservesRangeNotComparedToNil() {
        let input = """
        let r = text.range(of: "needle")
        """

        testFormatting(for: input, rule: .preferContainsOverRange)
    }

    func testPreservesRangeComparedToOtherValue() {
        let input = """
        text.range(of: "needle") != other
        """

        testFormatting(for: input, rule: .preferContainsOverRange)
    }

    func testPreservesRangeWithoutOfLabel() {
        let input = """
        array.range(in: bounds) != nil
        """

        testFormatting(for: input, rule: .preferContainsOverRange)
    }

    func testNegationInCompoundBooleanOnlyNegatesReceiver() {
        let input = """
        if foo && text.range(of: x) == nil {}
        """

        let output = """
        if foo && !text.contains(x) {}
        """

        // Exclude `andOperator`, which would rewrite `&&` to a comma in the `if` condition;
        // the point here is that the `!` negates only the `text` receiver, not `foo`.
        testFormatting(for: input, output, rule: .preferContainsOverRange, exclude: [.andOperator])
    }

    func testConvertNotEqualNilInCompoundBoolean() {
        let input = """
        if foo && text.range(of: x) != nil {}
        """

        let output = """
        if foo && text.contains(x) {}
        """

        testFormatting(for: input, output, rule: .preferContainsOverRange, exclude: [.andOperator])
    }

    func testPreservesOptionalChainedReceiver() {
        let input = """
        text?.range(of: x) != nil
        """

        testFormatting(for: input, rule: .preferContainsOverRange)
    }

    func testPreservesOptionalChainedReceiverInChain() {
        let input = """
        items.first?.name.range(of: "z") == nil
        """

        testFormatting(for: input, rule: .preferContainsOverRange)
    }

    func testConvertGenericReceiverNegated() {
        let input = """
        Box<Item>().range(of: x) == nil
        """

        let output = """
        !Box<Item>().contains(x)
        """

        testFormatting(for: input, output, rule: .preferContainsOverRange)
    }

    func testConvertSubscriptReceiverNegated() {
        let input = """
        items[index].range(of: x) == nil
        """

        let output = """
        !items[index].contains(x)
        """

        testFormatting(for: input, output, rule: .preferContainsOverRange)
    }

    func testPreservesLeadingDotReceiver() {
        let input = """
        let b: Bool = .text.range(of: x) == nil
        """

        testFormatting(for: input, rule: .preferContainsOverRange)
    }

    func testPreservesPrefixOperatorBeforeReceiver() {
        let input = """
        let n = -value.range(of: x) == nil
        """

        testFormatting(for: input, rule: .preferContainsOverRange)
    }

    func testPreservesCommentInsideRangeCall() {
        let input = """
        text.range(of: /* needle */ "needle") != nil
        """

        // Exclude `spaceAroundComments`, which would otherwise reformat the comment
        // spacing; the point here is that `preferContainsOverRange` leaves the
        // commented call untouched.
        testFormatting(for: input, rule: .preferContainsOverRange, exclude: [.spaceAroundComments])
    }
}
