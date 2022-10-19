//
//  CoreText.swift
//  Euclid
//
//  Created by Nick Lockwood on 10/03/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

#if canImport(CoreText)

import CoreText
import Foundation

#if os(watchOS)

/// Workaround for missing constants on watchOS
extension NSAttributedString.Key {
    static let font = NSAttributedString.Key(rawValue: "NSFont")
}

#endif

public extension Path {
    /// Create an array of glyph contours from an attributed string
    static func text(
        _ attributedString: NSAttributedString,
        width: Double? = nil,
        detail: Int = 2
    ) -> [Path] {
        return cgPaths(for: attributedString, width: width).map {
            let cgPath = CGMutablePath()
            let transform = CGAffineTransform(translationX: $1.x, y: $1.y)
            cgPath.addPath($0, transform: transform)
            return Path(cgPath: cgPath, detail: detail)
        }
    }
}

public extension Mesh {
    /// Create an extruded text model from a String
    init(text: String,
         font: CTFont? = nil,
         width: Double? = nil,
         depth: Double = 1,
         detail: Int = 2,
         material: Polygon.Material = nil)
    {
        let font = font ?? CTFontCreateWithName("Helvetica" as CFString, 1, nil)
        let attributes = [NSAttributedString.Key.font: font]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        self.init(text: attributedString, width: width, depth: depth, detail: detail, material: material)
    }

    /// Create an extruded text model from an attributed string
    init(text: NSAttributedString,
         width: Double? = nil,
         depth: Double = 1,
         detail _: Int = 2,
         material: Polygon.Material = nil)
    {
        var meshes = [Mesh]()
        var cache = [CGPath: Mesh]()
        for (cgPath, cgPoint) in cgPaths(for: text, width: width) {
            let offset = Vector(cgPoint)
            guard let mesh = cache[cgPath] else {
                let path = Path(cgPath: cgPath)
                let mesh = Mesh.extrude(path, depth: depth, material: material)
                cache[cgPath] = mesh
                meshes.append(mesh.translated(by: offset))
                continue
            }
            meshes.append(mesh.translated(by: offset))
        }
        self.init(Mesh.union(meshes).polygons)
    }
}

/// Returns an array of path, position tuples for the glyphs in an attributed string
private func cgPaths(
    for attributedString: NSAttributedString,
    width: Double?
) -> [(glyph: CGPath, offset: CGPoint)] {
    let framesetter = CTFramesetterCreateWithAttributedString(attributedString as CFAttributedString)

    let range = CFRangeMake(0, 0)
    let maxSize = CGSize(width: width ?? .greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
    let size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, range, nil, maxSize, nil)
    let rectPath = CGPath(rect: CGRect(origin: .zero, size: size), transform: nil)
    let frame = CTFramesetterCreateFrame(framesetter, range, rectPath, nil)
    let lines = CTFrameGetLines(frame) as! [CTLine]

    var origins = Array(repeating: CGPoint.zero, count: lines.count)
    CTFrameGetLineOrigins(frame, range, &origins)

    var paths = [(CGPath, CGPoint)]()
    for (line, origin) in zip(lines, origins) {
        let runs = CTLineGetGlyphRuns(line) as! [CTRun]
        for run in runs {
            let attributes = CTRunGetAttributes(run) as! [NSAttributedString.Key: Any]
            let font = attributes[.font] as! CTFont

            var glyph = CGGlyph()
            for index in 0 ..< CTRunGetGlyphCount(run) {
                let range = CFRangeMake(index, 1)
                CTRunGetGlyphs(run, range, &glyph)
                guard let letter = CTFontCreatePathForGlyph(font, glyph, nil) else {
                    continue
                }

                var position = CGPoint.zero
                CTRunGetPositions(run, range, &position)
                position.x += origin.x
                position.y += origin.y - origins[0].y
                paths.append((letter, position))
            }
        }
    }
    return paths
}

#endif
