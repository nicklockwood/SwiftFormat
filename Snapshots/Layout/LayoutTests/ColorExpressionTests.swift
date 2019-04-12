//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest
@testable import Layout

extension UIColor {
    @objc static let testColor = UIColor.brown
}

class ColorExpressionTests: XCTestCase {
    func testRed() {
        let node = LayoutNode()
        let expression = LayoutExpression(colorExpression: "red", for: node)
        let expected = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        XCTAssertEqual(try expression?.evaluate() as? UIColor, expected)
    }

    func testRedOrBlue() {
        let node = LayoutNode()
        let expression = LayoutExpression(colorExpression: "true ? #f00 : #00f", for: node)
        let expected = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        XCTAssertEqual(try expression?.evaluate() as? UIColor, expected)
    }

    func testRedOrBlue2() {
        let node = LayoutNode(state: ["foo": true])
        let expression = LayoutExpression(colorExpression: "foo ? red : blue", for: node)
        let expected = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        XCTAssertEqual(try expression?.evaluate() as? UIColor, expected)
    }

    func testCustomStaticColor() {
        let node = LayoutNode()
        let expression = LayoutExpression(colorExpression: "test", for: node)
        XCTAssertEqual(try expression?.evaluate() as? UIColor, .testColor)
    }

    func testCustomStaticColor2() {
        let node = LayoutNode()
        let expression = LayoutExpression(colorExpression: "testColor", for: node)
        XCTAssertEqual(try expression?.evaluate() as? UIColor, .testColor)
    }

    func testCustomStaticColor3() {
        let node = LayoutNode()
        let expression = LayoutExpression(colorExpression: "{UIColor.testColor}", for: node)
        XCTAssertEqual(try expression?.evaluate() as? UIColor, .testColor)
    }

    func testCustomStaticColor4() {
        let node = LayoutNode()
        let expression = LayoutExpression(colorExpression: "{testColor}", for: node)
        XCTAssertEqual(try expression?.evaluate() as? UIColor, .testColor)
    }

    func testNilColor() {
        let null: UIColor? = nil
        let node = LayoutNode(constants: ["color": null as Any])
        let expression = LayoutExpression(colorExpression: "color", for: node)
        XCTAssertThrowsError(try expression?.evaluate()) { error in
            XCTAssert("\(error)".contains("nil"))
        }
    }

    func testRGBColorWithClashingConstant() {
        let node = LayoutNode(constants: ["red": 255])
        let expression = LayoutExpression(colorExpression: "rgb(red,0,0)", for: node)
        XCTAssertThrowsError(try expression?.evaluate()) { error in
            XCTAssert("\(error)".lowercased().contains("type"))
        }
    }

    func testSetBackgroundColor() {
        let node = LayoutNode(expressions: ["backgroundColor": "red"])
        node.update()
        let expected = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        XCTAssertEqual(node.view.backgroundColor, expected)
    }

    func testSetLayerBackgroundColor() {
        let node = LayoutNode(expressions: ["layer.backgroundColor": "red"])
        node.update()
        let expected = UIColor(red: 1, green: 0, blue: 0, alpha: 1).cgColor
        XCTAssertEqual(node.view.layer.backgroundColor, expected)
    }

    func testSetLayerBackgroundColorWithCGColorConstant() {
        let color = UIColor(red: 1, green: 0, blue: 0, alpha: 1).cgColor
        let node = LayoutNode(
            constants: ["color": color],
            expressions: ["layer.backgroundColor": "color"]
        )
        node.update()
        XCTAssertEqual(node.view.layer.backgroundColor, color)
    }

    func testSetLayerBackgroundColorWithUIColorConstant() {
        let color = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        let node = LayoutNode(
            constants: ["color": color],
            expressions: ["layer.backgroundColor": "color"]
        )
        node.update()
        XCTAssertEqual(node.view.layer.backgroundColor, color.cgColor)
    }

    func testBracedColor() {
        let node = LayoutNode()
        let expression = LayoutExpression(colorExpression: "{red}", for: node)
        let expected = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        XCTAssertEqual(try expression?.evaluate() as? UIColor, expected)
    }

    func testNamedColorAsset() {
        let node = LayoutNode()
        let expression = LayoutExpression(colorExpression: "com.LayoutTests:MyColor", for: node)
        XCTAssertThrowsError(try expression?.evaluate() as? UIColor) { error in
            if #available(iOS 11.0, *) {
                XCTAssert("\(error)".contains("in bundle"))
            } else {
                XCTAssert("\(error)".contains("iOS 11"))
            }
        }
    }

    func testNamedColorAssetExpression() {
        let node = LayoutNode()
        let expression = LayoutExpression(colorExpression: "MyColor{1}", for: node)
        XCTAssertThrowsError(try expression?.evaluate() as? UIColor) { error in
            if #available(iOS 11.0, *) {
                XCTAssert("\(error)".contains("Invalid color name"))
            } else {
                XCTAssert("\(error)".contains("iOS 11"))
            }
        }
    }
}
