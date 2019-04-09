//
//  SprinterTests.swift
//  SprinterTests
//
//  Created by Nick Lockwood on 20/11/2017.
//  Copyright © 2017 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import Sprinter

class SprinterTests: XCTestCase {
    // MARK: format errors

    func testParseTrailingPercentCharacter() {
        XCTAssertThrowsError(try FormatString("foo %")) { error in
            XCTAssertEqual(error as? FormatString.Error, .unexpectedEndOfString)
        }
    }

    func testParseTrailingIndex() {
        XCTAssertThrowsError(try FormatString("foo %5$")) { error in
            XCTAssertEqual(error as? FormatString.Error, .unexpectedEndOfString)
        }
    }

    func testParseTrailingFlag() {
        XCTAssertThrowsError(try FormatString("foo %'")) { error in
            XCTAssertEqual(error as? FormatString.Error, .unexpectedEndOfString)
        }
    }

    func testParseTrailingWidth() {
        XCTAssertThrowsError(try FormatString("foo %5")) { error in
            XCTAssertEqual(error as? FormatString.Error, .unexpectedEndOfString)
        }
    }

    func testParseTrailingWidth2() {
        XCTAssertThrowsError(try FormatString("foo %*")) { error in
            XCTAssertEqual(error as? FormatString.Error, .unexpectedEndOfString)
        }
    }

    func testParseTrailingWidth3() {
        XCTAssertThrowsError(try FormatString("foo %*4")) { error in
            XCTAssertEqual(error as? FormatString.Error, .unexpectedEndOfString)
        }
    }

    func testParseMalformedWidth() {
        XCTAssertThrowsError(try FormatString("foo %*4i")) { error in
            XCTAssertEqual(error as? FormatString.Error, .unexpectedToken("i"))
        }
    }

    func testParseTrailingPrecision() {
        XCTAssertThrowsError(try FormatString("foo %.")) { error in
            XCTAssertEqual(error as? FormatString.Error, .unexpectedEndOfString)
        }
    }

    func testParseTrailingPrecision2() {
        XCTAssertThrowsError(try FormatString("foo %.5")) { error in
            XCTAssertEqual(error as? FormatString.Error, .unexpectedEndOfString)
        }
    }

    func testParseIndexedPercentCharacter() {
        XCTAssertThrowsError(try FormatString("%2$%")) { error in
            XCTAssertEqual(error as? FormatString.Error, .modifierMismatch("2", "%"))
        }
    }

    func testParseGroupedPercentCharacter() {
        XCTAssertThrowsError(try FormatString("%'%")) { error in
            XCTAssertEqual(error as? FormatString.Error, .modifierMismatch("'", "%"))
        }
    }

    func testParseWidthedPercentCharacter() {
        XCTAssertThrowsError(try FormatString("%5%")) { error in
            XCTAssertEqual(error as? FormatString.Error, .modifierMismatch("5", "%"))
        }
    }

    func testParseLongPercentCharacter() {
        XCTAssertThrowsError(try FormatString("%l%")) { error in
            XCTAssertEqual(error as? FormatString.Error, .modifierMismatch("l", "%"))
        }
    }

    func testParseMissingSpecifier() {
        XCTAssertThrowsError(try FormatString("foo %5$ bar")) { error in
            XCTAssertEqual(error as? FormatString.Error, .unexpectedToken("b"))
        }
    }

    func testParseInvalidSpecifier() {
        XCTAssertThrowsError(try FormatString("foo %bar")) { error in
            XCTAssertEqual(error as? FormatString.Error, .unexpectedToken("b"))
        }
    }

    func testInvalidIndex() {
        XCTAssertThrowsError(try FormatString("%05$i")) { error in
            XCTAssertEqual(error as? FormatString.Error, .unexpectedToken("$"))
        }
    }

    func testInvalidIndex2() {
        XCTAssertThrowsError(try FormatString("%005$i")) { error in
            XCTAssertEqual(error as? FormatString.Error, .duplicateFlag("0"))
        }
    }

    func testInvalidIndex3() {
        XCTAssertThrowsError(try FormatString("%123456789123456789123456789$i")) { error in
            XCTAssertEqual(error as? FormatString.Error, .unexpectedToken("1"))
        }
    }

    func testTypeMismatch() {
        XCTAssertThrowsError(try FormatString("%i %1$f")) { error in
            XCTAssertEqual(error as? FormatString.Error, .typeMismatch(1, Int.self, Double.self))
        }
    }

    func testArgumentMismatch() {
        XCTAssertThrowsError(try FormatString("%i").print("foo")) { error in
            XCTAssertEqual(error as? FormatString.Error, .argumentMismatch(1, String.self, Int.self))
        }
    }

