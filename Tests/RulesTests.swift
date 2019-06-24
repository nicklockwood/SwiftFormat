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
    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS)
            let thisClass = type(of: self)
            let linuxCount = thisClass.__allTests.count
            let darwinCount = thisClass.defaultTestSuite.testCaseCount
            XCTAssertEqual(linuxCount, darwinCount, "run swift test --generate-linuxmain")
        #endif
    }

    // MARK: spaceAroundParens

    func testSpaceAfterSet() {
        let input = "private(set)var foo: Int"
        let output = "private(set) var foo: Int"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testAddSpaceBetweenParenAndClass() {
        let input = "@objc(XYZFoo)class foo"
        let output = "@objc(XYZFoo) class foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSpaceBetweenParenAndClass() {
        let input = "@objc(XYZFoo) class foo"
        let output = "@objc(XYZFoo) class foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testAddSpaceBetweenConventionAndBlock() {
        let input = "@convention(block)() -> Void"
        let output = "@convention(block) () -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSpaceBetweenConventionAndBlock() {
        let input = "@convention(block) () -> Void"
        let output = "@convention(block) () -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testAddSpaceBetweenConventionAndEscaping() {
        let input = "@convention(block)@escaping () -> Void"
        let output = "@convention(block) @escaping () -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSpaceBetweenConventionAndEscaping() {
        let input = "@convention(block) @escaping () -> Void"
        let output = "@convention(block) @escaping () -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testAddSpaceBetweenAutoclosureEscapingAndBlock() { // swift 2.3 only
        let input = "@autoclosure(escaping)() -> Void"
        let output = "@autoclosure(escaping) () -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceBetweenParenAndAs() {
        let input = "(foo.bar) as? String"
        let output = "(foo.bar) as? String"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["redundantParens"])), output + "\n")
    }

    func testNoSpaceAfterParenAtEndOfFile() {
        let input = "(foo.bar)"
        let output = "(foo.bar)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["redundantParens"])), output + "\n")
    }

    func testSpaceBetweenParenAndFoo() {
        let input = "func foo ()"
        let output = "func foo()"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceBetweenParenAndInit() {
        let input = "init ()"
        let output = "init()"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceBetweenObjcAndSelector() {
        let input = "@objc (XYZFoo) class foo"
        let output = "@objc(XYZFoo) class foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceBetweenHashSelectorAndBrace() {
        let input = "#selector(foo)"
        let output = "#selector(foo)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceBetweenHashKeyPathAndBrace() {
        let input = "#keyPath (foo.bar)"
        let output = "#keyPath(foo.bar)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceBetweenHashAvailableAndBrace() {
        let input = "#available (iOS 9.0, *)"
        let output = "#available(iOS 9.0, *)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens, FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceBetweenPrivateAndSet() {
        let input = "private (set) var foo: Int"
        let output = "private(set) var foo: Int"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceBetweenLetAndTuple() {
        let input = "if let (foo, bar) = baz"
        let output = "if let (foo, bar) = baz"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceBetweenIfAndCondition() {
        let input = "if(a || b) == true {}"
        let output = "if (a || b) == true {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceBetweenArrayLiteralAndParen() {
        let input = "[String] ()"
        let output = "[String]()"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSpaceBetweenCaptureListAndArguments() {
        let input = "{ [weak self] (foo) in print(foo) }"
        let output = "{ [weak self] (foo) in print(foo) }"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        let rules = FormatRules.all(except: ["redundantParens"])
        XCTAssertEqual(try format(input + "\n", rules: rules), output + "\n")
    }

    func testNoRemoveSpaceBetweenCaptureListAndArguments2() {
        let input = "{ [weak self] () -> Void in }"
        let output = "{ [weak self] () -> Void in }"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSpaceBetweenCaptureListAndArguments3() {
        let input = "{ [weak self] () throws -> Void in }"
        let output = "{ [weak self] () throws -> Void in }"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testAddSpaceBetweenCaptureListAndArguments() {
        let input = "{ [weak self](foo) in print(foo) }"
        let output = "{ [weak self] (foo) in print(foo) }"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        let rules = FormatRules.all(except: ["redundantParens"])
        XCTAssertEqual(try format(input + "\n", rules: rules), output + "\n")
    }

    func testAddSpaceBetweenBetweenCaptureListAndArguments2() {
        let input = "{ [weak self]() -> Void in }"
        let output = "{ [weak self] () -> Void in }"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testAddSpaceBetweenBetweenCaptureListAndArguments3() {
        let input = "{ [weak self]() throws -> Void in }"
        let output = "{ [weak self] () throws -> Void in }"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceBetweenClosingParenAndOpenBrace() {
        let input = "func foo(){ foo }"
        let output = "func foo() { foo }"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceBetweenClosingBraceAndParens() {
        let input = "{ block } ()"
        let output = "{ block }()"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testDontRemoveSpaceBetweenOpeningBraceAndParens() {
        let input = "a = (b + c)"
        let output = "a = (b + c)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testKeywordAsIdentifierParensSpacing() {
        let input = "if foo.let (foo, bar)"
        let output = "if foo.let(foo, bar)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceAfterInoutParam() {
        let input = "func foo(bar _: inout(Int, String)) {}"
        let output = "func foo(bar _: inout (Int, String)) {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceAfterEscapingAttribute() {
        let input = "func foo(bar: @escaping() -> Void)"
        let output = "func foo(bar: @escaping () -> Void)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceAfterAutoclosureAttribute() {
        let input = "func foo(bar: @autoclosure () -> Void)"
        let output = "func foo(bar: @autoclosure () -> Void)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceBeforeTupleIndexArgument() {
        let input = "foo.1 (true)"
        let output = "foo.1(true)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: spaceInsideParens

    func testSpaceInsideParens() {
        let input = "( 1, ( 2, 3 ) )"
        let output = "(1, (2, 3))"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceBeforeCommentInsideParens() {
        let input = "( /* foo */ 1, 2 )"
        let output = "( /* foo */ 1, 2)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: spaceAroundBrackets

    func testSubscriptNoAddSpacing() {
        let input = "foo[bar] = baz"
        let output = "foo[bar] = baz"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBrackets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSubscriptRemoveSpacing() {
        let input = "foo [bar] = baz"
        let output = "foo[bar] = baz"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBrackets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testArrayLiteralSpacing() {
        let input = "foo = [bar, baz]"
        let output = "foo = [bar, baz]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBrackets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testAsArrayCastingSpacing() {
        let input = "foo as[String]"
        let output = "foo as [String]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBrackets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testAsOptionalArrayCastingSpacing() {
        let input = "foo as? [String]"
        let output = "foo as? [String]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBrackets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIsArrayTestingSpacing() {
        let input = "if foo is[String]"
        let output = "if foo is [String]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBrackets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testKeywordAsIdentifierBracketSpacing() {
        let input = "if foo.is[String]"
        let output = "if foo.is[String]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBrackets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceBeforeTupleIndexSubscript() {
        let input = "foo.1 [2]"
        let output = "foo.1[2]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBrackets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: spaceInsideBrackets

    func testSpaceInsideBrackets() {
        let input = "foo[ 5 ]"
        let output = "foo[5]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideBrackets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceInsideWrappedArray() {
        let input = "[ foo,\n bar ]"
        let output = "[foo,\n bar]"
        let options = FormatOptions(wrapCollections: .disabled)
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideBrackets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testSpaceBeforeCommentInsideWrappedArray() {
        let input = "[ // foo\n    bar,\n]"
        let output = "[ // foo\n    bar,\n]"
        let options = FormatOptions(wrapCollections: .disabled)
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideBrackets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // MARK: spaceAroundBraces

    func testSpaceAroundTrailingClosure() {
        let input = "if x{ y }else{ z }"
        let output = "if x { y } else { z }"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBraces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceAroundClosureInsiderParens() {
        let input = "foo({ $0 == 5 })"
        let output = "foo({ $0 == 5 })"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBraces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["trailingClosures"])), output + "\n")
    }

    func testNoExtraSpaceAroundBracesAtStartOrEndOfFile() {
        let input = "{ foo }"
        let output = "{ foo }"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBraces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceAroundBracesAfterOptionalProperty() {
        let input = "var: Foo?{}"
        let output = "var: Foo? {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBraces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceAroundBracesAfterImplicitlyUnwrappedProperty() {
        let input = "var: Foo!{}"
        let output = "var: Foo! {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBraces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceAroundBracesAfterNumber() {
        let input = "if x = 5{}"
        let output = "if x = 5 {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBraces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceAroundBracesAfterString() {
        let input = "if x = \"\"{}"
        let output = "if x = \"\" {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundBraces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: spaceInsideBraces

    func testSpaceInsideBraces() {
        let input = "foo({bar})"
        let output = "foo({ bar })"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideBraces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["trailingClosures"])), output + "\n")
    }

    func testNoExtraSpaceInsidebraces() {
        let input = "{ foo }"
        let output = "{ foo }"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideBraces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceInsideEmptybraces() {
        let input = "foo({ })"
        let output = "foo({})"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideBraces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["trailingClosures"])), output + "\n")
    }

    // MARK: spaceAroundGenerics

    func testSpaceAroundGenerics() {
        let input = "Foo <Bar <Baz>>"
        let output = "Foo<Bar<Baz>>"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundGenerics]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: spaceInsideGenerics

    func testSpaceInsideGenerics() {
        let input = "Foo< Bar< Baz > >"
        let output = "Foo<Bar<Baz>>"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideGenerics]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: spaceAroundOperators

    func testSpaceAfterColon() {
        let input = "let foo:Bar = 5"
        let output = "let foo: Bar = 5"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceBetweenOptionalAndDefaultValue() {
        let input = "let foo: String?=nil"
        let output = "let foo: String? = nil"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceBetweenImplictlyUnwrappedOptionalAndDefaultValue() {
        let input = "let foo: String!=nil"
        let output = "let foo: String! = nil"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceBetweenOptionalTryAndDot() {
        let input = "let foo: Int = try? .init()"
        let output = "let foo: Int = try? .init()"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceBetweenForceTryAndDot() {
        let input = "let foo: Int = try! .init()"
        let output = "let foo: Int = try! .init()"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceBetweenOptionalAndDefaultValueInFunction() {
        let input = "func foo(bar _: String?=nil) {}"
        let output = "func foo(bar _: String? = nil) {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceAddedAfterColonInSelector() {
        let input = "@objc(foo:bar:)"
        let output = "@objc(foo:bar:)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceAfterColonInSwitchCase() {
        let input = "switch x { case .y:break }"
        let output = "switch x { case .y: break }"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceAfterColonInSwitchDefault() {
        let input = "switch x { default:break }"
        let output = "switch x { default: break }"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceAfterComma() {
        let input = "let foo = [1,2,3]"
        let output = "let foo = [1, 2, 3]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceBetweenColonAndEnumValue() {
        let input = "[.Foo:.Bar]"
        let output = "[.Foo: .Bar]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceBetweenCommaAndEnumValue() {
        let input = "[.Foo,.Bar]"
        let output = "[.Foo, .Bar]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceBetweenSemicolonAndEnumValue() {
        let input = "statement;.Bar"
        let output = "statement; .Bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceBetweenEqualsAndEnumValue() {
        let input = "foo = .Bar"
        let output = "foo = .Bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceBeforeColon() {
        let input = "let foo : Bar = 5"
        let output = "let foo: Bar = 5"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceBeforeColonInTernary() {
        let input = "foo ? bar : baz"
        let output = "foo ? bar : baz"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testTernaryOfEnumValues() {
        let input = "foo ? .Bar : .Baz"
        let output = "foo ? .Bar : .Baz"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceBeforeColonInNestedTernary() {
        let input = "foo ? (hello + a ? b: c) : baz"
        let output = "foo ? (hello + a ? b : c) : baz"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceBeforeComma() {
        let input = "let foo = [1 , 2 , 3]"
        let output = "let foo = [1, 2, 3]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceAtStartOfLine() {
        let input = "foo\n    ,bar"
        let output = "foo\n    , bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["leadingDelimiters"])), output + "\n")
    }

    func testSpaceAroundInfixMinus() {
        let input = "foo-bar"
        let output = "foo - bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceAroundPrefixMinus() {
        let input = "foo + -bar"
        let output = "foo + -bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceAroundLessThan() {
        let input = "foo<bar"
        let output = "foo < bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testDontAddSpaceAroundDot() {
        let input = "foo.bar"
        let output = "foo.bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveSpaceAroundDot() {
        let input = "foo . bar"
        let output = "foo.bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceAroundDotOnNewLine() {
        let input = "foo\n    .bar"
        let output = "foo\n    .bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceAroundEnumCase() {
        let input = "case .Foo,.Bar:"
        let output = "case .Foo, .Bar:"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSwitchWithEnumCases() {
        let input = "switch x {\ncase.Foo:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\ncase .Foo:\n    break\ndefault:\n    break\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceAroundEnumReturn() {
        let input = "return.Foo"
        let output = "return .Foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceAfterReturnAsIdentifier() {
        let input = "foo.return.Bar"
        let output = "foo.return.Bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceAroundCaseLet() {
        let input = "case let.Foo(bar):"
        let output = "case let .Foo(bar):"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceAroundEnumArgument() {
        let input = "foo(with:.Bar)"
        let output = "foo(with: .Bar)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceBeforeEnumCaseInsideClosure() {
        let input = "{ .bar() }"
        let output = "{ .bar() }"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceAroundMultipleOptionalChaining() {
        let input = "foo??!?!.bar"
        let output = "foo??!?!.bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceAroundForcedChaining() {
        let input = "foo!.bar"
        let output = "foo!.bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceAddedInOptionalChaining() {
        let input = "foo?.bar"
        let output = "foo?.bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceRemovedInOptionalChaining() {
        let input = "foo? .bar"
        let output = "foo?.bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceRemovedInForcedChaining() {
        let input = "foo! .bar"
        let output = "foo!.bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceRemovedInMultipleOptionalChaining() {
        let input = "foo??! .bar"
        let output = "foo??!.bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceAfterOptionalInsideTernary() {
        let input = "x ? foo? .bar() : bar?.baz()"
        let output = "x ? foo?.bar() : bar?.baz()"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSplitLineOptionalChaining() {
        let input = "foo?\n    .bar"
        let output = "foo?\n    .bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSplitLineMultipleOptionalChaining() {
        let input = "foo??!\n    .bar"
        let output = "foo??!\n    .bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceBetweenNullCoalescingAndDot() {
        let input = "foo ?? .bar()"
        let output = "foo ?? .bar()"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceAroundFailableInit() {
        let input = "init?()"
        let output = "init?()"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceAroundImplictlyUnwrappedFailableInit() {
        let input = "init!()"
        let output = "init!()"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceAroundFailableInitWithGenerics() {
        let input = "init?<T>()"
        let output = "init?<T>()"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceAroundImplictlyUnwrappedFailableInitWithGenerics() {
        let input = "init!<T>()"
        let output = "init!<T>()"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceAfterOptionalAs() {
        let input = "foo as?[String]"
        let output = "foo as? [String]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceAfterForcedAs() {
        let input = "foo as![String]"
        let output = "foo as! [String]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceAroundGenerics() {
        let input = "Foo<String>"
        let output = "Foo<String>"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceAroundReturnTypeArrow() {
        let input = "foo() ->Bool"
        let output = "foo() -> Bool"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testPrefixMinusBeforeMember() {
        let input = "-.foo"
        let output = "-.foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testPostfixMinusBeforeMember() {
        let input = "foo-.bar"
        let output = "foo-.bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoInsertSpaceBeforeNegativeIndex() {
        let input = "foo[-bar]"
        let output = "foo[-bar]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveSpaceBeforeNegativeIndex() {
        let input = "foo[ -bar]"
        let output = "foo[-bar]"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoInsertSpaceBeforeUnlabelledAddressArgument() {
        let input = "foo(&bar)"
        let output = "foo(&bar)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveSpaceBeforeUnlabelledAddressArgument() {
        let input = "foo( &bar, baz: &baz)"
        let output = "foo(&bar, baz: &baz)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveSpaceBeforeKeyPath() {
        let input = "foo( \\.bar)"
        let output = "foo(\\.bar)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testAddSpaceAfterFuncEquals() {
        let input = "func ==(lhs: Int, rhs: Int) -> Bool { return lhs === rhs }"
        let output = "func == (lhs: Int, rhs: Int) -> Bool { return lhs === rhs }"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSpaceAfterFuncEquals() {
        let input = "func == (lhs: Int, rhs: Int) -> Bool { return lhs === rhs }"
        let output = "func == (lhs: Int, rhs: Int) -> Bool { return lhs === rhs }"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveSpaceAfterFuncEquals() {
        let input = "func == (lhs: Int, rhs: Int) -> Bool { return lhs === rhs }"
        let output = "func ==(lhs: Int, rhs: Int) -> Bool { return lhs === rhs }"
        let options = FormatOptions(spaceAroundOperatorDeclarations: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoAddSpaceAfterFuncEquals() {
        let input = "func ==(lhs: Int, rhs: Int) -> Bool { return lhs === rhs }"
        let output = "func ==(lhs: Int, rhs: Int) -> Bool { return lhs === rhs }"
        let options = FormatOptions(spaceAroundOperatorDeclarations: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testAddSpaceAfterOperatorEquals() {
        let input = "operator =={}"
        let output = "operator == {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSpaceAfterOperatorEquals() {
        let input = "operator == {}"
        let output = "operator == {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSpaceAfterOperatorEqualsWhenSpaceAroundOperatorDeclarationsFalse() {
        let input = "operator == {}"
        let output = "operator == {}"
        let options = FormatOptions(spaceAroundOperatorDeclarations: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoAddSpaceAfterOperatorEqualsWithAllmanBrace() {
        let input = "operator ==\n{}"
        let output = "operator ==\n{}"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
    }

    func testNoAddSpaceAroundOperatorInsideParens() {
        let input = "(!=)"
        let output = "(!=)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["redundantParens"])), output + "\n")
    }

    func testSpaceAroundPlusBeforeHash() {
        let input = "\"foo.\"+#file"
        let output = "\"foo.\" + #file"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundOperators]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: spaceAroundComments

    func testSpaceAroundCommentInParens() {
        let input = "(/* foo */)"
        let output = "( /* foo */ )"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["redundantParens"])), output + "\n")
    }

    func testNoSpaceAroundCommentAtStartAndEndOfFile() {
        let input = "/* foo */"
        let output = "/* foo */"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceAroundCommentBeforeComma() {
        let input = "(foo /* foo */ , bar)"
        let output = "(foo /* foo */, bar)"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceAroundSingleLineComment() {
        let input = "func foo() {// comment\n}"
        let output = "func foo() { // comment\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceAroundComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: spaceInsideComments

    func testSpaceInsideMultilineComment() {
        let input = "/*foo\n bar*/"
        let output = "/* foo\n bar */"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceInsideSingleLineMultilineComment() {
        let input = "/*foo*/"
        let output = "/* foo */"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceInsideEmptyMultilineComment() {
        let input = "/**/"
        let output = "/**/"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceInsideSingleLineComment() {
        let input = "//foo"
        let output = "// foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceInsideMultilineHeaderdocComment() {
        let input = "/**foo\n bar*/"
        let output = "/** foo\n bar */"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceInsideMultilineHeaderdocCommentType2() {
        let input = "/*!foo\n bar*/"
        let output = "/*! foo\n bar */"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceInsideMultilineSwiftPlaygroundDocComment() {
        let input = "/*:foo\n bar*/"
        let output = "/*: foo\n bar */"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoExtraSpaceInsideMultilineHeaderdocComment() {
        let input = "/** foo\n bar */"
        let output = "/** foo\n bar */"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoExtraSpaceInsideMultilineHeaderdocCommentType2() {
        let input = "/*! foo\n bar */"
        let output = "/*! foo\n bar */"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoExtraSpaceInsideMultilineSwiftPlaygroundDocComment() {
        let input = "/*: foo\n bar */"
        let output = "/*: foo\n bar */"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoExtraSpaceInsideSingleLineSwiftPlaygroundDocComment() {
        let input = "//: Playground"
        let output = "//: Playground"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceInsideSingleLineHeaderdocComment() {
        let input = "///foo"
        let output = "/// foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceInsideSingleLineHeaderdocCommentType2() {
        let input = "//!foo"
        let output = "//! foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceInsideSingleLineSwiftPlaygroundDocComment() {
        let input = "//:foo"
        let output = "//: foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoExtraSpaceInsideSingleLineHeaderdocComment() {
        let input = "/// foo"
        let output = "/// foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testPreformattedMultilineComment() {
        let input = "/*********************\n *****Hello World*****\n *********************/"
        let output = "/*********************\n *****Hello World*****\n *********************/"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceAddedToFirstLineOfDocComment() {
        let input = "/**\n Comment\n */"
        let output = "/**\n Comment\n */"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceAddedToEmptyDocComment() {
        let input = "///"
        let output = "///"
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoSpaceAddedInsideXCUITestCommentTokens() {
        let input = """
        XCUIApplication()/*@START_MENU_TOKEN@*/.buttons["Button"]/*[[".buttons[\"Button\"]",".buttons[\"buttonId\"]"],[[[-1,1],[-1,0]]],[1]]@END_MENU_TOKEN@*/.tap()
        """
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.spaceInsideComments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: consecutiveSpaces

    func testConsecutiveSpaces() {
        let input = "let foo  = bar"
        let output = "let foo = bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.consecutiveSpaces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testConsecutiveSpacesAfterComment() {
        let input = "// comment\nfoo  bar"
        let output = "// comment\nfoo bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.consecutiveSpaces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testConsecutiveSpacesDoesntStripIndent() {
        let input = "{\n    let foo  = bar\n}"
        let output = "{\n    let foo = bar\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.consecutiveSpaces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testConsecutiveSpacesDoesntAffectMultilineComments() {
        let input = "/*    comment  */"
        let output = "/*    comment  */"
        XCTAssertEqual(try format(input, rules: [FormatRules.consecutiveSpaces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testConsecutiveSpacesDoesntAffectNestedMultilineComments() {
        let input = "/*  foo  /*  bar  */  baz  */"
        let output = "/*  foo  /*  bar  */  baz  */"
        XCTAssertEqual(try format(input, rules: [FormatRules.consecutiveSpaces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testConsecutiveSpacesDoesntAffectSingleLineComments() {
        let input = "//    foo  bar"
        let output = "//    foo  bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.consecutiveSpaces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: trailingSpace

    // truncateBlankLines = true

    func testTrailingSpace() {
        let input = "foo  \nbar"
        let output = "foo\nbar"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingSpace]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testTrailingSpaceAtEndOfFile() {
        let input = "foo  "
        let output = "foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingSpace]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testTrailingSpaceInMultilineComments() {
        let input = "/* foo  \n bar  */"
        let output = "/* foo\n bar  */"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingSpace]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testTrailingSpaceInSingleLineComments() {
        let input = "// foo  \n// bar  "
        let output = "// foo\n// bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingSpace]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testTruncateBlankLine() {
        let input = "foo {\n    // bar\n    \n    // baz\n}"
        let output = "foo {\n    // bar\n\n    // baz\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingSpace]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testTrailingSpaceInArray() {
        let input = "let foo = [\n    1,\n    \n    2,\n]"
        let output = "let foo = [\n    1,\n\n    2,\n]"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingSpace]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["redundantSelf"])), output + "\n")
    }

    // truncateBlankLines = false

    func testNoTruncateBlankLine() {
        let input = "foo {\n    // bar\n    \n    // baz\n}"
        let output = "foo {\n    // bar\n    \n    // baz\n}"
        let options = FormatOptions(truncateBlankLines: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingSpace], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // MARK: consecutiveBlankLines

    func testConsecutiveBlankLines() {
        let input = "foo\n   \n\nbar"
        let output = "foo\n\nbar"
        XCTAssertEqual(try format(input, rules: [FormatRules.consecutiveBlankLines]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testConsecutiveBlankLinesAtEndOfFile() {
        let input = "foo\n\n"
        let output = "foo\n"
        XCTAssertEqual(try format(input, rules: [FormatRules.consecutiveBlankLines]), output)
        XCTAssertEqual(try format(input, rules: FormatRules.all), output)
    }

    func testConsecutiveBlankLinesAtStartOfFile() {
        let input = "\n\n\nfoo"
        let output = "\n\nfoo"
        XCTAssertEqual(try format(input, rules: [FormatRules.consecutiveBlankLines]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testConsecutiveBlankLinesInsideStringLiteral() {
        let input = "\"\"\"\nhello\n\n\nworld\n\"\"\""
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.consecutiveBlankLines]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testFragmentWithTrailingLinebreaks() {
        let input = "func foo() {}\n\n\n"
        let output = "func foo() {}\n\n"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.consecutiveBlankLines], options: options), output)
        XCTAssertEqual(try format(input, rules: FormatRules.all, options: options), output)
    }

    // MARK: blankLinesAtStartOfScope

    func testBlankLinesRemovedAtStartOfFunction() {
        let input = "func foo() {\n\n    // code\n}"
        let output = "func foo() {\n    // code\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesAtStartOfScope]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testBlankLinesRemovedAtStartOfParens() {
        let input = "(\n\n    foo: Int\n)"
        let output = "(\n    foo: Int\n)"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesAtStartOfScope]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testBlankLinesRemovedAtStartOfBrackets() {
        let input = "[\n\n    foo,\n    bar,\n]"
        let output = "[\n    foo,\n    bar,\n]"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesAtStartOfScope]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testBlankLinesNotRemovedBetweenElementsInsideBrackets() {
        let input = "[foo,\n\n bar]"
        let output = "[foo,\n\n bar]"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesAtStartOfScope]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["wrapArguments"])), output + "\n")
    }

    // MARK: blankLinesAtEndOfScope

    func testBlankLinesRemovedAtEndOfFunction() {
        let input = "func foo() {\n    // code\n\n}"
        let output = "func foo() {\n    // code\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesAtEndOfScope]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testBlankLinesRemovedAtEndOfParens() {
        let input = "(\n    foo: Int\n\n)"
        let output = "(\n    foo: Int\n)"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesAtEndOfScope]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testBlankLinesRemovedAtEndOfBrackets() {
        let input = "[\n    foo,\n    bar,\n\n]"
        let output = "[\n    foo,\n    bar,\n]"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesAtEndOfScope]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testBlankLineNotRemovedBeforeElse() {
        let input = "if x {\n\n    // do something\n\n} else if y {\n\n    // do something else\n\n}"
        let output = "if x {\n\n    // do something\n\n} else if y {\n\n    // do something else\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesAtEndOfScope]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["blankLinesAtStartOfScope"])), output + "\n")
    }

    // MARK: blankLinesBetweenScopes

    func testBlankLineBetweenFunctions() {
        let input = "func foo() {\n}\nfunc bar() {\n}"
        let output = "func foo() {\n}\n\nfunc bar() {\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["emptyBraces"])), output + "\n")
    }

    func testNoBlankLineBetweenPropertyAndFunction() {
        let input = "var foo: Int\nfunc bar() {\n}"
        let output = "var foo: Int\nfunc bar() {\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["emptyBraces"])), output + "\n")
    }

    func testBlankLineBetweenFunctionsIsBeforeComment() {
        let input = "func foo() {\n}\n// headerdoc\nfunc bar() {\n}"
        let output = "func foo() {\n}\n\n// headerdoc\nfunc bar() {\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["emptyBraces"])), output + "\n")
    }

    func testBlankLineBeforeAtObjcOnLineBeforeProtocol() {
        let input = "@objc\nprotocol Foo {\n}\n@objc\nprotocol Bar {\n}"
        let output = "@objc\nprotocol Foo {\n}\n\n@objc\nprotocol Bar {\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["emptyBraces"])), output + "\n")
    }

    func testBlankLineBeforeAtAvailabilityOnLineBeforeClass() {
        let input = "protocol Foo {\n}\n@available(iOS 8.0, OSX 10.10, *)\nclass Bar {\n}"
        let output = "protocol Foo {\n}\n\n@available(iOS 8.0, OSX 10.10, *)\nclass Bar {\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["emptyBraces"])), output + "\n")
    }

    func testNoExtraBlankLineBetweenFunctions() {
        let input = "func foo() {\n}\n\nfunc bar() {\n}"
        let output = "func foo() {\n}\n\nfunc bar() {\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["emptyBraces"])), output + "\n")
    }

    func testNoBlankLineBetweenFunctionsInProtocol() {
        let input = "protocol Foo {\n    func bar() -> Void\n    func baz() -> Int\n}"
        let output = "protocol Foo {\n    func bar() -> Void\n    func baz() -> Int\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoBlankLineInsideInitFunction() {
        let input = "init() {\n    super.init()\n}"
        let output = "init() {\n    super.init()\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testBlankLineAfterProtocolBeforeProperty() {
        let input = "protocol Foo {\n}\nvar bar: String"
        let output = "protocol Foo {\n}\n\nvar bar: String"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["emptyBraces"])), output + "\n")
    }

    func testNoExtraBlankLineAfterSingleLineComment() {
        let input = "var foo: Bar? // comment\n\nfunc bar() {}"
        let output = "var foo: Bar? // comment\n\nfunc bar() {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoExtraBlankLineAfterMultilineComment() {
        let input = "var foo: Bar? /* comment */\n\nfunc bar() {}"
        let output = "var foo: Bar? /* comment */\n\nfunc bar() {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoBlankLineBeforeFuncAsIdentifier() {
        let input = "var foo: Bar?\nfoo.func(x) {}"
        let output = "var foo: Bar?\nfoo.func(x) {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoBlankLineBetweenFunctionsWithInlineBody() {
        let input = "class Foo {\n    func foo() { print(\"foo\") }\n    func bar() { print(\"bar\") }\n}"
        let output = "class Foo {\n    func foo() { print(\"foo\") }\n    func bar() { print(\"bar\") }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoBlankLineBetweenIfStatements() {
        let input = "func foo() {\n    if x {\n    }\n    if y {\n    }\n}"
        let output = "func foo() {\n    if x {\n    }\n    if y {\n    }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["emptyBraces"])), output + "\n")
    }

    func testNoBlanksInsideClassFunc() {
        let input = "class func foo {\n    if x {\n    }\n    if y {\n    }\n}"
        let output = "class func foo {\n    if x {\n    }\n    if y {\n    }\n}"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["emptyBraces"]), options: options), output + "\n")
    }

    func testNoBlanksInsideClassVar() {
        let input = "class var foo: Int {\n    if x {\n    }\n    if y {\n    }\n}"
        let output = "class var foo: Int {\n    if x {\n    }\n    if y {\n    }\n}"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["emptyBraces"]), options: options), output + "\n")
    }

    func testBlankLineBetweenCalledClosures() {
        let input = "class Foo {\n    var foo = {\n    }()\n    func bar {\n    }\n}"
        let output = "class Foo {\n    var foo = {\n    }()\n\n    func bar {\n    }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["emptyBraces"])), output + "\n")
    }

    func testNoBlankLineAfterCalledClosureAtEndOfScope() {
        let input = "class Foo {\n    var foo = {\n    }()\n}"
        let output = "class Foo {\n    var foo = {\n    }()\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["emptyBraces"])), output + "\n")
    }

    func testNoBlankLineBeforeWhileInRepeatWhile() {
        let input = "repeat\n{}\nwhile true\n{}()"
        let output = "repeat\n{}\nwhile true\n{}()"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testBlankLineBeforeWhileIfNotRepeatWhile() {
        let input = "func foo(x)\n{\n}\nwhile true\n{\n}"
        let output = "func foo(x)\n{\n}\n\nwhile true\n{\n}"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["emptyBraces"]), options: options), output + "\n")
    }

    // MARK: blankLinesAroundMark

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
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesAroundMark]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoInsertExtraBlankLinesAroundMark() {
        let input = """
        let foo = "foo"

        // MARK: bar

        let bar = "bar"
        """
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesAroundMark]), input)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), input + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesAroundMark]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesAroundMark]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoInsertBlankLineBeforeMarkAtStartOfScope() {
        let input = """
        do {
            // MARK: foo

            let foo = "foo"
        }
        """
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesAroundMark]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoInsertBlankLineAfterMarkAtEndOfScope() {
        let input = """
        do {
            let foo = "foo"

            // MARK: foo
        }
        """
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesAroundMark]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: linebreakAtEndOfFile

    func testLinebreakAtEndOfFile() {
        let input = "foo\nbar"
        let output = "foo\nbar\n"
        XCTAssertEqual(try format(input, rules: [FormatRules.linebreakAtEndOfFile]), output)
        XCTAssertEqual(try format(input, rules: FormatRules.all), output)
    }

    func testNoLinebreakAtEndOfFragment() {
        let input = "foo\nbar"
        let output = "foo\nbar"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.linebreakAtEndOfFile], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // MARK: indent

    // indent parens

    func testSimpleScope() {
        let input = "foo(\nbar\n)"
        let output = "foo(\n    bar\n)"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNestedScope() {
        let input = "foo(\nbar {\n}\n)"
        let output = "foo(\n    bar {\n    }\n)"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["emptyBraces"])), output + "\n")
    }

    func testNestedScopeOnSameLine() {
        let input = "foo(bar(\nbaz\n))"
        let output = "foo(bar(\n    baz\n))"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNestedScopeOnSameLine2() {
        let input = "foo(bar(in:\nbaz))"
        let output = "foo(bar(in:\n    baz))"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIndentNestedArrayLiteral() {
        let input = "foo(bar: [\n.baz,\n])"
        let output = "foo(bar: [\n    .baz,\n])"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testClosingScopeAfterContent() {
        let input = "foo(\nbar\n)"
        let output = "foo(\n    bar\n)"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testClosingNestedScopeAfterContent() {
        let input = "foo(bar(\nbaz\n))"
        let output = "foo(bar(\n    baz\n))"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testWrappedFunctionArguments() {
        let input = "foo(\nbar,\nbaz\n)"
        let output = "foo(\n    bar,\n    baz\n)"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testFunctionArgumentsWrappedAfterFirst() {
        let input = "func foo(bar: Int,\nbaz: Int)"
        let output = "func foo(bar: Int,\n         baz: Int)"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // indent specifiers

    func testNoIndentWrappedSpecifiersForProtocol() {
        let input = "@objc\nprivate\nprotocol Foo {}"
        let output = "@objc\nprivate\nprotocol Foo {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // indent braces

    func testElseClauseIndenting() {
        let input = "if x {\nbar\n} else {\nbaz\n}"
        let output = "if x {\n    bar\n} else {\n    baz\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoIndentBlankLines() {
        let input = "{\n\n// foo\n}"
        let output = "{\n\n    // foo\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["blankLinesAtStartOfScope"])), output + "\n")
    }

    func testNestedBraces() {
        let input = "({\n// foo\n}, {\n// bar\n})"
        let output = "({\n    // foo\n}, {\n    // bar\n})"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testBraceIndentAfterComment() {
        let input = "if foo { // comment\nbar\n}"
        let output = "if foo { // comment\n    bar\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testBraceIndentAfterClosingScope() {
        let input = "foo(bar(baz), {\nquux\nbleem\n})"
        let output = "foo(bar(baz), {\n    quux\n    bleem\n})"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["trailingClosures"])), output + "\n")
    }

    func testBraceIndentAfterLineWithParens() {
        let input = "({\nfoo()\nbar\n})"
        let output = "({\n    foo()\n    bar\n})"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["redundantParens"])), output + "\n")
    }

    // indent switch/case

    func testSwitchCaseIndenting() {
        let input = "switch x {\ncase foo:\nbreak\ncase bar:\nbreak\ndefault:\nbreak\n}"
        let output = "switch x {\ncase foo:\n    break\ncase bar:\n    break\ndefault:\n    break\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSwitchWrappedCaseIndenting() {
        let input = "switch x {\ncase foo,\nbar,\n    baz:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\ncase foo,\n     bar,\n     baz:\n    break\ndefault:\n    break\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSwitchWrappedEnumCaseIndenting() {
        let input = "switch x {\ncase .foo,\n.bar,\n    .baz:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\ncase .foo,\n     .bar,\n     .baz:\n    break\ndefault:\n    break\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSwitchWrappedEnumCaseIndentingVariant2() {
        let input = "switch x {\ncase\n.foo,\n.bar,\n    .baz:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\ncase\n    .foo,\n    .bar,\n    .baz:\n    break\ndefault:\n    break\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSwitchWrappedEnumCaseIsIndenting() {
        let input = "switch x {\ncase is Foo.Type,\n    is Bar.Type:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\ncase is Foo.Type,\n     is Bar.Type:\n    break\ndefault:\n    break\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSwitchCaseIsDictionaryIndenting() {
        let input = "switch x {\ncase foo is [Key: Value]:\nfallthrough\ndefault:\nbreak\n}"
        let output = "switch x {\ncase foo is [Key: Value]:\n    fallthrough\ndefault:\n    break\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testEnumCaseIndenting() {
        let input = "enum Foo {\ncase Bar\ncase Baz\n}"
        let output = "enum Foo {\n    case Bar\n    case Baz\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testEnumCaseIndentingCommas() {
        let input = "enum Foo {\ncase Bar,\nBaz\n}"
        let output = "enum Foo {\n    case Bar,\n        Baz\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testEnumCaseIndentingCommasWithXcodeStyle() {
        let input = "enum Foo {\ncase Bar,\nBaz\n}"
        let output = "enum Foo {\n    case Bar,\n    Baz\n}"
        let options = FormatOptions(xcodeIndentation: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testEnumCaseWrappedIfWithXcodeStyle() {
        let input = "if case .foo = foo,\ntrue {\nreturn false\n}"
        let output = "if case .foo = foo,\n    true {\n    return false\n}"
        let options = FormatOptions(xcodeIndentation: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testGenericEnumCaseIndenting() {
        let input = "enum Foo<T> {\ncase Bar\ncase Baz\n}"
        let output = "enum Foo<T> {\n    case Bar\n    case Baz\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIndentSwitchAfterRangeCase() {
        let input = "switch x {\ncase 0 ..< 2:\n    switch y {\n    default:\n        break\n    }\ndefault:\n    break\n}"
        let output = "switch x {\ncase 0 ..< 2:\n    switch y {\n    default:\n        break\n    }\ndefault:\n    break\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIndentEnumDeclarationInsideSwitchCase() {
        let input = "switch x {\ncase y:\nenum Foo {\ncase z\n}\nbar()\ndefault: break\n}"
        let output = "switch x {\ncase y:\n    enum Foo {\n        case z\n    }\n    bar()\ndefault: break\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIndentEnumCaseBodyAfterWhereClause() {
        let input = "switch foo {\ncase _ where baz < quux:\n    print(1)\n    print(2)\ndefault:\n    break\n}"
        let output = "switch foo {\ncase _ where baz < quux:\n    print(1)\n    print(2)\ndefault:\n    break\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIndentSwitchCaseCommentsCorrectly() {
        let input = "switch x {\n// comment\ncase y:\n// comment\nbreak\n// comment\ncase z:\nbreak\n}"
        let output = "switch x {\n// comment\ncase y:\n    // comment\n    break\n// comment\ncase z:\n    break\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIndentMultilineSwitchCaseCommentsCorrectly() {
        let input = "switch x {\n/*\n * comment\n */\ncase y:\nbreak\n/*\n * comment\n */\ndefault:\nbreak\n}"
        let output = "switch x {\n/*\n * comment\n */\ncase y:\n    break\n/*\n * comment\n */\ndefault:\n    break\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIndentMultipleSingleLineSwitchCaseCommentsCorrectly() {
        let input = "switch x {\n// comment 1\n// comment 2\ncase y:\n// comment\nbreak\n}"
        let output = "switch x {\n// comment 1\n// comment 2\ncase y:\n    // comment\n    break\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIndentMultipleSingleLineSwitchCaseCommentsWithCommentsIgnoredCorrectly() {
        let input = """
        switch x {
        // bar
        case .y: return 1
        // baz
        case .z: return 2
        }
        """
        let output = input
        let options = FormatOptions(indentComments: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testIndentIfCase() {
        let input = "{\nif case let .foo(msg) = error {}\n}"
        let output = "{\n    if case let .foo(msg) = error {}\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIndentIfCaseCommaCase() {
        let input = "{\nif case let .foo(msg) = a,\ncase let .bar(msg) = b {}\n}"
        let output = "{\n    if case let .foo(msg) = a,\n        case let .bar(msg) = b {}\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]),
                       try format(input, rules: [FormatRules.indent], options: FormatOptions(xcodeIndentation: true)))
    }

    func testIndentGuardCase() {
        let input = "{\nguard case .Foo = error else {}\n}"
        let output = "{\n    guard case .Foo = error else {}\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // indentCase = true

    func testSwitchCaseWithIndentCaseTrue() {
        let input = "switch x {\ncase foo:\nbreak\ncase bar:\nbreak\ndefault:\nbreak\n}"
        let output = "switch x {\n    case foo:\n        break\n    case bar:\n        break\n    default:\n        break\n}"
        let options = FormatOptions(indentCase: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testSwitchWrappedEnumCaseWithIndentCaseTrue() {
        let input = "switch x {\ncase .foo,\n.bar,\n    .baz:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\n    case .foo,\n         .bar,\n         .baz:\n        break\n    default:\n        break\n}"
        let options = FormatOptions(indentCase: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testIndentMultilineSwitchCaseCommentsWithIndentCaseTrue() {
        let input = "switch x {\n/*\n * comment\n */\ncase y:\nbreak\n/*\n * comment\n */\ndefault:\nbreak\n}"
        let output = "switch x {\n    /*\n     * comment\n     */\n    case y:\n        break\n    /*\n     * comment\n     */\n    default:\n        break\n}"
        let options = FormatOptions(indentCase: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoMangleLabelWhenIndentCaseTrue() {
        let input = "foo: while true {\n    break foo\n}"
        let output = "foo: while true {\n    break foo\n}"
        let options = FormatOptions(indentCase: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        let output = input
        let options = FormatOptions(indentCase: true, indentComments: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        let output = input
        let options = FormatOptions(indentCase: true, indentComments: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        let output = input
        let options = FormatOptions(indentCase: true, indentComments: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // indent wrapped lines

    func testWrappedLineAfterOperator() {
        let input = "if x {\nlet y = foo +\nbar\n}"
        let output = "if x {\n    let y = foo +\n        bar\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testWrappedLineAfterComma() {
        let input = "let a = b,\nb = c"
        let output = "let a = b,\n    b = c"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testWrappedBeforeComma() {
        let input = "let a = b\n, b = c"
        let output = "let a = b\n    , b = c"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["leadingDelimiters"])), output + "\n")
    }

    func testWrappedLineAfterCommaInsideArray() {
        let input = "[\nfoo,\nbar,\n]"
        let output = "[\n    foo,\n    bar,\n]"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testWrappedLineBeforeCommaInsideArray() {
        let input = "[\nfoo\n, bar,\n]"
        let output = "[\n    foo\n    , bar,\n]"
        let options = FormatOptions(wrapCollections: .disabled)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["leadingDelimiters"]), options: options), output + "\n")
    }

    func testWrappedLineAfterCommaInsideInlineArray() {
        let input = "[foo,\nbar]"
        let output = "[foo,\n bar]"
        let options = FormatOptions(wrapCollections: .disabled)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testWrappedLineBeforeCommaInsideInlineArray() {
        let input = "[foo\n, bar]"
        let output = "[foo\n , bar]"
        let options = FormatOptions(wrapCollections: .disabled)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["leadingDelimiters"]), options: options), output + "\n")
    }

    func testWrappedLineAfterColonInFunction() {
        let input = "func foo(bar:\nbaz)"
        let output = "func foo(bar:\n    baz)"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoDoubleIndentOfWrapAfterAsAfterOpenScope() {
        let input = "(foo as\nBar)"
        let output = "(foo as\n    Bar)"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["redundantParens"])), output + "\n")
    }

    func testNoDoubleIndentOfWrapBeforeAsAfterOpenScope() {
        let input = "(foo\nas Bar)"
        let output = "(foo\n    as Bar)"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["redundantParens"])), output + "\n")
    }

    func testDoubleIndentWhenScopesSeparatedByWrap() {
        let input = "(foo\nas Bar {\nbaz\n})"
        let output = "(foo\n    as Bar {\n        baz\n})"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["redundantParens"])), output + "\n")
    }

    func testNoDoubleIndentWhenScopesSeparatedByWrap() {
        let input = "(foo\nas Bar {\nbaz\n}\n)"
        let output = "(foo\n    as Bar {\n        baz\n    }\n)"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["wrapArguments", "redundantParens"])), output + "\n")
    }

    func testNoPermanentReductionInScopeAfterWrap() {
        let input = "{ foo\nas Bar\nlet baz = 5\n}"
        let output = "{ foo\n    as Bar\n    let baz = 5\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testWrappedLineBeforeOperator() {
        let input = "if x {\nlet y = foo\n+ bar\n}"
        let output = "if x {\n    let y = foo\n        + bar\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testWrappedLineAfterForKeyword() {
        let input = "for\ni in range {}"
        let output = "for\n    i in range {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testWrappedLineAfterDot() {
        let input = "let foo = bar.\nbaz"
        let output = "let foo = bar.\n    baz"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testWrappedLineBeforeDot() {
        let input = "let foo = bar\n.baz"
        let output = "let foo = bar\n    .baz"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testWrappedLineBeforeWhere() {
        let input = "let foo = bar\nwhere foo == baz"
        let output = "let foo = bar\n    where foo == baz"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testWrappedLineAfterWhere() {
        let input = "let foo = bar where\nfoo == baz"
        let output = "let foo = bar where\n    foo == baz"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testWrappedLineBeforeGuardElse() {
        let input = "guard let foo = bar\nelse { return }"
        let output = "guard let foo = bar\nelse { return }"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSingleLineGuardFollowingLine() {
        let input = "guard let foo = bar else { return }\nreturn"
        let output = "guard let foo = bar else { return }\nreturn"
        let options = FormatOptions(xcodeIndentation: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testWrappedLineBeforeGuardElseWithXcodeStyle() {
        let input = "guard let foo = bar\nelse { return }"
        let output = "guard let foo = bar\n    else { return }"
        let options = FormatOptions(xcodeIndentation: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testWrappedLineAfterGuardElseWithXcodeStyleNotIndented() {
        let input = "guard let foo = bar else\n{ return }"
        let output = "guard let foo = bar else\n{ return }"
        let options = FormatOptions(xcodeIndentation: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testWrappedLineBeforeGuardElseAndReturnWithXcodeStyle() {
        let input = "guard let foo = foo\nelse {\nreturn\n}"
        let output = "guard let foo = foo\n    else {\n        return\n}"
        let options = FormatOptions(xcodeIndentation: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testXcodeIndentationGuardClosure() {
        let input = "guard let foo = bar(baz, completion: {\nfalse\n}) else { return }"
        let output = "guard let foo = bar(baz, completion: {\n    false\n}) else { return }"
        let options = FormatOptions(xcodeIndentation: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNestedScopesForXcodeGuardIndentation() {
        let input = "enum Foo {\ncase bar\n\nvar foo: String {\nguard self == .bar\nelse {\nreturn \"\"\n}\nreturn \"bar\"\n}\n}"
        let output = "enum Foo {\n    case bar\n\n    var foo: String {\n        guard self == .bar\n            else {\n                return \"\"\n        }\n        return \"bar\"\n    }\n}"
        let options = FormatOptions(xcodeIndentation: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testWrappedLineInClosure() {
        let input = "forEach { item in\nprint(item)\n}"
        let output = "forEach { item in\n    print(item)\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testConsecutiveWraps() {
        let input = "let a = b +\nc +\nd"
        let output = "let a = b +\n    c +\n    d"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testWrapReset() {
        let input = "let a = b +\nc +\nd\nlet a = b +\nc +\nd"
        let output = "let a = b +\n    c +\n    d\nlet a = b +\n    c +\n    d"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIndentElseAfterComment() {
        let input = "if x {}\n// comment\nelse {}"
        let output = "if x {}\n// comment\nelse {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testWrappedLinesWithComments() {
        let input = "let foo = bar ||\n // baz||\nquux"
        let output = "let foo = bar ||\n    // baz||\n    quux"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoIndentAfterAssignOperatorToVariable() {
        let input = "let greaterThan = >\nlet lessThan = <"
        let output = "let greaterThan = >\nlet lessThan = <"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoIndentAfterDefaultAsIdentifier() {
        let input = "let foo = FileManager.default\n// Comment\nlet bar = 0"
        let output = "let foo = FileManager.default\n// Comment\nlet bar = 0"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIndentClosureStartingOnIndentedLine() {
        let input = "foo\n.bar {\nbaz()\n}"
        let output = "foo\n    .bar {\n        baz()\n    }"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIndentClosureStartingOnIndentedLine2() {
        let input = "var foo = foo\n.bar {\nbaz()\n}"
        let output = "var foo = foo\n    .bar {\n        baz()\n    }"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNestedWrappedIfIndents() {
        let input = "if foo {\nif bar &&\n(baz ||\nquux) {\nfoo()\n}\n}"
        let output = "if foo {\n    if bar &&\n        (baz ||\n            quux) {\n        foo()\n    }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["andOperator"])), output + "\n")
    }

    func testWrappedEnumThatLooksLikeIf() {
        let input = "foo &&\n bar.if {\nfoo()\n}"
        let output = "foo &&\n    bar.if {\n        foo()\n    }"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testChainedClosureIndents() {
        let input = "foo\n.bar {\nbaz()\n}\n.bar {\nbaz()\n}"
        let output = "foo\n    .bar {\n        baz()\n    }\n    .bar {\n        baz()\n    }"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testChainedClosureIndentsAfterVarDeclaration() {
        let input = "var foo: Int\nfoo\n.bar {\nbaz()\n}\n.bar {\nbaz()\n}"
        let output = "var foo: Int\nfoo\n    .bar {\n        baz()\n    }\n    .bar {\n        baz()\n    }"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testChainedFunctionsInsideIf() {
        let input = "if foo {\nreturn bar()\n.baz()\n}"
        let output = "if foo {\n    return bar()\n        .baz()\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testChainedFunctionsInsideForLoop() {
        let input = "for x in y {\nfoo\n.bar {\nbaz()\n}\n.quux()\n}"
        let output = "for x in y {\n    foo\n        .bar {\n            baz()\n        }\n        .quux()\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testChainedFunctionsAfterAnIfStatement() {
        let input = "if foo {}\nbar\n.baz {\n}\n.quux()"
        let output = "if foo {}\nbar\n    .baz {\n    }\n    .quux()"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["emptyBraces"])), output + "\n")
    }

    func testIndentInsideWrappedIfStatementWithClosureCondition() {
        let input = "if foo({ 1 }) ||\nbar {\nbaz()\n}"
        let output = "if foo({ 1 }) ||\n    bar {\n    baz()\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIndentInsideWrappedClassDefinition() {
        let input = "class Foo\n: Bar {\nbaz()\n}"
        let output = "class Foo\n    : Bar {\n    baz()\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["leadingDelimiters"])), output + "\n")
    }

    func testIndentInsideWrappedProtocolDefinition() {
        let input = "protocol Foo\n: Bar, Baz {\nbaz()\n}"
        let output = "protocol Foo\n    : Bar, Baz {\n    baz()\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["leadingDelimiters"])), output + "\n")
    }

    func testIndentInsideWrappedVarStatement() {
        let input = "var Foo:\nBar {\nreturn 5\n}"
        let output = "var Foo:\n    Bar {\n    return 5\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoIndentAfterOperatorDeclaration() {
        let input = "infix operator ?=\nfunc ?= (lhs _: Int, rhs _: Int) -> Bool {}"
        let output = "infix operator ?=\nfunc ?= (lhs _: Int, rhs _: Int) -> Bool {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoIndentAfterChevronOperatorDeclaration() {
        let input = "infix operator =<<\nfunc =<< <T>(lhs _: T, rhs _: T) -> T {}"
        let output = "infix operator =<<\nfunc =<< <T>(lhs _: T, rhs _: T) -> T {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIndentEnumDictionaryKeysAndValues() {
        let input = "[\n.foo:\n.bar,\n.baz:\n.quux,\n]"
        let output = "[\n    .foo:\n        .bar,\n    .baz:\n        .quux,\n]"
        let options = FormatOptions(wrapCollections: .disabled)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testIndentWrappedFunctionArgument() {
        let input = "foobar(baz: a &&\nb)"
        let output = "foobar(baz: a &&\n    b)"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIndentWrappedFunctionClosureArgument() {
        let input = "foobar(baz: { a &&\nb })"
        let output = "foobar(baz: { a &&\n        b })"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["trailingClosures", "braces"])), output + "\n")
    }

    func testIndentClassDeclarationContainingComment() {
        let input = "class Foo: Bar,\n    // Comment\n    Baz {}"
        let output = "class Foo: Bar,\n    // Comment\n    Baz {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // indent comments

    func testCommentIndenting() {
        let input = "/* foo\nbar */"
        let output = "/* foo\n bar */"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCommentIndentingWithTrailingClose() {
        let input = "/*\nfoo\n*/"
        let output = "/*\n foo\n */"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNestedCommentIndenting() {
        let input = "/* foo\n/*\nbar\n*/\n*/"
        let output = "/* foo\n /*\n  bar\n  */\n */"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCommentedCodeBlocksNotIndented() {
        let input = "func foo() {\n//    var foo: Int\n}"
        let output = "func foo() {\n//    var foo: Int\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testBlankCodeCommentBlockLinesNotIndented() {
        let input = "func foo() {\n//\n}"
        let output = "func foo() {\n//\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // indent multiline strings

    func testSimpleMultilineString() {
        let input = "\"\"\"\n    hello\n    world\n\"\"\""
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIndentIndentedSimpleMultilineString() {
        let input = "{\n\"\"\"\n    hello\n    world\n    \"\"\"\n}"
        let output = "{\n    \"\"\"\n    hello\n    world\n    \"\"\"\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testMultilineStringWithEscapedLinebreak() {
        let input = "\"\"\"\n    hello \\\n    world\n\"\"\""
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIndentMultilineStringWrappedAfter() {
        let input = "foo(baz:\n    \"\"\"\n    baz\n    \"\"\")"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIndentMultilineStringInNestedCalls() {
        let input = "foo(bar(\"\"\"\nbaz\n\"\"\"))"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // indent multiline raw strings

    func testIndentIndentedSimpleRawMultilineString() {
        let input = "{\n##\"\"\"\n    hello\n    world\n    \"\"\"##\n}"
        let output = "{\n    ##\"\"\"\n    hello\n    world\n    \"\"\"##\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // indent #if/#else/#elseif/#endif (mode: indent)

    func testIfEndifIndenting() {
        let input = "#if x\n// foo\n#endif"
        let output = "#if x\n    // foo\n#endif"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIndentedIfEndifIndenting() {
        let input = "{\n#if x\n// foo\nfoo()\n#endif\n}"
        let output = "{\n    #if x\n        // foo\n        foo()\n    #endif\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIfElseEndifIndenting() {
        let input = "#if x\n    // foo\nfoo()\n#else\n    // bar\n#endif"
        let output = "#if x\n    // foo\n    foo()\n#else\n    // bar\n#endif"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testEnumIfCaseEndifIndenting() {
        let input = "enum Foo {\ncase bar\n#if x\ncase baz\n#endif\n}"
        let output = "enum Foo {\n    case bar\n    #if x\n        case baz\n    #endif\n}"
        let options = FormatOptions(indentCase: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testSwitchIfCaseEndifIndenting() {
        let input = "switch foo {\ncase .bar: break\n#if x\ncase .baz: break\n#endif\n}"
        let output = "switch foo {\ncase .bar: break\n#if x\n    case .baz: break\n#endif\n}"
        let options = FormatOptions(indentCase: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testSwitchIfCaseEndifIndenting2() {
        let input = "switch foo {\ncase .bar: break\n#if x\ncase .baz: break\n#endif\n}"
        let output = "switch foo {\n    case .bar: break\n    #if x\n        case .baz: break\n    #endif\n}"
        let options = FormatOptions(indentCase: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testSwitchIfCaseEndifIndenting3() {
        let input = "switch foo {\n#if x\ncase .bar: break\ncase .baz: break\n#endif\n}"
        let output = "switch foo {\n#if x\n    case .bar: break\n    case .baz: break\n#endif\n}"
        let options = FormatOptions(indentCase: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testSwitchIfCaseEndifIndenting4() {
        let input = "switch foo {\n#if x\ncase .bar:\nbreak\ncase .baz:\nbreak\n#endif\n}"
        let output = "switch foo {\n    #if x\n        case .bar:\n            break\n        case .baz:\n            break\n    #endif\n}"
        let options = FormatOptions(indentCase: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testSwitchIfCaseElseCaseEndifIndenting() {
        let input = "switch foo {\n#if x\ncase .bar: break\n#else\ncase .baz: break\n#endif\n}"
        let output = "switch foo {\n#if x\n    case .bar: break\n#else\n    case .baz: break\n#endif\n}"
        let options = FormatOptions(indentCase: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testSwitchIfCaseElseCaseEndifIndenting2() {
        let input = "switch foo {\n#if x\ncase .bar: break\n#else\ncase .baz: break\n#endif\n}"
        let output = "switch foo {\n    #if x\n        case .bar: break\n    #else\n        case .baz: break\n    #endif\n}"
        let options = FormatOptions(indentCase: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testSwitchIfEndifInsideCaseIndenting() {
        let input = "switch foo {\ncase .bar:\n#if x\nbar()\n#endif\nbaz()\ncase .baz: break\n}"
        let output = "switch foo {\ncase .bar:\n    #if x\n        bar()\n    #endif\n    baz()\ncase .baz: break\n}"
        let options = FormatOptions(indentCase: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testSwitchIfEndifInsideCaseIndenting2() {
        let input = "switch foo {\ncase .bar:\n#if x\nbar()\n#endif\nbaz()\ncase .baz: break\n}"
        let output = "switch foo {\n    case .bar:\n        #if x\n            bar()\n        #endif\n        baz()\n    case .baz: break\n}"
        let options = FormatOptions(indentCase: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        let output = input
        let options = FormatOptions(indentCase: false, ifdefIndent: .indent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        let output = input
        let options = FormatOptions(indentCase: true, ifdefIndent: .indent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // indent #if/#else/#elseif/#endif (mode: noindent)

    func testIfEndifNoIndenting() {
        let input = "#if x\n// foo\n#endif"
        let output = "#if x\n// foo\n#endif"
        let options = FormatOptions(ifdefIndent: .noIndent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testIndentedIfEndifNoIndenting() {
        let input = "{\n#if x\n// foo\n#endif\n}"
        let output = "{\n    #if x\n    // foo\n    #endif\n}"
        let options = FormatOptions(ifdefIndent: .noIndent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testIfElseEndifNoIndenting() {
        let input = "#if x\n// foo\n#else\n// bar\n#endif"
        let output = "#if x\n// foo\n#else\n// bar\n#endif"
        let options = FormatOptions(ifdefIndent: .noIndent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testIfCaseEndifNoIndenting() {
        let input = "switch foo {\ncase .bar: break\n#if x\ncase .baz: break\n#endif\n}"
        let output = "switch foo {\ncase .bar: break\n#if x\ncase .baz: break\n#endif\n}"
        let options = FormatOptions(indentCase: false, ifdefIndent: .noIndent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testIfCaseEndifNoIndenting2() {
        let input = "switch foo {\ncase .bar: break\n#if x\ncase .baz: break\n#endif\n}"
        let output = "switch foo {\n    case .bar: break\n    #if x\n    case .baz: break\n    #endif\n}"
        let options = FormatOptions(indentCase: true, ifdefIndent: .noIndent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        let output = input
        let options = FormatOptions(indentCase: false, ifdefIndent: .noIndent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        let output = input
        let options = FormatOptions(indentCase: true, ifdefIndent: .noIndent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testIfEndifInsideCaseNoIndenting() {
        let input = "switch foo {\ncase .bar:\n#if x\nbar()\n#endif\nbaz()\ncase .baz: break\n}"
        let output = "switch foo {\ncase .bar:\n    #if x\n    bar()\n    #endif\n    baz()\ncase .baz: break\n}"
        let options = FormatOptions(indentCase: false, ifdefIndent: .noIndent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testIfEndifInsideCaseNoIndenting2() {
        let input = "switch foo {\ncase .bar:\n#if x\nbar()\n#endif\nbaz()\ncase .baz: break\n}"
        let output = "switch foo {\n    case .bar:\n        #if x\n        bar()\n        #endif\n        baz()\n    case .baz: break\n}"
        let options = FormatOptions(indentCase: true, ifdefIndent: .noIndent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        let output = input
        let options = FormatOptions(ifdefIndent: .noIndent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        let output = input
        let options = FormatOptions(ifdefIndent: .noIndent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // indent #if/#else/#elseif/#endif (mode: outdent)

    func testIfEndifOutdenting() {
        let input = "#if x\n// foo\n#endif"
        let output = "#if x\n// foo\n#endif"
        let options = FormatOptions(ifdefIndent: .outdent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testIndentedIfEndifOutdenting() {
        let input = "{\n#if x\n// foo\n#endif\n}"
        let output = "{\n#if x\n    // foo\n#endif\n}"
        let options = FormatOptions(ifdefIndent: .outdent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testIfElseEndifOutdenting() {
        let input = "#if x\n// foo\n#else\n// bar\n#endif"
        let output = "#if x\n// foo\n#else\n// bar\n#endif"
        let options = FormatOptions(ifdefIndent: .outdent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testIndentedIfElseEndifOutdenting() {
        let input = "{\n#if x\n// foo\nfoo()\n#else\n// bar\n#endif\n}"
        let output = "{\n#if x\n    // foo\n    foo()\n#else\n    // bar\n#endif\n}"
        let options = FormatOptions(ifdefIndent: .outdent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testIfElseifEndifOutdenting() {
        let input = "#if x\n// foo\n#elseif y\n// bar\n#endif"
        let output = "#if x\n// foo\n#elseif y\n// bar\n#endif"
        let options = FormatOptions(ifdefIndent: .outdent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testIndentedIfElseifEndifOutdenting() {
        let input = "{\n#if x\n// foo\nfoo()\n#elseif y\n// bar\n#endif\n}"
        let output = "{\n#if x\n    // foo\n    foo()\n#elseif y\n    // bar\n#endif\n}"
        let options = FormatOptions(ifdefIndent: .outdent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNestedIndentedIfElseifEndifOutdenting() {
        let input = "{\n#if x\n#if y\n// foo\nfoo()\n#elseif y\n// bar\n#endif\n#endif\n}"
        let output = "{\n#if x\n#if y\n    // foo\n    foo()\n#elseif y\n    // bar\n#endif\n#endif\n}"
        let options = FormatOptions(ifdefIndent: .outdent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testDoubleNestedIndentedIfElseifEndifOutdenting() {
        let input = "{\n#if x\n#if y\n#if z\n// foo\nfoo()\n#elseif y\n// bar\n#endif\n#endif\n#endif\n}"
        let output = "{\n#if x\n#if y\n#if z\n    // foo\n    foo()\n#elseif y\n    // bar\n#endif\n#endif\n#endif\n}"
        let options = FormatOptions(ifdefIndent: .outdent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testIfCaseEndifOutdenting() {
        let input = "switch foo {\ncase .bar: break\n#if x\ncase .baz: break\n#endif\n}"
        let output = "switch foo {\ncase .bar: break\n#if x\ncase .baz: break\n#endif\n}"
        let options = FormatOptions(ifdefIndent: .outdent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        let output = input
        let options = FormatOptions(ifdefIndent: .outdent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        let output = input
        let options = FormatOptions(ifdefIndent: .outdent)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // indent expression after return

    func testIndentIdentifierAfterReturn() {
        let input = "if foo {\n    return\n        bar\n}"
        let output = "if foo {\n    return\n        bar\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIndentEnumValueAfterReturn() {
        let input = "if foo {\n    return\n        .bar\n}"
        let output = "if foo {\n    return\n        .bar\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIndentMultilineExpressionAfterReturn() {
        let input = "if foo {\n    return\n        bar +\n        baz\n}"
        let output = "if foo {\n    return\n        bar +\n        baz\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testDontIndentClosingBraceAfterReturn() {
        let input = "if foo {\n    return\n}"
        let output = "if foo {\n    return\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testDontIndentCaseAfterReturn() {
        let input = "switch foo {\ncase bar:\n    return\ncase baz:\n    return\n}"
        let output = "switch foo {\ncase bar:\n    return\ncase baz:\n    return\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testDontIndentCaseAfterWhere() {
        let input = "switch foo {\ncase bar\nwhere baz:\nreturn\ndefault:\nreturn\n}"
        let output = "switch foo {\ncase bar\n    where baz:\n    return\ndefault:\n    return\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testDontIndentIfAfterReturn() {
        let input = "if foo {\n    return\n    if bar {}\n}"
        let output = "if foo {\n    return\n    if bar {}\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testDontIndentFuncAfterReturn() {
        let input = "if foo {\n    return\n    func bar() {}\n}"
        let output = "if foo {\n    return\n    func bar() {}\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // indent fragments

    func testIndentFragment() {
        let input = "   func foo() {\nbar()\n}"
        let output = "   func foo() {\n       bar()\n   }"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testIndentFragmentAfterBlankLines() {
        let input = "\n\n   func foo() {\nbar()\n}"
        let output = "\n\n   func foo() {\n       bar()\n   }"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testUnterminatedFragment() {
        let input = "class Foo {\n\n  func foo() {\nbar()\n}"
        let output = "class Foo {\n\n    func foo() {\n        bar()\n    }"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["blankLinesAtStartOfScope"]), options: options), output + "\n")
    }

    func testOverTerminatedFragment() {
        let input = "   func foo() {\nbar()\n}\n\n}"
        let output = "   func foo() {\n       bar()\n   }\n\n}"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testDontCorruptPartialFragment() {
        let input = "    } foo {\n        bar\n    }\n}"
        let output = "    } foo {\n        bar\n    }\n}"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testDontCorruptPartialFragment2() {
        let input = "        return completionHandler(nil)\n    }\n}"
        let output = "        return completionHandler(nil)\n    }\n}"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.indent], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // MARK: braces

    func testAllmanBracesAreConverted() {
        let input = "func foo()\n{\n    statement\n}"
        let output = "func foo() {\n    statement\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.braces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testKnRBracesAfterComment() {
        let input = "func foo() // comment\n{\n    statement\n}"
        let output = "func foo() { // comment\n    statement\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.braces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testKnRBracesAfterMultilineComment() {
        let input = "func foo() /* comment/ncomment */\n{\n    statement\n}"
        let output = "func foo() { /* comment/ncomment */\n    statement\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.braces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testKnRExtraSpaceNotAddedBeforeBrace() {
        let input = "foo({ bar })"
        let output = "foo({ bar })"
        XCTAssertEqual(try format(input, rules: [FormatRules.braces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["trailingClosures"])), output + "\n")
    }

    func testKnRLinebreakNotRemovedBeforeInlineBlockNot() {
        let input = "func foo() -> Bool\n{ return false }"
        let output = "func foo() -> Bool\n{ return false }"
        XCTAssertEqual(try format(input, rules: [FormatRules.braces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testKnRNoMangleCommentBeforeClosure() {
        let input = "[\n    // foo\n    foo,\n    // bar\n    {\n        bar\n    }(),\n]"
        let output = "[\n    // foo\n    foo,\n    // bar\n    {\n        bar\n    }(),\n]"
        XCTAssertEqual(try format(input, rules: [FormatRules.braces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testKnRNoMangleClosureReturningClosure() {
        let input = """
        foo { bar in
            {
                bar()
            }
        }
        """
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.braces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testKnRClosingBraceWrapped() {
        let input = "func foo() {\n    print(bar) }"
        let output = "func foo() {\n    print(bar)\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.braces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testKnRInlineBracesNotWrapped() {
        let input = "func foo() { print(bar) }"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.braces]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // allman style

    func testKnRBracesAreConverted() {
        let input = "func foo() {\n    statement\n}"
        let output = "func foo()\n{\n    statement\n}"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.braces], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testAllmanBlankLineAfterBraceRemoved() {
        let input = "func foo() {\n    \n    statement\n}"
        let output = "func foo()\n{\n    statement\n}"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.braces], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testAllmanBraceInsideParensNotConverted() {
        let input = "foo({\n    bar\n})"
        let output = "foo({\n    bar\n})"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.braces], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["trailingClosures"]), options: options), output + "\n")
    }

    func testAllmanBraceDoClauseIndent() {
        let input = "do {\n    foo\n}"
        let output = "do\n{\n    foo\n}"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.braces], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testAllmanBraceCatchClauseIndent() {
        let input = "do {\n    try foo\n}\ncatch {\n}"
        let output = "do\n{\n    try foo\n}\ncatch\n{\n}"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.braces], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["emptyBraces"]), options: options), output + "\n")
    }

    func testAllmanBraceRepeatWhileIndent() {
        let input = "repeat {\n    foo\n}\nwhile x"
        let output = "repeat\n{\n    foo\n}\nwhile x"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.braces], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testAllmanBraceOptionalComputedPropertyIndent() {
        let input = "var foo: Int? {\n    return 5\n}"
        let output = "var foo: Int?\n{\n    return 5\n}"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.braces], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testAllmanBraceThrowsFunctionIndent() {
        let input = "func foo() throws {\n    bar\n}"
        let output = "func foo() throws\n{\n    bar\n}"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.braces], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testAllmanBraceAfterCommentIndent() {
        let input = "func foo() { // foo\n\n    bar\n}"
        let output = "func foo()\n{ // foo\n    bar\n}"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.braces], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testAllmanBraceAfterSwitch() {
        let input = "switch foo {\ncase bar: break\n}"
        let output = "switch foo\n{\ncase bar: break\n}"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.braces], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // MARK: elseOnSameLine

    func testElseOnSameLine() {
        let input = "if true {\n    1\n}\nelse { 2 }"
        let output = "if true {\n    1\n} else { 2 }"
        XCTAssertEqual(try format(input, rules: [FormatRules.elseOnSameLine]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testElseOnSameLineOnlyAppliedToDanglingBrace() {
        let input = "if true { 1 }\nelse { 2 }"
        let output = "if true { 1 }\nelse { 2 }"
        XCTAssertEqual(try format(input, rules: [FormatRules.elseOnSameLine]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testGuardNotAffectedByElseOnSameLine() {
        let input = "guard true\nelse { return }"
        let output = "guard true\nelse { return }"
        XCTAssertEqual(try format(input, rules: [FormatRules.elseOnSameLine]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testElseOnSameLineDoesntEatPreviousStatement() {
        let input = "if true {}\nguard true else { return }"
        let output = "if true {}\nguard true else { return }"
        XCTAssertEqual(try format(input, rules: [FormatRules.elseOnSameLine]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testElseNotOnSameLineForAllman() {
        let input = "if true\n{\n    1\n} else { 2 }"
        let output = "if true\n{\n    1\n}\nelse { 2 }"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.elseOnSameLine], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testElseOnNextLineOption() {
        let input = "if true {\n    1\n} else { 2 }"
        let output = "if true {\n    1\n}\nelse { 2 }"
        let options = FormatOptions(elseOnNextLine: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.elseOnSameLine], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testGuardNotAffectedByElseOnSameLineForAllman() {
        let input = "guard true else { return }"
        let output = "guard true else { return }"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.elseOnSameLine], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testRepeatWhileNotOnSameLineForAllman() {
        let input = "repeat\n{\n    foo\n} while x"
        let output = "repeat\n{\n    foo\n}\nwhile x"
        let options = FormatOptions(allmanBraces: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.elseOnSameLine], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testWhileNotAffectedByElseOnSameLineIfNotRepeatWhile() {
        let input = "func foo(x) {}\n\nwhile true {}"
        let output = "func foo(x) {}\n\nwhile true {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.elseOnSameLine]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCommentsNotDiscardedByElseOnSameLineRule() {
        let input = "if true {\n    1\n}\n\n// comment\nelse {}"
        let output = "if true {\n    1\n}\n\n// comment\nelse {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.elseOnSameLine]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: trailingCommas

    func testCommaAddedToSingleItem() {
        let input = "[\n    foo\n]"
        let output = "[\n    foo,\n]"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCommaAddedToLastItem() {
        let input = "[\n    foo,\n    bar\n]"
        let output = "[\n    foo,\n    bar,\n]"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCommaAddedToDictionary() {
        let input = "[\n    foo: bar\n]"
        let output = "[\n    foo: bar,\n]"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCommaNotAddedToInlineArray() {
        let input = "[foo, bar]"
        let output = "[foo, bar]"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCommaNotAddedToInlineDictionary() {
        let input = "[foo: bar]"
        let output = "[foo: bar]"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCommaNotAddedToSubscript() {
        let input = "foo[bar]"
        let output = "foo[bar]"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCommaAddedBeforeComment() {
        let input = "[\n    foo // comment\n]"
        let output = "[\n    foo, // comment\n]"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCommaNotAddedAfterComment() {
        let input = "[\n    foo, // comment\n]"
        let output = "[\n    foo, // comment\n]"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCommaNotAddedInsideEmptyArrayLiteral() {
        let input = "foo = [\n]"
        let output = "foo = [\n]"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCommaNotAddedInsideEmptyDictionaryLiteral() {
        let input = "foo = [:\n]"
        let output = "foo = [:\n]"
        let options = FormatOptions(wrapCollections: .disabled)
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testTrailingCommaRemovedInInlineArray() {
        let input = "[foo,]"
        let output = "[foo]"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testTrailingCommaNotAddedToSubscript() {
        let input = "foo[\n    bar\n]"
        let output = "foo[\n    bar\n]"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testTrailingCommaNotAddedToSubscript2() {
        let input = "foo?[\n    bar\n]"
        let output = "foo?[\n    bar\n]"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testTrailingCommaNotAddedToSubscript3() {
        let input = "foo()[\n    bar\n]"
        let output = "foo()[\n    bar\n]"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testTrailingCommaNotAddedToTypeDeclaration() {
        let input = "var: [\n    Int:\n        String\n]"
        let output = "var: [\n    Int:\n        String\n]"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testTrailingCommaNotAddedToTypeDeclaration2() {
        let input = "func foo(bar: [\n    Int:\n        String\n])"
        let output = "func foo(bar: [\n    Int:\n        String\n])"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // trailingCommas = false

    func testCommaNotAddedToLastItem() {
        let input = "[\n    foo,\n    bar\n]"
        let output = "[\n    foo,\n    bar\n]"
        let options = FormatOptions(trailingCommas: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testCommaRemovedFromLastItem() {
        let input = "[\n    foo,\n    bar,\n]"
        let output = "[\n    foo,\n    bar\n]"
        let options = FormatOptions(trailingCommas: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingCommas], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // MARK: todos

    func testMarkIsUpdated() {
        let input = "// MARK foo"
        let output = "// MARK: foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.todos]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testTodoIsUpdated() {
        let input = "// TODO foo"
        let output = "// TODO: foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.todos]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testFixmeIsUpdated() {
        let input = "//    FIXME foo"
        let output = "//    FIXME: foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.todos]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testMarkWithColonSeparatedBySpace() {
        let input = "// MARK : foo"
        let output = "// MARK: foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.todos]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testMarkWithTripleSlash() {
        let input = "/// MARK: foo"
        let output = "// MARK: foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.todos]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testMarkWithNoSpaceAfterColon() {
        // NOTE: this was an unintended side-effect, but I like it
        let input = "// MARK:foo"
        let output = "// MARK: foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.todos]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCorrectMarkIsIgnored() {
        let input = "// MARK: foo"
        let output = "// MARK: foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.todos]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testMarkInsideMultilineComment() {
        let input = "/* MARK foo */"
        let output = "/* MARK: foo */"
        XCTAssertEqual(try format(input, rules: [FormatRules.todos]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoExtraSpaceAddedAfterTodo() {
        let input = "/* TODO: */"
        let output = "/* TODO: */"
        XCTAssertEqual(try format(input, rules: [FormatRules.todos]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: semicolons

    func testSemicolonRemovedAtEndOfLine() {
        let input = "print(\"hello\");\n"
        let output = "print(\"hello\")\n"
        XCTAssertEqual(try format(input, rules: [FormatRules.semicolons]), output)
        XCTAssertEqual(try format(input, rules: FormatRules.all), output)
    }

    func testSemicolonRemovedAtStartOfLine() {
        let input = "\n;print(\"hello\")"
        let output = "\nprint(\"hello\")"
        XCTAssertEqual(try format(input, rules: [FormatRules.semicolons]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSemicolonRemovedAtEndOfProgram() {
        let input = "print(\"hello\");"
        let output = "print(\"hello\")"
        XCTAssertEqual(try format(input, rules: [FormatRules.semicolons]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSemicolonRemovedAtStartOfProgram() {
        let input = ";print(\"hello\")"
        let output = "print(\"hello\")"
        XCTAssertEqual(try format(input, rules: [FormatRules.semicolons]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIgnoreInlineSemicolon() {
        let input = "print(\"hello\"); print(\"goodbye\")"
        let output = "print(\"hello\"); print(\"goodbye\")"
        let options = FormatOptions(allowInlineSemicolons: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.semicolons], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testReplaceInlineSemicolon() {
        let input = "print(\"hello\"); print(\"goodbye\")"
        let output = "print(\"hello\")\nprint(\"goodbye\")"
        let options = FormatOptions(allowInlineSemicolons: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.semicolons], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testReplaceSemicolonFollowedByComment() {
        let input = "print(\"hello\"); // comment\nprint(\"goodbye\")"
        let output = "print(\"hello\") // comment\nprint(\"goodbye\")"
        let options = FormatOptions(allowInlineSemicolons: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.semicolons], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testSemicolonsNotReplacedInForLoop() {
        let input = "for (i = 0; i < 5; i++)"
        let output = "for (i = 0; i < 5; i++)"
        let options = FormatOptions(allowInlineSemicolons: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.semicolons], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testSemicolonsNotReplacedInForLoopContainingComment() {
        let input = "for (i = 0 // comment\n    ; i < 5; i++)"
        let output = "for (i = 0 // comment\n    ; i < 5; i++)"
        let options = FormatOptions(allowInlineSemicolons: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.semicolons], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["leadingDelimiters"]), options: options), output + "\n")
    }

    func testSemicolonNotReplacedAfterReturn() {
        let input = "return;\nfoo()"
        let output = "return;\nfoo()"
        XCTAssertEqual(try format(input, rules: [FormatRules.semicolons]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSemicolonReplacedAfterReturnIfEndOfScope() {
        let input = "do { return; }"
        let output = "do { return }"
        XCTAssertEqual(try format(input, rules: [FormatRules.semicolons]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: ranges

    func testSpaceAroundRangeOperatorsWithDefaultOptions() {
        let input = "foo..<bar"
        let output = "foo ..< bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.ranges]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // spaceAroundRangeOperators = true

    func testNoSpaceAroundRangeOperatorsWithCustomOptions() {
        let input = "foo ..< bar"
        let output = "foo..<bar"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.ranges], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoSpaceAddedAroundVariadic() {
        let input = "foo(bar: Int...)"
        let output = "foo(bar: Int...)"
        let options = FormatOptions(spaceAroundRangeOperators: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.ranges], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoSpaceAddedAroundSplitLineVariadic() {
        let input = "foo(\n    bar: Int...\n)"
        let output = "foo(\n    bar: Int...\n)"
        let options = FormatOptions(spaceAroundRangeOperators: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.ranges], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoSpaceAddedAroundTrailingRangeOperator() {
        let input = "foo[bar...]"
        let output = "foo[bar...]"
        let options = FormatOptions(spaceAroundRangeOperators: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.ranges], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoSpaceAddedBeforeLeadingRangeOperator() {
        let input = "foo[...bar]"
        let output = "foo[...bar]"
        let options = FormatOptions(spaceAroundRangeOperators: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.ranges], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testSpaceNotRemovedBeforeLeadingRangeOperator() {
        let input = "let range = ..<foo.endIndex"
        let output = "let range = ..<foo.endIndex"
        let options = FormatOptions(spaceAroundRangeOperators: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.ranges], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // spaceAroundRangeOperators = false

    func testSpaceNotRemovedBeforeLeadingRangeOperatorWithSpaceAroundRangeOperatorsFalse() {
        let input = "let range = ..<foo.endIndex"
        let output = "let range = ..<foo.endIndex"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.ranges], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testSpaceOnOneSideOfRangeMatchedByCommentNotRemoved() {
        let input = "let range = 0 .../*foo*/4"
        let output = input
        let options = FormatOptions(spaceAroundRangeOperators: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.ranges], options: options), output)
    }

    func testSpaceOnOneSideOfRangeMatchedByCommentNotRemoved2() {
        let input = "let range = 0/*foo*/... 4"
        let output = input
        let options = FormatOptions(spaceAroundRangeOperators: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.ranges], options: options), output)
    }

    func testSpaceAroundRangeWithCommentOnOneSideNotRemoved() {
        let input = "let range = 0 ... /*foo*/4"
        let output = input
        let options = FormatOptions(spaceAroundRangeOperators: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.ranges], options: options), output)
    }

    func testSpaceAroundRangeWithCommentOnOneSideNotRemoved2() {
        let input = "let range = 0/*foo*/ ... 4"
        let output = input
        let options = FormatOptions(spaceAroundRangeOperators: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.ranges], options: options), output)
    }

    func testSpaceOnOneSideOfRangeMatchedByLinebreakNotRemoved() {
        let input = "let range = 0 ...\n4"
        let output = input
        let options = FormatOptions(spaceAroundRangeOperators: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.ranges], options: options), output)
    }

    func testSpaceOnOneSideOfRangeMatchedByLinebreakNotRemoved2() {
        let input = "let range = 0\n... 4"
        let output = input
        let options = FormatOptions(spaceAroundRangeOperators: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.ranges], options: options), output)
    }

    func testSpaceAroundRangeWithLinebreakOnOneSideNotRemoved() {
        let input = "let range = 0 ... \n4"
        let output = input
        let options = FormatOptions(spaceAroundRangeOperators: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.ranges], options: options), output)
    }

    func testSpaceAroundRangeWithLinebreakOnOneSideNotRemoved2() {
        let input = "let range = 0\n ... 4"
        let output = input
        let options = FormatOptions(spaceAroundRangeOperators: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.ranges], options: options), output)
    }

    func testSpaceNotRemovedAroundRangeFollowedByPrefixOperator() {
        let input = "let range = 0 ... -4"
        let output = input
        let options = FormatOptions(spaceAroundRangeOperators: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.ranges], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testSpaceNotRemovedAroundRangePreceededByPostfixOperator() {
        let input = "let range = 0>> ... 4"
        let output = input
        let options = FormatOptions(spaceAroundRangeOperators: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.ranges], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // MARK: specifiers

    func testVarSpecifiersCorrected() {
        let input = "unowned private static var foo"
        let output = "private unowned static var foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.specifiers]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testPrivateSetSpecifierNotMangled() {
        let input = "private(set) public weak lazy var foo"
        let output = "public private(set) lazy weak var foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.specifiers]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testPrivateRequiredStaticFuncSpecifiers() {
        let input = "required static private func foo()"
        let output = "private required static func foo()"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.specifiers], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testPrivateConvenienceInit() {
        let input = "convenience private init()"
        let output = "private convenience init()"
        XCTAssertEqual(try format(input, rules: [FormatRules.specifiers]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceInSpecifiersLeftIntact() {
        let input = "weak private(set) /* read-only */\npublic var"
        let output = "public private(set) /* read-only */\nweak var"
        XCTAssertEqual(try format(input, rules: [FormatRules.specifiers]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testPrefixSpecifier() {
        let input = "prefix public static func - (rhs: Foo) -> Foo"
        let output = "public static prefix func - (rhs: Foo) -> Foo"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.specifiers], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoConfusePostfixIdentifierWithKeyword() {
        let input = "var foo = .postfix\noverride init() {}"
        let output = "var foo = .postfix\noverride init() {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.specifiers]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoConfusePostfixIdentifierWithKeyword2() {
        let input = "var foo = postfix\noverride init() {}"
        let output = "var foo = postfix\noverride init() {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.specifiers]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoConfuseCaseWithSpecifier() {
        let input = """
        enum Foo {
            case strong
            case weak
            public init() {}
        }
        """
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.specifiers]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: void

    func testEmptyParensReturnValueConvertedToVoid() {
        let input = "() -> ()"
        let output = "() -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpacedParensReturnValueConvertedToVoid() {
        let input = "() -> ( \n)"
        let output = "() -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensContainingCommentNotConvertedToVoid() {
        let input = "() -> ( /* Hello World */ )"
        let output = "() -> ( /* Hello World */ )"
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensRemovedAroundVoid() {
        let input = "() -> (Void)"
        let output = "() -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testVoidArgumentConvertedToEmptyParens() {
        let input = "Void -> Void"
        let output = "() -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testVoidArgumentInParensNotConvertedToEmptyParens() {
        let input = "(Void) -> Void"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testAnonymousVoidArgumentNotConvertedToEmptyParens() {
        let input = "{ (_: Void) -> Void in }"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testFuncWithAnonymousVoidArgumentNotStripped() {
        let input = "func foo(_: Void) -> Void"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testFunctionThatReturnsAFunction() {
        let input = "(Void) -> Void -> ()"
        let output = "(Void) -> () -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testFunctionThatReturnsAFunctionThatThrows() {
        let input = "(Void) -> Void throws -> ()"
        let output = "(Void) -> () throws -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testChainOfFunctionsIsNotChanged() {
        let input = "() -> () -> () -> Void"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testChainOfFunctionsWithThrowsIsNotChanged() {
        let input = "() -> () throws -> () throws -> Void"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testVoidThrowsIsNotMangled() {
        let input = "(Void) throws -> Void"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testEmptyClosureArgsNotMangled() {
        let input = "{ () in }"
        let output = "{ () in }"
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testEmptyClosureReturnValueConvertedToVoid() {
        let input = "{ () -> () in }"
        let output = "{ () -> Void in }"
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testAnonymousVoidClosureNotChanged() {
        let input = "{ (_: Void) in }"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["unusedArguments"])), output + "\n")
    }

    func testVoidLiteralNotConvertedToParens() {
        let input = "foo(Void())"
        let output = "foo(Void())"
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testMalformedFuncDoesNotCauseInvalidOutput() throws {
        let input = "func baz(Void) {}"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.void]), output)
    }

    // useVoid = false

    func testUseVoidOptionFalse() {
        let input = "(Void) -> Void"
        let output = "(()) -> ()"
        let options = FormatOptions(useVoid: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.void], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNamespacedVoidNotConverted() {
        let input = "() -> Swift.Void"
        let output = "() -> Swift.Void"
        let options = FormatOptions(useVoid: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.void], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testTypealiasVoidNotConverted() {
        let input = "public typealias Void = ()"
        let output = "public typealias Void = ()"
        let options = FormatOptions(useVoid: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.void], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testVoidClosureReturnValueConvertedToEmptyTuple() {
        let input = "{ () -> Void in }"
        let output = "{ () -> () in }"
        let options = FormatOptions(useVoid: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.void], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testVoidLiteralNotConvertedToParensWithVoidOptionFalse() {
        let input = "foo(Void())"
        let output = "foo(Void())"
        let options = FormatOptions(useVoid: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.void], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // MARK: redundantParens

    // around expressions

    func testRedundantParensRemoved() {
        let input = "(x || y)"
        let output = "x || y"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRedundantParensRemoved2() {
        let input = "(x) || y"
        let output = "x || y"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRedundantParensRemoved3() {
        let input = "x + (5)"
        let output = "x + 5"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRedundantParensRemoved4() {
        let input = "(.bar)"
        let output = ".bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRedundantParensRemoved5() {
        let input = "(Foo.bar)"
        let output = "Foo.bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRedundantParensRemoved6() {
        let input = "(foo())"
        let output = "foo()"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRequiredParensNotRemoved() {
        let input = "(x || y) * z"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRequiredParensNotRemoved2() {
        let input = "(x + y) as Int"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRequiredParensNotRemoved3() {
        let input = "a = (x is y)"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRequiredParensNotRemovedBeforeSubscript() {
        let input = "(foo + bar)[baz]"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRedundantParensRemovedBeforeCollectionLiteral() {
        let input = "(foo + bar)\n[baz]"
        let output = "foo + bar\n[baz]"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRequiredParensNotRemovedBeforeFunctionInvocation() {
        let input = "(foo + bar)(baz)"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRedundantParensRemovedBeforeTuple() {
        let input = "(foo + bar)\n(baz, quux).0"
        let output = "foo + bar\n(baz, quux).0"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRequiredParensNotRemovedBeforePostfixOperator() {
        let input = "(foo + bar)!"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRequiredParensNotRemovedBeforeInfixOperator() {
        let input = "(foo + bar) * baz"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testMeaningfulParensNotRemovedAroundSelectorStringLiteral() {
        let input = "Selector((\"foo\"))"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensRemovedOnLineAfterSelectorIdentifier() {
        let input = "Selector\n((\"foo\"))"
        let output = "Selector\n(\"foo\")"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // around conditions

    func testRedundantParensRemovedInIf() {
        let input = "if (x || y) {}"
        let output = "if x || y {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRedundantParensRemovedInIf2() {
        let input = "if (x) || y {}"
        let output = "if x || y {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRedundantParensRemovedInIf3() {
        let input = "if x + (5) == 6 {}"
        let output = "if x + 5 == 6 {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRedundantParensRemovedInIf4() {
        let input = "if (x || y), let foo = bar {}"
        let output = "if x || y, let foo = bar {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRedundantParensRemovedInIf5() {
        let input = "if (.bar) {}"
        let output = "if .bar {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRedundantParensRemovedInIf6() {
        let input = "if (Foo.bar) {}"
        let output = "if Foo.bar {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRedundantParensRemovedInIf7() {
        let input = "if (foo()) {}"
        let output = "if foo() {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRedundantParensRemovedInIf8() {
        let input = "if x, (y == 2) {}"
        let output = "if x, y == 2 {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRequiredParensNotRemovedInIf() {
        let input = "if (x || y) * z {}"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testOuterParensRemovedInWhile() {
        let input = "while ((x || y) && z) {}"
        let output = "while (x || y) && z {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["andOperator"])), output + "\n")
    }

    func testOuterParensRemovedInIf() {
        let input = "if (Foo.bar(baz)) {}"
        let output = "if Foo.bar(baz) {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCaseOuterParensRemoved() {
        let input = "switch foo {\ncase (Foo.bar(let baz)):\n}"
        let output = "switch foo {\ncase Foo.bar(let baz):\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["hoistPatternLet"])), output + "\n")
    }

    func testCaseLetOuterParensRemoved() {
        let input = "switch foo {\ncase let (Foo.bar(baz)):\n}"
        let output = "switch foo {\ncase let Foo.bar(baz):\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCaseVarOuterParensRemoved() {
        let input = "switch foo {\ncase var (Foo.bar(baz)):\n}"
        let output = "switch foo {\ncase var Foo.bar(baz):\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testsTupleNotUnwrapped() {
        let input = "tuple = (1, 2)"
        let output = "tuple = (1, 2)"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testsTupleOfClosuresNotUnwrapped() {
        let input = "tuple = ({}, {})"
        let output = "tuple = ({}, {})"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSwitchTupleNotUnwrapped() {
        let input = "switch (x, y) {}"
        let output = "switch (x, y) {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testGuardParensRemoved() {
        let input = "guard (x == y) else { return }"
        let output = "guard x == y else { return }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testForValueParensRemoved() {
        let input = "for (x) in (y) {}"
        let output = "for x in y {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensInStringNotRemoved() {
        let input = "\"hello \\(world)\""
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testClosureTypeNotUnwrapped() {
        let input = "foo = (Bar) -> Baz"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testOptionalFunctionCallNotUnwrapped() {
        let input = "foo?(bar)"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testForceUnwrapFunctionCallNotUnwrapped() {
        let input = "foo!(bar)"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCurriedFunctionCallNotUnwrapped() {
        let input = "foo(bar)(baz)"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCurriedFunctionCallNotUnwrapped2() {
        let input = "foo(bar)(baz) + quux"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSubscriptFunctionCallNotUnwrapped() {
        let input = "foo[\"bar\"](baz)"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRedundantParensRemovedInsideClosure() {
        let input = "{ (foo) + bar }"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceInsertedWhenRemovingParens() {
        let input = "if(x.y) {}"
        let output = "if x.y {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSpaceInsertedWhenRemovingParens2() {
        let input = "while(!foo) {}"
        let output = "while !foo {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoDoubleSpaceWhenRemovingParens() {
        let input = "if ( x.y ) {}"
        let output = "if x.y {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoDoubleSpaceWhenRemovingParens2() {
        let input = "if (x.y) {}"
        let output = "if x.y {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensAroundRangeNotRemoved() {
        let input = "(1 ..< 10).reduce(0, combine: +)"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensForLoopWhereClauseMethodNotRemoved() {
        let input = "for foo in foos where foo.method() { print(foo) }"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensRemovedAroundFunctionArgument() {
        let input = "foo(bar: (5))"
        let output = "foo(bar: 5)"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRequiredParensNotRemovedAroundOptionalClosureType() {
        let input = "let foo = (() -> ())?"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["void"])), output + "\n")
    }

    func testRedundantParensRemovedAroundOptionalClosureType() {
        let input = "let foo = ((() -> ()))?"
        let output = "let foo = (() -> ())?"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["void"])), output + "\n")
    }

    func testRequiredParensNotRemovedAfterClosureArgument() {
        let input = "foo({ /* code */ }())"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRequiredParensNotRemovedAfterClosureArgument2() {
        let input = "foo(bar: { /* code */ }())"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRequiredParensNotRemovedAfterClosureArgument3() {
        let input = "foo(bar: 5, { /* code */ }())"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRequiredParensNotRemovedAfterClosureInsideArray() {
        let input = "[{ /* code */ }()]"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRequiredParensNotRemovedAfterClosureInsideArrayWithTrailingComma() {
        let input = "[{ /* code */ }(),]"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["trailingCommas"])), output + "\n")
    }

    func testRequiredParensNotRemovedAfterClosureInWhereClause() {
        let input = "case foo where { x == y }():"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // around closure arguments

    func testSingleClosureArgumentUnwrapped() {
        let input = "{ (foo) in }"
        let output = "{ foo in }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["unusedArguments"])), output + "\n")
    }

    func testSingleAnonymousClosureArgumentUnwrapped() {
        let input = "{ (_) in }"
        let output = "{ _ in }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSingleAnonymousClosureArgumentNotUnwrapped() {
        let input = "{ (_ foo) in }"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["unusedArguments"])), output + "\n")
    }

    func testTypedClosureArgumentNotUnwrapped() {
        let input = "{ (foo: Int) in print(foo) }"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSingleClosureArgumentAfterCaptureListUnwrapped() {
        let input = "{ [weak self] (foo) in self.bar(foo) }"
        let output = "{ [weak self] foo in self.bar(foo) }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testMultipleClosureArgumentUnwrapped() {
        let input = "{ (foo, bar) in foo(bar) }"
        let output = "{ foo, bar in foo(bar) }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testTypedMultipleClosureArgumentNotUnwrapped() {
        let input = "{ (foo: Int, bar: String) in foo(bar) }"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testEmptyClosureArgsNotUnwrapped() {
        let input = "{ () in }"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // before trailing closure

    func testParensRemovedBeforeTrailingClosure() {
        let input = "var foo = bar() { /* some code */ }"
        let output = "var foo = bar { /* some code */ }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensRemovedBeforeTrailingClosure2() {
        let input = "let foo = bar() { /* some code */ }"
        let output = "let foo = bar { /* some code */ }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensRemovedBeforeTrailingClosure3() {
        let input = "var foo = bar() { /* some code */ }"
        let output = "var foo = bar { /* some code */ }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensRemovedBeforeTrailingClosureInsideHashIf() {
        let input = "#if baz\n    let foo = bar() { /* some code */ }\n#endif"
        let output = "#if baz\n    let foo = bar { /* some code */ }\n#endif"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedBeforeVarBody() {
        let input = "var foo = bar() { didSet {} }"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedBeforeFunctionBody() {
        let input = "func bar() { /* some code */ }"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedBeforeIfBody() {
        let input = "if let foo = bar() { /* some code */ }"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedBeforeIfBody2() {
        let input = "if try foo as Bar && baz() { /* some code */ }"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["andOperator"])), output + "\n")
    }

    func testParensNotRemovedBeforeIfBody3() {
        let input = "if #selector(foo(_:)) && bar() { /* some code */ }"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["andOperator"])), output + "\n")
    }

    func testParensNotRemovedBeforeIfBody4() {
        let input = "if let data = #imageLiteral(resourceName: \"abc.png\").pngData() { /* some code */ }"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedBeforeIfBodyAfterTry() {
        let input = "if let foo = try bar() { /* some code */ }"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedBeforeCompoundIfBody() {
        let input = "if let foo = bar(), let baz = quux() { /* some code */ }"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedBeforeForBody() {
        let input = "for foo in bar() { /* some code */ }"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedBeforeWhileBody() {
        let input = "while let foo = bar() { /* some code */ }"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedBeforeCaseBody() {
        let input = "if case foo = bar() { /* some code */ }"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedBeforeSwitchBody() {
        let input = "switch foo() {\ndefault: break\n}"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedAfterAnonymousClosureInsideIfStatementBody() {
        let input = "if let foo = bar(), { x == y }() {}"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedInGenericInit() {
        let input = "init<T>(_: T) {}"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedInGenericInit2() {
        let input = "init<T>() {}"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedInGenericFunction() {
        let input = "func foo<T>(_: T) {}"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedInGenericFunction2() {
        let input = "func foo<T>() {}"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedInGenericInstantiation() {
        let input = "let foo = Foo<T>()"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedInGenericInstantiation2() {
        let input = "let foo = Foo<T>(bar)"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRedundantParensRemovedAfterGenerics() {
        let input = "let foo: Foo<T>\n(a) + b"
        let output = "let foo: Foo<T>\na + b"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRedundantParensRemovedAfterGenerics2() {
        let input = "let foo: Foo<T>\n(foo())"
        let output = "let foo: Foo<T>\nfoo()"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // closure expression

    func testParensAroundClosureRemoved() {
        let input = "let foo = ({ /* some code */ })"
        let output = "let foo = { /* some code */ }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensAroundClosureAssignmentBlockRemoved() {
        let input = "let foo = ({ /* some code */ })()"
        let output = "let foo = { /* some code */ }()"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensAroundClosureInCompoundExpressionRemoved() {
        let input = "if foo == ({ /* some code */ }), let bar = baz {}"
        let output = "if foo == { /* some code */ }, let bar = baz {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedAroundClosure() {
        let input = "if (foo { $0 }) {}"
        let output = "if (foo { $0 }) {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedAroundClosure2() {
        let input = "if (foo.filter { $0 > 1 }.isEmpty) {}"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedAroundClosure3() {
        let input = "if let foo = (bar.filter { $0 > 1 }).first {}"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // around tuples

    func testParensRemovedAroundTuple() {
        let input = "let foo = ((bar: Int, baz: String))"
        let output = "let foo = (bar: Int, baz: String)"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedAroundTupleFunctionArgument() {
        let input = "let foo = bar((bar: Int, baz: String))"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedAroundTupleFunctionArgumentAfterSubscript() {
        let input = "bar[5]((bar: Int, baz: String))"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNestedParensRemovedAroundTupleFunctionArgument() {
        let input = "let foo = bar(((bar: Int, baz: String)))"
        let output = "let foo = bar((bar: Int, baz: String))"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNestedParensRemovedAroundTupleFunctionArgument2() {
        let input = "let foo = bar(foo: ((bar: Int, baz: String)))"
        let output = "let foo = bar(foo: (bar: Int, baz: String))"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNestedParensRemovedAroundTupleOperands() {
        let input = "((1, 2)) == ((1, 2))"
        let output = "(1, 2) == (1, 2)"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedAroundTupleFunctionTypeDeclaration() {
        let input = "let foo: ((bar: Int, baz: String)) -> Void"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedAroundUnlabelledTupleFunctionTypeDeclaration() {
        let input = "let foo: ((Int, String)) -> Void"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedAroundTupleFunctionTypeAssignment() {
        let input = "foo = ((bar: Int, baz: String)) -> Void { _ in }"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRedundantParensRemovedAroundTupleFunctionTypeAssignment() {
        let input = "foo = ((((bar: Int, baz: String)))) -> Void { _ in }"
        let output = "foo = ((bar: Int, baz: String)) -> Void { _ in }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedAroundUnlabelledTupleFunctionTypeAssignment() {
        let input = "foo = ((Int, String)) -> Void { _ in }"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRedundantParensRemovedAroundUnlabelledTupleFunctionTypeAssignment() {
        let input = "foo = ((((Int, String)))) -> Void { _ in }"
        let output = "foo = ((Int, String)) -> Void { _ in }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedAroundTupleArgument() {
        let input = "foo((bar, baz))"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // after indexed tuple

    func testParensNotRemovedAfterTupleIndex() {
        let input = "foo.1()"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedAfterTupleIndex2() {
        let input = "foo.1(true)"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensNotRemovedAfterTupleIndex3() {
        let input = "foo.1((bar: Int, baz: String))"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNestedParensRemovedAfterTupleIndex3() {
        let input = "foo.1(((bar: Int, baz: String)))"
        let output = "foo.1((bar: Int, baz: String))"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantParens]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: trailingClosures

    func testAnonymousClosureArgumentMadeTrailing() {
        let input = "foo(foo: 5, { /* some code */ })"
        let output = "foo(foo: 5) { /* some code */ }"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNamedClosureArgumentNotMadeTrailing() {
        let input = "foo(foo: 5, bar: { /* some code */ })"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testClosureArgumentPassedToFunctionInArgumentsNotMadeTrailing() {
        let input = "foo(bar { /* some code */ })"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testClosureArgumentInFunctionWithOtherClosureArgumentsNotMadeTrailing() {
        let input = "foo(foo: { /* some code */ }, { /* some code */ })"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testClosureArgumentInExpressionNotMadeTrailing() {
        let input = "if let foo = foo(foo: 5, { /* some code */ }) {}"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testClosureArgumentInCompoundExpressionNotMadeTrailing() {
        let input = "if let foo = foo(foo: 5, { /* some code */ }), let bar = bar(bar: 2, { /* some code */ }) {}"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testClosureArgumentAfterLinebreakInGuardNotMadeTrailing() {
        let input = "guard let foo =\n    bar({ /* some code */ })\nelse { return }"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testClosureMadeTrailingForNumericTupleMember() {
        let input = "foo.1(5, { bar })"
        let output = "foo.1(5) { bar }"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveParensAroundClosureFollowedByOpeningBrace() {
        let input = "foo({ bar }) { baz }"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // solitary argument

    func testParensAroundSolitaryClosureArgumentRemoved() {
        let input = "foo({ /* some code */ })"
        let output = "foo { /* some code */ }"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensAroundNamedSolitaryClosureArgumentNotRemoved() {
        let input = "foo(foo: { /* some code */ })"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensAroundSolitaryClosureArgumentInExpressionNotRemoved() {
        let input = "if let foo = foo({ /* some code */ }) {}"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensAroundSolitaryClosureArgumentInCompoundExpressionNotRemoved() {
        let input = "if let foo = foo({ /* some code */ }), let bar = bar({ /* some code */ }) {}"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensAroundOptionalTrailingClosureInForLoopNotRemoved() {
        let input = "for foo in bar?.map({ $0.baz }) ?? [] {}"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensAroundTrailingClosureInGuardCaseLetNotRemoved() {
        let input = "guard case let .foo(bar) = baz.filter({ $0 == quux }).isEmpty else {}"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensAroundTrailingClosureInWhereClauseLetNotRemoved() {
        let input = "for foo in bar where baz.filter({ $0 == quux }).isEmpty {}"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testParensAroundTrailingClosureInSwitchNotRemoved() {
        let input = "switch foo({ $0 == bar }).count {}"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSolitaryClosureMadeTrailingInChain() {
        let input = "foo.map({ $0.path }).joined()"
        let output = "foo.map { $0.path }.joined()"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSolitaryClosureMadeTrailingForNumericTupleMember() {
        let input = "foo.1({ bar })"
        let output = "foo.1 { bar }"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // dispatch methods

    func testDispatchAsyncClosureArgumentMadeTrailing() {
        let input = "queue.async(execute: { /* some code */ })"
        let output = "queue.async { /* some code */ }"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testDispatchAsyncGroupClosureArgumentMadeTrailing() {
        // TODO: async(group: , qos: , flags: , execute: )
        let input = "queue.async(group: g, execute: { /* some code */ })"
        let output = "queue.async(group: g) { /* some code */ }"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testDispatchAsyncAfterClosureArgumentMadeTrailing() {
        let input = "queue.asyncAfter(deadline: t, execute: { /* some code */ })"
        let output = "queue.asyncAfter(deadline: t) { /* some code */ }"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testDispatchAsyncAfterWallClosureArgumentMadeTrailing() {
        let input = "queue.asyncAfter(wallDeadline: t, execute: { /* some code */ })"
        let output = "queue.asyncAfter(wallDeadline: t) { /* some code */ }"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testDispatchSyncClosureArgumentMadeTrailing() {
        let input = "queue.sync(execute: { /* some code */ })"
        let output = "queue.sync { /* some code */ }"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testDispatchSyncFlagsClosureArgumentMadeTrailing() {
        let input = "queue.sync(flags: f, execute: { /* some code */ })"
        let output = "queue.sync(flags: f) { /* some code */ }"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // autoreleasepool

    func testAutoreleasepoolMadeTrailing() {
        let input = "autoreleasepool(invoking: { /* some code */ })"
        let output = "autoreleasepool { /* some code */ }"
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // whitelisted methods

    func testCustomMethodMadeTrailing() {
        let input = "foo(bar: 1, baz: { /* some code */ })"
        let output = "foo(bar: 1) { /* some code */ }"
        let options = FormatOptions(trailingClosures: ["foo"])
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // blacklisted methods

    func testPerformBatchUpdatesNotMadeTrailing() {
        let input = "collectionView.performBatchUpdates({ /* some code */ })"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.trailingClosures]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: redundantGet

    func testRemoveSingleLineIsolatedGet() {
        let input = "var foo: Int { get { return 5 } }"
        let output = "var foo: Int { return 5 }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantGet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveMultilineIsolatedGet() {
        let input = "var foo: Int {\n    get {\n        return 5\n    }\n}"
        let output = "var foo: Int {\n    return 5\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantGet, FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveMultilineGetSet() {
        let input = "var foo: Int {\n    get { return 5 }\n    set { foo = newValue }\n}"
        let output = "var foo: Int {\n    get { return 5 }\n    set { foo = newValue }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantGet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveAttributedGet() {
        let input = "var enabled: Bool { @objc(isEnabled) get { return true } }"
        let output = "var enabled: Bool { @objc(isEnabled) get { return true } }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantGet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveSubscriptGet() {
        let input = "subscript(_ index: Int) {\n    get {\n        return lookup(index)\n    }\n}"
        let output = "subscript(_ index: Int) {\n    return lookup(index)\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantGet, FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testGetNotRemovedInFunction() {
        let input = "func foo() {\n    get {\n        return self.lookup(index)\n    }\n}"
        let output = "func foo() {\n    get {\n        return self.lookup(index)\n    }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantGet, FormatRules.indent]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: redundantNilInit

    func testRemoveRedundantNilInit() {
        let input = "var foo: Int? = nil\nlet bar: Int? = nil"
        let output = "var foo: Int?\nlet bar: Int? = nil"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantNilInit]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveLetNilInitAfterVar() {
        let input = "var foo: Int; let bar: Int? = nil"
        let output = "var foo: Int; let bar: Int? = nil"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantNilInit]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveNonNilInit() {
        let input = "var foo: Int? = 0"
        let output = "var foo: Int? = 0"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantNilInit]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveRedundantImplicitUnwrapInit() {
        let input = "var foo: Int! = nil"
        let output = "var foo: Int!"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantNilInit]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveMultipleRedundantNilInitsInSameLine() {
        let input = "var foo: Int? = nil, bar: Int? = nil"
        let output = "var foo: Int?, bar: Int?"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantNilInit]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveLazyVarNilInit() {
        let input = "lazy var foo: Int? = nil"
        let output = "lazy var foo: Int? = nil"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantNilInit]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveLazyPublicPrivateSetVarNilInit() {
        let input = "lazy private(set) public var foo: Int? = nil"
        let output = "lazy private(set) public var foo: Int? = nil"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantNilInit]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["specifiers"])), output + "\n")
    }

    func testNoRemoveCodableNilInit() {
        let input = "struct Foo: Codable, Bar {\n    enum CodingKeys: String, CodingKey {\n        case bar = \"_bar\"\n    }\n\n    var bar: Int?\n    var baz: String? = nil\n}"
        let output = "struct Foo: Codable, Bar {\n    enum CodingKeys: String, CodingKey {\n        case bar = \"_bar\"\n    }\n\n    var bar: Int?\n    var baz: String? = nil\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantNilInit]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: redundantLet

    func testRemoveRedundantLet() {
        let input = "let _ = bar {}"
        let output = "_ = bar {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveLetWithType() {
        let input = "let _: String = bar {}"
        let output = "let _: String = bar {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveRedundantLetInCase() {
        let input = "if case .foo(let _) = bar {}"
        let output = "if case .foo(_) = bar {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantLet]), output)
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet, FormatRules.redundantLet]), output)
        let rules = FormatRules.all(except: ["redundantPattern"])
        XCTAssertEqual(try format(input + "\n", rules: rules), output + "\n")
    }

    func testRemoveRedundantVarsInCase() {
        let input = "if case .foo(var _, var /* unused */ _) = bar {}"
        let output = "if case .foo(_, /* unused */ _) = bar {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantLet]), output)
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet, FormatRules.redundantLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveLetInIf() {
        let input = "if let _ = foo {}"
        let output = "if let _ = foo {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveLetInMultiIf() {
        let input = "if foo == bar, /* comment! */ let _ = baz {}"
        let output = "if foo == bar, /* comment! */ let _ = baz {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveLetInGuard() {
        let input = "guard let _ = foo else {}"
        let output = "guard let _ = foo else {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveLetInWhile() {
        let input = "while let _ = foo {}"
        let output = "while let _ = foo {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: redundantPattern

    func testRemoveRedundantPatternInIfCase() {
        let input = "if case .foo(_, _) = bar {}"
        let output = "if case .foo = bar {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantPattern]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveRequiredPatternInIfCase() {
        let input = "if case (_, _) = bar {}"
        let output = "if case (_, _) = bar {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantPattern]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveRedundantPatternInSwitchCase() {
        let input = "switch foo {\ncase .bar(_, _): break\ndefault: break\n}"
        let output = "switch foo {\ncase .bar: break\ndefault: break\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantPattern]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveRequiredPatternInSwitchCase() {
        let input = "switch foo {\ncase (_, _): break\ndefault: break\n}"
        let output = "switch foo {\ncase (_, _): break\ndefault: break\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantPattern]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveMethodSignature() {
        let input = "func foo(_, _) {}"
        let output = "func foo(_, _) {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantPattern]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: redundantRawValues

    func testRemoveRedundantRawString() {
        let input = "enum Foo: String {\n    case bar = \"bar\"\n    case baz = \"baz\"\n}"
        let output = "enum Foo: String {\n    case bar\n    case baz\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantRawValues]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveCommaDelimitedCaseRawStringCases() {
        let input = "enum Foo: String { case bar = \"bar\", baz = \"baz\" }"
        let output = "enum Foo: String { case bar, baz }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantRawValues]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveRawStringIfNameDoesntMatch() {
        let input = "enum Foo: String {\n    case bar = \"foo\"\n}"
        let output = "enum Foo: String {\n    case bar = \"foo\"\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantRawValues]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: redundantVoidReturnType

    func testRemoveRedundantVoidReturnType() {
        let input = "func foo() -> Void {}"
        let output = "func foo() {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantVoidReturnType]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveRedundantEmptyReturnType() {
        let input = "func foo() -> () {}"
        let output = "func foo() {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantVoidReturnType]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveRedundantVoidTupleReturnType() {
        let input = "func foo() -> (Void) {}"
        let output = "func foo() {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantVoidReturnType]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveCommentFollowingRedundantVoidReturnType() {
        let input = "func foo() -> Void /* void */ {}"
        let output = "func foo() /* void */ {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantVoidReturnType]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveRequiredVoidReturnType() {
        let input = "typealias Foo = () -> Void"
        let output = "typealias Foo = () -> Void"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantVoidReturnType]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveChainedVoidReturnType() {
        let input = "func foo() -> () -> Void {}"
        let output = "func foo() -> () -> Void {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantVoidReturnType]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveRedundantVoidInClosureArguments() {
        let input = "{ (foo: Bar) -> Void in foo() }"
        let output = "{ (foo: Bar) -> Void in foo() }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantVoidReturnType]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: redundantReturn

    func testRemoveRedundantReturnInClosure() {
        let input = "foo(with: { return 5 })"
        let output = "foo(with: { 5 })"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantReturn]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["trailingClosures"])), output + "\n")
    }

    func testRemoveRedundantReturnInClosureWithArgs() {
        let input = "foo(with: { foo in return foo })"
        let output = "foo(with: { foo in foo })"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantReturn]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["trailingClosures"])), output + "\n")
    }

    func testRemoveRedundantReturnInMap() {
        let input = "let foo = bar.map { return 1 }"
        let output = "let foo = bar.map { 1 }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantReturn]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveReturnInComputedVar() {
        let input = "var foo: Int { return 5 }"
        let output = "var foo: Int { return 5 }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantReturn]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveReturnInGet() {
        let input = "var foo: Int {\n    get { return 5 }\n    set { _foo = newValue }\n}"
        let output = "var foo: Int {\n    get { return 5 }\n    set { _foo = newValue }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantReturn]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveReturnInVarClosure() {
        let input = "var foo = { return 5 }()"
        let output = "var foo = { 5 }()"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantReturn]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveReturnInParenthesizedClosure() {
        let input = "var foo = ({ return 5 }())"
        let output = "var foo = ({ 5 }())"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantReturn]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["redundantParens"])), output + "\n")
    }

    func testNoRemoveReturnInFunction() {
        let input = "func foo() -> Int { return 5 }"
        let output = "func foo() -> Int { return 5 }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantReturn]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveReturnInForIn() {
        let input = "for foo in bar { return 5 }"
        let output = "for foo in bar { return 5 }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantReturn]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveReturnInForWhere() {
        let input = "for foo in bar where baz { return 5 }"
        let output = "for foo in bar where baz { return 5 }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantReturn]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveReturnInIfLetTry() {
        let input = "if let foo = try? bar() { return 5 }"
        let output = "if let foo = try? bar() { return 5 }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantReturn]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveReturnInMultiIfLetTry() {
        let input = "if let foo = bar, let bar = baz { return 5 }"
        let output = "if let foo = bar, let bar = baz { return 5 }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantReturn]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveReturnAfterMultipleAs() {
        let input = "if foo as? bar as? baz { return 5 }"
        let output = "if foo as? bar as? baz { return 5 }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantReturn]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveVoidReturn() {
        let input = "{ _ in return }"
        let output = "{ _ in }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantReturn]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveReturnAfterKeyPath() {
        let input = "func foo() { if bar == #keyPath(baz) { return 5 } }"
        let output = "func foo() { if bar == #keyPath(baz) { return 5 } }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantReturn]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveReturnAfterParentheses() {
        let input = "if let foo = (bar as? String) { return foo }"
        let output = "if let foo = (bar as? String) { return foo }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantReturn]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveReturnInTupleVarGetter() {
        let input = "var foo: (Int, Int) { return (1, 2) }"
        let output = "var foo: (Int, Int) { return (1, 2) }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantReturn]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: redundantBackticks

    func testRemoveRedundantBackticksInLet() {
        let input = "let `foo` = bar"
        let output = "let foo = bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantBackticks]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveBackticksAroundKeyword() {
        let input = "let `let` = foo"
        let output = "let `let` = foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantBackticks]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveBackticksAroundSelf() {
        let input = "let `self` = foo"
        let output = "let `self` = foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantBackticks]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveBackticksAroundClassSelf() {
        let input = "typealias `Self` = Foo"
        let output = "typealias `Self` = Foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantBackticks]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveBackticksAroundSelfArgument() {
        let input = "func foo(`self`: Foo) { print(self) }"
        let output = "func foo(self: Foo) { print(self) }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantBackticks]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveBackticksAroundKeywordFollowedByType() {
        let input = "let `default`: Int = foo"
        let output = "let `default`: Int = foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantBackticks]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveBackticksAroundContextualGet() {
        let input = "var foo: Int {\n    `get`()\n    return 5\n}"
        let output = "var foo: Int {\n    `get`()\n    return 5\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantBackticks]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveBackticksAroundGetArgument() {
        let input = "func foo(`get` value: Int) { print(value) }"
        let output = "func foo(get value: Int) { print(value) }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantBackticks]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveBackticksAroundTypeAtRootLevel() {
        let input = "enum `Type` {}"
        let output = "enum Type {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantBackticks]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveBackticksAroundTypeInsideType() {
        let input = "struct Foo {\n    enum `Type` {}\n}"
        let output = "struct Foo {\n    enum `Type` {}\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantBackticks]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveBackticksAroundLetArgument() {
        let input = "func foo(`let`: Foo) { print(`let`) }"
        let output = "func foo(`let`: Foo) { print(`let`) }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantBackticks]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveBackticksAroundTypeProperty() {
        let input = "var type: Foo.`Type`"
        let output = "var type: Foo.`Type`"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantBackticks]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveBackticksAroundTypePropertyInsideType() {
        let input = "struct Foo {\n    enum `Type` {}\n}"
        let output = "struct Foo {\n    enum `Type` {}\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantBackticks]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveBackticksAroundTrueProperty() {
        let input = "var type = Foo.`true`"
        let output = "var type = Foo.`true`"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantBackticks]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveBackticksAroundProperty() {
        let input = "var type = Foo.`bar`"
        let output = "var type = Foo.bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantBackticks]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveBackticksAroundKeywordProperty() {
        let input = "var type = Foo.`default`"
        let output = "var type = Foo.default"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantBackticks]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveBackticksAroundKeypathProperty() {
        let input = "var type = \\.`bar`"
        let output = "var type = \\.bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantBackticks]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveBackticksAroundKeypathKeywordProperty() {
        let input = "var type = \\.`default`"
        let output = "var type = \\.`default`"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantBackticks]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveBackticksAroundAnyProperty() {
        let input = "enum Foo {\n    case `Any`\n}"
        let output = "enum Foo {\n    case `Any`\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantBackticks]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: redundantSelf

    // explicitSelf = .remove

    func testSimpleRemoveRedundantSelf() {
        let input = "func foo() { self.bar() }"
        let output = "func foo() { bar() }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveSelfInsideStringInterpolation() {
        let input = "class Foo {\n    var bar: String?\n    func baz() {\n        print(\"\\(self.bar)\")\n    }\n}"
        let output = "class Foo {\n    var bar: String?\n    func baz() {\n        print(\"\\(bar)\")\n    }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfForArgument() {
        let input = "func foo(bar: Int) { self.bar = bar }"
        let output = "func foo(bar: Int) { self.bar = bar }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfForLocalVariable() {
        let input = "func foo() { var bar = self.bar }"
        let output = "func foo() { var bar = self.bar }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfForCommaDelimitedLocalVariables() {
        let input = "func foo() { let foo = self.foo, bar = self.bar }"
        let output = "func foo() { let foo = self.foo, bar = self.bar }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfForCommaDelimitedLocalVariables2() {
        let input = "func foo() {\n    let foo: Foo, bar: Bar\n    foo = self.foo\n    bar = self.bar\n}"
        let output = "func foo() {\n    let foo: Foo, bar: Bar\n    foo = self.foo\n    bar = self.bar\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfForTupleAssignedVariables() {
        let input = "func foo() { let (foo, bar) = (self.foo, self.bar) }"
        let output = "func foo() { let (foo, bar) = (self.foo, self.bar) }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfForTupleAssignedVariablesFollowedByRegularVariable() {
        let input = "func foo() {\n    let (foo, bar) = (self.foo, self.bar), baz = self.baz\n}"
        let output = "func foo() {\n    let (foo, bar) = (self.foo, self.bar), baz = self.baz\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfForTupleAssignedVariablesFollowedByRegularLet() {
        let input = "func foo() {\n    let (foo, bar) = (self.foo, self.bar)\n    let baz = self.baz\n}"
        let output = "func foo() {\n    let (foo, bar) = (self.foo, self.bar)\n    let baz = self.baz\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveNonRedundantNestedFunctionSelf() {
        let input = "func foo() { func bar() { self.bar() } }"
        let output = "func foo() { func bar() { self.bar() } }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveNonRedundantNestedFunctionSelf2() {
        let input = "func foo() {\n    func bar() {}\n    self.bar()\n}"
        let output = "func foo() {\n    func bar() {}\n    self.bar()\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveNonRedundantNestedFunctionSelf3() {
        let input = "func foo() { let bar = 5; func bar() { self.bar = bar } }"
        let output = "func foo() { let bar = 5; func bar() { self.bar = bar } }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveClosureSelf() {
        let input = "func foo() { bar { self.bar = 5 } }"
        let output = "func foo() { bar { self.bar = 5 } }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfAfterOptionalReturn() {
        let input = "func foo() -> String? {\n    var index = startIndex\n    if !matching(self[index]) {\n        break\n    }\n    index = self.index(after: index)\n}"
        let output = "func foo() -> String? {\n    var index = startIndex\n    if !matching(self[index]) {\n        break\n    }\n    index = self.index(after: index)\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveRequiredSelfInExtensions() {
        let input = "extension Foo {\n    func foo() {\n        var index = 5\n        if true {\n            break\n        }\n        index = self.index(after: index)\n    }\n}"
        let output = "extension Foo {\n    func foo() {\n        var index = 5\n        if true {\n            break\n        }\n        index = self.index(after: index)\n    }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfBeforeInit() {
        let input = "convenience init() { self.init(5) }"
        let output = "convenience init() { self.init(5) }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveSelfInsideSwitch() {
        let input = "func foo() {\n    switch self.bar {\n    case .foo:\n        self.baz()\n    }\n}"
        let output = "func foo() {\n    switch bar {\n    case .foo:\n        baz()\n    }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveSelfInsideSwitchWhere() {
        let input = "func foo() {\n    switch self.bar {\n    case .foo where a == b:\n        self.baz()\n    }\n}"
        let output = "func foo() {\n    switch bar {\n    case .foo where a == b:\n        baz()\n    }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveSelfInsideSwitchWhereAs() {
        let input = "func foo() {\n    switch self.bar {\n    case .foo where a == b as C:\n        self.baz()\n    }\n}"
        let output = "func foo() {\n    switch bar {\n    case .foo where a == b as C:\n        baz()\n    }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveSelfInsideClassInit() {
        let input = "class Foo {\n    var bar = 5\n    init() { self.bar = 6 }\n}"
        let output = "class Foo {\n    var bar = 5\n    init() { bar = 6 }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfInClosureInsideIf() {
        let input = "if foo { bar { self.baz() } }"
        let output = "if foo { bar { self.baz() } }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfForErrorInCatch() {
        let input = "do {} catch { self.error = error }"
        let output = "do {} catch { self.error = error }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfForNewValueInSet() {
        let input = "var foo: Int { set { self.newValue = newValue } get { return 0 } }"
        let output = "var foo: Int { set { self.newValue = newValue } get { return 0 } }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfForCustomNewValueInSet() {
        let input = "var foo: Int { set(n00b) { self.n00b = n00b } get { return 0 } }"
        let output = "var foo: Int { set(n00b) { self.n00b = n00b } get { return 0 } }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfForNewValueInWillSet() {
        let input = "var foo: Int { willSet { self.newValue = newValue } }"
        let output = "var foo: Int { willSet { self.newValue = newValue } }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfForCustomNewValueInWillSet() {
        let input = "var foo: Int { willSet(n00b) { self.n00b = n00b } }"
        let output = "var foo: Int { willSet(n00b) { self.n00b = n00b } }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfForOldValueInDidSet() {
        let input = "var foo: Int { didSet { self.oldValue = oldValue } }"
        let output = "var foo: Int { didSet { self.oldValue = oldValue } }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfForCustomOldValueInDidSet() {
        let input = "var foo: Int { didSet(oldz) { self.oldz = oldz } }"
        let output = "var foo: Int { didSet(oldz) { self.oldz = oldz } }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfForIndexVarInFor() {
        let input = "for foo in bar { self.foo = foo }"
        let output = "for foo in bar { self.foo = foo }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfForKeyValueTupleInFor() {
        let input = "for (foo, bar) in baz { self.foo = foo; self.bar = bar }"
        let output = "for (foo, bar) in baz { self.foo = foo; self.bar = bar }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveSelfFromComputedVar() {
        let input = "var foo: Int { return self.bar }"
        let output = "var foo: Int { return bar }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveSelfFromOptionalComputedVar() {
        let input = "var foo: Int? { return self.bar }"
        let output = "var foo: Int? { return bar }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveSelfFromNamespacedComputedVar() {
        let input = "var foo: Swift.String { return self.bar }"
        let output = "var foo: Swift.String { return bar }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveSelfFromGenericComputedVar() {
        let input = "var foo: Foo<Int> { return self.bar }"
        let output = "var foo: Foo<Int> { return bar }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveSelfFromComputedArrayVar() {
        let input = "var foo: [Int] { return self.bar }"
        let output = "var foo: [Int] { return bar }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveSelfFromVarSetter() {
        let input = "var foo: Int { didSet { self.bar() } }"
        let output = "var foo: Int { didSet { bar() } }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfFromVarClosure() {
        let input = "var foo = { self.bar }"
        let output = "var foo = { self.bar }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfFromLazyVar() {
        let input = "lazy var foo = self.bar"
        let output = "lazy var foo = self.bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfFromLazyVarClosure() {
        let input = "lazy var foo = { self.bar }()"
        let output = "lazy var foo = { self.bar }()"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfFromLazyVarClosure2() {
        let input = "lazy var foo = { let bar = self.baz }()"
        let output = "lazy var foo = { let bar = self.baz }()"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfFromLazyVarClosure3() {
        let input = "lazy var foo = { [unowned self] in let bar = self.baz }()"
        let output = "lazy var foo = { [unowned self] in let bar = self.baz }()"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveSelfFromVarInFuncWithUnusedArgument() {
        let input = "func foo(bar _: Int) { self.baz = 5 }"
        let output = "func foo(bar _: Int) { baz = 5 }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveSelfFromVarMatchingUnusedArgument() {
        let input = "func foo(bar _: Int) { self.bar = 5 }"
        let output = "func foo(bar _: Int) { bar = 5 }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfFromVarMatchingRenamedArgument() {
        let input = "func foo(bar baz: Int) { self.baz = baz }"
        let output = "func foo(bar baz: Int) { self.baz = baz }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfFromVarRedeclaredInSubscope() {
        let input = "func foo() {\n    if quux {\n        let bar = 5\n    }\n    let baz = self.bar\n}"
        let output = "func foo() {\n    if quux {\n        let bar = 5\n    }\n    let baz = bar\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfFromVarDeclaredLaterInScope() {
        let input = "func foo() {\n    let bar = self.baz\n    let baz = quux\n}"
        let output = "func foo() {\n    let bar = self.baz\n    let baz = quux\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfFromVarDeclaredLaterInOuterScope() {
        let input = "func foo() {\n    if quux {\n        let bar = self.baz\n    }\n    let baz = 6\n}"
        let output = "func foo() {\n    if quux {\n        let bar = self.baz\n    }\n    let baz = 6\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfFromKeyword() {
        let input = "func foo() { self.default = 5 }"
        let output = "func foo() { `default` = 5 }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfInWhilePreceededByVarDeclaration() {
        let input = "var index = start\nwhile index < end {\n    index = self.index(after: index)\n}"
        let output = "var index = start\nwhile index < end {\n    index = self.index(after: index)\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfInLocalVarPrecededByLocalVarFollowedByIfComma() {
        let input = "func foo() {\n    let bar = Bar()\n    let baz = Baz()\n    self.baz = baz\n    if let bar = bar, bar > 0 {}\n}"
        let output = "func foo() {\n    let bar = Bar()\n    let baz = Baz()\n    self.baz = baz\n    if let bar = bar, bar > 0 {}\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfInLocalVarPrecededByIfLetContainingClosure() {
        let input = "func foo() {\n    if let bar = 5 { baz { _ in } }\n    let quux = self.quux\n}"
        let output = "func foo() {\n    if let bar = 5 { baz { _ in } }\n    let quux = self.quux\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfForVarCreatedInGuardScope() {
        let input = "func foo() {\n    guard let bar = 5 else {}\n    let baz = self.bar\n}"
        let output = "func foo() {\n    guard let bar = 5 else {}\n    let baz = self.bar\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveSelfForVarCreatedInIfScope() {
        let input = "func foo() {\n    if let bar = bar {}\n    let baz = self.bar\n}"
        let output = "func foo() {\n    if let bar = bar {}\n    let baz = bar\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfForVarDeclaredInWhileCondition() {
        let input = "while let foo = bar { self.foo = foo }"
        let output = "while let foo = bar { self.foo = foo }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveSelfForVarNotDeclaredInWhileCondition() {
        let input = "while let foo == bar { self.baz = 5 }"
        let output = "while let foo == bar { baz = 5 }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfForVarDeclaredInSwitchCase() {
        let input = "switch foo {\ncase bar: let baz = self.baz\n}"
        let output = "switch foo {\ncase bar: let baz = self.baz\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfAfterGenericInit() {
        let input = "init(bar: Int) {\n    self = Foo<Bar>()\n    self.bar(bar)\n}"
        let output = "init(bar: Int) {\n    self = Foo<Bar>()\n    self.bar(bar)\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveSelfInClassFunction() {
        let input = "class Foo {\n    class func foo() {\n        func bar() { self.foo() }\n    }\n}"
        let output = "class Foo {\n    class func foo() {\n        func bar() { foo() }\n    }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveSelfInStaticFunction() {
        let input = "struct Foo {\n    static func foo() {\n        func bar() { self.foo() }\n    }\n}"
        let output = "struct Foo {\n    static func foo() {\n        func bar() { foo() }\n    }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveSelfInClassFunctionWithSpecifiers() {
        let input = "class Foo {\n    class private func foo() {\n        func bar() { self.foo() }\n    }\n}"
        let output = "class Foo {\n    class private func foo() {\n        func bar() { foo() }\n    }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["specifiers"])), output + "\n")
    }

    func testNoRemoveSelfInClassFunction() {
        let input = "class Foo {\n    class func foo() {\n        var foo: Int\n        func bar() { self.foo() }\n    }\n}"
        let output = "class Foo {\n    class func foo() {\n        var foo: Int\n        func bar() { self.foo() }\n    }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfForVarDeclaredAfterRepeatWhile() {
        let input = "class Foo {\n    let foo = 5\n    func bar() {\n        repeat {} while foo\n        let foo = 6\n        self.foo()\n    }\n}"
        let output = "class Foo {\n    let foo = 5\n    func bar() {\n        repeat {} while foo\n        let foo = 6\n        self.foo()\n    }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfForVarInClosureAfterRepeatWhile() {
        let input = "class Foo {\n    let foo = 5\n    func bar() {\n        repeat {} while foo\n        ({ self.foo() })()\n    }\n}"
        let output = "class Foo {\n    let foo = 5\n    func bar() {\n        repeat {} while foo\n        ({ self.foo() })()\n    }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfInClosureAfterVar() {
        let input = "var foo: String\nbar { self.baz() }"
        let output = "var foo: String\nbar { self.baz() }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfInClosureAfterNamespacedVar() {
        let input = "var foo: Swift.String\nbar { self.baz() }"
        let output = "var foo: Swift.String\nbar { self.baz() }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfInClosureAfterOptionalVar() {
        let input = "var foo: String?\nbar { self.baz() }"
        let output = "var foo: String?\nbar { self.baz() }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfInClosureAfterGenericVar() {
        let input = "var foo: Foo<Int>\nbar { self.baz() }"
        let output = "var foo: Foo<Int>\nbar { self.baz() }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfInClosureAfterArray() {
        let input = "var foo: [Int]\nbar { self.baz() }"
        let output = "var foo: [Int]\nbar { self.baz() }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        let output = input
        let options = FormatOptions(selfRequired: ["log"])
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSelfNotRemovedInClosureInCaseWithWhereClause() {
        let input = """
        switch foo {
        case bar where baz:
            quux = { self.foo }
        }
        """
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSelfNotRemovedInGetter() {
        let input = """
        class Foo {
            var bar: Int {
                return self.bar
            }
        }
        """
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSelfNotRemovedInIfdef() {
        let input = """
        func foo() {
            #if os(macOS)
                let bar = self.bar
            #endif
        }
        """
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRedundantSelfDoesntGetStuckIfNoParensFound() {
        let input = "init<T>_ foo: T {}"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveSelfInClosureInIfCondition() {
        let input = """
        class Foo {
            func foo() {
                if bar({ self.baz() }) {}
            }
        }
        """
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // explicitSelf = .insert

    func testInsertSelf() {
        let input = "class Foo {\n    let foo: Int\n    init() { foo = 5 }\n}"
        let output = "class Foo {\n    let foo: Int\n    init() { self.foo = 5 }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testInsertSelfAfterReturn() {
        let input = "class Foo {\n    let foo: Int\n    func bar() -> Int { return foo }\n}"
        let output = "class Foo {\n    let foo: Int\n    func bar() -> Int { return self.foo }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testInsertSelfInsideStringInterpolation() {
        let input = "class Foo {\n    var bar: String?\n    func baz() {\n        print(\"\\(bar)\")\n    }\n}"
        let output = "class Foo {\n    var bar: String?\n    func baz() {\n        print(\"\\(self.bar)\")\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoInterpretGenericTypesAsMembers() {
        let input = "class Foo {\n    let foo: Bar<Int, Int>\n    init() { self.foo = Int(5) }\n}"
        let output = "class Foo {\n    let foo: Bar<Int, Int>\n    init() { self.foo = Int(5) }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testInsertSelfForStaticMemberInClassFunction() {
        let input = "class Foo {\n    static var foo: Int\n    class func bar() { foo = 5 }\n}"
        let output = "class Foo {\n    static var foo: Int\n    class func bar() { self.foo = 5 }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoInsertSelfForInstanceMemberInClassFunction() {
        let input = "class Foo {\n    var foo: Int\n    class func bar() { foo = 5 }\n}"
        let output = "class Foo {\n    var foo: Int\n    class func bar() { foo = 5 }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoInsertSelfForStaticMemberInInstanceFunction() {
        let input = "class Foo {\n    static var foo: Int\n    func bar() { foo = 5 }\n}"
        let output = "class Foo {\n    static var foo: Int\n    func bar() { foo = 5 }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoInsertSelfForShadowedClassMemberInClassFunction() {
        let input = "class Foo {\n    class func foo() {\n        var foo: Int\n        func bar() { foo = 5 }\n    }\n}"
        let output = "class Foo {\n    class func foo() {\n        var foo: Int\n        func bar() { foo = 5 }\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoInsertSelfInForLoopTuple() {
        let input = "class Foo {\n    var bar: Int\n    func foo() { for (bar, baz) in quux {} }\n}"
        let output = "class Foo {\n    var bar: Int\n    func foo() { for (bar, baz) in quux {} }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoInsertSelfForTupleTypeMembers() {
        let input = "class Foo {\n    var foo: (Int, UIColor) {\n        let bar = UIColor.red\n    }\n}"
        let output = "class Foo {\n    var foo: (Int, UIColor) {\n        let bar = UIColor.red\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoInsertSelfForArrayElements() {
        let input = "class Foo {\n    var foo = [1, 2, nil]\n    func bar() { baz(nil) }\n}"
        let output = "class Foo {\n    var foo = [1, 2, nil]\n    func bar() { baz(nil) }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoInsertSelfForNestedVarReference() {
        let input = "class Foo {\n    func bar() {\n        var bar = 5\n        repeat { bar = 6 } while true\n    }\n}"
        let output = "class Foo {\n    func bar() {\n        var bar = 5\n        repeat { bar = 6 } while true\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoInsertSelfInSwitchCaseLet() {
        let input = "class Foo {\n    var foo: Bar? {\n        switch bar {\n        case let .baz(foo, _):\n            return nil\n        }\n    }\n}"
        let output = "class Foo {\n    var foo: Bar? {\n        switch bar {\n        case let .baz(foo, _):\n            return nil\n        }\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoInsertSelfInFuncAfterImportedClass() {
        let input = "import class Foo.Bar\nfunc foo() {\n    var bar = 5\n    if true {\n        bar = 6\n    }\n}"
        let output = "import class Foo.Bar\nfunc foo() {\n    var bar = 5\n    if true {\n        bar = 6\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoInsertSelfForSubscriptGetSet() {
        let input = "class Foo {\n    func get() {}\n    func set() {}\n    subscript(key: String) -> String {\n        get { return get(key) }\n        set { set(key, newValue) }\n    }\n}"
        let output = "class Foo {\n    func get() {}\n    func set() {}\n    subscript(key: String) -> String {\n        get { return self.get(key) }\n        set { self.set(key, newValue) }\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoInsertSelfInIfCaseLet() {
        let input = "enum Foo {\n    case bar(Int)\n    var value: Int? {\n        if case let .bar(value) = self { return value }\n    }\n}"
        let output = "enum Foo {\n    case bar(Int)\n    var value: Int? {\n        if case let .bar(value) = self { return value }\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoInsertSelfForPatternLet() {
        let input = "class Foo {\n    func foo() {}\n    func bar() {\n        switch x {\n        case .bar(let foo, var bar): print(foo + bar)\n        }\n    }\n}"
        let output = "class Foo {\n    func foo() {}\n    func bar() {\n        switch x {\n        case .bar(let foo, var bar): print(foo + bar)\n        }\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoInsertSelfForPatternLet2() {
        let input = "class Foo {\n    func foo() {}\n    func bar() {\n        switch x {\n        case let .foo(baz): print(baz)\n        case .bar(let foo, var bar): print(foo + bar)\n        }\n    }\n}"
        let output = "class Foo {\n    func foo() {}\n    func bar() {\n        switch x {\n        case let .foo(baz): print(baz)\n        case .bar(let foo, var bar): print(foo + bar)\n        }\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoInsertSelfForTypeOf() {
        let input = "class Foo {\n    var type: String?\n    func bar() {\n        print(\"\\(type(of: self))\")\n    }\n}"
        let output = "class Foo {\n    var type: String?\n    func bar() {\n        print(\"\\(type(of: self))\")\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoInsertSelfForConditionalLocal() {
        let input = "class Foo {\n    func foo() {\n        #if os(watchOS)\n            var foo: Int\n        #else\n            var foo: Float\n        #endif\n        print(foo)\n    }\n}"
        let output = "class Foo {\n    func foo() {\n        #if os(watchOS)\n            var foo: Int\n        #else\n            var foo: Float\n        #endif\n        print(foo)\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        let output = input
        let options = FormatOptions(explicitSelf: .insert)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        let output = input
        let options = FormatOptions(explicitSelf: .insert)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        let output = input
        let options = FormatOptions(explicitSelf: .insert)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        let output = input
        let options = FormatOptions(explicitSelf: .insert)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        let output = input
        let options = FormatOptions(explicitSelf: .insert)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        let output = input
        let options = FormatOptions(explicitSelf: .insert)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        let output = input
        let options = FormatOptions(explicitSelf: .initOnly)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertNoThrow(try format(input, rules: [FormatRules.redundantSelf], options: options))
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertEqual(try format(input, rules: FormatRules.named(["redundantSelf"])), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        XCTAssertEqual(try format(input, rules: FormatRules.named(["redundantSelf"])), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        XCTAssertEqual(try format(input, rules: FormatRules.named(["redundantSelf"])), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        XCTAssertEqual(try format(input, rules: FormatRules.named(["redundantSelf"])), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: unusedArguments

    // closures

    func testUnusedTypedClosureArguments() {
        let input = "let foo = { (bar: Int, baz: String) in\n    print(\"Hello \\(baz)\")\n}"
        let output = "let foo = { (_: Int, baz: String) in\n    print(\"Hello \\(baz)\")\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testUnusedUntypedClosureArguments() {
        let input = "let foo = { bar, baz in\n    print(\"Hello \\(baz)\")\n}"
        let output = "let foo = { _, baz in\n    print(\"Hello \\(baz)\")\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveClosureReturnType() {
        let input = "let foo = { () -> Foo.Bar in baz() }"
        let output = "let foo = { () -> Foo.Bar in baz() }"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveClosureThrows() {
        let input = "let foo = { () throws in }"
        let output = "let foo = { () throws in }"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveClosureGenericReturnTypes() {
        let input = "let foo = { () -> Promise<String> in bar }"
        let output = "let foo = { () -> Promise<String> in bar }"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveClosureTupleReturnTypes() {
        let input = "let foo = { () -> (Int, Int) in (5, 6) }"
        let output = "let foo = { () -> (Int, Int) in (5, 6) }"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveClosureGenericArgumentTypes() {
        let input = "let foo = { (_: Foo<Bar, Baz>) in }"
        let output = "let foo = { (_: Foo<Bar, Baz>) in }"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveFunctionNameBeforeForLoop() {
        let input = "{\n    func foo() -> Int {}\n    for a in b {}\n}"
        let output = "{\n    func foo() -> Int {}\n    for a in b {}\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testClosureTypeInClosureArgumentsIsNotMangled() {
        let input = "{ (foo: (Int) -> Void) in }"
        let output = "{ (_: (Int) -> Void) in }"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testUnusedUnnamedClosureArguments() {
        let input = "{ (_ foo: Int, _ bar: Int) in }"
        let output = "{ (_: Int, _: Int) in }"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testUnusedInoutClosureArgumentsNotMangled() {
        let input = "{ (foo: inout Foo, bar: inout Bar) in }"
        let output = "{ (_: inout Foo, _: inout Bar) in }"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testMalformedFunctionNotMisidentifiedAsClosure() {
        let input = "func foo() { bar(5) {} in }"
        let output = "func foo() { bar(5) {} in }"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // functions

    func testMarkUnusedFunctionArgument() {
        let input = "func foo(bar: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        let output = "func foo(bar _: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testMarkUnusedArgumentsInNonVoidFunction() {
        let input = "func foo(bar: Int, baz: String) -> (A<B, C>, D & E, [F: G]) { return baz.quux }"
        let output = "func foo(bar _: Int, baz: String) -> (A<B, C>, D & E, [F: G]) { return baz.quux }"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testMarkUnusedArgumentsInThrowsFunction() {
        let input = "func foo(bar: Int, baz: String) throws {\n    print(\"Hello \\(baz)\")\n}"
        let output = "func foo(bar _: Int, baz: String) throws {\n    print(\"Hello \\(baz)\")\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testMarkUnusedArgumentsInOptionalReturningFunction() {
        let input = "func foo(bar: Int, baz: String) -> String? {\n    return \"Hello \\(baz)\"\n}"
        let output = "func foo(bar _: Int, baz: String) -> String? {\n    return \"Hello \\(baz)\"\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoMarkUnusedArgumentsInProtocolFunction() {
        let input = "protocol Foo {\n    func foo(bar: Int) -> Int\n    var bar: Int { get }\n}"
        let output = "protocol Foo {\n    func foo(bar: Int) -> Int\n    var bar: Int { get }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testUnusedUnnamedFunctionArgument() {
        let input = "func foo(_ foo: Int) {}"
        let output = "func foo(_: Int) {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testUnusedInoutFunctionArgumentIsNotMangled() {
        let input = "func foo(_ foo: inout Foo) {}"
        let output = "func foo(_: inout Foo) {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testUnusedInternallyRenamedFunctionArgument() {
        let input = "func foo(foo bar: Int) {}"
        let output = "func foo(foo _: Int) {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoMarkProtocolFunctionArgument() {
        let input = "func foo(foo bar: Int)\nvar bar: Bool { get }"
        let output = "func foo(foo bar: Int)\nvar bar: Bool { get }"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testMembersAreNotArguments() {
        let input = "func foo(bar: Int, baz: String) {\n    print(\"Hello \\(bar.baz)\")\n}"
        let output = "func foo(bar: Int, baz _: String) {\n    print(\"Hello \\(bar.baz)\")\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testLabelsAreNotArguments() {
        let input = "func foo(bar: Int, baz: String) {\n    bar: while true { print(baz) }\n}"
        let output = "func foo(bar _: Int, baz: String) {\n    bar: while true { print(baz) }\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testDictionaryLiteralsRuinEverything() {
        let input = "func foo(bar: Int, baz: Int) {\n    let quux = [bar: 1, baz: 2]\n}"
        let output = "func foo(bar: Int, baz: Int) {\n    let quux = [bar: 1, baz: 2]\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testOperatorArgumentsAreUnnamed() {
        let input = "func == (lhs: Int, rhs: Int) { return false }"
        let output = "func == (_: Int, _: Int) { return false }"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testUnusedtFailableInitArgumentsAreNotMangled() {
        let input = "init?(foo: Bar) {}"
        let output = "init?(foo _: Bar) {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testTreatEscapedArgumentsAsUsed() {
        let input = "func foo(default: Int) -> Int {\n    return `default`\n}"
        let output = "func foo(default: Int) -> Int {\n    return `default`\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // functions (closure-only)

    func testNoMarkFunctionArgument() {
        let input = "func foo(_ bar: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        let output = "func foo(_ bar: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        let options = FormatOptions(stripUnusedArguments: .closureOnly)
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // functions (unnamed-only)

    func testNoMarkNamedFunctionArgument() {
        let input = "func foo(bar: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        let output = "func foo(bar: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        let options = FormatOptions(stripUnusedArguments: .unnamedOnly)
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testRemoveUnnamedFunctionArgument() {
        let input = "func foo(_ foo: Int) {}"
        let output = "func foo(_: Int) {}"
        let options = FormatOptions(stripUnusedArguments: .unnamedOnly)
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testRemoveInternalFunctionArgumentName() {
        let input = "func foo(foo bar: Int) {}"
        let output = "func foo(foo bar: Int) {}"
        let options = FormatOptions(stripUnusedArguments: .unnamedOnly)
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // init

    func testMarkUnusedInitArgument() {
        let input = "init(bar: Int, baz: String) {\n    self.baz = baz\n}"
        let output = "init(bar _: Int, baz: String) {\n    self.baz = baz\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // subscript

    func testMarkUnusedSubscriptArgument() {
        let input = "subscript(foo: Int, baz: String) -> String {\n    return get(baz)\n}"
        let output = "subscript(_: Int, baz: String) -> String {\n    return get(baz)\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testMarkUnusedUnnamedSubscriptArgument() {
        let input = "subscript(_ foo: Int, baz: String) -> String {\n    return get(baz)\n}"
        let output = "subscript(_: Int, baz: String) -> String {\n    return get(baz)\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testMarkUnusedNamedSubscriptArgument() {
        let input = "subscript(foo foo: Int, baz: String) -> String {\n    return get(baz)\n}"
        let output = "subscript(foo _: Int, baz: String) -> String {\n    return get(baz)\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.unusedArguments]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: hoistPatternLet

    // hoist = true

    func testHoistCaseLet() {
        let input = "if case .foo(let bar, let baz) = quux {}"
        let output = "if case let .foo(bar, baz) = quux {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testHoistCaseVar() {
        let input = "if case .foo(var bar, var baz) = quux {}"
        let output = "if case var .foo(bar, baz) = quux {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoHoistMixedCaseLetVar() {
        let input = "if case .foo(let bar, var baz) = quux {}"
        let output = "if case .foo(let bar, var baz) = quux {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoHoistIfFirstArgSpecified() {
        let input = "if case .foo(bar, let baz) = quux {}"
        let output = "if case .foo(bar, let baz) = quux {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoHoistIfLastArgSpecified() {
        let input = "if case .foo(let bar, baz) = quux {}"
        let output = "if case .foo(let bar, baz) = quux {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testHoistIfArgIsNumericLiteral() {
        let input = "if case .foo(5, let baz) = quux {}"
        let output = "if case let .foo(5, baz) = quux {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testHoistIfArgIsEnumCaseLiteral() {
        let input = "if case .foo(.bar, let baz) = quux {}"
        let output = "if case let .foo(.bar, baz) = quux {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testHoistIfArgIsNamespacedEnumCaseLiteralInParens() {
        let input = "switch foo {\ncase (Foo.bar(let baz)):\n}"
        let output = "switch foo {\ncase let (Foo.bar(baz)):\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["redundantParens"])), output + "\n")
    }

    func testHoistIfArgIsUnderscore() {
        let input = "if case .foo(_, let baz) = quux {}"
        let output = "if case let .foo(_, baz) = quux {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNestedHoistLet() {
        let input = "if case (.foo(let a, let b), .bar(let c, let d)) = quux {}"
        let output = "if case let (.foo(a, b), .bar(c, d)) = quux {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoNestedHoistLetWithSpecifiedArgs() {
        let input = "if case (.foo(let a, b), .bar(let c, d)) = quux {}"
        let output = "if case (.foo(let a, b), .bar(let c, d)) = quux {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoHoistClosureVariables() {
        let input = "foo({ let bar = 5 })"
        let output = "foo({ let bar = 5 })"
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["trailingClosures"])), output + "\n")
    }

    // TODO: this could actually hoist out the let to the next level, but that's tricky
    // to implement without breaking the `testNoOverHoistSwitchCaseWithNestedParens` case
    func testHoistSwitchCaseWithNestedParens() {
        let input = "import Foo\nswitch (foo, bar) {\ncase (.baz(let quux), Foo.bar): break\n}"
        let output = "import Foo\nswitch (foo, bar) {\ncase (let .baz(quux), Foo.bar): break\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoOverHoistSwitchCaseWithNestedParens() {
        let input = "import Foo\nswitch (foo, bar) {\ncase (.baz(let quux), bar): break\n}"
        let output = "import Foo\nswitch (foo, bar) {\ncase (let .baz(quux), bar): break\n}"
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoHoistLetWithEmptArg() {
        let input = "if .foo(let _) = bar {}"
        let output = "if .foo(let _) = bar {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet]), output)
        let rules = FormatRules.all(except: ["redundantLet", "redundantPattern"])
        XCTAssertEqual(try format(input + "\n", rules: rules), output + "\n")
    }

    func testHoistLetWithNoSpaceAfterCase() {
        let input = "switch x { case.some(let y): return y }"
        let output = "switch x { case let .some(y): return y }"
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // hoist = false

    func testUnhoistCaseLet() {
        let input = "if case let .foo(bar, baz) = quux {}"
        let output = "if case .foo(let bar, let baz) = quux {}"
        let options = FormatOptions(hoistPatternLet: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testUnhoistCaseVar() {
        let input = "if case var .foo(bar, baz) = quux {}"
        let output = "if case .foo(var bar, var baz) = quux {}"
        let options = FormatOptions(hoistPatternLet: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testUnhoistSingleCaseLet() {
        let input = "if case let .foo(bar) = quux {}"
        let output = "if case .foo(let bar) = quux {}"
        let options = FormatOptions(hoistPatternLet: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testUnhoistIfArgIsEnumCaseLiteral() {
        let input = "if case let .foo(.bar, baz) = quux {}"
        let output = "if case .foo(.bar, let baz) = quux {}"
        let options = FormatOptions(hoistPatternLet: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testUnhoistIfArgIsEnumCaseLiteralInParens() {
        let input = "switch foo {\ncase let (.bar(baz)):\n}"
        let output = "switch foo {\ncase (.bar(let baz)):\n}"
        let options = FormatOptions(hoistPatternLet: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["redundantParens"]), options: options), output + "\n")
    }

    func testUnhoistIfArgIsNamespacedEnumCaseLiteral() {
        let input = "switch foo {\ncase let Foo.bar(baz):\n}"
        let output = "switch foo {\ncase Foo.bar(let baz):\n}"
        let options = FormatOptions(hoistPatternLet: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testUnhoistIfArgIsNamespacedEnumCaseLiteralInParens() {
        let input = "switch foo {\ncase let (Foo.bar(baz)):\n}"
        let output = "switch foo {\ncase (Foo.bar(let baz)):\n}"
        let options = FormatOptions(hoistPatternLet: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["redundantParens"]), options: options), output + "\n")
    }

    func testUnhoistIfArgIsUnderscore() {
        let input = "if case let .foo(_, baz) = quux {}"
        let output = "if case .foo(_, let baz) = quux {}"
        let options = FormatOptions(hoistPatternLet: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoUnhoistTupleLet() {
        let input = "let (bar, baz) = quux()"
        let output = "let (bar, baz) = quux()"
        let options = FormatOptions(hoistPatternLet: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoUnhoistIfLetTuple() {
        let input = "if let x = y, let (_, a) = z {}"
        let output = "if let x = y, let (_, a) = z {}"
        let options = FormatOptions(hoistPatternLet: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoUnhoistIfArgIsNamespacedEnumCaseLiteralInParens() {
        let input = "switch foo {\ncase (Foo.bar(let baz)):\n}"
        let output = "switch foo {\ncase (Foo.bar(let baz)):\n}"
        let options = FormatOptions(hoistPatternLet: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.hoistPatternLet], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["redundantParens"]), options: options), output + "\n")
    }

    // MARK: wrapArguments

    // afterFirst

    func testBeforeFirstConvertedToAfterFirst() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let output = "func foo(bar _: Int,\n         baz _: String) {}"
        let options = FormatOptions(wrapArguments: .afterFirst)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoWrapInnerArguments() {
        let input = "func foo(\n    bar _: Int,\n    baz _: foo(bar, baz)\n) {}"
        let output = "func foo(bar _: Int,\n         baz _: foo(bar, baz)) {}"
        let options = FormatOptions(wrapArguments: .afterFirst)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testCorrectWrapIndentForNestedArguments() {
        let input = "foo(\nbar: (\nx: 0,\ny: 0\n),\nbaz: (\nx: 0,\ny: 0\n)\n)"
        let output = "foo(bar: (x: 0,\n          y: 0),\n    baz: (x: 0,\n          y: 0))"
        let options = FormatOptions(wrapArguments: .afterFirst)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoRemoveLinebreakAfterCommentInArguments() {
        let input = "a(b // comment\n)"
        let output = input
        let options = FormatOptions(wrapArguments: .afterFirst)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoRemoveLinebreakAfterCommentInArguments2() {
        let input = """
        foo(bar: bar
        //  ,
        //  baz: baz
            ) {}
        """
        let output = input
        let options = FormatOptions(wrapArguments: .afterFirst)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["indent"]), options: options), output + "\n")
    }

    // preserve

    func testAfterFirstPreserved() {
        let input = "func foo(bar _: Int,\n         baz _: String) {}"
        let output = input
        let options = FormatOptions(wrapArguments: .preserve)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testAfterFirstPreservedIndentFixed() {
        let input = "func foo(bar _: Int,\n baz _: String) {}"
        let output = "func foo(bar _: Int,\n         baz _: String) {}"
        let options = FormatOptions(wrapArguments: .preserve)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testAfterFirstPreservedNewlineRemoved() {
        let input = "func foo(bar _: Int,\n         baz _: String\n) {}"
        let output = "func foo(bar _: Int,\n         baz _: String) {}"
        let options = FormatOptions(wrapArguments: .preserve)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testBeforeFirstPreserved() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let output = input
        let options = FormatOptions(wrapArguments: .preserve)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testBeforeFirstPreservedIndentFixed() {
        let input = "func foo(\n    bar _: Int,\n baz _: String\n) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapArguments: .preserve)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testBeforeFirstPreservedNewlineAdded() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapArguments: .preserve)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoBeforeFirstPreservedAndTrailingCommaIgnoredInMultilineNestedDictionary() {
        let input = "[foo: [bar: baz,\n    bar2: baz2]]"
        let output = "[foo: [bar: baz,\n       bar2: baz2]]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .preserve)
        let rules = [FormatRules.wrapArguments, FormatRules.trailingCommas]
        XCTAssertEqual(try format(input, rules: rules, options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testBeforeFirstPreservedAndTrailingCommaAddedInSingleLineNestedDictionary() {
        let input = "[\n    foo: [bar: baz, bar2: baz2]]"
        let output = "[\n    foo: [bar: baz, bar2: baz2],\n]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .preserve)
        let rules = [FormatRules.wrapArguments, FormatRules.trailingCommas]
        XCTAssertEqual(try format(input, rules: rules, options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // beforeFirst

    func testWrapAfterFirstConvertedToWrapBefore() {
        let input = "func foo(bar _: Int,\n    baz _: String) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapArguments: .beforeFirst)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testLinebreakInsertedAtEndOfWrappedFunction() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapArguments: .beforeFirst)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testAfterFirstConvertedToBeforeFirst() {
        let input = "func foo(bar _: Int,\n         baz _: String) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let options = FormatOptions(wrapArguments: .beforeFirst)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testClosureInsideParensNotWrappedOntoNextLine() {
        let input = "foo({\n    bar()\n})"
        let output = "foo({\n    bar()\n})"
        let options = FormatOptions(wrapArguments: .beforeFirst)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["trailingClosures"]), options: options), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoMistakeTernaryExpressionForArguments() {
        let input = """
        (foo ?
            bar :
            baz)
        """
        let output = input
        let options = FormatOptions(wrapArguments: .beforeFirst)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["redundantParens"]), options: options), output + "\n")
    }

    // closingParenOnSameLine = true

    func testParenOnSameLineWhenWrapAfterFirstConvertedToWrapBefore() {
        let input = "func foo(bar _: Int,\n    baz _: String) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String) {}"
        let options = FormatOptions(wrapArguments: .beforeFirst, closingParenOnSameLine: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testParenOnSameLineWhenWrapBeforeFirstUnchanged() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String) {}"
        let options = FormatOptions(wrapArguments: .beforeFirst, closingParenOnSameLine: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testParenOnSameLineWhenWrapBeforeFirstPreserved() {
        let input = "func foo(\n    bar _: Int,\n    baz _: String\n) {}"
        let output = "func foo(\n    bar _: Int,\n    baz _: String) {}"
        let options = FormatOptions(wrapArguments: .preserve, closingParenOnSameLine: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // MARK: wrapCollections

    func testNoDoubleSpaceAddedToWrappedArray() {
        let input = "[ foo,\n    bar ]"
        let output = "[\n    foo,\n    bar\n]"
        let options = FormatOptions(trailingCommas: false, wrapCollections: .beforeFirst)
        let rules = [FormatRules.wrapArguments, FormatRules.spaceInsideBrackets]
        XCTAssertEqual(try format(input, rules: rules, options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testTrailingCommasAddedToWrappedArray() {
        let input = "[foo,\n    bar]"
        let output = "[\n    foo,\n    bar,\n]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .beforeFirst)
        let rules = [FormatRules.wrapArguments, FormatRules.trailingCommas]
        XCTAssertEqual(try format(input, rules: rules, options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testTrailingCommasAddedToWrappedNestedDictionary() {
        let input = "[foo: [bar: baz,\n    bar2: baz2]]"
        let output = "[\n    foo: [\n        bar: baz,\n        bar2: baz2,\n    ],\n]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .beforeFirst)
        let rules = [FormatRules.wrapArguments, FormatRules.trailingCommas]
        XCTAssertEqual(try format(input, rules: rules, options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testTrailingCommasAddedToSingleLineNestedDictionary() {
        let input = "[\n    foo: [bar: baz, bar2: baz2]]"
        let output = "[\n    foo: [bar: baz, bar2: baz2],\n]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .beforeFirst)
        let rules = [FormatRules.wrapArguments, FormatRules.trailingCommas]
        XCTAssertEqual(try format(input, rules: rules, options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testTrailingCommasAddedToWrappedNestedDictionaries() {
        let input = "[foo: [bar: baz,\n    bar2: baz2],\n    foo2: [bar: baz,\n    bar2: baz2]]"
        let output = "[\n    foo: [\n        bar: baz,\n        bar2: baz2,\n    ],\n    foo2: [\n        bar: baz,\n        bar2: baz2,\n    ],\n]"
        let options = FormatOptions(trailingCommas: true, wrapCollections: .beforeFirst)
        let rules = [FormatRules.wrapArguments, FormatRules.trailingCommas]
        XCTAssertEqual(try format(input, rules: rules, options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testSpaceAroundEnumValuesInArray() {
        let input = "[\n    .foo,\n    .bar, .baz,\n]"
        let output = "[\n    .foo,\n    .bar, .baz,\n]"
        let options = FormatOptions(wrapCollections: .beforeFirst)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testTrailingCommaRemovedInWrappedArray() {
        let input = "[\n    .foo,\n    .bar,\n    .baz,\n]"
        let output = "[.foo,\n .bar,\n .baz]"
        let options = FormatOptions(wrapCollections: .afterFirst)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoRemoveLinebreakAfterCommentInElements() {
        let input = "[a, // comment\n]"
        let output = input
        let options = FormatOptions(wrapCollections: .afterFirst)
        XCTAssertEqual(try format(input, rules: [FormatRules.wrapArguments], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // MARK: numberFormatting

    // hex case

    func testLowercaseLiteralConvertedToUpper() {
        let input = "let foo = 0xabcd"
        let output = "let foo = 0xABCD"
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testMixedCaseLiteralConvertedToUpper() {
        let input = "let foo = 0xaBcD"
        let output = "let foo = 0xABCD"
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testUppercaseLiteralConvertedToLower() {
        let input = "let foo = 0xABCD"
        let output = "let foo = 0xabcd"
        let options = FormatOptions(uppercaseHex: false)
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testPInExponentialNotConvertedToUpper() {
        let input = "let foo = 0xaBcDp5"
        let output = "let foo = 0xABCDp5"
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testPInExponentialNotConvertedToLower() {
        let input = "let foo = 0xaBcDP5"
        let output = "let foo = 0xabcdP5"
        let options = FormatOptions(uppercaseHex: false, uppercaseExponent: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // exponent case

    func testLowercaseExponent() {
        let input = "let foo = 0.456E-5"
        let output = "let foo = 0.456e-5"
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testUppercaseExponent() {
        let input = "let foo = 0.456e-5"
        let output = "let foo = 0.456E-5"
        let options = FormatOptions(uppercaseExponent: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testUppercaseHexExponent() {
        let input = "let foo = 0xFF00p54"
        let output = "let foo = 0xFF00P54"
        let options = FormatOptions(uppercaseExponent: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testUppercaseGroupedHexExponent() {
        let input = "let foo = 0xFF00_AABB_CCDDp54"
        let output = "let foo = 0xFF00_AABB_CCDDP54"
        let options = FormatOptions(uppercaseExponent: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // decimal grouping

    func testDefaultDecimalGrouping() {
        let input = "let foo = 1234_56_78"
        let output = "let foo = 12_345_678"
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIgnoreDecimalGrouping() {
        let input = "let foo = 1234_5_678"
        let output = "let foo = 1234_5_678"
        let options = FormatOptions(decimalGrouping: .ignore)
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoDecimalGrouping() {
        let input = "let foo = 1234_5_678"
        let output = "let foo = 12345678"
        let options = FormatOptions(decimalGrouping: .none)
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testDecimalGroupingThousands() {
        let input = "let foo = 1234"
        let output = "let foo = 1_234"
        let options = FormatOptions(decimalGrouping: .group(3, 3))
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testExponentialGrouping() {
        let input = "let foo = 1234e5678"
        let output = "let foo = 1_234e5678"
        let options = FormatOptions(decimalGrouping: .group(3, 3))
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testZeroGrouping() {
        let input = "let foo = 1234"
        let output = "let foo = 1234"
        let options = FormatOptions(decimalGrouping: .group(0, 0))
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // binary grouping

    func testDefaultBinaryGrouping() {
        let input = "let foo = 0b11101000_00111111"
        let output = "let foo = 0b1110_1000_0011_1111"
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIgnoreBinaryGrouping() {
        let input = "let foo = 0b1110_10_00"
        let output = "let foo = 0b1110_10_00"
        let options = FormatOptions(binaryGrouping: .ignore)
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoBinaryGrouping() {
        let input = "let foo = 0b1110_10_00"
        let output = "let foo = 0b11101000"
        let options = FormatOptions(binaryGrouping: .none)
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testBinaryGroupingCustom() {
        let input = "let foo = 0b110011"
        let output = "let foo = 0b11_00_11"
        let options = FormatOptions(binaryGrouping: .group(2, 2))
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // hex grouping

    func testDefaultHexGrouping() {
        let input = "let foo = 0xFF01FF01AE45"
        let output = "let foo = 0xFF01_FF01_AE45"
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCustomHexGrouping() {
        let input = "let foo = 0xFF00p54"
        let output = "let foo = 0xFF_00p54"
        let options = FormatOptions(hexGrouping: .group(2, 2))
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // octal grouping

    func testDefaultOctalGrouping() {
        let input = "let foo = 0o123456701234"
        let output = "let foo = 0o1234_5670_1234"
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCustomOctalGrouping() {
        let input = "let foo = 0o12345670"
        let output = "let foo = 0o12_34_56_70"
        let options = FormatOptions(octalGrouping: .group(2, 2))
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // fraction grouping

    func testIgnoreFractionGrouping() {
        let input = "let foo = 1.234_5_678"
        let output = "let foo = 1.234_5_678"
        let options = FormatOptions(decimalGrouping: .ignore, fractionGrouping: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoFractionGrouping() {
        let input = "let foo = 1.234_5_678"
        let output = "let foo = 1.2345678"
        let options = FormatOptions(decimalGrouping: .none, fractionGrouping: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testFractionGroupingThousands() {
        let input = "let foo = 12.34_56_78"
        let output = "let foo = 12.345_678"
        let options = FormatOptions(decimalGrouping: .group(3, 3), fractionGrouping: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testHexFractionGrouping() {
        let input = "let foo = 0x12.34_56_78p56"
        let output = "let foo = 0x12.34_5678p56"
        let options = FormatOptions(hexGrouping: .group(4, 4), fractionGrouping: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.numberFormatting], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // MARK: fileHeader

    func testStripHeader() {
        let input = "//\n//  test.swift\n//  SwiftFormat\n//\n//  Created by Nick Lockwood on 08/11/2016.\n//  Copyright © 2016 Nick Lockwood. All rights reserved.\n//\n\n// func\nfunc foo() {}"
        let output = "// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "")
        XCTAssertEqual(try format(input, rules: [FormatRules.fileHeader], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testMultilineCommentHeader() {
        let input = "/****************************/\n/* Created by Nick Lockwood */\n/****************************/\n\n\n// func\nfunc foo() {}"
        let output = "// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "")
        XCTAssertEqual(try format(input, rules: [FormatRules.fileHeader], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoStripHeaderWhenDisabled() {
        let input = "//\n//  test.swift\n//  SwiftFormat\n//\n//  Created by Nick Lockwood on 08/11/2016.\n//  Copyright © 2016 Nick Lockwood. All rights reserved.\n//\n\n// func\nfunc foo() {}"
        let output = input
        let options = FormatOptions(fileHeader: .ignore)
        XCTAssertEqual(try format(input, rules: [FormatRules.fileHeader], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoStripComment() {
        let input = "\n// func\nfunc foo() {}"
        let output = "\n// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "")
        XCTAssertEqual(try format(input, rules: [FormatRules.fileHeader], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testSetSingleLineHeader() {
        let input = "//\n//  test.swift\n//  SwiftFormat\n//\n//  Created by Nick Lockwood on 08/11/2016.\n//  Copyright © 2016 Nick Lockwood. All rights reserved.\n//\n\n// func\nfunc foo() {}"
        let output = "// Hello World\n\n// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "// Hello World")
        XCTAssertEqual(try format(input, rules: [FormatRules.fileHeader], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testSetMultilineHeader() {
        let input = "//\n//  test.swift\n//  SwiftFormat\n//\n//  Created by Nick Lockwood on 08/11/2016.\n//  Copyright © 2016 Nick Lockwood. All rights reserved.\n//\n\n// func\nfunc foo() {}"
        let output = "// Hello\n// World\n\n// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "// Hello\n// World")
        XCTAssertEqual(try format(input, rules: [FormatRules.fileHeader], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testSetMultilineHeaderWithMarkup() {
        let input = "//\n//  test.swift\n//  SwiftFormat\n//\n//  Created by Nick Lockwood on 08/11/2016.\n//  Copyright © 2016 Nick Lockwood. All rights reserved.\n//\n\n// func\nfunc foo() {}"
        let output = "/*--- Hello ---*/\n/*--- World ---*/\n\n// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "/*--- Hello ---*/\n/*--- World ---*/")
        XCTAssertEqual(try format(input, rules: [FormatRules.fileHeader], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoStripHeaderIfRuleDisabled() {
        let input = "// swiftformat:disable fileHeader\n// test\n// swiftformat:enable fileHeader\n\nfunc foo() {}"
        let output = "// swiftformat:disable fileHeader\n// test\n// swiftformat:enable fileHeader\n\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "")
        XCTAssertEqual(try format(input, rules: [FormatRules.byName["fileHeader"]!], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoStripHeaderIfNextRuleDisabled() {
        let input = "// swiftformat:disable:next fileHeader\n// test\n\nfunc foo() {}"
        let output = "// swiftformat:disable:next fileHeader\n// test\n\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "")
        XCTAssertEqual(try format(input, rules: [FormatRules.byName["fileHeader"]!], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoStripHeaderDocWithNewlineBeforeCode() {
        let input = "/// Header doc\n\nclass Foo {}"
        let output = "/// Header doc\n\nclass Foo {}"
        let options = FormatOptions(fileHeader: "")
        XCTAssertEqual(try format(input, rules: [FormatRules.fileHeader], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testNoDuplicateHeaderIfMissingTrailingBlankLine() {
        let input = "// Header comment\nclass Foo {}"
        let output = "// Header comment\n\nclass Foo {}"
        let options = FormatOptions(fileHeader: "Header comment")
        XCTAssertEqual(try format(input, rules: [FormatRules.fileHeader], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testFileHeaderYearReplacement() {
        let input = "let foo = bar"
        let output: String = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return "// Copyright © \(formatter.string(from: Date()))\n\nlet foo = bar"
        }()
        let options = FormatOptions(fileHeader: "// Copyright © {year}")
        XCTAssertEqual(try format(input, rules: [FormatRules.fileHeader], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.fileHeader], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.fileHeader], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testFileHeaderFileReplacement() {
        let input = "let foo = bar"
        let output = "// MyFile.swift\n\nlet foo = bar"
        let fileInfo = FileInfo(fileName: "MyFile.swift")
        let options = FormatOptions(fileHeader: "// {file}", fileInfo: fileInfo)
        XCTAssertEqual(try format(input, rules: [FormatRules.fileHeader], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // MARK: redundantInit

    func testRemoveRedundantInit() {
        let input = "[1].flatMap { String.init($0) }"
        let output = "[1].flatMap { String($0) }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantInit]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveRedundantInit2() {
        let input = "[String.self].map { Type in Type.init(foo: 1) }"
        let output = "[String.self].map { Type in Type(foo: 1) }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantInit]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveRedundantInit3() {
        let input = "String.init(\"text\")"
        let output = "String(\"text\")"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantInit]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testDontRemoveInitInSuperCall() {
        let input = "class C: NSObject { override init() { super.init() } }"
        let output = "class C: NSObject { override init() { super.init() } }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantInit]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testDontRemoveInitInSelfCall() {
        let input = "struct S { let n: Int }; extension S { init() { self.init(n: 1) } }"
        let output = "struct S { let n: Int }; extension S { init() { self.init(n: 1) } }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantInit]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testDontRemoveInitWhenPassedAsFunction() {
        let input = "[1].flatMap(String.init)"
        let output = "[1].flatMap(String.init)"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantInit]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testDontRemoveInitWhenUsedOnMetatype() {
        let input = "[String.self].map { type in type.init(1) }"
        let output = "[String.self].map { type in type.init(1) }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantInit]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testDontRemoveInitWhenUsedOnImplicitClosureMetatype() {
        let input = "[String.self].map { $0.init(1) }"
        let output = "[String.self].map { $0.init(1) }"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantInit]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testDontRemoveInitWithExplicitSignature() {
        let input = "[String.self].map(Foo.init(bar:))"
        let output = "[String.self].map(Foo.init(bar:))"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantInit]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: sortedImports

    func testSortedImportsSimpleCase() {
        let input = "import Foo\nimport Bar"
        let output = "import Bar\nimport Foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.sortedImports]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSortedImportsKeepsPreviousCommentWithImport() {
        let input = "import Foo\n// important comment\n// (very important)\nimport Bar"
        let output = "// important comment\n// (very important)\nimport Bar\nimport Foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.sortedImports]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSortedImportsKeepsPreviousCommentWithImport2() {
        let input = "// important comment\n// (very important)\nimport Foo\nimport Bar"
        let output = "import Bar\n// important comment\n// (very important)\nimport Foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.sortedImports]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSortedImportsDoesntMoveHeaderComment() {
        let input = "// header comment\n\nimport Foo\nimport Bar"
        let output = "// header comment\n\nimport Bar\nimport Foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.sortedImports]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSortedImportsDoesntMoveHeaderCommentFollowedByImportComment() {
        let input = "// header comment\n\n// important comment\nimport Foo\nimport Bar"
        let output = "// header comment\n\nimport Bar\n// important comment\nimport Foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.sortedImports]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSortedImportsOnSameLine() {
        let input = "import Foo; import Bar\nimport Baz"
        let output = "import Baz\nimport Foo; import Bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.sortedImports]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSortedImportsWithSemicolonAndCommentOnSameLine() {
        let input = "import Foo; // foobar\nimport Bar\nimport Baz"
        let output = "import Bar\nimport Baz\nimport Foo; // foobar"
        XCTAssertEqual(try format(input, rules: [FormatRules.sortedImports]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["semicolons"])), output + "\n")
    }

    func testSortedImportEnum() {
        let input = "import enum Foo.baz\nimport Foo.bar"
        let output = "import Foo.bar\nimport enum Foo.baz"
        XCTAssertEqual(try format(input, rules: [FormatRules.sortedImports]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSortedImportFunc() {
        let input = "import func Foo.baz\nimport Foo.bar"
        let output = "import Foo.bar\nimport func Foo.baz"
        XCTAssertEqual(try format(input, rules: [FormatRules.sortedImports]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testAlreadySortedImportsDoesNothing() {
        let input = "import Bar\nimport Foo"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.sortedImports]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testPreprocessorSortedImports() {
        let input = "#if os(iOS)\n    import Foo2\n    import Bar2\n#else\n    import Foo1\n    import Bar1\n#endif\nimport Foo3\nimport Bar3"
        let output = "#if os(iOS)\n    import Bar2\n    import Foo2\n#else\n    import Bar1\n    import Foo1\n#endif\nimport Bar3\nimport Foo3"
        XCTAssertEqual(try format(input, rules: [FormatRules.sortedImports]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testTestableSortedImports() {
        let input = "@testable import Foo3\nimport Bar3"
        let output = "import Bar3\n@testable import Foo3"
        XCTAssertEqual(try format(input, rules: [FormatRules.sortedImports]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testTestableImportsWithTestableOnPreviousLine() {
        let input = "@testable\nimport Foo3\nimport Bar3"
        let output = "import Bar3\n@testable\nimport Foo3"
        XCTAssertEqual(try format(input, rules: [FormatRules.sortedImports]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testTestableImportsWithGroupingTestableBottom() {
        let input = "@testable import Bar\nimport Foo\n@testable import UIKit"
        let output = "import Foo\n@testable import Bar\n@testable import UIKit"
        let options = FormatOptions(importGrouping: .testableBottom)
        XCTAssertEqual(try format(input, rules: [FormatRules.sortedImports], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testTestableImportsWithGroupingTestableTop() {
        let input = "@testable import Bar\nimport Foo\n@testable import UIKit"
        let output = "@testable import Bar\n@testable import UIKit\nimport Foo"
        let options = FormatOptions(importGrouping: .testableTop)
        XCTAssertEqual(try format(input, rules: [FormatRules.sortedImports], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testCaseInsensitiveSortedImports() {
        let input = "import Zlib\nimport lib"
        let output = "import lib\nimport Zlib"
        XCTAssertEqual(try format(input, rules: [FormatRules.sortedImports]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCaseInsensitiveCaseDifferingSortedImports() {
        let input = "import c\nimport B\nimport A.a\nimport A.A"
        let output = "import A.A\nimport A.a\nimport B\nimport c"
        XCTAssertEqual(try format(input, rules: [FormatRules.sortedImports]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoDeleteCodeBetweenImports() {
        let input = "import Foo\nfunc bar() {}\nimport Bar"
        let output = "import Foo\nfunc bar() {}\nimport Bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.sortedImports]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoDeleteCodeBetweenImports2() {
        let input = "import Foo\nimport Bar\nfoo = bar\nimport Bar"
        let output = "import Bar\nimport Foo\nfoo = bar\nimport Bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.sortedImports]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.sortedImports]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSortContiguousImports() {
        let input = "import Foo\nimport Bar\nfunc bar() {}\nimport Quux\nimport Baz"
        let output = "import Bar\nimport Foo\nfunc bar() {}\nimport Baz\nimport Quux"
        XCTAssertEqual(try format(input, rules: [FormatRules.sortedImports]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: duplicateImports

    func testRemoveDuplicateImport() {
        let input = "import Foundation\nimport Foundation"
        let output = "import Foundation"
        XCTAssertEqual(try format(input, rules: [FormatRules.duplicateImports]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveDuplicateConditionalImport() {
        let input = "#if os(iOS)\n    import Foo\n    import Foo\n#else\n    import Bar\n    import Bar\n#endif"
        let output = "#if os(iOS)\n    import Foo\n#else\n    import Bar\n#endif"
        XCTAssertEqual(try format(input, rules: [FormatRules.duplicateImports]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveOverlappingImports() {
        let input = "import MyModule\nimport MyModule.Private"
        let output = "import MyModule\nimport MyModule.Private"
        XCTAssertEqual(try format(input, rules: [FormatRules.duplicateImports]), output)
    }

    func testNoRemoveCaseDifferingImports() {
        let input = "import Auth0.Authentication\nimport Auth0.authentication"
        let output = "import Auth0.Authentication\nimport Auth0.authentication"
        XCTAssertEqual(try format(input, rules: [FormatRules.duplicateImports]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveDuplicateImportFunc() {
        let input = "import func Foo.bar\nimport func Foo.bar"
        let output = "import func Foo.bar"
        XCTAssertEqual(try format(input, rules: [FormatRules.duplicateImports]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: strongOutlets

    func testRemoveWeakFromOutlet() {
        let input = "@IBOutlet weak var label: UILabel!"
        let output = "@IBOutlet var label: UILabel!"
        XCTAssertEqual(try format(input, rules: [FormatRules.strongOutlets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveWeakFromPrivateOutlet() {
        let input = "@IBOutlet private weak var label: UILabel!"
        let output = "@IBOutlet private var label: UILabel!"
        XCTAssertEqual(try format(input, rules: [FormatRules.strongOutlets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveWeakFromOutletOnSplitLine() {
        let input = "@IBOutlet\nweak var label: UILabel!"
        let output = "@IBOutlet\nvar label: UILabel!"
        XCTAssertEqual(try format(input, rules: [FormatRules.strongOutlets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveWeakFromNonOutlet() {
        let input = "weak var label: UILabel!"
        let output = "weak var label: UILabel!"
        XCTAssertEqual(try format(input, rules: [FormatRules.strongOutlets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveWeakFromNonOutletAfterOutlet() {
        let input = "@IBOutlet weak var label1: UILabel!\nweak var label2: UILabel!"
        let output = "@IBOutlet var label1: UILabel!\nweak var label2: UILabel!"
        XCTAssertEqual(try format(input, rules: [FormatRules.strongOutlets]), output)
    }

    func testNoRemoveWeakFromDelegateOutlet() {
        let input = "@IBOutlet weak var delegate: UITableViewDelegate?"
        let output = "@IBOutlet weak var delegate: UITableViewDelegate?"
        XCTAssertEqual(try format(input, rules: [FormatRules.strongOutlets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoRemoveWeakFromDataSourceOutlet() {
        let input = "@IBOutlet weak var dataSource: UITableViewDataSource?"
        let output = "@IBOutlet weak var dataSource: UITableViewDataSource?"
        XCTAssertEqual(try format(input, rules: [FormatRules.strongOutlets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveWeakFromOutletAfterDelegateOutlet() {
        let input = "@IBOutlet weak var delegate: UITableViewDelegate?\n@IBOutlet weak var label1: UILabel!"
        let output = "@IBOutlet weak var delegate: UITableViewDelegate?\n@IBOutlet var label1: UILabel!"
        XCTAssertEqual(try format(input, rules: [FormatRules.strongOutlets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRemoveWeakFromOutletAfterDataSourceOutlet() {
        let input = "@IBOutlet weak var dataSource: UITableViewDataSource?\n@IBOutlet weak var label1: UILabel!"
        let output = "@IBOutlet weak var dataSource: UITableViewDataSource?\n@IBOutlet var label1: UILabel!"
        XCTAssertEqual(try format(input, rules: [FormatRules.strongOutlets]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: emptyBraces

    func testLinebreaksRemovedInsideBraces() {
        let input = "func foo() {\n  \n }"
        let output = "func foo() {}"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.emptyBraces], options: options), output)
        XCTAssertEqual(try format(input, rules: FormatRules.all, options: options), output)
    }

    func testCommentNotRemovedInsideBraces() {
        let input = "func foo() { // foo\n}"
        let output = "func foo() { // foo\n}"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.emptyBraces], options: options), output)
        XCTAssertEqual(try format(input, rules: FormatRules.all, options: options), output)
    }

    func testEmptyBracesNotRemovedInDoCatch() {
        let input = """
        do {
        } catch is FooError {
        } catch {}
        """
        let output = input
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.emptyBraces], options: options), output)
        XCTAssertEqual(try format(input, rules: FormatRules.all, options: options), output)
    }

    func testEmptyBracesNotRemovedInIfElse() {
        let input = """
        if {
        } else if foo {
        } else {}
        """
        let output = input
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.emptyBraces], options: options), output)
        XCTAssertEqual(try format(input, rules: FormatRules.all, options: options), output)
    }

    // MARK: andOperator

    func testIfAndReplaced() {
        let input = "if true && true {}"
        let output = "if true, true {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.andOperator]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testGuardAndReplaced() {
        let input = "guard true && true\nelse { return }"
        let output = "guard true, true\nelse { return }"
        XCTAssertEqual(try format(input, rules: [FormatRules.andOperator]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testWhileAndReplaced() {
        let input = "while true && true {}"
        let output = "while true, true {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.andOperator]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIfDoubleAndReplaced() {
        let input = "if true && true && true {}"
        let output = "if true, true, true {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.andOperator]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIfAndParensReplaced() {
        let input = "if true && (true && true) {}"
        let output = "if true, (true && true) {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.andOperator]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["redundantParens"])), output + "\n")
    }

    func testIfFunctionAndReplaced() {
        let input = "if functionReturnsBool() && true {}"
        let output = "if functionReturnsBool(), true {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.andOperator]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoReplaceIfOrAnd() {
        let input = "if foo || bar && baz {}"
        let output = "if foo || bar && baz {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.andOperator]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoReplaceIfAndOr() {
        let input = "if foo && bar || baz {}"
        let output = "if foo && bar || baz {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.andOperator]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testIfAndReplacedInFunction() {
        let input = "func someFunc() { if bar && baz {} }"
        let output = "func someFunc() { if bar, baz {} }"
        XCTAssertEqual(try format(input, rules: [FormatRules.andOperator]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoReplaceIfCaseLetAnd() {
        let input = "if case let a = foo && bar {}"
        let output = "if case let a = foo && bar {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.andOperator]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoReplaceWhileCaseLetAnd() {
        let input = "while case let a = foo && bar {}"
        let output = "while case let a = foo && bar {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.andOperator]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoReplaceRepeatWhileAnd() {
        let input = """
        repeat {} while true && !false
        foo {}
        """
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.andOperator]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoReplaceIfLetAndLetAnd() {
        let input = "if let a = b && c, let d = e && f {}"
        let output = "if let a = b && c, let d = e && f {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.andOperator]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoReplaceIfTryAnd() {
        let input = "if try true && explode() {}"
        let output = "if try true && explode() {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.andOperator]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testHandleAndAtStartOfLine() {
        let input = "if a == b\n    && b == c {}"
        let output = "if a == b,\n    b == c {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.andOperator]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testHandleAndAtStartOfLineAfterComment() {
        let input = "if a == b // foo\n    && b == c {}"
        let output = "if a == b, // foo\n    b == c {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.andOperator]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: isEmpty

    // count == 0

    func testCountEqualsZero() {
        let input = "if foo.count == 0 {}"
        let output = "if foo.isEmpty {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.isEmpty]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testFunctionCountEqualsZero() {
        let input = "if foo().count == 0 {}"
        let output = "if foo().isEmpty {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.isEmpty]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testExpressionCountEqualsZero() {
        let input = "if foo || bar.count == 0 {}"
        let output = "if foo || bar.isEmpty {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.isEmpty]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCompoundIfCountEqualsZero() {
        let input = "if foo, bar.count == 0 {}"
        let output = "if foo, bar.isEmpty {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.isEmpty]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testOptionalCountEqualsZero() {
        let input = "if foo?.count == 0 {}"
        let output = "if foo?.isEmpty == true {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.isEmpty]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testOptionalChainCountEqualsZero() {
        let input = "if foo?.bar.count == 0 {}"
        let output = "if foo?.bar.isEmpty == true {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.isEmpty]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCompoundIfOptionalCountEqualsZero() {
        let input = "if foo, bar?.count == 0 {}"
        let output = "if foo, bar?.isEmpty == true {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.isEmpty]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testTernaryCountEqualsZero() {
        let input = "foo ? bar.count == 0 : baz.count == 0"
        let output = "foo ? bar.isEmpty : baz.isEmpty"
        XCTAssertEqual(try format(input, rules: [FormatRules.isEmpty]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // count != 0

    func testCountNotEqualToZero() {
        let input = "if foo.count != 0 {}"
        let output = "if !foo.isEmpty {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.isEmpty]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testFunctionCountNotEqualToZero() {
        let input = "if foo().count != 0 {}"
        let output = "if !foo().isEmpty {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.isEmpty]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testExpressionCountNotEqualToZero() {
        let input = "if foo || bar.count != 0 {}"
        let output = "if foo || !bar.isEmpty {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.isEmpty]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCompoundIfCountNotEqualToZero() {
        let input = "if foo, bar.count != 0 {}"
        let output = "if foo, !bar.isEmpty {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.isEmpty]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // count > 0

    func testCountGreaterThanZero() {
        let input = "if foo.count > 0 {}"
        let output = "if !foo.isEmpty {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.isEmpty]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCountExpressionGreaterThanZero() {
        let input = "if a.count - b.count > 0 {}"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.isEmpty]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // optional count

    func testOptionalCountNotEqualToZero() {
        let input = "if foo?.count != 0 {}" // nil evaluates to true
        let output = "if foo?.isEmpty != true {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.isEmpty]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testOptionalChainCountNotEqualToZero() {
        let input = "if foo?.bar.count != 0 {}" // nil evaluates to true
        let output = "if foo?.bar.isEmpty != true {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.isEmpty]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCompoundIfOptionalCountNotEqualToZero() {
        let input = "if foo, bar?.count != 0 {}"
        let output = "if foo, bar?.isEmpty != true {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.isEmpty]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // edge cases

    func testTernaryCountNotEqualToZero() {
        let input = "foo ? bar.count != 0 : baz.count != 0"
        let output = "foo ? !bar.isEmpty : !baz.isEmpty"
        XCTAssertEqual(try format(input, rules: [FormatRules.isEmpty]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCountEqualsZeroAfterOptionalOnPreviousLine() {
        let input = "_ = foo?.bar\nbar.count == 0 ? baz() : quux()"
        let output = "_ = foo?.bar\nbar.isEmpty ? baz() : quux()"
        XCTAssertEqual(try format(input, rules: [FormatRules.isEmpty]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCountEqualsZeroAfterOptionalCallOnPreviousLine() {
        let input = "foo?.bar()\nbar.count == 0 ? baz() : quux()"
        let output = "foo?.bar()\nbar.isEmpty ? baz() : quux()"
        XCTAssertEqual(try format(input, rules: [FormatRules.isEmpty]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCountEqualsZeroAfterTrailingCommentOnPreviousLine() {
        let input = "foo?.bar() // foobar\nbar.count == 0 ? baz() : quux()"
        let output = "foo?.bar() // foobar\nbar.isEmpty ? baz() : quux()"
        XCTAssertEqual(try format(input, rules: [FormatRules.isEmpty]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCountGreaterThanZeroAfterOpenParen() {
        let input = "foo(bar.count > 0)"
        let output = "foo(!bar.isEmpty)"
        XCTAssertEqual(try format(input, rules: [FormatRules.isEmpty]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCountGreaterThanZeroAfterArgumentLabel() {
        let input = "foo(bar: baz.count > 0)"
        let output = "foo(bar: !baz.isEmpty)"
        XCTAssertEqual(try format(input, rules: [FormatRules.isEmpty]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: redundantLetError

    func testCatchLetError() {
        let input = "do {} catch let error {}"
        let output = "do {} catch {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantLetError]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: anyObjectProtocol

    func testClassReplacedByAnyObject() {
        let input = "protocol Foo: class {}"
        let output = "protocol Foo: AnyObject {}"
        let options = FormatOptions(swiftVersion: "4.1")
        XCTAssertEqual(try format(input, rules: [FormatRules.anyObjectProtocol], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testClassReplacedByAnyObjectWithOtherProtocols() {
        let input = "protocol Foo: class, Codable {}"
        let output = "protocol Foo: AnyObject, Codable {}"
        let options = FormatOptions(swiftVersion: "4.1")
        XCTAssertEqual(try format(input, rules: [FormatRules.anyObjectProtocol], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testClassReplacedByAnyObjectImmediatelyAfterImport() {
        let input = "import Foundation\nprotocol Foo: class {}"
        let output = "import Foundation\nprotocol Foo: AnyObject {}"
        let options = FormatOptions(swiftVersion: "4.1")
        XCTAssertEqual(try format(input, rules: [FormatRules.anyObjectProtocol], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testClassDeclarationNotReplacedByAnyObject() {
        let input = "class Foo: Codable {}"
        let output = "class Foo: Codable {}"
        let options = FormatOptions(swiftVersion: "4.1")
        XCTAssertEqual(try format(input, rules: [FormatRules.anyObjectProtocol], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testClassImportNotReplacedByAnyObject() {
        let input = "import class Foo.Bar"
        let output = "import class Foo.Bar"
        let options = FormatOptions(swiftVersion: "4.1")
        XCTAssertEqual(try format(input, rules: [FormatRules.anyObjectProtocol], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testClassNotReplacedByAnyObjectIfSwiftVersionLessThan4_1() {
        let input = "protocol Foo: class {}"
        let output = "protocol Foo: class {}"
        let options = FormatOptions(swiftVersion: "4.0")
        XCTAssertEqual(try format(input, rules: [FormatRules.anyObjectProtocol], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // MARK: redundantBreak

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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantBreak]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantBreak]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantBreak]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: strongifiedSelf

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
        XCTAssertEqual(try format(input, rules: [FormatRules.strongifiedSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.strongifiedSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testBacktickedSelfNotConvertedIfVersionLessThan4_2() {
        let input = """
        { [weak self] in
            guard let `self` = self else { return }
        }
        """
        let output = input
        let options = FormatOptions(swiftVersion: "4.1.5")
        XCTAssertEqual(try format(input, rules: [FormatRules.strongifiedSelf], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testBacktickedSelfNotConvertedIfVersionUnspecified() {
        let input = """
        { [weak self] in
            guard let `self` = self else { return }
        }
        """
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.strongifiedSelf]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: redundantObjc

    func testRedundantObjcRemovedFromBeforeOutlet() {
        let input = "@objc @IBOutlet var label: UILabel!"
        let output = "@IBOutlet var label: UILabel!"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantObjc]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRedundantObjcRemovedFromAfterOutlet() {
        let input = "@IBOutlet @objc var label: UILabel!"
        let output = "@IBOutlet var label: UILabel!"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantObjc]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRedundantObjcRemovedFromLineBeforeOutlet() {
        let input = "@objc\n@IBOutlet var label: UILabel!"
        let output = "\n@IBOutlet var label: UILabel!"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantObjc]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRedundantObjcCommentNotRemoved() {
        let input = "@objc // an outlet\n@IBOutlet var label: UILabel!"
        let output = "// an outlet\n@IBOutlet var label: UILabel!"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantObjc]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testObjcNotRemovedFromNSCopying() {
        let input = "@objc @NSCopying var foo: String!"
        let output = "@objc @NSCopying var foo: String!"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantObjc]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testRenamedObjcNotRemoved() {
        let input = "@IBOutlet @objc(uiLabel) var label: UILabel!"
        let output = "@IBOutlet @objc(uiLabel) var label: UILabel!"
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantObjc]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantObjc]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantObjc]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testObjcNotRemovedOnNestedClass() {
        let input = """
        @objcMembers class Foo: NSObject {
            @objc class Bar: NSObject {}
        }
        """
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantObjc]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testObjcNotRemovedOnRenamedPrivateNestedClass() {
        let input = """
        @objcMembers class Foo: NSObject {
            @objc private class Bar: NSObject {}
        }
        """
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantObjc]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testObjcNotRemovedOnNestedEnum() {
        let input = """
        @objcMembers class Foo: NSObject {
            @objc enum Bar: Int {}
        }
        """
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantObjc]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantObjc]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantObjc]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testObjcNotRemovedOnPrivateFunc() {
        let input = """
        @objcMembers class Foo: NSObject {
            @objc private func bar() {}
        }
        """
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantObjc]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testObjcNotRemovedOnFileprivateFunc() {
        let input = """
        @objcMembers class Foo: NSObject {
            @objc fileprivate func bar() {}
        }
        """
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantObjc]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: typeSugar

    func testArrayTypeConvertedToSugar() {
        let input = "var foo: Array<String>"
        let output = "var foo: [String]"
        XCTAssertEqual(try format(input, rules: [FormatRules.typeSugar]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testDictionaryTypeConvertedToSugar() {
        let input = "var foo: Dictionary<String, Int>"
        let output = "var foo: [String: Int]"
        XCTAssertEqual(try format(input, rules: [FormatRules.typeSugar]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testOptionalTypeConvertedToSugar() {
        let input = "var foo: Optional<String>"
        let output = "var foo: String?"
        XCTAssertEqual(try format(input, rules: [FormatRules.typeSugar]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testOptionalClosureParenthesizedConvertedToSugar() {
        let input = "var foo: Optional<(Int) -> String>"
        let output = "var foo: ((Int) -> String)?"
        XCTAssertEqual(try format(input, rules: [FormatRules.typeSugar]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testArrayNestedTypeAliasNotConvertedToSugar() {
        let input = "typealias Indices = Array<Foo>.Indices"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.typeSugar]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testArrayTypeReferenceConvertedToSugar() {
        let input = "let type = Array<Foo>.Type"
        let output = "let type = [Foo].Type"
        XCTAssertEqual(try format(input, rules: [FormatRules.typeSugar]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testArraySelfReferenceConvertedToSugar() {
        let input = "let type = Array<Foo>.self"
        let output = "let type = [Foo].self"
        XCTAssertEqual(try format(input, rules: [FormatRules.typeSugar]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: redundantExtensionACL

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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantExtensionACL]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantExtensionACL]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: redundantFileprivate

    func testFileScopeFileprivateVarChangedToPrivate() {
        let input = """
        fileprivate var foo = "foo"
        """
        let output = """
        private var foo = "foo"
        """
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantFileprivate]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testFileScopeFileprivateVarNotChangedToPrivateIfFragment() {
        let input = """
        fileprivate var foo = "foo"
        """
        let output = input
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantFileprivate], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantFileprivate], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantFileprivate], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        let output = input
        let options = FormatOptions(swiftVersion: "4")
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantFileprivate], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        let output = input
        let options = FormatOptions(swiftVersion: "4")
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantFileprivate], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        let output = input
        let options = FormatOptions(swiftVersion: "4")
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantFileprivate], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testFileprivateVarNotChangedToPrivateIfAccessedFromAConstant() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        let kFoo = Foo().foo
        """
        let output = input
        let options = FormatOptions(swiftVersion: "4")
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantFileprivate], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testFileprivateVarNotChangedToPrivateIfAccessedFromAVar() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        var kFoo: String { return Foo().foo }
        """
        let output = input
        let options = FormatOptions(swiftVersion: "4")
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantFileprivate], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testFileprivateVarNotChangedToPrivateIfAccessedFromCode() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        print(Foo().foo)
        """
        let output = input
        let options = FormatOptions(swiftVersion: "4")
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantFileprivate], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testFileprivateVarNotChangedToPrivateIfAccessedFromAClosure() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        print({ Foo().foo }())
        """
        let output = input
        let options = FormatOptions(swiftVersion: "4")
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantFileprivate], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        let output = input
        let options = FormatOptions(swiftVersion: "4")
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantFileprivate], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantFileprivate], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantFileprivate], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["redundantSelf"]), options: options), output + "\n")
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
        let output = input
        let options = FormatOptions(swiftVersion: "4")
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantFileprivate], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantFileprivate], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testFileprivateInitNotChangedToPrivateIfConstructorCalledOutsideType() {
        let input = """
        struct Foo {
            fileprivate init() {}
        }

        let foo = Foo()
        """
        let output = input
        let options = FormatOptions(swiftVersion: "4")
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantFileprivate], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testFileprivateStructMemberNotChangedToPrivateIfConstructorCalledOutsideType() {
        let input = """
        struct Foo {
            fileprivate let bar: String
        }

        let foo = Foo(bar: "test")
        """
        let output = input
        let options = FormatOptions(swiftVersion: "4")
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantFileprivate], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantFileprivate], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    func testFileprivateExtensionFuncNotChangedToPrivateIfPartOfProtocolConformance() {
        let input = """
        private class Foo: Equatable {
            fileprivate static func == (_: Foo, _: Foo) -> Bool {
                return true
            }
        }
        """
        let output = input
        let options = FormatOptions(swiftVersion: "4")
        XCTAssertEqual(try format(input, rules: [FormatRules.redundantFileprivate], options: options), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all, options: options), output + "\n")
    }

    // MARK: yodaConditions

    func testNumericLiteralEqualYodaCondition() {
        let input = "5 == foo"
        let output = "foo == 5"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNumericLiteralGreaterYodaCondition() {
        let input = "5.1 > foo"
        let output = "foo < 5.1"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testStringLiteralNotEqualYodaCondition() {
        let input = "\"foo\" != foo"
        let output = "foo != \"foo\""
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNilNotEqualYodaCondition() {
        let input = "nil != foo"
        let output = "foo != nil"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testTrueNotEqualYodaCondition() {
        let input = "true != foo"
        let output = "foo != true"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testEnumCaseNotEqualYodaCondition() {
        let input = ".foo != foo"
        let output = "foo != .foo"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testArrayLiteralNotEqualYodaCondition() {
        let input = "[5, 6] != foo"
        let output = "foo != [5, 6]"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNestedArrayLiteralNotEqualYodaCondition() {
        let input = "[5, [6, 7]] != foo"
        let output = "foo != [5, [6, 7]]"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testDictionaryLiteralNotEqualYodaCondition() {
        let input = "[foo: 5, bar: 6] != foo"
        let output = "foo != [foo: 5, bar: 6]"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSubscriptNotTreatedAsYodaCondition() {
        let input = "foo[5] != bar"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSubscriptOfParenthesizedExpressionNotTreatedAsYodaCondition() {
        let input = "(foo + bar)[5] != baz"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSubscriptOfUnwrappedValueNotTreatedAsYodaCondition() {
        let input = "foo![5] != bar"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSubscriptOfExpressionWithInlineCommentNotTreatedAsYodaCondition() {
        let input = "foo /* foo */ [5] != bar"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSubscriptOfCollectionNotTreatedAsYodaCondition() {
        let input = "[foo][5] != bar"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSubscriptOfTrailingClosureNotTreatedAsYodaCondition() {
        let input = "foo { [5] }[0] != bar"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSubscriptOfRhsNotMangledInYodaCondition() {
        let input = "[1] == foo[0]"
        let output = "foo[0] == [1]"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testTupleYodaCondition() {
        let input = "(5, 6) != bar"
        let output = "bar != (5, 6)"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testLabeledTupleYodaCondition() {
        let input = "(foo: 5, bar: 6) != baz"
        let output = "baz != (foo: 5, bar: 6)"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNestedTupleYodaCondition() {
        let input = "(5, (6, 7)) != baz"
        let output = "baz != (5, (6, 7))"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testFunctionCallNotTreatedAsYodaCondition() {
        let input = "foo(5) != bar"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCallOfParenthesizedExpressionNotTreatedAsYodaCondition() {
        let input = "(foo + bar)(5) != baz"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCallOfUnwrappedValueNotTreatedAsYodaCondition() {
        let input = "foo!(5) != bar"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCallOfExpressionWithInlineCommentNotTreatedAsYodaCondition() {
        let input = "foo /* foo */ (5) != bar"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testCallOfRhsNotMangledInYodaCondition() {
        let input = "(1, 2) == foo(0)"
        let output = "foo(0) == (1, 2)"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testTrailingClosureOnRhsNotMangledInYodaCondition() {
        let input = "(1, 2) == foo { $0 }"
        let output = "foo { $0 } == (1, 2)"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testYodaConditionInIfStatement() {
        let input = "if 5 != foo {}"
        let output = "if foo != 5 {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testSubscriptYodaConditionInIfStatementWithBraceOnNextLine() {
        let input = "if [0] == foo.bar[0]\n{ baz() }"
        let output = "if foo.bar[0] == [0]\n{ baz() }"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testYodaConditionInSecondClauseOfIfStatement() {
        let input = "if foo, 5 != bar {}"
        let output = "if foo, bar != 5 {}"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testYodaConditionInExpression() {
        let input = "let foo = 5 < bar\nbaz()"
        let output = "let foo = bar > 5\nbaz()"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testYodaConditionInExpressionWithTrailingClosure() {
        let input = "let foo = 5 < bar { baz() }"
        let output = "let foo = bar { baz() } > 5"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testYodaConditionInFunctionCall() {
        let input = "foo(5 < bar)"
        let output = "foo(bar > 5)"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testYodaConditionFollowedByExpression() {
        let input = "5 == foo + 6"
        let output = "foo + 6 == 5"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testPrefixExpressionYodaCondition() {
        let input = "!false == foo"
        let output = "foo == !false"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testPrefixExpressionYodaCondition2() {
        let input = "true == !foo"
        let output = "!foo == true"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testPostfixExpressionYodaCondition() {
        let input = "5<*> == foo"
        let output = "foo == 5<*>"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testDoublePostfixExpressionYodaCondition() {
        let input = "5!! == foo"
        let output = "foo == 5!!"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testPostfixExpressionNonYodaCondition() {
        let input = "5 == 5<*>"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testPostfixExpressionNonYodaCondition2() {
        let input = "5<*> == 5"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testStringEqualsStringNonYodaCondition() {
        let input = "\"foo\" == \"bar\""
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testConstantAfterNullCoalescingNonYodaCondition() {
        let input = "foo.last ?? -1 < bar"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoMangleYodaConditionFollowedByAndOperator() {
        let input = "5 <= foo && foo <= 7"
        let output = "foo >= 5 && foo <= 7"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all(except: ["andOperator"])), output + "\n")
    }

    func testNoMangleYodaConditionFollowedByOrOperator() {
        let input = "5 <= foo || foo <= 7"
        let output = "foo >= 5 || foo <= 7"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoMangleYodaConditionFollowedByParentheses() {
        let input = "0 <= (foo + bar)"
        let output = "(foo + bar) >= 0"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoMangleYodaConditionInTernary() {
        let input = "let z = 0 < y ? 3 : 4"
        let output = "let z = y > 0 ? 3 : 4"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoMangleYodaConditionInTernary2() {
        let input = "let z = y > 0 ? 0 < x : 4"
        let output = "let z = y > 0 ? x > 0 : 4"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testNoMangleYodaConditionInTernary3() {
        let input = "let z = y > 0 ? 3 : 0 < x"
        let output = "let z = y > 0 ? 3 : x > 0"
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    func testKeyPathNotMangledAndNotTreatedAsYodaCondition() {
        let input = "\\.foo == bar"
        let output = input
        XCTAssertEqual(try format(input, rules: [FormatRules.yodaConditions]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }

    // MARK: leadingDelimiters

    func testLeadingCommaMovedToPreviousLine() {
        let input = """
        let foo = 5
            , bar = 6
        """
        let output = """
        let foo = 5,
            bar = 6
        """
        XCTAssertEqual(try format(input, rules: [FormatRules.leadingDelimiters]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.leadingDelimiters]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
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
        XCTAssertEqual(try format(input, rules: [FormatRules.leadingDelimiters]), output)
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.all), output + "\n")
    }
}
