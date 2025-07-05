//
//  Semicolons.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 8/24/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove semicolons, except where doing so would change the meaning of the code
    static let semicolons = FormatRule(
        help: "Remove semicolons.",
        options: ["semicolons"],
        sharedOptions: ["line-breaks"]
    ) { formatter in
        formatter.forEach(.delimiter(";")) { i, _ in
            if let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: i) {
                let prevTokenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i)
                let prevToken = prevTokenIndex.map { formatter.tokens[$0] }
                if prevToken == nil || nextToken == .endOfScope("}") {
                    // Safe to remove
                    formatter.removeToken(at: i)
                } else if prevToken == .keyword("return") || (
                    formatter.options.swiftVersion < "3" &&
                        // Might be a traditional for loop (not supported in Swift 3 and above)
                        formatter.currentScope(at: i) == .startOfScope("(")
                ) {
                    // Not safe to remove or replace
                } else if case .identifier? = prevToken, formatter.last(
                    .nonSpaceOrCommentOrLinebreak, before: prevTokenIndex!
                ) == .keyword("var") {
                    // Not safe to remove or replace
                } else if formatter.next(.nonSpaceOrComment, after: i)?.isLinebreak == true {
                    // Safe to remove
                    formatter.removeToken(at: i)
                } else if !formatter.options.allowInlineSemicolons {
                    // Replace with a linebreak
                    if formatter.token(at: i + 1)?.isSpace == true {
                        formatter.removeToken(at: i + 1)
                    }
                    formatter.insertSpace(formatter.currentIndentForLine(at: i), at: i + 1)
                    formatter.replaceToken(at: i, with: formatter.linebreakToken(for: i))
                }
            } else {
                // Safe to remove
                formatter.removeToken(at: i)
            }
        }
    } examples: {
        """
        ```diff
        - let foo = 5;
        + let foo = 5
        ```

        ```diff
        - let foo = 5; let bar = 6
        + let foo = 5
        + let bar = 6
        ```

        ```diff
          // semicolon is not removed if it would affect the behavior of the code
          return;
          goto(fail)
        ```
        """
    }
}