    func testModifierMismatch() {
        XCTAssertThrowsError(try FormatString("%Ld")) { error in
            XCTAssertEqual(error as? FormatString.Error, .modifierMismatch("L", "d"))
        }
        XCTAssertThrowsError(try FormatString("%Lu"))
        XCTAssertThrowsError(try FormatString("%lf"))
        XCTAssertThrowsError(try FormatString("%zc"))
        XCTAssertThrowsError(try FormatString("%llC"))
        XCTAssertThrowsError(try FormatString("%ts"))
        XCTAssertThrowsError(try FormatString("%LS"))
        XCTAssertThrowsError(try FormatString("%lp"))
        XCTAssertThrowsError(try FormatString("%h%"))
        XCTAssertThrowsError(try FormatString("%l@"))
    }

    func testUnsupportedSpecifier() {
        XCTAssertThrowsError(try FormatString("%n")) { error in
            XCTAssertEqual(error as? FormatString.Error, .unsupportedSpecifier("n"))
        }
    }

    // MARK: Error printing and comparisons

    func testErrorDescriptions() {
        XCTAssert("\(FormatString.Error.unexpectedEndOfString)".contains("end"))
        XCTAssert("\(FormatString.Error.unexpectedToken("a"))".contains("'a'"))
        XCTAssert("\(FormatString.Error.duplicateFlag("a"))".contains("'a'"))
        XCTAssert("\(FormatString.Error.unsupportedFlag("a"))".contains("'a'"))
        XCTAssert("\(FormatString.Error.unsupportedSpecifier("a"))".contains("'a'"))
        XCTAssert("\(FormatString.Error.modifierMismatch("a", "a"))".contains("'a'"))
        XCTAssert("\(FormatString.Error.typeMismatch(1, Any.self, Any.self))".contains("#1"))
        XCTAssert("\(FormatString.Error.argumentMismatch(1, Any.self, Any.self))".contains("#1"))
        XCTAssert("\(FormatString.Error.missingArgument(3))".contains("#3"))
    }

    func testErrorEquality() {
        XCTAssertNotEqual(FormatString.Error.unexpectedEndOfString, .missingArgument(1))
        XCTAssertNotEqual(FormatString.Error.unexpectedToken("a"), .unexpectedEndOfString)
        XCTAssertNotEqual(FormatString.Error.duplicateFlag("a"), .unexpectedEndOfString)
        XCTAssertNotEqual(FormatString.Error.unsupportedFlag("a"), .unexpectedEndOfString)
        XCTAssertNotEqual(FormatString.Error.unsupportedSpecifier("a"), .unexpectedEndOfString)
        XCTAssertNotEqual(FormatString.Error.modifierMismatch("a", "a"), .unexpectedEndOfString)
        XCTAssertNotEqual(FormatString.Error.typeMismatch(1, Any.self, Any.self), .unexpectedEndOfString)
        XCTAssertNotEqual(FormatString.Error.argumentMismatch(1, Any.self, Any.self), .unexpectedEndOfString)
        XCTAssertNotEqual(FormatString.Error.missingArgument(3), .unexpectedEndOfString)
    }

    // MARK: specifiers and types

    func testParsePercentPlaceholder() throws {
        let formatString = try FormatString("%%")
        XCTAssertEqual(formatString.placeholders.first?.specifier, .percentChar)
        XCTAssertEqual(formatString.types.map { "\($0)" }, [])
    }

