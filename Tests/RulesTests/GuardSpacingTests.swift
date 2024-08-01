// GuardSpacingTests.swift
// GuardSpacingTests
//
// Created by @NikeKov on 27.07.2024
// Copyright © 2024 Nick Lockwood. All rights reserved.

import XCTest
@testable import SwiftFormat

final class GuardSpacingTests: RulesTests {
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

        testFormatting(for: input, output, rule: FormatRules.guardSpacing)
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

        testFormatting(for: input, output, rule: FormatRules.guardSpacing)
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

        testFormatting(for: input, output, rule: FormatRules.guardSpacing)
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

        testFormatting(for: input, output, rule: FormatRules.guardSpacing)
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

        testFormatting(for: input, output, rule: FormatRules.guardSpacing, exclude: ["docComments"])
    }
}
