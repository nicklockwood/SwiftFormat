//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest
@testable import Layout

class TestClass: NSObject {
    @objc static var foo: Double {
        return 5
    }
}

func makeLayout(
    expressions: [String: String] = [:],
    parameters: [String: RuntimeType] = [:],
    macros: [String: String] = [:],
    children: [Layout] = []
) -> Layout {
    return Layout(
        className: "UIView",
        id: nil,
        expressions: expressions,
        parameters: parameters,
        macros: macros,
        children: children,
        body: nil,
        xmlPath: nil,
        templatePath: nil,
        childrenTagIndex: nil,
        relativePath: nil,
        rootURL: nil
    )
}

class LayoutExpressionTests: XCTestCase {
    // MARK: Expression parsing

    func testParseExpressionWithoutBraces() {
        let expression = try? parseExpression("4 + 5")
        XCTAssertNotNil(expression)
        XCTAssertEqual(expression?.symbols, [.infix("+")])
    }

    func testParseExpressionWithBraces() {
        let expression = try? parseExpression("{4 + 5}")
        XCTAssertNotNil(expression)
        XCTAssertEqual(expression?.symbols, [.infix("+")])
    }

    func testParseExpressionWithBracesAndWhitespace() {
        let expression = try? parseExpression(" {4 + 5} ")
        XCTAssertNotNil(expression)
        XCTAssertEqual(expression?.symbols, [.infix("+")])
    }

    func testParseExpressionWithLeadingGarbage() {
        XCTAssertThrowsError(try parseExpression("foo {4 + 5}"))
    }

    func testParseExpressionWithTrailingGarbage() {
        XCTAssertThrowsError(try parseExpression("{4 + 5} foo"))
    }

    func testParseExpressionWithBracesWithLeadingWhitespace() {
        XCTAssertNoThrow(try parseExpression("{ 4 + 5}"))
    }

    func testParseExpressionWithLeadingWhitespace() {
        XCTAssertNoThrow(try parseExpression(" 4 + 5"))
    }

    func testParseEmptyExpression() {
        XCTAssertNoThrow(try parseExpression(""))
    }

    func testParseExpressionWithEmptyBraces() {
        XCTAssertNoThrow(try parseExpression("{}"))
    }

    func testParseExpressionOpeningBrace() {
        XCTAssertThrowsError(try parseExpression("{"))
    }

    func testParseExpressionWithClosingBrace() {
        XCTAssertThrowsError(try parseExpression("}"))
    }

    func testParseExpressionWithMissingClosingBrace() {
        XCTAssertThrowsError(try parseExpression("{4 + 5"))
    }

    func testParseExpressionWithMissingOpeningBrace() {
        XCTAssertThrowsError(try parseExpression("4 + 5}"))
    }

    func testParseExpressionWithExtraOpeningBrace() {
        XCTAssertThrowsError(try parseExpression("{{4 + 5}"))
    }

    func testParseExpressionWithExtraClosingBrace() {
        XCTAssertThrowsError(try parseExpression("{4 + 5}}"))
    }

    func testParseExpressionWithClosingBraceInQuotes() {
        let expression = try? parseExpression("{'}'}")
        XCTAssertNotNil(expression)
        XCTAssertNil(expression?.error)
    }

    func testParseExpressionWithOpeningBraceInQuotes() {
        let expression = try? parseExpression("{'{'}")
        XCTAssertNotNil(expression)
        XCTAssertNil(expression?.error)
    }

    func testParseExpressionWithBracesInQuotes() {
        let expression = try? parseExpression("{'{foo}'}")
        XCTAssertNotNil(expression)
        XCTAssertNil(expression?.error)
    }

    // MARK: String expression parsing

    func testParseStringExpressionWithoutBraces() {
        let parts = (try? parseStringExpression("4 + 5")) ?? []
        XCTAssertEqual(parts.count, 1)
        guard let part = parts.first, case let .string(string) = part else {
            XCTFail()
            return
        }
        XCTAssertEqual(string, "4 + 5")
    }

    func testParseStringExpressionWithBraces() {
        let parts = (try? parseStringExpression("{4 + 5}")) ?? []
        XCTAssertEqual(parts.count, 1)
        guard let part = parts.first, case let .expression(expression) = part else {
            XCTFail()
            return
        }
        XCTAssertEqual(expression.symbols, [.infix("+")])
    }

