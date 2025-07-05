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
        options: ["type-blank-lines"],
        sharedOptions: ["type-blank-lines"]
    ) { formatter in
        formatter.forEach(.startOfScope) { startOfScope, token in
            guard ["{", "(", "[", "<"].contains(token.string) else { return }

            guard let endOfScope = formatter.endOfScope(at: startOfScope),
                  formatter.index(of: .nonSpaceOrComment, after: startOfScope) != endOfScope
            else { return }

            // If there is extra code after the closing scope on the same line, ignore it
            if let nextTokenAfterClosingScope = formatter.next(.nonSpaceOrComment, after: endOfScope),
               !nextTokenAfterClosingScope.isLinebreak
            {
                return
            }

            let rangeInsideScope = ClosedRange(startOfScope + 1 ..< endOfScope)

            if formatter.isStartOfTypeBody(at: startOfScope) {
                switch formatter.options.typeBlankLines {
                case .insert:
                    formatter.addTrailingBlankLineIfNeeded(in: rangeInsideScope)
                case .remove:
                    formatter.removeTrailingBlankLinesIfPresent(in: rangeInsideScope)
                case .preserve:
                    break
                }
            } else {
                formatter.removeTrailingBlankLinesIfPresent(in: rangeInsideScope)
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

        With `--typeblanklines insert`:

        ```diff
          struct Foo {
              let bar: Bar
        +
          }
        ```
        """
    }
}
