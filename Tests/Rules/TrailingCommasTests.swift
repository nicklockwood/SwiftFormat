//
//  TrailingCommasTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 8/22/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class TrailingCommasTests: XCTestCase {
    func testCommaAddedToSingleItem() {
        let input = "[\n    foo\n]"
        let output = "[\n    foo,\n]"
        testFormatting(for: input, output, rule: .trailingCommas)
    }

    func testCommaAddedToLastItem() {
        let input = "[\n    foo,\n    bar\n]"
        let output = "[\n    foo,\n    bar,\n]"
        testFormatting(for: input, output, rule: .trailingCommas)
    }

    func testCommaAddedToDictionary() {
        let input = "[\n    foo: bar\n]"
        let output = "[\n    foo: bar,\n]"
        testFormatting(for: input, output, rule: .trailingCommas)
    }

    func testCommaNotAddedToInlineArray() {
        let input = "[foo, bar]"
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testCommaNotAddedToInlineDictionary() {
        let input = "[foo: bar]"
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testCommaNotAddedToSubscript() {
        let input = "foo[bar]"
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testCommaAddedBeforeComment() {
        let input = "[\n    foo // comment\n]"
        let output = "[\n    foo, // comment\n]"
        testFormatting(for: input, output, rule: .trailingCommas)
    }

    func testCommaNotAddedAfterComment() {
        let input = "[\n    foo, // comment\n]"
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testCommaNotAddedInsideEmptyArrayLiteral() {
        let input = "foo = [\n]"
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testCommaNotAddedInsideEmptyDictionaryLiteral() {
        let input = "foo = [:\n]"
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testTrailingCommaRemovedInInlineArray() {
        let input = "[foo,]"
        let output = "[foo]"
        testFormatting(for: input, output, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToSubscript() {
        let input = "foo[\n    bar\n]"
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToSubscript2() {
        let input = "foo?[\n    bar\n]"
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToSubscript3() {
        let input = "foo()[\n    bar\n]"
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToSubscriptInsideArrayLiteral() {
        let input = """
        let array = [
            foo
                .bar[
                    0
                ]
                .baz,
        ]
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaAddedToArrayLiteralInsideTuple() {
        let input = """
        let arrays = ([
            foo
        ], [
            bar
        ])
        """
        let output = """
        let arrays = ([
            foo,
        ], [
            bar,
        ])
        """
        testFormatting(for: input, output, rule: .trailingCommas)
    }

    func testNoTrailingCommaAddedToArrayLiteralInsideTuple() {
        let input = """
        let arrays = ([
            Int
        ], [
            Int
        ]).self
        """
        testFormatting(for: input, rule: .trailingCommas, exclude: [.propertyTypes])
    }

    func testTrailingCommaNotAddedToTypeDeclaration() {
        let input = """
        var foo: [
            Int:
                String
        ]
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToTypeDeclaration2() {
        let input = """
        func foo(bar: [
            Int:
                String
        ])
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToTypeDeclaration3() {
        let input = """
        func foo() -> [
            String: String
        ]
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToTypeDeclaration4() {
        let input = """
        func foo() -> [String: [
            String: Int
        ]]
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToTypeDeclaration5() {
        let input = """
        let foo = [String: [
            String: Int
        ]]()
        """
        testFormatting(for: input, rule: .trailingCommas, exclude: [.propertyTypes])
    }

    func testTrailingCommaNotAddedToTypeDeclaration6() {
        let input = """
        let foo = [String: [
            (Foo<[
                String
            ]>, [
                Int
            ])
        ]]()
        """
        testFormatting(for: input, rule: .trailingCommas, exclude: [.propertyTypes])
    }

    func testTrailingCommaNotAddedToTypeDeclaration7() {
        let input = """
        func foo() -> Foo<[String: [
            String: Int
        ]]>
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToTypeDeclaration8() {
        let input = """
        extension Foo {
            var bar: [
                Int
            ] {
                fatalError()
            }
        }
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToTypealias() {
        let input = """
        typealias Foo = [
            Int
        ]
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToCaptureList() {
        let input = """
        let foo = { [
            self
        ] in }
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToCaptureListWithComment() {
        let input = """
        let foo = { [
            self // captures self
        ] in }
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToCaptureListWithMainActor() {
        let input = """
        let closure = { @MainActor [
            foo = state.foo,
            baz = state.baz
        ] _ in }
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToArrayExtension() {
        let input = """
        extension [
            Int
        ] {
            func foo() {}
        }
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    // trailingCommas = false

    func testCommaNotAddedToLastItem() {
        let input = "[\n    foo,\n    bar\n]"
        let options = FormatOptions(trailingCommas: false)
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testCommaRemovedFromLastItem() {
        let input = "[\n    foo,\n    bar,\n]"
        let output = "[\n    foo,\n    bar\n]"
        let options = FormatOptions(trailingCommas: false)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToFunctionParameters() {
        let input = "func foo(\n    bar _: Int\n) {}"
        let output = "func foo(\n    bar _: Int,\n) {}"
        let options = FormatOptions(trailingCommas: true, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromFunctionParameters() {
        let input = "func foo(\n    bar _: Int,\n) {}"
        let output = "func foo(\n    bar _: Int\n) {}"
        let options = FormatOptions(trailingCommas: false, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToFunctionArguments() {
        let input = "foo(\n    bar _: Int\n) {}"
        let output = "foo(\n    bar _: Int,\n) {}"
        let options = FormatOptions(trailingCommas: true, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromFunctionArguments() {
        let input = "foo(\n    bar _: Int,\n) {}"
        let output = "foo(\n    bar _: Int\n) {}"
        let options = FormatOptions(trailingCommas: false, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToEnumCaseAssociatedValue() {
        let input = "enum Foo {\n    case bar(\n        baz: String\n    )\n}"
        let output = "enum Foo {\n    case bar(\n        baz: String,\n    )\n}"
        let options = FormatOptions(trailingCommas: true, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromEnumCaseAssociatedValue() {
        let input = "enum Foo {\n    case bar(\n        baz: String,\n    )\n}"
        let output = "enum Foo {\n    case bar(\n        baz: String\n    )\n}"
        let options = FormatOptions(trailingCommas: false, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToInitializer() {
        let input = "let foo: Foo = .init(\n    1\n)"
        let output = "let foo: Foo = .init(\n    1,\n)"
        let options = FormatOptions(trailingCommas: true, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromInitializer() {
        let input = "let foo: Foo = .init(\n    1,\n)"
        let output = "let foo: Foo = .init(\n    1\n)"
        let options = FormatOptions(trailingCommas: false, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }
}
