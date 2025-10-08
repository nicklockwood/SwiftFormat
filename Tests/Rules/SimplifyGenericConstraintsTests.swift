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

    func testPartialSimplification() {
        let input = """
        struct Foo<T, U> where T: Hashable, U.Element == String {}
        """
        let output = """
        struct Foo<T: Hashable, U> where U.Element == String {}
        """
        testFormatting(for: input, output, rule: .simplifyGenericConstraints)
    }
}
