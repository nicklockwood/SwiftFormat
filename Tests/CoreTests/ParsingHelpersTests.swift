//
//  ParsingHelpersTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 18/12/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class ParsingHelpersTests: XCTestCase {
    // MARK: isStartOfClosure

    // types

    func testStructBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("struct Foo {}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 4))
    }

    func testStructWithProtocolBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("struct Foo: Bar {}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 7))
    }

    func testStructWithMultipleProtocolsBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("struct Foo: Bar, Baz {}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 10))
    }

    func testClassBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("class Foo {}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 4))
    }

    func testProtocolBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("protocol Foo {}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 4))
    }

    func testEnumBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("enum Foo {}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 4))
    }

    func testExtensionBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("extension Foo {}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 4))
    }

    // conditional statements

    func testIfBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("if foo {}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 4))
    }

    func testIfLetBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("if let foo = foo {}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 10))
    }

    func testIfCommaBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("if foo, bar {}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 7))
    }

    func testIfElseBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("if foo {} else {}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 9))
    }

    func testIfConditionClosureTreatedAsClosure() {
        let formatter = Formatter(tokenize("""
        if let foo = { () -> Int? in 5 }() {}
        """))
        XCTAssertTrue(formatter.isStartOfClosure(at: 8))
        XCTAssertFalse(formatter.isStartOfClosure(at: 26))
    }

    func testIfConditionClosureTreatedAsClosure2() {
        let formatter = Formatter(tokenize("if !foo { bar } {}"))
        XCTAssertTrue(formatter.isStartOfClosure(at: 5))
        XCTAssertFalse(formatter.isStartOfClosure(at: 11))
    }

    func testIfConditionWithoutSpaceNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("if let foo = bar(){}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 11))
    }

    func testGuardElseBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("guard foo else {}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 6))
    }

    func testWhileBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("while foo {}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 4))
    }

    func testForInBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("for foo in bar {}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 8))
    }

    func testRepeatBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("repeat {} while foo"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 2))
    }

    func testDoCatchBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("do {} catch Foo.error {}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 2))
        XCTAssertFalse(formatter.isStartOfClosure(at: 11))
    }

    func testClosureRecognizedInsideGuardCondition() {
        let formatter = Formatter(tokenize("""
        guard let bar = { nil }() else {
            return nil
        }
        """))
        XCTAssertTrue(formatter.isStartOfClosure(at: 8))
        XCTAssertFalse(formatter.isStartOfClosure(at: 18))
    }

    func testClosureInIfCondition() {
        let formatter = Formatter(tokenize("""
        if let btn = btns.first { !$0.isHidden } {}
        """))
        XCTAssertTrue(formatter.isStartOfClosure(at: 12))
        XCTAssertFalse(formatter.isStartOfClosure(at: 21))
    }

    func testClosureInIfCondition2() {
        let formatter = Formatter(tokenize("""
        if let foo, let btn = btns.first { !$0.isHidden } {}
        """))
        XCTAssertTrue(formatter.isStartOfClosure(at: 17))
        XCTAssertFalse(formatter.isStartOfClosure(at: 26))
    }

    // functions

    func testFunctionBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo() { bar = 5 }"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 6))
    }

    func testGenericFunctionNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo<T: Equatable>(_: T) {}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 16))
    }

    func testNonVoidFunctionBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo() -> Int {}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 10))
    }

    func testOptionalReturningFunctionBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo() -> Int? {}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 11))
    }

    func testTupleReturningFunctionBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo() -> (Int, Bool) {}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 15))
    }

    func testArrayReturningFunctionBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo() -> [Int] {}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 12))
    }

    func testNonVoidFunctionAllmanBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo() -> Int\n{\n    return 5\n}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 10))
    }

    func testThrowingFunctionBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo() throws { bar = 5 }"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 8))
    }

    func testThrowingFunctionWithReturnTypeNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo() throws -> Bar {}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 12))
    }

    func testFunctionWithOpaqueReturnTypeNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo() -> any Bar {}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 12))
    }

    func testThrowingFunctionWithGenericReturnTypeNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo<Baz>() throws -> Bar<Baz> {}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 18))
    }

    func testFunctionAllmanBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo()\n{\n    bar = 5\n}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 6))
    }

    func testFunctionWithWhereClauseBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo<U, V>() where T == Result<U, V> {}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 26))
    }

    func testThrowingFunctionWithWhereClauseBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("func foo<U, V>() throws where T == Result<U, V> {}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 28))
    }

    func testInitBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("init() { foo = 5 }"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 4))
    }

    func testGenericInitBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("init<T>() { foo = 5 }"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 7))
    }

    func testGenericOptionalInitBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("init?<T>() { foo = 5 }"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 8))
    }

    func testInitAllmanBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("init()\n{\n    foo = 5\n}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 4))
    }

    func testOptionalInitNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("init?() { return nil }"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 5))
    }

    func testOptionalInitAllmanBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("init?()\n{\n    return nil\n}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 5))
    }

    func testDeinitBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("deinit { foo = nil }"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 2))
    }

    func testDeinitAllmanBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("deinit\n{\n    foo = nil\n}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 2))
    }

    func testSubscriptBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("subscript(i: Int) -> Int { foo[i] }"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 12))
    }

    func testSubscriptAllmanBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("subscript(i: Int) -> Int\n{\n    foo[i]\n}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 12))
    }

    // accessors

    func testComputedVarBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("var foo: Int { return 5 }"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 7))
    }

    func testComputedVarAllmanBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("var foo: Int\n{\n    return 5\n}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 7))
    }

    func testVarFollowedByBracesOnNextLineTreatedAsClosure() {
        let formatter = Formatter(tokenize("var foo: Int\nfoo { return 5 }"))
        XCTAssert(formatter.isStartOfClosure(at: 9))
    }

    func testVarAssignmentBracesTreatedAsClosure() {
        let formatter = Formatter(tokenize("var foo = { return 5 }"))
        XCTAssert(formatter.isStartOfClosure(at: 6))
    }

    func testVarAssignmentBracesTreatedAsClosure2() {
        let formatter = Formatter(tokenize("var foo = bar { return 5 }"))
        XCTAssert(formatter.isStartOfClosure(at: 8))
    }

    func testTypedVarAssignmentBracesTreatedAsClosure() {
        let formatter = Formatter(tokenize("var foo: Int = { return 5 }"))
        XCTAssert(formatter.isStartOfClosure(at: 9))
    }

    func testVarDidSetBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("var foo: Int { didSet {} }"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 7))
        XCTAssertFalse(formatter.isStartOfClosure(at: 11))
    }

    func testVarDidSetBracesNotTreatedAsClosure2() {
        let formatter = Formatter(tokenize("var foo = bar { didSet {} }"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 8))
        XCTAssertFalse(formatter.isStartOfClosure(at: 12))
    }

    func testVarDidSetBracesNotTreatedAsClosure3() {
        let formatter = Formatter(tokenize("var foo = bar() { didSet {} }"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 10))
        XCTAssertFalse(formatter.isStartOfClosure(at: 14))
    }

    func testVarDidSetWithExplicitParamBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("var foo: Int { didSet(old) {} }"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 7))
        XCTAssertFalse(formatter.isStartOfClosure(at: 14))
    }

    func testVarDidSetWithExplicitParamBracesNotTreatedAsClosure2() {
        let formatter = Formatter(tokenize("var foo: Array<Int> { didSet(old) {} }"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 10))
        XCTAssertFalse(formatter.isStartOfClosure(at: 17))
    }

    func testVarDidSetWithExplicitParamBracesNotTreatedAsClosure3() {
        let formatter = Formatter(tokenize("var foo = bar { didSet(old) {} }"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 8))
        XCTAssertFalse(formatter.isStartOfClosure(at: 15))
    }

    func testVarDidSetWithExplicitParamBracesNotTreatedAsClosure4() {
        let formatter = Formatter(tokenize("var foo = bar() { didSet(old) {} }"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 10))
        XCTAssertFalse(formatter.isStartOfClosure(at: 17))
    }

    func testVarDidSetWithExplicitParamBracesNotTreatedAsClosure5() {
        let formatter = Formatter(tokenize("var foo = [5] { didSet(old) {} }"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 10))
        XCTAssertFalse(formatter.isStartOfClosure(at: 17))
    }

    // chained closures

    func testChainedTrailingClosureInVarChain() {
        let formatter = Formatter(tokenize("var foo = bar.baz { 5 }.quux { 6 }"))
        XCTAssert(formatter.isStartOfClosure(at: 10))
        XCTAssert(formatter.isStartOfClosure(at: 18))
    }

    func testChainedTrailingClosureInVarChain2() {
        let formatter = Formatter(tokenize("var foo = bar().baz { 5 }.quux { 6 }"))
        XCTAssert(formatter.isStartOfClosure(at: 12))
        XCTAssert(formatter.isStartOfClosure(at: 20))
    }

    func testChainedTrailingClosureInVarChain3() {
        let formatter = Formatter(tokenize("var foo = bar.baz() { 5 }.quux { 6 }"))
        XCTAssert(formatter.isStartOfClosure(at: 12))
        XCTAssert(formatter.isStartOfClosure(at: 20))
    }

    func testChainedTrailingClosureInLetChain() {
        let formatter = Formatter(tokenize("let foo = bar.baz { 5 }.quux { 6 }"))
        XCTAssert(formatter.isStartOfClosure(at: 10))
        XCTAssert(formatter.isStartOfClosure(at: 18))
    }

    func testChainedTrailingClosureInTypedVarChain() {
        let formatter = Formatter(tokenize("var foo: Int = bar.baz { 5 }.quux { 6 }"))
        XCTAssert(formatter.isStartOfClosure(at: 13))
        XCTAssert(formatter.isStartOfClosure(at: 21))
    }

    func testChainedTrailingClosureInTypedVarChain2() {
        let formatter = Formatter(tokenize("var foo: Int = bar().baz { 5 }.quux { 6 }"))
        XCTAssert(formatter.isStartOfClosure(at: 15))
        XCTAssert(formatter.isStartOfClosure(at: 23))
    }

    func testChainedTrailingClosureInTypedVarChain3() {
        let formatter = Formatter(tokenize("var foo: Int = bar.baz() { 5 }.quux { 6 }"))
        XCTAssert(formatter.isStartOfClosure(at: 15))
        XCTAssert(formatter.isStartOfClosure(at: 23))
    }

    func testChainedTrailingClosureInTypedLetChain() {
        let formatter = Formatter(tokenize("let foo: Int = bar.baz { 5 }.quux { 6 }"))
        XCTAssert(formatter.isStartOfClosure(at: 13))
        XCTAssert(formatter.isStartOfClosure(at: 21))
    }

    // async / await

    func testAsyncClosure() {
        let formatter = Formatter(tokenize("{ (foo) async in foo }"))
        XCTAssert(formatter.isStartOfClosure(at: 0))
    }

    func testAsyncClosure2() {
        let formatter = Formatter(tokenize("{ foo async in foo }"))
        XCTAssert(formatter.isStartOfClosure(at: 0))
    }

    func testFunctionNamedAsync() {
        let formatter = Formatter(tokenize("foo = async { bar }"))
        XCTAssert(formatter.isStartOfClosure(at: 6))
    }

    func testAwaitClosure() {
        let formatter = Formatter(tokenize("foo = await { bar }"))
        XCTAssert(formatter.isStartOfClosure(at: 6))
    }

    // edge cases

    func testMultipleNestedTrailingClosures() {
        let repeatCount = 2
        let formatter = Formatter(tokenize("""
        override func foo() {
        bar {
        var baz = 5
        \(String(repeating: """
        fizz {
        buzz {
        fizzbuzz()
        }
        }

        """, count: repeatCount))}
        }
        """))
        XCTAssertFalse(formatter.isStartOfClosure(at: 8))
        XCTAssert(formatter.isStartOfClosure(at: 12))
        for i in stride(from: 0, to: repeatCount * 16, by: 16) {
            XCTAssert(formatter.isStartOfClosure(at: 24 + i))
            XCTAssert(formatter.isStartOfClosure(at: 28 + i))
        }
    }

    func testWrappedClosureAfterAnIfStatement() {
        let formatter = Formatter(tokenize("""
        if foo {}
        bar
            .baz {}
        """))
        XCTAssert(formatter.isStartOfClosure(at: 13))
    }

    func testWrappedClosureAfterSwitch() {
        let formatter = Formatter(tokenize("""
        switch foo {
        default:
            break
        }
        bar
            .map {
                // baz
            }
        """))
        XCTAssert(formatter.isStartOfClosure(at: 20))
    }

    func testClosureInsideIfCondition() {
        let formatter = Formatter(tokenize("""
        if let foo = bar(), { x == y }() {}
        """))
        XCTAssert(formatter.isStartOfClosure(at: 13))
        XCTAssertFalse(formatter.isStartOfClosure(at: 25))
    }

    func testClosureInsideIfCondition2() {
        let formatter = Formatter(tokenize("""
        if foo == bar.map { $0.baz }.sorted() {}
        """))
        XCTAssert(formatter.isStartOfClosure(at: 10))
        XCTAssertFalse(formatter.isStartOfClosure(at: 22))
    }

    func testClosureInsideIfCondition3() {
        let formatter = Formatter(tokenize("""
        if baz, let foo = bar(), { x == y }() {}
        """))
        XCTAssert(formatter.isStartOfClosure(at: 16))
        XCTAssertFalse(formatter.isStartOfClosure(at: 28))
    }

    func testClosureAfterGenericType() {
        let formatter = Formatter(tokenize("let foo = Foo<String> {}"))
        XCTAssert(formatter.isStartOfClosure(at: 11))
    }

    func testAllmanClosureAfterFunction() {
        let formatter = Formatter(tokenize("""
        func foo() {}
        Foo
            .baz
            {
                baz()
            }
        """))
        XCTAssert(formatter.isStartOfClosure(at: 16))
    }

    func testGenericInitializerTrailingClosure() {
        let formatter = Formatter(tokenize("""
        Foo<Bar>(0) { [weak self]() -> Void in }
        """))
        XCTAssert(formatter.isStartOfClosure(at: 8))
    }

    func testParameterBodyAfterStringIsNotClosure() {
        let formatter = Formatter(tokenize("""
        var foo: String = "bar" {
            didSet { print("didSet") }
        }
        """))
        XCTAssertFalse(formatter.isStartOfClosure(at: 13))
    }

    func testParameterBodyAfterMultilineStringIsNotClosure() {
        let formatter = Formatter(tokenize("""
        var foo: String = \"\""
        bar
        \"\"" {
            didSet { print("didSet") }
        }
        """))
        XCTAssertFalse(formatter.isStartOfClosure(at: 15))
    }

    func testParameterBodyAfterNumberIsNotClosure() {
        let formatter = Formatter(tokenize("""
        var foo: Int = 10 {
            didSet { print("didSet") }
        }
        """))
        XCTAssertFalse(formatter.isStartOfClosure(at: 11))
    }

    func testParameterBodyAfterClosureIsNotClosure() {
        let formatter = Formatter(tokenize("""
        var foo: () -> String = { "bar" } {
            didSet { print("didSet") }
        }
        """))
        XCTAssertFalse(formatter.isStartOfClosure(at: 22))
    }

    func testParameterBodyAfterExecutedClosureIsNotClosure() {
        let formatter = Formatter(tokenize("""
        var foo: String = { "bar" }() {
            didSet { print("didSet") }
        }
        """))
        XCTAssertFalse(formatter.isStartOfClosure(at: 19))
    }

    func testMainActorClosure() {
        let formatter = Formatter(tokenize("""
        let foo = { @MainActor in () }
        """))
        XCTAssert(formatter.isStartOfClosure(at: 6))
    }

    func testThrowingClosure() {
        let formatter = Formatter(tokenize("""
        let foo = { bar throws in bar }
        """))
        XCTAssert(formatter.isStartOfClosure(at: 6))
    }

    func testTypedThrowingClosure() {
        let formatter = Formatter(tokenize("""
        let foo = { bar throws(Foo) in bar }
        """))
        XCTAssert(formatter.isStartOfClosure(at: 6))
    }

    func testNestedTypedThrowingClosures() {
        let formatter = Formatter(tokenize("""
        try! str.withCString(encodedAs: UTF8.self) { _ throws(Foo) in
            try! str.withCString(encodedAs: UTF8.self) { _ throws(Foo) in }
        }
        """))
        XCTAssert(formatter.isStartOfClosure(at: 15))
        XCTAssert(formatter.isStartOfClosure(at: 42))
    }

    func testTrailingClosureOnOptionalMethod() {
        let formatter = Formatter(tokenize("""
        foo.bar? { print("") }
        """))
        XCTAssert(formatter.isStartOfClosure(at: 5))
    }

    func testBraceAfterTypedThrows() {
        let formatter = Formatter(tokenize("""
        do throws(Foo) {} catch {}
        """))
        XCTAssertFalse(formatter.isStartOfClosure(at: 7))
        XCTAssertFalse(formatter.isStartOfClosure(at: 12))
    }

    // MARK: isConditionalStatement

    func testIfConditionContainingClosure() {
        let formatter = Formatter(tokenize("""
        if let btn = btns.first { !$0.isHidden } {}
        """))
        XCTAssertTrue(formatter.isConditionalStatement(at: 12))
        XCTAssertTrue(formatter.isConditionalStatement(at: 21))
    }

    func testIfConditionContainingClosure2() {
        let formatter = Formatter(tokenize("""
        if let foo, let btn = btns.first { !$0.isHidden } {}
        """))
        XCTAssertTrue(formatter.isConditionalStatement(at: 17))
        XCTAssertTrue(formatter.isConditionalStatement(at: 26))
    }

    // MARK: isAccessorKeyword

    func testDidSet() {
        let formatter = Formatter(tokenize("var foo: Int { didSet {} }"))
        XCTAssert(formatter.isAccessorKeyword(at: 9))
    }

    func testDidSetWillSet() {
        let formatter = Formatter(tokenize("""
        var foo: Int {
            didSet {}
            willSet {}
        }
        """))
        XCTAssert(formatter.isAccessorKeyword(at: 10))
        XCTAssert(formatter.isAccessorKeyword(at: 16))
    }

    func testGetSet() {
        let formatter = Formatter(tokenize("""
        var foo: Int {
            get { return _foo }
            set { _foo = newValue }
        }
        """))
        XCTAssert(formatter.isAccessorKeyword(at: 10))
        XCTAssert(formatter.isAccessorKeyword(at: 21))
    }

    func testSetGet() {
        let formatter = Formatter(tokenize("""
        var foo: Int {
            set { _foo = newValue }
            get { return _foo }
        }
        """))
        XCTAssert(formatter.isAccessorKeyword(at: 10))
        XCTAssert(formatter.isAccessorKeyword(at: 23))
    }

    func testGenericSubscriptSetGet() {
        let formatter = Formatter(tokenize("""
        subscript<T>(index: Int) -> T {
            set { _foo[index] = newValue }
            get { return _foo[index] }
        }
        """))
        XCTAssert(formatter.isAccessorKeyword(at: 18))
        XCTAssert(formatter.isAccessorKeyword(at: 34))
    }

    func testInit() {
        let formatter = Formatter(tokenize("""
        var foo: Int {
            init {}
            get {}
            set {}
        }
        """))
        XCTAssert(formatter.isAccessorKeyword(at: 10))
        XCTAssert(formatter.isAccessorKeyword(at: 16))
    }

    func testNotGetter() {
        let formatter = Formatter(tokenize("""
        func foo() {
            set { print("") }
        }
        """))
        XCTAssertFalse(formatter.isAccessorKeyword(at: 9))
    }

    func testFunctionInGetterPosition() {
        let formatter = Formatter(tokenize("""
        var foo: Int {
            `get`()
            return 5
        }
        """))
        XCTAssert(formatter.isAccessorKeyword(at: 10, checkKeyword: false))
    }

    func testNotSetterInit() {
        let formatter = Formatter(tokenize("""
        class Foo {
            init() { print("") }
        }
        """))
        XCTAssertFalse(formatter.isAccessorKeyword(at: 7))
    }

    // MARK: isEnumCase

    func testIsEnumCase() {
        let formatter = Formatter(tokenize("""
        enum Foo {
            case foo, bar
            case baz
        }
        """))
        XCTAssert(formatter.isEnumCase(at: 7))
        XCTAssert(formatter.isEnumCase(at: 15))
    }

    func testIsEnumCaseWithValue() {
        let formatter = Formatter(tokenize("""
        enum Foo {
            case foo, bar(Int)
            case baz
        }
        """))
        XCTAssert(formatter.isEnumCase(at: 7))
        XCTAssert(formatter.isEnumCase(at: 18))
    }

    func testIsNotEnumCase() {
        let formatter = Formatter(tokenize("""
        if case let .foo(bar) = baz {}
        """))
        XCTAssertFalse(formatter.isEnumCase(at: 2))
    }

    func testTypoIsNotEnumCase() {
        let formatter = Formatter(tokenize("""
        if let case .foo(bar) = baz {}
        """))
        XCTAssertFalse(formatter.isEnumCase(at: 4))
    }

    func testMixedCaseTypes() {
        let formatter = Formatter(tokenize("""
        enum Foo {
            case foo
            case bar(value: [Int])
        }

        func baz() {
            if case .foo = foo,
               case .bar(let value) = bar,
               value.isEmpty {}
        }
        """))
        XCTAssert(formatter.isEnumCase(at: 7))
        XCTAssert(formatter.isEnumCase(at: 12))
        XCTAssertFalse(formatter.isEnumCase(at: 38))
        XCTAssertFalse(formatter.isEnumCase(at: 49))
    }

    // MARK: modifierOrder

    func testModifierOrder() {
        let options = FormatOptions(modifierOrder: ["convenience", "override"])
        let formatter = Formatter([], options: options)
        XCTAssertEqual(formatter.modifierOrder, [
            "private", "fileprivate", "internal", "package", "public", "open",
            "private(set)", "fileprivate(set)", "internal(set)", "package(set)", "public(set)", "open(set)",
            "final",
            "dynamic",
            "optional", "required",
            "convenience",
            "override",
            "indirect",
            "isolated", "nonisolated", "nonisolated(unsafe)",
            "lazy",
            "weak", "unowned",
            "static", "class",
            "borrowing", "consuming", "mutating", "nonmutating",
            "prefix", "infix", "postfix",
        ])
    }

    func testModifierOrder2() {
        let options = FormatOptions(modifierOrder: [
            "override", "acl", "setterACL", "dynamic", "mutators",
            "lazy", "final", "required", "convenience", "typeMethods", "owned",
        ])
        let formatter = Formatter([], options: options)
        XCTAssertEqual(formatter.modifierOrder, [
            "override",
            "private", "fileprivate", "internal", "package", "public", "open",
            "private(set)", "fileprivate(set)", "internal(set)", "package(set)", "public(set)", "open(set)",
            "dynamic",
            "indirect",
            "isolated", "nonisolated", "nonisolated(unsafe)",
            "static", "class",
            "borrowing", "consuming", "mutating", "nonmutating",
            "lazy",
            "final",
            "optional", "required",
            "convenience",
            "weak", "unowned",
            "prefix", "infix", "postfix",
        ])
    }

    // MARK: startOfModifiers

    func testStartOfModifiers() {
        let formatter = Formatter(tokenize("""
        class Foo { @objc public required init() {} }
        """))
        XCTAssertEqual(formatter.startOfModifiers(at: 12, includingAttributes: false), 8)
    }

    func testStartOfModifiersIncludingNonisolated() {
        let formatter = Formatter(tokenize("""
        actor Foo { nonisolated public func foo() {} }
        """))
        XCTAssertEqual(formatter.startOfModifiers(at: 10, includingAttributes: true), 6)
    }

    func testStartOfModifiersIncludingAttributes() {
        let formatter = Formatter(tokenize("""
        class Foo { @objc public required init() {} }
        """))
        XCTAssertEqual(formatter.startOfModifiers(at: 12, includingAttributes: true), 6)
    }

    func testStartOfPropertyModifiers() {
        let formatter = Formatter(tokenize("""
        @objc public class override var foo: Int?
        """))
        XCTAssertEqual(formatter.startOfModifiers(at: 6, includingAttributes: true), 0)
    }

    func testStartOfPropertyModifiers2() {
        let formatter = Formatter(tokenize("""
        @objc(SFFoo) public var foo: Int?
        """))
        XCTAssertEqual(formatter.startOfModifiers(at: 7, includingAttributes: false), 5)
    }

    func testStartOfPropertyModifiers3() {
        let formatter = Formatter(tokenize("""
        @OuterType.Wrapper var foo: Int?
        """))
        XCTAssertEqual(formatter.startOfModifiers(at: 4, includingAttributes: true), 0)
    }

    // MARK: processDeclaredVariables

    func testProcessCommaDelimitedDeclaredVariables() {
        let formatter = Formatter(tokenize("""
        let foo = bar(), x = y, baz = quux {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["foo", "x", "baz"])
        XCTAssertEqual(index, 22)
    }

    func testProcessDeclaredVariablesInIfCondition() {
        let formatter = Formatter(tokenize("""
        if let foo = bar(), x == y, let baz = quux {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["foo", "baz"])
        XCTAssertEqual(index, 26)
    }

    func testProcessDeclaredVariablesInIfWithParenthetical() {
        let formatter = Formatter(tokenize("""
        if let foo = bar(), (x == y), let baz = quux {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["foo", "baz"])
        XCTAssertEqual(index, 28)
    }

    func testProcessDeclaredVariablesInIfWithClosure() {
        let formatter = Formatter(tokenize("""
        if let foo = bar(), { x == y }(), let baz = quux {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["foo", "baz"])
        XCTAssertEqual(index, 32)
    }

    func testProcessDeclaredVariablesInIfWithNamedClosureArgument() {
        let formatter = Formatter(tokenize("""
        if let foo = bar, foo.bar(baz: { $0 }), let baz = quux {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["foo", "baz"])
        XCTAssertEqual(index, 32)
    }

    func testProcessDeclaredVariablesInIfAfterCase() {
        let formatter = Formatter(tokenize("""
        if case let .foo(bar, .baz(quux: 5)) = foo, let baz2 = quux2 {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["bar", "baz2"])
        XCTAssertEqual(index, 33)
    }

    func testProcessDeclaredVariablesInIfWithArrayLiteral() {
        let formatter = Formatter(tokenize("""
        if let foo = bar(), [x] == y, let baz = quux {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["foo", "baz"])
        XCTAssertEqual(index, 28)
    }

    func testProcessDeclaredVariablesInIfLetAs() {
        let formatter = Formatter(tokenize("""
        if let foo = foo as? String, let bar = baz {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["foo", "bar"])
        XCTAssertEqual(index, 22)
    }

    func testProcessDeclaredVariablesInIfLetWithPostfixOperator() {
        let formatter = Formatter(tokenize("""
        if let foo = baz?.foo, let bar = baz?.bar {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["foo", "bar"])
        XCTAssertEqual(index, 23)
    }

    func testProcessCaseDeclaredVariablesInIfLetCommaCase() {
        let formatter = Formatter(tokenize("""
        if let foo = bar(), case .bar(var baz) = quux {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["foo", "baz"])
        XCTAssertEqual(index, 25)
    }

    func testProcessCaseDeclaredVariablesInIfCaseLet() {
        let formatter = Formatter(tokenize("""
        if case let .foo(a: bar, b: baz) = quux {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["bar", "baz"])
        XCTAssertEqual(index, 23)
    }

    func testProcessTupleDeclaredVariablesInIfLetSyntax() {
        let formatter = Formatter(tokenize("""
        if let (bar, a: baz) = quux, let x = y {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["x", "bar", "baz"])
        XCTAssertEqual(index, 25)
    }

    func testProcessTupleDeclaredVariablesInIfLetSyntax2() {
        let formatter = Formatter(tokenize("""
        if let ((a: bar, baz), (x, y)) = quux {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["bar", "baz", "x", "y"])
        XCTAssertEqual(index, 26)
    }

    func testProcessAwaitVariableInForLoop() {
        let formatter = Formatter(tokenize("""
        for await foo in DoubleGenerator() {
            print(foo)
        }
        """))
        var index = 0
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["foo"])
        XCTAssertEqual(index, 4)
    }

    func testProcessParametersInInit() {
        let formatter = Formatter(tokenize("""
        init(actor: Int, bar: String) {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["actor", "bar"])
        XCTAssertEqual(index, 11)
    }

    func testProcessGuardCaseLetVariables() {
        let formatter = Formatter(tokenize("""
        guard case let Foo.bar(foo) = baz
        else { return }
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["foo"])
        XCTAssertEqual(index, 15)
    }

    func testProcessLetDictionaryLiteralVariables() {
        let formatter = Formatter(tokenize("""
        let foo = [bar: 1, baz: 2]
        print(foo)
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["foo"])
        XCTAssertEqual(index, 17)
    }

    func testProcessLetStringLiteralFollowedByPrint() {
        let formatter = Formatter(tokenize("""
        let bar = "bar"
        print(bar)
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["bar"])
        XCTAssertEqual(index, 8)
    }

    func testProcessLetNumericLiteralFollowedByPrint() {
        let formatter = Formatter(tokenize("""
        let bar = 5
        print(bar)
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["bar"])
        XCTAssertEqual(index, 6)
    }

    func testProcessLetBooleanLiteralFollowedByPrint() {
        let formatter = Formatter(tokenize("""
        let bar = true
        print(bar)
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["bar"])
        XCTAssertEqual(index, 6)
    }

    func testProcessLetNilLiteralFollowedByPrint() {
        let formatter = Formatter(tokenize("""
        let bar: Bar? = nil
        print(bar)
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["bar"])
        XCTAssertEqual(index, 10)
    }

    // MARK: parseDeclarations

    func testParseDeclarations() {
        let input = """
        import CoreGraphics
        import Foundation

        let global = 10

        @objc
        @available(iOS 13.0, *)
        @propertyWrapper("parameter")
        weak var multilineGlobal = ["string"]
            .map(\\.count)
        let anotherGlobal = "hello"

        /// Doc comment
        /// (multiple lines)
        func globalFunction() {
            print("hi")
        }

        protocol SomeProtocol {
            var getter: String { get async throws }
            func protocolMethod() -> Bool
        }

        class SomeClass {

            enum NestedEnum {
                /// Doc comment
                case bar
                func test() {}
            }

            /*
             * Block comment
             */

            private(set)
            var instanceVar = "test" // trailing comment

            @objc
            private var computed: String {
                get {
                    "computed string"
                }
            }

        }
        """

        let originalTokens = tokenize(input)
        let declarations = Formatter(originalTokens).parseDeclarations()

        // Verify we didn't lose any tokens
        XCTAssertEqual(originalTokens, declarations.flatMap { $0.tokens })

        XCTAssertEqual(
            sourceCode(for: declarations[0].tokens),
            """
            import CoreGraphics

            """
        )

        XCTAssertEqual(
            sourceCode(for: declarations[1].tokens),
            """
            import Foundation


            """
        )

        XCTAssertEqual(
            sourceCode(for: declarations[2].tokens),
            """
            let global = 10


            """
        )

        XCTAssertEqual(
            sourceCode(for: declarations[3].tokens),
            """
            @objc
            @available(iOS 13.0, *)
            @propertyWrapper("parameter")
            weak var multilineGlobal = ["string"]
                .map(\\.count)

            """
        )

        XCTAssertEqual(
            sourceCode(for: declarations[4].tokens),
            """
            let anotherGlobal = "hello"


            """
        )

        XCTAssertEqual(
            sourceCode(for: declarations[5].tokens),
            """
            /// Doc comment
            /// (multiple lines)
            func globalFunction() {
                print("hi")
            }


            """
        )

        XCTAssertEqual(
            sourceCode(for: declarations[6].tokens),
            """
            protocol SomeProtocol {
                var getter: String { get async throws }
                func protocolMethod() -> Bool
            }


            """
        )

        XCTAssertEqual(
            sourceCode(for: declarations[6].body?[0].tokens),
            """
                var getter: String { get async throws }

            """
        )

        XCTAssertEqual(
            sourceCode(for: declarations[6].body?[1].tokens),
            """
                func protocolMethod() -> Bool

            """
        )

        XCTAssertEqual(
            sourceCode(for: declarations[7].tokens),
            """
            class SomeClass {

                enum NestedEnum {
                    /// Doc comment
                    case bar
                    func test() {}
                }

                /*
                 * Block comment
                 */

                private(set)
                var instanceVar = "test" // trailing comment

                @objc
                private var computed: String {
                    get {
                        "computed string"
                    }
                }

            }
            """
        )

        XCTAssertEqual(
            sourceCode(for: declarations[7].body?[0].tokens),
            """
                enum NestedEnum {
                    /// Doc comment
                    case bar
                    func test() {}
                }


            """
        )

        XCTAssertEqual(
            sourceCode(for: declarations[7].body?[0].body?[0].tokens),
            """
                    /// Doc comment
                    case bar

            """
        )

        XCTAssertEqual(
            sourceCode(for: declarations[7].body?[0].body?[1].tokens),
            """
                    func test() {}

            """
        )

        XCTAssertEqual(
            sourceCode(for: declarations[7].body?[1].tokens),
            """
                /*
                 * Block comment
                 */

                private(set)
                var instanceVar = "test" // trailing comment


            """
        )

        XCTAssertEqual(
            sourceCode(for: declarations[7].body?[2].tokens),
            """
                @objc
                private var computed: String {
                    get {
                        "computed string"
                    }
                }


            """
        )
    }

    func testParseClassFuncDeclarationCorrectly() {
        // `class func` is one of the few cases (possibly only!)
        // where a declaration will have more than one declaration token
        let input = """
        class Foo() {}

        class func foo() {}
        """

        let originalTokens = tokenize(input)
        let declarations = Formatter(originalTokens).parseDeclarations()

        XCTAssert(declarations[0].keyword == "class")
        XCTAssert(declarations[1].keyword == "func")
    }

    func testParseMarkCommentsCorrectly() {
        let input = """
        class Foo {

            // MARK: Lifecycle

            init(json: JSONObject) throws {
                bar = try json.value(for: "bar")
                baz = try json.value(for: "baz")
            }

            // MARK: Internal

            let bar: String
            var baz: Int?

        }
        """

        let originalTokens = tokenize(input)
        let declarations = Formatter(originalTokens).parseDeclarations()

        XCTAssert(declarations[0].keyword == "class")
        XCTAssert(declarations[0].body?[0].keyword == "init")
        XCTAssert(declarations[0].body?[1].keyword == "let")
        XCTAssert(declarations[0].body?[2].keyword == "var")
    }

    func testParseTrailingCommentsCorrectly() {
        let input = """
        struct Foo {
            var bar = "bar"
            /// Leading comment
            public var baz = "baz" // Trailing comment
            var quux = "quux"
        }
        """

        let originalTokens = tokenize(input)
        let declarations = Formatter(originalTokens).parseDeclarations()

        XCTAssertEqual(
            sourceCode(for: declarations[0].body?[0].tokens),
            """
                var bar = "bar"

            """
        )

        XCTAssertEqual(
            sourceCode(for: declarations[0].body?[0].tokens),
            """
                var bar = "bar"

            """
        )

        XCTAssertEqual(
            sourceCode(for: declarations[0].body?[1].tokens),
            """
                /// Leading comment
                public var baz = "baz" // Trailing comment

            """
        )

        XCTAssertEqual(
            sourceCode(for: declarations[0].body?[2].tokens),
            """
                var quux = "quux"

            """
        )
    }

    func testParseDeclarationsWithSituationalKeywords() {
        let input = """
        let `static` = NavigationBarType.static(nil, .none)
        let foo = bar
        let `static` = NavigationBarType.static
        let bar = foo
        """

        let originalTokens = tokenize(input)
        let declarations = Formatter(originalTokens).parseDeclarations()

        XCTAssertEqual(
            sourceCode(for: declarations[0].tokens),
            """
            let `static` = NavigationBarType.static(nil, .none)

            """
        )

        XCTAssertEqual(
            sourceCode(for: declarations[1].tokens),
            """
            let foo = bar

            """
        )

        XCTAssertEqual(
            sourceCode(for: declarations[2].tokens),
            """
            let `static` = NavigationBarType.static

            """
        )

        XCTAssertEqual(
            sourceCode(for: declarations[3].tokens),
            """
            let bar = foo
            """
        )
    }

    func testParseSimpleCompilationBlockCorrectly() {
        let input = """
        #if DEBUG
        struct DebugFoo {
            let bar = "debug"
        }
        #endif
        """

        let originalTokens = tokenize(input)
        let declarations = Formatter(originalTokens).parseDeclarations()

        XCTAssertNotNil(declarations[0].keyword, "#if")
        XCTAssertEqual(declarations[0].body?[0].keyword, "struct")
        XCTAssertEqual(declarations[0].body?[0].body?[0].keyword, "let")
    }

    func testParseSimpleNestedCompilationBlockCorrectly() {
        let input = """
        #if canImport(UIKit)
        #if DEBUG
        struct DebugFoo {
            let bar = "debug"
        }
        #endif
        #endif
        """

        let originalTokens = tokenize(input)
        let declarations = Formatter(originalTokens).parseDeclarations()

        XCTAssertNotNil(declarations[0].keyword, "#if")
        XCTAssertEqual(declarations[0].body?[0].keyword, "#if")
        XCTAssertEqual(declarations[0].body?[0].body?[0].keyword, "struct")
        XCTAssertEqual(declarations[0].body?[0].body?[0].body?[0].keyword, "let")
    }

    func testParseComplexConditionalCompilationBlockCorrectly() {
        let input = """
        let beforeBlock = "baz"

        #if DEBUG
        struct DebugFoo {
            let bar = "debug"
        }
        #elseif BETA
        struct BetaFoo {
            let bar = "beta"
        }
        #else
        struct ProductionFoo {
            let bar = "production"
        }
        #endif

        let afterBlock = "quux"
        """

        let originalTokens = tokenize(input)
        let declarations = Formatter(originalTokens).parseDeclarations()

        XCTAssertEqual(declarations[0].keyword, "let")
        XCTAssertEqual(declarations[1].keyword, "#if")
        XCTAssertEqual(declarations[1].body?[0].keyword, "struct")
        XCTAssertEqual(declarations[1].body?[1].keyword, "struct")
        XCTAssertEqual(declarations[1].body?[2].keyword, "struct")
        XCTAssertEqual(declarations[2].keyword, "let")
    }

    func testParseSymbolImportCorrectly() {
        let input = """
        import protocol SomeModule.SomeProtocol
        import class SomeModule.SomeClass
        import enum SomeModule.SomeEnum
        import struct SomeModule.SomeStruct
        import typealias SomeModule.SomeTypealias
        import let SomeModule.SomeGlobalConstant
        import var SomeModule.SomeGlobalVariable
        import func SomeModule.SomeFunc

        struct Foo {
            init() {}
            public func instanceMethod() {}
        }
        """

        let originalTokens = tokenize(input)
        let declarations = Formatter(originalTokens).parseDeclarations()

        XCTAssertEqual(declarations[0].keyword, "import")
        XCTAssertEqual(declarations[1].keyword, "import")
        XCTAssertEqual(declarations[2].keyword, "import")
        XCTAssertEqual(declarations[3].keyword, "import")
        XCTAssertEqual(declarations[4].keyword, "import")
        XCTAssertEqual(declarations[5].keyword, "import")
        XCTAssertEqual(declarations[6].keyword, "import")
        XCTAssertEqual(declarations[7].keyword, "import")
        XCTAssertEqual(declarations[8].keyword, "struct")
        XCTAssertEqual(declarations[8].body?[0].keyword, "init")
        XCTAssertEqual(declarations[8].body?[1].keyword, "func")
    }

    func testClassOverrideDoesntCrashParseDeclarations() {
        let input = """
        class Foo {
            var bar: Int?
            class override var baz: String
        }
        """
        let tokens = tokenize(input)
        _ = Formatter(tokens).parseDeclarations()
    }

    // MARK: declarationScope

    func testDeclarationScope_classAndGlobals() {
        let input = """
        let foo = Foo()

        class Foo {
            let instanceMember = Bar()
        }

        let bar = Bar()
        """

        let tokens = tokenize(input)
        let formatter = Formatter(tokens)

        XCTAssertEqual(formatter.declarationScope(at: 3), .global) // foo
        XCTAssertEqual(formatter.declarationScope(at: 20), .type) // instanceMember
        XCTAssertEqual(formatter.declarationScope(at: 33), .global) // bar
    }

    func testDeclarationScope_classAndLocal() {
        let input = """
        class Foo {
            let instanceMember1 = Bar()

            var instanceMember2: Bar = {
                Bar()
            }

            func instanceMethod() {
                let localMember1 = Bar()
            }

            let instanceMember3 = Bar()
        }
        """

        let tokens = tokenize(input)
        let formatter = Formatter(tokens)

        XCTAssertEqual(formatter.declarationScope(at: 9), .type) // instanceMember1
        XCTAssertEqual(formatter.declarationScope(at: 21), .type) // instanceMember2
        XCTAssertEqual(formatter.declarationScope(at: 31), .local) // Bar()
        XCTAssertEqual(formatter.declarationScope(at: 42), .type) // instanceMethod
        XCTAssertEqual(formatter.declarationScope(at: 51), .local) // localMember1
        XCTAssertEqual(formatter.declarationScope(at: 66), .type) // instanceMember3
    }

    // MARK: spaceEquivalentToWidth

    func testSpaceEquivalentToWidth() {
        let formatter = Formatter([])
        XCTAssertEqual(formatter.spaceEquivalentToWidth(10), "          ")
    }

    func testSpaceEquivalentToWidthWithTabs() {
        let options = FormatOptions(indent: "\t", tabWidth: 4, smartTabs: false)
        let formatter = Formatter([], options: options)
        XCTAssertEqual(formatter.spaceEquivalentToWidth(10), "\t\t  ")
    }

    // MARK: spaceEquivalentToTokens

    func testSpaceEquivalentToCode() {
        let tokens = tokenize("let a = b + c")
        let formatter = Formatter(tokens)
        XCTAssertEqual(formatter.spaceEquivalentToTokens(from: 0, upTo: tokens.count),
                       "             ")
    }

    func testSpaceEquivalentToImageLiteral() {
        let tokens = tokenize("let a = #imageLiteral(resourceName: \"abc.png\")")
        let formatter = Formatter(tokens)
        XCTAssertEqual(formatter.spaceEquivalentToTokens(from: 0, upTo: tokens.count),
                       "          ")
    }

    // MARK: startOfConditionalStatement

    func testIfTreatedAsConditional() {
        let formatter = Formatter(tokenize("if bar == baz {}"))
        for i in formatter.tokens.indices.dropLast(2) {
            XCTAssertEqual(formatter.startOfConditionalStatement(at: i), 0)
        }
    }

    func testIfLetTreatedAsConditional() {
        let formatter = Formatter(tokenize("if let bar = baz {}"))
        for i in formatter.tokens.indices.dropLast(2) {
            XCTAssertEqual(formatter.startOfConditionalStatement(at: i), 0)
        }
    }

    func testGuardLetTreatedAsConditional() {
        let formatter = Formatter(tokenize("guard let foo = bar else {}"))
        for i in formatter.tokens.indices.dropLast(4) {
            XCTAssertEqual(formatter.startOfConditionalStatement(at: i), 0)
        }
    }

    func testLetNotTreatedAsConditional() {
        let formatter = Formatter(tokenize("let foo = bar, bar = baz"))
        for i in formatter.tokens.indices {
            XCTAssertNil(formatter.startOfConditionalStatement(at: i))
        }
    }

    func testEnumCaseNotTreatedAsConditional() {
        let formatter = Formatter(tokenize("enum Foo { case bar }"))
        for i in formatter.tokens.indices {
            XCTAssertNil(formatter.startOfConditionalStatement(at: i))
        }
    }

    func testStartOfConditionalStatementConditionContainingUnParenthesizedClosure() {
        let formatter = Formatter(tokenize("""
        if let btn = btns.first { !$0.isHidden } {}
        """))
        XCTAssertEqual(formatter.startOfConditionalStatement(at: 12), 0)
        XCTAssertEqual(formatter.startOfConditionalStatement(at: 21), 0)
    }

    // MARK: isStartOfStatement

    func testAsyncAfterFuncNotTreatedAsStartOfStatement() {
        let formatter = Formatter(tokenize("""
        func foo()
            async
        """))
        XCTAssertFalse(formatter.isStartOfStatement(at: 7))
    }

    func testAsyncLetTreatedAsStartOfStatement() {
        let formatter = Formatter(tokenize("""
        async let foo = bar()
        """))
        XCTAssert(formatter.isStartOfStatement(at: 0))
    }

    func testAsyncIdentifierTreatedAsStartOfStatement() {
        let formatter = Formatter(tokenize("""
        func async() {}
        async()
        """))
        XCTAssert(formatter.isStartOfStatement(at: 9))
    }

    func testAsyncIdentifierNotTreatedAsStartOfStatement() {
        let formatter = Formatter(tokenize("""
        func async() {}
        let foo =
            async()
        """))
        XCTAssertFalse(formatter.isStartOfStatement(at: 16))
    }

    func testNumericFunctionArgumentNotTreatedAsStartOfStatement() {
        let formatter = Formatter(tokenize("""
        let foo = bar(
            200
        )
        """))
        XCTAssertFalse(formatter.isStartOfStatement(at: 10, treatingCollectionKeysAsStart: false))
    }

    func testStringLiteralFunctionArgumentNotTreatedAsStartOfStatement() {
        let formatter = Formatter(tokenize("""
        let foo = bar(
            "baz"
        )
        """))
        XCTAssertFalse(formatter.isStartOfStatement(at: 10, treatingCollectionKeysAsStart: false))
    }

    // MARK: - parseTypes

    func testParseSimpleType() {
        let formatter = Formatter(tokenize("""
        let foo: Foo = .init()
        """))
        XCTAssertEqual(formatter.parseType(at: 5)?.name, "Foo")
    }

    func testParseOptionalType() {
        let formatter = Formatter(tokenize("""
        let foo: Foo? = .init()
        """))
        XCTAssertEqual(formatter.parseType(at: 5)?.name, "Foo?")
    }

    func testParseIOUType() {
        let formatter = Formatter(tokenize("""
        let foo: Foo! = .init()
        """))
        XCTAssertEqual(formatter.parseType(at: 5)?.name, "Foo!")
    }

    func testDoesntParseTernaryOperatorAsType() {
        let formatter = Formatter(tokenize("""
        Foo.bar ? .foo : .bar
        """))
        XCTAssertEqual(formatter.parseType(at: 0)?.name, "Foo.bar")
    }

    func testParseGenericType() {
        let formatter = Formatter(tokenize("""
        let foo: Foo<Bar, Baaz> = .init()
        """))
        XCTAssertEqual(formatter.parseType(at: 5)?.name, "Foo<Bar, Baaz>")
    }

    func testParseOptionalGenericType() {
        let formatter = Formatter(tokenize("""
        let foo: Foo<Bar, Baaz>? = .init()
        """))
        XCTAssertEqual(formatter.parseType(at: 5)?.name, "Foo<Bar, Baaz>?")
    }

    func testParseDictionaryType() {
        let formatter = Formatter(tokenize("""
        let foo: [Foo: Bar] = [:]
        """))
        XCTAssertEqual(formatter.parseType(at: 5)?.name, "[Foo: Bar]")
    }

    func testParseOptionalDictionaryType() {
        let formatter = Formatter(tokenize("""
        let foo: [Foo: Bar]? = [:]
        """))
        XCTAssertEqual(formatter.parseType(at: 5)?.name, "[Foo: Bar]?")
    }

    func testParseTupleType() {
        let formatter = Formatter(tokenize("""
        let foo: (Foo, Bar) = (Foo(), Bar())
        """))
        XCTAssertEqual(formatter.parseType(at: 5)?.name, "(Foo, Bar)")
    }

    func testParseClosureType() {
        let formatter = Formatter(tokenize("""
        let foo: (Foo, Bar) -> (Foo, Bar) = { foo, bar in (foo, bar) }
        """))
        XCTAssertEqual(formatter.parseType(at: 5)?.name, "(Foo, Bar) -> (Foo, Bar)")
    }

    func testParseClosureTypeWithOwnership() {
        let formatter = Formatter(tokenize("""
        let foo: (consuming Foo, borrowing Bar) -> (Foo, Bar) = { foo, bar in (foo, bar) }
        """))
        XCTAssertEqual(formatter.parseType(at: 5)?.name, "(consuming Foo, borrowing Bar) -> (Foo, Bar)")
    }

    func testParseOptionalReturningClosureType() {
        let formatter = Formatter(tokenize("""
        let foo: (Foo, Bar) -> (Foo, Bar)? = { foo, bar in (foo, bar) }
        """))
        XCTAssertEqual(formatter.parseType(at: 5)?.name, "(Foo, Bar) -> (Foo, Bar)?")
    }

    func testParseOptionalClosureType() {
        let formatter = Formatter(tokenize("""
        let foo: ((Foo, Bar) -> (Foo, Bar)?)? = { foo, bar in (foo, bar) }
        """))
        XCTAssertEqual(formatter.parseType(at: 5)?.name, "((Foo, Bar) -> (Foo, Bar)?)?")
    }

    func testParseOptionalClosureTypeWithOwnership() {
        let formatter = Formatter(tokenize("""
        let foo: ((consuming Foo, borrowing Bar) -> (Foo, Bar)?)? = { foo, bar in (foo, bar) }
        """))
        XCTAssertEqual(formatter.parseType(at: 5)?.name, "((consuming Foo, borrowing Bar) -> (Foo, Bar)?)?")
    }

    func testParseExistentialAny() {
        let formatter = Formatter(tokenize("""
        let foo: any Foo
        """))
        XCTAssertEqual(formatter.parseType(at: 5)?.name, "any Foo")
    }

    func testParseCompoundType() {
        let formatter = Formatter(tokenize("""
        let foo: Foo.Bar.Baaz
        """))
        XCTAssertEqual(formatter.parseType(at: 5)?.name, "Foo.Bar.Baaz")
    }

    func testParseCompoundGenericType() {
        let formatter = Formatter(tokenize("""
        let foo: Foo<Bar>.Bar.Baaz<Quux.V2>
        """))
        XCTAssertEqual(formatter.parseType(at: 5)?.name, "Foo<Bar>.Bar.Baaz<Quux.V2>")
    }

    func testParseExistentialTypeWithSubtype() {
        let formatter = Formatter(tokenize("""
        let foo: (any Foo).Bar.Baaz
        """))
        XCTAssertEqual(formatter.parseType(at: 5)?.name, "(any Foo).Bar.Baaz")
    }

    func testParseOpaqueReturnType() {
        let formatter = Formatter(tokenize("""
        var body: some View { EmptyView() }
        """))
        XCTAssertEqual(formatter.parseType(at: 5)?.name, "some View")
    }

    func testParseInvalidType() {
        let formatter = Formatter(tokenize("""
        let foo = { foo, bar in (foo, bar) }
        """))
        XCTAssertEqual(formatter.parseType(at: 4)?.name, nil)
        XCTAssertEqual(formatter.parseType(at: 5)?.name, nil)
        XCTAssertEqual(formatter.parseType(at: 6)?.name, nil)
        XCTAssertEqual(formatter.parseType(at: 7)?.name, nil)
    }

    func testEndOfDeclaration() {
        let formatter = Formatter(tokenize("""
        public enum MyFeatureCacheStrategy {
          case networkOnly
          case cacheFirst

          public static let defaultCacheAge: TimeInterval = .minutes(5)

          public func requestStrategy<Outcome>() -> SingleRequestStrategy<Outcome> {
            switch self {
            case .networkOnly:
              return .networkOnly(writeResultToCache: true)
            case .cacheFirst:
              return .cacheFirst(maxCacheAge: Self.defaultCacheAge)
            }
          }
        }
        """))

        XCTAssertEqual(formatter.endOfDeclaration(atDeclarationKeyword: 24), 39) // let defaultCacheAge
        XCTAssertEqual(formatter.endOfDeclaration(atDeclarationKeyword: 43), 112) // func requestStrategy
    }

    // MARK: - parseExpressionRange

    func testParseIndividualExpressions() {
        XCTAssert(isSingleExpression(#"Foo()"#))
        XCTAssert(isSingleExpression(#"Foo("bar")"#))
        XCTAssert(isSingleExpression(#"Foo.init()"#))
        XCTAssert(isSingleExpression(#"Foo.init("bar")"#))
        XCTAssert(isSingleExpression(#"foo.bar"#))
        XCTAssert(isSingleExpression(#"foo .bar"#))
        XCTAssert(isSingleExpression(#"foo["bar"]("baaz")"#))
        XCTAssert(isSingleExpression(#"foo().bar().baaz[]().bar"#))
        XCTAssert(isSingleExpression(#"foo?.bar?().baaz!.quux ?? """#))
        XCTAssert(isSingleExpression(#"1"#))
        XCTAssert(isSingleExpression(#"10.0"#))
        XCTAssert(isSingleExpression(#"10000"#))
        XCTAssert(isSingleExpression(#"-24.0"#))
        XCTAssert(isSingleExpression(#"3.14e2"#))
        XCTAssert(isSingleExpression(#"1 + 2"#))
        XCTAssert(isSingleExpression(#"-0.05 * 10"#))
        XCTAssert(isSingleExpression(#"0...10"#))
        XCTAssert(isSingleExpression(#"0..<20"#))
        XCTAssert(isSingleExpression(#"0 ... array.indices.last"#))
        XCTAssert(isSingleExpression(#"true"#))
        XCTAssert(isSingleExpression(#"false"#))
        XCTAssert(isSingleExpression(#"!boolean"#))
        XCTAssert(isSingleExpression(#"boolean || !boolean && boolean"#))
        XCTAssert(isSingleExpression(#"boolean ? value : value"#))
        XCTAssert(isSingleExpression(#"foo"#))
        XCTAssert(isSingleExpression(#""foo""#))
        XCTAssert(isSingleExpression(##"#"raw string"#"##))
        XCTAssert(isSingleExpression(###"##"raw string"##"###))
        XCTAssert(isSingleExpression(#"["foo", "bar"]"#))
        XCTAssert(isSingleExpression(#"["foo": bar]"#))
        XCTAssert(isSingleExpression(#"(tuple: "foo", bar: "baaz")"#))
        XCTAssert(isSingleExpression(#"foo.bar { "baaz"}"#))
        XCTAssert(isSingleExpression(#"foo.bar({ "baaz" })"#))
        XCTAssert(isSingleExpression(#"foo.bar() { "baaz" }"#))
        XCTAssert(isSingleExpression(#"foo.bar { "baaz" } anotherTrailingClosure: { "quux" }"#))
        XCTAssert(isSingleExpression(#"try foo()"#))
        XCTAssert(isSingleExpression(#"try! foo()"#))
        XCTAssert(isSingleExpression(#"try? foo()"#))
        XCTAssert(isSingleExpression(#"try await foo()"#))
        XCTAssert(isSingleExpression(#"foo is Foo"#))
        XCTAssert(isSingleExpression(#"foo as Foo"#))
        XCTAssert(isSingleExpression(#"foo as? Foo"#))
        XCTAssert(isSingleExpression(#"foo as! Foo"#))
        XCTAssert(isSingleExpression(#"foo ? bar : baaz"#))
        XCTAssert(isSingleExpression(#".implicitMember"#))
        XCTAssert(isSingleExpression(#"\Foo.explicitKeypath"#))
        XCTAssert(isSingleExpression(#"\.inferredKeypath"#))
        XCTAssert(isSingleExpression(#"#selector(Foo.bar)"#))
        XCTAssert(isSingleExpression(#"#macro()"#))
        XCTAssert(isSingleExpression(#"#outerMacro(12, #innerMacro(34), "some text")"#))
        XCTAssert(isSingleExpression(#"try { try printThrows(foo) }()"#))
        XCTAssert(isSingleExpression(#"try! { try printThrows(foo) }()"#))
        XCTAssert(isSingleExpression(#"try? { try printThrows(foo) }()"#))
        XCTAssert(isSingleExpression(#"await { await printAsync(foo) }()"#))
        XCTAssert(isSingleExpression(#"try await { try await printAsyncThrows(foo) }()"#))
        XCTAssert(isSingleExpression(#"Foo<Bar>()"#))
        XCTAssert(isSingleExpression(#"Foo<Bar, Baaz>(quux: quux)"#))
        XCTAssert(!isSingleExpression(#"if foo { "foo" } else { "bar" }"#))
        XCTAssert(!isSingleExpression(#"foo.bar, baaz.quux"#))

        XCTAssert(isSingleExpression(
            #"if foo { "foo" } else { "bar" }"#,
            allowConditionalExpressions: true
        ))

        XCTAssert(isSingleExpression("""
        if foo {
          "foo"
        } else {
          "bar"
        }
        """, allowConditionalExpressions: true))

        XCTAssert(isSingleExpression("""
        switch foo {
        case true:
            "foo"
        case false:
            "bar"
        }
        """, allowConditionalExpressions: true))

        XCTAssert(isSingleExpression("""
        foo
            .bar
        """))

        XCTAssert(isSingleExpression("""
        foo?
            .bar?()
            .baaz![0]
        """))

        XCTAssert(isSingleExpression(#"""
        """
        multi-line string
        """
        """#))

        XCTAssert(isSingleExpression(##"""
        #"""
        raw multi-line string
        """#
        """##))

        XCTAssertFalse(isSingleExpression(#"foo = bar"#))
        XCTAssertFalse(isSingleExpression(#"foo = "foo"#))
        XCTAssertFalse(isSingleExpression(#"10 20 30"#))
        XCTAssertFalse(isSingleExpression(#"foo bar"#))
        XCTAssertFalse(isSingleExpression(#"foo? bar"#))

        XCTAssertFalse(isSingleExpression("""
        foo
            () // if you have a linebreak before a method call, its parsed as a tuple
        """))

        XCTAssertFalse(isSingleExpression("""
        foo
            [0] // if you have a linebreak before a subscript, its invalid
        """))

        XCTAssertFalse(isSingleExpression("""
        #if DEBUG
        foo
        #else
        bar
        #endif
        """))
    }

    func testParseMultipleSingleLineExpressions() {
        let input = """
        foo
        foo?.bar().baaz()
        24
        !foo
        methodCall()
        foo ?? bar ?? baaz
        """

        // Each line is a single expression
        let expectedExpressions = input.components(separatedBy: "\n")
        XCTAssertEqual(parseExpressions(input), expectedExpressions)
    }

    func testParseMultipleLineExpressions() {
        let input = """
        [
            "foo",
            "bar"
        ].map {
            $0.uppercased()
        }

        foo?.bar().methodCall(
            foo: foo,
            bar: bar)

        foo.multipleTrailingClosure {
            print("foo")
        } anotherTrailingClosure: {
            print("bar")
        }
        """

        let expectedExpressions = [
            """
            [
                "foo",
                "bar"
            ].map {
                $0.uppercased()
            }
            """,
            """
            foo?.bar().methodCall(
                foo: foo,
                bar: bar)
            """,
            """
            foo.multipleTrailingClosure {
                print("foo")
            } anotherTrailingClosure: {
                print("bar")
            }
            """,
        ]

        XCTAssertEqual(parseExpressions(input), expectedExpressions)
    }

    func testParsedExpressionInIfConditionExcludesConditionBody() {
        let input = """
        if let bar = foo.bar {
          print(bar)
        }

        if foo.contains(where: { $0.isEmpty }) {
          print("Empty foo")
        }
        """

        XCTAssertEqual(parseExpression(in: input, at: 8), "foo.bar")
        XCTAssertEqual(parseExpression(in: input, at: 25), "foo.contains(where: { $0.isEmpty })")
    }

    func testParsedExpressionInIfConditionExcludesConditionBody_trailingClosureEdgeCase() {
        // This code is generally considered an anti-pattern, and outputs the following warning when compiled:
        // warning: trailing closure in this context is confusable with the body of the statement; pass as a parenthesized argument to silence this warning
        let input = """
        if foo.contains { $0.isEmpty } {
          print("Empty foo")
        }
        """

        // We don't bother supporting this, since it would increase the complexity of the parser.
        // A more correct result would be `foo.contains { $0.isEmpty }`.
        XCTAssertEqual(parseExpression(in: input, at: 2), "foo.contains")
    }

    func isSingleExpression(_ string: String, allowConditionalExpressions: Bool = false) -> Bool {
        let formatter = Formatter(tokenize(string))
        guard let expressionRange = formatter.parseExpressionRange(startingAt: 0, allowConditionalExpressions: allowConditionalExpressions) else { return false }
        return expressionRange.upperBound == formatter.tokens.indices.last!
    }

    func parseExpressions(_ string: String) -> [String] {
        let formatter = Formatter(tokenize(string))
        var expressions = [String]()

        var parseIndex = 0
        while let expressionRange = formatter.parseExpressionRange(startingAt: parseIndex) {
            let expression = formatter.tokens[expressionRange].map { $0.string }.joined()
            expressions.append(expression)

            if let nextExpressionIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: expressionRange.upperBound) {
                parseIndex = nextExpressionIndex
            } else {
                return expressions
            }
        }

        return expressions
    }

    func parseExpression(in input: String, at index: Int) -> String {
        let formatter = Formatter(tokenize(input))
        guard let expressionRange = formatter.parseExpressionRange(startingAt: index) else { return "" }
        return formatter.tokens[expressionRange].map { $0.string }.joined()
    }

    // MARK: isStoredProperty

    func testIsStoredProperty() {
        XCTAssertTrue(isStoredProperty("var foo: String"))
        XCTAssertTrue(isStoredProperty("let foo = 42"))
        XCTAssertTrue(isStoredProperty("let foo: Int = 42"))
        XCTAssertTrue(isStoredProperty("var foo: Int = 42"))
        XCTAssertTrue(isStoredProperty("@Environment(\\.myEnvironmentProperty) var foo", at: 7))

        XCTAssertTrue(isStoredProperty("""
        var foo: String {
          didSet {
            print(newValue)
          }
        }
        """))

        XCTAssertTrue(isStoredProperty("""
        var foo: String {
          willSet {
            print(newValue)
          }
        }
        """))

        XCTAssertFalse(isStoredProperty("""
        var foo: String {
            "foo"
        }
        """))

        XCTAssertFalse(isStoredProperty("""
        var foo: String {
            get { "foo" }
            set { print(newValue} }
        }
        """))
    }

    func isStoredProperty(_ input: String, at index: Int = 0) -> Bool {
        let formatter = Formatter(tokenize(input))
        return formatter.isStoredProperty(atIntroducerIndex: index)
    }
}
