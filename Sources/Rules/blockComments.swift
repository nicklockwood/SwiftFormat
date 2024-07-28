//
//  blockComments.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

public extension FormatRule {
    static let blockComments = FormatRule(
        help: "Convert block comments to consecutive single line comments.",
        disabledByDefault: true
    ) { formatter in
        formatter.forEachToken { i, token in
            switch token {
            case .startOfScope("/*"):
                guard var endIndex = formatter.endOfScope(at: i) else {
                    return formatter.fatalError("Expected */", at: i)
                }

                // We can only convert block comments to single-line comments
                // if there are no non-comment tokens on the same line.
                //  - For example, we can't convert `if foo { /* code */ }`
                //    to a line comment because it would comment out the closing brace.
                //
                // To guard against this, we verify that there is only
                // comment or whitespace tokens on the remainder of this line
                guard formatter.next(.nonSpace, after: endIndex)?.isLinebreak != false else {
                    return
                }

                var isDocComment = false
                var stripLeadingStars = true
                func replaceCommentBody(at index: Int) -> Int {
                    var delta = 0
                    var space = ""
                    if case let .space(s) = formatter.tokens[index] {
                        formatter.removeToken(at: index)
                        space = s
                        delta -= 1
                    }
                    if case let .commentBody(body)? = formatter.token(at: index) {
                        var body = Substring(body)
                        if stripLeadingStars {
                            if body.hasPrefix("*") {
                                body = body.drop(while: { $0 == "*" })
                            } else {
                                stripLeadingStars = false
                            }
                        }
                        let prefix = isDocComment ? "/" : ""
                        if !prefix.isEmpty || !body.isEmpty, !body.hasPrefix(" ") {
                            space += " "
                        }
                        formatter.replaceToken(
                            at: index,
                            with: .commentBody(prefix + space + body)
                        )
                    } else if isDocComment {
                        formatter.insert(.commentBody("/"), at: index)
                        delta += 1
                    }
                    return delta
                }

                // Replace opening delimiter
                var startIndex = i
                let indent = formatter.currentIndentForLine(at: i)
                if case let .commentBody(body) = formatter.tokens[i + 1] {
                    isDocComment = body.hasPrefix("*")
                    let commentBody = body.drop(while: { $0 == "*" })
                    formatter.replaceToken(at: i + 1, with: .commentBody("/" + commentBody))
                }
                formatter.replaceToken(at: i, with: .startOfScope("//"))
                if let nextToken = formatter.token(at: i + 1),
                   nextToken.isSpaceOrLinebreak || nextToken.string == (isDocComment ? "/" : ""),
                   let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i + 1),
                   nextIndex > i + 2
                {
                    let range = i + 1 ..< nextIndex
                    formatter.removeTokens(in: range)
                    endIndex -= range.count
                    startIndex = i + 1
                    endIndex += replaceCommentBody(at: startIndex)
                }

                // Replace ending delimiter
                if let i = formatter.index(of: .nonSpace, before: endIndex, if: {
                    $0.isLinebreak
                }) {
                    let range = i ... endIndex
                    formatter.removeTokens(in: range)
                    endIndex -= range.count
                }

                // remove /* and */
                var index = i
                while index <= endIndex {
                    switch formatter.tokens[index] {
                    case .startOfScope("/*"):
                        formatter.removeToken(at: index)
                        endIndex -= 1
                        if formatter.tokens[index - 1].isSpace {
                            formatter.removeToken(at: index - 1)
                            index -= 1
                            endIndex -= 1
                        }
                    case .endOfScope("*/"):
                        formatter.removeToken(at: index)
                        endIndex -= 1
                        if formatter.tokens[index - 1].isSpace {
                            formatter.removeToken(at: index - 1)
                            index -= 1
                            endIndex -= 1
                        }
                    case .linebreak:
                        endIndex += formatter.insertSpace(indent, at: index + 1)
                        guard let i = formatter.index(of: .nonSpace, after: index) else {
                            index += 1
                            continue
                        }
                        index = i
                        formatter.insert(.startOfScope("//"), at: index)
                        var delta = 1 + replaceCommentBody(at: index + 1)
                        index += delta
                        endIndex += delta
                    default:
                        index += 1
                    }
                }
            default:
                break
            }
        }
    }
}
