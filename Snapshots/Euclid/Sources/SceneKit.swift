//
//  SceneKit.swift
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

#if canImport(SceneKit)

import SceneKit

public extension SCNVector3 {
    init(_ v: Vector) {
        self.init(v.x, v.y, v.z)
    }
}

public extension SCNQuaternion {
    init(_ m: Rotation) {
        let x = sqrt(max(0, 1 + m.m11 - m.m22 - m.m33)) / 2
        let y = sqrt(max(0, 1 - m.m11 + m.m22 - m.m33)) / 2
        let z = sqrt(max(0, 1 - m.m11 - m.m22 + m.m33)) / 2
        let w = sqrt(max(0, 1 + m.m11 + m.m22 + m.m33)) / 2
        self.init(
            x * (x * (m.m32 - m.m23) > 0 ? 1 : -1),
            y * (y * (m.m13 - m.m31) > 0 ? 1 : -1),
            z * (z * (m.m21 - m.m12) > 0 ? 1 : -1),
            -w
        )
    }
}

private extension Data {
    mutating func append(_ int: UInt32) {
        var int = int
        append(UnsafeBufferPointer(start: &int, count: 1))
    }

    mutating func append(_ double: Double) {
        var float = Float(double)
        append(UnsafeBufferPointer(start: &float, count: 1))
    }

    mutating func append(_ vector: Vector) {
        append(vector.x)
        append(vector.y)
        append(vector.z)
    }
}

public extension SCNNode {
    func setTransform(_ transform: Transform) {
        orientation = SCNQuaternion(transform.rotation)
        scale = SCNVector3(transform.scale)
        position = SCNVector3(transform.offset)
    }
}

public extension SCNGeometry {
    /// Creates an SCNGeometry using the default tessellation method
    convenience init(_ mesh: Mesh, materialLookup: ((Polygon.Material) -> SCNMaterial)? = nil) {
        self.init(triangles: mesh, materialLookup: materialLookup)
    }

    /// Creates an SCNGeometry from a Mesh using triangles
    convenience init(triangles mesh: Mesh, materialLookup: ((Polygon.Material) -> SCNMaterial)? = nil) {
        var elementData = [Data]()
        var vertexData = Data()
        var materials = [SCNMaterial]()
        var indicesByVertex = [Vertex: UInt32]()
        for (material, polygons) in mesh.polygonsByMaterial {
            var indexData = Data()
            func addVertex(_ vertex: Vertex) {
                if let index = indicesByVertex[vertex] {
                    indexData.append(index)
                    return
                }
                let index = UInt32(indicesByVertex.count)
                indicesByVertex[vertex] = index
                indexData.append(index)
                vertexData.append(vertex.position)
                vertexData.append(vertex.normal)
                vertexData.append(vertex.texcoord.x)
                vertexData.append(vertex.texcoord.y)
            }
            if let materialLookup = materialLookup {
                materials.append(materialLookup(material))
            }
            for polygon in polygons {
                for triangle in polygon.triangulate() {
                    triangle.vertices.forEach(addVertex)
                }
            }
            elementData.append(indexData)
        }
        let vertexStride = 12 + 12 + 8
        let vertexCount = vertexData.count / vertexStride
        self.init(
            sources: [
                SCNGeometrySource(
                    data: vertexData,
                    semantic: .vertex,
                    vectorCount: vertexCount,
                    usesFloatComponents: true,
                    componentsPerVector: 3,
                    bytesPerComponent: 4,
                    dataOffset: 0,
                    dataStride: vertexStride
                ),
                SCNGeometrySource(
                    data: vertexData,
                    semantic: .normal,
                    vectorCount: vertexCount,
                    usesFloatComponents: true,
                    componentsPerVector: 3,
                    bytesPerComponent: 4,
                    dataOffset: 12,
                    dataStride: vertexStride
                ),
                SCNGeometrySource(
                    data: vertexData,
                    semantic: .texcoord,
                    vectorCount: vertexCount,
                    usesFloatComponents: true,
                    componentsPerVector: 2,
                    bytesPerComponent: 4,
                    dataOffset: 24,
                    dataStride: vertexStride
                ),
            ],
            elements: elementData.map { indexData in
                SCNGeometryElement(
                    data: indexData,
                    primitiveType: .triangles,
                    primitiveCount: indexData.count / 12,
                    bytesPerIndex: 4
                )
            }
        )
        self.materials = materials
    }

