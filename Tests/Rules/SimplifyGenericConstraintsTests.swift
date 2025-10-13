//
//  SimplifyGenericConstraintsTests.swift
//  SwiftFormatTests
//
//  Created by Manuel Lopez on 10/8/25.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class SimplifyGenericConstraintsTests: XCTestCase {
    func testSimplifyStructGenericConstraint() {
        let input = """
        struct Foo<T> where T: Hashable {}
        """
        let output = """
        struct Foo<T: Hashable> {}
        """
        testFormatting(for: input, output, rule: .simplifyGenericConstraints)
    }

    func testSimplifyClassGenericConstraint() {
        let input = """
        class Bar<Element> where Element: Equatable {
            // ...
        }
        """
        let output = """
        class Bar<Element: Equatable> {
            // ...
        }
        """
        testFormatting(for: input, output, rule: .simplifyGenericConstraints)
    }

    func testSimplifyEnumGenericConstraint() {
        let input = """
        enum Result<Value, Error> where Value: Decodable, Error: Swift.Error {}
        """
        let output = """
        enum Result<Value: Decodable, Error: Swift.Error> {}
        """
        testFormatting(for: input, output, rule: .simplifyGenericConstraints)
    }

    func testSimplifyActorGenericConstraint() {
        let input = """
        actor Worker<T> where T: Sendable {}
        """
        let output = """
        actor Worker<T: Sendable> {}
        """
        testFormatting(for: input, output, rule: .simplifyGenericConstraints)
    }

    func testSimplifyMultipleConstraintsOnSameType() {
        let input = """
        struct Foo<T> where T: Hashable, T: Codable {}
        """
        let output = """
        struct Foo<T: Hashable & Codable> {}
        """
        testFormatting(for: input, output, rule: .simplifyGenericConstraints)
    }

    func testSimplifyMultipleGenericParameters() {
        let input = """
        struct Foo<T, U> where T: Hashable, U: Codable {}
        """
        let output = """
        struct Foo<T: Hashable, U: Codable> {}
        """
        testFormatting(for: input, output, rule: .simplifyGenericConstraints)
    }

    func testPreserveExistingInlineConstraints() {
        let input = """
        struct Foo<T: Equatable, U> where U: Codable {}
        """
        let output = """
        struct Foo<T: Equatable, U: Codable> {}
        """
        testFormatting(for: input, output, rule: .simplifyGenericConstraints)
    }

    func testPreserveConcreteTypeConstraints() {
        let input = """
        struct Foo<T> where T.Element == String {}
        """
        testFormatting(for: input, rule: .simplifyGenericConstraints)
    }

    func testPreserveMixedConstraints() {
        let input = """
        struct Foo<T> where T: Collection, T.Element == Int {}
        """
        let output = """
        struct Foo<T: Collection> where T.Element == Int {}
        """
        testFormatting(for: input, output, rule: .simplifyGenericConstraints)
    }

    func testDoesntAffectStructsWithoutWhereClause() {
        let input = """
        struct Foo<T: Hashable> {}
        """
        testFormatting(for: input, rule: .simplifyGenericConstraints)
    }

    func testDoesntAffectStructsWithoutGenerics() {
        let input = """
        struct Foo {}
        """
        testFormatting(for: input, rule: .simplifyGenericConstraints)
    }

    func testDoesntAffectWhereClauseWithOnlyConcreteTypes() {
        let input = """
        struct Foo<T, U> where T == U {}
        """
        testFormatting(for: input, rule: .simplifyGenericConstraints)
    }

    func testRealWorldExample() {
        let input = """
        public struct URLImage<Content, Placeholder> where Content: View, Placeholder: View {
            let url: URL
            let content: (Image) -> Content
            let placeholder: () -> Placeholder
        }
        """
        let output = """
        public struct URLImage<Content: View, Placeholder: View> {
            let url: URL
            let content: (Image) -> Content
            let placeholder: () -> Placeholder
        }
        """
        testFormatting(for: input, output, rule: .simplifyGenericConstraints)
    }

    func testMultilineWhereClause() {
        let input = """
        struct Foo<T, U>
            where T: Hashable,
                  U: Codable
        {
            // ...
        }
        """
        let output = """
        struct Foo<T: Hashable, U: Codable>
            {
            // ...
        }
        """
        testFormatting(for: input, output, rule: .simplifyGenericConstraints, exclude: [.braces, .indent])
    }

    func testSimplifyFunctionGenericConstraint() {
        let input = """
        func process<T>(_ value: T) where T: Codable {}
        """
        let output = """
        func process<T: Codable>(_ value: T) {}
        """
        testFormatting(for: input, output, rule: .simplifyGenericConstraints, exclude: [.unusedArguments])
    }

    func testSimplifyFunctionWithMultipleGenericParameters() {
        let input = """
        func compare<T, U>(_ lhs: T, _ rhs: U) where T: Equatable, U: Comparable {}
        """
        let output = """
        func compare<T: Equatable, U: Comparable>(_ lhs: T, _ rhs: U) {}
        """
        testFormatting(for: input, output, rule: .simplifyGenericConstraints, exclude: [.unusedArguments])
    }

    func testSimplifyFunctionWithMultipleConstraintsOnSameType() {
        let input = """
        func handle<T>(_ value: T) where T: Codable, T: Hashable {}
        """
        let output = """
        func handle<T: Codable & Hashable>(_ value: T) {}
        """
        testFormatting(for: input, output, rule: .simplifyGenericConstraints, exclude: [.unusedArguments])
    }

    func testPreserveFunctionWithMixedConstraints() {
        let input = """
        func process<T>(_ value: T) where T: Collection, T.Element == String {}
        """
        let output = """
        func process<T: Collection>(_ value: T) where T.Element == String {}
        """
        testFormatting(for: input, output, rule: .simplifyGenericConstraints, exclude: [.unusedArguments])
    }

    // MARK: - Interaction with opaqueGenericParameters

    func testWorksWithOpaqueGenericParametersToFullySimplify() {
        let input = """
        func foo<T>(_ value: T) where T: Fooable {}
        """
        let output = """
        func foo(_ value: some Fooable) {}
        """
        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, [output], rules: [.simplifyGenericConstraints, .opaqueGenericParameters],
                       options: options, exclude: [.unusedArguments])
    }

    func testWorksWithOpaqueGenericParametersFullConversion() {
        let input = """
        func foo<T, U>(_ t: T, _ u: U) where T: Fooable, U: Barable {}
        """
        let output = """
        func foo(_ t: some Fooable, _ u: some Barable) {}
        """
        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, [output], rules: [.simplifyGenericConstraints, .opaqueGenericParameters],
                       options: options, exclude: [.unusedArguments])
    }

    func testSimplificationOnlyWhenOpaqueCannotApply() {
        let input = """
        func foo<T>(_ value: T) -> T where T: Fooable {}
        """
        let output = """
        func foo<T: Fooable>(_ value: T) -> T {}
        """
        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, [output], rules: [.simplifyGenericConstraints, .opaqueGenericParameters],
                       options: options, exclude: [.unusedArguments])
    }

    func testPartialSimplification() {
        let input = """
        struct Foo<T, U> where T: Hashable, U.Element == String {}
        """
        let output = """
        struct Foo<T: Hashable, U> where U.Element == String {}
        """
        testFormatting(for: input, output, rule: .simplifyGenericConstraints)
    }

    // MARK: - Complex cases with many generics

    func testStructWithFourGenerics() {
        let input = """
        struct Foo<A, B, C, D> where A: Hashable, B: Codable, C: Equatable, D: Comparable {}
        """
        let output = """
        struct Foo<A: Hashable, B: Codable, C: Equatable, D: Comparable> {}
        """
        testFormatting(for: input, output, rule: .simplifyGenericConstraints)
    }

    func testStructWithSixGenerics() {
        let input = """
        struct Complex<A, B, C, D, E, F>
            where A: Hashable,
                  B: Codable,
                  C: Equatable,
                  D: Comparable,
                  E: Collection,
                  F: Sequence
        {
            var values: (A, B, C, D, E, F)
        }
        """
        let output = """
        struct Complex<A: Hashable, B: Codable, C: Equatable, D: Comparable, E: Collection, F: Sequence>
            {
            var values: (A, B, C, D, E, F)
        }
        """
        testFormatting(for: input, output, rule: .simplifyGenericConstraints, exclude: [.braces, .indent])
    }

    func testFunctionWithFiveGenerics() {
        let input = """
        func process<A, B, C, D, E>(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E)
            where A: Codable, B: Hashable, C: Equatable, D: Comparable, E: Collection
        {}
        """
        let output = """
        func process<A: Codable, B: Hashable, C: Equatable, D: Comparable, E: Collection>(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E)
            {}
        """
        testFormatting(for: input, output, rule: .simplifyGenericConstraints, exclude: [.unusedArguments, .indent])
    }

    func testManyGenericsWithMixedConstraints() {
        let input = """
        struct Foo<A, B, C, D, E> where A: Hashable, B: Collection, B.Element == String, C: Codable, D.Index == Int, E: Equatable {
            var values: (A, B, C, D, E)
        }
        """
        let output = """
        struct Foo<A: Hashable, B: Collection, C: Codable, D, E: Equatable> where B.Element == String, D.Index == Int {
            var values: (A, B, C, D, E)
        }
        """
        testFormatting(for: input, output, rule: .simplifyGenericConstraints)
    }

    func testManyGenericsWithMultipleConstraintsPerType() {
        let input = """
        func transform<A, B, C, D>(_ a: A, _ b: B, _ c: C, _ d: D)
            where A: Hashable,
                  A: Codable,
                  B: Collection,
                  B: Equatable,
                  C: Comparable,
                  D: Sequence,
                  D: Sendable
        {}
        """
        let output = """
        func transform<A: Hashable & Codable, B: Collection & Equatable, C: Comparable, D: Sequence & Sendable>(_ a: A, _ b: B, _ c: C, _ d: D)
            {}
        """
        testFormatting(for: input, output, rule: .simplifyGenericConstraints, exclude: [.unusedArguments, .indent])
    }

    // MARK: - Constraints on generics not in parameter list

    func testPreserveConstraintsForGenericsNotInParameterList() {
        // U is not in the function's generic parameters, so the constraint must be preserved
        let input = """
        func process<T>(value: T) where U: Hashable {
            print(U.self)
        }
        """
        testFormatting(for: input, rule: .simplifyGenericConstraints, exclude: [.unusedArguments])
    }

    func testCombineInlineAndWhereClauseConstraints() {
        // When a generic has both inline and where clause constraints, combine with &
        let input = """
        struct Config<T: Hashable> where T: Codable {}
        """
        let output = """
        struct Config<T: Hashable & Codable> {}
        """
        testFormatting(for: input, output, rule: .simplifyGenericConstraints)
    }

    func testCombineMultipleInlineAndWhereClauseConstraints() {
        // Multiple constraints should all be combined with &
        let input = """
        struct Config<T: Hashable, U: Codable> where T: Sendable, U: Equatable {}
        """
        let output = """
        struct Config<T: Hashable & Sendable, U: Codable & Equatable> {}
        """
        testFormatting(for: input, output, rule: .simplifyGenericConstraints)
    }
}
