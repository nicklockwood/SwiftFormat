//
//  CGPathTests.swift
//  Euclid
//
//  Created by Nick Lockwood on 10/03/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

#if canImport(CoreGraphics)

import CoreGraphics
import XCTest
@testable import Euclid

class CGPathTests: XCTestCase {
    func testRectangularCGPath() {
        let cgRect = CGRect(x: 0, y: 0, width: 1, height: 2)
        let cgPath = CGPath(rect: cgRect, transform: nil)
        let path = Path(cgPath: cgPath)
        XCTAssertTrue(path.isClosed)
        XCTAssertEqual(path.points, [
            .point(0, 0),
            .point(1, 0),
            .point(1, 2),
            .point(0, 2),
            .point(0, 0),
        ])
    }

    func testUnclosedLineAndQuadCurveCGPath() {
        let cgPath = CGMutablePath()
        cgPath.move(to: .zero)
        cgPath.addLine(to: CGPoint(x: 2, y: 0))
        cgPath.addQuadCurve(to: CGPoint(x: 0, y: 0), control: CGPoint(x: 1, y: 1))
        let path = Path(cgPath: cgPath, detail: 1)
        XCTAssertTrue(path.isClosed)
        XCTAssertEqual(path.points, [
            .point(0, 0),
            .point(2, 0),
            .curve(1, 0.5),
            .point(0, 0),
        ])
    }

    func testClosedLineAndQuadCurveCGPath() {
        let cgPath = CGMutablePath()
        cgPath.move(to: .zero)
        cgPath.addLine(to: CGPoint(x: 2, y: 0))
        cgPath.addQuadCurve(to: CGPoint(x: 0, y: 0), control: CGPoint(x: 1, y: 1))
        cgPath.closeSubpath()
        let path = Path(cgPath: cgPath, detail: 1)
        XCTAssertTrue(path.isClosed)
        XCTAssertEqual(path.points, [
            .point(0, 0),
            .point(2, 0),
            .curve(1, 0.5),
            .point(0, 0),
        ])
    }

    func testUnclosedLineAndCubicCurveCGPath() {
        let cgPath = CGMutablePath()
        cgPath.move(to: .zero)
        cgPath.addLine(to: CGPoint(x: 2, y: 0))
        cgPath.addCurve(to: CGPoint(x: 0, y: 0), control1: CGPoint(x: 1.5, y: 1), control2: CGPoint(x: 0.5, y: 1))
        let path = Path(cgPath: cgPath, detail: 1)
        XCTAssertTrue(path.isClosed)
        XCTAssertEqual(path.points.count, 5)
    }
}

#endif