    /// Creates an SCNGeometry from a Mesh using convex polygons
    @available(OSX 10.12, iOS 10.0, *)
    convenience init(polygons mesh: Mesh, materialLookup: ((Polygon.Material) -> SCNMaterial)? = nil) {
        var elementData = [(Int, Data)]()
        var vertexData = Data()
        var materials = [SCNMaterial]()
        var indicesByVertex = [Vertex: UInt32]()
        for (material, polygons) in mesh.polygonsByMaterial {
            var indexData = Data()
            func addVertex(_ vertex: Vertex) {
                if let index = indicesByVertex[vertex] {
                    indexData.append(index)
                    return
                }
                let index = UInt32(indicesByVertex.count)
                indicesByVertex[vertex] = index
                indexData.append(index)
                vertexData.append(vertex.position)
                vertexData.append(vertex.normal)
                vertexData.append(vertex.texcoord.x)
                vertexData.append(vertex.texcoord.y)
            }
            if let materialLookup = materialLookup {
                materials.append(materialLookup(material))
            }
            let polygons = polygons.flatMap { $0.tessellate() }
            for polygon in polygons {
                indexData.append(UInt32(polygon.vertices.count))
            }
            for polygon in polygons {
                polygon.vertices.forEach(addVertex)
            }
            elementData.append((polygons.count, indexData))
        }
        let vertexStride = 12 + 12 + 8
        let vertexCount = vertexData.count / vertexStride
        self.init(
            sources: [
                SCNGeometrySource(
                    data: vertexData,
                    semantic: .vertex,
                    vectorCount: vertexCount,
                    usesFloatComponents: true,
                    componentsPerVector: 3,
                    bytesPerComponent: 4,
                    dataOffset: 0,
                    dataStride: vertexStride
                ),
                SCNGeometrySource(
                    data: vertexData,
                    semantic: .normal,
                    vectorCount: vertexCount,
                    usesFloatComponents: true,
                    componentsPerVector: 3,
                    bytesPerComponent: 4,
                    dataOffset: 12,
                    dataStride: vertexStride
                ),
                SCNGeometrySource(
                    data: vertexData,
                    semantic: .texcoord,
                    vectorCount: vertexCount,
                    usesFloatComponents: true,
                    componentsPerVector: 2,
                    bytesPerComponent: 4,
                    dataOffset: 24,
                    dataStride: vertexStride
                ),
            ],
            elements: elementData.map { count, indexData in
                SCNGeometryElement(
                    data: indexData,
                    primitiveType: .polygon,
                    primitiveCount: count,
                    bytesPerIndex: 4
                )
            }
        )
        self.materials = materials
    }

    /// Creates a wireframe SCNGeometry from a Mesh using line segments
    convenience init(wireframe mesh: Mesh) {
        var indexData = Data()
        var vertexData = Data()
        var indicesByVertex = [Vector: UInt32]()
        func addVertex(_ vertex: Vector) {
            if let index = indicesByVertex[vertex] {
                indexData.append(index)
                return
            }
            let index = UInt32(indicesByVertex.count)
            indicesByVertex[vertex] = index
            indexData.append(index)
            vertexData.append(vertex)
        }
        for polygon in mesh.polygons {
            for polygon in polygon.tessellate() {
                let vertices = polygon.vertices
                var v0 = vertices.last
                for v1 in vertices {
                    addVertex(v0!.position)
                    addVertex(v1.position)
                    v0 = v1
                }
            }
        }
        self.init(
            sources: [
                SCNGeometrySource(
                    data: vertexData,
                    semantic: .vertex,
                    vectorCount: vertexData.count / 12,
                    usesFloatComponents: true,
                    componentsPerVector: 3,
                    bytesPerComponent: 4,
                    dataOffset: 0,
                    dataStride: 0
                ),
            ],
            elements: [
                SCNGeometryElement(
                    data: indexData,
                    primitiveType: .line,
                    primitiveCount: indexData.count / 8,
                    bytesPerIndex: 4
                ),
            ]
        )
    }

