//
//  Tokenizer.swift
//  SwiftFormat
//
//  Version 0.9.4
//
//  Created by Nick Lockwood on 11/08/2016.
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

// https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/LexicalStructure.html

public enum TokenType {
    case Number
    case Linebreak
    case StartOfScope
    case EndOfScope
    case Operator
    case StringBody
    case Identifier
    case Whitespace
    case CommentBody
    case Error
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
        case .Whitespace, .CommentBody:
            return true
        case .StartOfScope:
            return string == "//" || string == "/*"
        case .EndOfScope:
            return string == "*/"
        default:
            return false
        }
    }

    public var isWhitespaceOrLinebreak: Bool {
        return type == .Linebreak || type == .Whitespace
    }

    public var isWhitespaceOrCommentOrLinebreak: Bool {
        return type == .Linebreak || isWhitespaceOrComment
    }

    public func closesScopeForToken(token: Token) -> Bool {
        guard token.type == .StartOfScope else {
            return token.type == .EndOfScope && string == ":" &&
                (token.string == "case" || token.string == "default")
        }
        if type == .EndOfScope {
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
            return type == .Linebreak
        default:
            return false
        }
    }
}

public func ==(lhs: Token, rhs: Token) -> Bool {
    return lhs.type == rhs.type && lhs.string == rhs.string
}

private extension Character {

    var unicodeValue: UInt32 {
        return String(self).unicodeScalars.first?.value ?? 0
    }

    var isAlpha: Bool { return isalpha(Int32(unicodeValue)) > 0 }
    var isDigit: Bool { return isdigit(Int32(unicodeValue)) > 0 }
    var isWhitespace: Bool { return self == " " || self == "\t" || unicodeValue == 0x0b }
    var isLinebreak: Bool { return self == "\r" || self == "\n" || self == "\r\n" }
}

private extension String.CharacterView {

    mutating func scanCharacters(matching: (Character) -> Bool) -> String? {
        var index = endIndex
        for (i, c) in enumerate() {
            if !matching(c) {
                index = startIndex.advancedBy(i)
                break
            }
        }
        if index > startIndex {
            let string = String(prefixUpTo(index))
            self = suffixFrom(index)
            return string
        }
        return nil
    }

    mutating func scanCharacter(matching: (Character) -> Bool) -> String? {
        if let c = first where matching(c) {
            self = suffixFrom(startIndex.advancedBy(1))
            return String(c)
        }
        return nil
    }

    mutating func scanCharacter(character: Character) -> Bool {
        return scanCharacter({ $0 == character }) != nil
    }

    mutating func scanInteger() -> String? {
        return scanCharacters({ $0.isDigit })
    }
}

private extension String.CharacterView {

    mutating func parseToken(type: TokenType, oneOf matching: (Character) -> Bool) -> Token? {
        return scanCharacter(matching).map { Token(type, $0) }
    }

    mutating func parseToken(type: TokenType, oneOrMore matching: (Character) -> Bool) -> Token? {
        return scanCharacters(matching).map { Token(type, $0) }
    }

    mutating func parseToken(type: TokenType, oneOf characters: String.CharacterView) -> Token? {
        return parseToken(type, oneOf: { characters.contains($0) })
    }
}

private extension String.CharacterView {

    mutating func parseWhitespace() -> Token? {
        return parseToken(.Whitespace, oneOrMore: { $0.isWhitespace })
    }

    mutating func parseLineBreak() -> Token? {
        return parseToken(.Linebreak, oneOf: { $0.isLinebreak })
    }

    mutating func parsePunctuation() -> Token? {
        return parseToken(.Operator, oneOf: ":;,".characters)
    }

    mutating func parseStartOfScope() -> Token? {
        return parseToken(.StartOfScope, oneOf: "([{\"".characters)
    }

    mutating func parseEndOfScope() -> Token? {
        return parseToken(.EndOfScope, oneOf: "}])".characters)
    }

