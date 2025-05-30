//
//  DocCommentsBeforeModifiersTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/22/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class DocCommentsBeforeModifiersTests: XCTestCase {
    func testDocCommentsBeforeAttributes() {
        let input = """
        @MainActor
        /// Doc comment on this type declaration
        public struct Baaz {
            @available(*, deprecated)
            /// Doc comment on this property declaration.
            /// This comment spans multiple lines.
            private var bar: Bar

            @FooBarMacro(arg1: true, arg2: .baaz)
            /**
             * Doc comment on this function declaration
             */
            func foo() {}
        }
        """

        let output = """
        /// Doc comment on this type declaration
        @MainActor
        public struct Baaz {
            /// Doc comment on this property declaration.
            /// This comment spans multiple lines.
            @available(*, deprecated)
            private var bar: Bar

            /**
             * Doc comment on this function declaration
             */
            @FooBarMacro(arg1: true, arg2: .baaz)
            func foo() {}
        }
        """

        testFormatting(for: input, output, rule: .docCommentsBeforeModifiers)
    }

    func testDocCommentsBeforeMultipleAttributes() {
        let input = """
        @MainActor @Macro(argument: true) @available(*, deprecated)
        /// Doc comment on this function declaration after several attributes
        public func foo() {}

        @MainActor
        @Macro(argument: true)
        @available(*, deprecated)
        /// Doc comment on this function declaration after several attributes
        public func bar() {}
        """

        let output = """
        /// Doc comment on this function declaration after several attributes
        @MainActor @Macro(argument: true) @available(*, deprecated)
        public func foo() {}

        /// Doc comment on this function declaration after several attributes
        @MainActor
        @Macro(argument: true)
        @available(*, deprecated)
        public func bar() {}
        """

        testFormatting(for: input, output, rule: .docCommentsBeforeModifiers)
    }

    func testDocCommentsBeforeAllModifiers() {
        let input = """
        @MainActor
        @Macro(argument: true)
        @available(*, deprecated)
        public
        /// Doc comment on this function declaration after several attributes
        func bar() {}
        """

        let output = """
        /// Doc comment on this function declaration after several attributes
        @MainActor
        @Macro(argument: true)
        @available(*, deprecated)
        public
        func bar() {}
        """

        testFormatting(for: input, output, rule: .docCommentsBeforeModifiers, exclude: [.modifiersOnSameLine])
    }

    func testUpdatesCommentsAfterMark() {
        let input = """
        import FooBarKit

        // MARK: - Foo

        @MainActor
        /// Doc comment on this type declaration.
        enum Foo {

            // MARK: Public

            @MainActor
            /// Doc comment on this function declaration.
            public func foo() {}

            // MARK: Private

            // TODO: This function also has a TODO comment.
            @MainActor
            /// Doc comment on this function declaration.
            private func bar() {}

            private
            /// Doc comment on this function declaration.
            // TODO: This function also has a trailing TODO comment.
            func baz() {}
        }
        """

        let output = """
        import FooBarKit

        // MARK: - Foo

        /// Doc comment on this type declaration.
        @MainActor
        enum Foo {

            // MARK: Public

            /// Doc comment on this function declaration.
            @MainActor
            public func foo() {}

            // MARK: Private

            // TODO: This function also has a TODO comment.
            /// Doc comment on this function declaration.
            @MainActor
            private func bar() {}

            /// Doc comment on this function declaration.
            private
            // TODO: This function also has a trailing TODO comment.
            func baz() {}
        }
        """

        testFormatting(for: input, output, rule: .docCommentsBeforeModifiers,
                       exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    func testPreservesCommentOnSameLineAsAttribute() {
        let input = """
        @MainActor // Comment trailing attributes
        func foo() {}
        """

        testFormatting(for: input, rule: .docCommentsBeforeModifiers)
    }

    func testHoistMultilineDocCommentOnSameLineAsAttribute() {
        let input = """
        @MainActor /**
         Comment trailing attributes
         */
        func foo() {}
        """

        let output = """
        /**
         Comment trailing attributes
         */
        @MainActor func foo() {}
        """

        testFormatting(for: input, output, rule: .docCommentsBeforeModifiers, exclude: [.docComments])
    }

    func testPreservesCommentsBetweenAttributes() {
        let input = """
        @MainActor
        // Comment between attributes
        @available(*, deprecated)
        /// Doc comment before declaration
        func bar() {}

        @MainActor // Comment after main actor attribute
        @available(*, deprecated) // Comment after deprecation attribute
        /// Doc comment before declaration
        func bar() {}
        """

        let output = """
        /// Doc comment before declaration
        @MainActor
        // Comment between attributes
        @available(*, deprecated)
        func bar() {}

        /// Doc comment before declaration
        @MainActor // Comment after main actor attribute
        @available(*, deprecated) // Comment after deprecation attribute
        func bar() {}
        """

        testFormatting(for: input, output, rule: .docCommentsBeforeModifiers, exclude: [.docComments])
    }

    func testHoisDocCommentOnSameLineAsAttribute() {
        let input = """
        @MainActor /// Doc comment trailing attributes
        func foo() {}
        """

        let output = """
        /// Doc comment trailing attributes
        @MainActor func foo() {}
        """

        testFormatting(for: input, output, rule: .docCommentsBeforeModifiers, exclude: [.docComments])
    }

    func testPreservesRegularComments() {
        let input = """
        @MainActor
        // Comment after attribute
        func foo() {}
        """

        testFormatting(for: input, rule: .docCommentsBeforeModifiers, exclude: [.docComments])
    }

    func testCombinesWithDocCommentsRule() {
        let input = """
        @MainActor
        // Comment after attribute
        func foo() {}
        """

        let output = """
        /// Comment after attribute
        @MainActor
        func foo() {}
        """

        testFormatting(for: input, [output], rules: [.docComments, .docCommentsBeforeModifiers])
    }

    func testCaseCommentsNotMangled() {
        let input = """
        enum Symbol: CustomStringConvertible, Hashable {
            /// A named variable
            case variable(String)

            /// An infix operator
            case infix(String)

            /// A prefix operator
            case prefix(String)

            /// A postfix operator
            case postfix

            /// Required
            case required

            /// Optional
            case optional

            /// Open
            case open

            /// Other
            case other
        }
        """

        testFormatting(for: input, rule: .docCommentsBeforeModifiers)
    }

    func testDynamicFunctionName() {
        let input = """
        enum Colors {
            /// Tint color
            static let tintColor = UIColor.dynamic(light: .fullBlack, dark: .white)
            /// Text color
            static let textColor = UIColor.dynamic(light: .fullBlack, dark: .white)
            /// Line color
            static let lineColor: UIColor = .dynamic(light: .fullBlack, dark: .white)
        }
        """

        testFormatting(for: input, rule: .docCommentsBeforeModifiers, exclude: [.propertyTypes])
    }
}
