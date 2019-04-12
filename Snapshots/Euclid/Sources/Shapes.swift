//
//  Shapes.swift
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

import Foundation

// MARK: 3D shapes

public extension Path {
    /// Create a closed circular path
    static func circle(radius r: Double = 0.5, segments: Int = 16) -> Path {
        return ellipse(width: r * 2, height: r * 2, segments: segments)
    }

    /// Create a closed elliptical path
    static func ellipse(width: Double, height: Double, segments: Int = 16) -> Path {
        var points = [PathPoint]()
        let segments = max(3, Double(segments))
        let w = max(abs(width / 2), epsilon), h = max(abs(height / 2), epsilon)
        for angle in stride(from: 0, through: 2 * .pi, by: 2 * .pi / segments) {
            points.append(.curve(w * -sin(angle), h * cos(angle)))
        }
        return Path(unchecked: points, plane: .xy, subpathIndices: [])
    }

    /// Create a closed rectangular path
    static func rectangle(width: Double, height: Double) -> Path {
        let w = width / 2, h = height / 2
        return Path(unchecked: [
            .point(-w, h), .point(-w, -h),
            .point(w, -h), .point(w, h),
            .point(-w, h),
        ], plane: .xy, subpathIndices: [])
    }

    /// Create a closed square path
    static func square(size: Double = 1) -> Path {
        return rectangle(width: size, height: size)
    }

    /// Create a quadratic bezier spline
    static func curve(_ points: [PathPoint], detail: Int = 4) -> Path {
        enum ArcRange {
            case lhs, rhs, all
        }

        func arc(_ p0: PathPoint, _ p1: PathPoint, _ p2: PathPoint,
                 _ detail: Int, _ range: ArcRange = .all) -> [PathPoint] {
            let detail = detail + 1
            assert(detail >= 2)
            let steps: [Double]
            switch range {
            case .all:
                // excludes start and end points
                steps = (1 ..< detail).map { Double($0) / Double(detail) }
            case .lhs:
                // includes start and end point
                steps = (0 ..< Int(ceil(Double(detail) / 2))).map { Double($0) / Double(detail) } + [0.5]
            case .rhs:
                // excludes end point
                steps = [0.5] + (detail / 2 + 1 ..< detail).map { Double($0) / Double(detail) }
            }

            return steps.map {
                .curve(
                    quadraticBezier(p0.position.x, p1.position.x, p2.position.x, $0),
                    quadraticBezier(p0.position.y, p1.position.y, p2.position.y, $0),
                    quadraticBezier(p0.position.z, p1.position.z, p2.position.z, $0)
                )
            }
        }

        var points = sanitizePoints(points)
        guard detail > 0, !points.isEmpty else {
            return Path(unchecked: points, plane: nil, subpathIndices: nil)
        }
        var result = [PathPoint]()
        let isClosed = pointsAreClosed(unchecked: points)
        let count = points.count
        let start = isClosed ? 0 : 1
        let end = count - 1
        var p0 = isClosed ? points[count - 2] : points[0]
        var p1 = isClosed ? points[0] : points[1]
        if !isClosed {
            if p0.isCurved, count >= 3 {
                let pe = extrapolate(points[2], p1, p0)
                if p1.isCurved {
                    result += arc(pe.lerp(p0, 0.5), p0, p0.lerp(p1, 0.5), detail, .rhs)
                } else {
                    result += arc(pe, p0, p1, detail, .rhs)
                }
            } else {
                result.append(p0)
            }
        }
        for i in start ..< end {
            let p2 = points[(i + 1) % count]
            switch (p0.isCurved, p1.isCurved, p2.isCurved) {
            case (false, true, false):
                result += arc(p0, p1, p2, detail + 1)
            case (true, true, true):
                let p0p1 = p0.lerp(p1, 0.5)
                result.append(p0p1)
                result += arc(p0p1, p1, p1.lerp(p2, 0.5), detail)
            case (true, true, false):
                let p0p1 = p0.lerp(p1, 0.5)
                result.append(p0p1)
                result += arc(p0p1, p1, p2, detail)
            case (false, true, true):
                result += arc(p0, p1, p1.lerp(p2, 0.5), detail)
            case (_, false, _):
                result.append(p1)
            }
            p0 = p1
            p1 = p2
        }
        if !isClosed {
            let p2 = points.last!
            if p2.isCurved, count >= 3 {
                p1 = p0
                let pe = extrapolate(points[count - 3], p1, p2)
                if p1.isCurved {
                    result += arc(p1.lerp(p2, 0.5), p2, p2.lerp(pe, 0.5), detail, .lhs)
                } else {
                    result += arc(p1, p2, pe, detail, .lhs).dropFirst()
                }
            } else {
                result.append(p2)
            }
        } else {
            result.append(result[0])
        }
        let path = Path(unchecked: result, plane: nil, subpathIndices: nil)
        assert(path.isClosed == isClosed)
        return path
    }
}

