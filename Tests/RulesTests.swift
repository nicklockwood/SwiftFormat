//
//  RulesTests.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 12/08/2016.
//  Copyright 2016 Nick Lockwood
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/SwiftFormat
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
@testable import SwiftFormat

class RulesTests: XCTestCase {
    // MARK: - shared test infra

    func testFormatting(for input: String, _ output: String? = nil, rule: FormatRule,
                        options: FormatOptions = .default, exclude: [String] = []) {
        testFormatting(for: input, output.map { [$0] } ?? [], rules: [rule],
                       options: options, exclude: exclude)
    }

    func testFormatting(for input: String, _ outputs: [String] = [], rules: [FormatRule],
                        options: FormatOptions = .default, exclude: [String] = []) {
        precondition(input != outputs.first || input != outputs.last, "Redundant output parameter")
        precondition((0 ... 2).contains(outputs.count), "Only 0, 1 or 2 output parameters permitted")
        precondition(Set(exclude).intersection(rules.map { $0.name }).isEmpty, "Cannot exclude rule under test")
        let output = outputs.first ?? input, output2 = outputs.last ?? input
        let exclude = exclude + (rules.first?.name == "linebreakAtEndOfFile" ? [] : ["linebreakAtEndOfFile"])
        XCTAssertEqual(try format(input, rules: rules, options: options), output)
        XCTAssertEqual(try format(input, rules: FormatRules.all(except: exclude),
                                  options: options), output2)
        if input != output {
            XCTAssertEqual(try format(output, rules: rules, options: options), output)
        }
        if input != output2, output != output2 {
            XCTAssertEqual(try format(output2, rules: FormatRules.all(except: exclude),
                                      options: options), output2)
        }

        #if os(macOS)
            // These tests are flakey on Linux, and it's hard to debug
            XCTAssertEqual(try lint(output, rules: rules, options: options), [])
            XCTAssertEqual(try lint(output2, rules: FormatRules.all(except: exclude),
                                    options: options), [])
        #endif
    }

    // MARK: - spaceAroundParens

