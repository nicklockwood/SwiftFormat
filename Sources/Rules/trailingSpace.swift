//
//  trailingSpace.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

extension FormatRule {
    /// Remove trailing space from the end of lines, as it has no semantic
    /// meaning and leads to noise in commits.
    public static let trailingSpace = FormatRule(
        help: "Remove trailing space at end of a line.",
        orderAfter: ["wrap", "wrapArguments"],
        options: ["trimwhitespace"]
    ) { formatter in
        formatter.forEach(.space) { i, _ in
            if formatter.token(at: i + 1)?.isLinebreak ?? true,
               formatter.options.truncateBlankLines || formatter.token(at: i - 1)?.isLinebreak == false
            {
                formatter.removeToken(at: i)
            }
        }
    }
}
