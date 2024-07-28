//
//  wrapSwitchCases.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

public extension FormatRule {
    /// Writes one switch case per line
    static let wrapSwitchCases = FormatRule(
        help: "Wrap comma-delimited switch cases onto multiple lines.",
        disabledByDefault: true,
        sharedOptions: ["linebreaks", "tabwidth", "indent", "smarttabs"]
    ) { formatter in
        formatter.forEach(.endOfScope("case")) { i, _ in
            guard var endIndex = formatter.index(of: .startOfScope(":"), after: i) else { return }
            let lineStart = formatter.startOfLine(at: i)
            let indent = formatter.spaceEquivalentToTokens(from: lineStart, upTo: i + 2)

            var startIndex = i
            while let commaIndex = formatter.index(of: .delimiter(","), in: startIndex + 1 ..< endIndex),
                  let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: commaIndex)
            {
                if formatter.index(of: .linebreak, in: commaIndex ..< nextIndex) == nil {
                    formatter.insertLinebreak(at: commaIndex + 1)
                    let delta = formatter.insertSpace(indent, at: commaIndex + 2)
                    endIndex += 1 + delta
                }
                startIndex = commaIndex
            }
        }
    }
}
