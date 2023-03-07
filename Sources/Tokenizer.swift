//
//  Tokenizer.swift
//  SwiftFormat
//
//  Version 0.51.2
//
//  Created by Nick Lockwood on 11/08/2016.
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

// https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/LexicalStructure.html

// Used to speed up matching
// Note: Any, Self, self, super, nil, true and false have been omitted deliberately, as they
// behave like identifiers. So too have context-specific keywords such as the following:
// any, associativity, async, convenience, didSet, dynamic, final, get, indirect, infix, lazy,
// left, mutating, none, nonmutating, open, optional, override, postfix, precedence,
// prefix, Protocol, required, right, set, some, any, Type, unowned, weak, willSet
private let swiftKeywords = Set([
    "let", "return", "func", "var", "if", "public", "as", "else", "in", "import",
    "class", "try", "guard", "case", "for", "init", "extension", "private", "static",
    "fileprivate", "internal", "switch", "do", "catch", "enum", "struct", "throws",
    "throw", "typealias", "where", "break", "deinit", "subscript", "is", "while",
    "associatedtype", "inout", "continue", "operator", "repeat", "rethrows",
    "default", "protocol", "defer", "await", /* Any, Self, self, super, nil, true, false */
])

public extension String {
    /// Is this string a reserved keyword in Swift?
    var isSwiftKeyword: Bool {
        swiftKeywords.contains(self)
    }

    /// Is this string a valid operator?
    var isOperator: Bool {
        let tokens = tokenize(self)
        return tokens.count == 1 && tokens[0].isOperator
    }

    /// Is this string a comment directive (MARK:, TODO:, swiftlint:, etc)?
    var isCommentDirective: Bool {
        let parts = split(separator: ":")
        guard parts.count > 1 else {
            return false
        }
        return !parts[0].contains(" ")
    }
}

/// Classes of token used for matching
public enum TokenType {
    case space
    case linebreak
    case endOfStatement
    case startOfScope
    case endOfScope
    case keyword
    case delimiter
    case identifier
    case attribute
    case `operator`
    case unwrapOperator
    case rangeOperator
    case number
    case error

    // OR types
    case spaceOrComment
    case spaceOrLinebreak
    case spaceOrCommentOrLinebreak
    case identifierOrKeyword

    // NOT types
    case nonSpace
    case nonLinebreak
    case nonSpaceOrComment
    case nonSpaceOrLinebreak
    case nonSpaceOrCommentOrLinebreak
}

/// Numeric literal types
public enum NumberType {
    case integer
    case decimal
    case binary
    case octal
    case hex
}

/// Operator/operator types
public enum OperatorType {
    case none
    case infix
    case prefix
    case postfix
}

// Original line number for token
public typealias OriginalLine = Int

/// All token types
public enum Token: Equatable {
    case number(String, NumberType)
    case linebreak(String, OriginalLine)
    case startOfScope(String)
    case endOfScope(String)
    case delimiter(String)
    case `operator`(String, OperatorType)
    case stringBody(String)
    case keyword(String)
    case identifier(String)
    case space(String)
    case commentBody(String)
    case error(String)
}

private extension Token {
    /// Test if token matches type of another token
    func hasType(of token: Token) -> Bool {
        switch (self, token) {
        case (.number, .number),
             (.operator, .operator),
             (.linebreak, .linebreak),
             (.startOfScope, .startOfScope),
             (.endOfScope, .endOfScope),
             (.delimiter, .delimiter),
             (.keyword, .keyword),
             (.identifier, .identifier),
             (.stringBody, .stringBody),
             (.commentBody, .commentBody),
             (.space, .space),
             (.error, .error):
            return true
        case (.number, _),
             (.operator, _),
             (.linebreak, _),
             (.startOfScope, _),
             (.endOfScope, _),
             (.delimiter, _),
             (.keyword, _),
             (.identifier, _),
             (.stringBody, _),
             (.commentBody, _),
             (.space, _),
             (.error, _):
            return false
        }
    }

    struct StringDelimiterType {
        var isRegex: Bool
        var isMultiline: Bool
        var hashCount: Int
    }

    var stringDelimiterType: StringDelimiterType? {
        switch self {
        case let .startOfScope(string), let .endOfScope(string):
            var quoteCount = 0, hashCount = 0, slashCount = 0
            for c in string {
                switch c {
                case "#": hashCount += 1
                case "\"": quoteCount += 1
                case "/": slashCount += 1
                default: return nil
                }
            }
            let isRegex = slashCount == 1
            guard quoteCount > 0 || isRegex else {
                return nil
            }
            return StringDelimiterType(
                isRegex: isRegex,
                isMultiline: quoteCount == 3 || (isRegex && hashCount > 0),
                hashCount: hashCount
            )
        default:
            return nil
        }
    }
}

public extension Token {
    /// The original token string
    var string: String {
        switch self {
        case let .number(string, _),
             let .linebreak(string, _),
             let .startOfScope(string),
             let .endOfScope(string),
             let .delimiter(string),
             let .operator(string, _),
             let .stringBody(string),
             let .keyword(string),
             let .identifier(string),
             let .space(string),
             let .commentBody(string),
             let .error(string):
            return string
        }
    }

    /// Returns the width (in characters) of the token
    func columnWidth(tabWidth: Int) -> Int {
        switch self {
        case let .space(string), let .stringBody(string), let .commentBody(string):
            guard tabWidth > 1 else {
                return string.count
            }
            return string.reduce(0) { count, character in
                count + (character == "\t" ? tabWidth : 1)
            }
        case .linebreak:
            return 0
        default:
            return string.count
        }
    }

    /// Returns the unescaped token string
    func unescaped() -> String {
        switch self {
        case let .stringBody(string):
            var input = UnicodeScalarView(string.unicodeScalars)
            var output = String.UnicodeScalarView()
            while let c = input.popFirst() {
                if c == "\\" {
                    _ = input.readCharacters { $0 == "#" }
                    if let c = input.popFirst() {
                        switch c {
                        case "\0":
                            output.append("\0")
                        case "\\":
                            output.append("\\")
                        case "t":
                            output.append("\t")
                        case "n":
                            output.append("\n")
                        case "r":
                            output.append("\r")
                        case "\"":
                            output.append("\"")
                        case "\'":
                            output.append("\'")
                        case "u":
                            guard input.read("{"),
                                  let hex = input.readCharacters(where: { $0.isHexDigit }),
                                  input.read("}"),
                                  let codepoint = Int(hex, radix: 16),
                                  let c = UnicodeScalar(codepoint)
                            else {
                                // Invalid. Recover and continue
                                continue
                            }
                            output.append(c)
                        default:
                            // Invalid, but doesn't affect parsing
                            output.append(c)
                        }
                    } else {
                        // If a string body ends with \, it's probably part of a string
                        // interpolation expression, so the next token should be a `(`
                    }
                } else {
                    output.append(c)
                }
            }
            return String(output)
        case let .identifier(string):
            if string.hasPrefix("$") {
                return String(string.dropFirst())
            }
            return string.replacingOccurrences(of: "`", with: "")
        case let .number(string, .integer), let .number(string, .decimal):
            return string.replacingOccurrences(of: "_", with: "")
        case let .number(s, .binary), let .number(s, .octal), let .number(s, .hex):
            var characters = UnicodeScalarView(s.unicodeScalars)
            guard characters.read("0"), characters.readCharacter(where: {
                "oxb".unicodeScalars.contains($0)
            }) != nil else {
                return s.replacingOccurrences(of: "_", with: "")
            }
            return String(characters).replacingOccurrences(of: "_", with: "")
        default:
            return string
        }
    }

