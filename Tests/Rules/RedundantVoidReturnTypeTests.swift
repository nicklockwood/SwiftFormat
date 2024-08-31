//
//  RedundantVoidReturnTypeTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 1/3/17.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class RedundantVoidReturnTypeTests: XCTestCase {
    func testRemoveRedundantVoidReturnType() {
        let input = "func foo() -> Void {}"
        let output = "func foo() {}"
        testFormatting(for: input, output, rule: .redundantVoidReturnType)
    }

    func testRemoveRedundantVoidReturnType2() {
        let input = "func foo() ->\n    Void {}"
        let output = "func foo() {}"
        testFormatting(for: input, output, rule: .redundantVoidReturnType)
    }

    func testRemoveRedundantSwiftDotVoidReturnType() {
        let input = "func foo() -> Swift.Void {}"
        let output = "func foo() {}"
        testFormatting(for: input, output, rule: .redundantVoidReturnType)
    }

    func testRemoveRedundantSwiftDotVoidReturnType2() {
        let input = "func foo() -> Swift\n    .Void {}"
        let output = "func foo() {}"
        testFormatting(for: input, output, rule: .redundantVoidReturnType)
    }

    func testRemoveRedundantEmptyReturnType() {
        let input = "func foo() -> () {}"
        let output = "func foo() {}"
        testFormatting(for: input, output, rule: .redundantVoidReturnType)
    }

    func testRemoveRedundantVoidTupleReturnType() {
        let input = "func foo() -> (Void) {}"
        let output = "func foo() {}"
        testFormatting(for: input, output, rule: .redundantVoidReturnType)
    }

    func testNoRemoveCommentFollowingRedundantVoidReturnType() {
        let input = "func foo() -> Void /* void */ {}"
        let output = "func foo() /* void */ {}"
        testFormatting(for: input, output, rule: .redundantVoidReturnType)
    }

    func testNoRemoveRequiredVoidReturnType() {
        let input = "typealias Foo = () -> Void"
        testFormatting(for: input, rule: .redundantVoidReturnType)
    }

    func testNoRemoveChainedVoidReturnType() {
        let input = "func foo() -> () -> Void {}"
        testFormatting(for: input, rule: .redundantVoidReturnType)
    }

    func testRemoveRedundantVoidInClosureArguments() {
        let input = "{ (foo: Bar) -> Void in foo() }"
        let output = "{ (foo: Bar) in foo() }"
        testFormatting(for: input, output, rule: .redundantVoidReturnType)
    }

    func testRemoveRedundantEmptyReturnTypeInClosureArguments() {
        let input = "{ (foo: Bar) -> () in foo() }"
        let output = "{ (foo: Bar) in foo() }"
        testFormatting(for: input, output, rule: .redundantVoidReturnType)
    }

    func testRemoveRedundantVoidInClosureArguments2() {
        let input = "methodWithTrailingClosure { foo -> Void in foo() }"
        let output = "methodWithTrailingClosure { foo in foo() }"
        testFormatting(for: input, output, rule: .redundantVoidReturnType)
    }

    func testRemoveRedundantSwiftDotVoidInClosureArguments2() {
        let input = "methodWithTrailingClosure { foo -> Swift.Void in foo() }"
        let output = "methodWithTrailingClosure { foo in foo() }"
        testFormatting(for: input, output, rule: .redundantVoidReturnType)
    }

    func testNoRemoveRedundantVoidInClosureArgument() {
        let input = "{ (foo: Bar) -> Void in foo() }"
        let options = FormatOptions(closureVoidReturn: .preserve)
        testFormatting(for: input, rule: .redundantVoidReturnType, options: options)
    }

    func testRemoveRedundantVoidInProtocolDeclaration() {
        let input = """
        protocol Foo {
            func foo() -> Void
            func bar() -> ()
            var baz: Int { get }
            func bazz() -> ( )
        }
        """

        let output = """
        protocol Foo {
            func foo()
            func bar()
            var baz: Int { get }
            func bazz()
        }
        """
        testFormatting(for: input, output, rule: .redundantVoidReturnType)
    }
}
