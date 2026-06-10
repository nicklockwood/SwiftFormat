//
//  WrapIfStatementBodies.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 6/10/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let wrapIfStatementBodies = FormatRule(
        help: "Wrap the bodies of inline if/else statements onto a new line.",
        disabledByDefault: true,
        sharedOptions: ["linebreaks", "indent"]
    ) { formatter in
        formatter.forEachToken(where: { [.keyword("if"), .keyword("else")].contains($0) }) { i, _ in
            // Skip if this `if` is being used as an expression
            if formatter.tokens[i] == .keyword("if"),
               formatter.isIfExpression(at: i)
            {
                return
            }

            // For `else`, check if it belongs to an if expression or a guard
            if formatter.tokens[i] == .keyword("else") {
                // Check via startOfConditionalStatement (works for guard else and simple if/else)
                if let startOfStatement = formatter.startOfConditionalStatement(at: i) {
                    if formatter.tokens[startOfStatement] == .keyword("guard") {
                        return
                    }
                    if formatter.tokens[startOfStatement] == .keyword("if"),
                       formatter.isIfExpression(at: startOfStatement)
                    {
                        return
                    }
                }

                // Also check via the preceding `}` for if/else-if chains where
                // startOfConditionalStatement may fail due to intervening braces
                if let closingBrace = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i),
                   formatter.tokens[closingBrace] == .endOfScope("}"),
                   let openingBrace = formatter.startOfScope(at: closingBrace),
                   let startOfStatement = formatter.startOfConditionalStatement(at: openingBrace)
                {
                    if formatter.tokens[startOfStatement] == .keyword("guard") {
                        return
                    }
                    if formatter.tokens[startOfStatement] == .keyword("if"),
                       formatter.isIfExpression(at: startOfStatement)
                    {
                        return
                    }
                }
            }

            guard let startIndex = formatter.index(of: .startOfScope("{"), after: i) else {
                return formatter.fatalError("Expected {", at: i)
            }
            formatter.wrapStatementBody(at: startIndex)
        }
    } examples: {
        """
        ```diff
        - if foo { return bar }
        + if foo {
        +     return bar
        + }
        ```

        ```diff
        - if foo { return bar } else if baz { return qux } else { return quux }
        + if foo {
        +     return bar
        + } else if baz {
        +     return qux
        + } else {
        +     return quux
        + }
        ```
        """
    }
}

extension Formatter {
    /// Returns true if the `if` keyword at the given index is being used as an if expression
    /// (as opposed to an if statement). If expressions can appear in three locations:
    /// 1. Immediately following an `=` operator (`let foo = if ...`)
    /// 2. As the single expression in a function/var/closure body
    /// 3. Nested within other if/switch expressions
    func isIfExpression(at i: Int) -> Bool {
        guard tokens[i] == .keyword("if") else { return false }

        // Case 1: Following an `=` operator (possibly with try/await in between)
        if isConditionalAssignment(at: i) {
            return true
        }

        // Also check for `= try if`, `= await if`, `= try await if`, etc.
        if isPrecededByEqualsWithOptionalTryAwait(at: i) {
            return true
        }

        // Check if this is an `else if` where the parent `if` is an expression
        if let prevToken = lastToken(before: i, where: { !$0.isSpaceOrCommentOrLinebreak }),
           prevToken == .keyword("else")
        {
            // Find the parent if by looking at the `}` before `else`
            if let elseIndex = index(of: .keyword("else"), before: i),
               let closingBrace = index(of: .nonSpaceOrCommentOrLinebreak, before: elseIndex),
               tokens[closingBrace] == .endOfScope("}"),
               let openingBrace = startOfScope(at: closingBrace),
               let startOfStatement = startOfConditionalStatement(at: openingBrace),
               tokens[startOfStatement] == .keyword("if")
            {
                return isIfExpression(at: startOfStatement)
            }
        }

        // Case 2: Single expression in a function/var/closure body
        // Case 3: Nested within other if/switch expressions (which are themselves in a body or assignment)
        // We check if this `if` is the first token inside a scope that expects a return value
        guard let startOfScope = index(of: .startOfScope("{"), before: i),
              let firstTokenInScope = index(of: .nonSpaceOrCommentOrLinebreak, after: startOfScope),
              // Make sure we're looking at the `if` directly (possibly preceded by try/await)
              ifKeywordMatchesScopeStart(ifIndex: i, firstTokenInScope: firstTokenInScope)
        else {
            return false
        }

        // Check if the enclosing scope is a function/var/closure body (not a conditional body)
        if isStartOfClosure(at: startOfScope) {
            // It's a closure body - check if this if is the only expression
            return scopeBodyIsSingleExpression(at: startOfScope)
        }

        // Check if it's a function/var body
        if !isConditionalStatement(at: startOfScope, excluding: ["where"]) {
            let lastKeyword = lastSignificantKeyword(at: startOfScope, excluding: ["throws", "where"])
            if ["func", "var", "get", "set"].contains(lastKeyword) || lastKeyword == "" {
                return scopeBodyIsSingleExpression(at: startOfScope)
            }
        }

        // Case 3: Check if we're inside an if/switch expression branch body
        if isConditionalStatement(at: startOfScope) {
            // This is inside a branch of another if/switch - check if the parent is an expression
            if let parentKeyword = indexOfLastSignificantKeyword(at: startOfScope, excluding: ["else"]),
               tokens[parentKeyword] == .keyword("if")
            {
                return isIfExpression(at: parentKeyword)
            }
        }

        return false
    }

    /// Checks if the `if` keyword at `ifIndex` is the expression starting at `firstTokenInScope`
    /// (accounting for `try` / `await` prefixes)
    private func ifKeywordMatchesScopeStart(ifIndex: Int, firstTokenInScope: Int) -> Bool {
        if firstTokenInScope == ifIndex {
            return true
        }
        // Allow `try`, `try?`, `try!`, `await` before the if
        var current = firstTokenInScope
        while ["try", "await"].contains(tokens[current].string) {
            guard let next = index(of: .nonSpaceOrCommentOrLinebreak, after: current) else {
                return false
            }
            // Skip `?` or `!` after `try`
            if tokens[current].string == "try", tokens[next].isUnwrapOperator {
                guard let afterOperator = index(of: .nonSpaceOrCommentOrLinebreak, after: next) else {
                    return false
                }
                current = afterOperator
            } else {
                current = next
            }
        }
        return current == ifIndex
    }

    /// Checks if the `if` at `ifIndex` is preceded by `= [try|await]* if`
    private func isPrecededByEqualsWithOptionalTryAwait(at ifIndex: Int) -> Bool {
        var current = ifIndex
        // Walk backwards past try/await keywords
        while let prev = index(of: .nonSpaceOrCommentOrLinebreak, before: current) {
            if tokens[prev].isUnwrapOperator,
               let beforeOp = index(of: .nonSpaceOrCommentOrLinebreak, before: prev),
               tokens[beforeOp] == .keyword("try")
            {
                current = beforeOp
            } else if tokens[prev] == .keyword("try") || tokens[prev] == .keyword("await") {
                current = prev
            } else {
                break
            }
        }
        // Now check if what precedes is `=`
        guard let prev = lastToken(before: current, where: { !$0.isSpaceOrCommentOrLinebreak }) else {
            return false
        }
        return prev.isOperator("=")
    }
}
