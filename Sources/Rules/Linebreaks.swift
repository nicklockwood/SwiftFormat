//
//  Linebreaks.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 8/25/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Standardise linebreak characters as whatever is specified in the options (\n by default)
    static let linebreaks = FormatRule(
        help: "Use specified linebreak character for all linebreaks (CR, LF or CRLF).",
        options: ["linebreaks"]
    ) { formatter in
        formatter.forEach(.linebreak) { i, _ in
            formatter.replaceToken(at: i, with: formatter.linebreakToken(for: i))
        }
    }
}
