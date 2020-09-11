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
    // MARK: - shared test infra

    func testFormatting(for input: String, _ output: String? = nil, rule: FormatRule,
                        options: FormatOptions = .default, exclude: [String] = [],
                        file: StaticString = #file, line: UInt = #line)
    {
        testFormatting(for: input, output.map { [$0] } ?? [], rules: [rule],
                       options: options, exclude: exclude, file: file, line: line)
    }

    func testFormatting(for input: String, _ outputs: [String] = [], rules: [FormatRule],
                        options: FormatOptions = .default, exclude: [String] = [],
                        file: StaticString = #file, line: UInt = #line)
    {
        // The `name` property on individual rules is not populated until the first call into `rulesByName`,
        // so we have to make sure to trigger this before checking the names of the given rules.
        if rules.contains(where: { $0.name.isEmpty }) {
            _ = FormatRules.all
        }

        precondition(input != outputs.first || input != outputs.last, "Redundant output parameter")
        precondition((0 ... 2).contains(outputs.count), "Only 0, 1 or 2 output parameters permitted")
        precondition(Set(exclude).intersection(rules.map { $0.name }).isEmpty, "Cannot exclude rule under test")
        let output = outputs.first ?? input, output2 = outputs.last ?? input
        let exclude = exclude
            + (rules.first?.name == "linebreakAtEndOfFile" ? [] : ["linebreakAtEndOfFile"])
            + (rules.first?.name == "organizeDeclarations" ? [] : ["organizeDeclarations"])
        XCTAssertEqual(try format(input, rules: rules, options: options), output, file: file, line: line)
        XCTAssertEqual(try format(input, rules: FormatRules.all(except: exclude), options: options),
                       output2, file: file, line: line)
        if input != output {
            XCTAssertEqual(try format(output, rules: rules, options: options),
                           output, file: file, line: line)
        }
        if input != output2, output != output2 {
            XCTAssertEqual(try format(output2, rules: FormatRules.all(except: exclude), options: options),
                           output2, file: file, line: line)
        }

        #if os(macOS)
            // These tests are flakey on Linux, and it's hard to debug
            XCTAssertEqual(try lint(output, rules: rules, options: options), [], file: file, line: line)
            XCTAssertEqual(try lint(output2, rules: FormatRules.all(except: exclude), options: options),
                           [], file: file, line: line)
        #endif
    }

    // MARK: - initCoderUnavailable

    func testInitCoderUnavailableEmptyFunction() {
        let input = """
        struct A: UIView {
            required init?(coder aDecoder: NSCoder) {}
        }
        """
        let output = """
        struct A: UIView {
            @available(*, unavailable)
            required init?(coder aDecoder: NSCoder) {}
        }
        """
        testFormatting(for: input, output, rule: FormatRules.initCoderUnavailable,
                       exclude: ["unusedArguments"])
    }

    func testInitCoderUnavailableFatalError() {
        let input = """
        extension Module {
            final class A: UIView {
                required init?(coder _: NSCoder) {
                    fatalError()
                }
            }
        }
        """
        let output = """
        extension Module {
            final class A: UIView {
                @available(*, unavailable)
                required init?(coder _: NSCoder) {
                    fatalError()
                }
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.initCoderUnavailable)
    }

    func testInitCoderUnavailableAlreadyPresent() {
        let input = """
        extension Module {
            final class A: UIView {
                @available(*, unavailable)
                required init?(coder _: NSCoder) {
                    fatalError()
                }
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.initCoderUnavailable)
    }

    func testInitCoderUnavailableImplemented() {
        let input = """
        extension Module {
            final class A: UIView {
                required init?(coder aCoder: NSCoder) {
                    aCoder.doSomething()
                }
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.initCoderUnavailable)
    }

    func testPublicInitCoderUnavailable() {
        let input = """
        class Foo: UIView {
            public required init?(coder _: NSCoder) {
                fatalError()
            }
        }
        """
        let output = """
        class Foo: UIView {
            @available(*, unavailable)
            public required init?(coder _: NSCoder) {
                fatalError()
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.initCoderUnavailable)
    }

    func testPublicInitCoderUnavailable2() {
        let input = """
        class Foo: UIView {
            required public init?(coder _: NSCoder) {
                fatalError()
            }
        }
        """
        let output = """
        class Foo: UIView {
            @available(*, unavailable)
            required public init?(coder _: NSCoder) {
                fatalError()
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.initCoderUnavailable,
                       exclude: ["modifierOrder", "specifiers"])
    }

    // MARK: - trailingCommas

    func testCommaAddedToSingleItem() {
        let input = "[\n    foo\n]"
        let output = "[\n    foo,\n]"
        testFormatting(for: input, output, rule: FormatRules.trailingCommas)
    }

    func testCommaAddedToLastItem() {
        let input = "[\n    foo,\n    bar\n]"
        let output = "[\n    foo,\n    bar,\n]"
        testFormatting(for: input, output, rule: FormatRules.trailingCommas)
    }

    func testCommaAddedToDictionary() {
        let input = "[\n    foo: bar\n]"
        let output = "[\n    foo: bar,\n]"
        testFormatting(for: input, output, rule: FormatRules.trailingCommas)
    }

    func testCommaNotAddedToInlineArray() {
        let input = "[foo, bar]"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testCommaNotAddedToInlineDictionary() {
        let input = "[foo: bar]"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testCommaNotAddedToSubscript() {
        let input = "foo[bar]"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testCommaAddedBeforeComment() {
        let input = "[\n    foo // comment\n]"
        let output = "[\n    foo, // comment\n]"
        testFormatting(for: input, output, rule: FormatRules.trailingCommas)
    }

    func testCommaNotAddedAfterComment() {
        let input = "[\n    foo, // comment\n]"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testCommaNotAddedInsideEmptyArrayLiteral() {
        let input = "foo = [\n]"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testCommaNotAddedInsideEmptyDictionaryLiteral() {
        let input = "foo = [:\n]"
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, rule: FormatRules.trailingCommas, options: options)
    }

    func testTrailingCommaRemovedInInlineArray() {
        let input = "[foo,]"
        let output = "[foo]"
        testFormatting(for: input, output, rule: FormatRules.trailingCommas)
    }

    func testTrailingCommaNotAddedToSubscript() {
        let input = "foo[\n    bar\n]"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testTrailingCommaNotAddedToSubscript2() {
        let input = "foo?[\n    bar\n]"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testTrailingCommaNotAddedToSubscript3() {
        let input = "foo()[\n    bar\n]"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testTrailingCommaNotAddedToTypeDeclaration() {
        let input = "var: [\n    Int:\n        String\n]"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testTrailingCommaNotAddedToTypeDeclaration2() {
        let input = "func foo(bar: [\n    Int:\n        String\n])"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testTrailingCommaNotAddedToTypeDeclaration3() {
        let input = """
        func foo() -> [
            String: String
        ]
        """
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    // trailingCommas = false

    func testCommaNotAddedToLastItem() {
        let input = "[\n    foo,\n    bar\n]"
        let options = FormatOptions(trailingCommas: false)
        testFormatting(for: input, rule: FormatRules.trailingCommas, options: options)
    }

    func testCommaRemovedFromLastItem() {
        let input = "[\n    foo,\n    bar,\n]"
        let output = "[\n    foo,\n    bar\n]"
        let options = FormatOptions(trailingCommas: false)
        testFormatting(for: input, output, rule: FormatRules.trailingCommas, options: options)
    }

    // MARK: - todos

    func testMarkIsUpdated() {
        let input = "// MARK foo"
        let output = "// MARK: foo"
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testTodoIsUpdated() {
        let input = "// TODO foo"
        let output = "// TODO: foo"
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testFixmeIsUpdated() {
        let input = "//    FIXME foo"
        let output = "//    FIXME: foo"
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testMarkWithColonSeparatedBySpace() {
        let input = "// MARK : foo"
        let output = "// MARK: foo"
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testMarkWithTripleSlash() {
        let input = "/// MARK: foo"
        let output = "// MARK: foo"
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testMarkWithNoSpaceAfterColon() {
        // NOTE: this was an unintended side-effect, but I like it
        let input = "// MARK:foo"
        let output = "// MARK: foo"
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testMarkInsideMultilineComment() {
        let input = "/* MARK foo */"
        let output = "/* MARK: foo */"
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testNoExtraSpaceAddedAfterTodo() {
        let input = "/* TODO: */"
        testFormatting(for: input, rule: FormatRules.todos)
    }

    func testLowercaseMarkColonIsUpdated() {
        let input = "// mark: foo"
        let output = "// MARK: foo"
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testMixedCaseMarkColonIsUpdated() {
        let input = "// Mark: foo"
        let output = "// MARK: foo"
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testLowercaseMarkIsNotUpdated() {
        let input = "// mark as read"
        testFormatting(for: input, rule: FormatRules.todos)
    }

    func testMixedCaseMarkIsNotUpdated() {
        let input = "// Mark as read"
        testFormatting(for: input, rule: FormatRules.todos)
    }

    func testLowercaseMarkDashIsUpdated() {
        let input = "// mark - foo"
        let output = "// MARK: - foo"
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testSpaceAddedBeforeMarkDash() {
        let input = "// MARK:- foo"
        let output = "// MARK: - foo"
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testSpaceAddedAfterMarkDash() {
        let input = "// MARK: -foo"
        let output = "// MARK: - foo"
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testSpaceAddedAroundMarkDash() {
        let input = "// MARK:-foo"
        let output = "// MARK: - foo"
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testSpaceNotAddedAfterMarkDashAtEndOfString() {
        let input = "// MARK: -"
        testFormatting(for: input, rule: FormatRules.todos)
    }

    // MARK: - modifierOrder

    func testVarModifiersCorrected() {
        let input = "unowned private static var foo"
        let output = "private unowned static var foo"
        testFormatting(for: input, output, rule: FormatRules.modifierOrder)
    }

    func testPrivateSetModifierNotMangled() {
        let input = "private(set) public weak lazy var foo"
        let output = "public private(set) lazy weak var foo"
        testFormatting(for: input, output, rule: FormatRules.modifierOrder)
    }

    func testPrivateRequiredStaticFuncModifiers() {
        let input = "required static private func foo()"
        let output = "private required static func foo()"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: FormatRules.modifierOrder, options: options)
    }

    func testPrivateConvenienceInit() {
        let input = "convenience private init()"
        let output = "private convenience init()"
        testFormatting(for: input, output, rule: FormatRules.modifierOrder)
    }

    func testSpaceInModifiersLeftIntact() {
        let input = "weak private(set) /* read-only */\npublic var"
        let output = "public private(set) /* read-only */\nweak var"
        testFormatting(for: input, output, rule: FormatRules.modifierOrder)
    }

    func testPrefixModifier() {
        let input = "prefix public static func - (rhs: Foo) -> Foo"
        let output = "public static prefix func - (rhs: Foo) -> Foo"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: FormatRules.modifierOrder, options: options)
    }

    func testModifierOrder() {
        let input = "override public var foo: Int { 5 }"
        let output = "public override var foo: Int { 5 }"
        let options = FormatOptions(modifierOrder: ["public", "override"])
        testFormatting(for: input, output, rule: FormatRules.modifierOrder, options: options)
    }

    func testNoConfusePostfixIdentifierWithKeyword() {
        let input = "var foo = .postfix\noverride init() {}"
        testFormatting(for: input, rule: FormatRules.modifierOrder)
    }

    func testNoConfusePostfixIdentifierWithKeyword2() {
        let input = "var foo = postfix\noverride init() {}"
        testFormatting(for: input, rule: FormatRules.modifierOrder)
    }

    func testNoConfuseCaseWithModifier() {
        let input = """
        enum Foo {
            case strong
            case weak
            public init() {}
        }
        """
        testFormatting(for: input, rule: FormatRules.modifierOrder)
    }

    // MARK: - void

    func testEmptyParensReturnValueConvertedToVoid() {
        let input = "() -> ()"
        let output = "() -> Void"
        testFormatting(for: input, output, rule: FormatRules.void)
    }

    func testSpacedParensReturnValueConvertedToVoid() {
        let input = "() -> ( \n)"
        let output = "() -> Void"
        testFormatting(for: input, output, rule: FormatRules.void)
    }

    func testParensContainingCommentNotConvertedToVoid() {
        let input = "() -> ( /* Hello World */ )"
        testFormatting(for: input, rule: FormatRules.void)
    }

    func testParensRemovedAroundVoid() {
        let input = "() -> (Void)"
        let output = "() -> Void"
        testFormatting(for: input, output, rule: FormatRules.void)
    }

    func testVoidArgumentConvertedToEmptyParens() {
        let input = "Void -> Void"
        let output = "() -> Void"
        testFormatting(for: input, output, rule: FormatRules.void)
    }

    func testVoidArgumentInParensNotConvertedToEmptyParens() {
        let input = "(Void) -> Void"
        testFormatting(for: input, rule: FormatRules.void)
    }

    func testAnonymousVoidArgumentNotConvertedToEmptyParens() {
        let input = "{ (_: Void) -> Void in }"
        testFormatting(for: input, rule: FormatRules.void)
    }

    func testFuncWithAnonymousVoidArgumentNotStripped() {
        let input = "func foo(_: Void) -> Void"
        testFormatting(for: input, rule: FormatRules.void)
    }

    func testFunctionThatReturnsAFunction() {
        let input = "(Void) -> Void -> ()"
        let output = "(Void) -> () -> Void"
        testFormatting(for: input, output, rule: FormatRules.void)
    }

    func testFunctionThatReturnsAFunctionThatThrows() {
        let input = "(Void) -> Void throws -> ()"
        let output = "(Void) -> () throws -> Void"
        testFormatting(for: input, output, rule: FormatRules.void)
    }

    func testChainOfFunctionsIsNotChanged() {
        let input = "() -> () -> () -> Void"
        testFormatting(for: input, rule: FormatRules.void)
    }

    func testChainOfFunctionsWithThrowsIsNotChanged() {
        let input = "() -> () throws -> () throws -> Void"
        testFormatting(for: input, rule: FormatRules.void)
    }

    func testVoidThrowsIsNotMangled() {
        let input = "(Void) throws -> Void"
        testFormatting(for: input, rule: FormatRules.void)
    }

    func testEmptyClosureArgsNotMangled() {
        let input = "{ () in }"
        testFormatting(for: input, rule: FormatRules.void)
    }

    func testEmptyClosureReturnValueConvertedToVoid() {
        let input = "{ () -> () in }"
        let output = "{ () -> Void in }"
        testFormatting(for: input, output, rule: FormatRules.void)
    }

    func testAnonymousVoidClosureNotChanged() {
        let input = "{ (_: Void) in }"
        testFormatting(for: input, rule: FormatRules.void, exclude: ["unusedArguments"])
    }

    func testVoidLiteralConvertedToParens() {
        let input = "foo(Void())"
        let output = "foo(())"
        testFormatting(for: input, output, rule: FormatRules.void)
    }

    func testVoidLiteralConvertedToParens2() {
        let input = "let foo = Void()"
        let output = "let foo = ()"
        testFormatting(for: input, output, rule: FormatRules.void)
    }

    func testVoidLiteralReturnValueConvertedToParens() {
        let input = """
        func foo() {
            return Void()
        }
        """
        let output = """
        func foo() {
            return ()
        }
        """
        testFormatting(for: input, output, rule: FormatRules.void)
    }

    func testVoidLiteralReturnValueConvertedToParens2() {
        let input = "{ _ in Void() }"
        let output = "{ _ in () }"
        testFormatting(for: input, output, rule: FormatRules.void)
    }

    func testNamespacedVoidLiteralNotConverted() {
        let input = "let foo = Swift.Void()"
        testFormatting(for: input, rule: FormatRules.void)
    }

    func testMalformedFuncDoesNotCauseInvalidOutput() throws {
        let input = "func baz(Void) {}"
        testFormatting(for: input, rule: FormatRules.void)
    }

    func testEmptyParensInGenericsConvertedToVoid() {
        let input = "Foo<(), ()>"
        let output = "Foo<Void, Void>"
        testFormatting(for: input, output, rule: FormatRules.void)
    }

    // useVoid = false

    func testUseVoidOptionFalse() {
        let input = "(Void) -> Void"
        let output = "(()) -> ()"
        let options = FormatOptions(useVoid: false)
        testFormatting(for: input, output, rule: FormatRules.void, options: options)
    }

    func testNamespacedVoidNotConverted() {
        let input = "() -> Swift.Void"
        let options = FormatOptions(useVoid: false)
        testFormatting(for: input, rule: FormatRules.void, options: options)
    }

    func testTypealiasVoidNotConverted() {
        let input = "public typealias Void = ()"
        let options = FormatOptions(useVoid: false)
        testFormatting(for: input, rule: FormatRules.void, options: options)
    }

    func testVoidClosureReturnValueConvertedToEmptyTuple() {
        let input = "{ () -> Void in }"
        let output = "{ () -> () in }"
        let options = FormatOptions(useVoid: false)
        testFormatting(for: input, output, rule: FormatRules.void, options: options)
    }

    // MARK: - trailingClosures

    func testAnonymousClosureArgumentMadeTrailing() {
        let input = "foo(foo: 5, { /* some code */ })"
        let output = "foo(foo: 5) { /* some code */ }"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    func testNamedClosureArgumentNotMadeTrailing() {
        let input = "foo(foo: 5, bar: { /* some code */ })"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testClosureArgumentPassedToFunctionInArgumentsNotMadeTrailing() {
        let input = "foo(bar { /* some code */ })"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testClosureArgumentInFunctionWithOtherClosureArgumentsNotMadeTrailing() {
        let input = "foo(foo: { /* some code */ }, { /* some code */ })"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testClosureArgumentInExpressionNotMadeTrailing() {
        let input = "if let foo = foo(foo: 5, { /* some code */ }) {}"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testClosureArgumentInCompoundExpressionNotMadeTrailing() {
        let input = "if let foo = foo(foo: 5, { /* some code */ }), let bar = bar(bar: 2, { /* some code */ }) {}"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testClosureArgumentAfterLinebreakInGuardNotMadeTrailing() {
        let input = "guard let foo =\n    bar({ /* some code */ })\nelse { return }"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testClosureMadeTrailingForNumericTupleMember() {
        let input = "foo.1(5, { bar })"
        let output = "foo.1(5) { bar }"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    func testNoRemoveParensAroundClosureFollowedByOpeningBrace() {
        let input = "foo({ bar }) { baz }"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    // solitary argument

    func testParensAroundSolitaryClosureArgumentRemoved() {
        let input = "foo({ /* some code */ })"
        let output = "foo { /* some code */ }"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    func testParensAroundNamedSolitaryClosureArgumentNotRemoved() {
        let input = "foo(foo: { /* some code */ })"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testParensAroundSolitaryClosureArgumentInExpressionNotRemoved() {
        let input = "if let foo = foo({ /* some code */ }) {}"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testParensAroundSolitaryClosureArgumentInCompoundExpressionNotRemoved() {
        let input = "if let foo = foo({ /* some code */ }), let bar = bar({ /* some code */ }) {}"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testParensAroundOptionalTrailingClosureInForLoopNotRemoved() {
        let input = "for foo in bar?.map({ $0.baz }) ?? [] {}"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testParensAroundTrailingClosureInGuardCaseLetNotRemoved() {
        let input = "guard case let .foo(bar) = baz.filter({ $0 == quux }).isEmpty else {}"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testParensAroundTrailingClosureInWhereClauseLetNotRemoved() {
        let input = "for foo in bar where baz.filter({ $0 == quux }).isEmpty {}"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testParensAroundTrailingClosureInSwitchNotRemoved() {
        let input = "switch foo({ $0 == bar }).count {}"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testSolitaryClosureMadeTrailingInChain() {
        let input = "foo.map({ $0.path }).joined()"
        let output = "foo.map { $0.path }.joined()"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    func testSpaceNotInsertedAfterClosureBeforeUnwrap() {
        let input = "let foo = bar.map({ foo($0) })?.baz"
        let output = "let foo = bar.map { foo($0) }?.baz"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    func testSpaceNotInsertedAfterClosureBeforeForceUnwrap() {
        let input = "let foo = bar.map({ foo($0) })!.baz"
        let output = "let foo = bar.map { foo($0) }!.baz"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    func testSolitaryClosureMadeTrailingForNumericTupleMember() {
        let input = "foo.1({ bar })"
        let output = "foo.1 { bar }"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    // dispatch methods

    func testDispatchAsyncClosureArgumentMadeTrailing() {
        let input = "queue.async(execute: { /* some code */ })"
        let output = "queue.async { /* some code */ }"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    func testDispatchAsyncGroupClosureArgumentMadeTrailing() {
        // TODO: async(group: , qos: , flags: , execute: )
        let input = "queue.async(group: g, execute: { /* some code */ })"
        let output = "queue.async(group: g) { /* some code */ }"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    func testDispatchAsyncAfterClosureArgumentMadeTrailing() {
        let input = "queue.asyncAfter(deadline: t, execute: { /* some code */ })"
        let output = "queue.asyncAfter(deadline: t) { /* some code */ }"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    func testDispatchAsyncAfterWallClosureArgumentMadeTrailing() {
        let input = "queue.asyncAfter(wallDeadline: t, execute: { /* some code */ })"
        let output = "queue.asyncAfter(wallDeadline: t) { /* some code */ }"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    func testDispatchSyncClosureArgumentMadeTrailing() {
        let input = "queue.sync(execute: { /* some code */ })"
        let output = "queue.sync { /* some code */ }"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    func testDispatchSyncFlagsClosureArgumentMadeTrailing() {
        let input = "queue.sync(flags: f, execute: { /* some code */ })"
        let output = "queue.sync(flags: f) { /* some code */ }"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    // autoreleasepool

    func testAutoreleasepoolMadeTrailing() {
        let input = "autoreleasepool(invoking: { /* some code */ })"
        let output = "autoreleasepool { /* some code */ }"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
    }

    // whitelisted methods

    func testCustomMethodMadeTrailing() {
        let input = "foo(bar: 1, baz: { /* some code */ })"
        let output = "foo(bar: 1) { /* some code */ }"
        let options = FormatOptions(trailingClosures: ["foo"])
        testFormatting(for: input, output, rule: FormatRules.trailingClosures, options: options)
    }

    // blacklisted methods

    func testPerformBatchUpdatesNotMadeTrailing() {
        let input = "collectionView.performBatchUpdates({ /* some code */ })"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    // multiple closures

    func testMultipleNestedClosures() throws {
        let repeatCount = 10
        let input = """
        override func foo() {
            bar {
                var baz = 5
        \(String(repeating: """
                fizz {
                    buzz {
                        fizzbuzz()
                    }
                }

        """, count: repeatCount))    }
        }
        """
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    // MARK: - unusedArguments

    // closures

    func testUnusedTypedClosureArguments() {
        let input = "let foo = { (bar: Int, baz: String) in\n    print(\"Hello \\(baz)\")\n}"
        let output = "let foo = { (_: Int, baz: String) in\n    print(\"Hello \\(baz)\")\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testUnusedUntypedClosureArguments() {
        let input = "let foo = { bar, baz in\n    print(\"Hello \\(baz)\")\n}"
        let output = "let foo = { _, baz in\n    print(\"Hello \\(baz)\")\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testNoRemoveClosureReturnType() {
        let input = "let foo = { () -> Foo.Bar in baz() }"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testNoRemoveClosureThrows() {
        let input = "let foo = { () throws in }"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testNoRemoveClosureGenericReturnTypes() {
        let input = "let foo = { () -> Promise<String> in bar }"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testNoRemoveClosureTupleReturnTypes() {
        let input = "let foo = { () -> (Int, Int) in (5, 6) }"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testNoRemoveClosureGenericArgumentTypes() {
        let input = "let foo = { (_: Foo<Bar, Baz>) in }"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testNoRemoveFunctionNameBeforeForLoop() {
        let input = "{\n    func foo() -> Int {}\n    for a in b {}\n}"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testClosureTypeInClosureArgumentsIsNotMangled() {
        let input = "{ (foo: (Int) -> Void) in }"
        let output = "{ (_: (Int) -> Void) in }"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testUnusedUnnamedClosureArguments() {
        let input = "{ (_ foo: Int, _ bar: Int) in }"
        let output = "{ (_: Int, _: Int) in }"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testUnusedInoutClosureArgumentsNotMangled() {
        let input = "{ (foo: inout Foo, bar: inout Bar) in }"
        let output = "{ (_: inout Foo, _: inout Bar) in }"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testMalformedFunctionNotMisidentifiedAsClosure() {
        let input = "func foo() { bar(5) {} in }"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    // functions

    func testMarkUnusedFunctionArgument() {
        let input = "func foo(bar: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        let output = "func foo(bar _: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testMarkUnusedArgumentsInNonVoidFunction() {
        let input = "func foo(bar: Int, baz: String) -> (A<B, C>, D & E, [F: G]) { return baz.quux }"
        let output = "func foo(bar _: Int, baz: String) -> (A<B, C>, D & E, [F: G]) { return baz.quux }"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testMarkUnusedArgumentsInThrowsFunction() {
        let input = "func foo(bar: Int, baz: String) throws {\n    print(\"Hello \\(baz)\")\n}"
        let output = "func foo(bar _: Int, baz: String) throws {\n    print(\"Hello \\(baz)\")\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testMarkUnusedArgumentsInOptionalReturningFunction() {
        let input = "func foo(bar: Int, baz: String) -> String? {\n    return \"Hello \\(baz)\"\n}"
        let output = "func foo(bar _: Int, baz: String) -> String? {\n    return \"Hello \\(baz)\"\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testNoMarkUnusedArgumentsInProtocolFunction() {
        let input = "protocol Foo {\n    func foo(bar: Int) -> Int\n    var bar: Int { get }\n}"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testUnusedUnnamedFunctionArgument() {
        let input = "func foo(_ foo: Int) {}"
        let output = "func foo(_: Int) {}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testUnusedInoutFunctionArgumentIsNotMangled() {
        let input = "func foo(_ foo: inout Foo) {}"
        let output = "func foo(_: inout Foo) {}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testUnusedInternallyRenamedFunctionArgument() {
        let input = "func foo(foo bar: Int) {}"
        let output = "func foo(foo _: Int) {}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testNoMarkProtocolFunctionArgument() {
        let input = "func foo(foo bar: Int)\nvar bar: Bool { get }"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testMembersAreNotArguments() {
        let input = "func foo(bar: Int, baz: String) {\n    print(\"Hello \\(bar.baz)\")\n}"
        let output = "func foo(bar: Int, baz _: String) {\n    print(\"Hello \\(bar.baz)\")\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testLabelsAreNotArguments() {
        let input = "func foo(bar: Int, baz: String) {\n    bar: while true { print(baz) }\n}"
        let output = "func foo(bar _: Int, baz: String) {\n    bar: while true { print(baz) }\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testDictionaryLiteralsRuinEverything() {
        let input = "func foo(bar: Int, baz: Int) {\n    let quux = [bar: 1, baz: 2]\n}"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testOperatorArgumentsAreUnnamed() {
        let input = "func == (lhs: Int, rhs: Int) { return false }"
        let output = "func == (_: Int, _: Int) { return false }"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testUnusedtFailableInitArgumentsAreNotMangled() {
        let input = "init?(foo: Bar) {}"
        let output = "init?(foo _: Bar) {}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testTreatEscapedArgumentsAsUsed() {
        let input = "func foo(default: Int) -> Int {\n    return `default`\n}"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testPartiallyMarkedUnusedArguments() {
        let input = "func foo(bar: Bar, baz _: Baz) {}"
        let output = "func foo(bar _: Bar, baz _: Baz) {}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testPartiallyMarkedUnusedArguments2() {
        let input = "func foo(bar _: Bar, baz: Baz) {}"
        let output = "func foo(bar _: Bar, baz _: Baz) {}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    // functions (closure-only)

    func testNoMarkFunctionArgument() {
        let input = "func foo(_ bar: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        let options = FormatOptions(stripUnusedArguments: .closureOnly)
        testFormatting(for: input, rule: FormatRules.unusedArguments, options: options)
    }

    // functions (unnamed-only)

    func testNoMarkNamedFunctionArgument() {
        let input = "func foo(bar: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        let options = FormatOptions(stripUnusedArguments: .unnamedOnly)
        testFormatting(for: input, rule: FormatRules.unusedArguments, options: options)
    }

    func testRemoveUnnamedFunctionArgument() {
        let input = "func foo(_ foo: Int) {}"
        let output = "func foo(_: Int) {}"
        let options = FormatOptions(stripUnusedArguments: .unnamedOnly)
        testFormatting(for: input, output, rule: FormatRules.unusedArguments, options: options)
    }

    func testNoRemoveInternalFunctionArgumentName() {
        let input = "func foo(foo bar: Int) {}"
        let options = FormatOptions(stripUnusedArguments: .unnamedOnly)
        testFormatting(for: input, rule: FormatRules.unusedArguments, options: options)
    }

    // init

    func testMarkUnusedInitArgument() {
        let input = "init(bar: Int, baz: String) {\n    self.baz = baz\n}"
        let output = "init(bar _: Int, baz: String) {\n    self.baz = baz\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    // subscript

    func testMarkUnusedSubscriptArgument() {
        let input = "subscript(foo: Int, baz: String) -> String {\n    return get(baz)\n}"
        let output = "subscript(_: Int, baz: String) -> String {\n    return get(baz)\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testMarkUnusedUnnamedSubscriptArgument() {
        let input = "subscript(_ foo: Int, baz: String) -> String {\n    return get(baz)\n}"
        let output = "subscript(_: Int, baz: String) -> String {\n    return get(baz)\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testMarkUnusedNamedSubscriptArgument() {
        let input = "subscript(foo foo: Int, baz: String) -> String {\n    return get(baz)\n}"
        let output = "subscript(foo _: Int, baz: String) -> String {\n    return get(baz)\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    // MARK: - hoistPatternLet

    // hoist = true

    func testHoistCaseLet() {
        let input = "if case .foo(let bar, let baz) = quux {}"
        let output = "if case let .foo(bar, baz) = quux {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testHoistLabelledCaseLet() {
        let input = "if case .foo(bar: let bar, baz: let baz) = quux {}"
        let output = "if case let .foo(bar: bar, baz: baz) = quux {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testHoistCaseVar() {
        let input = "if case .foo(var bar, var baz) = quux {}"
        let output = "if case var .foo(bar, baz) = quux {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testNoHoistMixedCaseLetVar() {
        let input = "if case .foo(let bar, var baz) = quux {}"
        testFormatting(for: input, rule: FormatRules.hoistPatternLet)
    }

    func testNoHoistIfFirstArgSpecified() {
        let input = "if case .foo(bar, let baz) = quux {}"
        testFormatting(for: input, rule: FormatRules.hoistPatternLet)
    }

    func testNoHoistIfLastArgSpecified() {
        let input = "if case .foo(let bar, baz) = quux {}"
        testFormatting(for: input, rule: FormatRules.hoistPatternLet)
    }

    func testHoistIfArgIsNumericLiteral() {
        let input = "if case .foo(5, let baz) = quux {}"
        let output = "if case let .foo(5, baz) = quux {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testHoistIfArgIsEnumCaseLiteral() {
        let input = "if case .foo(.bar, let baz) = quux {}"
        let output = "if case let .foo(.bar, baz) = quux {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testHoistIfArgIsNamespacedEnumCaseLiteralInParens() {
        let input = "switch foo {\ncase (Foo.bar(let baz)):\n}"
        let output = "switch foo {\ncase let (Foo.bar(baz)):\n}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, exclude: ["redundantParens"])
    }

    func testHoistIfFirstArgIsUnderscore() {
        let input = "if case .foo(_, let baz) = quux {}"
        let output = "if case let .foo(_, baz) = quux {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testHoistIfSecondArgIsUnderscore() {
        let input = "if case .foo(let baz, _) = quux {}"
        let output = "if case let .foo(baz, _) = quux {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testNestedHoistLet() {
        let input = "if case (.foo(let a, let b), .bar(let c, let d)) = quux {}"
        let output = "if case let (.foo(a, b), .bar(c, d)) = quux {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testHoistCommaSeparatedSwitchCaseLets() {
        let input = "switch foo {\ncase .foo(let bar), .bar(let bar):\n}"
        let output = "switch foo {\ncase let .foo(bar), let .bar(bar):\n}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet,
                       exclude: ["wrapSwitchCases"])
    }

    func testHoistCatchLet() {
        let input = "do {} catch Foo.foo(bar: let bar) {}"
        let output = "do {} catch let Foo.foo(bar: bar) {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testNoNestedHoistLetWithSpecifiedArgs() {
        let input = "if case (.foo(let a, b), .bar(let c, d)) = quux {}"
        testFormatting(for: input, rule: FormatRules.hoistPatternLet)
    }

    func testNoHoistClosureVariables() {
        let input = "foo({ let bar = 5 })"
        testFormatting(for: input, rule: FormatRules.hoistPatternLet, exclude: ["trailingClosures"])
    }

    // TODO: this could actually hoist out the let to the next level, but that's tricky
    // to implement without breaking the `testNoOverHoistSwitchCaseWithNestedParens` case
    func testHoistSwitchCaseWithNestedParens() {
        let input = "import Foo\nswitch (foo, bar) {\ncase (.baz(let quux), Foo.bar): break\n}"
        let output = "import Foo\nswitch (foo, bar) {\ncase (let .baz(quux), Foo.bar): break\n}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testNoOverHoistSwitchCaseWithNestedParens() {
        let input = "import Foo\nswitch (foo, bar) {\ncase (.baz(let quux), bar): break\n}"
        let output = "import Foo\nswitch (foo, bar) {\ncase (let .baz(quux), bar): break\n}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testNoHoistLetWithEmptArg() {
        let input = "if .foo(let _) = bar {}"
        testFormatting(for: input, rule: FormatRules.hoistPatternLet,
                       exclude: ["redundantLet", "redundantPattern"])
    }

    func testHoistLetWithNoSpaceAfterCase() {
        let input = "switch x { case.some(let y): return y }"
        let output = "switch x { case let .some(y): return y }"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    // hoist = false

    func testUnhoistCaseLet() {
        let input = "if case let .foo(bar, baz) = quux {}"
        let output = "if case .foo(let bar, let baz) = quux {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testUnhoistLabelledCaseLet() {
        let input = "if case let .foo(bar: bar, baz: baz) = quux {}"
        let output = "if case .foo(bar: let bar, baz: let baz) = quux {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testUnhoistCaseVar() {
        let input = "if case var .foo(bar, baz) = quux {}"
        let output = "if case .foo(var bar, var baz) = quux {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testUnhoistSingleCaseLet() {
        let input = "if case let .foo(bar) = quux {}"
        let output = "if case .foo(let bar) = quux {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testUnhoistIfArgIsEnumCaseLiteral() {
        let input = "if case let .foo(.bar, baz) = quux {}"
        let output = "if case .foo(.bar, let baz) = quux {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testUnhoistIfArgIsEnumCaseLiteralInParens() {
        let input = "switch foo {\ncase let (.bar(baz)):\n}"
        let output = "switch foo {\ncase (.bar(let baz)):\n}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options,
                       exclude: ["redundantParens"])
    }

    func testUnhoistIfArgIsNamespacedEnumCaseLiteral() {
        let input = "switch foo {\ncase let Foo.bar(baz):\n}"
        let output = "switch foo {\ncase Foo.bar(let baz):\n}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testUnhoistIfArgIsNamespacedEnumCaseLiteralInParens() {
        let input = "switch foo {\ncase let (Foo.bar(baz)):\n}"
        let output = "switch foo {\ncase (Foo.bar(let baz)):\n}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options,
                       exclude: ["redundantParens"])
    }

    func testUnhoistIfArgIsUnderscore() {
        let input = "if case let .foo(_, baz) = quux {}"
        let output = "if case .foo(_, let baz) = quux {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testNestedUnhoistLet() {
        let input = "if case let (.foo(a, b), .bar(c, d)) = quux {}"
        let output = "if case (.foo(let a, let b), .bar(let c, let d)) = quux {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testUnhoistCommaSeparatedSwitchCaseLets() {
        let input = "switch foo {\ncase let .foo(bar), let .bar(bar):\n}"
        let output = "switch foo {\ncase .foo(let bar), .bar(let bar):\n}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options,
                       exclude: ["wrapSwitchCases"])
    }

    func testUnhoistCommaSeparatedSwitchCaseLets2() {
        let input = "switch foo {\ncase let Foo.foo(bar), let Foo.bar(bar):\n}"
        let output = "switch foo {\ncase Foo.foo(let bar), Foo.bar(let bar):\n}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options,
                       exclude: ["wrapSwitchCases"])
    }

    func testUnhoistCatchLet() {
        let input = "do {} catch let Foo.foo(bar: bar) {}"
        let output = "do {} catch Foo.foo(bar: let bar) {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testNoUnhoistTupleLet() {
        let input = "let (bar, baz) = quux()"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testNoUnhoistIfLetTuple() {
        let input = "if let x = y, let (_, a) = z {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testNoUnhoistIfCaseFollowedByLetTuple() {
        let input = "if case .foo = bar, let (foo, bar) = baz {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testNoUnhoistIfArgIsNamespacedEnumCaseLiteralInParens() {
        let input = "switch foo {\ncase (Foo.bar(let baz)):\n}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: FormatRules.hoistPatternLet, options: options,
                       exclude: ["redundantParens"])
    }

    // MARK: - numberFormatting

    // hex case

    func testLowercaseLiteralConvertedToUpper() {
        let input = "let foo = 0xabcd"
        let output = "let foo = 0xABCD"
        testFormatting(for: input, output, rule: FormatRules.numberFormatting)
    }

    func testMixedCaseLiteralConvertedToUpper() {
        let input = "let foo = 0xaBcD"
        let output = "let foo = 0xABCD"
        testFormatting(for: input, output, rule: FormatRules.numberFormatting)
    }

    func testUppercaseLiteralConvertedToLower() {
        let input = "let foo = 0xABCD"
        let output = "let foo = 0xabcd"
        let options = FormatOptions(uppercaseHex: false)
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    func testPInExponentialNotConvertedToUpper() {
        let input = "let foo = 0xaBcDp5"
        let output = "let foo = 0xABCDp5"
        testFormatting(for: input, output, rule: FormatRules.numberFormatting)
    }

    func testPInExponentialNotConvertedToLower() {
        let input = "let foo = 0xaBcDP5"
        let output = "let foo = 0xabcdP5"
        let options = FormatOptions(uppercaseHex: false, uppercaseExponent: true)
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    // exponent case

    func testLowercaseExponent() {
        let input = "let foo = 0.456E-5"
        let output = "let foo = 0.456e-5"
        testFormatting(for: input, output, rule: FormatRules.numberFormatting)
    }

    func testUppercaseExponent() {
        let input = "let foo = 0.456e-5"
        let output = "let foo = 0.456E-5"
        let options = FormatOptions(uppercaseExponent: true)
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    func testUppercaseHexExponent() {
        let input = "let foo = 0xFF00p54"
        let output = "let foo = 0xFF00P54"
        let options = FormatOptions(uppercaseExponent: true)
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    func testUppercaseGroupedHexExponent() {
        let input = "let foo = 0xFF00_AABB_CCDDp54"
        let output = "let foo = 0xFF00_AABB_CCDDP54"
        let options = FormatOptions(uppercaseExponent: true)
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    // decimal grouping

    func testDefaultDecimalGrouping() {
        let input = "let foo = 1234_56_78"
        let output = "let foo = 12_345_678"
        testFormatting(for: input, output, rule: FormatRules.numberFormatting)
    }

    func testIgnoreDecimalGrouping() {
        let input = "let foo = 1234_5_678"
        let options = FormatOptions(decimalGrouping: .ignore)
        testFormatting(for: input, rule: FormatRules.numberFormatting, options: options)
    }

    func testNoDecimalGrouping() {
        let input = "let foo = 1234_5_678"
        let output = "let foo = 12345678"
        let options = FormatOptions(decimalGrouping: .none)
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    func testDecimalGroupingThousands() {
        let input = "let foo = 1234"
        let output = "let foo = 1_234"
        let options = FormatOptions(decimalGrouping: .group(3, 3))
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    func testExponentialGrouping() {
        let input = "let foo = 1234e5678"
        let output = "let foo = 1_234e5678"
        let options = FormatOptions(decimalGrouping: .group(3, 3))
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    func testZeroGrouping() {
        let input = "let foo = 1234"
        let options = FormatOptions(decimalGrouping: .group(0, 0))
        testFormatting(for: input, rule: FormatRules.numberFormatting, options: options)
    }

    // binary grouping

    func testDefaultBinaryGrouping() {
        let input = "let foo = 0b11101000_00111111"
        let output = "let foo = 0b1110_1000_0011_1111"
        testFormatting(for: input, output, rule: FormatRules.numberFormatting)
    }

    func testIgnoreBinaryGrouping() {
        let input = "let foo = 0b1110_10_00"
        let options = FormatOptions(binaryGrouping: .ignore)
        testFormatting(for: input, rule: FormatRules.numberFormatting, options: options)
    }

    func testNoBinaryGrouping() {
        let input = "let foo = 0b1110_10_00"
        let output = "let foo = 0b11101000"
        let options = FormatOptions(binaryGrouping: .none)
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    func testBinaryGroupingCustom() {
        let input = "let foo = 0b110011"
        let output = "let foo = 0b11_00_11"
        let options = FormatOptions(binaryGrouping: .group(2, 2))
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    // hex grouping

    func testDefaultHexGrouping() {
        let input = "let foo = 0xFF01FF01AE45"
        let output = "let foo = 0xFF01_FF01_AE45"
        testFormatting(for: input, output, rule: FormatRules.numberFormatting)
    }

    func testCustomHexGrouping() {
        let input = "let foo = 0xFF00p54"
        let output = "let foo = 0xFF_00p54"
        let options = FormatOptions(hexGrouping: .group(2, 2))
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    // octal grouping

    func testDefaultOctalGrouping() {
        let input = "let foo = 0o123456701234"
        let output = "let foo = 0o1234_5670_1234"
        testFormatting(for: input, output, rule: FormatRules.numberFormatting)
    }

    func testCustomOctalGrouping() {
        let input = "let foo = 0o12345670"
        let output = "let foo = 0o12_34_56_70"
        let options = FormatOptions(octalGrouping: .group(2, 2))
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    // fraction grouping

    func testIgnoreFractionGrouping() {
        let input = "let foo = 1.234_5_678"
        let options = FormatOptions(decimalGrouping: .ignore, fractionGrouping: true)
        testFormatting(for: input, rule: FormatRules.numberFormatting, options: options)
    }

    func testNoFractionGrouping() {
        let input = "let foo = 1.234_5_678"
        let output = "let foo = 1.2345678"
        let options = FormatOptions(decimalGrouping: .none, fractionGrouping: true)
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    func testFractionGroupingThousands() {
        let input = "let foo = 12.34_56_78"
        let output = "let foo = 12.345_678"
        let options = FormatOptions(decimalGrouping: .group(3, 3), fractionGrouping: true)
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    func testHexFractionGrouping() {
        let input = "let foo = 0x12.34_56_78p56"
        let output = "let foo = 0x12.34_5678p56"
        let options = FormatOptions(hexGrouping: .group(4, 4), fractionGrouping: true)
        testFormatting(for: input, output, rule: FormatRules.numberFormatting, options: options)
    }

    // MARK: - fileHeader

    func testStripHeader() {
        let input = "//\n//  test.swift\n//  SwiftFormat\n//\n//  Created by Nick Lockwood on 08/11/2016.\n//  Copyright © 2016 Nick Lockwood. All rights reserved.\n//\n\n// func\nfunc foo() {}"
        let output = "// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testMultilineCommentHeader() {
        let input = "/****************************/\n/* Created by Nick Lockwood */\n/****************************/\n\n\n// func\nfunc foo() {}"
        let output = "// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testNoStripHeaderWhenDisabled() {
        let input = "//\n//  test.swift\n//  SwiftFormat\n//\n//  Created by Nick Lockwood on 08/11/2016.\n//  Copyright © 2016 Nick Lockwood. All rights reserved.\n//\n\n// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: .ignore)
        testFormatting(for: input, rule: FormatRules.fileHeader, options: options)
    }

    func testNoStripComment() {
        let input = "\n// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: FormatRules.fileHeader, options: options)
    }

    func testNoStripPackageHeader() {
        let input = "// swift-tools-version:4.2\n\nimport PackageDescription"
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: FormatRules.fileHeader, options: options)
    }

    func testNoStripFormatDirective() {
        let input = "// swiftformat:options --swiftversion 5.2\n\nimport PackageDescription"
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: FormatRules.fileHeader, options: options)
    }

    func testNoStripFormatDirectiveAfterHeader() {
        let input = "// header\n// swiftformat:options --swiftversion 5.2\n\nimport PackageDescription"
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: FormatRules.fileHeader, options: options)
    }

    func testNoReplaceFormatDirective() {
        let input = "// swiftformat:options --swiftversion 5.2\n\nimport PackageDescription"
        let output = "// Hello World\n\n// swiftformat:options --swiftversion 5.2\n\nimport PackageDescription"
        let options = FormatOptions(fileHeader: "// Hello World")
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testSetSingleLineHeader() {
        let input = "//\n//  test.swift\n//  SwiftFormat\n//\n//  Created by Nick Lockwood on 08/11/2016.\n//  Copyright © 2016 Nick Lockwood. All rights reserved.\n//\n\n// func\nfunc foo() {}"
        let output = "// Hello World\n\n// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "// Hello World")
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testSetMultilineHeader() {
        let input = "//\n//  test.swift\n//  SwiftFormat\n//\n//  Created by Nick Lockwood on 08/11/2016.\n//  Copyright © 2016 Nick Lockwood. All rights reserved.\n//\n\n// func\nfunc foo() {}"
        let output = "// Hello\n// World\n\n// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "// Hello\n// World")
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testSetMultilineHeaderWithMarkup() {
        let input = "//\n//  test.swift\n//  SwiftFormat\n//\n//  Created by Nick Lockwood on 08/11/2016.\n//  Copyright © 2016 Nick Lockwood. All rights reserved.\n//\n\n// func\nfunc foo() {}"
        let output = "/*--- Hello ---*/\n/*--- World ---*/\n\n// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "/*--- Hello ---*/\n/*--- World ---*/")
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testNoStripHeaderIfRuleDisabled() {
        let input = "// swiftformat:disable fileHeader\n// test\n// swiftformat:enable fileHeader\n\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: FormatRules.fileHeader, options: options)
    }

    func testNoStripHeaderIfNextRuleDisabled() {
        let input = "// swiftformat:disable:next fileHeader\n// test\n\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: FormatRules.fileHeader, options: options)
    }

    func testNoStripHeaderDocWithNewlineBeforeCode() {
        let input = "/// Header doc\n\nclass Foo {}"
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: FormatRules.fileHeader, options: options)
    }

    func testNoDuplicateHeaderIfMissingTrailingBlankLine() {
        let input = "// Header comment\nclass Foo {}"
        let output = "// Header comment\n\nclass Foo {}"
        let options = FormatOptions(fileHeader: "Header comment")
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testFileHeaderYearReplacement() {
        let input = "let foo = bar"
        let output: String = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return "// Copyright © \(formatter.string(from: Date()))\n\nlet foo = bar"
        }()
        let options = FormatOptions(fileHeader: "// Copyright © {year}")
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
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
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
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
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testFileHeaderRuleThrowsIfCreationDateUnavailable() {
        let input = "let foo = bar"
        let options = FormatOptions(fileHeader: "// Created by Nick Lockwood on {created}.", fileInfo: FileInfo())
        XCTAssertThrowsError(try format(input, rules: [FormatRules.fileHeader], options: options))
    }

    func testFileHeaderFileReplacement() {
        let input = "let foo = bar"
        let output = "// MyFile.swift\n\nlet foo = bar"
        let fileInfo = FileInfo(filePath: "~/MyFile.swift")
        let options = FormatOptions(fileHeader: "// {file}", fileInfo: fileInfo)
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testFileHeaderRuleThrowsIfFileNameUnavailable() {
        let input = "let foo = bar"
        let options = FormatOptions(fileHeader: "// {file}.", fileInfo: FileInfo())
        XCTAssertThrowsError(try format(input, rules: [FormatRules.fileHeader], options: options))
    }

    // MARK: - sortedImports

    func testSortedImportsSimpleCase() {
        let input = "import Foo\nimport Bar"
        let output = "import Bar\nimport Foo"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testSortedImportsKeepsPreviousCommentWithImport() {
        let input = "import Foo\n// important comment\n// (very important)\nimport Bar"
        let output = "// important comment\n// (very important)\nimport Bar\nimport Foo"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testSortedImportsKeepsPreviousCommentWithImport2() {
        let input = "// important comment\n// (very important)\nimport Foo\nimport Bar"
        let output = "import Bar\n// important comment\n// (very important)\nimport Foo"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testSortedImportsDoesntMoveHeaderComment() {
        let input = "// header comment\n\nimport Foo\nimport Bar"
        let output = "// header comment\n\nimport Bar\nimport Foo"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testSortedImportsDoesntMoveHeaderCommentFollowedByImportComment() {
        let input = "// header comment\n\n// important comment\nimport Foo\nimport Bar"
        let output = "// header comment\n\nimport Bar\n// important comment\nimport Foo"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testSortedImportsOnSameLine() {
        let input = "import Foo; import Bar\nimport Baz"
        let output = "import Baz\nimport Foo; import Bar"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testSortedImportsWithSemicolonAndCommentOnSameLine() {
        let input = "import Foo; // foobar\nimport Bar\nimport Baz"
        let output = "import Bar\nimport Baz\nimport Foo; // foobar"
        testFormatting(for: input, output, rule: FormatRules.sortedImports, exclude: ["semicolons"])
    }

    func testSortedImportEnum() {
        let input = "import enum Foo.baz\nimport Foo.bar"
        let output = "import Foo.bar\nimport enum Foo.baz"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testSortedImportFunc() {
        let input = "import func Foo.baz\nimport Foo.bar"
        let output = "import Foo.bar\nimport func Foo.baz"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testAlreadySortedImportsDoesNothing() {
        let input = "import Bar\nimport Foo"
        testFormatting(for: input, rule: FormatRules.sortedImports)
    }

    func testPreprocessorSortedImports() {
        let input = "#if os(iOS)\n    import Foo2\n    import Bar2\n#else\n    import Foo1\n    import Bar1\n#endif\nimport Foo3\nimport Bar3"
        let output = "#if os(iOS)\n    import Bar2\n    import Foo2\n#else\n    import Bar1\n    import Foo1\n#endif\nimport Bar3\nimport Foo3"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testTestableSortedImports() {
        let input = "@testable import Foo3\nimport Bar3"
        let output = "import Bar3\n@testable import Foo3"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testTestableImportsWithTestableOnPreviousLine() {
        let input = "@testable\nimport Foo3\nimport Bar3"
        let output = "import Bar3\n@testable\nimport Foo3"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testTestableImportsWithGroupingTestableBottom() {
        let input = "@testable import Bar\nimport Foo\n@testable import UIKit"
        let output = "import Foo\n@testable import Bar\n@testable import UIKit"
        let options = FormatOptions(importGrouping: .testableBottom)
        testFormatting(for: input, output, rule: FormatRules.sortedImports, options: options)
    }

    func testTestableImportsWithGroupingTestableTop() {
        let input = "@testable import Bar\nimport Foo\n@testable import UIKit"
        let output = "@testable import Bar\n@testable import UIKit\nimport Foo"
        let options = FormatOptions(importGrouping: .testableTop)
        testFormatting(for: input, output, rule: FormatRules.sortedImports, options: options)
    }

    func testCaseInsensitiveSortedImports() {
        let input = "import Zlib\nimport lib"
        let output = "import lib\nimport Zlib"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testCaseInsensitiveCaseDifferingSortedImports() {
        let input = "import c\nimport B\nimport A.a\nimport A.A"
        let output = "import A.A\nimport A.a\nimport B\nimport c"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testNoDeleteCodeBetweenImports() {
        let input = "import Foo\nfunc bar() {}\nimport Bar"
        testFormatting(for: input, rule: FormatRules.sortedImports)
    }

    func testNoDeleteCodeBetweenImports2() {
        let input = "import Foo\nimport Bar\nfoo = bar\nimport Bar"
        let output = "import Bar\nimport Foo\nfoo = bar\nimport Bar"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
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
        testFormatting(for: input, rule: FormatRules.sortedImports)
    }

    func testSortContiguousImports() {
        let input = "import Foo\nimport Bar\nfunc bar() {}\nimport Quux\nimport Baz"
        let output = "import Bar\nimport Foo\nfunc bar() {}\nimport Baz\nimport Quux"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testNoMangleImportsPrecededByComment() {
        let input = """
        // evil comment

        #if canImport(Foundation)
            import Foundation
            #if canImport(UIKit) && canImport(AVFoundation)
                import UIKit
                import AVFoundation
            #endif
        #endif
        """
        let output = """
        // evil comment

        #if canImport(Foundation)
            import Foundation
            #if canImport(UIKit) && canImport(AVFoundation)
                import AVFoundation
                import UIKit
            #endif
        #endif
        """
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    // MARK: - duplicateImports

    func testRemoveDuplicateImport() {
        let input = "import Foundation\nimport Foundation"
        let output = "import Foundation"
        testFormatting(for: input, output, rule: FormatRules.duplicateImports)
    }

    func testRemoveDuplicateConditionalImport() {
        let input = "#if os(iOS)\n    import Foo\n    import Foo\n#else\n    import Bar\n    import Bar\n#endif"
        let output = "#if os(iOS)\n    import Foo\n#else\n    import Bar\n#endif"
        testFormatting(for: input, output, rule: FormatRules.duplicateImports)
    }

    func testNoRemoveOverlappingImports() {
        let input = "import MyModule\nimport MyModule.Private"
        testFormatting(for: input, rule: FormatRules.duplicateImports)
    }

    func testNoRemoveCaseDifferingImports() {
        let input = "import Auth0.Authentication\nimport Auth0.authentication"
        testFormatting(for: input, rule: FormatRules.duplicateImports)
    }

    func testRemoveDuplicateImportFunc() {
        let input = "import func Foo.bar\nimport func Foo.bar"
        let output = "import func Foo.bar"
        testFormatting(for: input, output, rule: FormatRules.duplicateImports)
    }

    func testNoRemoveTestableDuplicateImport() {
        let input = "import Foo\n@testable import Foo"
        let output = "\n@testable import Foo"
        testFormatting(for: input, output, rule: FormatRules.duplicateImports)
    }

    func testNoRemoveTestableDuplicateImport2() {
        let input = "@testable import Foo\nimport Foo"
        let output = "@testable import Foo"
        testFormatting(for: input, output, rule: FormatRules.duplicateImports)
    }

    // MARK: - strongOutlets

    func testRemoveWeakFromOutlet() {
        let input = "@IBOutlet weak var label: UILabel!"
        let output = "@IBOutlet var label: UILabel!"
        testFormatting(for: input, output, rule: FormatRules.strongOutlets)
    }

    func testRemoveWeakFromPrivateOutlet() {
        let input = "@IBOutlet private weak var label: UILabel!"
        let output = "@IBOutlet private var label: UILabel!"
        testFormatting(for: input, output, rule: FormatRules.strongOutlets)
    }

    func testRemoveWeakFromOutletOnSplitLine() {
        let input = "@IBOutlet\nweak var label: UILabel!"
        let output = "@IBOutlet\nvar label: UILabel!"
        testFormatting(for: input, output, rule: FormatRules.strongOutlets)
    }

    func testNoRemoveWeakFromNonOutlet() {
        let input = "weak var label: UILabel!"
        testFormatting(for: input, rule: FormatRules.strongOutlets)
    }

    func testNoRemoveWeakFromNonOutletAfterOutlet() {
        let input = "@IBOutlet weak var label1: UILabel!\nweak var label2: UILabel!"
        let output = "@IBOutlet var label1: UILabel!\nweak var label2: UILabel!"
        testFormatting(for: input, output, rule: FormatRules.strongOutlets)
    }

    func testNoRemoveWeakFromDelegateOutlet() {
        let input = "@IBOutlet weak var delegate: UITableViewDelegate?"
        testFormatting(for: input, rule: FormatRules.strongOutlets)
    }

    func testNoRemoveWeakFromDataSourceOutlet() {
        let input = "@IBOutlet weak var dataSource: UITableViewDataSource?"
        testFormatting(for: input, rule: FormatRules.strongOutlets)
    }

    func testRemoveWeakFromOutletAfterDelegateOutlet() {
        let input = "@IBOutlet weak var delegate: UITableViewDelegate?\n@IBOutlet weak var label1: UILabel!"
        let output = "@IBOutlet weak var delegate: UITableViewDelegate?\n@IBOutlet var label1: UILabel!"
        testFormatting(for: input, output, rule: FormatRules.strongOutlets)
    }

    func testRemoveWeakFromOutletAfterDataSourceOutlet() {
        let input = "@IBOutlet weak var dataSource: UITableViewDataSource?\n@IBOutlet weak var label1: UILabel!"
        let output = "@IBOutlet weak var dataSource: UITableViewDataSource?\n@IBOutlet var label1: UILabel!"
        testFormatting(for: input, output, rule: FormatRules.strongOutlets)
    }

    // MARK: - emptyBraces

    func testLinebreaksRemovedInsideBraces() {
        let input = "func foo() {\n  \n }"
        let output = "func foo() {}"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: FormatRules.emptyBraces, options: options)
    }

    func testCommentNotRemovedInsideBraces() {
        let input = "func foo() { // foo\n}"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: FormatRules.emptyBraces, options: options)
    }

    func testEmptyBracesNotRemovedInDoCatch() {
        let input = """
        do {
        } catch is FooError {
        } catch {}
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: FormatRules.emptyBraces, options: options)
    }

    func testEmptyBracesNotRemovedInIfElse() {
        let input = """
        if {
        } else if foo {
        } else {}
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: FormatRules.emptyBraces, options: options)
    }

    func testSpaceRemovedInsideEmptybraces() {
        let input = "foo { }"
        let output = "foo {}"
        testFormatting(for: input, output, rule: FormatRules.emptyBraces)
    }

    // MARK: - andOperator

    func testIfAndReplaced() {
        let input = "if true && true {}"
        let output = "if true, true {}"
        testFormatting(for: input, output, rule: FormatRules.andOperator)
    }

    func testGuardAndReplaced() {
        let input = "guard true && true\nelse { return }"
        let output = "guard true, true\nelse { return }"
        testFormatting(for: input, output, rule: FormatRules.andOperator)
    }

    func testWhileAndReplaced() {
        let input = "while true && true {}"
        let output = "while true, true {}"
        testFormatting(for: input, output, rule: FormatRules.andOperator)
    }

    func testIfDoubleAndReplaced() {
        let input = "if true && true && true {}"
        let output = "if true, true, true {}"
        testFormatting(for: input, output, rule: FormatRules.andOperator)
    }

    func testIfAndParensReplaced() {
        let input = "if true && (true && true) {}"
        let output = "if true, (true && true) {}"
        testFormatting(for: input, output, rule: FormatRules.andOperator, exclude: ["redundantParens"])
    }

    func testIfFunctionAndReplaced() {
        let input = "if functionReturnsBool() && true {}"
        let output = "if functionReturnsBool(), true {}"
        testFormatting(for: input, output, rule: FormatRules.andOperator)
    }

    func testNoReplaceIfOrAnd() {
        let input = "if foo || bar && baz {}"
        testFormatting(for: input, rule: FormatRules.andOperator)
    }

    func testNoReplaceIfAndOr() {
        let input = "if foo && bar || baz {}"
        testFormatting(for: input, rule: FormatRules.andOperator)
    }

    func testIfAndReplacedInFunction() {
        let input = "func someFunc() { if bar && baz {} }"
        let output = "func someFunc() { if bar, baz {} }"
        testFormatting(for: input, output, rule: FormatRules.andOperator)
    }

    func testNoReplaceIfCaseLetAnd() {
        let input = "if case let a = foo && bar {}"
        testFormatting(for: input, rule: FormatRules.andOperator)
    }

    func testNoReplaceWhileCaseLetAnd() {
        let input = "while case let a = foo && bar {}"
        testFormatting(for: input, rule: FormatRules.andOperator)
    }

    func testNoReplaceRepeatWhileAnd() {
        let input = """
        repeat {} while true && !false
        foo {}
        """
        testFormatting(for: input, rule: FormatRules.andOperator)
    }

    func testNoReplaceIfLetAndLetAnd() {
        let input = "if let a = b && c, let d = e && f {}"
        testFormatting(for: input, rule: FormatRules.andOperator)
    }

    func testNoReplaceIfTryAnd() {
        let input = "if try true && explode() {}"
        testFormatting(for: input, rule: FormatRules.andOperator)
    }

    func testHandleAndAtStartOfLine() {
        let input = "if a == b\n    && b == c {}"
        let output = "if a == b,\n    b == c {}"
        testFormatting(for: input, output, rule: FormatRules.andOperator)
    }

    func testHandleAndAtStartOfLineAfterComment() {
        let input = "if a == b // foo\n    && b == c {}"
        let output = "if a == b, // foo\n    b == c {}"
        testFormatting(for: input, output, rule: FormatRules.andOperator)
    }

    func testNoReplaceAndInViewBuilder() {
        let input = """
        SomeView {
            if foo == 5 && bar {
                Text("5")
            } else {
                Text("Not 5")
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.andOperator)
    }

    func testNoReplaceAndInViewBuilder2() {
        let input = """
        var body: some View {
            ZStack {
                if self.foo && self.bar {
                    self.closedPath
                }
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.andOperator)
    }

    // MARK: - isEmpty

    // count == 0

    func testCountEqualsZero() {
        let input = "if foo.count == 0 {}"
        let output = "if foo.isEmpty {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testFunctionCountEqualsZero() {
        let input = "if foo().count == 0 {}"
        let output = "if foo().isEmpty {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testExpressionCountEqualsZero() {
        let input = "if foo || bar.count == 0 {}"
        let output = "if foo || bar.isEmpty {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testCompoundIfCountEqualsZero() {
        let input = "if foo, bar.count == 0 {}"
        let output = "if foo, bar.isEmpty {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testOptionalCountEqualsZero() {
        let input = "if foo?.count == 0 {}"
        let output = "if foo?.isEmpty == true {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testOptionalChainCountEqualsZero() {
        let input = "if foo?.bar.count == 0 {}"
        let output = "if foo?.bar.isEmpty == true {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testCompoundIfOptionalCountEqualsZero() {
        let input = "if foo, bar?.count == 0 {}"
        let output = "if foo, bar?.isEmpty == true {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testTernaryCountEqualsZero() {
        let input = "foo ? bar.count == 0 : baz.count == 0"
        let output = "foo ? bar.isEmpty : baz.isEmpty"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    // count != 0

    func testCountNotEqualToZero() {
        let input = "if foo.count != 0 {}"
        let output = "if !foo.isEmpty {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testFunctionCountNotEqualToZero() {
        let input = "if foo().count != 0 {}"
        let output = "if !foo().isEmpty {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testExpressionCountNotEqualToZero() {
        let input = "if foo || bar.count != 0 {}"
        let output = "if foo || !bar.isEmpty {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testCompoundIfCountNotEqualToZero() {
        let input = "if foo, bar.count != 0 {}"
        let output = "if foo, !bar.isEmpty {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    // count > 0

    func testCountGreaterThanZero() {
        let input = "if foo.count > 0 {}"
        let output = "if !foo.isEmpty {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testCountExpressionGreaterThanZero() {
        let input = "if a.count - b.count > 0 {}"
        testFormatting(for: input, rule: FormatRules.isEmpty)
    }

    // optional count

    func testOptionalCountNotEqualToZero() {
        let input = "if foo?.count != 0 {}" // nil evaluates to true
        let output = "if foo?.isEmpty != true {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testOptionalChainCountNotEqualToZero() {
        let input = "if foo?.bar.count != 0 {}" // nil evaluates to true
        let output = "if foo?.bar.isEmpty != true {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testCompoundIfOptionalCountNotEqualToZero() {
        let input = "if foo, bar?.count != 0 {}"
        let output = "if foo, bar?.isEmpty != true {}"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    // edge cases

    func testTernaryCountNotEqualToZero() {
        let input = "foo ? bar.count != 0 : baz.count != 0"
        let output = "foo ? !bar.isEmpty : !baz.isEmpty"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testCountEqualsZeroAfterOptionalOnPreviousLine() {
        let input = "_ = foo?.bar\nbar.count == 0 ? baz() : quux()"
        let output = "_ = foo?.bar\nbar.isEmpty ? baz() : quux()"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testCountEqualsZeroAfterOptionalCallOnPreviousLine() {
        let input = "foo?.bar()\nbar.count == 0 ? baz() : quux()"
        let output = "foo?.bar()\nbar.isEmpty ? baz() : quux()"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testCountEqualsZeroAfterTrailingCommentOnPreviousLine() {
        let input = "foo?.bar() // foobar\nbar.count == 0 ? baz() : quux()"
        let output = "foo?.bar() // foobar\nbar.isEmpty ? baz() : quux()"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testCountGreaterThanZeroAfterOpenParen() {
        let input = "foo(bar.count > 0)"
        let output = "foo(!bar.isEmpty)"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    func testCountGreaterThanZeroAfterArgumentLabel() {
        let input = "foo(bar: baz.count > 0)"
        let output = "foo(bar: !baz.isEmpty)"
        testFormatting(for: input, output, rule: FormatRules.isEmpty)
    }

    // MARK: - anyObjectProtocol

    func testClassReplacedByAnyObject() {
        let input = "protocol Foo: class {}"
        let output = "protocol Foo: AnyObject {}"
        let options = FormatOptions(swiftVersion: "4.1")
        testFormatting(for: input, output, rule: FormatRules.anyObjectProtocol, options: options)
    }

    func testClassReplacedByAnyObjectWithOtherProtocols() {
        let input = "protocol Foo: class, Codable {}"
        let output = "protocol Foo: AnyObject, Codable {}"
        let options = FormatOptions(swiftVersion: "4.1")
        testFormatting(for: input, output, rule: FormatRules.anyObjectProtocol, options: options)
    }

    func testClassReplacedByAnyObjectImmediatelyAfterImport() {
        let input = "import Foundation\nprotocol Foo: class {}"
        let output = "import Foundation\nprotocol Foo: AnyObject {}"
        let options = FormatOptions(swiftVersion: "4.1")
        testFormatting(for: input, output, rule: FormatRules.anyObjectProtocol, options: options)
    }

    func testClassDeclarationNotReplacedByAnyObject() {
        let input = "class Foo: Codable {}"
        let options = FormatOptions(swiftVersion: "4.1")
        testFormatting(for: input, rule: FormatRules.anyObjectProtocol, options: options)
    }

    func testClassImportNotReplacedByAnyObject() {
        let input = "import class Foo.Bar"
        let options = FormatOptions(swiftVersion: "4.1")
        testFormatting(for: input, rule: FormatRules.anyObjectProtocol, options: options)
    }

    func testClassNotReplacedByAnyObjectIfSwiftVersionLessThan4_1() {
        let input = "protocol Foo: class {}"
        let options = FormatOptions(swiftVersion: "4.0")
        testFormatting(for: input, rule: FormatRules.anyObjectProtocol, options: options)
    }

    // MARK: - strongifiedSelf

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
        testFormatting(for: input, output, rule: FormatRules.strongifiedSelf, options: options)
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
        testFormatting(for: input, output, rule: FormatRules.strongifiedSelf, options: options)
    }

    func testBacktickedSelfNotConvertedIfVersionLessThan4_2() {
        let input = """
        { [weak self] in
            guard let `self` = self else { return }
        }
        """
        let options = FormatOptions(swiftVersion: "4.1.5")
        testFormatting(for: input, rule: FormatRules.strongifiedSelf, options: options)
    }

    func testBacktickedSelfNotConvertedIfVersionUnspecified() {
        let input = """
        { [weak self] in
            guard let `self` = self else { return }
        }
        """
        testFormatting(for: input, rule: FormatRules.strongifiedSelf)
    }

    // MARK: - typeSugar

    // arrays

    func testArrayTypeConvertedToSugar() {
        let input = "var foo: Array<String>"
        let output = "var foo: [String]"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testSwiftArrayTypeConvertedToSugar() {
        let input = "var foo: Swift.Array<String>"
        let output = "var foo: [String]"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testArrayNestedTypeAliasNotConvertedToSugar() {
        let input = "typealias Indices = Array<Foo>.Indices"
        testFormatting(for: input, rule: FormatRules.typeSugar)
    }

    func testArrayTypeReferenceConvertedToSugar() {
        let input = "let type = Array<Foo>.Type"
        let output = "let type = [Foo].Type"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testSwiftArrayTypeReferenceConvertedToSugar() {
        let input = "let type = Swift.Array<Foo>.Type"
        let output = "let type = [Foo].Type"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testArraySelfReferenceConvertedToSugar() {
        let input = "let type = Array<Foo>.self"
        let output = "let type = [Foo].self"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testSwiftArraySelfReferenceConvertedToSugar() {
        let input = "let type = Swift.Array<Foo>.self"
        let output = "let type = [Foo].self"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    // dictionaries

    func testDictionaryTypeConvertedToSugar() {
        let input = "var foo: Dictionary<String, Int>"
        let output = "var foo: [String: Int]"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testSwiftDictionaryTypeConvertedToSugar() {
        let input = "var foo: Swift.Dictionary<String, Int>"
        let output = "var foo: [String: Int]"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    // optionals

    func testOptionalTypeConvertedToSugar() {
        let input = "var foo: Optional<String>"
        let output = "var foo: String?"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testSwiftOptionalTypeConvertedToSugar() {
        let input = "var foo: Swift.Optional<String>"
        let output = "var foo: String?"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testOptionalClosureParenthesizedConvertedToSugar() {
        let input = "var foo: Optional<(Int) -> String>"
        let output = "var foo: ((Int) -> String)?"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testSwiftOptionalClosureParenthesizedConvertedToSugar() {
        let input = "var foo: Swift.Optional<(Int) -> String>"
        let output = "var foo: ((Int) -> String)?"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testStrippingSwiftNamespaceInOptionalTypeWhenConvertedToSugar() {
        let input = "Swift.Optional<String>"
        let output = "String?"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testStrippingSwiftNamespaceDoesNotStripPreviousSwiftNamespaceReferences() {
        let input = "let a: Swift.String = Optional<String>"
        let output = "let a: Swift.String = String?"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    // shortOptionals = exceptProperties

    func testPropertyTypeNotConvertedToSugar() {
        let input = "var foo: Optional<String>"
        let options = FormatOptions(shortOptionals: .exceptProperties)
        testFormatting(for: input, rule: FormatRules.typeSugar, options: options)
    }

    // swift parser bug

    func testAvoidSwiftParserBugWithClosuresInsideArrays() {
        let input = "var foo = Array<(_ image: Data?) -> Void>()"
        testFormatting(for: input, rule: FormatRules.typeSugar)
    }

    func testAvoidSwiftParserBugWithClosuresInsideDictionaries() {
        let input = "var foo = Dictionary<String, (_ image: Data?) -> Void>()"
        testFormatting(for: input, rule: FormatRules.typeSugar)
    }

    func testAvoidSwiftParserBugWithClosuresInsideOptionals() {
        let input = "var foo = Optional<(_ image: Data?) -> Void>()"
        testFormatting(for: input, rule: FormatRules.typeSugar)
    }

    func testDontOverApplyBugWorkaround() {
        let input = "var foo: Array<(_ image: Data?) -> Void>"
        let output = "var foo: [(_ image: Data?) -> Void]"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testDontOverApplyBugWorkaround2() {
        let input = "var foo: Dictionary<String, (_ image: Data?) -> Void>"
        let output = "var foo: [String: (_ image: Data?) -> Void]"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testDontOverApplyBugWorkaround3() {
        let input = "var foo: Optional<(_ image: Data?) -> Void>"
        let output = "var foo: ((_ image: Data?) -> Void)?"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testDontOverApplyBugWorkaround4() {
        let input = "var foo = Array<(image: Data?) -> Void>()"
        let output = "var foo = [(image: Data?) -> Void]()"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testDontOverApplyBugWorkaround5() {
        let input = "var foo = Array<(Data?) -> Void>()"
        let output = "var foo = [(Data?) -> Void]()"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testDontOverApplyBugWorkaround6() {
        let input = "var foo = Dictionary<Int, Array<(_ image: Data?) -> Void>>()"
        let output = "var foo = [Int: Array<(_ image: Data?) -> Void>]()"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    // MARK: - yodaConditions

    func testNumericLiteralEqualYodaCondition() {
        let input = "5 == foo"
        let output = "foo == 5"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNumericLiteralGreaterYodaCondition() {
        let input = "5.1 > foo"
        let output = "foo < 5.1"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testStringLiteralNotEqualYodaCondition() {
        let input = "\"foo\" != foo"
        let output = "foo != \"foo\""
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNilNotEqualYodaCondition() {
        let input = "nil != foo"
        let output = "foo != nil"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testTrueNotEqualYodaCondition() {
        let input = "true != foo"
        let output = "foo != true"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testEnumCaseNotEqualYodaCondition() {
        let input = ".foo != foo"
        let output = "foo != .foo"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testArrayLiteralNotEqualYodaCondition() {
        let input = "[5, 6] != foo"
        let output = "foo != [5, 6]"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNestedArrayLiteralNotEqualYodaCondition() {
        let input = "[5, [6, 7]] != foo"
        let output = "foo != [5, [6, 7]]"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testDictionaryLiteralNotEqualYodaCondition() {
        let input = "[foo: 5, bar: 6] != foo"
        let output = "foo != [foo: 5, bar: 6]"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testSubscriptNotTreatedAsYodaCondition() {
        let input = "foo[5] != bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testSubscriptOfParenthesizedExpressionNotTreatedAsYodaCondition() {
        let input = "(foo + bar)[5] != baz"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testSubscriptOfUnwrappedValueNotTreatedAsYodaCondition() {
        let input = "foo![5] != bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testSubscriptOfExpressionWithInlineCommentNotTreatedAsYodaCondition() {
        let input = "foo /* foo */ [5] != bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testSubscriptOfCollectionNotTreatedAsYodaCondition() {
        let input = "[foo][5] != bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testSubscriptOfTrailingClosureNotTreatedAsYodaCondition() {
        let input = "foo { [5] }[0] != bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testSubscriptOfRhsNotMangledInYodaCondition() {
        let input = "[1] == foo[0]"
        let output = "foo[0] == [1]"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testTupleYodaCondition() {
        let input = "(5, 6) != bar"
        let output = "bar != (5, 6)"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testLabeledTupleYodaCondition() {
        let input = "(foo: 5, bar: 6) != baz"
        let output = "baz != (foo: 5, bar: 6)"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNestedTupleYodaCondition() {
        let input = "(5, (6, 7)) != baz"
        let output = "baz != (5, (6, 7))"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testFunctionCallNotTreatedAsYodaCondition() {
        let input = "foo(5) != bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testCallOfParenthesizedExpressionNotTreatedAsYodaCondition() {
        let input = "(foo + bar)(5) != baz"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testCallOfUnwrappedValueNotTreatedAsYodaCondition() {
        let input = "foo!(5) != bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testCallOfExpressionWithInlineCommentNotTreatedAsYodaCondition() {
        let input = "foo /* foo */ (5) != bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testCallOfRhsNotMangledInYodaCondition() {
        let input = "(1, 2) == foo(0)"
        let output = "foo(0) == (1, 2)"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testTrailingClosureOnRhsNotMangledInYodaCondition() {
        let input = "(1, 2) == foo { $0 }"
        let output = "foo { $0 } == (1, 2)"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testYodaConditionInIfStatement() {
        let input = "if 5 != foo {}"
        let output = "if foo != 5 {}"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testSubscriptYodaConditionInIfStatementWithBraceOnNextLine() {
        let input = "if [0] == foo.bar[0]\n{ baz() }"
        let output = "if foo.bar[0] == [0]\n{ baz() }"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testYodaConditionInSecondClauseOfIfStatement() {
        let input = "if foo, 5 != bar {}"
        let output = "if foo, bar != 5 {}"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testYodaConditionInExpression() {
        let input = "let foo = 5 < bar\nbaz()"
        let output = "let foo = bar > 5\nbaz()"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testYodaConditionInExpressionWithTrailingClosure() {
        let input = "let foo = 5 < bar { baz() }"
        let output = "let foo = bar { baz() } > 5"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testYodaConditionInFunctionCall() {
        let input = "foo(5 < bar)"
        let output = "foo(bar > 5)"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testYodaConditionFollowedByExpression() {
        let input = "5 == foo + 6"
        let output = "foo + 6 == 5"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testPrefixExpressionYodaCondition() {
        let input = "!false == foo"
        let output = "foo == !false"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testPrefixExpressionYodaCondition2() {
        let input = "true == !foo"
        let output = "!foo == true"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testPostfixExpressionYodaCondition() {
        let input = "5<*> == foo"
        let output = "foo == 5<*>"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testDoublePostfixExpressionYodaCondition() {
        let input = "5!! == foo"
        let output = "foo == 5!!"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testPostfixExpressionNonYodaCondition() {
        let input = "5 == 5<*>"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testPostfixExpressionNonYodaCondition2() {
        let input = "5<*> == 5"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testStringEqualsStringNonYodaCondition() {
        let input = "\"foo\" == \"bar\""
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testConstantAfterNullCoalescingNonYodaCondition() {
        let input = "foo.last ?? -1 < bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testNoMangleYodaConditionFollowedByAndOperator() {
        let input = "5 <= foo && foo <= 7"
        let output = "foo >= 5 && foo <= 7"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNoMangleYodaConditionFollowedByOrOperator() {
        let input = "5 <= foo || foo <= 7"
        let output = "foo >= 5 || foo <= 7"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNoMangleYodaConditionFollowedByParentheses() {
        let input = "0 <= (foo + bar)"
        let output = "(foo + bar) >= 0"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNoMangleYodaConditionInTernary() {
        let input = "let z = 0 < y ? 3 : 4"
        let output = "let z = y > 0 ? 3 : 4"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNoMangleYodaConditionInTernary2() {
        let input = "let z = y > 0 ? 0 < x : 4"
        let output = "let z = y > 0 ? x > 0 : 4"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNoMangleYodaConditionInTernary3() {
        let input = "let z = y > 0 ? 3 : 0 < x"
        let output = "let z = y > 0 ? 3 : x > 0"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testKeyPathNotMangledAndNotTreatedAsYodaCondition() {
        let input = "\\.foo == bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testEnumCaseLessThanEnumCase() {
        let input = "XCTAssertFalse(.never < .never)"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    // yodaSwap = literalsOnly

    func testNoSwapYodaDotMember() {
        let input = "foo(where: .bar == baz)"
        let options = FormatOptions(yodaSwap: .literalsOnly)
        testFormatting(for: input, rule: FormatRules.yodaConditions, options: options)
    }

    // MARK: - leadingDelimiters

    func testLeadingCommaMovedToPreviousLine() {
        let input = """
        let foo = 5
            , bar = 6
        """
        let output = """
        let foo = 5,
            bar = 6
        """
        testFormatting(for: input, output, rule: FormatRules.leadingDelimiters)
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
        testFormatting(for: input, output, rule: FormatRules.leadingDelimiters)
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
        testFormatting(for: input, output, rule: FormatRules.leadingDelimiters)
    }

    // MARK: - preferKeyPath

    func testMapPropertyToKeyPath() {
        let input = "let foo = bar.map { $0.foo }"
        let output = "let foo = bar.map(\\.foo)"
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, output, rule: FormatRules.preferKeyPath,
                       options: options)
    }

    func testCompactMapPropertyToKeyPath() {
        let input = "let foo = bar.compactMap { $0.foo }"
        let output = "let foo = bar.compactMap(\\.foo)"
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, output, rule: FormatRules.preferKeyPath,
                       options: options)
    }

    func testFlatMapPropertyToKeyPath() {
        let input = "let foo = bar.flatMap { $0.foo }"
        let output = "let foo = bar.flatMap(\\.foo)"
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, output, rule: FormatRules.preferKeyPath,
                       options: options)
    }

    func testMapNestedPropertyWithSpacesToKeyPath() {
        let input = "let foo = bar.map { $0 . foo . bar }"
        let output = "let foo = bar.map(\\ . foo . bar)"
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, output, rule: FormatRules.preferKeyPath,
                       options: options, exclude: ["spaceAroundOperators"])
    }

    func testMultilineMapPropertyToKeyPath() {
        let input = """
        let foo = bar.map {
            $0.foo
        }
        """
        let output = "let foo = bar.map(\\.foo)"
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, output, rule: FormatRules.preferKeyPath,
                       options: options)
    }

    func testParenthesizedMapPropertyToKeyPath() {
        let input = "let foo = bar.map({ $0.foo })"
        let output = "let foo = bar.map(\\.foo)"
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, output, rule: FormatRules.preferKeyPath,
                       options: options)
    }

    func testNoMapSelfToKeyPath() {
        let input = "let foo = bar.map { $0 }"
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: FormatRules.preferKeyPath, options: options)
    }

    func testNoMapPropertyToKeyPathForSwiftLessThan5_2() {
        let input = "let foo = bar.map { $0.foo }"
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, rule: FormatRules.preferKeyPath, options: options)
    }

    func testNoMapPropertyToKeyPathForFunctionCalls() {
        let input = "let foo = bar.map { $0.foo() }"
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: FormatRules.preferKeyPath, options: options)
    }

    func testNoMapPropertyToKeyPathForCompoundExpressions() {
        let input = "let foo = bar.map { $0.foo || baz }"
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: FormatRules.preferKeyPath, options: options)
    }

    func testNoMapPropertyToKeyPathForOptionalChaining() {
        let input = "let foo = bar.map { $0?.foo }"
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: FormatRules.preferKeyPath, options: options)
    }
}
