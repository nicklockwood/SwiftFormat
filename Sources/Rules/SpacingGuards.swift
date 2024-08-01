// Created by @NikeKov on 01.08.2024
// Copyright © 2024 Nick Lockwood. All rights reserved.

import Foundation

public extension FormatRule {
    static let spacingGuards = FormatRule(help: "Remove space between guard and add spaces after last guard.",
                                          disabledByDefault: true)
    { formatter in
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

            if nextNonSpaceAndNonLinebreakToken == .endOfScope("}") {
                // Do not add space for end bracket
                return
            }

            let isGuard = nextNonSpaceAndNonLinebreakToken == .keyword("guard")
            let indexesBetween = Set(endOfScopeOfGuard + 1 ... nextNonSpaceAndNonLinebreakIndex - 1)
            formatter.leaveOrSetLinebreaksInIndexes(indexesBetween, linebreaksCount: isGuard ? 1 : 2)
        }
    }
}