    /// Test if token is of the specified type
    func `is`(_ type: TokenType) -> Bool {
        switch type {
        case .space:
            return isSpace
        case .spaceOrComment:
            return isSpaceOrComment
        case .spaceOrLinebreak:
            return isSpaceOrLinebreak
        case .spaceOrCommentOrLinebreak:
            return isSpaceOrCommentOrLinebreak
        case .linebreak:
            return isLinebreak
        case .endOfStatement:
            return isEndOfStatement
        case .startOfScope:
            return isStartOfScope
        case .endOfScope:
            return isEndOfScope
        case .keyword:
            return isKeyword
        case .identifier:
            return isIdentifier
        case .identifierOrKeyword:
            return isIdentifierOrKeyword
        case .attribute:
            return isAttribute
        case .delimiter:
            return isDelimiter
        case .operator:
            return isOperator
        case .unwrapOperator:
            return isUnwrapOperator
        case .rangeOperator:
            return isRangeOperator
        case .number:
            return isNumber
        case .error:
            return isError
        case .nonSpace:
            return !isSpace
        case .nonLinebreak:
            return !isLinebreak
        case .nonSpaceOrComment:
            return !isSpaceOrComment
        case .nonSpaceOrLinebreak:
            return !isSpaceOrLinebreak
        case .nonSpaceOrCommentOrLinebreak:
            return !isSpaceOrCommentOrLinebreak
        }
    }

    var isAttribute: Bool { isKeyword && string.hasPrefix("@") }
    var isDelimiter: Bool { hasType(of: .delimiter("")) }
    var isOperator: Bool { hasType(of: .operator("", .none)) }
    var isUnwrapOperator: Bool { isOperator("?", .postfix) || isOperator("!", .postfix) }
    var isRangeOperator: Bool { isOperator("...") || isOperator("..<") }
    var isNumber: Bool { hasType(of: .number("", .integer)) }
    var isError: Bool { hasType(of: .error("")) }
    var isStartOfScope: Bool { hasType(of: .startOfScope("")) }
    var isEndOfScope: Bool { hasType(of: .endOfScope("")) }
    var isKeyword: Bool { hasType(of: .keyword("")) }
    var isIdentifier: Bool { hasType(of: .identifier("")) }
    var isIdentifierOrKeyword: Bool { isIdentifier || isKeyword }
    var isSpace: Bool { hasType(of: .space("")) }
    var isLinebreak: Bool { hasType(of: .linebreak("", 0)) }
    var isEndOfStatement: Bool { self == .delimiter(";") || isLinebreak }
    var isSpaceOrLinebreak: Bool { isSpace || isLinebreak }
    var isSpaceOrComment: Bool { isSpace || isComment }
    var isSpaceOrCommentOrLinebreak: Bool { isSpaceOrComment || isLinebreak }
    var isCommentOrLinebreak: Bool { isComment || isLinebreak }

    var isSwitchCaseOrDefault: Bool {
        if case let .endOfScope(string) = self {
            return ["case", "default"].contains(string)
        }
        return false
    }

    func isOperator(_ string: String) -> Bool {
        if case .operator(string, _) = self {
            return true
        }
        return false
    }

    func isOperator(ofType type: OperatorType) -> Bool {
        if case .operator(_, type) = self {
            return true
        }
        return false
    }

    func isOperator(_ string: String, _ type: OperatorType) -> Bool {
        if case .operator(string, type) = self {
            return true
        }
        return false
    }

    var isComment: Bool {
        switch self {
        case .commentBody,
             .startOfScope("//"),
             .startOfScope("/*"),
             .endOfScope("*/"):
            return true
        default:
            return false
        }
    }

    var isStringBody: Bool {
        switch self {
        case .stringBody:
            return true
        default:
            return false
        }
    }

    var isStringDelimiter: Bool {
        switch self {
        case let .startOfScope(string), let .endOfScope(string):
            return string.contains("\"") || string == "/" || string.hasSuffix("#")
                || (string.hasPrefix("#") && string.hasSuffix("/"))
        default:
            return false
        }
    }

    var isMultilineStringDelimiter: Bool {
        stringDelimiterType?.isMultiline == true
    }

