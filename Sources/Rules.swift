//
//  Rules.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 12/08/2016.
//  Copyright 2016 Nick Lockwood
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/SwiftFormat
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

public typealias FormatRule = (Formatter) -> Void

public class FormatRules: NSObject {
    private override init() {}

    /// A Dictionary of rules by name
    public static let byName: [String: FormatRule] = {
        var rules = [String: FormatRule]()
        var numberOfMethods: CUnsignedInt = 0
        let methods = class_copyMethodList(object_getClass(FormatRules.self), &numberOfMethods)!
        for i in 0 ..< Int(numberOfMethods) {
            let selector: Selector = method_getName(methods[i])
            let name = String(describing: selector)
            if name.hasSuffix(":") {
                let name = String(name.dropLast())
                rules[name] = { formatter in
                    formatter.currentRule = name
                    FormatRules.perform(selector, with: formatter)
                    formatter.currentRule = nil
                }
            }
        }
        return rules
    }()

    /// All rules
    public static let all: [FormatRule] = {
        Array(byName.keys.sorted().compactMap { byName[$0] })
    }()

    /// All rules except those specified
    public static func all(except rules: [String]) -> [FormatRule] {
        var rulesByName = byName
        for name in rules {
            precondition(byName[name] != nil, "`\(name)` is not a valid rule")
            rulesByName[name] = nil
        }
        return Array(rulesByName.keys.sorted().compactMap { rulesByName[$0] })
    }

    public static func all(named: [String]) -> [FormatRule] {
        return Array(named.sorted().compactMap { byName[$0] })
    }

    /// Rules that are disabled by default
    public static let disabledByDefault = ["trailingClosures", "isEmpty"]

    /// Default active rules
    public static let `default` = all(except: disabledByDefault)
}

extension FormatRules {
    /// Implement the following rules with respect to the spacing around parens:
    /// * There is no space between an opening paren and the preceding identifier,
    ///   unless the identifier is one of the specified keywords
    /// * There is no space between an opening paren and the preceding closing brace
    /// * There is no space between an opening paren and the preceding closing square bracket
    /// * There is space between a closing paren and following identifier
    /// * There is space between a closing paren and following opening brace
    /// * There is no space between a closing paren and following opening square bracket
    @objc public class func spaceAroundParens(_ formatter: Formatter) {
        func spaceAfter(_ keyword: String, index: Int) -> Bool {
            switch keyword {
            case "@autoclosure":
                if let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: index),
                    formatter.next(.nonSpaceOrCommentOrLinebreak, after: nextIndex) == .identifier("escaping") {
                    assert(formatter.tokens[nextIndex] == .startOfScope("("))
                    return false
                }
                return true
            case "@escaping", "@noescape":
                return true
            case "private", "fileprivate", "internal",
                 "init", "subscript":
                return false
            default:
                return keyword.first.map { !"@#".contains($0) } ?? true
            }
        }

        func isCaptureList(at i: Int) -> Bool {
            assert(formatter.tokens[i] == .endOfScope("]"))
            guard formatter.lastToken(before: i + 1, where: {
                !$0.isSpaceOrCommentOrLinebreak && $0 != .endOfScope("]") }) == .startOfScope("{"),
                let nextToken = formatter.nextToken(after: i, where: {
                    !$0.isSpaceOrCommentOrLinebreak && $0 != .startOfScope("(")
                }),
                [.operator("->", .infix), .keyword("throws"), .keyword("rethrows"), .keyword("in")].contains(nextToken)
            else { return false }
            return true
        }

