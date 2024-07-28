//
//  spaceAroundParens.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

public extension FormatRule {
    /// Implement the following rules with respect to the spacing around parens:
    /// * There is no space between an opening paren and the preceding identifier,
    ///   unless the identifier is one of the specified keywords
    /// * There is no space between an opening paren and the preceding closing brace
    /// * There is no space between an opening paren and the preceding closing square bracket
    /// * There is space between a closing paren and following identifier
    /// * There is space between a closing paren and following opening brace
    /// * There is no space between a closing paren and following opening square bracket
    static let spaceAroundParens = FormatRule(
        help: "Add or remove space around parentheses."
    ) { formatter in
        func spaceAfter(_ keywordOrAttribute: String, index: Int) -> Bool {
            switch keywordOrAttribute {
            case "@autoclosure":
                if formatter.options.swiftVersion < "3",
                   let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: index),
                   formatter.next(.nonSpaceOrCommentOrLinebreak, after: nextIndex) == .identifier("escaping")
                {
                    assert(formatter.tokens[nextIndex] == .startOfScope("("))
                    return false
                }
                return true
            case "@escaping", "@noescape", "@Sendable":
                return true
            case _ where keywordOrAttribute.hasPrefix("@"):
                if let i = formatter.index(of: .startOfScope("("), after: index) {
                    return formatter.isParameterList(at: i)
                }
                return false
            case "private", "fileprivate", "internal",
                 "init", "subscript", "throws":
                return false
            case "await":
                return formatter.options.swiftVersion >= "5.5" ||
                    formatter.options.swiftVersion == .undefined
            default:
                return keywordOrAttribute.first.map { !"@#".contains($0) } ?? true
            }
        }

        formatter.forEach(.startOfScope("(")) { i, _ in
            let index = i - 1
            guard let prevToken = formatter.token(at: index) else {
                return
            }
            switch prevToken {
            case let .keyword(string) where spaceAfter(string, index: index):
                fallthrough
            case .endOfScope("]") where formatter.isInClosureArguments(at: index),
                 .endOfScope(")") where formatter.isAttribute(at: index),
                 .identifier("some") where formatter.isTypePosition(at: index),
                 .identifier("any") where formatter.isTypePosition(at: index),
                 .identifier("borrowing") where formatter.isTypePosition(at: index),
                 .identifier("consuming") where formatter.isTypePosition(at: index),
                 .identifier("isolated") where formatter.isTypePosition(at: index),
                 .identifier("sending") where formatter.isTypePosition(at: index):
                formatter.insert(.space(" "), at: i)
            case .space:
                let index = i - 2
                guard let token = formatter.token(at: index) else {
                    return
                }
                switch token {
                case .identifier("some") where formatter.isTypePosition(at: index),
                     .identifier("any") where formatter.isTypePosition(at: index),
                     .identifier("borrowing") where formatter.isTypePosition(at: index),
                     .identifier("consuming") where formatter.isTypePosition(at: index),
                     .identifier("isolated") where formatter.isTypePosition(at: index),
                     .identifier("sending") where formatter.isTypePosition(at: index):
                    break
                case let .keyword(string) where !spaceAfter(string, index: index):
                    fallthrough
                case .number, .identifier:
                    fallthrough
                case .endOfScope("}"), .endOfScope(">"),
                     .endOfScope("]") where !formatter.isInClosureArguments(at: index),
                     .endOfScope(")") where !formatter.isAttribute(at: index):
                    formatter.removeToken(at: i - 1)
                default:
                    break
                }
            default:
                break
            }
        }
        formatter.forEach(.endOfScope(")")) { i, _ in
            guard let nextToken = formatter.token(at: i + 1) else {
                return
            }
            switch nextToken {
            case .identifier, .keyword, .startOfScope("{"):
                formatter.insert(.space(" "), at: i + 1)
            case .space where formatter.token(at: i + 2) == .startOfScope("["):
                formatter.removeToken(at: i + 1)
            default:
                break
            }
        }
    }
}
