//
//  RedundantGetTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 11/15/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class RedundantGetTests: XCTestCase {
    func testRemoveSingleLineIsolatedGet() {
        let input = """
        var foo: Int { get { return 5 } }
        """
        let output = """
        var foo: Int { return 5 }
        """
        testFormatting(for: input, output, rule: .redundantGet, exclude: [.wrapSingleLineBodies])
    }

    func testRemoveMultilineIsolatedGet() {
        let input = """
        var foo: Int {
            get {
                return 5
            }
        }
        """
        let output = """
        var foo: Int {
            return 5
        }
        """
        testFormatting(for: input, [output], rules: [.redundantGet, .indent])
    }

    func testNoRemoveMultilineGetSet() {
        let input = """
        var foo: Int {
            get { return 5 }
            set { foo = newValue }
        }
        """
        testFormatting(for: input, rule: .redundantGet)
    }

    func testNoRemoveAttributedGet() {
        let input = """
        var enabled: Bool { @objc(isEnabled) get { true } }
        """
        testFormatting(for: input, rule: .redundantGet, exclude: [.wrapSingleLineBodies])
    }

    func testRemoveSubscriptGet() {
        let input = """
        subscript(_ index: Int) {
            get {
                return lookup(index)
            }
        }
        """
        let output = """
        subscript(_ index: Int) {
            return lookup(index)
        }
        """
        testFormatting(for: input, [output], rules: [.redundantGet, .indent])
    }

    func testGetNotRemovedInFunction() {
        let input = """
        func foo() {
            get {
                self.lookup(index)
            }
        }
        """
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
