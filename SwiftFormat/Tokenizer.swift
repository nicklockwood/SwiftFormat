//
//  Tokenizer.swift
//  SwiftFormat
//
//  Version 0.13
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

public enum TokenType {
    case number
    case linebreak
    case startOfScope
    case endOfScope
    case symbol
    case stringBody
    case identifier
    case whitespace
    case commentBody
    case error
}

public struct Token: Equatable {
    public let type: TokenType
    public let string: String

    public init(_ type: TokenType, _ string: String) {
        self.type = type
        self.string = string
    }

    public var isWhitespaceOrComment: Bool {
        switch type {
        case .whitespace, .commentBody:
            return true
        case .startOfScope:
            return string == "//" || string == "/*"
        case .endOfScope:
            return string == "*/"
        default:
            return false
        }
    }

    public var isWhitespaceOrLinebreak: Bool {
        return type == .linebreak || type == .whitespace
    }

    public var isWhitespaceOrCommentOrLinebreak: Bool {
        return type == .linebreak || isWhitespaceOrComment
    }

    public func closesScopeForToken(_ token: Token) -> Bool {
        guard token.type == .startOfScope else {
            return string == ":" && token.type == .endOfScope &&
                (token.string == "case" || token.string == "default")
        }
        if type == .endOfScope {
            switch token.string {
            case "(":
                return string == ")"
            case "[":
                return string == "]"
            case "{":
                return string == "}" || string == "case" || string == "default"
            case "/*":
                return string == "*/"
            case "#if":
                return string == "#endif"
            case ":":
                return string == "case" || string == "default" || string == "}"
            default:
                break
            }
        }
        switch token.string {
        case "<":
            return string.hasPrefix(">")
        case "\"":
            return string == "\""
        case "//":
            return type == .linebreak
        default:
            return false
        }
    }
}

public func ==(lhs: Token, rhs: Token) -> Bool {
    return lhs.type == rhs.type && lhs.string == rhs.string
}

extension Character {

    var unicodeValue: UInt32 {
        return String(self).unicodeScalars.first?.value ?? 0
    }

    var isDigit: Bool { return isdigit(Int32(unicodeValue)) > 0 }
    var isHexDigit: Bool { return isxdigit(Int32(unicodeValue)) > 0 }
    var isWhitespace: Bool { return self == " " || self == "\t" || unicodeValue == 0x0b }
    var isLinebreak: Bool { return self == "\r" || self == "\n" || self == "\r\n" }
}

private extension String.CharacterView {

    mutating func scanCharacters(_ matching: (Character) -> Bool) -> String? {
        var index = endIndex
        for (i, c) in enumerated() {
            if !matching(c) {
                index = self.index(startIndex, offsetBy: i)
                break
            }
        }
        if index > startIndex {
            let string = String(prefix(upTo: index))
            self = suffix(from: index)
            return string
        }
        return nil
    }

    mutating func scanCharacters(head: (Character) -> Bool, tail: (Character) -> Bool) -> String? {
        if let head = scanCharacter(head) {
            if let tail = scanCharacters(tail) {
                return head + tail
            }
            return head
        }
        return nil
    }

    mutating func scanCharacter(_ matching: (Character) -> Bool = { _ in true }) -> String? {
        if let c = first, matching(c) {
            self = dropFirst()
            return String(c)
        }
        return nil
    }

    mutating func scanCharacter(_ character: Character) -> Bool {
        return scanCharacter({ $0 == character }) != nil
    }
}

private extension String.CharacterView {

    mutating func parseWhitespace() -> Token? {
        return scanCharacters({ $0.isWhitespace }).map { Token(.whitespace, $0) }
    }

    mutating func parseLineBreak() -> Token? {
        return scanCharacter({ $0.isLinebreak }).map { Token(.linebreak, $0) }
    }

    mutating func parsePunctuation() -> Token? {
        return scanCharacter({ ":;,".characters.contains($0) }).map { Token(.symbol, $0) }
    }

    mutating func parseStartOfScope() -> Token? {
        return scanCharacter({ "([{\"".characters.contains($0) }).map { Token(.startOfScope, $0) }
    }

    mutating func parseEndOfScope() -> Token? {
        return scanCharacter({ "}])".characters.contains($0) }).map { Token(.endOfScope, $0) }
    }

