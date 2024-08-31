//
//  RedundantBackticksTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 3/7/17.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class RedundantBackticksTests: XCTestCase {
    func testRemoveRedundantBackticksInLet() {
        let input = "let `foo` = bar"
        let output = "let foo = bar"
        testFormatting(for: input, output, rule: .redundantBackticks)
    }

    func testNoRemoveBackticksAroundKeyword() {
        let input = "let `let` = foo"
        testFormatting(for: input, rule: .redundantBackticks)
    }

    func testNoRemoveBackticksAroundSelf() {
        let input = "let `self` = foo"
        testFormatting(for: input, rule: .redundantBackticks)
    }

    func testNoRemoveBackticksAroundClassSelfInTypealias() {
        let input = "typealias `Self` = Foo"
        testFormatting(for: input, rule: .redundantBackticks)
    }

    func testRemoveBackticksAroundClassSelfAsReturnType() {
        let input = "func foo(bar: `Self`) { print(bar) }"
        let output = "func foo(bar: Self) { print(bar) }"
        testFormatting(for: input, output, rule: .redundantBackticks)
    }

    func testRemoveBackticksAroundClassSelfAsParameterType() {
        let input = "func foo() -> `Self` {}"
        let output = "func foo() -> Self {}"
        testFormatting(for: input, output, rule: .redundantBackticks)
    }

    func testRemoveBackticksAroundClassSelfArgument() {
        let input = "func foo(`Self`: Foo) { print(Self) }"
        let output = "func foo(Self: Foo) { print(Self) }"
        testFormatting(for: input, output, rule: .redundantBackticks)
    }

    func testNoRemoveBackticksAroundKeywordFollowedByType() {
        let input = "let `default`: Int = foo"
        testFormatting(for: input, rule: .redundantBackticks)
    }

    func testNoRemoveBackticksAroundContextualGet() {
        let input = "var foo: Int {\n    `get`()\n    return 5\n}"
        testFormatting(for: input, rule: .redundantBackticks)
    }

    func testRemoveBackticksAroundGetArgument() {
        let input = "func foo(`get` value: Int) { print(value) }"
        let output = "func foo(get value: Int) { print(value) }"
        testFormatting(for: input, output, rule: .redundantBackticks)
    }

    func testRemoveBackticksAroundTypeAtRootLevel() {
        let input = "enum `Type` {}"
        let output = "enum Type {}"
        testFormatting(for: input, output, rule: .redundantBackticks)
    }

    func testNoRemoveBackticksAroundTypeInsideType() {
        let input = "struct Foo {\n    enum `Type` {}\n}"
        testFormatting(for: input, rule: .redundantBackticks, exclude: [.enumNamespaces])
    }

    func testNoRemoveBackticksAroundLetArgument() {
        let input = "func foo(`let`: Foo) { print(`let`) }"
        testFormatting(for: input, rule: .redundantBackticks)
    }

    func testNoRemoveBackticksAroundTrueArgument() {
        let input = "func foo(`true`: Foo) { print(`true`) }"
        testFormatting(for: input, rule: .redundantBackticks)
    }

    func testRemoveBackticksAroundTrueArgument() {
        let input = "func foo(`true`: Foo) { print(`true`) }"
        let output = "func foo(true: Foo) { print(`true`) }"
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: .redundantBackticks, options: options)
    }

    func testNoRemoveBackticksAroundTypeProperty() {
        let input = "var type: Foo.`Type`"
        testFormatting(for: input, rule: .redundantBackticks)
    }

    func testNoRemoveBackticksAroundTypePropertyInsideType() {
        let input = "struct Foo {\n    enum `Type` {}\n}"
        testFormatting(for: input, rule: .redundantBackticks, exclude: [.enumNamespaces])
    }

    func testNoRemoveBackticksAroundTrueProperty() {
        let input = "var type = Foo.`true`"
        testFormatting(for: input, rule: .redundantBackticks)
    }

    func testRemoveBackticksAroundTrueProperty() {
        let input = "var type = Foo.`true`"
        let output = "var type = Foo.true"
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: .redundantBackticks, options: options, exclude: [.propertyType])
    }

    func testRemoveBackticksAroundProperty() {
        let input = "var type = Foo.`bar`"
        let output = "var type = Foo.bar"
        testFormatting(for: input, output, rule: .redundantBackticks, exclude: [.propertyType])
    }

    func testRemoveBackticksAroundKeywordProperty() {
        let input = "var type = Foo.`default`"
        let output = "var type = Foo.default"
        testFormatting(for: input, output, rule: .redundantBackticks, exclude: [.propertyType])
    }

    func testRemoveBackticksAroundKeypathProperty() {
        let input = "var type = \\.`bar`"
        let output = "var type = \\.bar"
        testFormatting(for: input, output, rule: .redundantBackticks)
    }

    func testNoRemoveBackticksAroundKeypathKeywordProperty() {
        let input = "var type = \\.`default`"
        testFormatting(for: input, rule: .redundantBackticks)
    }

    func testRemoveBackticksAroundKeypathKeywordPropertyInSwift5() {
        let input = "var type = \\.`default`"
        let output = "var type = \\.default"
        let options = FormatOptions(swiftVersion: "5")
        testFormatting(for: input, output, rule: .redundantBackticks, options: options)
    }

    func testNoRemoveBackticksAroundInitPropertyInSwift5() {
        let input = "let foo: Foo = .`init`"
        let options = FormatOptions(swiftVersion: "5")
        testFormatting(for: input, rule: .redundantBackticks, options: options, exclude: [.propertyType])
    }

    func testNoRemoveBackticksAroundAnyProperty() {
        let input = "enum Foo {\n    case `Any`\n}"
        testFormatting(for: input, rule: .redundantBackticks)
    }

    func testNoRemoveBackticksAroundGetInSubscript() {
        let input = """
        subscript<T>(_ name: String) -> T where T: Equatable {
            `get`(name)
        }
        """
        testFormatting(for: input, rule: .redundantBackticks)
    }

    func testNoRemoveBackticksAroundActorProperty() {
        let input = "let `actor`: Foo"
        testFormatting(for: input, rule: .redundantBackticks)
    }

    func testRemoveBackticksAroundActorRvalue() {
        let input = "let foo = `actor`"
        let output = "let foo = actor"
        testFormatting(for: input, output, rule: .redundantBackticks)
    }

    func testRemoveBackticksAroundActorLabel() {
        let input = "init(`actor`: Foo)"
        let output = "init(actor: Foo)"
        testFormatting(for: input, output, rule: .redundantBackticks)
    }

    func testRemoveBackticksAroundActorLabel2() {
        let input = "init(`actor` foo: Foo)"
        let output = "init(actor foo: Foo)"
        testFormatting(for: input, output, rule: .redundantBackticks)
    }

    func testNoRemoveBackticksAroundUnderscore() {
        let input = "func `_`<T>(_ foo: T) -> T { foo }"
        testFormatting(for: input, rule: .redundantBackticks)
    }

    func testNoRemoveBackticksAroundShadowedSelf() {
        let input = """
        struct Foo {
            let `self`: URL

            func printURL() {
                print("My URL is \\(self.`self`)")
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4.1")
        testFormatting(for: input, rule: .redundantBackticks, options: options)
    }

    func testNoRemoveBackticksAroundDollar() {
        let input = "@attached(peer, names: prefixed(`$`))"
        testFormatting(for: input, rule: .redundantBackticks)
    }
}
