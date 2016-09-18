//
//  Rules.swift
//  SwiftFormat
//
//  Version 0.9.6
//
//  Created by Nick Lockwood on 12/08/2016.
//  Copyright 2016 Charcoal Design
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
public func spaceAroundParens(formatter: Formatter) {

    func spaceAfter(identifier: String, index: Int) -> Bool {
        switch identifier {
        case "internal",
            "case",
            "for",
            "guard",
            "if",
            "in",
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

    formatter.forEachToken("(") { i, token in
        guard let previousToken = formatter.tokenAtIndex(i - 1) else {
            return
        }
        if previousToken.type == .Identifier && spaceAfter(previousToken.string, index: i - 1) {
            formatter.insertToken(Token(.Whitespace, " "), atIndex: i)
        } else if previousToken.type == .Whitespace {
            if let token = formatter.tokenAtIndex(i - 2) {
                if (token.type == .EndOfScope && ["]", "}", ")", ">"].contains(token.string)) ||
                    (token.type == .Identifier && !spaceAfter(token.string, index: i - 2)) {
                    formatter.removeTokenAtIndex(i - 1)
                }
            }
        }
    }
    formatter.forEachToken(")") { i, token in
        guard let nextToken = formatter.tokenAtIndex(i + 1) else {
            return
        }
        if nextToken.type == .Identifier || nextToken.string == "{" {
            formatter.insertToken(Token(.Whitespace, " "), atIndex: i + 1)
        } else if nextToken.type == .Whitespace && formatter.tokenAtIndex(i + 2)?.string == "[" {
            formatter.removeTokenAtIndex(i + 1)
        }
    }
}

/// Remove whitespace immediately inside parens
public func spaceInsideParens(formatter: Formatter) {
    formatter.forEachToken("(") { i, token in
        if formatter.tokenAtIndex(i + 1)?.type == .Whitespace {
            formatter.removeTokenAtIndex(i + 1)
        }
    }
    formatter.forEachToken(")") { i, token in
        if formatter.tokenAtIndex(i - 1)?.type == .Whitespace &&
            formatter.tokenAtIndex(i - 2)?.type != .Linebreak {
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
public func spaceAroundBrackets(formatter: Formatter) {

    func spaceAfter(identifier: String, index: Int) -> Bool {
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
        if previousToken.type == .Identifier && spaceAfter(previousToken.string, index: i - 1) {
            formatter.insertToken(Token(.Whitespace, " "), atIndex: i)
        } else if previousToken.type == .Whitespace {
            if let token = formatter.tokenAtIndex(i - 2) {
                if (token.type == .EndOfScope && ["]", "}", ")"].contains(token.string)) ||
                    (token.type == .Identifier && !spaceAfter(token.string, index: i - 2)) {
                    formatter.removeTokenAtIndex(i - 1)
                }
            }
        }
    }
    formatter.forEachToken("]") { i, token in
        guard let nextToken = formatter.tokenAtIndex(i + 1) else {
            return
        }
        if nextToken.type == .Identifier || nextToken.string == "{" {
            formatter.insertToken(Token(.Whitespace, " "), atIndex: i + 1)
        } else if nextToken.type == .Whitespace && formatter.tokenAtIndex(i + 2)?.string == "[" {
            formatter.removeTokenAtIndex(i + 1)
        }
    }
}

/// Remove whitespace immediately inside square brackets
public func spaceInsideBrackets(formatter: Formatter) {
    formatter.forEachToken("[") { i, token in
        if formatter.tokenAtIndex(i + 1)?.type == .Whitespace {
            formatter.removeTokenAtIndex(i + 1)
        }
    }
    formatter.forEachToken("]") { i, token in
        if formatter.tokenAtIndex(i - 1)?.type == .Whitespace &&
            formatter.tokenAtIndex(i - 2)?.type != .Linebreak {
            formatter.removeTokenAtIndex(i - 1)
        }
    }
}

/// Ensure that there is space between an opening brace and the preceding
/// identifier, and between a closing brace and the following identifier.
public func spaceAroundBraces(formatter: Formatter) {
    formatter.forEachToken("{") { i, token in
        if let previousToken = formatter.tokenAtIndex(i - 1) {
            switch previousToken.type {
            case .Whitespace, .Linebreak:
                break
            case .StartOfScope:
                if previousToken.string == "\"" {
                    fallthrough
                }
            default:
                formatter.insertToken(Token(.Whitespace, " "), atIndex: i)
            }
        }
    }
    formatter.forEachToken("}") { i, token in
        if formatter.tokenAtIndex(i + 1)?.type == .Identifier {
            formatter.insertToken(Token(.Whitespace, " "), atIndex: i + 1)
        }
    }
}

/// Ensure that there is space immediately inside braces
public func spaceInsideBraces(formatter: Formatter) {
    formatter.forEachToken("{") { i, token in
        if let nextToken = formatter.tokenAtIndex(i + 1) {
            if nextToken.type == .Whitespace {
                if formatter.tokenAtIndex(i + 2)?.string == "}" {
                    formatter.removeTokenAtIndex(i + 1)
                }
            } else if nextToken.type != .Linebreak && nextToken.string != "}" {
                formatter.insertToken(Token(.Whitespace, " "), atIndex: i + 1)
            }
        }
    }
    formatter.forEachToken("}") { i, token in
        if let previousToken = formatter.tokenAtIndex(i - 1) where
            previousToken.type != .Whitespace && previousToken.type != .Linebreak && previousToken.string != "{" {
            formatter.insertToken(Token(.Whitespace, " "), atIndex: i)
        }
    }
}

/// Ensure there is no space between an opening chevron and the preceding identifier
public func spaceAroundGenerics(formatter: Formatter) {
    formatter.forEachToken("<", ofType: .StartOfScope) { i, token in
        if formatter.tokenAtIndex(i - 1)?.type == .Whitespace &&
            formatter.tokenAtIndex(i - 2)?.type == .Identifier {
            formatter.removeTokenAtIndex(i - 1)
        }
    }
}

/// Remove whitespace immediately inside chevrons
public func spaceInsideGenerics(formatter: Formatter) {
    formatter.forEachToken("<", ofType: .StartOfScope) { i, token in
        if formatter.tokenAtIndex(i + 1)?.type == .Whitespace {
            formatter.removeTokenAtIndex(i + 1)
        }
    }
    formatter.forEachToken(">", ofType: .EndOfScope) { i, token in
        if formatter.tokenAtIndex(i - 1)?.type == .Whitespace &&
            formatter.tokenAtIndex(i - 2)?.type != .Linebreak {
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
public func spaceAroundOperators(formatter: Formatter) {

    func isLvalue(token: Token) -> Bool {
        switch token.type {
        case .Identifier, .Number, .EndOfScope:
            return true
        default:
            return false
        }
    }

    func isRvalue(token: Token) -> Bool {
        switch token.type {
        case .Identifier, .Number, .StartOfScope:
            return true
        default:
            return false
        }
    }

    func isUnwrapOperatorSequence(token: Token) -> Bool {
        for c in token.string.characters {
            if c != "?" && c != "!" {
                return false
            }
        }
        return true
    }

    func spaceAfter(identifier: String, index: Int) -> Bool {
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
        case .Operator:
            if [":", ",", ";"].contains(token.string) {
                if let nextToken = formatter.tokenAtIndex(i + 1) {
                    switch nextToken.type {
                    case .Whitespace, .Linebreak, .EndOfScope:
                        break
                    case .Identifier:
                        if token.string == ":" {
                            if formatter.tokenAtIndex(i + 2)?.string == ":" {
                                // It's a selector
                                break
                            }
                        }
                        fallthrough
                    default:
                        // Ensure there is a space after the token
                        formatter.insertToken(Token(.Whitespace, " "), atIndex: i + 1)
                    }
                }
                if token.string == ":" && scopeStack.last?.string == "?" {
                    // Treat the next : after a ? as closing the ternary scope
                    scopeStack.popLast()
                    // Ensure there is a space before the :
                    if let previousToken = formatter.tokenAtIndex(i - 1) {
                        if previousToken.type != .Whitespace && previousToken.type != .Linebreak {
                            formatter.insertToken(Token(.Whitespace, " "), atIndex: i)
                        }
                    }
                } else if formatter.tokenAtIndex(i - 1)?.type == .Whitespace &&
                    formatter.tokenAtIndex(i - 2)?.type != .Linebreak {
                    // Remove space before the token
                    formatter.removeTokenAtIndex(i - 1)
                }
            } else if token.string == "?" {
                if let previousToken = formatter.tokenAtIndex(i - 1), nextToken = formatter.tokenAtIndex(i + 1) {
                    if nextToken.type == .Whitespace || nextToken.type == .Linebreak {
                        if previousToken.type == .Whitespace || previousToken.type == .Linebreak {
                            // ? is a ternary operator, treat it as the start of a scope
                            scopeStack.append(token)
                        }
                    } else if previousToken.type == .Identifier && ["as", "try"].contains(previousToken.string) {
                        formatter.insertToken(Token(.Whitespace, " "), atIndex: i + 1)
                    }
                }
            } else if token.string == "!" {
                if let previousToken = formatter.tokenAtIndex(i - 1), nextToken = formatter.tokenAtIndex(i + 1) {
                    if nextToken.type != .Whitespace && nextToken.type != .Linebreak &&
                        previousToken.type == .Identifier && ["as", "try"].contains(previousToken.string) {
                        formatter.insertToken(Token(.Whitespace, " "), atIndex: i + 1)
                    }
                }
            } else if token.string == "." {
                if formatter.tokenAtIndex(i + 1)?.type == .Whitespace {
                    formatter.removeTokenAtIndex(i + 1)
                }
                if let previousToken = formatter.tokenAtIndex(i - 1) {
                    let previousTokenWasWhitespace = (previousToken.type == .Whitespace)
                    let previousNonWhitespaceTokenIndex = i - (previousTokenWasWhitespace ? 2 : 1)
                    if let previousNonWhitespaceToken = formatter.tokenAtIndex(previousNonWhitespaceTokenIndex) {
                        if previousNonWhitespaceToken.type != .Linebreak &&
                            previousNonWhitespaceToken.string != "{" &&
                            (previousNonWhitespaceToken.type != .Operator ||
                            (previousNonWhitespaceToken.string == "?" && scopeStack.last?.string != "?") ||
                            (previousNonWhitespaceToken.string != "?" &&
                            formatter.tokenAtIndex(previousNonWhitespaceTokenIndex - 1)?.type != .Whitespace &&
                            isUnwrapOperatorSequence(previousNonWhitespaceToken))) &&
                            !spaceAfter(previousNonWhitespaceToken.string, index: previousNonWhitespaceTokenIndex) {
                            if previousTokenWasWhitespace {
                                formatter.removeTokenAtIndex(i - 1)
                            }
                        } else if !previousTokenWasWhitespace {
                            formatter.insertToken(Token(.Whitespace, " "), atIndex: i)
                        }
                    }
                }
            } else if token.string == "->" {
                if let nextToken = formatter.tokenAtIndex(i + 1) {
                    if nextToken.type != .Whitespace && nextToken.type != .Linebreak {
                        formatter.insertToken(Token(.Whitespace, " "), atIndex: i + 1)
                    }
                }
                if let previousToken = formatter.tokenAtIndex(i - 1) {
                    if previousToken.type != .Whitespace && previousToken.type != .Linebreak {
                        formatter.insertToken(Token(.Whitespace, " "), atIndex: i)
                    }
                }
            } else if token.string != "..." && token.string != "..<" {
                if let previousToken = formatter.tokenAtIndex(i - 1) where isLvalue(previousToken) {
                    if let nextToken = formatter.tokenAtIndex(i + 1) where isRvalue(nextToken) {
                        // Insert space before and after the infix token
                        formatter.insertToken(Token(.Whitespace, " "), atIndex: i + 1)
                        formatter.insertToken(Token(.Whitespace, " "), atIndex: i)
                    }
                }
            }
        case .StartOfScope:
            scopeStack.append(token)
        case .EndOfScope:
            scopeStack.popLast()
        default: break
        }
    }
}

/// Add space around comments, except at the start or end of a line
public func spaceAroundComments(formatter: Formatter) {
    formatter.forEachToken(ofType: .StartOfScope) { i, token in
        guard let previousToken = formatter.tokenAtIndex(i - 1) where
            (token.string == "/*" || token.string == "//") else { return }
        if !previousToken.isWhitespaceOrLinebreak {
            formatter.insertToken(Token(.Whitespace, " "), atIndex: i)
        }
    }
    formatter.forEachToken("*/") { i, token in
        guard let nextToken = formatter.tokenAtIndex(i + 1) else { return }
        if !nextToken.isWhitespaceOrLinebreak {
            formatter.insertToken(Token(.Whitespace, " "), atIndex: i + 1)
        }
    }
}

/// Add space inside comments, taking care not to mangle headerdoc or
/// carefully preformatted comments, such as star boxes, etc.
public func spaceInsideComments(formatter: Formatter) {
    formatter.forEachToken("/*") { i, token in
        guard let nextToken = formatter.tokenAtIndex(i + 1) else { return }
        if !nextToken.isWhitespaceOrLinebreak {
            let string = nextToken.string
            if string.hasPrefix("*") || string.hasPrefix("!") || string.hasPrefix(":") {
                if !string.hasPrefix("**") && !string.hasPrefix("* ") &&
                    !string.hasPrefix("*\t") && !string.hasPrefix("*/") {
                    let string = String(string.characters.first!) + " " +
                        string.substringFromIndex(string.startIndex.advancedBy(1))
                    formatter.replaceTokenAtIndex(i + 1, with: Token(.CommentBody, string))
                }
            } else {
                formatter.insertToken(Token(.Whitespace, " "), atIndex: i + 1)
            }
        }
    }
    formatter.forEachToken("//") { i, token in
        guard let nextToken = formatter.tokenAtIndex(i + 1) else { return }
        if !nextToken.isWhitespaceOrLinebreak {
            let string = nextToken.string
            if string.hasPrefix("/") || string.hasPrefix("!") || string.hasPrefix(":") {
                if !string.hasPrefix("/ ") && !string.hasPrefix("/\t") {
                    let string = String(string.characters.first!) + " " +
                        string.substringFromIndex(string.startIndex.advancedBy(1))
                    formatter.replaceTokenAtIndex(i + 1, with: Token(.CommentBody, string))
                }
            } else {
                formatter.insertToken(Token(.Whitespace, " "), atIndex: i + 1)
            }
        }
    }
    formatter.forEachToken("*/") { i, token in
        guard let previousToken = formatter.tokenAtIndex(i - 1) else { return }
        if !previousToken.isWhitespaceOrLinebreak && !previousToken.string.hasSuffix("*") {
            formatter.insertToken(Token(.Whitespace, " "), atIndex: i)
        }
    }
}

/// Add or removes the space around range operators
public func ranges(formatter: Formatter) {
    formatter.forEachToken(ofType: .Operator) { i, token in
        if token.string == "..." || token.string == "..<" {
            if !formatter.options.spaceAroundRangeOperators {
                if formatter.tokenAtIndex(i + 1)?.type == .Whitespace {
                    formatter.removeTokenAtIndex(i + 1)
                }
                if formatter.tokenAtIndex(i - 1)?.type == .Whitespace {
                    formatter.removeTokenAtIndex(i - 1)
                }
            } else if let nextToken = formatter.nextNonWhitespaceOrCommentOrLinebreakToken(fromIndex: i) {
                if nextToken.string != ")" && nextToken.string != "," {
                    if formatter.tokenAtIndex(i + 1)?.isWhitespaceOrLinebreak == false {
                        formatter.insertToken(Token(.Whitespace, " "), atIndex: i + 1)
                    }
                    if formatter.tokenAtIndex(i - 1)?.isWhitespaceOrLinebreak == false {
                        formatter.insertToken(Token(.Whitespace, " "), atIndex: i)
                    }
                }
            }
        }
    }
}

/// Collapse all consecutive whitespace characters to a single space, except at
/// the start of a line or inside a comment or string, as these have no semantic
/// meaning and lead to noise in commits.
public func consecutiveSpaces(formatter: Formatter) {
    formatter.forEachToken(ofType: .Whitespace) { i, token in
        if let previousToken = formatter.tokenAtIndex(i - 1) where previousToken.type != .Linebreak {
            if token.string == "" {
                formatter.removeTokenAtIndex(i)
            } else if token.string != " " {
                let scope = formatter.scopeAtIndex(i)
                if scope?.string != "/*" && scope?.string != "//" {
                    formatter.replaceTokenAtIndex(i, with: Token(.Whitespace, " "))
                }
            }
        }
    }
}

/// Remove trailing whitespace from the end of lines, as it has no semantic
/// meaning and leads to noise in commits.
public func trailingWhitespace(formatter: Formatter) {
    formatter.forEachToken(ofType: .Linebreak) { i, token in
        if formatter.tokenAtIndex(i - 1)?.type == .Whitespace {
            formatter.removeTokenAtIndex(i - 1)
        }
    }
    if formatter.tokens.last?.type == .Whitespace {
        formatter.removeLastToken()
    }
}

/// Collapse all consecutive blank lines into a single blank line
public func consecutiveBlankLines(formatter: Formatter) {
    var linebreakCount = 0
    var lastTokenType = TokenType.Whitespace
    formatter.forEachToken { i, token in
        if token.type == .Linebreak {
            linebreakCount += 1
            if linebreakCount > 2 {
                formatter.removeTokenAtIndex(i)
                if lastTokenType == .Whitespace {
                    formatter.removeTokenAtIndex(i - 1)
                    lastTokenType = .Linebreak
                }
                linebreakCount -= 1
                return // continue
            }
        } else if token.type != .Whitespace {
            linebreakCount = 0
        }
        lastTokenType = token.type
    }
    if linebreakCount > 1 {
        if lastTokenType == .Whitespace {
            formatter.removeLastToken()
        }
        formatter.removeLastToken()
    }
}

/// Remove blank lines immediately before a closing brace, bracket, paren or chevron,
/// unless it's followed by more code on the same line (e.g. } else { )
public func blankLinesAtEndOfScope(formatter: Formatter) {
    formatter.forEachToken(ofType: .EndOfScope) { i, token in
        guard ["}", ")", "]", ">"].contains(token.string) else { return }
        if let nw = formatter.nextNonWhitespaceOrCommentToken(fromIndex: i) {
            // If there is extra code after the closing scope on the same line, ignore it
            guard nw.type == .Linebreak else { return }
        }
        // Find previous non-whitespace token
        var index = i - 1
        var indexOfFirstLineBreak: Int?
        var indexOfLastLineBreak: Int?
        loop: while let token = formatter.tokenAtIndex(index) {
            switch token.type {
            case .Linebreak:
                indexOfFirstLineBreak = index
                if indexOfLastLineBreak == nil {
                    indexOfLastLineBreak = index
                }
            case .Whitespace:
                break
            default:
                break loop
            }
            index -= 1
        }
        if let indexOfFirstLineBreak = indexOfFirstLineBreak, indexOfLastLineBreak = indexOfLastLineBreak {
            formatter.removeTokensInRange(indexOfFirstLineBreak ..< indexOfLastLineBreak)
            return
        }
    }
}

/// Adds a blank line immediately before a class, struct, enum, extension, protocol or function.
/// If the scope is immediately preceded by a comment, the line will be inserted before that instead.
public func blankLinesBetweenScopes(formatter: Formatter) {
    formatter.forEachToken(ofType: .Identifier) { i, token in
        if formatter.previousNonWhitespaceToken(fromIndex: i)?.string == "." {
            return
        }
        switch token.string {
        case "struct", "enum", "protocol", "extension":
            break
        case "class":
            // Ignore class var/let/func
            if let nextToken = formatter.nextNonWhitespaceOrCommentOrLinebreakToken(fromIndex: i)
                where nextToken.type == .Identifier {
                switch nextToken.string {
                case "var", "let", "func",
                    "private", "fileprivate", "public", "internal", "open",
                    "final", "required", "override", "convenience",
                    "lazy", "dynamic", "static":
                    return
                default:
                    break
                }
            }
        case "init":
            // Ignore self.init() / super.init() calls
            if formatter.previousNonWhitespaceToken(fromIndex: i)?.string == "." {
                return
            }
            fallthrough
        case "func", "subscript", "init":
            // Ignore function prototypes inside protocols
            if let startOfScope = formatter.indexOfPreviousToken(fromIndex: i, matching: {
                return $0.type == .StartOfScope && $0.string == "{" }) {
                if formatter.previousToken(fromIndex: startOfScope, matching: {
                    if $0.type == .Identifier && $0.string == "protocol" { return true }
                    return $0.type == .EndOfScope && $0.string == "}"
                })?.string == "protocol" {
                    return
                }
            }
        default:
            return
        }
        // Skip specifiers
        var index = i - 1
        var reachedStart = false
        var linebreakCount = 0
        var lastLinebreakIndex = 0
        while !reachedStart {
            while let token = formatter.tokenAtIndex(index) {
                if token.type == .Linebreak {
                    linebreakCount = 1
                    lastLinebreakIndex = index
                    index -= 1
                    break
                }
                index -= 1
            }
            loop: while let token = formatter.tokenAtIndex(index) {
                switch token.type {
                case .Whitespace:
                    break
                case .Linebreak:
                    linebreakCount += 1
                    lastLinebreakIndex = index
                case .Identifier:
                    switch token.string {
                    case "private", "fileprivate", "internal", "public", "open",
                        "final", "required", "override", "convenience":
                        break
                    default:
                        if !token.string.hasPrefix("@") {
                            reachedStart = true
                            break loop
                        }
                    }
                    linebreakCount = 0
                case .CommentBody:
                    if linebreakCount > 1 {
                        break loop
                    }
                    linebreakCount = 0
                case .EndOfScope:
                    if token.string == ")" {
                        // Handle @available(...), @objc(...), etc
                        if let openParenIndex = formatter.indexOfPreviousToken(fromIndex: index, matching: {
                            return $0.type == .StartOfScope && $0.string == "("
                        }), nonWSIndex = formatter.indexOfPreviousToken(fromIndex: openParenIndex, matching: {
                            return !$0.isWhitespaceOrCommentOrLinebreak
                        }) where formatter.tokenAtIndex(nonWSIndex)?.string.hasPrefix("@") == true {
                            linebreakCount = 0
                            index = nonWSIndex
                            break
                        }
                        reachedStart = true
                        break loop
                    }
                    if token.string == "*/" {
                        if linebreakCount > 1 {
                            break loop
                        }
                        linebreakCount = 0
                        break
                    }
                    reachedStart = true
                    break loop
                case .StartOfScope:
                    if token.string == "/*" || token.string == "//" {
                        linebreakCount = 0
                        break
                    }
                    reachedStart = true
                    break loop
                default:
                    reachedStart = true
                    break loop
                }
                index -= 1
            }
            if index < 0 {
                return // we've reached the start of the file
            }
        }
        if linebreakCount < 2 {
            // Insert blank line
            formatter.insertToken(Token(.Linebreak, formatter.options.linebreak), atIndex: lastLinebreakIndex)
        }
    }
}

/// Always end file with a linebreak, to avoid incompatibility with certain unix tools:
/// http://stackoverflow.com/questions/2287967/why-is-it-recommended-to-have-empty-line-in-the-end-of-file
public func linebreakAtEndOfFile(formatter: Formatter) {
    var token = formatter.tokens.last
    if token?.type == .Whitespace {
        token = formatter.tokenAtIndex(formatter.tokens.count - 2)
    }
    if token?.type != .Linebreak {
        formatter.insertToken(Token(.Linebreak, formatter.options.linebreak), atIndex: formatter.tokens.count)
    }
}

/// Indent code according to standard scope indenting rules.
/// The type (tab or space) and level (2 spaces, 4 spaces, etc.) of the
/// indenting can be configured with the `options` parameter of the formatter.
public func indent(formatter: Formatter) {
    var scopeIndexStack: [Int] = []
    var scopeStartLineIndexes: [Int] = []
    var lastNonWhitespaceOrLinebreakIndex = -1
    var lastNonWhitespaceIndex = -1
    var indentStack = [""]
    var indentCounts = [1]
    var lineIndex = 0
    var linewrapped = false

    func insertWhitespace(whitespace: String, atIndex index: Int) -> Int {
        if formatter.tokenAtIndex(index)?.type == .Whitespace {
            formatter.replaceTokenAtIndex(index, with: Token(.Whitespace, whitespace))
            return 0 // Inserted 0 tokens
        }
        formatter.insertToken(Token(.Whitespace, whitespace), atIndex: index)
        return 1 // Inserted 1 token
    }

    func currentScope() -> Token? {
        if let scopeIndex = scopeIndexStack.last {
            return formatter.tokens[scopeIndex]
        }
        return nil
    }

    func tokenIsEndOfStatement(i: Int) -> Bool {
        if let token = formatter.tokenAtIndex(i) {
            switch token.type {
            case .Identifier, .EndOfScope:
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
                    "case",
                    "default",
                    "for",
                    "guard",
                    "if",
                    "switch",
                    "where",
                    "while",
                    "as",
                    "catch",
                    "is",
                    "super",
                    "throw",
                    "try":
                    return formatter.previousNonWhitespaceToken(fromIndex: i)?.string == "."
                default:
                    return true
                }
            case .Operator:
                if token.string == "." {
                    return false
                }
                if token.string == "," {
                    // For arrays or argument lists, we already indent
                    return ["[", "("].contains(currentScope()?.string ?? "")
                }
                if let previousToken = formatter.tokenAtIndex(i - 1) {
                    if previousToken.string == "as" || previousToken.string == "try" {
                        return false
                    }
                    if previousToken.isWhitespaceOrCommentOrLinebreak {
                        return formatter.previousNonWhitespaceOrCommentOrLinebreakToken(fromIndex: i)?.string == "="
                    }
                }
            default:
                return true
            }
        }
        return true
    }

    func tokenIsStartOfStatement(i: Int) -> Bool {
        if let token = formatter.tokenAtIndex(i) {
            switch token.type {
            case .Identifier:
                // TODO: handle "in"
                switch token.string {
                case "as",
                    "dynamicType",
                    "false",
                    "is",
                    "nil",
                    "rethrows",
                    "throws",
                    "true",
                    "where":
                    return false
                case "else":
                    if let token = formatter.tokenAtIndex(lastNonWhitespaceOrLinebreakIndex) {
                        return token.string == "}"
                    }
                    return false
                default:
                    return true
                }
            case .Operator:
                if token.string == "." {
                    return false
                }
                if token.string == "," {
                    // For arrays or argument lists, we already indent
                    return ["[", "("].contains(currentScope()?.string ?? "")
                }
                if let nextToken = formatter.tokenAtIndex(i + 1) where
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

    insertWhitespace("", atIndex: 0)
    formatter.forEachToken { i, token in
        var i = i
        if token.type == .StartOfScope {
            // Handle start of scope
            scopeIndexStack.append(i)
            var indent = indentStack.last ?? ""
            if lineIndex > scopeStartLineIndexes.last ?? -1 {
                switch token.string {
                case "/*":
                    // Comments only indent one space
                    indent += " "
                default:
                    indent += formatter.options.indent
                }
                indentStack.append(indent)
                indentCounts.append(1)
            } else {
                indentCounts[indentCounts.count - 1] += 1
            }
            scopeStartLineIndexes.append(lineIndex)
        } else if token.type != .Whitespace {
            if let scopeIndex = scopeIndexStack.last, scope = formatter.tokenAtIndex(scopeIndex) {
                // Handle end of scope
                if token.closesScopeForToken(scope) {
                    scopeStartLineIndexes.popLast()
                    scopeIndexStack.popLast()
                    let indentCount = indentCounts.last! - 1
                    if indentCount == 0 {
                        indentStack.popLast()
                        indentCounts.popLast()
                    } else {
                        indentCounts[indentCounts.count - 1] = indentCount
                    }
                    if lineIndex > scopeStartLineIndexes.last ?? -1 {
                        // If indentCount > 0, drop back to previous indent level
                        if indentCount > 0 {
                            indentStack.popLast()
                            indentStack.append(indentStack.last ?? "")
                        }
                        // Check if line on which scope ends should be unindented
                        let start = formatter.startOfLine(atIndex: i)
                        if let nextToken = formatter.nextNonWhitespaceOrCommentOrLinebreakToken(fromIndex: start - 1)
                            where nextToken.type == .EndOfScope && nextToken.string != "*/" {
                            // Only reduce indent if line begins with a closing scope token
                            let indent = indentStack.last ?? ""
                            i += insertWhitespace(indent, atIndex: start)
                        }
                    }
                } else if token.type == .Identifier {
                    // Handle #elseif/#else
                    if token.string == "#else" || token.string == "#elseif" {
                        let indent = indentStack[indentStack.count - 2]
                        i += insertWhitespace(indent, atIndex: formatter.startOfLine(atIndex: i))
                    }
                }
            }
            // Indent each new line
            if token.type == .Linebreak {
                var indent = indentStack.last ?? ""
                linewrapped = !tokenIsEndOfStatement(lastNonWhitespaceOrLinebreakIndex)
                if linewrapped && lineIndex == scopeStartLineIndexes.last {
                    indent = indentStack.count > 1 ? indentStack[indentStack.count - 2] : ""
                    scopeStartLineIndexes[scopeStartLineIndexes.count - 1] += 1
                }
                lineIndex += 1
                insertWhitespace("", atIndex: i + 1)
                // Only indent if line isn't blank
                if let nextToken = formatter.tokenAtIndex(i + 2) where nextToken.type != .Linebreak {
                    indent += (linewrapped ? formatter.options.indent : "")
                    insertWhitespace(indent, atIndex: i + 1)
                }
            }
        }
        // Track token for line wraps
        if !token.isWhitespaceOrComment {
            if !linewrapped && formatter.tokenAtIndex(lastNonWhitespaceIndex)?.type == .Linebreak &&
                !tokenIsStartOfStatement(i) {
                linewrapped = true
                var indent = indentStack.last ?? ""
                if lineIndex - 1 == scopeStartLineIndexes.last {
                    indent = indentStack.count > 1 ? indentStack[indentStack.count - 2] : ""
                    scopeStartLineIndexes[scopeStartLineIndexes.count - 1] += 1
                }
                indent += (linewrapped ? formatter.options.indent : "")
                i += insertWhitespace(indent, atIndex: formatter.startOfLine(atIndex: i))
            }
            lastNonWhitespaceIndex = i
            if token.type != .Linebreak {
                lastNonWhitespaceOrLinebreakIndex = i
            }
        }
    }
}

/// Implement K&R-style braces, where opening brace appears on the same line as
/// the related function or keyword, and the closing brace is on its own line,
/// except for inline closures where opening and closing brace are on same line.
public func knrBraces(formatter: Formatter) {
    formatter.forEachToken("{") { i, token in
        var index = i - 1
        var linebreakIndex: Int?
        while let token = formatter.tokenAtIndex(index) {
            switch token.type {
            case .Linebreak:
                linebreakIndex = index
            case .Whitespace, .CommentBody:
                break
            case .StartOfScope:
                if token.string != "/*" && token.string != "//" {
                    fallthrough
                }
            case .EndOfScope:
                if token.string != "*/" {
                    fallthrough
                }
            default:
                if let linebreakIndex = linebreakIndex {
                    formatter.removeTokensInRange(linebreakIndex ... i)
                    formatter.insertToken(Token(.Whitespace, " "), atIndex: index + 1)
                    formatter.insertToken(Token(.StartOfScope, "{"), atIndex: index + 2)
                }
                return
            }
            index -= 1
        }
    }
}

/// Ensure that an `else` statement following `if { ... }` appears on the same line
/// as the closing brace. This has no effect on the `else` part of a `guard` statement
public func elseOnSameLine(formatter: Formatter) {
    formatter.forEachToken("else") { i, token in
        var index = i - 1
        var containsLinebreak = false
        while let token = formatter.tokenAtIndex(index) {
            switch token.type {
            case .Linebreak:
                containsLinebreak = true
            case .Whitespace:
                break
            case .EndOfScope:
                if token.string == "}" && containsLinebreak {
                    formatter.replaceTokensInRange(index + 1 ..< i, with: [Token(.Whitespace, " ")])
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
public func trailingCommas(formatter: Formatter) {
    // TODO: we don't currently check if [] is a subscript rather than a literal.
    // This should't matter in practice, as nobody splits subscripts onto multiple
    // lines, but ideally we'd check for this just in case
    formatter.forEachToken("]") { i, token in
        if let linebreakIndex = formatter.indexOfPreviousToken(fromIndex: i, matching: {
            return !$0.isWhitespaceOrComment
        }) where formatter.tokenAtIndex(linebreakIndex)?.type == .Linebreak {
            if let previousTokenIndex = formatter.indexOfPreviousToken(fromIndex: linebreakIndex + 1, matching: {
                return !$0.isWhitespaceOrCommentOrLinebreak
            }), token = formatter.tokenAtIndex(previousTokenIndex) where token.string != "," {
                formatter.insertToken(Token(.Operator, ","), atIndex: previousTokenIndex + 1)
            }
        }
    }
}

/// Ensure that TODO, MARK and FIXME comments are followed by a : as required
public func todos(formatter: Formatter) {
    formatter.forEachToken(ofType: .CommentBody) { i, token in
        let string = token.string
        for tag in ["TODO", "MARK", "FIXME"] {
            if string.hasPrefix(tag) {
                var suffix = string.substringFromIndex(tag.endIndex)
                while suffix.characters.first == " " || suffix.characters.first == ":" {
                    suffix = suffix.substringFromIndex(suffix.startIndex.advancedBy(1))
                }
                formatter.replaceTokenAtIndex(i, with: Token(.CommentBody, tag + ": " + suffix))
                break
            }
        }
    }
}

/// Remove semicolons, except where doing so would change the meaning of the code
public func semicolons(formatter: Formatter) {
    formatter.forEachToken(";") { i, token in
        if let nextToken = formatter.nextNonWhitespaceOrCommentOrLinebreakToken(fromIndex: i) {
            let lastToken = formatter.previousNonWhitespaceOrCommentOrLinebreakToken(fromIndex: i)
            if lastToken == nil || nextToken.string == "}" {
                // Safe to remove
                formatter.removeTokenAtIndex(i)
            } else if lastToken?.string == "return" || formatter.scopeAtIndex(i)?.string == "(" {
                // Not safe to remove or replace
            } else if formatter.nextNonWhitespaceOrCommentToken(fromIndex: i)?.type == .Linebreak {
                // Safe to remove
                formatter.removeTokenAtIndex(i)
            } else if !formatter.options.allowInlineSemicolons {
                // Replace with a linebreak
                if formatter.tokenAtIndex(i + 1)?.type == .Whitespace {
                    formatter.removeTokenAtIndex(i + 1)
                }
                if let indentToken = formatter.indentTokenForLineAtIndex(i) {
                    formatter.insertToken(indentToken, atIndex: i + 1)
                }
                formatter.replaceTokenAtIndex(i, with: Token(.Linebreak, formatter.options.linebreak))
            }
        } else {
            // Safe to remove
            formatter.removeTokenAtIndex(i)
        }
    }
}

/// Standardise linebreak characters as whatever is specified in the options (\n by default)
public func linebreaks(formatter: Formatter) {
    formatter.forEachToken(ofType: .Linebreak) { i, token in
        formatter.replaceTokenAtIndex(i, with: Token(.Linebreak, formatter.options.linebreak))
    }
}

/// Standardise the order of property specifiers
public func specifiers(formatter: Formatter) {
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
    ]
    let validSpecifiers = Set<String>(order)
    formatter.forEachToken(ofType: .Identifier) { i, token in
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
                if token.type != .Identifier || !validSpecifiers.contains(key) {
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

public let defaultRules: [FormatRule] = [
    linebreaks,
    semicolons,
    specifiers,
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
