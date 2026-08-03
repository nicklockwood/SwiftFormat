//
//  IfExpressionsTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/31/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class IfExpressionsTests: XCTestCase {
    func testSimpleTernaryInFunction() {
        let input = """
        func foo(_ condition: Bool) -> String {
            condition
                ? "foo"
                : "bar"
        }
        """
        let output = """
        func foo(_ condition: Bool) -> String {
            if condition {
                "foo"
            } else {
                "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .ifExpressions, options: options,
                       exclude: [.wrapIfExpressionBodies])
    }

    func testSimpleTernaryInComputedVar() {
        let input = """
        var foo: String {
            condition
                ? "foo"
                : "bar"
        }
        """
        let output = """
        var foo: String {
            if condition {
                "foo"
            } else {
                "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .ifExpressions, options: options,
                       exclude: [.wrapIfExpressionBodies])
    }

    func testTernaryWithReturnKeyword() {
        let input = """
        func foo(_ condition: Bool) -> String {
            return condition
                ? "foo"
                : "bar"
        }
        """
        let output = """
        func foo(_ condition: Bool) -> String {
            if condition {
                "foo"
            } else {
                "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .ifExpressions, options: options,
                       exclude: [.wrapIfExpressionBodies])
    }

    func testTernaryInSubscript() {
        let input = """
        subscript(index: Int) -> String {
            index > 0
                ? "positive"
                : "non-positive"
        }
        """
        let output = """
        subscript(index: Int) -> String {
            if index > 0 {
                "positive"
            } else {
                "non-positive"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .ifExpressions, options: options,
                       exclude: [.wrapIfExpressionBodies])
    }

    func testNestedTernaryInFunction() {
        let input = """
        func foo(_ x: Int) -> String {
            x > 0
                ? "positive"
                : x == 0 ? "zero" : "negative"
        }
        """
        let output = """
        func foo(_ x: Int) -> String {
            if x > 0 {
                "positive"
            } else {
                if x == 0 {
                    "zero"
                } else {
                    "negative"
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .ifExpressions, options: options,
                       exclude: [.wrapIfExpressionBodies])
    }

    func testDoublyNestedTernary() {
        let input = """
        func foo(_ x: Int) -> String {
            x > 10
                ? "big"
                : x > 0
                    ? "small"
                    : x == 0 ? "zero" : "negative"
        }
        """
        let output = """
        func foo(_ x: Int) -> String {
            if x > 10 {
                "big"
            } else {
                if x > 0 {
                    "small"
                } else {
                    if x == 0 {
                        "zero"
                    } else {
                        "negative"
                    }
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .ifExpressions, options: options,
                       exclude: [.wrapIfExpressionBodies])
    }

    func testSingleLineTernaryPreservedByDefault() {
        let input = """
        func foo(_ condition: Bool) -> String {
            condition ? "foo" : "bar"
        }
        """
        let output = """
        func foo(_ condition: Bool) -> String {
            if condition { "foo" } else { "bar" }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .ifExpressions, options: options)
    }

    func testSingleLineTernaryPreservedWithPreserveOption() {
        let input = """
        func foo(_ condition: Bool) -> String {
            condition ? "foo" : "bar"
        }
        """
        let options = FormatOptions(singleLineTernary: .preserve, swiftVersion: "5.9")
        testFormatting(for: input, rule: .ifExpressions, options: options)
    }

    func testSingleLineTernaryConvertedToSingleLineIfExpression() {
        let input = """
        func foo(_ condition: Bool) -> String {
            condition ? "foo" : "bar"
        }
        """
        let output = """
        func foo(_ condition: Bool) -> String {
            if condition { "foo" } else { "bar" }
        }
        """
        let options = FormatOptions(singleLineTernary: .convert, swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .ifExpressions, options: options,
                       exclude: [.wrapIfExpressionBodies])
    }

    func testSingleLineTernaryConvertWithWrapIfExpressionBodies() {
        let input = """
        func foo(_ condition: Bool) -> String {
            condition ? "foo" : "bar"
        }
        """
        let output = """
        func foo(_ condition: Bool) -> String {
            if condition {
                "foo"
            } else {
                "bar"
            }
        }
        """
        let options = FormatOptions(singleLineTernary: .convert, swiftVersion: "5.9")
        testFormatting(for: input, [output], rules: [.ifExpressions, .indent, .wrapIfExpressionBodies],
                       options: options)
    }

    func testMultiLineTernaryConverted() {
        let input = """
        func foo(_ condition: Bool) -> String {
            condition
                ? "foo"
                : "bar"
        }
        """
        let output = """
        func foo(_ condition: Bool) -> String {
            if condition {
                "foo"
            } else {
                "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output], rules: [.ifExpressions, .indent], options: options,
                       exclude: [.wrapIfExpressionBodies])
    }

    func testDoesNotConvertTernaryInClosure() {
        let input = """
        let foo = items.map { $0 > 0 ? "positive" : "negative" }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .ifExpressions, options: options)
    }

    func testDoesNotConvertTernaryPreSwift5_9() {
        let input = """
        func foo(_ condition: Bool) -> String {
            condition ? "foo" : "bar"
        }
        """
        let options = FormatOptions(swiftVersion: "5.8")
        testFormatting(for: input, rule: .ifExpressions, options: options)
    }

    func testDoesNotConvertTernaryInVoidFunction() {
        let input = """
        func foo(_ condition: Bool) {
            condition ? doSomething() : doSomethingElse()
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .ifExpressions, options: options)
    }

    func testDoesNotConvertTernaryInMultiStatementFunction() {
        let input = """
        func foo(_ condition: Bool) -> String {
            let x = "hello"
            return condition ? x : "world"
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .ifExpressions, options: options)
    }

    func testDoesNotConvertTernaryWithOpaqueReturnType() {
        let input = """
        func foo(_ condition: Bool) -> some View {
            condition
                ? Text("foo")
                : Text("bar")
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .ifExpressions, options: options)
    }

    func testDoesNotConvertTernaryWithOpaqueVarType() {
        let input = """
        var body: some View {
            condition
                ? Text("foo")
                : Text("bar")
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .ifExpressions, options: options)
    }

    func testMultiLineTernaryWithIndent() {
        let input = """
        func foo(_ condition: Bool) -> String {
            condition
                ? "foo"
                : "bar"
        }
        """
        let output = """
        func foo(_ condition: Bool) -> String {
            if condition {
                "foo"
            } else {
                "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output], rules: [.ifExpressions, .indent], options: options,
                       exclude: [.wrapIfExpressionBodies])
    }

    func testDoesNotConvertTernaryWithTrailingClosureInCondition() {
        let input = """
        func foo(_ channels: [Channel]) -> String {
            channels.contains { $0.property == .color }
                ? "has color"
                : "no color"
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .ifExpressions, options: options)
    }

    func testDoesNotConvertSingleLineTernaryWithTrailingClosureInCondition() {
        let input = """
        func foo(_ channels: [Channel]) -> String {
            channels.contains { $0.property == .color } ? "has color" : "no color"
        }
        """
        let options = FormatOptions(singleLineTernary: .convert, swiftVersion: "5.9")
        testFormatting(for: input, rule: .ifExpressions, options: options)
    }

    func testConvertsTernaryWithClosureInsideParens() {
        let input = """
        func foo(_ channels: [Channel]) -> String {
            channels.contains(where: { $0.property == .color })
                ? "has color"
                : "no color"
        }
        """
        let output = """
        func foo(_ channels: [Channel]) -> String {
            if channels.contains(where: { $0.property == .color }) {
                "has color"
            } else {
                "no color"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .ifExpressions, options: options,
                       exclude: [.wrapIfExpressionBodies])
    }

    func testTernaryInsideIfExpressionBranch() {
        let input = """
        private var contentOpacity: Double {
            if screenshotTestsEnabled {
                1.0
            } else {
                isMinimized ? 0.0 : 1.0
            }
        }
        """
        let output = """
        private var contentOpacity: Double {
            if screenshotTestsEnabled {
                1.0
            } else {
                if isMinimized {
                    0.0
                } else {
                    1.0
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .ifExpressions, options: options,
                       exclude: [.wrapIfExpressionBodies])
    }

    func testTernaryInsideIfExpressionBranchWithPreserveOption() {
        let input = """
        private var contentOpacity: Double {
            if screenshotTestsEnabled {
                1.0
            } else {
                isMinimized ? 0.0 : 1.0
            }
        }
        """
        let output = """
        private var contentOpacity: Double {
            if screenshotTestsEnabled {
                1.0
            } else {
                if isMinimized {
                    0.0
                } else {
                    1.0
                }
            }
        }
        """
        let options = FormatOptions(singleLineTernary: .preserve, swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .ifExpressions, options: options,
                       exclude: [.wrapIfExpressionBodies])
    }

    func testTernaryInBothIfExpressionBranches() {
        let input = """
        func foo(_ x: Bool, _ y: Bool) -> String {
            if x {
                y ? "a" : "b"
            } else {
                y ? "c" : "d"
            }
        }
        """
        let output = """
        func foo(_ x: Bool, _ y: Bool) -> String {
            if x {
                if y {
                    "a"
                } else {
                    "b"
                }
            } else {
                if y {
                    "c"
                } else {
                    "d"
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .ifExpressions, options: options,
                       exclude: [.wrapIfExpressionBodies])
    }

    func testTernaryInElseIfBranch() {
        let input = """
        func foo(_ x: Int) -> String {
            if x > 0 {
                "positive"
            } else if x == 0 {
                "zero"
            } else {
                x < -10 ? "very negative" : "negative"
            }
        }
        """
        let output = """
        func foo(_ x: Int) -> String {
            if x > 0 {
                "positive"
            } else if x == 0 {
                "zero"
            } else {
                if x < -10 {
                    "very negative"
                } else {
                    "negative"
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .ifExpressions, options: options,
                       exclude: [.wrapIfExpressionBodies])
    }

    func testNoConversionForNonTernaryIfBranches() {
        let input = """
        var foo: String {
            if condition {
                "hello"
            } else {
                "world"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .ifExpressions, options: options)
    }
}