    /// Creates line-segment SCNGeometry representing the vertex normals of a Mesh
    convenience init(normals mesh: Mesh, scale: Double = 1) {
        var indexData = Data()
        var vertexData = Data()
        var indicesByVertex = [Vector: UInt32]()
        func addVertex(_ vertex: Vector) {
            if let index = indicesByVertex[vertex] {
                indexData.append(index)
                return
            }
            let index = UInt32(indicesByVertex.count)
            indicesByVertex[vertex] = index
            indexData.append(index)
            vertexData.append(vertex)
        }
        func addNormal(for vertex: Vertex) {
            addVertex(vertex.position)
            addVertex(vertex.position + vertex.normal * scale)
        }
        for polygon in mesh.polygons {
            let vertices = polygon.vertices
            let v0 = vertices[0]
            for i in 2 ..< vertices.count {
                addNormal(for: v0)
                addNormal(for: vertices[i - 1])
                addNormal(for: vertices[i])
            }
        }
        self.init(
            sources: [
                SCNGeometrySource(
                    data: vertexData,
                    semantic: .vertex,
                    vectorCount: vertexData.count / 12,
                    usesFloatComponents: true,
                    componentsPerVector: 3,
                    bytesPerComponent: 4,
                    dataOffset: 0,
                    dataStride: 0
                ),
            ],
            elements: [
                SCNGeometryElement(
                    data: indexData,
                    primitiveType: .line,
                    primitiveCount: indexData.count / 8,
                    bytesPerIndex: 4
                ),
            ]
        )
    }

    // Creates a line-segment SCNGeometry from a Path
    convenience init(_ path: Path) {
        var indexData = Data()
        var vertexData = Data()
        var indicesByPoint = [Vector: UInt32]()
        for path in path.subpaths {
            for vertex in path.edgeVertices {
                let point = vertex.position
                if let index = indicesByPoint[point] {
                    indexData.append(index)
                    continue
                }
                let index = UInt32(indicesByPoint.count)
                indicesByPoint[point] = index
                indexData.append(index)
                vertexData.append(point)
            }
        }
        self.init(
            sources: [
                SCNGeometrySource(
                    data: vertexData,
                    semantic: .vertex,
                    vectorCount: vertexData.count / 8,
                    usesFloatComponents: true,
                    componentsPerVector: 3,
                    bytesPerComponent: 4,
                    dataOffset: 0,
                    dataStride: 0
                ),
            ],
            elements: [
                SCNGeometryElement(
                    data: indexData,
                    primitiveType: .line,
                    primitiveCount: indexData.count / 8,
                    bytesPerIndex: 4
                ),
            ]
        )
    }

    // Creates a line-segment bounding-box SCNGeometry from a Bounds
    convenience init(bounds: Bounds) {
        var vertexData = Data()
        for point in bounds.corners {
            vertexData.append(point)
        }
        let indices: [UInt32] = [
            // bottom
            0, 1, 1, 2, 2, 3, 3, 0,
            // top
            4, 5, 5, 6, 6, 7, 7, 4,
            // columns
            0, 4, 1, 5, 2, 6, 3, 7,
        ]
        var indexData = Data()
        indices.forEach { indexData.append($0) }
        self.init(
            sources: [
                SCNGeometrySource(
                    data: vertexData,
                    semantic: .vertex,
                    vectorCount: vertexData.count / 8,
                    usesFloatComponents: true,
                    componentsPerVector: 3,
                    bytesPerComponent: 4,
                    dataOffset: 0,
                    dataStride: 0
                ),
            ],
            elements: [
                SCNGeometryElement(
                    data: indexData,
                    primitiveType: .line,
                    primitiveCount: indexData.count / 8,
                    bytesPerIndex: 4
                ),
            ]
        )
    }
}

