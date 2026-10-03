//
//  NestedIf.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 10/3/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Merge nested if statements when each outer branch contains only another if statement.
    static let nestedIf = FormatRule(
        help: "Merge nested if statements into a single statement with comma-delimited conditions."
    ) { formatter in
        formatter.forEach(.keyword("if")) { ifIndex, _ in
            while formatter.mergeNestedIf(at: ifIndex) {}
        }
    } examples: {
        """
        ```diff
        - if isValid {
        -     if isEnabled {
        + if isValid, isEnabled {
                  performAction()
        -     }
          }
        ```
        """
    }
}

extension Formatter {
    /// Merges an if statement that is the only statement in the body of the if at `ifIndex`.
    func mergeNestedIf(at ifIndex: Int) -> Bool {
        guard tokens[ifIndex] == .keyword("if"),
              !isIfExpression(at: ifIndex),
              !isInResultBuilder(at: ifIndex),
              let outerBodyStart = startOfConditionalBranchBody(after: ifIndex),
              let outerBodyEnd = endOfScope(at: outerBodyStart),
              index(of: .nonSpaceOrCommentOrLinebreak, after: outerBodyEnd).map({
                  tokens[$0] != .keyword("else")
              }) ?? true,
              let nestedIfIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: outerBodyStart),
              nestedIfIndex < outerBodyEnd,
              tokens[nestedIfIndex] == .keyword("if"),
              !isIfExpression(at: nestedIfIndex),
              let nestedBodyStart = startOfConditionalBranchBody(after: nestedIfIndex),
              let nestedBodyEnd = endOfScope(at: nestedBodyStart),
              !tokens[nestedIfIndex ... nestedBodyEnd].contains(where: \.isMultilineStringDelimiter),
              index(of: .nonSpaceOrCommentOrLinebreak, before: outerBodyEnd) == nestedBodyEnd,
              index(of: .nonSpaceOrCommentOrLinebreak, after: nestedBodyEnd).map({
                  tokens[$0] != .keyword("else")
              }) ?? true,
              let outerConditionEnd = index(of: .nonSpaceOrCommentOrLinebreak, before: outerBodyStart)
        else {
            return false
        }

        let separatorRange = outerConditionEnd + 1 ... nestedIfIndex
        let trailingRange = nestedBodyEnd + 1 ... outerBodyEnd
        guard !tokens[separatorRange].contains(where: \.isComment) else {
            return false
        }

        let outerIndent = currentIndentForLine(at: ifIndex)
        let nestedIndent = currentIndentForLine(at: nestedIfIndex)
        let trailingCommentIndex = tokens[trailingRange].firstIndex(where: \.isComment).map {
            AutoUpdatingIndex(index: $0, formatter: self)
        }

        if let trailingCommentIndex {
            let closingBraceLineStart = startOfLine(at: nestedBodyEnd)
            if index(of: .nonSpaceOrCommentOrLinebreak, in: closingBraceLineStart ..< nestedBodyEnd) == nil,
               !onSameLine(nestedBodyEnd, trailingCommentIndex.index)
            {
                removeTokens(in: closingBraceLineStart ... endOfLine(at: nestedBodyEnd))
            } else if onSameLine(nestedBodyEnd, trailingCommentIndex.index) {
                removeTokens(in: nestedBodyEnd ..< trailingCommentIndex.index)
            } else {
                removeToken(at: nestedBodyEnd)
            }
        } else {
            removeTokens(in: trailingRange)
        }
        replaceTokens(in: separatorRange, with: .delimiter(","))

        if let mergedBodyStart = startOfConditionalBranchBody(after: ifIndex),
           let mergedBodyEnd = endOfScope(at: mergedBodyStart)
        {
            let indentationEnd = trailingCommentIndex.map {
                startOfLine(at: $0.index) - 2
            } ?? mergedBodyEnd
            replaceNestedIfIndentation(
                nestedIndent,
                with: outerIndent,
                after: ifIndex,
                through: indentationEnd
            )
        }
        return true
    }

    /// Replaces the indentation prefix on each line in a range, working backwards to keep indices stable.
    func replaceNestedIfIndentation(
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

        if case let .space(indent) = token(at: linebreakIndex + 1),
           indent.hasPrefix(oldIndent)
        {
            insertSpace(newIndent + indent.dropFirst(oldIndent.count), at: linebreakIndex + 1)
        }

        replaceNestedIfIndentation(oldIndent, with: newIndent, after: lowerBound, through: linebreakIndex - 1)
    }
}
