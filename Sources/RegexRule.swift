//
//  RegexRule.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 18/11/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import Foundation

final class RegexRule: RawRepresentable {
    let rawValue: String
    let name: String
    private let regex: NSRegularExpression
    private let replacement: String

    init(pattern: String) throws {
        let parts = pattern.components(separatedBy: "/")
        guard parts.count == 4 else {
            throw FormatError.options("Expected format [name]/pattern/replacement/")
        }
        guard !parts[1].isEmpty else {
            throw FormatError.options("Pattern cannot be empty")
        }
        guard parts[3].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FormatError.options("Unexpected token '\(parts[3])' after final slash")
        }
        rawValue = pattern
        let name = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
        self.name = name.isEmpty ? "regexReplace" : name
        do {
            regex = try NSRegularExpression(pattern: parts[1], options: [
                .anchorsMatchLines,
                .dotMatchesLineSeparators,
            ])
        } catch {
            throw FormatError.options("Pattern error: \(error.localizedDescription)")
        }
        replacement = parts[2]
    }

    convenience init?(rawValue: String) {
        try? self.init(pattern: rawValue)
    }

    func apply(to input: String) -> String {
        regex.stringByReplacingMatches(
            in: input,
            options: [],
            range: NSRange(location: 0, length: input.utf16.count),
            withTemplate: replacement
        )
    }
}
