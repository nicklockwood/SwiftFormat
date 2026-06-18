//
//  WrapGuardStatementBodies.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 6/10/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let wrapGuardStatementBodies = FormatRule(
        help: "Wrap the bodies of guard statements onto a new line.",
        disabledByDefault: true,
        sharedOptions: ["linebreaks", "indent"]
    ) { formatter in
        formatter.forEachToken(where: { $0 == .keyword("guard") }) { i, _ in
            // Find the `else` keyword for this guard statement.
            // The scope-aware index(of:after:) skips over any closures in the condition.
            guard let elseIndex = formatter.index(of: .keyword("else"), after: i),
                  let startIndex = formatter.index(of: .startOfScope("{"), after: elseIndex)
            else {
                return
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
        """
    }
}
