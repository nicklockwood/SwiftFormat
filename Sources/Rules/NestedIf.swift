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
        help: "Merge nested if statements using comma-delimited conditions or else-if chains.",
        sharedOptions: ["linebreaks", "indent", "tab-width", "smart-tabs"]
    ) { formatter in
        formatter.forEach(.keyword("if")) { ifIndex, _ in
            while formatter.mergeNestedIf(at: ifIndex) || formatter.flattenElseIf(at: ifIndex) {}
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

        ```diff
          if isValid {
              performAction()
        - } else {
        -     if isEnabled {
        -         performFallback()
        -     }
        + } else if isEnabled {
        +     performFallback()
          }
        ```
        """
    }
}

extension Formatter {
    /// Flattens an else body containing only an if statement into an else-if chain.
    func flattenElseIf(at ifIndex: Int) -> Bool {
        let branches = ifStatementBranches(at: ifIndex)
        guard !isIfExpression(at: ifIndex),
              // Explicit returns rule out a builder even when its return type looks like one.
              !isInResultBuilder(at: ifIndex) || branches.contains(where: {
                  next(.nonSpaceOrCommentOrLinebreak, after: $0.startOfBranch) == .keyword("return")
              }),
              let outerBranch = branches.last,
              let elseIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: outerBranch.startOfBranch),
              tokens[elseIndex] == .keyword("else"),
              let nestedIfIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: outerBranch.startOfBranch),
              tokens[nestedIfIndex] == .keyword("if"),
              let nestedEnd = ifStatementBranches(at: nestedIfIndex).last?.endOfBranch,
              index(of: .nonSpaceOrCommentOrLinebreak, after: nestedEnd) == outerBranch.endOfBranch,
              !tokens[elseIndex + 1 ..< nestedIfIndex].contains(where: \.isComment),
              !tokens[nestedEnd + 1 ..< outerBranch.endOfBranch].contains(where: \.isComment),
              !tokens[nestedIfIndex ... nestedEnd].contains(where: { token in
                  if case let .commentBody(body) = token {
                      return body.isCommentDirective
                  }
                  return token.isMultilineStringDelimiter
              })
        else { return false }

        let outerIndent = currentIndentForLine(at: elseIndex)
        let nestedIndent = currentIndentForLine(at: nestedIfIndex)
        removeTokens(in: nestedEnd + 1 ... outerBranch.endOfBranch)
        replaceNestedIfIndentation(nestedIndent, with: outerIndent, after: nestedIfIndex, through: nestedEnd)
        replaceTokens(in: elseIndex + 1 ..< nestedIfIndex, with: .space(" "))
        return true
    }

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
              let outerConditionEnd = index(of: .nonSpaceOrCommentOrLinebreak, before: outerBodyStart),
              let outerConditionStart = parseConditionalStatement(at: ifIndex).first?.range.lowerBound,
              let nestedConditionStart = parseConditionalStatement(at: nestedIfIndex).first?.range.lowerBound,
              let nestedConditionEnd = index(of: .nonSpaceOrCommentOrLinebreak, before: nestedBodyStart),
              let conditionCommentLines = nestedIfCommentLines(
                  in: outerBodyStart + 1 ..< nestedIfIndex
              ),
              !tokens[outerConditionEnd + 1 ... outerBodyStart].contains(where: \.isComment)
        else {
            return false
        }

        let separatorRange = outerConditionEnd + 1 ... nestedIfIndex
        let wrapSeparator = conditionCommentLines.isEmpty && (
            conditionsAreWrapped(after: ifIndex, before: outerBodyStart) ||
                conditionsAreWrapped(after: nestedIfIndex, before: nestedBodyStart)
        )
        let conditionIndent = spaceEquivalentToTokens(
            from: startOfLine(at: outerConditionStart), upTo: outerConditionStart
        )
        let trailingRange = nestedBodyEnd + 1 ... outerBodyEnd

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

        if wrapSeparator, let nestedContentStart = index(of: .nonSpaceOrLinebreak, after: nestedIfIndex) {
            replaceTokens(in: outerConditionEnd + 1 ..< nestedContentStart,
                          with: [.delimiter(","), linebreakToken(for: ifIndex)])
        } else if conditionCommentLines.isEmpty {
            replaceTokens(in: separatorRange, with: .delimiter(","))
        } else {
            let linebreak = linebreakToken(for: ifIndex)
            let conditionIndent = spaceEquivalentToTokens(
                from: startOfLine(at: ifIndex),
                upTo: outerConditionStart
            )
            let indentedLinebreak: [Token] = conditionIndent.isEmpty ?
                [linebreak] : [linebreak, .space(conditionIndent)]

            replaceTokens(
                in: nestedConditionEnd + 1 ..< nestedBodyStart,
                with: outerIndent.isEmpty ? [linebreak] : [linebreak, .space(outerIndent)]
            )

            var separator = [Token.delimiter(",")]
            separator.append(contentsOf: indentedLinebreak)
            for commentLine in conditionCommentLines {
                separator.append(contentsOf: commentLine)
                separator.append(contentsOf: indentedLinebreak)
            }
            replaceTokens(in: outerConditionEnd + 1 ..< nestedConditionStart, with: separator)
        }

        if let mergedBodyStart = startOfConditionalBranchBody(after: ifIndex),
           let mergedBodyEnd = endOfScope(at: mergedBodyStart)
        {
            let indentationEnd = trailingCommentIndex.map {
                startOfLine(at: $0.index) - 2
            } ?? mergedBodyEnd
            replaceNestedIfIndentation(
                nestedIndent,
                with: outerIndent,
                after: outerConditionEnd,
                through: indentationEnd
            )
        }
        if wrapSeparator {
            insertSpace(conditionIndent, at: outerConditionEnd + 3)
        }
        return true
    }

    /// Returns standalone comment lines in a range, without their original indentation.
    func nestedIfCommentLines(in range: Range<Int>) -> [[Token]]? {
        guard tokens[range].contains(where: \.isComment) else {
            return []
        }
        guard !tokens[range].contains(where: { token in
            if case let .commentBody(body) = token {
                return body.isCommentDirective
            }
            return false
        }) else {
            return nil
        }

        var commentLines = [[Token]]()
        for line in tokens[range].split(omittingEmptySubsequences: false, whereSeparator: \.isLinebreak) {
            let content = line.drop(while: \.isSpace).reversed().drop(while: \.isSpace).reversed()
            guard content.allSatisfy({ $0.isComment || $0.isSpace }) else { return nil }
            if !content.isEmpty {
                commentLines.append(Array(content))
            }
        }
        return commentLines
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
