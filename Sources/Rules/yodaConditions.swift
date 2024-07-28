//
//  yodaConditions.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

extension FormatRule {
    /// Reorders "yoda conditions" where constant is placed on lhs of a comparison
    public static let yodaConditions = FormatRule(
        help: "Prefer constant values to be on the right-hand-side of expressions.",
        options: ["yodaswap"]
    ) { formatter in
        func valuesInRangeAreConstant(_ range: CountableRange<Int>) -> Bool {
            var index = formatter.index(of: .nonSpaceOrCommentOrLinebreak, in: range)
            while var i = index {
                switch formatter.tokens[i] {
                case .startOfScope where isConstant(at: i):
                    guard let endIndex = formatter.index(of: .endOfScope, after: i) else {
                        return false
                    }
                    i = endIndex
                    fallthrough
                case _ where isConstant(at: i), .delimiter(","), .delimiter(":"):
                    index = formatter.index(of: .nonSpaceOrCommentOrLinebreak, in: i + 1 ..< range.upperBound)
                case .identifier:
                    guard let nextIndex =
                        formatter.index(of: .nonSpaceOrComment, in: i + 1 ..< range.upperBound),
                        formatter.tokens[nextIndex] == .delimiter(":")
                    else {
                        return false
                    }
                    // Identifier is a label
                    index = nextIndex
                default:
                    return false
                }
            }
            return true
        }
        func isConstant(at index: Int) -> Bool {
            var index = index
            while case .operator(_, .postfix) = formatter.tokens[index] {
                index -= 1
            }
            guard let token = formatter.token(at: index) else {
                return false
            }
            switch token {
            case .number, .identifier("true"), .identifier("false"), .identifier("nil"):
                return true
            case .endOfScope("]"), .endOfScope(")"):
                guard let startIndex = formatter.index(of: .startOfScope, before: index),
                      !formatter.isSubscriptOrFunctionCall(at: startIndex)
                else {
                    return false
                }
                return valuesInRangeAreConstant(startIndex + 1 ..< index)
            case .startOfScope("["), .startOfScope("("):
                guard !formatter.isSubscriptOrFunctionCall(at: index),
                      let endIndex = formatter.index(of: .endOfScope, after: index)
                else {
                    return false
                }
                return valuesInRangeAreConstant(index + 1 ..< endIndex)
            case .startOfScope, .endOfScope:
                // TODO: what if string contains interpolation?
                return token.isStringDelimiter
            case _ where formatter.options.yodaSwap == .literalsOnly:
                // Don't treat .members as constant
                return false
            case .operator(".", .prefix) where formatter.token(at: index + 1)?.isIdentifier == true,
                 .identifier where formatter.token(at: index - 1) == .operator(".", .prefix) &&
                     formatter.token(at: index - 2) != .operator("\\", .prefix):
                return true
            default:
                return false
            }
        }
        func isOperator(at index: Int?) -> Bool {
            guard let index = index else {
                return false
            }
            switch formatter.tokens[index] {
            // Discount operators with higher precedence than ==
            case .operator("=", .infix),
                 .operator("&&", .infix), .operator("||", .infix),
                 .operator("?", .infix), .operator(":", .infix):
                return false
            case .operator(_, .infix), .keyword("as"), .keyword("is"):
                return true
            default:
                return false
            }
        }
        func startOfValue(at index: Int) -> Int? {
            var index = index
            while case .operator(_, .postfix)? = formatter.token(at: index) {
                index -= 1
            }
            if case .endOfScope? = formatter.token(at: index) {
                guard let i = formatter.index(of: .startOfScope, before: index) else {
                    return nil
                }
                index = i
            }
            while case .operator(_, .prefix)? = formatter.token(at: index - 1) {
                index -= 1
            }
            return index
        }

        formatter.forEachToken { i, token in
            guard case let .operator(op, .infix) = token,
                  let opIndex = ["==", "!=", "<", "<=", ">", ">="].firstIndex(of: op),
                  let prevIndex = formatter.index(of: .nonSpace, before: i),
                  isConstant(at: prevIndex), let startIndex = startOfValue(at: prevIndex),
                  !isOperator(at: formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: startIndex)),
                  let nextIndex = formatter.index(of: .nonSpace, after: i), !isConstant(at: nextIndex) ||
                  isOperator(at: formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: nextIndex)),
                  let endIndex = formatter.endOfExpression(at: nextIndex, upTo: [
                      .operator("&&", .infix), .operator("||", .infix),
                      .operator("?", .infix), .operator(":", .infix),
                  ])
            else {
                return
            }
            let inverseOp = ["==", "!=", ">", ">=", "<", "<="][opIndex]
            let expression = Array(formatter.tokens[nextIndex ... endIndex])
            let constant = Array(formatter.tokens[startIndex ... prevIndex])
            formatter.replaceTokens(in: nextIndex ... endIndex, with: constant)
            formatter.replaceToken(at: i, with: .operator(inverseOp, .infix))
            formatter.replaceTokens(in: startIndex ... prevIndex, with: expression)
        }
    }
}
