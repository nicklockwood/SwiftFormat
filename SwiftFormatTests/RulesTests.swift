//
//  RulesTests.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 12/08/2016.
//  Copyright 2016 Nick Lockwood
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

class RulesTests: XCTestCase {

    // MARK: spaceAroundParens

    func testSpaceAfterSet() {
        let input = "private(set)var foo: Int"
        let output = "private(set) var foo: Int"
        XCTAssertEqual(try! format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenParenAndClass() {
        let input = "@objc(XYZFoo)class foo"
        let output = "@objc(XYZFoo) class foo"
        XCTAssertEqual(try! format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenConventionAndBlock() {
        let input = "@convention(block)() -> Void"
        let output = "@convention(block) () -> Void"
        XCTAssertEqual(try! format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenAutoclosureEscapingAndBlock() { // swift 2.3 only
        let input = "@autoclosure(escaping)() -> Void"
        let output = "@autoclosure(escaping) () -> Void"
        XCTAssertEqual(try! format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenConventionAndEscaping() {
        let input = "@convention(block) @escaping () -> Void"
        let output = "@convention(block) @escaping () -> Void"
        XCTAssertEqual(try! format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenParenAndAs() {
        let input = "(foo) as? String"
        let output = "(foo) as? String"
        XCTAssertEqual(try! format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAfterParenAtEndOfFile() {
        let input = "(foo)"
        let output = "(foo)"
        XCTAssertEqual(try! format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenParenAndFoo() {
        let input = "func foo ()"
        let output = "func foo()"
        XCTAssertEqual(try! format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceBetweenParenAndInit() {
        let input = "init ()"
        let output = "init()"
        XCTAssertEqual(try! format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceBetweenObjcAndSelector() {
        let input = "@objc (XYZFoo) class foo"
        let output = "@objc(XYZFoo) class foo"
        XCTAssertEqual(try! format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceBetweenHashSelectorAndBrace() {
        let input = "#selector(self.foo)"
        let output = "#selector(self.foo)"
        XCTAssertEqual(try! format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceBetweenHashKeyPathAndBrace() {
        let input = "#keyPath (self.foo)"
        let output = "#keyPath(self.foo)"
        XCTAssertEqual(try! format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceBetweenPrivateAndSet() {
        let input = "private (set) var foo: Int"
        let output = "private(set) var foo: Int"
        XCTAssertEqual(try! format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenLetAndTuple() {
        let input = "if let (foo, bar) = baz"
        let output = "if let (foo, bar) = baz"
        XCTAssertEqual(try! format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenIfAndCondition() {
        let input = "if(a || b) == true {}"
        let output = "if (a || b) == true {}"
        XCTAssertEqual(try! format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceBetweenArrayLiteralAndParen() {
        let input = "[String] ()"
        let output = "[String]()"
        XCTAssertEqual(try! format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoRemoveSpaceBetweenCaptureListAndArguments() {
        let input = "{ [weak self] (foo) in }"
        let output = "{ [weak self] (foo) in }"
        XCTAssertEqual(try! format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testAddSpaceBetweenCaptureListAndArguments() {
        let input = "{ [weak self](foo) in }"
        let output = "{ [weak self] (foo) in }"
        XCTAssertEqual(try! format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenClosingParenAndOpenBrace() {
        let input = "func foo(){ foo }"
        let output = "func foo() { foo }"
        XCTAssertEqual(try! format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceBetweenClosingBraceAndParens() {
        let input = "{ block } ()"
        let output = "{ block }()"
        XCTAssertEqual(try! format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testDontRemoveSpaceBetweenOpeningBraceAndParens() {
        let input = "a = (b + c)"
        let output = "a = (b + c)"
        XCTAssertEqual(try! format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testKeywordAsIdentifierParensSpacing() {
        let input = "if foo.let (foo, bar)"
        let output = "if foo.let(foo, bar)"
        XCTAssertEqual(try! format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAfterInoutParam() {
        let input = "func foo(bar: inout(Int, String)) {}"
        let output = "func foo(bar: inout (Int, String)) {}"
        XCTAssertEqual(try! format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAfterEscapingAttribute() {
        let input = "func foo(bar: @escaping() -> Void)"
        let output = "func foo(bar: @escaping () -> Void)"
        XCTAssertEqual(try! format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAfterAutoclosureAttribute() {
        let input = "func foo(bar: @autoclosure () -> Void)"
        let output = "func foo(bar: @autoclosure () -> Void)"
        XCTAssertEqual(try! format(input, rules: [spaceAroundParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: spaceInsideParens

    func testSpaceInsideParens() {
        let input = "( 1, ( 2, 3 ) )"
        let output = "(1, (2, 3))"
        XCTAssertEqual(try! format(input, rules: [spaceInsideParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: spaceAroundBrackets

    func testSubscriptNoAddSpacing() {
        let input = "foo[bar] = baz"
        let output = "foo[bar] = baz"
        XCTAssertEqual(try! format(input, rules: [spaceAroundBrackets]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSubscriptRemoveSpacing() {
        let input = "foo [bar] = baz"
        let output = "foo[bar] = baz"
        XCTAssertEqual(try! format(input, rules: [spaceAroundBrackets]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testArrayLiteralSpacing() {
        let input = "foo = [bar, baz]"
        let output = "foo = [bar, baz]"
        XCTAssertEqual(try! format(input, rules: [spaceAroundBrackets]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testAsArrayCastingSpacing() {
        let input = "foo as[String]"
        let output = "foo as [String]"
        XCTAssertEqual(try! format(input, rules: [spaceAroundBrackets]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testAsOptionalArrayCastingSpacing() {
        let input = "foo as? [String]"
        let output = "foo as? [String]"
        XCTAssertEqual(try! format(input, rules: [spaceAroundBrackets]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testIsArrayTestingSpacing() {
        let input = "if foo is[String]"
        let output = "if foo is [String]"
        XCTAssertEqual(try! format(input, rules: [spaceAroundBrackets]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testKeywordAsIdentifierBracketSpacing() {
        let input = "if foo.is[String]"
        let output = "if foo.is[String]"
        XCTAssertEqual(try! format(input, rules: [spaceAroundBrackets]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: spaceInsideBrackets

    func testSpaceInsideBrackets() {
        let input = "foo[ 5 ]"
        let output = "foo[5]"
        XCTAssertEqual(try! format(input, rules: [spaceInsideBrackets]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: spaceAroundBraces

    func testSpaceAroundTrailingClosure() {
        let input = "if x{ y }else{ z }"
        let output = "if x { y } else { z }"
        XCTAssertEqual(try! format(input, rules: [spaceAroundBraces]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAroundClosureInsiderParens() {
        let input = "foo({ $0 == 5 })"
        let output = "foo({ $0 == 5 })"
        XCTAssertEqual(try! format(input, rules: [spaceAroundBraces]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoExtraSpaceAroundBracesAtStartOrEndOfFile() {
        let input = "{ foo }"
        let output = "{ foo }"
        XCTAssertEqual(try! format(input, rules: [spaceAroundBraces]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundBracesAfterOptionalProperty() {
        let input = "var: Foo?{}"
        let output = "var: Foo? {}"
        XCTAssertEqual(try! format(input, rules: [spaceAroundBraces]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundBracesAfterImplicitlyUnwrappedProperty() {
        let input = "var: Foo!{}"
        let output = "var: Foo! {}"
        XCTAssertEqual(try! format(input, rules: [spaceAroundBraces]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundBracesAfterNumber() {
        let input = "if x = 5{}"
        let output = "if x = 5 {}"
        XCTAssertEqual(try! format(input, rules: [spaceAroundBraces]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundBracesAfterString() {
        let input = "if x = \"\"{}"
        let output = "if x = \"\" {}"
        XCTAssertEqual(try! format(input, rules: [spaceAroundBraces]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: spaceInsideBraces

    func testSpaceInsideBraces() {
        let input = "foo({bar})"
        let output = "foo({ bar })"
        XCTAssertEqual(try! format(input, rules: [spaceInsideBraces]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoExtraSpaceInsidebraces() {
        let input = "{ foo }"
        let output = "{ foo }"
        XCTAssertEqual(try! format(input, rules: [spaceInsideBraces]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceInsideEmptybraces() {
        let input = "foo({ })"
        let output = "foo({})"
        XCTAssertEqual(try! format(input, rules: [spaceInsideBraces]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: spaceAroundGenerics

    func testSpaceAroundGenerics() {
        let input = "Foo <Bar <Baz>>"
        let output = "Foo<Bar<Baz>>"
        XCTAssertEqual(try! format(input, rules: [spaceAroundGenerics]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: spaceInsideGenerics

    func testSpaceInsideGenerics() {
        let input = "Foo< Bar< Baz > >"
        let output = "Foo<Bar<Baz>>"
        XCTAssertEqual(try! format(input, rules: [spaceInsideGenerics]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: spaceAroundOperators

    func testSpaceAfterColon() {
        let input = "let foo:Bar = 5"
        let output = "let foo: Bar = 5"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenOptionalAndDefaultValue() {
        let input = "let foo: String?=nil"
        let output = "let foo: String? = nil"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenImplictlyUnwrappedOptionalAndDefaultValue() {
        let input = "let foo: String!=nil"
        let output = "let foo: String! = nil"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenOptionalAndDefaultValueInFunction() {
        let input = "func foo(bar: String?=nil) {}"
        let output = "func foo(bar: String? = nil) {}"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAddedAfterColonInSelector() {
        let input = "@objc(foo:bar:)"
        let output = "@objc(foo:bar:)"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAfterComma() {
        let input = "let foo = [1,2,3]"
        let output = "let foo = [1, 2, 3]"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenColonAndEnumValue() {
        let input = "[.Foo:.Bar]"
        let output = "[.Foo: .Bar]"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenCommaAndEnumValue() {
        let input = "[.Foo,.Bar]"
        let output = "[.Foo, .Bar]"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenSemicolonAndEnumValue() {
        let input = "statement;.Bar"
        let output = "statement; .Bar"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenEqualsAndEnumValue() {
        let input = "foo = .Bar"
        let output = "foo = .Bar"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceBeforeColon() {
        let input = "let foo : Bar = 5"
        let output = "let foo: Bar = 5"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBeforeColonInTernary() {
        let input = "foo ? bar : baz"
        let output = "foo ? bar : baz"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testTernaryOfEnumValues() {
        let input = "foo ? .Bar : .Baz"
        let output = "foo ? .Bar : .Baz"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBeforeColonInNestedTernary() {
        let input = "foo ? (hello + a ? b: c) : baz"
        let output = "foo ? (hello + a ? b : c) : baz"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceBeforeComma() {
        let input = "let foo = [1 , 2 , 3]"
        let output = "let foo = [1, 2, 3]"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAtStartOfLine() {
        let input = "foo\n    ,bar"
        let output = "foo\n    , bar"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundInfixMinus() {
        let input = "foo-bar"
        let output = "foo - bar"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAroundPrefixMinus() {
        let input = "foo + -bar"
        let output = "foo + -bar"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundLessThan() {
        let input = "foo<bar"
        let output = "foo < bar"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testDontAddSpaceAroundDot() {
        let input = "foo.bar"
        let output = "foo.bar"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testRemoveSpaceAroundDot() {
        let input = "foo . bar"
        let output = "foo.bar"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAroundDotOnNewLine() {
        let input = "foo\n    .bar"
        let output = "foo\n    .bar"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundEnumCase() {
        let input = "case .Foo,.Bar:"
        let output = "case .Foo, .Bar:"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSwitchWithEnumCases() {
        let input = "switch x {\ncase.Foo:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\ncase .Foo:\n    break\ndefault:\n    break\n}"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundEnumReturn() {
        let input = "return.Foo"
        let output = "return .Foo"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAfterReturnAsIdentifier() {
        let input = "foo.return.Bar"
        let output = "foo.return.Bar"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundCaseLet() {
        let input = "case let.Foo(bar):"
        let output = "case let .Foo(bar):"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundEnumArgument() {
        let input = "foo(with:.Bar)"
        let output = "foo(with: .Bar)"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBeforeEnumCaseInsideClosure() {
        let input = "{ .Bar() }"
        let output = "{ .Bar() }"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAroundOptionalChaining() {
        let input = "foo?.bar"
        let output = "foo?.bar"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAroundMultipleOptionalChaining() {
        let input = "foo??!?!.bar"
        let output = "foo??!?!.bar"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAroundForcedChaining() {
        let input = "foo!.bar"
        let output = "foo!.bar"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceBetweenOptionalChaining() {
        let input = "foo? .bar"
        let output = "foo?.bar"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceBetweenForcedChaining() {
        let input = "foo! .bar"
        let output = "foo!.bar"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceBetweenMultipleOptionalChaining() {
        let input = "foo??! .bar"
        let output = "foo??!.bar"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSplitLineOptionalChaining() {
        let input = "foo?\n    .bar"
        let output = "foo?\n    .bar"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSplitLineMultipleOptionalChaining() {
        let input = "foo??!\n    .bar"
        let output = "foo??!\n    .bar"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceBetweenNullCoalescingAndDot() {
        let input = "foo ?? .bar()"
        let output = "foo ?? .bar()"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAroundFailableInit() {
        let input = "init?()"
        let output = "init?()"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAroundImplictlyUnwrappedFailableInit() {
        let input = "init!()"
        let output = "init!()"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAroundFailableInitWithGenerics() {
        let input = "init?<T>()"
        let output = "init?<T>()"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAroundImplictlyUnwrappedFailableInitWithGenerics() {
        let input = "init!<T>()"
        let output = "init!<T>()"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testAsSpaceAfterOptionalAs() {
        let input = "foo as?[String]"
        let output = "foo as? [String]"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testAsSpaceAfterForcedAs() {
        let input = "foo as![String]"
        let output = "foo as! [String]"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAroundGenerics() {
        let input = "Array<String>"
        let output = "Array<String>"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundReturnTypeArrow() {
        let input = "foo() ->Bool"
        let output = "foo() -> Bool"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundCommentInInfixExpression() {
        let input = "foo/* hello */-bar"
        let output = "foo/* hello */ - bar"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
    }

    func testSpaceAroundCommentsInInfixExpression() {
        let input = "a/* */+/* */b"
        let output = "a/* */ + /* */b"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
    }

    func testSpaceAroundCommentInPrefixExpression() {
        let input = "a + /* hello */ -bar"
        let output = "a + /* hello */ -bar"
        XCTAssertEqual(try! format(input, rules: [spaceAroundOperators]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: spaceAroundComments

    func testSpaceAroundCommentInParens() {
        let input = "(/* foo */)"
        let output = "( /* foo */ )"
        XCTAssertEqual(try! format(input, rules: [spaceAroundComments]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAroundCommentAtStartAndEndOfFile() {
        let input = "/* foo */"
        let output = "/* foo */"
        XCTAssertEqual(try! format(input, rules: [spaceAroundComments]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceAroundSingleLineComment() {
        let input = "func foo() {// comment\n}"
        let output = "func foo() { // comment\n}"
        XCTAssertEqual(try! format(input, rules: [spaceAroundComments]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: spaceInsideComments

    func testSpaceInsideMultilineComment() {
        let input = "/*foo\n bar*/"
        let output = "/* foo\n bar */"
        XCTAssertEqual(try! format(input, rules: [spaceInsideComments]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceInsideSingleLineMultilineComment() {
        let input = "/*foo*/"
        let output = "/* foo */"
        XCTAssertEqual(try! format(input, rules: [spaceInsideComments]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceInsideEmptyMultilineComment() {
        let input = "/**/"
        let output = "/**/"
        XCTAssertEqual(try! format(input, rules: [spaceInsideComments]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceInsideSingleLineComment() {
        let input = "//foo"
        let output = "// foo"
        XCTAssertEqual(try! format(input, rules: [spaceInsideComments]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceInsideMultilineHeaderdocComment() {
        let input = "/**foo\n bar*/"
        let output = "/** foo\n bar */"
        XCTAssertEqual(try! format(input, rules: [spaceInsideComments]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceInsideMultilineHeaderdocCommentType2() {
        let input = "/*!foo\n bar*/"
        let output = "/*! foo\n bar */"
        XCTAssertEqual(try! format(input, rules: [spaceInsideComments]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceInsideMultilineSwiftPlaygroundDocComment() {
        let input = "/*:foo\n bar*/"
        let output = "/*: foo\n bar */"
        XCTAssertEqual(try! format(input, rules: [spaceInsideComments]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoExtraSpaceInsideMultilineHeaderdocComment() {
        let input = "/** foo\n bar */"
        let output = "/** foo\n bar */"
        XCTAssertEqual(try! format(input, rules: [spaceInsideComments]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceInsideSingleLineHeaderdocComment() {
        let input = "///foo"
        let output = "/// foo"
        XCTAssertEqual(try! format(input, rules: [spaceInsideComments]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceInsideSingleLineHeaderdocCommentType2() {
        let input = "//!foo"
        let output = "//! foo"
        XCTAssertEqual(try! format(input, rules: [spaceInsideComments]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpaceInsideSingleLineSwiftPlaygroundDocComment() {
        let input = "//:foo"
        let output = "//: foo"
        XCTAssertEqual(try! format(input, rules: [spaceInsideComments]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoExtraSpaceInsideSingleLineHeaderdocComment() {
        let input = "/// foo"
        let output = "/// foo"
        XCTAssertEqual(try! format(input, rules: [spaceInsideComments]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testPreformattedMultilineComment() {
        let input = "/*********************\n *****Hello World*****\n *********************/"
        let output = "/*********************\n *****Hello World*****\n *********************/"
        XCTAssertEqual(try! format(input, rules: [spaceInsideComments]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAddedToFirstLineOfDocComment() {
        let input = "/**\n Comment\n */"
        let output = "/**\n Comment\n */"
        XCTAssertEqual(try! format(input, rules: [spaceInsideComments]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAddedToEmptyDocComment() {
        let input = "///"
        let output = "///"
        XCTAssertEqual(try! format(input, rules: [spaceInsideComments]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: consecutiveSpaces

    func testConsecutiveSpaces() {
        let input = "let foo  = bar"
        let output = "let foo = bar"
        XCTAssertEqual(try! format(input, rules: [consecutiveSpaces]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testConsecutiveSpacesAfterComment() {
        let input = "// comment\nfoo  bar"
        let output = "// comment\nfoo bar"
        XCTAssertEqual(try! format(input, rules: [consecutiveSpaces]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testConsecutiveSpacesDoesntStripIndent() {
        let input = "{\n    let foo  = bar\n}"
        let output = "{\n    let foo = bar\n}"
        XCTAssertEqual(try! format(input, rules: [consecutiveSpaces]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testConsecutiveSpacesDoesntAffectMultilineComments() {
        let input = "/*    comment  */"
        let output = "/*    comment  */"
        XCTAssertEqual(try! format(input, rules: [consecutiveSpaces]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testConsecutiveSpacesDoesntAffectNestedMultilineComments() {
        let input = "/*  foo  /*  bar  */  baz  */"
        let output = "/*  foo  /*  bar  */  baz  */"
        XCTAssertEqual(try! format(input, rules: [consecutiveSpaces]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testConsecutiveSpacesDoesntAffectSingleLineComments() {
        let input = "//    foo  bar"
        let output = "//    foo  bar"
        XCTAssertEqual(try! format(input, rules: [consecutiveSpaces]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: trailingWhitespace

    func testTrailingWhitespace() {
        let input = "foo  \nbar"
        let output = "foo\nbar"
        XCTAssertEqual(try! format(input, rules: [trailingWhitespace]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testTrailingWhitespaceAtEndOfFile() {
        let input = "foo  "
        let output = "foo"
        XCTAssertEqual(try! format(input, rules: [trailingWhitespace]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testTrailingWhitespaceInMultilineComments() {
        let input = "/* foo  \n bar  */"
        let output = "/* foo\n bar  */"
        XCTAssertEqual(try! format(input, rules: [trailingWhitespace]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testTrailingWhitespaceInSingleLineComments() {
        let input = "// foo  \n// bar  "
        let output = "// foo\n// bar"
        XCTAssertEqual(try! format(input, rules: [trailingWhitespace]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: consecutiveBlankLines

    func testConsecutiveBlankLines() {
        let input = "foo\n\n  \nbar"
        let output = "foo\n\nbar"
        XCTAssertEqual(try! format(input, rules: [consecutiveBlankLines]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testConsecutiveBlankLinesAtEndOfFile() {
        let input = "foo\n\n"
        let output = "foo\n"
        XCTAssertEqual(try! format(input, rules: [consecutiveBlankLines]), output)
        XCTAssertEqual(try! format(input, rules: defaultRules), output)
    }

    func testConsecutiveBlankLinesAtStartOfFile() {
        let input = "\n\n\nfoo"
        let output = "\n\nfoo"
        XCTAssertEqual(try! format(input, rules: [consecutiveBlankLines]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testFragmentWithTrailingLinebreaks() {
        let input = "func foo() {\n}\n\n\n"
        let output = "func foo() {\n}\n\n"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try! format(input, rules: [consecutiveBlankLines], options: options), output)
        XCTAssertEqual(try! format(input, rules: defaultRules, options: options), output)
    }

    // MARK: blankLinesAtEndOfScope

    func testBlankLinesRemovedAtEndOfFunction() {
        let input = "func foo() {\n    // code\n\n}"
        let output = "func foo() {\n    // code\n}"
        XCTAssertEqual(try! format(input, rules: [blankLinesAtEndOfScope]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testBlankLinesRemovedAtEndOfParens() {
        let input = "(\n    foo: Int\n\n)"
        let output = "(\n    foo: Int\n)"
        XCTAssertEqual(try! format(input, rules: [blankLinesAtEndOfScope]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testBlankLinesRemovedAtEndOfBrackets() {
        let input = "[\n    foo,\n    bar,\n\n]"
        let output = "[\n    foo,\n    bar,\n]"
        XCTAssertEqual(try! format(input, rules: [blankLinesAtEndOfScope]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testBlankLineNotRemovedBeforeElse() {
        let input = "if x {\n\n    // do something\n\n} else if y {\n\n    // do something else\n\n}"
        let output = "if x {\n\n    // do something\n\n} else if y {\n\n    // do something else\n}"
        XCTAssertEqual(try! format(input, rules: [blankLinesAtEndOfScope]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: blankLinesBetweenScopes

    func testBlankLineBetweenFunctions() {
        let input = "func foo() {\n}\nfunc bar() {\n}"
        let output = "func foo() {\n}\n\nfunc bar() {\n}"
        XCTAssertEqual(try! format(input, rules: [blankLinesBetweenScopes]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNpBlankLineBetweenPropertyAndFunction() {
        let input = "var foo: Int\nfunc bar() {\n}"
        let output = "var foo: Int\nfunc bar() {\n}"
        XCTAssertEqual(try! format(input, rules: [blankLinesBetweenScopes]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testBlankLineBetweenFunctionsIsBeforeComment() {
        let input = "func foo() {\n}\n// headerdoc\nfunc bar() {\n}"
        let output = "func foo() {\n}\n\n// headerdoc\nfunc bar() {\n}"
        XCTAssertEqual(try! format(input, rules: [blankLinesBetweenScopes]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testBlankLineBeforeAtObjCOnLineBeforeProtocol() {
        let input = "@objc\nprotocol Foo {\n}\n@objc\nprotocol Bar {\n}"
        let output = "@objc\nprotocol Foo {\n}\n\n@objc\nprotocol Bar {\n}"
        XCTAssertEqual(try! format(input, rules: [blankLinesBetweenScopes]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testBlankLineBeforeAtAvailabilityOnLineBeforeClass() {
        let input = "protocol Foo {\n}\n@available(iOS 8.0, OSX 10.10, *)\nclass Bar {\n}"
        let output = "protocol Foo {\n}\n\n@available(iOS 8.0, OSX 10.10, *)\nclass Bar {\n}"
        XCTAssertEqual(try! format(input, rules: [blankLinesBetweenScopes]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoExtraBlankLineBetweenFunctions() {
        let input = "func foo() {\n}\n\nfunc bar() {\n}"
        let output = "func foo() {\n}\n\nfunc bar() {\n}"
        XCTAssertEqual(try! format(input, rules: [blankLinesBetweenScopes]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoBlankLineBetweenFunctionsInProtocol() {
        let input = "protocol Foo {\n    func bar() -> Void\n    func baz() -> Int\n}"
        let output = "protocol Foo {\n    func bar() -> Void\n    func baz() -> Int\n}"
        XCTAssertEqual(try! format(input, rules: [blankLinesBetweenScopes]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoBlankLineInsideInitFunction() {
        let input = "init() {\n    super.init()\n}"
        let output = "init() {\n    super.init()\n}"
        XCTAssertEqual(try! format(input, rules: [blankLinesBetweenScopes]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testBlankLineAfterProtocolBeforeProperty() {
        let input = "protocol Foo {\n}\nvar bar: String"
        let output = "protocol Foo {\n}\n\nvar bar: String"
        XCTAssertEqual(try! format(input, rules: [blankLinesBetweenScopes]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoExtraBlankLineAfterSingleLineComment() {
        let input = "var foo: Bar? // comment\n\nfunc bar() {}"
        let output = "var foo: Bar? // comment\n\nfunc bar() {}"
        XCTAssertEqual(try! format(input, rules: [blankLinesBetweenScopes]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoExtraBlankLineAfterMultilineComment() {
        let input = "var foo: Bar? /* comment */\n\nfunc bar() {}"
        let output = "var foo: Bar? /* comment */\n\nfunc bar() {}"
        XCTAssertEqual(try! format(input, rules: [blankLinesBetweenScopes]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoBlankLineBeforeFuncAsIdentifier() {
        let input = "var foo: Bar?\nfoo.func() {}"
        let output = "var foo: Bar?\nfoo.func() {}"
        XCTAssertEqual(try! format(input, rules: [blankLinesBetweenScopes]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoBlankLineBetweenFunctionsWithInlineBody() {
        let input = "class Foo {\n    func foo() { print(\"foo\") }\n    func bar() { print(\"bar\") }\n}"
        let output = "class Foo {\n    func foo() { print(\"foo\") }\n    func bar() { print(\"bar\") }\n}"
        XCTAssertEqual(try! format(input, rules: [blankLinesBetweenScopes]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoBlankLineBetweenIfStatements() {
        let input = "func foo() {\n    if x {\n    }\n    if y {\n    }\n}"
        let output = "func foo() {\n    if x {\n    }\n    if y {\n    }\n}"
        XCTAssertEqual(try! format(input, rules: [blankLinesBetweenScopes]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoBlanksInsideClassFunc() {
        let input = "class func foo {\n    if x {\n    }\n    if y {\n    }\n}"
        let output = "class func foo {\n    if x {\n    }\n    if y {\n    }\n}"
        XCTAssertEqual(try! format(input, rules: [blankLinesBetweenScopes]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoBlanksInsideClassVar() {
        let input = "class var foo: Int {\n    if x {\n    }\n    if y {\n    }\n}"
        let output = "class var foo: Int {\n    if x {\n    }\n    if y {\n    }\n}"
        XCTAssertEqual(try! format(input, rules: [blankLinesBetweenScopes]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testBlankLineBetweenCalledClosures() {
        let input = "class Foo {\n    var foo = {\n    }()\n    func bar {\n    }\n}"
        let output = "class Foo {\n    var foo = {\n    }()\n\n    func bar {\n    }\n}"
        XCTAssertEqual(try! format(input, rules: [blankLinesBetweenScopes]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoBlankLineAfterCalledClosureAtEndOfScope() {
        let input = "class Foo {\n    var foo = {\n    }()\n}"
        let output = "class Foo {\n    var foo = {\n    }()\n}"
        XCTAssertEqual(try! format(input, rules: [blankLinesBetweenScopes]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoBlankLineBeforeWhileInRepeatWhile() {
        let input = "repeat\n{\n}\nwhile true\n{\n}()"
        let output = "repeat\n{\n}\nwhile true\n{\n}()"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try! format(input, rules: [blankLinesBetweenScopes], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    func testBlankLineBeforeWhileIfNotRepeatWhile() {
        let input = "func foo(x)\n{\n}\nwhile true\n{\n}"
        let output = "func foo(x)\n{\n}\n\nwhile true\n{\n}"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try! format(input, rules: [blankLinesBetweenScopes], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    // MARK: linebreakAtEndOfFile

    func testLinebreakAtEndOfFile() {
        let input = "foo\nbar"
        let output = "foo\nbar\n"
        XCTAssertEqual(try! format(input, rules: [linebreakAtEndOfFile]), output)
        XCTAssertEqual(try! format(input, rules: defaultRules), output)
    }

    // MARK: indent parens

    func testSimpleScope() {
        let input = "foo(\nbar\n)"
        let output = "foo(\n    bar\n)"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNestedScope() {
        let input = "foo(\nbar {\n}\n)"
        let output = "foo(\n    bar {\n    }\n)"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNestedScopeOnSameLine() {
        let input = "foo(bar(\nbaz\n))"
        let output = "foo(bar(\n    baz\n))"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testIndentNestedArrayLiteral() {
        let input = "foo(bar: [\n.baz,\n])"
        let output = "foo(bar: [\n    .baz,\n])"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testClosingScopeAfterContent() {
        let input = "foo(\nbar)"
        let output = "foo(\n    bar)"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testClosingNestedScopeAfterContent() {
        let input = "foo(bar(\nbaz))"
        let output = "foo(bar(\n    baz))"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedFunctionArguments() {
        let input = "foo(\nbar,\nbaz\n)"
        let output = "foo(\n    bar,\n    baz\n)"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testFunctionArgumentsWrappedAfterFirst() {
        let input = "func foo(bar: Int,\nbaz: Int)"
        let output = "func foo(bar: Int,\n         baz: Int)"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: indent specifiers

    func testNoIndentWrappedSpecifiersForProtocol() {
        let input = "@objc\nprivate\nprotocol Foo {}"
        let output = "@objc\nprivate\nprotocol Foo {}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: indent braces

    func testElseClauseIndenting() {
        let input = "if x {\nbar\n} else {\nbaz\n}"
        let output = "if x {\n    bar\n} else {\n    baz\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoIndentBlankLines() {
        let input = "{\n\n// foo\n}"
        let output = "{\n\n    // foo\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNestedBraces() {
        let input = "({\n// foo\n}, {\n// bar\n})"
        let output = "({\n    // foo\n}, {\n    // bar\n})"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testBraceIndentAfterComment() {
        let input = "if foo { // comment\nbar\n}"
        let output = "if foo { // comment\n    bar\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testBraceIndentAfterClosingScope() {
        let input = "foo(bar(baz), {\nquux\nbleem\n})"
        let output = "foo(bar(baz), {\n    quux\n    bleem\n})"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testBraceIndentAfterLineWithParens() {
        let input = "({\nfoo()\nbar\n})"
        let output = "({\n    foo()\n    bar\n})"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: indent switch/case

    func testSwitchCaseIndenting() {
        let input = "switch x {\ncase foo:\nbreak\ncase bar:\nbreak\ndefault:\nbreak\n}"
        let output = "switch x {\ncase foo:\n    break\ncase bar:\n    break\ndefault:\n    break\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSwitchWrappedCaseIndenting() {
        let input = "switch x {\ncase foo,\nbar,\n    baz:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\ncase foo,\n     bar,\n     baz:\n    break\ndefault:\n    break\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSwitchWrappedEnumCaseIndenting() {
        let input = "switch x {\ncase .foo,\n.bar,\n    .baz:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\ncase .foo,\n     .bar,\n     .baz:\n    break\ndefault:\n    break\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSwitchWrappedEnumCaseIndentingVariant2() {
        let input = "switch x {\ncase\n.foo,\n.bar,\n    .baz:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\ncase\n    .foo,\n    .bar,\n    .baz:\n    break\ndefault:\n    break\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSwitchCaseIsDictionaryIndenting() {
        let input = "switch x {\ncase foo is [Key: Value]:\nfallthrough\ndefault:\nbreak\n}"
        let output = "switch x {\ncase foo is [Key: Value]:\n    fallthrough\ndefault:\n    break\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testEnumCaseIndenting() {
        let input = "enum Foo {\ncase Bar\ncase Baz\n}"
        let output = "enum Foo {\n    case Bar\n    case Baz\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testGenericEnumCaseIndenting() {
        let input = "enum Foo<T> {\ncase Bar\ncase Baz\n}"
        let output = "enum Foo<T> {\n    case Bar\n    case Baz\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: indent wrapped line

    func testWrappedLineAfterOperator() {
        let input = "if x {\nlet y = foo +\nbar\n}"
        let output = "if x {\n    let y = foo +\n        bar\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLineAfterComma() {
        let input = "let a = b,\nb = c"
        let output = "let a = b,\n    b = c"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedBeforeComma() {
        let input = "let a = b\n, b = c"
        let output = "let a = b\n    , b = c"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLineAfterCommaInsideArray() {
        let input = "[\nfoo,\nbar,\n]"
        let output = "[\n    foo,\n    bar,\n]"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLineBeforeCommaInsideArray() {
        let input = "[\nfoo\n, bar,\n]"
        let output = "[\n    foo\n    , bar,\n]"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLineAfterCommaInsideInlineArray() {
        let input = "[foo,\nbar]"
        let output = "[foo,\n bar]"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLineBeforeCommaInsideInlineArray() {
        let input = "[foo\n, bar]"
        let output = "[foo\n , bar]"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLineAfterColonInFunction() {
        let input = "func foo(bar:\nbaz)"
        let output = "func foo(bar:\n    baz)"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoDoubleIndentOfWrapAfterAsAfterOpenScope() {
        let input = "(foo as\nBar)"
        let output = "(foo as\n    Bar)"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoDoubleIndentOfWrapBeforeAsAfterOpenScope() {
        let input = "(foo\nas Bar)"
        let output = "(foo\n    as Bar)"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testDoubleIndentWhenScopesSeparatedByWrap() {
        let input = "(foo\nas Bar {\nbaz\n})"
        let output = "(foo\n    as Bar {\n        baz\n})"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoDoubleIndentWhenScopesSeparatedByWrap() {
        let input = "(foo\nas Bar {\nbaz\n}\n)"
        let output = "(foo\n    as Bar {\n        baz\n    }\n)"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoPermanentReductionInScopeAfterWrap() {
        let input = "{ foo\nas Bar\nlet baz = 5\n}"
        let output = "{ foo\n    as Bar\n    let baz = 5\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLineBeforeOperator() {
        let input = "if x {\nlet y = foo\n+ bar\n}"
        let output = "if x {\n    let y = foo\n        + bar\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLineAfterForKeyword() {
        let input = "for\ni in range {}"
        let output = "for\n    i in range {}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLineAfterDot() {
        let input = "let foo = bar.\nbaz"
        let output = "let foo = bar.\n    baz"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLineBeforeDot() {
        let input = "let foo = bar\n.baz"
        let output = "let foo = bar\n    .baz"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLineBeforeWhere() {
        let input = "let foo = bar\nwhere foo == baz"
        let output = "let foo = bar\n    where foo == baz"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLineAfterWhere() {
        let input = "let foo = bar where\nfoo == baz"
        let output = "let foo = bar where\n    foo == baz"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLineBeforeGuardElse() {
        let input = "guard let foo = bar\nelse { return }"
        let output = "guard let foo = bar\nelse { return }"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLineAfterGuardElse() {
        // Don't indent because this case is handled by braces rule
        let input = "guard let foo = bar else\n{ return }"
        let output = "guard let foo = bar else\n{ return }"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
    }

    func testWrappedLineAfterComment() {
        let input = "foo = bar && // comment\nbaz"
        let output = "foo = bar && // comment\n    baz"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLineInClosure() {
        let input = "forEach { item in\nprint(item)\n}"
        let output = "forEach { item in\n    print(item)\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testConsecutiveWraps() {
        let input = "let a = b +\nc +\nd"
        let output = "let a = b +\n    c +\n    d"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrapReset() {
        let input = "let a = b +\nc +\nd\nlet a = b +\nc +\nd"
        let output = "let a = b +\n    c +\n    d\nlet a = b +\n    c +\n    d"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testIndentIfCase() {
        let input = "{\nif case .Foo(let msg) = error {}\n}"
        let output = "{\n    if case .Foo(let msg) = error {}\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testIndentIfCaseCommaCase() {
        let input = "{\nif case .Foo(let msg) = a,\ncase .Bar(let msg) = b {}\n}"
        let output = "{\n    if case .Foo(let msg) = a,\n        case .Bar(let msg) = b {}\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testIndentGuardCase() {
        let input = "{\nguard case .Foo = error else {}\n}"
        let output = "{\n    guard case .Foo = error else {}\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testIndentElseAfterComment() {
        let input = "if x {}\n// comment\nelse {}"
        let output = "if x {}\n// comment\nelse {}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedLinesWithComments() {
        let input = "let foo = bar ||\n // baz||\nquux"
        let output = "let foo = bar ||\n    // baz||\n    quux"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoIndentAfterAssignOperatorToVariable() {
        let input = "let greaterThan = >\nlet lessThan = <"
        let output = "let greaterThan = >\nlet lessThan = <"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoIndentAfterDefaultAsIdentifier() {
        let input = "let foo = FileManager.default\n// Comment\nlet bar = 0"
        let output = "let foo = FileManager.default\n// Comment\nlet bar = 0"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testIndentClosureStartingOnIndentedLine() {
        let input = "foo\n.bar {\nbaz()\n}"
        let output = "foo\n    .bar {\n        baz()\n    }"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNestedWrappedIfIndents() {
        let input = "if foo {\nif bar &&\n(baz ||\nquux) {\nfoo()\n}\n}"
        let output = "if foo {\n    if bar &&\n        (baz ||\n            quux) {\n        foo()\n    }\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWrappedEnumThatLooksLikeIf() {
        let input = "foo &&\n bar.if {\nfoo()\n}"
        let output = "foo &&\n    bar.if {\n        foo()\n    }"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testChainedClosureIndents() {
        let input = "foo\n.bar {\nbaz()\n}\n.bar {\nbaz()\n}"
        let output = "foo\n    .bar {\n        baz()\n    }\n    .bar {\n        baz()\n    }"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testChainedFunctionsInsideIf() {
        let input = "if foo {\nreturn bar()\n.baz()\n}"
        let output = "if foo {\n    return bar()\n        .baz()\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testChainedFunctionsInsideForLoop() {
        let input = "for x in y {\nfoo\n.bar {\nbaz()\n}\n.quux()\n}"
        let output = "for x in y {\n    foo\n        .bar {\n            baz()\n        }\n        .quux()\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testChainedFunctionsAfterAnIfStatement() {
        let input = "if foo {}\nbar\n.baz {\n}\n.quux()"
        let output = "if foo {}\nbar\n    .baz {\n    }\n    .quux()"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testIndentInsideWrappedIfStatementWithClosureCondition() {
        let input = "if foo({ 1 }) ||\nbar {\nbaz()\n}"
        let output = "if foo({ 1 }) ||\n    bar {\n    baz()\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoIndentAfterOperatorDeclaration() {
        let input = "infix operator ?=\nfunc ?=(lhs: Int, rhs: Int) -> Bool {}"
        let output = "infix operator ?=\nfunc ?=(lhs: Int, rhs: Int) -> Bool {}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testIndentEnumDictionaryKeysAndValues() {
        let input = "[\n.foo:\n.bar,\n.baz:\n.quux,]"
        let output = "[\n    .foo:\n        .bar,\n    .baz:\n        .quux,]"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: indent comments

    func testCommentIndenting() {
        let input = "/* foo\nbar */"
        let output = "/* foo\n bar */"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testCommentIndentingWithTrailingClose() {
        let input = "/*\nfoo\n*/"
        let output = "/*\n foo\n */"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNestedCommentIndenting() {
        let input = "/* foo\n/*\nbar\n*/\n*/"
        let output = "/* foo\n /*\n  bar\n  */\n */"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testCommentIndentingDisabled() {
        let input = "  /**\n  hello\n    - world\n  */"
        let output = "  /**\n  hello\n    - world\n  */"
        let options = FormatOptions(indentComments: false, fragment: true)
        XCTAssertEqual(try! format(input, rules: [indent], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    // MARK: indent #if/#else/#elseif/#endif

    func testIfEndifIndenting() {
        let input = "#if x\n// foo\n#endif"
        let output = "#if x\n    // foo\n#endif"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testIfElseEndifIndenting() {
        let input = "#if x\n// foo\n#else\n// bar\n#endif"
        let output = "#if x\n    // foo\n#else\n    // bar\n#endif"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testIfElseifEndifIndenting() {
        let input = "#if x\n// foo\n#elseif y\n// bar\n#endif"
        let output = "#if x\n    // foo\n#elseif y\n    // bar\n#endif"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: indent expression after return

    func testIndentIdentifierAfterReturn() {
        let input = "if foo {\n    return\n        bar\n}"
        let output = "if foo {\n    return\n        bar\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testIndentEnumValueAfterReturn() {
        let input = "if foo {\n    return\n        .bar\n}"
        let output = "if foo {\n    return\n        .bar\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testIndentMultilineExpressionAfterReturn() {
        let input = "if foo {\n    return\n        bar +\n        baz\n}"
        let output = "if foo {\n    return\n        bar +\n        baz\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testDontIndentClosingBraceAfterReturn() {
        let input = "if foo {\n    return\n}"
        let output = "if foo {\n    return\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testDontIndentCaseAfterReturn() {
        let input = "switch foo {\ncase bar:\n    return\ncase baz:\n    return\n}"
        let output = "switch foo {\ncase bar:\n    return\ncase baz:\n    return\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testDontIndentIfAfterReturn() {
        let input = "if foo {\n    return\n    if bar {}\n}"
        let output = "if foo {\n    return\n    if bar {}\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testDontIndentFuncAfterReturn() {
        let input = "if foo {\n    return\n    func bar() {}\n}"
        let output = "if foo {\n    return\n    func bar() {}\n}"
        XCTAssertEqual(try! format(input, rules: [indent]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: indent fragments

    func testIndentFragment() {
        let input = "   func foo() {\nbar()\n}"
        let output = "   func foo() {\n       bar()\n   }"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try! format(input, rules: [indent], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    func testIndentFragmentAfterBlankLines() {
        let input = "\n\n   func foo() {\nbar()\n}"
        let output = "\n\n   func foo() {\n       bar()\n   }"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try! format(input, rules: [indent], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    func testUnterminatedFragment() {
        let input = "class Foo {\n  \nfunc foo() {\nbar()\n}"
        let output = "class Foo {\n\n    func foo() {\n        bar()\n    }"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try! format(input, rules: [indent], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: [indent, linebreakAtEndOfFile], options: options), output + "\n")
    }

    func testOverTerminatedFragment() {
        let input = "   func foo() {\nbar()\n}\n\n}"
        let output = "   func foo() {\n       bar()\n   }\n\n}"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try! format(input, rules: [indent], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    func testDontCorruptPartialFragment() {
        let input = "    } foo {\n        bar\n    }\n}"
        let output = "    } foo {\n        bar\n    }\n}"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try! format(input, rules: [indent], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    func testDontCorruptPartialFragment2() {
        let input = "        return completionHandler(nil)\n    }\n}"
        let output = "        return completionHandler(nil)\n    }\n}"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try! format(input, rules: [indent], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    // MARK: knr braces

    func testAllmanBracesAreConverted() {
        let input = "func foo()\n{\n    statement\n}"
        let output = "func foo() {\n    statement\n}"
        XCTAssertEqual(try! format(input, rules: [braces]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testKnRBracesAfterComment() {
        let input = "func foo() // comment\n{\n    statement\n}"
        let output = "func foo() { // comment\n    statement\n}"
        XCTAssertEqual(try! format(input, rules: [braces]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testKnRBracesAfterMultilineComment() {
        let input = "func foo() /* comment/ncomment */\n{\n    statement\n}"
        let output = "func foo() { /* comment/ncomment */\n    statement\n}"
        XCTAssertEqual(try! format(input, rules: [braces]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testKnRExtraSpaceNotAddedBeforeBrace() {
        let input = "foo({ bar })"
        let output = "foo({ bar })"
        XCTAssertEqual(try! format(input, rules: [braces]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: allman braces

    func testKnRBracesAreConverted() {
        let input = "func foo() {\n    statement\n}"
        let output = "func foo()\n{\n    statement\n}"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try! format(input, rules: [braces], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    func testAllmanBraceInsideParensNotConverted() {
        let input = "foo({\n    bar\n})"
        let output = "foo({\n    bar\n})"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try! format(input, rules: [braces], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    func testAllmanBraceDoClauseIndent() {
        let input = "do {\n    foo\n}"
        let output = "do\n{\n    foo\n}"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try! format(input, rules: [braces], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    func testAllmanBraceCatchClauseIndent() {
        let input = "do {\n    try foo\n}\ncatch {\n}"
        let output = "do\n{\n    try foo\n}\ncatch\n{\n}"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try! format(input, rules: [braces], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    func testAllmanBraceRepeatWhileIndent() {
        let input = "repeat {\n    foo\n}\nwhile x"
        let output = "repeat\n{\n    foo\n}\nwhile x"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try! format(input, rules: [braces], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    // MARK: elseOrCatchOnSameLine

    func testelseOrCatchOnSameLine() {
        let input = "if true {\n    1\n}\nelse { 2 }"
        let output = "if true {\n    1\n} else { 2 }"
        XCTAssertEqual(try! format(input, rules: [elseOrCatchOnSameLine]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testelseOrCatchOnSameLineOnlyAppliedToDanglingBrace() {
        let input = "if true { 1 }\nelse { 2 }"
        let output = "if true { 1 }\nelse { 2 }"
        XCTAssertEqual(try! format(input, rules: [elseOrCatchOnSameLine]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testGuardNotAffectedByelseOrCatchOnSameLine() {
        let input = "guard true\nelse { return }"
        let output = "guard true\nelse { return }"
        XCTAssertEqual(try! format(input, rules: [elseOrCatchOnSameLine]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testelseOrCatchOnSameLineDoesntEatPreviousStatement() {
        let input = "if true {}\nguard true else { return }"
        let output = "if true {}\nguard true else { return }"
        XCTAssertEqual(try! format(input, rules: [elseOrCatchOnSameLine]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testElseNotOnSameLineForAllman() {
        let input = "if true\n{\n    1\n} else { 2 }"
        let output = "if true\n{\n    1\n}\nelse { 2 }"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try! format(input, rules: [elseOrCatchOnSameLine], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    func testGuardNotAffectedByelseOrCatchOnSameLineForAllman() {
        let input = "guard true else { return }"
        let output = "guard true else { return }"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try! format(input, rules: [elseOrCatchOnSameLine], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    func testRepeatWhileNotOnSameLineForAllman() {
        let input = "repeat\n{\n    foo\n} while x"
        let output = "repeat\n{\n    foo\n}\nwhile x"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try! format(input, rules: [elseOrCatchOnSameLine], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    func testWhileNotAffectedByelseOrCatchOnSameLineIfNotRepeatWhile() {
        let input = "func foo(x) {\n}\n\nwhile true {\n}"
        let output = "func foo(x) {\n}\n\nwhile true {\n}"
        XCTAssertEqual(try! format(input, rules: [elseOrCatchOnSameLine]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: trailingCommas

    func testCommaAddedToSingleItem() {
        let input = "[\n    foo\n]"
        let output = "[\n    foo,\n]"
        XCTAssertEqual(try! format(input, rules: [trailingCommas]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testCommaAddedToLastItem() {
        let input = "[\n    foo,\n    bar\n]"
        let output = "[\n    foo,\n    bar,\n]"
        XCTAssertEqual(try! format(input, rules: [trailingCommas]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testCommaAddedToDictionary() {
        let input = "[\n    foo: bar\n]"
        let output = "[\n    foo: bar,\n]"
        XCTAssertEqual(try! format(input, rules: [trailingCommas]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testCommaNotAddedToInlineArray() {
        let input = "[foo, bar]"
        let output = "[foo, bar]"
        XCTAssertEqual(try! format(input, rules: [trailingCommas]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testCommaNotAddedToInlineDictionary() {
        let input = "[foo: bar]"
        let output = "[foo: bar]"
        XCTAssertEqual(try! format(input, rules: [trailingCommas]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testCommaNotAddedToSubscript() {
        let input = "foo[bar]"
        let output = "foo[bar]"
        XCTAssertEqual(try! format(input, rules: [trailingCommas]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testCommaAddedBeforeComment() {
        let input = "[\n    foo // comment\n]"
        let output = "[\n    foo, // comment\n]"
        XCTAssertEqual(try! format(input, rules: [trailingCommas]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testCommaNotAddedAfterComment() {
        let input = "[\n    foo, // comment\n]"
        let output = "[\n    foo, // comment\n]"
        XCTAssertEqual(try! format(input, rules: [trailingCommas]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testCommaNotAddedInsideEmptyArrayLiteral() {
        let input = "foo = [\n]"
        let output = "foo = [\n]"
        XCTAssertEqual(try! format(input, rules: [trailingCommas]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testCommaNotAddedInsideEmptyDictionaryLiteral() {
        let input = "foo = [:\n]"
        let output = "foo = [:\n]"
        XCTAssertEqual(try! format(input, rules: [trailingCommas]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: trailingCommas = false

    func testCommaNotAddedToLastItem() {
        let input = "[\n    foo,\n    bar\n]"
        let output = "[\n    foo,\n    bar\n]"
        let options = FormatOptions(trailingCommas: false)
        XCTAssertEqual(try! format(input, rules: [trailingCommas], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    func testCommaRemovedFromLastItem() {
        let input = "[\n    foo,\n    bar,\n]"
        let output = "[\n    foo,\n    bar\n]"
        let options = FormatOptions(trailingCommas: false)
        XCTAssertEqual(try! format(input, rules: [trailingCommas], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    // MARK: todos

    func testMarkIsUpdated() {
        let input = "// MARK foo"
        let output = "// MARK: foo"
        XCTAssertEqual(try! format(input, rules: [todos]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testTodoIsUpdated() {
        let input = "// TODO foo"
        let output = "// TODO: foo"
        XCTAssertEqual(try! format(input, rules: [todos]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testFixmeIsUpdated() {
        let input = "//    FIXME foo"
        let output = "//    FIXME: foo"
        XCTAssertEqual(try! format(input, rules: [todos]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testMarkWithColonSeparatedBySpace() {
        let input = "// MARK : foo"
        let output = "// MARK: foo"
        XCTAssertEqual(try! format(input, rules: [todos]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testMarkWithNoSpaceAfterColon() {
        // NOTE: this was an unintended side-effect, but I like it
        let input = "// MARK:foo"
        let output = "// MARK: foo"
        XCTAssertEqual(try! format(input, rules: [todos]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testCorrectMarkIsIgnored() {
        let input = "// MARK: foo"
        let output = "// MARK: foo"
        XCTAssertEqual(try! format(input, rules: [todos]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testMarkInsideMultilineComment() {
        let input = "/* MARK foo */"
        let output = "/* MARK: foo */"
        XCTAssertEqual(try! format(input, rules: [todos]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: semicolons

    func testSemicolonRemovedAtEndOfLine() {
        let input = "print(\"hello\");\n"
        let output = "print(\"hello\")\n"
        XCTAssertEqual(try! format(input, rules: [semicolons]), output)
        XCTAssertEqual(try! format(input, rules: defaultRules), output)
    }

    func testSemicolonRemovedAtStartOfLine() {
        let input = "\n;print(\"hello\")"
        let output = "\nprint(\"hello\")"
        XCTAssertEqual(try! format(input, rules: [semicolons]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSemicolonRemovedAtEndOfProgram() {
        let input = "print(\"hello\");"
        let output = "print(\"hello\")"
        XCTAssertEqual(try! format(input, rules: [semicolons]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSemicolonRemovedAtStartOfProgram() {
        let input = ";print(\"hello\")"
        let output = "print(\"hello\")"
        XCTAssertEqual(try! format(input, rules: [semicolons]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testIgnoreInlineSemicolon() {
        let input = "print(\"hello\"); print(\"goodbye\")"
        let output = "print(\"hello\"); print(\"goodbye\")"
        let options = FormatOptions(allowInlineSemicolons: true)
        XCTAssertEqual(try! format(input, rules: [semicolons], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    func testReplaceInlineSemicolon() {
        let input = "print(\"hello\"); print(\"goodbye\")"
        let output = "print(\"hello\")\nprint(\"goodbye\")"
        let options = FormatOptions(allowInlineSemicolons: false)
        XCTAssertEqual(try! format(input, rules: [semicolons], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    func testReplaceSemicolonFollowedByComment() {
        let input = "print(\"hello\"); // comment\nprint(\"goodbye\")"
        let output = "print(\"hello\") // comment\nprint(\"goodbye\")"
        let options = FormatOptions(allowInlineSemicolons: true)
        XCTAssertEqual(try! format(input, rules: [semicolons], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    func testSemicolonsNotReplacedInForLoop() {
        let input = "for (i = 0; i < 5; i++)"
        let output = "for (i = 0; i < 5; i++)"
        let options = FormatOptions(allowInlineSemicolons: false)
        XCTAssertEqual(try! format(input, rules: [semicolons], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    func testSemicolonsNotReplacedInForLoopContainingComment() {
        let input = "for (i = 0 // comment\n    ; i < 5; i++)"
        let output = "for (i = 0 // comment\n    ; i < 5; i++)"
        let options = FormatOptions(allowInlineSemicolons: false)
        XCTAssertEqual(try! format(input, rules: [semicolons], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    func testSemicolonNotReplacedAfterReturn() {
        let input = "return;\nfoo()"
        let output = "return;\nfoo()"
        XCTAssertEqual(try! format(input, rules: [semicolons]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSemicolonReplacedAfterReturnIfEndOfScope() {
        let input = "{ return; }"
        let output = "{ return }"
        XCTAssertEqual(try! format(input, rules: [semicolons]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: ranges

    func testSpaceAroundRangeOperatorsWithDefaultOptions() {
        let input = "foo..<bar"
        let output = "foo ..< bar"
        XCTAssertEqual(try! format(input, rules: [ranges]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testNoSpaceAroundRangeOperatorsWithCustomOptions() {
        let input = "foo ..< bar"
        let output = "foo..<bar"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        XCTAssertEqual(try! format(input, rules: [ranges], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    func testNoSpaceAddedAroundVariadic() {
        let input = "foo(bar: Int...)"
        let output = "foo(bar: Int...)"
        let options = FormatOptions(spaceAroundRangeOperators: true)
        XCTAssertEqual(try! format(input, rules: [ranges], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    func testNoSpaceAddedAroundVariadicWithComment() {
        let input = "foo(bar: Int.../* one or more */)"
        let output = "foo(bar: Int.../* one or more */)"
        let options = FormatOptions(spaceAroundRangeOperators: true)
        XCTAssertEqual(try! format(input, rules: [ranges], options: options), output)
    }

    func testNoSpaceAddedAroundVariadicThatIsntLastArg() {
        let input = "foo(bar: Int..., baz: Int)"
        let output = "foo(bar: Int..., baz: Int)"
        let options = FormatOptions(spaceAroundRangeOperators: true)
        XCTAssertEqual(try! format(input, rules: [ranges], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    func testNoSpaceAddedAroundSplitLineVariadic() {
        let input = "foo(\n    bar: Int...\n)"
        let output = "foo(\n    bar: Int...\n)"
        let options = FormatOptions(spaceAroundRangeOperators: true)
        XCTAssertEqual(try! format(input, rules: [ranges], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    // MARK: specifiers

    func testVarSpecifiersCorrected() {
        let input = "unowned private static var foo"
        let output = "private unowned static var foo"
        XCTAssertEqual(try! format(input, rules: [specifiers]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testPrivateSetSpecifierNotMangled() {
        let input = "public private(set) weak lazy var foo"
        let output = "private(set) public lazy weak var foo"
        XCTAssertEqual(try! format(input, rules: [specifiers]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testPrivateRequiredStaticFuncSpecifiers() {
        let input = "required static private func foo()"
        let output = "private required static func foo()"
        XCTAssertEqual(try! format(input, rules: [specifiers]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testPrivateConvenienceInit() {
        let input = "convenience private init()"
        let output = "private convenience init()"
        XCTAssertEqual(try! format(input, rules: [specifiers]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testWhitespaceInSpecifiersLeftIntact() {
        let input = "weak private(set) /* read-only */\npublic var"
        let output = "private(set) /* read-only */\npublic weak var"
        XCTAssertEqual(try! format(input, rules: [specifiers]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testPrefixSpecifier() {
        let input = "prefix public static func -(rhs: Foo) -> Foo"
        let output = "public static prefix func -(rhs: Foo) -> Foo"
        XCTAssertEqual(try! format(input, rules: [specifiers]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: void

    func testEmptyParensReturnValueConvertedToVoid() {
        let input = "() -> ()"
        let output = "() -> Void"
        XCTAssertEqual(try! format(input, rules: [void]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSpacedParensReturnValueConvertedToVoid() {
        let input = "() -> ( \n)"
        let output = "() -> Void"
        XCTAssertEqual(try! format(input, rules: [void]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testParensContainingCommentNotConvertedToVoid() {
        let input = "() -> ( /* Hello World */ )"
        let output = "() -> ( /* Hello World */ )"
        XCTAssertEqual(try! format(input, rules: [void]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testParensRemovedAroundVoid() {
        let input = "() -> (Void)"
        let output = "() -> Void"
        XCTAssertEqual(try! format(input, rules: [void]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testVoidArgumentConvertedToEmptyParens() {
        let input = "Void -> Void"
        let output = "() -> Void"
        XCTAssertEqual(try! format(input, rules: [void]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testVoidArgumentInParensConvertedToEmptyParens() {
        let input = "(Void) -> Void"
        let output = "() -> Void"
        XCTAssertEqual(try! format(input, rules: [void]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testFunctionThatReturnsAFunction() {
        let input = "(Void) -> Void -> ()"
        let output = "() -> () -> Void"
        XCTAssertEqual(try! format(input, rules: [void]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testChainOfFunctionsIsNotChanged() {
        let input = "() -> () -> () -> Void"
        let output = "() -> () -> () -> Void"
        XCTAssertEqual(try! format(input, rules: [void]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    // MARK: useVoid = false

    func testUseVoidOptionFalse() {
        let input = "(Void) -> Void"
        let output = "() -> ()"
        let options = FormatOptions(useVoid: false)
        XCTAssertEqual(try! format(input, rules: [void], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    func testNamespacedVoidNotConverted() {
        let input = "() -> Swift.Void"
        let output = "() -> Swift.Void"
        let options = FormatOptions(useVoid: false)
        XCTAssertEqual(try! format(input, rules: [void], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    func testTypealiasVoidNotConverted() {
        let input = "public typealias Void = ()"
        let output = "public typealias Void = ()"
        let options = FormatOptions(useVoid: false)
        XCTAssertEqual(try! format(input, rules: [void], options: options), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules, options: options), output + "\n")
    }

    // MARK: redundantParens

    func testRedundantParensRemoved() {
        let input = "if (x + y) {}"
        let output = "if x + y {}"
        XCTAssertEqual(try! format(input, rules: [redundantParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testRequiredParensNotRemoved() {
        let input = "if (x + y) * z {}"
        let output = "if (x + y) * z {}"
        XCTAssertEqual(try! format(input, rules: [redundantParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testOuterParensRemoved() {
        let input = "while ((x + y) * z) {}"
        let output = "while (x + y) * z {}"
        XCTAssertEqual(try! format(input, rules: [redundantParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }

    func testSwitchTupleNotUnwrapped() {
        let input = "switch (x, y) {}"
        let output = "switch (x, y) {}"
        XCTAssertEqual(try! format(input, rules: [redundantParens]), output)
        XCTAssertEqual(try! format(input + "\n", rules: defaultRules), output + "\n")
    }
}
