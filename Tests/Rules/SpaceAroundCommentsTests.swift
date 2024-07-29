//
//  SpaceAroundCommentsTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class SpaceAroundCommentsTests: XCTestCase {
    func testSpaceAroundCommentInParens() {
        let input = "(/* foo */)"
        let output = "( /* foo */ )"
        testFormatting(for: input, output, rule: .spaceAroundComments,
                       exclude: [.redundantParens])
    }

    func testNoSpaceAroundCommentAtStartAndEndOfFile() {
        let input = "/* foo */"
        testFormatting(for: input, rule: .spaceAroundComments)
    }

    func testNoSpaceAroundCommentBeforeComma() {
        let input = "(foo /* foo */ , bar)"
        let output = "(foo /* foo */, bar)"
        testFormatting(for: input, output, rule: .spaceAroundComments)
    }

    func testSpaceAroundSingleLineComment() {
        let input = "func foo() {// comment\n}"
        let output = "func foo() { // comment\n}"
        testFormatting(for: input, output, rule: .spaceAroundComments)
    }
}
