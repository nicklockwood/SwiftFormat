//
//  LeadingDelimiters.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 3/11/19.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let leadingDelimiters = FormatRule(
        help: "Move leading delimiters to the end of the previous line.",
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEach(.delimiter) { i, _ in
            guard let endOfLine = formatter.index(of: .nonSpace, before: i, if: {
                $0.isLinebreak
            }) else {
                return
            }
            let nextIndex = formatter.index(of: .nonSpace, after: i) ?? (i + 1)
            formatter.insertSpace(formatter.currentIndentForLine(at: i), at: nextIndex)
            formatter.insertLinebreak(at: nextIndex)
            formatter.removeTokens(in: i + 1 ..< nextIndex)
            guard case .commentBody? = formatter.last(.nonSpace, before: endOfLine) else {
                formatter.removeTokens(in: endOfLine ..< i)
                return
            }
            let startIndex = formatter.index(of: .nonSpaceOrComment, before: endOfLine) ?? -1
            formatter.removeTokens(in: endOfLine ..< i)
            let comment = Array(formatter.tokens[startIndex + 1 ..< endOfLine])
            formatter.insert(comment, at: endOfLine + 1)
            formatter.removeTokens(in: startIndex + 1 ..< endOfLine)
        }
    } examples: {
        """
        ```diff
        - guard let foo = maybeFoo // first
        -     , let bar = maybeBar else { ... }

        + guard let foo = maybeFoo, // first
        +      let bar = maybeBar else { ... }
        ```
        """
    }
}
