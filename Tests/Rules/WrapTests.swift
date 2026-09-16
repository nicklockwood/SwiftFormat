//
//  WrapTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class WrapTests: XCTestCase {
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
        testFormatting(for: input, output, rule: .wrap, options: options)
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
        testFormatting(for: input, [output, output2], rules: [.wrap], options: options)
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
        testFormatting(for: input, [output, output2], rules: [.wrap], options: options, exclude: [.wrapMultilineStatementBraces])
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
        testFormatting(for: input, [output, output2], rules: [.wrap], options: options)
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
        testFormatting(for: input, [output, output2], rules: [.wrap], options: options)
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
        testFormatting(for: input, [output, output2], rules: [.wrap], options: options)
    }

    func testWrapClosure3() {
        let input = """
        let foo = bar { $0.baz }
        """
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
        testFormatting(for: input, [output, output2], rules: [.wrap], options: options)
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
        testFormatting(for: input, output, rule: .wrap, options: options, exclude: [.wrapMultilineStatementBraces])
    }

    func testWrapGenericRequirementsInExtension() {
        let input = """
        extension Combined: MirrorableAtomicTransition where TransitionA: MirrorableAtomicTransition, TransitionB: MirrorableAtomicTransition {}
        """
        let output = """
        extension Combined: MirrorableAtomicTransition where
            TransitionA: MirrorableAtomicTransition,
            TransitionB: MirrorableAtomicTransition {}
        """
        let options = FormatOptions(maxWidth: 80)
        testFormatting(for: input, output, rule: .wrap, options: options)
    }

    func testWrapGenericRequirementsBeforeMultilineBodyBrace() {
        let input = """
        extension Combined: MirrorableAtomicTransition where TransitionA: MirrorableAtomicTransition, TransitionB: MirrorableAtomicTransition {
            typealias Value = (TransitionA, TransitionB)
        }
        """
        let output = """
        extension Combined: MirrorableAtomicTransition where
            TransitionA: MirrorableAtomicTransition,
            TransitionB: MirrorableAtomicTransition
        {
            typealias Value = (TransitionA, TransitionB)
        }
        """
        let options = FormatOptions(maxWidth: 80)
        testFormatting(for: input, [output], rules: [.wrap, .wrapMultilineStatementBraces], options: options)
    }

    func testCompletePartialGenericRequirementWrappingWithComment() {
        let input = """
        extension Combined: MirrorableAtomicTransition where TransitionA: MirrorableAtomicTransition, // first transition
            TransitionB: MirrorableAtomicTransition {
            typealias Value = (TransitionA, TransitionB)
        }
        """
        let output = """
        extension Combined: MirrorableAtomicTransition where
            TransitionA: MirrorableAtomicTransition, // first transition
            TransitionB: MirrorableAtomicTransition {
            typealias Value = (TransitionA, TransitionB)
        }
        """
        let options = FormatOptions(maxWidth: 100)
        testFormatting(for: input, output, rule: .wrap, options: options, exclude: [.wrapMultilineStatementBraces])
    }

    func testCompleteLeadingCommaGenericRequirementWrapping() {
        let input = """
        extension Foo where T: ProtocolOne
            , U: ProtocolTwo {
            func foo() {}
        }
        """
        let output = """
        extension Foo where
            T: ProtocolOne,
            U: ProtocolTwo {
            func foo() {}
        }
        """
        let options = FormatOptions(maxWidth: 80)
        testFormatting(for: input, output, rule: .wrap, options: options,
                       exclude: [.wrapMultilineStatementBraces])
    }

    func testPreserveLeadingCommaSeparatedFromPreviousRequirementByComment() {
        let input = """
        extension Foo where T: ProtocolOne
            // Keep this comment with the next requirement.
            , U: ProtocolTwo {
            func foo() {}
        }
        """
        let output = """
        extension Foo where
            T: ProtocolOne
            // Keep this comment with the next requirement.
            , U: ProtocolTwo {
            func foo() {}
        }
        """
        let options = FormatOptions(maxWidth: 80)
        testFormatting(for: input, output, rule: .wrap, options: options,
                       exclude: [.consecutiveSpaces, .leadingDelimiters, .wrapMultilineStatementBraces])
    }

    func testWrapGenericRequirementsWhenContinuationLineExceedsMaxWidth() throws {
        let input = """
        extension Foo where T == Result<
            ATypeNameThatExceedsTheConfiguredMaximumWidth,
            Error
        >, U: ProtocolOne {}
        """
        let options = FormatOptions(maxWidth: 40)
        let output = try format(input, rules: [.wrap], options: options).output
        XCTAssertTrue(output.contains("where\n    T =="))
        XCTAssertTrue(output.contains("\n    U: ProtocolOne"))
    }

    func testWrapGenericRequirementsInFunctionLikeDeclarations() {
        let input = """
        func resolve<T, U>() where T == Result<Value, Error>, U == (Value, Error) {}
        init?<T, U>() where T: VeryLongProtocolName, U: AnotherLongProtocolName {}
        init!<T, U>() where T: VeryLongProtocolName, U: AnotherLongProtocolName {}
        subscript<T, U>(_: T, _: U) -> Value where T: VeryLongProtocolName, U: AnotherLongProtocolName {}
        """
        let output = """
        func resolve<T, U>() where
            T == Result<Value, Error>,
            U == (Value, Error) {}
        init?<T, U>() where
            T: VeryLongProtocolName,
            U: AnotherLongProtocolName {}
        init!<T, U>() where
            T: VeryLongProtocolName,
            U: AnotherLongProtocolName {}
        subscript<T, U>(_: T, _: U) -> Value where
            T: VeryLongProtocolName,
            U: AnotherLongProtocolName {}
        """
        let options = FormatOptions(maxWidth: 70)
        testFormatting(for: input, output, rule: .wrap, options: options)
    }

    func testWrapGenericRequirementsInLocalFunction() {
        let input = """
        func outer() {
            func inner<T, U>() where T: VeryLongProtocolName, U: AnotherLongProtocolName {}
        }
        """
        let output = """
        func outer() {
            func inner<T, U>() where
                T: VeryLongProtocolName,
                U: AnotherLongProtocolName {}
        }
        """
        let options = FormatOptions(maxWidth: 70)
        testFormatting(for: input, output, rule: .wrap, options: options,
                       exclude: [.simplifyGenericConstraints, .unusedArguments])
    }

    func testWrapGenericRequirementsWhenDeclarationStartsOutsideFormattingRange() throws {
        let input = """
        extension Bar where V: VeryLongProtocolName, W: AnotherLongProtocolName {}
        extension Foo
        where T: VeryLongProtocolName, U: AnotherLongProtocolName {}
        """
        let output = """
        extension Bar where V: VeryLongProtocolName, W: AnotherLongProtocolName {}
        extension Foo
        where
            T: VeryLongProtocolName,
            U: AnotherLongProtocolName {}
        """
        let options = FormatOptions(maxWidth: 40)
        XCTAssertEqual(
            try format(input, rules: [.wrap], options: options, lineRange: 3 ... 3).output,
            output
        )
    }

    func testWrapGenericRequirementsWithoutSpaceAfterComma() {
        let input = """
        extension Combined: MirrorableAtomicTransition where TransitionA: MirrorableAtomicTransition,TransitionB: MirrorableAtomicTransition {}
        """
        let output = """
        extension Combined: MirrorableAtomicTransition where
            TransitionA: MirrorableAtomicTransition,
            TransitionB: MirrorableAtomicTransition {}
        """
        let options = FormatOptions(maxWidth: 80)
        testFormatting(for: input, output, rule: .wrap, options: options)
    }

    func testWrapGenericRequirementsInAssociatedType() {
        let input = """
        protocol Foo {
            associatedtype Value where Value: VeryLongProtocolName, Value: AnotherLongProtocolName
        }
        """
        let output = """
        protocol Foo {
            associatedtype Value where
                Value: VeryLongProtocolName,
                Value: AnotherLongProtocolName
        }
        """
        let options = FormatOptions(maxWidth: 70)
        testFormatting(for: input, output, rule: .wrap, options: options)
    }

    func testNoWrapGenericRequirementsBelowMaxWidth() {
        let input = """
        extension Foo where Bar: Baaz, Quux: Quuz {
            func foo() {}
        }
        """
        let options = FormatOptions(maxWidth: 80)
        testFormatting(for: input, rule: .wrap, options: options)
    }

    func testNoWrapGenericRequirementsWhenMultilineDeclarationIsBelowMaxWidth() {
        let input = """
        func resolve<T, U>(
            value: T,
            fallback: U
        ) where T: ProtocolOne, U: ProtocolTwo {}
        """
        let options = FormatOptions(maxWidth: 50)
        testFormatting(for: input, rule: .wrap, options: options,
                       exclude: [.simplifyGenericConstraints, .unusedArguments])
    }

    func testNoWrapGenericRequirementsWhenRuleDisabled() {
        let input = """
        // swiftformat:disable:next wrap
        extension Combined: MirrorableAtomicTransition where TransitionA: MirrorableAtomicTransition, TransitionB: MirrorableAtomicTransition {}
        """
        let options = FormatOptions(maxWidth: 80)
        testFormatting(for: input, rule: .wrap, options: options)
    }

    func testGenericRequirementsRespectMaxWidthDirectives() {
        let input = """
        // swiftformat:options:next --max-width 200
        extension Combined: MirrorableAtomicTransition where TransitionA: MirrorableAtomicTransition, TransitionB: MirrorableAtomicTransition {}
        // swiftformat:options:next --max-width 80
        extension Wrapped: MirrorableAtomicTransition where TransitionA: MirrorableAtomicTransition, TransitionB: MirrorableAtomicTransition {}
        """
        let output = """
        // swiftformat:options:next --max-width 200
        extension Combined: MirrorableAtomicTransition where TransitionA: MirrorableAtomicTransition, TransitionB: MirrorableAtomicTransition {}
        // swiftformat:options:next --max-width 80
        extension Wrapped: MirrorableAtomicTransition where
            TransitionA: MirrorableAtomicTransition,
            TransitionB: MirrorableAtomicTransition {}
        """
        let options = FormatOptions(maxWidth: 120)
        testFormatting(for: input, output, rule: .wrap, options: options)
    }

    func testNoWrapGenericRequirementsAcrossRuleDirective() {
        let input = """
        extension Foo where // swiftformat:disable:next wrap
            T: VeryLongProtocolName, U: AnotherLongProtocolName {
            func foo() {}
        }
        """
        let options = FormatOptions(maxWidth: 40)
        testFormatting(for: input, rule: .wrap, options: options,
                       exclude: [.wrapMultilineStatementBraces])
    }

    func testWrapGenericRequirementsAcrossUnrelatedRuleDirective() {
        let input = """
        extension Foo where // swiftformat:disable:next redundantSelf
            T: VeryLongProtocolName, U: AnotherLongProtocolName {
            func foo() {}
        }
        """
        let output = """
        extension Foo where // swiftformat:disable:next redundantSelf
            T: VeryLongProtocolName,
            U: AnotherLongProtocolName {
            func foo() {}
        }
        """
        let options = FormatOptions(maxWidth: 40)
        testFormatting(for: input, output, rule: .wrap, options: options,
                       exclude: [.wrapMultilineStatementBraces])
    }

    func testNoGenericRequirementWrappingInTypeAttribute() throws {
        let input = """
        @Marker({
            for value in values where predicate(value) {}
        })
        struct Example {}
        """
        let output = """
        @Marker({
            for value in
                values
                where predicate(
                    value
                ) {}
        })
        struct Example {}
        """
        let options = FormatOptions(maxWidth: 20)
        XCTAssertEqual(try format(input, rules: [.wrap], options: options).output, output)
    }

    func testNoGenericRequirementWrappingForNonDeclarationWhere() throws {
        let input = """
        struct Marker {}
        for value in allAvailableValues where predicate(value, someVeryLongContextName) {}
        switch result {
        case let .value(lhs, rhs) where predicate(lhs, rhs): break
        }
        let match = allAvailableValues.first(where: { predicate($0, someVeryLongContextName) })
        """
        let expected = """
        struct Marker {}
        for value in allAvailableValues where predicate(
            value,
            someVeryLongContextName
        ) {}
        switch result {
        case let .value(lhs, rhs) where predicate(
            lhs,
            rhs
        ): break
        }
        let match = allAvailableValues
            .first(where: { predicate(
                $0,
                someVeryLongContextName
            ) })
        """
        let options = FormatOptions(maxWidth: 50)
        let output = try format(input, rules: [.wrap], options: options)
        XCTAssertEqual(output.output, expected)
    }

    func testNoGenericRequirementWrappingAfterPreviousDeclaration() throws {
        let input = """
        struct Marker {}
        for value in allAvailableValues where predicateOne(value), predicateTwoWithLongName(value) {}
        """
        let expected = """
        struct Marker {}
        for value in allAvailableValues where predicateOne(value),
            predicateTwoWithLongName(value) {}
        """
        let options = FormatOptions(maxWidth: 70)
        let output = try format(input, rules: [.wrap], options: options)
        XCTAssertEqual(output.output, expected)
    }

    func testNoGenericRequirementWrappingAfterInitializerCall() throws {
        let input = """
        for value in Values.init() where predicateOne(value), predicateTwoWithLongName(value) {}
        """
        let expected = """
        for value in Values.init() where predicateOne(value),
            predicateTwoWithLongName(value) {}
        """
        let options = FormatOptions(maxWidth: 70)
        let output = try format(input, rules: [.wrap], options: options)
        XCTAssertEqual(output.output, expected)
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
        testFormatting(for: input, [output, output2], rules: [.wrap], options: options, exclude: [.wrapMultilineStatementBraces])
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
        testFormatting(for: input, output, rule: .wrap, options: options, exclude: [.wrapMultilineStatementBraces])
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
        testFormatting(for: input, [output, output2], rules: [.wrap], options: options, exclude: [.wrapMultilineStatementBraces])
    }

    func testWrapFunctionIfReturnTypeExceedsMaxWidth2WithXcodeIndentation2() {
        let input = """
        func testFunc() throws(Foo) -> (ReturnType, ReturnType2) {
            doSomething()
        }
        """
        let output = """
        func testFunc() throws(Foo)
            -> (ReturnType, ReturnType2) {
            doSomething()
        }
        """
        let output2 = """
        func testFunc() throws(Foo)
        -> (ReturnType, ReturnType2) {
            doSomething()
        }
        """
        let options = FormatOptions(xcodeIndentation: true, maxWidth: 35)
        testFormatting(for: input, [output, output2], rules: [.wrap], options: options, exclude: [.wrapMultilineStatementBraces])
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
        testFormatting(for: input, output, rule: .wrap, options: options, exclude: [.wrapMultilineStatementBraces])
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
        testFormatting(for: input, [output, output2], rules: [.wrap], options: options, exclude: [.wrapMultilineStatementBraces])
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
        testFormatting(for: input, output, rule: .wrap, options: options, exclude: [.wrapMultilineStatementBraces])
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
        testFormatting(for: input, [output, output2], rules: [.wrap], options: options, exclude: [.wrapMultilineStatementBraces])
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
        testFormatting(for: input, output, rule: .wrap, options: options)
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
        testFormatting(for: input, output, rule: .wrap, options: options)
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
        testFormatting(for: input, output, rule: .wrap, options: options, exclude: [.wrapMultilineStatementBraces])
    }

    func testWrapTypedThrowingFunctionIfReturnTypeExceedsMaxWidth() {
        let input = """
        func testFunc(_: () -> Void) throws(Foo) -> (Bool, String) -> String? {
            doSomething()
        }
        """
        let output = """
        func testFunc(_: () -> Void) throws(Foo)
            -> (Bool, String) -> String? {
            doSomething()
        }
        """
        let options = FormatOptions(maxWidth: 42)
        testFormatting(for: input, output, rule: .wrap, options: options, exclude: [.wrapMultilineStatementBraces])
    }

    func testNoWrapInterpolatedStringLiteral() {
        let input = """
        "a very long \\(string) literal"
        """
        let options = FormatOptions(maxWidth: 20)
        testFormatting(for: input, rule: .wrap, options: options)
    }

    func testNoWrapAtUnspacedOperator() {
        let input = """
        let foo = bar+baz+quux
        """
        let output = """
        let foo =
            bar+baz+quux
        """
        let options = FormatOptions(maxWidth: 15)
        testFormatting(for: input, output, rule: .wrap, options: options,
                       exclude: [.spaceAroundOperators])
    }

    func testNoWrapAtUnspacedEquals() {
        let input = """
        let foo=bar+baz+quux
        """
        let options = FormatOptions(maxWidth: 15)
        testFormatting(for: input, rule: .wrap, options: options,
                       exclude: [.spaceAroundOperators])
    }

    func testNoWrapSingleParameter() {
        let input = """
        let fooBar = try unkeyedContainer.decode(FooBar.self)
        """
        let output = """
        let fooBar = try unkeyedContainer
            .decode(FooBar.self)
        """
        let options = FormatOptions(maxWidth: 50)
        testFormatting(for: input, output, rule: .wrap, options: options)
    }

    func testWrapSingleParameter() {
        let input = """
        let fooBar = try unkeyedContainer.decode(FooBar.self)
        """
        let output = """
        let fooBar = try unkeyedContainer.decode(
            FooBar.self
        )
        """
        let options = FormatOptions(maxWidth: 50, noWrapOperators: [".", "="])
        testFormatting(for: input, output, rule: .wrap, options: options)
    }

    func testWrapFunctionArrow() {
        let input = """
        func foo() -> Int {}
        """
        let output = """
        func foo()
            -> Int {}
        """
        let options = FormatOptions(maxWidth: 14)
        testFormatting(for: input, output, rule: .wrap, options: options)
    }

    func testNoWrapFunctionArrow() {
        let input = """
        func foo() -> Int {}
        """
        let output = """
        func foo(
        ) -> Int {}
        """
        let options = FormatOptions(maxWidth: 14, noWrapOperators: ["->"])
        testFormatting(for: input, output, rule: .wrap, options: options)
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
        testFormatting(for: input, output, rule: .wrap, options: options,
                       exclude: [.unusedArguments])
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
        testFormatting(for: input, output, rule: .wrap, options: options,
                       exclude: [.indent, .wrapArguments])
    }

    func testWrapColorLiteral() {
        let input = """
        button.setTitleColor(#colorLiteral(red: 0.2392156863, green: 0.6470588235, blue: 0.3647058824, alpha: 1), for: .normal)
        """
        let options = FormatOptions(maxWidth: 80, assetLiteralWidth: .visualWidth)
        testFormatting(for: input, rule: .wrap, options: options)
    }

    func testWrapImageLiteral() {
        let input = """
        if let image = #imageLiteral(resourceName: \"abc.png\") {}
        """
        let options = FormatOptions(maxWidth: 40, assetLiteralWidth: .visualWidth)
        testFormatting(for: input, rule: .wrap, options: options)
    }

    func testNoWrapBeforeFirstArgumentInSingleLineStringInterpolation() {
        let input = """
        "a very long string literal with \\(interpolation) inside"
        """
        let options = FormatOptions(maxWidth: 40)
        testFormatting(for: input, rule: .wrap, options: options)
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
        let options = FormatOptions(wrapStringInterpolation: true, maxWidth: 40)
        testFormatting(for: input, output, rule: .wrap, options: options)
    }

    func testPreserveMultiLineStringInterpolationWrapAfterFirst() {
        let input = """
        \"""
        a very long string literal with \\(interpolation) inside
        \"""
        """
        let options = FormatOptions(wrapArguments: .afterFirst, wrapStringInterpolation: false, maxWidth: 40)
        testFormatting(for: input, rule: .wrap, options: options)
    }

    func testPreserveMultiLineStringInterpolationWrapBeforeFirst() {
        let input = """
        \"""
        a very long string literal with \\(interpolation) inside
        \"""
        """
        let options = FormatOptions(wrapArguments: .beforeFirst, wrapStringInterpolation: false, maxWidth: 40)
        testFormatting(for: input, rule: .wrap, options: options)
    }

    func testPreserveCustomMultiLineStringInterpolationWrapBeforeFirst() {
        let input = #"""
        """
        \(raw: isPublic ? "public " : "")lazy var \(raw: name.trimmed.description): \(raw: typeName)<\(raw: genericName),\(returnType)> = {
        """
        """#
        let options = FormatOptions(wrapArguments: .beforeFirst, wrapStringInterpolation: false, maxWidth: 40)
        testFormatting(for: input, rule: .wrap, options: options)
    }

    // ternary expressions

    func testWrapSimpleTernaryOperator() {
        let input = """
        let foo = fooCondition ? longValueThatContainsFoo(bar) : longValueThatContainsBar(baaz)
        """

        let output = """
        let foo = fooCondition
            ? longValueThatContainsFoo(bar)
            : longValueThatContainsBar(baaz)
        """

        let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 40)
        testFormatting(for: input, [output], rules: [.wrap, .wrapArguments], options: options)
    }

    func testRewrapsSimpleTernaryOperator() {
        let input = """
        let foo = fooCondition ? longValueThatContainsFoo(bar) :
            longValueThatContainsBar(baaz)
        """

        let output = """
        let foo = fooCondition
            ? longValueThatContainsFoo(bar)
            : longValueThatContainsBar(baaz)
        """

        let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 40)
        testFormatting(for: input, [output], rules: [.wrap, .wrapArguments], options: options)
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
        testFormatting(for: input, output, rule: .wrap, options: options)
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
        testFormatting(for: input, output, rule: .wrap, options: options)
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
        testFormatting(for: input, output, rule: .wrap, options: options)
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
        testFormatting(for: input, output, rule: .wrap, options: options)
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
        testFormatting(for: input, output, rule: .wrap, options: options)
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
        testFormatting(for: input, rule: .wrap, options: options)
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
        testFormatting(for: input, rule: .wrap, options: options)
    }

    func testNoWrapTernaryInsideStringLiteral() {
        let input = """
        "\\(true ? "Some string literal" : "Some other string")"
        """
        let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 50)
        testFormatting(for: input, rule: .wrap, options: options)
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
        let options = FormatOptions(wrapTernaryOperators: .beforeOperators, wrapStringInterpolation: true, maxWidth: 50)
        testFormatting(for: input, output, rule: .wrap, options: options)
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
        let rules: [FormatRule] = [.wrap, .wrapArguments]
        XCTAssertNoThrow(try format(input, rules: rules, options: options))
    }

    func testErrorNotReportedOnBlankLineAfterWrap() throws {
        let input = """
        [
            abagdiasiudbaisndoanosdasdasdasdasdnaosnooanso(),

            bar(),
        ]
        """
        let options = FormatOptions(truncateBlankLines: false, maxWidth: 40)
        let changes = try lint(input, rules: [.wrap, .indent], options: options)
        XCTAssertEqual(changes, [.init(line: 2, rule: .wrap, filePath: nil, isMove: false)])
    }

    func testNoReportIndentAsWrap() throws {
        let input = """
        let package = Package(
            name: "ExampleApp",
            products: [
                .executable(
                    name: "ExampleApp",
                    targets: ["ExampleApp"]
                ),
            ],
            dependencies: [
                .package(url: "https://example.com/package.swift", from: "1.0"),
                // Plugins:
                .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.54.5"),
             ]
        )
        """
        let options = FormatOptions(truncateBlankLines: false, maxWidth: 120)
        let changes = try lint(input, rules: [.wrap, .indent], options: options)
        XCTAssertEqual(changes, [.init(line: 13, rule: .indent, filePath: nil, isMove: false)])
    }

    func testKeepTrailingCommentWithLine() {
        // https://github.com/nicklockwood/SwiftFormat/issues/2261
        let input = """
        [
            item1, // Comment 1
            item2, // Comment 2
            item3 // Comment 3
        ]
        """

        let options = FormatOptions(maxWidth: 20)
        testFormatting(for: input, rule: .wrap, options: options,
                       exclude: [.trailingCommas, .wrapSingleLineComments])
    }

    func testKeepTrailingCommentWithLine2() {
        let input = """
        [
            item1, // Comment 1
            item2, // Comment 2
            item3 // Comment 3
        ]
        """

        let output = """
        [
            item1, // Comment
            // 1
            item2, // Comment
            // 2
            item3 // Comment
            // 3
        ]
        """

        testFormatting(for: input, [output],
                       rules: [.wrap, .wrapSingleLineComments],
                       options: FormatOptions(maxWidth: 20),
                       exclude: [.trailingCommas])
    }

    func testWrapDoubleColonBreaksBeforeOperator() {
        let input = """
        NationalAeronauticsAndSpaceAdministration::RocketEngine
        """
        let output = """
        NationalAeronauticsAndSpaceAdministration
            ::RocketEngine
        """
        let options = FormatOptions(maxWidth: 50)
        testFormatting(for: input, output, rule: .wrap, options: options)
    }

    func testWrapDoubleColonWithSpacesBreaksBeforeOperator() {
        let input = """
        NationalAeronauticsAndSpaceAdministration :: RocketEngine
        """
        let output = """
        NationalAeronauticsAndSpaceAdministration
            :: RocketEngine
        """
        let output2 = """
        NationalAeronauticsAndSpaceAdministration
            ::RocketEngine
        """
        let options = FormatOptions(maxWidth: 50)
        testFormatting(for: input, [output, output2], rules: [.wrap], options: options)
    }

    func testNoWrapEmptyFuncParens() {
        let input = """
        func aVeryLongFunctionNameThatExceedsTheMaxWidthLimit() {
            print("hello")
        }
        """
        let options = FormatOptions(maxWidth: 40)
        testFormatting(for: input, rule: .wrap, options: options)
    }

    func testNoWrapEmptyFuncParensSingleLine() {
        let input = """
        func aVeryLongFunctionNameThatExceedsTheMaxWidthLimit() {}
        """
        let options = FormatOptions(maxWidth: 40)
        testFormatting(for: input, rule: .wrap, options: options)
    }

    func testUnwrapAlreadyWrappedEmptyFuncParens() {
        let input = """
        func aVeryLongFunctionNameThatExceedsTheMaxWidthLimit(
        ) {
            print("hello")
        }
        """
        let output = """
        func aVeryLongFunctionNameThatExceedsTheMaxWidthLimit() {
            print("hello")
        }
        """
        let options = FormatOptions(maxWidth: 40)
        testFormatting(for: input, output, rule: .wrap, options: options)
    }
}
