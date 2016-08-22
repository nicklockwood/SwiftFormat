//
//  SwiftFormat
//  Formatter.swift
//
//  Version 0.1
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

import Foundation

/// Configuration options for formatting. These aren't actually used by the
/// Formatter class itself, but it makes them available to the format rules.
public struct FormattingOptions {
    var indent: String = "    "
}

/// This is a utility class used for manipulating a tokenized source file.
/// It doesn't actually contain any logic for formatting, but provides
/// utility methods for enumerating and adding/removing/replacing tokens.
/// The primary advantage it provides over operating on the token array
/// directly is that it allows mutation during enumeration, and
/// transparently handles changes that affect the current token index.
public class Formatter {
    private (set) var tokens: [Token]
    let options: FormattingOptions
    
    private var indexStack: [Int] = []
    
    init(_ tokens: [Token], options: FormattingOptions) {
        self.tokens = tokens
        self.options = options
    }
    
    /// Returns the token at the specified index, or nil if index is invalid
    public func tokenAtIndex(index: Int) -> Token? {
        guard index >= 0 && index < tokens.count else { return nil }
        return tokens[index]
    }
    
    /// Replaces the token at the specified index with one or more new tokens
    public func replaceTokenAtIndex(index: Int, with tokens: Token...) {
        if tokens.count == 0 {
            removeTokenAtIndex(index)
        } else {
            self.tokens[index] = tokens[0]
            for (i, token) in tokens.dropFirst().enumerate() {
                insertToken(token, atIndex: index + i + 1)
            }
        }
    }
    
    /// Returns the tokens in the specified range with new tokens
    public func replaceTokensInRange(range: Range<Int>, with tokens: Token...) {
        let max = min(range.count, tokens.count)
        for i in 0 ..< max {
            replaceTokenAtIndex(range.startIndex + i, with: tokens[i])
        }
        if range.count > max {
            for _ in max ..< range.count {
                removeTokenAtIndex(range.startIndex + max)
            }
        } else {
            for i in max ..< tokens.count {
                insertToken(tokens[i], atIndex: range.startIndex + i)
            }
        }
    }
    
    /// Removes the token at the specified indez
    public func removeTokenAtIndex(index: Int) {
        tokens.removeAtIndex(index)
        for i in 0 ..< indexStack.count {
            if indexStack[i] > index {
                indexStack[i] -= 1
            }
        }
    }
    
    /// Removes the last token
    public func removeLastToken() {
        tokens.removeLast()
    }
    
    /// Inserts a tokens at the specified index
    public func insertToken(token: Token, atIndex index: Int) {
        tokens.insert(token, atIndex: index)
        for i in 0 ..< indexStack.count {
            if indexStack[i] >= index {
                indexStack[i] += 1
            }
        }
    }
    
    /// Loops through each token in the array. It is safe to mutate the token
    /// array inside the body block, but note that the index and token arguments
    /// may not reflect the current token any more after a mutation
    public func forEachToken(body: (Int, Token) -> Void) {
        let i = indexStack.count
        indexStack.append(0)
        while indexStack[i] < tokens.count {
            let index = indexStack[i]
            body(index, tokens[index])
            indexStack[i] += 1
        }
        indexStack.popLast()
    }

    /// As above, but only loops through tokens with the specified type
    public func forEachToken(ofType type: TokenType, _ body: (Int, Token) -> Void) {
        forEachToken(matching: { $0.type == type }, body)
    }
    
    /// As above, but only loops through tokens with the specified type and string
    public func forEachToken(string: String, ofType type: TokenType, _ body: (Int, Token) -> Void) {
        forEachToken(matching: {
            return $0.type == type && $0.string == string
        }, body)
    }
    
    /// As above, but only loops through tokens with the specified string.
    /// Tokens of type `StringBody` and `CommentBody` are ignored, as these
    /// can't be usefully identified by their string value
    public func forEachToken(string: String, _ body: (Int, Token) -> Void) {
        forEachToken(matching: {
            // Exclude string and comment bodies as this will cause false-positive matches
            return $0.string == string && $0.type != .StringBody && $0.type != .CommentBody
        }, body)
    }
    
