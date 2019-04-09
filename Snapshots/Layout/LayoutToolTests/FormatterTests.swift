//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest

class FormatterTests: XCTestCase {
    // MARK: Invalid expressions

    func testMalformedExpression() {
        let input = "<Foo left=\"+\"/>"
        XCTAssertThrowsError(try format(input)) { error in
            guard case let FormatError.parsing(message) = error else {
                XCTFail()
                return
            }
            XCTAssert(message.contains("+"))
            XCTAssert(message.contains("left"))
            XCTAssert(message.contains("Foo"))
        }
    }

    func testMalformedExpression2() {
        let input = "<Foo left=\"foo bar\"/>"
        XCTAssertThrowsError(try format(input)) { error in
            guard case let FormatError.parsing(message) = error else {
                XCTFail()
                return
            }
            XCTAssert(message.contains("bar"))
            XCTAssert(message.contains("left"))
            XCTAssert(message.contains("Foo"))
        }
    }

    func testUndefinedOperator() throws {
        let input = "<Foo left=\"a^b\"/>"
        XCTAssertThrowsError(try format(input)) { error in
            guard case let FormatError.parsing(message) = error else {
                XCTFail()
                return
            }
            XCTAssert(message.contains("infix operator ^"))
            XCTAssert(message.contains("left"))
            XCTAssert(message.contains("Foo"))
        }
    }

    func testRGBFunctionArity() throws {
        let input = "<Foo color=\"rgb(1,2,3,4)\"/>"
        XCTAssertThrowsError(try format(input)) { error in
            guard case let FormatError.parsing(message) = error else {
                XCTFail()
                return
            }
            XCTAssert(message.contains("rgb() expects 3"))
            XCTAssert(message.contains("color"))
            XCTAssert(message.contains("Foo"))
        }
    }

    // MARK: Attributes

    func testNoAttributes() {
        let input = "<Foo/>"
        let output = "<Foo/>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testSingleAttribute() {
        let input = "<Foo bar=\"baz\"/>"
        let output = "<Foo bar=\"baz\"/>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testMultipleAttributes() {
        let input = "<Foo bar=\"baz\" baz=\"quux\" />"
        let output = "<Foo\n    bar=\"baz\"\n    baz=\"quux\"\n/>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testSortAttributes() {
        let input = "<Foo b=\"b\" c=\"c\" a=\"a\"/>"
        let output = "<Foo\n    a=\"a\"\n    b=\"b\"\n    c=\"c\"\n/>\n"
        XCTAssertEqual(try format(input), output)
    }

    // MARK: Children

    func testEmptyNode() {
        let input = "<Foo>\n</Foo>"
        let output = "<Foo/>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testWhiteSpaceAroundNodeWithNoAttributes() {
        let input = "<Foo> <Bar/> </Foo>"
        let output = "<Foo>\n    <Bar/>\n</Foo>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testWhiteSpaceAroundNodeWithOneAttribute() {
        let input = "<Foo bar=\"bar\"> <Bar/> </Foo>"
        let output = "<Foo bar=\"bar\">\n    <Bar/>\n</Foo>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testWhiteSpaceAroundNodeWithMultipleAttributes() {
        let input = "<Foo\n    bar=\"bar\"\n    baz=\"baz\"> <Bar/> </Foo>"
        let output = "<Foo\n    bar=\"bar\"\n    baz=\"baz\">\n\n    <Bar/>\n</Foo>\n"
        XCTAssertEqual(try format(input), output)
    }

    // MARK: Body text

    func testShortTextNode() {
        let input = "<Foo>\n    bar\n</Foo>"
        let output = "<Foo>bar</Foo>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testTextWithChildBefore() {
        let input = "<Foo><Baz/>bar</Foo>"
        let output = "<Foo>\n    <Baz/>\n    bar\n</Foo>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testTextWithChildAfter() {
        let input = "<Foo>bar<Baz/></Foo>"
        let output = "<Foo>\n    bar\n    <Baz/>\n</Foo>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testTextWithCommentBefore() {
        let input = "<Foo><!-- bar -->bar</Foo>"
        let output = "<Foo>\n\n    <!-- bar -->\n    bar\n</Foo>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testTextWithCommentAfter() {
        let input = "<Foo>bar<!-- bar --></Foo>"
        let output = "<Foo>\n    bar\n\n    <!-- bar -->\n</Foo>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testTextWithInterleavedComments() {
        let input = "<Foo><!-- bar -->bar<!-- baz -->baz</Foo>"
        let output = "<Foo>\n\n    <!-- bar -->\n    bar\n\n    <!-- baz -->\n    baz\n</Foo>\n"
        XCTAssertEqual(try format(input), output)
    }

    // MARK: HTML