    func testParseStringExpressionWithBracesAndWhitespace() {
        let parts = (try? parseStringExpression(" {4 + 5} ")) ?? []
        guard parts.count == 3 else {
            XCTFail()
            return
        }
        guard case let .string(a) = parts[0], a == " " else {
            XCTFail()
            return
        }
        guard case let .expression(b) = parts[1], b.symbols == [.infix("+")] else {
            XCTFail()
            return
        }
        guard case let .string(c) = parts[2], c == " " else {
            XCTFail()
            return
        }
    }

    func testParseStringExpressionWithMultipleBraces() {
        let parts = (try? parseStringExpression("{4} + {5}")) ?? []
        guard parts.count == 3 else {
            XCTFail()
            return
        }
        guard case let .expression(a) = parts[0], a.symbols == [] else {
            XCTFail()
            return
        }
        guard case let .string(b) = parts[1], b == " + " else {
            XCTFail()
            return
        }
        guard case let .expression(c) = parts[2], c.symbols == [] else {
            XCTFail()
            return
        }
    }

    func testParseEmptyStringExpression() {
        do {
            let parts = try parseStringExpression("")
            XCTAssertTrue(parts.isEmpty)
        } catch {
            XCTFail()
        }
    }

    func testParseStringExpressionWithEmptyBraces() {
        XCTAssertNoThrow(try parseStringExpression("{}"))
    }

    func testParseStringExpressionOpeningBrace() {
        XCTAssertThrowsError(try parseStringExpression("{"))
    }

    func testParseStringExpressionClosingBrace() {
        XCTAssertThrowsError(try parseStringExpression("}"))
    }

    func testParseStringExpressionWithMissingClosingBrace() {
        XCTAssertThrowsError(try parseStringExpression("{4 + 5"))
    }

    func testParseStringExpressionWithMissingOpeningBrace() {
        XCTAssertThrowsError(try parseStringExpression("4 + 5}"))
    }

    func testParseStringExpressionWithExtraOpeningBrace() {
        XCTAssertThrowsError(try parseStringExpression("{{4 + 5}"))
    }

    func testParseStringExpressionWithExtraClosingBrace() {
        XCTAssertThrowsError(try parseStringExpression("{4 + 5}}"))
    }

    func testParseStringExpressionWithClosingBraceInQuotes() {
        let parts = (try? parseStringExpression("{'}'}")) ?? []
        XCTAssertEqual(parts.count, 1)
        guard let part = parts.first, case let .expression(expression) = part else {
            XCTFail()
            return
        }
        XCTAssertNil(expression.error)
    }

    func testParseStringExpressionWithOpeningBraceInQuotes() {
        let parts = (try? parseStringExpression("{'{'}")) ?? []
        XCTAssertEqual(parts.count, 1)
        guard let part = parts.first, case let .expression(expression) = part else {
            XCTFail()
            return
        }
        XCTAssertNil(expression.error)
    }

    func testParseStringExpressionWithBracesInQuotes() {
        let parts = (try? parseStringExpression("{'{foo}'}")) ?? []
        XCTAssertEqual(parts.count, 1)
        guard let part = parts.first, case let .expression(expression) = part else {
            XCTFail()
            return
        }
        XCTAssertNil(expression.error)
    }

    // MARK: Expression comments

    func testParseExpressionWithCommentWithoutBraces() throws {
        let expression = try parseExpression("4 + 5 // hello")
        XCTAssertEqual(expression.symbols, [.infix("+")])
        XCTAssertEqual(expression.description, "4 + 5 // hello")
    }

    func testCommentedOutExpressionWithoutBraces() throws {
        let expression = try parseExpression(" //4 + 5")
        XCTAssertEqual(expression.isEmpty, true)
        XCTAssertEqual(expression.description, "// 4 + 5")
    }

    func testParseExpressionWithCommentInBraces() throws {
        let expression = try parseExpression("{4 + 5 // hello}")
        XCTAssertEqual(expression.symbols, [.infix("+")])
        XCTAssertEqual(expression.description, "4 + 5 // hello")
    }

    func testParseExpressionWithCommentAfterBraces() throws {
        let expression = try parseExpression("{4 + 5} // hello")
        XCTAssertEqual(expression.symbols, [.infix("+")])
        XCTAssertEqual(expression.description, "4 + 5 // hello")
    }

