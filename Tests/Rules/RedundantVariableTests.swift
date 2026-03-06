//
//  RedundantVariableTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 6/9/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class RedundantVariableTests: XCTestCase {
    func testRemovesRedundantVariable() {
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

        testFormatting(for: input, output, rule: .redundantVariable, exclude: [.redundantReturn])
    }

    func testRemovesRedundantVariableWithIfExpression() {
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
        testFormatting(for: input, [output], rules: [.redundantVariable, .redundantReturn, .indent], options: options)
    }

    func testRemovesRedundantVariableWithSwitchExpression() {
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
        testFormatting(for: input, [output], rules: [.conditionalAssignment, .redundantVariable, .redundantReturn, .indent], options: options)
    }

    func testRemovesRedundantVariableWithPreferInferredType() {
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

        testFormatting(for: input, [output], rules: [.propertyTypes, .redundantVariable, .redundantInit], exclude: [.redundantReturn])
    }

    func testRemovesRedundantVariableWithComments() {
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

        testFormatting(for: input, output, rule: .redundantVariable, exclude: [.redundantReturn])
    }

    func testRemovesRedundantVariableFollowingOtherVariable() {
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

        testFormatting(for: input, output, rule: .redundantVariable)
    }

    func testPreservesVariableWithExplicitTypeDifferentFromReturnType() {
        let input = """
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell: CustomCellType = tableView.dequeueReusableCell(for: indexPath)
            return cell
        }
        """

        testFormatting(for: input, rule: .redundantVariable)
    }

    func testRemovesVariableWithExplicitTypeMatchingReturnType() {
        let input = """
        func foo() -> Foo {
            let foo: Foo = Foo(bar: bar, baaz: baaz)
            return foo
        }
        """

        let output = """
        func foo() -> Foo {
            return Foo(bar: bar, baaz: baaz)
        }
        """

        testFormatting(for: input, output, rule: .redundantVariable, exclude: [.redundantReturn])
    }

    func testPreservesVariableWithExplicitTypeDifferentFromComputedPropertyType() {
        let input = """
        var foo: Foo {
            let bar: Bar = baz.makeSomething()
            return bar
        }
        """

        testFormatting(for: input, rule: .redundantVariable)
    }

    func testRemovesVariableWithExplicitTypeMatchingComputedPropertyType() {
        let input = """
        var foo: Foo {
            let foo: Foo = bar.makeSomething()
            return foo
        }
        """

        let output = """
        var foo: Foo {
            return bar.makeSomething()
        }
        """

        testFormatting(for: input, output, rule: .redundantVariable, exclude: [.redundantReturn])
    }

    func testPreservesVariableWhereReturnIsNotRedundant() {
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

        testFormatting(for: input, rule: .redundantVariable)
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

        testFormatting(for: input, rule: .redundantVariable)
    }
}
