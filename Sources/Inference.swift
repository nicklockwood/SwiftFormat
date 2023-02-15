//
//  Inference.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 07/08/2018.
//  Copyright © 2018 Nick Lockwood.
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

/// Infer default options by examining the existing source
public func inferFormatOptions(from tokens: [Token]) -> FormatOptions {
    var options = FormatOptions.default
    inferFormatOptions(Inference.all, from: tokens, into: &options)
    return options
}

func inferFormatOptions(_ options: [String], from tokens: [Token], into: inout FormatOptions) {
    let formatter = Formatter(tokens)
    for name in options {
        Inference.byName[name]?.fn(formatter, &into)
    }
}

private struct OptionInferrer {
    let fn: (Formatter, inout FormatOptions) -> Void

    init(_ fn: @escaping (Formatter, inout FormatOptions) -> Void) {
        self.fn = fn
    }
}

private struct Inference {
    let indent = OptionInferrer { formatter, options in
        var indents = [(indent: String, count: Int)]()
        func increment(_ indent: String) {
            for (i, element) in indents.enumerated() {
                if element.indent == indent {
                    indents[i] = (indent, element.count + 1)
                    return
                }
            }
            indents.append((indent, 0))
        }
        var previousLength = 0
        var scopeStack = [Token]()
        formatter.forEachToken { i, token in
            switch token {
            case .linebreak where scopeStack.isEmpty:
                guard case let .space(string)? = formatter.token(at: i + 1) else {
                    break
                }
                if string.hasPrefix("\t") {
                    increment("\t")
                } else {
                    let length = string.count
                    let delta = previousLength - length
                    if delta != 0 {
                        switch formatter.token(at: i + 2) ?? .space("") {
                        case .commentBody, .delimiter(","):
                            return
                        default:
                            break
                        }
                        switch formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) ?? .space("") {
                        case .delimiter(","):
                            break
                        default:
                            increment(String(repeating: " ", count: abs(delta)))
                            previousLength = length
                        }
                    }
                }
            case .startOfScope("/*"):
                scopeStack.append(token)
            case .endOfScope:
                if let scope = scopeStack.last, token.isEndOfScope(scope) {
                    scopeStack.removeLast()
                }
            default:
                break
            }
        }
        if let indent = indents.sorted(by: {
            $0.count > $1.count
        }).first.map({ $0.indent }) {
            options.indent = indent
        }
    }

    let linebreak = OptionInferrer { formatter, options in
        var cr = 0, lf = 0, crlf = 0
        formatter.forEachToken { _, token in
            switch token {
            case .linebreak("\n", _):
                lf += 1
            case .linebreak("\r", _):
                cr += 1
            case .linebreak("\r\n", _):
                crlf += 1
            default:
                break
            }
        }
        var max = lf
        var linebreak = "\n"
        if cr > max {
            max = cr
            linebreak = "\r"
        }
        if crlf > max {
            max = crlf
            linebreak = "\r\n"
        }
        options.linebreak = linebreak
    }

    let allowInlineSemicolons = OptionInferrer { formatter, options in
        var allow = false
        for (i, token) in formatter.tokens.enumerated() {
            guard case .delimiter(";") = token else {
                continue
            }
            if formatter.next(.nonSpaceOrComment, after: i)?.isLinebreak == false {
                allow = true
                break
            }
        }
        options.allowInlineSemicolons = allow
    }

    let noSpaceOperators = OptionInferrer { formatter, options in
        var spaced = [String: Int](), unspaced = [String: Int]()
        formatter.forEach(.operator) { i, token in
            guard case let .operator(name, .infix) = token, name != ".",
                  let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: i),
                  nextToken.string != ")", nextToken.string != ","
            else {
                return
            }
            if formatter.token(at: i + 1)?.isSpaceOrLinebreak == true {
                spaced[name, default: 0] += 1
            } else {
                unspaced[name, default: 0] += 1
            }
        }
        var noSpaceOperators = Set<String>()
        let operators = Set(spaced.keys).union(unspaced.keys)
        for name in operators where unspaced[name, default: 0] > spaced[name, default: 0] + 1 {
            noSpaceOperators.insert(name)
        }
        // Related pairs
        let relatedPairs = [
            ("...", "..<"), ("*", "/"), ("*=", "/="), ("+", "-"), ("+=", "-="),
            ("==", "!="), ("<", ">"), ("<=", ">="), ("<<", ">>"),
        ]
        for pair in relatedPairs {
            if noSpaceOperators.contains(pair.0),
               !noSpaceOperators.contains(pair.1),
               !operators.contains(pair.1)
            {
                noSpaceOperators.insert(pair.1)
            } else if noSpaceOperators.contains(pair.1),
                      !noSpaceOperators.contains(pair.0),
                      !operators.contains(pair.0)
            {
                noSpaceOperators.insert(pair.0)
            }
        }
        options.noSpaceOperators = noSpaceOperators
    }

    let useVoid = OptionInferrer { formatter, options in
        var voids = 0, tuples = 0
        formatter.forEach(.identifier("Void")) { i, _ in
            if let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: i),
               [.operator(".", .prefix), .operator(".", .infix), .keyword("typealias")].contains(prevToken)
            {
                return
            }
            voids += 1
        }
        formatter.forEach(.startOfScope("(")) { i, _ in
            if let prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i),
               let prevToken = formatter.token(at: prevIndex), prevToken == .operator("->", .infix),
               let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i),
               let nextToken = formatter.token(at: nextIndex), nextToken.string == ")",
               formatter.next(.nonSpaceOrCommentOrLinebreak, after: nextIndex) != .operator("->", .infix)
            {
                tuples += 1
            }
        }
        options.useVoid = (voids >= tuples)
    }

    let trailingCommas = OptionInferrer { formatter, options in
        var trailing = 0, noTrailing = 0
        formatter.forEach(.endOfScope("]")) { i, _ in
            guard let linebreakIndex = formatter.index(of: .nonSpaceOrComment, before: i),
                  case .linebreak = formatter.tokens[linebreakIndex],
                  let prevTokenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: linebreakIndex + 1),
                  let token = formatter.token(at: prevTokenIndex)
            else {
                return
            }
            switch token.string {
            case "[", ":":
                break // do nothing
            case ",":
                trailing += 1
            default:
                noTrailing += 1
            }
        }
        options.trailingCommas = (trailing >= noTrailing)
    }

    let truncateBlankLines = OptionInferrer { formatter, options in
        var truncated = 0, untruncated = 0
        var scopeStack = [Token]()
        formatter.forEachToken { i, token in
            switch token {
            case .startOfScope:
                scopeStack.append(token)
            case .linebreak:
                switch formatter.token(at: i + 1) {
                case .space?:
                    if let nextToken = formatter.token(at: i + 2) {
                        if case .linebreak = nextToken {
                            untruncated += 1
                        }
                    } else {
                        untruncated += 1
                    }
                case .linebreak?, nil:
                    truncated += 1
                default:
                    break
                }
            default:
                if let scope = scopeStack.last, token.isEndOfScope(scope) {
                    scopeStack.removeLast()
                }
            }
        }
        options.truncateBlankLines = (truncated >= untruncated)
    }

    let allmanBraces = OptionInferrer { formatter, options in
        var allman = 0, knr = 0
        formatter.forEach(.startOfScope("{")) { i, _ in
            // Check this isn't an inline block
            guard let closingBraceIndex = formatter.index(of: .endOfScope("}"), after: i),
                  formatter.index(of: .linebreak, in: i + 1 ..< closingBraceIndex) != nil
            else {
                return
            }
            // Ignore wrapped if/else/guard
            if let keyword = formatter.lastSignificantKeyword(at: i - 1, excluding: ["else"]),
               ["if", "guard", "while", "let", "var", "case"].contains(keyword)
            {
                return
            }
            // Check if brace is wrapped
            if let prevTokenIndex = formatter.index(of: .nonSpace, before: i),
               let prevToken = formatter.token(at: prevTokenIndex)
            {
                switch prevToken {
                case .identifier, .keyword, .endOfScope, .operator("?", .postfix), .operator("!", .postfix):
                    knr += 1
                case .linebreak:
                    allman += 1
                default:
                    break
                }
            }
        }
        options.allmanBraces = (allman > 1 && allman > knr)
    }

    let ifdefIndent = OptionInferrer { formatter, options in
        var indented = 0, notIndented = 0, outdented = 0
        formatter.forEach(.startOfScope("#if")) { i, _ in
            if let indent = formatter.token(at: i - 1), case let .space(string) = indent,
               !string.isEmpty
            {
                // Indented, check next line
                if let nextLineIndex = formatter.index(of: .linebreak, after: i),
                   let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: nextLineIndex)
                {
                    switch formatter.tokens[nextIndex - 1] {
                    case let .space(innerString):
                        if innerString.isEmpty {
                            // Error?
                            return
                        } else if innerString == string {
                            notIndented += 1
                        } else {
                            // Assume more indented, as less would be a mistake
                            indented += 1
                        }
                    case .linebreak:
                        // Could be noindent or outdent
                        notIndented += 1
                        outdented += 1
                    default:
                        break
                    }
                }
                // Error?
                return
            }
            // Not indented, check next line
            if let nextLineIndex = formatter.index(of: .linebreak, after: i),
               let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: nextLineIndex)
            {
                switch formatter.tokens[nextIndex - 1] {
                case let .space(string):
                    if string.isEmpty {
                        fallthrough
                    } else if string == formatter.options.indent {
                        // Could be indent or outdent
                        indented += 1
                        outdented += 1
                    } else {
                        // Assume more indented, as less would be a mistake
                        outdented += 1
                    }
                case .linebreak:
                    // Could be noindent or outdent
                    notIndented += 1
                    outdented += 1
                default:
                    break
                }
            }
            // Error?
        }
        if notIndented > indented {
            options.ifdefIndent = outdented > notIndented ? .outdent : .noIndent
        } else {
            options.ifdefIndent = outdented > indented ? .outdent : .indent
        }
    }

    let wrapArguments = OptionInferrer { formatter, options in
        options.wrapArguments = formatter.wrapMode(forParameters: false)
    }

    let wrapParameters = OptionInferrer { formatter, options in
        options.wrapParameters = formatter.wrapMode(forParameters: true)
    }

    let wrapCollections = OptionInferrer { formatter, options in
        options.wrapCollections = formatter.wrapMode(for: "[")
    }

    let closingParenOnSameLine = OptionInferrer { formatter, options in
        var balanced = 0, sameLine = 0
        formatter.forEach(.startOfScope("(")) { i, _ in
            guard let closingBraceIndex = formatter.endOfScope(at: i),
                  let linebreakIndex = formatter.index(of: .linebreak, after: i),
                  formatter.index(of: .nonSpaceOrComment, after: i) == linebreakIndex
            else {
                return
            }
            if formatter.last(.nonSpaceOrComment, before: closingBraceIndex)?.isLinebreak == true {
                balanced += 1
            } else {
                sameLine += 1
            }
        }
        options.closingParenOnSameLine = (sameLine > balanced)
    }

    let uppercaseHex = OptionInferrer { formatter, options in
        let prefix = "0x"
        var uppercase = 0, lowercase = 0
        formatter.forEachToken { _, token in
            if case var .number(string, .hex) = token {
                string = string
                    .replacingOccurrences(of: "p", with: "")
                    .replacingOccurrences(of: "P", with: "")
                if string == string.lowercased() {
                    lowercase += 1
                } else {
                    let value = string[prefix.endIndex ..< string.endIndex]
                    if value == value.uppercased() {
                        uppercase += 1
                    }
                }
            }
        }
        options.uppercaseHex = (uppercase >= lowercase)
    }

    let uppercaseExponent = OptionInferrer { formatter, options in
        var uppercase = 0, lowercase = 0
        formatter.forEachToken { _, token in
            switch token {
            case let .number(string, .decimal):
                let characters = string.unicodeScalars
                if characters.contains("e") {
                    lowercase += 1
                } else if characters.contains("E") {
                    uppercase += 1
                }
            case let .number(string, .hex):
                let characters = string.unicodeScalars
                if characters.contains("p") {
                    lowercase += 1
                } else if characters.contains("P") {
                    uppercase += 1
                }
            default:
                break
            }
        }
        options.uppercaseExponent = (uppercase > lowercase)
    }

    let decimalGrouping = OptionInferrer { formatter, options in
        options.decimalGrouping = formatter.grouping(for: .decimal)
    }

    let binaryGrouping = OptionInferrer { formatter, options in
        options.binaryGrouping = formatter.grouping(for: .binary)
    }

    let octalGrouping = OptionInferrer { formatter, options in
        options.octalGrouping = formatter.grouping(for: .octal)
    }

    let hexGrouping = OptionInferrer { formatter, options in
        options.hexGrouping = formatter.grouping(for: .hex)
    }

    let fractionGrouping = OptionInferrer { formatter, options in
        options.fractionGrouping = formatter.hasGrouping(for: .fraction)
    }

    let exponentGrouping = OptionInferrer { formatter, options in
        options.exponentGrouping = formatter.hasGrouping(for: .exponent)
    }

    let hoistPatternLet = OptionInferrer { formatter, options in
        var hoisted = 0, unhoisted = 0

        func hoistable(_ keyword: String, in range: CountableRange<Int>) -> Bool {
            var count = 0, keywordFound = false, identifierFound = false
            for index in range {
                switch formatter.tokens[index] {
                case .keyword(keyword):
                    keywordFound = true
                case .identifier("_"):
                    break
                case .identifier where formatter.last(.nonSpaceOrComment, before: index)?.string != ".":
                    identifierFound = true
                    if keywordFound {
                        count += 1
                    }
                case .delimiter(","):
                    guard keywordFound || !identifierFound else { return false }
                    keywordFound = false
                    identifierFound = false
                case .startOfScope("{"):
                    return false
                default:
                    break
                }
            }
            return (keywordFound || !identifierFound) && count > 0
        }

        formatter.forEach(.startOfScope("(")) { i, _ in
            // Check if pattern starts with let/var
            var startIndex = i
            guard let endIndex = formatter.index(of: .endOfScope(")"), after: i) else { return }
            if var prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i) {
                if case .identifier = formatter.tokens[prevIndex] {
                    prevIndex = formatter.index(of: .spaceOrCommentOrLinebreak, before: prevIndex) ?? -1
                    startIndex = prevIndex + 1
                    prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: startIndex) ?? 0
                }
                let prevToken = formatter.tokens[prevIndex]
                switch prevToken {
                case .keyword("let"), .keyword("var"):
                    guard let prevPrevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: prevIndex),
                          [.keyword("case"), .endOfScope("case"), .delimiter(",")].contains(prevPrevToken)
                    else {
                        // Tuple assignment, not a pattern
                        return
                    }
                    hoisted += 1
                case .keyword("case"), .endOfScope("case"), .delimiter(","):
                    if hoistable("let", in: i + 1 ..< endIndex) || hoistable("var", in: i + 1 ..< endIndex) {
                        unhoisted += 1
                    }
                default:
                    return
                }
            }
        }
        options.hoistPatternLet = (hoisted >= unhoisted)
    }

    let stripUnusedArguments = OptionInferrer { formatter, options in
        var functionArgsRemoved = 0, functionArgsKept = 0
        var unnamedFunctionArgsRemoved = 0, unnamedFunctionArgsKept = 0

        func removeUsed<T>(from argNames: inout [String], with associatedData: inout [T], in range: CountableRange<Int>) {
            for i in range {
                let token = formatter.tokens[i]
                if case .identifier = token, let index = argNames.firstIndex(of: token.unescaped()),
                   formatter.last(.nonSpaceOrCommentOrLinebreak, before: i)?.isOperator(".") == false,
                   formatter.next(.nonSpaceOrCommentOrLinebreak, after: i) != .delimiter(":") ||
                   formatter.currentScope(at: i) == .startOfScope("[")
                {
                    argNames.remove(at: index)
                    associatedData.remove(at: index)
                    if argNames.isEmpty {
                        break
                    }
                }
            }
        }
        // Function arguments
        formatter.forEachToken { i, token in
            guard case let .keyword(keyword) = token, ["func", "init", "subscript"].contains(keyword),
                  let startIndex = formatter.index(of: .startOfScope("("), after: i),
                  let endIndex = formatter.index(of: .endOfScope(")"), after: startIndex) else { return }
            let isOperator = (keyword == "subscript") ||
                (keyword == "func" && formatter.next(.nonSpaceOrCommentOrLinebreak, after: i)?.isOperator == true)
            var index = startIndex
            var argNames = [String]()
            var nameIndices = [Int]()
            while index < endIndex {
                guard let externalNameIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index, if: {
                    if case .identifier = $0 { return true }
                    // Probably an empty argument list
                    return false
                }) else { return }
                guard let nextIndex =
                    formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: externalNameIndex) else { return }
                let nextToken = formatter.tokens[nextIndex]
                switch nextToken {
                case let .identifier(name):
                    if name == "_" {
                        functionArgsRemoved += 1
                        let externalNameToken = formatter.tokens[externalNameIndex]
                        if case .identifier("_") = externalNameToken {
                            unnamedFunctionArgsRemoved += 1
                        }
                    } else {
                        argNames.append(nextToken.unescaped())
                        nameIndices.append(externalNameIndex)
                    }
                case .delimiter(":"):
                    let externalNameToken = formatter.tokens[externalNameIndex]
                    if case .identifier("_") = externalNameToken {
                        functionArgsRemoved += 1
                        unnamedFunctionArgsRemoved += 1
                    } else {
                        argNames.append(externalNameToken.unescaped())
                        nameIndices.append(externalNameIndex)
                    }
                default:
                    return
                }
                index = formatter.index(of: .delimiter(","), after: index) ?? endIndex
            }
            guard !argNames.isEmpty, let bodyStartIndex = formatter.index(after: endIndex, where: {
                switch $0 {
                case .startOfScope("{"): // What we're looking for
                    return true
                case .keyword("throws"),
                     .keyword("rethrows"),
                     .keyword("where"),
                     .keyword("is"):
                    return false // Keep looking
                case .keyword:
                    return true // Not valid between end of arguments and start of body
                default:
                    return false // Keep looking
                }
            }), formatter.tokens[bodyStartIndex] == .startOfScope("{"),
            let bodyEndIndex = formatter.index(of: .endOfScope("}"), after: bodyStartIndex) else {
                return
            }
            removeUsed(from: &argNames, with: &nameIndices, in: bodyStartIndex + 1 ..< bodyEndIndex)
            for index in nameIndices.reversed() {
                functionArgsKept += 1
                if case .identifier("_") = formatter.tokens[index] {
                    unnamedFunctionArgsKept += 1
                }
            }
        }
        if functionArgsRemoved >= functionArgsKept {
            options.stripUnusedArguments = .all
        } else if unnamedFunctionArgsRemoved >= unnamedFunctionArgsKept {
            options.stripUnusedArguments = .unnamedOnly
        } else {
            // TODO: infer not removing args at all
            options.stripUnusedArguments = .closureOnly
        }
    }

    let explicitSelf = OptionInferrer { formatter, options in
        func processBody(at index: inout Int, localNames: Set<String>, members: Set<String>,
                         typeStack: inout [String],
                         membersByType: inout [String: Set<String>],
                         classMembersByType: inout [String: Set<String>],
                         removed: inout Int, unremoved: inout Int,
                         initRemoved: inout Int, initUnremoved: inout Int,
                         isTypeRoot: Bool,
                         isInit: Bool)
        {
            var selfRequired: Set<String> { formatter.options.selfRequired }
            let currentScope = formatter.currentScope(at: index)
            let isWhereClause = index > 0 && formatter.tokens[index - 1] == .keyword("where")
            assert(isWhereClause || currentScope.map { token -> Bool in
                [.startOfScope("{"), .startOfScope(":")].contains(token)
            } ?? true)
            // Gather members & local variables
            let type = (isTypeRoot && typeStack.count == 1) ? typeStack.first : nil
            var members = type.flatMap { membersByType[$0] } ?? members
            var classMembers = type.flatMap { classMembersByType[$0] } ?? Set<String>()
            var localNames = localNames
            do {
                var i = index
                var classOrStatic = false
                outer: while let token = formatter.token(at: i) {
                    switch token {
                    case .keyword("import"):
                        guard let nextIndex = formatter.index(of: .identifier, after: i) else {
                            return // error
                        }
                        i = nextIndex
                    case .keyword("class"), .keyword("static"):
                        classOrStatic = true
                    case .keyword("repeat"):
                        guard let nextIndex = formatter.index(of: .keyword("while"), after: i) else {
                            return // error
                        }
                        i = nextIndex
                    case .keyword("if"), .keyword("while"):
                        guard let nextIndex = formatter.index(of: .startOfScope("{"), after: i) else {
                            return // error
                        }
                        i = nextIndex
                        continue
                    case .keyword("switch"):
                        guard let nextIndex = formatter.index(of: .startOfScope("{"), after: i),
                              var endIndex = formatter.index(of: .endOfScope, after: nextIndex)
                        else {
                            return // error
                        }
                        while formatter.tokens[endIndex] != .endOfScope("}") {
                            guard let nextIndex = formatter.index(of: .startOfScope(":"), after: endIndex),
                                  let _endIndex = formatter.index(of: .endOfScope, after: nextIndex)
                            else {
                                return // error
                            }
                            endIndex = _endIndex
                        }
                        i = endIndex
                    case .keyword("var"), .keyword("let"):
                        i += 1
                        if isTypeRoot {
                            if classOrStatic {
                                formatter.processDeclaredVariables(at: &i, names: &classMembers)
                                classOrStatic = false
                            } else {
                                formatter.processDeclaredVariables(at: &i, names: &members)
                            }
                        } else {
                            formatter.processDeclaredVariables(at: &i, names: &localNames)
                        }
                    case .keyword("func"):
                        guard let nameToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: i) else {
                            break
                        }
                        if isTypeRoot {
                            if classOrStatic {
                                classMembers.insert(nameToken.unescaped())
                                classOrStatic = false
                            } else {
                                members.insert(nameToken.unescaped())
                            }
                        } else {
                            localNames.insert(nameToken.unescaped())
                        }
                    case .startOfScope("("), .startOfScope("#if"), .startOfScope(":"):
                        break
                    case .startOfScope:
                        classOrStatic = false
                        i = formatter.endOfScope(at: i) ?? (formatter.tokens.count - 1)
                    case .endOfScope("}"), .endOfScope("case"), .endOfScope("default"):
                        break outer
                    default:
                        break
                    }
                    i += 1
                }
            }
            if let type = type {
                membersByType[type] = members
                classMembersByType[type] = classMembers
            }
            // Remove or add `self`
            var scopeStack = [Token]()
            var lastKeyword = ""
            var lastKeywordIndex = 0
            var classOrStatic = false
            while let token = formatter.token(at: index) {
                switch token {
                case .keyword("is"), .keyword("as"), .keyword("try"), .keyword("await"):
                    break
                case .keyword("init"), .keyword("subscript"),
                     .keyword("func") where lastKeyword != "import":
                    lastKeyword = ""
                    if classOrStatic {
                        if !isTypeRoot {
                            return // error
                        }
                        processFunction(at: &index, localNames: localNames, members: classMembers,
                                        typeStack: &typeStack, membersByType: &membersByType,
                                        classMembersByType: &classMembersByType,
                                        removed: &removed, unremoved: &unremoved,
                                        initRemoved: &initRemoved, initUnremoved: &initUnremoved)
                        classOrStatic = false
                    } else {
                        processFunction(at: &index, localNames: localNames, members: members,
                                        typeStack: &typeStack, membersByType: &membersByType,
                                        classMembersByType: &classMembersByType,
                                        removed: &removed, unremoved: &unremoved,
                                        initRemoved: &initRemoved, initUnremoved: &initUnremoved)
                    }
                    assert(formatter.token(at: index) != .endOfScope("}"))
                    continue
                case .keyword("static"):
                    classOrStatic = true
                case .keyword("class"):
                    if formatter.next(.nonSpaceOrCommentOrLinebreak, after: index)?.isIdentifier == true {
                        fallthrough
                    }
                    if formatter.last(.nonSpaceOrCommentOrLinebreak, before: index) != .delimiter(":") {
                        classOrStatic = true
                    }
                case .keyword("extension"), .keyword("struct"), .keyword("enum"):
                    guard formatter.last(.nonSpaceOrCommentOrLinebreak, before: index) != .keyword("import"),
                          let scopeStart = formatter.index(of: .startOfScope("{"), after: index) else { return }
                    guard let nameToken = formatter.next(.identifier, after: index),
                          case let .identifier(name) = nameToken
                    else {
                        return // error
                    }
                    // TODO: Add usingDynamicLookup logic from the main rule
                    index = scopeStart + 1
                    typeStack.append(name)
                    processBody(at: &index, localNames: ["init"], members: [], typeStack: &typeStack,
                                membersByType: &membersByType, classMembersByType: &classMembersByType,
                                removed: &removed, unremoved: &unremoved,
                                initRemoved: &initRemoved, initUnremoved: &initUnremoved,
                                isTypeRoot: true, isInit: false)
                    typeStack.removeLast()
                case .keyword("var"), .keyword("let"):
                    index += 1
                    switch lastKeyword {
                    case "lazy" where formatter.options.swiftVersion < "4":
                        loop: while let nextIndex =
                            formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index)
                        {
                            switch formatter.tokens[nextIndex] {
                            case .keyword("is"), .keyword("as"), .keyword("try"), .keyword("await"):
                                break
                            case .keyword, .startOfScope("{"):
                                break loop
                            default:
                                break
                            }
                            index = nextIndex
                        }
                        lastKeyword = ""
                    case "if", "while", "guard":
                        assert(!isTypeRoot)
                        // Guard is included because it's an error to reference guard vars in body
                        var scopedNames = localNames
                        formatter.processDeclaredVariables(at: &index, names: &scopedNames)
                        guard let startIndex = formatter.index(of: .startOfScope("{"), after: index) else {
                            return // error
                        }
                        index = startIndex + 1
                        processBody(at: &index, localNames: scopedNames, members: members, typeStack: &typeStack,
                                    membersByType: &membersByType, classMembersByType: &classMembersByType,
                                    removed: &removed, unremoved: &unremoved,
                                    initRemoved: &initRemoved, initUnremoved: &initUnremoved,
                                    isTypeRoot: false, isInit: isInit)
                        lastKeyword = ""
                    default:
                        lastKeyword = token.string
                    }
                    classOrStatic = false
                case .keyword("where") where lastKeyword == "in":
                    lastKeyword = ""
                    var localNames = localNames
                    guard let keywordIndex = formatter.index(of: .keyword, before: index),
                          let prevKeywordIndex = formatter.index(of: .keyword, before: keywordIndex),
                          let prevKeywordToken = formatter.token(at: prevKeywordIndex),
                          case .keyword("for") = prevKeywordToken else { return }
                    for token in formatter.tokens[prevKeywordIndex + 1 ..< keywordIndex] {
                        if case let .identifier(name) = token, name != "_" {
                            localNames.insert(token.unescaped())
                        }
                    }
                    index += 1
                    processBody(at: &index, localNames: localNames, members: members, typeStack: &typeStack,
                                membersByType: &membersByType, classMembersByType: &classMembersByType,
                                removed: &removed, unremoved: &unremoved,
                                initRemoved: &initRemoved, initUnremoved: &initUnremoved,
                                isTypeRoot: false, isInit: isInit)
                    continue
                case .keyword("while") where lastKeyword == "repeat":
                    lastKeyword = ""
                case let .keyword(name):
                    lastKeyword = name
                    lastKeywordIndex = index
                case .startOfScope("//"), .startOfScope("/*"):
                    if case let .commentBody(comment)? = formatter.next(.nonSpace, after: index) {
                        formatter.processCommentBody(comment, at: index)
                        if token == .startOfScope("//") {
                            formatter.processLinebreak()
                        }
                    }
                    index = formatter.endOfScope(at: index) ?? (formatter.tokens.count - 1)
                case .startOfScope("("):
                    if case let .identifier(fn)? = formatter.last(.nonSpaceOrCommentOrLinebreak, before: index),
                       selfRequired.contains(fn) || fn == "expect"
                    {
                        index = formatter.index(of: .endOfScope(")"), after: index) ?? index
                        break
                    }
                    fallthrough
                case .startOfScope where token.isStringDelimiter, .startOfScope("#if"):
                    scopeStack.append(token)
                case .startOfScope(":"):
                    lastKeyword = ""
                case .startOfScope("{") where lastKeyword == "catch":
                    lastKeyword = ""
                    var localNames = localNames
                    localNames.insert("error") // Implicit error argument
                    index += 1
                    processBody(at: &index, localNames: localNames, members: members, typeStack: &typeStack,
                                membersByType: &membersByType, classMembersByType: &classMembersByType,
                                removed: &removed, unremoved: &unremoved,
                                initRemoved: &initRemoved, initUnremoved: &initUnremoved,
                                isTypeRoot: false, isInit: isInit)
                    continue
                case .startOfScope("{") where lastKeyword == "in":
                    lastKeyword = ""
                    var localNames = localNames
                    guard let keywordIndex = formatter.index(of: .keyword, before: index),
                          let prevKeywordIndex = formatter.index(of: .keyword, before: keywordIndex),
                          let prevKeywordToken = formatter.token(at: prevKeywordIndex),
                          case .keyword("for") = prevKeywordToken else { return }
                    for token in formatter.tokens[prevKeywordIndex + 1 ..< keywordIndex] {
                        if case let .identifier(name) = token, name != "_" {
                            localNames.insert(token.unescaped())
                        }
                    }
                    index += 1
                    if classOrStatic {
                        assert(isTypeRoot)
                        processBody(at: &index, localNames: localNames, members: classMembers, typeStack: &typeStack,
                                    membersByType: &membersByType, classMembersByType: &classMembersByType,
                                    removed: &removed, unremoved: &unremoved,
                                    initRemoved: &initRemoved, initUnremoved: &initUnremoved,
                                    isTypeRoot: false, isInit: false)
                        classOrStatic = false
                    } else {
                        processBody(at: &index, localNames: localNames, members: members, typeStack: &typeStack,
                                    membersByType: &membersByType, classMembersByType: &classMembersByType,
                                    removed: &removed, unremoved: &unremoved,
                                    initRemoved: &initRemoved, initUnremoved: &initUnremoved,
                                    isTypeRoot: false, isInit: isInit)
                    }
                    continue
                case .startOfScope("{") where isWhereClause:
                    return
                case .startOfScope("{") where lastKeyword == "switch":
                    lastKeyword = ""
                    index += 1
                    loop: while let token = formatter.token(at: index) {
                        index += 1
                        switch token {
                        case .endOfScope("case"), .endOfScope("default"):
                            let localNames = localNames
                            processBody(at: &index, localNames: localNames, members: members, typeStack: &typeStack,
                                        membersByType: &membersByType, classMembersByType: &classMembersByType,
                                        removed: &removed, unremoved: &unremoved,
                                        initRemoved: &initRemoved, initUnremoved: &initUnremoved,
                                        isTypeRoot: false, isInit: isInit)
                            index -= 1
                        case .endOfScope("}"):
                            break loop
                        default:
                            break
                        }
                    }
                case .startOfScope("{") where ["for", "where", "if", "else", "while", "do"].contains(lastKeyword):
                    if let scopeIndex = formatter.index(of: .startOfScope, before: index), scopeIndex > lastKeywordIndex {
                        index = formatter.endOfScope(at: index) ?? (formatter.tokens.count - 1)
                        break
                    }
                    lastKeyword = ""
                    fallthrough
                case .startOfScope("{") where lastKeyword == "repeat":
                    index += 1
                    processBody(at: &index, localNames: localNames, members: members, typeStack: &typeStack,
                                membersByType: &membersByType, classMembersByType: &classMembersByType,
                                removed: &removed, unremoved: &unremoved,
                                initRemoved: &initRemoved, initUnremoved: &initUnremoved,
                                isTypeRoot: false, isInit: isInit)
                    continue
                case .startOfScope("{") where lastKeyword == "var":
                    lastKeyword = ""
                    if formatter.isStartOfClosure(at: index, in: scopeStack.last) {
                        fallthrough
                    }
                    var prevIndex = index - 1
                    var name: String?
                    while let token = formatter.token(at: prevIndex), token != .keyword("var") {
                        if token.isLvalue, let nextToken = formatter.nextToken(after: prevIndex, where: {
                            !$0.isSpaceOrCommentOrLinebreak && !$0.isStartOfScope
                        }), nextToken.isRvalue, !nextToken.isOperator(".") {
                            // It's a closure
                            fallthrough
                        }
                        if case let .identifier(_name) = token {
                            // Is the declared variable
                            name = _name
                        }
                        prevIndex -= 1
                    }
                    if let name = name {
                        processAccessors(["get", "set", "willSet", "didSet"], for: name,
                                         at: &index, localNames: localNames, members: members,
                                         typeStack: &typeStack, membersByType: &membersByType,
                                         classMembersByType: &classMembersByType,
                                         removed: &removed, unremoved: &unremoved,
                                         initRemoved: &initRemoved, initUnremoved: &initUnremoved)
                    }
                    continue
                case .startOfScope:
                    index = formatter.endOfScope(at: index) ?? (formatter.tokens.count - 1)
                case .identifier("self"):
                    guard !isTypeRoot, !localNames.contains("self"),
                          let dotIndex = formatter.index(of: .nonSpaceOrLinebreak, after: index, if: {
                              $0 == .operator(".", .infix)
                          }),
                          let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: dotIndex),
                          let name = formatter.token(at: nextIndex)?.unescaped(),
                          !localNames.contains(name), !selfRequired.contains(name),
                          !_FormatRules.globalSwiftFunctions.contains(name)
                    else {
                        break
                    }
                    if isInit {
                        if formatter.next(.nonSpaceOrCommentOrLinebreak, after: nextIndex) == .operator("=", .infix) {
                            initUnremoved += 1
                        } else if let scopeEnd = formatter.index(of: .endOfScope(")"), after: nextIndex),
                                  formatter.next(.nonSpaceOrCommentOrLinebreak, after: scopeEnd) == .operator("=", .infix)
                        {
                            initUnremoved += 1
                        } else {
                            unremoved += 1
                        }
                    } else {
                        unremoved += 1
                    }
                case .identifier("type"): // Special case for type(of:)
                    guard let parenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index, if: {
                        $0 == .startOfScope("(")
                    }), formatter.next(.nonSpaceOrCommentOrLinebreak, after: parenIndex) == .identifier("of") else {
                        fallthrough
                    }
                case .identifier:
                    guard !isTypeRoot else {
                        break
                    }
                    let isAssignment: Bool
                    if ["for", "var", "let"].contains(lastKeyword),
                       let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: index)
                    {
                        switch prevToken {
                        case .identifier, .number,
                             .operator where ![.operator("=", .infix), .operator(".", .prefix)].contains(prevToken),
                             .endOfScope where prevToken.isStringDelimiter:
                            isAssignment = false
                            lastKeyword = ""
                        default:
                            isAssignment = true
                        }
                    } else {
                        isAssignment = false
                    }
                    if !isAssignment, token.string == "lazy" {
                        lastKeyword = "lazy"
                        lastKeywordIndex = index
                    }
                    let name = token.unescaped()
                    guard members.contains(name), !localNames.contains(name), !isAssignment ||
                        formatter.last(.nonSpaceOrCommentOrLinebreak, before: index) == .operator("=", .infix),
                        formatter.next(.nonSpaceOrComment, after: index) != .delimiter(":")
                    else {
                        break
                    }
                    if let lastToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: index),
                       lastToken.isOperator(".")
                    {
                        break
                    }
                    if isInit {
                        if formatter.next(.nonSpaceOrCommentOrLinebreak, after: index) == .operator("=", .infix) {
                            initRemoved += 1
                        } else if let scopeEnd = formatter.index(of: .endOfScope(")"), after: index),
                                  formatter.next(.nonSpaceOrCommentOrLinebreak, after: scopeEnd) == .operator("=", .infix)
                        {
                            initRemoved += 1
                        } else {
                            removed += 1
                        }
                    } else {
                        removed += 1
                    }
                case .endOfScope("case"), .endOfScope("default"):
                    return
                case .endOfScope:
                    if token == .endOfScope("#endif") {
                        while let scope = scopeStack.last {
                            scopeStack.removeLast()
                            if scope != .startOfScope("#if") {
                                break
                            }
                        }
                    } else if let scope = scopeStack.last {
                        assert(token.isEndOfScope(scope))
                        scopeStack.removeLast()
                    } else {
                        assert(token.isEndOfScope(formatter.currentScope(at: index)!))
                        index += 1
                        return
                    }
                case .linebreak:
                    formatter.processLinebreak()
                default:
                    break
                }
                index += 1
            }
        }
        func processAccessors(_ names: [String], for name: String, at index: inout Int,
                              localNames: Set<String>, members: Set<String>,
                              typeStack: inout [String],
                              membersByType: inout [String: Set<String>],
                              classMembersByType: inout [String: Set<String>],
                              removed: inout Int, unremoved: inout Int,
                              initRemoved: inout Int, initUnremoved: inout Int)
        {
            var foundAccessors = false
            var localNames = localNames
            while let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index, if: {
                if case let .identifier(name) = $0, names.contains(name) { return true } else { return false }
            }), let startIndex = formatter.index(of: .startOfScope("{"), after: nextIndex) {
                foundAccessors = true
                index = startIndex + 1
                if let parenStart = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: nextIndex, if: {
                    $0 == .startOfScope("(")
                }), let varToken = formatter.next(.identifier, after: parenStart) {
                    localNames.insert(varToken.unescaped())
                } else {
                    switch formatter.tokens[nextIndex].string {
                    case "get":
                        localNames.insert(name)
                    case "set":
                        localNames.insert(name)
                        localNames.insert("newValue")
                    case "willSet":
                        localNames.insert("newValue")
                    case "didSet":
                        localNames.insert("oldValue")
                    default:
                        break
                    }
                }
                processBody(at: &index, localNames: localNames, members: members, typeStack: &typeStack,
                            membersByType: &membersByType, classMembersByType: &classMembersByType,
                            removed: &removed, unremoved: &unremoved,
                            initRemoved: &initRemoved, initUnremoved: &initUnremoved,
                            isTypeRoot: false, isInit: false)
            }
            if foundAccessors {
                guard let endIndex = formatter.index(of: .endOfScope("}"), after: index) else { return }
                index = endIndex + 1
            } else {
                index += 1
                localNames.insert(name)
                processBody(at: &index, localNames: localNames, members: members, typeStack: &typeStack,
                            membersByType: &membersByType, classMembersByType: &classMembersByType,
                            removed: &removed, unremoved: &unremoved,
                            initRemoved: &initRemoved, initUnremoved: &initUnremoved,
                            isTypeRoot: false, isInit: false)
            }
        }
        func processFunction(at index: inout Int, localNames: Set<String>, members: Set<String>,
                             typeStack: inout [String],
                             membersByType: inout [String: Set<String>],
                             classMembersByType: inout [String: Set<String>],
                             removed: inout Int, unremoved: inout Int,
                             initRemoved: inout Int, initUnremoved: inout Int)
        {
            let startToken = formatter.tokens[index]
            var localNames = localNames
            guard let startIndex = formatter.index(of: .startOfScope("("), after: index),
                  let endIndex = formatter.index(of: .endOfScope(")"), after: startIndex)
            else {
                index += 1 // Prevent endless loop
                return
            }
            // Get argument names
            index = startIndex
            while index < endIndex {
                guard let externalNameIndex = formatter.index(of: .identifier, after: index),
                      let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: externalNameIndex)
                else { break }
                let token = formatter.tokens[nextIndex]
                switch token {
                case let .identifier(name) where name != "_":
                    localNames.insert(token.unescaped())
                case .delimiter(":"):
                    let externalNameToken = formatter.tokens[externalNameIndex]
                    if case let .identifier(name) = externalNameToken, name != "_" {
                        localNames.insert(externalNameToken.unescaped())
                    }
                default:
                    break
                }
                index = formatter.index(of: .delimiter(","), after: index) ?? endIndex
            }
            guard let bodyStartIndex = formatter.index(after: endIndex, where: {
                switch $0 {
                case .startOfScope("{"): // What we're looking for
                    return true
                case .keyword("throws"),
                     .keyword("rethrows"),
                     .keyword("where"),
                     .keyword("is"):
                    return false // Keep looking
                case .keyword:
                    return true // Not valid between end of arguments and start of body
                default:
                    return false // Keep looking
                }
            }), formatter.tokens[bodyStartIndex] == .startOfScope("{") else {
                return
            }
            if startToken == .keyword("subscript") {
                index = bodyStartIndex
                processAccessors(["get", "set"], for: "", at: &index, localNames: localNames,
                                 members: members, typeStack: &typeStack, membersByType: &membersByType,
                                 classMembersByType: &classMembersByType,
                                 removed: &removed, unremoved: &unremoved,
                                 initRemoved: &initRemoved, initUnremoved: &initUnremoved)
            } else {
                index = bodyStartIndex + 1
                processBody(at: &index,
                            localNames: localNames,
                            members: members,
                            typeStack: &typeStack,
                            membersByType: &membersByType,
                            classMembersByType: &classMembersByType,
                            removed: &removed, unremoved: &unremoved,
                            initRemoved: &initRemoved, initUnremoved: &initUnremoved,
                            isTypeRoot: false,
                            isInit: startToken == .keyword("init"))
            }
        }
        var removed = 0, unremoved = 0
        var initRemoved = 0, initUnremoved = 0
        var typeStack = [String]()
        var membersByType = [String: Set<String>]()
        var classMembersByType = [String: Set<String>]()
        var index = 0
        processBody(at: &index, localNames: ["init"], members: [], typeStack: &typeStack,
                    membersByType: &membersByType, classMembersByType: &classMembersByType,
                    removed: &removed, unremoved: &unremoved, initRemoved: &initRemoved,
                    initUnremoved: &initUnremoved, isTypeRoot: false, isInit: false)
        // if both zero or equal, should be true
        if removed >= unremoved {
            options.explicitSelf = (initRemoved >= initUnremoved ? .remove : .initOnly)
        } else {
            options.explicitSelf = .insert
        }
    }

    let spaceAroundOperatorDeclarations = OptionInferrer { formatter, options in
        var space = 0, nospace = 0
        formatter.forEach(.operator) { i, token in
            guard case .operator(_, .none) = token,
                  formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) == .keyword("func"),
                  let token = formatter.token(at: i + 1)
            else {
                return
            }
            if token.isSpaceOrLinebreak {
                space += 1
            } else {
                nospace += 1
            }
        }
        options.spaceAroundOperatorDeclarations = (nospace <= space)
    }

    let elseOnNextLine = OptionInferrer { formatter, options in
        var sameLine = 0, nextLine = 0
        formatter.forEach(.keyword) { i, token in
            guard ["else", "catch", "while"].contains(token.string) else { return }
            // Check for brace
            guard let braceIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i, if: {
                $0 == .endOfScope("}")
            }) else { return }
            // Check this isn't an inline block
            guard let prevBraceIndex = formatter.index(of: .startOfScope("{"), before: braceIndex),
                  formatter.lastIndex(of: .linebreak, in: prevBraceIndex + 1 ..< braceIndex) != nil
            else {
                return
            }
            // Check if wrapped
            if formatter.lastIndex(of: .linebreak, in: braceIndex + 1 ..< i) != nil {
                nextLine += 1
            } else {
                sameLine += 1
            }
        }
        options.elseOnNextLine = (sameLine < nextLine)
    }

    let indentCase = OptionInferrer { formatter, options in
        var indent = 0, noindent = 0
        formatter.forEach(.keyword("switch")) { i, _ in
            var switchIndent = ""
            if let token = formatter.token(at: i - 1), !token.isLinebreak {
                guard case let .space(space) = token, formatter.token(at: i - 2)?.isLinebreak != false else {
                    return
                }
                switchIndent = space
            }
            guard let openBraceIndex = formatter.index(of: .startOfScope("{"), after: i),
                  let caseIndex = formatter.index(of: .endOfScope("case"), after: openBraceIndex) ??
                  formatter.index(of: .endOfScope("default"), after: openBraceIndex),
                  let indentToken = formatter.token(at: caseIndex - 1)
            else {
                return
            }
            switch indentToken {
            case .linebreak, .space(switchIndent):
                noindent += 1
            case let .space(caseIndent) where caseIndent.hasPrefix(switchIndent):
                indent += 1
            default:
                break
            }
        }
        options.indentCase = (indent > noindent)
    }
}

