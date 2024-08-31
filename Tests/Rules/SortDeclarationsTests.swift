//
//  SortDeclarationsTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 11/22/21.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class SortDeclarationsTests: XCTestCase {
    func testSortEnumBody() {
        let input = """
        // swiftformat:sort
        enum FeatureFlags {
            case upsellB
            case fooFeature(
                fooConfiguration: Foo,
                barConfiguration: Bar
            )
            case barFeature // Trailing comment -- bar feature
            /// Leading comment -- upsell A
            case upsellA(
                fooConfiguration: Foo,
                barConfiguration: Bar
            )
        }

        enum NextType {
            case foo
            case bar
        }
        """

        let output = """
        // swiftformat:sort
        enum FeatureFlags {
            case barFeature // Trailing comment -- bar feature
            case fooFeature(
                fooConfiguration: Foo,
                barConfiguration: Bar
            )
            /// Leading comment -- upsell A
            case upsellA(
                fooConfiguration: Foo,
                barConfiguration: Bar
            )
            case upsellB
        }

        enum NextType {
            case foo
            case bar
        }
        """

        testFormatting(for: input, output, rule: .sortDeclarations)
    }

    func testSortEnumBodyWithOnlyOneCase() {
        let input = """
        // swiftformat:sort
        enum FeatureFlags {
            case upsellB
        }
        """

        testFormatting(for: input, rule: .sortDeclarations)
    }

    func testSortEnumBodyWithoutCase() {
        let input = """
        // swiftformat:sort
        enum FeatureFlags {}
        """

        testFormatting(for: input, rule: .sortDeclarations)
    }

    func testNoSortUnannotatedType() {
        let input = """
        enum FeatureFlags {
            case upsellB
            case fooFeature
            case barFeature
            case upsellA
        }
        """

        testFormatting(for: input, rule: .sortDeclarations)
    }

    func testPreservesSortedBody() {
        let input = """
        // swiftformat:sort
        enum FeatureFlags {
            case barFeature
            case fooFeature
            case upsellA
            case upsellB
        }
        """

        testFormatting(for: input, rule: .sortDeclarations)
    }

    func testSortsTypeBody() {
        let input = """
        // swiftformat:sort
        enum FeatureFlags {
            case upsellB
            case fooFeature
            case barFeature
            case upsellA
        }
        """

        let output = """
        // swiftformat:sort
        enum FeatureFlags {
            case barFeature
            case fooFeature
            case upsellA
            case upsellB
        }
        """

        testFormatting(for: input, output, rule: .sortDeclarations, exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    func testSortClassWithMixedDeclarationTypes() {
        let input = """
        // swiftformat:sort
        class Foo {
            let quuxProperty = Quux()
            let barProperty = Bar()

            var fooComputedProperty: Foo {
                Foo()
            }

            func baazFunction() -> Baaz {
                Baaz()
            }
        }
        """

        let output = """
        // swiftformat:sort
        class Foo {
            func baazFunction() -> Baaz {
                Baaz()
            }
            let barProperty = Bar()

            var fooComputedProperty: Foo {
                Foo()
            }

            let quuxProperty = Quux()
        }
        """

        testFormatting(for: input, [output],
                       rules: [.sortDeclarations, .consecutiveBlankLines],
                       exclude: [.blankLinesBetweenScopes, .propertyType])
    }

    func testSortBetweenDirectiveCommentsInType() {
        let input = """
        enum FeatureFlags {
            // swiftformat:sort:begin
            case upsellB
            case fooFeature
            case barFeature
            case upsellA
            // swiftformat:sort:end

            var anUnsortedProperty: Foo {
                Foo()
            }
        }
        """

        let output = """
        enum FeatureFlags {
            // swiftformat:sort:begin
            case barFeature
            case fooFeature
            case upsellA
            case upsellB
            // swiftformat:sort:end

            var anUnsortedProperty: Foo {
                Foo()
            }
        }
        """

        testFormatting(for: input, output, rule: .sortDeclarations)
    }

    func testSortTopLevelDeclarations() {
        let input = """
        let anUnsortedGlobal = 0

        // swiftformat:sort:begin
        let sortThisGlobal = 1
        public let thisGlobalIsSorted = 2
        private let anotherSortedGlobal = 5
        let sortAllOfThem = 8
        // swiftformat:sort:end

        let anotherUnsortedGlobal = 9
        """

        let output = """
        let anUnsortedGlobal = 0

        // swiftformat:sort:begin
        private let anotherSortedGlobal = 5
        let sortAllOfThem = 8
        let sortThisGlobal = 1
        public let thisGlobalIsSorted = 2
        // swiftformat:sort:end

        let anotherUnsortedGlobal = 9
        """

        testFormatting(for: input, output, rule: .sortDeclarations)
    }

    func testSortDeclarationsSortsByNamePattern() {
        let input = """
        enum Namespace {}

        extension Namespace {
            static let foo = "foo"
            public static let bar = "bar"
            static let baaz = "baaz"
        }
        """

        let output = """
        enum Namespace {}

        extension Namespace {
            static let baaz = "baaz"
            public static let bar = "bar"
            static let foo = "foo"
        }
        """

        let options = FormatOptions(alphabeticallySortedDeclarationPatterns: ["Namespace"])
        testFormatting(for: input, [output], rules: [.sortDeclarations, .blankLinesBetweenScopes], options: options)
    }

    func testSortDeclarationsWontSortByNamePatternInComment() {
        let input = """
        enum Namespace {}

        /// Constants
        /// enum Constants
        extension Namespace {
            static let foo = "foo"
            public static let bar = "bar"
            static let baaz = "baaz"
        }
        """

        let options = FormatOptions(alphabeticallySortedDeclarationPatterns: ["Constants"])
        testFormatting(for: input, rules: [.sortDeclarations, .blankLinesBetweenScopes], options: options)
    }

    func testSortDeclarationsUsesLocalizedCompare() {
        let input = """
        // swiftformat:sort
        enum FeatureFlags {
            case upsella
            case upsellA
            case upsellb
            case upsellB
        }
        """

        testFormatting(for: input, rule: .sortDeclarations)
    }
}
