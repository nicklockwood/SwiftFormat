//
//  ConsecutiveSpacesTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 8/30/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class ConsecutiveSpacesTests: XCTestCase {
    func testConsecutiveSpaces() {
        let input = """
        let foo  = bar
        """
        let output = """
        let foo = bar
        """
        testFormatting(for: input, output, rule: .consecutiveSpaces)
    }

    func testConsecutiveSpacesAfterComment() {
        let input = """
        // comment
        foo  bar
        """
        let output = """
        // comment
        foo bar
        """
        testFormatting(for: input, output, rule: .consecutiveSpaces)
    }

    func testConsecutiveSpacesDoesntStripIndent() {
        let input = """
        {
            let foo  = bar
        }
        """
        let output = """
        {
            let foo = bar
        }
        """
        testFormatting(for: input, output, rule: .consecutiveSpaces)
    }

    func testConsecutiveSpacesDoesntAffectMultilineComments() {
        let input = """
        /*    comment  */
        """
        testFormatting(for: input, rule: .consecutiveSpaces)
    }

    func testConsecutiveSpacesRemovedBetweenComments() {
        let input = """
        /* foo */  /* bar */
        """
        let output = """
        /* foo */ /* bar */
        """
        testFormatting(for: input, output, rule: .consecutiveSpaces)
    }

    func testConsecutiveSpacesDoesntAffectNestedMultilineComments() {
        let input = """
        /*  foo  /*  bar  */  baz  */
        """
        testFormatting(for: input, rule: .consecutiveSpaces)
    }

    func testConsecutiveSpacesDoesntAffectNestedMultilineComments2() {
        let input = """
        /*  /*  foo  */  /*  bar  */  */
        """
        testFormatting(for: input, rule: .consecutiveSpaces)
    }

    func testConsecutiveSpacesDoesntAffectSingleLineComments() {
        let input = """
        //    foo  bar
        """
        testFormatting(for: input, rule: .consecutiveSpaces)
    }
}
