//
//  Formatter.swift
//  SwiftFormat
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

import Foundation

/// This is a utility class used for manipulating a tokenized source file.
/// It doesn't actually contain any logic for formatting, but provides
/// utility methods for enumerating and adding/removing/replacing tokens.
/// The primary advantage it provides over operating on the token array
/// directly is that it allows mutation during enumeration, and
/// transparently handles changes that affect the current token index.
public class Formatter: NSObject {
    private var enumerationIndex = -1

    /// The options that the formatter was initialized with
    public let options: FormatOptions

    /// The token array managed by the formatter (read-only)
    public private(set) var tokens: [Token]

    /// Create a new formatter instance from a token array
    public init(_ tokens: [Token], options: FormatOptions = FormatOptions()) {
        self.tokens = tokens
        self.options = options
    }

    // MARK: access and mutation

    /// Returns the token at the specified index, or nil if index is invalid
    public func token(at index: Int) -> Token? {
        guard index >= 0 && index < tokens.count else { return nil }
        return tokens[index]
    }

    /// Replaces the token at the specified index with one or more new tokens
    public func replaceToken(at index: Int, with tokens: Token...) {
        if tokens.count == 0 {
            removeToken(at: index)
        } else {
            self.tokens[index] = tokens[0]
            for (i, token) in tokens.dropFirst().enumerated() {
                insertToken(token, at: index + i + 1)
            }
        }
    }

    /// Replaces the tokens in the specified range with new tokens
    public func replaceTokens(inRange range: Range<Int>, with tokens: [Token]) {
        let max = min(range.count, tokens.count)
        for i in 0 ..< max {
            self.tokens[range.lowerBound + i] = tokens[i]
        }
        if range.count > max {
            for _ in max ..< range.count {
                removeToken(at: range.lowerBound + max)
            }
        } else {
            for i in max ..< tokens.count {
                insertToken(tokens[i], at: range.lowerBound + i)
            }
        }
    }

    /// Replaces the tokens in the specified closed range with new tokens
    public func replaceTokens(inRange range: ClosedRange<Int>, with tokens: [Token]) {
        replaceTokens(inRange: range.lowerBound ..< range.upperBound + 1, with: tokens)
    }

    /// Removes the token at the specified index
    public func removeToken(at index: Int) {
        tokens.remove(at: index)
        if enumerationIndex >= index {
            enumerationIndex -= 1
        }
    }

    /// Removes the tokens in the specified range
    public func removeTokens(inRange range: Range<Int>) {
        replaceTokens(inRange: range, with: [])
    }

    /// Removes the tokens in the specified closed range
    public func removeTokens(inRange range: ClosedRange<Int>) {
        replaceTokens(inRange: range, with: [])
    }

    /// Removes the last token
    public func removeLastToken() {
        tokens.removeLast()
    }

    /// Inserts an array of tokens at the specified index
    public func insertTokens(_ tokens: [Token], at index: Int) {
        for token in tokens.reversed() {
            self.tokens.insert(token, at: index)
        }
        if enumerationIndex >= index {
            enumerationIndex += tokens.count
        }
    }

    /// Inserts a single token at the specified index
    public func insertToken(_ token: Token, at index: Int) {
        insertTokens([token], at: index)
    }

    // MARK: enumeration

    /// Loops through each token in the array. It is safe to mutate the token
    /// array inside the body block, but note that the index and token arguments
    /// may not reflect the current token any more after a mutation
    public func forEachToken(_ body: (Int, Token) -> Void) {
        assert(enumerationIndex == -1, "forEachToken does not support re-entrancy")
        enumerationIndex = 0
        while enumerationIndex < tokens.count {
            body(enumerationIndex, tokens[enumerationIndex]) // May mutate enumerationIndex
            enumerationIndex += 1
        }
        enumerationIndex = -1
    }

    /// As above, but only loops through tokens that match the specified filter block
    public func forEachToken(where matching: (Token) -> Bool, _ body: (Int, Token) -> Void) {
        forEachToken { index, token in
            if matching(token) {
                body(index, token)
            }
        }
    }

    /// As above, but only loops through tokens with the specified type and string
    public func forEach(_ token: Token, _ body: (Int, Token) -> Void) {
        forEachToken(where: { $0 == token }, body)
    }

    /// As above, but only loops through tokens with the specified type and string
    public func forEach(_ type: TokenType, _ body: (Int, Token) -> Void) {
        forEachToken(where: { $0.is(type) }, body)
    }

    // MARK: utilities

    /// Returns the index of the next token at the current scope that matches the block
    public func index(after index: Int, where matches: (Token) -> Bool) -> Int? {
        guard index < tokens.count else { return nil }
        var scopeStack: [Token] = []
        for i in index + 1 ..< tokens.count {
            let token = tokens[i]
            if let scope = scopeStack.last, token.isEndOfScope(scope) {
                scopeStack.removeLast()
                if case .linebreak = token, scopeStack.count == 0, matches(token) {
                    return i
                }
            } else if scopeStack.count == 0 && matches(token) {
                return i
            } else if token.isEndOfScope {
                return nil
            } else if case .startOfScope = token {
                scopeStack.append(token)
            }
        }
        return nil
    }

