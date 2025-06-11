//
//  BlankLinesAtStartOfScopeTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 2/1/18.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class BlankLinesAtStartOfScopeTests: XCTestCase {
    func testBlankLinesRemovedAtStartOfFunction() {
        let input = """
        func foo() {

            // code
        }
        """
        let output = """
        func foo() {
            // code
        }
        """
        testFormatting(for: input, output, rule: .blankLinesAtStartOfScope)
    }

    func testBlankLinesRemovedAtStartOfParens() {
        let input = """
        (

            foo: Int
        )
        """
        let output = """
        (
            foo: Int
        )
        """
        testFormatting(for: input, output, rule: .blankLinesAtStartOfScope)
    }

    func testBlankLinesRemovedAtStartOfBrackets() {
        let input = """
        [

            foo,
            bar,
        ]
        """
        let output = """
        [
            foo,
            bar,
        ]
        """
        testFormatting(for: input, output, rule: .blankLinesAtStartOfScope)
    }

    func testBlankLinesNotRemovedBetweenElementsInsideBrackets() {
        let input = """
        [foo,

         bar]
        """
        testFormatting(for: input, rule: .blankLinesAtStartOfScope, exclude: [.wrapArguments])
    }

    func testBlankLineRemovedFromStartOfTypeByDefault() {
        let input = """
        class FooTests {

            func testFoo() {}
        }
        """

        let output = """
        class FooTests {
            func testFoo() {}
        }
        """
        testFormatting(for: input, output, rule: .blankLinesAtStartOfScope)
    }

    func testBlankLinesNotRemovedFromStartOfTypeWithOptionEnabled() {
        let input = """
        class FooClass {

            func fooMethod() {}
        }

        struct FooStruct {

            func fooMethod() {}
        }

        enum FooEnum {

            func fooMethod() {}
        }

        actor FooActor {

            func fooMethod() {}
        }

        protocol FooProtocol {

            func fooMethod()
        }

        extension Array where Element == Foo {

            func fooMethod() {}
        }
        """
        testFormatting(for: input, rule: .blankLinesAtStartOfScope, options: .init(typeBlankLines: .preserve))
    }

    func testBlankLineAtStartOfScopeRemovedFromMethodInType() {
        let input = """
        class Foo {
            func bar() {

                print("hello world")
            }
        }
        """

        let output = """
        class Foo {
            func bar() {
                print("hello world")
            }
        }
        """
        testFormatting(for: input, output, rule: .blankLinesAtStartOfScope, options: .init(typeBlankLines: .preserve))
    }

    func testBlankLineInsertedAtStartOfType() {
        let input = """
        class Foo {
            func bar() {}

        }
        """
        let output = """
        class Foo {

            func bar() {}

        }
        """
        testFormatting(for: input, output, rule: .blankLinesAtStartOfScope, options: .init(typeBlankLines: .insert))
    }

    func testFalsePositive() {
        let input = """
        struct S {
            // MARK: Internal

            func g() {}

            // MARK: Private

            private func f() {}
        }
        """
        XCTAssertEqual(try lint(input, rules: [.blankLinesAtStartOfScope, .organizeDeclarations]), [])
    }

    func testRemovesBlankLineFromStartOfSwitchCase() {
        let input = """
        switch bool {

        case true:

            print("true")

        case false:

            print("false")
        }
        """

        let output = """
        switch bool {
        case true:
            print("true")

        case false:
            print("false")
        }
        """

        testFormatting(for: input, output, rule: .blankLinesAtStartOfScope)
    }

    func testRemovesBlankLineInClosureWithParams() {
        let input = """
        presenter.present(viewController, animated: animated) { animated in

            if animated {
                self?.completion()
            }
        }
        """

        let output = """
        presenter.present(viewController, animated: animated) { animated in
            if animated {
                self?.completion()
            }
        }
        """

        testFormatting(for: input, output, rule: .blankLinesAtStartOfScope)
    }

    func testRemovesBlankLineInClosureWithCapture() {
        let input = """
        presenter.present(viewController, animated: animated) { [weak self] animated in

            if animated {
                self?.completion()
            }
        }
        """

        let output = """
        presenter.present(viewController, animated: animated) { [weak self] animated in
            if animated {
                self?.completion()
            }
        }
        """

        testFormatting(for: input, output, rule: .blankLinesAtStartOfScope)
    }

    func testRemovesBlankLineInClosureWithActorAnnotion() {
        let input = """
        presenter.present(viewController, animated: animated) { @MainActor in

            if animated {
                self?.completion()
            }
        }
        """

        let output = """
        presenter.present(viewController, animated: animated) { @MainActor in
            if animated {
                self?.completion()
            }
        }
        """

        testFormatting(for: input, output, rule: .blankLinesAtStartOfScope)
    }

    func testBlankLinesInsertedAtStartOfType() {
        let input = """
        class FooClass {
            struct FooStruct {
                func nestedFunc() {}

            }

            func fooMethod() {}

        }
        """

        let output = """
        class FooClass {

            struct FooStruct {

                func nestedFunc() {}

            }

            func fooMethod() {}

        }
        """
        testFormatting(for: input, output, rule: .blankLinesAtStartOfScope, options: .init(typeBlankLines: .insert))
    }
}
