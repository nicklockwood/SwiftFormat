//
//  PreferCountWhere.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 12/7/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let preferCountWhere = FormatRule(
        help: "Prefer `count(where:)` over `filter(_:).count`."
    ) { formatter in
        // count(where:) was added in Swift 6.0
        guard formatter.options.swiftVersion >= "6.0" else { return }

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

            // Check if there's a `.count` property access after the filter call
            guard let dotIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: closeParen ?? endOfClosure),
                  formatter.tokens[dotIndex] == .operator(".", .infix),
                  let countIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: dotIndex),
                  formatter.tokens[countIndex] == .identifier("count")
            else { return }

            // Ensure the `.count` is a property access, not a method call.
            if let tokenAfterCount = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: countIndex),
               formatter.tokens[tokenAfterCount].isStartOfScope
            { return }

            // Remove the `.count` property access.
            formatter.removeToken(at: countIndex)
            formatter.removeToken(at: dotIndex)

            // Replace the `filter(_:)` call with `count(where:)`.
            // Since the `where` label provides semantic value,
            // convert to the non-trailing-closure form.

            // Replace `filter({ ... })` with `count(where: { ... })`.
            if let openParen, let closeParen {
                formatter.replaceToken(at: filterIndex, with: .identifier("count"))

                formatter.insert(
                    [.identifier("where"), .delimiter(":"), .space(" ")],
                    at: openParen + 1
                )
            }

            // Replace `filter { ... }` with `count(where: { ... })`.
            else {
                formatter.insert(.endOfScope(")"), at: endOfClosure + 1)

                formatter.insert(
                    [.startOfScope("("), .identifier("where"), .delimiter(":"), .space(" ")],
                    at: startOfClosure
                )

                if formatter.tokens[filterIndex + 1].isSpace {
                    formatter.removeToken(at: filterIndex + 1)
                }

                formatter.replaceToken(at: filterIndex, with: .identifier("count"))
            }
        }
    } examples: {
        """
        ```diff
        - planets.filter { !$0.moons.isEmpty }.count
        + planets.count(where: { !$0.moons.isEmpty })

        - planets.filter { planet in
        -     planet.moons.filter { moon in
        -         moon.hasAtmosphere
        -     }.count > 1
        - }.count
        + planets.count(where: { planet in
        +     planet.moons.count(where: { moon in
        +         moon.hasAtmosphere
        +     }) > 1
        + })
        ```
        """
    }
}
