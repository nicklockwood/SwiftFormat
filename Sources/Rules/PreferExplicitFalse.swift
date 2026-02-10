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

            // Skip if adjacent to a comparison or casting operator —
            // inserting `== false` would create a non-associative chain
            // or change precedence. e.g., `a == !b` → `a == b == false`
            if let prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: notIndex),
               formatter.isComparisonOrCastingOperator(at: prevIndex)
            {
                return
            }

            guard let operandEnd = formatter.endOfPrefixOperand(
                at: operandStart
            ) else {
                return
            }

            if let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: operandEnd),
               formatter.isComparisonOrCastingOperator(at: nextIndex)
            {
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
    static let comparisonOperators: Set<String> = [
        "==", "!=", "===", "!==", "~=", "<", ">", "<=", ">=",
    ]

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
        // but `!` binds tighter than any infix operator. Find the earliest
        // infix operator (excluding member access `.`) or `is`/`as` keyword.
        let searchRange = index ..< expressionRange.upperBound + 1
        let infixIndex = self.index(in: searchRange, where: {
            $0.isOperator(ofType: .infix) && $0 != .operator(".", .infix)
        })
        let isIndex = self.index(of: .keyword("is"), in: index ... expressionRange.upperBound)
        let asIndex = self.index(of: .keyword("as"), in: index ... expressionRange.upperBound)

        if let breakIndex = [infixIndex, isIndex, asIndex].compactMap({ $0 }).min() {
            return self.index(of: .nonSpaceOrCommentOrLinebreak, before: breakIndex)
        }

        return expressionRange.upperBound
    }

    /// Whether the token at `index` is a comparison operator (`==`, `!=`, etc.)
    /// or a casting keyword (`is`, `as`) — operators that would conflict with
    /// an inserted `== false`.
    func isComparisonOrCastingOperator(at index: Int) -> Bool {
        let token = tokens[index]
        if case let .operator(op, .infix) = token {
            return Self.comparisonOperators.contains(op)
        }
        return token == .keyword("is") || token == .keyword("as")
    }
}
