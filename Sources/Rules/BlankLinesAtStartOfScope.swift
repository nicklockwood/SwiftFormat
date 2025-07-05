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
        options: ["type-blank-lines"]
    ) { formatter in
        formatter.forEach(.startOfScope) { i, token in
            guard ["{", "(", "[", "<", ":"].contains(token.string) else { return }

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

            guard let endOfScope = formatter.endOfScope(at: startOfScope),
                  formatter.index(of: .nonSpaceOrComment, after: startOfScope) != endOfScope
            else { return }

            let rangeInsideScope = ClosedRange(startOfScope + 1 ..< endOfScope)

            if formatter.isStartOfTypeBody(at: startOfScope) {
                switch formatter.options.typeBlankLines {
                case .insert:
                    formatter.addLeadingBlankLineIfNeeded(in: rangeInsideScope)
                case .remove:
                    formatter.removeLeadingBlankLinesIfPresent(in: rangeInsideScope)
                case .preserve:
                    break
                }
            } else {
                formatter.removeLeadingBlankLinesIfPresent(in: rangeInsideScope)
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

        With `--typeblanklines insert`:

        ```diff
          struct Foo {
        +
              let bar: Bar
          }
        ```
        """
    }
}
