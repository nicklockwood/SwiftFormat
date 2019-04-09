//
//  Vertex.swift
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

/// A polygon vertex
public struct Vertex: Hashable {
    public var position: Vector {
        didSet { position = position.quantized() }
    }

    public var normal: Vector {
        didSet { normal = normal.normalized() }
    }

    public var texcoord: Vector
}

public extension Vertex {
    init(_ position: Vector, _ normal: Vector, _ texcoord: Vector = .zero) {
        self.init(unchecked: position, normal.normalized(), texcoord)
    }

    /// Invert all orientation-specific data (e.g. vertex normal). Called when the
    /// orientation of a polygon is flipped.
    func inverted() -> Vertex {
        return Vertex(unchecked: position, -normal, texcoord)
    }

    /// Linearly interpolate between two vertices.
    /// Interpolation is applied to the position, texture coordinate and normal.
    func lerp(_ other: Vertex, _ t: Double) -> Vertex {
        return Vertex(
            unchecked: position.lerp(other.position, t),
            normal.lerp(other.normal, t),
            texcoord.lerp(other.texcoord, t)
        )
    }
}

internal extension Vertex {
    init(unchecked position: Vector, _ normal: Vector, _ texcoord: Vector = .zero) {
        self.position = position.quantized()
        self.normal = normal
        self.texcoord = texcoord
    }

    // Approximate equality
    func isEqual(to other: Vertex, withPrecision p: Double = epsilon) -> Bool {
        return position.isEqual(to: other.position, withPrecision: p) &&
            normal.isEqual(to: other.normal, withPrecision: p) &&
            texcoord.isEqual(to: other.texcoord, withPrecision: p)
    }
}
