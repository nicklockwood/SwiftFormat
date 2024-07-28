//
//  blankLinesBetweenScopes.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

public extension FormatRule {
    /// Adds a blank line immediately after a closing brace, unless followed by another closing brace
    static let blankLinesBetweenScopes = FormatRule(
        help: """
        Insert blank line before class, struct, enum, extension, protocol or function
        declarations.
        """,
        sharedOptions: ["linebreaks"]
    ) { formatter in
        var spaceableScopeStack = [true]
        var isSpaceableScopeType = false
        formatter.forEachToken(onlyWhereEnabled: false) { i, token in
            outer: switch token {
            case .keyword("class"),
                 .keyword("actor"),
                 .keyword("struct"),
                 .keyword("extension"),
                 .keyword("enum"):
                isSpaceableScopeType =
                    (formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) != .keyword("import"))
            case .keyword("func"), .keyword("var"):
                isSpaceableScopeType = false
            case .startOfScope("{"):
                spaceableScopeStack.append(isSpaceableScopeType)
                isSpaceableScopeType = false
            case .endOfScope("}"):
                spaceableScopeStack.removeLast()
                guard spaceableScopeStack.last == true,
                      let openingBraceIndex = formatter.index(of: .startOfScope("{"), before: i),
                      formatter.lastIndex(of: .linebreak, in: openingBraceIndex + 1 ..< i) != nil
                else {
                    // Inline braces
                    break
                }
                var i = i
                if let nextTokenIndex = formatter.index(of: .nonSpace, after: i, if: {
                    $0 == .startOfScope("(")
                }), let closingParenIndex = formatter.index(of:
                    .endOfScope(")"), after: nextTokenIndex)
                {
                    i = closingParenIndex
                }
                guard let nextTokenIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i),
                      formatter.isEnabled, formatter.options.insertBlankLines,
                      let firstLinebreakIndex = formatter.index(of: .linebreak, in: i + 1 ..< nextTokenIndex),
                      formatter.index(of: .linebreak, in: firstLinebreakIndex + 1 ..< nextTokenIndex) == nil
                else {
                    break
                }
                if var nextNonCommentIndex =
                    formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i)
                {
                    while formatter.tokens[nextNonCommentIndex] == .startOfScope("#if"),
                          let nextIndex = formatter.index(
                              of: .nonSpaceOrCommentOrLinebreak,
                              after: formatter.endOfLine(at: nextNonCommentIndex)
                          )
                    {
                        nextNonCommentIndex = nextIndex
                    }
                    switch formatter.tokens[nextNonCommentIndex] {
                    case .error, .endOfScope,
                         .operator(".", _), .delimiter(","), .delimiter(":"),
                         .keyword("else"), .keyword("catch"), .keyword("#else"):
                        break outer
                    case .keyword("while"):
                        if let previousBraceIndex = formatter.index(of: .startOfScope("{"), before: i),
                           formatter.last(.nonSpaceOrCommentOrLinebreak, before: previousBraceIndex)
                           == .keyword("repeat")
                        {
                            break outer
                        }
                    default:
                        if formatter.isLabel(at: nextNonCommentIndex), let colonIndex
                            = formatter.index(of: .delimiter(":"), after: nextNonCommentIndex),
                            formatter.next(.nonSpaceOrCommentOrLinebreak, after: colonIndex)
                            == .startOfScope("{")
                        {
                            break outer
                        }
                    }
                }
                switch formatter.tokens[nextTokenIndex] {
                case .startOfScope("//"):
                    if case let .commentBody(body)? = formatter.next(.nonSpace, after: nextTokenIndex),
                       body.trimmingCharacters(in: .whitespaces).lowercased().hasPrefix("sourcery:")
                    {
                        break
                    }
                    formatter.insertLinebreak(at: firstLinebreakIndex)
                default:
                    formatter.insertLinebreak(at: firstLinebreakIndex)
                }
            default:
                break
            }
        }
    }
}
