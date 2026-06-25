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
        help: "Prefer `first(where:)` over `filter(_:).first`."
    ) { formatter in
        formatter.forEach(.identifier("filter")) { filterIndex, _ in
            guard let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: filterIndex) else { return }

            // Parse the `filter` call, which takes exactly one closure
            // and is either `filter { ... }` or `filter({ ... })`
            let openParen: Int?
            let startOfClosure: Int
            let endOfClosure: Int
            let closeParen: Int?

            if formatter.tokens[nextIndex] == .startOfScope("("),
               let startOfClosureIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: nextIndex),
               formatter.tokens[startOfClosureIndex] == .startOfScope("{"),
               let endOfClosureIndex = formatter.endOfScope(at: startOfClosureIndex),
               let tokenAfterClosure = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: endOfClosureIndex),
               formatter.tokens[tokenAfterClosure] == .endOfScope(")")
            {
                openParen = nextIndex
                startOfClosure = startOfClosureIndex
                endOfClosure = endOfClosureIndex
                closeParen = tokenAfterClosure
            }

            else if formatter.tokens[nextIndex] == .startOfScope("{"),
                    let endOfClosureIndex = formatter.endOfScope(at: nextIndex)
            {
                openParen = nil
                startOfClosure = nextIndex
                endOfClosure = endOfClosureIndex
                closeParen = nil
            }

            else {
                return
            }

            // Check if there's a `.first` property access after the filter call
            guard let dotIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: closeParen ?? endOfClosure),
                  formatter.tokens[dotIndex] == .operator(".", .infix),
                  let firstIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: dotIndex),
                  formatter.tokens[firstIndex] == .identifier("first")
            else { return }

            // Ensure the `.first` is a property access, not a method call like `first(where:)`
            // or `first(3)`. Only the no-argument `.first` property is equivalent to `first(where:)`.
            if let tokenAfterFirst = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: firstIndex),
               formatter.tokens[tokenAfterFirst].isStartOfScope
            {
                return
            }

            // Remove the `.first` property access, including any whitespace or line breaks between
            // the filter call and `.first` (so a multiline `.first` on its own line doesn't leave a
            // dangling blank line). Bail rather than silently delete a comment in that span.
            let endOfFilterCall = closeParen ?? endOfClosure
            guard !formatter.tokens[(endOfFilterCall + 1) ... firstIndex].contains(where: \.isComment) else { return }
            formatter.removeTokens(in: (endOfFilterCall + 1) ... firstIndex)

            // Replace the `filter(_:)` call with `first(where:)`.
            // Since the `where` label provides semantic value,
            // convert to the non-trailing-closure form.

            // Replace `filter({ ... })` with `first(where: { ... })`.
            if let openParen, let closeParen {
                formatter.replaceToken(at: filterIndex, with: .identifier("first"))

                formatter.insert(
                    [.identifier("where"), .delimiter(":"), .space(" ")],
                    at: openParen + 1
                )
            }

            // Replace `filter { ... }` with `first(where: { ... })`.
            else {
                formatter.insert(.endOfScope(")"), at: endOfClosure + 1)

                formatter.insert(
                    [.startOfScope("("), .identifier("where"), .delimiter(":"), .space(" ")],
                    at: startOfClosure
                )

                if formatter.tokens[filterIndex + 1].isSpace {
                    formatter.removeToken(at: filterIndex + 1)
                }

                formatter.replaceToken(at: filterIndex, with: .identifier("first"))
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
