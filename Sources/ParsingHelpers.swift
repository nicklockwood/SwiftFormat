//
//  ParsingHelpers.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 08/04/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

import Foundation

// MARK: shared helper methods

extension Formatter {
    /// Returns the index of the first token of the line containing the specified index
    public func startOfLine(at index: Int) -> Int {
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
    public func endOfLine(at index: Int) -> Int {
        var index = index
        while let token = token(at: index) {
            if case .linebreak = token {
                break
            }
            index += 1
        }
        return index
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
        var length = 0
        for token in tokens[startOfLine(at: index) ..< endOfLine(at: index)] {
            length += tokenLength(token)
        }
        return length
    }

    /// Returns the length (in characters) up to (but not including) the specified token index
    func lineLength(upTo index: Int) -> Int {
        var length = 0
        for token in tokens[startOfLine(at: index) ..< index] {
            length += tokenLength(token)
        }
        return length
    }

    /// Returns the length (in characters) of the specified token range
    func lineLength(from start: Int, upTo end: Int) -> Int {
        return tokens[start ..< end].reduce(0) { total, token in
            total + tokenLength(token)
        }
    }

    /// Returns white space made up of indent characters equvialent to the specified width
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
        return tokens[start ..< end].reduce(into: "") { result, token in
            if case let .space(string) = token {
                result += string
            } else {
                result += String(repeating: " ", count: tokenLength(token))
            }
        }
    }

