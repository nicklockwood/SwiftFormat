//
//  SpaceInsideCommentsTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 8/31/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class SpaceInsideCommentsTests: XCTestCase {
    func testSpaceInsideMultilineComment() {
        let input = """
        /*foo
         bar*/
        """
        let output = """
        /* foo
         bar */
        """
        testFormatting(for: input, output, rule: .spaceInsideComments)
    }

    func testSpaceInsideSingleLineMultilineComment() {
        let input = """
        /*foo*/
        """
        let output = """
        /* foo */
        """
        testFormatting(for: input, output, rule: .spaceInsideComments)
    }

    func testNoSpaceInsideEmptyMultilineComment() {
        let input = """
        /**/
        """
        testFormatting(for: input, rule: .spaceInsideComments)
    }

    func testSpaceInsideSingleLineComment() {
        let input = """
        //foo
        """
        let output = """
        // foo
        """
        testFormatting(for: input, output, rule: .spaceInsideComments)
    }

    func testSpaceInsideMultilineHeaderdocComment() {
        let input = """
        /**foo
         bar*/
        """
        let output = """
        /** foo
         bar */
        """
        testFormatting(for: input, output, rule: .spaceInsideComments, exclude: [.docComments])
    }

    func testSpaceInsideMultilineHeaderdocCommentType2() {
        let input = """
        /*!foo
         bar*/
        """
        let output = """
        /*! foo
         bar */
        """
        testFormatting(for: input, output, rule: .spaceInsideComments)
    }

    func testSpaceInsideMultilineSwiftPlaygroundDocComment() {
        let input = """
        /*:foo
         bar*/
        """
        let output = """
        /*: foo
         bar */
        """
        testFormatting(for: input, output, rule: .spaceInsideComments)
    }

    func testNoExtraSpaceInsideMultilineHeaderdocComment() {
        let input = """
        /** foo
         bar */
        """
        testFormatting(for: input, rule: .spaceInsideComments, exclude: [.docComments])
    }

    func testNoExtraSpaceInsideMultilineHeaderdocCommentType2() {
        let input = """
        /*! foo
         bar */
        """
        testFormatting(for: input, rule: .spaceInsideComments)
    }

    func testNoExtraSpaceInsideMultilineSwiftPlaygroundDocComment() {
        let input = """
        /*: foo
         bar */
        """
        testFormatting(for: input, rule: .spaceInsideComments)
    }

    func testSpaceInsideSingleLineHeaderdocComment() {
        let input = """
        ///foo
        """
        let output = """
        /// foo
        """
        testFormatting(for: input, output, rule: .spaceInsideComments)
    }

    func testSpaceInsideSingleLineHeaderdocCommentType2() {
        let input = """
        //!foo
        """
        let output = """
        //! foo
        """
        testFormatting(for: input, output, rule: .spaceInsideComments)
    }

    func testSpaceInsideSingleLineSwiftPlaygroundDocComment() {
        let input = """
        //:foo
        """
        let output = """
        //: foo
        """
        testFormatting(for: input, output, rule: .spaceInsideComments)
    }

    func testPreformattedMultilineComment() {
        let input = """
        /*********************
         *****Hello World*****
         *********************/
        """
        testFormatting(for: input, rule: .spaceInsideComments)
    }

    func testPreformattedSingleLineComment() {
        let input = """
        /////////ATTENTION////////
        """
        testFormatting(for: input, rule: .spaceInsideComments)
    }

    func testNoSpaceAddedToFirstLineOfDocComment() {
        let input = """
        /**
         Comment
         */
        """
        testFormatting(for: input, rule: .spaceInsideComments, exclude: [.docComments])
    }

    func testNoSpaceAddedToEmptyDocComment() {
        let input = """
        ///
        """
        testFormatting(for: input, rule: .spaceInsideComments)
    }

    func testNoExtraTrailingSpaceAddedToDocComment() {
        let input = """
        class Foo {
            /**
            Call to configure forced disabling of Bills fallback mode.
            Intended for use only in debug builds and automated tests.
             */
            func bar() {}
        }
        """
        testFormatting(for: input, rule: .spaceInsideComments, exclude: [.indent])
    }
}
