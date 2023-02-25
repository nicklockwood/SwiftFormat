//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest
@testable import Layout

class OptionalExpressionTests: XCTestCase {
    func testEquateOptionalNumbers() {
        let foo: Double? = 5
        let node = LayoutNode(constants: ["foo": foo as Any])
        let expression = LayoutExpression(boolExpression: "foo == 5", for: node)
        XCTAssertTrue(try expression?.evaluate() as? Bool == true)
    }

    func testAddOptionalNumbers() {
        let foo: Double? = 5
        let node = LayoutNode(constants: ["foo": foo as Any])
        let expression = LayoutExpression(doubleExpression: "foo + 5", for: node)
        XCTAssertEqual(try expression?.evaluate() as? Double, 10)
    }

    func testMultiplyOptionalNumbers() {
        let foo: Double? = 5
        let node = LayoutNode(constants: ["foo": foo as Any])
        let expression = LayoutExpression(doubleExpression: "foo * 5", for: node)
        XCTAssertEqual(try expression?.evaluate() as? Double, 25)
    }

    func testEquateOptionalStrings() {
        let foo: String? = "foo"
        let node = LayoutNode(constants: ["foo": foo as Any])
        let expression = LayoutExpression(boolExpression: "foo == 'foo'", for: node)
        XCTAssertTrue(try expression?.evaluate() as? Bool == true)
    }

    func testAddOptionalStrings() {
        let foo: String? = "foo"
        let node = LayoutNode(constants: ["foo": foo as Any])
        let expression = LayoutExpression(stringExpression: "{foo + 'bar'}", for: node)
        XCTAssertEqual(try expression?.evaluate() as? String, "foobar")
    }

    func testNullCoalescingInNumberExpression() {
        let null: Double? = nil
        let node = LayoutNode(constants: ["foo": null as Any])
        let expression = LayoutExpression(doubleExpression: "foo ?? 5", for: node)
        XCTAssertEqual(try expression?.evaluate() as? Double, 5)
    }

    func testNullStringExpression() {
        let null: String? = nil
        let node = LayoutNode(constants: ["foo": null as Any])
        let expression = LayoutExpression(stringExpression: "{foo}", for: node)
        XCTAssertEqual(try expression?.evaluate() as? String, "")
    }

    func testOptionalStringExpression() {
        let foo: String? = "foo"
        let node = LayoutNode(constants: ["foo": foo as Any])
        let expression = LayoutExpression(stringExpression: "{foo}", for: node)
        XCTAssertEqual(try expression?.evaluate() as? String, "foo")
    }

    func testNullImageExpression() {
        let null: UIImage? = nil
        let node = LayoutNode(constants: ["foo": null as Any])
        let expression = LayoutExpression(imageExpression: "{foo}", for: node)
        XCTAssertEqual(try (expression?.evaluate() as? UIImage).map { $0.size }, .zero)
    }

    func testNullAnyExpression() {
        let null: Any? = nil
        let node = LayoutNode(constants: ["foo": null as Any])
        let expression = LayoutExpression(expression: "foo", type: RuntimeType(Any.self), for: node)
        XCTAssertThrowsError(try expression?.evaluate()) { error in
            XCTAssert("\(error)".contains("nil"))
        }
    }
}
