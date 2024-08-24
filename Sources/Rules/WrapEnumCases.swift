//
//  WrapEnumCases.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 8/28/20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Formats enum cases declaration into one case per line
    static let wrapEnumCases = FormatRule(
        help: "Rewrite comma-delimited enum cases to one case per line.",
        examples: """
        ```diff
          enum Foo {
        -   case bar, baz
          }

          enum Foo {
        +   case bar
        +   case baz
          }
        ```
        """,
        disabledByDefault: true,
        options: ["wrapenumcases"],
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.parseEnumCaseRanges()
            .filter(formatter.shouldWrapCaseRangeGroup)
            .flatMap { $0 }
            .filter { $0.endOfCaseRangeToken == .delimiter(",") }
            .reversed()
            .forEach { enumCase in
                guard var nextNonSpaceIndex = formatter.index(of: .nonSpace, after: enumCase.value.upperBound) else {
                    return
                }
                let caseIndex = formatter.lastIndex(of: .keyword("case"), in: 0 ..< enumCase.value.lowerBound)
                let indent = formatter.currentIndentForLine(at: caseIndex ?? enumCase.value.lowerBound)

                if formatter.tokens[nextNonSpaceIndex] == .startOfScope("//") {
                    formatter.removeToken(at: enumCase.value.upperBound)
                    if formatter.token(at: enumCase.value.upperBound)?.isSpace == true,
                       formatter.token(at: enumCase.value.upperBound - 1)?.isSpace == true
                    {
                        formatter.removeToken(at: enumCase.value.upperBound - 1)
                    }
                    nextNonSpaceIndex = formatter.index(of: .linebreak, after: enumCase.value.upperBound) ?? nextNonSpaceIndex
                } else {
                    formatter.removeTokens(in: enumCase.value.upperBound ..< nextNonSpaceIndex)
                    nextNonSpaceIndex = enumCase.value.upperBound
                }

                if !formatter.tokens[nextNonSpaceIndex].isLinebreak {
                    formatter.insertLinebreak(at: nextNonSpaceIndex)
                }

                let offset = indent.isEmpty ? 0 : 1
                formatter.insertSpace(indent, at: nextNonSpaceIndex + 1)
                formatter.insert([.keyword("case")], at: nextNonSpaceIndex + 1 + offset)
                formatter.insertSpace(" ", at: nextNonSpaceIndex + 2 + offset)
            }
    }
}

extension Formatter {
    struct EnumCaseRange: Comparable {
        let value: Range<Int>
        let endOfCaseRangeToken: Token

        static func < (lhs: Formatter.EnumCaseRange, rhs: Formatter.EnumCaseRange) -> Bool {
            lhs.value.lowerBound < rhs.value.lowerBound
        }
    }

    func parseEnumCaseRanges() -> [[EnumCaseRange]] {
        var indexedRanges: [Int: [EnumCaseRange]] = [:]

        forEach(.keyword("case")) { i, _ in
            guard isEnumCase(at: i) else { return }

            var idx = i
            while let starOfCaseRangeIdx = index(of: .identifier, after: idx),
                  lastSignificantKeyword(at: starOfCaseRangeIdx) == "case",
                  let lastCaseIndex = lastIndex(of: .keyword("case"), in: i ..< starOfCaseRangeIdx),
                  lastCaseIndex == i,
                  let endOfCaseRangeIdx = index(
                      after: starOfCaseRangeIdx,
                      where: { $0 == .delimiter(",") || $0.isLinebreak }
                  ),
                  let endOfCaseRangeToken = token(at: endOfCaseRangeIdx)
            {
                let startOfScopeIdx = index(of: .startOfScope, before: starOfCaseRangeIdx) ?? 0

                var indexedCase = indexedRanges[startOfScopeIdx, default: []]
                indexedCase.append(
                    EnumCaseRange(
                        value: starOfCaseRangeIdx ..< endOfCaseRangeIdx,
                        endOfCaseRangeToken: endOfCaseRangeToken
                    )
                )
                indexedRanges[startOfScopeIdx] = indexedCase

                idx = endOfCaseRangeIdx
            }
        }

        return Array(indexedRanges.values)
    }

    func shouldWrapCaseRangeGroup(_ caseRangeGroup: [Formatter.EnumCaseRange]) -> Bool {
        guard let firstIndex = caseRangeGroup.first?.value.lowerBound,
              let scopeStart = startOfScope(at: firstIndex),
              tokens[scopeStart ..< firstIndex].contains(where: { $0.isLinebreak })
        else {
            // Don't wrap if first case is on same line as opening `{`
            return false
        }
        return options.wrapEnumCases == .always || caseRangeGroup.contains(where: {
            tokens[$0.value].contains(where: {
                [.startOfScope("("), .operator("=", .infix)].contains($0)
            })
        })
    }
}
