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
    func startOfLine(at index: Int) -> Int {
        var index = index
        while let token = token(at: index - 1) {
            if case .linebreak = token {
                break
            }
            index -= 1
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

    /// Whether or not the two indicies represent tokens on the same line
    func onSameLine(_ lhs: Int, _ rhs: Int) -> Bool {
        return startOfLine(at: lhs) == startOfLine(at: rhs)
    }

    /// Returns the space at the start of the line containing the specified index
    func indentForLine(at index: Int) -> String {
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
        return lineLength(upTo: endOfLine(at: index))
    }

    /// Returns the length (in characters) up to (but not including) the specified token index
    func lineLength(upTo index: Int) -> Int {
        return lineLength(from: startOfLine(at: index), upTo: index)
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
        return last(.startOfScope, before: index)
    }

    /// Returns the index of the ending token for the current scope
    // TODO: should this return the closing `}` for `switch { ...` instead of nested `case`?
    func endOfScope(at index: Int) -> Int? {
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

    /// Returns the end of the expression at the specified index, optionally stopping at any of the specified tokens
    func endOfExpression(at index: Int, upTo delimiters: [Token]) -> Int? {
        var lastIndex = index
        var index: Int? = index
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
            case .startOfScope where wasOperator,
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

extension Formatter {
    func modifiersForType(at index: Int, contains: (Int, String) -> Bool) -> Bool {
        let allModifiers = _FormatRules.allModifiers
        var index = index
        while var prevIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, before: index) {
            let token = tokens[prevIndex]
            switch token {
            case let .keyword(name), let .identifier(name):
                if !allModifiers.contains(name), !name.hasPrefix("@") {
                    return false
                }
                if contains(prevIndex, name) {
                    return true
                }
            case .endOfScope(")"):
                guard let startIndex = self.index(of: .startOfScope("("), before: prevIndex),
                      last(.nonSpaceOrCommentOrLinebreak, before: startIndex, if: {
                          $0.isAttribute || _FormatRules.aclModifiers.contains($0.string)
                      }) != nil
                else {
                    return false
                }
                prevIndex = startIndex
            default:
                return false
            }
            index = prevIndex
        }
        return false
    }

    func modifiersForType(at index: Int, contains: String) -> Bool {
        return modifiersForType(at: index, contains: { $1 == contains })
    }

    // first index of modifier list
    func startOfModifiers(at index: Int) -> Int {
        var startIndex = index
        _ = modifiersForType(at: index, contains: { i, _ in
            startIndex = i
            return false
        })
        return startIndex
    }

    // gather declared variable names, starting at index after let/var keyword
    func processDeclaredVariables(at index: inout Int, names: inout Set<String>) {
        processDeclaredVariables(at: &index, names: &names, removeSelf: false)
    }

    // gather declared variable names, starting at index after let/var keyword
    func processDeclaredVariables(at index: inout Int, names: inout Set<String>, removeSelf: Bool) {
        let isConditional = isConditionalStatement(at: index)
        var declarationIndex: Int? = -1
        var scopeIndexStack = [Int]()
        while let token = self.token(at: index) {
            switch token {
            case .identifier where
                last(.nonSpaceOrCommentOrLinebreak, before: index)?.isOperator(".") == false:
                let name = token.unescaped()
                if name != "_", declarationIndex != nil || !isConditional {
                    names.insert(name)
                }
                inner: while let nextIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, after: index) {
                    switch tokens[nextIndex] {
                    case .keyword("as"), .keyword("is"), .keyword("try"):
                        break
                    case .startOfScope("<"), .startOfScope("["), .startOfScope("("),
                         .startOfScope where token.isStringDelimiter:
                        guard let endIndex = endOfScope(at: nextIndex) else {
                            return fatalError("Expected end of scope", at: nextIndex)
                        }
                        if removeSelf, isEnabled {
                            var i = endIndex - 1
                            while i > nextIndex {
                                switch tokens[i] {
                                case .endOfScope("}"):
                                    i = self.index(of: .startOfScope("{"), before: i) ?? i
                                case .identifier("self"):
                                    _ = self.removeSelf(at: i, localNames: names)
                                default:
                                    break
                                }
                                i -= 1
                            }
                            index = endOfScope(at: nextIndex)!
                        } else {
                            index = endIndex
                        }
                        continue
                    case .keyword, .startOfScope("{"), .endOfScope("}"), .startOfScope(":"):
                        return
                    case .endOfScope(")"):
                        let scopeIndex = scopeIndexStack.popLast() ?? -1
                        if let d = declarationIndex, d > scopeIndex {
                            declarationIndex = nil
                        }
                    case .delimiter(","):
                        if let d = declarationIndex, d > scopeIndexStack.last ?? -1 {
                            declarationIndex = nil
                        }
                        index = nextIndex
                        break inner
                    case .identifier("self") where removeSelf && isEnabled:
                        _ = self.removeSelf(at: nextIndex, localNames: names)
                    default:
                        break
                    }
                    index = nextIndex
                }
            case .keyword("let"), .keyword("var"):
                declarationIndex = index
            case .startOfScope("("):
                scopeIndexStack.append(index)
            case .startOfScope("{"):
                guard isStartOfClosure(at: index), let nextIndex = endOfScope(at: index) else {
                    index -= 1
                    return
                }
                index = nextIndex
            default:
                break
            }
            index += 1
        }
    }

    /// Returns true if token is inside the return type of a function or subscript
    func isInReturnType(at i: Int) -> Bool {
        return startOfReturnType(at: i) != nil
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
        assert(tokens[i] == .startOfScope("{"))

        if isConditionalStatement(at: i) {
            if let endIndex = endOfScope(at: i),
               next(.nonSpaceOrComment, after: endIndex) == .startOfScope("(") ||
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
             .operator(_, .infix), .operator(_, .prefix), .delimiter,
             .keyword("return"), .keyword("in"), .keyword("where"):
            return true
        case .operator(_, .none),
             .keyword("deinit"), .keyword("catch"), .keyword("else"),
             .keyword("repeat"), .keyword("throws"), .keyword("rethrows"):
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
            case .operator("->", .infix), .keyword("init"),
                 .keyword("subscript"), .endOfScope(">"):
                return false
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
        case .endOfScope where tokens[prevIndex].isStringDelimiter, .identifier, .number:
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
            case "func", "subscript", "class", "struct", "protocol", "enum", "extension", "throws":
                return false
            default:
                return true
            }
        case .operator("?", .postfix), .operator("!", .postfix),
             .keyword, .endOfScope("]"), .endOfScope(">"):
            return false
        default:
            return true
        }
    }

    func isInClosureArguments(at i: Int) -> Bool {
        var i = i
        while let token = self.token(at: i) {
            switch token {
            case .keyword("in"):
                guard let scopeIndex = index(of: .startOfScope, before: i) else {
                    return false
                }
                return isStartOfClosure(at: scopeIndex)
            case .startOfScope("("), .startOfScope("["), .startOfScope("<"),
                 .endOfScope(")"), .endOfScope("]"), .endOfScope(">"):
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
            ["get", "set", "willSet", "didSet"].contains(token(at: i)?.string ?? ""),
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

    func isConditionalStatement(at i: Int) -> Bool {
        return startOfConditionalStatement(at: i) != nil
    }

    func startOfConditionalStatement(at i: Int) -> Int? {
        guard let index = indexOfLastSignificantKeyword(at: i) else {
            return nil
        }

        func isAfterBrace(_ index: Int) -> Bool {
            guard let braceIndex = lastIndex(of: .endOfScope("}"), in: index ..< i) else {
                return false
            }
            return self.index(of: .nonSpaceOrCommentOrLinebreak, in: braceIndex + 1 ..< i) != nil
        }

        switch tokens[index].string {
        case "let", "var":
            guard let prevIndex = self
                .index(of: .nonSpaceOrCommentOrLinebreak, before: index)
            else {
                return nil
            }
            switch tokens[prevIndex] {
            case .delimiter(","):
                return prevIndex
            case let .keyword(name) where
                ["if", "guard", "while", "for", "case", "catch"].contains(name):
                return isAfterBrace(prevIndex) ? nil : prevIndex
            default:
                return nil
            }
        case "if", "guard", "while", "for", "case", "where", "switch":
            return isAfterBrace(index) ? nil : index
        default:
            return nil
        }
    }

    func lastSignificantKeyword(at i: Int, excluding: [String] = []) -> String? {
        guard let index = indexOfLastSignificantKeyword(at: i, excluding: excluding),
              case let .keyword(keyword) = tokens[index]
        else {
            return nil
        }
        return keyword
    }

    func indexOfLastSignificantKeyword(at i: Int, excluding: [String] = []) -> Int? {
        guard let token = token(at: i),
              let index = token.isKeyword ? i : index(of: .keyword, before: i),
              case let .keyword(keyword) = tokens[index]
        else {
            return nil
        }
        switch keyword {
        case let name where
            name.hasPrefix("#") || name.hasPrefix("@") || excluding.contains(name):
            fallthrough
        case "in", "as", "is", "try":
            return indexOfLastSignificantKeyword(at: index - 1, excluding: excluding)
        default:
            guard let braceIndex = self.index(of: .startOfScope("{"), in: index ..< i),
                  let endIndex = endOfScope(at: braceIndex),
                  next(.nonSpaceOrComment, after: endIndex) != .startOfScope("(")
            else {
                return index
            }
            if keyword == "if" || ["var", "let"].contains(keyword) &&
                last(.nonSpaceOrCommentOrLinebreak, before: index) == .keyword("if"),
                self.index(of: .startOfScope("{"), in: endIndex ..< i) == nil
            {
                return index
            }
            return nil
        }
    }

    func isAttribute(at i: Int) -> Bool {
        return startOfAttribute(at: i) != nil
    }

    func startOfAttribute(at i: Int) -> Int? {
        switch tokens[i] {
        case let token where token.isAttribute:
            return i
        case .endOfScope(")"):
            guard let openParenIndex = index(of: .startOfScope("("), before: i),
                  let prevTokenIndex = index(of: .nonSpaceOrComment, before: openParenIndex),
                  tokens[prevTokenIndex].isAttribute
            else {
                return nil
            }
            return prevTokenIndex
        default:
            return nil
        }
    }

    // Determine if next line after this token should be indented
    func isEndOfStatement(at i: Int, in scope: Token? = nil) -> Bool {
        guard let token = self.token(at: i) else { return true }
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
                 "while", "associatedtype", "inout":
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

    // Determine if line starting with this token should be indented
    func isStartOfStatement(at i: Int, in scope: Token? = nil) -> Bool {
        guard let token = self.token(at: i) else { return true }
        switch token {
        case let .keyword(string) where [ // TODO: handle "in"
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
        case .delimiter(","):
            guard let scope = scope ?? currentScope(at: i) else {
                return false
            }
            // For arrays, dictionaries, cases, or argument lists, we already indent
            return ["<", "[", "(", "case"].contains(scope.string)
        case .delimiter, .operator(_, .infix), .operator(_, .postfix):
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
               || indentForLine(at: startIndex) == indentForLine(at: prevIndex)
            {
                return false
            }
            return true
        default:
            return true
        }
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

    // Detect if currently inside a String literal
    func isStringLiteral(at index: Int) -> Bool {
        for token in tokens[..<index].reversed() {
            switch token {
            case .stringBody:
                return true
            case .endOfScope where token.isStringDelimiter, .linebreak:
                return false
            default:
                continue
            }
        }
        return false
    }

    // Detect if code is inside a ViewBuilder
    func isInViewBuilder(at i: Int) -> Bool {
        var i = i
        while let startIndex = index(of: .startOfScope("{"), before: i) {
            guard let prevIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: startIndex) else {
                return false
            }
            if tokens[prevIndex] == .identifier("View"),
               let prevToken = last(.nonSpaceOrCommentOrLinebreak, before: prevIndex),
               [.delimiter(":"), .identifier("some")].contains(prevToken)
            {
                return true
            }
            i = prevIndex
        }
        return false
    }

    // Detect if identifier requires backtick escaping
    func backticksRequired(at i: Int, ignoreLeadingDot: Bool = false) -> Bool {
        guard let token = token(at: i), token.isIdentifier else {
            return false
        }
        let unescaped = token.unescaped()
        if !unescaped.isSwiftKeyword {
            switch unescaped {
            case "super", "self", "nil", "true", "false":
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
            case "get", "set", "willSet", "didSet":
                return isAccessorKeyword(at: i, checkKeyword: false)
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

    // Is token at argument position
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

    func isParameterList(at i: Int) -> Bool {
        assert([.startOfScope("("), .startOfScope("<")].contains(tokens[i]))
        if let endIndex = endOfScope(at: i),
           let nextToken = next(.nonSpaceOrCommentOrLinebreak, after: endIndex),
           [.operator("->", .infix), .keyword("throws"), .keyword("rethrows")].contains(nextToken)
        {
            return true
        }
        if let funcIndex = index(of: .keyword, before: i, if: {
            [.keyword("func"), .keyword("init"), .keyword("subscript")].contains($0)
        }), lastIndex(of: .endOfScope("}"), in: funcIndex ..< i) == nil {
            // Is parameters at start of function
            return true
        }
        return false
    }

    func isEnumCase(at i: Int) -> Bool {
        assert(tokens[i] == .keyword("case"))
        if last(.keyword, before: i) == .keyword("case") {
            return true
        }
        return last(.nonSpaceOrCommentOrLinebreak, before: i) == .startOfScope("{")
    }

    struct ImportRange: Comparable {
        var module: String
        var range: Range<Int>
        var isTestable: Bool

        static func < (lhs: ImportRange, rhs: ImportRange) -> Bool {
            let la = lhs.module.lowercased()
            let lb = rhs.module.lowercased()
            return la == lb ? lhs.module < rhs.module : la < lb
        }
    }

    // Shared import rules implementation
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
            var previousKeywordIndex = index(of: .keyword, before: i)
            while let previousIndex = previousKeywordIndex {
                var nextStart: Int? // workaround for Swift Linux bug
                if tokens[previousIndex].isAttribute {
                    if previousIndex < startIndex {
                        nextStart = index(of: .linebreak, before: previousIndex) ?? 0
                    }
                    previousKeywordIndex = index(of: .keyword, before: previousIndex)
                    startIndex = nextStart ?? startIndex
                } else if previousIndex >= startIndex {
                    // Can't handle another keyword on same line as import
                    return
                } else {
                    break
                }
            }
            // Gather comments
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
                    isTestable: tokens[range].contains(.keyword("@testable"))
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

    enum Declaration: Equatable {
        /// A type-like declaration with body of additional declarations (`class`, `struct`, etc)
        indirect case type(kind: String, open: [Token], body: [Declaration], close: [Token])

        /// A simple declaration (like a property or function)
        case declaration(kind: String, tokens: [Token])

        /// A #if ... #endif conditional compilation block with a body of additional declarations
        indirect case conditionalCompilation(open: [Token], body: [Declaration], close: [Token])

        /// The tokens in this declaration
        var tokens: [Token] {
            switch self {
            case let .declaration(_, tokens):
                return tokens
            case let .type(_, openTokens, bodyDeclarations, closeTokens),
                 let .conditionalCompilation(openTokens, bodyDeclarations, closeTokens):
                return openTokens + bodyDeclarations.flatMap { $0.tokens } + closeTokens
            }
        }

        /// The opening tokens of the declaration (before the body)
        var openTokens: [Token] {
            switch self {
            case .declaration:
                return []
            case let .type(_, open, _, _),
                 let .conditionalCompilation(open, _, _):
                return open
            }
        }

        /// The body of this declaration, if applicable
        var body: [Declaration]? {
            switch self {
            case .declaration:
                return nil
            case let .type(_, _, body, _),
                 let .conditionalCompilation(_, body, _):
                return body
            }
        }

        /// The closing tokens of the declaration (after the body)
        var closeTokens: [Token] {
            switch self {
            case .declaration:
                return []
            case let .type(_, _, _, close),
                 let .conditionalCompilation(_, _, close):
                return close
            }
        }

        /// The keyword that determines the specific type of declaration that this is
        /// (`class`, `func`, `let`, `var`, etc.)
        var keyword: String {
            switch self {
            case let .declaration(kind, _),
                 let .type(kind, _, _, _):
                return kind
            case .conditionalCompilation:
                return "#if"
            }
        }

        /// The name of this type or variable
        var name: String? {
            let openingFormatter = Formatter(openTokens)

            guard let keywordIndex = openingFormatter.index(after: -1, where: {
                $0.string == keyword
            }) else { return nil }

            guard let typeNameIndex = openingFormatter.index(of: .identifier, after: keywordIndex) else {
                return nil
            }

            return openingFormatter.fullyQualifiedName(startingAt: typeNameIndex).name
        }
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

    // get type of declaration starting at index of declaration keyword
    func declarationType(at index: Int) -> String? {
        guard let token = self.token(at: index), token.isDeclarationTypeKeyword,
              case let .keyword(keyword) = token
        else {
            return nil
        }
        if keyword == "class",
           let nextToken = next(.nonSpaceOrCommentOrLinebreak, after: index),
           nextToken.isDeclarationTypeKeyword, case let .keyword(keyword) = nextToken
        {
            return keyword
        }
        return keyword
    }

    // gather declared name(s), starting at index of declaration keyword
    func namesInDeclaration(at index: Int) -> Set<String>? {
        guard case let .keyword(keyword)? = token(at: index) else {
            return nil
        }
        switch keyword {
        case "let", "var":
            var index = index + 1
            var names = Set<String>()
            processDeclaredVariables(at: &index, names: &names, removeSelf: false)
            return names
        case "func", "class", "struct", "enum":
            guard let name = next(.identifier, after: index) else {
                return nil
            }
            return [name.string]
        default:
            return nil
        }
    }

    func parseDeclarations() -> [Declaration] {
        let parser = Formatter(tokens)
        var declarations = [Declaration]()

        while !parser.tokens.isEmpty {
            let startOfDeclaration = 0
            var endOfDeclaration: Int?

            // Determine what type of declaration this is
            let declarationTypeKeywordIndex: Int?
            let declarationKeyword: String?

            if let firstDeclarationTypeKeywordIndex = parser.index(
                after: startOfDeclaration - 1,
                where: { $0.isDeclarationTypeKeyword || $0 == .startOfScope("#if") }
            ) {
                // Most declarations will include exactly one token that `isDeclarationTypeKeyword` in
                //  - `class func` methods will have two (and the first one will be incorrect!)
                //  - Symbol imports (like `import class Module.Type`) will have two,
                //    but the first one will be correct, so we don't make any corrections right here.
                if parser.tokens[firstDeclarationTypeKeywordIndex].string != "class" {
                    declarationTypeKeywordIndex = firstDeclarationTypeKeywordIndex
                    declarationKeyword = parser.tokens[firstDeclarationTypeKeywordIndex].string
                }

                // For `class` declarations, we have to look at the _last_ token that
                // `isDeclarationTypeKeyword` in the declaration's opening sequence (up until the `{`).
                //  - This makes sure that we correctly identify `class func` declarations as being functions.
                else if let endOfDeclarationOpeningSequence = parser.index(after: -1, where: { $0 == .startOfScope("{") }),
                    let lastDeclarationTypeKeywordIndex = parser.lastIndex(
                        in: 0 ..< endOfDeclarationOpeningSequence,
                        where: { $0.isDeclarationTypeKeyword }
                    )
                {
                    declarationTypeKeywordIndex = lastDeclarationTypeKeywordIndex
                    declarationKeyword = parser.tokens[lastDeclarationTypeKeywordIndex].string
                } else {
                    declarationTypeKeywordIndex = nil
                    declarationKeyword = nil
                }
            } else {
                declarationTypeKeywordIndex = nil
                declarationKeyword = nil
            }

            if let declarationTypeKeywordIndex = declarationTypeKeywordIndex {
                // Search for the next declaration so we know where this declaration ends.
                var nextDeclarationKeywordIndex: Int?
                var searchIndex = declarationTypeKeywordIndex + 1

                // For conditional compilation blocks, the `declarationKeyword` _is_ the `startOfScope`
                // so we can immediately skip to the corresponding #endif
                if declarationKeyword == "#if",
                   let endOfConditionalCompilationScope = parser.endOfScope(at: searchIndex)
                {
                    searchIndex = endOfConditionalCompilationScope
                }

                // Symbol imports (like `import class Module.Type`) will have an extra `isDeclarationTypeKeyword`
                // immediately following their `declarationKeyword`, so we need to skip them.
                if declarationKeyword == "import",
                   let symbolTypeKeywordIndex = parser.index(of: .nonSpaceOrComment, after: declarationTypeKeywordIndex),
                   parser.tokens[symbolTypeKeywordIndex].isDeclarationTypeKeyword
                {
                    searchIndex = symbolTypeKeywordIndex + 1
                }

                while searchIndex < parser.tokens.count, nextDeclarationKeywordIndex == nil {
                    // If we encounter a `startOfScope`, we have to skip to the end of the scope.
                    // This accounts for things like function bodies, etc.
                    //  - Comment marker tokens (e.g. `//`) are `startOfScope` tokens,
                    //    but they don't have a corresponding `endOfScope` so we can't skip through them.
                    //  - `#if` tokens are `startOfScope`, but immediately represent the start of a new
                    //    conditional compilation declaration so we can't skip through them.
                    if parser.tokens[searchIndex].isStartOfScope,
                       !parser.tokens[searchIndex].isComment,
                       parser.tokens[searchIndex].string != "#if",
                       let endOfScope = parser.endOfScope(at: searchIndex)
                    {
                        searchIndex = endOfScope + 1
                    } else if parser.tokens[searchIndex].isDeclarationTypeKeyword
                        || parser.tokens[searchIndex].string == "#if"
                    {
                        nextDeclarationKeywordIndex = searchIndex
                    } else {
                        searchIndex += 1
                    }
                }

                if let nextDeclarationKeywordIndex = nextDeclarationKeywordIndex {
                    // Search backward from the next declaration's type keyword
                    // to find exactly where that declaration begins.
                    var startOfNextDeclaration: Int?
                    searchIndex = nextDeclarationKeywordIndex

                    while searchIndex > declarationTypeKeywordIndex, startOfNextDeclaration == nil {
                        if parser.tokens[searchIndex - 1].canPrecedeDeclarationTypeKeyword {
                            searchIndex -= 1
                        }

                        // If we encounter a closing paren, we have to skip to the beginning of the scope.
                        // This accounts for things like attribute bodies, etc.
                        else if parser.tokens[searchIndex - 1] == .endOfScope(")") {
                            let encounteredEndOfScope = searchIndex - 1
                            var startOfScope: Int?
                            searchIndex -= 1

                            while searchIndex > declarationTypeKeywordIndex, startOfScope == nil {
                                if parser.tokens[searchIndex].isStartOfScope,
                                   parser.endOfScope(at: searchIndex) == encounteredEndOfScope
                                {
                                    startOfScope = searchIndex
                                    // Confirm whether or not this scope should be grouped with the
                                    // current or previous declaration:
                                    if let previousNonwhitespace = parser.index(
                                        of: .nonSpaceOrCommentOrLinebreak,
                                        before: searchIndex
                                    ), !parser.tokens[previousNonwhitespace].canPrecedeDeclarationTypeKeyword {
                                        startOfNextDeclaration = encounteredEndOfScope + 1
                                    }

                                } else {
                                    searchIndex -= 1
                                }
                            }

                        } else {
                            startOfNextDeclaration = searchIndex
                        }
                    }

                    // Now that we know where the next declaration starts,
                    // we know where this declaration ends.
                    if let startOfNextDeclaration = startOfNextDeclaration {
                        endOfDeclaration = startOfNextDeclaration - 1
                    }
                }
            }

            // Only separate declarations by line (never break up individual lines)
            endOfDeclaration = endOfDeclaration.flatMap {
                parser.endOfLine(at: $0)
            }

            // Prefer keeping linebreaks at the end of a declaration's tokens,
            // instead of the start of the next delaration's tokens
            while let linebreakSearchIndex = endOfDeclaration,
                  parser.token(at: linebreakSearchIndex + 1)?.isLinebreak == true
            {
                endOfDeclaration = linebreakSearchIndex + 1
            }

            let declarationRange = startOfDeclaration ... min(endOfDeclaration ?? .max, parser.tokens.count - 1)
            let declaration = Array(parser.tokens[declarationRange])
            parser.removeTokens(in: declarationRange)

            declarations.append(.declaration(kind: declarationKeyword ?? "unknown", tokens: declaration))
        }

        return declarations.map { declaration in
            let declarationParser = Formatter(declaration.tokens)

            /// Parses this declaration into a body of declarations separate from the start and end tokens
            func parseBody(in bodyRange: ClosedRange<Int>) -> (start: [Token], body: [Declaration], end: [Token]) {
                var startTokens = declarationParser.tokens[...bodyRange.lowerBound]
                var bodyTokens = declarationParser.tokens[bodyRange.lowerBound + 1 ..< bodyRange.upperBound]
                var endTokens = declarationParser.tokens[bodyRange.upperBound...]

                // Move the leading newlines from the `body` into the `start` tokens
                // so the first body token is the start of the first declaration
                while bodyTokens.first?.isLinebreak == true {
                    startTokens.append(bodyTokens.removeFirst())
                }

                // Move the closing brace's indentation token from the `body` into the `end` tokens
                if bodyTokens.last?.isSpace == true {
                    endTokens.insert(bodyTokens.removeLast(), at: endTokens.startIndex)
                }

                // Parse the inner body declarations of the type
                let bodyDeclarations = Formatter(Array(bodyTokens)).parseDeclarations()

                return (Array(startTokens), bodyDeclarations, Array(endTokens))
            }

            // If this declaration represents a type, we need to parse its inner declarations as well.
            let typelikeKeywords = ["class", "struct", "enum", "protocol", "extension"]

            if typelikeKeywords.contains(declaration.keyword),
               let declarationTypeKeywordIndex = declarationParser
               .index(after: -1, where: { $0.string == declaration.keyword }),
               let startOfBody = declarationParser
               .index(of: .startOfScope("{"), after: declarationTypeKeywordIndex),
               let endOfBody = declarationParser.endOfScope(at: startOfBody)
            {
                let (startTokens, bodyDeclarations, endTokens) = parseBody(in: startOfBody ... endOfBody)

                return .type(
                    kind: declaration.keyword,
                    open: startTokens,
                    body: bodyDeclarations,
                    close: endTokens
                )
            }

            // If this declaration represents a conditional compilation block,
            // we also have to parse its inner declarations.
            else if declaration.keyword == "#if",
                let declarationTypeKeywordIndex = declarationParser
                .index(after: -1, where: { $0.string == declaration.keyword }),
                let endOfBody = declarationParser.endOfScope(at: declarationTypeKeywordIndex)
            {
                let startOfBody = declarationParser.endOfLine(at: declarationTypeKeywordIndex)
                let (startTokens, bodyDeclarations, endTokens) = parseBody(in: startOfBody ... endOfBody)

                return .conditionalCompilation(
                    open: startTokens,
                    body: bodyDeclarations,
                    close: endTokens
                )
            } else {
                return declaration
            }
        }
    }

    // Swift modifier keywords, in preferred order
    var modifierOrder: [String] {
        var priorities = [String: Int]()
        for (i, modifiers) in _FormatRules.defaultModifierOrder.enumerated() {
            for modifier in modifiers {
                priorities[modifier] = i
            }
        }
        var order = options.modifierOrder
        for (i, modifiers) in _FormatRules.defaultModifierOrder.enumerated() {
            for modifier in modifiers where !order.contains(modifier) {
                var insertionPoint = order.count
                for (index, s) in order.enumerated() {
                    if let j = priorities[s] {
                        if j > i {
                            insertionPoint = index
                        } else if j == i {
                            insertionPoint = index + 1
                        }
                    }
                }
                order.insert(modifier, at: insertionPoint)
            }
        }
        return order
    }

    /// Returns the index where the `wrap` rule should add the next linebreak in the line at the selected index.
    ///
    /// If the line does not need to be wrapped, this will return `nil`.
    ///
    /// - Note: This checks the entire line from the start of the line, the linebreak may be an index preceding the
    ///         `index` passed to the function.
    func indexWhereLineShouldWrapInLine(at index: Int) -> Int? {
        return indexWhereLineShouldWrap(from: startOfLine(at: index))
    }

    func indexWhereLineShouldWrap(from index: Int) -> Int? {
        var lineLength = self.lineLength(upTo: index)
        var stringLiteralDepth = 0
        var currentPriority = 0
        var lastBreakPoint: Int?
        var lastBreakPointPriority = Int.min

        let maxWidth = options.maxWidth
        guard maxWidth > 0 else { return nil }

        func addBreakPoint(at i: Int, relativePriority: Int) {
            guard stringLiteralDepth == 0, currentPriority + relativePriority >= lastBreakPointPriority,
                  !isInClosureArguments(at: i + 1)
            else {
                return
            }
            let i = self.index(of: .nonSpace, before: i + 1) ?? i
            if token(at: i + 1)?.isLinebreak == true || token(at: i)?.isLinebreak == true {
                return
            }
            lastBreakPoint = i
            lastBreakPointPriority = currentPriority + relativePriority
        }

        var i = index
        let endIndex = endOfLine(at: index)
        while i < endIndex {
            var token = tokens[i]
            switch token {
            case .linebreak:
                return nil
            case .keyword("#colorLiteral"), .keyword("#imageLiteral"):
                guard let startIndex = self.index(of: .startOfScope("("), after: i),
                      let endIndex = endOfScope(at: startIndex)
                else {
                    return nil // error
                }
                token = .space(spaceEquivalentToTokens(from: i, upTo: endIndex + 1)) // hack to get correct length
                i = endIndex
            case let .delimiter(string) where options.noWrapOperators.contains(string),
                 let .operator(string, .infix) where options.noWrapOperators.contains(string):
                // TODO: handle as/is
                break
            case .delimiter(","):
                addBreakPoint(at: i, relativePriority: 0)
            case .operator("=", .infix) where self.token(at: i + 1)?.isSpace == true:
                addBreakPoint(at: i, relativePriority: -9)
            case .operator(".", .infix):
                addBreakPoint(at: i - 1, relativePriority: -2)
            case .operator("->", .infix):
                if isInReturnType(at: i) {
                    currentPriority -= 5
                }
                addBreakPoint(at: i - 1, relativePriority: -5)
            case .operator(_, .infix) where self.token(at: i + 1)?.isSpace == true:
                addBreakPoint(at: i, relativePriority: -3)
            case .startOfScope("{"):
                if !isStartOfClosure(at: i) ||
                    next(.keyword, after: i) != .keyword("in"),
                    next(.nonSpace, after: i) != .endOfScope("}")
                {
                    addBreakPoint(at: i, relativePriority: -6)
                }
                if isInReturnType(at: i) {
                    currentPriority += 5
                }
                currentPriority -= 6
            case .endOfScope("}"):
                currentPriority += 6
                if last(.nonSpace, before: i) != .startOfScope("{") {
                    addBreakPoint(at: i - 1, relativePriority: -6)
                }
            case .startOfScope("("):
                currentPriority -= 7
            case .endOfScope(")"):
                currentPriority += 7
            case .startOfScope("["):
                currentPriority -= 8
            case .endOfScope("]"):
                currentPriority += 8
            case .startOfScope("<"):
                currentPriority -= 9
            case .endOfScope(">"):
                currentPriority += 9
            case .startOfScope where token.isStringDelimiter:
                stringLiteralDepth += 1
            case .endOfScope where token.isStringDelimiter:
                stringLiteralDepth -= 1
            case .keyword("else"), .keyword("where"):
                addBreakPoint(at: i - 1, relativePriority: -1)
            case .keyword("in"):
                if last(.keyword, before: i) == .keyword("for") {
                    addBreakPoint(at: i, relativePriority: -11)
                    break
                }
                addBreakPoint(at: i, relativePriority: -5 - currentPriority)
            default:
                break
            }
            lineLength += tokenLength(token)
            if lineLength > maxWidth, let breakPoint = lastBreakPoint, breakPoint < i {
                return breakPoint
            }
            i += 1
        }
        return nil
    }

    /// Indent level to use for wrapped lines at the specified position (based on statement type)
    func linewrapIndent(at index: Int) -> String {
        guard let commaIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, before: index + 1, if: {
            $0 == .delimiter(",")
        }), case let lineStart = startOfLine(at: commaIndex),
            let firstToken = self.index(of: .nonSpace, after: lineStart - 1),
            let keywordIndex = lastIndex(in: firstToken ..< commaIndex, where: {
                [.keyword("if"), .keyword("guard"), .keyword("while")].contains($0)
            }) ?? lastIndex(in: firstToken ..< commaIndex, where: {
                [.keyword("let"), .keyword("var"), .keyword("case")].contains($0)
            })
        else {
            return options.indent
        }
        guard let nextTokenIndex = self.index(of: .nonSpace, after: keywordIndex) else {
            return options.indent
        }
        return spaceEquivalentToTokens(from: firstToken, upTo: nextTokenIndex)
    }
}

extension _FormatRules {
    // Short date formater. Used by fileHeader rule
    static var shortDateFormatter: (Date) -> String = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return { formatter.string(from: $0) }
    }()

    // Year formater. Used by fileHeader rule
    static var yearFormatter: (Date) -> String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return { formatter.string(from: $0) }
    }()

    // Current year. Used by fileHeader rule
    static var currentYear: String = {
        yearFormatter(Date())
    }()

    // All modifiers
    static let allModifiers = Set(defaultModifierOrder.flatMap { $0 })

    // ACL modifiers
    static let aclModifiers = ["private", "fileprivate", "internal", "public", "open"]

    // Swift modifier keywords, in default order
    static let defaultModifierOrder = [
        ["override"],
        aclModifiers,
        ["private(set)", "fileprivate(set)", "internal(set)", "public(set)"],
        ["final", "dynamic"], // Can't be both
        ["optional", "required"],
        ["convenience"],
        ["indirect"],
        ["lazy"],
        ["weak", "unowned"],
        ["static", "class"],
        ["mutating", "nonmutating"],
        ["prefix", "infix", "postfix"],
    ]
}

extension Token {
    /// Whether or not this token "defines" the specific type of declaration
    ///  - A valid declaration will usually include exactly one of these keywords in its outermost scope.
    ///  - Notable exceptions are `class func` and symbol imports (like `import class Module.Type`)
    ///    which will include two of these keywords.
    var isDeclarationTypeKeyword: Bool {
        guard case let .keyword(keyword) = self else {
            return false
        }
        // All of the keywords that map to individual Declaration grammars
        // https://docs.swift.org/swift-book/ReferenceManual/Declarations.html#grammar_declaration
        return ["import", "let", "var", "typealias", "func", "enum", "case",
                "struct", "class", "protocol", "init", "deinit",
                "extension", "subscript", "operator", "precedencegroup"].contains(keyword)
    }

    /// Whether or not this token can precede the token that `isDeclarationTypeKeyword`
    /// in a given declaration. e.g. `public` can precede `var` in `public var foo = "bar"`.
    var canPrecedeDeclarationTypeKeyword: Bool {
        if isAttribute || isKeyword || isSpaceOrCommentOrLinebreak {
            return true
        }
        if case let .identifier(string) = self, _FormatRules.allModifiers.contains(string) {
            return true
        }
        return false
    }
}
