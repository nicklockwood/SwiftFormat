//
//  TypeSugar.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Replace Array<T>, Dictionary<T, U> and Optional<T> with [T], [T: U] and T?
    static let typeSugar = FormatRule(
        help: "Prefer shorthand syntax for Arrays, Dictionaries and Optionals.",
        options: ["shortoptionals"]
    ) { formatter in
        formatter.forEach(.startOfScope("<")) { i, _ in
            guard let typeIndex = formatter.index(of: .nonSpaceOrLinebreak, before: i),
                  case let .identifier(identifier) = formatter.tokens[typeIndex],
                  let endIndex = formatter.index(of: .endOfScope(">"), after: i),
                  let typeStart = formatter.index(of: .nonSpaceOrLinebreak, in: i + 1 ..< endIndex),
                  let typeEnd = formatter.lastIndex(of: .nonSpaceOrLinebreak, in: i + 1 ..< endIndex)
            else {
                return
            }
            let dotIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: endIndex, if: {
                $0.isOperator(".")
            })
            if let dotIndex = dotIndex, formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: dotIndex, if: {
                ![.identifier("self"), .identifier("Type")].contains($0)
            }) != nil, identifier != "Optional" {
                return
            }
            // Workaround for https://bugs.swift.org/browse/SR-12856
            if formatter.last(.nonSpaceOrCommentOrLinebreak, before: typeIndex) != .delimiter(":") ||
                formatter.currentScope(at: i) == .startOfScope("[")
            {
                var startIndex = i
                if formatter.tokens[typeIndex] == .identifier("Dictionary") {
                    startIndex = formatter.index(of: .delimiter(","), in: i + 1 ..< endIndex) ?? startIndex
                }
                if let parenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: startIndex, if: {
                    $0 == .startOfScope("(")
                }), let underscoreIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: parenIndex, if: {
                    $0 == .identifier("_")
                }), formatter.next(.nonSpaceOrCommentOrLinebreak, after: underscoreIndex)?.isIdentifier == true {
                    return
                }
            }
            if let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: typeIndex) {
                switch prevToken {
                case .keyword("struct"), .keyword("class"), .keyword("actor"),
                     .keyword("enum"), .keyword("protocol"), .keyword("typealias"):
                    return
                default:
                    break
                }
            }
            switch formatter.tokens[typeIndex] {
            case .identifier("Array"):
                formatter.replaceTokens(in: typeIndex ... endIndex, with:
                    [.startOfScope("[")] + formatter.tokens[typeStart ... typeEnd] + [.endOfScope("]")])
            case .identifier("Dictionary"):
                guard let commaIndex = formatter.index(of: .delimiter(","), in: typeStart ..< typeEnd) else {
                    return
                }
                formatter.replaceToken(at: commaIndex, with: .delimiter(":"))
                formatter.replaceTokens(in: typeIndex ... endIndex, with:
                    [.startOfScope("[")] + formatter.tokens[typeStart ... typeEnd] + [.endOfScope("]")])
            case .identifier("Optional"):
                if formatter.options.shortOptionals == .exceptProperties,
                   let lastKeyword = formatter.lastSignificantKeyword(at: i),
                   ["var", "let"].contains(lastKeyword)
                {
                    return
                }
                if formatter.lastSignificantKeyword(at: i) == "case" ||
                    formatter.last(.endOfScope, before: i) == .endOfScope("case")
                {
                    // https://bugs.swift.org/browse/SR-13838
                    return
                }
                var typeTokens = formatter.tokens[typeStart ... typeEnd]
                if [.operator("&", .infix), .operator("->", .infix),
                    .identifier("some"), .identifier("any")].contains(where: typeTokens.contains)
                {
                    typeTokens.insert(.startOfScope("("), at: typeTokens.startIndex)
                    typeTokens.append(.endOfScope(")"))
                }
                typeTokens.append(.operator("?", .postfix))
                formatter.replaceTokens(in: typeIndex ... endIndex, with: typeTokens)
            default:
                return
            }
            // Drop leading Swift. namespace
            if let dotIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: typeIndex, if: {
                $0.isOperator(".")
            }), let swiftTokenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: dotIndex, if: {
                $0 == .identifier("Swift")
            }) {
                formatter.removeTokens(in: swiftTokenIndex ..< typeIndex)
            }
        }
    }
}
