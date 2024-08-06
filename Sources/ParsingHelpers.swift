//
//  ParsingHelpers.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 08/04/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

import Foundation

// MARK: shared helper methods

public extension Formatter {
    /// Returns the index of the first token of the line containing the specified index
    func startOfLine(at index: Int, excludingIndent: Bool = false) -> Int {
        var index = min(index, tokens.count)
        while let token = token(at: index - 1) {
            if case .linebreak = token {
                break
            }
            index -= 1
        }
        if excludingIndent, case .space? = token(at: index) {
            return index + 1
        }
        return index
    }

    /// Returns the index of the linebreak token at the end of the line containing the specified index
    func endOfLine(at index: Int) -> Int {
        var index = index
        while let token = token(at: index) {
            if case .linebreak = token {
                break
            }
            index += 1
        }
        return index
    }

    /// Whether or not the two indices represent tokens on the same line
    func onSameLine(_ lhs: Int, _ rhs: Int) -> Bool {
        startOfLine(at: lhs) == startOfLine(at: rhs)
    }

    /// Returns the current space at the start of the line containing the specified index
    func currentIndentForLine(at index: Int) -> String {
        if case let .space(string)? = token(at: startOfLine(at: index)) {
            return string
        }
        return ""
    }

    /// Returns the length (in characters) of the specified token
    func tokenLength(_ token: Token) -> Int {
        let tabWidth = options.tabWidth > 0 ? options.tabWidth : options.indent.count
        return token.columnWidth(tabWidth: tabWidth)
    }

    /// Returns the length (in characters) of the line at the specified index
    func lineLength(at index: Int) -> Int {
        lineLength(upTo: endOfLine(at: index))
    }

    /// Returns the length (in characters) up to (but not including) the specified token index
    func lineLength(upTo index: Int) -> Int {
        lineLength(from: startOfLine(at: index), upTo: index)
    }

    /// Returns the length (in characters) of the specified token range
    func lineLength(from start: Int, upTo end: Int) -> Int {
        if options.assetLiteralWidth == .actualWidth {
            return tokens[start ..< end].reduce(0) { total, token in
                total + tokenLength(token)
            }
        }
        var length = 0
        var index = start
        while index < end {
            let token = tokens[index]
            switch token {
            case .keyword("#colorLiteral"), .keyword("#imageLiteral"):
                guard let startIndex = self.index(of: .startOfScope("("), after: index),
                      let endIndex = endOfScope(at: startIndex)
                else {
                    fallthrough
                }
                length += 2 // visible length of asset literal in Xcode
                index = endIndex + 1
            default:
                length += tokenLength(token)
                index += 1
            }
        }
        return length
    }

    /// Returns white space made up of indent characters equivalent to the specified width
    func spaceEquivalentToWidth(_ width: Int) -> String {
        if !options.smartTabs, options.useTabs, options.tabWidth > 0 {
            let tabs = width / options.tabWidth
            let remainder = width % options.tabWidth
            return String(repeating: "\t", count: tabs) + String(repeating: " ", count: remainder)
        }
        return String(repeating: " ", count: width)
    }

    /// Returns white space made up of indent characters equvialent to the specified token range
    func spaceEquivalentToTokens(from start: Int, upTo end: Int) -> String {
        if !options.smartTabs, options.useTabs, options.tabWidth > 0 {
            return spaceEquivalentToWidth(lineLength(from: start, upTo: end))
        }
        var result = ""
        var index = start
        while index < end {
            let token = tokens[index]
            switch token {
            case let .space(string):
                result += string
            case .keyword("#colorLiteral"), .keyword("#imageLiteral"):
                guard let startIndex = self.index(of: .startOfScope("("), after: index),
                      let endIndex = endOfScope(at: startIndex)
                else {
                    fallthrough
                }
                let length = lineLength(from: index, upTo: endIndex + 1)
                result += String(repeating: " ", count: length)
                index = endIndex
            default:
                result += String(repeating: " ", count: tokenLength(token))
            }
            index += 1
        }
        return result
    }

    /// Returns the starting token for the containing scope at the specified index
    func currentScope(at index: Int) -> Token? {
        last(.startOfScope, before: index)
    }

    /// Returns the index of the starting token for the current scope
    func startOfScope(at index: Int) -> Int? {
        self.index(of: .startOfScope, before: index).flatMap {
            if [.startOfScope("//"), .startOfScope("#!")].contains(tokens[$0]),
               self.index(of: .linebreak, after: $0) ?? index < index
            {
                return nil
            }
            return $0
        }
    }

