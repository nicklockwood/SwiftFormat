//
//  WrapEnumCasesTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 8/28/20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class WrapEnumCasesTests: XCTestCase {
    func testMultilineEnumCases() {
        let input = """
        enum Enum1: Int {
            case a = 0, p = 2, c, d
            case e, k
            case m(String, String)
        }
        """
        let output = """
        enum Enum1: Int {
            case a = 0
            case p = 2
            case c
            case d
            case e
            case k
            case m(String, String)
        }
        """
        testFormatting(for: input, output, rule: .wrapEnumCases)
    }

    func testMultilineEnumCasesWithNestedEnumsDoesNothing() {
        let input = """
        public enum SearchTerm: Decodable, Equatable {
            case term(name: String)
            case category(category: Category)

            enum CodingKeys: String, CodingKey {
                case name
                case type
                case categoryID = "category_id"
                case attributes
            }
        }
        """
        testFormatting(for: input, rule: .wrapEnumCases)
    }

    func testEnumCaseSplitOverMultipleLines() {
        let input = """
        enum Foo {
            case bar(
                x: String,
                y: Int
            ), baz
        }
        """
        let output = """
        enum Foo {
            case bar(
                x: String,
                y: Int
            )
            case baz
        }
        """
        testFormatting(for: input, output, rule: .wrapEnumCases)
    }

    func testEnumCasesAlreadyWrappedOntoMultipleLines() {
        let input = """
        enum Foo {
            case bar,
                 baz,
                 quux
        }
        """
        let output = """
        enum Foo {
            case bar
            case baz
            case quux
        }
        """
        testFormatting(for: input, output, rule: .wrapEnumCases)
    }

    func testEnumCasesIfValuesWithoutValuesDoesNothing() {
        let input = """
        enum Foo {
            case bar, baz, quux
        }
        """
        testFormatting(for: input, rule: .wrapEnumCases,
                       options: FormatOptions(wrapEnumCases: .withValues))
    }

    func testEnumCasesIfValuesWithRawValuesAndNestedEnum() {
        let input = """
        enum Foo {
            case bar = 1, baz, quux

            enum Foo2 {
                case bar, baz, quux
            }
        }
        """
        let output = """
        enum Foo {
            case bar = 1
            case baz
            case quux

            enum Foo2 {
                case bar, baz, quux
            }
        }
        """
        testFormatting(
            for: input,
            output,
            rule: .wrapEnumCases,
            options: FormatOptions(wrapEnumCases: .withValues)
        )
    }

    func testEnumCasesIfValuesWithAssociatedValues() {
        let input = """
        enum Foo {
            case bar(a: Int), baz, quux
        }
        """
        let output = """
        enum Foo {
            case bar(a: Int)
            case baz
            case quux
        }
        """
        testFormatting(
            for: input,
            output,
            rule: .wrapEnumCases,
            options: FormatOptions(wrapEnumCases: .withValues)
        )
    }

    func testEnumCasesWithCommentsAlreadyWrappedOntoMultipleLines() {
        let input = """
        enum Foo {
            case bar, // bar
                 baz, // baz
                 quux // quux
        }
        """
        let output = """
        enum Foo {
            case bar // bar
            case baz // baz
            case quux // quux
        }
        """
        testFormatting(for: input, output, rule: .wrapEnumCases)
    }

    func testNoWrapEnumStatementAllOnOneLine() {
        let input = "enum Foo { bar, baz }"
        testFormatting(for: input, rule: .wrapEnumCases)
    }

    func testNoConfuseIfCaseWithEnum() {
        let input = """
        enum Foo {
            case foo
            case bar(value: [Int])
        }

        func baz() {
            if case .foo = foo,
               case .bar(let value) = bar,
               value.isEmpty
            {
                print("")
            }
        }
        """
        testFormatting(for: input, rule: .wrapEnumCases,
                       exclude: [.hoistPatternLet])
    }

    func testNoMangleUnindentedEnumCases() {
        let input = """
        enum Foo {
        case foo, bar
        }
        """
        let output = """
        enum Foo {
        case foo
        case bar
        }
        """
        testFormatting(for: input, output, rule: .wrapEnumCases, exclude: [.indent])
    }

    func testNoMangleEnumCaseOnOpeningLine() {
        let input = """
        enum SortOrder { case
            asc(String), desc(String)
        }
        """
        // TODO: improve formatting here
        let output = """
        enum SortOrder { case
            asc(String)
        case desc(String)
        }
        """
        testFormatting(for: input, output, rule: .wrapEnumCases, exclude: [.indent])
    }

    func testNoWrapSingleLineEnumCases() {
        let input = "enum Foo { case foo, bar }"
        testFormatting(for: input, rule: .wrapEnumCases)
    }

    func testNoMangleSequentialEnums() {
        let input = """
        // enums

        @objc public enum TestType: Int {
            case value1 = 0, value2 = 1
        }

        public struct TestStruct: Equatable, Comparable {
            public enum TestEnum {
                case value1, value2, value3
            }

            public enum TestEnumAnother {
                case value4, value5, value6
            }
        }
        """
        let output = """
        // enums

        @objc public enum TestType: Int {
            case value1 = 0
            case value2 = 1
        }

        public struct TestStruct: Equatable, Comparable {
            public enum TestEnum {
                case value1
                case value2
                case value3
            }

            public enum TestEnumAnother {
                case value4
                case value5
                case value6
            }
        }
        """

        testFormatting(for: input, output, rule: .wrapEnumCases)
    }
}
