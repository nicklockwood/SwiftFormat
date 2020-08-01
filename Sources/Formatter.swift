//
//  Formatter.swift
//  SwiftFormat
//
//  Version 0.45.1
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

/// This is a utility class used for manipulating a tokenized source file.
/// It doesn't actually contain any logic for formatting, but provides
/// utility methods for enumerating and adding/removing/replacing tokens.
/// The primary advantage it provides over operating on the token array
/// directly is that it allows mutation during enumeration, and
/// transparently handles changes that affect the current token index.
public class Formatter: NSObject {
    private var enumerationIndex = -1
    private var disabledCount = 0
    private var disabledNext = 0
    private var ruleDisabled = false
    private var tempOptions: FormatOptions?
    private var wasNextDirective = false

    // Formatting range
    public var range: Range<Int>?

    // Current rule, used for handling comment directives
    var currentRule: FormatRule? {
        didSet {
            disabledCount = 0
            disabledNext = 0
            ruleDisabled = false
        }
    }

    // Is current rule enabled
    var isEnabled: Bool {
        if ruleDisabled || disabledCount + disabledNext > 0 ||
            range?.contains(enumerationIndex) == false
        {
            return false
        }
        return true
    }

    // Process a comment token (which may contain directives)
    func processCommentBody(_ comment: String, at index: Int) {
        var prefix = "swiftformat:"
        guard comment.hasPrefix(prefix) else {
            return
        }
        guard let directive = ["disable", "enable", "options"].first(where: {
            comment.hasPrefix("\(prefix)\($0)")
        }) else {
            let parts = comment.components(separatedBy: ":")
            var directive = parts[1]
            if let range = directive.rangeOfCharacter(from: .whitespacesAndNewlines) {
                directive = String(directive[..<range.lowerBound])
            }
            return fatalError("Unknown directive swiftformat:\(directive)", at: index)
        }
        prefix += directive
        wasNextDirective = comment.hasPrefix("\(prefix):next")
        let offset = (wasNextDirective ? "\(prefix):next" : prefix).endIndex
        let argumentsString = String(comment[offset...])
        func containsRule() -> Bool {
            guard let rule = currentRule else {
                return false
            }
            // TODO: handle typos, error for invalid rule names
            // TODO: warn when trying to enable a rule that isn't enabled at file level
            return argumentsString.range(of: "\\b(\(rule.name)|all)\\b",
                                         options: .regularExpression) != nil
        }
        switch directive {
        case "options":
            if wasNextDirective {
                tempOptions = options
            }
            let args = parseArguments(argumentsString)
            do {
                let args = try preprocessArguments(args, formattingArguments + internalArguments)
                if let arg = args["1"] {
                    throw FormatError.options("Unknown option \(arg)")
                }
                var options = Options(formatOptions: self.options)
                try options.addArguments(args, in: "")
                self.options = options.formatOptions ?? self.options
            } catch {
                return fatalError("\(error)", at: index)
            }
        case "disable" where containsRule():
            if wasNextDirective {
                disabledNext = 1
            } else {
                disabledCount += 1
            }
        case "enable" where containsRule():
            if wasNextDirective {
                disabledNext = -1
            } else {
                disabledCount -= 1
            }
        default:
            return
        }
    }

    /// Process a linebreak (used to cancel disable/enable:next directive)
    func processLinebreak() {
        if wasNextDirective {
            wasNextDirective = false
        } else {
            if let options = tempOptions {
                self.options = options
                tempOptions = nil
            }
            if disabledNext != 0 {
                disabledNext = 0
            }
        }
    }

    /// The options that the formatter was initialized with
    public private(set) var options: FormatOptions

    /// The token array managed by the formatter (read-only)
    public private(set) var tokens: [Token]

    /// Create a new formatter instance from a token array
    public init(_ tokens: [Token], options: FormatOptions = FormatOptions(),
                trackChanges: Bool = false, range: Range<Int>? = nil)
    {
        self.tokens = tokens
        self.options = options
        self.trackChanges = trackChanges
        self.range = range
    }

    // MARK: changes made

    /// Change record
    public struct Change: Equatable, CustomStringConvertible {
        public let line: Int
        public let rule: FormatRule
        public let filePath: String?

        public var description: String {
            let help = stripMarkdown(rule.help).replacingOccurrences(of: "\n", with: " ")
            return "\(filePath ?? ""):\(line):1: warning: (\(rule.name)) \(help)"
        }
    }

    /// Changes made
    // TODO: make private(set)
    public var changes = [Change]()

    /// Should formatter track changes?
    // TODO: make let/private
    public var trackChanges = false

    private func trackChange(at index: Int) {
        guard trackChanges, let rule = currentRule else { return }
        changes.append(Change(
            line: originalLine(at: index),
            rule: rule,
            filePath: options.fileInfo.filePath
        ))
    }

