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
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testAddSpaceBetweenParenAndClass() {
        let input = "@objc(XYZFoo)class foo"
        let output = "@objc(XYZFoo) class foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoRemoveSpaceBetweenParenAndClass() {
        let input = "@objc(XYZFoo) class foo"
        let output = "@objc(XYZFoo) class foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testAddSpaceBetweenConventionAndBlock() {
        let input = "@convention(block)() -> Void"
        let output = "@convention(block) () -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoRemoveSpaceBetweenConventionAndBlock() {
        let input = "@convention(block) () -> Void"
        let output = "@convention(block) () -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testAddSpaceBetweenConventionAndEscaping() {
        let input = "@convention(block)@escaping () -> Void"
        let output = "@convention(block) @escaping () -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoRemoveSpaceBetweenConventionAndEscaping() {
        let input = "@convention(block) @escaping () -> Void"
        let output = "@convention(block) @escaping () -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testAddSpaceBetweenAutoclosureEscapingAndBlock() { // swift 2.3 only
        let input = "@autoclosure(escaping)() -> Void"
        let output = "@autoclosure(escaping) () -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceBetweenParenAndAs() {
        let input = "(foo.bar) as? String"
        let output = "(foo.bar) as? String"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceAfterParenAtEndOfFile() {
        let input = "(foo.bar)"
        let output = "(foo.bar)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceBetweenParenAndFoo() {
        let input = "func foo ()"
        let output = "func foo()"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceBetweenParenAndInit() {
        let input = "init ()"
        let output = "init()"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceBetweenObjcAndSelector() {
        let input = "@objc (XYZFoo) class foo"
        let output = "@objc(XYZFoo) class foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceBetweenHashSelectorAndBrace() {
        let input = "#selector(foo)"
        let output = "#selector(foo)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceBetweenHashKeyPathAndBrace() {
        let input = "#keyPath (self.foo.bar)"
        let output = "#keyPath(self.foo.bar)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceBetweenHashAvailableAndBrace() {
        let input = "#available (iOS 9.0, *)"
        let output = "#available(iOS 9.0, *)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceBetweenPrivateAndSet() {
        let input = "private (set) var foo: Int"
        let output = "private(set) var foo: Int"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceBetweenLetAndTuple() {
        let input = "if let (foo, bar) = baz"
        let output = "if let (foo, bar) = baz"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceBetweenIfAndCondition() {
        let input = "if(a || b) == true {}"
        let output = "if (a || b) == true {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceBetweenArrayLiteralAndParen() {
        let input = "[String] ()"
        let output = "[String]()"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoRemoveSpaceBetweenCaptureListAndArguments() {
        let input = "{ [weak self] (foo) in print(foo) }"
        let output = "{ [weak self] (foo) in print(foo) }"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        let rules = FormatRules.all(except: ["redundantParens"])
        XCTAssertEqual(try format(input + "\n", rules: rules), output + "\n")
    }

    func testAddSpaceBetweenCaptureListAndArguments() {
        let input = "{ [weak self](foo) in print(foo) }"
        let output = "{ [weak self] (foo) in print(foo) }"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        let rules = FormatRules.all(except: ["redundantParens"])
        XCTAssertEqual(try format(input + "\n", rules: rules), output + "\n")
    }

    func testSpaceBetweenClosingParenAndOpenBrace() {
        let input = "func foo(){ foo }"
        let output = "func foo() { foo }"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceBetweenClosingBraceAndParens() {
        let input = "{ block } ()"
        let output = "{ block }()"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testDontRemoveSpaceBetweenOpeningBraceAndParens() {
        let input = "a = (b + c)"
        let output = "a = (b + c)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testKeywordAsIdentifierParensSpacing() {
        let input = "if foo.let (foo, bar)"
        let output = "if foo.let(foo, bar)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceAfterInoutParam() {
        let input = "func foo(bar _: inout(Int, String)) {}"
        let output = "func foo(bar _: inout (Int, String)) {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceAfterEscapingAttribute() {
        let input = "func foo(bar: @escaping() -> Void)"
        let output = "func foo(bar: @escaping () -> Void)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceAfterAutoclosureAttribute() {
        let input = "func foo(bar: @autoclosure () -> Void)"
        let output = "func foo(bar: @autoclosure () -> Void)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: spaceInsideParens

    func testSpaceInsideParens() {
        let input = "( 1, ( 2, 3 ) )"
        let output = "(1, (2, 3))"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: spaceAroundBrackets

    func testSubscriptNoAddSpacing() {
        let input = "foo[bar] = baz"
        let output = "foo[bar] = baz"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBrackets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSubscriptRemoveSpacing() {
        let input = "foo [bar] = baz"
        let output = "foo[bar] = baz"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBrackets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testArrayLiteralSpacing() {
        let input = "foo = [bar, baz]"
        let output = "foo = [bar, baz]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBrackets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testAsArrayCastingSpacing() {
        let input = "foo as[String]"
        let output = "foo as [String]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBrackets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testAsOptionalArrayCastingSpacing() {
        let input = "foo as? [String]"
        let output = "foo as? [String]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBrackets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testIsArrayTestingSpacing() {
        let input = "if foo is[String]"
        let output = "if foo is [String]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBrackets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testKeywordAsIdentifierBracketSpacing() {
        let input = "if foo.is[String]"
        let output = "if foo.is[String]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBrackets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: spaceInsideBrackets

    func testSpaceInsideBrackets() {
        let input = "foo[ 5 ]"
        let output = "foo[5]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideBrackets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceInsideWrappedArray() {
        let input = "[ foo,\n bar ]"
        let output = "[foo,\n bar]"
        let options = FormatOptions(wrapElements: .disabled)
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideBrackets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    // MARK: spaceAroundBraces

    func testSpaceAroundTrailingClosure() {
        let input = "if x{ y }else{ z }"
        let output = "if x { y } else { z }"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBraces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceAroundClosureInsiderParens() {
        let input = "foo({ $0 == 5 })"
        let output = "foo({ $0 == 5 })"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBraces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoExtraSpaceAroundBracesAtStartOrEndOfFile() {
        let input = "{ foo }"
        let output = "{ foo }"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBraces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceAroundBracesAfterOptionalProperty() {
        let input = "var: Foo?{}"
        let output = "var: Foo? {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBraces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceAroundBracesAfterImplicitlyUnwrappedProperty() {
        let input = "var: Foo!{}"
        let output = "var: Foo! {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBraces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceAroundBracesAfterNumber() {
        let input = "if x = 5{}"
        let output = "if x = 5 {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBraces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceAroundBracesAfterString() {
        let input = "if x = \"\"{}"
        let output = "if x = \"\" {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBraces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: spaceInsideBraces

    func testSpaceInsideBraces() {
        let input = "foo({bar})"
        let output = "foo({ bar })"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideBraces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoExtraSpaceInsidebraces() {
        let input = "{ foo }"
        let output = "{ foo }"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideBraces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceInsideEmptybraces() {
        let input = "foo({ })"
        let output = "foo({})"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideBraces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: spaceAroundGenerics

    func testSpaceAroundGenerics() {
        let input = "Foo <Bar <Baz>>"
        let output = "Foo<Bar<Baz>>"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundGenerics]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: spaceInsideGenerics

    func testSpaceInsideGenerics() {
        let input = "Foo< Bar< Baz > >"
        let output = "Foo<Bar<Baz>>"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideGenerics]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: spaceAroundOperators

    func testSpaceAfterColon() {
        let input = "let foo:Bar = 5"
        let output = "let foo: Bar = 5"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceBetweenOptionalAndDefaultValue() {
        let input = "let foo: String?=nil"
        let output = "let foo: String? = nil"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceBetweenImplictlyUnwrappedOptionalAndDefaultValue() {
        let input = "let foo: String!=nil"
        let output = "let foo: String! = nil"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceBetweenOptionalAndDefaultValueInFunction() {
        let input = "func foo(bar _: String?=nil) {}"
        let output = "func foo(bar _: String? = nil) {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceAddedAfterColonInSelector() {
        let input = "@objc(foo:bar:)"
        let output = "@objc(foo:bar:)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceAfterComma() {
        let input = "let foo = [1,2,3]"
        let output = "let foo = [1, 2, 3]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceBetweenColonAndEnumValue() {
        let input = "[.Foo:.Bar]"
        let output = "[.Foo: .Bar]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceBetweenCommaAndEnumValue() {
        let input = "[.Foo,.Bar]"
        let output = "[.Foo, .Bar]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceBetweenSemicolonAndEnumValue() {
        let input = "statement;.Bar"
        let output = "statement; .Bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceBetweenEqualsAndEnumValue() {
        let input = "foo = .Bar"
        let output = "foo = .Bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceBeforeColon() {
        let input = "let foo : Bar = 5"
        let output = "let foo: Bar = 5"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceBeforeColonInTernary() {
        let input = "foo ? bar : baz"
        let output = "foo ? bar : baz"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testTernaryOfEnumValues() {
        let input = "foo ? .Bar : .Baz"
        let output = "foo ? .Bar : .Baz"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceBeforeColonInNestedTernary() {
        let input = "foo ? (hello + a ? b: c) : baz"
        let output = "foo ? (hello + a ? b : c) : baz"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceBeforeComma() {
        let input = "let foo = [1 , 2 , 3]"
        let output = "let foo = [1, 2, 3]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceAtStartOfLine() {
        let input = "foo\n    ,bar"
        let output = "foo\n    , bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceAroundInfixMinus() {
        let input = "foo-bar"
        let output = "foo - bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceAroundPrefixMinus() {
        let input = "foo + -bar"
        let output = "foo + -bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceAroundLessThan() {
        let input = "foo<bar"
        let output = "foo < bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testDontAddSpaceAroundDot() {
        let input = "foo.bar"
        let output = "foo.bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testRemoveSpaceAroundDot() {
        let input = "foo . bar"
        let output = "foo.bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceAroundDotOnNewLine() {
        let input = "foo\n    .bar"
        let output = "foo\n    .bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceAroundEnumCase() {
        let input = "case .Foo,.Bar:"
        let output = "case .Foo, .Bar:"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSwitchWithEnumCases() {
        let input = "switch x {\ncase.Foo:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\ncase .Foo:\n    break\ndefault:\n    break\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceAroundEnumReturn() {
        let input = "return.Foo"
        let output = "return .Foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceAfterReturnAsIdentifier() {
        let input = "foo.return.Bar"
        let output = "foo.return.Bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceAroundCaseLet() {
        let input = "case let.Foo(bar):"
        let output = "case let .Foo(bar):"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceAroundEnumArgument() {
        let input = "foo(with:.Bar)"
        let output = "foo(with: .Bar)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceBeforeEnumCaseInsideClosure() {
        let input = "{ .bar() }"
        let output = "{ .bar() }"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceAroundMultipleOptionalChaining() {
        let input = "foo??!?!.bar"
        let output = "foo??!?!.bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceAroundForcedChaining() {
        let input = "foo!.bar"
        let output = "foo!.bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceAddedInOptionalChaining() {
        let input = "foo?.bar"
        let output = "foo?.bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceRemovedInOptionalChaining() {
        let input = "foo? .bar"
        let output = "foo?.bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceRemovedInForcedChaining() {
        let input = "foo! .bar"
        let output = "foo!.bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceRemovedInMultipleOptionalChaining() {
        let input = "foo??! .bar"
        let output = "foo??!.bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceAfterOptionalInsideTernary() {
        let input = "x ? foo? .bar() : bar?.baz()"
        let output = "x ? foo?.bar() : bar?.baz()"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSplitLineOptionalChaining() {
        let input = "foo?\n    .bar"
        let output = "foo?\n    .bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSplitLineMultipleOptionalChaining() {
        let input = "foo??!\n    .bar"
        let output = "foo??!\n    .bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceBetweenNullCoalescingAndDot() {
        let input = "foo ?? .bar()"
        let output = "foo ?? .bar()"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceAroundFailableInit() {
        let input = "init?()"
        let output = "init?()"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceAroundImplictlyUnwrappedFailableInit() {
        let input = "init!()"
        let output = "init!()"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceAroundFailableInitWithGenerics() {
        let input = "init?<T>()"
        let output = "init?<T>()"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceAroundImplictlyUnwrappedFailableInitWithGenerics() {
        let input = "init!<T>()"
        let output = "init!<T>()"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testAsSpaceAfterOptionalAs() {
        let input = "foo as?[String]"
        let output = "foo as? [String]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testAsSpaceAfterForcedAs() {
        let input = "foo as![String]"
        let output = "foo as! [String]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceAroundGenerics() {
        let input = "Array<String>"
        let output = "Array<String>"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceAroundReturnTypeArrow() {
        let input = "foo() ->Bool"
        let output = "foo() -> Bool"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceAroundCommentInInfixExpression() {
        let input = "foo/* hello */-bar"
        let output = "foo/* hello */ -bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        let rules = FormatRules.all(except: ["spaceAroundComments"])
        XCTAssertEqual(try format(input + "\n", rules: rules), output + "\n")
    }

    func testSpaceAroundCommentsInInfixExpression() {
        let input = "a/* */+/* */b"
        let output = "a/* */ + /* */b"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        let rules = FormatRules.all(except: ["spaceAroundComments"])
        XCTAssertEqual(try format(input + "\n", rules: rules), output + "\n")
    }

    func testSpaceAroundCommentInPrefixExpression() {
        let input = "a + /* hello */ -bar"
        let output = "a + /* hello */ -bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: spaceAroundComments

    func testSpaceAroundCommentInParens() {
        let input = "(/* foo */)"
        let output = "( /* foo */ )"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceAroundCommentAtStartAndEndOfFile() {
        let input = "/* foo */"
        let output = "/* foo */"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceAroundCommentBeforeComma() {
        let input = "(foo /* foo */ , bar)"
        let output = "(foo /* foo */, bar)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceAroundSingleLineComment() {
        let input = "func foo() {// comment\n}"
        let output = "func foo() { // comment\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: spaceInsideComments

    func testSpaceInsideMultilineComment() {
        let input = "/*foo\n bar*/"
        let output = "/* foo\n bar */"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceInsideSingleLineMultilineComment() {
        let input = "/*foo*/"
        let output = "/* foo */"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceInsideEmptyMultilineComment() {
        let input = "/**/"
        let output = "/**/"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceInsideSingleLineComment() {
        let input = "//foo"
        let output = "// foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceInsideMultilineHeaderdocComment() {
        let input = "/**foo\n bar*/"
        let output = "/** foo\n bar */"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceInsideMultilineHeaderdocCommentType2() {
        let input = "/*!foo\n bar*/"
        let output = "/*! foo\n bar */"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceInsideMultilineSwiftPlaygroundDocComment() {
        let input = "/*:foo\n bar*/"
        let output = "/*: foo\n bar */"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoExtraSpaceInsideMultilineHeaderdocComment() {
        let input = "/** foo\n bar */"
        let output = "/** foo\n bar */"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoExtraSpaceInsideMultilineHeaderdocCommentType2() {
        let input = "/*! foo\n bar */"
        let output = "/*! foo\n bar */"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoExtraSpaceInsideMultilineSwiftPlaygroundDocComment() {
        let input = "/*: foo\n bar */"
        let output = "/*: foo\n bar */"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoExtraSpaceInsideSingleLineSwiftPlaygroundDocComment() {
        let input = "//: Playground"
        let output = "//: Playground"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceInsideSingleLineHeaderdocComment() {
        let input = "///foo"
        let output = "/// foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceInsideSingleLineHeaderdocCommentType2() {
        let input = "//!foo"
        let output = "//! foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceInsideSingleLineSwiftPlaygroundDocComment() {
        let input = "//:foo"
        let output = "//: foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoExtraSpaceInsideSingleLineHeaderdocComment() {
        let input = "/// foo"
        let output = "/// foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testPreformattedMultilineComment() {
        let input = "/*********************\n *****Hello World*****\n *********************/"
        let output = "/*********************\n *****Hello World*****\n *********************/"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceAddedToFirstLineOfDocComment() {
        let input = "/**\n Comment\n */"
        let output = "/**\n Comment\n */"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceAddedToEmptyDocComment() {
        let input = "///"
        let output = "///"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: consecutiveSpaces

    func testConsecutiveSpaces() {
        let input = "let foo  = bar"
        let output = "let foo = bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.consecutiveSpaces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testConsecutiveSpacesAfterComment() {
        let input = "// comment\nfoo  bar"
        let output = "// comment\nfoo bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.consecutiveSpaces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testConsecutiveSpacesDoesntStripIndent() {
        let input = "{\n    let foo  = bar\n}"
        let output = "{\n    let foo = bar\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.consecutiveSpaces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testConsecutiveSpacesDoesntAffectMultilineComments() {
        let input = "/*    comment  */"
        let output = "/*    comment  */"
        XCTAssertEqual(try format(input, rules: [FormatRules.consecutiveSpaces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testConsecutiveSpacesDoesntAffectNestedMultilineComments() {
        let input = "/*  foo  /*  bar  */  baz  */"
        let output = "/*  foo  /*  bar  */  baz  */"
        XCTAssertEqual(try format(input, rules: [FormatRules.consecutiveSpaces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testConsecutiveSpacesDoesntAffectSingleLineComments() {
        let input = "//    foo  bar"
        let output = "//    foo  bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.consecutiveSpaces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: trailingSpace

    func testTrailingSpace() {
        let input = "foo  \nbar"
        let output = "foo\nbar"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingSpace]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testTrailingSpaceAtEndOfFile() {
        let input = "foo  "
        let output = "foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingSpace]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testTrailingSpaceInMultilineComments() {
        let input = "/* foo  \n bar  */"
        let output = "/* foo\n bar  */"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingSpace]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testTrailingSpaceInSingleLineComments() {
        let input = "// foo  \n// bar  "
        let output = "// foo\n// bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingSpace]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: consecutiveBlankLines

    func testConsecutiveBlankLines() {
        let input = "foo\n\n  \nbar"
        let output = "foo\n\nbar"
        XCTAssertEqual(try format(input, rules: [FormatRules.consecutiveBlankLines]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testConsecutiveBlankLinesAtEndOfFile() {
        let input = "foo\n\n"
        let output = "foo\n"
        XCTAssertEqual(try format(input, rules: [FormatRules.consecutiveBlankLines]), output)
        XCTAssertEqual(try format(input, rules: FormatRules.default), output)
    }

    func testConsecutiveBlankLinesAtStartOfFile() {
        let input = "\n\n\nfoo"
        let output = "\n\nfoo"
        XCTAssertEqual(try format(input, rules: [FormatRules.consecutiveBlankLines]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testFragmentWithTrailingLinebreaks() {
        let input = "func foo() {\n}\n\n\n"
        let output = "func foo() {\n}\n\n"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.consecutiveBlankLines], options: options), output)
        XCTAssertEqual(try format(input, rules: FormatRules.default, options: options), output)
    }

    // MARK: blankLinesAtEndOfScope

    func testBlankLinesRemovedAtEndOfFunction() {
        let input = "func foo() {\n    // code\n\n}"
        let output = "func foo() {\n    // code\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesAtEndOfScope]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testBlankLinesRemovedAtEndOfParens() {
        let input = "(\n    foo: Int\n\n)"
        let output = "(\n    foo: Int\n)"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesAtEndOfScope]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testBlankLinesRemovedAtEndOfBrackets() {
        let input = "[\n    foo,\n    bar,\n\n]"
        let output = "[\n    foo,\n    bar,\n]"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesAtEndOfScope]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testBlankLineNotRemovedBeforeElse() {
        let input = "if x {\n\n    // do something\n\n} else if y {\n\n    // do something else\n\n}"
        let output = "if x {\n\n    // do something\n\n} else if y {\n\n    // do something else\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesAtEndOfScope]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: blankLinesBetweenScopes

    func testBlankLineBetweenFunctions() {
        let input = "func foo() {\n}\nfunc bar() {\n}"
        let output = "func foo() {\n}\n\nfunc bar() {\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNpBlankLineBetweenPropertyAndFunction() {
        let input = "var foo: Int\nfunc bar() {\n}"
        let output = "var foo: Int\nfunc bar() {\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testBlankLineBetweenFunctionsIsBeforeComment() {
        let input = "func foo() {\n}\n// headerdoc\nfunc bar() {\n}"
        let output = "func foo() {\n}\n\n// headerdoc\nfunc bar() {\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testBlankLineBeforeAtObjCOnLineBeforeProtocol() {
        let input = "@objc\nprotocol Foo {\n}\n@objc\nprotocol Bar {\n}"
        let output = "@objc\nprotocol Foo {\n}\n\n@objc\nprotocol Bar {\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testBlankLineBeforeAtAvailabilityOnLineBeforeClass() {
        let input = "protocol Foo {\n}\n@available(iOS 8.0, OSX 10.10, *)\nclass Bar {\n}"
        let output = "protocol Foo {\n}\n\n@available(iOS 8.0, OSX 10.10, *)\nclass Bar {\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoExtraBlankLineBetweenFunctions() {
        let input = "func foo() {\n}\n\nfunc bar() {\n}"
        let output = "func foo() {\n}\n\nfunc bar() {\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoBlankLineBetweenFunctionsInProtocol() {
        let input = "protocol Foo {\n    func bar() -> Void\n    func baz() -> Int\n}"
        let output = "protocol Foo {\n    func bar() -> Void\n    func baz() -> Int\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoBlankLineInsideInitFunction() {
        let input = "init() {\n    super.init()\n}"
        let output = "init() {\n    super.init()\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testBlankLineAfterProtocolBeforeProperty() {
        let input = "protocol Foo {\n}\nvar bar: String"
        let output = "protocol Foo {\n}\n\nvar bar: String"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoExtraBlankLineAfterSingleLineComment() {
        let input = "var foo: Bar? // comment\n\nfunc bar() {}"
        let output = "var foo: Bar? // comment\n\nfunc bar() {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoExtraBlankLineAfterMultilineComment() {
        let input = "var foo: Bar? /* comment */\n\nfunc bar() {}"
        let output = "var foo: Bar? /* comment */\n\nfunc bar() {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoBlankLineBeforeFuncAsIdentifier() {
        let input = "var foo: Bar?\nfoo.func(x) {}"
        let output = "var foo: Bar?\nfoo.func(x) {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoBlankLineBetweenFunctionsWithInlineBody() {
        let input = "class Foo {\n    func foo() { print(\"foo\") }\n    func bar() { print(\"bar\") }\n}"
        let output = "class Foo {\n    func foo() { print(\"foo\") }\n    func bar() { print(\"bar\") }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoBlankLineBetweenIfStatements() {
        let input = "func foo() {\n    if x {\n    }\n    if y {\n    }\n}"
        let output = "func foo() {\n    if x {\n    }\n    if y {\n    }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoBlanksInsideClassFunc() {
        let input = "class func foo {\n    if x {\n    }\n    if y {\n    }\n}"
        let output = "class func foo {\n    if x {\n    }\n    if y {\n    }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoBlanksInsideClassVar() {
        let input = "class var foo: Int {\n    if x {\n    }\n    if y {\n    }\n}"
        let output = "class var foo: Int {\n    if x {\n    }\n    if y {\n    }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testBlankLineBetweenCalledClosures() {
        let input = "class Foo {\n    var foo = {\n    }()\n    func bar {\n    }\n}"
        let output = "class Foo {\n    var foo = {\n    }()\n\n    func bar {\n    }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoBlankLineAfterCalledClosureAtEndOfScope() {
        let input = "class Foo {\n    var foo = {\n    }()\n}"
        let output = "class Foo {\n    var foo = {\n    }()\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoBlankLineBeforeWhileInRepeatWhile() {
        let input = "repeat\n{\n}\nwhile true\n{\n}()"
        let output = "repeat\n{\n}\nwhile true\n{\n}()"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testBlankLineBeforeWhileIfNotRepeatWhile() {
        let input = "func foo(x)\n{\n}\nwhile true\n{\n}"
        let output = "func foo(x)\n{\n}\n\nwhile true\n{\n}"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    // MARK: linebreakAtEndOfFile

    func testLinebreakAtEndOfFile() {
        let input = "foo\nbar"
        let output = "foo\nbar\n"
        XCTAssertEqual(try format(input, rules: [FormatRules.linebreakAtEndOfFile]), output)
        XCTAssertEqual(try format(input, rules: FormatRules.default), output)
    }

    func testNoLinebreakAtEndOfFragment() {
        let input = "foo\nbar"
        let output = "foo\nbar"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.linebreakAtEndOfFile], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    // MARK: indent parens

    func testSimpleScope() {
        let input = "foo(\nbar\n)"
        let output = "foo(\n    bar\n)"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNestedScope() {
        let input = "foo(\nbar {\n}\n)"
        let output = "foo(\n    bar {\n    }\n)"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNestedScopeOnSameLine() {
        let input = "foo(bar(\nbaz\n))"
        let output = "foo(bar(\n    baz\n))"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testIndentNestedArrayLiteral() {
        let input = "foo(bar: [\n.baz,\n])"
        let output = "foo(bar: [\n    .baz,\n])"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testClosingScopeAfterContent() {
        let input = "foo(\nbar)"
        let output = "foo(\n    bar)"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testClosingNestedScopeAfterContent() {
        let input = "foo(bar(\nbaz))"
        let output = "foo(bar(\n    baz))"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testWrappedFunctionArguments() {
        let input = "foo(\nbar,\nbaz\n)"
        let output = "foo(\n    bar,\n    baz\n)"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testFunctionArgumentsWrappedAfterFirst() {
        let input = "func foo(bar: Int,\nbaz: Int)"
        let output = "func foo(bar: Int,\n         baz: Int)"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: indent specifiers

    func testNoIndentWrappedSpecifiersForProtocol() {
        let input = "@objc\nprivate\nprotocol Foo {}"
        let output = "@objc\nprivate\nprotocol Foo {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: indent braces

    func testElseClauseIndenting() {
        let input = "if x {\nbar\n} else {\nbaz\n}"
        let output = "if x {\n    bar\n} else {\n    baz\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoIndentBlankLines() {
        let input = "{\n\n// foo\n}"
        let output = "{\n\n    // foo\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNestedBraces() {
        let input = "({\n// foo\n}, {\n// bar\n})"
        let output = "({\n    // foo\n}, {\n    // bar\n})"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testBraceIndentAfterComment() {
        let input = "if foo { // comment\nbar\n}"
        let output = "if foo { // comment\n    bar\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testBraceIndentAfterClosingScope() {
        let input = "foo(bar(baz), {\nquux\nbleem\n})"
        let output = "foo(bar(baz), {\n    quux\n    bleem\n})"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testBraceIndentAfterLineWithParens() {
        let input = "({\nfoo()\nbar\n})"
        let output = "({\n    foo()\n    bar\n})"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: indent switch/case

    func testSwitchCaseIndenting() {
        let input = "switch x {\ncase foo:\nbreak\ncase bar:\nbreak\ndefault:\nbreak\n}"
        let output = "switch x {\ncase foo:\n    break\ncase bar:\n    break\ndefault:\n    break\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSwitchWrappedCaseIndenting() {
        let input = "switch x {\ncase foo,\nbar,\n    baz:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\ncase foo,\n     bar,\n     baz:\n    break\ndefault:\n    break\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSwitchWrappedEnumCaseIndenting() {
        let input = "switch x {\ncase .foo,\n.bar,\n    .baz:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\ncase .foo,\n     .bar,\n     .baz:\n    break\ndefault:\n    break\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSwitchWrappedEnumCaseIndentingVariant2() {
        let input = "switch x {\ncase\n.foo,\n.bar,\n    .baz:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\ncase\n    .foo,\n    .bar,\n    .baz:\n    break\ndefault:\n    break\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSwitchCaseIsDictionaryIndenting() {
        let input = "switch x {\ncase foo is [Key: Value]:\nfallthrough\ndefault:\nbreak\n}"
        let output = "switch x {\ncase foo is [Key: Value]:\n    fallthrough\ndefault:\n    break\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testEnumCaseIndenting() {
        let input = "enum Foo {\ncase Bar\ncase Baz\n}"
        let output = "enum Foo {\n    case Bar\n    case Baz\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testGenericEnumCaseIndenting() {
        let input = "enum Foo<T> {\ncase Bar\ncase Baz\n}"
        let output = "enum Foo<T> {\n    case Bar\n    case Baz\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: indent wrapped line

    func testWrappedLineAfterOperator() {
        let input = "if x {\nlet y = foo +\nbar\n}"
        let output = "if x {\n    let y = foo +\n        bar\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testWrappedLineAfterComma() {
        let input = "let a = b,\nb = c"
        let output = "let a = b,\n    b = c"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testWrappedBeforeComma() {
        let input = "let a = b\n, b = c"
        let output = "let a = b\n    , b = c"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testWrappedLineAfterCommaInsideArray() {
        let input = "[\nfoo,\nbar,\n]"
        let output = "[\n    foo,\n    bar,\n]"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testWrappedLineBeforeCommaInsideArray() {
        let input = "[\nfoo\n, bar,\n]"
        let output = "[\n    foo\n    , bar,\n]"
        let options = FormatOptions(wrapElements: .disabled)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testWrappedLineAfterCommaInsideInlineArray() {
        let input = "[foo,\nbar]"
        let output = "[foo,\n bar]"
        let options = FormatOptions(wrapElements: .disabled)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testWrappedLineBeforeCommaInsideInlineArray() {
        let input = "[foo\n, bar]"
        let output = "[foo\n , bar]"
        let options = FormatOptions(wrapElements: .disabled)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testWrappedLineAfterColonInFunction() {
        let input = "func foo(bar:\nbaz)"
        let output = "func foo(bar:\n    baz)"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoDoubleIndentOfWrapAfterAsAfterOpenScope() {
        let input = "(foo as\nBar)"
        let output = "(foo as\n    Bar)"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoDoubleIndentOfWrapBeforeAsAfterOpenScope() {
        let input = "(foo\nas Bar)"
        let output = "(foo\n    as Bar)"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testDoubleIndentWhenScopesSeparatedByWrap() {
        let input = "(foo\nas Bar {\nbaz\n})"
        let output = "(foo\n    as Bar {\n        baz\n})"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoDoubleIndentWhenScopesSeparatedByWrap() {
        let input = "(foo\nas Bar {\nbaz\n}\n)"
        let output = "(foo\n    as Bar {\n        baz\n    }\n)"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoPermanentReductionInScopeAfterWrap() {
        let input = "{ foo\nas Bar\nlet baz = 5\n}"
        let output = "{ foo\n    as Bar\n    let baz = 5\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testWrappedLineBeforeOperator() {
        let input = "if x {\nlet y = foo\n+ bar\n}"
        let output = "if x {\n    let y = foo\n        + bar\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testWrappedLineAfterForKeyword() {
        let input = "for\ni in range {}"
        let output = "for\n    i in range {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testWrappedLineAfterDot() {
        let input = "let foo = bar.\nbaz"
        let output = "let foo = bar.\n    baz"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testWrappedLineBeforeDot() {
        let input = "let foo = bar\n.baz"
        let output = "let foo = bar\n    .baz"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testWrappedLineBeforeWhere() {
        let input = "let foo = bar\nwhere foo == baz"
        let output = "let foo = bar\n    where foo == baz"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testWrappedLineAfterWhere() {
        let input = "let foo = bar where\nfoo == baz"
        let output = "let foo = bar where\n    foo == baz"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testWrappedLineBeforeGuardElse() {
        let input = "guard let foo = bar\nelse { return }"
        let output = "guard let foo = bar\nelse { return }"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testWrappedLineAfterGuardElse() {
        // Don't indent because this case is handled by braces rule
        let input = "guard let foo = bar else\n{ return }"
        let output = "guard let foo = bar else\n{ return }"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
    }

    func testWrappedLineAfterComment() {
        let input = "foo = bar && // comment\nbaz"
        let output = "foo = bar && // comment\n    baz"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testWrappedLineInClosure() {
        let input = "forEach { item in\nprint(item)\n}"
        let output = "forEach { item in\n    print(item)\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testConsecutiveWraps() {
        let input = "let a = b +\nc +\nd"
        let output = "let a = b +\n    c +\n    d"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testWrapReset() {
        let input = "let a = b +\nc +\nd\nlet a = b +\nc +\nd"
        let output = "let a = b +\n    c +\n    d\nlet a = b +\n    c +\n    d"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testIndentIfCase() {
        let input = "{\nif case .Foo(let msg) = error {}\n}"
        let output = "{\n    if case .Foo(let msg) = error {}\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testIndentIfCaseCommaCase() {
        let input = "{\nif case .Foo(let msg) = a,\ncase .Bar(let msg) = b {}\n}"
        let output = "{\n    if case .Foo(let msg) = a,\n        case .Bar(let msg) = b {}\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testIndentGuardCase() {
        let input = "{\nguard case .Foo = error else {}\n}"
        let output = "{\n    guard case .Foo = error else {}\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testIndentElseAfterComment() {
        let input = "if x {}\n// comment\nelse {}"
        let output = "if x {}\n// comment\nelse {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testWrappedLinesWithComments() {
        let input = "let foo = bar ||\n // baz||\nquux"
        let output = "let foo = bar ||\n    // baz||\n    quux"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoIndentAfterAssignOperatorToVariable() {
        let input = "let greaterThan = >\nlet lessThan = <"
        let output = "let greaterThan = >\nlet lessThan = <"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoIndentAfterDefaultAsIdentifier() {
        let input = "let foo = FileManager.default\n// Comment\nlet bar = 0"
        let output = "let foo = FileManager.default\n// Comment\nlet bar = 0"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testIndentClosureStartingOnIndentedLine() {
        let input = "foo\n.bar {\nbaz()\n}"
        let output = "foo\n    .bar {\n        baz()\n    }"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNestedWrappedIfIndents() {
        let input = "if foo {\nif bar &&\n(baz ||\nquux) {\nfoo()\n}\n}"
        let output = "if foo {\n    if bar &&\n        (baz ||\n            quux) {\n        foo()\n    }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testWrappedEnumThatLooksLikeIf() {
        let input = "foo &&\n bar.if {\nfoo()\n}"
        let output = "foo &&\n    bar.if {\n        foo()\n    }"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testChainedClosureIndents() {
        let input = "foo\n.bar {\nbaz()\n}\n.bar {\nbaz()\n}"
        let output = "foo\n    .bar {\n        baz()\n    }\n    .bar {\n        baz()\n    }"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testChainedClosureIndentsAfterVarDeclaration() {
        let input = "var foo: Int\nfoo\n.bar {\nbaz()\n}\n.bar {\nbaz()\n}"
        let output = "var foo: Int\nfoo\n    .bar {\n        baz()\n    }\n    .bar {\n        baz()\n    }"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testChainedFunctionsInsideIf() {
        let input = "if foo {\nreturn bar()\n.baz()\n}"
        let output = "if foo {\n    return bar()\n        .baz()\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testChainedFunctionsInsideForLoop() {
        let input = "for x in y {\nfoo\n.bar {\nbaz()\n}\n.quux()\n}"
        let output = "for x in y {\n    foo\n        .bar {\n            baz()\n        }\n        .quux()\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testChainedFunctionsAfterAnIfStatement() {
        let input = "if foo {}\nbar\n.baz {\n}\n.quux()"
        let output = "if foo {}\nbar\n    .baz {\n    }\n    .quux()"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testIndentInsideWrappedIfStatementWithClosureCondition() {
        let input = "if foo({ 1 }) ||\nbar {\nbaz()\n}"
        let output = "if foo({ 1 }) ||\n    bar {\n    baz()\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testIndentInsideWrappedClassDefinition() {
        let input = "class Foo\n: Bar {\nbaz()\n}"
        let output = "class Foo\n    : Bar {\n    baz()\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testIndentInsideWrappedProtocolDefinition() {
        let input = "protocol Foo\n: Bar, Baz {\nbaz()\n}"
        let output = "protocol Foo\n    : Bar, Baz {\n    baz()\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testIndentInsideWrappedVarStatement() {
        let input = "var Foo:\nBar {\nreturn 5\n}"
        let output = "var Foo:\n    Bar {\n    return 5\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoIndentAfterOperatorDeclaration() {
        let input = "infix operator ?=\nfunc ?=(lhs _: Int, rhs _: Int) -> Bool {}"
        let output = "infix operator ?=\nfunc ?=(lhs _: Int, rhs _: Int) -> Bool {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoIndentAfterChevronOperatorDeclaration() {
        let input = "infix operator =<<\nfunc =<<<T>(lhs _: T, rhs _: T) -> T {}"
        let output = "infix operator =<<\nfunc =<<<T>(lhs _: T, rhs _: T) -> T {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testIndentEnumDictionaryKeysAndValues() {
        let input = "[\n.foo:\n.bar,\n.baz:\n.quux,\n]"
        let output = "[\n    .foo:\n        .bar,\n    .baz:\n        .quux,\n]"
        let options = FormatOptions(wrapElements: .disabled)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testIndentWrappedFunctionArgument() {
        let input = "foobar(baz: a &&\nb)"
        let output = "foobar(baz: a &&\n    b)"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testIndentWrappedFunctionClosureArgument() {
        let input = "foobar(baz: { a &&\nb })"
        let output = "foobar(baz: { a &&\n        b })"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: indent comments

    func testCommentIndenting() {
        let input = "/* foo\nbar */"
        let output = "/* foo\n bar */"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testCommentIndentingWithTrailingClose() {
        let input = "/*\nfoo\n*/"
        let output = "/*\n foo\n */"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNestedCommentIndenting() {
        let input = "/* foo\n/*\nbar\n*/\n*/"
        let output = "/* foo\n /*\n  bar\n  */\n */"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testCommentIndentingDisabled() {
        let input = "  /**\n  hello\n    - world\n  */"
        let output = "  /**\n  hello\n    - world\n  */"
        let options = FormatOptions(indentComments: false, fragment: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    // MARK: indent #if/#else/#elseif/#endif (mode: indent)

    func testIfEndifIndenting() {
        let input = "#if x\n// foo\n#endif"
        let output = "#if x\n    // foo\n#endif"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testIndentedIfEndifIndenting() {
        let input = "{\n#if x\n// foo\n#endif\n}"
        let output = "{\n    #if x\n        // foo\n    #endif\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testIfElseEndifIndenting() {
        let input = "#if x\n    // foo\n#else\n    // bar\n#endif"
        let output = "#if x\n    // foo\n#else\n    // bar\n#endif"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: indent #if/#else/#elseif/#endif (mode: noindent)

    func testIfEndifNoIndenting() {
        let input = "#if x\n// foo\n#endif"
        let output = "#if x\n// foo\n#endif"
        let options = FormatOptions(ifdefIndent: .noIndent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testIndentedIfEndifNoIndenting() {
        let input = "{\n#if x\n// foo\n#endif\n}"
        let output = "{\n    #if x\n    // foo\n    #endif\n}"
        let options = FormatOptions(ifdefIndent: .noIndent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testIfElseEndifNoIndenting() {
        let input = "#if x\n// foo\n#else\n// bar\n#endif"
        let output = "#if x\n// foo\n#else\n// bar\n#endif"
        let options = FormatOptions(ifdefIndent: .noIndent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    // MARK: indent #if/#else/#elseif/#endif (mode: outdent)

    func testIfEndifOutdenting() {
        let input = "#if x\n// foo\n#endif"
        let output = "#if x\n// foo\n#endif"
        let options = FormatOptions(ifdefIndent: .outdent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testIndentedIfEndifOutdenting() {
        let input = "{\n#if x\n// foo\n#endif\n}"
        let output = "{\n#if x\n    // foo\n#endif\n}"
        let options = FormatOptions(ifdefIndent: .outdent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testIfElseEndifOutdenting() {
        let input = "#if x\n// foo\n#else\n// bar\n#endif"
        let output = "#if x\n// foo\n#else\n// bar\n#endif"
        let options = FormatOptions(ifdefIndent: .outdent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testIndentedIfElseEndifOutdenting() {
        let input = "{\n#if x\n// foo\n#else\n// bar\n#endif\n}"
        let output = "{\n#if x\n    // foo\n#else\n    // bar\n#endif\n}"
        let options = FormatOptions(ifdefIndent: .outdent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testIfElseifEndifOutdenting() {
        let input = "#if x\n// foo\n#elseif y\n// bar\n#endif"
        let output = "#if x\n// foo\n#elseif y\n// bar\n#endif"
        let options = FormatOptions(ifdefIndent: .outdent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testIndentedIfElseifEndifOutdenting() {
        let input = "{\n#if x\n// foo\n#elseif y\n// bar\n#endif\n}"
        let output = "{\n#if x\n    // foo\n#elseif y\n    // bar\n#endif\n}"
        let options = FormatOptions(ifdefIndent: .outdent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testNestedIndentedIfElseifEndifOutdenting() {
        let input = "{\n#if x\n#if y\n// foo\n#elseif y\n// bar\n#endif\n#endif\n}"
        let output = "{\n#if x\n#if y\n    // foo\n#elseif y\n    // bar\n#endif\n#endif\n}"
        let options = FormatOptions(ifdefIndent: .outdent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testDoubleNestedIndentedIfElseifEndifOutdenting() {
        let input = "{\n#if x\n#if y\n#if z\n// foo\n#elseif y\n// bar\n#endif\n#endif\n#endif\n}"
        let output = "{\n#if x\n#if y\n#if z\n    // foo\n#elseif y\n    // bar\n#endif\n#endif\n#endif\n}"
        let options = FormatOptions(ifdefIndent: .outdent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    // MARK: indent expression after return

    func testIndentIdentifierAfterReturn() {
        let input = "if foo {\n    return\n        bar\n}"
        let output = "if foo {\n    return\n        bar\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testIndentEnumValueAfterReturn() {
        let input = "if foo {\n    return\n        .bar\n}"
        let output = "if foo {\n    return\n        .bar\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testIndentMultilineExpressionAfterReturn() {
        let input = "if foo {\n    return\n        bar +\n        baz\n}"
        let output = "if foo {\n    return\n        bar +\n        baz\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testDontIndentClosingBraceAfterReturn() {
        let input = "if foo {\n    return\n}"
        let output = "if foo {\n    return\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testDontIndentCaseAfterReturn() {
        let input = "switch foo {\ncase bar:\n    return\ncase baz:\n    return\n}"
        let output = "switch foo {\ncase bar:\n    return\ncase baz:\n    return\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testDontIndentCaseAfterWhere() {
        let input = "switch foo {\ncase bar\nwhere baz:\nreturn\ndefault:\nreturn\n}"
        let output = "switch foo {\ncase bar\n    where baz:\n    return\ndefault:\n    return\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testDontIndentIfAfterReturn() {
        let input = "if foo {\n    return\n    if bar {}\n}"
        let output = "if foo {\n    return\n    if bar {}\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testDontIndentFuncAfterReturn() {
        let input = "if foo {\n    return\n    func bar() {}\n}"
        let output = "if foo {\n    return\n    func bar() {}\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: indent fragments

    func testIndentFragment() {
        let input = "   func foo() {\nbar()\n}"
        let output = "   func foo() {\n       bar()\n   }"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testIndentFragmentAfterBlankLines() {
        let input = "\n\n   func foo() {\nbar()\n}"
        let output = "\n\n   func foo() {\n       bar()\n   }"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testUnterminatedFragment() {
        let input = "class Foo {\n  \nfunc foo() {\nbar()\n}"
        let output = "class Foo {\n\n    func foo() {\n        bar()\n    }"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: [FormatRules.indent, FormatRules.linebreakAtEndOfFile], options: options), output + "\n")
    }

    func testOverTerminatedFragment() {
        let input = "   func foo() {\nbar()\n}\n\n}"
        let output = "   func foo() {\n       bar()\n   }\n\n}"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testDontCorruptPartialFragment() {
        let input = "    } foo {\n        bar\n    }\n}"
        let output = "    } foo {\n        bar\n    }\n}"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testDontCorruptPartialFragment2() {
        let input = "        return completionHandler(nil)\n    }\n}"
        let output = "        return completionHandler(nil)\n    }\n}"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    // MARK: knr braces

    func testAllmanBracesAreConverted() {
        let input = "func foo()\n{\n    statement\n}"
        let output = "func foo() {\n    statement\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.braces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testKnRBracesAfterComment() {
        let input = "func foo() // comment\n{\n    statement\n}"
        let output = "func foo() { // comment\n    statement\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.braces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testKnRBracesAfterMultilineComment() {
        let input = "func foo() /* comment/ncomment */\n{\n    statement\n}"
        let output = "func foo() { /* comment/ncomment */\n    statement\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.braces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testKnRExtraSpaceNotAddedBeforeBrace() {
        let input = "foo({ bar })"
        let output = "foo({ bar })"
        XCTAssertEqual(try format(input, rules: [FormatRules.braces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testKnRLinebreakNotRemovedBeforeInlineBlockNot() {
        let input = "func foo() -> Bool\n{ return false }"
        let output = "func foo() -> Bool\n{ return false }"
        XCTAssertEqual(try format(input, rules: [FormatRules.braces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: allman braces

    func testKnRBracesAreConverted() {
        let input = "func foo() {\n    statement\n}"
        let output = "func foo()\n{\n    statement\n}"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.braces], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testAllmanBraceInsideParensNotConverted() {
        let input = "foo({\n    bar\n})"
        let output = "foo({\n    bar\n})"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.braces], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testAllmanBraceDoClauseIndent() {
        let input = "do {\n    foo\n}"
        let output = "do\n{\n    foo\n}"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.braces], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testAllmanBraceCatchClauseIndent() {
        let input = "do {\n    try foo\n}\ncatch {\n}"
        let output = "do\n{\n    try foo\n}\ncatch\n{\n}"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.braces], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testAllmanBraceRepeatWhileIndent() {
        let input = "repeat {\n    foo\n}\nwhile x"
        let output = "repeat\n{\n    foo\n}\nwhile x"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.braces], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    // MARK: elseOnSameLine

    func testelseOnSameLine() {
        let input = "if true {\n    1\n}\nelse { 2 }"
        let output = "if true {\n    1\n} else { 2 }"
        XCTAssertEqual(try format(input, rules: [FormatRules.elseOnSameLine]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testelseOnSameLineOnlyAppliedToDanglingBrace() {
        let input = "if true { 1 }\nelse { 2 }"
        let output = "if true { 1 }\nelse { 2 }"
        XCTAssertEqual(try format(input, rules: [FormatRules.elseOnSameLine]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testGuardNotAffectedByelseOnSameLine() {
        let input = "guard true\nelse { return }"
        let output = "guard true\nelse { return }"
        XCTAssertEqual(try format(input, rules: [FormatRules.elseOnSameLine]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testelseOnSameLineDoesntEatPreviousStatement() {
        let input = "if true {}\nguard true else { return }"
        let output = "if true {}\nguard true else { return }"
        XCTAssertEqual(try format(input, rules: [FormatRules.elseOnSameLine]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testElseNotOnSameLineForAllman() {
        let input = "if true\n{\n    1\n} else { 2 }"
        let output = "if true\n{\n    1\n}\nelse { 2 }"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.elseOnSameLine], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testGuardNotAffectedByelseOnSameLineForAllman() {
        let input = "guard true else { return }"
        let output = "guard true else { return }"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.elseOnSameLine], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testRepeatWhileNotOnSameLineForAllman() {
        let input = "repeat\n{\n    foo\n} while x"
        let output = "repeat\n{\n    foo\n}\nwhile x"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.elseOnSameLine], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testWhileNotAffectedByelseOnSameLineIfNotRepeatWhile() {
        let input = "func foo(x) {\n}\n\nwhile true {\n}"
        let output = "func foo(x) {\n}\n\nwhile true {\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.elseOnSameLine]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: trailingCommas

    func testCommaAddedToSingleItem() {
        let input = "[\n    foo\n]"
        let output = "[\n    foo,\n]"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testCommaAddedToLastItem() {
        let input = "[\n    foo,\n    bar\n]"
        let output = "[\n    foo,\n    bar,\n]"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testCommaAddedToDictionary() {
        let input = "[\n    foo: bar\n]"
        let output = "[\n    foo: bar,\n]"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testCommaNotAddedToInlineArray() {
        let input = "[foo, bar]"
        let output = "[foo, bar]"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testCommaNotAddedToInlineDictionary() {
        let input = "[foo: bar]"
        let output = "[foo: bar]"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testCommaNotAddedToSubscript() {
        let input = "foo[bar]"
        let output = "foo[bar]"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testCommaAddedBeforeComment() {
        let input = "[\n    foo // comment\n]"
        let output = "[\n    foo, // comment\n]"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testCommaNotAddedAfterComment() {
        let input = "[\n    foo, // comment\n]"
        let output = "[\n    foo, // comment\n]"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testCommaNotAddedInsideEmptyArrayLiteral() {
        let input = "foo = [\n]"
        let output = "foo = [\n]"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testCommaNotAddedInsideEmptyDictionaryLiteral() {
        let input = "foo = [:\n]"
        let output = "foo = [:\n]"
        let options = FormatOptions(wrapElements: .disabled)
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testTrailingCommaRemovedInInlineArray() {
        let input = "[foo,]"
        let output = "[foo]"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: trailingCommas = false

    func testCommaNotAddedToLastItem() {
        let input = "[\n    foo,\n    bar\n]"
        let output = "[\n    foo,\n    bar\n]"
        let options = FormatOptions(trailingCommas: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testCommaRemovedFromLastItem() {
        let input = "[\n    foo,\n    bar,\n]"
        let output = "[\n    foo,\n    bar\n]"
        let options = FormatOptions(trailingCommas: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    // MARK: todos

    func testMarkIsUpdated() {
        let input = "// MARK foo"
        let output = "// MARK: foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.todos]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testTodoIsUpdated() {
        let input = "// TODO foo"
        let output = "// TODO: foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.todos]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testFixmeIsUpdated() {
        let input = "//    FIXME foo"
        let output = "//    FIXME: foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.todos]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testMarkWithColonSeparatedBySpace() {
        let input = "// MARK : foo"
        let output = "// MARK: foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.todos]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testMarkWithNoSpaceAfterColon() {
        // NOTE: this was an unintended side-effect, but I like it
        let input = "// MARK:foo"
        let output = "// MARK: foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.todos]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testCorrectMarkIsIgnored() {
        let input = "// MARK: foo"
        let output = "// MARK: foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.todos]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testMarkInsideMultilineComment() {
        let input = "/* MARK foo */"
        let output = "/* MARK: foo */"
        XCTAssertEqual(try format(input, rules: [FormatRules.todos]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoExtraSpaceAddedAfterTodo() {
        let input = "/* TODO: */"
        let output = "/* TODO: */"
        XCTAssertEqual(try format(input, rules: [FormatRules.todos]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: semicolons

    func testSemicolonRemovedAtEndOfLine() {
        let input = "print(\"hello\");\n"
        let output = "print(\"hello\")\n"
        XCTAssertEqual(try format(input, rules: [FormatRules.semicolons]), output)
        XCTAssertEqual(try format(input, rules: FormatRules.default), output)
    }

    func testSemicolonRemovedAtStartOfLine() {
        let input = "\n;print(\"hello\")"
        let output = "\nprint(\"hello\")"
        XCTAssertEqual(try format(input, rules: [FormatRules.semicolons]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSemicolonRemovedAtEndOfProgram() {
        let input = "print(\"hello\");"
        let output = "print(\"hello\")"
        XCTAssertEqual(try format(input, rules: [FormatRules.semicolons]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSemicolonRemovedAtStartOfProgram() {
        let input = ";print(\"hello\")"
        let output = "print(\"hello\")"
        XCTAssertEqual(try format(input, rules: [FormatRules.semicolons]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testIgnoreInlineSemicolon() {
        let input = "print(\"hello\"); print(\"goodbye\")"
        let output = "print(\"hello\"); print(\"goodbye\")"
        let options = FormatOptions(allowInlineSemicolons: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.semicolons], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testReplaceInlineSemicolon() {
        let input = "print(\"hello\"); print(\"goodbye\")"
        let output = "print(\"hello\")\nprint(\"goodbye\")"
        let options = FormatOptions(allowInlineSemicolons: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.semicolons], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testReplaceSemicolonFollowedByComment() {
        let input = "print(\"hello\"); // comment\nprint(\"goodbye\")"
        let output = "print(\"hello\") // comment\nprint(\"goodbye\")"
        let options = FormatOptions(allowInlineSemicolons: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.semicolons], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testSemicolonsNotReplacedInForLoop() {
        let input = "for (i = 0; i < 5; i++)"
        let output = "for (i = 0; i < 5; i++)"
        let options = FormatOptions(allowInlineSemicolons: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.semicolons], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testSemicolonsNotReplacedInForLoopContainingComment() {
        let input = "for (i = 0 // comment\n    ; i < 5; i++)"
        let output = "for (i = 0 // comment\n    ; i < 5; i++)"
        let options = FormatOptions(allowInlineSemicolons: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.semicolons], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testSemicolonNotReplacedAfterReturn() {
        let input = "return;\nfoo()"
        let output = "return;\nfoo()"
        XCTAssertEqual(try format(input, rules: [FormatRules.semicolons]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSemicolonReplacedAfterReturnIfEndOfScope() {
        let input = "{ return; }"
        let output = "{ return }"
        XCTAssertEqual(try format(input, rules: [FormatRules.semicolons]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: ranges

    func testSpaceAroundRangeOperatorsWithDefaultOptions() {
        let input = "foo..<bar"
        let output = "foo ..< bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.ranges]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoSpaceAroundRangeOperatorsWithCustomOptions() {
        let input = "foo ..< bar"
        let output = "foo..<bar"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.ranges], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testNoSpaceAddedAroundVariadic() {
        let input = "foo(bar: Int...)"
        let output = "foo(bar: Int...)"
        let options = FormatOptions(spaceAroundRangeOperators: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.ranges], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testNoSpaceAddedAroundVariadicWithComment() {
        let input = "foo(bar: Int.../* one or more */)"
        let output = "foo(bar: Int.../* one or more */)"
        let options = FormatOptions(spaceAroundRangeOperators: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.ranges], options: options), output)
    }

    func testNoSpaceAddedAroundVariadicThatIsntLastArg() {
        let input = "foo(bar: Int..., baz: Int)"
        let output = "foo(bar: Int..., baz: Int)"
        let options = FormatOptions(spaceAroundRangeOperators: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.ranges], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testNoSpaceAddedAroundSplitLineVariadic() {
        let input = "foo(\n    bar: Int...\n)"
        let output = "foo(\n    bar: Int...\n)"
        let options = FormatOptions(spaceAroundRangeOperators: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.ranges], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    // MARK: specifiers

    func testVarSpecifiersCorrected() {
        let input = "unowned private static var foo"
        let output = "private unowned static var foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.specifiers]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testPrivateSetSpecifierNotMangled() {
        let input = "public private(set) weak lazy var foo"
        let output = "private(set) public lazy weak var foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.specifiers]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testPrivateRequiredStaticFuncSpecifiers() {
        let input = "required static private func foo()"
        let output = "private required static func foo()"
        XCTAssertEqual(try format(input, rules: [FormatRules.specifiers]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testPrivateConvenienceInit() {
        let input = "convenience private init()"
        let output = "private convenience init()"
        XCTAssertEqual(try format(input, rules: [FormatRules.specifiers]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceInSpecifiersLeftIntact() {
        let input = "weak private(set) /* read-only */\npublic var"
        let output = "private(set) /* read-only */\npublic weak var"
        XCTAssertEqual(try format(input, rules: [FormatRules.specifiers]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testPrefixSpecifier() {
        let input = "prefix public static func -(rhs: Foo) -> Foo"
        let output = "public static prefix func -(rhs: Foo) -> Foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.specifiers]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: void

    func testEmptyParensReturnValueConvertedToVoid() {
        let input = "() -> ()"
        let output = "() -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpacedParensReturnValueConvertedToVoid() {
        let input = "() -> ( \n)"
        let output = "() -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testParensContainingCommentNotConvertedToVoid() {
        let input = "() -> ( /* Hello World */ )"
        let output = "() -> ( /* Hello World */ )"
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testParensRemovedAroundVoid() {
        let input = "() -> (Void)"
        let output = "() -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testVoidArgumentConvertedToEmptyParens() {
        let input = "Void -> Void"
        let output = "() -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testVoidArgumentInParensConvertedToEmptyParens() {
        let input = "(Void) -> Void"
        let output = "() -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testAnonymousVoidArgumentConvertedToEmptyParens() {
        let input = "(_: Void) -> Void"
        let output = "() -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testFunctionThatReturnsAFunction() {
        let input = "(Void) -> Void -> ()"
        let output = "() -> () -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testFunctionThatReturnsAFunctionThatThrows() {
        let input = "(Void) -> Void throws -> ()"
        let output = "() -> () throws -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testChainOfFunctionsIsNotChanged() {
        let input = "() -> () -> () -> Void"
        let output = "() -> () -> () -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testChainOfFunctionsWithThrowsIsNotChanged() {
        let input = "() -> () throws -> () throws -> Void"
        let output = "() -> () throws -> () throws -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testVoidThrowsIsNotMangled() {
        let input = "(Void) throws -> Void"
        let output = "() throws -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testEmptyClosureArgsNotMangled() {
        let input = "{ () in }"
        let output = "{ () in }"
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testAnonymousVoidClosureArgConvertedToEmptyParens() {
        let input = "{ (_: Void) in }"
        let output = "{ () in }"
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: useVoid = false

    func testUseVoidOptionFalse() {
        let input = "(Void) -> Void"
        let output = "() -> ()"
        let options = FormatOptions(useVoid: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.void], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testNamespacedVoidNotConverted() {
        let input = "() -> Swift.Void"
        let output = "() -> Swift.Void"
        let options = FormatOptions(useVoid: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.void], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testTypealiasVoidNotConverted() {
        let input = "public typealias Void = ()"
        let output = "public typealias Void = ()"
        let options = FormatOptions(useVoid: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.void], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    // MARK: redundantParens

    // MARK: around expressions

    func testRedundantParensRemoved() {
        let input = "if (x || y) {}"
        let output = "if x || y {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testRedundantParensRemoved2() {
        let input = "if (x) || y {}"
        let output = "if x || y {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testRedundantParensRemoved3() {
        let input = "if x + (5) == 6 {}"
        let output = "if x + 5 == 6 {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testRedundantParensRemoved4() {
        let input = "if (x || y), let foo = bar {}"
        let output = "if x || y, let foo = bar {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testRequiredParensNotRemoved() {
        let input = "if (x || y) * z {}"
        let output = "if (x || y) * z {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testOuterParensRemoved() {
        let input = "while ((x || y) && z) {}"
        let output = "while (x || y) && z {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSwitchTupleNotUnwrapped() {
        let input = "switch (x, y) {}"
        let output = "switch (x, y) {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testIfClosureNotUnwrapped() {
        let input = "if (foo.contains { bar }) {}"
        let output = "if (foo.contains { bar }) {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testGuardParensRemoved() {
        let input = "guard (x == y) else { return }"
        let output = "guard x == y else { return }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testForValueParensRemoved() {
        let input = "for (x) in (y) {}"
        let output = "for x in y {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testParensInStringNotRemoved() {
        let input = "\"hello \\(world)\""
        let output = "\"hello \\(world)\""
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testClosureTypeNotUnwrapped() {
        let input = "foo = (Bar) -> Baz"
        let output = "foo = (Bar) -> Baz"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testOptionalFunctionCallNotUnwrapped() {
        let input = "foo?(bar)"
        let output = "foo?(bar)"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testForceUnwrapFunctionCallNotUnwrapped() {
        let input = "foo!(bar)"
        let output = "foo!(bar)"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testCurriedFunctionCallNotUnwrapped() {
        let input = "foo(bar)(baz)"
        let output = "foo(bar)(baz)"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSubscriptFunctionCallNotUnwrapped() {
        let input = "foo[\"bar\"](baz)"
        let output = "foo[\"bar\"](baz)"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceInsertedWhenRemovingParens() {
        let input = "if(x.y) {}"
        let output = "if x.y {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSpaceInsertedWhenRemovingParens2() {
        let input = "while(!foo) {}"
        let output = "while !foo {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoDoubleSpaceWhenRemovingParens() {
        let input = "if ( x.y ) {}"
        let output = "if x.y {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoDoubleSpaceWhenRemovingParens2() {
        let input = "if (x.y) {}"
        let output = "if x.y {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testParensAroundRangeNotRemoved() {
        let input = "(1 ..< 10).reduce(0, combine: +)"
        let output = "(1 ..< 10).reduce(0, combine: +)"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: around closure arguments

    func testSingleClosureArgumentUnwrapped() {
        let input = "{ (_) in }"
        let output = "{ _ in }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testTypedClosureArgumentNotUnwrapped() {
        let input = "{ (foo: Int) in print(foo) }"
        let output = "{ (foo: Int) in print(foo) }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSingleClosureArgumentAfterCaptureListUnwrapped() {
        let input = "{ [weak self] (foo) in self.bar(foo) }"
        let output = "{ [weak self] foo in self.bar(foo) }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testMultipleClosureArgumentUnwrapped() {
        let input = "{ (foo, bar) in foo(bar) }"
        let output = "{ foo, bar in foo(bar) }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testTypedMultipleClosureArgumentNotUnwrapped() {
        let input = "{ (foo: Int, bar: String) in foo(bar) }"
        let output = "{ (foo: Int, bar: String) in foo(bar) }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testEmptyClosureArgsNotUnwrapped() {
        let input = "{ () in }"
        let output = "{ () in }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: before trailing closure

    func testParensRemovedBeforeTrailingClosure() {
        let input = "var foo = bar() { /* some code */ }"
        let output = "var foo = bar { /* some code */ }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testParensRemovedBeforeTrailingClosure2() {
        let input = "let foo = bar() { /* some code */ }"
        let output = "let foo = bar { /* some code */ }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testParensNotRemovedBeforeVarBody() {
        let input = "var foo = bar() { didSet {} }"
        let output = "var foo = bar() { didSet {} }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testParensNotRemovedBeforeFunctionBody() {
        let input = "func bar() { /* some code */ }"
        let output = "func bar() { /* some code */ }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testParensNotRemovedBeforeIfBody() {
        let input = "if let foo = bar() { /* some code */ }"
        let output = "if let foo = bar() { /* some code */ }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testParensNotRemovedBeforeIfBodyAfterTry() {
        let input = "if let foo = try bar() { /* some code */ }"
        let output = "if let foo = try bar() { /* some code */ }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testParensNotRemovedBeforeCompoundIfBody() {
        let input = "if let foo = bar(), let baz = quux() { /* some code */ }"
        let output = "if let foo = bar(), let baz = quux() { /* some code */ }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testParensNotRemovedBeforeForBody() {
        let input = "for foo in bar() { /* some code */ }"
        let output = "for foo in bar() { /* some code */ }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testParensNotRemovedBeforeWhileBody() {
        let input = "while let foo = bar() { /* some code */ }"
        let output = "while let foo = bar() { /* some code */ }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testParensNotRemovedBeforeCaseBody() {
        let input = "if case foo = bar() { /* some code */ }"
        let output = "if case foo = bar() { /* some code */ }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testParensNotRemovedBeforeSwitchBody() {
        let input = "switch foo() {\ndefault: break\n}"
        let output = "switch foo() {\ndefault: break\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: closure expression

    func testParensAroundClosureRemoved() {
        let input = "let foo = ({ /* some code */ })"
        let output = "let foo = { /* some code */ }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testParensAroundClosureAssignmentBlockRemoved() {
        let input = "let foo = ({ /* some code */ })()"
        let output = "let foo = { /* some code */ }()"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testParensAroundClosureInCompoundExpressionRemoved() {
        let input = "if foo == ({ /* some code */ }), let bar = baz {}"
        let output = "if foo == { /* some code */ }, let bar = baz {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: trailingClosures

    func testClosureArgumentMadeTrailing() {
        let input = "foo(foo: 5, bar: { /* some code */ })"
        let output = "foo(foo: 5) { /* some code */ }"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testClosureArgumentInFunctionThatReturnsClosureNotMadeTrailing() {
        // NOTE: this is actually permitted by the compiler, but harms clarity IMHO
        let input = "foo(foo: 5, bar: { /* some code */ })()"
        let output = "foo(foo: 5, bar: { /* some code */ })()"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testClosureArgumentPassedToFunctionInArgumentsNotMadeTrailing() {
        let input = "foo(bar { /* some code */ })"
        let output = "foo(bar { /* some code */ })"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testClosureArgumentInFunctionWithOtherClosureArgumentsNotMadeTrailing() {
        let input = "foo(foo: { /* some code */ }, bar: { /* some code */ })"
        let output = "foo(foo: { /* some code */ }, bar: { /* some code */ })"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testClosureArgumentInExpressionNotMadeTrailing() {
        let input = "if let foo = foo(foo: 5, bar: { /* some code */ }) {}"
        let output = "if let foo = foo(foo: 5, bar: { /* some code */ }) {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testClosureArgumentInCompoundExpressionNotMadeTrailing() {
        let input = "if let foo = foo(foo: 5, bar: { /* some code */ }), bar = baz {}"
        let output = "if let foo = foo(foo: 5, bar: { /* some code */ }), bar = baz {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testClosureArgumentAfterLinebreakNotMadeTrailing() {
        let input = "guard let foo =\n    bar({ /* some code */ })\nelse { return }"
        let output = "guard let foo =\n    bar({ /* some code */ })\nelse { return }"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: solitary argument

    func testParensAroundSolitaryClosureArgumentRemoved() {
        let input = "foo({ /* some code */ })"
        let output = "foo { /* some code */ }"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensAroundNamedSolitaryClosureArgumentRemoved() {
        let input = "foo(foo: { /* some code */ })"
        let output = "foo { /* some code */ }"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensAroundSolitaryClosureArgumentInFunctionThatReturnsClosureNotRemoved() {
        // NOTE: this is actually permitted by the compiler, but harms clarity IMHO
        let input = "foo({ /* some code */ })()"
        let output = "foo({ /* some code */ })()"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensAroundSolitaryClosureArgumentInExpressionNotRemoved() {
        let input = "if let foo = foo({ /* some code */ }) {}"
        let output = "if let foo = foo({ /* some code */ }) {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensAroundSolitaryClosureArgumentInCompoundExpressionNotRemoved() {
        let input = "if let foo = foo({ /* some code */ }), bar = baz {}"
        let output = "if let foo = foo({ /* some code */ }), bar = baz {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: redundantGet

    func testRemoveSingleLineIsolatedGet() {
        let input = "var foo: Int { get { return 5 } }"
        let output = "var foo: Int { return 5 }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantGet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testRemoveMultilineIsolatedGet() {
        let input = "var foo: Int {\n    get {\n        return 5\n    }\n}"
        let output = "var foo: Int {\n    return 5\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantGet, FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoRemoveMultilineGetSet() {
        let input = "var foo: Int {\n    get { return 5 }\n    set { foo = newValue }\n}"
        let output = "var foo: Int {\n    get { return 5 }\n    set { foo = newValue }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantGet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoRemoveAttributedGet() {
        let input = "var enabled: Bool { @objc(isEnabled) get { return true } }"
        let output = "var enabled: Bool { @objc(isEnabled) get { return true } }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantGet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testRemoveSubscriptGet() {
        let input = "subscript(_ index: Int) {\n    get {\n        return 5\n    }\n}"
        let output = "subscript(_ index: Int) {\n    return 5\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantGet, FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: redundantNilInit

    func testRemoveRedundantNilInit() {
        let input = "var foo: Int? = nil\nlet bar: Int? = nil"
        let output = "var foo: Int?\nlet bar: Int? = nil"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantNilInit]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoRemoveLetNilInitAfterVar() {
        let input = "var foo: Int; let bar: Int? = nil"
        let output = "var foo: Int; let bar: Int? = nil"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantNilInit]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoRemoveNonNilInit() {
        let input = "var foo: Int? = 0"
        let output = "var foo: Int? = 0"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantNilInit]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testRemoveRedundantImplicitUnwrapInit() {
        let input = "var foo: Int! = nil"
        let output = "var foo: Int!"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantNilInit]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testRemoveMultipleRedundantNilInitsInSameLine() {
        let input = "var foo: Int? = nil, bar: Int? = nil"
        let output = "var foo: Int?, bar: Int?"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantNilInit]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: redundantLet

    func testRemoveRedundantLet() {
        let input = "let _ = bar {}"
        let output = "_ = bar {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoRemoveLetWithType() {
        let input = "let _: String = bar {}"
        let output = "let _: String = bar {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testRemoveRedundantLetInCase() {
        let input = "if case .foo(let _) = bar {}"
        let output = "if case .foo(_) = bar {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantLet]), output)
        let rules = FormatRules.all(except: ["redundantPattern"])
        XCTAssertEqual(try format(input + "\n", rules: rules), output + "\n")
    }

    func testRemoveRedundantVarsInCase() {
        let input = "if case .foo(var _, var /* unused */ _) = bar {}"
        let output = "if case .foo(_, /* unused */ _) = bar {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoRemoveLetInIf() {
        let input = "if let _ = foo {}"
        let output = "if let _ = foo {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoRemoveLetInMultiIf() {
        let input = "if foo == bar, /* comment! */ let _ = baz {}"
        let output = "if foo == bar, /* comment! */ let _ = baz {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoRemoveLetInGuard() {
        let input = "guard let _ = foo else {}"
        let output = "guard let _ = foo else {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoRemoveLetInWhile() {
        let input = "while let _ = foo {}"
        let output = "while let _ = foo {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: redundantPattern

    func testRemoveRedundantPatternInIfCase() {
        let input = "if case .foo(_, _) = bar {}"
        let output = "if case .foo = bar {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantPattern]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoRemoveRequiredPatternInIfCase() {
        let input = "if case (_, _) = bar {}"
        let output = "if case (_, _) = bar {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantPattern]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testRemoveRedundantPatternInSwitchCase() {
        let input = "switch foo {\ncase .bar(_, _): break\ndefault: break\n}"
        let output = "switch foo {\ncase .bar: break\ndefault: break\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantPattern]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoRemoveRequiredPatternInSwitchCase() {
        let input = "switch foo {\ncase (_, _): break\ndefault: break\n}"
        let output = "switch foo {\ncase (_, _): break\ndefault: break\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantPattern]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testSimplifyLetPattern() {
        let input = "let(_, _) = bar"
        let output = "let _ = bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantPattern]), output)
        let rules = FormatRules.all(except: ["redundantLet"])
        XCTAssertEqual(try format(input + "\n", rules: rules), output + "\n")
    }

    func testNoRemoveVoidFunctionCall() {
        let input = "if case .foo() = bar {}"
        let output = "if case .foo() = bar {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantPattern]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoRemoveMethodSignature() {
        let input = "func foo(_, _) {}"
        let output = "func foo(_, _) {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantPattern]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: redundantRawValues

    func testRemoveRedundantRawString() {
        let input = "enum Foo: String {\n    case bar = \"bar\"\n    case baz = \"baz\"\n}"
        let output = "enum Foo: String {\n    case bar\n    case baz\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantRawValues]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testRemoveCommaDelimitedCaseRawStringCases() {
        let input = "enum Foo: String { case bar = \"bar\", baz = \"baz\" }"
        let output = "enum Foo: String { case bar, baz }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantRawValues]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoRemoveRawStringIfNameDoesntMatch() {
        let input = "enum Foo: String {\n    case bar = \"foo\"\n}"
        let output = "enum Foo: String {\n    case bar = \"foo\"\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantRawValues]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: redundantVoidReturnType

    func testRemoveRedundantVoidReturnType() {
        let input = "func foo() -> Void {}"
        let output = "func foo() {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantVoidReturnType]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testRemoveRedundantEmptyReturnType() {
        let input = "func foo() -> () {}"
        let output = "func foo() {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantVoidReturnType]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testRemoveRedundantVoidTupleReturnType() {
        let input = "func foo() -> (Void) {}"
        let output = "func foo() {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantVoidReturnType]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoRemoveCommentFollowingRedundantVoidReturnType() {
        let input = "func foo() -> Void /* void */ {}"
        let output = "func foo() /* void */ {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantVoidReturnType]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoRemoveRequiredVoidReturnType() {
        let input = "typealias Foo = () -> Void"
        let output = "typealias Foo = () -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantVoidReturnType]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoRemoveChainedVoidReturnType() {
        let input = "func foo() -> () -> Void {}"
        let output = "func foo() -> () -> Void {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantVoidReturnType]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testRemoveRedundantVoidInClosureArguments() {
        let input = "{ (foo: Bar) -> Void in foo() }"
        let output = "{ (foo: Bar) in foo() }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantVoidReturnType]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: unusedArguments

    // MARK: closures

    func testUnusedTypedClosureArguments() {
        let input = "let foo = { (bar: Int, baz: String) in\n    print(\"Hello \\(baz)\")\n}"
        let output = "let foo = { (_: Int, baz: String) in\n    print(\"Hello \\(baz)\")\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testUnusedUntypedClosureArguments() {
        let input = "let foo = { bar, baz in\n    print(\"Hello \\(baz)\")\n}"
        let output = "let foo = { _, baz in\n    print(\"Hello \\(baz)\")\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoRemoveClosureReturnType() {
        let input = "let foo = { () -> Foo.Bar in baz() }"
        let output = "let foo = { () -> Foo.Bar in baz() }"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoRemoveClosureThrows() {
        let input = "let foo = { () throws in }"
        let output = "let foo = { () throws in }"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoRemoveClosureGenericReturnTypes() {
        let input = "let foo = { () -> Promise<String> in return bar }"
        let output = "let foo = { () -> Promise<String> in return bar }"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoRemoveClosureTupleReturnTypes() {
        let input = "let foo = { () -> (Int, Int) in return (5, 6) }"
        let output = "let foo = { () -> (Int, Int) in return (5, 6) }"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoRemoveClosureGenericArgumentTypes() {
        let input = "let foo = { (_: Foo<Bar, Baz>) in }"
        let output = "let foo = { (_: Foo<Bar, Baz>) in }"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoRemoveFunctionNameBeforeForLoop() {
        let input = "{\n    func foo() -> Int {}\n    for a in b {}\n}"
        let output = "{\n    func foo() -> Int {}\n    for a in b {}\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testClosureTypeInClosureArgumentsIsNotMangled() {
        let input = "{ (foo: (Int) -> Void) in }"
        let output = "{ (_: (Int) -> Void) in }"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testUnusedUnnamedClosureArgument() {
        let input = "{ (_ foo: Int) in }"
        let output = "{ (_: Int) in }"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testUnusedInoutClosureArgumentIsNotMangled() {
        let input = "{ (foo: inout Foo) in }"
        let output = "{ (_: inout Foo) in }"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: functions

    func testMarkUnusedFunctionArgument() {
        let input = "func foo(bar: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        let output = "func foo(bar _: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testMarkUnusedArgumentsInNonVoidFunction() {
        let input = "func foo(bar: Int, baz: String) -> (A<B, C>, D & E, [F: G]) { return baz.quux }"
        let output = "func foo(bar _: Int, baz: String) -> (A<B, C>, D & E, [F: G]) { return baz.quux }"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testMarkUnusedArgumentsInThrowsFunction() {
        let input = "func foo(bar: Int, baz: String) throws {\n    print(\"Hello \\(baz)\")\n}"
        let output = "func foo(bar _: Int, baz: String) throws {\n    print(\"Hello \\(baz)\")\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoMarkUnusedArgumentsInProtocolFunction() {
        let input = "protocol Foo {\n    func foo(bar: Int) -> Int\n    var bar: Int { get }\n}"
        let output = "protocol Foo {\n    func foo(bar: Int) -> Int\n    var bar: Int { get }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testUnusedUnnamedFunctionArgument() {
        let input = "func foo(_ foo: Int) {}"
        let output = "func foo(_: Int) {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testUnusedInoutFunctionArgumentIsNotMangled() {
        let input = "func foo(_ foo: inout Foo) {}"
        let output = "func foo(_: inout Foo) {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testUnusedInternallyRenamedFunctionArgument() {
        let input = "func foo(foo bar: Int) {}"
        let output = "func foo(foo _: Int) {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testNoMarkProtocolFunctionArgument() {
        let input = "func foo(foo bar: Int)\nvar bar: Bool { get }"
        let output = "func foo(foo bar: Int)\nvar bar: Bool { get }"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testMembersAreNotArguments() {
        let input = "func foo(bar: Int, baz: String) {\n    print(\"Hello \\(bar.baz)\")\n}"
        let output = "func foo(bar: Int, baz _: String) {\n    print(\"Hello \\(bar.baz)\")\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testLabelsAreNotArguments() {
        let input = "func foo(bar: Int, baz: String) {\n    bar: while true { print(baz) }\n}"
        let output = "func foo(bar _: Int, baz: String) {\n    bar: while true { print(baz) }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testDictionaryLiteralsRuinEverything() {
        let input = "func foo(bar: Int, baz: Int) {\n    let quux = [bar: 1, baz: 2]\n}"
        let output = "func foo(bar: Int, baz: Int) {\n    let quux = [bar: 1, baz: 2]\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testOperatorArgumentsAreUnnamed() {
        let input = "func ==(lhs: Int, rhs: Int) { return false }"
        let output = "func ==(_: Int, _: Int) { return false }"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    // MARK: functions (closure-only)

    func testNoMarkFunctionArgument() {
        let input = "func foo(_ bar: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        let output = "func foo(_ bar: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        let options = FormatOptions(stripUnusedArguments: .closureOnly)
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    // MARK: functions (unnamed-only)

    func testNoMarkNamedFunctionArgument() {
        let input = "func foo(bar: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        let output = "func foo(bar: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        let options = FormatOptions(stripUnusedArguments: .unnamedOnly)
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testRemoveUnnamedFunctionArgument() {
        let input = "func foo(_ foo: Int) {}"
        let output = "func foo(_: Int) {}"
        let options = FormatOptions(stripUnusedArguments: .unnamedOnly)
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testRemoveInternalFunctionArgumentName() {
        let input = "func foo(foo bar: Int) {}"
        let output = "func foo(foo bar: Int) {}"
        let options = FormatOptions(stripUnusedArguments: .unnamedOnly)
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    // MARK: wrapArguments

    func testWrapAfterFirstConvertedToWrapBefore() {
        let input = "func foo(bar _: Int,\n    baz _: String) {\n}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {\n}"
        let options = FormatOptions(wrapArguments: .beforeFirst)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testLinebreakInsertedAtEndOfWrappedFunction() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String) {\n}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {\n}"
        let options = FormatOptions(wrapArguments: .beforeFirst)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testAfterFirstConvertedToBeforeFirst() {
        let input = "func foo(bar _: Int,\n         baz _: String) {\n}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {\n}"
        let options = FormatOptions(wrapArguments: .beforeFirst)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testBeforeFirstConvertedToAfterFirst() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String\n) {\n}"
        let output = "func foo(bar _: Int,\n         baz _: String) {\n}"
        let options = FormatOptions(wrapArguments: .afterFirst)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testNoWrapInnerArguments() {
        let input = "func foo(\n    bar _: Int,\n    baz _: foo(bar, baz)\n) {\n}"
        let output = "func foo(bar _: Int,\n         baz _: foo(bar, baz)) {\n}"
        let options = FormatOptions(wrapArguments: .afterFirst)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testCorrectWrapIndentForNestedArguments() {
        let input = "foo(\nbar: (\nx: 0,\ny: 0\n),\nbaz: (\nx: 0,\ny: 0\n)\n)"
        let output = "foo(bar: (x: 0,\n          y: 0),\n    baz: (x: 0,\n          y: 0))"
        let options = FormatOptions(wrapArguments: .afterFirst)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testNoRemoveLinebreakAfterCommentInArguments() {
        let input = "a(b // comment\n)"
        let output = "a(b) // comment\n"
        let options = FormatOptions(wrapArguments: .afterFirst)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output)
    }

    // MARK: wrapElements

    func testNoDoubleSpaceAddedToWrappedArray() {
        let input = "[ foo,\n    bar ]"
        let output = "[\n    foo,\n    bar\n]"
        let options = FormatOptions(trailingCommas: false, wrapElements: .beforeFirst)
        let rules = [FormatRules.wrapArguments, FormatRules.spaceInsideBrackets]
        XCTAssertEqual(try format(input, rules: rules, options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testTrailingCommasAddedToWrappedArray() {
        let input = "[foo,\n    bar]"
        let output = "[\n    foo,\n    bar,\n]"
        let options = FormatOptions(trailingCommas: true, wrapElements: .beforeFirst)
        let rules = [FormatRules.wrapArguments, FormatRules.trailingCommas]
        XCTAssertEqual(try format(input, rules: rules, options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testSpaceAroundEnumValuesInArray() {
        let input = "[\n    .foo,\n    .bar, .baz,\n]"
        let output = "[\n    .foo,\n    .bar, .baz,\n]"
        let options = FormatOptions(wrapElements: .beforeFirst)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testTrailingCommaRemovedInWrappedArray() {
        let input = "[\n    .foo,\n    .bar,\n    .baz,\n]"
        let output = "[.foo,\n .bar,\n .baz]"
        let options = FormatOptions(wrapElements: .afterFirst)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testNoRemoveLinebreakAfterCommentInElements() {
        let input = "[a, // comment\n]"
        let output = "[a] // comment\n"
        let options = FormatOptions(wrapElements: .afterFirst)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output)
    }

    // MARK: numberFormatting

    // MARK: hex case

    func testLowercaseLiteralConvertedToUpper() {
        let input = "let foo = 0xabcd"
        let output = "let foo = 0xABCD"
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testMixedCaseLiteralConvertedToUpper() {
        let input = "let foo = 0xaBcD"
        let output = "let foo = 0xABCD"
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testUppercaseLiteralConvertedToLower() {
        let input = "let foo = 0xABCD"
        let output = "let foo = 0xabcd"
        let options = FormatOptions(uppercaseHex: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testPInExponentialNotConvertedToUpper() {
        let input = "let foo = 0xaBcDp5"
        let output = "let foo = 0xABCDp5"
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testPInExponentialNotConvertedToLower() {
        let input = "let foo = 0xaBcDP5"
        let output = "let foo = 0xabcdP5"
        let options = FormatOptions(uppercaseHex: false, uppercaseExponent: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    // MARK: decimal grouping

    func testDefaultDecimalGrouping() {
        let input = "let foo = 1234_56_78"
        let output = "let foo = 12_345_678"
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testIgnoreDecimalGrouping() {
        let input = "let foo = 1234_5_678"
        let output = "let foo = 1234_5_678"
        let options = FormatOptions(decimalGrouping: .ignore)
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testNoDecimalGrouping() {
        let input = "let foo = 1234_5_678"
        let output = "let foo = 12345678"
        let options = FormatOptions(decimalGrouping: .none)
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testDecimalGroupingThousands() {
        let input = "let foo = 1234"
        let output = "let foo = 1_234"
        let options = FormatOptions(decimalGrouping: .group(3, 3))
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testExponentialGrouping() {
        let input = "let foo = 1234e5678"
        let output = "let foo = 1_234e5678"
        let options = FormatOptions(decimalGrouping: .group(3, 3))
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    // MARK: binary grouping

    func testDefaultBinaryGrouping() {
        let input = "let foo = 0b11101000_00111111"
        let output = "let foo = 0b1110_1000_0011_1111"
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testIgnoreBinaryGrouping() {
        let input = "let foo = 0b1110_10_00"
        let output = "let foo = 0b1110_10_00"
        let options = FormatOptions(binaryGrouping: .ignore)
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testNoBinaryGrouping() {
        let input = "let foo = 0b1110_10_00"
        let output = "let foo = 0b11101000"
        let options = FormatOptions(binaryGrouping: .none)
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testBinaryGroupingCustom() {
        let input = "let foo = 0b110011"
        let output = "let foo = 0b11_00_11"
        let options = FormatOptions(binaryGrouping: .group(2, 2))
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    // MARK: hex grouping

    func testDefaultHexGrouping() {
        let input = "let foo = 0xFF01FF01AE45"
        let output = "let foo = 0xFF01_FF01_AE45"
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testCustomHexGrouping() {
        let input = "let foo = 0xFF00p54"
        let output = "let foo = 0xFF_00p54"
        let options = FormatOptions(hexGrouping: .group(2, 2))
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    // MARK: octal grouping

    func testDefaultOctalGrouping() {
        let input = "let foo = 0o123456701234"
        let output = "let foo = 0o1234_5670_1234"
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testCustomOctalGrouping() {
        let input = "let foo = 0o12345670"
        let output = "let foo = 0o12_34_56_70"
        let options = FormatOptions(octalGrouping: .group(2, 2))
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    // MARK: exponent case

    func testLowercaseExponent() {
        let input = "let foo = 0.456E-5"
        let output = "let foo = 0.456e-5"
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testUppercaseExponent() {
        let input = "let foo = 0.456e-5"
        let output = "let foo = 0.456E-5"
        let options = FormatOptions(uppercaseExponent: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testUppercaseHexExponent() {
        let input = "let foo = 0xFF00p54"
        let output = "let foo = 0xFF00P54"
        let options = FormatOptions(uppercaseExponent: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testUppercaseGroupedHexExponent() {
        let input = "let foo = 0xFF00_AABB_CCDDp54"
        let output = "let foo = 0xFF00_AABB_CCDDP54"
        let options = FormatOptions(uppercaseExponent: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    // MARK: stripHeader

    func testStripHeader() {
        let input = "//\n//  test.swift\n//  SwiftFormat\n//\n//  Created by Nick Lockwood on 08/11/2016.\n//  Copyright © 2016 Nick Lockwood. All rights reserved.\n//\n\n// func\nfunc foo() {}"
        let output = "// func\nfunc foo() {}"
        let options = FormatOptions(stripHeader: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.stripHeader], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testNoStripHeaderWhenDisabled() {
        let input = "//\n//  test.swift\n//  SwiftFormat\n//\n//  Created by Nick Lockwood on 08/11/2016.\n//  Copyright © 2016 Nick Lockwood. All rights reserved.\n//\n\n// func\nfunc foo() {}"
        let output = "//\n//  test.swift\n//  SwiftFormat\n//\n//  Created by Nick Lockwood on 08/11/2016.\n//  Copyright © 2016 Nick Lockwood. All rights reserved.\n//\n\n// func\nfunc foo() {}"
        let options = FormatOptions(stripHeader: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.stripHeader], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }

    func testNoStripComment() {
        let input = "\n// func\nfunc foo() {}"
        let output = "\n// func\nfunc foo() {}"
        let options = FormatOptions(stripHeader: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.stripHeader], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default, options: options), output + "\n")
    }
}
