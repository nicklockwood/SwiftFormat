//
//  Polygon.swift
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

/// A planar polygon
public struct Polygon: Hashable {
    public let vertices: [Vertex]
    public let plane: Plane
    public let bounds: Bounds
    public let isConvex: Bool
    public var material: Material

    // Used to track split/join
    var id = 0
}

public extension Polygon {
    /// Material used by a given polygon
    typealias Material = AnyHashable?

    /// Create a polygon from a set of vertices
    /// Polygon can be convex or concave, but vertices must be coplanar and non-degenerate
    /// Vertices are assumed to be in anticlockwise order for the purpose of deriving the plane
    init?(_ vertices: [Vertex], material: Material = nil) {
        guard vertices.count > 2, !verticesAreDegenerate(vertices),
              let plane = Plane(points: vertices.map { $0.position })
        else {
            return nil
        }
        self.init(unchecked: vertices, plane: plane, material: material)
    }

    /// Test if point lies inside the polygon
    // https://stackoverflow.com/questions/217578/how-can-i-determine-whether-a-2d-point-is-within-a-polygon#218081
    func containsPoint(_ p: Vector) -> Bool {
        guard plane.containsPoint(p), bounds.containsPoint(p) else {
            return false
        }
        let flatteningPlane = FlatteningPlane(normal: plane.normal)
        let points = vertices.map { flatteningPlane.flattenPoint($0.position) }
        let p = flatteningPlane.flattenPoint(p)
        let count = points.count
        var c = false
        var j = count - 1
        for i in 0 ..< count {
            if (points[i].y > p.y) != (points[j].y > p.y),
               p.x < (points[j].x - points[i].x) * (p.y - points[i].y) /
               (points[j].y - points[i].y) + points[i].x
            {
                c = !c
            }
            j = i
        }
        return c
    }

    /// Merge with another polygon, removing redundant vertices if possible
    func merge(_ other: Polygon) -> Polygon? {
        // were they split from the same polygon
        if id == 0 {
            // do they have the same material?
            guard material == other.material else {
                return nil
            }
            // are they coplanar?
            guard plane.isEqual(to: other.plane) else {
                return nil
            }
        } else if id != other.id {
            return nil
        }
        return join(unchecked: other)
    }

    func inverted() -> Polygon {
        return Polygon(
            unchecked: vertices.reversed().map { $0.inverted() },
            plane: plane.inverted(),
            isConvex: isConvex,
            bounds: bounds,
            material: material
        )
    }

    /// Converts a concave polygon into 2 or more convex polygons using the "ear clipping" method
    func tessellate() -> [Polygon] {
        if isConvex {
            return [self]
        }
        var polygons = triangulate()
        var i = polygons.count - 1
        while i > 0 {
            let a = polygons[i]
            let b = polygons[i - 1]
            if let merged = a.join(unchecked: b), merged.isConvex {
                polygons[i - 1] = merged
                polygons.remove(at: i)
            }
            i -= 1
        }
        return polygons
    }

    /// Tesselates polygon into triangles using the "ear clipping" method
    func triangulate() -> [Polygon] {
        var vertices = self.vertices
        guard vertices.count > 3 else {
            assert(vertices.count > 2)
            return [self]
        }
        var triangles = [Polygon]()
        func addTriangle(_ vertices: [Vertex]) -> Bool {
            guard !verticesAreDegenerate(vertices) else {
                return false
            }
            triangles.append(Polygon(
                unchecked: vertices,
                plane: plane,
                isConvex: true,
                material: material
            ))
            return true
        }
        if isConvex {
            let v0 = vertices[0]
            var v1 = vertices[1]
            for v2 in vertices[2...] {
                _ = addTriangle([v0, v1, v2])
                v1 = v2
            }
            return triangles
        }
        var i = 0
        var attempts = 0
        func removeVertex() {
            attempts = 0
            vertices.remove(at: i)
            if i == vertices.count {
                i = 0
            }
        }
        while vertices.count > 3 {
            let p0 = vertices[(i - 1 + vertices.count) % vertices.count]
            let p1 = vertices[i]
            let p2 = vertices[(i + 1) % vertices.count]
            // check for colinear points
            let p0p1 = p0.position - p1.position, p2p1 = p2.position - p1.position
            if p0p1.cross(p2p1).length < epsilon {
                // vertices are colinear, so we can't form a triangle
                if p0p1.dot(p2p1) > 0 {
                    // center point makes path degenerate - remove it
                    removeVertex()
                } else {
                    // try next point instead
                    i += 1
                }
                continue
            }
            let triangle = Polygon([p0, p1, p2])
            if triangle == nil ||
                triangle!.plane.normal.dot(plane.normal) <= 0 || vertices.contains(where: {
                    !triangle!.vertices.contains($0) && triangle!.containsPoint($0.position)
                })
            {
                i += 1
                if i == vertices.count {
                    i = 0
                    attempts += 1
                    if attempts > 1 {
                        return triangles
                    }
                }
            } else if addTriangle(triangle!.vertices) {
                removeVertex()
            }
        }
        _ = addTriangle(vertices)
        return triangles
    }
}

