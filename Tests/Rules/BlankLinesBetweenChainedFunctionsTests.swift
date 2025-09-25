//
//  BlankLinesBetweenChainedFunctionsTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 7/28/23.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class BlankLinesBetweenChainedFunctionsTests: XCTestCase {
    func testBlankLinesBetweenChainedFunctions() {
        let input = """
        [0, 1, 2]
        .map { $0 * 2 }



        .map { $0 * 3 }
        """
        let output1 = """
        [0, 1, 2]
        .map { $0 * 2 }
        .map { $0 * 3 }
        """
        let output2 = """
        [0, 1, 2]
            .map { $0 * 2 }
            .map { $0 * 3 }
        """
        testFormatting(for: input, [output1, output2], rules: [.blankLinesBetweenChainedFunctions])
    }

    func testBlankLinesWithCommentsBetweenChainedFunctions() {
        let input = """
        [0, 1, 2]
            .map { $0 * 2 }

            // Multiplies by 3

            .map { $0 * 3 }
        """
        let output = """
        [0, 1, 2]
            .map { $0 * 2 }
            // Multiplies by 3
            .map { $0 * 3 }
        """
        testFormatting(for: input, output, rule: .blankLinesBetweenChainedFunctions)
    }

    func testBlankLinesWithMarkCommentBetweenChainedFunctions() {
        let input = """
        [0, 1, 2]
            .map { $0 * 2 }

            // MARK: hello

            .map { $0 * 3 }
        """
        testFormatting(for: input, rules: [.blankLinesBetweenChainedFunctions, .blankLinesAroundMark])
    }
}
