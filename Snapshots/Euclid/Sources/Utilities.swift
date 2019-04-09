//
//  Utilities.swift
//  Euclid
//
//  Created by Nick Lockwood on 03/07/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/Euclid
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

// Tolerance used for calculating approximate equality
let epsilon = 1e-6

// Round-off floating point values to simplify equality checks
func quantize(_ value: Double) -> Double {
    let precision = 1e-8 * 1e-3
    return (value / precision).rounded() * precision
}

// MARK: Vertex utilities

func verticesAreDegenerate(_ vertices: [Vertex]) -> Bool {
    guard vertices.count > 1 else {
        return false
    }
    return pointsAreDegenerate(vertices.map { $0.position })
}

func verticesAreConvex(_ vertices: [Vertex]) -> Bool {
    guard vertices.count > 3 else {
        return vertices.count > 2
    }
    return pointsAreConvex(vertices.map { $0.position })
}

func faceNormalForConvexVertices(_ vertices: [Vertex]) -> Vector? {
    assert(verticesAreConvex(vertices))
    return faceNormalForConvexPoints(vertices.map { $0.position })
}

func faceNormalForConvexVertices(unchecked vertices: [Vertex]) -> Vector {
    let ab = vertices[1].position - vertices[0].position
    let bc = vertices[2].position - vertices[1].position
    let normal = ab.cross(bc)
    assert(normal.length > epsilon)
    return normal.normalized()
}

// MARK: Vector utilities

func pointsAreDegenerate(_ points: [Vector]) -> Bool {
    let threshold = 1e-10
    let count = points.count
    guard count > 1, let a = points.last else {
        return false
    }
    var ab = points[0] - a
    var length = ab.length
    guard length > threshold else {
        return true
    }
    ab = ab / length
    for i in 0 ..< count {
        let b = points[i]
        let c = points[(i + 1) % count]
        var bc = c - b
        length = bc.length
        guard length > threshold else {
            return true
        }
        bc = bc / length
        guard abs(ab.dot(bc) + 1) > threshold else {
            return true
        }
        ab = bc
    }
    return false
}

func pointsAreConvex(_ points: [Vector]) -> Bool {
    assert(!pointsAreDegenerate(points))
    let count = points.count
    guard count > 3, let a = points.last else {
        return count > 2
    }
    var normal: Vector?
    var ab = points[0] - a
    for i in 0 ..< count {
        let b = points[i]
        let c = points[(i + 1) % count]
        let bc = c - b
        var n = ab.cross(bc)
        let length = n.length
        // check result is large enough to be reliable
        if length > epsilon {
            n = n / length
            if let normal = normal {
                if n.dot(normal) < 0 {
                    return false
                }
            } else {
                normal = n
            }
        }
        ab = bc
    }
    return true
}

func faceNormalForConvexPoints(_ points: [Vector]) -> Vector {
    let count = points.count
    let unitZ = Vector(0, 0, 1)
    switch count {
    case 0, 1:
        return unitZ
    case 2:
        let ab = points[1] - points[0]
        return ab.cross(unitZ).cross(ab)
    default:
        var b = points[0]
        var ab = b - points.last!
        var bestLengthSquared = 0.0
        var best: Vector?
        for c in points {
            let bc = c - b
            let normal = ab.cross(bc)
            let lengthSquared = normal.lengthSquared
            if lengthSquared > bestLengthSquared {
                bestLengthSquared = lengthSquared
                best = normal / lengthSquared.squareRoot()
            }
            b = c
            ab = bc
        }
        return best ?? Vector(0, 0, 1)
    }
}

// https://stackoverflow.com/questions/1165647/how-to-determine-if-a-list-of-polygon-points-are-in-clockwise-order#1165943
func flattenedPointsAreClockwise(_ points: [Vector]) -> Bool {
    assert(!points.contains(where: { $0.z != 0 }))
    let points = (points.first == points.last) ? points.dropLast() : [Vector].SubSequence(points)
    guard points.count > 2, var a = points.last else {
        return false
    }
    var sum = 0.0
    for b in points {
        sum += (b.x - a.x) * (b.y + a.y)
        a = b
    }
    // abs(sum / 2) is the area of the polygon
    return sum > 0
}

// MARK: Curve utilities

func quadraticBezier(_ p0: Double, _ p1: Double, _ p2: Double, _ t: Double) -> Double {
    let oneMinusT = 1 - t
    let c0 = oneMinusT * oneMinusT * p0
    let c1 = 2 * oneMinusT * t * p1
    let c2 = t * t * p2
    return c0 + c1 + c2
}

func cubicBezier(_ p0: Double, _ p1: Double, _ p2: Double, _ p3: Double, _ t: Double) -> Double {
    let oneMinusT = 1 - t
    let oneMinusTSquared = oneMinusT * oneMinusT
    let c0 = oneMinusTSquared * oneMinusT * p0
    let c1 = 3 * oneMinusTSquared * t * p1
    let c2 = 3 * oneMinusT * t * t * p2
    let c3 = t * t * t * p3
    return c0 + c1 + c2 + c3
}
