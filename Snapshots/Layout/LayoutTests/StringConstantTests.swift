//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest
@testable import Layout

class StringConstantTests: XCTestCase {
    func testSimpleStringConstant() {
        let node = LayoutNode(constants: ["strings.hello": "Hello World"])
        let expression = LayoutExpression(expression: "{strings.hello}", type: .string, for: node)
        XCTAssertEqual(try expression?.evaluate() as? String, "Hello World")
    }

    func testParameterizedStringConstant() {
        let node = LayoutNode(constants: ["strings.hello": "Hello %s"])
        let expression = LayoutExpression(expression: "{strings.hello('World')}", type: .string, for: node)
        XCTAssertEqual(try expression?.evaluate() as? String, "Hello World")
    }

    func testParameterizedStringConstanWithNoArguments() {
        let node = LayoutNode(constants: ["strings.hello": "Hello %% World"])
        let expression = LayoutExpression(expression: "{strings.hello()}", type: .string, for: node)
        XCTAssertEqual(try expression?.evaluate() as? String, "Hello % World")
    }

    func testInvalidParameterizedStringConstantReference() {
        let node = LayoutNode(constants: ["strings.hello": "Hello %s"])
        let expression = LayoutExpression(expression: "{strings.hello('World', 'Universe')}", type: .string, for: node)
        XCTAssertThrowsError(try expression?.evaluate()) { error in
            XCTAssert("\(error)".contains("Too many arguments"))
        }
    }

    func testInvalidParameterizedStringConstantReference2() {
        let node = LayoutNode(constants: ["strings.hello": "Hello %s"])
        let expression = LayoutExpression(expression: "{strings.hello()}", type: .string, for: node)
        XCTAssertThrowsError(try expression?.evaluate()) { error in
            XCTAssert("\(error)".contains("Too few arguments"))
        }
    }

    func testInvalidParameterizedStringConstantReference3() {
        let node = LayoutNode(constants: ["strings.hello": "Hello %i"])
        let expression = LayoutExpression(expression: "{strings.hello('World')}", type: .string, for: node)
        XCTAssertThrowsError(try expression?.evaluate()) { error in
            XCTAssert("\(error)".contains("Type mismatch"))
        }
    }
}
