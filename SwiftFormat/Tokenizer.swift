//
//  Tokenizer.swift
//  SwiftFormat
//
//  Version 0.17.2
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

public enum Token: Equatable {
    case number(String)
    case linebreak(String)
    case startOfScope(String)
    case endOfScope(String)
    case symbol(String)
    case stringBody(String)
    case keyword(String)
    case identifier(String)
    case whitespace(String)
    case commentBody(String)
    case error(String)

    public var string: String {
        switch self {
        case .number(let string),
             .linebreak(let string),
             .startOfScope(let string),
             .endOfScope(let string),
             .symbol(let string),
             .stringBody(let string),
             .keyword(let string),
             .identifier(let string),
             .whitespace(let string),
             .commentBody(let string),
             .error(let string):
            return string
        }
    }

    public var isError: Bool {
        if case .error = self {
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

    public var isIdentifierOrKeyword: Bool {
        switch self {
        case .identifier, .keyword:
            return true
        default:
            return false
        }
    }

    public var isWhitespace: Bool {
        if case .whitespace = self {
            return true
        }
        return false
    }

    public var isLinebreak: Bool {
        if case .linebreak = self {
            return true
        }
        return false
    }

    public var isWhitespaceOrLinebreak: Bool {
        switch self {
        case .linebreak, .whitespace:
            return true
        default:
            return false
        }
    }

    public var isWhitespaceOrComment: Bool {
        switch self {
        case .whitespace,
             .commentBody,
             .startOfScope("//"),
             .startOfScope("/*"),
             .endOfScope("*/"):
            return true
        default:
            return false
        }
    }

    public var isWhitespaceOrCommentOrLinebreak: Bool {
        switch self {
        case .linebreak,
             .whitespace,
             .commentBody,
             .startOfScope("//"),
             .startOfScope("/*"),
             .endOfScope("*/"):
            return true
        default:
            return false
        }
    }

    public func closesScopeForToken(_ token: Token) -> Bool {
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
        case .symbol(":"):
            // Special case, only used in tokenizer
            switch token {
            case .endOfScope("case"), .endOfScope("default"):
                return true
            default:
                return false
            }
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
        case .symbol(let string):
            if case .symbol(string) = rhs {
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
        case .whitespace(let string):
            if case .whitespace(string) = rhs {
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
    var isWhitespace: Bool { return self == " " || self == "\t" || value == 0x0b }
}

private extension String.UnicodeScalarView {

    mutating func scanCharacters(_ matching: (UnicodeScalar) -> Bool) -> String? {
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

    mutating func scanCharacters(head: (UnicodeScalar) -> Bool, tail: (UnicodeScalar) -> Bool) -> String? {
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

    mutating func scanCharacter(_ matching: (UnicodeScalar) -> Bool = { _ in true }) -> UnicodeScalar? {
        if let c = first, matching(c) {
            self = dropFirst()
            return c
        }
        return nil
    }

    mutating func scanCharacter(_ character: UnicodeScalar) -> Bool {
        if first == character {
            self = dropFirst()
            return true
        }
        return false
    }
}

private extension String.UnicodeScalarView {

    mutating func parseWhitespace() -> Token? {
        return scanCharacters({ $0.isWhitespace }).map { .whitespace($0) }
    }

    mutating func parseLineBreak() -> Token? {
        if scanCharacter("\r") {
            if scanCharacter("\n") {
                return .linebreak("\r\n")
            }
            return .linebreak("\r")
        }
        return scanCharacter("\n") ? .linebreak("\n") : nil
    }

    mutating func parsePunctuation() -> Token? {
        return scanCharacter({ ":;,".unicodeScalars.contains($0) }).map { .symbol(String($0)) }
    }

    mutating func parseStartOfScope() -> Token? {
        return scanCharacter({ "<([{\"".unicodeScalars.contains($0) }).map { .startOfScope(String($0)) }
    }

    mutating func parseEndOfScope() -> Token? {
        return scanCharacter({ "}])>".unicodeScalars.contains($0) }).map { .endOfScope(String($0)) }
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
        if var tail = scanCharacter(isHead) {
            switch tail {
            case "?", "!":
                return .symbol(String(tail))
            case "/":
                break
            default:
                start = self
            }
            var head = ""
            // Tail may only contain dot if head does
            let headWasDot = (tail == ".")
            while let c = scanCharacter({ isTail($0) && (headWasDot || $0 != ".") }) {
                if tail == "/" {
                    if c == "*" {
                        if head == "" {
                            return .startOfScope("/*")
                        }
                        // Can't return two tokens, so put /* back to be parsed next time
                        self = start
                        return .symbol(head)
                    } else if c == "/" {
                        if head == "" {
                            return .startOfScope("//")
                        }
                        // Can't return two tokens, so put // back to be parsed next time
                        self = start
                        return .symbol(head)
                    }
                }
                if c != "/" {
                    start = self
                }
                head.append(Character(tail))
                tail = c
            }
            return .symbol(head + String(tail))
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

        func scanIdentifier() -> String? {
            return scanCharacters(head: isHead, tail: isTail)
        }

        let start = self
        if scanCharacter("`") {
            if let identifier = scanIdentifier(), scanCharacter("`") {
                return .identifier("`" + identifier + "`")
            }
            self = start
        } else if scanCharacter("#") {
            if let identifier = scanIdentifier() {
                if identifier == "if" {
                    return .startOfScope("#if")
                }
                if identifier == "endif" {
                    return .endOfScope("#endif")
                }
                return .keyword("#" + identifier)
            }
            self = start
        } else if scanCharacter("@") {
            if let identifier = scanIdentifier() {
                return .keyword("@" + identifier)
            }
            self = start
        } else if let identifier = scanIdentifier() {
            if swiftKeywords.contains(identifier) {
                return .keyword(identifier)
            }
            return .identifier(identifier)
        }
        return nil
    }

    mutating func parseNumber() -> Token? {

        func scanNumber(_ head: @escaping (UnicodeScalar) -> Bool) -> String? {
            return scanCharacters(head: head, tail: { head($0) || $0 == "_" })
        }

        func scanInteger() -> String? {
            return scanNumber({ $0.isDigit })
        }

        guard let integer = scanInteger() else {
            return nil
        }

        if integer == "0" {
            if scanCharacter("x") {
                if let hex = scanNumber({ $0.isHexDigit }) {
                    if scanCharacter("p") {
                        if let power = scanInteger() {
                            return .number("0x" + hex + "p" + power)
                        }
                        return .error("0x" + hex + "p" + String(self))
                    }
                    return .number("0x" + hex)
                }
                return .error("0x" + String(self))
            } else if scanCharacter("b") {
                if let bin = scanNumber({ "01".unicodeScalars.contains($0) }) {
                    return .number("0b" + bin)
                }
                return .error("0b" + String(self))
            } else if scanCharacter("o") {
                if let octal = scanNumber({ ("0" ... "7").contains($0) }) {
                    return .number("0o" + octal)
                }
                return .error("0o" + String(self))
            }
        }

        var number: String
        let endOfInt = self
        if scanCharacter("."), let fraction = scanInteger() {
            number = integer + "." + fraction
        } else {
            self = endOfInt
            number = integer
        }

        let endOfFloat = self
        if let e = scanCharacter({ "eE".unicodeScalars.contains($0) }) {
            let sign = scanCharacter({ "-+".unicodeScalars.contains($0) }).map { String($0) } ?? ""
            if let exponent = scanInteger() {
                number += String(e) + sign + exponent
            } else {
                self = endOfFloat
            }
        }

        return .number(number)
    }

    mutating func parseToken() -> Token? {
        // Have to split into groups for Swift to be able to process this
        if let token = parseWhitespace() ??
            parseLineBreak() ??
            parseNumber() ??
            parseIdentifier() {
            return token
        }
        if let token = parseOperator() ??
            parsePunctuation() ??
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
        while let c = characters.scanCharacter() {
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
    var whitespace = ""

    func flushCommentBodyTokens() {
        if comment != "" {
            tokens.append(.commentBody(comment))
            comment = ""
        }
        if whitespace != "" {
            tokens.append(.whitespace(whitespace))
            whitespace = ""
        }
    }

    func processCommentBody() {
        while let c = characters.scanCharacter() {
            switch c {
            case "/":
                if characters.scanCharacter("*") {
                    flushCommentBodyTokens()
                    scopeIndexStack.append(tokens.count)
                    tokens.append(.startOfScope("/*"))
                    continue
                }
            case "*":
                if characters.scanCharacter("/") {
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
                if characters.scanCharacter("\n") {
                    tokens.append(.linebreak("\r\n"))
                } else {
                    tokens.append(.linebreak("\r"))
                }
                continue
            default:
                if c.isWhitespace {
                    whitespace.append(Character(c))
                    continue
                }
            }
            if whitespace != "" {
                if comment == "" {
                    tokens.append(.whitespace(whitespace))
                } else {
                    comment += whitespace
                }
                whitespace = ""
            }
            comment.append(Character(c))
        }
        // We shouldn't actually get here, unless code is malformed
        flushCommentBodyTokens()
    }

    func processSingleLineCommentBody() {
        while let c = characters.scanCharacter({ !"\r\n".unicodeScalars.contains($0) }) {
            if c.isWhitespace {
                whitespace.append(Character(c))
                continue
            }
            if whitespace != "" {
                if comment == "" {
                    tokens.append(.whitespace(whitespace))
                } else {
                    comment += whitespace
                }
                whitespace = ""
            }
            comment.append(Character(c))
        }
        flushCommentBodyTokens()
    }

    func convertOpeningChevronToSymbol(at index: Int) {
        assert(tokens[index] == .startOfScope("<"))
        tokens[index] = .symbol("<")
        stitchSymbols(at: index)
    }

    func convertClosingChevronToSymbol(at index: Int, andOpeningChevron: Bool) {
        assert(tokens[index] == .endOfScope(">"))
        tokens[index] = .symbol(">")
        stitchSymbols(at: index)
        if let previousIndex = lastNonWhitespaceIndex(from: index),
            tokens[previousIndex] == .endOfScope(">") {
            convertClosingChevronToSymbol(at: previousIndex, andOpeningChevron: true)
        }
        if andOpeningChevron, let scopeIndex = closedGenericScopeIndexes.last {
            closedGenericScopeIndexes.removeLast()
            convertOpeningChevronToSymbol(at: scopeIndex)
        }
    }

    func isUnwrapSymbolOrPunctuation(at index: Int) -> Bool {
        let token = tokens[index]
        if case .symbol(let string) = token {
            if ["?", "!"].contains(string), index > 0, !tokens[index - 1].isWhitespaceOrLinebreak {
                return true
            } else if [":", ";", ","].contains(string) {
                return true
            }
        }
        return false
    }

    func stitchSymbols(at index: Int) {
        guard case .symbol(var string) = tokens[index] else {
            assertionFailure()
            return
        }
        while let nextToken: Token = index + 1 < tokens.count ? tokens[index + 1] : nil,
            case .symbol(let nextString) = nextToken {
            string += nextString
            tokens[index] = .symbol(string)
            tokens.remove(at: index + 1)
        }
        var index = index
        while let previousToken: Token = index > 1 ? tokens[index - 1] : nil,
            case .symbol(let prevString) = previousToken, !isUnwrapSymbolOrPunctuation(at: index - 1) {
            string = prevString + string
            tokens[index - 1] = .symbol(string)
            tokens.remove(at: index)
            index -= 1
        }
    }

    func lastNonWhitespaceIndex(from index: Int) -> Int? {
        if index > 0 {
            if !tokens[index - 1].isWhitespace {
                return index - 1
            } else if index > 1 {
                return index - 2
            }
        }
        return nil
    }

    func processToken() {
        let token = tokens.last!
        if !token.isWhitespace {
            switch token {
            case .keyword(let string):
                // Track switch/case statements
                let previousToken = lastNonWhitespaceIndex(from: tokens.count - 1).map { tokens[$0] }
                if previousToken == .symbol(".") {
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
                        if let previousToken = previousToken {
                            switch previousToken {
                            case .keyword("if"),
                                 .keyword("guard"),
                                 .keyword("while"),
                                 .keyword("for"),
                                 .symbol(","):
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
            default:
                break
            }
            // Fix up misidentified generic that is actually a pair of operators
            if let previousIndex = lastNonWhitespaceIndex(from: tokens.count - 1) {
                let previousToken = tokens[previousIndex]
                if case .endOfScope(">") = previousToken {
                    switch token {
                    case .symbol(let string):
                        if !["=", "->", ",", ":", ";", "?", "!", "."].contains(string) {
                            fallthrough
                        }
                    case .identifier, .number, .startOfScope("\""):
                        convertClosingChevronToSymbol(at: previousIndex, andOpeningChevron: true)
                        processToken()
                        return
                    default:
                        break
                    }
                }
            }
        }
        if let scopeIndex = scopeIndexStack.last {
            let scope = tokens[scopeIndex]
            if token.closesScopeForToken(scope) {
                scopeIndexStack.removeLast()
                switch token {
                case .symbol(":"):
                    tokens[tokens.count - 1] = .startOfScope(":")
                    scopeIndexStack.append(tokens.count - 1)
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
                case .symbol(let string):
                    switch string {
                    case ".", ",", ":", "==", "?", "!":
                        break
                    default:
                        // Not a generic scope
                        convertOpeningChevronToSymbol(at: scopeIndex)
                        scopeIndexStack.removeLast()
                    }
                case .endOfScope:
                    // If we encountered a closing scope token that wasn't >
                    // then the opening < must have been an operator after all
                    convertOpeningChevronToSymbol(at: scopeIndex)
                    scopeIndexStack.removeLast()
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
            scopeIndexStack.removeLast()
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

    return tokens
}
