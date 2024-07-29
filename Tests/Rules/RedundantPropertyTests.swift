//
//  RedundantPropertyTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class RedundantPropertyTests: XCTestCase {
    func testRemovesRedundantProperty() {
        let input = """
        func foo() -> Foo {
            let foo = Foo(bar: bar, baaz: baaz)
            return foo
        }
        """

        let output = """
        func foo() -> Foo {
            return Foo(bar: bar, baaz: baaz)
        }
        """

        testFormatting(for: input, output, rule: .redundantProperty, exclude: [.redundantReturn])
    }

    func testRemovesRedundantPropertyWithIfExpression() {
        let input = """
        func foo() -> Foo {
            let foo =
                if condition {
                    Foo.foo()
                } else {
                    Foo.bar()
                }

            return foo
        }
        """

        let output = """
        func foo() -> Foo {
            if condition {
                Foo.foo()
            } else {
                Foo.bar()
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output], rules: [.redundantProperty, .redundantReturn, .indent], options: options)
    }

    func testRemovesRedundantPropertyWithSwitchExpression() {
        let input = """
        func foo() -> Foo {
            let foo: Foo
            switch condition {
            case true:
                foo = Foo(bar)
            case false:
                foo = Foo(baaz)
            }

            return foo
        }
        """

        let output = """
        func foo() -> Foo {
            switch condition {
            case true:
                Foo(bar)
            case false:
                Foo(baaz)
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output], rules: [.conditionalAssignment, .redundantProperty, .redundantReturn, .indent], options: options)
    }

    func testRemovesRedundantPropertyWithPreferInferredType() {
        let input = """
        func bar() -> Bar {
            let bar: Bar = .init(baaz: baaz, quux: quux)
            return bar
        }
        """

        let output = """
        func bar() -> Bar {
            return Bar(baaz: baaz, quux: quux)
        }
        """

        testFormatting(for: input, [output], rules: [.propertyType, .redundantProperty, .redundantInit], exclude: [.redundantReturn])
    }

    func testRemovesRedundantPropertyWithComments() {
        let input = """
        func foo() -> Foo {
            // There's a comment before this property
            let foo = Foo(bar: bar, baaz: baaz)
            // And there's a comment after the property
            return foo
        }
        """

        let output = """
        func foo() -> Foo {
            // There's a comment before this property
            return Foo(bar: bar, baaz: baaz)
            // And there's a comment after the property
        }
        """

        testFormatting(for: input, output, rule: .redundantProperty, exclude: [.redundantReturn])
    }

    func testRemovesRedundantPropertyFollowingOtherProperty() {
        let input = """
        func foo() -> Foo {
            let bar = Bar(baaz: baaz)
            let foo = Foo(bar: bar)
            return foo
        }
        """

        let output = """
        func foo() -> Foo {
            let bar = Bar(baaz: baaz)
            return Foo(bar: bar)
        }
        """

        testFormatting(for: input, output, rule: .redundantProperty)
    }

    func testPreservesPropertyWhereReturnIsNotRedundant() {
        let input = """
        func foo() -> Foo {
            let foo = Foo(bar: bar, baaz: baaz)
            return foo.with(quux: quux)
        }

        func bar() -> Foo {
            let bar = Bar(baaz: baaz)
            return bar.baaz
        }

        func baaz() -> Foo {
            let bar = Bar(baaz: baaz)
            print(bar)
            return bar
        }
        """

        testFormatting(for: input, rule: .redundantProperty)
    }

    func testPreservesUnwrapConditionInIfStatement() {
        let input = """
        func foo() -> Foo {
            let foo = Foo(bar: bar, baaz: baaz)

            if let foo = foo.nestedFoo {
                print(foo)
            }

            return foo
        }
        """

        testFormatting(for: input, rule: .redundantProperty)
    }
}
