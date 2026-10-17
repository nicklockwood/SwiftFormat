//
//  WrapEnumCasesTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 8/28/20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class WrapEnumCasesTests: XCTestCase {
    func testPreserveEnumCasesInSingleLineStringInterpolation() {
        let input = #"""
        let text = "\({ enum Foo { case first, second }; return Foo.first }())"
        """#
        testFormatting(for: input, rule: .wrapEnumCases,
                       options: FormatOptions(wrapSingleLineEnumCases: true))
    }

    func testPreserveEnumCasesInMultilineStringInterpolationWhenWrappingDisabled() {
        let input = #"""
        let text = """
        \({ enum Foo { case first, second }; return Foo.first }())
        """
        """#
        testFormatting(for: input, rule: .wrapEnumCases,
                       options: FormatOptions(wrapSingleLineEnumCases: true))
    }

    func testSemicolonSeparatedSingleEnumCaseAfterMultipleCases() {
        let input = """
        enum Foo { case first, second; case third }
        """
        let output = """
        enum Foo {
            case first
            case second;
            case third
        }
        """
        let allRulesOutput = """
        enum Foo {
            case first
            case second
            case third
        }
        """
        testFormatting(for: input, [output, allRulesOutput], rules: [.wrapEnumCases],
                       options: FormatOptions(wrapSingleLineEnumCases: true))
    }

    func testPreserveAttributedEnumCases() {
        let input = """
        enum Inline { @available(*, deprecated) case first, second }

        enum Multiline {
            @available(*, unavailable)
            case first, second
        }
        """
        testFormatting(for: input, rule: .wrapEnumCases,
                       options: FormatOptions(wrapSingleLineEnumCases: true))
    }

    func testPreserveIndirectEnumCases() {
        let input = """
        enum Tree { indirect case left(Tree), right(Tree) }
        """
        testFormatting(for: input, rule: .wrapEnumCases,
                       options: FormatOptions(wrapSingleLineEnumCases: true))
    }

    func testEnableSingleLineEnumCasesWithNextDirective() {
        let input = """
        // swiftformat:options:next --wrap-single-line-enum-cases true
        enum Foo { case first, second }

        enum Bar { case third, fourth }
        """
        let output = """
        // swiftformat:options:next --wrap-single-line-enum-cases true
        enum Foo {
            case first
            case second
        }

        enum Bar { case third, fourth }
        """
        testFormatting(for: input, output, rule: .wrapEnumCases)
    }

    func testSingleLineEnumCasesWithAlternatingDirectives() {
        let input = """
        // swiftformat:options --wrap-single-line-enum-cases true
        enum Foo { case first, second }

        // swiftformat:options --wrap-single-line-enum-cases false
        enum Bar { case third, fourth }

        // swiftformat:options --wrap-single-line-enum-cases true --wrap-enum-cases with-values
        enum Baz { case fifth, sixth }

        enum Value { case seventh(Int), eighth }
        """
        let output = """
        // swiftformat:options --wrap-single-line-enum-cases true
        enum Foo {
            case first
            case second
        }

        // swiftformat:options --wrap-single-line-enum-cases false
        enum Bar { case third, fourth }

        // swiftformat:options --wrap-single-line-enum-cases true --wrap-enum-cases with-values
        enum Baz { case fifth, sixth }

        enum Value {
            case seventh(Int)
            case eighth
        }
        """
        testFormatting(for: input, output, rule: .wrapEnumCases)
    }

    func testSingleLineEnumCasesWithSemicolons() {
        let input = """
        enum Foo { case first, second; case third, fourth }
        """
        let output = """
        enum Foo {
            case first
            case second;
            case third
            case fourth
        }
        """
        let allRulesOutput = """
        enum Foo {
            case first
            case second
            case third
            case fourth
        }
        """
        testFormatting(for: input, [output, allRulesOutput], rules: [.wrapEnumCases],
                       options: FormatOptions(wrapSingleLineEnumCases: true))
    }

    func testSingleLineEnumCasesWithCRLFLinebreaks() {
        let input = """
        enum Foo { case first, second }
        """
        let output = """
        enum Foo {
            case first
            case second
        }
        """
        testFormatting(for: input, output.replacingOccurrences(of: "\n", with: "\r\n"), rule: .wrapEnumCases,
                       options: FormatOptions(linebreak: "\r\n", wrapSingleLineEnumCases: true))
    }

    func testSingleLineEnumCasesWithContextualKeywordNames() {
        let input = """
        enum Foo { case isolated, nonisolated, package }
        """
        let output = """
        enum Foo {
            case isolated
            case nonisolated
            case package
        }
        """
        testFormatting(for: input, output, rule: .wrapEnumCases,
                       options: FormatOptions(wrapSingleLineEnumCases: true))
    }

    func testPreserveSwitchCasesInsideEnum() {
        let input = """
        enum Foo {
            case first
            case second

            func check() {
                switch self {
                case .first,
                     .second:
                    break
                }
            }
        }
        """
        testFormatting(for: input, rule: .wrapEnumCases,
                       options: FormatOptions(wrapSingleLineEnumCases: true))
    }

    func testSingleLineEnumCasesWithTabIndentation() {
        let input = """
        enum Foo { case first, second }
        """
        let output = """
        enum Foo {
        \tcase first
        \tcase second
        }
        """
        testFormatting(for: input, output, rule: .wrapEnumCases,
                       options: FormatOptions(indent: "\t", wrapSingleLineEnumCases: true))
    }

    func testEnumCasesWithConditionalCompilation() {
        let input = """
        enum Foo {
            #if DEBUG
                case first, second
            #else
                case third, fourth
            #endif
        }
        """
        let output = """
        enum Foo {
            #if DEBUG
                case first
                case second
            #else
                case third
                case fourth
            #endif
        }
        """
        testFormatting(for: input, output, rule: .wrapEnumCases,
                       options: FormatOptions(wrapSingleLineEnumCases: true))
    }

    func testWrapSingleLinePackageEnumCases() {
        let input = """
        package enum Action { case delete, suspend, resume }
        """
        let output = """
        package enum Action {
            case delete
            case suspend
            case resume
        }
        """
        testFormatting(for: input, output, rule: .wrapEnumCases,
                       options: FormatOptions(wrapSingleLineEnumCases: true))
    }

    func testWrapSingleLineEnumCasesWithValues() {
        let input = """
        enum Raw: Int { case first = 1, second = 2 }

        enum Associated { case first(Int, String), second(value: (Int, Int)) }

        enum Plain { case first, second }
        """
        let output = """
        enum Raw: Int {
            case first = 1
            case second = 2
        }

        enum Associated {
            case first(Int, String)
            case second(value: (Int, Int))
        }

        enum Plain { case first, second }
        """
        testFormatting(for: input, output, rule: .wrapEnumCases,
                       options: FormatOptions(wrapEnumCases: .withValues, wrapSingleLineEnumCases: true))
    }

    func testWrapNestedSingleLineEnumCasesWithCustomIndent() {
        let input = """
        enum Outer {
          enum Inner { case first, second }
        }
        """
        let output = """
        enum Outer {
          enum Inner {
            case first
            case second
          }
        }
        """
        testFormatting(for: input, output, rule: .wrapEnumCases,
                       options: FormatOptions(indent: "  ", wrapSingleLineEnumCases: true))
    }

    func testWrapSingleLineEnumCasesWithComments() {
        let input = """
        enum Foo { /* cases */ case first, /* second */ second } // enum
        """
        let output = """
        enum Foo { /* cases */
            case first
            case /* second */ second
        } // enum
        """
        testFormatting(for: input, output, rule: .wrapEnumCases,
                       options: FormatOptions(wrapSingleLineEnumCases: true))
    }

    func testWrapSingleLineEnumCasesPreservesSingleCase() {
        let input = """
        enum Foo { case first(Int, String) }
        """
        testFormatting(for: input, rule: .wrapEnumCases,
                       options: FormatOptions(wrapSingleLineEnumCases: true))
    }

    func testWrapEnumCasesOnOpeningLineWithLineComments() {
        let input = """
        enum Foo { case first, // first
            second, // second
            third }
        """
        let output = """
        enum Foo {
            case first // first
            case second // second
            case third
        }
        """
        testFormatting(for: input, output, rule: .wrapEnumCases,
                       options: FormatOptions(wrapSingleLineEnumCases: true))
    }

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

    func testMultilineEnumCasesAfterRawValues() {
        let input = """
        enum Foo: String {
            case bar = "BAR", baz = #"BAZ"#
            case quux = "QUUX", corge = "CORGE"
            case grault, garply
        }

        enum Bar: Int {
            case a = 0, b = 1
            case c = 2, d = 3
        }
        """
        let output = """
        enum Foo: String {
            case bar = "BAR"
            case baz = #"BAZ"#
            case quux = "QUUX"
            case corge = "CORGE"
            case grault
            case garply
        }

        enum Bar: Int {
            case a = 0
            case b = 1
            case c = 2
            case d = 3
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
        let input = """
        enum Foo { bar, baz }
        """
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
        let input = """
        enum Foo { case foo, bar }
        """
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

    func testPackageEnumWithProtocolConformances() {
        let input = """
        enum Outer {
            case outerCase, otherOuterCase

            package enum Inner: String, CaseIterable, Codable {
                case innerCase
            }
        }
        """
        let output = """
        enum Outer {
            case outerCase
            case otherOuterCase

            package enum Inner: String, CaseIterable, Codable {
                case innerCase
            }
        }
        """
        testFormatting(for: input, output, rule: .wrapEnumCases)
    }
}
