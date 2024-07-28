//
//  sortDeclarations.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

public extension FormatRule {
    static let sortDeclarations = FormatRule(
        help: """
        Sorts the body of declarations with // swiftformat:sort
        and declarations between // swiftformat:sort:begin and
        // swiftformat:sort:end comments.
        """,
        options: ["sortedpatterns"],
        sharedOptions: ["organizetypes"]
    ) { formatter in
        formatter.forEachToken(
            where: {
                $0.isCommentBody && $0.string.contains("swiftformat:sort")
                    || $0.isDeclarationTypeKeyword(including: Array(Token.swiftTypeKeywords))
            }
        ) { index, token in

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
                    let lastRangeToken = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: endCommentIndex - 2)
                else { return }

                rangeToSort = sortRangeStart ... lastRangeToken
                numberOfLeadingLinebreaks = firstRangeToken - sortRangeStart
            } else if shouldBeFullySorted {
                guard let typeOpenBrace = formatter.index(of: .startOfScope("{"), after: index),
                      let typeCloseBrace = formatter.endOfScope(at: typeOpenBrace),
                      let firstTypeBodyToken = formatter.index(of: .nonLinebreak, after: typeOpenBrace),
                      let lastTypeBodyToken = formatter.index(of: .nonLinebreak, before: typeCloseBrace),
                      let declarationKeyword = formatter.lastSignificantKeyword(at: typeOpenBrace),
                      lastTypeBodyToken > typeOpenBrace
                else { return }

                // Sorting the body of a type conflicts with the `organizeDeclarations`
                // keyword if enabled for this type of declaration. In that case,
                // defer to the sorting implementation in `organizeDeclarations`.
                if formatter.options.enabledRules.contains(FormatRule.organizeDeclarations.name),
                   formatter.options.organizeTypes.contains(declarationKeyword)
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

            var declarations = Formatter(Array(formatter.tokens[rangeToSort]))
                .parseDeclarations()
                .enumerated()
                .sorted(by: { lhs, rhs -> Bool in
                    let (lhsIndex, lhsDeclaration) = lhs
                    let (rhsIndex, rhsDeclaration) = rhs

                    // Primarily sort by name, to alphabetize
                    if let lhsName = lhsDeclaration.name,
                       let rhsName = rhsDeclaration.name,
                       lhsName != rhsName
                    {
                        return lhsName.localizedCompare(rhsName) == .orderedAscending
                    }

                    // Otherwise preserve the existing order
                    else {
                        return lhsIndex < rhsIndex
                    }

                })
                .map { $0.element }

            // Make sure there's at least one newline between each declaration
            for i in 0 ..< max(0, declarations.count - 1) {
                let declaration = declarations[i]
                let nextDeclaration = declarations[i + 1]

                if declaration.tokens.last?.isLinebreak == false,
                   nextDeclaration.tokens.first?.isLinebreak == false
                {
                    declarations[i + 1] = formatter.mapOpeningTokens(in: nextDeclaration) { openTokens in
                        let openFormatter = Formatter(openTokens)
                        openFormatter.insertLinebreak(at: 0)
                        return openFormatter.tokens
                    }
                }
            }

            var sortedFormatter = Formatter(declarations.flatMap { $0.tokens })

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
    }
}
