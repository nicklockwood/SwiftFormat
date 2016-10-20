//
//  Formatter.swift
//  SwiftFormat
//
//  Version 0.13
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
public struct FormatOptions {
    public var indent: String
    public var linebreak: String
    public var allowInlineSemicolons: Bool
    public var spaceAroundRangeOperators: Bool
    public var useVoid: Bool
    public var trailingCommas: Bool
    public var fragment: Bool

    public init(indent: String = "    ",
        linebreak: String = "\n",
        allowInlineSemicolons: Bool = true,
        spaceAroundRangeOperators: Bool = true,
        useVoid: Bool = true,
        trailingCommas: Bool = true,
        fragment: Bool = false) {

        self.indent = indent
        self.linebreak = linebreak
        self.allowInlineSemicolons = allowInlineSemicolons
        self.spaceAroundRangeOperators = spaceAroundRangeOperators
        self.useVoid = useVoid
        self.trailingCommas = trailingCommas
        self.fragment = fragment
    }
}

/// This is a utility class used for manipulating a tokenized source file.
/// It doesn't actually contain any logic for formatting, but provides
/// utility methods for enumerating and adding/removing/replacing tokens.
/// The primary advantage it provides over operating on the token array
/// directly is that it allows mutation during enumeration, and
/// transparently handles changes that affect the current token index.
public class Formatter {
    private(set) var tokens: [Token]
    let options: FormatOptions

    private var indexStack: [Int] = []

    init(_ tokens: [Token], options: FormatOptions) {
        self.tokens = tokens
        self.options = options
    }

    // MARK: access and mutation

    /// Returns the token at the specified index, or nil if index is invalid
    public func tokenAtIndex(_ index: Int) -> Token? {
        guard index >= 0 && index < tokens.count else { return nil }
        return tokens[index]
    }

    /// Replaces the token at the specified index with one or more new tokens
    public func replaceTokenAtIndex(_ index: Int, with tokens: Token...) {
        if tokens.count == 0 {
            removeTokenAtIndex(index)
        } else {
            self.tokens[index] = tokens[0]
            for (i, token) in tokens.dropFirst().enumerated() {
                insertToken(token, atIndex: index + i + 1)
            }
        }
    }

    /// Replaces the tokens in the specified range with new tokens
    public func replaceTokensInRange(_ range: Range<Int>, with tokens: [Token]) {
        let max = min(range.count, tokens.count)
        for i in 0 ..< max {
            replaceTokenAtIndex(range.lowerBound + i, with: tokens[i])
        }
        if range.count > max {
            for _ in max ..< range.count {
                removeTokenAtIndex(range.lowerBound + max)
            }
        } else {
            for i in max ..< tokens.count {
                insertToken(tokens[i], atIndex: range.lowerBound + i)
            }
        }
    }

    /// Removes the token at the specified indez
    public func removeTokenAtIndex(_ index: Int) {
        tokens.remove(at: index)
        for (i, j) in indexStack.enumerated() where j >= index {
            indexStack[i] -= 1
        }
    }

    /// Removes the tokens in the specified range
    public func removeTokensInRange(_ range: Range<Int>) {
        replaceTokensInRange(range, with: [])
    }

    /// Removes the last token
    public func removeLastToken() {
        tokens.removeLast()
    }

    /// Inserts a tokens at the specified index
    public func insertToken(_ token: Token, atIndex index: Int) {
        tokens.insert(token, at: index)
        for (i, j) in indexStack.enumerated() where j >= index {
            indexStack[i] += 1
        }
    }

    // MARK: enumeration

    /// Loops through each token in the array. It is safe to mutate the token
    /// array inside the body block, but note that the index and token arguments
    /// may not reflect the current token any more after a mutation
    public func forEachToken(_ body: (Int, Token) -> Void) {
        let i = indexStack.count
        indexStack.append(0)
        while indexStack[i] < tokens.count {
            let index = indexStack[i]
            body(index, tokens[index]) // May mutate indexStack
            indexStack[i] += 1
        }
        indexStack.removeLast()
    }

    /// As above, but only loops through tokens that match the specified filter block
    public func forEachToken(_ matching: (Token) -> Bool, _ body: (Int, Token) -> Void) {
        forEachToken { index, token in
            if matching(token) {
                body(index, token)
            }
        }
    }

    /// As above, but only loops through tokens with the specified type
    public func forEachToken(ofType type: TokenType, _ body: (Int, Token) -> Void) {
        forEachToken({ $0.type == type }, body)
    }