// MARK: import

private extension Data {
    func index(at index: Int, bytes: Int) -> UInt32 {
        switch bytes {
        case 1: return UInt32(self[index])
        case 2: return UInt32(uint16(at: index * 2))
        case 4: return uint32(at: index * 4)
        default: preconditionFailure()
        }
    }

    func uint16(at index: Int) -> UInt16 {
        var int: UInt16 = 0
        _ = copyBytes(
            to: UnsafeMutableBufferPointer(start: &int, count: 1),
            from: index ..< index + 2
        )
        return int
    }

    func uint32(at index: Int) -> UInt32 {
        var int: UInt32 = 0
        _ = copyBytes(
            to: UnsafeMutableBufferPointer(start: &int, count: 1),
            from: index ..< index + 4
        )
        return int
    }

    func float(at index: Int) -> Double {
        var float: Float = 0
        _ = copyBytes(
            to: UnsafeMutableBufferPointer(start: &float, count: 1),
            from: index ..< index + 4
        )
        return Double(float)
    }

    func vector(at index: Int) -> Vector {
        return Vector(
            float(at: index),
            float(at: index + 4),
            float(at: index + 8)
        )
    }
}

public extension Vector {
    init(_ v: SCNVector3) {
        self.init(Double(v.x), Double(v.y), Double(v.z))
    }
}

public extension Rotation {
    init(_ q: SCNQuaternion) {
        let d = sqrt(1 - Double(q.w * q.w))
        guard d > epsilon else {
            self = .identity
            return
        }
        let axis = Vector(Double(q.x) / d, Double(q.y) / d, Double(q.z) / d)
        self.init(unchecked: axis.normalized(), radians: Double(2 * acos(-q.w)))
    }
}

public extension Transform {
    static func transform(from scnNode: SCNNode) -> Transform {
        return Transform(
            offset: Vector(scnNode.position),
            rotation: Rotation(scnNode.orientation),
            scale: Vector(scnNode.scale)
        )
    }
}

public extension Mesh {
    init?(scnGeometry: SCNGeometry, materialLookup: ((SCNMaterial) -> Polygon.Material)? = nil) {
        var polygons = [Polygon]()
        var vertices = [Vertex]()
        for source in scnGeometry.sources {
            let count = source.vectorCount
            if vertices.isEmpty {
                vertices = Array(repeating: Vertex(.zero, .zero), count: count)
            } else if vertices.count != source.vectorCount {
                return nil
            }
            var offset = source.dataOffset
            let stride = source.dataStride
            let data = source.data
            switch source.semantic {
            case .vertex:
                for i in 0 ..< count {
                    vertices[i].position = data.vector(at: offset)
                    offset += stride
                }
            case .normal:
                for i in 0 ..< count {
                    vertices[i].normal = data.vector(at: offset)
                    offset += stride
                }
            case .texcoord:
                for i in 0 ..< count {
                    vertices[i].texcoord = Vector(
                        data.float(at: offset),
                        data.float(at: offset + 4)
                    )
                    offset += stride
                }
            default:
                continue
            }
        }
        let materials: [Polygon.Material] = materialLookup.map {
            scnGeometry.materials.map($0)
        } ?? []
        for (index, element) in scnGeometry.elements.enumerated() {
            let material = materials.isEmpty ? nil : materials[index % materials.count]
            switch element.primitiveType {
            case .triangles:
                let indexData = element.data
                let indexSize = element.bytesPerIndex
                func vertex(at i: Int) -> Vertex {
                    let index = indexData.index(at: i, bytes: indexSize)
                    return vertices[Int(index)]
                }
                for i in 0 ..< element.primitiveCount {
                    Polygon([
                        vertex(at: i * 3),
                        vertex(at: i * 3 + 1),
                        vertex(at: i * 3 + 2),
                    ], material: material).map {
                        polygons.append($0)
                    }
                }
            default:
                break // TODO:
            }
        }
        self.init(polygons)
    }
}

#endif
