//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest
@testable import Layout

final class XMLTests: XCTestCase {
    // MARK: Malformed XML

    func testEmptyXML() throws {
        let input = ""
        XCTAssertThrowsError(try Layout(xmlData: XCTUnwrap(input.data(using: .utf8)))) { error in
            XCTAssert("\(error)".contains("Empty"))
        }
    }

    func testHTMLAtRoot() throws {
        let input = "<html></html>"
        XCTAssertThrowsError(try Layout(xmlData: XCTUnwrap(input.data(using: .utf8)))) { error in
            XCTAssert("\(error)".contains("Invalid root"))
        }
    }

    func testViewInsideHTML() throws {
        let input = "<UIView><p><UIView/></p></UIView>"
        XCTAssertThrowsError(try Layout(xmlData: XCTUnwrap(input.data(using: .utf8)))) { error in
            XCTAssert("\(error)".contains("Unsupported HTML"))
        }
    }

    func testViewInsideHTMLInsideLabel() throws {
        let input = "<UILabel><p>hello <UIView/> world</p></UILabel>"
        XCTAssertThrowsError(try Layout(xmlData: XCTUnwrap(input.data(using: .utf8)))) { error in
            guard let layoutError = error as? LayoutError else {
                XCTFail("\(error)")
                return
            }
            XCTAssertTrue("\(layoutError)".contains("Unsupported HTML"))
            XCTAssertTrue("\(layoutError)".contains("UIView"))
        }
    }

    func testMismatchedHTML() throws {
        let input = "<UILabel>Some <b>bold</bold> text</UILabel>"
        let xmlData = try XCTUnwrap(input.data(using: .utf8))
        XCTAssertThrowsError(try Layout(xmlData: xmlData)) { error in
            XCTAssert("\(error)".contains("bold"))
        }
    }

    func testMissingParameterAttribute() throws {
        let input = "<UILabel><param name=\"text\" value=\"foo\"/></UILabel>"
        let xmlData = try XCTUnwrap(input.data(using: .utf8))
        XCTAssertThrowsError(try Layout(xmlData: xmlData)) { error in
            XCTAssert("\(error)".contains("type is a required attribute"))
        }
    }

    func testExtraParameterAttribute() throws {
        let input = "<UILabel><param name=\"text\" type=\"String\" value=\"foo\"/></UILabel>"
        let xmlData = try XCTUnwrap(input.data(using: .utf8))
        XCTAssertThrowsError(try Layout(xmlData: xmlData)) { error in
            XCTAssert("\(error)".contains("Unexpected attribute value"))
        }
    }

    func testUnknownParameterType() throws {
        let input = "<UILabel><param name=\"text\" type=\"Foo\"/></UILabel>"
        let xmlData = try XCTUnwrap(input.data(using: .utf8))
        XCTAssertThrowsError(try Layout(xmlData: xmlData)) { error in
            XCTAssert("\(error)".contains("Unknown or unsupported type"))
        }
    }

    func testChildNodeInParameter() throws {
        let input = "<UILabel><param name=\"text\">foo</param></UILabel>"
        let xmlData = try XCTUnwrap(input.data(using: .utf8))
        XCTAssertThrowsError(try Layout(xmlData: xmlData)) { error in
            XCTAssert("\(error)".contains("should not contain sub-nodes"))
        }
    }

    func testMissingMacroAttribute() throws {
        let input = "<UILabel><macro key=\"text\" value=\"foo\"/></UILabel>"
        let xmlData = try XCTUnwrap(input.data(using: .utf8))
        XCTAssertThrowsError(try Layout(xmlData: xmlData)) { error in
            XCTAssert("\(error)".contains("name is a required attribute"))
        }
    }

    func testExtraMacroAttribute() throws {
        let input = "<UILabel><macro name=\"text\" type=\"String\" value=\"foo\"/></UILabel>"
        let xmlData = try XCTUnwrap(input.data(using: .utf8))
        XCTAssertThrowsError(try Layout(xmlData: xmlData)) { error in
            XCTAssert("\(error)".contains("Unexpected attribute type"))
        }
    }

    func testChildNodeInMacro() throws {
        let input = "<UILabel><macro name=\"text\">foo</macro></UILabel>"
        let xmlData = try XCTUnwrap(input.data(using: .utf8))
        XCTAssertThrowsError(try Layout(xmlData: xmlData)) { error in
            XCTAssert("\(error)".contains("should not contain sub-nodes"))
        }
    }

    func testStringInOutletAttribute() throws {
        let input = "<UILabel outlet=\"foo\"/>"
        let xmlData = try XCTUnwrap(input.data(using: .utf8))
        XCTAssertNoThrow(try Layout(xmlData: xmlData))
    }

