//
//  FormatterTests.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 30/08/2016.
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

import SwiftFormat
import XCTest

class FormatterTests: XCTestCase {
    func testRemoveCurrentTokenWhileEnumerating() {
        let input: [Token] = [
            .identifier("foo"),
            .identifier("bar"),
            .identifier("baz"),
        ]
        var output: [Token] = []
        let formatter = Formatter(input, options: .default)
        formatter.forEachToken { i, token in
            output.append(token)
            if i == 1 {
                formatter.removeToken(at: i)
            }
        }
        XCTAssertEqual(output, input)
    }

    func testRemovePreviousTokenWhileEnumerating() {
        let input: [Token] = [
            .identifier("foo"),
            .identifier("bar"),
            .identifier("baz"),
        ]
        var output: [Token] = []
        let formatter = Formatter(input, options: .default)
        formatter.forEachToken { i, token in
            output.append(token)
            if i == 1 {
                formatter.removeToken(at: i - 1)
            }
        }
        XCTAssertEqual(output, input)
    }

    func testRemoveNextTokenWhileEnumerating() {
        let input: [Token] = [
            .identifier("foo"),
            .identifier("bar"),
            .identifier("baz"),
        ]
        var output: [Token] = []
        let formatter = Formatter(input, options: .default)
        formatter.forEachToken { i, token in
            output.append(token)
            if i == 1 {
                formatter.removeToken(at: i + 1)
            }
        }
        XCTAssertEqual(output, [Token](input.dropLast()))
    }

    func testIndexBeforeComment() {
        let input: [Token] = [
            .identifier("foo"),
            .startOfScope("//"),
            .space(" "),
            .commentBody("bar"),
            .linebreak("\n", 1),
        ]
        let formatter = Formatter(input, options: .default)
        let index = formatter.index(before: 4, where: { !$0.isSpaceOrComment })
        XCTAssertEqual(index, 0)
    }

    func testIndexBeforeMultilineComment() {
        let input: [Token] = [
            .identifier("foo"),
            .startOfScope("/*"),
            .space(" "),
            .commentBody("bar"),
            .space(" "),
            .endOfScope("*/"),
            .linebreak("\n", 1),
        ]
        let formatter = Formatter(input, options: .default)
        let index = formatter.index(before: 6, where: { !$0.isSpaceOrComment })
        XCTAssertEqual(index, 0)
    }

    // MARK: enable/disable directives

    func testDisableRule() {
        let input = "//swiftformat:disable spaceAroundOperators\nlet foo : Int=5;"
        let output = "// swiftformat:disable spaceAroundOperators\nlet foo : Int=5\n"
        XCTAssertEqual(try format(input, rules: FormatRules.default), output)
    }

    func testDirectiveInMiddleOfComment() {
        let input = "//fixme: swiftformat:disable spaceAroundOperators - bug\nlet foo : Int=5;"
        let output = "// FIXME: swiftformat:disable spaceAroundOperators - bug\nlet foo : Int=5\n"
        XCTAssertEqual(try format(input, rules: FormatRules.default), output)
    }

