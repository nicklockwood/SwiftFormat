//
//  RepeatedGuard.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 10/3/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Merge consecutive guard statements that have identical bodies.
    static let repeatedGuard = FormatRule(
        help: "Merge consecutive guard statements that have identical bodies.",
        sharedOptions: ["linebreaks", "indent", "tab-width", "smart-tabs"]
    ) { formatter in
        formatter.forEach(.keyword("guard")) { guardIndex, _ in
            while formatter.mergeGuardFollowingGuard(at: guardIndex) {}
        }
    } examples: {
        """
        ```diff
        - guard isValid else { return }
        - guard isEnabled else { return }
        + guard isValid, isEnabled else { return }
        ```

        ```diff
        - // The value must be valid.
        - guard isValid else { return }
        - guard isEnabled else { return }
        + guard
        +     // The value must be valid.
        +     isValid,
        +     isEnabled
        + else { return }
        ```
        """
    }
}

extension Formatter {
    /// Merges the guard immediately following the guard at `guardIndex`, if possible.
    func mergeGuardFollowingGuard(at guardIndex: Int) -> Bool {
        guard let firstGuard = repeatedGuardParts(at: guardIndex),
              let nextGuardIndex = index(
                  of: .nonSpaceOrCommentOrLinebreak,
                  after: firstGuard.bodyRange.upperBound
              ),
              tokens[nextGuardIndex] == .keyword("guard"),
              let secondGuard = repeatedGuardParts(at: nextGuardIndex),
              repeatedGuardBodiesMatch(firstGuard.bodyRange, secondGuard.bodyRange),
              let firstNames = namesDeclaredByRepeatedGuard(at: guardIndex),
              namesDeclaredByRepeatedGuard(at: nextGuardIndex) != nil,
              !firstNames.contains(where: { name in
                  tokens[secondGuard.bodyRange].contains(.identifier(name))
              }),
              let firstConditionEnd = index(
                  of: .nonSpaceOrCommentOrLinebreak,
                  before: firstGuard.elseIndex
              ),
              let firstConditionStart = parseConditionalStatement(at: guardIndex).first?.range.lowerBound,
              let secondConditionStart = parseConditionalStatement(at: nextGuardIndex).first?.range.lowerBound,
              let secondConditionEnd = index(
                  of: .nonSpaceOrCommentOrLinebreak,
                  before: secondGuard.elseIndex
              )
        else {
            return false
        }

        let leadingCommentRange = parseDocCommentRange(forDeclarationAt: guardIndex)
        let leadingCommentLines: [[Token]]?
        if let leadingCommentRange {
            leadingCommentLines = repeatedGuardCommentLines(
                in: Range(leadingCommentRange),
                requireLeadingLinebreak: false
            )
        } else {
            leadingCommentLines = []
        }
        guard let leadingCommentLines,
              let firstConditionCommentLines = repeatedGuardCommentLines(
                  in: guardIndex + 1 ..< firstConditionStart
              ),
              let commentLinesBeforeSecondGuard = repeatedGuardCommentLines(
                  in: firstGuard.bodyRange.upperBound + 1 ..< nextGuardIndex
              ),
              let commentLinesAfterSecondGuard = repeatedGuardCommentLines(
                  in: nextGuardIndex + 1 ..< secondConditionStart
              )
        else {
            return false
        }
        let firstCommentLines = leadingCommentLines + firstConditionCommentLines
        let secondCommentLines = commentLinesBeforeSecondGuard + commentLinesAfterSecondGuard

        let isMultiline = !firstCommentLines.isEmpty || !secondCommentLines.isEmpty ||
            tokens[guardIndex ..< firstGuard.elseIndex].contains(where: \.isLinebreak) ||
            tokens[nextGuardIndex ..< secondGuard.elseIndex].contains(where: \.isLinebreak)

        if isMultiline {
            let indent = currentIndentForLine(at: guardIndex)
            let firstConditionIsInline = !tokens[guardIndex ..< firstConditionStart].contains(where: \.isLinebreak)
            let conditionIndent = firstCommentLines.isEmpty && firstConditionIsInline ?
                spaceEquivalentToTokens(from: startOfLine(at: guardIndex), upTo: firstConditionStart) :
                indent + options.indent
            let linebreak = linebreakToken(for: guardIndex)
            let indentedLinebreak: [Token] = conditionIndent.isEmpty ?
                [linebreak] : [linebreak, .space(conditionIndent)]

            let beforeElseRange = secondConditionEnd + 1 ..< secondGuard.elseIndex
            guard !tokens[beforeElseRange].contains(where: \.isComment) else {
                return false
            }
            replaceTokens(
                in: beforeElseRange,
                with: indent.isEmpty ? [linebreak] : [linebreak, .space(indent)]
            )

            var separator = [Token.delimiter(",")]
            separator.append(contentsOf: indentedLinebreak)
            for commentLine in secondCommentLines {
                separator.append(contentsOf: commentLine)
                separator.append(contentsOf: indentedLinebreak)
            }
            replaceTokens(in: firstConditionEnd + 1 ..< secondConditionStart, with: separator)

            if !firstCommentLines.isEmpty {
                var prefix = indentedLinebreak
                for commentLine in firstCommentLines {
                    prefix.append(contentsOf: commentLine)
                    prefix.append(contentsOf: indentedLinebreak)
                }
                replaceTokens(in: guardIndex + 1 ..< firstConditionStart, with: prefix)
            }

            if let leadingCommentRange {
                replaceTokens(
                    in: startOfLine(at: leadingCommentRange.lowerBound) ..< guardIndex,
                    with: indent.isEmpty ? [] : [.space(indent)]
                )
            }
        } else {
            replaceTokens(
                in: firstConditionEnd + 1 ... nextGuardIndex,
                with: .delimiter(",")
            )
        }
        return true
    }

