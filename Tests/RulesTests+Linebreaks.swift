//
//  RulesTests+Linebreaks.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 04/09/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

extension RulesTests {
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
        let input = """
        repeat
        { print("foo") }
        while false
        { print("bar") }()
        """
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
        testFormatting(for: input, rule: FormatRules.blankLinesBetweenScopes)
    }

    func testNoBlankLineBetweenChainedClosureIndents() {
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
        testFormatting(for: input, rule: FormatRules.blankLinesBetweenScopes)
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

    func testInsertBlankLinesJustBeforeMarkNotAfter() {
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
        let options = FormatOptions(lineAfterMarks: false)
        testFormatting(for: input, output, rule: FormatRules.blankLinesAroundMark, options: options)
    }

    func testNoInsertExtraBlankLinesAroundMarkWithNoBlankLineAfterMark() {
        let input = """
        let foo = "foo"

        // MARK: bar
        let bar = "bar"
        """
        let options = FormatOptions(lineAfterMarks: false)
        testFormatting(for: input, rule: FormatRules.blankLinesAroundMark, options: options)
    }

    func testNoInsertBlankLineAfterMarkAtStartOfFile() {
        let input = """
        // MARK: bar
        let bar = "bar"
        """
        let options = FormatOptions(lineAfterMarks: false)
        testFormatting(for: input, rule: FormatRules.blankLinesAroundMark, options: options)
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
}
