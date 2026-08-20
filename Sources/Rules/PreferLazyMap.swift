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

            // Don't insert `.lazy` again if the receiver is already lazy. `lazy` can sit anywhere in
            // the chain — `xs.lazy.filter { ... }.map { ... }` is already lazy — so checking only the
            // token before the `map` would append a second, redundant `.lazy`.
            if formatter.memberCallReceiverIsLazy(endingAt: dotBeforeMap) {
                return
            }

            // An identity `map { $0 }` transforms nothing, so making it lazy saves no work while
            // still requiring `lazy` on the receiver — which only exists on a `Sequence`, and the
            // receiver's type isn't knowable here. Leave these alone: there is nothing to gain, and
            // `map` is defined on plenty of non-`Sequence` types.
            if let onlyBodyIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: openBraceIndex),
               formatter.tokens[onlyBodyIndex] == .identifier("$0"),
               formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: onlyBodyIndex) == closeBraceIndex
            {
                return
            }

            // `lazy.map` stores its transform, so the closure becomes escaping. Where `self` is a
            // reference that turns an implicit `self` member reference — legal in the non-escaping
            // closure eager `map` takes — into "requires explicit use of 'self'", so the rewrite
            // would not compile. A bare name can't be resolved to a member of `self` from the tokens
            // alone, so unless implicit capture is permitted here, bail on any of them.
            guard formatter.implicitSelfCaptureIsPermittedInEscapingClosure(at: openBraceIndex)
                || formatter.closureBodyOnlyReferencesItsArguments(atStartOfScope: openBraceIndex)
            else { return }

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

            // `joined()` has to be passed a separator. Without one it resolves differently on a lazy
            // sequence — to the overload that flattens a sequence of sequences, rather than the
            // `StringProtocol` one — so a `String` result silently becomes a lazy sequence, and any
            // string interpolation of it starts emitting the sequence's description.
            // `joined(separator:)` returns `String` either way.
            if consumer == "joined" {
                guard callToken == .startOfScope("("),
                      !formatter.parseFunctionCallArguments(startOfScope: callIndex).isEmpty
                else { return }
            }

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
    /// Whether a closure at `index` may refer to members of `self` implicitly even once it is
    /// escaping, which is decided by what `self` is at that point.
    ///
    /// Only a reference — a `class` or `actor` — requires an explicit `self.` in an escaping closure,
    /// so a value type imposes no such requirement, and outside of any type there is no `self` to
    /// capture at all. The innermost enclosing type wins, since that is what `self` refers to.
    ///
    /// `extension` and `protocol` bodies return `false`: the underlying type may well be a class, and
    /// its declaration is usually in another file, so it can't be resolved from here.
    func implicitSelfCaptureIsPermittedInEscapingClosure(at index: Int) -> Bool {
        var scopeIndex = index
        while let startIndex = startOfScope(at: scopeIndex) {
            if isStartOfTypeBody(at: startIndex),
               let keyword = lastSignificantKeyword(at: startIndex, excluding: ["where"])
            {
                return keyword == "struct" || keyword == "enum"
            }
            scopeIndex = startIndex
        }
        // Not inside any type, so there is no `self`.
        return true
    }

    /// Whether the body of the closure starting at `startOfScopeIndex` refers to nothing but its own
    /// arguments — either the implicit `$0` shorthand or names it declares in its parameter list.
    ///
    /// Any other bare name may be an implicit `self` member, which is only legal in a non-escaping
    /// closure, so callers that make a closure escaping must not rewrite when this returns `false`.
    /// Names reached through a `.` (`$0.foo`), argument labels, keywords, and literals are all fine.
    ///
    /// This is deliberately conservative: a bare name that is really a global function or a type
    /// (`hypot($0)`, `String($0)`) is indistinguishable from a member of `self` here, so it is
    /// treated as one.
    func closureBodyOnlyReferencesItsArguments(atStartOfScope startOfScopeIndex: Int) -> Bool {
        assert(tokens[startOfScopeIndex] == .startOfScope("{"))
        guard let endOfScopeIndex = endOfScope(at: startOfScopeIndex) else { return false }

        let arguments = parseClosureArguments(at: startOfScopeIndex)
        let argumentNames = Set((arguments?.argumentIndices ?? []).map { tokens[$0].string })
        let bodyStartIndex = arguments?.inKeywordIndex ?? startOfScopeIndex

        for index in (bodyStartIndex + 1) ..< endOfScopeIndex {
            guard case let .identifier(name) = tokens[index] else { continue }
            // Literals, which the tokenizer represents as identifiers rather than keywords, and the
            // wildcard. None of these name anything.
            if tokens[index].isLiteralIdentifier || name == "_" {
                continue
            }
            // `$0` and friends are the closure's own arguments.
            if name.hasPrefix("$") {
                continue
            }
            // A name declared by the closure's parameter list.
            if argumentNames.contains(name) {
                continue
            }
            // A member of another value rather than a bare name, as in `$0.foo`.
            if last(.nonSpaceOrCommentOrLinebreak, before: index)?.isOperator(".") == true {
                continue
            }
            // An argument label, as in `$0.reduce(into: [])`.
            if isLabel(at: index) {
                continue
            }
            return false
        }

        return true
    }

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
