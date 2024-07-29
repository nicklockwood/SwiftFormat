//
//  LeadingDelimitersTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class LeadingDelimitersTests: XCTestCase {
    func testLeadingCommaMovedToPreviousLine() {
        let input = """
        let foo = 5
            , bar = 6
        """
        let output = """
        let foo = 5,
            bar = 6
        """
        testFormatting(for: input, output, rule: .leadingDelimiters)
    }

    func testLeadingColonFollowedByCommentMovedToPreviousLine() {
        let input = """
        let foo
            : /* string */ String
        """
        let output = """
        let foo:
            /* string */ String
        """
        testFormatting(for: input, output, rule: .leadingDelimiters)
    }

    func testCommaMovedBeforeCommentIfLineEndsInComment() {
        let input = """
        let foo = 5 // first
            , bar = 6
        """
        let output = """
        let foo = 5, // first
            bar = 6
        """
        testFormatting(for: input, output, rule: .leadingDelimiters)
    }
}
