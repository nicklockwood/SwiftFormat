//
//  PreferMinOverSorted.swift
//  SwiftFormat
//
//  Created by Jon Parise on 6/26/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let preferMinOverSorted = FormatRule(
        help: "Prefer `min()` over `sorted().first`."
    ) { formatter in
        formatter.forEach(.identifier("sorted")) { sortedIndex, _ in
            // Require a member call: something `.sorted(...)`.
            guard let dotBeforeSorted = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: sortedIndex),
                  formatter.tokens[dotBeforeSorted] == .operator(".", .infix),
                  let openParenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: sortedIndex),
                  formatter.tokens[openParenIndex] == .startOfScope("("),
                  let closeParenIndex = formatter.endOfScope(at: openParenIndex)
            else { return }

            // `sorted()` and `sorted(by:)` are the only forms equivalent to `min`.
            // `sorted()` → no arguments; `sorted(by:)` → a single `by:` argument that passes
            // through unchanged to `min(by:)`.
            let args = formatter.parseFunctionCallArguments(startOfScope: openParenIndex)
            switch args.count {
            case 0:
                break
            case 1 where args[0].label == "by":
                break
            default:
                return
            }

            // Require a trailing `.first` *property* access. Only `.first` is rewritten, not
            // `.last`: `sorted().first` always equals `min()` (both pick the first minimal element),
            // but `sorted().last` does NOT equal `max()` when elements tie under the comparator —
            // `sorted().last` is the last tied element while `max()` returns the first maximal one.
            guard let dotIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: closeParenIndex),
                  formatter.tokens[dotIndex] == .operator(".", .infix),
                  let accessorIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: dotIndex),
                  formatter.tokens[accessorIndex] == .identifier("first")
            else { return }

            // Ensure `.first` is a property access, not a method call (`.first(where:)`)
            // or a subscript (`.first[0]`).
            if let tokenAfterAccessor = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: accessorIndex),
               formatter.tokens[tokenAfterAccessor].isStartOfScope
            {
                return
            }

            // Bail rather than silently delete a comment in the `.first` suffix span
            // (between the `sorted(...)` close paren and the accessor).
            guard !formatter.tokens[(closeParenIndex + 1) ... accessorIndex].contains(where: \.isComment) else { return }

            // Remove the trailing `.first` (and any whitespace/linebreaks before it, so a chained
            // `.first` on its own line doesn't leave a dangling blank line).
            formatter.removeTokens(in: (closeParenIndex + 1) ... accessorIndex)

            // Rename `sorted` → `min`. The `(...)` argument list (empty or `by:`) is reused as-is:
            // `sorted(by: p).first` → `min(by: p)`, `sorted().first` → `min()`.
            formatter.replaceToken(at: sortedIndex, with: .identifier("min"))
        }
    } examples: {
        """
        ```diff
        - let smallest = values.sorted().first
        + let smallest = values.min()

        - let earliest = events.sorted(by: { $0.date < $1.date }).first
        + let earliest = events.min(by: { $0.date < $1.date })
        ```
        """
    }
}
