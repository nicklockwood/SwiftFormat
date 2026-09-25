//
//  SortDeclarations.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 11/22/21.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let sortDeclarations = FormatRule(
        help: """
        Sorts the body of declarations with // swiftformat:sort
        and declarations between // swiftformat:sort:begin and
        // swiftformat:sort:end comments.
        """,
        options: ["sorted-patterns"],
        sharedOptions: ["locale", "linebreaks", "organize-types", "struct-threshold", "class-threshold", "enum-threshold", "extension-threshold"]
    ) { formatter in
        formatter.forEachToken(
            where: {
                $0.isCommentBody && $0.string.contains("swiftformat:sort")
                    || $0.isDeclarationTypeKeyword(including: Array(Token.swiftTypeKeywords))
            }
        ) { index, token in
            if token.isCommentBody, !token.string.contains(":sort:"),
               let literalStartIndex = formatter.collectionLiteralStartOfScope(forSortCommentAt: index)
            {
                formatter.sortCollectionLiteralElements(startOfScope: literalStartIndex)
                return
            }

            let rangeToSort: ClosedRange<Int>
            let numberOfLeadingLinebreaks: Int

            // For `:sort:begin`, directives, we sort the declarations
            // between the `:begin` and and `:end` comments
            let shouldBePartiallySorted = token.string.contains("swiftformat:sort:begin")

            let identifier = formatter.next(.identifier, after: index)
            let shouldBeSortedByNamePattern = formatter.options.alphabeticallySortedDeclarationPatterns.contains {
                identifier?.string.contains($0) ?? false
            }
            let shouldBeSortedByMarkComment = token.isCommentBody && !token.string.contains(":sort:")
            // For `:sort` directives and types with matching name pattern, we sort the declarations
            // between the open and close brace of the following type
            let shouldBeFullySorted = shouldBeSortedByNamePattern || shouldBeSortedByMarkComment

            if shouldBePartiallySorted {
                guard let endCommentIndex = formatter.tokens[index...].firstIndex(where: {
                    $0.isComment && $0.string.contains("swiftformat:sort:end")
                }),
                    let sortRangeStart = formatter.index(of: .nonSpaceOrComment, after: index),
                    let firstRangeToken = formatter.index(of: .nonLinebreak, after: sortRangeStart),
                    let lastRangeToken = formatter.index(of: .nonSpaceOrLinebreak, before: endCommentIndex - 2),
                    sortRangeStart <= lastRangeToken
                else { return }

                rangeToSort = sortRangeStart ... lastRangeToken
                numberOfLeadingLinebreaks = firstRangeToken - sortRangeStart
            } else if shouldBeFullySorted {
                guard let typeOpenBrace = formatter.index(of: .startOfScope("{"), after: index),
                      let typeCloseBrace = formatter.endOfScope(at: typeOpenBrace),
                      let firstTypeBodyToken = formatter.index(of: .nonLinebreak, after: typeOpenBrace),
                      let lastTypeBodyToken = formatter.index(of: .nonSpaceOrLinebreak, before: typeCloseBrace),
                      let declarationKeywordIndex = formatter.indexOfLastSignificantKeyword(at: typeOpenBrace),
                      lastTypeBodyToken > typeOpenBrace
                else { return }

                // Sorting the body of a type conflicts with the `organizeDeclarations`
                // keyword if enabled for this declaration. In that case,
                // defer to the sorting implementation in `organizeDeclarations`.
                if formatter.options.enabledRules.contains(FormatRule.organizeDeclarations.name),
                   formatter.options.organizeTypes.contains(formatter.tokens[declarationKeywordIndex].string),
                   formatter.typeLengthExceedsOrganizationThreshold(at: declarationKeywordIndex)
                {
                    return
                }

                rangeToSort = firstTypeBodyToken ... lastTypeBodyToken
                // We don't include any leading linebreaks in the range to sort,
                // since `firstTypeBodyToken` is the first `nonLinebreak` in the body
                numberOfLeadingLinebreaks = 0
            } else {
                return
            }

            let parsedDeclarations = Formatter(Array(formatter.tokens[rangeToSort])).parseDeclarations()

            // Tokens that aren't part of any declaration (e.g. a bare expression)
            // would be dropped when reassembling the sorted declarations,
            // so sort the collection literals in the expression instead
            guard parsedDeclarations.reduce(0, { $0 + $1.tokens.count }) == rangeToSort.count else {
                if shouldBePartiallySorted {
                    formatter.sortCollectionLiterals(in: rangeToSort)
                }
                return
            }

            var declarations = parsedDeclarations
                .enumerated()
                .sorted(by: { lhs, rhs -> Bool in
                    let (lhsIndex, lhsDeclaration) = lhs
                    let (rhsIndex, rhsDeclaration) = rhs

                    // Primarily sort by name, to alphabetize
                    if let lhsName = lhsDeclaration.name,
                       let rhsName = rhsDeclaration.name,
                       lhsName != rhsName
                    {
                        return formatter.options.locale.compare(lhsName, rhsName) == .orderedAscending
                    }

                    // Otherwise preserve the existing order
                    else {
                        return lhsIndex < rhsIndex
                    }

                })
                .map(\.element)

            // Make sure there's at least one newline between each declaration
            for i in 0 ..< max(0, declarations.count - 1) {
                let declaration = declarations[i]
                let nextDeclaration = declarations[i + 1]

                if declaration.tokens.last?.isLinebreak == false,
                   nextDeclaration.tokens.first?.isLinebreak == false
                {
                    let declarationNeedingLinebreak = declarations[i + 1]
                    declarationNeedingLinebreak.formatter.insertLinebreak(at: declarationNeedingLinebreak.range.lowerBound)
                }
            }

            var sortedFormatter = Formatter(declarations.flatMap(\.tokens))

            // Make sure the type has the same number of leading line breaks
            // as it did before sorting
            if let currentLeadingLinebreakCount = sortedFormatter.tokens.firstIndex(where: { !$0.isLinebreak }) {
                if numberOfLeadingLinebreaks != currentLeadingLinebreakCount {
                    sortedFormatter.removeTokens(in: 0 ..< currentLeadingLinebreakCount)

                    for _ in 0 ..< numberOfLeadingLinebreaks {
                        sortedFormatter.insertLinebreak(at: 0)
                    }
                }

            } else {
                for _ in 0 ..< numberOfLeadingLinebreaks {
                    sortedFormatter.insertLinebreak(at: 0)
                }
            }

            // There are always expected to be zero trailing line breaks,
            // so we remove any trailing line breaks
            // (this is because `typeBodyRange` specifically ends before the first
            // trailing linebreak)
            while sortedFormatter.tokens.last?.isLinebreak == true {
                sortedFormatter.removeLastToken()
            }

            if Array(formatter.tokens[rangeToSort]) != sortedFormatter.tokens {
                formatter.replaceTokens(
                    in: rangeToSort,
                    with: sortedFormatter.tokens
                )
            }
        }
    } examples: {
        """
        ```diff
          // swiftformat:sort
          enum FeatureFlags {
        -     case fooFeature
        -     case barFeature
        +     case barFeature
        +     case fooFeature
          }

          /// With --sortedpatterns Feature
          enum FeatureFlags {
        -     case fooFeature
        -     case barFeature
        +     case barFeature
        +     case fooFeature
          }

          enum FeatureFlags {
              // swiftformat:sort:begin
        -     case fooFeature
        -     case barFeature
        +     case barFeature
        +     case fooFeature
              // swiftformat:sort:end

              var anUnsortedProperty: Foo {
                  Foo()
              }
          }

          let featureFlags = [ // swiftformat:sort
        -     fooFeature,
        -     barFeature,
        +     barFeature,
        +     fooFeature,
          ]
        ```
        """
    }
}

