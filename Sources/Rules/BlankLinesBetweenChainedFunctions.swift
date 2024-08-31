//
//  BlankLinesBetweenChainedFunctions.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 7/28/23.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove blank lines between chained functions but keep the linebreaks
    static let blankLinesBetweenChainedFunctions = FormatRule(
        help: """
        Remove blank lines between chained functions but keep the linebreaks.
        """
    ) { formatter in
        formatter.forEach(.operator(".", .infix)) { i, _ in
            let endOfLine = formatter.endOfLine(at: i)
            if let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: endOfLine),
               formatter.tokens[nextIndex] == .operator(".", .infix),
               // Make sure to preserve any code comment between the two lines
               let nextTokenOrComment = formatter.index(of: .nonSpaceOrLinebreak, after: endOfLine)
            {
                if formatter.tokens[nextTokenOrComment].isComment {
                    if formatter.options.enabledRules.contains(FormatRule.blankLinesAroundMark.name),
                       case let .commentBody(body)? = formatter.next(.nonSpace, after: nextTokenOrComment),
                       body.hasPrefix("MARK:")
                    {
                        return
                    }
                    if let endOfComment = formatter.index(of: .comment, before: nextIndex) {
                        let endOfLine = formatter.endOfLine(at: endOfComment)
                        let startOfLine = formatter.startOfLine(at: nextIndex)
                        formatter.removeTokens(in: endOfLine + 1 ..< startOfLine)
                    }
                }
                let startOfLine = formatter.startOfLine(at: nextTokenOrComment)
                formatter.removeTokens(in: endOfLine + 1 ..< startOfLine)
            }
        }
    }
}
