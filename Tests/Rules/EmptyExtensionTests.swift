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
    // MARK: - emptyExtension

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
}
