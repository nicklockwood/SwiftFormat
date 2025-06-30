//
//  SinglePropertyPerLine.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 12/26/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Separate multiple property declarations on the same line into separate lines
    static let singlePropertyPerLine = FormatRule(
        help: "Place each property declaration on its own line.",
        disabledByDefault: true,
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEach(.delimiter(",")) { i, _ in
            guard let letOrVarIndex = formatter.index(of: .keyword, before: i, if: {
                ["let", "var"].contains($0.string)
            }),
            !formatter.isInClosureArguments(at: i),
            let identifierIndex = formatter.index(of: .nonSpaceOrComment, after: i),
            formatter.tokens[identifierIndex].isIdentifier
            else { return }

            // Replace comma with newline
            formatter.replaceToken(at: i, with: .linebreak(formatter.options.linebreak, 1))
            
            // Add indentation
            let indent = formatter.currentIndentForLine(at: letOrVarIndex)
            if !indent.isEmpty {
                formatter.insert(.space(indent), at: i + 1)
            }
            
            // Insert modifiers and keyword
            let startOfModifiers = formatter.startOfModifiers(at: letOrVarIndex, includingAttributes: true)
            let insertPoint = i + (indent.isEmpty ? 1 : 2)
            
            for j in startOfModifiers...letOrVarIndex {
                formatter.insert(formatter.tokens[j], at: insertPoint + (j - startOfModifiers))
            }
        }
    } examples: {
        """
        ```diff
        - let a: Int, b: Int
        + let a: Int
        + let b: Int
        ```

        ```diff
        - public var c = 10, d = false, e = "string"
        + public var c = 10
        + public var d = false
        + public var e = "string"
        ```

        ```diff
        - @objc var f = true, g: Bool
        + @objc var f = true
        + @objc var g: Bool
        ```
        """
    }
}
