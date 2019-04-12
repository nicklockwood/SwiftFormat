//
//  PlaneTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 19/12/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import Euclid

class PlaneTests: XCTestCase {
    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS)
        let thisClass = type(of: self)
        let linuxCount = thisClass.__allTests.count
        let darwinCount = thisClass.defaultTestSuite.testCaseCount
        XCTAssertEqual(linuxCount, darwinCount, "run swift test --generate-linuxmain")
        #endif
    }

    func testConcavePolygonClockwiseWinding() {
        var transform = Transform.identity
        var points = [Vector]()
        let sides = 5
        for _ in 0 ..< sides {
            points.append(Vector(0, -0.5).transformed(by: transform))
            transform.rotate(by: .roll(.pi / Double(sides)))
            points.append(Vector(0, -1).transformed(by: transform))
            transform.rotate(by: .roll(.pi / Double(sides)))
        }
        let plane = Plane(points: points)
        XCTAssertEqual(plane?.normal, Vector(0, 0, -1))
    }
}
