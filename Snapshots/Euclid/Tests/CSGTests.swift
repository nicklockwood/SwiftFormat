//
//  CSGTests.swift
//  GeometryScriptTests
//
//  Created by Nick Lockwood on 31/10/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import Euclid

class CSGTests: XCTestCase {
    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS)
        let thisClass = type(of: self)
        let linuxCount = thisClass.__allTests.count
        let darwinCount = thisClass.defaultTestSuite.testCaseCount
        XCTAssertEqual(linuxCount, darwinCount, "run swift test --generate-linuxmain")
        #endif
    }

    // MARK: Subtraction

    func testSubtractCoincidingBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube()
        let c = a.subtract(b)
        XCTAssert(c.polygons.isEmpty)
    }

    func testSubtractAdjacentBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: Vector(1, 0, 0))
        let c = a.subtract(b)
        XCTAssertEqual(c.bounds, a.bounds)
    }

    func testSubtractOverlappingBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: Vector(0.5, 0, 0))
        let c = a.subtract(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Vector(-0.5, -0.5, -0.5),
            max: Vector(0, 0.5, 0.5)
        ))
    }

    // MARK: XOR

    func testXorCoincidingCubes() {
        let a = Mesh.cube()
        let b = Mesh.cube()
        let c = a.xor(b)
        XCTAssert(c.polygons.isEmpty)
    }

    func testXorAdjacentCubes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: Vector(1, 0, 0))
        let c = a.xor(b)
        XCTAssertEqual(c.bounds, a.bounds.union(b.bounds))
    }

    func testXorOverlappingCubes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: Vector(0.5, 0, 0))
        let c = a.xor(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Vector(-0.5, -0.5, -0.5),
            max: Vector(1.0, 0.5, 0.5)
        ))
    }

    // MARK: Union

    func testUnionOfCoincidingBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube()
        let c = a.union(b)
        XCTAssertEqual(c.bounds, a.bounds)
    }

    func testUnionOfAdjacentBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: Vector(1, 0, 0))
        let c = a.union(b)
        XCTAssertEqual(c.bounds, a.bounds.union(b.bounds))
    }

    func testUnionOfOverlappingBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: Vector(0.5, 0, 0))
        let c = a.union(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Vector(-0.5, -0.5, -0.5),
            max: Vector(1, 0.5, 0.5)
        ))
    }

    // MARK: Intersection

    func testIntersectionOfCoincidingBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube()
        let c = a.intersect(b)
        XCTAssertEqual(c.bounds, a.bounds)
    }

    func testIntersectionOfAdjacentBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: Vector(1, 0, 0))
        let c = a.intersect(b)
        // TODO: ideally this should probably be empty, but it's not clear
        // how to achieve that while also getting desired planar behavior
        XCTAssertEqual(c.bounds, Bounds(
            min: Vector(0.5, -0.5, -0.5),
            max: Vector(0.5, 0.5, 0.5)
        ))
    }

    func testIntersectionOfOverlappingBoxes() {
        let a = Mesh.cube()
        let b = Mesh.cube().translated(by: Vector(0.5, 0, 0))
        let c = a.intersect(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Vector(0, -0.5, -0.5),
            max: Vector(0.5, 0.5, 0.5)
        ))
    }

    // MARK: Planar subtraction

    func testSubtractCoincidingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square())
        let c = a.subtract(b)
        XCTAssert(c.polygons.isEmpty)
    }

    func testSubtractAdjacentSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: Vector(1, 0, 0))
        let c = a.subtract(b)
        XCTAssertEqual(c.bounds, a.bounds)
    }

    func testSubtractOverlappingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: Vector(0.5, 0, 0))
        let c = a.subtract(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Vector(-0.5, -0.5, 0),
            max: Vector(0, 0.5, 0)
        ))
    }

    // MARK: Planar XOR

    func testXorCoincidingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square())
        let c = a.xor(b)
        XCTAssert(c.polygons.isEmpty)
    }

    func testXorAdjacentSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: Vector(1, 0, 0))
        let c = a.xor(b)
        XCTAssertEqual(c.bounds, a.bounds.union(b.bounds))
    }

    func testXorOverlappingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: Vector(0.5, 0, 0))
        let c = a.xor(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Vector(-0.5, -0.5, 0),
            max: Vector(1.0, 0.5, 0)
        ))
    }

    // MARK: Planar union

    func testUnionOfCoincidingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square())
        let c = a.union(b)
        XCTAssertEqual(c.bounds, a.bounds)
    }

    func testUnionOfAdjacentSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: Vector(1, 0, 0))
        let c = a.union(b)
        XCTAssertEqual(c.bounds, a.bounds.union(b.bounds))
    }

    func testUnionOfOverlappingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: Vector(0.5, 0, 0))
        let c = a.union(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Vector(-0.5, -0.5, 0),
            max: Vector(1, 0.5, 0)
        ))
    }

    // MARK: Planar intersection

    func testIntersectionOfCoincidingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square())
        let c = a.intersect(b)
        XCTAssertEqual(c.bounds, a.bounds)
    }

    func testIntersectionOfAdjacentSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: Vector(1, 0, 0))
        let c = a.intersect(b)
        XCTAssert(c.polygons.isEmpty)
    }

    func testIntersectionOfOverlappingSquares() {
        let a = Mesh.fill(.square())
        let b = Mesh.fill(.square()).translated(by: Vector(0.5, 0, 0))
        let c = a.intersect(b)
        XCTAssertEqual(c.bounds, Bounds(
            min: Vector(0, -0.5, 0),
            max: Vector(0.5, 0.5, 0)
        ))
    }
}
