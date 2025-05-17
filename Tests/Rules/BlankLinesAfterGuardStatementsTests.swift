// Created by @NikeKov on 01.08.2024
// Copyright © 2024 Nick Lockwood. All rights reserved.

import XCTest
@testable import SwiftFormat

final class BlankLinesAfterGuardStatementsTests: XCTestCase {
    func testSpacesBetweenMultiLineGuards() {
        let input = """
        guard let one = test.one else {
            return
        }
        guard let two = test.two else {
            return
        }

        guard let three = test.three else {
            return
        }


        guard let four = test.four else {
            return
        }




        guard let five = test.five else {
            return
        }
        """
        let output = """
        guard let one = test.one else {
            return
        }
        guard let two = test.two else {
            return
        }
        guard let three = test.three else {
            return
        }
        guard let four = test.four else {
            return
        }
        guard let five = test.five else {
            return
        }
        """

        testFormatting(for: input, output, rule: .blankLinesAfterGuardStatements, exclude: [.blankLinesBetweenScopes])
    }

    func testSpacesBetweenSingleLineGuards() {
        let input = """
        guard let one = test.one else { return }
        guard let two = test.two else { return }

        guard let three = test.three else { return }


        guard let four = test.four else { return }




        guard let five = test.five else { return }
        """
        let output = """
        guard let one = test.one else { return }
        guard let two = test.two else { return }
        guard let three = test.three else { return }
        guard let four = test.four else { return }
        guard let five = test.five else { return }
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            exclude: [.blankLinesBetweenScopes, .wrapConditionalBodies]
        )
    }

    func testSpacesBetweenSingleLineAndMultiLineGuards() {
        let input = """
        guard let one = test.one else { return }
        guard let two = test.two else { return }

        guard let three = test.three else {
            return
        }


        guard let four = test.four else { return }




        guard let five = test.five else {
            return
        }
        """
        let output = """
        guard let one = test.one else { return }
        guard let two = test.two else { return }
        guard let three = test.three else {
            return
        }
        guard let four = test.four else { return }
        guard let five = test.five else {
            return
        }
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            exclude: [.blankLinesBetweenScopes, .wrapConditionalBodies]
        )
    }

    func testSpacesBetweenMultiLineGuardsWhenBlankLineInsertedBetweenConsecutiveGuards() {
        let input = """
        guard let one = test.one else {
            return
        }
        guard let two = test.two else {
            return
        }

        guard let three = test.three else {
            return
        }


        guard let four = test.four else {
            return
        }




        guard let five = test.five else {
            return
        }
        """
        let output = """
        guard let one = test.one else {
            return
        }

        guard let two = test.two else {
            return
        }

        guard let three = test.three else {
            return
        }

        guard let four = test.four else {
            return
        }

        guard let five = test.five else {
            return
        }
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            options: FormatOptions(lineBetweenConsecutiveGuards: true),
            exclude: [.blankLinesBetweenScopes]
        )
    }

    func testSpacesBetweenSingleLineGuardsWhenBlankLineInsertedBetweenConsecutiveGuards() {
        let input = """
        guard let one = test.one else { return }
        guard let two = test.two else { return }

        guard let three = test.three else { return }


        guard let four = test.four else { return }




        guard let five = test.five else { return }
        """
        let output = """
        guard let one = test.one else { return }

        guard let two = test.two else { return }

        guard let three = test.three else { return }

        guard let four = test.four else { return }

        guard let five = test.five else { return }
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            options: FormatOptions(lineBetweenConsecutiveGuards: true),
            exclude: [.blankLinesBetweenScopes, .wrapConditionalBodies]
        )
    }

    func testSpacesBetweenSingleLineAndMultiLineGuardsWhenBlankLineInsertedBetweenConsecutiveGuards() {
        let input = """
        guard let one = test.one else { return }
        guard let two = test.two else { return }

        guard let three = test.three else {
            return
        }


        guard let four = test.four else { return }




        guard let five = test.five else {
            return
        }
        """
        let output = """
        guard let one = test.one else { return }

        guard let two = test.two else { return }

        guard let three = test.three else {
            return
        }

        guard let four = test.four else { return }

        guard let five = test.five else {
            return
        }
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            options: FormatOptions(lineBetweenConsecutiveGuards: true),
            exclude: [.blankLinesBetweenScopes, .wrapConditionalBodies]
        )
    }

    func testLinebreakAfterMultiLineGuard() {
        let input = """
        guard let one = test.one else {
            return
        }
        let x = test()
        """
        let output = """
        guard let one = test.one else {
            return
        }

        let x = test()
        """

        testFormatting(for: input, output, rule: .blankLinesAfterGuardStatements)
    }

    func testLinebreakAfterSingleLineGuard() {
        let input = """
        guard let one = test.one else { return }
        let x = test()
        """
        let output = """
        guard let one = test.one else { return }

        let x = test()
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            exclude: [.wrapConditionalBodies]
        )
    }

    func testLinebreakAfterMultiLineGuardWhenBlankLineInsertedBetweenConsecutiveGuards() {
        let input = """
        guard let one = test.one else {
            return
        }
        let x = test()
        """
        let output = """
        guard let one = test.one else {
            return
        }

        let x = test()
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            options: FormatOptions(lineBetweenConsecutiveGuards: true)
        )
    }

    func testLinebreakAfterSingleLineGuardWhenBlankLineInsertedBetweenConsecutiveGuards() {
        let input = """
        guard let one = test.one else { return }
        let x = test()
        """
        let output = """
        guard let one = test.one else { return }

        let x = test()
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            options: FormatOptions(lineBetweenConsecutiveGuards: true),
            exclude: [.wrapConditionalBodies]
        )
    }

    func testIncludedMultiLineGuard() {
        let input = """
        guard let one = test.one else {
            guard let two = test.two() else {
                return
            }
            return
        }

        guard let three = test.three() else {
            return
        }
        """
        let output = """
        guard let one = test.one else {
            guard let two = test.two() else {
                return
            }

            return
        }
        guard let three = test.three() else {
            return
        }
        """

        testFormatting(for: input, output, rule: .blankLinesAfterGuardStatements, exclude: [.blankLinesBetweenScopes])
    }

    func testIncludedSingleLineGuard() {
        let input = """
        guard let one = test.one else {
            guard let two = test.two() else { return }
            return
        }

        guard let three = test.three() else {
            return
        }
        """
        let output = """
        guard let one = test.one else {
            guard let two = test.two() else { return }

            return
        }
        guard let three = test.three() else {
            return
        }
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            exclude: [.blankLinesBetweenScopes, .wrapConditionalBodies]
        )
    }

    func testIncludedMultiLineGuardWhenBlankLineInsertedBetweenConsecutiveGuards() {
        let input = """
        guard let one = test.one else {
            guard let two = test.two() else {
                return
            }
            return
        }

        guard let three = test.three() else {
            return
        }
        """
        let output = """
        guard let one = test.one else {
            guard let two = test.two() else {
                return
            }

            return
        }

        guard let three = test.three() else {
            return
        }
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            options: FormatOptions(lineBetweenConsecutiveGuards: true),
            exclude: [.blankLinesBetweenScopes]
        )
    }

    func testIncludedSingleLineGuardWhenBlankLineInsertedBetweenConsecutiveGuards() {
        let input = """
        guard let one = test.one else {
            guard let two = test.two() else { return }
            return
        }

        guard let three = test.three() else {
            return
        }
        """
        let output = """
        guard let one = test.one else {
            guard let two = test.two() else { return }

            return
        }

        guard let three = test.three() else {
            return
        }
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            options: FormatOptions(lineBetweenConsecutiveGuards: true),
            exclude: [.blankLinesBetweenScopes, .wrapConditionalBodies]
        )
    }

    func testEndBracketAndIf() {
        let input = """
        guard let something = test.something else {
            return
        }
        if someone == someoneElse {
            guard let nextTime else {
                return
            }
        }
        """
        let output = """
        guard let something = test.something else {
            return
        }

        if someone == someoneElse {
            guard let nextTime else {
                return
            }
        }
        """

        testFormatting(for: input, output, rule: .blankLinesAfterGuardStatements)
    }

    func testSingleLineGuardAndIf() {
        let input = """
        guard let something = test.something else { return }
        if someone == someoneElse {
            guard let nextTime else { return }
        }
        """
        let output = """
        guard let something = test.something else { return }

        if someone == someoneElse {
            guard let nextTime else { return }
        }
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            exclude: [.wrapConditionalBodies]
        )
    }

    func testEndBracketAndIfWhenBlankLineInsertedBetweenConsecutiveGuards() {
        let input = """
        guard let something = test.something else {
            return
        }
        if someone == someoneElse {
            guard let nextTime else {
                return
            }
        }
        """
        let output = """
        guard let something = test.something else {
            return
        }

        if someone == someoneElse {
            guard let nextTime else {
                return
            }
        }
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            options: FormatOptions(lineBetweenConsecutiveGuards: true)
        )
    }

    func testSingleLineGuardAndIfWhenBlankLineInsertedBetweenConsecutiveGuards() {
        let input = """
        guard let something = test.something else { return }
        if someone == someoneElse {
            guard let nextTime else { return }
        }
        """
        let output = """
        guard let something = test.something else { return }

        if someone == someoneElse {
            guard let nextTime else { return }
        }
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            options: FormatOptions(lineBetweenConsecutiveGuards: true),
            exclude: [.wrapConditionalBodies]
        )
    }

    func testMultiLineGuardAndComments() {
        let input = """
        guard let somethingTwo = test.somethingTwo else {
            return
        }
        // commentOne
        guard let somethingOne = test.somethingOne else {
            return
        }
        // commentTwo
        let something = xxx
        """

        let output = """
        guard let somethingTwo = test.somethingTwo else {
            return
        }

        // commentOne
        guard let somethingOne = test.somethingOne else {
            return
        }

        // commentTwo
        let something = xxx
        """

        testFormatting(for: input, output, rule: .blankLinesAfterGuardStatements, exclude: [.docComments])
    }

    func testSingleLineGuardAndComments() {
        let input = """
        guard let somethingTwo = test.somethingTwo else { return }
        // commentOne
        guard let somethingOne = test.somethingOne else { return }
        // commentTwo
        let something = xxx
        """

        let output = """
        guard let somethingTwo = test.somethingTwo else { return }

        // commentOne
        guard let somethingOne = test.somethingOne else { return }

        // commentTwo
        let something = xxx
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            exclude: [.docComments, .wrapConditionalBodies]
        )
    }

    func testMultiLineGuardAndCommentsWhenBlankLineInsertedBetweenConsecutiveGuards() {
        let input = """
        guard let somethingTwo = test.somethingTwo else {
            return
        }
        // commentOne
        guard let somethingOne = test.somethingOne else {
            return
        }
        // commentTwo
        let something = xxx
        """

        let output = """
        guard let somethingTwo = test.somethingTwo else {
            return
        }

        // commentOne
        guard let somethingOne = test.somethingOne else {
            return
        }

        // commentTwo
        let something = xxx
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            options: FormatOptions(lineBetweenConsecutiveGuards: true),
            exclude: [.docComments]
        )
    }

    func testSingleLineGuardAndCommentsWhenBlankLineInsertedBetweenConsecutiveGuards() {
        let input = """
        guard let somethingTwo = test.somethingTwo else { return }
        // commentOne
        guard let somethingOne = test.somethingOne else { return }
        // commentTwo
        let something = xxx
        """

        let output = """
        guard let somethingTwo = test.somethingTwo else { return }

        // commentOne
        guard let somethingOne = test.somethingOne else { return }

        // commentTwo
        let something = xxx
        """

        testFormatting(
            for: input,
            output,
            rule: .blankLinesAfterGuardStatements,
            options: FormatOptions(lineBetweenConsecutiveGuards: true),
            exclude: [.docComments, .wrapConditionalBodies]
        )
    }

    func testNotInsertLineBreakWhenInlineFunction() {
        let input = """
        let array = [1, 2, 3]
        guard array.map { String($0) }.isEmpty else {
            return
        }
        """
        testFormatting(for: input, rule: .blankLinesAfterGuardStatements, exclude: [.wrapConditionalBodies])
    }

    func testNotInsertLineBreakWhenInlineFunctionAndBlankLineInsertedBetweenConsecutiveGuards() {
        let input = """
        let array = [1, 2, 3]
        guard array.map { String($0) }.isEmpty else {
            return
        }
        """
        testFormatting(
            for: input,
            rule: .blankLinesAfterGuardStatements,
            options: FormatOptions(lineBetweenConsecutiveGuards: true),
            exclude: [.wrapConditionalBodies]
        )
    }

    func testNotInsertLineBreakInChain() {
        let input = """
        guard aBool,
              anotherBool,
              aTestArray
              .map { $0 * 2 }
              .filter { $0 == 4 }
              .isEmpty,
              yetAnotherBool
        else { return }
        """

        testFormatting(for: input, rule: .blankLinesAfterGuardStatements, exclude: [.wrapConditionalBodies])
    }

    func testNotInsertLineBreakInChainWhenBlankLineInsertedBetweenConsecutiveGuards() {
        let input = """
        guard aBool,
              anotherBool,
              aTestArray
              .map { $0 * 2 }
              .filter { $0 == 4 }
              .isEmpty,
              yetAnotherBool
        else { return }
        """

        testFormatting(
            for: input,
            rule: .blankLinesAfterGuardStatements,
            options: FormatOptions(lineBetweenConsecutiveGuards: true),
            exclude: [.wrapConditionalBodies]
        )
    }
}
