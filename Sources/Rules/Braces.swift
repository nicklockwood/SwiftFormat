//
//  Braces.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 10/27/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Implement brace-wrapping rules
    static let braces = FormatRule(
        help: "Wrap braces in accordance with selected style (K&R or Allman).",
        examples: """
        ```diff
        - if x
        - {
            // foo
          }
        - else
        - {
            // bar
          }

        + if x {
            // foo
          }
        + else {
            // bar
          }
        ```
        """,
        options: ["allman"],
        sharedOptions: ["linebreaks", "maxwidth", "indent", "tabwidth", "assetliterals"]
    ) { formatter in
        formatter.forEach(.startOfScope("{")) { i, _ in
            guard let closingBraceIndex = formatter.endOfScope(at: i),
                  // Check this isn't an inline block
                  formatter.index(of: .linebreak, in: i + 1 ..< closingBraceIndex) != nil,
                  let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: i),
                  ![.delimiter(","), .keyword("in")].contains(prevToken),
                  !prevToken.is(.startOfScope)
            else {
                return
            }
            if let penultimateToken = formatter.last(.nonSpaceOrComment, before: closingBraceIndex),
               !penultimateToken.isLinebreak
            {
                formatter.insertSpace(formatter.currentIndentForLine(at: i), at: closingBraceIndex)
                formatter.insertLinebreak(at: closingBraceIndex)
                if formatter.token(at: closingBraceIndex - 1)?.isSpace == true {
                    formatter.removeToken(at: closingBraceIndex - 1)
                }
            }
            if formatter.options.allmanBraces {
                // Implement Allman-style braces, where opening brace appears on the next line
                switch formatter.last(.nonSpace, before: i) ?? .space("") {
                case .identifier, .keyword, .endOfScope, .number,
                     .operator("?", .postfix), .operator("!", .postfix):
                    formatter.insertLinebreak(at: i)
                    if let breakIndex = formatter.index(of: .linebreak, after: i + 1),
                       let nextIndex = formatter.index(of: .nonSpace, after: breakIndex, if: { $0.isLinebreak })
                    {
                        formatter.removeTokens(in: breakIndex ..< nextIndex)
                    }
                    formatter.insertSpace(formatter.currentIndentForLine(at: i), at: i + 1)
                    if formatter.tokens[i - 1].isSpace {
                        formatter.removeToken(at: i - 1)
                    }
                default:
                    break
                }
            } else {
                // Implement K&R-style braces, where opening brace appears on the same line
                guard let prevIndex = formatter.index(of: .nonSpaceOrLinebreak, before: i),
                      formatter.tokens[prevIndex ..< i].contains(where: { $0.isLinebreak }),
                      !formatter.tokens[prevIndex].isComment
                else {
                    return
                }

                var maxWidth = formatter.options.maxWidth
                if maxWidth == 0 {
                    maxWidth = .max
                }

                // Check that unwrapping wouldn't exceed line length
                let endOfLine = formatter.endOfLine(at: i)
                let length = formatter.lineLength(from: i, upTo: endOfLine)
                let prevLineLength = formatter.lineLength(at: prevIndex)
                guard prevLineLength + length + 1 <= maxWidth else {
                    return
                }

                // Avoid conflicts with wrapMultilineStatementBraces
                // (Can't refer to `FormatRule.wrapMultilineStatementBraces` directly
                // because it creates a cicrcular reference)
                if formatter.options.enabledRules.contains("wrapMultilineStatementBraces"),
                   formatter.shouldWrapMultilineStatementBrace(at: i)
                {
                    return
                }
                formatter.replaceTokens(in: prevIndex + 1 ..< i, with: .space(" "))
            }
        }
    }
}
