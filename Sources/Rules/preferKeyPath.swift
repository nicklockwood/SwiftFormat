//
//  preferKeyPath.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

extension FormatRule {
    public static let preferKeyPath = FormatRule(
        help: "Convert trivial `map { $0.foo }` closures to keyPath-based syntax."
    ) { formatter in
        formatter.forEach(.startOfScope("{")) { i, _ in
            guard formatter.options.swiftVersion >= "5.2",
                  var prevIndex = formatter.index(of: .nonSpaceOrLinebreak, before: i)
            else {
                return
            }
            var prevToken = formatter.tokens[prevIndex]
            var label: String?
            if prevToken == .delimiter(":"),
               let labelIndex = formatter.index(of: .nonSpace, before: prevIndex),
               case let .identifier(name) = formatter.tokens[labelIndex],
               let prevIndex2 = formatter.index(of: .nonSpaceOrLinebreak, before: labelIndex)
            {
                label = name
                prevToken = formatter.tokens[prevIndex2]
                prevIndex = prevIndex2
            }
            let parenthesized = prevToken == .startOfScope("(")
            if parenthesized {
                prevToken = formatter.last(.nonSpaceOrLinebreak, before: prevIndex) ?? prevToken
            }
            guard case let .identifier(name) = prevToken,
                  ["map", "flatMap", "compactMap", "allSatisfy", "filter", "contains"].contains(name),
                  let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i, if: {
                      $0 == .identifier("$0")
                  }),
                  let endIndex = formatter.endOfScope(at: i),
                  let lastIndex = formatter.index(of: .nonSpaceOrLinebreak, before: endIndex)
            else {
                return
            }
            if let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: endIndex),
               formatter.isLabel(at: nextIndex)
            {
                return
            }
            if name == "contains" {
                if label != "where" {
                    return
                }
            } else if label != nil {
                return
            }
            var replacementTokens: [Token]
            if nextIndex == lastIndex {
                // TODO: add this when https://bugs.swift.org/browse/SR-12897 is fixed
                // replacementTokens = tokenize("\\.self")
                return
            } else {
                let tokens = formatter.tokens[nextIndex + 1 ... lastIndex]
                guard tokens.allSatisfy({ $0.isSpace || $0.isIdentifier || $0.isOperator(".") }) else {
                    return
                }
                replacementTokens = [.operator("\\", .prefix)] + tokens
            }
            if let label = label {
                replacementTokens = [.identifier(label), .delimiter(":"), .space(" ")] + replacementTokens
            }
            if !parenthesized {
                replacementTokens = [.startOfScope("(")] + replacementTokens + [.endOfScope(")")]
            }
            formatter.replaceTokens(in: prevIndex + 1 ... endIndex, with: replacementTokens)
        }
    }
}