    mutating func parseOperator() -> Token? {

        func isHead(_ c: Character) -> Bool {
            if "./=­-+!*%<>&|^~?".characters.contains(c) {
                return true
            }
            switch c.unicodeValue {
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

        func isTail(_ c: Character) -> Bool {
            if isHead(c) {
                return true
            }
            switch c.unicodeValue {
            case 0x0300 ... 0x036F,
                 0x1DC0 ... 0x1DFF,
                 0x20D0 ... 0x20FF,
                 0xFE00 ... 0xFE0F,
                 0xFE20 ... 0xFE2F,
                 0xE0100 ... 0xE01EF:
                return true
            default:
                return false
            }
        }

        if var tail = scanCharacter(isHead) {
            var head = ""
            // Tail may only contain dot if head does
            let headWasDot = (tail == ".")
            while let c = scanCharacter({ isTail($0) && (headWasDot || $0 != ".") }) {
                if tail == "/" {
                    if c == "*" {
                        if head == "" {
                            return Token(.startOfScope, "/*")
                        }
                        // Can't return two tokens, so put /* back to be parsed next time
                        self = "/*".characters + self
                        return Token(.symbol, head)
                    } else if c == "/" {
                        if head == "" {
                            return Token(.startOfScope, "//")
                        }
                        // Can't return two tokens, so put // back to be parsed next time
                        self = "//".characters + self
                        return Token(.symbol, head)
                    }
                }
                head += tail
                tail = c
            }
            let op = head + tail
            return Token(op == "<" ? .startOfScope : .symbol, op)
        }
        return nil
    }

    mutating func parseIdentifier() -> Token? {

        func isHead(_ c: Character) -> Bool {
            switch c.unicodeValue {
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

        func isTail(_ c: Character) -> Bool {
            switch c.unicodeValue {
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
            return scanCharacters(head: { isHead($0) || "@#".characters.contains($0) }, tail: isTail)
        }

        let start = self
        if scanCharacter("`") {
            if let identifier = scanIdentifier() {
                if scanCharacter("`") {
                    return Token(.identifier, "`" + identifier + "`")
                }
            }
            self = start
        } else if let identifier = scanIdentifier() {
            if identifier == "#if" {
                return Token(.startOfScope, identifier)
            }
            if identifier == "#endif" {
                return Token(.endOfScope, identifier)
            }
            return Token(.identifier, identifier)
        }
        return nil
    }

    mutating func parseNumber() -> Token? {

        func scanNumber(_ head: @escaping (Character) -> Bool) -> String? {
            return scanCharacters(head: head, tail: { head($0) || $0 == "_" })
        }

        func scanInteger() -> String? {
            return scanNumber({ $0.isDigit })
        }

        var number = ""
        if scanCharacter("0") {
            number = "0"
            if scanCharacter("x") {
                number += "x"
                if let hex = scanNumber({ $0.isHexDigit }) {
                    number += hex
                    if scanCharacter("p"), let power = scanInteger() {
                        number += "p" + power
                    }
                    return Token(.number, number)
                }
                return Token(.error, number + String(self))
            } else if scanCharacter("b") {
                number += "b"
                if let bin = scanNumber({ "01".characters.contains($0) }) {
                    return Token(.number, number + bin)
                }
                return Token(.error, number + String(self))
            } else if scanCharacter("o") {
                number += "o"
                if let octal = scanNumber({ ("0" ... "7").contains($0) }) {
                    return Token(.number, number + octal)
                }
                return Token(.error, number + String(self))
            } else if let tail = scanCharacters({ $0.isDigit || $0 == "_" }) {
                number += tail
            }
        } else if let integer = scanInteger() {
            number += integer
        }
        if !number.isEmpty {
            let endOfInt = self
            if scanCharacter(".") {
                if let fraction = scanInteger() {
                    number += "." + fraction
                } else {
                    self = endOfInt
                }
            }
            let endOfFloat = self
            if let e = scanCharacter({ "eE".characters.contains($0) }) {
                let sign = scanCharacter({ "-+".characters.contains($0) }) ?? ""
                if let exponent = scanInteger() {
                    number += e + sign + exponent
                } else {
                    self = endOfFloat
                }
            }
            return Token(.number, number)
        }
        return nil
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
        if count > 0 {
            return Token(.error, String(self))
        }
        return nil
    }
}

func tokenize(_ source: String) -> [Token] {
    var scopeIndexStack: [Int] = []
    var tokens: [Token] = []
    var characters = source.characters
    var lastNonWhitespaceIndex: Int?
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
                        tokens.append(Token(.stringBody, string))
                    }
                    tokens.append(Token(.endOfScope, "\""))
                    scopeIndexStack.removeLast()
                    return
                }
                escaped = false
            case "(":
                if escaped {
                    if string != "" {
                        tokens.append(Token(.stringBody, string))
                    }
                    scopeIndexStack.append(tokens.count)
                    tokens.append(Token(.startOfScope, "("))
                    return
                }
                escaped = false
            default:
                escaped = false
            }
            string += c
        }
        if string != "" {
            tokens.append(Token(.stringBody, string))
        }
    }

