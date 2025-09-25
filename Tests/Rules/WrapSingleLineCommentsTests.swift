//
//  WrapSingleLineCommentsTests.swift
//  SwiftFormatTests
//
//  Created by Max Desiatov on 8/11/22.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class WrapSingleLineCommentsTests: XCTestCase {
    func testWrapSingleLineComment() {
        let input = """
        // a b cde fgh
        """
        let output = """
        // a b
        // cde
        // fgh
        """

        testFormatting(for: input, output, rule: .wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 6))
    }

    func testWrapSingleLineCommentThatOverflowsByOneCharacter() {
        let input = """
        // a b cde fg h
        """
        let output = """
        // a b cde fg
        // h
        """

        testFormatting(for: input, output, rule: .wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 14))
    }

    func testNoWrapSingleLineCommentThatExactlyFits() {
        let input = """
        // a b cde fg h
        """

        testFormatting(for: input, rule: .wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 15))
    }

    func testWrapSingleLineCommentWithNoLeadingSpace() {
        let input = """
        //a b cde fgh
        """
        let output = """
        //a b
        //cde
        //fgh
        """

        testFormatting(for: input, output, rule: .wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 6),
                       exclude: [.spaceInsideComments])
    }

    func testWrapDocComment() {
        let input = """
        /// a b cde fgh
        """
        let output = """
        /// a b
        /// cde
        /// fgh
        """

        testFormatting(for: input, output, rule: .wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 7), exclude: [.docComments])
    }

    func testWrapDocLineCommentWithNoLeadingSpace() {
        let input = """
        ///a b cde fgh
        """
        let output = """
        ///a b
        ///cde
        ///fgh
        """

        testFormatting(for: input, output, rule: .wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 6),
                       exclude: [.spaceInsideComments, .docComments])
    }

    func testWrapSingleLineCommentWithIndent() {
        let input = """
        func f() {
            // a b cde fgh
            let x = 1
        }
        """
        let output = """
        func f() {
            // a b cde
            // fgh
            let x = 1
        }
        """

        testFormatting(for: input, output, rule: .wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 14), exclude: [.docComments])
    }

    func testWrapSingleLineCommentAfterCode() {
        let input = """
        func f() {
            foo.bar() // this comment is much much much too long
        }
        """
        let output = """
        func f() {
            foo.bar() // this comment
            // is much much much too
            // long
        }
        """

        testFormatting(for: input, output, rule: .wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 29), exclude: [.wrap])
    }

    func testWrapDocCommentWithLongURL() {
        let input = """
        /// See [Link](https://www.domain.com/pathextension/pathextension/pathextension/pathextension/pathextension/pathextension).
        """

        testFormatting(for: input, rule: .wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 100), exclude: [.docComments])
    }

    func testWrapDocCommentWithLongURL2() {
        let input = """
        /// Link to SDK documentation - https://docs.adyen.com/checkout/3d-secure/native-3ds2/api-integration#collect-the-3d-secure-2-device-fingerprint-from-an-ios-app
        """

        testFormatting(for: input, rule: .wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 80))
    }

    func testWrapDocCommentWithMultipleLongURLs() {
        let input = """
        /// Link to http://a-very-long-url-that-wont-fit-on-one-line, http://another-very-long-url-that-wont-fit-on-one-line
        """
        let output = """
        /// Link to http://a-very-long-url-that-wont-fit-on-one-line,
        /// http://another-very-long-url-that-wont-fit-on-one-line
        """

        testFormatting(for: input, output, rule: .wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 40), exclude: [.docComments])
    }
}
