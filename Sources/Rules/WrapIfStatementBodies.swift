//
//  WrapIfStatementBodies.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 6/10/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let wrapIfStatementBodies = FormatRule(
        help: "Wrap the bodies of inline if/else statements onto a new line.",
        sharedOptions: ["linebreaks", "indent"]
    ) { formatter in
        formatter.forEachToken(where: { [.keyword("if"), .keyword("else")].contains($0) }) { i, _ in
            // Skip if this `if` is being used as an expression
            if formatter.tokens[i] == .keyword("if"),
               formatter.isIfExpression(at: i)
            {
                return
            }

            // For `else`, check if it belongs to an if expression or a guard
            if formatter.tokens[i] == .keyword("else") {
                // If the `else` is not preceded by `}`, it must be a guard-else
                // (since if/else always has `} else`)
                if let prevNonSpace = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i),
                   formatter.tokens[prevNonSpace] != .endOfScope("}")
                {
                    return
                }

                // Check if this else belongs to an if expression via the preceding `}`
                if let closingBrace = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i),
                   formatter.tokens[closingBrace] == .endOfScope("}"),
                   let openingBrace = formatter.startOfScope(at: closingBrace),
                   let startOfStatement = formatter.startOfConditionalStatement(at: openingBrace)
                {
                    if formatter.tokens[startOfStatement] == .keyword("guard") {
                        return
                    }
                    if formatter.tokens[startOfStatement] == .keyword("if"),
                       formatter.isIfExpression(at: startOfStatement)
                    {
                        return
                    }
                }
            }

            // If this `if` immediately follows a `{` on the same line, wrap after
            // the `{` so the `if` starts on its own line.
            if formatter.tokens[i] == .keyword("if") {
                formatter.wrapIfFollowingOpeningBrace(at: i)
            }

            guard let startIndex = formatter.index(of: .startOfScope("{"), after: i) else {
                return formatter.fatalError("Expected {", at: i)
            }
            formatter.wrapStatementBody(at: startIndex)
        }
    } examples: {
        """
        ```diff
        - if foo { return bar }
        + if foo {
        +     return bar
        + }
        ```

        ```diff
        - if foo { return bar } else if baz { return qux } else { return quux }
        + if foo {
        +     return bar
        + } else if baz {
        +     return qux
        + } else {
        +     return quux
        + }
        ```
        """
    }
}

extension Formatter {
    /// If the token at index `i` is on the same line as a preceding `{`,
    /// inserts a linebreak after the `{` so the token starts on its own line.
    func wrapIfFollowingOpeningBrace(at i: Int) {
        // Check if we're on the same line as a preceding `{`
        let lineStart = startOfLine(at: i)
        guard let openBrace = lastIndex(of: .startOfScope("{"), in: lineStart ..< i) else {
            return
        }

        // There's content between the `{` and the `if` on the same line.
        // Insert a linebreak after the `{`.
        let insertionIndex = openBrace + 1
        // Remove any space between `{` and the `if`
        if tokens[insertionIndex].isSpace {
            removeToken(at: insertionIndex)
        }
        let indent = currentIndentForLine(at: openBrace) + options.indent
        insertLinebreak(at: insertionIndex)
        insertSpace(indent, at: insertionIndex + 1)
    }
}
