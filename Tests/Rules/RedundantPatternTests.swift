//
//  RedundantPatternTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 12/14/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class RedundantPatternTests: XCTestCase {
    func testRemoveRedundantPatternInIfCase() {
        let input = """
        if case let .foo(_, _) = bar {}
        """
        let output = """
        if case .foo = bar {}
        """
        testFormatting(for: input, output, rule: .redundantPattern)
    }

    func testNoRemoveRequiredPatternInIfCase() {
        let input = """
        if case (_, _) = bar {}
        """
        testFormatting(for: input, rule: .redundantPattern)
    }

    func testRemoveRedundantPatternInSwitchCase() {
        let input = """
        switch foo {
        case let .bar(_, _): break
        default: break
        }
        """
        let output = """
        switch foo {
        case .bar: break
        default: break
        }
        """
        testFormatting(for: input, output, rule: .redundantPattern)
    }

    func testNoRemoveRequiredPatternLetInSwitchCase() {
        let input = """
        switch foo {
        case let .bar(_, a): break
        default: break
        }
        """
        testFormatting(for: input, rule: .redundantPattern)
    }

    func testNoRemoveRequiredPatternInSwitchCase() {
        let input = """
        switch foo {
        case (_, _): break
        default: break
        }
        """
        testFormatting(for: input, rule: .redundantPattern)
    }

    func testSimplifyLetPattern() {
        let input = """
        let(_, _) = bar
        """
        let output = """
        let _ = bar
        """
        testFormatting(for: input, output, rule: .redundantPattern, exclude: [.redundantLet])
    }

    func testNoRemoveVoidFunctionCall() {
        let input = """
        if case .foo() = bar {}
        """
        testFormatting(for: input, rule: .redundantPattern)
    }

    func testNoRemoveMethodSignature() {
        let input = """
        func foo(_, _) {}
        """
        testFormatting(for: input, rule: .redundantPattern)
    }
}
