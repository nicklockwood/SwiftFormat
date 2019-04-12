//
//  ShapeTests.swift
//  GeometryScriptTests
//
//  Created by Nick Lockwood on 09/10/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import Euclid

class ShapeTests: XCTestCase {
    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS)
        let thisClass = type(of: self)
        let linuxCount = thisClass.__allTests.count
        let darwinCount = thisClass.defaultTestSuite.testCaseCount
        XCTAssertEqual(linuxCount, darwinCount, "run swift test --generate-linuxmain")
        #endif
    }

    // MARK: Curve

    func testCurveWithConsecutiveMixedTypePointsWithSamePosition() {
        let points: [PathPoint] = [
            .point(-1, 1),
            .point(-1, -1),
            .point(1, -1),
            .curve(1, -1),
            .point(1, 1),
            .point(-1, 1),
        ]
        _ = Path(points)
    }

    func testSimpleCurvedPath() {
        let points: [PathPoint] = [
            .point(-1, -1),
            .curve(0, 1),
            .point(1, -1),
        ]
        XCTAssertEqual(Path.curve(points, detail: 0).points, points)
        XCTAssertEqual(Path.curve(points, detail: 1).points, [
            .point(-1, -1),
            .curve(-1 / 3, -1 / 9),
            .curve(1 / 3, -1 / 9),
            .point(1, -1),
        ] as [PathPoint])
        XCTAssertEqual(Path.curve(points, detail: 2).points, [
            .point(-1, -1),
            .curve(-0.5, -0.25),
            .curve(0, 0),
            .curve(0.5, -0.25),
            .point(1, -1),
        ])
    }

    func testSimpleCurveEndedPath() {
        let points: [PathPoint] = [
            .curve(0, 1),
            .point(-1, 0),
            .curve(0, -1),
        ]
        XCTAssertEqual(Path.curve(points, detail: 0).points, points)
        XCTAssertEqual(Path.curve(points, detail: 1).points, [
            .curve(0, 0.5),
            .point(-1, 0),
            .curve(0, -0.5),
        ])
    }

    func testClosedCurvedPath() {
        let points: [PathPoint] = [
            .curve(-1, 1),
            .curve(1, 1),
            .curve(1, -1),
            .curve(-1, -1),
            .curve(-1, 1),
        ]
        XCTAssertEqual(Path.curve(points, detail: 0).points, points)
        XCTAssertEqual(Path.curve(points, detail: 1).points, [
            .curve(-1, 0),
            .curve(-0.75, 0.75),
            .curve(0, 1),
            .curve(0.75, 0.75),
            .curve(1, 0),
            .curve(0.75, -0.75),
            .curve(0, -1),
            .curve(-0.75, -0.75),
            .curve(-1, 0),
        ])
    }

    func testClosedCurvedPathWithSharpFirstCorner() {
        let points: [PathPoint] = [
            .point(-1, 1),
            .curve(1, 1),
            .curve(1, -1),
            .curve(-1, -1),
            .point(-1, 1),
        ]
        XCTAssertEqual(Path.curve(points, detail: 0).points, points)
        XCTAssertEqual(Path.curve(points, detail: 1).points, [
            .point(-1, 1),
            .curve(0.5, 0.75),
            .curve(1, 0),
            .curve(0.75, -0.75),
            .curve(0, -1),
            .curve(-0.75, -0.5),
            .point(-1, 1),
        ])
    }

    func testClosedCurvedPathWithSharpSecondCorner() {
        let points: [PathPoint] = [
            .curve(-1, 1),
            .point(1, 1),
            .curve(1, -1),
            .curve(-1, -1),
            .curve(-1, 1),
        ]
        XCTAssertEqual(Path.curve(points, detail: 0).points, points)
        XCTAssertEqual(Path.curve(points, detail: 1).points, [
            .curve(-1, 0),
            .curve(-0.5, 0.75),
            .point(1, 1),
            .curve(0.75, -0.5),
            .curve(0, -1),
            .curve(-0.75, -0.75),
            .curve(-1, 0),
        ])
    }

    func testClosedCurvedPathWithSharpSecondAndThirdCorner() {
        let points: [PathPoint] = [
            .curve(-1, 1),
            .point(1, 1),
            .point(1, -1),
            .curve(-1, -1),
            .curve(-1, 1),
        ]
        XCTAssertEqual(Path.curve(points, detail: 0).points, points)
        XCTAssertEqual(Path.curve(points, detail: 1).points, [
            .curve(-1, 0),
            .curve(-0.5, 0.75),
            .point(1, 1),
            .point(1, -1),
            .curve(-0.5, -0.75),
            .curve(-1, 0),
        ])
    }
}
