//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest
@testable import Layout

private class TestView: UIView {
    @objc var nestedTestView = TestView()

    @objc override open class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["backgroundColor"] = .unavailable("For reasons")
        return types
    }
}

private class TestObject: NSObject {
    @objc var testView = TestView()
    @objc var testPoint = CGPoint(x: 1, y: 2)
    @objc var testRect = CGRect(x: 1, y: 2, width: 3, height: 4)
}

class PropertiesTests: XCTestCase {
    // MARK: Property types

    func testPropertyType() {
        let result = TestObject.allPropertyTypes()["testView"]
        let expected = RuntimeType(TestView.self)
        let control = RuntimeType(NSObject.self)
        XCTAssertEqual(result, expected)
        XCTAssertNotEqual(result, control)
    }

    func testNestedPropertyType() {
        let result = TestObject.allPropertyTypes()["testView.backgroundColor"]
        XCTAssertNil(result) // Not supoported yet
    }

    func testCGPointPropertyType() {
        let result = TestObject.allPropertyTypes()["testPoint"]!
        let expected = RuntimeType(CGPoint.self)
        let control = RuntimeType(NSValue.self)
        XCTAssertEqual(result, expected)
        XCTAssertNotEqual(result, control)
    }

    func testCGPointNestedPropertyType() {
        let result = TestObject.allPropertyTypes()["testPoint.x"]
        let expected = RuntimeType(CGFloat.self)
        XCTAssertEqual(result, expected)
    }

    func testCGRectNestedPropertyType() {
        let result = TestObject.allPropertyTypes()["testRect.size.width"]
        let expected = RuntimeType(CGFloat.self)
        XCTAssertEqual(result, expected)
    }

    // MARK: View property types

    func testViewPropertyType() {
        let result = TestView.expressionTypes["backgroundColor"]
        let expected = RuntimeType.unavailable("For reasons")
        XCTAssertEqual(result, expected)
    }

    func testViewNestedPropertyType() {
        let result = TestView.expressionTypes["nestedTestView.backgroundColor"]
        XCTAssertNil(result) // Not supoported yet
    }

    func testViewDoubleNestedPropertyType() {
        let result = TestView.expressionTypes["layer.contentsCenter.x"]
        let expected = RuntimeType(CGFloat.self)
        XCTAssertEqual(result, expected)
    }

    // MARK: Unavailable properties

    func testNonexistentPropertyType() {
        let result = TestObject.allPropertyTypes()["foo"]
        XCTAssertNil(result)
    }

    func testNestedNonexistentPropertyType() {
        let result = TestObject.allPropertyTypes()["testPoint.foo"]
        XCTAssertNil(result)
    }

    func testUnavailablePropertyType() {
        let result = TestView.expressionTypes["frame"]
        XCTAssertEqual(result?.isAvailable, false)
    }

    func testNestedUnavailablePropertyType() {
        let result = TestView.expressionTypes["frame.origin.x"]
        XCTAssertEqual(result?.isAvailable, false)
    }
}
