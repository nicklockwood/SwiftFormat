//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest
@testable import Layout

class AttributedStringExpressionTests: XCTestCase {
    func testAttributedStringExpressionTextAndFont() {
        let node = LayoutNode()
        let expression = LayoutExpression(attributedStringExpression: "foo", for: node)
        let result = try! expression?.evaluate() as! NSAttributedString
        XCTAssertEqual(result.string, "foo")
        XCTAssertEqual(result.attribute(NSAttributedString.Key.font, at: 0, effectiveRange: nil) as? UIFont, .systemFont(ofSize: 17))
    }

    func testAttributedStringHTMLExpression() {
        let node = LayoutNode()
        let expression = LayoutExpression(attributedStringExpression: "<b>foo</b>", for: node)
        let result = try! expression?.evaluate() as! NSAttributedString
        XCTAssertEqual(result.string, "foo")
        XCTAssertEqual(result.attribute(NSAttributedString.Key.font, at: 0, effectiveRange: nil) as? UIFont, .boldSystemFont(ofSize: 17))
    }

    func testAttributedStringContainingUnicode() {
        let node = LayoutNode()
        let text = "🤔😂"
        let expression = LayoutExpression(attributedStringExpression: "<i>\(text)</i>", for: node)
        let result = try! expression?.evaluate() as! NSAttributedString
        XCTAssertEqual(result.string, text)
    }

    func testAttributedStringInheritsFont() {
        let label = UILabel()
        label.font = UIFont(name: "Courier", size: 57)
        let node = LayoutNode(view: label)
        let expression = LayoutExpression(attributedStringExpression: "foo", for: node)
        let result = try! expression?.evaluate() as! NSAttributedString
        XCTAssertEqual(result.attribute(NSAttributedString.Key.font, at: 0, effectiveRange: nil) as? UIFont, label.font)
    }

    func testAttributedStringInheritsTextColor() {
        let label = UILabel()
        label.textColor = .red
        let node = LayoutNode(view: label)
        let expression = LayoutExpression(attributedStringExpression: "foo", for: node)
        let result = try! expression?.evaluate() as! NSAttributedString
        XCTAssertEqual(result.attribute(NSAttributedString.Key.foregroundColor, at: 0, effectiveRange: nil) as? UIColor, .red)
    }

    func testAttributedStringInheritsTextAlignment() {
        let label = UILabel()
        label.textAlignment = .right
        let node = LayoutNode(view: label)
        let expression = LayoutExpression(attributedStringExpression: "foo", for: node)
        let result = try! expression?.evaluate() as! NSAttributedString
        let paragraphStyle = result.attribute(NSAttributedString.Key.paragraphStyle, at: 0, effectiveRange: nil) as! NSParagraphStyle
        XCTAssertEqual(paragraphStyle.alignment, .right)
    }

    func testAttributedStringInheritsLinebreakMode() {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingHead
        let node = LayoutNode(view: label)
        let expression = LayoutExpression(attributedStringExpression: "foo", for: node)
        let result = try! expression?.evaluate() as! NSAttributedString
        let paragraphStyle = result.attribute(NSAttributedString.Key.paragraphStyle, at: 0, effectiveRange: nil) as! NSParagraphStyle
        XCTAssertEqual(paragraphStyle.lineBreakMode, .byTruncatingHead)
    }

    func testAttributedStringContainingStringConstant() {
        let node = LayoutNode(constants: ["bar": "bar"])
        let expression = LayoutExpression(attributedStringExpression: "hello world {bar}", for: node)
        let result = try! expression?.evaluate() as! NSAttributedString
        XCTAssertEqual(result.string, "hello world bar")
    }

    func testAttributedStringContainingAttributedStringConstant() {
        let node = LayoutNode(constants: ["bar": NSAttributedString(string: "bar", attributes: [
            NSAttributedString.Key.foregroundColor: UIColor.red,
        ])])
        let expression = LayoutExpression(attributedStringExpression: "hello world {bar}", for: node)
        let result = try! expression?.evaluate() as! NSAttributedString
        XCTAssertEqual(result.string, "hello world bar")
        XCTAssertEqual(result.attribute(NSAttributedString.Key.foregroundColor, at: 12, effectiveRange: nil) as? UIColor, .red)
    }

    func testAttributedStringContainingHTMLConstant() {
        let node = LayoutNode(constants: ["bar": "<i>bar</i>"])
        let expression = LayoutExpression(attributedStringExpression: "<b>foo {bar}</b>", for: node)
        let result = try! expression?.evaluate() as! NSAttributedString
        XCTAssertEqual(result.string, "foo bar")
        XCTAssertEqual(result.attribute(NSAttributedString.Key.font, at: 0, effectiveRange: nil) as? UIFont, .boldSystemFont(ofSize: 17))
        let traits = (result.attribute(NSAttributedString.Key.font, at: 4, effectiveRange: nil) as? UIFont)?.fontDescriptor.symbolicTraits
        XCTAssert(traits?.contains(.traitItalic) == true)
        XCTAssert(traits?.contains(.traitBold) == true)
    }

    func testAttributedStringContainingAmbiguousTokens() {
        let node = LayoutNode(constants: ["foo": "$(2)", "bar": "$(3)"])
        let expression = LayoutExpression(attributedStringExpression: "<b>$(1)</b>{foo}{bar}", for: node)
        let result = try! expression?.evaluate() as! NSAttributedString
        XCTAssertEqual(result.string, "$(1)$(2)$(3)")
    }
}
