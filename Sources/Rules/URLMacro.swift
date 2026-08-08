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
    static let urlMacro = FormatRule(
        help: "Replace force-unwrapped `URL(string:)` initializers with the configured `#URL(_:)` macro.",
        disabledByDefault: true,
        options: ["url-macro"]
    ) { formatter in
        // Only apply this rule if a URL macro is configured
        guard case let .macro(macroName, module: module) = formatter.options.urlMacro else {
            return
        }
        var didMakeChanges = false
        formatter.forEach(.identifier("URL")) { i, _ in
            // Match `URL(string: "...")` with a simple string literal
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
                  formatter.tokens[closeParenIndex] == .endOfScope(")")
            else { return }

            // Only convert simple string literals (no interpolation, concatenation, etc.)
            guard formatter.isSimpleStringLiteral(from: stringStartIndex, to: stringEndIndex) else { return }

            if let unwrapIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: closeParenIndex),
               formatter.tokens[unwrapIndex] == .operator("!", .postfix)
            {
                // Pattern: `URL(string: "...")!`
                formatter.removeToken(at: unwrapIndex)
                formatter.removeTokens(in: firstArgIndex ..< stringStartIndex)
                formatter.replaceToken(at: i, with: .keyword(macroName))
                didMakeChanges = true
            } else if formatter.isWrappedInTryRequire(urlIndex: i, openParenIndex: openParenIndex, closeParenIndex: closeParenIndex) {
                // Pattern: `try #require(URL(string: "..."))` → `#URL("...")`
                // Keep inner parens from URL(...), remove outer parens from #require(...)
                let (tryIndex, _, outerCloseParenIndex) = formatter.tryRequireIndices(around: i)!

                // Work back-to-front to keep earlier indices valid
                // 1. Remove outer `)` from #require(...)
                formatter.removeToken(at: outerCloseParenIndex)
                // 2. Remove `string: ` argument label (keep inner parens)
                formatter.removeTokens(in: firstArgIndex ..< stringStartIndex)
                // 3. Replace `URL` with macro name
                formatter.replaceToken(at: i, with: .keyword(macroName))
                // 4. Remove outer `(` from #require(...)
                let outerOpenParen = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i)!
                formatter.removeToken(at: outerOpenParen)
                // 5. Remove `#require`
                let requireIdx = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: outerOpenParen)!
                formatter.removeToken(at: requireIdx)
                // 6. Remove `try ` (keyword + trailing space)
                let currentTryIndex = tryIndex
                if currentTryIndex + 1 < formatter.tokens.count, formatter.tokens[currentTryIndex + 1] == .space(" ") {
                    formatter.removeToken(at: currentTryIndex + 1)
                }
                formatter.removeToken(at: currentTryIndex)
                didMakeChanges = true
            }
        }

        if didMakeChanges {
            formatter.addImports([module])
        }
    } examples: {
        """
        With `--url-macro "#URL,URLFoundation"`:

        ```diff
          import Foundation
        + import URLFoundation

        - let url = URL(string: "https://example.com")!
        + let url = #URL("https://example.com")
        ```

        ```diff
        - let url = try #require(URL(string: "https://example.com"))
        + let url = #URL("https://example.com")
        ```
        """
    }
}

extension Formatter {
    func isSimpleStringLiteral(from startIndex: Int, to endIndex: Int) -> Bool {
        for tokenIndex in (startIndex + 1) ..< endIndex {
            switch tokens[tokenIndex] {
            case .stringBody:
                continue
            default:
                return false
            }
        }
        return true
    }

    /// Check if `URL(string:)` at the given indices is wrapped in `try #require(...)`
    func isWrappedInTryRequire(urlIndex: Int, openParenIndex _: Int, closeParenIndex: Int) -> Bool {
        tryRequireIndices(around: urlIndex) != nil
            && index(of: .nonSpaceOrCommentOrLinebreak, after: closeParenIndex).map { tokens[$0] == .endOfScope(")") } == true
    }

    /// Returns `(tryIndex, requireIndex, outerCloseParenIndex)` if URL is wrapped in `try #require(URL(...))`
    func tryRequireIndices(around urlIndex: Int) -> (Int, Int, Int)? {
        // Look for `#require(` before URL
        guard let requireOpenParen = index(of: .nonSpaceOrCommentOrLinebreak, before: urlIndex),
              tokens[requireOpenParen] == .startOfScope("("),
              let requireIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: requireOpenParen),
              tokens[requireIndex] == .keyword("#require"),
              let tryIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: requireIndex),
              tokens[tryIndex] == .keyword("try")
        else { return nil }

        // Find the matching outer close paren
        guard let outerCloseParenIndex = endOfScope(at: requireOpenParen) else { return nil }

        return (tryIndex, requireIndex, outerCloseParenIndex)
    }
}
