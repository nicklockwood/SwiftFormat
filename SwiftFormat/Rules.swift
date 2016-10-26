//
//  Rules.swift
//  SwiftFormat
//
//  Version 0.14
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

public typealias FormatRule = (Formatter) -> Void

/// Implement the following rules with respect to the spacing around parens:
/// * There is no space between an opening paren and the preceding identifier,
///   unless the identifier is one of the specified keywords
/// * There is no space between an opening paren and the preceding closing brace
/// * There is no space between an opening paren and the preceding closing square bracket
/// * There is space between a closing paren and following identifier
/// * There is space between a closing paren and following opening brace
/// * There is no space between a closing paren and following opening square bracket
public func spaceAroundParens(_ formatter: Formatter) {

    func spaceAfter(_ identifier: String, index: Int) -> Bool {
        switch identifier {
        case "@escaping",
             "@autoclosure",
             "internal",
             "case",
             "for",
             "guard",
             "if",
             "in",
             "inout",
             "return",
             "switch",
             "where",
             "while",
             "as",
             "catch",
             "is",
             "let",
             "rethrows",
             "throw",
             "throws",
             "try":
            return formatter.previousNonWhitespaceToken(fromIndex: index)?.string != "."
        default:
            return false
        }
    }

    func isCaptureList(atIndex i: Int) -> Bool {
        assert(formatter.tokens[i].string == "]")
        guard let previousToken = formatter.previousToken(fromIndex: i + 1, matching: {
            return !$0.isWhitespaceOrCommentOrLinebreak && ($0.type != .endOfScope || $0.string != "]")
        }), previousToken.type == .startOfScope, previousToken.string == "{" else {
            return false
        }
        guard let nextToken = formatter.nextToken(fromIndex: i, matching: {
            return !$0.isWhitespaceOrCommentOrLinebreak && ($0.type != .startOfScope || $0.string != "(")
        }), nextToken.type == .identifier, nextToken.string == "in" else {
            return false
        }
        return true
    }

    formatter.forEachToken("(") { i, token in
        guard let previousToken = formatter.tokenAtIndex(i - 1) else {
            return
        }
        if previousToken.type == .identifier && spaceAfter(previousToken.string, index: i - 1) {
            formatter.insertToken(Token(.whitespace, " "), atIndex: i)
        } else if previousToken.type == .endOfScope && previousToken.string == "]" {
            if isCaptureList(atIndex: i - 1) {
                formatter.insertToken(Token(.whitespace, " "), atIndex: i)
            }
        } else if previousToken.type == .whitespace {
            if let token = formatter.tokenAtIndex(i - 2) {
                if token.type == .identifier && !spaceAfter(token.string, index: i - 2) {
                    formatter.removeTokenAtIndex(i - 1)
                } else if token.type == .endOfScope {
                    switch token.string {
                    case "}", ")", ">":
                        formatter.removeTokenAtIndex(i - 1)
                    case "]":
                        if !isCaptureList(atIndex: i - 2) {
                            formatter.removeTokenAtIndex(i - 1)
                        }
                    default:
                        break
                    }
                }
            }
        }
    }
    formatter.forEachToken(")") { i, token in
        guard let nextToken = formatter.tokenAtIndex(i + 1) else {
            return
        }
        if nextToken.type == .identifier || nextToken.string == "{" {
            formatter.insertToken(Token(.whitespace, " "), atIndex: i + 1)
        } else if nextToken.type == .whitespace && formatter.tokenAtIndex(i + 2)?.string == "[" {
            formatter.removeTokenAtIndex(i + 1)
        }
    }
}

