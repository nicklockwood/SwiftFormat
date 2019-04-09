//
//  Bounds.swift
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

/// An axially-aligned bounding box
public struct Bounds: Hashable {
    public let min, max: Vector

    public init(min: Vector, max: Vector) {
        self.min = min
        self.max = max
    }
}

public extension Bounds {
    static let empty = Bounds()

    init(points: [Vector] = []) {
        var min = Vector(.infinity, .infinity, .infinity)
        var max = Vector(-.infinity, -.infinity, -.infinity)
        for p in points {
            min = Euclid.min(min, p)
            max = Euclid.max(max, p)
        }
        self.min = min
        self.max = max
    }

    init(bounds: [Bounds]) {
        var min = Vector(.infinity, .infinity, .infinity)
        var max = Vector(-.infinity, -.infinity, -.infinity)
        for b in bounds {
            min = Euclid.min(min, b.min)
            max = Euclid.max(max, b.max)
        }
        self.min = min
        self.max = max
    }

    var isEmpty: Bool {
        return max.x < min.x || max.y < min.y || max.z < min.z
    }

    var size: Vector {
        return isEmpty ? .zero : max - min
    }

    var center: Vector {
        return isEmpty ? .zero : min + size / 2
    }

    var corners: [Vector] {
        return [
            min,
            Vector(min.x, max.y, min.z),
            Vector(max.x, max.y, min.z),
            Vector(max.x, min.y, min.z),
            Vector(min.x, min.y, max.z),
            Vector(min.x, max.y, max.z),
            max,
            Vector(max.x, min.y, max.z),
        ]
    }

    func union(_ other: Bounds) -> Bounds {
        return Bounds(
            min: Euclid.min(min, other.min),
            max: Euclid.max(max, other.max)
        )
    }

    func intersection(_ other: Bounds) -> Bounds {
        return Bounds(
            min: Euclid.max(min, other.min),
            max: Euclid.min(max, other.max)
        )
    }

    func intersects(_ other: Bounds) -> Bool {
        return !(
            other.max.x < min.x || other.min.x > max.x ||
                other.max.y < min.y || other.min.y > max.y ||
                other.max.z < min.z || other.min.z > max.z
        )
    }

    func containsPoint(_ p: Vector) -> Bool {
        return p.x >= min.x && p.x <= max.x &&
            p.y >= min.y && p.y <= max.y &&
            p.z >= min.z && p.z <= max.z
    }
}

private func min(_ lhs: Vector, _ rhs: Vector) -> Vector {
    return Vector(min(lhs.x, rhs.x), min(lhs.y, rhs.y), min(lhs.z, rhs.z))
}

private func max(_ lhs: Vector, _ rhs: Vector) -> Vector {
    return Vector(max(lhs.x, rhs.x), max(lhs.y, rhs.y), max(lhs.z, rhs.z))
}
