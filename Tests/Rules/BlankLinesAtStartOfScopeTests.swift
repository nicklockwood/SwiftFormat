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
        let input = "func foo() {\n\n    // code\n}"
        let output = "func foo() {\n    // code\n}"
        testFormatting(for: input, output, rule: .blankLinesAtStartOfScope)
    }

    func testBlankLinesRemovedAtStartOfParens() {
        let input = "(\n\n    foo: Int\n)"
        let output = "(\n    foo: Int\n)"
        testFormatting(for: input, output, rule: .blankLinesAtStartOfScope)
    }

    func testBlankLinesRemovedAtStartOfBrackets() {
        let input = "[\n\n    foo,\n    bar,\n]"
        let output = "[\n    foo,\n    bar,\n]"
        testFormatting(for: input, output, rule: .blankLinesAtStartOfScope)
    }

    func testBlankLinesNotRemovedBetweenElementsInsideBrackets() {
        let input = "[foo,\n\n bar]"
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
        testFormatting(for: input, rule: .blankLinesAtStartOfScope, options: .init(removeStartOrEndBlankLinesFromTypes: false))
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
        testFormatting(for: input, output, rule: .blankLinesAtStartOfScope, options: .init(removeStartOrEndBlankLinesFromTypes: false))
    }
}