public extension Mesh {
    enum Faces {
        case front
        case back
        case frontAndBack
        case `default`
    }

    enum WrapMode {
        case shrink
        case tube
        case `default`
    }

    /// Construct an axis-aligned cuboid mesh
    static func cube(center c: Vector = .init(0, 0, 0),
                     size s: Vector,
                     faces: Faces = .default,
                     material: Polygon.Material = nil) -> Mesh {
        let polygons: [Polygon] = [
            [[5, 1, 3, 7], [+1, 0, 0]],
            [[0, 4, 6, 2], [-1, 0, 0]],
            [[6, 7, 3, 2], [0, +1, 0]],
            [[0, 1, 5, 4], [0, -1, 0]],
            [[4, 5, 7, 6], [0, 0, +1]],
            [[1, 0, 2, 3], [0, 0, -1]],
        ].map {
            var index = 0
            let (indexData, normalData) = ($0[0], $0[1])
            let normal = Vector(
                Double(normalData[0]),
                Double(normalData[1]),
                Double(normalData[2])
            )
            return Polygon(
                unchecked: indexData.map { i in
                    let pos = c + s.scaled(by: Vector(
                        i & 1 > 0 ? 0.5 : -0.5,
                        i & 2 > 0 ? 0.5 : -0.5,
                        i & 4 > 0 ? 0.5 : -0.5
                    ))
                    let uv = Vector(
                        (1 ... 2).contains(index) ? 1 : 0,
                        (0 ... 1).contains(index) ? 1 : 0
                    )
                    index += 1
                    return Vertex(pos, normal, uv)
                },
                normal: normal,
                isConvex: true,
                material: material
            )
        }
        switch faces {
        case .front, .default:
            return Mesh(polygons)
        case .back:
            return Mesh(polygons.map { $0.inverted() })
        case .frontAndBack:
            return Mesh(polygons + polygons.map { $0.inverted() })
        }
    }

    static func cube(center c: Vector = .init(0, 0, 0),
                     size s: Double = 1,
                     faces: Faces = .default,
                     material: Polygon.Material = nil) -> Mesh {
        return cube(center: c, size: Vector(s, s, s), faces: faces, material: material)
    }

    /// Construct a sphere mesh
    static func sphere(radius r: Double = 0.5,
                       slices: Int = 16,
                       stacks: Int? = nil,
                       poleDetail: Int = 0,
                       faces: Faces = .default,
                       wrapMode: WrapMode = .default,
                       material: Polygon.Material = nil) -> Mesh {
        var semicircle = [PathPoint]()
        let stacks = max(2, stacks ?? (slices / 2))
        let r = max(abs(r), epsilon)
        for i in 0 ... stacks {
            let a = Double(i) / Double(stacks) * .pi
            semicircle.append(.curve(-sin(a) * r, cos(a) * r))
        }
        return lathe(
            Path(unchecked: semicircle, plane: .xy, subpathIndices: []),
            slices: slices,
            poleDetail: poleDetail,
            faces: faces,
            wrapMode: wrapMode,
            material: material
        )
    }