    func testParseExpressionWithCommentInAndAfterBraces() throws {
        let expression = try parseExpression("{4 + 5 // hello} // world")
        XCTAssertEqual(expression.symbols, [.infix("+")])
        XCTAssertEqual(expression.description, "4 + 5 // hello // world")
    }

    func testCommentedOutExpressionWithBraces() throws {
        let expression = try parseExpression("{ //4 + 5}")
        XCTAssertEqual(expression.isEmpty, true)
        XCTAssertEqual(expression.description, "// 4 + 5")
    }

    func testParseExpressionWithCommentBeforeBraces() throws {
        let expression = try parseExpression(" //{4 + 5}")
        XCTAssertEqual(expression.isEmpty, true)
        XCTAssertEqual(expression.description, "// {4 + 5}")
    }

    // MARK: String expression comments

    func testParseStringExpressionWithComment() throws {
        let expression = "foo {4 + 5 // hello } bar"
        let parts = try parseStringExpression(expression)
        guard parts.count == 3 else {
            XCTFail()
            return
        }
        guard case .string("foo ") = parts[0] else {
            XCTFail()
            return
        }
        guard case let .expression(exp) = parts[1] else {
            XCTFail()
            return
        }
        XCTAssertEqual(exp.symbols, [.infix("+")])
        XCTAssertEqual(exp.description, "4 + 5 // hello")
        XCTAssertNil(exp.error)
        guard case .string(" bar") = parts[2] else {
            XCTFail()
            return
        }
        guard let layoutExpression = LayoutExpression(stringExpression: expression, for: LayoutNode()) else {
            XCTFail()
            return
        }
        XCTAssertEqual(try layoutExpression.evaluate() as? String, "foo 9 bar")
    }

    func testParseStringExpressionWithCommentedOutClause() throws {
        let expression = "foo {// 4 + 5} bar"
        let parts = try parseStringExpression(expression)
        guard parts.count == 3 else {
            XCTFail()
            return
        }
        guard case .string("foo ") = parts[0] else {
            XCTFail()
            return
        }
        guard case let .expression(exp) = parts[1] else {
            XCTFail()
            return
        }
        XCTAssertEqual(exp.symbols, [])
        XCTAssertEqual(exp.description, "// 4 + 5")
        XCTAssertTrue(exp.isEmpty)
        guard let layoutExpression = LayoutExpression(stringExpression: expression, for: LayoutNode()) else {
            XCTFail()
            return
        }
        XCTAssertEqual(try layoutExpression.evaluate() as? String, "foo  bar")
    }

    func testCommentedOutStringExpression() throws {
        let expression = " //hello {'world'}"
        let parts = try parseStringExpression(expression)
        guard parts.count == 1 else {
            XCTFail()
            return
        }
        guard case let .comment(comment) = parts[0] else {
            XCTFail()
            return
        }
        XCTAssertEqual(comment, "hello {'world'}")
        XCTAssertEqual(parts.description, "// hello {'world'}")
        XCTAssertNil(LayoutExpression(stringExpression: expression, for: LayoutNode()))
    }

    // MARK: Image and color expression comments

    func testCommentedOutColorExpression() {
        let node = LayoutNode()
        let expression = LayoutExpression(colorExpression: "// red", for: node)
        XCTAssertNil(expression)
    }

    func testCommentedOutImageExpression() {
        let node = LayoutNode()
        let expression = LayoutExpression(imageExpression: "// MyImage.png", for: node)
        XCTAssertNil(expression)
    }

    func testColorExpressionWithComment() {
        let node = LayoutNode()
        let expression = LayoutExpression(colorExpression: "red // comment", for: node)
        XCTAssertNotNil(expression)
        XCTAssertEqual(try expression?.evaluate() as? UIColor, .red)
    }

    func testImageExpressionWithComment() { // Not supported
        let node = LayoutNode()
        let expression = LayoutExpression(imageExpression: "MyImage.png // comment", for: node)
        XCTAssertNotNil(expression)
        XCTAssertThrowsError(try expression?.evaluate())
    }

    // MARK: Class properties

