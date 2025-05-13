// Created by @NikeKov on 01.08.2024
// Copyright © 2024 Nick Lockwood. All rights reserved.

import XCTest
@testable import SwiftFormat

final class BlankLinesAfterGuardStatementsTests: XCTestCase {
    func testSpacesBetweenGuard() {
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

    func testLinebreakAfterGuard() {
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

    func testIncludedGuard() {
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

    func testComments() {
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

    func testNotInsertLineBreakWhenInlineFunction() {
        let input = """
        let array = [1, 2, 3]
        guard array.map { String($0) }.isEmpty else {
            return
        }
        """
        testFormatting(for: input, rule: .blankLinesAfterGuardStatements, exclude: [.wrapConditionalBodies])
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
}