    private func updateRange(at index: Int, delta: Int) {
        guard let range = range, range.contains(index) else {
            return
        }
        self.range = range.lowerBound ..< range.upperBound + delta
    }

    // MARK: errors and warning

    private(set) var errors = [FormatError]()

    func fatalError(_ error: String, at tokenIndex: Int) {
        let line = originalLine(at: tokenIndex)
        errors.append(.parsing(error + " on line \(line)"))
        ruleDisabled = true
    }

    // MARK: access and mutation

    /// Returns the token at the specified index, or nil if index is invalid
    public func token(at index: Int) -> Token? {
        guard index >= 0, index < tokens.count else { return nil }
        return tokens[index]
    }

    /// Replaces the token at the specified index with one or more new tokens
    public func replaceToken(at index: Int, with tokens: [Token]) {
        if tokens.isEmpty {
            removeToken(at: index)
        } else if tokens.count != 1 || tokens[0] != self.tokens[index] {
            trackChange(at: index)
            self.tokens[index] = tokens[0]
            for (i, token) in tokens.dropFirst().enumerated() {
                insertToken(token, at: index + i + 1)
            }
        }
    }

    /// Replaces the token at the specified index with a new token
    public func replaceToken(at index: Int, with token: Token) {
        if token != tokens[index] {
            trackChange(at: index)
            tokens[index] = token
        }
    }