    /// Returns the index of the ending token for the current scope
    func endOfScope(at index: Int) -> Int? {
        // TODO: should this return the closing `}` for `switch { ...` instead of nested `case`?
        var startIndex: Int
        guard var startToken = token(at: index) else { return nil }
        if case .startOfScope = startToken {
            startIndex = index
        } else if let index = self.index(of: .startOfScope, before: index, if: {
            ![.startOfScope("//"), .startOfScope("#!")].contains($0)
        }) {
            startToken = tokens[index]
            startIndex = index
        } else {
            return nil
        }
        guard startToken == .startOfScope("{") else {
            var endIndex: Int? = startIndex
            while let index = endIndex, !tokens[index].isEndOfScope(startToken) {
                endIndex = self.index(after: index, where: {
                    $0.isEndOfScope(startToken) || $0 == .endOfScope("#endif")
                })
            }
            return endIndex
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

    /// Returns the end of the expression at the specified index, optionally stopping at any of the specified tokens
    func endOfExpression(at index: Int, upTo delimiters: [Token]) -> Int? {
        var index: Int? = index
        if token(at: index!)?.isEndOfScope == true {
            index = self.index(of: .nonSpaceOrLinebreak, after: index!)
        }
        var lastIndex = index
        var wasOperator = true
        while var i = index {
            let token = tokens[i]
            if delimiters.contains(token) {
                return lastIndex
            }
            switch token {
            case .operator(_, .infix):
                wasOperator = true
            case .operator(_, .prefix) where wasOperator, .operator(_, .postfix):
                break
            case .keyword("as"):
                wasOperator = true
                if case let .operator(name, .postfix)? = self.token(at: i + 1),
                   ["?", "!"].contains(name)
                {
                    i += 1
                }
            case .number, .identifier:
                guard wasOperator else {
                    return lastIndex
                }
                wasOperator = false
            case .startOfScope("<"),
                 .startOfScope where wasOperator,
                 .startOfScope("{") where isStartOfClosure(at: i),
                 .startOfScope("(") where isSubscriptOrFunctionCall(at: i),
                 .startOfScope("[") where isSubscriptOrFunctionCall(at: i):
                wasOperator = false
                guard let endIndex = endOfScope(at: i) else {
                    return nil
                }
                i = endIndex
            default:
                return lastIndex
            }
            lastIndex = i
            index = self.index(of: .nonSpaceOrCommentOrLinebreak, after: i)
        }
        return lastIndex
    }
}

enum ScopeType {
    case array
    case arrayType
    case captureList
    case dictionary
    case dictionaryType
    case `subscript`
    case tuple
    case tupleType

    var isType: Bool {
        switch self {
        case .array, .captureList, .dictionary, .subscript, .tuple:
            return false
        case .arrayType, .dictionaryType, .tupleType:
            return true
        }
    }
}

extension Formatter {
    /// Returns true if a token at this position is expected to be a type.
    /// Note: Doesn't actually look at the token to see if it plausibly *is* a type.
    func isTypePosition(at index: Int) -> Bool {
        guard let prevIndex = self.index(
            of: .nonSpaceOrCommentOrLinebreak,
            before: index
        ) else {
            return false
        }
        switch tokens[prevIndex] {
        case .operator("->", .infix), .startOfScope("<"),
             .keyword("is"), .keyword("as"):
            return true
        case .delimiter(":"), .delimiter(","):
            // Check for property declaration
            if let token = last(.keyword, before: index),
               [.keyword("let"), .keyword("var")].contains(token)
            {
                return true
            }
            // Check for function declaration
            if let scopeStart = startOfScope(at: index) {
                switch tokens[scopeStart] {
                case .startOfScope("("):
                    if last(.keyword, before: scopeStart) == .keyword("func") {
                        return true
                    }
                    fallthrough
                case .startOfScope("["):
                    return isInClosureArguments(at: scopeStart)
                default:
                    break
                }
            }
            fallthrough
        default:
            return scopeType(at: index)?.isType ?? false
        }
    }

    /// Returns the type of the containing scope at the specified index
    func scopeType(at index: Int) -> ScopeType? {
        guard let token = token(at: index) else {
            return nil
        }
        guard case .startOfScope = token else {
            guard let startIndex = self.index(of: .startOfScope, before: index) else {
                return nil
            }
            return scopeType(at: startIndex)
        }
        switch token {
        case .startOfScope("["), .startOfScope("("):
            guard let endIndex = endOfScope(at: index) else {
                return nil
            }
            var isType = false
            if let nextIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, after: endIndex, if: {
                $0.isOperator(".")
            }), [.identifier("self"), .identifier("init")]
                .contains(next(.nonSpaceOrCommentOrLinebreak, after: nextIndex))
            {
                isType = true
            } else if next(.nonSpaceOrComment, after: endIndex) == .startOfScope("(") {
                isType = true
            } else if var prevIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, before: index) {
                if tokens[prevIndex].isAttribute {
                    prevIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, before: prevIndex) ?? prevIndex
                }
                switch tokens[prevIndex] {
                case .identifier, .endOfScope(")"), .endOfScope("]"),
                     .operator("?", _), .operator("!", _),
                     .endOfScope where token.isStringDelimiter:
                    if tokens[prevIndex + 1 ..< index].contains(where: { $0.isLinebreak }) {
                        break
                    }
                    return .subscript
                case .startOfScope("{") where isInClosureArguments(at: index):
                    return .captureList
                case .delimiter(":"), .delimiter(","):
                    // Check for type declaration
                    if let scopeStart = self.index(of: .startOfScope, before: prevIndex) {
                        switch tokens[scopeStart] {
                        case .startOfScope("("):
                            if last(.keyword, before: scopeStart) == .keyword("func") {
                                isType = true
                                break
                            }
                            fallthrough
                        case .startOfScope("["):
                            guard let type = scopeType(at: scopeStart) else {
                                return nil
                            }
                            isType = type.isType
                        default:
                            break
                        }
                    }
                    if let token = last(.keyword, before: index),
                       [.keyword("let"), .keyword("var")].contains(token)
                    {
                        isType = true
                    }
                case .operator("->", _), .startOfScope("<"):
                    isType = true
                case .startOfScope("["), .startOfScope("("):
                    guard let type = scopeType(at: prevIndex) else {
                        return nil
                    }
                    isType = type.isType
                case .operator("=", .infix):
                    isType = lastSignificantKeyword(at: prevIndex) == "typealias"
                default:
                    break
                }
            }
            if token == .startOfScope("(") {
                return isType ? .tupleType : .tuple
            }
            if !isType {
                return self.index(of: .delimiter(":"), after: index) == nil ? .array : .dictionary
            }
            return self.index(of: .delimiter(":"), after: index) == nil ? .arrayType : .dictionaryType
        default:
            return nil
        }
    }

    /// Returns true if the token at specified index is a modifier
    func isModifier(at index: Int) -> Bool {
        guard let token = token(at: index), token.isModifierKeyword else {
            return false
        }
        if token == .keyword("class"),
           let nextToken = next(.nonSpaceOrCommentOrLinebreak, after: index)
        {
            return nextToken.isDeclarationTypeKeyword || nextToken.isModifierKeyword
        }
        return true
    }

    /// Returns true if the modifiers list for the given declaration contain a
    /// modifier matching the specified predicate
    func modifiersForDeclaration(at index: Int, contains: (Int, String) -> Bool) -> Bool {
        var index = index
        while var prevIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, before: index) {
            let token = tokens[prevIndex]
            switch token {
            case _ where token.isModifierKeyword || token.isAttribute:
                if contains(prevIndex, token.string) {
                    return true
                }
            case .endOfScope(")"):
                guard let startIndex = self.index(of: .startOfScope("("), before: prevIndex),
                      last(.nonSpaceOrCommentOrLinebreak, before: startIndex, if: {
                          $0.isAttribute || _FormatRules.allModifiers.contains($0.string) || $0 == .endOfScope(">")
                      }) != nil
                else {
                    return false
                }
                prevIndex = startIndex
            case .endOfScope(">"):
                guard let startIndex = self.index(of: .startOfScope("<"), before: prevIndex),
                      last(.nonSpaceOrCommentOrLinebreak, before: startIndex, if: { $0.isAttribute }) != nil
                else {
                    return false
                }
                prevIndex = startIndex
            case .identifier:
                guard let startIndex = startOfAttribute(at: prevIndex),
                      let nextIndex = self.index(of: .operator(".", .infix), after: startIndex)
                else {
                    return false
                }
                prevIndex = nextIndex
            default:
                return false
            }
            index = prevIndex
        }
        return false
    }

    /// Returns true if the modifiers list for the given declaration contain the
    /// specified modifier
    func modifiersForDeclaration(at index: Int, contains: String) -> Bool {
        modifiersForDeclaration(at: index, contains: { $1 == contains })
    }

    /// Returns the index of the specified modifier for a given declaration, or
    /// nil if the type doesn't have that modifier
    func indexOfModifier(_ modifier: String, forDeclarationAt index: Int) -> Int? {
        var i: Int?
        return modifiersForDeclaration(at: index, contains: {
            i = $0
            return $1 == modifier
        }) ? i : nil
    }

    /// Returns the index of the first modifier in a list
    func startOfModifiers(at index: Int, includingAttributes: Bool) -> Int {
        var startIndex = index
        _ = modifiersForDeclaration(at: index, contains: { i, name in
            if !includingAttributes, name.hasPrefix("@") {
                return true
            }
            startIndex = i
            return false
        })
        return startIndex
    }

    /// Return true if token at specified index in a function in the given list
    func isSymbol(at i: Int, in names: Set<String>) -> Bool {
        // TODO: more sophisticated checks involving full signature, namespace, etc
        guard let name = token(at: i)?.unescaped() else {
            return false
        }
        return names.contains(name)
    }

    /// Gather declared variable names, starting at index after let/var keyword
    func processDeclaredVariables(at index: inout Int, names: inout Set<String>) {
        processDeclaredVariables(at: &index, names: &names, removeSelfKeyword: nil,
                                 onlyLocal: false, scopeAllowsImplicitSelfRebinding: false)
    }

    /// Returns true if token is inside the return type of a function or subscript
    func isInReturnType(at i: Int) -> Bool {
        startOfReturnType(at: i) != nil
    }

    /// Returns the index of the `->` operator for the current return type declaration if
    /// the specified index is in a return type declaration.
    func startOfReturnType(at i: Int) -> Int? {
        guard let startIndex = indexOfLastSignificantKeyword(
            at: i, excluding: ["throws", "rethrows"]
        ), ["func", "subscript"].contains(tokens[startIndex].string) else {
            return nil
        }

        let endIndex = index(of: .startOfScope("{"), after: i) ?? i

        return index(of: .operator("->", .infix), in: startIndex + 1 ..< endIndex)
    }

    func isStartOfClosure(at i: Int, in _: Token? = nil) -> Bool {
        guard token(at: i) == .startOfScope("{") else {
            return false
        }
        if isConditionalStatement(at: i) {
            if let endIndex = endOfScope(at: i),
               [.startOfScope("("), .operator(".", .infix)]
               .contains(next(.nonSpaceOrComment, after: endIndex) ?? .space("")) ||
               next(.nonSpaceOrCommentOrLinebreak, after: endIndex) == .startOfScope("{")
            {
                return true
            }
            return false
        }
        guard var prevIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: i) else {
            return true
        }
        switch tokens[prevIndex] {
        case .startOfScope("("), .startOfScope("["), .startOfScope("{"),
             .operator(_, .infix), .operator(_, .prefix), .delimiter, .keyword("return"),
             .keyword("in"), .keyword("where"), .keyword("try"), .keyword("throw"), .keyword("await"):
            return true
        case .operator(_, .none),
             .keyword("deinit"), .keyword("catch"), .keyword("else"), .keyword("repeat"),
             .keyword("throws"), .keyword("rethrows"):
            return false
        case .endOfScope("}"):
            guard let startOfScope = index(of: .startOfScope("{"), before: prevIndex) else {
                return false
            }
            return !isStartOfClosure(at: startOfScope)
        case .endOfScope(")"), .endOfScope(">"):
            guard var startOfScope = index(of: .startOfScope, before: prevIndex),
                  var prev = index(of: .nonSpaceOrCommentOrLinebreak, before: startOfScope)
            else {
                return true
            }
            if tokens[prevIndex] == .endOfScope(">"), tokens[prev] == .endOfScope(")") {
                startOfScope = index(of: .startOfScope, before: prev) ?? startOfScope
                prev = index(of: .nonSpaceOrCommentOrLinebreak, before: startOfScope) ?? prev
            }
            switch tokens[prev] {
            case .identifier:
                prevIndex = prev
            case .operator("?", .postfix), .operator("!", .postfix):
                switch token(at: prev - 1) {
                case .identifier?:
                    prevIndex = prev - 1
                case .keyword("init")?:
                    return false
                default:
                    return true
                }
            case .operator("->", .infix), .keyword("init"), .keyword("subscript"), .keyword("throws"):
                return false
            case .endOfScope(">"):
                guard let startIndex = index(of: .startOfScope("<"), before: prev) else {
                    fatalError("Expected <", at: prev - 1)
                    return false
                }
                guard let prevIndex = index(of: .nonSpaceOrComment, before: startIndex, if: {
                    $0.isIdentifier
                }) else {
                    return false
                }
                return last(.nonSpaceOrCommentOrLinebreak, before: prevIndex) != .keyword("func")
            default:
                if let nextIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: i),
                   isAccessorKeyword(at: nextIndex) || isAccessorKeyword(at: prevIndex)
                {
                    return false
                } else {
                    return !isConditionalStatement(at: startOfScope)
                }
            }
            fallthrough
        case .identifier, .number, .operator("?", .postfix), .operator("!", .postfix),
             .endOfScope where tokens[prevIndex].isStringDelimiter:
            if let nextIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: i),
               isAccessorKeyword(at: nextIndex) || isAccessorKeyword(at: prevIndex)
            {
                return false
            }
            guard let prevKeywordIndex = indexOfLastSignificantKeyword(at: prevIndex) else {
                return true
            }
            switch tokens[prevKeywordIndex].string {
            case "var":
                if lastIndex(of: .operator("=", .infix), in: prevKeywordIndex + 1 ..< i) != nil {
                    return true
                }
                var index = prevKeywordIndex
                while let nextIndex = self.index(of: .nonSpaceOrComment, after: index),
                      nextIndex < i
                {
                    switch tokens[nextIndex] {
                    case .operator("=", .infix):
                        return true
                    case .linebreak:
                        guard let nextIndex =
                            self.index(of: .nonSpaceOrCommentOrLinebreak, after: nextIndex)
                        else {
                            return true
                        }
                        if tokens[nextIndex] != .startOfScope("{"),
                           isEndOfStatement(at: index), isStartOfStatement(at: nextIndex)
                        {
                            return true
                        }
                        index = nextIndex
                    default:
                        index = nextIndex
                    }
                }
                return false
            case "class", "actor", "struct", "enum", "protocol", "extension",
                 "func", "subscript", "catch":
                return false
            case "throws", "rethrows":
                return next(.keyword, after: prevKeywordIndex) == .keyword("in")
            default:
                return true
            }
        case .keyword, .endOfScope("]"), .endOfScope(">"):
            return false
        default:
            return true
        }
    }

    func isInClosureArguments(at i: Int) -> Bool {
        var i = i
        while let token = token(at: i) {
            switch token {
            case .keyword("in"), .keyword("throws"), .keyword("rethrows"), .identifier("async"):
                guard let scopeIndex = index(of: .startOfScope, before: i, if: {
                    $0 == .startOfScope("{")
                }), isStartOfClosure(at: scopeIndex) else {
                    return false
                }
                if token != .keyword("in"),
                   let arrowIndex = index(of: .operator("->", .infix), after: i),
                   next(.keyword, after: arrowIndex) != .keyword("in")
                {
                    return false
                }
                return true
            case .startOfScope("("), .startOfScope("["), .startOfScope("<"),
                 .endOfScope(")"), .endOfScope("]"), .endOfScope(">"),
                 .keyword where token.isAttribute, _ where token.isComment:
                break
            case .keyword, .startOfScope, .endOfScope:
                return false
            default:
                break
            }
            i += 1
        }
        return false
    }

    func isAccessorKeyword(at i: Int, checkKeyword: Bool = true) -> Bool {
        guard !checkKeyword ||
            ["get", "set", "willSet", "didSet", "init", "_modify"].contains(token(at: i)?.string ?? ""),
            var prevIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: i)
        else {
            return false
        }
        if tokens[prevIndex] == .endOfScope("}"),
           let startIndex = index(of: .startOfScope("{"), before: prevIndex),
           let prev = index(of: .nonSpaceOrCommentOrLinebreak, before: startIndex)
        {
            prevIndex = prev
            if tokens[prevIndex] == .endOfScope(")"),
               let startIndex = index(of: .startOfScope("("), before: prevIndex),
               let prev = index(of: .nonSpaceOrCommentOrLinebreak, before: startIndex)
            {
                prevIndex = prev
            }
            return isAccessorKeyword(at: prevIndex)
        } else if tokens[prevIndex] == .startOfScope("{") {
            switch lastSignificantKeyword(at: prevIndex, excluding: ["where"]) {
            case "var"?, "subscript"?:
                return true
            default:
                return false
            }
        }
        return false
    }

    /// Returns true if the token at the specified index is part of a conditional statement
    func isConditionalStatement(at i: Int, excluding: Set<String> = []) -> Bool {
        startOfConditionalStatement(at: i, excluding: excluding) != nil
    }

    /// If the token at the specified index is part of a conditional statement, returns the index of the first
    /// token in the statement (e.g. `if`, `guard`, `while`, etc.), otherwise returns nil
    func startOfConditionalStatement(at i: Int, excluding: Set<String> = []) -> Int? {
        guard var index = indexOfLastSignificantKeyword(at: i, excluding: excluding.union(["else"])) else {
            return nil
        }

        if tokens[index] == .keyword("case"), let i = self.index(
            of: .nonSpaceOrCommentOrLinebreak,
            before: index,
            if: { $0 != .delimiter(",") }
        ) {
            index = i
        }

        switch tokens[index].string {
        case "let", "var":
            guard let prevIndex = self
                .index(of: .nonSpaceOrCommentOrLinebreak, before: index)
            else {
                return nil
            }
            switch tokens[prevIndex] {
            case let .keyword(name) where
                ["if", "guard", "while", "for", "case", "catch"].contains(name):
                return prevIndex
            case .delimiter(","):
                return startOfConditionalStatement(at: prevIndex)
            default:
                return nil
            }
        case "if", "guard", "while", "for", "case", "where", "switch":
            return index
        default:
            return nil
        }
    }

    func lastSignificantKeyword(at i: Int, excluding: Set<String> = []) -> String? {
        guard let index = indexOfLastSignificantKeyword(at: i, excluding: excluding),
              case let .keyword(keyword) = tokens[index]
        else {
            return nil
        }
        return keyword
    }

    func indexOfLastSignificantKeyword(at i: Int, excluding: Set<String> = []) -> Int? {
        guard let token = token(at: i),
              let index = token.isKeyword ? i : index(of: .keyword, before: i),
              case let .keyword(keyword) = tokens[index]
        else {
            return nil
        }

        func isAfterBrace(_ index: Int, _ i: Int) -> Bool {
            if let scopeStart = lastIndex(of: .startOfScope, in: index ..< i) {
                return isAfterBrace(index, scopeStart)
            }
            guard let braceIndex = lastIndex(
                of: .endOfScope("}"),
                in: index ..< i
            ) else {
                return false
            }
            guard let nextToken = next(.nonSpaceOrComment, after: braceIndex),
                  !nextToken.isOperator(ofType: .infix),
                  !nextToken.isOperator(ofType: .postfix),
                  nextToken != .startOfScope("("),
                  nextToken != .startOfScope("{")
            else {
                return isAfterBrace(index, braceIndex)
            }
            return true
        }

        if isAfterBrace(index, i) {
            return nil
        }

        switch keyword {
        case let name where name.hasPrefix("#") || excluding.contains(name):
            fallthrough
        case "in", "is", "as", "try", "await":
            return indexOfLastSignificantKeyword(at: index - 1, excluding: excluding)
        default:
            return index
        }
    }

    /// Returns true if the token at the specified index is part of an @attribute
    func isAttribute(at i: Int) -> Bool {
        startOfAttribute(at: i) != nil
    }

    /// If the token at the specified index is part of an @attribute, returns the index of the first
    /// token in the attribute
    func startOfAttribute(at i: Int) -> Int? {
        switch tokens[i] {
        case let token where token.isAttribute:
            return i
        case .endOfScope(")"):
            guard let openParenIndex = index(of: .startOfScope("("), before: i),
                  let prevTokenIndex = index(of: .nonSpaceOrComment, before: openParenIndex)
            else {
                return nil
            }
            return startOfAttribute(at: prevTokenIndex)
        case .identifier:
            guard let dotIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: i, if: {
                $0.isOperator(".")
            }), let prevTokenIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: dotIndex) else {
                return nil
            }
            return startOfAttribute(at: prevTokenIndex)
        default:
            return nil
        }
    }

    /// If the token at the specified index is part of an @attribute, returns the index of the last
    /// token in the attribute
    func endOfAttribute(at i: Int) -> Int? {
        guard let startIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: i) else {
            return i
        }
        switch tokens[startIndex] {
        case .startOfScope("(") where !tokens[i + 1 ..< startIndex].contains(where: { $0.isLinebreak }):
            guard let closeParenIndex = index(of: .endOfScope(")"), after: startIndex) else {
                return nil
            }
            return closeParenIndex
        case .operator(".", .infix):
            guard let nextIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: startIndex) else {
                return nil
            }
            return endOfAttribute(at: nextIndex)
        case .startOfScope("<"):
            guard let nextIndex = index(of: .endOfScope(">"), after: startIndex) else {
                return nil
            }
            return endOfAttribute(at: nextIndex)
        default:
            return i
        }
    }

    /// Parses the list of attributes on a declaration, starting at the given index.
    func attributes(startingAt index: Int) -> [(startIndex: Int, endIndex: Int, tokens: [Token])] {
        assert(tokens[index].isAttribute)

        var attributes: [(startIndex: Int, endIndex: Int, tokens: [Token])] = []

        var nextAttributeStartIndex = index
        while tokens[nextAttributeStartIndex].isAttribute {
            guard let endOfAttribute = endOfAttribute(at: nextAttributeStartIndex) else {
                return attributes
            }

            attributes.append((
                startIndex: nextAttributeStartIndex,
                endIndex: endOfAttribute,
                tokens: Array(tokens[nextAttributeStartIndex ... endOfAttribute])
            ))

            guard let nextIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, after: endOfAttribute) else {
                return attributes
            }

            nextAttributeStartIndex = nextIndex
        }

        return attributes
    }

    /// Whether or not this property at the given introducer index (either `var` or `let`)
    /// is a stored property or a computed property.
    func isStoredProperty(atIntroducerIndex introducerIndex: Int) -> Bool {
        assert(["let", "var"].contains(tokens[introducerIndex].string))

        var parseIndex = introducerIndex

        // All properties have the property name after the introducer
        if let propertyNameIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: parseIndex),
           tokens[propertyNameIndex].isIdentifierOrKeyword
        {
            parseIndex = propertyNameIndex
        }

        // Properties have an optional `: TypeName` component
        if let typeAnnotationStartIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: parseIndex),
           tokens[typeAnnotationStartIndex] == .delimiter(":"),
           let startOfTypeIndex = index(of: .nonSpaceOrComment, after: typeAnnotationStartIndex),
           let typeRange = parseType(at: startOfTypeIndex)?.range
        {
            parseIndex = typeRange.upperBound
        }

        // Properties have an optional `= expression` component
        if let assignmentIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: parseIndex),
           tokens[assignmentIndex] == .operator("=", .infix)
        {
            // If the type has an assignment operator, it's guaranteed to be a stored property.
            return true
        }

        // Finally, properties have an optional `{` body
        if let startOfBody = index(of: .nonSpaceOrCommentOrLinebreak, after: parseIndex),
           tokens[startOfBody] == .startOfScope("{")
        {
            // If this property has a body, then its a stored property if and only if the body
            // has a `didSet` or `willSet` keyword, based on the grammar for a variable declaration.
            if let nextToken = next(.nonSpaceOrCommentOrLinebreak, after: startOfBody),
               [.identifier("willSet"), .identifier("didSet")].contains(nextToken)
            {
                return true
            } else {
                return false
            }
        }

        // If the property declaration isn't followed by a `{ ... }` block,
        // then it's definitely a stored property and not a computed property.
        else {
            return true
        }
    }

    /// Determine if next line after this token should be indented
    func isEndOfStatement(at i: Int, in scope: Token? = nil) -> Bool {
        guard let token = token(at: i) else { return true }
        switch token {
        case .endOfScope("case"), .endOfScope("default"):
            return false
        case let .keyword(string):
            // TODO: handle context-specific keywords
            // associativity, convenience, dynamic, didSet, final, get, infix, indirect,
            // lazy, left, mutating, none, nonmutating, open, optional, override, postfix,
            // precedence, prefix, Protocol, required, right, set, Type, unowned, weak, willSet
            switch string {
            case "let", "func", "var", "if", "as", "import", "try", "guard", "case",
                 "for", "init", "switch", "throw", "where", "subscript", "is",
                 "while", "associatedtype", "inout", "await":
                return false
            case "in":
                return lastSignificantKeyword(at: i) != "for"
            case "return":
                guard let nextToken = next(.nonSpaceOrCommentOrLinebreak, after: i) else {
                    return true
                }
                switch nextToken {
                case .keyword, .endOfScope("case"), .endOfScope("default"):
                    return true
                default:
                    return false
                }
            default:
                return true
            }
        case .delimiter(","):
            guard let scope = scope ?? currentScope(at: i) else {
                return false
            }
            // For arrays or argument lists, we already indent
            return ["<", "[", "(", "case", "default"].contains(scope.string)
        case .delimiter(":"):
            guard let scope = scope ?? currentScope(at: i) else {
                return false
            }
            // For arrays or argument lists, we already indent
            return ["case", "default", "("].contains(scope.string)
        case .operator(_, .infix), .operator(_, .prefix):
            return false
        case .operator("?", .postfix), .operator("!", .postfix):
            switch self.token(at: i - 1) {
            case .keyword("as")?, .keyword("try")?:
                return false
            default:
                return true
            }
        default:
            if let attributeIndex = startOfAttribute(at: i),
               let prevIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: attributeIndex)
            {
                return isEndOfStatement(at: prevIndex, in: scope)
            }
            return true
        }
    }

    /// Determine if line starting with this token should be indented
    func isStartOfStatement(at i: Int, in scope: Token? = nil,
                            treatingCollectionKeysAsStart: Bool = true) -> Bool
    {
        guard let token = token(at: i) else { return true }
        switch token {
        case let .keyword(string) where [
            "where", "dynamicType", "rethrows", "throws",
        ].contains(string):
            return false
        case .keyword("as"):
            // For case statements, we already indent
            return (scope ?? currentScope(at: i))?.string == "case"
        case .keyword("in"):
            let scope = (scope ?? currentScope(at: i))?.string
            // For case statements and closures, we already indent
            return scope == "case" || (scope == "{" && lastSignificantKeyword(at: i) != "for")
        case .keyword("is"):
            guard let lastToken = last(.nonSpaceOrCommentOrLinebreak, before: i) else {
                return false
            }
            return [.endOfScope("case"), .keyword("case"), .delimiter(",")].contains(lastToken)
        case .space, .delimiter, .operator(_, .infix), .operator(_, .postfix),
             .endOfScope("}"), .endOfScope("]"), .endOfScope(")"), .endOfScope(">"),
             .identifier where isTrailingClosureLabel(at: i):
            return false
        case .startOfScope("{") where isStartOfClosure(at: i):
            guard last(.nonSpaceOrComment, before: i)?.isLinebreak == true,
                  let prevIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: i),
                  let prevToken = self.token(at: prevIndex)
            else {
                return false
            }
            if prevToken.isIdentifier, !["true", "false", "nil"].contains(prevToken.string) {
                return false
            }
            if [.endOfScope(")"), .endOfScope("]")].contains(prevToken),
               let startIndex = index(of: .startOfScope, before: prevIndex),
               !tokens[startIndex ..< prevIndex].contains(where: { $0.isLinebreak })
               || currentIndentForLine(at: startIndex) == currentIndentForLine(at: prevIndex)
            {
                return false
            }
            return true
        case .identifier("async"):
            if next(.nonSpaceOrCommentOrLinebreak, after: i) == .keyword("let") {
                return true
            }
            if last(.nonSpaceOrCommentOrLinebreak, before: i) == .endOfScope(")"),
               lastSignificantKeyword(at: i) == "func"
            {
                return false
            }
            fallthrough
        case .startOfScope where token.isStringDelimiter && !treatingCollectionKeysAsStart,
             .number where !treatingCollectionKeysAsStart, .identifier:
            if !treatingCollectionKeysAsStart,
               let prevToken = last(.nonSpaceOrCommentOrLinebreak, before: i), [
                   .delimiter(","), .startOfScope("["), .startOfScope("(")
               ].contains(prevToken)
            {
                return false
            }
            fallthrough
        case .keyword("try"), .keyword("await"):
            guard let prevToken = last(.nonSpaceOrComment, before: i) else {
                return true
            }
            guard prevToken.isLinebreak else {
                return false
            }
            if let prevToken = last(.nonSpaceOrCommentOrLinebreak, before: i) {
                switch prevToken {
                case .number, .operator(_, .postfix), .endOfScope, .identifier,
                     .startOfScope("{"), .delimiter(";"),
                     .keyword("in") where lastSignificantKeyword(at: i) != "for":
                    return true
                default:
                    return false
                }
            }
            return true
        case .keyword:
            return true
        default:
            guard let prevToken = last(.nonSpaceOrComment, before: i) else {
                return true
            }
            guard prevToken.isLinebreak else {
                return false
            }
            if let prevToken = last(.nonSpaceOrCommentOrLinebreak, before: i),
               prevToken == .keyword("return") || prevToken.isOperator(ofType: .infix)
            {
                return false
            }
            return true
        }
    }

    func isTrailingClosureLabel(at i: Int) -> Bool {
        if case .identifier? = token(at: i),
           last(.nonSpaceOrCommentOrLinebreak, before: i) == .endOfScope("}"),
           let nextIndex = index(of: .nonSpaceOrComment, after: i, if: { $0 == .delimiter(":") }),
           let nextNextIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: nextIndex),
           isStartOfClosure(at: nextNextIndex, in: nil)
        {
            return true
        }
        return false
    }

    func isSubscriptOrFunctionCall(at i: Int) -> Bool {
        guard case let .startOfScope(string)? = token(at: i), ["[", "("].contains(string),
              let prevToken = last(.nonSpaceOrComment, before: i)
        else {
            return false
        }
        switch prevToken {
        case .identifier, .operator(_, .postfix),
             .endOfScope("]"), .endOfScope(")"), .endOfScope("}"),
             .endOfScope where prevToken.isStringDelimiter:
            return true
        default:
            return false
        }
    }

    /// Returns true if the token at the specified index is inside a single-line string literal (including inside an interpolation)
    func isInSingleLineStringLiteral(at i: Int) -> Bool {
        var i = i
        while let token = token(at: i), !token.isLinebreak {
            if token.isStringDelimiter {
                return !token.isMultilineStringDelimiter
            }
            i -= 1
        }
        return false
    }

    /// Crude check to detect if code is inside a Result Builder
    /// Note: this will produce false positives for any init that takes a closure
    func isInResultBuilder(at i: Int) -> Bool {
        var i = i
        while let startIndex = index(before: i, where: {
            [.startOfScope("{"), .startOfScope(":")].contains($0)
        }) {
            guard let prevIndex = index(before: startIndex, where: {
                !$0.isSpaceOrCommentOrLinebreak && !$0.isEndOfScope
            }) else {
                return false
            }
            if case let .identifier(name) = tokens[prevIndex], name.first?.isUppercase == true {
                switch last(.nonSpaceOrCommentOrLinebreak, before: prevIndex) {
                case .identifier("some")?, .delimiter?, .startOfScope?, .endOfScope?,
                     .operator(_, .infix)?, .operator(_, .prefix)?, nil:
                    return true
                default:
                    break
                }
            }
            i = prevIndex
        }
        return false
    }

    /// Detect if identifier requires backtick escaping
    func backticksRequired(at i: Int, ignoreLeadingDot: Bool = false) -> Bool {
        guard let token = token(at: i), token.isIdentifier else {
            return false
        }
        let unescaped = token.unescaped()
        if !unescaped.isSwiftKeyword {
            switch unescaped {
            case "_", "$":
                return true
            case "self":
                if last(.nonSpaceOrCommentOrLinebreak, before: i)?.isOperator(".") == true {
                    return true
                }
                fallthrough
            case "super", "nil", "true", "false":
                if options.swiftVersion < "4" {
                    return true
                }
            case "Self", "Any":
                if let prevToken = last(.nonSpaceOrCommentOrLinebreak, before: i),
                   [.delimiter(":"), .operator("->", .infix)].contains(prevToken)
                {
                    // TODO: check for other cases where it's safe to use unescaped
                    return false
                }
            case "Type":
                if currentScope(at: i) == .startOfScope("{") {
                    // TODO: check it's actually inside a type declaration, otherwise backticks aren't needed
                    return true
                }
                if last(.nonSpaceOrCommentOrLinebreak, before: i)?.isOperator(".") == true {
                    return true
                }
                return false
            case "get", "set", "willSet", "didSet", "init", "_modify":
                return isAccessorKeyword(at: i, checkKeyword: false)
            case "actor":
                if last(.nonSpaceOrCommentOrLinebreak, before: i)?.isOperator(ofType: .infix) == true {
                    return false
                }
            default:
                return false
            }
        }
        if let prevIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: i, if: {
            $0.isOperator(".")
        }) {
            if unescaped == "init" {
                return true
            }
            if options.swiftVersion >= "5" || self.token(at: prevIndex - 1)?.isOperator("\\") != true {
                return ignoreLeadingDot
            }
            return true
        }
        guard !["let", "var"].contains(unescaped) else {
            return true
        }
        return !isArgumentPosition(at: i)
    }

    /// Is token at argument position
    func isArgumentPosition(at i: Int) -> Bool {
        assert(tokens[i].isIdentifierOrKeyword)
        guard let nextIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: i) else {
            return false
        }
        let nextToken = tokens[nextIndex]
        if nextToken == .delimiter(":") || (nextToken.isIdentifier &&
            next(.nonSpaceOrCommentOrLinebreak, after: nextIndex) == .delimiter(":")),
            currentScope(at: i) == .startOfScope("(")
        {
            return true
        }
        return false
    }

    /// Determine if the specified token is the start of a commented line of code
    func isCommentedCode(at i: Int) -> Bool {
        if token(at: i) == .startOfScope("//"), token(at: i - 1)?.isSpace != true {
            switch token(at: i + 1) {
            case nil, .linebreak?:
                return true
            case let .space(space)? where space.hasPrefix(options.indent):
                return true
            default:
                break
            }
        }
        return false
    }

    /// Returns true if the identifier at the specified index is a label
    func isLabel(at i: Int) -> Bool {
        guard case .identifier = token(at: i) else {
            return false
        }
        return next(.nonSpaceOrCommentOrLinebreak, after: i) == .delimiter(":")
    }

    /// Returns true if the token at the specified index is the opening delimiter of a parameter list
    /// (i.e. either the `(` for a function, or the `<` for some generic parameters)
    func isParameterList(at i: Int) -> Bool {
        assert([.startOfScope("("), .startOfScope("<")].contains(tokens[i]))
        guard let endIndex = endOfScope(at: i),
              let nextIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: endIndex)
        else { return false }
        switch tokens[nextIndex] {
        case .operator("->", .infix), .keyword("throws"), .keyword("rethrows"):
            return true
        case .keyword("in"):
            return last(.nonSpaceOrLinebreak, before: i) != .keyword("for")
        case .identifier("async"):
            if let nextToken = next(.nonSpaceOrCommentOrLinebreak, after: nextIndex),
               [.operator("->", .infix), .keyword("throws"), .keyword("rethrows")].contains(nextToken)
            {
                return true
            }
        default:
            if let funcIndex = index(of: .keywordOrAttribute, before: i, if: {
                [.keyword("func"), .keyword("init"), .keyword("subscript"), .keyword("macro")].contains($0)
            }), lastIndex(of: .endOfScope("}"), in: funcIndex ..< i) == nil {
                // Is parameters at start of function
                return true
            }
        }
        return false
    }

    /// Returns if the `case` keyword at the specified index is part of an enum (as opposed to `if case`)
    func isEnumCase(at i: Int) -> Bool {
        assert(tokens[i] == .keyword("case"))
        switch last(.nonSpaceOrCommentOrLinebreak, before: i) {
        case .identifier?, .endOfScope(")")?, .startOfScope("{")?:
            return true
        default:
            return false
        }
    }

    /// Parses a type name starting at the given index, of one of the following forms:
    ///  - `Foo`
    ///  - `[...]`
    ///  - `(...)`
    ///  - `Foo<...>`
    ///  - `(...) -> ...`
    ///  - `...?`
    ///  - `...!`
    ///  - `any ...`
    ///  - `some ...`
    ///  - `borrowing ...`
    ///  - `consuming ...`
    ///  - `(type).(type)`
    func parseType(
        at startOfTypeIndex: Int,
        excludeLowercaseIdentifiers: Bool = false
    )
        -> (name: String, range: ClosedRange<Int>)?
    {
        guard let baseType = parseNonOptionalType(at: startOfTypeIndex, excludeLowercaseIdentifiers: excludeLowercaseIdentifiers) else { return nil }

        // Any type can be optional, so check for a trailing `?` or `!`.
        // There cannot be any other tokens between the type and the operator:
        //
        //   let foo: String? // allowed
        //   let foo: String ? // not allowed
        //   let foo: String/*bar*/? // not allowed
        //
        let nextTokenIndex = baseType.range.upperBound + 1
        if let nextToken = token(at: nextTokenIndex),
           ["?", "!"].contains(nextToken.string)
        {
            let typeRange = baseType.range.lowerBound ... nextTokenIndex
            return (name: tokens[typeRange].string, range: typeRange)
        }

        // Any type can be followed by a `.` which can then continue the type
        if let nextTokenIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: baseType.range.upperBound),
           tokens[nextTokenIndex] == .operator(".", .infix),
           let followingToken = index(of: .nonSpaceOrCommentOrLinebreak, after: nextTokenIndex),
           let followingType = parseType(at: followingToken, excludeLowercaseIdentifiers: excludeLowercaseIdentifiers)
        {
            let typeRange = startOfTypeIndex ... followingType.range.upperBound
            return (name: tokens[typeRange].string, range: typeRange)
        }

        return baseType
    }

    private func parseNonOptionalType(
        at startOfTypeIndex: Int,
        excludeLowercaseIdentifiers: Bool
    )
        -> (name: String, range: ClosedRange<Int>)?
    {
        let startToken = tokens[startOfTypeIndex]

        // Parse types of the form `[...]`
        if startToken == .startOfScope("["), let endOfScope = endOfScope(at: startOfTypeIndex) {
            // Validate that the inner type is also valid
            guard let innerTypeStartIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: startOfTypeIndex),
                  let innerType = parseType(at: innerTypeStartIndex, excludeLowercaseIdentifiers: excludeLowercaseIdentifiers),
                  let indexAfterType = index(of: .nonSpaceOrCommentOrLinebreak, after: innerType.range.upperBound)
            else { return nil }

            // This is either an array type of the form `[Element]`,
            // or a dictionary type of the form `[Key: Value]`.
            if indexAfterType != endOfScope {
                guard tokens[indexAfterType] == .delimiter(":"),
                      let secondTypeIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: indexAfterType),
                      let secondType = parseType(at: secondTypeIndex, excludeLowercaseIdentifiers: excludeLowercaseIdentifiers),
                      let indexAfterSecondType = index(of: .nonSpaceOrCommentOrLinebreak, after: secondType.range.upperBound),
                      indexAfterSecondType == endOfScope
                else { return nil }
            }

            let typeRange = startOfTypeIndex ... endOfScope
            return (name: tokens[typeRange].string, range: typeRange)
        }

        // Parse types of the form `(...)` or `(...) -> ...`
        if startToken == .startOfScope("("), let endOfScope = endOfScope(at: startOfTypeIndex) {
            // Parse types of the form `(...) -> ...`
            if let closureReturnIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: endOfScope),
               tokens[closureReturnIndex] == .operator("->", .infix),
               let returnTypeIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: closureReturnIndex),
               let returnTypeRange = parseType(at: returnTypeIndex)?.range
            {
                let typeRange = startOfTypeIndex ... returnTypeRange.upperBound
                return (name: tokens[typeRange].string, range: typeRange)
            }

            // Otherwise this is just `(...)`
            let typeRange = startOfTypeIndex ... endOfScope
            return (name: tokens[typeRange].string, range: typeRange)
        }

        // Parse types of the form `Foo<...>`
        if let nextTokenIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: startOfTypeIndex),
           tokens[nextTokenIndex] == .startOfScope("<"),
           let endOfScope = endOfScope(at: nextTokenIndex)
        {
            let typeRange = startOfTypeIndex ... endOfScope
            return (name: tokens[typeRange].string, range: typeRange)
        }

        // Parse types of the form `any ...`, `some ...`, `borrowing ...`, `consuming ...`
        if ["any", "some", "borrowing", "consuming"].contains(startToken.string),
           let nextToken = index(of: .nonSpaceOrCommentOrLinebreak, after: startOfTypeIndex),
           let followingType = parseType(at: nextToken)
        {
            let typeRange = startOfTypeIndex ... followingType.range.upperBound
            return (name: tokens[typeRange].string, range: typeRange)
        }

        // Otherwise this is just a single identifier
        if startToken.isIdentifier || startToken.isKeywordOrAttribute, startToken != .identifier("init") {
            let firstCharacter = startToken.string.first.flatMap(String.init) ?? ""
            let isLowercaseIdentifier = firstCharacter.uppercased() != firstCharacter

            guard !(excludeLowercaseIdentifiers && isLowercaseIdentifier),
                  // Don't parse macro invocations or `#selector` as a type.
                  !["#"].contains(firstCharacter)
            else { return nil }

            return (name: startToken.string, range: startOfTypeIndex ... startOfTypeIndex)
        }

        return nil
    }

    /// Whether or not the token at this index could potentially be the last token in a type.
    /// For a full list of all supported type patterns, check the documentation of `parseType(at:)`.
    func isValidEndOfType(at index: Int) -> Bool {
        if tokens[index].isIdentifier {
            return true
        }

        let validEndOfTypeTokens = ["]", ")", ">", "?", "!"]
        if validEndOfTypeTokens.contains(tokens[index].string) {
            return true
        }

        return false
    }

    /// Parses the expression starting at the given index.
    ///
    /// A full list of expression types are available here:
    /// https://docs.swift.org/swift-book/documentation/the-swift-programming-language/expressions/
    ///
    /// Can be any of:
    ///  - `identifier`
    ///  - `1` (integer literal)
    ///  - `1.0` (double literal)
    ///  - `"foo"` (string literal)
    ///  - `(...)` (tuple)
    ///  - `[...]` (array or dictionary)
    ///  - `{ ... }` (closure)
    ///  - `#selector(...)` / macro invocations
    ///  - An `if/switch` expression (only allowed if this is the only expression in
    ///    a code block or if following an assignment `=` operator).
    ///  - Any value can be preceded by a prefix operator
    ///  - Any value can be preceded by `try`, `try?`, `try!`, or `await`
    ///  - Any value can be followed by a postfix operator
    ///  - Any value can be followed by an infix operator plus a right-hand-side expression.
    ///  - Any value can be followed by an arbitrary number of method calls `(...)`, subscripts `[...]`, or generic arguments `<...>`.
    ///  - Any value can be followed by a `.identifier`
    func parseExpressionRange(
        startingAt startIndex: Int,
        allowConditionalExpressions: Bool = false
    )
        -> ClosedRange<Int>?
    {
        // Any expression can start with a prefix operator, or `await`
        if tokens[startIndex].isOperator(ofType: .prefix) || tokens[startIndex].string == "await",
           let nextTokenIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: startIndex),
           let followingExpression = parseExpressionRange(startingAt: nextTokenIndex, allowConditionalExpressions: allowConditionalExpressions)
        {
            return startIndex ... followingExpression.upperBound
        }

        // Any value can be preceded by `try`
        if tokens[startIndex].string == "try" {
            guard var nextTokenAfterTry = index(of: .nonSpaceOrCommentOrLinebreak, after: startIndex) else { return nil }

            // `try` can either be by itself, or followed by `?` or `!` (`try`, `try?`, or `try!`).
            // If present, skip the operator.
            if tokens[nextTokenAfterTry].isUnwrapOperator {
                guard let nextTokenAfterTryOperator = index(of: .nonSpaceOrCommentOrLinebreak, after: nextTokenAfterTry) else { return nil }
                nextTokenAfterTry = nextTokenAfterTryOperator
            }

            if let followingExpression = parseExpressionRange(startingAt: nextTokenAfterTry, allowConditionalExpressions: allowConditionalExpressions) {
                return startIndex ... followingExpression.upperBound
            }
        }

        // Parse the base of any potential method call or chain,
        // which is always a simple identifier or a simple literal.
        var endOfExpression: Int
        switch tokens[startIndex] {
        case .identifier, .number:
            endOfExpression = startIndex

        case .startOfScope:
            // All types of scopes (tuples, arrays, closures, strings) are considered expressions
            // _except_ for conditional complication blocks.
            if ["#if", "#elseif", "#else"].contains(tokens[startIndex].string) {
                return nil
            }

            guard let endOfScope = endOfScope(at: startIndex) else { return nil }
            endOfExpression = endOfScope

        case let .keyword(keyword) where keyword.hasPrefix("#"):
            // #selector() and macro expansions like #macro() are parsed into keyword tokens.
            endOfExpression = startIndex

        case .keyword("if"), .keyword("switch"):
            guard allowConditionalExpressions,
                  let conditionalBranches = conditionalBranches(at: startIndex),
                  let lastBranch = conditionalBranches.last
            else { return nil }
            endOfExpression = lastBranch.endOfBranch

        default:
            return nil
        }

        while let nextTokenIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: endOfExpression),
              let nextToken = token(at: nextTokenIndex)
        {
            switch nextToken {
            // Any expression can be followed by an arbitrary number of method calls `(...)`, subscripts `[...]`, or generic arguments `<...>`.
            case .startOfScope("("), .startOfScope("["), .startOfScope("<"):
                // If there's a linebreak between an expression and a paren or subscript,
                // then it's not parsed as a method call and is actually a separate expression
                if tokens[endOfExpression ..< nextTokenIndex].contains(where: \.isLinebreak) {
                    return startIndex ... endOfExpression
                }

                guard let endOfScope = endOfScope(at: nextTokenIndex) else { return nil }
                endOfExpression = endOfScope

            /// Any value can be followed by a `.identifier`
            case .delimiter("."), .operator(".", _):
                guard let nextIdentifierIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: nextTokenIndex),
                      tokens[nextIdentifierIndex].isIdentifier
                else { return startIndex ... endOfExpression }

                endOfExpression = nextIdentifierIndex

            /// Any value can be followed by a postfix operator
            case .operator(_, .postfix):
                endOfExpression = nextTokenIndex

            /// Any value can be followed by an infix operator, plus another expression
            ///  - However, the assignment operator (`=`) is special and _isn't_ an expression
            case let .operator(operatorString, .infix) where operatorString != "=":
                guard let nextTokenIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: nextTokenIndex),
                      let nextExpression = parseExpressionRange(startingAt: nextTokenIndex)
                else { return startIndex ... endOfExpression }

                endOfExpression = nextExpression.upperBound

            /// Any value can be followed by `is`, `as`, `as?`, or `as?`, plus another expression
            case .keyword("is"), .keyword("as"):
                guard var nextTokenAfterKeyword = index(of: .nonSpaceOrCommentOrLinebreak, after: nextTokenIndex) else { return nil }

                // `as` can either be by itself, or followed by `?` or `!` (`as`, `as?`, or `as!`).
                // If present, skip the operator.
                if tokens[nextTokenAfterKeyword].isUnwrapOperator {
                    guard let nextTokenAfterOperator = index(of: .nonSpaceOrCommentOrLinebreak, after: nextTokenAfterKeyword) else { return nil }
                    nextTokenAfterKeyword = nextTokenAfterOperator
                }

                guard let followingExpression = parseExpressionRange(startingAt: nextTokenAfterKeyword) else {
                    return startIndex ... endOfExpression
                }

                endOfExpression = followingExpression.upperBound

            /// Any value can be followed by a trailing closure
            case .startOfScope("{"):
                guard let endOfScope = endOfScope(at: nextTokenIndex) else { return nil }

                // Within a conditional statement, an open brace is most likely
                // to instead represent the body of the condition.
                if isConditionalStatement(at: startIndex) {
                    return startIndex ... endOfExpression
                }

                endOfExpression = endOfScope

            /// Some values can be followed by a labeled trailing closure,
            /// like (expression) trailingClosure: { ... }
            case .identifier:
                guard let colonIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: nextTokenIndex),
                      tokens[colonIndex] == .delimiter(":"),
                      let startOfClosureIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: colonIndex),
                      tokens[startOfClosureIndex] == .startOfScope("{"),
                      let endOfClosureScope = endOfScope(at: startOfClosureIndex)
                else { return startIndex ... endOfExpression }

                endOfExpression = endOfClosureScope

            default:
                return startIndex ... endOfExpression
            }
        }

        return startIndex ... endOfExpression
    }

    /// Whether or not the comment starting at the given index is a doc comment
    func isDocComment(startOfComment: Int) -> Bool {
        let commentToken = tokens[startOfComment]
        guard commentToken == .startOfScope("//") || commentToken == .startOfScope("/*") else {
            return false
        }

        // Doc comment tokens like `///` and `/**` aren't parsed as a
        // single `.startOfScope` token -- they're parsed as:
        // `.startOfScope("//"), .commentBody("/ ...")` or
        // `.startOfScope("/*"), .commentBody("* ...")`
        let startOfDocCommentBody: String
        switch commentToken.string {
        case "//":
            startOfDocCommentBody = "/"
        case "/*":
            startOfDocCommentBody = "*"
        default:
            return false
        }

        guard let commentBody = token(at: startOfComment + 1),
              commentBody.isCommentBody
        else { return false }

        return commentBody.string.hasPrefix(startOfDocCommentBody)
    }

    struct ImportRange: Comparable {
        var module: String
        var range: Range<Int>
        var attributes: [String]

        var isTestable: Bool {
            attributes.contains("@testable")
        }

        static func < (lhs: ImportRange, rhs: ImportRange) -> Bool {
            let la = lhs.module.lowercased()
            let lb = rhs.module.lowercased()
            return la == lb ? lhs.module < rhs.module : la < lb
        }
    }

    /// A property of the format `(let|var) identifier: Type = expression`.
    ///  - `: Type` and `= expression` elements are optional
    struct PropertyDeclaration {
        let introducerIndex: Int
        let identifier: String
        let identifierIndex: Int
        let type: (colonIndex: Int, name: String, range: ClosedRange<Int>)?
        let value: (assignmentIndex: Int, expressionRange: ClosedRange<Int>)?

        var range: ClosedRange<Int> {
            if let value = value {
                return introducerIndex ... value.expressionRange.upperBound
            } else if let type = type {
                return introducerIndex ... type.range.upperBound
            } else {
                return introducerIndex ... identifierIndex
            }
        }
    }

    /// Parses a property of the format `(let|var) identifier: Type = expression`
    /// starting at the given introducer index (the `let` / `var` keyword).
    func parsePropertyDeclaration(atIntroducerIndex introducerIndex: Int) -> PropertyDeclaration? {
        assert(["let", "var"].contains(tokens[introducerIndex].string))

        guard let propertyIdentifierIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: introducerIndex),
              let propertyIdentifier = token(at: propertyIdentifierIndex),
              propertyIdentifier.isIdentifier
        else { return nil }

        var typeInformation: (colonIndex: Int, name: String, range: ClosedRange<Int>)?

        if let colonIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: propertyIdentifierIndex),
           tokens[colonIndex] == .delimiter(":"),
           let startOfTypeIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: colonIndex),
           let type = parseType(at: startOfTypeIndex)
        {
            typeInformation = (
                colonIndex: colonIndex,
                name: type.name,
                range: type.range
            )
        }

        let endOfTypeOrIdentifier = typeInformation?.range.upperBound ?? propertyIdentifierIndex
        var valueInformation: (assignmentIndex: Int, expressionRange: ClosedRange<Int>)?

        if let assignmentIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: endOfTypeOrIdentifier),
           tokens[assignmentIndex] == .operator("=", .infix),
           let startOfExpression = index(of: .nonSpaceOrCommentOrLinebreak, after: assignmentIndex),
           let expressionRange = parseExpressionRange(startingAt: startOfExpression, allowConditionalExpressions: true)
        {
            valueInformation = (
                assignmentIndex: assignmentIndex,
                expressionRange: expressionRange
            )
        }

        return PropertyDeclaration(
            introducerIndex: introducerIndex,
            identifier: propertyIdentifier.string,
            identifierIndex: propertyIdentifierIndex,
            type: typeInformation,
            value: valueInformation
        )
    }

    /// Shared import rules implementation
    func parseImports() -> [[ImportRange]] {
        var importStack = [[ImportRange]]()
        var importRanges = [ImportRange]()
        forEach(.keyword("import")) { i, _ in
            func pushStack() {
                importStack.append(importRanges)
                importRanges.removeAll()
            }
            // Get start of line
            var startIndex = index(of: .linebreak, before: i) ?? 0
            // Check for attributes
            var previousKeywordIndex = index(of: .keywordOrAttribute, before: i)
            while let previousIndex = previousKeywordIndex {
                var nextStart: Int? // workaround for Swift Linux bug
                if tokens[previousIndex].isAttribute {
                    if previousIndex < startIndex {
                        nextStart = index(of: .linebreak, before: previousIndex) ?? 0
                    }
                    previousKeywordIndex = index(of: .keywordOrAttribute, before: previousIndex)
                    startIndex = nextStart ?? startIndex
                } else if previousIndex >= startIndex {
                    // Can't handle another keyword on same line as import
                    return
                } else {
                    break
                }
            }
            // Gather comments
            let codeStartIndex = startIndex
            var prevIndex = index(of: .linebreak, before: startIndex) ?? 0
            while startIndex > 0,
                  next(.nonSpace, after: prevIndex)?.isComment == true,
                  next(.nonSpaceOrComment, after: prevIndex)?.isLinebreak == true
            {
                if prevIndex == 0, index(of: .startOfScope("#if"), before: startIndex) != nil {
                    break
                }
                startIndex = prevIndex
                prevIndex = index(of: .linebreak, before: startIndex) ?? 0
            }
            // Check if comment is potentially a file header
            if last(.nonSpaceOrCommentOrLinebreak, before: startIndex) == nil {
                for case let .commentBody(body) in tokens[startIndex ..< codeStartIndex] {
                    if body.contains("created") || body.contains("Created") ||
                        body.contains(options.fileInfo.fileName ?? ".swift")
                    {
                        startIndex = codeStartIndex
                        break
                    }
                }
            }
            // Get end of line
            let endIndex = index(of: .linebreak, after: i) ?? tokens.count
            // Get name
            if let firstPartIndex = index(of: .identifier, after: i) {
                var name = tokens[firstPartIndex].string
                var partIndex = firstPartIndex
                loop: while let nextPartIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: partIndex) {
                    switch tokens[nextPartIndex] {
                    case .operator(".", .infix):
                        name += "."
                    case let .identifier(string):
                        name += string
                    default:
                        break loop
                    }
                    partIndex = nextPartIndex
                }
                let range = startIndex ..< endIndex as Range
                importRanges.append(ImportRange(
                    module: name,
                    range: range,
                    attributes: tokens[range].compactMap { $0.isAttribute ? $0.string : nil }
                ))
            } else {
                // Error
                pushStack()
                return
            }
            if next(.spaceOrCommentOrLinebreak, after: endIndex)?.isLinebreak == true {
                // Blank line after - consider this the end of a block
                pushStack()
                return
            }
            if var nextTokenIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: endIndex) {
                while tokens[nextTokenIndex].isAttribute {
                    guard let nextIndex = index(of: .nonSpaceOrLinebreak, after: nextTokenIndex) else {
                        // End of imports
                        pushStack()
                        return
                    }
                    nextTokenIndex = nextIndex
                }
                if tokens[nextTokenIndex] != .keyword("import") {
                    // End of imports
                    pushStack()
                    return
                }
            }
        }
        // End of imports
        importStack.append(importRanges)
        return importStack
    }

    /// Parses the arguments of the closure whose open brace is at the given index.
    /// Returns `nil` if this is an anonymous closure, or if there was an issue parsing the closure arguments.
    ///  - `{ foo in ... }` returns `argumentNames: ["foo"]`
    ///  - `{ foo, bar in ... }` returns `argumentNames: ["foo", "bar"]`
    ///  - `{ (foo: Foo, bar: Bar) in ... }` returns `argumentNames: ["foo", "bar"]`
    func parseClosureArgumentList(at closureOpenBraceIndex: Int) -> (argumentNames: [String], inKeywordIndex: Int)? {
        var argumentNames = [String]()
        let inKeywordIndex: Int

        // Check if this is a closure `{ value in ... }` clause
        if let indexAfterOpenBrace = index(of: .nonSpaceOrCommentOrLinebreak, after: closureOpenBraceIndex),
           tokens[indexAfterOpenBrace].isIdentifier
        {
            // Parse a list of argument names like `foo, bar, baaz` until the `in` keyword
            var currentArgumentListIndex = indexAfterOpenBrace
            while tokens[currentArgumentListIndex].isIdentifier {
                argumentNames.append(tokens[currentArgumentListIndex].string)

                guard let nextIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: currentArgumentListIndex) else {
                    return nil
                }

                // Skip over any commas
                if tokens[nextIndex] == .delimiter(",") {
                    currentArgumentListIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: nextIndex) ?? nextIndex
                } else {
                    currentArgumentListIndex = nextIndex
                }
            }

            // Finally we expect there to be an `in` keyword
            guard tokens[currentArgumentListIndex] == .keyword("in") else {
                return nil
            }

            inKeywordIndex = currentArgumentListIndex
        }

        // Check if this is a closure `{ (value: ValueType) in ... }` clause
        else if let indexAfterOpenBrace = index(of: .nonSpaceOrCommentOrLinebreak, after: closureOpenBraceIndex),
                tokens[indexAfterOpenBrace] == .startOfScope("("),
                let endOfArgumentsScopeIndex = endOfScope(at: indexAfterOpenBrace),
                let firstTokenInArgumentsList = index(of: .nonSpaceOrCommentOrLinebreak, after: indexAfterOpenBrace),
                let indexAfterArguments = index(of: .nonSpaceOrCommentOrLinebreak, after: endOfArgumentsScopeIndex),
                tokens[indexAfterArguments] == .keyword("in")
        {
            inKeywordIndex = indexAfterArguments

            // This can be a completely empty argument list, like `{ () in ... }`.
            if firstTokenInArgumentsList == endOfArgumentsScopeIndex {
                return (argumentNames: [], inKeywordIndex: inKeywordIndex)
            }

            // Parse the comma-separated list of arguments
            var currentArgIndex = firstTokenInArgumentsList
            while tokens[currentArgIndex].isIdentifierOrKeyword {
                argumentNames.append(tokens[currentArgIndex].string)

                guard let nextComma = index(of: .delimiter(","), in: currentArgIndex ..< endOfArgumentsScopeIndex),
                      let nextArgLabel = index(of: .identifierOrKeyword, in: nextComma ..< endOfArgumentsScopeIndex)
                else {
                    break
                }

                currentArgIndex = nextArgLabel
            }
        }

        // Otherwise this is an anonymous closure
        else {
            return nil
        }

        return (argumentNames: argumentNames, inKeywordIndex: inKeywordIndex)
    }

    /// The fully qualified name starting at the given index
    func fullyQualifiedName(startingAt index: Int) -> (name: String, endIndex: Int) {
        // If the identifier is followed by a dot, it's actually the first
        // part of the fully-qualified name and we should skip through
        // to the last component of the name.
        var name = tokens[index].string
        var index = index

        while token(at: index + 1)?.string == ".",
              let nextIdentifier = token(at: index + 2),
              nextIdentifier.is(.identifier) == true
        {
            name = "\(name).\(nextIdentifier.string)"
            index += 2
        }

        return (name, index)
    }

    /// Get the type of the declaration starting at the index of the declaration keyword
    func declarationType(at index: Int) -> String? {
        guard let token = token(at: index), token.isDeclarationTypeKeyword,
              case let .keyword(keyword) = token
        else {
            return nil
        }
        if keyword == "class" {
            var nextIndex = index
            while let i = self.index(of: .nonSpaceOrCommentOrLinebreak, after: nextIndex) {
                let nextToken = tokens[i]
                if nextToken.isDeclarationTypeKeyword {
                    return nextToken.string
                }
                guard nextToken.isModifierKeyword else {
                    break
                }
                nextIndex = i
            }
            return keyword
        }
        return keyword
    }

    /// Gather declared name(s), starting at the index of the declaration keyword
    func namesInDeclaration(at index: Int) -> Set<String>? {
        guard case let .keyword(keyword)? = token(at: index) else {
            return nil
        }
        switch keyword {
        case "let", "var":
            var index = index + 1
            var names = Set<String>()
            processDeclaredVariables(at: &index, names: &names)
            return names
        case "func", "class", "actor", "struct", "enum":
            guard let name = next(.identifier, after: index) else {
                return nil
            }
            return [name.string]
        default:
            return nil
        }
    }

    /// The type of scope that a declaration is contained within
    enum DeclarationScope {
        /// The declaration is a top-level global
        case global

        /// The declaration is a member of some type
        case type

        /// The declaration is within some local scope,
        /// like a function body or closure.
        case local
    }

    /// Returns the index of the start of the declaration scope that the given token index is contained by,
    /// and the type (global, type, or local)
    func declarationIndexAndScope(at i: Int) -> (index: Int?, scope: DeclarationScope) {
        // Declarations which have `DeclarationScope.type`
        let typeDeclarations = Set(["class", "actor", "struct", "enum", "extension"])

        // Declarations which have `DeclarationScope.local`
        let localDeclarations = Set(["let", "var", "func", "subscript", "init", "deinit", "get", "set", "willSet", "didSet"])

        let allDeclarationScopes = typeDeclarations.union(localDeclarations)

        // back track through tokens until we find a startOfScope("{") that isDeclarationTypeKeyword
        //  - we have to skip scopes that sit between this token and the its actual start of scope,
        //    so we have to keep track of the number of unpaired end scope tokens we have encountered
        var unpairedEndScopeCount = 0
        var currentIndex = i
        var startOfScope: Int?

        while startOfScope == nil, currentIndex > 0 {
            currentIndex -= 1

            if tokens[currentIndex] == .endOfScope("}") {
                unpairedEndScopeCount += 1
            } else if tokens[currentIndex] == .startOfScope("{") {
                // If we find a closure or conditional statement that contains the index we're checking,
                // we know the inner code is local.
                if let endOfScope = endOfScope(at: currentIndex),
                   (currentIndex ... endOfScope).contains(i),
                   isStartOfClosureOrFunctionBody(at: currentIndex) || isConditionalStatement(at: currentIndex)
                {
                    return (nil, .local)
                }

                if unpairedEndScopeCount == 0 {
                    startOfScope = currentIndex
                } else {
                    unpairedEndScopeCount -= 1
                }
            }
        }

        // If this declaration isn't within any scope,
        // it must be a global.
        guard let startOfScopeIndex = startOfScope else {
            return (nil, .global)
        }

        // Code within closures and conditionals is always local
        if isStartOfClosureOrFunctionBody(at: startOfScopeIndex) || isConditionalStatement(at: startOfScopeIndex) {
            return (nil, .local)
        }

        guard let declarationKeywordIndex = index(before: startOfScopeIndex, where: {
            allDeclarationScopes.contains($0.string)
        }) else {
            return (nil, .global)
        }

        if typeDeclarations.contains(tokens[declarationKeywordIndex].string) {
            return (declarationKeywordIndex, .type)
        } else {
            return (nil, .local)
        }
    }

    /// Returns the declaration scope (global, type, or local) that the
    /// given token index is contained by.
    func declarationScope(at i: Int) -> DeclarationScope {
        declarationIndexAndScope(at: i).scope
    }

    /// Indent level to use for wrapped lines at the specified position (based on statement type)
    func linewrapIndent(at index: Int) -> String {
        guard let commaIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, before: index + 1, if: {
            $0 == .delimiter(",")
        }),
            case let firstToken = startOfLine(at: commaIndex, excludingIndent: true),
            let firstNonBrace = (firstToken ..< commaIndex).first(where: {
                let token = self.tokens[$0]
                return !token.isEndOfScope && !token.isSpaceOrComment
            })
        else {
            if next(.nonSpaceOrCommentOrLinebreak, after: index) == .operator(".", .infix),
               var prevIndex = self.index(of: .nonSpaceOrLinebreak, before: index)
            {
                if case .endOfScope = tokens[prevIndex] {
                    prevIndex = self.index(of: .startOfScope, before: index) ?? prevIndex
                }
                if case let lineStart = startOfLine(at: prevIndex, excludingIndent: true),
                   tokens[lineStart] == .operator(".", .infix),
                   self.index(of: .startOfScope, before: index) ?? -1 < lineStart
                {
                    return currentIndentForLine(at: lineStart)
                }
            }
            return options.indent
        }
        if case .endOfScope = tokens[firstToken],
           next(.nonSpaceOrCommentOrLinebreak, after: firstNonBrace - 1) == .delimiter(",")
        {
            return ""
        }
        guard let keywordIndex = lastIndex(in: firstNonBrace ..< commaIndex, where: {
            [.keyword("if"), .keyword("guard"), .keyword("while")].contains($0)
        }) ?? lastIndex(in: firstNonBrace ..< commaIndex, where: {
            [.keyword("let"), .keyword("var"), .keyword("case")].contains($0)
        }), let nextTokenIndex = self.index(of: .nonSpace, after: keywordIndex) else {
            return options.indent
        }
        return spaceEquivalentToTokens(from: firstToken, upTo: nextTokenIndex)
    }

    /// Returns end of last index of Void type declaration starting at specified index, or nil if not Void
    func endOfVoidType(at index: Int) -> Int? {
        switch tokens[index] {
        case .identifier("Void"):
            return index
        case .identifier("Swift"):
            guard let dotIndex = self.index(of: .nonSpaceOrLinebreak, after: index, if: {
                $0 == .operator(".", .infix)
            }), let voidIndex = self.index(of: .nonSpace, after: dotIndex, if: {
                $0 == .identifier("Void")
            }) else { return nil }
            return voidIndex
        case .startOfScope("("):
            guard let nextIndex = self.index(of: .nonSpace, after: index) else {
                return nil
            }
            switch tokens[nextIndex] {
            case .endOfScope(")"):
                return nextIndex
            case .identifier("Void"):
                guard let nextIndex = self.index(of: .nonSpace, after: nextIndex),
                      case .endOfScope(")") = tokens[nextIndex]
                else {
                    return nil
                }
                return nextIndex
            default:
                return nil
            }
        default:
            return nil
        }
    }

    /// Range of tokens forming file header comment
    func headerCommentTokenRange(includingDirectives directives: [String]) -> Range<Int>? {
        guard !options.fragment else {
            return nil
        }
        var start = 0
        var lastHeaderTokenIndex = -1
        if var startIndex = index(of: .nonSpaceOrLinebreak, after: -1) {
            if tokens[startIndex] == .startOfScope("#!") {
                guard let endIndex = index(of: .linebreak, after: startIndex) else {
                    return nil
                }
                startIndex = index(of: .nonSpaceOrLinebreak, after: endIndex) ?? endIndex
                start = startIndex
                lastHeaderTokenIndex = startIndex - 1
            }
            switch tokens[startIndex] {
            case .startOfScope("//"):
                if case let .commentBody(body)? = next(.nonSpace, after: startIndex) {
                    processCommentBody(body, at: startIndex)
                    defer {
                        processLinebreak()
                        processLinebreak()
                    }
                    if !isEnabled || (body.hasPrefix("/") && !body.hasPrefix("//")) ||
                        body.hasPrefix("swift-tools-version")
                    {
                        return nil
                    } else if let directive = body.commentDirective,
                              !directives.contains(directive),
                              directives != ["*"]
                    {
                        break
                    }
                }
                var lastIndex = startIndex
                while let index = index(of: .linebreak, after: lastIndex) {
                    switch token(at: index + 1) ?? .space("") {
                    case .startOfScope("//"):
                        if case let .commentBody(body)? = next(.nonSpace, after: index + 1),
                           let directive = body.commentDirective,
                           !directives.contains(directive),
                           directives != ["*"]
                        {
                            break
                        }
                        lastIndex = index
                        continue
                    case .linebreak:
                        lastHeaderTokenIndex = index + 1
                    case .space where token(at: index + 2)?.isLinebreak == true:
                        lastHeaderTokenIndex = index + 2
                    default:
                        break
                    }
                    break
                }
            case .startOfScope("/*"):
                if case let .commentBody(body)? = next(.nonSpace, after: startIndex) {
                    processCommentBody(body, at: startIndex)
                    defer {
                        processLinebreak()
                        processLinebreak()
                    }
                    if !isEnabled || (body.hasPrefix("*") && !body.hasPrefix("**")) {
                        return nil
                    } else if body.isCommentDirective {
                        break
                    }
                }
                while let endIndex = index(of: .endOfScope("*/"), after: startIndex) {
                    lastHeaderTokenIndex = endIndex
                    if let linebreakIndex = index(of: .linebreak, after: endIndex) {
                        lastHeaderTokenIndex = linebreakIndex
                    }
                    guard let nextIndex = index(of: .nonSpace, after: lastHeaderTokenIndex) else {
                        break
                    }
                    guard tokens[nextIndex] == .startOfScope("/*") else {
                        if let endIndex = index(of: .nonSpaceOrLinebreak, after: lastHeaderTokenIndex) {
                            lastHeaderTokenIndex = endIndex - 1
                        }
                        break
                    }
                    startIndex = nextIndex
                }
            default:
                break
            }
        }
        return start ..< lastHeaderTokenIndex + 1
    }

    /// Parses the prorocol composition typealias declaration starting at the given `typealias` keyword index.
    /// Returns `nil` if the given index isn't a protocol composition typealias.
    func parseProtocolCompositionTypealias(at typealiasIndex: Int)
        -> (equalsIndex: Int, andTokenIndices: [Int], endIndex: Int)?
    {
        guard let equalsIndex = index(of: .operator("=", .infix), after: typealiasIndex),
              // Any type can follow the equals index of a typealias,
              // but we're specifically looking for protocol compositions.
              //  - Valid composite protocols are strictly _only_ prootocol types
              //    separated by `&` tokens. These always start with identifiers,
              //    but can be generic (e.g. `Collection<Int>`).
              //  - `&` tokens in types are also _only valid_ for composite protocol types,
              //    so if we see one then we know this if what we're looking for.
              // https://docs.swift.org/swift-book/ReferenceManual/Types.html#grammar_protocol-composition-type
              let firstIdentifierIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: equalsIndex),
              tokens[firstIdentifierIndex].isIdentifier,
              var lastTypeEndIndex = parseType(at: firstIdentifierIndex)?.range.upperBound,
              let firstAndIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: lastTypeEndIndex),
              tokens[firstAndIndex] == .operator("&", .infix)
        else { return nil }

        // Parse through to the end of the composite protocol type
        // so we know how long it is (and where the &s are)
        var andTokenIndices = [Int]()

        while let nextAndIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: lastTypeEndIndex),
              tokens[nextAndIndex] == .operator("&", .infix),
              let nextIdentifierIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: nextAndIndex),
              tokens[nextIdentifierIndex].isIdentifier,
              let endOfType = parseType(at: nextIdentifierIndex)?.range.upperBound
        {
            andTokenIndices.append(nextAndIndex)
            lastTypeEndIndex = endOfType
        }

        return (equalsIndex, andTokenIndices, lastTypeEndIndex)
    }

    /// Parses the external parameter labels of the function with its `(` start of scope
    /// token at the given index.
    func parseFunctionDeclarationArgumentLabels(startOfScope: Int) -> [String?] {
        assert(tokens[startOfScope] == .startOfScope("("))
        guard let endOfScope = endOfScope(at: startOfScope) else { return [] }

        var argumentLabels: [String?] = []

        var currentIndex = startOfScope
        while let nextArgumentColon = index(of: .delimiter(":"), in: (currentIndex + 1) ..< endOfScope) {
            currentIndex = nextArgumentColon

            // If there is only one label, the param has the same internal and external label.
            // If there are two labels, the first one is the external label.
            guard let internalLabelIndex = index(of: .nonSpaceOrComment, before: nextArgumentColon),
                  tokens[internalLabelIndex].isIdentifier || tokens[internalLabelIndex].string == "_"
            else { continue }

            var externalLabelToken = tokens[internalLabelIndex]

            if let externalLabelIndex = index(of: .nonSpaceOrComment, before: internalLabelIndex),
               tokens[externalLabelIndex].isIdentifier || tokens[externalLabelIndex].string == "_"
            {
                externalLabelToken = tokens[externalLabelIndex]
            }

            if externalLabelToken.string == "_" {
                argumentLabels.append(nil)
            } else {
                argumentLabels.append(externalLabelToken.string)
            }
        }

        return argumentLabels
    }

    /// Parses the parameter labels of the function call with its `(` start of scope
    /// token at the given index.
    func parseFunctionCallArgumentLabels(startOfScope: Int) -> [String?] {
        assert(tokens[startOfScope] == .startOfScope("("))
        guard let endOfScope = endOfScope(at: startOfScope),
              index(of: .nonSpaceOrCommentOrLinebreak, after: startOfScope) != endOfScope
        else { return [] }

        var argumentLabels: [String?] = []

        var currentIndex = startOfScope
        repeat {
            let endOfPreviousArgument = currentIndex
            let endOfCurrentArgument = index(of: .delimiter(","), in: endOfPreviousArgument + 1 ..< endOfScope) ?? endOfScope

            if let colonIndex = index(of: .delimiter(":"), in: (endOfPreviousArgument + 1) ..< endOfCurrentArgument),
               let argumentLabelIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: colonIndex),
               tokens[argumentLabelIndex].isIdentifier
            {
                argumentLabels.append(tokens[argumentLabelIndex].string)
            } else {
                argumentLabels.append(nil)
            }

            if endOfCurrentArgument >= endOfScope {
                break
            } else {
                currentIndex = endOfCurrentArgument
            }
        } while true

        return argumentLabels
    }
}

