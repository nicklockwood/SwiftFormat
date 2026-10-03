//
//  PreferForWhere.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 04/10/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Move a single if statement inside a for loop into the loop's where clause.
    static let preferForWhere = FormatRule(
        help: "Prefer a `where` clause over a single `if` statement inside a `for` loop.",
        orderAfter: [.andOperator, .preferForLoop]
    ) { formatter in
        formatter.forEach(.keyword("for")) { forIndex, _ in
            formatter.convertIfToForWhere(at: forIndex)
        }
    } examples: {
        """
        ```diff
        - for child in visibleChildren {
        -     if !child.buildPreview(progress) {
        + for child in visibleChildren where !child.buildPreview(progress) {
                  return false
        -     }
          }
        ```
        """
    }
}

extension Formatter {
    /// Converts an if statement that is the only statement in a for loop body to a where clause.
    func convertIfToForWhere(at forIndex: Int) {
        guard tokens[forIndex] == .keyword("for"),
              let inIndex = index(of: .keyword("in"), after: forIndex),
              let loopBodyStart = startOfForLoopBody(after: inIndex),
              index(of: .keyword("where"), in: inIndex + 1 ..< loopBodyStart) == nil,
              let loopBodyEnd = endOfScope(at: loopBodyStart),
              let ifIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: loopBodyStart),
              ifIndex < loopBodyEnd,
              tokens[ifIndex] == .keyword("if"),
              let ifBodyStart = startOfConditionalBranchBody(after: ifIndex),
              let ifBodyEnd = endOfScope(at: ifBodyStart),
              index(of: .nonSpaceOrCommentOrLinebreak, after: ifBodyEnd) == loopBodyEnd,
              let loopHeaderEnd = index(of: .nonSpaceOrCommentOrLinebreak, before: loopBodyStart),
              let conditionEnd = index(of: .nonSpaceOrCommentOrLinebreak, before: ifBodyStart),
              !tokens[loopHeaderEnd + 1 ..< ifBodyStart].contains(where: \.isComment),
              !tokens[ifIndex ..< ifBodyStart].contains(where: \.isLinebreak),
              !tokens[ifIndex ... ifBodyEnd].contains(where: \.isMultilineStringDelimiter),
              !tokens[ifBodyEnd + 1 ... loopBodyEnd].contains(where: \.isComment)
        else {
            return
        }

        let conditions = parseConditionalStatement(at: ifIndex)
        guard !conditions.isEmpty,
              conditions.allSatisfy({ condition in
                  if case .booleanExpression = condition {
                      return true
                  }
                  return false
              }),
              conditions.last?.range.upperBound == conditionEnd
        else {
            return
        }

        var whereClause: [Token] = [
            .space(" "),
            .keyword("where"),
            .space(" "),
        ]
        for (offset, condition) in conditions.enumerated() {
            if offset > 0 {
                whereClause.append(contentsOf: [
                    .space(" "),
                    .operator("&&", .infix),
                    .space(" "),
                ])
            }
            whereClause.append(contentsOf: tokens[condition.range])
        }
        whereClause.append(.space(" "))

        let loopIndent = currentIndentForLine(at: forIndex)
        let ifIndent = currentIndentForLine(at: ifIndex)

        removeTokens(in: ifBodyEnd + 1 ... loopBodyEnd)
        replaceTokens(in: loopHeaderEnd + 1 ..< ifBodyStart, with: whereClause)

        if let bodyStart = startOfForLoopBody(after: inIndex),
           let bodyEnd = endOfScope(at: bodyStart)
        {
            replaceForWhereIndentation(
                ifIndent,
                with: loopIndent,
                after: forIndex,
                through: bodyEnd
            )
        }
    }

    /// Returns the opening brace of the for loop body, skipping closures in the sequence expression.
    func startOfForLoopBody(after index: Int) -> Int? {
        guard let startOfBody = self.index(of: .startOfScope("{"), after: index) else {
            return nil
        }
        if isStartOfClosure(at: startOfBody), let endOfClosure = endOfScope(at: startOfBody) {
            return startOfForLoopBody(after: endOfClosure)
        }
        return startOfBody
    }

    /// Replaces the indentation prefix on each line after removing the nested if scope.
    func replaceForWhereIndentation(
        _ oldIndent: String,
        with newIndent: String,
        after lowerBound: Int,
        through upperBound: Int
    ) {
        guard oldIndent != newIndent,
              let linebreakIndex = tokens[lowerBound ... upperBound].lastIndex(where: \.isLinebreak),
              linebreakIndex > lowerBound
        else {
            return
        }

        if case let .space(indent) = token(at: linebreakIndex + 1), indent.hasPrefix(oldIndent) {
            insertSpace(newIndent + indent.dropFirst(oldIndent.count), at: linebreakIndex + 1)
        }

        replaceForWhereIndentation(
            oldIndent,
            with: newIndent,
            after: lowerBound,
            through: linebreakIndex - 1
        )
    }
}
