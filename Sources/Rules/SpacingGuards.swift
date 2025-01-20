// Created by @NikeKov on 01.08.2024
// Copyright © 2024 Nick Lockwood. All rights reserved.

import Foundation

public extension FormatRule {
    static let spacingGuards = FormatRule(
        help: "Remove space between guard statements, and add spaces after last guard.",
        disabledByDefault: true
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

            let linebreaks = nextToken == .keyword("guard") ? 1 : 2
            let indexesBetween = Set(endOfGuardScope + 1 ..< nextNonSpaceAndNonLinebreakIndex)
            formatter.leaveOrSetLinebreaksInIndexes(indexesBetween, linebreaksCount: linebreaks)
        }
    } examples: {
        """
        ```diff
            guard let spicy = self.makeSpicy() else {
                return
            }
        -
            guard let soap = self.clean() else {
                return
            }
        +
            let doTheJob = nikekov()
        ```
        """
    }
}
