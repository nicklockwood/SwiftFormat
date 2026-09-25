//
//  SortDeclarationsTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 11/22/21.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class SortDeclarationsTests: XCTestCase {
    func testSortNestedDeclarationsDoesNotMoveClosingBraceIndentation() {
        let input = """
        public extension String {
            // swiftformat:sort
            enum Feature {
                /// comment
                case bFeature = "bFeature"
                /// comment
                case cFeature = "cFeature"
                /// comment
                case aFeature = "aFeature" // Trailing comment -- a feature
            }

            // swiftformat:sort
            extension Feature {
                /// comment
                var b: Bool {
                    true
                }
                /// comment
                var c: Bool {
                    true
                }
                /// comment
                var a: Bool {
                    true
                }
            }
        }
        """

        let output = """
        public extension String {
            // swiftformat:sort
            enum Feature {
                /// comment
                case aFeature = "aFeature" // Trailing comment -- a feature
                /// comment
                case bFeature = "bFeature"
                /// comment
                case cFeature = "cFeature"
            }

            // swiftformat:sort
            extension Feature {
                /// comment
                var a: Bool {
                    true
                }
                /// comment
                var b: Bool {
                    true
                }
                /// comment
                var c: Bool {
                    true
                }
            }
        }
        """

        testFormatting(for: input, output, rule: .sortDeclarations, exclude: [.blankLinesBetweenScopes])
    }

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

    func testSortDeclarationsUsesEnglishLocaleByDefault() {
        let input = """
        // swiftformat:sort
        enum Words {
            case idea
            case hora
            case chata
        }
        """
        let output = """
        // swiftformat:sort
        enum Words {
            case chata
            case hora
            case idea
        }
        """
        testFormatting(for: input, output, rule: .sortDeclarations)
    }

    func testSortDeclarationsWithCzechLocale() {
        let input = """
        // swiftformat:sort
        enum Words {
            case chata
            case idea
            case hora
        }
        """
        let output = """
        // swiftformat:sort
        enum Words {
            case hora
            case chata
            case idea
        }
        """
        let options = FormatOptions(locale: .identifier("cs_CZ"))
        testFormatting(for: input, output, rule: .sortDeclarations, options: options)
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
                       exclude: [.blankLinesBetweenScopes, .propertyTypes])
    }

    func testSortBetweenDirectiveCommentsInType() {
        let input = """
        enum FeatureFlags {
            // swiftformat:sort:begin
            case upsellB
            case fooFeature
            case barFeature // Trailing comment -- bar feature
            /// Leading comment -- upsell A
            case upsellA // Trailing comment -- upsell A
            // swiftformat:sort:end

            var anUnsortedProperty: Foo {
                Foo()
            }
        }
        """

        let output = """
        enum FeatureFlags {
            // swiftformat:sort:begin
            case barFeature // Trailing comment -- bar feature
            case fooFeature
            /// Leading comment -- upsell A
            case upsellA // Trailing comment -- upsell A
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
        testFormatting(for: input, [output], rules: [.sortDeclarations, .blankLinesBetweenScopes], options: options, exclude: [.redundantPublic])
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
        testFormatting(for: input, rules: [.sortDeclarations, .blankLinesBetweenScopes], options: options, exclude: [.redundantPublic])
    }

    func testSortDeclarationsUsesCaseInsensitiveCompare() {
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

    func testSortEnumNamespaceSmallerThanOrganizeDeclarationsEnumThreshold() {
        let input = """
        // swiftformat:sort
        public enum Constants {
            public static let foo = "foo"
            public static let bar = "bar"
            public static let baaz = "baaz"
        }
        """

        let output = """
        // swiftformat:sort
        public enum Constants {
            public static let baaz = "baaz"
            public static let bar = "bar"
            public static let foo = "foo"
        }
        """

        let options = FormatOptions(organizeEnumThreshold: 20)
        testFormatting(for: input, [output], rules: [.sortDeclarations, .organizeDeclarations], options: options)
    }

    func testSortStructSmallerThanOrganizeDeclarationsEnumThreshold() {
        let input = """
        // swiftformat:sort
        public struct Foo {
            public let foo = "foo"
            public let bar = "bar"
            public let baaz = "baaz"
        }
        """

        let output = """
        // swiftformat:sort
        public struct Foo {
            public let baaz = "baaz"
            public let bar = "bar"
            public let foo = "foo"
        }
        """

        let options = FormatOptions(organizeStructThreshold: 20)
        testFormatting(for: input, [output], rules: [.sortDeclarations, .organizeDeclarations], options: options)
    }

    func testSortDeclarationsArrayMembers() {
        let input = """
        let x = [ // swiftformat:sort
            b,
            c,
            a,
        ]
        """

        let output = """
        let x = [ // swiftformat:sort
            a,
            b,
            c,
        ]
        """
        testFormatting(for: input, output, rule: .sortDeclarations)
    }

    func testSortDeclarationsArrayMembersWithoutTrailingComma() {
        let input = """
        let x = [ // swiftformat:sort
            b,
            c,
            a
        ]
        """

        let output = """
        let x = [ // swiftformat:sort
            a,
            b,
            c
        ]
        """
        testFormatting(for: input, output, rule: .sortDeclarations, exclude: [.trailingCommas])
    }

    func testSortCollectionLiteralWithoutTrailingCommaInSortBlock() {
        let input = """
        // swiftformat:sort:begin
        foo(
            bar: [
                "b",
                "c",
                "a"
            ]
        )
        // swiftformat:sort:end
        """

        let output = """
        // swiftformat:sort:begin
        foo(
            bar: [
                "a",
                "b",
                "c"
            ]
        )
        // swiftformat:sort:end
        """
        testFormatting(for: input, output, rule: .sortDeclarations, exclude: [.trailingCommas])
    }

    func testSortDeclarationsDictionaryMembers() {
        let input = """
        let x = [ // swiftformat:sort
            b: 2,
            c: 3,
            a: 1,
        ]
        """

        let output = """
        let x = [ // swiftformat:sort
            a: 1,
            b: 2,
            c: 3,
        ]
        """
        testFormatting(for: input, output, rule: .sortDeclarations)
    }

    func testSortDeclarationsDictionaryMembersSortsByKey() {
        // `_` sorts before `:`, so comparing whole elements would put `a_b: 2` before `a: 1`
        let input = """
        let x = [ // swiftformat:sort
            a_b: 2,
            a: 1,
        ]
        """

        let output = """
        let x = [ // swiftformat:sort
            a: 1,
            a_b: 2,
        ]
        """
        testFormatting(for: input, output, rule: .sortDeclarations)
    }

    func testSortDeclarationsDictionaryMembersWithColonInStringKey() {
        // Splitting at the first `:` would compare `"x` against `"x_y"` and put `"x:y"` first
        let input = """
        let x = [ // swiftformat:sort
            "x:y": 1,
            "x_y": 2,
        ]
        """

        let output = """
        let x = [ // swiftformat:sort
            "x_y": 2,
            "x:y": 1,
        ]
        """
        testFormatting(for: input, output, rule: .sortDeclarations)
    }

    func testSortDeclarationsArrayMembersWithCommentsBeforeElements() {
        let input = """
        let x = [ // swiftformat:sort
            // bee
            b,
            // sea
            c,
            // ay
            a,
        ]
        """

        let output = """
        let x = [ // swiftformat:sort
            // ay
            a,
            // bee
            b,
            // sea
            c,
        ]
        """
        testFormatting(for: input, output, rule: .sortDeclarations)
    }

    func testSortDeclarationsArrayMembersWithCommentsAfterElements() {
        let input = """
        let x = [ // swiftformat:sort
            b, // bee
            c, // sea
            a, // ay
        ]
        """

        let output = """
        let x = [ // swiftformat:sort
            a, // ay
            b, // bee
            c, // sea
        ]
        """
        testFormatting(for: input, output, rule: .sortDeclarations)
    }

    func testSortDeclarationsArrayMembersWithCommentBetweenSomeElements() {
        let input = """
        let x = [ // swiftformat:sort
            b,
            c,
            // ay
            a,
        ]
        """

        let output = """
        let x = [ // swiftformat:sort
            // ay
            a,
            b,
            c,
        ]
        """
        testFormatting(for: input, output, rule: .sortDeclarations)
    }

    func testSortDeclarationsArrayMembersWithCommentAfterLastElement() {
        let input = """
        let x = [ // swiftformat:sort
            b,
            c,
            a,
            // end of list
        ]
        """

        let output = """
        let x = [ // swiftformat:sort
            a,
            b,
            c,
            // end of list
        ]
        """
        testFormatting(for: input, output, rule: .sortDeclarations)
    }

    func testSortDeclarationsDictionaryMembersWithCommentsBeforeElements() {
        let input = """
        let x = [ // swiftformat:sort
            // bee
            b: 2,
            // sea
            c: 3,
            // ay
            a: 1,
        ]
        """

        let output = """
        let x = [ // swiftformat:sort
            // ay
            a: 1,
            // bee
            b: 2,
            // sea
            c: 3,
        ]
        """
        testFormatting(for: input, output, rule: .sortDeclarations)
    }

    func testSortDeclarationsDictionaryMembersWithCommentsAfterElements() {
        let input = """
        let x = [ // swiftformat:sort
            b: 2, // bee
            c: 3, // sea
            a: 1, // ay
        ]
        """

        let output = """
        let x = [ // swiftformat:sort
            a: 1, // ay
            b: 2, // bee
            c: 3, // sea
        ]
        """
        testFormatting(for: input, output, rule: .sortDeclarations)
    }

    func testSortDeclarationsDictionaryMembersWithCommentBetweenKeyAndValue() {
        let input = """
        let x = [ // swiftformat:sort
            b: /* bee */ 2,
            a: /* ay */ 1,
        ]
        """

        let output = """
        let x = [ // swiftformat:sort
            a: /* ay */ 1,
            b: /* bee */ 2,
        ]
        """
        testFormatting(for: input, output, rule: .sortDeclarations)
    }

    func testSortPackageDotSwift() {
        let input = """
        // swiftformat:sort:begin
        Package(
            name: "PackageName",
            products: [
                .library(
                    name: "PackageName",
                    targets: ["PackageName"]
                ),
            ],
            dependencies: [
                .package(path: "../OtherPackage"),
                .package(path: "../AnotherPackage"),
            ],
            targets: [
                .target(
                    name: "PackageName",
                    dependencies: [
                        "OtherPackage",
                        "AnotherPackage",
                    ]
                ),
                .target(
                    name: "AnotherPackage",
                    dependencies: [
                        "OtherPackage",
                        "AnotherPackage",
                    ]
                ),
            ]
        )
        // swiftformat:sort:end
        """

        let output = """
        // swiftformat:sort:begin
        Package(
            name: "PackageName",
            products: [
                .library(
                    name: "PackageName",
                    targets: ["PackageName"]
                ),
            ],
            dependencies: [
                .package(path: "../AnotherPackage"),
                .package(path: "../OtherPackage"),
            ],
            targets: [
                .target(
                    name: "AnotherPackage",
                    dependencies: [
                        "AnotherPackage",
                        "OtherPackage",
                    ]
                ),
                .target(
                    name: "PackageName",
                    dependencies: [
                        "AnotherPackage",
                        "OtherPackage",
                    ]
                ),
            ]
        )
        // swiftformat:sort:end
        """

        testFormatting(for: input, output, rule: .sortDeclarations)
    }
}
