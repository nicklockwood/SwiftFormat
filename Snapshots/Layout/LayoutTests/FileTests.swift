//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest
@testable import Layout

class FileTests: XCTestCase {
    // MARK: Ignore file

    func testLoadNonexistentIgnoreFile() {
        let inputURL = URL(fileURLWithPath: "does-not-exist.foo")
        XCTAssertThrowsError(try parseIgnoreFile(inputURL)) { error in
            XCTAssertTrue("\(error)".contains("no such file"))
        }
    }

    func testLoadMalformedIgnoreFile() {
        let inputURL = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .appendingPathComponent("UTF16.txt")
        XCTAssertThrowsError(try parseIgnoreFile(inputURL)) { error in
            XCTAssertTrue("\(error)".contains("Unable to read"))
        }
    }

    func testParseIgnoreFile() {
        let baseURL = URL(fileURLWithPath: "/")
        let file = "foo/\nbar/"
        let result = parseIgnoreFile(file, baseURL: baseURL)
        XCTAssertEqual(result, [
            URL(fileURLWithPath: "/foo"),
            URL(fileURLWithPath: "/bar"),
        ])
    }

    func testParseIgnoreFileWithCommentedLine() {
        let baseURL = URL(fileURLWithPath: "/")
        let file = "# foo/\nbar/"
        let result = parseIgnoreFile(file, baseURL: baseURL)
        XCTAssertEqual(result, [
            URL(fileURLWithPath: "/bar"),
        ])
    }

    func testParseIgnoreFileWithLineContainingComment() {
        let baseURL = URL(fileURLWithPath: "/")
        let file = "foo/ #comment\nbar/"
        let result = parseIgnoreFile(file, baseURL: baseURL)
        XCTAssertEqual(result, [
            URL(fileURLWithPath: "/foo"),
            URL(fileURLWithPath: "/bar"),
        ])
    }
}