    /// Construct a cylindrical mesh
    static func cylinder(radius r: Double = 0.5,
                         height h: Double = 1,
                         slices: Int = 16,
                         poleDetail: Int = 0,
                         faces: Faces = .default,
                         wrapMode: WrapMode = .default,
                         material: Polygon.Material = nil) -> Mesh {
        let r = max(abs(r), epsilon)
        let h = max(abs(h), epsilon)
        let wrapMode = wrapMode == .default ? .tube : wrapMode
        return lathe(
            Path(unchecked: [
                .point(0, h / 2),
                .point(-r, h / 2),
                .point(-r, -h / 2),
                .point(0, -h / 2),
            ], plane: .xy, subpathIndices: []),
            slices: slices,
            poleDetail: poleDetail,
            addDetailForFlatPoles: true,
            faces: faces,
            wrapMode: wrapMode,
            material: material
        )
    }

    /// Construct as conical mesh
    static func cone(radius r: Double = 0.5,
                     height h: Double = 1,
                     slices: Int = 16,
                     poleDetail: Int? = nil,
                     addDetailAtBottomPole: Bool = false,
                     faces: Faces = .default,
                     wrapMode: WrapMode = .default,
                     material: Polygon.Material = nil) -> Mesh {
        let r = max(abs(r), epsilon)
        let h = max(abs(h), epsilon)
        let poleDetail = poleDetail ?? Int(sqrt(Double(slices)))
        let wrapMode = wrapMode == .default ? .tube : wrapMode
        return lathe(
            Path(unchecked: [
                .point(0, h / 2),
                .point(-r, -h / 2),
                .point(0, -h / 2),
            ], plane: .xy, subpathIndices: []),
            slices: slices,
            poleDetail: poleDetail,
            addDetailForFlatPoles: addDetailAtBottomPole,
            faces: faces,
            wrapMode: wrapMode,
            material: material
        )
    }