    /// Replaces the tokens in the specified range with new tokens
    public func replaceTokens(inRange range: Range<Int>, with tokens: [Token]) {
        if range.count == tokens.count, ArraySlice(tokens) == self.tokens[range] {
            return
        }
        let max = min(range.count, tokens.count)
        for i in 0 ..< max {
            trackChange(at: range.lowerBound + i)
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
        trackChange(at: index)
        updateRange(at: index, delta: -1)
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
        trackChange(at: tokens.endIndex - 1)
        updateRange(at: tokens.endIndex - 1, delta: -1)
        tokens.removeLast()
    }

    /// Inserts an array of tokens at the specified index
    public func insertTokens(_ tokens: [Token], at index: Int) {
        trackChange(at: index)
        for token in tokens.reversed() {
            updateRange(at: index, delta: 1)
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
            let token = tokens[enumerationIndex]
            switch token {
            case let .commentBody(comment):
                processCommentBody(comment, at: enumerationIndex)
            case .linebreak:
                processLinebreak()
            default:
                break
            }
            if isEnabled {
                body(enumerationIndex, token) // May mutate enumerationIndex
            }
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

    /// Returns the index of the next token in the specified range that matches the block
    public func index(in range: CountableRange<Int>, where matches: (Token) -> Bool) -> Int? {
        let range = range.clamped(to: 0 ..< tokens.count)
        var scopeStack: [Token] = []
        for i in range {
            let token = tokens[i]
            // TODO: find a better way to deal with this special case
            if token == .endOfScope("#endif") {
                while let scope = scopeStack.last, scope != .startOfScope("#if") {
                    scopeStack.removeLast()
                }
            }
            if let scope = scopeStack.last, token.isEndOfScope(scope) {
                scopeStack.removeLast()
                if case .linebreak = token, scopeStack.isEmpty, matches(token) {
                    return i
                }
            } else if token == .endOfScope("case") || token == .endOfScope("default"),
                scopeStack.last == .startOfScope("#if")
            {
                continue
            } else if scopeStack.isEmpty, matches(token) {
                return i
            } else if token.isEndOfScope {
                return nil
            } else if case .startOfScope = token {
                scopeStack.append(token)
            }
        }
        return nil
    }

    /// Returns the index of the next token at the current scope that matches the block
    public func index(after index: Int, where matches: (Token) -> Bool) -> Int? {
        guard index < tokens.count else { return nil }
        return self.index(in: index + 1 ..< tokens.count, where: matches)
    }

    /// Returns the index of the next matching token in the specified range
    public func index(of token: Token, in range: CountableRange<Int>) -> Int? {
        return index(in: range, where: { $0 == token })
    }

    /// Returns the index of the next matching token at the current scope
    public func index(of token: Token, after index: Int) -> Int? {
        return self.index(after: index, where: { $0 == token })
    }

    /// Returns the index of the next token in the specified range of the specified type
    public func index(of type: TokenType, in range: CountableRange<Int>, if matches: (Token) -> Bool = { _ in true }) -> Int? {
        return index(in: range, where: { $0.is(type) }).flatMap { matches(tokens[$0]) ? $0 : nil }
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

    /// Returns the next token in the specified range of the specified type
    public func next(_ type: TokenType, in range: CountableRange<Int>, if matches: (Token) -> Bool = { _ in true }) -> Token? {
        return index(of: type, in: range, if: matches).map { tokens[$0] }
    }

    /// Returns the index of the last token in the specified range that matches the block
    public func lastIndex(in range: CountableRange<Int>, where matches: (Token) -> Bool) -> Int? {
        let range = range.clamped(to: 0 ..< tokens.count)
        var linebreakEncountered = false
        var scopeStack: [Token] = []
        for i in range.reversed() {
            let token = tokens[i]
            if case .startOfScope = token {
                if let scope = scopeStack.last, scope.isEndOfScope(token) {
                    scopeStack.removeLast()
                } else if token.string == "//", linebreakEncountered {
                    linebreakEncountered = false
                } else if matches(token) {
                    return i
                } else if token.string == "//", self.token(at: range.upperBound)?.isLinebreak == true {
                    continue
                } else {
                    return nil
                }
            } else if scopeStack.isEmpty, matches(token) {
                return i
            } else if case .linebreak = token {
                linebreakEncountered = true
            } else if case .endOfScope = token {
                scopeStack.append(token)
            }
        }
        return nil
    }

    /// Returns the index of the previous token at the current scope that matches the block
    public func index(before index: Int, where matches: (Token) -> Bool) -> Int? {
        guard index > 0 else { return nil }
        return lastIndex(in: 0 ..< index, where: matches)
    }

    /// Returns the index of the last matching token in the specified range
    public func lastIndex(of token: Token, in range: CountableRange<Int>) -> Int? {
        return lastIndex(in: range, where: { $0 == token })
    }

    /// Returns the index of the previous matching token at the current scope
    public func index(of token: Token, before index: Int) -> Int? {
        return self.index(before: index, where: { $0 == token })
    }

    /// Returns the index of the last token in the specified range of the specified type
    public func lastIndex(of type: TokenType, in range: CountableRange<Int>, if matches: (Token) -> Bool = { _ in true }) -> Int? {
        return lastIndex(in: range, where: { $0.is(type) }).flatMap { matches(tokens[$0]) ? $0 : nil }
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

    /// Returns the previous token in the specified range of the specified type
    public func last(_ type: TokenType, in range: CountableRange<Int>, if matches: (Token) -> Bool = { _ in true }) -> Token? {
        return lastIndex(of: type, in: range, if: matches).map { tokens[$0] }
    }

    /// Inserts a linebreak at the specified index
    public func insertLinebreak(at index: Int) {
        insertToken(linebreakToken(for: index), at: index)
    }

    /// Indicates if the given range contains any nontokens other than those allowed.
    ///
    /// - Note: The range does not need to include the given tokens to return `true`,
    ///         it just can't include any unallowed tokens.
    ///
    /// - Parameters:
    ///   - range: The range to check
    ///   - allowedTokens: The only tokens allowed in the range
    ///   - allowingWhitespaceAndComments:If spaces, linebreaks, and comments should also be allowed.
    public func range(_ range: CountableRange<Int>,
                      doesNotContainsTokensExcept allowedTokens: [Token],
                      allowingWhitespaceAndComments: Bool) -> Bool
    {
        let range = range.clamped(to: 0 ..< tokens.count)
        for token in tokens[range] {
            if allowedTokens.contains(token) ||
                (allowingWhitespaceAndComments && token.isSpaceOrCommentOrLinebreak)
            {
                continue
            }
            return false
        }
        return true
    }

    /// Returns the starting token for the containing scope at the specified index
    public func currentScope(at index: Int) -> Token? {
        return last(.startOfScope, before: index)
    }

    /// Returns the index of the ending token for the current scope
    // TODO: should this return the closing `}` for `switch { ...` instead of nested `case`?
    public func endOfScope(at index: Int) -> Int? {
        var startIndex: Int
        guard var startToken = token(at: index) else { return nil }
        if case .startOfScope = startToken {
            startIndex = index
        } else if let index = self.index(of: .startOfScope, before: index) {
            startToken = tokens[index]
            startIndex = index
        } else {
            return nil
        }
        guard startToken == .startOfScope("{") else {
            return self.index(after: startIndex, where: {
                $0.isEndOfScope(startToken)
            })
        }
        while let endIndex = self.index(after: startIndex, where: {
            $0.isEndOfScope(startToken)
        }), let token = token(at: endIndex) {
            if token == .endOfScope("}") {
                return endIndex
            }
            startIndex = endIndex
            startToken = token
        }
        return nil
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

    /// Returns the original line number at the specified index
    public func originalLine(at index: Int) -> OriginalLine {
        for token in tokens[0 ..< index].reversed() {
            if case let .linebreak(_, line) = token {
                return line + 1
            }
        }
        return 1
    }

    /// Returns a linebreak token suitable for insertion at the specified index
    public func linebreakToken(for index: Int) -> Token {
        let lineNumber: Int
        if case let .linebreak(_, index)? = token(at: index) {
            lineNumber = index
        } else {
            lineNumber = originalLine(at: index)
        }
        return .linebreak(options.linebreak, lineNumber)
    }
}
