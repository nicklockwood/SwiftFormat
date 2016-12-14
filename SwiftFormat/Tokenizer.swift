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
// Note: super, self, nil, etc. have been omitted deliberately, as they behave like
// identifiers. So too have context-specific keywords such as the following:
// associativity, convenience, dynamic, didSet, final, get, infix, indirect,
// lazy, left, mutating, none, nonmutating, open, optional, override, postfix,
// precedence, prefix, Protocol, required, right, set, Type, unowned, weak, willSet
private let swiftKeywords = [
    "let", "return", "func", "var", "if", "public", "as", "else", "in", "import",
    "class", "try", "guard", "case", "for", "init", "extension", "private", "static",
    "fileprivate", "internal", "switch", "do", "catch", "enum", "struct", "throws",
    "throw", "typealias", "where", "break", "deinit", "subscript", "lazy", "is",
    "while", "associatedtype", "inout", "continue", "operator", "repeat", "rethrows",
    "default", "protocol",
]

/// Classes of token used for matching
public enum TokenType {
    case space
    case spaceOrComment
    case spaceOrLinebreak
    case spaceOrCommentOrLinebreak
    case linebreak
    case endOfStatement
    case startOfScope
    case endOfScope
    case identifier
    case identifierOrKeyword
    case symbol
    case unwrapSymbol
    case rangeOperator
    case error

    // Negative types
    case nonSpace
    case nonSpaceOrComment
    case nonSpaceOrLinebreak
    case nonSpaceOrCommentOrLinebreak
}

/// Symbol/operator types
public enum SymbolType {
    case none
    case infix
    case prefix
    case postfix
}

/// All token types
public enum Token: Equatable {
    case number(String)
    case linebreak(String)
    case startOfScope(String)
    case endOfScope(String)
    case delimiter(String)
    case symbol(String, SymbolType)
    case stringBody(String)
    case keyword(String)
    case identifier(String)
    case space(String)
    case commentBody(String)
    case error(String)

    public var string: String {
        switch self {
        case .number(let string),
             .linebreak(let string),
             .startOfScope(let string),
             .endOfScope(let string),
             .delimiter(let string),
             .symbol(let string, _),
             .stringBody(let string),
             .keyword(let string),
             .identifier(let string),
             .space(let string),
             .commentBody(let string),
             .error(let string):
            return string
        }
    }

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
        case .identifier:
            return isIdentifier
        case .identifierOrKeyword:
            return isIdentifierOrKeyword
        case .symbol:
            return isSymbol
        case .unwrapSymbol:
            return isUnwrapSymbol
        case .rangeOperator:
            return isRangeOperator
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

    public var isSymbol: Bool {
        switch self {
        case .symbol:
            return true
        default:
            return false
        }
    }

    public var isUnwrapSymbol: Bool {
        switch self {
        case .symbol("?", _), .symbol("!", _):
            return true
        default:
            return false
        }
    }

    public var isRangeOperator: Bool {
        switch self {
        case .symbol("...", _), .symbol("..<", _):
            return true
        default:
            return false
        }
    }

    public var isError: Bool {
        if case .error = self {
            return true
        }
        return false
    }

    public var isStartOfScope: Bool {
        if case .startOfScope = self {
            return true
        }
        return false
    }

    public var isEndOfScope: Bool {
        if case .endOfScope = self {
            return true
        }
        return false
    }

    public var isIdentifier: Bool {
        switch self {
        case .identifier:
            return true
        default:
            return false
        }
    }

    public var isIdentifierOrKeyword: Bool {
        switch self {
        case .identifier, .keyword:
            return true
        default:
            return false
        }
    }

