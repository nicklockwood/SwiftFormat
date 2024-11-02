//
//  WrapArgumentsTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 11/23/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class WrapArgumentsTests: XCTestCase {
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
        testFormatting(for: input, output, rule: .wrapArguments, exclude: [.propertyTypes])
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
        testFormatting(for: input, output, rule: .wrapArguments)
    }

    func testWrapArgumentsDoesntIndentClosingBracket() {
        let input = """
        [
            "foo": [
            ],
        ]
        """
        testFormatting(for: input, rule: .wrapArguments)
    }

    func testWrapParametersDoesNotAffectFunctionDeclaration() {
        let input = "foo(\n    bar _: Int,\n    baz _: String\n)"
        let options = FormatOptions(wrapArguments: .preserve, wrapParameters: .afterFirst)
        testFormatting(for: input, rule: .wrapArguments, options: options)
    }

    func testWrapParametersClosureAfterParameterListDoesNotWrapClosureArguments() {
        let input = """
        func foo() {}
        bar = (baz: 5, quux: 7,
               quuz: 10)
        """
        let options = FormatOptions(wrapArguments: .preserve, wrapParameters: .beforeFirst)
        testFormatting(for: input, rule: .wrapArguments, options: options)
    }

    func testWrapParametersNotSetWrapArgumentsAfterFirstDefaultsToAfterFirst() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let output = "func foo(bar _: Int,\n         baz _: String) {}"
        let options = FormatOptions(wrapArguments: .afterFirst)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    func testWrapParametersNotSetWrapArgumentsBeforeFirstDefaultsToBeforeFirst() {
        let input = "func foo(bar _: Int,\n    baz _: String) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapArguments: .beforeFirst)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    func testWrapParametersNotSetWrapArgumentsPreserveDefaultsToPreserve() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapArguments: .preserve)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    func testWrapParametersFunctionDeclarationClosingParenOnSameLine() {
        let input = """
        func foo(
            bar _: Int,
            baz _: String
        ) {}
        """
        let output = """
        func foo(
            bar _: Int,
            baz _: String) {}
        """
        let options = FormatOptions(wrapArguments: .beforeFirst, closingParenPosition: .sameLine)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    func testWrapParametersFunctionDeclarationClosingParenOnNextLine() {
        let input = """
        func foo(
            bar _: Int,
            baz _: String) {}
        """
        let output = """
        func foo(
            bar _: Int,
            baz _: String
        ) {}
        """
        let options = FormatOptions(wrapArguments: .beforeFirst, closingParenPosition: .balanced)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    func testWrapParametersFunctionDeclarationClosingParenOnSameLineAndForce() {
        let input = """
        func foo(
            bar _: Int,
            baz _: String
        ) {}
        """
        let output = """
        func foo(
            bar _: Int,
            baz _: String) {}
        """
        let options = FormatOptions(wrapArguments: .beforeFirst, closingParenPosition: .sameLine, callSiteClosingParenPosition: .sameLine)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    func testWrapParametersFunctionDeclarationClosingParenOnNextLineAndForce() {
        let input = """
        func foo(
            bar _: Int,
            baz _: String) {}
        """
        let output = """
        func foo(
            bar _: Int,
            baz _: String
        ) {}
        """
        let options = FormatOptions(wrapArguments: .beforeFirst, closingParenPosition: .balanced, callSiteClosingParenPosition: .sameLine)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    func testWrapParametersFunctionCallClosingParenOnNextLineAndForce() {
        let input = """
        foo(
            bar: 42,
            baz: "foo"
        )
        """
        let output = """
        foo(
            bar: 42,
            baz: "foo")
        """
        let options = FormatOptions(wrapArguments: .beforeFirst, closingParenPosition: .balanced, callSiteClosingParenPosition: .sameLine)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
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
        testFormatting(for: input, rule: .wrapArguments, options: options)
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
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    func testIssue1530() {
        let input = """
        extension DRAutoWeatherReadRequestResponse {
            static let mock = DRAutoWeatherReadRequestResponse(
                offlineFirstWeather: DRAutoWeatherReadRequestResponse.DROfflineFirstWeather(
                    daily: .mockWeatherID, hourly: []
                )
            )
        }
        """
        let options = FormatOptions(wrapArguments: .beforeFirst)
        testFormatting(for: input, rule: .wrapArguments, options: options, exclude: [.propertyTypes])
    }

    // MARK: wrapParameters

    // MARK: preserve

    func testAfterFirstPreserved() {
        let input = "func foo(bar _: Int,\n         baz _: String) {}"
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, rule: .wrapArguments, options: options)
    }

    func testAfterFirstPreservedIndentFixed() {
        let input = "func foo(bar _: Int,\n baz _: String) {}"
        let output = "func foo(bar _: Int,\n         baz _: String) {}"
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    func testAfterFirstPreservedNewlineRemoved() {
        let input = "func foo(bar _: Int,\n         baz _: String\n) {}"
        let output = "func foo(bar _: Int,\n         baz _: String) {}"
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    func testBeforeFirstPreserved() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, rule: .wrapArguments, options: options)
    }

    func testBeforeFirstPreservedIndentFixed() {
        let input = "func foo(\n    bar _: Int,\n baz _: String\n) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    func testBeforeFirstPreservedNewlineAdded() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
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
        testFormatting(for: input, rule: .wrapArguments, options: options)
    }

    // MARK: afterFirst

    func testBeforeFirstConvertedToAfterFirst() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let output = "func foo(bar _: Int,\n         baz _: String) {}"
        let options = FormatOptions(wrapParameters: .afterFirst)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    func testNoWrapInnerArguments() {
        let input = "func foo(\n    bar _: Int,\n    baz _: foo(bar, baz)\n) {}"
        let output = "func foo(bar _: Int,\n         baz _: foo(bar, baz)) {}"
        let options = FormatOptions(wrapParameters: .afterFirst)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
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
        testFormatting(for: input, output, rule: .wrapArguments, options: options,
                       exclude: [.unusedArguments, .wrap])
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
        testFormatting(for: input, output, rule: .wrapArguments, options: options,
                       exclude: [.unusedArguments, .wrap])
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
        testFormatting(for: input, output, rule: .wrapArguments, options: options,
                       exclude: [.unusedArguments, .wrap])
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
                       rules: [.wrapArguments, .wrap],
                       options: options, exclude: [.unusedArguments])
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
                       rules: [.wrapArguments, .wrap],
                       options: options, exclude: [.unusedArguments])
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
                       rules: [.wrapArguments, .wrap],
                       options: options, exclude: [.unusedArguments])
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
                       rules: [.wrapArguments],
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
        testFormatting(for: input, [input, output2], rules: [.wrapArguments],
                       options: options, exclude: [.unusedArguments])
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
        testFormatting(for: input, output, rule: .wrapArguments,
                       options: options, exclude: [.unusedArguments])
    }

    // MARK: beforeFirst

    func testWrapAfterFirstConvertedToWrapBefore() {
        let input = "func foo(bar _: Int,\n    baz _: String) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    func testLinebreakInsertedAtEndOfWrappedFunction() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    func testAfterFirstConvertedToBeforeFirst() {
        let input = "func foo(bar _: Int,\n         baz _: String) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
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
                       rules: [.wrapArguments],
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
                       rules: [.wrapArguments],
                       options: options)
    }

    func testWrapParametersListBeforeFirstInTypedThrowingClosureType() {
        let input = """
        var mathFunction: (Int,
                           Int, String) throws(Foo) -> Int = { _, _, _ in
            0
        }
        """
        let output = """
        var mathFunction: (
            Int,
            Int,
            String
        ) throws(Foo) -> Int = { _, _, _ in
            0
        }
        """
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, [output],
                       rules: [.wrapArguments],
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
                       rules: [.wrapArguments],
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
                       rules: [.wrapArguments],
                       options: options,
                       exclude: [.unusedArguments])
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
                       rules: [.wrapArguments],
                       options: options,
                       exclude: [.unusedArguments])
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
                       rules: [.wrapArguments],
                       options: options,
                       exclude: [.unusedArguments])
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
                       rules: [.wrapArguments],
                       options: options,
                       exclude: [.unusedArguments])
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
                       rules: [.wrapArguments],
                       options: options,
                       exclude: [.unusedArguments])
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
                       rules: [.wrapArguments],
                       options: options,
                       exclude: [.unusedArguments])
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
        testFormatting(for: input, output, rule: .wrapArguments, options: options,
                       exclude: [.unusedArguments])
    }

    func testNoWrapBeforeFirstIfMaxLengthNotExceeded() {
        let input = """
        func foo(bar: Int, baz: String) -> Bool {}
        """
        let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 42)
        testFormatting(for: input, rule: .wrapArguments, options: options,
                       exclude: [.unusedArguments])
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
        testFormatting(for: input, output, rule: .wrapArguments, options: options,
                       exclude: [.unusedArguments])
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
        testFormatting(for: input, output, rule: .wrapArguments, options: options,
                       exclude: [.unusedArguments])
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
        testFormatting(for: input, [input, output2], rules: [.wrapArguments],
                       options: options, exclude: [.unusedArguments])
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
        testFormatting(for: input, output, rule: .wrapArguments,
                       options: options, exclude: [.unusedArguments])
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
        testFormatting(for: input, [output], rules: [.wrapArguments],
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
        testFormatting(for: input, rule: .wrapArguments,
                       options: options, exclude: [.unusedArguments])
    }

    func testNoWrapSubscriptWithSingleElement() {
        let input = "guard let foo = bar[0] {}"
        let options = FormatOptions(wrapCollections: .beforeFirst, maxWidth: 20)
        testFormatting(for: input, rule: .wrapArguments, options: options,
                       exclude: [.wrap])
    }

    func testNoWrapArrayWithSingleElement() {
        let input = "let foo = [0]"
        let options = FormatOptions(wrapCollections: .beforeFirst, maxWidth: 11)
        testFormatting(for: input, rule: .wrapArguments, options: options,
                       exclude: [.wrap])
    }

    func testNoWrapDictionaryWithSingleElement() {
        let input = "let foo = [bar: baz]"
        let options = FormatOptions(wrapCollections: .beforeFirst, maxWidth: 15)
        testFormatting(for: input, rule: .wrapArguments, options: options,
                       exclude: [.wrap])
    }

    func testNoWrapImageLiteral() {
        let input = "if let image = #imageLiteral(resourceName: \"abc.png\") {}"
        let options = FormatOptions(wrapCollections: .beforeFirst, maxWidth: 30)
        testFormatting(for: input, rule: .wrapArguments, options: options,
                       exclude: [.wrap])
    }

    func testNoWrapColorLiteral() {
        let input = """
        if let color = #colorLiteral(red: 0.2392156863, green: 0.6470588235, blue: 0.3647058824, alpha: 1) {}
        """
        let options = FormatOptions(wrapCollections: .beforeFirst, maxWidth: 30)
        testFormatting(for: input, rule: .wrapArguments, options: options,
                       exclude: [.wrap])
    }

    func testWrapArgumentsNoIndentBlankLines() {
        let input = """
        let foo = [

            bar,

        ]
        """
        let options = FormatOptions(wrapCollections: .beforeFirst)
        testFormatting(for: input, rule: .wrapArguments, options: options,
                       exclude: [.wrap, .blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    // MARK: closingParenPosition = true

    func testParenOnSameLineWhenWrapAfterFirstConvertedToWrapBefore() {
        let input = "func foo(bar _: Int,\n    baz _: String) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String) {}"
        let options = FormatOptions(wrapParameters: .beforeFirst, closingParenPosition: .sameLine)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    func testParenOnSameLineWhenWrapBeforeFirstUnchanged() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String) {}"
        let options = FormatOptions(wrapParameters: .beforeFirst, closingParenPosition: .sameLine)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    func testParenOnSameLineWhenWrapBeforeFirstPreserved() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String) {}"
        let options = FormatOptions(wrapParameters: .preserve, closingParenPosition: .sameLine)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    // MARK: indent with tabs

    func testTabIndentWrappedFunctionWithSmartTabs() {
        let input = """
        func foo(bar: Int,
                 baz: Int) {}
        """
        let options = FormatOptions(indent: "\t", wrapParameters: .afterFirst, tabWidth: 2)
        testFormatting(for: input, rule: .wrapArguments, options: options,
                       exclude: [.unusedArguments])
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
        testFormatting(for: input, output, rule: .wrapArguments, options: options,
                       exclude: [.unusedArguments])
    }

    // MARK: - wrapArguments --wrapArguments

    func testWrapArgumentsDoesNotAffectFunctionDeclaration() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapArguments: .afterFirst, wrapParameters: .preserve)
        testFormatting(for: input, rule: .wrapArguments, options: options)
    }

    func testWrapArgumentsDoesNotAffectInit() {
        let input = "init(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapArguments: .afterFirst, wrapParameters: .preserve)
        testFormatting(for: input, rule: .wrapArguments, options: options)
    }

    func testWrapArgumentsDoesNotAffectSubscript() {
        let input = "subscript(\n    bar _: Int,\n    baz _: String\n) -> Int {}"
        let options = FormatOptions(wrapArguments: .afterFirst, wrapParameters: .preserve)
        testFormatting(for: input, rule: .wrapArguments, options: options)
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
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    func testCorrectWrapIndentForNestedArguments() {
        let input = "foo(\nbar: (\nx: 0,\ny: 0\n),\nbaz: (\nx: 0,\ny: 0\n)\n)"
        let output = "foo(bar: (x: 0,\n          y: 0),\n    baz: (x: 0,\n          y: 0))"
        let options = FormatOptions(wrapArguments: .afterFirst)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    func testNoRemoveLinebreakAfterCommentInArguments() {
        let input = "a(b // comment\n)"
        let options = FormatOptions(wrapArguments: .afterFirst)
        testFormatting(for: input, rule: .wrapArguments, options: options)
    }

    func testNoRemoveLinebreakAfterCommentInArguments2() {
        let input = """
        foo(bar: bar
        //  ,
        //  baz: baz
            ) {}
        """
        let options = FormatOptions(wrapArguments: .afterFirst)
        testFormatting(for: input, rule: .wrapArguments, options: options, exclude: [.indent])
    }

    func testConsecutiveCodeCommentsNotIndented() {
        let input = """
        foo(bar: bar,
        //    bar,
        //    baz,
            quux)
        """
        let options = FormatOptions(wrapArguments: .afterFirst)
        testFormatting(for: input, rule: .wrapArguments, options: options)
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
        testFormatting(for: input, output, rule: .wrapArguments, options: options,
                       exclude: [.unusedArguments, .wrap])
    }

    // MARK: beforeFirst

    func testClosureInsideParensNotWrappedOntoNextLine() {
        let input = "foo({\n    bar()\n})"
        let options = FormatOptions(wrapArguments: .beforeFirst)
        testFormatting(for: input, rule: .wrapArguments, options: options,
                       exclude: [.trailingClosures])
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
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
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
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    // MARK: preserve

    func testWrapArgumentsDoesNotAffectLessThanOperator() {
        let input = """
        func foo() {
            guard foo < bar.count else { return nil }
        }
        """
        let options = FormatOptions(wrapArguments: .preserve)
        testFormatting(for: input, rule: .wrapArguments,
                       options: options, exclude: [.wrapConditionalBodies])
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
        testFormatting(for: input, rule: .wrapArguments, options: options,
                       exclude: [.redundantParens])
    }

    // MARK: beforeFirst, maxWidth : string interpolation

    func testNoWrapBeforeFirstArgumentInStringInterpolation() {
        let input = """
        "a very long string literal with \\(interpolation) inside"
        """
        let options = FormatOptions(wrapArguments: .beforeFirst,
                                    wrapParameters: .beforeFirst,
                                    maxWidth: 40)
        testFormatting(for: input, rule: .wrapArguments, options: options)
    }

    func testNoWrapBeforeFirstArgumentInStringInterpolation2() {
        let input = """
        "a very long string literal with \\(interpolation) inside"
        """
        let options = FormatOptions(wrapArguments: .beforeFirst,
                                    wrapParameters: .beforeFirst,
                                    maxWidth: 50)
        testFormatting(for: input, rule: .wrapArguments, options: options)
    }

    func testNoWrapBeforeFirstArgumentInStringInterpolation3() {
        let input = """
        "a very long string literal with \\(interpolated, variables) inside"
        """
        let options = FormatOptions(wrapArguments: .beforeFirst,
                                    wrapParameters: .beforeFirst,
                                    maxWidth: 40)
        testFormatting(for: input, rule: .wrapArguments, options: options)
    }

    func testNoWrapBeforeNestedFirstArgumentInStringInterpolation() {
        let input = """
        "a very long string literal with \\(foo(interpolated)) inside"
        """
        let options = FormatOptions(wrapArguments: .beforeFirst,
                                    wrapParameters: .beforeFirst,
                                    maxWidth: 45)
        testFormatting(for: input, rule: .wrapArguments, options: options)
    }

    func testNoWrapBeforeNestedFirstArgumentInStringInterpolation2() {
        let input = """
        "a very long string literal with \\(foo(interpolated, variables)) inside"
        """
        let options = FormatOptions(wrapArguments: .beforeFirst,
                                    wrapParameters: .beforeFirst,
                                    maxWidth: 45)
        testFormatting(for: input, rule: .wrapArguments, options: options)
    }

    func testWrapProtocolFuncParametersBeforeFirst() {
        let input = """
        protocol Foo {
            public func stringify<T>(_ value: T, label: String) -> (T, String)
        }
        """
        let output = """
        protocol Foo {
            public func stringify<T>(
                _ value: T,
                label: String
            ) -> (T, String)
        }
        """
        let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 30)
        testFormatting(for: input, output, rule: .wrapArguments,
                       options: options)
    }

    // MARK: afterFirst maxWidth : string interpolation

    func testNoWrapAfterFirstArgumentInStringInterpolation() {
        let input = """
        "a very long string literal with \\(interpolated) inside"
        """
        let options = FormatOptions(wrapArguments: .afterFirst,
                                    wrapParameters: .afterFirst,
                                    maxWidth: 46)
        testFormatting(for: input, rule: .wrapArguments, options: options)
    }

    func testNoWrapAfterFirstArgumentInStringInterpolation2() {
        let input = """
        "a very long string literal with \\(interpolated, variables) inside"
        """
        let options = FormatOptions(wrapArguments: .afterFirst,
                                    wrapParameters: .afterFirst,
                                    maxWidth: 50)
        testFormatting(for: input, rule: .wrapArguments, options: options)
    }

    func testNoWrapAfterNestedFirstArgumentInStringInterpolation() {
        let input = """
        "a very long string literal with \\(foo(interpolated, variables)) inside"
        """
        let options = FormatOptions(wrapArguments: .afterFirst,
                                    wrapParameters: .afterFirst,
                                    maxWidth: 55)
        testFormatting(for: input, rule: .wrapArguments, options: options)
    }

    // macros

    func testWrapMacroParametersBeforeFirst() {
        let input = """
        @freestanding(expression)
        public macro stringify<T>(_ value: T, label: String) -> (T, String)
        """
        let output = """
        @freestanding(expression)
        public macro stringify<T>(
            _ value: T,
            label: String
        ) -> (T, String)
        """
        let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 30)
        testFormatting(for: input, output, rule: .wrapArguments,
                       options: options)
    }

    // MARK: - wrapArguments --wrapCollections

    // MARK: beforeFirst

    func testNoDoubleSpaceAddedToWrappedArray() {
        let input = "[ foo,\n    bar ]"
        let output = "[\n    foo,\n    bar\n]"
        let options = FormatOptions(trailingCommas: false, wrapCollections: .beforeFirst)
        testFormatting(for: input, [output], rules: [.wrapArguments, .spaceInsideBrackets],
                       options: options)
    }

    func testTrailingCommasAddedToWrappedArray() {
        let input = "[foo,\n    bar]"
        let output = "[\n    foo,\n    bar,\n]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .beforeFirst)
        testFormatting(for: input, [output], rules: [.wrapArguments, .trailingCommas],
                       options: options)
    }

    func testTrailingCommasAddedToWrappedNestedDictionary() {
        let input = "[foo: [bar: baz,\n    bar2: baz2]]"
        let output = "[foo: [\n    bar: baz,\n    bar2: baz2,\n]]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .beforeFirst)
        testFormatting(for: input, [output], rules: [.wrapArguments, .trailingCommas],
                       options: options)
    }

    func testTrailingCommasAddedToSingleLineNestedDictionary() {
        let input = "[\n    foo: [bar: baz, bar2: baz2]]"
        let output = "[\n    foo: [bar: baz, bar2: baz2],\n]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .beforeFirst)
        testFormatting(for: input, [output], rules: [.wrapArguments, .trailingCommas],
                       options: options)
    }

    func testTrailingCommasAddedToWrappedNestedDictionaries() {
        let input = "[foo: [bar: baz,\n    bar2: baz2],\n    foo2: [bar: baz,\n    bar2: baz2]]"
        let output = "[\n    foo: [\n        bar: baz,\n        bar2: baz2,\n    ],\n    foo2: [\n        bar: baz,\n        bar2: baz2,\n    ],\n]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .beforeFirst)
        testFormatting(for: input, [output], rules: [.wrapArguments, .trailingCommas],
                       options: options)
    }

    func testSpaceAroundEnumValuesInArray() {
        let input = "[\n    .foo,\n    .bar, .baz,\n]"
        let options = FormatOptions(wrapCollections: .beforeFirst)
        testFormatting(for: input, rule: .wrapArguments, options: options)
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
                       rules: [.wrapArguments], options: options)
    }

    // MARK: afterFirst

    func testTrailingCommaRemovedInWrappedArray() {
        let input = "[\n    .foo,\n    .bar,\n    .baz,\n]"
        let output = "[.foo,\n .bar,\n .baz]"
        let options = FormatOptions(wrapCollections: .afterFirst)
        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    func testNoRemoveLinebreakAfterCommentInElements() {
        let input = "[a, // comment\n]"
        let options = FormatOptions(wrapCollections: .afterFirst)
        testFormatting(for: input, rule: .wrapArguments, options: options)
    }

    func testWrapCollectionsConsecutiveCodeCommentsNotIndented() {
        let input = """
        let a = [foo,
        //         bar,
        //         baz,
                 quux]
        """
        let options = FormatOptions(wrapCollections: .afterFirst)
        testFormatting(for: input, rule: .wrapArguments, options: options)
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
        testFormatting(for: input, rule: .wrapArguments, options: options)
    }

    // MARK: preserve

    func testNoBeforeFirstPreservedAndTrailingCommaIgnoredInMultilineNestedDictionary() {
        let input = "[foo: [bar: baz,\n    bar2: baz2]]"
        let output = "[foo: [bar: baz,\n       bar2: baz2]]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .preserve)
        testFormatting(for: input, [output], rules: [.wrapArguments, .trailingCommas],
                       options: options)
    }

    func testBeforeFirstPreservedAndTrailingCommaAddedInSingleLineNestedDictionary() {
        let input = "[\n    foo: [bar: baz, bar2: baz2]]"
        let output = "[\n    foo: [bar: baz, bar2: baz2],\n]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .preserve)
        testFormatting(for: input, [output], rules: [.wrapArguments, .trailingCommas],
                       options: options)
    }

    func testBeforeFirstPreservedAndTrailingCommaAddedInSingleLineNestedDictionaryWithOneNestedItem() {
        let input = "[\n    foo: [bar: baz]]"
        let output = "[\n    foo: [bar: baz],\n]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .preserve)
        testFormatting(for: input, [output], rules: [.wrapArguments, .trailingCommas],
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
                       rules: [.wrapArguments], options: options)
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
                       rules: [.wrapArguments], options: options)
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
                       rules: [.wrapArguments, .wrap], options: options)
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
                       rules: [.wrapArguments, .wrap], options: options)
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
                       rules: [.wrapArguments, .wrap], options: options)
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
        testFormatting(for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases])
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
        testFormatting(for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases])
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
        testFormatting(for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases])
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
        testFormatting(for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases])
    }

    func testWrapArguments_typealias_shorterThanMaxWidth() {
        let input = """
        typealias Dependencies = FooProviding & BarProviding & BaazProviding
        """

        let options = FormatOptions(wrapTypealiases: .afterFirst, maxWidth: 100)
        testFormatting(for: input, rule: .wrapArguments, options: options, exclude: [.sortTypealiases])
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
        testFormatting(for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases])
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
        testFormatting(for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases])
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
        testFormatting(for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases])
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
        testFormatting(for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases])
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
        testFormatting(for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases])
    }

    func testWrapArguments_typealias_singleTypePreserved() {
        let input = """
        typealias Dependencies = FooProviding
        """

        let options = FormatOptions(wrapTypealiases: .beforeFirst, maxWidth: 10)
        testFormatting(for: input, rule: .wrapArguments, options: options, exclude: [.wrap])
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
        testFormatting(for: input, rule: .wrapArguments, options: options, exclude: [.sortTypealiases])
    }

    func testWrapArguments_typealias_preservesCommentsAfterTypes() {
        let input = """
        typealias Dependencies
            = FooProviding // We use `FooProviding` because `FooFeature` depends on `Foo`
            & BarProviding // We use `BarProviding` because `BarFeature` depends on `Bar`
            & BaazProviding // We use `BaazProviding` because `BaazFeature` depends on `Baaz`
        """

        let options = FormatOptions(wrapTypealiases: .beforeFirst, maxWidth: 100)
        testFormatting(for: input, rule: .wrapArguments, options: options, exclude: [.sortTypealiases])
    }

    func testWrapArguments_typealias_withAssociatedType() {
        let input = """
        typealias Collections = Collection<Int> & Collection<String> & Collection<Double> & Collection<Float>
        """

        let output = """
        typealias Collections
            = Collection<Int>
            & Collection<String>
            & Collection<Double>
            & Collection<Float>
        """

        let options = FormatOptions(wrapTypealiases: .beforeFirst, maxWidth: 50)
        testFormatting(for: input, output, rule: .wrapArguments, options: options, exclude: [.sortTypealiases])
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
            closingParenPosition: .sameLine,
            wrapReturnType: .ifMultiline
        )

        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    func testWrapReturnAndEffectOnMultilineFunctionDeclaration() {
        let input = """
        func multilineFunction(
            foo _: String,
            bar _: String) async -> String {}
        """

        let output = """
        func multilineFunction(
            foo _: String,
            bar _: String)
            async -> String {}
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenPosition: .sameLine,
            wrapReturnType: .ifMultiline,
            wrapEffects: .ifMultiline
        )

        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    func testDoesntWrapReturnAndEffectOnSingleLineFunctionDeclaration() {
        let input = """
        func singleLineFunction() async throws -> String {}
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenPosition: .sameLine,
            wrapReturnType: .ifMultiline,
            wrapEffects: .ifMultiline
        )

        testFormatting(for: input, rule: .wrapArguments, options: options)
    }

    func testDoesntWrapReturnAndTypedEffectOnSingleLineFunctionDeclaration() {
        let input = """
        func singleLineFunction() async throws(Foo) -> String {}
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenPosition: .sameLine,
            wrapReturnType: .ifMultiline,
            wrapEffects: .ifMultiline
        )

        testFormatting(for: input, rule: .wrapArguments, options: options)
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
            closingParenPosition: .sameLine,
            wrapReturnType: .ifMultiline,
            wrapEffects: .ifMultiline
        )

        testFormatting(for: input, output, rule: .wrapArguments, options: options)
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
            closingParenPosition: .sameLine,
            wrapReturnType: .ifMultiline,
            wrapEffects: .never
        )

        testFormatting(for: input, output, rule: .wrapArguments, options: options)
    }

    func testWrapArgumentsDoesntBreakFunctionDeclaration_issue_1776() {
        let input = """
        struct OpenAPIController: RouteCollection {
            let info = InfoObject(title: "Swagger {{cookiecutter.service_name}} - OpenAPI",
                                  description: "{{cookiecutter.description}}",
                                  contact: .init(email: "{{cookiecutter.email}}"),
                                  version: Version(0, 0, 1))
            func boot(routes: RoutesBuilder) throws {
                routes.get("swagger", "swagger.json") {
                    $0.application.routes.openAPI(info: info)
                }
                .excludeFromOpenAPI()
            }
        }
        """

        let options = FormatOptions(wrapEffects: .never)
        testFormatting(for: input, rule: .wrapArguments, options: options, exclude: [.propertyTypes])
    }

    func testWrapEffectsNeverPreservesComments() {
        let input = """
        func multilineFunction(
            foo _: String,
            bar _: String)
            // Comment here between the parameters and effects
            async throws -> String {}
        """

        let options = FormatOptions(closingParenPosition: .sameLine, wrapEffects: .never)
        testFormatting(for: input, rule: .wrapArguments, options: options)
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
            closingParenPosition: .sameLine,
            wrapReturnType: .ifMultiline
        )

        testFormatting(
            for: input, output, rule: .wrapArguments, options: options,
            exclude: [.indent]
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
            closingParenPosition: .sameLine,
            wrapReturnType: .ifMultiline
        )

        testFormatting(
            for: input, output, rule: .wrapArguments, options: options,
            exclude: [.indent]
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
            closingParenPosition: .sameLine,
            wrapReturnType: .ifMultiline,
            wrapEffects: .ifMultiline
        )

        testFormatting(
            for: input, output, rule: .wrapArguments, options: options,
            exclude: [.indent]
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
            closingParenPosition: .sameLine,
            wrapReturnType: .ifMultiline
        )

        testFormatting(
            for: input, rule: .wrapArguments, options: options,
            exclude: [.indent]
        )
    }

    func testDoesntWrapReturnOnSingleLineFunctionDeclaration() {
        let input = """
        func multilineFunction(foo _: String, bar _: String) -> String {}
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenPosition: .sameLine,
            wrapReturnType: .ifMultiline
        )

        testFormatting(for: input, rule: .wrapArguments, options: options)
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
            closingParenPosition: .sameLine,
            wrapReturnType: .ifMultiline
        )

        testFormatting(for: input, rule: .wrapArguments, options: options)
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
            closingParenPosition: .sameLine,
            wrapReturnType: .ifMultiline
        )

        testFormatting(for: input, rule: .wrapArguments, options: options, exclude: [.propertyTypes])
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
            closingParenPosition: .sameLine
        )

        testFormatting(for: input, rule: .wrapArguments, options: options)
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
            for: input, rules: [.wrapArguments, .indent],
            options: FormatOptions(closingParenPosition: .sameLine, wrapConditions: .beforeFirst),
            exclude: [.propertyTypes]
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
            for: input, output, rule: .wrapArguments,
            options: FormatOptions(indent: "  ", wrapConditions: .beforeFirst),
            exclude: [.wrapConditionalBodies]
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
            for: input, rule: .wrapArguments,
            options: FormatOptions(indent: "  ", wrapConditions: .beforeFirst),
            exclude: [.elseOnSameLine, .wrapConditionalBodies]
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
            for: input, output, rule: .wrapArguments,
            options: FormatOptions(indent: "  ", wrapConditions: .afterFirst),
            exclude: [.wrapConditionalBodies]
        )
    }

    func testWrapConditionsAfterFirstWhenFirstLineIsComment() {
        let input = """
        guard
            // Apply this rule to any function-like declaration
            ["func", "init", "subscript"].contains(keyword.string),
            // Opaque generic parameter syntax is only supported in Swift 5.7+
            formatter.options.swiftVersion >= "5.7",
            // Validate that this is a generic method using angle bracket syntax,
            // and find the indices for all of the key tokens
            let paramListStartIndex = formatter.index(of: .startOfScope("("), after: keywordIndex),
            let paramListEndIndex = formatter.endOfScope(at: paramListStartIndex),
            let genericSignatureStartIndex = formatter.index(of: .startOfScope("<"), after: keywordIndex),
            let genericSignatureEndIndex = formatter.endOfScope(at: genericSignatureStartIndex),
            genericSignatureStartIndex < paramListStartIndex,
            genericSignatureEndIndex < paramListStartIndex,
            let openBraceIndex = formatter.index(of: .startOfScope("{"), after: paramListEndIndex),
            let closeBraceIndex = formatter.endOfScope(at: openBraceIndex)
        else { return }
        """
        let output = """
        guard // Apply this rule to any function-like declaration
            ["func", "init", "subscript"].contains(keyword.string),
            // Opaque generic parameter syntax is only supported in Swift 5.7+
            formatter.options.swiftVersion >= "5.7",
            // Validate that this is a generic method using angle bracket syntax,
            // and find the indices for all of the key tokens
            let paramListStartIndex = formatter.index(of: .startOfScope("("), after: keywordIndex),
            let paramListEndIndex = formatter.endOfScope(at: paramListStartIndex),
            let genericSignatureStartIndex = formatter.index(of: .startOfScope("<"), after: keywordIndex),
            let genericSignatureEndIndex = formatter.endOfScope(at: genericSignatureStartIndex),
            genericSignatureStartIndex < paramListStartIndex,
            genericSignatureEndIndex < paramListStartIndex,
            let openBraceIndex = formatter.index(of: .startOfScope("{"), after: paramListEndIndex),
            let closeBraceIndex = formatter.endOfScope(at: openBraceIndex)
        else { return }
        """
        testFormatting(
            for: input, [output], rules: [.wrapArguments, .indent],
            options: FormatOptions(wrapConditions: .afterFirst),
            exclude: [.wrapConditionalBodies]
        )
    }
}
