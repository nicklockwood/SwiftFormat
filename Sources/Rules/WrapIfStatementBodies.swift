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
            // the `{` so the `if` starts on its own line. Only do this when we're
            // actually going to wrap the body (i.e. not inside a single-line string).
            if formatter.tokens[i] == .keyword("if") {
                if let bodyBrace = formatter.index(of: .startOfScope("{"), after: i),
                   !formatter.isInStringLiteralWithWrappingDisabled(at: bodyBrace)
                {
                    formatter.wrapIfFollowingOpeningBrace(at: i)
                }
            }

            // Re-find the body brace after any token insertions from wrapIfFollowingOpeningBrace
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

