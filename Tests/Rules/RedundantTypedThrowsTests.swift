//
//  RedundantTypedThrowsTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class RedundantTypedThrowsTests: XCTestCase {
    func testRemovesRedundantNeverTypeThrows() {
        let input = """
        func foo() throws(Never) -> Int {
            0
        }
        """

        let output = """
        func foo() -> Int {
            0
        }
        """

        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, output, rule: .redundantTypedThrows, options: options)
    }

    func testRemovesRedundantAnyErrorTypeThrows() {
        let input = """
        func foo() throws(any Error) -> Int {
            throw MyError.foo
        }
        """

        let output = """
        func foo() throws -> Int {
            throw MyError.foo
        }
        """

        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, output, rule: .redundantTypedThrows, options: options)
    }

    func testDontRemovesNonRedundantErrorTypeThrows() {
        let input = """
        func bar() throws(BarError) -> Foo {
            throw .foo
        }

        func foo() throws(Error) -> Int {
            throw MyError.foo
        }
        """

        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, rule: .redundantTypedThrows, options: options)
    }
}