    /// Returns standalone comment lines in a range, without their original indentation.
    func repeatedGuardCommentLines(
        in range: Range<Int>,
        requireLeadingLinebreak: Bool = true
    ) -> [[Token]]? {
        guard let firstCommentIndex = tokens[range].firstIndex(where: \.isComment) else {
            return []
        }
        guard !requireLeadingLinebreak ||
            tokens[range.lowerBound ..< firstCommentIndex].contains(where: \.isLinebreak),
            !tokens[range].contains(where: { token in
                if case let .commentBody(body) = token {
                    return body.isCommentDirective
                }
                return false
            })
        else {
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

    /// Returns the `else` keyword and body range for the guard at `guardIndex`.
    func repeatedGuardParts(at guardIndex: Int) -> (elseIndex: Int, bodyRange: ClosedRange<Int>)? {
        guard tokens[guardIndex] == .keyword("guard"),
              let elseIndex = index(of: .keyword("else"), after: guardIndex),
              let bodyStart = index(of: .startOfScope("{"), after: elseIndex),
              let bodyEnd = endOfScope(at: bodyStart)
        else {
            return nil
        }
        return (elseIndex, bodyStart ... bodyEnd)
    }

    /// Compares guard bodies without considering their whitespace formatting.
    func repeatedGuardBodiesMatch(_ lhs: ClosedRange<Int>, _ rhs: ClosedRange<Int>) -> Bool {
        let lhsTokens = tokens[lhs].filter { !$0.isSpaceOrLinebreak }
        let rhsTokens = tokens[rhs].filter { !$0.isSpaceOrLinebreak }
        guard !lhsTokens.contains(where: \.isComment),
              !rhsTokens.contains(where: \.isComment)
        else {
            return false
        }
        return lhsTokens == rhsTokens
    }

    /// Returns names that may be introduced by a guard.
    func namesDeclaredByRepeatedGuard(at guardIndex: Int) -> Set<String>? {
        let conditions = parseConditionalStatement(at: guardIndex)
        guard !conditions.isEmpty else { return nil }

        var names = Set<String>()
        for condition in conditions {
            switch condition {
            case let .optionalBinding(_, property):
                names.insert(property.identifier)
            case let .patternMatching(range):
                guard let equalsIndex = index(of: .operator("=", .infix), in: range) else {
                    return nil
                }
                names.formUnion(tokens[range.lowerBound ..< equalsIndex].compactMap { token in
                    guard case let .identifier(name) = token, name != "_" else { return nil }
                    return name
                })
            case .availabilityCondition, .booleanExpression:
                break
            }
        }
        return names
    }
}
