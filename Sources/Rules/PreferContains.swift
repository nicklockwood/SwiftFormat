//
//  PreferContains.swift
//  SwiftFormat
//
//  Created by Jon Parise on 7/2/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Prefer `contains` over equivalent patterns using `count(where:)`, `filter`, `first`, or `range(of:)`.
    static let preferContains = FormatRule(
        help: "Prefer `contains` over `count(where:) > 0`, `count(where:) == 0`, `filter(_:).isEmpty`, `first(where:) != nil`, and `range(of:) != nil`.",
        disabledByDefault: true
    ) { formatter in
        // MARK: - count(where:) > 0 / == 0 → contains(where:) / !contains(where:)

        formatter.forEach(.identifier("count")) { countIndex, _ in
            guard let (dotIndex, _, endOfCall) = formatter.parsePredicateMemberCall(at: countIndex),
                  let comparison = formatter.parseTrailingComparison(after: endOfCall)
            else { return }

            let negate: Bool
            switch (comparison.operator, formatter.tokens[comparison.operandIndex]) {
            case (">", .number("0", .integer)): negate = false // count(where:) > 0  ->  contains(where:)
            case ("==", .number("0", .integer)): negate = true // count(where:) == 0  -> !contains(where:)
            default: return
            }

            // Find the start of the receiver expression, used to insert a negating `!`. Bails on
            // optional chaining / force-unwrap in the receiver (`foo?.count(where:) == 0` is `false`
            // when `foo` is nil, whereas `!foo?.contains(where:)` doesn't produce a plain `Bool`),
            // leading-dot implicit members, and prefix operators.
            guard let receiverStart = formatter.startOfMemberCallReceiver(endingAt: dotIndex),
                  formatter.isStandaloneComparison(from: receiverStart, to: comparison.operandIndex)
            else { return }

            // Rewrite right-to-left so earlier indices stay valid.

            // 1. Drop the trailing comparison: ` > 0` / ` == 0`.
            formatter.removeTokens(in: (endOfCall + 1) ... comparison.operandIndex)

            // 2. Rename `count` → `contains`. The argument is reused as-is, so both the
            //    `(where: ...)` and trailing-closure forms keep their original syntax.
            formatter.replaceToken(at: countIndex, with: .identifier("contains"))

            // 3. Negate the receiver expression for the `== 0` case.
            if negate {
                formatter.insert(.operator("!", .prefix), at: receiverStart)
            }
        }

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
                // A non-`where:` paren label (e.g. `firstIndex(of:)`), extra arguments, or the bare
                // `.first` property don't apply.
                guard let (dotIndex, scopeIndex, endOfCall) = formatter.parsePredicateMemberCall(at: accessorIndex),
                      let comparison = formatter.parseTrailingComparison(after: endOfCall)
                else { return }

                let isTrailingClosure = formatter.tokens[scopeIndex] == .startOfScope("{")
                let nilIndex = comparison.operandIndex

                let negate: Bool
                switch (comparison.operator, formatter.tokens[nilIndex]) {
                case ("!=", .identifier("nil")): negate = false // first(where:) != nil  ->  contains(where:)
                case ("==", .identifier("nil")): negate = true // first(where:) == nil  -> !contains(where:)
                default: return
                }

                // Find the start of the receiver expression. This serves two purposes:
                //  - it locates where a negating `!` is inserted for the `== nil` case, and
                //  - it detects optional chaining / force-unwrap in the receiver, which must bail in
                //    *both* comparison directions: `foo?.first(where:)` yields an `Optional`, so
                //    `foo?.contains(where:)` is `Bool?` rather than the `Bool` the nil comparison
                //    produces (and `foo?.first(where:) != nil` is `false`, not `nil`, when `foo` is
                //    nil). It also bails on leading-dot implicit members and prefix operators.
                guard let receiverStart = formatter.startOfMemberCallReceiver(endingAt: dotIndex),
                      formatter.isStandaloneComparison(from: receiverStart, to: nilIndex)
                else { return }

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
            guard let comparison = formatter.parseTrailingComparison(after: closeParenIndex) else { return }
            let nilIndex = comparison.operandIndex

            let negate: Bool
            switch (comparison.operator, formatter.tokens[nilIndex]) {
            case ("!=", .identifier("nil")): negate = false // range(of:) != nil  ->  contains(_:)
            case ("==", .identifier("nil")): negate = true // range(of:) == nil  -> !contains(_:)
            default: return
            }

            // Bail rather than silently delete a comment before the `of:` argument.
            guard !formatter.tokens[(rangeIndex + 1) ... argStartIndex].contains(where: \.isComment) else { return }

            // Find the start of the receiver expression (the value `.range` is called on),
            // so a negated rewrite can insert `!` before the whole expression. Returns nil if
            // the receiver uses optional chaining (`foo?.range(of:)` yields `Range?`, so the
            // comparison can't be rewritten to a plain `Bool` `contains`).
            guard let receiverStart = formatter.startOfMemberCallReceiver(endingAt: dotIndex),
                  formatter.isStandaloneComparison(from: receiverStart, to: nilIndex)
            else { return }

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
        - if messages.count(where: { $0.isUnread }) == 0 {
        + if !messages.contains(where: { $0.isUnread }) {
        ```

        ```diff
        - let hasNegative = numbers.count { $0 < 0 } > 0
        + let hasNegative = numbers.contains { $0 < 0 }
        ```

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

extension Formatter {
    /// Parses a `.accessor(where: { ... })` or trailing-closure `.accessor { ... }` member call
    /// taking a single predicate, as accepted by `contains(where:)`. Returns the index of the `.`
    /// before the accessor, the `(` or `{` that starts the call, and the last token of the call.
    func parsePredicateMemberCall(at accessorIndex: Int) -> (dotIndex: Int, scopeIndex: Int, endOfCall: Int)? {
        guard let dotIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: accessorIndex),
              tokens[dotIndex] == .operator(".", .infix),
              let scopeIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: accessorIndex),
              let args = parseFunctionCallArguments(after: accessorIndex),
              args.count == 1
        else { return nil }

        if tokens[scopeIndex] == .startOfScope("{") {
            guard args[0].label == nil else { return nil }
            return (dotIndex, scopeIndex, args[0].valueRange.upperBound)
        }

        guard args[0].label == "where", let closeParenIndex = endOfScope(at: scopeIndex) else { return nil }
        return (dotIndex, scopeIndex, closeParenIndex)
    }

    /// Parses an infix comparison `<operator> <operand>` immediately following `endOfCall`, where
    /// the operand is a single token. Returns nil if a comment would be lost by removing it.
    func parseTrailingComparison(after endOfCall: Int) -> (operator: String, operandIndex: Int)? {
        guard let operatorIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: endOfCall),
              case let .operator(op, .infix) = tokens[operatorIndex],
              let operandIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: operatorIndex),
              !tokens[endOfCall ... operandIndex].contains(where: \.isComment)
        else { return nil }
        return (op, operandIndex)
    }

    /// Whether the comparison spanning `startIndex ... endIndex` is a complete operand, i.e. it
    /// isn't adjacent to an infix operator that binds more tightly than comparison operators
    /// (e.g. `a + xs.count(where: p) > 0` or `xs.count(where: p) > 0 + offset`).
    func isStandaloneComparison(from startIndex: Int, to endIndex: Int) -> Bool {
        let looserOperators: Set = ["&&", "||", "?", ":", "="]
        for neighbor in [
            index(of: .nonSpaceOrCommentOrLinebreak, before: startIndex),
            index(of: .nonSpaceOrCommentOrLinebreak, after: endIndex),
        ] {
            if let neighbor, case let .operator(op, .infix) = tokens[neighbor], !looserOperators.contains(op) {
                return false
            }
        }
        return true
    }
}
