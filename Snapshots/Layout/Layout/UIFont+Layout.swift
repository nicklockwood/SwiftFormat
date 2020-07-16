//  Copyright © 2017 Schibsted. All rights reserved.

import UIKit

private var fontWeights = [String: UIFont.Weight]()
private let weightsBySuffix: [(String, UIFont.Weight)] = [
    ("normal", .regular),
    ("ultralight", .ultraLight),
    ("thin", .thin),
    ("light", .light),
    ("regular", .regular),
    ("medium", .medium),
    ("semibold", .semibold),
    ("demibold", .semibold),
    ("extrabold", .heavy),
    ("ultrabold", .heavy),
    ("bold", .bold),
    ("heavy", .heavy),
    ("black", .black),
]

extension UIFont {
    // This is the actual default font size on iOS
    // which is not the same as reported by `UIFont.systemFontSize`
    static let defaultSize: CGFloat = 17

    struct RelativeSize {
        let factor: CGFloat
    }

    var fontWeight: UIFont.Weight {
        assert(Thread.isMainThread)
        // Check cache
        if let weight = fontWeights[fontName] {
            return weight
        }
        // Do string-based match first, as this is more reliable
        let name = fontName.lowercased()
        for (suffix, weight) in weightsBySuffix {
            if name.contains(suffix) {
                fontWeights[fontName] = weight
                return weight
            }
        }
        // Use the weight attribute as a fallback, but this is not very reliable for 3rd party fonts
        guard let traits = fontDescriptor.object(forKey: UIFontDescriptor.AttributeName.traits) as? [UIFontDescriptor.TraitKey: Any],
            let weight = traits[UIFontDescriptor.TraitKey.weight] as? UIFont.Weight else {
            fontWeights[fontName] = .regular
            return UIFont.Weight.regular
        }
        fontWeights[fontName] = weight
        return weight
    }

    static func font(with parts: [Any]) throws -> UIFont {
        var font: UIFont!
        var fontSize: CGFloat!
        var traits = UIFontDescriptor.SymbolicTraits()
        var fontWeight: UIFont.Weight?
        for part in parts {
            switch part {
            case let part as UIFont:
                font = part
            case let trait as UIFontDescriptor.SymbolicTraits:
                traits.insert(trait)
            case let weight as UIFont.Weight:
                fontWeight = weight
            case let size as NSNumber:
                fontSize = CGFloat(truncating: size)
            case let size as UIFont.RelativeSize:
                fontSize = (fontSize ?? font?.pointSize ?? defaultSize) * size.factor
            case let style as UIFont.TextStyle:
                let preferredFont = UIFont.preferredFont(forTextStyle: style)
                fontSize = preferredFont.pointSize
                font = font ?? preferredFont
            default:
                throw Expression.Error.message("Invalid font specifier '\(part)'")
            }
        }
        return self.font(font, withSize: fontSize, weight: fontWeight, traits: traits)
    }

    static func font(
        _ font: UIFont?,
        withSize fontSize: CGFloat?,
        weight: UIFont.Weight?,
        traits: UIFontDescriptor.SymbolicTraits
    ) -> UIFont {
        let fontSize = fontSize ?? font?.pointSize ?? defaultSize
        let font = font ?? {
            if traits.contains(.traitMonoSpace), let font = UIFont(name: "Courier", size: fontSize) {
                return font
            }
            if traits.contains(.traitBold) {
                return boldSystemFont(ofSize: fontSize)
            }
            return systemFont(ofSize: fontSize, weight: weight ?? .regular)
        }()
        let weight = weight ?? font.fontWeight
        let fontNames = UIFont.fontNames(forFamilyName: font.familyName)
        if fontNames.isEmpty {
            let fontTraits = font.fontDescriptor.symbolicTraits.union(traits)
            if let descriptor = font.fontDescriptor.withSymbolicTraits(fontTraits) {
                return UIFont(descriptor: descriptor, size: fontSize)
            }
        }
        var bestMatch = UIFont(descriptor: font.fontDescriptor, size: fontSize)
        var bestMatchQuality = -Double.infinity
        for name in fontNames {
            let font = UIFont(name: name, size: fontSize)!
            let fontTraits = font.fontDescriptor.symbolicTraits
            var matchQuality = 0.0
            for trait in [
                // NOTE: traitBold is handled using weight argument
                .traitCondensed,
                .traitExpanded,
                .traitItalic,
                .traitMonoSpace,
            ] as [UIFontDescriptor.SymbolicTraits] {
                if traits.contains(trait) {
                    if fontTraits.contains(trait) {
                        matchQuality += 1
                    }
                } else if fontTraits.contains(trait) {
                    matchQuality -= 0.1
                }
            }
            matchQuality -= abs(Double(truncating: font.fontWeight as NSNumber) - Double(truncating: weight as NSNumber))
            if matchQuality > bestMatchQuality {
                bestMatchQuality = matchQuality
                bestMatch = font
            }
        }
        return bestMatch
    }
}
