// Created by Cal Stephens on 9/25/24.
// Copyright © 2024 Airbnb Inc. All rights reserved.

import XCTest
@testable import SwiftFormat

final class RedundantEquatableTests: XCTestCase {
    func testRemoveSimpleEquatableConformanceOnType() {
        let input = """
        struct Foo: Equatable {
            let bar: Bar
            let baaz: Baaz

            static func ==(_ lhs: Foo, _ rhs: Foo) -> Bool {
                lhs.bar == rhs.bar
                    && lhs.baaz == rhs.baaz
            }
        }

        struct Baaz: Hashable {
            let foo: Foo

            static func ==(_ lhs: Baaz, _ rhs: Baaz) -> Bool {
                return lhs.foo == rhs.foo
            }
        }
        """

        let output = """
        struct Foo: Equatable {
            let bar: Bar
            let baaz: Baaz
        }

        struct Baaz: Hashable {
            let foo: Foo
        }
        """

        testFormatting(for: input, [output], rules: [.redundantEquatable, .blankLinesAtEndOfScope])
    }

    func testRemoveSimpleEquatableConformanceInExtensionType() {
        let input = """
        struct Foo {
            static let shared: Foo = .init()

            let bar: Bar

            var baaz: Baaz {
                didSet {
                    print("Updated baaz")
                }
            }

            var quux: Quux {
                Quux(baaz)
            }
        }

        extension Foo: Equatable {
            static func ==(_ lhs: Foo, _ rhs: Foo) -> Bool {
                lhs.bar == rhs.bar && lhs.baaz == rhs.baaz 
            }
        }
        """

        let output = """
        struct Foo {
            static let shared: Foo = .init()

            let bar: Bar

            var baaz: Baaz {
                didSet {
                    print("Updated baaz")
                }
            }

            var quux: Quux {
                Quux(baaz)
            }
        }

        extension Foo: Equatable {}
        """

        testFormatting(for: input, [output], rules: [.redundantEquatable, .emptyBraces])
    }

    func testRemoveSimpleEquatableConformanceUsingSelfInExtensionType() {
        let input = """
        struct Foo {
            let bar: Bar
            let baaz: Baaz
        }

        extension Foo: Equatable {
            static func ==(_ lhs: Self, _ rhs: Self) -> Bool {
                lhs.bar == rhs.bar
                    && lhs.baaz == rhs.baaz
            }
        }
        """

        let output = """
        struct Foo {
            let bar: Bar
            let baaz: Baaz
        }

        extension Foo: Equatable {}
        """

        testFormatting(for: input, [output], rules: [.redundantEquatable, .emptyBraces])
    }

    func testPreservesEquatableImplementationNotComparingAllProperties() {
        let input = """
        struct Foo: Equatable {
            let bar: Bar
            let baaz: Baaz

            static func == (_ lhs: Foo, _ rhs: Foo) -> Equatable {
                lhs.bar == rhs.bar
            }
        }

        struct Baaz: Equatable {
            let foo: Foo

            static func == (_ lhs: Foo, _ rhs: Baaz) -> Equatable {
                lhs.foo.bar == rhs.foo.bar
            }
        }
        """

        testFormatting(for: input, rule: .redundantEquatable)
    }

    func testPreservesEquatableImplementationInClass() {
        let input = """
        class Foo: Equatable {
            let bar: Bar
            let baaz: Baaz

            static func == (_ lhs: Foo, _ rhs: Foo) -> Equatable {
                lhs.bar == rhs.bar && lhs.baaz == rhs.baaz
            }
        }
        """

        testFormatting(for: input, rule: .redundantEquatable)
    }
}
