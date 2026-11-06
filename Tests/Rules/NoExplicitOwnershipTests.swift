//
//  NoExplicitOwnershipTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 8/27/23.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class NoExplicitOwnershipTests: XCTestCase {
    func testRemovesOwnershipKeywordsFromFunc() {
        let input = """
        consuming func myMethod(consuming foo: consuming Foo, borrowing bars: borrowing [Bar]) {}
        borrowing func myMethod(consuming foo: consuming Foo, borrowing bars: borrowing [Bar]) {}
        """

        let output = """
        func myMethod(consuming foo: Foo, borrowing bars: [Bar]) {}
        func myMethod(consuming foo: Foo, borrowing bars: [Bar]) {}
        """

        testFormatting(for: input, output, rule: .noExplicitOwnership, exclude: [.unusedArguments])
    }

    func testRemovesOwnershipKeywordsFromClosure() {
        let input = """
        foos.map { (foo: consuming Foo) in
            foo.bar
        }

        foos.map { (foo: borrowing Foo) in
            foo.bar
        }
        """

        let output = """
        foos.map { (foo: Foo) in
            foo.bar
        }

        foos.map { (foo: Foo) in
            foo.bar
        }
        """

        testFormatting(for: input, output, rule: .noExplicitOwnership)
    }

    func testRemovesOwnershipKeywordsFromType() {
        let input = """
        let consuming: (consuming Foo) -> Bar
        let borrowing: (borrowing Foo) -> Bar
        """

        let output = """
        let consuming: (Foo) -> Bar
        let borrowing: (Foo) -> Bar
        """

        testFormatting(for: input, output, rule: .noExplicitOwnership)
    }

    func testDoesntRemoveOwnershipKeywordsFromNoncopyableType() {
        let input = """
        struct Foo: Sendable, ~Copyable {
            var bar: Bar?

            consuming func take() -> Bar? {
                bar.take()
            }

            borrowing func peek() -> Bar? {
                bar
            }
        }

        func baz(_ foo: consuming Foo, quux: borrowing Foo?) {}
        """

        let output = """
        struct Foo: Sendable, ~Copyable {
            var bar: Bar?

            consuming func take() -> Bar? {
                bar.take()
            }

            func peek() -> Bar? {
                bar
            }
        }

        func baz(_ foo: consuming Foo, quux: borrowing Foo?) {}
        """

        testFormatting(for: input, output, rule: .noExplicitOwnership,
                       exclude: [.unusedArguments, .redundantSendable])
    }

    func testDoesntRemoveOwnershipKeywordsFromNoncopyableGenericParameter() {
        let input = """
        struct Box<Value: ~Copyable>: ~Copyable {
            var value: Value

            init(value: consuming Value) {
                self.value = value
            }
        }

        func foo<T: ~Copyable>(_ value: consuming T) -> T {
            value
        }

        func bar<U>(_ value: borrowing U) -> Int where U: ~Copyable {
            0
        }

        protocol Baz {
            associatedtype Element: ~Copyable
            func quux(_ element: consuming Element)
        }
        """

        testFormatting(for: input, rule: .noExplicitOwnership,
                       exclude: [.unusedArguments, .simplifyGenericConstraints])
    }

    func testDoesntRemoveConsumingFromMethodWithNoncopyableSelf() {
        let input = """
        extension Foo where Self: ~Copyable {
            consuming func bar() -> Self {
                self
            }

            borrowing func baz() {}
        }
        """

        let output = """
        extension Foo where Self: ~Copyable {
            consuming func bar() -> Self {
                self
            }

            func baz() {}
        }
        """

        testFormatting(for: input, output, rule: .noExplicitOwnership)
    }

    func testDoesntRemoveOwnershipKeywordsFromSelfParameterOfNoncopyableType() {
        let input = """
        extension RigidArray where Element: ~Copyable {
            public func isTriviallyIdentical(to other: borrowing Self) -> Bool {
                _count == other._count
            }

            public static func == (left: borrowing Self, right: borrowing Self) -> Bool {
                left.span == right.span
            }
        }

        extension Array {
            func isIdentical(to other: borrowing Self) -> Bool {
                count == other.count
            }
        }
        """

        let output = """
        extension RigidArray where Element: ~Copyable {
            public func isTriviallyIdentical(to other: borrowing Self) -> Bool {
                _count == other._count
            }

            public static func == (left: borrowing Self, right: borrowing Self) -> Bool {
                left.span == right.span
            }
        }

        extension Array {
            func isIdentical(to other: Self) -> Bool {
                count == other.count
            }
        }
        """

        testFormatting(for: input, output, rule: .noExplicitOwnership)
    }

    func testProjectDoesntRemoveOwnershipKeywordsFromSelfParameterOfNoncopyableTypeInAnotherFile() throws {
        let declarations = """
        struct Foo: ~Copyable {}
        struct Bar {}
        """

        let input = """
        extension Foo {
            func isIdentical(to other: borrowing Self) -> Bool { true }
        }

        extension Bar {
            func isIdentical(to other: borrowing Self) -> Bool { true }
        }
        """

        let output = """
        extension Foo {
            func isIdentical(to other: borrowing Self) -> Bool { true }
        }

        extension Bar {
            func isIdentical(to other: Self) -> Bool { true }
        }
        """

        try testProjectFormatting(for: input, output, declarations: declarations)
    }

    func testProjectDoesntRemoveOwnershipKeywordsFromNoncopyableTypeInAnotherFile() throws {
        let declarations = """
        struct Foo: ~Copyable {}
        struct Bar {}
        """

        let input = """
        extension Foo {
            consuming func take() -> Foo { self }
        }

        extension Bar {
            consuming func take() -> Bar { self }
        }

        func baz(_ foo: consuming Foo, _ bar: consuming Bar) {}
        """

        let output = """
        extension Foo {
            consuming func take() -> Foo { self }
        }

        extension Bar {
            func take() -> Bar { self }
        }

        func baz(_ foo: consuming Foo, _ bar: Bar) {}
        """

        try testProjectFormatting(for: input, output, declarations: declarations)
    }

    private func testProjectFormatting(
        for input: String,
        _ output: String,
        declarations: String,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        _ = FormatRules.all
        let declarationsURL = URL(fileURLWithPath: "/Project/Sources/App/Declarations.swift")
        let inputURL = URL(fileURLWithPath: "/Project/Sources/App/Input.swift")
        let projectIndex = ProjectIndex(files: [
            declarationsURL.path: makeSourceFileIndex(from: declarations, moduleIdentifiers: ["App"]),
            inputURL.path: makeSourceFileIndex(from: input, moduleIdentifiers: ["App"]),
        ])
        let result = try applyRules(
            [.noExplicitOwnership],
            to: tokenize(input),
            with: .default,
            trackChanges: false,
            range: nil,
            context: FormattingContext(currentFileURL: inputURL, projectIndex: projectIndex)
        )
        XCTAssertEqual(sourceCode(for: result.tokens), output, file: file, line: line)
    }
}
