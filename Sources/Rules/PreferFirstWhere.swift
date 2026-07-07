//
//  PreferFirstWhere.swift
//  SwiftFormat
//
//  Created by Jon Parise on 6/25/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let preferFirstWhere = FormatRule(
        help: "Prefer `first(where:)` over `filter(_:).first`.",
        disabledByDefault: true
    ) { formatter in
        formatter.forEach(.identifier("filter")) { filterIndex, _ in
            // Parse the filter call arguments using the shared helper
            guard let args = formatter.parseFunctionCallArguments(after: filterIndex),
                  args.count == 1
            else { return }

            let closureArg = args[0]

            // Verify the single argument is a closure
            guard formatter.tokens[closureArg.valueRange.lowerBound] == .startOfScope("{"),
                  formatter.tokens[closureArg.valueRange.upperBound] == .endOfScope("}")
            else { return }

            // Determine whether the call uses trailing closure syntax or parenthesized syntax
            guard let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: filterIndex) else { return }
            let isTrailingClosure = formatter.tokens[nextIndex] == .startOfScope("{")

            // Determine the end of the filter call expression
            let endOfFilterCall: Int
            if isTrailingClosure {
                endOfFilterCall = closureArg.valueRange.upperBound
            } else {
                guard let closeParenIndex = formatter.endOfScope(at: nextIndex) else { return }
                endOfFilterCall = closeParenIndex
            }

            // Check if there's a `.first` property access after the filter call
            guard let dotIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: endOfFilterCall),
                  formatter.tokens[dotIndex] == .operator(".", .infix),
                  let firstIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: dotIndex),
                  formatter.tokens[firstIndex] == .identifier("first")
            else { return }

            // Ensure the `.first` is a property access, not a method call like `first(where:)`
            // or `first(3)`. Only the no-argument `.first` property is equivalent to `first(where:)`.
            // A following `{` that begins a control-flow body rather than a closure (e.g.
            // `if let x = xs.filter { ... }.first {`) does *not* disqualify it — there `.first` is
            // still a property access, so only bail on a `{` that actually starts a closure.
            if let tokenAfterFirst = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: firstIndex),
               formatter.tokens[tokenAfterFirst].isStartOfScope,
               formatter.tokens[tokenAfterFirst] != .startOfScope("{") || formatter.isStartOfClosure(at: tokenAfterFirst)
            {
                return
            }

            // Remove the `.first` property access, including any whitespace or line breaks between
            // the filter call and `.first` (so a multiline `.first` on its own line doesn't leave a
            // dangling blank line). Bail rather than silently delete a comment in that span.
            guard !formatter.tokens[(endOfFilterCall + 1) ... firstIndex].contains(where: \.isComment) else { return }
            formatter.removeTokens(in: (endOfFilterCall + 1) ... firstIndex)

            // Replace the `filter(_:)` call with `first(where:)`.
            // Since the `where` label provides semantic value,
            // convert to the non-trailing-closure form.

            let startOfClosure = closureArg.valueRange.lowerBound
            let endOfClosure = closureArg.valueRange.upperBound

            if isTrailingClosure {
                // Replace `filter { ... }` with `first(where: { ... })`.
                formatter.insert(.endOfScope(")"), at: endOfClosure + 1)

                formatter.insert(
                    [.startOfScope("("), .identifier("where"), .delimiter(":"), .space(" ")],
                    at: startOfClosure
                )

                if formatter.tokens[filterIndex + 1].isSpace {
                    formatter.removeToken(at: filterIndex + 1)
                }

                formatter.replaceToken(at: filterIndex, with: .identifier("first"))
            } else {
                // Replace `filter({ ... })` with `first(where: { ... })`.
                formatter.replaceToken(at: filterIndex, with: .identifier("first"))

                formatter.insert(
                    [.identifier("where"), .delimiter(":"), .space(" ")],
                    at: nextIndex + 1
                )
            }
        }
    } examples: {
        """
        ```diff
        - planets.filter { $0.hasMoons }.first
        + planets.first(where: { $0.hasMoons })

        - planets.filter({ $0.hasMoons }).first
        + planets.first(where: { $0.hasMoons })
        ```
        """
    }
}
