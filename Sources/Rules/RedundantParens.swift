//
//  RedundantParens.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 11/2/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove redundant parens around the arguments for loops, if statements, closures, etc.
    static let redundantParens = FormatRule(
        help: "Remove redundant parentheses."
    ) { formatter in
        // TODO: unify with conditionals logic in trailingClosures
        let conditionals = Set(["in", "while", "if", "case", "switch", "where", "for", "guard"])

        formatter.forEach(.startOfScope("(")) { i, _ in
            guard var closingIndex = formatter.index(of: .endOfScope(")"), after: i),
                  formatter.next(.nonSpaceOrCommentOrLinebreak, after: i) != .keyword("repeat")
            else {
                return
            }
            var innerParens = formatter.nestedParens(in: i ... closingIndex)
            while let range = innerParens, formatter.nestedParens(in: range) != nil {
                // TODO: this could be a lot more efficient if we kept track of the
                // removed token indices instead of recalculating paren positions every time
                formatter.removeParen(at: range.upperBound)
                formatter.removeParen(at: range.lowerBound)
                closingIndex = formatter.index(of: .endOfScope(")"), after: i)!
                innerParens = formatter.nestedParens(in: i ... closingIndex)
            }
            var isClosure = false
            let previousIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i) ?? -1
            let prevToken = formatter.token(at: previousIndex) ?? .space("")
            let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: closingIndex) ?? .space("")
            switch nextToken {
            case .operator("->", .infix), .keyword("throws"), .keyword("rethrows"),
                 .identifier("async"), .keyword("in"):
                if prevToken != .keyword("throws"),
                   formatter.index(before: i, where: {
                       [.endOfScope(")"), .operator("->", .infix), .keyword("for")].contains($0)
                   }) == nil,
                   let scopeIndex = formatter.startOfScope(at: i)
                {
                    isClosure = formatter.isStartOfClosure(at: scopeIndex) && formatter.isInClosureArguments(at: i)
                }
                if !isClosure, nextToken != .keyword("in") {
                    return // It's a closure type, function declaration or for loop
                }
            case .operator:
                if let prevToken = formatter.last(.nonSpace, before: closingIndex),
                   prevToken.isOperator, !prevToken.isUnwrapOperator
                {
                    return
                }
            default:
                break
            }
            switch prevToken {
            case .stringBody, .operator("?", .postfix), .operator("!", .postfix), .operator("->", .infix):
                return
            case .identifier: // TODO: are trailing closures allowed in other cases?
                // Parens before closure
                guard closingIndex == formatter.index(of: .nonSpace, after: i),
                      let openingIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: closingIndex, if: {
                          $0 == .startOfScope("{")
                      }),
                      formatter.isStartOfClosure(at: openingIndex)
                else {
                    return
                }
                formatter.removeParen(at: closingIndex)
                formatter.removeParen(at: i)
            case _ where isClosure:
                if formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i) == closingIndex ||
                    formatter.index(of: .delimiter(":"), in: i + 1 ..< closingIndex) != nil ||
                    formatter.tokens[i + 1 ..< closingIndex].contains(.identifier("self"))
                {
                    return
                }
                if let index = formatter.tokens[i + 1 ..< closingIndex].firstIndex(of: .identifier("_")),
                   formatter.next(.nonSpaceOrComment, after: index)?.isIdentifier == true
                {
                    return
                }
                formatter.removeParen(at: closingIndex)
                formatter.removeParen(at: i)
            case let .keyword(name) where !conditionals.contains(name) && !["let", "var", "return"].contains(name):
                return
            case .endOfScope("}"), .endOfScope(")"), .endOfScope("]"), .endOfScope(">"):
                if formatter.tokens[previousIndex + 1 ..< i].contains(where: \.isLinebreak) {
                    fallthrough
                }
                return // Probably a method invocation
            case .delimiter(","), .endOfScope, .keyword:
                let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: closingIndex) ?? .space("")
                guard formatter.index(of: .endOfScope("}"), before: closingIndex) == nil,
                      ![.endOfScope("}"), .endOfScope(">")].contains(prevToken) ||
                      ![.startOfScope("{"), .delimiter(",")].contains(nextToken)
                else {
                    return
                }
                let string = prevToken.string
                if ![.startOfScope("{"), .delimiter(","), .startOfScope(":")].contains(nextToken),
                   !(string == "for" && nextToken == .keyword("in")),
                   !(string == "guard" && nextToken == .keyword("else"))
                {
                    // TODO: this is confusing - refactor to move fallthrough to end of case
                    fallthrough
                }
                if formatter.index(of: .nonSpaceOrCommentOrLinebreak, in: i + 1 ..< closingIndex) == nil ||
                    formatter.index(of: .delimiter(","), in: i + 1 ..< closingIndex) != nil
                {
                    // Might be a tuple, so we won't remove the parens
                    // TODO: improve the logic here so we don't misidentify function calls as tuples
                    return
                }
                formatter.removeParen(at: closingIndex)
                formatter.removeParen(at: i)
            case .operator(_, .infix):
                guard let nextIndex = formatter.index(of: .nonSpaceOrComment, after: i, if: {
                    $0 == .startOfScope("{")
                }), let lastIndex = formatter.index(of: .endOfScope("}"), after: nextIndex),
                formatter.index(of: .nonSpaceOrComment, before: closingIndex) == lastIndex else {
                    fallthrough
                }
                formatter.removeParen(at: closingIndex)
                formatter.removeParen(at: i)
            default:
                if let range = innerParens {
                    formatter.removeParen(at: range.upperBound)
                    formatter.removeParen(at: range.lowerBound)
                    closingIndex = formatter.index(of: .endOfScope(")"), after: i)!
                    innerParens = nil
                }
                if prevToken == .startOfScope("("),
                   formatter.last(.nonSpaceOrComment, before: previousIndex) == .identifier("Selector")
                {
                    return
                }
                if case .operator = formatter.tokens[closingIndex - 1],
                   case .operator(_, .infix)? = formatter.token(at: closingIndex + 1)
                {
                    return
                }
                let nextNonLinebreak = formatter.next(.nonSpaceOrComment, after: closingIndex)
                if let index = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i),
                   case .operator = formatter.tokens[index]
                {
                    if nextToken.isOperator(".") || (index == i + 1 &&
                        formatter.token(at: i - 1)?.isSpaceOrCommentOrLinebreak == false)
                    {
                        return
                    }
                    switch nextNonLinebreak {
                    case .startOfScope("[")?, .startOfScope("(")?, .operator(_, .postfix)?:
                        return
                    default:
                        break
                    }
                }
                guard formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i) != closingIndex,
                      formatter.index(in: i + 1 ..< closingIndex, where: {
                          switch $0 {
                          case .operator(_, .infix), .identifier("any"), .identifier("some"), .identifier("each"),
                               .keyword("as"), .keyword("is"), .keyword("try"), .keyword("await"):
                              switch prevToken {
                              // TODO: add option to always strip parens in this case (or only for boolean operators?)
                              case .operator("=", .infix) where $0 == .operator("->", .infix):
                                  break
                              case .operator(_, .prefix), .operator(_, .infix), .keyword("as"), .keyword("is"):
                                  return true
                              default:
                                  break
                              }
                              switch nextToken {
                              case .operator(_, .postfix), .operator(_, .infix), .keyword("as"), .keyword("is"):
                                  return true
                              default:
                                  break
                              }
                              switch nextNonLinebreak {
                              case .startOfScope("[")?, .startOfScope("(")?, .operator(_, .postfix)?:
                                  return true
                              default:
                                  return false
                              }
                          case .operator(_, .postfix):
                              switch prevToken {
                              case .operator(_, .prefix), .keyword("as"), .keyword("is"):
                                  return true
                              default:
                                  return false
                              }
                          case .delimiter(","), .delimiter(":"), .delimiter(";"),
                               .operator(_, .none), .startOfScope("{"):
                              return true
                          default:
                              return false
                          }
                      }) == nil,
                      formatter.index(in: i + 1 ..< closingIndex, where: { $0.isUnwrapOperator }) ?? closingIndex >=
                      formatter.index(of: .nonSpace, before: closingIndex) ?? closingIndex - 1
                else {
                    return
                }
                if formatter.next(.nonSpaceOrCommentOrLinebreak, after: i) == .keyword("#file") {
                    return
                }
                formatter.removeParen(at: closingIndex)
                formatter.removeParen(at: i)
            }
        }
    } examples: {
        """
        ```diff
        - if (foo == true) {}
        + if foo == true {}
        ```

        ```diff
        - while (i < bar.count) {}
        + while i < bar.count {}
        ```

        ```diff
        - queue.async() { ... }
        + queue.async { ... }
        ```

        ```diff
        - let foo: Int = ({ ... })()
        + let foo: Int = { ... }()
        ```
        """
    }
}

extension Formatter {
    func nestedParens(in range: ClosedRange<Int>) -> ClosedRange<Int>? {
        guard let startIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: range.lowerBound, if: {
            $0 == .startOfScope("(")
        }), let endIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: range.upperBound, if: {
            $0 == .endOfScope(")")
        }), index(of: .endOfScope(")"), after: startIndex) == endIndex else {
            return nil
        }
        return startIndex ... endIndex
    }
}
