//
//  EmptyExtensionTests.swift
//  SwiftFormatTests
//
//  Created by manny_lopez on 7/28/2024.
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
}
