//
//  MultilineStrings.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/26/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Convert single-line strings containing escaped newlines to multi-line strings
    static let multilineStrings = FormatRule(
        help: "Convert single-line strings containing escaped newlines to multi-line strings.",
        options: []
    ) { formatter in
        formatter.forEach(.startOfScope("\"")) { startIndex, _ in
            guard let endIndex = formatter.endOfScope(at: startIndex) else {
                return
            }

            let stringBodyRange = (startIndex + 1) ..< endIndex
            let stringContent = formatter.tokens[stringBodyRange].string

            guard stringContent.contains("\\n") else { return }

            let unescapedContent = stringContent
                .replacingOccurrences(of: "\\n", with: "\n")
                .replacingOccurrences(of: "\\r", with: "\r")
                .replacingOccurrences(of: "\\t", with: "\t")
                .replacingOccurrences(of: "\\0", with: "\0")
                .replacingOccurrences(of: "\\", with: "")

            // Skip strings that contain only whitespace characters and escape sequences
            guard !unescapedContent.allSatisfy({ $0.isWhitespace || $0.isNewline }) else { return }

            // Get the current line's indentation
            let currentIndent = formatter.currentIndentForLine(at: startIndex)

            // Convert escaped newlines to actual newlines
            let convertedContent = stringContent.replacingOccurrences(of: "\\n", with: "\n\(currentIndent)")

            // Replace with multi-line string tokens
            let newTokens: [Token] = [
                .startOfScope("\"\"\""),
                .linebreak("\n", 0),
                .space(currentIndent),
                .stringBody(convertedContent),
                .linebreak("\n", 0),
                .space(currentIndent),
                .endOfScope("\"\"\""),
            ]

            formatter.replaceTokens(in: startIndex ... endIndex, with: newTokens)
        }
    } examples: {
        """
        ```diff
        - let message = "Hello\\nWorld"
        + let message = \"\"\"
        + Hello
        + World
        + \"\"\"
        ```
        """
    }
}