    func testParseObjectPlaceholder() throws {
        let formatString = try FormatString("%@")
        XCTAssertEqual(formatString.placeholders.first?.specifier, .object)
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["Any"])
    }

    func testParseIntPlaceholder() throws {
        let formatString = try FormatString("%i")
        XCTAssertEqual(formatString.placeholders.first?.specifier, .int)
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["Int"])
    }

    func testParseSizeTPlaceholder() throws {
        let formatString = try FormatString("%zd")
        XCTAssertEqual(formatString.placeholders.first?.specifier, .decimal)
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["Int"])
    }

    func testParseUnsignedSizeTPlaceholder() throws {
        let formatString = try FormatString("%zu")
        XCTAssertEqual(formatString.placeholders.first?.specifier, .unsigned)
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["UInt"])
    }

    func testParsePointerSizedPlaceholder() throws {
        let formatString = try FormatString("%td")
        XCTAssertEqual(formatString.placeholders.first?.specifier, .decimal)
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["Int"])
    }

    func testParseUnsignedPointerSizedPlaceholder() throws {
        let formatString = try FormatString("%tu")
        XCTAssertEqual(formatString.placeholders.first?.specifier, .unsigned)
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["UInt"])
    }

    func testParseIntMaxPlaceholder() throws {
        let formatString = try FormatString("%jd")
        XCTAssertEqual(formatString.placeholders.first?.specifier, .decimal)
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["Int"])
    }

    func testParseUnsignedIntMaxPlaceholder() throws {
        let formatString = try FormatString("%ju")
        XCTAssertEqual(formatString.placeholders.first?.specifier, .unsigned)
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["UInt"])
    }

    func testParseLongDecimalPlaceholder() throws {
        let formatString = try FormatString("%ld")
        XCTAssertEqual(formatString.placeholders.first?.specifier, .decimal)
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["Int"])
    }

    func testParseLongLongDecimalPlaceholder() throws {
        let formatString = try FormatString("%lld")
        XCTAssertEqual(formatString.placeholders.first?.specifier, .decimal)
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["Int64"])
    }

    func testParseUnsignedLongPlaceholder() throws {
        let formatString = try FormatString("%lu")
        XCTAssertEqual(formatString.placeholders.first?.specifier, .unsigned)
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["UInt"])
    }

    func testParseUnsignedLongLongPlaceholder() throws {
        let formatString = try FormatString("%llu")
        XCTAssertEqual(formatString.placeholders.first?.specifier, .unsigned)
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["UInt64"])
    }

    func testParseShortIntPlaceholder() throws {
        let formatString = try FormatString("%hi")
        XCTAssertEqual(formatString.placeholders.first?.specifier, .int)
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["Int16"])
    }

    func testParseCharLengthIntPlaceholder() throws {
        let formatString = try FormatString("%hhi")
        XCTAssertEqual(formatString.placeholders.first?.specifier, .int)
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["Int8"])
    }

    func testParseUnsignedShortPlaceholder() throws {
        let formatString = try FormatString("%hu")
        XCTAssertEqual(formatString.placeholders.first?.specifier, .unsigned)
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["UInt16"])
    }

    func testParseUnsignedCharPlaceholder() throws {
        let formatString = try FormatString("%hhu")
        XCTAssertEqual(formatString.placeholders.first?.specifier, .unsigned)
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["UInt8"])
    }

    func testParseHexPlaceholder() throws {
        let formatString = try FormatString("%x")
        XCTAssertEqual(formatString.placeholders.first?.specifier, .hex)
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["Int"])
    }

    func testParseShortHexPlaceholder() throws {
        let formatString = try FormatString("%hx")
        XCTAssertEqual(formatString.placeholders.first?.specifier, .hex)
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["Int16"])
    }

    func testParseFloatPlaceholder() throws {
        let formatString = try FormatString("%f")
        XCTAssertEqual(formatString.placeholders.first?.specifier, .float)
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["Double"])
    }

    func testParseVariablePrecisionFloatPlaceholder() throws {
        let formatString = try FormatString("%g")
        XCTAssertEqual(formatString.placeholders.first?.specifier, .variablePrecisionFloat)
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["Double"])
    }

    func testParseFloat80Placeholder() throws {
        let formatString = try FormatString("%Lf")
        XCTAssertEqual(formatString.placeholders.first?.specifier, .float)
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["Float80"])
    }

    func testParseCharacterPlaceholder() throws {
        let formatString = try FormatString("%c")
        XCTAssertEqual(formatString.placeholders.first?.specifier, .char)
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["Character"])
    }

    func testParseWideCharacterPlaceholder() throws {
        let formatString = try FormatString("%lc")
        XCTAssertEqual(formatString.placeholders.first?.specifier, .char)
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["Character"])
    }

    func testParseStringlaceholder() throws {
        let formatString = try FormatString("%s")
        XCTAssertEqual(formatString.placeholders.first?.specifier, .string)
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["String"])
    }

    func testParseWideStringlaceholder() throws {
        let formatString = try FormatString("%ls")
        XCTAssertEqual(formatString.placeholders.first?.specifier, .string)
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["String"])
    }

    func testParsePercentPlaceholderFollowedByInteger() throws {
        let formatString = try FormatString("foo %% bar %i")
        XCTAssertEqual(formatString.placeholders.map { $0.specifier }, [.percentChar, .int])
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["Int"])
    }

    // MARK: argument indices

    func testReversedIndices() throws {
        let formatString = try FormatString("%2$f %1$i")
        XCTAssertEqual(formatString.placeholders.map { $0.specifier }, [.float, .int])
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["Int", "Double"])
    }

    func testDuplicateIndices() throws {
        let formatString = try FormatString("%2$f %1$i %2$f")
        XCTAssertEqual(formatString.placeholders.map { $0.specifier }, [.float, .int, .float])
        XCTAssertEqual(formatString.types.map { "\($0)" }, ["Int", "Double"])
    }

    func testMultiDigitIndex() throws {
        let formatString = try FormatString("%205$f")
        XCTAssertEqual(formatString.placeholders.map { $0.specifier }, [.float])
        XCTAssertEqual(formatString.types.count, 205)
    }

    // MARK: printing

    func testPrintLiteral() throws {
        let string = "foo"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(), "foo")
        XCTAssertEqual(try formatString.print(), String(format: string))
    }

    func testPrintPercentCharacter() throws {
        let string = "foo %% bar"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(), "foo % bar")
        XCTAssertEqual(try formatString.print(), String(format: string))
    }

    func testPrintInvertedArguments() throws {
        let string = "%2$@ %1$i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5, "foo"), "foo 5")
        XCTAssertEqual(try formatString.print(5, "foo"), String(format: string, 5, "foo"))
    }

    func testPrintInt() throws {
        let string = "%i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5), "5")
        XCTAssertEqual(try formatString.print(5), String(format: string, 5))
    }

    func testPrintNegativeInt() throws {
        let string = "%i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(-5), "-5")
        XCTAssertEqual(try formatString.print(-5), String(format: string, -5))
    }

    func testPrintInt32Max() throws {
        let string = "%i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(Int32.max), "2147483647")
        XCTAssertEqual(try formatString.print(Int32.max), String(format: string, Int32.max))
    }

    func testPrintIntMax() throws {
        let string = "%i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(Int.max), "9223372036854775807")
        XCTAssertEqual(try formatString.print(Int.max), String(format: "%zi", Int.max))
    }

    func testPrintZeroAsInt() throws {
        let string = "%i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(0), "0")
        XCTAssertEqual(try formatString.print(0), String(format: string, 0))
    }

    func testPrintDecimal() throws {
        let string = "%d"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5), "5")
        XCTAssertEqual(try formatString.print(5), String(format: string, 5))
    }

    func testPrintDecimalIntMax() throws {
        let string = "%d"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(Int.max), "9223372036854775807")
        XCTAssertEqual(try formatString.print(Int.max), String(format: "%zd", Int.max))
    }

    func testPrintUppercaseDecimal() throws {
        let string = "%D"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5), "5")
        XCTAssertEqual(try formatString.print(5), String(format: string, 5))
    }

    func testPrintUppercaseDecimalIntMax() throws {
        let string = "%D"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(Int.max), "9223372036854775807")
        XCTAssertEqual(try formatString.print(Int.max), String(format: "%zD", Int.max))
    }

    func testPrintUnsignedInt() throws {
        let string = "%u"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(UInt(5)), "5")
        XCTAssertEqual(try formatString.print(UInt(5)), String(format: string, 5))
    }

    func testPrintUnsignedIntMax() throws {
        let string = "%u"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(UInt.max), "18446744073709551615")
        XCTAssertEqual(try formatString.print(UInt.max), String(format: "%tu", UInt.max))
    }

    func testPrintUppercaseUnsignedInt() throws {
        let string = "%U"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(UInt(5)), "5")
        XCTAssertEqual(try formatString.print(UInt(5)), String(format: string, 5))
    }

    func testPrintUppercaseUnsignedIntMax() throws {
        let string = "%U"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(UInt.max), "18446744073709551615")
        XCTAssertEqual(try formatString.print(UInt.max), String(format: "%tU", UInt.max))
    }

    func testPrintHex() throws {
        let string = "%x"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(0x123ABC), "123abc")
        XCTAssertEqual(try formatString.print(0x123ABC), String(format: string, 0x123ABC))
    }

    func testPrintHexIntMax() throws {
        let string = "%x"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(Int.max), "7fffffffffffffff")
        XCTAssertEqual(try formatString.print(Int.max), String(format: "%tx", Int.max))
    }

    func testPrintUppercaseHex() throws {
        let string = "%X"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(0x123ABC), "123ABC")
        XCTAssertEqual(try formatString.print(0x123ABC), String(format: string, 0x123ABC))
    }

    func testPrintUppercaseHexIntMax() throws {
        let string = "%X"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(Int.max), "7FFFFFFFFFFFFFFF")
        XCTAssertEqual(try formatString.print(Int.max), String(format: "%tX", Int.max))
    }

    func testPrintOctal() throws {
        let string = "%o"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(0o123456), "123456")
        XCTAssertEqual(try formatString.print(0o123456), String(format: string, 0o123456))
    }

    func testPrintOctalIntMax() throws {
        let string = "%o"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(Int.max), "777777777777777777777")
        XCTAssertEqual(try formatString.print(Int.max), String(format: "%to", Int.max))
    }

    func testPrintUppercaseOctal() throws {
        let string = "%O"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(0o123456), "123456")
        XCTAssertEqual(try formatString.print(0o123456), String(format: string, 0o123456))
    }

    func testPrintUppercaseOctalIntMax() throws {
        let string = "%O"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(Int.max), "777777777777777777777")
        XCTAssertEqual(try formatString.print(Int.max), String(format: "%tO", Int.max))
    }

    func testPrintFloat() throws {
        let string = "%f"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(0.53), "0.530000")
        XCTAssertEqual(try formatString.print(0.53), String(format: string, 0.53))
    }

    func testPrintUppercaseFloat() throws {
        let string = "%F"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(0.53), "0.530000")
        XCTAssertEqual(try formatString.print(0.53), String(format: string, 0.53))
    }

    func testPrintZeroAsFloat() throws {
        let string = "%f"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(0), "0.000000")
        XCTAssertEqual(try formatString.print(0), String(format: string, 0))
    }

    func testPrintPiAsFloat() throws {
        let string = "%f"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(Double.pi), "3.141593")
        XCTAssertEqual(try formatString.print(Double.pi), String(format: string, Double.pi))
    }

    func testPrintInfinityAsFloat() throws {
        let string = "%f"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(Double.infinity), "inf")
        XCTAssertEqual(try formatString.print(Double.infinity), String(format: string, Double.infinity))
    }

    func testPrintNegativeInfinityAsFloat() throws {
        let string = "%f"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(-Double.infinity), "-inf")
        XCTAssertEqual(try formatString.print(-Double.infinity), String(format: string, -Double.infinity))
    }

    func testPrintVariablePrecisionFloat() throws {
        let string = "%g"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(0.53), "0.53")
        XCTAssertEqual(try formatString.print(0.53), String(format: string, 0.53))
    }

    func testPrintZeroAsVariablePrecisionFloat() throws {
        let string = "%g"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(0), "0")
        XCTAssertEqual(try formatString.print(0), String(format: string, 0))
    }

    func testPrintPiAsVariablePrecisionFloat() throws {
        let string = "%g"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(Double.pi), "3.14159")
        XCTAssertEqual(try formatString.print(Double.pi), String(format: string, Double.pi))
    }

    func testPrintInfinityAsVariablePrecisionFloat() throws {
        let string = "%g"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(Double.infinity), "inf")
        XCTAssertEqual(try formatString.print(Double.infinity), String(format: string, Double.infinity))
    }

    func testPrintUppercaseInfinityAsVariablePrecisionFloat() throws {
        let string = "%G"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(Double.infinity), "INF")
        XCTAssertEqual(try formatString.print(Double.infinity), String(format: string, Double.infinity))
    }

    func testPrintNegativeInfinityAsVariablePrecisionFloat() throws {
        let string = "%g"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(-Double.infinity), "-inf")
        XCTAssertEqual(try formatString.print(-Double.infinity), String(format: string, -Double.infinity))
    }

    func testPrintExponentialFloat() throws {
        let string = "%e"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(0.53), "5.300000e-01")
        XCTAssertEqual(try formatString.print(0.53), String(format: string, 0.53))
    }

    func testPrintUppercaseExponentialFloat() throws {
        let string = "%E"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(0.53), "5.300000E-01")
        XCTAssertEqual(try formatString.print(0.53), String(format: string, 0.53))
    }

    func testPrintHexFloat() throws {
        let string = "%a"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(16.32), "0x1.051eb851eb852p+4")
        XCTAssertEqual(try formatString.print(16.32), String(format: string, 16.32))
    }

    func testPrintUppercaseHexFloat() throws {
        let string = "%A"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(0.53), "0X1.0F5C28F5C28F6P-1")
        XCTAssertEqual(try formatString.print(0.53), String(format: string, 0.53))
    }

    func testPrintObjectPointer() throws {
        let string = "%p"
        let formatString = try FormatString(string)
        let object = NSObject()
        XCTAssertEqual(try formatString.print(object), String(format: "%p", object))
    }

    func testPrintChar() throws {
        let string = "%c"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print("a"), "a")
        XCTAssertEqual(try formatString.print("a"), String(format: string, UnicodeScalar("a")!.value))
    }

    func testPrintUnicodeChar() throws {
        let string = "%c"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print("🔥"), "🔥")
    }

    func testPrintWideChar() throws {
        let string = "%C"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print("ü"), "ü")
        XCTAssertEqual(try formatString.print("ü"), String(format: string, UnicodeScalar("ü")!.value))
    }

    func testPrintUnicodeWideChar() throws {
        let string = "%C"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print("🔥"), "🔥")
    }

    func testPrintString() throws {
        let string = "%s"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print("Hello World"), "Hello World")
    }

    func testPrintUnicodeString() throws {
        let string = "%s"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print("🤔👌"), "🤔👌")
    }

    func testPrintWideString() throws {
        let string = "%S"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print("ËØËÔÌË"), "ËØËÔÌË")
    }

    func testPrintUnicodeWideString() throws {
        let string = "%S"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print("🤔👌"), "🤔👌")
    }

    // MARK: field width

    func testPrintIntWithFieldWidth() throws {
        let string = "%5i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5), "    5")
        XCTAssertEqual(try formatString.print(5), String(format: string, 5))
    }

    func testPrintIntWithZeroFieldWidth() throws {
        let string = "%0i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5), "5")
        XCTAssertEqual(try formatString.print(5), String(format: string, 5))
    }

    func testPrintInt32MaxWithFieldWidth() throws {
        let string = "%5i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(Int32.max), "2147483647")
        XCTAssertEqual(try formatString.print(Int32.max), String(format: string, Int32.max))
    }

    func testPrintFloatWithFieldWidth() throws {
        let string = "%10f"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(0.53), "  0.530000")
        XCTAssertEqual(try formatString.print(0.53), String(format: string, 0.53))
    }

    func testPrintPiAsVariablePrecisionFloatWithFieldWidth() throws {
        let string = "%10g"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(Double.pi), "   3.14159")
        XCTAssertEqual(try formatString.print(Double.pi), String(format: string, Double.pi))
    }

    func testParameterizedFieldWidth() throws {
        let string = "%*i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5, 10), "   10")
        XCTAssertEqual(try formatString.print(5, 10), String(format: string, 5, 10))
    }

    func testParameterizedFieldWidth2() throws {
        let string = "%2$*i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5, 10), "   10")
        XCTAssertEqual(try formatString.print(5, 10), String(format: string, 5, 10))
    }

    func testParameterizedFieldWidth3() throws {
        let string = "%*2$x"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(10, 5), "    a")
        XCTAssertEqual(try formatString.print(10, 5), String(format: string, 10, 5))
    }

    func testParameterizedFieldWidth4() throws {
        let string = "%1$*2$g"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(10, 5), "   10")
        XCTAssertEqual(try formatString.print(10, 5), String(format: string, 10.0, 5))
    }

    // MARK: precision

    func testPrintIntWithPrecision() throws {
        let string = "%.5i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5), "00005")
        XCTAssertEqual(try formatString.print(5), String(format: string, 5))
    }

    func testPrintIntWithZeroPrecision() throws {
        let string = "%.0i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5), "5")
        XCTAssertEqual(try formatString.print(5), String(format: string, 5))
    }

    func testPrintIntWithEmptyPrecision() throws {
        let string = "%.i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5), "5")
        XCTAssertEqual(try formatString.print(5), String(format: string, 5))
    }

    func testPrintInt32MaxWithPrecision() throws {
        let string = "%.5i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(Int32.max), "2147483647")
        XCTAssertEqual(try formatString.print(Int32.max), String(format: string, Int32.max))
    }

    func testPrintFloatWithPrecision() throws {
        let string = "%.1f"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(0.53), "0.5")
        XCTAssertEqual(try formatString.print(0.53), String(format: string, 0.53))
    }

    func testPrintFloatWithZeroPrecision() throws {
        let string = "%.0f"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(0.53), "1")
        XCTAssertEqual(try formatString.print(0.53), String(format: string, 0.53))
    }

    func testPrintFloatWithEmptyPrecision() throws {
        let string = "%.f"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(0.53), "1")
        XCTAssertEqual(try formatString.print(0.53), String(format: string, 0.53))
    }

    func testPrintPiAsFloatWithPrecision() throws {
        let string = "%.2f"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(Double.pi), "3.14")
        XCTAssertEqual(try formatString.print(Double.pi), String(format: string, Double.pi))
    }

    func testPrintVariablePrecisionFloatWithPrecision() throws {
        let string = "%.1g"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(0.53), "0.5")
        XCTAssertEqual(try formatString.print(0.53), String(format: string, 0.53))
    }

    func testPrintPiAsVariablePrecisionFloatWithPrecision() throws {
        let string = "%.2g"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(Double.pi), "3.1")
        XCTAssertEqual(try formatString.print(Double.pi), String(format: string, Double.pi))
    }

    func testPrintHexWithPrecision() throws {
        let string = "%.4x"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(10), "000a")
        XCTAssertEqual(try formatString.print(10), String(format: string, 10))
    }

    func testPrintHexWithZeroPrecision() throws {
        let string = "%.0X"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(10), "A")
        XCTAssertEqual(try formatString.print(10), String(format: string, 10))
    }

    func testPrintHexWithEmptyPrecision() throws {
        let string = "%.x"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(10), "a")
        XCTAssertEqual(try formatString.print(10), String(format: string, 10))
    }

    func testPrintOctalWithPrecision() throws {
        let string = "%.3o"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(7), "007")
        XCTAssertEqual(try formatString.print(7), String(format: string, 7))
    }

    func testPrintOctalWithZeroPrecision() throws {
        let string = "%.0O"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(7), "7")
        XCTAssertEqual(try formatString.print(7), String(format: string, 7))
    }

    func testPrintFloat80() throws {
        let string = "%Lf" // TODO: support other formatting options
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(Float80(7.0)), "7.0")
    }

    func testParameterizedPrecision() throws {
        let string = "%.*X"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5, 10), "0000A")
        XCTAssertEqual(try formatString.print(5, 10), String(format: string, 5, 10))
    }

    func testParameterizedPrecision2() throws {
        let string = "%.*2$g"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(10.123, 3), "10.1")
        XCTAssertEqual(try formatString.print(10.123, 3), String(format: string, 10.123, 3))
    }

    func testParameterizedFieldWidthAndPrecision() throws {
        let string = "%*2$.*3$i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(10, 5, 3), "  010")
        XCTAssertEqual(try formatString.print(10, 5, 3), String(format: string, 10, 5, 3))
    }

    func testParameterizedFieldWidthAndPrecision2() throws {
        let string = "%*2$.*3$x"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(10, 5, 3), "  00a")
        XCTAssertEqual(try formatString.print(10, 5, 3), String(format: string, 10, 5, 3))
    }

    func testParameterizedFieldWidthAndPrecision3() throws {
        let string = "%*2$.*3$g"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(10, 5, 3), "   10")
        XCTAssertEqual(try formatString.print(10, 5, 3), String(format: string, 10.0, 5, 3))
    }

    // MARK: flags

    func testPrintIntWithGrouping() throws {
        let string = "%'i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5000), "5,000")
    }

    func testPrintFloatWithGrouping() throws {
        let string = "%'f"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5000.123), "5,000.123000")
    }

    func testParameterizedFieldWidthWithGrouping() throws {
        let string = "%'*2$.3g"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(1000, 6), " 1,000")
    }

    func testParameterizedPrecisionWithGrouping() throws {
        let string = "%'6.*2$g"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(1000, 3), " 1,000")
    }

    func testPrintVariablePrecisionFloatWithGrouping() throws {
        let string = "%'g"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5000.123), "5,000.12")
    }

    func testPrintIntWithLeftJustification() throws {
        let string = "%-5i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(32), "32   ")
        XCTAssertEqual(try formatString.print(32), String(format: string, 32))
    }

    func testPrintIntWithLeadingPlus() throws {
        let string = "%+i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5), "+5")
        XCTAssertEqual(try formatString.print(5), String(format: string, 5))
    }

    func testPrintIntWithLeadingPlusAndGrouping() throws {
        let string = "%'+i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5000), "+5,000")
    }

    func testPrintNegativeIntWithLeadingPlus() throws {
        let string = "%+i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(-5), "-5")
        XCTAssertEqual(try formatString.print(-5), String(format: string, -5))
    }

    func testPrintIntWithLeadingSpace() throws {
        let string = "% i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5), " 5")
        XCTAssertEqual(try formatString.print(5), String(format: string, 5))
    }

    func testPrintIntWithLeadingSpaceAndGrouping() throws {
        let string = "%' i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5000), " 5,000")
    }

    func testPrintIntWithLeadingSpaceAndPlus() throws {
        let string = "%+ i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5), "+5")
        XCTAssertEqual(try formatString.print(5), String(format: string, 5))
    }

    func testPrintOctalWithZeroPrefix() throws {
        let string = "%#o"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(7), "07")
        XCTAssertEqual(try formatString.print(7), String(format: string, 7))
    }

    func testPrintHexWithOxPrefix() throws {
        let string = "%#x"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(10), "0xa")
        XCTAssertEqual(try formatString.print(10), String(format: string, 10))
    }

    func testPrintFloatWithTrailingRadix() throws {
        let string = "%#.f"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5), "5.")
        XCTAssertEqual(try formatString.print(5), String(format: string, 5.0))
    }

    func testPrintHexFloatWithTrailingRadix() throws {
        let string = "%#A"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(16), "0X1.P+4")
        XCTAssertEqual(try formatString.print(16), String(format: string, 16.0))
    }

    func testPrintVariablePrecisionFloatWithTrailingZeros() throws {
        let string = "%#g"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5.23), "5.23000")
        XCTAssertEqual(try formatString.print(5.23), String(format: string, 5.23))
    }

    func testPrintIntWithZeroPadding() throws {
        let string = "%05i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5), "00005")
        XCTAssertEqual(try formatString.print(5), String(format: string, 5))
    }

    func testPrintFloatWithZeroPadding() throws {
        let string = "%05.1f"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5.23), "005.2")
        XCTAssertEqual(try formatString.print(5.23), String(format: string, 5.23))
    }

    func testPrintVariablePrecisionFloatWithZeroPadding() throws {
        let string = "%05g"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5.23), "05.23")
        XCTAssertEqual(try formatString.print(5.23), String(format: string, 5.23))
    }

    func testPrintLeftAlignedIntWithZeroPadding() throws {
        let string = "%-05i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5), "5    ")
        XCTAssertEqual(try formatString.print(5), String(format: string, 5))
    }

    func testPrintLeftAlignedIntWithZeroPaddingAndGrouping() throws {
        let string = "%'-06i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5000), "5,000 ")
    }

    func testPrintIntWithZeroPaddingAndGrouping() throws {
        let string = "%0'5i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5000), "5,000")
    }

    func testPrintFloatWithZeroPaddingAndGrouping() throws {
        let string = "%'015f"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(1000), "0001,000.000000")
    }

    func testPrintVAriablePrecisionFloatWithZeroPaddingAndGrouping() throws {
        let string = "%'0g"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(1000), "1,000")
    }

    func testParameterizedFieldWidthWithZeroPaddingAndGrouping() throws {
        let string = "%0'*2$.3g"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(1000, 6), "01,000")
    }

    func testParameterizedPrecisionWithZeroPaddingAndGrouping() throws {
        let string = "%0'6.*2$g"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(1000, 3), "01,000")
    }

    func testPrintFloatWithZeroPaddingAndTrailingRadix() throws {
        let string = "%0#5.f"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5), "0005.")
        XCTAssertEqual(try formatString.print(5), String(format: string, 5.0))
    }

    func testPrintAltVariablePrecisionFloatWithZeroPadding() throws {
        let string = "%#06.4g"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5.23), "05.230")
        XCTAssertEqual(try formatString.print(5.23), String(format: string, 5.23))
    }

    func testPrintAltVariablePrecisionFloatWithZeroPaddingAndGrouping() throws {
        let string = "%'#011g"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(5000.23), "0005,000.23")
    }

    // MARK: print function arguments

    func testPrintArgumentsArray() throws {
        let string = "%2$@ %1$i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(arguments: [5, "foo"]), "foo 5")
    }

    func testPrintInferredArgumentsArray() throws {
        let string = "%2$@ %1$i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print([5, "foo"]), "foo 5")
    }

    func testPrintTooFewArguments() throws {
        let string = "%2$@ %1$i"
        let formatString = try FormatString(string)
        XCTAssertThrowsError(try formatString.print(5)) { error in
            XCTAssertEqual(error as? FormatString.Error, .missingArgument(2))
        }
    }

    // MARK: test localization

    func testPrintGroupedFloatWithFrenchLocale() throws {
        let string = "%'g"
        let locale = Locale(identifier: "fr-FR")
        let formatString = try FormatString(string, locale: locale)
        XCTAssertEqual(try formatString.print(5000.34), "5 000,34")
    }

    func testPrintGroupedFloatWithGermanLocale() throws {
        let string = "%'g"
        let locale = Locale(identifier: "de-DE")
        let formatString = try FormatString(string, locale: locale)
        XCTAssertEqual(try formatString.print(5000.34), "5.000,34")
    }

    func testPrintInfinityWithGermanLocale() throws {
        let string = "%f"
        let locale = Locale(identifier: "de-DE")
        let formatString = try FormatString(string, locale: locale)
        XCTAssertEqual(try formatString.print(Double.infinity), "∞")
        XCTAssertEqual(try formatString.print(Double.infinity), String(format: string, locale: locale, Double.infinity))
    }

    func testPrintInfinityWithBritishLocale() throws {
        let string = "%f"
        let locale = Locale(identifier: "en-GB")
        let formatString = try FormatString(string, locale: locale)
        XCTAssertEqual(try formatString.print(Double.infinity), "∞")
        XCTAssertEqual(try formatString.print(Double.infinity), String(format: string, locale: locale, Double.infinity))
    }

    func testPrintInfinityWithJapaneseLocale() throws {
        let string = "%f"
        let locale = Locale(identifier: "ja-JP")
        let formatString = try FormatString(string, locale: locale)
        XCTAssertEqual(try formatString.print(Double.infinity), "∞")
        XCTAssertEqual(try formatString.print(Double.infinity), String(format: string, locale: locale, Double.infinity))
    }

    // MARK: type promotions

    func testIntPromotions() throws {
        let string = "%i"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(Int32(5)), "5")
        XCTAssertEqual(try formatString.print(Int16(5)), "5")
        XCTAssertEqual(try formatString.print(UInt16(5)), "5")
        XCTAssertEqual(try formatString.print(Int8(5)), "5")
        XCTAssertEqual(try formatString.print(UInt8(5)), "5")
        XCTAssertThrowsError(try formatString.print(UInt(5)))
        XCTAssertThrowsError(try formatString.print(UInt32(5)))
        XCTAssertThrowsError(try formatString.print(Int64(5)))
        XCTAssertThrowsError(try formatString.print(UInt64(5)))
        XCTAssertThrowsError(try formatString.print(5.0))
        XCTAssertThrowsError(try formatString.print("foo"))
    }

    func testDoublePromotions() throws {
        let string = "%g"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print(Int(5)), "5")
        XCTAssertEqual(try formatString.print(UInt(5)), "5")
        XCTAssertEqual(try formatString.print(Int64(5)), "5")
        XCTAssertEqual(try formatString.print(UInt64(5)), "5")
        XCTAssertEqual(try formatString.print(Int32(5)), "5")
        XCTAssertEqual(try formatString.print(UInt32(5)), "5")
        XCTAssertEqual(try formatString.print(Int16(5)), "5")
        XCTAssertEqual(try formatString.print(UInt16(5)), "5")
        XCTAssertEqual(try formatString.print(Int8(5)), "5")
        XCTAssertEqual(try formatString.print(UInt8(5)), "5")
        XCTAssertEqual(try formatString.print(Float(5)), "5")
        XCTAssertThrowsError(try formatString.print(Float80(5.0)))
        XCTAssertThrowsError(try formatString.print("foo"))
    }

    func testCharacterPromotions() throws {
        let string = "%c"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print("a"), "a")
        XCTAssertEqual(try formatString.print(Character("a")), "a")
        XCTAssertEqual(try formatString.print("a" as UnicodeScalar), "a")
        XCTAssertEqual(try formatString.print(("a" as UnicodeScalar).value), "a")
        XCTAssertEqual(try formatString.print(Int(("a" as UnicodeScalar).value)), "a")
        XCTAssertEqual(try formatString.print(UInt16(("a" as UnicodeScalar).value)), "a")
        XCTAssertEqual(try formatString.print(UInt8(("a" as UnicodeScalar).value)), "a")
        XCTAssertEqual(try formatString.print(CChar(("a" as UnicodeScalar).value)), "a")
        XCTAssertThrowsError(try formatString.print(UInt64(("a" as UnicodeScalar).value)))
    }

    func testStringPromotions() throws {
        let string = "%s"
        let formatString = try FormatString(string)
        XCTAssertEqual(try formatString.print("abc"), "abc")
        XCTAssertEqual(try formatString.print("abc" as NSString), "abc")
    }
}
