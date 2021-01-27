//
//  RulesTests+Wrapping.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 04/09/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class WrappingTests: RulesTests {
    // MARK: - elseOnSameLine

    func testElseOnSameLine() {
        let input = "if true {\n    1\n}\nelse { 2 }"
        let output = "if true {\n    1\n} else { 2 }"
        testFormatting(for: input, output, rule: FormatRules.elseOnSameLine,
                       exclude: ["wrapConditionalBodies"])
    }

    func testElseOnSameLineOnlyAppliedToDanglingBrace() {
        let input = "if true { 1 }\nelse { 2 }"
        testFormatting(for: input, rule: FormatRules.elseOnSameLine,
                       exclude: ["wrapConditionalBodies"])
    }

    func testGuardNotAffectedByElseOnSameLine() {
        let input = "guard true\nelse { return }"
        testFormatting(for: input, rule: FormatRules.elseOnSameLine,
                       exclude: ["wrapConditionalBodies"])
    }

    func testElseOnSameLineDoesntEatPreviousStatement() {
        let input = "if true {}\nguard true else { return }"
        testFormatting(for: input, rule: FormatRules.elseOnSameLine,
                       exclude: ["wrapConditionalBodies"])
    }

    func testElseNotOnSameLineForAllman() {
        let input = "if true\n{\n    1\n} else { 2 }"
        let output = "if true\n{\n    1\n}\nelse { 2 }"
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: FormatRules.elseOnSameLine,
                       options: options, exclude: ["wrapConditionalBodies"])
    }

    func testElseOnNextLineOption() {
        let input = "if true {\n    1\n} else { 2 }"
        let output = "if true {\n    1\n}\nelse { 2 }"
        let options = FormatOptions(elseOnNextLine: true)
        testFormatting(for: input, output, rule: FormatRules.elseOnSameLine,
                       options: options, exclude: ["wrapConditionalBodies"])
    }

    func testGuardNotAffectedByElseOnSameLineForAllman() {
        let input = "guard true else { return }"
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, rule: FormatRules.elseOnSameLine,
                       options: options, exclude: ["wrapConditionalBodies"])
    }

    func testRepeatWhileNotOnSameLineForAllman() {
        let input = "repeat\n{\n    foo\n} while x"
        let output = "repeat\n{\n    foo\n}\nwhile x"
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: FormatRules.elseOnSameLine, options: options)
    }

    func testWhileNotAffectedByElseOnSameLineIfNotRepeatWhile() {
        let input = "func foo(x) {}\n\nwhile true {}"
        testFormatting(for: input, rule: FormatRules.elseOnSameLine)
    }

    func testCommentsNotDiscardedByElseOnSameLineRule() {
        let input = "if true {\n    1\n}\n\n// comment\nelse {}"
        testFormatting(for: input, rule: FormatRules.elseOnSameLine)
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
        let options = FormatOptions(elseOnNextLine: false)
        testFormatting(for: input, rule: FormatRules.elseOnSameLine, options: options,
                       exclude: ["braces"])
    }

    // guardelse = auto

    func testSingleLineGuardElseNotWrappedByDefault() {
        let input = "guard foo = bar else {}"
        testFormatting(for: input, rule: FormatRules.elseOnSameLine,
                       exclude: ["wrapConditionalBodies"])
    }

    func testSingleLineGuardElseNotUnwrappedByDefault() {
        let input = "guard foo = bar\nelse {}"
        testFormatting(for: input, rule: FormatRules.elseOnSameLine,
                       exclude: ["wrapConditionalBodies"])
    }

    func testSingleLineGuardElseWrappedByDefaultIfBracesOnNextLine() {
        let input = "guard foo = bar else\n{}"
        let output = "guard foo = bar\nelse {}"
        testFormatting(for: input, output, rule: FormatRules.elseOnSameLine,
                       exclude: ["wrapConditionalBodies"])
    }

    func testMultilineGuardElseNotWrappedByDefault() {
        let input = """
        guard let foo = bar,
              bar > 5 else {
            return
        }
        """
        testFormatting(for: input, rule: FormatRules.elseOnSameLine,
                       exclude: ["wrapMultilineStatementBraces"])
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
        testFormatting(for: input, output, rule: FormatRules.elseOnSameLine)
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
        testFormatting(for: input, output, rule: FormatRules.elseOnSameLine)
    }

    // guardelse = nextLine

    func testSingleLineGuardElseNotWrapped() {
        let input = "guard foo = bar else {}"
        let options = FormatOptions(guardElsePosition: .nextLine)
        testFormatting(for: input, rule: FormatRules.elseOnSameLine,
                       options: options, exclude: ["wrapConditionalBodies"])
    }

    func testSingleLineGuardElseNotUnwrapped() {
        let input = "guard foo = bar\nelse {}"
        let options = FormatOptions(guardElsePosition: .nextLine)
        testFormatting(for: input, rule: FormatRules.elseOnSameLine,
                       options: options, exclude: ["wrapConditionalBodies"])
    }

    func testSingleLineGuardElseWrappedIfBracesOnNextLine() {
        let input = "guard foo = bar else\n{}"
        let output = "guard foo = bar\nelse {}"
        let options = FormatOptions(guardElsePosition: .nextLine)
        testFormatting(for: input, output, rule: FormatRules.elseOnSameLine,
                       options: options, exclude: ["wrapConditionalBodies"])
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
        testFormatting(for: input, output, rule: FormatRules.elseOnSameLine,
                       options: options, exclude: ["wrapMultilineStatementBraces"])
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
        let options = FormatOptions(guardElsePosition: .auto)
        testFormatting(for: input, output, rule: FormatRules.elseOnSameLine,
                       options: options)
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
        testFormatting(for: input, output, rule: FormatRules.elseOnSameLine,
                       options: options, exclude: ["wrapMultilineStatementBraces"])
    }

    func testGuardElseUnwrappedIfBracesOnNextLine() {
        let input = "guard foo = bar\nelse {}"
        let output = "guard foo = bar else {}"
        let options = FormatOptions(guardElsePosition: .sameLine)
        testFormatting(for: input, output, rule: FormatRules.elseOnSameLine,
                       options: options)
    }

    // MARK: - wrapConditionalBodies

    func testGuardReturnWraps() {
        let input = "guard let foo = bar else { return }"
        let output = """
        guard let foo = bar else {
            return
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapConditionalBodies)
    }

    func testEmptyGuardReturnWithSpaceDoesNothing() {
        let input = "guard let foo = bar else { }"
        testFormatting(for: input, rule: FormatRules.wrapConditionalBodies,
                       exclude: ["emptyBraces"])
    }

    func testEmptyGuardReturnWithoutSpaceDoesNothing() {
        let input = "guard let foo = bar else {}"
        testFormatting(for: input, rule: FormatRules.wrapConditionalBodies,
                       exclude: ["emptyBraces"])
    }

    func testGuardReturnWithValueWraps() {
        let input = "guard let foo = bar else { return baz }"
        let output = """
        guard let foo = bar else {
            return baz
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapConditionalBodies)
    }

    func testGuardBodyWithClosingBraceAlreadyOnNewlineWraps() {
        let input = """
        guard foo else { return
        }
        """
        let output = """
        guard foo else {
            return
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapConditionalBodies)
    }

    func testGuardContinueWithNoSpacesToCleanupWraps() {
        let input = "guard let foo = bar else {continue}"
        let output = """
        guard let foo = bar else {
            continue
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapConditionalBodies)
    }

    func testGuardReturnWrapsSemicolonDelimitedStatements() {
        let input = "guard let foo = bar else { var baz = 0; let boo = 1; fatalError() }"
        let output = """
        guard let foo = bar else {
            var baz = 0; let boo = 1; fatalError()
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapConditionalBodies)
    }

    func testGuardReturnWrapsSemicolonDelimitedStatementsWithNoSpaces() {
        let input = "guard let foo = bar else {var baz=0;let boo=1;fatalError()}"
        let output = """
        guard let foo = bar else {
            var baz=0;let boo=1;fatalError()
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapConditionalBodies,
                       exclude: ["spaceAroundOperators"])
    }

    func testGuardReturnOnNewlineUnchanged() {
        let input = """
        guard let foo = bar else {
            return
        }
        """
        testFormatting(for: input, rule: FormatRules.wrapConditionalBodies)
    }

    func testGuardCommentSameLineUnchanged() {
        let input = """
        guard let foo = bar else { // Test comment
            return
        }
        """
        testFormatting(for: input, rule: FormatRules.wrapConditionalBodies)
    }

    func testGuardMultilineCommentSameLineUnchanged() {
        let input = "guard let foo = bar else { /* Test comment */ return }"
        let output = """
        guard let foo = bar else { /* Test comment */
            return
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapConditionalBodies)
    }

    func testGuardTwoMultilineCommentsSameLine() {
        let input = "guard let foo = bar else { /* Test comment 1 */ return /* Test comment 2 */ }"
        let output = """
        guard let foo = bar else { /* Test comment 1 */
            return /* Test comment 2 */
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapConditionalBodies)
    }

    func testNestedGuardElseIfStatementsPutOnNewline() {
        let input = "guard let foo = bar else { if qux { return quux } else { return quuz } }"
        let output = """
        guard let foo = bar else {
            if qux {
                return quux
            } else {
                return quuz
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapConditionalBodies)
    }

    func testNestedGuardElseGuardStatementPutOnNewline() {
        let input = "guard let foo = bar else { guard qux else { return quux } }"
        let output = """
        guard let foo = bar else {
            guard qux else {
                return quux
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapConditionalBodies)
    }

    func testGuardWithClosureOnlyWrapsElseBody() {
        let input = "guard foo { $0.bar } else { return true }"
        let output = """
        guard foo { $0.bar } else {
            return true
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapConditionalBodies)
    }

    func testIfElseReturnsWrap() {
        let input = "if foo { return bar } else if baz { return qux } else { return quux }"
        let output = """
        if foo {
            return bar
        } else if baz {
            return qux
        } else {
            return quux
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapConditionalBodies)
    }

    func testIfElseBodiesWrap() {
        let input = "if foo { bar } else if baz { qux } else { quux }"
        let output = """
        if foo {
            bar
        } else if baz {
            qux
        } else {
            quux
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapConditionalBodies)
    }

    func testIfElsesWithClosuresDontWrapClosures() {
        let input = "if foo { $0.bar } { baz } else if qux { $0.quux } { quuz } else { corge }"
        let output = """
        if foo { $0.bar } {
            baz
        } else if qux { $0.quux } {
            quuz
        } else {
            corge
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapConditionalBodies)
    }

    func testEmptyIfElseBodiesWithSpaceDoNothing() {
        let input = "if foo { } else if baz { } else { }"
        testFormatting(for: input, rule: FormatRules.wrapConditionalBodies,
                       exclude: ["emptyBraces"])
    }

    func testEmptyIfElseBodiesWithoutSpaceDoNothing() {
        let input = "if foo {} else if baz {} else {}"
        testFormatting(for: input, rule: FormatRules.wrapConditionalBodies,
                       exclude: ["emptyBraces"])
    }

    func testGuardElseBraceStartingOnDifferentLine() {
        let input = """
        guard foo else
            { return bar }
        """
        let output = """
        guard foo else
            {
            return bar
        }
        """

        testFormatting(for: input, output, rule: FormatRules.wrapConditionalBodies,
                       exclude: ["braces", "indent", "elseOnSameLine"])
    }

    func testIfElseBracesStartingOnDifferentLines() {
        let input = """
        if foo
            { return bar }
        else if baz
            { return qux }
        else
            { return quux }
        """
        let output = """
        if foo
            {
            return bar
        }
        else if baz
            {
            return qux
        }
        else
            {
            return quux
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapConditionalBodies,
                       exclude: ["braces", "indent", "elseOnSameLine"])
    }

    // MARK: - wrap

    func testWrapIfStatement() {
        let input = """
        if let foo = foo, let bar = bar, let baz = baz {}
        """
        let output = """
        if let foo = foo,
           let bar = bar,
           let baz = baz {}
        """
        let options = FormatOptions(maxWidth: 20)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testWrapIfElseStatement() {
        let input = """
        if let foo = foo {} else if let bar = bar {}
        """
        let output = """
        if let foo = foo {}
            else if let bar =
            bar {}
        """
        let output2 = """
        if let foo = foo {}
        else if let bar =
            bar {}
        """
        let options = FormatOptions(maxWidth: 20)
        testFormatting(for: input, [output, output2], rules: [FormatRules.wrap], options: options)
    }

    func testWrapGuardStatement() {
        let input = """
        guard let foo = foo, let bar = bar else {
            break
        }
        """
        let output = """
        guard let foo = foo,
              let bar = bar
              else {
            break
        }
        """
        let output2 = """
        guard let foo = foo,
              let bar = bar
        else {
            break
        }
        """
        let options = FormatOptions(maxWidth: 20)
        testFormatting(for: input, [output, output2], rules: [FormatRules.wrap], options: options, exclude: ["wrapMultilineStatementBraces"])
    }

    func testWrapClosure() {
        let input = """
        let foo = { () -> Bool in true }
        """
        let output = """
        let foo =
            { () -> Bool in
            true }
        """
        let output2 = """
        let foo =
            { () -> Bool in
                true
            }
        """
        let options = FormatOptions(maxWidth: 20)
        testFormatting(for: input, [output, output2], rules: [FormatRules.wrap], options: options)
    }

    func testWrapClosure2() {
        let input = """
        let foo = { bar, _ in bar }
        """
        let output = """
        let foo =
            { bar, _ in
            bar }
        """
        let output2 = """
        let foo =
            { bar, _ in
                bar
            }
        """
        let options = FormatOptions(maxWidth: 20)
        testFormatting(for: input, [output, output2], rules: [FormatRules.wrap], options: options)
    }

    func testWrapClosureWithAllmanBraces() {
        let input = """
        let foo = { bar, _ in bar }
        """
        let output = """
        let foo =
            { bar, _ in
            bar }
        """
        let output2 = """
        let foo =
        { bar, _ in
            bar
        }
        """
        let options = FormatOptions(allmanBraces: true, maxWidth: 20)
        testFormatting(for: input, [output, output2], rules: [FormatRules.wrap], options: options)
    }

    func testWrapClosure3() {
        let input = "let foo = bar { $0.baz }"
        let output = """
        let foo = bar {
            $0.baz }
        """
        let output2 = """
        let foo = bar {
            $0.baz
        }
        """
        let options = FormatOptions(maxWidth: 20)
        testFormatting(for: input, [output, output2], rules: [FormatRules.wrap], options: options)
    }

    func testWrapFunctionIfReturnTypeExceedsMaxWidth() {
        let input = """
        func testFunc() -> ReturnType {
            doSomething()
            doSomething()
        }
        """
        let output = """
        func testFunc()
            -> ReturnType {
            doSomething()
            doSomething()
        }
        """
        let options = FormatOptions(maxWidth: 25)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options, exclude: ["wrapMultilineStatementBraces"])
    }

    func testWrapFunctionIfReturnTypeExceedsMaxWidthWithXcodeIndentation() {
        let input = """
        func testFunc() -> ReturnType {
            doSomething()
            doSomething()
        }
        """
        let output = """
        func testFunc()
            -> ReturnType {
            doSomething()
            doSomething()
        }
        """
        let output2 = """
        func testFunc()
        -> ReturnType {
            doSomething()
            doSomething()
        }
        """
        let options = FormatOptions(xcodeIndentation: true, maxWidth: 25)
        testFormatting(for: input, [output, output2], rules: [FormatRules.wrap], options: options, exclude: ["wrapMultilineStatementBraces"])
    }

    func testWrapFunctionIfReturnTypeExceedsMaxWidth2() {
        let input = """
        func testFunc() -> (ReturnType, ReturnType2) {
            doSomething()
        }
        """
        let output = """
        func testFunc()
            -> (ReturnType, ReturnType2) {
            doSomething()
        }
        """
        let options = FormatOptions(maxWidth: 35)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options, exclude: ["wrapMultilineStatementBraces"])
    }

    func testWrapFunctionIfReturnTypeExceedsMaxWidth2WithXcodeIndentation() {
        let input = """
        func testFunc() throws -> (ReturnType, ReturnType2) {
            doSomething()
        }
        """
        let output = """
        func testFunc() throws
            -> (ReturnType, ReturnType2) {
            doSomething()
        }
        """
        let output2 = """
        func testFunc() throws
        -> (ReturnType, ReturnType2) {
            doSomething()
        }
        """
        let options = FormatOptions(xcodeIndentation: true, maxWidth: 35)
        testFormatting(for: input, [output, output2], rules: [FormatRules.wrap], options: options, exclude: ["wrapMultilineStatementBraces"])
    }

    func testWrapFunctionIfReturnTypeExceedsMaxWidth3() {
        let input = """
        func testFunc() -> (Bool, String) -> String? {
            doSomething()
        }
        """
        let output = """
        func testFunc()
            -> (Bool, String) -> String? {
            doSomething()
        }
        """
        let options = FormatOptions(maxWidth: 35)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options, exclude: ["wrapMultilineStatementBraces"])
    }

    func testWrapFunctionIfReturnTypeExceedsMaxWidth3WithXcodeIndentation() {
        let input = """
        func testFunc() -> (Bool, String) -> String? {
            doSomething()
        }
        """
        let output = """
        func testFunc()
            -> (Bool, String) -> String? {
            doSomething()
        }
        """
        let output2 = """
        func testFunc()
        -> (Bool, String) -> String? {
            doSomething()
        }
        """
        let options = FormatOptions(xcodeIndentation: true, maxWidth: 35)
        testFormatting(for: input, [output, output2], rules: [FormatRules.wrap], options: options, exclude: ["wrapMultilineStatementBraces"])
    }

    func testWrapFunctionIfReturnTypeExceedsMaxWidth4() {
        let input = """
        func testFunc(_: () -> Void) -> (Bool, String) -> String? {
            doSomething()
        }
        """
        let output = """
        func testFunc(_: () -> Void)
            -> (Bool, String) -> String? {
            doSomething()
        }
        """
        let options = FormatOptions(maxWidth: 35)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options, exclude: ["wrapMultilineStatementBraces"])
    }

    func testWrapFunctionIfReturnTypeExceedsMaxWidth4WithXcodeIndentation() {
        let input = """
        func testFunc(_: () -> Void) -> (Bool, String) -> String? {
            doSomething()
        }
        """
        let output = """
        func testFunc(_: () -> Void)
            -> (Bool, String) -> String? {
            doSomething()
        }
        """
        let output2 = """
        func testFunc(_: () -> Void)
        -> (Bool, String) -> String? {
            doSomething()
        }
        """
        let options = FormatOptions(xcodeIndentation: true, maxWidth: 35)
        testFormatting(for: input, [output, output2], rules: [FormatRules.wrap], options: options, exclude: ["wrapMultilineStatementBraces"])
    }

    func testWrapChainedFunctionAfterSubscriptCollection() {
        let input = """
        let foo = bar["baz"].quuz()
        """
        let output = """
        let foo = bar["baz"]
            .quuz()
        """
        let options = FormatOptions(maxWidth: 20)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testWrapChainedFunctionInSubscriptCollection() {
        let input = """
        let foo = bar[baz.quuz()]
        """
        let output = """
        let foo =
            bar[baz.quuz()]
        """
        let options = FormatOptions(maxWidth: 20)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testWrapThrowingFunctionIfReturnTypeExceedsMaxWidth() {
        let input = """
        func testFunc(_: () -> Void) throws -> (Bool, String) -> String? {
            doSomething()
        }
        """
        let output = """
        func testFunc(_: () -> Void) throws
            -> (Bool, String) -> String? {
            doSomething()
        }
        """
        let options = FormatOptions(maxWidth: 42)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options, exclude: ["wrapMultilineStatementBraces"])
    }

    func testNoWrapInterpolatedStringLiteral() {
        let input = """
        "a very long \\(string) literal"
        """
        let options = FormatOptions(maxWidth: 20)
        testFormatting(for: input, rule: FormatRules.wrap, options: options)
    }

    func testNoWrapAtUnspacedOperator() {
        let input = "let foo = bar+baz+quux"
        let output = "let foo =\n    bar+baz+quux"
        let options = FormatOptions(maxWidth: 15)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options,
                       exclude: ["spaceAroundOperators"])
    }

    func testNoWrapAtUnspacedEquals() {
        let input = "let foo=bar+baz+quux"
        let options = FormatOptions(maxWidth: 15)
        testFormatting(for: input, rule: FormatRules.wrap, options: options,
                       exclude: ["spaceAroundOperators"])
    }

    func testNoWrapSingleParameter() {
        let input = "let fooBar = try unkeyedContainer.decode(FooBar.self)"
        let output = """
        let fooBar = try unkeyedContainer
            .decode(FooBar.self)
        """
        let options = FormatOptions(maxWidth: 50)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testWrapSingleParameter() {
        let input = "let fooBar = try unkeyedContainer.decode(FooBar.self)"
        let output = """
        let fooBar = try unkeyedContainer.decode(
            FooBar.self
        )
        """
        let options = FormatOptions(maxWidth: 50, noWrapOperators: [".", "="])
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testWrapFunctionArrow() {
        let input = "func foo() -> Int {}"
        let output = """
        func foo()
            -> Int {}
        """
        let options = FormatOptions(maxWidth: 14)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testNoWrapFunctionArrow() {
        let input = "func foo() -> Int {}"
        let output = """
        func foo(
        ) -> Int {}
        """
        let options = FormatOptions(maxWidth: 14, noWrapOperators: ["->"])
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testNoCrashWrap() {
        let input = """
        struct Foo {
            func bar(a: Set<B>, c: D) {}
        }
        """
        let output = """
        struct Foo {
            func bar(
                a: Set<
                    B
                >,
                c: D
            ) {}
        }
        """
        let options = FormatOptions(maxWidth: 10)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options,
                       exclude: ["unusedArguments"])
    }

    func testNoCrashWrap2() {
        let input = """
        struct Test {
            func webView(_: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
                authenticationChallengeProcessor.process(challenge: challenge, completionHandler: completionHandler)
            }
        }
        """
        let output = """
        struct Test {
            func webView(
                _: WKWebView,
                didReceive challenge: URLAuthenticationChallenge,
                completionHandler: @escaping (URLSession.AuthChallengeDisposition,
                                              URLCredential?) -> Void
            ) {
                authenticationChallengeProcessor.process(
                    challenge: challenge,
                    completionHandler: completionHandler
                )
            }
        }
        """
        let options = FormatOptions(wrapParameters: .preserve, maxWidth: 80)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options,
                       exclude: ["indent", "wrapArguments"])
    }

    func testNoCrashWrap3() throws {
        let input = """
        override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
            let context = super.invalidationContext(forBoundsChange: newBounds) as! UICollectionViewFlowLayoutInvalidationContext
            context.invalidateFlowLayoutDelegateMetrics = newBounds.size != collectionView?.bounds.size
            return context
        }
        """
        let options = FormatOptions(wrapArguments: .afterFirst, maxWidth: 100)
        let rules = [FormatRules.wrap, FormatRules.wrapArguments]
        XCTAssertNoThrow(try format(input, rules: rules, options: options))
    }

    func testWrapColorLiteral() throws {
        let input = """
        button.setTitleColor(#colorLiteral(red: 0.2392156863, green: 0.6470588235, blue: 0.3647058824, alpha: 1), for: .normal)
        """
        let options = FormatOptions(maxWidth: 80, assetLiteralWidth: .visualWidth)
        testFormatting(for: input, rule: FormatRules.wrap, options: options)
    }

    func testWrapImageLiteral() {
        let input = "if let image = #imageLiteral(resourceName: \"abc.png\") {}"
        let options = FormatOptions(maxWidth: 40, assetLiteralWidth: .visualWidth)
        testFormatting(for: input, rule: FormatRules.wrap, options: options)
    }

    func testNoWrapBeforeFirstArgumentInSingleLineStringInterpolation() {
        let input = """
        "a very long string literal with \\(interpolation) inside"
        """
        let options = FormatOptions(maxWidth: 40)
        testFormatting(for: input, rule: FormatRules.wrap, options: options)
    }

    func testWrapBeforeFirstArgumentInMultineStringInterpolation() {
        let input = """
        \"""
        a very long string literal with \\(interpolation) inside
        \"""
        """
        let output = """
        \"""
        a very long string literal with \\(
            interpolation
        ) inside
        \"""
        """
        let options = FormatOptions(maxWidth: 40)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    // ternary expressions

    func testWrapSimpleTernaryOperator() {
        let input = """
        let foo = fooCondition ? longValueThatContainsFoo : longValueThatContainsBar
        """

        let output = """
        let foo = fooCondition
            ? longValueThatContainsFoo
            : longValueThatContainsBar
        """

        let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 60)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testRewrapsSimpleTernaryOperator() {
        let input = """
        let foo = fooCondition ? longValueThatContainsFoo :
            longValueThatContainsBar
        """

        let output = """
        let foo = fooCondition
            ? longValueThatContainsFoo
            : longValueThatContainsBar
        """

        let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 60)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testWrapComplexTernaryOperator() {
        let input = """
        let foo = fooCondition ? Foo(property: value) : barContainer.getBar(using: barProvider)
        """

        let output = """
        let foo = fooCondition
            ? Foo(property: value)
            : barContainer.getBar(using: barProvider)
        """

        let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 60)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testRewrapsComplexTernaryOperator() {
        let input = """
        let foo = fooCondition ? Foo(property: value) :
            barContainer.getBar(using: barProvider)
        """

        let output = """
        let foo = fooCondition
            ? Foo(property: value)
            : barContainer.getBar(using: barProvider)
        """

        let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 60)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testWrappedTernaryOperatorIndentsChainedCalls() {
        let input = """
        let ternary = condition
            ? values
                .map { $0.bar }
                .filter { $0.hasFoo }
                .last
            : other.values
                .compactMap { $0 }
                .first?
                .with(property: updatedValue)
        """

        let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 60)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testWrapsSimpleNestedTernaryOperator() {
        let input = """
        let foo = fooCondition ? (barCondition ? a : b) : (baazCondition ? c : d)
        """

        let output = """
        let foo = fooCondition
            ? (barCondition ? a : b)
            : (baazCondition ? c : d)
        """

        let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 60)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testWrapsDoubleNestedTernaryOperation() {
        let input = """
        let foo = fooCondition ? barCondition ? longTrueBarResult : longFalseBarResult : baazCondition ? longTrueBaazResult : longFalseBaazResult
        """

        let output = """
        let foo = fooCondition
            ? barCondition
                ? longTrueBarResult
                : longFalseBarResult
            : baazCondition
                ? longTrueBaazResult
                : longFalseBaazResult
        """

        let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 60)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testWrapsTripleNestedTernaryOperation() {
        let input = """
        let foo = fooCondition ? barCondition ? quuxCondition ? longTrueQuuxResult : longFalseQuuxResult : barCondition2 ? longTrueBarResult : longFalseBarResult : baazCondition ? longTrueBaazResult : longFalseBaazResult
        """

        let output = """
        let foo = fooCondition
            ? barCondition
                ? quuxCondition
                    ? longTrueQuuxResult
                    : longFalseQuuxResult
                : barCondition2
                    ? longTrueBarResult
                    : longFalseBarResult
            : baazCondition
                ? longTrueBaazResult
                : longFalseBaazResult
        """

        let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 60)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testNoWrapTernaryWrappedWithinChildExpression() {
        let input = """
        func foo() {
            return _skipString(string) ? .token(
                string, Location(source: input, range: startIndex ..< index)
            ) : nil
        }
        """

        let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 0)
        testFormatting(for: input, rule: FormatRules.wrap, options: options)
    }

    func testNoWrapTernaryWrappedWithinChildExpression2() {
        let input = """
        let types: [PolygonType] = plane.isEqual(to: plane) ? [] : vertices.map {
            let t = plane.normal.dot($0.position) - plane.w
            let type: PolygonType = (t < -epsilon) ? .back : (t > epsilon) ? .front : .coplanar
            polygonType = PolygonType(rawValue: polygonType.rawValue | type.rawValue)!
            return type
        }
        """

        let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 0)
        testFormatting(for: input, rule: FormatRules.wrap, options: options)
    }

    func testNoWrapTernaryInsideStringLiteral() {
        let input = """
        "\\(true ? "Some string literal" : "Some other string")"
        """
        let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 50)
        testFormatting(for: input, rule: FormatRules.wrap, options: options)
    }

    func testWrapTernaryInsideMultilineStringLiteral() {
        let input = """
        let foo = \"""
        \\(true ? "Some string literal" : "Some other string")"
        \"""
        """
        let output = """
        let foo = \"""
        \\(true
            ? "Some string literal"
            : "Some other string")"
        \"""
        """
        let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 50)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testErrorNotReportedOnBlankLineAfterWrap() throws {
        let input = """
        [
            abagdiasiudbaisndoanosdasdasdasdasdnaosnooanso(),

            bar(),
        ]
        """
        let options = FormatOptions(truncateBlankLines: false, maxWidth: 40)
        let changes = try lint(input, rules: [FormatRules.wrap, FormatRules.indent], options: options)
        XCTAssertEqual(changes, [.init(line: 2, rule: FormatRules.wrap, filePath: nil)])
    }

    // MARK: - wrapArguments

    func testIndentFirstElementWhenApplyingWrap() {
        let input = """
        let foo = Set([
        Thing(),
        Thing(),
        ])
        """
        let output = """
        let foo = Set([
            Thing(),
            Thing(),
        ])
        """
        testFormatting(for: input, output, rule: FormatRules.wrapArguments)
    }

    func testWrapArgumentsDoesntIndentTrailingComment() {
        let input = """
        foo( // foo
        bar: Int
        )
        """
        let output = """
        foo( // foo
            bar: Int
        )
        """
        testFormatting(for: input, output, rule: FormatRules.wrapArguments)
    }

    func testWrapArgumentsDoesntIndentClosingBracket() {
        let input = """
        [
            "foo": [
            ],
        ]
        """
        testFormatting(for: input, rule: FormatRules.wrapArguments)
    }

    // MARK: wrapArguments

    func testWrapParametersDoesNotAffectFunctionDeclaration() {
        let input = "foo(\n    bar _: Int,\n    baz _: String\n)"
        let options = FormatOptions(wrapArguments: .preserve, wrapParameters: .afterFirst)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapParametersClosureAfterParameterListDoesNotWrapClosureArguments() {
        let input = """
        func foo() {}
        bar = (baz: 5, quux: 7,
               quuz: 10)
        """
        let options = FormatOptions(wrapArguments: .preserve, wrapParameters: .beforeFirst)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapParametersNotSetWrapArgumentsAfterFirstDefaultsToAfterFirst() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let output = "func foo(bar _: Int,\n         baz _: String) {}"
        let options = FormatOptions(wrapArguments: .afterFirst)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapParametersNotSetWrapArgumentsBeforeFirstDefaultsToBeforeFirst() {
        let input = "func foo(bar _: Int,\n    baz _: String) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapArguments: .beforeFirst)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapParametersNotSetWrapArgumentsPreserveDefaultsToPreserve() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapArguments: .preserve)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testIndentMultilineStringWhenWrappingArguments() {
        let input = """
        foobar(foo: \"\""
                   baz
               \"\"",
               bar: \"\""
                   baz
               \"\"")
        """
        let options = FormatOptions(wrapArguments: .afterFirst)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testHandleXcodeTokenApplyingWrap() {
        let input = """
        test(image: \u{003c}#T##UIImage#>, name: "Name")
        """

        let output = """
        test(
            image: \u{003c}#T##UIImage#>,
            name: "Name"
        )
        """
        let options = FormatOptions(wrapArguments: .beforeFirst, maxWidth: 20)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    // MARK: wrapParameters

    // MARK: preserve

    func testAfterFirstPreserved() {
        let input = "func foo(bar _: Int,\n         baz _: String) {}"
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testAfterFirstPreservedIndentFixed() {
        let input = "func foo(bar _: Int,\n baz _: String) {}"
        let output = "func foo(bar _: Int,\n         baz _: String) {}"
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testAfterFirstPreservedNewlineRemoved() {
        let input = "func foo(bar _: Int,\n         baz _: String\n) {}"
        let output = "func foo(bar _: Int,\n         baz _: String) {}"
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testBeforeFirstPreserved() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testBeforeFirstPreservedIndentFixed() {
        let input = "func foo(\n    bar _: Int,\n baz _: String\n) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testBeforeFirstPreservedNewlineAdded() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapParametersAfterMultilineComment() {
        let input = """
        /**
         Some function comment.
         */
        func barFunc(
            _ firstParam: FirstParamType,
            secondParam: SecondParamType
        )
        """
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    // MARK: afterFirst

    func testBeforeFirstConvertedToAfterFirst() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let output = "func foo(bar _: Int,\n         baz _: String) {}"
        let options = FormatOptions(wrapParameters: .afterFirst)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testNoWrapInnerArguments() {
        let input = "func foo(\n    bar _: Int,\n    baz _: foo(bar, baz)\n) {}"
        let output = "func foo(bar _: Int,\n         baz _: foo(bar, baz)) {}"
        let options = FormatOptions(wrapParameters: .afterFirst)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    // MARK: afterFirst, maxWidth

    func testWrapAfterFirstIfMaxLengthExceeded() {
        let input = """
        func foo(bar: Int, baz: String) -> Bool {}
        """
        let output = """
        func foo(bar: Int,
                 baz: String) -> Bool {}
        """
        let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 20)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["unusedArguments", "wrap"])
    }

    func testWrapAfterFirstIfMaxLengthExceeded2() {
        let input = """
        func foo(bar: Int, baz: String, quux: Bool) -> Bool {}
        """
        let output = """
        func foo(bar: Int,
                 baz: String,
                 quux: Bool) -> Bool {}
        """
        let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 20)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["unusedArguments", "wrap"])
    }

    func testWrapAfterFirstIfMaxLengthExceeded3() {
        let input = """
        func foo(bar: Int, baz: String, aVeryLongLastArgumentThatExceedsTheMaxWidthByItself: Bool) -> Bool {}
        """
        let output = """
        func foo(bar: Int, baz: String,
                 aVeryLongLastArgumentThatExceedsTheMaxWidthByItself: Bool) -> Bool {}
        """
        let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 32)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["unusedArguments", "wrap"])
    }

    func testWrapAfterFirstIfMaxLengthExceeded3WithWrap() {
        let input = """
        func foo(bar: Int, baz: String, aVeryLongLastArgumentThatExceedsTheMaxWidthByItself: Bool) -> Bool {}
        """
        let output = """
        func foo(bar: Int, baz: String,
                 aVeryLongLastArgumentThatExceedsTheMaxWidthByItself: Bool)
                 -> Bool {}
        """
        let output2 = """
        func foo(bar: Int, baz: String,
                 aVeryLongLastArgumentThatExceedsTheMaxWidthByItself: Bool)
            -> Bool {}
        """
        let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 32)
        testFormatting(for: input, [output, output2],
                       rules: [FormatRules.wrapArguments, FormatRules.wrap],
                       options: options, exclude: ["unusedArguments"])
    }

    func testWrapAfterFirstIfMaxLengthExceeded4WithWrap() {
        let input = """
        func foo(bar: String, baz: String, quux: Bool) -> Bool {}
        """
        let output = """
        func foo(bar: String,
                 baz: String,
                 quux: Bool) -> Bool {}
        """
        let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 31)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments, FormatRules.wrap],
                       options: options, exclude: ["unusedArguments"])
    }

    func testWrapAfterFirstIfMaxLengthExceededInClassScopeWithWrap() {
        let input = """
        class TestClass {
            func foo(bar: String, baz: String, quux: Bool) -> Bool {}
        }
        """
        let output = """
        class TestClass {
            func foo(bar: String,
                     baz: String,
                     quux: Bool)
                     -> Bool {}
        }
        """
        let output2 = """
        class TestClass {
            func foo(bar: String,
                     baz: String,
                     quux: Bool)
                -> Bool {}
        }
        """
        let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 31)
        testFormatting(for: input, [output, output2],
                       rules: [FormatRules.wrapArguments, FormatRules.wrap],
                       options: options, exclude: ["unusedArguments"])
    }

    func testWrapParametersListInClosureType() {
        let input = """
        var mathFunction: (Int,
                           Int, String) -> Int = { _, _, _ in
            0
        }
        """
        let output = """
        var mathFunction: (Int,
                           Int,
                           String) -> Int = { _, _, _ in
            0
        }
        """
        let output2 = """
        var mathFunction: (Int,
                           Int,
                           String)
            -> Int = { _, _, _ in
                0
            }
        """
        let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 30)
        testFormatting(for: input, [output, output2],
                       rules: [FormatRules.wrapArguments],
                       options: options)
    }

    func testWrapParametersAfterFirstIfMaxLengthExceededInReturnType() {
        let input = """
        func foo(bar: Int, baz: String, quux: Bool) -> LongReturnType {}
        """
        let output2 = """
        func foo(bar: Int, baz: String,
                 quux: Bool) -> LongReturnType {}
        """
        let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 50)
        testFormatting(for: input, [input, output2], rules: [FormatRules.wrapArguments],
                       options: options, exclude: ["unusedArguments"])
    }

    func testWrapParametersAfterFirstWithSeparatedArgumentLabels() {
        let input = """
        func foo(with
            bar: Int, and
            baz: String, and
            quux: Bool
        ) -> LongReturnType {}
        """
        let output = """
        func foo(with bar: Int,
                 and baz: String,
                 and quux: Bool) -> LongReturnType {}
        """
        let options = FormatOptions(wrapParameters: .afterFirst)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments,
                       options: options, exclude: ["unusedArguments"])
    }

    // MARK: beforeFirst

    func testWrapAfterFirstConvertedToWrapBefore() {
        let input = "func foo(bar _: Int,\n    baz _: String) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testLinebreakInsertedAtEndOfWrappedFunction() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testAfterFirstConvertedToBeforeFirst() {
        let input = "func foo(bar _: Int,\n         baz _: String) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapParametersListBeforeFirstInClosureType() {
        let input = """
        var mathFunction: (Int,
                           Int, String) -> Int = { _, _, _ in
            0
        }
        """
        let output = """
        var mathFunction: (
            Int,
            Int,
            String
        ) -> Int = { _, _, _ in
            0
        }
        """
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments],
                       options: options)
    }

    func testWrapParametersListBeforeFirstInThrowingClosureType() {
        let input = """
        var mathFunction: (Int,
                           Int, String) throws -> Int = { _, _, _ in
            0
        }
        """
        let output = """
        var mathFunction: (
            Int,
            Int,
            String
        ) throws -> Int = { _, _, _ in
            0
        }
        """
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments],
                       options: options)
    }

    func testWrapParametersListBeforeFirstInRethrowingClosureType() {
        let input = """
        var mathFunction: (Int,
                           Int, String) rethrows -> Int = { _, _, _ in
            0
        }
        """
        let output = """
        var mathFunction: (
            Int,
            Int,
            String
        ) rethrows -> Int = { _, _, _ in
            0
        }
        """
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments],
                       options: options)
    }

    func testWrapParametersListBeforeFirstInClosureTypeAsFunctionParameter() {
        let input = """
        func foo(bar: (Int,
                       Bool, String) -> Int) -> Int {}
        """
        let output = """
        func foo(bar: (
            Int,
            Bool,
            String
        ) -> Int) -> Int {}
        """
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments],
                       options: options,
                       exclude: ["unusedArguments"])
    }

    func testWrapParametersListBeforeFirstInClosureTypeAsFunctionParameterWithOtherParams() {
        let input = """
        func foo(bar: Int, baz: (Int,
                                 Bool, String) -> Int) -> Int {}
        """
        let output = """
        func foo(bar: Int, baz: (
            Int,
            Bool,
            String
        ) -> Int) -> Int {}
        """
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments],
                       options: options,
                       exclude: ["unusedArguments"])
    }

    func testWrapParametersListBeforeFirstInClosureTypeAsFunctionParameterWithOtherParamsAfterWrappedClosure() {
        let input = """
        func foo(bar: Int, baz: (Int,
                                 Bool, String) -> Int, quux: String) -> Int {}
        """
        let output = """
        func foo(bar: Int, baz: (
            Int,
            Bool,
            String
        ) -> Int, quux: String) -> Int {}
        """
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments],
                       options: options,
                       exclude: ["unusedArguments"])
    }

    func testWrapParametersListBeforeFirstInEscapingClosureTypeAsFunctionParameter() {
        let input = """
        func foo(bar: @escaping (Int,
                                 Bool, String) -> Int) -> Int {}
        """
        let output = """
        func foo(bar: @escaping (
            Int,
            Bool,
            String
        ) -> Int) -> Int {}
        """
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments],
                       options: options,
                       exclude: ["unusedArguments"])
    }

    func testWrapParametersListBeforeFirstInNoEscapeClosureTypeAsFunctionParameter() {
        let input = """
        func foo(bar: @noescape (Int,
                                 Bool, String) -> Int) -> Int {}
        """
        let output = """
        func foo(bar: @noescape (
            Int,
            Bool,
            String
        ) -> Int) -> Int {}
        """
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments],
                       options: options,
                       exclude: ["unusedArguments"])
    }

    func testWrapParametersListBeforeFirstInEscapingAutoclosureTypeAsFunctionParameter() {
        let input = """
        func foo(bar: @escaping @autoclosure (Int,
                                              Bool, String) -> Int) -> Int {}
        """
        let output = """
        func foo(bar: @escaping @autoclosure (
            Int,
            Bool,
            String
        ) -> Int) -> Int {}
        """
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments],
                       options: options,
                       exclude: ["unusedArguments"])
    }

    // MARK: beforeFirst, maxWidth

    func testWrapBeforeFirstIfMaxLengthExceeded() {
        let input = """
        func foo(bar: Int, baz: String) -> Bool {}
        """
        let output = """
        func foo(
            bar: Int,
            baz: String
        ) -> Bool {}
        """
        let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 20)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["unusedArguments"])
    }

    func testNoWrapBeforeFirstIfMaxLengthNotExceeded() {
        let input = """
        func foo(bar: Int, baz: String) -> Bool {}
        """
        let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 42)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["unusedArguments"])
    }

    func testNoWrapGenericsIfClosingBracketWithinMaxWidth() {
        let input = """
        func foo<T: Bar>(bar: Int, baz: String) -> Bool {}
        """
        let output = """
        func foo<T: Bar>(
            bar: Int,
            baz: String
        ) -> Bool {}
        """
        let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 20)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["unusedArguments"])
    }

    func testWrapAlreadyWrappedArgumentsIfMaxLengthExceeded() {
        let input = """
        func foo(
            bar: Int, baz: String, quux: Bool
        ) -> Bool {}
        """
        let output = """
        func foo(
            bar: Int, baz: String,
            quux: Bool
        ) -> Bool {}
        """
        let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 26)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["unusedArguments"])
    }

    func testWrapParametersBeforeFirstIfMaxLengthExceededInReturnType() {
        let input = """
        func foo(bar: Int, baz: String, quux: Bool) -> LongReturnType {}
        """
        let output2 = """
        func foo(
            bar: Int,
            baz: String,
            quux: Bool
        ) -> LongReturnType {}
        """
        let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 50)
        testFormatting(for: input, [input, output2], rules: [FormatRules.wrapArguments],
                       options: options, exclude: ["unusedArguments"])
    }

    func testWrapParametersBeforeFirstWithSeparatedArgumentLabels() {
        let input = """
        func foo(with
            bar: Int, and
            baz: String
        ) -> LongReturnType {}
        """
        let output = """
        func foo(
            with bar: Int,
            and baz: String
        ) -> LongReturnType {}
        """
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments,
                       options: options, exclude: ["unusedArguments"])
    }

    func testWrapParametersListBeforeFirstInClosureTypeWithMaxWidth() {
        let input = """
        var mathFunction: (Int, Int, String) -> Int = { _, _, _ in
            0
        }
        """
        let output = """
        var mathFunction: (
            Int,
            Int,
            String
        ) -> Int = { _, _, _ in
            0
        }
        """
        let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 30)
        testFormatting(for: input, [output], rules: [FormatRules.wrapArguments],
                       options: options)
    }

    func testNoWrapBeforeFirstMaxWidthNotExceededWithLineBreakSinceLastEndOfArgumentScope() {
        let input = """
        class Foo {
            func foo() {
                bar()
            }

            func bar(foo: String, bar: Int) {
                quux()
            }
        }
        """
        let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 37)
        testFormatting(for: input, rule: FormatRules.wrapArguments,
                       options: options, exclude: ["unusedArguments"])
    }

    func testNoWrapSubscriptWithSingleElement() {
        let input = "guard let foo = bar[0] {}"
        let options = FormatOptions(wrapCollections: .beforeFirst, maxWidth: 20)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["wrap"])
    }

    func testNoWrapArrayWithSingleElement() {
        let input = "let foo = [0]"
        let options = FormatOptions(wrapCollections: .beforeFirst, maxWidth: 11)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["wrap"])
    }

    func testNoWrapDictionaryWithSingleElement() {
        let input = "let foo = [bar: baz]"
        let options = FormatOptions(wrapCollections: .beforeFirst, maxWidth: 15)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["wrap"])
    }

    func testNoWrapImageLiteral() {
        let input = "if let image = #imageLiteral(resourceName: \"abc.png\") {}"
        let options = FormatOptions(wrapCollections: .beforeFirst, maxWidth: 30)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["wrap"])
    }

    func testNoWrapColorLiteral() {
        let input = """
        if let color = #colorLiteral(red: 0.2392156863, green: 0.6470588235, blue: 0.3647058824, alpha: 1) {}
        """
        let options = FormatOptions(wrapCollections: .beforeFirst, maxWidth: 30)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["wrap"])
    }

    func testWrapArgumentsNoIndentBlankLines() {
        let input = """
        let foo = [

            bar,

        ]
        """
        let options = FormatOptions(wrapCollections: .beforeFirst)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["wrap", "blankLinesAtStartOfScope", "blankLinesAtEndOfScope"])
    }

    // MARK: closingParenOnSameLine = true

    func testParenOnSameLineWhenWrapAfterFirstConvertedToWrapBefore() {
        let input = "func foo(bar _: Int,\n    baz _: String) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String) {}"
        let options = FormatOptions(wrapParameters: .beforeFirst, closingParenOnSameLine: true)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testParenOnSameLineWhenWrapBeforeFirstUnchanged() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String) {}"
        let options = FormatOptions(wrapParameters: .beforeFirst, closingParenOnSameLine: true)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testParenOnSameLineWhenWrapBeforeFirstPreserved() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String) {}"
        let options = FormatOptions(wrapParameters: .preserve, closingParenOnSameLine: true)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    // MARK: indent with tabs

    func testTabIndentWrappedFunctionWithSmartTabs() {
        let input = """
        func foo(bar: Int,
                 baz: Int) {}
        """
        let options = FormatOptions(indent: "\t", wrapParameters: .afterFirst, tabWidth: 2)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["unusedArguments"])
    }

    func testTabIndentWrappedFunctionWithoutSmartTabs() {
        let input = """
        func foo(bar: Int,
                 baz: Int) {}
        """
        let output = """
        func foo(bar: Int,
        \t\t\t\t baz: Int) {}
        """
        let options = FormatOptions(indent: "\t", wrapParameters: .afterFirst,
                                    tabWidth: 2, smartTabs: false)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["unusedArguments"])
    }

    // MARK: - wrapArguments --wrapArguments

    func testWrapArgumentsDoesNotAffectFunctionDeclaration() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapArguments: .afterFirst, wrapParameters: .preserve)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapArgumentsDoesNotAffectInit() {
        let input = "init(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapArguments: .afterFirst, wrapParameters: .preserve)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapArgumentsDoesNotAffectSubscript() {
        let input = "subscript(\n    bar _: Int,\n    baz _: String\n) -> Int {}"
        let options = FormatOptions(wrapArguments: .afterFirst, wrapParameters: .preserve)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    // MARK: afterFirst

    func testWrapArgumentsConvertBeforeFirstToAfterFirst() {
        let input = """
        foo(
            bar _: Int,
            baz _: String
        )
        """
        let output = """
        foo(bar _: Int,
            baz _: String)
        """
        let options = FormatOptions(wrapArguments: .afterFirst)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testCorrectWrapIndentForNestedArguments() {
        let input = "foo(\nbar: (\nx: 0,\ny: 0\n),\nbaz: (\nx: 0,\ny: 0\n)\n)"
        let output = "foo(bar: (x: 0,\n          y: 0),\n    baz: (x: 0,\n          y: 0))"
        let options = FormatOptions(wrapArguments: .afterFirst)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testNoRemoveLinebreakAfterCommentInArguments() {
        let input = "a(b // comment\n)"
        let options = FormatOptions(wrapArguments: .afterFirst)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testNoRemoveLinebreakAfterCommentInArguments2() {
        let input = """
        foo(bar: bar
        //  ,
        //  baz: baz
            ) {}
        """
        let options = FormatOptions(wrapArguments: .afterFirst)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options, exclude: ["indent"])
    }

    func testConsecutiveCodeCommentsNotIndented() {
        let input = """
        foo(bar: bar,
        //    bar,
        //    baz,
            quux)
        """
        let options = FormatOptions(wrapArguments: .afterFirst)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    // MARK: afterFirst maxWidth

    func testWrapArgumentsAfterFirst() {
        let input = """
        foo(bar: Int, baz: String, quux: Bool)
        """
        let output = """
        foo(bar: Int,
            baz: String,
            quux: Bool)
        """
        let options = FormatOptions(wrapArguments: .afterFirst, maxWidth: 20)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["unusedArguments", "wrap"])
    }

    // MARK: beforeFirst

    func testClosureInsideParensNotWrappedOntoNextLine() {
        let input = "foo({\n    bar()\n})"
        let options = FormatOptions(wrapArguments: .beforeFirst)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["trailingClosures"])
    }

    func testNoMangleCommentedLinesWhenWrappingArguments() {
        let input = """
        foo(bar: bar
        //    ,
        //    baz: baz
            ) {}
        """
        let output = """
        foo(
            bar: bar
        //    ,
        //    baz: baz
        ) {}
        """
        let options = FormatOptions(wrapArguments: .beforeFirst)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testNoMangleCommentedLinesWhenWrappingArgumentsWithNoCommas() {
        let input = """
        foo(bar: bar
        //    baz: baz
            ) {}
        """
        let output = """
        foo(
            bar: bar
        //    baz: baz
        ) {}
        """
        let options = FormatOptions(wrapArguments: .beforeFirst)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    // MARK: preserve

    func testWrapArgumentsDoesNotAffectLessThanOperator() {
        let input = """
        func foo() {
            guard foo < bar.count else { return nil }
        }
        """
        let options = FormatOptions(wrapArguments: .preserve)
        testFormatting(for: input, rule: FormatRules.wrapArguments,
                       options: options, exclude: ["wrapConditionalBodies"])
    }

    // MARK: - --wrapArguments, --wrapParameter

    // MARK: beforeFirst

    func testNoMistakeTernaryExpressionForArguments() {
        let input = """
        (foo ?
            bar :
            baz)
        """
        let options = FormatOptions(wrapArguments: .beforeFirst, wrapParameters: .beforeFirst)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["redundantParens"])
    }

    // MARK: beforeFirst, maxWidth : string interpolation

    func testNoWrapBeforeFirstArgumentInStringInterpolation() {
        let input = """
        "a very long string literal with \\(interpolation) inside"
        """
        let options = FormatOptions(wrapArguments: .beforeFirst,
                                    wrapParameters: .beforeFirst,
                                    maxWidth: 40)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testNoWrapBeforeFirstArgumentInStringInterpolation2() {
        let input = """
        "a very long string literal with \\(interpolation) inside"
        """
        let options = FormatOptions(wrapArguments: .beforeFirst,
                                    wrapParameters: .beforeFirst,
                                    maxWidth: 50)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testNoWrapBeforeFirstArgumentInStringInterpolation3() {
        let input = """
        "a very long string literal with \\(interpolated, variables) inside"
        """
        let options = FormatOptions(wrapArguments: .beforeFirst,
                                    wrapParameters: .beforeFirst,
                                    maxWidth: 40)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testNoWrapBeforeNestedFirstArgumentInStringInterpolation() {
        let input = """
        "a very long string literal with \\(foo(interpolated)) inside"
        """
        let options = FormatOptions(wrapArguments: .beforeFirst,
                                    wrapParameters: .beforeFirst,
                                    maxWidth: 45)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testNoWrapBeforeNestedFirstArgumentInStringInterpolation2() {
        let input = """
        "a very long string literal with \\(foo(interpolated, variables)) inside"
        """
        let options = FormatOptions(wrapArguments: .beforeFirst,
                                    wrapParameters: .beforeFirst,
                                    maxWidth: 45)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    // MARK: afterFirst maxWidth : string interpolation

    func testNoWrapAfterFirstArgumentInStringInterpolation() {
        let input = """
        "a very long string literal with \\(interpolated) inside"
        """
        let options = FormatOptions(wrapArguments: .afterFirst,
                                    wrapParameters: .afterFirst,
                                    maxWidth: 46)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testNoWrapAfterFirstArgumentInStringInterpolation2() {
        let input = """
        "a very long string literal with \\(interpolated, variables) inside"
        """
        let options = FormatOptions(wrapArguments: .afterFirst,
                                    wrapParameters: .afterFirst,
                                    maxWidth: 50)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testNoWrapAfterNestedFirstArgumentInStringInterpolation() {
        let input = """
        "a very long string literal with \\(foo(interpolated, variables)) inside"
        """
        let options = FormatOptions(wrapArguments: .afterFirst,
                                    wrapParameters: .afterFirst,
                                    maxWidth: 55)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    // MARK: - wrapArguments --wrapCollections

    // MARK: beforeFirst

    func testNoDoubleSpaceAddedToWrappedArray() {
        let input = "[ foo,\n    bar ]"
        let output = "[\n    foo,\n    bar\n]"
        let options = FormatOptions(trailingCommas: false, wrapCollections: .beforeFirst)
        testFormatting(for: input, [output], rules: [FormatRules.wrapArguments, FormatRules.spaceInsideBrackets],
                       options: options)
    }

    func testTrailingCommasAddedToWrappedArray() {
        let input = "[foo,\n    bar]"
        let output = "[\n    foo,\n    bar,\n]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .beforeFirst)
        testFormatting(for: input, [output], rules: [FormatRules.wrapArguments, FormatRules.trailingCommas],
                       options: options)
    }

    func testTrailingCommasAddedToWrappedNestedDictionary() {
        let input = "[foo: [bar: baz,\n    bar2: baz2]]"
        let output = "[foo: [\n    bar: baz,\n    bar2: baz2,\n]]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .beforeFirst)
        testFormatting(for: input, [output], rules: [FormatRules.wrapArguments, FormatRules.trailingCommas],
                       options: options)
    }

    func testTrailingCommasAddedToSingleLineNestedDictionary() {
        let input = "[\n    foo: [bar: baz, bar2: baz2]]"
        let output = "[\n    foo: [bar: baz, bar2: baz2],\n]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .beforeFirst)
        testFormatting(for: input, [output], rules: [FormatRules.wrapArguments, FormatRules.trailingCommas],
                       options: options)
    }

    func testTrailingCommasAddedToWrappedNestedDictionaries() {
        let input = "[foo: [bar: baz,\n    bar2: baz2],\n    foo2: [bar: baz,\n    bar2: baz2]]"
        let output = "[\n    foo: [\n        bar: baz,\n        bar2: baz2,\n    ],\n    foo2: [\n        bar: baz,\n        bar2: baz2,\n    ],\n]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .beforeFirst)
        testFormatting(for: input, [output], rules: [FormatRules.wrapArguments, FormatRules.trailingCommas],
                       options: options)
    }

    func testSpaceAroundEnumValuesInArray() {
        let input = "[\n    .foo,\n    .bar, .baz,\n]"
        let options = FormatOptions(wrapCollections: .beforeFirst)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    // MARK: beforeFirst maxWidth

    func testWrapCollectionOnOneLineBeforeFirstWidthExceededInChainedFunctionCallAfterCollection() {
        let input = """
        let foo = ["bar", "baz"].quux(quuz)
        """
        let output2 = """
        let foo = ["bar", "baz"]
            .quux(quuz)
        """
        let options = FormatOptions(wrapCollections: .beforeFirst, maxWidth: 26)
        testFormatting(for: input, [input, output2],
                       rules: [FormatRules.wrapArguments], options: options)
    }

    // MARK: afterFirst

    func testTrailingCommaRemovedInWrappedArray() {
        let input = "[\n    .foo,\n    .bar,\n    .baz,\n]"
        let output = "[.foo,\n .bar,\n .baz]"
        let options = FormatOptions(wrapCollections: .afterFirst)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testNoRemoveLinebreakAfterCommentInElements() {
        let input = "[a, // comment\n]"
        let options = FormatOptions(wrapCollections: .afterFirst)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapCollectionsConsecutiveCodeCommentsNotIndented() {
        let input = """
        let a = [foo,
        //         bar,
        //         baz,
                 quux]
        """
        let options = FormatOptions(wrapCollections: .afterFirst)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapCollectionsConsecutiveCodeCommentsNotIndentedInWrapBeforeFirst() {
        let input = """
        let a = [
            foo,
        //    bar,
        //    baz,
            quux,
        ]
        """
        let options = FormatOptions(wrapCollections: .beforeFirst)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    // MARK: preserve

    func testNoBeforeFirstPreservedAndTrailingCommaIgnoredInMultilineNestedDictionary() {
        let input = "[foo: [bar: baz,\n    bar2: baz2]]"
        let output = "[foo: [bar: baz,\n       bar2: baz2]]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .preserve)
        testFormatting(for: input, [output], rules: [FormatRules.wrapArguments, FormatRules.trailingCommas],
                       options: options)
    }

    func testBeforeFirstPreservedAndTrailingCommaAddedInSingleLineNestedDictionary() {
        let input = "[\n    foo: [bar: baz, bar2: baz2]]"
        let output = "[\n    foo: [bar: baz, bar2: baz2],\n]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .preserve)
        testFormatting(for: input, [output], rules: [FormatRules.wrapArguments, FormatRules.trailingCommas],
                       options: options)
    }

    func testBeforeFirstPreservedAndTrailingCommaAddedInSingleLineNestedDictionaryWithOneNestedItem() {
        let input = "[\n    foo: [bar: baz]]"
        let output = "[\n    foo: [bar: baz],\n]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .preserve)
        testFormatting(for: input, [output], rules: [FormatRules.wrapArguments, FormatRules.trailingCommas],
                       options: options)
    }

    // MARK: - wrapArguments --wrapCollections & --wrapArguments

    // MARK: beforeFirst maxWidth

    func testWrapArgumentsBeforeFirstWhenArgumentsExceedMaxWidthAndArgumentIsCollection() {
        let input = """
        foo(bar: ["baz", "quux"], quuz: corge)
        """
        let output = """
        foo(
            bar: ["baz", "quux"],
            quuz: corge
        )
        """
        let options = FormatOptions(wrapArguments: .beforeFirst,
                                    wrapCollections: .beforeFirst,
                                    maxWidth: 26)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments], options: options)
    }

    // MARK: afterFirst maxWidth

    func testWrapArgumentsAfterFirstWhenArgumentsExceedMaxWidthAndArgumentIsCollection() {
        let input = """
        foo(bar: ["baz", "quux"], quuz: corge)
        """
        let output = """
        foo(bar: ["baz", "quux"],
            quuz: corge)
        """
        let options = FormatOptions(wrapArguments: .afterFirst,
                                    wrapCollections: .beforeFirst,
                                    maxWidth: 26)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments], options: options)
    }

    // MARK: - wrapArguments Multiple Wraps On Same Line

    func testWrapAfterFirstWhenChainedFunctionAndThenArgumentsExceedMaxWidth() {
        let input = """
        foo.bar(baz: [qux, quux]).quuz([corge: grault], garply: waldo)
        """
        let output = """
        foo.bar(baz: [qux, quux])
            .quuz([corge: grault],
                  garply: waldo)
        """
        let options = FormatOptions(wrapArguments: .afterFirst,
                                    wrapCollections: .afterFirst,
                                    maxWidth: 28)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments, FormatRules.wrap], options: options)
    }

    func testWrapAfterFirstWrapCollectionsBeforeFirstWhenChainedFunctionAndThenArgumentsExceedMaxWidth() {
        let input = """
        foo.bar(baz: [qux, quux]).quuz([corge: grault], garply: waldo)
        """
        let output = """
        foo.bar(baz: [qux, quux])
            .quuz([corge: grault],
                  garply: waldo)
        """
        let options = FormatOptions(wrapArguments: .afterFirst,
                                    wrapCollections: .beforeFirst,
                                    maxWidth: 28)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments, FormatRules.wrap], options: options)
    }

    func testNoMangleNestedFunctionCalls() {
        let input = """
        points.append(.curve(
            quadraticBezier(p0.position.x, Double(p1.x), Double(p2.x), t),
            quadraticBezier(p0.position.y, Double(p1.y), Double(p2.y), t)
        ))
        """
        let output = """
        points.append(.curve(
            quadraticBezier(
                p0.position.x,
                Double(p1.x),
                Double(p2.x),
                t
            ),
            quadraticBezier(
                p0.position.y,
                Double(p1.y),
                Double(p2.y),
                t
            )
        ))
        """
        let options = FormatOptions(wrapArguments: .beforeFirst, maxWidth: 40)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments, FormatRules.wrap], options: options)
    }

    func testWrapArguments_typealias_beforeFirst() {
        let input = """
        typealias Dependencies = FooProviding & BarProviding & BaazProviding & QuuxProviding
        """

        let output = """
        typealias Dependencies
            = FooProviding
            & BarProviding
            & BaazProviding
            & QuuxProviding
        """

        let options = FormatOptions(wrapTypealiases: .beforeFirst, maxWidth: 40)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapArguments_multipleTypealiases_beforeFirst() {
        let input = """
        enum Namespace {
            typealias DependenciesA = FooProviding & BarProviding
            typealias DependenciesB = BaazProviding & QuuxProviding
        }
        """

        let output = """
        enum Namespace {
            typealias DependenciesA
                = FooProviding
                & BarProviding
            typealias DependenciesB
                = BaazProviding
                & QuuxProviding
        }
        """

        let options = FormatOptions(wrapTypealiases: .beforeFirst, maxWidth: 45)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapArguments_typealias_afterFirst() {
        let input = """
        typealias Dependencies = FooProviding & BarProviding & BaazProviding & QuuxProviding
        """

        let output = """
        typealias Dependencies = FooProviding
            & BarProviding
            & BaazProviding
            & QuuxProviding
        """

        let options = FormatOptions(wrapTypealiases: .afterFirst, maxWidth: 40)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapArguments_multipleTypealiases_afterFirst() {
        let input = """
        enum Namespace {
            typealias DependenciesA = FooProviding & BarProviding
            typealias DependenciesB = BaazProviding & QuuxProviding
        }
        """

        let output = """
        enum Namespace {
            typealias DependenciesA = FooProviding
                & BarProviding
            typealias DependenciesB = BaazProviding
                & QuuxProviding
        }
        """

        let options = FormatOptions(wrapTypealiases: .afterFirst, maxWidth: 45)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapArguments_typealias_shorterThanMaxWidth() {
        let input = """
        typealias Dependencies = FooProviding & BarProviding & BaazProviding
        """

        let options = FormatOptions(wrapTypealiases: .afterFirst, maxWidth: 100)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapArguments_typealias_shorterThanMaxWidth_butWrappedInconsistently() {
        let input = """
        typealias Dependencies = FooProviding & BarProviding &
            BaazProviding & QuuxProviding
        """

        let output = """
        typealias Dependencies = FooProviding
            & BarProviding
            & BaazProviding
            & QuuxProviding
        """

        let options = FormatOptions(wrapTypealiases: .afterFirst, maxWidth: 200)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapArguments_typealias_shorterThanMaxWidth_butWrappedInconsistently2() {
        let input = """
        enum Namespace {
            typealias Dependencies = FooProviding & BarProviding
                & BaazProviding & QuuxProviding
        }
        """

        let output = """
        enum Namespace {
            typealias Dependencies
                = FooProviding
                & BarProviding
                & BaazProviding
                & QuuxProviding
        }
        """

        let options = FormatOptions(wrapTypealiases: .beforeFirst, maxWidth: 200)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapArguments_typealias_shorterThanMaxWidth_butWrappedInconsistently3() {
        let input = """
        typealias Dependencies
            = FooProviding & BarProviding &
            BaazProviding & QuuxProviding
        """

        let output = """
        typealias Dependencies = FooProviding
            & BarProviding
            & BaazProviding
            & QuuxProviding
        """

        let options = FormatOptions(wrapTypealiases: .afterFirst, maxWidth: 200)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapArguments_typealias_shorterThanMaxWidth_butWrappedInconsistently4() {
        let input = """
        typealias Dependencies
            = FooProviding
            & BarProviding
            & BaazProviding
            & QuuxProviding
        """

        let output = """
        typealias Dependencies = FooProviding
            & BarProviding
            & BaazProviding
            & QuuxProviding
        """

        let options = FormatOptions(wrapTypealiases: .afterFirst, maxWidth: 200)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapArguments_typealias_shorterThanMaxWidth_butWrappedInconsistentlyWithComment() {
        let input = """
        typealias Dependencies = FooProviding & BarProviding // trailing comment 1
            // Inline Comment 1
            & BaazProviding & QuuxProviding // trailing comment 2
        """

        let output = """
        typealias Dependencies
            = FooProviding
            & BarProviding // trailing comment 1
            // Inline Comment 1
            & BaazProviding
            & QuuxProviding // trailing comment 2
        """

        let options = FormatOptions(wrapTypealiases: .beforeFirst, maxWidth: 200)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapArguments_typealias_singleTypePreserved() {
        let input = """
        typealias Dependencies = FooProviding
        """

        let options = FormatOptions(wrapTypealiases: .beforeFirst, maxWidth: 10)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options, exclude: ["wrap"])
    }

    func testWrapArguments_typealias_preservesCommentsBetweenTypes() {
        let input = """
        typealias Dependencies
            // We use `FooProviding` because `FooFeature` depends on `Foo`
            = FooProviding
            // We use `BarProviding` because `BarFeature` depends on `Bar`
            & BarProviding
            // We use `BaazProviding` because `BaazFeature` depends on `Baaz`
            & BaazProviding
        """

        let options = FormatOptions(wrapTypealiases: .beforeFirst, maxWidth: 100)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapArguments_typealias_preservesCommentsAfterTypes() {
        let input = """
        typealias Dependencies
            = FooProviding // We use `FooProviding` because `FooFeature` depends on `Foo`
            & BarProviding // We use `BarProviding` because `BarFeature` depends on `Bar`
            & BaazProviding // We use `BaazProviding` because `BaazFeature` depends on `Baaz`
        """

        let options = FormatOptions(wrapTypealiases: .beforeFirst, maxWidth: 100)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    // MARK: - -return wrap-if-multiline

    func testWrapReturnOnMultilineFunctionDeclaration() {
        let input = """
        func multilineFunction(
            foo _: String,
            bar _: String) -> String {}
        """

        let output = """
        func multilineFunction(
            foo _: String,
            bar _: String)
            -> String {}
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenOnSameLine: true,
            wrapReturnType: .ifMultiline
        )

        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapReturnAndEffectOnMultilineFunctionDeclaration() {
        let input = """
        func multilineFunction(
            foo _: String,
            bar _: String) async throws -> String {}
        """

        let output = """
        func multilineFunction(
            foo _: String,
            bar _: String)
            async throws -> String {}
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenOnSameLine: true,
            wrapReturnType: .ifMultiline,
            wrapEffects: .ifMultiline
        )

        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testDoesntWrapReturnAndEffectOnSingleLineFunctionDeclaration() {
        let input = """
        func singleLineFunction() async throws -> String {}
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenOnSameLine: true,
            wrapReturnType: .ifMultiline,
            wrapEffects: .ifMultiline
        )

        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapEffectOnMultilineFunctionDeclaration() {
        let input = """
        func multilineFunction(
            foo _: String,
            bar _: String) async throws
            -> String {}
        """

        let output = """
        func multilineFunction(
            foo _: String,
            bar _: String)
            async throws -> String {}
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenOnSameLine: true,
            wrapReturnType: .ifMultiline,
            wrapEffects: .ifMultiline
        )

        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testUnwrapEffectOnMultilineFunctionDeclaration() {
        let input = """
        func multilineFunction(
            foo _: String,
            bar _: String)
            async throws -> String {}
        """

        let output = """
        func multilineFunction(
            foo _: String,
            bar _: String) async throws
            -> String {}
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenOnSameLine: true,
            wrapReturnType: .ifMultiline,
            wrapEffects: .never
        )

        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapReturnOnMultilineFunctionDeclarationWithAfterFirst() {
        let input = """
        func multilineFunction(foo _: String,
                               bar _: String) -> String {}
        """

        let output = """
        func multilineFunction(foo _: String,
                               bar _: String)
                               -> String {}
        """

        let options = FormatOptions(
            wrapArguments: .afterFirst,
            closingParenOnSameLine: true,
            wrapReturnType: .ifMultiline
        )

        testFormatting(
            for: input, output, rule: FormatRules.wrapArguments, options: options,
            exclude: ["indent"]
        )
    }

    func testWrapReturnOnMultilineThrowingFunctionDeclarationWithAfterFirst() {
        let input = """
        func multilineFunction(foo _: String,
                               bar _: String) throws -> String {}
        """

        let output = """
        func multilineFunction(foo _: String,
                               bar _: String) throws
                               -> String {}
        """

        let options = FormatOptions(
            wrapArguments: .afterFirst,
            closingParenOnSameLine: true,
            wrapReturnType: .ifMultiline
        )

        testFormatting(
            for: input, output, rule: FormatRules.wrapArguments, options: options,
            exclude: ["indent"]
        )
    }

    func testWrapReturnAndEffectOnMultilineThrowingFunctionDeclarationWithAfterFirst() {
        let input = """
        func multilineFunction(foo _: String,
                               bar _: String) throws -> String {}
        """

        let output = """
        func multilineFunction(foo _: String,
                               bar _: String)
                               throws -> String {}
        """

        let options = FormatOptions(
            wrapArguments: .afterFirst,
            closingParenOnSameLine: true,
            wrapReturnType: .ifMultiline,
            wrapEffects: .ifMultiline
        )

        testFormatting(
            for: input, output, rule: FormatRules.wrapArguments, options: options,
            exclude: ["indent"]
        )
    }

    func testDoesntWrapReturnOnMultilineThrowingFunction() {
        let input = """
        func multilineFunction(foo _: String,
                               bar _: String)
                               throws -> String {}
        """

        let options = FormatOptions(
            wrapArguments: .afterFirst,
            closingParenOnSameLine: true,
            wrapReturnType: .ifMultiline
        )

        testFormatting(
            for: input, rule: FormatRules.wrapArguments, options: options,
            exclude: ["indent"]
        )
    }

    func testDoesntWrapReturnOnSingleLineFunctionDeclaration() {
        let input = """
        func multilineFunction(foo _: String, bar _: String) -> String {}
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenOnSameLine: true,
            wrapReturnType: .ifMultiline
        )

        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testDoesntWrapReturnOnSingleLineFunctionDeclarationAfterMultilineArray() {
        let input = """
        final class Foo {
            private static let array = [
                "one",
            ]

            private func singleLine() -> String {}
        }
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenOnSameLine: true,
            wrapReturnType: .ifMultiline
        )

        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testDoesntWrapReturnOnSingleLineFunctionDeclarationAfterMultilineMethodCall() {
        let input = """
        public final class Foo {
            public var multiLineMethodCall = Foo.multiLineMethodCall(
                bar: bar,
                baz: baz)

            func singleLine() -> String {
                return "method body"
            }
        }
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenOnSameLine: true,
            wrapReturnType: .ifMultiline
        )

        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testPreserveReturnOnMultilineFunctionDeclarationByDefault() {
        let input = """
        func multilineFunction(
            foo _: String,
            bar _: String) -> String
        {}
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenOnSameLine: true
        )

        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    // MARK: wrapMultilineStatementBraces

    func testMultilineIfBraceOnNextLine() {
        let input = """
        if firstConditional,
           array.contains(where: { secondConditional }) {
            print("statement body")
        }
        """
        let output = """
        if firstConditional,
           array.contains(where: { secondConditional })
        {
            print("statement body")
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapMultilineStatementBraces)
    }

    func testMultilineFuncBraceOnNextLine() {
        let input = """
        func method(
            foo: Int,
            bar: Int) {
            print("function body")
        }
        """
        let output = """
        func method(
            foo: Int,
            bar: Int)
        {
            print("function body")
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapMultilineStatementBraces,
                       exclude: ["wrapArguments", "unusedArguments"])
    }

    func testMultilineInitBraceOnNextLine() {
        let input = """
        init(foo: Int,
             bar: Int) {
            print("function body")
        }
        """
        let output = """
        init(foo: Int,
             bar: Int)
        {
            print("function body")
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapMultilineStatementBraces,
                       exclude: ["wrapArguments", "unusedArguments"])
    }

    func testMultilineForLoopBraceOnNextLine() {
        let input = """
        for foo in
            [1, 2] {
            print(foo)
        }
        """
        let output = """
        for foo in
            [1, 2]
        {
            print(foo)
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapMultilineStatementBraces)
    }

    func testMultilineForLoopBraceOnNextLine2() {
        let input = """
        for foo in [
            1,
            2,
        ] {
            print(foo)
        }
        """
        testFormatting(for: input, rule: FormatRules.wrapMultilineStatementBraces)
    }

    func testMultilineForWhereLoopBraceOnNextLine() {
        let input = """
        for foo in bar
            where foo != baz {
            print(foo)
        }
        """
        let output = """
        for foo in bar
            where foo != baz
        {
            print(foo)
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapMultilineStatementBraces)
    }

    func testMultilineGuardBraceOnNextLine() {
        let input = """
        guard firstConditional,
              array.contains(where: { secondConditional }) else {
            print("statement body")
        }
        """
        let output = """
        guard firstConditional,
              array.contains(where: { secondConditional }) else
        {
            print("statement body")
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapMultilineStatementBraces,
                       exclude: ["braces", "elseOnSameLine"])
    }

    func testInnerMultilineIfBraceOnNextLine() {
        let input = """
        if outerConditional {
            if firstConditional,
               array.contains(where: { secondConditional }) {
                print("statement body")
            }
        }
        """
        let output = """
        if outerConditional {
            if firstConditional,
               array.contains(where: { secondConditional })
            {
                print("statement body")
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapMultilineStatementBraces)
    }

    func testMultilineIfBraceOnSameLine() {
        let input = """
        if let object = Object([
            foo,
            bar,
        ]) {
            print("statement body")
        }
        """
        testFormatting(for: input, rule: FormatRules.wrapMultilineStatementBraces)
    }

    func testSingleLineIfBraceOnSameLine() {
        let input = """
        if firstConditional {
            print("statement body")
        }
        """
        testFormatting(for: input, rule: FormatRules.wrapMultilineStatementBraces)
    }

    func testSingleLineGuardBrace() {
        let input = """
        guard firstConditional else {
            print("statement body")
        }
        """
        testFormatting(for: input, rule: FormatRules.wrapMultilineStatementBraces)
    }

    func testGuardElseOnOwnLineBraceNotWrapped() {
        let input = """
        guard let foo = bar,
              bar == baz
        else {
            print("statement body")
        }
        """
        testFormatting(for: input, rule: FormatRules.wrapMultilineStatementBraces)
    }

    func testMultilineGuardClosingBraceOnSameLine() {
        let input = """
        guard let foo = bar,
              let baz = quux else { return }
        """
        testFormatting(for: input, rule: FormatRules.wrapMultilineStatementBraces,
                       exclude: ["wrapConditionalBodies"])
    }

    func testMultilineGuardBraceOnSameLineAsElse() {
        let input = """
        guard let foo = bar,
              let baz = quux
        else {
            return
        }
        """
        testFormatting(for: input, rule: FormatRules.wrapMultilineStatementBraces)
    }

    func testMultilineClassBrace() {
        let input = """
        class Foo: BarProtocol,
            BazProtocol
        {
            init() {}
        }
        """
        testFormatting(for: input, rule: FormatRules.wrapMultilineStatementBraces)
    }

    func testMultilineClassBraceNotAppliedForXcodeIndentationMode() {
        let input = """
        class Foo: BarProtocol,
        BazProtocol {
            init() {}
        }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: FormatRules.wrapMultilineStatementBraces, options: options)
    }

    func testMultilineBraceAppliedToTrailingClosure_wrapBeforeFirst() {
        let input = """
        UIView.animate(
            duration: 10,
            options: []) {
            print()
        }
        """

        let output = """
        UIView.animate(
            duration: 10,
            options: [])
        {
            print()
        }
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenOnSameLine: true
        )
        testFormatting(for: input, output, rule: FormatRules.wrapMultilineStatementBraces,
                       options: options, exclude: ["indent"])
    }

    func testMultilineBraceAppliedToTrailingClosure2_wrapBeforeFirst() {
        let input = """
        moveGradient(
            to: defaultPosition,
            isTouchDown: false,
            animated: animated) {
                self.isTouchDown = false
            }
        """

        let output = """
        moveGradient(
            to: defaultPosition,
            isTouchDown: false,
            animated: animated)
        {
            self.isTouchDown = false
        }
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenOnSameLine: true
        )
        testFormatting(for: input, [output], rules: [
            FormatRules.wrapMultilineStatementBraces,
            FormatRules.indent, FormatRules.braces,
        ], options: options)
    }

    func testMultilineBraceAppliedToGetterBody_wrapBeforeFirst() {
        let input = """
        var items: Adaptive<CGFloat> = .adaptive(
            compact: Sizes.horizontalPaddingTiny_8,
            regular: Sizes.horizontalPaddingLarge_64) {
                didSet { updateAccessoryViewSpacing() }
        }
        """

        let output = """
        var items: Adaptive<CGFloat> = .adaptive(
            compact: Sizes.horizontalPaddingTiny_8,
            regular: Sizes.horizontalPaddingLarge_64)
        {
            didSet { updateAccessoryViewSpacing() }
        }
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenOnSameLine: true
        )
        testFormatting(for: input, [output], rules: [
            FormatRules.wrapMultilineStatementBraces,
            FormatRules.indent,
        ], options: options)
    }

    func testMultilineBraceAppliedToTrailingClosure_wrapAfterFirst() {
        let input = """
        UIView.animate(duration: 10,
                       options: []) {
            print()
        }
        """

        let output = """
        UIView.animate(duration: 10,
                       options: [])
        {
            print()
        }
        """

        let options = FormatOptions(
            wrapArguments: .afterFirst,
            closingParenOnSameLine: true
        )
        testFormatting(for: input, output, rule: FormatRules.wrapMultilineStatementBraces,
                       options: options, exclude: ["indent"])
    }

    func testMultilineBraceAppliedToGetterBody_wrapAfterFirst() {
        let input = """
        var items: Adaptive<CGFloat> = .adaptive(compact: Sizes.horizontalPaddingTiny_8,
                                                 regular: Sizes.horizontalPaddingLarge_64)
        {
            didSet { updateAccessoryViewSpacing() }
        }
        """

        let options = FormatOptions(
            wrapArguments: .afterFirst,
            closingParenOnSameLine: true
        )
        testFormatting(for: input, [], rules: [
            FormatRules.wrapMultilineStatementBraces,
            FormatRules.wrapArguments,
        ], options: options)
    }

    func testMultilineBraceAppliedToSubscriptBody() {
        let input = """
        public subscript(
            key: Foo)
            -> ServerDrivenLayoutContentPresenter<Feature>?
        {
            get { foo[key] }
            set { foo[key] = newValue }
        }
        """
        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenOnSameLine: true
        )
        testFormatting(for: input, rule: FormatRules.wrapMultilineStatementBraces,
                       options: options, exclude: ["trailingClosures"])
    }

    func testWrapsMultilineStatementConsistently() {
        let input = """
        func aFunc(
            one _: Int,
            two _: Int) -> String {
            "one"
        }
        """

        let output = """
        func aFunc(
            one _: Int,
            two _: Int)
            -> String
        {
            "one"
        }
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenOnSameLine: true,
            wrapReturnType: .ifMultiline
        )
        testFormatting(for: input, [output], rules: [
            FormatRules.wrapMultilineStatementBraces,
            FormatRules.wrapArguments,
        ], options: options)
    }

    func testWrapsMultilineStatementConsistently2() {
        let input = """
        func aFunc(
            one _: Int,
            two _: Int) -> String {
            "one"
        }
        """

        let output = """
        func aFunc(
            one _: Int,
            two _: Int
        ) -> String {
            "one"
        }
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenOnSameLine: false
        )
        testFormatting(for: input, [output], rules: [
            FormatRules.wrapMultilineStatementBraces,
            FormatRules.wrapArguments,
        ], options: options)
    }

    func testWrapsMultilineStatementConsistently2_withEffects() {
        let input = """
        func aFunc(
            one _: Int,
            two _: Int) async throws -> String {
            "one"
        }
        """

        let output = """
        func aFunc(
            one _: Int,
            two _: Int
        ) async throws -> String {
            "one"
        }
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenOnSameLine: false,
            wrapEffects: .never
        )
        testFormatting(for: input, [output], rules: [
            FormatRules.wrapMultilineStatementBraces,
            FormatRules.wrapArguments,
        ], options: options)
    }

    func testWrapsMultilineStatementConsistently3() {
        let input = """
        func aFunc(
            one _: Int,
            two _: Int
        ) -> String {
            "one"
        }
        """

        let options = FormatOptions(
            //            wrapMultilineStatementBraces: true,
            wrapArguments: .beforeFirst,
            closingParenOnSameLine: false
        )

        testFormatting(for: input, [], rules: [
            FormatRules.wrapMultilineStatementBraces,
            FormatRules.wrapArguments,
        ], options: options)
    }

    func testWrapsMultilineStatementConsistently4() {
        let input = """
        func aFunc(
            one _: Int,
            two _: Int
        ) -> String {
            "one"
        }
        """

        let output = """
        func aFunc(
            one _: Int,
            two _: Int) -> String
        {
            "one"
        }
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenOnSameLine: true
        )
        testFormatting(for: input, [output], rules: [
            FormatRules.wrapMultilineStatementBraces,
            FormatRules.wrapArguments,
        ], options: options)
    }

    func testWrapMultilineStatementConsistently5() {
        let input = """
        foo(
            one: 1,
            two: 2).bar({ _ in
            "one"
        })
        """
        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenOnSameLine: true
        )
        testFormatting(for: input, rule: FormatRules.wrapMultilineStatementBraces,
                       options: options, exclude: ["trailingClosures"])
    }

    func testOpenBraceAfterEqualsInGuardNotWrapped() {
        let input = """
        guard
            let foo = foo,
            let bar: String = {
                nil
            }()
        else { return }
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenOnSameLine: true
        )
        testFormatting(for: input, rules: [FormatRules.wrapMultilineStatementBraces, FormatRules.wrap],
                       options: options, exclude: ["indent", "redundantClosure", "wrapConditionalBodies"])
    }

    // MARK: wrapConditions before-first

    func testWrapConditionsBeforeFirstPreservesMultilineStatements() {
        let input = """
        if
            let unwrappedFoo = Foo(
                bar: bar,
                baz: baz),
            unwrappedFoo.elements
                .compactMap({ $0 })
                .filter({
                    if $0.matchesCondition {
                        return true
                    } else {
                        return false
                    }
                }).isEmpty,
            let bar = unwrappedFoo.bar,
            let baz = unwrappedFoo.bar?
                .first(where: { $0.isBaz }),
            let unwrappedFoo2 = Foo(
                bar: bar2,
                baz: baz2),
            let quux = baz.quux
        {}
        """

        testFormatting(
            for: input, rules: [FormatRules.wrapArguments, FormatRules.indent],
            options: FormatOptions(closingParenOnSameLine: true, wrapConditions: .beforeFirst)
        )
    }

    func testWrapConditionsBeforeFirst() {
        let input = """
        if let foo = foo,
           let bar = bar,
           foo == bar {}

        else if foo != bar,
                let quux = quux {}

        if let baz = baz {}

        guard baz.filter({ $0 == foo }),
              let bar = bar else {}

        while let foo = foo,
              let bar = bar {}
        """

        let output = """
        if
          let foo = foo,
          let bar = bar,
          foo == bar {}

        else if
          foo != bar,
          let quux = quux {}

        if let baz = baz {}

        guard
          baz.filter({ $0 == foo }),
          let bar = bar else {}

        while
          let foo = foo,
          let bar = bar {}
        """

        testFormatting(
            for: input, [output], rules: [FormatRules.wrapArguments, FormatRules.indent],
            options: FormatOptions(indent: "  ", wrapConditions: .beforeFirst),
            exclude: ["wrapConditionalBodies"]
        )
    }

    func testWrapConditionsBeforeFirstWhereShouldPreserveExisting() {
        let input = """
        else {}

        else
        {}

        if foo == bar
        {}

        guard let foo = bar else
        {}

        guard let foo = bar
        else {}
        """

        testFormatting(
            for: input, rules: [FormatRules.wrapArguments, FormatRules.indent],
            options: FormatOptions(indent: "  ", wrapConditions: .beforeFirst),
            exclude: ["elseOnSameLine", "wrapConditionalBodies"]
        )
    }

    func testWrapConditionsAfterFirst() {
        let input = """
        if
          let foo = foo,
          let bar = bar,
          foo == bar {}

        else if
          foo != bar,
          let quux = quux {}

        else {}

        if let baz = baz {}

        guard
          baz.filter({ $0 == foo }),
          let bar = bar else {}

        while
          let foo = foo,
          let bar = bar {}
        """

        let output = """
        if let foo = foo,
           let bar = bar,
           foo == bar {}

        else if foo != bar,
                let quux = quux {}

        else {}

        if let baz = baz {}

        guard baz.filter({ $0 == foo }),
              let bar = bar else {}

        while let foo = foo,
              let bar = bar {}
        """

        testFormatting(
            for: input, [output], rules: [FormatRules.wrapArguments, FormatRules.indent],
            options: FormatOptions(indent: "  ", wrapConditions: .afterFirst),
            exclude: ["wrapConditionalBodies"]
        )
    }

    // MARK: conditionsWrap auto

    func testConditionsWrapAutoForLongGuard() {
        let input = """
        guard let foo = foo, let bar = bar, let third = third else {}
        """

        let output = """
        guard let foo = foo,
              let bar = bar,
              let third = third
        else {}
        """

        testFormatting(
            for: input,
            [output],
            rules: [FormatRules.wrapArguments],
            options: FormatOptions(indent: "  ", conditionsWrap: .auto, maxWidth: 40)
        )
    }

    func testConditionsWrapAutoForLongGuardWithoutChanges() {
        let input = """
        guard let foo = foo, let bar = bar, let third = third else {}
        """
        testFormatting(
            for: input,
            rules: [FormatRules.wrapArguments],
            options: FormatOptions(indent: "  ", conditionsWrap: .auto, maxWidth: 120)
        )
    }

    func testConditionsWrapAutoForMultilineGuard() {
        let input = """
        guard let foo = foo,
              let bar = bar, let third = third else {}
        """

        let output = """
        guard let foo = foo,
              let bar = bar,
              let third = third
        else {}
        """

        testFormatting(
            for: input,
            [output],
            rules: [FormatRules.wrapArguments, FormatRules.indent],
            options: FormatOptions(indent: "  ", conditionsWrap: .auto, maxWidth: 40)
        )
    }

    func testConditionsWrapAutoOptionForGuardStyledAsBeforeArgument() {
        let input = """
        guard
            let foo = foo,
            let bar = bar,
            let third = third
        else {}

        guard
        let foo = foo,
        let bar = bar,
        let third = third
        else {}
        """

        let output = """
        guard let foo = foo,
              let bar = bar,
              let third = third
        else {}

        guard let foo = foo,
              let bar = bar,
              let third = third
        else {}
        """

        testFormatting(
            for: input,
            [output],
            rules: [FormatRules.wrapArguments],
            options: FormatOptions(indent: "  ", conditionsWrap: .auto, maxWidth: 40)
        )
    }

    func testConditionsWrapAutoOptionForGuardWhenElseOnNewLine() {
        let input = """
        guard let foo = foo, let bar = bar, let third = third
        else {}
        """

        let output = """
        guard let foo = foo,
              let bar = bar,
              let third = third
        else {}
        """

        testFormatting(
            for: input,
            [output],
            rules: [FormatRules.wrapArguments],
            options: FormatOptions(indent: "  ", conditionsWrap: .auto, maxWidth: 40)
        )
    }

    func testConditionsWrapAutoOptionForGuardWhenElseOnNewLineAndNotAligned() {
        let input = """
        guard let foo = foo, let bar = bar, let third = third
           else {}

        guard let foo = foo, let bar = bar, let third = third

        else {}
        """

        let output = """
        guard let foo = foo,
              let bar = bar,
              let third = third
        else {}

        guard let foo = foo,
              let bar = bar,
              let third = third
        else {}
        """

        testFormatting(
            for: input,
            [output],
            rules: [FormatRules.wrapArguments],
            options: FormatOptions(indent: "  ", conditionsWrap: .auto, maxWidth: 40)
        )
    }

    func testConditionsWrapAutoOptionForGuardInMethod() {
        let input = """
        func doSmth() {
            let a = smth as? SmthElse

            guard
                let foo = foo,
                let bar = bar,
                let third = third
            else {
                return nil
            }

            let value = a.doSmth()
        }
        """

        let output = """
        func doSmth() {
            let a = smth as? SmthElse

            guard let foo = foo,
                  let bar = bar,
                  let third = third
            else {
                return nil
            }

            let value = a.doSmth()
        }
        """

        testFormatting(
            for: input,
            [output],
            rules: [FormatRules.wrapArguments],
            options: FormatOptions(indent: "    ", conditionsWrap: .auto, maxWidth: 120)
        )
    }

    func testConditionsWrapAutoOptionForIfInsideMethod() {
        let input = """
        func doSmth() {
            let a = smth as? SmthElse

            if
            let foo = foo,
            let bar = bar,
            let third = third {
                return nil
            }

            let value = a.doSmth()
        }
        """

        let output = """
        func doSmth() {
            let a = smth as? SmthElse

            if let foo = foo,
               let bar = bar,
               let third = third {
                return nil
            }

            let value = a.doSmth()
        }
        """

        testFormatting(
            for: input,
            [output],
            rules: [FormatRules.wrapArguments],
            options: FormatOptions(indent: "    ", conditionsWrap: .auto, maxWidth: 120),
            exclude: ["wrapMultilineStatementBraces"]
        )
    }

    func testConditionsWrapAutoOptionForLongIf() {
        let input = """
        if let foo = foo, let bar = bar, let third = third {}
        """

        let output = """
        if let foo = foo,
           let bar = bar,
           let third = third {}
        """

        testFormatting(
            for: input,
            [output],
            rules: [FormatRules.wrapArguments, FormatRules.indent],
            options: FormatOptions(indent: "  ", conditionsWrap: .auto, maxWidth: 25)
        )
    }

    func testConditionsWrapAutoOptionForLongMultilineIf() {
        let input = """
        if let foo = foo,
        let bar = bar, let third = third {}
        """

        let output = """
        if let foo = foo,
           let bar = bar,
           let third = third {}
        """

        testFormatting(
            for: input,
            [output],
            rules: [FormatRules.wrapArguments, FormatRules.indent],
            options: FormatOptions(indent: "  ", conditionsWrap: .auto, maxWidth: 25)
        )
    }

    // MARK: conditionsWrap always

    func testConditionWrapAlwaysOptionForLongGuard() {
        let input = """
        guard let foo = foo, let bar = bar, let third = third else {}
        """

        let output = """
        guard let foo = foo,
              let bar = bar,
              let third = third
        else {}
        """

        testFormatting(
            for: input,
            [output],
            rules: [FormatRules.wrapArguments],
            options: FormatOptions(indent: "  ", conditionsWrap: .always, maxWidth: 120)
        )
    }

    // MARK: - wrapAttributes

    func testPreserveWrappedFuncAttributeByDefault() {
        let input = """
        @objc
        func foo() {}
        """
        testFormatting(for: input, rule: FormatRules.wrapAttributes)
    }

    func testPreserveUnwrappedFuncAttributeByDefault() {
        let input = """
        @objc func foo() {}
        """
        testFormatting(for: input, rule: FormatRules.wrapAttributes)
    }

    func testWrapFuncAttribute() {
        let input = """
        @available(iOS 14.0, *) func foo() {}
        """
        let output = """
        @available(iOS 14.0, *)
        func foo() {}
        """
        let options = FormatOptions(funcAttributes: .prevLine)
        testFormatting(for: input, output, rule: FormatRules.wrapAttributes, options: options)
    }

    func testWrapInitAttribute() {
        let input = """
        @available(iOS 14.0, *) init() {}
        """
        let output = """
        @available(iOS 14.0, *)
        init() {}
        """
        let options = FormatOptions(funcAttributes: .prevLine)
        testFormatting(for: input, output, rule: FormatRules.wrapAttributes, options: options)
    }

    func testMultipleAttributesNotSeparated() {
        let input = """
        @objc @IBAction func foo {}
        """
        let output = """
        @objc @IBAction
        func foo {}
        """
        let options = FormatOptions(funcAttributes: .prevLine)
        testFormatting(for: input, output, rule: FormatRules.wrapAttributes,
                       options: options, exclude: ["redundantObjc"])
    }

    func testFuncAttributeStaysWrapped() {
        let input = """
        @available(iOS 14.0, *)
        func foo() {}
        """
        let options = FormatOptions(funcAttributes: .prevLine)
        testFormatting(for: input, rule: FormatRules.wrapAttributes, options: options)
    }

    func testUnwrapFuncAttribute() {
        let input = """
        @available(iOS 14.0, *)
        func foo() {}
        """
        let output = """
        @available(iOS 14.0, *) func foo() {}
        """
        let options = FormatOptions(funcAttributes: .sameLine)
        testFormatting(for: input, output, rule: FormatRules.wrapAttributes, options: options)
    }

    func testFuncAttributeStaysUnwrapped() {
        let input = """
        @objc func foo() {}
        """
        let options = FormatOptions(funcAttributes: .sameLine)
        testFormatting(for: input, rule: FormatRules.wrapAttributes, options: options)
    }

    func testVarAttributeIsNotWrapped() {
        let input = """
        @IBOutlet var foo: UIView?

        @available(iOS 14.0, *)
        func foo() {}
        """
        let options = FormatOptions(funcAttributes: .prevLine)
        testFormatting(for: input, rule: FormatRules.wrapAttributes, options: options)
    }

    func testWrapTypeAttribute() {
        let input = """
        @available(iOS 14.0, *) class Foo {}
        """
        let output = """
        @available(iOS 14.0, *)
        class Foo {}
        """
        let options = FormatOptions(typeAttributes: .prevLine)
        testFormatting(
            for: input,
            output,
            rule: FormatRules.wrapAttributes,
            options: options
        )
    }

    func testWrapExtensionAttribute() {
        let input = """
        @available(iOS 14.0, *) extension Foo {}
        """
        let output = """
        @available(iOS 14.0, *)
        extension Foo {}
        """
        let options = FormatOptions(typeAttributes: .prevLine)
        testFormatting(
            for: input,
            output,
            rule: FormatRules.wrapAttributes,
            options: options
        )
    }

    func testTypeAttributeStaysWrapped() {
        let input = """
        @available(iOS 14.0, *)
        struct Foo {}
        """
        let options = FormatOptions(typeAttributes: .prevLine)
        testFormatting(for: input, rule: FormatRules.wrapAttributes, options: options)
    }

    func testUnwrapTypeAttribute() {
        let input = """
        @available(iOS 14.0, *)
        enum Foo {}
        """
        let output = """
        @available(iOS 14.0, *) enum Foo {}
        """
        let options = FormatOptions(typeAttributes: .sameLine)
        testFormatting(for: input, output, rule: FormatRules.wrapAttributes, options: options)
    }

    func testTypeAttributeStaysUnwrapped() {
        let input = """
        @objc class Foo {}
        """
        let options = FormatOptions(typeAttributes: .sameLine)
        testFormatting(for: input, rule: FormatRules.wrapAttributes, options: options)
    }

    func testTestableImportIsNotWrapped() {
        let input = """
        @testable import Framework

        @available(iOS 14.0, *)
        class Foo {}
        """
        let options = FormatOptions(typeAttributes: .prevLine)
        testFormatting(for: input, rule: FormatRules.wrapAttributes, options: options)
    }

    func testModifiersDontAffectAttributeWrapping() {
        let input = """
        @objc override public func foo {}
        """
        let output = """
        @objc
        override public func foo {}
        """
        let options = FormatOptions(funcAttributes: .prevLine)
        testFormatting(for: input, output, rule: FormatRules.wrapAttributes, options: options)
    }

    func testClassFuncAttributeTreatedAsFunction() {
        let input = """
        @objc class func foo {}
        """
        let output = """
        @objc
        class func foo {}
        """
        let options = FormatOptions(funcAttributes: .prevLine, fragment: true)
        testFormatting(for: input, output, rule: FormatRules.wrapAttributes, options: options)
    }

    func testClassFuncAttributeNotTreatedAsType() {
        let input = """
        @objc class func foo {}
        """
        let options = FormatOptions(typeAttributes: .prevLine, fragment: true)
        testFormatting(for: input, rule: FormatRules.wrapAttributes, options: options)
    }

    func testClassImportAttributeNotTreatedAsType() {
        let input = """
        @testable import class Framework.Foo
        """
        let options = FormatOptions(typeAttributes: .prevLine)
        testFormatting(for: input, rule: FormatRules.wrapAttributes, options: options)
    }

    func testWrapPrivateSetVarAttributes() {
        let input = """
        @objc private(set) dynamic var foo = Foo()
        """
        let output = """
        @objc
        private(set) dynamic var foo = Foo()
        """
        let options = FormatOptions(varAttributes: .prevLine)
        testFormatting(for: input, output, rule: FormatRules.wrapAttributes, options: options)
    }

    func testWrapConvenienceInitAttribute() {
        let input = """
        @objc public convenience init() {}
        """
        let output = """
        @objc
        public convenience init() {}
        """
        let options = FormatOptions(funcAttributes: .prevLine)
        testFormatting(for: input, output, rule: FormatRules.wrapAttributes, options: options)
    }

    func testWrapPropertyWrapperAttribute() {
        let input = """
        @OuterType.Wrapper var foo: Int
        """
        let output = """
        @OuterType.Wrapper
        var foo: Int
        """
        let options = FormatOptions(varAttributes: .prevLine)
        testFormatting(for: input, output, rule: FormatRules.wrapAttributes, options: options)
    }

    func testWrapGenericPropertyWrapperAttribute() {
        let input = """
        @OuterType.Generic<WrappedType> var foo: WrappedType
        """
        let output = """
        @OuterType.Generic<WrappedType>
        var foo: WrappedType
        """
        let options = FormatOptions(varAttributes: .prevLine)
        testFormatting(for: input, output, rule: FormatRules.wrapAttributes, options: options)
    }

    func testWrapGenericPropertyWrapperAttribute2() {
        let input = """
        @OuterType.Generic<WrappedType>.Foo var foo: WrappedType
        """
        let output = """
        @OuterType.Generic<WrappedType>.Foo
        var foo: WrappedType
        """
        let options = FormatOptions(varAttributes: .prevLine)
        testFormatting(for: input, output, rule: FormatRules.wrapAttributes, options: options)
    }

    func testWrapAttributesIndentsLineCorrectly() {
        let input = """
        class Foo {
            @objc var foo = Foo()
        }
        """
        let output = """
        class Foo {
            @objc
            var foo = Foo()
        }
        """
        let options = FormatOptions(varAttributes: .prevLine)
        testFormatting(for: input, output, rule: FormatRules.wrapAttributes, options: options)
    }

    func testInlineMainActorAttributeNotWrapped() {
        let input = """
        var foo: @MainActor (Foo) -> Void
        var bar: @MainActor (Bar) -> Void
        """
        let options = FormatOptions(varAttributes: .prevLine)
        testFormatting(for: input, rule: FormatRules.wrapAttributes, options: options)
    }

    // MARK: wrapEnumCases

    func testMultilineEnumCases() {
        let input = """
        enum Enum1: Int {
            case a = 0, p = 2, c, d
            case e, k
            case m(String, String)
        }
        """
        let output = """
        enum Enum1: Int {
            case a = 0
            case p = 2
            case c
            case d
            case e
            case k
            case m(String, String)
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapEnumCases)
    }

    func testMultilineEnumCasesWithNestedEnumsDoesNothing() {
        let input = """
        public enum SearchTerm: Decodable, Equatable {
            case term(name: String)
            case category(category: Category)

            enum CodingKeys: String, CodingKey {
                case name
                case type
                case categoryID = "category_id"
                case attributes
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.wrapEnumCases)
    }

    func testEnumCaseSplitOverMultipleLines() {
        let input = """
        enum Foo {
            case bar(
                x: String,
                y: Int
            ), baz
        }
        """
        let output = """
        enum Foo {
            case bar(
                x: String,
                y: Int
            )
            case baz
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapEnumCases)
    }

    func testEnumCasesAlreadyWrappedOntoMultipleLines() {
        let input = """
        enum Foo {
            case bar,
                 baz,
                 quux
        }
        """
        let output = """
        enum Foo {
            case bar
            case baz
            case quux
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapEnumCases)
    }

    func testEnumCasesIfValuesWithoutValuesDoesNothing() {
        let input = """
        enum Foo {
            case bar, baz, quux
        }
        """
        testFormatting(for: input, rule: FormatRules.wrapEnumCases,
                       options: FormatOptions(wrapEnumCases: .withValues))
    }

    func testEnumCasesIfValuesWithRawValuesAndNestedEnum() {
        let input = """
        enum Foo {
            case bar = 1, baz, quux

            enum Foo2 {
                case bar, baz, quux
            }
        }
        """
        let output = """
        enum Foo {
            case bar = 1
            case baz
            case quux

            enum Foo2 {
                case bar, baz, quux
            }
        }
        """
        testFormatting(
            for: input,
            output,
            rule: FormatRules.wrapEnumCases,
            options: FormatOptions(wrapEnumCases: .withValues)
        )
    }

    func testEnumCasesIfValuesWithAssociatedValues() {
        let input = """
        enum Foo {
            case bar(a: Int), baz, quux
        }
        """
        let output = """
        enum Foo {
            case bar(a: Int)
            case baz
            case quux
        }
        """
        testFormatting(
            for: input,
            output,
            rule: FormatRules.wrapEnumCases,
            options: FormatOptions(wrapEnumCases: .withValues)
        )
    }

    func testEnumCasesWithCommentsAlreadyWrappedOntoMultipleLines() {
        let input = """
        enum Foo {
            case bar, // bar
                 baz, // baz
                 quux // quux
        }
        """
        let output = """
        enum Foo {
            case bar // bar
            case baz // baz
            case quux // quux
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapEnumCases)
    }

    func testNoWrapEnumStatementAllOnOneLine() {
        let input = "enum Foo { bar, baz }"
        testFormatting(for: input, rule: FormatRules.wrapEnumCases)
    }

    func testNoConfuseIfCaseWithEnum() {
        let input = """
        enum Foo {
            case foo
            case bar(value: [Int])
        }

        func baz() {
            if case .foo = foo,
               case .bar(let value) = bar,
               value.isEmpty
            {
                print("")
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.wrapEnumCases,
                       exclude: ["hoistPatternLet"])
    }

    // MARK: wrapSwitchCases

    func testMultilineSwitchCases() {
        let input = """
        func foo() {
            switch bar {
            case .a(_), .b, "c":
                print("")
            case .d:
                print("")
            }
        }
        """
        let output = """
        func foo() {
            switch bar {
            case .a(_),
                 .b,
                 "c":
                print("")
            case .d:
                print("")
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.wrapSwitchCases)
    }

    func testIfAfterSwitchCaseNotWrapped() {
        let input = """
        switch foo {
        case "foo":
            print("")
        default:
            print("")
        }
        if let foo = bar, foo != .baz {
            throw error
        }
        """
        testFormatting(for: input, rule: FormatRules.wrapSwitchCases)
    }

    // MARK: wrapSingleLineComments

    func testWrapSingleLineComment() {
        let input = """
        // a b cde fgh
        """
        let output = """
        // a b
        // cde
        // fgh
        """

        testFormatting(for: input, output, rule: FormatRules.wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 6))
    }

    func testWrapSingleLineCommentThatOverflowsByOneCharacter() {
        let input = """
        // a b cde fg h
        """
        let output = """
        // a b cde fg
        // h
        """

        testFormatting(for: input, output, rule: FormatRules.wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 14))
    }

    func testNoWrapSingleLineCommentThatExactlyFits() {
        let input = """
        // a b cde fg h
        """

        testFormatting(for: input, rule: FormatRules.wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 15))
    }

    func testWrapSingleLineCommentWithNoLeadingSpace() {
        let input = """
        //a b cde fgh
        """
        let output = """
        //a b
        //cde
        //fgh
        """

        testFormatting(for: input, output, rule: FormatRules.wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 6),
                       exclude: ["spaceInsideComments"])
    }

    func testWrapDocComment() {
        let input = """
        /// a b cde fgh
        """
        let output = """
        /// a b
        /// cde
        /// fgh
        """

        testFormatting(for: input, output, rule: FormatRules.wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 7), exclude: ["docComments"])
    }

    func testWrapDocLineCommentWithNoLeadingSpace() {
        let input = """
        ///a b cde fgh
        """
        let output = """
        ///a b
        ///cde
        ///fgh
        """

        testFormatting(for: input, output, rule: FormatRules.wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 6),
                       exclude: ["spaceInsideComments", "docComments"])
    }

    func testWrapSingleLineCommentWithIndent() {
        let input = """
        func f() {
            // a b cde fgh
            let x = 1
        }
        """
        let output = """
        func f() {
            // a b cde
            // fgh
            let x = 1
        }
        """

        testFormatting(for: input, output, rule: FormatRules.wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 14), exclude: ["docComments"])
    }

    func testWrapSingleLineCommentAfterCode() {
        let input = """
        func f() {
            foo.bar() // this comment is much much much too long
        }
        """
        let output = """
        func f() {
            foo.bar() // this comment
            // is much much much too
            // long
        }
        """

        testFormatting(for: input, output, rule: FormatRules.wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 29), exclude: ["wrap"])
    }

    func testWrapDocCommentWithLongURL() {
        let input = """
        /// See [Link](https://www.domain.com/pathextension/pathextension/pathextension/pathextension/pathextension/pathextension).
        """

        testFormatting(for: input, rule: FormatRules.wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 100), exclude: ["docComments"])
    }

    func testWrapDocCommentWithLongURL2() {
        let input = """
        /// Link to SDK documentation - https://docs.adyen.com/checkout/3d-secure/native-3ds2/api-integration#collect-the-3d-secure-2-device-fingerprint-from-an-ios-app
        """

        testFormatting(for: input, rule: FormatRules.wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 80))
    }

    func testWrapDocCommentWithMultipleLongURLs() {
        let input = """
        /// Link to http://a-very-long-url-that-wont-fit-on-one-line, http://another-very-long-url-that-wont-fit-on-one-line
        """
        let output = """
        /// Link to http://a-very-long-url-that-wont-fit-on-one-line,
        /// http://another-very-long-url-that-wont-fit-on-one-line
        """

        testFormatting(for: input, output, rule: FormatRules.wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 40), exclude: ["docComments"])
    }
}
