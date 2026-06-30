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
