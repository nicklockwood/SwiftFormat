//
//  EmptyExtensionTests.swift
//  SwiftFormatTests
//
//  Created by Manny Lopez on 7/30/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class EmptyExtensionTests: XCTestCase {
    func testRemoveEmptyExtension() {
        let input = """
        extension String {}

        extension String: Equatable {}
        """
        let output = """
        extension String: Equatable {}
        """
        testFormatting(for: input, output, rule: .emptyExtension)
    }

    func testRemoveNonConformingEmptyExtension() {
        let input = """
        extension [Foo: Bar] {}

        extension Array where Element: Foo {}
        """
        let output = ""
        testFormatting(for: input, output, rule: .emptyExtension)
    }

    func testDoNotRemoveEmptyConformingExtension() {
        let input = """
        extension String: Equatable {}
        """
        testFormatting(for: input, rule: .emptyExtension)
    }

    func testDoNotRemoveAtModifierEmptyExtension() {
        let input = """
        @GenerateBoilerPlate
        extension Foo {}
        """
        testFormatting(for: input, rule: .emptyExtension)
    }

    func testRemoveEmptyExtensionWithEmptyBody() {
        let input = """
        extension Foo { }

        extension Foo {

        }
        """
        let output = ""
        testFormatting(for: input, output, rule: .emptyExtension)
    }

    func testRemoveUnusedPrivateDeclarationThenEmptyExtension() {
        let input = """
        class Foo {
            init() {}
        }
        extension Foo {
            private var bar: Bar { "bar" }
        }
        """

        let output = """
        class Foo {
            init() {}
        }

        """
        testFormatting(for: input, [output], rules: [.unusedPrivateDeclaration, .emptyExtension])
    }
}