    /// Create a rotationally symmetrical shape by rotating the supplied path
    /// around an axis. The path consists of an array of xy coordinate pairs
    /// defining the profile of the shape. Some notes on path coordinates:
    ///
    /// * The path can be open or closed. Define a closed path by ending with
    ///   the same coordinate pair that you started with
    ///
    /// * The path can be placed on either the left or right of the Y axis,
    ///   however the behavior is undefined for paths that cross the Y axis
    ///
    /// * Open paths that do not start and end on the Y axis will produce
    ///   a shape with a hole in it
    ///
    static func lathe(_ profile: Path,
                      slices: Int = 16,
                      poleDetail: Int = 0,
                      addDetailForFlatPoles: Bool = false,
                      faces: Faces = .default,
                      wrapMode: WrapMode = .default,
                      material: Polygon.Material = nil) -> Mesh {
        let subpaths = profile.subpaths
        if subpaths.count > 1 {
            return .xor(subpaths.map {
                .lathe(
                    $0,
                    slices: slices,
                    poleDetail: poleDetail,
                    addDetailForFlatPoles: addDetailForFlatPoles,
                    faces: faces,
                    wrapMode: wrapMode,
                    material: material
                )
            })
        }

        var profile = profile
        if profile.points.count < 2 {
            return Mesh([])
        }

        // min slices
        let slices = max(3, slices)

        // normalize profile
        profile = profile.flattened().clippedToYAxis()
        guard let normal = profile.plane?.normal else {
            assertionFailure()
            return Mesh([])
        }
        if normal.z < 0 {
            profile = Path(
                unchecked: profile.points.reversed(),
                plane: profile.plane?.inverted(),
                subpathIndices: nil // Is is possible to reverse these?
            )
        }

        // get profile vertices
        var vertices = profile.edgeVertices(for: wrapMode)

        // add more detail around poles automatically
        if poleDetail > 0 {
            func subdivide(_ times: Int, _ v0: Vertex, _ v1: Vertex) -> [Vertex] {
                guard times > 0 else {
                    return [v0, v1]
                }
                let v0v1 = v0.lerp(v1, 0.5)
                return subdivide(times - 1, v0, v0v1) + [v0v1, v1]
            }
            func isVertical(_ normal: Vector) -> Bool {
                return abs(normal.x) < epsilon && abs(normal.z) < epsilon
            }
            var i = 0
            while i < vertices.count {
                let v0 = vertices[i]
                let v1 = vertices[i + 1]
                if v0.position.x == 0 {
                    if v1.position.x != 0, addDetailForFlatPoles || !isVertical(v0.normal) {
                        let s = subdivide(poleDetail, v0, v1)
                        vertices.replaceSubrange(i ... i + 1, with: s)
                        i += s.count - 2
                    }
                } else if v1.position.x == 0, addDetailForFlatPoles || !isVertical(v1.normal) {
                    let s = subdivide(poleDetail, v1, v0).reversed()
                    vertices.replaceSubrange(i ... i + 1, with: s)
                    i += s.count - 2
                }
                i += 2
            }
        }

        var polygons = [Polygon]()
        for i in 0 ..< slices {
            let t0 = Double(i) / Double(slices), t1 = Double(i + 1) / Double(slices)
            let a0 = t0 * 2 * .pi, a1 = t1 * 2 * .pi
            let cos0 = cos(a0), cos1 = cos(a1), sin0 = sin(a0), sin1 = sin(a1)
            for j in stride(from: 1, to: vertices.count, by: 2) {
                let v0 = vertices[j - 1], v1 = vertices[j]
                if v0.position.x == 0 {
                    if abs(v1.position.x) >= epsilon {
                        // top triangle
                        let v0 = Vertex(
                            unchecked: v0.position,
                            Vector(cos0 * v0.normal.x, v0.normal.y, sin0 * -v0.normal.x),
                            Vector(v0.texcoord.x + (t0 + t1) / 2, v0.texcoord.y, 0)
                        )
                        let v2 = Vertex(unchecked:
                            Vector(cos0 * v1.position.x, v1.position.y, sin0 * -v1.position.x),
                                        Vector(cos0 * v1.normal.x, v1.normal.y, sin0 * -v1.normal.x),
                                        Vector(v1.texcoord.x + t0, v1.texcoord.y, 0))
                        let v3 = Vertex(unchecked:
                            Vector(cos1 * v1.position.x, v1.position.y, sin1 * -v1.position.x),
                                        Vector(cos1 * v1.normal.x, v1.normal.y, sin1 * -v1.normal.x),
                                        Vector(v1.texcoord.x + t1, v1.texcoord.y, 0))
                        polygons.append(Polygon(unchecked: [v0, v2, v3], isConvex: true, material: material))
                    }
                } else if v1.position.x == 0 {
                    // bottom triangle
                    let v1 = Vertex(
                        unchecked: v1.position,
                        Vector(cos0 * v1.normal.x, v1.normal.y, sin0 * -v1.normal.x),
                        Vector(v1.texcoord.x + (t0 + t1) / 2, v1.texcoord.y, 0)
                    )
                    let v2 = Vertex(unchecked:
                        Vector(cos1 * v0.position.x, v0.position.y, sin1 * -v0.position.x),
                                    Vector(cos1 * v0.normal.x, v0.normal.y, sin1 * -v0.normal.x),
                                    Vector(v0.texcoord.x + t1, v0.texcoord.y, 0))
                    let v3 = Vertex(unchecked:
                        Vector(cos0 * v0.position.x, v0.position.y, sin0 * -v0.position.x),
                                    Vector(cos0 * v0.normal.x, v0.normal.y, sin0 * -v0.normal.x),
                                    Vector(v0.texcoord.x + t0, v0.texcoord.y, 0))
                    polygons.append(Polygon(unchecked: [v2, v3, v1], isConvex: true, material: material))
                } else {
                    // quad face
                    let v2 = Vertex(unchecked:
                        Vector(cos1 * v0.position.x, v0.position.y, sin1 * -v0.position.x),
                                    Vector(cos1 * v0.normal.x, v0.normal.y, sin1 * -v0.normal.x),
                                    Vector(v0.texcoord.x + t1, v0.texcoord.y, 0))
                    let v3 = Vertex(unchecked:
                        Vector(cos0 * v0.position.x, v0.position.y, sin0 * -v0.position.x),
                                    Vector(cos0 * v0.normal.x, v0.normal.y, sin0 * -v0.normal.x),
                                    Vector(v0.texcoord.x + t0, v0.texcoord.y, 0))
                    let v4 = Vertex(unchecked:
                        Vector(cos0 * v1.position.x, v1.position.y, sin0 * -v1.position.x),
                                    Vector(cos0 * v1.normal.x, v1.normal.y, sin0 * -v1.normal.x),
                                    Vector(v1.texcoord.x + t0, v1.texcoord.y, 0))
                    let v5 = Vertex(unchecked:
                        Vector(cos1 * v1.position.x, v1.position.y, sin1 * -v1.position.x),
                                    Vector(cos1 * v1.normal.x, v1.normal.y, sin1 * -v1.normal.x),
                                    Vector(v1.texcoord.x + t1, v1.texcoord.y, 0))
                    let vertices = [v2, v3, v4, v5]
                    if !verticesAreDegenerate(vertices) {
                        polygons.append(Polygon(unchecked: vertices, isConvex: true, material: material))
                    }
                }
            }
        }

        switch faces {
        case .front:
            return Mesh(polygons)
        case .back:
            return Mesh(polygons.map { $0.inverted() })
        case .frontAndBack:
            return Mesh(polygons + polygons.map { $0.inverted() })
        case .default:
            // seal loose ends
            // TODO: improve this by not adding backfaces inside closed subsectors
            if let first = vertices.first?.position,
                let last = vertices.last?.position,
                first != last, first.x != 0 || last.x != 0 {
                polygons += polygons.map { $0.inverted() }
            }
            return Mesh(polygons)
        }
    }

