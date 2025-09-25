//
//  VersionTests.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 28/01/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class VersionTests: XCTestCase {
    // MARK: Version parsing

    func testParseEmptyVersion() {
        let version = Version(rawValue: "")
        XCTAssertNil(version)
    }

    func testParseOrdinaryVersion() {
        let version = Version(rawValue: "4.2")
        XCTAssertEqual(version, "4.2")
    }

    func testParsePaddedVersion() {
        let version = Version(rawValue: " 4.2 ")
        XCTAssertEqual(version, "4.2")
    }

    func testParseThreePartVersion() {
        let version = Version(rawValue: "3.1.5")
        XCTAssertNotNil(version)
        XCTAssertEqual(version, "3.1.5")
    }

    func testParsePreviewVersion() {
        let version = Version(rawValue: "3.0-PREVIEW-4")
        XCTAssertNotNil(version)
        XCTAssertEqual(version, "3.0-PREVIEW-4")
    }

    func testComparison() {
        let version = Version(rawValue: "3.1.5")
        XCTAssertLessThan(version ?? "0", "3.2")
        XCTAssertGreaterThan(version ?? "0", "3.1.4")
    }

    func testPreviewComparison() {
        let version = Version(rawValue: "3.0-PREVIEW-4")
        XCTAssertLessThan(version ?? "0", "4.0")
        XCTAssertGreaterThan(version ?? "0", "2.0")
    }

    func testWildcardVersion() {
        let version = Version(rawValue: "3.x")
        XCTAssertNotNil(version)
        XCTAssertLessThan(version ?? "0", "4.0")
        XCTAssertGreaterThan(version ?? "0", "2.0")
    }
}