private extension Formatter {
    func wrapMode(forParameters parameters: Bool) -> WrapMode {
        var beforeFirst = 0, afterFirst = 0
        forEachToken(where: { [.startOfScope("("), .startOfScope("<")].contains($0) }) { i, _ in
            guard isParameterList(at: i) == parameters,
                  let closingBraceIndex = endOfScope(at: i),
                  index(of: .linebreak, in: i + 1 ..< closingBraceIndex) != nil
            else {
                return
            }
            // Check if linebreak is after opening paren or first comma
            if next(.nonSpaceOrComment, after: i)?.isLinebreak == true {
                beforeFirst += 1
            } else {
                afterFirst += 1
            }
        }
        if beforeFirst > 0, afterFirst == 0 {
            return .beforeFirst
        } else if afterFirst > 0, beforeFirst == 0 {
            return .afterFirst
        } else {
            return parameters ? .default : .preserve
        }
    }

    func wrapMode(for scopes: String...) -> WrapMode {
        var beforeFirst = 0, afterFirst = 0
        forEachToken(where: { $0.isStartOfScope && scopes.contains($0.string) }) { i, _ in
            guard let closingBraceIndex = endOfScope(at: i),
                  index(of: .linebreak, in: i + 1 ..< closingBraceIndex) != nil
            else {
                return
            }
            // Check if linebreak is after opening paren or first comma
            if next(.nonSpaceOrComment, after: i)?.isLinebreak == true {
                beforeFirst += 1
            } else {
                afterFirst += 1
            }
        }
        if beforeFirst > 0, afterFirst == 0 {
            return .beforeFirst
        } else if afterFirst > 0, beforeFirst == 0 {
            return .afterFirst
        } else {
            return .preserve
        }
    }

