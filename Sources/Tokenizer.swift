//
//  Tokenizer.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 11/08/2016.
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

// https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/LexicalStructure.html

// Used to speed up matching
// Note: Self, self, super, nil, true and false have been omitted deliberately, as they
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
    "default", "protocol", "defer", /* Self, self, super, nil, true, false */
])

public extension String {

    /// Is this string a reserved keyword in Swift?
    var isSwiftKeyword: Bool {
        return swiftKeywords.contains(self)
    }

    /// Is this string a keyword in some contexts?
    var isContextualKeyword: Bool {
        switch self {
        case "super", "self", "nil", "true", "false",
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
            var input = string.unicodeScalars
            var output = String.UnicodeScalarView()
            while let c = input.readCharacter() {
                if c == "\\" {
                    if let c = input.readCharacter() {
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
            var characters = string.unicodeScalars
            guard characters.count > 2, characters.removeFirst() == "0",
                "oxb".unicodeScalars.contains(characters.removeFirst()) else {
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

    public var isOperator: Bool { return hasType(of: .operator("", .none)) }
    public var isUnwrapOperator: Bool { return isOperator("?") || isOperator("!") }
    public var isAmpersandOperator: Bool { return isOperator("&") }
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
             .endOfScope("\""):
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
             .startOfScope("("), .startOfScope("["),
             .startOfScope("{"), .startOfScope("\""):
            return true
        default:
            return false
        }
    }

    public static func ==(lhs: Token, rhs: Token) -> Bool {
        return lhs.match(with: rhs) == .exact
    }
}

extension UnicodeScalar {
    var isDigit: Bool { return isdigit(Int32(value)) > 0 }
    var isHexDigit: Bool { return isxdigit(Int32(value)) > 0 }
    var isSpace: Bool { return self == " " || self == "\t" || value == 0x0B }
}

private extension String.UnicodeScalarView {

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

    mutating func readCharacter(where matching: (UnicodeScalar) -> Bool = { _ in true }) -> UnicodeScalar? {
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

private extension String.UnicodeScalarView {

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
        return readCharacter(where: { "<([{\"".unicodeScalars.contains($0) }).map { .startOfScope(String($0)) }
    }

    mutating func parseEndOfScope() -> Token? {
        return readCharacter(where: { "}])>".unicodeScalars.contains($0) }).map { .endOfScope(String($0)) }
    }

    mutating func parseOperator() -> Token? {

        func isHead(_ c: UnicodeScalar) -> Bool {
            if "./=­-+!*%&|^~?".unicodeScalars.contains(c) {
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
    var characters = source.unicodeScalars
    var closedGenericScopeIndexes: [Int] = []
    var nestedSwitches = 0

    func processStringBody() {
        var string = ""
        var escaped = false
        while let c = characters.readCharacter() {
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
        while let c = characters.readCharacter() {
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
        if case let .operator(string, _) = token, ["?", "!"].contains(string) &&
            index > 0 && !tokens[index - 1].isSpaceOrLinebreak {
            return true
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
                break
            }
            type = .postfix
        case "!" where !prevToken.isSpaceOrCommentOrLinebreak:
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
            } else if prevToken.isSpaceOrCommentOrLinebreak && prevNonSpaceToken.isLvalue &&
                nextToken.isSpaceOrCommentOrLinebreak && nextNonSpaceToken.isRvalue {
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
        switch token {
        case let .keyword(string):
            // Track switch/case statements
            let prevToken =
                index(of: .nonSpaceOrCommentOrLinebreak, before: tokens.count - 1).map { tokens[$0] }
            if let prevToken = prevToken, case .operator(".", _) = prevToken {
                tokens[tokens.count - 1] = .identifier(string)
                processToken()
                return
            }
            if string == "switch" {
                nestedSwitches += 1
            } else if nestedSwitches > 0 {
                switch string {
                case "default":
                    tokens[tokens.count - 1] = .endOfScope(string)
                    processToken()
                    return
                case "case":
                    if let scopeIndex = scopeIndexStack.last,
                        let keywordIndex = index(of: .keyword, before: scopeIndex),
                        case .keyword("enum") = tokens[keywordIndex] {
                        break
                    }
                    if let prevToken = prevToken {
                        switch prevToken {
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
            fallthrough
        case .identifier, .number:
            let count = tokens.count
            if count > 1, case .number = tokens[count - 2] {
                tokens[count - 1] = .error(token.string)
            }
        case .operator:
            stitchOperators(at: tokens.count - 1)
        case .startOfScope("<"):
            if tokens.count >= 2 && tokens[tokens.count - 2].isOperator,
                let index = index(of: .nonSpaceOrCommentOrLinebreak, before: tokens.count - 2),
                ![.keyword("func"), .keyword("init")].contains(tokens[index]) {
                tokens[tokens.count - 1] = .operator("<", .none)
                stitchOperators(at: tokens.count - 1)
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
            if let prevIndex = index(of: .nonSpaceOrComment, before: tokens.count - 1),
                case .endOfScope(">") = tokens[prevIndex] {
                // Fix up misidentified generic that is actually a pair of operators
                switch token {
                case let .operator(string, _) where ["->", "?", "!", ".", "..."].contains(string):
                    break
                case .operator("=", _):
                    if prevIndex == tokens.count - 2 {
                        // TODO: this isn't the way swiftc disambiguates this case, so it won't
                        // always work correctly. But in practice, it will be correct most of
                        // the time, and when it's wrong, it should still result in code that
                        // compiles correctly, even if it's mis-formatted
                        fallthrough
                    }
                case .operator, .identifier, .number, .startOfScope("\""):
                    convertClosingChevronToSymbol(at: prevIndex, andOpeningChevron: true)
                    processToken()
                    return
                default:
                    break
                }
            }
            if let lastSymbolIndex = index(of: .operator, before: tokens.count - 1) {
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
                case .endOfScope("}"):
                    if scope == .startOfScope(":") {
                        nestedSwitches -= 1
                    }
                case .endOfScope(")"):
                    if scopeIndexStack.last.map({ tokens[$0] }) == .startOfScope("\"") {
                        processStringBody()
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
                    case ".", "==", "?", "!", "&":
                        if scopeIndex == tokens.count - 2 {
                            // These are allowed in a generic, but not as the first character
                            fallthrough
                        }
                    default:
                        // Not a generic scope
                        convertOpeningChevronToSymbol(at: scopeIndex)
                    }
                case .endOfScope:
                    // If we encountered a closing scope token that wasn't >
                    // then the opening < must have been an operator after all
                    convertOpeningChevronToSymbol(at: scopeIndex)
                    processToken()
                    return
                default:
                    break
                }
            } else if token == .delimiter(":"),
                scope == .startOfScope("(") || scope == .startOfScope("["),
                let prevIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: tokens.count - 1),
                tokens[prevIndex].isIdentifierOrKeyword,
                let prevPrevIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: prevIndex) {
                if case let .keyword(name) = tokens[prevIndex] {
                    tokens[prevIndex] = .identifier(name)
                }
                if case let .keyword(name) = tokens[prevPrevIndex] {
                    tokens[prevPrevIndex] = .identifier(name)
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
            case "/*":
                processCommentBody()
            case "//":
                processSingleLineCommentBody()
            default:
                break
            }
        case .endOfScope(">"):
            // Misidentified > as closing generic scope
            convertClosingChevronToSymbol(at: tokens.count - 1, andOpeningChevron: false)
            return
        case let .endOfScope(string):
            // Previous scope wasn't closed correctly
            tokens[tokens.count - 1] = .error(string)
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