    private func forEachToken(matching condition: (Token) -> Bool, _ body: (Int, Token) -> Void) {
        forEachToken { index, token in
            if condition(token) {
                body(index, token)
            }
        }
    }
}

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
    func spaceAfter(identifier: String) -> Bool {
        switch identifier {
        case "internal",
                "fileprivate",
                "private",
                "public",
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
                "rethrows",
                "throw",
                "throws",
                "try":
            return true
        default:
            return false
        }
    }
    
    formatter.forEachToken("(") { i, token in
        guard let previousToken = formatter.tokenAtIndex(i - 1) else {
            return
        }
        if spaceAfter(previousToken.string) {
            formatter.insertToken(Token(.Whitespace, " "), atIndex: i)
        } else if previousToken.type == .Whitespace {
            if let token = formatter.tokenAtIndex(i - 2) {
                if (token.type == .EndOfScope && ["]", "}", ")", ">"].contains(token.string)) ||
                    (token.type == .Identifier && !spaceAfter(token.string)) {
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
    func spaceAfter(identifier: String) -> Bool {
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
            return true
        default:
            return false
        }
    }
    
    formatter.forEachToken("[") { i, token in
        guard let previousToken = formatter.tokenAtIndex(i - 1) else {
            return
        }
        if spaceAfter(previousToken.string) {
            formatter.insertToken(Token(.Whitespace, " "), atIndex: i)
        } else if previousToken.type == .Whitespace {
            if let token = formatter.tokenAtIndex(i - 2) {
                if (token.type == .EndOfScope && ["]", "}", ")"].contains(token.string)) ||
                    (token.type == .Identifier && !spaceAfter(token.string)) {
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
    
    func spaceAfter(identifier: String) -> Bool {
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
            return true
        default:
            return false
        }
    }
    
    var scopeStack: [Token] = []
    formatter.forEachToken { i, token in
        switch token.type {
        case .Operator:
            if [":", ",", ";"].contains(token.string) {
                // Ensure there is a space after the token
                if let nextToken = formatter.tokenAtIndex(i + 1) {
                    switch nextToken.type {
                    case .Whitespace, .Linebreak, .EndOfScope: break
                    default:
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
            } else if ["?.", "!."].contains(token.string) {
                // Do nothing, as whitespace is not permitted by compiler
            } else if token.string == "." {
                if formatter.tokenAtIndex(i + 1)?.type == .Whitespace {
                    formatter.removeTokenAtIndex(i + 1)
                }
                if let previousToken = formatter.tokenAtIndex(i - 1) {
                    let previousTokenWasWhitespace = (previousToken.type == .Whitespace)
                    if let previousNonWhitespaceToken =
                        previousTokenWasWhitespace ? formatter.tokenAtIndex(i - 2) : previousToken {
                        if previousNonWhitespaceToken.type != .Linebreak &&
                            (previousNonWhitespaceToken.type != .Operator ||
                            (previousNonWhitespaceToken.string == "?" && scopeStack.last?.string != "?") ||
                            (previousNonWhitespaceToken.string == "!" && scopeStack.last?.string != "!")) &&
                            (previousNonWhitespaceToken.type != .Identifier ||
                                !spaceAfter(previousNonWhitespaceToken.string)) {
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
            } else if let previousToken = formatter.tokenAtIndex(i - 1) where isLvalue(previousToken) {
                if let nextToken = formatter.tokenAtIndex(i + 1) where isRvalue(nextToken) {
                    // Insert space before and after the infix token
                    formatter.insertToken(Token(.Whitespace, " "), atIndex: i + 1)
                    formatter.insertToken(Token(.Whitespace, " "), atIndex: i)
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

/// Collapse all consecutive whitespace characters to a single space, except at
/// the start of a line or inside a comment or string, as these have no semantic
/// meaning and lead to noise in commits.
public func noConsecutiveSpaces(formatter: Formatter) {
    formatter.forEachToken(ofType: .Whitespace) { i, token in
        if let previous = formatter.tokenAtIndex(i - 1) where previous.type != .Linebreak {
            formatter.replaceTokenAtIndex(i, with: Token(.Whitespace, " "))
        }
    }
}

/// Remove trailing whitespace from the end of lines, as it has no semantic
/// meaning and leads to noise in commits.
public func noTrailingWhitespace(formatter: Formatter) {
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
public func noConsecutiveBlankLines(formatter: Formatter) {
    var blankLineCount = 0
    var lastTokenWasWhitespace = false
    formatter.forEachToken { i, token in
        if token.type == .Linebreak {
            blankLineCount += 1
            if blankLineCount > 2 {
                formatter.removeTokenAtIndex(i)
                if lastTokenWasWhitespace {
                    formatter.removeTokenAtIndex(i - 1)
                }
                blankLineCount -= 1
            }
            lastTokenWasWhitespace = false
        } else if token.type != .Whitespace {
            blankLineCount = 0
            lastTokenWasWhitespace = false
        } else {
            lastTokenWasWhitespace = true
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
        formatter.insertToken(Token(.Linebreak, "\n"), atIndex: formatter.tokens.count)
    }
}

/// Indent code according to standard scope indenting rules.
/// The type (tab or space) and level (2 spaces, 4 spaces, etc.) of the
/// indenting can be configured with the `options` parameter of the formatter.
public func indent(formatter: Formatter) {
    func startOfLine(atIndex index: Int) -> Int {
        var index = index
        while let token = formatter.tokenAtIndex(index - 1) {
            if token.type == .Linebreak {
                break
            }
            index -= 1
        }
        return index
    }
    
    func nextNonWhitespaceToken(fromIndex index: Int) -> Token? {
        var index = index
        while let token = formatter.tokenAtIndex(index) {
            if token.type != .Whitespace && token.type != .Linebreak {
                return token
            }
            index += 1
        }
        return nil
    }
    
    func setIndent(indent: String, atIndex index: Int) {
        if formatter.tokenAtIndex(index)?.type == .Whitespace {
            if indent != "" {
                formatter.replaceTokenAtIndex(index, with: Token(.Whitespace, indent))
            } else {
                formatter.removeTokenAtIndex(index)
            }
        } else if indent != "" {
            formatter.insertToken(Token(.Whitespace, indent), atIndex: index)
        }
    }
    
    var scopeIndexStack: [Int] = []
    var scopeStartLineIndexes: [Int] = []
    var lastNonWhitespaceIndex = -1
    var indentStack = [""]
    var lineIndex = 0
    var linewrapped = false
    
    func currentScope() -> Token? {
        if let scopeIndex = scopeIndexStack.last {
            return formatter.tokens[scopeIndex]
        }
        return nil
    }
    
    func tokenIsEndOfStatement(i: Int) -> Bool {
        if let token = formatter.tokenAtIndex(i) {
            switch token.type {
            case .Identifier:
                // TODO: handle context-specific keywords
                // in, associativity, convenience, dynamic, didSet, final, get, infix, indirect,
                // lazy, left, mutating, none, nonmutating, optional, override, postfix, precedence,
                // prefix, Protocol, required, right, set, Type, unowned, weak, willSet
                switch token.string {
                case "associatedtype",
                        "class",
                        "deinit",
                        "enum",
                        "extension",
                        "fileprivate",
                        "func",
                        "import",
                        "init",
                        "inout",
                        "internal",
                        "let",
                        "open",
                        "operator",
                        "private",
                        "protocol",
                        "public",
                        "static",
                        "struct",
                        "subscript",
                        "typealias",
                        "var",
                        "case",
                        "default",
                        "defer",
                        "else",
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
                    return false
                default:
                    return true
                }
            case .Operator:
                if token.string == "." {
                    return false
                }
                if token.string == "," && !["[", "("].contains(currentScope()?.string ?? "") {
                    return false
                }
                if let previousToken = formatter.tokenAtIndex(i - 1) where
                    previousToken.isWhitespaceOrCommentOrLinebreak ||
                    previousToken.string == "as" || previousToken.string == "try" {
                    return false
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
                // TODO: handle in
                switch token.string {
                case "else",
                        "as",
                        "dynamicType",
                        "false",
                        "is",
                        "nil",
                        "rethrows",
                        "throws",
                        "true":
                    return false
                default:
                    return true
                }
            case .Operator:
                if token.string == "." {
                    return false
                }
                if token.string == "," && !["[", "("].contains(currentScope()?.string ?? "") {
                    return false
                }
                if let nextToken = formatter.tokenAtIndex(i + 1) where
                    nextToken.isWhitespaceOrCommentOrLinebreak {
                    return false
                }
            default:
                return true
            }
        }
        return true
    }
    
    formatter.forEachToken { i, token in
        if token.type == .StartOfScope {
            // Handle start of scope
            scopeIndexStack.append(i)
            var indent = indentStack.last ?? ""
            if lineIndex > scopeStartLineIndexes.last ?? -1 {
                if token.string == "/*" {
                    // Comments only indent one space
                    indent += " "
                } else {
                    indent += formatter.options.indent
                }
            }
            indentStack.append(indent)
            scopeStartLineIndexes.append(lineIndex)
        } else {
            if let scopeIndex = scopeIndexStack.last, scope = formatter.tokenAtIndex(scopeIndex) {
                // Handle end of scope
                if token.closesScopeForToken(scope) {
                    scopeStartLineIndexes.popLast()
                    scopeIndexStack.popLast()
                    indentStack.popLast()
                    if lineIndex > scopeStartLineIndexes.last ?? -1 {
                        let start = startOfLine(atIndex: i)
                        if let nextToken = nextNonWhitespaceToken(fromIndex: start) where
                            nextToken.type == .EndOfScope && nextToken.string != "*/" {
                            // Only reduce indent if line begins with a closing scope token
                            let indent = indentStack.last ?? ""
                            setIndent(indent, atIndex: start)
                        }
                    }
                } else if token.type == .Identifier {
                    // Handle #elseif/#else
                    if token.string == "#else" || token.string == "#elseif" {
                        let indent = indentStack[indentStack.count - 2]
                        setIndent(indent, atIndex: startOfLine(atIndex: i))
                    }
                    // Handle switch/case
                        else if token.string == "case" || token.string == "default" {
                        if scope.string == "{" {
                            // walk backwards to see if this is an switch or enum
                            var isSwitch = true
                            var subscopeStack: [Token] = []
                            var j = scopeIndex - 1
                            loop: while let token = formatter.tokenAtIndex(j) {
                                switch token.type {
                                case .Identifier:
                                    if subscopeStack.count == 0 {
                                        if token.string == "switch" {
                                            break loop
                                        }
                                        if token.string == "enum" {
                                            isSwitch = false
                                            break loop
                                        }
                                    }
                                case .EndOfScope:
                                    subscopeStack.append(token)
                                case .StartOfScope:
                                    if subscopeStack.count == 0 {
                                        break loop
                                    }
                                    subscopeStack.popLast()
                                default:
                                    break
                                }
                                j -= 1
                            }
                            if isSwitch {
                                let indent = indentStack[indentStack.count - 2]
                                setIndent(indent, atIndex: startOfLine(atIndex: i))
                            }
                        }
                    }
                }
            }
            // Indent each new line
            if token.type == .Linebreak {
                linewrapped = !tokenIsEndOfStatement(lastNonWhitespaceIndex)
                if linewrapped && lineIndex == scopeStartLineIndexes.last {
                    indentStack.popLast()
                    indentStack.append(indentStack.last ?? "")
                }
                lineIndex += 1
                let indent = (indentStack.last ?? "") + (linewrapped ? formatter.options.indent : "")
                setIndent(indent, atIndex: i + 1)
            }
        }
        // Track token for line wraps
        if !token.isWhitespaceOrComment {
            if !linewrapped && formatter.tokenAtIndex(lastNonWhitespaceIndex)?.type == .Linebreak &&
                !tokenIsStartOfStatement(i) {
                linewrapped = true
                if linewrapped && lineIndex - 1 == scopeStartLineIndexes.last {
                    indentStack.popLast()
                    indentStack.append(indentStack.last ?? "")
                }
                let indent = (indentStack.last ?? "") + (linewrapped ? formatter.options.indent : "")
                setIndent(indent, atIndex: startOfLine(atIndex: i))
            }
            lastNonWhitespaceIndex = i
        }
    }
}

/// Implement K&R-style braces, where opening brace appears on the same line as
/// the related function or keyword, and the closing brace is on its own line,
/// except for inline closures where opening and closing brace are on same line.
public func knrBraces(formatter: Formatter) {
    formatter.forEachToken("{") { i, token in
        var index = i - 1
        var containsLinebreak = false
        while let token = formatter.tokenAtIndex(index) {
            switch token.type {
            case .Linebreak:
                containsLinebreak = true
            case .Whitespace:
                break
            default:
                if containsLinebreak {
                    formatter.replaceTokensInRange(index + 1 ..< i, with: Token(.Whitespace, " "))
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
                    formatter.replaceTokensInRange(index + 1 ..< i, with: Token(.Whitespace, " "))
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
        var index = i - 1
        var newLine = false
        while let token = formatter.tokenAtIndex(index) {
            if token.type == .Linebreak {
                newLine = true
            } else if token.type != .Whitespace {
                if newLine && token.type != .Operator {
                    formatter.insertToken(Token(.Operator, ","), atIndex: index + 1)
                }
                break
            }
            index -= 1
        }
    }
}

public let defaultRules: [FormatRule] = [
    spaceAroundParens,
    spaceInsideParens,
    spaceAroundBrackets,
    spaceInsideBrackets,
    spaceAroundBraces,
    spaceInsideBraces,
    spaceAroundGenerics,
    spaceInsideGenerics,
    spaceAroundOperators,
    noConsecutiveSpaces,
    noTrailingWhitespace,
    noConsecutiveBlankLines,
    linebreakAtEndOfFile,
    indent,
    knrBraces,
    elseOnSameLine,
    trailingCommas,
]
