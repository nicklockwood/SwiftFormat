//
//  RulesTests+Parens.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 04/09/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class ParensTests: RulesTests {
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
        let input = "x+(-5)"
        testFormatting(for: input, rule: FormatRules.redundantParens,
                       exclude: ["spaceAroundOperators"])
    }

    func testRedundantParensAroundIsNotRemoved() {
        let input = "a = (x is Int)"
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

    func testMeaningfulParensNotRemovedAroundOperator() {
        let input = "let foo: (Int, Int) -> Bool = (<)"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testMeaningfulParensNotRemovedAroundOperatorWithSpaces() {
        let input = "let foo: (Int, Int) -> Bool = ( < )"
        testFormatting(for: input, rule: FormatRules.redundantParens,
                       exclude: ["spaceAroundOperators", "spaceInsideParens"])
    }

    func testMeaningfulParensNotRemovedAroundPrefixOperator() {
        let input = "let foo: (Int) -> Int = ( -)"
        testFormatting(for: input, rule: FormatRules.redundantParens,
                       exclude: ["spaceAroundOperators", "spaceInsideParens"])
    }

    func testMeaningfulParensAroundPrefixExpressionFollowedByDotNotRemoved() {
        let input = "let foo = (!bar).description"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testMeaningfulParensAroundPrefixExpressionWithSpacesFollowedByDotNotRemoved() {
        let input = "let foo = ( !bar ).description"
        testFormatting(for: input, rule: FormatRules.redundantParens,
                       exclude: ["spaceAroundOperators", "spaceInsideParens"])
    }

    func testMeaningfulParensAroundPrefixExpressionFollowedByPostfixExpressionNotRemoved() {
        let input = "let foo = (!bar)!"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testMeaningfulParensAroundPrefixExpressionFollowedBySubscriptNotRemoved() {
        let input = "let foo = (!bar)[5]"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testRedundantParensAroundPostfixExpressionFollowedByPostfixOperatorRemoved() {
        let input = "let foo = (bar!)!"
        let output = "let foo = bar!!"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRedundantParensAroundPostfixExpressionFollowedByPostfixOperatorRemoved2() {
        let input = "let foo = ( bar! )!"
        let output = "let foo = bar!!"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRedundantParensAroundPostfixExpressionRemoved() {
        let input = "let foo = foo + (bar!)"
        let output = "let foo = foo + bar!"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRedundantParensAroundPostfixExpressionFollowedBySubscriptRemoved() {
        let input = "let foo = (bar!)[5]"
        let output = "let foo = bar![5]"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRedundantParensAroundPrefixExpressionRemoved() {
        let input = "let foo = foo + (!bar)"
        let output = "let foo = foo + !bar"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRedundantParensAroundInfixExpressionNotRemoved() {
        let input = "let foo = (foo + bar)"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testRedundantParensAroundInfixEqualsExpressionNotRemoved() {
        let input = "let foo = (bar == baz)"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testRedundantParensAroundClosureTypeRemoved() {
        let input = "typealias Foo = ((Int) -> Bool)"
        let output = "typealias Foo = (Int) -> Bool"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    // TODO: future enhancement
//    func testRedundantParensAroundClosureReturnTypeRemoved() {
//        let input = "typealias Foo = (Int) -> ((Int) -> Bool)"
//        let output = "typealias Foo = (Int) -> (Int) -> Bool"
//        testFormatting(for: input, output, rule: FormatRules.redundantParens)
//    }

    func testRedundantParensAroundNestedClosureTypesNotRemoved() {
        let input = "typealias Foo = (((Int) -> Bool) -> Int) -> ((String) -> Bool) -> Void"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testMeaningfulParensAroundClosureTypeNotRemoved() {
        let input = "let foo = ((Int) -> Bool)?"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testMeaningfulParensAroundTryExpressionNotRemoved() {
        let input = "let foo = (try? bar()) != nil"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testMeaningfulParensAroundAwaitExpressionNotRemoved() {
        let input = "if !(await isSomething()) {}"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testRedundantParensInReturnRemoved() {
        let input = "return (true)"
        let output = "return true"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRedundantParensInMultilineReturnRemovedCleanly() {
        let input = """
        return (
            foo
                .bar
        )
        """
        let output = """
        return
            foo
                .bar

        """
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
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

    func testGuardParensRemoved() {
        let input = "guard (x == y) else { return }"
        let output = "guard x == y else { return }"
        testFormatting(for: input, output, rule: FormatRules.redundantParens,
                       exclude: ["wrapConditionalBodies"])
    }

    func testForValueParensRemoved() {
        let input = "for (x) in (y) {}"
        let output = "for x in y {}"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testParensForLoopWhereClauseMethodNotRemoved() {
        let input = "for foo in foos where foo.method() { print(foo) }"
        testFormatting(for: input, rule: FormatRules.redundantParens, exclude: ["wrapLoopBodies"])
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

    // around function and closure arguments

    func testNestedClosureParensNotRemoved() {
        let input = "foo { _ in foo(y) {} }"
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

    func testOptionalFunctionCallResultNotUnwrapped() {
        let input = "bar = (foo?()).flatMap(Bar.init)"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testOptionalSubscriptResultNotUnwrapped() {
        let input = "bar = (foo?[0]).flatMap(Bar.init)"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testOptionalMemberResultNotUnwrapped() {
        let input = "bar = (foo?.baz).flatMap(Bar.init)"
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
        let output = "{ foo + bar }"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
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

    func testRequiredParensNotRemovedAroundOptionalRange() {
        let input = "let foo = (2...)?"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testRedundantParensRemovedAroundOptionalUnwrap() {
        let input = "let foo = (bar!)+5"
        testFormatting(for: input, rule: FormatRules.redundantParens,
                       exclude: ["spaceAroundOperators"])
    }

    func testRedundantParensRemovedAroundOptionalOptional() {
        let input = "let foo: (Int?)?"
        let output = "let foo: Int??"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRedundantParensRemovedAroundOptionalOptional2() {
        let input = "let foo: (Int!)?"
        let output = "let foo: Int!?"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRedundantParensRemovedAroundOptionalOptional3() {
        let input = "let foo: (Int?)!"
        let output = "let foo: Int?!"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRequiredParensNotRemovedAroundOptionalAnyType() {
        let input = "let foo: (any Foo)?"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testRequiredParensNotRemovedAroundAnyTypeSelf() {
        let input = "let foo = (any Foo).self"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testRequiredParensNotRemovedAroundAnyTypeType() {
        let input = "let foo: (any Foo).Type"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testRequiredParensNotRemovedAroundAnyComposedMetatype() {
        let input = "let foo: any (A & B).Type"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testRedundantParensRemovedAroundAnyType() {
        let input = "let foo: (any Foo)"
        let output = "let foo: any Foo"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testRedundantParensRemovedAroundAnyTypeInsideArray() {
        let input = "let foo: [(any Foo)]"
        let output = "let foo: [any Foo]"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testParensAroundParameterPackEachNotRemoved() {
        let input = "func f<each V>(_: repeat ((each V).Type, as: (each V) -> String)) {}"
        testFormatting(for: input, rule: FormatRules.redundantParens)
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
        testFormatting(for: input, rule: FormatRules.redundantParens, exclude: ["redundantClosure"])
    }

    // around closure arguments

    func testSingleClosureArgumentUnwrapped() {
        let input = "{ (foo) in }"
        let output = "{ foo in }"
        testFormatting(for: input, output, rule: FormatRules.redundantParens, exclude: ["unusedArguments"])
    }

    func testSingleMainActorClosureArgumentUnwrapped() {
        let input = "{ @MainActor (foo) in }"
        let output = "{ @MainActor foo in }"
        testFormatting(for: input, output, rule: FormatRules.redundantParens, exclude: ["unusedArguments"])
    }

    func testSingleClosureArgumentWithReturnValueUnwrapped() {
        let input = "{ (foo) -> Int in 5 }"
        let output = "{ foo -> Int in 5 }"
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

    func testNoRemoveParensAroundArrayInitializer() {
        let input = "let foo = bar { [Int](foo) }"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testNoRemoveParensAroundForIndexInsideClosure() {
        let input = """
        let foo = {
            for (i, token) in bar {}
        }()
        """
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testNoRemoveRequiredParensInsideClosure() {
        let input = "let foo = { _ in (a + b).c }"
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

    func testParensNotRemovedBeforeIfBody5() {
        let input = """
        if currentProducts != newProducts.map { $0.id }.sorted() {
            self?.products.accept(newProducts)
        }
        """
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
        testFormatting(for: input, rule: FormatRules.redundantParens, exclude: ["redundantClosure"])
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
        testFormatting(for: input, rule: FormatRules.redundantParens, exclude: ["propertyType"])
    }

    func testParensNotRemovedInGenericInstantiation2() {
        let input = "let foo = Foo<T>(bar)"
        testFormatting(for: input, rule: FormatRules.redundantParens, exclude: ["propertyType"])
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

    // inside string interpolation

    func testParensInStringNotRemoved() {
        let input = "\"hello \\(world)\""
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    // around ranges

    func testParensAroundRangeNotRemoved() {
        let input = "(1 ..< 10).reduce(0, combine: +)"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensRemovedAroundRangeArguments() {
        let input = "(a)...(b)"
        let output = "a...b"
        testFormatting(for: input, output, rule: FormatRules.redundantParens,
                       exclude: ["spaceAroundOperators"])
    }

    func testParensNotRemovedAroundRangeArgumentBeginningWithDot() {
        let input = "a...(.b)"
        testFormatting(for: input, rule: FormatRules.redundantParens,
                       exclude: ["spaceAroundOperators"])
    }

    func testParensNotRemovedAroundTrailingRangeFollowedByDot() {
        let input = "(a...).b"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testParensNotRemovedAroundRangeArgumentBeginningWithPrefixOperator() {
        let input = "a...(-b)"
        testFormatting(for: input, rule: FormatRules.redundantParens,
                       exclude: ["spaceAroundOperators"])
    }

    func testParensRemovedAroundRangeArgumentBeginningWithDot() {
        let input = "a ... (.b)"
        let output = "a ... .b"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    func testParensRemovedAroundRangeArgumentBeginningWithPrefixOperator() {
        let input = "a ... (-b)"
        let output = "a ... -b"
        testFormatting(for: input, output, rule: FormatRules.redundantParens)
    }

    // around ternaries

    func testParensNotRemovedAroundTernaryCondition() {
        let input = "let a = (b == c) ? d : e"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testRequiredParensNotRemovedAroundTernaryAssignment() {
        let input = "a ? (b = c) : (b = d)"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    // around parameter repeat each

    func testRequiredParensNotRemovedAroundRepeat() {
        let input = "(repeat (each foo, each bar))"
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    // in async expression

    func testRequiredParensNotRemovedInAsyncLet() {
        let input = """
        Task {
            async let dataTask1: Void = someTask(request)
            async let dataTask2: Void = someTask(request)
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }

    func testRequiredParensNotRemovedInAsyncLet2() {
        let input = """
        Task {
            let processURL: (URL) async throws -> Void = { _ in }
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantParens)
    }
}
