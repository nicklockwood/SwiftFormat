//
//  PreferContainsOverRange.swift
//  SwiftFormat
//
//  Created by Jon Parise on 6/25/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let preferContainsOverRange = FormatRule(
        help: "Prefer `contains` over `range(of:)` compared against nil.",
        disabledByDefault: true
    ) { formatter in
        formatter.forEach(.identifier("range")) { rangeIndex, _ in
            // Require a member call: something `.range(...)`.
            guard let dotIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: rangeIndex),
                  formatter.tokens[dotIndex] == .operator(".", .infix),
                  let openParenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: rangeIndex),
                  formatter.tokens[openParenIndex] == .startOfScope("("),
                  let closeParenIndex = formatter.endOfScope(at: openParenIndex)
            else { return }

            // Require a single `of:` labeled argument. The `range(of:options:range:)`
            // overloads take additional arguments and aren't equivalent to `contains`, so a
            // top-level comma in the call disqualifies it. Commas nested inside the argument
            // expression (e.g. `range(of: foo(a, b))`) don't count, so skip nested scopes.
            guard let labelIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: openParenIndex),
                  formatter.tokens[labelIndex] == .identifier("of"),
                  let colonIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: labelIndex),
                  formatter.tokens[colonIndex] == .delimiter(":")
            else { return }

            var scanIndex = colonIndex
            while scanIndex < closeParenIndex {
                if formatter.tokens[scanIndex].isStartOfScope {
                    guard let scopeEnd = formatter.endOfScope(at: scanIndex) else { return }
                    scanIndex = scopeEnd
                } else if formatter.tokens[scanIndex] == .delimiter(",") {
                    return // top-level comma: a multi-argument `range(of:options:…)` call
                }
                scanIndex += 1
            }

            // The argument must be non-empty (e.g. `range(of:)` as a method reference is not a call we handle).
            guard let argStartIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: colonIndex),
                  argStartIndex < closeParenIndex
            else { return }

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
            guard let receiverStart = formatter.startOfRangeReceiver(endingAt: dotIndex) else { return }

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
        - if text.range(of: "needle") != nil {
        + if text.contains("needle") {

        - if text.range(of: "needle") == nil {
        + if !text.contains("needle") {
        ```

        ***NOTE:*** In rare cases this rewrite can change behavior — e.g. an
        `NSString` receiver whose `range(of:)` returns a non-optional `NSRange`
        (where `!= nil` is always true), or a type without a matching `contains`
        overload. For this reason the rule is disabled by default, and must be
        enabled via the `--enable preferContainsOverRange` option.
        """
    }
}

extension Formatter {
    /// Given the index of the `.` immediately before a `range(of:)` call, returns the index of
    /// the first token of the receiver expression that `range(of:)` is called on — the position
    /// where a `!` should be inserted to negate the whole `contains` call.
    ///
    /// Walks backwards across member-access dots and balanced trailing scopes (subscripts, call
    /// parentheses, and generic argument clauses), and stops at the first token that bounds the
    /// expression (an infix operator, delimiter, keyword, or start of an enclosing scope).
    ///
    /// Returns `nil` when the negating `!` couldn't be placed safely:
    /// - optional chaining / force-unwrap in the receiver (`foo?.range(of:)` yields `Range?`, so
    ///   the nil comparison can't become a plain `Bool`-returning `contains`),
    /// - a leading-dot (implicit member) receiver (`.foo.range(of:)`), where a prefix `!` would be
    ///   malformed,
    /// - a prefix operator immediately before the receiver (`-foo.range(of:)`), where inserting `!`
    ///   would juxtapose unary operators.
    func startOfRangeReceiver(endingAt dotIndex: Int) -> Int? {
        var start = dotIndex
        while let prev = index(of: .nonSpaceOrCommentOrLinebreak, before: start) {
            switch tokens[prev] {
            case .operator(".", _), .delimiter("."):
                // Only an identifier or a closing scope can precede an ordinary member-access dot.
                // Anything else (or nothing) means a leading-dot implicit member (`.foo`), which
                // has no value token to prefix with `!`, so bail.
                guard let beforeDot = index(of: .nonSpaceOrCommentOrLinebreak, before: prev),
                      tokens[beforeDot].isIdentifier || tokens[beforeDot].isEndOfScope
                else { return nil }
                start = prev

            case .identifier:
                start = prev

            case .operator("?", _), .operator("!", _):
                // Optional chaining (or force-unwrap) in the receiver changes the result type
                // of the call, so we can't safely rewrite the nil comparison.
                return nil

            case .operator(_, .prefix):
                // A prefix operator right before the receiver (e.g. `-foo`) would be juxtaposed
                // with the `!` we'd insert. Bail rather than emit invalid syntax.
                return nil

            case .endOfScope(")"), .endOfScope("]"), .endOfScope(">"):
                guard let scopeStart = startOfScope(at: prev) else { return nil }
                start = scopeStart

            default:
                // Any other token (infix operator, delimiter, keyword, start of scope) bounds
                // the receiver expression.
                return start
            }
        }
        return start
    }
}
