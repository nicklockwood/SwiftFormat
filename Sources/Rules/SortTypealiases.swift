//
//  SortTypealiases.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 5/6/23.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let sortTypealiases = FormatRule(
        help: "Sort protocol composition typealiases alphabetically.",
        sharedOptions: ["line-breaks"]
    ) { formatter in
        formatter.forEach(.keyword("typealias")) { typealiasIndex, _ in
            guard let (equalsIndex, andTokenIndices, endIndex) = formatter.parseProtocolCompositionTypealias(at: typealiasIndex),
                  let typealiasNameIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: equalsIndex)
            else {
                return
            }

            var seenTypes = Set<String>()

            // Split the typealias into individual elements.
            // Any comments on their own line are grouped with the following element.
            let delimiters = [equalsIndex] + andTokenIndices
            var parsedElements: [(startIndex: Int, delimiterIndex: Int, endIndex: Int, type: String, allTokens: [Token], isDuplicate: Bool)] = []

            for delimiter in delimiters.indices {
                let endOfPreviousElement = parsedElements.last?.endIndex ?? typealiasNameIndex
                let elementStartIndex = formatter.index(of: .nonSpaceOrLinebreak, after: endOfPreviousElement) ?? delimiters[delimiter]

                // Start with the end index just being the end of the type name
                var elementEndIndex: Int
                let nextElementIsOnSameLine: Bool
                if delimiter == delimiters.indices.last {
                    elementEndIndex = endIndex
                    nextElementIsOnSameLine = false
                } else {
                    let nextDelimiterIndex = delimiters[delimiter + 1]
                    elementEndIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: nextDelimiterIndex) ?? (nextDelimiterIndex - 1)

                    let endOfLine = formatter.endOfLine(at: elementEndIndex)
                    nextElementIsOnSameLine = formatter.endOfLine(at: nextDelimiterIndex) == endOfLine
                }

                // Handle comments in multiline typealiases
                if !nextElementIsOnSameLine {
                    // Any comments on the same line as the type name should be considered part of this element.
                    // Any comments after the linebreak are consisidered part of the next element.
                    // To do that we just extend this element to the end of the current line.
                    elementEndIndex = formatter.endOfLine(at: elementEndIndex) - 1
                }

                let tokens = Array(formatter.tokens[elementStartIndex ... elementEndIndex])
                let typeName = tokens
                    .filter { !$0.isSpaceOrCommentOrLinebreak && !$0.isOperator }
                    .map(\.string).joined()

                // While we're here, also filter out any duplicates.
                // Since we're sorting, duplicates would sit right next to each other
                // which makes them especially obvious.
                let isDuplicate = seenTypes.contains(typeName)
                seenTypes.insert(typeName)

                parsedElements.append((
                    startIndex: elementStartIndex,
                    delimiterIndex: delimiters[delimiter],
                    endIndex: elementEndIndex,
                    type: typeName,
                    allTokens: tokens,
                    isDuplicate: isDuplicate
                ))
            }

            // Sort each element by type name
            var sortedElements = parsedElements.sorted(by: { lhsElement, rhsElement in
                // Exclude the any keyword if present when comparing types.
                // Otherwise, all `any` types will be sorted to the end of the list.
                // (lowercase letters come after uppercase letters in this sort order).
                var lhsType = lhsElement.type
                var rhsType = rhsElement.type

                if lhsType.hasPrefix("any") {
                    lhsType = String(lhsType.dropFirst(3))
                }

                if rhsType.hasPrefix("any") {
                    rhsType = String(rhsType.dropFirst(3))
                }

                return lhsType.lexicographicallyPrecedes(rhsType)
            })

            // Don't modify the file if the typealias is already sorted
            if parsedElements.map(\.startIndex) == sortedElements.map(\.startIndex) {
                return
            }

            let firstNonDuplicateIndex = sortedElements.firstIndex(where: { !$0.isDuplicate })

            for elementIndex in sortedElements.indices {
                // Revalidate all of the delimiters after sorting
                // (the first delimiter should be `=` and all others should be `&`
                let delimiterIndexInTokens = sortedElements[elementIndex].delimiterIndex - sortedElements[elementIndex].startIndex

                if elementIndex == firstNonDuplicateIndex {
                    sortedElements[elementIndex].allTokens[delimiterIndexInTokens] = .operator("=", .infix)
                } else {
                    sortedElements[elementIndex].allTokens[delimiterIndexInTokens] = .operator("&", .infix)
                }

                // Make sure there's always a linebreak after any comments, to prevent
                // them from accidentally commenting out following elements of the typealias
                if elementIndex != sortedElements.indices.last,
                   sortedElements[elementIndex].allTokens.last?.isComment == true,
                   let nextToken = formatter.nextToken(after: parsedElements[elementIndex].endIndex),
                   !nextToken.isLinebreak
                {
                    sortedElements[elementIndex].allTokens
                        .append(formatter.linebreakToken(for: parsedElements[elementIndex].endIndex))
                }

                // If this element starts with a comment, that's because the comment
                // was originally on a line all by itself. To preserve this, make sure
                // there's a linebreak before the comment.
                if elementIndex != sortedElements.indices.first,
                   sortedElements[elementIndex].allTokens.first?.isComment == true,
                   let previousToken = formatter.lastToken(before: parsedElements[elementIndex].startIndex, where: { !$0.isSpace }),
                   !previousToken.isLinebreak
                {
                    sortedElements[elementIndex].allTokens
                        .insert(formatter.linebreakToken(for: parsedElements[elementIndex].startIndex), at: 0)
                }
            }

            // Replace each index in the parsed list with the corresponding index in the sorted list,
            // working backwards to not invalidate any existing indices
            for (originalElement, newElement) in zip(parsedElements, sortedElements).reversed() {
                if newElement.isDuplicate, let tokenBeforeElement = formatter.index(of: .nonSpaceOrLinebreak, before: originalElement.startIndex) {
                    formatter.removeTokens(in: (tokenBeforeElement + 1) ... originalElement.endIndex)
                } else {
                    formatter.replaceTokens(
                        in: originalElement.startIndex ... originalElement.endIndex,
                        with: newElement.allTokens
                    )
                }
            }
        }
    } examples: {
        """
        ```diff
        - typealias Placeholders = Foo & Bar & Baaz & Quux
        + typealias Placeholders = Baaz & Bar & Foo & Quux

          typealias Dependencies
        -     = FooProviding
        +     = BaazProviding
              & BarProviding
        -     & BaazProviding
        +     & FooProviding
              & QuuxProviding
        ```
        """
    }
}
