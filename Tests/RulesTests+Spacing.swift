//
//  SpacingRulesTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 04/09/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class SpacingTests: RulesTests {
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

    func testAddSpaceBetweenSendableAndBlock() {
        let input = "@Sendable (Action) -> Void"
        testFormatting(for: input, rule: FormatRules.spaceAroundParens)
    }

    func testAddSpaceBetweenMainActorAndBlock() {
        let input = "@MainActor (Action) -> Void"
        testFormatting(for: input, rule: FormatRules.spaceAroundParens)
    }

    func testAddSpaceBetweenMainActorAndBlock2() {
        let input = "@MainActor (@MainActor (Action) -> Void) async -> Void"
        testFormatting(for: input, rule: FormatRules.spaceAroundParens)
    }

    func testAddSpaceBetweenMainActorAndClosureParams() {
        let input = "{ @MainActor (foo: Int) in foo }"
        testFormatting(for: input, rule: FormatRules.spaceAroundParens)
    }

    func testSpaceBetweenUncheckedAndSendable() {
        let input = """
        enum Foo: @unchecked Sendable {
            case bar
        }
        """
        testFormatting(for: input, rule: FormatRules.spaceAroundParens)
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

    func testSpaceBetweenParenAndAny() {
        let input = "func any ()"
        let output = "func any()"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testSpaceBetweenParenAndAnyType() {
        let input = "let foo: any(A & B).Type"
        let output = "let foo: any (A & B).Type"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testSpaceBetweenParenAndSomeType() {
        let input = "func foo() -> some(A & B).Type"
        let output = "func foo() -> some (A & B).Type"
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
        let input = "if let (foo, bar) = baz {}"
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
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens, exclude: ["redundantVoidReturnType"])
    }

    func testAddSpaceBetweenCaptureListAndArguments3() {
        let input = "{ [weak self]() throws -> Void in }"
        let output = "{ [weak self] () throws -> Void in }"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens, exclude: ["redundantVoidReturnType"])
    }

    func testAddSpaceBetweenCaptureListAndArguments4() {
        let input = "{ [weak self](foo: @escaping(Bar?) -> Void) -> Baz? in foo }"
        let output = "{ [weak self] (foo: @escaping (Bar?) -> Void) -> Baz? in foo }"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testAddSpaceBetweenCaptureListAndArguments5() {
        let input = "{ [weak self](foo: @autoclosure() -> String) -> Baz? in foo() }"
        let output = "{ [weak self] (foo: @autoclosure () -> String) -> Baz? in foo() }"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testAddSpaceBetweenCaptureListAndArguments6() {
        let input = "{ [weak self](foo: @Sendable() -> String) -> Baz? in foo() }"
        let output = "{ [weak self] (foo: @Sendable () -> String) -> Baz? in foo() }"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testAddSpaceBetweenCaptureListAndArguments7() {
        let input = "Foo<Bar>(0) { [weak self]() -> Void in }"
        let output = "Foo<Bar>(0) { [weak self] () -> Void in }"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens, exclude: ["redundantVoidReturnType"])
    }

    func testAddSpaceBetweenEscapingAndParenthesizedClosure() {
        let input = "@escaping(() -> Void)"
        let output = "@escaping (() -> Void)"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testAddSpaceBetweenAutoclosureAndParenthesizedClosure() {
        let input = "@autoclosure(() -> String)"
        let output = "@autoclosure (() -> String)"
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
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens, exclude: ["redundantClosure"])
    }

    func testDontRemoveSpaceBetweenOpeningBraceAndParens() {
        let input = "a = (b + c)"
        testFormatting(for: input, rule: FormatRules.spaceAroundParens,
                       exclude: ["redundantParens"])
    }

    func testKeywordAsIdentifierParensSpacing() {
        let input = "if foo.let (foo, bar) {}"
        let output = "if foo.let(foo, bar) {}"
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

    func testSpaceAfterSendableAttribute() {
        let input = "func foo(bar: @Sendable () -> Void)"
        testFormatting(for: input, rule: FormatRules.spaceAroundParens)
    }

    func testSpaceBeforeTupleIndexArgument() {
        let input = "foo.1 (true)"
        let output = "foo.1(true)"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testRemoveSpaceBetweenParenAndBracket() {
        let input = "let foo = bar[5] ()"
        let output = "let foo = bar[5]()"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testRemoveSpaceBetweenParenAndBracketInsideClosure() {
        let input = "let foo = bar { [Int] () }"
        let output = "let foo = bar { [Int]() }"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testAddSpaceBetweenParenAndCaptureList() {
        let input = "let foo = bar { [self](foo: Int) in foo }"
        let output = "let foo = bar { [self] (foo: Int) in foo }"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testAddSpaceBetweenParenAndAwait() {
        let input = "let foo = await(bar: 5)"
        let output = "let foo = await (bar: 5)"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens)
    }

    func testAddSpaceBetweenParenAndAwaitForSwift5_5() {
        let input = "let foo = await(bar: 5)"
        let output = "let foo = await (bar: 5)"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundParens,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testNoAddSpaceBetweenParenAndAwaitForSwiftLessThan5_5() {
        let input = "let foo = await(bar: 5)"
        testFormatting(for: input, rule: FormatRules.spaceAroundParens,
                       options: FormatOptions(swiftVersion: "5.4.9"))
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
        let input = "if foo is[String] {}"
        let output = "if foo is [String] {}"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundBrackets)
    }

    func testKeywordAsIdentifierBracketSpacing() {
        let input = "if foo.is[String] {}"
        testFormatting(for: input, rule: FormatRules.spaceAroundBrackets)
    }

    func testSpaceBeforeTupleIndexSubscript() {
        let input = "foo.1 [2]"
        let output = "foo.1[2]"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundBrackets)
    }

    func testRemoveSpaceBetweenBracketAndParen() {
        let input = "let foo = bar[5] ()"
        let output = "let foo = bar[5]()"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundBrackets)
    }

    func testRemoveSpaceBetweenBracketAndParenInsideClosure() {
        let input = "let foo = bar { [Int] () }"
        let output = "let foo = bar { [Int]() }"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundBrackets)
    }

    func testAddSpaceBetweenCaptureListAndParen() {
        let input = "let foo = bar { [self](foo: Int) in foo }"
        let output = "let foo = bar { [self] (foo: Int) in foo }"
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
        testFormatting(for: input, output, rule: FormatRules.spaceAroundBraces,
                       exclude: ["wrapConditionalBodies"])
    }

    func testNoSpaceAroundClosureInsiderParens() {
        let input = "foo({ $0 == 5 })"
        testFormatting(for: input, rule: FormatRules.spaceAroundBraces,
                       exclude: ["trailingClosures"])
    }

    func testNoExtraSpaceAroundBracesAtStartOrEndOfFile() {
        let input = "{ foo }"
        testFormatting(for: input, rule: FormatRules.spaceAroundBraces)
    }

    func testNoSpaceAfterPrefixOperator() {
        let input = "let foo = ..{ bar }"
        testFormatting(for: input, rule: FormatRules.spaceAroundBraces)
    }

    func testNoSpaceBeforePostfixOperator() {
        let input = "let foo = { bar }.."
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

    func testNoSpaceAddedInsideEmptybraces() {
        let input = "foo({})"
        testFormatting(for: input, rule: FormatRules.spaceInsideBraces, exclude: ["trailingClosures"])
    }

    func testNoSpaceAddedBetweenDoublebraces() {
        let input = "func foo() -> () -> Void {{ bar() }}"
        testFormatting(for: input, rule: FormatRules.spaceInsideBraces)
    }

    // MARK: - spaceAroundGenerics

    func testSpaceAroundGenerics() {
        let input = "Foo <Bar <Baz>>"
        let output = "Foo<Bar<Baz>>"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundGenerics)
    }

    func testSpaceAroundGenericsFollowedByAndOperator() {
        let input = "if foo is Foo<Bar> && baz {}"
        testFormatting(for: input, rule: FormatRules.spaceAroundGenerics, exclude: ["andOperator"])
    }

    func testSpaceAroundGenericResultBuilder() {
        let input = "func foo(@SomeResultBuilder<Self> builder: () -> Void) {}"
        testFormatting(for: input, rule: FormatRules.spaceAroundGenerics)
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

    func testNoRemoveSpaceAroundEnumInBrackets() {
        let input = "[ .red ]"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators,
                       exclude: ["spaceInsideBrackets"])
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
        let input = "print(foo\n      ,bar)"
        let output = "print(foo\n      , bar)"
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

    func testSpaceNotAddedInKeyPath() {
        let input = "let a = b.map(\\.?.something)"
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators)
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
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators, options: options,
                       exclude: ["indent"])
    }

    func testSpaceOnOneSideOfPlusMatchedByLinebreakNotRemoved2() {
        let input = "let range = 0\n+ 4"
        let options = FormatOptions(noSpaceOperators: ["+"])
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators, options: options,
                       exclude: ["indent"])
    }

    func testSpaceAroundPlusWithLinebreakOnOneSideNotRemoved() {
        let input = "let range = 0 + \n4"
        let options = FormatOptions(noSpaceOperators: ["+"])
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators, options: options,
                       exclude: ["indent", "trailingSpace"])
    }

    func testSpaceAroundPlusWithLinebreakOnOneSideNotRemoved2() {
        let input = "let range = 0\n + 4"
        let options = FormatOptions(noSpaceOperators: ["+"])
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators, options: options,
                       exclude: ["indent"])
    }

    func testAddSpaceEvenAfterLHSClosure() {
        let input = "let foo = { $0 }..bar"
        let output = "let foo = { $0 } .. bar"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testAddSpaceEvenBeforeRHSClosure() {
        let input = "let foo = bar..{ $0 }"
        let output = "let foo = bar .. { $0 }"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testAddSpaceEvenAfterLHSArray() {
        let input = "let foo = [42]..bar"
        let output = "let foo = [42] .. bar"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testAddSpaceEvenBeforeRHSArray() {
        let input = "let foo = bar..[42]"
        let output = "let foo = bar .. [42]"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testAddSpaceEvenAfterLHSParens() {
        let input = "let foo = (42, 1337)..bar"
        let output = "let foo = (42, 1337) .. bar"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testAddSpaceEvenBeforeRHSParens() {
        let input = "let foo = bar..(42, 1337)"
        let output = "let foo = bar .. (42, 1337)"
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators)
    }

    func testRemoveSpaceEvenAfterLHSClosure() {
        let input = "let foo = { $0 } .. bar"
        let output = "let foo = { $0 }..bar"
        let options = FormatOptions(noSpaceOperators: [".."])
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators, options: options)
    }

    func testRemoveSpaceEvenBeforeRHSClosure() {
        let input = "let foo = bar .. { $0 }"
        let output = "let foo = bar..{ $0 }"
        let options = FormatOptions(noSpaceOperators: [".."])
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators, options: options)
    }

    func testRemoveSpaceEvenAfterLHSArray() {
        let input = "let foo = [42] .. bar"
        let output = "let foo = [42]..bar"
        let options = FormatOptions(noSpaceOperators: [".."])
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators, options: options)
    }

    func testRemoveSpaceEvenBeforeRHSArray() {
        let input = "let foo = bar .. [42]"
        let output = "let foo = bar..[42]"
        let options = FormatOptions(noSpaceOperators: [".."])
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators, options: options)
    }

    func testRemoveSpaceEvenAfterLHSParens() {
        let input = "let foo = (42, 1337) .. bar"
        let output = "let foo = (42, 1337)..bar"
        let options = FormatOptions(noSpaceOperators: [".."])
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators, options: options)
    }

    func testRemoveSpaceEvenBeforeRHSParens() {
        let input = "let foo = bar .. (42, 1337)"
        let output = "let foo = bar..(42, 1337)"
        let options = FormatOptions(noSpaceOperators: [".."])
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators, options: options)
    }

    // spaceAroundRangeOperators = false

    func testNoSpaceAroundRangeOperatorsWithCustomOptions() {
        let input = "foo ..< bar"
        let output = "foo..<bar"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, output, rule: FormatRules.spaceAroundOperators, options: options)
    }

    func testSpaceNotRemovedBeforeLeadingRangeOperatorWithSpaceAroundRangeOperatorsFalse() {
        let input = "let range = ..<foo.endIndex"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators, options: options)
    }

    func testSpaceOnOneSideOfRangeMatchedByCommentNotRemoved() {
        let input = "let range = 0 .../* foo */4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators, options: options,
                       exclude: ["spaceAroundComments"])
    }

    func testSpaceOnOneSideOfRangeMatchedByCommentNotRemoved2() {
        let input = "let range = 0/* foo */... 4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators, options: options,
                       exclude: ["spaceAroundComments"])
    }

    func testSpaceAroundRangeWithCommentOnOneSideNotRemoved() {
        let input = "let range = 0 ... /* foo */4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators, options: options,
                       exclude: ["spaceAroundComments"])
    }

    func testSpaceAroundRangeWithCommentOnOneSideNotRemoved2() {
        let input = "let range = 0/* foo */ ... 4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators, options: options,
                       exclude: ["spaceAroundComments"])
    }

    func testSpaceOnOneSideOfRangeMatchedByLinebreakNotRemoved() {
        let input = "let range = 0 ...\n4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators, options: options,
                       exclude: ["indent"])
    }

    func testSpaceOnOneSideOfRangeMatchedByLinebreakNotRemoved2() {
        let input = "let range = 0\n... 4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators, options: options,
                       exclude: ["indent"])
    }

    func testSpaceAroundRangeWithLinebreakOnOneSideNotRemoved() {
        let input = "let range = 0 ... \n4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators, options: options,
                       exclude: ["indent", "trailingSpace"])
    }

    func testSpaceAroundRangeWithLinebreakOnOneSideNotRemoved2() {
        let input = "let range = 0\n ... 4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators, options: options,
                       exclude: ["indent"])
    }

    func testSpaceNotRemovedAroundRangeFollowedByPrefixOperator() {
        let input = "let range = 0 ... -4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators, options: options)
    }

    func testSpaceNotRemovedAroundRangePreceededByPostfixOperator() {
        let input = "let range = 0>> ... 4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: FormatRules.spaceAroundOperators, options: options)
    }

    func testSpaceAroundDataTypeDelimiterLeadingAdded() {
        let input = "class Implementation: ImplementationProtocol {}"
        let output = "class Implementation : ImplementationProtocol {}"
        let options = FormatOptions(spaceAroundDelimiter: .leadingTrailing)
        testFormatting(
            for: input,
            output,
            rule: FormatRules.spaceAroundOperators,
            options: options
        )
    }

    func testSpaceAroundDataTypeDelimiterLeadingTrailingAdded() {
        let input = "class Implementation:ImplementationProtocol {}"
        let output = "class Implementation : ImplementationProtocol {}"
        let options = FormatOptions(spaceAroundDelimiter: .leadingTrailing)
        testFormatting(
            for: input,
            output,
            rule: FormatRules.spaceAroundOperators,
            options: options
        )
    }

    func testSpaceAroundDataTypeDelimiterLeadingTrailingNotModified() {
        let input = "class Implementation : ImplementationProtocol {}"
        let options = FormatOptions(spaceAroundDelimiter: .leadingTrailing)
        testFormatting(
            for: input,
            rule: FormatRules.spaceAroundOperators,
            options: options
        )
    }

    func testSpaceAroundDataTypeDelimiterTrailingAdded() {
        let input = "class Implementation:ImplementationProtocol {}"
        let output = "class Implementation: ImplementationProtocol {}"

        let options = FormatOptions(spaceAroundDelimiter: .trailing)
        testFormatting(
            for: input,
            output,
            rule: FormatRules.spaceAroundOperators,
            options: options
        )
    }

    func testSpaceAroundDataTypeDelimiterLeadingNotAdded() {
        let input = "class Implementation: ImplementationProtocol {}"
        let options = FormatOptions(spaceAroundDelimiter: .trailing)
        testFormatting(
            for: input,
            rule: FormatRules.spaceAroundOperators,
            options: options
        )
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
        testFormatting(for: input, output, rule: FormatRules.spaceInsideComments, exclude: ["docComments"])
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
        testFormatting(for: input, rule: FormatRules.spaceInsideComments, exclude: ["docComments"])
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
        testFormatting(for: input, rule: FormatRules.spaceInsideComments, exclude: ["docComments"])
    }

    func testNoSpaceAddedToEmptyDocComment() {
        let input = "///"
        testFormatting(for: input, rule: FormatRules.spaceInsideComments)
    }

    func testNoExtraTrailingSpaceAddedToDocComment() {
        let input = """
        class Foo {
            /**
            Call to configure forced disabling of Bills fallback mode.
            Intended for use only in debug builds and automated tests.
             */
            func bar() {}
        }
        """
        testFormatting(for: input, rule: FormatRules.spaceInsideComments, exclude: ["indent"])
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

    // MARK: - emptyBraces

    func testLinebreaksRemovedInsideBraces() {
        let input = "func foo() {\n  \n }"
        let output = "func foo() {}"
        testFormatting(for: input, output, rule: FormatRules.emptyBraces)
    }

    func testCommentNotRemovedInsideBraces() {
        let input = "func foo() { // foo\n}"
        testFormatting(for: input, rule: FormatRules.emptyBraces)
    }

    func testEmptyBracesNotRemovedInDoCatch() {
        let input = """
        do {
        } catch is FooError {
        } catch {}
        """
        testFormatting(for: input, rule: FormatRules.emptyBraces)
    }

    func testEmptyBracesNotRemovedInIfElse() {
        let input = """
        if bar {
        } else if foo {
        } else {}
        """
        testFormatting(for: input, rule: FormatRules.emptyBraces)
    }

    func testSpaceRemovedInsideEmptybraces() {
        let input = "foo { }"
        let output = "foo {}"
        testFormatting(for: input, output, rule: FormatRules.emptyBraces)
    }

    func testSpaceAddedInsideEmptyBracesWithSpacedConfiguration() {
        let input = "foo {}"
        let output = "foo { }"
        let options = FormatOptions(emptyBracesSpacing: .spaced)
        testFormatting(for: input, output, rule: FormatRules.emptyBraces, options: options)
    }

    func testLinebreaksRemovedInsideBracesWithSpacedConfiguration() {
        let input = "func foo() {\n  \n }"
        let output = "func foo() { }"
        let options = FormatOptions(emptyBracesSpacing: .spaced)
        testFormatting(for: input, output, rule: FormatRules.emptyBraces, options: options)
    }

    func testCommentNotRemovedInsideBracesWithSpacedConfiguration() {
        let input = "func foo() { // foo\n}"
        let options = FormatOptions(emptyBracesSpacing: .spaced)
        testFormatting(for: input, rule: FormatRules.emptyBraces, options: options)
    }

    func testEmptyBracesSpaceNotRemovedInDoCatchWithSpacedConfiguration() {
        let input = """
        do {
        } catch is FooError {
        } catch { }
        """
        let options = FormatOptions(emptyBracesSpacing: .spaced)
        testFormatting(for: input, rule: FormatRules.emptyBraces, options: options)
    }

    func testEmptyBracesSpaceNotRemovedInIfElseWithSpacedConfiguration() {
        let input = """
        if bar {
        } else if foo {
        } else { }
        """
        let options = FormatOptions(emptyBracesSpacing: .spaced)
        testFormatting(for: input, rule: FormatRules.emptyBraces, options: options)
    }

    func testEmptyBracesLinebreakNotRemovedInIfElseWithLinebreakConfiguration() {
        let input = """
        if bar {
        } else if foo {
        } else {
        }
        """
        let options = FormatOptions(emptyBracesSpacing: .linebreak)
        testFormatting(for: input, rule: FormatRules.emptyBraces, options: options)
    }

    func testEmptyBracesLinebreakIndentedCorrectly() {
        let input = """
        func foo() {
            if bar {
            } else if foo {
            } else {
            }
        }
        """
        let options = FormatOptions(emptyBracesSpacing: .linebreak)
        testFormatting(for: input, rule: FormatRules.emptyBraces, options: options)
    }
}
