//
//  Rules.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 12/08/2016.
//  Copyright 2016 Nick Lockwood
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

public final class FormatRule: Equatable, Comparable {
    private let fn: (Formatter) -> Void
    fileprivate(set) var name = ""
    fileprivate(set) var index = 0
    let help: String
    let runOnceOnly: Bool
    let disabledByDefault: Bool
    let orderAfter: [String]
    let options: [String]
    let sharedOptions: [String]
    let deprecationMessage: String?

    var isDeprecated: Bool {
        return deprecationMessage != nil
    }

    fileprivate init(help: String,
                     deprecationMessage: String? = nil,
                     runOnceOnly: Bool = false,
                     disabledByDefault: Bool = false,
                     orderAfter: [String] = [],
                     options: [String] = [],
                     sharedOptions: [String] = [],
                     _ fn: @escaping (Formatter) -> Void)
    {
        self.fn = fn
        self.help = help
        self.runOnceOnly = runOnceOnly
        self.disabledByDefault = disabledByDefault || deprecationMessage != nil
        self.orderAfter = orderAfter
        self.options = options
        self.sharedOptions = sharedOptions
        self.deprecationMessage = deprecationMessage
    }

    public func apply(with formatter: Formatter) {
        formatter.currentRule = self
        fn(formatter)
        formatter.currentRule = nil
    }

    public static func == (lhs: FormatRule, rhs: FormatRule) -> Bool {
        return lhs === rhs
    }

    public static func < (lhs: FormatRule, rhs: FormatRule) -> Bool {
        return lhs.index < rhs.index
    }
}

public let FormatRules = _FormatRules()

private let rulesByName: [String: FormatRule] = {
    var rules = [String: FormatRule]()
    for (label, value) in Mirror(reflecting: FormatRules).children {
        guard let name = label, let rule = value as? FormatRule else {
            continue
        }
        rule.name = name
        rules[name] = rule
    }
    let values = rules.values.sorted(by: { $0.name < $1.name })
    for (index, value) in values.enumerated() {
        value.index = index * 10
    }
    var changedOrder = true
    while changedOrder {
        changedOrder = false
        for value in values {
            value.orderAfter.forEach { name in
                guard let rule = rules[name] else {
                    preconditionFailure(name)
                }
                if rule.index >= value.index {
                    value.index = rule.index + 1
                    changedOrder = true
                }
            }
        }
    }
    return rules
}()

private func allRules(except rules: [String]) -> [FormatRule] {
    precondition(!rules.contains(where: { rulesByName[$0] == nil }))
    return Array(rulesByName.keys.sorted().compactMap {
        rules.contains($0) ? nil : rulesByName[$0]
    })
}

private let _allRules = allRules(except: [])
private let _disabledByDefault = _allRules.filter { $0.disabledByDefault }.map { $0.name }
private let _defaultRules = allRules(except: _disabledByDefault)

public extension _FormatRules {
    /// A Dictionary of rules by name
    var byName: [String: FormatRule] { return rulesByName }

    /// All rules
    var all: [FormatRule] { return _allRules }

    /// Default active rules
    var `default`: [FormatRule] { return _defaultRules }

    /// Rules that are disabled by default
    var disabledByDefault: [String] { return _disabledByDefault }

    /// Just the specified rules
    func named(_ names: [String]) -> [FormatRule] {
        return Array(names.sorted().compactMap { rulesByName[$0] })
    }

    /// All rules except those specified
    func all(except rules: [String]) -> [FormatRule] {
        return allRules(except: rules)
    }
}

extension _FormatRules {
    /// Get all format options used by a given set of rules
    func optionsForRules(_ rules: [FormatRule]) -> [String] {
        var options = Set<String>()
        for rule in rules {
            options.formUnion(rule.options + rule.sharedOptions)
        }
        return options.sorted()
    }

    // Get shared-only options for a given set of rules
    func sharedOptionsForRules(_ rules: [FormatRule]) -> [String] {
        var options = Set<String>()
        var sharedOptions = Set<String>()
        for rule in rules {
            options.formUnion(rule.options)
            sharedOptions.formUnion(rule.sharedOptions)
        }
        sharedOptions.subtract(options)
        return sharedOptions.sorted()
    }
}

public struct _FormatRules {
    fileprivate init() {}

    /// Implement the following rules with respect to the spacing around parens:
    /// * There is no space between an opening paren and the preceding identifier,
    ///   unless the identifier is one of the specified keywords
    /// * There is no space between an opening paren and the preceding closing brace
    /// * There is no space between an opening paren and the preceding closing square bracket
    /// * There is space between a closing paren and following identifier
    /// * There is space between a closing paren and following opening brace
    /// * There is no space between a closing paren and following opening square bracket
    public let spaceAroundParens = FormatRule(
        help: "Add or remove space around parentheses."
    ) { formatter in
        func spaceAfter(_ keyword: String, index: Int) -> Bool {
            switch keyword {
            case "@autoclosure":
                if let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: index),
                   formatter.next(.nonSpaceOrCommentOrLinebreak, after: nextIndex) == .identifier("escaping")
                {
                    assert(formatter.tokens[nextIndex] == .startOfScope("("))
                    return false
                }
                return true
            case "@escaping", "@noescape":
                return true
            case "private", "fileprivate", "internal",
                 "init", "subscript":
                return false
            default:
                return keyword.first.map { !"@#".contains($0) } ?? true
            }
        }

