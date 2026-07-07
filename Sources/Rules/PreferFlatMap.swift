//
//  PreferFlatMap.swift
//  SwiftFormat
//
//  Created by Jon Parise on 6/24/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let preferFlatMap = FormatRule(
        help: "Prefer `flatMap { ... }` over `map { ... }.reduce([], +)`.",
        disabledByDefault: true
    ) { formatter in
        formatter.forEach(.identifier("map")) { mapIndex, _ in
            guard let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: mapIndex) else { return }

            // Parse the `map` call, which takes exactly one closure
            // and is either `map { ... }` or `map({ ... })`
            let endOfMapCall: Int

            if formatter.tokens[nextIndex] == .startOfScope("("),
               let startOfClosureIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: nextIndex),
               formatter.tokens[startOfClosureIndex] == .startOfScope("{"),
               let endOfClosureIndex = formatter.endOfScope(at: startOfClosureIndex),
               let tokenAfterClosure = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: endOfClosureIndex),
               formatter.tokens[tokenAfterClosure] == .endOfScope(")")
            {
                endOfMapCall = tokenAfterClosure
            }

            else if formatter.tokens[nextIndex] == .startOfScope("{"),
                    let endOfClosureIndex = formatter.endOfScope(at: nextIndex)
            {
                endOfMapCall = endOfClosureIndex
            }

            else {
                return
            }

            // Require a `.reduce` call immediately after the `map` call.
            guard let dotIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: endOfMapCall),
                  formatter.tokens[dotIndex] == .operator(".", .infix),
                  let reduceIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: dotIndex),
                  formatter.tokens[reduceIndex] == .identifier("reduce"),
                  let openParenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: reduceIndex),
                  formatter.tokens[openParenIndex] == .startOfScope("("),
                  let closeParenIndex = formatter.endOfScope(at: openParenIndex)
            else { return }

            // Require the reduce arguments to be exactly `[], +`, i.e. an empty
            // array literal seed combined with the `+` operator. This is the
            // flatten-by-concatenation shape that `flatMap` expresses directly.
            let reduceArgs = formatter.parseFunctionCallArguments(startOfScope: openParenIndex)
            guard reduceArgs.count == 2,
                  reduceArgs[0].label == nil,
                  reduceArgs[0].value == "[]",
                  reduceArgs[1].label == nil,
                  reduceArgs[1].value == "+"
            else { return }

            // Bail if the span we'd remove contains a comment, so we never
            // silently delete a comment between the `map` and `reduce` calls.
            let removalRange = (endOfMapCall + 1) ... closeParenIndex
            guard !formatter.tokens[removalRange].contains(where: \.isComment) else { return }

            // Remove the `.reduce([], +)` suffix (including any whitespace or
            // line breaks between the map call and the reduce call), then
            // rename `map` to `flatMap`.
            formatter.removeTokens(in: removalRange)
            formatter.replaceToken(at: mapIndex, with: .identifier("flatMap"))
        }
    } examples: {
        """
        ```diff
        - let allItems = sections.map { $0.items }.reduce([], +)
        + let allItems = sections.flatMap { $0.items }

        - let allItems = sections.map({ $0.items }).reduce([], +)
        + let allItems = sections.flatMap({ $0.items })
        ```
        """
    }
}
