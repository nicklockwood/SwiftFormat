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
}
