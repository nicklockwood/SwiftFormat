//
//  BlankLinesAroundMark.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 11/29/17.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Adds a blank line around MARK: comments
    static let blankLinesAroundMark = FormatRule(
        help: "Insert blank line before and after `MARK:` comments.",
        options: ["lineaftermarks"],
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEachToken { i, token in
            guard case let .commentBody(comment) = token, comment.hasPrefix("MARK:"),
                  let startIndex = formatter.index(of: .nonSpace, before: i),
                  formatter.tokens[startIndex] == .startOfScope("//") else { return }
            if let nextIndex = formatter.index(of: .linebreak, after: i),
               let nextToken = formatter.next(.nonSpace, after: nextIndex),
               !nextToken.isLinebreak, nextToken != .endOfScope("}"),
               formatter.options.lineAfterMarks
            {
                formatter.insertLinebreak(at: nextIndex)
            }
            if formatter.options.insertBlankLines,
               let lastIndex = formatter.index(of: .linebreak, before: startIndex),
               let lastToken = formatter.last(.nonSpace, before: lastIndex),
               !lastToken.isLinebreak, lastToken != .startOfScope("{")
            {
                formatter.insertLinebreak(at: lastIndex)
            }
        }
    }
}