    func testSpaceAfterSet() {
        let input = "private(set)var foo: Int"
        let output = "private(set) var foo: Int"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testAddSpaceBetweenParenAndClass() {
        let input = "@objc(XYZFoo)class foo"
        let output = "@objc(XYZFoo) class foo"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testAddSpaceBetweenConventionAndBlock() {
        let input = "@convention(block)() -> Void"
        let output = "@convention(block) () -> Void"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testAddSpaceBetweenConventionAndEscaping() {
        let input = "@convention(block)@escaping () -> Void"
        let output = "@convention(block) @escaping () -> Void"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testAddSpaceBetweenAutoclosureEscapingAndBlock() { // Swift 2.3 only
        let input = "@autoclosure(escaping)() -> Void"
        let output = "@autoclosure(escaping) () -> Void"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testSpaceBetweenParenAndAs() {
        let input = "(foo.bar) as? String"
        testFormatting(for: input, rule: FormatRules.spaceAroundParens, exclude: ["redundantParens"])
    }

    func testNoSpaceAfterParenAtEndOfFile() {
        let input = "(foo.bar)"
        testFormatting(for: input, rule: FormatRules.spaceAroundParens, exclude: ["redundantParens"])
    }

    func testSpaceBetweenParenAndFoo() {
        let input = "func foo ()"
        let output = "func foo()"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testNoSpaceBetweenParenAndInit() {
        let input = "init ()"
        let output = "init()"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testNoSpaceBetweenObjcAndSelector() {
        let input = "@objc (XYZFoo) class foo"
        let output = "@objc(XYZFoo) class foo"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testNoSpaceBetweenHashSelectorAndBrace() {
        let input = "#selector(foo)"
        testFormatting(for: input, rule: FormatRules.spaceAroundParens)
    }

    func testNoSpaceBetweenHashKeyPathAndBrace() {
        let input = "#keyPath (foo.bar)"
        let output = "#keyPath(foo.bar)"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testNoSpaceBetweenHashAvailableAndBrace() {
        let input = "#available (iOS 9.0, *)"
        let output = "#available(iOS 9.0, *)"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testNoSpaceBetweenPrivateAndSet() {
        let input = "private (set) var foo: Int"
        let output = "private(set) var foo: Int"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testSpaceBetweenLetAndTuple() {
        let input = "if let (foo, bar) = baz"
        testFormatting(for: input, rule: FormatRules.spaceAroundParens)
    }

    func testSpaceBetweenIfAndCondition() {
        let input = "if(a || b) == true {}"
        let output = "if (a || b) == true {}"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testNoSpaceBetweenArrayLiteralAndParen() {
        let input = "[String] ()"
        let output = "[String]()"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testAddSpaceBetweenCaptureListAndArguments() {
        let input = "{ [weak self](foo) in print(foo) }"
        let output = "{ [weak self] (foo) in print(foo) }"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens, exclude: ["redundantParens"])
    }

    func testAddSpaceBetweenCaptureListAndArguments2() {
        let input = "{ [weak self]() -> Void in }"
        let output = "{ [weak self] () -> Void in }"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testAddSpaceBetweenCaptureListAndArguments3() {
        let input = "{ [weak self]() throws -> Void in }"
        let output = "{ [weak self] () throws -> Void in }"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testSpaceBetweenClosingParenAndOpenBrace() {
        let input = "func foo(){ foo }"
        let output = "func foo() { foo }"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testNoSpaceBetweenClosingBraceAndParens() {
        let input = "{ block } ()"
        let output = "{ block }()"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testDontRemoveSpaceBetweenOpeningBraceAndParens() {
        let input = "a = (b + c)"
        testFormatting(for: input, rule: FormatRules.spaceAroundParens)
    }

    func testKeywordAsIdentifierParensSpacing() {
        let input = "if foo.let (foo, bar)"
        let output = "if foo.let(foo, bar)"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testSpaceAfterInoutParam() {
        let input = "func foo(bar _: inout(Int, String)) {}"
        let output = "func foo(bar _: inout (Int, String)) {}"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testSpaceAfterEscapingAttribute() {
        let input = "func foo(bar: @escaping() -> Void)"
        let output = "func foo(bar: @escaping () -> Void)"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testSpaceAfterAutoclosureAttribute() {
        let input = "func foo(bar: @autoclosure () -> Void)"
        testFormatting(for: input, rule: FormatRules.spaceAroundParens)
    }

    func testSpaceBeforeTupleIndexArgument() {
        let input = "foo.1 (true)"
        let output = "foo.1(true)"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    // MARK: - spaceInsideParens

    func testSpaceInsideParens() {
        let input = "( 1, ( 2, 3 ) )"
        let output = "(1, (2, 3))"
        testFormatting(for: input, output, rule: FormatRules.spaceInsideParens)
    }

    func testSpaceBeforeCommentInsideParens() {
        let input = "( /* foo */ 1, 2 )"
        let output = "( /* foo */ 1, 2)"
        testFormatting(for: input, output, rule: FormatRules.spaceInsideParens)
    }

    // MARK: - spaceAroundBrackets

    func testSubscriptNoAddSpacing() {
        let input = "foo[bar] = baz"
        testFormatting(for: input, rule: FormatRules.spaceAroundBrackets)
    }

    func testSubscriptRemoveSpacing() {
        let input = "foo [bar] = baz"
        let output = "foo[bar] = baz"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundBrackets)
    }

    func testArrayLiteralSpacing() {
        let input = "foo = [bar, baz]"
        testFormatting(for: input, rule: FormatRules.spaceAroundBrackets)
    }

    func testAsArrayCastingSpacing() {
        let input = "foo as[String]"
        let output = "foo as [String]"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundBrackets)
    }

    func testAsOptionalArrayCastingSpacing() {
        let input = "foo as? [String]"
        testFormatting(for: input, rule: FormatRules.spaceAroundBrackets)
    }

    func testIsArrayTestingSpacing() {
        let input = "if foo is[String]"
        let output = "if foo is [String]"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundBrackets)
    }

    func testKeywordAsIdentifierBracketSpacing() {
        let input = "if foo.is[String]"
        testFormatting(for: input, rule: FormatRules.spaceAroundBrackets)
    }

    func testSpaceBeforeTupleIndexSubscript() {
        let input = "foo.1 [2]"
        let output = "foo.1[2]"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundBrackets)
    }

    // MARK: - spaceInsideBrackets

    func testSpaceInsideBrackets() {
        let input = "foo[ 5 ]"
        let output = "foo[5]"
        testFormatting(for: input, output, rule: FormatRules.spaceInsideBrackets)
    }

    func testSpaceInsideWrappedArray() {
        let input = "[ foo,\n bar ]"
        let output = "[foo,\n bar]"
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, output, rule: FormatRules.spaceInsideBrackets, options: options)
    }

    func testSpaceBeforeCommentInsideWrappedArray() {
        let input = "[ // foo\n    bar,\n]"
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, rule: FormatRules.spaceInsideBrackets, options: options)
    }

    // MARK: - spaceAroundBraces

    func testSpaceAroundTrailingClosure() {
        let input = "if x{ y }else{ z }"
        let output = "if x { y } else { z }"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundBraces)
    }

    func testNoSpaceAroundClosureInsiderParens() {
        let input = "foo({ $0 == 5 })"
        testFormatting(for: input, rule: FormatRules.spaceAroundBraces, exclude: ["trailingClosures"])
    }

    func testNoExtraSpaceAroundBracesAtStartOrEndOfFile() {
        let input = "{ foo }"
        testFormatting(for: input, rule: FormatRules.spaceAroundBraces)
    }

    func testSpaceAroundBracesAfterOptionalProperty() {
        let input = "var: Foo?{}"
        let output = "var: Foo? {}"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundBraces)
    }

    func testSpaceAroundBracesAfterImplicitlyUnwrappedProperty() {
        let input = "var: Foo!{}"
        let output = "var: Foo! {}"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundBraces)
    }

    func testSpaceAroundBracesAfterNumber() {
        let input = "if x = 5{}"
        let output = "if x = 5 {}"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundBraces)
    }

    func testSpaceAroundBracesAfterString() {
        let input = "if x = \"\"{}"
        let output = "if x = \"\" {}"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundBraces)
    }

    // MARK: - spaceInsideBraces

    func testSpaceInsideBraces() {
        let input = "foo({bar})"
        let output = "foo({ bar })"
        testFormatting(for: input, output, rule: FormatRules.spaceInsideBraces, exclude: ["trailingClosures"])
    }

    func testNoExtraSpaceInsidebraces() {
        let input = "{ foo }"
        testFormatting(for: input, rule: FormatRules.spaceInsideBraces, exclude: ["trailingClosures"])
    }

    func testNoSpaceInsideEmptybraces() {
        let input = "foo({ })"
        let output = "foo({})"
        testFormatting(for: input, output, rule: FormatRules.spaceInsideBraces, exclude: ["trailingClosures"])
    }

    // MARK: - spaceAroundGenerics

    func testSpaceAroundGenerics() {
        let input = "Foo <Bar <Baz>>"
        let output = "Foo<Bar<Baz>>"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundGenerics)
    }

    // MARK: - spaceInsideGenerics

    func testSpaceInsideGenerics() {
        let input = "Foo< Bar< Baz > >"
        let output = "Foo<Bar<Baz>>"
        testFormatting(for: input, output, rule: FormatRules.spaceInsideGenerics)
    }

    // MARK: - spaceAroundOperators

    func testSpaceAfterColon() {
        let input = "let foo:Bar = 5"
        let output = "let foo: Bar = 5"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceBetweenOptionalAndDefaultValue() {
        let input = "let foo: String?=nil"
        let output = "let foo: String? = nil"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceBetweenImplictlyUnwrappedOptionalAndDefaultValue() {
        let input = "let foo: String!=nil"
        let output = "let foo: String! = nil"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testSpacePreservedBetweenOptionalTryAndDot() {
        let input = "let foo: Int = try? .init()"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testSpacePreservedBetweenForceTryAndDot() {
        let input = "let foo: Int = try! .init()"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceBetweenOptionalAndDefaultValueInFunction() {
        let input = "func foo(bar _: String?=nil) {}"
        let output = "func foo(bar _: String? = nil) {}"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testNoSpaceAddedAfterColonInSelector() {
        let input = "@objc(foo:bar:)"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceAfterColonInSwitchCase() {
        let input = "switch x { case .y:break }"
        let output = "switch x { case .y: break }"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceAfterColonInSwitchDefault() {
        let input = "switch x { default:break }"
        let output = "switch x { default: break }"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceAfterComma() {
        let input = "let foo = [1,2,3]"
        let output = "let foo = [1, 2, 3]"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceBetweenColonAndEnumValue() {
        let input = "[.Foo:.Bar]"
        let output = "[.Foo: .Bar]"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceBetweenCommaAndEnumValue() {
        let input = "[.Foo,.Bar]"
        let output = "[.Foo, .Bar]"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceBetweenSemicolonAndEnumValue() {
        let input = "statement;.Bar"
        let output = "statement; .Bar"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testSpacePreservedBetweenEqualsAndEnumValue() {
        let input = "foo = .Bar"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testNoSpaceBeforeColon() {
        let input = "let foo : Bar = 5"
        let output = "let foo: Bar = 5"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testSpacePreservedBeforeColonInTernary() {
        let input = "foo ? bar : baz"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testSpacePreservedAroundEnumValuesInTernary() {
        let input = "foo ? .Bar : .Baz"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceBeforeColonInNestedTernary() {
        let input = "foo ? (hello + a ? b: c) : baz"
        let output = "foo ? (hello + a ? b : c) : baz"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testNoSpaceBeforeComma() {
        let input = "let foo = [1 , 2 , 3]"
        let output = "let foo = [1, 2, 3]"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceAtStartOfLine() {
        let input = "foo\n    ,bar"
        let output = "foo\n    , bar"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators,
                       exclude: ["leadingDelimiters"])
    }

    func testSpaceAroundInfixMinus() {
        let input = "foo-bar"
        let output = "foo - bar"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testNoSpaceAroundPrefixMinus() {
        let input = "foo + -bar"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceAroundLessThan() {
        let input = "foo<bar"
        let output = "foo < bar"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testRemoveSpaceAroundDot() {
        let input = "foo . bar"
        let output = "foo.bar"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testNoSpaceAroundDotOnNewLine() {
        let input = "foo\n    .bar"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceAroundEnumCase() {
        let input = "case .Foo,.Bar:"
        let output = "case .Foo, .Bar:"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testSwitchWithEnumCases() {
        let input = "switch x {\ncase.Foo:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\ncase .Foo:\n    break\ndefault:\n    break\n}"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceAroundEnumReturn() {
        let input = "return.Foo"
        let output = "return .Foo"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testNoSpaceAfterReturnAsIdentifier() {
        let input = "foo.return.Bar"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceAroundCaseLet() {
        let input = "case let.Foo(bar):"
        let output = "case let .Foo(bar):"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceAroundEnumArgument() {
        let input = "foo(with:.Bar)"
        let output = "foo(with: .Bar)"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceBeforeEnumCaseInsideClosure() {
        let input = "{ .bar() }"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testNoSpaceAroundMultipleOptionalChaining() {
        let input = "foo??!?!.bar"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testNoSpaceAroundForcedChaining() {
        let input = "foo!.bar"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testNoSpaceAddedInOptionalChaining() {
        let input = "foo?.bar"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceRemovedInOptionalChaining() {
        let input = "foo? .bar"
        let output = "foo?.bar"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceRemovedInForcedChaining() {
        let input = "foo! .bar"
        let output = "foo!.bar"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceRemovedInMultipleOptionalChaining() {
        let input = "foo??! .bar"
        let output = "foo??!.bar"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testNoSpaceAfterOptionalInsideTernary() {
        let input = "x ? foo? .bar() : bar?.baz()"
        let output = "x ? foo?.bar() : bar?.baz()"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testSplitLineOptionalChaining() {
        let input = "foo?\n    .bar"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testSplitLineMultipleOptionalChaining() {
        let input = "foo??!\n    .bar"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceBetweenNullCoalescingAndDot() {
        let input = "foo ?? .bar()"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testNoSpaceAroundFailableInit() {
        let input = "init?()"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testNoSpaceAroundImplictlyUnwrappedFailableInit() {
        let input = "init!()"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testNoSpaceAroundFailableInitWithGenerics() {
        let input = "init?<T>()"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testNoSpaceAroundImplictlyUnwrappedFailableInitWithGenerics() {
        let input = "init!<T>()"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceAfterOptionalAs() {
        let input = "foo as?[String]"
        let output = "foo as? [String]"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceAfterForcedAs() {
        let input = "foo as![String]"
        let output = "foo as! [String]"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testNoSpaceAroundGenerics() {
        let input = "Foo<String>"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceAroundReturnTypeArrow() {
        let input = "foo() ->Bool"
        let output = "foo() -> Bool"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceAroundCommentInInfixExpression() {
        let input = "foo/* hello */-bar"
        let output = "foo/* hello */ -bar"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators,
                       exclude: ["spaceAroundComments"])
    }

    func testSpaceAroundCommentsInInfixExpression() {
        let input = "a/* */+/* */b"
        let output = "a/* */ + /* */b"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators,
                       exclude: ["spaceAroundComments"])
    }

    func testSpaceAroundCommentInPrefixExpression() {
        let input = "a + /* hello */ -bar"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testPrefixMinusBeforeMember() {
        let input = "-.foo"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testPostfixMinusBeforeMember() {
        let input = "foo-.bar"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testRemoveSpaceBeforeNegativeIndex() {
        let input = "foo[ -bar]"
        let output = "foo[-bar]"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testNoInsertSpaceBeforeUnlabelledAddressArgument() {
        let input = "foo(&bar)"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testRemoveSpaceBeforeUnlabelledAddressArgument() {
        let input = "foo( &bar, baz: &baz)"
        let output = "foo(&bar, baz: &baz)"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testRemoveSpaceBeforeKeyPath() {
        let input = "foo( \\.bar)"
        let output = "foo(\\.bar)"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testAddSpaceAfterFuncEquals() {
        let input = "func ==(lhs: Int, rhs: Int) -> Bool { return lhs === rhs }"
        let output = "func == (lhs: Int, rhs: Int) -> Bool { return lhs === rhs }"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testRemoveSpaceAfterFuncEquals() {
        let input = "func == (lhs: Int, rhs: Int) -> Bool { return lhs === rhs }"
        let output = "func ==(lhs: Int, rhs: Int) -> Bool { return lhs === rhs }"
        let options = FormatOptions(spaceAroundOperatorDeclarations: false)
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators, options: options)
    }

    func testAddSpaceAfterOperatorEquals() {
        let input = "operator =={}"
        let output = "operator == {}"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testNoRemoveSpaceAfterOperatorEqualsWhenSpaceAroundOperatorDeclarationsFalse() {
        let input = "operator == {}"
        let options = FormatOptions(spaceAroundOperatorDeclarations: false)
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators, options: options)
    }

    func testNoAddSpaceAfterOperatorEqualsWithAllmanBrace() {
        let input = "operator ==\n{}"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testNoAddSpaceAroundOperatorInsideParens() {
        let input = "(!=)"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators, exclude: ["redundantParens"])
    }

    func testSpaceAroundPlusBeforeHash() {
        let input = "\"foo.\"+#file"
        let output = "\"foo.\" + #file"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceNotAddedAroundStarInAvailableAnnotation() {
        let input = "@available(*, deprecated, message: \"foo\")"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
    }

    func testAddSpaceAroundRange() {
        let input = "let a = b...c"
        let output = "let a = b ... c"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testSpaceRemovedInNestedPropertyWrapper() {
        let input = "@Encoded .Foo var foo: String"
        let output = "@Encoded.Foo var foo: String"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    // noSpaceOperators

    func testNoAddSpaceAroundNoSpaceStar() {
        let input = "let a = b*c+d"
        let output = "let a = b*c + d"
        let options = FormatOptions(noSpaceOperators: ["*"])
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators, options: options)
    }

    func testRemoveSpaceAroundNoSpaceStar() {
        let input = "let a = b * c + d"
        let output = "let a = b*c + d"
        let options = FormatOptions(noSpaceOperators: ["*"])
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators, options: options)
    }

    func testNoRemoveSpaceAroundNoSpaceStarBeforePrefixOperator() {
        let input = "let a = b * -c"
        let options = FormatOptions(noSpaceOperators: ["*"])
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators, options: options)
    }

    func testNoRemoveSpaceAroundNoSpaceStarAfterPostfixOperator() {
        let input = "let a = b% * c"
        let options = FormatOptions(noSpaceOperators: ["*"])
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators, options: options)
    }

    func testRemoveSpaceAroundNoSpaceStarAfterUnwrapOperator() {
        let input = "let a = b! * c"
        let output = "let a = b!*c"
        let options = FormatOptions(noSpaceOperators: ["*"])
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators, options: options)
    }

    func testNoAddSpaceAroundNoSpaceRange() {
        let input = "let a = b...c"
        let options = FormatOptions(noSpaceOperators: ["..."])
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators, options: options)
    }

    func testNoAddSpaceAroundNoSpaceHalfOpenRange() {
        let input = "let a = b..<c"
        let options = FormatOptions(noSpaceOperators: ["..<"])
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators, options: options)
    }

    func testRemoveSpaceAroundNoSpaceRange() {
        let input = "let a = b ... c"
        let output = "let a = b...c"
        let options = FormatOptions(noSpaceOperators: ["..."])
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators, options: options)
    }

    func testNoRemoveSpaceAroundNoSpaceRangeBeforePrefixOperator() {
        let input = "let a = b ... -c"
        let options = FormatOptions(noSpaceOperators: ["..."])
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators, options: options)
    }

    func testNoRemoveSpaceAroundTernaryColon() {
        let input = "let a = b ? c : d"
        let output = "let a = b ? c:d"
        let options = FormatOptions(noSpaceOperators: [":"])
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators, options: options)
    }

    func testNoRemoveSpaceAroundTernaryQuestionMark() {
        let input = "let a = b ? c : d"
        let options = FormatOptions(noSpaceOperators: ["?"])
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators, options: options)
    }

    func testSpaceOnOneSideOfPlusMatchedByLinebreakNotRemoved() {
        let input = "let range = 0 +\n4"
        let options = FormatOptions(noSpaceOperators: ["+"])
        testFormatting(for: input, rule: FormatRules.ranges, options: options, exclude: ["indent"])
    }

    func testSpaceOnOneSideOfPlusMatchedByLinebreakNotRemoved2() {
        let input = "let range = 0\n+ 4"
        let options = FormatOptions(noSpaceOperators: ["+"])
        testFormatting(for: input, rule: FormatRules.ranges, options: options, exclude: ["indent"])
    }

    func testSpaceAroundPlusWithLinebreakOnOneSideNotRemoved() {
        let input = "let range = 0 + \n4"
        let options = FormatOptions(noSpaceOperators: ["+"])
        testFormatting(for: input, rule: FormatRules.ranges, options: options,
                       exclude: ["indent", "trailingSpace"])
    }

    func testSpaceAroundPlusWithLinebreakOnOneSideNotRemoved2() {
        let input = "let range = 0\n + 4"
        let options = FormatOptions(noSpaceOperators: ["+"])
        testFormatting(for: input, rule: FormatRules.ranges, options: options, exclude: ["indent"])
    }

    // MARK: - spaceAroundComments

    func testSpaceAroundCommentInParens() {
        let input = "(/* foo */)"
        let output = "( /* foo */ )"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundComments,
                       exclude: ["redundantParens"])
    }

    func testNoSpaceAroundCommentAtStartAndEndOfFile() {
        let input = "/* foo */"
        testFormatting(for: input, rule: FormatRules.spaceAroundComments)
    }

    func testNoSpaceAroundCommentBeforeComma() {
        let input = "(foo /* foo */ , bar)"
        let output = "(foo /* foo */, bar)"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundComments)
    }

    func testSpaceAroundSingleLineComment() {
        let input = "func foo() {// comment\n}"
        let output = "func foo() { // comment\n}"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundComments)
    }

    // MARK: - spaceInsideComments

    func testSpaceInsideMultilineComment() {
        let input = "/*foo\n bar*/"
        let output = "/* foo\n bar */"
        testFormatting(for: input, output, rule: FormatRules.spaceInsideComments)
    }

    func testSpaceInsideSingleLineMultilineComment() {
        let input = "/*foo*/"
        let output = "/* foo */"
        testFormatting(for: input, output, rule: FormatRules.spaceInsideComments)
    }

    func testNoSpaceInsideEmptyMultilineComment() {
        let input = "/**/"
        testFormatting(for: input, rule: FormatRules.spaceInsideComments)
    }

    func testSpaceInsideSingleLineComment() {
        let input = "//foo"
        let output = "// foo"
        testFormatting(for: input, output, rule: FormatRules.spaceInsideComments)
    }

    func testSpaceInsideMultilineHeaderdocComment() {
        let input = "/**foo\n bar*/"
        let output = "/** foo\n bar */"
        testFormatting(for: input, output, rule: FormatRules.spaceInsideComments)
    }

    func testSpaceInsideMultilineHeaderdocCommentType2() {
        let input = "/*!foo\n bar*/"
        let output = "/*! foo\n bar */"
        testFormatting(for: input, output, rule: FormatRules.spaceInsideComments)
    }

    func testSpaceInsideMultilineSwiftPlaygroundDocComment() {
        let input = "/*:foo\n bar*/"
        let output = "/*: foo\n bar */"
        testFormatting(for: input, output, rule: FormatRules.spaceInsideComments)
    }

    func testNoExtraSpaceInsideMultilineHeaderdocComment() {
        let input = "/** foo\n bar */"
        testFormatting(for: input, rule: FormatRules.spaceInsideComments)
    }

    func testNoExtraSpaceInsideMultilineHeaderdocCommentType2() {
        let input = "/*! foo\n bar */"
        testFormatting(for: input, rule: FormatRules.spaceInsideComments)
    }

    func testNoExtraSpaceInsideMultilineSwiftPlaygroundDocComment() {
        let input = "/*: foo\n bar */"
        testFormatting(for: input, rule: FormatRules.spaceInsideComments)
    }

    func testSpaceInsideSingleLineHeaderdocComment() {
        let input = "///foo"
        let output = "/// foo"
        testFormatting(for: input, output, rule: FormatRules.spaceInsideComments)
    }

    func testSpaceInsideSingleLineHeaderdocCommentType2() {
        let input = "//!foo"
        let output = "//! foo"
        testFormatting(for: input, output, rule: FormatRules.spaceInsideComments)
    }

    func testSpaceInsideSingleLineSwiftPlaygroundDocComment() {
        let input = "//:foo"
        let output = "//: foo"
        testFormatting(for: input, output, rule: FormatRules.spaceInsideComments)
    }

    func testPreformattedMultilineComment() {
        let input = "/*********************\n *****Hello World*****\n *********************/"
        testFormatting(for: input, rule: FormatRules.spaceInsideComments)
    }

    func testPreformattedSingleLineComment() {
        let input = "/////////ATTENTION////////"
        testFormatting(for: input, rule: FormatRules.spaceInsideComments)
    }

    func testNoSpaceAddedToFirstLineOfDocComment() {
        let input = "/**\n Comment\n */"
        testFormatting(for: input, rule: FormatRules.spaceInsideComments)
    }

    func testNoSpaceAddedToEmptyDocComment() {
        let input = "///"
        testFormatting(for: input, rule: FormatRules.spaceInsideComments)
    }

    // MARK: - consecutiveSpaces

    func testConsecutiveSpaces() {
        let input = "let foo  = bar"
        let output = "let foo = bar"
        testFormatting(for: input, output, rule: FormatRules.consecutiveSpaces)
    }

    func testConsecutiveSpacesAfterComment() {
        let input = "// comment\nfoo  bar"
        let output = "// comment\nfoo bar"
        testFormatting(for: input, output, rule: FormatRules.consecutiveSpaces)
    }

    func testConsecutiveSpacesDoesntStripIndent() {
        let input = "{\n    let foo  = bar\n}"
        let output = "{\n    let foo = bar\n}"
        testFormatting(for: input, output, rule: FormatRules.consecutiveSpaces)
    }

    func testConsecutiveSpacesDoesntAffectMultilineComments() {
        let input = "/*    comment  */"
        testFormatting(for: input, rule: FormatRules.consecutiveSpaces)
    }

    func testConsecutiveSpacesRemovedBetweenComments() {
        let input = "/* foo */  /* bar */"
        let output = "/* foo */ /* bar */"
        testFormatting(for: input, output, rule: FormatRules.consecutiveSpaces)
    }

    func testConsecutiveSpacesDoesntAffectNestedMultilineComments() {
        let input = "/*  foo  /*  bar  */  baz  */"
        testFormatting(for: input, rule: FormatRules.consecutiveSpaces)
    }

    func testConsecutiveSpacesDoesntAffectNestedMultilineComments2() {
        let input = "/*  /*  foo  */  /*  bar  */  */"
        testFormatting(for: input, rule: FormatRules.consecutiveSpaces)
    }

    func testConsecutiveSpacesDoesntAffectSingleLineComments() {
        let input = "//    foo  bar"
        testFormatting(for: input, rule: FormatRules.consecutiveSpaces)
    }

    // MARK: - trailingSpace

    // truncateBlankLines = true

    func testTrailingSpace() {
        let input = "foo  \nbar"
        let output = "foo\nbar"
        testFormatting(for: input, output, rule: FormatRules.trailingSpace)
    }

    func testTrailingSpaceAtEndOfFile() {
        let input = "foo  "
        let output = "foo"
        testFormatting(for: input, output, rule: FormatRules.trailingSpace)
    }

    func testTrailingSpaceInMultilineComments() {
        let input = "/* foo  \n bar  */"
        let output = "/* foo\n bar  */"
        testFormatting(for: input, output, rule: FormatRules.trailingSpace)
    }

    func testTrailingSpaceInSingleLineComments() {
        let input = "// foo  \n// bar  "
        let output = "// foo\n// bar"
        testFormatting(for: input, output, rule: FormatRules.trailingSpace)
    }

    func testTruncateBlankLine() {
        let input = "foo {\n    // bar\n    \n    // baz\n}"
        let output = "foo {\n    // bar\n\n    // baz\n}"
        testFormatting(for: input, output, rule: FormatRules.trailingSpace)
    }

    func testTrailingSpaceInArray() {
        let input = "let foo = [\n    1,\n    \n    2,\n]"
        let output = "let foo = [\n    1,\n\n    2,\n]"
        testFormatting(for: input, output, rule: FormatRules.trailingSpace, exclude: ["redundantSelf"])
    }

    // truncateBlankLines = false

    func testNoTruncateBlankLine() {
        let input = "foo {\n    // bar\n    \n    // baz\n}"
        let options = FormatOptions(truncateBlankLines: false)
        testFormatting(for: input, rule: FormatRules.trailingSpace, options: options)
    }

    // MARK: - consecutiveBlankLines

    func testConsecutiveBlankLines() {
        let input = "foo\n\n    \nbar"
        let output = "foo\n\nbar"
        testFormatting(for: input, output, rule: FormatRules.consecutiveBlankLines)
    }

    func testConsecutiveBlankLinesAtEndOfFile() {
        let input = "foo\n\n"
        let output = "foo\n"
        testFormatting(for: input, output, rule: FormatRules.consecutiveBlankLines)
    }

    func testConsecutiveBlankLinesAtStartOfFile() {
        let input = "\n\n\nfoo"
        let output = "\n\nfoo"
        testFormatting(for: input, output, rule: FormatRules.consecutiveBlankLines)
    }

    func testConsecutiveBlankLinesInsideStringLiteral() {
        let input = "\"\"\"\nhello\n\n\nworld\n\"\"\""
        testFormatting(for: input, rule: FormatRules.consecutiveBlankLines)
    }

    func testConsecutiveBlankLinesAtStartOfStringLiteral() {
        let input = "\"\"\"\n\n\nhello world\n\"\"\""
        testFormatting(for: input, rule: FormatRules.consecutiveBlankLines)
    }

    func testConsecutiveBlankLinesAfterStringLiteral() {
        let input = "\"\"\"\nhello world\n\"\"\"\n\n\nfoo()"
        let output = "\"\"\"\nhello world\n\"\"\"\n\nfoo()"
        testFormatting(for: input, output, rule: FormatRules.consecutiveBlankLines)
    }

    func testFragmentWithTrailingLinebreaks() {
        let input = "func foo() {}\n\n\n"
        let output = "func foo() {}\n\n"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: FormatRules.consecutiveBlankLines, options: options)
    }

    func testLintingConsecutiveBlankLinesReportsCorrectLine() {
        let input = "foo\n   \n\nbar"
        XCTAssertEqual(try lint(input, rules: [FormatRules.consecutiveBlankLines]), [
            .init(line: 3, rule: FormatRules.consecutiveBlankLines, filePath: nil),
        ])
    }

    // MARK: - blankLinesAtStartOfScope

    func testBlankLinesRemovedAtStartOfFunction() {
        let input = "func foo() {\n\n    // code\n}"
        let output = "func foo() {\n    // code\n}"
        testFormatting(for: input, output, rule: FormatRules.blankLinesAtStartOfScope)
    }

    func testBlankLinesRemovedAtStartOfParens() {
        let input = "(\n\n    foo: Int\n)"
        let output = "(\n    foo: Int\n)"
        testFormatting(for: input, output, rule: FormatRules.blankLinesAtStartOfScope)
    }

    func testBlankLinesRemovedAtStartOfBrackets() {
        let input = "[\n\n    foo,\n    bar,\n]"
        let output = "[\n    foo,\n    bar,\n]"
        testFormatting(for: input, output, rule: FormatRules.blankLinesAtStartOfScope)
    }

    func testBlankLinesNotRemovedBetweenElementsInsideBrackets() {
        let input = "[foo,\n\n bar]"
        testFormatting(for: input, rule: FormatRules.blankLinesAtStartOfScope, exclude: ["wrapArguments"])
    }

    // MARK: - blankLinesAtEndOfScope

    func testBlankLinesRemovedAtEndOfFunction() {
        let input = "func foo() {\n    // code\n\n}"
        let output = "func foo() {\n    // code\n}"
        testFormatting(for: input, output, rule: FormatRules.blankLinesAtEndOfScope)
    }

    func testBlankLinesRemovedAtEndOfParens() {
        let input = "(\n    foo: Int\n\n)"
        let output = "(\n    foo: Int\n)"
        testFormatting(for: input, output, rule: FormatRules.blankLinesAtEndOfScope)
    }

    func testBlankLinesRemovedAtEndOfBrackets() {
        let input = "[\n    foo,\n    bar,\n\n]"
        let output = "[\n    foo,\n    bar,\n]"
        testFormatting(for: input, output, rule: FormatRules.blankLinesAtEndOfScope)
    }

    func testBlankLineNotRemovedBeforeElse() {
        let input = "if x {\n\n    // do something\n\n} else if y {\n\n    // do something else\n\n}"
        let output = "if x {\n\n    // do something\n\n} else if y {\n\n    // do something else\n}"
        testFormatting(for: input, output, rule: FormatRules.blankLinesAtEndOfScope,
                       exclude: ["blankLinesAtStartOfScope"])
    }

    // MARK: - blankLinesBetweenScopes

    func testBlankLineBetweenFunctions() {
        let input = "func foo() {\n}\nfunc bar() {\n}"
        let output = "func foo() {\n}\n\nfunc bar() {\n}"
        testFormatting(for: input, output, rule: FormatRules.blankLinesBetweenScopes,
                       exclude: ["emptyBraces"])
    }

    func testNoBlankLineBetweenPropertyAndFunction() {
        let input = "var foo: Int\nfunc bar() {\n}"
        testFormatting(for: input, rule: FormatRules.blankLinesBetweenScopes, exclude: ["emptyBraces"])
    }

    func testBlankLineBetweenFunctionsIsBeforeComment() {
        let input = "func foo() {\n}\n// headerdoc\nfunc bar() {\n}"
        let output = "func foo() {\n}\n\n// headerdoc\nfunc bar() {\n}"
        testFormatting(for: input, output, rule: FormatRules.blankLinesBetweenScopes,
                       exclude: ["emptyBraces"])
    }

    func testBlankLineBeforeAtObjcOnLineBeforeProtocol() {
        let input = "@objc\nprotocol Foo {\n}\n@objc\nprotocol Bar {\n}"
        let output = "@objc\nprotocol Foo {\n}\n\n@objc\nprotocol Bar {\n}"
        testFormatting(for: input, output, rule: FormatRules.blankLinesBetweenScopes,
                       exclude: ["emptyBraces"])
    }

    func testBlankLineBeforeAtAvailabilityOnLineBeforeClass() {
        let input = "protocol Foo {\n}\n@available(iOS 8.0, OSX 10.10, *)\nclass Bar {\n}"
        let output = "protocol Foo {\n}\n\n@available(iOS 8.0, OSX 10.10, *)\nclass Bar {\n}"
        testFormatting(for: input, output, rule: FormatRules.blankLinesBetweenScopes,
                       exclude: ["emptyBraces"])
    }

    func testNoExtraBlankLineBetweenFunctions() {
        let input = "func foo() {\n}\n\nfunc bar() {\n}"
        testFormatting(for: input, rule: FormatRules.blankLinesBetweenScopes, exclude: ["emptyBraces"])
    }

    func testNoBlankLineBetweenFunctionsInProtocol() {
        let input = "protocol Foo {\n    func bar() -> Void\n    func baz() -> Int\n}"
        testFormatting(for: input, rule: FormatRules.blankLinesBetweenScopes)
    }

    func testNoBlankLineInsideInitFunction() {
        let input = "init() {\n    super.init()\n}"
        testFormatting(for: input, rule: FormatRules.blankLinesBetweenScopes)
    }

    func testBlankLineAfterProtocolBeforeProperty() {
        let input = "protocol Foo {\n}\nvar bar: String"
        let output = "protocol Foo {\n}\n\nvar bar: String"
        testFormatting(for: input, output, rule: FormatRules.blankLinesBetweenScopes,
                       exclude: ["emptyBraces"])
    }

    func testNoExtraBlankLineAfterSingleLineComment() {
        let input = "var foo: Bar? // comment\n\nfunc bar() {}"
        testFormatting(for: input, rule: FormatRules.blankLinesBetweenScopes)
    }

    func testNoExtraBlankLineAfterMultilineComment() {
        let input = "var foo: Bar? /* comment */\n\nfunc bar() {}"
        testFormatting(for: input, rule: FormatRules.blankLinesBetweenScopes)
    }

    func testNoBlankLineBeforeFuncAsIdentifier() {
        let input = "var foo: Bar?\nfoo.func(x) {}"
        testFormatting(for: input, rule: FormatRules.blankLinesBetweenScopes)
    }

    func testNoBlankLineBetweenFunctionsWithInlineBody() {
        let input = "class Foo {\n    func foo() { print(\"foo\") }\n    func bar() { print(\"bar\") }\n}"
        testFormatting(for: input, rule: FormatRules.blankLinesBetweenScopes)
    }

    func testNoBlankLineBetweenIfStatements() {
        let input = "func foo() {\n    if x {\n    }\n    if y {\n    }\n}"
        testFormatting(for: input, rule: FormatRules.blankLinesBetweenScopes, exclude: ["emptyBraces"])
    }

    func testNoBlanksInsideClassFunc() {
        let input = "class func foo {\n    if x {\n    }\n    if y {\n    }\n}"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: FormatRules.blankLinesBetweenScopes, options: options,
                       exclude: ["emptyBraces"])
    }

    func testNoBlanksInsideClassVar() {
        let input = "class var foo: Int {\n    if x {\n    }\n    if y {\n    }\n}"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: FormatRules.blankLinesBetweenScopes, options: options,
                       exclude: ["emptyBraces"])
    }

    func testBlankLineBetweenCalledClosures() {
        let input = "class Foo {\n    var foo = {\n    }()\n    func bar {\n    }\n}"
        let output = "class Foo {\n    var foo = {\n    }()\n\n    func bar {\n    }\n}"
        testFormatting(for: input, output, rule: FormatRules.blankLinesBetweenScopes,
                       exclude: ["emptyBraces"])
    }

    func testNoBlankLineAfterCalledClosureAtEndOfScope() {
        let input = "class Foo {\n    var foo = {\n    }()\n}"
        testFormatting(for: input, rule: FormatRules.blankLinesBetweenScopes, exclude: ["emptyBraces"])
    }

    func testNoBlankLineBeforeWhileInRepeatWhile() {
        let input = "repeat\n{}\nwhile true\n{}()"
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, rule: FormatRules.blankLinesBetweenScopes, options: options)
    }

    func testBlankLineBeforeWhileIfNotRepeatWhile() {
        let input = "func foo(x)\n{\n}\nwhile true\n{\n}"
        let output = "func foo(x)\n{\n}\n\nwhile true\n{\n}"
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: FormatRules.blankLinesBetweenScopes, options: options,
                       exclude: ["emptyBraces"])
    }

    func testNoInsertBlankLinesInConditionalCompilation() {
        let input = """
        struct Foo {
            #if BAR
                func something() {
                }
            #else
                func something() {
                }
            #endif
        }
        """
        testFormatting(for: input, rule: FormatRules.blankLinesBetweenScopes,
                       exclude: ["emptyBraces"])
    }

    // MARK: - blankLinesAroundMark

    func testInsertBlankLinesAroundMark() {
        let input = """
        let foo = "foo"
        // MARK: bar
        let bar = "bar"
        """
        let output = """
        let foo = "foo"

        // MARK: bar

        let bar = "bar"
        """
        testFormatting(for: input, output, rule: FormatRules.blankLinesAroundMark)
    }

    func testNoInsertExtraBlankLinesAroundMark() {
        let input = """
        let foo = "foo"

        // MARK: bar

        let bar = "bar"
        """
        testFormatting(for: input, rule: FormatRules.blankLinesAroundMark)
    }

    func testInsertBlankLineAfterMarkAtStartOfFile() {
        let input = """
        // MARK: bar
        let bar = "bar"
        """
        let output = """
        // MARK: bar

        let bar = "bar"
        """
        testFormatting(for: input, output, rule: FormatRules.blankLinesAroundMark)
    }

    func testInsertBlankLineBeforeMarkAtEndOfFile() {
        let input = """
        let foo = "foo"
        // MARK: bar
        """
        let output = """
        let foo = "foo"

        // MARK: bar
        """
        testFormatting(for: input, output, rule: FormatRules.blankLinesAroundMark)
    }

    func testNoInsertBlankLineBeforeMarkAtStartOfScope() {
        let input = """
        do {
            // MARK: foo

            let foo = "foo"
        }
        """
        testFormatting(for: input, rule: FormatRules.blankLinesAroundMark)
    }

    func testNoInsertBlankLineAfterMarkAtEndOfScope() {
        let input = """
        do {
            let foo = "foo"

            // MARK: foo
        }
        """
        testFormatting(for: input, rule: FormatRules.blankLinesAroundMark)
    }

    // MARK: - linebreakAtEndOfFile

    func testLinebreakAtEndOfFile() {
        let input = "foo\nbar"
        let output = "foo\nbar\n"
        testFormatting(for: input, output, rule: FormatRules.linebreakAtEndOfFile)
    }

    func testNoLinebreakAtEndOfFragment() {
        let input = "foo\nbar"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: FormatRules.linebreakAtEndOfFile, options: options)
    }

    // MARK: - indent

    func testReduceIndentAtStartOfFile() {
        let input = "    foo()"
        let output = "foo()"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testReduceIndentAtEndOfFile() {
        let input = "foo()\n   bar()"
        let output = "foo()\nbar()"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    // indent parens

    func testSimpleScope() {
        let input = "foo(\nbar\n)"
        let output = "foo(\n    bar\n)"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testNestedScope() {
        let input = "foo(\nbar {\n}\n)"
        let output = "foo(\n    bar {\n    }\n)"
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["emptyBraces"])
    }

    func testNestedScopeOnSameLine() {
        let input = "foo(bar(\nbaz\n))"
        let output = "foo(bar(\n    baz\n))"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testNestedScopeOnSameLine2() {
        let input = "foo(bar(in:\nbaz))"
        let output = "foo(bar(in:\n    baz))"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentNestedArrayLiteral() {
        let input = "foo(bar: [\n.baz,\n])"
        let output = "foo(bar: [\n    .baz,\n])"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testClosingScopeAfterContent() {
        let input = "foo(\nbar\n)"
        let output = "foo(\n    bar\n)"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testClosingNestedScopeAfterContent() {
        let input = "foo(bar(\nbaz\n))"
        let output = "foo(bar(\n    baz\n))"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedFunctionArguments() {
        let input = "foo(\nbar,\nbaz\n)"
        let output = "foo(\n    bar,\n    baz\n)"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testFunctionArgumentsWrappedAfterFirst() {
        let input = "func foo(bar: Int,\nbaz: Int)"
        let output = "func foo(bar: Int,\n         baz: Int)"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentImbalancedNestedClosingParens() {
        let input = """
        Foo(bar:
            Bar(
                baz: quux
            ))
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    // indent specifiers

    func testNoIndentWrappedSpecifiersForProtocol() {
        let input = "@objc\nprivate\nprotocol Foo {}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    // indent braces

    func testElseClauseIndenting() {
        let input = "if x {\nbar\n} else {\nbaz\n}"
        let output = "if x {\n    bar\n} else {\n    baz\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testNoIndentBlankLines() {
        let input = "{\n\n// foo\n}"
        let output = "{\n\n    // foo\n}"
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["blankLinesAtStartOfScope"])
    }

    func testNestedBraces() {
        let input = "({\n// foo\n}, {\n// bar\n})"
        let output = "({\n    // foo\n}, {\n    // bar\n})"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testBraceIndentAfterComment() {
        let input = "if foo { // comment\nbar\n}"
        let output = "if foo { // comment\n    bar\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testBraceIndentAfterClosingScope() {
        let input = "foo(bar(baz), {\nquux\nbleem\n})"
        let output = "foo(bar(baz), {\n    quux\n    bleem\n})"
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["trailingClosures"])
    }

    func testBraceIndentAfterLineWithParens() {
        let input = "({\nfoo()\nbar\n})"
        let output = "({\n    foo()\n    bar\n})"
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["redundantParens"])
    }

    // indent switch/case

    func testSwitchCaseIndenting() {
        let input = "switch x {\ncase foo:\nbreak\ncase bar:\nbreak\ndefault:\nbreak\n}"
        let output = "switch x {\ncase foo:\n    break\ncase bar:\n    break\ndefault:\n    break\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testSwitchWrappedCaseIndenting() {
        let input = "switch x {\ncase foo,\nbar,\n    baz:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\ncase foo,\n     bar,\n     baz:\n    break\ndefault:\n    break\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testSwitchWrappedEnumCaseIndenting() {
        let input = "switch x {\ncase .foo,\n.bar,\n    .baz:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\ncase .foo,\n     .bar,\n     .baz:\n    break\ndefault:\n    break\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testSwitchWrappedEnumCaseIndentingVariant2() {
        let input = "switch x {\ncase\n.foo,\n.bar,\n    .baz:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\ncase\n    .foo,\n    .bar,\n    .baz:\n    break\ndefault:\n    break\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testSwitchWrappedEnumCaseIsIndenting() {
        let input = "switch x {\ncase is Foo.Type,\n    is Bar.Type:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\ncase is Foo.Type,\n     is Bar.Type:\n    break\ndefault:\n    break\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testSwitchCaseIsDictionaryIndenting() {
        let input = "switch x {\ncase foo is [Key: Value]:\nfallthrough\ndefault:\nbreak\n}"
        let output = "switch x {\ncase foo is [Key: Value]:\n    fallthrough\ndefault:\n    break\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testEnumCaseIndenting() {
        let input = "enum Foo {\ncase Bar\ncase Baz\n}"
        let output = "enum Foo {\n    case Bar\n    case Baz\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testEnumCaseIndentingCommas() {
        let input = "enum Foo {\ncase Bar,\nBaz\n}"
        let output = "enum Foo {\n    case Bar,\n        Baz\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testEnumCaseIndentingCommasWithXcodeStyle() {
        let input = "enum Foo {\ncase Bar,\nBaz\n}"
        let output = "enum Foo {\n    case Bar,\n    Baz\n}"
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testEnumCaseWrappedIfWithXcodeStyle() {
        let input = "if case .foo = foo,\ntrue {\nreturn false\n}"
        let output = "if case .foo = foo,\n    true {\n    return false\n}"
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testGenericEnumCaseIndenting() {
        let input = "enum Foo<T> {\ncase Bar\ncase Baz\n}"
        let output = "enum Foo<T> {\n    case Bar\n    case Baz\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentSwitchAfterRangeCase() {
        let input = "switch x {\ncase 0 ..< 2:\n    switch y {\n    default:\n        break\n    }\ndefault:\n    break\n}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentEnumDeclarationInsideSwitchCase() {
        let input = "switch x {\ncase y:\nenum Foo {\ncase z\n}\nbar()\ndefault: break\n}"
        let output = "switch x {\ncase y:\n    enum Foo {\n        case z\n    }\n    bar()\ndefault: break\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentEnumCaseBodyAfterWhereClause() {
        let input = "switch foo {\ncase _ where baz < quux:\n    print(1)\n    print(2)\ndefault:\n    break\n}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentSwitchCaseCommentsCorrectly() {
        let input = """
        switch x {
        // comment
        case y:
        // comment
        break
        // comment
        case z:
        break
        }
        """
        let output = """
        switch x {
        // comment
        case y:
            // comment
            break
        // comment
        case z:
            break
        }
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentMultilineSwitchCaseCommentsCorrectly() {
        let input = "switch x {\n/*\n * comment\n */\ncase y:\nbreak\n/*\n * comment\n */\ndefault:\nbreak\n}"
        let output = "switch x {\n/*\n * comment\n */\ncase y:\n    break\n/*\n * comment\n */\ndefault:\n    break\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentEnumCaseComment() {
        let input = """
        enum Foo {
           /// bar
           case bar
        }
        """
        let output = """
        enum Foo {
            /// bar
            case bar
        }
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentMultipleSingleLineSwitchCaseCommentsCorrectly() {
        let input = "switch x {\n// comment 1\n// comment 2\ncase y:\n// comment\nbreak\n}"
        let output = "switch x {\n// comment 1\n// comment 2\ncase y:\n    // comment\n    break\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentIfCase() {
        let input = "{\nif case let .foo(msg) = error {}\n}"
        let output = "{\n    if case let .foo(msg) = error {}\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentIfCaseCommaCase() {
        let input = "{\nif case let .foo(msg) = a,\ncase let .bar(msg) = b {}\n}"
        let output = "{\n    if case let .foo(msg) = a,\n        case let .bar(msg) = b {}\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
        let options = FormatOptions(xcodeIndentation: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]),
                       try format(input, rules: [FormatRules.indent], options: options))
    }

    func testIndentGuardCase() {
        let input = "{\nguard case .Foo = error else {}\n}"
        let output = "{\n    guard case .Foo = error else {}\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentUnknownDefault() {
        let input = """
        switch foo {
        case .bar:
            break
        @unknown default:
            break
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentUnknownCase() {
        let input = """
        switch foo {
        case .bar:
            break
        @unknown case _:
            break
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testWrappedClassDeclaration() {
        let input = """
        class Foo: Bar,
            Baz {
            init() {}
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testWrappedClassDeclarationLikeXcode() {
        let input = """
        class Foo: Bar,
            Baz {
            init() {}
        }
        """
        let output = """
        class Foo: Bar,
        Baz {
            init() {}
        }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    // indentCase = true

    func testSwitchCaseWithIndentCaseTrue() {
        let input = "switch x {\ncase foo:\nbreak\ncase bar:\nbreak\ndefault:\nbreak\n}"
        let output = "switch x {\n    case foo:\n        break\n    case bar:\n        break\n    default:\n        break\n}"
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testSwitchWrappedEnumCaseWithIndentCaseTrue() {
        let input = "switch x {\ncase .foo,\n.bar,\n    .baz:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\n    case .foo,\n         .bar,\n         .baz:\n        break\n    default:\n        break\n}"
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIndentMultilineSwitchCaseCommentsWithIndentCaseTrue() {
        let input = "switch x {\n/*\n * comment\n */\ncase y:\nbreak\n/*\n * comment\n */\ndefault:\nbreak\n}"
        let output = "switch x {\n    /*\n     * comment\n     */\n    case y:\n        break\n    /*\n     * comment\n     */\n    default:\n        break\n}"
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testNoMangleLabelWhenIndentCaseTrue() {
        let input = "foo: while true {\n    break foo\n}"
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIndentMultipleSingleLineSwitchCaseCommentsWithCommentsIgnoredCorrectlyWhenIndentCaseTrue() {
        let input = """
        switch x {
            // bar
            case .y: return 1
            // baz
            case .z: return 2
        }
        """
        let options = FormatOptions(indentCase: true, indentComments: false)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIndentUnknownDefaultCorrectlyWhenIndentCaseTrue() {
        let input = """
        switch foo {
            case .bar:
                break
            @unknown default:
                break
        }
        """
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIndentUnknownCaseCorrectlyWhenIndentCaseTrue() {
        let input = """
        switch foo {
            case .bar:
                break
            @unknown case _:
                break
        }
        """
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    // indent wrapped lines

    func testWrappedLineAfterOperator() {
        let input = "if x {\nlet y = foo +\nbar\n}"
        let output = "if x {\n    let y = foo +\n        bar\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedLineAfterComma() {
        let input = "let a = b,\nb = c"
        let output = "let a = b,\n    b = c"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedBeforeComma() {
        let input = "let a = b\n, b = c"
        let output = "let a = b\n    , b = c"
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["leadingDelimiters"])
    }

    func testWrappedLineAfterCommaInsideArray() {
        let input = "[\nfoo,\nbar,\n]"
        let output = "[\n    foo,\n    bar,\n]"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedLineBeforeCommaInsideArray() {
        let input = "[\nfoo\n, bar,\n]"
        let output = "[\n    foo\n    , bar,\n]"
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options,
                       exclude: ["leadingDelimiters"])
    }

    func testWrappedLineAfterCommaInsideInlineArray() {
        let input = "[foo,\nbar]"
        let output = "[foo,\n bar]"
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testWrappedLineBeforeCommaInsideInlineArray() {
        let input = "[foo\n, bar]"
        let output = "[foo\n , bar]"
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options,
                       exclude: ["leadingDelimiters"])
    }

    func testWrappedLineAfterColonInFunction() {
        let input = "func foo(bar:\nbaz)"
        let output = "func foo(bar:\n    baz)"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testNoDoubleIndentOfWrapAfterAsAfterOpenScope() {
        let input = "(foo as\nBar)"
        let output = "(foo as\n    Bar)"
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["redundantParens"])
    }

    func testNoDoubleIndentOfWrapBeforeAsAfterOpenScope() {
        let input = "(foo\nas Bar)"
        let output = "(foo\n    as Bar)"
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["redundantParens"])
    }

    func testDoubleIndentWhenScopesSeparatedByWrap() {
        let input = "(foo\nas Bar {\nbaz\n})"
        let output = "(foo\n    as Bar {\n        baz\n})"
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["redundantParens"])
    }

    func testNoDoubleIndentWhenScopesSeparatedByWrap() {
        let input = "(foo\nas Bar {\nbaz\n}\n)"
        let output = "(foo\n    as Bar {\n        baz\n    }\n)"
        testFormatting(for: input, output, rule: FormatRules.indent,
                       exclude: ["wrapArguments", "redundantParens"])
    }

    func testNoPermanentReductionInScopeAfterWrap() {
        let input = "{ foo\nas Bar\nlet baz = 5\n}"
        let output = "{ foo\n    as Bar\n    let baz = 5\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedLineBeforeOperator() {
        let input = "if x {\nlet y = foo\n+ bar\n}"
        let output = "if x {\n    let y = foo\n        + bar\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedLineBeforeIsOperator() {
        let input = "if x {\nlet y = foo\nis Bar\n}"
        let output = "if x {\n    let y = foo\n        is Bar\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedLineAfterForKeyword() {
        let input = "for\ni in range {}"
        let output = "for\n    i in range {}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedLineAfterInKeyword() {
        let input = "for i in\nrange {}"
        let output = "for i in\n    range {}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedLineAfterDot() {
        let input = "let foo = bar.\nbaz"
        let output = "let foo = bar.\n    baz"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedLineBeforeDot() {
        let input = "let foo = bar\n.baz"
        let output = "let foo = bar\n    .baz"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedLineBeforeWhere() {
        let input = "let foo = bar\nwhere foo == baz"
        let output = "let foo = bar\n    where foo == baz"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedLineAfterWhere() {
        let input = "let foo = bar where\nfoo == baz"
        let output = "let foo = bar where\n    foo == baz"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedLineBeforeGuardElse() {
        let input = "guard let foo = bar\nelse { return }"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testSingleLineGuardFollowingLine() {
        let input = "guard let foo = bar else { return }\nreturn"
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testWrappedLineBeforeGuardElseWithXcodeStyle() {
        let input = "guard let foo = bar\nelse { return }"
        let output = "guard let foo = bar\n    else { return }"
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testWrappedLineAfterGuardElseWithXcodeStyleNotIndented() {
        let input = "guard let foo = bar else\n{ return }"
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testWrappedLineBeforeGuardElseAndReturnWithXcodeStyle() {
        let input = "guard let foo = foo\nelse {\nreturn\n}"
        let output = "guard let foo = foo\n    else {\n        return\n}"
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testWrappedLineAfterGuardCommaIndented() {
        let input = "guard let foo = foo,\nlet bar = bar else {}"
        let output = "guard let foo = foo,\n    let bar = bar else {}"
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testXcodeIndentationGuardClosure() {
        let input = "guard let foo = bar(baz, completion: {\nfalse\n}) else { return }"
        let output = "guard let foo = bar(baz, completion: {\n    false\n}) else { return }"
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testNestedScopesForXcodeGuardIndentation() {
        let input = "enum Foo {\ncase bar\n\nvar foo: String {\nguard self == .bar\nelse {\nreturn \"\"\n}\nreturn \"bar\"\n}\n}"
        let output = "enum Foo {\n    case bar\n\n    var foo: String {\n        guard self == .bar\n            else {\n                return \"\"\n        }\n        return \"bar\"\n    }\n}"
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testWrappedLineAfterGuardElse() {
        // Don't indent because this case is handled by braces rule
        let input = "guard let foo = bar else\n{ return }"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testWrappedLineAfterComment() {
        let input = "foo = bar && // comment\nbaz"
        let output = "foo = bar && // comment\n    baz"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedLineInClosure() {
        let input = "forEach { item in\nprint(item)\n}"
        let output = "forEach { item in\n    print(item)\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedGuardInClosure() {
        let input = """
        forEach { foo in
            guard let foo = foo,
                let bar = bar else { break }
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testConsecutiveWraps() {
        let input = "let a = b +\nc +\nd"
        let output = "let a = b +\n    c +\n    d"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrapReset() {
        let input = "let a = b +\nc +\nd\nlet a = b +\nc +\nd"
        let output = "let a = b +\n    c +\n    d\nlet a = b +\n    c +\n    d"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentElseAfterComment() {
        let input = "if x {}\n// comment\nelse {}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testWrappedLinesWithComments() {
        let input = "let foo = bar ||\n // baz||\nquux"
        let output = "let foo = bar ||\n    // baz||\n    quux"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testNoIndentAfterAssignOperatorToVariable() {
        let input = "let greaterThan = >\nlet lessThan = <"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testNoIndentAfterDefaultAsIdentifier() {
        let input = "let foo = FileManager.default\n// Comment\nlet bar = 0"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentClosureStartingOnIndentedLine() {
        let input = "foo\n.bar {\nbaz()\n}"
        let output = "foo\n    .bar {\n        baz()\n    }"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentClosureStartingOnIndentedLineInVar() {
        let input = "var foo = foo\n.bar {\nbaz()\n}"
        let output = "var foo = foo\n    .bar {\n        baz()\n    }"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentClosureStartingOnIndentedLineInLet() {
        let input = "let foo = foo\n.bar {\nbaz()\n}"
        let output = "let foo = foo\n    .bar {\n        baz()\n    }"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentClosureStartingOnIndentedLineInTypedVar() {
        let input = "var: Int foo = foo\n.bar {\nbaz()\n}"
        let output = "var: Int foo = foo\n    .bar {\n        baz()\n    }"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentClosureStartingOnIndentedLineInTypedLet() {
        let input = "let: Int foo = foo\n.bar {\nbaz()\n}"
        let output = "let: Int foo = foo\n    .bar {\n        baz()\n    }"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testNestedWrappedIfIndents() {
        let input = "if foo {\nif bar &&\n(baz ||\nquux) {\nfoo()\n}\n}"
        let output = "if foo {\n    if bar &&\n        (baz ||\n            quux) {\n        foo()\n    }\n}"
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["andOperator"])
    }

    func testWrappedEnumThatLooksLikeIf() {
        let input = "foo &&\n bar.if {\nfoo()\n}"
        let output = "foo &&\n    bar.if {\n        foo()\n    }"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testChainedClosureIndents() {
        let input = "foo\n.bar {\nbaz()\n}\n.bar {\nbaz()\n}"
        let output = "foo\n    .bar {\n        baz()\n    }\n    .bar {\n        baz()\n    }"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testChainedClosureIndentsAfterIfCondition() {
        let input = "if foo {\nbar()\n.baz()\n}\n\nfoo\n.bar {\nbaz()\n}\n.bar {\nbaz()\n}"
        let output = "if foo {\n    bar()\n        .baz()\n}\n\nfoo\n    .bar {\n        baz()\n    }\n    .bar {\n        baz()\n    }"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testChainedClosureIndentsAfterIfCondition2() {
        let input = "if foo {\nbar()\n.baz()\n}\n\nfoo\n.bar {\nbaz()\n}.bar {\nbaz()\n}"
        let output = "if foo {\n    bar()\n        .baz()\n}\n\nfoo\n    .bar {\n        baz()\n    }.bar {\n        baz()\n    }"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testChainedClosureIndentsAfterVarDeclaration() {
        let input = "var foo: Int\nfoo\n.bar {\nbaz()\n}\n.bar {\nbaz()\n}"
        let output = "var foo: Int\nfoo\n    .bar {\n        baz()\n    }\n    .bar {\n        baz()\n    }"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testChainedClosureIndentsAfterLetDeclaration() {
        let input = "let foo: Int\nfoo\n.bar {\nbaz()\n}\n.bar {\nbaz()\n}"
        let output = "let foo: Int\nfoo\n    .bar {\n        baz()\n    }\n    .bar {\n        baz()\n    }"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedClosureIndentAfterAssignment() {
        let input = """
        let bar =
            baz { _ in
                print("baz")
            }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testChainedFunctionsInPropertySetter() {
        let input = """
        private let foo = bar(a: "A", b: "B")
        .baz()!
        .quux
        """
        let output = """
        private let foo = bar(a: "A", b: "B")
            .baz()!
            .quux
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testChainedFunctionsInPropertySetterOnNewLine() {
        let input = """
        private let foo =
        bar(a: "A", b: "B")
        .baz()!
        .quux
        """
        let output = """
        private let foo =
            bar(a: "A", b: "B")
                .baz()!
                .quux
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testChainedFunctionsInsideIf() {
        let input = "if foo {\nreturn bar()\n.baz()\n}"
        let output = "if foo {\n    return bar()\n        .baz()\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testChainedFunctionsInsideForLoop() {
        let input = "for x in y {\nfoo\n.bar {\nbaz()\n}\n.quux()\n}"
        let output = "for x in y {\n    foo\n        .bar {\n            baz()\n        }\n        .quux()\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testChainedFunctionsAfterAnIfStatement() {
        let input = "if foo {}\nbar\n.baz {\n}\n.quux()"
        let output = "if foo {}\nbar\n    .baz {\n    }\n    .quux()"
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["emptyBraces"])
    }

    func testIndentInsideWrappedIfStatementWithClosureCondition() {
        let input = "if foo({ 1 }) ||\nbar {\nbaz()\n}"
        let output = "if foo({ 1 }) ||\n    bar {\n    baz()\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentInsideWrappedClassDefinition() {
        let input = "class Foo\n: Bar {\nbaz()\n}"
        let output = "class Foo\n    : Bar {\n    baz()\n}"
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["leadingDelimiters"])
    }

    func testIndentInsideWrappedProtocolDefinition() {
        let input = "protocol Foo\n: Bar, Baz {\nbaz()\n}"
        let output = "protocol Foo\n    : Bar, Baz {\n    baz()\n}"
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["leadingDelimiters"])
    }

    func testIndentInsideWrappedVarStatement() {
        let input = "var Foo:\nBar {\nreturn 5\n}"
        let output = "var Foo:\n    Bar {\n    return 5\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testNoIndentAfterOperatorDeclaration() {
        let input = "infix operator ?=\nfunc ?= (lhs _: Int, rhs _: Int) -> Bool {}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testNoIndentAfterChevronOperatorDeclaration() {
        let input = "infix operator =<<\nfunc =<< <T>(lhs _: T, rhs _: T) -> T {}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentEnumDictionaryKeysAndValues() {
        let input = "[\n.foo:\n.bar,\n.baz:\n.quux,\n]"
        let output = "[\n    .foo:\n        .bar,\n    .baz:\n        .quux,\n]"
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIndentWrappedFunctionArgument() {
        let input = "foobar(baz: a &&\nb)"
        let output = "foobar(baz: a &&\n    b)"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentWrappedFunctionClosureArgument() {
        let input = "foobar(baz: { a &&\nb })"
        let output = "foobar(baz: { a &&\n        b })"
        testFormatting(for: input, output, rule: FormatRules.indent,
                       exclude: ["trailingClosures", "braces"])
    }

    func testIndentClassDeclarationContainingComment() {
        let input = "class Foo: Bar,\n    // Comment\n    Baz {}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testWrappedLineAfterTypeAttribute() {
        let input = """
        let f: @convention(swift)
            (Int) -> Int = { x in x }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testWrappedLineAfterTypeAttribute2() {
        let input = """
        func foo(_: @escaping
            (Int) -> Int) {}
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testWrappedLineAfterNonTypeAttribute() {
        let input = """
        @discardableResult
        func foo() -> Int { 5 }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentWrappedClosureAfterSwitch() {
        let input = """
        switch foo {
        default:
            break
        }
        bar
            .map {
                // baz
            }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    // indent xcodeindentation

    func testChainedFunctionsInPropertySetterOnNewLineWithXcodeIndentation() {
        let input = """
        private let foo =
        bar(a: "A", b: "B")
        .baz()!
        .quux
        """
        let output = """
        private let foo =
            bar(a: "A", b: "B")
                .baz()!
                .quux
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testChainedFunctionsInFunctionWithReturnOnNewLineWithXcodeIndentation() {
        let input = """
        func foo() -> Bool {
        return
        bar(a: "A", b: "B")
        .baz()!
        .quux
        }
        """
        let output = """
        func foo() -> Bool {
            return
                bar(a: "A", b: "B")
                    .baz()!
                    .quux
        }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testChainedOrOperatorsInFunctionWithReturnOnNewLineWithXcodeIndentation() {
        let input = """
        func foo(lhs: Bool, rhs: Bool) -> Bool {
        return
        lhs == rhs &&
        lhs == rhs &&
        lhs == rhs
        }
        """
        let output = """
        func foo(lhs: Bool, rhs: Bool) -> Bool {
            return
                lhs == rhs &&
                    lhs == rhs &&
                    lhs == rhs
        }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testWrappedMultilineClosureOnNewLineWithXcodeIndentation() {
        let input = """
        func foo() {
            let bar =
            {
                print("foo")
            }
        }
        """
        let output = """
        func foo() {
            let bar =
                {
                    print("foo")
                }
        }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testWrappedMultilineStringOnNewLineWithXcodeIndentation() {
        let input = """
        func foo() {
            let bar =
            \"""
            foo
            \"""
        }
        """
        let output = """
        func foo() {
            let bar =
                \"""
                foo
                \"""
        }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testChainedFunctionEndingInOpenParenNotDoubleIndented() {
        let input = """
        private let foo =
        bar.baz(
            quux
        )
        """
        let output = """
        private let foo =
            bar.baz(
                quux
            )
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    // indent comments

    func testCommentIndenting() {
        let input = "/* foo\nbar */"
        let output = "/* foo\n bar */"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testCommentIndentingWithTrailingClose() {
        let input = "/*\nfoo\n*/"
        let output = "/*\n foo\n */"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testCommentIndentingWithTrailingClose2() {
        let input = "/* foo\n*/"
        let output = "/* foo\n */"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testNestedCommentIndenting() {
        let input = """
        /*
         class foo() {
             /*
              * Nested comment
              */
             bar {}
         }
         */
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testNestedCommentIndenting2() {
        let input = """
        /**
        Some description;
        ```
        func foo() {
            bar()
        }
        ```
        */
        """
        let output = """
        /**
         Some description;
         ```
         func foo() {
             bar()
         }
         ```
         */
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testCommentedCodeBlocksNotIndented() {
        let input = "func foo() {\n//    var foo: Int\n}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testBlankCodeCommentBlockLinesNotIndented() {
        let input = "func foo() {\n//\n}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    // TODO: maybe need special case handling for this?
    func testIndentWrappedTrailingComment() {
        let input = """
        let foo = 5 // a wrapped
                    // comment
                    // block
        """
        let output = """
        let foo = 5 // a wrapped
        // comment
        // block
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    // indent multiline strings

    func testSimpleMultilineString() {
        let input = "\"\"\"\n    hello\n    world\n\"\"\""
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentIndentedSimpleMultilineString() {
        let input = "{\n\"\"\"\n    hello\n    world\n    \"\"\"\n}"
        let output = "{\n    \"\"\"\n    hello\n    world\n    \"\"\"\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testMultilineStringWithEscapedLinebreak() {
        let input = "\"\"\"\n    hello \\\n    world\n\"\"\""
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentMultilineStringWrappedAfter() {
        let input = "foo(baz:\n    \"\"\"\n    baz\n    \"\"\")"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentMultilineStringInNestedCalls() {
        let input = "foo(bar(\"\"\"\nbaz\n\"\"\"))"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testReduceIndentForMultilineString() {
        let input = """
        switch foo {
            case bar:
                return \"""
                baz
                \"""
        }
        """
        let output = """
        switch foo {
        case bar:
            return \"""
            baz
            \"""
        }
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testReduceIndentForMultilineString2() {
        let input = """
            foo(\"""
            bar
            \""")
        """
        let output = """
        foo(\"""
        bar
        \""")
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentMultilineStringWithMultilineInterpolation() {
        let input = """
        func foo() {
            \"""
                bar
                    \\(bar.map {
                        baz
                    })
                quux
            \"""
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentMultilineStringWithMultilineNestedInterpolation() {
        let input = """
        func foo() {
            \"""
                bar
                    \\(bar.map {
                        \"""
                            quux
                        \"""
                    })
                quux
            \"""
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentMultilineStringWithMultilineNestedInterpolation2() {
        let input = """
        func foo() {
            \"""
                bar
                    \\(bar.map {
                        \"""
                            quux
                        \"""
                    }
                    )
                quux
            \"""
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    // indent multiline raw strings

    func testIndentIndentedSimpleRawMultilineString() {
        let input = "{\n##\"\"\"\n    hello\n    world\n    \"\"\"##\n}"
        let output = "{\n    ##\"\"\"\n    hello\n    world\n    \"\"\"##\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    // indent #if/#else/#elseif/#endif (mode: indent)

    func testIfEndifIndenting() {
        let input = "#if x\n// foo\n#endif"
        let output = "#if x\n    // foo\n#endif"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentedIfEndifIndenting() {
        let input = "{\n#if x\n// foo\nfoo()\n#endif\n}"
        let output = "{\n    #if x\n        // foo\n        foo()\n    #endif\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIfElseEndifIndenting() {
        let input = "#if x\n    // foo\nfoo()\n#else\n    // bar\n#endif"
        let output = "#if x\n    // foo\n    foo()\n#else\n    // bar\n#endif"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testEnumIfCaseEndifIndenting() {
        let input = "enum Foo {\ncase bar\n#if x\ncase baz\n#endif\n}"
        let output = "enum Foo {\n    case bar\n    #if x\n        case baz\n    #endif\n}"
        let options = FormatOptions(indentCase: false)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testSwitchIfCaseEndifIndenting() {
        let input = "switch foo {\ncase .bar: break\n#if x\ncase .baz: break\n#endif\n}"
        let output = "switch foo {\ncase .bar: break\n#if x\n    case .baz: break\n#endif\n}"
        let options = FormatOptions(indentCase: false)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testSwitchIfCaseEndifIndenting2() {
        let input = "switch foo {\ncase .bar: break\n#if x\ncase .baz: break\n#endif\n}"
        let output = "switch foo {\n    case .bar: break\n    #if x\n        case .baz: break\n    #endif\n}"
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testSwitchIfCaseEndifIndenting3() {
        let input = "switch foo {\n#if x\ncase .bar: break\ncase .baz: break\n#endif\n}"
        let output = "switch foo {\n#if x\n    case .bar: break\n    case .baz: break\n#endif\n}"
        let options = FormatOptions(indentCase: false)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testSwitchIfCaseEndifIndenting4() {
        let input = "switch foo {\n#if x\ncase .bar:\nbreak\ncase .baz:\nbreak\n#endif\n}"
        let output = "switch foo {\n    #if x\n        case .bar:\n            break\n        case .baz:\n            break\n    #endif\n}"
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testSwitchIfCaseElseCaseEndifIndenting() {
        let input = "switch foo {\n#if x\ncase .bar: break\n#else\ncase .baz: break\n#endif\n}"
        let output = "switch foo {\n#if x\n    case .bar: break\n#else\n    case .baz: break\n#endif\n}"
        let options = FormatOptions(indentCase: false)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testSwitchIfCaseElseCaseEndifIndenting2() {
        let input = "switch foo {\n#if x\ncase .bar: break\n#else\ncase .baz: break\n#endif\n}"
        let output = "switch foo {\n    #if x\n        case .bar: break\n    #else\n        case .baz: break\n    #endif\n}"
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testSwitchIfEndifInsideCaseIndenting() {
        let input = "switch foo {\ncase .bar:\n#if x\nbar()\n#endif\nbaz()\ncase .baz: break\n}"
        let output = "switch foo {\ncase .bar:\n    #if x\n        bar()\n    #endif\n    baz()\ncase .baz: break\n}"
        let options = FormatOptions(indentCase: false)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testSwitchIfEndifInsideCaseIndenting2() {
        let input = "switch foo {\ncase .bar:\n#if x\nbar()\n#endif\nbaz()\ncase .baz: break\n}"
        let output = "switch foo {\n    case .bar:\n        #if x\n            bar()\n        #endif\n        baz()\n    case .baz: break\n}"
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIfUnknownCaseEndifIndenting() {
        let input = """
        switch foo {
        case .bar: break
        #if x
            @unknown case _: break
        #endif
        }
        """
        let options = FormatOptions(indentCase: false, ifdefIndent: .indent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIfUnknownCaseEndifIndenting2() {
        let input = """
        switch foo {
            case .bar: break
            #if x
                @unknown case _: break
            #endif
        }
        """
        let options = FormatOptions(indentCase: true, ifdefIndent: .indent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIfEndifInsideEnumIndenting() {
        let input = """
        enum Foo {
            case bar
            #if x
                case baz
            #endif
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIfEndifInsideEnumWithTrailingCommentIndenting() {
        let input = """
        enum Foo {
            case bar
            #if x
                case baz
            #endif // ends
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testNoIndentCommentBeforeIfdefAroundCase() {
        let input = """
        switch x {
        // foo
        case .foo:
            break
        // conditional
        // bar
        #if BAR
            case .bar:
                break
        // baz
        #else
            case .baz:
                break
        #endif
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testNoIndentCommentedCodeBeforeIfdefAroundCase() {
        let input = """
        func foo() {
        //    foo()
            #if BAR
        //        bar()
            #else
        //        baz()
            #endif
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testNoIndentIfdefFollowedByCommentAroundCase() {
        let input = """
        switch x {
        case .foo:
            break
        #if BAR
            // bar
            case .bar:
                break
        #else
            // baz
            case .baz:
                break
        #endif
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    // indent #if/#else/#elseif/#endif (mode: noindent)

    func testIfEndifNoIndenting() {
        let input = "#if x\n// foo\n#endif"
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIndentedIfEndifNoIndenting() {
        let input = "{\n#if x\n// foo\n#endif\n}"
        let output = "{\n    #if x\n    // foo\n    #endif\n}"
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIfElseEndifNoIndenting() {
        let input = "#if x\n// foo\n#else\n// bar\n#endif"
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIfCaseEndifNoIndenting() {
        let input = "switch foo {\ncase .bar: break\n#if x\ncase .baz: break\n#endif\n}"
        let options = FormatOptions(indentCase: false, ifdefIndent: .noIndent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIfCaseEndifNoIndenting2() {
        let input = "switch foo {\ncase .bar: break\n#if x\ncase .baz: break\n#endif\n}"
        let output = "switch foo {\n    case .bar: break\n    #if x\n    case .baz: break\n    #endif\n}"
        let options = FormatOptions(indentCase: true, ifdefIndent: .noIndent)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIfUnknownCaseEndifNoIndenting() {
        let input = """
        switch foo {
        case .bar: break
        #if x
        @unknown case _: break
        #endif
        }
        """
        let options = FormatOptions(indentCase: false, ifdefIndent: .noIndent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIfUnknownCaseEndifNoIndenting2() {
        let input = """
        switch foo {
            case .bar: break
            #if x
            @unknown case _: break
            #endif
        }
        """
        let options = FormatOptions(indentCase: true, ifdefIndent: .noIndent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIfEndifInsideCaseNoIndenting() {
        let input = "switch foo {\ncase .bar:\n#if x\nbar()\n#endif\nbaz()\ncase .baz: break\n}"
        let output = "switch foo {\ncase .bar:\n    #if x\n    bar()\n    #endif\n    baz()\ncase .baz: break\n}"
        let options = FormatOptions(indentCase: false, ifdefIndent: .noIndent)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIfEndifInsideCaseNoIndenting2() {
        let input = "switch foo {\ncase .bar:\n#if x\nbar()\n#endif\nbaz()\ncase .baz: break\n}"
        let output = "switch foo {\n    case .bar:\n        #if x\n        bar()\n        #endif\n        baz()\n    case .baz: break\n}"
        let options = FormatOptions(indentCase: true, ifdefIndent: .noIndent)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIfEndifInsideEnumNoIndenting() {
        let input = """
        enum Foo {
            case bar
            #if x
            case baz
            #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIfEndifInsideEnumWithTrailingCommentNoIndenting() {
        let input = """
        enum Foo {
            case bar
            #if x
            case baz
            #endif // ends
        }
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    // indent #if/#else/#elseif/#endif (mode: outdent)

    func testIfEndifOutdenting() {
        let input = "#if x\n// foo\n#endif"
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIndentedIfEndifOutdenting() {
        let input = "{\n#if x\n// foo\n#endif\n}"
        let output = "{\n#if x\n    // foo\n#endif\n}"
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIfElseEndifOutdenting() {
        let input = "#if x\n// foo\n#else\n// bar\n#endif"
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIndentedIfElseEndifOutdenting() {
        let input = "{\n#if x\n// foo\nfoo()\n#else\n// bar\n#endif\n}"
        let output = "{\n#if x\n    // foo\n    foo()\n#else\n    // bar\n#endif\n}"
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIfElseifEndifOutdenting() {
        let input = "#if x\n// foo\n#elseif y\n// bar\n#endif"
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIndentedIfElseifEndifOutdenting() {
        let input = "{\n#if x\n// foo\nfoo()\n#elseif y\n// bar\n#endif\n}"
        let output = "{\n#if x\n    // foo\n    foo()\n#elseif y\n    // bar\n#endif\n}"
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testNestedIndentedIfElseifEndifOutdenting() {
        let input = "{\n#if x\n#if y\n// foo\nfoo()\n#elseif y\n// bar\n#endif\n#endif\n}"
        let output = "{\n#if x\n#if y\n    // foo\n    foo()\n#elseif y\n    // bar\n#endif\n#endif\n}"
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testDoubleNestedIndentedIfElseifEndifOutdenting() {
        let input = "{\n#if x\n#if y\n#if z\n// foo\nfoo()\n#elseif y\n// bar\n#endif\n#endif\n#endif\n}"
        let output = "{\n#if x\n#if y\n#if z\n    // foo\n    foo()\n#elseif y\n    // bar\n#endif\n#endif\n#endif\n}"
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIfCaseEndifOutdenting() {
        let input = "switch foo {\ncase .bar: break\n#if x\ncase .baz: break\n#endif\n}"
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIfEndifInsideEnumOutdenting() {
        let input = """
        enum Foo {
            case bar
        #if x
            case baz
        #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIfEndifInsideEnumWithTrailingCommentOutdenting() {
        let input = """
        enum Foo {
            case bar
        #if x
            case baz
        #endif // ends
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    // indent expression after return

    func testIndentIdentifierAfterReturn() {
        let input = "if foo {\n    return\n        bar\n}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentEnumValueAfterReturn() {
        let input = "if foo {\n    return\n        .bar\n}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentMultilineExpressionAfterReturn() {
        let input = "if foo {\n    return\n        bar +\n        baz\n}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testDontIndentClosingBraceAfterReturn() {
        let input = "if foo {\n    return\n}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testDontIndentCaseAfterReturn() {
        let input = "switch foo {\ncase bar:\n    return\ncase baz:\n    return\n}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testDontIndentCaseAfterWhere() {
        let input = "switch foo {\ncase bar\nwhere baz:\nreturn\ndefault:\nreturn\n}"
        let output = "switch foo {\ncase bar\n    where baz:\n    return\ndefault:\n    return\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testDontIndentIfAfterReturn() {
        let input = "if foo {\n    return\n    if bar {}\n}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testDontIndentFuncAfterReturn() {
        let input = "if foo {\n    return\n    func bar() {}\n}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    // indent fragments

    func testIndentFragment() {
        let input = "   func foo() {\nbar()\n}"
        let output = "   func foo() {\n       bar()\n   }"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIndentFragmentAfterBlankLines() {
        let input = "\n\n   func foo() {\nbar()\n}"
        let output = "\n\n   func foo() {\n       bar()\n   }"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testUnterminatedFragment() {
        let input = "class Foo {\n\n  func foo() {\nbar()\n}"
        let output = "class Foo {\n\n    func foo() {\n        bar()\n    }"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options,
                       exclude: ["blankLinesAtStartOfScope"])
    }

    func testOverTerminatedFragment() {
        let input = "   func foo() {\nbar()\n}\n\n}"
        let output = "   func foo() {\n       bar()\n   }\n\n}"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testDontCorruptPartialFragment() {
        let input = "    } foo {\n        bar\n    }\n}"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testDontCorruptPartialFragment2() {
        let input = "        return completionHandler(nil)\n    }\n}"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    // indent with tabs

    func testTabIndentWrappedTuple() {
        let input = """
        let foo = (bar: Int,
                   baz: Int)
        """
        let output = """
        let foo = (bar: Int,
        \t\t\t\t\t baz: Int)
        """
        let options = FormatOptions(indent: "\t", tabWidth: 2)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testTabIndentCase() {
        let input = """
        switch x {
        case .foo,
             .bar:
          break
        }
        """
        let output = """
        switch x {
        case .foo,
        \t\t .bar:
        \tbreak
        }
        """
        let options = FormatOptions(indent: "\t", tabWidth: 2)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testTabIndentCase2() {
        let input = """
        switch x {
            case .foo,
                 .bar:
              break
        }
        """
        let output = """
        switch x {
        \tcase .foo,
        \t\t\t .bar:
        \t\tbreak
        }
        """
        let options = FormatOptions(indent: "\t", indentCase: true, tabWidth: 2)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    // indent blank lines

    func testTruncateBlankLineBeforeIndenting() {
        // NOTE: don't convert to multiline string
        let input =
            "func foo() {\n" +
            "    guard bar = baz else { return }\n" +
            "    \n" + // should not be indented
            "    quux()\n" +
            "}"

        let rules = [FormatRules.indent, FormatRules.trailingSpace]
        let options = FormatOptions(truncateBlankLines: true)
        XCTAssertEqual(try lint(input, rules: rules, options: options), [
            Formatter.Change(line: 3, rule: FormatRules.trailingSpace, filePath: nil),
        ])
    }

    // MARK: - braces

    func testAllmanBracesAreConverted() {
        let input = "func foo()\n{\n    statement\n}"
        let output = "func foo() {\n    statement\n}"
        testFormatting(for: input, output, rule: FormatRules.braces)
    }

    func testNestedAllmanBracesAreConverted() {
        let input = """
        func foo()
        {
            for bar in baz
            {
                print(bar)
            }
        }
        """
        let output = """
        func foo() {
            for bar in baz {
                print(bar)
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.braces)
    }

    func testKnRBracesAfterComment() {
        let input = "func foo() // comment\n{\n    statement\n}"
        testFormatting(for: input, rule: FormatRules.braces)
    }

    func testKnRBracesAfterMultilineComment() {
        let input = "func foo() /* comment/ncomment */\n{\n    statement\n}"
        testFormatting(for: input, rule: FormatRules.braces)
    }

    func testKnRBracesAfterMultilineComment2() {
        let input = """
        class Foo /*
         aaa
         */
        {
            // foo
        }
        """
        testFormatting(for: input, rule: FormatRules.braces)
    }

    func testKnRExtraSpaceNotAddedBeforeBrace() {
        let input = "foo({ bar })"
        testFormatting(for: input, rule: FormatRules.braces, exclude: ["trailingClosures"])
    }

    func testKnRLinebreakNotRemovedBeforeInlineBlockNot() {
        let input = "func foo() -> Bool\n{ return false }"
        testFormatting(for: input, rule: FormatRules.braces)
    }

    func testKnRNoMangleCommentBeforeClosure() {
        let input = """
        [
            // foo
            foo,
            // bar
            {
                bar
            }(),
        ]
        """
        testFormatting(for: input, rule: FormatRules.braces)
    }

    func testKnRNoMangleClosureReturningClosure() {
        let input = """
        foo { bar in
            {
                bar()
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.braces)
    }

    func testKnRClosingBraceWrapped() {
        let input = "func foo() {\n    print(bar) }"
        let output = "func foo() {\n    print(bar)\n}"
        testFormatting(for: input, output, rule: FormatRules.braces)
    }

    func testKnRInlineBracesNotWrapped() {
        let input = "func foo() { print(bar) }"
        testFormatting(for: input, rule: FormatRules.braces)
    }

    func testKnRBracesIgnoresClosure() {
        let input = """
        let foo =
            { bar in
                print(bar)
            }
        """
        testFormatting(for: input, rule: FormatRules.braces)
    }

    func testUnbalancedClosingClosureBraceCorrected() {
        let input = """
        let foo =
            { bar in
                print(bar) }
        """
        let output = """
        let foo =
            { bar in
                print(bar)
            }
        """
        testFormatting(for: input, output, rule: FormatRules.braces)
    }

    func testAllmanComputedPropertyBracesConverted() {
        let input = """
        var foo: Int
        {
            return 5
        }
        """
        let output = """
        var foo: Int {
            return 5
        }
        """
        testFormatting(for: input, output, rule: FormatRules.braces)
    }

    func testAllmanInitBracesConverted() {
        let input = """
        init()
        {
            foo = 5
        }
        """
        let output = """
        init() {
            foo = 5
        }
        """
        testFormatting(for: input, output, rule: FormatRules.braces)
    }

    func testAllmanSubscriptBracesConverted() {
        let input = """
        subscript(i: Int) -> Int
        {
            foo[i]
        }
        """
        let output = """
        subscript(i: Int) -> Int {
            foo[i]
        }
        """
        testFormatting(for: input, output, rule: FormatRules.braces)
    }

    func testBracesForStructDeclaration() {
        let input = """
        struct Foo
        {
            // foo
        }
        """
        let output = """
        struct Foo {
            // foo
        }
        """
        testFormatting(for: input, output, rule: FormatRules.braces)
    }

    func testBracesForInit() {
        let input = """
        init(foo: Int)
        {
            self.foo = foo
        }
        """
        let output = """
        init(foo: Int) {
            self.foo = foo
        }
        """
        testFormatting(for: input, output, rule: FormatRules.braces)
    }

    func testBracesForIfStatement() {
        let input = """
        if foo
        {
            // foo
        }
        """
        let output = """
        if foo {
            // foo
        }
        """
        testFormatting(for: input, output, rule: FormatRules.braces)
    }

    func testBracesForExtension() {
        let input = """
        extension Foo
        {
            // foo
        }
        """
        let output = """
        extension Foo {
            // foo
        }
        """
        testFormatting(for: input, output, rule: FormatRules.braces)
    }

    func testBracesForOptionalInit() {
        let input = """
        init?()
        {
            return nil
        }
        """
        let output = """
        init?() {
            return nil
        }
        """
        testFormatting(for: input, output, rule: FormatRules.braces)
    }

    // allman style

    func testKnRBracesAreConverted() {
        let input = "func foo() {\n    statement\n}"
        let output = "func foo()\n{\n    statement\n}"
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: FormatRules.braces, options: options)
    }

    func testAllmanBlankLineAfterBraceRemoved() {
        let input = "func foo() {\n    \n    statement\n}"
        let output = "func foo()\n{\n    statement\n}"
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: FormatRules.braces, options: options)
    }

    func testAllmanBraceInsideParensNotConverted() {
        let input = "foo({\n    bar\n})"
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, rule: FormatRules.braces, options: options,
                       exclude: ["trailingClosures"])
    }

    func testAllmanBraceDoClauseIndent() {
        let input = "do {\n    foo\n}"
        let output = "do\n{\n    foo\n}"
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: FormatRules.braces, options: options)
    }

    func testAllmanBraceCatchClauseIndent() {
        let input = "do {\n    try foo\n}\ncatch {\n}"
        let output = "do\n{\n    try foo\n}\ncatch\n{\n}"
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: FormatRules.braces, options: options,
                       exclude: ["emptyBraces"])
    }

    func testAllmanBraceRepeatWhileIndent() {
        let input = "repeat {\n    foo\n}\nwhile x"
        let output = "repeat\n{\n    foo\n}\nwhile x"
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: FormatRules.braces, options: options)
    }

    func testAllmanBraceOptionalComputedPropertyIndent() {
        let input = "var foo: Int? {\n    return 5\n}"
        let output = "var foo: Int?\n{\n    return 5\n}"
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: FormatRules.braces, options: options)
    }

    func testAllmanBraceThrowsFunctionIndent() {
        let input = "func foo() throws {\n    bar\n}"
        let output = "func foo() throws\n{\n    bar\n}"
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: FormatRules.braces, options: options)
    }

    func testAllmanBraceAfterCommentIndent() {
        let input = "func foo() { // foo\n\n    bar\n}"
        let output = "func foo()\n{ // foo\n    bar\n}"
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: FormatRules.braces, options: options)
    }

    func testAllmanBraceAfterSwitch() {
        let input = "switch foo {\ncase bar: break\n}"
        let output = "switch foo\n{\ncase bar: break\n}"
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: FormatRules.braces, options: options)
    }

    func testAllmanBracesForStructDeclaration() {
        let input = """
        struct Foo {
            // foo
        }
        """
        let output = """
        struct Foo
        {
            // foo
        }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: FormatRules.braces, options: options)
    }

    func testAllmanBracesForInit() {
        let input = """
        init(foo: Int) {
            self.foo = foo
        }
        """
        let output = """
        init(foo: Int)
        {
            self.foo = foo
        }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: FormatRules.braces, options: options)
    }

    func testAllmanBracesForOptionalInit() {
        let input = """
        init?() {
            return nil
        }
        """
        let output = """
        init?()
        {
            return nil
        }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: FormatRules.braces, options: options)
    }

    func testAllmanBracesForIfStatement() {
        let input = """
        if foo {
            // foo
        }
        """
        let output = """
        if foo
        {
            // foo
        }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: FormatRules.braces, options: options)
    }

    func testAllmanBracesForIfStatement2() {
        let input = """
        if foo > 0 {
            // foo
        }
        """
        let output = """
        if foo > 0
        {
            // foo
        }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: FormatRules.braces, options: options)
    }

    func testAllmanBracesForExtension() {
        let input = """
        extension Foo {
            // foo
        }
        """
        let output = """
        extension Foo
        {
            // foo
        }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: FormatRules.braces, options: options)
    }

    // MARK: - elseOnSameLine

    func testElseOnSameLine() {
        let input = "if true {\n    1\n}\nelse { 2 }"
        let output = "if true {\n    1\n} else { 2 }"
        testFormatting(for: input, output, rule: FormatRules.elseOnSameLine)
    }

    func testElseOnSameLineOnlyAppliedToDanglingBrace() {
        let input = "if true { 1 }\nelse { 2 }"
        testFormatting(for: input, rule: FormatRules.elseOnSameLine)
    }

    func testGuardNotAffectedByElseOnSameLine() {
        let input = "guard true\nelse { return }"
        testFormatting(for: input, rule: FormatRules.elseOnSameLine)
    }

    func testElseOnSameLineDoesntEatPreviousStatement() {
        let input = "if true {}\nguard true else { return }"
        testFormatting(for: input, rule: FormatRules.elseOnSameLine)
    }

    func testElseNotOnSameLineForAllman() {
        let input = "if true\n{\n    1\n} else { 2 }"
        let output = "if true\n{\n    1\n}\nelse { 2 }"
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: FormatRules.elseOnSameLine, options: options)
    }

    func testElseOnNextLineOption() {
        let input = "if true {\n    1\n} else { 2 }"
        let output = "if true {\n    1\n}\nelse { 2 }"
        let options = FormatOptions(elseOnNextLine: true)
        testFormatting(for: input, output, rule: FormatRules.elseOnSameLine, options: options)
    }

    func testGuardNotAffectedByElseOnSameLineForAllman() {
        let input = "guard true else { return }"
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, rule: FormatRules.elseOnSameLine, options: options)
    }

    func testRepeatWhileNotOnSameLineForAllman() {
        let input = "repeat\n{\n    foo\n} while x"
        let output = "repeat\n{\n    foo\n}\nwhile x"
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: FormatRules.elseOnSameLine, options: options)
    }

    func testWhileNotAffectedByElseOnSameLineIfNotRepeatWhile() {
        let input = "func foo(x) {}\n\nwhile true {}"
        testFormatting(for: input, rule: FormatRules.elseOnSameLine)
    }

    func testCommentsNotDiscardedByElseOnSameLineRule() {
        let input = "if true {\n    1\n}\n\n// comment\nelse {}"
        testFormatting(for: input, rule: FormatRules.elseOnSameLine)
    }

    // MARK: - trailingCommas

    func testCommaAddedToSingleItem() {
        let input = "[\n    foo\n]"
        let output = "[\n    foo,\n]"
        testFormatting(for: input, output, rule: FormatRules.trailingCommas)
    }

    func testCommaAddedToLastItem() {
        let input = "[\n    foo,\n    bar\n]"
        let output = "[\n    foo,\n    bar,\n]"
        testFormatting(for: input, output, rule: FormatRules.trailingCommas)
    }

    func testCommaAddedToDictionary() {
        let input = "[\n    foo: bar\n]"
        let output = "[\n    foo: bar,\n]"
        testFormatting(for: input, output, rule: FormatRules.trailingCommas)
    }

    func testCommaNotAddedToInlineArray() {
        let input = "[foo, bar]"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testCommaNotAddedToInlineDictionary() {
        let input = "[foo: bar]"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testCommaNotAddedToSubscript() {
        let input = "foo[bar]"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testCommaAddedBeforeComment() {
        let input = "[\n    foo // comment\n]"
        let output = "[\n    foo, // comment\n]"
        testFormatting(for: input, output, rule: FormatRules.trailingCommas)
    }

    func testCommaNotAddedAfterComment() {
        let input = "[\n    foo, // comment\n]"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testCommaNotAddedInsideEmptyArrayLiteral() {
        let input = "foo = [\n]"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testCommaNotAddedInsideEmptyDictionaryLiteral() {
        let input = "foo = [:\n]"
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, rule: FormatRules.trailingCommas, options: options)
    }

    func testTrailingCommaRemovedInInlineArray() {
        let input = "[foo,]"
        let output = "[foo]"
        testFormatting(for: input, output, rule: FormatRules.trailingCommas)
    }

    func testTrailingCommaNotAddedToSubscript() {
        let input = "foo[\n    bar\n]"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testTrailingCommaNotAddedToSubscript2() {
        let input = "foo?[\n    bar\n]"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testTrailingCommaNotAddedToSubscript3() {
        let input = "foo()[\n    bar\n]"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testTrailingCommaNotAddedToTypeDeclaration() {
        let input = "var: [\n    Int:\n        String\n]"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testTrailingCommaNotAddedToTypeDeclaration2() {
        let input = "func foo(bar: [\n    Int:\n        String\n])"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testTrailingCommaNotAddedToTypeDeclaration3() {
        let input = """
        func foo() -> [
            String: String
        ]
        """
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    // trailingCommas = false

    func testCommaNotAddedToLastItem() {
        let input = "[\n    foo,\n    bar\n]"
        let options = FormatOptions(trailingCommas: false)
        testFormatting(for: input, rule: FormatRules.trailingCommas, options: options)
    }

    func testCommaRemovedFromLastItem() {
        let input = "[\n    foo,\n    bar,\n]"
        let output = "[\n    foo,\n    bar\n]"
        let options = FormatOptions(trailingCommas: false)
        testFormatting(for: input, output, rule: FormatRules.trailingCommas, options: options)
    }

    // MARK: - todos

    func testMarkIsUpdated() {
        let input = "// MARK foo"
        let output = "// MARK: foo"
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testTodoIsUpdated() {
        let input = "// TODO foo"
        let output = "// TODO: foo"
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testFixmeIsUpdated() {
        let input = "//    FIXME foo"
        let output = "//    FIXME: foo"
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testMarkWithColonSeparatedBySpace() {
        let input = "// MARK : foo"
        let output = "// MARK: foo"
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testMarkWithTripleSlash() {
        let input = "/// MARK: foo"
        let output = "// MARK: foo"
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testMarkWithNoSpaceAfterColon() {
        // NOTE: this was an unintended side-effect, but I like it
        let input = "// MARK:foo"
        let output = "// MARK: foo"
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testMarkInsideMultilineComment() {
        let input = "/* MARK foo */"
        let output = "/* MARK: foo */"
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testNoExtraSpaceAddedAfterTodo() {
        let input = "/* TODO: */"
        testFormatting(for: input, rule: FormatRules.todos)
    }

    func testLowercaseMarkColonIsUpdated() {
        let input = "// mark: foo"
        let output = "// MARK: foo"
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testMixedCaseMarkColonIsUpdated() {
        let input = "// Mark: foo"
        let output = "// MARK: foo"
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testLowercaseMarkIsNotUpdated() {
        let input = "// mark as read"
        testFormatting(for: input, rule: FormatRules.todos)
    }

    func testMixedCaseMarkIsNotUpdated() {
        let input = "// Mark as read"
        testFormatting(for: input, rule: FormatRules.todos)
    }

    func testLowercaseMarkDashIsUpdated() {
        let input = "// mark - foo"
        let output = "// MARK: - foo"
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testSpaceAddedBeforeMarkDash() {
        let input = "// MARK:- foo"
        let output = "// MARK: - foo"
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testSpaceAddedAfterMarkDash() {
        let input = "// MARK: -foo"
        let output = "// MARK: - foo"
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testSpaceAddedAroundMarkDash() {
        let input = "// MARK:-foo"
        let output = "// MARK: - foo"
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testSpaceNotAddedAfterMarkDashAtEndOfString() {
        let input = "// MARK: -"
        testFormatting(for: input, rule: FormatRules.todos)
    }

    // MARK: - semicolons

    func testSemicolonRemovedAtEndOfLine() {
        let input = "print(\"hello\");\n"
        let output = "print(\"hello\")\n"
        testFormatting(for: input, output, rule: FormatRules.semicolons)
    }

    func testSemicolonRemovedAtStartOfLine() {
        let input = "\n;print(\"hello\")"
        let output = "\nprint(\"hello\")"
        testFormatting(for: input, output, rule: FormatRules.semicolons)
    }

    func testSemicolonRemovedAtEndOfProgram() {
        let input = "print(\"hello\");"
        let output = "print(\"hello\")"
        testFormatting(for: input, output, rule: FormatRules.semicolons)
    }

    func testSemicolonRemovedAtStartOfProgram() {
        let input = ";print(\"hello\")"
        let output = "print(\"hello\")"
        testFormatting(for: input, output, rule: FormatRules.semicolons)
    }

    func testIgnoreInlineSemicolon() {
        let input = "print(\"hello\"); print(\"goodbye\")"
        let options = FormatOptions(allowInlineSemicolons: true)
        testFormatting(for: input, rule: FormatRules.semicolons, options: options)
    }

    func testReplaceInlineSemicolon() {
        let input = "print(\"hello\"); print(\"goodbye\")"
        let output = "print(\"hello\")\nprint(\"goodbye\")"
        let options = FormatOptions(allowInlineSemicolons: false)
        testFormatting(for: input, output, rule: FormatRules.semicolons, options: options)
    }

    func testReplaceSemicolonFollowedByComment() {
        let input = "print(\"hello\"); // comment\nprint(\"goodbye\")"
        let output = "print(\"hello\") // comment\nprint(\"goodbye\")"
        let options = FormatOptions(allowInlineSemicolons: true)
        testFormatting(for: input, output, rule: FormatRules.semicolons, options: options)
    }

    func testSemicolonsNotReplacedInForLoop() {
        let input = "for (i = 0; i < 5; i++)"
        let options = FormatOptions(allowInlineSemicolons: false)
        testFormatting(for: input, rule: FormatRules.semicolons, options: options)
    }

    func testSemicolonsNotReplacedInForLoopContainingComment() {
        let input = "for (i = 0 // comment\n    ; i < 5; i++)"
        let options = FormatOptions(allowInlineSemicolons: false)
        testFormatting(for: input, rule: FormatRules.semicolons, options: options,
                       exclude: ["leadingDelimiters"])
    }

    func testSemicolonNotReplacedAfterReturn() {
        let input = "return;\nfoo()"
        testFormatting(for: input, rule: FormatRules.semicolons)
    }

    func testSemicolonReplacedAfterReturnIfEndOfScope() {
        let input = "do { return; }"
        let output = "do { return }"
        testFormatting(for: input, output, rule: FormatRules.semicolons)
    }

    // MARK: - ranges

    func testSpaceAroundRangeOperatorsWithDefaultOptions() {
        let input = "foo..<bar"
        let output = "foo ..< bar"
        testFormatting(for: input, output, rule: FormatRules.ranges)
    }

    // spaceAroundRangeOperators = true

    func testNoSpaceAroundRangeOperatorsWithCustomOptions() {
        let input = "foo ..< bar"
        let output = "foo..<bar"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, output, rule: FormatRules.ranges, options: options)
    }

    func testNoSpaceAddedAroundVariadic() {
        let input = "foo(bar: Int...)"
        let options = FormatOptions(spaceAroundRangeOperators: true)
        testFormatting(for: input, rule: FormatRules.ranges, options: options)
    }

    func testNoSpaceAddedAroundVariadicWithComment() {
        let input = "foo(bar: Int.../* one or more */)"
        let options = FormatOptions(spaceAroundRangeOperators: true)
        testFormatting(for: input, rule: FormatRules.ranges, options: options,
                       exclude: ["spaceAroundComments", "spaceAroundOperators"])
    }

    func testNoSpaceAddedAroundVariadicThatIsntLastArg() {
        let input = "foo(bar: Int..., baz: Int)"
        let options = FormatOptions(spaceAroundRangeOperators: true)
        testFormatting(for: input, rule: FormatRules.ranges, options: options)
    }

    func testNoSpaceAddedAroundSplitLineVariadic() {
        let input = "foo(\n    bar: Int...\n)"
        let options = FormatOptions(spaceAroundRangeOperators: true)
        testFormatting(for: input, rule: FormatRules.ranges, options: options)
    }

    func testNoSpaceAddedAroundTrailingRangeOperator() {
        let input = "foo[bar...]"
        let options = FormatOptions(spaceAroundRangeOperators: true)
        testFormatting(for: input, rule: FormatRules.ranges, options: options)
    }

    func testNoSpaceAddedBeforeLeadingRangeOperator() {
        let input = "foo[...bar]"
        let options = FormatOptions(spaceAroundRangeOperators: true)
        testFormatting(for: input, rule: FormatRules.ranges, options: options)
    }

    func testSpaceNotRemovedBeforeLeadingRangeOperator() {
        let input = "let range = ..<foo.endIndex"
        let options = FormatOptions(spaceAroundRangeOperators: true)
        testFormatting(for: input, rule: FormatRules.ranges, options: options)
    }

    // spaceAroundRangeOperators = false

    func testSpaceNotRemovedBeforeLeadingRangeOperatorWithSpaceAroundRangeOperatorsFalse() {
        let input = "let range = ..<foo.endIndex"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: FormatRules.ranges, options: options)
    }

    func testSpaceOnOneSideOfRangeMatchedByCommentNotRemoved() {
        let input = "let range = 0 .../* foo */4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: FormatRules.ranges, options: options,
                       exclude: ["spaceAroundComments"])
    }

    func testSpaceOnOneSideOfRangeMatchedByCommentNotRemoved2() {
        let input = "let range = 0/* foo */... 4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: FormatRules.ranges, options: options,
                       exclude: ["spaceAroundComments"])
    }

    func testSpaceAroundRangeWithCommentOnOneSideNotRemoved() {
        let input = "let range = 0 ... /* foo */4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: FormatRules.ranges, options: options,
                       exclude: ["spaceAroundComments"])
    }

    func testSpaceAroundRangeWithCommentOnOneSideNotRemoved2() {
        let input = "let range = 0/* foo */ ... 4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: FormatRules.ranges, options: options,
                       exclude: ["spaceAroundComments"])
    }

    func testSpaceOnOneSideOfRangeMatchedByLinebreakNotRemoved() {
        let input = "let range = 0 ...\n4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: FormatRules.ranges, options: options,
                       exclude: ["indent"])
    }

    func testSpaceOnOneSideOfRangeMatchedByLinebreakNotRemoved2() {
        let input = "let range = 0\n... 4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: FormatRules.ranges, options: options,
                       exclude: ["indent"])
    }

    func testSpaceAroundRangeWithLinebreakOnOneSideNotRemoved() {
        let input = "let range = 0 ... \n4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: FormatRules.ranges, options: options,
                       exclude: ["indent", "trailingSpace"])
    }

    func testSpaceAroundRangeWithLinebreakOnOneSideNotRemoved2() {
        let input = "let range = 0\n ... 4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: FormatRules.ranges, options: options,
                       exclude: ["indent"])
    }

    func testSpaceNotRemovedAroundRangeFollowedByPrefixOperator() {
        let input = "let range = 0 ... -4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: FormatRules.ranges, options: options)
    }

    func testSpaceNotRemovedAroundRangePreceededByPostfixOperator() {
        let input = "let range = 0>> ... 4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: FormatRules.ranges, options: options)
    }

    // MARK: - specifiers

    func testVarSpecifiersCorrected() {
        let input = "unowned private static var foo"
        let output = "private unowned static var foo"
        testFormatting(for: input, output, rule: FormatRules.specifiers)
    }

    func testPrivateSetSpecifierNotMangled() {
        let input = "private(set) public weak lazy var foo"
        let output = "public private(set) lazy weak var foo"
        testFormatting(for: input, output, rule: FormatRules.specifiers)
    }

    func testPrivateRequiredStaticFuncSpecifiers() {
        let input = "required static private func foo()"
        let output = "private required static func foo()"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: FormatRules.specifiers, options: options)
    }

    func testPrivateConvenienceInit() {
        let input = "convenience private init()"
        let output = "private convenience init()"
        testFormatting(for: input, output, rule: FormatRules.specifiers)
    }

    func testSpaceInSpecifiersLeftIntact() {
        let input = "weak private(set) /* read-only */\npublic var"
        let output = "public private(set) /* read-only */\nweak var"
        testFormatting(for: input, output, rule: FormatRules.specifiers)
    }

    func testPrefixSpecifier() {
        let input = "prefix public static func - (rhs: Foo) -> Foo"
        let output = "public static prefix func - (rhs: Foo) -> Foo"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: FormatRules.specifiers, options: options)
    }

    func testSpecifierOrder() {
        let input = "override public var foo: Int { 5 }"
        let output = "public override var foo: Int { 5 }"
        let options = FormatOptions(specifierOrder: ["public", "override"])
        testFormatting(for: input, output, rule: FormatRules.specifiers, options: options)
    }

    func testNoConfusePostfixIdentifierWithKeyword() {
        let input = "var foo = .postfix\noverride init() {}"
        testFormatting(for: input, rule: FormatRules.specifiers)
    }

    func testNoConfusePostfixIdentifierWithKeyword2() {
        let input = "var foo = postfix\noverride init() {}"
        testFormatting(for: input, rule: FormatRules.specifiers)
    }

    func testNoConfuseCaseWithSpecifier() {
        let input = """
        enum Foo {
            case strong
            case weak
            public init() {}
        }
        """
        testFormatting(for: input, rule: FormatRules.specifiers)
    }

    // MARK: - void

    func testEmptyParensReturnValueConvertedToVoid() {
        let input = "() -> ()"
        let output = "() -> Void"
        testFormatting(for: input, output, rule: FormatRules.void)
    }

    func testSpacedParensReturnValueConvertedToVoid() {
        let input = "() -> ( \n)"
        let output = "() -> Void"
        testFormatting(for: input, output, rule: FormatRules.void)
    }

    func testParensContainingCommentNotConvertedToVoid() {
        let input = "() -> ( /* Hello World */ )"
        testFormatting(for: input, rule: FormatRules.void)
    }

    func testParensRemovedAroundVoid() {
        let input = "() -> (Void)"
        let output = "() -> Void"
        testFormatting(for: input, output, rule: FormatRules.void)
    }

    func testVoidArgumentConvertedToEmptyParens() {
        let input = "Void -> Void"
        let output = "() -> Void"
        testFormatting(for: input, output, rule: FormatRules.void)
    }

    func testVoidArgumentInParensNotConvertedToEmptyParens() {
        let input = "(Void) -> Void"
        testFormatting(for: input, rule: FormatRules.void)
    }

    func testAnonymousVoidArgumentNotConvertedToEmptyParens() {
        let input = "{ (_: Void) -> Void in }"
        testFormatting(for: input, rule: FormatRules.void)
    }

    func testFuncWithAnonymousVoidArgumentNotStripped() {
        let input = "func foo(_: Void) -> Void"
        testFormatting(for: input, rule: FormatRules.void)
    }

    func testFunctionThatReturnsAFunction() {
        let input = "(Void) -> Void -> ()"
        let output = "(Void) -> () -> Void"
        testFormatting(for: input, output, rule: FormatRules.void)
    }

    func testFunctionThatReturnsAFunctionThatThrows() {
        let input = "(Void) -> Void throws -> ()"
        let output = "(Void) -> () throws -> Void"
        testFormatting(for: input, output, rule: FormatRules.void)
    }

    func testChainOfFunctionsIsNotChanged() {
        let input = "() -> () -> () -> Void"
        testFormatting(for: input, rule: FormatRules.void)
    }

    func testChainOfFunctionsWithThrowsIsNotChanged() {
        let input = "() -> () throws -> () throws -> Void"
        testFormatting(for: input, rule: FormatRules.void)
    }

    func testVoidThrowsIsNotMangled() {
        let input = "(Void) throws -> Void"
        testFormatting(for: input, rule: FormatRules.void)
    }

    func testEmptyClosureArgsNotMangled() {
        let input = "{ () in }"
        testFormatting(for: input, rule: FormatRules.void)
    }

    func testEmptyClosureReturnValueConvertedToVoid() {
        let input = "{ () -> () in }"
        let output = "{ () -> Void in }"
        testFormatting(for: input, output, rule: FormatRules.void)
    }

    func testAnonymousVoidClosureNotChanged() {
        let input = "{ (_: Void) in }"
        testFormatting(for: input, rule: FormatRules.void, exclude: ["unusedArguments"])
    }

    func testVoidLiteralNotConvertedToParens() {
        let input = "foo(Void())"
        testFormatting(for: input, rule: FormatRules.void)
    }

    func testMalformedFuncDoesNotCauseInvalidOutput() throws {
        let input = "func baz(Void) {}"
        testFormatting(for: input, rule: FormatRules.void)
    }

    func testEmptyParensInGenericsConvertedToVoid() {
        let input = "Foo<(), ()>"
        let output = "Foo<Void, Void>"
        testFormatting(for: input, output, rule: FormatRules.void)
    }

    // useVoid = false

    func testUseVoidOptionFalse() {
        let input = "(Void) -> Void"
        let output = "(()) -> ()"
        let options = FormatOptions(useVoid: false)
        testFormatting(for: input, output, rule: FormatRules.void, options: options)
    }

    func testNamespacedVoidNotConverted() {
        let input = "() -> Swift.Void"
        let options = FormatOptions(useVoid: false)
        testFormatting(for: input, rule: FormatRules.void, options: options)
    }

    func testTypealiasVoidNotConverted() {
        let input = "public typealias Void = ()"
        let options = FormatOptions(useVoid: false)
        testFormatting(for: input, rule: FormatRules.void, options: options)
    }

    func testVoidClosureReturnValueConvertedToEmptyTuple() {
        let input = "{ () -> Void in }"
        let output = "{ () -> () in }"
        let options = FormatOptions(useVoid: false)
        testFormatting(for: input, output, rule: FormatRules.void, options: options)
    }

    func testVoidLiteralNotConvertedToParensWithVoidOptionFalse() {
        let input = "foo(Void())"
        let options = FormatOptions(useVoid: false)
        testFormatting(for: input, rule: FormatRules.void, options: options)
    }

    // MARK: - redundantParens

    // around expressions

    func testRedundantParensRemoved() {
        let input = "(x || y)"
        let output = "x || y"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRedundantParensRemoved2() {
        let input = "(x) || y"
        let output = "x || y"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRedundantParensRemoved3() {
        let input = "x + (5)"
        let output = "x + 5"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRedundantParensRemoved4() {
        let input = "(.bar)"
        let output = ".bar"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRedundantParensRemoved5() {
        let input = "(Foo.bar)"
        let output = "Foo.bar"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRedundantParensRemoved6() {
        let input = "(foo())"
        let output = "foo()"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRequiredParensNotRemoved() {
        let input = "(x || y) * z"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testRequiredParensNotRemoved2() {
        let input = "(x + y) as Int"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testRequiredParensNotRemoved3() {
        let input = "a = (x is y)"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testRequiredParensNotRemovedBeforeSubscript() {
        let input = "(foo + bar)[baz]"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testRedundantParensRemovedBeforeCollectionLiteral() {
        let input = "(foo + bar)\n[baz]"
        let output = "foo + bar\n[baz]"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRequiredParensNotRemovedBeforeFunctionInvocation() {
        let input = "(foo + bar)(baz)"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testRedundantParensRemovedBeforeTuple() {
        let input = "(foo + bar)\n(baz, quux).0"
        let output = "foo + bar\n(baz, quux).0"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRequiredParensNotRemovedBeforePostfixOperator() {
        let input = "(foo + bar)!"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testRequiredParensNotRemovedBeforeInfixOperator() {
        let input = "(foo + bar) * baz"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testMeaningfulParensNotRemovedAroundSelectorStringLiteral() {
        let input = "Selector((\"foo\"))"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensRemovedOnLineAfterSelectorIdentifier() {
        let input = "Selector\n((\"foo\"))"
        let output = "Selector\n(\"foo\")"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testMeaningfulParensNotRemovedAroundFileLiteral() {
        let input = "func foo(_ file: String = (#file)) {}"
        testFormatting(for: input, rule: FormatRules.redundantParens, exclude: ["unusedArguments"])
    }

    // around conditions

    func testRedundantParensRemovedInIf() {
        let input = "if (x || y) {}"
        let output = "if x || y {}"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRedundantParensRemovedInIf2() {
        let input = "if (x) || y {}"
        let output = "if x || y {}"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRedundantParensRemovedInIf3() {
        let input = "if x + (5) == 6 {}"
        let output = "if x + 5 == 6 {}"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRedundantParensRemovedInIf4() {
        let input = "if (x || y), let foo = bar {}"
        let output = "if x || y, let foo = bar {}"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRedundantParensRemovedInIf5() {
        let input = "if (.bar) {}"
        let output = "if .bar {}"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRedundantParensRemovedInIf6() {
        let input = "if (Foo.bar) {}"
        let output = "if Foo.bar {}"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRedundantParensRemovedInIf7() {
        let input = "if (foo()) {}"
        let output = "if foo() {}"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRedundantParensRemovedInIf8() {
        let input = "if x, (y == 2) {}"
        let output = "if x, y == 2 {}"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRedundantParensRemovedInIfWithNoSpace() {
        let input = "if(x) {}"
        let output = "if x {}"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRedundantParensRemovedInHashIfWithNoSpace() {
        let input = "#if(x)\n#endif"
        let output = "#if x\n#endif"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRequiredParensNotRemovedInIf() {
        let input = "if (x || y) * z {}"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testOuterParensRemovedInWhile() {
        let input = "while ((x || y) && z) {}"
        let output = "while (x || y) && z {}"
        testFormatting(for: input, output, rule: FormatRules.redundantParens, exclude: ["andOperator"])
    }

    func testOuterParensRemovedInIf() {
        let input = "if (Foo.bar(baz)) {}"
        let output = "if Foo.bar(baz) {}"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testCaseOuterParensRemoved() {
        let input = "switch foo {\ncase (Foo.bar(let baz)):\n}"
        let output = "switch foo {\ncase Foo.bar(let baz):\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantParens, exclude: ["hoistPatternLet"])
    }

    func testCaseLetOuterParensRemoved() {
        let input = "switch foo {\ncase let (Foo.bar(baz)):\n}"
        let output = "switch foo {\ncase let Foo.bar(baz):\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testCaseVarOuterParensRemoved() {
        let input = "switch foo {\ncase var (Foo.bar(baz)):\n}"
        let output = "switch foo {\ncase var Foo.bar(baz):\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testsTupleNotUnwrapped() {
        let input = "tuple = (1, 2)"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testsTupleOfClosuresNotUnwrapped() {
        let input = "tuple = ({}, {})"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testSwitchTupleNotUnwrapped() {
        let input = "switch (x, y) {}"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testGuardParensRemoved() {
        let input = "guard (x == y) else { return }"
        let output = "guard x == y else { return }"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testForValueParensRemoved() {
        let input = "for (x) in (y) {}"
        let output = "for x in y {}"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testNestedClosureParensNotRemoved() {
        let input = "foo { _ in foo(y) {} }"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensInStringNotRemoved() {
        let input = "\"hello \\(world)\""
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testClosureTypeNotUnwrapped() {
        let input = "foo = (Bar) -> Baz"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testOptionalFunctionCallNotUnwrapped() {
        let input = "foo?(bar)"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testForceUnwrapFunctionCallNotUnwrapped() {
        let input = "foo!(bar)"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testCurriedFunctionCallNotUnwrapped() {
        let input = "foo(bar)(baz)"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testCurriedFunctionCallNotUnwrapped2() {
        let input = "foo(bar)(baz) + quux"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testSubscriptFunctionCallNotUnwrapped() {
        let input = "foo[\"bar\"](baz)"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testRedundantParensRemovedInsideClosure() {
        let input = "{ (foo) + bar }"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testSpaceInsertedWhenRemovingParens() {
        let input = "if(x.y) {}"
        let output = "if x.y {}"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testSpaceInsertedWhenRemovingParens2() {
        let input = "while(!foo) {}"
        let output = "while !foo {}"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testNoDoubleSpaceWhenRemovingParens() {
        let input = "if ( x.y ) {}"
        let output = "if x.y {}"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testNoDoubleSpaceWhenRemovingParens2() {
        let input = "if (x.y) {}"
        let output = "if x.y {}"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testParensAroundRangeNotRemoved() {
        let input = "(1 ..< 10).reduce(0, combine: +)"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensForLoopWhereClauseMethodNotRemoved() {
        let input = "for foo in foos where foo.method() { print(foo) }"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensRemovedAroundFunctionArgument() {
        let input = "foo(bar: (5))"
        let output = "foo(bar: 5)"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRequiredParensNotRemovedAroundOptionalClosureType() {
        let input = "let foo = (() -> ())?"
        testFormatting(for: input, rule: FormatRules.redundantParens, exclude: ["void"])
    }

    func testRedundantParensRemovedAroundOptionalClosureType() {
        let input = "let foo = ((() -> ()))?"
        let output = "let foo = (() -> ())?"
        testFormatting(for: input, output, rule: FormatRules.redundantParens, exclude: ["void"])
    }

    func testRequiredParensNotRemovedAfterClosureArgument() {
        let input = "foo({ /* code */ }())"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testRequiredParensNotRemovedAfterClosureArgument2() {
        let input = "foo(bar: { /* code */ }())"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testRequiredParensNotRemovedAfterClosureArgument3() {
        let input = "foo(bar: 5, { /* code */ }())"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testRequiredParensNotRemovedAfterClosureInsideArray() {
        let input = "[{ /* code */ }()]"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testRequiredParensNotRemovedAfterClosureInsideArrayWithTrailingComma() {
        let input = "[{ /* code */ }(),]"
        testFormatting(for: input, rule: FormatRules.redundantParens, exclude: ["trailingCommas"])
    }

    func testRequiredParensNotRemovedAfterClosureInWhereClause() {
        let input = "case foo where { x == y }():"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    // around closure arguments

    func testSingleClosureArgumentUnwrapped() {
        let input = "{ (foo) in }"
        let output = "{ foo in }"
        testFormatting(for: input, output, rule: FormatRules.redundantParens, exclude: ["unusedArguments"])
    }

    func testSingleAnonymousClosureArgumentUnwrapped() {
        let input = "{ (_) in }"
        let output = "{ _ in }"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testSingleAnonymousClosureArgumentNotUnwrapped() {
        let input = "{ (_ foo) in }"
        testFormatting(for: input, rule: FormatRules.redundantParens, exclude: ["unusedArguments"])
    }

    func testTypedClosureArgumentNotUnwrapped() {
        let input = "{ (foo: Int) in print(foo) }"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testSingleClosureArgumentAfterCaptureListUnwrapped() {
        let input = "{ [weak self] (foo) in self.bar(foo) }"
        let output = "{ [weak self] foo in self.bar(foo) }"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testMultipleClosureArgumentUnwrapped() {
        let input = "{ (foo, bar) in foo(bar) }"
        let output = "{ foo, bar in foo(bar) }"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testTypedMultipleClosureArgumentNotUnwrapped() {
        let input = "{ (foo: Int, bar: String) in foo(bar) }"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testEmptyClosureArgsNotUnwrapped() {
        let input = "{ () in }"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testClosureArgsContainingSelfNotUnwrapped() {
        let input = "{ (self) in self }"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testClosureArgsContainingSelfNotUnwrapped2() {
        let input = "{ (foo, self) in foo(self) }"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testClosureArgsContainingSelfNotUnwrapped3() {
        let input = "{ (self, foo) in foo(self) }"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    // before trailing closure

    func testParensRemovedBeforeTrailingClosure() {
        let input = "var foo = bar() { /* some code */ }"
        let output = "var foo = bar { /* some code */ }"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testParensRemovedBeforeTrailingClosure2() {
        let input = "let foo = bar() { /* some code */ }"
        let output = "let foo = bar { /* some code */ }"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testParensRemovedBeforeTrailingClosure3() {
        let input = "var foo = bar() { /* some code */ }"
        let output = "var foo = bar { /* some code */ }"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testParensRemovedBeforeTrailingClosureInsideHashIf() {
        let input = "#if baz\n    let foo = bar() { /* some code */ }\n#endif"
        let output = "#if baz\n    let foo = bar { /* some code */ }\n#endif"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedBeforeVarBody() {
        let input = "var foo = bar() { didSet {} }"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedBeforeFunctionBody() {
        let input = "func bar() { /* some code */ }"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedBeforeIfBody() {
        let input = "if let foo = bar() { /* some code */ }"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedBeforeIfBody2() {
        let input = "if try foo as Bar && baz() { /* some code */ }"
        testFormatting(for: input, rule: FormatRules.redundantParens, exclude: ["andOperator"])
    }

    func testParensNotRemovedBeforeIfBody3() {
        let input = "if #selector(foo(_:)) && bar() { /* some code */ }"
        testFormatting(for: input, rule: FormatRules.redundantParens, exclude: ["andOperator"])
    }

    func testParensNotRemovedBeforeIfBody4() {
        let input = "if let data = #imageLiteral(resourceName: \"abc.png\").pngData() { /* some code */ }"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedBeforeIfBodyAfterTry() {
        let input = "if let foo = try bar() { /* some code */ }"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedBeforeCompoundIfBody() {
        let input = "if let foo = bar(), let baz = quux() { /* some code */ }"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedBeforeForBody() {
        let input = "for foo in bar() { /* some code */ }"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedBeforeWhileBody() {
        let input = "while let foo = bar() { /* some code */ }"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedBeforeCaseBody() {
        let input = "if case foo = bar() { /* some code */ }"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedBeforeSwitchBody() {
        let input = "switch foo() {\ndefault: break\n}"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedAfterAnonymousClosureInsideIfStatementBody() {
        let input = "if let foo = bar(), { x == y }() {}"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedInGenericInit() {
        let input = "init<T>(_: T) {}"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedInGenericInit2() {
        let input = "init<T>() {}"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedInGenericFunction() {
        let input = "func foo<T>(_: T) {}"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedInGenericFunction2() {
        let input = "func foo<T>() {}"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedInGenericInstantiation() {
        let input = "let foo = Foo<T>()"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedInGenericInstantiation2() {
        let input = "let foo = Foo<T>(bar)"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testRedundantParensRemovedAfterGenerics() {
        let input = "let foo: Foo<T>\n(a) + b"
        let output = "let foo: Foo<T>\na + b"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRedundantParensRemovedAfterGenerics2() {
        let input = "let foo: Foo<T>\n(foo())"
        let output = "let foo: Foo<T>\nfoo()"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    // closure expression

    func testParensAroundClosureRemoved() {
        let input = "let foo = ({ /* some code */ })"
        let output = "let foo = { /* some code */ }"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testParensAroundClosureAssignmentBlockRemoved() {
        let input = "let foo = ({ /* some code */ })()"
        let output = "let foo = { /* some code */ }()"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testParensAroundClosureInCompoundExpressionRemoved() {
        let input = "if foo == ({ /* some code */ }), let bar = baz {}"
        let output = "if foo == { /* some code */ }, let bar = baz {}"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedAroundClosure() {
        let input = "if (foo { $0 }) {}"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedAroundClosure2() {
        let input = "if (foo.filter { $0 > 1 }.isEmpty) {}"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedAroundClosure3() {
        let input = "if let foo = (bar.filter { $0 > 1 }).first {}"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    // around tuples

    func testParensRemovedAroundTuple() {
        let input = "let foo = ((bar: Int, baz: String))"
        let output = "let foo = (bar: Int, baz: String)"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedAroundTupleFunctionArgument() {
        let input = "let foo = bar((bar: Int, baz: String))"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedAroundTupleFunctionArgumentAfterSubscript() {
        let input = "bar[5]((bar: Int, baz: String))"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testNestedParensRemovedAroundTupleFunctionArgument() {
        let input = "let foo = bar(((bar: Int, baz: String)))"
        let output = "let foo = bar((bar: Int, baz: String))"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testNestedParensRemovedAroundTupleFunctionArgument2() {
        let input = "let foo = bar(foo: ((bar: Int, baz: String)))"
        let output = "let foo = bar(foo: (bar: Int, baz: String))"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testNestedParensRemovedAroundTupleOperands() {
        let input = "((1, 2)) == ((1, 2))"
        let output = "(1, 2) == (1, 2)"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedAroundTupleFunctionTypeDeclaration() {
        let input = "let foo: ((bar: Int, baz: String)) -> Void"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedAroundUnlabelledTupleFunctionTypeDeclaration() {
        let input = "let foo: ((Int, String)) -> Void"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedAroundTupleFunctionTypeAssignment() {
        let input = "foo = ((bar: Int, baz: String)) -> Void { _ in }"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testRedundantParensRemovedAroundTupleFunctionTypeAssignment() {
        let input = "foo = ((((bar: Int, baz: String)))) -> Void { _ in }"
        let output = "foo = ((bar: Int, baz: String)) -> Void { _ in }"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedAroundUnlabelledTupleFunctionTypeAssignment() {
        let input = "foo = ((Int, String)) -> Void { _ in }"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testRedundantParensRemovedAroundUnlabelledTupleFunctionTypeAssignment() {
        let input = "foo = ((((Int, String)))) -> Void { _ in }"
        let output = "foo = ((Int, String)) -> Void { _ in }"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedAroundTupleArgument() {
        let input = "foo((bar, baz))"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedAroundVoidGenerics() {
        let input = "let foo = Foo<Bar, (), ()>"
        testFormatting(for: input, rule: FormatRules.redundantParens, exclude: ["void"])
    }

    func testParensNotRemovedAroundTupleGenerics() {
        let input = "let foo = Foo<Bar, (Int, String), ()>"
        testFormatting(for: input, rule: FormatRules.redundantParens, exclude: ["void"])
    }

    func testParensNotRemovedAroundLabeledTupleGenerics() {
        let input = "let foo = Foo<Bar, (a: Int, b: String), ()>"
        testFormatting(for: input, rule: FormatRules.redundantParens, exclude: ["void"])
    }

    // after indexed tuple

    func testParensNotRemovedAfterTupleIndex() {
        let input = "foo.1()"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedAfterTupleIndex2() {
        let input = "foo.1(true)"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedAfterTupleIndex3() {
        let input = "foo.1((bar: Int, baz: String))"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testNestedParensRemovedAfterTupleIndex3() {
        let input = "foo.1(((bar: Int, baz: String)))"
        let output = "foo.1((bar: Int, baz: String))"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    // MARK: - trailingClosures

    func testAnonymousClosureArgumentMadeTrailing() {
        let input = "foo(foo: 5, { /* some code */ })"
        let output = "foo(foo: 5) { /* some code */ }"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    func testNamedClosureArgumentNotMadeTrailing() {
        let input = "foo(foo: 5, bar: { /* some code */ })"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testClosureArgumentPassedToFunctionInArgumentsNotMadeTrailing() {
        let input = "foo(bar { /* some code */ })"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testClosureArgumentInFunctionWithOtherClosureArgumentsNotMadeTrailing() {
        let input = "foo(foo: { /* some code */ }, { /* some code */ })"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testClosureArgumentInExpressionNotMadeTrailing() {
        let input = "if let foo = foo(foo: 5, { /* some code */ }) {}"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testClosureArgumentInCompoundExpressionNotMadeTrailing() {
        let input = "if let foo = foo(foo: 5, { /* some code */ }), let bar = bar(bar: 2, { /* some code */ }) {}"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testClosureArgumentAfterLinebreakInGuardNotMadeTrailing() {
        let input = "guard let foo =\n    bar({ /* some code */ })\nelse { return }"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testClosureMadeTrailingForNumericTupleMember() {
        let input = "foo.1(5, { bar })"
        let output = "foo.1(5) { bar }"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    func testNoRemoveParensAroundClosureFollowedByOpeningBrace() {
        let input = "foo({ bar }) { baz }"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    // solitary argument

    func testParensAroundSolitaryClosureArgumentRemoved() {
        let input = "foo({ /* some code */ })"
        let output = "foo { /* some code */ }"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    func testParensAroundNamedSolitaryClosureArgumentNotRemoved() {
        let input = "foo(foo: { /* some code */ })"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testParensAroundSolitaryClosureArgumentInExpressionNotRemoved() {
        let input = "if let foo = foo({ /* some code */ }) {}"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testParensAroundSolitaryClosureArgumentInCompoundExpressionNotRemoved() {
        let input = "if let foo = foo({ /* some code */ }), let bar = bar({ /* some code */ }) {}"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testParensAroundOptionalTrailingClosureInForLoopNotRemoved() {
        let input = "for foo in bar?.map({ $0.baz }) ?? [] {}"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testParensAroundTrailingClosureInGuardCaseLetNotRemoved() {
        let input = "guard case let .foo(bar) = baz.filter({ $0 == quux }).isEmpty else {}"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testParensAroundTrailingClosureInWhereClauseLetNotRemoved() {
        let input = "for foo in bar where baz.filter({ $0 == quux }).isEmpty {}"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testParensAroundTrailingClosureInSwitchNotRemoved() {
        let input = "switch foo({ $0 == bar }).count {}"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testSolitaryClosureMadeTrailingInChain() {
        let input = "foo.map({ $0.path }).joined()"
        let output = "foo.map { $0.path }.joined()"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    func testSpaceNotInsertedAfterClosureBeforeUnwrap() {
        let input = "let foo = bar.map({ foo($0) })?.baz"
        let output = "let foo = bar.map { foo($0) }?.baz"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    func testSpaceNotInsertedAfterClosureBeforeForceUnwrap() {
        let input = "let foo = bar.map({ foo($0) })!.baz"
        let output = "let foo = bar.map { foo($0) }!.baz"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    func testSolitaryClosureMadeTrailingForNumericTupleMember() {
        let input = "foo.1({ bar })"
        let output = "foo.1 { bar }"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    // dispatch methods

    func testDispatchAsyncClosureArgumentMadeTrailing() {
        let input = "queue.async(execute: { /* some code */ })"
        let output = "queue.async { /* some code */ }"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    func testDispatchAsyncGroupClosureArgumentMadeTrailing() {
        // TODO: async(group: , qos: , flags: , execute: )
        let input = "queue.async(group: g, execute: { /* some code */ })"
        let output = "queue.async(group: g) { /* some code */ }"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    func testDispatchAsyncAfterClosureArgumentMadeTrailing() {
        let input = "queue.asyncAfter(deadline: t, execute: { /* some code */ })"
        let output = "queue.asyncAfter(deadline: t) { /* some code */ }"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    func testDispatchAsyncAfterWallClosureArgumentMadeTrailing() {
        let input = "queue.asyncAfter(wallDeadline: t, execute: { /* some code */ })"
        let output = "queue.asyncAfter(wallDeadline: t) { /* some code */ }"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    func testDispatchSyncClosureArgumentMadeTrailing() {
        let input = "queue.sync(execute: { /* some code */ })"
        let output = "queue.sync { /* some code */ }"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    func testDispatchSyncFlagsClosureArgumentMadeTrailing() {
        let input = "queue.sync(flags: f, execute: { /* some code */ })"
        let output = "queue.sync(flags: f) { /* some code */ }"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    // autoreleasepool

    func testAutoreleasepoolMadeTrailing() {
        let input = "autoreleasepool(invoking: { /* some code */ })"
        let output = "autoreleasepool { /* some code */ }"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    // whitelisted methods

    func testCustomMethodMadeTrailing() {
        let input = "foo(bar: 1, baz: { /* some code */ })"
        let output = "foo(bar: 1) { /* some code */ }"
        let options = FormatOptions(trailingClosures: ["foo"])
        testFormatting(for: input, output, rule: FormatRules.trailingClosures, options: options)
    }

    // blacklisted methods

    func testPerformBatchUpdatesNotMadeTrailing() {
        let input = "collectionView.performBatchUpdates({ /* some code */ })"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    // multiple closures

    func testMultipleNestedClosures() throws {
        let repeatCount = 10
        let input = """
        override func foo() {
            bar {
                var baz = 5
        \(String(repeating: """
                fizz {
                    buzz {
                        fizzbuzz()
                    }
                }

        """, count: repeatCount))    }
        }
        """
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    // MARK: - redundantGet

    func testRemoveSingleLineIsolatedGet() {
        let input = "var foo: Int { get { return 5 } }"
        let output = "var foo: Int { return 5 }"
        testFormatting(for: input, output, rule: FormatRules.redundantGet)
    }

    func testRemoveMultilineIsolatedGet() {
        let input = "var foo: Int {\n    get {\n        return 5\n    }\n}"
        let output = "var foo: Int {\n    return 5\n}"
        testFormatting(for: input, [output], rules: [FormatRules.redundantGet, FormatRules.indent])
    }

    func testNoRemoveMultilineGetSet() {
        let input = "var foo: Int {\n    get { return 5 }\n    set { foo = newValue }\n}"
        testFormatting(for: input, rule: FormatRules.redundantGet)
    }

    func testNoRemoveAttributedGet() {
        let input = "var enabled: Bool { @objc(isEnabled) get { true } }"
        testFormatting(for: input, rule: FormatRules.redundantGet)
    }

    func testRemoveSubscriptGet() {
        let input = "subscript(_ index: Int) {\n    get {\n        return lookup(index)\n    }\n}"
        let output = "subscript(_ index: Int) {\n    return lookup(index)\n}"
        testFormatting(for: input, [output], rules: [FormatRules.redundantGet, FormatRules.indent])
    }

    func testGetNotRemovedInFunction() {
        let input = "func foo() {\n    get {\n        self.lookup(index)\n    }\n}"
        testFormatting(for: input, rule: FormatRules.redundantGet)
    }

    // MARK: - redundantNilInit

    func testRemoveRedundantNilInit() {
        let input = "var foo: Int? = nil\nlet bar: Int? = nil"
        let output = "var foo: Int?\nlet bar: Int? = nil"
        testFormatting(for: input, output, rule: FormatRules.redundantNilInit)
    }

    func testNoRemoveLetNilInitAfterVar() {
        let input = "var foo: Int; let bar: Int? = nil"
        testFormatting(for: input, rule: FormatRules.redundantNilInit)
    }

    func testNoRemoveNonNilInit() {
        let input = "var foo: Int? = 0"
        testFormatting(for: input, rule: FormatRules.redundantNilInit)
    }

    func testRemoveRedundantImplicitUnwrapInit() {
        let input = "var foo: Int! = nil"
        let output = "var foo: Int!"
        testFormatting(for: input, output, rule: FormatRules.redundantNilInit)
    }

    func testRemoveMultipleRedundantNilInitsInSameLine() {
        let input = "var foo: Int? = nil, bar: Int? = nil"
        let output = "var foo: Int?, bar: Int?"
        testFormatting(for: input, output, rule: FormatRules.redundantNilInit)
    }

    func testNoRemoveLazyVarNilInit() {
        let input = "lazy var foo: Int? = nil"
        testFormatting(for: input, rule: FormatRules.redundantNilInit)
    }

    func testNoRemoveLazyPublicPrivateSetVarNilInit() {
        let input = "lazy private(set) public var foo: Int? = nil"
        testFormatting(for: input, rule: FormatRules.redundantNilInit, exclude: ["specifiers"])
    }

    func testNoRemoveCodableNilInit() {
        let input = "struct Foo: Codable, Bar {\n    enum CodingKeys: String, CodingKey {\n        case bar = \"_bar\"\n    }\n\n    var bar: Int?\n    var baz: String? = nil\n}"
        testFormatting(for: input, rule: FormatRules.redundantNilInit)
    }

    func testNoRemoveNilInitWithPropertyWrapper() {
        let input = "@Foo var foo: Int? = nil"
        testFormatting(for: input, rule: FormatRules.redundantNilInit)
    }

    func testNoRemoveNilInitWithLowercasePropertyWrapper() {
        let input = "@foo var foo: Int? = nil"
        testFormatting(for: input, rule: FormatRules.redundantNilInit)
    }

    func testNoRemoveNilInitWithPropertyWrapperWithArgument() {
        let input = "@Foo(bar: baz) var foo: Int? = nil"
        testFormatting(for: input, rule: FormatRules.redundantNilInit)
    }

    func testNoRemoveNilInitWithLowercasePropertyWrapperWithArgument() {
        let input = "@foo(bar: baz) var foo: Int? = nil"
        testFormatting(for: input, rule: FormatRules.redundantNilInit)
    }

    func testRemoveNilInitWithObjcAttributes() {
        let input = "@objc var foo: Int? = nil"
        let output = "@objc var foo: Int?"
        testFormatting(for: input, output, rule: FormatRules.redundantNilInit)
    }

    func testNoRemoveNilInitInStructWithDefaultInit() {
        let input = """
        struct Foo {
            var bar: String? = nil
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantNilInit)
    }

    func testRemoveNilInitInStructWithCustomInit() {
        let input = """
        struct Foo {
            var bar: String? = nil
            init() {
                bar = "bar"
            }
        }
        """
        let output = """
        struct Foo {
            var bar: String?
            init() {
                bar = "bar"
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantNilInit)
    }

    // MARK: - redundantLet

    func testRemoveRedundantLet() {
        let input = "let _ = bar {}"
        let output = "_ = bar {}"
        testFormatting(for: input, output, rule: FormatRules.redundantLet)
    }

    func testNoRemoveLetWithType() {
        let input = "let _: String = bar {}"
        testFormatting(for: input, rule: FormatRules.redundantLet)
    }

    func testRemoveRedundantLetInCase() {
        let input = "if case .foo(let _) = bar {}"
        let output = "if case .foo(_) = bar {}"
        testFormatting(for: input, output, rule: FormatRules.redundantLet, exclude: ["redundantPattern"])
    }

    func testRemoveRedundantVarsInCase() {
        let input = "if case .foo(var _, var /* unused */ _) = bar {}"
        let output = "if case .foo(_, /* unused */ _) = bar {}"
        testFormatting(for: input, output, rule: FormatRules.redundantLet)
    }

    func testNoRemoveLetInIf() {
        let input = "if let _ = foo {}"
        testFormatting(for: input, rule: FormatRules.redundantLet)
    }

    func testNoRemoveLetInMultiIf() {
        let input = "if foo == bar, /* comment! */ let _ = baz {}"
        testFormatting(for: input, rule: FormatRules.redundantLet)
    }

    func testNoRemoveLetInGuard() {
        let input = "guard let _ = foo else {}"
        testFormatting(for: input, rule: FormatRules.redundantLet)
    }

    func testNoRemoveLetInWhile() {
        let input = "while let _ = foo {}"
        testFormatting(for: input, rule: FormatRules.redundantLet)
    }

    // MARK: - redundantPattern

    func testRemoveRedundantPatternInIfCase() {
        let input = "if case .foo(_, _) = bar {}"
        let output = "if case .foo = bar {}"
        testFormatting(for: input, output, rule: FormatRules.redundantPattern)
    }

    func testNoRemoveRequiredPatternInIfCase() {
        let input = "if case (_, _) = bar {}"
        testFormatting(for: input, rule: FormatRules.redundantPattern)
    }

    func testRemoveRedundantPatternInSwitchCase() {
        let input = "switch foo {\ncase .bar(_, _): break\ndefault: break\n}"
        let output = "switch foo {\ncase .bar: break\ndefault: break\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantPattern)
    }

    func testNoRemoveRequiredPatternInSwitchCase() {
        let input = "switch foo {\ncase (_, _): break\ndefault: break\n}"
        testFormatting(for: input, rule: FormatRules.redundantPattern)
    }

    func testSimplifyLetPattern() {
        let input = "let(_, _) = bar"
        let output = "let _ = bar"
        testFormatting(for: input, output, rule: FormatRules.redundantPattern, exclude: ["redundantLet"])
    }

    func testNoRemoveVoidFunctionCall() {
        let input = "if case .foo() = bar {}"
        testFormatting(for: input, rule: FormatRules.redundantPattern)
    }

    func testNoRemoveMethodSignature() {
        let input = "func foo(_, _) {}"
        testFormatting(for: input, rule: FormatRules.redundantPattern)
    }

    // MARK: - redundantRawValues

    func testRemoveRedundantRawString() {
        let input = "enum Foo: String {\n    case bar = \"bar\"\n    case baz = \"baz\"\n}"
        let output = "enum Foo: String {\n    case bar\n    case baz\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantRawValues)
    }

    func testRemoveCommaDelimitedCaseRawStringCases() {
        let input = "enum Foo: String { case bar = \"bar\", baz = \"baz\" }"
        let output = "enum Foo: String { case bar, baz }"
        testFormatting(for: input, output, rule: FormatRules.redundantRawValues)
    }

    func testRemoveBacktickCaseRawStringCases() {
        let input = "enum Foo: String { case `as` = \"as\", `let` = \"let\" }"
        let output = "enum Foo: String { case `as`, `let` }"
        testFormatting(for: input, output, rule: FormatRules.redundantRawValues)
    }

    func testNoRemoveRawStringIfNameDoesntMatch() {
        let input = "enum Foo: String {\n    case bar = \"foo\"\n}"
        testFormatting(for: input, rule: FormatRules.redundantRawValues)
    }

    // MARK: - redundantVoidReturnType

    func testRemoveRedundantVoidReturnType() {
        let input = "func foo() -> Void {}"
        let output = "func foo() {}"
        testFormatting(for: input, output, rule: FormatRules.redundantVoidReturnType)
    }

    func testRemoveRedundantEmptyReturnType() {
        let input = "func foo() -> () {}"
        let output = "func foo() {}"
        testFormatting(for: input, output, rule: FormatRules.redundantVoidReturnType)
    }

    func testRemoveRedundantVoidTupleReturnType() {
        let input = "func foo() -> (Void) {}"
        let output = "func foo() {}"
        testFormatting(for: input, output, rule: FormatRules.redundantVoidReturnType)
    }

    func testNoRemoveCommentFollowingRedundantVoidReturnType() {
        let input = "func foo() -> Void /* void */ {}"
        let output = "func foo() /* void */ {}"
        testFormatting(for: input, output, rule: FormatRules.redundantVoidReturnType)
    }

    func testNoRemoveRequiredVoidReturnType() {
        let input = "typealias Foo = () -> Void"
        testFormatting(for: input, rule: FormatRules.redundantVoidReturnType)
    }

    func testNoRemoveChainedVoidReturnType() {
        let input = "func foo() -> () -> Void {}"
        testFormatting(for: input, rule: FormatRules.redundantVoidReturnType)
    }

    func testNoRemoveRedundantVoidInClosureArguments() {
        let input = "{ (foo: Bar) -> Void in foo() }"
        testFormatting(for: input, rule: FormatRules.redundantVoidReturnType)
    }

    // MARK: - redundantReturn

    func testRemoveRedundantReturnInClosure() {
        let input = "foo(with: { return 5 })"
        let output = "foo(with: { 5 })"
        testFormatting(for: input, output, rule: FormatRules.redundantReturn, exclude: ["trailingClosures"])
    }

    func testRemoveRedundantReturnInClosureWithArgs() {
        let input = "foo(with: { foo in return foo })"
        let output = "foo(with: { foo in foo })"
        testFormatting(for: input, output, rule: FormatRules.redundantReturn, exclude: ["trailingClosures"])
    }

    func testRemoveRedundantReturnInMap() {
        let input = "let foo = bar.map { return 1 }"
        let output = "let foo = bar.map { 1 }"
        testFormatting(for: input, output, rule: FormatRules.redundantReturn)
    }

    func testNoRemoveReturnInComputedVar() {
        let input = "var foo: Int { return 5 }"
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testRemoveReturnInComputedVar() {
        let input = "var foo: Int { return 5 }"
        let output = "var foo: Int { 5 }"
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, output, rule: FormatRules.redundantReturn, options: options)
    }

    func testNoRemoveReturnInGet() {
        let input = "var foo: Int {\n    get { return 5 }\n    set { _foo = newValue }\n}"
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testRemoveReturnInGet() {
        let input = "var foo: Int {\n    get { return 5 }\n    set { _foo = newValue }\n}"
        let output = "var foo: Int {\n    get { 5 }\n    set { _foo = newValue }\n}"
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, output, rule: FormatRules.redundantReturn, options: options)
    }

    func testNoRemoveReturnInGetClosure() {
        let input = "let foo = get { return 5 }"
        let output = "let foo = get { 5 }"
        testFormatting(for: input, output, rule: FormatRules.redundantReturn)
    }

    func testRemoveReturnInVarClosure() {
        let input = "var foo = { return 5 }()"
        let output = "var foo = { 5 }()"
        testFormatting(for: input, output, rule: FormatRules.redundantReturn)
    }

    func testRemoveReturnInParenthesizedClosure() {
        let input = "var foo = ({ return 5 }())"
        let output = "var foo = ({ 5 }())"
        testFormatting(for: input, output, rule: FormatRules.redundantReturn, exclude: ["redundantParens"])
    }

    func testNoRemoveReturnInFunction() {
        let input = "func foo() -> Int { return 5 }"
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testRemoveReturnInFunction() {
        let input = "func foo() -> Int { return 5 }"
        let output = "func foo() -> Int { 5 }"
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, output, rule: FormatRules.redundantReturn, options: options)
    }

    func testNoRemoveReturnInOperatorFunction() {
        let input = "func + (lhs: Int, rhs: Int) -> Int { return 5 }"
        testFormatting(for: input, rule: FormatRules.redundantReturn, exclude: ["unusedArguments"])
    }

    func testRemoveReturnInOperatorFunction() {
        let input = "func + (lhs: Int, rhs: Int) -> Int { return 5 }"
        let output = "func + (lhs: Int, rhs: Int) -> Int { 5 }"
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, output, rule: FormatRules.redundantReturn, options: options,
                       exclude: ["unusedArguments"])
    }

    func testNoRemoveReturnInFailableInit() {
        let input = "init?() { return nil }"
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testRemoveReturnInFailableInit() {
        let input = "init?() { return nil }"
        let output = "init?() { nil }"
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, output, rule: FormatRules.redundantReturn, options: options)
    }

    func testNoRemoveReturnInSubscript() {
        let input = "subscript(index: Int) -> String { return nil }"
        testFormatting(for: input, rule: FormatRules.redundantReturn, exclude: ["unusedArguments"])
    }

    func testRemoveReturnInSubscript() {
        let input = "subscript(index: Int) -> String { return nil }"
        let output = "subscript(index: Int) -> String { nil }"
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, output, rule: FormatRules.redundantReturn, options: options,
                       exclude: ["unusedArguments"])
    }

    func testNoRemoveReturnInCatch() {
        let input = """
        func foo() -> Int {
            do {
                return try Bar()
            } catch let e as Error {
                return -1
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, rule: FormatRules.redundantReturn, options: options)
    }

    func testNoRemoveReturnInForIn() {
        let input = "for foo in bar { return 5 }"
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testNoRemoveReturnInForWhere() {
        let input = "for foo in bar where baz { return 5 }"
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testNoRemoveReturnInIfLetTry() {
        let input = "if let foo = try? bar() { return 5 }"
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testNoRemoveReturnInMultiIfLetTry() {
        let input = "if let foo = bar, let bar = baz { return 5 }"
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testNoRemoveReturnAfterMultipleAs() {
        let input = "if foo as? bar as? baz { return 5 }"
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testRemoveVoidReturn() {
        let input = "{ _ in return }"
        let output = "{ _ in }"
        testFormatting(for: input, output, rule: FormatRules.redundantReturn)
    }

    func testNoRemoveReturnAfterKeyPath() {
        let input = "func foo() { if bar == #keyPath(baz) { return 5 } }"
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testNoRemoveReturnAfterParentheses() {
        let input = "if let foo = (bar as? String) { return foo }"
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testNoRemoveReturnInTupleVarGetter() {
        let input = "var foo: (Int, Int) { return (1, 2) }"
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testNoRemoveReturnInIfLetWithNoSpaceAfterParen() {
        let input = """
        var foo: String? {
            if let bar = baz(){
                return bar
            } else {
                return nil
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, rule: FormatRules.redundantReturn, options: options,
                       exclude: ["spaceAroundBraces", "spaceAroundParens"])
    }

    func testNoRemoveReturnInIfWithUnParenthesizedClosure() {
        let input = """
        if foo { $0.bar } {
            return true
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testRemoveBlankLineWithReturn() {
        let input = """
        foo {
            return
                bar
        }
        """
        let output = """
        foo {
            bar
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantReturn,
                       exclude: ["indent"])
    }

    // MARK: - redundantBackticks

    func testRemoveRedundantBackticksInLet() {
        let input = "let `foo` = bar"
        let output = "let foo = bar"
        testFormatting(for: input, output, rule: FormatRules.redundantBackticks)
    }

    func testNoRemoveBackticksAroundKeyword() {
        let input = "let `let` = foo"
        testFormatting(for: input, rule: FormatRules.redundantBackticks)
    }

    func testNoRemoveBackticksAroundSelf() {
        let input = "let `self` = foo"
        testFormatting(for: input, rule: FormatRules.redundantBackticks)
    }

    func testNoRemoveBackticksAroundClassSelfInTypealias() {
        let input = "typealias `Self` = Foo"
        testFormatting(for: input, rule: FormatRules.redundantBackticks)
    }

    func testRemoveBackticksAroundClassSelfAsReturnType() {
        let input = "func foo(bar: `Self`) { print(bar) }"
        let output = "func foo(bar: Self) { print(bar) }"
        testFormatting(for: input, output, rule: FormatRules.redundantBackticks)
    }

    func testRemoveBackticksAroundClassSelfAsParameterType() {
        let input = "func foo() -> `Self` {}"
        let output = "func foo() -> Self {}"
        testFormatting(for: input, output, rule: FormatRules.redundantBackticks)
    }

    func testRemoveBackticksAroundClassSelfArgument() {
        let input = "func foo(`Self`: Foo) { print(Self) }"
        let output = "func foo(Self: Foo) { print(Self) }"
        testFormatting(for: input, output, rule: FormatRules.redundantBackticks)
    }

    func testNoRemoveBackticksAroundKeywordFollowedByType() {
        let input = "let `default`: Int = foo"
        testFormatting(for: input, rule: FormatRules.redundantBackticks)
    }

    func testNoRemoveBackticksAroundContextualGet() {
        let input = "var foo: Int {\n    `get`()\n    return 5\n}"
        testFormatting(for: input, rule: FormatRules.redundantBackticks)
    }

    func testRemoveBackticksAroundGetArgument() {
        let input = "func foo(`get` value: Int) { print(value) }"
        let output = "func foo(get value: Int) { print(value) }"
        testFormatting(for: input, output, rule: FormatRules.redundantBackticks)
    }

    func testRemoveBackticksAroundTypeAtRootLevel() {
        let input = "enum `Type` {}"
        let output = "enum Type {}"
        testFormatting(for: input, output, rule: FormatRules.redundantBackticks)
    }

    func testNoRemoveBackticksAroundTypeInsideType() {
        let input = "struct Foo {\n    enum `Type` {}\n}"
        testFormatting(for: input, rule: FormatRules.redundantBackticks)
    }

    func testNoRemoveBackticksAroundLetArgument() {
        let input = "func foo(`let`: Foo) { print(`let`) }"
        testFormatting(for: input, rule: FormatRules.redundantBackticks)
    }

    func testNoRemoveBackticksAroundTrueArgument() {
        let input = "func foo(`true`: Foo) { print(`true`) }"
        testFormatting(for: input, rule: FormatRules.redundantBackticks)
    }

    func testRemoveBackticksAroundTrueArgument() {
        let input = "func foo(`true`: Foo) { print(`true`) }"
        let output = "func foo(true: Foo) { print(`true`) }"
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: FormatRules.redundantBackticks, options: options)
    }

    func testNoRemoveBackticksAroundTypeProperty() {
        let input = "var type: Foo.`Type`"
        testFormatting(for: input, rule: FormatRules.redundantBackticks)
    }

    func testNoRemoveBackticksAroundTypePropertyInsideType() {
        let input = "struct Foo {\n    enum `Type` {}\n}"
        testFormatting(for: input, rule: FormatRules.redundantBackticks)
    }

    func testNoRemoveBackticksAroundTrueProperty() {
        let input = "var type = Foo.`true`"
        testFormatting(for: input, rule: FormatRules.redundantBackticks)
    }

    func testRemoveBackticksAroundTrueProperty() {
        let input = "var type = Foo.`true`"
        let output = "var type = Foo.true"
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: FormatRules.redundantBackticks, options: options)
    }

    func testRemoveBackticksAroundProperty() {
        let input = "var type = Foo.`bar`"
        let output = "var type = Foo.bar"
        testFormatting(for: input, output, rule: FormatRules.redundantBackticks)
    }

    func testRemoveBackticksAroundKeywordProperty() {
        let input = "var type = Foo.`default`"
        let output = "var type = Foo.default"
        testFormatting(for: input, output, rule: FormatRules.redundantBackticks)
    }

    func testRemoveBackticksAroundKeypathProperty() {
        let input = "var type = \\.`bar`"
        let output = "var type = \\.bar"
        testFormatting(for: input, output, rule: FormatRules.redundantBackticks)
    }

    func testNoRemoveBackticksAroundKeypathKeywordProperty() {
        let input = "var type = \\.`default`"
        testFormatting(for: input, rule: FormatRules.redundantBackticks)
    }

    func testRemoveBackticksAroundKeypathKeywordPropertyInSwift5() {
        let input = "var type = \\.`default`"
        let output = "var type = \\.default"
        let options = FormatOptions(swiftVersion: "5")
        testFormatting(for: input, output, rule: FormatRules.redundantBackticks, options: options)
    }

    func testNoRemoveBackticksAroundAnyProperty() {
        let input = "enum Foo {\n    case `Any`\n}"
        testFormatting(for: input, rule: FormatRules.redundantBackticks)
    }

    // MARK: - redundantSelf

    // explicitSelf = .remove

    func testSimpleRemoveRedundantSelf() {
        let input = "func foo() { self.bar() }"
        let output = "func foo() { bar() }"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfInsideStringInterpolation() {
        let input = "class Foo {\n    var bar: String?\n    func baz() {\n        print(\"\\(self.bar)\")\n    }\n}"
        let output = "class Foo {\n    var bar: String?\n    func baz() {\n        print(\"\\(bar)\")\n    }\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForArgument() {
        let input = "func foo(bar: Int) { self.bar = bar }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForLocalVariable() {
        let input = "func foo() { var bar = self.bar }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForCommaDelimitedLocalVariables() {
        let input = "func foo() { let foo = self.foo, bar = self.bar }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForCommaDelimitedLocalVariables2() {
        let input = "func foo() {\n    let foo: Foo, bar: Bar\n    foo = self.foo\n    bar = self.bar\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForTupleAssignedVariables() {
        let input = "func foo() { let (foo, bar) = (self.foo, self.bar) }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForTupleAssignedVariablesFollowedByRegularVariable() {
        let input = "func foo() {\n    let (foo, bar) = (self.foo, self.bar), baz = self.baz\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForTupleAssignedVariablesFollowedByRegularLet() {
        let input = "func foo() {\n    let (foo, bar) = (self.foo, self.bar)\n    let baz = self.baz\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveNonRedundantNestedFunctionSelf() {
        let input = "func foo() { func bar() { self.bar() } }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveNonRedundantNestedFunctionSelf2() {
        let input = "func foo() {\n    func bar() {}\n    self.bar()\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveNonRedundantNestedFunctionSelf3() {
        let input = "func foo() { let bar = 5; func bar() { self.bar = bar } }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveClosureSelf() {
        let input = "func foo() { bar { self.bar = 5 } }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfAfterOptionalReturn() {
        let input = "func foo() -> String? {\n    var index = startIndex\n    if !matching(self[index]) {\n        break\n    }\n    index = self.index(after: index)\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveRequiredSelfInExtensions() {
        let input = "extension Foo {\n    func foo() {\n        var index = 5\n        if true {\n            break\n        }\n        index = self.index(after: index)\n    }\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfBeforeInit() {
        let input = "convenience init() { self.init(5) }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfInsideSwitch() {
        let input = "func foo() {\n    switch self.bar {\n    case .foo:\n        self.baz()\n    }\n}"
        let output = "func foo() {\n    switch bar {\n    case .foo:\n        baz()\n    }\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfInsideSwitchWhere() {
        let input = "func foo() {\n    switch self.bar {\n    case .foo where a == b:\n        self.baz()\n    }\n}"
        let output = "func foo() {\n    switch bar {\n    case .foo where a == b:\n        baz()\n    }\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfInsideSwitchWhereAs() {
        let input = "func foo() {\n    switch self.bar {\n    case .foo where a == b as C:\n        self.baz()\n    }\n}"
        let output = "func foo() {\n    switch bar {\n    case .foo where a == b as C:\n        baz()\n    }\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfInsideClassInit() {
        let input = "class Foo {\n    var bar = 5\n    init() { self.bar = 6 }\n}"
        let output = "class Foo {\n    var bar = 5\n    init() { bar = 6 }\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInClosureInsideIf() {
        let input = "if foo { bar { self.baz() } }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForErrorInCatch() {
        let input = "do {} catch { self.error = error }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForNewValueInSet() {
        let input = "var foo: Int { set { self.newValue = newValue } get { return 0 } }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForCustomNewValueInSet() {
        let input = "var foo: Int { set(n00b) { self.n00b = n00b } get { return 0 } }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForNewValueInWillSet() {
        let input = "var foo: Int { willSet { self.newValue = newValue } }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForCustomNewValueInWillSet() {
        let input = "var foo: Int { willSet(n00b) { self.n00b = n00b } }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForOldValueInDidSet() {
        let input = "var foo: Int { didSet { self.oldValue = oldValue } }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForCustomOldValueInDidSet() {
        let input = "var foo: Int { didSet(oldz) { self.oldz = oldz } }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForIndexVarInFor() {
        let input = "for foo in bar { self.foo = foo }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForKeyValueTupleInFor() {
        let input = "for (foo, bar) in baz { self.foo = foo; self.bar = bar }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfFromComputedVar() {
        let input = "var foo: Int { return self.bar }"
        let output = "var foo: Int { return bar }"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfFromOptionalComputedVar() {
        let input = "var foo: Int? { return self.bar }"
        let output = "var foo: Int? { return bar }"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfFromNamespacedComputedVar() {
        let input = "var foo: Swift.String { return self.bar }"
        let output = "var foo: Swift.String { return bar }"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfFromGenericComputedVar() {
        let input = "var foo: Foo<Int> { return self.bar }"
        let output = "var foo: Foo<Int> { return bar }"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfFromComputedArrayVar() {
        let input = "var foo: [Int] { return self.bar }"
        let output = "var foo: [Int] { return bar }"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfFromVarSetter() {
        let input = "var foo: Int { didSet { self.bar() } }"
        let output = "var foo: Int { didSet { bar() } }"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfFromVarClosure() {
        let input = "var foo = { self.bar }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfFromLazyVar() {
        let input = "lazy var foo = self.bar"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfFromLazyVar() {
        let input = "lazy var foo = self.bar"
        let output = "lazy var foo = bar"
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoRemoveSelfFromLazyVarImmediatelyAfterOtherVar() {
        let input = """
        var baz = bar
        lazy var foo = self.bar
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfFromLazyVarImmediatelyAfterOtherVar() {
        let input = """
        var baz = bar
        lazy var foo = self.bar
        """
        let output = """
        var baz = bar
        lazy var foo = bar
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoRemoveSelfFromLazyVarClosure() {
        let input = "lazy var foo = { self.bar }()"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfFromLazyVarClosure2() {
        let input = "lazy var foo = { let bar = self.baz }()"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfFromLazyVarClosure3() {
        let input = "lazy var foo = { [unowned self] in let bar = self.baz }()"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfFromVarInFuncWithUnusedArgument() {
        let input = "func foo(bar _: Int) { self.baz = 5 }"
        let output = "func foo(bar _: Int) { baz = 5 }"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfFromVarMatchingUnusedArgument() {
        let input = "func foo(bar _: Int) { self.bar = 5 }"
        let output = "func foo(bar _: Int) { bar = 5 }"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfFromVarMatchingRenamedArgument() {
        let input = "func foo(bar baz: Int) { self.baz = baz }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfFromVarRedeclaredInSubscope() {
        let input = "func foo() {\n    if quux {\n        let bar = 5\n    }\n    let baz = self.bar\n}"
        let output = "func foo() {\n    if quux {\n        let bar = 5\n    }\n    let baz = bar\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfFromVarDeclaredLaterInScope() {
        let input = "func foo() {\n    let bar = self.baz\n    let baz = quux\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfFromVarDeclaredLaterInOuterScope() {
        let input = "func foo() {\n    if quux {\n        let bar = self.baz\n    }\n    let baz = 6\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInWhilePreceededByVarDeclaration() {
        let input = "var index = start\nwhile index < end {\n    index = self.index(after: index)\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInLocalVarPrecededByLocalVarFollowedByIfComma() {
        let input = "func foo() {\n    let bar = Bar()\n    let baz = Baz()\n    self.baz = baz\n    if let bar = bar, bar > 0 {}\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInLocalVarPrecededByIfLetContainingClosure() {
        let input = "func foo() {\n    if let bar = 5 { baz { _ in } }\n    let quux = self.quux\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForVarCreatedInGuardScope() {
        let input = "func foo() {\n    guard let bar = 5 else {}\n    let baz = self.bar\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfForVarCreatedInIfScope() {
        let input = "func foo() {\n    if let bar = bar {}\n    let baz = self.bar\n}"
        let output = "func foo() {\n    if let bar = bar {}\n    let baz = bar\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForVarDeclaredInWhileCondition() {
        let input = "while let foo = bar { self.foo = foo }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfForVarNotDeclaredInWhileCondition() {
        let input = "while let foo == bar { self.baz = 5 }"
        let output = "while let foo == bar { baz = 5 }"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForVarDeclaredInSwitchCase() {
        let input = "switch foo {\ncase bar: let baz = self.baz\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfAfterGenericInit() {
        let input = "init(bar: Int) {\n    self = Foo<Bar>()\n    self.bar(bar)\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfInClassFunction() {
        let input = "class Foo {\n    class func foo() {\n        func bar() { self.foo() }\n    }\n}"
        let output = "class Foo {\n    class func foo() {\n        func bar() { foo() }\n    }\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfInStaticFunction() {
        let input = "struct Foo {\n    static func foo() {\n        func bar() { self.foo() }\n    }\n}"
        let output = "struct Foo {\n    static func foo() {\n        func bar() { foo() }\n    }\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfInClassFunctionWithSpecifiers() {
        let input = "class Foo {\n    class private func foo() {\n        func bar() { self.foo() }\n    }\n}"
        let output = "class Foo {\n    class private func foo() {\n        func bar() { foo() }\n    }\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, exclude: ["specifiers"])
    }

    func testNoRemoveSelfInClassFunction() {
        let input = "class Foo {\n    class func foo() {\n        var foo: Int\n        func bar() { self.foo() }\n    }\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForVarDeclaredAfterRepeatWhile() {
        let input = "class Foo {\n    let foo = 5\n    func bar() {\n        repeat {} while foo\n        let foo = 6\n        self.foo()\n    }\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForVarInClosureAfterRepeatWhile() {
        let input = "class Foo {\n    let foo = 5\n    func bar() {\n        repeat {} while foo\n        ({ self.foo() })()\n    }\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInClosureAfterVar() {
        let input = "var foo: String\nbar { self.baz() }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInClosureAfterNamespacedVar() {
        let input = "var foo: Swift.String\nbar { self.baz() }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInClosureAfterOptionalVar() {
        let input = "var foo: String?\nbar { self.baz() }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInClosureAfterGenericVar() {
        let input = "var foo: Foo<Int>\nbar { self.baz() }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInClosureAfterArray() {
        let input = "var foo: [Int]\nbar { self.baz() }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInExpectFunction() { // Special case to support the Nimble framework
        let input = """
        class FooTests: XCTestCase {
            let foo = 1
            func testFoo() {
                expect(self.foo) == 1
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInExcludedFunction() {
        let input = """
        class Foo {
            let foo = 1
            func testFoo() {
                log(self.foo)
            }
        }
        """
        let options = FormatOptions(selfRequired: ["log"])
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoMistakeProtocolClassSpecifierForClassFunction() {
        let input = "protocol Foo: class {}\nfunc bar() {}"
        XCTAssertNoThrow(try format(input, rules: [FormatRules.redundantSelf]))
        XCTAssertNoThrow(try format(input, rules: FormatRules.all))
    }

    func testSelfRemovedFromSwitchCaseWhere() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let foo where self.bar.baz:
                    return self.bar
                default:
                    return nil
                }
            }
        }
        """
        let output = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let foo where bar.baz:
                    return bar
                default:
                    return nil
                }
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testSwitchCaseLetVarRecognized() {
        let input = """
        switch foo {
        case .bar:
            baz = nil
        case let baz:
            self.baz = baz
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testSwitchCaseHoistedLetVarRecognized() {
        let input = """
        switch foo {
        case .bar:
            baz = nil
        case let .foo(baz):
            self.baz = baz
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testSwitchCaseWhereMemberNotTreatedAsVar() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let bar where self.bar.baz:
                    return self.bar
                default:
                    return nil
                }
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testSelfNotRemovedInClosureAfterSwitch() {
        let input = """
        switch x {
        default:
            break
        }
        let foo = { y in
            switch y {
            default:
                self.bar()
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testSelfNotRemovedInClosureInCaseWithWhereClause() {
        let input = """
        switch foo {
        case bar where baz:
            quux = { self.foo }
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testSelfRemovedInDidSet() {
        let input = """
        class Foo {
            var bar: Bool = false {
                didSet {
                    self.bar = !self.bar
                }
            }
        }
        """
        let output = """
        class Foo {
            var bar: Bool = false {
                didSet {
                    bar = !bar
                }
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testSelfNotRemovedInGetter() {
        let input = """
        class Foo {
            var bar: Int {
                return self.bar
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testSelfNotRemovedInIfdef() {
        let input = """
        func foo() {
            #if os(macOS)
                let bar = self.bar
            #endif
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testRedundantSelfRemovedWhenFollowedBySwitchContainingIfdef() {
        let input = """
        struct Foo {
            func bar() {
                self.method(self.value)
                switch x {
                #if BAZ
                    case .baz:
                        break
                #endif
                default:
                    break
                }
            }
        }
        """
        let output = """
        struct Foo {
            func bar() {
                method(value)
                switch x {
                #if BAZ
                    case .baz:
                        break
                #endif
                default:
                    break
                }
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRedundantSelfRemovedInsideConditionalCase() {
        let input = """
        struct Foo {
            func bar() {
                let method2 = () -> Void
                switch x {
                #if BAZ
                    case .baz:
                        self.method1(self.value)
                #else
                    case .quux:
                        self.method2(self.value)
                #endif
                default:
                    break
                }
            }
        }
        """
        let output = """
        struct Foo {
            func bar() {
                let method2 = () -> Void
                switch x {
                #if BAZ
                    case .baz:
                        method1(value)
                #else
                    case .quux:
                        self.method2(value)
                #endif
                default:
                    break
                }
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRedundantSelfDoesntGetStuckIfNoParensFound() {
        let input = "init<T>_ foo: T {}"
        testFormatting(for: input, rule: FormatRules.redundantSelf,
                       exclude: ["spaceAroundOperators"])
    }

    func testNoRemoveSelfInIfLetSelf() {
        let input = """
        func foo() {
            if let self = self as? Foo {
                self.bar()
            }
            self.bar()
        }
        """
        let output = """
        func foo() {
            if let self = self as? Foo {
                self.bar()
            }
            bar()
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInIfLetEscapedSelf() {
        let input = """
        func foo() {
            if let `self` = self as? Foo {
                self.bar()
            }
            self.bar()
        }
        """
        let output = """
        func foo() {
            if let `self` = self as? Foo {
                self.bar()
            }
            bar()
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfAfterGuardLetSelf() {
        let input = """
        func foo() {
            guard let self = self as? Foo else {
                return
            }
            self.bar()
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInClosureInIfCondition() {
        let input = """
        class Foo {
            func foo() {
                if bar({ self.baz() }) {}
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInTrailingClosureInVarAssignment() {
        let input = """
        func broken() {
            var bad = abc {
                self.foo()
                self.bar
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testSelfNotRemovedWhenPropertyIsKeyword() {
        let input = """
        class Foo {
            let `default` = 5
            func foo() {
                print(self.default)
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testSelfNotRemovedWhenPropertyIsContextualKeyword() {
        let input = """
        class Foo {
            let `self` = 5
            func foo() {
                print(self.self)
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testSelfRemovedForContextualKeywordThatRequiresNoEscaping() {
        let input = """
        class Foo {
            let get = 5
            func foo() {
                print(self.get)
            }
        }
        """
        let output = """
        class Foo {
            let get = 5
            func foo() {
                print(get)
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfForMemberNamedLazy() {
        let input = "func foo() { self.lazy() }"
        let output = "func foo() { lazy() }"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveRedundantSelfInArrayLiteral() {
        let input = """
        class Foo {
            func foo() {
                print([self.bar.x, self.bar.y])
            }
        }
        """
        let output = """
        class Foo {
            func foo() {
                print([bar.x, bar.y])
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveRedundantSelfInArrayLiteralVar() {
        let input = """
        class Foo {
            func foo() {
                var bars = [self.bar.x, self.bar.y]
                print(bars)
            }
        }
        """
        let output = """
        class Foo {
            func foo() {
                var bars = [bar.x, bar.y]
                print(bars)
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveRedundantSelfInGuardLet() {
        let input = """
        class Foo {
            func foo() {
                guard let bar = self.baz else {
                    return
                }
            }
        }
        """
        let output = """
        class Foo {
            func foo() {
                guard let bar = baz else {
                    return
                }
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testSelfNotRemovedInClosureInIf() {
        let input = """
        if let foo = bar(baz: { [weak self] in
            guard let self = self else { return }
            _ = self.myVar
        }) {}
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    // explicitSelf = .insert

    func testInsertSelf() {
        let input = "class Foo {\n    let foo: Int\n    init() { foo = 5 }\n}"
        let output = "class Foo {\n    let foo: Int\n    init() { self.foo = 5 }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testInsertSelfAfterReturn() {
        let input = "class Foo {\n    let foo: Int\n    func bar() -> Int { return foo }\n}"
        let output = "class Foo {\n    let foo: Int\n    func bar() -> Int { return self.foo }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testInsertSelfInsideStringInterpolation() {
        let input = "class Foo {\n    var bar: String?\n    func baz() {\n        print(\"\\(bar)\")\n    }\n}"
        let output = "class Foo {\n    var bar: String?\n    func baz() {\n        print(\"\\(self.bar)\")\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInterpretGenericTypesAsMembers() {
        let input = "class Foo {\n    let foo: Bar<Int, Int>\n    init() { self.foo = Int(5) }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testInsertSelfForStaticMemberInClassFunction() {
        let input = "class Foo {\n    static var foo: Int\n    class func bar() { foo = 5 }\n}"
        let output = "class Foo {\n    static var foo: Int\n    class func bar() { self.foo = 5 }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfForInstanceMemberInClassFunction() {
        let input = "class Foo {\n    var foo: Int\n    class func bar() { foo = 5 }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfForStaticMemberInInstanceFunction() {
        let input = "class Foo {\n    static var foo: Int\n    func bar() { foo = 5 }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfForShadowedClassMemberInClassFunction() {
        let input = "class Foo {\n    class func foo() {\n        var foo: Int\n        func bar() { foo = 5 }\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfInForLoopTuple() {
        let input = "class Foo {\n    var bar: Int\n    func foo() { for (bar, baz) in quux {} }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfForTupleTypeMembers() {
        let input = "class Foo {\n    var foo: (Int, UIColor) {\n        let bar = UIColor.red\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfForArrayElements() {
        let input = "class Foo {\n    var foo = [1, 2, nil]\n    func bar() { baz(nil) }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfForNestedVarReference() {
        let input = "class Foo {\n    func bar() {\n        var bar = 5\n        repeat { bar = 6 } while true\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfInSwitchCaseLet() {
        let input = "class Foo {\n    var foo: Bar? {\n        switch bar {\n        case let .baz(foo, _):\n            return nil\n        }\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfInFuncAfterImportedClass() {
        let input = "import class Foo.Bar\nfunc foo() {\n    var bar = 5\n    if true {\n        bar = 6\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfForSubscriptGetSet() {
        let input = "class Foo {\n    func get() {}\n    func set() {}\n    subscript(key: String) -> String {\n        get { return get(key) }\n        set { set(key, newValue) }\n    }\n}"
        let output = "class Foo {\n    func get() {}\n    func set() {}\n    subscript(key: String) -> String {\n        get { return self.get(key) }\n        set { self.set(key, newValue) }\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfInIfCaseLet() {
        let input = "enum Foo {\n    case bar(Int)\n    var value: Int? {\n        if case let .bar(value) = self { return value }\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfForPatternLet() {
        let input = "class Foo {\n    func foo() {}\n    func bar() {\n        switch x {\n        case .bar(let foo, var bar): print(foo + bar)\n        }\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfForPatternLet2() {
        let input = "class Foo {\n    func foo() {}\n    func bar() {\n        switch x {\n        case let .foo(baz): print(baz)\n        case .bar(let foo, var bar): print(foo + bar)\n        }\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfForTypeOf() {
        let input = "class Foo {\n    var type: String?\n    func bar() {\n        print(\"\\(type(of: self))\")\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfForConditionalLocal() {
        let input = "class Foo {\n    func foo() {\n        #if os(watchOS)\n            var foo: Int\n        #else\n            var foo: Float\n        #endif\n        print(foo)\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testInsertSelfInExtension() {
        let input = """
        struct Foo {
            var bar = 5
        }

        extension Foo {
            func baz() {
                bar = 6
            }
        }
        """
        let output = """
        struct Foo {
            var bar = 5
        }

        extension Foo {
            func baz() {
                self.bar = 6
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testGlobalAfterTypeNotTreatedAsMember() {
        let input = """
        struct Foo {
            var foo = 1
        }

        var bar = 5

        extension Foo {
            func baz() {
                bar = 6
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testForWhereVarNotTreatedAsMember() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                for bar in self where bar.baz {
                    return bar
                }
                return nil
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testSwitchCaseWhereVarNotTreatedAsMember() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let bar where bar.baz:
                    return bar
                default:
                    return nil
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testSwitchCaseVarDoesntLeak() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let bar:
                    return bar
                default:
                    return bar
                }
            }
        }
        """
        let output = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let bar:
                    return bar
                default:
                    return self.bar
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testSelfInsertedInSwitchCaseLet() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let foo:
                    return bar
                default:
                    return bar
                }
            }
        }
        """
        let output = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let foo:
                    return self.bar
                default:
                    return self.bar
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testSelfInsertedInSwitchCaseWhere() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let foo where bar.baz:
                    return bar
                default:
                    return bar
                }
            }
        }
        """
        let output = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let foo where self.bar.baz:
                    return self.bar
                default:
                    return self.bar
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testSelfInsertedInDidSet() {
        let input = """
        class Foo {
            var bar: Bool = false {
                didSet {
                    bar = !bar
                }
            }
        }
        """
        let output = """
        class Foo {
            var bar: Bool = false {
                didSet {
                    self.bar = !self.bar
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testSelfInsertedAfterLet() {
        let input = """
        struct Foo {
            let foo = "foo"
            func bar() {
                let x = foo
                baz(x)
            }

            func baz(_: String) {}
        }
        """
        let output = """
        struct Foo {
            let foo = "foo"
            func bar() {
                let x = self.foo
                self.baz(x)
            }

            func baz(_: String) {}
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testSelfNotInsertedInParameterNames() {
        let input = """
        class Foo {
            let a: String

            func bar() {
                foo(a: a)
            }
        }
        """
        let output = """
        class Foo {
            let a: String

            func bar() {
                foo(a: self.a)
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testSelfNotInsertedInCaseLet() {
        let input = """
        class Foo {
            let a: String?
            let b: String

            func bar() {
                if case let .some(a) = self.a, case var .some(b) = self.b {}
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testSelfNotInsertedInCaseLet2() {
        let input = """
        class Foo {
            let a: String?
            let b: String

            func baz() {
                if case let .foos(a, b) = foo, case let .bars(a, b) = bar {}
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testSelfInsertedInTupleAssignment() {
        let input = """
        class Foo {
            let a: String?
            let b: String

            func bar() {
                (a, b) = ("foo", "bar")
            }
        }
        """
        let output = """
        class Foo {
            let a: String?
            let b: String

            func bar() {
                (self.a, self.b) = ("foo", "bar")
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testSelfNotInsertedInTupleAssignment() {
        let input = """
        class Foo {
            let a: String?
            let b: String

            func bar() {
                let (a, b) = (self.a, self.b)
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testInsertSelfForMemberNamedLazy() {
        let input = """
        class Foo {
            var lazy = "foo"
            func foo() {
                print(lazy)
            }
        }
        """
        let output = """
        class Foo {
            var lazy = "foo"
            func foo() {
                print(self.lazy)
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    // explicitSelf = .initOnly

    func testPreserveSelfInsideClassInit() {
        let input = """
        class Foo {
            var bar = 5
            init() {
                self.bar = 6
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testRemoveSelfIfNotInsideClassInit() {
        let input = """
        class Foo {
            var bar = 5
            func baz() {
                self.bar = 6
            }
        }
        """
        let output = """
        class Foo {
            var bar = 5
            func baz() {
                bar = 6
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testInsertSelfInsideClassInit() {
        let input = """
        class Foo {
            var bar = 5
            init() {
                bar = 6
            }
        }
        """
        let output = """
        class Foo {
            var bar = 5
            init() {
                self.bar = 6
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfInsideClassInitIfNotLvalue() {
        let input = """
        class Foo {
            var bar = 5
            let baz = 6
            init() {
                bar = baz
            }
        }
        """
        let output = """
        class Foo {
            var bar = 5
            let baz = 6
            init() {
                self.bar = baz
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testRemoveSelfInsideClassInitIfNotLvalue() {
        let input = """
        class Foo {
            var bar = 5
            let baz = 6
            init() {
                self.bar = self.baz
            }
        }
        """
        let output = """
        class Foo {
            var bar = 5
            let baz = 6
            init() {
                self.bar = baz
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testSelfDotTypeInsideClassInitEdgeCase() {
        let input = """
        class Foo {
            let type: Int

            init() {
                self.type = 5
            }

            func baz() {
                switch type {}
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testSelfInsertedInTupleInInit() {
        let input = """
        class Foo {
            let a: String?
            let b: String

            init() {
                (a, b) = ("foo", "bar")
            }
        }
        """
        let output = """
        class Foo {
            let a: String?
            let b: String

            init() {
                (self.a, self.b) = ("foo", "bar")
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testSelfInsertedAfterLetInInit() {
        let input = """
        class Foo {
            var foo: String
            init(bar: Bar) {
                let baz = bar.quux
                foo = baz
            }
        }
        """
        let output = """
        class Foo {
            var foo: String
            init(bar: Bar) {
                let baz = bar.quux
                self.foo = baz
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    // enable/disable

    func testDisableRemoveSelf() {
        let input = """
        class Foo {
            var bar: Int
            func baz() {
                // swiftformat:disable redundantSelf
                self.bar = 1
                // swiftformat:enable redundantSelf
                self.bar = 2
            }
        }
        """
        let output = """
        class Foo {
            var bar: Int
            func baz() {
                // swiftformat:disable redundantSelf
                self.bar = 1
                // swiftformat:enable redundantSelf
                bar = 2
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testDisableNextRemoveSelf() {
        let input = """
        class Foo {
            var bar: Int
            func baz() {
                // swiftformat:disable:next redundantSelf
                self.bar = 1
                self.bar = 2
            }
        }
        """
        let output = """
        class Foo {
            var bar: Int
            func baz() {
                // swiftformat:disable:next redundantSelf
                self.bar = 1
                bar = 2
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testMultilineDisableRemoveSelf() {
        let input = """
        class Foo {
            var bar: Int
            func baz() {
                /* swiftformat:disable redundantSelf */ self.bar = 1 /* swiftformat:enable all */
                self.bar = 2
            }
        }
        """
        let output = """
        class Foo {
            var bar: Int
            func baz() {
                /* swiftformat:disable redundantSelf */ self.bar = 1 /* swiftformat:enable all */
                bar = 2
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testMultilineDisableNextRemoveSelf() {
        let input = """
        class Foo {
            var bar: Int
            func baz() {
                /* swiftformat:disable:next redundantSelf */
                self.bar = 1
                self.bar = 2
            }
        }
        """
        let output = """
        class Foo {
            var bar: Int
            func baz() {
                /* swiftformat:disable:next redundantSelf */
                self.bar = 1
                bar = 2
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    // MARK: - unusedArguments

    // closures

    func testUnusedTypedClosureArguments() {
        let input = "let foo = { (bar: Int, baz: String) in\n    print(\"Hello \\(baz)\")\n}"
        let output = "let foo = { (_: Int, baz: String) in\n    print(\"Hello \\(baz)\")\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testUnusedUntypedClosureArguments() {
        let input = "let foo = { bar, baz in\n    print(\"Hello \\(baz)\")\n}"
        let output = "let foo = { _, baz in\n    print(\"Hello \\(baz)\")\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testNoRemoveClosureReturnType() {
        let input = "let foo = { () -> Foo.Bar in baz() }"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testNoRemoveClosureThrows() {
        let input = "let foo = { () throws in }"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testNoRemoveClosureGenericReturnTypes() {
        let input = "let foo = { () -> Promise<String> in bar }"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testNoRemoveClosureTupleReturnTypes() {
        let input = "let foo = { () -> (Int, Int) in (5, 6) }"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testNoRemoveClosureGenericArgumentTypes() {
        let input = "let foo = { (_: Foo<Bar, Baz>) in }"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testNoRemoveFunctionNameBeforeForLoop() {
        let input = "{\n    func foo() -> Int {}\n    for a in b {}\n}"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testClosureTypeInClosureArgumentsIsNotMangled() {
        let input = "{ (foo: (Int) -> Void) in }"
        let output = "{ (_: (Int) -> Void) in }"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testUnusedUnnamedClosureArguments() {
        let input = "{ (_ foo: Int, _ bar: Int) in }"
        let output = "{ (_: Int, _: Int) in }"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testUnusedInoutClosureArgumentsNotMangled() {
        let input = "{ (foo: inout Foo, bar: inout Bar) in }"
        let output = "{ (_: inout Foo, _: inout Bar) in }"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testMalformedFunctionNotMisidentifiedAsClosure() {
        let input = "func foo() { bar(5) {} in }"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    // functions

    func testMarkUnusedFunctionArgument() {
        let input = "func foo(bar: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        let output = "func foo(bar _: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testMarkUnusedArgumentsInNonVoidFunction() {
        let input = "func foo(bar: Int, baz: String) -> (A<B, C>, D & E, [F: G]) { return baz.quux }"
        let output = "func foo(bar _: Int, baz: String) -> (A<B, C>, D & E, [F: G]) { return baz.quux }"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testMarkUnusedArgumentsInThrowsFunction() {
        let input = "func foo(bar: Int, baz: String) throws {\n    print(\"Hello \\(baz)\")\n}"
        let output = "func foo(bar _: Int, baz: String) throws {\n    print(\"Hello \\(baz)\")\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testMarkUnusedArgumentsInOptionalReturningFunction() {
        let input = "func foo(bar: Int, baz: String) -> String? {\n    return \"Hello \\(baz)\"\n}"
        let output = "func foo(bar _: Int, baz: String) -> String? {\n    return \"Hello \\(baz)\"\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testNoMarkUnusedArgumentsInProtocolFunction() {
        let input = "protocol Foo {\n    func foo(bar: Int) -> Int\n    var bar: Int { get }\n}"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testUnusedUnnamedFunctionArgument() {
        let input = "func foo(_ foo: Int) {}"
        let output = "func foo(_: Int) {}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testUnusedInoutFunctionArgumentIsNotMangled() {
        let input = "func foo(_ foo: inout Foo) {}"
        let output = "func foo(_: inout Foo) {}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testUnusedInternallyRenamedFunctionArgument() {
        let input = "func foo(foo bar: Int) {}"
        let output = "func foo(foo _: Int) {}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testNoMarkProtocolFunctionArgument() {
        let input = "func foo(foo bar: Int)\nvar bar: Bool { get }"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testMembersAreNotArguments() {
        let input = "func foo(bar: Int, baz: String) {\n    print(\"Hello \\(bar.baz)\")\n}"
        let output = "func foo(bar: Int, baz _: String) {\n    print(\"Hello \\(bar.baz)\")\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testLabelsAreNotArguments() {
        let input = "func foo(bar: Int, baz: String) {\n    bar: while true { print(baz) }\n}"
        let output = "func foo(bar _: Int, baz: String) {\n    bar: while true { print(baz) }\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testDictionaryLiteralsRuinEverything() {
        let input = "func foo(bar: Int, baz: Int) {\n    let quux = [bar: 1, baz: 2]\n}"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testOperatorArgumentsAreUnnamed() {
        let input = "func == (lhs: Int, rhs: Int) { return false }"
        let output = "func == (_: Int, _: Int) { return false }"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testUnusedtFailableInitArgumentsAreNotMangled() {
        let input = "init?(foo: Bar) {}"
        let output = "init?(foo _: Bar) {}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testTreatEscapedArgumentsAsUsed() {
        let input = "func foo(default: Int) -> Int {\n    return `default`\n}"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testPartiallyMarkedUnusedArguments() {
        let input = "func foo(bar: Bar, baz _: Baz) {}"
        let output = "func foo(bar _: Bar, baz _: Baz) {}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testPartiallyMarkedUnusedArguments2() {
        let input = "func foo(bar _: Bar, baz: Baz) {}"
        let output = "func foo(bar _: Bar, baz _: Baz) {}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    // functions (closure-only)

    func testNoMarkFunctionArgument() {
        let input = "func foo(_ bar: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        let options = FormatOptions(stripUnusedArguments: .closureOnly)
        testFormatting(for: input, rule: FormatRules.unusedArguments, options: options)
    }

    // functions (unnamed-only)

    func testNoMarkNamedFunctionArgument() {
        let input = "func foo(bar: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        let options = FormatOptions(stripUnusedArguments: .unnamedOnly)
        testFormatting(for: input, rule: FormatRules.unusedArguments, options: options)
    }

    func testRemoveUnnamedFunctionArgument() {
        let input = "func foo(_ foo: Int) {}"
        let output = "func foo(_: Int) {}"
        let options = FormatOptions(stripUnusedArguments: .unnamedOnly)
        testFormatting(for: input, output, rule: FormatRules.unusedArguments, options: options)
    }

    func testNoRemoveInternalFunctionArgumentName() {
        let input = "func foo(foo bar: Int) {}"
        let options = FormatOptions(stripUnusedArguments: .unnamedOnly)
        testFormatting(for: input, rule: FormatRules.unusedArguments, options: options)
    }

    // init

    func testMarkUnusedInitArgument() {
        let input = "init(bar: Int, baz: String) {\n    self.baz = baz\n}"
        let output = "init(bar _: Int, baz: String) {\n    self.baz = baz\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    // subscript

    func testMarkUnusedSubscriptArgument() {
        let input = "subscript(foo: Int, baz: String) -> String {\n    return get(baz)\n}"
        let output = "subscript(_: Int, baz: String) -> String {\n    return get(baz)\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testMarkUnusedUnnamedSubscriptArgument() {
        let input = "subscript(_ foo: Int, baz: String) -> String {\n    return get(baz)\n}"
        let output = "subscript(_: Int, baz: String) -> String {\n    return get(baz)\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testMarkUnusedNamedSubscriptArgument() {
        let input = "subscript(foo foo: Int, baz: String) -> String {\n    return get(baz)\n}"
        let output = "subscript(foo _: Int, baz: String) -> String {\n    return get(baz)\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    // MARK: - hoistPatternLet

    // hoist = true

    func testHoistCaseLet() {
        let input = "if case .foo(let bar, let baz) = quux {}"
        let output = "if case let .foo(bar, baz) = quux {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testHoistLabelledCaseLet() {
        let input = "if case .foo(bar: let bar, baz: let baz) = quux {}"
        let output = "if case let .foo(bar: bar, baz: baz) = quux {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testHoistCaseVar() {
        let input = "if case .foo(var bar, var baz) = quux {}"
        let output = "if case var .foo(bar, baz) = quux {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testNoHoistMixedCaseLetVar() {
        let input = "if case .foo(let bar, var baz) = quux {}"
        testFormatting(for: input, rule: FormatRules.hoistPatternLet)
    }

    func testNoHoistIfFirstArgSpecified() {
        let input = "if case .foo(bar, let baz) = quux {}"
        testFormatting(for: input, rule: FormatRules.hoistPatternLet)
    }

    func testNoHoistIfLastArgSpecified() {
        let input = "if case .foo(let bar, baz) = quux {}"
        testFormatting(for: input, rule: FormatRules.hoistPatternLet)
    }

    func testHoistIfArgIsNumericLiteral() {
        let input = "if case .foo(5, let baz) = quux {}"
        let output = "if case let .foo(5, baz) = quux {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testHoistIfArgIsEnumCaseLiteral() {
        let input = "if case .foo(.bar, let baz) = quux {}"
        let output = "if case let .foo(.bar, baz) = quux {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testHoistIfArgIsNamespacedEnumCaseLiteralInParens() {
        let input = "switch foo {\ncase (Foo.bar(let baz)):\n}"
        let output = "switch foo {\ncase let (Foo.bar(baz)):\n}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, exclude: ["redundantParens"])
    }

    func testHoistIfFirstArgIsUnderscore() {
        let input = "if case .foo(_, let baz) = quux {}"
        let output = "if case let .foo(_, baz) = quux {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testHoistIfSecondArgIsUnderscore() {
        let input = "if case .foo(let baz, _) = quux {}"
        let output = "if case let .foo(baz, _) = quux {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testNestedHoistLet() {
        let input = "if case (.foo(let a, let b), .bar(let c, let d)) = quux {}"
        let output = "if case let (.foo(a, b), .bar(c, d)) = quux {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testHoistCommaSeparatedSwitchCaseLets() {
        let input = "switch foo {\ncase .foo(let bar), .bar(let bar):\n}"
        let output = "switch foo {\ncase let .foo(bar), let .bar(bar):\n}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testHoistCatchLet() {
        let input = "do {} catch Foo.foo(bar: let bar) {}"
        let output = "do {} catch let Foo.foo(bar: bar) {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testNoNestedHoistLetWithSpecifiedArgs() {
        let input = "if case (.foo(let a, b), .bar(let c, d)) = quux {}"
        testFormatting(for: input, rule: FormatRules.hoistPatternLet)
    }

    func testNoHoistClosureVariables() {
        let input = "foo({ let bar = 5 })"
        testFormatting(for: input, rule: FormatRules.hoistPatternLet, exclude: ["trailingClosures"])
    }

    // TODO: this could actually hoist out the let to the next level, but that's tricky
    // to implement without breaking the `testNoOverHoistSwitchCaseWithNestedParens` case
    func testHoistSwitchCaseWithNestedParens() {
        let input = "import Foo\nswitch (foo, bar) {\ncase (.baz(let quux), Foo.bar): break\n}"
        let output = "import Foo\nswitch (foo, bar) {\ncase (let .baz(quux), Foo.bar): break\n}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testNoOverHoistSwitchCaseWithNestedParens() {
        let input = "import Foo\nswitch (foo, bar) {\ncase (.baz(let quux), bar): break\n}"
        let output = "import Foo\nswitch (foo, bar) {\ncase (let .baz(quux), bar): break\n}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testNoHoistLetWithEmptArg() {
        let input = "if .foo(let _) = bar {}"
        testFormatting(for: input, rule: FormatRules.hoistPatternLet,
                       exclude: ["redundantLet", "redundantPattern"])
    }

    func testHoistLetWithNoSpaceAfterCase() {
        let input = "switch x { case.some(let y): return y }"
        let output = "switch x { case let .some(y): return y }"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    // hoist = false

    func testUnhoistCaseLet() {
        let input = "if case let .foo(bar, baz) = quux {}"
        let output = "if case .foo(let bar, let baz) = quux {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testUnhoistLabelledCaseLet() {
        let input = "if case let .foo(bar: bar, baz: baz) = quux {}"
        let output = "if case .foo(bar: let bar, baz: let baz) = quux {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testUnhoistCaseVar() {
        let input = "if case var .foo(bar, baz) = quux {}"
        let output = "if case .foo(var bar, var baz) = quux {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testUnhoistSingleCaseLet() {
        let input = "if case let .foo(bar) = quux {}"
        let output = "if case .foo(let bar) = quux {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testUnhoistIfArgIsEnumCaseLiteral() {
        let input = "if case let .foo(.bar, baz) = quux {}"
        let output = "if case .foo(.bar, let baz) = quux {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testUnhoistIfArgIsEnumCaseLiteralInParens() {
        let input = "switch foo {\ncase let (.bar(baz)):\n}"
        let output = "switch foo {\ncase (.bar(let baz)):\n}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options,
                       exclude: ["redundantParens"])
    }

    func testUnhoistIfArgIsNamespacedEnumCaseLiteral() {
        let input = "switch foo {\ncase let Foo.bar(baz):\n}"
        let output = "switch foo {\ncase Foo.bar(let baz):\n}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testUnhoistIfArgIsNamespacedEnumCaseLiteralInParens() {
        let input = "switch foo {\ncase let (Foo.bar(baz)):\n}"
        let output = "switch foo {\ncase (Foo.bar(let baz)):\n}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options,
                       exclude: ["redundantParens"])
    }

    func testUnhoistIfArgIsUnderscore() {
        let input = "if case let .foo(_, baz) = quux {}"
        let output = "if case .foo(_, let baz) = quux {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testNestedUnhoistLet() {
        let input = "if case let (.foo(a, b), .bar(c, d)) = quux {}"
        let output = "if case (.foo(let a, let b), .bar(let c, let d)) = quux {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testUnhoistCommaSeparatedSwitchCaseLets() {
        let input = "switch foo {\ncase let .foo(bar), let .bar(bar):\n}"
        let output = "switch foo {\ncase .foo(let bar), .bar(let bar):\n}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testUnhoistCommaSeparatedSwitchCaseLets2() {
        let input = "switch foo {\ncase let Foo.foo(bar), let Foo.bar(bar):\n}"
        let output = "switch foo {\ncase Foo.foo(let bar), Foo.bar(let bar):\n}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testUnhoistCatchLet() {
        let input = "do {} catch let Foo.foo(bar: bar) {}"
        let output = "do {} catch Foo.foo(bar: let bar) {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testNoUnhoistTupleLet() {
        let input = "let (bar, baz) = quux()"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testNoUnhoistIfLetTuple() {
        let input = "if let x = y, let (_, a) = z {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testNoUnhoistIfCaseFollowedByLetTuple() {
        let input = "if case .foo = bar, let (foo, bar) = baz {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testNoUnhoistIfArgIsNamespacedEnumCaseLiteralInParens() {
        let input = "switch foo {\ncase (Foo.bar(let baz)):\n}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: FormatRules.hoistPatternLet, options: options,
                       exclude: ["redundantParens"])
    }

    // MARK: - wrap

    func testWrapIfStatement() {
        let input = """
        if let foo = foo, let bar = bar, let baz = baz {}
        """
        let output = """
        if let foo = foo,
            let bar = bar,
            let baz = baz {}
        """
        let options = FormatOptions(maxWidth: 20)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testWrapIfElseStatement() {
        let input = """
        if let foo = foo {} else if let bar = bar {}
        """
        let output = """
        if let foo = foo {}
            else if let bar =
            bar {}
        """
        let output2 = """
        if let foo = foo {}
        else if let bar =
            bar {}
        """
        let options = FormatOptions(maxWidth: 20)
        testFormatting(for: input, [output, output2], rules: [FormatRules.wrap], options: options)
    }

    func testWrapGuardStatement() {
        let input = """
        guard let foo = foo, let bar = bar else {
            break
        }
        """
        let output = """
        guard let foo = foo,
            let bar = bar
            else {
            break
        }
        """
        let output2 = """
        guard let foo = foo,
            let bar = bar
        else {
            break
        }
        """
        let options = FormatOptions(maxWidth: 20)
        testFormatting(for: input, [output, output2], rules: [FormatRules.wrap], options: options)
    }

    func testWrapClosure() {
        let input = """
        let foo = { () -> Bool in true }
        """
        let output = """
        let foo =
            { () -> Bool in
            true }
        """
        let output2 = """
        let foo =
            { () -> Bool in
                true
            }
        """
        let options = FormatOptions(maxWidth: 20)
        testFormatting(for: input, [output, output2], rules: [FormatRules.wrap], options: options)
    }

    func testWrapClosure2() {
        let input = """
        let foo = { bar, _ in bar }
        """
        let output = """
        let foo =
            { bar, _ in
            bar }
        """
        let output2 = """
        let foo =
            { bar, _ in
                bar
            }
        """
        let options = FormatOptions(maxWidth: 20)
        testFormatting(for: input, [output, output2], rules: [FormatRules.wrap], options: options)
    }

    func testWrapClosure3() {
        let input = "let foo = bar { $0.baz }"
        let output = """
        let foo = bar {
            $0.baz }
        """
        let output2 = """
        let foo = bar {
            $0.baz
        }
        """
        let options = FormatOptions(maxWidth: 20)
        testFormatting(for: input, [output, output2], rules: [FormatRules.wrap], options: options)
    }

    func testWrapFunctionIfReturnTypeExceedsMaxWidth() {
        let input = """
        func testFunc() -> ReturnType {
            doSomething()
            doSomething()
        }
        """
        let output = """
        func testFunc()
            -> ReturnType {
            doSomething()
            doSomething()
        }
        """
        let options = FormatOptions(maxWidth: 25)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testWrapFunctionIfReturnTypeExceedsMaxWidthWithXcodeIndentation() {
        let input = """
        func testFunc() -> ReturnType {
            doSomething()
            doSomething()
        }
        """
        let output = """
        func testFunc()
            -> ReturnType {
            doSomething()
            doSomething()
        }
        """
        let output2 = """
        func testFunc()
            -> ReturnType {
                doSomething()
                doSomething()
        }
        """
        let options = FormatOptions(xcodeIndentation: true, maxWidth: 25)
        testFormatting(for: input, [output, output2], rules: [FormatRules.wrap], options: options)
    }

    func testWrapFunctionIfReturnTypeExceedsMaxWidth2() {
        let input = """
        func testFunc() -> (ReturnType, ReturnType2) {
            doSomething()
        }
        """
        let output = """
        func testFunc()
            -> (ReturnType, ReturnType2) {
            doSomething()
        }
        """
        let options = FormatOptions(maxWidth: 35)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testWrapFunctionIfReturnTypeExceedsMaxWidth2WithXcodeIndentation() {
        let input = """
        func testFunc() -> (ReturnType, ReturnType2) {
            doSomething()
        }
        """
        let output = """
        func testFunc()
            -> (ReturnType, ReturnType2) {
            doSomething()
        }
        """
        let output2 = """
        func testFunc()
            -> (ReturnType, ReturnType2) {
                doSomething()
        }
        """
        let options = FormatOptions(xcodeIndentation: true, maxWidth: 35)
        testFormatting(for: input, [output, output2], rules: [FormatRules.wrap], options: options)
    }

    func testWrapFunctionIfReturnTypeExceedsMaxWidth3() {
        let input = """
        func testFunc() -> (Bool, String) -> String? {
            doSomething()
        }
        """
        let output = """
        func testFunc()
            -> (Bool, String) -> String? {
            doSomething()
        }
        """
        let options = FormatOptions(maxWidth: 35)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testWrapFunctionIfReturnTypeExceedsMaxWidth3WithXcodeIndentation() {
        let input = """
        func testFunc() -> (Bool, String) -> String? {
            doSomething()
        }
        """
        let output = """
        func testFunc()
            -> (Bool, String) -> String? {
            doSomething()
        }
        """
        let output2 = """
        func testFunc()
            -> (Bool, String) -> String? {
                doSomething()
        }
        """
        let options = FormatOptions(xcodeIndentation: true, maxWidth: 35)
        testFormatting(for: input, [output, output2], rules: [FormatRules.wrap], options: options)
    }

    func testWrapFunctionIfReturnTypeExceedsMaxWidth4() {
        let input = """
        func testFunc(_: () -> Void) -> (Bool, String) -> String? {
            doSomething()
        }
        """
        let output = """
        func testFunc(_: () -> Void)
            -> (Bool, String) -> String? {
            doSomething()
        }
        """
        let options = FormatOptions(maxWidth: 35)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testWrapFunctionIfReturnTypeExceedsMaxWidth4WithXcodeIndentation() {
        let input = """
        func testFunc(_: () -> Void) -> (Bool, String) -> String? {
            doSomething()
        }
        """
        let output = """
        func testFunc(_: () -> Void)
            -> (Bool, String) -> String? {
            doSomething()
        }
        """
        let output2 = """
        func testFunc(_: () -> Void)
            -> (Bool, String) -> String? {
                doSomething()
        }
        """
        let options = FormatOptions(xcodeIndentation: true, maxWidth: 35)
        testFormatting(for: input, [output, output2], rules: [FormatRules.wrap], options: options)
    }

    func testWrapChainedFunctionAfterSubscriptCollection() {
        let input = """
        let foo = bar["baz"].quuz()
        """
        let output = """
        let foo = bar["baz"]
            .quuz()
        """
        let options = FormatOptions(maxWidth: 20)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testWrapChainedFunctionInSubscriptCollection() {
        let input = """
        let foo = bar[baz.quuz()]
        """
        let output = """
        let foo =
            bar[baz.quuz()]
        """
        let options = FormatOptions(maxWidth: 20)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testWrapThrowingFunctionIfReturnTypeExceedsMaxWidth() {
        let input = """
        func testFunc(_: () -> Void) throws -> (Bool, String) -> String? {
            doSomething()
        }
        """
        let output = """
        func testFunc(_: () -> Void) throws
            -> (Bool, String) -> String? {
            doSomething()
        }
        """
        let options = FormatOptions(maxWidth: 42)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testNoWrapInterpolatedStringLiteral() {
        let input = """
        "a very long \\(string) literal"
        """
        let options = FormatOptions(maxWidth: 20)
        testFormatting(for: input, rule: FormatRules.wrap, options: options)
    }

    func testNoWrapAtUnspacedOperator() {
        let input = "let foo = bar+baz+quux"
        let output = "let foo =\n    bar+baz+quux"
        let options = FormatOptions(maxWidth: 15)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options,
                       exclude: ["spaceAroundOperators"])
    }

    func testNoWrapAtUnspacedEquals() {
        let input = "let foo=bar+baz+quux"
        let options = FormatOptions(maxWidth: 15)
        testFormatting(for: input, rule: FormatRules.wrap, options: options,
                       exclude: ["spaceAroundOperators"])
    }

    func testNoWrapSingleParameter() {
        let input = "let fooBar = try unkeyedContainer.decode(FooBar.self)"
        let output = """
        let fooBar = try unkeyedContainer
            .decode(FooBar.self)
        """
        let options = FormatOptions(maxWidth: 50)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testWrapSingleParameter() {
        let input = "let fooBar = try unkeyedContainer.decode(FooBar.self)"
        let output = """
        let fooBar = try unkeyedContainer.decode(
            FooBar.self
        )
        """
        let options = FormatOptions(maxWidth: 50, noWrapOperators: [".", "="])
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testWrapFunctionArrow() {
        let input = "func foo() -> Int {}"
        let output = """
        func foo()
            -> Int {}
        """
        let options = FormatOptions(maxWidth: 14)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testNoWrapFunctionArrow() {
        let input = "func foo() -> Int {}"
        let output = """
        func foo(
        ) -> Int {}
        """
        let options = FormatOptions(maxWidth: 14, noWrapOperators: ["->"])
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options)
    }

    func testNoCrashWrap() {
        let input = """
        struct Foo {
            func bar(a: Set<B>, c: D) {}
        }
        """
        let output = """
        struct Foo {
            func bar(
                a: Set<
                    B
                >,
                c: D
            ) {}
        }
        """
        let options = FormatOptions(maxWidth: 10)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options,
                       exclude: ["unusedArguments"])
    }

    func testNoCrashWrap2() {
        let input = """
        struct Test {
            func webView(_: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
                authenticationChallengeProcessor.process(challenge: challenge, completionHandler: completionHandler)
            }
        }
        """
        let output = """
        struct Test {
            func webView(
                _: WKWebView,
                didReceive challenge: URLAuthenticationChallenge,
                completionHandler: @escaping (URLSession.AuthChallengeDisposition,
                                              URLCredential?) -> Void
            ) {
                authenticationChallengeProcessor.process(
                    challenge: challenge,
                    completionHandler: completionHandler
                )
            }
        }
        """
        let options = FormatOptions(maxWidth: 80)
        testFormatting(for: input, output, rule: FormatRules.wrap, options: options,
                       exclude: ["indent", "wrapArguments"])
    }

    func testNoCrashWrap3() throws {
        let input = """
        override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
            let context = super.invalidationContext(forBoundsChange: newBounds) as! UICollectionViewFlowLayoutInvalidationContext
            context.invalidateFlowLayoutDelegateMetrics = newBounds.size != collectionView?.bounds.size
            return context
        }
        """
        let options = FormatOptions(wrapArguments: .afterFirst, maxWidth: 100)
        let rules = [FormatRules.wrap, FormatRules.wrapArguments]
        XCTAssertNoThrow(try format(input, rules: rules, options: options))
    }

    // MARK: - wrapArguments

    // MARK: wrapParameters

    func testWrapParametersDoesNotAffectFunctionDeclaration() {
        let input = "foo(\n    bar _: Int,\n    baz _: String\n)"
        let options = FormatOptions(wrapArguments: .preserve, wrapParameters: .afterFirst)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapParametersClosureAfterParameterListDoesNotWrapClosureArguments() {
        let input = """
        func foo() {}
        bar = (baz: 5, quux: 7,
               quuz: 10)
        """
        let options = FormatOptions(wrapArguments: .preserve, wrapParameters: .beforeFirst)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapParametersNotSetWrapArgumentsAfterFirstDefaultsToAfterFirst() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let output = "func foo(bar _: Int,\n         baz _: String) {}"
        let options = FormatOptions(wrapArguments: .afterFirst)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapParametersNotSetWrapArgumentsBeforeFirstDefaultsToBeforeFirst() {
        let input = "func foo(bar _: Int,\n    baz _: String) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapArguments: .beforeFirst)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapParametersNotSetWrapArgumentsPreserveDefaultsToPreserve() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapArguments: .preserve)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    // MARK: preserve

    func testAfterFirstPreserved() {
        let input = "func foo(bar _: Int,\n         baz _: String) {}"
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testAfterFirstPreservedIndentFixed() {
        let input = "func foo(bar _: Int,\n baz _: String) {}"
        let output = "func foo(bar _: Int,\n         baz _: String) {}"
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testAfterFirstPreservedNewlineRemoved() {
        let input = "func foo(bar _: Int,\n         baz _: String\n) {}"
        let output = "func foo(bar _: Int,\n         baz _: String) {}"
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testBeforeFirstPreserved() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testBeforeFirstPreservedIndentFixed() {
        let input = "func foo(\n    bar _: Int,\n baz _: String\n) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testBeforeFirstPreservedNewlineAdded() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testIndentFirstElementWhenApplyingWrap() {
        let input = """
        let foo = Set([
        Thing(),
        Thing(),
        ])
        """
        let output = """
        let foo = Set([
            Thing(),
            Thing(),
        ])
        """
        testFormatting(for: input, output, rule: FormatRules.wrapArguments)
    }

    func testWrapArgumentsDoesntIndentTrailingComment() {
        let input = """
        foo( // foo
        bar: Int
        )
        """
        let output = """
        foo( // foo
            bar: Int
        )
        """
        testFormatting(for: input, output, rule: FormatRules.wrapArguments)
    }

    func testWrapArgumentsDoesntIndentClosingBracket() {
        let input = """
        [
            "foo": [
            ],
        ]
        """
        testFormatting(for: input, rule: FormatRules.wrapArguments)
    }

    // MARK: afterFirst

    func testBeforeFirstConvertedToAfterFirst() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let output = "func foo(bar _: Int,\n         baz _: String) {}"
        let options = FormatOptions(wrapParameters: .afterFirst)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testNoWrapInnerArguments() {
        let input = "func foo(\n    bar _: Int,\n    baz _: foo(bar, baz)\n) {}"
        let output = "func foo(bar _: Int,\n         baz _: foo(bar, baz)) {}"
        let options = FormatOptions(wrapParameters: .afterFirst)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    // MARK: afterFirst, maxWidth

    func testWrapAfterFirstIfMaxLengthExceeded() {
        let input = """
        func foo(bar: Int, baz: String) -> Bool {}
        """
        let output = """
        func foo(bar: Int,
                 baz: String) -> Bool {}
        """
        let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 20)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["unusedArguments", "wrap"])
    }

    func testWrapAfterFirstIfMaxLengthExceeded2() {
        let input = """
        func foo(bar: Int, baz: String, quux: Bool) -> Bool {}
        """
        let output = """
        func foo(bar: Int,
                 baz: String,
                 quux: Bool) -> Bool {}
        """
        let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 20)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["unusedArguments", "wrap"])
    }

    func testWrapAfterFirstIfMaxLengthExceeded3() {
        let input = """
        func foo(bar: Int, baz: String, aVeryLongLastArgumentThatExceedsTheMaxWidthByItself: Bool) -> Bool {}
        """
        let output = """
        func foo(bar: Int, baz: String,
                 aVeryLongLastArgumentThatExceedsTheMaxWidthByItself: Bool) -> Bool {}
        """
        let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 32)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["unusedArguments", "wrap"])
    }

    func testWrapAfterFirstIfMaxLengthExceeded3WithWrap() {
        let input = """
        func foo(bar: Int, baz: String, aVeryLongLastArgumentThatExceedsTheMaxWidthByItself: Bool) -> Bool {}
        """
        let output = """
        func foo(bar: Int, baz: String,
                 aVeryLongLastArgumentThatExceedsTheMaxWidthByItself: Bool)
                 -> Bool {}
        """
        let output2 = """
        func foo(bar: Int, baz: String,
                 aVeryLongLastArgumentThatExceedsTheMaxWidthByItself: Bool)
            -> Bool {}
        """
        let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 32)
        testFormatting(for: input, [output, output2],
                       rules: [FormatRules.wrapArguments, FormatRules.wrap],
                       options: options, exclude: ["unusedArguments"])
    }

    func testWrapAfterFirstIfMaxLengthExceeded4WithWrap() {
        let input = """
        func foo(bar: String, baz: String, quux: Bool) -> Bool {}
        """
        let output = """
        func foo(bar: String,
                 baz: String,
                 quux: Bool) -> Bool {}
        """
        let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 31)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments, FormatRules.wrap],
                       options: options, exclude: ["unusedArguments"])
    }

    func testWrapAfterFirstIfMaxLengthExceededInClassScopeWithWrap() {
        let input = """
        class TestClass {
            func foo(bar: String, baz: String, quux: Bool) -> Bool {}
        }
        """
        let output = """
        class TestClass {
            func foo(bar: String,
                     baz: String,
                     quux: Bool)
                     -> Bool {}
        }
        """
        let output2 = """
        class TestClass {
            func foo(bar: String,
                     baz: String,
                     quux: Bool)
                -> Bool {}
        }
        """
        let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 31)
        testFormatting(for: input, [output, output2],
                       rules: [FormatRules.wrapArguments, FormatRules.wrap],
                       options: options, exclude: ["unusedArguments"])
    }

    func testWrapParametersListInClosureType() {
        let input = """
        var mathFunction: (Int,
                           Int, String) -> Int = { _, _, _ in
            0
        }
        """
        let output = """
        var mathFunction: (Int,
                           Int,
                           String) -> Int = { _, _, _ in
            0
        }
        """
        let output2 = """
        var mathFunction: (Int,
                           Int,
                           String)
            -> Int =
            { _, _, _ in
                0
            }
        """
        let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 30)
        testFormatting(for: input, [output, output2],
                       rules: [FormatRules.wrapArguments],
                       options: options)
    }

    func testWrapParametersAfterFirstIfMaxLengthExceededInReturnType() {
        let input = """
        func foo(bar: Int, baz: String, quux: Bool) -> LongReturnType {}
        """
        let output2 = """
        func foo(bar: Int, baz: String,
                 quux: Bool) -> LongReturnType {}
        """
        let options = FormatOptions(wrapParameters: .afterFirst, maxWidth: 50)
        testFormatting(for: input, [input, output2], rules: [FormatRules.wrapArguments],
                       options: options, exclude: ["unusedArguments"])
    }

    // MARK: beforeFirst

    func testWrapAfterFirstConvertedToWrapBefore() {
        let input = "func foo(bar _: Int,\n    baz _: String) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testLinebreakInsertedAtEndOfWrappedFunction() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testAfterFirstConvertedToBeforeFirst() {
        let input = "func foo(bar _: Int,\n         baz _: String) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapParametersListBeforeFirstInClosureType() {
        let input = """
        var mathFunction: (Int,
                           Int, String) -> Int = { _, _, _ in
            0
        }
        """
        let output = """
        var mathFunction: (
            Int,
            Int,
            String
        ) -> Int = { _, _, _ in
            0
        }
        """
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments],
                       options: options)
    }

    func testWrapParametersListBeforeFirstInThrowingClosureType() {
        let input = """
        var mathFunction: (Int,
                           Int, String) throws -> Int = { _, _, _ in
            0
        }
        """
        let output = """
        var mathFunction: (
            Int,
            Int,
            String
        ) throws -> Int = { _, _, _ in
            0
        }
        """
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments],
                       options: options)
    }

    func testWrapParametersListBeforeFirstInRethrowingClosureType() {
        let input = """
        var mathFunction: (Int,
                           Int, String) rethrows -> Int = { _, _, _ in
            0
        }
        """
        let output = """
        var mathFunction: (
            Int,
            Int,
            String
        ) rethrows -> Int = { _, _, _ in
            0
        }
        """
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments],
                       options: options)
    }

    func testWrapParametersListBeforeFirstInClosureTypeAsFunctionParameter() {
        let input = """
        func foo(bar: (Int,
                       Bool, String) -> Int) -> Int {}
        """
        let output = """
        func foo(bar: (
            Int,
            Bool,
            String
        ) -> Int) -> Int {}
        """
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments],
                       options: options,
                       exclude: ["unusedArguments"])
    }

    func testWrapParametersListBeforeFirstInClosureTypeAsFunctionParameterWithOtherParams() {
        let input = """
        func foo(bar: Int, baz: (Int,
                                 Bool, String) -> Int) -> Int {}
        """
        let output = """
        func foo(bar: Int, baz: (
            Int,
            Bool,
            String
        ) -> Int) -> Int {}
        """
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments],
                       options: options,
                       exclude: ["unusedArguments"])
    }

    func testWrapParametersListBeforeFirstInClosureTypeAsFunctionParameterWithOtherParamsAfterWrappedClosure() {
        let input = """
        func foo(bar: Int, baz: (Int,
                                 Bool, String) -> Int, quux: String) -> Int {}
        """
        let output = """
        func foo(bar: Int, baz: (
            Int,
            Bool,
            String
        ) -> Int, quux: String) -> Int {}
        """
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments],
                       options: options,
                       exclude: ["unusedArguments"])
    }

    func testWrapParametersListBeforeFirstInEscapingClosureTypeAsFunctionParameter() {
        let input = """
        func foo(bar: @escaping (Int,
                                 Bool, String) -> Int) -> Int {}
        """
        let output = """
        func foo(bar: @escaping (
            Int,
            Bool,
            String
        ) -> Int) -> Int {}
        """
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments],
                       options: options,
                       exclude: ["unusedArguments"])
    }

    func testWrapParametersListBeforeFirstInNoEscapeClosureTypeAsFunctionParameter() {
        let input = """
        func foo(bar: @noescape (Int,
                                 Bool, String) -> Int) -> Int {}
        """
        let output = """
        func foo(bar: @noescape (
            Int,
            Bool,
            String
        ) -> Int) -> Int {}
        """
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments],
                       options: options,
                       exclude: ["unusedArguments"])
    }

    func testWrapParametersListBeforeFirstInEscapingAutoclosureTypeAsFunctionParameter() {
        let input = """
        func foo(bar: @escaping @autoclosure (Int,
                                              Bool, String) -> Int) -> Int {}
        """
        let output = """
        func foo(bar: @escaping @autoclosure (
            Int,
            Bool,
            String
        ) -> Int) -> Int {}
        """
        let options = FormatOptions(wrapParameters: .beforeFirst)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments],
                       options: options,
                       exclude: ["unusedArguments"])
    }

    // MARK: beforeFirst, maxWidth

    func testWrapBeforeFirstIfMaxLengthExceeded() {
        let input = """
        func foo(bar: Int, baz: String) -> Bool {}
        """
        let output = """
        func foo(
            bar: Int,
            baz: String
        ) -> Bool {}
        """
        let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 20)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["unusedArguments"])
    }

    func testNoWrapBeforeFirstIfMaxLengthNotExceeded() {
        let input = """
        func foo(bar: Int, baz: String) -> Bool {}
        """
        let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 42)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["unusedArguments"])
    }

    func testNoWrapGenericsIfClosingBracketWithinMaxWidth() {
        let input = """
        func foo<T: Bar>(bar: Int, baz: String) -> Bool {}
        """
        let output = """
        func foo<T: Bar>(
            bar: Int,
            baz: String
        ) -> Bool {}
        """
        let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 20)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["unusedArguments"])
    }

    func testWrapAlreadyWrappedArgumentsIfMaxLengthExceeded() {
        let input = """
        func foo(
            bar: Int, baz: String, quux: Bool
        ) -> Bool {}
        """
        let output = """
        func foo(
            bar: Int, baz: String,
            quux: Bool
        ) -> Bool {}
        """
        let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 26)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["unusedArguments"])
    }

    func testWrapParametersBeforeFirstIfMaxLengthExceededInReturnType() {
        let input = """
        func foo(bar: Int, baz: String, quux: Bool) -> LongReturnType {}
        """
        let output2 = """
        func foo(
            bar: Int,
            baz: String,
            quux: Bool
        ) -> LongReturnType {}
        """
        let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 50)
        testFormatting(for: input, [input, output2], rules: [FormatRules.wrapArguments],
                       options: options, exclude: ["unusedArguments"])
    }

    func testWrapParametersListBeforeFirstInClosureTypeWithMaxWidth() {
        let input = """
        var mathFunction: (Int, Int, String) -> Int = { _, _, _ in
            0
        }
        """
        let output = """
        var mathFunction: (
            Int,
            Int,
            String
        ) -> Int = { _, _, _ in
            0
        }
        """
        let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 30)
        testFormatting(for: input, [output], rules: [FormatRules.wrapArguments],
                       options: options)
    }

    func testNoWrapBeforeFirstMaxWidthNotExceededWithLineBreakSinceLastEndOfArgumentScope() {
        let input = """
        class Foo {
            func foo() {
                bar()
            }

            func bar(foo: String, bar: Int) {
                quux()
            }
        }
        """
        let options = FormatOptions(wrapParameters: .beforeFirst, maxWidth: 37)
        testFormatting(for: input, rule: FormatRules.wrapArguments,
                       options: options, exclude: ["unusedArguments"])
    }

    func testNoWrapSubscriptWithSingleElement() {
        let input = "guard let foo = bar[0] {}"
        let options = FormatOptions(wrapCollections: .beforeFirst, maxWidth: 20)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["wrap"])
    }

    func testNoWrapArrayWithSingleElement() {
        let input = "let foo = [0]"
        let options = FormatOptions(wrapCollections: .beforeFirst, maxWidth: 11)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["wrap"])
    }

    func testNoWrapDictionaryWithSingleElement() {
        let input = "let foo = [bar: baz]"
        let options = FormatOptions(wrapCollections: .beforeFirst, maxWidth: 15)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["wrap"])
    }

    func testNoWrapImageLiteral() {
        let input = "if let image = #imageLiteral(resourceName: \"abc.png\") {}"
        let options = FormatOptions(wrapCollections: .beforeFirst, maxWidth: 30)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["wrap"])
    }

    func testNoWrapColorLiteral() {
        let input = "if let color = #colorLiteral(red: 0.2392156863, green: 0.6470588235, blue: 0.3647058824, alpha: 1)"
        let options = FormatOptions(wrapCollections: .beforeFirst, maxWidth: 30)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["wrap"])
    }

    // MARK: closingParenOnSameLine = true

    func testParenOnSameLineWhenWrapAfterFirstConvertedToWrapBefore() {
        let input = "func foo(bar _: Int,\n    baz _: String) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String) {}"
        let options = FormatOptions(wrapParameters: .beforeFirst, closingParenOnSameLine: true)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testParenOnSameLineWhenWrapBeforeFirstUnchanged() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String) {}"
        let options = FormatOptions(wrapParameters: .beforeFirst, closingParenOnSameLine: true)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testParenOnSameLineWhenWrapBeforeFirstPreserved() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String) {}"
        let options = FormatOptions(wrapParameters: .preserve, closingParenOnSameLine: true)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    // MARK: indent with tabs

    func testTabIndentWrappedFunction() {
        let input = """
        func foo(bar: Int,
                 baz: Int) {}
        """
        let output = """
        func foo(bar: Int,
        \t\t\t\t baz: Int) {}
        """
        let options = FormatOptions(indent: "\t", wrapParameters: .afterFirst, tabWidth: 2)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["unusedArguments"])
    }

    // MARK: - wrapArguments --wrapArguments

    func testWrapArgumentsDoesNotAffectFunctionDeclaration() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapArguments: .afterFirst, wrapParameters: .preserve)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapArgumentsDoesNotAffectInit() {
        let input = "init(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapArguments: .afterFirst, wrapParameters: .preserve)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapArgumentsDoesNotAffectSubscript() {
        let input = "subscript(\n    bar _: Int,\n    baz _: String\n) -> Int {}"
        let options = FormatOptions(wrapArguments: .afterFirst, wrapParameters: .preserve)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    // MARK: afterFirst

    func testWrapArgumentsConvertBeforeFirstToAfterFirst() {
        let input = """
        foo(
            bar _: Int,
            baz _: String
        )
        """
        let output = """
        foo(bar _: Int,
            baz _: String)
        """
        let options = FormatOptions(wrapArguments: .afterFirst)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testCorrectWrapIndentForNestedArguments() {
        let input = "foo(\nbar: (\nx: 0,\ny: 0\n),\nbaz: (\nx: 0,\ny: 0\n)\n)"
        let output = "foo(bar: (x: 0,\n          y: 0),\n    baz: (x: 0,\n          y: 0))"
        let options = FormatOptions(wrapArguments: .afterFirst)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testNoRemoveLinebreakAfterCommentInArguments() {
        let input = "a(b // comment\n)"
        let options = FormatOptions(wrapArguments: .afterFirst)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testNoRemoveLinebreakAfterCommentInArguments2() {
        let input = """
        foo(bar: bar
        //  ,
        //  baz: baz
            ) {}
        """
        let options = FormatOptions(wrapArguments: .afterFirst)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options, exclude: ["indent"])
    }

    func testConsecutiveCodeCommentsNotIndented() {
        let input = """
        foo(bar: bar,
        //    bar,
        //    baz,
            quux)
        """
        let options = FormatOptions(wrapArguments: .afterFirst)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    // MARK: afterFirst maxWidth

    func testWrapArgumentsAfterFirst() {
        let input = """
        foo(bar: Int, baz: String, quux: Bool)
        """
        let output = """
        foo(bar: Int,
            baz: String,
            quux: Bool)
        """
        let options = FormatOptions(wrapArguments: .afterFirst, maxWidth: 20)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["unusedArguments", "wrap"])
    }

    // MARK: beforeFirst

    func testClosureInsideParensNotWrappedOntoNextLine() {
        let input = "foo({\n    bar()\n})"
        let options = FormatOptions(wrapArguments: .beforeFirst)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["trailingClosures"])
    }

    func testNoMangleCommentedLinesWhenWrappingArguments() {
        let input = """
        foo(bar: bar
        //    ,
        //    baz: baz
            ) {}
        """
        let output = """
        foo(
            bar: bar
        //    ,
        //    baz: baz
        ) {}
        """
        let options = FormatOptions(wrapArguments: .beforeFirst)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testNoMangleCommentedLinesWhenWrappingArgumentsWithNoCommas() {
        let input = """
        foo(bar: bar
        //    baz: baz
            ) {}
        """
        let output = """
        foo(
            bar: bar
        //    baz: baz
        ) {}
        """
        let options = FormatOptions(wrapArguments: .beforeFirst)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    // MARK: preserve

    func testWrapArgumentsDoesNotAffectLessThanOperator() {
        let input = """
        func foo() {
            guard foo < bar.count else { return nil }
        }
        """
        let options = FormatOptions(wrapArguments: .preserve)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    // MARK: - --wrapArguments, --wrapParameter

    // MARK: beforeFirst

    func testNoMistakeTernaryExpressionForArguments() {
        let input = """
        (foo ?
            bar :
            baz)
        """
        let options = FormatOptions(wrapArguments: .beforeFirst, wrapParameters: .beforeFirst)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options,
                       exclude: ["redundantParens"])
    }

    // MARK: beforeFirst, maxWidth : string interpolation

    func testNoWrapBeforeFirstArgumentInStringInterpolation() {
        let input = """
        "a very long string literal with \\(interpolation) inside"
        """
        let options = FormatOptions(wrapArguments: .beforeFirst,
                                    wrapParameters: .beforeFirst,
                                    maxWidth: 40)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testNoWrapBeforeFirstArgumentInStringInterpolation2() {
        let input = """
        "a very long string literal with \\(interpolation) inside"
        """
        let options = FormatOptions(wrapArguments: .beforeFirst,
                                    wrapParameters: .beforeFirst,
                                    maxWidth: 50)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testNoWrapBeforeFirstArgumentInStringInterpolation3() {
        let input = """
        "a very long string literal with \\(interpolated, variables) inside"
        """
        let options = FormatOptions(wrapArguments: .beforeFirst,
                                    wrapParameters: .beforeFirst,
                                    maxWidth: 40)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testNoWrapBeforeNestedFirstArgumentInStringInterpolation() {
        let input = """
        "a very long string literal with \\(foo(interpolated)) inside"
        """
        let options = FormatOptions(wrapArguments: .beforeFirst,
                                    wrapParameters: .beforeFirst,
                                    maxWidth: 45)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testNoWrapBeforeNestedFirstArgumentInStringInterpolation2() {
        let input = """
        "a very long string literal with \\(foo(interpolated, variables)) inside"
        """
        let options = FormatOptions(wrapArguments: .beforeFirst,
                                    wrapParameters: .beforeFirst,
                                    maxWidth: 45)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    // MARK: afterFirst maxWidth : string interpolation

    func testNoWrapAfterFirstArgumentInStringInterpolation() {
        let input = """
        "a very long string literal with \\(interpolated) inside"
        """
        let options = FormatOptions(wrapArguments: .afterFirst,
                                    wrapParameters: .afterFirst,
                                    maxWidth: 46)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testNoWrapAfterFirstArgumentInStringInterpolation2() {
        let input = """
        "a very long string literal with \\(interpolated, variables) inside"
        """
        let options = FormatOptions(wrapArguments: .afterFirst,
                                    wrapParameters: .afterFirst,
                                    maxWidth: 50)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testNoWrapAfterNestedFirstArgumentInStringInterpolation() {
        let input = """
        "a very long string literal with \\(foo(interpolated, variables)) inside"
        """
        let options = FormatOptions(wrapArguments: .afterFirst,
                                    wrapParameters: .afterFirst,
                                    maxWidth: 55)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    // MARK: - wrapArguments --wrapCollections

    // MARK: beforeFirst

    func testNoDoubleSpaceAddedToWrappedArray() {
        let input = "[ foo,\n    bar ]"
        let output = "[\n    foo,\n    bar\n]"
        let options = FormatOptions(trailingCommas: false, wrapCollections: .beforeFirst)
        testFormatting(for: input, [output], rules: [FormatRules.wrapArguments, FormatRules.spaceInsideBrackets],
                       options: options)
    }

    func testTrailingCommasAddedToWrappedArray() {
        let input = "[foo,\n    bar]"
        let output = "[\n    foo,\n    bar,\n]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .beforeFirst)
        testFormatting(for: input, [output], rules: [FormatRules.wrapArguments, FormatRules.trailingCommas],
                       options: options)
    }

    func testTrailingCommasAddedToWrappedNestedDictionary() {
        let input = "[foo: [bar: baz,\n    bar2: baz2]]"
        let output = "[foo: [\n    bar: baz,\n    bar2: baz2,\n]]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .beforeFirst)
        testFormatting(for: input, [output], rules: [FormatRules.wrapArguments, FormatRules.trailingCommas],
                       options: options)
    }

    func testTrailingCommasAddedToSingleLineNestedDictionary() {
        let input = "[\n    foo: [bar: baz, bar2: baz2]]"
        let output = "[\n    foo: [bar: baz, bar2: baz2],\n]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .beforeFirst)
        testFormatting(for: input, [output], rules: [FormatRules.wrapArguments, FormatRules.trailingCommas],
                       options: options)
    }

    func testTrailingCommasAddedToWrappedNestedDictionaries() {
        let input = "[foo: [bar: baz,\n    bar2: baz2],\n    foo2: [bar: baz,\n    bar2: baz2]]"
        let output = "[\n    foo: [\n        bar: baz,\n        bar2: baz2,\n    ],\n    foo2: [\n        bar: baz,\n        bar2: baz2,\n    ],\n]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .beforeFirst)
        testFormatting(for: input, [output], rules: [FormatRules.wrapArguments, FormatRules.trailingCommas],
                       options: options)
    }

    func testSpaceAroundEnumValuesInArray() {
        let input = "[\n    .foo,\n    .bar, .baz,\n]"
        let options = FormatOptions(wrapCollections: .beforeFirst)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    // MARK: beforeFirst maxWidth

    func testWrapCollectionOnOneLineBeforeFirstWidthExceededInChainedFunctionCallAfterCollection() {
        let input = """
        let foo = ["bar", "baz"].quux(quuz)
        """
        let output2 = """
        let foo = ["bar", "baz"]
            .quux(quuz)
        """
        let options = FormatOptions(wrapCollections: .beforeFirst, maxWidth: 26)
        testFormatting(for: input, [input, output2],
                       rules: [FormatRules.wrapArguments], options: options)
    }

    // MARK: afterFirst

    func testTrailingCommaRemovedInWrappedArray() {
        let input = "[\n    .foo,\n    .bar,\n    .baz,\n]"
        let output = "[.foo,\n .bar,\n .baz]"
        let options = FormatOptions(wrapCollections: .afterFirst)
        testFormatting(for: input, output, rule: FormatRules.wrapArguments, options: options)
    }

    func testNoRemoveLinebreakAfterCommentInElements() {
        let input = "[a, // comment\n]"
        let options = FormatOptions(wrapCollections: .afterFirst)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapCollectionsConsecutiveCodeCommentsNotIndented() {
        let input = """
        let a = [foo,
        //         bar,
        //         baz,
                 quux]
        """
        let options = FormatOptions(wrapCollections: .afterFirst)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    func testWrapCollectionsConsecutiveCodeCommentsNotIndentedInWrapBeforeFirst() {
        let input = """
        let a = [
            foo,
        //    bar,
        //    baz,
            quux,
        ]
        """
        let options = FormatOptions(wrapCollections: .beforeFirst)
        testFormatting(for: input, rule: FormatRules.wrapArguments, options: options)
    }

    // MARK: preserve

    func testNoBeforeFirstPreservedAndTrailingCommaIgnoredInMultilineNestedDictionary() {
        let input = "[foo: [bar: baz,\n    bar2: baz2]]"
        let output = "[foo: [bar: baz,\n       bar2: baz2]]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .preserve)
        testFormatting(for: input, [output], rules: [FormatRules.wrapArguments, FormatRules.trailingCommas],
                       options: options)
    }

    func testBeforeFirstPreservedAndTrailingCommaAddedInSingleLineNestedDictionary() {
        let input = "[\n    foo: [bar: baz, bar2: baz2]]"
        let output = "[\n    foo: [bar: baz, bar2: baz2],\n]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .preserve)
        testFormatting(for: input, [output], rules: [FormatRules.wrapArguments, FormatRules.trailingCommas],
                       options: options)
    }

    func testBeforeFirstPreservedAndTrailingCommaAddedInSingleLineNestedDictionaryWithOneNestedItem() {
        let input = "[\n    foo: [bar: baz]]"
        let output = "[\n    foo: [bar: baz],\n]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .preserve)
        testFormatting(for: input, [output], rules: [FormatRules.wrapArguments, FormatRules.trailingCommas],
                       options: options)
    }

    // MARK: - wrapArguments --wrapCollections & --wrapArguments

    // MARK: beforeFirst maxWidth

    func testWrapArgumentsBeforeFirstWhenArgumentsExceedMaxWidthAndArgumentIsCollection() {
        let input = """
        foo(bar: ["baz", "quux"], quuz: corge)
        """
        let output = """
        foo(
            bar: ["baz", "quux"],
            quuz: corge
        )
        """
        let options = FormatOptions(wrapArguments: .beforeFirst,
                                    wrapCollections: .beforeFirst,
                                    maxWidth: 26)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments], options: options)
    }

    // MARK: afterFirst maxWidth

    func testWrapArgumentsAfterFirstWhenArgumentsExceedMaxWidthAndArgumentIsCollection() {
        let input = """
        foo(bar: ["baz", "quux"], quuz: corge)
        """
        let output = """
        foo(bar: ["baz", "quux"],
            quuz: corge)
        """
        let options = FormatOptions(wrapArguments: .afterFirst,
                                    wrapCollections: .beforeFirst,
                                    maxWidth: 26)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments], options: options)
    }

    // MARK: - wrapArguments Multiple Wraps On Same Line

    func testWrapAfterFirstWhenChainedFunctionAndThenArgumentsExceedMaxWidth() {
        let input = """
        foo.bar(baz: [qux, quux]).quuz([corge: grault], garply: waldo)
        """
        let output = """
        foo.bar(baz: [qux, quux])
            .quuz([corge: grault],
                  garply: waldo)
        """
        let options = FormatOptions(wrapArguments: .afterFirst,
                                    wrapCollections: .afterFirst,
                                    maxWidth: 28)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments, FormatRules.wrap], options: options)
    }

    func testWrapAfterFirstWrapCollectionsBeforeFirstWhenChainedFunctionAndThenArgumentsExceedMaxWidth() {
        let input = """
        foo.bar(baz: [qux, quux]).quuz([corge: grault], garply: waldo)
        """
        let output = """
        foo.bar(baz: [qux, quux])
            .quuz([corge: grault],
                  garply: waldo)
        """
        let options = FormatOptions(wrapArguments: .afterFirst,
                                    wrapCollections: .beforeFirst,
                                    maxWidth: 28)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments, FormatRules.wrap], options: options)
    }

    func testNoMangleNestedFunctionCalls() {
        let input = """
        points.append(.curve(
            quadraticBezier(p0.position.x, Double(p1.x), Double(p2.x), t),
            quadraticBezier(p0.position.y, Double(p1.y), Double(p2.y), t)
        ))
        """
        let output = """
        points.append(.curve(
            quadraticBezier(
                p0.position.x,
                Double(p1.x),
                Double(p2.x),
                t
            ),
            quadraticBezier(
                p0.position.y,
                Double(p1.y),
                Double(p2.y),
                t
            )
        ))
        """
        let options = FormatOptions(wrapArguments: .beforeFirst, maxWidth: 40)
        testFormatting(for: input, [output],
                       rules: [FormatRules.wrapArguments, FormatRules.wrap], options: options)
    }

    // MARK: - numberFormatting

    // hex case

    func testLowercaseLiteralConvertedToUpper() {
        let input = "let foo = 0xabcd"
        let output = "let foo = 0xABCD"
        testFormatting(for: input, output, rule: FormatRules.numberFormatting)
    }

    func testMixedCaseLiteralConvertedToUpper() {
        let input = "let foo = 0xaBcD"
        let output = "let foo = 0xABCD"
        testFormatting(for: input, output, rule: FormatRules.numberFormatting)
    }

    func testUppercaseLiteralConvertedToLower() {
        let input = "let foo = 0xABCD"
        let output = "let foo = 0xabcd"
        let options = FormatOptions(uppercaseHex: false)
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    func testPInExponentialNotConvertedToUpper() {
        let input = "let foo = 0xaBcDp5"
        let output = "let foo = 0xABCDp5"
        testFormatting(for: input, output, rule: FormatRules.numberFormatting)
    }

    func testPInExponentialNotConvertedToLower() {
        let input = "let foo = 0xaBcDP5"
        let output = "let foo = 0xabcdP5"
        let options = FormatOptions(uppercaseHex: false, uppercaseExponent: true)
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    // exponent case

    func testLowercaseExponent() {
        let input = "let foo = 0.456E-5"
        let output = "let foo = 0.456e-5"
        testFormatting(for: input, output, rule: FormatRules.numberFormatting)
    }

    func testUppercaseExponent() {
        let input = "let foo = 0.456e-5"
        let output = "let foo = 0.456E-5"
        let options = FormatOptions(uppercaseExponent: true)
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    func testUppercaseHexExponent() {
        let input = "let foo = 0xFF00p54"
        let output = "let foo = 0xFF00P54"
        let options = FormatOptions(uppercaseExponent: true)
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    func testUppercaseGroupedHexExponent() {
        let input = "let foo = 0xFF00_AABB_CCDDp54"
        let output = "let foo = 0xFF00_AABB_CCDDP54"
        let options = FormatOptions(uppercaseExponent: true)
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    // decimal grouping

    func testDefaultDecimalGrouping() {
        let input = "let foo = 1234_56_78"
        let output = "let foo = 12_345_678"
        testFormatting(for: input, output, rule: FormatRules.numberFormatting)
    }

    func testIgnoreDecimalGrouping() {
        let input = "let foo = 1234_5_678"
        let options = FormatOptions(decimalGrouping: .ignore)
        testFormatting(for: input, rule: FormatRules.numberFormatting, options: options)
    }

    func testNoDecimalGrouping() {
        let input = "let foo = 1234_5_678"
        let output = "let foo = 12345678"
        let options = FormatOptions(decimalGrouping: .none)
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    func testDecimalGroupingThousands() {
        let input = "let foo = 1234"
        let output = "let foo = 1_234"
        let options = FormatOptions(decimalGrouping: .group(3, 3))
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    func testExponentialGrouping() {
        let input = "let foo = 1234e5678"
        let output = "let foo = 1_234e5678"
        let options = FormatOptions(decimalGrouping: .group(3, 3))
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    func testZeroGrouping() {
        let input = "let foo = 1234"
        let options = FormatOptions(decimalGrouping: .group(0, 0))
        testFormatting(for: input, rule: FormatRules.numberFormatting, options: options)
    }

    // binary grouping

    func testDefaultBinaryGrouping() {
        let input = "let foo = 0b11101000_00111111"
        let output = "let foo = 0b1110_1000_0011_1111"
        testFormatting(for: input, output, rule: FormatRules.numberFormatting)
    }

    func testIgnoreBinaryGrouping() {
        let input = "let foo = 0b1110_10_00"
        let options = FormatOptions(binaryGrouping: .ignore)
        testFormatting(for: input, rule: FormatRules.numberFormatting, options: options)
    }

    func testNoBinaryGrouping() {
        let input = "let foo = 0b1110_10_00"
        let output = "let foo = 0b11101000"
        let options = FormatOptions(binaryGrouping: .none)
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    func testBinaryGroupingCustom() {
        let input = "let foo = 0b110011"
        let output = "let foo = 0b11_00_11"
        let options = FormatOptions(binaryGrouping: .group(2, 2))
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    // hex grouping

    func testDefaultHexGrouping() {
        let input = "let foo = 0xFF01FF01AE45"
        let output = "let foo = 0xFF01_FF01_AE45"
        testFormatting(for: input, output, rule: FormatRules.numberFormatting)
    }

    func testCustomHexGrouping() {
        let input = "let foo = 0xFF00p54"
        let output = "let foo = 0xFF_00p54"
        let options = FormatOptions(hexGrouping: .group(2, 2))
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    // octal grouping

    func testDefaultOctalGrouping() {
        let input = "let foo = 0o123456701234"
        let output = "let foo = 0o1234_5670_1234"
        testFormatting(for: input, output, rule: FormatRules.numberFormatting)
    }

    func testCustomOctalGrouping() {
        let input = "let foo = 0o12345670"
        let output = "let foo = 0o12_34_56_70"
        let options = FormatOptions(octalGrouping: .group(2, 2))
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    // fraction grouping

    func testIgnoreFractionGrouping() {
        let input = "let foo = 1.234_5_678"
        let options = FormatOptions(decimalGrouping: .ignore, fractionGrouping: true)
        testFormatting(for: input, rule: FormatRules.numberFormatting, options: options)
    }

    func testNoFractionGrouping() {
        let input = "let foo = 1.234_5_678"
        let output = "let foo = 1.2345678"
        let options = FormatOptions(decimalGrouping: .none, fractionGrouping: true)
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    func testFractionGroupingThousands() {
        let input = "let foo = 12.34_56_78"
        let output = "let foo = 12.345_678"
        let options = FormatOptions(decimalGrouping: .group(3, 3), fractionGrouping: true)
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    func testHexFractionGrouping() {
        let input = "let foo = 0x12.34_56_78p56"
        let output = "let foo = 0x12.34_5678p56"
        let options = FormatOptions(hexGrouping: .group(4, 4), fractionGrouping: true)
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    // MARK: - fileHeader

    func testStripHeader() {
        let input = "//\n//  test.swift\n//  SwiftFormat\n//\n//  Created by Nick Lockwood on 08/11/2016.\n//  Copyright © 2016 Nick Lockwood. All rights reserved.\n//\n\n// func\nfunc foo() {}"
        let output = "// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testMultilineCommentHeader() {
        let input = "/****************************/\n/* Created by Nick Lockwood */\n/****************************/\n\n\n// func\nfunc foo() {}"
        let output = "// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testNoStripHeaderWhenDisabled() {
        let input = "//\n//  test.swift\n//  SwiftFormat\n//\n//  Created by Nick Lockwood on 08/11/2016.\n//  Copyright © 2016 Nick Lockwood. All rights reserved.\n//\n\n// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: .ignore)
        testFormatting(for: input, rule: FormatRules.fileHeader, options: options)
    }

    func testNoStripComment() {
        let input = "\n// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: FormatRules.fileHeader, options: options)
    }

    func testNoStripPackageHeader() {
        let input = "// swift-tools-version:4.2\n\nimport PackageDescription"
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: FormatRules.fileHeader, options: options)
    }

    func testSetSingleLineHeader() {
        let input = "//\n//  test.swift\n//  SwiftFormat\n//\n//  Created by Nick Lockwood on 08/11/2016.\n//  Copyright © 2016 Nick Lockwood. All rights reserved.\n//\n\n// func\nfunc foo() {}"
        let output = "// Hello World\n\n// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "// Hello World")
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testSetMultilineHeader() {
        let input = "//\n//  test.swift\n//  SwiftFormat\n//\n//  Created by Nick Lockwood on 08/11/2016.\n//  Copyright © 2016 Nick Lockwood. All rights reserved.\n//\n\n// func\nfunc foo() {}"
        let output = "// Hello\n// World\n\n// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "// Hello\n// World")
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testSetMultilineHeaderWithMarkup() {
        let input = "//\n//  test.swift\n//  SwiftFormat\n//\n//  Created by Nick Lockwood on 08/11/2016.\n//  Copyright © 2016 Nick Lockwood. All rights reserved.\n//\n\n// func\nfunc foo() {}"
        let output = "/*--- Hello ---*/\n/*--- World ---*/\n\n// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "/*--- Hello ---*/\n/*--- World ---*/")
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testNoStripHeaderIfRuleDisabled() {
        let input = "// swiftformat:disable fileHeader\n// test\n// swiftformat:enable fileHeader\n\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: FormatRules.fileHeader, options: options)
    }

    func testNoStripHeaderIfNextRuleDisabled() {
        let input = "// swiftformat:disable:next fileHeader\n// test\n\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: FormatRules.fileHeader, options: options)
    }

    func testNoStripHeaderDocWithNewlineBeforeCode() {
        let input = "/// Header doc\n\nclass Foo {}"
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: FormatRules.fileHeader, options: options)
    }

    func testNoDuplicateHeaderIfMissingTrailingBlankLine() {
        let input = "// Header comment\nclass Foo {}"
        let output = "// Header comment\n\nclass Foo {}"
        let options = FormatOptions(fileHeader: "Header comment")
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testFileHeaderYearReplacement() {
        let input = "let foo = bar"
        let output: String = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return "// Copyright © \(formatter.string(from: Date()))\n\nlet foo = bar"
        }()
        let options = FormatOptions(fileHeader: "// Copyright © {year}")
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testFileHeaderCreationYearReplacement() {
        let input = "let foo = bar"
        let date = Date(timeIntervalSince1970: 0)
        let output: String = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return "// Copyright © \(formatter.string(from: date))\n\nlet foo = bar"
        }()
        let fileInfo = FileInfo(creationDate: date)
        let options = FormatOptions(fileHeader: "// Copyright © {created.year}", fileInfo: fileInfo)
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testFileHeaderCreationDateReplacement() {
        let input = "let foo = bar"
        let date = Date(timeIntervalSince1970: 0)
        let output: String = {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return "// Created by Nick Lockwood on \(formatter.string(from: date)).\n\nlet foo = bar"
        }()
        let fileInfo = FileInfo(creationDate: date)
        let options = FormatOptions(fileHeader: "// Created by Nick Lockwood on {created}.", fileInfo: fileInfo)
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testFileHeaderFileReplacement() {
        let input = "let foo = bar"
        let output = "// MyFile.swift\n\nlet foo = bar"
        let fileInfo = FileInfo(filePath: "~/MyFile.swift")
        let options = FormatOptions(fileHeader: "// {file}", fileInfo: fileInfo)
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    // MARK: - redundantInit

    func testRemoveRedundantInit() {
        let input = "[1].flatMap { String.init($0) }"
        let output = "[1].flatMap { String($0) }"
        testFormatting(for: input, output, rule: FormatRules.redundantInit)
    }

    func testRemoveRedundantInit2() {
        let input = "[String.self].map { Type in Type.init(foo: 1) }"
        let output = "[String.self].map { Type in Type(foo: 1) }"
        testFormatting(for: input, output, rule: FormatRules.redundantInit)
    }

    func testRemoveRedundantInit3() {
        let input = "String.init(\"text\")"
        let output = "String(\"text\")"
        testFormatting(for: input, output, rule: FormatRules.redundantInit)
    }

    func testDontRemoveInitInSuperCall() {
        let input = "class C: NSObject { override init() { super.init() } }"
        testFormatting(for: input, rule: FormatRules.redundantInit)
    }

    func testDontRemoveInitInSelfCall() {
        let input = "struct S { let n: Int }; extension S { init() { self.init(n: 1) } }"
        testFormatting(for: input, rule: FormatRules.redundantInit)
    }

    func testDontRemoveInitWhenPassedAsFunction() {
        let input = "[1].flatMap(String.init)"
        testFormatting(for: input, rule: FormatRules.redundantInit)
    }

    func testDontRemoveInitWhenUsedOnMetatype() {
        let input = "[String.self].map { type in type.init(1) }"
        testFormatting(for: input, rule: FormatRules.redundantInit)
    }

    func testDontRemoveInitWhenUsedOnImplicitClosureMetatype() {
        let input = "[String.self].map { $0.init(1) }"
        testFormatting(for: input, rule: FormatRules.redundantInit)
    }

    func testDontRemoveInitWithExplicitSignature() {
        let input = "[String.self].map(Foo.init(bar:))"
        testFormatting(for: input, rule: FormatRules.redundantInit)
    }

    // MARK: - sortedImports

    func testSortedImportsSimpleCase() {
        let input = "import Foo\nimport Bar"
        let output = "import Bar\nimport Foo"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testSortedImportsKeepsPreviousCommentWithImport() {
        let input = "import Foo\n// important comment\n// (very important)\nimport Bar"
        let output = "// important comment\n// (very important)\nimport Bar\nimport Foo"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testSortedImportsKeepsPreviousCommentWithImport2() {
        let input = "// important comment\n// (very important)\nimport Foo\nimport Bar"
        let output = "import Bar\n// important comment\n// (very important)\nimport Foo"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testSortedImportsDoesntMoveHeaderComment() {
        let input = "// header comment\n\nimport Foo\nimport Bar"
        let output = "// header comment\n\nimport Bar\nimport Foo"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testSortedImportsDoesntMoveHeaderCommentFollowedByImportComment() {
        let input = "// header comment\n\n// important comment\nimport Foo\nimport Bar"
        let output = "// header comment\n\nimport Bar\n// important comment\nimport Foo"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testSortedImportsOnSameLine() {
        let input = "import Foo; import Bar\nimport Baz"
        let output = "import Baz\nimport Foo; import Bar"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testSortedImportsWithSemicolonAndCommentOnSameLine() {
        let input = "import Foo; // foobar\nimport Bar\nimport Baz"
        let output = "import Bar\nimport Baz\nimport Foo; // foobar"
        testFormatting(for: input, output, rule: FormatRules.sortedImports, exclude: ["semicolons"])
    }

    func testSortedImportEnum() {
        let input = "import enum Foo.baz\nimport Foo.bar"
        let output = "import Foo.bar\nimport enum Foo.baz"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testSortedImportFunc() {
        let input = "import func Foo.baz\nimport Foo.bar"
        let output = "import Foo.bar\nimport func Foo.baz"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testAlreadySortedImportsDoesNothing() {
        let input = "import Bar\nimport Foo"
        testFormatting(for: input, rule: FormatRules.sortedImports)
    }

    func testPreprocessorSortedImports() {
        let input = "#if os(iOS)\n    import Foo2\n    import Bar2\n#else\n    import Foo1\n    import Bar1\n#endif\nimport Foo3\nimport Bar3"
        let output = "#if os(iOS)\n    import Bar2\n    import Foo2\n#else\n    import Bar1\n    import Foo1\n#endif\nimport Bar3\nimport Foo3"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testTestableSortedImports() {
        let input = "@testable import Foo3\nimport Bar3"
        let output = "import Bar3\n@testable import Foo3"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testTestableImportsWithTestableOnPreviousLine() {
        let input = "@testable\nimport Foo3\nimport Bar3"
        let output = "import Bar3\n@testable\nimport Foo3"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testTestableImportsWithGroupingTestableBottom() {
        let input = "@testable import Bar\nimport Foo\n@testable import UIKit"
        let output = "import Foo\n@testable import Bar\n@testable import UIKit"
        let options = FormatOptions(importGrouping: .testableBottom)
        testFormatting(for: input, output, rule: FormatRules.sortedImports, options: options)
    }

    func testTestableImportsWithGroupingTestableTop() {
        let input = "@testable import Bar\nimport Foo\n@testable import UIKit"
        let output = "@testable import Bar\n@testable import UIKit\nimport Foo"
        let options = FormatOptions(importGrouping: .testableTop)
        testFormatting(for: input, output, rule: FormatRules.sortedImports, options: options)
    }

    func testCaseInsensitiveSortedImports() {
        let input = "import Zlib\nimport lib"
        let output = "import lib\nimport Zlib"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testCaseInsensitiveCaseDifferingSortedImports() {
        let input = "import c\nimport B\nimport A.a\nimport A.A"
        let output = "import A.A\nimport A.a\nimport B\nimport c"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testNoDeleteCodeBetweenImports() {
        let input = "import Foo\nfunc bar() {}\nimport Bar"
        testFormatting(for: input, rule: FormatRules.sortedImports)
    }

    func testNoDeleteCodeBetweenImports2() {
        let input = "import Foo\nimport Bar\nfoo = bar\nimport Bar"
        let output = "import Bar\nimport Foo\nfoo = bar\nimport Bar"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testNoDeleteCodeBetweenImports3() {
        let input = """
        import Z

        // one

        #if FLAG
            print("hi")
        #endif

        import A
        """
        testFormatting(for: input, rule: FormatRules.sortedImports)
    }

    func testSortContiguousImports() {
        let input = "import Foo\nimport Bar\nfunc bar() {}\nimport Quux\nimport Baz"
        let output = "import Bar\nimport Foo\nfunc bar() {}\nimport Baz\nimport Quux"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    // MARK: - duplicateImports

    func testRemoveDuplicateImport() {
        let input = "import Foundation\nimport Foundation"
        let output = "import Foundation"
        testFormatting(for: input, output, rule: FormatRules.duplicateImports)
    }

    func testRemoveDuplicateConditionalImport() {
        let input = "#if os(iOS)\n    import Foo\n    import Foo\n#else\n    import Bar\n    import Bar\n#endif"
        let output = "#if os(iOS)\n    import Foo\n#else\n    import Bar\n#endif"
        testFormatting(for: input, output, rule: FormatRules.duplicateImports)
    }

    func testNoRemoveOverlappingImports() {
        let input = "import MyModule\nimport MyModule.Private"
        testFormatting(for: input, rule: FormatRules.duplicateImports)
    }

    func testNoRemoveCaseDifferingImports() {
        let input = "import Auth0.Authentication\nimport Auth0.authentication"
        testFormatting(for: input, rule: FormatRules.duplicateImports)
    }

    func testRemoveDuplicateImportFunc() {
        let input = "import func Foo.bar\nimport func Foo.bar"
        let output = "import func Foo.bar"
        testFormatting(for: input, output, rule: FormatRules.duplicateImports)
    }

    func testNoRemoveTestableDuplicateImport() {
        let input = "import Foo\n@testable import Foo"
        let output = "\n@testable import Foo"
        testFormatting(for: input, output, rule: FormatRules.duplicateImports)
    }

    func testNoRemoveTestableDuplicateImport2() {
        let input = "@testable import Foo\nimport Foo"
        let output = "@testable import Foo"
        testFormatting(for: input, output, rule: FormatRules.duplicateImports)
    }

    // MARK: - strongOutlets

    func testRemoveWeakFromOutlet() {
        let input = "@IBOutlet weak var label: UILabel!"
        let output = "@IBOutlet var label: UILabel!"
        testFormatting(for: input, output, rule: FormatRules.strongOutlets)
    }

    func testRemoveWeakFromPrivateOutlet() {
        let input = "@IBOutlet private weak var label: UILabel!"
        let output = "@IBOutlet private var label: UILabel!"
        testFormatting(for: input, output, rule: FormatRules.strongOutlets)
    }

    func testRemoveWeakFromOutletOnSplitLine() {
        let input = "@IBOutlet\nweak var label: UILabel!"
        let output = "@IBOutlet\nvar label: UILabel!"
        testFormatting(for: input, output, rule: FormatRules.strongOutlets)
    }

    func testNoRemoveWeakFromNonOutlet() {
        let input = "weak var label: UILabel!"
        testFormatting(for: input, rule: FormatRules.strongOutlets)
    }

    func testNoRemoveWeakFromNonOutletAfterOutlet() {
        let input = "@IBOutlet weak var label1: UILabel!\nweak var label2: UILabel!"
        let output = "@IBOutlet var label1: UILabel!\nweak var label2: UILabel!"
        testFormatting(for: input, output, rule: FormatRules.strongOutlets)
    }

    func testNoRemoveWeakFromDelegateOutlet() {
        let input = "@IBOutlet weak var delegate: UITableViewDelegate?"
        testFormatting(for: input, rule: FormatRules.strongOutlets)
    }

    func testNoRemoveWeakFromDataSourceOutlet() {
        let input = "@IBOutlet weak var dataSource: UITableViewDataSource?"
        testFormatting(for: input, rule: FormatRules.strongOutlets)
    }

    func testRemoveWeakFromOutletAfterDelegateOutlet() {
        let input = "@IBOutlet weak var delegate: UITableViewDelegate?\n@IBOutlet weak var label1: UILabel!"
        let output = "@IBOutlet weak var delegate: UITableViewDelegate?\n@IBOutlet var label1: UILabel!"
        testFormatting(for: input, output, rule: FormatRules.strongOutlets)
    }

    func testRemoveWeakFromOutletAfterDataSourceOutlet() {
        let input = "@IBOutlet weak var dataSource: UITableViewDataSource?\n@IBOutlet weak var label1: UILabel!"
        let output = "@IBOutlet weak var dataSource: UITableViewDataSource?\n@IBOutlet var label1: UILabel!"
        testFormatting(for: input, output, rule: FormatRules.strongOutlets)
    }

    // MARK: - emptyBraces

    func testLinebreaksRemovedInsideBraces() {
        let input = "func foo() {\n  \n }"
        let output = "func foo() {}"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: FormatRules.emptyBraces, options: options)
    }

    func testCommentNotRemovedInsideBraces() {
        let input = "func foo() { // foo\n}"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: FormatRules.emptyBraces, options: options)
    }

    func testEmptyBracesNotRemovedInDoCatch() {
        let input = """
        do {
        } catch is FooError {
        } catch {}
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: FormatRules.emptyBraces, options: options)
    }

    func testEmptyBracesNotRemovedInIfElse() {
        let input = """
        if {
        } else if foo {
        } else {}
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: FormatRules.emptyBraces, options: options)
    }

    // MARK: - andOperator

    func testIfAndReplaced() {
        let input = "if true && true {}"
        let output = "if true, true {}"
        testFormatting(for: input, output, rule: FormatRules.andOperator)
    }

    func testGuardAndReplaced() {
        let input = "guard true && true\nelse { return }"
        let output = "guard true, true\nelse { return }"
        testFormatting(for: input, output, rule: FormatRules.andOperator)
    }

    func testWhileAndReplaced() {
        let input = "while true && true {}"
        let output = "while true, true {}"
        testFormatting(for: input, output, rule: FormatRules.andOperator)
    }

    func testIfDoubleAndReplaced() {
        let input = "if true && true && true {}"
        let output = "if true, true, true {}"
        testFormatting(for: input, output, rule: FormatRules.andOperator)
    }

    func testIfAndParensReplaced() {
        let input = "if true && (true && true) {}"
        let output = "if true, (true && true) {}"
        testFormatting(for: input, output, rule: FormatRules.andOperator, exclude: ["redundantParens"])
    }

    func testIfFunctionAndReplaced() {
        let input = "if functionReturnsBool() && true {}"
        let output = "if functionReturnsBool(), true {}"
        testFormatting(for: input, output, rule: FormatRules.andOperator)
    }

    func testNoReplaceIfOrAnd() {
        let input = "if foo || bar && baz {}"
        testFormatting(for: input, rule: FormatRules.andOperator)
    }

    func testNoReplaceIfAndOr() {
        let input = "if foo && bar || baz {}"
        testFormatting(for: input, rule: FormatRules.andOperator)
    }

    func testIfAndReplacedInFunction() {
        let input = "func someFunc() { if bar && baz {} }"
        let output = "func someFunc() { if bar, baz {} }"
        testFormatting(for: input, output, rule: FormatRules.andOperator)
    }

    func testNoReplaceIfCaseLetAnd() {
        let input = "if case let a = foo && bar {}"
        testFormatting(for: input, rule: FormatRules.andOperator)
    }

    func testNoReplaceWhileCaseLetAnd() {
        let input = "while case let a = foo && bar {}"
        testFormatting(for: input, rule: FormatRules.andOperator)
    }

    func testNoReplaceRepeatWhileAnd() {
        let input = """
        repeat {} while true && !false
        foo {}
        """
        testFormatting(for: input, rule: FormatRules.andOperator)
    }

    func testNoReplaceIfLetAndLetAnd() {
        let input = "if let a = b && c, let d = e && f {}"
        testFormatting(for: input, rule: FormatRules.andOperator)
    }

    func testNoReplaceIfTryAnd() {
        let input = "if try true && explode() {}"
        testFormatting(for: input, rule: FormatRules.andOperator)
    }

    func testHandleAndAtStartOfLine() {
        let input = "if a == b\n    && b == c {}"
        let output = "if a == b,\n    b == c {}"
        testFormatting(for: input, output, rule: FormatRules.andOperator)
    }

    func testHandleAndAtStartOfLineAfterComment() {
        let input = "if a == b // foo\n    && b == c {}"
        let output = "if a == b, // foo\n    b == c {}"
        testFormatting(for: input, output, rule: FormatRules.andOperator)
    }

    func testNoReplaceAndInViewBuilder() {
        let input = """
        SomeView {
            if foo == 5 && bar {
                Text("5")
            } else {
                Text("Not 5")
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.andOperator)
    }

    func testNoReplaceAndInViewBuilder2() {
        let input = """
        var body: some View {
            ZStack {
                if self.foo && self.bar {
                    self.closedPath
                }
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.andOperator)
    }

    // MARK: - isEmpty

    // count == 0

    func testCountEqualsZero() {
        let input = "if foo.count == 0 {}"
        let output = "if foo.isEmpty {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testFunctionCountEqualsZero() {
        let input = "if foo().count == 0 {}"
        let output = "if foo().isEmpty {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testExpressionCountEqualsZero() {
        let input = "if foo || bar.count == 0 {}"
        let output = "if foo || bar.isEmpty {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testCompoundIfCountEqualsZero() {
        let input = "if foo, bar.count == 0 {}"
        let output = "if foo, bar.isEmpty {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testOptionalCountEqualsZero() {
        let input = "if foo?.count == 0 {}"
        let output = "if foo?.isEmpty == true {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testOptionalChainCountEqualsZero() {
        let input = "if foo?.bar.count == 0 {}"
        let output = "if foo?.bar.isEmpty == true {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testCompoundIfOptionalCountEqualsZero() {
        let input = "if foo, bar?.count == 0 {}"
        let output = "if foo, bar?.isEmpty == true {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testTernaryCountEqualsZero() {
        let input = "foo ? bar.count == 0 : baz.count == 0"
        let output = "foo ? bar.isEmpty : baz.isEmpty"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    // count != 0

    func testCountNotEqualToZero() {
        let input = "if foo.count != 0 {}"
        let output = "if !foo.isEmpty {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testFunctionCountNotEqualToZero() {
        let input = "if foo().count != 0 {}"
        let output = "if !foo().isEmpty {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testExpressionCountNotEqualToZero() {
        let input = "if foo || bar.count != 0 {}"
        let output = "if foo || !bar.isEmpty {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testCompoundIfCountNotEqualToZero() {
        let input = "if foo, bar.count != 0 {}"
        let output = "if foo, !bar.isEmpty {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    // count > 0

    func testCountGreaterThanZero() {
        let input = "if foo.count > 0 {}"
        let output = "if !foo.isEmpty {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testCountExpressionGreaterThanZero() {
        let input = "if a.count - b.count > 0 {}"
        testFormatting(for: input, rule: FormatRules.isEmpty)
    }

    // optional count

    func testOptionalCountNotEqualToZero() {
        let input = "if foo?.count != 0 {}" // nil evaluates to true
        let output = "if foo?.isEmpty != true {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testOptionalChainCountNotEqualToZero() {
        let input = "if foo?.bar.count != 0 {}" // nil evaluates to true
        let output = "if foo?.bar.isEmpty != true {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testCompoundIfOptionalCountNotEqualToZero() {
        let input = "if foo, bar?.count != 0 {}"
        let output = "if foo, bar?.isEmpty != true {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    // edge cases

    func testTernaryCountNotEqualToZero() {
        let input = "foo ? bar.count != 0 : baz.count != 0"
        let output = "foo ? !bar.isEmpty : !baz.isEmpty"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testCountEqualsZeroAfterOptionalOnPreviousLine() {
        let input = "_ = foo?.bar\nbar.count == 0 ? baz() : quux()"
        let output = "_ = foo?.bar\nbar.isEmpty ? baz() : quux()"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testCountEqualsZeroAfterOptionalCallOnPreviousLine() {
        let input = "foo?.bar()\nbar.count == 0 ? baz() : quux()"
        let output = "foo?.bar()\nbar.isEmpty ? baz() : quux()"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testCountEqualsZeroAfterTrailingCommentOnPreviousLine() {
        let input = "foo?.bar() // foobar\nbar.count == 0 ? baz() : quux()"
        let output = "foo?.bar() // foobar\nbar.isEmpty ? baz() : quux()"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testCountGreaterThanZeroAfterOpenParen() {
        let input = "foo(bar.count > 0)"
        let output = "foo(!bar.isEmpty)"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testCountGreaterThanZeroAfterArgumentLabel() {
        let input = "foo(bar: baz.count > 0)"
        let output = "foo(bar: !baz.isEmpty)"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    // MARK: - redundantLetError

    func testCatchLetError() {
        let input = "do {} catch let error {}"
        let output = "do {} catch {}"
        testFormatting(for: input, output, rule: FormatRules.redundantLetError)
    }

    // MARK: - anyObjectProtocol

    func testClassReplacedByAnyObject() {
        let input = "protocol Foo: class {}"
        let output = "protocol Foo: AnyObject {}"
        let options = FormatOptions(swiftVersion: "4.1")
        testFormatting(for: input, output, rule: FormatRules.anyObjectProtocol, options: options)
    }

    func testClassReplacedByAnyObjectWithOtherProtocols() {
        let input = "protocol Foo: class, Codable {}"
        let output = "protocol Foo: AnyObject, Codable {}"
        let options = FormatOptions(swiftVersion: "4.1")
        testFormatting(for: input, output, rule: FormatRules.anyObjectProtocol, options: options)
    }

    func testClassReplacedByAnyObjectImmediatelyAfterImport() {
        let input = "import Foundation\nprotocol Foo: class {}"
        let output = "import Foundation\nprotocol Foo: AnyObject {}"
        let options = FormatOptions(swiftVersion: "4.1")
        testFormatting(for: input, output, rule: FormatRules.anyObjectProtocol, options: options)
    }

    func testClassDeclarationNotReplacedByAnyObject() {
        let input = "class Foo: Codable {}"
        let options = FormatOptions(swiftVersion: "4.1")
        testFormatting(for: input, rule: FormatRules.anyObjectProtocol, options: options)
    }

    func testClassImportNotReplacedByAnyObject() {
        let input = "import class Foo.Bar"
        let options = FormatOptions(swiftVersion: "4.1")
        testFormatting(for: input, rule: FormatRules.anyObjectProtocol, options: options)
    }

    func testClassNotReplacedByAnyObjectIfSwiftVersionLessThan4_1() {
        let input = "protocol Foo: class {}"
        let options = FormatOptions(swiftVersion: "4.0")
        testFormatting(for: input, rule: FormatRules.anyObjectProtocol, options: options)
    }

    // MARK: - redundantBreak

    func testRedundantBreaksRemoved() {
        let input = """
        switch x {
        case foo:
            print("hello")
            break
        case bar:
            print("world")
            break
        default:
            print("goodbye")
            break
        }
        """
        let output = """
        switch x {
        case foo:
            print("hello")
        case bar:
            print("world")
        default:
            print("goodbye")
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantBreak)
    }

    func testBreakInEmptyCaseNotRemoved() {
        let input = """
        switch x {
        case foo:
            break
        case bar:
            break
        default:
            break
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantBreak)
    }

    func testConditionalBreakNotRemoved() {
        let input = """
        switch x {
        case foo:
            if bar {
                break
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantBreak)
    }

    func testBreakAfterSemicolonNotMangled() {
        let input = """
        switch foo {
        case 1: print(1); break
        }
        """
        let output = """
        switch foo {
        case 1: print(1);
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantBreak, exclude: ["semicolons"])
    }

    // MARK: - strongifiedSelf

    func testBacktickedSelfConvertedToSelfInGuard() {
        let input = """
        { [weak self] in
            guard let `self` = self else { return }
        }
        """
        let output = """
        { [weak self] in
            guard let self = self else { return }
        }
        """
        let options = FormatOptions(swiftVersion: "4.2")
        testFormatting(for: input, output, rule: FormatRules.strongifiedSelf, options: options)
    }

    func testBacktickedSelfConvertedToSelfInIf() {
        let input = """
        { [weak self] in
            if let `self` = self else { print(self) }
        }
        """
        let output = """
        { [weak self] in
            if let self = self else { print(self) }
        }
        """
        let options = FormatOptions(swiftVersion: "4.2")
        testFormatting(for: input, output, rule: FormatRules.strongifiedSelf, options: options)
    }

    func testBacktickedSelfNotConvertedIfVersionLessThan4_2() {
        let input = """
        { [weak self] in
            guard let `self` = self else { return }
        }
        """
        let options = FormatOptions(swiftVersion: "4.1.5")
        testFormatting(for: input, rule: FormatRules.strongifiedSelf, options: options)
    }

    func testBacktickedSelfNotConvertedIfVersionUnspecified() {
        let input = """
        { [weak self] in
            guard let `self` = self else { return }
        }
        """
        testFormatting(for: input, rule: FormatRules.strongifiedSelf)
    }

    // MARK: - redundantObjc

    func testRedundantObjcRemovedFromBeforeOutlet() {
        let input = "@objc @IBOutlet var label: UILabel!"
        let output = "@IBOutlet var label: UILabel!"
        testFormatting(for: input, output, rule: FormatRules.redundantObjc)
    }

    func testRedundantObjcRemovedFromAfterOutlet() {
        let input = "@IBOutlet @objc var label: UILabel!"
        let output = "@IBOutlet var label: UILabel!"
        testFormatting(for: input, output, rule: FormatRules.redundantObjc)
    }

    func testRedundantObjcRemovedFromLineBeforeOutlet() {
        let input = "@objc\n@IBOutlet var label: UILabel!"
        let output = "\n@IBOutlet var label: UILabel!"
        testFormatting(for: input, output, rule: FormatRules.redundantObjc)
    }

    func testRedundantObjcCommentNotRemoved() {
        let input = "@objc // an outlet\n@IBOutlet var label: UILabel!"
        let output = "// an outlet\n@IBOutlet var label: UILabel!"
        testFormatting(for: input, output, rule: FormatRules.redundantObjc)
    }

    func testObjcNotRemovedFromNSCopying() {
        let input = "@objc @NSCopying var foo: String!"
        testFormatting(for: input, rule: FormatRules.redundantObjc)
    }

    func testRenamedObjcNotRemoved() {
        let input = "@IBOutlet @objc(uiLabel) var label: UILabel!"
        testFormatting(for: input, rule: FormatRules.redundantObjc)
    }

    func testObjcRemovedOnObjcMembersClass() {
        let input = """
        @objcMembers class Foo: NSObject {
            @objc var foo: String
        }
        """
        let output = """
        @objcMembers class Foo: NSObject {
            var foo: String
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantObjc)
    }

    func testObjcRemovedOnRenamedObjcMembersClass() {
        let input = """
        @objcMembers @objc(OCFoo) class Foo: NSObject {
            @objc var foo: String
        }
        """
        let output = """
        @objcMembers @objc(OCFoo) class Foo: NSObject {
            var foo: String
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantObjc)
    }

    func testObjcNotRemovedOnNestedClass() {
        let input = """
        @objcMembers class Foo: NSObject {
            @objc class Bar: NSObject {}
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantObjc)
    }

    func testObjcNotRemovedOnRenamedPrivateNestedClass() {
        let input = """
        @objcMembers class Foo: NSObject {
            @objc private class Bar: NSObject {}
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantObjc)
    }

    func testObjcNotRemovedOnNestedEnum() {
        let input = """
        @objcMembers class Foo: NSObject {
            @objc enum Bar: Int {}
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantObjc)
    }

    func testObjcRemovedOnObjcExtensionVar() {
        let input = """
        @objc extension Foo {
            @objc var foo: String {}
        }
        """
        let output = """
        @objc extension Foo {
            var foo: String {}
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantObjc)
    }

    func testObjcRemovedOnObjcExtensionFunc() {
        let input = """
        @objc extension Foo {
            @objc func foo() -> String {}
        }
        """
        let output = """
        @objc extension Foo {
            func foo() -> String {}
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantObjc)
    }

    func testObjcNotRemovedOnPrivateFunc() {
        let input = """
        @objcMembers class Foo: NSObject {
            @objc private func bar() {}
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantObjc)
    }

    func testObjcNotRemovedOnFileprivateFunc() {
        let input = """
        @objcMembers class Foo: NSObject {
            @objc fileprivate func bar() {}
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantObjc)
    }

    // MARK: - typeSugar

    // arrays

    func testArrayTypeConvertedToSugar() {
        let input = "var foo: Array<String>"
        let output = "var foo: [String]"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testSwiftArrayTypeConvertedToSugar() {
        let input = "var foo: Swift.Array<String>"
        let output = "var foo: [String]"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testArrayNestedTypeAliasNotConvertedToSugar() {
        let input = "typealias Indices = Array<Foo>.Indices"
        testFormatting(for: input, rule: FormatRules.typeSugar)
    }

    func testArrayTypeReferenceConvertedToSugar() {
        let input = "let type = Array<Foo>.Type"
        let output = "let type = [Foo].Type"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testSwiftArrayTypeReferenceConvertedToSugar() {
        let input = "let type = Swift.Array<Foo>.Type"
        let output = "let type = [Foo].Type"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testArraySelfReferenceConvertedToSugar() {
        let input = "let type = Array<Foo>.self"
        let output = "let type = [Foo].self"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testSwiftArraySelfReferenceConvertedToSugar() {
        let input = "let type = Swift.Array<Foo>.self"
        let output = "let type = [Foo].self"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    // dictionaries

    func testDictionaryTypeConvertedToSugar() {
        let input = "var foo: Dictionary<String, Int>"
        let output = "var foo: [String: Int]"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testSwiftDictionaryTypeConvertedToSugar() {
        let input = "var foo: Swift.Dictionary<String, Int>"
        let output = "var foo: [String: Int]"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    // optionals

    func testOptionalTypeConvertedToSugar() {
        let input = "var foo: Optional<String>"
        let output = "var foo: String?"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testSwiftOptionalTypeConvertedToSugar() {
        let input = "var foo: Swift.Optional<String>"
        let output = "var foo: String?"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testOptionalClosureParenthesizedConvertedToSugar() {
        let input = "var foo: Optional<(Int) -> String>"
        let output = "var foo: ((Int) -> String)?"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testSwiftOptionalClosureParenthesizedConvertedToSugar() {
        let input = "var foo: Swift.Optional<(Int) -> String>"
        let output = "var foo: ((Int) -> String)?"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testStrippingSwiftNamespaceInOptionalTypeWhenConvertedToSugar() {
        let input = "Swift.Optional<String>"
        let output = "String?"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testStrippingSwiftNamespaceDoesNotStripPreviousSwiftNamespaceReferences() {
        let input = "let a: Swift.String = Optional<String>"
        let output = "let a: Swift.String = String?"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    // shortOptionals = exceptProperties

    func testPropertyTypeNotConvertedToSugar() {
        let input = "var foo: Optional<String>"
        let options = FormatOptions(shortOptionals: .exceptProperties)
        testFormatting(for: input, rule: FormatRules.typeSugar, options: options)
    }

    // swift parser bug

    func testAvoidSwiftParserBugWithClosuresInsideArrays() {
        let input = "var foo = Array<(_ image: Data?) -> Void>()"
        testFormatting(for: input, rule: FormatRules.typeSugar)
    }

    func testAvoidSwiftParserBugWithClosuresInsideDictionaries() {
        let input = "var foo = Dictionary<String, (_ image: Data?) -> Void>()"
        testFormatting(for: input, rule: FormatRules.typeSugar)
    }

    func testAvoidSwiftParserBugWithClosuresInsideOptionals() {
        let input = "var foo = Optional<(_ image: Data?) -> Void>()"
        testFormatting(for: input, rule: FormatRules.typeSugar)
    }

    func testDontOverApplyBugWorkaround() {
        let input = "var foo: Array<(_ image: Data?) -> Void>"
        let output = "var foo: [(_ image: Data?) -> Void]"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testDontOverApplyBugWorkaround2() {
        let input = "var foo: Dictionary<String, (_ image: Data?) -> Void>"
        let output = "var foo: [String: (_ image: Data?) -> Void]"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testDontOverApplyBugWorkaround3() {
        let input = "var foo: Optional<(_ image: Data?) -> Void>"
        let output = "var foo: ((_ image: Data?) -> Void)?"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testDontOverApplyBugWorkaround4() {
        let input = "var foo = Array<(image: Data?) -> Void>()"
        let output = "var foo = [(image: Data?) -> Void]()"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testDontOverApplyBugWorkaround5() {
        let input = "var foo = Array<(Data?) -> Void>()"
        let output = "var foo = [(Data?) -> Void]()"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testDontOverApplyBugWorkaround6() {
        let input = "var foo = Dictionary<Int, Array<(_ image: Data?) -> Void>>()"
        let output = "var foo = [Int: Array<(_ image: Data?) -> Void>]()"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    // MARK: - redundantExtensionACL

    func testPublicExtensionMemberACLStripped() {
        let input = """
        public extension Foo {
            public var bar: Int { 5 }
            private static let baz = "baz"
            public func quux() {}
        }
        """
        let output = """
        public extension Foo {
            var bar: Int { 5 }
            private static let baz = "baz"
            func quux() {}
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantExtensionACL)
    }

    func testPrivateExtensionMemberACLNotStrippedUnlessFileprivate() {
        let input = """
        private extension Foo {
            fileprivate var bar: Int { 5 }
            private static let baz = "baz"
            fileprivate func quux() {}
        }
        """
        let output = """
        private extension Foo {
            var bar: Int { 5 }
            private static let baz = "baz"
            func quux() {}
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantExtensionACL)
    }

    // MARK: - redundantFileprivate

    func testFileScopeFileprivateVarChangedToPrivate() {
        let input = """
        fileprivate var foo = "foo"
        """
        let output = """
        private var foo = "foo"
        """
        testFormatting(for: input, output, rule: FormatRules.redundantFileprivate)
    }

    func testFileScopeFileprivateVarNotChangedToPrivateIfFragment() {
        let input = """
        fileprivate var foo = "foo"
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateVarChangedToPrivateIfNotAccessedFromAnotherType() {
        let input = """
        struct Foo {
            fileprivate var foo = "foo"
        }
        """
        let output = """
        struct Foo {
            private var foo = "foo"
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateVarChangedToPrivateIfNotAccessedFromAnotherTypeAndFileIncludesImports() {
        let input = """
        import Foundation

        struct Foo {
            fileprivate var foo = "foo"
        }
        """
        let output = """
        import Foundation

        struct Foo {
            private var foo = "foo"
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateVarNotChangedToPrivateIfAccessedFromAnotherType() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        struct Bar {
            func bar() {
                print(Foo().foo)
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateVarNotChangedToPrivateIfAccessedFromSubclass() {
        let input = """
        class Foo {
            fileprivate func foo() {}
        }

        class Bar: Foo {
            func bar() {
                return foo()
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateVarNotChangedToPrivateIfAccessedFromAFunction() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        func getFoo() -> String {
            return Foo().foo
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateVarNotChangedToPrivateIfAccessedFromAConstant() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        let kFoo = Foo().foo
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateVarNotChangedToPrivateIfAccessedFromAVar() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        var kFoo: String { return Foo().foo }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateVarNotChangedToPrivateIfAccessedFromCode() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        print(Foo().foo)
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateVarNotChangedToPrivateIfAccessedFromAClosure() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        print({ Foo().foo }())
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateVarNotChangedToPrivateIfAccessedFromAnExtensionOnAnotherType() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        extension Bar {
            func bar() {
                print(Foo().foo)
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateVarChangedToPrivateIfAccessedFromAnExtensionOnSameType() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        extension Foo {
            func bar() {
                print(foo)
            }
        }
        """
        let output = """
        struct Foo {
            private let foo = "foo"
        }

        extension Foo {
            func bar() {
                print(foo)
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateVarChangedToPrivateIfAccessedViaSelfFromAnExtensionOnSameType() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        extension Foo {
            func bar() {
                print(self.foo)
            }
        }
        """
        let output = """
        struct Foo {
            private let foo = "foo"
        }

        extension Foo {
            func bar() {
                print(self.foo)
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: FormatRules.redundantFileprivate, options: options,
                       exclude: ["redundantSelf"])
    }

    func testFileprivateMultiLetNotChangedToPrivateIfAccessedOutsideType() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo", bar = "bar"
        }

        extension Foo {
            func bar() {
                print(foo)
            }
        }

        extension Bar {
            func bar() {
                print(Foo().bar)
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateInitChangedToPrivateIfConstructorNotCalledOutsideType() {
        let input = """
        struct Foo {
            fileprivate init() {}
        }
        """
        let output = """
        struct Foo {
            private init() {}
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateInitNotChangedToPrivateIfConstructorCalledOutsideType() {
        let input = """
        struct Foo {
            fileprivate init() {}
        }

        let foo = Foo()
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateInitNotChangedToPrivateIfConstructorCalledOutsideType2() {
        let input = """
        class Foo {
            fileprivate init() {}
        }

        struct Bar {
            let foo = Foo()
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateStructMemberNotChangedToPrivateIfConstructorCalledOutsideType() {
        let input = """
        struct Foo {
            fileprivate let bar: String
        }

        let foo = Foo(bar: "test")
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateClassMemberChangedToPrivateEvenIfConstructorCalledOutsideType() {
        let input = """
        class Foo {
            fileprivate let bar: String
        }

        let foo = Foo()
        """
        let output = """
        class Foo {
            private let bar: String
        }

        let foo = Foo()
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateExtensionFuncNotChangedToPrivateIfPartOfProtocolConformance() {
        let input = """
        private class Foo: Equatable {
            fileprivate static func == (_: Foo, _: Foo) -> Bool {
                return true
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateInnerTypeNotChangedToPrivate() {
        let input = """
        struct Foo {
            fileprivate enum Bar {
                case a, b
            }

            fileprivate let bar: Bar
        }

        func foo(foo: Foo) {
            print(foo.bar)
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateClassTypeMemberNotChangedToPrivate() {
        let input = """
        class Foo {
            fileprivate class var bar = "bar"
        }

        func foo() {
            print(Foo.bar)
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testOverriddenFileprivateInitNotChangedToPrivate() {
        let input = """
        class Foo {
            fileprivate init() {}
        }

        class Bar: Foo, Equatable {
            override public init() {
                super.init()
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testNonOverriddenFileprivateInitChangedToPrivate() {
        let input = """
        class Foo {
            fileprivate init() {}
        }

        class Bar: Baz {
            override public init() {
                super.init()
            }
        }
        """
        let output = """
        class Foo {
            private init() {}
        }

        class Bar: Baz {
            override public init() {
                super.init()
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateInitNotChangedToPrivateWhenUsingTypeInferredInits() {
        let input = """
        struct Example {
            fileprivate init() {}
        }

        enum Namespace {
            static let example: Example = .init()
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
    }

    // MARK: - yodaConditions

    func testNumericLiteralEqualYodaCondition() {
        let input = "5 == foo"
        let output = "foo == 5"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNumericLiteralGreaterYodaCondition() {
        let input = "5.1 > foo"
        let output = "foo < 5.1"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testStringLiteralNotEqualYodaCondition() {
        let input = "\"foo\" != foo"
        let output = "foo != \"foo\""
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNilNotEqualYodaCondition() {
        let input = "nil != foo"
        let output = "foo != nil"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testTrueNotEqualYodaCondition() {
        let input = "true != foo"
        let output = "foo != true"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testEnumCaseNotEqualYodaCondition() {
        let input = ".foo != foo"
        let output = "foo != .foo"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testArrayLiteralNotEqualYodaCondition() {
        let input = "[5, 6] != foo"
        let output = "foo != [5, 6]"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNestedArrayLiteralNotEqualYodaCondition() {
        let input = "[5, [6, 7]] != foo"
        let output = "foo != [5, [6, 7]]"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testDictionaryLiteralNotEqualYodaCondition() {
        let input = "[foo: 5, bar: 6] != foo"
        let output = "foo != [foo: 5, bar: 6]"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testSubscriptNotTreatedAsYodaCondition() {
        let input = "foo[5] != bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testSubscriptOfParenthesizedExpressionNotTreatedAsYodaCondition() {
        let input = "(foo + bar)[5] != baz"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testSubscriptOfUnwrappedValueNotTreatedAsYodaCondition() {
        let input = "foo![5] != bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testSubscriptOfExpressionWithInlineCommentNotTreatedAsYodaCondition() {
        let input = "foo /* foo */ [5] != bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testSubscriptOfCollectionNotTreatedAsYodaCondition() {
        let input = "[foo][5] != bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testSubscriptOfTrailingClosureNotTreatedAsYodaCondition() {
        let input = "foo { [5] }[0] != bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testSubscriptOfRhsNotMangledInYodaCondition() {
        let input = "[1] == foo[0]"
        let output = "foo[0] == [1]"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testTupleYodaCondition() {
        let input = "(5, 6) != bar"
        let output = "bar != (5, 6)"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testLabeledTupleYodaCondition() {
        let input = "(foo: 5, bar: 6) != baz"
        let output = "baz != (foo: 5, bar: 6)"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNestedTupleYodaCondition() {
        let input = "(5, (6, 7)) != baz"
        let output = "baz != (5, (6, 7))"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testFunctionCallNotTreatedAsYodaCondition() {
        let input = "foo(5) != bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testCallOfParenthesizedExpressionNotTreatedAsYodaCondition() {
        let input = "(foo + bar)(5) != baz"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testCallOfUnwrappedValueNotTreatedAsYodaCondition() {
        let input = "foo!(5) != bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testCallOfExpressionWithInlineCommentNotTreatedAsYodaCondition() {
        let input = "foo /* foo */ (5) != bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testCallOfRhsNotMangledInYodaCondition() {
        let input = "(1, 2) == foo(0)"
        let output = "foo(0) == (1, 2)"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testTrailingClosureOnRhsNotMangledInYodaCondition() {
        let input = "(1, 2) == foo { $0 }"
        let output = "foo { $0 } == (1, 2)"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testYodaConditionInIfStatement() {
        let input = "if 5 != foo {}"
        let output = "if foo != 5 {}"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testSubscriptYodaConditionInIfStatementWithBraceOnNextLine() {
        let input = "if [0] == foo.bar[0]\n{ baz() }"
        let output = "if foo.bar[0] == [0]\n{ baz() }"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testYodaConditionInSecondClauseOfIfStatement() {
        let input = "if foo, 5 != bar {}"
        let output = "if foo, bar != 5 {}"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testYodaConditionInExpression() {
        let input = "let foo = 5 < bar\nbaz()"
        let output = "let foo = bar > 5\nbaz()"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testYodaConditionInExpressionWithTrailingClosure() {
        let input = "let foo = 5 < bar { baz() }"
        let output = "let foo = bar { baz() } > 5"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testYodaConditionInFunctionCall() {
        let input = "foo(5 < bar)"
        let output = "foo(bar > 5)"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testYodaConditionFollowedByExpression() {
        let input = "5 == foo + 6"
        let output = "foo + 6 == 5"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testPrefixExpressionYodaCondition() {
        let input = "!false == foo"
        let output = "foo == !false"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testPrefixExpressionYodaCondition2() {
        let input = "true == !foo"
        let output = "!foo == true"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testPostfixExpressionYodaCondition() {
        let input = "5<*> == foo"
        let output = "foo == 5<*>"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testDoublePostfixExpressionYodaCondition() {
        let input = "5!! == foo"
        let output = "foo == 5!!"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testPostfixExpressionNonYodaCondition() {
        let input = "5 == 5<*>"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testPostfixExpressionNonYodaCondition2() {
        let input = "5<*> == 5"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testStringEqualsStringNonYodaCondition() {
        let input = "\"foo\" == \"bar\""
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testConstantAfterNullCoalescingNonYodaCondition() {
        let input = "foo.last ?? -1 < bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testNoMangleYodaConditionFollowedByAndOperator() {
        let input = "5 <= foo && foo <= 7"
        let output = "foo >= 5 && foo <= 7"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNoMangleYodaConditionFollowedByOrOperator() {
        let input = "5 <= foo || foo <= 7"
        let output = "foo >= 5 || foo <= 7"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNoMangleYodaConditionFollowedByParentheses() {
        let input = "0 <= (foo + bar)"
        let output = "(foo + bar) >= 0"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNoMangleYodaConditionInTernary() {
        let input = "let z = 0 < y ? 3 : 4"
        let output = "let z = y > 0 ? 3 : 4"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNoMangleYodaConditionInTernary2() {
        let input = "let z = y > 0 ? 0 < x : 4"
        let output = "let z = y > 0 ? x > 0 : 4"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNoMangleYodaConditionInTernary3() {
        let input = "let z = y > 0 ? 3 : 0 < x"
        let output = "let z = y > 0 ? 3 : x > 0"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testKeyPathNotMangledAndNotTreatedAsYodaCondition() {
        let input = "\\.foo == bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testEnumCaseLessThanEnumCase() {
        let input = "XCTAssertFalse(.never < .never)"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    // MARK: - leadingDelimiters

    func testLeadingCommaMovedToPreviousLine() {
        let input = """
        let foo = 5
            , bar = 6
        """
        let output = """
        let foo = 5,
            bar = 6
        """
        testFormatting(for: input, output, rule: FormatRules.leadingDelimiters)
    }

    func testLeadingColonFollowedByCommentMovedToPreviousLine() {
        let input = """
        let foo
            : /* string */ String
        """
        let output = """
        let foo:
            /* string */ String
        """
        testFormatting(for: input, output, rule: FormatRules.leadingDelimiters)
    }

    func testCommaMovedBeforeCommentIfLineEndsInComment() {
        let input = """
        let foo = 5 // first
            , bar = 6
        """
        let output = """
        let foo = 5, // first
            bar = 6
        """
        testFormatting(for: input, output, rule: FormatRules.leadingDelimiters)
    }
}
