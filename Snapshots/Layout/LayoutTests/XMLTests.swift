//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest
@testable import Layout

class XMLTests: XCTestCase {
    // MARK: Malformed XML

    func testEmptyXML() {
        let input = ""
        XCTAssertThrowsError(try Layout(xmlData: input.data(using: .utf8)!)) { error in
            XCTAssert("\(error)".contains("Empty"))
        }
    }

    func testHTMLAtRoot() {
        let input = "<html></html>"
        XCTAssertThrowsError(try Layout(xmlData: input.data(using: .utf8)!)) { error in
            XCTAssert("\(error)".contains("Invalid root"))
        }
    }

    func testViewInsideHTML() {
        let input = "<UIView><p><UIView/></p></UIView>"
        XCTAssertThrowsError(try Layout(xmlData: input.data(using: .utf8)!)) { error in
            XCTAssert("\(error)".contains("Unsupported HTML"))
        }
    }

    func testViewInsideHTMLInsideLabel() {
        let input = "<UILabel><p>hello <UIView/> world</p></UILabel>"
        XCTAssertThrowsError(try Layout(xmlData: input.data(using: .utf8)!)) { error in
            guard let layoutError = error as? LayoutError else {
                XCTFail("\(error)")
                return
            }
            XCTAssertTrue("\(layoutError)".contains("Unsupported HTML"))
            XCTAssertTrue("\(layoutError)".contains("UIView"))
        }
    }

    func testMismatchedHTML() {
        let input = "<UILabel>Some <b>bold</bold> text</UILabel>"
        let xmlData = input.data(using: .utf8)!
        XCTAssertThrowsError(try Layout(xmlData: xmlData)) { error in
            XCTAssert("\(error)".contains("bold"))
        }
    }

    func testMissingParameterAttribute() {
        let input = "<UILabel><param name=\"text\" value=\"foo\"/></UILabel>"
        let xmlData = input.data(using: .utf8)!
        XCTAssertThrowsError(try Layout(xmlData: xmlData)) { error in
            XCTAssert("\(error)".contains("type is a required attribute"))
        }
    }

    func testExtraParameterAttribute() {
        let input = "<UILabel><param name=\"text\" type=\"String\" value=\"foo\"/></UILabel>"
        let xmlData = input.data(using: .utf8)!
        XCTAssertThrowsError(try Layout(xmlData: xmlData)) { error in
            XCTAssert("\(error)".contains("Unexpected attribute value"))
        }
    }

    func testUnknownParameterType() {
        let input = "<UILabel><param name=\"text\" type=\"Foo\"/></UILabel>"
        let xmlData = input.data(using: .utf8)!
        XCTAssertThrowsError(try Layout(xmlData: xmlData)) { error in
            XCTAssert("\(error)".contains("Unknown or unsupported type"))
        }
    }

    func testChildNodeInParameter() {
        let input = "<UILabel><param name=\"text\">foo</param></UILabel>"
        let xmlData = input.data(using: .utf8)!
        XCTAssertThrowsError(try Layout(xmlData: xmlData)) { error in
            XCTAssert("\(error)".contains("should not contain sub-nodes"))
        }
    }

    func testMissingMacroAttribute() {
        let input = "<UILabel><macro key=\"text\" value=\"foo\"/></UILabel>"
        let xmlData = input.data(using: .utf8)!
        XCTAssertThrowsError(try Layout(xmlData: xmlData)) { error in
            XCTAssert("\(error)".contains("name is a required attribute"))
        }
    }

    func testExtraMacroAttribute() {
        let input = "<UILabel><macro name=\"text\" type=\"String\" value=\"foo\"/></UILabel>"
        let xmlData = input.data(using: .utf8)!
        XCTAssertThrowsError(try Layout(xmlData: xmlData)) { error in
            XCTAssert("\(error)".contains("Unexpected attribute type"))
        }
    }

    func testChildNodeInMacro() {
        let input = "<UILabel><macro name=\"text\">foo</macro></UILabel>"
        let xmlData = input.data(using: .utf8)!
        XCTAssertThrowsError(try Layout(xmlData: xmlData)) { error in
            XCTAssert("\(error)".contains("should not contain sub-nodes"))
        }
    }

    func testStringInOutletAttribute() {
        let input = "<UILabel outlet=\"foo\"/>"
        let xmlData = input.data(using: .utf8)!
        XCTAssertNoThrow(try Layout(xmlData: xmlData))
    }

