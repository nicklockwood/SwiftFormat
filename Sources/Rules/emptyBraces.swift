//
//  emptyBraces.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

public extension FormatRule {
    /// Remove white-space between empty braces
    static let emptyBraces = FormatRule(
        help: "Remove whitespace inside empty braces.",
        options: ["emptybraces"],
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEach(.startOfScope("{")) { i, _ in
            guard let closingIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i, if: {
                $0 == .endOfScope("}")
            }) else {
                return
            }
            if let token = formatter.next(.nonSpaceOrComment, after: closingIndex),
               [.keyword("else"), .keyword("catch")].contains(token)
            {
                return
            }
            let range = i + 1 ..< closingIndex
            switch formatter.options.emptyBracesSpacing {
            case .noSpace:
                formatter.removeTokens(in: range)
            case .spaced:
                formatter.replaceTokens(in: range, with: .space(" "))
            case .linebreak:
                formatter.insertSpace(formatter.currentIndentForLine(at: i), at: range.endIndex)
                formatter.replaceTokens(in: range, with: formatter.linebreakToken(for: i + 1))
            }
        }
    }
}
