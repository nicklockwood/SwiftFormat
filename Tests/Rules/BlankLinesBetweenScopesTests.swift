//
//  BlankLinesBetweenScopesTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 9/7/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class BlankLinesBetweenScopesTests: XCTestCase {
    func testBlankLineBetweenFunctions() {
        let input = """
        func foo() {
        }
        func bar() {
        }
        """
        let output = """
        func foo() {
        }

        func bar() {
        }
        """
        testFormatting(for: input, output, rule: .blankLinesBetweenScopes,
                       exclude: [.emptyBraces])
    }

    func testNoBlankLineBetweenPropertyAndFunction() {
        let input = """
        var foo: Int
        func bar() {
        }
        """
        testFormatting(for: input, rule: .blankLinesBetweenScopes, exclude: [.emptyBraces])
    }

    func testBlankLineBetweenFunctionsIsBeforeComment() {
        let input = """
        func foo() {
        }
        /// headerdoc
        func bar() {
        }
        """
        let output = """
        func foo() {
        }

        /// headerdoc
        func bar() {
        }
        """
        testFormatting(for: input, output, rule: .blankLinesBetweenScopes,
                       exclude: [.emptyBraces])
    }

    func testBlankLineBeforeAtObjcOnLineBeforeProtocol() {
        let input = """
        @objc
        protocol Foo {
        }
        @objc
        protocol Bar {
        }
        """
        let output = """
        @objc
        protocol Foo {
        }

        @objc
        protocol Bar {
        }
        """
        testFormatting(for: input, output, rule: .blankLinesBetweenScopes,
                       exclude: [.emptyBraces])
    }

    func testBlankLineBeforeAtAvailabilityOnLineBeforeClass() {
        let input = """
        protocol Foo {
        }
        @available(iOS 8.0, OSX 10.10, *)
        class Bar {
        }
        """
        let output = """
        protocol Foo {
        }

        @available(iOS 8.0, OSX 10.10, *)
        class Bar {
        }
        """
        testFormatting(for: input, output, rule: .blankLinesBetweenScopes,
                       exclude: [.emptyBraces])
    }

    func testNoExtraBlankLineBetweenFunctions() {
        let input = """
        func foo() {
        }

        func bar() {
        }
        """
        testFormatting(for: input, rule: .blankLinesBetweenScopes, exclude: [.emptyBraces])
    }

    func testNoBlankLineBetweenFunctionsInProtocol() {
        let input = """
        protocol Foo {
            func bar()
            func baz() -> Int
        }
        """
        testFormatting(for: input, rule: .blankLinesBetweenScopes)
    }

    func testNoBlankLineInsideInitFunction() {
        let input = """
        init() {
            super.init()
        }
        """
        testFormatting(for: input, rule: .blankLinesBetweenScopes)
    }

    func testBlankLineAfterProtocolBeforeProperty() {
        let input = """
        protocol Foo {
        }
        var bar: String
        """
        let output = """
        protocol Foo {
        }

        var bar: String
        """
        testFormatting(for: input, output, rule: .blankLinesBetweenScopes,
                       exclude: [.emptyBraces])
    }

    func testNoExtraBlankLineAfterSingleLineComment() {
        let input = """
        var foo: Bar? // comment

        func bar() {}
        """
        testFormatting(for: input, rule: .blankLinesBetweenScopes)
    }

    func testNoExtraBlankLineAfterMultilineComment() {
        let input = """
        var foo: Bar? /* comment */

        func bar() {}
        """
        testFormatting(for: input, rule: .blankLinesBetweenScopes)
    }

    func testNoBlankLineBeforeFuncAsIdentifier() {
        let input = """
        var foo: Bar?
        foo.func(x) {}
        """
        testFormatting(for: input, rule: .blankLinesBetweenScopes)
    }

    func testNoBlankLineBetweenFunctionsWithInlineBody() {
        let input = """
        class Foo {
            func foo() { print(\"foo\") }
            func bar() { print(\"bar\") }
        }
        """
        testFormatting(for: input, rule: .blankLinesBetweenScopes, exclude: [.wrapFunctionBodies, .wrapPropertyBodies])
    }

    func testNoBlankLineBetweenIfStatements() {
        let input = """
        func foo() {
            if x {
            }
            if y {
            }
        }
        """
        testFormatting(for: input, rule: .blankLinesBetweenScopes, exclude: [.emptyBraces])
    }

    func testNoBlanksInsideClassFunc() {
        let input = """
        class func foo {
            if x {
            }
            if y {
            }
        }
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: .blankLinesBetweenScopes, options: options,
                       exclude: [.emptyBraces])
    }

    func testNoBlanksInsideClassVar() {
        let input = """
        class var foo: Int {
            if x {
            }
            if y {
            }
        }
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: .blankLinesBetweenScopes, options: options,
                       exclude: [.emptyBraces])
    }

    func testBlankLineBetweenCalledClosures() {
        let input = """
        class Foo {
            var foo = {
            }()
            func bar {
            }
        }
        """
        let output = """
        class Foo {
            var foo = {
            }()

            func bar {
            }
        }
        """
        testFormatting(for: input, output, rule: .blankLinesBetweenScopes,
                       exclude: [.emptyBraces])
    }

    func testNoBlankLineAfterCalledClosureAtEndOfScope() {
        let input = """
        class Foo {
            var foo = {
            }()
        }
        """
        testFormatting(for: input, rule: .blankLinesBetweenScopes, exclude: [.emptyBraces])
    }

    func testNoBlankLineBeforeWhileInRepeatWhile() {
        let input = """
        repeat
        { print("foo") }
        while false
        { print("bar") }()
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, rule: .blankLinesBetweenScopes, options: options, exclude: [.redundantClosure, .wrapLoopBodies])
    }

    func testBlankLineBeforeWhileIfNotRepeatWhile() {
        let input = """
        func foo(x)
        {
        }
        while true
        {
        }
        """
        let output = """
        func foo(x)
        {
        }

        while true
        {
        }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, output, rule: .blankLinesBetweenScopes, options: options,
                       exclude: [.emptyBraces])
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
        testFormatting(for: input, rule: .blankLinesBetweenScopes,
                       exclude: [.emptyBraces])
    }

    func testNoInsertBlankLineAfterBraceBeforeSourceryComment() {
        let input = """
        struct Foo {
            var bar: String

            // sourcery:inline:Foo.init
            public init(bar: String) {
                self.bar = bar
            }
            // sourcery:end
        }
        """
        testFormatting(for: input, rule: .blankLinesBetweenScopes, exclude: [.redundantPublic, .redundantMemberwiseInit])
    }

    func testNoBlankLineBetweenChainedClosures() {
        let input = """
        foo {
            doFoo()
        }
        // bar
        .bar {
            doBar()
        }
        // baz
        .baz {
            doBaz($0)
        }
        """
        testFormatting(for: input, rule: .blankLinesBetweenScopes)
    }

    func testNoBlankLineBetweenTrailingClosures() {
        let input = """
        UIView.animate(withDuration: 0) {
            fromView.transform = .identity
        }
        completion: { finished in
            context.completeTransition(finished)
        }
        """
        testFormatting(for: input, rule: .blankLinesBetweenScopes)
    }

    func testBlankLineBetweenTrailingClosureAndLabelledLoop() {
        let input = """
        UIView.animate(withDuration: 0) {
            fromView.transform = .identity
        }
        completion: for foo in bar {
            print(foo)
        }
        """
        let output = """
        UIView.animate(withDuration: 0) {
            fromView.transform = .identity
        }

        completion: for foo in bar {
            print(foo)
        }
        """
        testFormatting(for: input, output, rule: .blankLinesBetweenScopes)
    }
}
