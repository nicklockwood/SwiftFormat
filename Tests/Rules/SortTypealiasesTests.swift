//
//  SortTypealiasesTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 5/6/23.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class SortTypealiasesTests: XCTestCase {
    func testSortSingleLineTypealias() {
        let input = """
        typealias Placeholders = Foo & Bar & Quux & Baaz
        """

        let output = """
        typealias Placeholders = Baaz & Bar & Foo & Quux
        """

        testFormatting(for: input, output, rule: .sortTypealiases)
    }

    func testSortMultilineTypealias() {
        let input = """
        typealias Placeholders = Foo & Bar
            & Quux & Baaz
        """

        let output = """
        typealias Placeholders = Baaz & Bar
            & Foo & Quux
        """

        testFormatting(for: input, output, rule: .sortTypealiases)
    }

    func testSortMultilineTypealiasWithComments() {
        let input = """
        typealias Placeholders = Foo & Bar // Comment about Bar
            // Comment about Quux
            & Quux & Baaz // Comment about Baaz
        """

        let output = """
        typealias Placeholders = Baaz // Comment about Baaz
            & Bar // Comment about Bar
            & Foo
            // Comment about Quux
            & Quux
        """

        testFormatting(for: input, [output], rules: [.sortTypealiases, .indent, .trailingSpace])
    }

    func testSortWrappedMultilineTypealias1() {
        let input = """
        typealias Dependencies = FooProviding
            & BarProviding
            & BaazProviding
            & QuuxProviding
        """

        let output = """
        typealias Dependencies = BaazProviding
            & BarProviding
            & FooProviding
            & QuuxProviding
        """

        testFormatting(for: input, output, rule: .sortTypealiases)
    }

    func testSortWrappedMultilineTypealias2() {
        let input = """
        typealias Dependencies
            = FooProviding
            & BarProviding
            & BaazProviding
            & QuuxProviding
        """

        let output = """
        typealias Dependencies
            = BaazProviding
            & BarProviding
            & FooProviding
            & QuuxProviding
        """

        testFormatting(for: input, output, rule: .sortTypealiases)
    }

    func testSortWrappedMultilineTypealiasWithAny() {
        let input = """
        typealias Dependencies
            = any FooProviding
            & any BarProviding
            & any BaazProviding
            & any QuuxProviding
        """

        let output = """
        typealias Dependencies
            = any BaazProviding
            & any BarProviding
            & any FooProviding
            & any QuuxProviding
        """

        testFormatting(for: input, output, rule: .sortTypealiases)
    }

    func testSortWrappedMultilineTypealiasWithMixedAny() {
        let input = """
        typealias Dependencies
            = any FooProviding
            & BarProviding
            & any BaazProviding
            & QuuxProviding
        """

        let output = """
        typealias Dependencies
            = any BaazProviding
            & BarProviding
            & any FooProviding
            & QuuxProviding
        """

        testFormatting(for: input, output, rule: .sortTypealiases)
    }

    func testSortWrappedMultilineTypealiasWithComments() {
        let input = """
        typealias Dependencies
            // Comment about FooProviding
            = FooProviding
            // Comment about BarProviding
            & BarProviding
            & QuuxProviding // Comment about QuuxProviding
            // Comment about BaazProviding
            & BaazProviding // Comment about BaazProviding
        """

        let output = """
        typealias Dependencies
            // Comment about BaazProviding
            = BaazProviding // Comment about BaazProviding
            // Comment about BarProviding
            & BarProviding
            // Comment about FooProviding
            & FooProviding
            & QuuxProviding // Comment about QuuxProviding
        """

        testFormatting(for: input, output, rule: .sortTypealiases)
    }

    func testSortTypealiasesWithAssociatedTypes() {
        let input = """
        typealias Collections
            = Collection<Int>
            & Collection<String>
            & Collection<Double>
            & Collection<Float>
        """

        let output = """
        typealias Collections
            = Collection<Double>
            & Collection<Float>
            & Collection<Int>
            & Collection<String>
        """

        testFormatting(for: input, output, rule: .sortTypealiases)
    }

    func testSortTypeAliasesAndRemoveDuplicates() {
        let input = """
        typealias Placeholders = Foo & Bar & Quux & Baaz & Bar

        typealias Dependencies1
            = FooProviding
            & BarProviding
            & BaazProviding
            & QuuxProviding
            & FooProviding

        typealias Dependencies2
            = FooProviding
            & BarProviding
            & BaazProviding
            & QuuxProviding
            & BaazProviding
        """

        let output = """
        typealias Placeholders = Baaz & Bar & Foo & Quux

        typealias Dependencies1
            = BaazProviding
            & BarProviding
            & FooProviding
            & QuuxProviding

        typealias Dependencies2
            = BaazProviding
            & BarProviding
            & FooProviding
            & QuuxProviding
        """

        testFormatting(for: input, output, rule: .sortTypealiases)
    }

    func testSortSingleLineTypealiasBeginningWithAny() {
        let input = """
        typealias Placeholders = any Bar & Foo
        """
        testFormatting(for: input, rule: .sortTypealiases)
    }

    func testCollectionTypealiasWithArrayOfExistentialTypes() {
        let input = """
        public typealias Parameters = [any Any & Sendable]
        """
        testFormatting(for: input, rule: .sortTypealiases)
    }

    func testCollectionTypealiasWithDictionaryOfExistentialTypes() {
        let input = """
        public typealias Parameters = [any Hashable & Sendable: any Any & Sendable]
        """
        testFormatting(for: input, rule: .sortTypealiases)
    }

    func testCollectionTypealiasWithOptionalExistentialType() {
        let input = """
        public typealias Parameters = (Hashable & Sendable)?
        """
        testFormatting(for: input, rule: .sortTypealiases)
    }

    func testCollectionTypealiasWithGenericExistentialType() {
        let input = """
        public typealias Parameters = Result<any Hashable & Sendable, any Error & Sendable>
        """
        testFormatting(for: input, rule: .sortTypealiases)
    }

    func testCollectionTypealiasWithExistentialClosureType() {
        let input = """
        public typealias Parameters = (any Hashable & Sendable, any Error & Sendable) -> any Equatable & Codable
        """
        testFormatting(for: input, rule: .sortTypealiases)
    }
}
