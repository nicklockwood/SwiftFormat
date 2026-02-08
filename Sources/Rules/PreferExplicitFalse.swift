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

            guard let operandEnd = formatter.endOfPrefixNegationOperand(
                startingAt: operandStart
            ) else {
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
    /// first non-space token after a prefix `!`. This includes member access chains,
    /// method calls, subscripts, and postfix operators, but stops before infix
    /// operators, `is`/`as`, trailing closures, or linebreaks.
    func endOfPrefixNegationOperand(startingAt index: Int) -> Int? {
        var endOfExpression: Int
        switch tokens[index] {
        case .identifier:
            endOfExpression = index

        case .startOfScope("("), .startOfScope("["):
            guard let end = endOfScope(at: index) else { return nil }
            endOfExpression = end

        case let .keyword(keyword) where keyword.isMacroOrCompilerDirective:
            endOfExpression = index

        default:
            return nil
        }

        while let nextTokenIndex = self.index(
            of: .nonSpaceOrCommentOrLinebreak,
            after: endOfExpression
        ), let nextToken = token(at: nextTokenIndex) {
            switch nextToken {
            case .startOfScope("("), .startOfScope("["), .startOfScope("<"):
                if tokens[endOfExpression ..< nextTokenIndex].contains(where: \.isLinebreak) {
                    return endOfExpression
                }
                guard let end = endOfScope(at: nextTokenIndex) else { return nil }
                endOfExpression = end

            case .delimiter("."), .operator(".", _):
                guard let nextIdentIndex = self.index(
                    of: .nonSpaceOrCommentOrLinebreak,
                    after: nextTokenIndex
                ), tokens[nextIdentIndex].isIdentifier else {
                    return endOfExpression
                }
                endOfExpression = nextIdentIndex

            case .operator(_, .postfix):
                endOfExpression = nextTokenIndex

            default:
                return endOfExpression
            }
        }

        return endOfExpression
    }
}
