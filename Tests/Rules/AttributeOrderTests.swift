//
//  AttributeOrderTests.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 16/11/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class AttributeOrderTests: XCTestCase {
    func testDefaultOrder() {
        let input = """
        @objc
        @discardableResult
        @available(iOS 15, *)
        func update() -> Bool {
            true
        }
        """
        let output = """
        @available(iOS 15, *)
        @discardableResult
        @objc
        func update() -> Bool {
            true
        }
        """
        testFormatting(for: input, output, rule: .attributeOrder)
    }

    func testInlineAttributes() {
        let input = """
        @objc @MainActor @available(iOS 15, *) func update() {}
        """
        let output = """
        @available(iOS 15, *) @MainActor @objc func update() {}
        """
        testFormatting(for: input, output, rule: .attributeOrder)
    }

    func testAlreadyOrderedAttributes() {
        let input = """
        @available(iOS 15, *)
        @discardableResult
        @MainActor
        @objc
        func update() -> Bool {
            true
        }
        """
        testFormatting(for: input, rule: .attributeOrder)
    }

    func testRepeatedAttributesRemainStable() {
        let input = """
        @objc
        @available(macOS 12, *)
        @available(iOS 15, *)
        func update() {}
        """
        let output = """
        @available(macOS 12, *)
        @available(iOS 15, *)
        @objc
        func update() {}
        """
        testFormatting(for: input, output, rule: .attributeOrder)
    }

    func testUnknownMacroSeparatesOrderedRuns() {
        let input = """
        @objc @MainActor
        @CustomMacro("A long argument should not affect attribute order")
        @discardableResult @available(iOS 15, *)
        func update() -> Bool {
            true
        }
        """
        let output = """
        @MainActor @objc
        @CustomMacro("A long argument should not affect attribute order")
        @available(iOS 15, *) @discardableResult
        func update() -> Bool {
            true
        }
        """
        testFormatting(for: input, output, rule: .attributeOrder)
    }

    func testPropertyWrappersAreBoundaries() {
        let input = """
        struct Example {
            @MainActor
            @Outer @Inner
            @available(iOS 15, *)
            var value: Int
        }
        """
        testFormatting(for: input, rule: .attributeOrder)
    }

    func testCustomOrderPreservesExplicitOrder() {
        let input = """
        @available(iOS 15, *) @MainActor @Test("An arbitrarily long test description")
        func example() {}
        """
        let output = """
        @Test("An arbitrarily long test description") @MainActor @available(iOS 15, *)
        func example() {}
        """
        let options = FormatOptions(attributeOrder: ["Test", "MainActor", "available"])
        testFormatting(for: input, output, rule: .attributeOrder, options: options)
    }

    func testCustomOrderInsertsOmittedDefaults() {
        let input = """
        @MainActor @objc @discardableResult @available(iOS 15, *)
        func update() -> Bool {
            true
        }
        """
        let output = """
        @available(iOS 15, *) @discardableResult @objc @MainActor
        func update() -> Bool {
            true
        }
        """
        let options = FormatOptions(attributeOrder: ["objc", "MainActor"])
        testFormatting(for: input, output, rule: .attributeOrder, options: options)
    }

    func testNamedAttributeBeforeWildcard() {
        let input = """
        @CustomMacro("Custom") @available(iOS 15, *) @MainActor @objc
        func update() {}
        """
        let output = """
        @MainActor @CustomMacro("Custom") @available(iOS 15, *) @objc
        func update() {}
        """
        let options = FormatOptions(attributeOrder: ["@MainActor", "*"])
        testFormatting(for: input, output, rule: .attributeOrder, options: options)
    }

    func testNamedAttributesAfterWildcardPreserveWrapperOrder() {
        let input = """
        struct Example {
            @MainActor @Outer("Example") @available(iOS 15, *) @Inner
            var value: Int
        }
        """
        let output = """
        struct Example {
            @Outer("Example") @Inner @MainActor @available(iOS 15, *)
            var value: Int
        }
        """
        let options = FormatOptions(attributeOrder: ["*", "MainActor", "available"])
        testFormatting(for: input, output, rule: .attributeOrder, options: options)
    }

    func testMultilineMacroArgumentsMoveIntact() {
        let input = """
        @MainActor
        @Test(
            "A test with nested argument expressions",
            arguments: [Example(value: 1), Example(value: 2)]
        )
        func example(value: Example) {}
        """
        let output = """
        @Test(
            "A test with nested argument expressions",
            arguments: [Example(value: 1), Example(value: 2)]
        )
        @MainActor
        func example(value: Example) {}
        """
        let options = FormatOptions(stripUnusedArguments: .closureOnly, attributeOrder: ["Test", "MainActor"])
        testFormatting(for: input, output, rule: .attributeOrder, options: options)
    }

    func testQualifiedAndGenericAttributes() {
        let input = """
        @MainActor @Testing.Test("Example") @Example.Builder<String>
        func example() {}
        """
        let output = """
        @Example.Builder<String> @Testing.Test("Example") @MainActor
        func example() {}
        """
        let options = FormatOptions(attributeOrder: ["Example.Builder", "Testing.Test", "MainActor"])
        testFormatting(for: input, output, rule: .attributeOrder, options: options)
    }

    func testQualifiedNameDoesNotMatchUnqualifiedName() {
        let input = """
        @MainActor @Other.Test @available(iOS 15, *) func example() {}
        """
        let options = FormatOptions(attributeOrder: ["available", "Test", "MainActor"])
        testFormatting(for: input, rule: .attributeOrder, options: options)
    }

    func testCommentsAreBoundaries() {
        let input = """
        @objc // Objective-C entry point
        @MainActor /* Availability of this entry point */
        @available(iOS 15, *)
        func update() {}
        """
        testFormatting(for: input, rule: .attributeOrder)
    }

    func testTrailingCommentStaysWithAttribute() {
        let input = """
        @objc
        @available(iOS 15, *) // Introduced with the new API
        func update() {}
        """
        testFormatting(for: input, rule: .attributeOrder)
    }

    func testCommentInArgumentsPreventsReordering() {
        let input = """
        @objc
        @available(iOS 15, /* minimum version */ *)
        func update() {}
        """
        testFormatting(for: input, rule: .attributeOrder)
    }

    func testDoesNotOrderTypeAttributes() {
        let input = """
        var callback: @MainActor @Sendable () -> Void
        """
        let options = FormatOptions(attributeOrder: ["Sendable", "MainActor"])
        testFormatting(for: input, rule: .attributeOrder, options: options)
    }

    func testDisableNextAttribute() {
        let input = """
        // swiftformat:disable:next attributeOrder
        @objc
        @available(iOS 15, *)
        func update() {}
        """
        testFormatting(for: input, rule: .attributeOrder)
    }

    func testWrappingRemainsIndependent() {
        let input = """
        @objc @available(iOS 15, *) func update() {}
        """
        let output = """
        @available(iOS 15, *) @objc
        func update() {}
        """
        let options = FormatOptions(funcAttributes: .prevLine)
        testFormatting(for: input, [output], rules: [.attributeOrder, .wrapAttributes], options: options)
    }
}