extension _FormatRules {
    /// Swiftlint semantic modifier groups
    static let semanticModifierGroups = ["acl", "setteracl", "mutators", "typemethods", "owned"]

    /// All modifiers
    static let allModifiers = Set(defaultModifierOrder.flatMap { $0 })

    /// ACL modifiers
    static let aclModifiers = ["private", "fileprivate", "internal", "package", "public", "open"]

    /// ACL setter modifiers
    static let aclSetterModifiers = aclModifiers.map { "\($0)(set)" }

    /// Mutating modifiers
    static let mutatingModifiers = ["borrowing", "consuming", "mutating", "nonmutating"]

    /// Ownership modifiers
    static let ownershipModifiers = ["weak", "unowned"]

    /// Modifier mapping (designed to match SwiftLint)
    static func mapModifiers(_ input: String) -> [String]? {
        switch input.lowercased() {
        case "acl":
            return aclModifiers
        case "setteracl":
            return aclSetterModifiers
        case "mutators":
            return mutatingModifiers
        case "typemethods":
            return [] // Not clear what this is for - legacy?
        case "owned":
            return ownershipModifiers
        case let input:
            if allModifiers.contains(input) {
                return [input]
            }
            guard let index = input.firstIndex(of: "(") else {
                return nil
            }
            let input = String(input[..<index])
            return allModifiers.contains(input) ? [input] : nil
        }
    }