/// Remove whitespace immediately inside parens
public func spaceInsideParens(_ formatter: Formatter) {
    formatter.forEachToken("(") { i, token in
        if formatter.tokenAtIndex(i + 1)?.type == .whitespace {
            formatter.removeTokenAtIndex(i + 1)
        }
    }
    formatter.forEachToken(")") { i, token in
        if formatter.tokenAtIndex(i - 1)?.type == .whitespace &&
            formatter.tokenAtIndex(i - 2)?.type != .linebreak {
            formatter.removeTokenAtIndex(i - 1)
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
public func spaceAroundBrackets(_ formatter: Formatter) {

    func spaceAfter(_ identifier: String, index: Int) -> Bool {
        switch identifier {
        case "case",
             "guard",
             "if",
             "in",
             "return",
             "switch",
             "where",
             "while",
             "as",
             "is":
            return formatter.previousNonWhitespaceToken(fromIndex: index)?.string != "."
        default:
            return false
        }
    }

    formatter.forEachToken("[") { i, token in
        guard let previousToken = formatter.tokenAtIndex(i - 1) else {
            return
        }
        if previousToken.type == .identifier && spaceAfter(previousToken.string, index: i - 1) {
            formatter.insertToken(Token(.whitespace, " "), atIndex: i)
        } else if previousToken.type == .whitespace {
            if let token = formatter.tokenAtIndex(i - 2) {
                if (token.type == .endOfScope && ["]", "}", ")"].contains(token.string)) ||
                    (token.type == .identifier && !spaceAfter(token.string, index: i - 2)) {
                    formatter.removeTokenAtIndex(i - 1)
                }
            }
        }
    }
    formatter.forEachToken("]") { i, token in
        guard let nextToken = formatter.tokenAtIndex(i + 1) else {
            return
        }
        if nextToken.type == .identifier || nextToken.string == "{" {
            formatter.insertToken(Token(.whitespace, " "), atIndex: i + 1)
        } else if nextToken.type == .whitespace && formatter.tokenAtIndex(i + 2)?.string == "[" {
            formatter.removeTokenAtIndex(i + 1)
        }
    }
}

/// Remove whitespace immediately inside square brackets
public func spaceInsideBrackets(_ formatter: Formatter) {
    formatter.forEachToken("[") { i, token in
        if formatter.tokenAtIndex(i + 1)?.type == .whitespace {
            formatter.removeTokenAtIndex(i + 1)
        }
    }
    formatter.forEachToken("]") { i, token in
        if formatter.tokenAtIndex(i - 1)?.type == .whitespace &&
            formatter.tokenAtIndex(i - 2)?.type != .linebreak {
            formatter.removeTokenAtIndex(i - 1)
        }
    }
}

/// Ensure that there is space between an opening brace and the preceding
/// identifier, and between a closing brace and the following identifier.
public func spaceAroundBraces(_ formatter: Formatter) {
    formatter.forEachToken("{") { i, token in
        if let previousToken = formatter.tokenAtIndex(i - 1) {
            switch previousToken.type {
            case .whitespace, .linebreak:
                break
            case .startOfScope:
                if previousToken.string == "\"" {
                    fallthrough
                }
            default:
                formatter.insertToken(Token(.whitespace, " "), atIndex: i)
            }
        }
    }
    formatter.forEachToken("}") { i, token in
        if formatter.tokenAtIndex(i + 1)?.type == .identifier {
            formatter.insertToken(Token(.whitespace, " "), atIndex: i + 1)
        }
    }
}

/// Ensure that there is space immediately inside braces
public func spaceInsideBraces(_ formatter: Formatter) {
    formatter.forEachToken("{") { i, token in
        if let nextToken = formatter.tokenAtIndex(i + 1) {
            if nextToken.type == .whitespace {
                if formatter.tokenAtIndex(i + 2)?.string == "}" {
                    formatter.removeTokenAtIndex(i + 1)
                }
            } else if nextToken.type != .linebreak && nextToken.string != "}" {
                formatter.insertToken(Token(.whitespace, " "), atIndex: i + 1)
            }
        }
    }
    formatter.forEachToken("}") { i, token in
        if let previousToken = formatter.tokenAtIndex(i - 1),
            previousToken.type != .whitespace && previousToken.type != .linebreak && previousToken.string != "{" {
            formatter.insertToken(Token(.whitespace, " "), atIndex: i)
        }
    }
}

/// Ensure there is no space between an opening chevron and the preceding identifier
public func spaceAroundGenerics(_ formatter: Formatter) {
    formatter.forEachToken("<", ofType: .startOfScope) { i, token in
        if formatter.tokenAtIndex(i - 1)?.type == .whitespace &&
            formatter.tokenAtIndex(i - 2)?.type == .identifier {
            formatter.removeTokenAtIndex(i - 1)
        }
    }
}

/// Remove whitespace immediately inside chevrons
public func spaceInsideGenerics(_ formatter: Formatter) {
    formatter.forEachToken("<", ofType: .startOfScope) { i, token in
        if formatter.tokenAtIndex(i + 1)?.type == .whitespace {
            formatter.removeTokenAtIndex(i + 1)
        }
    }
    formatter.forEachToken(">", ofType: .endOfScope) { i, token in
        if formatter.tokenAtIndex(i - 1)?.type == .whitespace &&
            formatter.tokenAtIndex(i - 2)?.type != .linebreak {
            formatter.removeTokenAtIndex(i - 1)
        }
    }
}

/// Implement the following rules with respect to the spacing around operators:
/// * Infix operators are separated from their operands by a space on either
///   side. Does not affect prefix/postfix operators, as required by syntax.
/// * Punctuation such as commas and colons is consistently followed by a
///   single space, unless it appears at the end of a line, and is not
///   preceded by a space, unless it appears at the beginning of a line.
public func spaceAroundOperators(_ formatter: Formatter) {

    func isLvalue(_ token: Token) -> Bool {
        switch token.type {
        case .identifier, .number, .endOfScope:
            return true
        case .symbol:
            return ["?", "!"].contains(token.string)
        default:
            return false
        }
    }

    func isRvalue(_ token: Token) -> Bool {
        switch token.type {
        case .identifier, .number, .startOfScope:
            return true
        default:
            return false
        }
    }

    func isUnwrapOperatorSequence(_ token: Token) -> Bool {
        for c in token.string.characters {
            if c != "?" && c != "!" {
                return false
            }
        }
        return true
    }

    func spaceAfter(_ identifier: String, index: Int) -> Bool {
        switch identifier {
        case "case",
             "guard",
             "if",
             "in",
             "let",
             "return",
             "switch",
             "where",
             "while",
             "as",
             "is":
            return formatter.previousNonWhitespaceToken(fromIndex: index)?.string != "."
        default:
            return false
        }
    }

    var scopeStack: [Token] = []
    formatter.forEachToken { i, token in
        switch token.type {
        case .symbol:
            if [":", ",", ";"].contains(token.string) {
                if let nextToken = formatter.tokenAtIndex(i + 1) {
                    switch nextToken.type {
                    case .whitespace, .linebreak, .endOfScope:
                        break
                    case .identifier:
                        if token.string == ":" {
                            if formatter.tokenAtIndex(i + 2)?.string == ":" {
                                // It's a selector
                                break
                            }
                        }
                        fallthrough
                    default:
                        // Ensure there is a space after the token
                        formatter.insertToken(Token(.whitespace, " "), atIndex: i + 1)
                    }
                }
                if token.string == ":" && scopeStack.last?.string == "?" {
                    // Treat the next : after a ? as closing the ternary scope
                    scopeStack.removeLast()
                    // Ensure there is a space before the :
                    if let previousToken = formatter.tokenAtIndex(i - 1) {
                        if previousToken.type != .whitespace && previousToken.type != .linebreak {
                            formatter.insertToken(Token(.whitespace, " "), atIndex: i)
                        }
                    }
                } else if formatter.tokenAtIndex(i - 1)?.type == .whitespace &&
                    formatter.tokenAtIndex(i - 2)?.type != .linebreak {
                    // Remove space before the token
                    formatter.removeTokenAtIndex(i - 1)
                }
            } else if token.string == "?" {
                if let previousToken = formatter.tokenAtIndex(i - 1), let nextToken = formatter.tokenAtIndex(i + 1) {
                    if nextToken.type == .whitespace || nextToken.type == .linebreak {
                        if previousToken.type == .whitespace || previousToken.type == .linebreak {
                            // ? is a ternary operator, treat it as the start of a scope
                            scopeStack.append(token)
                        }
                    } else if previousToken.type == .identifier && ["as", "try"].contains(previousToken.string) {
                        formatter.insertToken(Token(.whitespace, " "), atIndex: i + 1)
                    }
                }
            } else if token.string == "!" {
                if let previousToken = formatter.tokenAtIndex(i - 1), let nextToken = formatter.tokenAtIndex(i + 1) {
                    if nextToken.type != .whitespace && nextToken.type != .linebreak &&
                        previousToken.type == .identifier && ["as", "try"].contains(previousToken.string) {
                        formatter.insertToken(Token(.whitespace, " "), atIndex: i + 1)
                    }
                }
            } else if token.string == "." {
                if formatter.tokenAtIndex(i + 1)?.type == .whitespace {
                    formatter.removeTokenAtIndex(i + 1)
                }
                if let previousToken = formatter.tokenAtIndex(i - 1) {
                    let previousTokenWasWhitespace = (previousToken.type == .whitespace)
                    let previousNonWhitespaceTokenIndex = i - (previousTokenWasWhitespace ? 2 : 1)
                    if let previousNonWhitespaceToken = formatter.tokenAtIndex(previousNonWhitespaceTokenIndex) {
                        if previousNonWhitespaceToken.type != .linebreak &&
                            previousNonWhitespaceToken.string != "{" &&
                            (previousNonWhitespaceToken.type != .symbol ||
                                (previousNonWhitespaceToken.string == "?" && scopeStack.last?.string != "?") ||
                                (previousNonWhitespaceToken.string != "?" &&
                                    formatter.tokenAtIndex(previousNonWhitespaceTokenIndex - 1)?.type != .whitespace &&
                                    isUnwrapOperatorSequence(previousNonWhitespaceToken))) &&
                            !spaceAfter(previousNonWhitespaceToken.string, index: previousNonWhitespaceTokenIndex) {
                            if previousTokenWasWhitespace {
                                formatter.removeTokenAtIndex(i - 1)
                            }
                        } else if !previousTokenWasWhitespace {
                            formatter.insertToken(Token(.whitespace, " "), atIndex: i)
                        }
                    }
                }
            } else if token.string == "->" {
                if let nextToken = formatter.tokenAtIndex(i + 1) {
                    if nextToken.type != .whitespace && nextToken.type != .linebreak {
                        formatter.insertToken(Token(.whitespace, " "), atIndex: i + 1)
                    }
                }
                if let previousToken = formatter.tokenAtIndex(i - 1) {
                    if previousToken.type != .whitespace && previousToken.type != .linebreak {
                        formatter.insertToken(Token(.whitespace, " "), atIndex: i)
                    }
                }
            } else if token.string != "..." && token.string != "..<" {
                if let previousToken = formatter.tokenAtIndex(i - 1), isLvalue(previousToken) {
                    if let nextToken = formatter.tokenAtIndex(i + 1), isRvalue(nextToken) {
                        // Insert space before and after the infix token
                        formatter.insertToken(Token(.whitespace, " "), atIndex: i + 1)
                        formatter.insertToken(Token(.whitespace, " "), atIndex: i)
                    }
                }
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
public func spaceAroundComments(_ formatter: Formatter) {
    formatter.forEachToken(ofType: .startOfScope) { i, token in
        guard let previousToken = formatter.tokenAtIndex(i - 1),
            (token.string == "/*" || token.string == "//") else { return }
        if !previousToken.isWhitespaceOrLinebreak {
            formatter.insertToken(Token(.whitespace, " "), atIndex: i)
        }
    }
    formatter.forEachToken("*/") { i, token in
        guard let nextToken = formatter.tokenAtIndex(i + 1) else { return }
        if !nextToken.isWhitespaceOrLinebreak {
            formatter.insertToken(Token(.whitespace, " "), atIndex: i + 1)
        }
    }
}

/// Add space inside comments, taking care not to mangle headerdoc or
/// carefully preformatted comments, such as star boxes, etc.
public func spaceInsideComments(_ formatter: Formatter) {
    formatter.forEachToken("/*") { i, token in
        guard let nextToken = formatter.tokenAtIndex(i + 1) else { return }
        if !nextToken.isWhitespaceOrLinebreak {
            let string = nextToken.string
            if string.hasPrefix("*") || string.hasPrefix("!") || string.hasPrefix(":") {
                if string.characters.count > 1 && !string.hasPrefix("**") &&
                    !string.hasPrefix("* ") && !string.hasPrefix("*\t") && !string.hasPrefix("*/") {
                    let string = String(string.characters.first!) + " " +
                        string.substring(from: string.characters.index(string.startIndex, offsetBy: 1))
                    formatter.replaceTokenAtIndex(i + 1, with: Token(.commentBody, string))
                }
            } else {
                formatter.insertToken(Token(.whitespace, " "), atIndex: i + 1)
            }
        }
    }
    formatter.forEachToken("//") { i, token in
        guard let nextToken = formatter.tokenAtIndex(i + 1) else { return }
        if !nextToken.isWhitespaceOrLinebreak {
            let string = nextToken.string
            if string.hasPrefix("/") || string.hasPrefix("!") || string.hasPrefix(":") {
                if string.characters.count > 1 && !string.hasPrefix("/ ") && !string.hasPrefix("/\t") {
                    let string = String(string.characters.first!) + " " +
                        string.substring(from: string.characters.index(string.startIndex, offsetBy: 1))
                    formatter.replaceTokenAtIndex(i + 1, with: Token(.commentBody, string))
                }
            } else {
                formatter.insertToken(Token(.whitespace, " "), atIndex: i + 1)
            }
        }
    }
    formatter.forEachToken("*/") { i, token in
        guard let previousToken = formatter.tokenAtIndex(i - 1) else { return }
        if !previousToken.isWhitespaceOrLinebreak && !previousToken.string.hasSuffix("*") {
            formatter.insertToken(Token(.whitespace, " "), atIndex: i)
        }
    }
}

/// Add or removes the space around range operators
public func ranges(_ formatter: Formatter) {
    formatter.forEachToken(ofType: .symbol) { i, token in
        if token.string == "..." || token.string == "..<" {
            if !formatter.options.spaceAroundRangeOperators {
                if formatter.tokenAtIndex(i + 1)?.type == .whitespace {
                    formatter.removeTokenAtIndex(i + 1)
                }
                if formatter.tokenAtIndex(i - 1)?.type == .whitespace {
                    formatter.removeTokenAtIndex(i - 1)
                }
            } else if let nextToken = formatter.nextNonWhitespaceOrCommentOrLinebreakToken(fromIndex: i) {
                if nextToken.string != ")" && nextToken.string != "," {
                    if formatter.tokenAtIndex(i + 1)?.isWhitespaceOrLinebreak == false {
                        formatter.insertToken(Token(.whitespace, " "), atIndex: i + 1)
                    }
                    if formatter.tokenAtIndex(i - 1)?.isWhitespaceOrLinebreak == false {
                        formatter.insertToken(Token(.whitespace, " "), atIndex: i)
                    }
                }
            }
        }
    }
}

/// Collapse all consecutive whitespace characters to a single space, except at
/// the start of a line or inside a comment or string, as these have no semantic
/// meaning and lead to noise in commits.
public func consecutiveSpaces(_ formatter: Formatter) {
    formatter.forEachToken(ofType: .whitespace) { i, token in
        if let previousToken = formatter.tokenAtIndex(i - 1), previousToken.type != .linebreak {
            if token.string == "" {
                formatter.removeTokenAtIndex(i)
            } else if token.string != " " {
                let scope = formatter.scopeAtIndex(i)
                if scope?.string != "/*" && scope?.string != "//" {
                    formatter.replaceTokenAtIndex(i, with: Token(.whitespace, " "))
                }
            }
        }
    }
}

/// Remove trailing whitespace from the end of lines, as it has no semantic
/// meaning and leads to noise in commits.
public func trailingWhitespace(_ formatter: Formatter) {
    formatter.forEachToken(ofType: .linebreak) { i, token in
        if let previousToken = formatter.tokenAtIndex(i - 1) {
            if previousToken.type == .whitespace {
                formatter.removeTokenAtIndex(i - 1)
            } else if previousToken.type == .commentBody {
                // should never happen as Tokenizer treats trailing space as new token
                assert(!(previousToken.string.characters.last?.isWhitespace == true))
            }
        }
    }
    if formatter.tokens.last?.type == .whitespace {
        formatter.removeLastToken()
    }
}

/// Collapse all consecutive blank lines into a single blank line
public func consecutiveBlankLines(_ formatter: Formatter) {
    var linebreakCount = 0
    var lastTokenType = TokenType.whitespace
    formatter.forEachToken { i, token in
        if token.type == .linebreak {
            linebreakCount += 1
            if linebreakCount > 2 {
                formatter.removeTokenAtIndex(i)
                if lastTokenType == .whitespace {
                    formatter.removeTokenAtIndex(i - 1)
                    lastTokenType = .linebreak
                }
                linebreakCount -= 1
                return // continue
            }
        } else if token.type != .whitespace {
            linebreakCount = 0
        }
        lastTokenType = token.type
    }
    if linebreakCount > 1 && !formatter.options.fragment {
        if lastTokenType == .whitespace {
            formatter.removeLastToken()
        }
        formatter.removeLastToken()
    }
}

/// Remove blank lines immediately before a closing brace, bracket, paren or chevron,
/// unless it's followed by more code on the same line (e.g. } else { )
public func blankLinesAtEndOfScope(_ formatter: Formatter) {
    formatter.forEachToken(ofType: .endOfScope) { i, token in
        guard ["}", ")", "]", ">"].contains(token.string) else { return }
        if let nw = formatter.nextNonWhitespaceOrCommentToken(fromIndex: i) {
            // If there is extra code after the closing scope on the same line, ignore it
            guard nw.type == .linebreak else { return }
        }
        // Find previous non-whitespace token
        var index = i - 1
        var indexOfFirstLineBreak: Int?
        var indexOfLastLineBreak: Int?
        loop: while let token = formatter.tokenAtIndex(index) {
            switch token.type {
            case .linebreak:
                indexOfFirstLineBreak = index
                if indexOfLastLineBreak == nil {
                    indexOfLastLineBreak = index
                }
            case .whitespace:
                break
            default:
                break loop
            }
            index -= 1
        }
        if let indexOfFirstLineBreak = indexOfFirstLineBreak, let indexOfLastLineBreak = indexOfLastLineBreak {
            formatter.removeTokensInRange(indexOfFirstLineBreak ..< indexOfLastLineBreak)
            return
        }
    }
}

/// Adds a blank line immediately after a closing brace, unless followed by another closing brace
public func blankLinesBetweenScopes(_ formatter: Formatter) {
    var spaceableScopeStack = [true]
    var isSpaceableScopeType = false
    formatter.forEachToken { i, token in
        switch token.type {
        case .identifier:
            if formatter.previousNonWhitespaceToken(fromIndex: i)?.string != "." {
                if ["class", "struct", "extension", "enum"].contains(token.string) {
                    isSpaceableScopeType = true
                } else if ["func", "var"].contains(token.string) {
                    isSpaceableScopeType = false
                }
            }
        case .startOfScope:
            if token.string == "{" {
                spaceableScopeStack.append(isSpaceableScopeType)
                isSpaceableScopeType = false
            }
        case .endOfScope:
            if token.string == "}" {
                if spaceableScopeStack.count > 1 && spaceableScopeStack[spaceableScopeStack.count - 2] {
                    guard let openingBraceIndex = formatter.indexOfPreviousToken(fromIndex: i, matching: {
                        $0.type == .startOfScope && $0.string == "{" }),
                        let previousLinebreakIndex = formatter.indexOfPreviousToken(fromIndex: i, matching: {
                            $0.type == .linebreak }), previousLinebreakIndex > openingBraceIndex else {
                        // Inline braces
                        break
                    }
                    var i = i
                    if let nextTokenIndex = formatter.indexOfNextToken(fromIndex: i, matching: { $0.type != .whitespace }),
                        formatter.tokenAtIndex(nextTokenIndex)?.string == "(",
                        let closingParenIndex = formatter.indexOfNextToken(fromIndex: nextTokenIndex, matching: {
                            return $0.type == .endOfScope && $0.string == ")"
                        }) {
                        i = closingParenIndex
                    }
                    if let nextTokenIndex = formatter.indexOfNextToken(fromIndex: i, matching: {
                        !$0.isWhitespaceOrLinebreak }), let nextToken = formatter.tokenAtIndex(nextTokenIndex),
                        nextToken.type != .endOfScope && nextToken.type != .error && nextToken.string != "." {
                        if let firstLinebreakIndex = formatter.indexOfNextToken(fromIndex: i, matching: { $0.type == .linebreak }),
                            firstLinebreakIndex < nextTokenIndex {
                            if let secondLinebreakIndex = formatter.indexOfNextToken(
                                fromIndex: firstLinebreakIndex, matching: { $0.type == .linebreak }),
                                secondLinebreakIndex < nextTokenIndex {
                                // Already has a blank line after
                            } else {
                                // Insert linebreak
                                formatter.insertToken(Token(.linebreak, formatter.options.linebreak), atIndex: firstLinebreakIndex)
                            }
                        }
                    }
                }
                spaceableScopeStack.removeLast()
            }
        default:
            break
        }
    }
}

/// Always end file with a linebreak, to avoid incompatibility with certain unix tools:
/// http://stackoverflow.com/questions/2287967/why-is-it-recommended-to-have-empty-line-in-the-end-of-file
public func linebreakAtEndOfFile(_ formatter: Formatter) {
    if let lastToken = formatter.previousToken(fromIndex: formatter.tokens.count, matching: {
        return $0.type != .whitespace && $0.type != .error
    }), lastToken.type != .linebreak {
        formatter.insertToken(Token(.linebreak, formatter.options.linebreak), atIndex: formatter.tokens.count)
    }
}

/// Indent code according to standard scope indenting rules.
/// The type (tab or space) and level (2 spaces, 4 spaces, etc.) of the
/// indenting can be configured with the `options` parameter of the formatter.
public func indent(_ formatter: Formatter) {
    var scopeIndexStack: [Int] = []
    var scopeStartLineIndexes: [Int] = []
    var lastNonWhitespaceOrLinebreakIndex = -1
    var lastNonWhitespaceIndex = -1
    var indentStack = [""]
    var indentCounts = [1]
    var linewrapStack = [false]
    var lineIndex = 0

    @discardableResult func insertWhitespace(_ whitespace: String, atIndex index: Int) -> Int {
        if formatter.tokenAtIndex(index)?.type == .whitespace {
            formatter.replaceTokenAtIndex(index, with: Token(.whitespace, whitespace))
            return 0 // Inserted 0 tokens
        }
        formatter.insertToken(Token(.whitespace, whitespace), atIndex: index)
        return 1 // Inserted 1 token
    }

    func currentScope() -> Token? {
        if let scopeIndex = scopeIndexStack.last {
            return formatter.tokens[scopeIndex]
        }
        return nil
    }

    func tokenIsEndOfStatement(_ i: Int) -> Bool {
        if let token = formatter.tokenAtIndex(i) {
            switch token.type {
            case .identifier, .endOfScope:
                // TODO: handle in
                // TODO: handle context-specific keywords
                // associativity, convenience, dynamic, didSet, final, get, infix, indirect,
                // lazy, left, mutating, none, nonmutating, optional, override, postfix, precedence,
                // prefix, Protocol, required, right, set, Type, unowned, weak, willSet
                switch token.string {
                case "associatedtype",
                     "import",
                     "init",
                     "inout",
                     "let",
                     "subscript",
                     "var",
                     "func",
                     "case",
                     "default",
                     "for",
                     "guard",
                     "if",
                     "switch",
                     "where",
                     "while",
                     "do",
                     "as",
                     "catch",
                     "is",
                     "super",
                     "throw",
                     "try":
                    return formatter.previousNonWhitespaceToken(fromIndex: i)?.string == "."
                case "return":
                    if formatter.previousNonWhitespaceToken(fromIndex: i)?.string == "." {
                        return true
                    }
                    guard let nextToken = formatter.nextNonWhitespaceOrCommentOrLinebreakToken(fromIndex: i) else {
                        return true
                    }
                    if nextToken.type != .identifier && nextToken.type != .endOfScope {
                        return true
                    }
                    switch nextToken.string {
                    case "let",
                         "var",
                         "func",
                         "case",
                         "default",
                         "for",
                         "guard",
                         "if",
                         "switch",
                         "while",
                         "do",
                         "super",
                         "throw",
                         "return":
                        return true
                    default:
                        return false
                    }
                default:
                    return true
                }
            case .symbol:
                switch token.string {
                case ".", ":":
                    return false
                case ",":
                    // For arrays or argument lists, we already indent
                    return ["[", "(", "case"].contains(currentScope()?.string ?? "")
                default:
                    if formatter.previousToken(fromIndex: i, matching: {
                        $0.type == .identifier && $0.string == "operator"
                    }) != nil {
                        return true
                    }
                    if let previousToken = formatter.tokenAtIndex(i - 1) {
                        if previousToken.string == "as" || previousToken.string == "try" {
                            return false
                        }
                        if previousToken.isWhitespaceOrCommentOrLinebreak {
                            return formatter.previousNonWhitespaceOrCommentOrLinebreakToken(fromIndex: i)?.string == "="
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
        if let token = formatter.tokenAtIndex(i) {
            switch token.type {
            case .identifier:
                // TODO: handle "in"
                switch token.string {
                case "as",
                     "dynamicType",
                     "is",
                     "rethrows",
                     "throws",
                     "where":
                    return false
                default:
                    return true
                }
            case .symbol:
                if token.string == "." {
                    if let previousToken = formatter.previousNonWhitespaceOrCommentOrLinebreakToken(fromIndex: i) {
                        // Is this an enum value?
                        let scope = currentScope()?.string ?? ""
                        return ["(", "[", "case"].contains(scope) && [scope, ",", ":"].contains(previousToken.string)
                    }
                    return true
                }
                if token.string == "," {
                    // For arrays, dictionaries, cases, or argument lists, we already indent
                    return ["[", "(", "case"].contains(currentScope()?.string ?? "")
                }
                if let nextToken = formatter.tokenAtIndex(i + 1),
                    nextToken.isWhitespaceOrCommentOrLinebreak {
                    // Is an infix operator
                    return false
                }
            default:
                return true
            }
        }
        return true
    }

    func tokenIsStartOfClosure(_ i: Int) -> Bool {
        var i = i - 1
        while let token = formatter.tokenAtIndex(i) {
            switch token.type {
            case .identifier:
                if ["if", "for", "while", "catch", "switch", "guard" /* TODO: get/set/didSet */ ].contains(token.string) {
                    // Check that it's actually a keyword and not a member property or enum value
                    return formatter.previousNonWhitespaceOrCommentOrLinebreakToken(fromIndex: i)?.string == "."
                }
            case .startOfScope:
                return true
            default:
                break
            }
            i = formatter.indexOfPreviousToken(fromIndex: i) {
                return !$0.isWhitespaceOrCommentOrLinebreak && ($0.type != .endOfScope || $0.string == "}")
            } ?? -1
        }
        return true
    }

    if formatter.options.fragment,
        let firstIndex = formatter.indexOfNextToken(fromIndex: -1, matching: { !$0.isWhitespaceOrLinebreak }),
        let indentToken = formatter.tokenAtIndex(firstIndex - 1), indentToken.type == .whitespace {
        indentStack[0] = indentToken.string
    } else {
        insertWhitespace("", atIndex: 0)
    }
    formatter.forEachToken { i, token in
        var i = i
        if token.type == .startOfScope {
            if token.string == ":" && currentScope()?.string == "case" {
                indentStack.removeLast()
                indentCounts.removeLast()
                linewrapStack.removeLast()
                scopeStartLineIndexes.removeLast()
                scopeIndexStack.removeLast()
            } else if token.string == "{" && !tokenIsStartOfClosure(i) {
                if linewrapStack.last == true {
                    indentStack.removeLast()
                    linewrapStack[linewrapStack.count - 1] = false
                }
            }
            // Handle start of scope
            scopeIndexStack.append(i)
            let indentCount: Int
            if lineIndex > scopeStartLineIndexes.last ?? -1 {
                indentCount = 1
            } else {
                indentCount = indentCounts.last! + 1
            }
            indentCounts.append(indentCount)
            var indent = indentStack[indentStack.count - indentCount]
            switch token.string {
            case "/*":
                // Comments only indent one space
                indent += " "
            case "[", "(":
                if formatter.nextNonWhitespaceOrCommentToken(fromIndex: i)?.type != .linebreak {
                    let nextIndex: Int! = formatter.indexOfNextToken(fromIndex: i) { $0.type != .whitespace }
                    let start = formatter.startOfLine(atIndex: i)
                    // align indent with previous value
                    indent = ""
                    for token in formatter.tokens[start ..< nextIndex] {
                        if token.type == .whitespace {
                            indent += token.string
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
            scopeStartLineIndexes.append(lineIndex)
            linewrapStack.append(false)
        } else if token.type != .whitespace {
            if let scope = currentScope() {
                // Handle end of scope
                if token.closesScopeForToken(scope) {
                    if linewrapStack.last == true {
                        indentStack.removeLast()
                    }
                    linewrapStack.removeLast()
                    scopeStartLineIndexes.removeLast()
                    scopeIndexStack.removeLast()
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
                        let start = formatter.startOfLine(atIndex: i)
                        if let nextToken = formatter.nextNonWhitespaceOrCommentOrLinebreakToken(fromIndex: start - 1),
                            nextToken.type == .endOfScope && nextToken.string != "*/" {
                            // Only reduce indent if line begins with a closing scope token
                            let indent = indentStack.last ?? ""
                            i += insertWhitespace(indent, atIndex: start)
                        }
                    }
                    if token.string == "case" {
                        scopeIndexStack.append(i)
                        var indent = (indentStack.last ?? "")
                        if formatter.nextNonWhitespaceOrCommentToken(fromIndex: i)?.type == .linebreak {
                            indent += formatter.options.indent
                        } else {
                            // align indent with previous case value
                            indent += "     "
                        }
                        indentStack.append(indent)
                        indentCounts.append(1)
                        scopeStartLineIndexes.append(lineIndex)
                        linewrapStack.append(false)
                    }
                } else if token.type == .identifier {
                    // Handle #elseif/#else
                    if token.string == "#else" || token.string == "#elseif" {
                        let indent = indentStack[indentStack.count - 2]
                        i += insertWhitespace(indent, atIndex: formatter.startOfLine(atIndex: i))
                    }
                }
            } else if token.type == .error && ["}", "]", ")", ">"].contains(token.string) {
                // Handled over-terminated fragment
                if let prevToken = formatter.tokenAtIndex(i - 1) {
                    if prevToken.type == .whitespace {
                        let prevButOneToken = formatter.tokenAtIndex(i - 2)
                        if prevButOneToken == nil || prevButOneToken!.type == .linebreak {
                            indentStack[0] = prevToken.string
                        }
                    } else if prevToken.type == .linebreak {
                        indentStack[0] = ""
                    }
                }
                return
            }
            // Indent each new line
            if token.type == .linebreak {
                // Detect linewrap
                let nextTokenIndex = formatter.indexOfNextToken(fromIndex: i) { !$0.isWhitespaceOrCommentOrLinebreak }
                let linewrapped = !tokenIsEndOfStatement(lastNonWhitespaceOrLinebreakIndex) ||
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
                    let lastToken = formatter.tokenAtIndex(lastNonWhitespaceOrLinebreakIndex)
                    if formatter.tokenAtIndex(nextTokenIndex ?? -1)?.string != "." ||
                        !(lastToken?.type == .endOfScope && lastToken?.string != "case" &&
                            formatter.previousNonWhitespaceToken(fromIndex:
                                lastNonWhitespaceOrLinebreakIndex)?.type == .linebreak) {
                        indent += formatter.options.indent
                    }
                    indentStack.append(indent)
                }
                // Apply indent
                if formatter.tokenAtIndex(i + 1)?.type != .whitespace {
                    insertWhitespace("", atIndex: i + 1)
                }
                if let nextToken = formatter.tokenAtIndex(i + 2) {
                    switch nextToken.type {
                    case .linebreak:
                        // TODO: Add option to not strip indent from blank lines
                        insertWhitespace("", atIndex: i + 1)
                    case .commentBody:
                        if formatter.options.indentComments {
                            insertWhitespace(indent, atIndex: i + 1)
                        }
                    case .startOfScope:
                        if formatter.options.indentComments || nextToken.string != "/*" {
                            insertWhitespace(indent, atIndex: i + 1)
                        }
                    case .endOfScope:
                        if formatter.options.indentComments || nextToken.string != "*/" {
                            insertWhitespace(indent, atIndex: i + 1)
                        }
                    case .error:
                        break
                    default:
                        insertWhitespace(indent, atIndex: i + 1)
                    }
                }
            }
        }
        // Track token for line wraps
        if !token.isWhitespaceOrComment {
            lastNonWhitespaceIndex = i
            if token.type != .linebreak {
                lastNonWhitespaceOrLinebreakIndex = i
            }
        }
    }
}

/// Implement K&R-style braces, where opening brace appears on the same line as
/// the related function or keyword, and the closing brace is on its own line,
/// except for inline closures where opening and closing brace are on same line.
public func knrBraces(_ formatter: Formatter) {
    formatter.forEachToken("{") { i, token in
        var index = i - 1
        var linebreakIndex: Int?
        while let token = formatter.tokenAtIndex(index) {
            switch token.type {
            case .linebreak:
                linebreakIndex = index
            case .whitespace, .commentBody:
                break
            case .startOfScope:
                if token.string != "/*" && token.string != "//" {
                    fallthrough
                }
            case .endOfScope:
                if token.string != "*/" {
                    fallthrough
                }
            default:
                if let linebreakIndex = linebreakIndex {
                    formatter.removeTokensInRange(Range(linebreakIndex ... i))
                    formatter.insertToken(Token(.whitespace, " "), atIndex: index + 1)
                    formatter.insertToken(Token(.startOfScope, "{"), atIndex: index + 2)
                }
                return
            }
            index -= 1
        }
    }
}

/// Ensure that an `else` statement following `if { ... }` appears on the same line
/// as the closing brace. This has no effect on the `else` part of a `guard` statement
public func elseOnSameLine(_ formatter: Formatter) {
    formatter.forEachToken("else") { i, token in
        var index = i - 1
        var containsLinebreak = false
        while let token = formatter.tokenAtIndex(index) {
            switch token.type {
            case .linebreak:
                containsLinebreak = true
            case .whitespace:
                break
            case .endOfScope:
                if token.string == "}" && containsLinebreak &&
                    formatter.previousNonWhitespaceToken(fromIndex: index)?.type == .linebreak {
                    formatter.replaceTokensInRange(index + 1 ..< i, with: [Token(.whitespace, " ")])
                }
                return
            default:
                return
            }
            index -= 1
        }
    }
}

/// Ensure that the last item in a multi-line array literal is followed by a comma.
/// This is useful for preventing noise in commits when items are added to end of array.
public func trailingCommas(_ formatter: Formatter) {
    // TODO: we don't currently check if [] is a subscript rather than a literal.
    // This should't matter in practice, as nobody splits subscripts onto multiple
    // lines, but ideally we'd check for this just in case
    formatter.forEachToken("]") { i, token in
        if let linebreakIndex = formatter.indexOfPreviousToken(fromIndex: i, matching: {
            return !$0.isWhitespaceOrComment
        }), formatter.tokenAtIndex(linebreakIndex)?.type == .linebreak {
            if let previousTokenIndex = formatter.indexOfPreviousToken(fromIndex: linebreakIndex + 1, matching: {
                return !$0.isWhitespaceOrCommentOrLinebreak
            }), let token = formatter.tokenAtIndex(previousTokenIndex) {
                switch token.string {
                case "[", ":":
                    break // do nothing
                case ",":
                    if !formatter.options.trailingCommas {
                        formatter.removeTokenAtIndex(previousTokenIndex)
                    }
                default:
                    if formatter.options.trailingCommas {
                        formatter.insertToken(Token(.symbol, ","), atIndex: previousTokenIndex + 1)
                    }
                }
            }
        }
    }
}

/// Ensure that TODO, MARK and FIXME comments are followed by a : as required
public func todos(_ formatter: Formatter) {
    formatter.forEachToken(ofType: .commentBody) { i, token in
        let string = token.string
        for tag in ["TODO", "MARK", "FIXME"] {
            if string.hasPrefix(tag) {
                var suffix = string.substring(from: tag.endIndex)
                while suffix.characters.first == " " || suffix.characters.first == ":" {
                    suffix = suffix.substring(from: suffix.characters.index(suffix.startIndex, offsetBy: 1))
                }
                formatter.replaceTokenAtIndex(i, with: Token(.commentBody, tag + ": " + suffix))
                break
            }
        }
    }
}

/// Remove semicolons, except where doing so would change the meaning of the code
public func semicolons(_ formatter: Formatter) {
    formatter.forEachToken(";") { i, token in
        if let nextToken = formatter.nextNonWhitespaceOrCommentOrLinebreakToken(fromIndex: i) {
            let lastToken = formatter.previousNonWhitespaceOrCommentOrLinebreakToken(fromIndex: i)
            if lastToken == nil || nextToken.string == "}" {
                // Safe to remove
                formatter.removeTokenAtIndex(i)
            } else if lastToken?.string == "return" || formatter.scopeAtIndex(i)?.string == "(" {
                // Not safe to remove or replace
            } else if formatter.nextNonWhitespaceOrCommentToken(fromIndex: i)?.type == .linebreak {
                // Safe to remove
                formatter.removeTokenAtIndex(i)
            } else if !formatter.options.allowInlineSemicolons {
                // Replace with a linebreak
                if formatter.tokenAtIndex(i + 1)?.type == .whitespace {
                    formatter.removeTokenAtIndex(i + 1)
                }
                if let indentToken = formatter.indentTokenForLineAtIndex(i) {
                    formatter.insertToken(indentToken, atIndex: i + 1)
                }
                formatter.replaceTokenAtIndex(i, with: Token(.linebreak, formatter.options.linebreak))
            }
        } else {
            // Safe to remove
            formatter.removeTokenAtIndex(i)
        }
    }
}

/// Standardise linebreak characters as whatever is specified in the options (\n by default)
public func linebreaks(_ formatter: Formatter) {
    formatter.forEachToken(ofType: .linebreak) { i, token in
        formatter.replaceTokenAtIndex(i, with: Token(.linebreak, formatter.options.linebreak))
    }
}

/// Standardise the order of property specifiers
public func specifiers(_ formatter: Formatter) {
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
        "prefix", "postfix",
    ]
    let validSpecifiers = Set<String>(order)
    formatter.forEachToken(ofType: .identifier) { i, token in
        if formatter.previousNonWhitespaceToken(fromIndex: i)?.string == "." {
            return
        }
        switch token.string {
        case "let", "var",
             "typealias", "associatedtype",
             "class", "struct", "enum", "protocol", "extension",
             "func", "init", "subscript":
            break
        default:
            return
        }
        var specifiers = [String: [Token]]()
        var index = i - 1
        var specifierIndex = i
        while let token = formatter.tokenAtIndex(index) {
            if !token.isWhitespaceOrCommentOrLinebreak {
                var key = token.string
                if token.type != .identifier || !validSpecifiers.contains(key) {
                    if token.string == ")" && formatter
                        .previousNonWhitespaceOrCommentOrLinebreakToken(fromIndex: index)?.string == "set" {
                        // Skip tokens for entire private(set) expression
                        loop: while let token = formatter.tokenAtIndex(index) {
                            switch token.string {
                            case "private", "fileprivate", "internal", "public":
                                key = token.string + "(set)"
                                break loop
                            default:
                                break
                            }
                            index -= 1
                        }
                    } else {
                        // Not a specifier
                        break
                    }
                }
                specifiers[key] = [Token](formatter.tokens[index ..< specifierIndex])
                specifierIndex = index
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
        formatter.replaceTokensInRange(specifierIndex ..< i, with: sortedSpecifiers)
    }
}

/// Normalize the use of void in closure arguments and return values
public func void(_ formatter: Formatter) {
    formatter.forEachToken("Void", ofType: .identifier) { i, token in
        if let prevIndex = formatter.indexOfPreviousToken(fromIndex: i, matching: { !$0.isWhitespaceOrLinebreak }),
            let prevToken = formatter.tokenAtIndex(prevIndex), prevToken.string == "(",
            let nextIndex = formatter.indexOfNextToken(fromIndex: i, matching: { !$0.isWhitespaceOrLinebreak }),
            let nextToken = formatter.tokenAtIndex(nextIndex), nextToken.string == ")" {
            if let nextToken = formatter.nextNonWhitespaceOrCommentOrLinebreakToken(fromIndex: nextIndex),
                nextToken.type == .symbol, nextToken.string == "->" {
                // Remove Void
                formatter.removeTokensInRange(prevIndex + 1 ..< nextIndex)
            } else if formatter.options.useVoid {
                // Strip parens
                formatter.removeTokensInRange(i + 1 ..< nextIndex + 1)
                formatter.removeTokensInRange(prevIndex ..< i)
            } else {
                // Remove Void
                formatter.removeTokensInRange(prevIndex + 1 ..< nextIndex)
            }
        } else if !formatter.options.useVoid ||
            formatter.nextNonWhitespaceOrCommentOrLinebreakToken(fromIndex: i)?.string == "->" {
            if let prevToken = formatter.previousNonWhitespaceOrCommentOrLinebreakToken(fromIndex: i),
                prevToken.string == "." || prevToken.string == "typealias" {
                return
            }
            // Convert to parens
            formatter.replaceTokenAtIndex(i, with: Token(.endOfScope, ")"))
            formatter.insertToken(Token(.startOfScope, "("), atIndex: i)
        }
    }
    if formatter.options.useVoid {
        formatter.forEachToken("(", ofType: .startOfScope) { i, token in
            if let prevIndex = formatter.indexOfPreviousToken(fromIndex: i, matching: { !$0.isWhitespaceOrCommentOrLinebreak }),
                let prevToken = formatter.tokenAtIndex(prevIndex), prevToken.string == "->",
                let nextIndex = formatter.indexOfNextToken(fromIndex: i, matching: { !$0.isWhitespaceOrLinebreak }),
                let nextToken = formatter.tokenAtIndex(nextIndex), nextToken.string == ")",
                formatter.nextNonWhitespaceOrCommentOrLinebreakToken(fromIndex: nextIndex)?.string != "->" {
                // Replace with Void
                formatter.replaceTokensInRange(i ..< nextIndex + 1, with: [Token(.identifier, "Void")])
            }
        }
    }
}

public let defaultRules: [FormatRule] = [
    linebreaks,
    semicolons,
    specifiers,
    void,
    knrBraces,
    elseOnSameLine,
    indent,
    spaceAroundParens,
    spaceInsideParens,
    spaceAroundBrackets,
    spaceInsideBrackets,
    spaceAroundBraces,
    spaceInsideBraces,
    spaceAroundGenerics,
    spaceInsideGenerics,
    spaceAroundOperators,
    spaceAroundComments,
    spaceInsideComments,
    consecutiveSpaces,
    blankLinesAtEndOfScope,
    blankLinesBetweenScopes,
    consecutiveBlankLines,
    trailingWhitespace,
    linebreakAtEndOfFile,
    trailingCommas,
    todos,
    ranges,
]
