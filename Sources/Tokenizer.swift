//
//  Tokenizer.swift
//  SwiftFormat
//
//  Version 0.39.3
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
// associativity, convenience, dynamic, didSet, final, get, infix, indirect,
// lazy, left, mutating, none, nonmutating, open, optional, override, postfix,
// precedence, prefix, Protocol, required, right, set, Type, unowned, weak, willSet
private let swiftKeywords = Set([
    "let", "return", "func", "var", "if", "public", "as", "else", "in", "import",
    "class", "try", "guard", "case", "for", "init", "extension", "private", "static",
    "fileprivate", "internal", "switch", "do", "catch", "enum", "struct", "throws",
    "throw", "typealias", "where", "break", "deinit", "subscript", "lazy", "is",
    "while", "associatedtype", "inout", "continue", "operator", "repeat", "rethrows",
    "default", "protocol", "defer", /* Any, Self, self, super, nil, true, false */
])

public extension String {
    /// Is this string a reserved keyword in Swift?
    var isSwiftKeyword: Bool {
        return swiftKeywords.contains(self)
    }

    /// Is this string a keyword in some contexts?
    var isContextualKeyword: Bool {
        switch self {
        case "Any", "super", "self", "nil", "true", "false",
             "Self", "get", "set", "willSet", "didSet":
            return true
        default:
            return isSwiftKeyword
        }
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

/// Symbol/operator types
public enum OperatorType {
    case none
    case infix
    case prefix
    case postfix
}

/// All token types
public enum Token: Equatable {
    case number(String, NumberType)
    case linebreak(String)
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

    /// The original token string
    public var string: String {
        switch self {
        case let .number(string, _),
             let .linebreak(string),
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

    /// Returns the unescaped token string
    public func unescaped() -> String {
        switch self {
        case .stringBody:
            var input = UnicodeScalarView(string.unicodeScalars)
            var output = String.UnicodeScalarView()
            while let c = input.popFirst() {
                if c == "\\" {
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
                                let c = UnicodeScalar(codepoint) else {
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
        case .identifier:
            return string.replacingOccurrences(of: "`", with: "")
        case .number(_, .integer), .number(_, .decimal):
            return string.replacingOccurrences(of: "_", with: "")
        case .number(_, .binary), .number(_, .octal), .number(_, .hex):
            var characters = UnicodeScalarView(string.unicodeScalars)
            guard characters.read("0"), characters.readCharacter(where: {
                "oxb".unicodeScalars.contains($0)
            }) != nil else {
                return string.replacingOccurrences(of: "_", with: "")
            }
            return String(characters).replacingOccurrences(of: "_", with: "")
        default:
            return string
        }
    }

    /// Test if token is of the specified type
    public func `is`(_ type: TokenType) -> Bool {
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
        case .nonSpaceOrComment:
            return !isSpaceOrComment
        case .nonSpaceOrLinebreak:
            return !isSpaceOrLinebreak
        case .nonSpaceOrCommentOrLinebreak:
            return !isSpaceOrCommentOrLinebreak
        }
    }

    private enum Match {
        case none
        case type
        case typeAndSubtype
        case typeAndString
        case exact
    }

    private func match(with token: Token) -> Match {
        switch (self, token) {
        case let (.number(a, c), .number(b, d)):
            return a == b ?
                (c == d ? .exact : .typeAndString) :
                (c == d ? .typeAndSubtype : .type)
        case let (.operator(a, c), .operator(b, d)):
            return a == b ?
                (c == d ? .exact : .typeAndString) :
                (c == d ? .typeAndSubtype : .type)
        case let (.linebreak(a), .linebreak(b)),
             let (.startOfScope(a), .startOfScope(b)),
             let (.endOfScope(a), .endOfScope(b)),
             let (.delimiter(a), .delimiter(b)),
             let (.keyword(a), .keyword(b)),
             let (.identifier(a), .identifier(b)),
             let (.stringBody(a), .stringBody(b)),
             let (.commentBody(a), .commentBody(b)),
             let (.space(a), .space(b)),
             let (.error(a), .error(b)):
            return a == b ? .exact : .type
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
            return .none
        }
    }

    private func hasType(of token: Token) -> Bool {
        return match(with: token) != .none
    }

    public var isAttribute: Bool { return isKeyword && string.hasPrefix("@") }
    public var isOperator: Bool { return hasType(of: .operator("", .none)) }
    public var isUnwrapOperator: Bool { return isOperator("?") || isOperator("!") }
    public var isRangeOperator: Bool { return isOperator("...") || isOperator("..<") }
    public var isNumber: Bool { return hasType(of: .number("", .integer)) }
    public var isError: Bool { return hasType(of: .error("")) }
    public var isStartOfScope: Bool { return hasType(of: .startOfScope("")) }
    public var isEndOfScope: Bool { return hasType(of: .endOfScope("")) }
    public var isKeyword: Bool { return hasType(of: .keyword("")) }
    public var isIdentifier: Bool { return hasType(of: .identifier("")) }
    public var isIdentifierOrKeyword: Bool { return isIdentifier || isKeyword }
    public var isSpace: Bool { return hasType(of: .space("")) }
    public var isLinebreak: Bool { return hasType(of: .linebreak("")) }
    public var isEndOfStatement: Bool { return self == .delimiter(";") || isLinebreak }
    public var isSpaceOrLinebreak: Bool { return isSpace || isLinebreak }
    public var isSpaceOrComment: Bool { return isSpace || isComment }
    public var isSpaceOrCommentOrLinebreak: Bool { return isSpaceOrComment || isLinebreak }
    public var isCommentOrLinebreak: Bool { return isComment || isLinebreak }

    public func isOperator(_ string: String) -> Bool {
        if case .operator(string, _) = self {
            return true
        }
        return false
    }

    public func isOperator(ofType type: OperatorType) -> Bool {
        if case .operator(_, type) = self {
            return true
        }
        return false
    }

    public var isComment: Bool {
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

    public func isEndOfScope(_ token: Token) -> Bool {
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
            case "\"":
                return closing == "\""
            case "\"\"\"":
                return closing == "\"\"\""
            default:
                return false
            }
        case .linebreak:
            switch token {
            case .startOfScope("//"), .startOfScope("#!"):
                return true
            default:
                return false
            }
        case .delimiter(":"):
            // Special case, only used in tokenizer
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

    var isLvalue: Bool {
        switch self {
        case .identifier, .number, .operator(_, .postfix),
             .endOfScope(")"), .endOfScope("]"),
             .endOfScope("}"), .endOfScope(">"),
             .endOfScope("\""), .endOfScope("\"\"\""):
            return true
        case let .keyword(name) where name.hasPrefix("#"):
            return true
        default:
            return false
        }
    }

    var isRvalue: Bool {
        switch self {
        case .operator(".", _):
            return true
        case .operator(_, .infix), .operator(_, .postfix):
            return false
        case .identifier, .number, .operator,
             .startOfScope("("), .startOfScope("["), .startOfScope("{"),
             .startOfScope("\""), .startOfScope("\"\"\""):
            return true
        case let .keyword(name) where name.hasPrefix("#"):
            return true
        default:
            return false
        }
    }

    public static func == (lhs: Token, rhs: Token) -> Bool {
        return lhs.match(with: rhs) == .exact
    }
}

extension UnicodeScalar {
    var isDigit: Bool { return isdigit(Int32(value)) > 0 }
    var isHexDigit: Bool { return isxdigit(Int32(value)) > 0 }
    var isSpace: Bool { return self == " " || self == "\t" || value == 0x0B }
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
        return isEmpty ? nil : characters[startIndex]
    }

    @available(*, deprecated, message: "Really hurts performance - use a different approach")
    public var count: Int {
        return characters.distance(from: startIndex, to: endIndex)
    }

    public var isEmpty: Bool {
        return startIndex >= endIndex
    }

    public subscript(_ index: Index) -> UnicodeScalar {
        return characters[index]
    }

    public func index(after index: Index) -> Index {
        return characters.index(after: index)
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
        return characters[startIndex ..< endIndex]
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

    mutating func readToEndOfToken() -> String {
        return readCharacters { !$0.isSpace && !"\n\r".unicodeScalars.contains($0) } ?? ""
    }
}

private extension UnicodeScalarView {
    mutating func parseSpace() -> Token? {
        return readCharacters(where: { $0.isSpace }).map { .space($0) }
    }

    mutating func parseLineBreak() -> Token? {
        if read("\r") {
            if read("\n") {
                return .linebreak("\r\n")
            }
            return .linebreak("\r")
        }
        return read("\n") ? .linebreak("\n") : nil
    }

    mutating func parseDelimiter() -> Token? {
        return readCharacter(where: { ":;,".unicodeScalars.contains($0) }).map { .delimiter(String($0)) }
    }

    mutating func parseStartOfScope() -> Token? {
        if read("\"") {
            let nextIndex = index(after: startIndex)
            if nextIndex < endIndex, first == "\"", self[nextIndex] == "\"" {
                removeFirst(2)
                return .startOfScope("\"\"\"")
            }
            return .startOfScope("\"")
        }
        return readCharacter(where: { "<([{".unicodeScalars.contains($0) }).map { .startOfScope(String($0)) }
    }

    mutating func parseEndOfScope() -> Token? {
        return readCharacter(where: { "}])>".unicodeScalars.contains($0) }).map { .endOfScope(String($0)) }
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
            case "?", "!":
                return .operator(String(tail), .none)
            case "/":
                break
            default:
                start = self
            }
            var head = ""
            // Tail may only contain dot if head does
            let headWasDot = (tail == ".")
            while let c = readCharacter(where: { isTail($0) && (headWasDot || $0 != ".") }) {
                if tail == "/" {
                    if c == "*" {
                        if head == "" {
                            return .startOfScope("/*")
                        }
                        // Can't return two tokens, so put /* back to be parsed next time
                        self = start
                        return .operator(head, .none)
                    } else if c == "/" {
                        if head == "" {
                            return .startOfScope("//")
                        }
                        // Can't return two tokens, so put // back to be parsed next time
                        self = start
                        return .operator(head, .none)
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
            return read(head: isHead, tail: isTail)
        }

        let start = self
        if read("`") {
            if let identifier = readIdentifier(), read("`") {
                return .identifier("`" + identifier + "`")
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
            return read(head: head, tail: { head($0) || $0 == "_" })
        }

        func readInteger() -> String? {
            return readNumber(where: { $0.isDigit })
        }

        func readHex() -> String? {
            return readNumber(where: { $0.isHexDigit })
        }

        func readSign() -> String {
            return readCharacter(where: { "-+".unicodeScalars.contains($0) }).map { String($0) } ?? ""
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
            parseIdentifier() {
            return token
        }
        if let token = parseOperator() ??
            parseDelimiter() ??
            parseStartOfScope() ??
            parseEndOfScope() {
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

    func processStringBody() {
        var string = ""
        var escaped = false
        while let c = characters.popFirst() {
            switch c {
            case "\\":
                escaped = !escaped
            case "\"":
                if !escaped {
                    if string != "" {
                        tokens.append(.stringBody(string))
                    }
                    tokens.append(.endOfScope("\""))
                    scopeIndexStack.removeLast()
                    return
                }
                escaped = false
            case "(":
                if escaped {
                    if string != "" {
                        tokens.append(.stringBody(string))
                    }
                    scopeIndexStack.append(tokens.count)
                    tokens.append(.startOfScope("("))
                    return
                }
                escaped = false
            default:
                escaped = false
            }
            string.append(Character(c))
        }
        if string != "" {
            tokens.append(.stringBody(string))
        }
    }

    func processMultilineStringBody() {
        var string = ""
        var escaped = false
        while let c = characters.popFirst() {
            switch c {
            case "\\":
                escaped = !escaped
            case "\"":
                let nextIndex = characters.index(after: characters.startIndex)
                if nextIndex < characters.endIndex, !escaped, tokens[scopeIndexStack.last!] == .startOfScope("\"\"\""), characters.first == "\"", characters[nextIndex] == "\"" {
                    characters.removeFirst(2)
                    if string != "" {
                        tokens.append(.error(string)) // Not permitted by the spec
                    } else {
                        var offset = ""
                        if case let .space(_offset) = tokens.last! {
                            offset = _offset
                        }
                        // Fix up indents
                        for index in (scopeIndexStack.last! ..< tokens.count - 1).reversed() {
                            if case let .space(indent) = tokens[index], tokens[index - 1].isLinebreak {
                                guard offset.isEmpty || indent.hasPrefix(offset) else {
                                    tokens[index] = .error(indent) // Mismatched whitespace
                                    break
                                }
                                let remainder: String = String(indent[offset.endIndex ..< indent.endIndex])
                                if case let .stringBody(body) = tokens[index + 1] {
                                    tokens[index + 1] = .stringBody(remainder + body)
                                } else {
                                    tokens.insert(.stringBody(remainder), at: index + 1)
                                }
                                if offset.isEmpty {
                                    tokens.remove(at: index)
                                } else {
                                    tokens[index] = .space(offset)
                                }
                            }
                        }
                    }
                    tokens.append(.endOfScope("\"\"\""))
                    scopeIndexStack.removeLast()
                    return
                }
                escaped = false
            case "(":
                if escaped {
                    if string != "" {
                        tokens.append(.stringBody(string))
                    }
                    scopeIndexStack.append(tokens.count)
                    tokens.append(.startOfScope("("))
                    return
                }
                escaped = false
            case "\r", "\n":
                if string != "" {
                    tokens.append(.stringBody(string))
                    string = ""
                }
                if c == "\r", characters.read("\n") {
                    tokens.append(.linebreak("\r\n"))
                } else {
                    tokens.append(.linebreak(String(c)))
                }
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
        while let c = characters.popFirst() {
            switch c {
            case "/":
                if characters.read("*") {
                    flushCommentBodyTokens()
                    scopeIndexStack.append(tokens.count)
                    tokens.append(.startOfScope("/*"))
                    continue
                }
            case "*":
                if characters.read("/") {
                    flushCommentBodyTokens()
                    tokens.append(.endOfScope("*/"))
                    scopeIndexStack.removeLast()
                    if scopeIndexStack.last == nil || tokens[scopeIndexStack.last!] != .startOfScope("/*") {
                        return
                    }
                    continue
                }
            case "\n":
                flushCommentBodyTokens()
                tokens.append(.linebreak("\n"))
                continue
            case "\r":
                flushCommentBodyTokens()
                if characters.read("\n") {
                    tokens.append(.linebreak("\r\n"))
                } else {
                    tokens.append(.linebreak("\r"))
                }
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

    func processSingleLineCommentBody() {
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

    func convertOpeningChevronToSymbol(at index: Int) {
        assert(tokens[index] == .startOfScope("<"))
        if scopeIndexStack.last == index {
            scopeIndexStack.removeLast()
        }
        tokens[index] = .operator("<", .none)
        stitchOperators(at: index)
    }

    func convertClosingChevronToSymbol(at i: Int, andOpeningChevron: Bool) {
        assert(tokens[i] == .endOfScope(">"))
        tokens[i] = .operator(">", .none)
        stitchOperators(at: i)
        if let previousIndex = index(of: .nonSpaceOrComment, before: i),
            tokens[previousIndex] == .endOfScope(">") {
            convertClosingChevronToSymbol(at: previousIndex, andOpeningChevron: true)
        }
        if andOpeningChevron, let scopeIndex = closedGenericScopeIndexes.last {
            closedGenericScopeIndexes.removeLast()
            convertOpeningChevronToSymbol(at: scopeIndex)
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
            case let .operator(nextString, _) = nextToken,
            string.hasPrefix(".") || !nextString.contains(".") {
            if scopeIndexStack.last == index {
                // In case of a ? previously interpreted as a ternary
                scopeIndexStack.removeLast()
            }
            string += nextString
            tokens[index] = .operator(string, .none)
            tokens.remove(at: index + 1)
        }
        var index = index
        while let prevToken: Token = index > 1 ? tokens[index - 1] : nil,
            case let .operator(prevString, _) = prevToken, !isUnwrapOperator(at: index - 1),
            prevString.hasPrefix(".") || !string.contains(".") {
            if scopeIndexStack.last == index - 1 {
                // In case of a ? previously interpreted as a ternary
                scopeIndexStack.removeLast()
            }
            string = prevString + string
            tokens[index - 1] = .operator(string, .none)
            tokens.remove(at: index)
            index -= 1
        }
        setSymbolType(at: index)
        // Fix ternary that may not have been correctly closed in the first pass
        if let scopeIndex = scopeIndexStack.last, tokens[scopeIndex] == .operator("?", .infix) {
            for i in index ..< tokens.count where tokens[i] == .delimiter(":") {
                tokens[i] = .operator(":", .infix)
                scopeIndexStack.removeLast()
                break
            }
        }
    }

    func setSymbolType(at i: Int) {
        let token = tokens[i]
        guard case let .operator(string, currentType) = token else {
            assertionFailure()
            return
        }
        guard let prevNonSpaceToken =
            index(of: .nonSpaceOrCommentOrLinebreak, before: i).map({ tokens[$0] }) else {
            if tokens.count > i + 1 {
                tokens[i] = .operator(string, .prefix)
            }
            return
        }
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
            type = prevNonSpaceToken.isLvalue ? .infix : .prefix
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
                index(of: .nonSpaceOrCommentOrLinebreak, after: i).map({ tokens[$0] }) else {
                if prevToken.isLvalue {
                    type = .postfix
                    break
                }
                return
            }
            let nextToken: Token = tokens[i + 1]
            if nextToken.isRvalue {
                type = prevToken.isLvalue ? .infix : .prefix
            } else if prevToken.isLvalue {
                type = .postfix
            } else if prevToken.isSpaceOrCommentOrLinebreak, prevNonSpaceToken.isLvalue,
                nextToken.isSpaceOrCommentOrLinebreak, nextNonSpaceToken.isRvalue {
                type = .infix
            } else {
                // TODO: should we add an `identifier` type?
                return
            }
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
        let token = tokens.last!
        let count = tokens.count
        switch token {
        case let .keyword(string):
            // Track switch/case statements
            if let prevIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: count - 1),
                case .operator(".", _) = tokens[prevIndex] {
                tokens[tokens.count - 1] = .identifier(string)
                processToken()
                return
            }
            fallthrough
        case .identifier:
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
                let index = index(of: .nonSpaceOrCommentOrLinebreak, before: count - 2),
                ![.keyword("func"), .keyword("init")].contains(tokens[index]) {
                tokens[tokens.count - 1] = .operator("<", .none)
                stitchOperators(at: count - 1)
                processToken()
                return
            }
            fallthrough
        case .startOfScope:
            closedGenericScopeIndexes.removeAll()
        default:
            break
        }
        if !token.isSpaceOrCommentOrLinebreak {
            if let prevIndex = index(of: .nonSpaceOrComment, before: count - 1),
                case .endOfScope(">") = tokens[prevIndex] {
                // Fix up misidentified generic that is actually a pair of operators
                switch token {
                case .operator("=", _) where prevIndex == count - 2,
                     .identifier, .number, .startOfScope("\""), .startOfScope("\"\"\""):
                    convertClosingChevronToSymbol(at: prevIndex, andOpeningChevron: true)
                    processToken()
                    return
                default:
                    break
                }
            }
            if let lastSymbolIndex = index(of: .operator, before: count - 1) {
                // Set operator type
                setSymbolType(at: lastSymbolIndex)
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
                    if scope == .startOfScope("\"") {
                        processStringBody()
                    } else if scope == .startOfScope("\"\"\"") {
                        processMultilineStringBody()
                    }
                case .endOfScope(">"):
                    if scope == .startOfScope("<"), scopeIndex == count - 2 {
                        convertOpeningChevronToSymbol(at: count - 2)
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
            } else if scope == .startOfScope("<") {
                // We think it's a generic at this point, but could be wrong
                switch token {
                case let .operator(string, _):
                    switch string {
                    case ".", "==", "?", "!", "&", "->":
                        if scopeIndex == count - 2 {
                            // These are allowed in a generic, but not as the first character
                            fallthrough
                        }
                    default:
                        // Not a generic scope
                        convertOpeningChevronToSymbol(at: scopeIndex)
                    }
                case .delimiter(":") where scopeIndexStack.count > 1 &&
                    tokens[scopeIndexStack[scopeIndexStack.count - 2]] == .endOfScope("case"):
                    // Not a generic scope
                    convertOpeningChevronToSymbol(at: scopeIndex)
                    processToken()
                    return
                case .keyword("where"):
                    break
                case .endOfScope, .keyword:
                    // If we encountered a keyword, or closing scope token that wasn't >
                    // then the opening < must have been an operator after all
                    convertOpeningChevronToSymbol(at: scopeIndex)
                    processToken()
                    return
                default:
                    break
                }
            } else if token == .delimiter(":"),
                scope == .startOfScope("(") || scope == .startOfScope("["),
                let prevIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: count - 1),
                tokens[prevIndex].isIdentifierOrKeyword,
                let prevPrevIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: prevIndex) {
                if case let .keyword(name) = tokens[prevIndex] {
                    tokens[prevIndex] = .identifier(name)
                }
                if case let .keyword(name) = tokens[prevPrevIndex] {
                    tokens[prevPrevIndex] = .identifier(name)
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
                            if case .keyword("where") = keyword,
                                let keywordIndex = index(of: .keyword, before: keywordIndex) {
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
        switch token {
        case let .startOfScope(string):
            scopeIndexStack.append(tokens.count - 1)
            switch string {
            case "\"":
                processStringBody()
            case "\"\"\"":
                processMultilineStringBody()
            case "/*":
                processCommentBody()
            case "//":
                processSingleLineCommentBody()
            default:
                break
            }
        case .endOfScope(">"):
            // Misidentified > as closing generic scope
            convertClosingChevronToSymbol(at: count - 1, andOpeningChevron: false)
            return
        case let .endOfScope(string):
            if ["case", "default"].contains(string), let scopeIndex = scopeIndexStack.last,
                tokens[scopeIndex] == .startOfScope("#if") {
                scopeIndexStack.append(tokens.count - 1)
                return
            }
            // Previous scope wasn't closed correctly
            tokens[count - 1] = .error(string)
            return
        default:
            break
        }
    }

    // Ignore hashbang at start of file
    if source.hasPrefix("#!") {
        characters.removeFirst(2)
        tokens.append(.startOfScope("#!"))
        processSingleLineCommentBody()
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
            convertOpeningChevronToSymbol(at: scopeIndex)
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
    if let lastSymbolIndex = index(of: .operator, before: tokens.count) {
        setSymbolType(at: lastSymbolIndex)
    }

    return tokens
}
