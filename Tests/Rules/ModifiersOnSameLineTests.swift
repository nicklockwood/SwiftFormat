//
//  ModifiersOnSameLineTests.swift
//  SwiftFormatTests
//
//  Created by cal_stephens on 5/29/25.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class ModifiersOnSameLineTests: XCTestCase {
    // MARK: - modifiersOnSameLine

    func testModifiersOnSeparateLinesAreCombined() {
        let input = """
        public
        private(set)
        var foo: Foo
        """
        let output = """
        public private(set) var foo: Foo
        """
        testFormatting(for: input, output, rule: .modifiersOnSameLine)
    }

    func testSingleModifierOnSeparateLineIsCombined() {
        let input = """
        public
        var foo: Foo
        """
        let output = """
        public var foo: Foo
        """
        testFormatting(for: input, output, rule: .modifiersOnSameLine)
    }

    func testNonisolatedModifierOnSeparateLineIsCombined() {
        let input = """
        nonisolated
        func bar() {}
        """
        let output = """
        nonisolated func bar() {}
        """
        testFormatting(for: input, output, rule: .modifiersOnSameLine)
    }

    func testMultipleModifiersOnMultipleLinesAreCombined() {
        let input = """
        class Container {
            public
            static
            final
            var foo: String = ""
        }
        """
        let output = """
        class Container {
            public static final var foo: String = ""
        }
        """
        testFormatting(for: input, output, rule: .modifiersOnSameLine, exclude: [.modifierOrder])
    }

    func testAttributesCanRemainOnSeparateLines() {
        let input = """
        @MainActor
        public var foo: Foo
        """
        testFormatting(for: input, rule: .modifiersOnSameLine)
    }

    func testAttributesOnSeparateLinesWithModifiersOnSeparateLines() {
        let input = """
        @MainActor
        public
        private(set)
        var foo: Foo
        """
        let output = """
        @MainActor
        public private(set) var foo: Foo
        """
        testFormatting(for: input, output, rule: .modifiersOnSameLine)
    }

    func testMultipleAttributesCanRemainOnSeparateLines() {
        let input = """
        @MainActor
        @Published
        public var foo: Foo
        """
        testFormatting(for: input, rule: .modifiersOnSameLine)
    }

    func testModifiersAlreadyOnSameLineAreNotChanged() {
        let input = """
        public private(set) var foo: Foo
        """
        testFormatting(for: input, rule: .modifiersOnSameLine)
    }

    func testCommentsArePreserved() {
        let input = """
        public
        // This is private setter
        private(set)
        var foo: Foo
        """
        testFormatting(for: input, rule: .modifiersOnSameLine, exclude: [.docComments, .docCommentsBeforeModifiers])
    }

    func testDeclarationWithoutModifiersIsNotChanged() {
        let input = """
        var foo: Foo
        func bar() {}
        class Baz {}
        """
        testFormatting(for: input, rule: .modifiersOnSameLine)
    }

    func testOnlyAttributesWithoutModifiers() {
        let input = """
        @MainActor
        var foo: Foo
        """
        testFormatting(for: input, rule: .modifiersOnSameLine)
    }

    func testModifiersInStructDeclaration() {
        let input = """
        public
        struct MyStruct {
            private
            var value: Int
        }
        """
        let output = """
        public struct MyStruct {
            private var value: Int
        }
        """
        testFormatting(for: input, output, rule: .modifiersOnSameLine)
    }

    func testModifiersInProtocolDeclaration() {
        let input = """
        public
        protocol MyProtocol {
            static
            func someMethod()
        }
        """
        let output = """
        public protocol MyProtocol {
            static func someMethod()
        }
        """
        testFormatting(for: input, output, rule: .modifiersOnSameLine)
    }

    func testModifiersWithComplexAccessControl() {
        let input = """
        public
        private(set)
        var complexProperty: String
        """
        let output = """
        public private(set) var complexProperty: String
        """
        testFormatting(for: input, output, rule: .modifiersOnSameLine)
    }

    func testDoesNotConfusePropertyIdentifierWithModifier() {
        let input = """
        @Environment(\\.rowPaddingOverride) private var override
        private var resolvedRowPadding: AdaptiveEdgeInsets
        """
        testFormatting(for: input, rule: .modifiersOnSameLine)
    }

    func testDoesNotUnwrapWhenLineWouldExceedMaxWidth() {
        let input = """
        public private(set)
        var propertyWithAReallyLongNameExceedingWidth: T
        """
        let options = FormatOptions(maxWidth: 50)
        testFormatting(for: input, rule: .modifiersOnSameLine, options: options)
    }
}
