//
//  SpaceAroundCommentsTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 8/31/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class SpaceAroundCommentsTests: XCTestCase {
    func testSpaceAroundCommentInParens() {
        let input = """
        (/* foo */)
        """
        let output = """
        ( /* foo */ )
        """
        testFormatting(for: input, output, rule: .spaceAroundComments)
    }

    func testNoSpaceAroundCommentAtStartAndEndOfFile() {
        let input = """
        /* foo */
        """
        testFormatting(for: input, rule: .spaceAroundComments)
    }

    func testNoSpaceAroundCommentBeforeComma() {
        let input = """
        (foo /* foo */ , bar)
        """
        let output = """
        (foo /* foo */, bar)
        """
        testFormatting(for: input, output, rule: .spaceAroundComments)
    }

    func testSpaceAroundSingleLineComment() {
        let input = """
        func foo() {// comment
        }
        """
        let output = """
        func foo() { // comment
        }
        """
        testFormatting(for: input, output, rule: .spaceAroundComments)
    }
}