    func isEndOfScope(_ token: Token) -> Bool {
        switch self {
        case let .endOfScope(closing):
            guard case let .startOfScope(opening) = token else {
                return false
            }
            switch opening {
            case "(":
                return closing == ")"
            case "[":
                return closing == "]"
            case "<":
                return closing == ">"
            case "{", ":":
                switch closing {
                case "}", "case", "default":
                    return true
                default:
                    return false
                }
            case "/*":
                return closing == "*/"
            case "#if":
                return closing == "#endif"
            default:
                if let delimiterType = stringDelimiterType {
                    let quotes = delimiterType.isRegex ? "/" : (
                        delimiterType.isMultiline ? "\"\"\"" : "\""
                    )
                    let hashes = String(repeating: "#", count: delimiterType.hashCount)
                    return closing == "\(quotes)\(hashes)"
                }
                return false
            }
        case .linebreak:
            switch token {
            case .startOfScope("//"), .startOfScope("#!"):
                return true
            default:
                return false
            }
        case .delimiter(":"), .startOfScope(":"):
            switch token {
            case .endOfScope("case"), .endOfScope("default"), .operator("?", .infix):
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
}

extension Token {
    var isLvalue: Bool {
        switch self {
        case .identifier, .number, .operator(_, .postfix),
             .endOfScope(")"), .endOfScope("]"),
             .endOfScope("}"), .endOfScope(">"),
             .endOfScope where isStringDelimiter:
            return true
        case let .keyword(name) where name.hasPrefix("#"):
            return true
        default:
            return false
        }
    }

    var isRvalue: Bool {
        switch self {
        case .operator(_, .infix), .operator(_, .postfix):
            return false
        case .identifier, .number, .operator,
             .startOfScope("("), .startOfScope("["), .startOfScope("{"),
             .startOfScope where isStringDelimiter:
            return true
        case let .keyword(name) where name.hasPrefix("#"):
            return true
        default:
            return false
        }
    }
}

extension Collection where Element == Token {
    var string: String {
        map { $0.string }.joined()
    }
}

extension UnicodeScalar {
    var isDigit: Bool { isdigit(Int32(value)) > 0 }
    var isHexDigit: Bool { isxdigit(Int32(value)) > 0 }
    var isSpace: Bool {
        switch value {
        case 0x0009, 0x0011, 0x0012, 0x0020,
             0x0085, 0x00A0, 0x1680, 0x2000 ... 0x200A,
             0x2028, 0x2029, 0x202F, 0x205F, 0x3000:
            return true
        default:
            return false
        }
    }
}

// Workaround for horribly slow String.UnicodeScalarView.Subsequence perf

private struct UnicodeScalarView {
    public typealias Index = String.UnicodeScalarView.Index

    private let characters: String.UnicodeScalarView
    public private(set) var startIndex: Index
    public private(set) var endIndex: Index

    public init(_ unicodeScalars: String.UnicodeScalarView) {
        characters = unicodeScalars
        startIndex = characters.startIndex
        endIndex = characters.endIndex
    }

    public init(_ unicodeScalars: String.UnicodeScalarView.SubSequence) {
        self.init(String.UnicodeScalarView(unicodeScalars))
    }

    public init(_ string: String) {
        self.init(string.unicodeScalars)
    }

    public var first: UnicodeScalar? {
        isEmpty ? nil : characters[startIndex]
    }

    @available(*, deprecated, message: "Really hurts performance - use a different approach")
    public var count: Int {
        characters.distance(from: startIndex, to: endIndex)
    }

    public var isEmpty: Bool {
        startIndex >= endIndex
    }

    public subscript(_ index: Index) -> UnicodeScalar {
        characters[index]
    }

    public func index(after index: Index) -> Index {
        characters.index(after: index)
    }

    public func prefix(upTo index: Index) -> UnicodeScalarView {
        var view = UnicodeScalarView(characters)
        view.startIndex = startIndex
        view.endIndex = index
        return view
    }

    public func suffix(from index: Index) -> UnicodeScalarView {
        var view = UnicodeScalarView(characters)
        view.startIndex = index
        view.endIndex = endIndex
        return view
    }

    public func dropFirst() -> UnicodeScalarView {
        var view = UnicodeScalarView(characters)
        view.startIndex = characters.index(after: startIndex)
        view.endIndex = endIndex
        return view
    }

    public mutating func popFirst() -> UnicodeScalar? {
        if isEmpty {
            return nil
        }
        let char = characters[startIndex]
        startIndex = characters.index(after: startIndex)
        return char
    }

    /// Will crash if n > remaining char count
    public mutating func removeFirst(_ n: Int) {
        startIndex = characters.index(startIndex, offsetBy: n)
    }

    /// Will crash if collection is empty
    @discardableResult
    public mutating func removeFirst() -> UnicodeScalar {
        let oldIndex = startIndex
        startIndex = characters.index(after: startIndex)
        return characters[oldIndex]
    }

    /// Returns the remaining characters
    fileprivate var unicodeScalars: String.UnicodeScalarView.SubSequence {
        characters[startIndex ..< endIndex]
    }
}

private typealias _UnicodeScalarView = UnicodeScalarView
private extension String {
    init(_ unicodeScalarView: _UnicodeScalarView) {
        self.init(unicodeScalarView.unicodeScalars)
    }
}

private extension String.UnicodeScalarView {
    init(_ unicodeScalarView: _UnicodeScalarView) {
        self.init(unicodeScalarView.unicodeScalars)
    }
}

private extension String.UnicodeScalarView.SubSequence {
    init(_ unicodeScalarView: _UnicodeScalarView) {
        self.init(unicodeScalarView.unicodeScalars)
    }
}

private extension UnicodeScalarView {
    mutating func readCharacters(where matching: (UnicodeScalar) -> Bool) -> String? {
        var index = startIndex
        while index < endIndex {
            if !matching(self[index]) {
                break
            }
            index = self.index(after: index)
        }
        if index > startIndex {
            let string = String(prefix(upTo: index))
            self = suffix(from: index)
            return string
        }
        return nil
    }

    mutating func read(head: (UnicodeScalar) -> Bool, tail: (UnicodeScalar) -> Bool) -> String? {
        if let c = first, head(c) {
            var index = self.index(after: startIndex)
            while index < endIndex {
                if !tail(self[index]) {
                    break
                }
                index = self.index(after: index)
            }
            let string = String(prefix(upTo: index))
            self = suffix(from: index)
            return string
        }
        return nil
    }

    mutating func readCharacter(where matching: (UnicodeScalar) -> Bool) -> UnicodeScalar? {
        if let c = first, matching(c) {
            self = dropFirst()
            return c
        }
        return nil
    }

    mutating func read(_ character: UnicodeScalar) -> Bool {
        if first == character {
            self = dropFirst()
            return true
        }
        return false
    }

    mutating func readString(_ string: String) -> Bool {
        let scalars = string.unicodeScalars
        var index = startIndex
        for c in scalars {
            guard index < endIndex, self[index] == c else {
                return false
            }
            index = self.index(after: index)
        }
        removeFirst(scalars.count)
        return true
    }

    mutating func readToEndOfToken() -> String {
        readCharacters { !$0.isSpace && !"\n\r".unicodeScalars.contains($0) } ?? ""
    }
}

private extension UnicodeScalarView {
    mutating func parseSpace() -> Token? {
        readCharacters(where: { $0.isSpace }).map { .space($0) }
    }

    mutating func parseLineBreak() -> Token? {
        if read("\r") {
            if read("\n") {
                return .linebreak("\r\n", 0)
            }
            return .linebreak("\r", 0)
        }
        return read("\n") ? .linebreak("\n", 0) : nil
    }

    mutating func parseDelimiter() -> Token? {
        readCharacter(where: {
            ":;,".unicodeScalars.contains($0)
        }).map { .delimiter(String($0)) }
    }

    mutating func parseStartOfString() -> Token? {
        guard read("\"") else {
            return nil
        }
        let start = self
        if readString("\"\"") {
            if first != "#" {
                return .startOfScope("\"\"\"")
            }
            self = start
        }
        return .startOfScope("\"")
    }

    mutating func parseStartOfScope() -> Token? {
        parseStartOfString() ?? readCharacter(where: {
            "<([{".unicodeScalars.contains($0)
        }).map { .startOfScope(String($0)) }
    }

    mutating func parseEndOfScope() -> Token? {
        readCharacter(where: {
            "}])>".unicodeScalars.contains($0)
        }).map { .endOfScope(String($0)) }
    }

    mutating func parseOperator() -> Token? {
        func isHead(_ c: UnicodeScalar) -> Bool {
            if "./\\=­-+!*%&|^~?".unicodeScalars.contains(c) {
                return true
            }
            switch c.value {
            case 0x00A1 ... 0x00A7,
                 0x00A9, 0x00AB, 0x00AC, 0x00AE,
                 0x00B0 ... 0x00B1,
                 0x00B6, 0x00BB, 0x00BF, 0x00D7, 0x00F7,
                 0x2016 ... 0x2017,
                 0x2020 ... 0x2027,
                 0x2030 ... 0x203E,
                 0x2041 ... 0x2053,
                 0x2055 ... 0x205E,
                 0x2190 ... 0x23FF,
                 0x2500 ... 0x2775,
                 0x2794 ... 0x2BFF,
                 0x2E00 ... 0x2E7F,
                 0x3001 ... 0x3003,
                 0x3008 ... 0x3030:
                return true
            default:
                return false
            }
        }

        func isTail(_ c: UnicodeScalar) -> Bool {
            if isHead(c) {
                return true
            }
            switch c.value {
            case 0x0300 ... 0x036F,
                 0x1DC0 ... 0x1DFF,
                 0x20D0 ... 0x20FF,
                 0xFE00 ... 0xFE0F,
                 0xFE20 ... 0xFE2F,
                 0xE0100 ... 0xE01EF:
                return true
            default:
                return c == ">"
            }
        }

        var start = self
        if var tail = readCharacter(where: isHead) {
            switch tail {
            case "/" where !["*", "/"].contains(first), "?", "!", "\\":
                return .operator(String(tail), .none)
            default:
                start = self
            }
            var head = ""
            // Tail may only contain dot if head does
            let headWasDot = (tail == ".")
            while let c = readCharacter(where: { isTail($0) && (headWasDot || $0 != ".") }) {
                if tail == "/" {
                    switch c {
                    case "*":
                        if head == "" {
                            return .startOfScope("/*")
                        }
                        // Can't return two tokens, so put /* back to be parsed next time
                        self = start
                        return .operator(head, .none)
                    case "/":
                        if head == "" {
                            return .startOfScope("//")
                        }
                        // Can't return two tokens, so put // back to be parsed next time
                        self = start
                        return .operator(head, .none)
                    default:
                        break
                    }
                }
                if c != "/" {
                    start = self
                }
                head.append(Character(tail))
                tail = c
            }
            head.append(Character(tail))
            return .operator(head, .none)
        }
        return nil
    }

    mutating func parseIdentifier() -> Token? {
        func isHead(_ c: UnicodeScalar) -> Bool {
            switch c.value {
            case 0x41 ... 0x5A, // A-Z
                 0x61 ... 0x7A, // a-z
                 0x5F, 0x24, // _ and $
                 0x00A8, 0x00AA, 0x00AD, 0x00AF,
                 0x00B2 ... 0x00B5,
                 0x00B7 ... 0x00BA,
                 0x00BC ... 0x00BE,
                 0x00C0 ... 0x00D6,
                 0x00D8 ... 0x00F6,
                 0x00F8 ... 0x00FF,
                 0x0100 ... 0x02FF,
                 0x0370 ... 0x167F,
                 0x1681 ... 0x180D,
                 0x180F ... 0x1DBF,
                 0x1E00 ... 0x1FFF,
                 0x200B ... 0x200D,
                 0x202A ... 0x202E,
                 0x203F ... 0x2040,
                 0x2054,
                 0x2060 ... 0x206F,
                 0x2070 ... 0x20CF,
                 0x2100 ... 0x218F,
                 0x2460 ... 0x24FF,
                 0x2776 ... 0x2793,
                 0x2C00 ... 0x2DFF,
                 0x2E80 ... 0x2FFF,
                 0x3004 ... 0x3007,
                 0x3021 ... 0x302F,
                 0x3031 ... 0x303F,
                 0x3040 ... 0xD7FF,
                 0xF900 ... 0xFD3D,
                 0xFD40 ... 0xFDCF,
                 0xFDF0 ... 0xFE1F,
                 0xFE30 ... 0xFE44,
                 0xFE47 ... 0xFFFD,
                 0x10000 ... 0x1FFFD,
                 0x20000 ... 0x2FFFD,
                 0x30000 ... 0x3FFFD,
                 0x40000 ... 0x4FFFD,
                 0x50000 ... 0x5FFFD,
                 0x60000 ... 0x6FFFD,
                 0x70000 ... 0x7FFFD,
                 0x80000 ... 0x8FFFD,
                 0x90000 ... 0x9FFFD,
                 0xA0000 ... 0xAFFFD,
                 0xB0000 ... 0xBFFFD,
                 0xC0000 ... 0xCFFFD,
                 0xD0000 ... 0xDFFFD,
                 0xE0000 ... 0xEFFFD:
                return true
            default:
                return false
            }
        }

        func isTail(_ c: UnicodeScalar) -> Bool {
            switch c.value {
            case 0x30 ... 0x39, // 0-9
                 0x0300 ... 0x036F,
                 0x1DC0 ... 0x1DFF,
                 0x20D0 ... 0x20FF,
                 0xFE20 ... 0xFE2F:
                return true
            default:
                return isHead(c)
            }
        }

        func readIdentifier() -> String? {
            read(head: isHead, tail: isTail)
        }

        let start = self
        if read("`") {
            if let identifier = readIdentifier(), read("`") {
                return .identifier("`" + identifier + "`")
            }
            self = start
        } else if read("<") {
            if read("#") {
                // look for closing Xcode token
                var previousWasHash = false
                var index = startIndex
                var found = false
                while index < endIndex {
                    let idx = index
                    index = self.index(after: index)
                    if self[idx] == ">" {
                        if previousWasHash {
                            found = true
                            break
                        }
                    } else {
                        previousWasHash = self[idx] == "#"
                    }
                }
                if found {
                    let string = String(prefix(upTo: index))
                    self = suffix(from: index)
                    return .identifier("<#\(string)")
                }
            }
            self = start
        } else if read("#") {
            if let identifier = readIdentifier() {
                if identifier == "if" {
                    return .startOfScope("#if")
                }
                if identifier == "endif" {
                    return .endOfScope("#endif")
                }
                return .keyword("#" + identifier)
            }
            let hashes = readCharacters { $0 == "#" } ?? ""
            if case let .startOfScope(quotes)? = parseStartOfString() {
                return .startOfScope("#" + hashes + quotes)
            }
            if read("/") {
                return .startOfScope("#\(hashes)/")
            }
            self = start
        } else if read("@") {
            if let identifier = readIdentifier() {
                return .keyword("@" + identifier)
            }
            self = start
        } else if let identifier = readIdentifier() {
            return identifier.isSwiftKeyword ? .keyword(identifier) : .identifier(identifier)
        }
        return nil
    }

    mutating func parseNumber() -> Token? {
        func readNumber(where head: @escaping (UnicodeScalar) -> Bool) -> String? {
            read(head: head, tail: { head($0) || $0 == "_" })
        }

        func readInteger() -> String? {
            readNumber(where: { $0.isDigit })
        }

        func readHex() -> String? {
            readNumber(where: { $0.isHexDigit })
        }

        func readSign() -> String {
            readCharacter(where: { "-+".unicodeScalars.contains($0) }).map { String($0) } ?? ""
        }

        guard let integer = readInteger() else {
            return nil
        }

        if integer == "0" {
            if read("x") {
                if let hex = readHex() {
                    if let p = readCharacter(where: { "pP".unicodeScalars.contains($0) }) {
                        let sign = readSign()
                        if let power = readInteger() {
                            return .number("0x\(hex)\(p)\(sign)\(power)", .hex)
                        }
                        return .error("0x\(hex)\(p)\(readToEndOfToken())")
                    }
                    let endOfHex = self
                    if read("."), let fraction = readHex() {
                        if let p = readCharacter(where: { "pP".unicodeScalars.contains($0) }) {
                            let sign = readSign()
                            if let power = readInteger() {
                                return .number("0x\(hex).\(fraction)\(p)\(sign)\(power)", .hex)
                            }
                            return .error("0x\(hex).\(fraction)\(p)\(readToEndOfToken())")
                        }
                        if fraction.unicodeScalars.first?.isDigit == true {
                            return .error("0x\(hex).\(fraction)\(readToEndOfToken())")
                        }
                    }
                    self = endOfHex
                    return .number("0x\(hex)", .hex)
                }
                return .error("0x" + readToEndOfToken())
            } else if read("b") {
                if let bin = readNumber(where: { "01".unicodeScalars.contains($0) }) {
                    return .number("0b\(bin)", .binary)
                }
                return .error("0b" + readToEndOfToken())
            } else if read("o") {
                if let octal = readNumber(where: { ("0" ... "7").contains($0) }) {
                    return .number("0o\(octal)", .octal)
                }
                return .error("0o" + readToEndOfToken())
            }
        }

        var type: NumberType
        var number: String
        let endOfInt = self
        if read("."), let fraction = readInteger() {
            type = .decimal
            number = integer + "." + fraction
        } else {
            self = endOfInt
            type = .integer
            number = integer
        }

        let endOfFloat = self
        if let e = readCharacter(where: { "eE".unicodeScalars.contains($0) }) {
            let sign = readSign()
            if let exponent = readInteger() {
                type = .decimal
                number += String(e) + sign + exponent
            } else {
                self = endOfFloat
            }
        }

        return .number(number, type)
    }

    mutating func parseToken() -> Token? {
        // Have to split into groups for Swift to be able to process this
        if let token = parseSpace() ??
            parseLineBreak() ??
            parseNumber() ??
            parseIdentifier()
        {
            return token
        }
        if let token = parseOperator() ??
            parseDelimiter() ??
            parseStartOfScope() ??
            parseEndOfScope()
        {
            return token
        }
        if !isEmpty {
            return .error(readToEndOfToken())
        }
        return nil
    }
}

public func tokenize(_ source: String) -> [Token] {
    var scopeIndexStack: [Int] = []
    var tokens: [Token] = []
    var characters = UnicodeScalarView(source.unicodeScalars)
    var closedGenericScopeIndexes: [Int] = []
    var lineNumber = 1

    func processLinebreak(_ char: UnicodeScalar) {
        if char == "\r", characters.read("\n") {
            tokens.append(.linebreak("\r\n", lineNumber))
        } else {
            assert(char == "\n")
            tokens.append(.linebreak("\n", lineNumber))
        }
        lineNumber += 1
    }

    func processStringBody(_ delimiterType: Token.StringDelimiterType) {
        let regex = delimiterType.isRegex, hashCount = delimiterType.hashCount
        if delimiterType.isMultiline {
            processMultilineStringBody(regex: regex, hashCount: hashCount)
        } else {
            processStringBody(regex: regex, hashCount: hashCount)
        }
    }

    func processStringBody(regex: Bool, hashCount: Int) {
        var string = ""
        var escaped = false
        let hashes = String(repeating: "#", count: hashCount)
        let delimiter: UnicodeScalar = regex ? "/" : "\""
        while let c = characters.popFirst() {
            switch c {
            case "\\" where !escaped && characters.readString(hashes):
                escaped = true
                string.append("\\" + hashes)
                continue
            case delimiter where !escaped && characters.readString(hashes):
                if string != "" {
                    tokens.append(.stringBody(string))
                }
                tokens.append(.endOfScope("\(delimiter)\(hashes)"))
                scopeIndexStack.removeLast()
                return
            case "(" where escaped && !regex:
                if string != "" {
                    tokens.append(.stringBody(string))
                }
                scopeIndexStack.append(tokens.count)
                tokens.append(.startOfScope("("))
                return
            case "\r", "\n":
                if string != "" {
                    tokens.append(.stringBody(string))
                }
                tokens.append(.error(""))
                processLinebreak(c)
                if !regex {
                    scopeIndexStack.removeLast()
                }
                return
            default:
                escaped = false
            }
            string.append(Character(c))
        }
        if string != "" {
            tokens.append(.stringBody(string))
        }
    }

    func processMultilineStringBody(regex: Bool, hashCount: Int) {
        var string = ""
        var escaped = false
        let hashes = String(repeating: "#", count: hashCount)
        let delimiter: UnicodeScalar = regex ? "/" : "\""
        let terminator = regex ? hashes : "\"\"\(hashes)"
        while let c = characters.popFirst() {
            switch c {
            case "\\" where !escaped && characters.readString(hashes):
                escaped = true
                string.append("\\" + hashes)
                continue
            case delimiter where !escaped && characters.readString(terminator):
                if !string.isEmpty {
                    if regex {
                        tokens.append(.stringBody(string))
                    } else {
                        tokens.append(.error(string)) // Not permitted by the spec
                    }
                    string = ""
                }
                var offsetStack = [""]
                if case let .space(offset) = tokens.last! {
                    offsetStack[0] = offset
                }
                // Fix up indents
                for index in (scopeIndexStack.last! ..< tokens.count - 1).reversed() {
                    let nextToken = tokens[index + 1]
                    guard case let .space(indent) = tokens[index], tokens[index - 1].isLinebreak,
                          (nextToken.isMultilineStringDelimiter && nextToken.isEndOfScope) ||
                          nextToken.isStringBody
                    else {
                        if nextToken.isMultilineStringDelimiter, nextToken.isStartOfScope {
                            offsetStack.removeLast()
                        }
                        continue
                    }
                    if nextToken.isMultilineStringDelimiter, nextToken.isEndOfScope {
                        offsetStack.append(indent)
                    }
                    let offset = offsetStack.last ?? ""
                    guard offset.isEmpty || indent.hasPrefix(offset) else {
                        tokens[index] = .error(indent) // Mismatched whitespace
                        break
                    }
                    let remainder = String(indent[offset.endIndex ..< indent.endIndex])
                    if case let .stringBody(body) = nextToken {
                        tokens[index + 1] = .stringBody(remainder + body)
                    } else if !remainder.isEmpty {
                        tokens.insert(.stringBody(remainder), at: index + 1)
                    }
                    if offset.isEmpty {
                        tokens.remove(at: index)
                    } else {
                        tokens[index] = .space(offset)
                    }
                }
                tokens.append(.endOfScope("\(delimiter)\(terminator)"))
                scopeIndexStack.removeLast()
                return
            case "(" where escaped && !regex:
                if string != "" {
                    tokens.append(.stringBody(string))
                }
                scopeIndexStack.append(tokens.count)
                tokens.append(.startOfScope("("))
                return
            case "\r", "\n":
                if string != "" {
                    tokens.append(.stringBody(string))
                    string = ""
                }
                processLinebreak(c)
                if let space = characters.parseSpace() {
                    tokens.append(space)
                }
                escaped = false
                continue
            default:
                escaped = false
            }
            string.append(Character(c))
        }
        if string != "" {
            tokens.append(.stringBody(string))
        }
    }

    var comment = ""
    var space = ""

    func flushCommentBodyTokens() {
        if comment != "" {
            tokens.append(.commentBody(comment))
            comment = ""
        }
        if space != "" {
            tokens.append(.space(space))
            space = ""
        }
    }

    func processCommentBody() {
        while let c = characters.readCharacter(where: { !"\r\n".unicodeScalars.contains($0) }) {
            if c.isSpace {
                space.append(Character(c))
                continue
            }
            if space != "" {
                if comment == "" {
                    tokens.append(.space(space))
                } else {
                    comment += space
                }
                space = ""
            }
            comment.append(Character(c))
        }
        flushCommentBodyTokens()
    }

    func processMultilineCommentBody() {
        while let c = characters.popFirst() {
            switch c {
            case "/" where characters.read("*"):
                flushCommentBodyTokens()
                scopeIndexStack.append(tokens.count)
                tokens.append(.startOfScope("/*"))
                continue
            case "*" where characters.read("/"):
                flushCommentBodyTokens()
                tokens.append(.endOfScope("*/"))
                // Fix up indents
                var baseIndent = ""
                let range = scopeIndexStack.last! + 1 ..< tokens.count - 1
                for index in range where tokens[index - 1].isLinebreak {
                    if case let .space(indent) = tokens[index] {
                        switch tokens[index + 1] {
                        case .commentBody, .endOfScope("*/"):
                            if baseIndent.isEmpty || indent.count < baseIndent.count {
                                baseIndent = indent
                            }
                        default:
                            break
                        }
                    } else if case .commentBody = tokens[index] {
                        baseIndent = ""
                        break
                    }
                }
                for index in range.reversed() {
                    guard case let .space(indent) = tokens[index], tokens[index - 1].isLinebreak,
                          indent.hasPrefix(baseIndent)
                    else {
                        continue
                    }
                    switch tokens[index + 1] {
                    case let .commentBody(body):
                        tokens[index + 1] = .commentBody(indent.dropFirst(baseIndent.count) + body)
                    case .startOfScope("/*"), .endOfScope("*/"):
                        if indent.count > baseIndent.count {
                            tokens.insert(.commentBody(String(indent.dropFirst(baseIndent.count))),
                                          at: index + 1)
                        }
                    default:
                        continue
                    }
                    if baseIndent.isEmpty {
                        tokens.remove(at: index)
                    } else {
                        tokens[index] = .space(baseIndent)
                    }
                }
                scopeIndexStack.removeLast()
                if scopeIndexStack.last == nil || tokens[scopeIndexStack.last!] != .startOfScope("/*") {
                    return
                }
                continue
            case "\r", "\n":
                flushCommentBodyTokens()
                processLinebreak(c)
                continue
            default:
                if c.isSpace {
                    space.append(Character(c))
                    continue
                }
            }
            if space != "" {
                if comment == "" {
                    tokens.append(.space(space))
                } else {
                    comment += space
                }
                space = ""
            }
            comment.append(Character(c))
        }
        // We shouldn't actually get here, unless code is malformed
        flushCommentBodyTokens()
    }

    func convertOpeningChevronToOperator(at index: Int) {
        assert(tokens[index] == .startOfScope("<"))
        if let stackIndex = scopeIndexStack.lastIndex(of: index) {
            scopeIndexStack.remove(at: stackIndex)
        }
        tokens[index] = .operator("<", .none)
        stitchOperators(at: index)
    }

    func convertClosingChevronToOperator(at i: Int, andOpeningChevron: Bool) {
        assert(tokens[i] == .endOfScope(">"))
        tokens[i] = .operator(">", .none)
        stitchOperators(at: i)
        if let previousIndex = index(of: .nonSpaceOrComment, before: i),
           tokens[previousIndex] == .endOfScope(">")
        {
            convertClosingChevronToOperator(at: previousIndex, andOpeningChevron: true)
        }
        if andOpeningChevron, let scopeIndex = closedGenericScopeIndexes.last {
            closedGenericScopeIndexes.removeLast()
            convertOpeningChevronToOperator(at: scopeIndex)
        }
    }

    func isUnwrapOperator(at index: Int) -> Bool {
        let token = tokens[index]
        if case let .operator(string, _) = token, ["?", "!"].contains(string), index > 0 {
            let token = tokens[index - 1]
            return !token.isSpaceOrLinebreak && !token.isStartOfScope
        }
        return false
    }

    func stitchOperators(at index: Int) {
        guard case var .operator(string, _) = tokens[index] else {
            assertionFailure()
            return
        }
        while let nextToken: Token = index + 1 < tokens.count ? tokens[index + 1] : nil,
              case let .operator(nextString, _) = nextToken, !nextString.hasPrefix("\\"),
              string.hasPrefix(".") || !nextString.contains(".")
        {
            if scopeIndexStack.last == index {
                // In case of a ? previously interpreted as a ternary
                scopeIndexStack.removeLast()
            }
            string += nextString
            tokens[index ... index + 1] = [.operator(string, .none)]
            scopeIndexStack = scopeIndexStack.map { $0 > index ? $0 - 1 : $0 }
        }
        var index = index
        while let prevToken: Token = index > 0 ? tokens[index - 1] : nil,
              case let .operator(prevString, _) = prevToken, !isUnwrapOperator(at: index - 1),
              !string.hasPrefix("\\"), prevString.hasPrefix(".") || !string.contains(".")
        {
            if scopeIndexStack.last == index - 1 {
                // In case of a ? previously interpreted as a ternary
                scopeIndexStack.removeLast()
            }
            string = prevString + string
            tokens[index - 1 ... index] = [.operator(string, .none)]
            scopeIndexStack = scopeIndexStack.map { $0 > index ? $0 - 1 : $0 }
            index -= 1
        }
        setOperatorType(at: index)
        // Fix ternary that may not have been correctly closed in the first pass
        if let scopeIndex = scopeIndexStack.last, tokens[scopeIndex] == .operator("?", .infix) {
            for i in index ..< tokens.count where tokens[i] == .delimiter(":") {
                tokens[i] = .operator(":", .infix)
                scopeIndexStack.removeLast()
                break
            }
        }
    }

    func setOperatorType(at i: Int) {
        let token = tokens[i]
        guard case let .operator(string, currentType) = token else {
            assertionFailure()
            return
        }
        guard let prevNonSpaceIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: i) else {
            if tokens.count > i + 1 {
                tokens[i] = string == "/" ? .startOfScope("/") : .operator(string, .prefix)
            }
            return
        }
        let prevNonSpaceToken = tokens[prevNonSpaceIndex]
        switch prevNonSpaceToken {
        case .keyword("func"), .keyword("operator"):
            tokens[i] = .operator(string, .none)
            return
        default:
            break
        }
        let prevToken: Token = tokens[i - 1]
        let type: OperatorType
        switch string {
        case ":", "=", "->":
            type = .infix
        case ".":
            type = prevNonSpaceToken.isLvalue || prevNonSpaceToken.isAttribute ||
                prevNonSpaceToken == .endOfScope("#endif") ? .infix : .prefix
        case "?":
            if prevToken.isSpaceOrCommentOrLinebreak {
                // ? is a ternary operator, treat it as the start of a scope
                if currentType != .infix {
                    assert(scopeIndexStack.last ?? -1 < i)
                    scopeIndexStack.append(i) // TODO: should we be doing this here?
                }
                type = .infix
            } else if !prevToken.isStartOfScope {
                type = .postfix
            } else {
                type = .none
            }
        case "!" where !prevToken.isSpaceOrCommentOrLinebreak && !prevToken.isStartOfScope:
            type = .postfix
        default:
            guard let nextNonSpaceToken =
                index(of: .nonSpaceOrCommentOrLinebreak, after: i).map({ tokens[$0] })
            else {
                if prevToken.isLvalue {
                    type = .postfix
                    break
                }
                if token == .operator("/", .none),
                   prevNonSpaceToken.isOperator(ofType: .infix) || (
                       prevNonSpaceToken.isUnwrapOperator &&
                           prevNonSpaceIndex > 0 &&
                           tokens[prevNonSpaceIndex - 1] == .keyword("try")
                   ) || [
                       .startOfScope("("), .startOfScope("["),
                       .delimiter(":"), .delimiter(","),
                       .keyword("try"), .keyword("await"),
                   ].contains(prevNonSpaceToken)
                {
                    tokens[i] = .startOfScope("/")
                }
                return
            }
            let nextToken: Token = tokens[i + 1]
            if nextToken.isRvalue {
                type = prevToken.isLvalue ? .infix : .prefix
            } else if prevToken.isLvalue {
                type = .postfix
            } else if prevToken.isSpaceOrCommentOrLinebreak, prevNonSpaceToken.isLvalue,
                      nextToken.isSpaceOrCommentOrLinebreak, nextNonSpaceToken.isRvalue
            {
                type = .infix
            } else {
                // TODO: should we add an `identifier` type?
                return
            }
        }
        if type == .prefix, prevNonSpaceToken == .endOfScope(">") {
            convertClosingChevronToOperator(at: prevNonSpaceIndex, andOpeningChevron: true)
        }
        tokens[i] = .operator(string, type)
    }

    func index(of type: TokenType, before index: Int) -> Int? {
        var index = index - 1
        while index >= 0 {
            if tokens[index].is(type) {
                return index
            }
            index -= 1
        }
        return nil
    }

    func index(of type: TokenType, after index: Int) -> Int? {
        var index = index + 1
        while index < tokens.count {
            if tokens[index].is(type) {
                return index
            }
            index += 1
        }
        return nil
    }

    func processToken() {
        var count = tokens.count
        var token = tokens[count - 1]
        switch token {
        case let .keyword(name):
            if let prevIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: count - 1),
               tokens[prevIndex].isOperator(".") || (name == "await" && [
                   .keyword("func"), .keyword("let"), .keyword("var"),
                   .keyword("class"), .keyword("struct"), .keyword("enum"),
                   .keyword("extension"), .keyword("typealias"),
               ].contains(tokens[prevIndex]))
            {
                tokens[tokens.count - 1] = .identifier(name)
                processToken()
                return
            }
            if count > 1, case .number = tokens[count - 2] {
                tokens[count - 1] = .error(token.string)
            }
        case .identifier:
            if let prevIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: count - 1),
               case .identifier("actor") = tokens[prevIndex],
               case let prevPrevIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: prevIndex),
               prevPrevIndex.map({ tokens[$0].isOperator(ofType: .infix) }) != true
            {
                tokens[prevIndex] = .keyword("actor")
                processToken()
                return
            }
            if count > 1, case .number = tokens[count - 2] {
                tokens[count - 1] = .error(token.string)
            }
        case let .number(string, _) where count > 1:
            switch tokens[count - 2] {
            case .number:
                tokens[count - 1] = .error(string)
            case .operator(".", _):
                tokens[count - 1] = .identifier(string)
            default:
                break
            }
        case .operator:
            stitchOperators(at: count - 1)
        case .startOfScope("<") where count >= 2:
            if tokens[count - 2].isOperator,
               index(of: .nonSpaceOrCommentOrLinebreak, before: count - 2).map({
                   ![.keyword("func"), .keyword("init")].contains(tokens[$0])
               }) ?? true
            {
                tokens[tokens.count - 1] = .operator("<", .none)
                stitchOperators(at: count - 1)
                processToken()
                return
            }
            fallthrough
        case .startOfScope:
            closedGenericScopeIndexes.removeAll()
        case let .linebreak(string, line):
            if line == 0 {
                tokens[count - 1] = .linebreak(string, lineNumber)
                lineNumber += 1
            } else {
                lineNumber = line + 1
            }
        default:
            break
        }
        if !token.isSpaceOrCommentOrLinebreak {
            if let prevIndex = index(of: .nonSpaceOrComment, before: count - 1),
               case .endOfScope(">") = tokens[prevIndex]
            {
                // Fix up misidentified generic that is actually a pair of operators
                switch token {
                case .operator("=", _) where prevIndex == count - 2:
                    guard let startIndex = index(of: .startOfScope, before: count - 1),
                          tokens[startIndex] == .startOfScope("<"),
                          let prevIndex = index(of: .nonSpaceOrComment, before: startIndex),
                          case .identifier = tokens[prevIndex],
                          let prevPrevIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: prevIndex),
                          tokens[prevPrevIndex] == .delimiter(":")
                    else {
                        fallthrough
                    }
                case .identifier:
                    guard let scopeIndex = closedGenericScopeIndexes.first,
                          let prevIndex = index(of: .nonSpaceOrComment, before: scopeIndex),
                          tokens[prevIndex].isAttribute
                    else {
                        fallthrough
                    }
                case .startOfScope where token.isStringDelimiter, .number:
                    convertClosingChevronToOperator(at: prevIndex, andOpeningChevron: true)
                    processToken()
                    return
                default:
                    break
                }
            }
            if let lastOperatorIndex = index(of: .operator, before: count - 1) {
                // Set operator type
                setOperatorType(at: lastOperatorIndex)
            }
        }
        // Handle scope
        if let scopeIndex = scopeIndexStack.last {
            let scope = tokens[scopeIndex]
            if token.isEndOfScope(scope) {
                scopeIndexStack.removeLast()
                switch token {
                case .delimiter(":"):
                    if case .operator("?", .infix) = scope {
                        tokens[tokens.count - 1] = .operator(":", .infix)
                    } else {
                        tokens[tokens.count - 1] = .startOfScope(":")
                        scopeIndexStack.append(tokens.count - 1)
                    }
                case .endOfScope("case"), .endOfScope("default"):
                    scopeIndexStack.append(tokens.count - 1)
                case .endOfScope(")"):
                    guard let scope = scopeIndexStack.last.map({ tokens[$0] }) else {
                        break
                    }
                    if let delimiterType = scope.stringDelimiterType {
                        processStringBody(delimiterType)
                    }
                case .endOfScope(">"):
                    if scope == .startOfScope("<"), scopeIndex == count - 2 {
                        convertOpeningChevronToOperator(at: count - 2)
                        processToken()
                        return
                    }
                default:
                    break
                }
                if token == .endOfScope(">") {
                    closedGenericScopeIndexes.insert(scopeIndex, at: 0)
                } else {
                    closedGenericScopeIndexes.removeAll()
                }
                return
            } else if let scopeIndex = scopeIndexStack.last(where: {
                tokens[$0] == .startOfScope("<")
            }) {
                // We think it's a generic at this point, but could be wrong
                switch token {
                case let .operator(string, _):
                    switch string {
                    case ".", "==", "?", "!", "&", "->":
                        if index(of: .nonSpaceOrCommentOrLinebreak, before: count - 1) == scopeIndex {
                            // These are allowed in a generic, but not as the first character
                            fallthrough
                        }
                    default:
                        // Not a generic scope
                        convertOpeningChevronToOperator(at: scopeIndex)
                    }
                case .delimiter(":") where scopeIndexStack.count > 1 &&
                    [.endOfScope("case"), .operator("?", .infix)].contains(tokens[scopeIndexStack[scopeIndexStack.count - 2]]
                    ):
                    // Not a generic scope
                    convertOpeningChevronToOperator(at: scopeIndex)
                    processToken()
                    return
                case .keyword("where"):
                    break
                case .endOfScope, .keyword:
                    // If we encountered a keyword, or closing scope token that wasn't >
                    // then the opening < must have been an operator after all
                    convertOpeningChevronToOperator(at: scopeIndex)
                    processToken()
                    return
                default:
                    break
                }
            } else if token == .delimiter(":") {
                if [.startOfScope("("), .startOfScope("[")].contains(scope),
                   let prevIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: count - 1),
                   tokens[prevIndex].isIdentifierOrKeyword
                {
                    if case let .keyword(name) = tokens[prevIndex] {
                        tokens[prevIndex] = .identifier(name)
                    }
                    if let prevPrevIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: prevIndex),
                       case let .keyword(name) = tokens[prevPrevIndex]
                    {
                        tokens[prevPrevIndex] = .identifier(name)
                    }
                }
            } else if case let .keyword(string) = token {
                var scope = scope
                var scopeIndex = scopeIndex
                var scopeStackIndex = scopeIndexStack.count - 1
                while scopeStackIndex > 0, scope == .startOfScope("#if") {
                    scopeStackIndex -= 1
                    scopeIndex = scopeIndexStack[scopeStackIndex]
                    scope = tokens[scopeIndex]
                }
                if [.startOfScope("{"), .startOfScope(":")].contains(scope) {
                    switch string {
                    case "default":
                        tokens[tokens.count - 1] = .endOfScope(string)
                        processToken()
                        return
                    case "case":
                        if let keywordIndex = index(of: .keyword, before: scopeIndex) {
                            var keyword = tokens[keywordIndex]
                            if keyword == .keyword("where"),
                               let keywordIndex = index(of: .keyword, before: keywordIndex)
                            {
                                keyword = tokens[keywordIndex]
                            }
                            if keyword.isAttribute,
                               let keywordIndex = index(of: .keyword, before: keywordIndex)
                            {
                                keyword = tokens[keywordIndex]
                            }
                            if case .keyword("enum") = keyword {
                                break
                            }
                        }
                        if let prevIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: count - 1) {
                            switch tokens[prevIndex] {
                            case .keyword("if"),
                                 .keyword("guard"),
                                 .keyword("while"),
                                 .keyword("for"),
                                 .keyword("await"),
                                 .delimiter(","):
                                break
                            default:
                                tokens[tokens.count - 1] = .endOfScope(string)
                                processToken()
                                return
                            }
                        }
                    default:
                        break
                    }
                }
            } else if scope == .startOfScope(":") {
                if [.keyword("#else"), .keyword("#elseif")].contains(token) {
                    scopeIndexStack.removeLast()
                    return
                } else if .endOfScope("#endif") == token {
                    scopeIndexStack.removeLast()
                    if let index = scopeIndexStack.last, tokens[index] == .startOfScope("#if") {
                        scopeIndexStack.removeLast()
                    }
                    return
                }
            }
        }
        // Either there's no scope, or token didn't close it
        count = tokens.count
        token = tokens[count - 1]
        switch token {
        case .startOfScope("/"):
            scopeIndexStack.append(count - 1)
            let start = characters
            processStringBody(regex: true, hashCount: 0)
            if scopeIndexStack.last == count - 1 {
                characters = start
                scopeIndexStack.removeLast()
                tokens.removeLast(tokens.count - count)
                token = .operator("/", .none)
                tokens[count - 1] = token
                return
            }
        case let .startOfScope(string):
            scopeIndexStack.append(count - 1)
            switch string {
            case "/*":
                processMultilineCommentBody()
            case "//":
                processCommentBody()
            default:
                if let delimiterType = token.stringDelimiterType {
                    processStringBody(delimiterType)
                }
            }
        case .endOfScope(">"):
            // Misidentified > as closing generic scope
            convertClosingChevronToOperator(at: count - 1, andOpeningChevron: false)
        case let .endOfScope(string):
            if ["case", "default"].contains(string), let scopeIndex = scopeIndexStack.last,
               tokens[scopeIndex] == .startOfScope("#if")
            {
                scopeIndexStack.append(count - 1)
                return
            }
            // Previous scope wasn't closed correctly
            tokens[count - 1] = .error(string)
        case .delimiter(":"):
            if let prevIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: count - 1),
               case let .keyword(name) = tokens[prevIndex]
            {
                tokens[prevIndex] = .identifier(name)
            }
        default:
            break
        }
    }

    // Ignore hashbang at start of file
    if source.hasPrefix("#!") {
        characters.removeFirst(2)
        tokens.append(.startOfScope("#!"))
        processCommentBody()
    }

    // Parse tokens
    while let token = characters.parseToken() {
        tokens.append(token)
        processToken()
    }

    loop: while let scopeIndex = scopeIndexStack.last {
        switch tokens[scopeIndex] {
        case .startOfScope("<"):
            // If we encountered an end-of-file while a generic scope was
            // still open, the opening < must have been an operator
            convertOpeningChevronToOperator(at: scopeIndex)
        case .startOfScope("//"):
            scopeIndexStack.removeLast()
        default:
            if tokens.last?.isError == false {
                // File ended with scope still open
                tokens.append(.error(""))
            }
            break loop
        }
    }

    // Set final operator type
    if let lastOperatorIndex = index(of: .operator, before: tokens.count) {
        setOperatorType(at: lastOperatorIndex)
    }

    return tokens
}
