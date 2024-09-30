//
//  WrapMultilineStatementBracesTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/16/20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class WrapMultilineStatementBracesTests: XCTestCase {
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
        testFormatting(for: input, output, rule: .wrapMultilineStatementBraces)
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
        testFormatting(for: input, output, rule: .wrapMultilineStatementBraces,
                       exclude: [.wrapArguments, .unusedArguments])
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
        testFormatting(for: input, output, rule: .wrapMultilineStatementBraces,
                       exclude: [.wrapArguments, .unusedArguments])
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
        testFormatting(for: input, output, rule: .wrapMultilineStatementBraces)
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
        testFormatting(for: input, rule: .wrapMultilineStatementBraces)
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
        testFormatting(for: input, output, rule: .wrapMultilineStatementBraces)
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
        testFormatting(for: input, output, rule: .wrapMultilineStatementBraces,
                       exclude: [.braces, .elseOnSameLine])
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
        testFormatting(for: input, output, rule: .wrapMultilineStatementBraces)
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
        testFormatting(for: input, rule: .wrapMultilineStatementBraces, exclude: [.propertyType])
    }

    func testSingleLineIfBraceOnSameLine() {
        let input = """
        if firstConditional {
            print("statement body")
        }
        """
        testFormatting(for: input, rule: .wrapMultilineStatementBraces)
    }

    func testSingleLineGuardBrace() {
        let input = """
        guard firstConditional else {
            print("statement body")
        }
        """
        testFormatting(for: input, rule: .wrapMultilineStatementBraces)
    }

    func testGuardElseOnOwnLineBraceNotWrapped() {
        let input = """
        guard let foo = bar,
              bar == baz
        else {
            print("statement body")
        }
        """
        testFormatting(for: input, rule: .wrapMultilineStatementBraces)
    }

    func testMultilineGuardClosingBraceOnSameLine() {
        let input = """
        guard let foo = bar,
              let baz = quux else { return }
        """
        testFormatting(for: input, rule: .wrapMultilineStatementBraces,
                       exclude: [.wrapConditionalBodies])
    }

    func testMultilineGuardBraceOnSameLineAsElse() {
        let input = """
        guard let foo = bar,
              let baz = quux
        else {
            return
        }
        """
        testFormatting(for: input, rule: .wrapMultilineStatementBraces)
    }

    func testMultilineClassBrace() {
        let input = """
        class Foo: BarProtocol,
            BazProtocol
        {
            init() {}
        }
        """
        testFormatting(for: input, rule: .wrapMultilineStatementBraces)
    }

    func testMultilineClassBraceNotAppliedForXcodeIndentationMode() {
        let input = """
        class Foo: BarProtocol,
        BazProtocol {
            init() {}
        }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: .wrapMultilineStatementBraces, options: options)
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
            closingParenPosition: .sameLine
        )
        testFormatting(for: input, output, rule: .wrapMultilineStatementBraces,
                       options: options, exclude: [.indent])
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
            closingParenPosition: .sameLine
        )
        testFormatting(for: input, [output], rules: [
            .wrapMultilineStatementBraces,
            .indent, .braces,
        ], options: options)
    }

    func testMultilineBraceAppliedToGetterBody_wrapBeforeFirst() {
        let input = """
        var items = Adaptive<CGFloat>.adaptive(
            compact: Sizes.horizontalPaddingTiny_8,
            regular: Sizes.horizontalPaddingLarge_64) {
                didSet { updateAccessoryViewSpacing() }
        }
        """

        let output = """
        var items = Adaptive<CGFloat>.adaptive(
            compact: Sizes.horizontalPaddingTiny_8,
            regular: Sizes.horizontalPaddingLarge_64)
        {
            didSet { updateAccessoryViewSpacing() }
        }
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenPosition: .sameLine
        )
        testFormatting(for: input, [output], rules: [
            .wrapMultilineStatementBraces,
            .indent,
        ], options: options, exclude: [.propertyType])
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
            closingParenPosition: .sameLine
        )
        testFormatting(for: input, output, rule: .wrapMultilineStatementBraces,
                       options: options, exclude: [.indent])
    }

    func testMultilineBraceAppliedToGetterBody_wrapAfterFirst() {
        let input = """
        var items = Adaptive<CGFloat>.adaptive(compact: Sizes.horizontalPaddingTiny_8,
                                               regular: Sizes.horizontalPaddingLarge_64)
        {
            didSet { updateAccessoryViewSpacing() }
        }
        """

        let options = FormatOptions(
            wrapArguments: .afterFirst,
            closingParenPosition: .sameLine
        )
        testFormatting(for: input, [], rules: [
            .wrapMultilineStatementBraces,
            .wrapArguments,
        ], options: options, exclude: [.propertyType])
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
            closingParenPosition: .sameLine
        )
        testFormatting(for: input, rule: .wrapMultilineStatementBraces,
                       options: options, exclude: [.trailingClosures])
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
            closingParenPosition: .sameLine,
            wrapReturnType: .ifMultiline,
            wrapEffects: .ifMultiline
        )
        testFormatting(for: input, [output], rules: [
            .wrapMultilineStatementBraces,
            .wrapArguments,
        ], options: options)
    }

    func testWrapsMultilineStatementConsistentlyWithEffects() {
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
            two _: Int)
            async throws -> String
        {
            "one"
        }
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenPosition: .sameLine,
            wrapReturnType: .ifMultiline,
            wrapEffects: .ifMultiline
        )
        testFormatting(for: input, [output], rules: [
            .wrapMultilineStatementBraces,
            .wrapArguments,
        ], options: options)
    }

    func testWrapsMultilineStatementConsistentlyWithArrayReturnType() {
        let input = """
        public func aFunc(
            one _: Int,
            two _: Int) -> [String] {
            ["one"]
        }
        """

        let output = """
        public func aFunc(
            one _: Int,
            two _: Int)
            -> [String]
        {
            ["one"]
        }
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenPosition: .sameLine,
            wrapReturnType: .ifMultiline,
            wrapEffects: .ifMultiline
        )
        testFormatting(for: input, [output], rules: [
            .wrapMultilineStatementBraces,
            .wrapArguments,
        ], options: options)
    }

    func testWrapsMultilineStatementConsistentlyWithComplexGenericReturnType() {
        let input = """
        public func aFunc(
            one _: Int,
            two _: Int) throws -> some Collection<String> {
            ["one"]
        }
        """

        let output = """
        public func aFunc(
            one _: Int,
            two _: Int)
            throws -> some Collection<String>
        {
            ["one"]
        }
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenPosition: .sameLine,
            wrapReturnType: .ifMultiline,
            wrapEffects: .ifMultiline
        )
        testFormatting(for: input, [output], rules: [
            .wrapMultilineStatementBraces,
            .wrapArguments,
        ], options: options)
    }

    func testWrapsMultilineStatementConsistentlyWithTuple() {
        let input = """
        public func aFunc(
            one: Int,
            two: Int) -> (one: String, two: String) {
            (one: String(one), two: String(two))
        }
        """

        let output = """
        public func aFunc(
            one: Int,
            two: Int)
            -> (one: String, two: String)
        {
            (one: String(one), two: String(two))
        }
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenPosition: .sameLine,
            wrapReturnType: .ifMultiline,
            wrapEffects: .ifMultiline
        )
        testFormatting(for: input, [output], rules: [
            .wrapMultilineStatementBraces,
            .wrapArguments,
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
            closingParenPosition: .balanced
        )
        testFormatting(for: input, [output], rules: [
            .wrapMultilineStatementBraces,
            .wrapArguments,
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
            closingParenPosition: .balanced,
            wrapEffects: .never
        )
        testFormatting(for: input, [output], rules: [
            .wrapMultilineStatementBraces,
            .wrapArguments,
        ], options: options)
    }

    func testWrapsMultilineStatementConsistently2_withTypedEffects() {
        let input = """
        func aFunc(
            one _: Int,
            two _: Int) async throws(Foo) -> String {
            "one"
        }
        """

        let output = """
        func aFunc(
            one _: Int,
            two _: Int
        ) async throws(Foo) -> String {
            "one"
        }
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenPosition: .balanced,
            wrapEffects: .never
        )
        testFormatting(for: input, [output], rules: [
            .wrapMultilineStatementBraces,
            .wrapArguments,
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
            closingParenPosition: .balanced
        )

        testFormatting(for: input, [], rules: [
            .wrapMultilineStatementBraces,
            .wrapArguments,
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
            closingParenPosition: .sameLine
        )
        testFormatting(for: input, [output], rules: [
            .wrapMultilineStatementBraces,
            .wrapArguments,
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
            closingParenPosition: .sameLine
        )
        testFormatting(for: input, rule: .wrapMultilineStatementBraces,
                       options: options, exclude: [.trailingClosures])
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
            closingParenPosition: .sameLine
        )
        testFormatting(for: input, rules: [.wrapMultilineStatementBraces, .wrap],
                       options: options, exclude: [.indent, .redundantClosure, .wrapConditionalBodies])
    }

    func testWrapMultilineStatementBraceAfterWhereClauseWithTuple() {
        let input = """
        extension Foo {
            public func testWithWhereClause<A, B, Outcome>(
                a: A,
                b: B)
                -> Outcome where
                Outcome == (A, B)
            {
                return (a, b)
            }
        }
        """

        let options = FormatOptions(
            wrapArguments: .beforeFirst,
            closingParenPosition: .sameLine
        )
        testFormatting(for: input, rules: [.wrapMultilineStatementBraces, .braces], options: options)
    }
}