    func testClassPropertyInDoubleExpression() {
        let node = LayoutNode()
        let className = NSStringFromClass(TestClass.self)
        let expression = LayoutExpression(doubleExpression: "\(className).foo", for: node)
        XCTAssertEqual(try expression?.evaluate() as? Double, 5)
    }

    func testUIColorPropertyInColorExpression() {
        let node = LayoutNode()
        let expression = LayoutExpression(colorExpression: "UIColor.red", for: node)
        XCTAssertEqual(try expression?.evaluate() as? UIColor, .red)
    }

    func testEnumPropertyInEnumExpression() {
        let node = LayoutNode()
        let expression = LayoutExpression(expression: "UIViewContentMode.center", type: .uiViewContentMode, for: node)
        XCTAssertEqual(try expression?.evaluate() as? UIView.ContentMode, .center)
    }

    func testOptionSetPropertyInEnumExpression() {
        let node = LayoutNode()
        let expression = LayoutExpression(expression: "UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight", type: .uiViewAutoresizing, for: node)
        XCTAssertEqual(try expression?.evaluate() as? UIView.AutoresizingMask, [.flexibleWidth, .flexibleHeight])
    }

    // MARK: Integration tests

    func testOptionalBracesInNumberExpression() {
        let node = LayoutNode()
        let expression = LayoutExpression(doubleExpression: "{4 + 5}", for: node)
        XCTAssertEqual(try expression?.evaluate() as? Double, 9)
    }

    func testOptionalBracesInColorExpression() {
        let node = LayoutNode()
        let expression = LayoutExpression(colorExpression: "{white}", for: node)
        XCTAssertEqual(try expression?.evaluate() as? UIColor, .white)
    }

    func testOptionalMultipleExpressionBodiesDisallowedInNumberExpression() {
        let node = LayoutNode()
        let expression = LayoutExpression(doubleExpression: "{5}{6}", for: node)
        XCTAssertThrowsError(try expression?.evaluate())
    }

    func testFalseTreatedAsConstant() {
        let node = LayoutNode()
        let expression = LayoutExpression(boolExpression: "false", for: node)
        XCTAssertEqual(expression?.symbols.isEmpty, true)
    }

    func testSetLayerContentsWithCGImageConstant() {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        let image: AnyObject = UIGraphicsGetImageFromCurrentImageContext()!.cgImage!
        UIGraphicsEndImageContext()
        let node = LayoutNode(
            constants: ["image": image],
            expressions: ["layer.contents": "{image}"]
        )
        node.update()
        XCTAssertTrue(node.view.layer.contents as AnyObject === image)
    }

    func testSetLayerContentsWithUIImageConstant() {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        let node = LayoutNode(
            constants: ["image": image],
            expressions: ["layer.contents": "{image}"]
        )
        node.update()
        XCTAssertTrue(node.view.layer.contents as AnyObject === image.cgImage as AnyObject)
    }