    /// Swift modifier keywords, in default order
    static let defaultModifierOrder = [
        ["override"],
        aclModifiers,
        aclSetterModifiers,
        ["final", "dynamic"],
        ["optional", "required"],
        ["convenience"],
        ["indirect"],
        ["isolated", "nonisolated", "nonisolated(unsafe)"],
        ["lazy"],
        ownershipModifiers,
        ["static", "class"],
        mutatingModifiers,
        ["prefix", "infix", "postfix"],
    ]

    /// Global swift functions
    static let globalSwiftFunctions = [
        "min", "max", "abs", "print", "stride", "zip",
    ]
}

extension Token {
    /// Whether or not this token "defines" the specific type of declaration
    ///  - A valid declaration will usually include exactly one of these keywords in its outermost scope.
    ///  - Notable exceptions are `class func` and symbol imports (like `import class Module.Type`)
    ///    which will include two of these keywords.
    var isDeclarationTypeKeyword: Bool {
        isDeclarationTypeKeyword(excluding: [])
    }

    // All of the keywords defining top-level entity
    // https://docs.swift.org/swift-book/ReferenceManual/Declarations.html#grammar_declaration
    static var swiftTypeKeywords: Set<String> {
        Set(["struct", "class", "actor", "protocol", "enum", "extension"])
    }

