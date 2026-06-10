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
        options: ["wrap-if-body", "wrap-guard-body"],
        sharedOptions: ["linebreaks", "indent"]
    ) { formatter in
        formatter.forEachToken(where: { [.keyword("if"), .keyword("else")].contains($0) }) { i, token in
            let isGuardElse = token == .keyword("else") && formatter.isGuardElse(at: i)
            if isGuardElse {
                guard formatter.options.wrapGuardBody else { return }
            } else {
                guard formatter.options.wrapIfBody else { return }
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

        With `--wrap-guard-body false`, `guard` bodies are not wrapped:

        ```diff
        - if foo { return bar }
        + if foo {
        +    return bar
        + }

          // guard is not affected
          guard let foo = bar else { return baz }
        ```
        """
    }
}
