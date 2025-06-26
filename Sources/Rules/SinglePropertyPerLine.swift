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
        // Simple approach: find each comma in a property declaration and replace it with a newline + declaration
        var commaIndices: [Int] = []

        // First pass: collect all comma indices that need to be processed
        formatter.forEachToken { index, token in
            guard case .delimiter(",") = token else { return }

            // Check if this comma is in a property declaration
            guard let introducerIndex = formatter.index(of: .keyword, before: index, if: {
                ["let", "var"].contains($0.string)
            }),
                // Check that we're not inside nested structures like function calls or arrays
                formatter.currentScope(at: index) == nil || formatter.currentScope(at: index) == .startOfScope("{"),
                // Check there's an identifier after the comma
                let nextNonSpaceIndex = formatter.index(of: .nonSpaceOrComment, after: index),
                formatter.token(at: nextNonSpaceIndex)?.isIdentifier == true,
                // Make sure this isn't inside a function call, array, or other nested structure
                !formatter.isInClosureArguments(at: index)
            else { return }

            // Make sure we're at the top level by checking depth
            let startOfLine = formatter.startOfLine(at: introducerIndex)
            var depth = 0
            for i in startOfLine ..< index {
                guard let token = formatter.token(at: i) else { continue }
                switch token {
                case .startOfScope("("), .startOfScope("["):
                    depth += 1
                case .endOfScope(")"), .endOfScope("]"):
                    depth -= 1
                default:
                    break
                }
            }

            guard depth == 0 else { return }

            commaIndices.append(index)
        }

        // Second pass: process commas from right to left to avoid index shifts
        for commaIndex in commaIndices.reversed() {
            guard let introducerIndex = formatter.index(of: .keyword, before: commaIndex, if: {
                ["let", "var"].contains($0.string)
            }),
                let nextNonSpaceIndex = formatter.index(of: .nonSpaceOrComment, after: commaIndex)
            else { continue }

            // Find the end of this property (before the next comma or end of line)
            let endOfLine = formatter.endOfLine(at: commaIndex)
            var endIndex = nextNonSpaceIndex
            while endIndex < endOfLine {
                if let nextToken = formatter.token(at: endIndex + 1) {
                    switch nextToken {
                    case .delimiter(","), .linebreak, .delimiter(";"), .startOfScope("{"):
                        break
                    default:
                        endIndex += 1
                        continue
                    }
                }
                break
            }

            // Get modifiers and the introducer
            let startOfModifiers = formatter.startOfModifiers(at: introducerIndex, includingAttributes: true)
            let introducerToken = formatter.tokens[introducerIndex]

            // Build replacement tokens
            var newTokens: [Token] = []
            newTokens.append(.linebreak(formatter.options.linebreak, 1))

            let currentIndent = formatter.currentIndentForLine(at: introducerIndex)
            if !currentIndent.isEmpty {
                newTokens.append(.space(currentIndent))
            }

            // Add all tokens from start of modifiers to the introducer keyword (including spaces)
            if startOfModifiers < introducerIndex {
                let declarationPrefixTokens = Array(formatter.tokens[startOfModifiers ... introducerIndex])
                newTokens.append(contentsOf: declarationPrefixTokens)
            } else {
                newTokens.append(introducerToken)
            }

            newTokens.append(.space(" "))

            // Add the property part after the comma
            let propertyTokens = Array(formatter.tokens[nextNonSpaceIndex ... endIndex])
            newTokens.append(contentsOf: propertyTokens)

            // Replace the comma and following tokens
            formatter.replaceTokens(in: commaIndex ... endIndex, with: newTokens)
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