    // All of the keywords that map to individual Declaration grammars
    // https://docs.swift.org/swift-book/ReferenceManual/Declarations.html#grammar_declaration
    static var declarationTypeKeywords: Set<String> {
        swiftTypeKeywords.union([
            "import", "let", "var", "typealias", "func", "enum", "case",
            "struct", "class", "actor", "protocol", "init", "deinit",
            "extension", "subscript", "operator", "precedencegroup",
            "associatedtype", "macro",
        ])
    }

    /// Whether or not this token "defines" the specific type of declaration
    ///  - A valid declaration will usually include exactly one of these keywords in its outermost scope.
    ///  - Notable exceptions are `class func` and symbol imports (like `import class Module.Type`)
    ///    which will include two of these keywords.
    func isDeclarationTypeKeyword(excluding keywordsToExclude: [String]) -> Bool {
        guard case let .keyword(keyword) = self else {
            return false
        }

        return Self.declarationTypeKeywords
            .subtracting(keywordsToExclude)
            .contains(keyword)
    }

    /// Whether or not this token "defines" the specific type of declaration
    ///  - A valid declaration will usually include exactly one of these keywords in its outermost scope.
    ///  - Notable exceptions are `class func` and symbol imports (like `import class Module.Type`)
    ///    which will include two of these keywords.
    func isDeclarationTypeKeyword(including keywordsToInclude: [String]) -> Bool {
        guard case let .keyword(keyword) = self else {
            return false
        }

        return Self.declarationTypeKeywords
            .intersection(keywordsToInclude)
            .contains(keyword)
    }

    var isModifierKeyword: Bool {
        switch self {
        case let .keyword(keyword), let .identifier(keyword):
            return _FormatRules.allModifiers.contains(keyword)
        default:
            return false
        }
    }
}
