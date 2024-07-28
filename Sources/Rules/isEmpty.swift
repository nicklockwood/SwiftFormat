//
//  isEmpty.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Replace count == 0 with isEmpty
    static let isEmpty = FormatRule(
        help: "Prefer `isEmpty` over comparing `count` against zero.",
        disabledByDefault: true
    ) { formatter in
        formatter.forEach(.identifier("count")) { i, _ in
            guard let dotIndex = formatter.index(of: .nonSpaceOrLinebreak, before: i, if: {
                $0.isOperator(".")
            }), let opIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i, if: {
                $0.isOperator
            }), let endIndex = formatter.index(of: .nonSpaceOrLinebreak, after: opIndex, if: {
                $0 == .number("0", .integer)
            }) else {
                return
            }
            var isOptional = false
            var index = dotIndex
            var wasIdentifier = false
            loop: while true {
                guard let prev = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: index) else {
                    break
                }
                switch formatter.tokens[prev] {
                case .operator("!", _), .operator(".", _):
                    break // Ignored
                case .operator("?", _):
                    if formatter.tokens[prev - 1].isSpace {
                        break loop
                    }
                    isOptional = true
                case let .operator(op, .infix):
                    guard ["||", "&&", ":"].contains(op) else {
                        return
                    }
                    break loop
                case .keyword, .delimiter, .startOfScope:
                    break loop
                case .identifier:
                    if wasIdentifier {
                        break loop
                    }
                    wasIdentifier = true
                    index = prev
                    continue
                case .endOfScope:
                    guard !wasIdentifier, let start = formatter.index(of: .startOfScope, before: prev) else {
                        break loop
                    }
                    wasIdentifier = false
                    index = start
                    continue
                default:
                    break
                }
                wasIdentifier = false
                index = prev
            }
            let isEmpty: Bool
            switch formatter.tokens[opIndex] {
            case .operator("==", .infix): isEmpty = true
            case .operator("!=", .infix), .operator(">", .infix): isEmpty = false
            default: return
            }
            if isEmpty {
                if isOptional {
                    formatter.replaceTokens(in: i ... endIndex, with: [
                        .identifier("isEmpty"), .space(" "), .operator("==", .infix), .space(" "), .identifier("true"),
                    ])
                } else {
                    formatter.replaceTokens(in: i ... endIndex, with: .identifier("isEmpty"))
                }
            } else {
                if isOptional {
                    formatter.replaceTokens(in: i ... endIndex, with: [
                        .identifier("isEmpty"), .space(" "), .operator("!=", .infix), .space(" "), .identifier("true"),
                    ])
                } else {
                    formatter.replaceTokens(in: i ... endIndex, with: .identifier("isEmpty"))
                    formatter.insert(.operator("!", .prefix), at: index)
                }
            }
        }
    }
}
