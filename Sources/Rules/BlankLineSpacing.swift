//
//  BlankLineSpacing.swift
//  SwiftFormat
//
//  Created by Kim de Vos on 11/27/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Configure blank lines after selected control flow constructs.
    static let blankLineSpacing = FormatRule(
        help: """
        Configure blank lines after selected control flow constructs and between switch cases.
        The `guard` and `case` selections use `--line-between-guards` and `--blank-line-after-switch-case`, respectively.
        """,
        disabledByDefault: true,
        orderAfter: [.blankLinesAfterGuardStatements, .redundantBreak],
        options: ["blank-lines-after"],
        sharedOptions: ["blank-line-after-switch-case", "line-between-guards", "linebreaks"]
    ) { formatter in
        // Case spacing takes precedence at the end of a case that ends with a guard.
        formatter.forEach(.keyword("guard")) { index, _ in
            if formatter.options.blankLinesAfter.contains("guard") {
                formatter.applyBlankLineAfterGuard(at: index, betweenGuards: formatter.options.lineBetweenConsecutiveGuards)
            }
        }

        formatter.forEachToken(where: { token in
            [.keyword("if"), .keyword("switch"), .keyword("do"), .keyword("for")].contains(token)
        }) { index, token in
            let requiringCatch = token == .keyword("do")
            let selection = requiringCatch ? "do-catch" : token.string
            let selected = formatter.options.blankLinesAfter
            if selected.contains(selection),
               let statement = formatter.controlFlowStatementRange(
                   at: index, allowingHeaderContinuations: true, requiringCatch: requiringCatch
               )
            {
                formatter.applyBlankLineAfterControlFlow(at: statement.upperBound)
            }

            if token == .keyword("switch"), selected.contains("case"),
               let bodyStart = formatter.startOfConditionalBranchBody(after: index, allowingHeaderContinuations: true)
            {
                formatter.applyBlankLinesAfterSwitchCases(at: index, spacing: formatter.options.blankLineAfterSwitchCase, bodyStart: bodyStart)
            }
        }
    } examples: {
        """
        `--blank-lines-after if`

        ```diff
          if shouldStop {
              return
          }
        +
          guard let value else {
              return
          }
        ```
        """
    }
}

extension Formatter {
    func applyBlankLineAfterControlFlow(at end: Int) {
        let boundary: Int
        if let separator = index(of: .nonSpaceOrComment, after: end),
           tokens[separator] == .delimiter(";")
        {
            boundary = separator
        } else {
            boundary = end
        }

        guard let (linebreak, next) = blankLineBoundary(afterStatementAt: boundary),
              !tokens[next].isSwitchCaseOrDefault,
              isEnabled(at: linebreak),
              !hasLineRelativeDirective("next", in: startOfLine(at: linebreak) ..< linebreak),
              !hasLineRelativeDirective("previous", in: linebreak + 1 ..< endOfLine(at: linebreak + 1))
        else { return }
        insertLinebreak(at: linebreak)
    }

    func hasLineRelativeDirective(_ target: String, in range: Range<Int>) -> Bool {
        tokens[range].contains { token in
            token.isCommentBody && token.string.range(
                of: #"swiftformat:[^\s:]+:\#(target)(?:\s|$)"#, options: .regularExpression
            ) != nil
        }
    }
}
