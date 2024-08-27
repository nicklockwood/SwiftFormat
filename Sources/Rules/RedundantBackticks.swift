//
//  RedundantBackticks.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 3/7/17.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove redundant backticks around non-keywords, or in places where keywords don't need escaping
    static let redundantBackticks = FormatRule(
        help: "Remove redundant backticks around identifiers.",
        examples: """
        ```diff
        - let `infix` = bar
        + let infix = bar
        ```

        ```diff
        - func foo(with `default`: Int) {}
        + func foo(with default: Int) {}
        ```
        """
    ) { formatter in
        formatter.forEach(.identifier) { i, token in
            guard token.string.first == "`", !formatter.backticksRequired(at: i) else {
                return
            }
            formatter.replaceToken(at: i, with: .identifier(token.unescaped()))
        }
    }
}
