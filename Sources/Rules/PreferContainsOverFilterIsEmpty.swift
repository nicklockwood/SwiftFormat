//
//  PreferContainsOverFilterIsEmpty.swift
//  SwiftFormat
//
//  Created by Jon Parise on 7/2/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let preferContainsOverFilterIsEmpty = FormatRule(
        help: "Prefer `contains(where:)` over `filter(_:).isEmpty`."
    ) { formatter in
        formatter.forEach(.identifier("filter")) { filterIndex, _ in
            // Require a member call: something `.filter(...)`.
            guard let dotBeforeFilter = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: filterIndex),
                  formatter.tokens[dotBeforeFilter] == .operator(".", .infix),
                  let scopeIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: filterIndex)
            else { return }

            // `filter` must be called with a single closure argument, either the trailing-closure
            // `filter { ... }` form or the parenthesized `filter({ ... })` form. A stored-predicate
            // argument (`filter(predicate)`) isn't matched — we only reuse a literal closure.
            guard let args = formatter.parseFunctionCallArguments(after: filterIndex),
                  args.count == 1,
                  args[0].label == nil,
                  formatter.tokens[args[0].valueRange.lowerBound] == .startOfScope("{")
            else { return }

            let isTrailingClosure = formatter.tokens[scopeIndex] == .startOfScope("{")

            // End of the `filter(...)` call: the closure's `}` for the trailing-closure form,
            // otherwise the closing paren.
            let endOfCall: Int
            if isTrailingClosure {
                endOfCall = args[0].valueRange.upperBound
            } else {
                guard let closeParenIndex = formatter.endOfScope(at: scopeIndex) else { return }
                endOfCall = closeParenIndex
            }

            // Require a trailing `.isEmpty` *property* access.
            guard let dotIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: endOfCall),
                  formatter.tokens[dotIndex] == .operator(".", .infix),
                  let isEmptyIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: dotIndex),
                  formatter.tokens[isEmptyIndex] == .identifier("isEmpty")
            else { return }

            // `.isEmpty` must be the *end* of the expression. The rewrite inserts (or cancels) a
            // prefix `!`, which binds looser than any postfix operator, so any postfix continuation
            // after `.isEmpty` would be captured by the `!` and change meaning:
            //   `xs.filter { }.isEmpty.description`  -> `!xs.contains(...).description`  (== `!String`)
            //   `xs.filter { }.isEmpty!`             -> `!xs.contains(...)!`             (wrong precedence)
            // So bail on a trailing member-access `.`, a call/subscript/generic/closure start-of-scope,
            // or a postfix `!` / `?`. A `{` that opens a *control-flow* body (e.g.
            // `if xs.filter { }.isEmpty {`) is not a postfix continuation and does not disqualify it.
            if let tokenAfterIsEmpty = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: isEmptyIndex) {
                switch formatter.tokens[tokenAfterIsEmpty] {
                case .operator(".", .infix), .delimiter("."),
                     .operator("!", .postfix), .operator("?", .postfix):
                    return
                case .startOfScope("{") where !formatter.isStartOfClosure(at: tokenAfterIsEmpty):
                    break // control-flow body, e.g. `if xs.filter { }.isEmpty { ... }`
                case let token where token.isStartOfScope:
                    return // call `(`, subscript `[`, generic `<`, or trailing closure `{`
                default:
                    break
                }
            }

            // Find the start of the receiver expression. `stoppingAtLeadingNegation` makes a leading
            // `!` (the `!xs.filter { … }.isEmpty` cancellation case) bound the receiver instead of
            // bailing. Still bails on optional chaining / force-unwrap (result-type change), leading-dot
            // implicit members, and other prefix operators.
            guard let receiverStart = formatter.startOfMemberCallReceiver(
                endingAt: dotBeforeFilter,
                stoppingAtLeadingNegation: true
            ) else { return }

            // A prefix `!` immediately before the receiver is an existing negation to cancel.
            let leadingNegation: Int?
            if let prev = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: receiverStart),
               formatter.tokens[prev] == .operator("!", .prefix)
            {
                leadingNegation = prev
            } else {
                leadingNegation = nil
            }

            // Bail rather than silently delete a comment in any span we rewrite.
            guard !formatter.tokens[endOfCall ... isEmptyIndex].contains(where: \.isComment) else { return }
            if isTrailingClosure,
               formatter.tokens[(filterIndex + 1) ..< scopeIndex].contains(where: \.isComment)
            {
                return
            }

            // Rewrite right-to-left so earlier indices stay valid.

            // 1. Drop the trailing `.isEmpty`.
            formatter.removeTokens(in: (endOfCall + 1) ... isEmptyIndex)

            // 2. Reshape `filter`'s argument into `(where: { ... })`.
            if isTrailingClosure {
                // `filter { ... }` -> `contains(where: { ... })`
                formatter.insert(.endOfScope(")"), at: endOfCall + 1)
                formatter.insert(
                    [.startOfScope("("), .identifier("where"), .delimiter(":"), .space(" ")],
                    at: scopeIndex
                )
                // Collapse any whitespace/linebreak between `filter` and its `{`.
                if filterIndex + 1 < scopeIndex {
                    formatter.removeTokens(in: (filterIndex + 1) ..< scopeIndex)
                }
            } else {
                // `filter({ ... })` -> `contains(where: { ... })`
                formatter.insert(
                    [.identifier("where"), .delimiter(":"), .space(" ")],
                    at: scopeIndex + 1
                )
            }

            // 3. Rename `filter` -> `contains`.
            formatter.replaceToken(at: filterIndex, with: .identifier("contains"))

            // 4. Reconcile negation. `filter { ... }.isEmpty` means "nothing matches", i.e.
            //    `!contains(where:)`. If the expression was already negated (`!xs.filter { ... }.isEmpty`),
            //    the two negations cancel: just drop the existing `!`. Otherwise insert one.
            if let leadingNegation {
                // Drop the existing `!` (a prefix operator binds directly to its operand, so there's
                // no whitespace between it and the receiver to clean up).
                formatter.removeToken(at: leadingNegation)
            } else {
                formatter.insert(.operator("!", .prefix), at: receiverStart)
            }
        }
    } examples: {
        """
        ```diff
        - if messages.filter({ $0.isUnread }).isEmpty {
        + if !messages.contains(where: { $0.isUnread }) {

        - let hasUnread = !messages.filter { $0.isUnread }.isEmpty
        + let hasUnread = messages.contains(where: { $0.isUnread })
        ```
        """
    }
}
