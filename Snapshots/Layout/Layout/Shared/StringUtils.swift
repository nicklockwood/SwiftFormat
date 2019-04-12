//  Copyright © 2017 Schibsted. All rights reserved.

import Foundation

// NOTE: these functions only apply capitalization to the Roman alphabet, which is deliberate
// because they are intended to be used with class and method names, not arbitrary strings

private let AToZ = "A".unicodeScalars.first!.value ... "Z".unicodeScalars.first!.value
private let aToZ = "a".unicodeScalars.first!.value ... "z".unicodeScalars.first!.value
private let aMinusA = "a".unicodeScalars.first!.value - "A".unicodeScalars.first!.value

extension Unicode.Scalar {
    var isUppercase: Bool { return AToZ.contains(value) }
    var isLowercase: Bool { return aToZ.contains(value) }

    func lowercased() -> Unicode.Scalar {
        return isUppercase ? UnicodeScalar(value + aMinusA)! : self
    }

    func uppercased() -> Unicode.Scalar {
        return isLowercase ? UnicodeScalar(value - aMinusA)! : self
    }
}

extension Character {
    var isUppercase: Bool { return unicodeScalars.first!.isUppercase }
    var isLowercase: Bool { return unicodeScalars.first!.isLowercase }

    func lowercased() -> Character {
        return unicodeScalars.count == 1 ? Character(unicodeScalars.first!.lowercased()) : self
    }

    func uppercased() -> Character {
        return unicodeScalars.count == 1 ? Character(unicodeScalars.first!.uppercased()) : self
    }
}

extension String {
    var isCapitalized: Bool {
        return unicodeScalars.first.map { $0.isUppercase } ?? false
    }

    func capitalized() -> String {
        let characters = unicodeScalars
        guard let first = characters.first, first.isLowercase else {
            return self
        }
        return String(Character(first.uppercased())) + String(characters.dropFirst())
    }

    func unCapitalized() -> String {
        let characters = unicodeScalars
        guard let first = characters.first, first.isUppercase else {
            return self
        }
        return String(Character(first.lowercased())) + String(characters.dropFirst())
    }
}
