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
        let input = "if case let .foo(_, _) = bar {}"
        let output = "if case .foo = bar {}"
        testFormatting(for: input, output, rule: .redundantPattern)
    }

    func testNoRemoveRequiredPatternInIfCase() {
        let input = "if case (_, _) = bar {}"
        testFormatting(for: input, rule: .redundantPattern)
    }

    func testRemoveRedundantPatternInSwitchCase() {
        let input = "switch foo {\ncase let .bar(_, _): break\ndefault: break\n}"
        let output = "switch foo {\ncase .bar: break\ndefault: break\n}"
        testFormatting(for: input, output, rule: .redundantPattern)
    }

    func testNoRemoveRequiredPatternLetInSwitchCase() {
        let input = "switch foo {\ncase let .bar(_, a): break\ndefault: break\n}"
        testFormatting(for: input, rule: .redundantPattern)
    }

    func testNoRemoveRequiredPatternInSwitchCase() {
        let input = "switch foo {\ncase (_, _): break\ndefault: break\n}"
        testFormatting(for: input, rule: .redundantPattern)
    }

    func testSimplifyLetPattern() {
        let input = "let(_, _) = bar"
        let output = "let _ = bar"
        testFormatting(for: input, output, rule: .redundantPattern, exclude: [.redundantLet])
    }

    func testNoRemoveVoidFunctionCall() {
        let input = "if case .foo() = bar {}"
        testFormatting(for: input, rule: .redundantPattern)
    }

    func testNoRemoveMethodSignature() {
        let input = "func foo(_, _) {}"
        testFormatting(for: input, rule: .redundantPattern)
    }
}
