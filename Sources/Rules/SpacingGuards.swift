// Created by @NikeKov on 01.08.2024
// Copyright © 2024 Nick Lockwood. All rights reserved.

import Foundation

public extension FormatRule {
    static let spacingGuards = FormatRule(
        help: "Remove space between guard statements, and add spaces after last guard.",
        examples: """
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
        """,
        disabledByDefault: true
    ) { formatter in
        formatter.forEach(.keyword("guard")) { guardIndex, _ in
            guard let startOfScopeOfGuard = formatter.index(of: .startOfScope("{"), after: guardIndex),
                  let endOfScopeOfGuard = formatter.endOfScope(at: startOfScopeOfGuard)
            else {
                return
            }

            guard let nextNonSpaceAndNonLinebreakIndex = formatter.index(of: .nonSpaceOrLinebreak, after: endOfScopeOfGuard) else {
                return
            }

            let nextNonSpaceAndNonLinebreakToken = formatter.token(at: nextNonSpaceAndNonLinebreakIndex)

            if nextNonSpaceAndNonLinebreakToken == .endOfScope("}")
                || nextNonSpaceAndNonLinebreakToken?.isOperator == true
            {
                // Do not add space in this cases
                return
            }

            let isGuard = nextNonSpaceAndNonLinebreakToken == .keyword("guard")
            let indexesBetween = Set(endOfScopeOfGuard + 1 ..< nextNonSpaceAndNonLinebreakIndex)
            formatter.leaveOrSetLinebreaksInIndexes(indexesBetween, linebreaksCount: isGuard ? 1 : 2)
        }
    }
}
