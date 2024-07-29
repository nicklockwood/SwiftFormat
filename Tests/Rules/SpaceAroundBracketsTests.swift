//
//  SpaceAroundBracketsTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class SpaceAroundBracketsTests: XCTestCase {
    func testSubscriptNoAddSpacing() {
        let input = "foo[bar] = baz"
        testFormatting(for: input, rule: .spaceAroundBrackets)
    }

    func testSubscriptRemoveSpacing() {
        let input = "foo [bar] = baz"
        let output = "foo[bar] = baz"
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testArrayLiteralSpacing() {
        let input = "foo = [bar, baz]"
        testFormatting(for: input, rule: .spaceAroundBrackets)
    }

    func testAsArrayCastingSpacing() {
        let input = "foo as[String]"
        let output = "foo as [String]"
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testAsOptionalArrayCastingSpacing() {
        let input = "foo as? [String]"
        testFormatting(for: input, rule: .spaceAroundBrackets)
    }

    func testIsArrayTestingSpacing() {
        let input = "if foo is[String] {}"
        let output = "if foo is [String] {}"
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testKeywordAsIdentifierBracketSpacing() {
        let input = "if foo.is[String] {}"
        testFormatting(for: input, rule: .spaceAroundBrackets)
    }

    func testSpaceBeforeTupleIndexSubscript() {
        let input = "foo.1 [2]"
        let output = "foo.1[2]"
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testRemoveSpaceBetweenBracketAndParen() {
        let input = "let foo = bar[5] ()"
        let output = "let foo = bar[5]()"
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testRemoveSpaceBetweenBracketAndParenInsideClosure() {
        let input = "let foo = bar { [Int] () }"
        let output = "let foo = bar { [Int]() }"
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testAddSpaceBetweenCaptureListAndParen() {
        let input = "let foo = bar { [self](foo: Int) in foo }"
        let output = "let foo = bar { [self] (foo: Int) in foo }"
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testAddSpaceBetweenInoutAndStringArray() {
        let input = "func foo(arg _: inout[String]) {}"
        let output = "func foo(arg _: inout [String]) {}"
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testAddSpaceBetweenConsumingAndStringArray() {
        let input = "func foo(arg _: consuming[String]) {}"
        let output = "func foo(arg _: consuming [String]) {}"
        testFormatting(for: input, output, rule: .spaceAroundBrackets,
                       exclude: [.noExplicitOwnership])
    }

    func testAddSpaceBetweenBorrowingAndStringArray() {
        let input = "func foo(arg _: borrowing[String]) {}"
        let output = "func foo(arg _: borrowing [String]) {}"
        testFormatting(for: input, output, rule: .spaceAroundBrackets,
                       exclude: [.noExplicitOwnership])
    }

    func testAddSpaceBetweenSendingAndStringArray() {
        let input = "func foo(arg _: sending[String]) {}"
        let output = "func foo(arg _: sending [String]) {}"
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }
}
