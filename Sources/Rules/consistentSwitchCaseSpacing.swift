//
//  consistentSwitchCaseSpacing.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let consistentSwitchCaseSpacing = FormatRule(
        help: "Ensures consistent spacing among all of the cases in a switch statement.",
        orderAfter: [.blankLineAfterSwitchCase]
    ) { formatter in
        formatter.forEach(.keyword("switch")) { switchIndex, _ in
            guard let switchCases = formatter.switchStatementBranchesWithSpacingInfo(at: switchIndex) else { return }

            // When counting the switch cases, exclude the last case (which should never have a trailing blank line).
            let countWithTrailingBlankLine = switchCases.filter { $0.isFollowedByBlankLine && !$0.isLastCase }.count
            let countWithoutTrailingBlankLine = switchCases.filter { !$0.isFollowedByBlankLine && !$0.isLastCase }.count

            // We want the spacing to be consistent for all switch cases,
            // so use whichever formatting is used for the majority of cases.
            var allCasesShouldHaveBlankLine = countWithTrailingBlankLine >= countWithoutTrailingBlankLine

            // When the `blankLinesBetweenChainedFunctions` rule is enabled, and there is a switch case
            // that is required to span multiple lines, then all cases must span multiple lines.
            // (Since if this rule removed the blank line from that case, it would contradict the other rule)
            if formatter.options.enabledRules.contains(FormatRule.blankLineAfterSwitchCase.name),
               switchCases.contains(where: { $0.spansMultipleLines && !$0.isLastCase })
            {
                allCasesShouldHaveBlankLine = true
            }

            for switchCase in switchCases.reversed() {
                if !switchCase.isFollowedByBlankLine, allCasesShouldHaveBlankLine, !switchCase.isLastCase {
                    switchCase.insertTrailingBlankLine(using: formatter)
                }

                if switchCase.isFollowedByBlankLine, !allCasesShouldHaveBlankLine || switchCase.isLastCase {
                    switchCase.removeTrailingBlankLine(using: formatter)
                }
            }
        }
    }
}