    func modifiersForType(at index: Int, contains: (Int, Token) -> Bool) -> Bool {
        let allModifiers = _FormatRules.allModifiers
        var index = index
        while var prevIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, before: index) {
            switch tokens[prevIndex] {
            case let token where contains(prevIndex, token):
                return true
            case .endOfScope(")"):
                guard let startIndex = self.index(of: .startOfScope("("), before: prevIndex),
                    last(.nonSpaceOrCommentOrLinebreak, before: startIndex, if: {
                        $0.isAttribute || _FormatRules.aclModifiers.contains($0.string)
                    }) != nil
                else {
                    return false
                }
                prevIndex = startIndex
            case let .keyword(name), let .identifier(name):
                if !allModifiers.contains(name), !name.hasPrefix("@") {
                    return false
                }
            default:
                return false
            }
            index = prevIndex
        }
        return false
    }

    func modifiersForType(at index: Int, contains: String) -> Bool {
        return modifiersForType(at: index, contains: { $1.string == contains })
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

    // get type of declaration starting at index of declaration keyword
    func declarationType(at index: Int) -> String? {
        guard case let .keyword(keyword)? = token(at: index) else {
            return nil
        }
        switch keyword {
        case "let", "var", "func", "init", "subscript", "struct", "enum":
            return keyword
        case "class":
            if let nextIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, after: index, if: {
                $0.isKeyword
            }) {
                return declarationType(at: nextIndex)
            }
            return keyword
        default:
            return nil
        }
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

    // remove self if possible
    func removeSelf(at i: Int, localNames: Set<String>) -> Bool {
        assert(tokens[i] == .identifier("self"))
        guard let dotIndex = index(of: .nonSpaceOrLinebreak, after: i, if: {
            $0 == .operator(".", .infix)
        }), let nextIndex = index(of: .nonSpaceOrLinebreak, after: dotIndex, if: {
            $0.isIdentifier && !localNames.contains($0.unescaped())
        }), !backticksRequired(at: nextIndex, ignoreLeadingDot: true) else {
            return false
        }
        removeTokens(inRange: i ..< nextIndex)
        return true
    }

    // gather declared variable names, starting at index after let/var keyword
    func processDeclaredVariables(at index: inout Int, names: inout Set<String>) {
        processDeclaredVariables(at: &index, names: &names, removeSelf: false)
    }

    // gather declared variable names, starting at index after let/var keyword
    func processDeclaredVariables(at index: inout Int, names: inout Set<String>, removeSelf: Bool) {
        while let token = self.token(at: index) {
            switch token {
            case .identifier where
                last(.nonSpaceOrCommentOrLinebreak, before: index)?.isOperator(".") == false:
                let name = token.unescaped()
                if name != "_" {
                    names.insert(name)
                }
                inner: while let nextIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, after: index) {
                    switch tokens[nextIndex] {
                    case .keyword("as"), .keyword("is"), .keyword("try"):
                        break
                    case .startOfScope("<"), .startOfScope("["), .startOfScope("("),
                         .startOfScope where token.isStringDelimiter:
                        guard let endIndex = endOfScope(at: nextIndex) else {
                            return // error
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
                    case .delimiter(","):
                        index = nextIndex
                        break inner
                    case .identifier("self") where removeSelf && isEnabled:
                        _ = self.removeSelf(at: nextIndex, localNames: names)
                    default:
                        break
                    }
                    index = nextIndex
                }
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
        case .endOfScope(")"):
            guard let startOfScope = index(of: .startOfScope("("), before: prevIndex),
                let prev = index(of: .nonSpaceOrCommentOrLinebreak, before: startOfScope)
            else {
                return true
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
                return !isConditionalStatement(at: startOfScope)
            }
            fallthrough
        case .identifier:
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
            case "func", "subscript", "class", "struct", "protocol", "enum", "extension":
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
            guard let braceIndex = lastIndex(of: .endOfScope("}"), in: index + 1 ..< i) else {
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
        return indexOfLastSignificantKeyword(at: i, excluding: excluding).map {
            tokens[$0].string
        }
    }

    func indexOfLastSignificantKeyword(at i: Int, excluding: [String] = []) -> Int? {
        guard let token = token(at: i),
            let index = token.isKeyword ? i : index(of: .keyword, before: i)
        else {
            return nil
        }
        switch tokens[index].string {
        case let name where
            name.hasPrefix("#") || name.hasPrefix("@") || excluding.contains(name):
            fallthrough
        case "in", "as", "is", "try":
            return indexOfLastSignificantKeyword(at: index - 1, excluding: excluding)
        default:
            return index
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

    func isStartOfStatement(at i: Int, in scope: Token? = nil) -> Bool {
        guard let token = self.token(at: i) else { return true }
        switch token {
        case let .keyword(string) where [ // TODO: handle "in"
            "where", "dynamicType", "rethrows", "throws",
        ].contains(string):
            return false
        case .keyword("as"), .keyword("in"):
            // For case statements, we already indent
            return currentScope(at: i)?.string == "case"
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
        if let prevIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: i),
            tokens[prevIndex].isOperator(".")
        {
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

    // Shared wrap implementation
    func wrapCollectionsAndArguments(completePartialWrapping: Bool, wrapSingleArguments: Bool) {
        let maxWidth = options.maxWidth
        func removeLinebreakBeforeEndOfScope(at endOfScope: inout Int) {
            guard let lastIndex = index(of: .nonSpace, before: endOfScope, if: {
                $0.isLinebreak
            }) else {
                return
            }
            if case .commentBody? = last(.nonSpace, before: lastIndex) {
                return
            }
            // Remove linebreak
            removeTokens(inRange: lastIndex ..< endOfScope)
            endOfScope = lastIndex
            // Remove trailing comma
            if let prevCommaIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: endOfScope, if: {
                $0 == .delimiter(",")
            }) {
                removeToken(at: prevCommaIndex)
                endOfScope -= 1
            }
        }

        func keepParameterLabelsOnSameLine(startOfScope i: Int, endOfScope: inout Int) {
            var endIndex = endOfScope
            while let index = self.lastIndex(of: .linebreak, in: i + 1 ..< endIndex) {
                endIndex = index
                // Check if this linebreak sits between two identifiers
                // (e.g. the external and internal argument labels)
                guard let lastIndex = self.index(of: .nonSpaceOrLinebreak, before: index, if: {
                    $0.isIdentifier
                }), let nextIndex = self.index(of: .nonSpaceOrLinebreak, after: index, if: {
                    $0.isIdentifier
                }) else {
                    continue
                }
                // Remove linebreak
                let range = lastIndex + 1 ..< nextIndex
                let linebreakAndIndent = tokens[index ..< nextIndex]
                replaceTokens(inRange: range, with: [.space(" ")])
                endOfScope -= (range.count - 1)
                // Insert replacement linebreak after next comma
                if let nextComma = self.index(of: .delimiter(","), after: index) {
                    if token(at: nextComma + 1)?.isSpace == true {
                        replaceToken(at: nextComma + 1, with: Array(linebreakAndIndent))
                        endOfScope += linebreakAndIndent.count - 1
                    } else {
                        insertTokens(Array(linebreakAndIndent), at: nextComma + 1)
                        endOfScope += linebreakAndIndent.count
                    }
                }
            }
        }

        func wrapArgumentsBeforeFirst(startOfScope i: Int,
                                      endOfScope: Int,
                                      allowGrouping: Bool,
                                      endOfScopeOnSameLine: Bool)
        {
            // Get indent
            let indent = indentForLine(at: i)
            var endOfScope = endOfScope

            keepParameterLabelsOnSameLine(startOfScope: i,
                                          endOfScope: &endOfScope)

            if endOfScopeOnSameLine {
                removeLinebreakBeforeEndOfScope(at: &endOfScope)
            } else {
                // Insert linebreak before closing paren
                if let lastIndex = self.index(of: .nonSpace, before: endOfScope) {
                    endOfScope += insertSpace(indent, at: lastIndex + 1)
                    if !tokens[lastIndex].isLinebreak {
                        insertLinebreak(at: lastIndex + 1)
                        endOfScope += 1
                    }
                }
            }

            // Insert linebreak after each comma
            var index = self.index(of: .nonSpaceOrCommentOrLinebreak, before: endOfScope)!
            if tokens[index] != .delimiter(",") {
                index += 1
            }
            while let commaIndex = self.lastIndex(of: .delimiter(","), in: i + 1 ..< index),
                var linebreakIndex = self.index(of: .nonSpaceOrComment, after: commaIndex)
            {
                if let index = self.index(of: .nonSpace, before: linebreakIndex) {
                    linebreakIndex = index + 1
                }
                if !isCommentedCode(at: linebreakIndex + 1) {
                    if tokens[linebreakIndex].isLinebreak, !options.truncateBlankLines ||
                        next(.nonSpace, after: linebreakIndex).map({ !$0.isLinebreak }) ?? false
                    {
                        insertSpace(indent + options.indent, at: linebreakIndex + 1)
                    } else if !allowGrouping || (maxWidth > 0 &&
                        lineLength(at: linebreakIndex) > maxWidth &&
                        lineLength(upTo: linebreakIndex) <= maxWidth)
                    {
                        insertLinebreak(at: linebreakIndex)
                        insertSpace(indent + options.indent, at: linebreakIndex + 1)
                    }
                }
                index = commaIndex
            }
            // Insert linebreak and indent after opening paren
            if let nextIndex = self.index(of: .nonSpaceOrComment, after: i) {
                if !tokens[nextIndex].isLinebreak {
                    insertLinebreak(at: nextIndex)
                }
                if nextIndex + 1 < endOfScope {
                    var indent = indent
                    if (self.index(of: .nonSpace, after: nextIndex) ?? 0) < endOfScope {
                        indent += options.indent
                    }
                    insertSpace(indent, at: nextIndex + 1)
                }
            }
        }
        func wrapArgumentsAfterFirst(startOfScope i: Int, endOfScope: Int, allowGrouping: Bool) {
            guard var firstArgumentIndex = self.index(of: .nonSpaceOrLinebreak, in: i + 1 ..< endOfScope) else {
                return
            }

            var endOfScope = endOfScope
            keepParameterLabelsOnSameLine(startOfScope: i,
                                          endOfScope: &endOfScope)

            // Remove linebreak after opening paren
            removeTokens(inRange: i + 1 ..< firstArgumentIndex)
            endOfScope -= (firstArgumentIndex - (i + 1))
            firstArgumentIndex = i + 1
            // Get indent
            let start = startOfLine(at: i)
            let indent = spaceEquivalentToTokens(from: start, upTo: firstArgumentIndex)
            removeLinebreakBeforeEndOfScope(at: &endOfScope)
            // Insert linebreak after each comma
            var lastBreakIndex: Int?
            var index = firstArgumentIndex
            while let commaIndex = self.index(of: .delimiter(","), in: index ..< endOfScope),
                var linebreakIndex = self.index(of: .nonSpaceOrComment, after: commaIndex)
            {
                if let index = self.index(of: .nonSpace, before: linebreakIndex) {
                    linebreakIndex = index + 1
                }
                if maxWidth > 0, lineLength(upTo: commaIndex) >= maxWidth, let breakIndex = lastBreakIndex {
                    endOfScope += 1 + insertSpace(indent, at: breakIndex)
                    insertLinebreak(at: breakIndex)
                    lastBreakIndex = nil
                    index = commaIndex + 1
                    continue
                }
                if tokens[linebreakIndex].isLinebreak {
                    if linebreakIndex + 1 != endOfScope, !isCommentedCode(at: linebreakIndex + 1) {
                        endOfScope += insertSpace(indent, at: linebreakIndex + 1)
                    }
                } else if !allowGrouping {
                    insertLinebreak(at: linebreakIndex)
                    endOfScope += 1 + insertSpace(indent, at: linebreakIndex + 1)
                } else {
                    lastBreakIndex = linebreakIndex
                }
                index = commaIndex + 1
            }
            if maxWidth > 0, let breakIndex = lastBreakIndex, lineLength(at: breakIndex) > maxWidth {
                insertSpace(indent, at: breakIndex)
                insertLinebreak(at: breakIndex)
            }
        }

        var lastIndex = -1
        forEach(.startOfScope) { i, token in
            guard ["(", "[", "<"].contains(token.string) else {
                lastIndex = i
                return
            }

            if lastIndex < i, let i = (lastIndex + 1 ..< i).last(where: {
                tokens[$0].isLinebreak
            }) {
                lastIndex = i
            }

            guard let endOfScope = endOfScope(at: i) else {
                return
            }

            let mode: WrapMode
            var endOfScopeOnSameLine = false
            let hasMultipleArguments = index(of: .delimiter(","), in: i + 1 ..< endOfScope) != nil
            var isParameters = false
            switch token.string {
            case "(":
                /// Don't wrap color/image literals due to Xcode bug
                guard let prevToken = self.token(at: i - 1),
                    prevToken != .keyword("#colorLiteral"),
                    prevToken != .keyword("#imageLiteral")
                else {
                    return
                }
                guard hasMultipleArguments || wrapSingleArguments ||
                    index(in: i + 1 ..< endOfScope, where: { $0.isComment }) != nil
                else {
                    // Not an argument list, or only one argument
                    lastIndex = i
                    return
                }

                endOfScopeOnSameLine = options.closingParenOnSameLine
                isParameters = isParameterList(at: i)
                mode = isParameters ? options.wrapParameters : options.wrapArguments
            case "<":
                mode = options.wrapArguments
            case "[":
                mode = options.wrapCollections
            default:
                return
            }
            guard mode != .disabled, let firstIdentifierIndex =
                index(of: .nonSpaceOrCommentOrLinebreak, after: i),
                !isStringLiteral(at: i)
            else {
                lastIndex = i
                return
            }

            if completePartialWrapping,
                let firstLinebreakIndex = index(of: .linebreak, in: i + 1 ..< endOfScope)
            {
                switch mode {
                case .beforeFirst:
                    wrapArgumentsBeforeFirst(startOfScope: i,
                                             endOfScope: endOfScope,
                                             allowGrouping: firstIdentifierIndex > firstLinebreakIndex,
                                             endOfScopeOnSameLine: endOfScopeOnSameLine)
                case .preserve where firstIdentifierIndex > firstLinebreakIndex:
                    wrapArgumentsBeforeFirst(startOfScope: i,
                                             endOfScope: endOfScope,
                                             allowGrouping: true,
                                             endOfScopeOnSameLine: endOfScopeOnSameLine)
                case .afterFirst, .preserve:
                    wrapArgumentsAfterFirst(startOfScope: i,
                                            endOfScope: endOfScope,
                                            allowGrouping: true)
                case .disabled, .default:
                    assertionFailure() // Shouldn't happen
                }

            } else if maxWidth > 0, hasMultipleArguments || wrapSingleArguments {
                func willWrapAtStartOfReturnType(maxWidth: Int) -> Bool {
                    return isInReturnType(at: i) && maxWidth < lineLength(at: i)
                }

                func startOfNextScopeNotInReturnType() -> Int? {
                    let endOfLine = self.endOfLine(at: i)
                    guard endOfScope < endOfLine else { return nil }

                    var startOfLastScopeOnLine = endOfScope

                    repeat {
                        guard let startOfNextScope = index(
                            of: .startOfScope,
                            in: startOfLastScopeOnLine + 1 ..< endOfLine
                        ) else {
                            return nil
                        }

                        startOfLastScopeOnLine = startOfNextScope
                    } while isInReturnType(at: startOfLastScopeOnLine)

                    return startOfLastScopeOnLine
                }

                func indexOfNextWrap() -> Int? {
                    let startOfNextScopeOnLine = startOfNextScopeNotInReturnType()
                    let nextNaturalWrap = indexWhereLineShouldWrap(from: endOfScope + 1)

                    switch (startOfNextScopeOnLine, nextNaturalWrap) {
                    case let (.some(startOfNextScopeOnLine), .some(nextNaturalWrap)):
                        return min(startOfNextScopeOnLine, nextNaturalWrap)
                    case let (nil, .some(nextNaturalWrap)):
                        return nextNaturalWrap
                    case let (.some(startOfNextScopeOnLine), nil):
                        return startOfNextScopeOnLine
                    case (nil, nil):
                        return nil
                    }
                }

                func wrapArgumentsWithoutPartialWrapping() {
                    switch mode {
                    case .preserve, .beforeFirst:
                        wrapArgumentsBeforeFirst(startOfScope: i,
                                                 endOfScope: endOfScope,
                                                 allowGrouping: false,
                                                 endOfScopeOnSameLine: endOfScopeOnSameLine)
                    case .afterFirst:
                        wrapArgumentsAfterFirst(startOfScope: i,
                                                endOfScope: endOfScope,
                                                allowGrouping: true)
                    case .disabled, .default:
                        assertionFailure() // Shouldn't happen
                    }
                }

                if currentRule == FormatRules.wrap {
                    let nextWrapIndex = indexOfNextWrap() ?? endOfLine(at: i)
                    if nextWrapIndex > lastIndex,
                        maxWidth < lineLength(from: max(lastIndex, 0), upTo: nextWrapIndex),
                        !willWrapAtStartOfReturnType(maxWidth: maxWidth)
                    {
                        wrapArgumentsWithoutPartialWrapping()
                        lastIndex = nextWrapIndex
                        return
                    }
                } else if maxWidth < lineLength(upTo: endOfScope) {
                    wrapArgumentsWithoutPartialWrapping()
                }
            }

            lastIndex = i
        }
    }

    func removeParen(at index: Int) {
        func tokenOutsideParenRequiresSpacing(at index: Int) -> Bool {
            guard let token = self.token(at: index) else { return false }
            switch token {
            case .identifier, .keyword, .number, .startOfScope("#if"):
                return true
            default:
                return false
            }
        }

        func tokenInsideParenRequiresSpacing(at index: Int) -> Bool {
            guard let token = self.token(at: index) else { return false }
            switch token {
            case .operator, .startOfScope("{"), .endOfScope("}"):
                return true
            default:
                return tokenOutsideParenRequiresSpacing(at: index)
            }
        }

        if token(at: index - 1)?.isSpace == true,
            token(at: index + 1)?.isSpace == true
        {
            // Need to remove one
            removeToken(at: index + 1)
        } else if case .startOfScope = tokens[index] {
            if tokenOutsideParenRequiresSpacing(at: index - 1),
                tokenInsideParenRequiresSpacing(at: index + 1)
            {
                // Need to insert one
                insertToken(.space(" "), at: index + 1)
            }
        } else if tokenInsideParenRequiresSpacing(at: index - 1),
            tokenOutsideParenRequiresSpacing(at: index + 1)
        {
            // Need to insert one
            insertToken(.space(" "), at: index + 1)
        }
        removeToken(at: index)
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

        let tokens = self.tokens[index ..< endOfLine(at: index)]
        for (i, token) in zip(tokens.indices, tokens) {
            switch token {
            case .linebreak:
                return nil
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
        }
        return nil
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
    static let aclModifiers = ["private", "fileprivate", "internal", "public"]

    // Swift modifier keywords, in default order
    static let defaultModifierOrder = [
        ["override"],
        ["private", "fileprivate", "internal", "public", "open"],
        ["private(set)", "fileprivate(set)", "internal(set)", "public(set)"],
        ["final", "dynamic"], // Can't be both
        ["optional", "required"],
        ["convenience"],
        ["indirect"],
        ["lazy"],
        ["weak", "unowned"],
        ["static", "class"],
        ["mutating", "nonmutating"],
        ["prefix", "postfix"],
    ]
}
