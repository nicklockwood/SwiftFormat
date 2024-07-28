//
//  andOperator.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Replace the `&&` operator with `,` where applicable
    static let andOperator = FormatRule(
        help: "Prefer comma over `&&` in `if`, `guard` or `while` conditions."
    ) { formatter in
        formatter.forEachToken { i, token in
            switch token {
            case .keyword("if"), .keyword("guard"),
                 .keyword("while") where formatter.last(.keyword, before: i) != .keyword("repeat"):
                break
            default:
                return
            }
            guard var endIndex = formatter.index(of: .startOfScope("{"), after: i) else {
                return
            }
            if formatter.options.swiftVersion < "5.3", formatter.isInResultBuilder(at: i) {
                return
            }
            var index = i + 1
            var chevronIndex: Int?
            outer: while index < endIndex {
                switch formatter.tokens[index] {
                case .operator("&&", .infix):
                    let endOfGroup = formatter.index(of: .delimiter(","), after: index) ?? endIndex
                    var nextOpIndex = index
                    while let next = formatter.index(of: .operator, after: nextOpIndex) {
                        if formatter.tokens[next] == .operator("||", .infix) {
                            index = endOfGroup
                            continue outer
                        }
                        nextOpIndex = next
                    }
                    if let chevronIndex = chevronIndex,
                       formatter.index(of: .operator(">", .infix), in: index ..< endIndex) != nil
                    {
                        // Check if this would cause ambiguity for chevrons
                        var tokens = Array(formatter.tokens[i ... endIndex])
                        tokens[index - i] = .delimiter(",")
                        tokens.append(.endOfScope("}"))
                        let reparsed = tokenize(sourceCode(for: tokens))
                        if reparsed[chevronIndex - i] == .startOfScope("<") {
                            return
                        }
                    }
                    formatter.replaceToken(at: index, with: .delimiter(","))
                    if formatter.tokens[index - 1] == .space(" ") {
                        formatter.removeToken(at: index - 1)
                        endIndex -= 1
                        index -= 1
                    } else if let prevIndex = formatter.index(of: .nonSpace, before: index),
                              formatter.tokens[prevIndex].isLinebreak, let nonLinbreak =
                              formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: prevIndex)
                    {
                        formatter.removeToken(at: index)
                        formatter.insert(.delimiter(","), at: nonLinbreak + 1)
                        if formatter.tokens[index + 1] == .space(" ") {
                            formatter.removeToken(at: index + 1)
                            endIndex -= 1
                        }
                    }
                case .operator("<", .infix):
                    chevronIndex = index
                case .operator("||", .infix), .operator("=", .infix), .keyword("try"):
                    index = formatter.index(of: .delimiter(","), after: index) ?? endIndex
                case .startOfScope:
                    index = formatter.endOfScope(at: index) ?? endIndex
                default:
                    break
                }
                index += 1
            }
        }
    }
}
