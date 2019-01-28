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

    func testComparison() throws {
        let version = Version(rawValue: "3.1.5")
        XCTAssertLessThan(version ?? "0", "3.2")
        XCTAssertGreaterThan(version ?? "0", "3.1.4")
    }
}
