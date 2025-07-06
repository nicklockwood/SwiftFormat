//
//  EmptyBraces.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 8/2/18.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove white-space between empty braces
    static let emptyBraces = FormatRule(
        help: "Remove whitespace inside empty braces.",
        options: ["empty-braces"],
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
    } examples: {
        """
        ```diff
        - func foo() {
        -
        - }

        + func foo() {}
        ```
        """
    }
}
