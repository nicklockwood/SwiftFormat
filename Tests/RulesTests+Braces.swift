//
//  RulesTests+Braces.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 04/09/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

extension RulesTests {
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
        testFormatting(for: input, rule: FormatRules.braces, exclude: ["redundantClosure"])
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

    func testKnRNoMangleClosureReturningClosure2() {
        let input = """
        foo {
            {
                bar()
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.braces)
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
        testFormatting(for: input, rule: FormatRules.braces, options: options)
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
        testFormatting(for: input, output, rule: FormatRules.braces)
    }

    func testKnRNoUnwrapClosureIfWidthExceeded() {
        let input = """
        let foo =
        { bar in
            bar()
        }
        """
        let options = FormatOptions(maxWidth: 15)
        testFormatting(for: input, rule: FormatRules.braces, options: options, exclude: ["indent"])
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
        testFormatting(
            for: input, output,
            rule: FormatRules.braces,
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
}
