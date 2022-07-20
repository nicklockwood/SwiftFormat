//
//  VersionTests.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 28/01/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class VersionTests: XCTestCase {
    // MARK: Version parsing

    func testParseEmptyVersion() throws {
        let version = Version(rawValue: "")
        XCTAssertNil(version)
    }

    func testParseOrdinaryVersion() throws {
        let version = Version(rawValue: "4.2")
        XCTAssertEqual(version, "4.2")
    }

    func testParsePaddedVersion() throws {
        let version = Version(rawValue: " 4.2 ")
        XCTAssertEqual(version, "4.2")
    }

    func testParseThreePartVersion() throws {
        let version = Version(rawValue: "3.1.5")
        XCTAssertNotNil(version)
        XCTAssertEqual(version, "3.1.5")
    }

    func testParsePreviewVersion() throws {
        let version = Version(rawValue: "3.0-PREVIEW-4")
        XCTAssertNotNil(version)
        XCTAssertEqual(version, "3.0-PREVIEW-4")
    }

    func testComparison() throws {
        let version = Version(rawValue: "3.1.5")
        XCTAssertLessThan(version ?? "0", "3.2")
        XCTAssertGreaterThan(version ?? "0", "3.1.4")
    }

    func testPreviewComparison() throws {
        let version = Version(rawValue: "3.0-PREVIEW-4")
        XCTAssertLessThan(version ?? "0", "4.0")
        XCTAssertGreaterThan(version ?? "0", "2.0")
    }

    func testWildcardVersion() throws {
        let version = Version(rawValue: "3.x")
        XCTAssertNotNil(version)
        XCTAssertLessThan(version ?? "0", "4.0")
        XCTAssertGreaterThan(version ?? "0", "2.0")
    }

    func testLatestSwiftVersion() throws {
        let version = Version(rawValue: "latest")
        let latestVersion = Version(rawValue: latestSwiftVersion)
        XCTAssertEqual(version, latestVersion)
    }

    func testSpecifyLatestSwiftVersion() throws {
        let options = FormatOptions(swiftVersion: "latest")
        XCTAssertEqual(options.swiftVersion, Version(rawValue: latestSwiftVersion))
    }
}
