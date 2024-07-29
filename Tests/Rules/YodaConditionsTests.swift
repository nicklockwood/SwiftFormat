//
//  YodaConditionsTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class YodaConditionsTests: XCTestCase {
    func testNumericLiteralEqualYodaCondition() {
        let input = "5 == foo"
        let output = "foo == 5"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testNumericLiteralGreaterYodaCondition() {
        let input = "5.1 > foo"
        let output = "foo < 5.1"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testStringLiteralNotEqualYodaCondition() {
        let input = "\"foo\" != foo"
        let output = "foo != \"foo\""
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testNilNotEqualYodaCondition() {
        let input = "nil != foo"
        let output = "foo != nil"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testTrueNotEqualYodaCondition() {
        let input = "true != foo"
        let output = "foo != true"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testEnumCaseNotEqualYodaCondition() {
        let input = ".foo != foo"
        let output = "foo != .foo"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testArrayLiteralNotEqualYodaCondition() {
        let input = "[5, 6] != foo"
        let output = "foo != [5, 6]"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testNestedArrayLiteralNotEqualYodaCondition() {
        let input = "[5, [6, 7]] != foo"
        let output = "foo != [5, [6, 7]]"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testDictionaryLiteralNotEqualYodaCondition() {
        let input = "[foo: 5, bar: 6] != foo"
        let output = "foo != [foo: 5, bar: 6]"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testSubscriptNotTreatedAsYodaCondition() {
        let input = "foo[5] != bar"
        testFormatting(for: input, rule: .yodaConditions)
    }

    func testSubscriptOfParenthesizedExpressionNotTreatedAsYodaCondition() {
        let input = "(foo + bar)[5] != baz"
        testFormatting(for: input, rule: .yodaConditions)
    }

    func testSubscriptOfUnwrappedValueNotTreatedAsYodaCondition() {
        let input = "foo![5] != bar"
        testFormatting(for: input, rule: .yodaConditions)
    }

    func testSubscriptOfExpressionWithInlineCommentNotTreatedAsYodaCondition() {
        let input = "foo /* foo */ [5] != bar"
        testFormatting(for: input, rule: .yodaConditions)
    }

    func testSubscriptOfCollectionNotTreatedAsYodaCondition() {
        let input = "[foo][5] != bar"
        testFormatting(for: input, rule: .yodaConditions)
    }

    func testSubscriptOfTrailingClosureNotTreatedAsYodaCondition() {
        let input = "foo { [5] }[0] != bar"
        testFormatting(for: input, rule: .yodaConditions)
    }

    func testSubscriptOfRhsNotMangledInYodaCondition() {
        let input = "[1] == foo[0]"
        let output = "foo[0] == [1]"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testTupleYodaCondition() {
        let input = "(5, 6) != bar"
        let output = "bar != (5, 6)"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testLabeledTupleYodaCondition() {
        let input = "(foo: 5, bar: 6) != baz"
        let output = "baz != (foo: 5, bar: 6)"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testNestedTupleYodaCondition() {
        let input = "(5, (6, 7)) != baz"
        let output = "baz != (5, (6, 7))"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testFunctionCallNotTreatedAsYodaCondition() {
        let input = "foo(5) != bar"
        testFormatting(for: input, rule: .yodaConditions)
    }

    func testCallOfParenthesizedExpressionNotTreatedAsYodaCondition() {
        let input = "(foo + bar)(5) != baz"
        testFormatting(for: input, rule: .yodaConditions)
    }

    func testCallOfUnwrappedValueNotTreatedAsYodaCondition() {
        let input = "foo!(5) != bar"
        testFormatting(for: input, rule: .yodaConditions)
    }

    func testCallOfExpressionWithInlineCommentNotTreatedAsYodaCondition() {
        let input = "foo /* foo */ (5) != bar"
        testFormatting(for: input, rule: .yodaConditions)
    }

    func testCallOfRhsNotMangledInYodaCondition() {
        let input = "(1, 2) == foo(0)"
        let output = "foo(0) == (1, 2)"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testTrailingClosureOnRhsNotMangledInYodaCondition() {
        let input = "(1, 2) == foo { $0 }"
        let output = "foo { $0 } == (1, 2)"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testYodaConditionInIfStatement() {
        let input = "if 5 != foo {}"
        let output = "if foo != 5 {}"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testSubscriptYodaConditionInIfStatementWithBraceOnNextLine() {
        let input = "if [0] == foo.bar[0]\n{ baz() }"
        let output = "if foo.bar[0] == [0]\n{ baz() }"
        testFormatting(for: input, output, rule: .yodaConditions,
                       exclude: [.wrapConditionalBodies])
    }

    func testYodaConditionInSecondClauseOfIfStatement() {
        let input = "if foo, 5 != bar {}"
        let output = "if foo, bar != 5 {}"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testYodaConditionInExpression() {
        let input = "let foo = 5 < bar\nbaz()"
        let output = "let foo = bar > 5\nbaz()"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testYodaConditionInExpressionWithTrailingClosure() {
        let input = "let foo = 5 < bar { baz() }"
        let output = "let foo = bar { baz() } > 5"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testYodaConditionInFunctionCall() {
        let input = "foo(5 < bar)"
        let output = "foo(bar > 5)"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testYodaConditionFollowedByExpression() {
        let input = "5 == foo + 6"
        let output = "foo + 6 == 5"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testPrefixExpressionYodaCondition() {
        let input = "!false == foo"
        let output = "foo == !false"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testPrefixExpressionYodaCondition2() {
        let input = "true == !foo"
        let output = "!foo == true"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testPostfixExpressionYodaCondition() {
        let input = "5<*> == foo"
        let output = "foo == 5<*>"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testDoublePostfixExpressionYodaCondition() {
        let input = "5!! == foo"
        let output = "foo == 5!!"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testPostfixExpressionNonYodaCondition() {
        let input = "5 == 5<*>"
        testFormatting(for: input, rule: .yodaConditions)
    }

    func testPostfixExpressionNonYodaCondition2() {
        let input = "5<*> == 5"
        testFormatting(for: input, rule: .yodaConditions)
    }

    func testStringEqualsStringNonYodaCondition() {
        let input = "\"foo\" == \"bar\""
        testFormatting(for: input, rule: .yodaConditions)
    }

    func testConstantAfterNullCoalescingNonYodaCondition() {
        let input = "foo.last ?? -1 < bar"
        testFormatting(for: input, rule: .yodaConditions)
    }

    func testNoMangleYodaConditionFollowedByAndOperator() {
        let input = "5 <= foo && foo <= 7"
        let output = "foo >= 5 && foo <= 7"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testNoMangleYodaConditionFollowedByOrOperator() {
        let input = "5 <= foo || foo <= 7"
        let output = "foo >= 5 || foo <= 7"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testNoMangleYodaConditionFollowedByParentheses() {
        let input = "0 <= (foo + bar)"
        let output = "(foo + bar) >= 0"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testNoMangleYodaConditionInTernary() {
        let input = "let z = 0 < y ? 3 : 4"
        let output = "let z = y > 0 ? 3 : 4"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testNoMangleYodaConditionInTernary2() {
        let input = "let z = y > 0 ? 0 < x : 4"
        let output = "let z = y > 0 ? x > 0 : 4"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testNoMangleYodaConditionInTernary3() {
        let input = "let z = y > 0 ? 3 : 0 < x"
        let output = "let z = y > 0 ? 3 : x > 0"
        testFormatting(for: input, output, rule: .yodaConditions)
    }

    func testKeyPathNotMangledAndNotTreatedAsYodaCondition() {
        let input = "\\.foo == bar"
        testFormatting(for: input, rule: .yodaConditions)
    }

    func testEnumCaseLessThanEnumCase() {
        let input = "XCTAssertFalse(.never < .never)"
        testFormatting(for: input, rule: .yodaConditions)
    }

    // yodaSwap = literalsOnly

    func testNoSwapYodaDotMember() {
        let input = "foo(where: .bar == baz)"
        let options = FormatOptions(yodaSwap: .literalsOnly)
        testFormatting(for: input, rule: .yodaConditions, options: options)
    }
}
