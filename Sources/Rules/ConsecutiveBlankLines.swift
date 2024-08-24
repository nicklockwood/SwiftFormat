//
//  ConsecutiveBlankLines.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Collapse all consecutive blank lines into a single blank line
    static let consecutiveBlankLines = FormatRule(
        help: "Replace consecutive blank lines with a single blank line.",
        examples: """
        ```diff
          func foo() {
            let x = "bar"
        -

            print(x)
          }

          func foo() {
            let x = "bar"

            print(x)
          }
        ```
        """
    ) { formatter in
        formatter.forEach(.linebreak) { i, _ in
            guard let prevIndex = formatter.index(of: .nonSpace, before: i, if: { $0.isLinebreak }) else {
                return
            }
            if let scope = formatter.currentScope(at: i), scope.isMultilineStringDelimiter {
                return
            }
            if let nextIndex = formatter.index(of: .nonSpace, after: i) {
                if formatter.tokens[nextIndex].isLinebreak {
                    formatter.removeTokens(in: i + 1 ... nextIndex)
                }
            } else if !formatter.options.fragment {
                formatter.removeTokens(in: i ..< formatter.tokens.count)
            }
        }
    }
}