    /// Returns the index of the next matching token at the current scope
    public func index(of token: Token, after index: Int) -> Int? {
        return self.index(after: index, where: { $0 == token })
    }

    /// Returns the index of the next token at the current scope of the specified type
    public func index(of type: TokenType, after index: Int, if matches: (Token) -> Bool = { _ in true }) -> Int? {
        return self.index(after: index, where: { $0.is(type) }).flatMap { matches(tokens[$0]) ? $0 : nil }
    }

    /// Returns the next token at the current scope that matches the block
    public func nextToken(after index: Int, where matches: (Token) -> Bool = { _ in true }) -> Token? {
        return self.index(after: index, where: matches).map { tokens[$0] }
    }

    /// Returns the next token at the current scope of the specified type
    public func next(_ type: TokenType, after index: Int, if matches: (Token) -> Bool = { _ in true }) -> Token? {
        return self.index(of: type, after: index, if: matches).map { tokens[$0] }
    }

    /// Returns the index of the previous token at the current scope that matches the block
    public func index(before index: Int, where matches: (Token) -> Bool) -> Int? {
        guard index > 0 else { return nil }
        var linebreakEncountered = (token(at: index)?.isLinebreak == true)
        var scopeStack: [Token] = []
        for i in (0 ..< index).reversed() {
            let token = tokens[i]
            if case .startOfScope = token {
                if let scope = scopeStack.last, scope.isEndOfScope(token) {
                    scopeStack.removeLast()
                } else if token.string == "//" && linebreakEncountered {
                    linebreakEncountered = false
                } else if matches(token) {
                    return i
                } else {
                    return nil
                }
            } else if scopeStack.count == 0 && matches(token) {
                return i
            } else if case .linebreak = token {
                linebreakEncountered = true
            } else if case .endOfScope = token {
                scopeStack.append(token)
            }
        }
        return nil
    }

    /// Returns the index of the previous matching token at the current scope
    public func index(of token: Token, before index: Int) -> Int? {
        return self.index(before: index, where: { $0 == token })
    }

    /// Returns the index of the previous token at the current scope of the specified type
    public func index(of type: TokenType, before index: Int, if matches: (Token) -> Bool = { _ in true }) -> Int? {
        return self.index(before: index, where: { $0.is(type) }).flatMap { matches(tokens[$0]) ? $0 : nil }
    }

    /// Returns the previous token at the current scope that matches the block
    public func lastToken(before index: Int, where matches: (Token) -> Bool) -> Token? {
        return self.index(before: index, where: matches).map { tokens[$0] }
    }

    /// Returns the previous token at the current scope of the specified type
    public func last(_ type: TokenType, before index: Int, if matches: (Token) -> Bool = { _ in true }) -> Token? {
        return self.index(of: type, before: index, if: matches).map { tokens[$0] }
    }

    /// Returns the starting token for the containing scope at the specified index
    public func currentScope(at index: Int) -> Token? {
        return last(.startOfScope, before: index)
    }

    /// Returns the index of the ending token for the current scope
    public func endOfScope(at index: Int) -> Int? {
        let startIndex: Int
        guard var startToken = token(at: index) else { return nil }
        if case .startOfScope = startToken {
            startIndex = index
        } else if let index = self.index(of: .startOfScope, before: index) {
            startToken = tokens[index]
            startIndex = index
        } else {
            return nil
        }
        return self.index(after: startIndex) {
            $0.isEndOfScope(startToken)
        }
    }

    /// Returns the index of the first token of the line containing the specified index
    public func startOfLine(at index: Int) -> Int {
        var index = index
        while let token = token(at: index - 1) {
            if case .linebreak = token {
                break
            }
            index -= 1
        }
        return index
    }

    /// Returns the space at the start of the line containing the specified index
    public func indentForLine(at index: Int) -> String {
        if let token = token(at: startOfLine(at: index)), case let .space(string) = token {
            return string
        }
        return ""
    }

    /// Either modifies or removes the existing space token at the specified
    /// index, or inserts a new one if there is not already a space token present.
    /// Returns the number of tokens inserted or removed
    @discardableResult func insertSpace(_ space: String, at index: Int) -> Int {
        if token(at: index)?.isSpace == true {
            if space.isEmpty {
                removeToken(at: index)
                return -1 // Removed 1 token
            }
            replaceToken(at: index, with: .space(space))
        } else if !space.isEmpty {
            insertToken(.space(space), at: index)
            return 1 // Inserted 1 token
        }
        return 0 // Inserted 0 tokens
    }
}