        func isAttribute(at i: Int) -> Bool {
            assert(formatter.tokens[i] == .endOfScope(")"))
            guard let openParenIndex = formatter.index(of: .startOfScope("("), before: i),
                let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: openParenIndex),
                prevToken.isAttribute else { return false }
            return true
        }

        formatter.forEach(.startOfScope("(")) { i, token in
            guard let prevToken = formatter.token(at: i - 1) else {
                return
            }
            switch prevToken {
            case let .keyword(string) where spaceAfter(string, index: i - 1):
                fallthrough
            case .endOfScope("]") where isCaptureList(at: i - 1),
                 .endOfScope(")") where isAttribute(at: i - 1):
                formatter.insertToken(.space(" "), at: i)
            case .space:
                if let token = formatter.token(at: i - 2) {
                    switch token {
                    case let .keyword(string) where !spaceAfter(string, index: i - 2):
                        fallthrough
                    case .identifier, .number:
                        fallthrough
                    case .endOfScope("}"), .endOfScope(">"),
                         .endOfScope("]") where !isCaptureList(at: i - 2),
                         .endOfScope(")") where !isAttribute(at: i - 2):
                        formatter.removeToken(at: i - 1)
                    default:
                        break
                    }
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
                formatter.insertToken(.space(" "), at: i + 1)
            case .space where formatter.token(at: i + 2) == .startOfScope("["):
                formatter.removeToken(at: i + 1)
            default:
                break
            }
        }
    }

    /// Remove space immediately inside parens
    @objc public class func spaceInsideParens(_ formatter: Formatter) {
        formatter.forEach(.startOfScope("(")) { i, _ in
            if formatter.token(at: i + 1)?.isSpace == true,
                formatter.token(at: i + 2)?.isComment == false {
                formatter.removeToken(at: i + 1)
            }
        }
        formatter.forEach(.endOfScope(")")) { i, _ in
            if formatter.token(at: i - 1)?.isSpace == true,
                formatter.token(at: i - 2)?.isCommentOrLinebreak == false {
                formatter.removeToken(at: i - 1)
            }
        }
    }

    /// Implement the following rules with respect to the spacing around square brackets:
    /// * There is no space between an opening bracket and the preceding identifier,
    ///   unless the identifier is one of the specified keywords
    /// * There is no space between an opening bracket and the preceding closing brace
    /// * There is no space between an opening bracket and the preceding closing square bracket
    /// * There is space between a closing bracket and following identifier
    /// * There is space between a closing bracket and following opening brace
    @objc public class func spaceAroundBrackets(_ formatter: Formatter) {
        formatter.forEach(.startOfScope("[")) { i, token in
            guard let prevToken = formatter.token(at: i - 1) else {
                return
            }
            switch prevToken {
            case .keyword:
                formatter.insertToken(.space(" "), at: i)
            case .space:
                if let token = formatter.token(at: i - 2) {
                    switch token {
                    case .identifier, .number, .endOfScope("]"), .endOfScope("}"), .endOfScope(")"):
                        formatter.removeToken(at: i - 1)
                    default:
                        break
                    }
                }
            default:
                break
            }
        }
        formatter.forEach(.endOfScope("]")) { i, _ in
            guard let nextToken = formatter.token(at: i + 1) else {
                return
            }
            switch nextToken {
            case .identifier, .keyword, .startOfScope("{"):
                formatter.insertToken(.space(" "), at: i + 1)
            case .space where formatter.token(at: i + 2) == .startOfScope("["):
                formatter.removeToken(at: i + 1)
            default:
                break
            }
        }
    }

    /// Remove space immediately inside square brackets
    @objc public class func spaceInsideBrackets(_ formatter: Formatter) {
        formatter.forEach(.startOfScope("[")) { i, _ in
            if formatter.token(at: i + 1)?.isSpace == true,
                formatter.token(at: i + 2)?.isComment == false {
                formatter.removeToken(at: i + 1)
            }
        }
        formatter.forEach(.endOfScope("]")) { i, _ in
            if formatter.token(at: i - 1)?.isSpace == true,
                formatter.token(at: i - 2)?.isCommentOrLinebreak == false {
                formatter.removeToken(at: i - 1)
            }
        }
    }

    /// Ensure that there is space between an opening brace and the preceding
    /// identifier, and between a closing brace and the following identifier.
    @objc public class func spaceAroundBraces(_ formatter: Formatter) {
        formatter.forEach(.startOfScope("{")) { i, _ in
            if let prevToken = formatter.token(at: i - 1) {
                switch prevToken {
                case .space, .linebreak:
                    break
                case let .startOfScope(string) where string != "\"":
                    break
                default:
                    formatter.insertToken(.space(" "), at: i)
                }
            }
        }
        formatter.forEach(.endOfScope("}")) { i, _ in
            if let nextToken = formatter.token(at: i + 1) {
                switch nextToken {
                case .identifier, .keyword:
                    formatter.insertToken(.space(" "), at: i + 1)
                default:
                    break
                }
            }
        }
    }

    /// Ensure that there is space immediately inside braces
    @objc public class func spaceInsideBraces(_ formatter: Formatter) {
        formatter.forEach(.startOfScope("{")) { i, _ in
            if let nextToken = formatter.token(at: i + 1) {
                if nextToken.isSpace {
                    if formatter.token(at: i + 2) == .endOfScope("}") {
                        formatter.removeToken(at: i + 1)
                    }
                } else if !nextToken.isLinebreak, nextToken != .endOfScope("}") {
                    formatter.insertToken(.space(" "), at: i + 1)
                }
            }
        }
        formatter.forEach(.endOfScope("}")) { i, _ in
            if let prevToken = formatter.token(at: i - 1),
                !prevToken.isSpaceOrLinebreak, prevToken != .startOfScope("{") {
                formatter.insertToken(.space(" "), at: i)
            }
        }
    }

    /// Ensure there is no space between an opening chevron and the preceding identifier
    @objc public class func spaceAroundGenerics(_ formatter: Formatter) {
        formatter.forEach(.startOfScope("<")) { i, _ in
            if formatter.token(at: i - 1)?.isSpace == true,
                formatter.token(at: i - 2)?.isIdentifierOrKeyword == true {
                formatter.removeToken(at: i - 1)
            }
        }
    }

    /// Remove space immediately inside chevrons
    @objc public class func spaceInsideGenerics(_ formatter: Formatter) {
        formatter.forEach(.startOfScope("<")) { i, _ in
            if formatter.token(at: i + 1)?.isSpace == true {
                formatter.removeToken(at: i + 1)
            }
        }
        formatter.forEach(.endOfScope(">")) { i, _ in
            if formatter.token(at: i - 1)?.isSpace == true,
                formatter.token(at: i - 2)?.isLinebreak == false {
                formatter.removeToken(at: i - 1)
            }
        }
    }

    /// Implement the following rules with respect to the spacing around operators:
    /// * Infix operators are separated from their operands by a space on either
    ///   side. Does not affect prefix/postfix operators, as required by syntax.
    /// * Delimiters, such as commas and colons, are consistently followed by a
    ///   single space, unless it appears at the end of a line, and is not
    ///   preceded by a space, unless it appears at the beginning of a line.
    @objc public class func spaceAroundOperators(_ formatter: Formatter) {
        formatter.forEachToken { i, token in
            switch token {
            case .operator(_, .none) where formatter.token(at: i + 1)?.isSpace == true:
                let nextToken = formatter.next(.nonSpaceOrLinebreak, after: i)
                if nextToken == nil || nextToken?.isEndOfScope == true ||
                    nextToken == .startOfScope("("), !formatter.options.spaceAroundOperatorDeclarations {
                    formatter.removeToken(at: i + 1)
                }
            case .operator(_, .none) where formatter.token(at: i + 1)?.isLinebreak == false:
                if let nextToken = formatter.next(.nonSpaceOrLinebreak, after: i), !nextToken.isEndOfScope,
                    nextToken != .startOfScope("(") || formatter.options.spaceAroundOperatorDeclarations {
                    formatter.insertSpace(" ", at: i + 1)
                }
            case .operator("?", .postfix), .operator("!", .postfix):
                if let prevToken = formatter.token(at: i - 1),
                    formatter.token(at: i + 1)?.isSpaceOrLinebreak == false,
                    [.keyword("as"), .keyword("try")].contains(prevToken) {
                    formatter.insertToken(.space(" "), at: i + 1)
                }
            case let .operator(".", type):
                if formatter.token(at: i + 1)?.isSpace == true {
                    formatter.removeToken(at: i + 1)
                }
                if type == .infix {
                    if formatter.token(at: i - 1)?.isSpace == true,
                        let lastTokenIndex = formatter.index(of: .nonSpace, before: i),
                        formatter.tokens[lastTokenIndex].isLvalue {
                        if ["!", "?"].contains(formatter.tokens[lastTokenIndex].string),
                            let prevToken = formatter.last(.nonSpace, before: lastTokenIndex),
                            [.keyword("try"), .keyword("as")].contains(prevToken) {} else {
                            formatter.removeToken(at: i - 1)
                        }
                    }
                } else if formatter.token(at: i - 1)?.isSpace == true {
                    if formatter.last(.nonSpace, before: i) == nil {
                        formatter.removeToken(at: i - 1)
                    }
                } else if let prevToken = formatter.last(.nonSpace, before: i),
                    !prevToken.isStartOfScope, !prevToken.isOperator(ofType: .prefix) {
                    formatter.insertSpace(" ", at: i)
                }
            case .operator(_, .infix) where !token.isRangeOperator:
                if formatter.token(at: i + 1)?.isSpaceOrLinebreak == false {
                    formatter.insertToken(.space(" "), at: i + 1)
                }
                if formatter.token(at: i - 1)?.isSpaceOrLinebreak == false {
                    formatter.insertToken(.space(" "), at: i)
                }
            case .operator(_, .prefix):
                if let prevIndex = formatter.index(of: .nonSpace, before: i, if: {
                    [.startOfScope("["), .startOfScope("("), .startOfScope("<")].contains($0)
                }) {
                    formatter.removeTokens(inRange: prevIndex + 1 ..< i)
                } else if formatter.token(at: i - 1)?.isSpaceOrLinebreak == false {
                    formatter.insertToken(.space(" "), at: i)
                }
            case .delimiter(":"):
                // TODO: make this check more robust, and remove redundant space
                if formatter.token(at: i + 1)?.isIdentifier == true,
                    formatter.token(at: i + 2) == .delimiter(":") {
                    // It's a selector
                    break
                }
                fallthrough
            case .operator(_, .postfix), .delimiter(","), .delimiter(";"), .startOfScope(":"):
                switch formatter.token(at: i + 1) {
                case nil, .space?, .linebreak?, .endOfScope?:
                    break
                default:
                    // Ensure there is a space after the token
                    formatter.insertToken(.space(" "), at: i + 1)
                }
                if formatter.token(at: i - 1)?.isSpace == true,
                    formatter.token(at: i - 2)?.isLinebreak == false {
                    // Remove space before the token
                    formatter.removeToken(at: i - 1)
                }
            default:
                break
            }
        }
    }

    /// Add space around comments, except at the start or end of a line
    @objc public class func spaceAroundComments(_ formatter: Formatter) {
        formatter.forEach(.startOfScope("//")) { i, _ in
            if let prevToken = formatter.token(at: i - 1), !prevToken.isSpaceOrLinebreak {
                formatter.insertToken(.space(" "), at: i)
            }
        }
        formatter.forEach(.endOfScope("*/")) { i, _ in
            guard let startIndex = formatter.index(of: .startOfScope("/*"), before: i),
                case let .commentBody(commentStart)? = formatter.next(.nonSpaceOrLinebreak, after: startIndex),
                case let .commentBody(commentEnd)? = formatter.last(.nonSpaceOrLinebreak, before: i),
                !commentStart.hasPrefix("@"), !commentEnd.hasSuffix("@") else {
                return
            }
            if let nextToken = formatter.token(at: i + 1) {
                if !nextToken.isSpaceOrLinebreak {
                    if nextToken != .delimiter(",") {
                        formatter.insertToken(.space(" "), at: i + 1)
                    }
                } else if formatter.next(.nonSpace, after: i + 1) == .delimiter(",") {
                    formatter.removeToken(at: i + 1)
                }
            }
            if let prevToken = formatter.token(at: startIndex - 1), !prevToken.isSpaceOrLinebreak {
                formatter.insertToken(.space(" "), at: startIndex)
            }
        }
    }

    /// Add space inside comments, taking care not to mangle headerdoc or
    /// carefully preformatted comments, such as star boxes, etc.
    @objc public class func spaceInsideComments(_ formatter: Formatter) {
        guard formatter.options.indentComments else { return }
        formatter.forEach(.startOfScope("//")) { i, _ in
            guard let nextToken = formatter.token(at: i + 1),
                case let .commentBody(string) = nextToken else { return }
            guard let first = string.first else { return }
            if "/!:".contains(first) {
                let nextIndex = string.index(after: string.startIndex)
                if nextIndex < string.endIndex, case let next = string[nextIndex], !" /t".contains(next) {
                    let string = String(string.first!) + " " + String(string.dropFirst())
                    formatter.replaceToken(at: i + 1, with: .commentBody(string))
                }
            } else if !" /t".contains(first), !string.hasPrefix("===") { // Special-case check for swift stdlib codebase
                formatter.insertToken(.space(" "), at: i + 1)
            }
        }
        formatter.forEach(.startOfScope("/*")) { i, _ in
            guard let nextToken = formatter.token(at: i + 1), case let .commentBody(string) = nextToken,
                !string.hasPrefix("---"), !string.hasPrefix("@"), !string.hasSuffix("---"), !string.hasSuffix("@") else {
                return
            }
            if let first = string.first, "*!:".contains(first) {
                let nextIndex = string.index(after: string.startIndex)
                if nextIndex < string.endIndex, case let next = string[nextIndex],
                    !" /t".contains(next), !string.hasPrefix("**"), !string.hasPrefix("*/") {
                    let string = String(string.first!) + " " + String(string.dropFirst())
                    formatter.replaceToken(at: i + 1, with: .commentBody(string))
                }
            } else {
                formatter.insertToken(.space(" "), at: i + 1)
            }
            if let i = formatter.index(of: .endOfScope("*/"), after: i), let prevToken = formatter.token(at: i - 1) {
                if !prevToken.isSpaceOrLinebreak, !prevToken.string.hasSuffix("*") {
                    formatter.insertToken(.space(" "), at: i)
                }
            }
        }
    }

    /// Adds or removes the space around range operators
    @objc public class func ranges(_ formatter: Formatter) {
        formatter.forEach(.rangeOperator) { i, token in
            guard case .operator(_, .infix) = token else { return }
            if !formatter.options.spaceAroundRangeOperators {
                if formatter.token(at: i + 1)?.isSpace == true,
                    formatter.token(at: i - 1)?.isSpace == true,
                    let nextToken = formatter.next(.nonSpace, after: i),
                    !nextToken.isCommentOrLinebreak, !nextToken.isOperator(ofType: .prefix),
                    let prevToken = formatter.last(.nonSpace, before: i),
                    !prevToken.isCommentOrLinebreak, !prevToken.isOperator(ofType: .postfix) {
                    formatter.removeToken(at: i + 1)
                    formatter.removeToken(at: i - 1)
                }
            } else {
                if formatter.token(at: i + 1)?.isSpaceOrLinebreak == false {
                    formatter.insertToken(.space(" "), at: i + 1)
                }
                if formatter.token(at: i - 1)?.isSpaceOrLinebreak == false {
                    formatter.insertToken(.space(" "), at: i)
                }
            }
        }
    }

    /// Collapse all consecutive space characters to a single space, except at
    /// the start of a line or inside a comment or string, as these have no semantic
    /// meaning and lead to noise in commits.
    @objc public class func consecutiveSpaces(_ formatter: Formatter) {
        formatter.forEach(.space) { i, token in
            if let prevToken = formatter.token(at: i - 1), !prevToken.isLinebreak {
                switch token {
                case .space(""):
                    formatter.removeToken(at: i)
                case .space(" "):
                    break
                case .space:
                    let scope = formatter.currentScope(at: i)
                    if scope != .startOfScope("/*"), scope != .startOfScope("//") {
                        formatter.replaceToken(at: i, with: .space(" "))
                    }
                default:
                    break
                }
            }
        }
    }

    /// Remove trailing space from the end of lines, as it has no semantic
    /// meaning and leads to noise in commits.
    @objc public class func trailingSpace(_ formatter: Formatter) {
        formatter.forEach(.space) { i, _ in
            guard formatter.token(at: i + 1)?.isLinebreak ?? true else {
                return
            }
            if formatter.options.truncateBlankLines || formatter.token(at: i - 1)?.isLinebreak == false {
                formatter.removeToken(at: i)
            }
        }
    }

    /// Collapse all consecutive blank lines into a single blank line
    @objc public class func consecutiveBlankLines(_ formatter: Formatter) {
        formatter.forEach(.linebreak) { i, _ in
            guard let prevIndex = formatter.index(of: .nonSpace, before: i, if: { $0.isLinebreak }) else {
                return
            }
            if formatter.next(.nonSpace, after: i)?.isLinebreak ?? !formatter.options.fragment {
                formatter.removeTokens(inRange: prevIndex ..< i)
            }
        }
    }

    /// Remove blank lines immediately after an opening brace, bracket, paren or chevron
    @objc public class func blankLinesAtStartOfScope(_ formatter: Formatter) {
        guard formatter.options.removeBlankLines else { return }
        formatter.forEach(.startOfScope) { i, token in
            guard ["{", "(", "[", "<"].contains(token.string),
                let indexOfFirstLineBreak = formatter.index(of: .nonSpaceOrComment, after: i),
                // If there is extra code on the same line, ignore it
                formatter.tokens[indexOfFirstLineBreak].isLinebreak
            else { return }
            // Find next non-space token
            var index = indexOfFirstLineBreak + 1
            var indexOfLastLineBreak = indexOfFirstLineBreak
            loop: while let token = formatter.token(at: index) {
                switch token {
                case .linebreak:
                    indexOfLastLineBreak = index
                case .space:
                    break
                default:
                    break loop
                }
                index += 1
            }
            if indexOfFirstLineBreak != indexOfLastLineBreak {
                formatter.removeTokens(inRange: indexOfFirstLineBreak ..< indexOfLastLineBreak)
                return
            }
        }
    }

    /// Remove blank lines immediately before a closing brace, bracket, paren or chevron
    /// unless it's followed by more code on the same line (e.g. } else { )
    @objc public class func blankLinesAtEndOfScope(_ formatter: Formatter) {
        guard formatter.options.removeBlankLines else { return }
        formatter.forEach(.endOfScope) { i, token in
            guard ["}", ")", "]", ">"].contains(token.string),
                // If there is extra code after the closing scope on the same line, ignore it
                (formatter.next(.nonSpaceOrComment, after: i).map { $0.isLinebreak }) ?? true
            else { return }
            // Find previous non-space token
            var index = i - 1
            var indexOfFirstLineBreak: Int?
            var indexOfLastLineBreak: Int?
            loop: while let token = formatter.token(at: index) {
                switch token {
                case .linebreak:
                    indexOfFirstLineBreak = index
                    if indexOfLastLineBreak == nil {
                        indexOfLastLineBreak = index
                    }
                case .space:
                    break
                default:
                    break loop
                }
                index -= 1
            }
            if let indexOfFirstLineBreak = indexOfFirstLineBreak,
                indexOfFirstLineBreak != indexOfLastLineBreak {
                formatter.removeTokens(inRange: indexOfFirstLineBreak ..< indexOfLastLineBreak!)
                return
            }
        }
    }

    /// Adds a blank line immediately after a closing brace, unless followed by another closing brace
    @objc public class func blankLinesBetweenScopes(_ formatter: Formatter) {
        guard formatter.options.insertBlankLines else { return }
        var spaceableScopeStack = [true]
        var isSpaceableScopeType = false
        formatter.forEachToken { i, token in
            switch token {
            case .keyword("class"),
                 .keyword("struct"),
                 .keyword("extension"),
                 .keyword("enum"):
                isSpaceableScopeType = (formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) != .keyword("import"))
            case .keyword("func"), .keyword("var"):
                isSpaceableScopeType = false
            case .startOfScope("{"):
                spaceableScopeStack.append(isSpaceableScopeType)
                isSpaceableScopeType = false
            case .endOfScope("}"):
                if spaceableScopeStack.count > 1, spaceableScopeStack[spaceableScopeStack.count - 2] {
                    guard let openingBraceIndex = formatter.index(of: .startOfScope("{"), before: i),
                        let previousLinebreakIndex = formatter.index(of: .linebreak, before: i),
                        previousLinebreakIndex > openingBraceIndex else {
                        // Inline braces
                        break
                    }
                    var i = i
                    if let nextTokenIndex = formatter.index(of: .nonSpace, after: i, if: {
                        $0 == .startOfScope("(") }), let closingParenIndex = formatter.index(of:
                        .endOfScope(")"), after: nextTokenIndex) {
                        i = closingParenIndex
                    }
                    if let nextTokenIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i) {
                        switch formatter.tokens[nextTokenIndex] {
                        case .error, .endOfScope,
                             .operator(".", _), .delimiter(","), .delimiter(":"),
                             .keyword("else"), .keyword("catch"):
                            break
                        case .keyword("while"):
                            if let previousBraceIndex = formatter.index(of: .startOfScope("{"), before: i),
                                formatter.last(.nonSpaceOrCommentOrLinebreak, before: previousBraceIndex)
                                != .keyword("repeat") {
                                fallthrough
                            }
                            break
                        default:
                            if let firstLinebreakIndex = formatter.index(of: .linebreak, after: i),
                                firstLinebreakIndex < nextTokenIndex {
                                if let secondLinebreakIndex = formatter.index(of: .linebreak, after: firstLinebreakIndex),
                                    secondLinebreakIndex < nextTokenIndex {
                                    // Already has a blank line after
                                } else {
                                    // Insert linebreak
                                    formatter.insertToken(.linebreak(formatter.options.linebreak), at: firstLinebreakIndex)
                                }
                            }
                        }
                    }
                }
                spaceableScopeStack.removeLast()
            default:
                break
            }
        }
    }

    /// Adds a blank line around MARK: comments
    @objc public class func blankLinesAroundMark(_ formatter: Formatter) {
        guard formatter.options.insertBlankLines else { return }
        formatter.forEachToken { i, token in
            guard case let .commentBody(comment) = token, comment.hasPrefix("MARK:"),
                let startIndex = formatter.index(of: .nonSpace, before: i),
                formatter.tokens[startIndex] == .startOfScope("//") else { return }
            if let nextIndex = formatter.index(of: .linebreak, after: i),
                let nextToken = formatter.next(.nonSpace, after: nextIndex),
                !nextToken.isLinebreak, nextToken != .endOfScope("}") {
                formatter.insertToken(.linebreak(formatter.options.linebreak), at: nextIndex)
            }
            if let lastIndex = formatter.index(of: .linebreak, before: startIndex),
                let lastToken = formatter.last(.nonSpace, before: lastIndex),
                !lastToken.isLinebreak, lastToken != .startOfScope("{") {
                formatter.insertToken(.linebreak(formatter.options.linebreak), at: lastIndex)
            }
        }
    }

    /// Always end file with a linebreak, to avoid incompatibility with certain unix tools:
    /// http://stackoverflow.com/questions/2287967/why-is-it-recommended-to-have-empty-line-in-the-end-of-file
    @objc public class func linebreakAtEndOfFile(_ formatter: Formatter) {
        guard !formatter.options.fragment else { return }
        var wasLinebreak = true
        formatter.forEachToken { _, token in
            switch token {
            case .linebreak:
                wasLinebreak = true
            case .space:
                break
            default:
                wasLinebreak = false
            }
        }
        if formatter.isEnabled, !wasLinebreak {
            formatter.insertToken(.linebreak(formatter.options.linebreak), at: formatter.tokens.count)
        }
    }

    /// Indent code according to standard scope indenting rules.
    /// The type (tab or space) and level (2 spaces, 4 spaces, etc.) of the
    /// indenting can be configured with the `options` parameter of the formatter.
    @objc public class func indent(_ formatter: Formatter) {
        var scopeStack: [Token] = []
        var scopeStartLineIndexes: [Int] = []
        var lastNonSpaceOrLinebreakIndex = -1
        var lastNonSpaceIndex = -1
        var indentStack = [""]
        var indentCounts = [1]
        var linewrapStack = [false]
        var lineIndex = 0

        func tokenIsEndOfStatement(_ i: Int) -> Bool {
            guard let token = formatter.token(at: i) else { return true }
            switch token {
            case .endOfScope("case"), .endOfScope("default"):
                return false
            case let .keyword(string):
                // TODO: handle in
                // TODO: handle context-specific keywords
                // associativity, convenience, dynamic, didSet, final, get, infix, indirect,
                // lazy, left, mutating, none, nonmutating, open, optional, override, postfix,
                // precedence, prefix, Protocol, required, right, set, Type, unowned, weak, willSet
                switch string {
                case "let", "func", "var", "if", "as", "import", "try", "guard", "case",
                     "for", "init", "switch", "throw", "where", "subscript", "is",
                     "while", "associatedtype", "inout":
                    return false
                case "return":
                    guard let nextToken =
                        formatter.next(.nonSpaceOrCommentOrLinebreak, after: i)
                    else { return true }
                    switch nextToken {
                    case .keyword, .endOfScope("case"), .endOfScope("default"):
                        return true
                    default:
                        return false
                    }
                default:
                    return true
                }
            case .delimiter(","):
                // For arrays or argument lists, we already indent
                return ["<", "[", "(", "case", "default"].contains(scopeStack.last?.string ?? "")
            case .delimiter(":"):
                // For arrays or argument lists, we already indent
                return ["case", "default", "("].contains(scopeStack.last?.string ?? "")
            case .operator(_, .infix), .operator(_, .prefix):
                return false
            case .operator("?", .postfix), .operator("!", .postfix):
                if let prevToken = formatter.token(at: i - 1) {
                    switch prevToken {
                    case .keyword("as"), .keyword("try"):
                        return false
                    default:
                        return true
                    }
                }
                return true
            default:
                return true
            }
        }

        func tokenIsStartOfStatement(_ i: Int) -> Bool {
            guard let token = formatter.token(at: i) else { return true }
            switch token {
            case let .keyword(string) where [ // TODO: handle "in"
                "where", "dynamicType", "rethrows", "throws",
            ].contains(string):
                return false
            case .keyword("as"), .keyword("in"):
                // For case statements, we already indent
                return scopeStack.last?.string == "case"
            case .delimiter(","):
                if let scope = scopeStack.last?.string, ["<", "[", "(", "case"].contains(scope) {
                    // For arrays, dictionaries, cases, or argument lists, we already indent
                    return true
                }
                return false
            case .delimiter(":"), .delimiter("->"), .operator(_, .infix), .operator(_, .postfix):
                return false
            default:
                return true
            }
        }

        func tokenIsStartOfClosure(_ i: Int) -> Bool {
            var i = i - 1
            var nextTokenIndex = i
            while let token = formatter.token(at: i) {
                let prevTokenIndex = formatter.index(before: i, where: {
                    !$0.isSpaceOrComment && (!$0.isEndOfScope || $0 == .endOfScope("}"))
                }) ?? -1
                switch token {
                case let .keyword(string):
                    switch string {
                    case "class", "struct", "enum", "protocol", "var", "func":
                        if formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) != .keyword("import") {
                            return false
                        }
                    case "extension", "init", "subscript",
                         "if", "switch", "guard", "else",
                         "for", "while", "repeat",
                         "do", "catch":
                        return false
                    default:
                        break
                    }
                case .startOfScope:
                    return true
                case .linebreak:
                    var prevTokenIndex = prevTokenIndex
                    if formatter.token(at: prevTokenIndex)?.isLinebreak == true {
                        prevTokenIndex = formatter.index(before: prevTokenIndex, where: {
                            !$0.isSpaceOrCommentOrLinebreak && (!$0.isEndOfScope || $0 == .endOfScope("}"))
                        }) ?? -1
                    }
                    if tokenIsEndOfStatement(prevTokenIndex), tokenIsStartOfStatement(nextTokenIndex) {
                        return true
                    }
                    break
                default:
                    break
                }
                nextTokenIndex = i
                i = prevTokenIndex
            }
            return true
        }

        func isCommentedCode(at index: Int) -> Bool {
            if !scopeStack.isEmpty, formatter.token(at: index - 1)?.isSpace != true {
                switch formatter.token(at: index + 1) {
                case nil, .linebreak?:
                    return true
                case let .space(space)? where space.hasPrefix(formatter.options.indent):
                    return true
                default:
                    break
                }
            }
            return false
        }

        if formatter.options.fragment,
            let firstIndex = formatter.index(of: .nonSpaceOrLinebreak, after: -1),
            let indentToken = formatter.token(at: firstIndex - 1), case let .space(string) = indentToken {
            indentStack[0] = string
        } else {
            formatter.insertSpace("", at: 0)
        }
        formatter.forEachToken { i, token in

            func popScope() {
                if linewrapStack.last == true {
                    indentStack.removeLast()
                }
                indentStack.removeLast()
                indentCounts.removeLast()
                linewrapStack.removeLast()
                scopeStartLineIndexes.removeLast()
                scopeStack.removeLast()
            }

            var i = i
            switch token {
            case let .startOfScope(string):
                switch string {
                case ":":
                    if scopeStack.last == .endOfScope("case") {
                        popScope()
                    }
                case "{":
                    if !tokenIsStartOfClosure(i) {
                        if linewrapStack.last == true {
                            indentStack.removeLast()
                            linewrapStack[linewrapStack.count - 1] = false
                        }
                    }
                default:
                    break
                }
                // Handle start of scope
                scopeStack.append(token)
                var indentCount: Int
                if lineIndex > scopeStartLineIndexes.last ?? -1 {
                    indentCount = 1
                } else {
                    indentCount = indentCounts.last! + 1
                }
                var indent = indentStack[indentStack.count - indentCount]
                switch string {
                case "/*":
                    // Comments only indent one space
                    indent += " "
                case "\"\"\"":
                    // Don't indent multiline string literals
                    break
                case ":":
                    indent += formatter.options.indent
                    if formatter.options.indentCase,
                        scopeStack.count < 2 || scopeStack[scopeStack.count - 2] != .startOfScope("#if") {
                        indent += formatter.options.indent
                    }
                case "#if":
                    if let lineIndex = formatter.index(of: .linebreak, after: i),
                        let nextKeyword = formatter.next(.nonSpaceOrLinebreak, after: lineIndex), [.endOfScope("case"), .endOfScope("default")].contains(nextKeyword) {
                        indent = indentStack[indentStack.count - indentCount - 1]
                        if formatter.options.indentCase {
                            indent += formatter.options.indent
                        }
                    }
                    switch formatter.options.ifdefIndent {
                    case .indent:
                        i += formatter.insertSpace(indent, at: formatter.startOfLine(at: i))
                        indent += formatter.options.indent
                    case .noIndent:
                        i += formatter.insertSpace(indent, at: formatter.startOfLine(at: i))
                    case .outdent:
                        i += formatter.insertSpace("", at: formatter.startOfLine(at: i))
                    }
                case "[", "(":
                    if let linebreakIndex = formatter.index(of: .linebreak, after: i),
                        let nextIndex = formatter.index(of: .nonSpace, after: i),
                        nextIndex != linebreakIndex {
                        if formatter.last(.nonSpaceOrComment, before: linebreakIndex) != .delimiter(","),
                            formatter.next(.nonSpaceOrComment, after: linebreakIndex) != .delimiter(",") {
                            fallthrough
                        }
                        let start = formatter.startOfLine(at: i)
                        // Align indent with previous value
                        indentCount = 1
                        indent = ""
                        for token in formatter.tokens[start ..< nextIndex] {
                            if case let .space(string) = token {
                                indent += string
                            } else {
                                indent += String(repeating: " ", count: token.string.count)
                            }
                        }
                        break
                    }
                    fallthrough
                default:
                    indent += formatter.options.indent
                }
                indentStack.append(indent)
                indentCounts.append(indentCount)
                scopeStartLineIndexes.append(lineIndex)
                linewrapStack.append(false)
            case .space:
                break
            default:
                if let scope = scopeStack.last {
                    // Handle end of scope
                    if token.isEndOfScope(scope) {
                        let indentCount = indentCounts.last! - 1
                        popScope()
                        if !token.isLinebreak, lineIndex > scopeStartLineIndexes.last ?? -1 {
                            // If indentCount > 0, drop back to previous indent level
                            if indentCount > 0 {
                                indentStack.removeLast()
                                indentStack.append(indentStack.last ?? "")
                            }
                            // Check if line on which scope ends should be unindented
                            let start = formatter.startOfLine(at: i)
                            if !isCommentedCode(at: start), formatter.options.indentComments ||
                                formatter.next(.nonSpace, after: start - 1) != .startOfScope("/*"),
                                let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: start - 1),
                                nextToken.isEndOfScope, nextToken != .endOfScope("*/") {
                                // Only reduce indent if line begins with a closing scope token
                                var indent = indentStack.last ?? ""
                                if [.endOfScope("case"), .endOfScope("default")].contains(token),
                                    formatter.options.indentCase, scopeStack.last != .startOfScope("#if") {
                                    indent += formatter.options.indent
                                }
                                i += formatter.insertSpace(indent, at: start)
                            }
                        }
                    } else if [.keyword("#else"), .keyword("#elseif")].contains(token) {
                        var indent = indentStack[indentStack.count - 2]
                        if scope == .startOfScope(":") {
                            indent = indentStack[indentStack.count - 4]
                            if formatter.options.indentCase {
                                indent += formatter.options.indent
                            }
                        }
                        switch formatter.options.ifdefIndent {
                        case .indent, .noIndent:
                            i += formatter.insertSpace(indent, at: formatter.startOfLine(at: i))
                        case .outdent:
                            i += formatter.insertSpace("", at: formatter.startOfLine(at: i))
                        }
                    } else if token == .endOfScope("#endif") {
                        var indent = indentStack[indentStack.count - 2]
                        if scope == .startOfScope(":") {
                            indent = indentStack[indentStack.count - 4]
                            if formatter.options.indentCase {
                                indent += formatter.options.indent
                            }
                            popScope()
                        }
                        switch formatter.options.ifdefIndent {
                        case .indent, .noIndent:
                            i += formatter.insertSpace(indent, at: formatter.startOfLine(at: i))
                        case .outdent:
                            i += formatter.insertSpace("", at: formatter.startOfLine(at: i))
                        }
                        if scopeStack.last == .startOfScope("#if") {
                            popScope()
                        }
                    }
                    switch token {
                    case .endOfScope("case"):
                        scopeStack.append(token)
                        var indent = (indentStack.last ?? "")
                        if formatter.next(.nonSpaceOrComment, after: i)?.isLinebreak == true {
                            indent += formatter.options.indent
                        } else {
                            // Align indent with previous case value
                            indent += "     "
                            if formatter.options.indentCase {
                                indent += formatter.options.indent
                            }
                        }
                        indentStack.append(indent)
                        indentCounts.append(1)
                        scopeStartLineIndexes.append(lineIndex)
                        linewrapStack.append(false)
                    case .endOfScope("#endif"):
                        switch formatter.options.ifdefIndent {
                        case .indent, .noIndent:
                            break
                        case .outdent:
                            i += formatter.insertSpace("", at: formatter.startOfLine(at: i))
                        }
                    default:
                        break
                    }
                } else if [.error("}"), .error("]"), .error(")"), .error(">")].contains(token) {
                    // Handled over-terminated fragment
                    if let prevToken = formatter.token(at: i - 1) {
                        if case let .space(string) = prevToken {
                            let prevButOneToken = formatter.token(at: i - 2)
                            if prevButOneToken == nil || prevButOneToken!.isLinebreak {
                                indentStack[0] = string
                            }
                        } else if prevToken.isLinebreak {
                            indentStack[0] = ""
                        }
                    }
                    return
                }
                // Indent each new line
                if token.isLinebreak {
                    // Detect linewrap
                    let nextTokenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i)
                    let linewrapped = !tokenIsEndOfStatement(lastNonSpaceOrLinebreakIndex) ||
                        !(nextTokenIndex == nil || tokenIsStartOfStatement(nextTokenIndex!))
                    // Determine current indent
                    var indent = indentStack.last ?? ""
                    if linewrapped, lineIndex == scopeStartLineIndexes.last {
                        indent = indentStack.count > 1 ? indentStack[indentStack.count - 2] : ""
                    }
                    lineIndex += 1
                    // Begin wrap scope
                    if linewrapStack.last == true {
                        if !linewrapped {
                            indentStack.removeLast()
                            linewrapStack[linewrapStack.count - 1] = false
                            indent = indentStack.last!
                        }
                    } else if linewrapped {
                        linewrapStack[linewrapStack.count - 1] = true
                        // Don't indent line starting with dot if previous line was just a closing scope
                        let lastToken = formatter.token(at: lastNonSpaceOrLinebreakIndex)
                        if formatter.token(at: nextTokenIndex ?? -1) != .operator(".", .infix) ||
                            !(lastToken?.isEndOfScope == true && lastToken != .endOfScope("case") &&
                                formatter.last(.nonSpace, before:
                                    lastNonSpaceOrLinebreakIndex)?.isLinebreak == true) {
                            indent += formatter.options.indent
                        }
                        indentStack.append(indent)
                    }
                    // Apply indent
                    if let nextTokenIndex = formatter.index(of: .nonSpace, after: i) {
                        switch formatter.tokens[nextTokenIndex] {
                        case .linebreak where formatter.options.truncateBlankLines:
                            formatter.insertSpace("", at: i + 1)
                        case .error:
                            break
                        case .endOfScope("case"), .endOfScope("default"):
                            formatter.insertSpace(indent, at: i + 1)
                            // TODO: is this the best place to do this?
                            var index = i
                            while let prevToken = formatter.token(at: index - 1), prevToken.isComment,
                                let startIndex = formatter.index(of: .nonSpaceOrComment, before: index),
                                formatter.tokens[startIndex].isLinebreak {
                                // Set indent for comment immediately before case to match the case
                                var indent = indentStack.count > 1 ? indentStack[indentStack.count - 2] : ""
                                if formatter.options.indentCase {
                                    indent += formatter.options.indent
                                }
                                formatter.insertSpace(indent, at: startIndex + 1)
                                if case .endOfScope("*/") = prevToken,
                                    var index = formatter.index(of: .startOfScope("/*"), after: startIndex) {
                                    while let linebreakIndex = formatter.index(of: .linebreak, after: index) {
                                        formatter.insertSpace(indent + " ", at: linebreakIndex + 1)
                                        index = linebreakIndex
                                    }
                                }
                                index = startIndex
                            }
                        case .startOfScope("//"):
                            // Avoid indenting commented code
                            if isCommentedCode(at: nextTokenIndex) {
                                return
                            }
                            formatter.insertSpace(indent, at: i + 1)
                        case .startOfScope("/*"), .commentBody, .endOfScope("*/"):
                            if formatter.options.indentComments { fallthrough }
                        default:
                            formatter.insertSpace(indent, at: i + 1)
                        }
                    }
                }
            }
            // Track token for line wraps
            if !token.isSpaceOrComment {
                lastNonSpaceIndex = i
                if !token.isLinebreak {
                    lastNonSpaceOrLinebreakIndex = i
                }
            }
        }
    }

    // Implement brace-wrapping rules
    @objc public class func braces(_ formatter: Formatter) {
        formatter.forEach(.startOfScope("{")) { i, token in
            // Check this isn't an inline block
            guard let nextLinebreakIndex = formatter.index(of: .linebreak, after: i),
                let closingBraceIndex = formatter.index(of: .endOfScope("}"), after: i),
                nextLinebreakIndex < closingBraceIndex else { return }
            guard let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: i),
                prevToken != .delimiter(","), !prevToken.is(.startOfScope) else { return }
            if formatter.options.allmanBraces {
                // Implement Allman-style braces, where opening brace appears on the next line
                if let prevTokenIndex = formatter.index(of: .nonSpace, before: i),
                    let prevToken = formatter.token(at: prevTokenIndex) {
                    switch prevToken {
                    case .identifier, .keyword, .endOfScope, .operator("?", .postfix), .operator("!", .postfix):
                        formatter.insertToken(.linebreak(formatter.options.linebreak), at: i)
                        if let breakIndex = formatter.index(of: .linebreak, after: i + 1),
                            let nextIndex = formatter.index(of: .nonSpace, after: breakIndex, if: { $0.isLinebreak }) {
                            formatter.removeTokens(inRange: breakIndex ..< nextIndex)
                        }
                        formatter.insertSpace(formatter.indentForLine(at: i), at: i + 1)
                        if formatter.tokens[i - 1].isSpace {
                            formatter.removeToken(at: i - 1)
                        }
                    default:
                        break
                    }
                }
            } else {
                // Implement K&R-style braces, where opening brace appears on the same line
                var index = i - 1
                var linebreakIndex: Int?
                while let token = formatter.token(at: index) {
                    switch token {
                    case .linebreak:
                        linebreakIndex = index
                    case .space, .commentBody,
                         .startOfScope("/*"), .startOfScope("//"),
                         .endOfScope("*/"):
                        break
                    default:
                        if let linebreakIndex = linebreakIndex {
                            formatter.removeTokens(inRange: Range(linebreakIndex ... i))
                            if formatter.token(at: linebreakIndex - 1)?.isSpace == true {
                                formatter.removeToken(at: linebreakIndex - 1)
                            }
                            formatter.insertToken(.space(" "), at: index + 1)
                            formatter.insertToken(.startOfScope("{"), at: index + 2)
                        }
                        return
                    }
                    index -= 1
                }
            }
        }
    }

    /// Ensure that an `else` statement following `if { ... }` appears on the same line
    /// as the closing brace. This has no effect on the `else` part of a `guard` statement.
    /// Also applies to `catch` after `try` and `while` after `repeat`.
    @objc public class func elseOnSameLine(_ formatter: Formatter) {
        var closingBraceIndex: Int?
        formatter.forEachToken { i, token in
            switch token {
            case .endOfScope("}"):
                closingBraceIndex = i
            case .keyword("while"):
                if let closingBraceIndex = closingBraceIndex,
                    let previousBraceIndex = formatter.index(of: .startOfScope("{"), before: closingBraceIndex),
                    formatter.last(.nonSpaceOrCommentOrLinebreak, before: previousBraceIndex) == .keyword("repeat") {
                    fallthrough
                }
                break
            case .keyword("else"), .keyword("catch"):
                if let closingBraceIndex = closingBraceIndex {
                    // Only applies to dangling braces
                    if formatter.last(.nonSpace, before: closingBraceIndex)?.isLinebreak == true {
                        if let prevLinebreakIndex = formatter.index(of: .linebreak, before: i),
                            closingBraceIndex < prevLinebreakIndex {
                            if !formatter.options.allmanBraces, !formatter.options.elseOnNextLine {
                                formatter.replaceTokens(inRange: closingBraceIndex + 1 ..< i, with: [.space(" ")])
                            }
                        } else if formatter.options.allmanBraces || formatter.options.elseOnNextLine {
                            formatter.replaceTokens(inRange: closingBraceIndex + 1 ..< i, with:
                                [.linebreak(formatter.options.linebreak)])
                            formatter.insertSpace(formatter.indentForLine(at: i), at: closingBraceIndex + 2)
                        }
                    }
                }
            default:
                if !token.isSpaceOrCommentOrLinebreak {
                    closingBraceIndex = nil
                }
                break
            }
        }
    }

    /// Ensure that the last item in a multi-line array literal is followed by a comma.
    /// This is useful for preventing noise in commits when items are added to end of array.
    @objc public class func trailingCommas(_ formatter: Formatter) {
        formatter.forEach(.endOfScope("]")) { i, _ in
            guard let prevTokenIndex = formatter.index(of: .nonSpaceOrComment, before: i) else { return }
            if let startIndex = formatter.index(of: .startOfScope("["), before: i),
                let prevToken = formatter.last(.nonSpaceOrComment, before: startIndex) {
                // Check for subscript
                if prevToken.isIdentifier || prevToken.isUnwrapOperator ||
                    [.endOfScope(")"), .endOfScope("]")].contains(prevToken) { return }
                // Check for type declaration
                if prevToken == .delimiter(":") {
                    if let scopeStart = formatter.index(of: .startOfScope, before: startIndex),
                        formatter.tokens[scopeStart] == .startOfScope("(") {
                        if formatter.last(.keyword, before: scopeStart) == .keyword("func") {
                            return
                        }
                    } else if let token = formatter.last(.keyword, before: startIndex),
                        [.keyword("let"), .keyword("var")].contains(token) {
                        return
                    }
                }
            }
            let prevToken = formatter.tokens[prevTokenIndex]
            if prevToken.isLinebreak {
                if let prevTokenIndex = formatter.index(of:
                    .nonSpaceOrCommentOrLinebreak, before: prevTokenIndex + 1) {
                    switch formatter.tokens[prevTokenIndex] {
                    case .startOfScope("["), .delimiter(":"):
                        break // do nothing
                    case .delimiter(","):
                        if !formatter.options.trailingCommas {
                            formatter.removeToken(at: prevTokenIndex)
                        }
                    default:
                        if formatter.options.trailingCommas {
                            formatter.insertToken(.delimiter(","), at: prevTokenIndex + 1)
                        }
                    }
                }
            } else if prevToken == .delimiter(",") {
                formatter.removeToken(at: prevTokenIndex)
            }
        }
    }

    /// Ensure that TODO, MARK and FIXME comments are followed by a : as required
    @objc public class func todos(_ formatter: Formatter) {
        formatter.forEachToken { i, token in
            guard case var .commentBody(string) = token else {
                return
            }
            var removedSpace = false
            if string.hasPrefix("/") {
                removedSpace = true
                string = string.replacingOccurrences(of: "^/(\\s+)", with: "", options: .regularExpression)
            }
            guard let tag = ["TODO", "MARK", "FIXME"].first(where: { string.hasPrefix($0) }) else {
                return
            }
            var suffix: String = String(string[tag.endIndex ..< string.endIndex])
            if let first = suffix.unicodeScalars.first, !" :".unicodeScalars.contains(first) {
                // If not followed by a space or :, don't mess with it as it may be a custom format
                return
            }
            while let first = suffix.unicodeScalars.first, " :".unicodeScalars.contains(first) {
                suffix = String(suffix.unicodeScalars.dropFirst())
            }
            formatter.replaceToken(at: i, with: .commentBody(tag + ":" + (suffix.isEmpty ? "" : " \(suffix)")))
            if removedSpace {
                formatter.insertSpace(" ", at: i)
            }
        }
    }

    /// Remove semicolons, except where doing so would change the meaning of the code
    @objc public class func semicolons(_ formatter: Formatter) {
        formatter.forEach(.delimiter(";")) { i, _ in
            if let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: i) {
                let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: i)
                if prevToken == nil || nextToken == .endOfScope("}") {
                    // Safe to remove
                    formatter.removeToken(at: i)
                } else if prevToken == .keyword("return") || formatter.currentScope(at: i) == .startOfScope("(") {
                    // Not safe to remove or replace
                } else if formatter.next(.nonSpaceOrComment, after: i)?.isLinebreak == true {
                    // Safe to remove
                    formatter.removeToken(at: i)
                } else if !formatter.options.allowInlineSemicolons {
                    // Replace with a linebreak
                    if formatter.token(at: i + 1)?.isSpace == true {
                        formatter.removeToken(at: i + 1)
                    }
                    formatter.insertSpace(formatter.indentForLine(at: i), at: i + 1)
                    formatter.replaceToken(at: i, with: .linebreak(formatter.options.linebreak))
                }
            } else {
                // Safe to remove
                formatter.removeToken(at: i)
            }
        }
    }

    /// Standardise linebreak characters as whatever is specified in the options (\n by default)
    @objc public class func linebreaks(_ formatter: Formatter) {
        formatter.forEach(.linebreak) { i, _ in
            formatter.replaceToken(at: i, with: .linebreak(formatter.options.linebreak))
        }
    }

    /// Standardise the order of property specifiers
    @objc public class func specifiers(_ formatter: Formatter) {
        let order = [
            "private", "fileprivate", "internal", "public", "open",
            "private(set)", "fileprivate(set)", "internal(set)", "public(set)",
            "final", "dynamic", // Can't be both
            "optional", "required",
            "convenience",
            "override",
            "indirect",
            "lazy",
            "weak", "unowned",
            "static", "class",
            "mutating", "nonmutating",
            "prefix", "postfix",
        ]
        let validSpecifiers = Set(order)
        formatter.forEach(.keyword) { i, token in
            switch token.string {
            case "let", "func", "var", "class", "extension", "init", "enum",
                 "struct", "typealias", "subscript", "associatedtype", "protocol":
                break
            default:
                return
            }
            var specifiers = [String: [Token]]()
            var lastSpecifier: (String, [Token])?
            var lastIndex = i
            var previousIndex = lastIndex
            loop: while let index = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: lastIndex) {
                switch formatter.tokens[index] {
                case .operator(_, .prefix), .operator(_, .infix), .keyword("case"):
                    // Last specifier was invalid
                    lastSpecifier = nil
                    lastIndex = previousIndex
                    break loop
                case let .keyword(string), let .identifier(string):
                    if !validSpecifiers.contains(string) {
                        break loop
                    }
                    lastSpecifier.map { specifiers[$0.0] = $0.1 }
                    lastSpecifier = (string, [Token](formatter.tokens[index ..< lastIndex]))
                    previousIndex = lastIndex
                    lastIndex = index
                case .endOfScope(")"):
                    if formatter.last(.nonSpaceOrCommentOrLinebreak, before: index) == .identifier("set"),
                        let openParenIndex = formatter.index(of: .startOfScope("("), before: index),
                        let index = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: openParenIndex),
                        case let .keyword(string)? = formatter.token(at: index),
                        ["private", "fileprivate", "public", "internal"].contains(string) {
                        lastSpecifier.map { specifiers[$0.0] = $0.1 }
                        lastSpecifier = (string + "(set)", [Token](formatter.tokens[index ..< lastIndex]))
                        previousIndex = lastIndex
                        lastIndex = index
                    } else {
                        break loop
                    }
                default:
                    // Not a specifier
                    break loop
                }
            }
            lastSpecifier.map { specifiers[$0.0] = $0.1 }
            guard !specifiers.isEmpty else { return }
            var sortedSpecifiers = [Token]()
            for specifier in order {
                if let tokens = specifiers[specifier] {
                    sortedSpecifiers += tokens
                }
            }
            formatter.replaceTokens(inRange: lastIndex ..< i, with: sortedSpecifiers)
        }
    }

    /// Convert closure arguments to trailing closure syntax where possible
    /// NOTE: Parens around trailing closures are sometimes required for disambiguation.
    /// SwiftFormat can't detect those cases, so `trailingClosures` is disabled by default
    @objc public class func trailingClosures(_ formatter: Formatter) {
        func removeParen(at index: Int) {
            if formatter.token(at: index - 1)?.isSpace == true {
                if formatter.token(at: index + 1)?.isSpace == true {
                    // Need to remove one
                    formatter.removeToken(at: index + 1)
                }
            } else if formatter.token(at: index + 1)?.isSpace == false {
                // Need to insert one
                formatter.insertToken(.space(" "), at: index + 1)
            }
            formatter.removeToken(at: index)
        }

        formatter.forEach(.startOfScope("(")) { i, _ in
            guard let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: i),
                case .identifier = prevToken else { // TODO: are trailing closures allowed in other cases?
                return
            }
            guard let closingIndex = formatter.index(of: .endOfScope(")"), after: i), let closingBraceIndex =
                formatter.index(of: .nonSpaceOrComment, before: closingIndex, if: { $0 == .endOfScope("}") }),
                let openingBraceIndex = formatter.index(of: .startOfScope("{"), before: closingBraceIndex),
                formatter.index(of: .endOfScope("}"), before: openingBraceIndex) == nil else {
                return
            }
            if let nextIndex = formatter.index(of: .nonSpaceOrComment, after: closingIndex) {
                switch formatter.tokens[nextIndex] {
                case .linebreak:
                    if let next = formatter.next(.nonSpaceOrComment, after: nextIndex) {
                        switch next {
                        case .operator(_, .infix),
                             .operator(_, .postfix),
                             .delimiter(","),
                             .delimiter(":"),
                             .startOfScope("{"),
                             .keyword("else"):
                            return
                        default:
                            break
                        }
                    }
                default:
                    return
                }
            }
            guard var startIndex = formatter.index(of: .nonSpaceOrLinebreak, before: openingBraceIndex) else {
                return
            }
            switch formatter.tokens[startIndex] {
            case .delimiter(","), .startOfScope("("):
                break
            case .delimiter(":"):
                if let commaIndex = formatter.index(of: .delimiter(","), before: openingBraceIndex) {
                    startIndex = commaIndex
                } else if formatter.index(of: .startOfScope("("), before: openingBraceIndex) == i {
                    startIndex = i
                } else {
                    return
                }
            default:
                return
            }
            let wasParen = (startIndex == i)
            removeParen(at: closingIndex)
            formatter.replaceTokens(inRange: startIndex ..< openingBraceIndex, with:
                wasParen ? [.space(" ")] : [.endOfScope(")"), .space(" ")])
        }
    }

    /// Remove redundant parens around the arguments for loops, if statements, closures, etc.
    @objc public class func redundantParens(_ formatter: Formatter) {
        func tokenOutsideParenRequiresSpacing(at index: Int) -> Bool {
            guard let token = formatter.token(at: index) else { return false }
            switch token {
            case .identifier, .keyword, .number:
                return true
            default:
                return false
            }
        }

        func tokenInsideParenRequiresSpacing(at index: Int) -> Bool {
            guard let token = formatter.token(at: index) else { return false }
            switch token {
            case .operator, .startOfScope("{"), .endOfScope("}"):
                return true
            default:
                return tokenOutsideParenRequiresSpacing(at: index)
            }
        }

        func removeParen(at index: Int) {
            if formatter.token(at: index - 1)?.isSpace == true,
                formatter.token(at: index + 1)?.isSpace == true {
                // Need to remove one
                formatter.removeToken(at: index + 1)
            } else if case .startOfScope = formatter.tokens[index] {
                if tokenOutsideParenRequiresSpacing(at: index - 1),
                    tokenInsideParenRequiresSpacing(at: index + 1) {
                    // Need to insert one
                    formatter.insertToken(.space(" "), at: index + 1)
                }
            } else if tokenInsideParenRequiresSpacing(at: index - 1),
                tokenOutsideParenRequiresSpacing(at: index + 1) {
                // Need to insert one
                formatter.insertToken(.space(" "), at: index + 1)
            }
            formatter.removeToken(at: index)
        }

        func nestedParens(in range: ClosedRange<Int>) -> ClosedRange<Int>? {
            guard let startIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: range.lowerBound, if: {
                $0 == .startOfScope("(")
            }), let endIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: range.upperBound, if: {
                $0 == .endOfScope(")")
            }), formatter.index(of: .endOfScope(")"), after: startIndex) == endIndex else {
                return nil
            }
            return startIndex ... endIndex
        }

        formatter.forEach(.startOfScope("(")) { i, _ in
            let previousIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i) ?? -1
            guard var closingIndex = formatter.index(of: .endOfScope(")"), after: i) else {
                return
            }
            var innerParens = nestedParens(in: i ... closingIndex)
            while let range = innerParens, nestedParens(in: range) != nil {
                // TODO: this could be a lot more efficient if we kept track of the
                // removed token indices instead of recalculating paren positions every time
                removeParen(at: range.upperBound)
                removeParen(at: range.lowerBound)
                closingIndex = formatter.index(of: .endOfScope(")"), after: i)!
                innerParens = nestedParens(in: i ... closingIndex)
            }
            if let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: closingIndex),
                [.operator("->", .infix), .keyword("throws"), .keyword("rethrows")].contains(nextToken) {
                return
            }
            let token = formatter.token(at: previousIndex) ?? .space("")
            switch token {
            case .endOfScope("]"):
                if let startIndex = formatter.index(of: .startOfScope("["), before: previousIndex),
                    formatter.last(.nonSpaceOrCommentOrLinebreak, before: startIndex) == .startOfScope("{") {
                    fallthrough
                }
            case .startOfScope("{"):
                if formatter.next(.nonSpaceOrCommentOrLinebreak, after: closingIndex) == .keyword("in"),
                    formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i) != closingIndex {
                    if let labelIndex = formatter.index(of: .delimiter(":"), after: i),
                        labelIndex < closingIndex {
                        break
                    }
                    removeParen(at: closingIndex)
                    removeParen(at: i)
                }
            case .stringBody, .operator("?", .postfix), .operator("!", .postfix):
                break
            case .identifier, .number: // TODO: are trailing closures allowed in other cases?
                // Parens before closure
                if closingIndex == formatter.index(of: .nonSpace, after: i),
                    let openingIndex = formatter.index(
                        of: .nonSpaceOrCommentOrLinebreak, after: closingIndex, if: { $0 == .startOfScope("{") }
                    ), formatter.last(.nonSpaceOrCommentOrLinebreak, before: previousIndex) != .keyword("func") {
                    if var prevIndex = formatter.index(of: .keyword, before: i) {
                        var prevKeyword = formatter.tokens[prevIndex]
                        while prevKeyword.string.hasPrefix("#") || prevKeyword.string.hasPrefix("@") ||
                            [.keyword("try"), .keyword("is"), .keyword("as")].contains(prevKeyword),
                            let index = formatter.index(of: .keyword, before: prevIndex) {
                            prevIndex = index
                            prevKeyword = formatter.tokens[prevIndex]
                        }
                        let disallowed: [Token] = [
                            .keyword("in"),
                            .keyword("while"),
                            .keyword("if"),
                            .keyword("case"),
                            .keyword("switch"),
                            .keyword("import"),
                            .keyword("where"),
                        ]
                        if disallowed.contains(prevKeyword) {
                            break
                        }
                        if [.keyword("var"), .keyword("let")].contains(prevKeyword),
                            let keyword = formatter.last(.nonSpaceOrCommentOrLinebreak, before: prevIndex),
                            disallowed.contains(keyword) || keyword == .delimiter(",") {
                            break
                        }
                        if prevKeyword == .keyword("var"),
                            let token = formatter.next(.nonSpaceOrCommentOrLinebreak, after: openingIndex),
                            [.identifier("willSet"), .identifier("didSet")].contains(token) {
                            break
                        }
                    }
                    removeParen(at: closingIndex)
                    removeParen(at: i)
                }
            case .keyword, .endOfScope:
                let string = token.string
                guard ["if", "while", "switch", "for", "in", "where", "guard", "let", "case"].contains(string),
                    formatter.index(of: .endOfScope("}"), before: closingIndex) == nil,
                    let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: closingIndex) else {
                    break
                }
                if nextToken != .startOfScope("{"),
                    nextToken != .delimiter(","),
                    nextToken != .startOfScope(":"),
                    !(string == "for" && nextToken == .keyword("in")),
                    !(string == "guard" && nextToken == .keyword("else")) {
                    // TODO: this is confusing - refactor to move fallthrough to end of case
                    fallthrough
                }
                if let commaIndex = formatter.index(of: .delimiter(","), after: i),
                    commaIndex < closingIndex {
                    // Might be a tuple, so we won't remove the parens
                    // TODO: improve the logic here so we don't misidentify function calls as tuples
                    break
                }
                removeParen(at: closingIndex)
                removeParen(at: i)
            case .operator(_, .infix):
                if let nextIndex = formatter.index(of: .nonSpaceOrComment, after: i, if: { $0 == .startOfScope("{") }),
                    let lastIndex = formatter.index(of: .endOfScope("}"), after: nextIndex),
                    formatter.index(of: .nonSpaceOrComment, before: closingIndex) == lastIndex {
                    removeParen(at: closingIndex)
                    removeParen(at: i)
                }
                fallthrough
            default:
                if let range = innerParens {
                    removeParen(at: range.upperBound)
                    removeParen(at: range.lowerBound)
                    closingIndex = formatter.index(of: .endOfScope(")"), after: i)!
                    innerParens = nil
                }
                if let nextTokenIndex = formatter.index(of: .nonSpace, after: i),
                    closingIndex == formatter.index(of: .nonSpace, after: nextTokenIndex) {
                    switch formatter.tokens[nextTokenIndex] {
                    case .identifier, .number:
                        removeParen(at: closingIndex)
                        removeParen(at: i)
                    default:
                        break
                    }
                }
            }
        }
    }

    /// Remove redundant `get {}` clause inside read-only computed property
    @objc public class func redundantGet(_ formatter: Formatter) {
        formatter.forEach(.identifier("get")) { i, _ in
            if let previousIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i, if: {
                $0 == .startOfScope("{") }), let prevKeyword = formatter.last(.keyword, before: previousIndex),
                [.keyword("var"), .keyword("subscript")].contains(prevKeyword), let openIndex = formatter.index(of:
                    .nonSpaceOrCommentOrLinebreak, after: i, if: { $0 == .startOfScope("{") }),
                let closeIndex = formatter.index(of: .endOfScope("}"), after: openIndex),
                let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: closeIndex, if: {
                    $0 == .endOfScope("}") }) {
                formatter.removeTokens(inRange: closeIndex ..< nextIndex)
                formatter.removeTokens(inRange: previousIndex + 1 ... openIndex)
                // TODO: fix-up indenting of lines in between removed braces
            }
        }
    }

    /// Remove redundant `= nil` initialization for Optional properties
    @objc public class func redundantNilInit(_ formatter: Formatter) {
        func search(from index: Int) {
            if let optionalIndex = formatter.index(of: .unwrapOperator, after: index) {
                if let terminatorIndex = formatter.index(of: .endOfStatement, after: index),
                    terminatorIndex < optionalIndex {
                    return
                }
                if !formatter.tokens[optionalIndex - 1].isSpaceOrCommentOrLinebreak,
                    let equalsIndex = formatter.index(of: .nonSpaceOrLinebreak, after: optionalIndex, if: {
                        $0 == .operator("=", .infix)
                    }), let nilIndex = formatter.index(of: .nonSpaceOrLinebreak, after: equalsIndex, if: {
                        $0 == .identifier("nil")
                    }) {
                    formatter.removeTokens(inRange: optionalIndex + 1 ... nilIndex)
                }
                search(from: optionalIndex)
            }
        }

        // Check specifiers don't include `lazy`
        // TODO: reduce duplication between this and the `specifiers` rule
        let specifiers = Set([
            "private", "fileprivate", "internal", "public", "open",
            "final", "dynamic", // Can't be both
            "optional", "required",
            "override",
            "lazy",
            "weak", "unowned",
            "static", "class",
            "mutating", "nonmutating",
        ])
        formatter.forEach(.keyword("var")) { i, _ in
            var index = i - 1
            loop: while let token = formatter.token(at: index) {
                switch token {
                case .keyword("lazy"):
                    return // Can't remove the init
                case let .keyword(string), let .identifier(string):
                    if !specifiers.contains(string) {
                        break loop
                    }
                case .endOfScope(")"):
                    if formatter.last(.nonSpaceOrCommentOrLinebreak, before: index) == .identifier("set") {
                        // Skip tokens for entire private(set) expression
                        while let token = formatter.token(at: index) {
                            if case let .keyword(string) = token,
                                ["private", "fileprivate", "public", "internal"].contains(string) {
                                break
                            }
                            index -= 1
                        }
                    }
                case .linebreak,
                     .space,
                     .commentBody,
                     .startOfScope("//"),
                     .startOfScope("/*"),
                     .endOfScope("*/"):
                    break
                default:
                    // Not a specifier
                    break loop
                }
                index -= 1
            }

            // Check this isn't a Codable
            if let scopeIndex = formatter.index(of: .startOfScope("{"), before: i) {
                var prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: scopeIndex)
                loop: while let index = prevIndex {
                    switch formatter.tokens[index] {
                    case .identifier("Codable"), .identifier("Decodable"):
                        return // Can't safely remove the default value
                    case .delimiter(":"), .keyword:
                        break loop
                    default:
                        break
                    }
                    prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: index)
                }
            }

            // Find the nil
            search(from: i)
        }
    }

    /// Remove redundant let/var for unnamed variables
    @objc public class func redundantLet(_ formatter: Formatter) {
        formatter.forEach(.identifier("_")) { i, _ in
            guard formatter.next(.nonSpaceOrCommentOrLinebreak, after: i) != .delimiter(":"),
                let prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i, if: {
                    [.keyword("let"), .keyword("var")].contains($0) }),
                let nextNonSpaceIndex = formatter.index(of: .nonSpaceOrLinebreak, after: prevIndex) else {
                return
            }
            if let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: prevIndex) {
                switch prevToken {
                case .keyword("if"), .keyword("guard"), .keyword("while"):
                    return
                case .delimiter(","):
                    if formatter.currentScope(at: i) != .startOfScope("(") {
                        return
                    }
                default:
                    break
                }
            }
            formatter.removeTokens(inRange: prevIndex ..< nextNonSpaceIndex)
        }
    }

    /// Remove redundant pattern in case statements
    @objc public class func redundantPattern(_ formatter: Formatter) {
        func redundantBindings(inRange range: Range<Int>) -> Bool {
            var isEmpty = true
            for token in formatter.tokens[range.lowerBound ..< range.upperBound] {
                switch token {
                case .identifier("_"):
                    isEmpty = false
                case .space, .linebreak, .delimiter(","), .keyword("let"), .keyword("var"):
                    break
                default:
                    return false
                }
            }
            return !isEmpty
        }

        formatter.forEach(.startOfScope("(")) { i, _ in
            let prevIndex = formatter.index(of: .nonSpaceOrComment, before: i)
            if let prevIndex = prevIndex, let prevToken = formatter.token(at: prevIndex),
                [.keyword("case"), .endOfScope("case")].contains(prevToken) {
                // Not safe to remove
                return
            }
            guard let endIndex = formatter.index(of: .endOfScope(")"), after: i),
                let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: endIndex),
                [.startOfScope(":"), .operator("=", .infix)].contains(nextToken),
                redundantBindings(inRange: i + 1 ..< endIndex) else {
                return
            }
            formatter.removeTokens(inRange: i ... endIndex)
            if let prevIndex = prevIndex, formatter.tokens[prevIndex].isIdentifier,
                formatter.last(.nonSpaceOrComment, before: prevIndex)?.string == "." {
                // Was an enum case
                return
            }
            // Was an assignment
            formatter.insertToken(.identifier("_"), at: i)
            if !(formatter.token(at: i - 1).map({ $0.isSpaceOrLinebreak }) ?? true) {
                formatter.insertToken(.space(" "), at: i)
            }
        }
    }

    /// Remove redundant raw string values for case statements
    @objc public class func redundantRawValues(_ formatter: Formatter) {
        formatter.forEach(.keyword("enum")) { i, _ in
            guard let nameIndex = formatter.index(
                of: .nonSpaceOrCommentOrLinebreak, after: i, if: { $0.isIdentifier }
            ), let colonIndex = formatter.index(
                of: .nonSpaceOrCommentOrLinebreak, after: nameIndex, if: { $0 == .delimiter(":") }
            ), formatter.next(.nonSpaceOrCommentOrLinebreak, after: colonIndex) == .identifier("String"),
                let braceIndex = formatter.index(of: .startOfScope("{"), after: colonIndex) else {
                return
            }
            var lastIndex = formatter.index(of: .keyword("case"), after: braceIndex)
            while var index = lastIndex {
                guard let nameIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index, if: {
                    $0.isIdentifier
                }) else { break }
                if let equalsIndex = formatter.index(of: .nonSpaceOrLinebreak, after: nameIndex, if: {
                    $0 == .operator("=", .infix)
                }), let quoteIndex = formatter.index(of: .nonSpaceOrLinebreak, after: equalsIndex, if: {
                    $0 == .startOfScope("\"")
                }), formatter.token(at: quoteIndex + 2) == .endOfScope("\"") {
                    if formatter.tokens[nameIndex].string == formatter.token(at: quoteIndex + 1)?.string {
                        formatter.removeTokens(inRange: nameIndex + 1 ... quoteIndex + 2)
                        index = nameIndex
                    } else {
                        index = quoteIndex + 2
                    }
                } else {
                    index = nameIndex
                }
                lastIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index, if: {
                    $0 == .delimiter(",")
                }) ?? formatter.index(of: .keyword("case"), after: index)
            }
        }
    }

    /// Remove redundant void return values for function declarations
    @objc public class func redundantVoidReturnType(_ formatter: Formatter) {
        formatter.forEach(.operator("->", .infix)) { i, _ in
            guard var endIndex = formatter.index(of: .nonSpace, after: i) else { return }
            switch formatter.tokens[endIndex] {
            case .identifier("Void"):
                break
            case .startOfScope("("):
                guard let nextIndex = formatter.index(of: .nonSpace, after: endIndex) else { return }
                switch formatter.tokens[nextIndex] {
                case .endOfScope(")"):
                    endIndex = nextIndex
                case .identifier("Void"):
                    guard let nextIndex = formatter.index(of: .nonSpace, after: nextIndex),
                        case .endOfScope(")") = formatter.tokens[nextIndex] else { return }
                    endIndex = nextIndex
                default:
                    return
                }
            default:
                return
            }
            guard formatter.next(.nonSpaceOrCommentOrLinebreak, after: endIndex) == .startOfScope("{") else {
                return
            }
            guard let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: i),
                [.endOfScope(")"), .keyword("throws"), .keyword("rethrows")].contains(prevToken) else { return }
            guard let prevIndex = formatter.index(of: .endOfScope(")"), before: i),
                let startIndex = formatter.index(of: .startOfScope("("), before: prevIndex),
                let startToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: startIndex),
                (startToken.isIdentifier || [.startOfScope("{"), .endOfScope("]")].contains(startToken)) else {
                return
            }
            formatter.removeTokens(inRange: i ..< formatter.index(of: .nonSpace, after: endIndex)!)
        }
    }

    /// Remove redundant return keyword from single-line closures
    @objc public class func redundantReturn(_ formatter: Formatter) {
        formatter.forEach(.startOfScope("{")) { i, _ in
            guard formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) != .identifier("get") else { return }
            if formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) != .operator("=", .infix),
                var prevKeywordIndex = formatter.index(of: .keyword, before: i) {
                var keyword = formatter.tokens[prevKeywordIndex].string
                while ["try", "as", "is"].contains(keyword) || keyword.hasPrefix("#") || keyword.hasPrefix("@") {
                    prevKeywordIndex = formatter.index(of: .keyword, before: prevKeywordIndex) ?? -1
                    guard prevKeywordIndex > -1 else {
                        return
                    }
                    keyword = formatter.tokens[prevKeywordIndex].string
                }
                if [
                    "let", "var", "func", "throws", "rethrows", "init", "subscript", "else", "if",
                    "case", "where", "for", "in", "while", "repeat", "do", "catch",
                ].contains(keyword) { return }
            }
            var startIndex = i
            if let inIndex = formatter.index(of: .keyword, after: i, if: { $0 == .keyword("in") }) {
                startIndex = inIndex
            }
            guard let firstIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: startIndex) else {
                return
            }
            guard formatter.tokens[firstIndex] == .keyword("return"),
                formatter.next(.nonSpaceOrCommentOrLinebreak, after: firstIndex) != .endOfScope("}") else {
                return
            }
            formatter.removeToken(at: firstIndex)
            if formatter.token(at: firstIndex)?.isSpace == true {
                formatter.removeToken(at: firstIndex)
            }
        }
    }

    /// Remove redundant backticks around non-keywords, or in places where keywords don't need escaping
    @objc public class func redundantBackticks(_ formatter: Formatter) {
        formatter.forEach(.identifier) { i, token in
            guard token.string.first == "`" else { return }
            let unescaped = token.unescaped()
            if !unescaped.isSwiftKeyword {
                switch unescaped {
                case "Any", "super", "self", "nil", "true", "false":
                    if formatter.last(.nonSpaceOrCommentOrLinebreak, before: i)?.isOperator(".") == true {
                        return
                    }
                case "Self" where formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) != .delimiter(":"):
                    // TODO: check for other cases where it's safe to use unescaped
                    break
                case "Type":
                    if formatter.currentScope(at: i) == .startOfScope("{") {
                        // TODO: check it's actually inside a type declaration, otherwise backticks aren't needed
                        return
                    }
                    if formatter.last(.nonSpaceOrCommentOrLinebreak, before: i)?.isOperator(".") == true {
                        return
                    }
                    formatter.replaceToken(at: i, with: .identifier(unescaped))
                    return
                case "get", "set", "willSet", "didSet":
                    guard formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) != .startOfScope("{") else {
                        // TODO: check it's actually inside a var or subscript
                        return
                    }
                    formatter.replaceToken(at: i, with: .identifier(unescaped))
                    return
                default:
                    formatter.replaceToken(at: i, with: .identifier(unescaped))
                    return
                }
            }
            if formatter.last(.nonSpaceOrCommentOrLinebreak, before: i)?.isOperator(".") == true {
                formatter.replaceToken(at: i, with: .identifier(unescaped))
                return
            }
            guard !["let", "var"].contains(unescaped),
                let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i) else {
                return
            }
            let nextToken = formatter.tokens[nextIndex]
            if formatter.currentScope(at: i) == .startOfScope("("),
                nextToken == .delimiter(":") || (nextToken.isIdentifier &&
                    formatter.next(.nonSpaceOrCommentOrLinebreak, after: nextIndex) == .delimiter(":")) {
                formatter.replaceToken(at: i, with: .identifier(unescaped))
            }
        }
    }

    /// Remove redundant self keyword
    // TODO: restructure this to use forEachToken to avoid exposing processCommentBody mechanism
    @objc public class func redundantSelf(_ formatter: Formatter) {
        var typeStack = [String]()
        var membersByType = [String: Set<String>]()
        var classMembersByType = [String: Set<String>]()
        func processDeclaredVariables(at index: inout Int, names: inout Set<String>) {
            while let token = formatter.token(at: index) {
                switch token {
                case .identifier where
                    formatter.last(.nonSpaceOrCommentOrLinebreak, before: index)?.isOperator(".") == false:
                    let name = token.unescaped()
                    if name != "_" {
                        names.insert(name)
                    }
                    inner: while let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index) {
                        switch formatter.tokens[nextIndex] {
                        case .keyword("as"), .keyword("is"), .keyword("try"):
                            break
                        case .startOfScope("<"), .startOfScope("["), .startOfScope("("):
                            guard let endIndex = formatter.endOfScope(at: nextIndex) else {
                                return // error
                            }
                            index = endIndex
                            continue
                        case .keyword, .startOfScope("{"), .endOfScope("}"), .startOfScope(":"):
                            return
                        case .delimiter(","):
                            index = nextIndex
                            break inner
                        default:
                            break
                        }
                        index = nextIndex
                    }
                default:
                    break
                }
                index += 1
            }
        }
        let explicitSelf = formatter.options.explicitSelf
        func processBody(at index: inout Int,
                         localNames: Set<String>,
                         members: Set<String>,
                         isTypeRoot: Bool,
                         isInit: Bool) {
            let currentScope = formatter.currentScope(at: index)
            let isWhereClause = index > 0 && formatter.tokens[index - 1] == .keyword("where")
            assert(isWhereClause || currentScope.map { token -> Bool in
                [.startOfScope("{"), .startOfScope(":")].contains(token)
            } ?? true)
            if explicitSelf == .remove {
                // Check if scope actually includes self before we waste a bunch of time
                var scopeCount = 0
                loop: for i in index ..< formatter.tokens.count {
                    switch formatter.tokens[i] {
                    case .identifier("self"):
                        break loop // Contains self
                    case .startOfScope("{"), .startOfScope(":"):
                        scopeCount += 1
                    case .endOfScope("}"), .endOfScope("case"), .endOfScope("default"):
                        if scopeCount == 0 {
                            index = i + 1
                            return // Does not contain self
                        }
                        scopeCount -= 1
                    default:
                        break
                    }
                }
            }
            // Gather members & local variables
            let type = (isTypeRoot && typeStack.count == 1) ? typeStack.first : nil
            var members = type.flatMap { membersByType[$0] } ?? members
            var classMembers = type.flatMap { classMembersByType[$0] } ?? Set<String>()
            var localNames = localNames
            if !isTypeRoot || explicitSelf != .remove {
                var i = index
                var classOrStatic = false
                outer: while let token = formatter.token(at: i) {
                    switch token {
                    case .keyword("import"):
                        guard let nextIndex = formatter.index(of: .identifier, after: i) else {
                            return // error
                        }
                        i = nextIndex
                    case .keyword("class"), .keyword("static"):
                        classOrStatic = true
                    case .keyword("repeat"):
                        guard let nextIndex = formatter.index(of: .keyword("while"), after: i) else {
                            return // error
                        }
                        i = nextIndex
                    case .keyword("if"), .keyword("while"):
                        guard let nextIndex = formatter.index(of: .startOfScope("{"), after: i) else {
                            return // error
                        }
                        i = nextIndex
                        continue
                    case .keyword("switch"):
                        guard let nextIndex = formatter.index(of: .startOfScope("{"), after: i),
                            var endIndex = formatter.index(of: .endOfScope, after: nextIndex) else {
                            return // error
                        }
                        while formatter.tokens[endIndex] != .endOfScope("}") {
                            guard let nextIndex = formatter.index(of: .startOfScope(":"), after: endIndex),
                                let _endIndex = formatter.index(of: .endOfScope, after: nextIndex) else {
                                return // error
                            }
                            endIndex = _endIndex
                        }
                        i = endIndex
                    case .keyword("var"), .keyword("let"):
                        i += 1
                        if isTypeRoot {
                            if classOrStatic {
                                processDeclaredVariables(at: &i, names: &classMembers)
                                classOrStatic = false
                            } else {
                                processDeclaredVariables(at: &i, names: &members)
                            }
                        } else {
                            processDeclaredVariables(at: &i, names: &localNames)
                        }
                    case .keyword("func"):
                        if let nameToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: i) {
                            if isTypeRoot {
                                if classOrStatic {
                                    classMembers.insert(nameToken.unescaped())
                                    classOrStatic = false
                                } else {
                                    members.insert(nameToken.unescaped())
                                }
                            } else {
                                localNames.insert(nameToken.unescaped())
                            }
                        }
                    case .startOfScope("("), .startOfScope("#if"), .startOfScope(":"):
                        break
                    case .startOfScope:
                        classOrStatic = false
                        i = formatter.endOfScope(at: i) ?? (formatter.tokens.count - 1)
                    case .endOfScope("}"), .endOfScope("case"), .endOfScope("default"):
                        break outer
                    default:
                        break
                    }
                    i += 1
                }
            }
            if let type = type {
                membersByType[type] = members
                classMembersByType[type] = classMembers
            }
            // Remove or add `self`
            var scopeStack = [Token]()
            var lastKeyword = ""
            var classOrStatic = false
            while let token = formatter.token(at: index) {
                switch token {
                case .keyword("is"), .keyword("as"), .keyword("try"):
                    break
                case .keyword("init"), .keyword("subscript"),
                     .keyword("func") where lastKeyword != "import":
                    lastKeyword = ""
                    if classOrStatic {
                        if !isTypeRoot {
                            return // error unless formatter.options.fragment = true
                        }
                        processFunction(at: &index, localNames: localNames, members: classMembers)
                        classOrStatic = false
                    } else {
                        processFunction(at: &index, localNames: localNames, members: members)
                    }
                    assert(formatter.token(at: index) != .endOfScope("}"))
                    continue
                case .keyword("static"):
                    classOrStatic = true
                case .keyword("class"):
                    if formatter.next(.nonSpaceOrCommentOrLinebreak, after: index)?.isIdentifier == true {
                        fallthrough
                    }
                    if formatter.last(.nonSpaceOrCommentOrLinebreak, before: index) != .delimiter(":") {
                        classOrStatic = true
                    }
                case .keyword("extension"), .keyword("struct"), .keyword("enum"):
                    guard formatter.last(.nonSpaceOrCommentOrLinebreak, before: index) != .keyword("import"),
                        let scopeStart = formatter.index(of: .startOfScope("{"), after: index) else { return }
                    guard let nameToken = formatter.next(.identifier, after: index),
                        case let .identifier(name) = nameToken else {
                        return // error
                    }
                    index = scopeStart + 1
                    typeStack.append(name)
                    processBody(at: &index, localNames: ["init"], members: [], isTypeRoot: true, isInit: false)
                    typeStack.removeLast()
                case .keyword("var"), .keyword("let"):
                    index += 1
                    switch lastKeyword {
                    case "lazy":
                        loop: while let nextIndex =
                            formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index) {
                            switch formatter.tokens[nextIndex] {
                            case .keyword("as"), .keyword("is"), .keyword("try"):
                                break
                            case .keyword, .startOfScope("{"):
                                break loop
                            default:
                                break
                            }
                            index = nextIndex
                        }
                        lastKeyword = ""
                    case "if", "while", "guard":
                        assert(!isTypeRoot)
                        // Guard is included because it's an error to reference guard vars in body
                        var scopedNames = localNames
                        processDeclaredVariables(at: &index, names: &scopedNames)
                        guard let startIndex = formatter.index(of: .startOfScope("{"), after: index) else {
                            return // error
                        }
                        index = startIndex + 1
                        processBody(at: &index, localNames: scopedNames, members: members, isTypeRoot: false, isInit: isInit)
                        lastKeyword = ""
                    default:
                        lastKeyword = token.string
                    }
                    classOrStatic = false
                case .keyword("where") where lastKeyword == "in":
                    lastKeyword = ""
                    var localNames = localNames
                    guard let keywordIndex = formatter.index(of: .keyword, before: index),
                        let prevKeywordIndex = formatter.index(of: .keyword, before: keywordIndex),
                        let prevKeywordToken = formatter.token(at: prevKeywordIndex),
                        case .keyword("for") = prevKeywordToken else { return }
                    for token in formatter.tokens[prevKeywordIndex + 1 ..< keywordIndex] {
                        if case let .identifier(name) = token, name != "_" {
                            localNames.insert(token.unescaped())
                        }
                    }
                    index += 1
                    processBody(at: &index, localNames: localNames, members: members, isTypeRoot: false, isInit: isInit)
                    continue
                case .keyword("while") where lastKeyword == "repeat":
                    lastKeyword = ""
                case let .keyword(name):
                    lastKeyword = name
                case .startOfScope("//"), .startOfScope("/*"):
                    if case let .commentBody(comment)? = formatter.next(.nonSpace, after: index) {
                        formatter.processCommentBody(comment)
                        if token == .startOfScope("//") {
                            formatter.processLinebreak()
                        }
                    }
                    index = formatter.endOfScope(at: index) ?? (formatter.tokens.count - 1)
                case .startOfScope("("):
                    // Special case to support autoclosure arguments in the Nimble framework
                    if formatter.last(.nonSpaceOrCommentOrLinebreak, before: index) == .identifier("expect") {
                        index = formatter.index(of: .endOfScope(")"), after: index) ?? index
                        break
                    }
                    fallthrough
                case .startOfScope("\""), .startOfScope("#if"):
                    scopeStack.append(token)
                case .startOfScope(":"):
                    lastKeyword = ""
                    break
                case .startOfScope("{") where lastKeyword == "catch":
                    lastKeyword = ""
                    var localNames = localNames
                    localNames.insert("error") // Implicit error argument
                    index += 1
                    processBody(at: &index, localNames: localNames, members: members, isTypeRoot: false, isInit: isInit)
                    continue
                case .startOfScope("{") where lastKeyword == "in":
                    lastKeyword = ""
                    var localNames = localNames
                    guard let keywordIndex = formatter.index(of: .keyword, before: index),
                        let prevKeywordIndex = formatter.index(of: .keyword, before: keywordIndex),
                        let prevKeywordToken = formatter.token(at: prevKeywordIndex),
                        case .keyword("for") = prevKeywordToken else { return }
                    for token in formatter.tokens[prevKeywordIndex + 1 ..< keywordIndex] {
                        if case let .identifier(name) = token, name != "_" {
                            localNames.insert(token.unescaped())
                        }
                    }
                    index += 1
                    if classOrStatic {
                        assert(isTypeRoot)
                        processBody(at: &index, localNames: localNames, members: classMembers, isTypeRoot: false, isInit: false)
                        classOrStatic = false
                    } else {
                        processBody(at: &index, localNames: localNames, members: members, isTypeRoot: false, isInit: isInit)
                    }
                    continue
                case .startOfScope("{") where isWhereClause:
                    return
                case .startOfScope("{") where lastKeyword == "switch":
                    lastKeyword = ""
                    guard let i = formatter.index(of: .endOfScope, after: index) else {
                        return
                    }
                    index = i
                    loop: while let token = formatter.token(at: index) {
                        index += 1
                        switch token {
                        case .endOfScope("case"), .endOfScope("default"):
                            let localNames = localNames
                            processBody(at: &index, localNames: localNames, members: members, isTypeRoot: false, isInit: isInit)
                            index -= 1
                        case .endOfScope("}"):
                            break loop
                        default:
                            break
                        }
                    }
                case .startOfScope("{") where ["for", "where", "if", "else", "while", "do"].contains(lastKeyword):
                    lastKeyword = ""
                    fallthrough
                case .startOfScope("{") where lastKeyword == "repeat":
                    index += 1
                    processBody(at: &index, localNames: localNames, members: members, isTypeRoot: false, isInit: isInit)
                    continue
                case .startOfScope("{") where lastKeyword == "var":
                    lastKeyword = ""
                    if let token = formatter.last(.nonSpaceOrLinebreak, before: index),
                        token.is(.startOfScope) || token == .operator("=", .infix) {
                        // It's a closure
                        fallthrough
                    }
                    var prevIndex = index - 1
                    var name: String?
                    while let token = formatter.token(at: prevIndex), token != .keyword("var") {
                        if token.isLvalue, let nextToken = formatter.nextToken(after: prevIndex, where: {
                            !$0.isSpaceOrCommentOrLinebreak && !$0.isStartOfScope
                        }), nextToken.isRvalue, !nextToken.isOperator(".") {
                            // It's a closure
                            fallthrough
                        }
                        if case let .identifier(_name) = token {
                            // Is the declared variable
                            name = _name
                        }
                        prevIndex -= 1
                    }
                    if let name = name {
                        processAccessors(["get", "set", "willSet", "didSet"], for: name,
                                         at: &index, localNames: localNames, members: members)
                    }
                    continue
                case .startOfScope:
                    index = formatter.endOfScope(at: index) ?? (formatter.tokens.count - 1)
                case .identifier("self") where !isTypeRoot:
                    if formatter.isEnabled, explicitSelf == .remove || (explicitSelf == .initOnly && !isInit),
                        formatter.last(.nonSpaceOrCommentOrLinebreak, before: index)?.isOperator(".") == false,
                        let dotIndex = formatter.index(of: .nonSpaceOrLinebreak, after: index, if: {
                            $0 == .operator(".", .infix)
                        }), let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: dotIndex, if: {
                            $0.isIdentifier && !localNames.contains($0.unescaped())
                        }) {
                        if case let .identifier(name) = formatter.tokens[nextIndex], name.isContextualKeyword {
                            // May be unnecessary, but will be reverted by `redundantBackticks` rule if so
                            formatter.replaceToken(at: nextIndex, with: .identifier("`\(name)`"))
                        }
                        formatter.removeTokens(inRange: index ..< nextIndex)
                    }
                case .identifier("type"): // Special case for type(of:)
                    guard let parenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index, if: {
                        $0 == .startOfScope("(")
                    }), formatter.next(.nonSpaceOrCommentOrLinebreak, after: parenIndex) == .identifier("of") else {
                        fallthrough
                    }
                case .identifier:
                    guard formatter.isEnabled, !isTypeRoot, (explicitSelf == .insert ||
                        (explicitSelf == .initOnly && isInit &&
                            formatter.next(.nonSpaceOrCommentOrLinebreak, after: index) == .operator("=", .infix))) else {
                        break
                    }
                    let name = token.unescaped()
                    if members.contains(name), !localNames.contains(name), !["for", "var", "let"].contains(lastKeyword) {
                        if let lastToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: index),
                            lastToken.isOperator(".") {
                            break
                        }
                        if let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: index),
                            nextToken.isIdentifierOrKeyword || nextToken == .delimiter(":") {
                            break
                        }
                        formatter.insertTokens([.identifier("self"), .operator(".", .infix)], at: index)
                        index += 2
                    }
                case .endOfScope("case"), .endOfScope("default"):
                    return
                case .endOfScope:
                    if let scope = scopeStack.last {
                        assert(token.isEndOfScope(scope))
                        scopeStack.removeLast()
                    } else {
                        assert(token.isEndOfScope(formatter.currentScope(at: index)!))
                        index += 1
                        return
                    }
                case .linebreak:
                    formatter.processLinebreak()
                default:
                    break
                }
                index += 1
            }
        }
        func processAccessors(
            _ names: [String], for name: String, at index: inout Int,
            localNames: Set<String>, members: Set<String>
        ) {
            var foundAccessors = false
            var localNames = localNames
            while let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index, if: {
                if case let .identifier(name) = $0, names.contains(name) { return true } else { return false }
            }), let startIndex = formatter.index(of: .startOfScope("{"), after: nextIndex) {
                foundAccessors = true
                index = startIndex + 1
                if let parenStart = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: nextIndex, if: {
                    $0 == .startOfScope("(")
                }), let varToken = formatter.next(.identifier, after: parenStart) {
                    localNames.insert(varToken.unescaped())
                } else {
                    switch formatter.tokens[nextIndex].string {
                    case "get":
                        localNames.insert(name)
                    case "set":
                        localNames.insert(name)
                        localNames.insert("newValue")
                    case "willSet":
                        localNames.insert("newValue")
                    case "didSet":
                        localNames.insert("oldValue")
                    default:
                        break
                    }
                }
                processBody(at: &index, localNames: localNames, members: members, isTypeRoot: false, isInit: false)
            }
            if foundAccessors {
                guard let endIndex = formatter.index(of: .endOfScope("}"), after: index) else { return }
                index = endIndex + 1
            } else {
                index += 1
                localNames.insert(name)
                processBody(at: &index, localNames: localNames, members: members, isTypeRoot: false, isInit: false)
            }
        }
        func processFunction(at index: inout Int, localNames: Set<String>, members: Set<String>) {
            let startToken = formatter.tokens[index]
            var localNames = localNames
            guard let startIndex = formatter.index(of: .startOfScope("("), after: index),
                let endIndex = formatter.index(of: .endOfScope(")"), after: startIndex) else { return }
            // Get argument names
            index = startIndex
            while index < endIndex {
                guard let externalNameIndex = formatter.index(of: .identifier, after: index),
                    let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: externalNameIndex)
                else { break }
                let token = formatter.tokens[nextIndex]
                switch token {
                case let .identifier(name) where name != "_":
                    localNames.insert(token.unescaped())
                case .delimiter(":"):
                    let externalNameToken = formatter.tokens[externalNameIndex]
                    if case let .identifier(name) = externalNameToken, name != "_" {
                        localNames.insert(externalNameToken.unescaped())
                    }
                default:
                    break
                }
                index = formatter.index(of: .delimiter(","), after: index) ?? endIndex
            }
            guard let bodyStartIndex = formatter.index(after: endIndex, where: {
                switch $0 {
                case .startOfScope("{"): // What we're looking for
                    return true
                case .keyword("throws"),
                     .keyword("rethrows"),
                     .keyword("where"),
                     .keyword("is"):
                    return false // Keep looking
                case .keyword:
                    return true // Not valid between end of arguments and start of body
                default:
                    return false // Keep looking
                }
            }), formatter.tokens[bodyStartIndex] == .startOfScope("{") else {
                return
            }
            if startToken == .keyword("subscript") {
                index = bodyStartIndex
                processAccessors(["get", "set"], for: "", at: &index, localNames: localNames, members: members)
            } else {
                index = bodyStartIndex + 1
                processBody(at: &index,
                            localNames: localNames,
                            members: members,
                            isTypeRoot: false,
                            isInit: startToken == .keyword("init"))
            }
        }
        var index = 0
        processBody(at: &index, localNames: ["init"], members: [], isTypeRoot: false, isInit: false)
    }

    /// Replace unused arguments with an underscore
    @objc public class func unusedArguments(_ formatter: Formatter) {
        func removeUsed<T>(from argNames: inout [String], with associatedData: inout [T], in range: Range<Int>) {
            for i in range.lowerBound ..< range.upperBound {
                let token = formatter.tokens[i]
                if case .identifier = token, let index = argNames.index(of: token.unescaped()),
                    formatter.last(.nonSpaceOrCommentOrLinebreak, before: i)?.isOperator(".") == false,
                    (formatter.next(.nonSpaceOrCommentOrLinebreak, after: i) != .delimiter(":") ||
                        formatter.currentScope(at: i) == .startOfScope("[")) {
                    argNames.remove(at: index)
                    associatedData.remove(at: index)
                    if argNames.isEmpty {
                        break
                    }
                }
            }
        }
        // Closure arguments
        formatter.forEach(.keyword("in")) { i, _ in
            var argNames = [String]()
            var nameIndexPairs = [(Int, Int)]()
            if let start = formatter.index(of: .startOfScope("{"), before: i) {
                var index = i - 1
                var argCountStack = [0]
                while index > start {
                    let token = formatter.tokens[index]
                    switch token {
                    case let .keyword(name) where !token.isAttribute && !name.hasPrefix("#") && name != "inout":
                        return
                    case .endOfScope("}"), .startOfScope("{"):
                        return
                    case .endOfScope(")"):
                        argCountStack.append(argNames.count)
                    case .startOfScope("("):
                        argCountStack.removeLast()
                    case .delimiter(","):
                        argCountStack[argCountStack.count - 1] = argNames.count
                    case .operator("->", .infix):
                        // Everything after this was part of return value
                        let count = argCountStack.last ?? 0
                        argNames.removeSubrange(count ..< argNames.count)
                        nameIndexPairs.removeSubrange(count ..< nameIndexPairs.count)
                    case .identifier:
                        if argCountStack.count < 3,
                            let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: index), [
                                .delimiter(","), .startOfScope("("), .startOfScope("{"), .endOfScope("]"),
                            ].contains(prevToken), let scopeStart = formatter.index(of: .startOfScope, before: index),
                            ![.startOfScope("["), .startOfScope("<")].contains(formatter.tokens[scopeStart]) {
                            let name = token.unescaped()
                            if let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index),
                                let nextToken = formatter.token(at: nextIndex), case .identifier = nextToken {
                                let internalName = nextToken.unescaped()
                                if internalName != "_" {
                                    argNames.append(internalName)
                                    nameIndexPairs.append((index, nextIndex))
                                }
                            } else if name != "_" {
                                argNames.append(name)
                                nameIndexPairs.append((index, index))
                            }
                        }
                    default:
                        break
                    }
                    index -= 1
                }
            }
            guard !argNames.isEmpty, let bodyEndIndex = formatter.index(of: .endOfScope("}"), after: i) else {
                return
            }
            removeUsed(from: &argNames, with: &nameIndexPairs, in: i + 1 ..< bodyEndIndex)
            for pair in nameIndexPairs {
                if case .identifier("_") = formatter.tokens[pair.0], pair.0 != pair.1 {
                    formatter.removeToken(at: pair.1)
                    if formatter.tokens[pair.1 - 1] == .space(" ") {
                        formatter.removeToken(at: pair.1 - 1)
                    }
                } else {
                    formatter.replaceToken(at: pair.1, with: .identifier("_"))
                }
            }
        }
        // Function arguments
        guard formatter.options.stripUnusedArguments != .closureOnly else {
            return
        }
        formatter.forEachToken { i, token in
            guard case let .keyword(keyword) = token, ["func", "init", "subscript"].contains(keyword),
                let startIndex = formatter.index(of: .startOfScope("("), after: i),
                let endIndex = formatter.index(of: .endOfScope(")"), after: startIndex) else { return }
            let isOperator = (keyword == "subscript") ||
                (keyword == "func" && formatter.next(.nonSpaceOrCommentOrLinebreak, after: i)?.isOperator == true)
            var index = startIndex
            var argNames = [String]()
            var nameIndexPairs = [(Int, Int)]()
            while index < endIndex {
                guard let externalNameIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index, if: {
                    if case let .identifier(name) = $0 {
                        return formatter.options.stripUnusedArguments != .unnamedOnly || name == "_"
                    }
                    // Probably an empty argument list
                    return false
                }) else { return }
                guard let nextIndex =
                    formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: externalNameIndex) else { return }
                let nextToken = formatter.tokens[nextIndex]
                switch nextToken {
                case let .identifier(name) where name != "_":
                    argNames.append(nextToken.unescaped())
                    nameIndexPairs.append((externalNameIndex, nextIndex))
                case .delimiter(":"):
                    let externalNameToken = formatter.tokens[externalNameIndex]
                    if case let .identifier(name) = externalNameToken, name != "_" {
                        argNames.append(externalNameToken.unescaped())
                        nameIndexPairs.append((externalNameIndex, externalNameIndex))
                    }
                default:
                    return
                }
                index = formatter.index(of: .delimiter(","), after: index) ?? endIndex
            }
            guard !argNames.isEmpty, let bodyStartIndex = formatter.index(after: endIndex, where: {
                switch $0 {
                case .startOfScope("{"): // What we're looking for
                    return true
                case .keyword("throws"),
                     .keyword("rethrows"),
                     .keyword("where"),
                     .keyword("is"):
                    return false // Keep looking
                case .keyword:
                    return true // Not valid between end of arguments and start of body
                default:
                    return false // Keep looking
                }
            }), formatter.tokens[bodyStartIndex] == .startOfScope("{"),
                let bodyEndIndex = formatter.index(of: .endOfScope("}"), after: bodyStartIndex) else {
                return
            }
            removeUsed(from: &argNames, with: &nameIndexPairs, in: bodyStartIndex + 1 ..< bodyEndIndex)
            for pair in nameIndexPairs.reversed() {
                if pair.0 == pair.1 {
                    if isOperator {
                        formatter.replaceToken(at: pair.0, with: .identifier("_"))
                    } else {
                        formatter.insertToken(.identifier("_"), at: pair.0 + 1)
                        formatter.insertToken(.space(" "), at: pair.0 + 1)
                    }
                } else if case .identifier("_") = formatter.tokens[pair.0] {
                    formatter.removeToken(at: pair.1)
                    if formatter.tokens[pair.1 - 1] == .space(" ") {
                        formatter.removeToken(at: pair.1 - 1)
                    }
                } else {
                    formatter.replaceToken(at: pair.1, with: .identifier("_"))
                }
            }
        }
    }

    /// Move `let` and `var` inside patterns to the beginning
    @objc public class func hoistPatternLet(_ formatter: Formatter) {
        func indicesOf(_ keyword: String, in range: CountableRange<Int>) -> [Int]? {
            var indices = [Int]()
            var keywordFound = false, identifierFound = false
            for index in range {
                switch formatter.tokens[index] {
                case .keyword(keyword):
                    indices.append(index)
                    keywordFound = true
                case .identifier("_"):
                    break
                case .identifier where formatter.last(.nonSpaceOrComment, before: index) != .operator(".", .prefix):
                    identifierFound = true
                case .delimiter(","):
                    guard keywordFound || !identifierFound else { return nil }
                    keywordFound = false
                    identifierFound = false
                case .startOfScope("{"):
                    return nil
                default:
                    break
                }
            }
            return !identifierFound || !keywordFound || indices.isEmpty ? nil : indices
        }

        formatter.forEach(.startOfScope("(")) { i, _ in
            let hoist = formatter.options.hoistPatternLet
            // Check if pattern already starts with let/var
            var openParenIndex = i
            var startIndex = i
            var keyword = "let"
            if var prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i) {
                if case .identifier = formatter.tokens[prevIndex] {
                    prevIndex = formatter.index(before: prevIndex) {
                        $0.isSpaceOrCommentOrLinebreak || $0.isStartOfScope
                    } ?? -1
                    startIndex = prevIndex + 1
                    prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: startIndex) ?? 0
                }
                let prevToken = formatter.tokens[prevIndex]
                if [.keyword("let"), .keyword("var")].contains(prevToken) {
                    if hoist {
                        // No changes needed
                        return
                    }
                    var prevKeywordIndex = prevIndex
                    loop: while let index = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: prevKeywordIndex) {
                        switch formatter.tokens[index] {
                        case .keyword("case"), .endOfScope("case"):
                            break loop
                        case .keyword("let"), .keyword("var"),
                             .keyword("as"), .keyword("is"), .keyword("try"):
                            break
                        case .keyword, .startOfScope("{"), .endOfScope("}"):
                            // Tuple assignment, not a pattern
                            return
                        default:
                            break
                        }
                        prevKeywordIndex = index
                    }
                    guard let prevPrevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: prevIndex),
                        [.keyword("case"), .endOfScope("case"), .delimiter(",")].contains(prevPrevToken) else {
                        // Tuple assignment, not a pattern
                        return
                    }
                    keyword = prevToken.string
                    formatter.removeTokens(inRange: prevIndex ..< startIndex)
                    openParenIndex -= (startIndex - prevIndex)
                    startIndex = prevIndex
                } else if hoist == false {
                    // No changes needed
                    return
                }
            }
            guard let endIndex = formatter.index(of: .endOfScope(")"), after: openParenIndex) else { return }
            if hoist {
                // Find let/var keyword indices
                guard let indices: [Int] = ({
                    guard let indices = indicesOf(keyword, in: openParenIndex + 1 ..< endIndex) else {
                        keyword = "var"
                        return indicesOf(keyword, in: openParenIndex + 1 ..< endIndex)
                    }
                    return indices
                }()) else { return }
                // Remove keywords inside parens
                for index in indices.reversed() {
                    if formatter.tokens[index + 1].isSpace {
                        formatter.removeToken(at: index + 1)
                    }
                    formatter.removeToken(at: index)
                }
                // Insert keyword before parens
                formatter.insertToken(.keyword(keyword), at: startIndex)
                formatter.insertToken(.space(" "), at: startIndex + 1)
                if let prevToken = formatter.token(at: startIndex - 1),
                    !prevToken.isSpaceOrCommentOrLinebreak, !prevToken.isStartOfScope {
                    formatter.insertToken(.space(" "), at: startIndex)
                }
            } else {
                // Find variable indices
                var indices = [Int]()
                var index = openParenIndex + 1
                var wasParenOrComma = true
                while index < endIndex {
                    let token = formatter.tokens[index]
                    switch token {
                    case .delimiter(","), .startOfScope("("):
                        wasParenOrComma = true
                    case let .identifier(name) where wasParenOrComma:
                        wasParenOrComma = false
                        if name != "_", formatter.next(.nonSpaceOrComment, after: index) != .operator(".", .infix) {
                            indices.append(index)
                        }
                    case _ where token.isSpaceOrCommentOrLinebreak:
                        break
                    default:
                        wasParenOrComma = false
                    }
                    index += 1
                }
                // Insert keyword at indices
                for index in indices.reversed() {
                    formatter.insertTokens([.keyword(keyword), .space(" ")], at: index)
                }
            }
        }
    }

    /// Normalize argument wrapping style
    @objc public class func wrapArguments(_ formatter: Formatter) {
        func removeLinebreakBeforeClosingBrace(at closingBraceIndex: inout Int) {
            if var lastIndex = formatter.index(of: .nonSpace, before: closingBraceIndex, if: {
                $0.isLinebreak
            }) {
                if let prevIndex = formatter.index(of: .nonSpaceOrLinebreak, before: closingBraceIndex),
                    case .commentBody = formatter.tokens[prevIndex],
                    let startIndex = formatter.index(of: .startOfScope("//"), before: prevIndex) {
                    lastIndex = formatter.index(of: .space, before: startIndex) ?? startIndex
                    formatter.insertToken(formatter.tokens[closingBraceIndex], at: lastIndex)
                    formatter.removeToken(at: closingBraceIndex + 1)
                    closingBraceIndex = lastIndex
                } else {
                    formatter.removeTokens(inRange: lastIndex ..< closingBraceIndex)
                    closingBraceIndex = lastIndex
                }
                // Remove trailing comma
                if let prevCommaIndex = formatter.index(of:
                    .nonSpaceOrCommentOrLinebreak, before: closingBraceIndex, if: {
                        $0 == .delimiter(",")
                }) {
                    formatter.removeToken(at: prevCommaIndex)
                    closingBraceIndex -= 1
                }
            }
        }
        func wrapArgumentsBeforeFirst(startOfScope i: Int,
                                      closingBraceIndex: Int,
                                      allowGrouping: Bool,
                                      closingBraceOnSameLine: Bool) {
            // Get indent
            let start = formatter.startOfLine(at: i)
            let indent: String
            if let indentToken = formatter.token(at: start), case let .space(string) = indentToken {
                indent = string
            } else {
                indent = ""
            }
            var closingBraceIndex = closingBraceIndex
            if closingBraceOnSameLine {
                removeLinebreakBeforeClosingBrace(at: &closingBraceIndex)
            } else {
                // Insert linebreak before closing paren
                if let lastIndex = formatter.index(of: .nonSpace, before: closingBraceIndex, if: {
                    !$0.isLinebreak
                }) {
                    formatter.insertSpace(indent, at: lastIndex + 1)
                    formatter.insertToken(.linebreak(formatter.options.linebreak), at: lastIndex + 1)
                    closingBraceIndex += 1
                }
            }
            // Insert linebreak after each comma
            var index = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: closingBraceIndex)!
            if formatter.tokens[index] != .delimiter(",") {
                index += 1
            }
            while index > i {
                guard let commaIndex = formatter.index(of: .delimiter(","), before: index) else {
                    break
                }
                let linebreakIndex = formatter.index(of: .nonSpaceOrComment, after: commaIndex)!
                if formatter.tokens[linebreakIndex].isLinebreak, !formatter.options.truncateBlankLines ||
                    formatter.next(.nonSpace, after: linebreakIndex).map({ !$0.isLinebreak }) ?? false {
                    formatter.insertSpace(indent + formatter.options.indent, at: linebreakIndex + 1)
                } else if !allowGrouping {
                    formatter.insertToken(.linebreak(formatter.options.linebreak), at: linebreakIndex)
                    formatter.insertSpace(indent + formatter.options.indent, at: linebreakIndex + 1)
                }
                index = commaIndex
            }
            // Insert linebreak after opening paren
            if formatter.next(.nonSpaceOrComment, after: i)?.isLinebreak == false {
                formatter.insertSpace(indent + formatter.options.indent, at: i + 1)
                formatter.insertToken(.linebreak(formatter.options.linebreak), at: i + 1)
            }
        }
        func wrapArgumentsAfterFirst(startOfScope i: Int, closingBraceIndex: Int, allowGrouping: Bool) {
            guard var firstArgumentIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i) else {
                return
            }
            // Remove linebreak after opening paren
            formatter.removeTokens(inRange: i + 1 ..< firstArgumentIndex)
            var closingBraceIndex = closingBraceIndex - (firstArgumentIndex - (i + 1))
            firstArgumentIndex = i + 1
            // Get indent
            let start = formatter.startOfLine(at: i)
            var indent = ""
            for token in formatter.tokens[start ..< firstArgumentIndex] {
                if case let .space(string) = token {
                    indent += string
                } else {
                    indent += String(repeating: " ", count: token.string.count)
                }
            }
            removeLinebreakBeforeClosingBrace(at: &closingBraceIndex)
            // Insert linebreak after each comma
            guard var index = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: closingBraceIndex) else {
                return
            }
            if formatter.tokens[index] != .delimiter(",") {
                index += 1
            }
            while index > i {
                guard let commaIndex = formatter.index(of: .delimiter(","), before: index) else {
                    break
                }
                let linebreakIndex = formatter.index(of: .nonSpaceOrComment, after: commaIndex)!
                if formatter.tokens[linebreakIndex].isLinebreak {
                    formatter.insertSpace(indent, at: linebreakIndex + 1)
                } else if !allowGrouping {
                    formatter.insertToken(.linebreak(formatter.options.linebreak), at: linebreakIndex)
                    formatter.insertSpace(indent, at: linebreakIndex + 1)
                }
                index = commaIndex
            }
        }
        formatter.forEach(.startOfScope) { i, token in
            let mode: WrapMode
            var closingBraceOnSameLine = false
            switch token.string {
            case "(":
                closingBraceOnSameLine = formatter.options.closingParenOnSameLine
                fallthrough
            case "<":
                mode = formatter.options.wrapArguments
            case "[":
                mode = formatter.options.wrapCollections
            default:
                return
            }
            guard mode != .disabled, let closingBraceIndex = formatter.endOfScope(at: i),
                let firstLinebreakIndex = (i ..< closingBraceIndex).first(where: { formatter.tokens[$0].isLinebreak }) else {
                return
            }
            let firstIdentifierIndex = formatter.index(of:
                .nonSpaceOrCommentOrLinebreak, after: i) ?? firstLinebreakIndex
            switch mode {
            case .beforeFirst,
                 .preserve where firstIdentifierIndex > firstLinebreakIndex:
                wrapArgumentsBeforeFirst(startOfScope: i,
                                         closingBraceIndex: closingBraceIndex,
                                         allowGrouping: true,
                                         closingBraceOnSameLine: closingBraceOnSameLine)
            case .afterFirst,
                 .preserve:
                wrapArgumentsAfterFirst(startOfScope: i,
                                        closingBraceIndex: closingBraceIndex,
                                        allowGrouping: true)
            case .disabled:
                assertionFailure() // Shouldn't happen
            }
        }
    }

    /// Normalize the use of void in closure arguments and return values
    @objc public class func void(_ formatter: Formatter) {
        func isArgumentToken(at index: Int) -> Bool {
            if let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: index) {
                if [.operator("->", .infix), .keyword("throws"), .keyword("rethrows")].contains(nextToken) {
                    return true
                }
                if nextToken == .keyword("in") {
                    var index = index
                    if formatter.tokens[index].isEndOfScope {
                        index = formatter.index(of: .startOfScope, before: index) ?? index
                    }
                    return formatter.last(.nonSpaceOrCommentOrLinebreak, before: index) == .startOfScope("{")
                }
            }
            return false
        }

        formatter.forEach(.identifier("Void")) { i, _ in
            if let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i, if: {
                $0 == .endOfScope(")")
            }), var prevIndex = formatter.index(of: .nonSpaceOrLinebreak, before: i), {
                let token = formatter.tokens[prevIndex]
                if token == .delimiter(":"),
                    let prevPrevIndex = formatter.index(of: .nonSpaceOrLinebreak, before: prevIndex),
                    formatter.tokens[prevPrevIndex] == .identifier("_"),
                    let startIndex = formatter.index(of: .nonSpaceOrLinebreak, before: prevPrevIndex),
                    formatter.tokens[startIndex] == .startOfScope("(") {
                    prevIndex = startIndex
                    return true
                }
                return token == .startOfScope("(")
            }() {
                if isArgumentToken(at: nextIndex) {
                    if !formatter.options.useVoid {
                        // Convert to parens
                        formatter.replaceToken(at: i, with: .endOfScope(")"))
                        formatter.insertToken(.startOfScope("("), at: i)
                    }
                } else if formatter.options.useVoid {
                    // Strip parens
                    formatter.removeTokens(inRange: i + 1 ... nextIndex)
                    formatter.removeTokens(inRange: prevIndex ..< i)
                } else {
                    // Remove Void
                    formatter.removeTokens(inRange: prevIndex + 1 ..< nextIndex)
                }
            } else if !formatter.options.useVoid || isArgumentToken(at: i) {
                if let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: i),
                    [.operator(".", .prefix), .operator(".", .infix), .keyword("typealias")].contains(prevToken) {
                    return
                }
                if formatter.next(.nonSpaceOrCommentOrLinebreak, after: i) == .startOfScope("(") { return }
                // Convert to parens
                formatter.replaceToken(at: i, with: .endOfScope(")"))
                formatter.insertToken(.startOfScope("("), at: i)
            }
        }
        if formatter.options.useVoid {
            formatter.forEach(.startOfScope("(")) { i, _ in
                if formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) == .operator("->", .infix),
                    let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i, if: {
                        $0 == .endOfScope(")") }), !isArgumentToken(at: nextIndex) {
                    // Replace with Void
                    formatter.replaceTokens(inRange: i ... nextIndex, with: [.identifier("Void")])
                }
            }
        }
    }

    /// Standardize formatting of numeric literals
    @objc public class func numberFormatting(_ formatter: Formatter) {
        func applyGrouping(_ grouping: Grouping, to number: inout String) {
            switch grouping {
            case .none, .group:
                number = number.replacingOccurrences(of: "_", with: "")
            case .ignore:
                return
            }
            guard case let .group(group, threshold) = grouping, group > 0, number.count >= threshold else {
                return
            }
            var output = Substring()
            var index = number.endIndex
            var count = 0
            repeat {
                index = number.index(before: index)
                if count > 0, count % group == 0 {
                    output.insert("_", at: output.startIndex)
                }
                count += 1
                output.insert(number[index], at: output.startIndex)
            } while index != number.startIndex
            number = String(output)
        }
        formatter.forEachToken { i, token in
            guard case let .number(number, type) = token else {
                return
            }
            let grouping: Grouping
            let prefix: String, exponentSeparator: String, parts: [String]
            switch type {
            case .integer, .decimal:
                grouping = formatter.options.decimalGrouping
                prefix = ""
                exponentSeparator = formatter.options.uppercaseExponent ? "E" : "e"
                parts = number.components(separatedBy: CharacterSet(charactersIn: ".eE"))
            case .binary:
                grouping = formatter.options.binaryGrouping
                prefix = "0b"
                exponentSeparator = ""
                parts = [String(number[prefix.endIndex...])]
            case .octal:
                grouping = formatter.options.octalGrouping
                prefix = "0o"
                exponentSeparator = ""
                parts = [String(number[prefix.endIndex...])]
            case .hex:
                grouping = formatter.options.hexGrouping
                prefix = "0x"
                exponentSeparator = formatter.options.uppercaseExponent ? "P" : "p"
                parts = number[prefix.endIndex...].components(separatedBy: CharacterSet(charactersIn: ".pP")).map {
                    formatter.options.uppercaseHex ? $0.uppercased() : $0.lowercased()
                }
            }
            var main = parts[0], fraction = "", exponent = ""
            switch parts.count {
            case 2 where number.contains("."):
                fraction = parts[1]
            case 2:
                exponent = parts[1]
            case 3:
                fraction = parts[1]
                exponent = parts[2]
            default:
                break
            }
            applyGrouping(grouping, to: &main)
            if formatter.options.fractionGrouping {
                applyGrouping(grouping, to: &fraction)
            }
            if formatter.options.exponentGrouping {
                applyGrouping(grouping, to: &exponent)
            }
            var result = prefix + main
            if !fraction.isEmpty {
                result += "." + fraction
            }
            if !exponent.isEmpty {
                result += exponentSeparator + exponent
            }
            formatter.replaceToken(at: i, with: .number(result, type))
        }
    }

    /// Strip header comments from the file
    @objc public class func fileHeader(_ formatter: Formatter) {
        guard !formatter.options.fragment else { return }
        let header: String
        switch formatter.options.fileHeader {
        case .ignore:
            return
        case var .replace(string):
            if let range = string.range(of: "{year}") {
                string.replaceSubrange(range, with: currentYear)
            }
            header = string
        }
        if let startIndex = formatter.index(of: .nonSpaceOrLinebreak, after: -1) {
            switch formatter.tokens[startIndex] {
            case .startOfScope("//"):
                if case let .commentBody(body)? = formatter.next(.nonSpace, after: startIndex) {
                    formatter.processCommentBody(body)
                    if !formatter.isEnabled || (body.hasPrefix("/") && !body.hasPrefix("//")) {
                        return
                    }
                }
                var lastIndex = startIndex
                while let index = formatter.index(of: .linebreak, after: lastIndex) {
                    if let nextToken = formatter.token(at: index + 1), nextToken != .startOfScope("//") {
                        switch nextToken {
                        case .linebreak:
                            formatter.removeTokens(inRange: 0 ... index + 1)
                        case .space where formatter.token(at: index + 2)?.isLinebreak == true:
                            formatter.removeTokens(inRange: 0 ... index + 2)
                        default:
                            break
                        }
                        break
                    }
                    lastIndex = index
                }
            case .startOfScope("/*"):
                if case let .commentBody(body)? = formatter.next(.nonSpace, after: startIndex) {
                    formatter.processCommentBody(body)
                    if !formatter.isEnabled || (body.hasPrefix("*") && !body.hasPrefix("**")) {
                        return
                    }
                }
                while let endIndex = formatter.index(of: .endOfScope("*/"), after: startIndex) {
                    formatter.removeTokens(inRange: 0 ... endIndex)
                    if let linebreakIndex = formatter.index(of: .linebreak, after: -1) {
                        formatter.removeTokens(inRange: 0 ... linebreakIndex)
                    }
                    if formatter.next(.nonSpace, after: -1) != .startOfScope("/*") {
                        if let endIndex = formatter.index(of: .nonSpaceOrLinebreak, after: -1) {
                            formatter.removeTokens(inRange: 0 ..< endIndex)
                        }
                        break
                    }
                }
            default:
                break
            }
        }
        guard !header.isEmpty else { return }
        if formatter.tokens.first?.isSpaceOrLinebreak == false {
            formatter.insertToken(.linebreak(formatter.options.linebreak), at: 0)
        }
        formatter.insertToken(.linebreak(formatter.options.linebreak), at: 0)
        let headerTokens = tokenize(header)
        formatter.insertTokens(headerTokens, at: 0)
    }

    /// Strip redundant `.init` from type instantiations
    @objc public class func redundantInit(_ formatter: Formatter) {
        formatter.forEach(.identifier("init")) { i, _ in
            guard let dotIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i, if: {
                $0 == .operator(".", .infix)
            }), let openParenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i, if: {
                $0 == .startOfScope("(")
            }), let closeParenIndex = formatter.index(of: .endOfScope(")"), after: openParenIndex),
                formatter.last(.nonSpaceOrCommentOrLinebreak, before: closeParenIndex) != .delimiter(":"),
                let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: dotIndex),
                case let .identifier(name) = prevToken, let firstChar = name.first,
                firstChar != "$", String(firstChar).uppercased() == String(firstChar) else {
                return
            }
            formatter.removeTokens(inRange: dotIndex ... i)
        }
    }

    /// Sort import statements
    @objc public class func sortedImports(_ formatter: Formatter) {
        func sortRanges(_ ranges: [ImportRange]) -> [ImportRange] {
            if case .alphabetized = formatter.options.importGrouping {
                return ranges.sorted { $0.0 < $1.0 }
            }
            // Group @testable imports at the top or bottom
            return ranges.sorted {
                let isLhsTestable = formatter.tokens[$0.1].contains(.keyword("@testable"))
                let isRhsTestable = formatter.tokens[$1.1].contains(.keyword("@testable"))
                // If both have a @testable keyword, or neither has one, just sort alphabetically
                guard isLhsTestable != isRhsTestable else {
                    return $0.0 < $1.0
                }
                return formatter.options.importGrouping == .testableTop ? isLhsTestable : isRhsTestable
            }
        }

        var importStack = parseImports(formatter)
        while let importRanges = importStack.popLast() {
            guard importRanges.count > 1 else { continue }
            let range: Range = importRanges.first!.1.lowerBound ..< importRanges.last!.1.upperBound
            let sortedRanges = sortRanges(importRanges)
            var insertedLinebreak = false
            var sortedTokens = sortedRanges.flatMap { inputRange -> [Token] in
                var tokens = Array(formatter.tokens[inputRange.1])
                if tokens.first?.isLinebreak == false {
                    insertedLinebreak = true
                    tokens.insert(Token.linebreak(formatter.options.linebreak), at: tokens.startIndex)
                }
                return tokens
            }
            if insertedLinebreak {
                sortedTokens.removeFirst()
            }
            formatter.replaceTokens(inRange: range, with: sortedTokens)
        }
    }

    /// Remove duplicate import statements
    @objc public class func duplicateImports(_ formatter: Formatter) {
        var importStack = parseImports(formatter)
        while var importRanges = importStack.popLast() {
            while let range = importRanges.popLast() {
                if importRanges.contains(where: { $0.0 == range.0 }) {
                    formatter.removeTokens(inRange: range.1)
                }
            }
        }
    }

    /// Strip unnecessary `weak` from @IBOutlet properties (except delegates and datasources)
    @objc public class func strongOutlets(_ formatter: Formatter) {
        formatter.forEach(.keyword("@IBOutlet")) { i, _ in
            guard let varIndex = formatter.index(of: .keyword("var"), after: i),
                let weakIndex = (i ..< varIndex).first(where: { formatter.tokens[$0] == .identifier("weak") }),
                case let .identifier(name)? = formatter.next(.identifier, after: varIndex) else {
                return
            }
            let lowercased = name.lowercased()
            if lowercased.hasSuffix("delegate") || lowercased.hasSuffix("datasource") {
                return
            }
            if formatter.tokens[weakIndex + 1].isSpace {
                formatter.removeToken(at: weakIndex + 1)
            } else if formatter.tokens[weakIndex - 1].isSpace {
                formatter.removeToken(at: weakIndex - 1)
            }
            formatter.removeToken(at: weakIndex)
        }
    }

    /// Remove white-space between empty braces
    @objc public class func emptyBraces(_ formatter: Formatter) {
        formatter.forEach(.startOfScope("{")) { i, _ in
            if let closingIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i, if: {
                $0 == .endOfScope("}")
            }) {
                formatter.removeTokens(inRange: i + 1 ..< closingIndex)
            }
        }
    }

    /// Replace the `&&` operator with `,` where applicable
    @objc public class func andOperator(_ formatter: Formatter) {
        formatter.forEachToken { i, token in
            guard [.keyword("if"), .keyword("guard"), .keyword("while")].contains(token),
                var endIndex = formatter.index(of: .startOfScope("{"), after: i) else {
                return
            }
            var index = i + 1
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
                    formatter.replaceToken(at: index, with: .delimiter(","))
                    if formatter.tokens[index - 1] == .space(" ") {
                        formatter.removeToken(at: index - 1)
                        endIndex -= 1
                        index -= 1
                    } else if let prevIndex = formatter.index(of: .nonSpace, before: index),
                        formatter.tokens[prevIndex].isLinebreak, let nonLinbreak =
                        formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: prevIndex) {
                        formatter.removeToken(at: index)
                        formatter.insertToken(.delimiter(","), at: nonLinbreak + 1)
                        if formatter.tokens[index + 1] == .space(" ") {
                            formatter.removeToken(at: index + 1)
                            endIndex -= 1
                        }
                    }
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

    /// Replace count == 0 with isEmpty
    @objc public class func isEmpty(_ formatter: Formatter) {
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
                case .operator("?", _):
                    if formatter.tokens[prev - 1].isSpace {
                        break loop
                    }
                    isOptional = true
                case .operator("!", _), .operator(".", _):
                    break // Ignored
                case .operator, .keyword, .delimiter:
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
                    formatter.replaceTokens(inRange: i ... endIndex, with: [
                        .identifier("isEmpty"), .space(" "), .operator("==", .infix), .space(" "), .identifier("true"),
                    ])
                } else {
                    formatter.replaceTokens(inRange: i ... endIndex, with: [.identifier("isEmpty")])
                }
            } else {
                if isOptional {
                    formatter.replaceTokens(inRange: i ... endIndex, with: [
                        .identifier("isEmpty"), .space(" "), .operator("!=", .infix), .space(" "), .identifier("true"),
                    ])
                } else {
                    formatter.replaceTokens(inRange: i ... endIndex, with: [.identifier("isEmpty")])
                    formatter.insertToken(.operator("!", .prefix), at: index)
                }
            }
        }
    }

    /// Remove redundant `let error` from `catch` statements
    @objc public class func redundantLetError(_ formatter: Formatter) {
        formatter.forEach(.keyword("catch")) { i, _ in
            if let letIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i, if: {
                $0 == .keyword("let")
            }), let errorIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: letIndex, if: {
                $0 == .identifier("error")
            }), let scopeIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: errorIndex, if: {
                $0 == .startOfScope("{")
            }) {
                formatter.removeTokens(inRange: letIndex ..< scopeIndex)
            }
        }
    }
}

