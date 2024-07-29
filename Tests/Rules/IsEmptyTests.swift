//
//  IsEmptyTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class IsEmptyTests: XCTestCase {
    // count == 0

    func testCountEqualsZero() {
        let input = "if foo.count == 0 {}"
        let output = "if foo.isEmpty {}"
        testFormatting(for: input, output, rule: .isEmpty)
    }

    func testFunctionCountEqualsZero() {
        let input = "if foo().count == 0 {}"
        let output = "if foo().isEmpty {}"
        testFormatting(for: input, output, rule: .isEmpty)
    }

    func testExpressionCountEqualsZero() {
        let input = "if foo || bar.count == 0 {}"
        let output = "if foo || bar.isEmpty {}"
        testFormatting(for: input, output, rule: .isEmpty)
    }

    func testCompoundIfCountEqualsZero() {
        let input = "if foo, bar.count == 0 {}"
        let output = "if foo, bar.isEmpty {}"
        testFormatting(for: input, output, rule: .isEmpty)
    }

    func testOptionalCountEqualsZero() {
        let input = "if foo?.count == 0 {}"
        let output = "if foo?.isEmpty == true {}"
        testFormatting(for: input, output, rule: .isEmpty)
    }

    func testOptionalChainCountEqualsZero() {
        let input = "if foo?.bar.count == 0 {}"
        let output = "if foo?.bar.isEmpty == true {}"
        testFormatting(for: input, output, rule: .isEmpty)
    }

    func testCompoundIfOptionalCountEqualsZero() {
        let input = "if foo, bar?.count == 0 {}"
        let output = "if foo, bar?.isEmpty == true {}"
        testFormatting(for: input, output, rule: .isEmpty)
    }

    func testTernaryCountEqualsZero() {
        let input = "foo ? bar.count == 0 : baz.count == 0"
        let output = "foo ? bar.isEmpty : baz.isEmpty"
        testFormatting(for: input, output, rule: .isEmpty)
    }

    // count != 0

    func testCountNotEqualToZero() {
        let input = "if foo.count != 0 {}"
        let output = "if !foo.isEmpty {}"
        testFormatting(for: input, output, rule: .isEmpty)
    }

    func testFunctionCountNotEqualToZero() {
        let input = "if foo().count != 0 {}"
        let output = "if !foo().isEmpty {}"
        testFormatting(for: input, output, rule: .isEmpty)
    }

    func testExpressionCountNotEqualToZero() {
        let input = "if foo || bar.count != 0 {}"
        let output = "if foo || !bar.isEmpty {}"
        testFormatting(for: input, output, rule: .isEmpty)
    }

    func testCompoundIfCountNotEqualToZero() {
        let input = "if foo, bar.count != 0 {}"
        let output = "if foo, !bar.isEmpty {}"
        testFormatting(for: input, output, rule: .isEmpty)
    }

    // count > 0

    func testCountGreaterThanZero() {
        let input = "if foo.count > 0 {}"
        let output = "if !foo.isEmpty {}"
        testFormatting(for: input, output, rule: .isEmpty)
    }

    func testCountExpressionGreaterThanZero() {
        let input = "if a.count - b.count > 0 {}"
        testFormatting(for: input, rule: .isEmpty)
    }

    // optional count

    func testOptionalCountNotEqualToZero() {
        let input = "if foo?.count != 0 {}" // nil evaluates to true
        let output = "if foo?.isEmpty != true {}"
        testFormatting(for: input, output, rule: .isEmpty)
    }

    func testOptionalChainCountNotEqualToZero() {
        let input = "if foo?.bar.count != 0 {}" // nil evaluates to true
        let output = "if foo?.bar.isEmpty != true {}"
        testFormatting(for: input, output, rule: .isEmpty)
    }

    func testCompoundIfOptionalCountNotEqualToZero() {
        let input = "if foo, bar?.count != 0 {}"
        let output = "if foo, bar?.isEmpty != true {}"
        testFormatting(for: input, output, rule: .isEmpty)
    }

    // edge cases

    func testTernaryCountNotEqualToZero() {
        let input = "foo ? bar.count != 0 : baz.count != 0"
        let output = "foo ? !bar.isEmpty : !baz.isEmpty"
        testFormatting(for: input, output, rule: .isEmpty)
    }

    func testCountEqualsZeroAfterOptionalOnPreviousLine() {
        let input = "_ = foo?.bar\nbar.count == 0 ? baz() : quux()"
        let output = "_ = foo?.bar\nbar.isEmpty ? baz() : quux()"
        testFormatting(for: input, output, rule: .isEmpty)
    }

    func testCountEqualsZeroAfterOptionalCallOnPreviousLine() {
        let input = "foo?.bar()\nbar.count == 0 ? baz() : quux()"
        let output = "foo?.bar()\nbar.isEmpty ? baz() : quux()"
        testFormatting(for: input, output, rule: .isEmpty)
    }

    func testCountEqualsZeroAfterTrailingCommentOnPreviousLine() {
        let input = "foo?.bar() // foobar\nbar.count == 0 ? baz() : quux()"
        let output = "foo?.bar() // foobar\nbar.isEmpty ? baz() : quux()"
        testFormatting(for: input, output, rule: .isEmpty)
    }

    func testCountGreaterThanZeroAfterOpenParen() {
        let input = "foo(bar.count > 0)"
        let output = "foo(!bar.isEmpty)"
        testFormatting(for: input, output, rule: .isEmpty)
    }

    func testCountGreaterThanZeroAfterArgumentLabel() {
        let input = "foo(bar: baz.count > 0)"
        let output = "foo(bar: !baz.isEmpty)"
        testFormatting(for: input, output, rule: .isEmpty)
    }
}
