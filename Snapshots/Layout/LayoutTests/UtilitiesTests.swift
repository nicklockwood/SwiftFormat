//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest
@testable import Layout

class UtilitiesTests: XCTestCase {
    // MARK: StringUtils

    // Unicode scalars

    func testAScalarIsUppercase() {
        let char: Unicode.Scalar = "A"
        XCTAssertTrue(char.isUppercase)
    }

    func testAScalarIsNotUppercase() {
        let char: Unicode.Scalar = "a"
        XCTAssertFalse(char.isUppercase)
    }

    func testNumberScalarIsNotUppercase() {
        let char: Unicode.Scalar = "9"
        XCTAssertFalse(char.isUppercase)
    }

    func testAScalarIsLowercase() {
        let char: Unicode.Scalar = "a"
        XCTAssertTrue(char.isLowercase)
    }

    func testAScalarIsNotLowercase() {
        let char: Unicode.Scalar = "A"
        XCTAssertFalse(char.isLowercase)
    }

    func testNumberScalarIsNotLowercase() {
        let char: Unicode.Scalar = "9"
        XCTAssertFalse(char.isLowercase)
    }

    func testUppercaseAScalar() {
        let char: Unicode.Scalar = "a"
        XCTAssertEqual(char.uppercased(), "A")
    }

    func testUppercaseZScalar() {
        let char: Unicode.Scalar = "z"
        XCTAssertEqual(char.uppercased(), "Z")
    }

    func testUppercaseNumberScalar() {
        let char: Unicode.Scalar = "9"
        XCTAssertEqual(char.uppercased(), "9")
    }

    func testUppercaseEmojiScalar() {
        let char: Unicode.Scalar = "😊"
        XCTAssertEqual(char.uppercased(), "😊")
    }

    func testLowercaseAScalar() {
        let char: Unicode.Scalar = "A"
        XCTAssertEqual(char.lowercased(), "a")
    }

    func testLowercaseZScalar() {
        let char: Unicode.Scalar = "Z"
        XCTAssertEqual(char.lowercased(), "z")
    }

    func testLowercaseNumberScalar() {
        let char: Unicode.Scalar = "Z"
        XCTAssertEqual(char.lowercased(), "z")
    }

    // Characters

    func testIsUppercaseACharacter() {
        let char: Character = "A"
        XCTAssertTrue(char.isUppercase)
    }

    func testIsNotUppercaseACharacter() {
        let char: Character = "a"
        XCTAssertFalse(char.isUppercase)
    }

    func testUppercaseACharacter() {
        let char: Character = "a"
        XCTAssertEqual(char.uppercased(), "A")
    }

    func testUppercaseZCharacter() {
        let char: Character = "z"
        XCTAssertEqual(char.uppercased(), "Z")
    }

    func testUppercaseEmojiCharacter() {
        let char: Character = "👨‍👩‍👦‍👦"
        XCTAssertEqual(char.uppercased(), "👨‍👩‍👦‍👦")
    }

    // Strings

    func testCapitalizeFoo() {
        XCTAssertEqual("foo".capitalized, "Foo")
    }

    func testCapitalizeFooBar() {
        XCTAssertEqual("fooBar".capitalized(), "FooBar")
    }

    func testCapitalize_fooBar() {
        XCTAssertEqual("_fooBar".capitalized(), "_fooBar")
    }

    func testUnCapitalizeFooBar() {
        XCTAssertEqual("FooBar".unCapitalized(), "fooBar")
    }

    func testUnCapitalizefooBar() {
        XCTAssertEqual("fooBar".unCapitalized(), "fooBar")
    }

    // MARK: urlFromString

    func testURLFromAbsoluteURL() {
        let input = "http://example.com"
        let output = URL(string: input)
        XCTAssertEqual(urlFromString(input), output)
    }

    func testURLFromDataURL() {
        let input = "data:blahblah"
        let output = URL(string: input)
        XCTAssertEqual(urlFromString(input), output)
    }

    func testURLFromRelativePath() {
        let input = "foo.xml"
        let output = Bundle.main.resourceURL?.appendingPathComponent(input)
        XCTAssertEqual(urlFromString(input), output)
    }

    func testURLFromRelativePathWithBaseURL() {
        let input = "foo.xml"
        let baseURL = URL(string: "http://example.com/bar/ba.xml")
        let output = URL(string: input, relativeTo: baseURL)
        XCTAssertEqual(urlFromString(input, relativeTo: baseURL), output)
    }

    func testURLFromUserPath() {
        let input = "~/foo.xml"
        let output = URL(fileURLWithPath: (input as NSString).expandingTildeInPath)
        XCTAssertEqual(urlFromString(input), output)
    }

    func testURLFromUserPathWithBaseURL() {
        let input = "~/foo.xml"
        let baseURL = URL(string: "http://example.com/bar.xml")
        let output = URL(fileURLWithPath: (input as NSString).expandingTildeInPath)
        XCTAssertEqual(urlFromString(input, relativeTo: baseURL), output)
    }
}
