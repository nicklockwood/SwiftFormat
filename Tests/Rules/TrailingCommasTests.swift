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
        let input = """
        func foo(
            bar _: Int
        ) {}
        """
        let output = """
        func foo(
            bar _: Int,
        ) {}
        """
        let options = FormatOptions(trailingCommas: true, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasNotAddedToFunctionParametersBeforeSwift6_1() {
        let input = """
        func foo(
            bar _: Int
        ) {}
        """
        let options = FormatOptions(trailingCommas: true)
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromFunctionParameters() {
        let input = """
        func foo(
            bar _: Int,
        ) {}
        """
        let output = """
        func foo(
            bar _: Int
        ) {}
        """
        let options = FormatOptions(trailingCommas: false)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromFunctionParametersWithParenOnSameLine_trailingCommasDisabled() {
        let input = """
        func foo(
            bar _: Int,
            baaz _: Int,)
        {}
        """
        let output = """
        func foo(
            bar _: Int,
            baaz _: Int)
        {}
        """
        let options = FormatOptions(trailingCommas: false, closingParenPosition: .sameLine)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromFunctionParametersWithParenOnSameLine_trailingCommasEnabled() {
        let input = """
        func foo(
            bar _: Int,
            baaz _: Int,)
        {}
        """
        let output = """
        func foo(
            bar _: Int,
            baaz _: Int)
        {}
        """
        let options = FormatOptions(trailingCommas: true, closingParenPosition: .sameLine)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToFunctionArguments() {
        let input = """
        foo(
            bar _: Int
        ) {}
        """
        let output = """
        foo(
            bar _: Int,
        ) {}
        """
        let options = FormatOptions(trailingCommas: true, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromFunctionArguments() {
        let input = """
        foo(
            bar _: Int,
        ) {}
        """
        let output = """
        foo(
            bar _: Int
        ) {}
        """
        let options = FormatOptions(trailingCommas: false)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToEnumCaseAssociatedValue() {
        let input = """
        enum Foo {
            case bar(
                baz: String
            )
        }
        """
        let output = """
        enum Foo {
            case bar(
                baz: String,
            )
        }
        """
        let options = FormatOptions(trailingCommas: true, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromEnumCaseAssociatedValue() {
        let input = """
        enum Foo {
            case bar(
                baz: String,
            )
        }
        """
        let output = """
        enum Foo {
            case bar(
                baz: String
            )
        }
        """
        let options = FormatOptions(trailingCommas: false)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToInitializer() {
        let input = """
        let foo: Foo = .init(
            1
        )
        """
        let output = """
        let foo: Foo = .init(
            1,
        )
        """
        let options = FormatOptions(trailingCommas: true, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromInitializer() {
        let input = """
        let foo: Foo = .init(
            1,
        )
        """
        let output = """
        let foo: Foo = .init(
            1
        )
        """
        let options = FormatOptions(trailingCommas: false)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToTuple() {
        let input = """
        let foo = (
            bar: 0,
            baz: 1
        )
        """
        let output = """
        let foo = (
            bar: 0,
            baz: 1,
        )
        """
        let options = FormatOptions(trailingCommas: true, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromTuple() {
        let input = """
        let foo = (
            bar: 0,
            baz: 1,
        )
        """
        let output = """
        let foo = (
            bar: 0,
            baz: 1
        )
        """
        let options = FormatOptions(trailingCommas: false)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToReturnTuple() {
        let input = """
        func foo() -> (Int, Int) {
            let bar = 0
            let baz = 1

            return (
                bar,
                baz
            )
        }
        """
        let output = """
        func foo() -> (Int, Int) {
            let bar = 0
            let baz = 1

            return (
                bar,
                baz,
            )
        }
        """
        let options = FormatOptions(trailingCommas: true, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromReturnTuple() {
        let input = """
        func foo() -> (Int, Int) {
            let bar = 0
            let baz = 1

            return (
                bar,
                baz,
            )
        }
        """
        let output = """
        func foo() -> (Int, Int) {
            let bar = 0
            let baz = 1

            return (
                bar,
                baz
            )
        }
        """
        let options = FormatOptions(trailingCommas: false)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToThrow() {
        let input = """
        enum FooError: Error {
            case bar
        }

        func baz() throws {
            throw (
                FooError.bar
            )
        }
        """
        let output = """
        enum FooError: Error {
            case bar
        }

        func baz() throws {
            throw (
                FooError.bar,
            )
        }
        """
        let options = FormatOptions(trailingCommas: true, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromThrow() {
        let input = """
        enum FooError: Error {
            case bar
        }

        func baz() throws {
            throw (
                FooError.bar,
            )
        }
        """
        let output = """
        enum FooError: Error {
            case bar
        }

        func baz() throws {
            throw (
                FooError.bar
            )
        }
        """
        let options = FormatOptions(trailingCommas: false)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToSwitch() {
        let input = """
        let foo = (
            bar: 0,
            baz: 1
        )
        switch (
            foo.bar,
            foo.baz
        ) {
        case (
            0,
            1
        ): break
        default: break
        }
        """
        let output = """
        let foo = (
            bar: 0,
            baz: 1,
        )
        switch (
            foo.bar,
            foo.baz,
        ) {
        case (
            0,
            1,
        ): break
        default: break
        }
        """
        let options = FormatOptions(trailingCommas: true, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasNotAddedToTypeAnnotation() {
        let input = """
        let foo: (
            bar: Int,
            baz: Int
        )
        """
        let options = FormatOptions(trailingCommas: false)
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToCaseLet() {
        let input = """
        let foo = (0, 1)
        switch foo {
        case let (
            bar,
            baz
        ): break
        }
        """
        let output = """
        let foo = (0, 1)
        switch foo {
        case let (
            bar,
            baz,
        ): break
        }
        """
        let options = FormatOptions(trailingCommas: true, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromCaseLet() {
        let input = """
        let foo = (0, 1)
        switch foo {
        case let (
            bar,
            baz,
        ): break
        }
        """
        let output = """
        let foo = (0, 1)
        switch foo {
        case let (
            bar,
            baz
        ): break
        }
        """
        let options = FormatOptions(trailingCommas: false)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommaAddedToDestructuringLetTuple() {
        let input = """
        let (
            foo,
            bar
        ) = (0, 1)
        """
        let output = """
        let (
            foo,
            bar,
        ) = (0, 1)
        """
        let options = FormatOptions(trailingCommas: true, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommaRemovedFromDestructuringLetTuple() {
        let input = """
        let (
            foo,
            bar,
        ) = (0, 1)
        """
        let output = """
        let (
            foo,
            bar
        ) = (0, 1)
        """
        let options = FormatOptions(trailingCommas: false)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasNotAddedToEmptyParentheses() {
        let input = """
        let foo = (

        )
        """
        let options = FormatOptions(trailingCommas: false)
        testFormatting(for: input, rule: .trailingCommas,
                       options: options, exclude: [
                           .blankLinesAtEndOfScope,
                           .blankLinesAtStartOfScope,
                       ])
    }

    func testTrailingCommasAddedToStringInterpolation() {
        let input = """
        let foo = \"""
        Foo: \\(
            1,
            2
        )
        \"""
        """
        let output = """
        let foo = \"""
        Foo: \\(
            1,
            2,
        )
        \"""
        """
        let options = FormatOptions(trailingCommas: true, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromStringInterpolation() {
        let input = """
        let foo = \"""
        Foo: \\(
            1,
            2,
        )
        \"""
        """
        let output = """
        let foo = \"""
        Foo: \\(
            1,
            2
        )
        \"""
        """
        let options = FormatOptions(trailingCommas: false)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToAttribute() {
        let input = """
        @Foo(
            "bar",
            "baz"
        )
        struct Qux {}
        """
        let output = """
        @Foo(
            "bar",
            "baz",
        )
        struct Qux {}
        """
        let options = FormatOptions(trailingCommas: true, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromAttribute() {
        let input = """
        @Foo(
            "bar",
            "baz",
        )
        struct Qux {}
        """
        let output = """
        @Foo(
            "bar",
            "baz"
        )
        struct Qux {}
        """
        let options = FormatOptions(trailingCommas: false)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToMacro() {
        let input = """
        #foo(
            "bar",
            "baz"
        )
        """
        let output = """
        #foo(
            "bar",
            "baz",
        )
        """
        let options = FormatOptions(trailingCommas: true, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromMacro() {
        let input = """
        #foo(
            "bar",
            "baz",
        )
        """
        let output = """
        #foo(
            "bar",
            "baz"
        )
        """
        let options = FormatOptions(trailingCommas: false)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToGenericList() {
        let input = """
        struct S<
            T1,
            T2,
            T3
        > {}
        """
        let output = """
        struct S<
            T1,
            T2,
            T3,
        > {}
        """
        let options = FormatOptions(trailingCommas: true, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromGenericList() {
        let input = """
        struct S<
            T1,
            T2,
            T3,
        > {}
        """
        let output = """
        struct S<
            T1,
            T2,
            T3
        > {}
        """
        let options = FormatOptions(trailingCommas: false)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromSingleLineGenericList() {
        let input = """
        struct S<T1, T2, T3,> {}
        """
        let output = """
        struct S<T1, T2, T3> {}
        """
        let options = FormatOptions(trailingCommas: true, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToCaptureList() {
        let input = """
        { [
            capturedValue1,
            capturedValue2
        ] in
        }
        """
        let output = """
        { [
            capturedValue1,
            capturedValue2,
        ] in
        }
        """
        let options = FormatOptions(trailingCommas: true, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromCaptureList() {
        let input = """
        { [
            capturedValue1,
            capturedValue2,
        ] in
        }
        """
        let output = """
        { [
            capturedValue1,
            capturedValue2
        ] in
        }
        """
        let options = FormatOptions(trailingCommas: false)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromSingleLineCaptureList() {
        let input = """
        { [capturedValue1, capturedValue2,] in
            print(capturedValue1, capturedValue2)
        }
        """
        let output = """
        { [capturedValue1, capturedValue2] in
            print(capturedValue1, capturedValue2)
        }
        """
        let options = FormatOptions(trailingCommas: true, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToSubscript() {
        let input = """
        let value = m[
            x,
            y
        ]
        """
        let output = """
        let value = m[
            x,
            y,
        ]
        """
        let options = FormatOptions(trailingCommas: true, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromSubscript() {
        let input = """
        let value = m[
            x,
            y,
        ]
        """
        let output = """
        let value = m[
            x,
            y
        ]
        """
        let options = FormatOptions(trailingCommas: false)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromSingleLineSubscript() {
        let input = """
        let value = m[x, y,]
        """
        let output = """
        let value = m[x, y]
        """
        let options = FormatOptions(trailingCommas: true, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testAddingTrailingCommaDoesntConflictWithOpaqueGenericParametersRule() {
        let input = """
        private func foo<
            Foo: Bar,
            Bar: Baaz
        >(a: Foo, b: Foo)
            where Foo == Bar
        {
            print(a, b)
        }
        """

        let output = """
        private func foo<
            Foo: Bar,
            Bar: Baaz,
        >(a: Foo, b: Foo)
            where Foo == Bar
        {
            print(a, b)
        }
        """

        let options = FormatOptions(trailingCommas: true, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }
}
