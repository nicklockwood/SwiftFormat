//
//  PreferMinMaxOverMap.swift
//  SwiftFormat
//
//  Created by Jon Parise on 8/19/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let preferMinMaxOverMap = FormatRule(
        help: "Prefer `min()`/`max()` over `map { $0.foo }.min()`/`.max()`.",
        disabledByDefault: true
    ) { formatter in
        formatter.forEach(.identifier("map")) { mapIndex, _ in
            // Require a member call: something `.map { ... }` (trailing closure, no parens —
            // `.map(someTransform)` isn't rewritten since there's no closure body to inspect).
            guard let dotBeforeMap = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: mapIndex),
                  formatter.tokens[dotBeforeMap] == .operator(".", .infix),
                  let openBraceIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: mapIndex),
                  formatter.tokens[openBraceIndex] == .startOfScope("{"),
                  let closeBraceIndex = formatter.endOfScope(at: openBraceIndex)
            else { return }

            // The closure body must be exactly `$0` followed by a plain member-access chain
            // (`$0.foo`, `$0.foo.bar`) — nothing else. This is what lets the same chain be safely
            // reused three times below: twice to build the `min`/`max` comparator, and once more
            // to re-extract the projected value from the element `min`/`max` returns. A computed
            // expression (`$0.width * $0.height`), a function call, or a bare `$0` (identity map)
            // can't be replayed this way, so all of those are left untouched.
            guard let dollarZeroIndex = formatter.index(of: .nonSpaceOrLinebreak, after: openBraceIndex),
                  formatter.tokens[dollarZeroIndex] == .identifier("$0"),
                  let lastBodyIndex = formatter.index(of: .nonSpaceOrLinebreak, before: closeBraceIndex),
                  lastBodyIndex > dollarZeroIndex
            else { return }
            guard formatter.isSimpleMemberAccessChain(in: (dollarZeroIndex + 1) ... lastBodyIndex) else {
                return
            }
            let chainTokens = Array(formatter.tokens[(dollarZeroIndex + 1) ... lastBodyIndex])

            // Require a trailing, argument-less `.min()` or `.max()` call. Unlike the `sorted().first`
            // → `min()` rewrite, there's no tie-breaking hazard here for `.max()`: the map projects
            // to a scalar, and every element tied on that scalar shares the same projected value, so
            // it doesn't matter which tied element `min`/`max` picks — the re-extracted value is
            // identical either way. Both directions are safe to rewrite symmetrically.
            guard let dotBeforeAccessor = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: closeBraceIndex),
                  formatter.tokens[dotBeforeAccessor] == .operator(".", .infix),
                  let accessorIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: dotBeforeAccessor),
                  case let .identifier(accessorName) = formatter.tokens[accessorIndex],
                  accessorName == "min" || accessorName == "max",
                  let openParenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: accessorIndex),
                  formatter.tokens[openParenIndex] == .startOfScope("("),
                  let closeParenIndex = formatter.endOfScope(at: openParenIndex),
                  formatter.parseFunctionCallArguments(startOfScope: openParenIndex).isEmpty
            else { return }

            // The result is only rewritten as far as an immediately-trailing `!`; anything else
            // that follows (further chaining, a subscript) is out of scope, since inserting the
            // re-extracted chain ahead of it would change what it's applied to. A trailing
            // `?? default` is left completely alone — the rewrite only needs to land the
            // re-extraction before it, which happens naturally since we stop at `closeParenIndex`.
            var replacementEndIndex = closeParenIndex
            var trailingMarker = Token.operator("?", .postfix)
            if let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: closeParenIndex) {
                switch formatter.tokens[nextIndex] {
                case .operator("!", .postfix):
                    trailingMarker = .operator("!", .postfix)
                    replacementEndIndex = nextIndex

                case .operator(".", .infix), .startOfScope("["):
                    return

                default:
                    break
                }
            }

            // Bail rather than silently dropping a comment anywhere in the span being rewritten.
            guard !formatter.tokens[dotBeforeMap ... replacementEndIndex].contains(where: \.isComment) else { return }

            let comparator: [Token] = [.identifier("$0")] + chainTokens
                + [.space(" "), .operator("<", .infix), .space(" ")]
                + [.identifier("$1")] + chainTokens
            let replacement: [Token] = [.operator(".", .infix), .identifier(accessorName), .space(" "),
                                        .startOfScope("{"), .space(" ")] + comparator
                + [.space(" "), .endOfScope("}"), trailingMarker] + chainTokens

            formatter.replaceTokens(in: dotBeforeMap ... replacementEndIndex, with: replacement)
        }
    } examples: {
        """
        ```diff
        - let minY = vertices.map { $0.y }.min()!
        + let minY = vertices.min { $0.y < $1.y }!.y

        - let floorOffset = amenities.map { $0.box.minY }.min() ?? 0
        + let floorOffset = amenities.min { $0.box.minY < $1.box.minY }?.box.minY ?? 0
        ```
        """
    }
}
