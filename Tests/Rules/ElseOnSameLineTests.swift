//
//  ElseOnSameLineTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 8/22/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class ElseOnSameLineTests: XCTestCase {
    func testElseOnSameLine() {
        let input = """
        if true {
            1
        }
        else { 2 }
        """
        let output = """
        if true {
            1
        } else { 2 }
        """
        testFormatting(for: input, output, rule: .elseOnSameLine,
                       exclude: [.wrapConditionalBodies])
    }

    func testElseOnSameLineOnlyAppliedToDanglingBrace() {
        let input = """
        if true { 1 }
        else { 2 }
        """
        testFormatting(for: input, rule: .elseOnSameLine,
                       exclude: [.wrapConditionalBodies])
    }

    func testGuardNotAffectedByElseOnSameLine() {
        let input = """
        guard true
        else { return }
        """
        testFormatting(for: input, rule: .elseOnSameLine,
                       exclude: [.wrapConditionalBodies])
    }

    func testElseOnSameLineDoesntEatPreviousStatement() {
        let input = """
        if true {}
        guard true else { return }
        """
        testFormatting(for: input, rule: .elseOnSameLine,
                       exclude: [.wrapConditionalBodies])
    }

    func testElseNotOnSameLineForAllman() {
        let input = """
        if true
        {
            1
        } else { 2 }
        """
        let output = """
        if true
        {
            1
        }
        else { 2 }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: .elseOnSameLine,
                       options: options, exclude: [.wrapConditionalBodies])
    }

    func testElseOnNextLineOption() {
        let input = """
        if true {
            1
        } else { 2 }
        """
        let output = """
        if true {
            1
        }
        else { 2 }
        """
        let options = FormatOptions(elsePosition: .nextLine)
        testFormatting(for: input, output, rule: .elseOnSameLine,
                       options: options, exclude: [.wrapConditionalBodies])
    }

    func testGuardNotAffectedByElseOnSameLineForAllman() {
        let input = """
        guard true else { return }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, rule: .elseOnSameLine,
                       options: options, exclude: [.wrapConditionalBodies])
    }

    func testRepeatWhileNotOnSameLineForAllman() {
        let input = """
        repeat
        {
            foo
        } while x
        """
        let output = """
        repeat
        {
            foo
        }
        while x
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: .elseOnSameLine, options: options)
    }

    func testWhileNotAffectedByElseOnSameLineIfNotRepeatWhile() {
        let input = """
        func foo(x) {}

        while true {}
        """
        testFormatting(for: input, rule: .elseOnSameLine)
    }

    func testCommentsNotDiscardedByElseOnSameLineRule() {
        let input = """
        if true {
            1
        }

        // comment
        else {}
        """
        testFormatting(for: input, rule: .elseOnSameLine)
    }

    func testElseOnSameLineInferenceEdgeCase() {
        let input = """
        func foo() {
            if let foo == bar {
                // ...
            } else {
                // ...
            }

            if let foo == bar,
               let baz = quux
            {
                print()
            }

            if let foo == bar,
               let baz = quux
            {
                print()
            }

            if let foo == bar,
               let baz = quux
            {
                print()
            }

            if let foo == bar,
               let baz = quux
            {
                print()
            }
        }
        """
        let options = FormatOptions(elsePosition: .sameLine)
        testFormatting(for: input, rule: .elseOnSameLine, options: options,
                       exclude: [.braces])
    }

    // guardelse = auto

    func testSingleLineGuardElseNotWrappedByDefault() {
        let input = """
        guard foo = bar else {}
        """
        testFormatting(for: input, rule: .elseOnSameLine,
                       exclude: [.wrapConditionalBodies])
    }

    func testSingleLineGuardElseNotUnwrappedByDefault() {
        let input = """
        guard foo = bar
        else {}
        """
        testFormatting(for: input, rule: .elseOnSameLine,
                       exclude: [.wrapConditionalBodies])
    }

    func testSingleLineGuardElseWrappedByDefaultIfBracesOnNextLine() {
        let input = """
        guard foo = bar else
        {}
        """
        let output = """
        guard foo = bar
        else {}
        """
        testFormatting(for: input, output, rule: .elseOnSameLine,
                       exclude: [.wrapConditionalBodies])
    }

    func testMultilineGuardElseNotWrappedByDefault() {
        let input = """
        guard let foo = bar,
              bar > 5 else {
            return
        }
        """
        testFormatting(for: input, rule: .elseOnSameLine,
                       exclude: [.wrapMultilineStatementBraces])
    }

    func testMultilineGuardElseWrappedByDefaultIfBracesOnNextLine() {
        let input = """
        guard let foo = bar,
              bar > 5 else
        {
            return
        }
        """
        let output = """
        guard let foo = bar,
              bar > 5
        else {
            return
        }
        """
        testFormatting(for: input, output, rule: .elseOnSameLine)
    }

    func testWrappedMultilineGuardElseCorrectlyIndented() {
        let input = """
        func foo() {
            guard let foo = bar,
                  bar > 5 else
            {
                return
            }
        }
        """
        let output = """
        func foo() {
            guard let foo = bar,
                  bar > 5
            else {
                return
            }
        }
        """
        testFormatting(for: input, output, rule: .elseOnSameLine)
    }

    func testMultilineGuardElseEndingInParen() {
        let input = """
        guard let foo = bar,
              let baz = quux() else
        {
            return
        }
        """
        let output = """
        guard let foo = bar,
              let baz = quux()
        else {
            return
        }
        """
        testFormatting(for: input, output, rule: .elseOnSameLine)
    }

    // guardelse = nextLine

    func testSingleLineGuardElseNotWrapped() {
        let input = """
        guard foo = bar else {}
        """
        let options = FormatOptions(guardElsePosition: .nextLine)
        testFormatting(for: input, rule: .elseOnSameLine,
                       options: options, exclude: [.wrapConditionalBodies])
    }

    func testSingleLineGuardElseNotUnwrapped() {
        let input = """
        guard foo = bar
        else {}
        """
        let options = FormatOptions(guardElsePosition: .nextLine)
        testFormatting(for: input, rule: .elseOnSameLine,
                       options: options, exclude: [.wrapConditionalBodies])
    }

    func testSingleLineGuardElseWrappedIfBracesOnNextLine() {
        let input = """
        guard foo = bar else
        {}
        """
        let output = """
        guard foo = bar
        else {}
        """
        let options = FormatOptions(guardElsePosition: .nextLine)
        testFormatting(for: input, output, rule: .elseOnSameLine,
                       options: options, exclude: [.wrapConditionalBodies])
    }

    func testMultilineGuardElseWrapped() {
        let input = """
        guard let foo = bar,
              bar > 5 else {
            return
        }
        """
        let output = """
        guard let foo = bar,
              bar > 5
        else {
            return
        }
        """
        let options = FormatOptions(guardElsePosition: .nextLine)
        testFormatting(for: input, output, rule: .elseOnSameLine,
                       options: options, exclude: [.wrapMultilineStatementBraces])
    }

    // guardelse = sameLine

    func testMultilineGuardElseUnwrapped() {
        let input = """
        guard let foo = bar,
              bar > 5
        else {
            return
        }
        """
        let output = """
        guard let foo = bar,
              bar > 5 else {
            return
        }
        """
        let options = FormatOptions(guardElsePosition: .sameLine)
        testFormatting(for: input, output, rule: .elseOnSameLine,
                       options: options, exclude: [.wrapMultilineStatementBraces])
    }

    func testGuardElseUnwrappedIfBracesOnNextLine() {
        let input = """
        guard foo = bar
        else {}
        """
        let output = """
        guard foo = bar else {}
        """
        let options = FormatOptions(guardElsePosition: .sameLine)
        testFormatting(for: input, output, rule: .elseOnSameLine,
                       options: options)
    }

    func testPreserveBlankLineBeforeElse() {
        let input = """
        if foo {
            print("foo")
        }

        else if bar {
            print("bar")
        }

        else {
            print("baaz")
        }
        """

        testFormatting(for: input, rule: .elseOnSameLine)
    }

    func testPreserveBlankLineBeforeElseOnSameLine() {
        let input = """
        if foo {
            print("foo")
        }

        else if bar {
            print("bar")
        }

        else {
            print("baaz")
        }
        """

        let options = FormatOptions(elsePosition: .sameLine)
        testFormatting(for: input, rule: .elseOnSameLine, options: options)
    }

    func testPreserveBlankLineBeforeElseWithComments() {
        let input = """
        if foo {
            print("foo")
        }
        // Comment before else if
        else if bar {
            print("bar")
        }

        // Comment before else
        else {
            print("baaz")
        }
        """

        testFormatting(for: input, rule: .elseOnSameLine)
    }

    func testPreserveBlankLineBeforeElseDoesntAffectOtherCases() {
        let input = """
        if foo {
            print("foo")
        }
        else {
            print("bar")
        }

        guard foo else {
            return
        }

        guard
            let foo,
            let bar,
            lat baaz else
        {
            return
        }
        """

        let output = """
        if foo {
            print("foo")
        } else {
            print("bar")
        }

        guard foo else {
            return
        }

        guard
            let foo,
            let bar,
            lat baaz
        else {
            return
        }
        """

        let options = FormatOptions(elsePosition: .sameLine, guardElsePosition: .nextLine)
        testFormatting(for: input, output, rule: .elseOnSameLine, options: options, exclude: [.blankLinesAfterGuardStatements])
    }
}
