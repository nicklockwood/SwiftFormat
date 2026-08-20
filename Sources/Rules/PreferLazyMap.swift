//
//  PreferLazyMap.swift
//  SwiftFormat
//
//  Created by Jon Parise on 8/19/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let preferLazyMap = FormatRule(
        help: "Prefer `lazy.map` over `map` before single-pass operations like `min()`.",
        disabledByDefault: true
    ) { formatter in
        formatter.forEach(.identifier("map")) { mapIndex, _ in
            // Require a member call with a trailing closure: something `.map { ... }`.
            // `.map(transform)` is left alone — detecting where to insert `.lazy` safely across
            // the other call forms isn't worth the added complexity.
            guard let dotBeforeMap = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: mapIndex),
                  formatter.tokens[dotBeforeMap] == .operator(".", .infix),
                  let openBraceIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: mapIndex),
                  formatter.tokens[openBraceIndex] == .startOfScope("{"),
                  let closeBraceIndex = formatter.endOfScope(at: openBraceIndex)
            else { return }

            // Don't insert `.lazy` again if the receiver already has it.
            if let receiverIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: dotBeforeMap),
               formatter.tokens[receiverIndex] == .identifier("lazy")
            {
                return
            }

            // The mapped sequence must be consumed directly by one of the operations that walks it
            // a single time, since those never need the intermediate array an eager `map` allocates.
            guard let dotBeforeConsumer = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: closeBraceIndex),
                  formatter.tokens[dotBeforeConsumer] == .operator(".", .infix),
                  let consumerIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: dotBeforeConsumer),
                  case let .identifier(consumer) = formatter.tokens[consumerIndex],
                  Formatter.lazyMapConsumers.contains(consumer),
                  let callIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: consumerIndex)
            else { return }

            // The consumer has to actually be *called*, either with an argument list (`min()`) or a
            // trailing closure (`allSatisfy { ... }`). This is what limits `first` to `first(where:)`
            // — see `lazyMapConsumers` — and skips an uncalled method reference. A `{` that opens a
            // control-flow body rather than a closure doesn't count, since in that case the consumer
            // is a property access rather than a call.
            let callToken = formatter.tokens[callIndex]
            guard callToken == .startOfScope("(")
                || (callToken == .startOfScope("{") && formatter.isStartOfClosure(at: callIndex))
            else { return }

            formatter.insert([.identifier("lazy"), .operator(".", .infix)], at: mapIndex)
        }
    } examples: {
        """
        ```diff
        - let minY = vertices.map { $0.y }.min()
        + let minY = vertices.lazy.map { $0.y }.min()

        - let names = users.map { $0.name }.joined(separator: ", ")
        + let names = users.lazy.map { $0.name }.joined(separator: ", ")

        - let hasEmpty = rows.map { $0.title }.contains(where: { $0.isEmpty })
        + let hasEmpty = rows.lazy.map { $0.title }.contains(where: { $0.isEmpty })
        ```
        """
    }
}

extension Formatter {
    /// `Sequence` operations that consume their receiver in a single pass without materializing it,
    /// so a preceding `map` can be made lazy to avoid allocating an intermediate array.
    ///
    /// Deliberately excludes operations that must materialize their receiver to do their work
    /// (`sorted()`, `reversed()`), where laziness buys nothing.
    ///
    /// `first` refers only to `first(where:)`. The `first` *property* is declared on `Collection`
    /// rather than `Sequence`, so its meaning depends on the receiver's type in a way that can't be
    /// determined from the tokens alone — callers must require a call paren, which excludes it.
    static let lazyMapConsumers: Set<String> = [
        // Visit every element exactly once, so the closure is called the same number of times
        // whether the `map` is eager or lazy — safe even for a closure with side effects.
        "min", "max", "reduce", "joined",
        // May exit early, so a lazy `map` can call the closure fewer times than an eager one.
        // This is the same tradeoff the `preferFirstWhere` rule already makes.
        "contains", "allSatisfy", "first",
    ]
}