    func testDisableAndReEnableRules() {
        let input = """
        // swiftformat:disable indent blankLinesBetweenScopes redundantSelf
        class Foo {
        let _foo = "foo"
        func foo() {
        print(self._foo)
        }
        }
        // swiftformat:enable indent redundantSelf
        class Bar {
        let _bar = "bar"
        func bar() {
        print(_bar)
        }
        }
        """
        let output = """
        // swiftformat:disable indent blankLinesBetweenScopes redundantSelf
        class Foo {
        let _foo = "foo"
        func foo() {
        print(self._foo)
        }
        }
        // swiftformat:enable indent redundantSelf
        class Bar {
            let _bar = "bar"
            func bar() {
                print(_bar)
            }
        }
        """
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testDisableAllRules() {
        let input = "//swiftformat:disable all\nlet foo : Int=5;"
        let output = "// swiftformat:disable all\nlet foo : Int=5;"
        XCTAssertEqual(try format(input, rules: FormatRules.default), output)
    }

    func testDisableAndReEnableAllRules() {
        let input = """
        // swiftformat:disable all
        class Foo {
        let _foo = "foo"
        func foo() {
        print(self._foo)
        }
        }
        // swiftformat:enable all
        class Bar {
        let _bar = "bar"
        func bar() {
        print(_bar)
        }
        }
        """
        let output = """
        // swiftformat:disable all
        class Foo {
        let _foo = "foo"
        func foo() {
        print(self._foo)
        }
        }
        // swiftformat:enable all
        class Bar {
            let _bar = "bar"
            func bar() {
                print(_bar)
            }
        }
        """
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testDisableAllRulesAndReEnableOneRule() {
        let input = "//swiftformat:disable all\nlet foo : Int=5;\n//swiftformat:enable linebreakAtEndOfFile"
        let output = "// swiftformat:disable all\nlet foo : Int=5;\n//swiftformat:enable linebreakAtEndOfFile\n"
        XCTAssertEqual(try format(input, rules: FormatRules.default), output)
    }

    func testDisableNext() {
        let input = "//swiftformat:disable:next all\nlet foo : Int=5;\nlet foo : Int=5;"
        let output = "// swiftformat:disable:next all\nlet foo : Int=5;\nlet foo: Int = 5\n"
        XCTAssertEqual(try format(input, rules: FormatRules.default), output)
    }

    func testEnableNext() {
        let input = "//swiftformat:disable all\n//swiftformat:enable:next all\nlet foo : Int=5;\nlet foo : Int=5;"
        let output = "// swiftformat:disable all\n//swiftformat:enable:next all\nlet foo: Int = 5\nlet foo : Int=5;"
        XCTAssertEqual(try format(input, rules: FormatRules.default), output)
    }

    func testDisableRuleWithMultilineComment() {
        let input = "/*swiftformat:disable spaceAroundOperators*/let foo : Int=5;"
        let output = "/* swiftformat:disable spaceAroundOperators */ let foo : Int=5\n"
        XCTAssertEqual(try format(input, rules: FormatRules.default), output)
    }

    func testDisableAllRulesWithMultilineComment() {
        let input = "/*swiftformat:disable all*/let foo : Int=5;"
        let output = "/*swiftformat:disable all*/let foo : Int=5;"
        XCTAssertEqual(try format(input, rules: FormatRules.default), output)
    }

    func testDisableNextWithMultilineComment() {
        let input = "/*swiftformat:disable:next all*/\nlet foo : Int=5;\nlet foo : Int=5;"
        let output = "/* swiftformat:disable:next all */\nlet foo : Int=5;\nlet foo: Int = 5\n"
        XCTAssertEqual(try format(input, rules: FormatRules.default), output)
    }

    func testEnableNextWithMultilineComment() {
        let input = "//swiftformat:disable all\n/*swiftformat:enable:next all*/\nlet foo : Int=5;\nlet foo : Int=5;"
        let output = "// swiftformat:disable all\n/*swiftformat:enable:next all*/\nlet foo: Int = 5\nlet foo : Int=5;"
        XCTAssertEqual(try format(input, rules: FormatRules.default), output)
    }

    func testDisableLinewrap() {
        let input = """
        // swiftformat:disable all
        let foo = bar.baz(some: param).quux("a string of some sort")
        """
        let options = FormatOptions(maxWidth: 10)
        XCTAssertEqual(try format(input, rules: FormatRules.default, options: options), input)
    }

    func testMalformedDirective() {
        let input = """
        // swiftformat:disbible all
        """
        XCTAssertThrowsError(try format(input, rules: FormatRules.default)) { error in
            XCTAssert("\(error)".contains("Unknown directive swiftformat:disbible"))
        }
    }

    // MARK: options directive

    func testAllmanOption() {
        let input = """
        // swiftformat:options --allman true
        func foo() {
            print("bar")
        }

        """
        let output = """
        // swiftformat:options --allman true
        func foo()
        {
            print("bar")
        }

        """
        XCTAssertEqual(try format(input, rules: FormatRules.default), output)
    }

    func testIndentNext() {
        let input = """
        class Foo {
            // swiftformat:options:next --indent 2
            func bar() {
                print("bar")
            }

            func baz() {
                print("bar")
            }
        }

        """
        let output = """
        class Foo {
            // swiftformat:options:next --indent 2
            func bar() {
              print("bar")
            }

            func baz() {
                print("bar")
            }
        }

        """
        XCTAssertEqual(try format(input, rules: FormatRules.default), output)
    }

    func testSwiftVersionNext() {
        let input = """
        // swiftformat:options:next --swiftversion 5.2
        let foo1 = bar.map { $0.foo }
        let foo2 = bar.map { $0.foo }

        """
        let output = """
        // swiftformat:options:next --swiftversion 5.2
        let foo1 = bar.map(\\.foo)
        let foo2 = bar.map { $0.foo }

        """
        XCTAssertEqual(try format(input, rules: FormatRules.default), output)
    }

    func testMalformedOption() {
        let input = """
        // swiftformat:options blooblahbleh
        """
        XCTAssertThrowsError(try format(input, rules: FormatRules.default)) { error in
            XCTAssert("\(error)".contains("Unknown option blooblahbleh"))
        }
    }

    func testInvalidOption() {
        let input = """
        // swiftformat:options --foobar baz
        """
        XCTAssertThrowsError(try format(input, rules: FormatRules.default)) { error in
            XCTAssert("\(error)".contains("Unknown option --foobar"))
        }
    }

    func testInvalidOptionValue() {
        let input = """
        // swiftformat:options --indent baz
        """
        XCTAssertThrowsError(try format(input, rules: FormatRules.default)) { error in
            XCTAssert("\(error)".contains("Unsupported --indent value"))
        }
    }

    func testDeprecatedOptionValue() {
        let input = """
        // swiftformat:options --ranges spaced
        """
        XCTAssertNoThrow(try format(input, rules: FormatRules.default))
    }

    // MARK: linebreaks

    func testLinebreakAfterLinebreakReturnsCorrectIndex() {
        let formatter = Formatter([
            .linebreak("\n", 1),
            .linebreak("\n", 1),
        ])
        XCTAssertEqual(formatter.linebreakToken(for: 1), .linebreak("\n", 1))
    }

    func testOriginalLinePreservedAfterFormatting() {
        let formatter = Formatter([
            .identifier("foo"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 1),
            .linebreak("\n", 2),
            .space("    "),
            .identifier("bar"),
            .linebreak("\n", 3),
            .endOfScope("}"),
        ])
        FormatRules.blankLinesAtStartOfScope.apply(with: formatter)
        XCTAssertEqual(formatter.tokens, [
            .identifier("foo"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 2),
            .space("    "),
            .identifier("bar"),
            .linebreak("\n", 3),
            .endOfScope("}"),
        ])
    }

    // MARK: range

    func testCodeOutsideRangeNotFormatted() throws {
        let input = tokenize("""
        func foo () {

            var  bar = 5
        }
        """)
        for range in [0 ..< 2, 5 ..< 7, 14 ..< 16, 17 ..< 19] {
            XCTAssertEqual(try format(input,
                                      rules: FormatRules.all,
                                      range: range), input)
        }
        let output1 = tokenize("""
        func foo () {

            var bar = 5
        }
        """)
        XCTAssertEqual(try format(
            input,
            rules: [FormatRules.consecutiveSpaces],
            range: 10 ..< 13
        ), output1)
        let output2 = """
        func foo () {
            var  bar = 5
        }
        """
        XCTAssertEqual(try sourceCode(for: format(
            input,
            rules: [FormatRules.blankLinesAtStartOfScope],
            range: 6 ..< 9
        )), output2)
    }

    // MARK: endOfScope

    func testEndOfScopeInSwitch() throws {
        let formatter = Formatter(tokenize("""
        switch foo {
        case bar: break
        }
        """))
        XCTAssertEqual(formatter.endOfScope(at: 4), 13)
    }

    // MARK: change tracking

    func testTrackChangesInFirstLine() {
        let formatter = Formatter(tokenize("foo bar\nbaz"), trackChanges: true)
        let tokens = formatter.tokens
        formatter.removeLastToken()
        XCTAssertNotEqual(formatter.tokens, tokens)
        XCTAssertEqual(formatter.changes.count, 1)
        XCTAssertEqual(formatter.changes.first?.line, 2)
    }

    func testTrackChangesInSecondLine() {
        let formatter = Formatter(tokenize("foo\nbar\nbaz"), trackChanges: true)
        let tokens = formatter.tokens
        formatter.removeToken(at: formatter.tokens.firstIndex(of: .identifier("bar"))!)
        XCTAssertNotEqual(formatter.tokens, tokens)
        XCTAssertEqual(formatter.changes.count, 1)
        XCTAssertEqual(formatter.changes.first?.line, 2)
    }

    func testTrackChangesInLastLine() {
        let formatter = Formatter(tokenize("foo\nbar\nbaz"), trackChanges: true)
        let tokens = formatter.tokens
        formatter.removeLastToken()
        XCTAssertNotEqual(formatter.tokens, tokens)
        XCTAssertEqual(formatter.changes.count, 1)
        XCTAssertEqual(formatter.changes.first?.line, 3)
    }

    func testTrackChangesInSingleLine() {
        let formatter = Formatter(tokenize("foo bar"), trackChanges: true)
        let tokens = formatter.tokens
        formatter.removeToken(at: 0)
        XCTAssertNotEqual(formatter.tokens, tokens)
        XCTAssertEqual(formatter.changes.count, 1)
    }

    func testTrackChangesIgnoresLinebreakIndex() {
        let formatter = Formatter(tokenize("\n\n"), trackChanges: true)
        var tokens = formatter.tokens
        tokens.insert(tokens.removeLast(), at: 0)
        XCTAssertNotEqual(formatter.tokens, tokens)
        formatter.replaceTokens(in: 0 ..< 2, with: tokens)
        XCTAssert(formatter.changes.isEmpty)
    }
}
