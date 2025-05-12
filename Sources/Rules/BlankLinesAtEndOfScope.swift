//
//  BlankLinesAtEndOfScope.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 8/30/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove blank lines immediately before a closing brace, bracket, paren or chevron
    /// unless it's followed by more code on the same line (e.g. } else { )
    /// Also insert blank lines before closing braces for type declarations if configured
    static let blankLinesAtEndOfScope = FormatRule(
        help: "Remove or insert trailing blank line at the end of a scope.",
        options: ["typeblanklines"],
        sharedOptions: ["typeblanklines"]
    ) { formatter in
        // First pass: Find all non-type scopes or type scopes that need blank lines removed
        formatter.forEach(.startOfScope) { startOfScopeIndex, _ in
            guard let endOfScopeIndex = formatter.endOfScope(at: startOfScopeIndex) else { return }
            let endOfScope = formatter.tokens[endOfScopeIndex]

            guard ["}", ")", "]", ">"].contains(endOfScope.string) else { return }

            // If there is extra code after the closing scope on the same line, ignore it
            if let nextToken = formatter.next(.nonSpaceOrComment, after: endOfScopeIndex), !nextToken.isLinebreak {
                return
            }

            // Check if this is a type declaration
            let isTypeDeclaration = formatter.isTypeDeclaration(at: startOfScopeIndex)

            // Find previous non-space token
            var index = endOfScopeIndex - 1
            var indexOfFirstLineBreak: Int?
            var indexOfLastLineBreak: Int?
            loop: while let token = formatter.token(at: index) {
                switch token {
                case .linebreak:
                    indexOfFirstLineBreak = index
                    if indexOfLastLineBreak == nil {
                        indexOfLastLineBreak = index
                    }
                case .space:
                    break
                default:
                    break loop
                }
                index -= 1
            }

            // For types, check the typeBlankLines option
            if isTypeDeclaration {
                switch formatter.options.typeBlankLines {
                case .remove:
                    // Remove blank lines before closing brace in types
                    if let indexOfFirstLineBreak,
                       indexOfFirstLineBreak != indexOfLastLineBreak
                    {
                        formatter.removeTokens(in: indexOfFirstLineBreak ..< indexOfLastLineBreak!)
                    }
                case .preserve:
                    // Do nothing - preserve existing blank lines
                    break
                case .insert:
                    // For insert, we'll handle in a separate pass
                    break
                }
            } else {
                // For non-types, always remove blank lines
                if let indexOfFirstLineBreak,
                   indexOfFirstLineBreak != indexOfLastLineBreak
                {
                    formatter.removeTokens(in: indexOfFirstLineBreak ..< indexOfLastLineBreak!)
                }
            }
        }

        // Second pass: Handle typeBlankLines = .insert for type declarations
        if formatter.options.typeBlankLines == .insert {
            formatter.forEach(.startOfScope("{")) { startOfScopeIndex, _ in
                // Only process type declarations
                guard formatter.isTypeDeclaration(at: startOfScopeIndex),
                      let endOfScopeIndex = formatter.endOfScope(at: startOfScopeIndex) else { return }

                // Find last non-whitespace token before the closing brace
                guard let lastContentIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: endOfScopeIndex) else { return }

                // Count linebreaks between last content and closing brace
                var linebreakCount = 0
                var hasWhitespaceAfterLastLinebreak = false

                // Iterate through tokens between last content and closing brace
                for i in (lastContentIndex + 1) ..< endOfScopeIndex {
                    let token = formatter.tokens[i]
                    if token.isLinebreak {
                        linebreakCount += 1
                        hasWhitespaceAfterLastLinebreak = false
                    } else if token.isSpace {
                        hasWhitespaceAfterLastLinebreak = true
                    }
                }

                // We want exactly one blank line, which means 2 linebreaks
                // If we don't have exactly 2 linebreaks, or if there's no whitespace after the last linebreak,
                // we need to modify the tokens
                if linebreakCount != 2 || !hasWhitespaceAfterLastLinebreak {
                    // Remove existing whitespace and linebreaks
                    formatter.removeTokens(in: (lastContentIndex + 1) ..< endOfScopeIndex)

                    // Insert first linebreak
                    formatter.insertLinebreak(at: lastContentIndex + 1)

                    // Insert second linebreak (creates the blank line)
                    formatter.insertLinebreak(at: lastContentIndex + 2)

                    // Don't add indentation - the closing brace should be at the same level as the opening brace
                }
            }
        }
    } examples: {
        """
        ```diff
          func foo() {
            // foo
        -
          }

          func foo() {
            // foo
          }
        ```

        ```diff
          array = [
            foo,
            bar,
            baz,
        -
          ]

          array = [
            foo,
            bar,
            baz,
          ]
        ```

        With --typeblanklines insert:

        ```diff
          class MyClass {
              // Implementation
        -     }
        +
        +     }
        ```
        """
    }
}

private extension Formatter {
    func isTypeDeclaration(at scopeIndex: Int) -> Bool {
        guard let lastKeyword = lastSignificantKeyword(at: scopeIndex, excluding: ["where"]) else {
            return false
        }

        return ["class", "actor", "struct", "enum", "protocol", "extension"].contains(lastKeyword)
    }
}
