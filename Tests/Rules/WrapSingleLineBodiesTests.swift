//
//  WrapSingleLineBodiesTests.swift
//  SwiftFormatTests
//
//  Created by Manuel Lopez on 12/10/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class WrapSingleLineBodiesTests: XCTestCase {
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
        testFormatting(for: input, output, rule: .wrapSingleLineBodies)
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
        testFormatting(for: input, output, rule: .wrapSingleLineBodies)
    }

    func testWrapFunctionWithParameters() {
        let input = """
        func add(_ a: Int, _ b: Int) -> Int { a + b }
        """
        let output = """
        func add(_ a: Int, _ b: Int) -> Int {
            a + b
        }
        """
        testFormatting(for: input, output, rule: .wrapSingleLineBodies)
    }

    func testDoesNotWrapAlreadyMultilineFunction() {
        let input = """
        func foo() {
            print("bar")
        }
        """
        testFormatting(for: input, rule: .wrapSingleLineBodies)
    }

    func testDoesNotWrapEmptyFunctionBody() {
        let input = """
        func foo() {}
        """
        testFormatting(for: input, rule: .wrapSingleLineBodies)
    }

    // MARK: - Computed Properties

    func testWrapSingleLineComputedProperty() {
        let input = """
        var bar: String { "bar" }
        """
        let output = """
        var bar: String {
            "bar"
        }
        """
        testFormatting(for: input, output, rule: .wrapSingleLineBodies)
    }

    func testWrapComputedPropertyWithReturn() {
        let input = """
        var value: Int { return 42 }
        """
        let output = """
        var value: Int {
            return 42
        }
        """
        testFormatting(for: input, output, rule: .wrapSingleLineBodies)
    }

    func testDoesNotWrapAlreadyMultilineComputedProperty() {
        let input = """
        var bar: String {
            "bar"
        }
        """
        testFormatting(for: input, rule: .wrapSingleLineBodies)
    }

    func testDoesNotWrapStoredPropertyWithDidSet() {
        let input = """
        var value: Int = 0 { didSet { print("changed") } }
        """
        testFormatting(for: input, rule: .wrapSingleLineBodies)
    }

    func testDoesNotWrapStoredPropertyWithWillSet() {
        let input = """
        var value: Int = 0 { willSet { print("will change") } }
        """
        testFormatting(for: input, rule: .wrapSingleLineBodies)
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
        testFormatting(for: input, output, rule: .wrapSingleLineBodies)
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
        testFormatting(for: input, output, rule: .wrapSingleLineBodies)
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
        testFormatting(for: input, output, rule: .wrapSingleLineBodies)
    }

    // MARK: - Closures (should NOT be wrapped)

    func testDoesNotWrapClosure() {
        let input = """
        let closure = { print("hello") }
        """
        testFormatting(for: input, rule: .wrapSingleLineBodies)
    }

    func testDoesNotWrapClosureAsArgument() {
        let input = """
        array.map { $0 * 2 }
        """
        testFormatting(for: input, rule: .wrapSingleLineBodies)
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
        testFormatting(for: input, output, rule: .wrapSingleLineBodies)
    }

    func testWrapComputedPropertyInStruct() {
        let input = """
        struct Foo {
            var bar: String { "bar" }
        }
        """
        let output = """
        struct Foo {
            var bar: String {
                "bar"
            }
        }
        """
        testFormatting(for: input, output, rule: .wrapSingleLineBodies)
    }

    func testWrapMultipleFunctionsOnSeparateLines() {
        let input = """
        func foo() { print("foo") }
        func bar() { print("bar") }
        """
        let output = """
        func foo() {
            print("foo")
        }
        func bar() {
            print("bar")
        }
        """
        testFormatting(for: input, output, rule: .wrapSingleLineBodies, exclude: [.blankLinesBetweenScopes])
    }

    func testWrapFunctionWithAnyReturnType() {
        let input = """
        func foo() -> any Bar { baz() }
        """
        let output = """
        func foo() -> any Bar {
            baz()
        }
        """
        testFormatting(for: input, output, rule: .wrapSingleLineBodies)
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
        testFormatting(for: input, output, rule: .wrapSingleLineBodies)
    }

    // MARK: - Protocols (should NOT be wrapped)

    func testDoesNotWrapFunctionInProtocol() {
        let input = """
        protocol Foo {
            func bar() -> String { "bar" }
        }
        """
        testFormatting(for: input, rule: .wrapSingleLineBodies)
    }

    func testDoesNotWrapComputedPropertyInProtocol() {
        let input = """
        protocol Expandable: ExpandableView {
            var expansionStateDidChange: ((Self) -> Void)? { get set }
        }
        """
        testFormatting(for: input, rule: .wrapSingleLineBodies)
    }

    func testDoesNotWrapSubscriptInProtocol() {
        let input = """
        protocol Foo {
            subscript(index: Int) -> Int { get }
        }
        """
        testFormatting(for: input, rule: .wrapSingleLineBodies, exclude: [.unusedArguments])
    }

    func testDoesNotWrapInitInProtocol() {
        let input = """
        protocol Foo {
            init() { }
        }
        """
        testFormatting(for: input, rule: .wrapSingleLineBodies, exclude: [.emptyBraces])
    }

    func testDoesNotWrapComputedPropertyInProtocolWithClassConstraint() {
        let input = """
        protocol LayoutBacked: class {
            var layoutNode: LayoutNode? { get }
        }
        """
        testFormatting(for: input, rule: .wrapSingleLineBodies)
    }
}