    func testSetLayerShadowPathWithConstant() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let path = CGPath(rect: rect, transform: nil)
        let node = LayoutNode(
            constants: ["path": path],
            expressions: ["layer.shadowPath": "path"]
        )
        node.update()
        XCTAssertEqual(node.view.layer.shadowPath, path)
    }

    func testThrowErrorForConstantExpression() {
        let node = LayoutNode(
            constants: ["foo": "Not a color"],
            expressions: ["backgroundColor": "{foo}"]
        )
        node.update()
        XCTAssertThrowsError(try node.throwUnhandledError())
    }

    // MARK: Constant optimization

    func testLiteral() {
        let node = LayoutNode()
        let expression = LayoutExpression(doubleExpression: "5 + 6", for: node)
        XCTAssertEqual(expression?.isConstant, true)
        XCTAssertEqual(try expression?.evaluate() as! Double, 11)
    }

    func testConstant() {
        let node = LayoutNode(constants: ["foo": 5])
        let expression = LayoutExpression(doubleExpression: "foo + 6", for: node)
        XCTAssertEqual(expression?.isConstant, true)
        XCTAssertEqual(try expression?.evaluate() as! Double, 11)
    }

    func testState() {
        let node = LayoutNode(state: ["foo": 5])
        let expression = LayoutExpression(doubleExpression: "foo + 6", for: node)
        XCTAssertEqual(expression?.isConstant, false)
        XCTAssertEqual(try expression?.evaluate() as! Double, 11)
    }

    func testInheritedConstant() {
        let child = LayoutNode()
        let parent = LayoutNode(constants: ["foo": 5], children: [child])
        parent.update()
        let expression = LayoutExpression(doubleExpression: "foo + 6", for: child)
        XCTAssertEqual(expression?.isConstant, true)
        XCTAssertEqual(try expression?.evaluate() as! Double, 11)
    }

    func testParentLiteralExpression() {
        let child = LayoutNode()
        let parent = LayoutNode(expressions: ["height": "5"], children: [child])
        parent.update()
        let expression = LayoutExpression(doubleExpression: "parent.height + 6", for: child)
        XCTAssertEqual(expression?.isConstant, true)
        XCTAssertEqual(try expression?.evaluate() as! Double, 11)
    }

    func testParentConstantExpression() {
        let child = LayoutNode()
        let parent = LayoutNode(constants: ["foo": 5], expressions: ["height": "foo + 6"], children: [child])
        parent.update()
        let expression = LayoutExpression(doubleExpression: "parent.height + 6", for: child)
        XCTAssertEqual(expression?.isConstant, true)
        XCTAssertEqual(try expression?.evaluate() as! Double, 17)
    }

    func testLiteralParameter() {
        let layout = makeLayout(
            expressions: ["foo": "5"],
            parameters: ["foo": RuntimeType(Int.self)],
            children: [
                makeLayout(),
            ]
        )
        let parent = try! LayoutNode(layout: layout)
        let child = parent.children[0]
        parent.update()
        let expression = LayoutExpression(doubleExpression: "foo + 6", for: child)
        XCTAssertEqual(expression?.isConstant, true)
        XCTAssertEqual(try expression?.evaluate() as! Double, 11)
    }

    func testConstantParameter() {
        let layout = makeLayout(
            expressions: ["foo": "bar + 3"],
            parameters: ["foo": RuntimeType(Int.self)],
            children: [
                makeLayout(),
            ]
        )
        let parent = try! LayoutNode(layout: layout, constants: ["bar": 5])
        let child = parent.children[0]
        parent.update()
        let expression = LayoutExpression(doubleExpression: "foo + 6", for: child)
        XCTAssertEqual(expression?.isConstant, true)
        XCTAssertEqual(try expression?.evaluate() as! Double, 14)
    }

    func testLiteralMacro() {
        let layout = makeLayout(
            macros: ["BAR": "5"],
            children: [
                makeLayout(),
            ]
        )
        let parent = try! LayoutNode(layout: layout)
        let child = parent.children[0]
        parent.update()
        let expression = LayoutExpression(doubleExpression: "BAR + 6", for: child)
        XCTAssertEqual(expression?.isConstant, true)
        XCTAssertEqual(try expression?.evaluate() as! Double, 11)
    }

    func testArrayMacro() {
        let layout = makeLayout(macros: ["ITEMS": "1,2,3"])
        let node = try! LayoutNode(layout: layout)
        node.update()
        let expression = LayoutExpression(doubleExpression: "ITEMS[1]", for: node)
        XCTAssertEqual(expression?.isConstant, true)
        XCTAssertEqual(try expression?.evaluate() as! Double, 2)
    }

    func testArrayMacro2() {
        let layout = makeLayout(macros: ["ITEMS": "[1,2,3]"])
        let node = try! LayoutNode(layout: layout)
        node.update()
        let expression = LayoutExpression(doubleExpression: "ITEMS[1]", for: node)
        XCTAssertEqual(expression?.isConstant, true)
        XCTAssertEqual(try expression?.evaluate() as! Double, 2)
    }

    func testArrayConstant() {
        let node = LayoutNode(constants: ["items": ["foo", "bar", "baz"]])
        node.update()
        let expression = LayoutExpression(stringExpression: "{items[0]}", for: node)
        XCTAssertEqual(expression?.isConstant, true)
        XCTAssertEqual(try expression?.evaluate() as! String, "foo")
    }

    // MARK: Edge cases

    func testPercentOperatorSpacingAmbiguity() {
        let child = LayoutNode(expressions: ["width": "100%-5"])
        let parent = LayoutNode(expressions: ["width": "50"], children: [child])
        parent.update()
        XCTAssertEqual(child.frame.width, 45)
    }
}
