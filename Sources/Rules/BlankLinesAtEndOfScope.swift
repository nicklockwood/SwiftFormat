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
    static let blankLinesAtEndOfScope = FormatRule(
        help: "Remove trailing blank line at the end of a scope.",
        sharedOptions: ["typeblanklines"]
    ) { formatter in
        formatter.forEach(.startOfScope) { startOfScopeIndex, _ in
            guard let endOfScopeIndex = formatter.endOfScope(at: startOfScopeIndex) else { return }
            let endOfScope = formatter.tokens[endOfScopeIndex]

            guard ["}", ")", "]", ">"].contains(endOfScope.string),
                  // If there is extra code after the closing scope on the same line, ignore it
                  (formatter.next(.nonSpaceOrComment, after: endOfScopeIndex).map(\.isLinebreak)) ?? true
            else { return }

            // Consumers can choose whether or not this rule should apply to type bodies
            if !formatter.options.removeStartOrEndBlankLinesFromTypes,
               ["class", "actor", "struct", "enum", "protocol", "extension"].contains(
                   formatter.lastSignificantKeyword(at: startOfScopeIndex, excluding: ["where"]))
            {
                return
            }

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
            if formatter.options.removeBlankLines,
               let indexOfFirstLineBreak,
               indexOfFirstLineBreak != indexOfLastLineBreak
            {
                formatter.removeTokens(in: indexOfFirstLineBreak ..< indexOfLastLineBreak!)
                return
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
        """
    }
}
