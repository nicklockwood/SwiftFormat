//
//  DocCommentsBeforeAttributesTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/22/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class DocCommentsBeforeAttributesTests: XCTestCase {
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

        testFormatting(for: input, output, rule: .docCommentsBeforeAttributes)
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

        testFormatting(for: input, output, rule: .docCommentsBeforeAttributes)
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

        }
        """

        testFormatting(for: input, output, rule: .docCommentsBeforeAttributes, exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    func testPreservesCommentsBetweenAttributes() {
        let input = """
        @MainActor
        /// Doc comment between attributes
        @available(*, deprecated)
        /// Doc comment before declaration
        func bar() {}

        @MainActor /// Doc comment after main actor attribute
        @available(*, deprecated) /// Doc comment after deprecation attribute
        /// Doc comment before declaration
        func bar() {}
        """

        let output = """
        /// Doc comment before declaration
        @MainActor
        /// Doc comment between attributes
        @available(*, deprecated)
        func bar() {}

        /// Doc comment before declaration
        @MainActor /// Doc comment after main actor attribute
        @available(*, deprecated) /// Doc comment after deprecation attribute
        func bar() {}
        """

        testFormatting(for: input, output, rule: .docCommentsBeforeAttributes, exclude: [.docComments])
    }

    func testPreservesCommentOnSameLineAsAttribute() {
        let input = """
        @MainActor /// Doc comment trailing attributes
        func foo() {}
        """

        testFormatting(for: input, rule: .docCommentsBeforeAttributes, exclude: [.docComments])
    }

    func testPreservesRegularComments() {
        let input = """
        @MainActor
        // Comment after attribute
        func foo() {}
        """

        testFormatting(for: input, rule: .docCommentsBeforeAttributes, exclude: [.docComments])
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

        testFormatting(for: input, [output], rules: [.docComments, .docCommentsBeforeAttributes])
    }
}
