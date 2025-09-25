//
//  BlockCommentsTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 11/6/21.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class BlockCommentsTests: XCTestCase {
    func testBlockCommentsOneLine() {
        let input = """
        foo = bar /* comment */
        """
        let output = """
        foo = bar // comment
        """
        testFormatting(for: input, output, rule: .blockComments)
    }

    func testDocBlockCommentsOneLine() {
        let input = """
        foo = bar /** doc comment */
        """
        let output = """
        foo = bar /// doc comment
        """
        testFormatting(for: input, output, rule: .blockComments)
    }

    func testPreservesBlockCommentInSingleLineScope() {
        let input = """
        if foo { /* code */ }
        """
        testFormatting(for: input, rule: .blockComments)
    }

    func testBlockCommentsMultiLine() {
        let input = """
        /*
         * foo
         * bar
         */
        """
        let output = """
        // foo
        // bar
        """
        testFormatting(for: input, output, rule: .blockComments)
    }

    func testBlockCommentsWithoutBlankFirstLine() {
        let input = """
        /* foo
         * bar
         */
        """
        let output = """
        // foo
        // bar
        """
        testFormatting(for: input, output, rule: .blockComments)
    }

    func testBlockCommentsWithBlankLine() {
        let input = """
        /*
         * foo
         *
         * bar
         */
        """
        let output = """
        // foo
        //
        // bar
        """
        testFormatting(for: input, output, rule: .blockComments)
    }

    func testBlockDocCommentsWithAsterisksOnEachLine() {
        let input = """
        /**
         * This is a documentation comment,
         * not a regular comment.
         */
        """
        let output = """
        /// This is a documentation comment,
        /// not a regular comment.
        """
        testFormatting(for: input, output, rule: .blockComments, exclude: [.docComments])
    }

    func testBlockDocCommentsWithoutAsterisksOnEachLine() {
        let input = """
        /**
         This is a documentation comment,
         not a regular comment.
         */
        """
        let output = """
        /// This is a documentation comment,
        /// not a regular comment.
        """
        testFormatting(for: input, output, rule: .blockComments, exclude: [.docComments])
    }

    func testBlockCommentWithBulletPoints() {
        let input = """
        /*
         This is a list of nice colors:

         * green
         * blue
         * red

         Yellow is also great.
         */

        /*
         * Another comment.
         */
        """
        let output = """
        // This is a list of nice colors:
        //
        // * green
        // * blue
        // * red
        //
        // Yellow is also great.

        // Another comment.
        """
        testFormatting(for: input, output, rule: .blockComments)
    }

    func testBlockCommentsNested() {
        let input = """
        /*
         * comment
         * /* inside */
         * a comment
         */
        """
        let output = """
        // comment
        // inside
        // a comment
        """
        testFormatting(for: input, output, rule: .blockComments)
    }

    func testBlockCommentsIndentPreserved() {
        let input = """
        func foo() {
            /*
             foo
             bar.
             */
        }
        """
        let output = """
        func foo() {
            // foo
            // bar.
        }
        """
        testFormatting(for: input, output, rule: .blockComments)
    }

    func testBlockCommentsIndentPreserved2() {
        let input = """
        func foo() {
            /*
             * foo
             * bar.
             */
        }
        """
        let output = """
        func foo() {
            // foo
            // bar.
        }
        """
        testFormatting(for: input, output, rule: .blockComments)
    }

    func testBlockDocCommentsIndentPreserved() {
        let input = """
        func foo() {
            /**
             * foo
             * bar.
             */
        }
        """
        let output = """
        func foo() {
            /// foo
            /// bar.
        }
        """
        testFormatting(for: input, output, rule: .blockComments, exclude: [.docComments])
    }

    func testLongBlockCommentsWithoutPerLineMarkersFullyConverted() {
        let input = """
        /*
            The beginnings of the lines in this multiline comment body
            have only spaces in them. There are no asterisks, only spaces.

            This should not cause the blockComments rule to convert only
            part of the comment body and leave the rest hanging.

            The comment must have at least this many lines to trigger the bug.
        */
        """
        let output = """
        // The beginnings of the lines in this multiline comment body
        // have only spaces in them. There are no asterisks, only spaces.
        //
        // This should not cause the blockComments rule to convert only
        // part of the comment body and leave the rest hanging.
        //
        // The comment must have at least this many lines to trigger the bug.
        """
        testFormatting(for: input, output, rule: .blockComments)
    }

    func testBlockCommentImmediatelyFollowedByCode() {
        let input = """
        /**
          foo

          bar
        */
        func foo() {}
        """
        let output = """
        /// foo
        ///
        /// bar
        func foo() {}
        """
        testFormatting(for: input, output, rule: .blockComments)
    }

    func testBlockCommentImmediatelyFollowedByCode2() {
        let input = """
        /**
         Line 1.

         Line 2.

         Line 3.
         */
        foo(bar)
        """
        let output = """
        /// Line 1.
        ///
        /// Line 2.
        ///
        /// Line 3.
        foo(bar)
        """
        testFormatting(for: input, output, rule: .blockComments, exclude: [.docComments])
    }

    func testBlockCommentImmediatelyFollowedByCode3() {
        let input = """
        /* foo
           bar */
        func foo() {}
        """
        let output = """
        // foo
        // bar
        func foo() {}
        """
        testFormatting(for: input, output, rule: .blockComments, exclude: [.docComments])
    }

    func testBlockCommentFollowedByBlankLine() {
        let input = """
        /**
          foo

          bar
        */

        func foo() {}
        """
        let output = """
        /// foo
        ///
        /// bar

        func foo() {}
        """
        testFormatting(for: input, output, rule: .blockComments, exclude: [.docComments])
    }
}
