//
//  URLMacro.swift
//  SwiftFormat
//
//  Created by Manuel Lopez on 6/17/25.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Convert force-unwrapped URL initializers to use the #URL(...) macro
    static let uRLMacro = FormatRule(
        help: "Replace force-unwrapped URL initializers with the #URL(...) macro for compile-time validation."
    ) { formatter in
        // First collect all indices to process
        var indicesToProcess: [(Int, Int, Int, Int)] = [] // (i, firstArgIndex, stringStartIndex, unwrapIndex)

        formatter.forEach(.identifier("URL")) { i, _ in
            // Look for `URL(string: "...")!` pattern
            guard let openParenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i),
                  formatter.tokens[openParenIndex] == .startOfScope("("),
                  let firstArgIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: openParenIndex),
                  formatter.tokens[firstArgIndex] == .identifier("string"),
                  let colonIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: firstArgIndex),
                  formatter.tokens[colonIndex] == .delimiter(":"),
                  let stringStartIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: colonIndex),
                  formatter.tokens[stringStartIndex] == .startOfScope("\""),
                  let stringEndIndex = formatter.index(of: .endOfScope("\""), after: stringStartIndex),
                  let closeParenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: stringEndIndex),
                  formatter.tokens[closeParenIndex] == .endOfScope(")"),
                  let unwrapIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: closeParenIndex),
                  formatter.tokens[unwrapIndex] == .operator("!", .postfix)
            else { return }

            indicesToProcess.append((i, firstArgIndex, stringStartIndex, unwrapIndex))
        }

        // Process changes in reverse order to avoid index shifts
        for (i, firstArgIndex, stringStartIndex, unwrapIndex) in indicesToProcess.reversed() {
            // Remove the unwrap operator first (working backwards to avoid index shifts)
            formatter.removeToken(at: unwrapIndex)

            // Remove "string: " argument
            formatter.removeTokens(in: firstArgIndex ..< stringStartIndex)

            // Insert "#" before "URL"
            formatter.insert(.operator("#", .prefix), at: i)
        }

        // Add URLFoundation import if any modifications were made
        if !indicesToProcess.isEmpty {
            formatter.addImports(["URLFoundation"])
        }
    } examples: {
        """
        ```diff
        - let url = URL(string: "https://example.com")!
        + import URLFoundation
        + let url = #URL("https://example.com")
        ```

        ```diff
        - return URL(string: "https://api.example.com/users")!
        + import URLFoundation
        + return #URL("https://api.example.com/users")
        ```
        """
    }
}
