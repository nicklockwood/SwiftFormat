//
//  OpaqueGenericParametersTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/5/22.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class OpaqueGenericParametersTests: XCTestCase {
    func testGenericNotModifiedBelowSwift5_7() {
        let input = """
        func foo<T>(_ value: T) {
            print(value)
        }
        """

        let options = FormatOptions(swiftVersion: "5.6")
        testFormatting(for: input, rule: .opaqueGenericParameters, options: options)
    }

    func testOpaqueGenericParameterWithNoConstraint() {
        let input = """
        func foo<T>(_ value: T) {
            print(value)
        }

        init<T>(_ value: T) {
            print(value)
        }

        subscript<T>(_ value: T) -> Foo {
            Foo(value)
        }

        subscript<T>(_ value: T) -> Foo {
            get {
                Foo(value)
            }
            set {
                print(newValue)
            }
        }
        """

        let output = """
        func foo(_ value: some Any) {
            print(value)
        }

        init(_ value: some Any) {
            print(value)
        }

        subscript(_ value: some Any) -> Foo {
            Foo(value)
        }

        subscript(_ value: some Any) -> Foo {
            get {
                Foo(value)
            }
            set {
                print(newValue)
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .opaqueGenericParameters, options: options)
    }

    func testDisableSomeAnyGenericType() {
        let input = """
        func foo<T>(_ value: T) {
            print(value)
        }
        """

        let options = FormatOptions(useSomeAny: false, swiftVersion: "5.7")
        testFormatting(for: input, rule: .opaqueGenericParameters, options: options)
    }

    func testOpaqueGenericParameterWithConstraintInBracket() {
        let input = """
        func foo<T: Fooable, U: Barable>(_ fooable: T, barable: U) -> Baaz {
            print(fooable, barable)
        }

        init<T: Fooable, U: Barable>(_ fooable: T, barable: U) {
            print(fooable, barable)
        }

        subscript<T: Fooable, U: Barable>(_ fooable: T, barable: U) -> Any {
            (fooable, barable)
        }
        """

        let output = """
        func foo(_ fooable: some Fooable, barable: some Barable) -> Baaz {
            print(fooable, barable)
        }

        init(_ fooable: some Fooable, barable: some Barable) {
            print(fooable, barable)
        }

        subscript(_ fooable: some Fooable, barable: some Barable) -> Any {
            (fooable, barable)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .opaqueGenericParameters, options: options)
    }

    func testOpaqueGenericParameterWithConstraintsInWhereClause() {
        let input = """
        func foo<T, U>(_ t: T, _ u: U) -> Baaz where T: Fooable, T: Barable, U: Baazable {
            print(t, u)
        }

        init<T, U>(_ t: T, _ u: U) where T: Fooable, T: Barable, U: Baazable {
            print(t, u)
        }
        """

        let output = """
        func foo(_ t: some Fooable & Barable, _ u: some Baazable) -> Baaz {
            print(t, u)
        }

        init(_ t: some Fooable & Barable, _ u: some Baazable) {
            print(t, u)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .opaqueGenericParameters, options: options)
    }

    func testOpaqueGenericParameterCanRemoveOneButNotOthers_onOneLine() {
        let input = """
        func foo<S: Baazable, T: Fooable, U: Barable>(_ foo: T, bar1: U, bar2: U) where S.AssociatedType == Baaz, T: Quuxable, U: Qaaxable {
            print(foo, bar1, bar2)
        }
        """

        let output = """
        func foo<S: Baazable, U: Barable>(_ foo: some Fooable & Quuxable, bar1: U, bar2: U) where S.AssociatedType == Baaz, U: Qaaxable {
            print(foo, bar1, bar2)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .opaqueGenericParameters, options: options)
    }

    func testOpaqueGenericParameterCanRemoveOneButNotOthers_onMultipleLines() {
        let input = """
        func foo<
            S: Baazable,
            T: Fooable,
            U: Barable
        >(_ foo: T, bar1: U, bar2: U) where
            S.AssociatedType == Baaz,
            T: Quuxable,
            U: Qaaxable
        {
            print(foo, bar1, bar2)
        }
        """

        let output = """
        func foo<
            S: Baazable,
            U: Barable
        >(_ foo: some Fooable & Quuxable, bar1: U, bar2: U) where
            S.AssociatedType == Baaz,
            U: Qaaxable
        {
            print(foo, bar1, bar2)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .opaqueGenericParameters, options: options)
    }

    func testOpaqueGenericParameterWithUnknownAssociatedTypeConstraint() {
        // If we knew that `T.AssociatedType` was the protocol's primary
        // associated type we could update this to `value: some Fooable<Bar>`,
        // but we don't necessarily have that type information available.
        //  - If primary associated types become very widespread, it may make
        //    sense to assume (or have an option to assume) that this would work.
        let input = """
        func foo<T: Fooable>(_ value: T) where T.AssociatedType == Bar {
            print(value)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .opaqueGenericParameters, options: options)
    }

    func testOpaqueGenericParameterWithAssociatedTypeConformance() {
        // There is no opaque generic parameter syntax that supports this type of constraint
        let input = """
        func foo<T: Fooable>(_ value: T) where T.AssociatedType: Bar {
            print(value)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .opaqueGenericParameters, options: options)
    }

    func testOpaqueGenericParameterWithKnownAssociatedTypeConstraint() {
        // For known types (like those in the standard library),
        // we are able to know their primary associated types
        let input = """
        func foo<T: Collection>(_ value: T) where T.Element == Foo {
            print(value)
        }
        """

        let output = """
        func foo(_ value: some Collection<Foo>) {
            print(value)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .opaqueGenericParameters, options: options)
    }

    func testOpaqueGenericParameterWithAssociatedTypeConstraint() {
        let input = """
        func foo<T: Collection<Foo>>(_: T) {}
        func bar<T>(_: T) where T: Collection<Foo> {}
        func baaz<T>(_: T) where T == any Collection<Foo> {}
        """

        let output = """
        func foo(_: some Collection<Foo>) {}
        func bar(_: some Collection<Foo>) {}
        func baaz(_: any Collection<Foo>) {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .opaqueGenericParameters, options: options)
    }

    func testGenericTypeUsedInMultipleParameters() {
        let input = """
        func foo<T: Fooable>(_ first: T, second: T) {
            print(first, second)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .opaqueGenericParameters, options: options)
    }

    func testGenericTypeUsedInClosureMultipleTimes() {
        let input = """
        func foo<T: Fooable>(_ closure: (T) -> T) {
            closure(foo)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .opaqueGenericParameters, options: options)
    }

    func testGenericTypeUsedAsReturnType() {
        // A generic used as a return type is different from an opaque result type (SE-244).
        // In `-> T where T: Fooable`, the generic type is caller-specified, but with
        // `-> some Fooable` the generic type is specified by the function implementation.
        // Because those represent different concepts, we can't convert between them.
        let input = """
        func foo<T: Fooable>() -> T {
            // ...
        }

        func bar<T>() -> T where T: Barable {
            // ...
        }

        func baaz<T: Baazable>() -> Set<SomeComplicatedNestedGeneric<T, Bar>> {
            // ...
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .opaqueGenericParameters, options: options)
    }

    func testGenericTypeUsedAsReturnTypeAndParameter() {
        // Since we can't change the return value, we can't change any of the use cases of T
        let input = """
        func foo<T: Fooable>(_ value: T) -> T {
            value
        }

        func bar<T>(_ value: T) -> T where T: Barable {
            value
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .opaqueGenericParameters, options: options)
    }

    func testGenericTypeWithClosureInWhereClauseDoesntCrash() {
        let input = """
        struct Foo<U> {
            func bar<V>(_: V) where U == @Sendable (V) -> Int {}
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .opaqueGenericParameters, options: options)
    }

    func testGenericExtensionSameTypeConstraint() {
        let input = """
        func foo<U>(_ u: U) where U == String {
            print(u)
        }
        """

        let output = """
        func foo(_ u: String) {
            print(u)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .opaqueGenericParameters, options: options)
    }

    func testGenericExtensionSameTypeGenericConstraint() {
        let input = """
        func foo<U, V>(_ u: U, _ v: V) where U == V {
            print(u, v)
        }

        func foo<U, V>(_ u: U, _ v: V) where V == U {
            print(u, v)
        }
        """

        let output = """
        func foo<V>(_ u: V, _ v: V) {
            print(u, v)
        }

        func foo<U>(_ u: U, _ v: U) {
            print(u, v)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .opaqueGenericParameters, options: options)
    }

    func testIssue1269() {
        let input = """
        func bar<V, R>(
            _: V,
            _ work: () -> R
        ) -> R
            where Value == @Sendable () -> V,
            V: Sendable
        {
            work()
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .opaqueGenericParameters, options: options)
    }

    func testVariadicParameterNotConvertedToOpaqueGeneric() {
        let input = """
        func variadic<T>(_ t: T...) {
            print(t)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .opaqueGenericParameters, options: options)
    }

    func testNonGenericVariadicParametersDoesntPreventUsingOpaqueGenerics() {
        let input = """
        func variadic<U>(t: Any..., u: U, v: Any...) {
            print(t, u, v)
        }
        """

        let output = """
        func variadic(t: Any..., u: some Any, v: Any...) {
            print(t, u, v)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .opaqueGenericParameters, options: options)
    }

    func testIssue1275() {
        let input = """
        func loggedKeypath<T: CustomStringConvertible>(
            by _: KeyPath<T, Element>...,
            actionKeyword _: UserActionKeyword,
            identifier _: String
        ) {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .opaqueGenericParameters, options: options)
    }

    func testIssue1278() {
        let input = """
        public struct Foo<Value> {
            public func withValue<V, R>(
                _: V,
                operation _: () throws -> R
            ) rethrows -> R
                where Value == @Sendable () -> V,
                V: Sendable
            {}

            public func withValue<V, R>(
                _: V,
                operation _: () async throws -> R
            ) async rethrows -> R
                where Value == () -> V
            {}
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .opaqueGenericParameters, options: options)
    }

    func testIssue1392() {
        let input = """
        public struct Ref<Value> {}

        public extension Ref {
            static func weak<Base: AnyObject, T>(
                _: Base,
                _: ReferenceWritableKeyPath<Base, Value>
            ) -> Ref<Value> where T? == Value {}
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .opaqueGenericParameters, options: options)
    }

    func testIssue1684() {
        let input = """
        @_specialize(where S == Int)
        func foo<S: Sequence<Element>>(t: S) {
            print(t)
        }
        """
        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .opaqueGenericParameters, options: options)
    }

    func testGenericSimplifiedInMethodWithAttributeOrMacro() {
        let input = """
        @MyResultBuilder
        func foo<T: Foo, U: Bar>(foo: T, bar: U) -> MyResult {
            foo
            bar
        }

        @MyFunctionBodyMacro(withArgument: true)
        func foo<T: Foo, U: Bar>(foo: T, bar: U) {
            print(foo, bar)
        }
        """

        let output = """
        @MyResultBuilder
        func foo(foo: some Foo, bar: some Bar) -> MyResult {
            foo
            bar
        }

        @MyFunctionBodyMacro(withArgument: true)
        func foo(foo: some Foo, bar: some Bar) {
            print(foo, bar)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .opaqueGenericParameters, options: options)
    }

    func testGenericThrowsTypeNotTreatedAsAny() {
        let input = """
        func sample<ErrorType>(error: ErrorType) throws(ErrorType) {
            throw error
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .opaqueGenericParameters, options: options)
    }

    // MARK: - genericExtensions

    func testGenericExtensionNotModifiedBeforeSwift5_7() {
        let input = """
        extension Array where Element == Foo {}
        """

        let options = FormatOptions(swiftVersion: "5.6")
        testFormatting(for: input, rule: .opaqueGenericParameters, options: options, exclude: [.emptyExtensions])
    }

    func testOpaqueGenericParametersRuleSuccessfullyTerminatesInSampleCode() {
        let input = """
        public class Service {
            public func run() {}
            private let foo: Foo<Void, Void>
            private func a() -> Eventual<Void> {}
            private func b() -> Eventual<Void> {}
            private func c() -> Eventual<Void> {}
            private func d() -> Eventual<Void> {}
            private func e() -> Eventual<Void> {}
            private func f() -> Eventual<Void> {}
            private func g() -> Eventual<Void> {}
            private func h() -> Eventual<Void> {}
            private func i() {}
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .opaqueGenericParameters, options: options)
    }

    func testGenericParameterUsedInConstraintOfOtherTypeNotChanged() {
        let input = """
        func combineResults<ASuccess, AFailure, BSuccess, BFailure>(
            _: Potential<ASuccess, AFailure>,
            _: Potential<BSuccess, BFailure>
        ) -> Potential<Success, Never> where
            Success == (Result<ASuccess, AFailure>, Result<BSuccess, BFailure>),
            Failure == Never
        {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .opaqueGenericParameters, options: options)
    }

    func testGenericParameterInheritedFromContextNotRemoved() {
        let input = """
        func assign<Target>(
            on _: DispatchQueue,
            to _: AssignTarget<Target>,
            at _: ReferenceWritableKeyPath<Target, Value>
        ) where Value: Equatable {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .opaqueGenericParameters, options: options)
    }

    func testGenericParameterUsedInBodyNotRemoved() {
        let input = """
        func foo<T>(_ value: T) {
            typealias TTT = T
            let casted = value as TTT
            print(casted)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .opaqueGenericParameters, options: options)
    }

    func testGenericParameterUsedAsClosureParameterNotRemoved() {
        let input = """
        func foo<Foo>(_: (Foo) -> Void) {}
        func bar<Foo>(_: (Foo) throws -> Void) {}
        func baz<Foo>(_: (Foo) throws(Bar) -> Void) {}
        func baaz<Foo>(_: (Foo) async -> Void) {}
        func qux<Foo>(_: (Foo) async throws -> Void) {}
        func quux<Foo>(_: (Foo) async throws(Bar) -> Void) {}
        func qaax<Foo>(_: ([Foo]) -> Void) {}
        func qaax<Foo>(_: ((Foo, Bar)) -> Void) {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .opaqueGenericParameters, options: options)
    }

    func testFinalGenericParamRemovedProperlyWithoutHangingComma() {
        let input = """
        func foo<Bar, Baaz>(
            bar _: (Bar) -> Void,
            baaz _: Baaz
        ) {}
        """

        let output = """
        func foo<Bar>(
            bar _: (Bar) -> Void,
            baaz _: some Any
        ) {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .opaqueGenericParameters, options: options)
    }

    func testAddsParensAroundTypeIfNecessary() {
        let input = """
        func foo<Foo>(_: Foo.Type) {}
        func bar<Foo>(_: Foo?) {}
        """

        let output = """
        func foo(_: (some Any).Type) {}
        func bar(_: (some Any)?) {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .opaqueGenericParameters, options: options)
    }

    func testHandlesSingleExactTypeGenericConstraint() {
        let input = """
        func foo<T>(with _: T) -> Foo where T == Dependencies {}
        """

        let output = """
        func foo(with _: Dependencies) -> Foo {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .opaqueGenericParameters, options: options)
    }

    func testGenericConstraintThatIsGeneric() {
        let input = """
        class Foo<Bar, Baaz> {}
        func foo<T: Foo<String, String>>(_: T) {}
        class Bar<Baaz> {}
        func bar<T: Bar<String>>(_: T) {}
        """

        let output = """
        class Foo<Bar, Baaz> {}
        func foo(_: some Foo<String, String>) {}
        class Bar<Baaz> {}
        func bar(_: some Bar<String>) {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .opaqueGenericParameters, options: options)
    }

    func testDoesntChangeTypeWithConstraintThatReferencesItself() {
        // This is a weird one but in the actual code this comes from `ViewModelContext` is both defined
        // on the parent type of this declaration (where it has additional important constraints),
        // and again in the method itself. Changing this to an opaque parameter breaks the build, because
        // it loses the generic constraints applied by the parent type.
        let input = """
        func makeSections<ViewModelContext: RoutingBehaviors<ViewModelContext.Dependencies>>(_: ViewModelContext) {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .opaqueGenericParameters, options: options)
    }

    func testOpaqueGenericParametersDoesntleaveTrailingComma() {
        let input = """
        func f<T, U>(x: U) -> T where T: A, U: B {}
        """
        let output = """
        func f<T>(x: some B) -> T where T: A {}
        """
        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .opaqueGenericParameters,
                       options: options, exclude: [.unusedArguments])
    }

    func testUpdatesProtocolRequirements() {
        let input = """
        protocol FooProtocol {
            func foo<T>(_ foos: T) where T: Collection, T.Element == Foo
            func bar<T: Collection>(_ bars: T)
        }
        """

        let output = """
        protocol FooProtocol {
            func foo(_ foos: some Collection<Foo>) 
            func bar(_ bars: some Collection)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .opaqueGenericParameters,
                       options: options, exclude: [.unusedArguments, .trailingSpace])
    }

    func testPreservesGenericUsedInBodyAtEndOfScope() {
        let input = """
        extension ModelTransformer {
          public static func decodableTransformer<T: Decodable>(for _: T.Type) -> ValueTransformer {
            CodableTransformer<T>.default
          }
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .opaqueGenericParameters,
                       options: options, exclude: [.unusedArguments, .indent])
    }

    func testUpdatesNestedFunction() {
        let input = """
        func test() {
            func foo<T: Fooable, U>(_ fooable: T, barable: U) -> Baaz where U: Barable {
                print(fooable, barable)
            }

            print(foo(fooable, barable))
        }
        """

        let output = """
        func test() {
            func foo(_ fooable: some Fooable, barable: some Barable) -> Baaz {
                print(fooable, barable)
            }

            print(foo(fooable, barable))
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .opaqueGenericParameters, options: options)
    }
}
