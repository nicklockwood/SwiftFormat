//
//  NumberFormattingTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 1/17/17.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class NumberFormattingTests: XCTestCase {
    // hex case

    func testLowercaseLiteralConvertedToUpper() {
        let input = "let foo = 0xabcd"
        let output = "let foo = 0xABCD"
        testFormatting(for: input, output, rule: .numberFormatting)
    }

    func testMixedCaseLiteralConvertedToUpper() {
        let input = "let foo = 0xaBcD"
        let output = "let foo = 0xABCD"
        testFormatting(for: input, output, rule: .numberFormatting)
    }

    func testUppercaseLiteralConvertedToLower() {
        let input = "let foo = 0xABCD"
        let output = "let foo = 0xabcd"
        let options = FormatOptions(uppercaseHex: false)
        testFormatting(for: input, output, rule: .numberFormatting, options: options)
    }

    func testPInExponentialNotConvertedToUpper() {
        let input = "let foo = 0xaBcDp5"
        let output = "let foo = 0xABCDp5"
        testFormatting(for: input, output, rule: .numberFormatting)
    }

    func testPInExponentialNotConvertedToLower() {
        let input = "let foo = 0xaBcDP5"
        let output = "let foo = 0xabcdP5"
        let options = FormatOptions(uppercaseHex: false, uppercaseExponent: true)
        testFormatting(for: input, output, rule: .numberFormatting, options: options)
    }

    // exponent case

    func testLowercaseExponent() {
        let input = "let foo = 0.456E-5"
        let output = "let foo = 0.456e-5"
        testFormatting(for: input, output, rule: .numberFormatting)
    }

    func testUppercaseExponent() {
        let input = "let foo = 0.456e-5"
        let output = "let foo = 0.456E-5"
        let options = FormatOptions(uppercaseExponent: true)
        testFormatting(for: input, output, rule: .numberFormatting, options: options)
    }

    func testUppercaseHexExponent() {
        let input = "let foo = 0xFF00p54"
        let output = "let foo = 0xFF00P54"
        let options = FormatOptions(uppercaseExponent: true)
        testFormatting(for: input, output, rule: .numberFormatting, options: options)
    }

    func testUppercaseGroupedHexExponent() {
        let input = "let foo = 0xFF00_AABB_CCDDp54"
        let output = "let foo = 0xFF00_AABB_CCDDP54"
        let options = FormatOptions(uppercaseExponent: true)
        testFormatting(for: input, output, rule: .numberFormatting, options: options)
    }

    // decimal grouping

    func testDefaultDecimalGrouping() {
        let input = "let foo = 1234_56_78"
        let output = "let foo = 12_345_678"
        testFormatting(for: input, output, rule: .numberFormatting)
    }

    func testIgnoreDecimalGrouping() {
        let input = "let foo = 1234_5_678"
        let options = FormatOptions(decimalGrouping: .ignore)
        testFormatting(for: input, rule: .numberFormatting, options: options)
    }

    func testNoDecimalGrouping() {
        let input = "let foo = 1234_5_678"
        let output = "let foo = 12345678"
        let options = FormatOptions(decimalGrouping: .none)
        testFormatting(for: input, output, rule: .numberFormatting, options: options)
    }

    func testDecimalGroupingThousands() {
        let input = "let foo = 1234"
        let output = "let foo = 1_234"
        let options = FormatOptions(decimalGrouping: .group(3, 3))
        testFormatting(for: input, output, rule: .numberFormatting, options: options)
    }

    func testExponentialGrouping() {
        let input = "let foo = 1234e5678"
        let output = "let foo = 1_234e5678"
        let options = FormatOptions(decimalGrouping: .group(3, 3))
        testFormatting(for: input, output, rule: .numberFormatting, options: options)
    }

    func testZeroGrouping() {
        let input = "let foo = 1234"
        let options = FormatOptions(decimalGrouping: .group(0, 0))
        testFormatting(for: input, rule: .numberFormatting, options: options)
    }

    // binary grouping

    func testDefaultBinaryGrouping() {
        let input = "let foo = 0b11101000_00111111"
        let output = "let foo = 0b1110_1000_0011_1111"
        testFormatting(for: input, output, rule: .numberFormatting)
    }

    func testIgnoreBinaryGrouping() {
        let input = "let foo = 0b1110_10_00"
        let options = FormatOptions(binaryGrouping: .ignore)
        testFormatting(for: input, rule: .numberFormatting, options: options)
    }

    func testNoBinaryGrouping() {
        let input = "let foo = 0b1110_10_00"
        let output = "let foo = 0b11101000"
        let options = FormatOptions(binaryGrouping: .none)
        testFormatting(for: input, output, rule: .numberFormatting, options: options)
    }

    func testBinaryGroupingCustom() {
        let input = "let foo = 0b110011"
        let output = "let foo = 0b11_00_11"
        let options = FormatOptions(binaryGrouping: .group(2, 2))
        testFormatting(for: input, output, rule: .numberFormatting, options: options)
    }

    // hex grouping

    func testDefaultHexGrouping() {
        let input = "let foo = 0xFF01FF01AE45"
        let output = "let foo = 0xFF01_FF01_AE45"
        testFormatting(for: input, output, rule: .numberFormatting)
    }

    func testCustomHexGrouping() {
        let input = "let foo = 0xFF00p54"
        let output = "let foo = 0xFF_00p54"
        let options = FormatOptions(hexGrouping: .group(2, 2))
        testFormatting(for: input, output, rule: .numberFormatting, options: options)
    }

    // octal grouping

    func testDefaultOctalGrouping() {
        let input = "let foo = 0o123456701234"
        let output = "let foo = 0o1234_5670_1234"
        testFormatting(for: input, output, rule: .numberFormatting)
    }

    func testCustomOctalGrouping() {
        let input = "let foo = 0o12345670"
        let output = "let foo = 0o12_34_56_70"
        let options = FormatOptions(octalGrouping: .group(2, 2))
        testFormatting(for: input, output, rule: .numberFormatting, options: options)
    }

    // fraction grouping

    func testIgnoreFractionGrouping() {
        let input = "let foo = 1.234_5_678"
        let options = FormatOptions(decimalGrouping: .ignore, fractionGrouping: true)
        testFormatting(for: input, rule: .numberFormatting, options: options)
    }

    func testNoFractionGrouping() {
        let input = "let foo = 1.234_5_678"
        let output = "let foo = 1.2345678"
        let options = FormatOptions(decimalGrouping: .none, fractionGrouping: true)
        testFormatting(for: input, output, rule: .numberFormatting, options: options)
    }

    func testFractionGroupingThousands() {
        let input = "let foo = 12.34_56_78"
        let output = "let foo = 12.345_678"
        let options = FormatOptions(decimalGrouping: .group(3, 3), fractionGrouping: true)
        testFormatting(for: input, output, rule: .numberFormatting, options: options)
    }

    func testHexFractionGrouping() {
        let input = "let foo = 0x12.34_56_78p56"
        let output = "let foo = 0x12.34_5678p56"
        let options = FormatOptions(hexGrouping: .group(4, 4), fractionGrouping: true)
        testFormatting(for: input, output, rule: .numberFormatting, options: options)
    }
}
