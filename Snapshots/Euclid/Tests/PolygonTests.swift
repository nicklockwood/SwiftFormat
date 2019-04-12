//
//  PolygonTests.swift
//  GeometryScriptTests
//
//  Created by Nick Lockwood on 19/09/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import Euclid

class PolygonTests: XCTestCase {
    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS)
        let thisClass = type(of: self)
        let linuxCount = thisClass.__allTests.count
        let darwinCount = thisClass.defaultTestSuite.testCaseCount
        XCTAssertEqual(linuxCount, darwinCount, "run swift test --generate-linuxmain")
        #endif
    }

    // MARK: initialization

    func testConvexPolygonAnticlockwiseWinding() {
        let normal = Vector(0, 0, 1)
        guard let polygon = Polygon([
            Vertex(Vector(-1, 1), normal),
            Vertex(Vector(-1, -1), normal),
            Vertex(Vector(1, -1), normal),
            Vertex(Vector(1, 1), normal),
        ]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(polygon.plane.normal, normal)
    }

    func testConvexPolygonClockwiseWinding() {
        let normal = Vector(0, 0, -1)
        guard let polygon = Polygon([
            Vertex(Vector(-1, -1), normal),
            Vertex(Vector(-1, 1), normal),
            Vertex(Vector(1, 1), normal),
            Vertex(Vector(1, -1), normal),
        ]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(polygon.plane.normal, normal)
    }

    func testConcavePolygonAnticlockwiseWinding() {
        let normal = Vector(0, 0, 1)
        guard let polygon = Polygon([
            Vertex(Vector(-1, 0), normal),
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(0, -1), normal),
            Vertex(Vector(1, -1), normal),
            Vertex(Vector(1, 1), normal),
            Vertex(Vector(-1, 1), normal),
        ]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(polygon.plane.normal, normal)
    }

    func testConcavePolygonClockwiseWinding() {
        let normal = Vector(0, 0, -1)
        guard let polygon = Polygon([
            Vertex(Vector(-1, 0), normal),
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(1, 1), normal),
            Vertex(Vector(1, -1), normal),
            Vertex(Vector(-1, -1), normal),
        ]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(polygon.plane.normal, normal)
    }

    func testDegeneratePolygonWithColinearPoints() {
        let normal = Vector(0, 0, 1)
        XCTAssertNil(Polygon([
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(0, -2), normal),
        ]))
    }

    func testNonDegeneratePolygonWithColinearPoints() {
        let normal = Vector(0, 0, 1)
        XCTAssertNotNil(Polygon([
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(0, -2), normal),
            Vertex(Vector(1.5, -1), normal),
        ]))
    }

    // MARK: merging

    func testMerge1() {
        let normal = Vector(0, 0, 1)
        let a = Polygon(unchecked: [
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(1, 1), normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(Vector(1, 1), normal),
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(1, 0), normal),
        ])
        let c = Polygon(unchecked: [
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(1, 0), normal),
            Vertex(Vector(1, 1), normal),
        ])
        XCTAssertEqual(a.merge(b), c)
    }

    func testMerge2() {
        let normal = Vector(0, 0, 1)
        let a = Polygon(unchecked: [
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(1, 0), normal),
            Vertex(Vector(1, 1), normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(Vector(2, 1), normal),
            Vertex(Vector(1, 1), normal),
            Vertex(Vector(1, 0), normal),
        ])
        let c = Polygon(unchecked: [
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(1, 0), normal),
            Vertex(Vector(2, 1), normal),
        ])
        XCTAssertEqual(a.merge(b), c)
    }

    func testMergeL2RAdjacentRects() {
        let normal = Vector(0, 0, 1)
        let a = Polygon(unchecked: [
            Vertex(Vector(-1, 1), normal),
            Vertex(Vector(-1, -1), normal),
            Vertex(Vector(0, -1), normal),
            Vertex(Vector(0, 1), normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(0, -1), normal),
            Vertex(Vector(1, -1), normal),
            Vertex(Vector(1, 1), normal),
        ])
        guard let c = a.merge(b) else {
            XCTFail()
            return
        }
        XCTAssertEqual(c, Polygon(unchecked: [
            Vertex(Vector(-1, 1), normal),
            Vertex(Vector(-1, -1), normal),
            Vertex(Vector(1, -1), normal),
            Vertex(Vector(1, 1), normal),
        ]))
    }

    func testMergeR2LAdjacentRects() {
        let normal = Vector(0, 0, 1)
        let a = Polygon(unchecked: [
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(0, -1), normal),
            Vertex(Vector(1, -1), normal),
            Vertex(Vector(1, 1), normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(Vector(-1, 1), normal),
            Vertex(Vector(-1, -1), normal),
            Vertex(Vector(0, -1), normal),
            Vertex(Vector(0, 1), normal),
        ])
        guard let c = a.merge(b) else {
            XCTFail()
            return
        }
        XCTAssertEqual(c, Polygon(unchecked: [
            Vertex(Vector(1, -1), normal),
            Vertex(Vector(1, 1), normal),
            Vertex(Vector(-1, 1), normal),
            Vertex(Vector(-1, -1), normal),
        ]))
    }

    func testMergeB2TAdjacentRects() {
        let normal = Vector(0, 0, 1)
        let a = Polygon(unchecked: [
            Vertex(Vector(-1, 0), normal),
            Vertex(Vector(-1, -1), normal),
            Vertex(Vector(1, -1), normal),
            Vertex(Vector(1, 0), normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(Vector(-1, 1), normal),
            Vertex(Vector(-1, 0), normal),
            Vertex(Vector(1, 0), normal),
            Vertex(Vector(1, 1), normal),
        ])
        guard let c = a.merge(b) else {
            XCTFail()
            return
        }
        XCTAssertEqual(c, Polygon(unchecked: [
            Vertex(Vector(-1, -1), normal),
            Vertex(Vector(1, -1), normal),
            Vertex(Vector(1, 1), normal),
            Vertex(Vector(-1, 1), normal),
        ]))
    }

    func testMergeT2BAdjacentRects() {
        let normal = Vector(0, 0, 1)
        let a = Polygon(unchecked: [
            Vertex(Vector(-1, 1), normal),
            Vertex(Vector(-1, 0), normal),
            Vertex(Vector(1, 0), normal),
            Vertex(Vector(1, 1), normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(Vector(-1, 0), normal),
            Vertex(Vector(-1, -1), normal),
            Vertex(Vector(1, -1), normal),
            Vertex(Vector(1, 0), normal),
        ])
        guard let c = a.merge(b) else {
            XCTFail()
            return
        }
        XCTAssertEqual(c, Polygon(unchecked: [
            Vertex(Vector(1, 1), normal),
            Vertex(Vector(-1, 1), normal),
            Vertex(Vector(-1, -1), normal),
            Vertex(Vector(1, -1), normal),
        ]))
    }

    func testMergeL2RAdjacentRectAndTriangle() {
        let normal = Vector(0, 0, 1)
        let a = Polygon(unchecked: [
            Vertex(Vector(-1, 1), normal),
            Vertex(Vector(-1, -1), normal),
            Vertex(Vector(0, -1), normal),
            Vertex(Vector(0, 1), normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(Vector(0, 1), normal),
            Vertex(Vector(0, -1), normal),
            Vertex(Vector(1, 1), normal),
        ])
        guard let c = a.merge(b) else {
            XCTFail()
            return
        }
        XCTAssertEqual(c, Polygon(unchecked: [
            Vertex(Vector(-1, 1), normal),
            Vertex(Vector(-1, -1), normal),
            Vertex(Vector(0, -1), normal),
            Vertex(Vector(1, 1), normal),
        ]))
    }

    func testMergeEdgeCase() {
        let normal = Vector(0, 0, 1)
        let a = Polygon(unchecked: [
            Vertex(Vector(-0.02, 0.8), normal),
            Vertex(Vector(0.7028203230300001, 0.38267949192000006), normal),
            Vertex(Vector(0.7028203230300001, -0.38267949192000006), normal),
        ])
        let b = Polygon(unchecked: [
            Vertex(Vector(0.7028203230300001, -0.38267949192000006), normal),
            Vertex(Vector(-0.02, -0.8), normal),
            Vertex(Vector(-0.6828203230300001, -0.41732050808000004), normal),
            Vertex(Vector(-0.6828203230300001, 0.41732050808000004), normal),
            Vertex(Vector(-0.02, 0.8), normal),
        ])
        let c = Polygon(unchecked: [
            Vertex(Vector(0.7028203230300001, 0.38267949192000006), normal),
            Vertex(Vector(0.7028203230300001, -0.38267949192000006), normal),
            Vertex(Vector(-0.02, -0.8), normal),
            Vertex(Vector(-0.6828203230300001, -0.41732050808000004), normal),
            Vertex(Vector(-0.6828203230300001, 0.41732050808000004), normal),
            Vertex(Vector(-0.02, 0.8), normal),
        ])
        XCTAssertEqual(a.merge(b), c)
    }

    // MARK: containsPoint

    func testConvexAnticlockwisePolygonContainsPoint() {
        let path = Path([
            .point(-1, 1),
            .point(-1, -1),
            .point(1, -1),
            .point(1, 1),
            .point(-1, 1),
        ])
        guard let polygon = Polygon(shape: path) else {
            XCTFail()
            return
        }
        XCTAssertTrue(polygon.containsPoint(Vector(0, 0)))
        XCTAssertTrue(polygon.containsPoint(Vector(-0.999, 0.999)))
        XCTAssertTrue(polygon.containsPoint(Vector(0.999, 0.999)))
        XCTAssertTrue(polygon.containsPoint(Vector(0.999, -0.999)))
        XCTAssertTrue(polygon.containsPoint(Vector(-0.999, -0.999)))
        XCTAssertFalse(polygon.containsPoint(Vector(-1.001, 0)))
        XCTAssertFalse(polygon.containsPoint(Vector(1.001, 0)))
        XCTAssertFalse(polygon.containsPoint(Vector(0, -1.001)))
        XCTAssertFalse(polygon.containsPoint(Vector(0, 1.001)))
    }

    func testConvexClockwisePolygonContainsPoint() {
        let path = Path([
            .point(-1, -1),
            .point(-1, 1),
            .point(1, 1),
            .point(1, -1),
            .point(-1, -1),
        ])
        guard let polygon = Polygon(shape: path) else {
            XCTFail()
            return
        }
        XCTAssertTrue(polygon.containsPoint(Vector(0, 0)))
        XCTAssertTrue(polygon.containsPoint(Vector(-0.999, 0.999)))
        XCTAssertTrue(polygon.containsPoint(Vector(0.999, 0.999)))
        XCTAssertTrue(polygon.containsPoint(Vector(0.999, -0.999)))
        XCTAssertTrue(polygon.containsPoint(Vector(-0.999, -0.999)))
        XCTAssertFalse(polygon.containsPoint(Vector(-1.001, 0)))
        XCTAssertFalse(polygon.containsPoint(Vector(1.001, 0)))
        XCTAssertFalse(polygon.containsPoint(Vector(0, -1.001)))
        XCTAssertFalse(polygon.containsPoint(Vector(0, 1.001)))
    }

    func testConcaveAnticlockwisePolygonContainsPoint() {
        let path = Path([
            .point(-1, 0),
            .point(0, 0),
            .point(0, -1),
            .point(1, -1),
            .point(1, 1),
            .point(-1, 1),
            .point(-1, 0),
        ])
        guard let polygon = Polygon(shape: path) else {
            XCTFail()
            return
        }
        XCTAssertTrue(polygon.containsPoint(Vector(-0.5, 0.5)))
        XCTAssertTrue(polygon.containsPoint(Vector(0.5, 0.5)))
        XCTAssertFalse(polygon.containsPoint(Vector(-0.5, -0.5)))
        XCTAssertTrue(polygon.containsPoint(Vector(0.5, -0.5)))
    }

    func testConcaveAnticlockwisePolygonContainsPoint2() {
        let path = Path([
            .point(0, 1),
            .point(0.5, 0),
            .point(0, -1),
            .point(1, 0),
            .point(0, 1),
        ])
        guard let polygon = Polygon(shape: path) else {
            XCTFail()
            return
        }
        XCTAssertTrue(polygon.containsPoint(Vector(0.75, 0)))
        XCTAssertFalse(polygon.containsPoint(Vector(0.25, 0)))
        XCTAssertFalse(polygon.containsPoint(Vector(0.25, 0.25)))
        XCTAssertFalse(polygon.containsPoint(Vector(0.25, -0.25)))
        XCTAssertTrue(polygon.containsPoint(Vector(0.25, 0.5)))
        XCTAssertTrue(polygon.containsPoint(Vector(0.25, -0.5)))
    }

    // MARK: tessellation

    func testConcaveAnticlockwisePolygonCorrectlyTessellated() {
        let path = Path([
            .point(0, 1),
            .point(0.5, 0),
            .point(0, -1),
            .point(1, 0),
            .point(0, 1),
        ])
        guard let polygon = Polygon(shape: path) else {
            XCTFail()
            return
        }
        let polygons = polygon.tessellate()
        XCTAssertEqual(polygons.count, 2)
        guard polygons.count > 1 else {
            return
        }
        let a = Set(polygons[0].vertices.map { $0.position })
        let expectedA = Set([
            Vector(0, 1),
            Vector(0.5, 0),
            Vector(1, 0),
        ])
        let b = Set(polygons[1].vertices.map { $0.position })
        let expectedB = Set([
            Vector(0.5, 0),
            Vector(1, 0),
            Vector(0, -1),
        ])
        XCTAssert(a == expectedA || a == expectedB)
        XCTAssert(b == expectedA || b == expectedB)
    }

    func testInvertedConcaveAnticlockwisePolygonCorrectlyTessellated() {
        let path = Path([
            .point(0, 1),
            .point(0.5, 0),
            .point(0, -1),
            .point(1, 0),
            .point(0, 1),
        ])
        guard let polygon = Polygon(shape: path)?.inverted() else {
            XCTFail()
            return
        }
        let polygons = polygon.tessellate()
        XCTAssertEqual(polygons.count, 2)
        guard polygons.count > 1 else {
            return
        }
        let a = Set(polygons[0].vertices.map { $0.position })
        let expectedA = Set([
            Vector(0, 1),
            Vector(1, 0),
            Vector(0.5, 0),
        ])
        let b = Set(polygons[1].vertices.map { $0.position })
        let expectedB = Set([
            Vector(0.5, 0),
            Vector(1, 0),
            Vector(0, -1),
        ])
        XCTAssert(a == expectedA || a == expectedB)
        XCTAssert(b == expectedA || b == expectedB)
    }

    // MARK: triangulation

    func testConcaveAnticlockwisePolygonCorrectlyTriangulated() {
        let path = Path([
            .point(0, 1),
            .point(0.5, 0),
            .point(0, -1),
            .point(1, 0),
            .point(0, 1),
        ])
        guard let polygon = Polygon(shape: path) else {
            XCTFail()
            return
        }
        let triangles = polygon.triangulate()
        XCTAssertEqual(triangles.count, 2)
        guard triangles.count > 1 else {
            return
        }
        let a = Set(triangles[0].vertices.map { $0.position })
        let expectedA = Set([
            Vector(0, 1),
            Vector(0.5, 0),
            Vector(1, 0),
        ])
        let b = Set(triangles[1].vertices.map { $0.position })
        let expectedB = Set([
            Vector(0.5, 0),
            Vector(1, 0),
            Vector(0, -1),
        ])
        XCTAssert(a == expectedA || a == expectedB)
        XCTAssert(b == expectedA || b == expectedB)
    }

    func testInvertedConcaveAnticlockwisePolygonCorrectlyTriangulated() {
        let path = Path([
            .point(0, 1),
            .point(0.5, 0),
            .point(0, -1),
            .point(1, 0),
            .point(0, 1),
        ])
        guard let polygon = Polygon(shape: path)?.inverted() else {
            XCTFail()
            return
        }
        let triangles = polygon.triangulate()
        XCTAssertEqual(triangles.count, 2)
        guard triangles.count > 1 else {
            return
        }
        let a = Set(triangles[0].vertices.map { $0.position })
        let expectedA = Set([
            Vector(0, 1),
            Vector(1, 0),
            Vector(0.5, 0),
        ])
        let b = Set(triangles[1].vertices.map { $0.position })
        let expectedB = Set([
            Vector(0.5, 0),
            Vector(1, 0),
            Vector(0, -1),
        ])
        XCTAssert(a == expectedA || a == expectedB)
        XCTAssert(b == expectedA || b == expectedB)
    }

    func testPolygonWithColinearPointsCorrectlyTriangulated() {
        let normal = Vector(0, 0, -1)
        guard let polygon = Polygon([
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(0.5, 0), normal),
            Vertex(Vector(0.5, 1), normal),
            Vertex(Vector(-0.5, 1), normal),
            Vertex(Vector(-0.5, 0), normal),
        ]) else {
            XCTFail()
            return
        }
        let triangles = polygon.triangulate()
        guard triangles.count == 3 else {
            XCTFail()
            return
        }
        XCTAssertEqual(triangles[0], Polygon([
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(0.5, 0), normal),
            Vertex(Vector(0.5, 1), normal),
        ]))
        XCTAssertEqual(triangles[1], Polygon([
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(0.5, 1), normal),
            Vertex(Vector(-0.5, 1), normal),
        ]))
        XCTAssertEqual(triangles[2], Polygon([
            Vertex(Vector(0, 0), normal),
            Vertex(Vector(-0.5, 1), normal),
            Vertex(Vector(-0.5, 0), normal),
        ]))
    }

    func testHouseShapedPolygonCorrectlyTriangulated() {
        let normal = Vector(0, 0, -1)
        guard let polygon = Polygon([
            Vertex(Vector(0, 0.5), normal),
            Vertex(Vector(1, 0), normal),
            Vertex(Vector(0.5, -epsilon), normal),
            Vertex(Vector(0.5, -1), normal),
            Vertex(Vector(-0.5, -1), normal),
            Vertex(Vector(-0.5, -epsilon), normal),
            Vertex(Vector(-1, 0), normal),
        ]) else {
            XCTFail()
            return
        }
        let triangles = polygon.triangulate()
        guard triangles.count == 3 else {
            XCTFail()
            return
        }
        XCTAssertEqual(triangles[0], Polygon([
            Vertex(Vector(-1, 0), normal),
            Vertex(Vector(0, 0.5), normal),
            Vertex(Vector(1, 0), normal),
        ]))
        XCTAssertEqual(triangles[1], Polygon([
            Vertex(Vector(0.5, -epsilon), normal),
            Vertex(Vector(0.5, -1), normal),
            Vertex(Vector(-0.5, -1), normal),
        ]))
        XCTAssertEqual(triangles[2], Polygon([
            Vertex(Vector(0.5, -epsilon), normal),
            Vertex(Vector(-0.5, -1), normal),
            Vertex(Vector(-0.5, -epsilon), normal),
        ]))
    }

    func testPathWithZeroAreaColinearPointTriangulated() {
        let path = Path([
            .point(0.18, 0.245),
            .point(0.18, 0.255),
            .point(0.17, 0.255),
            .point(0.16, 0.247),
            .point(0.16, 0.244),
            .point(0.16, 0.245),
            .point(0.18, 0.245),
        ])
        guard let polygon = Polygon(shape: path) else {
            XCTFail()
            return
        }
        let triangles = polygon.triangulate()
        XCTAssertEqual(triangles.count, 3)
    }
}
