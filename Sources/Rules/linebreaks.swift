//
//  linebreaks.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

extension FormatRule {
    /// Standardise linebreak characters as whatever is specified in the options (\n by default)
    public static let linebreaks = FormatRule(
        help: "Use specified linebreak character for all linebreaks (CR, LF or CRLF).",
        options: ["linebreaks"]
    ) { formatter in
        formatter.forEach(.linebreak) { i, _ in
            formatter.replaceToken(at: i, with: formatter.linebreakToken(for: i))
        }
    }

}
