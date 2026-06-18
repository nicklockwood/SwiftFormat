//
//  WrapIfExpressionBodies.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 6/10/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let wrapIfExpressionBodies = FormatRule(
        help: "Wrap the bodies of if expressions onto a new line.",
        sharedOptions: ["linebreaks", "indent"]
    ) { formatter in
        formatter.forEachToken(where: { [.keyword("if"), .keyword("else")].contains($0) }) { i, _ in
            // Only handle if expressions
            if formatter.tokens[i] == .keyword("if") {
                guard formatter.isIfExpression(at: i) else { return }
            }

            // For `else`, check if the parent if is an expression
            if formatter.tokens[i] == .keyword("else") {
                // Check if `else if` - look at the next token
                if let nextNonSpace = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i),
                   formatter.tokens[nextNonSpace] == .keyword("if")
                {
                    guard formatter.isIfExpression(at: nextNonSpace) else { return }
                } else {
                    // Plain `else` - find the parent if via the preceding `}`
                    var foundIfExpression = false
                    if let closingBrace = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i),
                       formatter.tokens[closingBrace] == .endOfScope("}"),
                       let openingBrace = formatter.startOfScope(at: closingBrace),
                       let startOfStatement = formatter.startOfConditionalStatement(at: openingBrace),
                       formatter.tokens[startOfStatement] == .keyword("if"),
                       formatter.isIfExpression(at: startOfStatement)
                    {
                        foundIfExpression = true
                    }
                    guard foundIfExpression else { return }
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
        - let foo = if condition { bar } else { baz }
        + let foo = if condition {
        +     bar
        + } else {
        +     baz
        + }
        ```
        """
    }
}
