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
        help: "Remove redundant backticks around identifiers."
    ) { formatter in
        let isSwiftTestingFile = formatter.hasImport("Testing")
        formatter.forEach(.identifier) { i, token in
            guard token.string.first == "`", !formatter.backticksRequired(at: i) else {
                return
            }
            // Don't remove backticks from Swift Testing @Test function names
            if isSwiftTestingFile,
               let prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i),
               formatter.tokens[prevIndex] == .keyword("func"),
               formatter.modifiersForDeclaration(at: prevIndex, contains: "@Test")
            {
                return
            }
            formatter.replaceToken(at: i, with: .identifier(token.unescaped()))
        }
    } examples: {
        """
        ```diff
        - let `infix` = bar
        + let infix = bar
        ```

        ```diff
        - func foo(with `default`: Int) {}
        + func foo(with default: Int) {}
        ```
        """
    }
}