internal extension Polygon {
    // Create polygon from vertices and face normal without performing validation
    // Vertices may be convex or concave, but are assumed to describe a non-degenerate polygon
    init(
        unchecked vertices: [Vertex],
        normal: Vector,
        isConvex: Bool,
        bounds: Bounds? = nil,
        material: Material
    ) {
        self.init(
            unchecked: vertices,
            plane: Plane(unchecked: normal, pointOnPlane: vertices[0].position),
            isConvex: isConvex,
            bounds: bounds,
            material: material
        )
    }

    // Create polygon from vertices and plane without performing validation
    // Vertices may be convex or concave, but are assumed to describe a non-degenerate polygon
    // Vertices are assumed to be in anticlockwise order for the purpose of deriving the plane
    init(
        unchecked vertices: [Vertex],
        plane: Plane? = nil,
        isConvex: Bool? = nil,
        bounds: Bounds? = nil,
        material: Material = nil,
        id: Int = 0
    ) {
        assert(vertices.count > 2)
        assert(!verticesAreDegenerate(vertices))
        assert(isConvex == nil || verticesAreConvex(vertices) == isConvex)
        let isConvex = isConvex ?? verticesAreConvex(vertices)
        let points = (plane == nil || bounds == nil) ? vertices.map { $0.position } : []
        self.vertices = vertices
        self.plane = plane ?? Plane(unchecked: points, convex: isConvex)
        self.isConvex = isConvex
        self.bounds = bounds ?? Bounds(points: points)
        self.material = material
        self.id = id
    }

    // Join touching polygons (without checking they are coplanar or share the same material)
    func join(unchecked other: Polygon) -> Polygon? {
        assert(material == other.material)
        assert(plane.isEqual(to: other.plane))

        // get vertices
        var va = vertices
        var vb = other.vertices

        // find shared vertices
        var joins = [(Int, Int)]()
        for i in va.indices {
            if let j = vb.firstIndex(where: { $0.isEqual(to: va[i]) }) {
                joins.append((i, j))
            }
        }
        guard joins.count == 2 else {
            // TODO: what if 3 or more points are joined?
            return nil
        }
        var result = [Vertex]()
        let (a0, b0) = joins[0], (a1, b1) = joins[1]
        if a1 == a0 + 1 {
            result = Array(va[(a1 + 1)...] + va[..<a0])
        } else if a0 == 0, a1 == va.count - 1 {
            result = Array(va.dropFirst().dropLast())
        } else {
            return nil
        }
        let join1 = result.count
        if b1 == b0 + 1 {
            result += Array(vb[b1...] + vb[...b0])
        } else if b0 == b1 + 1 {
            result += Array(vb[b0...] + vb[...b1])
        } else if (b0 == 0 && b1 == vb.count - 1) || (b1 == 0 && b0 == vb.count - 1) {
            result += vb
        } else {
            return nil
        }
        let join2 = result.count - 1

        // can the merged points be removed?
        func testPoint(_ index: Int) {
            let prev = (index == 0) ? result.count - 1 : index - 1
            let va = (result[index].position - result[prev].position).normalized()
            let vb = (result[(index + 1) % result.count].position - result[index].position).normalized()
            // check if point is redundant
            if abs(va.dot(vb) - 1) < epsilon {
                // TODO: should we check that normal and uv ~= slerp of values either side?
                result.remove(at: index)
            }
        }
        testPoint(join2)
        testPoint(join1)

        // check result is not degenerate
        guard !verticesAreDegenerate(result) else {
            return nil
        }

        // replace poly with merged result
        return Polygon(
            unchecked: result,
            plane: plane,
            isConvex: verticesAreConvex(result),
            material: material,
            id: id
        )
    }
}
