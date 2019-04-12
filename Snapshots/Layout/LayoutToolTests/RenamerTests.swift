//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest

class RenamerTests: XCTestCase {
    func testRenameStandaloneVariable() {
        let input = "<Foo bar=\"foo\"/>"
        let expected = "<Foo bar=\"bar\"/>\n"
        let output = try! rename("foo", to: "bar", in: input)
        XCTAssertEqual(output, expected)
    }

    func testRenameVariableInExpression() {
        let input = "<Foo bar=\"(foo + bar) * 5\"/>"
        let expected = "<Foo bar=\"(bar + bar) * 5\"/>\n"
        let output = try! rename("foo", to: "bar", in: input)
        XCTAssertEqual(output, expected)
    }

    func testNoRenameTextInStringExpression() {
        let input = "<Foo title=\"foo + bar\"/>"
        let expected = "<Foo title=\"foo + bar\"/>\n"
        let output = try! rename("foo", to: "bar", in: input)
        XCTAssertEqual(output, expected)
    }

    func testRenameVariableInEscapedStringExpression() {
        let input = "<Foo title=\"{foo + bar}\"/>"
        let expected = "<Foo title=\"{bar + bar}\"/>\n"
        let output = try! rename("foo", to: "bar", in: input)
        XCTAssertEqual(output, expected)
    }

    func testRenameClass() {
        let input = "<Foo bar=\"bar\"/>"
        let expected = "<Bar bar=\"bar\"/>\n"
        let output = try! rename("Foo", to: "Bar", in: input)
        XCTAssertEqual(output, expected)
    }

    func testNoRenameHTML() {
        let input = "<UILabel align=\"center\">\n    <center>foo</center>\n</UILabel>\n"
        let expected = "<UILabel align=\"centered\">\n    <center>foo</center>\n</UILabel>\n"
        let output = try! rename("center", to: "centered", in: input)
        XCTAssertEqual(output, expected)
    }
}