extension Formatter {
    /// If the sort directive comment body at the given index directly follows
    /// the opening `[` of an array or dictionary literal, returns the index of that `[`.
    func collectionLiteralStartOfScope(forSortCommentAt commentBodyIndex: Int) -> Int? {
        guard let commentStartIndex = index(of: .startOfScope("//"), before: commentBodyIndex),
              let previousIndex = index(of: .nonSpace, before: commentStartIndex),
              tokens[previousIndex] == .startOfScope("["),
              !isSubscriptOrFunctionCall(at: previousIndex)
        else { return nil }
        return previousIndex
    }

    /// Sorts the elements of every array and dictionary literal in the given range.
    func sortCollectionLiterals(in range: ClosedRange<Int>) {
        let literalStarts = range.filter {
            tokens[$0] == .startOfScope("[") && [.array, .dictionary].contains(scopeType(at: $0))
        }
        // Sorting from last to first sorts nested literals before their parents,
        // and never moves the start of an earlier literal
        for startOfScope in literalStarts.reversed() {
            sortCollectionLiteralElements(startOfScope: startOfScope)
        }
    }

    /// Sorts the comma-separated elements of the array or dictionary literal starting at the given `[`,
    /// leaving the commas and whitespace between elements in place. Comments on their own lines
    /// move with the element below them, and comments at the end of a line move with the element before them.
    func sortCollectionLiteralElements(startOfScope: Int) {
        var elements = commaSeparatedElementsInScope(startOfScope: startOfScope)
        // The first element range starts at the sort comment itself, so skip past it
        guard let firstElement = elements.first,
              let firstElementStart = index(of: .nonSpaceOrCommentOrLinebreak, after: startOfScope),
              firstElementStart <= firstElement.upperBound
        else { return }
        elements[0] = firstElementStart ... firstElement.upperBound

        let parts = elements.map(collectionLiteralElementParts)
        let sortKeys = parts.map { collectionLiteralElementSortKey($0.body) }
        let sortedParts = parts.indices.sorted { lhs, rhs in
            let order = sortKeys[lhs].localizedCompare(sortKeys[rhs])
            return order == .orderedSame ? lhs < rhs : order == .orderedAscending
        }.map { parts[$0] }

        var replacements = [(range: Range<Int>, tokens: [Token])]()
        for (original, sorted) in zip(parts, sortedParts) {
            replacements.append((original.leadingCommentsAndBody, Array(tokens[sorted.leadingCommentsAndBody])))
            replacements.append((original.trailingComment, Array(tokens[sorted.trailingComment])))
        }

        // Replace from last to first so earlier ranges remain valid
        for (range, newTokens) in replacements.reversed() where Array(tokens[range]) != newTokens {
            replaceTokens(in: range, with: newTokens)
        }
    }

