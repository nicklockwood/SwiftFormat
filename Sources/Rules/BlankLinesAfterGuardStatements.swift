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
            formatter.applyBlankLineAfterGuard(at: guardIndex, betweenGuards: formatter.options.lineBetweenConsecutiveGuards)
        }
    } examples: {
        """
        `--line-between-guards false` (default)

        ```diff
          guard let foo else { return }
        -
          guard let bar else { return }
        +
          print(foo, bar)
        ```

        `--line-between-guards true`

        ```diff
          guard let foo else { return }
        +
          guard let bar else { return }
        +
          print(foo, bar)
        ```
        """
    }
}
