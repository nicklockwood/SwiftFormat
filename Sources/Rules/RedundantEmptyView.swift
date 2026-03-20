//
//  RedundantEmptyView.swift
//  SwiftFormat
//
//  Created by Manuel Lopez on 2026-03-19.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove redundant `else { EmptyView() }` in result builders
    static let redundantEmptyView = FormatRule(
        help: "Remove redundant `else { EmptyView() }` branches in SwiftUI result builders."
    ) { formatter in
        formatter.forEach(.keyword("else")) { elseIndex, _ in
            guard let redundantElseRange = formatter.redundantEmptyViewElseRange(at: elseIndex) else {
                return
            }
            formatter.removeTokens(in: redundantElseRange)
        }
    } examples: {
        """
        ```diff
          var body: some View {
              if condition {
                  Text("Hello")
        -     } else {
        -         EmptyView()
              }
          }
        ```
        """
    }
}

extension Formatter {
    /// Returns the range to remove if the `else` at `elseKeywordIndex` is a redundant
    /// `else { EmptyView() }` in a result builder, or `nil` if it should be preserved.
    func redundantEmptyViewElseRange(at elseKeywordIndex: Int) -> ClosedRange<Int>? {
        guard isInResultBuilder(at: elseKeywordIndex),
              // Skip `else if` chains — only plain `else` can be redundant
              next(.nonSpaceOrCommentOrLinebreak, after: elseKeywordIndex) != .keyword("if"),
              // Verify the preceding if-body closes with `}`
              let previousTokenIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: elseKeywordIndex),
              tokens[previousTokenIndex] == .endOfScope("}"),
              // Preserve comments between `}` and `else`
              tokens[(previousTokenIndex + 1) ..< elseKeywordIndex].allSatisfy(\.isSpaceOrLinebreak),
              let startOfElseBody = index(of: .nonSpaceOrCommentOrLinebreak, after: elseKeywordIndex),
              tokens[startOfElseBody] == .startOfScope("{"),
              tokens[(elseKeywordIndex + 1) ..< startOfElseBody].allSatisfy(\.isSpaceOrLinebreak),
              let endOfElseBody = endOfScope(at: startOfElseBody),
              // Verify the else body contains exactly one expression, with no comments
              let firstTokenInElseBody = index(of: .nonSpaceOrCommentOrLinebreak, after: startOfElseBody),
              let elseExpressionRange = parseExpressionRange(startingAt: firstTokenInElseBody),
              index(of: .nonSpaceOrCommentOrLinebreak, after: elseExpressionRange.upperBound) == endOfElseBody,
              tokens[(startOfElseBody + 1) ..< firstTokenInElseBody].allSatisfy(\.isSpaceOrLinebreak),
              tokens[(elseExpressionRange.upperBound + 1) ..< endOfElseBody].allSatisfy(\.isSpaceOrLinebreak),
              expressionIsEmptyView(in: elseExpressionRange)
        else {
            return nil
        }

        // Remove from after the if-body `}` through the else-body `}`
        return (previousTokenIndex + 1) ... endOfElseBody
    }

    /// Whether the expression in the given range is `EmptyView()` or `SwiftUI.EmptyView()`
    /// with no arguments and no modifiers.
    func expressionIsEmptyView(in expressionRange: ClosedRange<Int>) -> Bool {
        var emptyViewIdentifierIndex = expressionRange.lowerBound

        // Handle fully-qualified `SwiftUI.EmptyView()`
        if tokens[emptyViewIdentifierIndex] == .identifier("SwiftUI") {
            guard let dotIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: emptyViewIdentifierIndex),
                  tokens[dotIndex] == .operator(".", .infix),
                  let nextIdentifierIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: dotIndex),
                  tokens[nextIdentifierIndex] == .identifier("EmptyView")
            else {
                return false
            }
            emptyViewIdentifierIndex = nextIdentifierIndex
        }

        // Verify it's `EmptyView()` with no arguments and no trailing modifiers
        guard tokens[emptyViewIdentifierIndex] == .identifier("EmptyView"),
              let startOfArguments = index(of: .nonSpaceOrCommentOrLinebreak, after: emptyViewIdentifierIndex),
              tokens[startOfArguments] == .startOfScope("("),
              let endOfArguments = endOfScope(at: startOfArguments),
              endOfArguments == expressionRange.upperBound,
              tokens[(emptyViewIdentifierIndex + 1) ..< startOfArguments].allSatisfy(\.isSpaceOrLinebreak),
              tokens[(startOfArguments + 1) ..< endOfArguments].allSatisfy(\.isSpaceOrLinebreak)
        else {
            return false
        }

        return true
    }
}
