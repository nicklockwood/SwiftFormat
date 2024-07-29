//
//  RedundantGetTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 11/15/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class RedundantGetTests: XCTestCase {
    func testRemoveSingleLineIsolatedGet() {
        let input = "var foo: Int { get { return 5 } }"
        let output = "var foo: Int { return 5 }"
        testFormatting(for: input, output, rule: .redundantGet)
    }

    func testRemoveMultilineIsolatedGet() {
        let input = "var foo: Int {\n    get {\n        return 5\n    }\n}"
        let output = "var foo: Int {\n    return 5\n}"
        testFormatting(for: input, [output], rules: [.redundantGet, .indent])
    }

    func testNoRemoveMultilineGetSet() {
        let input = "var foo: Int {\n    get { return 5 }\n    set { foo = newValue }\n}"
        testFormatting(for: input, rule: .redundantGet)
    }

    func testNoRemoveAttributedGet() {
        let input = "var enabled: Bool { @objc(isEnabled) get { true } }"
        testFormatting(for: input, rule: .redundantGet)
    }

    func testRemoveSubscriptGet() {
        let input = "subscript(_ index: Int) {\n    get {\n        return lookup(index)\n    }\n}"
        let output = "subscript(_ index: Int) {\n    return lookup(index)\n}"
        testFormatting(for: input, [output], rules: [.redundantGet, .indent])
    }

    func testGetNotRemovedInFunction() {
        let input = "func foo() {\n    get {\n        self.lookup(index)\n    }\n}"
        testFormatting(for: input, rule: .redundantGet)
    }

    func testEffectfulGetNotRemoved() {
        let input = """
        var foo: Int {
            get async throws {
                try await getFoo()
            }
        }
        """
        testFormatting(for: input, rule: .redundantGet)
    }
}
