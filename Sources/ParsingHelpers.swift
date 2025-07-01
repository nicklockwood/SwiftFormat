//
//  ParsingHelpers.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 08/04/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

import Foundation

// MARK: - shared helper methods

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
            while let i = endIndex, i < index || !tokens[i].isEndOfScope(startToken) {
                endIndex = self.index(after: i, where: {
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
                if self.token(at: i + 1)?.isUnwrapOperator == true {
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
                let tokenBeforePrevIndex = lastToken(before: prevIndex, where: \.isNonSpaceOrCommentOrLinebreak)

                switch tokens[prevIndex] {
                case .identifier, .endOfScope(")"), .endOfScope("]"),
                     .operator("?", .postfix) where tokenBeforePrevIndex != .keyword("try"),
                     .operator("!", .postfix) where tokenBeforePrevIndex != .keyword("try"),
                     .endOfScope where token.isStringDelimiter:
                    if tokens[prevIndex + 1 ..< index].contains(where: \.isLinebreak) {
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
                case .operator("->", _), .startOfScope("<"), .keyword("extension"):
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
            switch tokens[prevIndex] {
            case let token where token.isModifierKeyword || token.isAttribute:
                if case .identifier = token,
                   let nextToken = last(.nonSpaceOrCommentOrLinebreak, before: prevIndex),
                   nextToken == .keyword("case") || nextToken.isOperator(ofType: .infix) || nextToken.isOperator(ofType: .prefix)
                {
                    // Part of previous declaration
                    return false
                }
                if contains(prevIndex, token.string) {
                    return true
                }
            case .endOfScope(")"):
                guard let startIndex = self.index(of: .startOfScope("("), before: prevIndex),
                      let identifierIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, before: startIndex, if: {
                          $0.isAttribute || _FormatRules.allModifiers.contains($0.string) || $0 == .endOfScope(">")
                      })
                else {
                    return false
                }
                if let prevToken = last(.nonSpaceOrCommentOrLinebreak, before: identifierIndex),
                   prevToken == .delimiter(",") || prevToken.isDeclarationTypeKeyword
                {
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

    /// Recursively searches to the start of scopes until we either no longer find a scope or we know we are in a closure.
    func isInClosure(at index: Int) -> Bool {
        guard let startOfScopeIndex = startOfScope(at: index) else {
            return false
        }
        if isStartOfClosure(at: startOfScopeIndex) {
            return true
        } else {
            return isInClosure(at: startOfScopeIndex)
        }
    }

    /// Whether the given index is within the body of the given function declaration,
    /// and not inside a nested closure or nested function.
    func isInFunctionBody(of functionDecl: FunctionDeclaration, at index: Int) -> Bool {
        guard let bodyRange = functionDecl.bodyRange,
              bodyRange.contains(index)
        else {
            return false
        }

        guard let startOfScopeIndex = startOfScope(at: index) else {
            return false
        }

        if startOfScopeIndex == bodyRange.lowerBound {
            return true
        }

        if isStartOfClosure(at: startOfScopeIndex) {
            return false
        }

        // If this is a function scope, but not the body of the function itself,
        // then this is some nested function.
        if lastSignificantKeyword(at: startOfScopeIndex, excluding: ["where"]) == "func",
           startOfScopeIndex != bodyRange.lowerBound
        {
            return false
        }

        // Recursively check parent scope
        return isInFunctionBody(of: functionDecl, at: startOfScopeIndex)
    }

    /// Whether or not this index the start of scope of a closure literal, eg `{` but not some other type of scope.
    func isStartOfClosure(at i: Int) -> Bool {
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
                return false
            }
            fallthrough
        case .identifier, .number, .operator("?", .postfix), .operator("!", .postfix),
             .endOfScope where tokens[prevIndex].isStringDelimiter:
            if let nextIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: i),
               isAccessorKeyword(at: nextIndex) || isAccessorKeyword(at: prevIndex)
            {
                return false
            }
            guard let prevKeywordIndex = indexOfLastSignificantKeyword(at: prevIndex, excluding: ["where"]) else {
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
                 "func", "init", "subscript", "catch":
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

    /// Whether or not the index is the start of a valid closure type
    func isStartOfClosureType(at i: Int) -> Bool {
        guard let type = parseType(at: i),
              index(of: .operator("->", .infix), in: Range(type.range)) != nil
        else { return false }

        // Avoid confusing the arguments + return type of a function declaration with a closure type
        if let previousKeyword = indexOfLastSignificantKeyword(at: i, excluding: ["where"]),
           tokens[previousKeyword] == .keyword("func"),
           let functionDeclaration = parseFunctionDeclaration(keywordIndex: previousKeyword),
           functionDeclaration.argumentsRange.lowerBound == type.range.lowerBound
        {
            return false
        }

        return true
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

    /// Returns true if the token at the specified index is part of a conditional assignment
    /// (e.g. an if or switch expression following an `=` token)
    func isConditionalAssignment(at i: Int) -> Bool {
        guard let startOfConditional = startOfConditionalStatement(at: i),
              let previousToken = lastToken(before: startOfConditional, where: { !$0.isSpaceOrCommentOrLinebreak })
        else { return false }

        return previousToken.isOperator("=")
    }

    /// If the token at the specified index is part of a conditional statement, returns the index of the first
    /// token in the statement (e.g. `if`, `guard`, `while`, etc.), otherwise returns nil
    func startOfConditionalStatement(at i: Int, excluding: Set<String> = []) -> Int? {
        guard var index = indexOfLastSignificantKeyword(at: i, excluding: excluding.union(["else"])) else {
            return nil
        }

        if tokens[index] == .keyword("where") {
            if self.index(of: .endOfScope("case"), before: index) != nil {
                return nil
            }
            index = indexOfLastSignificantKeyword(at: index, excluding: ["where"]) ?? index
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
        case "if", "guard", "while", "for", "case":
            return index
        case "switch":
            return next(.startOfScope, after: i) == .startOfScope(":") ? nil : index
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
        case .startOfScope("(") where !tokens[i + 1 ..< startIndex].contains(where: \.isLinebreak):
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

    /// Whether or not this property at the given introducer index (either `var` or `let`)
    /// is a stored property or a computed property.
    func isStoredProperty(atIntroducerIndex introducerIndex: Int) -> Bool {
        guard let property = parsePropertyDeclaration(atIntroducerIndex: introducerIndex) else {
            return false
        }

        // If this property doesn't have a body, then it's definitely a stored property.
        guard let bodyRange = property.body?.range,
              let firstTokenInBody = token(at: bodyRange.lowerBound)
        else {
            return true
        }

        // If this property has a body, then its a stored property if and only if the body
        // has a `didSet` or `willSet` keyword, based on the grammar for a variable declaration.
        return [.identifier("willSet"), .identifier("didSet")].contains(firstTokenInBody)
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
            // For arrays or argument lists, we already indent
            guard let scope = scope ?? currentScope(at: i) else { return false }
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
               !tokens[startIndex ..< prevIndex].contains(where: \.isLinebreak)
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
               let prevIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: i),
               case let prevToken = tokens[prevIndex], [
                   .delimiter(","), .startOfScope("["), .startOfScope("(")
               ].contains(prevToken) || (
                   [
                       .operator("?", .postfix), .operator("!", .postfix),
                   ].contains(prevToken) && [
                       .keyword("try"), .keyword("as"),
                   ].contains(last(.nonSpaceOrComment, before: prevIndex) ?? .space(""))
               )
            {
                return false
            }
            fallthrough
        case .keyword("try"), .keyword("await"):
            guard let prevToken = last(.nonSpaceOrCommentOrLinebreak, before: i) else {
                return true
            }
            switch prevToken {
            case .number, .operator(_, .postfix), .endOfScope, .identifier,
                 .startOfScope("{"), .startOfScope(":"), .delimiter(";"),
                 .keyword("in") where lastSignificantKeyword(at: i) != "for":
                return true
            default:
                return false
            }
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
               prevToken == .keyword("return") || prevToken.isOperator(ofType: .infix) ||
               currentScope(at: i)?.isMultilineStringDelimiter == true
            {
                return false
            }
            return true
        }
    }

    /// Whether the given index is a `startOfScope("{")` that represents the start of a type body
    func isStartOfTypeBody(at scopeIndex: Int) -> Bool {
        guard tokens[scopeIndex] == .startOfScope("{") else { return false }

        guard let lastKeyword = lastSignificantKeyword(at: scopeIndex, excluding: ["where"]) else {
            return false
        }

        return Token.swiftTypeKeywords.contains(lastKeyword)
    }

    func isTrailingClosureLabel(at i: Int) -> Bool {
        if case .identifier? = token(at: i),
           last(.nonSpaceOrCommentOrLinebreak, before: i) == .endOfScope("}"),
           let nextIndex = index(of: .nonSpaceOrComment, after: i, if: { $0 == .delimiter(":") }),
           let nextNextIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: nextIndex),
           isStartOfClosure(at: nextNextIndex)
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
             .endOfScope("]"), .endOfScope(")"), .endOfScope(">"), .endOfScope("}"),
             .endOfScope where prevToken.isStringDelimiter:
            return true
        default:
            return false
        }
    }

    /// Crude check to detect if code is inside a Result Builder
    /// Note: this will produce false positives for any init that takes a closure
    func isInResultBuilder(at i: Int) -> Bool {
        var i = i
        while let startIndex = index(before: i, where: {
            [.startOfScope("{"), .startOfScope(":"), .startOfScope("#if")].contains($0)
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
            if tokens[prevIndex].isStartOfScope, i != startIndex {
                i = startIndex
            } else {
                i = prevIndex
            }
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
    ///  - `(...) (async|throws|throws(Error)) -> ...`
    ///  - `...?`
    ///  - `...!`
    ///  - `any ...`
    ///  - `some ...`
    ///  - `borrowing ...`
    ///  - `consuming ...`
    ///  - `sending ...`
    ///  - `repeat ...`
    ///  - `each ...`
    ///  - `inout ...`
    ///  - `~...`
    ///  - any `@attribute ...`
    ///  - `(type).(type)`
    ///  - `(type) & (type)`
    func parseType(
        at startOfTypeIndex: Int,
        excludeLowercaseIdentifiers: Bool = false,
        excludeProtocolCompositions: Bool = false
    ) -> (name: String, range: ClosedRange<Int>)? {
        guard let baseType = parseNonOptionalType(
            at: startOfTypeIndex,
            excludeLowercaseIdentifiers: excludeLowercaseIdentifiers,
            excludeProtocolCompositions: excludeProtocolCompositions
        )
        else { return nil }

        // Any type can be optional, so check for a trailing `?` or `!`.
        // There cannot be any other tokens between the type and the operator:
        //
        //   let foo: String? // allowed
        //   let foo: String ? // not allowed
        //   let foo: String/*bar*/? // not allowed
        //
        let nextTokenIndex = baseType.range.upperBound + 1
        if token(at: nextTokenIndex)?.isUnwrapOperator == true {
            let typeRange = baseType.range.lowerBound ... nextTokenIndex
            return (name: tokens[typeRange].stringExcludingLinebreaksAndComments, range: typeRange)
        }

        // Any type can be followed by a `.` or `&` which can then continue the type
        let continuationOperators: [Token]
        if excludeProtocolCompositions {
            continuationOperators = [.operator(".", .infix)]
        } else {
            continuationOperators = [.operator(".", .infix), .operator("&", .infix)]
        }

        if let nextTokenIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: baseType.range.upperBound),
           continuationOperators.contains(tokens[nextTokenIndex]),
           let followingToken = index(of: .nonSpaceOrCommentOrLinebreak, after: nextTokenIndex),
           let followingType = parseType(at: followingToken, excludeLowercaseIdentifiers: excludeLowercaseIdentifiers)
        {
            let typeRange = startOfTypeIndex ... followingType.range.upperBound
            return (name: tokens[typeRange].stringExcludingLinebreaksAndComments, range: typeRange)
        }

        return baseType
    }

    private func parseNonOptionalType(
        at startOfTypeIndex: Int,
        excludeLowercaseIdentifiers: Bool,
        excludeProtocolCompositions: Bool
    ) -> (name: String, range: ClosedRange<Int>)? {
        let startToken = tokens[startOfTypeIndex]

        /// Helpers that calls `parseType` with all of the optional params passed in by default
        func parseType(at index: Int) -> (name: String, range: ClosedRange<Int>)? {
            self.parseType(
                at: index,
                excludeLowercaseIdentifiers: excludeLowercaseIdentifiers,
                excludeProtocolCompositions: excludeProtocolCompositions
            )
        }

        // Parse types of the form `[...]`
        if startToken == .startOfScope("["), let endOfScope = endOfScope(at: startOfTypeIndex) {
            // Validate that the inner type is also valid
            guard let innerTypeStartIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: startOfTypeIndex),
                  let innerType = parseType(at: innerTypeStartIndex),
                  let indexAfterType = index(of: .nonSpaceOrCommentOrLinebreak, after: innerType.range.upperBound)
            else { return nil }

            // This is either an array type of the form `[Element]`,
            // or a dictionary type of the form `[Key: Value]`.
            if indexAfterType != endOfScope {
                guard tokens[indexAfterType] == .delimiter(":"),
                      let secondTypeIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: indexAfterType),
                      let secondType = parseType(at: secondTypeIndex),
                      let indexAfterSecondType = index(of: .nonSpaceOrCommentOrLinebreak, after: secondType.range.upperBound),
                      indexAfterSecondType == endOfScope
                else { return nil }
            }

            let typeRange = startOfTypeIndex ... endOfScope
            return (name: tokens[typeRange].stringExcludingLinebreaksAndComments, range: typeRange)
        }

        // Parse types of the form `(...)` or `(...) -> ...`
        if startToken == .startOfScope("("), let endOfScope = endOfScope(at: startOfTypeIndex) {
            // Parse types of the form `(...) (async|throws|throws(Error)) -> ...`.
            // Look for the `->` token, skipping over any `async`, `throws`, or `throws(Error)`s.
            var searchIndex = endOfScope

            if let effectsRange = parseFunctionDeclarationEffectsClause(at: endOfScope)?.range {
                searchIndex = effectsRange.upperBound
            }

            // If we find a return arrow, this is a closure with a return type.
            if let closureReturnIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: searchIndex),
               tokens[closureReturnIndex] == .operator("->", .infix),
               let returnTypeIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: closureReturnIndex),
               let returnTypeRange = parseType(at: returnTypeIndex)?.range
            {
                let typeRange = startOfTypeIndex ... returnTypeRange.upperBound
                return (name: tokens[typeRange].stringExcludingLinebreaksAndComments, range: typeRange)
            }

            // Otherwise this is just `(...)`
            let typeRange = startOfTypeIndex ... endOfScope
            return (name: tokens[typeRange].stringExcludingLinebreaksAndComments, range: typeRange)
        }

        // Parse types of the form `Foo<...>`
        if let nextTokenIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: startOfTypeIndex),
           tokens[nextTokenIndex] == .startOfScope("<"),
           let endOfScope = endOfScope(at: nextTokenIndex)
        {
            let typeRange = startOfTypeIndex ... endOfScope
            return (name: tokens[typeRange].stringExcludingLinebreaksAndComments, range: typeRange)
        }

        // Parse types with any of the following prefixes, along with any `@attribute`.
        let typePrefixes = Set(["any", "some", "borrowing", "consuming", "sending", "repeat", "each", "~", "inout"])
        if typePrefixes.contains(startToken.string) || startToken.isAttribute,
           let nextToken = index(of: .nonSpaceOrCommentOrLinebreak, after: startOfTypeIndex),
           let followingType = parseType(at: nextToken)
        {
            let typeRange = startOfTypeIndex ... followingType.range.upperBound
            return (name: tokens[typeRange].stringExcludingLinebreaksAndComments, range: typeRange)
        }

        // Otherwise this is just a single identifier
        if case let .identifier(name) = startToken, name != "init" {
            let firstCharacter = name.drop { $0 == "_" }.first.flatMap(String.init) ?? ""
            let isLowercaseIdentifier = firstCharacter.uppercased() != firstCharacter
            guard !excludeLowercaseIdentifiers || !isLowercaseIdentifier else { return nil }

            return (name: name, range: startOfTypeIndex ... startOfTypeIndex)
        }

        return nil
    }

    /// Whether or not the `.startOfScope("(")` token at the given index represents the start of a valid tuple type.
    func isStartOfTupleType(at index: Int) -> Bool {
        parseType(at: index)?.name.isTupleType == true
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
    ) -> ClosedRange<Int>? {
        // Any expression can start with a prefix operator, or `await`, `repeat`, `each`
        let prefixKeywords = ["await", "repeat", "each"]
        if tokens[startIndex].isOperator(ofType: .prefix) || prefixKeywords.contains(tokens[startIndex].string),
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
            case .startOfScope("{") where isStartOfClosure(at: nextTokenIndex):
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

    /// Parses all of the declarations in the source file.
    func parseDeclarations() -> [Declaration] {
        parseDeclarations(in: tokens.indices)
    }

    /// Parses the declarations in the given range.
    func parseDeclarations(in range: Range<Int>) -> [Declaration] {
        /// A temporary declaration value. We can't create a `DeclarationV2` directly
        /// within the `forEachToken` call, since `forEachToken` doesn't support reentrancy.
        struct _Declaration {
            let keyword: String
            let keywordIndex: Int
            let range: ClosedRange<Int>
        }

        var declarations = [_Declaration]()
        var startOfDeclaration = range.lowerBound

        forEachToken(onlyWhereEnabled: false) { index, token in
            guard range.contains(index),
                  index >= startOfDeclaration,
                  token.isDeclarationTypeKeyword || token == .startOfScope("#if")
            else {
                return
            }

            let keywordIndex = index
            let declarationKeyword = declarationType(at: keywordIndex) ?? "#if"
            let endOfDeclaration = self._endOfDeclarationInTypeBody(atDeclarationKeyword: keywordIndex)

            let declarationRange = startOfDeclaration ... min(endOfDeclaration ?? .max, range.upperBound - 1)
            startOfDeclaration = declarationRange.upperBound + 1

            // If the current rule is disabled at this index, don't keep the declaration.
            // This makes it easy for parseDeclarations-based rules to support directives
            // like swiftformat:disable, swiftformat:disable:next.
            if isEnabled {
                declarations.append(_Declaration(
                    keyword: declarationKeyword,
                    keywordIndex: keywordIndex,
                    range: declarationRange
                ))
            }
        }

        return declarations.map { declaration in
            // If this declaration represents a type, we need to parse its inner declarations as well.
            if Token.swiftTypeKeywords.contains(declaration.keyword),
               let bodyOpenBrace = self.index(of: .startOfScope("{"), after: declaration.keywordIndex),
               let endOfScope = endOfScope(at: bodyOpenBrace)
            {
                // The type body excludes any leading linebreaks or trailing spaces.
                let body: [Declaration]
                if let startOfBody = self.index(of: .nonLinebreak, after: bodyOpenBrace),
                   let endOfBody = self.index(of: .nonSpace, before: endOfScope),
                   startOfBody <= endOfBody
                {
                    body = parseDeclarations(in: Range(startOfBody ... endOfBody))
                } else {
                    body = parseDeclarations(in: (bodyOpenBrace + 1) ..< endOfScope)
                }

                return TypeDeclaration(
                    keyword: declaration.keyword,
                    range: declaration.range,
                    body: body,
                    formatter: self
                )
            }

            // If this declaration represents a conditional compilation block,
            // we also have to parse its inner declarations.
            else if declaration.keyword == "#if",
                    let endOfScope = endOfScope(at: declaration.keywordIndex)
            {
                // The conditional compilation body excludes any leading linebreaks or trailing spaces.
                let body: [Declaration]
                if let startOfBody = self.index(of: .nonLinebreak, after: endOfLine(at: declaration.keywordIndex)),
                   let endOfBody = self.index(of: .nonSpace, before: endOfScope),
                   startOfBody <= endOfBody
                {
                    body = parseDeclarations(in: Range(startOfBody ... endOfBody))
                } else {
                    body = parseDeclarations(in: (endOfLine(at: declaration.keywordIndex) + 1) ..< endOfScope)
                }

                return ConditionalCompilationDeclaration(
                    range: declaration.range,
                    body: body,
                    formatter: self
                )
            }

            else {
                return SimpleDeclaration(
                    keyword: declaration.keyword,
                    range: declaration.range,
                    formatter: self
                )
            }
        }
        .filter(\.isValid)
    }

    /// Returns the end index of the `Declaration` containing `declarationKeywordIndex`.
    /// This is mostly an implementation detail of `parseDeclarations` and only correctly
    /// handles declarations within type bodies (not within function bodies).
    ///  - `declarationKeywordIndex.isDeclarationTypeKeyword` must be `true`
    ///    (e.g. it must be a keyword like `let`, `var`, `func`, `class`, etc.
    func _endOfDeclarationInTypeBody(atDeclarationKeyword declarationKeywordIndex: Int) -> Int? {
        assert(tokens[declarationKeywordIndex].isDeclarationTypeKeyword
            || tokens[declarationKeywordIndex] == .startOfScope("#if"))

        // Get declaration keyword
        var searchIndex = declarationKeywordIndex
        let declarationKeyword = declarationType(at: declarationKeywordIndex) ?? "#if"
        switch tokens[declarationKeywordIndex] {
        case .startOfScope("#if"):
            // For conditional compilation blocks, the `declarationKeyword` _is_ the `startOfScope`
            // so we can immediately skip to the corresponding #endif
            if let endOfConditionalCompilationScope = endOfScope(at: declarationKeywordIndex) {
                searchIndex = endOfConditionalCompilationScope
            }
        case .keyword("class") where declarationKeyword != "class":
            // Most declarations will include exactly one token that `isDeclarationTypeKeyword` in
            //  - `class func` methods will have two (and the first one will be incorrect!)
            searchIndex = index(of: .keyword(declarationKeyword), after: declarationKeywordIndex) ?? searchIndex
        case .keyword("import"):
            // Symbol imports (like `import class Module.Type`) will have an extra `isDeclarationTypeKeyword`
            // immediately following their `declarationKeyword`, so we need to skip them.
            if let symbolTypeKeywordIndex = index(of: .nonSpaceOrComment, after: declarationKeywordIndex),
               tokens[symbolTypeKeywordIndex].isDeclarationTypeKeyword
            {
                searchIndex = symbolTypeKeywordIndex
            }
        case .keyword("protocol"), .keyword("struct"), .keyword("actor"),
             .keyword("enum"), .keyword("extension"):
            if let scopeStart = index(of: .startOfScope("{"), after: declarationKeywordIndex) {
                searchIndex = endOfScope(at: scopeStart) ?? searchIndex
            }
        case .keyword("let"), .keyword("var"):
            if let propertyDeclaration = parsePropertyDeclaration(atIntroducerIndex: declarationKeywordIndex) {
                searchIndex = propertyDeclaration.range.upperBound
            }
        default:
            break
        }

        // Search for the next declaration so we know where this declaration ends.
        let nextDeclarationKeywordIndex = index(after: searchIndex, where: {
            $0.isDeclarationTypeKeyword || $0 == .startOfScope("#if")
        })

        // Search backward from the next declaration keyword to find where declaration begins.
        var endOfDeclaration = nextDeclarationKeywordIndex.flatMap {
            index(before: startOfModifiers(at: $0, includingAttributes: true), where: {
                !$0.isSpaceOrCommentOrLinebreak
            }).map { endOfLine(at: $0) }
        }

        // Prefer keeping linebreaks at the end of a declaration's tokens,
        // instead of the start of the next delaration's tokens.
        //  - This includes any spaces on blank lines, but doesn't include the
        //    indentation associated with the next declaration.
        while let linebreakSearchIndex = endOfDeclaration,
              token(at: linebreakSearchIndex + 1)?.isSpaceOrLinebreak == true
        {
            // Only spaces between linebreaks (e.g. spaces on blank lines) are included
            if token(at: linebreakSearchIndex + 1)?.isSpace == true {
                guard token(at: linebreakSearchIndex)?.isLinebreak == true,
                      token(at: linebreakSearchIndex + 2)?.isLinebreak == true
                else { break }
            }

            endOfDeclaration = linebreakSearchIndex + 1
        }

        return endOfDeclaration
    }

    /// Whether or not the body within this scope is a single expression
    func scopeBodyIsSingleExpression(at startOfScopeIndex: Int) -> Bool {
        guard let endOfScopeIndex = endOfScope(at: startOfScopeIndex),
              startOfScopeIndex + 1 != endOfScopeIndex,
              let firstTokenInBody = index(of: .nonSpaceOrCommentOrLinebreak, after: startOfScopeIndex + 1),
              let expressionRange = parseExpressionRange(startingAt: firstTokenInBody, allowConditionalExpressions: true)
        else { return false }

        return index(of: .nonSpaceOrCommentOrLinebreak, after: expressionRange.upperBound) == endOfScopeIndex
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

    /// A property of the format `(let|var) identifier: Type = expression { ... }`.
    ///  - `: Type`, `= expression`, and the following `{ ... }` body are optional
    struct PropertyDeclaration {
        /// The start index for this property's list of modifiers.
        /// If there are no modifiers, `startOfModifiersIndex` is just `introducerIndex`.
        let startOfModifiersIndex: Int

        /// The index of the `let` or `var` keyword
        let introducerIndex: Int

        /// The identifier / name of this property.
        let identifier: String

        /// The index of this property's identifier / name.
        let identifierIndex: Int

        /// Information about the property's type definition, if written explicitly.
        let type: (colonIndex: Int, name: String, range: ClosedRange<Int>)?

        /// Information about the value following the property's `=` token, if present.
        let value: (assignmentIndex: Int, expressionRange: ClosedRange<Int>)?

        /// Information about the body following the property, which can include
        /// `get`, `set`, `willSet`, `didSet` blocks, or just a single getter.
        ///  - `scopeRange` is the range starting at the `{` token and ending at the `}` token.
        ///  - `range` is the range of tokens inside the body scope.
        let body: (scopeRange: ClosedRange<Int>, range: ClosedRange<Int>)?

        var range: ClosedRange<Int> {
            if let bodyScopeRange = body?.scopeRange {
                return startOfModifiersIndex ... bodyScopeRange.upperBound
            } else if let value {
                return startOfModifiersIndex ... value.expressionRange.upperBound
            } else if let type {
                return startOfModifiersIndex ... type.range.upperBound
            } else {
                return startOfModifiersIndex ... identifierIndex
            }
        }
    }

    /// Parses a property of the format `(let|var) identifier: Type = expression`
    /// starting at the given introducer index (the `let` / `var` keyword).
    ///
    /// Does not attempt to parse less-common property declarations that define multiple identifiers,
    /// like `let (foo, bar) = (1, 2)` or `let foo: Foo, bar: Bar`.
    func parsePropertyDeclaration(atIntroducerIndex introducerIndex: Int) -> PropertyDeclaration? {
        guard ["let", "var"].contains(tokens[introducerIndex].string),
              let propertyIdentifierIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: introducerIndex),
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

        let endOfTypeOrIdentifierOrValue = valueInformation?.expressionRange.upperBound ?? endOfTypeOrIdentifier
        var body: (scopeRange: ClosedRange<Int>, range: ClosedRange<Int>)?

        if let startOfBodyIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: endOfTypeOrIdentifierOrValue),
           tokens[startOfBodyIndex] == .startOfScope("{"),
           let endOfScope = endOfScope(at: startOfBodyIndex)
        {
            let bodyRange = startOfBodyIndex ... endOfScope

            let rangeInsideBody: ClosedRange<Int>
            if startOfBodyIndex + 1 != endOfScope {
                if let firstTokenInBody = index(of: .nonSpaceOrCommentOrLinebreak, after: startOfBodyIndex + 1),
                   let lastTokenInBody = index(of: .nonSpaceOrCommentOrLinebreak, before: endOfScope),
                   firstTokenInBody <= lastTokenInBody
                {
                    rangeInsideBody = firstTokenInBody ... lastTokenInBody
                } else {
                    rangeInsideBody = startOfBodyIndex + 1 ... endOfScope - 1
                }
            } else {
                rangeInsideBody = bodyRange
            }

            body = (bodyRange, rangeInsideBody)
        }

        return PropertyDeclaration(
            startOfModifiersIndex: startOfModifiers(at: introducerIndex, includingAttributes: true),
            introducerIndex: introducerIndex,
            identifier: propertyIdentifier.string,
            identifierIndex: propertyIdentifierIndex,
            type: typeInformation,
            value: valueInformation,
            body: body
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
                    case let .identifier(string) where name.hasSuffix("."):
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

    /// Whether or not the given module is imported in this file
    func hasImport(_ moduleName: String) -> Bool {
        parseImports().contains(where: { importGroup in
            importGroup.contains(where: { importedModule in
                importedModule.module == moduleName
            })
        })
    }

    enum TestingFramework {
        case xcTest
        case swiftTesting
    }

    /// Detects which testing framework is being used in the file
    func detectTestingFramework() -> TestingFramework? {
        if hasImport("Testing") {
            return .swiftTesting
        } else if hasImport("XCTest") {
            return .xcTest
        } else {
            return nil
        }
    }

    /// Adds imports for the given list of modules to this file if not already present
    func addImports(_ importsToAddIfNeeded: [String]) {
        let importRanges = parseImports()
        let currentImports = Set(importRanges.flatMap { $0.map(\.module) })

        for importToAddIfNeeded in importsToAddIfNeeded {
            guard !currentImports.contains(importToAddIfNeeded) else { continue }

            let newImport: [Token] = [.keyword("import"), .space(" "), .identifier(importToAddIfNeeded)]

            // If there are any existing imports, add the new import in the existing group
            if let firstImportIndex = index(of: .keyword("import"), after: -1) {
                let startOfFirstImport = startOfModifiers(at: firstImportIndex, includingAttributes: true)
                insert(newImport + [linebreakToken(for: firstImportIndex)], at: startOfFirstImport)
            }

            // Otherwise if there are no imports:
            //  - Make sure to insert the comment after any header comment if present
            //  - Include a blank line after the import
            else {
                let insertionIndex: Int
                if let headerCommentRange = headerCommentTokenRange(), !headerCommentRange.isEmpty {
                    insertionIndex = headerCommentRange.upperBound
                } else {
                    insertionIndex = 0
                }

                let newImportWithBlankLine = newImport + [
                    linebreakToken(for: insertionIndex),
                    linebreakToken(for: insertionIndex),
                ]

                insert(newImportWithBlankLine, at: insertionIndex)
            }
        }
    }

    /// Removes the import for the given module names if present
    func removeImports(_ moduleNames: Set<String>) {
        let imports = parseImports().flatMap { $0 }
        let importsToRemove = imports.filter { moduleNames.contains($0.module) }

        let importsToRemoveByFileOrder = importsToRemove.sorted(by: { lhs, rhs in
            lhs.range.lowerBound < rhs.range.lowerBound
        })

        for importToRemove in importsToRemoveByFileOrder.reversed() {
            removeTokens(in: importToRemove.range)
        }
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
        let typeDeclarations = Set(["class", "actor", "struct", "enum", "protocol", "extension"])

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

        // If this declaration isn't within any scope, it must be a global.
        guard let startOfScopeIndex = startOfScope else {
            return (nil, isConditionalStatement(at: i) ? .local : .global)
        }

        // Code within closures and conditionals is always local
        if isStartOfClosureOrFunctionBody(at: startOfScopeIndex) || isConditionalStatement(at: startOfScopeIndex) {
            return (nil, .local)
        }

        guard let declarationKeywordIndex = indexOfLastSignificantKeyword(
            at: startOfScopeIndex, excluding: ["where"]
        ) else {
            // Probably a contextual keyword like get, set, didSet, willSet, etc
            return (nil, .local)
        }

        if typeDeclarations.contains(tokens[declarationKeywordIndex].string) {
            return (declarationKeywordIndex, .type)
        } else {
            return (declarationKeywordIndex, .local)
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
    func headerCommentTokenRange(includingDirectives directives: [String] = []) -> Range<Int>? {
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

    /// Finds the set of single-line comments in the given range matching the given closure
    func singleLineComments(
        in range: Range<Int>,
        matching isMatch: (_ commentBody: String) -> Bool
    ) -> [ClosedRange<Int>] {
        var matches = [ClosedRange<Int>]()

        for commentStartIndex in range {
            guard tokens[commentStartIndex] == .startOfScope("//"),
                  let commentBodyIndex = index(after: commentStartIndex, where: \.isCommentBody)
            else { continue }

            if isMatch(tokens[commentBodyIndex].string) {
                matches.append(commentStartIndex ... commentBodyIndex)
            }
        }

        return matches
    }

    /// Parses the prorocol composition typealias declaration starting at the given `typealias` keyword index.
    /// Returns `nil` if the given index isn't a protocol composition typealias.
    func parseProtocolCompositionTypealias(at typealiasIndex: Int)
        -> (equalsIndex: Int, andTokenIndices: [Int], endIndex: Int)?
    {
        guard let equalsIndex = index(of: .operator("=", .infix), after: typealiasIndex),
              let startOfType = index(of: .nonSpaceOrCommentOrLinebreak, after: equalsIndex),
              let fullProtocolCompositionType = parseType(at: startOfType)
        else { return nil }

        var andTokenIndices: [Int] = []
        var currentIndex = startOfType

        while let nextType = parseType(at: currentIndex, excludeProtocolCompositions: true),
              let nextAndToken = index(of: .nonSpaceOrCommentOrLinebreak, after: nextType.range.upperBound),
              tokens[nextAndToken] == .operator("&", .infix),
              let tokenAfterAndToken = index(of: .nonSpaceOrCommentOrLinebreak, after: nextAndToken)
        {
            andTokenIndices.append(nextAndToken)
            currentIndex = tokenAfterAndToken
        }

        // If we didn't find any `&` tokens then this isn't a protocol composition typealias.
        guard !andTokenIndices.isEmpty else { return nil }

        return (equalsIndex, andTokenIndices, fullProtocolCompositionType.range.upperBound)
    }

    /// A fully parsed function declaration
    struct FunctionDeclaration {
        /// The index of the `func`, `subscript`, or `init` keyword
        let keywordIndex: Int
        /// The name of the function
        let name: String?
        /// The index of the function name's `identifier` token
        let nameIndex: Int?
        /// The range of of the generic parameters clause (`<...>`) if present
        let genericParameterRange: ClosedRange<Int>?
        /// The range of the function arguments (`(...)`)
        let argumentsRange: ClosedRange<Int> // the range of (...)
        /// The parsed function arguments within `argumentsRange`
        let arguments: [FunctionArgument]
        /// The range of effects keywords (`async`, `throws`, `rethrows`)
        let effectsRange: ClosedRange<Int>?
        /// The effects applied to the function in `effectsRange`
        let effects: Set<String>
        /// The index of the `->` operator if present
        let returnOperatorIndex: Int?
        /// The parsed return type if present
        let returnType: (name: String, range: ClosedRange<Int>)?
        /// The range of the `where` clause if present
        let whereClauseRange: ClosedRange<Int>?
        /// The range of the function body (`{ ... }`) if present.
        /// A protocol method requirement doesn't have a body.
        let bodyRange: ClosedRange<Int>?

        /// The full range of this declaration
        var range: ClosedRange<Int> {
            let endIndex = bodyRange?.upperBound
                ?? whereClauseRange?.upperBound
                ?? returnType?.range.upperBound
                ?? effectsRange?.upperBound
                ?? argumentsRange.upperBound

            return keywordIndex ... endIndex
        }
    }

    /// A function argument like `with foo: Foo`.
    struct FunctionArgument: Equatable {
        /// The external label of this argument. `nil` if omitted with an `_`.
        let externalLabel: String?

        /// The internal label of this argument. `nil` if omitted with an `_`.
        let internalLabel: String?

        /// The index of the external argument label. If nil, the argument
        /// uses the same label both internally and externally.
        let externalLabelIndex: Int?

        /// The index of the internal argument name. Always present in the grammar.
        let internalLabelIndex: Int

        /// The type of the argument
        var type: String
    }

    /// Parses the function or function-like declaration (`func`, `subscript`, `init`) at the given keyword index
    func parseFunctionDeclaration(keywordIndex: Int) -> FunctionDeclaration? {
        assert(["func", "subscript", "init"].contains(tokens[keywordIndex].string))
        var currentIndex = keywordIndex

        var nameIndex: Int?
        var name: String?

        // Only function declarations (not subscripts / inits) have names
        if tokens[keywordIndex] == .keyword("func") {
            // The `func` / `subscript` keyword is always followed by the method name
            guard let funcNameIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: keywordIndex) else {
                return nil
            }

            nameIndex = funcNameIndex
            name = tokens[funcNameIndex].string
            currentIndex = funcNameIndex
        }

        // If this is a failable initializer (`init?`), skip over the ? token
        if tokens[keywordIndex] == .keyword("init"),
           let nextToken = index(of: .nonSpaceOrCommentOrLinebreak, after: keywordIndex),
           tokens[nextToken] == .operator("?", .postfix)
        {
            currentIndex = nextToken
        }

        // Parse the optional generic parameters in `<...>`
        var genericParameterRange: ClosedRange<Int>?
        if let startOfGenericParameters = index(of: .nonSpaceOrCommentOrLinebreak, after: currentIndex),
           tokens[startOfGenericParameters] == .startOfScope("<"),
           let endOfGenericParameters = endOfScope(at: startOfGenericParameters)
        {
            genericParameterRange = startOfGenericParameters ... endOfGenericParameters
            currentIndex = endOfGenericParameters
        }

        // All functions have an arguments list, following the optional generic parameters
        guard let startOfArguments = index(of: .nonSpaceOrCommentOrLinebreak, after: currentIndex),
              tokens[startOfArguments] == .startOfScope("("),
              let endOfArguments = endOfScope(at: startOfArguments)
        else { return nil }

        let argumentsRange = startOfArguments ... endOfArguments
        currentIndex = endOfArguments

        let effects: Set<String>
        let effectsRange: ClosedRange<Int>?

        if let parsedEffects = parseFunctionDeclarationEffectsClause(at: currentIndex) {
            effects = parsedEffects.effects
            effectsRange = parsedEffects.range
            currentIndex = parsedEffects.range.upperBound + 1
        } else {
            effects = []
            effectsRange = nil
        }

        // Parse the optional return type
        let returnOperatorIndex: Int?
        let returnType: (name: String, range: ClosedRange<Int>)?

        if let parsedReturnType = parseFunctionDeclarationReturnClause(at: currentIndex) {
            returnOperatorIndex = parsedReturnType.returnOperatorIndex
            returnType = parsedReturnType.returnType
            currentIndex = parsedReturnType.returnType.range.upperBound
        } else {
            returnOperatorIndex = nil
            returnType = nil
        }

        // Parse the optional where clause
        var whereClauseRange: ClosedRange<Int>?
        if let whereKeyword = index(of: .nonSpaceOrCommentOrLinebreak, after: currentIndex),
           tokens[whereKeyword] == .keyword("where")
        {
            let parsedWhereClauseRange = parseGenericTypes(from: whereKeyword).range
            whereClauseRange = parsedWhereClauseRange
            currentIndex = parsedWhereClauseRange.upperBound
        }

        // Parse the optional body.
        // If this is a protocol declaration, there will be no body.
        var bodyRange: ClosedRange<Int>?
        if let bodyOpenBrace = index(of: .nonSpaceOrCommentOrLinebreak, after: currentIndex),
           tokens[bodyOpenBrace] == .startOfScope("{"),
           let bodyClosingBrace = endOfScope(at: bodyOpenBrace)
        {
            bodyRange = bodyOpenBrace ... bodyClosingBrace
        }

        return FunctionDeclaration(
            keywordIndex: keywordIndex,
            name: name,
            nameIndex: nameIndex,
            genericParameterRange: genericParameterRange,
            argumentsRange: argumentsRange,
            arguments: parseFunctionDeclarationArguments(startOfScope: argumentsRange.lowerBound),
            effectsRange: effectsRange,
            effects: effects,
            returnOperatorIndex: returnOperatorIndex,
            returnType: returnType,
            whereClauseRange: whereClauseRange,
            bodyRange: bodyRange
        )
    }

    /// Parses the arguments of the function with its `(` start of scope token at the given index.
    func parseFunctionDeclarationArguments(startOfScope: Int) -> [FunctionArgument] {
        assert(tokens[startOfScope] == .startOfScope("("))
        guard let endOfScope = endOfScope(at: startOfScope) else { return [] }

        var arguments: [FunctionArgument] = []

        var currentIndex = startOfScope
        while let nextArgumentColon = index(of: .delimiter(":"), in: (currentIndex + 1) ..< endOfScope) {
            let colonIndex = nextArgumentColon
            currentIndex = nextArgumentColon

            // If there is only one label, the param has the same internal and external label.
            // If there are two labels, the first one is the external label.
            guard let internalLabelIndex = index(of: .nonSpaceOrComment, before: colonIndex),
                  tokens[internalLabelIndex].isIdentifier || tokens[internalLabelIndex].string == "_"
            else { continue }

            var externalLabelIndex = internalLabelIndex
            var hasExplicitExternalLabel = false

            if let possibleExternalLabelIndex = index(of: .nonSpaceOrComment, before: internalLabelIndex),
               tokens[possibleExternalLabelIndex].isIdentifier || tokens[possibleExternalLabelIndex].string == "_"
            {
                externalLabelIndex = possibleExternalLabelIndex
                hasExplicitExternalLabel = true
            }

            guard let startOfType = index(of: .nonSpaceOrComment, after: colonIndex),
                  let type = parseType(at: startOfType)?.name
            else { continue }

            let identifierString: (Token) -> String? = { token in
                if token.string == "_" {
                    return nil
                } else {
                    return token.unescaped()
                }
            }

            arguments.append(FunctionArgument(
                externalLabel: identifierString(tokens[externalLabelIndex]),
                internalLabel: identifierString(tokens[internalLabelIndex]),
                externalLabelIndex: hasExplicitExternalLabel ? externalLabelIndex : nil,
                internalLabelIndex: internalLabelIndex,
                type: type
            ))
        }

        return arguments
    }

    func parseFunctionDeclarationEffectsClause(at startIndex: Int) -> (effects: Set<String>, range: ClosedRange<Int>)? {
        // Parse optional `async`, `throws`, `rethrows`, and typed throws `throws(...)` effects.
        var effects = Set<String>()
        var effectsRange: ClosedRange<Int>?

        var currentIndex = startIndex
        let firstIndexAfterArguments = index(of: .nonSpaceOrCommentOrLinebreak, after: currentIndex)
        while let effectIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: currentIndex),
              let effect = token(at: effectIndex)?.string,
              ["async", "throws", "rethrows"].contains(effect),
              let firstIndexAfterArguments
        {
            // `throws` can optionally be typed throws with a `(Type)` component
            if effect == "throws",
               let startOfTypedThrows = index(of: .nonSpaceOrCommentOrLinebreak, after: effectIndex),
               tokens[startOfTypedThrows] == .startOfScope("("),
               let endOfTypedThrows = endOfScope(at: startOfTypedThrows)
            {
                effects.insert(tokens[effectIndex ... endOfTypedThrows].string)
                effectsRange = firstIndexAfterArguments ... endOfTypedThrows
                currentIndex = endOfTypedThrows
                continue
            }

            // If an `async` keyword is immediately followed by `let` on the same line, this is probably an `async let` property.
            // It's possible an `async` keyword to be followed by a `let` keyword without being an `async let` property
            // (e.g. if the attached function doesn't have a body), so this seems fundamentally ambiguous in the grammar.
            if effect == "async",
               let nextToken = index(of: .nonSpaceOrComment, after: effectIndex),
               tokens[nextToken] == .keyword("let")
            {
                break
            }

            effects.insert(effect)
            effectsRange = firstIndexAfterArguments ... effectIndex
            currentIndex = effectIndex
        }

        if let effectsRange {
            return (effects: effects, range: effectsRange)
        } else {
            return nil
        }
    }

    func parseFunctionDeclarationReturnClause(at startIndex: Int) -> (returnOperatorIndex: Int, returnType: (name: String, range: ClosedRange<Int>))? {
        guard let returnIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: startIndex),
              tokens[returnIndex] == .operator("->", .infix),
              let indexAfterReturnOperator = index(of: .nonSpaceOrCommentOrLinebreak, after: returnIndex),
              let parsedReturnType = parseType(at: indexAfterReturnOperator) else { return nil }

        return (returnOperatorIndex: returnIndex, returnType: parsedReturnType)
    }

    struct FunctionCallArgument {
        /// The label of the argument. `nil` if unlabeled.
        let label: String?
        /// The index of the optional label
        let labelIndex: Int?
        /// The value of the argument, including any leading or trailing whitespace / comments.
        let value: String
        /// The index of the value
        let valueRange: ClosedRange<Int>
    }

    /// Parses the parameter labels of the function call with its `(` start of scope
    /// token at the given index.
    func parseFunctionCallArguments(startOfScope: Int) -> [FunctionCallArgument] {
        assert(tokens[startOfScope] == .startOfScope("("))
        guard let endOfScope = endOfScope(at: startOfScope),
              index(of: .nonSpaceOrCommentOrLinebreak, after: startOfScope) != endOfScope
        else { return [] }

        var argumentLabels: [FunctionCallArgument] = []

        var currentIndex = startOfScope
        while currentIndex < endOfScope {
            let endOfPreviousArgument = currentIndex
            let endOfCurrentArgument = index(of: .delimiter(","), in: endOfPreviousArgument + 1 ..< endOfScope) ?? endOfScope

            if let colonIndex = index(of: .delimiter(":"), in: (endOfPreviousArgument + 1) ..< endOfCurrentArgument),
               let argumentLabelIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: colonIndex),
               tokens[argumentLabelIndex].isIdentifier
            {
                argumentLabels.append(FunctionCallArgument(
                    label: tokens[argumentLabelIndex].string,
                    labelIndex: argumentLabelIndex,
                    value: tokens[colonIndex + 1 ..< endOfCurrentArgument].string,
                    valueRange: ClosedRange(colonIndex + 1 ..< endOfCurrentArgument)
                ))
            } else {
                argumentLabels.append(FunctionCallArgument(
                    label: nil,
                    labelIndex: nil,
                    value: tokens[endOfPreviousArgument + 1 ..< endOfCurrentArgument].string,
                    valueRange: ClosedRange(endOfPreviousArgument + 1 ..< endOfCurrentArgument)
                ))
            }

            if endOfCurrentArgument >= endOfScope {
                break
            } else {
                currentIndex = endOfCurrentArgument
            }
        }

        return argumentLabels
    }

    /// Parses the parameter labels of the tuple type or value with its `(` start of scope
    /// token at the given index.
    func parseTupleArguments(startOfScope: Int) -> [FunctionCallArgument] {
        parseFunctionCallArguments(startOfScope: startOfScope)
    }

    /// Parses the list of conformances on this type, starting at
    /// the index of the type keyword (`struct`, `class`, `extension`, etc).
    func parseConformancesOfType(atKeywordIndex keywordIndex: Int) -> [(conformance: String, index: Int)] {
        assert(Token.swiftTypeKeywords.contains(tokens[keywordIndex].string))

        guard let startOfType = index(of: .nonSpaceOrCommentOrLinebreak, after: keywordIndex),
              let typeName = parseType(at: startOfType),
              let indexAfterType = index(of: .nonSpaceOrCommentOrLinebreak, after: typeName.range.upperBound),
              tokens[indexAfterType] == .delimiter(":"),
              let firstConformanceIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: indexAfterType)
        else { return [] }

        var conformances = [(conformance: String, index: Int)]()
        var nextConformanceIndex = firstConformanceIndex

        while let type = parseType(at: nextConformanceIndex) {
            conformances.append((conformance: type.name, index: nextConformanceIndex))

            if let nextTokenIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: type.range.upperBound) {
                nextConformanceIndex = nextTokenIndex

                // Skip over any comma tokens that separate conformances.
                // If we find something other than a comma, like a `where` or `{`,
                // then we reached the end of the conformance list.
                guard tokens[nextTokenIndex] == .delimiter(","),
                      let followingConformanceIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: nextTokenIndex)
                else {
                    return conformances
                }

                nextConformanceIndex = followingConformanceIndex
            }
        }

        return conformances
    }

    /// Removes the protocol conformance at the given index.
    /// e.g. can remove `Foo` from `Type: Foo, Bar {` (becomes `Type: Bar {`).
    func removeConformance(at conformanceIndex: Int) {
        guard let previousToken = index(of: .nonSpaceOrCommentOrLinebreak, before: conformanceIndex),
              let nextToken = index(of: .nonSpaceOrCommentOrLinebreak, after: conformanceIndex)
        else { return }

        // The first conformance will be preceded by a colon.
        // Every conformance but the last one will be followed by a comma.
        //  - for example: `Type: Foo, Bar, Baaz {`
        let isFirstConformance = tokens[previousToken] == .delimiter(":")
        let isLastConformance = tokens[nextToken] != .delimiter(",")
        let isOnlyConformance = isFirstConformance && isLastConformance

        if isLastConformance || isOnlyConformance {
            removeTokens(in: previousToken ... conformanceIndex)
        } else {
            // When changing `Foo, Bar` to just `Bar`, also remove the space between them
            if token(at: nextToken + 1)?.isSpace == true {
                removeTokens(in: conformanceIndex ... (nextToken + 1))
            } else {
                removeTokens(in: conformanceIndex ... (nextToken + 1))
            }
        }
    }

    /// The explicit `Visibility` of the `Declaration` with its keyword at the given index
    func declarationVisibility(keywordIndex: Int) -> Visibility? {
        // Search for a visibility keyword in the tokens before the primary keyword,
        // making sure we exclude groups like private(set).
        var searchIndex = startOfModifiers(at: keywordIndex, includingAttributes: false)
        while searchIndex < keywordIndex {
            if let visibility = Visibility(rawValue: tokens[searchIndex].string),
               next(.nonSpaceOrComment, after: searchIndex) != .startOfScope("(")
            {
                return visibility
            }

            searchIndex += 1
        }

        return nil
    }

    /// Adds the given visibility keyword to the given declaration,
    /// replacing any existing visibility keyword.
    func addDeclarationVisibility(_ visibilityKeyword: Visibility, declarationKeywordIndex: Int) {
        var declarationKeywordIndex = declarationKeywordIndex

        if let existingVisibility = declarationVisibility(keywordIndex: declarationKeywordIndex),
           let visibilityKeywordIndex = indexOfModifier(existingVisibility.rawValue, forDeclarationAt: declarationKeywordIndex)
        {
            removeToken(at: visibilityKeywordIndex)
            declarationKeywordIndex -= 1

            while token(at: visibilityKeywordIndex)?.isSpace == true {
                removeToken(at: visibilityKeywordIndex)
                declarationKeywordIndex -= 1
            }
        }

        insert(
            [.keyword(visibilityKeyword.rawValue), .space(" ")],
            at: startOfModifiers(at: declarationKeywordIndex, includingAttributes: false)
        )
    }

    /// Removes the given visibility keyword from the given declaration
    func removeDeclarationVisibility(_ visibilityKeyword: Visibility, declarationKeywordIndex: Int) {
        guard let visibilityKeywordIndex = indexOfModifier(visibilityKeyword.rawValue, forDeclarationAt: declarationKeywordIndex) else { return }

        removeToken(at: visibilityKeywordIndex)

        while token(at: visibilityKeywordIndex)?.isSpace == true {
            removeToken(at: visibilityKeywordIndex)
        }
    }

    /// The name of the declaration defined at the given index
    func declarationName(keywordIndex: Int) -> String? {
        // Conditional compilation blocks don't have a "name"
        guard tokens[keywordIndex].string != "#if" else { return nil }

        guard let nameIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: keywordIndex) else {
            return nil
        }

        // An extension can refer to complicated types like `Foo.Bar`, `[Foo]`, `Collection<Foo>`, etc.
        // Every other declaration type just uses a simple identifier.
        if tokens[keywordIndex].string == "extension" {
            return parseType(at: nameIndex)?.name
        } else {
            return tokens[nameIndex].string
        }
    }

    /// Represents a condition in a guard or if statement
    enum ConditionalStatementElement {
        // A boolean expression like `foo == bar`
        case booleanExpression(range: ClosedRange<Int>)
        // An optional binding / unwrap condition like `let foo` or `let foo = foo`
        case optionalBinding(range: ClosedRange<Int>, property: PropertyDeclaration)
        /// A pattern matching condition like `case .foo(let bar) = baaz`
        case patternMatching(range: ClosedRange<Int>)

        var range: ClosedRange<Int> {
            switch self {
            case let .booleanExpression(range), let .optionalBinding(range, _), let .patternMatching(range):
                return range
            }
        }
    }

    /// Parse conditions in a guard or if statement
    func parseConditionalStatement(at guardOrIfIndex: Int) -> [ConditionalStatementElement] {
        assert(tokens[guardOrIfIndex] == .keyword("guard") || tokens[guardOrIfIndex] == .keyword("if"))

        // Find the else keyword (or opening brace for if)
        var endIndex: Int?

        if let braceIndex = index(of: .startOfScope("{"), after: guardOrIfIndex) {
            if tokens[guardOrIfIndex] == .keyword("if") {
                // For if statements without else
                endIndex = braceIndex
            } else if let prevTokenIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: braceIndex),
                      tokens[prevTokenIndex] == .keyword("else")
            {
                // For guard statements with else
                endIndex = prevTokenIndex
            }
        }

        guard let endIndex else { return [] }

        var conditions: [ConditionalStatementElement] = []
        var currentPos = guardOrIfIndex + 1

        while currentPos < endIndex {
            // Skip whitespace and comments
            guard let conditionStart = index(of: .nonSpaceOrCommentOrLinebreak, after: currentPos - 1),
                  conditionStart < endIndex
            else {
                break
            }

            let conditionEnd: Int
            if let commaIndex = index(of: .delimiter(","), after: conditionStart),
               commaIndex < endIndex
            {
                conditionEnd = index(of: .nonSpaceOrCommentOrLinebreak, before: commaIndex) ?? conditionStart
            } else {
                conditionEnd = index(of: .nonSpaceOrCommentOrLinebreak, before: endIndex) ?? conditionStart
            }

            let element: ConditionalStatementElement
            if tokens[conditionStart] == .keyword("case") {
                element = .patternMatching(range: conditionStart ... conditionEnd)
            } else if tokens[conditionStart] == .keyword("let") || tokens[conditionStart] == .keyword("var") {
                guard let property = parsePropertyDeclaration(atIntroducerIndex: conditionStart) else {
                    return []
                }

                element = .optionalBinding(range: conditionStart ... conditionEnd, property: property)
            } else {
                element = .booleanExpression(range: conditionStart ... conditionEnd)
            }

            conditions.append(element)

            // Find next condition (after comma)
            if let commaIndex = index(of: .delimiter(","), after: conditionEnd),
               commaIndex < endIndex
            {
                currentPos = commaIndex + 1
            } else {
                break
            }
        }

        return conditions
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

extension String {
    /// Whether or not this type name is a tuple.
    /// Assumes this string represents a valid type.
    var isTupleType: Bool {
        let formatter = Formatter(tokenize(self))

        // Tuple types start and end with parens and have a comma-separated list of elements.
        // (There are no single-element tuples).
        guard let openParen = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: -1),
              formatter.tokens[openParen] == .startOfScope("("),
              let closingParen = formatter.endOfScope(at: openParen),
              openParen + 1 != closingParen
        else { return false }

        // The tuple could be optional, but otherwise the closing paren should be the last token.
        let tokenAfterClosingParen = formatter.next(.nonSpaceOrCommentOrLinebreak, after: closingParen)
        guard tokenAfterClosingParen == nil || tokenAfterClosingParen == .operator("?", .postfix) else {
            return false
        }

        let hasCommaInParens = formatter.index(of: .delimiter(","), in: (openParen + 1) ..< closingParen) != nil
        return hasCommaInParens
    }
}
