//
//  PathTests.swift
//  GeometryScriptTests
//
//  Created by Nick Lockwood on 19/09/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import Euclid

class PathTests: XCTestCase {
    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS)
        let thisClass = type(of: self)
        let linuxCount = thisClass.__allTests.count
        let darwinCount = thisClass.defaultTestSuite.testCaseCount
        XCTAssertEqual(linuxCount, darwinCount, "run swift test --generate-linuxmain")
        #endif
    }

    // MARK: isSimple

    func testSimpleLine() {
        let path = Path([
            .point(0, 1),
            .point(0, -1),
        ])
        XCTAssertTrue(path.isSimple)
        XCTAssertFalse(path.isClosed)
    }

    func testSimpleOpenTriangle() {
        let path = Path([
            .point(0, 1),
            .point(0, -1),
            .point(1, -1),
        ])
        XCTAssertTrue(path.isSimple)
        XCTAssertFalse(path.isClosed)
    }

    func testSimpleClosedTriangle() {
        let path = Path([
            .point(0, 1),
            .point(-1, -1),
            .point(1, -1),
            .point(0, 1),
        ])
        XCTAssertTrue(path.isSimple)
        XCTAssertTrue(path.isClosed)
    }

    func testSimpleOpenQuad() {
        let path = Path([
            .point(-1, 1),
            .point(-1, -1),
            .point(1, -1),
            .point(1, 1),
        ])
        XCTAssertTrue(path.isSimple)
        XCTAssertFalse(path.isClosed)
    }

    func testOverlappingOpenQuad() {
        let path = Path([
            .point(-1, 1),
            .point(1, -1),
            .point(-1, -1),
            .point(1, 1),
        ])
        XCTAssertFalse(path.isSimple)
        XCTAssertFalse(path.isClosed)
    }

    func testSimpleClosedQuad() {
        let path = Path([
            .point(-1, 1),
            .point(-1, -1),
            .point(1, -1),
            .point(1, 1),
            .point(-1, 1),
        ])
        XCTAssertTrue(path.isSimple)
        XCTAssertTrue(path.isClosed)
    }

    func testOverlappingClosedQuad() {
        let path = Path([
            .point(-1, 1),
            .point(1, -1),
            .point(-1, -1),
            .point(1, 1),
            .point(-1, 1),
        ])
        XCTAssertFalse(path.isSimple)
        XCTAssertTrue(path.isClosed)
    }

    // MARK: winding direction

    func testConvexClosedPathAnticlockwiseWinding() {
        let path = Path([
            .point(-1, 1),
            .point(-1, -1),
            .point(1, -1),
            .point(1, 1),
            .point(-1, 1),
        ])
        XCTAssertTrue(path.isClosed)
        XCTAssertEqual(path.plane?.normal, Vector(0, 0, 1))
    }

    func testConvexClosedPathClockwiseWinding() {
        let path = Path([
            .point(-1, -1),
            .point(-1, 1),
            .point(1, 1),
            .point(1, -1),
            .point(-1, -1),
        ])
        XCTAssertTrue(path.isClosed)
        XCTAssertEqual(path.plane?.normal, Vector(0, 0, -1))
    }

    func testConvexOpenPathAnticlockwiseWinding() {
        let path = Path([
            .point(-1, 1),
            .point(-1, -1),
            .point(1, -1),
        ])
        XCTAssertFalse(path.isClosed)
        XCTAssertEqual(path.plane?.normal, Vector(0, 0, 1))
    }

    func testConvexOpenPathClockwiseWinding() {
        let path = Path([
            .point(-1, -1),
            .point(-1, 1),
            .point(1, 1),
        ])
        XCTAssertFalse(path.isClosed)
        XCTAssertEqual(path.plane?.normal, Vector(0, 0, -1))
    }

    func testConcaveClosedPathAnticlockwiseWinding() {
        let path = Path([
            .point(-1, 0),
            .point(0, 0),
            .point(0, -1),
            .point(1, -1),
            .point(1, 1),
            .point(-1, 1),
            .point(-1, 0),
        ])
        XCTAssertTrue(path.isClosed)
        XCTAssertEqual(path.plane?.normal, Vector(0, 0, 1))
    }

    func testConcaveClosedPathClockwiseWinding() {
        let path = Path([
            .point(-1, 0),
            .point(0, 0),
            .point(0, 1),
            .point(1, 1),
            .point(1, -1),
            .point(-1, -1),
            .point(-1, 0),
        ])
        XCTAssertTrue(path.isClosed)
        XCTAssertEqual(path.plane?.normal, Vector(0, 0, -1))
    }

    func testConcaveClosedPathClockwiseWinding2() {
        var transform = Transform.identity
        var points = [PathPoint]()
        let sides = 5
        for _ in 0 ..< sides {
            points.append(PathPoint.point(0, -0.5).transformed(by: transform))
            transform.rotate(by: .roll(.pi / Double(sides)))
            points.append(PathPoint.point(0, -1).transformed(by: transform))
            transform.rotate(by: .roll(.pi / Double(sides)))
        }
        points.append(.point(0, -0.5))
        let path = Path(points)
        XCTAssertEqual(path.plane?.normal, Vector(0, 0, -1))
    }

    func testConcaveOpenPathAnticlockwiseWinding() {
        let path = Path([
            .point(-1, 0),
            .point(0, 0),
            .point(0, -1),
            .point(1, -1),
            .point(-1, 1),
        ])
        XCTAssertFalse(path.isClosed)
        XCTAssertEqual(path.plane?.normal, Vector(0, 0, 1))
    }

    func testConcaveOpenPathClockwiseWinding() {
        let path = Path([
            .point(-1, 0),
            .point(0, 0),
            .point(0, 1),
            .point(1, 1),
            .point(-1, -1),
        ])
        XCTAssertFalse(path.isClosed)
        XCTAssertEqual(path.plane?.normal, Vector(0, 0, -1))
    }

    func testStraightLinePathAnticlockwiseWinding() {
        let path = Path([
            .point(-1, 1),
            .point(-1, -1),
        ])
        XCTAssertFalse(path.isClosed)
        XCTAssertEqual(path.plane?.normal, Vector(0, 0, 1))
    }

    func testStraightLinePathAnticlockwiseWinding2() {
        let path = Path([
            .point(-1, -1),
            .point(-1, 1),
        ])
        XCTAssertFalse(path.isClosed)
        XCTAssertEqual(path.plane?.normal, Vector(0, 0, 1))
    }

    func testStraightLinePathAnticlockwiseWinding3() {
        let path = Path([
            .point(1, 1),
            .point(1, -1),
        ])
        XCTAssertFalse(path.isClosed)
        XCTAssertEqual(path.plane?.normal, Vector(0, 0, 1))
    }

    // MARK: faceVertices

    func testFaceVerticesForConcaveClockwisePath() {
        let path = Path([
            .point(0, 1),
            .point(1, 0),
            .point(0, -1),
            .point(0.5, 0),
            .point(0, 1),
        ])
        guard let vertices = path.faceVertices else {
            XCTFail()
            return
        }
        XCTAssertEqual(vertices.count, 4)
    }

    func testFaceVerticesForDegenerateClosedAnticlockwisePath() {
        let path = Path([
            .point(0, 1),
            .point(0, 0),
            .point(0, -1),
            .point(0, 1),
        ])
        XCTAssert(path.isClosed)
        XCTAssertNil(path.faceVertices)
    }

    // MARK: edgeVertices

    func testEdgeVerticesForSmoothedClosedRect() {
        let path = Path([
            .curve(-1, 1),
            .curve(-1, -1),
            .curve(1, -1),
            .curve(1, 1),
            .curve(-1, 1),
        ])
        let vertices = path.edgeVertices
        XCTAssertEqual(vertices.count, 8)
        guard vertices.count >= 8 else { return }
        // positions
        XCTAssertEqual(vertices[0].position, Vector(-1, 1))
        XCTAssertEqual(vertices[1].position, Vector(-1, -1))
        XCTAssertEqual(vertices[2].position, Vector(-1, -1))
        XCTAssertEqual(vertices[3].position, Vector(1, -1))
        XCTAssertEqual(vertices[4].position, Vector(1, -1))
        XCTAssertEqual(vertices[5].position, Vector(1, 1))
        XCTAssertEqual(vertices[6].position, Vector(1, 1))
        XCTAssertEqual(vertices[7].position, Vector(-1, 1))
        // texture coords
        XCTAssertEqual(vertices[0].texcoord, Vector(0, 0))
        XCTAssertEqual(vertices[1].texcoord, Vector(0, 0.25))
        XCTAssertEqual(vertices[2].texcoord, Vector(0, 0.25))
        XCTAssertEqual(vertices[3].texcoord, Vector(0, 0.5))
        XCTAssertEqual(vertices[4].texcoord, Vector(0, 0.5))
        XCTAssertEqual(vertices[5].texcoord, Vector(0, 0.75))
        XCTAssertEqual(vertices[6].texcoord, Vector(0, 0.75))
        XCTAssertEqual(vertices[7].texcoord, Vector(0, 1))
        // normals
        XCTAssertEqual(vertices[0].normal.quantized(), Vector(-1, 1).normalized().quantized())
        XCTAssertEqual(vertices[1].normal.quantized(), Vector(-1, -1).normalized().quantized())
        XCTAssertEqual(vertices[2].normal.quantized(), Vector(-1, -1).normalized().quantized())
        XCTAssertEqual(vertices[3].normal.quantized(), Vector(1, -1).normalized().quantized())
        XCTAssertEqual(vertices[4].normal.quantized(), Vector(1, -1).normalized().quantized())
        XCTAssertEqual(vertices[5].normal.quantized(), Vector(1, 1).normalized().quantized())
        XCTAssertEqual(vertices[6].normal.quantized(), Vector(1, 1).normalized().quantized())
        XCTAssertEqual(vertices[7].normal.quantized(), Vector(-1, 1).normalized().quantized())
    }

    func testEdgeVerticesForSmoothedCylinder() {
        let path = Path([
            .point(0, 1),
            .curve(-1, 1),
            .curve(-1, -1),
            .point(0, -1),
        ])
        let vertices = path.edgeVertices
        XCTAssertEqual(vertices.count, 6)
        guard vertices.count >= 6 else { return }
        // positions
        XCTAssertEqual(vertices[0].position, Vector(0, 1))
        XCTAssertEqual(vertices[1].position, Vector(-1, 1))
        XCTAssertEqual(vertices[2].position, Vector(-1, 1))
        XCTAssertEqual(vertices[3].position, Vector(-1, -1))
        XCTAssertEqual(vertices[4].position, Vector(-1, -1))
        XCTAssertEqual(vertices[5].position, Vector(0, -1))
        // texture coords
        XCTAssertEqual(vertices[0].texcoord, Vector(0, 0))
        XCTAssertEqual(vertices[1].texcoord, Vector(0, 0.25))
        XCTAssertEqual(vertices[2].texcoord, Vector(0, 0.25))
        XCTAssertEqual(vertices[3].texcoord, Vector(0, 0.75))
        XCTAssertEqual(vertices[4].texcoord, Vector(0, 0.75))
        XCTAssertEqual(vertices[5].texcoord, Vector(0, 1))
        // normals
        XCTAssertEqual(vertices[0].normal, Vector(0, 1))
        XCTAssertEqual(vertices[1].normal.quantized(), Vector(-1, 1).normalized().quantized())
        XCTAssertEqual(vertices[2].normal.quantized(), Vector(-1, 1).normalized().quantized())
        XCTAssertEqual(vertices[3].normal.quantized(), Vector(-1, -1).normalized().quantized())
        XCTAssertEqual(vertices[4].normal.quantized(), Vector(-1, -1).normalized().quantized())
        XCTAssertEqual(vertices[5].normal, Vector(0, -1))
    }

    func testEdgeVerticesForSharpEdgedCylinder() {
        let path = Path([
            .point(0, 1),
            .point(-1, 1),
            .point(-1, -1),
            .point(0, -1),
        ])
        let vertices = path.edgeVertices
        XCTAssertEqual(vertices.count, 6)
        guard vertices.count >= 6 else { return }
        // positions
        XCTAssertEqual(vertices[0].position, Vector(0, 1))
        XCTAssertEqual(vertices[1].position, Vector(-1, 1))
        XCTAssertEqual(vertices[2].position, Vector(-1, 1))
        XCTAssertEqual(vertices[3].position, Vector(-1, -1))
        XCTAssertEqual(vertices[4].position, Vector(-1, -1))
        XCTAssertEqual(vertices[5].position, Vector(0, -1))
        // texture coords
        XCTAssertEqual(vertices[0].texcoord, Vector(0, 0))
        XCTAssertEqual(vertices[1].texcoord, Vector(0, 0.25))
        XCTAssertEqual(vertices[2].texcoord, Vector(0, 0.25))
        XCTAssertEqual(vertices[3].texcoord, Vector(0, 0.75))
        XCTAssertEqual(vertices[4].texcoord, Vector(0, 0.75))
        XCTAssertEqual(vertices[5].texcoord, Vector(0, 1))
        // normals
        XCTAssertEqual(vertices[0].normal, Vector(0, 1))
        XCTAssertEqual(vertices[1].normal, Vector(0, 1))
        XCTAssertEqual(vertices[2].normal, Vector(-1, 0))
        XCTAssertEqual(vertices[3].normal, Vector(-1, 0))
        XCTAssertEqual(vertices[4].normal, Vector(0, -1))
        XCTAssertEqual(vertices[5].normal, Vector(0, -1))
    }

    func testEdgeVerticesForCircle() {
        let path = Path.circle(radius: 1, segments: 4)
        let vertices = path.edgeVertices
        XCTAssertEqual(vertices.count, 8)
        guard vertices.count >= 8 else { return }
        // positions
        XCTAssertEqual(vertices[0].position, Vector(0, 1))
        XCTAssertEqual(vertices[1].position, Vector(-1, 0))
        XCTAssertEqual(vertices[2].position, Vector(-1, 0))
        XCTAssertEqual(vertices[3].position, Vector(0, -1))
        XCTAssertEqual(vertices[4].position, Vector(0, -1))
        XCTAssertEqual(vertices[5].position, Vector(1, 0))
        XCTAssertEqual(vertices[6].position, Vector(1, 0))
        XCTAssertEqual(vertices[7].position, Vector(0, 1))
        // texture coords
        XCTAssertEqual(vertices[0].texcoord, Vector(0, 0))
        XCTAssertEqual(vertices[1].texcoord, Vector(0, 0.25))
        XCTAssertEqual(vertices[2].texcoord, Vector(0, 0.25))
        XCTAssertEqual(vertices[3].texcoord, Vector(0, 0.5))
        XCTAssertEqual(vertices[4].texcoord, Vector(0, 0.5))
        XCTAssertEqual(vertices[5].texcoord, Vector(0, 0.75))
        XCTAssertEqual(vertices[6].texcoord, Vector(0, 0.75))
        XCTAssertEqual(vertices[7].texcoord, Vector(0, 1))
        // normals
        XCTAssertEqual(vertices[0].normal, Vector(0, 1))
        XCTAssertEqual(vertices[1].normal, Vector(-1, 0))
        XCTAssertEqual(vertices[2].normal, Vector(-1, 0))
        XCTAssertEqual(vertices[3].normal, Vector(0, -1))
        XCTAssertEqual(vertices[4].normal, Vector(0, -1))
        XCTAssertEqual(vertices[5].normal, Vector(1, 0))
        XCTAssertEqual(vertices[6].normal, Vector(1, 0))
        XCTAssertEqual(vertices[7].normal, Vector(0, 1))
    }

    func testEdgeVerticesForEllipse() {
        let path = Path.ellipse(width: 4, height: 2, segments: 4)
        let vertices = path.edgeVertices
        XCTAssertEqual(vertices.count, 8)
        guard vertices.count >= 8 else { return }
        // positions
        XCTAssertEqual(vertices[0].position, Vector(0, 1))
        XCTAssertEqual(vertices[1].position, Vector(-2, 0))
        XCTAssertEqual(vertices[2].position, Vector(-2, 0))
        XCTAssertEqual(vertices[3].position, Vector(0, -1))
        XCTAssertEqual(vertices[4].position, Vector(0, -1))
        XCTAssertEqual(vertices[5].position, Vector(2, 0))
        XCTAssertEqual(vertices[6].position, Vector(2, 0))
        XCTAssertEqual(vertices[7].position, Vector(0, 1))
        // texture coords
        XCTAssertEqual(vertices[0].texcoord, Vector(0, 0))
        XCTAssertEqual(vertices[1].texcoord, Vector(0, 0.25))
        XCTAssertEqual(vertices[2].texcoord, Vector(0, 0.25))
        XCTAssertEqual(vertices[3].texcoord, Vector(0, 0.5))
        XCTAssertEqual(vertices[4].texcoord, Vector(0, 0.5))
        XCTAssertEqual(vertices[5].texcoord, Vector(0, 0.75))
        XCTAssertEqual(vertices[6].texcoord, Vector(0, 0.75))
        XCTAssertEqual(vertices[7].texcoord, Vector(0, 1))
        // normals
        XCTAssertEqual(vertices[0].normal, Vector(0, 1))
        XCTAssertEqual(vertices[1].normal, Vector(-1, 0))
        XCTAssertEqual(vertices[2].normal, Vector(-1, 0))
        XCTAssertEqual(vertices[3].normal, Vector(0, -1))
        XCTAssertEqual(vertices[4].normal, Vector(0, -1))
        XCTAssertEqual(vertices[5].normal, Vector(1, 0))
        XCTAssertEqual(vertices[6].normal, Vector(1, 0))
        XCTAssertEqual(vertices[7].normal, Vector(0, 1))
    }

    func testEdgeVerticesForSemicircle() {
        let path = Path([
            .curve(0, 1),
            .curve(-1, 0),
            .curve(0, -1),
        ])
        let vertices = path.edgeVertices
        XCTAssertEqual(vertices.count, 4)
        guard vertices.count >= 4 else { return }
        // positions
        XCTAssertEqual(vertices[0].position, Vector(0, 1))
        XCTAssertEqual(vertices[1].position, Vector(-1, 0))
        XCTAssertEqual(vertices[2].position, Vector(-1, 0))
        XCTAssertEqual(vertices[3].position, Vector(0, -1))
        // texture coords
        XCTAssertEqual(vertices[0].texcoord, Vector(0, 0))
        XCTAssertEqual(vertices[1].texcoord, Vector(0, 0.5))
        XCTAssertEqual(vertices[2].texcoord, Vector(0, 0.5))
        XCTAssertEqual(vertices[3].texcoord, Vector(0, 1))
        // normals
        XCTAssertEqual(vertices[0].normal, Vector(0, 1))
        XCTAssertEqual(vertices[1].normal, Vector(-1, 0))
        XCTAssertEqual(vertices[2].normal, Vector(-1, 0))
        XCTAssertEqual(vertices[3].normal, Vector(0, -1))
    }

    func testEdgeVerticesForVerticalPath() {
        let path = Path([
            .point(-1, 1),
            .point(-1, -1),
        ])
        let vertices = path.edgeVertices
        XCTAssertEqual(vertices.count, 2)
        guard vertices.count >= 2 else { return }
        // positions
        XCTAssertEqual(vertices[0].position, Vector(-1, 1))
        XCTAssertEqual(vertices[1].position, Vector(-1, -1))
        // texture coords
        XCTAssertEqual(vertices[0].texcoord, Vector(0, 0))
        XCTAssertEqual(vertices[1].texcoord, Vector(0, 1))
        // normals
        XCTAssertEqual(vertices[0].normal, Vector(-1, 0))
        XCTAssertEqual(vertices[1].normal, Vector(-1, 0))
    }

    // MARK: Y-axis clipping

    func testClipClosedClockwiseTriangleToRightOfAxis() {
        let path = Path([
            .point(0, 0),
            .point(1, 1),
            .point(1, 0),
            .point(0, 0),
        ])
        let result = path.clippedToYAxis()
        XCTAssertEqual(result.points, [
            .point(0, 0),
            .point(-1, 1),
            .point(-1, 0),
            .point(0, 0),
        ])
    }

    func testClipClosedClockwiseTriangleMostlyRightOfAxis() {
        let path = Path([
            .point(-1, 0),
            .point(1, 1),
            .point(1, 0),
            .point(-1, 0),
        ])
        let result = path.clippedToYAxis()
        XCTAssertEqual(result.points, [
            .point(0, 0.5),
            .point(-1, 1),
            .point(-1, 0),
            .point(0, 0),
        ])
    }

    func testClipClosedRectangleSpanningAxis() {
        let path = Path([
            .point(-1, 1),
            .point(1, 1),
            .point(1, -1),
            .point(-1, -1),
            .point(-1, 1),
        ])
        let result = path.clippedToYAxis()
        XCTAssertEqual(result.points, [
            .point(-1, 1),
            .point(0, 1),
            .point(0, -1),
            .point(-1, -1),
            .point(-1, 1),
        ])
    }

    func testClosedAnticlockwiseTriangleLeftOfAxis() {
        let path = Path([
            .point(0, 1),
            .point(-1, -1),
            .point(0, -1),
        ])
        let result = path.clippedToYAxis()
        XCTAssertEqual(result.points, [
            .point(0, 1),
            .point(-1, -1),
            .point(0, -1),
        ])
    }

    // MARK: subpaths

    func testSimpleOpenPathHasNoSubpaths() {
        let path = Path([
            .point(0, 1),
            .point(-1, -1),
            .point(0, -1),
        ])
        XCTAssertEqual(path.subpaths, [path])
    }

    func testSimpleClosedPathHasNoSubpaths() {
        let path = Path.square()
        XCTAssertEqual(path.subpaths, [path])
    }

    func testPathWithLineEndingInLoopHasCorrectSubpaths() {
        let path = Path([
            .point(0, 0),
            .point(1, 0),
            .point(2, 0),
            .point(2, 1),
            .point(1, 1),
            .point(1, 0),
        ])
        XCTAssertEqual(path.subpaths, [
            Path([
                .point(0, 0),
                .point(1, 0),
            ]),
            Path([
                .point(1, 0),
                .point(2, 0),
                .point(2, 1),
                .point(1, 1),
                .point(1, 0),
            ]),
        ])
    }

    func testPathWithLoopEndingInLineHasCorrectSubpaths() {
        let path = Path([
            .point(0, 0),
            .point(1, 0),
            .point(1, 1),
            .point(0, 1),
            .point(0, 0),
            .point(-1, 0),
        ])
        XCTAssertEqual(path.subpaths, [
            Path([
                .point(0, 0),
                .point(1, 0),
                .point(1, 1),
                .point(0, 1),
                .point(0, 0),
            ]),
            Path([
                .point(0, 0),
                .point(-1, 0),
            ]),
        ])
    }

    func testPathWithConjoinedLoopsHasCorrectSubpaths() {
        let path = Path([
            .point(0, 0),
            .point(1, 1),
            .point(2, 0),
            .point(1, -1),
            .point(0, 0),
            .point(-1, 1),
            .point(-2, 0),
            .point(-1, -1),
            .point(0, 0),
        ])
        XCTAssertEqual(path.subpaths, [
            Path([
                .point(0, 0),
                .point(1, 1),
                .point(2, 0),
                .point(1, -1),
                .point(0, 0),
            ]),
            Path([
                .point(0, 0),
                .point(-1, 1),
                .point(-2, 0),
                .point(-1, -1),
                .point(0, 0),
            ]),
        ])
    }

    func testPathWithTwoSeparateLoopsHasCorrectSubpaths() {
        let path = Path([
            .point(0, 0),
            .point(1, 0),
            .point(1, 1),
            .point(0, 1),
            .point(0, 0),
            .point(2, 0),
            .point(3, 0),
            .point(3, 1),
            .point(2, 1),
            .point(2, 0),
        ])
        XCTAssertEqual(path.subpaths, [
            Path([
                .point(0, 0),
                .point(1, 0),
                .point(1, 1),
                .point(0, 1),
                .point(0, 0),
            ]),
            Path([
                .point(2, 0),
                .point(3, 0),
                .point(3, 1),
                .point(2, 1),
                .point(2, 0),
            ]),
        ])
    }
}
