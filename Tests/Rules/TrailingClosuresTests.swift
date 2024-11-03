//
//  TrailingClosuresTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 1/17/17.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class TrailingClosuresTests: XCTestCase {
    func testAnonymousClosureArgumentMadeTrailing() {
        let input = "foo(foo: 5, { /* some code */ })"
        let output = "foo(foo: 5) { /* some code */ }"
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testNamedClosureArgumentNotMadeTrailing() {
        let input = "foo(foo: 5, bar: { /* some code */ })"
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testClosureArgumentPassedToFunctionInArgumentsNotMadeTrailing() {
        let input = "foo(bar { /* some code */ })"
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testClosureArgumentInFunctionWithOtherClosureArgumentsNotMadeTrailing() {
        let input = "foo(foo: { /* some code */ }, { /* some code */ })"
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testClosureArgumentInExpressionNotMadeTrailing() {
        let input = "if let foo = foo(foo: 5, { /* some code */ }) {}"
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testClosureArgumentInCompoundExpressionNotMadeTrailing() {
        let input = "if let foo = foo(foo: 5, { /* some code */ }), let bar = bar(bar: 2, { /* some code */ }) {}"
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testClosureArgumentAfterLinebreakInGuardNotMadeTrailing() {
        let input = "guard let foo =\n    bar({ /* some code */ })\nelse { return }"
        testFormatting(for: input, rule: .trailingClosures,
                       exclude: [.wrapConditionalBodies])
    }

    func testClosureMadeTrailingForNumericTupleMember() {
        let input = "foo.1(5, { bar })"
        let output = "foo.1(5) { bar }"
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testNoRemoveParensAroundClosureFollowedByOpeningBrace() {
        let input = "foo({ bar }) { baz }"
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testRemoveParensAroundClosureWithInnerSpacesFollowedByUnwrapOperator() {
        let input = "foo( { bar } )?.baz"
        let output = "foo { bar }?.baz"
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    // solitary argument

    func testParensAroundSolitaryClosureArgumentRemoved() {
        let input = "foo({ /* some code */ })"
        let output = "foo { /* some code */ }"
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testParensAroundNamedSolitaryClosureArgumentNotRemoved() {
        let input = "foo(foo: { /* some code */ })"
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testParensAroundSolitaryClosureArgumentInExpressionNotRemoved() {
        let input = "if let foo = foo({ /* some code */ }) {}"
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testParensAroundSolitaryClosureArgumentInCompoundExpressionNotRemoved() {
        let input = "if let foo = foo({ /* some code */ }), let bar = bar({ /* some code */ }) {}"
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testParensAroundOptionalTrailingClosureInForLoopNotRemoved() {
        let input = "for foo in bar?.map({ $0.baz }) ?? [] {}"
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testParensAroundTrailingClosureInGuardCaseLetNotRemoved() {
        let input = "guard case let .foo(bar) = baz.filter({ $0 == quux }).isEmpty else {}"
        testFormatting(for: input, rule: .trailingClosures,
                       exclude: [.wrapConditionalBodies])
    }

    func testParensAroundTrailingClosureInWhereClauseLetNotRemoved() {
        let input = "for foo in bar where baz.filter({ $0 == quux }).isEmpty {}"
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testParensAroundTrailingClosureInSwitchNotRemoved() {
        let input = "switch foo({ $0 == bar }).count {}"
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testSolitaryClosureMadeTrailingInChain() {
        let input = "foo.map({ $0.path }).joined()"
        let output = "foo.map { $0.path }.joined()"
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testSpaceNotInsertedAfterClosureBeforeUnwrap() {
        let input = "let foo = bar.map({ foo($0) })?.baz"
        let output = "let foo = bar.map { foo($0) }?.baz"
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testSpaceNotInsertedAfterClosureBeforeForceUnwrap() {
        let input = "let foo = bar.map({ foo($0) })!.baz"
        let output = "let foo = bar.map { foo($0) }!.baz"
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testSolitaryClosureMadeTrailingForNumericTupleMember() {
        let input = "foo.1({ bar })"
        let output = "foo.1 { bar }"
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    // dispatch methods

    func testDispatchAsyncClosureArgumentMadeTrailing() {
        let input = "queue.async(execute: { /* some code */ })"
        let output = "queue.async { /* some code */ }"
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testDispatchAsyncGroupClosureArgumentMadeTrailing() {
        // TODO: async(group: , qos: , flags: , execute: )
        let input = "queue.async(group: g, execute: { /* some code */ })"
        let output = "queue.async(group: g) { /* some code */ }"
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testDispatchAsyncAfterClosureArgumentMadeTrailing() {
        let input = "queue.asyncAfter(deadline: t, execute: { /* some code */ })"
        let output = "queue.asyncAfter(deadline: t) { /* some code */ }"
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testDispatchAsyncAfterWallClosureArgumentMadeTrailing() {
        let input = "queue.asyncAfter(wallDeadline: t, execute: { /* some code */ })"
        let output = "queue.asyncAfter(wallDeadline: t) { /* some code */ }"
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testDispatchSyncClosureArgumentMadeTrailing() {
        let input = "queue.sync(execute: { /* some code */ })"
        let output = "queue.sync { /* some code */ }"
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testDispatchSyncFlagsClosureArgumentMadeTrailing() {
        let input = "queue.sync(flags: f, execute: { /* some code */ })"
        let output = "queue.sync(flags: f) { /* some code */ }"
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    // autoreleasepool

    func testAutoreleasepoolMadeTrailing() {
        let input = "autoreleasepool(invoking: { /* some code */ })"
        let output = "autoreleasepool { /* some code */ }"
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    // explicit trailing closure methods

    func testCustomMethodMadeTrailing() {
        let input = "foo(bar: 1, baz: { /* some code */ })"
        let output = "foo(bar: 1) { /* some code */ }"
        let options = FormatOptions(trailingClosures: ["foo"])
        testFormatting(for: input, output, rule: .trailingClosures, options: options)
    }

    // explicit non-trailing closure methods

    func testPerformBatchUpdatesNotMadeTrailing() {
        let input = "collectionView.performBatchUpdates({ /* some code */ })"
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testNimbleExpectNotMadeTrailing() {
        let input = "expect({ bar }).to(beNil())"
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testCustomMethodNotMadeTrailing() {
        let input = "foo({ /* some code */ })"
        let options = FormatOptions(neverTrailing: ["foo"])
        testFormatting(for: input, rule: .trailingClosures, options: options)
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
        testFormatting(for: input, rule: .trailingClosures)
    }
}
