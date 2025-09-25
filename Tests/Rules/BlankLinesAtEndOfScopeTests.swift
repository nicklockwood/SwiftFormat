//
//  BlankLinesAtEndOfScopeTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 8/30/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class BlankLinesAtEndOfScopeTests: XCTestCase {
    func testBlankLinesRemovedAtEndOfFunction() {
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

        testFormatting(for: input, output, rule: .blankLinesAtEndOfScope)
    }

    func testBlankLinesRemovedAtEndOfParens() {
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
        testFormatting(for: input, output, rule: .blankLinesAtEndOfScope)
    }

    func testBlankLinesRemovedAtEndOfBrackets() {
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

        testFormatting(for: input, output, rule: .blankLinesAtEndOfScope)
    }

    func testBlankLineNotRemovedBeforeElse() {
        let input = """
        if x {
            // do something

        } else if y {

            // do something else

        }
        """
        let output = """
        if x {
            // do something

        } else if y {

            // do something else
        }
        """
        testFormatting(for: input, output, rule: .blankLinesAtEndOfScope,
                       exclude: [.blankLinesAtStartOfScope])
    }

    func testBlankLineRemovedFromEndOfTypeByDefault() {
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
        testFormatting(for: input, output, rule: .blankLinesAtEndOfScope)
    }

    func testBlankLinesNotRemovedFromEndOfTypeWithOptionEnabled() {
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
        testFormatting(for: input, rule: .blankLinesAtEndOfScope, options: .init(typeBlankLines: .preserve))
    }

    func testBlankLineAtEndOfScopeRemovedFromMethodInType() {
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
        testFormatting(for: input, output, rule: .blankLinesAtEndOfScope, options: .init(typeBlankLines: .preserve), exclude: [.blankLinesAtStartOfScope])
    }

    func testBlankLinesInsertedAtEndOfType() {
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
        testFormatting(for: input, output, rule: .blankLinesAtEndOfScope, options: .init(typeBlankLines: .insert))
    }

    func testBlankLinesRemovedAtEndOfType() {
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
        testFormatting(for: input, output, rule: .blankLinesAtEndOfScope, options: .init(typeBlankLines: .insert), exclude: [.blankLinesAtStartOfScope])
    }
}
