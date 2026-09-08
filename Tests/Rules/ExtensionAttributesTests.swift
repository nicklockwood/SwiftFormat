//
//  ExtensionAttributesTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 9/8/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class ExtensionAttributesTests: XCTestCase {
    func testHoistsMainActorAttributeToPreviousLineByDefault() {
        let input = """
        extension Foo {
            @MainActor func bar() {}
            @MainActor func baz() {}
        }
        """

        let output = """
        @MainActor
        extension Foo {
            func bar() {}
            func baz() {}
        }
        """

        testFormatting(for: input, output, rule: .extensionAttributes)
    }

    func testHoistsMainActorAttributeToSameLineIfConfigured() {
        let input = """
        extension Foo {
            @MainActor func bar() {}
            @MainActor func baz() {}
        }
        """

        let output = """
        @MainActor extension Foo {
            func bar() {}
            func baz() {}
        }
        """

        testFormatting(
            for: input, output, rule: .extensionAttributes,
            options: FormatOptions(typeAttributes: .sameLine)
        )
    }

    func testHoistsAvailableAttribute() {
        let input = """
        extension Foo {
            @available(iOS 17.0, *)
            func bar() {}

            @available(iOS 17.0, *)
            var baz: Int { 0 }
        }
        """

        let output = """
        @available(iOS 17.0, *)
        extension Foo {
            func bar() {}

            var baz: Int { 0 }
        }
        """

        testFormatting(for: input, output, rule: .extensionAttributes, exclude: [.wrapPropertyBodies])
    }

    func testRemovesRedundantAttributesWhenExtensionAlreadyHasAttribute() {
        let input = """
        @MainActor extension Foo {
            @MainActor func bar() {}
            @MainActor func baz() {}
        }
        """

        let output = """
        @MainActor extension Foo {
            func bar() {}
            func baz() {}
        }
        """

        testFormatting(for: input, output, rule: .extensionAttributes)
    }

    func testHoistsMainActorAttributeToPreviousLineIfConfigured() {
        let input = """
        extension Foo {
            @MainActor func bar() {}
            @MainActor func baz() {}
        }
        """

        let output = """
        @MainActor
        extension Foo {
            func bar() {}
            func baz() {}
        }
        """

        testFormatting(
            for: input, output, rule: .extensionAttributes,
            options: FormatOptions(typeAttributes: .prevLine)
        )
    }

    func testDoesntHoistAttributeNotOnAllMembers() {
        let input = """
        extension Foo {
            @MainActor func bar() {}
            func baz() {}
        }
        """

        testFormatting(for: input, rule: .extensionAttributes)
    }

    func testDoesntHoistDifferentAvailableAttributes() {
        let input = """
        extension Foo {
            @available(iOS 17.0, *) func bar() {}
            @available(iOS 18.0, *) func baz() {}
        }
        """

        testFormatting(for: input, rule: .extensionAttributes)
    }

    func testDoesntHoistUnsupportedAttribute() {
        let input = """
        extension Foo {
            @discardableResult func bar() -> Int { 0 }
            @discardableResult func baz() -> Int { 0 }
        }
        """

        testFormatting(for: input, rule: .extensionAttributes, exclude: [.wrapFunctionBodies])
    }

    func testDoesntHoistObjcAttribute() {
        let input = """
        extension Foo {
            @objc func bar() {}
            @objc(bazWithValue:) func baz(value: Int) {}
        }
        """

        testFormatting(for: input, rule: .extensionAttributes, exclude: [.unusedArguments])
    }

    func testDoesntHoistAttributesOntoConformingExtension() {
        let input = """
        extension Foo: Bar {
            @MainActor func bar() {}
            @MainActor func baz() {}
        }
        """

        testFormatting(for: input, rule: .extensionAttributes)
    }

    func testHoistsAttributeWithConditionalCompilationMembers() {
        let input = """
        extension Foo {
            #if DEBUG
                @MainActor func bar() {}
            #else
                @MainActor func baz() {}
            #endif
        }
        """

        let output = """
        @MainActor
        extension Foo {
            #if DEBUG
                func bar() {}
            #else
                func baz() {}
            #endif
        }
        """

        testFormatting(for: input, output, rule: .extensionAttributes)
    }

    func testDoesntRemoveAttributeWithTrailingComment() {
        let input = """
        extension Foo {
            @MainActor // required
            func bar() {}

            @MainActor
            func baz() {}
        }
        """

        let output = """
        @MainActor
        extension Foo {
            @MainActor // required
            func bar() {}

            func baz() {}
        }
        """

        testFormatting(for: input, output, rule: .extensionAttributes)
    }
}
