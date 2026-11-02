//
//  NoExplicitOwnershipTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 8/27/23.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class NoExplicitOwnershipTests: XCTestCase {
    func testRemovesOwnershipKeywordsFromFunc() {
        let input = """
        consuming func myMethod(consuming foo: consuming Foo, borrowing bars: borrowing [Bar]) {}
        borrowing func myMethod(consuming foo: consuming Foo, borrowing bars: borrowing [Bar]) {}
        """

        let output = """
        func myMethod(consuming foo: Foo, borrowing bars: [Bar]) {}
        func myMethod(consuming foo: Foo, borrowing bars: [Bar]) {}
        """

        testFormatting(for: input, output, rule: .noExplicitOwnership, exclude: [.unusedArguments])
    }

    func testRemovesOwnershipKeywordsFromClosure() {
        let input = """
        foos.map { (foo: consuming Foo) in
            foo.bar
        }

        foos.map { (foo: borrowing Foo) in
            foo.bar
        }
        """

        let output = """
        foos.map { (foo: Foo) in
            foo.bar
        }

        foos.map { (foo: Foo) in
            foo.bar
        }
        """

        testFormatting(for: input, output, rule: .noExplicitOwnership)
    }

    func testRemovesOwnershipKeywordsFromType() {
        let input = """
        let consuming: (consuming Foo) -> Bar
        let borrowing: (borrowing Foo) -> Bar
        """

        let output = """
        let consuming: (Foo) -> Bar
        let borrowing: (Foo) -> Bar
        """

        testFormatting(for: input, output, rule: .noExplicitOwnership)
    }

    func testDoesntRemoveEnumCasesNamedConsumingOrBorrowing() {
        let input = """
        enum Ownership {
            case consuming(Int)
            case borrowing(Int)
        }

        func swap(_ ownership: Ownership) -> Ownership {
            switch ownership {
            case let .consuming(value):
                .borrowing(value)
            case let .borrowing(value):
                Ownership.consuming(value)
            }
        }
        """

        testFormatting(for: input, rule: .noExplicitOwnership)
    }

    func testDoesntRemoveFunctionsNamedConsumingOrBorrowing() {
        let input = """
        func consuming(_ value: Int) -> Int {
            value + 1
        }

        func borrowing(_ value: Int) -> Int {
            value * 2
        }

        let foo = consuming(1)
        let bar = borrowing(foo) + consuming(foo)
        """

        testFormatting(for: input, rule: .noExplicitOwnership)
    }
}
