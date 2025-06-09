//
//  VoidTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 10/19/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class VoidTests: XCTestCase {
    func testEmptyParensReturnValueConvertedToVoid() {
        let input = "() -> ()"
        let output = "() -> Void"
        testFormatting(for: input, output, rule: .void)
    }

    func testSpacedParensReturnValueConvertedToVoid() {
        let input = "() -> ( \n)"
        let output = "() -> Void"
        testFormatting(for: input, output, rule: .void)
    }

    func testParensContainingCommentNotConvertedToVoid() {
        let input = "() -> ( /* Hello World */ )"
        testFormatting(for: input, rule: .void)
    }

    func testParensNotConvertedToVoidIfLocalOverrideExists() {
        let input = """
        struct Void {}
        let foo = () -> ()
        print(foo)
        """
        testFormatting(for: input, rule: .void)
    }

    func testParensRemovedAroundVoid() {
        let input = "() -> (Void)"
        let output = "() -> Void"
        testFormatting(for: input, output, rule: .void)
    }

    func testVoidArgumentConvertedToEmptyParens() {
        let input = "Void -> Void"
        let output = "() -> Void"
        testFormatting(for: input, output, rule: .void)
    }

    func testVoidArgumentInParensNotConvertedToEmptyParens() {
        let input = "(Void) -> Void"
        testFormatting(for: input, rule: .void)
    }

    func testAnonymousVoidArgumentNotConvertedToEmptyParens() {
        let input = "{ (_: Void) -> Void in }"
        testFormatting(for: input, rule: .void, exclude: [.redundantVoidReturnType])
    }

    func testFuncWithAnonymousVoidArgumentNotStripped() {
        let input = "func foo(_: Void) -> Void"
        testFormatting(for: input, rule: .void)
    }

    func testFunctionThatReturnsAFunction() {
        let input = "(Void) -> Void -> ()"
        let output = "(Void) -> () -> Void"
        testFormatting(for: input, output, rule: .void)
    }

    func testFunctionThatReturnsAFunctionThatThrows() {
        let input = "(Void) -> Void throws -> ()"
        let output = "(Void) -> () throws -> Void"
        testFormatting(for: input, output, rule: .void)
    }

    func testFunctionThatReturnsAFunctionThatHasTypedThrows() {
        let input = "(Void) -> Void throws(Foo) -> ()"
        let output = "(Void) -> () throws(Foo) -> Void"
        testFormatting(for: input, output, rule: .void)
    }

    func testChainOfFunctionsIsNotChanged() {
        let input = "() -> () -> () -> Void"
        testFormatting(for: input, rule: .void)
    }

    func testChainOfFunctionsWithThrowsIsNotChanged() {
        let input = "() -> () throws -> () throws -> Void"
        testFormatting(for: input, rule: .void)
    }

    func testChainOfFunctionsWithTypedThrowsIsNotChanged() {
        let input = "() -> () throws(Foo) -> () throws(Foo) -> Void"
        testFormatting(for: input, rule: .void)
    }

    func testVoidThrowsIsNotMangled() {
        let input = "(Void) throws -> Void"
        testFormatting(for: input, rule: .void)
    }

    func testVoidTypedThrowsIsNotMangled() {
        let input = "(Void) throws(Foo) -> Void"
        testFormatting(for: input, rule: .void)
    }

    func testEmptyClosureArgsNotMangled() {
        let input = "{ () in }"
        testFormatting(for: input, rule: .void)
    }

    func testEmptyClosureReturnValueConvertedToVoid() {
        let input = "{ () -> () in }"
        let output = "{ () -> Void in }"
        testFormatting(for: input, output, rule: .void, exclude: [.redundantVoidReturnType])
    }

    func testAnonymousVoidClosureNotChanged() {
        let input = "{ (_: Void) in }"
        testFormatting(for: input, rule: .void, exclude: [.unusedArguments])
    }

    func testVoidLiteralConvertedToParens() {
        let input = "foo(Void())"
        let output = "foo(())"
        testFormatting(for: input, output, rule: .void)
    }

    func testVoidLiteralConvertedToParens2() {
        let input = "let foo = Void()"
        let output = "let foo = ()"
        testFormatting(for: input, output, rule: .void)
    }

    func testVoidLiteralReturnValueConvertedToParens() {
        let input = """
        func foo() {
            return Void()
        }
        """
        let output = """
        func foo() {
            return ()
        }
        """
        testFormatting(for: input, output, rule: .void)
    }

    func testVoidLiteralReturnValueConvertedToParens2() {
        let input = "{ _ in Void() }"
        let output = "{ _ in () }"
        testFormatting(for: input, output, rule: .void)
    }

    func testNamespacedVoidLiteralNotConverted() {
        // TODO: it should actually be safe to convert Swift.Void - only unsafe for other namespaces
        let input = "let foo = Swift.Void()"
        testFormatting(for: input, rule: .void)
    }

    func testMalformedFuncDoesNotCauseInvalidOutput() throws {
        let input = "func baz(Void) {}"
        testFormatting(for: input, rule: .void)
    }

    func testEmptyParensInGenericsConvertedToVoid() {
        let input = "Foo<(), ()>"
        let output = "Foo<Void, Void>"
        testFormatting(for: input, output, rule: .void)
    }

    func testCaseVoidNotUnwrapped() {
        let input = "case some(Void)"
        testFormatting(for: input, rule: .void)
    }

    func testLocalVoidTypeNotConverted() {
        let input = """
        struct Void {}
        let foo = Void()
        print(foo)
        """
        testFormatting(for: input, rule: .void)
    }

    func testLocalVoidTypeForwardReferenceNotConverted() {
        let input = """
        let foo = Void()
        print(foo)
        struct Void {}
        """
        testFormatting(for: input, rule: .void)
    }

    func testLocalVoidTypealiasNotConverted() {
        let input = """
        typealias Void = MyVoid
        let foo = Void()
        print(foo)
        """
        testFormatting(for: input, rule: .void)
    }

    func testLocalVoidTypealiasForwardReferenceNotConverted() {
        let input = """
        let foo = Void()
        print(foo)
        typealias Void = MyVoid
        """
        testFormatting(for: input, rule: .void)
    }

    // useVoid = false

    func testUseVoidOptionFalse() {
        let input = "(Void) -> Void"
        let output = "(()) -> ()"
        let options = FormatOptions(useVoid: false)
        testFormatting(for: input, output, rule: .void, options: options)
    }

    func testNamespacedVoidNotConverted() {
        let input = "() -> Swift.Void"
        let options = FormatOptions(useVoid: false)
        testFormatting(for: input, rule: .void, options: options)
    }

    func testTypealiasVoidNotConverted() {
        let input = "public typealias Void = ()"
        let options = FormatOptions(useVoid: false)
        testFormatting(for: input, rule: .void, options: options)
    }

    func testVoidClosureReturnValueConvertedToEmptyTuple() {
        let input = "{ () -> Void in }"
        let output = "{ () -> () in }"
        let options = FormatOptions(useVoid: false)
        testFormatting(for: input, output, rule: .void, options: options, exclude: [.redundantVoidReturnType])
    }

    func testNoConvertVoidSelfToTuple() {
        let input = "Void.self"
        let options = FormatOptions(useVoid: false)
        testFormatting(for: input, rule: .void, options: options)
    }

    func testNoConvertVoidTypeToTuple() {
        let input = "Void.Type"
        let options = FormatOptions(useVoid: false)
        testFormatting(for: input, rule: .void, options: options)
    }

    func testCaseVoidConvertedToTuple() {
        let input = "case some(Void)"
        let output = "case some(())"
        let options = FormatOptions(useVoid: false)
        testFormatting(for: input, output, rule: .void, options: options)
    }

    func testTypealiasEmptyTupleConvertedToVoid() {
        let input = "public typealias Dependencies = ()"
        let output = "public typealias Dependencies = Void"
        testFormatting(for: input, output, rule: .void)
    }
}
