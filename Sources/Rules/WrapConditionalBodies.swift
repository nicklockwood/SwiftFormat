//
//  WrapConditionalBodies.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 11/6/21.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let wrapConditionalBodies = FormatRule(
        help: "Wrap the bodies of inline conditional statements onto a new line.",
        disabledByDefault: true,
        options: ["conditional-bodies"],
        sharedOptions: ["linebreaks", "indent"]
    ) { formatter in
        formatter.forEachToken(where: { [.keyword("if"), .keyword("else")].contains($0) }) { i, token in
            if token == .keyword("else"),
               formatter.options.wrapConditionalBodiesScope == .ifOnly,
               formatter.isGuardElse(at: i)
            {
                return
            }
            guard let startIndex = formatter.index(of: .startOfScope("{"), after: i) else {
                return formatter.fatalError("Expected {", at: i)
            }
            formatter.wrapStatementBody(at: startIndex)
        }
    } examples: {
        """
        ```diff
        - guard let foo = bar else { return baz }
        + guard let foo = bar else {
        +     return baz
        + }
        ```

        ```diff
        - if foo { return bar }
        + if foo {
        +    return bar
        + }
        ```

        With `--conditional-bodies if-only`, `guard` bodies are not wrapped:

        ```diff
        - if foo { return bar }
        + if foo {
        +    return bar
        + }

          // guard is not affected (both statement and expression)
          guard let foo = bar else { return baz }
        ```
        """
    }
}