    mutating func parseOperator() -> Token? {

        func isHead(c: Character) -> Bool {
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

        func isTail(c: Character) -> Bool {
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
                            return Token(.StartOfScope, "/*")
                        }
                        // Can't return two tokens, so put /* back to be parsed next time
                        self = "/*".characters + self
                        return Token(.Operator, head)
                    } else if c == "/" {
                        if head == "" {
                            return Token(.StartOfScope, "//")
                        }
                        // Can't return two tokens, so put // back to be parsed next time
                        self = "//".characters + self
                        return Token(.Operator, head)
                    }
                }
                head += tail
                tail = c
            }
            let op = head + tail
            return Token(op == "<" ? .StartOfScope : .Operator, op)
        }
        return nil
    }

    mutating func parseIdentifier() -> Token? {

        func isHead(c: Character) -> Bool {
            if c.isAlpha || c == "_" || c == "$" {
                return true
            }
            switch c.unicodeValue {
            case 0x00A8, 0x00AA, 0x00AD, 0x00AF,
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

        func isTail(c: Character) -> Bool {
            if isHead(c) || c.isDigit {
                return true
            }
            switch c.unicodeValue {
            case 0x0300 ... 0x036F,
                0x1DC0 ... 0x1DFF,
                0x20D0 ... 0x20FF,
                0xFE20 ... 0xFE2F:
                return true
            default:
                return false
            }
        }

        func scanIdentifier() -> String? {
            if let head = scanCharacter({ isHead($0) || $0 == "@" || $0 == "#" }) {
                if let tail = scanCharacters(isTail) {
                    return head + tail
                }
                return head
            }
            return nil
        }

        let start = self
        if scanCharacter("`") {
            if let identifier = scanIdentifier() {
                if scanCharacter("`") {
                    return Token(.Identifier, "`" + identifier + "`")
                }
            }
            self = start
        } else if let identifier = scanIdentifier() {
            if identifier == "#if" {
                return Token(.StartOfScope, identifier)
            }
            if identifier == "#endif" {
                return Token(.EndOfScope, identifier)
            }
            return Token(.Identifier, identifier)
        }
        return nil
    }

    mutating func parseNumber() -> Token? {
        var number = ""
        if let integer = scanInteger() {
            number = integer
            let endOfInt = self
            if scanCharacter(".") {
                if let fraction = scanInteger() {
                    number += "." + fraction
                } else {
                    self = endOfInt
                }
            }
            let endOfFloat = self
            if let e = scanCharacter({ $0 == "e" || $0 == "E" }) {
                let sign = scanCharacter({ $0 == "-" || $0 == "+" }) ?? ""
                if let exponent = scanInteger() {
                    number += e + sign + exponent
                } else {
                    self = endOfFloat
                }
            }
            return Token(.Number, number)
        }
        return nil
    }

    mutating func parseToken() -> Token? {
        // Have to split into groups for Swift to be able to process this
        if let token = parseWhitespace() ??
            parseLineBreak() ??
            parseIdentifier() ??
            parseNumber() {
            return token
        }
        if let token = parseOperator() ??
            parsePunctuation() ??
            parseStartOfScope() ??
            parseEndOfScope() {
            return token
        }
        if count > 0 {
            return Token(.Error, String(self))
        }
        return nil
    }
}

func tokenize(source: String) -> [Token] {
    var scopeIndexStack: [Int] = []
    var tokens: [Token] = []
    var characters = source.characters
    var lastNonWhitespaceIndex: Int?
    var closedGenericScopeIndexes: [Int] = []
    var nestedSwitches = 0

    func processStringBody() {
        var string = ""
        var escaped = false
        while let c = characters.scanCharacter({ _ in true }) {
            switch c {
            case "\\":
                escaped = !escaped
            case "\"":
                if !escaped {
                    if string != "" {
                        tokens.append(Token(.StringBody, string))
                    }
                    tokens.append(Token(.EndOfScope, "\""))
                    scopeIndexStack.popLast()
                    return
                }
                escaped = false
            case "(":
                if escaped {
                    if string != "" {
                        tokens.append(Token(.StringBody, string))
                    }
                    scopeIndexStack.append(tokens.count)
                    tokens.append(Token(.StartOfScope, "("))
                    return
                }
                escaped = false
            default:
                escaped = false
            }
            string += c
        }
        if string != "" {
            tokens.append(Token(.StringBody, string))
        }
    }

    var comment = ""
    var whitespace = ""

    func flushCommentBodyTokens() {
        if comment != "" {
            tokens.append(Token(.CommentBody, comment))
            comment = ""
        }
        if whitespace != "" {
            tokens.append(Token(.Whitespace, whitespace))
            whitespace = ""
        }
    }

    func processCommentBody() {
        while let c = characters.scanCharacter({ _ in true }) {
            switch c {
            case "/":
                if characters.scanCharacter("*") {
                    flushCommentBodyTokens()
                    scopeIndexStack.append(tokens.count)
                    tokens.append(Token(.StartOfScope, "/*"))
                    continue
                }
            case "*":
                if characters.scanCharacter("/") {
                    flushCommentBodyTokens()
                    tokens.append(Token(.EndOfScope, "*/"))
                    scopeIndexStack.popLast()
                    if scopeIndexStack.last == nil || tokens[scopeIndexStack.last!].string != "/*" {
                        return
                    }
                    continue
                }
            default:
                if c.characters.first?.isLinebreak == true {
                    flushCommentBodyTokens()
                    tokens.append(Token(.Linebreak, c))
                    continue
                }
                if c.characters.first?.isWhitespace == true {
                    whitespace += c
                    continue
                }
            }
            if whitespace != "" {
                if comment == "" {
                    tokens.append(Token(.Whitespace, whitespace))
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
                    tokens.append(Token(.Whitespace, whitespace))
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
        if token.type != .Whitespace {
            // Track switch/case statements
            if token.type == .Identifier {
                if token.string == "switch" {
                    nestedSwitches += 1
                } else if nestedSwitches > 0 && (token.string == "case" || token.string == "default") {
                    let lastToken = tokens[lastNonWhitespaceIndex!]
                    if lastToken.string != "if" && lastToken.string != "." {
                        tokens[tokens.count - 1] = Token(.EndOfScope, token.string)
                        scopeIndexStack.append(tokens.count - 1)
                        processToken()
                        return
                    }
                }
            }
            // Fix up generic misidentified as ?< or !< operator
            if token.type == .Operator && (token.string == "?<" || token.string == "!<") {
                if tokens[tokens.count - 2].string == "init" {
                    tokens[tokens.count - 1] = Token(.Operator, String(token.string.characters.first!))
                    tokens.append(Token(.StartOfScope, "<"))
                    processToken()
                    return
                }
            }
            // Fix up misidentified generic that is actually a pair of operators
            if let lastNonWhitespaceIndex = lastNonWhitespaceIndex {
                let lastToken = tokens[lastNonWhitespaceIndex]
                if lastToken.string == ">" && lastToken.type == .EndOfScope {
                    var wasOperator = false
                    switch token.type {
                    case .Identifier, .Number:
                        switch token.string {
                        case "in", "is", "as", "where", "else":
                            wasOperator = false
                        default:
                            wasOperator = true
                        }
                    case .StartOfScope:
                        wasOperator = (token.string == "\"")
                    case .Operator:
                        wasOperator = !["=", "->", ">", ",", ":", ";", "?", "!", "."].contains(token.string)
                    default:
                        wasOperator = false
                    }
                    if wasOperator {
                        tokens[closedGenericScopeIndexes.last!] = Token(.Operator, "<")
                        closedGenericScopeIndexes.popLast()
                        if token.type == .Operator && lastNonWhitespaceIndex == tokens.count - 2 {
                            // Need to stitch the operator back together
                            tokens[lastNonWhitespaceIndex] = Token(.Operator, ">" + token.string)
                            tokens.removeLast()
                        } else {
                            tokens[lastNonWhitespaceIndex] = Token(.Operator, ">")
                        }
                        // TODO: this is horrible - need to take a better approach
                        var previousIndex = lastNonWhitespaceIndex - 1
                        var previousToken = tokens[previousIndex]
                        while previousToken.string == ">" {
                            if previousToken.type == .EndOfScope {
                                tokens[closedGenericScopeIndexes.last!] = Token(.Operator, "<")
                                closedGenericScopeIndexes.popLast()
                            }
                            tokens[previousIndex] = Token(.Operator, ">" + tokens[previousIndex + 1].string)
                            tokens.removeAtIndex(previousIndex + 1)
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
                scopeIndexStack.popLast()
                if token.string == ":" {
                    tokens[tokens.count - 1] = Token(.StartOfScope, ":")
                } else if token.string == "}" && scope.string == ":" {
                    nestedSwitches -= 1
                } else if token.string.hasPrefix(">") {
                    closedGenericScopeIndexes.append(scopeIndex)
                    tokens[tokens.count - 1] = Token(.EndOfScope, ">")
                    if token.string != ">" {
                        // Need to split the token
                        let suffix = String(token.string.characters.dropFirst())
                        tokens.append(Token(.Operator, suffix))
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
                case .Operator:
                    if !token.string.hasPrefix("?>") && !token.string.hasPrefix("!>") {
                        fallthrough
                    }
                    // Need to split token
                    tokens[tokens.count - 1] = Token(.Operator, String(token.string.characters.first!))
                    let suffix = String(token.string.characters.dropFirst())
                    tokens.append(Token(.Operator, suffix))
                    processToken()
                    return
                case .StartOfScope:
                    if !["<", "[", "(", ".", ",", ":", "==", "?", "!"].contains(token.string) {
                        // Not a generic scope
                        tokens[scopeIndex] = Token(.Operator, "<")
                        scopeIndexStack.popLast()
                        processToken()
                        return
                    }
                case .EndOfScope:
                    // If we encountered a scope token that wasn't a < or >
                    // then the opening < must have been an operator after all
                    tokens[scopeIndex] = Token(.Operator, "<")
                    scopeIndexStack.popLast()
                    processToken()
                    return
                default:
                    break
                }
            }
        }
        if token.type == .StartOfScope {
            scopeIndexStack.append(tokens.count - 1)
            if token.string == "\"" {
                processStringBody()
            } else if token.string == "/*" {
                processCommentBody()
            } else if token.string == "//" {
                processSingleLineCommentBody()
            }
        } else if token.type == .EndOfScope && token.string != "case" && token.string != "default" {
            // Previous scope wasn't closed correctly
            tokens[tokens.count - 1] = Token(.Error, token.string)
            return
        }
    }

    while let token = characters.parseToken() {
        tokens.append(token)
        if token.type == .Error {
            return tokens
        }
        processToken()
    }

    if let scopeIndex = scopeIndexStack.last {
        switch tokens[scopeIndex].string {
        case "<":
            // If we encountered an end-of-file while a generic scope was
            // still open, the opening < must have been an operator
            tokens[scopeIndex] = Token(.Operator, "<")
            scopeIndexStack.popLast()
        case "//":
            break
        default:
            if tokens.last?.type != .Error {
                // File ended with scope still open
                tokens.append(Token(.Error, ""))
            }
        }
    }

    return tokens
}
