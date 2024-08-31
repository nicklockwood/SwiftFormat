//
//  SortSwitchCases.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 8/13/23.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Sorts switch cases alphabetically
    static let sortSwitchCases = FormatRule(
        help: "Sort switch cases alphabetically.",
        disabledByDefault: true
    ) { formatter in
        formatter.parseSwitchCaseRanges()
            .reversed() // don't mess with indexes
            .forEach { switchCaseRanges in
                guard switchCaseRanges.count > 1, // nothing to sort
                      let firstCaseIndex = switchCaseRanges.first?.beforeDelimiterRange.lowerBound else { return }

                let indentCounts = switchCaseRanges.map { formatter.currentIndentForLine(at: $0.beforeDelimiterRange.lowerBound).count }
                let maxIndentCount = indentCounts.max() ?? 0

                let sorted = switchCaseRanges.sorted { case1, case2 -> Bool in
                    let lhs = formatter.tokens[case1.beforeDelimiterRange]
                        .compactMap(formatter.sortableValue)
                    let rhs = formatter.tokens[case2.beforeDelimiterRange]
                        .compactMap(formatter.sortableValue)
                    for (lhs, rhs) in zip(lhs, rhs) {
                        switch lhs.localizedStandardCompare(rhs) {
                        case .orderedAscending:
                            return true
                        case .orderedDescending:
                            return false
                        case .orderedSame:
                            continue
                        }
                    }
                    return lhs.count < rhs.count
                }

                let sortedTokens = sorted.map { formatter.tokens[$0.beforeDelimiterRange] }
                let sortedComments = sorted.map { formatter.tokens[$0.afterDelimiterRange] }

                // ignore if there's a where keyword and it is not in the last place.
                let firstWhereIndex = sortedTokens.firstIndex(where: { slice in slice.contains(.keyword("where")) })
                guard firstWhereIndex == nil || firstWhereIndex == sortedTokens.count - 1 else { return }

                for switchCase in switchCaseRanges.enumerated().reversed() {
                    let newTokens = Array(sortedTokens[switchCase.offset])
                    var newComments = Array(sortedComments[switchCase.offset])
                    let oldComments = formatter.tokens[switchCaseRanges[switchCase.offset].afterDelimiterRange]

                    if newComments.last?.isLinebreak == oldComments.last?.isLinebreak {
                        formatter.replaceTokens(in: switchCaseRanges[switchCase.offset].afterDelimiterRange, with: newComments)
                    } else if newComments.count > 1,
                              newComments.last?.isLinebreak == true, oldComments.last?.isLinebreak == false
                    {
                        // indent the new content
                        newComments.append(.space(String(repeating: " ", count: maxIndentCount)))
                        formatter.replaceTokens(in: switchCaseRanges[switchCase.offset].afterDelimiterRange, with: newComments)
                    }

                    formatter.replaceTokens(in: switchCaseRanges[switchCase.offset].beforeDelimiterRange, with: newTokens)
                }
            }
    }
}

extension Formatter {
    struct SwitchCaseRange {
        let beforeDelimiterRange: Range<Int>
        let delimiterToken: Token
        let afterDelimiterRange: Range<Int>
    }

    func parseSwitchCaseRanges() -> [[SwitchCaseRange]] {
        var result: [[SwitchCaseRange]] = []

        forEach(.endOfScope("case")) { i, _ in
            var switchCaseRanges: [SwitchCaseRange] = []
            guard let lastDelimiterIndex = index(of: .startOfScope(":"), after: i),
                  let endIndex = index(after: lastDelimiterIndex, where: { $0.isLinebreak }) else { return }

            var idx = i
            while idx < endIndex,
                  let startOfCaseIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: idx),
                  let delimiterIndex = index(after: idx, where: {
                      $0 == .delimiter(",") || $0 == .startOfScope(":")
                  }),
                  let delimiterToken = token(at: delimiterIndex),
                  let endOfCaseIndex = lastIndex(
                      of: .nonSpaceOrCommentOrLinebreak,
                      in: startOfCaseIndex ..< delimiterIndex
                  )
            {
                let afterDelimiterRange: Range<Int>

                let startOfCommentIdx = delimiterIndex + 1
                if startOfCommentIdx <= endIndex,
                   token(at: startOfCommentIdx)?.isSpaceOrCommentOrLinebreak == true,
                   let nextNonSpaceOrComment = index(of: .nonSpaceOrComment, after: startOfCommentIdx)
                {
                    if token(at: startOfCommentIdx)?.isLinebreak == true
                        || token(at: nextNonSpaceOrComment)?.isSpaceOrCommentOrLinebreak == false
                    {
                        afterDelimiterRange = startOfCommentIdx ..< (startOfCommentIdx + 1)
                    } else if endIndex > startOfCommentIdx {
                        afterDelimiterRange = startOfCommentIdx ..< (nextNonSpaceOrComment + 1)
                    } else {
                        afterDelimiterRange = endIndex ..< (endIndex + 1)
                    }
                } else {
                    afterDelimiterRange = 0 ..< 0
                }

                let switchCaseRange = SwitchCaseRange(
                    beforeDelimiterRange: Range(startOfCaseIndex ... endOfCaseIndex),
                    delimiterToken: delimiterToken,
                    afterDelimiterRange: afterDelimiterRange
                )

                switchCaseRanges.append(switchCaseRange)

                if afterDelimiterRange.isEmpty {
                    idx = delimiterIndex
                } else if afterDelimiterRange.count > 1 {
                    idx = afterDelimiterRange.upperBound
                } else {
                    idx = afterDelimiterRange.lowerBound
                }
            }
            result.append(switchCaseRanges)
        }
        return result
    }

    func sortableValue(for token: Token) -> String? {
        switch token {
        case let .identifier(name):
            return name
        case let .stringBody(body):
            return body
        case let .number(value, .hex):
            return Int(value.dropFirst(2), radix: 16)
                .map(String.init) ?? value
        case let .number(value, .octal):
            return Int(value.dropFirst(2), radix: 8)
                .map(String.init) ?? value
        case let .number(value, .binary):
            return Int(value.dropFirst(2), radix: 2)
                .map(String.init) ?? value
        case let .number(value, _):
            return value
        default:
            return nil
        }
    }
}