    /// Extrude a path along its face normal
    static func extrude(_ shape: Path,
                        depth: Double = 1,
                        faces: Faces = .default,
                        material: Polygon.Material = nil) -> Mesh {
        let offset = (shape.plane?.normal ?? Vector(0, 0, 1)) * (depth / 2)
        if offset.lengthSquared < epsilon {
            return fill(shape, faces: faces, material: material)
        }
        return loft([
            shape.translated(by: offset),
            shape.translated(by: -offset),
        ], faces: faces, material: material)
    }

    /// Connect multiple 3D paths
    static func loft(_ shapes: [Path],
                     faces: Faces = .default,
                     material: Polygon.Material = nil) -> Mesh {
        var subpathCount = 0
        let arrayOfSubpaths: [[Path]] = shapes.map {
            let subpaths = $0.subpaths
            subpathCount = max(subpathCount, subpaths.count)
            return subpaths
        }
        if subpathCount > 1 {
            var subshapes = Array(repeating: [Path](), count: subpathCount)
            for subpaths in arrayOfSubpaths {
                for (i, subpath) in subpaths.enumerated() {
                    subshapes[i].append(subpath)
                }
            }
            return .xor(subshapes.map { .loft($0, faces: faces, material: material) })
        }

        // TODO: handle subpaths
        var shapes = shapes
        if shapes.isEmpty {
            return Mesh([])
        }
        let count = shapes.count
        let isClosed = (shapes.first == shapes.last)
        if count < 3, isClosed {
            return fill(shapes[0], faces: faces, material: material)
        }
        func directionBetweenShapes(_ s0: Path, _ s1: Path) -> Vector? {
            if let p0 = s0.points.first, let p1 = s1.points.first {
                // TODO: what if p0p1 length is zero? We should try other points
                return (p1.position - p0.position).normalized()
            }
            return nil
        }
        var polygons = [Polygon]()
        var prev = shapes[0]
        if !isClosed, var polygon = Polygon(shape: prev, material: material) {
            if let p0p1 = directionBetweenShapes(prev, shapes[1]), p0p1.dot(polygon.plane.normal) > 0 {
                polygon = polygon.inverted()
            }
            polygons.append(polygon)
        }
        let uvstep = Double(1) / Double(count - 1)
        var e1 = prev.edgeVertices
        for i in 1 ..< count {
            let path = shapes[i]
            let e0 = e1
            e1 = path.edgeVertices
            // TODO: better handling of case where e0 and e1 counts don't match
            let invert: Bool
            if let n = prev.plane?.normal,
                let p0p1 = directionBetweenShapes(prev, path), p0p1.dot(n) > 0 {
                invert = false
            } else {
                invert = true
            }
            let uvx0 = Double(i - 1) * uvstep
            let uvx1 = uvx0 + uvstep
            for j in stride(from: 0, to: min(e0.count, e1.count), by: 2) {
                var vertices = [e0[j], e0[j + 1], e1[j + 1], e1[j]]
                vertices[0].texcoord = Vector(vertices[0].texcoord.y, uvx0)
                vertices[1].texcoord = Vector(vertices[1].texcoord.y, uvx0)
                vertices[2].texcoord = Vector(vertices[2].texcoord.y, uvx1)
                vertices[3].texcoord = Vector(vertices[3].texcoord.y, uvx1)
                if vertices[0].position == vertices[1].position {
                    vertices.remove(at: 0)
                } else if vertices[2].position == vertices[3].position {
                    vertices.remove(at: 3)
                } else {
                    if vertices[0].position == vertices[3].position {
                        vertices[0].normal = vertices[0].normal + vertices[3].normal // auto-normalized
                        vertices.remove(at: 3)
                    }
                    if vertices[1].position == vertices[2].position {
                        vertices[1].normal = vertices[1].normal + vertices[2].normal // auto-normalized
                        vertices.remove(at: 2)
                    }
                }
                if !verticesAreDegenerate(vertices) {
                    polygons.append(Polygon(
                        unchecked: invert ? vertices.reversed() : vertices,
                        isConvex: true,
                        material: material
                    ))
                }
            }
            // TODO: create triangles for mismatched points points
            prev = path
        }
        if !isClosed, var polygon = Polygon(shape: prev, material: material) {
            if let p0p1 = directionBetweenShapes(shapes[shapes.count - 2], prev),
                p0p1.dot(polygon.plane.normal) < 0 {
                polygon = polygon.inverted()
            }
            polygons.append(polygon)
        }
        switch faces {
        case .default where !shapes.contains(where: { !$0.isClosed }), .front:
            return Mesh(polygons)
        case .back:
            return Mesh(polygons.map { $0.inverted() })
        case .frontAndBack, .default:
            return Mesh(polygons + polygons.map { $0.inverted() })
        }
    }

    /// Fill a path to form a polygon
    static func fill(_ shape: Path,
                     faces: Faces = .default,
                     material: Polygon.Material = nil) -> Mesh {
        let subpaths = shape.subpaths
        if subpaths.count > 1 {
            return .xor(subpaths.map { .fill($0, faces: faces, material: material) })
        }

        guard let polygon = Polygon(shape: shape.closed(), material: material) else {
            return Mesh([])
        }
        switch faces {
        case .front:
            return Mesh([polygon])
        case .back:
            return Mesh([polygon.inverted()])
        case .frontAndBack, .default:
            return Mesh([polygon, polygon.inverted()])
        }
    }
}
