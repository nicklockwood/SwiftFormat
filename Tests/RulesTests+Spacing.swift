//
//  RulesTests+Spacing.swift
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
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenParenAndClass() {
        let input = "@objc(XYZFoo)class foo"
        let output = "@objc(XYZFoo) class foo"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenConventionAndBlock() {
        let input = "@convention(block)() -> Void"
        let output = "@convention(block) () -> Void"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenConventionAndEscaping() {
        let input = "@convention(block)@escaping () -> Void"
        let output = "@convention(block) @escaping () -> Void"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenAutoclosureEscapingAndBlock() { // Swift 2.3 only
        let input = "@autoclosure(escaping)() -> Void"
        let output = "@autoclosure(escaping) () -> Void"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenSendableAndBlock() {
        let input = "@Sendable (Action) -> Void"
        testFormatting(for: input, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenMainActorAndBlock() {
        let input = "@MainActor (Action) -> Void"
        testFormatting(for: input, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenMainActorAndBlock2() {
        let input = "@MainActor (@MainActor (Action) -> Void) async -> Void"
        testFormatting(for: input, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenMainActorAndClosureParams() {
        let input = "{ @MainActor (foo: Int) in foo }"
        testFormatting(for: input, rule: .spaceAroundParens)
    }

    func testSpaceBetweenUncheckedAndSendable() {
        let input = """
        enum Foo: @unchecked Sendable {
            case bar
        }
        """
        testFormatting(for: input, rule: .spaceAroundParens)
    }

    func testSpaceBetweenParenAndAs() {
        let input = "(foo.bar) as? String"
        testFormatting(for: input, rule: .spaceAroundParens, exclude: [.redundantParens])
    }

    func testNoSpaceAfterParenAtEndOfFile() {
        let input = "(foo.bar)"
        testFormatting(for: input, rule: .spaceAroundParens, exclude: [.redundantParens])
    }

    func testSpaceBetweenParenAndFoo() {
        let input = "func foo ()"
        let output = "func foo()"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testSpaceBetweenParenAndAny() {
        let input = "func any ()"
        let output = "func any()"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testSpaceBetweenParenAndAnyType() {
        let input = "let foo: any(A & B).Type"
        let output = "let foo: any (A & B).Type"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testSpaceBetweenParenAndSomeType() {
        let input = "func foo() -> some(A & B).Type"
        let output = "func foo() -> some (A & B).Type"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testNoSpaceBetweenParenAndInit() {
        let input = "init ()"
        let output = "init()"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testNoSpaceBetweenObjcAndSelector() {
        let input = "@objc (XYZFoo) class foo"
        let output = "@objc(XYZFoo) class foo"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testNoSpaceBetweenHashSelectorAndBrace() {
        let input = "#selector(foo)"
        testFormatting(for: input, rule: .spaceAroundParens)
    }

    func testNoSpaceBetweenHashKeyPathAndBrace() {
        let input = "#keyPath (foo.bar)"
        let output = "#keyPath(foo.bar)"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testNoSpaceBetweenHashAvailableAndBrace() {
        let input = "#available (iOS 9.0, *)"
        let output = "#available(iOS 9.0, *)"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testNoSpaceBetweenPrivateAndSet() {
        let input = "private (set) var foo: Int"
        let output = "private(set) var foo: Int"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testSpaceBetweenLetAndTuple() {
        let input = "if let (foo, bar) = baz {}"
        testFormatting(for: input, rule: .spaceAroundParens)
    }

    func testSpaceBetweenIfAndCondition() {
        let input = "if(a || b) == true {}"
        let output = "if (a || b) == true {}"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testNoSpaceBetweenArrayLiteralAndParen() {
        let input = "[String] ()"
        let output = "[String]()"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenCaptureListAndArguments() {
        let input = "{ [weak self](foo) in print(foo) }"
        let output = "{ [weak self] (foo) in print(foo) }"
        testFormatting(for: input, output, rule: .spaceAroundParens, exclude: [.redundantParens])
    }

    func testAddSpaceBetweenCaptureListAndArguments2() {
        let input = "{ [weak self]() -> Void in }"
        let output = "{ [weak self] () -> Void in }"
        testFormatting(for: input, output, rule: .spaceAroundParens, exclude: [.redundantVoidReturnType])
    }

    func testAddSpaceBetweenCaptureListAndArguments3() {
        let input = "{ [weak self]() throws -> Void in }"
        let output = "{ [weak self] () throws -> Void in }"
        testFormatting(for: input, output, rule: .spaceAroundParens, exclude: [.redundantVoidReturnType])
    }

    func testAddSpaceBetweenCaptureListAndArguments4() {
        let input = "{ [weak self](foo: @escaping(Bar?) -> Void) -> Baz? in foo }"
        let output = "{ [weak self] (foo: @escaping (Bar?) -> Void) -> Baz? in foo }"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenCaptureListAndArguments5() {
        let input = "{ [weak self](foo: @autoclosure() -> String) -> Baz? in foo() }"
        let output = "{ [weak self] (foo: @autoclosure () -> String) -> Baz? in foo() }"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenCaptureListAndArguments6() {
        let input = "{ [weak self](foo: @Sendable() -> String) -> Baz? in foo() }"
        let output = "{ [weak self] (foo: @Sendable () -> String) -> Baz? in foo() }"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenCaptureListAndArguments7() {
        let input = "Foo<Bar>(0) { [weak self]() -> Void in }"
        let output = "Foo<Bar>(0) { [weak self] () -> Void in }"
        testFormatting(for: input, output, rule: .spaceAroundParens, exclude: [.redundantVoidReturnType])
    }

    func testAddSpaceBetweenCaptureListAndArguments8() {
        let input = "{ [weak self]() throws(Foo) -> Void in }"
        let output = "{ [weak self] () throws(Foo) -> Void in }"
        testFormatting(for: input, output, rule: .spaceAroundParens, exclude: [.redundantVoidReturnType])
    }

    func testAddSpaceBetweenEscapingAndParenthesizedClosure() {
        let input = "@escaping(() -> Void)"
        let output = "@escaping (() -> Void)"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenAutoclosureAndParenthesizedClosure() {
        let input = "@autoclosure(() -> String)"
        let output = "@autoclosure (() -> String)"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testSpaceBetweenClosingParenAndOpenBrace() {
        let input = "func foo(){ foo }"
        let output = "func foo() { foo }"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testNoSpaceBetweenClosingBraceAndParens() {
        let input = "{ block } ()"
        let output = "{ block }()"
        testFormatting(for: input, output, rule: .spaceAroundParens, exclude: [.redundantClosure])
    }

    func testDontRemoveSpaceBetweenOpeningBraceAndParens() {
        let input = "a = (b + c)"
        testFormatting(for: input, rule: .spaceAroundParens,
                       exclude: [.redundantParens])
    }

    func testKeywordAsIdentifierParensSpacing() {
        let input = "if foo.let (foo, bar) {}"
        let output = "if foo.let(foo, bar) {}"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testSpaceAfterInoutParam() {
        let input = "func foo(bar _: inout(Int, String)) {}"
        let output = "func foo(bar _: inout (Int, String)) {}"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testSpaceAfterEscapingAttribute() {
        let input = "func foo(bar: @escaping() -> Void)"
        let output = "func foo(bar: @escaping () -> Void)"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testSpaceAfterAutoclosureAttribute() {
        let input = "func foo(bar: @autoclosure () -> Void)"
        testFormatting(for: input, rule: .spaceAroundParens)
    }

    func testSpaceAfterSendableAttribute() {
        let input = "func foo(bar: @Sendable () -> Void)"
        testFormatting(for: input, rule: .spaceAroundParens)
    }

    func testSpaceBeforeTupleIndexArgument() {
        let input = "foo.1 (true)"
        let output = "foo.1(true)"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testRemoveSpaceBetweenParenAndBracket() {
        let input = "let foo = bar[5] ()"
        let output = "let foo = bar[5]()"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testRemoveSpaceBetweenParenAndBracketInsideClosure() {
        let input = "let foo = bar { [Int] () }"
        let output = "let foo = bar { [Int]() }"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenParenAndCaptureList() {
        let input = "let foo = bar { [self](foo: Int) in foo }"
        let output = "let foo = bar { [self] (foo: Int) in foo }"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenParenAndAwait() {
        let input = "let foo = await(bar: 5)"
        let output = "let foo = await (bar: 5)"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenParenAndAwaitForSwift5_5() {
        let input = "let foo = await(bar: 5)"
        let output = "let foo = await (bar: 5)"
        testFormatting(for: input, output, rule: .spaceAroundParens,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testNoAddSpaceBetweenParenAndAwaitForSwiftLessThan5_5() {
        let input = "let foo = await(bar: 5)"
        testFormatting(for: input, rule: .spaceAroundParens,
                       options: FormatOptions(swiftVersion: "5.4.9"))
    }

    func testRemoveSpaceBetweenParenAndConsume() {
        let input = "let foo = consume (bar)"
        let output = "let foo = consume(bar)"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testNoAddSpaceBetweenParenAndAvailableAfterFunc() {
        let input = """
        func foo()

        @available(macOS 10.13, *)
        func bar()
        """
        testFormatting(for: input, rule: .spaceAroundParens)
    }

    func testNoAddSpaceAroundTypedThrowsFunctionType() {
        let input = "func foo() throws (Bar) -> Baz {}"
        let output = "func foo() throws(Bar) -> Baz {}"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenParenAndBorrowing() {
        let input = "func foo(_: borrowing(any Foo)) {}"
        let output = "func foo(_: borrowing (any Foo)) {}"
        testFormatting(for: input, output, rule: .spaceAroundParens,
                       exclude: [.noExplicitOwnership])
    }

    func testAddSpaceBetweenParenAndIsolated() {
        let input = "func foo(isolation _: isolated(any Actor)) {}"
        let output = "func foo(isolation _: isolated (any Actor)) {}"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    func testAddSpaceBetweenParenAndSending() {
        let input = "func foo(_: sending(any Foo)) {}"
        let output = "func foo(_: sending (any Foo)) {}"
        testFormatting(for: input, output, rule: .spaceAroundParens)
    }

    // MARK: - spaceInsideParens

    func testSpaceInsideParens() {
        let input = "( 1, ( 2, 3 ) )"
        let output = "(1, (2, 3))"
        testFormatting(for: input, output, rule: .spaceInsideParens)
    }

    func testSpaceBeforeCommentInsideParens() {
        let input = "( /* foo */ 1, 2 )"
        let output = "( /* foo */ 1, 2)"
        testFormatting(for: input, output, rule: .spaceInsideParens)
    }

    // MARK: - spaceAroundBrackets

    func testSubscriptNoAddSpacing() {
        let input = "foo[bar] = baz"
        testFormatting(for: input, rule: .spaceAroundBrackets)
    }

    func testSubscriptRemoveSpacing() {
        let input = "foo [bar] = baz"
        let output = "foo[bar] = baz"
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testArrayLiteralSpacing() {
        let input = "foo = [bar, baz]"
        testFormatting(for: input, rule: .spaceAroundBrackets)
    }

    func testAsArrayCastingSpacing() {
        let input = "foo as[String]"
        let output = "foo as [String]"
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testAsOptionalArrayCastingSpacing() {
        let input = "foo as? [String]"
        testFormatting(for: input, rule: .spaceAroundBrackets)
    }

    func testIsArrayTestingSpacing() {
        let input = "if foo is[String] {}"
        let output = "if foo is [String] {}"
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testKeywordAsIdentifierBracketSpacing() {
        let input = "if foo.is[String] {}"
        testFormatting(for: input, rule: .spaceAroundBrackets)
    }

    func testSpaceBeforeTupleIndexSubscript() {
        let input = "foo.1 [2]"
        let output = "foo.1[2]"
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testRemoveSpaceBetweenBracketAndParen() {
        let input = "let foo = bar[5] ()"
        let output = "let foo = bar[5]()"
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testRemoveSpaceBetweenBracketAndParenInsideClosure() {
        let input = "let foo = bar { [Int] () }"
        let output = "let foo = bar { [Int]() }"
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testAddSpaceBetweenCaptureListAndParen() {
        let input = "let foo = bar { [self](foo: Int) in foo }"
        let output = "let foo = bar { [self] (foo: Int) in foo }"
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testAddSpaceBetweenInoutAndStringArray() {
        let input = "func foo(arg _: inout[String]) {}"
        let output = "func foo(arg _: inout [String]) {}"
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testAddSpaceBetweenConsumingAndStringArray() {
        let input = "func foo(arg _: consuming[String]) {}"
        let output = "func foo(arg _: consuming [String]) {}"
        testFormatting(for: input, output, rule: .spaceAroundBrackets,
                       exclude: [.noExplicitOwnership])
    }

    func testAddSpaceBetweenBorrowingAndStringArray() {
        let input = "func foo(arg _: borrowing[String]) {}"
        let output = "func foo(arg _: borrowing [String]) {}"
        testFormatting(for: input, output, rule: .spaceAroundBrackets,
                       exclude: [.noExplicitOwnership])
    }

    func testAddSpaceBetweenSendingAndStringArray() {
        let input = "func foo(arg _: sending[String]) {}"
        let output = "func foo(arg _: sending [String]) {}"
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    // MARK: - spaceInsideBrackets

    func testSpaceInsideBrackets() {
        let input = "foo[ 5 ]"
        let output = "foo[5]"
        testFormatting(for: input, output, rule: .spaceInsideBrackets)
    }

    func testSpaceInsideWrappedArray() {
        let input = "[ foo,\n bar ]"
        let output = "[foo,\n bar]"
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, output, rule: .spaceInsideBrackets, options: options)
    }

    func testSpaceBeforeCommentInsideWrappedArray() {
        let input = "[ // foo\n    bar,\n]"
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, rule: .spaceInsideBrackets, options: options)
    }

    // MARK: - spaceAroundBraces

    func testSpaceAroundTrailingClosure() {
        let input = "if x{ y }else{ z }"
        let output = "if x { y } else { z }"
        testFormatting(for: input, output, rule: .spaceAroundBraces,
                       exclude: [.wrapConditionalBodies])
    }

    func testNoSpaceAroundClosureInsiderParens() {
        let input = "foo({ $0 == 5 })"
        testFormatting(for: input, rule: .spaceAroundBraces,
                       exclude: [.trailingClosures])
    }

    func testNoExtraSpaceAroundBracesAtStartOrEndOfFile() {
        let input = "{ foo }"
        testFormatting(for: input, rule: .spaceAroundBraces)
    }

    func testNoSpaceAfterPrefixOperator() {
        let input = "let foo = ..{ bar }"
        testFormatting(for: input, rule: .spaceAroundBraces)
    }

    func testNoSpaceBeforePostfixOperator() {
        let input = "let foo = { bar }.."
        testFormatting(for: input, rule: .spaceAroundBraces)
    }

    func testSpaceAroundBracesAfterOptionalProperty() {
        let input = "var: Foo?{}"
        let output = "var: Foo? {}"
        testFormatting(for: input, output, rule: .spaceAroundBraces)
    }

    func testSpaceAroundBracesAfterImplicitlyUnwrappedProperty() {
        let input = "var: Foo!{}"
        let output = "var: Foo! {}"
        testFormatting(for: input, output, rule: .spaceAroundBraces)
    }

    func testSpaceAroundBracesAfterNumber() {
        let input = "if x = 5{}"
        let output = "if x = 5 {}"
        testFormatting(for: input, output, rule: .spaceAroundBraces)
    }

    func testSpaceAroundBracesAfterString() {
        let input = "if x = \"\"{}"
        let output = "if x = \"\" {}"
        testFormatting(for: input, output, rule: .spaceAroundBraces)
    }

    // MARK: - spaceInsideBraces

    func testSpaceInsideBraces() {
        let input = "foo({bar})"
        let output = "foo({ bar })"
        testFormatting(for: input, output, rule: .spaceInsideBraces, exclude: [.trailingClosures])
    }

    func testNoExtraSpaceInsidebraces() {
        let input = "{ foo }"
        testFormatting(for: input, rule: .spaceInsideBraces, exclude: [.trailingClosures])
    }

    func testNoSpaceAddedInsideEmptybraces() {
        let input = "foo({})"
        testFormatting(for: input, rule: .spaceInsideBraces, exclude: [.trailingClosures])
    }

    func testNoSpaceAddedBetweenDoublebraces() {
        let input = "func foo() -> () -> Void {{ bar() }}"
        testFormatting(for: input, rule: .spaceInsideBraces)
    }

    // MARK: - spaceAroundGenerics

    func testSpaceAroundGenerics() {
        let input = "Foo <Bar <Baz>>"
        let output = "Foo<Bar<Baz>>"
        testFormatting(for: input, output, rule: .spaceAroundGenerics)
    }

    func testSpaceAroundGenericsFollowedByAndOperator() {
        let input = "if foo is Foo<Bar> && baz {}"
        testFormatting(for: input, rule: .spaceAroundGenerics, exclude: [.andOperator])
    }

    func testSpaceAroundGenericResultBuilder() {
        let input = "func foo(@SomeResultBuilder<Self> builder: () -> Void) {}"
        testFormatting(for: input, rule: .spaceAroundGenerics)
    }

    // MARK: - spaceInsideGenerics

    func testSpaceInsideGenerics() {
        let input = "Foo< Bar< Baz > >"
        let output = "Foo<Bar<Baz>>"
        testFormatting(for: input, output, rule: .spaceInsideGenerics)
    }

    // MARK: - spaceAroundOperators

    func testSpaceAfterColon() {
        let input = "let foo:Bar = 5"
        let output = "let foo: Bar = 5"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceBetweenOptionalAndDefaultValue() {
        let input = "let foo: String?=nil"
        let output = "let foo: String? = nil"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceBetweenImplictlyUnwrappedOptionalAndDefaultValue() {
        let input = "let foo: String!=nil"
        let output = "let foo: String! = nil"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpacePreservedBetweenOptionalTryAndDot() {
        let input = "let foo: Int = try? .init()"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testSpacePreservedBetweenForceTryAndDot() {
        let input = "let foo: Int = try! .init()"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testSpaceBetweenOptionalAndDefaultValueInFunction() {
        let input = "func foo(bar _: String?=nil) {}"
        let output = "func foo(bar _: String? = nil) {}"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testNoSpaceAddedAfterColonInSelector() {
        let input = "@objc(foo:bar:)"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testSpaceAfterColonInSwitchCase() {
        let input = "switch x { case .y:break }"
        let output = "switch x { case .y: break }"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceAfterColonInSwitchDefault() {
        let input = "switch x { default:break }"
        let output = "switch x { default: break }"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceAfterComma() {
        let input = "let foo = [1,2,3]"
        let output = "let foo = [1, 2, 3]"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceBetweenColonAndEnumValue() {
        let input = "[.Foo:.Bar]"
        let output = "[.Foo: .Bar]"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceBetweenCommaAndEnumValue() {
        let input = "[.Foo,.Bar]"
        let output = "[.Foo, .Bar]"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testNoRemoveSpaceAroundEnumInBrackets() {
        let input = "[ .red ]"
        testFormatting(for: input, rule: .spaceAroundOperators,
                       exclude: [.spaceInsideBrackets])
    }

    func testSpaceBetweenSemicolonAndEnumValue() {
        let input = "statement;.Bar"
        let output = "statement; .Bar"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpacePreservedBetweenEqualsAndEnumValue() {
        let input = "foo = .Bar"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testNoSpaceBeforeColon() {
        let input = "let foo : Bar = 5"
        let output = "let foo: Bar = 5"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpacePreservedBeforeColonInTernary() {
        let input = "foo ? bar : baz"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testSpacePreservedAroundEnumValuesInTernary() {
        let input = "foo ? .Bar : .Baz"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testSpaceBeforeColonInNestedTernary() {
        let input = "foo ? (hello + a ? b: c) : baz"
        let output = "foo ? (hello + a ? b : c) : baz"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testNoSpaceBeforeComma() {
        let input = "let foo = [1 , 2 , 3]"
        let output = "let foo = [1, 2, 3]"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceAtStartOfLine() {
        let input = "print(foo\n      ,bar)"
        let output = "print(foo\n      , bar)"
        testFormatting(for: input, output, rule: .spaceAroundOperators,
                       exclude: [.leadingDelimiters])
    }

    func testSpaceAroundInfixMinus() {
        let input = "foo-bar"
        let output = "foo - bar"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testNoSpaceAroundPrefixMinus() {
        let input = "foo + -bar"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testSpaceAroundLessThan() {
        let input = "foo<bar"
        let output = "foo < bar"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testRemoveSpaceAroundDot() {
        let input = "foo . bar"
        let output = "foo.bar"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testNoSpaceAroundDotOnNewLine() {
        let input = "foo\n    .bar"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testSpaceAroundEnumCase() {
        let input = "case .Foo,.Bar:"
        let output = "case .Foo, .Bar:"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSwitchWithEnumCases() {
        let input = "switch x {\ncase.Foo:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\ncase .Foo:\n    break\ndefault:\n    break\n}"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceAroundEnumReturn() {
        let input = "return.Foo"
        let output = "return .Foo"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testNoSpaceAfterReturnAsIdentifier() {
        let input = "foo.return.Bar"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testSpaceAroundCaseLet() {
        let input = "case let.Foo(bar):"
        let output = "case let .Foo(bar):"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceAroundEnumArgument() {
        let input = "foo(with:.Bar)"
        let output = "foo(with: .Bar)"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceBeforeEnumCaseInsideClosure() {
        let input = "{ .bar() }"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testNoSpaceAroundMultipleOptionalChaining() {
        let input = "foo??!?!.bar"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testNoSpaceAroundForcedChaining() {
        let input = "foo!.bar"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testNoSpaceAddedInOptionalChaining() {
        let input = "foo?.bar"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testSpaceRemovedInOptionalChaining() {
        let input = "foo? .bar"
        let output = "foo?.bar"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceRemovedInForcedChaining() {
        let input = "foo! .bar"
        let output = "foo!.bar"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceRemovedInMultipleOptionalChaining() {
        let input = "foo??! .bar"
        let output = "foo??!.bar"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testNoSpaceAfterOptionalInsideTernary() {
        let input = "x ? foo? .bar() : bar?.baz()"
        let output = "x ? foo?.bar() : bar?.baz()"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSplitLineOptionalChaining() {
        let input = "foo?\n    .bar"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testSplitLineMultipleOptionalChaining() {
        let input = "foo??!\n    .bar"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testSpaceBetweenNullCoalescingAndDot() {
        let input = "foo ?? .bar()"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testNoSpaceAroundFailableInit() {
        let input = "init?()"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testNoSpaceAroundImplictlyUnwrappedFailableInit() {
        let input = "init!()"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testNoSpaceAroundFailableInitWithGenerics() {
        let input = "init?<T>()"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testNoSpaceAroundImplictlyUnwrappedFailableInitWithGenerics() {
        let input = "init!<T>()"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testNoSpaceAroundInitWithGenericAndSuppressedConstraint() {
        let input = "init<T: ~Copyable>()"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testGenericBracketAroundAttributeNotConfusedWithLessThan() {
        let input = "Example<(@MainActor () -> Void)?>(nil)"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testSpaceAfterOptionalAs() {
        let input = "foo as?[String]"
        let output = "foo as? [String]"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceAfterForcedAs() {
        let input = "foo as![String]"
        let output = "foo as! [String]"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testNoSpaceAroundGenerics() {
        let input = "Foo<String>"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testNoSpaceAroundGenericsWithSuppressedConstraint() {
        let input = "Foo<String: ~Copyable>"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testSpaceAroundReturnTypeArrow() {
        let input = "foo() ->Bool"
        let output = "foo() -> Bool"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceAroundCommentInInfixExpression() {
        let input = "foo/* hello */-bar"
        let output = "foo/* hello */ -bar"
        testFormatting(for: input, output, rule: .spaceAroundOperators,
                       exclude: [.spaceAroundComments])
    }

    func testSpaceAroundCommentsInInfixExpression() {
        let input = "a/* */+/* */b"
        let output = "a/* */ + /* */b"
        testFormatting(for: input, output, rule: .spaceAroundOperators,
                       exclude: [.spaceAroundComments])
    }

    func testSpaceAroundCommentInPrefixExpression() {
        let input = "a + /* hello */ -bar"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testPrefixMinusBeforeMember() {
        let input = "-.foo"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testPostfixMinusBeforeMember() {
        let input = "foo-.bar"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testRemoveSpaceBeforeNegativeIndex() {
        let input = "foo[ -bar]"
        let output = "foo[-bar]"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testNoInsertSpaceBeforeUnlabelledAddressArgument() {
        let input = "foo(&bar)"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testRemoveSpaceBeforeUnlabelledAddressArgument() {
        let input = "foo( &bar, baz: &baz)"
        let output = "foo(&bar, baz: &baz)"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testRemoveSpaceBeforeKeyPath() {
        let input = "foo( \\.bar)"
        let output = "foo(\\.bar)"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testAddSpaceAfterFuncEquals() {
        let input = "func ==(lhs: Int, rhs: Int) -> Bool { return lhs === rhs }"
        let output = "func == (lhs: Int, rhs: Int) -> Bool { return lhs === rhs }"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testRemoveSpaceAfterFuncEquals() {
        let input = "func == (lhs: Int, rhs: Int) -> Bool { return lhs === rhs }"
        let output = "func ==(lhs: Int, rhs: Int) -> Bool { return lhs === rhs }"
        let options = FormatOptions(spaceAroundOperatorDeclarations: false)
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    func testAddSpaceAfterOperatorEquals() {
        let input = "operator =={}"
        let output = "operator == {}"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testNoRemoveSpaceAfterOperatorEqualsWhenSpaceAroundOperatorDeclarationsFalse() {
        let input = "operator == {}"
        let options = FormatOptions(spaceAroundOperatorDeclarations: false)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    func testNoAddSpaceAfterOperatorEqualsWithAllmanBrace() {
        let input = "operator ==\n{}"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testNoAddSpaceAroundOperatorInsideParens() {
        let input = "(!=)"
        testFormatting(for: input, rule: .spaceAroundOperators, exclude: [.redundantParens])
    }

    func testSpaceAroundPlusBeforeHash() {
        let input = "\"foo.\"+#file"
        let output = "\"foo.\" + #file"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceNotAddedAroundStarInAvailableAnnotation() {
        let input = "@available(*, deprecated, message: \"foo\")"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testAddSpaceAroundRange() {
        let input = "let a = b...c"
        let output = "let a = b ... c"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceRemovedInNestedPropertyWrapper() {
        let input = "@Encoded .Foo var foo: String"
        let output = "@Encoded.Foo var foo: String"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceNotAddedInKeyPath() {
        let input = "let a = b.map(\\.?.something)"
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    // noSpaceOperators

    func testNoAddSpaceAroundNoSpaceStar() {
        let input = "let a = b*c+d"
        let output = "let a = b*c + d"
        let options = FormatOptions(noSpaceOperators: ["*"])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    func testRemoveSpaceAroundNoSpaceStar() {
        let input = "let a = b * c + d"
        let output = "let a = b*c + d"
        let options = FormatOptions(noSpaceOperators: ["*"])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    func testNoRemoveSpaceAroundNoSpaceStarBeforePrefixOperator() {
        let input = "let a = b * -c"
        let options = FormatOptions(noSpaceOperators: ["*"])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    func testNoRemoveSpaceAroundNoSpaceStarAfterPostfixOperator() {
        let input = "let a = b% * c"
        let options = FormatOptions(noSpaceOperators: ["*"])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    func testRemoveSpaceAroundNoSpaceStarAfterUnwrapOperator() {
        let input = "let a = b! * c"
        let output = "let a = b!*c"
        let options = FormatOptions(noSpaceOperators: ["*"])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    func testNoAddSpaceAroundNoSpaceSlash() {
        let input = "let a = b/c+d"
        let output = "let a = b/c + d"
        let options = FormatOptions(noSpaceOperators: ["/"])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    func testNoAddSpaceAroundNoSpaceRange() {
        let input = "let a = b...c"
        let options = FormatOptions(noSpaceOperators: ["..."])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    func testNoAddSpaceAroundNoSpaceHalfOpenRange() {
        let input = "let a = b..<c"
        let options = FormatOptions(noSpaceOperators: ["..<"])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    func testRemoveSpaceAroundNoSpaceRange() {
        let input = "let a = b ... c"
        let output = "let a = b...c"
        let options = FormatOptions(noSpaceOperators: ["..."])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    func testNoRemoveSpaceAroundNoSpaceRangeBeforePrefixOperator() {
        let input = "let a = b ... -c"
        let options = FormatOptions(noSpaceOperators: ["..."])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    func testNoRemoveSpaceAroundTernaryColon() {
        let input = "let a = b ? c : d"
        let output = "let a = b ? c:d"
        let options = FormatOptions(noSpaceOperators: [":"])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    func testNoRemoveSpaceAroundTernaryQuestionMark() {
        let input = "let a = b ? c : d"
        let options = FormatOptions(noSpaceOperators: ["?"])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    func testSpaceOnOneSideOfPlusMatchedByLinebreakNotRemoved() {
        let input = "let range = 0 +\n4"
        let options = FormatOptions(noSpaceOperators: ["+"])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.indent])
    }

    func testSpaceOnOneSideOfPlusMatchedByLinebreakNotRemoved2() {
        let input = "let range = 0\n+ 4"
        let options = FormatOptions(noSpaceOperators: ["+"])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.indent])
    }

    func testSpaceAroundPlusWithLinebreakOnOneSideNotRemoved() {
        let input = "let range = 0 + \n4"
        let options = FormatOptions(noSpaceOperators: ["+"])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.indent, .trailingSpace])
    }

    func testSpaceAroundPlusWithLinebreakOnOneSideNotRemoved2() {
        let input = "let range = 0\n + 4"
        let options = FormatOptions(noSpaceOperators: ["+"])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.indent])
    }

    func testAddSpaceEvenAfterLHSClosure() {
        let input = "let foo = { $0 }..bar"
        let output = "let foo = { $0 } .. bar"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testAddSpaceEvenBeforeRHSClosure() {
        let input = "let foo = bar..{ $0 }"
        let output = "let foo = bar .. { $0 }"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testAddSpaceEvenAfterLHSArray() {
        let input = "let foo = [42]..bar"
        let output = "let foo = [42] .. bar"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testAddSpaceEvenBeforeRHSArray() {
        let input = "let foo = bar..[42]"
        let output = "let foo = bar .. [42]"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testAddSpaceEvenAfterLHSParens() {
        let input = "let foo = (42, 1337)..bar"
        let output = "let foo = (42, 1337) .. bar"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testAddSpaceEvenBeforeRHSParens() {
        let input = "let foo = bar..(42, 1337)"
        let output = "let foo = bar .. (42, 1337)"
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testRemoveSpaceEvenAfterLHSClosure() {
        let input = "let foo = { $0 } .. bar"
        let output = "let foo = { $0 }..bar"
        let options = FormatOptions(noSpaceOperators: [".."])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    func testRemoveSpaceEvenBeforeRHSClosure() {
        let input = "let foo = bar .. { $0 }"
        let output = "let foo = bar..{ $0 }"
        let options = FormatOptions(noSpaceOperators: [".."])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    func testRemoveSpaceEvenAfterLHSArray() {
        let input = "let foo = [42] .. bar"
        let output = "let foo = [42]..bar"
        let options = FormatOptions(noSpaceOperators: [".."])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    func testRemoveSpaceEvenBeforeRHSArray() {
        let input = "let foo = bar .. [42]"
        let output = "let foo = bar..[42]"
        let options = FormatOptions(noSpaceOperators: [".."])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    func testRemoveSpaceEvenAfterLHSParens() {
        let input = "let foo = (42, 1337) .. bar"
        let output = "let foo = (42, 1337)..bar"
        let options = FormatOptions(noSpaceOperators: [".."])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    func testRemoveSpaceEvenBeforeRHSParens() {
        let input = "let foo = bar .. (42, 1337)"
        let output = "let foo = bar..(42, 1337)"
        let options = FormatOptions(noSpaceOperators: [".."])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    // spaceAroundRangeOperators = false

    func testNoSpaceAroundRangeOperatorsWithCustomOptions() {
        let input = "foo ..< bar"
        let output = "foo..<bar"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    func testSpaceNotRemovedBeforeLeadingRangeOperatorWithSpaceAroundRangeOperatorsFalse() {
        let input = "let range = ..<foo.endIndex"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    func testSpaceOnOneSideOfRangeMatchedByCommentNotRemoved() {
        let input = "let range = 0 .../* foo */4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.spaceAroundComments])
    }

    func testSpaceOnOneSideOfRangeMatchedByCommentNotRemoved2() {
        let input = "let range = 0/* foo */... 4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.spaceAroundComments])
    }

    func testSpaceAroundRangeWithCommentOnOneSideNotRemoved() {
        let input = "let range = 0 ... /* foo */4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.spaceAroundComments])
    }

    func testSpaceAroundRangeWithCommentOnOneSideNotRemoved2() {
        let input = "let range = 0/* foo */ ... 4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.spaceAroundComments])
    }

    func testSpaceOnOneSideOfRangeMatchedByLinebreakNotRemoved() {
        let input = "let range = 0 ...\n4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.indent])
    }

    func testSpaceOnOneSideOfRangeMatchedByLinebreakNotRemoved2() {
        let input = "let range = 0\n... 4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.indent])
    }

    func testSpaceAroundRangeWithLinebreakOnOneSideNotRemoved() {
        let input = "let range = 0 ... \n4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.indent, .trailingSpace])
    }

    func testSpaceAroundRangeWithLinebreakOnOneSideNotRemoved2() {
        let input = "let range = 0\n ... 4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.indent])
    }

    func testSpaceNotRemovedAroundRangeFollowedByPrefixOperator() {
        let input = "let range = 0 ... -4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    func testSpaceNotRemovedAroundRangePreceededByPostfixOperator() {
        let input = "let range = 0>> ... 4"
        let options = FormatOptions(spaceAroundRangeOperators: false)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    func testSpaceAroundDataTypeDelimiterLeadingAdded() {
        let input = "class Implementation: ImplementationProtocol {}"
        let output = "class Implementation : ImplementationProtocol {}"
        let options = FormatOptions(typeDelimiterSpacing: .spaced)
        testFormatting(
            for: input,
            output,
            rule: .spaceAroundOperators,
            options: options
        )
    }

    func testSpaceAroundDataTypeDelimiterLeadingTrailingAdded() {
        let input = "class Implementation:ImplementationProtocol {}"
        let output = "class Implementation : ImplementationProtocol {}"
        let options = FormatOptions(typeDelimiterSpacing: .spaced)
        testFormatting(
            for: input,
            output,
            rule: .spaceAroundOperators,
            options: options
        )
    }

    func testSpaceAroundDataTypeDelimiterLeadingTrailingNotModified() {
        let input = "class Implementation : ImplementationProtocol {}"
        let options = FormatOptions(typeDelimiterSpacing: .spaced)
        testFormatting(
            for: input,
            rule: .spaceAroundOperators,
            options: options
        )
    }

    func testSpaceAroundDataTypeDelimiterTrailingAdded() {
        let input = "class Implementation:ImplementationProtocol {}"
        let output = "class Implementation: ImplementationProtocol {}"

        let options = FormatOptions(typeDelimiterSpacing: .spaceAfter)
        testFormatting(
            for: input,
            output,
            rule: .spaceAroundOperators,
            options: options
        )
    }

    func testSpaceAroundDataTypeDelimiterLeadingNotAdded() {
        let input = "class Implementation: ImplementationProtocol {}"
        let options = FormatOptions(typeDelimiterSpacing: .spaceAfter)
        testFormatting(
            for: input,
            rule: .spaceAroundOperators,
            options: options
        )
    }

    // MARK: - spaceAroundComments

    func testSpaceAroundCommentInParens() {
        let input = "(/* foo */)"
        let output = "( /* foo */ )"
        testFormatting(for: input, output, rule: .spaceAroundComments,
                       exclude: [.redundantParens])
    }

    func testNoSpaceAroundCommentAtStartAndEndOfFile() {
        let input = "/* foo */"
        testFormatting(for: input, rule: .spaceAroundComments)
    }

    func testNoSpaceAroundCommentBeforeComma() {
        let input = "(foo /* foo */ , bar)"
        let output = "(foo /* foo */, bar)"
        testFormatting(for: input, output, rule: .spaceAroundComments)
    }

    func testSpaceAroundSingleLineComment() {
        let input = "func foo() {// comment\n}"
        let output = "func foo() { // comment\n}"
        testFormatting(for: input, output, rule: .spaceAroundComments)
    }

    // MARK: - spaceInsideComments

    func testSpaceInsideMultilineComment() {
        let input = "/*foo\n bar*/"
        let output = "/* foo\n bar */"
        testFormatting(for: input, output, rule: .spaceInsideComments)
    }

    func testSpaceInsideSingleLineMultilineComment() {
        let input = "/*foo*/"
        let output = "/* foo */"
        testFormatting(for: input, output, rule: .spaceInsideComments)
    }

    func testNoSpaceInsideEmptyMultilineComment() {
        let input = "/**/"
        testFormatting(for: input, rule: .spaceInsideComments)
    }

    func testSpaceInsideSingleLineComment() {
        let input = "//foo"
        let output = "// foo"
        testFormatting(for: input, output, rule: .spaceInsideComments)
    }

    func testSpaceInsideMultilineHeaderdocComment() {
        let input = "/**foo\n bar*/"
        let output = "/** foo\n bar */"
        testFormatting(for: input, output, rule: .spaceInsideComments, exclude: [.docComments])
    }

    func testSpaceInsideMultilineHeaderdocCommentType2() {
        let input = "/*!foo\n bar*/"
        let output = "/*! foo\n bar */"
        testFormatting(for: input, output, rule: .spaceInsideComments)
    }

    func testSpaceInsideMultilineSwiftPlaygroundDocComment() {
        let input = "/*:foo\n bar*/"
        let output = "/*: foo\n bar */"
        testFormatting(for: input, output, rule: .spaceInsideComments)
    }

    func testNoExtraSpaceInsideMultilineHeaderdocComment() {
        let input = "/** foo\n bar */"
        testFormatting(for: input, rule: .spaceInsideComments, exclude: [.docComments])
    }

    func testNoExtraSpaceInsideMultilineHeaderdocCommentType2() {
        let input = "/*! foo\n bar */"
        testFormatting(for: input, rule: .spaceInsideComments)
    }

    func testNoExtraSpaceInsideMultilineSwiftPlaygroundDocComment() {
        let input = "/*: foo\n bar */"
        testFormatting(for: input, rule: .spaceInsideComments)
    }

    func testSpaceInsideSingleLineHeaderdocComment() {
        let input = "///foo"
        let output = "/// foo"
        testFormatting(for: input, output, rule: .spaceInsideComments)
    }

    func testSpaceInsideSingleLineHeaderdocCommentType2() {
        let input = "//!foo"
        let output = "//! foo"
        testFormatting(for: input, output, rule: .spaceInsideComments)
    }

    func testSpaceInsideSingleLineSwiftPlaygroundDocComment() {
        let input = "//:foo"
        let output = "//: foo"
        testFormatting(for: input, output, rule: .spaceInsideComments)
    }

    func testPreformattedMultilineComment() {
        let input = "/*********************\n *****Hello World*****\n *********************/"
        testFormatting(for: input, rule: .spaceInsideComments)
    }

    func testPreformattedSingleLineComment() {
        let input = "/////////ATTENTION////////"
        testFormatting(for: input, rule: .spaceInsideComments)
    }

    func testNoSpaceAddedToFirstLineOfDocComment() {
        let input = "/**\n Comment\n */"
        testFormatting(for: input, rule: .spaceInsideComments, exclude: [.docComments])
    }

    func testNoSpaceAddedToEmptyDocComment() {
        let input = "///"
        testFormatting(for: input, rule: .spaceInsideComments)
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
        testFormatting(for: input, rule: .spaceInsideComments, exclude: [.indent])
    }

    // MARK: - consecutiveSpaces

    func testConsecutiveSpaces() {
        let input = "let foo  = bar"
        let output = "let foo = bar"
        testFormatting(for: input, output, rule: .consecutiveSpaces)
    }

    func testConsecutiveSpacesAfterComment() {
        let input = "// comment\nfoo  bar"
        let output = "// comment\nfoo bar"
        testFormatting(for: input, output, rule: .consecutiveSpaces)
    }

    func testConsecutiveSpacesDoesntStripIndent() {
        let input = "{\n    let foo  = bar\n}"
        let output = "{\n    let foo = bar\n}"
        testFormatting(for: input, output, rule: .consecutiveSpaces)
    }

    func testConsecutiveSpacesDoesntAffectMultilineComments() {
        let input = "/*    comment  */"
        testFormatting(for: input, rule: .consecutiveSpaces)
    }

    func testConsecutiveSpacesRemovedBetweenComments() {
        let input = "/* foo */  /* bar */"
        let output = "/* foo */ /* bar */"
        testFormatting(for: input, output, rule: .consecutiveSpaces)
    }

    func testConsecutiveSpacesDoesntAffectNestedMultilineComments() {
        let input = "/*  foo  /*  bar  */  baz  */"
        testFormatting(for: input, rule: .consecutiveSpaces)
    }

    func testConsecutiveSpacesDoesntAffectNestedMultilineComments2() {
        let input = "/*  /*  foo  */  /*  bar  */  */"
        testFormatting(for: input, rule: .consecutiveSpaces)
    }

    func testConsecutiveSpacesDoesntAffectSingleLineComments() {
        let input = "//    foo  bar"
        testFormatting(for: input, rule: .consecutiveSpaces)
    }

    // MARK: - trailingSpace

    // truncateBlankLines = true

    func testTrailingSpace() {
        let input = "foo  \nbar"
        let output = "foo\nbar"
        testFormatting(for: input, output, rule: .trailingSpace)
    }

    func testTrailingSpaceAtEndOfFile() {
        let input = "foo  "
        let output = "foo"
        testFormatting(for: input, output, rule: .trailingSpace)
    }

    func testTrailingSpaceInMultilineComments() {
        let input = "/* foo  \n bar  */"
        let output = "/* foo\n bar  */"
        testFormatting(for: input, output, rule: .trailingSpace)
    }

    func testTrailingSpaceInSingleLineComments() {
        let input = "// foo  \n// bar  "
        let output = "// foo\n// bar"
        testFormatting(for: input, output, rule: .trailingSpace)
    }

    func testTruncateBlankLine() {
        let input = "foo {\n    // bar\n    \n    // baz\n}"
        let output = "foo {\n    // bar\n\n    // baz\n}"
        testFormatting(for: input, output, rule: .trailingSpace)
    }

    func testTrailingSpaceInArray() {
        let input = "let foo = [\n    1,\n    \n    2,\n]"
        let output = "let foo = [\n    1,\n\n    2,\n]"
        testFormatting(for: input, output, rule: .trailingSpace, exclude: [.redundantSelf])
    }

    // truncateBlankLines = false

    func testNoTruncateBlankLine() {
        let input = "foo {\n    // bar\n    \n    // baz\n}"
        let options = FormatOptions(truncateBlankLines: false)
        testFormatting(for: input, rule: .trailingSpace, options: options)
    }

    // MARK: - emptyBraces

    func testLinebreaksRemovedInsideBraces() {
        let input = "func foo() {\n  \n }"
        let output = "func foo() {}"
        testFormatting(for: input, output, rule: .emptyBraces)
    }

    func testCommentNotRemovedInsideBraces() {
        let input = "func foo() { // foo\n}"
        testFormatting(for: input, rule: .emptyBraces)
    }

    func testEmptyBracesNotRemovedInDoCatch() {
        let input = """
        do {
        } catch is FooError {
        } catch {}
        """
        testFormatting(for: input, rule: .emptyBraces)
    }

    func testEmptyBracesNotRemovedInIfElse() {
        let input = """
        if bar {
        } else if foo {
        } else {}
        """
        testFormatting(for: input, rule: .emptyBraces)
    }

    func testSpaceRemovedInsideEmptybraces() {
        let input = "foo { }"
        let output = "foo {}"
        testFormatting(for: input, output, rule: .emptyBraces)
    }

    func testSpaceAddedInsideEmptyBracesWithSpacedConfiguration() {
        let input = "foo {}"
        let output = "foo { }"
        let options = FormatOptions(emptyBracesSpacing: .spaced)
        testFormatting(for: input, output, rule: .emptyBraces, options: options)
    }

    func testLinebreaksRemovedInsideBracesWithSpacedConfiguration() {
        let input = "func foo() {\n  \n }"
        let output = "func foo() { }"
        let options = FormatOptions(emptyBracesSpacing: .spaced)
        testFormatting(for: input, output, rule: .emptyBraces, options: options)
    }

    func testCommentNotRemovedInsideBracesWithSpacedConfiguration() {
        let input = "func foo() { // foo\n}"
        let options = FormatOptions(emptyBracesSpacing: .spaced)
        testFormatting(for: input, rule: .emptyBraces, options: options)
    }

    func testEmptyBracesSpaceNotRemovedInDoCatchWithSpacedConfiguration() {
        let input = """
        do {
        } catch is FooError {
        } catch { }
        """
        let options = FormatOptions(emptyBracesSpacing: .spaced)
        testFormatting(for: input, rule: .emptyBraces, options: options)
    }

    func testEmptyBracesSpaceNotRemovedInIfElseWithSpacedConfiguration() {
        let input = """
        if bar {
        } else if foo {
        } else { }
        """
        let options = FormatOptions(emptyBracesSpacing: .spaced)
        testFormatting(for: input, rule: .emptyBraces, options: options)
    }

    func testEmptyBracesLinebreakNotRemovedInIfElseWithLinebreakConfiguration() {
        let input = """
        if bar {
        } else if foo {
        } else {
        }
        """
        let options = FormatOptions(emptyBracesSpacing: .linebreak)
        testFormatting(for: input, rule: .emptyBraces, options: options)
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
        testFormatting(for: input, rule: .emptyBraces, options: options)
    }

    // MARK: - blankLineAfterSwitchCase

    func testAddsBlankLineAfterMultilineSwitchCases() {
        let input = """
        func handle(_ action: SpaceshipAction) {
            switch action {
            // The warp drive can be engaged by pressing a button on the control panel
            case .engageWarpDrive:
                navigationComputer.destination = targetedDestination
                await warpDrive.spinUp()
                warpDrive.activate()
            // Triggered automatically whenever we detect an energy blast was fired in our direction
            case .handleIncomingEnergyBlast:
                await energyShields.prepare()
                energyShields.engage()
            }
        }
        """

        let output = """
        func handle(_ action: SpaceshipAction) {
            switch action {
            // The warp drive can be engaged by pressing a button on the control panel
            case .engageWarpDrive:
                navigationComputer.destination = targetedDestination
                await warpDrive.spinUp()
                warpDrive.activate()

            // Triggered automatically whenever we detect an energy blast was fired in our direction
            case .handleIncomingEnergyBlast:
                await energyShields.prepare()
                energyShields.engage()
            }
        }
        """
        testFormatting(for: input, output, rule: .blankLineAfterSwitchCase)
    }

    func testRemovesBlankLineAfterLastSwitchCase() {
        let input = """
        func handle(_ action: SpaceshipAction) {
            switch action {
            case .engageWarpDrive:
                navigationComputer.destination = targetedDestination
                await warpDrive.spinUp()
                warpDrive.activate()

            case let .scanPlanet(planet):
                scanner.target = planet
                scanner.scanAtmosphere()
                scanner.scanBiosphere()
                scanner.scanForArticialLife()

            case .handleIncomingEnergyBlast:
                await energyShields.prepare()
                energyShields.engage()

            }
        }
        """

        let output = """
        func handle(_ action: SpaceshipAction) {
            switch action {
            case .engageWarpDrive:
                navigationComputer.destination = targetedDestination
                await warpDrive.spinUp()
                warpDrive.activate()

            case let .scanPlanet(planet):
                scanner.target = planet
                scanner.scanAtmosphere()
                scanner.scanBiosphere()
                scanner.scanForArticialLife()

            case .handleIncomingEnergyBlast:
                await energyShields.prepare()
                energyShields.engage()
            }
        }
        """
        testFormatting(for: input, output, rule: .blankLineAfterSwitchCase)
    }

    func testDoesntAddBlankLineAfterSingleLineSwitchCase() {
        let input = """
        var planetType: PlanetType {
            switch self {
            case .mercury, .venus, .earth, .mars:
                // The terrestrial planets are smaller and have a solid, rocky surface
                .terrestrial
            case .jupiter, .saturn, .uranus, .neptune:
                // The gas giants are huge and lack a solid surface
                .gasGiant
            }
        }

        var planetType: PlanetType {
            switch self {
            // The terrestrial planets are smaller and have a solid, rocky surface
            case .mercury, .venus, .earth, .mars:
                .terrestrial
            // The gas giants are huge and lack a solid surface
            case .jupiter, .saturn, .uranus, .neptune:
                .gasGiant
            }
        }

        var name: PlanetType {
            switch self {
            // The planet closest to the sun
            case .mercury:
                "Mercury"
            case .venus:
                "Venus"
            // The best planet, where everything cool happens
            case .earth:
                "Earth"
            // This planet is entirely inhabited by robots.
            // There are cool landers, rovers, and even a helicopter.
            case .mars:
                "Mars"
            case .jupiter:
                "Jupiter"
            case .saturn:
                // Other planets have rings, but satun's are the best.
                // It's rings are the only once that are usually visible in photos.
                "Saturn"
            case .uranus:
                /*
                 * The pronunciation of this planet's name is subject of scholarly debate
                 */
                "Uranus"
            case .neptune:
                "Neptune"
            }
        }
        """

        testFormatting(for: input, rule: .blankLineAfterSwitchCase, exclude: [.sortSwitchCases, .wrapSwitchCases, .blockComments])
    }

    func testMixedSingleLineAndMultiLineCases() {
        let input = """
        switch action {
        case .engageWarpDrive:
            navigationComputer.destination = targetedDestination
            await warpDrive.spinUp()
            warpDrive.activate()
        case .enableArtificialGravity:
            artificialGravityEngine.enable(strength: .oneG)
        case let .scanPlanet(planet):
            scanner.target = planet
            scanner.scanAtmosphere()
            scanner.scanBiosphere()
            scanner.scanForArtificialLife()
        case .handleIncomingEnergyBlast:
            energyShields.engage()
        }
        """

        let output = """
        switch action {
        case .engageWarpDrive:
            navigationComputer.destination = targetedDestination
            await warpDrive.spinUp()
            warpDrive.activate()

        case .enableArtificialGravity:
            artificialGravityEngine.enable(strength: .oneG)
        case let .scanPlanet(planet):
            scanner.target = planet
            scanner.scanAtmosphere()
            scanner.scanBiosphere()
            scanner.scanForArtificialLife()

        case .handleIncomingEnergyBlast:
            energyShields.engage()
        }
        """
        testFormatting(for: input, output, rule: .blankLineAfterSwitchCase, exclude: [.consistentSwitchCaseSpacing])
    }

    func testAllowsBlankLinesAfterSingleLineCases() {
        let input = """
        switch action {
        case .engageWarpDrive:
            warpDrive.engage()

        case .enableArtificialGravity:
            artificialGravityEngine.enable(strength: .oneG)

        case let .scanPlanet(planet):
            scanner.scan(planet)

        case .handleIncomingEnergyBlast:
            energyShields.engage()
        }
        """

        testFormatting(for: input, rule: .blankLineAfterSwitchCase)
    }

    // MARK: - consistentSwitchCaseSpacing

    func testInsertsBlankLinesToMakeSwitchStatementSpacingConsistent1() {
        let input = """
        switch action {
        case .engageWarpDrive:
            navigationComputer.destination = targetedDestination
            await warpDrive.spinUp()
            warpDrive.activate()

        case .enableArtificialGravity:
            artificialGravityEngine.enable(strength: .oneG)
        case let .scanPlanet(planet):
            scanner.target = planet
            scanner.scanAtmosphere()
            scanner.scanBiosphere()
            scanner.scanForArtificialLife()

        case .handleIncomingEnergyBlast:
            energyShields.engage()
        }
        """

        let output = """
        switch action {
        case .engageWarpDrive:
            navigationComputer.destination = targetedDestination
            await warpDrive.spinUp()
            warpDrive.activate()

        case .enableArtificialGravity:
            artificialGravityEngine.enable(strength: .oneG)

        case let .scanPlanet(planet):
            scanner.target = planet
            scanner.scanAtmosphere()
            scanner.scanBiosphere()
            scanner.scanForArtificialLife()

        case .handleIncomingEnergyBlast:
            energyShields.engage()
        }
        """
        testFormatting(for: input, output, rule: .consistentSwitchCaseSpacing)
    }

    func testInsertsBlankLinesToMakeSwitchStatementSpacingConsistent2() {
        let input = """
        switch action {
        case .engageWarpDrive:
            navigationComputer.destination = targetedDestination
            await warpDrive.spinUp()
            warpDrive.activate()

        case .enableArtificialGravity:
            artificialGravityEngine.enable(strength: .oneG)
        case .handleIncomingEnergyBlast:
            energyShields.engage()
        }
        """

        let output = """
        switch action {
        case .engageWarpDrive:
            navigationComputer.destination = targetedDestination
            await warpDrive.spinUp()
            warpDrive.activate()

        case .enableArtificialGravity:
            artificialGravityEngine.enable(strength: .oneG)

        case .handleIncomingEnergyBlast:
            energyShields.engage()
        }
        """
        testFormatting(for: input, output, rule: .consistentSwitchCaseSpacing)
    }

    func testInsertsBlankLinesToMakeSwitchStatementSpacingConsistent3() {
        let input = """
        var name: PlanetType {
            switch self {
            // The planet closest to the sun
            case .mercury:
                "Mercury"
            // Similar to Earth but way more deadly
            case .venus:
                "Venus"

            // The best planet, where everything cool happens
            case .earth:
                "Earth"

            // This planet is entirely inhabited by robots.
            // There are cool landers, rovers, and even a helicopter.
            case .mars:
                "Mars"

            // The biggest planet with the most moons
            case .jupiter:
                "Jupiter"

            // Other planets have rings, but satun's are the best.
            case .saturn:
                "Saturn"
            case .uranus:
                "Uranus"
            case .neptune:
                "Neptune"
            }
        }
        """

        let output = """
        var name: PlanetType {
            switch self {
            // The planet closest to the sun
            case .mercury:
                "Mercury"

            // Similar to Earth but way more deadly
            case .venus:
                "Venus"

            // The best planet, where everything cool happens
            case .earth:
                "Earth"

            // This planet is entirely inhabited by robots.
            // There are cool landers, rovers, and even a helicopter.
            case .mars:
                "Mars"

            // The biggest planet with the most moons
            case .jupiter:
                "Jupiter"

            // Other planets have rings, but satun's are the best.
            case .saturn:
                "Saturn"

            case .uranus:
                "Uranus"

            case .neptune:
                "Neptune"
            }
        }
        """
        testFormatting(for: input, output, rule: .consistentSwitchCaseSpacing)
    }

    func testRemovesBlankLinesToMakeSwitchStatementConsistent() {
        let input = """
        var name: PlanetType {
            switch self {
            // The planet closest to the sun
            case .mercury:
                "Mercury"

            case .venus:
                "Venus"
            // The best planet, where everything cool happens
            case .earth:
                "Earth"
            // This planet is entirely inhabited by robots.
            // There are cool landers, rovers, and even a helicopter.
            case .mars:
                "Mars"
            case .jupiter:
                "Jupiter"
            // Other planets have rings, but satun's are the best.
            case .saturn:
                "Saturn"
            case .uranus:
                "Uranus"
            case .neptune:
                "Neptune"
            }
        }
        """

        let output = """
        var name: PlanetType {
            switch self {
            // The planet closest to the sun
            case .mercury:
                "Mercury"
            case .venus:
                "Venus"
            // The best planet, where everything cool happens
            case .earth:
                "Earth"
            // This planet is entirely inhabited by robots.
            // There are cool landers, rovers, and even a helicopter.
            case .mars:
                "Mars"
            case .jupiter:
                "Jupiter"
            // Other planets have rings, but satun's are the best.
            case .saturn:
                "Saturn"
            case .uranus:
                "Uranus"
            case .neptune:
                "Neptune"
            }
        }
        """

        testFormatting(for: input, output, rule: .consistentSwitchCaseSpacing)
    }

    func testSingleLineAndMultiLineSwitchCase1() {
        let input = """
        switch planetType {
        case .terrestrial:
            if options.treatPlutoAsPlanet {
                [.mercury, .venus, .earth, .mars, .pluto]
            } else {
                [.mercury, .venus, .earth, .mars]
            }
        case .gasGiant:
            [.jupiter, .saturn, .uranus, .neptune]
        }
        """

        let output = """
        switch planetType {
        case .terrestrial:
            if options.treatPlutoAsPlanet {
                [.mercury, .venus, .earth, .mars, .pluto]
            } else {
                [.mercury, .venus, .earth, .mars]
            }

        case .gasGiant:
            [.jupiter, .saturn, .uranus, .neptune]
        }
        """

        testFormatting(for: input, [output], rules: [.blankLineAfterSwitchCase, .consistentSwitchCaseSpacing])
    }

    func testSingleLineAndMultiLineSwitchCase2() {
        let input = """
        switch planetType {
        case .gasGiant:
            [.jupiter, .saturn, .uranus, .neptune]
        case .terrestrial:
            if options.treatPlutoAsPlanet {
                [.mercury, .venus, .earth, .mars, .pluto]
            } else {
                [.mercury, .venus, .earth, .mars]
            }
        }
        """

        testFormatting(for: input, rule: .consistentSwitchCaseSpacing)
    }

    func testSwitchStatementWithSingleMultilineCase_blankLineAfterSwitchCaseEnabled() {
        let input = """
        switch action {
        case .enableArtificialGravity:
            artificialGravityEngine.enable(strength: .oneG)
        case .engageWarpDrive:
            navigationComputer.destination = targetedDestination
            await warpDrive.spinUp()
            warpDrive.activate()
        case let .scanPlanet(planet):
            scanner.scan(planet)
        case .handleIncomingEnergyBlast:
            energyShields.engage()
        }
        """

        let output = """
        switch action {
        case .enableArtificialGravity:
            artificialGravityEngine.enable(strength: .oneG)

        case .engageWarpDrive:
            navigationComputer.destination = targetedDestination
            await warpDrive.spinUp()
            warpDrive.activate()

        case let .scanPlanet(planet):
            scanner.scan(planet)

        case .handleIncomingEnergyBlast:
            energyShields.engage()
        }
        """

        testFormatting(for: input, [output], rules: [.consistentSwitchCaseSpacing, .blankLineAfterSwitchCase])
    }

    func testSwitchStatementWithSingleMultilineCase_blankLineAfterSwitchCaseDisabled() {
        let input = """
        switch action {
        case .enableArtificialGravity:
            artificialGravityEngine.enable(strength: .oneG)
        case .engageWarpDrive:
            navigationComputer.destination = targetedDestination
            await warpDrive.spinUp()
            warpDrive.activate()
        case let .scanPlanet(planet):
            scanner.scan(planet)
        case .handleIncomingEnergyBlast:
            energyShields.engage()
        }
        """

        testFormatting(for: input, rule: .consistentSwitchCaseSpacing, exclude: [.blankLineAfterSwitchCase])
    }
}
