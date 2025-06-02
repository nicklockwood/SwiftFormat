// Created by Andy Bartholomew on 5/30/25.
// Copyright © 2025 Airbnb Inc. All rights reserved.

import XCTest

final class ThrowingTestsTests: XCTestCase {
    func testTestCaseIsUpdated_for_Testing() throws {
        let input = """
        import Testing

        @Test func something() {
            try! somethingThatThrows()
        }
        """
        let output = """
        import Testing

        @Test func something() throws {
            try somethingThatThrows()
        }
        """
        testFormatting(for: input, output, rule: .throwingTests)
    }

    func testTestCaseIsUpdated_for_XCTest() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                try! somethingThatThrows()
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                try somethingThatThrows()
            }
        }
        """
        testFormatting(for: input, output, rule: .throwingTests)
    }

    func testTestCaseIsUpdated_for_async_test() throws {
        let input = """
        import Testing

        @Test func something() async {
            try! somethingThatThrows()
        }
        """
        let output = """
        import Testing

        @Test func something() throws async {
            try somethingThatThrows()
        }
        """
        testFormatting(for: input, output, rule: .throwingTests)
    }

    func testTestCaseIsUpdated_for_already_throws() throws {
        let input = """
        import Testing

        @Test func something() throws {
            try! somethingThatThrows()
        }
        """
        let output = """
        import Testing

        @Test func something() throws {
            try somethingThatThrows()
        }
        """
        testFormatting(for: input, output, rule: .throwingTests)
    }

    func testTestCaseIsUpdated_for_multiple_try_exclamationMarks() throws {
        let input = """
        import Testing

        @Test func something() {
            try! somethingThatThrows()
            try! somethingThatThrows()
        }
        """
        let output = """
        import Testing

        @Test func something() throws {
            try somethingThatThrows()
            try somethingThatThrows()
        }
        """
        testFormatting(for: input, output, rule: .throwingTests)
    }

    func testTestCaseIsNotUpdated_for_try_exclamationMark_in_closoure() throws {
        let input = """
        import Testing

        @Test func something() {
            someFunction {
                try! somethingThatThrows()
            }
        }
        """
        testFormatting(for: input, rule: .throwingTests)
    }

    func testTestCaseIsUpdated_for_try_exclamationMark_in_if_statement() throws {
        let input = """
        import Testing

        @Test func something() {
            if condition {
                try! somethingThatThrows()
            }
        }
        """
        let output = """
        import Testing

        @Test func something() throws {
            if condition {
                try somethingThatThrows()
            }
        }
        """
        testFormatting(for: input, output, rule: .throwingTests)
    }

    func testCaseIsNotUpdated_for_try_exclamationMark_in_closure_inside_if_statement() throws {
        let input = """
        import Testing

        @Test func something() {
            doSomething {
                if condition {
                    try! somethingThatThrows()
                }
            }
        }
        """
        testFormatting(for: input, rule: .throwingTests)
    }
}
