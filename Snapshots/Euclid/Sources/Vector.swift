//
//  Vector.swift
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

/// A distance or position in 3D space
public struct Vector: Hashable {
    public var x, y, z: Double
}

public extension Vector {
    static let zero = Vector(0, 0, 0)

    init(_ x: Double, _ y: Double, _ z: Double = 0) {
        self.x = x
        self.y = y
        self.z = z
    }

    /// Create a vector from an array of coordinates.
    /// Omitted values are defaulted to zero.
    init(_ components: [Double]) {
        switch components.count {
        case 0: self = .zero
        case 1: self.init(components[0], 0)
        case 2: self.init(components[0], components[1])
        default: self.init(components[0], components[1], components[2])
        }
    }

    static prefix func - (rhs: Vector) -> Vector {
        return Vector(-rhs.x, -rhs.y, -rhs.z)
    }

    static func + (lhs: Vector, rhs: Vector) -> Vector {
        return Vector(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }

    static func - (lhs: Vector, rhs: Vector) -> Vector {
        return Vector(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }

    static func * (lhs: Vector, rhs: Double) -> Vector {
        return Vector(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
    }

    static func / (lhs: Vector, rhs: Double) -> Vector {
        return Vector(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs)
    }

    var lengthSquared: Double {
        return dot(self)
    }

    var length: Double {
        return lengthSquared.squareRoot()
    }

    func dot(_ a: Vector) -> Double {
        return x * a.x + y * a.y + z * a.z
    }

    func cross(_ a: Vector) -> Vector {
        return Vector(
            y * a.z - z * a.y,
            z * a.x - x * a.z,
            x * a.y - y * a.x
        )
    }

    var isNormalized: Bool {
        return abs(lengthSquared - 1) < epsilon
    }

    func normalized() -> Vector {
        return self / length
    }

    /// Linearly interpolate between two vectors
    func lerp(_ a: Vector, _ t: Double) -> Vector {
        return self + (a - self) * t
    }

    func quantized() -> Vector {
        return Vector(quantize(x), quantize(y), quantize(z))
    }
}

internal extension Vector {
    // Approximate equality
    func isEqual(to other: Vector, withPrecision p: Double = epsilon) -> Bool {
        return abs(x - other.x) < p && abs(y - other.y) < p && abs(z - other.z) < p
    }
}
