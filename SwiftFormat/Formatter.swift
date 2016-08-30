//
//  Formatter.swift
//  SwiftFormat
//
//  Version 0.7.1
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

    public init(indent: String = "    ",
        linebreak: String = "\n",
        allowInlineSemicolons: Bool = true) {

        self.indent = indent
        self.linebreak = linebreak
        self.allowInlineSemicolons = allowInlineSemicolons
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

    /// Replaces the tokens in the specified range with new tokens
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
            if indexStack[i] >= index {
                indexStack[i] -= 1
            }
        }
    }

    /// Removes the tokens in the specified range
    public func removeTokensInRange(range: Range<Int>) {
        replaceTokensInRange(range)
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

    // MARK: enumeration

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

    /// As above, but only loops through tokens that match the specified filter block
    public func forEachToken(matching: (Token) -> Bool, _ body: (Int, Token) -> Void) {
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
    public func forEachToken(string: String, ofType type: TokenType, _ body: (Int, Token) -> Void) {
        forEachToken({ return $0.type == type && $0.string == string }, body)
    }

    /// As above, but only loops through tokens with the specified string.
    /// Tokens of type `StringBody` and `CommentBody` are ignored, as these
    /// can't be usefully identified by their string value
    public func forEachToken(string: String, _ body: (Int, Token) -> Void) {
        forEachToken({
            return $0.string == string && $0.type != .StringBody && $0.type != .CommentBody
        }, body)
    }
}
