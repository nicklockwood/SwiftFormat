//
//  WrapPropertyBodiesTests.swift
//  SwiftFormatTests
//
//  Created by Manuel Lopez on 12/15/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class WrapPropertyBodiesTests: XCTestCase {
    // MARK: - Computed Properties

    func testWrapSingleLineComputedProperty() {
        let input = """
        var bar: String { "bar" }
        """
        let output = """
        var bar: String {
            "bar"
        }
        """
        testFormatting(for: input, output, rule: .wrapPropertyBodies)
    }

    func testWrapComputedPropertyWithReturn() {
        let input = """
        var value: Int { return 42 }
        """
        let output = """
        var value: Int {
            return 42
        }
        """
        testFormatting(for: input, output, rule: .wrapPropertyBodies)
    }

    func testDoesNotWrapAlreadyMultilineComputedProperty() {
        let input = """
        var bar: String {
            "bar"
        }
        """
        testFormatting(for: input, rule: .wrapPropertyBodies)
    }

    func testDoesNotWrapStoredPropertyWithDidSet() {
        let input = """
        var value: Int = 0 { didSet { print("changed") } }
        """
        testFormatting(for: input, rule: .wrapPropertyBodies)
    }

    func testDoesNotWrapStoredPropertyWithWillSet() {
        let input = """
        var value: Int = 0 { willSet { print("will change") } }
        """
        testFormatting(for: input, rule: .wrapPropertyBodies)
    }

    func testWrapComputedPropertyInStruct() {
        let input = """
        struct Foo {
            var bar: String { "bar" }
        }
        """
        let output = """
        struct Foo {
            var bar: String {
                "bar"
            }
        }
        """
        testFormatting(for: input, output, rule: .wrapPropertyBodies)
    }

    // MARK: - Functions (should NOT be wrapped by this rule)

    func testDoesNotWrapFunction() {
        let input = """
        func foo() { print("bar") }
        """
        testFormatting(for: input, rule: .wrapPropertyBodies, exclude: [.wrapFunctionBodies])
    }

    func testDoesNotWrapInit() {
        let input = """
        init() { value = 0 }
        """
        testFormatting(for: input, rule: .wrapPropertyBodies, exclude: [.wrapFunctionBodies])
    }

    func testDoesNotWrapSubscript() {
        let input = """
        subscript(index: Int) -> Int { array[index] }
        """
        testFormatting(for: input, rule: .wrapPropertyBodies, exclude: [.wrapFunctionBodies])
    }

    // MARK: - Protocols (should NOT be wrapped)

    func testDoesNotWrapComputedPropertyInProtocol() {
        let input = """
        protocol Expandable: ExpandableView {
            var expansionStateDidChange: ((Self) -> Void)? { get set }
        }
        """
        testFormatting(for: input, rule: .wrapPropertyBodies)
    }

    func testDoesNotWrapComputedPropertyInProtocolWithClassConstraint() {
        let input = """
        protocol LayoutBacked: class {
            var layoutNode: LayoutNode? { get }
        }
        """
        testFormatting(for: input, rule: .wrapPropertyBodies)
    }
}
