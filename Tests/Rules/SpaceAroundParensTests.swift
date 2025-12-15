//
//  SpaceAroundParensTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 8/22/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class SpaceAroundParensTests: XCTestCase {
    func testSpaceAfterSet() {
        let input = """
        private(set)var foo: Int
        """
        let output = """
        private(set) var foo: Int
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenParenAndClass() {
        let input = """
        @objc(XYZFoo)class foo
        """
        let output = """
        @objc(XYZFoo) class foo
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenConventionAndBlock() {
        let input = """
        @convention(block)() -> Void
        """
        let output = """
        @convention(block) () -> Void
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenConventionAndEscaping() {
        let input = """
        @convention(block)@escaping () -> Void
        """
        let output = """
        @convention(block) @escaping () -> Void
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenAutoclosureEscapingAndBlock() { // Swift 2.3 only
        let input = """
        @autoclosure(escaping)() -> Void
        """
        let output = """
        @autoclosure(escaping) () -> Void
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenSendableAndBlock() {
        let input = """
        @Sendable (Action) -> Void
        """
        testFormatting(for: input, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenMainActorAndBlock() {
        let input = """
        @MainActor (Action) -> Void
        """
        testFormatting(for: input, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenMainActorAndBlock2() {
        let input = """
        @MainActor (@MainActor (Action) -> Void) async -> Void
        """
        testFormatting(for: input, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenMainActorAndClosureParams() {
        let input = """
        { @MainActor (foo: Int) in foo }
        """
        testFormatting(for: input, rule: .spaceAroundParens)
    }

    func testSpaceBetweenUncheckedAndSendable() {
        let input = """
        enum Foo: @unchecked Sendable {
            case bar
        }
        """
        testFormatting(for: input, rule: .spaceAroundParens)
    }

    func testSpaceBetweenParenAndAs() {
        let input = """
        (foo.bar) as? String
        """
        testFormatting(for: input, rule: .spaceAroundParens, exclude: [.redundantParens])
    }

    func testNoSpaceAfterParenAtEndOfFile() {
        let input = """
        (foo.bar)
        """
        testFormatting(for: input, rule: .spaceAroundParens, exclude: [.redundantParens])
    }

    func testSpaceBetweenParenAndFoo() {
        let input = """
        func foo ()
        """
        let output = """
        func foo()
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testSpaceBetweenParenAndAny() {
        let input = """
        func any ()
        """
        let output = """
        func any()
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testSpaceBetweenParenAndAnyType() {
        let input = """
        let foo: any(A & B).Type
        """
        let output = """
        let foo: any (A & B).Type
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testSpaceBetweenParenAndSomeType() {
        let input = """
        func foo() -> some(A & B).Type
        """
        let output = """
        func foo() -> some (A & B).Type
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testNoSpaceBetweenParenAndInit() {
        let input = """
        init ()
        """
        let output = """
        init()
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testNoSpaceBetweenObjcAndSelector() {
        let input = """
        @objc (XYZFoo) class foo
        """
        let output = """
        @objc(XYZFoo) class foo
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testNoSpaceBetweenHashSelectorAndBrace() {
        let input = """
        #selector(foo)
        """
        testFormatting(for: input, rule: .spaceAroundParens)
    }

    func testNoSpaceBetweenHashKeyPathAndBrace() {
        let input = """
        #keyPath (foo.bar)
        """
        let output = """
        #keyPath(foo.bar)
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testNoSpaceBetweenHashAvailableAndBrace() {
        let input = """
        #available (iOS 9.0, *)
        """
        let output = """
        #available(iOS 9.0, *)
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testNoSpaceBetweenPrivateAndSet() {
        let input = """
        private (set) var foo: Int
        """
        let output = """
        private(set) var foo: Int
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testSpaceBetweenLetAndTuple() {
        let input = """
        if let (foo, bar) = baz {}
        """
        testFormatting(for: input, rule: .spaceAroundParens)
    }

    func testSpaceBetweenIfAndCondition() {
        let input = """
        if(a || b) == true {}
        """
        let output = """
        if (a || b) == true {}
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testNoSpaceBetweenArrayLiteralAndParen() {
        let input = """
        [String] ()
        """
        let output = """
        [String]()
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenCaptureListAndArguments() {
        let input = """
        { [weak self](foo) in print(foo) }
        """
        let output = """
        { [weak self] (foo) in print(foo) }
        """
        testFormatting(for: input, output, rule: .spaceAroundParens, exclude: [.redundantParens])
    }

    func testAddSpaceBetweenCaptureListAndArguments2() {
        let input = """
        { [weak self]() -> Void in }
        """
        let output = """
        { [weak self] () -> Void in }
        """
        testFormatting(for: input, output, rule: .spaceAroundParens, exclude: [.redundantVoidReturnType])
    }

    func testAddSpaceBetweenCaptureListAndArguments3() {
        let input = """
        { [weak self]() throws -> Void in }
        """
        let output = """
        { [weak self] () throws -> Void in }
        """
        testFormatting(for: input, output, rule: .spaceAroundParens, exclude: [.redundantVoidReturnType])
    }

    func testAddSpaceBetweenCaptureListAndArguments4() {
        let input = """
        { [weak self](foo: @escaping(Bar?) -> Void) -> Baz? in foo }
        """
        let output = """
        { [weak self] (foo: @escaping (Bar?) -> Void) -> Baz? in foo }
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenCaptureListAndArguments5() {
        let input = """
        { [weak self](foo: @autoclosure() -> String) -> Baz? in foo() }
        """
        let output = """
        { [weak self] (foo: @autoclosure () -> String) -> Baz? in foo() }
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenCaptureListAndArguments6() {
        let input = """
        { [weak self](foo: @Sendable() -> String) -> Baz? in foo() }
        """
        let output = """
        { [weak self] (foo: @Sendable () -> String) -> Baz? in foo() }
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenCaptureListAndArguments7() {
        let input = """
        Foo<Bar>(0) { [weak self]() -> Void in }
        """
        let output = """
        Foo<Bar>(0) { [weak self] () -> Void in }
        """
        testFormatting(for: input, output, rule: .spaceAroundParens, exclude: [.redundantVoidReturnType])
    }

    func testAddSpaceBetweenCaptureListAndArguments8() {
        let input = """
        { [weak self]() throws(Foo) -> Void in }
        """
        let output = """
        { [weak self] () throws(Foo) -> Void in }
        """
        testFormatting(for: input, output, rule: .spaceAroundParens, exclude: [.redundantVoidReturnType])
    }

    func testAddSpaceBetweenEscapingAndParenthesizedClosure() {
        let input = """
        @escaping(() -> Void)
        """
        let output = """
        @escaping (() -> Void)
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenAutoclosureAndParenthesizedClosure() {
        let input = """
        @autoclosure(() -> String)
        """
        let output = """
        @autoclosure (() -> String)
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testSpaceBetweenClosingParenAndOpenBrace() {
        let input = """
        func foo(){ foo }
        """
        let output = """
        func foo() { foo }
        """
        testFormatting(for: input, output, rule: .spaceAroundParens, exclude: [.wrapFunctionBodies])
    }

    func testNoSpaceBetweenClosingBraceAndParens() {
        let input = """
        { block } ()
        """
        let output = """
        { block }()
        """
        testFormatting(for: input, output, rule: .spaceAroundParens, exclude: [.redundantClosure])
    }

    func testDontRemoveSpaceBetweenOpeningBraceAndParens() {
        let input = """
        a = (b + c)
        """
        testFormatting(for: input, rule: .spaceAroundParens,
                       exclude: [.redundantParens])
    }

    func testKeywordAsIdentifierParensSpacing() {
        let input = """
        if foo.let (foo, bar) {}
        """
        let output = """
        if foo.let(foo, bar) {}
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testSpaceAfterInoutParam() {
        let input = """
        func foo(bar _: inout(Int, String)) {}
        """
        let output = """
        func foo(bar _: inout (Int, String)) {}
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testSpaceAfterEscapingAttribute() {
        let input = """
        func foo(bar: @escaping() -> Void)
        """
        let output = """
        func foo(bar: @escaping () -> Void)
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testSpaceAfterAutoclosureAttribute() {
        let input = """
        func foo(bar: @autoclosure () -> Void)
        """
        testFormatting(for: input, rule: .spaceAroundParens)
    }

    func testSpaceAfterSendableAttribute() {
        let input = """
        func foo(bar: @Sendable () -> Void)
        """
        testFormatting(for: input, rule: .spaceAroundParens)
    }

    func testSpaceBeforeTupleIndexArgument() {
        let input = """
        foo.1 (true)
        """
        let output = """
        foo.1(true)
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testRemoveSpaceBetweenParenAndBracket() {
        let input = """
        let foo = bar[5] ()
        """
        let output = """
        let foo = bar[5]()
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testRemoveSpaceBetweenParenAndBracketInsideClosure() {
        let input = """
        let foo = bar { [Int] () }
        """
        let output = """
        let foo = bar { [Int]() }
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenParenAndCaptureList() {
        let input = """
        let foo = bar { [self](foo: Int) in foo }
        """
        let output = """
        let foo = bar { [self] (foo: Int) in foo }
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenParenAndAwait() {
        let input = """
        let foo = await(bar: 5)
        """
        let output = """
        let foo = await (bar: 5)
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenParenAndAwaitForSwift5_5() {
        let input = """
        let foo = await(bar: 5)
        """
        let output = """
        let foo = await (bar: 5)
        """
        testFormatting(for: input, output, rule: .spaceAroundParens,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testNoAddSpaceBetweenParenAndAwaitForSwiftLessThan5_5() {
        let input = """
        let foo = await(bar: 5)
        """
        testFormatting(for: input, rule: .spaceAroundParens,
                       options: FormatOptions(swiftVersion: "5.4.9"))
    }

    func testAddSpaceBetweenParenAndUnsafe() {
        let input = """
        unsafe(["sudo"] + args).map { unsafe strdup($0) }
        """
        let output = """
        unsafe (["sudo"] + args).map { unsafe strdup($0) }
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testNoAddSpaceBetweenParenAndAwaitForSwiftLessThan6_2() {
        let input = """
        unsafe(["sudo"] + args).map { unsafe strdup($0) }
        """
        testFormatting(for: input, rule: .spaceAroundParens,
                       options: FormatOptions(swiftVersion: "6.1"))
    }

    func testRemoveSpaceBetweenParenAndConsume() {
        let input = """
        let foo = consume (bar)
        """
        let output = """
        let foo = consume(bar)
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testNoAddSpaceBetweenParenAndAvailableAfterFunc() {
        let input = """
        func foo()

        @available(macOS 10.13, *)
        func bar()
        """
        testFormatting(for: input, rule: .spaceAroundParens)
    }

    func testNoAddSpaceAroundTypedThrowsFunctionType() {
        let input = """
        func foo() throws (Bar) -> Baz {}
        """
        let output = """
        func foo() throws(Bar) -> Baz {}
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenParenAndBorrowing() {
        let input = """
        func foo(_: borrowing(any Foo)) {}
        """
        let output = """
        func foo(_: borrowing (any Foo)) {}
        """
        testFormatting(for: input, output, rule: .spaceAroundParens,
                       exclude: [.noExplicitOwnership])
    }

    func testAddSpaceBetweenParenAndIsolated() {
        let input = """
        func foo(isolation _: isolated(any Actor)) {}
        """
        let output = """
        func foo(isolation _: isolated (any Actor)) {}
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenParenAndSending() {
        let input = """
        func foo(_: sending(any Foo)) {}
        """
        let output = """
        func foo(_: sending (any Foo)) {}
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testOfTupleSpacing() {
        let input = """
        let foo: [4 of(String, Int)]
        """
        let output = """
        let foo: [4 of (String, Int)]
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testOfIdentifierParenSpacing() {
        let input = """
        if foo.of(String.self) {}
        """
        testFormatting(for: input, rule: .spaceAroundParens)
    }

    func testAsTupleCastingSpacing() {
        let input = """
        foo as(String, Int)
        """
        let output = """
        foo as (String, Int)
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAsOptionalTupleCastingSpacing() {
        let input = """
        foo as? (String, Int)
        """
        testFormatting(for: input, rule: .spaceAroundParens)
    }

    func testIsTupleTestingSpacing() {
        let input = """
        if foo is(String, Int) {}
        """
        let output = """
        if foo is (String, Int) {}
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testIsIdentifierParenSpacing() {
        let input = """
        if foo.is(String.self, Int.self) {}
        """
        testFormatting(for: input, rule: .spaceAroundParens)
    }

    func testSpaceBeforeTupleIndexCall() {
        let input = """
        foo.1 (2)
        """
        let output = """
        foo.1(2)
        """
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }
}
