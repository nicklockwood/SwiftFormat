//
//  BracesTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class BracesTests: XCTestCase {
    func testAllmanBracesAreConverted() {
        let input = """
        func foo()
        {
            statement
        }
        """
        let output = """
        func foo() {
            statement
        }
        """
        testFormatting(for: input, output, rule: .braces)
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
        testFormatting(for: input, output, rule: .braces)
    }

    func testKnRBracesAfterComment() {
        let input = """
        func foo() // comment
        {
            statement
        }
        """
        testFormatting(for: input, rule: .braces)
    }

    func testKnRBracesAfterMultilineComment() {
        let input = """
        func foo() /* comment/ncomment */
        {
            statement
        }
        """
        testFormatting(for: input, rule: .braces)
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
        testFormatting(for: input, rule: .braces)
    }

    func testKnRExtraSpaceNotAddedBeforeBrace() {
        let input = """
        foo({ bar })
        """
        testFormatting(for: input, rule: .braces, exclude: [.trailingClosures])
    }

    func testKnRLinebreakNotRemovedBeforeInlineBlockNot() {
        let input = """
        func foo() -> Bool
        { return false }
        """
        testFormatting(for: input, rule: .braces)
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
        testFormatting(for: input, rule: .braces, exclude: [.redundantClosure])
    }

    func testKnRNoMangleClosureReturningClosure() {
        let input = """
        foo { bar in
            {
                bar()
            }
        }
        """
        testFormatting(for: input, rule: .braces)
    }

    func testKnRNoMangleClosureReturningClosure2() {
        let input = """
        foo {
            {
                bar()
            }
        }
        """
        testFormatting(for: input, rule: .braces)
    }

    func testAllmanNoMangleClosureReturningClosure() {
        let input = """
        foo
        { bar in
            {
                bar()
            }
        }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, rule: .braces, options: options)
    }

    func testKnRUnwrapClosure() {
        let input = """
        let foo =
        { bar in
            bar()
        }
        """
        let output = """
        let foo = { bar in
            bar()
        }
        """
        testFormatting(for: input, output, rule: .braces)
    }

    func testKnRNoUnwrapClosureIfWidthExceeded() {
        let input = """
        let foo =
        { bar in
            bar()
        }
        """
        let options = FormatOptions(maxWidth: 15)
        testFormatting(for: input, rule: .braces, options: options, exclude: [.indent])
    }

    func testKnRClosingBraceWrapped() {
        let input = """
        func foo() {
            print(bar) }
        """
        let output = """
        func foo() {
            print(bar)
        }
        """
        testFormatting(for: input, output, rule: .braces)
    }

    func testKnRInlineBracesNotWrapped() {
        let input = """
        func foo() { print(bar) }
        """
        testFormatting(for: input, rule: .braces)
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
        testFormatting(for: input, output, rule: .braces)
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
        testFormatting(for: input, output, rule: .braces)
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
        testFormatting(for: input, output, rule: .braces)
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
        testFormatting(for: input, output, rule: .braces)
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
        testFormatting(for: input, output, rule: .braces)
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
        testFormatting(for: input, output, rule: .braces)
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
        testFormatting(for: input, output, rule: .braces, exclude: [.emptyExtensions])
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
        testFormatting(for: input, output, rule: .braces)
    }

    func testBraceUnwrappedIfWrapMultilineStatementBracesRuleDisabled() {
        let input = """
        if let foo = bar,
           let baz = quux
        {
            return nil
        }
        """
        let output = """
        if let foo = bar,
           let baz = quux {
            return nil
        }
        """
        testFormatting(for: input, output, rule: .braces,
                       exclude: [.wrapMultilineStatementBraces])
    }

    func testBraceNotUnwrappedIfWrapMultilineStatementBracesRuleDisabled() {
        let input = """
        if let foo = bar,
           let baz = quux
        {
            return nil
        }
        """
        testFormatting(for: input, rules: [
            .braces, .wrapMultilineStatementBraces,
        ])
    }

    func testIssue1534() {
        let input = """
        func application(_: UIApplication, willFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool
        {
        //
        }
        """
        let output = """
        func application(_: UIApplication, willFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        //
        }
        """
        testFormatting(for: input, output, rule: .braces)
    }

    // allman style

    func testKnRBracesAreConverted() {
        let input = """
        func foo() {
            statement
        }
        """
        let output = """
        func foo()
        {
            statement
        }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: .braces, options: options)
    }

    func testAllmanBlankLineAfterBraceRemoved() {
        let input = """
        func foo() {

            statement
        }
        """
        let output = """
        func foo()
        {
            statement
        }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: .braces, options: options)
    }

    func testAllmanBraceInsideParensNotConverted() {
        let input = """
        foo({
            bar
        })
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, rule: .braces, options: options,
                       exclude: [.trailingClosures])
    }

    func testAllmanBraceDoClauseIndent() {
        let input = """
        do {
            foo
        }
        """
        let output = """
        do
        {
            foo
        }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: .braces, options: options)
    }

    func testAllmanBraceCatchClauseIndent() {
        let input = """
        do {
            try foo
        }
        catch {
        }
        """
        let output = """
        do
        {
            try foo
        }
        catch
        {
        }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: .braces, options: options,
                       exclude: [.emptyBraces])
    }

    func testAllmanBraceDoThrowsCatchClauseIndent() {
        let input = """
        do throws(Foo) {
            try foo
        }
        catch {
        }
        """
        let output = """
        do throws(Foo)
        {
            try foo
        }
        catch
        {
        }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: .braces, options: options,
                       exclude: [.emptyBraces])
    }

    func testAllmanBraceRepeatWhileIndent() {
        let input = """
        repeat {
            foo
        }
        while x
        """
        let output = """
        repeat
        {
            foo
        }
        while x
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: .braces, options: options)
    }

    func testAllmanBraceOptionalComputedPropertyIndent() {
        let input = """
        var foo: Int? {
            return 5
        }
        """
        let output = """
        var foo: Int?
        {
            return 5
        }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: .braces, options: options)
    }

    func testAllmanBraceThrowsFunctionIndent() {
        let input = """
        func foo() throws {
            bar
        }
        """
        let output = """
        func foo() throws
        {
            bar
        }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: .braces, options: options)
    }

    func testAllmanBraceAsyncFunctionIndent() {
        let input = """
        func foo() async {
            bar
        }
        """
        let output = """
        func foo() async
        {
            bar
        }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: .braces, options: options)
    }

    func testAllmanBraceAfterCommentIndent() {
        let input = """
        func foo() { // foo

            bar
        }
        """
        let output = """
        func foo()
        { // foo
            bar
        }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: .braces, options: options)
    }

    func testAllmanBraceAfterSwitch() {
        let input = """
        switch foo {
        case bar: break
        }
        """
        let output = """
        switch foo
        {
        case bar: break
        }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: .braces, options: options)
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
        testFormatting(
            for: input, output,
            rule: .braces,
            options: options
        )
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
        testFormatting(for: input, output, rule: .braces, options: options)
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
        testFormatting(for: input, output, rule: .braces, options: options)
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
        testFormatting(for: input, output, rule: .braces, options: options)
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
        testFormatting(for: input, output, rule: .braces, options: options)
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
        testFormatting(for: input, output, rule: .braces, options: options, exclude: [.emptyExtensions])
    }

    func testEmptyAllmanIfElseBraces() {
        let input = """
        if true {

        } else {

        }
        """
        let output = """
        if true
        {}
        else
        {}
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, [output], rules: [
            .braces, .emptyBraces, .elseOnSameLine,
        ], options: options)
    }

    func testTrailingClosureWrappingAfterSingleParamMethodCall() {
        let input = """
        func build() -> StateStore {
            StateStore(initial: State(
                foo: foo,
                bar: bar))
            {
                ActionHandler()
            }
        }
        """

        let options = FormatOptions(wrapArguments: .beforeFirst, closingParenPosition: .sameLine)
        testFormatting(for: input, rules: [.braces, .wrapMultilineStatementBraces], options: options)
    }

    func testTrailingClosureWrappingAfterMethodWithPartialWrappingAndClosures() {
        let input = """
        Picker("Language", selection: .init(
            get: { self.store.state.language },
            set: { self.store.handle(.setLanguage($0)) }))
        {
            Text("English").tag(Language.english)
            Text("German").tag(Language.german)
        }
        """

        let options = FormatOptions(wrapArguments: .beforeFirst, closingParenPosition: .sameLine)
        testFormatting(for: input, rules: [.braces, .wrapMultilineStatementBraces], options: options)
    }

    func testWrapInitBraceWithComplexWhereClause() {
        let input = """
        class Bar {
            init(
                foo: Foo
            ) where
                Foo: Fooable,
                Foo.Something == Something
            {
                self.foo = foo
            }
        }
        """
        testFormatting(for: input, rules: [.braces, .wrapMultilineStatementBraces])
    }
}
