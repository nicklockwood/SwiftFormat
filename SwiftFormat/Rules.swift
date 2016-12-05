//
//  Rules.swift
//  SwiftFormat
//
//  Version 0.19
//
//  Created by Nick Lockwood on 12/08/2016.
//  Copyright 2016 Nick Lockwood
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/SwiftFormat
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

import ObjectiveC

public typealias FormatRule = (Formatter) -> Void

public class FormatRules: NSObject {

    private override init() {}

    /// A Dictionary of rules by name
    public static let byName: [String: FormatRule] = {
        var rules = [String: FormatRule]()
        var numberOfMethods: CUnsignedInt = 0
        let methods = class_copyMethodList(object_getClass(FormatRules.self), &numberOfMethods)
        for i in 0 ..< Int(numberOfMethods) {
            if let selector = method_getName(methods?[i].unsafelyUnwrapped) {
                let name = String(String(describing: selector).characters.dropLast())
                rules[name] = { FormatRules.perform(selector, with: $0) }
            }
        }
        return rules
    }()

    /// Default rules
    public static let `default` = Array(FormatRules.byName.values)
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
    public class func spaceAroundParens(_ formatter: Formatter) {

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
                if let first = keyword.characters.first {
                    return !"@#".characters.contains(first)
                }
                return true
            }
        }

        func isCaptureList(at i: Int) -> Bool {
            assert(formatter.tokens[i] == .endOfScope("]"))
            guard formatter.lastToken(before: i + 1, where: {
                return !$0.isSpaceOrCommentOrLinebreak && $0 != .endOfScope("]") }) == .startOfScope("{"),
                formatter.nextToken(after: i, where: {
                    !$0.isSpaceOrCommentOrLinebreak && $0 != .startOfScope("(") }) == .keyword("in")
            else { return false }
            return true
        }

        func isAttribute(at i: Int) -> Bool {
            assert(formatter.tokens[i] == .endOfScope(")"))
            guard let openParenIndex = formatter.index(of: .startOfScope("("), before: i),
                let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: openParenIndex),
                case .keyword(let string) = prevToken, string.hasPrefix("@") else { return false }
            return true
        }

        formatter.forEach(.startOfScope("(")) { i, token in
            guard let prevToken = formatter.token(at: i - 1) else {
                return
            }
            switch prevToken {
            case .keyword(let string) where spaceAfter(string, index: i - 1):
                fallthrough
            case .endOfScope("]") where isCaptureList(at: i - 1),
                 .endOfScope(")") where isAttribute(at: i - 1):
                formatter.insertToken(.space(" "), at: i)
            case .space:
                if let token = formatter.token(at: i - 2) {
                    switch token {
                    case .keyword(let string) where !spaceAfter(string, index: i - 2):
                        fallthrough
                    case .identifier:
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
        formatter.forEach(.endOfScope(")")) { i, token in
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
    public class func spaceInsideParens(_ formatter: Formatter) {
        formatter.forEach(.startOfScope("(")) { i, token in
            if formatter.token(at: i + 1)?.isSpace == true &&
                formatter.token(at: i + 2)?.isComment == false {
                formatter.removeToken(at: i + 1)
            }
        }
        formatter.forEach(.endOfScope(")")) { i, token in
            if formatter.token(at: i - 1)?.isSpace == true &&
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
    public class func spaceAroundBrackets(_ formatter: Formatter) {

        func spaceAfter(_ token: Token, index: Int) -> Bool {
            switch token {
            case .keyword:
                return true
            default:
                return false
            }
        }

        formatter.forEach(.startOfScope("[")) { i, token in
            guard let prevToken = formatter.token(at: i - 1) else {
                return
            }
            if spaceAfter(prevToken, index: i - 1) {
                formatter.insertToken(.space(" "), at: i)
            } else if prevToken.isSpace {
                if let token = formatter.token(at: i - 2) {
                    switch token {
                    case .identifier, .keyword:
                        if !spaceAfter(token, index: i - 2) {
                            fallthrough
                        }
                    case .endOfScope("]"), .endOfScope("}"), .endOfScope(")"):
                        formatter.removeToken(at: i - 1)
                    default:
                        break
                    }
                }
            }
        }
        formatter.forEach(.endOfScope("]")) { i, token in
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
    public class func spaceInsideBrackets(_ formatter: Formatter) {
        formatter.forEach(.startOfScope("[")) { i, token in
            if formatter.token(at: i + 1)?.isSpace == true {
                formatter.removeToken(at: i + 1)
            }
        }
        formatter.forEach(.endOfScope("]")) { i, token in
            if formatter.token(at: i - 1)?.isSpace == true &&
                formatter.token(at: i - 2)?.isLinebreak == false {
                formatter.removeToken(at: i - 1)
            }
        }
    }

    /// Ensure that there is space between an opening brace and the preceding
    /// identifier, and between a closing brace and the following identifier.
    public class func spaceAroundBraces(_ formatter: Formatter) {
        formatter.forEach(.startOfScope("{")) { i, token in
            if let prevToken = formatter.token(at: i - 1) {
                switch prevToken {
                case .space, .linebreak:
                    break
                case .startOfScope(let string) where string != "\"":
                    break
                default:
                    formatter.insertToken(.space(" "), at: i)
                }
            }
        }
        formatter.forEach(.endOfScope("}")) { i, token in
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
    public class func spaceInsideBraces(_ formatter: Formatter) {
        formatter.forEach(.startOfScope("{")) { i, token in
            if let nextToken = formatter.token(at: i + 1) {
                if nextToken.isSpace {
                    if formatter.token(at: i + 2) == .endOfScope("}") {
                        formatter.removeToken(at: i + 1)
                    }
                } else if !nextToken.isLinebreak && nextToken != .endOfScope("}") {
                    formatter.insertToken(.space(" "), at: i + 1)
                }
            }
        }
        formatter.forEach(.endOfScope("}")) { i, token in
            if let prevToken = formatter.token(at: i - 1),
                !prevToken.isSpaceOrLinebreak && prevToken != .startOfScope("{") {
                formatter.insertToken(.space(" "), at: i)
            }
        }
    }

    /// Ensure there is no space between an opening chevron and the preceding identifier
    public class func spaceAroundGenerics(_ formatter: Formatter) {
        formatter.forEach(.startOfScope("<")) { i, token in
            if formatter.token(at: i - 1)?.isSpace == true &&
                formatter.token(at: i - 2)?.isIdentifierOrKeyword == true {
                formatter.removeToken(at: i - 1)
            }
        }
    }

    /// Remove space immediately inside chevrons
    public class func spaceInsideGenerics(_ formatter: Formatter) {
        formatter.forEach(.startOfScope("<")) { i, token in
            if formatter.token(at: i + 1)?.isSpace == true {
                formatter.removeToken(at: i + 1)
            }
        }
        formatter.forEach(.endOfScope(">")) { i, token in
            if formatter.token(at: i - 1)?.isSpace == true &&
                formatter.token(at: i - 2)?.isLinebreak == false {
                formatter.removeToken(at: i - 1)
            }
        }
    }

    /// Implement the following rules with respect to the spacing around operators:
    /// * Infix operators are separated from their operands by a space on either
    ///   side. Does not affect prefix/postfix operators, as required by syntax.
    /// * Punctuation such as commas and colons is consistently followed by a
    ///   single space, unless it appears at the end of a line, and is not
    ///   preceded by a space, unless it appears at the beginning of a line.
    public class func spaceAroundOperators(_ formatter: Formatter) {

        func isLvalue(_ token: Token) -> Bool {
            switch token {
            case .identifier, .number, .endOfScope, .symbol("?"), .symbol("!"):
                return true
            default:
                return false
            }
        }

        func isRvalue(_ token: Token) -> Bool {
            switch token {
            case .identifier, .number, .startOfScope:
                return true
            default:
                return false
            }
        }

        func isUnwrapOperatorSequence(_ token: Token) -> Bool {
            if case .symbol(let string) = token {
                for c in string.characters {
                    if c != "?" && c != "!" {
                        return false
                    }
                }
            }
            return true
        }

        func spaceAfter(_ token: Token, index: Int) -> Bool {
            switch token {
            case .keyword, .endOfScope("case"):
                return true
            default:
                return false
            }
        }

        var scopeStack: [Token] = []
        formatter.forEachToken { i, token in
            switch token {
            case .symbol(":"):
                if let nextToken = formatter.token(at: i + 1) {
                    switch nextToken {
                    case .space, .linebreak, .endOfScope:
                        break
                    case .identifier where formatter.token(at: i + 2) == .symbol(":"):
                        // It's a selector
                        break
                    default:
                        // Ensure there is a space after the token
                        formatter.insertToken(.space(" "), at: i + 1)
                    }
                }
                if scopeStack.last == .symbol("?") {
                    // Treat the next : after a ? as closing the ternary scope
                    scopeStack.removeLast()
                    // Ensure there is a space before the :
                    if let prevToken = formatter.token(at: i - 1) {
                        if !prevToken.isSpaceOrLinebreak {
                            formatter.insertToken(.space(" "), at: i)
                        }
                    }
                } else if formatter.token(at: i - 1)?.isSpace == true &&
                    formatter.token(at: i - 2)?.isLinebreak == false {
                    // Remove space before the token
                    formatter.removeToken(at: i - 1)
                }
            case .symbol(","), .symbol(";"):
                if let nextToken = formatter.token(at: i + 1) {
                    switch nextToken {
                    case .space, .linebreak, .endOfScope:
                        break
                    default:
                        // Ensure there is a space after the token
                        formatter.insertToken(.space(" "), at: i + 1)
                    }
                }
                if formatter.token(at: i - 1)?.isSpace == true &&
                    formatter.token(at: i - 2)?.isLinebreak == false {
                    // Remove space before the token
                    formatter.removeToken(at: i - 1)
                }
            case .symbol("?"):
                if let prevToken = formatter.token(at: i - 1), let nextToken = formatter.token(at: i + 1) {
                    if nextToken.isSpaceOrLinebreak {
                        if prevToken.isSpaceOrLinebreak {
                            // ? is a ternary operator, treat it as the start of a scope
                            scopeStack.append(token)
                        }
                    } else if [.keyword("as"), .keyword("try")].contains(prevToken) {
                        formatter.insertToken(.space(" "), at: i + 1)
                    }
                }
            case .symbol("!"):
                if let prevToken = formatter.token(at: i - 1), let nextToken = formatter.token(at: i + 1) {
                    if !nextToken.isSpaceOrLinebreak &&
                        [.keyword("as"), .keyword("try")].contains(prevToken) {
                        formatter.insertToken(.space(" "), at: i + 1)
                    }
                }
            case .symbol("."):
                if formatter.token(at: i + 1)?.isSpace == true {
                    formatter.removeToken(at: i + 1)
                }
                if let previousNonSpaceTokenIndex = formatter.index(of: .nonSpace, before: i) {
                    let previousNonSpaceToken = formatter.tokens[previousNonSpaceTokenIndex]
                    let previousNonSpaceTokenIsSymbol: Bool = {
                        if case .symbol = previousNonSpaceToken {
                            return true
                        }
                        return false
                    }()
                    if !previousNonSpaceToken.isLinebreak && previousNonSpaceToken != .startOfScope("{") &&
                        (!previousNonSpaceTokenIsSymbol ||
                            (previousNonSpaceToken == .symbol("?") && scopeStack.last != .symbol("?")) ||
                            (previousNonSpaceToken != .symbol("?") &&
                                formatter.token(at: previousNonSpaceTokenIndex - 1)?.isSpace == false &&
                                isUnwrapOperatorSequence(previousNonSpaceToken))) &&
                        !spaceAfter(previousNonSpaceToken, index: previousNonSpaceTokenIndex) {
                        if previousNonSpaceTokenIndex < i - 1 {
                            formatter.removeToken(at: i - 1)
                        }
                    } else if previousNonSpaceTokenIndex == i - 1 {
                        formatter.insertToken(.space(" "), at: i)
                    }
                }
            case .symbol("->"):
                if (formatter.token(at: i + 1).map { !$0.isSpaceOrLinebreak }) ?? false {
                    formatter.insertToken(.space(" "), at: i + 1)
                }
                if (formatter.token(at: i - 1).map { !$0.isSpaceOrLinebreak }) ?? false {
                    formatter.insertToken(.space(" "), at: i)
                }
            case .symbol("..."), .symbol("..<"):
                break
            case .symbol:
                if formatter.token(at: i - 1).map(isLvalue) ?? false,
                    formatter.token(at: i + 1).map(isRvalue) ?? false {
                    // Insert space before and after the infix token
                    formatter.insertToken(.space(" "), at: i + 1)
                    formatter.insertToken(.space(" "), at: i)
                }
            case .startOfScope:
                scopeStack.append(token)
            case .endOfScope:
                scopeStack.removeLast()
            default: break
            }
        }
    }

    /// Add space around comments, except at the start or end of a line
    public class func spaceAroundComments(_ formatter: Formatter) {
        formatter.forEachToken { i, token in
            switch token {
            case .startOfScope("/*"), .startOfScope("//"):
                if let prevToken = formatter.token(at: i - 1), !prevToken.isSpaceOrLinebreak {
                    formatter.insertToken(.space(" "), at: i)
                }
            case .endOfScope("*/"):
                if let nextToken = formatter.token(at: i + 1), !nextToken.isSpaceOrLinebreak {
                    formatter.insertToken(.space(" "), at: i + 1)
                }
            default:
                break
            }
        }
    }

    /// Add space inside comments, taking care not to mangle headerdoc or
    /// carefully preformatted comments, such as star boxes, etc.
    public class func spaceInsideComments(_ formatter: Formatter) {
        guard formatter.options.indentComments else { return }
        formatter.forEach(.startOfScope("/*")) { i, token in
            guard let nextToken = formatter.token(at: i + 1), case .commentBody(let string) = nextToken else { return }
            if case let characters = string.characters, let first = characters.first, "*!:".characters.contains(first) {
                if characters.count > 1, case let next = characters[characters.index(after: characters.startIndex)],
                    !" /t".characters.contains(next), !string.hasPrefix("**"), !string.hasPrefix("*/") {
                    let string = String(string.characters.first!) + " " +
                        string.substring(from: string.characters.index(string.startIndex, offsetBy: 1))
                    formatter.replaceToken(at: i + 1, with: .commentBody(string))
                }
            } else {
                formatter.insertToken(.space(" "), at: i + 1)
            }
        }
        formatter.forEach(.startOfScope("//")) { i, token in
            guard let nextToken = formatter.token(at: i + 1), case .commentBody(let string) = nextToken else { return }
            if case let characters = string.characters, let first = characters.first, "/!:".characters.contains(first) {
                if characters.count > 1, case let next = characters[characters.index(after: characters.startIndex)],
                    !" /t".characters.contains(next) {
                    let string = String(string.characters.first!) + " " +
                        string.substring(from: string.characters.index(string.startIndex, offsetBy: 1))
                    formatter.replaceToken(at: i + 1, with: .commentBody(string))
                }
            } else if !string.hasPrefix("===") { // Special-case check for swift stdlib codebase
                formatter.insertToken(.space(" "), at: i + 1)
            }
        }
        formatter.forEach(.endOfScope("*/")) { i, token in
            guard let prevToken = formatter.token(at: i - 1) else { return }
            if !prevToken.isSpaceOrLinebreak && !prevToken.string.hasSuffix("*") {
                formatter.insertToken(.space(" "), at: i)
            }
        }
    }

    /// Adds or removes the space around range operators
    public class func ranges(_ formatter: Formatter) {
        formatter.forEachToken(where: { [.symbol("..."), .symbol("..<")].contains($0) }) { i, token in
            if !formatter.options.spaceAroundRangeOperators {
                if formatter.token(at: i + 1)?.isSpace == true {
                    formatter.removeToken(at: i + 1)
                }
                if formatter.token(at: i - 1)?.isSpace == true {
                    formatter.removeToken(at: i - 1)
                }
            } else if let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: i) {
                if nextToken != .endOfScope(")") && nextToken != .symbol(",") {
                    if formatter.token(at: i + 1)?.isSpaceOrLinebreak == false {
                        formatter.insertToken(.space(" "), at: i + 1)
                    }
                    if formatter.token(at: i - 1)?.isSpaceOrLinebreak == false {
                        formatter.insertToken(.space(" "), at: i)
                    }
                }
            }
        }
    }

    /// Collapse all consecutive space characters to a single space, except at
    /// the start of a line or inside a comment or string, as these have no semantic
    /// meaning and lead to noise in commits.
    public class func consecutiveSpaces(_ formatter: Formatter) {
        formatter.forEach(.space) { i, token in
            if let prevToken = formatter.token(at: i - 1), !prevToken.isLinebreak {
                switch token {
                case .space(""):
                    formatter.removeToken(at: i)
                case .space(" "):
                    break
                case .space:
                    let scope = formatter.currentScope(at: i)
                    if scope != .startOfScope("/*") && scope != .startOfScope("//") {
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
    public class func trailingSpace(_ formatter: Formatter) {
        formatter.forEach(.linebreak) { i, token in
            if formatter.token(at: i - 1)?.isSpace == true {
                formatter.removeToken(at: i - 1)
            }
        }
        if formatter.tokens.last?.isSpace == true {
            formatter.removeLastToken()
        }
    }

    /// Collapse all consecutive blank lines into a single blank line
    public class func consecutiveBlankLines(_ formatter: Formatter) {
        var linebreakCount = 0
        var lastTokenWasSpace = false
        formatter.forEachToken { i, token in
            if token.isLinebreak {
                linebreakCount += 1
                if linebreakCount > 2 {
                    formatter.removeToken(at: i)
                    if lastTokenWasSpace {
                        formatter.removeToken(at: i - 1)
                    }
                    linebreakCount -= 1
                }
            } else if !token.isSpace {
                linebreakCount = 0
            }
            lastTokenWasSpace = token.isSpace
        }
        if linebreakCount > 1 && !formatter.options.fragment {
            if lastTokenWasSpace {
                formatter.removeLastToken()
            }
            formatter.removeLastToken()
        }
    }

    /// Remove blank lines immediately before a closing brace, bracket, paren or chevron,
    /// unless it's followed by more code on the same line (e.g. } else { )
    public class func blankLinesAtEndOfScope(_ formatter: Formatter) {
        guard formatter.options.removeBlankLines else { return }
        formatter.forEachToken { i, token in
            guard [.endOfScope("}"), .endOfScope(")"), .endOfScope("]"), .endOfScope(">")].contains(token),
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
            if let indexOfFirstLineBreak = indexOfFirstLineBreak, let indexOfLastLineBreak = indexOfLastLineBreak {
                formatter.removeTokens(inRange: indexOfFirstLineBreak ..< indexOfLastLineBreak)
                return
            }
        }
    }

    /// Adds a blank line immediately after a closing brace, unless followed by another closing brace
    public class func blankLinesBetweenScopes(_ formatter: Formatter) {
        guard formatter.options.insertBlankLines else { return }
        var spaceableScopeStack = [true]
        var isSpaceableScopeType = false
        formatter.forEachToken { i, token in
            switch token {
            case .keyword("class"),
                 .keyword("struct"),
                 .keyword("extension"),
                 .keyword("enum"):
                isSpaceableScopeType = true
            case .keyword("func"), .keyword("var"):
                isSpaceableScopeType = false
            case .startOfScope("{"):
                spaceableScopeStack.append(isSpaceableScopeType)
                isSpaceableScopeType = false
            case .endOfScope("}"):
                if spaceableScopeStack.count > 1 && spaceableScopeStack[spaceableScopeStack.count - 2] {
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
                             .symbol("."), .symbol(","), .symbol(":"),
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

    /// Always end file with a linebreak, to avoid incompatibility with certain unix tools:
    /// http://stackoverflow.com/questions/2287967/why-is-it-recommended-to-have-empty-line-in-the-end-of-file
    public class func linebreakAtEndOfFile(_ formatter: Formatter) {
        guard !formatter.options.fragment else { return }
        if formatter.last(.nonSpace, before: formatter.tokens.count, if: { !$0.isLinebreak && !$0.isError }) != nil {
            formatter.insertToken(.linebreak(formatter.options.linebreak), at: formatter.tokens.count)
        }
    }

    /// Indent code according to standard scope indenting rules.
    /// The type (tab or space) and level (2 spaces, 4 spaces, etc.) of the
    /// indenting can be configured with the `options` parameter of the formatter.
    public class func indent(_ formatter: Formatter) {
        var scopeStack: [Token] = []
        var scopeStartLineIndexes: [Int] = []
        var lastNonSpaceOrLinebreakIndex = -1
        var lastNonSpaceIndex = -1
        var indentStack = [""]
        var indentCounts = [1]
        var linewrapStack = [false]
        var lineIndex = 0

        func tokenIsEndOfStatement(_ i: Int) -> Bool {
            if let token = formatter.token(at: i) {
                switch token {
                case .endOfScope("case"),
                     .endOfScope("default"):
                    return false
                case .keyword(let string):
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
                case .symbol("."), .symbol(":"):
                    return false
                case .symbol(","):
                    // For arrays or argument lists, we already indent
                    return ["<", "[", "(", "case"].contains(scopeStack.last?.string ?? "")
                case .symbol:
                    if formatter.index(of: .keyword("operator"), before: i) != nil {
                        return true
                    }
                    if let prevToken = formatter.token(at: i - 1) {
                        switch prevToken {
                        case .keyword("as"), .keyword("try"):
                            return false
                        default:
                            if prevToken.isSpaceOrCommentOrLinebreak {
                                return formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) == .symbol("=")
                            }
                        }
                    }
                default:
                    return true
                }
            }
            return true
        }

        func tokenIsStartOfStatement(_ i: Int) -> Bool {
            if let token = formatter.token(at: i) {
                switch token {
                case .keyword(let string) where [ // TODO: handle "in"
                    "as", "is", "where", "dynamicType", "rethrows", "throws",
                ].contains(string):
                    return false
                case .symbol("."):
                    // Is this an enum value?
                    if let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) {
                        if let scope = scopeStack.last?.string, ["<", "(", "[", "case"].contains(scope),
                            [scope, ",", ":"].contains(prevToken.string) {
                            return true
                        }
                        return false
                    }
                    return true
                case .symbol(","):
                    if let scope = scopeStack.last?.string, ["<", "[", "(", "case"].contains(scope) {
                        // For arrays, dictionaries, cases, or argument lists, we already indent
                        return true
                    }
                    return false
                case .symbol where formatter.token(at: i + 1)?.isSpaceOrCommentOrLinebreak == true:
                    // Is an infix operator
                    return false
                default:
                    return true
                }
            }
            return true
        }

        func tokenIsStartOfClosure(_ i: Int) -> Bool {
            var i = i - 1
            var nextTokenIndex = i
            while let token = formatter.token(at: i) {
                let prevTokenIndex = formatter.index(before: i, where: {
                    return !$0.isSpaceOrComment && (!$0.isEndOfScope || $0 == .endOfScope("}"))
                }) ?? -1
                switch token {
                case .keyword(let string):
                    switch string {
                    case "class", "struct", "enum", "protocol", "extension",
                         "var", "func", "init", "subscript",
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
                    if tokenIsEndOfStatement(prevTokenIndex) && tokenIsStartOfStatement(nextTokenIndex) {
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

        if formatter.options.fragment,
            let firstIndex = formatter.index(of: .nonSpaceOrLinebreak, after: -1),
            let indentToken = formatter.token(at: firstIndex - 1), case .space(let string) = indentToken {
            indentStack[0] = string
        } else {
            formatter.insertSpace("", at: 0)
        }
        formatter.forEachToken { i, token in
            var i = i
            switch token {
            case .startOfScope(let string):
                switch string {
                case ":":
                    if scopeStack.last == .endOfScope("case") {
                        if linewrapStack.last == true {
                            indentStack.removeLast()
                        }
                        indentStack.removeLast()
                        indentCounts.removeLast()
                        linewrapStack.removeLast()
                        scopeStartLineIndexes.removeLast()
                        scopeStack.removeLast()
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
                case "#if":
                    switch formatter.options.ifdefIndent {
                    case .indent:
                        indent += formatter.options.indent
                    case .noIndent:
                        break
                    case .outdent:
                        i += formatter.insertSpace("", at: formatter.startOfLine(at: i))
                    }
                case "[", "(":
                    if let linebreakIndex = formatter.index(of: .linebreak, after: i),
                        let nextIndex = formatter.index(of: .nonSpace, after: i),
                        nextIndex != linebreakIndex {
                        if formatter.last(.nonSpaceOrComment, before: linebreakIndex) != .symbol(",") &&
                            formatter.next(.nonSpaceOrComment, after: linebreakIndex) != .symbol(",") {
                            fallthrough
                        }
                        let start = formatter.startOfLine(at: i)
                        // align indent with previous value
                        indentCount = 1
                        indent = ""
                        for token in formatter.tokens[start ..< nextIndex] {
                            if case .space(let string) = token {
                                indent += string
                            } else {
                                indent += String(repeating: " ", count: token.string.characters.count)
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
                        if linewrapStack.last == true {
                            indentStack.removeLast()
                        }
                        linewrapStack.removeLast()
                        scopeStartLineIndexes.removeLast()
                        scopeStack.removeLast()
                        indentStack.removeLast()
                        let indentCount = indentCounts.last! - 1
                        indentCounts.removeLast()
                        if lineIndex > scopeStartLineIndexes.last ?? -1 {
                            // If indentCount > 0, drop back to previous indent level
                            if indentCount > 0 {
                                indentStack.removeLast()
                                indentStack.append(indentStack.last ?? "")
                            }
                            // Check if line on which scope ends should be unindented
                            let start = formatter.startOfLine(at: i)
                            if let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: start - 1),
                                nextToken.isEndOfScope && nextToken != .endOfScope("*/") {
                                // Only reduce indent if line begins with a closing scope token
                                let indent = indentStack.last ?? ""
                                i += formatter.insertSpace(indent, at: start)
                            }
                        }
                        switch token {
                        case .endOfScope("case"):
                            scopeStack.append(token)
                            var indent = (indentStack.last ?? "")
                            if formatter.next(.nonSpaceOrComment, after: i)?.isLinebreak == true {
                                indent += formatter.options.indent
                            } else {
                                // align indent with previous case value
                                indent += "     "
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
                    } else if [.keyword("#else"), .keyword("#elseif")].contains(token) {
                        switch formatter.options.ifdefIndent {
                        case .indent:
                            let indent = indentStack[indentStack.count - 2]
                            i += formatter.insertSpace(indent, at: formatter.startOfLine(at: i))
                        case .outdent:
                            i += formatter.insertSpace("", at: formatter.startOfLine(at: i))
                        case .noIndent:
                            break
                        }
                    }
                } else if [.error("}"), .error("]"), .error(")"), .error(">")].contains(token) {
                    // Handled over-terminated fragment
                    if let prevToken = formatter.token(at: i - 1) {
                        if case .space(let string) = prevToken {
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
                    if linewrapped && lineIndex == scopeStartLineIndexes.last {
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
                        if formatter.token(at: nextTokenIndex ?? -1) != .symbol(".") ||
                            !(lastToken?.isEndOfScope == true && lastToken != .endOfScope("case") &&
                                formatter.last(.nonSpace, before:
                                    lastNonSpaceOrLinebreakIndex)?.isLinebreak == true) {
                            indent += formatter.options.indent
                        }
                        indentStack.append(indent)
                    }
                    // Apply indent
                    if let nextToken = formatter.next(.nonSpace, after: i) {
                        switch nextToken {
                        case .linebreak:
                            formatter.insertSpace(formatter.options.truncateBlankLines ? "" : indent, at: i + 1)
                        case .commentBody:
                            if formatter.options.indentComments {
                                formatter.insertSpace(indent, at: i + 1)
                            }
                        case .startOfScope(let string):
                            if formatter.options.indentComments || string != "/*" {
                                formatter.insertSpace(indent, at: i + 1)
                            }
                        case .endOfScope(let string):
                            if formatter.options.indentComments || string != "*/" {
                                formatter.insertSpace(indent, at: i + 1)
                            }
                        case .error:
                            break
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
    public class func braces(_ formatter: Formatter) {
        formatter.forEach(.startOfScope("{")) { i, token in
            // Check this isn't an inline block
            guard let nextLinebreakIndex = formatter.index(of: .linebreak, after: i),
                let closingBraceIndex = formatter.index(of: .endOfScope("}"), after: i),
                nextLinebreakIndex < closingBraceIndex else { return }
            if formatter.options.allmanBraces {
                // Implement Allman-style braces, where opening brace appears on the next line
                if let prevTokenIndex = formatter.index(of: .nonSpace, before: i),
                    let prevToken = formatter.token(at: prevTokenIndex) {
                    switch prevToken {
                    case .identifier, .keyword, .endOfScope:
                        formatter.insertToken(.linebreak(formatter.options.linebreak), at: i)
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
    public class func elseOnSameLine(_ formatter: Formatter) {
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
                            if !formatter.options.allmanBraces {
                                formatter.replaceTokens(inRange: closingBraceIndex + 1 ..< i, with: [.space(" ")])
                            }
                        } else if formatter.options.allmanBraces {
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
    public class func trailingCommas(_ formatter: Formatter) {
        // TODO: we don't currently check if [] is a subscript rather than a literal.
        // This should't matter in practice, as nobody splits subscripts onto multiple
        // lines, but ideally we'd check for this just in case
        formatter.forEach(.endOfScope("]")) { i, token in
            guard let prevTokenIndex = formatter.index(of: .nonSpaceOrComment, before: i) else { return }
            let prevToken = formatter.tokens[prevTokenIndex]
            if prevToken.isLinebreak {
                if let prevTokenIndex = formatter.index(of:
                    .nonSpaceOrCommentOrLinebreak, before: prevTokenIndex + 1) {
                    switch formatter.tokens[prevTokenIndex] {
                    case .startOfScope("["), .symbol(":"):
                        break // do nothing
                    case .symbol(","):
                        if !formatter.options.trailingCommas {
                            formatter.removeToken(at: prevTokenIndex)
                        }
                    default:
                        if formatter.options.trailingCommas {
                            formatter.insertToken(.symbol(","), at: prevTokenIndex + 1)
                        }
                    }
                }
            } else if prevToken == .symbol(",") {
                formatter.removeToken(at: prevTokenIndex)
            }
        }
    }

    /// Ensure that TODO, MARK and FIXME comments are followed by a : as required
    public class func todos(_ formatter: Formatter) {
        formatter.forEachToken { i, token in
            if case .commentBody(let string) = token {
                for tag in ["TODO", "MARK", "FIXME"] {
                    if string.hasPrefix(tag) {
                        var suffix = string.substring(from: tag.endIndex)
                        if let first = suffix.characters.first {
                            // If not followed by a space or :, don't mess with it as it may be a custom format
                            if " :".characters.contains(first) {
                                while let first = suffix.characters.first, " :".characters.contains(first) {
                                    suffix = suffix.substring(from: suffix.index(after: suffix.startIndex))
                                }
                                formatter.replaceToken(at: i, with: .commentBody(tag + ": " + suffix))
                            }
                        } else {
                            formatter.replaceToken(at: i, with: .commentBody(tag + ":"))
                        }
                        break
                    }
                }
            }
        }
    }

    /// Remove semicolons, except where doing so would change the meaning of the code
    public class func semicolons(_ formatter: Formatter) {
        formatter.forEach(.symbol(";")) { i, token in
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
    public class func linebreaks(_ formatter: Formatter) {
        formatter.forEach(.linebreak) { i, token in
            formatter.replaceToken(at: i, with: .linebreak(formatter.options.linebreak))
        }
    }

    /// Standardise the order of property specifiers
    public class func specifiers(_ formatter: Formatter) {
        let order = [
            "private(set)", "fileprivate(set)", "internal(set)", "public(set)",
            "private", "fileprivate", "internal", "public", "open",
            "final", "dynamic", // Can't be both
            "optional", "required",
            "convenience",
            "override",
            "lazy",
            "weak", "unowned",
            "static", "class",
            "mutating", "nonmutating",
            "prefix", "postfix",
        ]
        let validSpecifiers = Set(order)
        formatter.forEachToken { i, token in
            guard case .keyword(let string) = token else {
                return
            }
            switch string {
            case "let", "func", "var", "class", "extension", "init", "enum",
                 "struct", "typealias", "subscript", "associatedtype", "protocol":
                break
            default:
                return
            }
            var specifiers = [String: [Token]]()
            var index = i - 1
            var specifierIndex = i
            loop: while let token = formatter.token(at: index) {
                switch token {
                case .keyword(let string), .identifier(let string):
                    if !validSpecifiers.contains(string) {
                        break loop
                    }
                    specifiers[string] = [Token](formatter.tokens[index ..< specifierIndex])
                    specifierIndex = index
                case .endOfScope(")"):
                    if formatter.last(.nonSpaceOrCommentOrLinebreak, before: index) == .identifier("set") {
                        // Skip tokens for entire private(set) expression
                        while let token = formatter.token(at: index) {
                            if case .keyword(let string) = token,
                                ["private", "fileprivate", "public", "internal"].contains(string) {
                                specifiers[string + "(set)"] = [Token](formatter.tokens[index ..< specifierIndex])
                                specifierIndex = index
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
            guard specifiers.count > 0 else { return }
            var sortedSpecifiers = [Token]()
            for specifier in order {
                if let tokens = specifiers[specifier] {
                    sortedSpecifiers += tokens
                }
            }
            formatter.replaceTokens(inRange: specifierIndex ..< i, with: sortedSpecifiers)
        }
    }

    /// Remove redundant parens around the arguments for loops, if statements, closures, etc.
    public class func redundantParens(_ formatter: Formatter) {
        func tokenOutsideParenRequiresSpacing(at index: Int) -> Bool {
            if let token = formatter.token(at: index) {
                switch token {
                case .identifier, .keyword, .number:
                    return true
                default:
                    return false
                }
            }
            return false
        }

        func tokenInsideParenRequiresSpacing(at index: Int) -> Bool {
            if let token = formatter.token(at: index), case .symbol = token {
                return true
            }
            return tokenOutsideParenRequiresSpacing(at: index)
        }

        func removeParen(at index: Int) {
            if formatter.token(at: index - 1)?.isSpace == true &&
                formatter.token(at: index + 1)?.isSpace == true {
                // Need to remove one
                formatter.removeToken(at: index + 1)
            } else if case .startOfScope = formatter.tokens[index] {
                if tokenOutsideParenRequiresSpacing(at: index - 1) &&
                    tokenInsideParenRequiresSpacing(at: index + 1) {
                    // Need to insert one
                    formatter.insertToken(.space(" "), at: index + 1)
                }
            } else if tokenInsideParenRequiresSpacing(at: index - 1) &&
                tokenOutsideParenRequiresSpacing(at: index + 1) {
                // Need to insert one
                formatter.insertToken(.space(" "), at: index + 1)
            }
            formatter.removeToken(at: index)
        }

        formatter.forEach(.startOfScope("(")) { i, token in
            let previousIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i) ?? -1
            switch formatter.token(at: previousIndex) ?? .space("") {
            case .endOfScope("]"):
                if let startIndex = formatter.index(of: .startOfScope("["), before: previousIndex),
                    formatter.last(.nonSpaceOrCommentOrLinebreak, before: startIndex) == .startOfScope("{") {
                    fallthrough
                }
            case .startOfScope("{"):
                if let closingIndex = formatter.index(of: .endOfScope(")"), after: i),
                    formatter.next(.nonSpaceOrCommentOrLinebreak, after: closingIndex) == .keyword("in"),
                    formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i) != closingIndex {
                    if let labelIndex = formatter.index(of: .symbol(":"), after: i),
                        labelIndex < closingIndex {
                        break
                    }
                    removeParen(at: closingIndex)
                    removeParen(at: i)
                }
            case .identifier, .stringBody, .endOfScope, .symbol("?"), .symbol("!"):
                break
            case .keyword(let string):
                if ["if", "while", "switch", "for", "in", "where", "guard"].contains(string),
                    let closingIndex = formatter.index(of: .endOfScope(")"), after: i),
                    formatter.last(.nonSpaceOrCommentOrLinebreak, before: closingIndex)
                    != .endOfScope("}"),
                    let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: closingIndex) {
                    if nextToken != .startOfScope("{") && nextToken != .symbol(",") &&
                        !(string == "for" && nextToken == .keyword("in")) &&
                        !(string == "guard" && nextToken == .keyword("else")) {
                        fallthrough
                    }
                    if let commaIndex = formatter.index(of: .symbol(","), after: i),
                        commaIndex < closingIndex {
                        // Might be a tuple, so we won't remove the parens
                        // TODO: improve the logic here so we don't misidentify function calls as tuples
                        break
                    }
                    removeParen(at: closingIndex)
                    removeParen(at: i)
                    return
                }
            default:
                if let nextTokenIndex = formatter.index(of: .nonSpace, after: i),
                    let closingIndex = formatter.index(of: .nonSpace, after: nextTokenIndex, if: {
                        $0 == .endOfScope(")") }) {
                    if let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: closingIndex),
                        [.symbol("->"), .keyword("throws"), .keyword("rethrows")].contains(nextToken) {
                        return
                    }
                    switch formatter.tokens[nextTokenIndex] {
                    case .identifier, .number:
                        removeParen(at: closingIndex)
                        removeParen(at: i)
                        return
                    default:
                        break
                    }
                }
            }
        }
    }

    /// Remove redundant `get {}` clause inside read-only computed property
    public class func redundantGet(_ formatter: Formatter) {
        formatter.forEach(.identifier("get")) { i, token in
            if let previousIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i, if: {
                $0 == .startOfScope("{") }), let openIndex = formatter.index(of:
                .nonSpaceOrCommentOrLinebreak, after: i, if: { $0 == .startOfScope("{") }),
                let closeIndex = formatter.index(of: .endOfScope("}"), after: openIndex),
                let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: closeIndex, if: {
                    $0 == .endOfScope("}") }) {
                formatter.removeTokens(inRange: closeIndex ..< nextIndex)
                formatter.removeTokens(inRange: previousIndex + 1 ..< openIndex + 1)
                // TODO: fix-up indenting of lines in between removed braces
            }
        }
    }

    /// Normalize argument wrapping style
    public class func wrapArguments(_ formatter: Formatter) {
        func wrapArguments(for scopes: String..., mode: WrapMode, allowGrouping: Bool) {
            switch mode {
            case .beforeFirst:
                formatter.forEachToken(where: { scopes.contains($0.string) }) { i, token in
                    if let firstLinebreakIndex = formatter.index(of: .linebreak, after: i),
                        let closingBraceIndex = formatter.index(after: i, where: { $0.isEndOfScope(token) }),
                        firstLinebreakIndex < closingBraceIndex {
                        // Get indent
                        let start = formatter.startOfLine(at: i)
                        let indent: String
                        if let indentToken = formatter.token(at: start), case .space(let string) = indentToken {
                            indent = string
                        } else {
                            indent = ""
                        }
                        // Insert linebreak before closing paren
                        if let lastIndex = formatter.index(of: .nonSpace, before: closingBraceIndex, if: {
                            !$0.isLinebreak
                        }) {
                            formatter.insertSpace(indent, at: lastIndex + 1)
                            formatter.insertToken(.linebreak(formatter.options.linebreak), at: lastIndex + 1)
                        }
                        // Insert linebreak after each comma
                        var index = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: closingBraceIndex)!
                        if formatter.tokens[index] != .symbol(",") {
                            index += 1
                        }
                        while index > i {
                            guard let commaIndex = formatter.index(of: .symbol(","), before: index) else {
                                break
                            }
                            let linebreakIndex = formatter.index(of: .nonSpaceOrComment, after: commaIndex)!
                            if formatter.tokens[linebreakIndex].isLinebreak {
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
                }
            case .afterFirst:
                formatter.forEachToken(where: { scopes.contains($0.string) }) { i, token in
                    if let firstLinebreakIndex = formatter.index(of: .linebreak, after: i),
                        var closingBraceIndex = formatter.index(after: i, where: { $0.isEndOfScope(token) }),
                        firstLinebreakIndex < closingBraceIndex,
                        var firstArgumentIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i) {
                        // Remove linebreak after opening paren
                        formatter.removeTokens(inRange: i + 1 ..< firstArgumentIndex)
                        closingBraceIndex -= (firstArgumentIndex - (i + 1))
                        firstArgumentIndex = i + 1
                        // Get indent
                        let start = formatter.startOfLine(at: i)
                        var indent = ""
                        for token in formatter.tokens[start ..< firstArgumentIndex] {
                            if case .space(let string) = token {
                                indent += string
                            } else {
                                indent += String(repeating: " ", count: token.string.characters.count)
                            }
                        }
                        // Remove linebreak before closing paren
                        if let lastIndex = formatter.index(of: .nonSpace, before: closingBraceIndex, if: {
                            $0.isLinebreak
                        }) {
                            formatter.removeTokens(inRange: lastIndex ..< closingBraceIndex)
                            closingBraceIndex = lastIndex
                            // Remove trailing comma
                            if let prevCommaIndex = formatter.index(
                                of: .nonSpaceOrCommentOrLinebreak, before: closingBraceIndex, if: {
                                    return $0 == .symbol(",")
                            }) {
                                formatter.removeToken(at: prevCommaIndex)
                                closingBraceIndex -= 1
                            }
                        }
                        // Insert linebreak after each comma
                        var index = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: closingBraceIndex)!
                        if formatter.tokens[index] != .symbol(",") {
                            index += 1
                        }
                        while index > i {
                            guard let commaIndex = formatter.index(of: .symbol(","), before: index) else {
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
                }
            case .disabled:
                break
            }
        }
        wrapArguments(for: "(", "<", mode: formatter.options.wrapArguments, allowGrouping: false)
        wrapArguments(for: "[", mode: formatter.options.wrapElements, allowGrouping: true)
    }

    /// Normalize the use of void in closure arguments and return values
    public class func void(_ formatter: Formatter) {
        formatter.forEach(.identifier("Void")) { i, token in
            if let prevIndex = formatter.index(of: .nonSpaceOrLinebreak, before: i, if: {
                $0 == .startOfScope("(") }), let nextIndex = formatter.index(of:
                .nonSpaceOrLinebreak, after: i, if: { $0 == .endOfScope(")") }) {
                if let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: nextIndex),
                    [.symbol("->"), .keyword("throws"), .keyword("rethrows")].contains(nextToken) {
                    // Remove Void
                    formatter.removeTokens(inRange: prevIndex + 1 ..< nextIndex)
                } else if formatter.options.useVoid {
                    // Strip parens
                    formatter.removeTokens(inRange: i + 1 ..< nextIndex + 1)
                    formatter.removeTokens(inRange: prevIndex ..< i)
                } else {
                    // Remove Void
                    formatter.removeTokens(inRange: prevIndex + 1 ..< nextIndex)
                }
            } else if !formatter.options.useVoid ||
                formatter.next(.nonSpaceOrCommentOrLinebreak, after: i) == .symbol("->") {
                if let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: i),
                    prevToken == .symbol(".") || prevToken == .keyword("typealias") {
                    return
                }
                // Convert to parens
                formatter.replaceToken(at: i, with: .endOfScope(")"))
                formatter.insertToken(.startOfScope("("), at: i)
            }
        }
        if formatter.options.useVoid {
            formatter.forEach(.startOfScope("(")) { i, token in
                if formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) == .symbol("->"),
                    let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i, if: {
                        $0 == .endOfScope(")") }), formatter.next(.nonSpaceOrCommentOrLinebreak,
                                                                  after: nextIndex) != .symbol("->") {
                    // Replace with Void
                    formatter.replaceTokens(inRange: i ..< nextIndex + 1, with: [.identifier("Void")])
                }
            }
        }
    }

    /// Ensure hex literals are all upper- or lower-cased
    public class func hexLiterals(_ formatter: Formatter) {
        let prefix = "0x"
        formatter.forEachToken { i, token in
            if case .number(let string) = token, string.hasPrefix(prefix) {
                if formatter.options.uppercaseHex {
                    formatter.replaceToken(at: i, with: .number(prefix +
                            string.substring(from: prefix.endIndex).uppercased()))
                } else {
                    formatter.replaceToken(at: i, with: .number(string.lowercased()))
                }
            }
        }
    }

    /// Strip header comments from the file
    public class func stripHeader(_ formatter: Formatter) {
        guard formatter.options.stripHeader && !formatter.options.fragment else { return }
        if let startIndex = formatter.index(of: .nonSpaceOrLinebreak, after: -1) {
            switch formatter.tokens[startIndex] {
            case .startOfScope("//"):
                var lastIndex = startIndex
                while let index = formatter.index(of: .linebreak, after: lastIndex) {
                    if let nextToken = formatter.token(at: index + 1), nextToken != .startOfScope("//") {
                        switch nextToken {
                        case .linebreak:
                            formatter.removeTokens(inRange: 0 ..< index + 2)
                        case .space where formatter.token(at: index + 2)?.isLinebreak == true:
                            formatter.removeTokens(inRange: 0 ..< index + 3)
                        default:
                            break
                        }
                        return
                    }
                    lastIndex = index
                }
            case .startOfScope("/*"):
                // TODO: handle multiline comment headers
                break
            default:
                return
            }
        }
    }
}
