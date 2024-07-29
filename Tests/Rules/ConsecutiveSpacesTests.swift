//
//  ConsecutiveSpacesTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class ConsecutiveSpacesTests: XCTestCase {
    func testConsecutiveSpaces() {
        let input = "let foo  = bar"
        let output = "let foo = bar"
        testFormatting(for: input, output, rule: .consecutiveSpaces)
    }

    func testConsecutiveSpacesAfterComment() {
        let input = "// comment\nfoo  bar"
        let output = "// comment\nfoo bar"
        testFormatting(for: input, output, rule: .consecutiveSpaces)
    }

    func testConsecutiveSpacesDoesntStripIndent() {
        let input = "{\n    let foo  = bar\n}"
        let output = "{\n    let foo = bar\n}"
        testFormatting(for: input, output, rule: .consecutiveSpaces)
    }

    func testConsecutiveSpacesDoesntAffectMultilineComments() {
        let input = "/*    comment  */"
        testFormatting(for: input, rule: .consecutiveSpaces)
    }

    func testConsecutiveSpacesRemovedBetweenComments() {
        let input = "/* foo */  /* bar */"
        let output = "/* foo */ /* bar */"
        testFormatting(for: input, output, rule: .consecutiveSpaces)
    }

    func testConsecutiveSpacesDoesntAffectNestedMultilineComments() {
        let input = "/*  foo  /*  bar  */  baz  */"
        testFormatting(for: input, rule: .consecutiveSpaces)
    }

    func testConsecutiveSpacesDoesntAffectNestedMultilineComments2() {
        let input = "/*  /*  foo  */  /*  bar  */  */"
        testFormatting(for: input, rule: .consecutiveSpaces)
    }

    func testConsecutiveSpacesDoesntAffectSingleLineComments() {
        let input = "//    foo  bar"
        testFormatting(for: input, rule: .consecutiveSpaces)
    }
}