    /// Splits a collection literal element into the element itself, the element along with
    /// the comments on the lines above it, and the (possibly empty) comment at the end of its line.
    func collectionLiteralElementParts(_ element: ClosedRange<Int>)
        -> (body: ClosedRange<Int>, leadingCommentsAndBody: Range<Int>, trailingComment: Range<Int>)
    {
        var body = element
        let endOfElement: Int
        if let commaIndex = index(of: .nonSpaceOrLinebreak, after: element.upperBound),
           tokens[commaIndex] == .delimiter(",")
        {
            endOfElement = commaIndex
        } else {
            // The last element has no trailing comma, so exclude any comments after it
            let lastBodyToken = index(of: .nonSpaceOrCommentOrLinebreak, before: element.upperBound + 1) ?? element.upperBound
            body = element.lowerBound ... lastBodyToken
            endOfElement = body.upperBound
        }

        var trailingComment = endOfElement + 1 ..< endOfElement + 1
        let restOfLine = endOfElement + 1 ..< endOfLine(at: endOfElement)
        if tokens[restOfLine].contains(where: \.isComment),
           tokens[restOfLine].allSatisfy(\.isSpaceOrComment)
        {
            trailingComment = restOfLine
        }

        var leadingStart = body.lowerBound
        while let previousIndex = index(of: .nonSpaceOrLinebreak, before: leadingStart),
              tokens[previousIndex].isComment
        {
            let lineStart = startOfLine(at: previousIndex, excludingIndent: true)
            guard tokens[lineStart].isComment else { break }
            leadingStart = lineStart
        }

        return (body, leadingStart ..< body.upperBound + 1, trailingComment)
    }

    /// The text to sort a collection literal element by: the key for dictionary
    /// elements, or the entire element for array elements.
    func collectionLiteralElementSortKey(_ element: ClosedRange<Int>) -> String {
        // Ternary colons are tokenized as `.operator(":", .infix)`, so only the dictionary colon matches
        guard let colonIndex = index(of: .delimiter(":"), in: element.lowerBound ..< element.upperBound),
              let endOfKey = index(of: .nonSpaceOrCommentOrLinebreak, before: colonIndex),
              endOfKey >= element.lowerBound
        else { return tokens[element].string }
        return tokens[element.lowerBound ... endOfKey].string
    }
}
