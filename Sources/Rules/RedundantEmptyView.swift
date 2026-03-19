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
    func redundantEmptyViewElseRange(at elseKeywordIndex: Int) -> ClosedRange<Int>? {
        guard isInResultBuilder(at: elseKeywordIndex),
              next(.nonSpaceOrCommentOrLinebreak, after: elseKeywordIndex) != .keyword("if"),
              let previousTokenIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: elseKeywordIndex),
              tokens[previousTokenIndex] == .endOfScope("}"),
              tokens[(previousTokenIndex + 1) ..< elseKeywordIndex].allSatisfy(\.isSpaceOrLinebreak),
              let startOfElseBody = index(of: .nonSpaceOrCommentOrLinebreak, after: elseKeywordIndex),
              tokens[startOfElseBody] == .startOfScope("{"),
              tokens[(elseKeywordIndex + 1) ..< startOfElseBody].allSatisfy(\.isSpaceOrLinebreak),
              let endOfElseBody = endOfScope(at: startOfElseBody),
              let firstTokenInElseBody = index(of: .nonSpaceOrCommentOrLinebreak, after: startOfElseBody),
              let elseExpressionRange = parseExpressionRange(startingAt: firstTokenInElseBody),
              index(of: .nonSpaceOrCommentOrLinebreak, after: elseExpressionRange.upperBound) == endOfElseBody,
              tokens[(startOfElseBody + 1) ..< firstTokenInElseBody].allSatisfy(\.isSpaceOrLinebreak),
              tokens[(elseExpressionRange.upperBound + 1) ..< endOfElseBody].allSatisfy(\.isSpaceOrLinebreak),
              expressionIsEmptyView(in: elseExpressionRange)
        else {
            return nil
        }

        return (previousTokenIndex + 1) ... endOfElseBody
    }

    func expressionIsEmptyView(in expressionRange: ClosedRange<Int>) -> Bool {
        var emptyViewIdentifierIndex = expressionRange.lowerBound

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
