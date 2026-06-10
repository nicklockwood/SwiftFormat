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
        disabledByDefault: true,
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
                // Check via startOfConditionalStatement (works for guard else and simple if/else)
                if let startOfStatement = formatter.startOfConditionalStatement(at: i) {
                    if formatter.tokens[startOfStatement] == .keyword("guard") {
                        return
                    }
                    if formatter.tokens[startOfStatement] == .keyword("if"),
                       formatter.isIfExpression(at: startOfStatement)
                    {
                        return
                    }
                }

                // Also check via the preceding `}` for if/else-if chains where
                // startOfConditionalStatement may fail due to intervening braces
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

