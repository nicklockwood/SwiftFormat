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
        let input = """
        foo(foo: 5, { /* some code */ })
        """
        let output = """
        foo(foo: 5) { /* some code */ }
        """
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testNamedClosureArgumentNotMadeTrailing() {
        let input = """
        foo(foo: 5, bar: { /* some code */ })
        """
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testClosureArgumentPassedToFunctionInArgumentsNotMadeTrailing() {
        let input = """
        foo(bar { /* some code */ })
        """
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testClosureArgumentInFunctionWithOtherClosureArgumentsNotMadeTrailing() {
        let input = """
        foo(foo: { /* some code */ }, { /* some code */ })
        """
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testClosureArgumentInIfStatementNotMadeTrailing() {
        let input = """
        if let foo = foo(foo: 5, { /* some code */ }) {}
        """
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testClosureArgumentInCompoundIfStatementNotMadeTrailing() {
        let input = """
        if let foo = foo(foo: 5, { /* some code */ }), let bar = bar(bar: 2, { /* some code */ }) {}
        """
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testClosureArgumentAfterLinebreakInGuardNotMadeTrailing() {
        let input = """
        guard let foo =
            bar({ /* some code */ })
        else { return }
        """
        testFormatting(for: input, rule: .trailingClosures,
                       exclude: [.wrapConditionalBodies])
    }

    func testClosureMadeTrailingForNumericTupleMember() {
        let input = """
        foo.1(5, { bar })
        """
        let output = """
        foo.1(5) { bar }
        """
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testAnonymousInitClosureArgumentMadeTrailing() {
        let input = """
        Foo.init({ foo = bar })
        """
        let output = """
        Foo.init { foo = bar }
        """
        testFormatting(for: input, output, rule: .trailingClosures, exclude: [.redundantInit])
    }

    func testNamedInitClosureArgumentNotMadeTrailing() {
        let input = """
        Foo.init(bar: { foo = bar })
        """
        testFormatting(for: input, rule: .trailingClosures, exclude: [.redundantInit])
    }

    func testNoRemoveParensAroundClosureFollowedByOpeningBrace() {
        let input = """
        foo({ bar }) { baz }
        """
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testRemoveParensAroundClosureWithInnerSpacesFollowedByUnwrapOperator() {
        let input = """
        foo( { bar } )?.baz
        """
        let output = """
        foo { bar }?.baz
        """
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    // solitary argument

    func testParensAroundSolitaryClosureArgumentRemoved() {
        let input = """
        foo({ /* some code */ })
        """
        let output = """
        foo { /* some code */ }
        """
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testParensAroundNamedSolitaryClosureArgumentNotRemoved() {
        let input = """
        foo(foo: { /* some code */ })
        """
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testParensAroundSolitaryClosureArgumentInExpressionNotRemoved() {
        let input = """
        if let foo = foo({ /* some code */ }) {}
        """
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testParensAroundSolitaryClosureArgumentInCompoundExpressionNotRemoved() {
        let input = """
        if let foo = foo({ /* some code */ }), let bar = bar({ /* some code */ }) {}
        """
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testParensAroundOptionalTrailingClosureInForLoopNotRemoved() {
        let input = """
        for foo in bar?.map({ $0.baz }) ?? [] {}
        """
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testParensAroundTrailingClosureInGuardCaseLetNotRemoved() {
        let input = """
        guard case let .foo(bar) = baz.filter({ $0 == quux }).isEmpty else {}
        """
        testFormatting(for: input, rule: .trailingClosures,
                       exclude: [.wrapConditionalBodies])
    }

    func testParensAroundTrailingClosureInWhereClauseLetNotRemoved() {
        let input = """
        for foo in bar where baz.filter({ $0 == quux }).isEmpty {}
        """
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testParensAroundTrailingClosureInSwitchNotRemoved() {
        let input = """
        switch foo({ $0 == bar }).count {}
        """
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testSolitaryClosureMadeTrailingInChain() {
        let input = """
        foo.map({ $0.path }).joined()
        """
        let output = """
        foo.map { $0.path }.joined()
        """
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testSpaceNotInsertedAfterClosureBeforeUnwrap() {
        let input = """
        let foo = bar.map({ foo($0) })?.baz
        """
        let output = """
        let foo = bar.map { foo($0) }?.baz
        """
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testSpaceNotInsertedAfterClosureBeforeForceUnwrap() {
        let input = """
        let foo = bar.map({ foo($0) })!.baz
        """
        let output = """
        let foo = bar.map { foo($0) }!.baz
        """
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testSolitaryClosureMadeTrailingForNumericTupleMember() {
        let input = """
        foo.1({ bar })
        """
        let output = """
        foo.1 { bar }
        """
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    // dispatch methods

    func testDispatchAsyncClosureArgumentMadeTrailing() {
        let input = """
        queue.async(execute: { /* some code */ })
        """
        let output = """
        queue.async { /* some code */ }
        """
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testDispatchAsyncGroupClosureArgumentMadeTrailing() {
        // TODO: async(group: , qos: , flags: , execute: )
        let input = """
        queue.async(group: g, execute: { /* some code */ })
        """
        let output = """
        queue.async(group: g) { /* some code */ }
        """
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testDispatchAsyncAfterClosureArgumentMadeTrailing() {
        let input = """
        queue.asyncAfter(deadline: t, execute: { /* some code */ })
        """
        let output = """
        queue.asyncAfter(deadline: t) { /* some code */ }
        """
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testDispatchAsyncAfterWallClosureArgumentMadeTrailing() {
        let input = """
        queue.asyncAfter(wallDeadline: t, execute: { /* some code */ })
        """
        let output = """
        queue.asyncAfter(wallDeadline: t) { /* some code */ }
        """
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testDispatchSyncClosureArgumentMadeTrailing() {
        let input = """
        queue.sync(execute: { /* some code */ })
        """
        let output = """
        queue.sync { /* some code */ }
        """
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testDispatchSyncFlagsClosureArgumentMadeTrailing() {
        let input = """
        queue.sync(flags: f, execute: { /* some code */ })
        """
        let output = """
        queue.sync(flags: f) { /* some code */ }
        """
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    // autoreleasepool

    func testAutoreleasepoolMadeTrailing() {
        let input = """
        autoreleasepool(invoking: { /* some code */ })
        """
        let output = """
        autoreleasepool { /* some code */ }
        """
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    // explicit trailing closure methods

    func testCustomMethodMadeTrailing() {
        let input = """
        foo(bar: 1, baz: { /* some code */ })
        """
        let output = """
        foo(bar: 1) { /* some code */ }
        """
        let options = FormatOptions(trailingClosures: ["foo"])
        testFormatting(for: input, output, rule: .trailingClosures, options: options)
    }

    // explicit non-trailing closure methods

    func testPerformBatchUpdatesNotMadeTrailing() {
        let input = """
        collectionView.performBatchUpdates({ /* some code */ })
        """
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testNimbleExpectNotMadeTrailing() {
        let input = """
        expect({ bar }).to(beNil())
        """
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testCustomMethodNotMadeTrailing() {
        let input = """
        foo({ /* some code */ })
        """
        let options = FormatOptions(neverTrailing: ["foo"])
        testFormatting(for: input, rule: .trailingClosures, options: options)
    }

    func testOptionalClosureCallMadeTrailing() {
        let input = """
        myClosure?(foo: 5, { /* some code */ })
        """
        let output = """
        myClosure?(foo: 5) { /* some code */ }
        """
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testOptionalSolitaryClosureCallMadeTrailing() {
        let input = """
        myClosure?({ /* some code */ })
        """
        let output = """
        myClosure? { /* some code */ }
        """
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testOptionalClosureInChainMadeTrailing() {
        let input = """
        foo.myClosure?({ $0.path }).joined()
        """
        let output = """
        foo.myClosure? { $0.path }.joined()
        """
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testOptionalNamedClosureArgumentNotMadeTrailing() {
        let input = """
        myClosure?(foo: 5, bar: { /* some code */ })
        """
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testReturnTupleNotConfusedForFunctionCall() {
        let input = """
        return (expectation, { state in
            XCTAssertEqual(state, expectedStates.removeFirst())
            expectation.fulfill()
        })
        """

        testFormatting(for: input, rule: .trailingClosures, exclude: [.redundantParens])
    }

    func testClosureReturnTupleNotConfusedForFunctionCall() {
        let input = """
        { _ in
            (expectation, { state in
                XCTAssertEqual(state, expectedStates.removeFirst())
                expectation.fulfill()
            })
        }
        """

        testFormatting(for: input, rule: .trailingClosures, exclude: [.redundantParens])
    }

    // multiple closures

    func testMultipleTrailingClosuresWithFirstUnlabeled() {
        let input = """
        withAnimation(.linear, {
            // perform animation
        }, completion: {
            // handle completion
        })
        """
        let output = """
        withAnimation(.linear) {
            // perform animation
        } completion: {
            // handle completion
        }
        """
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testMultipleTrailingClosuresWithFirstLabeled() {
        let input = """
        withAnimation(.linear, animation: {
            // perform animation
        }, completion: {
            // handle completion
        })
        """
        testFormatting(for: input, rule: .trailingClosures)
    }

    func testMultipleTrailingClosuresWithThreeClosures() {
        let input = """
        performTask(param: 1, {
            // first closure
        }, onSuccess: {
            // success handler
        }, onFailure: {
            // failure handler
        })
        """
        let output = """
        performTask(param: 1) {
            // first closure
        } onSuccess: {
            // success handler
        } onFailure: {
            // failure handler
        }
        """
        testFormatting(for: input, output, rule: .trailingClosures)
    }

    func testMultipleTrailingClosuresNotAppliedWhenFirstIsLabeled() {
        let input = """
        someFunction(param: 1, first: {
            // first closure
        }, second: {
            // second closure
        })
        """
        testFormatting(for: input, rule: .trailingClosures)
    }

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

    func testMultipleTrailingClosuresWithTrailingComma() {
        let input = """
        withAnimationIfNeeded(
            .linear,
            { didAppear = true },
            completion: { animateText = true },
        )
        """
        let output = """
        withAnimationIfNeeded(
            .linear
        ) { didAppear = true }
            completion: { animateText = true }

        """
        testFormatting(for: input, [output], rules: [.trailingClosures, .indent])
    }
}
