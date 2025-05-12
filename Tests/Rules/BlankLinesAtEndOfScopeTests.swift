//
//  BlankLinesAtEndOfScopeTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 8/30/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class BlankLinesAtEndOfScopeTests: XCTestCase {
    func testBlankLinesRemovedAtEndOfFunction() {
        let input = "func foo() {\n    // code\n\n}"
        let output = "func foo() {\n    // code\n}"
        testFormatting(for: input, output, rule: .blankLinesAtEndOfScope)
    }

    func testBlankLinesRemovedAtEndOfParens() {
        let input = "(\n    foo: Int\n\n)"
        let output = "(\n    foo: Int\n)"
        testFormatting(for: input, output, rule: .blankLinesAtEndOfScope)
    }

    func testBlankLinesRemovedAtEndOfBrackets() {
        let input = "[\n    foo,\n    bar,\n\n]"
        let output = "[\n    foo,\n    bar,\n]"
        testFormatting(for: input, output, rule: .blankLinesAtEndOfScope)
    }

    func testBlankLineNotRemovedBeforeElse() {
        let input = "if x {\n\n    // do something\n\n} else if y {\n\n    // do something else\n\n}"
        let output = "if x {\n\n    // do something\n\n} else if y {\n\n    // do something else\n}"
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
        testFormatting(for: input, output, rule: .blankLinesAtEndOfScope, options: .init(typeBlankLines: .preserve))
    }

    func testBlankLinesInsertedAtEndOfType() {
        let input = """
        class FooClass {
            func fooMethod() {}
        }
        """

        let output = """
        class FooClass {
            func fooMethod() {}

        }
        """
        testFormatting(for: input, output, rule: .blankLinesAtEndOfScope, options: .init(typeBlankLines: .insert))
    }
}
