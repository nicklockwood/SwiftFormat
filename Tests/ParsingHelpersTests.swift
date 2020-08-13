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

    func testDoBracesNotTreatedAsClosure() {
        let formatter = Formatter(tokenize("do {}"))
        XCTAssertFalse(formatter.isStartOfClosure(at: 2))
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

    // MARK: modifierOrder

    func testModifierOrder() {
        let options = FormatOptions(modifierOrder: ["convenience", "override"])
        let formatter = Formatter([], options: options)
        XCTAssertEqual(formatter.modifierOrder, [
            "private", "fileprivate", "internal", "public", "open",
            "private(set)", "fileprivate(set)", "internal(set)", "public(set)",
            "final", "dynamic",
            "optional", "required",
            "convenience",
            "override",
            "indirect",
            "lazy",
            "weak", "unowned",
            "static", "class",
            "mutating", "nonmutating",
            "prefix", "postfix",
        ])
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
    }

    func testProcessDeclaredVariablesInIfCondition() {
        let formatter = Formatter(tokenize("""
        if let foo = bar(), x == y, let baz = quux {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["foo", "baz"])
    }

    func testProcessDeclaredVariablesInIfWithParenthetical() {
        let formatter = Formatter(tokenize("""
        if let foo = bar(), (x == y), let baz = quux {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["foo", "baz"])
    }

    func testProcessDeclaredVariablesInIfWithClosure() {
        let formatter = Formatter(tokenize("""
        if let foo = bar(), { x == y }(), let baz = quux {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["foo", "baz"])
    }

    func testProcessDeclaredVariablesInIfWithArrayLiteral() {
        let formatter = Formatter(tokenize("""
        if let foo = bar(), [x] == y, let baz = quux {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["foo", "baz"])
    }

    func testProcessCaseDeclaredVariablesInIf() {
        let formatter = Formatter(tokenize("""
        if let foo = bar(), case .bar(var baz) = quux {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["foo", "baz"])
    }

    func testProcessCaseDeclaredVariablesInIf2() {
        let formatter = Formatter(tokenize("""
        if case let .foo(bar, baz) = quux {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["bar", "baz"])
    }

    func testProcessTupleDeclaredVariablesInIf() {
        let formatter = Formatter(tokenize("""
        if let (bar, baz) = quux, x = y {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["bar", "baz"])
    }

    func testProcessTupleDeclaredVariablesInIf2() {
        let formatter = Formatter(tokenize("""
        if let ((bar, baz), (x, y)) = quux {}
        """))
        var index = 2
        var names = Set<String>()
        formatter.processDeclaredVariables(at: &index, names: &names)
        XCTAssertEqual(names, ["bar", "baz", "x", "y"])
    }
}