    func grouping(for numberType: NumberType) -> Grouping {
        var grouping = [(group: Int, threshold: Int, count: Int)](), lowest = Int.max
        forEachToken { _, token in
            guard case let .number(number, type) = token else {
                return
            }
            guard numberType == type || numberType == .decimal && type == .integer else {
                return
            }
            // Strip prefix/suffix
            let digits: String
            let prefix = "0x"
            switch type {
            case .integer:
                digits = number
            case .binary, .octal:
                digits = String(number[prefix.endIndex...])
            case .hex:
                let endIndex = number.firstIndex { [".", "p", "P"].contains($0) } ?? number.endIndex
                digits = String(number[prefix.endIndex ..< endIndex])
            case .decimal:
                let endIndex = number.firstIndex { [".", "e", "E"].contains($0) } ?? number.endIndex
                digits = String(number[..<endIndex])
            }
            // Get the group for this number
            var count = 0
            var index = digits.endIndex
            var group = 0
            repeat {
                index = digits.index(before: index)
                if digits[index] == "_" {
                    if group == 0, count > 0 {
                        group = count
                        lowest = min(lowest, group + 1)
                    }
                } else {
                    count += 1
                }
            } while index != digits.startIndex
            // Add To groups list
            var found = false
            if group > 0 {
                for (i, g) in grouping.enumerated() {
                    if g.group == group {
                        grouping[i] = (group, min(g.threshold, count), g.count + 1)
                        found = true
                        break
                    }
                }
            }
            if !found {
                grouping.append((group, count, 1))
            }
        }
        // Only count none values whose threshold > lowest group value
        var none = 0, maxCount = 0, total = 0
        var group = (group: 0, threshold: 0, count: 0)
        grouping = grouping.filter {
            if $0.group == 0 {
                if $0.threshold >= lowest {
                    none += 1
                }
                return false
            }
            total += $0.count
            if $0.count > maxCount {
                maxCount = $0.count
                group = $0
            }
            return true
        }
        // Return most common
        if group.count >= max(1, none) {
            if group.count > total / 2 {
                return .group(group.group, group.threshold)
            }
            return .ignore
        }
        return .none
    }

