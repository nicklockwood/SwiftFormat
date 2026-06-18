//
//  WrapIfExpressionBodiesTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 6/10/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class WrapIfExpressionBodiesTests: XCTestCase {
    func testIfExpressionFollowingAssignmentWraps() {
        let input = """
        let foo = if condition { bar } else { baz }
        """
        let output = """
        let foo = if condition {
            bar
        } else {
            baz
        }
        """
        testFormatting(for: input, output, rule: .wrapIfExpressionBodies,
                       exclude: [.wrapMultilineConditionalAssignment])
    }

    func testIfExpressionInFunctionBodyWraps() {
        let input = """
        func foo() -> String {
            if condition { "bar" } else { "baz" }
        }
        """
        let output = """
        func foo() -> String {
            if condition {
                "bar"
            } else {
                "baz"
            }
        }
        """
        testFormatting(for: input, output, rule: .wrapIfExpressionBodies)
    }

    func testIfExpressionInVarBodyWraps() {
        let input = """
        var foo: String {
            if condition { "bar" } else { "baz" }
        }
        """
        let output = """
        var foo: String {
            if condition {
                "bar"
            } else {
                "baz"
            }
        }
        """
        testFormatting(for: input, output, rule: .wrapIfExpressionBodies)
    }

    func testIfExpressionInClosureBodyWraps() {
        let input = """
        let foo = items.map { if $0 > 0 { "positive" } else { "negative" } }
        """
        let output = """
        let foo = items.map { if $0 > 0 {
            "positive"
        } else {
            "negative"
        } }
        """
        testFormatting(for: input, output, rule: .wrapIfExpressionBodies)
    }

    func testNestedIfExpressionWraps() {
        let input = """
        let foo = if condition1 { if condition2 { "a" } else { "b" } } else { "c" }
        """
        let output = """
        let foo = if condition1 {
            if condition2 {
                "a"
            } else {
                "b"
            }
        } else {
            "c"
        }
        """
        testFormatting(for: input, output, rule: .wrapIfExpressionBodies,
                       exclude: [.wrapMultilineConditionalAssignment])
    }

    func testIfExpressionWithTryWraps() {
        let input = """
        let foo = try if condition { bar } else { baz }
        """
        let output = """
        let foo = try if condition {
            bar
        } else {
            baz
        }
        """
        testFormatting(for: input, output, rule: .wrapIfExpressionBodies,
                       exclude: [.wrapMultilineConditionalAssignment])
    }

    func testIfExpressionAlreadyWrappedUnchanged() {
        let input = """
        let foo = if condition {
            bar
        } else {
            baz
        }
        """
        testFormatting(for: input, rule: .wrapIfExpressionBodies,
                       exclude: [.wrapMultilineConditionalAssignment])
    }

    func testDoesNotWrapIfStatement() {
        let input = """
        if foo { return bar } else { return baz }
        """
        testFormatting(for: input, rule: .wrapIfExpressionBodies,
                       exclude: [.wrapIfStatementBodies])
    }

    func testDoesNotWrapGuardStatement() {
        let input = """
        guard let foo = bar else { return }
        """
        testFormatting(for: input, rule: .wrapIfExpressionBodies,
                       exclude: [.wrapGuardStatementBodies])
    }

    func testIfExpressionWithElseIfWraps() {
        let input = """
        let foo = if condition1 { "a" } else if condition2 { "b" } else { "c" }
        """
        let output = """
        let foo = if condition1 {
            "a"
        } else if condition2 {
            "b"
        } else {
            "c"
        }
        """
        testFormatting(for: input, output, rule: .wrapIfExpressionBodies,
                       exclude: [.wrapMultilineConditionalAssignment])
    }

    func testDoesNotWrapIfStatementInVoidFunction() {
        let input = """
        private func setTitleText(_ titleText: StylableText?) {
            if let titleText { titleText.set(on: titleLabel) }
            else { titleLabel.text = nil }
        }
        """
        testFormatting(for: input, rule: .wrapIfExpressionBodies,
                       exclude: [.wrapIfStatementBodies, .elseOnSameLine])
    }

    func testDoesNotWrapIfWithoutElseBranch() {
        let input = """
        for subview in root.subviews {
            if let found = findView(withIdentifier: id, in: subview) { return found }
        }
        """
        testFormatting(for: input, rule: .wrapIfExpressionBodies,
                       exclude: [.wrapIfStatementBodies])
    }

    func testDoesNotWrapIfStatementInForLoop() {
        let input = """
        for item in items {
            if item.isValid { process(item) } else { skip(item) }
        }
        """
        testFormatting(for: input, rule: .wrapIfExpressionBodies,
                       exclude: [.wrapIfStatementBodies])
    }
}
