// Created by @NikeKov on 01.08.2024
// Copyright © 2024 Nick Lockwood. All rights reserved.

import Foundation

public extension FormatRule {
    static let blankLinesAfterGuardStatements = FormatRule(
        help: "Remove blank lines between consecutive guard statements, and insert a blank after the last guard statement.",
        disabledByDefault: true,
        options: ["line-between-guards"]
    ) { formatter in
        formatter.forEach(.keyword("guard")) { guardIndex, _ in
            guard var elseIndex = formatter.index(of: .keyword("else"), after: guardIndex) else {
                return
            }
            if !formatter.isGuardElse(at: elseIndex) {
                guard let nextIndex = formatter.index(of: .keyword("else"), after: elseIndex) else {
                    return
                }
                elseIndex = nextIndex
            }
            guard let startOfGuardScope = formatter.index(of: .startOfScope("{"), after: elseIndex),
                  let endOfGuardScope = formatter.endOfScope(at: startOfGuardScope)
            else {
                return
            }

            guard let nextNonSpaceAndNonLinebreakIndex = formatter.index(of: .nonSpaceOrLinebreak, after: endOfGuardScope) else {
                return
            }

            let nextToken = formatter.tokens[nextNonSpaceAndNonLinebreakIndex]
            if nextToken == .endOfScope("}") || nextToken.isOperator {
                // Do not add space in this cases
                return
            }

            let linebreaks: Int
            if formatter.options.lineBetweenConsecutiveGuards {
                linebreaks = 2
            } else {
                linebreaks = nextToken == .keyword("guard") ? 1 : 2
            }

            let indexesBetween = Set(endOfGuardScope + 1 ..< nextNonSpaceAndNonLinebreakIndex)
            formatter.leaveOrSetLinebreaksInIndexes(indexesBetween, linebreaksCount: linebreaks)
        }
    } examples: {
        """
        `--linebetweenguards false` (default)

        ```diff
            // Multiline guard
            guard let spicy = self.makeSpicy() else {
                return
            } 
        -
            guard let yummy = self.makeYummy() else {
                return
            }
            guard let soap = self.clean() else {
                return
            }
        +
            let doTheJob = nikekov()
        ```
        ```diff
            // Single-line guard
            guard let spicy = self.makeSpicy() else { return }
        -
            guard let yummy = self.makeYummy() else { return }
            guard let soap = self.clean() else { return }
        +
            let doTheJob = nikekov()
        ```

        `--linebetweenguards true`

        ```diff
            // Multiline guard
            guard let spicy = self.makeSpicy() else {
                return
            }

            guard let yummy = self.makeYummy() else {
                return
            }
        +
            guard let soap = self.clean() else {
                return
            }
        +
            let doTheJob = nikekov()
        ```
        ```diff
            // Single-line guard
            guard let spicy = self.makeSpicy() else { return }

            guard let yummy = self.makeYummy() else { return }
        +
            guard let soap = self.clean() else { return }
        +
            let doTheJob = nikekov()
        ```
        """
    }
}
