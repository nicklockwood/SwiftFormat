//
//  SpaceAroundBracesTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class SpaceAroundBracesTests: XCTestCase {
    func testSpaceAroundTrailingClosure() {
        let input = "if x{ y }else{ z }"
        let output = "if x { y } else { z }"
        testFormatting(for: input, output, rule: .spaceAroundBraces,
                       exclude: [.wrapConditionalBodies])
    }

    func testNoSpaceAroundClosureInsiderParens() {
        let input = "foo({ $0 == 5 })"
        testFormatting(for: input, rule: .spaceAroundBraces,
                       exclude: [.trailingClosures])
    }

    func testNoExtraSpaceAroundBracesAtStartOrEndOfFile() {
        let input = "{ foo }"
        testFormatting(for: input, rule: .spaceAroundBraces)
    }

    func testNoSpaceAfterPrefixOperator() {
        let input = "let foo = ..{ bar }"
        testFormatting(for: input, rule: .spaceAroundBraces)
    }

    func testNoSpaceBeforePostfixOperator() {
        let input = "let foo = { bar }.."
        testFormatting(for: input, rule: .spaceAroundBraces)
    }

    func testSpaceAroundBracesAfterOptionalProperty() {
        let input = "var: Foo?{}"
        let output = "var: Foo? {}"
        testFormatting(for: input, output, rule: .spaceAroundBraces)
    }

    func testSpaceAroundBracesAfterImplicitlyUnwrappedProperty() {
        let input = "var: Foo!{}"
        let output = "var: Foo! {}"
        testFormatting(for: input, output, rule: .spaceAroundBraces)
    }

    func testSpaceAroundBracesAfterNumber() {
        let input = "if x = 5{}"
        let output = "if x = 5 {}"
        testFormatting(for: input, output, rule: .spaceAroundBraces)
    }

    func testSpaceAroundBracesAfterString() {
        let input = "if x = \"\"{}"
        let output = "if x = \"\" {}"
        testFormatting(for: input, output, rule: .spaceAroundBraces)
    }
}
