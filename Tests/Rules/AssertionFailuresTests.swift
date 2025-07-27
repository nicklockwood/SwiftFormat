//
//  AssertionFailuresTests.swift
//  SwiftFormatTests
//
//  Created by sanjanapruthi on 9/28/21.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class AssertionFailuresTests: XCTestCase {
    func testAssertionFailuresForAssertFalse() {
        let input = """
        assert(false)
        """
        let output = """
        assertionFailure()
        """
        testFormatting(for: input, output, rule: .assertionFailures)
    }

    func testAssertionFailuresForAssertFalseWithSpaces() {
        let input = """
        assert ( false )
        """
        let output = """
        assertionFailure()
        """
        testFormatting(for: input, output, rule: .assertionFailures)
    }

    func testAssertionFailuresForAssertFalseWithLinebreaks() {
        let input = """
        assert(
            false
        )
        """
        let output = """
        assertionFailure()
        """
        testFormatting(for: input, output, rule: .assertionFailures)
    }

    func testAssertionFailuresForAssertTrue() {
        let input = """
        assert(true)
        """
        testFormatting(for: input, rule: .assertionFailures)
    }

    func testAssertionFailuresForAssertFalseWithArgs() {
        let input = """
        assert(false, msg, 20, 21)
        """
        let output = """
        assertionFailure(msg, 20, 21)
        """
        testFormatting(for: input, output, rule: .assertionFailures)
    }

    func testAssertionFailuresForPreconditionFalse() {
        let input = """
        precondition(false)
        """
        let output = """
        preconditionFailure()
        """
        testFormatting(for: input, output, rule: .assertionFailures)
    }

    func testAssertionFailuresForPreconditionTrue() {
        let input = """
        precondition(true)
        """
        testFormatting(for: input, rule: .assertionFailures)
    }

    func testAssertionFailuresForPreconditionFalseWithArgs() {
        let input = """
        precondition(false, msg, 0, 1)
        """
        let output = """
        preconditionFailure(msg, 0, 1)
        """
        testFormatting(for: input, output, rule: .assertionFailures)
    }
}