    func testNoTrimSpaceInHTML() {
        let input = "<Foo>hello<span> world</span></Foo>"
        let output = "<Foo>\n    hello<span> world</span>\n</Foo>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testIndentList() {
        let input = "<ul><li>foo</li><li>bar</li></ul>"
        let output = "<ul>\n    <li>foo</li>\n    <li>bar</li>\n</ul>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testPreserveListIndenting() {
        let input = "<ul>\n    <li>foo</li>\n    <li>bar</li>\n</ul>"
        let output = "<ul>\n    <li>foo</li>\n    <li>bar</li>\n</ul>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testIndentMultilineText() {
        let input = "<Foo><p>foo\nbar</p></Foo>"
        let output = "<Foo>\n    <p>foo\n    bar</p>\n</Foo>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testPreserveMultilineTextIndent() {
        let input = "<Foo>\n    <p>\n        foo\n        <b>bar</b> baz\n    </p>\n</Foo>"
        let output = "<Foo>\n    <p>\n        foo\n        <b>bar</b> baz\n    </p>\n</Foo>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testLayoutdNodeInsideHTMLP() {
        let input = "<p><Foo/></p>"
        let output = "<p>\n    <Foo/>\n</p>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testLayoutNodeInsideHTMLBR() {
        let input = "<br><Foo/></br>"
        let output = "<br>\n    <Foo/>\n</br>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testNoRemoveSpaceAfterFirstHTMLTag() {
        let input = "<UIView height=\"auto\">\n    <i>hello</i> cruel <b>world</b>\n</UIView>"
        let output = "<UIView height=\"auto\">\n    <i>hello</i> cruel <b>world</b>\n</UIView>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testNoRemoveIndentForClosingHTMLTag() {
        let input = "<UILabel>\n    <p>\n        hello world\n    </p>\n</UILabel>"
        let output = "<UILabel>\n    <p>\n        hello world\n    </p>\n</UILabel>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testNoInsertBlankLineInHTMLTagWithAttributes() {
        let input = "<UILabel>\n    <p bar=\"bar\" baz=\"baz\">\n        hello <b>world</b>\n    </p>\n</UILabel>"
        let output = "<UILabel>\n    <p bar=\"bar\" baz=\"baz\">\n        hello <b>world</b>\n    </p>\n</UILabel>\n"
        XCTAssertEqual(try format(input), output)
    }

    // MARK: Comments

    func testLeadingComment() {
        let input = "<!-- foo --><Foo/>"
        let output = "<!-- foo -->\n<Foo/>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testInnerComment() {
        let input = "<Foo><!-- foo --></Foo>"
        let output = "<Foo><!-- foo --></Foo>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testNoMultipleLinebreaksBetweenNodeAndComment() {
        let input = "<Foo>\n\n    <Bar/>\n\n    <!-- baz -->\n    <Baz/>\n\n</Foo>"
        let output = "<Foo>\n    <Bar/>\n\n    <!-- baz -->\n    <Baz/>\n</Foo>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testNoMultipleLinebreaksAfterAttributesBeforeComment() {
        let input = "<Foo\n    bar=\"bar\"\n    baz=\"baz\">\n\n    <!-- bar -->\n    <Bar/>\n\n</Foo>"
        let output = "<Foo\n    bar=\"bar\"\n    baz=\"baz\">\n\n    <!-- bar -->\n    <Bar/>\n</Foo>\n"
        XCTAssertEqual(try format(input), output)
    }

    // MARK: Parameters and macros

    func testViewWithParameterAndChildren() {
        let input = "<Foo>\n\n    <Bar/>\n\n    <param name=\"baz\" type=\"String\"/>\n    <Baz/>\n\n</Foo>"
        let output = "<Foo>\n    <param name=\"baz\" type=\"String\"/>\n\n    <Bar/>\n    <Baz/>\n</Foo>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testViewWithMultipleParametersAndChildren() {
        let input = "<Foo>\n    <param name=\"bar\" type=\"String\"/>\n    <param name=\"baz\" type=\"String\"/>\n\n    <Bar/>\n    <Baz/>\n</Foo>"
        let output = "<Foo>\n    <param name=\"bar\" type=\"String\"/>\n    <param name=\"baz\" type=\"String\"/>\n\n    <Bar/>\n    <Baz/>\n</Foo>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testViewWithMultipleParametersWithCommentsAndChildren() {
        let input = "<Foo>\n    <param name=\"foo\" type=\"String\"/>\n\n    <!-- bar -->\n    <param name=\"bar\" type=\"String\"/>\n    <param name=\"baz\" type=\"String\"/>\n\n    <Bar/>\n</Foo>"
        let output = "<Foo>\n    <param name=\"foo\" type=\"String\"/>\n\n    <!-- bar -->\n    <param name=\"bar\" type=\"String\"/>\n    <param name=\"baz\" type=\"String\"/>\n\n    <Bar/>\n</Foo>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testViewWithMacroAndChildren() {
        let input = "<Foo>\n\n    <Bar/>\n\n    <macro name=\"baz\" value=\"5\"/>\n    <Baz/>\n\n</Foo>"
        let output = "<Foo>\n    <macro name=\"baz\" value=\"5\"/>\n\n    <Bar/>\n    <Baz/>\n</Foo>\n"
        XCTAssertEqual(try format(input), output)
    }

