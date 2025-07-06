//
//  WrapSingleLineComments.swift
//  SwiftFormat
//
//  Created by Max Desiatov on 8/11/22.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Wrap single-line comments that exceed given `FormatOptions.maxWidth` setting.
    static let wrapSingleLineComments = FormatRule(
        help: "Wrap single line `//` comments that exceed the specified `--max-width`.",
        sharedOptions: ["max-width", "indent", "tab-width", "asset-literals", "line-breaks"]
    ) { formatter in
        let delimiterLength = "//".count
        var maxWidth = formatter.options.maxWidth
        guard maxWidth > 3 else {
            return
        }

        formatter.forEach(.startOfScope("//")) { i, _ in
            let startOfLine = formatter.startOfLine(at: i)
            let endOfLine = formatter.endOfLine(at: i)
            guard formatter.lineLength(from: startOfLine, upTo: endOfLine) > maxWidth else {
                return
            }

            guard let startIndex = formatter.index(of: .nonSpace, after: i),
                  case var .commentBody(comment) = formatter.tokens[startIndex],
                  !comment.isCommentDirective
            else {
                return
            }

            var words = comment.components(separatedBy: " ")
            comment = words.removeFirst()
            let commentPrefix = comment == "/" ? "/ " : comment.hasPrefix("/") ? "/" : ""
            let prefixLength = formatter.lineLength(upTo: startIndex)
            var length = prefixLength + comment.count
            while length <= maxWidth, let next = words.first,
                  length + next.count < maxWidth ||
                  // Don't wrap if next word won't fit on a line by itself anyway
                  prefixLength + commentPrefix.count + next.count > maxWidth
            {
                comment += " \(next)"
                length += next.count + 1
                words.removeFirst()
            }
            if words.isEmpty || comment == commentPrefix {
                return
            }
            var prefix = formatter.tokens[i ..< startIndex]
            if let token = formatter.token(at: startOfLine), case .space = token {
                prefix.insert(token, at: prefix.startIndex)
            }
            formatter.replaceTokens(in: startIndex ..< endOfLine, with: [
                .commentBody(comment), formatter.linebreakToken(for: startIndex),
            ] + prefix + [
                .commentBody(commentPrefix + words.joined(separator: " ")),
            ])
        }
    } examples: {
        nil
    }
}