    enum NumberPart {
        case fraction
        case exponent
    }

    // TODO: ensure dependent options have been inferred already
    func hasGrouping(for part: NumberPart) -> Bool {
        var grouped = 0, ungrouped = 0
        forEachToken { _, token in
            guard case let .number(number, type) = token else {
                return
            }
            let exp: String
            let grouping: Grouping
            switch type {
            case .integer, .binary, .octal:
                return
            case .hex:
                exp = "pP"
                grouping = options.hexGrouping
            case .decimal:
                exp = "eE"
                grouping = options.decimalGrouping
            }
            let target: String
            switch part {
            case .fraction where number.contains("."):
                target = number.components(separatedBy: CharacterSet(charactersIn: ".\(exp)"))[1]
            case .exponent where number.contains(where: { exp.contains($0) }):
                target = number.components(separatedBy: CharacterSet(charactersIn: ".\(exp)")).last!
            default:
                return
            }
            if target.contains("_") {
                grouped += 1
            } else if case let .group(_, threshold) = grouping, target.count >= threshold {
                ungrouped += 1
            }
        }
        return grouped > ungrouped
    }
}

extension Inference {
    static let all: [String] = {
        // Deliberately not sorted alphabetically due to dependencies
        // TODO: find a proper solution for the dependencies issue
        var names = [String]()
        for (label, _) in Mirror(reflecting: Inference()).children {
            if let name = label {
                names.append(name)
            }
        }
        return names
    }()

    static let byName: [String: OptionInferrer] = {
        var inferrers = [String: OptionInferrer]()
        for (label, value) in Mirror(reflecting: Inference()).children {
            guard let name = label, let inferrer = value as? OptionInferrer else {
                continue
            }
            inferrers[name] = inferrer
        }
        return inferrers
    }()
}