    public var isSpace: Bool {
        if case .space = self {
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

    public var isLinebreak: Bool {
        if case .linebreak = self {
            return true
        }
        return false
    }

    public var isSpaceOrLinebreak: Bool {
        return isSpace || isLinebreak
    }

    public var isCommentOrLinebreak: Bool {
        return isComment || isLinebreak
    }

    public var isSpaceOrComment: Bool {
        return isSpace || isComment
    }

    public var isSpaceOrCommentOrLinebreak: Bool {
        return isSpace || isComment || isLinebreak
    }

    public var isEndOfStatement: Bool {
        if case .delimiter(";") = self {
            return true
        }
        return isLinebreak
    }

    public func isEndOfScope(_ token: Token) -> Bool {
        switch self {
        case .endOfScope(let closing):
            guard case .startOfScope(let opening) = token else {
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
            return token == .startOfScope("//")
        case .delimiter(":"):
            // Special case, only used in tokenizer
            switch token {
            case .endOfScope("case"), .endOfScope("default"), .symbol("?", .infix):
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
        case .identifier, .number, .symbol(_, .postfix),
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
        case .symbol(_, .infix), .symbol(_, .postfix):
            return false
        case .identifier, .number, .symbol,
             .startOfScope("("), .startOfScope("["), .startOfScope("{"):
            return true
        default:
            return false
        }
    }

    public static func ==(lhs: Token, rhs: Token) -> Bool {
        switch lhs {
        case .number(let string):
            if case .number(string) = rhs {
                return true
            }
        case .linebreak(let string):
            if case .linebreak(string) = rhs {
                return true
            }
        case .startOfScope(let string):
            if case .startOfScope(string) = rhs {
                return true
            }
        case .endOfScope(let string):
            if case .endOfScope(string) = rhs {
                return true
            }
        case .delimiter(let string):
            if case .delimiter(string) = rhs {
                return true
            }
        case .symbol(let string, let type):
            if case .symbol(string, type) = rhs {
                return true
            }
        case .keyword(let string):
            if case .keyword(string) = rhs {
                return true
            }
        case .identifier(let string):
            if case .identifier(string) = rhs {
                return true
            }
        case .stringBody(let string):
            if case .stringBody(string) = rhs {
                return true
            }
        case .commentBody(let string):
            if case .commentBody(string) = rhs {
                return true
            }
        case .space(let string):
            if case .space(string) = rhs {
                return true
            }
        case .error(let string):
            if case .error(string) = rhs {
                return true
            }
        }
        return false
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
                return .symbol(String(tail), .none)
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
                        return .symbol(head, .none)
                    } else if c == "/" {
                        if head == "" {
                            return .startOfScope("//")
                        }
                        // Can't return two tokens, so put // back to be parsed next time
                        self = start
                        return .symbol(head, .none)
                    }
                }
                if c != "/" {
                    start = self
                }
                head.append(Character(tail))
                tail = c
            }
            head.append(Character(tail))
            return head == "->" ? .delimiter("->") : .symbol(head, .none)
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
            if swiftKeywords.contains(identifier) {
                return .keyword(identifier)
            }
            return .identifier(identifier)
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

        guard let integer = readInteger() else {
            return nil
        }

        if integer == "0" {
            if read("x") {
                if let hex = readNumber(where: { $0.isHexDigit }) {
                    if read("p") {
                        if let power = readInteger() {
                            return .number("0x" + hex + "p" + power)
                        }
                        return .error("0x" + hex + "p" + String(self))
                    }
                    return .number("0x" + hex)
                }
                return .error("0x" + String(self))
            } else if read("b") {
                if let bin = readNumber(where: { "01".unicodeScalars.contains($0) }) {
                    return .number("0b" + bin)
                }
                return .error("0b" + String(self))
            } else if read("o") {
                if let octal = readNumber(where: { ("0" ... "7").contains($0) }) {
                    return .number("0o" + octal)
                }
                return .error("0o" + String(self))
            }
        }

        var number: String
        let endOfInt = self
        if read("."), let fraction = readInteger() {
            number = integer + "." + fraction
        } else {
            self = endOfInt
            number = integer
        }

        let endOfFloat = self
        if let e = readCharacter(where: { "eE".unicodeScalars.contains($0) }) {
            let sign = readCharacter(where: { "-+".unicodeScalars.contains($0) }).map { String($0) } ?? ""
            if let exponent = readInteger() {
                number += String(e) + sign + exponent
            } else {
                self = endOfFloat
            }
        }

        return .number(number)
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
            return .error(String(self))
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
        tokens[index] = .symbol("<", .none)
        stitchSymbols(at: index)
    }

    func convertClosingChevronToSymbol(at i: Int, andOpeningChevron: Bool) {
        assert(tokens[i] == .endOfScope(">"))
        tokens[i] = .symbol(">", .none)
        stitchSymbols(at: i)
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
        if case .symbol(let string, _) = token, ["?", "!"].contains(string) &&
            index > 0 && !tokens[index - 1].isSpaceOrLinebreak {
            return true
        }
        return false
    }

    func stitchSymbols(at index: Int) {
        guard case .symbol(var string, _) = tokens[index] else {
            assertionFailure()
            return
        }
        while let nextToken: Token = index + 1 < tokens.count ? tokens[index + 1] : nil,
            case .symbol(let nextString, _) = nextToken,
            string.hasPrefix(".") || !nextString.contains(".") {
            if scopeIndexStack.last == index {
                // In case of a ? previously interpreted as a ternary
                scopeIndexStack.removeLast()
            }
            string += nextString
            tokens[index] = .symbol(string, .none)
            tokens.remove(at: index + 1)
        }
        var index = index
        while let prevToken: Token = index > 1 ? tokens[index - 1] : nil,
            case .symbol(let prevString, _) = prevToken, !isUnwrapOperator(at: index - 1),
            prevString.hasPrefix(".") || !string.contains(".") {
            if scopeIndexStack.last == index - 1 {
                // In case of a ? previously interpreted as a ternary
                scopeIndexStack.removeLast()
            }
            string = prevString + string
            tokens[index - 1] = .symbol(string, .none)
            tokens.remove(at: index)
            index -= 1
        }
        setSymbolType(at: index)
    }

    func setSymbolType(at i: Int) {
        let token = tokens[i]
        guard case .symbol(let string, let currentType) = token else {
            assertionFailure()
            return
        }

        let nextToken: Token? = i < tokens.count - 1 ? tokens[i + 1] : nil
        let nextNonSpaceToken = index(of: .nonSpaceOrCommentOrLinebreak, after: i).map { tokens[$0] }
        let prevToken: Token? = i > 0 ? tokens[i - 1] : nil
        let prevNonSpaceToken = index(of: .nonSpaceOrCommentOrLinebreak, before: i).map { tokens[$0] }

        let type: SymbolType
        switch string {
        case ":":
            type = .infix
        case ".":
            type = (prevNonSpaceToken?.isLvalue == true) ? .infix : .prefix
        case "?":
            if prevToken?.isSpaceOrCommentOrLinebreak == true {
                // ? is a ternary operator, treat it as the start of a scope
                if currentType != .infix {
                    assert(scopeIndexStack.last ?? -1 < i)
                    scopeIndexStack.append(i) // TODO: should we be doing this here?
                }
                type = .infix
                break
            }
            type = .postfix
        case "!":
            if prevToken.map({ $0.isSpaceOrCommentOrLinebreak }) ?? true {
                fallthrough
            }
            type = .postfix
        default:
            if prevToken?.isLvalue == true {
                type = (nextToken?.isRvalue == true) ? .infix : .postfix
            } else if nextToken?.isRvalue == true {
                type = .prefix
            } else if prevToken?.isSpaceOrCommentOrLinebreak == true &&
                prevNonSpaceToken?.isLvalue == true &&
                nextToken?.isSpaceOrCommentOrLinebreak == true &&
                nextNonSpaceToken?.isRvalue == true {
                type = .infix
            } else {
                // TODO: should we add an `identifier` type?
                type = .none
            }
        }
        tokens[i] = .symbol(string, type)
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
        case .keyword(let string):
            // Track switch/case statements
            let prevToken =
                index(of: .nonSpaceOrCommentOrLinebreak, before: tokens.count - 1).map { tokens[$0] }
            if let prevToken = prevToken, case .symbol(".", _) = prevToken {
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
        case .symbol:
            stitchSymbols(at: tokens.count - 1)
        case .startOfScope:
            closedGenericScopeIndexes.removeAll()
        default:
            break
        }
        if let previousIndex = index(of: .nonSpaceOrComment, before: tokens.count - 1) {
            // Fix up misidentified generic that is actually a pair of operators
            let prevToken = tokens[previousIndex]
            if case .endOfScope(">") = prevToken {
                switch token {
                case .symbol(let string, _) where ["=", "?", "!", ".", "..."].contains(string):
                    break
                case .symbol, .identifier, .number, .startOfScope("\""):
                    convertClosingChevronToSymbol(at: previousIndex, andOpeningChevron: true)
                    processToken()
                    return
                default:
                    break
                }
            }
        }
        if !token.isSpaceOrCommentOrLinebreak,
            let lastSymbolIndex = index(of: .symbol, before: tokens.count - 1) {
            // Set operator type
            setSymbolType(at: lastSymbolIndex)
        }
        // Handle scope
        if let scopeIndex = scopeIndexStack.last {
            let scope = tokens[scopeIndex]
            if token.isEndOfScope(scope) {
                scopeIndexStack.removeLast()
                switch token {
                case .delimiter(":"):
                    if case .symbol("?", .infix) = scope {
                        tokens[tokens.count - 1] = .symbol(":", .infix)
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
                case .symbol(let string, _):
                    switch string {
                    case ".", "==", "?", "!":
                        break
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
            }
        }
        // Either there's no scope, or token didn't close it
        switch token {
        case .startOfScope(let string):
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
        case .endOfScope(let string):
            // Previous scope wasn't closed correctly
            tokens[tokens.count - 1] = .error(string)
            return
        default:
            break
        }
    }

    while let token = characters.parseToken() {
        tokens.append(token)
        if case .error = token {
            return tokens
        }
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
    if let lastSymbolIndex = index(of: .symbol, before: tokens.count) {
        setSymbolType(at: lastSymbolIndex)
    }

    return tokens
}
