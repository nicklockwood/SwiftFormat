//
//  RulesTests+Syntax.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 15/11/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class SyntaxTests: RulesTests {
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

    func testTodoReplacedInMiddleOfCommentBlock() {
        let input = """
        // Some comment
        // todo : foo
        // Some more comment
        """
        let output = """
        // Some comment
        // TODO: foo
        // Some more comment
        """
        testFormatting(for: input, output, rule: FormatRules.todos)
    }

    func testTodoNotReplacedInMiddleOfDocBlock() {
        let input = """
        /// Some docs
        /// TODO: foo
        /// Some more docs
        """
        testFormatting(for: input, rule: FormatRules.todos, exclude: ["docComments"])
    }

    func testTodoNotReplacedAtStartOfDocBlock() {
        let input = """
        /// TODO: foo
        /// Some docs
        """
        testFormatting(for: input, rule: FormatRules.todos, exclude: ["docComments"])
    }

    func testTodoNotReplacedAtEndOfDocBlock() {
        let input = """
        /// Some docs
        /// TODO: foo
        """
        testFormatting(for: input, rule: FormatRules.todos, exclude: ["docComments"])
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

    func testParensNotConvertedToVoidIfLocalOverrideExists() {
        let input = """
        struct Void {}
        let foo = () -> ()
        print(foo)
        """
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
        testFormatting(for: input, rule: FormatRules.void, exclude: ["redundantVoidReturnType"])
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
        testFormatting(for: input, output, rule: FormatRules.void, exclude: ["redundantVoidReturnType"])
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
        // TODO: it should actually be safe to convert Swift.Void - only unsafe for other namespaces
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

    func testCaseVoidNotUnwrapped() {
        let input = "case some(Void)"
        testFormatting(for: input, rule: FormatRules.void)
    }

    func testLocalVoidTypeNotConverted() {
        let input = """
        struct Void {}
        let foo = Void()
        print(foo)
        """
        testFormatting(for: input, rule: FormatRules.void)
    }

    func testLocalVoidTypeForwardReferenceNotConverted() {
        let input = """
        let foo = Void()
        print(foo)
        struct Void {}
        """
        testFormatting(for: input, rule: FormatRules.void)
    }

    func testLocalVoidTypealiasNotConverted() {
        let input = """
        typealias Void = MyVoid
        let foo = Void()
        print(foo)
        """
        testFormatting(for: input, rule: FormatRules.void)
    }

    func testLocalVoidTypealiasForwardReferenceNotConverted() {
        let input = """
        let foo = Void()
        print(foo)
        typealias Void = MyVoid
        """
        testFormatting(for: input, rule: FormatRules.void)
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
        testFormatting(for: input, output, rule: FormatRules.void, options: options, exclude: ["redundantVoidReturnType"])
    }

    func testNoConvertVoidSelfToTuple() {
        let input = "Void.self"
        let options = FormatOptions(useVoid: false)
        testFormatting(for: input, rule: FormatRules.void, options: options)
    }

    func testNoConvertVoidTypeToTuple() {
        let input = "Void.Type"
        let options = FormatOptions(useVoid: false)
        testFormatting(for: input, rule: FormatRules.void, options: options)
    }

    func testCaseVoidConvertedToTuple() {
        let input = "case some(Void)"
        let output = "case some(())"
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
        testFormatting(for: input, rule: FormatRules.trailingClosures,
                       exclude: ["wrapConditionalBodies"])
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

    func testRemoveParensAroundClosureWithInnerSpacesFollowedByUnwrapOperator() {
        let input = "foo( { bar } )?.baz"
        let output = "foo { bar }?.baz"
        testFormatting(for: input, output, rule: FormatRules.trailingClosures)
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
        testFormatting(for: input, rule: FormatRules.trailingClosures,
                       exclude: ["wrapConditionalBodies"])
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

    // explicit trailing closure methods

    func testCustomMethodMadeTrailing() {
        let input = "foo(bar: 1, baz: { /* some code */ })"
        let output = "foo(bar: 1) { /* some code */ }"
        let options = FormatOptions(trailingClosures: ["foo"])
        testFormatting(for: input, output, rule: FormatRules.trailingClosures, options: options)
    }

    // explicit non-trailing closure methods

    func testPerformBatchUpdatesNotMadeTrailing() {
        let input = "collectionView.performBatchUpdates({ /* some code */ })"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testNimbleExpectNotMadeTrailing() {
        let input = "expect({ bar }).to(beNil())"
        testFormatting(for: input, rule: FormatRules.trailingClosures)
    }

    func testCustomMethodNotMadeTrailing() {
        let input = "foo({ /* some code */ })"
        let options = FormatOptions(neverTrailing: ["foo"])
        testFormatting(for: input, rule: FormatRules.trailingClosures, options: options)
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

    // MARK: - enumNamespaces

    func testEnumNamespacesClassAsProtocolRestriction() {
        let input = """
        @objc protocol Foo: class {
            @objc static var expressionTypes: [String: RuntimeType] { get }
        }
        """
        testFormatting(for: input, rule: FormatRules.enumNamespaces)
    }

    func testEnumNamespacesConformingOtherType() {
        let input = "private final class CustomUITableViewCell: UITableViewCell {}"
        testFormatting(for: input, rule: FormatRules.enumNamespaces)
    }

    func testEnumNamespacesImportClass() {
        let input = "import class MyUIKit.AutoHeightTableView"
        testFormatting(for: input, rule: FormatRules.enumNamespaces)
    }

    func testEnumNamespacesImportStruct() {
        let input = "import struct Core.CurrencyFormatter"
        testFormatting(for: input, rule: FormatRules.enumNamespaces)
    }

    func testEnumNamespacesClassFunction() {
        let input = """
        class Container {
            class func bar() {}
        }
        """
        testFormatting(for: input, rule: FormatRules.enumNamespaces)
    }

    func testEnumNamespacesRemovingExtraKeywords() {
        let input = """
        final class MyNamespace {
            static let bar = "bar"
        }
        """
        let output = """
        enum MyNamespace {
            static let bar = "bar"
        }
        """
        testFormatting(for: input, output, rule: FormatRules.enumNamespaces)
    }

    func testEnumNamespacesNestedTypes() {
        let input = """
        enum Namespace {}
        extension Namespace {
            struct Constants {
                static let bar = "bar"
            }
        }
        """
        let output = """
        enum Namespace {}
        extension Namespace {
            enum Constants {
                static let bar = "bar"
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.enumNamespaces)
    }

    func testEnumNamespacesNestedTypes2() {
        let input = """
        struct Namespace {
            struct NestedNamespace {
                static let foo: Int
                static let bar: Int
            }
        }
        """
        let output = """
        enum Namespace {
            enum NestedNamespace {
                static let foo: Int
                static let bar: Int
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.enumNamespaces)
    }

    func testEnumNamespacesNestedTypes3() {
        let input = """
        struct Namespace {
            struct TypeNestedInNamespace {
                let foo: Int
                let bar: Int
            }
        }
        """
        let output = """
        enum Namespace {
            struct TypeNestedInNamespace {
                let foo: Int
                let bar: Int
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.enumNamespaces)
    }

    func testEnumNamespacesNestedTypes4() {
        let input = """
        struct Namespace {
            static func staticFunction() {
                struct NestedType {
                    init() {}
                }
            }
        }
        """
        let output = """
        enum Namespace {
            static func staticFunction() {
                struct NestedType {
                    init() {}
                }
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.enumNamespaces)
    }

    func testEnumNamespacesNestedTypes5() {
        let input = """
        struct Namespace {
            static func staticFunction() {
                func nestedFunction() { /* ... */ }
            }
        }
        """
        let output = """
        enum Namespace {
            static func staticFunction() {
                func nestedFunction() { /* ... */ }
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.enumNamespaces)
    }

    func testEnumNamespacesStaticVariable() {
        let input = """
        struct Constants {
            static let β = 0, 5
        }
        """
        let output = """
        enum Constants {
            static let β = 0, 5
        }
        """
        testFormatting(for: input, output, rule: FormatRules.enumNamespaces)
    }

    func testEnumNamespacesStaticAndInstanceVariable() {
        let input = """
        struct Constants {
            static let β = 0, 5
            let Ɣ = 0, 3
        }
        """
        testFormatting(for: input, rule: FormatRules.enumNamespaces)
    }

    func testEnumNamespacesStaticFunction() {
        let input = """
        struct Constants {
            static func remoteConfig() -> Int {
                return 10
            }
        }
        """
        let output = """
        enum Constants {
            static func remoteConfig() -> Int {
                return 10
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.enumNamespaces)
    }

    func testEnumNamespacesStaticAndInstanceFunction() {
        let input = """
        struct Constants {
            static func remoteConfig() -> Int {
                return 10
            }

            func instanceConfig(offset: Int) -> Int {
                return offset + 10
            }
        }
        """

        testFormatting(for: input, rule: FormatRules.enumNamespaces)
    }

    func testEnumNamespaceDoesNothing() {
        let input = """
        struct Foo {
            #if BAR
                func something() {}
            #else
                func something() {}
            #endif
        }
        """
        testFormatting(for: input, rule: FormatRules.enumNamespaces)
    }

    func testEnumNamespaceDoesNothingForEmptyDeclaration() {
        let input = """
        struct Foo {}
        """
        testFormatting(for: input, rule: FormatRules.enumNamespaces)
    }

    func testEnumNamespacesDoesNothingIfTypeInitializedInternally() {
        let input = """
        struct Foo {
            static func bar() {
                Foo().baz
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.enumNamespaces)
    }

    func testEnumNamespacesDoesNothingIfSelfInitializedInternally() {
        let input = """
        struct Foo {
            static func bar() {
                Self().baz
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.enumNamespaces)
    }

    func testEnumNamespacesDoesNothingIfSelfInitializedInternally2() {
        let input = """
        struct Foo {
            static func bar() -> Foo {
                self.init()
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.enumNamespaces)
    }

    func testEnumNamespacesDoesNothingIfSelfAssignedInternally() {
        let input = """
        class Foo {
            public static func bar() {
                let bundle = Bundle(for: self)
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.enumNamespaces)
    }

    func testEnumNamespacesDoesNothingIfSelfAssignedInternally2() {
        let input = """
        class Foo {
            public static func bar() {
                let `class` = self
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.enumNamespaces)
    }

    func testEnumNamespacesDoesNothingIfSelfAssignedInternally3() {
        let input = """
        class Foo {
            public static func bar() {
                let `class` = Foo.self
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.enumNamespaces)
    }

    func testClassFuncNotReplacedByEnum() {
        let input = """
        class Foo {
            class override func foo() {
                Bar.bar()
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.enumNamespaces,
                       exclude: ["modifierOrder", "specifiers"])
    }

    func testOpenClassNotReplacedByEnum() {
        let input = """
        open class Foo {
            public static let bar = "bar"
        }
        """
        testFormatting(for: input, rule: FormatRules.enumNamespaces)
    }

    func testClassNotReplacedByEnum() {
        let input = """
        class Foo {
            public static let bar = "bar"
        }
        """
        let options = FormatOptions(enumNamespaces: .structsOnly)
        testFormatting(for: input, rule: FormatRules.enumNamespaces, options: options)
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

    // MARK: - andOperator

    func testIfAndReplaced() {
        let input = "if true && true {}"
        let output = "if true, true {}"
        testFormatting(for: input, output, rule: FormatRules.andOperator)
    }

    func testGuardAndReplaced() {
        let input = "guard true && true\nelse { return }"
        let output = "guard true, true\nelse { return }"
        testFormatting(for: input, output, rule: FormatRules.andOperator,
                       exclude: ["wrapConditionalBodies"])
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
        testFormatting(for: input, output, rule: FormatRules.andOperator,
                       exclude: ["redundantParens"])
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
        testFormatting(for: input, output, rule: FormatRules.andOperator, exclude: ["indent"])
    }

    func testHandleAndAtStartOfLineAfterComment() {
        let input = "if a == b // foo\n    && b == c {}"
        let output = "if a == b, // foo\n    b == c {}"
        testFormatting(for: input, output, rule: FormatRules.andOperator, exclude: ["indent"])
    }

    func testNoReplaceAndOperatorWhereGenericsAmbiguous() {
        let input = "if x < y && z > (a * b) {}"
        testFormatting(for: input, rule: FormatRules.andOperator)
    }

    func testNoReplaceAndOperatorWhereGenericsAmbiguous2() {
        let input = "if x < y && z && w > (a * b) {}"
        let output = "if x < y, z && w > (a * b) {}"
        testFormatting(for: input, output, rule: FormatRules.andOperator)
    }

    func testAndOperatorCrash() {
        let input = """
        DragGesture().onChanged { gesture in
            if gesture.translation.width < 50 && gesture.translation.height > 50 {
                offset = gesture.translation
            }
        }
        """
        let output = """
        DragGesture().onChanged { gesture in
            if gesture.translation.width < 50, gesture.translation.height > 50 {
                offset = gesture.translation
            }
        }
        """
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

    func testReplaceAndInViewBuilderInSwift5_3() {
        let input = """
        SomeView {
            if foo == 5 && bar {
                Text("5")
            } else {
                Text("Not 5")
            }
        }
        """
        let output = """
        SomeView {
            if foo == 5, bar {
                Text("5")
            } else {
                Text("Not 5")
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.3")
        testFormatting(for: input, output, rule: FormatRules.andOperator, options: options)
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
        testFormatting(for: input, output, rule: FormatRules.anyObjectProtocol, options: options,
                       exclude: ["blankLineAfterImports"])
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

    func testArrayDeclarationNotConvertedToSugar() {
        let input = "struct Array<Element> {}"
        testFormatting(for: input, rule: FormatRules.typeSugar)
    }

    func testExtensionTypeSugar() {
        let input = """
        extension Array<Foo> {}
        extension Optional<Foo> {}
        extension Dictionary<Foo, Bar> {}
        extension Optional<Array<Dictionary<Foo, Array<Bar>>>> {}
        """

        let output = """
        extension [Foo] {}
        extension Foo? {}
        extension [Foo: Bar] {}
        extension [[Foo: [Bar]]]? {}
        """
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

    func testOptionalTupleWrappedInParensConvertedToSugar() {
        let input = "let foo: Optional<(foo: Int, bar: String)>"
        let output = "let foo: (foo: Int, bar: String)?"
        testFormatting(for: input, output, rule: FormatRules.typeSugar)
    }

    func testOptionalComposedProtocolWrappedInParensConvertedToSugar() {
        let input = "let foo: Optional<UIView & Foo>"
        let output = "let foo: (UIView & Foo)?"
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

    func testOptionalTypeInsideCaseConvertedToSugar() {
        let input = "if case .some(Optional<Any>.some(let foo)) = bar else {}"
        let output = "if case .some(Any?.some(let foo)) = bar else {}"
        testFormatting(for: input, output, rule: FormatRules.typeSugar, exclude: ["hoistPatternLet"])
    }

    func testSwitchCaseOptionalNotReplaced() {
        let input = """
        switch foo {
        case Optional<Any>.none:
        }
        """
        testFormatting(for: input, rule: FormatRules.typeSugar)
    }

    func testCaseOptionalNotReplaced2() {
        let input = "if case Optional<Any>.none = foo {}"
        testFormatting(for: input, rule: FormatRules.typeSugar)
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

    func testNoMapPropertyToKeyPathForTrailingContains() {
        let input = "let foo = bar.contains { $0.foo }"
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: FormatRules.preferKeyPath, options: options)
    }

    func testMapPropertyToKeyPathForContainsWhere() {
        let input = "let foo = bar.contains(where: { $0.foo })"
        let output = "let foo = bar.contains(where: \\.foo)"
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, output, rule: FormatRules.preferKeyPath, options: options)
    }

    func testMultipleTrailingClosuresNotConvertedToKeyPath() {
        let input = "foo.map { $0.bar } reverse: { $0.bar }"
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: FormatRules.preferKeyPath, options: options)
    }

    // MARK: - assertionFailures

    func testAssertionFailuresForAssertFalse() {
        let input = "assert(false)"
        let output = "assertionFailure()"
        testFormatting(for: input, output, rule: FormatRules.assertionFailures)
    }

    func testAssertionFailuresForAssertFalseWithSpaces() {
        let input = "assert ( false )"
        let output = "assertionFailure()"
        testFormatting(for: input, output, rule: FormatRules.assertionFailures)
    }

    func testAssertionFailuresForAssertFalseWithLinebreaks() {
        let input = """
        assert(
            false
        )
        """
        let output = "assertionFailure()"
        testFormatting(for: input, output, rule: FormatRules.assertionFailures)
    }

    func testAssertionFailuresForAssertTrue() {
        let input = "assert(true)"
        testFormatting(for: input, rule: FormatRules.assertionFailures)
    }

    func testAssertionFailuresForAssertFalseWithArgs() {
        let input = "assert(false, msg, 20, 21)"
        let output = "assertionFailure(msg, 20, 21)"
        testFormatting(for: input, output, rule: FormatRules.assertionFailures)
    }

    func testAssertionFailuresForPreconditionFalse() {
        let input = "precondition(false)"
        let output = "preconditionFailure()"
        testFormatting(for: input, output, rule: FormatRules.assertionFailures)
    }

    func testAssertionFailuresForPreconditionTrue() {
        let input = "precondition(true)"
        testFormatting(for: input, rule: FormatRules.assertionFailures)
    }

    func testAssertionFailuresForPreconditionFalseWithArgs() {
        let input = "precondition(false, msg, 0, 1)"
        let output = "preconditionFailure(msg, 0, 1)"
        testFormatting(for: input, output, rule: FormatRules.assertionFailures)
    }

    // MARK: - acronyms

    func testUppercaseAcronyms() {
        let input = """
        let url: URL
        let destinationUrl: URL
        let id: ID
        let screenId = "screenId" // We intentionally don't change the content of strings
        let validUrls: Set<URL>
        let validUrlschemes: Set<URL>

        let uniqueIdentifier = UUID()

        /// Opens Urls based on their scheme
        struct UrlRouter {}

        /// The Id of a screen that can be displayed in the app
        struct ScreenId {}
        """

        let output = """
        let url: URL
        let destinationURL: URL
        let id: ID
        let screenID = "screenId" // We intentionally don't change the content of strings
        let validURLs: Set<URL>
        let validUrlschemes: Set<URL>

        let uniqueIdentifier = UUID()

        /// Opens URLs based on their scheme
        struct URLRouter {}

        /// The ID of a screen that can be displayed in the app
        struct ScreenID {}
        """

        testFormatting(for: input, output, rule: FormatRules.acronyms)
    }

    func testUppercaseCustomAcronym() {
        let input = """
        let url: URL
        let destinationUrl: URL
        let pngData: Data
        let imageInPngFormat: UIImage
        """

        let output = """
        let url: URL
        let destinationUrl: URL
        let pngData: Data
        let imageInPNGFormat: UIImage
        """

        testFormatting(for: input, output, rule: FormatRules.acronyms, options: FormatOptions(acronyms: ["png"]))
    }

    func testDisableUppercaseAcronym() {
        let input = """
        // swiftformat:disable:next acronyms
        typeNotOwnedByAuthor.destinationUrl = URL()
        typeOwnedByAuthor.destinationURL = URL()
        """

        testFormatting(for: input, rule: FormatRules.acronyms)
    }

    // MARK: - blockComments

    func testBlockCommentsOneLine() {
        let input = "foo = bar /* comment */"
        let output = "foo = bar // comment"
        testFormatting(for: input, output, rule: FormatRules.blockComments)
    }

    func testDocBlockCommentsOneLine() {
        let input = "foo = bar /** doc comment */"
        let output = "foo = bar /// doc comment"
        testFormatting(for: input, output, rule: FormatRules.blockComments)
    }

    func testPreservesBlockCommentInSingleLineScope() {
        let input = "if foo { /* code */ }"
        testFormatting(for: input, rule: FormatRules.blockComments)
    }

    func testBlockCommentsMultiLine() {
        let input = """
        /*
         * foo
         * bar
         */
        """
        let output = """
        // foo
        // bar
        """
        testFormatting(for: input, output, rule: FormatRules.blockComments)
    }

    func testBlockCommentsWithoutBlankFirstLine() {
        let input = """
        /* foo
         * bar
         */
        """
        let output = """
        // foo
        // bar
        """
        testFormatting(for: input, output, rule: FormatRules.blockComments)
    }

    func testBlockCommentsWithBlankLine() {
        let input = """
        /*
         * foo
         *
         * bar
         */
        """
        let output = """
        // foo
        //
        // bar
        """
        testFormatting(for: input, output, rule: FormatRules.blockComments)
    }

    func testBlockDocCommentsWithAsterisksOnEachLine() {
        let input = """
        /**
         * This is a documentation comment,
         * not a standard comment.
         */
        """
        let output = """
        /// This is a documentation comment,
        /// not a standard comment.
        """
        testFormatting(for: input, output, rule: FormatRules.blockComments, exclude: ["docComments"])
    }

    func testBlockDocCommentsWithoutAsterisksOnEachLine() {
        let input = """
        /**
         This is a documentation comment,
         not a standard comment.
         */
        """
        let output = """
        /// This is a documentation comment,
        /// not a standard comment.
        """
        testFormatting(for: input, output, rule: FormatRules.blockComments, exclude: ["docComments"])
    }

    func testBlockCommentWithBulletPoints() {
        let input = """
        /*
         This is a list of nice colors:

         * green
         * blue
         * red

         Yellow is also great.
         */

        /*
         * Another comment.
         */
        """
        let output = """
        // This is a list of nice colors:
        //
        // * green
        // * blue
        // * red
        //
        // Yellow is also great.

        // Another comment.
        """
        testFormatting(for: input, output, rule: FormatRules.blockComments)
    }

    func testBlockCommentsNested() {
        let input = """
        /*
         * comment
         * /* inside */
         * a comment
         */
        """
        let output = """
        // comment
        // inside
        // a comment
        """
        testFormatting(for: input, output, rule: FormatRules.blockComments)
    }

    func testBlockCommentsIndentPreserved() {
        let input = """
        func foo() {
            /*
             foo
             bar.
             */
        }
        """
        let output = """
        func foo() {
            // foo
            // bar.
        }
        """
        testFormatting(for: input, output, rule: FormatRules.blockComments)
    }

    func testBlockCommentsIndentPreserved2() {
        let input = """
        func foo() {
            /*
             * foo
             * bar.
             */
        }
        """
        let output = """
        func foo() {
            // foo
            // bar.
        }
        """
        testFormatting(for: input, output, rule: FormatRules.blockComments)
    }

    func testBlockDocCommentsIndentPreserved() {
        let input = """
        func foo() {
            /**
             * foo
             * bar.
             */
        }
        """
        let output = """
        func foo() {
            /// foo
            /// bar.
        }
        """
        testFormatting(for: input, output, rule: FormatRules.blockComments, exclude: ["docComments"])
    }

    func testLongBlockCommentsWithoutPerLineMarkersFullyConverted() {
        let input = """
        /*
            The beginnings of the lines in this multiline comment body
            have only spaces in them. There are no asterisks, only spaces.

            This should not cause the blockComments rule to convert only
            part of the comment body and leave the rest hanging.

            The comment must have at least this many lines to trigger the bug.
        */
        """
        let output = """
        // The beginnings of the lines in this multiline comment body
        // have only spaces in them. There are no asterisks, only spaces.
        //
        // This should not cause the blockComments rule to convert only
        // part of the comment body and leave the rest hanging.
        //
        // The comment must have at least this many lines to trigger the bug.
        """
        testFormatting(for: input, output, rule: FormatRules.blockComments)
    }

    func testBlockCommentImmediatelyFollowedByCode() {
        let input = """
        /**
          foo

          bar
        */
        func foo() {}
        """
        let output = """
        /// foo
        ///
        /// bar
        func foo() {}
        """
        testFormatting(for: input, output, rule: FormatRules.blockComments)
    }

    func testBlockCommentImmediatelyFollowedByCode2() {
        let input = """
        /**
         Line 1.

         Line 2.

         Line 3.
         */
        foo(bar)
        """
        let output = """
        /// Line 1.
        ///
        /// Line 2.
        ///
        /// Line 3.
        foo(bar)
        """
        testFormatting(for: input, output, rule: FormatRules.blockComments, exclude: ["docComments"])
    }

    func testBlockCommentImmediatelyFollowedByCode3() {
        let input = """
        /* foo
           bar */
        func foo() {}
        """
        let output = """
        // foo
        // bar
        func foo() {}
        """
        testFormatting(for: input, output, rule: FormatRules.blockComments, exclude: ["docComments"])
    }

    func testBlockCommentFollowedByBlankLine() {
        let input = """
        /**
          foo

          bar
        */

        func foo() {}
        """
        let output = """
        /// foo
        ///
        /// bar

        func foo() {}
        """
        testFormatting(for: input, output, rule: FormatRules.blockComments, exclude: ["docComments"])
    }

    // MARK: - opaqueGenericParameters

    func testGenericNotModifiedBelowSwift5_7() {
        let input = """
        func foo<T>(_ value: T) {
            print(value)
        }
        """

        let options = FormatOptions(swiftVersion: "5.6")
        testFormatting(for: input, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testOpaqueGenericParameterWithNoConstraint() {
        let input = """
        func foo<T>(_ value: T) {
            print(value)
        }

        init<T>(_ value: T) {
            print(value)
        }

        subscript<T>(_ value: T) -> Foo {
            Foo(value)
        }

        subscript<T>(_ value: T) -> Foo {
            get {
                Foo(value)
            }
            set {
                print(newValue)
            }
        }
        """

        let output = """
        func foo(_ value: some Any) {
            print(value)
        }

        init(_ value: some Any) {
            print(value)
        }

        subscript(_ value: some Any) -> Foo {
            Foo(value)
        }

        subscript(_ value: some Any) -> Foo {
            get {
                Foo(value)
            }
            set {
                print(newValue)
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testDisableSomeAnyGenericType() {
        let input = """
        func foo<T>(_ value: T) {
            print(value)
        }
        """

        let options = FormatOptions(useSomeAny: false, swiftVersion: "5.7")
        testFormatting(for: input, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testOpaqueGenericParameterWithConstraintInBracket() {
        let input = """
        func foo<T: Fooable, U: Barable>(_ fooable: T, barable: U) -> Baaz {
            print(fooable, barable)
        }

        init<T: Fooable, U: Barable>(_ fooable: T, barable: U) {
            print(fooable, barable)
        }

        subscript<T: Fooable, U: Barable>(_ fooable: T, barable: U) -> Any {
            (fooable, barable)
        }
        """

        let output = """
        func foo(_ fooable: some Fooable, barable: some Barable) -> Baaz {
            print(fooable, barable)
        }

        init(_ fooable: some Fooable, barable: some Barable) {
            print(fooable, barable)
        }

        subscript(_ fooable: some Fooable, barable: some Barable) -> Any {
            (fooable, barable)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testOpaqueGenericParameterWithConstraintsInWhereClause() {
        let input = """
        func foo<T, U>(_ t: T, _ u: U) -> Baaz where T: Fooable, T: Barable, U: Baazable {
            print(t, u)
        }

        init<T, U>(_ t: T, _ u: U) where T: Fooable, T: Barable, U: Baazable {
            print(t, u)
        }
        """

        let output = """
        func foo(_ t: some Fooable & Barable, _ u: some Baazable) -> Baaz {
            print(t, u)
        }

        init(_ t: some Fooable & Barable, _ u: some Baazable) {
            print(t, u)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testOpaqueGenericParameterCanRemoveOneButNotOthers_onOneLine() {
        let input = """
        func foo<S: Baazable, T: Fooable, U: Barable>(_ foo: T, bar1: U, bar2: U) where S.AssociatedType == Baaz, T: Quuxable, U: Qaaxable {
            print(foo, bar1, bar2)
        }
        """

        let output = """
        func foo<S: Baazable, U: Barable>(_ foo: some Fooable & Quuxable, bar1: U, bar2: U) where S.AssociatedType == Baaz, U: Qaaxable {
            print(foo, bar1, bar2)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testOpaqueGenericParameterCanRemoveOneButNotOthers_onMultipleLines() {
        let input = """
        func foo<
            S: Baazable,
            T: Fooable,
            U: Barable
        >(_ foo: T, bar1: U, bar2: U) where
            S.AssociatedType == Baaz,
            T: Quuxable,
            U: Qaaxable
        {
            print(foo, bar1, bar2)
        }
        """

        let output = """
        func foo<
            S: Baazable,
            U: Barable
        >(_ foo: some Fooable & Quuxable, bar1: U, bar2: U) where
            S.AssociatedType == Baaz,
            U: Qaaxable
        {
            print(foo, bar1, bar2)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testOpaqueGenericParameterWithUnknownAssociatedTypeConstraint() {
        // If we knew that `T.AssociatedType` was the protocol's primary
        // associated type we could update this to `value: some Fooable<Bar>`,
        // but we don't necessarily have that type information available.
        //  - If primary associated types become very widespread, it may make
        //    sense to assume (or have an option to assume) that this would work.
        let input = """
        func foo<T: Fooable>(_ value: T) where T.AssociatedType == Bar {
            print(value)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testOpaqueGenericParameterWithAssociatedTypeConformance() {
        // There is no opaque generic parameter syntax that supports this type of constraint
        let input = """
        func foo<T: Fooable>(_ value: T) where T.AssociatedType: Bar {
            print(value)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testOpaqueGenericParameterWithKnownAssociatedTypeConstraint() {
        // For known types (like those in the standard library),
        // we are able to know their primary associated types
        let input = """
        func foo<T: Collection>(_ value: T) where T.Element == Foo {
            print(value)
        }
        """

        let output = """
        func foo(_ value: some Collection<Foo>) {
            print(value)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testOpaqueGenericParameterWithAssociatedTypeConstraint() {
        let input = """
        func foo<T: Collection<Foo>>(_: T) {}
        func bar<T>(_: T) where T: Collection<Foo> {}
        func baaz<T>(_: T) where T == any Collection<Foo> {}
        """

        let output = """
        func foo(_: some Collection<Foo>) {}
        func bar(_: some Collection<Foo>) {}
        func baaz(_: any Collection<Foo>) {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testGenericTypeUsedInMultipleParameters() {
        let input = """
        func foo<T: Fooable>(_ first: T, second: T) {
            print(first, second)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testGenericTypeUsedInClosureMultipleTimes() {
        let input = """
        func foo<T: Fooable>(_ closure: (T) -> T) {
            closure(foo)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testGenericTypeUsedAsReturnType() {
        // A generic used as a return type is different from an opaque result type (SE-244).
        // In `-> T where T: Fooable`, the generic type is caller-specified, but with
        // `-> some Fooable` the generic type is specified by the function implementation.
        // Because those represent different concepts, we can't convert between them.
        let input = """
        func foo<T: Fooable>() -> T {
            // ...
        }

        func bar<T>() -> T where T: Barable {
            // ...
        }

        func baaz<T: Baazable>() -> Set<SomeComplicatedNestedGeneric<T, Bar>> {
            // ...
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testGenericTypeUsedAsReturnTypeAndParameter() {
        // Since we can't change the return value, we can't change any of the use cases of T
        let input = """
        func foo<T: Fooable>(_ value: T) -> T {
            value
        }

        func bar<T>(_ value: T) -> T where T: Barable {
            value
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testGenericTypeWithClosureInWhereClauseDoesntCrash() {
        let input = """
        struct Foo<U> {
            func bar<V>(_ value: V) where U == @Sendable (V) -> Int {}
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testGenericExtensionSameTypeConstraint() {
        let input = """
        func foo<U>(_ u: U) where U == String {
            print(u)
        }
        """

        let output = """
        func foo(_ u: String) {
            print(u)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testGenericExtensionSameTypeGenericConstraint() {
        let input = """
        func foo<U, V>(_ u: U, _ v: V) where U == V {
            print(u, v)
        }

        func foo<U, V>(_ u: U, _ v: V) where V == U {
            print(u, v)
        }
        """

        let output = """
        func foo<V>(_ u: V, _ v: V) {
            print(u, v)
        }

        func foo<U>(_ u: U, _ v: U) {
            print(u, v)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testIssue1269() {
        let input = """
        func bar<V, R>(
            _ value: V,
            _ work: () -> R
        ) -> R
            where Value == @Sendable () -> V,
            V: Sendable
        {
            work()
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testVariadicParameterNotConvertedToOpaqueGeneric() {
        let input = """
        func variadic<T>(_ t: T...) {
            print(t)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testNonGenericVariadicParametersDoesntPreventUsingOpaqueGenerics() {
        let input = """
        func variadic<U>(t: Any..., u: U, v: Any...) {
            print(t, u, v)
        }
        """

        let output = """
        func variadic(t: Any..., u: some Any, v: Any...) {
            print(t, u, v)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testIssue1275() {
        let input = """
        func loggedKeypath<T: CustomStringConvertible>(
            by _: KeyPath<T, Element>...,
            actionKeyword _: UserActionKeyword,
            identifier _: String
        ) {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testIssue1278() {
        let input = """
        public struct Foo<Value> {
            public func withValue<V, R>(
                _: V,
                operation _: () throws -> R
            ) rethrows -> R
                where Value == @Sendable () -> V,
                V: Sendable
            {}

            public func withValue<V, R>(
                _: V,
                operation _: () async throws -> R
            ) async rethrows -> R
                where Value == () -> V
            {}
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    // MARK: - genericExtensions

    func testGenericExtensionNotModifiedBeforeSwift5_7() {
        let input = "extension Array where Element == Foo {}"

        let options = FormatOptions(swiftVersion: "5.6")
        testFormatting(for: input, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testUpdatesArrayGenericExtensionToAngleBracketSyntax() {
        let input = "extension Array where Element == Foo {}"
        let output = "extension Array<Foo> {}"

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: FormatRules.genericExtensions, options: options, exclude: ["typeSugar"])
    }

    func testUpdatesOptionalGenericExtensionToAngleBracketSyntax() {
        let input = "extension Optional where Wrapped == Foo {}"
        let output = "extension Optional<Foo> {}"

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: FormatRules.genericExtensions, options: options, exclude: ["typeSugar"])
    }

    func testUpdatesArrayGenericExtensionToAngleBracketSyntaxWithSelf() {
        let input = "extension Array where Self.Element == Foo {}"
        let output = "extension Array<Foo> {}"

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: FormatRules.genericExtensions, options: options, exclude: ["typeSugar"])
    }

    func testUpdatesArrayWithGenericElement() {
        let input = "extension Array where Element == Foo<Bar> {}"
        let output = "extension Array<Foo<Bar>> {}"

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: FormatRules.genericExtensions, options: options, exclude: ["typeSugar"])
    }

    func testUpdatesDictionaryGenericExtensionToAngleBracketSyntax() {
        let input = "extension Dictionary where Key == Foo, Value == Bar {}"
        let output = "extension Dictionary<Foo, Bar> {}"

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: FormatRules.genericExtensions, options: options, exclude: ["typeSugar"])
    }

    func testRequiresAllGenericTypesToBeProvided() {
        // No type provided for `Value`, so we can't use the angle bracket syntax
        let input = "extension Dictionary where Key == Foo {}"

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: FormatRules.genericExtensions, options: options)
    }

    func testHandlesNestedCollectionTypes() {
        let input = "extension Array where Element == [[Foo: Bar]] {}"
        let output = "extension Array<[[Foo: Bar]]> {}"

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: FormatRules.genericExtensions, options: options, exclude: ["typeSugar"])
    }

    func testDoesntUpdateIneligibleConstraints() {
        // This could potentially by `extension Optional<some Fooable>` in a future language version
        // but that syntax isn't implemented as of Swift 5.7
        let input = "extension Optional where Wrapped: Fooable {}"

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: FormatRules.genericExtensions, options: options)
    }

    func testPreservesOtherConstraintsInWhereClause() {
        let input = "extension Collection where Element == String, Index == Int {}"
        let output = "extension Collection<String> where Index == Int {}"

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: FormatRules.genericExtensions, options: options)
    }

    func testSupportsUserProvidedGenericTypes() {
        let input = """
        extension StateStore where State == FooState, Action == FooAction {}
        extension LinkedList where Element == Foo {}
        """
        let output = """
        extension StateStore<FooState, FooAction> {}
        extension LinkedList<Foo> {}
        """

        let options = FormatOptions(
            genericTypes: "LinkedList<Element>;StateStore<State, Action>",
            swiftVersion: "5.7"
        )
        testFormatting(for: input, output, rule: FormatRules.genericExtensions, options: options)
    }

    func testSupportsMultilineUserProvidedGenericTypes() {
        let input = """
        extension Reducer where
            State == MyFeatureState,
            Action == MyFeatureAction,
            Environment == ApplicationEnvironment
        {}
        """
        let output = """
        extension Reducer<MyFeatureState, MyFeatureAction, ApplicationEnvironment> {}
        """

        let options = FormatOptions(
            genericTypes: "Reducer<State, Action, Environment>",
            swiftVersion: "5.7"
        )
        testFormatting(for: input, output, rule: FormatRules.genericExtensions, options: options)
    }

    func testOpaqueGenericParametersRuleSuccessfullyTerminatesInSampleCode() {
        let input = """
        class Service {
            public func run() {}
            private let foo: Foo<Void, Void>
            private func a() -> Eventual<Void> {}
            private func b() -> Eventual<Void> {}
            private func c() -> Eventual<Void> {}
            private func d() -> Eventual<Void> {}
            private func e() -> Eventual<Void> {}
            private func f() -> Eventual<Void> {}
            private func g() -> Eventual<Void> {}
            private func h() -> Eventual<Void> {}
            private func i() {}
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testGenericParameterUsedInConstraintOfOtherTypeNotChanged() {
        let input = """
        func combineResults<ASuccess, AFailure, BSuccess, BFailure>(
            _: Potential<ASuccess, AFailure>,
            _: Potential<BSuccess, BFailure>
        ) -> Potential<Success, Never> where
            Success == (Result<ASuccess, AFailure>, Result<BSuccess, BFailure>),
            Failure == Never
        {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testGenericParameterInheritedFromContextNotRemoved() {
        let input = """
        func assign<Target>(
            on _: DispatchQueue,
            to _: AssignTarget<Target>,
            at _: ReferenceWritableKeyPath<Target, Value>
        ) where Value: Equatable {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testGenericParameterUsedInBodyNotRemoved() {
        let input = """
        func foo<T>(_ value: T) {
            typealias TTT = T
            let casted = value as TTT
            print(casted)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testGenericParameterUsedAsClosureParameterNotRemoved() {
        let input = """
        func foo<Foo>(_: (Foo) -> Void) {}
        func bar<Foo>(_: (Foo) throws -> Void) {}
        func baaz<Foo>(_: (Foo) async -> Void) {}
        func quux<Foo>(_: (Foo) async throws -> Void) {}
        func qaax<Foo>(_: ([Foo]) -> Void) {}
        func qaax<Foo>(_: ((Foo, Bar)) -> Void) {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testFinalGenericParamRemovedProperlyWithoutHangingComma() {
        let input = """
        func foo<Bar, Baaz>(
            bar _: (Bar) -> Void,
            baaz _: Baaz
        ) {}
        """

        let output = """
        func foo<Bar>(
            bar _: (Bar) -> Void,
            baaz _: some Any
        ) {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testAddsParensAroundTypeIfNecessary() {
        let input = """
        func foo<Foo>(_: Foo.Type) {}
        func bar<Foo>(_: Foo?) {}
        """

        let output = """
        func foo(_: (some Any).Type) {}
        func bar(_: (some Any)?) {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testHandlesSingleExactTypeGenericConstraint() {
        let input = """
        func foo<T>(with _: T) -> Foo where T == Dependencies {}
        """

        let output = """
        func foo(with _: Dependencies) -> Foo {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testGenericConstraintThatIsGeneric() {
        let input = """
        class Foo<Bar, Baaz> {}
        func foo<T: Foo<String, String>>(_: T) {}
        class Bar<Baaz> {}
        func bar<T: Bar<String>>(_: T) {}
        """

        let output = """
        class Foo<Bar, Baaz> {}
        func foo(_: some Foo<String, String>) {}
        class Bar<Baaz> {}
        func bar(_: some Bar<String>) {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testDoesntChangeTypeWithConstraintThatReferencesItself() {
        // This is a weird one but in the actual code this comes from `ViewModelContext` is both defined
        // on the parent type of this declaration (where it has additional important constraints),
        // and again in the method itself. Changing this to an opaque parameter breaks the build, because
        // it loses the generic constraints applied by the parent type.
        let input = """
        func makeSections<ViewModelContext: RoutingBehaviors<ViewModelContext.Dependencies>>(_: ViewModelContext) {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: FormatRules.opaqueGenericParameters, options: options)
    }

    func testOpaqueGenericParametersDoesntleaveTrailingComma() {
        let input = "func f<T, U>(x: U) -> T where T: A, U: B {}"
        let output = "func f<T>(x: some B) -> T where T: A {}"
        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: FormatRules.opaqueGenericParameters,
                       options: options, exclude: ["unusedArguments"])
    }

    // MARK: docComments

    func testConvertCommentsToDocComments() {
        let input = """
        // Multi-line comment before class with
        // attribute between comment and declaration
        @objc
        class Foo {
            // Single line comment before property
            let foo = Foo()

            // Single line comment before property with property wrapper
            @State
            let bar = Bar()

            // Single line comment
            func foo() {}

            /* Single line block comment before method */
            func baaz() {}

            /*
               Multi-line block comment before method with attribute.

               This comment has a blank line in it.
             */
            @nonobjc
            func baaz() {}
        }

        // Enum with a case
        enum Quux {
            // Documentation on an enum case
            case quux
        }

        extension Collection where Element: Foo {
            // Property in extension with where clause
            var foo: Foo {
                first!
            }
        }
        """

        let output = """
        /// Multi-line comment before class with
        /// attribute between comment and declaration
        @objc
        class Foo {
            /// Single line comment before property
            let foo = Foo()

            /// Single line comment before property with property wrapper
            @State
            let bar = Bar()

            /// Single line comment
            func foo() {}

            /** Single line block comment before method */
            func baaz() {}

            /**
               Multi-line block comment before method with attribute.

               This comment has a blank line in it.
             */
            @nonobjc
            func baaz() {}
        }

        /// Enum with a case
        enum Quux {
            /// Documentation on an enum case
            case quux
        }

        extension Collection where Element: Foo {
            /// Property in extension with where clause
            var foo: Foo {
                first!
            }
        }
        """

        testFormatting(for: input, output, rule: FormatRules.docComments, exclude: ["spaceInsideComments"])
    }

    func testConvertDocCommentsToComments() {
        let input = """
        /// Comment not associated with class

        class Foo {
            /** Comment not associated with function */

            func bar() {
                /// Comment inside function declaration.
                /// This one is multi-line.

                /// This comment is inside a function and precedes a declaration,
                /// but we don't want to use doc comments inside property or function
                /// scopes since users typically don't think of these as doc comments,
                /// and this also breaks a common pattern where comments introduce
                /// an entire following block of code (not just the property)
                let bar: Bar? = Bar()
                print(bar)
            }

            var baaz: Baaz {
                /// Comment inside property getter
                let baazImpl = Baaz()
                return baazImpl
            }

            var quux: Quux {
                didSet {
                    /// Comment inside didSet
                    let newQuux = Quux()
                    print(newQuux)
                }
            }
        }
        """

        let output = """
        // Comment not associated with class

        class Foo {
            /* Comment not associated with function */

            func bar() {
                // Comment inside function declaration.
                // This one is multi-line.

                // This comment is inside a function and precedes a declaration,
                // but we don't want to use doc comments inside property or function
                // scopes since users typically don't think of these as doc comments,
                // and this also breaks a common pattern where comments introduce
                // an entire following block of code (not just the property)
                let bar: Bar? = Bar()
                print(bar)
            }

            var baaz: Baaz {
                // Comment inside property getter
                let baazImpl = Baaz()
                return baazImpl
            }

            var quux: Quux {
                didSet {
                    // Comment inside didSet
                    let newQuux = Quux()
                    print(newQuux)
                }
            }
        }
        """

        testFormatting(for: input, output, rule: FormatRules.docComments, exclude: ["spaceInsideComments"])
    }

    func testDoesntConvertAnnotationCommentsToDocComments() {
        let input = """
        // swiftformat:disable some_swift_format_rule
        let testSwiftLint: Foo

        // swiftlint:disable some_swift_lint_rule
        let testSwiftLint: Foo

        // sourcery:directive
        let testSourcery: Foo
        """

        testFormatting(for: input, rule: FormatRules.docComments)
    }

    // MARK: - conditionalAssignment

    func testDoesntConvertIfStatementAssignmentSwift5_8() {
        let input = """
        let foo: Foo
        if condition {
            foo = Foo("foo")
        } else {
            foo = Foo("bar")
        }
        """
        let options = FormatOptions(swiftVersion: "5.8")
        testFormatting(for: input, rule: FormatRules.conditionalAssignment, options: options)
    }

    func testConvertsIfStatementAssignment() {
        let input = """
        let foo: Foo
        if condition {
            foo = Foo("foo")
        } else {
            foo = Foo("bar")
        }
        """
        let output = """
        let foo: Foo = if condition {
            Foo("foo")
        } else {
            Foo("bar")
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: FormatRules.conditionalAssignment, options: options, exclude: ["redundantType"])
    }

    func testConvertsSimpleSwitchStatementAssignment() {
        let input = """
        let foo: Foo
        switch condition {
        case true:
            foo = Foo("foo")
        case false:
            foo = Foo("bar")
        }
        """
        let output = """
        let foo: Foo = switch condition {
        case true:
            Foo("foo")
        case false:
            Foo("bar")
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: FormatRules.conditionalAssignment, options: options, exclude: ["redundantType"])
    }

    func testConvertsTrivialSwitchStatementAssignment() {
        let input = """
        let foo: Foo
        switch enumWithOnceCase(let value) {
        case singleCase:
            foo = value
        }
        """
        let output = """
        let foo: Foo = switch enumWithOnceCase(let value) {
        case singleCase:
            value
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: FormatRules.conditionalAssignment, options: options)
    }

    func testConvertsNestedIfAndStatementAssignments() {
        let input = """
        let foo: Foo
        switch condition {
        case true:
            if condition {
                foo = Foo("foo")
            } else {
                foo = Foo("bar")
            }
        case false:
            switch condition {
            case true:
                foo = Foo("baaz")
            case false:
                if condition {
                    foo = Foo("quux")
                } else {
                    foo = Foo("quack")
                }
            }
        }
        """
        let output = """
        let foo: Foo = switch condition {
        case true:
            if condition {
                Foo("foo")
            } else {
                Foo("bar")
            }
        case false:
            switch condition {
            case true:
                Foo("baaz")
            case false:
                if condition {
                    Foo("quux")
                } else {
                    Foo("quack")
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: FormatRules.conditionalAssignment, options: options, exclude: ["redundantType"])
    }

    func testConvertsIfStatementAssignmentPreservingComment() {
        let input = """
        let foo: Foo
        // This is a comment between the property and condition
        if condition {
            foo = Foo("foo")
        } else {
            foo = Foo("bar")
        }
        """
        let output = """
        let foo: Foo
        // This is a comment between the property and condition
        = if condition {
            Foo("foo")
        } else {
            Foo("bar")
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: FormatRules.conditionalAssignment, options: options, exclude: ["indent", "redundantType"])
    }

    func testDoesntConvertsIfStatementAssigningMultipleProperties() {
        let input = """
        let foo: Foo
        let bar: Bar
        if condition {
            foo = Foo("foo")
            bar = Bar("foo")
        } else {
            foo = Foo("bar")
            bar = Bar("bar")
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: FormatRules.conditionalAssignment, options: options)
    }

    func testDoesntConvertsIfStatementAssigningDifferentProperties() {
        let input = """
        var foo: Foo?
        var bar: Bar?
        if condition {
            foo = Foo("foo")
        } else {
            bar = Bar("bar")
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: FormatRules.conditionalAssignment, options: options)
    }

    func testDoesntConvertNonExhaustiveIfStatementAssignment1() {
        let input = """
        var foo: Foo?
        if condition {
            foo = Foo("foo")
        } else if someOtherCondition {
            foo = Foo("bar")
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: FormatRules.conditionalAssignment, options: options)
    }

    func testDoesntConvertNonExhaustiveIfStatementAssignment2() {
        let input = """
        var foo: Foo?
        if condition {
            if condition {
                foo = Foo("foo")
            }
        } else {
            foo = Foo("bar")
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: FormatRules.conditionalAssignment, options: options)
    }

    func testDoesntConvertMultiStatementIfStatementAssignment1() {
        let input = """
        let foo: Foo
        if condition {
            foo = Foo("foo")
            print("Multi-statement")
        } else {
            foo = Foo("bar")
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: FormatRules.conditionalAssignment, options: options)
    }

    func testDoesntConvertMultiStatementIfStatementAssignment2() {
        let input = """
        let foo: Foo
        switch condition {
        case true:
            foo = Foo("foo")
            print("Multi-statement")
        case false:
            foo = Foo("bar")
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: FormatRules.conditionalAssignment, options: options)
    }

    func testDoesntConvertMultiStatementIfStatementAssignment3() {
        let input = """
        let foo: Foo
        if condition {
            if condition {
                foo = Foo("bar")
            } else {
                foo = Foo("baaz")
            }
            print("Multi-statement")
        } else {
            foo = Foo("bar")
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: FormatRules.conditionalAssignment, options: options)
    }

    func testDoesntConvertMultiStatementIfStatementAssignment4() {
        let input = """
        let foo: Foo
        switch condition {
        case true:
            if condition {
                foo = Foo("bar")
            } else {
                foo = Foo("baaz")
            }
            print("Multi-statement")
        case false:
            foo = Foo("bar")
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: FormatRules.conditionalAssignment, options: options)
    }
}
