//
//  SpaceAroundOperators.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Implement the following rules with respect to the spacing around operators:
    /// * Infix operators are separated from their operands by a space on either
    ///   side. Does not affect prefix/postfix operators, as required by syntax.
    /// * Delimiters, such as commas and colons, are consistently followed by a
    ///   single space, unless it appears at the end of a line, and is not
    ///   preceded by a space, unless it appears at the beginning of a line.
    static let spaceAroundOperators = FormatRule(
        help: "Add or remove space around operators or delimiters.",
        options: ["operatorfunc", "nospaceoperators", "ranges", "typedelimiter"]
    ) { formatter in
        formatter.forEachToken { i, token in
            switch token {
            case .operator(_, .none):
                switch formatter.token(at: i + 1) {
                case nil, .linebreak?, .endOfScope?, .operator?, .delimiter?,
                     .startOfScope("(")? where formatter.options.spaceAroundOperatorDeclarations != .insert:
                    break
                case .space?:
                    switch formatter.next(.nonSpaceOrLinebreak, after: i) {
                    case nil, .linebreak?, .endOfScope?, .delimiter?,
                         .startOfScope("(")? where formatter.options.spaceAroundOperatorDeclarations == .remove:
                        formatter.removeToken(at: i + 1)
                    default:
                        break
                    }
                default:
                    formatter.insert(.space(" "), at: i + 1)
                }
            case .operator("?", .postfix), .operator("!", .postfix):
                if let prevToken = formatter.token(at: i - 1),
                   formatter.token(at: i + 1)?.isSpaceOrLinebreak == false,
                   [.keyword("as"), .keyword("try")].contains(prevToken)
                {
                    formatter.insert(.space(" "), at: i + 1)
                }
            case .operator(".", _):
                if formatter.token(at: i + 1)?.isSpace == true {
                    formatter.removeToken(at: i + 1)
                }
                guard let prevIndex = formatter.index(of: .nonSpace, before: i) else {
                    formatter.removeTokens(in: 0 ..< i)
                    break
                }
                let spaceRequired: Bool
                switch formatter.tokens[prevIndex] {
                case .operator(_, .infix), .startOfScope:
                    return
                case let token where token.isUnwrapOperator:
                    if let prevToken = formatter.last(.nonSpace, before: prevIndex),
                       [.keyword("as"), .keyword("try")].contains(prevToken)
                    {
                        spaceRequired = true
                    } else {
                        spaceRequired = false
                    }
                case .operator(_, .prefix):
                    spaceRequired = false
                case let token:
                    spaceRequired = !token.isAttribute && !token.isLvalue
                }
                if formatter.token(at: i - 1)?.isSpaceOrLinebreak == true {
                    if !spaceRequired {
                        formatter.removeToken(at: i - 1)
                    }
                } else if spaceRequired {
                    formatter.insertSpace(" ", at: i)
                }
            case .operator("?", .infix):
                break // Spacing around ternary ? is not optional
            case let .operator(name, .infix) where formatter.options.noSpaceOperators.contains(name) ||
                (formatter.options.spaceAroundRangeOperators == .remove && token.isRangeOperator):
                if formatter.token(at: i + 1)?.isSpace == true,
                   formatter.token(at: i - 1)?.isSpace == true,
                   let nextToken = formatter.next(.nonSpace, after: i),
                   !nextToken.isCommentOrLinebreak, !nextToken.isOperator,
                   let prevToken = formatter.last(.nonSpace, before: i),
                   !prevToken.isCommentOrLinebreak, !prevToken.isOperator || prevToken.isUnwrapOperator
                {
                    formatter.removeToken(at: i + 1)
                    formatter.removeToken(at: i - 1)
                }
            case .operator(_, .infix):
                if token.isRangeOperator, formatter.options.spaceAroundRangeOperators != .insert {
                    break
                }
                if formatter.token(at: i + 1)?.isSpaceOrLinebreak == false {
                    formatter.insert(.space(" "), at: i + 1)
                }
                if formatter.token(at: i - 1)?.isSpaceOrLinebreak == false {
                    formatter.insert(.space(" "), at: i)
                }
            case .operator(_, .prefix):
                if let prevIndex = formatter.index(of: .nonSpace, before: i, if: {
                    [.startOfScope("["), .startOfScope("("), .startOfScope("<")].contains($0)
                }) {
                    formatter.removeTokens(in: prevIndex + 1 ..< i)
                } else if let prevToken = formatter.token(at: i - 1),
                          !prevToken.isSpaceOrLinebreak, !prevToken.isOperator
                {
                    formatter.insert(.space(" "), at: i)
                }
            case .delimiter(":"):
                // TODO: make this check more robust, and remove redundant space
                if formatter.token(at: i + 1)?.isIdentifier == true,
                   formatter.token(at: i + 2) == .delimiter(":")
                {
                    // It's a selector
                    break
                }
                fallthrough
            case .operator(_, .postfix), .delimiter(","), .delimiter(";"), .startOfScope(":"):
                switch formatter.token(at: i + 1) {
                case nil, .space?, .linebreak?, .endOfScope?, .operator?, .delimiter?:
                    break
                default:
                    // Ensure there is a space after the token
                    formatter.insert(.space(" "), at: i + 1)
                }

                let spaceBeforeToken = formatter.token(at: i - 1)?.isSpace == true
                    && formatter.token(at: i - 2)?.isLinebreak == false

                if spaceBeforeToken, formatter.options.typeDelimiterSpacing == .spaceAfter {
                    // Remove space before the token
                    formatter.removeToken(at: i - 1)
                } else if !spaceBeforeToken, formatter.options.typeDelimiterSpacing == .spaced {
                    formatter.insertSpace(" ", at: i)
                }
            default:
                break
            }
        }
    }
}
