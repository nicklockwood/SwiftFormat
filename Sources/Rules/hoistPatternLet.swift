//
//  HoistPatternLet.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Move `let` and `var` inside patterns to the beginning
    static let hoistPatternLet = FormatRule(
        help: "Reposition `let` or `var` bindings within pattern.",
        options: ["patternlet"]
    ) { formatter in
        func indicesOf(_ keyword: String, in range: CountableRange<Int>) -> [Int]? {
            var indices = [Int]()
            var keywordFound = false, identifierFound = false
            var count = 0
            for index in range {
                switch formatter.tokens[index] {
                case .keyword(keyword):
                    indices.append(index)
                    keywordFound = true
                case .identifier("_"):
                    break
                case .identifier where formatter.last(.nonSpaceOrComment, before: index) != .operator(".", .prefix):
                    identifierFound = true
                    if keywordFound {
                        count += 1
                    }
                case .delimiter(","):
                    guard keywordFound || !identifierFound else {
                        return nil
                    }
                    keywordFound = false
                    identifierFound = false
                case .startOfScope("{"):
                    return nil
                case .startOfScope("<"):
                    // See: https://github.com/nicklockwood/SwiftFormat/issues/768
                    return nil
                default:
                    break
                }
            }
            return (keywordFound || !identifierFound) && count > 0 ? indices : nil
        }

        formatter.forEach(.startOfScope("(")) { i, _ in
            let hoist = formatter.options.hoistPatternLet
            // Check if pattern already starts with let/var
            guard let endIndex = formatter.index(of: .endOfScope(")"), after: i),
                  let prevIndex = formatter.index(before: i, where: {
                      switch $0 {
                      case .operator(".", _), .keyword("let"), .keyword("var"),
                           .endOfScope("*/"):
                          return false
                      case .endOfScope, .delimiter, .operator, .keyword:
                          return true
                      default:
                          return false
                      }
                  })
            else {
                return
            }
            switch formatter.tokens[prevIndex] {
            case .endOfScope("case"), .keyword("case"), .keyword("catch"):
                break
            case .delimiter(","):
                loop: for token in formatter.tokens[0 ..< prevIndex].reversed() {
                    switch token {
                    case .endOfScope("case"), .keyword("catch"):
                        break loop
                    case .keyword("var"), .keyword("let"):
                        break
                    case .keyword:
                        // Tuple assignment
                        return
                    default:
                        break
                    }
                }
            default:
                return
            }
            let startIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: prevIndex)
                ?? (prevIndex + 1)
            if case let .keyword(keyword) = formatter.tokens[startIndex],
               ["let", "var"].contains(keyword)
            {
                if hoist {
                    // No changes needed
                    return
                }
                // Find variable indices
                var indices = [Int]()
                var index = i + 1
                var wasParenOrCommaOrLabel = true
                while index < endIndex {
                    let token = formatter.tokens[index]
                    switch token {
                    case .delimiter(","), .startOfScope("("), .delimiter(":"):
                        wasParenOrCommaOrLabel = true
                    case .identifier("_"), .identifier("true"), .identifier("false"), .identifier("nil"):
                        wasParenOrCommaOrLabel = false
                    case let .identifier(name) where wasParenOrCommaOrLabel:
                        wasParenOrCommaOrLabel = false
                        let next = formatter.next(.nonSpaceOrComment, after: index)
                        if next != .operator(".", .infix), next != .delimiter(":") {
                            indices.append(index)
                        }
                    case _ where token.isSpaceOrCommentOrLinebreak:
                        break
                    case .startOfScope("["):
                        guard let next = formatter.endOfScope(at: index) else {
                            return formatter.fatalError("Expected ]", at: index)
                        }
                        index = next
                    default:
                        wasParenOrCommaOrLabel = false
                    }
                    index += 1
                }
                // Insert keyword at indices
                for index in indices.reversed() {
                    formatter.insert([.keyword(keyword), .space(" ")], at: index)
                }
                // Remove keyword
                let range = ((formatter.index(of: .nonSpace, before: startIndex) ??
                        (prevIndex - 1)) + 1) ... startIndex
                formatter.removeTokens(in: range)
            } else if hoist {
                // Find let/var keyword indices
                var keyword = "let"
                guard let indices: [Int] = {
                    guard let indices = indicesOf(keyword, in: i + 1 ..< endIndex) else {
                        keyword = "var"
                        return indicesOf(keyword, in: i + 1 ..< endIndex)
                    }
                    return indices
                }() else {
                    return
                }
                // Remove keywords inside parens
                for index in indices.reversed() {
                    if formatter.tokens[index + 1].isSpace {
                        formatter.removeToken(at: index + 1)
                    }
                    formatter.removeToken(at: index)
                }
                // Insert keyword before parens
                formatter.insert(.keyword(keyword), at: startIndex)
                if let nextToken = formatter.token(at: startIndex + 1), !nextToken.isSpaceOrLinebreak {
                    formatter.insert(.space(" "), at: startIndex + 1)
                }
                if let prevToken = formatter.token(at: startIndex - 1),
                   !prevToken.isSpaceOrCommentOrLinebreak, !prevToken.isStartOfScope
                {
                    formatter.insert(.space(" "), at: startIndex)
                }
            }
        }
    }
}
