//
//  PreferExplicitFalse.swift
//  SwiftFormat
//
//  Created by KYHyeon on 02/08/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Convert prefix `!` negation to explicit `== false` comparison.
    /// This improves readability for teams who find the `!` prefix easy to miss.
    static let preferExplicitFalse = FormatRule(
        help: "Prefer `== false` over `!` prefix negation.",
        disabledByDefault: true
    ) { formatter in
        formatter.forEach(.operator("!", .prefix)) { notIndex, _ in
            guard let operandStart = formatter.index(
                of: .nonSpaceOrCommentOrLinebreak,
                after: notIndex
            ) else {
                return
            }

            if formatter.tokens[operandStart].isOperator(ofType: .prefix) {
                return
            }

            if formatter.currentScope(at: notIndex) == .startOfScope("#if") {
                return
            }

            guard let operandEnd = formatter.endOfPrefixOperand(
                at: operandStart
            ) else {
                return
            }

            // Skip if followed by a comparison operator — inserting `== false`
            // before another comparison creates a non-associative operator chain.
            // e.g., `!a == b` would become `a == false == b` (compile error)
            if formatter.isFollowedByComparisonOperator(at: operandEnd) {
                return
            }

            formatter.insert([
                .space(" "),
                .operator("==", .infix),
                .space(" "),
                .identifier("false"),
            ], at: operandEnd + 1)

            formatter.removeToken(at: notIndex)
        }
    } examples: {
        """
        ```diff
        - if !flag {
        + if flag == false {
        ```

        ```diff
        - guard !array.isEmpty else { return }
        + guard array.isEmpty == false else { return }
        ```
        """
    }
}

// MARK: - Helpers

extension Formatter {
    /// Finds the end of the postfix expression starting at `index`, which is the
    /// first non-space token after a prefix `!`. Uses `parseExpressionRange` for
    /// expression parsing, then finds the boundary before any infix operators,
    /// since the prefix `!` only binds to the immediate postfix expression.
    func endOfPrefixOperand(at index: Int) -> Int? {
        guard let expressionRange = parseExpressionRange(
            startingAt: index
        ) else {
            return nil
        }

        // parseExpressionRange includes infix operators in the expression range,
        // but `!` binds tighter than any infix operator. Scan through the range
        // and stop at the first infix operator (excluding member access `.`).
        var i = index
        while i <= expressionRange.upperBound {
            let token = tokens[i]
            if token.isStartOfScope {
                guard let scopeEnd = endOfScope(at: i) else { break }
                i = scopeEnd + 1
                continue
            }
            if token.isOperator(ofType: .infix), token != .operator(".", .infix) {
                return self.index(of: .nonSpaceOrCommentOrLinebreak, before: i)
            }
            if token == .keyword("is") || token == .keyword("as") {
                return self.index(of: .nonSpaceOrCommentOrLinebreak, before: i)
            }
            i += 1
        }
        return expressionRange.upperBound
    }

    /// Whether the token after `index` is a comparison operator (`==`, `!=`, etc.)
    /// in Swift's non-associative `ComparisonPrecedence` group.
    func isFollowedByComparisonOperator(at index: Int) -> Bool {
        guard let nextIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, after: index),
              case let .operator(op, .infix) = tokens[nextIndex]
        else {
            return false
        }
        return ["==", "!=", "===", "!==", "~=", "<", ">", "<=", ">="].contains(op)
    }
}
