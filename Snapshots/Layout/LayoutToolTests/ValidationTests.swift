//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest

class ValidationTests: XCTestCase {
    // MARK: XML validation

    func testMissingClosingChevron() {
        let input = "<Foo left=\"5\"></Foo"
        XCTAssertThrowsError(try parseXML(input)) { error in
            guard case let FormatError.parsing(message) = error else {
                XCTFail()
                return
            }
            XCTAssert(message.contains("line 1"))
            XCTAssert(message.contains(">"))
        }
    }

    func testMissingClosingQuote() {
        let input = "<Foo left=\"5/>"
        XCTAssertThrowsError(try parseXML(input)) { error in
            guard case let FormatError.parsing(message) = error else {
                XCTFail()
                return
            }
            XCTAssert(message.contains("line 1"))
            XCTAssert(message.contains("'"))
        }
    }

    // MARK: Format identification

    func testValidLayout() {
        let input = "<Foo left=\"5\"/>"
        let xml = try! parseXML(input)
        XCTAssertTrue(xml.isLayout)
    }

    func testInvalidLayout() {
        let input = "<html><p> Hello </p></html>"
        let xml = try! parseXML(input)
        XCTAssertFalse(xml.isLayout)
    }

    func testMalformedXML() {
        let input = "<Foo>\n    <Bar/>\n</Baz>\n"
        XCTAssertThrowsError(try parseXML(input)) { error in
            let description = "\(error)"
            XCTAssert(description.contains("Foo"))
            XCTAssert(description.contains("Baz"))
            XCTAssert(description.contains("line 3"))
        }
    }

    // MARK: Known node properties

    func testNonStringViewPropertyType() {
        let cls = "UILabel"
        let prop = "numberOfLines"
        let node = try! parseXML("<\(cls) \(prop)=\"\"/>")[0]
        let type = typeOfAttribute(prop, inNode: node) ?? "<unknown>"
        XCTAssertEqual(type, "Int")
        XCTAssertFalse(isStringType(type))
        XCTAssertEqual(attributeIsString(prop, inNode: node), false)
    }

    func testStringViewPropertyType() {
        let cls = "UILabel"
        let prop = "text"
        let node = try! parseXML("<\(cls) \(prop)=\"\"/>")[0]
        let type = typeOfAttribute(prop, inNode: node) ?? "<unknown>"
        XCTAssertEqual(type, "String")
        XCTAssertTrue(isStringType(type))
        XCTAssertEqual(attributeIsString(prop, inNode: node), true)
    }

    func testUnknownViewPropertyType() {
        let cls = "UILabel"
        let prop = "foo"
        let node = try! parseXML("<\(cls) \(prop)=\"\"/>")[0]
        let type = typeOfAttribute(prop, inNode: node)
        XCTAssertNil(type)
        XCTAssertNil(attributeIsString(prop, inNode: node))
    }

    func testViewParameterType() {
        let cls = "UILabel"
        let prop = "foo"
        let node = try! parseXML("<\(cls) \(prop)=\"\"><param name=\"foo\" type=\"Int\"/></\(cls)>")[0]
        let type = typeOfAttribute(prop, inNode: node) ?? "<unknown>"
        XCTAssertEqual(type, "Int")
        XCTAssertFalse(isStringType(type))
        XCTAssertEqual(attributeIsString(prop, inNode: node), false)
    }

    func testBuiltinAttributeType() {
        let cls = "UILabel"
        let prop = "template"
        let node = try! parseXML("<\(cls) \(prop)=\"\"/>")[0]
        let type = typeOfAttribute(prop, inNode: node) ?? "<unknown>"
        XCTAssertEqual(type, "URL")
        XCTAssertTrue(isStringType(type))
        XCTAssertEqual(attributeIsString(prop, inNode: node), true)
    }

    // MARK: Unknown node properties

    func testUIViewPropertyOfUnknownNode() {
        let cls = "Foo"
        let prop = "contentMode"
        let node = try! parseXML("<\(cls) \(prop)=\"\"/>")[0]
        let type = typeOfAttribute(prop, inNode: node)
        XCTAssertEqual(type, "UIViewContentMode")
        XCTAssertEqual(attributeIsString(prop, inNode: node), false)
    }

    func testUIViewControllerPropertyOfUnknownNode() {
        let cls = "Foo"
        let prop = "tabBarItem.systemItem"
        let node = try! parseXML("<\(cls) \(prop)=\"\"/>")[0]
        let type = typeOfAttribute(prop, inNode: node)
        XCTAssertNil(type)
        XCTAssertNil(attributeIsString(prop, inNode: node))
    }

    func testUIViewPropertyOfUnknownControllerNode() {
        let cls = "FooController"
        let prop = "contentMode"
        let node = try! parseXML("<\(cls) \(prop)=\"\"/>")[0]
        let type = typeOfAttribute(prop, inNode: node)
        XCTAssertEqual(type, "UIViewContentMode")
        XCTAssertEqual(attributeIsString(prop, inNode: node), false)
    }

    func testUIViewControllerPropertyOfUnknownControllerNode() {
        let cls = "FooController"
        let prop = "tabBarItem.systemItem"
        let node = try! parseXML("<\(cls) \(prop)=\"\"/>")[0]
        let type = typeOfAttribute(prop, inNode: node)
        XCTAssertEqual(type, "UITabBarSystemItem")
        XCTAssertEqual(attributeIsString(prop, inNode: node), false)
    }
}