// MARK: shared helper methods

private extension FormatRules {
    // Current year. Used by fileHeader rule
    private static var currentYear: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }()

    // Shared import rules implementation
    typealias ImportRange = (String, Range<Int>)
    static func parseImports(_ formatter: Formatter) -> [[ImportRange]] {
        var importStack = [[ImportRange]]()
        var importRanges = [ImportRange]()
        formatter.forEach(.keyword("import")) { i, _ in

            func pushStack() {
                importStack.append(importRanges)
                importRanges.removeAll()
            }

            // Get start of line
            var startIndex = formatter.index(of: .linebreak, before: i) ?? 0
            // Check for attributes
            var previousKeywordIndex = formatter.index(of: .keyword, before: i)
            while let previousIndex = previousKeywordIndex {
                if formatter.tokens[previousIndex].isAttribute {
                    if previousIndex < startIndex {
                        startIndex = formatter.index(of: .linebreak, before: previousIndex) ?? 0
                    }
                    previousKeywordIndex = formatter.index(of: .keyword, before: previousIndex)
                } else if previousIndex >= startIndex {
                    // Can't handle another keyword on same line as import
                    return
                } else {
                    break
                }
            }
            // Gather comments
            var prevIndex = formatter.index(of: .linebreak, before: startIndex) ?? 0
            while startIndex > 0,
                formatter.next(.nonSpace, after: prevIndex)?.isComment == true,
                formatter.next(.nonSpaceOrComment, after: prevIndex)?.isLinebreak == true {
                startIndex = prevIndex
                prevIndex = formatter.index(of: .linebreak, before: startIndex) ?? 0
            }
            // Get end of line
            let endIndex = formatter.index(of: .linebreak, after: i) ?? formatter.tokens.count
            // Get name
            if let firstPartIndex = formatter.index(of: .identifier, after: i) {
                var name = formatter.tokens[firstPartIndex].string
                var partIndex = firstPartIndex
                loop: while let nextPartIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: partIndex) {
                    switch formatter.tokens[nextPartIndex] {
                    case .operator(".", .infix):
                        name += "."
                    case let .identifier(string):
                        name += string
                    default:
                        break loop
                    }
                    partIndex = nextPartIndex
                }
                importRanges.append((name.lowercased(), startIndex ..< endIndex as Range))
            } else {
                // Error
                pushStack()
                return
            }
            if formatter.next(.spaceOrCommentOrLinebreak, after: endIndex)?.isLinebreak == true {
                // Blank line after - consider this the end of a block
                pushStack()
                return
            }
            if var nextTokenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: endIndex) {
                while formatter.tokens[nextTokenIndex].isAttribute {
                    guard let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: nextTokenIndex) else {
                        // End of imports
                        pushStack()
                        return
                    }
                    nextTokenIndex = nextIndex
                }
                if formatter.tokens[nextTokenIndex] != .keyword("import") {
                    // End of imports
                    pushStack()
                    return
                }
            }
        }
        // End of imports
        importStack.append(importRanges)
        return importStack
    }
}
