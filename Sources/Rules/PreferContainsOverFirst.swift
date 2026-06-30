//
//  PreferContainsOverFirst.swift
//  SwiftFormat
//
//  Created by Jon Parise on 6/29/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let preferContainsOverFirst = FormatRule(
        help: "Prefer `contains(where:)` over `first(where:)` / `firstIndex(where:)` compared against nil."
    ) { formatter in
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

                // For the `== nil` case, find the start of the receiver expression so the negating
                // `!` can be inserted before the whole expression (bails on optional chaining etc.).
                let receiverStart: Int?
                if negate {
                    guard let start = formatter.startOfMemberCallReceiver(endingAt: dotIndex) else { return }
                    receiverStart = start
                } else {
                    receiverStart = nil
                }

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
                if let receiverStart {
                    formatter.insert(.operator("!", .prefix), at: receiverStart)
                }
            }
        }
    } examples: {
        """
        ```diff
        - if numbers.first(where: { $0 < 0 }) != nil {
        + if numbers.contains(where: { $0 < 0 }) {

        - if numbers.firstIndex(where: { $0 < 0 }) == nil {
        + if !numbers.contains(where: { $0 < 0 }) {
        ```
        """
    }
}
