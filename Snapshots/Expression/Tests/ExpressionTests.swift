//
//  ExpressionTests.swift
//  ExpressionTests
//
//  Created by Nick Lockwood on 15/09/2016.
//  Copyright © 2016 Nick Lockwood. All rights reserved.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/Expression
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import XCTest
@testable import Expression

class ExpressionTests: XCTestCase {
    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS)
            let thisClass = type(of: self)
            let linuxCount = thisClass.__allTests.count
            let darwinCount = thisClass.defaultTestSuite.testCaseCount
            XCTAssertEqual(linuxCount, darwinCount, "run swift test --generate-linuxmain")
        #endif
    }

    // MARK: Description

    func testDescriptionSpacing() {
        let expression = Expression("a+b")
        XCTAssertEqual(expression.description, "a + b")
    }

    func testDescriptionParensAdded() {
        let expression = Expression("a+b*c")
        XCTAssertEqual(expression.description, "a + b * c")
    }

    func testDescriptionParensPreserved() {
        let expression = Expression("a*(b+c)")
        XCTAssertEqual(expression.description, "a * (b + c)")
    }

    func testDescriptionParensPreserved2() {
        let expression = Expression("(a+b)*c")
        XCTAssertEqual(expression.description, "(a + b) * c")
    }

    func testDescriptionRedundantParensDiscarded() {
        let expression = Expression("(a+b)+c")
        XCTAssertEqual(expression.description, "a + b + c")
    }

    func testIntExpressionDescription() {
        let expression = Expression("32 + 200014")
        XCTAssertEqual(expression.description, "200046")
    }

    func testFloatExpressionDescription() {
        let expression = Expression("2.4 + 7.65")
        XCTAssertEqual(expression.description, "10.05")
    }

    func testPrefixOperatorDescription() {
        let expression = Expression("-foo")
        XCTAssertEqual(expression.description, "-foo")
    }

    func testPrefixOperatorInsidePostfixExpressionDescription() {
        let expression = Expression("(-foo)%")
        XCTAssertEqual(expression.description, "-foo%")
    }

    func testInfixOperatorInsidePrefixExpressionDescription() {
        let expression = Expression("-(a+b)")
        XCTAssertEqual(expression.description, "-(a + b)")
    }

    func testPrefixRangeFollowedByLessThan() {
        let expression = Expression("...(<5)")
        XCTAssertEqual(expression.description, "...(<5)")
    }

    func testNestedPrefixOperatorDescription() {
        let expression = Expression("- -foo")
        XCTAssertEqual(expression.description, "-(-foo)")
    }

    func testPostfixOperatorDescription() {
        let expression = Expression("foo%")
        XCTAssertEqual(expression.description, "foo%")
    }

    func testNestedPostfixOperatorDescription() {
        let expression = Expression("foo% !")
        XCTAssertEqual(expression.description, "(foo%)!")
    }

    func testPostfixOperatorInsidePrefixExpressionDescription() {
        let expression = Expression("-(foo%)")
        XCTAssertEqual(expression.description, "-(foo%)")
    }

    func testInfixOperatorInsidePostfixExpressionDescription() {
        let expression = Expression("(a+b)%")
        XCTAssertEqual(expression.description, "(a + b)%")
    }

    func testPostfixOperatorInsideInfixExpressionDescription() {
        let expression = Expression("foo% + 5")
        XCTAssertEqual(expression.description, "foo% + 5")
    }

    func testPostfixAlphanumericOperatorDescription() {
        let expression = Expression("5ms")
        XCTAssertEqual(expression.description, "5ms")
    }

    func testPostfixAlphanumericOperatorDescription2() {
        let expression = Expression("foo ms")
        XCTAssertEqual(expression.description, "(foo)ms")
    }

    func testPostfixAlphanumericOperatorInsidePrefixExpressionDescription() {
        let expression = Expression("-foo ms")
        XCTAssertEqual(expression.description, "(-foo)ms")
    }

    func testInfixAlphanumericOperatorDescription() {
        let expression = Expression("foo or bar")
        XCTAssertEqual(expression.description, "foo or bar")
    }

    func testNestedPostfixAlphanumericOperatorsDescription() {
        let expression = Expression("(foo bar) baz")
        XCTAssertEqual(expression.description, "((foo)bar)baz")
    }

    func testRightAssociativeOperatorsDescription() {
        let expression = Expression("(a = b) = c")
        XCTAssertEqual(expression.description, "(a = b) = c")
    }

    func testRightAssociativeOperatorsDescription2() {
        let expression = Expression("a == b > c")
        XCTAssertEqual(expression.description, "a == b > c")
    }

    func testInfixDotOperatorDescription() {
        let expression = Expression("(foo).(bar)")
        XCTAssertEqual(expression.description, "foo . bar")
    }

    func testPrefixDotOperatorDescription() {
        let expression = Expression(".(foo)")
        XCTAssertEqual(expression.description, ".(foo)")
    }

    func testCommaSpacingDescription() {
        let expression = Expression("a,b")
        XCTAssertEqual(expression.description, "a, b")
    }

    func testCommaSpacingAfterOperatorDescription() {
        let expression = Expression("a % , b")
        XCTAssertEqual(expression.description, "a%, b")
    }

    func testErrorDescription() {
        let expression = Expression("0x")
        XCTAssertEqual(expression.description, "0x")
    }

    func testEscapedVariableDescription() {
        let expression = Expression.parse("`hello\\tworld`")
        XCTAssertEqual(expression.description, "`hello\\tworld`")
    }

    func testEscapedFunctionDescription() {
        let expression = Expression.parse("`hello\\tworld`(x)")
        XCTAssertEqual(expression.description, "`hello\\tworld`(x)")
    }

    func testEscapedPostfixOperatorDescription() {
        let expression = Expression.parse("5`metric\\ttonnes`")
        XCTAssertEqual(expression.description, "5`metric\\ttonnes`")
    }

    func testEscapedPostfixOperatorChainDescription() {
        let expression = Expression.parse("(5foo)`bar\\tbaz`")
        XCTAssertEqual(expression.description, "(5foo)`bar\\tbaz`")
    }

    func testSumOfTuplesDescription() {
        let expression = Expression.parse("(3,4) + (5,6)")
        XCTAssertEqual(expression.description, "(3, 4) + (5, 6)")
    }

    func testFunctionWithTupleArgumentDescription() {
        let expression = Expression.parse("foo((5,6))")
        XCTAssertEqual(expression.description, "foo((5, 6))")
    }

    func testFunctionWithMultipleTupleArgumentsDescription() {
        let expression = Expression.parse("foo((3,4),(5,6))")
        XCTAssertEqual(expression.description, "foo((3, 4), (5, 6))")
    }

    func testArrayWithTupleArgumentDescription() {
        let expression = Expression.parse("foo[(5,6)]")
        XCTAssertEqual(expression.description, "foo[(5, 6)]")
    }

    func testArrayLiteralDescription() {
        let expression = Expression.parse("[1,2,3]")
        XCTAssertEqual(expression.description, "[1, 2, 3]")
    }

    func testArrayOperatorDescription() {
        let expression = Expression.parse("3 * 3[4] + 2")
        XCTAssertEqual(expression.description, "3 * 3[4] + 2")
    }

    func testArrayOperatorDescription2() {
        let expression = Expression.parse("3 * 3[4 * 2] + 3")
        XCTAssertEqual(expression.description, "3 * 3[4 * 2] + 3")
    }

    // MARK: Error description

    func testCustomErrorDescription() {
        let error = Expression.Error.message("foo")
        XCTAssertEqual(error.description, "foo")
    }

    func testEmptyExpressionErrorDescription() {
        let error = Expression.Error.emptyExpression
        XCTAssertEqual(error.description, "Empty expression")
    }

    func testUnexpectedTokenErrorDescription() {
        let error = Expression.Error.unexpectedToken(")")
        XCTAssertEqual(error.description, "Unexpected token `)`")
    }

    func testMissingDelimiterErrorDescription() {
        let error = Expression.Error.missingDelimiter("]")
        XCTAssertEqual(error.description, "Missing `]`")
    }

    func testMissingUndefinedSymbolErrorDescription() {
        let error = Expression.Error.undefinedSymbol(.postfix("foo"))
        XCTAssertEqual(error.description, "Undefined postfix operator foo")
    }

    func testArrayArityMismatchErrorDescription() {
        let error = Expression.Error.arityMismatch(.array("foo"))
        XCTAssertEqual(error.description, "Array foo[] expects 1 argument")
    }

    func testZeroFunctionArityMismatchErrorDescription() {
        let error = Expression.Error.arityMismatch(.function("foo", arity: 0))
        XCTAssertEqual(error.description, "Function foo() expects 0 arguments")
    }

    func testUnaryFunctionArityMismatchErrorDescription() {
        let error = Expression.Error.arityMismatch(.function("foo", arity: 1))
        XCTAssertEqual(error.description, "Function foo() expects 1 argument")
    }

    func testBinaryFunctionArityMismatchErrorDescription() {
        let error = Expression.Error.arityMismatch(.function("foo", arity: 2))
        XCTAssertEqual(error.description, "Function foo() expects 2 arguments")
    }

    func testVariadicFunctionArityMismatchErrorDescription() {
        let error = Expression.Error.arityMismatch(.function("foo", arity: .atLeast(1)))
        XCTAssertEqual(error.description, "Function foo() expects at least 1 argument")
    }

    func testVariadicFunctionArityMismatchErrorDescription2() {
        let error = Expression.Error.arityMismatch(.function("foo", arity: .atLeast(2)))
        XCTAssertEqual(error.description, "Function foo() expects at least 2 arguments")
    }

    func testInfixOperatorArityMismatchErrorDescription() {
        let error = Expression.Error.arityMismatch(.infix("foo"))
        XCTAssertEqual(error.description, "Infix operator foo expects 2 arguments")
    }

    func testTernaryOperatorArityMismatchErrorDescription() {
        let error = Expression.Error.arityMismatch(.infix("?:"))
        XCTAssertEqual(error.description, "Ternary operator ?: expects 3 arguments")
    }

    func testSubscriptOperatorArityMismatchErrorDescription() {
        let error = Expression.Error.arityMismatch(.infix("[]"))
        XCTAssertEqual(error.description, "Subscript operator [] expects 1 argument")
    }

    func testFunctionCallOperatorArityMismatchErrorDescription() {
        let error = Expression.Error.arityMismatch(.infix("()"))
        XCTAssertEqual(error.description, "Function call operator () expects at least 1 argument")
    }

    func testPostfixOperatorArityMismatchErrorDescription() {
        let error = Expression.Error.arityMismatch(.postfix("foo"))
        XCTAssertEqual(error.description, "Postfix operator foo expects 1 argument")
    }

    func testPrefixOperatorArityMismatchErrorDescription() {
        let error = Expression.Error.arityMismatch(.prefix("foo"))
        XCTAssertEqual(error.description, "Prefix operator foo expects 1 argument")
    }

    func testVariableArityMismatchErrorDescription() {
        let error = Expression.Error.arityMismatch(.variable("foo"))
        XCTAssertEqual(error.description, "Variable foo expects 0 arguments")
    }

    func testEmptySymbolArityErrorDescription() {
        // TODO: is this the correct behavior?
        let error = Expression.Error.arityMismatch(.variable(""))
        XCTAssertEqual(error.description, "Variable  expects 0 arguments")
    }

    func testArrayBoundsErrorDescription() {
        let error = Expression.Error.arrayBounds(.array("foo"), 5)
        XCTAssertEqual(error.description, "Index 5 out of bounds for array foo[]")
    }

    // MARK: Error equatability

    func testMessageErrorEquality() {
        let error = Expression.Error.message("foo")
        XCTAssertEqual(error, error)
        XCTAssertNotEqual(error, .message("bar"))
        XCTAssertNotEqual(error, .unexpectedToken("foo"))
    }

    func testUnexpectedTokenErrorEquality() {
        let error = Expression.Error.unexpectedToken(")")
        XCTAssertEqual(error, error)
        XCTAssertNotEqual(error, .unexpectedToken("]"))
        XCTAssertNotEqual(error, .missingDelimiter(")"))
    }

    func testMissingDelimiterErrorEquality() {
        let error = Expression.Error.missingDelimiter("]")
        XCTAssertEqual(error, error)
        XCTAssertNotEqual(error, .missingDelimiter(")"))
        XCTAssertNotEqual(error, .unexpectedToken("]"))
    }

    func testUndefinedSymbolErrorEquality() {
        let error = Expression.Error.undefinedSymbol(.array("foo"))
        XCTAssertEqual(error, error)
        XCTAssertNotEqual(error, .undefinedSymbol(.array("bar")))
        XCTAssertNotEqual(error, .undefinedSymbol(.variable("foo")))
        XCTAssertNotEqual(error, .arityMismatch(.array("foo")))
    }

    func testArityMismatchErrorEquality() {
        let error = Expression.Error.arityMismatch(.function("foo", arity: 1))
        XCTAssertEqual(error, error)
        XCTAssertNotEqual(error, .arityMismatch(.function("foo", arity: 2)))
        XCTAssertNotEqual(error, .arityMismatch(.function("bar", arity: 1)))
        XCTAssertNotEqual(error, .arityMismatch(.array("foo")))
        XCTAssertNotEqual(error, .undefinedSymbol(.array("bar")))
    }

    func testArrayBoundsErrorEquality() {
        let error = Expression.Error.arrayBounds(.array("foo"), 2)
        XCTAssertNotEqual(error, .arrayBounds(.array("foo"), 3))
        XCTAssertNotEqual(error, .arrayBounds(.array("bar"), 2))
        XCTAssertNotEqual(error, .arityMismatch(.array("foo")))
    }

    // MARK: Numbers

    func testZero() {
        let expression = Expression("0")
        XCTAssertEqual(try expression.evaluate(), 0)
    }

    func testSmallInteger() {
        let expression = Expression("5")
        XCTAssertEqual(try expression.evaluate(), 5)
    }

    func testLargeInteger() {
        let expression = Expression("12345678901234567890")
        XCTAssertEqual(try expression.evaluate(), 12345678901234567890)
    }

    func testNegativeInteger() {
        let expression = Expression("-7")
        XCTAssertEqual(try expression.evaluate(), -7)
    }

    func testSmallFloat() {
        let expression = Expression("0.2")
        XCTAssertEqual(try expression.evaluate(), 0.2)
    }

    func testLargeFloat() {
        let expression = Expression("1234.567890")
        XCTAssertEqual(try expression.evaluate(), 1234.567890)
    }

    func testNegativeFloat() {
        let expression = Expression("-0.34")
        XCTAssertEqual(try expression.evaluate(), -0.34)
    }

    func testLeadingDecimalPoint() {
        let expression = Expression(".5")
        XCTAssertEqual(try expression.evaluate(), 0.5)
    }

    func testExponential() {
        let expression = Expression("1234e5")
        XCTAssertEqual(try expression.evaluate(), 1234e5)
    }

    func testPositiveExponential() {
        let expression = Expression("0.123e+4")
        XCTAssertEqual(try expression.evaluate(), 0.123e+4)
    }

    func testNegativeExponential() {
        let expression = Expression("0.123e-4")
        XCTAssertEqual(try expression.evaluate(), 0.123e-4)
    }

    func testCapitalExponential() {
        let expression = Expression("0.123E-4")
        XCTAssertEqual(try expression.evaluate(), 0.123e-4)
    }

    func testInvalidExponential() {
        let expression = Expression("123.e5")
        XCTAssertThrowsError(try expression.evaluate())
    }

    func testLeadingZeros() {
        let expression = Expression("0005")
        XCTAssertEqual(try expression.evaluate(), 0005)
    }

    func testHex() {
        let expression = Expression("0x2A ")
        XCTAssertEqual(try expression.evaluate(), 0x2A)
    }

    // MARK: Quoted identifiers (strings)

    func testDoubleQuotedIdentifier() {
        let expression = Expression.parse("\"foo\" + \"bar\"")
        XCTAssertEqual(expression.symbols, [.variable("\"foo\""), .infix("+"), .variable("\"bar\"")])
    }

    func testSingleQuotedIdentifier() {
        let expression = Expression.parse("'foo' + 'bar'")
        XCTAssertEqual(expression.symbols, [.variable("'foo'"), .infix("+"), .variable("'bar'")])
    }

    func testTrailingSingleQuotes() {
        let expression = Expression.parse("foo' + bar'")
        XCTAssertEqual(expression.symbols, [.variable("foo'"), .infix("+"), .variable("bar'")])
    }

    func testBacktickEscapedIdentifier() {
        let expression = Expression.parse("`foo` + `bar`")
        XCTAssertEqual(expression.symbols, [.variable("`foo`"), .infix("+"), .variable("`bar`")])
    }

    func testBacktickEscapedIdentifierWithEscapedChars() {
        let expression = Expression.parse("`foo\\`bar\\n`")
        XCTAssertEqual(expression.symbols, [.variable("`foo`bar\n`")])
    }

    func testValidateQuotedIdentifierContainingNull() {
        let expression = Expression.parse("'foo\\0bar'")
        XCTAssertEqual(expression.symbols, [.variable("'foo\0bar'")])
        XCTAssertEqual(expression.description, "'foo\\0bar'")
    }

    func testValidateQuotedIdentifierContainingTab() {
        let expression = Expression.parse("'foo\\tbar'")
        XCTAssertEqual(expression.symbols, [.variable("'foo\tbar'")])
        XCTAssertEqual(expression.description, "'foo\\tbar'")
    }

    func testValidateQuotedIdentifierContainingNewline() {
        let expression = Expression.parse("'foo\\nbar'")
        XCTAssertEqual(expression.symbols, [.variable("'foo\nbar'")])
        XCTAssertEqual(expression.description, "'foo\\nbar'")
    }

    func testValidateQuotedIdentifierContainingCarriageReturn() {
        let expression = Expression.parse("'foo\\rbar'")
        XCTAssertEqual(expression.symbols, [.variable("'foo\rbar'")])
        XCTAssertEqual(expression.description, "'foo\\rbar'")
    }

    func testValidateQuotedIdentifierContainingDelete() {
        let expression = Expression.parse("'foo\\u{7F}bar'")
        XCTAssertEqual(expression.symbols, [.variable("'foo\u{7F}bar'")])
        XCTAssertEqual(expression.description, "'foo\\u{7F}bar'")
    }

    func testValidateQuotedIdentifierContainingUnitSeparator() {
        let expression = Expression.parse("'foo\\u{1F}bar'")
        XCTAssertEqual(expression.symbols, [.variable("'foo\u{1F}bar'")])
        XCTAssertEqual(expression.description, "'foo\\u{1F}bar'")
    }

    func testValidateQuotedIdentifierContainingEmoji() {
        let expression = Expression.parse("'foo🤡bar'")
        XCTAssertEqual(expression.symbols, [.variable("'foo🤡bar'")])
        XCTAssertEqual(expression.description, "'foo🤡bar'")
    }

    // MARK: Ambiguous whitespace

    func testPostfixOperatorAsInfix() {
        let expression = Expression.parse("a+ b", usingCache: false)
        XCTAssertEqual(expression.description, "a + b")
    }

    func testPostfixOperatorAsInfix2() {
        let expression = Expression.parse("1+ 2", usingCache: false)
        XCTAssertEqual(expression.description, "1 + 2")
    }

    func testPostfixOperatorAsInfix3() {
        let expression = Expression.parse("a+ (b)", usingCache: false)
        XCTAssertEqual(expression.description, "a + b")
    }

    func testParenthesizedPostfixOperator() {
        let expression = Expression.parse("(a +) b", usingCache: false)
        XCTAssertEqual(expression.description, "(a+)b")
    }

    func testParenthesizedPostfixOperator2() {
        let expression = Expression.parse("(a +) +", usingCache: false)
        XCTAssertEqual(expression.description, "(a+)+")
    }

    func testParenthesizedPrefixOperator() {
        let expression = Expression.parse("+ (+ a)", usingCache: false)
        XCTAssertEqual(expression.description, "+(+a)")
    }

    func testPrefixOperatorAsInfix() {
        let expression = Expression.parse("a +b", usingCache: false)
        XCTAssertEqual(expression.description, "a + b")
    }

    func testPrefixOperatorAsInfix2() {
        let expression = Expression.parse("1 +2", usingCache: false)
        XCTAssertEqual(expression.description, "1 + 2")
    }

    func testSpaceBeforePrefixOperator() {
        let expression = Expression.parse(" -1", usingCache: false)
        XCTAssertEqual(expression.description, "-1")
    }

    func testSpaceAroundPrefixOperator() {
        let expression = Expression.parse(" - 1", usingCache: false)
        XCTAssertEqual(expression.description, "-1")
    }

    func testSpaceBeforeInfixExpression() {
        let expression = Expression.parse(" 1 + 2", usingCache: false)
        XCTAssertEqual(expression.description, "1 + 2")
    }

    func testPlusFollowedByDecimalPoint() {
        let expression = Expression.parse("1+.5", usingCache: false)
        XCTAssertEqual(expression.description, "1 + 0.5")
    }

    func testDotsFollowedByLessThan() {
        let expression = Expression.parse("1..<5", usingCache: false)
        XCTAssertEqual(expression.description, "1 ..< 5")
    }

    func testLiteralPlusNegativeLiteral() {
        let expression = Expression("5+-4", options: .noOptimize)
        XCTAssertEqual(expression.description, "5 + -4")
    }

    func testLiteralPercentNegativeLiteral() {
        let expression = Expression("5%-4")
        XCTAssertEqual(expression.description, "5% - 4")
    }

    // MARK: Delimited expressions

    func testBracedExpression() {
        let input = "{ 1 + 2 }"
        var characters = Substring.UnicodeScalarView(input.unicodeScalars)
        characters.removeFirst() // Remove opening {
        var expression = Expression.parse(&characters)
        XCTAssertEqual(characters.first, "}")
        guard expression.error == .unexpectedToken("}") else {
            XCTFail()
            return
        }
        characters = Substring.UnicodeScalarView(input.unicodeScalars)
        characters.removeFirst() // Remove opening {
        expression = Expression.parse(&characters, upTo: "\"")
        XCTAssertEqual(characters.first, "}")
        guard expression.error == .unexpectedToken("}") else {
            XCTFail()
            return
        }
        characters = Substring.UnicodeScalarView(input.unicodeScalars)
        characters.removeFirst() // Remove opening {
        expression = Expression.parse(&characters, upTo: "}")
        XCTAssertEqual(characters.first, "}")
        XCTAssertEqual(expression.description, "1 + 2")
        XCTAssertNil(expression.error)
    }

    func testQuotedExpression() {
        let input = "\" 1 + 2 \""
        var characters = Substring.UnicodeScalarView(input.unicodeScalars)
        characters.removeFirst() // Remove opening quote
        var expression = Expression.parse(&characters)
        XCTAssertNil(characters.first)
        guard expression.error == .unexpectedToken("\"") else {
            XCTFail()
            return
        }
        characters = Substring.UnicodeScalarView(input.unicodeScalars)
        characters.removeFirst() // Remove opening quote
        expression = Expression.parse(&characters, upTo: "}")
        XCTAssertNil(characters.first)
        guard expression.error == .unexpectedToken("\"") else {
            XCTFail()
            return
        }
        characters = Substring.UnicodeScalarView(input.unicodeScalars)
        characters.removeFirst() // Remove opening quote
        expression = Expression.parse(&characters, upTo: "\"")
        XCTAssertEqual(characters.first, "\"")
        XCTAssertEqual(expression.description, "1 + 2")
        XCTAssertNil(expression.error)
    }

    func testEmptyBracedExpression() {
        let input = "{}"
        var characters = Substring.UnicodeScalarView(input.unicodeScalars)
        characters.removeFirst() // Remove opening {
        let expression = Expression.parse(&characters, upTo: "}")
        XCTAssertEqual(characters.first, "}")
        XCTAssertEqual(expression.error, .emptyExpression)
    }

    func testAllWhitespaceBracedExpression() {
        let input = "{ \n }"
        var characters = Substring.UnicodeScalarView(input.unicodeScalars)
        characters.removeFirst() // Remove opening {
        let expression = Expression.parse(&characters, upTo: "}")
        XCTAssertEqual(characters.first, "}")
        XCTAssertEqual(expression.error, .emptyExpression)
    }

    // MARK: Syntax errors

    func testMissingCloseParen() {
        let expression = Expression("(1 + (2 + 3)")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .missingDelimiter(")"))
        }
    }

    func testMissingOpenParen() {
        let expression = Expression("1 + 2)")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .unexpectedToken(")"))
        }
    }

    func testMissingClosingFunctionParen() {
        let expression = Expression("foo(")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .missingDelimiter(")"))
        }
    }

    func testMissingRHS() {
        let expression = Expression("1 + ")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .undefinedSymbol(.postfix("+")))
        }
    }

    func testTrailingDot() {
        let expression = Expression("foo.", constants: ["foo": 5])
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .undefinedSymbol(.postfix(".")))
        }
    }

    func testTrailingDotFollowedBySpace() {
        let expression = Expression("foo. ", constants: ["foo": 5])
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .undefinedSymbol(.postfix(".")))
        }
    }

    func testTrailingDecimalPoint() {
        let expression = Expression("5.")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .undefinedSymbol(.postfix(".")))
        }
    }

    func testInvalidExpression() {
        let expression = Expression("0 5")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .unexpectedToken("5"))
        }
    }

    func testEmptyExpression() {
        let expression = Expression("")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .emptyExpression)
            XCTAssertEqual(error as? Expression.Error, .unexpectedToken(""))
        }
    }

    func testStandaloneOperator() {
        let expression = Expression("+")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .unexpectedToken("+"))
        }
    }

    func testUnterminatedString() {
        let expression = Expression("'foo")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .missingDelimiter("'"))
        }
    }

    func testUnterminatedStringEscapeSequence() {
        let expression = Expression("'foo\\")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .missingDelimiter("'"))
        }
    }

    func testUnterminatedStringAfterEscapeSequence() {
        let expression = Expression("'foo\\'")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .missingDelimiter("'"))
        }
    }

    func testUnicodeLiteralMissingNumber() {
        let expression = Expression("'foo\\u{}")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .unexpectedToken("}"))
        }
    }

    func testUnicodeLiteralMissingNumberAndBrace() {
        let expression = Expression("'foo\\u{")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .missingDelimiter("}"))
        }
    }

    func testUnicodeLiteralContainsJunk() {
        let expression = Expression("'foo\\u{bar}'")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .unexpectedToken("r}'"))
        }
    }

    func testUnicodeLiteralMissingClosingBrace() {
        let expression = Expression("'foo\\u{5")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .missingDelimiter("}"))
        }
    }

    func testInvalidUnicodeCodepoint() {
        let expression = Expression("'foo\\u{DDDD}'")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .unexpectedToken("DDDD"))
        }
    }

    func testMissingClosingBracket() {
        let expression = Expression("foo[0", arrays: ["foo": [1]])
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .missingDelimiter("]"))
        }
    }

    func testMissingIndexExpression() {
        let expression = Expression("foo[", arrays: ["foo": [1]])
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .missingDelimiter("]"))
        }
    }

    func testEmptyBrackets() {
        let expression = Expression("foo[]", arrays: ["foo": []])
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .arityMismatch(.array("foo")))
        }
    }

    func testTrailingParen() {
        let expression = Expression("5)")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .unexpectedToken(")"))
        }
    }

    func testTrailingParenThenSpace() {
        let expression = Expression("5) ")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .unexpectedToken(")"))
        }
    }

    func testTrailingWhitespace() {
        let expression = Expression("5\n")
        XCTAssertNoThrow(try expression.evaluate())
    }

    func testTrailingE() {
        let expression = Expression("5e")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .undefinedSymbol(.postfix("e")))
        }
    }

    func testTrailingEPlus() {
        let expression = Expression("5e+", symbols: [.postfix("e"): { _ in 1 }])
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .undefinedSymbol(.postfix("+")))
        }
    }

    func testTrailingHexPrefix() {
        let expression = Expression("0x")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .unexpectedToken("0x"))
        }
    }

    func testTrailingHexPrefixAfterPrefixOperator() {
        let expression = Expression("-0x")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .unexpectedToken("0x"))
        }
    }

    func testTrailingHexPrefixAfterInfxOperator() {
        let expression = Expression("5 + 0x")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .unexpectedToken("0x"))
        }
    }

    func testMissingFirstArgument() {
        let expression = Expression.parse("foo(,5)")
        XCTAssertEqual(expression.error, .unexpectedToken(","))
    }

    func testMissingLastArgument() { // TODO: should trailing commas be allowed?
        let expression = Expression.parse("foo(1,)")
        XCTAssertEqual(expression.error, .unexpectedToken(")"))
    }

    func testMissingMiddleArgument() {
        let expression = Expression.parse("foo(1,,2)")
        XCTAssertEqual(expression.error, .unexpectedToken(","))
    }

    // MARK: Arity errors

    func testTooFewArguments() {
        let expression = Expression("pow(4)")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .arityMismatch(.function("pow", arity: 2)))
        }
    }

    func testTooFewArgumentsForCustomFunction() {
        let expression = Expression("foo(4)", symbols: [
            .function("foo", arity: 2): { $0[0] + $0[1] },
        ])
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .arityMismatch(.function("foo", arity: 2)))
        }
    }

    func testTooFewArgumentsWithAdvancedInitializer() {
        let expression = Expression(Expression.parse("pow(4)"), pureSymbols: { _ in nil })
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .arityMismatch(.function("pow", arity: 2)))
        }
    }

    func testTooFewArgumentsForCustomFunctionWithAdvancedInitializer() {
        let expression = Expression(Expression.parse("foo(4)"), pureSymbols: { symbol in
            switch symbol {
            case .function("foo", arity: 2):
                return { $0[0] + $0[1] }
            default:
                return nil
            }
        })
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .arityMismatch(.function("foo", arity: 2)))
        }
    }

    func testTooManyArguments() {
        let expression = Expression("pow(4,5,6)")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .arityMismatch(.function("pow", arity: 2)))
        }
    }

    func testTooManyArgumentsWithAdvancedInitializer() {
        let expression = Expression(Expression.parse("pow(4,5,6)"), impureSymbols: { _ in nil })
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .arityMismatch(.function("pow", arity: 2)))
        }
    }

    func testTooFewVariadicArguments() {
        let expression = Expression("min(3)")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .arityMismatch(.function("min", arity: .atLeast(2))))
        }
    }

    // MARK: Symbol errors

    func testUnknownSymbolError() {
        let expression = Expression(Expression.parse("foo()"))
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .undefinedSymbol(.function("foo", arity: 0)))
        }
    }

    func testUnknownSymbolWithAdvancedInitializer() {
        let expression = Expression(Expression.parse("foo()"), pureSymbols: { _ in nil })
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .undefinedSymbol(.function("foo", arity: 0)))
        }
    }

    // MARK: Function overloading

    func testOverridePow() {
        let expression = Expression("pow(3)", symbols: [.function("pow", arity: 1): { $0[0] * $0[0] }])
        XCTAssertEqual(try expression.evaluate(), 9)
    }

    func testOverriddenPow() {
        let expression = Expression("pow(3,3)", symbols: [.function("pow", arity: 1): { $0[0] * $0[0] }])
        XCTAssertEqual(try expression.evaluate(), 27)
    }

    func testCustomOverriddenFunction() {
        let expression = Expression("foo(3,3)", symbols: [
            .function("foo", arity: 1): { args in args[0] },
            .function("foo", arity: 2): { args in args[0] + args[1] },
        ])
        XCTAssertEqual(try expression.evaluate(), 6)
    }

    // MARK: Function blocking

    func testDisablePow() {
        let symbol = Expression.Symbol.function("pow", arity: 2)
        let expression = Expression("pow(1,2)", symbols: [symbol: { _ in
            throw Expression.Error.undefinedSymbol(symbol)
        }])
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .undefinedSymbol(.function("pow", arity: 2)))
        }
    }

    // MARK: Function chaining

    func testCallNumericLiteral() {
        let expression = Expression("1(3)")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .unexpectedToken("("))
        }
    }

    func testCallNumericLiteralWithFunctionCallOperator() {
        let expression = Expression("1(3)", symbols: [
            .infix("()"): { $0[0] + $0[1] },
        ])
        XCTAssertEqual(try expression.evaluate(), 4)
    }

    func testCallResultOfFunction() {
        let expression = Expression("pow(1,2)(3)")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .unexpectedToken("("))
        }
    }

    func testCallResultOfFunctionWithFunctionCallOperator() {
        let expression = Expression("pow(1,2)(3)", symbols: [
            .infix("()"): { $0[0] + $0[1] },
        ])
        XCTAssertEqual(try expression.evaluate(), 4)
    }

    func testCallResultOfSubscript() {
        let expression = Expression("foo[1](3)", symbols: [
            .array("foo"): { _ in 1 },
        ])
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .unexpectedToken("("))
        }
    }

    func testCallResultOfSubscriptWithFunctionCallOperator() {
        let expression = Expression("foo[1](3)", symbols: [
            .array("foo"): { _ in 1 },
            .infix("()"): { $0[0] + $0[1] },
        ])
        XCTAssertEqual(try expression.evaluate(), 4)
    }

    func testCallArrayLiteral() {
        let expression = Expression("[1,2](3)", symbols: [
            .function("[]", arity: .any): { _ in 1 },
        ])
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .unexpectedToken("("))
        }
    }

    func testCallArrayLiteralWithFunctionCallOperator() {
        let expression = Expression("[1,2](3)", symbols: [
            .function("[]", arity: .any): { _ in 1 },
            .infix("()"): { $0[0] + $0[1] },
        ])
        XCTAssertEqual(try expression.evaluate(), 4)
    }

    // MARK: Arrays

    func testSubscriptConstantArray() {
        let expression = Expression("foo[2]", arrays: ["foo": [1, 2, 3]])
        XCTAssertEqual(try expression.evaluate(), 3)
    }

    func testArrayBoundsError() {
        let expression = Expression("foo[3]", arrays: ["foo": [1, 2, 3]])
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .arrayBounds(.array("foo"), 3))
        }
    }

    func testSubscriptCustomArray() {
        let expression = Expression("foo[2]", symbols: [.array("foo"): { args in
            [1, 2, 3][Int(args[0])]
        }])
        XCTAssertEqual(try expression.evaluate(), 3)
    }

    func testMultiArgSubscript() {
        let expression = Expression("foo[2,3]", symbols: [
            .array("foo"): { _ in 0 },
        ])
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .arityMismatch(.array("foo")))
        }
    }

    func testUndefinedTupleSubscript() {
        let expression = Expression("foo[(2,3)]", symbols: [
            .array("foo"): { _ in 0 },
        ])
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .unexpectedToken(","))
        }
    }

    func testSubscriptResultOfSubscript() {
        let expression = Expression("foo[2][3]", symbols: [.array("foo"): { _ in 0 }])
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .unexpectedToken("["))
        }
    }

    func testSubscriptResultOfFunction() {
        let expression = Expression("pow(2,3)[2]")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .unexpectedToken("["))
        }
    }

    func testUndefinedArrayLiteral() {
        let expression = Expression("[1,2,3]")
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .unexpectedToken("["))
        }
    }

    func testArrayLiteral() {
        let expression = Expression("[1,2,3]", symbols: [
            .function("[]", arity: .any): { $0.reduce(0) { $0 + $1 } },
        ])
        XCTAssertEqual(try expression.evaluate(), 6)
    }

    func testAddArrayLiteral() {
        let expression = Expression("[1,2,3] + [4,5,6]", symbols: [
            .function("[]", arity: .any): { $0.reduce(0) { $0 + $1 } },
        ])
        XCTAssertEqual(try expression.evaluate(), 21)
    }

    func testSubscriptArrayLiteral() {
        let expression = Expression("[1,2][3]", symbols: [
            .function("[]", arity: .any): { $0.reduce(0) { $0 + $1 } },
        ])
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .unexpectedToken("["))
        }
    }

    func testSubscriptArrayLiteralWithCustomSubscriptOperator() {
        let expression = Expression("[1,2][0]", symbols: [
            .function("[]", arity: .any): { $0.reduce(0) { $0 + $1 } },
            .infix("[]"): { args in
                let digits = Array(String(Int(args[0])))
                let index = Int(args[1])
                if index >= digits.count {
                    return .nan
                }
                return Double(String(digits[index])) ?? 0
            },
        ])
        XCTAssertEqual(try expression.evaluate(), 3)
    }

    func testSubscriptNumericLiteralWithCustomSubscriptOperator() {
        let expression = Expression("534[2]", symbols: [
            .infix("[]"): { args in
                let digits = Array(String(Int(args[0])))
                let index = Int(args[1])
                if index >= digits.count {
                    return .nan
                }
                return Double(String(digits[index])) ?? 0
            },
        ])
        XCTAssertEqual(try expression.evaluate(), 4)
    }

    func testSubscriptNumericLiteralWithCustomSubscriptOperatorWithMultipleArguments() {
        let expression = Expression("534[2,4]", symbols: [
            .infix("[]"): { _ in 5 },
        ])
        XCTAssertThrowsError(try expression.evaluate()) { error in
            XCTAssertEqual(error as? Expression.Error, .arityMismatch(.infix("[]")))
        }
    }

    // MARK: Evaluation

    func testLiteral() {
        let expression = Expression("5")
        XCTAssertEqual(try expression.evaluate(), 5)
    }

    func testNegativeLiteral() {
        let expression = Expression("- 12")
        XCTAssertEqual(try expression.evaluate(), -12)
    }

    func testVariable() {
        let expression = Expression("foo", constants: ["foo": 15.5])
        XCTAssertEqual(try expression.evaluate(), 15.5)
    }

    func testNegativeVariable() {
        let expression = Expression("-foo", constants: ["foo": 7])
        XCTAssertEqual(try expression.evaluate(), -7)
    }

    func testLiteralAddition() {
        let expression = Expression("5 + 4")
        XCTAssertEqual(try expression.evaluate(), 9)
    }

    func testLiteralPlusVariable() {
        let expression = Expression("3 + foo", constants: ["foo": -7])
        XCTAssertEqual(try expression.evaluate(), -4)
    }

    func testTwoAdditions() {
        let expression = Expression("5 + foo + 4", constants: ["foo": 1.5])
        XCTAssertEqual(try expression.evaluate(), 10.5)
    }

    func testAdditionThenMultiplication() {
        let expression = Expression("5 + foo * 4", constants: ["foo": 1.5])
        XCTAssertEqual(try expression.evaluate(), 11)
    }

    func testAdditionThenMultiplicationWithPrefixMinus() {
        let expression = Expression("5 + foo * -4", constants: ["foo": 1.5])
        XCTAssertEqual(try expression.evaluate(), -1)
    }

    func testMultiplicationThenAddition() {
        let expression = Expression("5 * foo + 4", constants: ["foo": 1.5])
        XCTAssertEqual(try expression.evaluate(), 11.5)
    }

    func testParenthesizedAdditionThenMultiplication() {
        let expression = Expression("(5 + foo) * 4", constants: ["foo": 1.5])
        XCTAssertEqual(try expression.evaluate(), 26)
    }

    func testNestedParenthese() {
        let expression = Expression("((5 + 3) * ((2 - 3) - 1))")
        XCTAssertEqual(try expression.evaluate(), -16)
    }

    func testModFunction() {
        let expression = Expression("mod(-4, 2.5)")
        XCTAssertEqual(try expression.evaluate(), -1.5)
    }

    func testSqrtFunction() {
        let expression = Expression("7 + sqrt(9)")
        XCTAssertEqual(try expression.evaluate(), 10)
    }

    func testPowFunction() {
        let expression = Expression("7 + pow(9, 1/2)")
        XCTAssertEqual(try expression.evaluate(), 10)
    }

    func testVariadicMinFunction() {
        let expression = Expression("min(3, 2, 7)")
        XCTAssertEqual(try expression.evaluate(), 2)
    }

    func testVariadicMaxFunction() {
        let expression = Expression("max(7, 8, 9)")
        XCTAssertEqual(try expression.evaluate(), 9)
    }

    // MARK: Function parsing

    func testParseEmptyFunction() {
        let expression = Expression.parse("foo()")
        XCTAssertEqual(expression.symbols, [.function("foo", arity: 0)])
        XCTAssertEqual(expression.description, "foo()")
    }

    func testParseEmptyFunctionContainingSpace() {
        let expression = Expression.parse("foo( )")
        XCTAssertEqual(expression.symbols, [.function("foo", arity: 0)])
        XCTAssertEqual(expression.description, "foo()")
    }

    func testParseFunctionWithOneArgumentAndSpaces() {
        let expression = Expression.parse("foo( 5 )")
        XCTAssertEqual(expression.symbols, [.function("foo", arity: 1)])
        XCTAssertEqual(expression.description, "foo(5)")
    }

    func testParseFunctionWithTwoArgumentsAndSpaces() {
        let expression = Expression.parse("foo( 5 , 6 )")
        XCTAssertEqual(expression.symbols, [.function("foo", arity: 2)])
        XCTAssertEqual(expression.description, "foo(5, 6)")
    }

    func testParseFunctionWithNestedParensAndSpaces() {
        let expression = Expression.parse("foo( (( (5)) ))")
        XCTAssertEqual(expression.symbols, [.function("foo", arity: 1)])
        XCTAssertEqual(expression.description, "foo(5)")
    }

    func testParseFunctionWithTupleArgument() {
        let expression = Expression.parse("foo((5,6))")
        XCTAssertEqual(expression.symbols, [.infix(","), .function("foo", arity: 1)])
        XCTAssertEqual(expression.description, "foo((5, 6))")
    }

    // MARK: Postfix operator parsing

    func testPostfixOperatorBeforeComma() {
        let expression = Expression("max(50%, 0.6)", symbols: [
            .postfix("%"): { args in args[0] / 100 },
        ])
        XCTAssertEqual(try expression.evaluate(), 0.6)
    }

    func testPostfixOperatorBeforeClosingParen() {
        let expression = Expression("min(0.3, 50%)", symbols: [
            .postfix("%"): { args in args[0] / 100 },
        ])
        XCTAssertEqual(try expression.evaluate(), 0.3)
    }

    func testWronglySpacedPostfixOperator() {
        let expression = Expression("50 % + 10%", symbols: [
            .postfix("%"): { args in args[0] / 100 },
        ])
        XCTAssertEqual(try expression.evaluate(), 0.6)
    }

    // MARK: Alphanumeric operators

    func testPostfixAlphanumericOperator() {
        let expression = Expression("10ms + 5s", symbols: [
            .postfix("ms"): { args in args[0] / 1000 },
            .postfix("s"): { args in args[0] },
        ])
        XCTAssertEqual(try expression.evaluate(), 5.01)
    }

    func testInfixAlphanumericOperator() {
        let expression = Expression("true or false", options: .boolSymbols, symbols: [
            .infix("or"): { args in
                if args[0] != 0 { return 1 }
                if args[1] != 0 { return 1 }
                return 0
            },
        ])
        XCTAssertEqual(try expression.evaluate(), 1)
    }

    // MARK: Math errors

    func testDivideByZero() {
        let expression = Expression("1 / 0")
        XCTAssertEqual(try expression.evaluate(), Double.infinity)
    }

    func testHugeNumber() {
        let expression = Expression("19911919912912919291291291921929123")
        XCTAssertEqual(try expression.evaluate(), 19911919912912919291291291921929123)
    }

    // MARK: Symbols

    func testModExpressionSymbols() {
        let expression = Expression("mod(foo, bar)", symbols: [
            .variable("foo"): { _ in 5 },
            .variable("bar"): { _ in 2.5 },
        ])
        XCTAssertEqual(expression.symbols, [.function("mod", arity: 2), .variable("foo"), .variable("bar")])
    }

    func testPrefixSymbol() {
        let expression = Expression("-foo", symbols: [.variable("foo"): { _ in 5 }])
        let expected: Set<Expression.Symbol> = [.prefix("-"), .variable("foo")]
        XCTAssertEqual(expression.symbols, expected)
    }

    func testPostfixSymbol() {
        let expression = Expression("foo++", symbols: [
            .variable("foo"): { _ in 5 },
            .postfix("++"): { args in args[0] + 1 },
        ])
        let expected: Set<Expression.Symbol> = [.postfix("++"), .variable("foo")]
        XCTAssertEqual(expression.symbols, expected)
    }

    // MARK: Optimization

    func testConstantSymbolsInlined() {
        let expression = Expression("foo(bar, baz)", constants: ["bar": 5, "baz": 2.5])
        XCTAssertEqual(expression.symbols, [.function("foo", arity: 2)])
        XCTAssertEqual(expression.description, "foo(5, 2.5)")
    }

    func testConstantSymbolsInlined2() {
        let expression = Expression("foo[bar]", constants: ["bar": 0])
        XCTAssertEqual(expression.symbols, [.array("foo")])
        XCTAssertEqual(expression.description, "foo[0]")
    }

    func testConstantExpressionEvaluatedCorrectly() {
        let expression = Expression("5 + foo", constants: ["foo": 5])
        XCTAssertEqual(try expression.evaluate(), 10)
    }

    func testConstantInlined() {
        let expression = Expression("5 + foo", constants: ["foo": 5])
        XCTAssertEqual(expression.symbols, [])
        XCTAssertEqual(expression.description, "10")
    }

    func testConstantInlined2() {
        let expression = Expression("5 + foo", constants: ["foo": 5], symbols: [.variable("bar"): { _ in 6 }])
        XCTAssertEqual(expression.symbols, [])
        XCTAssertEqual(expression.description, "10")
    }

    func testVariableSymbolNotInlined() {
        let expression = Expression("5 + foo", options: .pureSymbols, symbols: [.variable("foo"): { _ in 5 }])
        XCTAssertEqual(expression.symbols, [.variable("foo"), .infix("+")])
        XCTAssertEqual(expression.description, "5 + foo")
    }

    func testArrayInlined() {
        let expression = Expression("5 + foo[0]", arrays: ["foo": [5]])
        XCTAssertEqual(expression.symbols, [])
        XCTAssertEqual(expression.description, "10")
    }

    func testArraySymbolNotInlined() {
        let expression = Expression("5 + foo[0]", options: .pureSymbols, symbols: [.array("foo"): { _ in 5 }])
        XCTAssertEqual(expression.symbols, [.array("foo"), .infix("+")])
        XCTAssertEqual(expression.description, "5 + foo[0]")
    }

    func testPotentiallyImpureConstantNotInlined() {
        let expression = Expression("5 + foo", symbols: [.variable("foo"): { _ in 5 }])
        XCTAssertEqual(expression.symbols, [.variable("foo"), .infix("+")])
        XCTAssertEqual(expression.description, "5 + foo")
    }

    func testPotentiallyImpureArrayNotInlined() {
        let expression = Expression("5 + foo[0]", symbols: [.array("foo"): { _ in 5 }])
        XCTAssertEqual(expression.symbols, [.array("foo"), .infix("+")])
        XCTAssertEqual(expression.description, "5 + foo[0]")
    }

    func testPureExpressionInlined() {
        let expression = Expression("min(5, 6) + a")
        XCTAssertEqual(expression.symbols, [.variable("a"), .infix("+")])
        XCTAssertEqual(expression.description, "5 + a")
    }

    func testPotentiallyImpureExpressionNotInlined() {
        let expression = Expression("min(5, 6) + a", symbols: [.function("min", arity: 2): { min($0[0], $0[1]) }])
        XCTAssertEqual(expression.symbols, [.function("min", arity: 2), .variable("a"), .infix("+")])
        XCTAssertEqual(expression.description, "min(5, 6) + a")
    }

    func testBooleanExpressionsInlined() {
        let expression = Expression("1 || 1 ? 3 * 5 : 2 * 3", options: .boolSymbols)
        XCTAssertEqual(expression.symbols, [])
        XCTAssertEqual(expression.description, "15")
    }

    func testVariableDoesntBreakOptimizer() {
        let expression = Expression(
            "foo ? bar : baz",
            options: .boolSymbols,
            constants: ["bar": 5, "baz": 6],
            symbols: [.variable("foo"): { _ in 1 }]
        )
        XCTAssertEqual(expression.symbols, [.variable("foo"), .infix("?:")])
        XCTAssertEqual(expression.description, "foo ? 5 : 6")
    }

    func testOptimizerDisabled() {
        let expression = Expression("3 * 5", options: .noOptimize)
        XCTAssertEqual(expression.symbols, [.infix("*")])
        XCTAssertEqual(expression.description, "3 * 5")
    }

    // MARK: Pure symbols

    func testOverriddenBuiltInConstantNotInlined() {
        let expression = Expression("5 + pi", symbols: [.variable("pi"): { _ in 5 }])
        XCTAssertEqual(expression.symbols, [.infix("+"), .variable("pi")])
        XCTAssertEqual(expression.description, "5 + pi")
    }

    func testOverriddenBuiltInConstantNotInlinedWithPureSymbols() {
        let expression = Expression("5 + pi", options: .pureSymbols, symbols: [.variable("pi"): { _ in 5 }])
        XCTAssertEqual(expression.symbols, [.infix("+"), .variable("pi")])
        XCTAssertEqual(expression.description, "5 + pi")
    }

    func testOverriddenBuiltInFunctionNotInlined() {
        let expression = Expression("5 + floor(1.5)", symbols: [
            .function("floor", arity: 1): { args in ceil(args[0]) },
        ])
        XCTAssertEqual(expression.symbols, [.infix("+"), .function("floor", arity: 1)])
        XCTAssertEqual(expression.description, "5 + floor(1.5)")
    }

    func testOverriddenBuiltInFunctionInlinedWithPureSymbols() {
        let expression = Expression("5 + floor(1.5)", options: .pureSymbols, symbols: [
            .function("floor", arity: 1): { args in ceil(args[0]) },
        ])
        XCTAssertEqual(expression.symbols, [])
        XCTAssertEqual(expression.description, "7")
    }

    func testCustomFunctionNotInlined() {
        let expression = Expression("5 + foo()", symbols: [.function("foo", arity: 0): { _ in 5 }])
        XCTAssertEqual(expression.symbols, [.infix("+"), .function("foo", arity: 0)])
        XCTAssertEqual(expression.description, "5 + foo()")
    }

    func testCustomFunctionInlinedWithPureSymbols() {
        let expression = Expression("5 + foo()", options: .pureSymbols, symbols: [.function("foo", arity: 0): { _ in 5 }])
        XCTAssertEqual(expression.symbols, [])
        XCTAssertEqual(expression.description, "10")
    }

    // MARK: Dot operators

    func testDotInsideIdentifier() {
        let expression = Expression("foo.bar", options: .boolSymbols)
        XCTAssertEqual(expression.symbols, [.variable("foo.bar")])
    }

    func testDotBetweenParens() {
        let expression = Expression("(foo).(bar)", options: .boolSymbols)
        XCTAssertEqual(expression.symbols, [.variable("foo"), .infix("."), .variable("bar")])
    }

    func testDotFollowedByNumber() {
        let expression = Expression("foo.3", options: .boolSymbols)
        XCTAssertEqual(expression.symbols, [.variable("foo.3")])
    }

    func testIdentifierWithLeadingDot() {
        let expression = Expression(".foo", options: .boolSymbols)
        XCTAssertEqual(expression.symbols, [.variable(".foo")])
    }

    func testRangeOperator() {
        let expression = Expression("foo..bar", options: .boolSymbols)
        XCTAssertEqual(expression.symbols, [.variable("foo"), .infix(".."), .variable("bar")])
    }

    // MARK: Ternary operator

    func testTernaryTrue() {
        let expression = Expression("0 ? 1 : 2", options: .boolSymbols)
        XCTAssertEqual(try expression.evaluate(), 2)
    }

    func testTernaryFalse() {
        let expression = Expression("1 ? 1 : 2", options: .boolSymbols)
        XCTAssertEqual(try expression.evaluate(), 1)
    }

    func testTernaryPrecedence() {
        let expression = Expression("1 - 1 ? 3 * 5 : 2 * 3", options: .boolSymbols)
        XCTAssertEqual(try expression.evaluate(), 6)
    }

    func testUndefinedTernaryOperator() {
        let symbols: [Expression.Symbol: Expression.SymbolEvaluator] = [
            .infix("?"): { $0[0] != 0 ? $0[1] : 0 },
            .infix(":"): { $0[0] != 0 ? $0[0] : $0[1] },
        ]
        let expression = Expression("1 - 1 ? 3 * 5 : 2 * 3", symbols: symbols)
        XCTAssertEqual(expression.description, "0 ? 15 : 6")
        XCTAssertEqual(try expression.evaluate(), 6)
    }

    func testTernaryWith2Arguments() {
        let expression1 = Expression("5 ?: 4", options: .boolSymbols)
        XCTAssertEqual(try expression1.evaluate(), 5)
        let expression2 = Expression("0 ?: 4", options: .boolSymbols)
        XCTAssertEqual(try expression2.evaluate(), 4)
    }

    // MARK: Modulo operator

    func testPostiveIntegerModulo() {
        let expression = Expression("5 % 2")
        XCTAssertEqual(try expression.evaluate(), 1)
    }

    func testNegativeIntegerModulo() {
        let expression = Expression("5 % -2")
        XCTAssertEqual(try expression.evaluate(), 1)
    }

    func testNegativeIntegerModulo2() {
        let expression = Expression("-5 % 2")
        XCTAssertEqual(try expression.evaluate(), -1)
    }

    func testNegativeIntegerModulo3() {
        let expression = Expression("-5 % -2")
        XCTAssertEqual(try expression.evaluate(), -1)
    }

    func testPostiveFloatModulo() {
        let expression = Expression("5.5 % 2")
        XCTAssertEqual(try expression.evaluate(), 1.5)
    }

    func testNegativeFloatModulo() {
        let expression = Expression("5.5 % -2")
        XCTAssertEqual(try expression.evaluate(), 1.5)
    }

    // MARK: Assignment

    func testAssignmentAssociativity() {
        var variables: [Double] = [0, 0]
        let expression = Expression("a = b = 5", symbols: [
            .infix("="): { args in
                variables[Int(args[0])] = args[1]
                return args[1]
            },
            .variable("a"): { _ in 0 },
            .variable("b"): { _ in 1 },
        ])
        XCTAssertEqual(try expression.evaluate(), 5)
        XCTAssertEqual(variables[0], 5)
        XCTAssertEqual(variables[1], 5)
    }

    // MARK: Identifier validation

    func testValidateSimpleIdentifier() {
        XCTAssertTrue(Expression.isValidIdentifier("foo"))
    }

    func testValidateIdentifierWithTrailingSpace() {
        XCTAssertFalse(Expression.isValidIdentifier("foo "))
    }

    func testValidateIdentifierWithLeadingSpace() {
        XCTAssertFalse(Expression.isValidIdentifier(" foo"))
    }

    func testValidateUnicodeIdentifier() {
        XCTAssertTrue(Expression.isValidIdentifier("🤡"))
    }

    func testValidateDotDelimitedIdentifier() {
        XCTAssertTrue(Expression.isValidIdentifier("foo.bar"))
    }

    func testValidateDotPrefixedIdentifier() {
        XCTAssertTrue(Expression.isValidIdentifier(".foo"))
    }

    func testValidateDotSuffixedIdentifier() {
        XCTAssertFalse(Expression.isValidIdentifier("foo."))
    }

    func testValidateIdentifierWithTrailingApostrophe() {
        XCTAssertTrue(Expression.isValidIdentifier("x'"))
    }

    func testValidateIdentifierWithTrailingDotApostrophe() {
        XCTAssertFalse(Expression.isValidIdentifier("x.'"))
    }

    func testValidateIdentifierWithLeadingApostrophe() {
        XCTAssertFalse(Expression.isValidIdentifier("'x"))
    }

    func testValidateEscapedIdentifier() {
        XCTAssertTrue(Expression.isValidIdentifier("`foo bar`"))
    }

    func testValidateQuotedIdentifier() {
        XCTAssertTrue(Expression.isValidIdentifier("'foo bar'"))
    }

    func testValidateDoubleQuotedIdentifier() {
        XCTAssertTrue(Expression.isValidIdentifier("\"foo 'bar'\""))
    }

    func testValidateOperatorAsIdentifier() {
        XCTAssertFalse(Expression.isValidIdentifier("+"))
    }

    func testValidateEmptyIdentifier() {
        XCTAssertFalse(Expression.isValidIdentifier(""))
    }

    // MARK: Operator validation

    func testValidateSimpleOperator() {
        XCTAssertTrue(Expression.isValidOperator("+"))
    }

    func testValidateTripleEqualsOperator() {
        XCTAssertTrue(Expression.isValidOperator("==="))
    }

    func testValidateTernaryOperator() {
        XCTAssertTrue(Expression.isValidOperator("?:"))
    }

    func testValidateUnicodeOperator() {
        XCTAssertTrue(Expression.isValidOperator("•"))
    }

    func testValidateOpenParenAsOperator() {
        XCTAssertFalse(Expression.isValidOperator("("))
    }

    func testValidateOpenBracketAsOperator() {
        XCTAssertFalse(Expression.isValidOperator("["))
    }

    func testValidateCommaOperator() {
        XCTAssertTrue(Expression.isValidOperator(","))
    }

    func testValidateCommaSequenceAsOperator() {
        XCTAssertFalse(Expression.isValidOperator(",,"))
    }

    func testValidateColonOperator() {
        XCTAssertTrue(Expression.isValidOperator(":"))
    }

    func testValidateColonSequenceAsOperator() {
        XCTAssertTrue(Expression.isValidOperator("::"))
    }

    func testValidateIdentifierAsOperator() {
        XCTAssertFalse(Expression.isValidOperator("foo"))
    }

    func testValidateEmptyOperator() {
        XCTAssertFalse(Expression.isValidOperator(""))
    }

    // MARK: Operator precedence

    func testEqualityIsRightAssociative() {
        let expression = Expression("a == b == c", options: .boolSymbols, constants: ["a": 1, "b": 2, "c": 2])
        XCTAssertEqual(try expression.evaluate(), 1)
    }

    func testBitshiftTakesPrecedenceOverAddition() {
        let expression = Expression("1 + 2 << 3", symbols: [.infix("<<"): { Double(Int($0[0]) << Int($0[1])) }])
        XCTAssertEqual(try expression.evaluate(), 17)
    }

    func testMultiplicationTakesPrecedenceOverAddition() {
        let expression = Expression("2 + 3 * 2")
        XCTAssertEqual(try expression.evaluate(), 8)
    }

    func testAdditionTakesPrecedenceOverRange() {
        let expression = Expression("1 ... 3 * 4", symbols: [.infix("..."): { $0[0] + $0[1] }])
        XCTAssertEqual(try expression.evaluate(), 13)
    }

    func testRangeTakesPrecedenceOverIs() {
        let expression = Expression("3 is 1 ... 2", symbols: [
            .infix("..."): { $0[0] + $0[1] },
            .infix("is"): { $0[0] == $0[1] ? 1 : 0 },
        ] as [Expression.Symbol: ([Double]) throws -> Double])
        XCTAssertEqual(try expression.evaluate(), 1)
    }

    func testIsTakesPrecedenceOverTernary() {
        let expression = Expression("0 ? 1 is 2 : 2 is 2", options: .boolSymbols, symbols: [
            .infix("is"): { $0[0] == $0[1] ? 1 : 0 },
        ])
        XCTAssertEqual(try expression.evaluate(), 1)
    }

    func testSubtractionTakesPrecedenceOverNullCoalescing() {
        let expression = Expression("1 - 1 ?? 2 + 1", symbols: [.infix("??"): { $0[0] != 0 ? $0[0] : $0[1] }])
        XCTAssertEqual(try expression.evaluate(), 3)
    }

    func testEqualityTakesPrecedenceOverAssignment() {
        let expression = Expression("2 = 3 == 1", options: .boolSymbols, symbols: [.infix("="): { $0[1] }])
        XCTAssertEqual(try expression.evaluate(), 0)
    }

    func testEqualityTakesPrecedenceOverAnd() {
        let expression = Expression("1 == 1 && 2 == 2", options: .boolSymbols)
        XCTAssertEqual(try expression.evaluate(), 1)
    }

    func testEverythingTakesPrecedenceOverComma() {
        let expression = Expression("3 * 2, 2 * 3", symbols: [.infix(","): { $0[0] + $0[1] }])
        XCTAssertEqual(try expression.evaluate(), 12)
    }

    func testSubscriptTakesPrecedenceOverMultiplications() {
        let expression = Expression("2 * 3[3] * 4", symbols: [.infix("[]"): { $0[0] + $0[1] }])
        XCTAssertEqual(try expression.evaluate(), 48)
    }

    func testSubscriptArgumentTakesPrecedence() {
        let expression = Expression("3[3 + 2] * 4", symbols: [.infix("[]"): { $0[0] + $0[1] }])
        XCTAssertEqual(try expression.evaluate(), 32)
    }

    func testWhitespaceDoesNotaffectPrecedence() {
        let expression = Expression("3 * 4 +5")
        XCTAssertEqual(try expression.evaluate(), 17)
    }

    func testWhitespaceDoesNotaffectPrecedence2() {
        let expression = Expression("3 * 4+ 5")
        XCTAssertEqual(try expression.evaluate(), 17)
    }

    func testWhitespaceDoesNotaffectPrecedence3() {
        let expression = Expression("3 *4 + 5")
        XCTAssertEqual(try expression.evaluate(), 17)
    }

    func testWhitespaceDoesNotaffectPrecedence4() {
        let expression = Expression("3* 4 + 5")
        XCTAssertEqual(try expression.evaluate(), 17)
    }

    // MARK: Symbol precedence

    func testConstantTakesPrecedenceOverSymbol() {
        let expression = Expression(
            "foo",
            constants: ["foo": 5],
            symbols: [.variable("foo"): { _ in 6 }]
        )
        XCTAssertEqual(try expression.evaluate(), 5)
    }

    func testArrayConstantTakesPrecedenceOverSymbol() {
        let expression = Expression(
            "foo[0]",
            arrays: ["foo": [5]],
            symbols: [.array("foo"): { _ in 6 }]
        )
        XCTAssertEqual(try expression.evaluate(), 5)
    }

    // MARK: Cache

    func testCache() {
        let expression = "foo + 5"
        Expression.clearCache()
        XCTAssertFalse(Expression.isCached(expression))
        _ = Expression(expression)
        XCTAssertTrue(Expression.isCached(expression))
        Expression.clearCache(for: expression)
        XCTAssertFalse(Expression.isCached(expression))
    }
}
