//
//  PreferContains.swift
//  SwiftFormat
//
//  Created by Jon Parise on 7/2/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Prefer `contains` over equivalent patterns using `filter`, `first`, or `range(of:)`.
    static let preferContains = FormatRule(
        help: "Prefer `contains` over `filter(_:).isEmpty`, `first(where:) != nil`, and `range(of:) != nil`."
    ) { formatter in
        // MARK: - filter(_:).isEmpty → !contains(where:)

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

        // MARK: - first(where:) / firstIndex(where:) != nil → contains(where:)

        for accessor in ["first", "firstIndex"] {
            formatter.forEach(.identifier(accessor)) { accessorIndex, _ in
                // Require a member call: something `.first(...)` / `.firstIndex(...)`.
                guard let dotIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: accessorIndex),
                      formatter.tokens[dotIndex] == .operator(".", .infix),
                      let scopeIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: accessorIndex)
                else { return }

                // Parse the call arguments with the shared helper, which handles both the
                // `first(where: { ... })` paren form and the trailing-closure `first { ... }` form.
                // Each must be a single argument equivalent to `contains(where:)`: a `where:`-labeled
                // paren argument, or the unlabeled trailing closure. A non-`where:` paren label (e.g.
                // `firstIndex(of:)`), extra arguments, or the bare `.first` property don't apply.
                guard let args = formatter.parseFunctionCallArguments(after: accessorIndex),
                      args.count == 1
                else { return }

                let isTrailingClosure = formatter.tokens[scopeIndex] == .startOfScope("{")
                if isTrailingClosure {
                    guard args[0].label == nil else { return }
                } else {
                    guard args[0].label == "where" else { return }
                }

                // End of the call expression: the closure's `}` for the trailing-closure form,
                // otherwise the closing paren.
                let endOfCall: Int
                if isTrailingClosure {
                    endOfCall = args[0].valueRange.upperBound
                } else {
                    guard let closeParenIndex = formatter.endOfScope(at: scopeIndex) else { return }
                    endOfCall = closeParenIndex
                }

                // Require a trailing `!= nil` or `== nil` comparison.
                guard let operatorIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: endOfCall),
                      let nilIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: operatorIndex),
                      formatter.tokens[nilIndex] == .identifier("nil")
                else { return }

                let negate: Bool
                switch formatter.tokens[operatorIndex] {
                case .operator("!=", .infix): negate = false // first(where:) != nil  ->  contains(where:)
                case .operator("==", .infix): negate = true // first(where:) == nil  -> !contains(where:)
                default: return
                }

                // Bail rather than silently delete a comment in the trailing comparison span.
                guard !formatter.tokens[endOfCall ... nilIndex].contains(where: \.isComment) else { return }

                // Find the start of the receiver expression. This serves two purposes:
                //  - it locates where a negating `!` is inserted for the `== nil` case, and
                //  - it detects optional chaining / force-unwrap in the receiver, which must bail in
                //    *both* comparison directions: `foo?.first(where:)` yields an `Optional`, so
                //    `foo?.contains(where:)` is `Bool?` rather than the `Bool` the nil comparison
                //    produces (and `foo?.first(where:) != nil` is `false`, not `nil`, when `foo` is
                //    nil). It also bails on leading-dot implicit members and prefix operators.
                guard let receiverStart = formatter.startOfMemberCallReceiver(endingAt: dotIndex) else { return }

                // For the trailing-closure form we move the closure into `(where: ...)`, which means
                // collapsing any whitespace between the accessor and its `{`. Bail rather than
                // silently discard a comment living in that gap (the closure body is untouched).
                if isTrailingClosure,
                   formatter.tokens[(accessorIndex + 1) ..< scopeIndex].contains(where: \.isComment)
                {
                    return
                }

                // Rewrite right-to-left so earlier indices stay valid.

                // 1. Drop the trailing comparison: ` != nil` / ` == nil`.
                formatter.removeTokens(in: (endOfCall + 1) ... nilIndex)

                // 2. For the trailing-closure form, wrap the closure in `(where: { ... })` so it
                //    matches `contains(where:)` (which has no trailing-closure-friendly position).
                if isTrailingClosure {
                    formatter.insert(.endOfScope(")"), at: endOfCall + 1)
                    formatter.insert(
                        [.startOfScope("("), .identifier("where"), .delimiter(":"), .space(" ")],
                        at: scopeIndex
                    )
                    // Collapse any whitespace or linebreak between the accessor and the (now
                    // wrapped) closure so `first { ... }` becomes `contains(where: { ... })`
                    // instead of leaving a stray space or newline before the inserted `(`.
                    if accessorIndex + 1 < scopeIndex {
                        formatter.removeTokens(in: (accessorIndex + 1) ..< scopeIndex)
                    }
                }

                // 3. Rename `first` / `firstIndex` → `contains`. The `(where: ...)` argument is reused.
                formatter.replaceToken(at: accessorIndex, with: .identifier("contains"))

                // 4. Negate the receiver expression for the `== nil` case.
                if negate {
                    formatter.insert(.operator("!", .prefix), at: receiverStart)
                }
            }
        }

        // MARK: - range(of:) != nil → contains(_:)

        formatter.forEach(.identifier("range")) { rangeIndex, _ in
            // Require a member call: something `.range(...)`.
            guard let dotIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: rangeIndex),
                  formatter.tokens[dotIndex] == .operator(".", .infix),
                  let openParenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: rangeIndex),
                  formatter.tokens[openParenIndex] == .startOfScope("("),
                  let closeParenIndex = formatter.endOfScope(at: openParenIndex)
            else { return }

            // Require a single `of:` labeled argument. The `range(of:options:range:)`
            // overloads take additional arguments and aren't equivalent to `contains`.
            let args = formatter.parseFunctionCallArguments(startOfScope: openParenIndex)
            guard args.count == 1,
                  args[0].label == "of",
                  let labelIndex = args[0].labelIndex
            else { return }

            let argStartIndex = args[0].valueRange.lowerBound

            // Require a trailing `!= nil` or `== nil` comparison.
            guard let operatorIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: closeParenIndex),
                  let nilIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: operatorIndex),
                  formatter.tokens[nilIndex] == .identifier("nil")
            else { return }

            let negate: Bool
            switch formatter.tokens[operatorIndex] {
            case .operator("!=", .infix): negate = false // range(of:) != nil  ->  contains(_:)
            case .operator("==", .infix): negate = true // range(of:) == nil  -> !contains(_:)
            default: return
            }

            // Bail rather than silently delete any comment in the spans we rewrite.
            guard !formatter.tokens[(rangeIndex + 1) ... argStartIndex].contains(where: \.isComment),
                  !formatter.tokens[closeParenIndex ... nilIndex].contains(where: \.isComment)
            else { return }

            // Find the start of the receiver expression (the value `.range` is called on),
            // so a negated rewrite can insert `!` before the whole expression. Returns nil if
            // the receiver uses optional chaining (`foo?.range(of:)` yields `Range?`, so the
            // comparison can't be rewritten to a plain `Bool` `contains`).
            guard let receiverStart = formatter.startOfMemberCallReceiver(endingAt: dotIndex) else { return }

            // Rewrite right-to-left so earlier indices stay valid.

            // 1. Drop the trailing comparison: ` != nil` / ` == nil`.
            formatter.removeTokens(in: (closeParenIndex + 1) ... nilIndex)

            // 2. Drop the `of:` label (and the space after the colon) so
            //    `range(of: x)` becomes `contains(x)`.
            formatter.removeTokens(in: labelIndex ..< argStartIndex)

            // 3. Rename `range` to `contains`.
            formatter.replaceToken(at: rangeIndex, with: .identifier("contains"))

            // 4. Negate the receiver expression for the `== nil` case.
            if negate {
                formatter.insert(.operator("!", .prefix), at: receiverStart)
            }
        }
    } examples: {
        """
        ```diff
        - if messages.filter({ $0.isUnread }).isEmpty {
        + if !messages.contains(where: { $0.isUnread }) {
        ```

        ```diff
        - if numbers.first(where: { $0 < 0 }) != nil {
        + if numbers.contains(where: { $0 < 0 }) {
        ```

        ```diff
        - if text.range(of: "needle") != nil {
        + if text.contains("needle") {
        ```
        """
    }
}
