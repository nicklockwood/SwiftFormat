//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest
@testable import Layout

class ArrayExpressionTests: XCTestCase {
    func testArrayExpression() {
        let node = LayoutNode()
        let expression = LayoutExpression(expression: "1, 2, 3", type: .array(of: .int), for: node)
        let expected = [1, 2, 3]
        XCTAssertEqual(expression?.symbols, [])
        XCTAssertEqual(try expression?.evaluate() as? NSArray, expected as NSArray)
    }

    func testSetSegmentedControlTitlesWithLiteral() {
        let node = LayoutNode(
            view: UISegmentedControl(),
            expressions: [
                "items": "'foo', 'bar', 'baz'",
            ]
        )
        let expected = ["foo", "bar", "baz"]
        XCTAssertEqual(try node.value(forSymbol: "items") as? NSArray, expected as NSArray)
    }

    func testSetSingleSegmentedControlTitle() {
        let node = LayoutNode(
            view: UISegmentedControl(),
            expressions: [
                "items": "'foo'",
            ]
        )
        let expected = ["foo"]
        XCTAssertEqual(try node.value(forSymbol: "items") as? NSArray, expected as NSArray)
    }

    func testSetSegmentedControlTitlesWithConstant() {
        let items = ["foo", "bar", "baz"]
        let node = LayoutNode(
            view: UISegmentedControl(),
            constants: [
                "items": items,
            ],
            expressions: [
                "items": "items",
            ]
        )
        XCTAssertEqual(try node.value(forSymbol: "items") as? NSArray, items as NSArray)
    }

    func testSetSegmentedControlTitlesWithMixedConstantAndLiteral() {
        let node = LayoutNode(
            view: UISegmentedControl(),
            constants: [
                "items": ["foo", "bar"],
            ],
            expressions: [
                "items": "items, 'baz', 'quux'",
            ]
        )
        let expected = ["foo", "bar", "baz", "quux"]
        XCTAssertEqual(try node.value(forSymbol: "items") as? NSArray, expected as NSArray)
    }
}