    func testCommentedOutOutletAttribute() throws {
        let input = "<UILabel outlet=\"//foo\"/>"
        let xmlData = try XCTUnwrap(input.data(using: .utf8))
        XCTAssertNoThrow(try Layout(xmlData: xmlData))
    }

    func testEmptyOutletAttribute() throws {
        let input = "<UILabel outlet=\"\"/>"
        let xmlData = try XCTUnwrap(input.data(using: .utf8))
        XCTAssertNoThrow(try Layout(xmlData: xmlData))
    }

    func testExpressionInXMLAttribute() throws {
        let input = "<UILabel xml=\"{foo}\"/>"
        let xmlData = try XCTUnwrap(input.data(using: .utf8))
        XCTAssertThrowsError(try Layout(xmlData: xmlData)) { error in
            XCTAssert("\(error)".contains("xml must be a literal value"))
        }
    }

    func testExpressionInTemplateAttribute() throws {
        let input = "<UILabel template=\"{foo}.xml\"/>"
        let xmlData = try XCTUnwrap(input.data(using: .utf8))
        XCTAssertThrowsError(try Layout(xmlData: xmlData)) { error in
            XCTAssert("\(error)".contains("template must be a literal value"))
        }
    }

    // MARK: White space

    func testDiscardLeadingWhitespace() throws {
        let input = "    <UIView/>"
        let xmlData = try XCTUnwrap(input.data(using: .utf8))
        let xml = try XMLParser.parse(data: xmlData)
        guard xml.count == 1, case let .node(name, _, _) = xml[0] else {
            XCTFail()
            return
        }
        XCTAssertEqual(name, "UIView")
    }

    func testDiscardWhitespaceInsideLabel() throws {
        let input = "<UILabel>\n    Foo\n</UILabel>"
        let xmlData = try XCTUnwrap(input.data(using: .utf8))
        let layout = try Layout(xmlData: xmlData)
        XCTAssertEqual(layout.body, "Foo")
    }

    func testInterleavedTextAndViewsInsideLabel() throws {
        let input = "<UILabel>Foo<UIView/>Bar</UILabel>"
        let xmlData = try XCTUnwrap(input.data(using: .utf8))
        let layout = try Layout(xmlData: xmlData)
        XCTAssertEqual(layout.body, "FooBar")
    }

    func testPreserveWhitespaceInsideHTML() throws {
        let html = "Some <b>bold </b>and<i> italic</i> text"
        let input = "<UILabel>\n    \(html)\n</UILabel>"
        let xmlData = try XCTUnwrap(input.data(using: .utf8))
        let layout = try Layout(xmlData: xmlData)
        XCTAssertEqual(layout.body, html)
    }

    func testPreserveHTMLAttributes() throws {
        let html = "An <img src=\"foo.jpg\"/> tag"
        let input = "<UILabel>\n    \(html)\n</UILabel>"
        let xmlData = try XCTUnwrap(input.data(using: .utf8))
        let layout = try Layout(xmlData: xmlData)
        XCTAssertEqual(layout.body, html)
    }

    // MARK: Entity encoding

    func testEncodeXMLEntities() {
        let input = "if 2 > 3 && 1 < 4"
        let expected = "if 2 > 3 &amp;&amp; 1 &lt; 4"
        XCTAssertEqual(input.xmlEncoded(), expected)
    }

    func testNoEncodeHTMLEntitiesInText() throws {
        let text = "2 legs are < 4 legs"
        let input = "<UILabel>\(text.xmlEncoded())</UILabel>"
        let xmlData = try XCTUnwrap(input.data(using: .utf8))
        let layout = try Layout(xmlData: xmlData)
        XCTAssertEqual(layout.body, text)
    }

    func testEncodeHTMLEntitiesInHTML() throws {
        let html = "2 legs are &lt; 4 legs<br/>"
        let input = "<UILabel>\(html)</UILabel>"
        let xmlData = try XCTUnwrap(input.data(using: .utf8))
        let layout = try Layout(xmlData: xmlData)
        XCTAssertEqual(layout.body, html)
    }

    func testEncodeHTMLEntitiesInHTML2() throws {
        let html = "<p>2 legs are &lt; 4 legs</p>"
        let input = "<UILabel>\(html)</UILabel>"
        let xmlData = try XCTUnwrap(input.data(using: .utf8))
        let layout = try Layout(xmlData: xmlData)
        XCTAssertEqual(layout.body, html)
    }

    func testEncodeHTMLEntitiesInHTML3() throws {
        let html = "<b>trial</b> &amp; error"
        let input = "<UILabel>\(html)</UILabel>"
        let xmlData = try XCTUnwrap(input.data(using: .utf8))
        let layout = try Layout(xmlData: xmlData)
        XCTAssertEqual(layout.body, html)
    }
}