        formatter.forEach(.startOfScope("(")) { i, token in
            guard let prevToken = formatter.token(at: i - 1) else {
                return
            }
            switch prevToken {
            case let .keyword(string) where spaceAfter(string, index: i - 1):
                fallthrough
            case .endOfScope("]") where formatter.isInClosureArguments(at: i - 1),
                 .endOfScope(")") where formatter.isAttribute(at: i - 1):
                formatter.insert(.space(" "), at: i)
            case .space:
                if let token = formatter.token(at: i - 2) {
                    switch token {
                    case let .keyword(string) where !spaceAfter(string, index: i - 2):
                        fallthrough
                    case .identifier, .number:
                        fallthrough
                    case .endOfScope("}"), .endOfScope(">"),
                         .endOfScope("]") where !formatter.isInClosureArguments(at: i - 2),
                         .endOfScope(")") where !formatter.isAttribute(at: i - 2):
                        formatter.removeToken(at: i - 1)
                    default:
                        break
                    }
                }
            default:
                break
            }
        }
        formatter.forEach(.endOfScope(")")) { i, _ in
            guard let nextToken = formatter.token(at: i + 1) else {
                return
            }
            switch nextToken {
            case .identifier, .keyword, .startOfScope("{"):
                formatter.insert(.space(" "), at: i + 1)
            case .space where formatter.token(at: i + 2) == .startOfScope("["):
                formatter.removeToken(at: i + 1)
            default:
                break
            }
        }
    }

    /// Remove space immediately inside parens
    public let spaceInsideParens = FormatRule(
        help: "Remove space inside parentheses."
    ) { formatter in
        formatter.forEach(.startOfScope("(")) { i, _ in
            if formatter.token(at: i + 1)?.isSpace == true,
               formatter.token(at: i + 2)?.isComment == false
            {
                formatter.removeToken(at: i + 1)
            }
        }
        formatter.forEach(.endOfScope(")")) { i, _ in
            if formatter.token(at: i - 1)?.isSpace == true,
               formatter.token(at: i - 2)?.isCommentOrLinebreak == false
            {
                formatter.removeToken(at: i - 1)
            }
        }
    }

    /// Implement the following rules with respect to the spacing around square brackets:
    /// * There is no space between an opening bracket and the preceding identifier,
    ///   unless the identifier is one of the specified keywords
    /// * There is no space between an opening bracket and the preceding closing brace
    /// * There is no space between an opening bracket and the preceding closing square bracket
    /// * There is space between a closing bracket and following identifier
    /// * There is space between a closing bracket and following opening brace
    public let spaceAroundBrackets = FormatRule(
        help: "Add or remove space around square brackets."
    ) { formatter in
        formatter.forEach(.startOfScope("[")) { i, token in
            guard let prevToken = formatter.token(at: i - 1) else {
                return
            }
            switch prevToken {
            case .keyword:
                formatter.insert(.space(" "), at: i)
            case .space:
                if let token = formatter.token(at: i - 2) {
                    switch token {
                    case .identifier, .number, .endOfScope("]"), .endOfScope("}"), .endOfScope(")"):
                        formatter.removeToken(at: i - 1)
                    default:
                        break
                    }
                }
            default:
                break
            }
        }
        formatter.forEach(.endOfScope("]")) { i, _ in
            guard let nextToken = formatter.token(at: i + 1) else {
                return
            }
            switch nextToken {
            case .identifier, .keyword, .startOfScope("{"),
                 .startOfScope("(") where formatter.isInClosureArguments(at: i):
                formatter.insert(.space(" "), at: i + 1)
            case .space:
                switch formatter.token(at: i + 2) {
                case .startOfScope("(")? where !formatter.isInClosureArguments(at: i + 2), .startOfScope("[")?:
                    formatter.removeToken(at: i + 1)
                default:
                    break
                }
            default:
                break
            }
        }
    }

    /// Remove space immediately inside square brackets
    public let spaceInsideBrackets = FormatRule(
        help: "Remove space inside square brackets."
    ) { formatter in
        formatter.forEach(.startOfScope("[")) { i, _ in
            if formatter.token(at: i + 1)?.isSpace == true,
               formatter.token(at: i + 2)?.isComment == false
            {
                formatter.removeToken(at: i + 1)
            }
        }
        formatter.forEach(.endOfScope("]")) { i, _ in
            if formatter.token(at: i - 1)?.isSpace == true,
               formatter.token(at: i - 2)?.isCommentOrLinebreak == false
            {
                formatter.removeToken(at: i - 1)
            }
        }
    }

    /// Ensure that there is space between an opening brace and the preceding
    /// identifier, and between a closing brace and the following identifier.
    public let spaceAroundBraces = FormatRule(
        help: "Add or remove space around curly braces."
    ) { formatter in
        formatter.forEach(.startOfScope("{")) { i, _ in
            if let prevToken = formatter.token(at: i - 1) {
                switch prevToken {
                case .space, .linebreak, .operator(_, .prefix), .operator(_, .infix),
                     .startOfScope where !prevToken.isStringDelimiter:
                    break
                default:
                    formatter.insert(.space(" "), at: i)
                }
            }
        }
        formatter.forEach(.endOfScope("}")) { i, _ in
            if let nextToken = formatter.token(at: i + 1) {
                switch nextToken {
                case .identifier, .keyword:
                    formatter.insert(.space(" "), at: i + 1)
                default:
                    break
                }
            }
        }
    }

    /// Ensure that there is space immediately inside braces
    public let spaceInsideBraces = FormatRule(
        help: "Add space inside curly braces."
    ) { formatter in
        formatter.forEach(.startOfScope("{")) { i, _ in
            if let nextToken = formatter.token(at: i + 1) {
                if !nextToken.isSpaceOrLinebreak,
                   ![.endOfScope("}"), .startOfScope("{")].contains(nextToken)
                {
                    formatter.insert(.space(" "), at: i + 1)
                }
            }
        }
        formatter.forEach(.endOfScope("}")) { i, _ in
            if let prevToken = formatter.token(at: i - 1) {
                if !prevToken.isSpaceOrLinebreak,
                   ![.endOfScope("}"), .startOfScope("{")].contains(prevToken)
                {
                    formatter.insert(.space(" "), at: i)
                }
            }
        }
    }

    /// Ensure there is no space between an opening chevron and the preceding identifier
    public let spaceAroundGenerics = FormatRule(
        help: "Remove space around angle brackets."
    ) { formatter in
        formatter.forEach(.startOfScope("<")) { i, _ in
            if formatter.token(at: i - 1)?.isSpace == true,
               formatter.token(at: i - 2)?.isIdentifierOrKeyword == true
            {
                formatter.removeToken(at: i - 1)
            }
        }
    }

    /// Remove space immediately inside chevrons
    public let spaceInsideGenerics = FormatRule(
        help: "Remove space inside angle brackets."
    ) { formatter in
        formatter.forEach(.startOfScope("<")) { i, _ in
            if formatter.token(at: i + 1)?.isSpace == true {
                formatter.removeToken(at: i + 1)
            }
        }
        formatter.forEach(.endOfScope(">")) { i, _ in
            if formatter.token(at: i - 1)?.isSpace == true,
               formatter.token(at: i - 2)?.isLinebreak == false
            {
                formatter.removeToken(at: i - 1)
            }
        }
    }

    /// Implement the following rules with respect to the spacing around operators:
    /// * Infix operators are separated from their operands by a space on either
    ///   side. Does not affect prefix/postfix operators, as required by syntax.
    /// * Delimiters, such as commas and colons, are consistently followed by a
    ///   single space, unless it appears at the end of a line, and is not
    ///   preceded by a space, unless it appears at the beginning of a line.
    public let spaceAroundOperators = FormatRule(
        help: "Add or remove space around operators or delimiters.",
        options: ["operatorfunc", "nospaceoperators", "ranges"]
    ) { formatter in
        formatter.forEachToken { i, token in
            switch token {
            case .operator(_, .none):
                switch formatter.token(at: i + 1) {
                case nil, .linebreak?, .endOfScope?, .operator?, .delimiter?,
                     .startOfScope("(")? where !formatter.options.spaceAroundOperatorDeclarations:
                    break
                case .space?:
                    switch formatter.next(.nonSpaceOrLinebreak, after: i) {
                    case nil, .linebreak?, .endOfScope?, .delimiter?,
                         .startOfScope("(")? where !formatter.options.spaceAroundOperatorDeclarations:
                        formatter.removeToken(at: i + 1)
                    default:
                        break
                    }
                default:
                    formatter.insert(.space(" "), at: i + 1)
                }
            case .operator("?", .postfix), .operator("!", .postfix):
                if let prevToken = formatter.token(at: i - 1),
                   formatter.token(at: i + 1)?.isSpaceOrLinebreak == false,
                   [.keyword("as"), .keyword("try")].contains(prevToken)
                {
                    formatter.insert(.space(" "), at: i + 1)
                }
            case .operator(".", _):
                if formatter.token(at: i + 1)?.isSpace == true {
                    formatter.removeToken(at: i + 1)
                }
                guard let prevIndex = formatter.index(of: .nonSpace, before: i) else {
                    formatter.removeTokens(in: 0 ..< i)
                    break
                }
                let spaceRequired: Bool
                switch formatter.tokens[prevIndex] {
                case .operator(_, .infix), .startOfScope:
                    return
                case let token where token.isUnwrapOperator:
                    if let prevToken = formatter.last(.nonSpace, before: prevIndex),
                       [.keyword("as"), .keyword("try")].contains(prevToken)
                    {
                        spaceRequired = true
                    } else {
                        spaceRequired = false
                    }
                case .operator(_, .prefix):
                    spaceRequired = false
                case let token:
                    spaceRequired = !token.isAttribute && !token.isLvalue
                }
                if formatter.token(at: i - 1)?.isSpaceOrLinebreak == true {
                    if !spaceRequired {
                        formatter.removeToken(at: i - 1)
                    }
                } else if spaceRequired {
                    formatter.insertSpace(" ", at: i)
                }
            case .operator("?", .infix):
                break // Spacing around ternary ? is not optional
            case let .operator(name, .infix) where formatter.options.noSpaceOperators.contains(name) ||
                (!formatter.options.spaceAroundRangeOperators && token.isRangeOperator):
                if formatter.token(at: i + 1)?.isSpace == true,
                   formatter.token(at: i - 1)?.isSpace == true,
                   let nextToken = formatter.next(.nonSpace, after: i),
                   !nextToken.isCommentOrLinebreak, !nextToken.isOperator,
                   let prevToken = formatter.last(.nonSpace, before: i),
                   !prevToken.isCommentOrLinebreak, !prevToken.isOperator || prevToken.isUnwrapOperator
                {
                    formatter.removeToken(at: i + 1)
                    formatter.removeToken(at: i - 1)
                }
            case .operator(_, .infix):
                if formatter.token(at: i + 1)?.isSpaceOrLinebreak == false {
                    formatter.insert(.space(" "), at: i + 1)
                }
                if formatter.token(at: i - 1)?.isSpaceOrLinebreak == false {
                    formatter.insert(.space(" "), at: i)
                }
            case .operator(_, .prefix):
                if let prevIndex = formatter.index(of: .nonSpace, before: i, if: {
                    [.startOfScope("["), .startOfScope("("), .startOfScope("<")].contains($0)
                }) {
                    formatter.removeTokens(in: prevIndex + 1 ..< i)
                } else if let prevToken = formatter.token(at: i - 1),
                          !prevToken.isSpaceOrLinebreak, !prevToken.isOperator
                {
                    formatter.insert(.space(" "), at: i)
                }
            case .delimiter(":"):
                // TODO: make this check more robust, and remove redundant space
                if formatter.token(at: i + 1)?.isIdentifier == true,
                   formatter.token(at: i + 2) == .delimiter(":")
                {
                    // It's a selector
                    break
                }
                fallthrough
            case .operator(_, .postfix), .delimiter(","), .delimiter(";"), .startOfScope(":"):
                switch formatter.token(at: i + 1) {
                case nil, .space?, .linebreak?, .endOfScope?, .operator?, .delimiter?:
                    break
                default:
                    // Ensure there is a space after the token
                    formatter.insert(.space(" "), at: i + 1)
                }
                if formatter.token(at: i - 1)?.isSpace == true,
                   formatter.token(at: i - 2)?.isLinebreak == false
                {
                    // Remove space before the token
                    formatter.removeToken(at: i - 1)
                }
            default:
                break
            }
        }
    }

    /// Add space around comments, except at the start or end of a line
    public let spaceAroundComments = FormatRule(
        help: "Add space before and/or after comments."
    ) { formatter in
        formatter.forEach(.startOfScope("//")) { i, _ in
            if let prevToken = formatter.token(at: i - 1), !prevToken.isSpaceOrLinebreak {
                formatter.insert(.space(" "), at: i)
            }
        }
        formatter.forEach(.endOfScope("*/")) { i, _ in
            guard let startIndex = formatter.index(of: .startOfScope("/*"), before: i),
                  case let .commentBody(commentStart)? = formatter.next(.nonSpaceOrLinebreak, after: startIndex),
                  case let .commentBody(commentEnd)? = formatter.last(.nonSpaceOrLinebreak, before: i),
                  !commentStart.hasPrefix("@"), !commentEnd.hasSuffix("@")
            else {
                return
            }
            if let nextToken = formatter.token(at: i + 1) {
                if !nextToken.isSpaceOrLinebreak {
                    if nextToken != .delimiter(",") {
                        formatter.insert(.space(" "), at: i + 1)
                    }
                } else if formatter.next(.nonSpace, after: i + 1) == .delimiter(",") {
                    formatter.removeToken(at: i + 1)
                }
            }
            if let prevToken = formatter.token(at: startIndex - 1), !prevToken.isSpaceOrLinebreak {
                if case let .commentBody(text) = prevToken, text.last?.unicodeScalars.last?.isSpace == true {
                    return
                }
                formatter.insert(.space(" "), at: startIndex)
            }
        }
    }

    /// Add space inside comments, taking care not to mangle headerdoc or
    /// carefully preformatted comments, such as star boxes, etc.
    public let spaceInsideComments = FormatRule(
        help: "Add leading and/or trailing space inside comments."
    ) { formatter in
        formatter.forEach(.startOfScope("//")) { i, _ in
            guard case let .commentBody(string)? = formatter.token(at: i + 1),
                  let first = string.first else { return }
            if "/!:".contains(first) {
                let nextIndex = string.index(after: string.startIndex)
                if nextIndex < string.endIndex, case let next = string[nextIndex], !" \t/".contains(next) {
                    let string = String(string.first!) + " " + String(string.dropFirst())
                    formatter.replaceToken(at: i + 1, with: .commentBody(string))
                }
            } else if !" \t".contains(first), !string.hasPrefix("===") { // Special-case check for swift stdlib codebase
                formatter.insert(.space(" "), at: i + 1)
            }
        }
        formatter.forEach(.startOfScope("/*")) { i, _ in
            guard case let .commentBody(string)? = formatter.token(at: i + 1),
                  !string.hasPrefix("---"), !string.hasPrefix("@"), !string.hasSuffix("---"), !string.hasSuffix("@")
            else {
                return
            }
            if let first = string.first, "*!:".contains(first) {
                let nextIndex = string.index(after: string.startIndex)
                if nextIndex < string.endIndex, case let next = string[nextIndex],
                   !" /t".contains(next), !string.hasPrefix("**"), !string.hasPrefix("*/")
                {
                    let string = String(string.first!) + " " + String(string.dropFirst())
                    formatter.replaceToken(at: i + 1, with: .commentBody(string))
                }
            } else {
                formatter.insert(.space(" "), at: i + 1)
            }
            if let i = formatter.index(of: .endOfScope("*/"), after: i), let prevToken = formatter.token(at: i - 1) {
                if !prevToken.isSpaceOrLinebreak, !prevToken.string.hasSuffix("*"),
                   !prevToken.string.trimmingCharacters(in: .whitespaces).isEmpty
                {
                    formatter.insert(.space(" "), at: i)
                }
            }
        }
    }

    /// Removes explicit type declarations from initialization declarations
    public let redundantType = FormatRule(
        help: "Remove redundant type from variable declarations.",
        options: ["redundanttype"]
    ) { formatter in
        formatter.forEachToken(where: { (token) -> Bool in
            token == .keyword("var") || token == .keyword("let")
        }) { i, _ in
            guard let colonIndex = formatter.index(after: i, where: {
                [.delimiter(":"), .operator("=", .infix)].contains($0)
            }), formatter.tokens[colonIndex] == .delimiter(":"),
            let equalsIndex = formatter.index(of: .operator("=", .infix), after: colonIndex),
            let typeEndIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: equalsIndex)
            else { return }

            // Check types match
            var i = colonIndex, j = equalsIndex
            while let typeIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i),
                  typeIndex <= typeEndIndex,
                  let valueIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: j)
            {
                guard formatter.tokens[typeIndex] == formatter.tokens[valueIndex] else {
                    return
                }
                i = typeIndex
                j = valueIndex
            }
            guard i == typeEndIndex else {
                return
            }

            // Check for ternary
            if let endOfExpression = formatter.endOfExpression(at: j, upTo: [.operator("?", .infix)]),
               formatter.next(.nonSpaceOrCommentOrLinebreak, after: endOfExpression) == .operator("?", .infix)
            {
                return
            }

            switch formatter.options.redundantType {
            case .inferred:
                formatter.removeTokens(in: colonIndex ... typeEndIndex)
                if formatter.tokens[colonIndex - 1].isSpace {
                    formatter.removeToken(at: colonIndex - 1)
                }
            case .explicit:
                guard let valueStartIndex = formatter
                    .index(of: .nonSpaceOrCommentOrLinebreak, after: equalsIndex),
                    !formatter.isConditionalStatement(at: i)
                else { break }
                if formatter.nextToken(after: j) == .startOfScope("(") {
                    formatter.replaceTokens(in: valueStartIndex ... j, with: [.operator(".", .infix), .identifier("init")])
                } else if
                    // check for `= Type.identifier` or `= Type.identifier()`
                    formatter.token(at: j + 1) == .operator(".", .infix),
                    formatter.endOfExpression(at: j + 1, upTo: []) == j + 2 ||
                    (formatter.token(at: j + 3) == .startOfScope("(") && formatter.token(at: j + 4) == .endOfScope(")"))
                {
                    formatter.removeTokens(in: valueStartIndex ... j)
                }
            }
        }
    }

    /// Collapse all consecutive space characters to a single space, except at
    /// the start of a line or inside a comment or string, as these have no semantic
    /// meaning and lead to noise in commits.
    public let consecutiveSpaces = FormatRule(
        help: "Replace consecutive spaces with a single space."
    ) { formatter in
        formatter.forEach(.space) { i, token in
            switch token {
            case .space(""):
                formatter.removeToken(at: i)
            case .space(" "):
                break
            default:
                guard let prevToken = formatter.token(at: i - 1),
                      let nextToken = formatter.token(at: i + 1)
                else {
                    return
                }
                switch prevToken {
                case .linebreak, .startOfScope("/*"), .startOfScope("//"), .commentBody:
                    return
                case .endOfScope("*/") where nextToken == .startOfScope("/*") &&
                    formatter.currentScope(at: i) == .startOfScope("/*"):
                    return
                default:
                    break
                }
                switch nextToken {
                case .linebreak, .endOfScope("*/"), .commentBody:
                    return
                default:
                    formatter.replaceToken(at: i, with: .space(" "))
                }
            }
        }
    }

    // Converts types used for hosting only static members into enums to avoid instantiation.
    public let enumNamespaces = FormatRule(
        help: "Converts types used for hosting only static members into enums."
    ) { formatter in
        func rangeHostsOnlyStaticMembersAtTopLevel(_ range: Range<Int>) -> Bool {
            // exit for empty declarations
            guard formatter.next(.nonSpaceOrCommentOrLinebreak, in: range) != nil else {
                return false
            }

            var j = range.startIndex
            while j < range.endIndex, let token = formatter.token(at: j) {
                if token == .startOfScope("{"),
                   let skip = formatter.index(of: .endOfScope, after: j, if: { $0 == .endOfScope("}") })
                {
                    j = skip
                    continue
                }
                // exit if there's a explicit init
                if token == .keyword("init") {
                    return false
                } else if [.keyword("let"),
                           .keyword("var"),
                           .keyword("func")].contains(token),
                    !formatter.modifiersForDeclaration(at: j, contains: "static")
                {
                    return false
                }
                j += 1
            }
            return true
        }

        func rangeContainsTypeInit(_ type: String, in range: Range<Int>) -> Bool {
            for i in range {
                guard case let .identifier(name) = formatter.tokens[i],
                      [type, "Self", "self"].contains(name)
                else {
                    continue
                }
                if let nextIndex = formatter.index(of: .nonSpaceOrComment, after: i),
                   let nextToken = formatter.token(at: nextIndex), nextToken == .startOfScope("(") ||
                   (nextToken == .operator(".", .infix) && [.identifier("init"), .identifier("self")]
                       .contains(formatter.next(.nonSpaceOrComment, after: nextIndex) ?? .space("")))
                {
                    return true
                }
            }
            return false
        }

        func rangeContainsSelfAssignment(_ range: Range<Int>) -> Bool {
            for i in range {
                guard case .identifier("self") = formatter.tokens[i] else {
                    continue
                }
                if let token = formatter.last(.nonSpaceOrCommentOrLinebreak, before: i),
                   [.operator("=", .infix), .delimiter(":"), .startOfScope("(")].contains(token)
                {
                    return true
                }
            }
            return false
        }

        formatter.forEachToken(where: { [.keyword("class"), .keyword("struct")].contains($0) }) { i, _ in
            guard formatter.last(.keyword, before: i) != .keyword("import"),
                  // exit if class is a type modifier
                  let next = formatter.next(.nonSpaceOrCommentOrLinebreak, after: i), !next.isKeyword,
                  // exit for class as protocol conformance
                  formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) != .delimiter(":"),
                  let braceIndex = formatter.index(after: i, where: { $0 == .startOfScope("{") }),
                  // exit if type is conforming any types
                  !formatter.tokens[i ... braceIndex].contains(.delimiter(":")),
                  let endIndex = formatter.index(after: braceIndex, where: { $0 == .endOfScope("}") }),
                  case let .identifier(name)? = formatter.next(.identifier, after: i + 1)
            else {
                return
            }

            let range = braceIndex + 1 ..< endIndex
            if rangeHostsOnlyStaticMembersAtTopLevel(range),
               !rangeContainsTypeInit(name, in: range), !rangeContainsSelfAssignment(range)
            {
                formatter.replaceToken(at: i, with: .keyword("enum"))

                if let finalIndex = formatter.indexOfModifier("final", forTypeAt: i) {
                    formatter.removeTokens(in: finalIndex ... finalIndex + 1)
                }
            }
        }
    }

    /// Remove trailing space from the end of lines, as it has no semantic
    /// meaning and leads to noise in commits.
    public let trailingSpace = FormatRule(
        help: "Remove trailing space at end of a line.",
        orderAfter: ["wrap", "wrapArguments"],
        options: ["trimwhitespace"]
    ) { formatter in
        formatter.forEach(.space) { i, _ in
            if formatter.token(at: i + 1)?.isLinebreak ?? true,
               formatter.options.truncateBlankLines || formatter.token(at: i - 1)?.isLinebreak == false
            {
                formatter.removeToken(at: i)
            }
        }
    }

    /// Collapse all consecutive blank lines into a single blank line
    public let consecutiveBlankLines = FormatRule(
        help: "Replace consecutive blank lines with a single blank line."
    ) { formatter in
        formatter.forEach(.linebreak) { i, _ in
            guard let prevIndex = formatter.index(of: .nonSpace, before: i, if: { $0.isLinebreak }) else {
                return
            }
            if let prevToken = formatter.last(.nonSpaceOrLinebreak, before: prevIndex) {
                switch prevToken {
                case .startOfScope where prevToken.isStringDelimiter, .stringBody:
                    return
                default:
                    break
                }
            }
            if let nextIndex = formatter.index(of: .nonSpace, after: i) {
                if formatter.tokens[nextIndex].isLinebreak {
                    formatter.removeTokens(in: i + 1 ... nextIndex)
                }
            } else if !formatter.options.fragment {
                formatter.removeTokens(in: i ..< formatter.tokens.count)
            }
        }
    }

    /// Remove blank lines immediately after an opening brace, bracket, paren or chevron
    public let blankLinesAtStartOfScope = FormatRule(
        help: "Remove leading blank line at the start of a scope.",
        orderAfter: ["organizeDeclarations"]
    ) { formatter in
        formatter.forEach(.startOfScope) { i, token in
            guard ["{", "(", "[", "<"].contains(token.string),
                  let indexOfFirstLineBreak = formatter.index(of: .nonSpaceOrComment, after: i),
                  // If there is extra code on the same line, ignore it
                  formatter.tokens[indexOfFirstLineBreak].isLinebreak
            else { return }
            // Find next non-space token
            var index = indexOfFirstLineBreak + 1
            var indexOfLastLineBreak = indexOfFirstLineBreak
            loop: while let token = formatter.token(at: index) {
                switch token {
                case .linebreak:
                    indexOfLastLineBreak = index
                case .space:
                    break
                default:
                    break loop
                }
                index += 1
            }
            if formatter.options.removeBlankLines, indexOfFirstLineBreak != indexOfLastLineBreak {
                formatter.removeTokens(in: indexOfFirstLineBreak ..< indexOfLastLineBreak)
                return
            }
        }
    }

    /// Remove blank lines immediately before a closing brace, bracket, paren or chevron
    /// unless it's followed by more code on the same line (e.g. } else { )
    public let blankLinesAtEndOfScope = FormatRule(
        help: "Remove trailing blank line at the end of a scope.",
        orderAfter: ["organizeDeclarations"]
    ) { formatter in
        formatter.forEach(.endOfScope) { i, token in
            guard ["}", ")", "]", ">"].contains(token.string),
                  // If there is extra code after the closing scope on the same line, ignore it
                  (formatter.next(.nonSpaceOrComment, after: i).map { $0.isLinebreak }) ?? true
            else { return }
            // Find previous non-space token
            var index = i - 1
            var indexOfFirstLineBreak: Int?
            var indexOfLastLineBreak: Int?
            loop: while let token = formatter.token(at: index) {
                switch token {
                case .linebreak:
                    indexOfFirstLineBreak = index
                    if indexOfLastLineBreak == nil {
                        indexOfLastLineBreak = index
                    }
                case .space:
                    break
                default:
                    break loop
                }
                index -= 1
            }
            if formatter.options.removeBlankLines,
               let indexOfFirstLineBreak = indexOfFirstLineBreak,
               indexOfFirstLineBreak != indexOfLastLineBreak
            {
                formatter.removeTokens(in: indexOfFirstLineBreak ..< indexOfLastLineBreak!)
                return
            }
        }
    }

    /// Adds a blank line immediately after a closing brace, unless followed by another closing brace
    public let blankLinesBetweenScopes = FormatRule(
        help: """
        Insert blank line before class, struct, enum, extension, protocol or function
        declarations.
        """,
        sharedOptions: ["linebreaks"]
    ) { formatter in
        var spaceableScopeStack = [true]
        var isSpaceableScopeType = false
        formatter.forEachToken(onlyWhereEnabled: false) { i, token in
            switch token {
            case .keyword("class"),
                 .keyword("struct"),
                 .keyword("extension"),
                 .keyword("enum"):
                isSpaceableScopeType =
                    (formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) != .keyword("import"))
            case .keyword("func"), .keyword("var"):
                isSpaceableScopeType = false
            case .startOfScope("{"):
                spaceableScopeStack.append(isSpaceableScopeType)
                isSpaceableScopeType = false
            case .endOfScope("}"):
                spaceableScopeStack.removeLast()
                guard spaceableScopeStack.last == true,
                      let openingBraceIndex = formatter.index(of: .startOfScope("{"), before: i),
                      formatter.lastIndex(of: .linebreak, in: openingBraceIndex + 1 ..< i) != nil
                else {
                    // Inline braces
                    break
                }
                var i = i
                if let nextTokenIndex = formatter.index(of: .nonSpace, after: i, if: {
                    $0 == .startOfScope("(")
                }), let closingParenIndex = formatter.index(of:
                    .endOfScope(")"), after: nextTokenIndex)
                {
                    i = closingParenIndex
                }
                guard let nextTokenIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i),
                      formatter.isEnabled, formatter.options.insertBlankLines,
                      let firstLinebreakIndex = formatter.index(of: .linebreak, in: i + 1 ..< nextTokenIndex),
                      formatter.index(of: .linebreak, in: firstLinebreakIndex + 1 ..< nextTokenIndex) == nil
                else {
                    break
                }
                switch formatter.tokens[nextTokenIndex] {
                case .error, .endOfScope,
                     .operator(".", _), .delimiter(","), .delimiter(":"),
                     .keyword("else"), .keyword("catch"), .keyword("#else"):
                    break
                case .keyword("while"):
                    if let previousBraceIndex = formatter.index(of: .startOfScope("{"), before: i),
                       formatter.last(.nonSpaceOrCommentOrLinebreak, before: previousBraceIndex)
                       != .keyword("repeat")
                    {
                        formatter.insertLinebreak(at: firstLinebreakIndex)
                    }
                case .startOfScope("//"):
                    if case let .commentBody(body)? = formatter.next(.nonSpace, after: nextTokenIndex),
                       body.trimmingCharacters(in: .whitespaces).lowercased().hasPrefix("sourcery:")
                    {
                        break
                    }
                    formatter.insertLinebreak(at: firstLinebreakIndex)
                default:
                    formatter.insertLinebreak(at: firstLinebreakIndex)
                }
            default:
                break
            }
        }
    }

    /// Adds a blank line around MARK: comments
    public let blankLinesAroundMark = FormatRule(
        help: "Insert blank line before and after `MARK:` comments.",
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEachToken { i, token in
            guard case let .commentBody(comment) = token, comment.hasPrefix("MARK:"),
                  let startIndex = formatter.index(of: .nonSpace, before: i),
                  formatter.tokens[startIndex] == .startOfScope("//") else { return }
            if let nextIndex = formatter.index(of: .linebreak, after: i),
               let nextToken = formatter.next(.nonSpace, after: nextIndex),
               !nextToken.isLinebreak, nextToken != .endOfScope("}")
            {
                formatter.insertLinebreak(at: nextIndex)
            }
            if formatter.options.insertBlankLines,
               let lastIndex = formatter.index(of: .linebreak, before: startIndex),
               let lastToken = formatter.last(.nonSpace, before: lastIndex),
               !lastToken.isLinebreak, lastToken != .startOfScope("{")
            {
                formatter.insertLinebreak(at: lastIndex)
            }
        }
    }

    /// Always end file with a linebreak, to avoid incompatibility with certain unix tools:
    /// http://stackoverflow.com/questions/2287967/why-is-it-recommended-to-have-empty-line-in-the-end-of-file
    public let linebreakAtEndOfFile = FormatRule(
        help: "Add empty blank line at end of file.",
        sharedOptions: ["linebreaks"]
    ) { formatter in
        guard !formatter.options.fragment else { return }
        var wasLinebreak = true
        formatter.forEachToken(onlyWhereEnabled: false) { _, token in
            switch token {
            case .linebreak:
                wasLinebreak = true
            case .space:
                break
            default:
                wasLinebreak = false
            }
        }
        if formatter.isEnabled, !wasLinebreak {
            formatter.insertLinebreak(at: formatter.tokens.count)
        }
    }

    /// Indent code according to standard scope indenting rules.
    /// The type (tab or space) and level (2 spaces, 4 spaces, etc.) of the
    /// indenting can be configured with the `options` parameter of the formatter.
    public let indent = FormatRule(
        help: "Indent code in accordance with the scope level.",
        orderAfter: ["trailingSpace", "wrap", "wrapArguments"],
        options: ["indent", "tabwidth", "smarttabs", "indentcase", "ifdef", "xcodeindentation"],
        sharedOptions: ["trimwhitespace", "closingparen", "allman"]
    ) { formatter in
        var scopeStack: [Token] = []
        var scopeStartLineIndexes: [Int] = []
        var lastNonSpaceOrLinebreakIndex = -1
        var lastNonSpaceIndex = -1
        var indentStack = [""]
        var stringBodyIndentStack = [""]
        var indentCounts = [1]
        var linewrapStack = [false]
        var lineIndex = 0

        func inFunctionDeclarationWhereReturnTypeIsWrappedToStartOfLine(at i: Int) -> Bool {
            guard let returnOperatorIndex = formatter.startOfReturnType(at: i) else {
                return false
            }
            return formatter.last(.nonSpaceOrComment, before: returnOperatorIndex)?.isLinebreak == true
        }

        func isFirstStackedClosureArgument(at i: Int) -> Bool {
            assert(formatter.tokens[i] == .startOfScope("{"))
            if let prevIndex = formatter.index(of: .nonSpace, before: i),
               let prevToken = formatter.token(at: prevIndex), prevToken == .startOfScope("(") ||
               (prevToken == .delimiter(":") && formatter.token(at: prevIndex - 1)?.isIdentifier == true
                   && formatter.last(.nonSpace, before: prevIndex - 1) == .startOfScope("(")),
               let endIndex = formatter.endOfScope(at: i),
               let commaIndex = formatter.index(of: .nonSpace, after: endIndex, if: {
                   $0 == .delimiter(",")
               }),
               formatter.next(.nonSpaceOrComment, after: commaIndex)?.isLinebreak == true
            {
                return true
            }
            return false
        }

        if formatter.options.fragment,
           let firstIndex = formatter.index(of: .nonSpaceOrLinebreak, after: -1),
           let indentToken = formatter.token(at: firstIndex - 1), case let .space(string) = indentToken
        {
            indentStack[0] = string
        }
        formatter.forEachToken(onlyWhereEnabled: false) { i, token in
            func popScope() {
                if linewrapStack.last == true {
                    indentStack.removeLast()
                    stringBodyIndentStack.removeLast()
                }
                indentStack.removeLast()
                stringBodyIndentStack.removeLast()
                indentCounts.removeLast()
                linewrapStack.removeLast()
                scopeStartLineIndexes.removeLast()
                scopeStack.removeLast()
            }

            func stringBodyIndent(at i: Int) -> String {
                var space = ""
                let start = formatter.startOfLine(at: i)
                if let index = formatter.index(of: .nonSpace, in: start ..< i),
                   case let .stringBody(string) = formatter.tokens[index],
                   string.unicodeScalars.first?.isSpace == true
                {
                    var index = string.startIndex
                    while index < string.endIndex, string[index].unicodeScalars.first!.isSpace {
                        space.append(string[index])
                        index = string.index(after: index)
                    }
                }
                return space
            }

            var i = i
            switch token {
            case let .startOfScope(string):
                switch string {
                case ":" where scopeStack.last == .endOfScope("case"):
                    popScope()
                case "{" where !formatter.isStartOfClosure(at: i, in: scopeStack.last) &&
                    linewrapStack.last == true:
                    indentStack.removeLast()
                    linewrapStack[linewrapStack.count - 1] = false
                default:
                    break
                }
                // Handle start of scope
                scopeStack.append(token)
                var indentCount: Int
                if lineIndex > scopeStartLineIndexes.last ?? -1 {
                    indentCount = 1
                } else if token.isMultilineStringDelimiter, let endIndex = formatter.endOfScope(at: i),
                          let closingIndex = formatter.index(of: .endOfScope(")"), after: endIndex),
                          formatter.next(.linebreak, in: endIndex + 1 ..< closingIndex) != nil
                {
                    indentCount = 1
                } else if scopeStack.count > 1, scopeStack[scopeStack.count - 2] == .startOfScope(":") {
                    indentCount = 1
                } else {
                    indentCount = indentCounts.last! + 1
                }
                var indent = indentStack[indentStack.count - indentCount]

                switch string {
                case "/*":
                    if scopeStack.count < 2 || scopeStack[scopeStack.count - 2] != .startOfScope("/*") {
                        // Comments only indent one space
                        indent += " "
                    }
                case ":":
                    indent += formatter.options.indent
                    if formatter.options.indentCase,
                       scopeStack.count < 2 || scopeStack[scopeStack.count - 2] != .startOfScope("#if")
                    {
                        indent += formatter.options.indent
                    }
                case "#if":
                    if let lineIndex = formatter.index(of: .linebreak, after: i),
                       let nextKeyword = formatter.next(.nonSpaceOrCommentOrLinebreak, after: lineIndex), [
                           .endOfScope("case"), .endOfScope("default"), .keyword("@unknown"),
                       ].contains(nextKeyword)
                    {
                        indent = indentStack[indentStack.count - indentCount - 1]
                        if formatter.options.indentCase {
                            indent += formatter.options.indent
                        }
                    }
                    switch formatter.options.ifdefIndent {
                    case .indent:
                        i += formatter.insertSpaceIfEnabled(indent, at: formatter.startOfLine(at: i))
                        indent += formatter.options.indent
                    case .noIndent:
                        i += formatter.insertSpaceIfEnabled(indent, at: formatter.startOfLine(at: i))
                    case .outdent:
                        i += formatter.insertSpaceIfEnabled("", at: formatter.startOfLine(at: i))
                    }
                case "{" where isFirstStackedClosureArgument(at: i):
                    guard var prevIndex = formatter.index(of: .nonSpace, before: i) else {
                        assertionFailure()
                        break
                    }
                    if formatter.tokens[prevIndex] == .delimiter(":") {
                        guard formatter.token(at: prevIndex - 1)?.isIdentifier == true,
                              let parenIndex = formatter.index(of: .nonSpace, before: prevIndex - 1, if: {
                                  $0 == .startOfScope("(")
                              })
                        else {
                            let stringIndent = stringBodyIndent(at: i)
                            stringBodyIndentStack[stringBodyIndentStack.count - 1] = stringIndent
                            indent += stringIndent + formatter.options.indent
                            break
                        }
                        prevIndex = parenIndex
                    }
                    let startIndex = formatter.startOfLine(at: i)
                    indent = formatter.spaceEquivalentToTokens(from: startIndex, upTo: prevIndex + 1)
                    indentStack[indentStack.count - 1] = indent
                    indent += formatter.options.indent
                    indentCount -= 1
                case "{" where formatter.options.closingParenOnSameLine && formatter.isStartOfClosure(at: i):
                    // When a trailing closure starts on the same line as the end of
                    // a multi-line method call, and `closingParenOnSameLine` is enabled,
                    // the trailing closure body should be double-indented.
                    //  - Check that the trailing closure starts on the same line as the end of a parameter list
                    //    But _not_ on the same line as the start of the parameter list
                    let startOfLine = formatter.startOfLine(at: i)
                    if let previousTokenIndex = formatter.index(of: .nonSpaceOrComment, before: i),
                       formatter.tokens[previousTokenIndex] == .endOfScope(")"),
                       startOfLine < previousTokenIndex,
                       let startOfParameterList = formatter.index(of: .startOfScope("("), before: previousTokenIndex),
                       startOfParameterList < startOfLine
                    {
                        indent += formatter.options.indent + formatter.options.indent
                    } else {
                        indent += formatter.options.indent
                    }
                case _ where token.isStringDelimiter, "//":
                    break
                case "[", "(":
                    guard let linebreakIndex = formatter.index(of: .linebreak, after: i),
                          let nextIndex = formatter.index(of: .nonSpace, after: i),
                          nextIndex != linebreakIndex
                    else {
                        fallthrough
                    }
                    if formatter.last(.nonSpaceOrComment, before: linebreakIndex) != .delimiter(","),
                       formatter.next(.nonSpaceOrComment, after: linebreakIndex) != .delimiter(",")
                    {
                        fallthrough
                    }
                    let start = formatter.startOfLine(at: i)
                    // Align indent with previous value
                    indentCount = 1
                    indent = formatter.spaceEquivalentToTokens(from: start, upTo: nextIndex)
                default:
                    let stringIndent = stringBodyIndent(at: i)
                    stringBodyIndentStack[stringBodyIndentStack.count - 1] = stringIndent
                    indent += stringIndent + formatter.options.indent
                }
                indentStack.append(indent)
                stringBodyIndentStack.append("")
                indentCounts.append(indentCount)
                scopeStartLineIndexes.append(lineIndex)
                linewrapStack.append(false)
            case .space:
                if i == 0, !formatter.options.fragment,
                   formatter.token(at: i + 1)?.isLinebreak != true
                {
                    formatter.removeToken(at: i)
                }
            case .error("}"), .error("]"), .error(")"), .error(">"):
                // Handled over-terminated fragment
                if let prevToken = formatter.token(at: i - 1) {
                    if case let .space(string) = prevToken {
                        let prevButOneToken = formatter.token(at: i - 2)
                        if prevButOneToken == nil || prevButOneToken!.isLinebreak {
                            indentStack[0] = string
                        }
                    } else if prevToken.isLinebreak {
                        indentStack[0] = ""
                    }
                }
                return
            case .keyword("#else"), .keyword("#elseif"):
                var indent = indentStack[indentStack.count - 2]
                if scopeStack.last == .startOfScope(":") {
                    indent = indentStack[indentStack.count - 4]
                    if formatter.options.indentCase {
                        indent += formatter.options.indent
                    }
                }
                let start = formatter.startOfLine(at: i)
                switch formatter.options.ifdefIndent {
                case .indent, .noIndent:
                    i += formatter.insertSpaceIfEnabled(indent, at: start)
                case .outdent:
                    i += formatter.insertSpaceIfEnabled("", at: start)
                }
            case .keyword("@unknown") where scopeStack.last != .startOfScope("#if"):
                var indent = indentStack[indentStack.count - 2]
                if formatter.options.indentCase {
                    indent += formatter.options.indent
                }
                let start = formatter.startOfLine(at: i)
                let stringIndent = stringBodyIndentStack.last!
                i += formatter.insertSpaceIfEnabled(stringIndent + indent, at: start)
            case .keyword("in") where scopeStack.last == .startOfScope("{"):
                guard let lastIndex = formatter.index(of: .nonSpaceOrComment, before: i, if: {
                    $0 == .endOfScope(")")
                }), let startIndex = formatter.index(of: .startOfScope("("), before: lastIndex),
                formatter.tokens[startIndex ..< lastIndex].contains(where: {
                    if case .linebreak = $0 { return true } else { return false }
                }) else {
                    break
                }
                indentStack[indentStack.count - 1] += formatter.options.indent
            default:
                // Handle end of scope
                if let scope = scopeStack.last, token.isEndOfScope(scope) {
                    let indentCount = indentCounts.last! - 1
                    popScope()
                    guard !token.isLinebreak, lineIndex > scopeStartLineIndexes.last ?? -1 else {
                        break
                    }
                    // If indentCount > 0, drop back to previous indent level
                    if indentCount > 0 {
                        indentStack.removeLast(indentCount)
                        stringBodyIndentStack.removeLast(indentCount)
                        for _ in 0 ..< indentCount {
                            indentStack.append(indentStack.last ?? "")
                            stringBodyIndentStack.append(stringBodyIndentStack.last ?? "")
                        }
                    }
                    // Don't reduce indent if line doesn't start with end of scope
                    let start = formatter.startOfLine(at: i)
                    guard let firstIndex = formatter.index(of: .nonSpaceOrComment, after: start - 1) else {
                        break
                    }
                    if firstIndex != i {
                        break
                    }
                    if token == .endOfScope("#endif"), formatter.options.ifdefIndent == .outdent {
                        i += formatter.insertSpaceIfEnabled("", at: start)
                    } else {
                        var indent = indentStack.last ?? ""
                        if [.endOfScope("case"), .endOfScope("default")].contains(token),
                           formatter.options.indentCase, scopeStack.last != .startOfScope("#if")
                        {
                            indent += formatter.options.indent
                        }
                        let stringIndent = stringBodyIndentStack.last!
                        i += formatter.insertSpaceIfEnabled(stringIndent + indent, at: start)
                    }
                } else if token == .endOfScope("#endif"), indentStack.count > 1 {
                    var indent = indentStack[indentStack.count - 2]
                    if scopeStack.last == .startOfScope(":"), indentStack.count > 1 {
                        indent = indentStack[indentStack.count - 4]
                        if formatter.options.indentCase {
                            indent += formatter.options.indent
                        }
                        popScope()
                    }
                    switch formatter.options.ifdefIndent {
                    case .indent, .noIndent:
                        i += formatter.insertSpaceIfEnabled(indent, at: formatter.startOfLine(at: i))
                    case .outdent:
                        i += formatter.insertSpaceIfEnabled("", at: formatter.startOfLine(at: i))
                    }
                    if scopeStack.last == .startOfScope("#if") {
                        popScope()
                    }
                }
            }
            switch token {
            case .endOfScope("case"):
                scopeStack.append(token)
                var indent = (indentStack.last ?? "")
                if formatter.next(.nonSpaceOrComment, after: i)?.isLinebreak == true {
                    indent += formatter.options.indent
                } else {
                    if formatter.options.indentCase {
                        indent += formatter.options.indent
                    }
                    // Align indent with previous case value
                    indent += formatter.spaceEquivalentToWidth(5)
                }
                indentStack.append(indent)
                stringBodyIndentStack.append("")
                indentCounts.append(1)
                scopeStartLineIndexes.append(lineIndex)
                linewrapStack.append(false)
                fallthrough
            case .endOfScope("default"), .keyword("@unknown"),
                 .startOfScope("#if"), .keyword("#else"), .keyword("#elseif"):
                var index = formatter.startOfLine(at: i)
                if index == i || index == i - 1 {
                    let indent: String
                    if case let .space(space) = formatter.tokens[index] {
                        indent = space
                    } else {
                        indent = ""
                    }
                    index -= 1
                    while let prevToken = formatter.token(at: index - 1), prevToken.isComment,
                          let startIndex = formatter.index(of: .nonSpaceOrComment, before: index),
                          formatter.tokens[startIndex].isLinebreak
                    {
                        // Set indent for comment immediately before this line to match this line
                        if !formatter.isCommentedCode(at: startIndex + 1) {
                            formatter.insertSpaceIfEnabled(indent, at: startIndex + 1)
                        }
                        if case .endOfScope("*/") = prevToken,
                           var index = formatter.index(of: .startOfScope("/*"), after: startIndex)
                        {
                            while let linebreakIndex = formatter.index(of: .linebreak, after: index) {
                                formatter.insertSpaceIfEnabled(indent + " ", at: linebreakIndex + 1)
                                index = linebreakIndex
                            }
                        }
                        index = startIndex
                    }
                }
            case .linebreak:
                // Detect linewrap
                let nextTokenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i)
                let linewrapped = lastNonSpaceOrLinebreakIndex > -1 && (
                    !formatter.isEndOfStatement(at: lastNonSpaceOrLinebreakIndex, in: scopeStack.last) ||
                        !(nextTokenIndex == nil ||
                            formatter.isStartOfStatement(at: nextTokenIndex!, in: scopeStack.last))
                )

                // Determine current indent
                var indent = indentStack.last ?? ""
                if linewrapped, lineIndex == scopeStartLineIndexes.last {
                    indent = indentStack.count > 1 ? indentStack[indentStack.count - 2] : ""
                }
                lineIndex += 1

                func shouldIndentNextLine(at i: Int) -> Bool {
                    // If there is a linebreak after certain symbols, we should add
                    // an additional indentation to the lines at the same indention scope
                    // after this line.
                    let endOfLine = formatter.endOfLine(at: i)
                    switch formatter.token(at: endOfLine - 1) {
                    case .keyword("return")?, .operator("=", .infix)?:
                        let endOfNextLine = formatter.endOfLine(at: endOfLine + 1)
                        switch formatter.last(.nonSpaceOrCommentOrLinebreak, before: endOfNextLine) {
                        case .operator(_, .infix)?, .delimiter(",")?:
                            return false
                        case .endOfScope(")")?:
                            return !formatter.options.xcodeIndentation
                        default:
                            return formatter.lastIndex(of: .startOfScope,
                                                       in: i ..< endOfNextLine) == nil
                        }
                    default:
                        return false
                    }
                }

                guard var nextNonSpaceIndex = formatter.index(of: .nonSpace, after: i),
                      let nextToken = formatter.token(at: nextNonSpaceIndex)
                else {
                    break
                }

                // Begin wrap scope
                if linewrapStack.last == true {
                    if !linewrapped {
                        indentStack.removeLast()
                        linewrapStack[linewrapStack.count - 1] = false
                        indent = indentStack.last!
                    } else {
                        if formatter.options.xcodeIndentation,
                           formatter.next(.nonSpace, after: i) == .operator(".", .infix),
                           let startIndex = formatter.index(of: .nonSpace, after: formatter.startOfLine(at: i - 1)),
                           formatter.isStartOfStatement(at: startIndex)
                        {
                            indent += formatter.options.indent
                            indentStack[indentStack.count - 1] = indent
                        }
                    }
                } else if linewrapped {
                    func isWrappedDeclaration() -> Bool {
                        guard let keywordIndex = formatter
                            .indexOfLastSignificantKeyword(at: i, excluding: [
                                "where", "throws", "rethrows", "async",
                            ]), !formatter.tokens[keywordIndex ..< i].contains(.endOfScope("}")),
                            case let .keyword(keyword) = formatter.tokens[keywordIndex],
                            ["class", "struct", "enum", "protocol", "func"].contains(keyword)
                        else {
                            return false
                        }

                        let end = formatter.endOfLine(at: i + 1)
                        guard let lastToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: end + 1),
                              [.startOfScope("{"), .endOfScope("}")].contains(lastToken) else { return false }

                        return true
                    }

                    // Don't indent line starting with dot if previous line was just a closing brace
                    let lastToken = formatter.tokens[lastNonSpaceOrLinebreakIndex]
                    if formatter.options.allmanBraces, nextToken == .startOfScope("{"),
                       formatter.isStartOfClosure(at: nextNonSpaceIndex)
                    {
                        // Don't indent further
                    } else if formatter.token(at: nextTokenIndex ?? -1) == .operator(".", .infix),
                              formatter.last(.nonSpace, before: lastNonSpaceOrLinebreakIndex)?.isLinebreak == true
                    {
                        if !lastToken.isEndOfScope || lastToken == .endOfScope("case") ||
                            (formatter.options.xcodeIndentation && lastToken.isMultilineStringDelimiter)
                        {
                            indent += formatter.options.indent
                        }
                    } else if !formatter.options.xcodeIndentation || !isWrappedDeclaration() {
                        indent += formatter.linewrapIndent(at: i)
                    }
                    linewrapStack[linewrapStack.count - 1] = true
                    indentStack.append(indent)
                    stringBodyIndentStack.append("")
                }
                // Avoid indenting commented code
                guard !formatter.isCommentedCode(at: nextNonSpaceIndex) else {
                    break
                }
                // Apply indent
                switch nextToken {
                case .linebreak:
                    if formatter.options.truncateBlankLines {
                        formatter.insertSpaceIfEnabled("", at: i + 1)
                    }
                case .error, .keyword("#else"), .keyword("#elseif"), .endOfScope("#endif"),
                     .startOfScope("#if") where formatter.options.ifdefIndent != .indent:
                    break
                case .startOfScope("/*"), .commentBody, .endOfScope("*/"):
                    nextNonSpaceIndex = formatter.endOfScope(at: nextNonSpaceIndex) ?? nextNonSpaceIndex
                    fallthrough
                case .startOfScope("//"):
                    nextNonSpaceIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak,
                                                        after: nextNonSpaceIndex) ?? nextNonSpaceIndex
                    nextNonSpaceIndex = formatter.index(of: .nonSpaceOrLinebreak,
                                                        before: nextNonSpaceIndex) ?? nextNonSpaceIndex
                    if let lineIndex = formatter.index(of: .linebreak, after: nextNonSpaceIndex),
                       let nextToken = formatter.next(.nonSpace, after: lineIndex),
                       [.startOfScope("#if"), .keyword("#else"), .keyword("#elseif")].contains(nextToken)
                    {
                        break
                    }
                    fallthrough
                case .startOfScope("#if"):
                    if let lineIndex = formatter.index(of: .linebreak, after: nextNonSpaceIndex),
                       let nextKeyword = formatter.next(.nonSpaceOrCommentOrLinebreak, after: lineIndex), [
                           .endOfScope("case"), .endOfScope("default"), .keyword("@unknown"),
                       ].contains(nextKeyword)
                    {
                        break
                    }
                    formatter.insertSpaceIfEnabled(indent, at: i + 1)
                case .endOfScope, .keyword("@unknown"):
                    if let scope = scopeStack.last {
                        switch scope {
                        case .startOfScope("/*"), .startOfScope("#if"),
                             .keyword("#else"), .keyword("#elseif"),
                             .startOfScope where scope.isStringDelimiter:
                            formatter.insertSpaceIfEnabled(indent, at: i + 1)
                        default:
                            break
                        }
                    }
                default:
                    formatter.insertSpaceIfEnabled(indent, at: i + 1)
                }

                if linewrapped, shouldIndentNextLine(at: i) {
                    indentStack[indentStack.count - 1] += formatter.options.indent
                }

            default:
                break
            }
            // Track token for line wraps
            if !token.isSpaceOrComment {
                lastNonSpaceIndex = i
                if !token.isLinebreak {
                    lastNonSpaceOrLinebreakIndex = i
                }
            }
        }
    }

    // Add @available(*, unavailable) to init?(coder aDecoder: NSCoder)
    public let initCoderUnavailable = FormatRule(
        help: """
        Add `@available(*, unavailable)` attribute to required `init(coder:)` when
        it hasn't been implemented.
        """,
        options: [],
        sharedOptions: ["linebreaks"]
    ) { formatter in
        let unavailableTokens = tokenize("@available(*, unavailable)")
        formatter.forEach(.identifier("required")) { i, _ in
            // look for required init?(coder
            guard var initIndex = formatter.index(of: .keyword("init"), after: i) else { return }
            if let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: initIndex, if: {
                $0 == .operator("?", .postfix)
            }) {
                initIndex = nextIndex
            }

            guard let parenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: initIndex, if: {
                $0 == .startOfScope("(")
            }), let coderIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: parenIndex, if: {
                $0 == .identifier("coder")
            }), let endParenIndex = formatter.index(of: .endOfScope(")"), after: coderIndex),
            let braceIndex = formatter.index(of: .startOfScope("{"), after: endParenIndex)
            else { return }

            // make sure the implementation is empty or fatalError
            guard let firstToken = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: braceIndex, if: {
                [.endOfScope("}"), .identifier("fatalError")].contains($0)
            }) else { return }

            // avoid adding attribute if it's already there
            if formatter.modifiersForDeclaration(at: i, contains: "@available") { return }

            let startIndex = formatter.startOfModifiers(at: i, includingAttributes: true)
            formatter.insert(.space(formatter.indentForLine(at: startIndex)), at: startIndex)
            formatter.insertLinebreak(at: startIndex)
            formatter.insert(unavailableTokens, at: startIndex)
        }
    }

    // Implement brace-wrapping rules
    public let braces = FormatRule(
        help: "Wrap braces in accordance with selected style (K&R or Allman).",
        options: ["allman"],
        sharedOptions: ["linebreaks", "maxwidth", "indent", "tabwidth", "assetliterals"]
    ) { formatter in
        formatter.forEach(.startOfScope("{")) { i, _ in
            guard let closingBraceIndex = formatter.endOfScope(at: i),
                  // Check this isn't an inline block
                  formatter.index(of: .linebreak, in: i + 1 ..< closingBraceIndex) != nil,
                  let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: i),
                  ![.delimiter(","), .keyword("in")].contains(prevToken),
                  !prevToken.is(.startOfScope)
            else {
                return
            }
            if let penultimateToken = formatter.last(.nonSpaceOrComment, before: closingBraceIndex),
               !penultimateToken.isLinebreak
            {
                formatter.insertSpace(formatter.indentForLine(at: i), at: closingBraceIndex)
                formatter.insertLinebreak(at: closingBraceIndex)
                if formatter.token(at: closingBraceIndex - 1)?.isSpace == true {
                    formatter.removeToken(at: closingBraceIndex - 1)
                }
            }
            if formatter.options.allmanBraces {
                // Implement Allman-style braces, where opening brace appears on the next line
                switch formatter.last(.nonSpace, before: i) ?? .space("") {
                case .identifier, .keyword, .endOfScope, .number,
                     .operator("?", .postfix), .operator("!", .postfix):
                    formatter.insertLinebreak(at: i)
                    if let breakIndex = formatter.index(of: .linebreak, after: i + 1),
                       let nextIndex = formatter.index(of: .nonSpace, after: breakIndex, if: { $0.isLinebreak })
                    {
                        formatter.removeTokens(in: breakIndex ..< nextIndex)
                    }
                    formatter.insertSpace(formatter.indentForLine(at: i), at: i + 1)
                    if formatter.tokens[i - 1].isSpace {
                        formatter.removeToken(at: i - 1)
                    }
                default:
                    break
                }
            } else {
                // Implement K&R-style braces, where opening brace appears on the same line
                guard let prevIndex = formatter.index(of: .nonSpaceOrLinebreak, before: i),
                      formatter.tokens[prevIndex ..< i].contains(where: { $0.isLinebreak }),
                      !formatter.tokens[prevIndex].isComment
                else {
                    return
                }

                var maxWidth = formatter.options.maxWidth
                if maxWidth == 0 {
                    // Set reasonable default
                    maxWidth = 100
                }

                // Check that unwrapping wouldn't exceed line length
                let endOfLine = formatter.endOfLine(at: i)
                let length = formatter.lineLength(from: i, upTo: endOfLine)
                let prevLineLength = formatter.lineLength(at: prevIndex)
                guard prevLineLength + length + 1 <= maxWidth else {
                    return
                }

                // Avoid conflicts with wrapMultilineStatementBraces
                // TODO: find a better solution for this
                if let keywordIndex =
                    formatter.indexOfLastSignificantKeyword(at: prevIndex + 1, excluding: ["where"]),
                    case let .keyword(keyword) = formatter.tokens[keywordIndex],
                    ["if", "for", "guard", "while", "switch", "func", "init", "subscript",
                     "extension", "class", "struct", "enum", "protocol"].contains(keyword),
                    formatter.indentForLine(at: prevIndex) > formatter.indentForLine(at: keywordIndex)
                {
                    return
                }
                formatter.replaceTokens(in: prevIndex + 1 ..< i, with: .space(" "))
            }
        }
    }

    /// Ensure that an `else` statement following `if { ... }` appears on the same line
    /// as the closing brace. This has no effect on the `else` part of a `guard` statement.
    /// Also applies to `catch` after `try` and `while` after `repeat`.
    public let elseOnSameLine = FormatRule(
        help: """
        Place `else`, `catch` or `while` keyword in accordance with current style (same or
        next line).
        """,
        orderAfter: ["wrapMultilineStatementBraces"],
        options: ["elseposition", "guardelse"],
        sharedOptions: ["allman", "linebreaks"]
    ) { formatter in
        func bracesContainLinebreak(_ endIndex: Int) -> Bool {
            guard let startIndex = formatter.index(of: .startOfScope("{"), before: endIndex) else {
                return false
            }
            return (startIndex ..< endIndex).contains(where: { formatter.tokens[$0].isLinebreak })
        }
        formatter.forEachToken { i, token in
            switch token {
            case .keyword("while"):
                if let endIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i, if: {
                    $0 == .endOfScope("}")
                }), let startIndex = formatter.index(of: .startOfScope("{"), before: endIndex),
                formatter.last(.nonSpaceOrCommentOrLinebreak, before: startIndex) == .keyword("repeat") {
                    fallthrough
                }
            case .keyword("else"):
                guard var prevIndex = formatter.index(of: .nonSpace, before: i),
                      let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i, if: {
                          !$0.isComment
                      })
                else {
                    return
                }
                let isOnNewLine = formatter.tokens[prevIndex].isLinebreak
                if isOnNewLine {
                    prevIndex = formatter.index(of: .nonSpaceOrLinebreak, before: i) ?? prevIndex
                }
                if formatter.tokens[prevIndex] == .endOfScope("}") {
                    fallthrough
                }
                guard let guardIndex = formatter.indexOfLastSignificantKeyword(at: prevIndex + 1, excluding: [
                    "var", "let", "case",
                ]), formatter.tokens[guardIndex] == .keyword("guard") else {
                    return
                }
                let isAllman = formatter.options.allmanBraces
                let shouldWrap: Bool
                switch formatter.options.guardElsePosition {
                case .auto:
                    // Only wrap if else or following brace is on next line
                    shouldWrap = isOnNewLine ||
                        formatter.tokens[i + 1 ..< nextIndex].contains { $0.isLinebreak }
                case .nextLine:
                    // Only wrap if guard statement spans multiple lines
                    shouldWrap = isOnNewLine ||
                        formatter.tokens[guardIndex + 1 ..< nextIndex].contains { $0.isLinebreak }
                case .sameLine:
                    shouldWrap = false
                }
                if shouldWrap {
                    if !isAllman {
                        formatter.replaceTokens(in: i + 1 ..< nextIndex, with: .space(" "))
                    }
                    if !isOnNewLine {
                        formatter.replaceTokens(in: prevIndex + 1 ..< i, with:
                            formatter.linebreakToken(for: prevIndex + 1))
                        formatter.insertSpace(formatter.indentForLine(at: guardIndex), at: prevIndex + 2)
                    }
                } else if isOnNewLine {
                    formatter.replaceTokens(in: prevIndex + 1 ..< i, with: .space(" "))
                }
            case .keyword("catch"):
                guard let prevIndex = formatter.index(of: .nonSpace, before: i) else {
                    return
                }
                let shouldWrap = formatter.options.allmanBraces || formatter.options.elseOnNextLine
                if !shouldWrap, formatter.tokens[prevIndex].isLinebreak {
                    if let prevBraceIndex = formatter.index(of: .nonSpaceOrLinebreak, before: prevIndex, if: {
                        $0 == .endOfScope("}")
                    }), bracesContainLinebreak(prevBraceIndex) {
                        formatter.replaceTokens(in: prevBraceIndex + 1 ..< i, with: .space(" "))
                    }
                } else if shouldWrap, let token = formatter.token(at: prevIndex), !token.isLinebreak,
                          let prevBraceIndex = (token == .endOfScope("}")) ? prevIndex :
                          formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: prevIndex, if: {
                              $0 == .endOfScope("}")
                          }), bracesContainLinebreak(prevBraceIndex)
                {
                    formatter.replaceTokens(in: prevIndex + 1 ..< i, with:
                        formatter.linebreakToken(for: prevIndex + 1))
                    formatter.insertSpace(formatter.indentForLine(at: prevIndex + 1), at: prevIndex + 2)
                }
            default:
                break
            }
        }
    }

    /// Ensure that the last item in a multi-line array literal is followed by a comma.
    /// This is useful for preventing noise in commits when items are added to end of array.
    public let trailingCommas = FormatRule(
        help: "Add or remove trailing comma from the last item in a collection literal.",
        options: ["commas"]
    ) { formatter in
        formatter.forEach(.endOfScope("]")) { i, _ in
            guard let prevTokenIndex = formatter.index(of: .nonSpaceOrComment, before: i) else {
                return
            }
            if let startIndex = formatter.index(of: .startOfScope("["), before: i),
               let prevToken = formatter.last(.nonSpaceOrComment, before: startIndex)
            {
                switch prevToken {
                case .identifier,
                     .operator("!", .postfix), .operator("?", .postfix),
                     .endOfScope(")"), .endOfScope("]"):
                    // Subscript
                    return
                case .delimiter(":"):
                    // Check for type declaration
                    if let scopeStart = formatter.index(of: .startOfScope, before: startIndex),
                       formatter.tokens[scopeStart] == .startOfScope("(")
                    {
                        if formatter.last(.keyword, before: scopeStart) == .keyword("func") {
                            return
                        }
                    } else if let token = formatter.last(.keyword, before: startIndex),
                              [.keyword("let"), .keyword("var")].contains(token)
                    {
                        return
                    }
                case .operator("->", .infix),
                     .startOfScope("{") where formatter.isInClosureArguments(at: i):
                    return
                default:
                    break
                }
            }
            switch formatter.tokens[prevTokenIndex] {
            case .linebreak:
                guard let prevTokenIndex = formatter.index(
                    of: .nonSpaceOrCommentOrLinebreak, before: prevTokenIndex + 1
                ) else {
                    break
                }
                switch formatter.tokens[prevTokenIndex] {
                case .startOfScope("["), .delimiter(":"):
                    break // do nothing
                case .delimiter(","):
                    if !formatter.options.trailingCommas {
                        formatter.removeToken(at: prevTokenIndex)
                    }
                default:
                    if formatter.options.trailingCommas {
                        formatter.insert(.delimiter(","), at: prevTokenIndex + 1)
                    }
                }
            case .delimiter(","):
                formatter.removeToken(at: prevTokenIndex)
            default:
                break
            }
        }
    }

    /// Ensure that TODO, MARK and FIXME comments are followed by a : as required
    public let todos = FormatRule(
        help: "Use correct formatting for `TODO:`, `MARK:` or `FIXME:` comments."
    ) { formatter in
        formatter.forEachToken { i, token in
            guard case var .commentBody(string) = token else {
                return
            }
            var removedSpace = false
            if string.hasPrefix("/") {
                removedSpace = true
                string = string.replacingOccurrences(of: "^/(\\s+)", with: "", options: .regularExpression)
            }
            for pair in [
                "todo:": "TODO:",
                "todo :": "TODO:",
                "fixme:": "FIXME:",
                "fixme :": "FIXME:",
                "mark:": "MARK:",
                "mark :": "MARK:",
                "mark-": "MARK: -",
                "mark -": "MARK: -",
            ] where string.lowercased().hasPrefix(pair.0) {
                string = pair.1 + string.dropFirst(pair.0.count)
            }
            guard let tag = ["TODO", "MARK", "FIXME"].first(where: { string.hasPrefix($0) }) else {
                return
            }
            var suffix = String(string[tag.endIndex ..< string.endIndex])
            if let first = suffix.unicodeScalars.first, !" :".unicodeScalars.contains(first) {
                // If not followed by a space or :, don't mess with it as it may be a custom format
                return
            }
            while let first = suffix.unicodeScalars.first, " :".unicodeScalars.contains(first) {
                suffix = String(suffix.dropFirst())
            }
            if tag == "MARK", suffix.hasPrefix("-"), suffix != "-", !suffix.hasPrefix("- ") {
                suffix = "- " + suffix.dropFirst()
            }
            formatter.replaceToken(at: i, with: .commentBody(tag + ":" + (suffix.isEmpty ? "" : " \(suffix)")))
            if removedSpace {
                formatter.insertSpace(" ", at: i)
            }
        }
    }

    /// Remove semicolons, except where doing so would change the meaning of the code
    public let semicolons = FormatRule(
        help: "Remove semicolons.",
        options: ["semicolons"],
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEach(.delimiter(";")) { i, _ in
            if let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: i) {
                let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: i)
                if prevToken == nil || nextToken == .endOfScope("}") {
                    // Safe to remove
                    formatter.removeToken(at: i)
                } else if prevToken == .keyword("return") || (
                    formatter.options.swiftVersion < "3" &&
                        // Might be a traditional for loop (not supported in Swift 3 and above)
                        formatter.currentScope(at: i) == .startOfScope("(")
                ) {
                    // Not safe to remove or replace
                } else if formatter.next(.nonSpaceOrComment, after: i)?.isLinebreak == true {
                    // Safe to remove
                    formatter.removeToken(at: i)
                } else if !formatter.options.allowInlineSemicolons {
                    // Replace with a linebreak
                    if formatter.token(at: i + 1)?.isSpace == true {
                        formatter.removeToken(at: i + 1)
                    }
                    formatter.insertSpace(formatter.indentForLine(at: i), at: i + 1)
                    formatter.replaceToken(at: i, with: formatter.linebreakToken(for: i))
                }
            } else {
                // Safe to remove
                formatter.removeToken(at: i)
            }
        }
    }

    /// Standardise linebreak characters as whatever is specified in the options (\n by default)
    public let linebreaks = FormatRule(
        help: "Use specified linebreak character for all linebreaks (CR, LF or CRLF).",
        options: ["linebreaks"]
    ) { formatter in
        formatter.forEach(.linebreak) { i, _ in
            formatter.replaceToken(at: i, with: formatter.linebreakToken(for: i))
        }
    }

    /// Deprecated
    public let specifiers = FormatRule(
        help: "Use consistent ordering for member modifiers.",
        deprecationMessage: "Use modifierOrder instead.",
        options: ["modifierorder"]
    ) { formatter in
        _ = formatter.options.modifierOrder
        FormatRules.modifierOrder.apply(with: formatter)
    }

    /// Standardise the order of property modifiers
    public let modifierOrder = FormatRule(
        help: "Use consistent ordering for member modifiers.",
        options: ["modifierorder"]
    ) { formatter in
        formatter.forEach(.keyword) { i, token in
            switch token.string {
            case "let", "func", "var", "class", "extension", "init", "enum",
                 "struct", "typealias", "subscript", "associatedtype", "protocol":
                break
            default:
                return
            }
            var modifiers = [String: [Token]]()
            var lastModifier: (String, [Token])?
            var lastIndex = i
            var previousIndex = lastIndex
            loop: while let index = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: lastIndex) {
                switch formatter.tokens[index] {
                case .operator(_, .prefix), .operator(_, .infix), .keyword("case"):
                    // Last modifier was invalid
                    lastModifier = nil
                    lastIndex = previousIndex
                    break loop
                case let token where token.isModifierKeyword:
                    lastModifier.map { modifiers[$0.0] = $0.1 }
                    lastModifier = (token.string, [Token](formatter.tokens[index ..< lastIndex]))
                    previousIndex = lastIndex
                    lastIndex = index
                case .endOfScope(")"):
                    if formatter.last(.nonSpaceOrCommentOrLinebreak, before: index) == .identifier("set"),
                       let openParenIndex = formatter.index(of: .startOfScope("("), before: index),
                       let index = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: openParenIndex),
                       case let .keyword(string)? = formatter.token(at: index), aclModifiers.contains(string)
                    {
                        lastModifier.map { modifiers[$0.0] = $0.1 }
                        lastModifier = (string + "(set)", [Token](formatter.tokens[index ..< lastIndex]))
                        previousIndex = lastIndex
                        lastIndex = index
                    } else {
                        break loop
                    }
                default:
                    // Not a modifier
                    break loop
                }
            }
            lastModifier.map { modifiers[$0.0] = $0.1 }
            guard !modifiers.isEmpty else { return }
            var sortedModifiers = [Token]()
            for modifier in formatter.modifierOrder {
                if let tokens = modifiers[modifier] {
                    sortedModifiers += tokens
                }
            }
            formatter.replaceTokens(in: lastIndex ..< i, with: sortedModifiers)
        }
    }

    /// Convert closure arguments to trailing closure syntax where possible
    public let trailingClosures = FormatRule(
        help: "Use trailing closure syntax where applicable.",
        options: ["trailingclosures", "nevertrailing"]
    ) { formatter in
        let useTrailing = Set([
            "async", "asyncAfter", "sync", "autoreleasepool",
        ] + formatter.options.trailingClosures)

        let nonTrailing = Set([
            "performBatchUpdates",
            "expect", // Special case to support autoclosure arguments in the Nimble framework
        ] + formatter.options.neverTrailing)

        formatter.forEach(.startOfScope("(")) { i, _ in
            guard let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: i),
                  case let .identifier(name) = prevToken, // TODO: are trailing closures allowed in other cases?
                  !nonTrailing.contains(name), !formatter.isConditionalStatement(at: i)
            else {
                return
            }
            guard let closingIndex = formatter.index(of: .endOfScope(")"), after: i), let closingBraceIndex =
                formatter.index(of: .nonSpaceOrComment, before: closingIndex, if: { $0 == .endOfScope("}") }),
                let openingBraceIndex = formatter.index(of: .startOfScope("{"), before: closingBraceIndex),
                formatter.index(of: .endOfScope("}"), before: openingBraceIndex) == nil
            else {
                return
            }
            guard formatter.next(.nonSpaceOrCommentOrLinebreak, after: closingIndex) != .startOfScope("{"),
                  var startIndex = formatter.index(of: .nonSpaceOrLinebreak, before: openingBraceIndex)
            else {
                return
            }
            switch formatter.tokens[startIndex] {
            case .delimiter(","), .startOfScope("("):
                break
            case .delimiter(":"):
                guard useTrailing.contains(name) else {
                    return
                }
                if let commaIndex = formatter.index(of: .delimiter(","), before: openingBraceIndex) {
                    startIndex = commaIndex
                } else if formatter.index(of: .startOfScope("("), before: openingBraceIndex) == i {
                    startIndex = i
                } else {
                    return
                }
            default:
                return
            }
            let wasParen = (startIndex == i)
            formatter.removeParen(at: closingIndex)
            formatter.replaceTokens(in: startIndex ..< openingBraceIndex, with:
                wasParen ? [.space(" ")] : [.endOfScope(")"), .space(" ")])
        }
    }

    /// Remove redundant parens around the arguments for loops, if statements, closures, etc.
    public let redundantParens = FormatRule(
        help: "Remove redundant parentheses."
    ) { formatter in
        func nestedParens(in range: ClosedRange<Int>) -> ClosedRange<Int>? {
            guard let startIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: range.lowerBound, if: {
                $0 == .startOfScope("(")
            }), let endIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: range.upperBound, if: {
                $0 == .endOfScope(")")
            }), formatter.index(of: .endOfScope(")"), after: startIndex) == endIndex else {
                return nil
            }
            return startIndex ... endIndex
        }

        // TODO: unify with conditionals logic in trailingClosures
        let conditionals = Set(["in", "while", "if", "case", "switch", "where", "for", "guard"])

        formatter.forEach(.startOfScope("(")) { i, _ in
            guard var closingIndex = formatter.index(of: .endOfScope(")"), after: i) else {
                return
            }
            var innerParens = nestedParens(in: i ... closingIndex)
            while let range = innerParens, nestedParens(in: range) != nil {
                // TODO: this could be a lot more efficient if we kept track of the
                // removed token indices instead of recalculating paren positions every time
                formatter.removeParen(at: range.upperBound)
                formatter.removeParen(at: range.lowerBound)
                closingIndex = formatter.index(of: .endOfScope(")"), after: i)!
                innerParens = nestedParens(in: i ... closingIndex)
            }
            let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: closingIndex) ?? .space("")
            if [.operator("->", .infix), .keyword("throws"), .keyword("rethrows"),
                .keyword("async"), .identifier("async")].contains(nextToken)
            {
                return // It's a closure type or function declaration
            }
            let previousIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i) ?? -1
            let token = formatter.token(at: previousIndex) ?? .space("")
            switch token {
            case .endOfScope("]") where formatter.isInClosureArguments(at: previousIndex), .startOfScope("{"):
                guard formatter.next(.nonSpaceOrCommentOrLinebreak, after: closingIndex) == .keyword("in"),
                      formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i) != closingIndex,
                      formatter.index(of: .delimiter(":"), in: i + 1 ..< closingIndex) == nil
                else {
                    // Not a closure
                    if formatter.last(.nonSpaceOrComment, before: i) == .endOfScope("]") {
                        return
                    }
                    fallthrough
                }
                if formatter.tokens[i + 1 ..< closingIndex].contains(.identifier("self")) {
                    return
                }
                if let index = formatter.tokens[i + 1 ..< closingIndex].index(of: .identifier("_")),
                   formatter.next(.nonSpaceOrComment, after: index)?.isIdentifier == true
                {
                    return
                }
                formatter.removeParen(at: closingIndex)
                formatter.removeParen(at: i)
            case .stringBody, .operator("?", .postfix), .operator("!", .postfix), .operator("->", .infix):
                return
            case .identifier: // TODO: are trailing closures allowed in other cases?
                // Parens before closure
                guard closingIndex == formatter.index(of: .nonSpace, after: i),
                      let openingIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: closingIndex, if: {
                          $0 == .startOfScope("{")
                      }),
                      formatter.isStartOfClosure(at: openingIndex)
                else {
                    return
                }
                formatter.removeParen(at: closingIndex)
                formatter.removeParen(at: i)
            case let .keyword(name) where !conditionals.contains(name) && !["let", "var"].contains(name):
                return
            case .endOfScope("}"), .endOfScope(")"), .endOfScope("]"), .endOfScope(">"):
                if formatter.tokens[previousIndex + 1 ..< i].contains(where: { $0.isLinebreak }) {
                    fallthrough
                }
                return // Probably a method invocation
            case .delimiter(","), .endOfScope, .keyword:
                let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: closingIndex) ?? .space("")
                guard formatter.index(of: .endOfScope("}"), before: closingIndex) == nil,
                      ![.endOfScope("}"), .endOfScope(">")].contains(token) ||
                      ![.startOfScope("{"), .delimiter(",")].contains(nextToken)
                else {
                    return
                }
                let string = token.string
                if ![.startOfScope("{"), .delimiter(","), .startOfScope(":")].contains(nextToken),
                   !(string == "for" && nextToken == .keyword("in")),
                   !(string == "guard" && nextToken == .keyword("else"))
                {
                    // TODO: this is confusing - refactor to move fallthrough to end of case
                    fallthrough
                }
                if formatter.index(of: .nonSpaceOrCommentOrLinebreak, in: i + 1 ..< closingIndex) == nil ||
                    formatter.index(of: .delimiter(","), in: i + 1 ..< closingIndex) != nil
                {
                    // Might be a tuple, so we won't remove the parens
                    // TODO: improve the logic here so we don't misidentify function calls as tuples
                    return
                }
                formatter.removeParen(at: closingIndex)
                formatter.removeParen(at: i)
            case .operator(_, .infix):
                guard let nextIndex = formatter.index(of: .nonSpaceOrComment, after: i, if: {
                    $0 == .startOfScope("{")
                }), let lastIndex = formatter.index(of: .endOfScope("}"), after: nextIndex),
                formatter.index(of: .nonSpaceOrComment, before: closingIndex) == lastIndex else {
                    fallthrough
                }
                formatter.removeParen(at: closingIndex)
                formatter.removeParen(at: i)
            default:
                if let range = innerParens {
                    formatter.removeParen(at: range.upperBound)
                    formatter.removeParen(at: range.lowerBound)
                    closingIndex = formatter.index(of: .endOfScope(")"), after: i)!
                    innerParens = nil
                }
                if token == .startOfScope("("),
                   formatter.last(.nonSpaceOrComment, before: previousIndex) == .identifier("Selector")
                {
                    return
                }
                if let nextNonLinebreak = formatter.next(.nonSpaceOrComment, after: closingIndex) {
                    switch nextNonLinebreak {
                    case .startOfScope("["), .startOfScope("("), .operator(_, .postfix):
                        return
                    default:
                        break
                    }
                }
                guard formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i) != closingIndex,
                      formatter.index(in: i + 1 ..< closingIndex, where: {
                          switch $0 {
                          case .operator(".", _):
                              return false
                          case .operator, .keyword("as"), .keyword("is"), .keyword("try"):
                              switch token {
                              case .operator(_, .prefix), .operator(_, .infix), .keyword("as"), .keyword("is"):
                                  return true
                              default:
                                  break
                              }
                              switch nextToken {
                              case .operator(_, .postfix), .operator(_, .infix), .keyword("as"), .keyword("is"):
                                  return true
                              default:
                                  return false
                              }
                          case .delimiter(","), .delimiter(":"), .delimiter(";"), .startOfScope("{"):
                              return true
                          default:
                              return false
                          }
                      }) == nil
                else {
                    return
                }
                if formatter.next(.nonSpaceOrCommentOrLinebreak, after: i) == .keyword("#file") {
                    return
                }
                formatter.removeParen(at: closingIndex)
                formatter.removeParen(at: i)
            }
        }
    }

    /// Remove redundant `get {}` clause inside read-only computed property
    public let redundantGet = FormatRule(
        help: "Remove unneeded `get` clause inside computed properties."
    ) { formatter in
        formatter.forEach(.identifier("get")) { i, _ in
            if formatter.isAccessorKeyword(at: i, checkKeyword: false),
               let prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i, if: {
                   $0 == .startOfScope("{")
               }), let openIndex = formatter.index(of: .startOfScope("{"), after: i),
               let closeIndex = formatter.index(of: .endOfScope("}"), after: openIndex),
               let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: closeIndex, if: {
                   $0 == .endOfScope("}")
               })
            {
                formatter.removeTokens(in: closeIndex ..< nextIndex)
                formatter.removeTokens(in: prevIndex + 1 ... openIndex)
                // TODO: fix-up indenting of lines in between removed braces
            }
        }
    }

    /// Remove redundant `= nil` initialization for Optional properties
    public let redundantNilInit = FormatRule(
        help: "Remove redundant `nil` default value (Optional vars are nil by default)."
    ) { formatter in
        func search(from index: Int) {
            if let optionalIndex = formatter.index(of: .unwrapOperator, after: index) {
                if formatter.index(of: .endOfStatement, in: index + 1 ..< optionalIndex) != nil {
                    return
                }
                if !formatter.tokens[optionalIndex - 1].isSpaceOrCommentOrLinebreak,
                   let equalsIndex = formatter.index(of: .nonSpaceOrLinebreak, after: optionalIndex, if: {
                       $0 == .operator("=", .infix)
                   }), let nilIndex = formatter.index(of: .nonSpaceOrLinebreak, after: equalsIndex, if: {
                       $0 == .identifier("nil")
                   })
                {
                    formatter.removeTokens(in: optionalIndex + 1 ... nilIndex)
                }
                search(from: optionalIndex)
            }
        }

        // Check modifiers don't include `lazy`
        formatter.forEach(.keyword("var")) { i, _ in
            if formatter.modifiersForDeclaration(at: i, contains: {
                $1 == "lazy" || ($1 != "@objc" && $1.hasPrefix("@"))
            }) {
                return // Can't remove the init
            }
            // Check this isn't a Codable
            if let scopeIndex = formatter.index(of: .startOfScope("{"), before: i) {
                var prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: scopeIndex)
                loop: while let index = prevIndex {
                    switch formatter.tokens[index] {
                    case .identifier("Codable"), .identifier("Decodable"):
                        return // Can't safely remove the default value
                    case .keyword("struct"):
                        if formatter.index(of: .keyword("init"), after: scopeIndex) == nil {
                            return // Can't safely remove the default value
                        }
                        break loop
                    case .keyword:
                        break loop
                    default:
                        break
                    }
                    prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: index)
                }
            }
            // Find the nil
            search(from: i)
        }
    }

    /// Remove redundant let/var for unnamed variables
    public let redundantLet = FormatRule(
        help: "Remove redundant `let`/`var` from ignored variables."
    ) { formatter in
        formatter.forEach(.identifier("_")) { i, _ in
            guard formatter.next(.nonSpaceOrCommentOrLinebreak, after: i) != .delimiter(":"),
                  let prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i, if: {
                      [.keyword("let"), .keyword("var")].contains($0)
                  }),
                  let nextNonSpaceIndex = formatter.index(of: .nonSpaceOrLinebreak, after: prevIndex)
            else {
                return
            }
            if let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: prevIndex) {
                switch prevToken {
                case .keyword("if"), .keyword("guard"), .keyword("while"),
                     .delimiter(",") where formatter.currentScope(at: i) != .startOfScope("("):
                    return
                default:
                    break
                }
            }
            formatter.removeTokens(in: prevIndex ..< nextNonSpaceIndex)
        }
    }

    /// Remove redundant pattern in case statements
    public let redundantPattern = FormatRule(
        help: "Remove redundant pattern matching parameter syntax."
    ) { formatter in
        func redundantBindings(in range: Range<Int>) -> Bool {
            var isEmpty = true
            for token in formatter.tokens[range.lowerBound ..< range.upperBound] {
                switch token {
                case .identifier("_"):
                    isEmpty = false
                case .space, .linebreak, .delimiter(","), .keyword("let"), .keyword("var"):
                    break
                default:
                    return false
                }
            }
            return !isEmpty
        }

        formatter.forEach(.startOfScope("(")) { i, _ in
            let prevIndex = formatter.index(of: .nonSpaceOrComment, before: i)
            if let prevIndex = prevIndex, let prevToken = formatter.token(at: prevIndex),
               [.keyword("case"), .endOfScope("case")].contains(prevToken)
            {
                // Not safe to remove
                return
            }
            guard let endIndex = formatter.index(of: .endOfScope(")"), after: i),
                  let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: endIndex),
                  [.startOfScope(":"), .operator("=", .infix)].contains(nextToken),
                  redundantBindings(in: i + 1 ..< endIndex)
            else {
                return
            }
            formatter.removeTokens(in: i ... endIndex)
            if let prevIndex = prevIndex, formatter.tokens[prevIndex].isIdentifier,
               formatter.last(.nonSpaceOrComment, before: prevIndex)?.string == "."
            {
                // Was an enum case
                return
            }
            // Was an assignment
            formatter.insert(.identifier("_"), at: i)
            if formatter.token(at: i - 1).map({ $0.isSpaceOrLinebreak }) != true {
                formatter.insert(.space(" "), at: i)
            }
        }
    }

    /// Remove redundant raw string values for case statements
    public let redundantRawValues = FormatRule(
        help: "Remove redundant raw string values for enum cases."
    ) { formatter in
        formatter.forEach(.keyword("enum")) { i, _ in
            guard let nameIndex = formatter.index(
                of: .nonSpaceOrCommentOrLinebreak, after: i, if: { $0.isIdentifier }
            ), let colonIndex = formatter.index(
                of: .nonSpaceOrCommentOrLinebreak, after: nameIndex, if: { $0 == .delimiter(":") }
            ), formatter.next(.nonSpaceOrCommentOrLinebreak, after: colonIndex) == .identifier("String"),
            let braceIndex = formatter.index(of: .startOfScope("{"), after: colonIndex) else {
                return
            }
            var lastIndex = formatter.index(of: .keyword("case"), after: braceIndex)
            while var index = lastIndex {
                guard let nameIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index, if: {
                    $0.isIdentifier
                }) else { break }
                if let equalsIndex = formatter.index(of: .nonSpaceOrLinebreak, after: nameIndex, if: {
                    $0 == .operator("=", .infix)
                }), let quoteIndex = formatter.index(of: .nonSpaceOrLinebreak, after: equalsIndex, if: {
                    $0 == .startOfScope("\"")
                }), formatter.token(at: quoteIndex + 2) == .endOfScope("\"") {
                    if formatter.tokens[nameIndex].unescaped() == formatter.token(at: quoteIndex + 1)?.string {
                        formatter.removeTokens(in: nameIndex + 1 ... quoteIndex + 2)
                        index = nameIndex
                    } else {
                        index = quoteIndex + 2
                    }
                } else {
                    index = nameIndex
                }
                lastIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index, if: {
                    $0 == .delimiter(",")
                }) ?? formatter.index(of: .keyword("case"), after: index)
            }
        }
    }

    /// Remove redundant void return values for function declarations
    public let redundantVoidReturnType = FormatRule(
        help: "Remove explicit `Void` return type."
    ) { formatter in
        formatter.forEach(.operator("->", .infix)) { i, _ in
            guard var endIndex = formatter.index(of: .nonSpace, after: i) else { return }
            switch formatter.tokens[endIndex] {
            case .identifier("Void"):
                break
            case .startOfScope("("):
                guard let nextIndex = formatter.index(of: .nonSpace, after: endIndex) else { return }
                switch formatter.tokens[nextIndex] {
                case .endOfScope(")"):
                    endIndex = nextIndex
                case .identifier("Void"):
                    guard let nextIndex = formatter.index(of: .nonSpace, after: nextIndex),
                          case .endOfScope(")") = formatter.tokens[nextIndex] else { return }
                    endIndex = nextIndex
                default:
                    return
                }
            default:
                return
            }
            guard formatter.next(.nonSpaceOrCommentOrLinebreak, after: endIndex) == .startOfScope("{") else {
                return
            }
            guard let prevIndex = formatter.index(of: .endOfScope(")"), before: i),
                  let startIndex = formatter.index(of: .startOfScope("("), before: prevIndex),
                  let startToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: startIndex),
                  startToken.isIdentifier || [.startOfScope("{"), .endOfScope("]")].contains(startToken)
            else {
                return
            }
            formatter.removeTokens(in: i ..< formatter.index(of: .nonSpace, after: endIndex)!)
        }
    }

    /// Remove redundant return keyword from single-line closures
    public let redundantReturn = FormatRule(
        help: "Remove unneeded `return` keyword."
    ) { formatter in
        formatter.forEach(.keyword("return")) { i, _ in
            guard let startIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i) else {
                return
            }
            switch formatter.tokens[startIndex] {
            case .keyword("in"):
                break
            case .startOfScope("{"):
                guard var prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: startIndex) else {
                    break
                }
                if formatter.options.swiftVersion < "5.1", formatter.isAccessorKeyword(at: prevIndex) {
                    return
                }
                if formatter.tokens[prevIndex] == .endOfScope(")"),
                   let j = formatter.index(of: .startOfScope("("), before: prevIndex)
                {
                    prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: j) ?? j
                    if formatter.tokens[prevIndex] == .operator("?", .postfix) {
                        prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: prevIndex) ?? prevIndex
                    }
                    let prevToken = formatter.tokens[prevIndex]
                    guard prevToken.isIdentifier || prevToken == .keyword("init") else {
                        return
                    }
                }
                let prevToken = formatter.tokens[prevIndex]
                guard ![.delimiter(":"), .startOfScope("(")].contains(prevToken), var prevKeywordIndex =
                    formatter.indexOfLastSignificantKeyword(at: startIndex, excluding: ["where"])
                else {
                    break
                }
                switch formatter.tokens[prevKeywordIndex].string {
                case "let", "var":
                    guard formatter.options.swiftVersion >= "5.1" || prevToken == .operator("=", .infix) ||
                        formatter.lastIndex(of: .operator("=", .infix), in: prevKeywordIndex + 1 ..< prevIndex) != nil,
                        !formatter.isConditionalStatement(at: prevKeywordIndex)
                    else {
                        return
                    }
                case "func", "throws", "rethrows", "init", "subscript":
                    if formatter.options.swiftVersion < "5.1" {
                        return
                    }
                default:
                    return
                }
            default:
                return
            }
            if formatter.index(of: .keyword("return"), after: i) != nil {
                return
            }
            formatter.removeToken(at: i)
            if var nextIndex = formatter.index(of: .nonSpace, after: i - 1, if: { $0.isLinebreak }) {
                if let i = formatter.index(of: .nonSpaceOrLinebreak, after: nextIndex) {
                    nextIndex = i - 1
                }
                formatter.removeTokens(in: i ... nextIndex)
            } else if formatter.token(at: i)?.isSpace == true {
                formatter.removeToken(at: i)
            }
        }
    }

    /// Remove redundant backticks around non-keywords, or in places where keywords don't need escaping
    public let redundantBackticks = FormatRule(
        help: "Remove redundant backticks around identifiers."
    ) { formatter in
        formatter.forEach(.identifier) { i, token in
            guard token.string.first == "`", !formatter.backticksRequired(at: i) else {
                return
            }
            formatter.replaceToken(at: i, with: .identifier(token.unescaped()))
        }
    }

    /// Remove redundant self keyword
    // TODO: restructure this to use forEachToken to avoid exposing processCommentBody mechanism
    public let redundantSelf = FormatRule(
        help: "Insert/remove explicit `self` where applicable.",
        options: ["self", "selfrequired"]
    ) { formatter in
        guard !formatter.options.fragment else { return }

        func processBody(at index: inout Int,
                         localNames: Set<String>,
                         members: Set<String>,
                         typeStack: inout [String],
                         membersByType: inout [String: Set<String>],
                         classMembersByType: inout [String: Set<String>],
                         isTypeRoot: Bool,
                         isInit: Bool)
        {
            let selfRequired = formatter.options.selfRequired + [
                "expect", // Special case to support autoclosure arguments in the Nimble framework
            ]
            let explicitSelf = formatter.options.explicitSelf
            let isWhereClause = index > 0 && formatter.tokens[index - 1] == .keyword("where")
            assert(isWhereClause || formatter.currentScope(at: index).map { token -> Bool in
                [.startOfScope("{"), .startOfScope(":"), .startOfScope("#if")].contains(token)
            } ?? true)
            let isCaseClause = !isWhereClause && index > 0 &&
                [.endOfScope("case"), .endOfScope("default")].contains(formatter.tokens[index - 1])
            if explicitSelf == .remove {
                // Check if scope actually includes self before we waste a bunch of time
                var scopeCount = 0
                loop: for i in index ..< formatter.tokens.count {
                    switch formatter.tokens[i] {
                    case .identifier("self"):
                        break loop // Contains self
                    case .startOfScope("{") where isWhereClause && scopeCount == 0:
                        return // Does not contain self
                    case .startOfScope("{"), .startOfScope(":"):
                        scopeCount += 1
                    case .endOfScope("}"), .endOfScope("case"), .endOfScope("default"):
                        if scopeCount == 0 || (scopeCount == 1 && isCaseClause) {
                            index = i + 1
                            return // Does not contain self
                        }
                        scopeCount -= 1
                    default:
                        break
                    }
                }
            }
            // Gather members & local variables
            let type = (isTypeRoot && typeStack.count == 1) ? typeStack.first : nil
            var members = type.flatMap { membersByType[$0] } ?? members
            var classMembers = type.flatMap { classMembersByType[$0] } ?? Set<String>()
            var localNames = localNames
            if !isTypeRoot || explicitSelf != .remove {
                var i = index
                var classOrStatic = false
                outer: while let token = formatter.token(at: i) {
                    switch token {
                    case .keyword("import"):
                        guard let nextIndex = formatter.index(of: .identifier, after: i) else {
                            return formatter.fatalError("Expected identifier", at: i)
                        }
                        i = nextIndex
                    case .keyword("class"), .keyword("static"):
                        classOrStatic = true
                    case .keyword("repeat"):
                        guard let nextIndex = formatter.index(of: .keyword("while"), after: i) else {
                            return formatter.fatalError("Expected while", at: i)
                        }
                        i = nextIndex
                    case .keyword("if"), .keyword("while"):
                        if explicitSelf == .insert {
                            break
                        }
                        guard let nextIndex = formatter.index(of: .startOfScope("{"), after: i) else {
                            return formatter.fatalError("Expected {", at: i)
                        }
                        i = nextIndex
                        continue
                    case .keyword("switch"):
                        guard let nextIndex = formatter.index(of: .startOfScope("{"), after: i) else {
                            return formatter.fatalError("Expected {", at: i)
                        }
                        guard var endIndex = formatter.index(of: .endOfScope, after: nextIndex) else {
                            return formatter.fatalError("Expected }", at: i)
                        }
                        while formatter.tokens[endIndex] != .endOfScope("}") {
                            guard let nextIndex = formatter.index(of: .startOfScope(":"), after: endIndex) else {
                                return formatter.fatalError("Expected :", at: i)
                            }
                            guard let _endIndex = formatter.index(of: .endOfScope, after: nextIndex) else {
                                return formatter.fatalError("Expected end of scope", at: i)
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
                            return formatter.fatalError("Unexpected class/static \(token.string)", at: index)
                        }
                        processFunction(at: &index, localNames: localNames, members: classMembers,
                                        typeStack: &typeStack, membersByType: &membersByType,
                                        classMembersByType: &classMembersByType)
                        classOrStatic = false
                    } else {
                        processFunction(at: &index, localNames: localNames, members: members,
                                        typeStack: &typeStack, membersByType: &membersByType,
                                        classMembersByType: &classMembersByType)
                    }
                    assert(formatter.token(at: index) != .endOfScope("}"))
                    continue
                case .keyword("static"):
                    classOrStatic = true
                case .keyword("class") where
                    formatter.next(.nonSpaceOrCommentOrLinebreak, after: index)?.isIdentifier == false:
                    if formatter.last(.nonSpaceOrCommentOrLinebreak, before: index) != .delimiter(":") {
                        classOrStatic = true
                    }
                case .keyword("where") where lastKeyword == "protocol", .keyword("protocol"):
                    if let startIndex = formatter.index(of: .startOfScope("{"), after: index),
                       let endIndex = formatter.endOfScope(at: startIndex)
                    {
                        index = endIndex
                    }
                case .keyword("extension"), .keyword("struct"), .keyword("enum"), .keyword("class"),
                     .keyword("where") where ["extension", "struct", "enum", "class"].contains(lastKeyword):
                    guard formatter.last(.nonSpaceOrCommentOrLinebreak, before: index) != .keyword("import"),
                          let scopeStart = formatter.index(of: .startOfScope("{"), after: index) else { return }
                    guard let nameToken = formatter.next(.identifier, after: index),
                          case let .identifier(name) = nameToken
                    else {
                        return formatter.fatalError("Expected identifier", at: index)
                    }
                    index = scopeStart + 1
                    typeStack.append(name)
                    processBody(at: &index, localNames: ["init"], members: [], typeStack: &typeStack,
                                membersByType: &membersByType, classMembersByType: &classMembersByType,
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
                            case .keyword("as"), .keyword("is"), .keyword("try"), .keyword("await"):
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
                        formatter.processDeclaredVariables(at: &index, names: &scopedNames,
                                                           removeSelf: explicitSelf != .insert)
                        guard let startIndex = formatter.index(of: .startOfScope("{"), after: index) else {
                            return formatter.fatalError("Expected {", at: index)
                        }
                        index = startIndex + 1
                        processBody(at: &index, localNames: scopedNames, members: members, typeStack: &typeStack,
                                    membersByType: &membersByType, classMembersByType: &classMembersByType,
                                    isTypeRoot: false, isInit: isInit)
                        lastKeyword = ""
                    default:
                        lastKeyword = token.string
                    }
                    classOrStatic = false
                case .keyword("where") where lastKeyword == "in",
                     .startOfScope("{") where lastKeyword == "in" && !formatter.isStartOfClosure(at: index):
                    lastKeyword = ""
                    var localNames = localNames
                    guard let keywordIndex = formatter.index(of: .keyword("in"), before: index),
                          let prevKeywordIndex = formatter.index(of: .keyword("for"), before: keywordIndex)
                    else {
                        return formatter.fatalError("Expected for keyword", at: index)
                    }
                    for token in formatter.tokens[prevKeywordIndex + 1 ..< keywordIndex] {
                        if case let .identifier(name) = token, name != "_" {
                            localNames.insert(token.unescaped())
                        }
                    }
                    index += 1
                    processBody(at: &index, localNames: localNames, members: members, typeStack: &typeStack,
                                membersByType: &membersByType, classMembersByType: &classMembersByType,
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
                       selfRequired.contains(fn)
                    {
                        index = formatter.index(of: .endOfScope(")"), after: index) ?? index
                        break
                    }
                    fallthrough
                case .startOfScope where token.isStringDelimiter, .startOfScope("#if"), .startOfScope("["):
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
                                isTypeRoot: false, isInit: isInit)
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
                                         classMembersByType: &classMembersByType)
                    }
                    continue
                case .startOfScope:
                    index = formatter.endOfScope(at: index) ?? (formatter.tokens.count - 1)
                case .identifier("self"):
                    guard formatter.isEnabled, !isTypeRoot, !localNames.contains("self"),
                          let dotIndex = formatter.index(of: .nonSpaceOrLinebreak, after: index, if: {
                              $0 == .operator(".", .infix)
                          }), let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: dotIndex, if: {
                              $0.isIdentifier && !localNames.contains($0.unescaped())
                          })
                    else {
                        break
                    }
                    if explicitSelf == .insert {
                        break
                    } else if explicitSelf == .initOnly, isInit {
                        if formatter.next(.nonSpaceOrCommentOrLinebreak, after: nextIndex) == .operator("=", .infix) {
                            break
                        } else if let scopeEnd = formatter.index(of: .endOfScope(")"), after: nextIndex),
                                  formatter.next(.nonSpaceOrCommentOrLinebreak, after: scopeEnd) == .operator("=", .infix)
                        {
                            break
                        }
                    }
                    if !formatter.backticksRequired(at: nextIndex, ignoreLeadingDot: true) {
                        formatter.removeTokens(in: index ..< nextIndex)
                    }
                case .identifier("type"): // Special case for type(of:)
                    guard let parenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index, if: {
                        $0 == .startOfScope("(")
                    }), formatter.next(.nonSpaceOrCommentOrLinebreak, after: parenIndex) == .identifier("of") else {
                        fallthrough
                    }
                case .identifier:
                    guard formatter.isEnabled && !isTypeRoot else {
                        break
                    }
                    if explicitSelf == .insert {
                        // continue
                    } else if explicitSelf == .initOnly, isInit {
                        if formatter.next(.nonSpaceOrCommentOrLinebreak, after: index) == .operator("=", .infix) {
                            // continue
                        } else if let scopeEnd = formatter.index(of: .endOfScope(")"), after: index),
                                  formatter.next(.nonSpaceOrCommentOrLinebreak, after: scopeEnd) == .operator("=", .infix)
                        {
                            // continue
                        } else {
                            if token.string == "lazy" {
                                lastKeyword = "lazy"
                                lastKeywordIndex = index
                            }
                            break
                        }
                    } else {
                        if token.string == "lazy" {
                            lastKeyword = "lazy"
                            lastKeywordIndex = index
                        }
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
                    formatter.insert([.identifier("self"), .operator(".", .infix)], at: index)
                    index += 2
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
                        // TODO: fix this bug
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
                              classMembersByType: inout [String: Set<String>])
        {
            assert(formatter.tokens[index] == .startOfScope("{"))
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
                            isTypeRoot: false, isInit: false)
            }
        }
        func processFunction(at index: inout Int, localNames: Set<String>, members: Set<String>,
                             typeStack: inout [String],
                             membersByType: inout [String: Set<String>],
                             classMembersByType: inout [String: Set<String>])
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
                     .keyword("async"),
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
                                 classMembersByType: &classMembersByType)
                return
            } else {
                index = bodyStartIndex + 1
                processBody(at: &index,
                            localNames: localNames,
                            members: members,
                            typeStack: &typeStack,
                            membersByType: &membersByType,
                            classMembersByType: &classMembersByType,
                            isTypeRoot: false,
                            isInit: startToken == .keyword("init"))
            }
        }
        var typeStack = [String]()
        var membersByType = [String: Set<String>]()
        var classMembersByType = [String: Set<String>]()
        var index = 0
        processBody(at: &index, localNames: ["init"], members: [], typeStack: &typeStack,
                    membersByType: &membersByType, classMembersByType: &classMembersByType,
                    isTypeRoot: false, isInit: false)
    }

    /// Replace unused arguments with an underscore
    public let unusedArguments = FormatRule(
        help: "Mark unused function arguments with `_`.",
        options: ["stripunusedargs"]
    ) { formatter in
        guard !formatter.options.fragment else { return }

        func removeUsed<T>(from argNames: inout [String], with associatedData: inout [T], in range: CountableRange<Int>) {
            for i in range {
                let token = formatter.tokens[i]
                if case .identifier = token, let index = argNames.index(of: token.unescaped()),
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
        // Closure arguments
        formatter.forEach(.keyword("in")) { i, _ in
            var argNames = [String]()
            var nameIndexPairs = [(Int, Int)]()
            if let start = formatter.index(of: .startOfScope("{"), before: i) {
                var index = i - 1
                var argCountStack = [0]
                while index > start {
                    let token = formatter.tokens[index]
                    switch token {
                    case let .keyword(name) where !token.isAttribute && !name.hasPrefix("#") && name != "inout":
                        return
                    case .endOfScope("}"), .startOfScope("{"):
                        return
                    case .endOfScope(")"):
                        argCountStack.append(argNames.count)
                    case .startOfScope("("):
                        argCountStack.removeLast()
                    case .delimiter(","):
                        argCountStack[argCountStack.count - 1] = argNames.count
                    case .operator("->", .infix):
                        // Everything after this was part of return value
                        let count = argCountStack.last ?? 0
                        argNames.removeSubrange(count ..< argNames.count)
                        nameIndexPairs.removeSubrange(count ..< nameIndexPairs.count)
                    case .identifier:
                        guard argCountStack.count < 3,
                              let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: index), [
                                  .delimiter(","), .startOfScope("("), .startOfScope("{"), .endOfScope("]"),
                              ].contains(prevToken), let scopeStart = formatter.index(of: .startOfScope, before: index),
                              ![.startOfScope("["), .startOfScope("<")].contains(formatter.tokens[scopeStart])
                        else {
                            break
                        }
                        let name = token.unescaped()
                        if let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index),
                           let nextToken = formatter.token(at: nextIndex), case .identifier = nextToken
                        {
                            let internalName = nextToken.unescaped()
                            if internalName != "_" {
                                argNames.append(internalName)
                                nameIndexPairs.append((index, nextIndex))
                            }
                        } else if name != "_" {
                            argNames.append(name)
                            nameIndexPairs.append((index, index))
                        }
                    default:
                        break
                    }
                    index -= 1
                }
            }
            guard !argNames.isEmpty, let bodyEndIndex = formatter.index(of: .endOfScope("}"), after: i) else {
                return
            }
            removeUsed(from: &argNames, with: &nameIndexPairs, in: i + 1 ..< bodyEndIndex)
            for pair in nameIndexPairs {
                if case .identifier("_") = formatter.tokens[pair.0], pair.0 != pair.1 {
                    formatter.removeToken(at: pair.1)
                    if formatter.tokens[pair.1 - 1] == .space(" ") {
                        formatter.removeToken(at: pair.1 - 1)
                    }
                } else {
                    formatter.replaceToken(at: pair.1, with: .identifier("_"))
                }
            }
        }
        // Function arguments
        guard formatter.options.stripUnusedArguments != .closureOnly else {
            return
        }
        formatter.forEachToken { i, token in
            guard case let .keyword(keyword) = token, ["func", "init", "subscript"].contains(keyword),
                  let startIndex = formatter.index(of: .startOfScope("("), after: i),
                  let endIndex = formatter.index(of: .endOfScope(")"), after: startIndex) else { return }
            let isOperator = (keyword == "subscript") ||
                (keyword == "func" && formatter.next(.nonSpaceOrCommentOrLinebreak, after: i)?.isOperator == true)
            var index = startIndex
            var argNames = [String]()
            var nameIndexPairs = [(Int, Int)]()
            while index < endIndex {
                guard let externalNameIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index, if: {
                    if case let .identifier(name) = $0 {
                        return formatter.options.stripUnusedArguments != .unnamedOnly || name == "_"
                    }
                    // Probably an empty argument list
                    return false
                }) else { return }
                guard let nextIndex =
                    formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: externalNameIndex) else { return }
                let nextToken = formatter.tokens[nextIndex]
                switch nextToken {
                case let .identifier(name):
                    if name != "_" {
                        argNames.append(nextToken.unescaped())
                        nameIndexPairs.append((externalNameIndex, nextIndex))
                    }
                case .delimiter(":"):
                    let externalNameToken = formatter.tokens[externalNameIndex]
                    if case let .identifier(name) = externalNameToken, name != "_" {
                        argNames.append(externalNameToken.unescaped())
                        nameIndexPairs.append((externalNameIndex, externalNameIndex))
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
                     .identifier("async"),
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
            removeUsed(from: &argNames, with: &nameIndexPairs, in: bodyStartIndex + 1 ..< bodyEndIndex)
            for pair in nameIndexPairs.reversed() {
                if pair.0 == pair.1 {
                    if isOperator {
                        formatter.replaceToken(at: pair.0, with: .identifier("_"))
                    } else {
                        formatter.insert(.identifier("_"), at: pair.0 + 1)
                        formatter.insert(.space(" "), at: pair.0 + 1)
                    }
                } else if case .identifier("_") = formatter.tokens[pair.0] {
                    formatter.removeToken(at: pair.1)
                    if formatter.tokens[pair.1 - 1] == .space(" ") {
                        formatter.removeToken(at: pair.1 - 1)
                    }
                } else {
                    formatter.replaceToken(at: pair.1, with: .identifier("_"))
                }
            }
        }
    }

    /// Move `let` and `var` inside patterns to the beginning
    public let hoistPatternLet = FormatRule(
        help: "Reposition `let` or `var` bindings within pattern.",
        options: ["patternlet"]
    ) { formatter in
        func indicesOf(_ keyword: String, in range: CountableRange<Int>) -> [Int]? {
            var indices = [Int]()
            var keywordFound = false, identifierFound = false
            var count = 0
            for index in range {
                switch formatter.tokens[index] {
                case .keyword(keyword):
                    indices.append(index)
                    keywordFound = true
                case .identifier("_"):
                    break
                case .identifier where formatter.last(.nonSpaceOrComment, before: index) != .operator(".", .prefix):
                    identifierFound = true
                    if keywordFound {
                        count += 1
                    }
                case .delimiter(","):
                    guard keywordFound || !identifierFound else {
                        return nil
                    }
                    keywordFound = false
                    identifierFound = false
                case .startOfScope("{"):
                    return nil
                case .startOfScope("<"):
                    // See: https://github.com/nicklockwood/SwiftFormat/issues/768
                    return nil
                default:
                    break
                }
            }
            return (keywordFound || !identifierFound) && count > 0 ? indices : nil
        }

        formatter.forEach(.startOfScope("(")) { i, _ in
            let hoist = formatter.options.hoistPatternLet
            // Check if pattern already starts with let/var
            guard let endIndex = formatter.index(of: .endOfScope(")"), after: i),
                  let prevIndex = formatter.index(before: i, where: {
                      switch $0 {
                      case .operator(".", _), .keyword("let"), .keyword("var"):
                          return false
                      case .endOfScope, .delimiter, .operator, .keyword:
                          return true
                      default:
                          return false
                      }
                  })
            else {
                return
            }
            switch formatter.tokens[prevIndex] {
            case .endOfScope("case"), .keyword("case"), .keyword("catch"):
                break
            case .delimiter(","):
                loop: for token in formatter.tokens[0 ..< prevIndex].reversed() {
                    switch token {
                    case .endOfScope("case"), .keyword("catch"):
                        break loop
                    case .keyword("var"), .keyword("let"):
                        break
                    case .keyword:
                        // Tuple assignment
                        return
                    default:
                        break
                    }
                }
            default:
                return
            }
            let startIndex = prevIndex + 1
            if let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: prevIndex),
               case let .keyword(keyword) = formatter.tokens[nextIndex], ["let", "var"].contains(keyword)
            {
                if hoist {
                    // No changes needed
                    return
                }
                // Find variable indices
                var indices = [Int]()
                var index = i + 1
                var wasParenOrCommaOrLabel = true
                while index < endIndex {
                    let token = formatter.tokens[index]
                    switch token {
                    case .delimiter(","), .startOfScope("("), .delimiter(":"):
                        wasParenOrCommaOrLabel = true
                    case let .identifier(name) where wasParenOrCommaOrLabel:
                        wasParenOrCommaOrLabel = false
                        let next = formatter.next(.nonSpaceOrComment, after: index)
                        if name != "_", next != .operator(".", .infix), next != .delimiter(":") {
                            indices.append(index)
                        }
                    case _ where token.isSpaceOrCommentOrLinebreak:
                        break
                    default:
                        wasParenOrCommaOrLabel = false
                    }
                    index += 1
                }
                // Insert keyword at indices
                for index in indices.reversed() {
                    formatter.insert([.keyword(keyword), .space(" ")], at: index)
                }
                // Remove keyword
                let range = startIndex ... nextIndex
                formatter.removeTokens(in: range)
            } else if hoist {
                // Find let/var keyword indices
                var keyword = "let"
                guard let indices: [Int] = {
                    guard let indices = indicesOf(keyword, in: i + 1 ..< endIndex) else {
                        keyword = "var"
                        return indicesOf(keyword, in: i + 1 ..< endIndex)
                    }
                    return indices
                }() else {
                    return
                }
                // Remove keywords inside parens
                for index in indices.reversed() {
                    if formatter.tokens[index + 1].isSpace {
                        formatter.removeToken(at: index + 1)
                    }
                    formatter.removeToken(at: index)
                }
                // Insert keyword before parens
                formatter.insert(.keyword(keyword), at: startIndex)
                if let nextToken = formatter.token(at: startIndex + 1), !nextToken.isSpaceOrLinebreak {
                    formatter.insert(.space(" "), at: startIndex + 1)
                }
                if let prevToken = formatter.token(at: startIndex - 1),
                   !prevToken.isSpaceOrCommentOrLinebreak, !prevToken.isStartOfScope
                {
                    formatter.insert(.space(" "), at: startIndex)
                }
            }
        }
    }

    public let wrap = FormatRule(
        help: "Wrap lines that exceed the specified maximum width.",
        options: ["maxwidth", "nowrapoperators", "assetliterals"],
        sharedOptions: ["wraparguments", "wrapparameters", "wrapcollections", "closingparen", "indent",
                        "trimwhitespace", "linebreaks", "tabwidth", "maxwidth", "smarttabs", "wrapreturntype",
                        "wrapconditions", "conditionswrap"]
    ) { formatter in
        let maxWidth = formatter.options.maxWidth
        guard maxWidth > 0 else { return }

        // Wrap collections first to avoid conflict
        formatter.wrapCollectionsAndArguments(completePartialWrapping: false,
                                              wrapSingleArguments: false)

        // Wrap other line types
        var currentIndex = 0
        var indent = ""
        var alreadyLinewrapped = false

        func isLinewrapToken(_ token: Token?) -> Bool {
            switch token {
            case .delimiter?, .operator(_, .infix)?:
                return true
            default:
                return false
            }
        }

        formatter.forEachToken(onlyWhereEnabled: false) { i, token in
            if i < currentIndex {
                return
            }
            if token.isLinebreak {
                indent = formatter.indentForLine(at: i + 1)
                alreadyLinewrapped = isLinewrapToken(formatter.last(.nonSpaceOrComment, before: i))
                currentIndex = i + 1
            } else if let breakPoint = formatter.indexWhereLineShouldWrapInLine(at: i) {
                if !alreadyLinewrapped {
                    indent += formatter.linewrapIndent(at: breakPoint)
                }
                alreadyLinewrapped = true
                if formatter.isEnabled {
                    let spaceAdded = formatter.insertSpace(indent, at: breakPoint + 1)
                    formatter.insertLinebreak(at: breakPoint + 1)
                    currentIndex = breakPoint + spaceAdded + 2
                } else {
                    currentIndex = breakPoint + 1
                }
            } else {
                currentIndex = formatter.endOfLine(at: i)
            }
        }

        formatter.wrapCollectionsAndArguments(completePartialWrapping: true,
                                              wrapSingleArguments: true)
    }

    /// Normalize argument wrapping style
    public let wrapArguments = FormatRule(
        help: "Align wrapped function arguments or collection elements.",
        orderAfter: ["wrap"],
        options: ["wraparguments", "wrapparameters", "wrapcollections", "closingparen",
                  "wrapreturntype", "wrapconditions", "conditionswrap"],
        sharedOptions: ["indent", "trimwhitespace", "linebreaks",
                        "tabwidth", "maxwidth", "smarttabs", "assetliterals"]
    ) { formatter in
        formatter.wrapCollectionsAndArguments(completePartialWrapping: true,
                                              wrapSingleArguments: false)
    }

    public let wrapMultilineStatementBraces = FormatRule(
        help: "Wrap the opening brace of multiline statements.",
        orderAfter: ["indent", "braces", "wrapArguments"],
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEachToken { i, token in
            guard case let .keyword(keyword) = token, [
                "if", "for", "guard", "while", "switch", "func", "init", "subscript",
                "extension", "class", "struct", "enum", "protocol",
            ].contains(keyword),
                let openBraceIndex = formatter.index(of: .startOfScope("{"), after: i)
            else {
                return
            }
            let startOfLine = formatter.startOfLine(at: openBraceIndex)
            // Make sure the brace is on a separate line from the if / guard
            guard i < startOfLine,
                  // If token before the brace isn't a newline or guard else then insert a newline
                  let prevIndex = formatter.index(of: .nonSpace, before: openBraceIndex),
                  let prevToken = formatter.token(at: prevIndex),
                  !prevToken.isLinebreak, !(prevToken == .keyword("else") &&
                      prevIndex == formatter.index(of: .nonSpace, after: startOfLine)),
                  // Only wrap when the brace's line is more indented than the if / guard
                  formatter.indentForLine(at: i) < formatter.indentForLine(at: openBraceIndex),
                  // And only when closing brace is not on same line
                  let closingIndex = formatter.endOfScope(at: openBraceIndex),
                  formatter.tokens[openBraceIndex ..< closingIndex].contains(where: { $0.isLinebreak })
            else {
                return
            }
            formatter.insertLinebreak(at: openBraceIndex)

            // Insert a space to align the opening brace with the if / guard keyword
            let indentation = formatter.indentForLine(at: i)
            formatter.insertSpace(indentation, at: openBraceIndex + 1)

            // If we left behind a trailing space on the previous line, clean it up
            let previousTokenIndex = openBraceIndex - 1
            if formatter.tokens[previousTokenIndex].isSpace {
                formatter.removeToken(at: previousTokenIndex)
            }
        }
    }

    /// Formats enum cases declaration into one case per line
    public let wrapEnumCases = FormatRule(
        help: "Writes one enum case per line.",
        disabledByDefault: true,
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEach(.keyword("case")) { i, _ in
            guard formatter.isEnumCase(at: i), var end = formatter.index(after: i, where: {
                $0.isKeyword || $0 == .endOfScope("}")
            }), formatter.last(.nonSpaceOrComment, before: i)?.isLinebreak == true else {
                return
            }
            var index = i
            let indent = formatter.indentForLine(at: i)
            while let commaIndex = formatter.index(of: .delimiter(","), in: (index + 1) ..< end),
                  let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: commaIndex)
            {
                formatter.replaceToken(at: commaIndex, with: .keyword("case"))
                let delta = formatter
                    .replaceTokens(in: commaIndex + 1 ..< nextIndex, with: .space(" "))
                formatter.insertLinebreak(at: commaIndex)
                formatter.insertSpace(indent, at: commaIndex + 1)
                index = commaIndex
                end += delta + 2
            }
        }
    }

    /// Writes one switch case per line
    public let wrapSwitchCases = FormatRule(
        help: "Writes one switch case per line.",
        disabledByDefault: true,
        sharedOptions: ["linebreaks", "tabwidth", "indent", "smarttabs"]
    ) { formatter in
        formatter.forEach(.endOfScope("case")) { i, _ in
            guard var endIndex = formatter.index(of: .startOfScope(":"), after: i) else { return }
            let lineStart = formatter.startOfLine(at: i)
            let indent = formatter.spaceEquivalentToTokens(from: lineStart, upTo: i + 2)

            var startIndex = i
            while let commaIndex = formatter.index(of: .delimiter(","), in: startIndex + 1 ..< endIndex),
                  let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: commaIndex)
            {
                if formatter.index(of: .linebreak, in: commaIndex ..< nextIndex) == nil {
                    formatter.insertLinebreak(at: commaIndex + 1)
                    let delta = formatter.insertSpace(indent, at: commaIndex + 2)
                    endIndex += 1 + delta
                }
                startIndex = commaIndex
            }
        }
    }

    /// Normalize the use of void in closure arguments and return values
    public let void = FormatRule(
        help: "Use `Void` for type declarations and `()` for values.",
        options: ["voidtype"]
    ) { formatter in
        func isArgumentToken(at index: Int) -> Bool {
            guard let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: index) else {
                return false
            }
            switch nextToken {
            case .operator("->", .infix), .keyword("throws"), .keyword("rethrows"),
                 .keyword("async"), .identifier("async"):
                return true
            case .startOfScope("{"):
                if formatter.tokens[index] == .endOfScope(")"),
                   let index = formatter.index(of: .startOfScope("("), before: index),
                   let nameIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: index, if: {
                       $0.isIdentifier
                   }), formatter.last(.nonSpaceOrCommentOrLinebreak, before: nameIndex) == .keyword("func")
                {
                    return true
                }
                return false
            case .keyword("in"):
                if formatter.tokens[index] == .endOfScope(")"),
                   let index = formatter.index(of: .startOfScope("("), before: index)
                {
                    return formatter.last(.nonSpaceOrCommentOrLinebreak, before: index) == .startOfScope("{")
                }
                return false
            default:
                return false
            }
        }

        formatter.forEach(.identifier("Void")) { i, _ in
            if let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i, if: {
                $0 == .endOfScope(")")
            }), var prevIndex = formatter.index(of: .nonSpaceOrLinebreak, before: i), {
                let token = formatter.tokens[prevIndex]
                if token == .delimiter(":"),
                   let prevPrevIndex = formatter.index(of: .nonSpaceOrLinebreak, before: prevIndex),
                   formatter.tokens[prevPrevIndex] == .identifier("_"),
                   let startIndex = formatter.index(of: .nonSpaceOrLinebreak, before: prevPrevIndex),
                   formatter.tokens[startIndex] == .startOfScope("(")
                {
                    prevIndex = startIndex
                    return true
                }
                return token == .startOfScope("(")
            }() {
                if isArgumentToken(at: nextIndex) {
                    if !formatter.options.useVoid {
                        // Convert to parens
                        formatter.replaceToken(at: i, with: .endOfScope(")"))
                        formatter.insert(.startOfScope("("), at: i)
                    }
                } else if formatter.options.useVoid {
                    // Strip parens
                    formatter.removeTokens(in: i + 1 ... nextIndex)
                    formatter.removeTokens(in: prevIndex ..< i)
                } else {
                    // Remove Void
                    formatter.removeTokens(in: prevIndex + 1 ..< nextIndex)
                }
            } else if let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: i),
                      [.operator(".", .prefix), .operator(".", .infix), .keyword("typealias")].contains(prevToken)
            {
                return
            } else {
                if formatter.next(.nonSpace, after: i) == .startOfScope("(") {
                    formatter.removeToken(at: i)
                    return
                }
                if !formatter.options.useVoid || isArgumentToken(at: i) {
                    // Convert to parens
                    formatter.replaceToken(at: i, with: [.startOfScope("("), .endOfScope(")")])
                }
            }
        }
        guard formatter.options.useVoid else {
            return
        }
        formatter.forEach(.startOfScope("(")) { i, _ in
            guard let endIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i, if: {
                $0 == .endOfScope(")")
            }), let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: i),
            !isArgumentToken(at: endIndex) else {
                return
            }
            if formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) == .operator("->", .infix) {
                formatter.replaceTokens(in: i ... endIndex, with: .identifier("Void"))
            } else if prevToken == .startOfScope("<") ||
                (prevToken == .delimiter(",") && formatter.currentScope(at: i) == .startOfScope("<"))
            {
                formatter.replaceTokens(in: i ... endIndex, with: .identifier("Void"))
            }
            // TODO: other cases
        }
    }

    /// Standardize formatting of numeric literals
    public let numberFormatting = FormatRule(
        help: """
        Use consistent grouping for numeric literals. Groups will be separated by `_`
        delimiters to improve readability. For each numeric type you can specify a group
        size (the number of digits in each group) and a threshold (the minimum number of
        digits in a number before grouping is applied).
        """,
        options: ["decimalgrouping", "binarygrouping", "octalgrouping", "hexgrouping",
                  "fractiongrouping", "exponentgrouping", "hexliteralcase", "exponentcase"]
    ) { formatter in
        func applyGrouping(_ grouping: Grouping, to number: inout String) {
            switch grouping {
            case .none, .group:
                number = number.replacingOccurrences(of: "_", with: "")
            case .ignore:
                return
            }
            guard case let .group(group, threshold) = grouping, group > 0, number.count >= threshold else {
                return
            }
            var output = Substring()
            var index = number.endIndex
            var count = 0
            repeat {
                index = number.index(before: index)
                if count > 0, count % group == 0 {
                    output.insert("_", at: output.startIndex)
                }
                count += 1
                output.insert(number[index], at: output.startIndex)
            } while index != number.startIndex
            number = String(output)
        }
        formatter.forEachToken { i, token in
            guard case let .number(number, type) = token else {
                return
            }
            let grouping: Grouping
            let prefix: String, exponentSeparator: String, parts: [String]
            switch type {
            case .integer, .decimal:
                grouping = formatter.options.decimalGrouping
                prefix = ""
                exponentSeparator = formatter.options.uppercaseExponent ? "E" : "e"
                parts = number.components(separatedBy: CharacterSet(charactersIn: ".eE"))
            case .binary:
                grouping = formatter.options.binaryGrouping
                prefix = "0b"
                exponentSeparator = ""
                parts = [String(number[prefix.endIndex...])]
            case .octal:
                grouping = formatter.options.octalGrouping
                prefix = "0o"
                exponentSeparator = ""
                parts = [String(number[prefix.endIndex...])]
            case .hex:
                grouping = formatter.options.hexGrouping
                prefix = "0x"
                exponentSeparator = formatter.options.uppercaseExponent ? "P" : "p"
                parts = number[prefix.endIndex...].components(separatedBy: CharacterSet(charactersIn: ".pP")).map {
                    formatter.options.uppercaseHex ? $0.uppercased() : $0.lowercased()
                }
            }
            var main = parts[0], fraction = "", exponent = ""
            switch parts.count {
            case 2 where number.contains("."):
                fraction = parts[1]
            case 2:
                exponent = parts[1]
            case 3:
                fraction = parts[1]
                exponent = parts[2]
            default:
                break
            }
            applyGrouping(grouping, to: &main)
            if formatter.options.fractionGrouping {
                applyGrouping(grouping, to: &fraction)
            }
            if formatter.options.exponentGrouping {
                applyGrouping(grouping, to: &exponent)
            }
            var result = prefix + main
            if !fraction.isEmpty {
                result += "." + fraction
            }
            if !exponent.isEmpty {
                result += exponentSeparator + exponent
            }
            formatter.replaceToken(at: i, with: .number(result, type))
        }
    }

    /// Strip header comments from the file
    public let fileHeader = FormatRule(
        help: "Use specified source file header template for all files.",
        runOnceOnly: true,
        options: ["header"],
        sharedOptions: ["linebreaks"]
    ) { formatter in
        guard !formatter.options.fragment else { return }

        let header: String
        switch formatter.options.fileHeader {
        case .ignore:
            return
        case var .replace(string):
            if let range = string.range(of: "{file}"),
               let file = formatter.options.fileInfo.fileName
            {
                string.replaceSubrange(range, with: file)
            }
            if let range = string.range(of: "{year}") {
                string.replaceSubrange(range, with: currentYear)
            }
            if let range = string.range(of: "{created}"),
               let date = formatter.options.fileInfo.creationDate
            {
                string.replaceSubrange(range, with: shortDateFormatter(date))
            }
            if let range = string.range(of: "{created.year}"),
               let date = formatter.options.fileInfo.creationDate
            {
                string.replaceSubrange(range, with: yearFormatter(date))
            }
            header = string
        }
        var lastHeaderTokenIndex = -1
        if var startIndex = formatter.index(of: .nonSpaceOrLinebreak, after: -1) {
            switch formatter.tokens[startIndex] {
            case .startOfScope("//"):
                if case let .commentBody(body)? = formatter.next(.nonSpace, after: startIndex) {
                    formatter.processCommentBody(body, at: startIndex)
                    if !formatter.isEnabled || (body.hasPrefix("/") && !body.hasPrefix("//")) ||
                        body.hasPrefix("swift-tools-version")
                    {
                        return
                    } else if body.isFormattingDirective {
                        break
                    }
                }
                var lastIndex = startIndex
                while let index = formatter.index(of: .linebreak, after: lastIndex) {
                    switch formatter.token(at: index + 1) ?? .space("") {
                    case .startOfScope("//"):
                        if case let .commentBody(body)? = formatter.next(.nonSpace, after: index + 1),
                           body.isFormattingDirective
                        {
                            break
                        }
                        lastIndex = index
                        continue
                    case .linebreak:
                        lastHeaderTokenIndex = index + 1
                    case .space where formatter.token(at: index + 2)?.isLinebreak == true:
                        lastHeaderTokenIndex = index + 2
                    default:
                        break
                    }
                    break
                }
            case .startOfScope("/*"):
                if case let .commentBody(body)? = formatter.next(.nonSpace, after: startIndex) {
                    formatter.processCommentBody(body, at: startIndex)
                    if !formatter.isEnabled || (body.hasPrefix("*") && !body.hasPrefix("**")) {
                        return
                    } else if body.isFormattingDirective {
                        break
                    }
                }
                while let endIndex = formatter.index(of: .endOfScope("*/"), after: startIndex) {
                    lastHeaderTokenIndex = endIndex
                    if let linebreakIndex = formatter.index(of: .linebreak, after: endIndex) {
                        lastHeaderTokenIndex = linebreakIndex
                    }
                    guard let nextIndex = formatter.index(of: .nonSpace, after: lastHeaderTokenIndex) else {
                        break
                    }
                    guard formatter.tokens[nextIndex] == .startOfScope("/*") else {
                        if let endIndex = formatter.index(of: .nonSpaceOrLinebreak, after: lastHeaderTokenIndex) {
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
        if header.isEmpty {
            formatter.removeTokens(in: 0 ..< lastHeaderTokenIndex + 1)
            return
        }
        var headerTokens = tokenize(header)
        let endIndex = lastHeaderTokenIndex + headerTokens.count
        if formatter.tokens.endIndex > endIndex, headerTokens == Array(formatter.tokens[
            lastHeaderTokenIndex + 1 ... endIndex
        ]) {
            lastHeaderTokenIndex += headerTokens.count
        }
        let headerLinebreaks = headerTokens.reduce(0) { result, token -> Int in
            result + (token.isLinebreak ? 1 : 0)
        }
        headerTokens += [
            .linebreak(formatter.options.linebreak, headerLinebreaks + 1),
            .linebreak(formatter.options.linebreak, headerLinebreaks + 2),
        ]
        if let index = formatter.index(of: .nonSpace, after: lastHeaderTokenIndex, if: {
            $0.isLinebreak
        }) {
            lastHeaderTokenIndex = index
        }
        formatter.replaceTokens(in: 0 ..< lastHeaderTokenIndex + 1, with: headerTokens)
    }

    /// Strip redundant `.init` from type instantiations
    public let redundantInit = FormatRule(
        help: "Remove explicit `init` if not required."
    ) { formatter in
        formatter.forEach(.identifier("init")) { i, _ in
            guard let dotIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i, if: {
                $0 == .operator(".", .infix)
            }), let openParenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i, if: {
                $0 == .startOfScope("(")
            }), let closeParenIndex = formatter.index(of: .endOfScope(")"), after: openParenIndex),
            formatter.last(.nonSpaceOrCommentOrLinebreak, before: closeParenIndex) != .delimiter(":"),
            let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: dotIndex),
            case let .identifier(name) = prevToken, let firstChar = name.first,
            firstChar != "$", String(firstChar).uppercased() == String(firstChar) else {
                return
            }
            formatter.removeTokens(in: dotIndex ... i)
        }
    }

    /// Sorts switch cases alphabetically
    public let sortedSwitchCases = FormatRule(
        help: "Sorts switch cases alphabetically.",
        disabledByDefault: true // TODO: fix bugs with comments, then this can be enabled by default
    ) { formatter in

        formatter.forEach(.endOfScope("case")) { i, _ in
            guard let endIndex = formatter.index(
                after: i,
                where: { $0 == .startOfScope(":") }
            )
            else { return }

            var nextDelimiterIndex = formatter.index(in: i + 1 ..< endIndex, where: { $0 == .delimiter(",") })
            var nextStartIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i)
            var enums: [Range<Int>] = []

            while let startIndex = nextStartIndex,
                  let delimiterIndex = nextDelimiterIndex,
                  delimiterIndex < endIndex,
                  startIndex < endIndex,
                  let end = formatter.lastIndex(of: .nonSpaceOrCommentOrLinebreak,
                                                in: Range(uncheckedBounds: (lower: startIndex, upper: delimiterIndex)))
            {
                enums.append(Range(startIndex ... end))
                nextStartIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak,
                                                 after: delimiterIndex) ?? endIndex
                nextDelimiterIndex = formatter.index(after: delimiterIndex, where: { $0 == .delimiter(",") })
            }

            // last one from the cases list
            if let nextStart = nextStartIndex,
               let nextEnd = formatter.lastIndex(of: .nonSpaceOrCommentOrLinebreak, in: nextStart ..< endIndex),
               nextStart <= nextEnd
            {
                enums.append(Range(nextStart ... nextEnd))
            }

            guard enums.count > 1 else { return } // nothing to sort

            let sorted: [Range<Int>] = enums.sorted { (range1, range2) -> Bool in
                let lhs = formatter.tokens[range1]
                    .compactMap { $0.isIdentifier || $0.isStringBody || $0.isNumber ? $0.string : nil }
                let rhs = formatter.tokens[range2]
                    .compactMap { $0.isIdentifier || $0.isStringBody || $0.isNumber ? $0.string : nil }
                for (lhs, rhs) in zip(lhs, rhs) {
                    switch lhs.localizedStandardCompare(rhs) {
                    case .orderedAscending:
                        return true
                    case .orderedDescending:
                        return false
                    case .orderedSame:
                        continue
                    }
                }
                return lhs.count < rhs.count
            }

            let sortedTokens = sorted.map { formatter.tokens[$0] }

            // ignore if there's a where keyword and it is not in the last place.
            let firstWhereIndex = sortedTokens.firstIndex(where: { slice in slice.contains(.keyword("where")) })
            guard firstWhereIndex == nil || firstWhereIndex == sortedTokens.count - 1 else { return }

            for switchCase in enums.enumerated().reversed() {
                let newTokens = Array(sortedTokens[switchCase.offset])
                formatter.replaceTokens(in: enums[switchCase.offset], with: newTokens)
            }
        }
    }

    /// Sort import statements
    public let sortedImports = FormatRule(
        help: "Sort import statements alphabetically.",
        options: ["importgrouping"],
        sharedOptions: ["linebreaks"]
    ) { formatter in
        func sortRanges(_ ranges: [Formatter.ImportRange]) -> [Formatter.ImportRange] {
            if case .alpha = formatter.options.importGrouping {
                return ranges.sorted(by: <)
            } else if case .length = formatter.options.importGrouping {
                return ranges.sorted { $0.module.count < $1.module.count }
            }
            // Group @testable imports at the top or bottom
            return ranges.sorted {
                // If both have a @testable keyword, or neither has one, just sort alphabetically
                guard $0.isTestable != $1.isTestable else {
                    return $0 < $1
                }
                return formatter.options.importGrouping == .testableFirst ? $0.isTestable : $1.isTestable
            }
        }

        for var importRanges in formatter.parseImports().reversed() {
            guard importRanges.count > 1 else { continue }
            let range: Range = importRanges.first!.range.lowerBound ..< importRanges.last!.range.upperBound
            let sortedRanges = sortRanges(importRanges)
            var insertedLinebreak = false
            var sortedTokens = sortedRanges.flatMap { inputRange -> [Token] in
                var tokens = Array(formatter.tokens[inputRange.range])
                if tokens.first?.isLinebreak == false {
                    insertedLinebreak = true
                    tokens.insert(formatter.linebreakToken(for: tokens.startIndex), at: tokens.startIndex)
                }
                return tokens
            }
            if insertedLinebreak {
                sortedTokens.removeFirst()
            }
            formatter.replaceTokens(in: range, with: sortedTokens)
        }
    }

    /// Remove duplicate import statements
    public let duplicateImports = FormatRule(
        help: "Remove duplicate import statements."
    ) { formatter in
        for var importRanges in formatter.parseImports().reversed() {
            for i in importRanges.indices.reversed() {
                let range = importRanges.remove(at: i)
                guard let j = importRanges.firstIndex(where: { $0.module == range.module }) else {
                    continue
                }
                let range2 = importRanges[j]
                if !range.isTestable || range2.isTestable {
                    formatter.removeTokens(in: range.range)
                    continue
                }
                if j >= i {
                    formatter.removeTokens(in: range2.range)
                    importRanges.remove(at: j)
                }
                importRanges.append(range)
            }
        }
    }

    /// Strip unnecessary `weak` from @IBOutlet properties (except delegates and datasources)
    public let strongOutlets = FormatRule(
        help: "Remove `weak` modifier from `@IBOutlet` properties."
    ) { formatter in
        formatter.forEach(.keyword("@IBOutlet")) { i, _ in
            guard let varIndex = formatter.index(of: .keyword("var"), after: i),
                  let weakIndex = (i ..< varIndex).first(where: { formatter.tokens[$0] == .identifier("weak") }),
                  case let .identifier(name)? = formatter.next(.identifier, after: varIndex)
            else {
                return
            }
            let lowercased = name.lowercased()
            if lowercased.hasSuffix("delegate") || lowercased.hasSuffix("datasource") {
                return
            }
            if formatter.tokens[weakIndex + 1].isSpace {
                formatter.removeToken(at: weakIndex + 1)
            } else if formatter.tokens[weakIndex - 1].isSpace {
                formatter.removeToken(at: weakIndex - 1)
            }
            formatter.removeToken(at: weakIndex)
        }
    }

    /// Remove white-space between empty braces
    public let emptyBraces = FormatRule(
        help: "Remove whitespace inside empty braces."
    ) { formatter in
        formatter.forEach(.startOfScope("{")) { i, _ in
            guard let closingIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i, if: {
                $0 == .endOfScope("}")
            }) else {
                return
            }
            if let token = formatter.next(.nonSpaceOrCommentOrLinebreak, after: closingIndex),
               [.keyword("else"), .keyword("catch")].contains(token)
            {
                return
            }
            formatter.removeTokens(in: i + 1 ..< closingIndex)
        }
    }

    /// Replace the `&&` operator with `,` where applicable
    public let andOperator = FormatRule(
        help: "Prefer comma over `&&` in `if`, `guard` or `while` conditions."
    ) { formatter in
        formatter.forEachToken { i, token in
            switch token {
            case .keyword("if"), .keyword("guard"),
                 .keyword("while") where formatter.last(.keyword, before: i) != .keyword("repeat"):
                break
            default:
                return
            }
            guard var endIndex = formatter.index(of: .startOfScope("{"), after: i) else {
                return
            }
            // Crude check for Function Builder
            if let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: endIndex),
               case let .identifier(name) = nextToken, let firstChar = name.first.map(String.init),
               firstChar == firstChar.uppercased()
            {
                return
            } else if formatter.isInViewBuilder(at: i) {
                return
            }
            var index = i + 1
            outer: while index < endIndex {
                switch formatter.tokens[index] {
                case .operator("&&", .infix):
                    let endOfGroup = formatter.index(of: .delimiter(","), after: index) ?? endIndex
                    var nextOpIndex = index
                    while let next = formatter.index(of: .operator, after: nextOpIndex) {
                        if formatter.tokens[next] == .operator("||", .infix) {
                            index = endOfGroup
                            continue outer
                        }
                        nextOpIndex = next
                    }
                    formatter.replaceToken(at: index, with: .delimiter(","))
                    if formatter.tokens[index - 1] == .space(" ") {
                        formatter.removeToken(at: index - 1)
                        endIndex -= 1
                        index -= 1
                    } else if let prevIndex = formatter.index(of: .nonSpace, before: index),
                              formatter.tokens[prevIndex].isLinebreak, let nonLinbreak =
                              formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: prevIndex)
                    {
                        formatter.removeToken(at: index)
                        formatter.insert(.delimiter(","), at: nonLinbreak + 1)
                        if formatter.tokens[index + 1] == .space(" ") {
                            formatter.removeToken(at: index + 1)
                            endIndex -= 1
                        }
                    }
                case .operator("||", .infix), .operator("=", .infix), .keyword("try"):
                    index = formatter.index(of: .delimiter(","), after: index) ?? endIndex
                case .startOfScope:
                    index = formatter.endOfScope(at: index) ?? endIndex
                default:
                    break
                }
                index += 1
            }
        }
    }

    /// Replace count == 0 with isEmpty
    public let isEmpty = FormatRule(
        help: "Prefer `isEmpty` over comparing `count` against zero.",
        disabledByDefault: true
    ) { formatter in
        formatter.forEach(.identifier("count")) { i, _ in
            guard let dotIndex = formatter.index(of: .nonSpaceOrLinebreak, before: i, if: {
                $0.isOperator(".")
            }), let opIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i, if: {
                $0.isOperator
            }), let endIndex = formatter.index(of: .nonSpaceOrLinebreak, after: opIndex, if: {
                $0 == .number("0", .integer)
            }) else {
                return
            }
            var isOptional = false
            var index = dotIndex
            var wasIdentifier = false
            loop: while true {
                guard let prev = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: index) else {
                    break
                }
                switch formatter.tokens[prev] {
                case .operator("!", _), .operator(".", _):
                    break // Ignored
                case .operator("?", _):
                    if formatter.tokens[prev - 1].isSpace {
                        break loop
                    }
                    isOptional = true
                case let .operator(op, .infix):
                    guard ["||", "&&", ":"].contains(op) else {
                        return
                    }
                    break loop
                case .keyword, .delimiter, .startOfScope:
                    break loop
                case .identifier:
                    if wasIdentifier {
                        break loop
                    }
                    wasIdentifier = true
                    index = prev
                    continue
                case .endOfScope:
                    guard !wasIdentifier, let start = formatter.index(of: .startOfScope, before: prev) else {
                        break loop
                    }
                    wasIdentifier = false
                    index = start
                    continue
                default:
                    break
                }
                wasIdentifier = false
                index = prev
            }
            let isEmpty: Bool
            switch formatter.tokens[opIndex] {
            case .operator("==", .infix): isEmpty = true
            case .operator("!=", .infix), .operator(">", .infix): isEmpty = false
            default: return
            }
            if isEmpty {
                if isOptional {
                    formatter.replaceTokens(in: i ... endIndex, with: [
                        .identifier("isEmpty"), .space(" "), .operator("==", .infix), .space(" "), .identifier("true"),
                    ])
                } else {
                    formatter.replaceTokens(in: i ... endIndex, with: .identifier("isEmpty"))
                }
            } else {
                if isOptional {
                    formatter.replaceTokens(in: i ... endIndex, with: [
                        .identifier("isEmpty"), .space(" "), .operator("!=", .infix), .space(" "), .identifier("true"),
                    ])
                } else {
                    formatter.replaceTokens(in: i ... endIndex, with: .identifier("isEmpty"))
                    formatter.insert(.operator("!", .prefix), at: index)
                }
            }
        }
    }

    /// Remove redundant `let error` from `catch` statements
    public let redundantLetError = FormatRule(
        help: "Remove redundant `let error` from `catch` clause."
    ) { formatter in
        formatter.forEach(.keyword("catch")) { i, _ in
            if let letIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i, if: {
                $0 == .keyword("let")
            }), let errorIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: letIndex, if: {
                $0 == .identifier("error")
            }), let scopeIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: errorIndex, if: {
                $0 == .startOfScope("{")
            }) {
                formatter.removeTokens(in: letIndex ..< scopeIndex)
            }
        }
    }

    /// Prefer `AnyObject` over `class` for class-based protocols
    public let anyObjectProtocol = FormatRule(
        help: "Prefer `AnyObject` over `class` in protocol definitions."
    ) { formatter in
        formatter.forEach(.keyword("protocol")) { i, _ in
            guard formatter.options.swiftVersion >= "4.1",
                  let nameIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i, if: {
                      $0.isIdentifier
                  }), let colonIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: nameIndex, if: {
                      $0 == .delimiter(":")
                  }), let classIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: colonIndex, if: {
                      $0 == .keyword("class")
                  })
            else {
                return
            }
            formatter.replaceToken(at: classIndex, with: .identifier("AnyObject"))
        }
    }

    /// Remove redundant `break` keyword from switch cases
    public let redundantBreak = FormatRule(
        help: "Remove redundant `break` in switch case."
    ) { formatter in
        formatter.forEach(.keyword("break")) { i, _ in
            guard formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) != .startOfScope(":"),
                  formatter.next(.nonSpaceOrCommentOrLinebreak, after: i)?.isEndOfScope == true,
                  var startIndex = formatter.index(of: .nonSpace, before: i),
                  let endIndex = formatter.index(of: .nonSpace, after: i),
                  formatter.currentScope(at: i) == .startOfScope(":")
            else {
                return
            }
            if !formatter.tokens[startIndex].isLinebreak || !formatter.tokens[endIndex].isLinebreak {
                startIndex += 1
            }
            formatter.removeTokens(in: startIndex ..< endIndex)
        }
    }

    /// Removed backticks from `self` when strongifying
    public let strongifiedSelf = FormatRule(
        help: "Remove backticks around `self` in Optional unwrap expressions."
    ) { formatter in
        formatter.forEach(.identifier("`self`")) { i, _ in
            guard formatter.options.swiftVersion >= "4.2",
                  let equalIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i, if: {
                      $0 == .operator("=", .infix)
                  }), formatter.next(.nonSpaceOrCommentOrLinebreak, after: equalIndex) == .identifier("self")
            else {
                return
            }
            formatter.replaceToken(at: i, with: .identifier("self"))
        }
    }

    /// Remove redundant @objc annotation
    public let redundantObjc = FormatRule(
        help: "Remove redundant `@objc` annotations."
    ) { formatter in
        let objcAttributes = [
            "@IBOutlet", "@IBAction",
            "@IBDesignable", "@IBInspectable", "@GKInspectable",
            "@NSManaged",
        ]
        formatter.forEach(.keyword("@objc")) { i, _ in
            guard formatter.next(.nonSpaceOrCommentOrLinebreak, after: i) != .startOfScope("(") else {
                return
            }
            var index = i
            loop: while var nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index) {
                switch formatter.tokens[nextIndex] {
                case .keyword("class"), .keyword("enum"),
                     // Not actually allowed currently, but: future-proofing!
                     .keyword("protocol"), .keyword("struct"):
                    return
                case .keyword("private"), .keyword("fileprivate"):
                    // Can't safely remove objc from private members
                    return
                case let token where token.isAttribute:
                    if let startIndex = formatter.index(of: .startOfScope("("), after: nextIndex),
                       let endIndex = formatter.index(of: .endOfScope(")"), after: startIndex)
                    {
                        nextIndex = endIndex
                    }
                case let token:
                    guard token.isModifierKeyword else {
                        break loop
                    }
                }
                index = nextIndex
            }
            func removeAttribute() {
                formatter.removeToken(at: i)
                if formatter.token(at: i)?.isSpace == true {
                    formatter.removeToken(at: i)
                } else if formatter.token(at: i - 1)?.isSpace == true {
                    formatter.removeToken(at: i - 1)
                }
            }
            if formatter.last(.nonSpaceOrCommentOrLinebreak, before: i, if: {
                $0.isAttribute && objcAttributes.contains($0.string)
            }) != nil || formatter.next(.nonSpaceOrCommentOrLinebreak, after: i, if: {
                $0.isAttribute && objcAttributes.contains($0.string)
            }) != nil {
                removeAttribute()
                return
            }
            guard let scopeStart = formatter.index(of: .startOfScope("{"), before: i),
                  let keywordIndex = formatter.index(of: .keyword, before: scopeStart)
            else {
                return
            }
            switch formatter.tokens[keywordIndex] {
            case .keyword("class"):
                if formatter.modifiersForDeclaration(at: keywordIndex, contains: "@objcMembers") {
                    removeAttribute()
                }
            case .keyword("extension"):
                if formatter.modifiersForDeclaration(at: keywordIndex, contains: "@objc") {
                    removeAttribute()
                }
            default:
                break
            }
        }
    }

    /// Replace Array<T>, Dictionary<T, U> and Optional<T> with [T], [T: U] and T?
    public let typeSugar = FormatRule(
        help: "Prefer shorthand syntax for Arrays, Dictionaries and Optionals.",
        options: ["shortoptionals"]
    ) { formatter in
        formatter.forEach(.startOfScope("<")) { i, _ in
            guard let typeIndex = formatter.index(of: .nonSpaceOrLinebreak, before: i),
                  case let .identifier(identifier) = formatter.tokens[typeIndex],
                  let endIndex = formatter.index(of: .endOfScope(">"), after: i),
                  let typeStart = formatter.index(of: .nonSpaceOrLinebreak, in: i + 1 ..< endIndex),
                  let typeEnd = formatter.lastIndex(of: .nonSpaceOrLinebreak, in: i + 1 ..< endIndex)
            else {
                return
            }
            if let dotIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: endIndex, if: {
                $0.isOperator(".")
            }), formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: dotIndex, if: {
                ![.identifier("self"), .identifier("Type")].contains($0)
            }) != nil, identifier != "Optional" {
                return
            }
            // Workaround for https://bugs.swift.org/browse/SR-12856
            if formatter.last(.nonSpaceOrCommentOrLinebreak, before: typeIndex) != .delimiter(":") ||
                formatter.currentScope(at: i) == .startOfScope("[")
            {
                var startIndex = i
                if formatter.tokens[typeIndex] == .identifier("Dictionary") {
                    startIndex = formatter.index(of: .delimiter(","), in: i + 1 ..< endIndex) ?? startIndex
                }
                if let parenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: startIndex, if: {
                    $0 == .startOfScope("(")
                }), let underscoreIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: parenIndex, if: {
                    $0 == .identifier("_")
                }), formatter.next(.nonSpaceOrCommentOrLinebreak, after: underscoreIndex)?.isIdentifier == true {
                    return
                }
            }
            func dropSwiftNamespaceIfPresent() {
                if let dotIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: typeIndex, if: {
                    $0.isOperator(".")
                }), let swiftTokenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: dotIndex, if: {
                    $0 == .identifier("Swift")
                }) {
                    formatter.removeTokens(in: swiftTokenIndex ..< typeIndex)
                }
            }
            switch formatter.tokens[typeIndex] {
            case .identifier("Array"):
                formatter.replaceTokens(in: typeIndex ... endIndex, with:
                    [.startOfScope("[")] + formatter.tokens[typeStart ... typeEnd] + [.endOfScope("]")])
                dropSwiftNamespaceIfPresent()
            case .identifier("Dictionary"):
                guard let commaIndex = formatter.index(of: .delimiter(","), in: typeStart ..< typeEnd) else {
                    return
                }
                formatter.replaceToken(at: commaIndex, with: .delimiter(":"))
                formatter.replaceTokens(in: typeIndex ... endIndex, with:
                    [.startOfScope("[")] + formatter.tokens[typeStart ... typeEnd] + [.endOfScope("]")])
                dropSwiftNamespaceIfPresent()
            case .identifier("Optional"):
                if formatter.options.shortOptionals == .exceptProperties,
                   let lastKeyword = formatter.lastSignificantKeyword(at: i),
                   ["var", "let"].contains(lastKeyword)
                {
                    return
                }
                var typeTokens = formatter.tokens[typeStart ... typeEnd]
                if formatter.tokens[typeStart] == .startOfScope("("),
                   let commaEnd = formatter.index(of: .endOfScope(")"), after: typeStart),
                   commaEnd < typeEnd
                {
                    typeTokens.insert(.startOfScope("("), at: typeTokens.startIndex)
                    typeTokens.append(.endOfScope(")"))
                }
                typeTokens.append(.operator("?", .postfix))
                formatter.replaceTokens(in: typeIndex ... endIndex, with: typeTokens)
                dropSwiftNamespaceIfPresent()
            default:
                return
            }
        }
    }

    /// Remove redundant access control level modifiers in extensions
    public let redundantExtensionACL = FormatRule(
        help: "Remove redundant access control modifiers."
    ) { formatter in
        formatter.forEach(.keyword("extension")) { i, _ in
            var acl = ""
            guard formatter.modifiersForDeclaration(at: i, contains: {
                acl = $1
                return aclModifiers.contains(acl)
            }), let startIndex = formatter.index(of: .startOfScope("{"), after: i),
            var endIndex = formatter.index(of: .endOfScope("}"), after: startIndex) else {
                return
            }
            if acl == "private" { acl = "fileprivate" }
            while let aclIndex = formatter.lastIndex(of: .keyword(acl), in: startIndex + 1 ..< endIndex) {
                formatter.removeToken(at: aclIndex)
                if formatter.token(at: aclIndex)?.isSpace == true {
                    formatter.removeToken(at: aclIndex)
                }
                endIndex = aclIndex
            }
        }
    }

    /// Replace `fileprivate` with `private` where possible
    public let redundantFileprivate = FormatRule(
        help: "Prefer `private` over `fileprivate` where equivalent."
    ) { formatter in
        guard !formatter.options.fragment else { return }

        var hasUnreplacedFileprivates = false
        formatter.forEach(.keyword("fileprivate")) { i, _ in
            // check if definition is at file-scope
            if formatter.index(of: .startOfScope, before: i) == nil {
                formatter.replaceToken(at: i, with: .keyword("private"))
            } else {
                hasUnreplacedFileprivates = true
            }
        }
        guard hasUnreplacedFileprivates else {
            return
        }
        let importRanges = formatter.parseImports()
        var fileJustContainsOneType: Bool?
        func ifCodeInRange(_ range: CountableRange<Int>) -> Bool {
            var index = range.lowerBound
            while index < range.upperBound, let nextIndex =
                formatter.index(of: .nonSpaceOrCommentOrLinebreak, in: index ..< range.upperBound)
            {
                guard let importRange = importRanges.first(where: {
                    $0.contains(where: { $0.range.contains(nextIndex) })
                }) else {
                    return true
                }
                index = importRange.last!.range.upperBound + 1
            }
            return false
        }
        func isTypeInitialized(_ name: String, in range: CountableRange<Int>) -> Bool {
            for i in range {
                switch formatter.tokens[i] {
                case .identifier(name):
                    guard let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i) else {
                        break
                    }
                    switch formatter.tokens[nextIndex] {
                    case .operator(".", .infix):
                        if formatter.next(.nonSpaceOrCommentOrLinebreak, after: nextIndex) == .identifier("init") {
                            return true
                        }
                    case .startOfScope("("):
                        return true
                    case .startOfScope("{"):
                        if formatter.isStartOfClosure(at: nextIndex) {
                            return true
                        }
                    default:
                        break
                    }
                case .identifier("init"):
                    // TODO: this will return true if *any* type is initialized using type inference.
                    // Is there a way to narrow this down a bit?
                    if formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) == .operator(".", .prefix) {
                        return true
                    }
                default:
                    break
                }
            }
            return false
        }
        // TODO: improve this logic to handle shadowing
        func areMembers(_ names: [String], of type: String,
                        referencedIn range: CountableRange<Int>) -> Bool
        {
            var i = range.lowerBound
            while i < range.upperBound {
                switch formatter.tokens[i] {
                case .keyword("struct"), .keyword("extension"), .keyword("enum"),
                     .keyword("class") where formatter.declarationType(at: i) == "class":
                    guard let startIndex = formatter.index(of: .startOfScope("{"), after: i),
                          let endIndex = formatter.endOfScope(at: startIndex)
                    else {
                        break
                    }
                    guard let nameIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i),
                          formatter.tokens[nameIndex] != .identifier(type)
                    else {
                        i = endIndex
                        break
                    }
                    for case let .identifier(name) in formatter.tokens[startIndex ..< endIndex]
                        where names.contains(name)
                    {
                        return true
                    }
                    i = endIndex
                case let .identifier(name) where names.contains(name):
                    if let dotIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i, if: {
                        $0 == .operator(".", .infix)
                    }), formatter.last(.nonSpaceOrCommentOrLinebreak, before: dotIndex)
                        != .identifier("self")
                    {
                        return true
                    }
                default:
                    break
                }
                i += 1
            }
            return false
        }
        func isInitOverridden(for type: String, in range: CountableRange<Int>) -> Bool {
            for i in range {
                guard case .keyword("init") = formatter.tokens[i],
                      formatter.modifiersForDeclaration(at: i, contains: "override"),
                      let scopeIndex = formatter.index(of: .startOfScope("{"), before: i),
                      let colonIndex = formatter.index(of: .delimiter(":"), before: scopeIndex),
                      formatter.next(.nonSpaceOrCommentOrLinebreak, in: colonIndex + 1 ..< scopeIndex)
                      == .identifier(type)
                else {
                    continue
                }
                return true
            }
            return false
        }
        formatter.forEach(.keyword("fileprivate")) { i, _ in
            // Check if definition is a member of a file-scope type
            guard formatter.options.swiftVersion >= "4",
                  let scopeIndex = formatter.index(of: .startOfScope, before: i, if: {
                      $0 == .startOfScope("{")
                  }), let typeIndex = formatter.index(of: .keyword, before: scopeIndex, if: {
                      ["class", "struct", "enum", "extension"].contains($0.string)
                  }), let nameIndex = formatter.index(of: .identifier, after: typeIndex),
                  formatter.next(.nonSpaceOrCommentOrLinebreak, after: nameIndex)?.isOperator(".") == false,
                  case let .identifier(typeName) = formatter.tokens[nameIndex],
                  let endIndex = formatter.index(of: .endOfScope, after: scopeIndex),
                  formatter.currentScope(at: typeIndex) == nil
            else {
                return
            }
            // Get member type
            guard let keywordIndex = formatter.index(of: .keyword, in: i + 1 ..< endIndex),
                  let memberType = formatter.declarationType(at: keywordIndex),
                  // TODO: check if member types are exposed in the interface, otherwise convert them too
                  ["let", "var", "func", "init"].contains(memberType)
            else {
                return
            }
            // Check that type doesn't (potentially) conform to a protocol
            // TODO: use a whitelist of known protocols to make this check less blunt
            guard !formatter.tokens[typeIndex ..< scopeIndex].contains(.delimiter(":")) else {
                return
            }
            // Check for code outside of main type definition
            let startIndex = formatter.startOfModifiers(at: typeIndex, includingAttributes: true)
            if fileJustContainsOneType == nil {
                fileJustContainsOneType = !ifCodeInRange(0 ..< startIndex) &&
                    !ifCodeInRange(endIndex + 1 ..< formatter.tokens.count)
            }
            if fileJustContainsOneType == true {
                formatter.replaceToken(at: i, with: .keyword("private"))
                return
            }
            // Check if type name is initialized outside type, and if so don't
            // change any fileprivate members in case we break memberwise initializer
            // TODO: check if struct contains an overridden init; if so we can skip this check
            if formatter.tokens[typeIndex] == .keyword("struct"),
               isTypeInitialized(typeName, in: 0 ..< startIndex) ||
               isTypeInitialized(typeName, in: endIndex + 1 ..< formatter.tokens.count)
            {
                return
            }
            // Check if member is referenced outside type
            if memberType == "init" {
                // Make initializer private if it's not called anywhere
                if !isTypeInitialized(typeName, in: 0 ..< startIndex),
                   !isTypeInitialized(typeName, in: endIndex + 1 ..< formatter.tokens.count),
                   !isInitOverridden(for: typeName, in: 0 ..< startIndex),
                   !isInitOverridden(for: typeName, in: endIndex + 1 ..< formatter.tokens.count)
                {
                    formatter.replaceToken(at: i, with: .keyword("private"))
                }
            } else if let _names = formatter.namesInDeclaration(at: keywordIndex),
                      case let names = _names + _names.map({ "$\($0)" }),
                      !areMembers(names, of: typeName, referencedIn: 0 ..< startIndex),
                      !areMembers(names, of: typeName, referencedIn: endIndex + 1 ..< formatter.tokens.count)
            {
                formatter.replaceToken(at: i, with: .keyword("private"))
            }
        }
    }

    /// Reorders "yoda conditions" where constant is placed on lhs of a comparison
    public let yodaConditions = FormatRule(
        help: "Prefer constant values to be on the right-hand-side of expressions.",
        options: ["yodaswap"]
    ) { formatter in
        func valuesInRangeAreConstant(_ range: CountableRange<Int>) -> Bool {
            var index = formatter.index(of: .nonSpaceOrCommentOrLinebreak, in: range)
            while var i = index {
                switch formatter.tokens[i] {
                case .startOfScope where isConstant(at: i):
                    guard let endIndex = formatter.index(of: .endOfScope, after: i) else {
                        return false
                    }
                    i = endIndex
                    fallthrough
                case _ where isConstant(at: i), .delimiter(","), .delimiter(":"):
                    index = formatter.index(of: .nonSpaceOrCommentOrLinebreak, in: i + 1 ..< range.upperBound)
                case .identifier:
                    guard let nextIndex =
                        formatter.index(of: .nonSpaceOrComment, in: i + 1 ..< range.upperBound),
                        formatter.tokens[nextIndex] == .delimiter(":")
                    else {
                        return false
                    }
                    // Identifier is a label
                    index = nextIndex
                default:
                    return false
                }
            }
            return true
        }
        func isConstant(at index: Int) -> Bool {
            var index = index
            while case .operator(_, .postfix) = formatter.tokens[index] {
                index -= 1
            }
            guard let token = formatter.token(at: index) else {
                return false
            }
            switch token {
            case .number, .identifier("true"), .identifier("false"), .identifier("nil"):
                return true
            case .endOfScope("]"), .endOfScope(")"):
                guard let startIndex = formatter.index(of: .startOfScope, before: index),
                      !formatter.isSubscriptOrFunctionCall(at: startIndex)
                else {
                    return false
                }
                return valuesInRangeAreConstant(startIndex + 1 ..< index)
            case .startOfScope("["), .startOfScope("("):
                guard !formatter.isSubscriptOrFunctionCall(at: index),
                      let endIndex = formatter.index(of: .endOfScope, after: index)
                else {
                    return false
                }
                return valuesInRangeAreConstant(index + 1 ..< endIndex)
            case .startOfScope, .endOfScope:
                // TODO: what if string contains interpolation?
                return token.isStringDelimiter
            case _ where formatter.options.yodaSwap == .literalsOnly:
                // Don't treat .members as constant
                return false
            case .operator(".", .prefix) where formatter.token(at: index + 1)?.isIdentifier == true,
                 .identifier where formatter.token(at: index - 1) == .operator(".", .prefix) &&
                     formatter.token(at: index - 2) != .operator("\\", .prefix):
                return true
            default:
                return false
            }
        }
        func isOperator(at index: Int?) -> Bool {
            guard let index = index else {
                return false
            }
            switch formatter.tokens[index] {
            // Discount operators with higher precedence than ==
            case .operator("=", .infix),
                 .operator("&&", .infix), .operator("||", .infix),
                 .operator("?", .infix), .operator(":", .infix):
                return false
            case .operator(_, .infix), .keyword("as"), .keyword("is"):
                return true
            default:
                return false
            }
        }
        func startOfValue(at index: Int) -> Int? {
            var index = index
            while case .operator(_, .postfix)? = formatter.token(at: index) {
                index -= 1
            }
            if case .endOfScope? = formatter.token(at: index) {
                guard let i = formatter.index(of: .startOfScope, before: index) else {
                    return nil
                }
                index = i
            }
            while case .operator(_, .prefix)? = formatter.token(at: index - 1) {
                index -= 1
            }
            return index
        }

        formatter.forEachToken { i, token in
            guard case let .operator(op, .infix) = token,
                  let opIndex = ["==", "!=", "<", "<=", ">", ">="].index(of: op),
                  let prevIndex = formatter.index(of: .nonSpace, before: i),
                  isConstant(at: prevIndex), let startIndex = startOfValue(at: prevIndex),
                  !isOperator(at: formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: startIndex)),
                  let nextIndex = formatter.index(of: .nonSpace, after: i), !isConstant(at: nextIndex) ||
                  isOperator(at: formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: nextIndex)),
                  let endIndex = formatter.endOfExpression(at: nextIndex, upTo: [
                      .operator("&&", .infix), .operator("||", .infix),
                      .operator("?", .infix), .operator(":", .infix),
                  ])
            else {
                return
            }
            let inverseOp = ["==", "!=", ">", ">=", "<", "<="][opIndex]
            let expression = Array(formatter.tokens[nextIndex ... endIndex])
            let constant = Array(formatter.tokens[startIndex ... prevIndex])
            formatter.replaceTokens(in: nextIndex ... endIndex, with: constant)
            formatter.replaceToken(at: i, with: .operator(inverseOp, .infix))
            formatter.replaceTokens(in: startIndex ... prevIndex, with: expression)
        }
    }

    public let leadingDelimiters = FormatRule(
        help: "Move leading delimiters to the end of the previous line.",
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEach(.delimiter) { i, _ in
            guard let endOfLine = formatter.index(of: .nonSpace, before: i, if: {
                $0.isLinebreak
            }) else {
                return
            }
            let nextIndex = formatter.index(of: .nonSpace, after: i) ?? (i + 1)
            formatter.insertSpace(formatter.indentForLine(at: i), at: nextIndex)
            formatter.insertLinebreak(at: nextIndex)
            formatter.removeTokens(in: i + 1 ..< nextIndex)
            guard case .commentBody? = formatter.last(.nonSpace, before: endOfLine) else {
                formatter.removeTokens(in: endOfLine ..< i)
                return
            }
            let startIndex = formatter.index(of: .nonSpaceOrComment, before: endOfLine) ?? -1
            formatter.removeTokens(in: endOfLine ..< i)
            let comment = Array(formatter.tokens[startIndex + 1 ..< endOfLine])
            formatter.insert(comment, at: endOfLine + 1)
            formatter.removeTokens(in: startIndex + 1 ..< endOfLine)
        }
    }

    public let wrapAttributes = FormatRule(
        help: "Wrap @attributes onto a separate line, or keep them on the same line.",
        options: ["funcattributes", "typeattributes", "varattributes"],
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEach(.attribute) { i, _ in
            // Determine the end index of the attribute
            let endIndex: Int
            if let argumentStartIndex = formatter.index(of: .nonSpaceOrComment, after: i),
               formatter.token(at: argumentStartIndex) == .startOfScope("("),
               let endOfArgumentScope = formatter.endOfScope(at: argumentStartIndex)
            {
                endIndex = endOfArgumentScope
            } else {
                endIndex = i
            }

            // Ignore sequential attributes
            guard var keywordIndex = formatter.index(of: .keyword, after: endIndex),
                  var keyword = formatter.token(at: keywordIndex),
                  !formatter.tokens[keywordIndex].isAttribute
            else {
                return
            }

            // Skip modifiers
            while keyword.isModifierKeyword {
                guard let nextIndex = formatter.index(of: .keyword, after: keywordIndex) else {
                    break
                }
                keywordIndex = nextIndex
                keyword = formatter.tokens[keywordIndex]
            }

            // Check which `AttributeMode` option to use
            let attributeMode: AttributeMode
            switch keyword.string {
            case "func", "init", "subscript":
                attributeMode = formatter.options.funcAttributes
            case "class", "struct", "enum", "protocol":
                attributeMode = formatter.options.typeAttributes
            case "var", "let":
                attributeMode = formatter.options.varAttributes
            default:
                return
            }

            // Apply the `AttributeMode`
            switch attributeMode {
            case .preserve:
                return
            case .prevLine:
                // Make sure there's a newline immediately following the attribute
                if let nextIndex = formatter.index(of: .nonSpaceOrComment, after: endIndex),
                   formatter.token(at: nextIndex)?.isLinebreak != true
                {
                    formatter.insertLinebreak(at: nextIndex)
                    // Remove any trailing whitespace left on the line with the attributes
                    if let prevToken = formatter.token(at: nextIndex - 1), prevToken.isSpace {
                        formatter.removeToken(at: nextIndex - 1)
                    }
                }
            case .sameLine:
                // Make sure there isn't a newline immediately following the attribute
                if let nextIndex = formatter.index(of: .nonSpaceOrComment, after: endIndex),
                   formatter.token(at: nextIndex)?.isLinebreak != false
                {
                    // Replace the newline with a space so the attribute doesn't
                    // merge with the next token.
                    formatter.replaceToken(at: nextIndex, with: .space(" "))
                }
            }
        }
    }

    public let preferKeyPath = FormatRule(
        help: "Convert trivial `map { $0.foo }` closures to keyPath-based syntax."
    ) { formatter in
        formatter.forEach(.startOfScope("{")) { i, _ in
            guard formatter.options.swiftVersion >= "5.2",
                  let prevIndex = formatter.index(of: .nonSpaceOrLinebreak, before: i)
            else {
                return
            }
            var prevToken = formatter.tokens[prevIndex]
            let parenthesized = prevToken == .startOfScope("(")
            if parenthesized {
                prevToken = formatter.last(.nonSpaceOrLinebreak, before: prevIndex) ?? prevToken
            }
            guard [.identifier("map"), .identifier("flatMap"),
                   .identifier("compactMap")].contains(prevToken),
                let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i, if: {
                    $0 == .identifier("$0")
                }),
                let endIndex = formatter.endOfScope(at: i),
                let lastIndex = formatter.index(of: .nonSpaceOrLinebreak, before: endIndex)
            else {
                return
            }
            var replacementTokens: [Token]
            if nextIndex == lastIndex {
                // TODO: add this when https://bugs.swift.org/browse/SR-12897 is fixed
                // replacementTokens = tokenize("\\.self")
                return
            } else {
                let tokens = formatter.tokens[nextIndex + 1 ... lastIndex]
                guard tokens.allSatisfy({ $0.isSpace || $0.isIdentifier || $0.isOperator(".") }) else {
                    return
                }
                replacementTokens = [.operator("\\", .prefix)] + tokens
            }
            if !parenthesized {
                replacementTokens = [.startOfScope("(")] + replacementTokens + [.endOfScope(")")]
            }
            formatter.replaceTokens(in: prevIndex + 1 ... endIndex, with: replacementTokens)
        }
    }

    public let organizeDeclarations = FormatRule(
        help: "Organizes declarations within class, struct, and enum bodies.",
        runOnceOnly: true,
        disabledByDefault: true,
        orderAfter: ["extensionAccessControl", "redundantFileprivate"],
        options: ["categorymark", "beforemarks", "lifecycle", "organizetypes",
                  "structthreshold", "classthreshold", "enumthreshold", "extensionlength"]
    ) { formatter in
        guard !formatter.options.fragment else { return }

        formatter.mapRecursiveDeclarations { declaration in
            switch declaration {
            // Organize the body of type declarations
            case let .type(kind, open, body, close):
                let organizedType = formatter.organizeType((kind, open, body, close))
                return .type(
                    kind: organizedType.kind,
                    open: organizedType.open,
                    body: organizedType.body,
                    close: organizedType.close
                )

            case .conditionalCompilation, .declaration:
                return declaration
            }
        }
    }

    public let extensionAccessControl = FormatRule(
        help: "Configure the placement of an extension's access control keyword.",
        options: ["extensionacl"]
    ) { formatter in
        guard !formatter.options.fragment else { return }

        let declarations = formatter.parseDeclarations()
        let updatedDeclarations = formatter.mapRecursiveDeclarations(declarations) { declaration, _ in
            guard case let .type("extension", open, body, close) = declaration else {
                return declaration
            }

            let visibilityKeyword = formatter.visibility(of: declaration)
            // `private` visibility at top level of file is equivalent to `fileprivate`
            let extensionVisibility = (visibilityKeyword == .private) ? .fileprivate : visibilityKeyword

            switch formatter.options.extensionACLPlacement {
            // If all declarations in the extension have the same visibility,
            // remove the keyword from the individual declarations and
            // place it on the extension itself.
            case .onExtension:
                if extensionVisibility == nil,
                   let delimiterIndex = declaration.openTokens.index(of: .delimiter(":")),
                   declaration.openTokens.index(of: .keyword("where")).map({ $0 > delimiterIndex }) ?? true
                {
                    // Extension adds protocol conformance so can't have visibility modifier
                    return declaration
                }

                let visibilityOfBodyDeclarations = formatter
                    .mapDeclarations(body) {
                        formatter.visibility(of: $0) ?? extensionVisibility ?? .internal
                    }
                    .compactMap { $0 }

                let counts = Set(visibilityOfBodyDeclarations).sorted().map { visibility in
                    (visibility, count: visibilityOfBodyDeclarations.filter { $0 == visibility }.count)
                }

                guard let memberVisibility = counts.max(by: { $0.count < $1.count })?.0,
                      memberVisibility <= extensionVisibility ?? .public,
                      // Check that most common level is also most visible
                      memberVisibility == visibilityOfBodyDeclarations.max(),
                      // `private` can't be hoisted without changing code behavior
                      // (private applied at extension level is equivalent to `fileprivate`)
                      memberVisibility > .private
                else { return declaration }

                if memberVisibility > extensionVisibility ?? .internal {
                    // Check type being extended does not have lower visibility
                    for d in declarations where d.name == declaration.name {
                        if case let .type(kind, _, _, _) = d {
                            if kind != "extension", formatter.visibility(of: d) ?? .internal < memberVisibility {
                                // Cannot make extension with greater visibility than type being extended
                                return declaration
                            }
                            break
                        }
                    }
                }

                let extensionWithUpdatedVisibility: Formatter.Declaration
                if memberVisibility == extensionVisibility ||
                    (memberVisibility == .internal && visibilityKeyword == nil)
                {
                    extensionWithUpdatedVisibility = declaration
                } else {
                    extensionWithUpdatedVisibility = formatter.add(memberVisibility, to: declaration)
                }

                return formatter.mapBodyDeclarations(in: extensionWithUpdatedVisibility) { bodyDeclaration in
                    let visibility = formatter.visibility(of: bodyDeclaration)
                    if memberVisibility > visibility ?? extensionVisibility ?? .internal {
                        if visibility == nil {
                            return formatter.add(.internal, to: bodyDeclaration)
                        }
                        return bodyDeclaration
                    }
                    return formatter.remove(memberVisibility, from: bodyDeclaration)
                }

            // Move the extension's visibility keyword to each individual declaration
            case .onDeclarations:
                // If the extension visibility is unspecified then there isn't any work to do
                guard let extensionVisibility = extensionVisibility else {
                    return declaration
                }

                // Remove the visibility keyword from the extension declaration itself
                let extensionWithUpdatedVisibility = formatter.remove(visibilityKeyword!, from: declaration)

                // And apply the extension's visibility to each of its child declarations
                // that don't have an explicit visibility keyword
                return formatter.mapBodyDeclarations(in: extensionWithUpdatedVisibility) { bodyDeclaration in
                    if formatter.visibility(of: bodyDeclaration) == nil {
                        // If there was no explicit visibility keyword, then this declaration
                        // was using the visibility of the extension itself.
                        return formatter.add(extensionVisibility, to: bodyDeclaration)
                    } else {
                        // Keep the existing visibility
                        return bodyDeclaration
                    }
                }
            }
        }

        let updatedTokens = updatedDeclarations.flatMap { $0.tokens }
        formatter.replaceTokens(in: formatter.tokens.indices, with: updatedTokens)
    }

    public let markTypes = FormatRule(
        help: "Adds a mark comment before top-level types and extensions.",
        runOnceOnly: true,
        disabledByDefault: true,
        options: ["marktypes", "typemark", "markextensions", "extensionmark", "groupedextension"]
    ) { formatter in
        var declarations = formatter.parseDeclarations()

        // Do nothing if there is only one top-level declaration in the file (excluding imports)
        let declarationsWithoutImports = declarations.filter { $0.keyword != "import" }
        guard declarationsWithoutImports.count > 1 else {
            return
        }

        for (index, declaration) in declarations.enumerated() {
            guard case let .type(kind, open, body, close) = declaration else { continue }

            guard let typeName = declaration.name else {
                continue
            }

            let markMode: MarkMode
            let commentTemplate: String
            switch declaration.keyword {
            case "extension":
                markMode = formatter.options.markExtensions

                // We provide separate mark comment customization points for
                // extensions that are "grouped" with (e.g. following) their extending type,
                // vs extensions that are completely separate.
                //
                //  struct Foo { }
                //  extension Foo { } // This extension is "grouped" with its extending type
                //  extension String { } // This extension is standalone (not grouped with any type)
                //
                let isGroupedWithExtendingType: Bool
                if let indexOfExtendingType = declarations[..<index].lastIndex(where: {
                    $0.name == typeName && ["class", "enum", "protocol", "struct", "typealias"].contains($0.keyword)
                }) {
                    let declarationsBetweenTypeAndExtension = declarations[indexOfExtendingType + 1 ..< index]
                    isGroupedWithExtendingType = declarationsBetweenTypeAndExtension.allSatisfy {
                        // Only treat the type and its extension as grouped if there aren't any other
                        // types or type-like declarations between them
                        if ["class", "enum", "protocol", "struct", "typealias"].contains($0.keyword) {
                            return false
                        }
                        // Extensions extending other types also break the grouping
                        if $0.keyword == "extension", $0.name != declaration.name {
                            return false
                        }
                        return true
                    }
                } else {
                    isGroupedWithExtendingType = false
                }

                if isGroupedWithExtendingType {
                    commentTemplate = "// \(formatter.options.groupedExtensionMarkComment)"
                } else {
                    commentTemplate = "// \(formatter.options.extensionMarkComment)"
                }
            default:
                markMode = formatter.options.markTypes
                commentTemplate = "// \(formatter.options.typeMarkComment)"
            }

            switch markMode {
            case .always:
                break
            case .never:
                continue
            case .ifNotEmpty:
                guard !body.isEmpty else {
                    continue
                }
            }

            declarations[index] = formatter.mapOpeningTokens(in: declarations[index]) { openingTokens -> [Token] in
                var openingFormatter = Formatter(openingTokens)

                guard let keywordIndex = openingFormatter.index(after: -1, where: {
                    $0.string == declaration.keyword
                }) else { return openingTokens }

                let conformanceNames: String?
                if declaration.keyword == "extension" {
                    var conformances = [String]()

                    guard var conformanceSearchIndex = openingFormatter.index(
                        of: .delimiter(":"),
                        after: keywordIndex
                    ) else { return openingFormatter.tokens }

                    let endOfConformances = openingFormatter.index(of: .keyword("where"), after: keywordIndex)
                        ?? openingFormatter.index(of: .startOfScope("{"), after: keywordIndex)
                        ?? openingFormatter.tokens.count

                    while let token = openingFormatter.token(at: conformanceSearchIndex),
                          conformanceSearchIndex < endOfConformances
                    {
                        if token.isIdentifier {
                            let (fullyQualifiedName, next) = openingFormatter.fullyQualifiedName(startingAt: conformanceSearchIndex)
                            conformances.append(fullyQualifiedName)
                            conformanceSearchIndex = next
                        }

                        conformanceSearchIndex += 1
                    }

                    guard !conformances.isEmpty else {
                        return openingFormatter.tokens
                    }

                    conformanceNames = conformances.joined(separator: ", ")
                } else {
                    conformanceNames = nil
                }

                let expectedComment = commentTemplate
                    .replacingOccurrences(of: "%t", with: typeName)
                    .replacingOccurrences(of: "%c", with: conformanceNames ?? "")

                // Remove any lines that have the same prefix as the comment template
                //  - We can't really do exact matches here like we do for `organizeDeclaration`
                //    category separators, because there's a much wider variety of options
                //    that a user could use the the type name (orphaned renames, etc.)
                var commentPrefixes = Set(["// MARK: ", "// MARK: - "])

                if let typeNameSymbolIndex = commentTemplate.index(of: "%") {
                    commentPrefixes.insert(String(commentTemplate.prefix(upTo: typeNameSymbolIndex)))
                }

                openingFormatter.forEach(.startOfScope("//")) { index, _ in
                    let startOfLine = openingFormatter.startOfLine(at: index)
                    let endOfLine = openingFormatter.endOfLine(at: index)

                    let commentLine = sourceCode(for: Array(openingFormatter.tokens[index ... endOfLine]))

                    for commentPrefix in commentPrefixes {
                        if commentLine.lowercased().hasPrefix(commentPrefix.lowercased()) {
                            // If we found a line that matched the comment prefix,
                            // remove it and any linebreak immediately after it.
                            if openingFormatter.token(at: endOfLine + 1)?.isLinebreak == true {
                                openingFormatter.removeToken(at: endOfLine + 1)
                            }

                            openingFormatter.removeTokens(in: startOfLine ... endOfLine)
                            break
                        }
                    }
                }

                // When inserting a mark before the first declaration,
                // we should make sure we place it _after_ the file header.
                var markInsertIndex = 0
                if index == 0 {
                    // Search for the end of the file header, which ends when we hit a
                    // blank line or any non-space/comment/lintbreak
                    var endOfFileHeader = 0

                    while openingFormatter.token(at: endOfFileHeader)?.isSpaceOrCommentOrLinebreak == true {
                        endOfFileHeader += 1

                        if openingFormatter.token(at: endOfFileHeader)?.isLinebreak == true,
                           openingFormatter.next(.nonSpace, after: endOfFileHeader)?.isLinebreak == true
                        {
                            markInsertIndex = endOfFileHeader + 2
                            break
                        }
                    }
                }

                // Insert the expected comment at the start of the declaration
                openingFormatter.insert(tokenize("\(expectedComment)\n\n"), at: markInsertIndex)

                // If the previous declaration doesn't end in a blank line,
                // add an additional linebreak to balance the mark.
                if index != 0 {
                    declarations[index - 1] = formatter.mapClosingTokens(in: declarations[index - 1]) {
                        formatter.endingWithBlankLine($0)
                    }
                }

                return openingFormatter.tokens
            }
        }

        let updatedTokens = declarations.flatMap { $0.tokens }
        formatter.replaceTokens(in: 0 ..< formatter.tokens.count, with: updatedTokens)
    }
}
