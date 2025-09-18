//
//  RedundantAsyncTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 2025-09-18.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class RedundantAsyncTests: XCTestCase {
    func testRemovesAsyncFromXCTestFunction() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() async {
                XCTAssertEqual(1, 1)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                XCTAssertEqual(1, 1)
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantAsync)
    }

    func testRemovesAsyncFromSwiftTestingFunction() {
        let input = """
        import Testing

        @Test func something() async {
            #expect(1 == 1)
        }
        """
        let output = """
        import Testing

        @Test func something() {
            #expect(1 == 1)
        }
        """
        let options = FormatOptions(redundantAsync: .testsOnly)
        testFormatting(for: input, output, rule: .redundantAsync)
    }

    func testIgnoresNonTestFunctionsInTestsOnlyMode() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func helper() async {
                // This is not a test function, should not be modified
            }

            func testHelper() async -> Bool {
                // This is not a test function, should not be modified
                false
            }

            func test_something() async {
                XCTAssertEqual(1, 1)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func helper() async {
                // This is not a test function, should not be modified
            }

            func testHelper() async -> Bool {
                // This is not a test function, should not be modified
                false
            }

            func test_something() {
                XCTAssertEqual(1, 1)
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantAsync)
    }

    func testRemovesAsyncFromAnyFunctionInAlwaysMode() {
        let input = """
        func foo() async -> Int {
            return 0
        }

        init() async -> Int {
            return 0
        }

        subscript(_: String) async -> Int {
            return 0
        }
        """
        let output = """
        func foo() -> Int {
            return 0
        }

        init() -> Int {
            return 0
        }

        subscript(_: String) -> Int {
            return 0
        }
        """
        let options = FormatOptions(redundantAsync: .always)
        testFormatting(for: input, output, rule: .redundantAsync, options: options)
    }

    func testDoesNotModifyOverrideFunctions() {
        let input = """
        class TestCase {
            override func setUpWithError() async {
                // Setup code that doesn't actually await
            }
        }
        """
        let options = FormatOptions(redundantAsync: .always)
        testFormatting(for: input, rule: .redundantAsync, options: options)
    }

    func testPreservesAsyncWhenFunctionContainsAwait() {
        let input = """
        func baz() async -> Int {
            await somethingAsync()
            return 0
        }
        """
        let options = FormatOptions(redundantAsync: .always)
        testFormatting(for: input, rule: .redundantAsync, options: options)
    }

    func testPreservesAsyncWhenFunctionContainsAwaitInControlFlow() {
        let input = """
        func foo() async -> Int {
            if someCondition {
                await somethingAsync()
            }
            return 0
        }
        """
        let options = FormatOptions(redundantAsync: .always)
        testFormatting(for: input, rule: .redundantAsync, options: options)
    }

    func testRemovesAsyncWhenAwaitInNestedClosure() {
        let input = """
        func foo() async -> Int {
            let closure = {
                await somethingAsync()
            }
            return 0
        }
        """
        let output = """
        func foo() -> Int {
            let closure = {
                await somethingAsync()
            }
            return 0
        }
        """
        let options = FormatOptions(redundantAsync: .always)
        testFormatting(for: input, output, rule: .redundantAsync, options: options)
    }

    func testPreservesAsyncWithMultipleAwaitCalls() {
        let input = """
        func foo() async -> Int {
            await firstCall()
            await secondCall()
            return 0
        }
        """
        let options = FormatOptions(redundantAsync: .always)
        testFormatting(for: input, rule: .redundantAsync, options: options)
    }

    func testRemovesAsyncFromAsyncThrowsFunction() {
        let input = """
        func foo() async throws -> Int {
            throw MyError.someError
        }
        """
        let output = """
        func foo() throws -> Int {
            throw MyError.someError
        }
        """
        let options = FormatOptions(redundantAsync: .always)
        testFormatting(for: input, output, rule: .redundantAsync, options: options)
    }

    func testPreservesAsyncInAsyncThrowsWithAwait() {
        let input = """
        func foo() async throws -> Int {
            await someAsyncCall()
            throw MyError.someError
        }
        """
        let options = FormatOptions(redundantAsync: .always)
        testFormatting(for: input, rule: .redundantAsync, options: options)
    }

    func testRemovesAsyncFromInitializer() {
        let input = """
        struct MyStruct {
            init() async {
                // No await calls
            }
        }
        """
        let output = """
        struct MyStruct {
            init() {
                // No await calls
            }
        }
        """
        let options = FormatOptions(redundantAsync: .always)
        testFormatting(for: input, output, rule: .redundantAsync, options: options)
    }

    func testRemovesAsyncFromSubscript() {
        let input = """
        struct MyStruct {
            subscript(key: String) async -> String {
                key
            }
        }
        """
        let output = """
        struct MyStruct {
            subscript(key: String) -> String {
                key
            }
        }
        """
        let options = FormatOptions(redundantAsync: .always)
        testFormatting(for: input, output, rule: .redundantAsync, options: options)
    }

    func testPreservesAsyncInNestedFunction() {
        let input = """
        func outerFunction() async {
            func innerFunction() async {
                await someAsyncCall()
            }

            // No await in outer function body
        }
        """
        let output = """
        func outerFunction() {
            func innerFunction() async {
                await someAsyncCall()
            }

            // No await in outer function body
        }
        """
        let options = FormatOptions(redundantAsync: .always)
        testFormatting(for: input, output, rule: .redundantAsync, options: options)
    }
}