    func testCommentedOutOutletAttribute() {
        let input = "<UILabel outlet=\"//foo\"/>"
        let xmlData = input.data(using: .utf8)!
        XCTAssertNoThrow(try Layout(xmlData: xmlData))
    }

    func testEmptyOutletAttribute() {
        let input = "<UILabel outlet=\"\"/>"
        let xmlData = input.data(using: .utf8)!
        XCTAssertNoThrow(try Layout(xmlData: xmlData))
    }

    func testExpressionInXMLAttribute() {
        let input = "<UILabel xml=\"{foo}\"/>"
        let xmlData = input.data(using: .utf8)!
        XCTAssertThrowsError(try Layout(xmlData: xmlData)) { error in
            XCTAssert("\(error)".contains("xml must be a literal value"))
        }
    }

    func testExpressionInTemplateAttribute() {
        let input = "<UILabel template=\"{foo}.xml\"/>"
        let xmlData = input.data(using: .utf8)!
        XCTAssertThrowsError(try Layout(xmlData: xmlData)) { error in
            XCTAssert("\(error)".contains("template must be a literal value"))
        }
    }

    // MARK: White space

    func testDiscardLeadingWhitespace() {
        let input = "    <UIView/>"
        let xmlData = input.data(using: .utf8)!
        let xml = try! XMLParser.parse(data: xmlData)
        guard xml.count == 1, case let .node(name, _, _) = xml[0] else {
            XCTFail()
            return
        }
        XCTAssertEqual(name, "UIView")
    }

    func testDiscardWhitespaceInsideLabel() {
        let input = "<UILabel>\n    Foo\n</UILabel>"
        let xmlData = input.data(using: .utf8)!
        let layout = try! Layout(xmlData: xmlData)
        XCTAssertEqual(layout.body, "Foo")
    }

    func testInterleavedTextAndViewsInsideLabel() {
        let input = "<UILabel>Foo<UIView/>Bar</UILabel>"
        let xmlData = input.data(using: .utf8)!
        let layout = try! Layout(xmlData: xmlData)
        XCTAssertEqual(layout.body, "FooBar")
    }

    func testPreserveWhitespaceInsideHTML() {
        let html = "Some <b>bold </b>and<i> italic</i> text"
        let input = "<UILabel>\n    \(html)\n</UILabel>"
        let xmlData = input.data(using: .utf8)!
        let layout = try! Layout(xmlData: xmlData)
        XCTAssertEqual(layout.body, html)
    }

    func testPreserveHTMLAttributes() {
        let html = "An <img src=\"foo.jpg\"/> tag"
        let input = "<UILabel>\n    \(html)\n</UILabel>"
        let xmlData = input.data(using: .utf8)!
        let layout = try! Layout(xmlData: xmlData)
        XCTAssertEqual(layout.body, html)
    }

    // MARK: Entity encoding

    func testEncodeXMLEntities() {
        let input = "if 2 > 3 && 1 < 4"
        let expected = "if 2 > 3 &amp;&amp; 1 &lt; 4"
        XCTAssertEqual(input.xmlEncoded(), expected)
    }

    func testNoEncodeHTMLEntitiesInText() {
        let text = "2 legs are < 4 legs"
        let input = "<UILabel>\(text.xmlEncoded())</UILabel>"
        let xmlData = input.data(using: .utf8)!
        let layout = try! Layout(xmlData: xmlData)
        XCTAssertEqual(layout.body, text)
    }

    func testEncodeHTMLEntitiesInHTML() {
        let html = "2 legs are &lt; 4 legs<br/>"
        let input = "<UILabel>\(html)</UILabel>"
        let xmlData = input.data(using: .utf8)!
        let layout = try! Layout(xmlData: xmlData)
        XCTAssertEqual(layout.body, html)
    }

    func testEncodeHTMLEntitiesInHTML2() {
        let html = "<p>2 legs are &lt; 4 legs</p>"
        let input = "<UILabel>\(html)</UILabel>"
        let xmlData = input.data(using: .utf8)!
        let layout = try! Layout(xmlData: xmlData)
        XCTAssertEqual(layout.body, html)
    }

    func testEncodeHTMLEntitiesInHTML3() {
        let html = "<b>trial</b> &amp; error"
        let input = "<UILabel>\(html)</UILabel>"
        let xmlData = input.data(using: .utf8)!
        let layout = try! Layout(xmlData: xmlData)
        XCTAssertEqual(layout.body, html)
    }
}
