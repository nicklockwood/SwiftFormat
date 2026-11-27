//
//  ReflowCommentsTests.swift
//  SwiftFormatTests
//
//  Created by Rui Nelson on 11/27/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class ReflowCommentsTests: XCTestCase {
    func testReflowLineComment() {
        let input = """
        func foo() {
            // this
            // is
            // a comment
            bar()
        }
        """
        let output = """
        func foo() {
            // this is a comment
            bar()
        }
        """
        testFormatting(for: input, output, rule: .reflowComments)
    }

    func testReflowLineCommentParagraphs() {
        let input = """
        func foo() {
            // first
            // paragraph
            //
            //
            // second
            // paragraph
            bar()
        }
        """
        let output = """
        func foo() {
            // first paragraph
            //
            // second paragraph
            bar()
        }
        """
        testFormatting(for: input, output, rule: .reflowComments)
    }

    func testReflowDocComment() {
        let input = """
        /// Adds two
        /// numbers.
        ///
        /// - Parameter lhs: The first
        ///   number.
        /// - Parameter rhs: The second number.
        func add(lhs: Int, rhs: Int) -> Int {
            lhs + rhs
        }
        """
        let output = """
        /// Adds two numbers.
        ///
        /// - Parameter lhs: The first number.
        /// - Parameter rhs: The second number.
        func add(lhs: Int, rhs: Int) -> Int {
            lhs + rhs
        }
        """
        testFormatting(for: input, output, rule: .reflowComments)
    }

    func testDocCommentsAndLineCommentsAreReflowedSeparately() {
        let input = """
        struct Foo {
            // comment
            // second line
            /// doc
            /// comment
            var bar: Int
        }
        """
        let output = """
        struct Foo {
            // comment second line
            /// doc comment
            var bar: Int
        }
        """
        testFormatting(for: input, output, rule: .reflowComments, exclude: [.docComments])
    }

    func testListsTablesQuotesAndHeadingsKeepTheirLines() {
        let input = """
        /// # Heading
        /// Intro
        /// text.
        /// 1. one
        /// 2. two
        /// * three
        /// + four
        /// > quote
        /// | A | B |
        /// | --- | --- |
        /// | 1 | 2 |
        /// outro
        /// ---
        /// `code`
        /// end
        func foo() {}
        """
        let output = """
        /// # Heading
        /// Intro text.
        /// 1. one
        /// 2. two
        /// * three
        /// + four
        /// > quote
        /// | A | B |
        /// | --- | --- |
        /// | 1 | 2 |
        /// outro
        /// ---
        /// `code`
        /// end
        func foo() {}
        """
        testFormatting(for: input, output, rule: .reflowComments)
    }

    func testFencedCodeBlockInDocCommentIsKeptAsWritten() {
        let input = """
        public extension String {
            /// Converts a Windows-style path into the SFTP path form.
            ///
            /// ## Usage
            /// ```swift
            /// let remote = #"C:\\Users\\alice"#.sftpPathFromWindows
            /// // "/C:/Users/alice"
            ///
            /// try await client.upload(from: localURL, to: remote)
            /// ```
            ///
            /// - Note: Call this explicitly.
            var sftpPathFromWindows: String {
                self
            }
        }
        """
        testFormatting(for: input, rule: .reflowComments)
    }

    func testProseAroundFencedCodeBlockIsReflowed() {
        let input = """
        /// one
        /// two
        /// ~~~
        /// let a = 1
        /// let b = 2
        /// ~~~
        /// three
        /// four
        func foo() {}
        """
        let output = """
        /// one two
        /// ~~~
        /// let a = 1
        /// let b = 2
        /// ~~~
        /// three four
        func foo() {}
        """
        testFormatting(for: input, output, rule: .reflowComments)
    }

    func testReflowTrailingCommentLinedUpUnderIt() {
        let input = """
        let foo = 5 // with
                    // a
                    // comment
        """
        let output = """
        let foo = 5 // with a comment
        """
        testFormatting(for: input, output, rule: .reflowComments, exclude: [.indent])
    }

    func testCommentAfterCodeDoesNotJoinCommentNotLinedUpUnderIt() {
        let input = """
        func foo() {
            let bar = 5 // trailing
            // standalone
            print(bar)
        }
        """
        testFormatting(for: input, rule: .reflowComments)
    }

    func testCommentDirectivesStandAlone() {
        let input = """
        func foo() {
            // first
            // line
            // swiftlint:disable:next force_cast
            // TODO: fix
            // this
            bar()
        }
        """
        let output = """
        func foo() {
            // first line
            // swiftlint:disable:next force_cast
            // TODO: fix
            // this
            bar()
        }
        """
        testFormatting(for: input, output, rule: .reflowComments)
    }

    func testFileHeaderIsNotReflowed() {
        let input = """
        // Foo.swift
        // MyModule

        let foo = 5
        """
        testFormatting(for: input, rule: .reflowComments)
    }

    func testCommentsInsideStringsAreNotReflowed() {
        let input = """
        let foo = \"""
        // this
        // is data
        \"""
        """
        testFormatting(for: input, rule: .reflowComments)
    }

    func testReflowBlockComment() {
        let input = """
        let foo = 5

        /* this
         is a
         block comment
         */
        """
        let output = """
        let foo = 5

        /* this is a block comment
         */
        """
        testFormatting(for: input, output, rule: .reflowComments)
    }

    func testReflowIndentedBlockComment() {
        let input = """
        func foo() {
            /*
             block
             comment

             - item
             */
            bar()
        }
        """
        let output = """
        func foo() {
            /*
             block comment
             - item
             */
            bar()
        }
        """
        testFormatting(for: input, output, rule: .reflowComments)
    }

    func testReflowDocBlockCommentWithStarMargin() {
        let input = """
        /**
         * Returns the
         * number of items.
         */
        func count() -> Int {
            0
        }
        """
        let output = """
        /**
         * Returns the number of items.
         */
        func count() -> Int {
            0
        }
        """
        testFormatting(for: input, output, rule: .reflowComments)
    }

    func testBlockCommentClosingAfterText() {
        let input = """
        let foo = 5 /* one
                       two */
        """
        let output = """
        let foo = 5 /* one two */
        """
        testFormatting(for: input, output, rule: .reflowComments)
    }

    func testBannerBlockCommentIsNotReflowed() {
        let input = """
        let foo = 5

        /*****************
         * one
         * two
         *****************/
        """
        testFormatting(for: input, rule: .reflowComments)
    }

    func testOnlyReflowChosenCommentKinds() {
        let input = """
        func foo() {
            // line
            // comment
            /* block
             comment */
            bar()
        }

        /// doc
        /// comment
        func bar() {}
        """
        let output = """
        func foo() {
            // line
            // comment
            /* block
             comment */
            bar()
        }

        /// doc comment
        func bar() {}
        """
        let options = FormatOptions(reflowComments: ["doc"])
        testFormatting(for: input, output, rule: .reflowComments, options: options)
    }

    func testReflowThenWrapToMaxWidth() {
        let input = """
        func foo() {
            // aaa bbb
            // ccc ddd eee
            bar()
        }
        """
        let output = """
        func foo() {
            // aaa bbb ccc
            // ddd eee
            bar()
        }
        """
        let options = FormatOptions(maxWidth: 20)
        testFormatting(for: input, [output], rules: [.reflowComments, .wrapSingleLineComments], options: options)
    }

    func testPartialLineRangeDoesNotReflowPastIt() throws {
        let lineComments = """
        func foo() {
            // aaa
            // bbb
            // ccc
            bar()
        }
        """
        XCTAssertEqual(try format(lineComments, rules: [.reflowComments], lineRange: 1 ... 2).output, lineComments)
        XCTAssertEqual(try format(lineComments, rules: [.reflowComments], lineRange: 2 ... 3).output, """
        func foo() {
            // aaa bbb
            // ccc
            bar()
        }
        """)
        let blockComment = """
        func foo() {
            /*
             aaa
             bbb
             ccc
             */
            bar()
        }
        """
        XCTAssertEqual(try format(blockComment, rules: [.reflowComments], lineRange: 2 ... 4).output, blockComment)
    }

    func testCommentsChangingEnabledRulesEndARun() {
        let input = """
        func foo() {
            // aaa
            // bbb /* swiftformat:disable reflowComments */
            // ccc
            // ddd
            bar()
        }
        """
        testFormatting(for: input, rule: .reflowComments)
    }

    func testDocCommentLineMentioningDirectiveStandsAlone() {
        let input = """
        /// A doc comment. // swiftformat:disable:next reflowComments
        /// Lines kept
        /// as written.
        func foo() {}
        """
        testFormatting(for: input, rule: .reflowComments)
    }

    func testFileHeaderWithDirectiveLikeLineIsNotReflowed() {
        let input = """
        // Copyright 2024 Foo Inc.
        // SPDX-License-Identifier: Apache-2.0

        let foo = 5
        """
        testFormatting(for: input, rule: .reflowComments)
    }

    func testXcodeFileHeaderWithAuthorIsNotReflowed() {
        let input = """
        //
        //  Foo.swift
        //  Project
        //
        //  Author: Jane Doe
        //

        import Foundation
        """
        testFormatting(for: input, rule: .reflowComments)
    }

    func testLineCommentsStartingTheFileAreNotReflowed() {
        let input = """
        // MIT License
        // Permission is hereby granted
        import Foundation
        """
        testFormatting(for: input, rule: .reflowComments)
    }

    func testBlockCommentOpenerWithOnlyLineSeparatorDoesNotCrash() throws {
        let input = """
        let foo = 5
        /*\u{2028}
        */
        """
        let output = """
        let foo = 5
        /*
        */
        """
        XCTAssertEqual(try format(input, rules: [.reflowComments]).output, output)
    }

    func testTextStartingWithSlashTerminatesWithWrap() {
        let input = """
        let foo = 5
        // /usr/local/bin is where the tool is installed
        // unless a different prefix was chosen.
        """
        let output = """
        let foo = 5
        // /usr/local/bin is where the tool is
        // /installed unless a different prefix
        // /was chosen.
        """
        let options = FormatOptions(maxWidth: 40)
        testFormatting(for: input, [output], rules: [.reflowComments, .wrapSingleLineComments], options: options)
    }

    func testIndentedTextStartingWithSlashTerminatesWithWrap() {
        let input = """
        let foo = 5
        //   /usr/local/bin is where the tool is installed
        """
        let output = """
        let foo = 5
        //   /usr/local/bin is where the tool is
        //   /installed
        """
        let options = FormatOptions(maxWidth: 40)
        testFormatting(for: input, [output], rules: [.reflowComments, .wrapSingleLineComments], options: options)
    }

    func testBlankLinesAroundDirectiveLikeParagraphAreKept() {
        let input = """
        func foo() {
            // Explanation of the
            // workaround.
            //
            // TODO: Remove this
            //
            // The old API is
            // still needed.
            bar()
        }
        """
        let output = """
        func foo() {
            // Explanation of the workaround.
            //
            // TODO: Remove this
            //
            // The old API is still needed.
            bar()
        }
        """
        testFormatting(for: input, output, rule: .reflowComments)
    }

    func testPartialLineRangeEndingAtBlankLineKeepsIt() throws {
        let input = """
        /// aaa
        ///
        /// bbb
        /// ccc
        func foo() {}
        """
        XCTAssertEqual(try format(input, rules: [.reflowComments], lineRange: 1 ... 2).output, input)
    }

    func testIndentedDirectiveLikeParagraphIsKeptAsWritten() {
        let input = """
        func foo() {
            //   Returns: the value that is computed from the inputs
            //   and then cached for later use by the caller.
            bar()
        }
        """
        let options = FormatOptions(maxWidth: 60)
        testFormatting(for: input, rules: [.reflowComments, .wrapSingleLineComments], options: options)
    }

    func testReflowAndWrapLeaveWrappedParagraphsUnchanged() {
        let input = """
        /// Summary line that is long enough to need wrapping at the
        /// configured width of sixty columns.
        ///
        /// Discussion paragraph.
        func foo() {}
        """
        let options = FormatOptions(maxWidth: 60)
        testFormatting(for: input, rules: [.reflowComments, .wrapSingleLineComments], options: options)
    }

    func testDirectiveLikeParagraphIsKeptAsWritten() {
        let input = """
        func foo() {
            // TODO: Refactor this function to use the new
            // API once it is available in all supported versions.
            //
            // Workaround: call the old
            // API for now.
            bar()
        }
        """
        let options = FormatOptions(maxWidth: 60)
        testFormatting(for: input, rules: [.reflowComments, .wrapSingleLineComments], options: options)
    }

    func testMisspelledMarkIsFixedBeforeReflowing() {
        let input = """
        struct Foo {
            // Helpers below
            // MARK - Helpers

            func bar() {}
        }
        """
        let output = """
        struct Foo {
            // Helpers below
            // MARK: - Helpers

            func bar() {}
        }
        """
        testFormatting(for: input, [output], rules: [.reflowComments, .todos])
    }

    func testOptionsCommentChangesCommentKinds() {
        let input = """
        // swiftformat:options --reflow-comments doc
        func foo() {
            // eee
            // fff
            bar()
        }
        """
        testFormatting(for: input, rule: .reflowComments)
    }

    func testTrailingCommentIsNotJoinedPastMaxWidth() {
        let input = """
        print(alpha, beta, gamma) // a trailing comment that
                                  // continues here
        """
        let options = FormatOptions(maxWidth: 60)
        testFormatting(for: input, rules: [.reflowComments, .wrap], options: options, exclude: [.indent])
    }

    func testTrailingBlockCommentIsNotJoinedPastMaxWidth() {
        let input = """
        print(alpha, beta, gamma) /* a trailing comment that
                                     continues here */
        """
        let options = FormatOptions(maxWidth: 60)
        testFormatting(for: input, rules: [.reflowComments, .wrap], options: options, exclude: [.indent])
    }
}
