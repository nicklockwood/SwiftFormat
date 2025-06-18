//
//  BlankLinesBetweenScopesTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 9/7/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class BlankLinesBetweenScopesTests: XCTestCase {
    func testBlankLineBetweenFunctions() {
        let input = "func foo() {\n}\nfunc bar() {\n}"
        let output = "func foo() {\n}\n\nfunc bar() {\n}"
        testFormatting(for: input, output, rule: .blankLinesBetweenScopes,
                       exclude: [.emptyBraces])
    }

    func testNoBlankLineBetweenPropertyAndFunction() {
        let input = "var foo: Int\nfunc bar() {\n}"
        testFormatting(for: input, rule: .blankLinesBetweenScopes, exclude: [.emptyBraces])
    }

    func testBlankLineBetweenFunctionsIsBeforeComment() {
        let input = "func foo() {\n}\n/// headerdoc\nfunc bar() {\n}"
        let output = "func foo() {\n}\n\n/// headerdoc\nfunc bar() {\n}"
        testFormatting(for: input, output, rule: .blankLinesBetweenScopes,
                       exclude: [.emptyBraces])
    }

    func testBlankLineBeforeAtObjcOnLineBeforeProtocol() {
        let input = "@objc\nprotocol Foo {\n}\n@objc\nprotocol Bar {\n}"
        let output = "@objc\nprotocol Foo {\n}\n\n@objc\nprotocol Bar {\n}"
        testFormatting(for: input, output, rule: .blankLinesBetweenScopes,
                       exclude: [.emptyBraces])
    }

    func testBlankLineBeforeAtAvailabilityOnLineBeforeClass() {
        let input = "protocol Foo {\n}\n@available(iOS 8.0, OSX 10.10, *)\nclass Bar {\n}"
        let output = "protocol Foo {\n}\n\n@available(iOS 8.0, OSX 10.10, *)\nclass Bar {\n}"
        testFormatting(for: input, output, rule: .blankLinesBetweenScopes,
                       exclude: [.emptyBraces])
    }

    func testNoExtraBlankLineBetweenFunctions() {
        let input = "func foo() {\n}\n\nfunc bar() {\n}"
        testFormatting(for: input, rule: .blankLinesBetweenScopes, exclude: [.emptyBraces])
    }

    func testNoBlankLineBetweenFunctionsInProtocol() {
        let input = "protocol Foo {\n    func bar()\n    func baz() -> Int\n}"
        testFormatting(for: input, rule: .blankLinesBetweenScopes)
    }

    func testNoBlankLineInsideInitFunction() {
        let input = "init() {\n    super.init()\n}"
        testFormatting(for: input, rule: .blankLinesBetweenScopes)
    }

    func testBlankLineAfterProtocolBeforeProperty() {
        let input = "protocol Foo {\n}\nvar bar: String"
        let output = "protocol Foo {\n}\n\nvar bar: String"
        testFormatting(for: input, output, rule: .blankLinesBetweenScopes,
                       exclude: [.emptyBraces])
    }

    func testNoExtraBlankLineAfterSingleLineComment() {
        let input = "var foo: Bar? // comment\n\nfunc bar() {}"
        testFormatting(for: input, rule: .blankLinesBetweenScopes)
    }

    func testNoExtraBlankLineAfterMultilineComment() {
        let input = "var foo: Bar? /* comment */\n\nfunc bar() {}"
        testFormatting(for: input, rule: .blankLinesBetweenScopes)
    }

    func testNoBlankLineBeforeFuncAsIdentifier() {
        let input = "var foo: Bar?\nfoo.func(x) {}"
        testFormatting(for: input, rule: .blankLinesBetweenScopes)
    }

    func testNoBlankLineBetweenFunctionsWithInlineBody() {
        let input = "class Foo {\n    func foo() { print(\"foo\") }\n    func bar() { print(\"bar\") }\n}"
        testFormatting(for: input, rule: .blankLinesBetweenScopes)
    }

    func testNoBlankLineBetweenIfStatements() {
        let input = "func foo() {\n    if x {\n    }\n    if y {\n    }\n}"
        testFormatting(for: input, rule: .blankLinesBetweenScopes, exclude: [.emptyBraces])
    }

    func testNoBlanksInsideClassFunc() {
        let input = "class func foo {\n    if x {\n    }\n    if y {\n    }\n}"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: .blankLinesBetweenScopes, options: options,
                       exclude: [.emptyBraces])
    }

    func testNoBlanksInsideClassVar() {
        let input = "class var foo: Int {\n    if x {\n    }\n    if y {\n    }\n}"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: .blankLinesBetweenScopes, options: options,
                       exclude: [.emptyBraces])
    }

    func testBlankLineBetweenCalledClosures() {
        let input = "class Foo {\n    var foo = {\n    }()\n    func bar {\n    }\n}"
        let output = "class Foo {\n    var foo = {\n    }()\n\n    func bar {\n    }\n}"
        testFormatting(for: input, output, rule: .blankLinesBetweenScopes,
                       exclude: [.emptyBraces])
    }

    func testNoBlankLineAfterCalledClosureAtEndOfScope() {
        let input = "class Foo {\n    var foo = {\n    }()\n}"
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
        let input = "func foo(x)\n{\n}\nwhile true\n{\n}"
        let output = "func foo(x)\n{\n}\n\nwhile true\n{\n}"
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
