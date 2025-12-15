//
//  WrapFunctionBodiesTests.swift
//  SwiftFormatTests
//
//  Created by Manuel Lopez on 12/15/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class WrapFunctionBodiesTests: XCTestCase {
    // MARK: - Functions

    func testWrapSingleLineFunctionBody() {
        let input = """
        func foo() { print("bar") }
        """
        let output = """
        func foo() {
            print("bar")
        }
        """
        testFormatting(for: input, output, rule: .wrapFunctionBodies)
    }

    func testWrapFunctionWithReturnStatement() {
        let input = """
        func getValue() -> Int { return 42 }
        """
        let output = """
        func getValue() -> Int {
            return 42
        }
        """
        testFormatting(for: input, output, rule: .wrapFunctionBodies)
    }

    func testDoesNotWrapAlreadyMultilineFunction() {
        let input = """
        func foo() {
            print("bar")
        }
        """
        testFormatting(for: input, rule: .wrapFunctionBodies)
    }

    func testDoesNotWrapEmptyFunctionBody() {
        let input = """
        func foo() {}
        """
        testFormatting(for: input, rule: .wrapFunctionBodies)
    }

    func testWrapFunctionWithSomeReturnType() {
        let input = """
        func foo() -> some View { Text("hello") }
        """
        let output = """
        func foo() -> some View {
            Text("hello")
        }
        """
        testFormatting(for: input, output, rule: .wrapFunctionBodies)
    }

    // MARK: - Initializers

    func testWrapSingleLineInit() {
        let input = """
        init() { value = 0 }
        """
        let output = """
        init() {
            value = 0
        }
        """
        testFormatting(for: input, output, rule: .wrapFunctionBodies)
    }

    func testWrapFailableInit() {
        let input = """
        init?() { return nil }
        """
        let output = """
        init?() {
            return nil
        }
        """
        testFormatting(for: input, output, rule: .wrapFunctionBodies)
    }

    // MARK: - Subscripts

    func testWrapSingleLineSubscript() {
        let input = """
        subscript(index: Int) -> Int { array[index] }
        """
        let output = """
        subscript(index: Int) -> Int {
            array[index]
        }
        """
        testFormatting(for: input, output, rule: .wrapFunctionBodies)
    }

    // MARK: - Closures (should NOT be wrapped)

    func testDoesNotWrapClosure() {
        let input = """
        let closure = { print("hello") }
        """
        testFormatting(for: input, rule: .wrapFunctionBodies)
    }

    func testDoesNotWrapClosureAsArgument() {
        let input = """
        array.map { $0 * 2 }
        """
        testFormatting(for: input, rule: .wrapFunctionBodies)
    }

    // MARK: - Computed Properties (should NOT be wrapped by this rule)

    func testDoesNotWrapComputedProperty() {
        let input = """
        var bar: String { "bar" }
        """
        testFormatting(for: input, rule: .wrapFunctionBodies, exclude: [.wrapPropertyBodies])
    }

    // MARK: - Protocols (should NOT be wrapped)

    func testDoesNotWrapFunctionInProtocol() {
        let input = """
        protocol Foo {
            func bar() -> String { "bar" }
        }
        """
        testFormatting(for: input, rule: .wrapFunctionBodies)
    }

    func testDoesNotWrapSubscriptInProtocol() {
        let input = """
        protocol Foo {
            subscript(index: Int) -> Int { get }
        }
        """
        testFormatting(for: input, rule: .wrapFunctionBodies, exclude: [.unusedArguments])
    }

    func testDoesNotWrapInitInProtocol() {
        let input = """
        protocol Foo {
            init() { }
        }
        """
        testFormatting(for: input, rule: .wrapFunctionBodies, exclude: [.emptyBraces])
    }

    // MARK: - Edge Cases

    func testWrapFunctionInClass() {
        let input = """
        class Foo {
            func bar() { print("baz") }
        }
        """
        let output = """
        class Foo {
            func bar() {
                print("baz")
            }
        }
        """
        testFormatting(for: input, output, rule: .wrapFunctionBodies)
    }
}
