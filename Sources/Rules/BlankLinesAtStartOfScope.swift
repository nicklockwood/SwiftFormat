//
//  BlankLinesAtStartOfScope.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 2/1/18.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove blank lines immediately after an opening brace, bracket, paren, chevron, or colon
    /// that starts a new scope.
    static let blankLinesAtStartOfScope = FormatRule(
        help: "Remove leading blank line at the start of a scope.",
        options: ["typeblanklines"]
    ) { formatter in
        formatter.forEach(.startOfScope) { i, token in
            guard ["{", "(", "[", "<", ":"].contains(token.string) else { return }

            // Consumers can choose whether or not this rule should apply to type bodies
            if !formatter.options.removeStartOrEndBlankLinesFromTypes,
               ["class", "actor", "struct", "enum", "protocol", "extension"].contains(
                   formatter.lastSignificantKeyword(at: i, excluding: ["where"]))
            {
                return
            }

            // If this is a closure with captures or params, skip to the `in` keyword
            // before we look for a blank line at the start of the scope.
            var startOfScope = i
            if formatter.isStartOfClosure(at: startOfScope),
               let endOfScope = formatter.endOfScope(at: startOfScope),
               startOfScope + 1 < endOfScope,
               let inKeywordIndex = formatter.index(of: .keyword("in"), in: startOfScope + 1 ..< endOfScope),
               formatter.startOfScope(at: inKeywordIndex) == startOfScope
            {
                startOfScope = inKeywordIndex
            }

            guard let indexOfFirstLineBreak = formatter.index(of: .nonSpaceOrComment, after: startOfScope),
                  // If there is extra code on the same line, ignore it
                  formatter.tokens[indexOfFirstLineBreak].isLinebreak
            else { return }

            // Find next non-space token
            var index = indexOfFirstLineBreak + 1
            var indexOfLastLineBreak = indexOfFirstLineBreak
            loop: while let token = formatter.token(at: index) {
                switch token {
                case .linebreak:
                    indexOfLastLineBreak = index
                case .space:
                    break
                default:
                    break loop
                }
                index += 1
            }
            if formatter.options.removeBlankLines, indexOfFirstLineBreak != indexOfLastLineBreak {
                formatter.removeTokens(in: indexOfFirstLineBreak ..< indexOfLastLineBreak)
                return
            }
        }
    } examples: {
        """
        ```diff
          func foo() {
        -
            // foo
          }

          func foo() {
            // foo
          }
        ```

        ```diff
          array = [
        -
            foo,
            bar,
            baz,
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