    // MARK: Children tag

    func testViewWithChildrenTag() {
        let input = "<Foo>\n\n    <children/>\n\n</Foo>"
        let output = "<Foo>\n    <children/>\n</Foo>\n"
        XCTAssertEqual(try format(input), output)
    }

    // MARK: Encoding

    func testEncodeAmpersandInText() {
        let input = "<Foo>bar &amp; baz</Foo>"
        let output = "<Foo>bar &amp; baz</Foo>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testNoEncodeDoubleQuoteInText() {
        let input = "<Foo>\"bar\"</Foo>"
        let output = "<Foo>\"bar\"</Foo>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testEncodeAmpersandInAttribute() {
        let input = "<Foo\n    bar=\"baz &amp; quux\"\n    baz=\"baz\"\n/>"
        let output = "<Foo\n    bar=\"baz &amp; quux\"\n    baz=\"baz\"\n/>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testEncodeDoubleQuoteInAttribute() {
        let input = "<Foo\n    bar=\"&quot;bar&quot;\"\n    baz=\"baz\"\n/>"
        let output = "<Foo\n    bar=\"&quot;bar&quot;\"\n    baz=\"baz\"\n/>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testNoEncodeCommentBody() {
        let input = "<!-- <Foo>\"bar & baz\"</Foo> --><Bar/>"
        let output = "<!-- <Foo>\"bar & baz\"</Foo> -->\n<Bar/>\n"
        XCTAssertEqual(try format(input), output)
    }

    // MARK: Expressions

    func testFormatKnownExpressionAttribute() {
        let input = "<Foo top=\"10-5* 4\"/>"
        let output = "<Foo top=\"10 - 5 * 4\"/>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testFormatUnknownExpressionAttribute() {
        let input = "<Foo bar=\"foo-bar\"/>"
        let output = "<Foo bar=\"foo-bar\"/>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testFormatUnknownEscapedExpressionAttribute() {
        let input = "<Foo bar=\"{foo-bar}\"/>"
        let output = "<Foo bar=\"{foo - bar}\"/>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testFormatUnknownColorAttribute() {
        let input = "<Foo barColor=\"rgb(255,255,0)\"/>"
        let output = "<Foo barColor=\"rgb(255, 255, 0)\"/>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testFormatTextAttribute() {
        let input = "<Foo text=\" foo ( bar ) \"/>"
        let output = "<Foo text=\" foo ( bar ) \"/>\n"
        XCTAssertEqual(try format(input), output)
    }

    // MARK: Expression comments

    func testExpressionWithComment() {
        let input = "<Foo top=\"10-5* 4//foo\"/>"
        let output = "<Foo top=\"10 - 5 * 4 // foo\"/>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testExpressionWithCommentInBraces() {
        let input = "<Foo top=\"{10-5* 4//foo}\"/>"
        let output = "<Foo top=\"10 - 5 * 4 // foo\"/>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testStringExpressionWithComment() {
        let input = "<Foo text=\"hello {10-5* 4//foo} world\"/>"
        let output = "<Foo text=\"hello {10 - 5 * 4 // foo} world\"/>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testCommentedOutExpression() {
        let input = "<Foo top=\"//10-5* 4 \"/>"
        let output = "<Foo top=\"// 10-5* 4\"/>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testCommentedOutExpressionInBraces() {
        let input = "<Foo top=\" {//10-5* 4} \"/>"
        let output = "<Foo top=\"// 10-5* 4\"/>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testCommentBeforeExpressionInBraces() {
        let input = "<Foo top=\" //{10-5* 4} \"/>"
        let output = "<Foo top=\"// {10-5* 4}\"/>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testCommentedOutStringExpression() {
        let input = "<Foo text=\" //hello world\"/>"
        let output = "<Foo text=\"// hello world\"/>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testCommentedOutStringExpressionClause() {
        let input = "<Foo text=\"{ //10-5* 4 }\"/>"
        let output = "<Foo text=\"{// 10-5* 4}\"/>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testCommentedOutStringExpressionClause2() {
        let input = "<Foo text=\"foo { //10-5* 4 }bar\"/>"
        let output = "<Foo text=\"foo {// 10-5* 4}bar\"/>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testCommentedOutColorExpression() {
        let input = "<UIImageView image=\" //MyColor\"/>"
        let output = "<UIImageView image=\"// MyColor\"/>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testCommentedOutImageExpression() {
        let input = "<UIImageView image=\" //MyImage.png\"/>"
        let output = "<UIImageView image=\"// MyImage.png\"/>\n"
        XCTAssertEqual(try format(input), output)
    }

    func testCommentedOutURLExpressionWithoutComment() {
        let input = "<Foo url=\"//http://example.com\"/>"
        let output = "<Foo url=\"// http://example.com\"/>\n"
        XCTAssertEqual(try format(input), output)
    }
}
