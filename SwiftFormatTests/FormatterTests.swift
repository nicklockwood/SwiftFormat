//
//  SwiftFormat
//  FormatterTests.swift
//
//  Version 0.7
//
//  Created by Nick Lockwood on 12/08/2016.
//  Copyright 2016 Charcoal Design
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/SwiftFormat
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

import XCTest
import SwiftFormat

class FormatterTests: XCTestCase {

    // MARK: spaceAroundParens

    func testSpaceAfterSet() {
        let input = "private(set)var foo: Int"
        let output = "private(set) var foo: Int"
        XCTAssertEqual(format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenParenAndClass() {
        let input = "@objc(XYZFoo)class foo"
        let output = "@objc(XYZFoo) class foo"
        XCTAssertEqual(format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenParenAndAs() {
        let input = "(foo) as? String"
        let output = "(foo) as? String"
        XCTAssertEqual(format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAfterParenAtEndOfFile() {
        let input = "(foo)"
        let output = "(foo)"
        XCTAssertEqual(format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenParenAndFoo() {
        let input = "func foo ()"
        let output = "func foo()"
        XCTAssertEqual(format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceBetweenParenAndInit() {
        let input = "init ()"
        let output = "init()"
        XCTAssertEqual(format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceBetweenObjcAndSelector() {
        let input = "@objc (XYZFoo) class foo"
        let output = "@objc(XYZFoo) class foo"
        XCTAssertEqual(format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenPrivateAndSet() {
        let input = "private (set) var foo: Int"
        let output = "private(set) var foo: Int"
        XCTAssertEqual(format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenLetAndTuple() {
        let input = "if let (foo, bar) = baz"
        let output = "if let (foo, bar) = baz"
        XCTAssertEqual(format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenIfAndCondition() {
        let input = "if(true) {}"
        let output = "if (true) {}"
        XCTAssertEqual(format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceBetweenArrayLiteralAndParen() {
        let input = "[String] ()"
        let output = "[String]()"
        XCTAssertEqual(format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenClosingParenAndOpenBrace() {
        let input = "func foo(){ foo }"
        let output = "func foo() { foo }"
        XCTAssertEqual(format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceBetweenClosingBraceAndParens() {
        let input = "{ block } ()"
        let output = "{ block }()"
        XCTAssertEqual(format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testDontRemoveSpaceBetweenOpeningBraceAndParens() {
        let input = "a = (b + c)"
        let output = "a = (b + c)"
        XCTAssertEqual(format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: spaceInsideParens

    func testSpaceInsideParens() {
        let input = "( 1, ( 2, 3 ) )"
        let output = "(1, (2, 3))"
        XCTAssertEqual(format(input, rules: [spaceInsideParens]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: spaceAroundBrackets

    func testSubscriptSpacing() {
        let input = "foo[bar] = baz"
        let output = "foo[bar] = baz"
        XCTAssertEqual(format(input, rules: [spaceAroundBrackets]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testArrayLiteralSpacing() {
        let input = "foo = [bar, baz]"
        let output = "foo = [bar, baz]"
        XCTAssertEqual(format(input, rules: [spaceAroundBrackets]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testAsArrayCasting() {
        let input = "foo as[String]"
        let output = "foo as [String]"
        XCTAssertEqual(format(input, rules: [spaceAroundBrackets]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testAsOptionalArrayCasting() {
        let input = "foo as? [String]"
        let output = "foo as? [String]"
        XCTAssertEqual(format(input, rules: [spaceAroundBrackets]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testIsArrayTesting() {
        let input = "if foo is[String]"
        let output = "if foo is [String]"
        XCTAssertEqual(format(input, rules: [spaceAroundBrackets]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: spaceInsideBrackets

    func testSpaceInsideBrackets() {
        let input = "foo[ 5 ]"
        let output = "foo[5]"
        XCTAssertEqual(format(input, rules: [spaceInsideBrackets]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: spaceAroundBraces

    func testSpaceAroundTrailingClosure() {
        let input = "if x{ y }else{ z }"
        let output = "if x { y } else { z }"
        XCTAssertEqual(format(input, rules: [spaceAroundBraces]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAroundClosureInsiderParens() {
        let input = "foo({ $0 == 5 })"
        let output = "foo({ $0 == 5 })"
        XCTAssertEqual(format(input, rules: [spaceAroundBraces]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoExtraSpaceAroundBracesAtStartOrEndOfFile() {
        let input = "{ foo }"
        let output = "{ foo }"
        XCTAssertEqual(format(input, rules: [spaceAroundBraces]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundBracesAfterOptionalProperty() {
        let input = "var: Foo?{}"
        let output = "var: Foo? {}"
        XCTAssertEqual(format(input, rules: [spaceAroundBraces]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundBracesAfterImplicitlyUnwrappedProperty() {
        let input = "var: Foo!{}"
        let output = "var: Foo! {}"
        XCTAssertEqual(format(input, rules: [spaceAroundBraces]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundBracesAfterNumber() {
        let input = "if x = 5{}"
        let output = "if x = 5 {}"
        XCTAssertEqual(format(input, rules: [spaceAroundBraces]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundBracesAfterString() {
        let input = "if x = \"\"{}"
        let output = "if x = \"\" {}"
        XCTAssertEqual(format(input, rules: [spaceAroundBraces]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: spaceInsideBraces

    func testSpaceInsideBraces() {
        let input = "foo({bar})"
        let output = "foo({ bar })"
        XCTAssertEqual(format(input, rules: [spaceInsideBraces]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoExtraSpaceInsidebraces() {
        let input = "{ foo }"
        let output = "{ foo }"
        XCTAssertEqual(format(input, rules: [spaceInsideBraces]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceInsideEmptybraces() {
        let input = "foo({ })"
        let output = "foo({})"
        XCTAssertEqual(format(input, rules: [spaceInsideBraces]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: spaceAroundGenerics

    func testSpaceAroundGenerics() {
        let input = "Foo <Bar <Baz>>"
        let output = "Foo<Bar<Baz>>"
        XCTAssertEqual(format(input, rules: [spaceAroundGenerics]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: spaceInsideGenerics

    func testSpaceInsideGenerics() {
        let input = "Foo< Bar< Baz > >"
        let output = "Foo<Bar<Baz>>"
        XCTAssertEqual(format(input, rules: [spaceInsideGenerics]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: spaceAroundOperators

    func testSpaceAfterColon() {
        let input = "let foo:Bar = 5"
        let output = "let foo: Bar = 5"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAddedAfterColonInSelector() {
        let input = "@objc(foo:bar:)"
        let output = "@objc(foo:bar:)"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAfterComma() {
        let input = "let foo = [1,2,3]"
        let output = "let foo = [1, 2, 3]"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenColonAndEnumValue() {
        let input = "[.Foo:.Bar]"
        let output = "[.Foo: .Bar]"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenCommaAndEnumValue() {
        let input = "[.Foo,.Bar]"
        let output = "[.Foo, .Bar]"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenSemicolonAndEnumValue() {
        let input = "statement;.Bar"
        let output = "statement; .Bar"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenEqualsAndEnumValue() {
        let input = "foo = .Bar"
        let output = "foo = .Bar"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceBeforeColon() {
        let input = "let foo : Bar = 5"
        let output = "let foo: Bar = 5"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBeforeColonInTernary() {
        let input = "foo ? bar : baz"
        let output = "foo ? bar : baz"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testTernaryOfEnumValues() {
        let input = "foo ? .Bar : .Baz"
        let output = "foo ? .Bar : .Baz"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBeforeColonInNestedTernary() {
        let input = "foo ? (hello + a ? b: c) : baz"
        let output = "foo ? (hello + a ? b : c) : baz"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceBeforeComma() {
        let input = "let foo = [1 , 2 , 3]"
        let output = "let foo = [1, 2, 3]"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAtStartOfLine() {
        let input = "foo\n    ,bar"
        let output = "foo\n    , bar"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundInfixMinus() {
        let input = "foo-bar"
        let output = "foo - bar"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAroundPrefixMinus() {
        let input = "foo + -bar"
        let output = "foo + -bar"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundLessThan() {
        let input = "foo<bar"
        let output = "foo < bar"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testDontAddSpaceAroundDot() {
        let input = "foo.bar"
        let output = "foo.bar"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testRemoveSpaceAroundDot() {
        let input = "foo . bar"
        let output = "foo.bar"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAroundDotOnNewLine() {
        let input = "foo\n    .bar"
        let output = "foo\n    .bar"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundEnumCase() {
        let input = "case .Foo,.Bar:"
        let output = "case .Foo, .Bar:"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSwitchWithEnumCases() {
        let input = "switch x {\ncase.Foo:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\ncase .Foo:\n    break\ndefault:\n    break\n}"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundEnumReturn() {
        let input = "return.Foo"
        let output = "return .Foo"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundCaseLet() {
        let input = "case let.Foo(bar):"
        let output = "case let .Foo(bar):"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundEnumArgument() {
        let input = "foo(with:.Bar)"
        let output = "foo(with: .Bar)"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBeforeEnumCaseInsideClosure() {
        let input = "{ .Bar() }"
        let output = "{ .Bar() }"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAroundOptionalChaining() {
        let input = "foo?.bar"
        let output = "foo?.bar"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAroundMultipleOptionalChaining() {
        let input = "foo??!?!.bar"
        let output = "foo??!?!.bar"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAroundForcedChaining() {
        let input = "foo!.bar"
        let output = "foo!.bar"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceBetweenOptionalChaining() {
        let input = "foo? .bar"
        let output = "foo?.bar"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceBetweenForcedChaining() {
        let input = "foo! .bar"
        let output = "foo!.bar"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceBetweenMultipleOptionalChaining() {
        let input = "foo??! .bar"
        let output = "foo??!.bar"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSplitLineOptionalChaining() {
        let input = "foo?\n    .bar"
        let output = "foo?\n    .bar"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSplitLineMultipleOptionalChaining() {
        let input = "foo??!\n    .bar"
        let output = "foo??!\n    .bar"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenNullCoalescingAndDot() {
        let input = "foo ?? .bar()"
        let output = "foo ?? .bar()"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAroundFailableInit() {
        let input = "init?()"
        let output = "init?()"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAroundImplictlyUnwrappedFailableInit() {
        let input = "init!()"
        let output = "init!()"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAroundFailableInitWithGenerics() {
        let input = "init?<T>()"
        let output = "init?<T>()"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAroundImplictlyUnwrappedFailableInitWithGenerics() {
        let input = "init!<T>()"
        let output = "init!<T>()"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testAsSpaceAfterOptionalAs() {
        let input = "foo as?[String]"
        let output = "foo as? [String]"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testAsSpaceAfterForcedAs() {
        let input = "foo as![String]"
        let output = "foo as! [String]"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAroundGenerics() {
        let input = "Array<String>"
        let output = "Array<String>"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundReturnTypeArrow() {
        let input = "foo() ->Bool"
        let output = "foo() -> Bool"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundCommentInInfixExpression() {
        let input = "foo/* hello */-bar"
        let output = "foo/* hello */ - bar"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundCommentInPrefixExpression() {
        let input = "a + /* hello */ -bar"
        let output = "a + /* hello */ -bar"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundCommentsInInfixExpression() {
        let input = "a/* */+/* */b"
        let output = "a/* */ + /* */b"
        XCTAssertEqual(format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: noConsecutiveSpaces

    func testNoConsecutiveSpaces() {
        let input = "let foo  = bar"
        let output = "let foo = bar"
        XCTAssertEqual(format(input, rules: [noConsecutiveSpaces]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoConsecutiveSpacesDoesntStripIndent() {
        let input = "{\n    let foo  = bar\n}"
        let output = "{\n    let foo = bar\n}"
        XCTAssertEqual(format(input, rules: [noConsecutiveSpaces]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoConsecutiveSpacesDoesntAffectMultilineComments() {
        let input = "/*    comment  */"
        let output = "/*    comment  */"
        XCTAssertEqual(format(input, rules: [noConsecutiveSpaces]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoConsecutiveSpacesDoesntAffectNestedMultilineComments() {
        let input = "/*  foo  /*  bar  */  baz  */"
        let output = "/*  foo  /*  bar  */  baz  */"
        XCTAssertEqual(format(input, rules: [noConsecutiveSpaces]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoConsecutiveSpacesDoesntAffectSingleLineComments() {
        let input = "//    foo  bar"
        let output = "//    foo  bar"
        XCTAssertEqual(format(input, rules: [noConsecutiveSpaces]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: noTrailingWhitespace

    func testNoTrailingWhitespace() {
        let input = "foo  \nbar"
        let output = "foo\nbar"
        XCTAssertEqual(format(input, rules: [noTrailingWhitespace]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoTrailingWhitespaceAtEndOfFile() {
        let input = "foo  "
        let output = "foo"
        XCTAssertEqual(format(input, rules: [noTrailingWhitespace]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoTrailingWhitespaceInMultilineComments() {
        let input = "/*foo  \n bar  */"
        let output = "/*foo\n bar  */"
        XCTAssertEqual(format(input, rules: [noTrailingWhitespace]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoTrailingWhitespaceInSingleLineComments() {
        let input = "//foo  \n//bar  "
        let output = "//foo\n//bar"
        XCTAssertEqual(format(input, rules: [noTrailingWhitespace]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: noConsecutiveBlankLines

    func testNoConsecutiveBlankLines() {
        let input = "foo\n\n  \nbar"
        let output = "foo\n\nbar"
        XCTAssertEqual(format(input, rules: [noConsecutiveBlankLines]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoConsecutiveBlankLinesAtEndOfFile() {
        let input = "foo\n\n\n"
        let output = "foo\n\n"
        XCTAssertEqual(format(input, rules: [noConsecutiveBlankLines]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoConsecutiveBlankLinesAtStartOfFile() {
        let input = "\n\n\nfoo"
        let output = "\n\nfoo"
        XCTAssertEqual(format(input, rules: [noConsecutiveBlankLines]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: linebreakAtEndOfFile

    func testLinebreakAtEndOfFile() {
        let input = "foo\nbar"
        let output = "foo\nbar\n"
        XCTAssertEqual(format(input, rules: [linebreakAtEndOfFile]), output)
        XCTAssertEqual(format(input, rules: defaultRules), output)
    }

    // MARK: indent parens

    func testSimpleScope() {
        let input = "foo(\nbar\n)"
        let output = "foo(\n    bar\n)"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNestedScope() {
        let input = "foo(\nbar {\n}\n)"
        let output = "foo(\n    bar {\n    }\n)"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNestedScopeOnSameLine() {
        let input = "foo(bar(\nbaz\n))"
        let output = "foo(bar(\n    baz\n))"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testClosingScopeAfterContent() {
        let input = "foo(\nbar)"
        let output = "foo(\n    bar)"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testClosingNestedScopeAfterContent() {
        let input = "foo(bar(\nbaz))"
        let output = "foo(bar(\n    baz))"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedFunctionArguments() {
        let input = "foo(\nbar,\nbaz\n)"
        let output = "foo(\n    bar,\n    baz\n)"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: indent braces

    func testElseClauseIndenting() {
        let input = "if x {\nbar\n} else {\nbaz\n}"
        let output = "if x {\n    bar\n} else {\n    baz\n}"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoIndentBlankLines() {
        let input = "{\n\n}"
        let output = "{\n\n}"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNestedBraces() {
        let input = "({\n//foo\n}, {\n//bar\n})"
        let output = "({\n    //foo\n}, {\n    //bar\n})"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testBraceIndentAfterComment() {
        let input = "if foo { //comment\nbar\n}"
        let output = "if foo { //comment\n    bar\n}"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testBraceIndentAfterClosingScope() {
        let input = "foo(bar(baz), {\nquux\nbleem\n})"
        let output = "foo(bar(baz), {\n    quux\n    bleem\n})"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testBraceIndentAfterLineWithParens() {
        let input = "({\nfoo()\nbar\n})"
        let output = "({\n    foo()\n    bar\n})"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: indent switch/case

    func testSwitchCaseIndenting() {
        let input = "switch x {\ncase foo:\nbreak\ncase bar:\nbreakdefault:\nbreak\n}"
        let output = "switch x {\ncase foo:\n    break\ncase bar:\n    breakdefault:\n    break\n}"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSwitchWrappedCaseIndenting() {
        let input = "switch x {\ncase foo,\nbar,\n    baz:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\ncase foo,\n    bar,\n    baz:\n    break\ndefault:\n    break\n}"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testEnumCaseIndenting() {
        let input = "enum Foo {\ncase Bar\ncase Baz\n}"
        let output = "enum Foo {\n    case Bar\n    case Baz\n}"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testGenericEnumCaseIndenting() {
        let input = "enum Foo<T> {\ncase Bar\ncase Baz\n}"
        let output = "enum Foo<T> {\n    case Bar\n    case Baz\n}"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: indent wrapped line

    func testWrappedLineAfterOperator() {
        let input = "if x {\nlet y = foo +\nbar\n}"
        let output = "if x {\n    let y = foo +\n        bar\n}"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLineAfterComma() {
        let input = "let a = b,\nb = c"
        let output = "let a = b,\n    b = c"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedBeforeComma() {
        let input = "let a = b\n, b = c"
        let output = "let a = b\n    , b = c"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLineAfterCommaInsideArray() {
        let input = "[\nfoo,\nbar,\n]"
        let output = "[\n    foo,\n    bar,\n]"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLineBeforeCommaInsideArray() {
        let input = "[\nfoo\n, bar,\n]"
        let output = "[\n    foo\n    , bar,\n]"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLineAfterCommaInsideInlineArray() {
        let input = "[foo,\nbar]"
        let output = "[foo,\n    bar]"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLineBeforeCommaInsideInlineArray() {
        let input = "[foo\n, bar]"
        let output = "[foo\n    , bar]"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoDoubleIndentOfWrapAfterAsAfterOpenScope() {
        let input = "(foo as\nBar)"
        let output = "(foo as\n    Bar)"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoDoubleIndentOfWrapBeforeAsAfterOpenScope() {
        let input = "(foo\nas Bar)"
        let output = "(foo\n    as Bar)"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoDoubleIndentWhenScopesSeparatedByWrap() {
        let input = "(foo\nas Bar {\nbaz\n})"
        let output = "(foo\n    as Bar {\n    baz\n})"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoPermanentReductionInScopeAfterWrap() {
        let input = "{ foo\nas Bar\nlet baz = 5\n}"
        let output = "{ foo\n    as Bar\n    let baz = 5\n}"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLineBeforeOperator() {
        let input = "if x {\nlet y = foo\n+ bar\n}"
        let output = "if x {\n    let y = foo\n        + bar\n}"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLineAfterForKeyword() {
        let input = "for\ni in 0 ..< 5 {}"
        let output = "for\n    i in 0 ..< 5 {}"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLineAfterDot() {
        let input = "let foo = bar.\nbaz"
        let output = "let foo = bar.\n    baz"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLineBeforeDot() {
        let input = "let foo = bar\n.baz"
        let output = "let foo = bar\n    .baz"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLineAfterComment() {
        let input = "foo = bar && // comment\nbaz"
        let output = "foo = bar && // comment\n    baz"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLineInClosure() {
        let input = "forEach { item in\nprint(item)\n}"
        let output = "forEach { item in\n    print(item)\n}"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testConsecutiveWraps() {
        let input = "let a = b +\nc +\nd"
        let output = "let a = b +\n    c +\n    d"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrapReset() {
        let input = "let a = b +\nc +\nd\nlet a = b +\nc +\nd"
        let output = "let a = b +\n    c +\n    d\nlet a = b +\n    c +\n    d"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testIndentIfCase() {
        let input = "{\nif case .Foo = error {}\n}"
        let output = "{\n    if case .Foo = error {}\n}"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testIndentElseAfterComment() {
        let input = "if x {}\n//comment\nelse {}"
        let output = "if x {}\n//comment\nelse {}"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLinesWithComments() {
        let input = "let foo = bar ||\n//baz||\nquux"
        let output = "let foo = bar ||\n    //baz||\n    quux"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: indent comments

    func testCommentIndenting() {
        let input = "/* foo\nbar */"
        let output = "/* foo\n bar */"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testCommentIndentingWithTrailingClose() {
        let input = "/*\nfoo\n*/"
        let output = "/*\n foo\n */"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNestedCommentIndenting() {
        let input = "/*foo\n/*\nbar\n*/\n*/"
        let output = "/*foo\n /*\n  bar\n  */\n */"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: indent #if/#else/#elseif/#endif

    func testIfEndifIndenting() {
        let input = "#if x\n//foo\n#endif"
        let output = "#if x\n    //foo\n#endif"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testIfElseEndifIndenting() {
        let input = "#if x\n//foo\n#else\n//bar\n#endif"
        let output = "#if x\n    //foo\n#else\n    //bar\n#endif"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testIfElseifEndifIndenting() {
        let input = "#if x\n//foo\n#elseif y\n//bar\n#endif"
        let output = "#if x\n    //foo\n#elseif y\n    //bar\n#endif"
        XCTAssertEqual(format(input, rules: [indent]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: knrBraces

    func testAllmanBracesAreConverted() {
        let input = "func foo()\n{\n    statement\n}"
        let output = "func foo() {\n    statement\n}"
        XCTAssertEqual(format(input, rules: [knrBraces]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testBracesAfterComment() {
        let input = "func foo() //comment\n{\n    statement\n}"
        let output = "func foo() { //comment\n    statement\n}"
        XCTAssertEqual(format(input, rules: [knrBraces]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testBracesAfterMultilineComment() {
        let input = "func foo() /* comment/ncomment */\n{\n    statement\n}"
        let output = "func foo() { /* comment/ncomment */\n    statement\n}"
        XCTAssertEqual(format(input, rules: [knrBraces]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testExtraSpaceNotAddedBeforeBrace() {
        let input = "foo({ bar })"
        let output = "foo({ bar })"
        XCTAssertEqual(format(input, rules: [knrBraces]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: elseOnSameLine

    func testElseOnSameLine() {
        let input = "if true { 1 }\nelse { 2 }"
        let output = "if true { 1 } else { 2 }"
        XCTAssertEqual(format(input, rules: [elseOnSameLine]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testGuardNotAffectedByElseOnSameLine() {
        let input = "guard true\n    else { return }"
        let output = "guard true\n    else { return }"
        XCTAssertEqual(format(input, rules: [elseOnSameLine]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testElseOnSameLineDoesntEatPreviousStatement() {
        let input = "if true {}\nguard true else { return }"
        let output = "if true {}\nguard true else { return }"
        XCTAssertEqual(format(input, rules: [elseOnSameLine]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: trailingCommas

    func testCommasAddedToSingleItem() {
        let input = "[\n    foo\n]"
        let output = "[\n    foo,\n]"
        XCTAssertEqual(format(input, rules: [trailingCommas]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testCommasAddedToLastItem() {
        let input = "[\n    foo,\n    bar\n]"
        let output = "[\n    foo,\n    bar,\n]"
        XCTAssertEqual(format(input, rules: [trailingCommas]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testCommasAddedToDictionary() {
        let input = "[\n    foo: bar\n]"
        let output = "[\n    foo: bar,\n]"
        XCTAssertEqual(format(input, rules: [trailingCommas]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testCommasNotAddedToInlineArray() {
        let input = "[foo, bar]"
        let output = "[foo, bar]"
        XCTAssertEqual(format(input, rules: [trailingCommas]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testCommasNotAddedToInlineDictionary() {
        let input = "[foo: bar]"
        let output = "[foo: bar]"
        XCTAssertEqual(format(input, rules: [trailingCommas]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testCommasNotAddedToSubscript() {
        let input = "foo[bar]"
        let output = "foo[bar]"
        XCTAssertEqual(format(input, rules: [trailingCommas]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: todos

    func testMarkIsUpdated() {
        let input = "//MARK foo"
        let output = "//MARK: foo"
        XCTAssertEqual(format(input, rules: [todos]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testTodoIsUpdated() {
        let input = "// TODO foo"
        let output = "// TODO: foo"
        XCTAssertEqual(format(input, rules: [todos]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testFixmeIsUpdated() {
        let input = "//    FIXME foo"
        let output = "//    FIXME: foo"
        XCTAssertEqual(format(input, rules: [todos]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testMarkWithColonSeparatedBySpace() {
        let input = "//MARK : foo"
        let output = "//MARK: foo"
        XCTAssertEqual(format(input, rules: [todos]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testMarkWithNoSpaceAfterColon() {
        // NOTE: this was an unintended side-effect, but I like it
        let input = "//MARK:foo"
        let output = "//MARK: foo"
        XCTAssertEqual(format(input, rules: [todos]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testCorrectMarkIsIgnored() {
        let input = "//MARK: foo"
        let output = "//MARK: foo"
        XCTAssertEqual(format(input, rules: [todos]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testMarkInsideMultilineComment() {
        let input = "/* MARK foo */"
        let output = "/* MARK: foo */"
        XCTAssertEqual(format(input, rules: [todos]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: semicolons

    func testSemicolonRemovedAtEndOfLine() {
        let input = "print(\"hello\");\n"
        let output = "print(\"hello\")\n"
        XCTAssertEqual(format(input, rules: [semicolons]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSemicolonRemovedAtStartOfLine() {
        let input = "\n;print(\"hello\")"
        let output = "\nprint(\"hello\")"
        XCTAssertEqual(format(input, rules: [semicolons]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSemicolonRemovedAtEndOfProgram() {
        let input = "print(\"hello\");"
        let output = "print(\"hello\")"
        XCTAssertEqual(format(input, rules: [semicolons]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSemicolonRemovedAtStartOfProgram() {
        let input = ";print(\"hello\")"
        let output = "print(\"hello\")"
        XCTAssertEqual(format(input, rules: [semicolons]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testIgnoreInlineSemicolon() {
        let input = "print(\"hello\"); print(\"goodbye\")"
        let output = "print(\"hello\"); print(\"goodbye\")"
        let options = FormatOptions(allowInlineSemicolons: true)
        XCTAssertEqual(format(input, rules: [semicolons], options: options), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    func testReplaceInlineSemicolon() {
        let input = "print(\"hello\"); print(\"goodbye\")"
        let output = "print(\"hello\")\nprint(\"goodbye\")"
        let options = FormatOptions(allowInlineSemicolons: false)
        XCTAssertEqual(format(input, rules: [semicolons], options: options), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    func testReplaceSemicolonFollowedByComment() {
        let input = "print(\"hello\"); //comment\nprint(\"goodbye\")"
        let output = "print(\"hello\") //comment\nprint(\"goodbye\")"
        let options = FormatOptions(allowInlineSemicolons: true)
        XCTAssertEqual(format(input, rules: [semicolons], options: options), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    func testSemicolonsNotReplacedInForLoop() {
        let input = "for (i = 0; i < 5; i++)"
        let output = "for (i = 0; i < 5; i++)"
        XCTAssertEqual(format(input, rules: [semicolons]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSemicolonNotReplacedAfterReturn() {
        let input = "return;\nfoo()"
        let output = "return;\nfoo()"
        XCTAssertEqual(format(input, rules: [semicolons]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSemicolonReplacedAfterReturnIfEndOfScope() {
        let input = "{ return; }"
        let output = "{ return }"
        XCTAssertEqual(format(input, rules: [semicolons]), output)
        XCTAssertEqual(format(input + "\n", rules: defaultRules), output + "\n")
    }
}
