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
        disabledByDefault: true,
        options: ["wrap-enum-cases"],
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
    } examples: {
        """
        ```diff
          enum Foo {
        -   case bar, baz
          }

          enum Foo {
        +   case bar
        +   case baz
          }
        ```
        """
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
        var result = [[EnumCaseRange]]()

        parseDeclarations().forEachRecursiveDeclaration { declaration in
            guard declaration.keyword == "case", isEnumCase(at: declaration.keywordIndex) else { return }

            let caseIndex = declaration.keywordIndex
            var caseRanges = [EnumCaseRange]()

            // Split the case declaration on commas to get individual case ranges
            var currentStart = index(of: .nonSpaceOrCommentOrLinebreak, after: caseIndex) ?? caseIndex
            var searchIndex = caseIndex

            while let commaIndex = index(of: .delimiter(","), after: searchIndex),
                  commaIndex <= declaration.range.upperBound
            {
                // Add the case before this comma
                caseRanges.append(EnumCaseRange(
                    value: currentStart ..< commaIndex,
                    endOfCaseRangeToken: .delimiter(",")
                ))

                // Move to start of next case
                currentStart = index(of: .nonSpaceOrCommentOrLinebreak, after: commaIndex) ?? commaIndex
                searchIndex = commaIndex
            }

            // Add the final case
            let finalCaseEnd = lastIndex(of: .nonSpaceOrCommentOrLinebreak, in: currentStart ..< (declaration.range.upperBound + 1)) ?? declaration.range.upperBound

            let endToken = token(at: finalCaseEnd) ?? .linebreak("\n", 1)
            caseRanges.append(EnumCaseRange(
                value: currentStart ..< finalCaseEnd,
                endOfCaseRangeToken: endToken
            ))

            // Only add if there are multiple cases in this declaration
            if caseRanges.count > 1 {
                result.append(caseRanges)
            }
        }

        return result
    }

    func shouldWrapCaseRangeGroup(_ caseRangeGroup: [Formatter.EnumCaseRange]) -> Bool {
        guard let firstIndex = caseRangeGroup.first?.value.lowerBound,
              let scopeStart = startOfScope(at: firstIndex),
              tokens[scopeStart ..< firstIndex].contains(where: \.isLinebreak)
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
