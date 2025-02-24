//
//  WrapMultilineFunctionChainsTests.swift
//  SwiftFormat
//
//  Created by Eric Horacek on 2/20/25.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class WrapMultilineFunctionChainsTests: XCTestCase {
    func testWrapIfExpressionAssignment() {
        let input = """
        let evenSquaresSum = [20, 17, 35, 4]
            .filter { $0 % 2 == 0 }.map { $0 * $0 }
            .reduce(0, +)
        """

        let output = """
        let evenSquaresSum = [20, 17, 35, 4]
            .filter { $0 % 2 == 0 }
            .map { $0 * $0 }
            .reduce(0, +)
        """

        testFormatting(for: input, [output], rules: [.wrapMultilineFunctionChains, .indent])
    }

    func testWrapMultipleFunctionCalls() {
        let input = """
        let result = array
            .first?.map { $0 * 2 }.filter { $0 > 10 }
            .reduce(0, +)
        """

        let output = """
        let result = array
            .first?
            .map { $0 * 2 }
            .filter { $0 > 10 }
            .reduce(0, +)
        """

        testFormatting(for: input, [output], rules: [.wrapMultilineFunctionChains, .indent])
    }

    func testWrapSingleFunctionCall() {
        let input = """
        let result = array.map { $0 * 2 }
        """

        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent])
    }

    func testWrapNestedFunctionCallsWithTrailingClosures() {
        let input = """
        let result = array
            .map { $0.filter { $1 > 10 } }.flatMap { $0 }
        """

        let output = """
        let result = array
            .map { $0.filter { $1 > 10 } }
            .flatMap { $0 }
        """

        testFormatting(for: input, [output], rules: [.wrapMultilineFunctionChains, .indent])
    }

    func testWrapNestedFunctionCallsWithClosureParameters() {
        let input = """
        let result = array
            .map { $0.reduce(0, +) }.flatMap { $0 }
        """

        let output = """
        let result = array
            .map { $0.reduce(0, +) }
            .flatMap { $0 }
        """

        testFormatting(for: input, [output], rules: [.wrapMultilineFunctionChains, .indent])
    }

    func testWrapFunctionCallsWithComments() {
        let input = """
        let result = array
            .map { $0 * 2 } // multiply by 2
            .filter { $0 > 10 } // filter greater than 10
            .reduce(0, +) // sum up
        """

        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent])
    }

    func testWrapFunctionCallsWithPropertyAccess() {
        let input = """
        let result = array
            .first?.property.map { $0 * 2 }.filter { $0 > 10 }
            .reduce(0, +)
        """

        let output = """
        let result = array
            .first?
            .property
            .map { $0 * 2 }
            .filter { $0 > 10 }
            .reduce(0, +)
        """

        testFormatting(for: input, [output], rules: [.wrapMultilineFunctionChains, .indent])
    }

    func testWrapFunctionCallsWithMultiplePropertyAccesses() {
        let input = """
        let result = array
            .first?.property.anotherProperty.map { $0 * 2 }.filter { $0 > 10 }
            .reduce(0, +)
        """

        let output = """
        let result = array
            .first?
            .property
            .anotherProperty
            .map { $0 * 2 }
            .filter { $0 > 10 }
            .reduce(0, +)
        """

        testFormatting(for: input, [output], rules: [.wrapMultilineFunctionChains, .indent])
    }

    func testWrapFunctionCallsWithChainsOnEndOfClosures() {
        let input = """
        let result = array
            .map { item in
                item.property
            }.filter { $0 > 10 }
            .reduce(0, +)
        """

        let output = """
        let result = array
            .map { item in
                item.property
            }
            .filter { $0 > 10 }
            .reduce(0, +)
        """

        testFormatting(for: input, [output], rules: [.wrapMultilineFunctionChains, .indent])
    }

    func testWrapFunctionCallsWithChainsOnEndOfParameters() {
        let input = """
        let result = array
            .function(
                arg1: item.property,
                arg2: item.property
            ).reduce(0, +)
        """

        let output = """
        let result = array
            .function(
                arg1: item.property,
                arg2: item.property
            )
            .reduce(0, +)
        """

        testFormatting(for: input, [output], rules: [.wrapMultilineFunctionChains, .indent])
    }

    func testMultilineOperatorStatementsNotWrapped() {
        let input = """
        formatter.currentIndentForLine(at: conditionBeginIndex)
            .count < indent.count + formatter.options.indent.count
        """

        testFormatting(for: input, rules: [.wrapMultilineFunctionChains, .indent])
    }

    func testMultilineTypesNotWrapped() {
        let input = """
        func tableCellSelection(for selection: Selection?) -> Selection
            .TableSelection.CellSelection?
        {
            selection.tableCellSelection
        }
        """

        testFormatting(for: input, rules: [.wrapMultilineFunctionChains, .indent])
    }

    func testSingleFunctionChainNotWrapped() {
        let input = """
        let result = array.map { $0 * 2 }
        """

        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent])
    }

    func testMultipleFunctionChainsOnOneLineNotWrapped() {
        let input = """
        let result = array.map { $0 * 2 }.filter { $0 > 10 }.reduce(0, +)
        """

        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent])
    }

    func testFunctionChainWithOptionalChaining() {
        let input = """
        let result = array?
            .map { $0 * 2 }
            .filter { $0 > 10 }
            .reduce(0, +)
        """

        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent])
    }

    func testConsecutiveDeclarations() {
        let input = """
        let sequence = [42].async
        let sequence = [43].async
        """

        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent])
    }

    func testConsecutiveStatements() {
        let input = """
        let encoded = try JSONEncoder().encode(container)
        let decoded = try JSONDecoder().decode(Container.self, from: encoded)
        """

        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent])
    }

    func testAdjacentChainsChainsShouldNotWrap() {
        let input = """
        value.property.map { $0 * 2 }
        value.property.map { $0 * 2 }
        """

        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent])
    }

    func testAdjacentChainsInViewBuildersWithDifferentWraps() {
        let input = """
        Text("S")
            .padding(10)
        Color.blue.frame(maxWidth: 1, maxHeight: .infinity).fixedSize()
        """

        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent])
    }

    func testNonFunctionChains() {
        let input = """
        let adjusted: CGPoint = .init(
            x: rect.origin.x + insets.left,
            y: rect.origin.y + insets.top
        )
        """

        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent])
    }

    func testAdjacentChainsInConditions() {
        let input = """
        let hexSanitized = hexString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var hex: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&hex) else {
            return nil
        }
        """
        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent])
    }

    func testAdjacentChainsInIfConditionWhereStatement() {
        let input = """
        let xcTestCaseInstanceMethods = Set(["expectation"])
            .union(options.additionalXCTestSymbols)

        for index in tokens.indices where tokens[index].isIdentifier {
            let identifier = tokens[index].string
        }
        """

        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent])
    }

    func testTrailingClosureNotWrapped() {
        let input = """
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.hideKeyboard.send()
        }
        """

        testFormatting(for: input, [], rules: [.wrapMultilineFunctionChains, .indent])
    }
}
