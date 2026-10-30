//
//  RedundantBlankLinesTests.swift
//  SwiftFormatTests
//
//  Created by Ethan Pippin on 2026-10-26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class RedundantBlankLinesTests: XCTestCase {
    func testRemovesBlankLineAfterTypeAttribute() {
        let input = """
        @MainActor

        struct Foo {}
        """
        let output = """
        @MainActor
        struct Foo {}
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesMultipleBlankLinesAfterAttribute() {
        let input = """
        @MainActor


        struct Foo {}
        """
        let output = """
        @MainActor
        struct Foo {}
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesBetweenSequentialAttributes() {
        let input = """
        @objc

        @MainActor

        class Foo: NSObject {}
        """
        let output = """
        @objc
        @MainActor
        class Foo: NSObject {}
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLineAfterAttributeWithArguments() {
        let input = """
        @available(iOS 15, *)

        func foo() {}
        """
        let output = """
        @available(iOS 15, *)
        func foo() {}
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLineBeforeModifiers() {
        let input = """
        @objc

        public final class Foo: NSObject {}
        """
        let output = """
        @objc
        public final class Foo: NSObject {}
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLineAfterPropertyAttributeInTypeBody() {
        let input = """
        struct Foo: View {
            @State

            private var count = 0

            var body: some View {
                Text("\\(count)")
            }
        }
        """
        let output = """
        struct Foo: View {
            @State
            private var count = 0

            var body: some View {
                Text("\\(count)")
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLineAfterLocalPropertyAttribute() {
        let input = """
        #Preview {
            @Previewable

            @State var count = 0
            Text("\\(count)")
        }
        """
        let output = """
        #Preview {
            @Previewable
            @State var count = 0
            Text("\\(count)")
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLineAfterAttributeWithTrailingComment() {
        let input = """
        @MainActor // Isolated to the main actor

        struct Foo {}
        """
        let output = """
        @MainActor // Isolated to the main actor
        struct Foo {}
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testPreservesBlankLineBeforeComment() {
        let input = """
        @MainActor

        // TODO: Remove main actor isolation
        struct Foo {}
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }

    func testPreservesAttributesWithoutBlankLines() {
        let input = """
        @MainActor
        struct Foo {
            @State private var count = 0
        }
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }

    func testRemovesBlankLineAfterParameterAttribute() {
        let input = """
        func foo(
            @ViewBuilder

            content: () -> some View
        ) -> some View {
            content()
        }
        """
        let output = """
        func foo(
            @ViewBuilder
            content: () -> some View
        ) -> some View {
            content()
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesBetweenModifiers() {
        let input = """
        public

        final

        class Foo {}
        """
        let output = """
        public
        final
        class Foo {}
        """
        testFormatting(for: input, output, rule: .redundantBlankLines, exclude: [.modifiersOnSameLine])
    }

    func testRemovesBlankLinesBetweenParenthesizedModifier() {
        let input = """
        private(set)

        var value = 0
        """
        let output = """
        private(set)
        var value = 0
        """
        testFormatting(for: input, output, rule: .redundantBlankLines, exclude: [.modifiersOnSameLine])
    }

    func testRemovesBlankLinesBetweenDeclarationNames() {
        let input = """
        struct

        Foo {
            let

                value = 0
        }
        """
        let output = """
        struct
        Foo {
            let
                value = 0
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesBetweenFunctionSignature() {
        let input = """
        func

        foo()

        async

        throws

        ->

        Int {
            0
        }
        """
        let output = """
        func
        foo()
        async
        throws
        ->
        Int {
            0
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesBetweenTypedThrows() {
        let input = """
        func foo()

            async

            throws(Failure)

            ->

            Int
        {
            0
        }
        """
        let output = """
        func foo()
            async
            throws(Failure)
            ->
            Int
        {
            0
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesBetweenParameterSyntax() {
        let input = """
        func foo(
            value

                :

            Int,

            other: String
        ) {
            print(value, other)
        }
        """
        let output = """
        func foo(
            value
                :
            Int,

            other: String
        ) {
            print(value, other)
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines, exclude: [.leadingDelimiters])
    }

    func testRemovesBlankLinesBetweenParameterLabels() {
        let input = """
        func foo(
            external

            internalName: Int
        ) {
            print(internalName)
        }
        """
        let output = """
        func foo(
            external
            internalName: Int
        ) {
            print(internalName)
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines, exclude: [.wrapArguments])
    }

    func testRemovesBlankLinesBetweenExpressionPrefixes() {
        let input = """
        let value = try

            await

            load()
        let other = try?

            load()
        """
        let output = """
        let value = try
            await
            load()
        let other = try?
            load()
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testPreservesGroupedExpressions() {
        let input = """
        let values = [
            first,

            second,
        ]
        foo(
            first,

            second
        )
        let result = first

            + second
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }

    func testPreservesScopePadding() {
        let input = """
        func foo() {

            first()

            second()

        }
        """
        testFormatting(for: input, rule: .redundantBlankLines, exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    func testPreservesComments() {
        let input = """
        func foo()

            /// Explanation
            async -> Int
        {
            0
        }

        let value = try

            // Explanation
            load()
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }

    func testPreservesConditionalCompilation() {
        let input = """
        @MainActor

        #if DEBUG
            struct Foo {}
        #endif
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }

    func testPreservesAttributeArguments() {
        let input = """
        @available(
            iOS 15,

            macOS 12, *
        )
        struct Foo {}
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }

    func testPreservesMultilineString() {
        let input = """
        let text = \"\"\"
        try

        await

        value
        \"\"\"
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }

    func testPreservesDisabledRule() {
        let input = """
        // swiftformat:disable redundantBlankLines
        @MainActor

        struct Foo {}
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }

    func testPreservesBlankLinesInsideParameterDefaults() {
        let input = """
        func foo(
            value: Int = condition ? first :

                second
        ) {
            print(value)
        }
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }

    func testPreservesBlankLinesBeforeBodyAndBetweenBranches() {
        let input = """
        func foo() -> Int

        {
            if condition {
                return 1
            }

            else {
                return 2
            }
        }
        """
        testFormatting(for: input, rule: .redundantBlankLines, exclude: [.braces, .elseOnSameLine])
    }

    func testPreservesBlankLineAfterBodylessAsyncFunction() {
        let input = """
        @GenerateBody
        func foo() async

        let value: Int
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInPropertyAnnotationAfterColon() {
        let input = """
        let foo:

            Int = 0
        """
        let output = """
        let foo:
            Int = 0
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInPropertyAnnotationBeforeColon() {
        let input = """
        let foo

            : Int = 0
        """
        let output = """
        let foo
            : Int = 0
        """
        let output2 = """
        let foo:
            Int = 0
        """
        testFormatting(for: input, [output, output2], rules: [.redundantBlankLines])
    }

    func testRemovesBlankLinesInParameterDefaultBeforeEquals() {
        let input = """
        func foo(
            value: Int

                = 0
        ) {
            print(value)
        }
        """
        let output = """
        func foo(
            value: Int
                = 0
        ) {
            print(value)
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInParameterDefaultAfterEquals() {
        let input = """
        func foo(
            value: Int =

                1
        ) {
            print(value)
        }
        """
        let output = """
        func foo(
            value: Int =
                1
        ) {
            print(value)
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInVariadicParameter() {
        let input = """
        func foo(
            values: Int

            ...
        ) {
            print(values)
        }
        """
        let output = """
        func foo(
            values: Int
            ...
        ) {
            print(values)
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInParameterAttribute() {
        let input = """
        func foo(
            @ViewBuilder

            content: () -> Int
        ) {
            print(content())
        }
        """
        let output = """
        func foo(
            @ViewBuilder
            content: () -> Int
        ) {
            print(content())
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInEnumCaseName() {
        let input = """
        enum E {
            case

                foo
        }
        """
        let output = """
        enum E {
            case
                foo
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInImportName() {
        let input = """
        import

            Foundation
        """
        let output = """
        import
            Foundation
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInMacroName() {
        let input = """
        @freestanding(expression)
        macro

        foo() = #externalMacro(module: "A", type: "B")
        """
        let output = """
        @freestanding(expression)
        macro
        foo() = #externalMacro(module: "A", type: "B")
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInPrecedenceGroupName() {
        let input = """
        precedencegroup

        Foo {}
        """
        let output = """
        precedencegroup
        Foo {}
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInOperatorName() {
        let input = """
        infix operator

        +++
        """
        let output = """
        infix operator
        +++
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInOperatorFunctionName() {
        let input = """
        struct S {
            static func

            == (lhs: S, rhs: S) -> Bool { true }
        }
        """
        let output = """
        struct S {
            static func
            == (lhs: S, rhs: S) -> Bool { true }
        }
        """
        let output2 = """
        enum S {
            static func
            == (_: S, _: S) -> Bool {
                true
            }
        }
        """
        testFormatting(for: input, [output, output2], rules: [.redundantBlankLines])
    }

    func testRemovesBlankLinesInFunctionTypeArrow() {
        let input = """
        let handler: (Int)

            -> Void = { _ in }
        """
        let output = """
        let handler: (Int)
            -> Void = { _ in }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInFunctionTypeEffects() {
        let input = """
        let handler: (Int)

        async throws -> Void
        """
        let output = """
        let handler: (Int)
        async throws -> Void
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInClosureReturnType() {
        let input = """
        let x = { (value: Int)

            -> Int

            in
                value
        }
        """
        let output = """
        let x = { (value: Int)
            -> Int
            in
                value
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInClosureEffects() {
        let input = """
        let x = { (value: Int)

            async throws -> Int in
                value
        }
        """
        let output = """
        let x = { (value: Int)
            async throws -> Int in
                value
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInGetterEffects() {
        let input = """
        struct S {
            var foo: Int {
                get

                async

                throws {
                    0
                }
            }
        }
        """
        let output = """
        struct S {
            var foo: Int {
                get
                async
                throws {
                    0
                }
            }
        }
        """
        let output2 = """
        struct S {
            var foo: Int {
                get
                async
                    throws
                {
                    0
                }
            }
        }
        """
        testFormatting(for: input, [output, output2], rules: [.redundantBlankLines])
    }

    func testRemovesBlankLinesInThrowOperand() {
        let input = """
        func foo() throws {
            throw

                MyError()
        }
        """
        let output = """
        func foo() throws {
            throw
                MyError()
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInFunctionParameterClause() {
        let input = """
        func foo

        () {}
        """
        let output = """
        func foo
        () {}
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInFunctionGenericClause() {
        let input = """
        func foo

        <T>(_ value: T) {
            print(value)
        }
        """
        let output = """
        func foo
        <T>(_ value: T) {
            print(value)
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInInitializerGenericClause() {
        let input = """
        struct S {
            init

            <T>(value: T) {
                print(value)
            }
        }
        """
        let output = """
        struct S {
            init
            <T>(value: T) {
                print(value)
            }
        }
        """
        let output2 = """
        struct S {
            init
                <T>(value: T)
            {
                print(value)
            }
        }
        """
        testFormatting(for: input, [output, output2], rules: [.redundantBlankLines])
    }

    func testRemovesBlankLinesInTypeGenericClause() {
        let input = """
        struct Foo

        <T> {}
        """
        let output = """
        struct Foo
        <T> {}
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInInheritanceBeforeColon() {
        let input = """
        struct Foo

            : Equatable {}
        """
        let output = """
        struct Foo
            : Equatable {}
        """
        let output2 = """
        struct Foo:
            Equatable {}
        """
        testFormatting(for: input, [output, output2], rules: [.redundantBlankLines])
    }

    func testRemovesBlankLinesInInheritanceAfterColon() {
        let input = """
        struct Foo:

            Equatable {}
        """
        let output = """
        struct Foo:
            Equatable {}
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInEnumRawType() {
        let input = """
        enum Foo:

            String {
            case a
        }
        """
        let output = """
        enum Foo:
            String {
            case a
        }
        """
        let output2 = """
        enum Foo:
            String
        {
            case a
        }
        """
        testFormatting(for: input, [output, output2], rules: [.redundantBlankLines])
    }

    func testRemovesBlankLinesInExtensionConformance() {
        let input = """
        extension Foo

            : Bar {}
        """
        let output = """
        extension Foo
            : Bar {}
        """
        let output2 = """
        extension Foo:
            Bar {}
        """
        testFormatting(for: input, [output, output2], rules: [.redundantBlankLines])
    }

    func testRemovesBlankLinesInAssociatedTypeConstraint() {
        let input = """
        protocol P {
            associatedtype T:

                Equatable
        }
        """
        let output = """
        protocol P {
            associatedtype T:
                Equatable
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInGenericConstraint() {
        let input = """
        func foo<T:

        Equatable>(_ t: T) {
            print(t)
        }
        """
        let output = """
        func foo<T:
        Equatable>(_ t: T) {
            print(t)
        }
        """
        let output2 = """
        func foo<T:
            Equatable>(_ t: T)
        {
            print(t)
        }
        """
        testFormatting(for: input, [output, output2], rules: [.redundantBlankLines])
    }

    func testRemovesBlankLinesInTypealiasBeforeEquals() {
        let input = """
        typealias Foo

            = Int
        """
        let output = """
        typealias Foo
            = Int
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInTypealiasAfterEquals() {
        let input = """
        typealias Foo =

            Int
        """
        let output = """
        typealias Foo =
            Int
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInEnumRawValue() {
        let input = """
        enum E: Int {
            case foo

                = 1
        }
        """
        let output = """
        enum E: Int {
            case foo
                = 1
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInAccessorAttribute() {
        let input = """
        struct S {
            var foo: Int {
                @inlinable

                get { 0 }
            }
        }
        """
        let output = """
        struct S {
            var foo: Int {
                @inlinable
                get { 0 }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInAccessorModifier() {
        let input = """
        struct S {
            var foo: Int {
                mutating

                get { 0 }
            }
        }
        """
        let output = """
        struct S {
            var foo: Int {
                mutating
                get { 0 }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInUnknownDefault() {
        let input = """
        switch x {
        case .a: break
        @unknown

        default: break
        }
        """
        let output = """
        switch x {
        case .a: break
        @unknown
        default: break
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInPreviewAttribute() {
        let input = """
        @available(iOS 17, *)

        #Preview {
            Text("")
        }
        """
        let output = """
        @available(iOS 17, *)
        #Preview {
            Text("")
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInFunctionTypeAttribute() {
        let input = """
        let handler: @MainActor

        () -> Void = {}
        """
        let output = """
        let handler: @MainActor
        () -> Void = {}
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInOpaqueReturnType() {
        let input = """
        func foo() -> some

        View {
            Text("")
        }
        """
        let output = """
        func foo() -> some
        View {
            Text("")
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInOpaquePropertyType() {
        let input = """
        struct V: View {
            var body: some

                View {
                Text("")
            }
        }
        """
        let output = """
        struct V: View {
            var body: some
                View {
                Text("")
            }
        }
        """
        let output2 = """
        struct V: View {
            var body: some
            View {
                Text("")
            }
        }
        """
        testFormatting(for: input, [output, output2], rules: [.redundantBlankLines])
    }

    func testRemovesBlankLinesInAsyncLet() {
        let input = """
        func foo() async {
            async

            let x = bar()
            await print(x)
        }
        """
        let output = """
        func foo() async {
            async
            let x = bar()
            await print(x)
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInIfCondition() {
        let input = """
        if

            condition {
            print(1)
        }
        """
        let output = """
        if
            condition {
            print(1)
        }
        """
        let output2 = """
        if
            condition
        {
            print(1)
        }
        """
        testFormatting(for: input, [output, output2], rules: [.redundantBlankLines])
    }

    func testRemovesBlankLinesInForIn() {
        let input = """
        for x

            in xs {
            print(x)
        }
        """
        let output = """
        for x
            in xs {
            print(x)
        }
        """
        let output2 = """
        for x
            in xs
        {
            print(x)
        }
        """
        testFormatting(for: input, [output, output2], rules: [.redundantBlankLines])
    }

    func testRemovesBlankLinesInSwitchSubject() {
        let input = """
        switch

            value {
        default: break
        }
        """
        let output = """
        switch
            value {
        default: break
        }
        """
        let output2 = """
        switch
            value
        {
        default: break
        }
        """
        testFormatting(for: input, [output, output2], rules: [.redundantBlankLines])
    }

    func testRemovesBlankLinesInCatchPattern() {
        let input = """
        do {
            try foo()
        } catch

            let error {
            print(error)
        }
        """
        let output = """
        do {
            try foo()
        } catch
            let error {
            print(error)
        }
        """
        let output2 = """
        do {
            try foo()
        } catch {
            print(error)
        }
        """
        testFormatting(for: input, [output, output2], rules: [.redundantBlankLines])
    }

    func testRemovesBlankLinesInCasePattern() {
        let input = """
        switch x {
        case let

            .foo(y):
            print(y)
        default: break
        }
        """
        let output = """
        switch x {
        case let
            .foo(y):
            print(y)
        default: break
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInElseIf() {
        let input = """
        if a {
            print(1)
        } else

        if b {
            print(2)
        }
        """
        let output = """
        if a {
            print(1)
        } else
        if b {
            print(2)
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInDestructuringBinding() {
        let input = """
        let

            (a, b) = (1, 2)
        """
        let output = """
        let
            (a, b) = (1, 2)
        """
        let output2 = """
        let a = 1
        let b = 2
        """
        testFormatting(for: input, [output, output2], rules: [.redundantBlankLines])
    }

    func testRemovesBlankLinesInPropertyAfterEquals() {
        let input = """
        let foo =

            0
        """
        let output = """
        let foo =
            0
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInPropertyBeforeEquals() {
        let input = """
        let bar

            = 0
        """
        let output = """
        let bar
            = 0
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInFunctionWhereClause() {
        let input = """
        func foo<T>(_ t: T)

            where T: Equatable
        {
            print(t)
        }
        """
        let output = """
        func foo<T>(_ t: T)
            where T: Equatable
        {
            print(t)
        }
        """
        let output2 = """
        func foo<T: Equatable>(_ t: T) {
            print(t)
        }
        """
        testFormatting(for: input, [output, output2], rules: [.redundantBlankLines])
    }

    func testRemovesBlankLinesInTypeWhereClause() {
        let input = """
        struct Foo<T>

            where T: Equatable {}
        """
        let output = """
        struct Foo<T>
            where T: Equatable {}
        """
        let output2 = """
        struct Foo<T: Equatable>
        {}
        """
        testFormatting(for: input, [output, output2], rules: [.redundantBlankLines])
    }

    func testRemovesBlankLinesInParameterInout() {
        let input = """
        func foo(
            value: inout

                Int
        ) {
            print(value)
        }
        """
        let output = """
        func foo(
            value: inout
                Int
        ) {
            print(value)
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInParameterBorrowing() {
        let input = """
        func foo(
            value: borrowing

                Foo
        ) {
            print(value)
        }
        """
        let output = """
        func foo(
            value: borrowing
                Foo
        ) {
            print(value)
        }
        """
        let output2 = """
        func foo(
            value: Foo
        ) {
            print(value)
        }
        """
        testFormatting(for: input, [output, output2], rules: [.redundantBlankLines])
    }

    func testRemovesBlankLinesInParameterSome() {
        let input = """
        func foo(
            value: some

                View
        ) {
            print(value)
        }
        """
        let output = """
        func foo(
            value: some
                View
        ) {
            print(value)
        }
        """
        let output2 = """
        func foo(
            value: some View
        ) {
            print(value)
        }
        """
        testFormatting(for: input, [output, output2], rules: [.redundantBlankLines])
    }

    func testRemovesBlankLinesInParameterEscaping() {
        let input = """
        func foo(
            value: @escaping

            () -> Void
        ) {
            print(value)
        }
        """
        let output = """
        func foo(
            value: @escaping
            () -> Void
        ) {
            print(value)
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInParameterAutoclosure() {
        let input = """
        func foo(
            value: @autoclosure

            () -> Bool
        ) {
            print(value)
        }
        """
        let output = """
        func foo(
            value: @autoclosure
            () -> Bool
        ) {
            print(value)
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInParameterFunctionTypeArrow() {
        let input = """
        func foo(
            handler: (Int)

                -> Void
        ) {
            print(handler)
        }
        """
        let output = """
        func foo(
            handler: (Int)
                -> Void
        ) {
            print(handler)
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesInParameterFunctionTypeEffects() {
        let input = """
        func foo(
            handler: (Int)

            async throws -> Void
        ) {
            print(handler)
        }
        """
        let output = """
        func foo(
            handler: (Int)
            async throws -> Void
        ) {
            print(handler)
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLineAfterStatementLabel() {
        let input = """
        outer:

            for x in xs
        {
            print(x)
            break outer
        }
        """
        let output = """
        outer:
            for x in xs
        {
            print(x)
            break outer
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testPreservesBlankLineAfterBareReturn() {
        let input = """
        func foo() {
            return

                value()
        }
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }

    func testPreservesBlankLinesInInitializerExpression() {
        let input = """
        let value: Int = condition ? first :

            second
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }

    func testPreservesGroupedGenericConstraints() {
        let input = """
        struct Foo<T, U>: Equatable,

            Hashable where T: Equatable,

            U: Equatable {}
        """
        testFormatting(for: input, rule: .redundantBlankLines, exclude: [.simplifyGenericConstraints])
    }

    func testPreservesGroupedParameters() {
        let input = """
        func foo(
            first: Int,

            second: Int
        ) {
            print(first, second)
        }
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }

    func testPreservesBlankLineBeforeGuardElse() {
        let input = """
        guard condition

        else {
            return
        }
        """
        testFormatting(for: input, rule: .redundantBlankLines, exclude: [.elseOnSameLine])
    }

    func testPreservesBlankLineBeforePropertyBody() {
        let input = """
        var foo: Int

        {
            0
        }
        """
        testFormatting(for: input, rule: .redundantBlankLines, exclude: [.braces])
    }

    func testPreservesBlankLineInFunctionChain() {
        let input = """
        let x = foo

            .bar()
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }

    func testPreservesCommentsWithinDeclarationHeader() {
        let input = """
        let foo:

            // The stored value's type
            Int = 0
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }

    func testPreservesBlankLineAfterImportOfType() {
        let input = """
        package import struct TSCBasic.ByteString
        import class Foundation.NSObject

        package extension ByteString {
            func foo() {}
        }
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }
}
