//
//  SpaceAroundBracketsTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 8/22/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class SpaceAroundBracketsTests: XCTestCase {
    func testSubscriptNoAddSpacing() {
        let input = """
        foo[bar] = baz
        """
        testFormatting(for: input, rule: .spaceAroundBrackets)
    }

    func testSubscriptRemoveSpacing() {
        let input = """
        foo [bar] = baz
        """
        let output = """
        foo[bar] = baz
        """
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testArrayLiteralSpacing() {
        let input = """
        foo = [bar, baz]
        """
        testFormatting(for: input, rule: .spaceAroundBrackets)
    }

    func testSpaceNotRemovedAfterOfArray() {
        let input = """
        let foo: [4 of [String]]
        """
        testFormatting(for: input, rule: .spaceAroundBrackets)
    }

    func testSpaceAddedAfterOfArray() {
        let input = """
        let foo: [4 of[String]]
        """
        let output = """
        let foo: [4 of [String]]
        """
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testOfIdentifierBracketSpacing() {
        let input = """
        if foo.of[String.self] {}
        """
        testFormatting(for: input, rule: .spaceAroundBrackets)
    }

    func testAsArrayCastingSpacing() {
        let input = """
        foo as[String]
        """
        let output = """
        foo as [String]
        """
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testAsOptionalArrayCastingSpacing() {
        let input = """
        foo as? [String]
        """
        testFormatting(for: input, rule: .spaceAroundBrackets)
    }

    func testIsArrayTestingSpacing() {
        let input = """
        if foo is[String] {}
        """
        let output = """
        if foo is [String] {}
        """
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testIsIdentifierBracketSpacing() {
        let input = """
        if foo.is[String.self] {}
        """
        testFormatting(for: input, rule: .spaceAroundBrackets)
    }

    func testSpaceBeforeTupleIndexSubscript() {
        let input = """
        foo.1 [2]
        """
        let output = """
        foo.1[2]
        """
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testRemoveSpaceBetweenBracketAndParen() {
        let input = """
        let foo = bar[5] ()
        """
        let output = """
        let foo = bar[5]()
        """
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testRemoveSpaceBetweenBracketAndParenInsideClosure() {
        let input = """
        let foo = bar { [Int] () }
        """
        let output = """
        let foo = bar { [Int]() }
        """
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testAddSpaceBetweenCaptureListAndParen() {
        let input = """
        let foo = bar { [self](foo: Int) in foo }
        """
        let output = """
        let foo = bar { [self] (foo: Int) in foo }
        """
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testAddSpaceBetweenInoutAndStringArray() {
        let input = """
        func foo(arg _: inout[String]) {}
        """
        let output = """
        func foo(arg _: inout [String]) {}
        """
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testAddSpaceBetweenConsumingAndStringArray() {
        let input = """
        func foo(arg _: consuming[String]) {}
        """
        let output = """
        func foo(arg _: consuming [String]) {}
        """
        testFormatting(for: input, output, rule: .spaceAroundBrackets,
                       exclude: [.noExplicitOwnership])
    }

    func testAddSpaceBetweenBorrowingAndStringArray() {
        let input = """
        func foo(arg _: borrowing[String]) {}
        """
        let output = """
        func foo(arg _: borrowing [String]) {}
        """
        testFormatting(for: input, output, rule: .spaceAroundBrackets,
                       exclude: [.noExplicitOwnership])
    }

    func testAddSpaceBetweenSendingAndStringArray() {
        let input = """
        func foo(arg _: sending[String]) {}
        """
        let output = """
        func foo(arg _: sending [String]) {}
        """
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testSpaceNotRemovedBetweenAsOperatorAndBracket() {
        // https://github.com/nicklockwood/SwiftFormat/issues/1846
        let input = """
        @Test(arguments: [kSecReturnRef, kSecReturnAttributes] as [String])
        """
        testFormatting(for: input, rule: .spaceAroundBrackets)
    }

    func testSpaceNotRemovedBetweenTryAndBracket() {
        let input = """
        @Test(arguments: try [Identifier(101), nil])
        """
        testFormatting(for: input, rule: .spaceAroundBrackets)
    }

    func testAddSpaceBetweenBracketAndAwait() {
        let input = """
        let foo = await[bar: 5]
        """
        let output = """
        let foo = await [bar: 5]
        """
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testAddSpaceBetweenParenAndAwaitForSwift5_5() {
        let input = """
        let foo = await[bar: 5]
        """
        let output = """
        let foo = await [bar: 5]
        """
        testFormatting(for: input, output, rule: .spaceAroundBrackets,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testNoAddSpaceBetweenParenAndAwaitForSwiftLessThan5_5() {
        let input = """
        let foo = await[bar: 5]
        """
        testFormatting(for: input, rule: .spaceAroundBrackets,
                       options: FormatOptions(swiftVersion: "5.4.9"))
    }

    func testAddSpaceBetweenParenAndUnsafe() {
        let input = """
        unsafe[kinfo_proc](repeating: kinfo_proc(), count: length / MemoryLayout<kinfo_proc>.stride)
        """
        let output = """
        unsafe [kinfo_proc](repeating: kinfo_proc(), count: length / MemoryLayout<kinfo_proc>.stride)
        """
        testFormatting(for: input, output, rule: .spaceAroundBrackets)
    }

    func testNoAddSpaceBetweenParenAndAwaitForSwiftLessThan6_2() {
        let input = """
        unsafe[kinfo_proc](repeating: kinfo_proc(), count: length / MemoryLayout<kinfo_proc>.stride)
        """
        testFormatting(for: input, rule: .spaceAroundBrackets,
                       options: FormatOptions(swiftVersion: "6.1"))
    }
}