    var comment = ""
    var whitespace = ""

    func flushCommentBodyTokens() {
        if comment != "" {
            tokens.append(Token(.commentBody, comment))
            comment = ""
        }
        if whitespace != "" {
            tokens.append(Token(.whitespace, whitespace))
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
                    tokens.append(Token(.startOfScope, "/*"))
                    continue
                }
            case "*":
                if characters.scanCharacter("/") {
                    flushCommentBodyTokens()
                    tokens.append(Token(.endOfScope, "*/"))
                    scopeIndexStack.removeLast()
                    if scopeIndexStack.last == nil || tokens[scopeIndexStack.last!].string != "/*" {
                        return
                    }
                    continue
                }
            default:
                if c.characters.first?.isLinebreak == true {
                    flushCommentBodyTokens()
                    tokens.append(Token(.linebreak, c))
                    continue
                }
                if c.characters.first?.isWhitespace == true {
                    whitespace += c
                    continue
                }
            }
            if whitespace != "" {
                if comment == "" {
                    tokens.append(Token(.whitespace, whitespace))
                } else {
                    comment += whitespace
                }
                whitespace = ""
            }
            comment += c
        }
        // We shouldn't actually get here, unless code is malformed
        flushCommentBodyTokens()
    }

    func processSingleLineCommentBody() {
        while let c = characters.scanCharacter({ !$0.isLinebreak }) {
            if c.characters.first?.isWhitespace == true {
                whitespace += c
                continue
            }
            if whitespace != "" {
                if comment == "" {
                    tokens.append(Token(.whitespace, whitespace))
                } else {
                    comment += whitespace
                }
                whitespace = ""
            }
            comment += c
        }
        flushCommentBodyTokens()
    }

    func processToken() {
        let token = tokens.last!
        if token.type != .whitespace {
            // Track switch/case statements
            if token.type == .identifier {
                let previousToken: Token? =
                    (lastNonWhitespaceIndex != nil) ? tokens[lastNonWhitespaceIndex!] : nil
                switch previousToken?.string ?? "" {
                case "if", "guard", "while", "for", ".", ",":
                    break
                default:
                    switch token.string {
                    case "switch":
                        nestedSwitches += 1
                    case "default", "case":
                        if nestedSwitches > 0 {
                            tokens[tokens.count - 1] = Token(.endOfScope, token.string)
                            processToken()
                            return
                        }
                    default:
                        break
                    }
                }
            }
            // Fix up optional indicator misidentified as operator
            if token.type == .symbol && token.string.characters.count > 1 &&
                (token.string.hasPrefix("?") || token.string.hasPrefix("!")) &&
                tokens.count > 1 && tokens[tokens.count - 2].type != .whitespace {
                tokens[tokens.count - 1] = Token(.symbol, String(token.string.characters.first!))
                let string = String(token.string.characters.dropFirst())
                tokens.append(Token(string == "<" ? .startOfScope : .symbol, string))
                processToken()
                return
            }
            // Fix up misidentified generic that is actually a pair of operators
            if let lastNonWhitespaceIndex = lastNonWhitespaceIndex {
                let lastToken = tokens[lastNonWhitespaceIndex]
                if lastToken.string == ">" && lastToken.type == .endOfScope {
                    var wasOperator = false
                    switch token.type {
                    case .identifier, .number:
                        switch token.string {
                        case "in", "is", "as", "where", "else":
                            wasOperator = false
                        default:
                            wasOperator = true
                        }
                    case .startOfScope:
                        wasOperator = (token.string == "\"")
                    case .symbol:
                        switch token.string {
                        case "=", "->", ">", ",", ":", ";", "?", "!", ".":
                            wasOperator = false
                        default:
                            wasOperator = true
                        }
                    default:
                        wasOperator = false
                    }
                    if wasOperator {
                        tokens[closedGenericScopeIndexes.last!] = Token(.symbol, "<")
                        closedGenericScopeIndexes.removeLast()
                        if token.type == .symbol && lastNonWhitespaceIndex == tokens.count - 2 {
                            // Need to stitch the operator back together
                            tokens[lastNonWhitespaceIndex] = Token(.symbol, ">" + token.string)
                            tokens.removeLast()
                        } else {
                            tokens[lastNonWhitespaceIndex] = Token(.symbol, ">")
                        }
                        // TODO: this is horrible - need to take a better approach
                        var previousIndex = lastNonWhitespaceIndex - 1
                        var previousToken = tokens[previousIndex]
                        while previousToken.string == ">" {
                            if previousToken.type == .endOfScope {
                                tokens[closedGenericScopeIndexes.last!] = Token(.symbol, "<")
                                closedGenericScopeIndexes.removeLast()
                            }
                            tokens[previousIndex] = Token(.symbol, ">" + tokens[previousIndex + 1].string)
                            tokens.remove(at: previousIndex + 1)
                            previousIndex -= 1
                            previousToken = tokens[previousIndex]
                        }
                        processToken()
                        return
                    }
                }
            }
            lastNonWhitespaceIndex = tokens.count - 1
        }
        if let scopeIndex = scopeIndexStack.last {
            let scope = tokens[scopeIndex]
            if token.closesScopeForToken(scope) {
                scopeIndexStack.removeLast()
                if token.string == ":" {
                    tokens[tokens.count - 1] = Token(.startOfScope, ":")
                    processToken()
                    return
                } else if token.string == "case" || token.string == "default" {
                    scopeIndexStack.append(tokens.count - 1)
                    processToken()
                    return
                } else if token.string == "}" && scope.string == ":" {
                    nestedSwitches -= 1
                } else if token.string.hasPrefix(">") {
                    closedGenericScopeIndexes.append(scopeIndex)
                    tokens[tokens.count - 1] = Token(.endOfScope, ">")
                    if token.string != ">" {
                        // Need to split the token
                        let suffix = String(token.string.characters.dropFirst())
                        tokens.append(Token(.symbol, suffix))
                        processToken()
                        return
                    }
                } else if scopeIndexStack.last != nil && tokens[scopeIndexStack.last!].string == "\"" {
                    processStringBody()
                }
                return
            } else if scope.string == "<" {
                // We think it's a generic at this point, but could be wrong
                switch token.type {
                case .symbol:
                    if !token.string.hasPrefix("?>") && !token.string.hasPrefix("!>") {
                        fallthrough
                    }
                    // Need to split token
                    tokens[tokens.count - 1] = Token(.symbol, String(token.string.characters.first!))
                    let suffix = String(token.string.characters.dropFirst())
                    tokens.append(Token(.symbol, suffix))
                    processToken()
                    return
                case .startOfScope:
                    switch token.string {
                    case "<", "[", "(", ".", ",", ":", "==", "?", "!":
                        break
                    default:
                        // Not a generic scope
                        tokens[scopeIndex] = Token(.symbol, "<")
                        scopeIndexStack.removeLast()
                        processToken()
                        return
                    }
                case .endOfScope:
                    // If we encountered a scope token that wasn't a < or >
                    // then the opening < must have been an operator after all
                    tokens[scopeIndex] = Token(.symbol, "<")
                    scopeIndexStack.removeLast()
                    processToken()
                    return
                default:
                    break
                }
            }
        }
        if token.type == .startOfScope {
            scopeIndexStack.append(tokens.count - 1)
            if token.string == "\"" {
                processStringBody()
            } else if token.string == "/*" {
                processCommentBody()
            } else if token.string == "//" {
                processSingleLineCommentBody()
            }
        } else if token.type == .endOfScope && token.string != "case" && token.string != "default" {
            // Previous scope wasn't closed correctly
            tokens[tokens.count - 1] = Token(.error, token.string)
            return
        }
    }

    while let token = characters.parseToken() {
        tokens.append(token)
        if token.type == .error {
            return tokens
        }
        processToken()
    }

    if let scopeIndex = scopeIndexStack.last {
        switch tokens[scopeIndex].string {
        case "<":
            // If we encountered an end-of-file while a generic scope was
            // still open, the opening < must have been an operator
            tokens[scopeIndex] = Token(.symbol, "<")
            scopeIndexStack.removeLast()
        case "//":
            break
        default:
            if tokens.last?.type != .error {
                // File ended with scope still open
                tokens.append(Token(.error, ""))
            }
        }
    }

    return tokens
}