    /// As above, but only loops through tokens with the specified type and string
    public func forEachToken(_ string: String, ofType type: TokenType, _ body: (Int, Token) -> Void) {
        forEachToken({ return $0.type == type && $0.string == string }, body)
    }

    /// As above, but only loops through tokens with the specified string.
    /// Tokens of type `StringBody` and `CommentBody` are ignored, as these
    /// can't be usefully identified by their string value
    public func forEachToken(_ string: String, _ body: (Int, Token) -> Void) {
        forEachToken({
            return $0.string == string && $0.type != .stringBody && $0.type != .commentBody
        }, body)
    }

    // MARK: utilities

    /// Returns the index of the next token at the current scope that matches the block
    func indexOfNextToken(fromIndex index: Int, matching: (Token) -> Bool) -> Int? {
        var i = index + 1
        var scopeStack: [Token] = []
        while let token = tokenAtIndex(i) {
            if let scope = scopeStack.last, token.closesScopeForToken(scope) {
                scopeStack.removeLast()
                if token.type == .linebreak {
                    i -= 1
                }
            } else if scopeStack.count == 0 && matching(token) {
                return i
            } else if token.type == .startOfScope {
                scopeStack.append(token)
            }
            i += 1
        }
        return nil
    }

    /// Returns the next token at the current scope that matches the block
    public func nextToken(fromIndex index: Int, matching: (Token) -> Bool) -> Token? {
        return indexOfNextToken(fromIndex: index, matching: matching).map { tokens[$0] }
    }

    /// Returns the next token that isn't whitespace, a comment or a linebreak
    public func nextNonWhitespaceOrCommentOrLinebreakToken(fromIndex index: Int) -> Token? {
        return nextToken(fromIndex: index) { !$0.isWhitespaceOrCommentOrLinebreak }
    }

    /// Returns the next token that isn't whitespace or a comment
    public func nextNonWhitespaceOrCommentToken(fromIndex index: Int) -> Token? {
        return nextToken(fromIndex: index) { !$0.isWhitespaceOrComment }
    }

    /// Returns the next token that isn't whitespace
    public func nextNonWhitespaceToken(fromIndex index: Int) -> Token? {
        return nextToken(fromIndex: index) { $0.type != .whitespace }
    }

    /// Returns the index of the previous token at the current scope that matches the block
    func indexOfPreviousToken(fromIndex index: Int, matching: (Token) -> Bool) -> Int? {
        var i = index - 1
        var linebreakEncountered = false
        var scopeStack: [Token] = []
        while let token = tokenAtIndex(i) {
            if token.type == .startOfScope {
                if let scope = scopeStack.last, scope.closesScopeForToken(token) {
                    scopeStack.removeLast()
                } else if token.string == "//" && linebreakEncountered {
                    linebreakEncountered = false
                } else if matching(token) {
                    return i
                } else {
                    return nil
                }
            } else if scopeStack.count == 0 && matching(token) {
                return i
            } else if token.type == .linebreak {
                linebreakEncountered = true
            } else if token.type == .endOfScope {
                scopeStack.append(token)
            }
            i -= 1
        }
        return nil
    }

    /// Returns the previous token at the current scope that matches the block
    func previousToken(fromIndex index: Int, matching: (Token) -> Bool) -> Token? {
        return indexOfPreviousToken(fromIndex: index, matching: matching).map { tokens[$0] }
    }

    /// Returns the previous token that isn't whitespace, a comment or a linebreak
    func previousNonWhitespaceOrCommentOrLinebreakToken(fromIndex index: Int) -> Token? {
        return previousToken(fromIndex: index) { !$0.isWhitespaceOrCommentOrLinebreak }
    }

    /// Returns the previous token that isn't whitespace
    func previousNonWhitespaceToken(fromIndex index: Int) -> Token? {
        return previousToken(fromIndex: index) { $0.type != .whitespace }
    }

    /// Returns the starting token for the containing scope at the specified index
    public func scopeAtIndex(_ index: Int) -> Token? {
        return previousToken(fromIndex: index) { $0.type == .startOfScope }
    }

    /// Returns the index of the first token of the line containing the specified index
    public func startOfLine(atIndex index: Int) -> Int {
        var index = index
        while let token = tokenAtIndex(index - 1) {
            if token.type == .linebreak {
                break
            }
            index -= 1
        }
        return index
    }

    /// Returns the whitespace token at the start of the line containing the specified index
    public func indentTokenForLineAtIndex(_ index: Int) -> Token? {
        if let token = tokenAtIndex(startOfLine(atIndex: index)), token.type == .whitespace {
            return token
        }
        return nil
    }
}
