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
        deprecationMessage != nil
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
        lhs === rhs
    }

    public static func < (lhs: FormatRule, rhs: FormatRule) -> Bool {
        lhs.index < rhs.index
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
    var byName: [String: FormatRule] { rulesByName }

    /// All rules
    var all: [FormatRule] { _allRules }

    /// Default active rules
    var `default`: [FormatRule] { _defaultRules }

    /// Rules that are disabled by default
    var disabledByDefault: [String] { _disabledByDefault }

    /// Just the specified rules
    func named(_ names: [String]) -> [FormatRule] {
        Array(names.sorted().compactMap { rulesByName[$0] })
    }

    /// All rules except those specified
    func all(except rules: [String]) -> [FormatRule] {
        allRules(except: rules)
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
                if formatter.options.swiftVersion < "3",
                   let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: index),
                   formatter.next(.nonSpaceOrCommentOrLinebreak, after: nextIndex) == .identifier("escaping")
                {
                    assert(formatter.tokens[nextIndex] == .startOfScope("("))
                    return false
                }
                return true
            case "@escaping", "@noescape", "@Sendable":
                return true
            case _ where keyword.hasPrefix("@"):
                if let i = formatter.index(of: .startOfScope("("), after: index) {
                    return formatter.isParameterList(at: i)
                }
                return false
            case "private", "fileprivate", "internal",
                 "init", "subscript":
                return false
            case "await":
                return formatter.options.swiftVersion >= "5.5" ||
                    formatter.options.swiftVersion == .undefined
            default:
                return keyword.first.map { !"@#".contains($0) } ?? true
            }
        }

        formatter.forEach(.startOfScope("(")) { i, _ in
            let index = i - 1
            guard let prevToken = formatter.token(at: index) else {
                return
            }
            switch prevToken {
            case let .keyword(string) where spaceAfter(string, index: index):
                fallthrough
            case .endOfScope("]") where formatter.isInClosureArguments(at: index),
                 .endOfScope(")") where formatter.isAttribute(at: index),
                 .identifier("some") where formatter.isTypePosition(at: index),
                 .identifier("any") where formatter.isTypePosition(at: index):
                formatter.insert(.space(" "), at: i)
            case .space:
                let index = i - 2
                guard let token = formatter.token(at: index) else {
                    return
                }
                switch token {
                case .identifier("some") where formatter.isTypePosition(at: index),
                     .identifier("any") where formatter.isTypePosition(at: index):
                    break
                case let .keyword(string) where !spaceAfter(string, index: index):
                    fallthrough
                case .number, .identifier:
                    fallthrough
                case .endOfScope("}"), .endOfScope(">"),
                     .endOfScope("]") where !formatter.isInClosureArguments(at: index),
                     .endOfScope(")") where !formatter.isAttribute(at: index):
                    formatter.removeToken(at: i - 1)
                default:
                    break
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
        formatter.forEach(.startOfScope("[")) { i, _ in
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
        formatter.forEach(.operator("=", .infix)) { i, _ in
            guard let keyword = formatter.lastSignificantKeyword(at: i),
                  ["var", "let"].contains(keyword)
            else {
                return
            }

            let equalsIndex = i
            guard let colonIndex = formatter.index(before: i, where: {
                [.delimiter(":"), .operator("=", .infix)].contains($0)
            }), formatter.tokens[colonIndex] == .delimiter(":"),
            let typeEndIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: equalsIndex)
            else { return }

            /// Compares whether or not two types are equivalent
            func compare(typeStartingAfter j: Int, withTypeStartingAfter i: Int)
                -> (matches: Bool, i: Int, j: Int, wasValue: Bool)
            {
                var i = i, j = j, wasValue = false

                while let typeIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i),
                      typeIndex <= typeEndIndex,
                      let valueIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: j)
                {
                    let typeToken = formatter.tokens[typeIndex]
                    let valueToken = formatter.tokens[valueIndex]
                    if !wasValue {
                        switch valueToken {
                        case _ where valueToken.isStringDelimiter, .number,
                             .identifier("true"), .identifier("false"):
                            if formatter.options.redundantType == .explicit {
                                // We never remove the value in this case, so exit early
                                return (false, i, j, wasValue)
                            }
                            wasValue = true
                        default:
                            break
                        }
                    }
                    guard typeToken == formatter.typeToken(forValueToken: valueToken) else {
                        return (false, i, j, wasValue)
                    }
                    // Avoid introducing "inferred to have type 'Void'" warning
                    if formatter.options.redundantType == .inferred, typeToken == .identifier("Void") ||
                        typeToken == .endOfScope(")") && formatter.tokens[i] == .startOfScope("(")
                    {
                        return (false, i, j, wasValue)
                    }
                    i = typeIndex
                    j = valueIndex
                    if formatter.tokens[j].isStringDelimiter, let next = formatter.endOfScope(at: j) {
                        j = next
                    }
                }
                guard i == typeEndIndex else {
                    return (false, i, j, wasValue)
                }

                // Check for ternary
                if let endOfExpression = formatter.endOfExpression(at: j, upTo: [.operator("?", .infix)]),
                   formatter.next(.nonSpaceOrCommentOrLinebreak, after: endOfExpression) == .operator("?", .infix)
                {
                    return (false, i, j, wasValue)
                }

                return (true, i, j, wasValue)
            }

            // The implementation of RedundantType uses inferred or explicit,
            // potentially depending on the context.
            let isInferred: Bool
            switch formatter.options.redundantType {
            case .inferred:
                isInferred = true
            case .explicit:
                isInferred = false
            case .inferLocalsOnly:
                switch formatter.declarationScope(at: equalsIndex) {
                case .global, .type:
                    isInferred = false
                case .local:
                    isInferred = true
                }
            }

            /// Removes a type already processed by `compare(typeStartingAfter:withTypeStartingAfter:)`
            func removeType(after indexBeforeStartOfType: Int, i: Int, j: Int, wasValue: Bool) {
                if isInferred {
                    formatter.removeTokens(in: colonIndex ... typeEndIndex)
                    if formatter.tokens[colonIndex - 1].isSpace {
                        formatter.removeToken(at: colonIndex - 1)
                    }
                } else if !wasValue, let valueStartIndex = formatter
                    .index(of: .nonSpaceOrCommentOrLinebreak, after: indexBeforeStartOfType),
                    !formatter.isConditionalStatement(at: i),
                    let endIndex = formatter.endOfExpression(at: j, upTo: []),
                    endIndex > j
                {
                    let allowChains = formatter.options.swiftVersion >= "5.4"
                    if formatter.next(.nonSpaceOrComment, after: j) == .startOfScope("(") {
                        if allowChains || formatter.index(
                            of: .operator(".", .infix),
                            in: j ..< endIndex
                        ) == nil {
                            formatter.replaceTokens(in: valueStartIndex ... j, with: [
                                .operator(".", .infix), .identifier("init"),
                            ])
                        }
                    } else if let nextIndex = formatter.index(
                        of: .nonSpaceOrCommentOrLinebreak,
                        after: j,
                        if: { $0 == .operator(".", .infix) }
                    ), allowChains || formatter.index(
                        of: .operator(".", .infix),
                        in: (nextIndex + 1) ..< endIndex
                    ) == nil {
                        formatter.removeTokens(in: valueStartIndex ... j)
                    }
                }
            }

            // In Swift 5.8+ we need to handle if / switch expressions by checking each branch
            if formatter.options.swiftVersion >= "5.8",
               let tokenAfterEquals = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: equalsIndex),
               let conditionalBranches = formatter.conditionalBranches(at: tokenAfterEquals),
               formatter.allRecursiveConditionalBranches(
                   in: conditionalBranches,
                   satisfy: { branch in
                       compare(typeStartingAfter: branch.startOfBranch, withTypeStartingAfter: colonIndex).matches
                   }
               )
            {
                if isInferred {
                    formatter.removeTokens(in: colonIndex ... typeEndIndex)
                    if formatter.tokens[colonIndex - 1].isSpace {
                        formatter.removeToken(at: colonIndex - 1)
                    }
                } else {
                    formatter.forEachRecursiveConditionalBranch(in: conditionalBranches) { branch in
                        let (_, i, j, wasValue) = compare(
                            typeStartingAfter: branch.startOfBranch,
                            withTypeStartingAfter: colonIndex
                        )

                        removeType(after: branch.startOfBranch, i: i, j: j, wasValue: wasValue)
                    }
                }
            }

            // Otherwise this is just a simple assignment expression where the RHS is a single value
            else {
                let (matches, i, j, wasValue) = compare(typeStartingAfter: equalsIndex, withTypeStartingAfter: colonIndex)
                if matches {
                    removeType(after: equalsIndex, i: i, j: j, wasValue: wasValue)
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
        help: """
        Converts types used for hosting only static members into enums (an empty enum is
        the canonical way to create a namespace in Swift as it can't be instantiated).
        """,
        options: ["enumnamespaces"]
    ) { formatter in
        func rangeHostsOnlyStaticMembersAtTopLevel(_ range: Range<Int>) -> Bool {
            // exit for empty declarations
            guard formatter.next(.nonSpaceOrCommentOrLinebreak, in: range) != nil else {
                return false
            }

            var j = range.startIndex
            while j < range.endIndex, let token = formatter.token(at: j) {
                if token == .startOfScope("{"),
                   let skip = formatter.index(of: .endOfScope("}"), after: j)
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

        formatter.forEachToken(where: { [
            .keyword("class"),
            .keyword("struct"),
        ].contains($0) }) { i, token in
            guard formatter.last(.keyword, before: i) != .keyword("import"),
                  // exit if class is a type modifier
                  let next = formatter.next(.nonSpaceOrCommentOrLinebreak, after: i),
                  !(next.isKeyword || next.isModifierKeyword),
                  // exit for class as protocol conformance
                  formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) != .delimiter(":"),
                  let braceIndex = formatter.index(of: .startOfScope("{"), after: i),
                  // exit if type is conforming any types
                  !formatter.tokens[i ... braceIndex].contains(.delimiter(":")),
                  let endIndex = formatter.index(of: .endOfScope("}"), after: braceIndex),
                  case let .identifier(name)? = formatter.next(.identifier, after: i + 1),
                  // exit if open for extension
                  !formatter.modifiersForDeclaration(at: i, contains: "open")
            else {
                return
            }
            switch formatter.options.enumNamespaces {
            case .structsOnly where token == .keyword("struct"), .always:
                break
            case .structsOnly:
                return
            }
            let range = braceIndex + 1 ..< endIndex
            if rangeHostsOnlyStaticMembersAtTopLevel(range),
               !rangeContainsTypeInit(name, in: range), !rangeContainsSelfAssignment(range)
            {
                formatter.replaceToken(at: i, with: .keyword("enum"))

                if let finalIndex = formatter.indexOfModifier("final", forDeclarationAt: i),
                   let nextIndex = formatter.index(of: .nonSpace, after: finalIndex)
                {
                    formatter.removeTokens(in: finalIndex ..< nextIndex)
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
            if let scope = formatter.currentScope(at: i), scope.isMultilineStringDelimiter {
                return
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
        orderAfter: ["organizeDeclarations"],
        options: ["typeblanklines"]
    ) { formatter in
        formatter.forEach(.startOfScope) { i, token in
            guard ["{", "(", "[", "<"].contains(token.string),
                  let indexOfFirstLineBreak = formatter.index(of: .nonSpaceOrComment, after: i),
                  // If there is extra code on the same line, ignore it
                  formatter.tokens[indexOfFirstLineBreak].isLinebreak
            else { return }

            // Consumers can choose whether or not this rule should apply to type bodies
            if !formatter.options.removeStartOrEndBlankLinesFromTypes,
               ["class", "struct", "enum", "actor", "protocol", "extension"].contains(
                   formatter.lastSignificantKeyword(at: i, excluding: ["where"]))
            {
                return
            }

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
        orderAfter: ["organizeDeclarations"],
        sharedOptions: ["typeblanklines"]
    ) { formatter in
        formatter.forEach(.startOfScope) { startOfScopeIndex, _ in
            guard let endOfScopeIndex = formatter.endOfScope(at: startOfScopeIndex) else { return }
            let endOfScope = formatter.tokens[endOfScopeIndex]

            guard ["}", ")", "]", ">"].contains(endOfScope.string),
                  // If there is extra code after the closing scope on the same line, ignore it
                  (formatter.next(.nonSpaceOrComment, after: endOfScopeIndex).map { $0.isLinebreak }) ?? true
            else { return }

            // Consumers can choose whether or not this rule should apply to type bodies
            if !formatter.options.removeStartOrEndBlankLinesFromTypes,
               ["class", "struct", "enum", "actor", "protocol", "extension"].contains(
                   formatter.lastSignificantKeyword(at: startOfScopeIndex, excluding: ["where"]))
            {
                return
            }

            // Find previous non-space token
            var index = endOfScopeIndex - 1
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

    /// Remove blank lines between import statements
    public let blankLinesBetweenImports = FormatRule(
        help: """
        Remove blank lines between import statements.
        """,
        disabledByDefault: true,
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEach(.keyword("import")) { currentImportIndex, _ in
            guard let endOfLine = formatter.index(of: .linebreak, after: currentImportIndex),
                  let nextImportIndex = formatter.index(of: .nonSpaceOrLinebreak, after: endOfLine, if: {
                      $0 == .keyword("@testable") || $0 == .keyword("import")
                  })
            else {
                return
            }

            formatter.replaceTokens(in: endOfLine ..< nextImportIndex, with: formatter.linebreakToken(for: currentImportIndex + 1))
        }
    }

    /// Insert blank line after import statements
    public let blankLineAfterImports = FormatRule(
        help: """
        Insert blank line after import statements.
        """,
        disabledByDefault: true,
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEach(.keyword("import")) { currentImportIndex, _ in
            guard let endOfLine = formatter.index(of: .linebreak, after: currentImportIndex),
                  var nextIndex = formatter.index(of: .nonSpace, after: endOfLine)
            else {
                return
            }
            if formatter.tokens[nextIndex] == .startOfScope("#if") {
                var keyword = "#if"
                while keyword == "#if",
                      let index = formatter.index(of: .keyword, after: nextIndex)
                {
                    nextIndex = index
                    keyword = formatter.tokens[nextIndex].string
                }
            }
            switch formatter.tokens[nextIndex] {
            case .linebreak, .keyword("import"), .keyword("@testable"),
                 .keyword("@_exported"), .keyword("@_implementationOnly"),
                 .keyword("#else"), .keyword("#elseif"), .endOfScope("#endif"):
                break
            default:
                formatter.insertLinebreak(at: endOfLine)
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
            outer: switch token {
            case .keyword("class"),
                 .keyword("actor"),
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
                if let nextNonCommentIndex =
                    formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i)
                {
                    switch formatter.tokens[nextNonCommentIndex] {
                    case .error, .endOfScope,
                         .operator(".", _), .delimiter(","), .delimiter(":"),
                         .keyword("else"), .keyword("catch"), .keyword("#else"):
                        break outer
                    case .keyword("while"):
                        if let previousBraceIndex = formatter.index(of: .startOfScope("{"), before: i),
                           formatter.last(.nonSpaceOrCommentOrLinebreak, before: previousBraceIndex)
                           == .keyword("repeat")
                        {
                            break outer
                        }
                    default:
                        if formatter.isLabel(at: nextNonCommentIndex), let colonIndex
                            = formatter.index(of: .delimiter(":"), after: nextNonCommentIndex),
                            formatter.next(.nonSpaceOrCommentOrLinebreak, after: colonIndex)
                            == .startOfScope("{")
                        {
                            break outer
                        }
                    }
                }
                switch formatter.tokens[nextTokenIndex] {
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
        options: ["lineaftermarks"],
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEachToken { i, token in
            guard case let .commentBody(comment) = token, comment.hasPrefix("MARK:"),
                  let startIndex = formatter.index(of: .nonSpace, before: i),
                  formatter.tokens[startIndex] == .startOfScope("//") else { return }
            if let nextIndex = formatter.index(of: .linebreak, after: i),
               let nextToken = formatter.next(.nonSpace, after: nextIndex),
               !nextToken.isLinebreak, nextToken != .endOfScope("}"),
               formatter.options.lineAfterMarks
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
        options: ["indent", "tabwidth", "smarttabs", "indentcase", "ifdef", "xcodeindentation", "indentstrings"],
        sharedOptions: ["trimwhitespace", "allman", "wrapconditions", "wrapternary"]
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
                case "{" where formatter.isStartOfClosure(at: i):
                    // When a trailing closure starts on the same line as the end of a multi-line
                    // method call the trailing closure body should be double-indented
                    if let prevIndex = formatter.index(of: .nonSpaceOrComment, before: i),
                       formatter.tokens[prevIndex] == .endOfScope(")"),
                       case let prevIndent = formatter.indentForLine(at: prevIndex),
                       prevIndent == indent + formatter.options.indent
                    {
                        if linewrapStack.last == false {
                            linewrapStack[linewrapStack.count - 1] = true
                            indentStack.append(prevIndent)
                            stringBodyIndentStack.append("")
                        }
                        indent = prevIndent
                    }
                    let stringIndent = stringBodyIndent(at: i)
                    stringBodyIndentStack[stringBodyIndentStack.count - 1] = stringIndent
                    indent += stringIndent + formatter.options.indent
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
                    let lastIndentCount = indentCounts.last ?? 0
                    if indentCount > lastIndentCount {
                        indentCount = lastIndentCount
                        indentCounts[indentCounts.count - 1] = 1
                    }
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
                if let startIndex = formatter.index(of: .startOfScope("{"), before: i),
                   formatter.index(of: .keyword("for"), in: startIndex + 1 ..< i) == nil,
                   let paramsIndex = formatter.index(of: .startOfScope, in: startIndex + 1 ..< i),
                   !formatter.tokens[startIndex + 1 ..< paramsIndex].contains(where: {
                       $0.isLinebreak
                   }), formatter.tokens[paramsIndex + 1 ..< i].contains(where: {
                       $0.isLinebreak
                   })
                {
                    indentStack[indentStack.count - 1] += formatter.options.indent
                }
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
                    func isInIfdef() -> Bool {
                        guard scopeStack.last == .startOfScope("#if") else {
                            return false
                        }
                        var index = i - 1
                        while index > 0 {
                            switch formatter.tokens[index] {
                            case .keyword("switch"):
                                return false
                            case .startOfScope("#if"), .keyword("#else"), .keyword("#elseif"):
                                return true
                            default:
                                index -= 1
                            }
                        }
                        return false
                    }
                    if token == .endOfScope("#endif"), formatter.options.ifdefIndent == .outdent {
                        i += formatter.insertSpaceIfEnabled("", at: start)
                    } else {
                        var indent = indentStack.last ?? ""
                        if token.isSwitchCaseOrDefault,
                           formatter.options.indentCase, !isInIfdef()
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
                        (nextTokenIndex.map { formatter.isTrailingClosureLabel(at: $0) } == true) ||
                        !(nextTokenIndex == nil || [
                            .endOfScope("}"), .endOfScope("]"), .endOfScope(")"),
                        ].contains(formatter.tokens[nextTokenIndex!]) ||
                            formatter.isStartOfStatement(at: nextTokenIndex!, in: scopeStack.last) || (
                                ((formatter.tokens[nextTokenIndex!].isIdentifier && !(formatter.tokens[nextTokenIndex!] == .identifier("async") && formatter.currentScope(at: nextTokenIndex!) != .startOfScope("("))) || [
                                    .keyword("try"), .keyword("await"),
                                ].contains(formatter.tokens[nextTokenIndex!])) &&
                                    formatter.last(.nonSpaceOrCommentOrLinebreak, before: nextTokenIndex!).map {
                                        $0 != .keyword("return") && !$0.isOperator(ofType: .infix)
                                    } ?? false) || (
                                formatter.tokens[nextTokenIndex!] == .delimiter(",") && [
                                    "<", "[", "(", "case",
                                ].contains(formatter.currentScope(at: nextTokenIndex!)?.string ?? "")
                            )
                        )
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
                        let shouldIndentLeadingDotStatement: Bool
                        if formatter.options.xcodeIndentation {
                            if let prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i),
                               formatter.token(at: formatter.startOfLine(
                                   at: prevIndex, excludingIndent: true
                               )) == .endOfScope("}"),
                               formatter.index(of: .linebreak, in: prevIndex + 1 ..< i) != nil
                            {
                                shouldIndentLeadingDotStatement = false
                            } else {
                                shouldIndentLeadingDotStatement = true
                            }
                        } else {
                            shouldIndentLeadingDotStatement = (
                                formatter.startOfConditionalStatement(at: i) != nil
                                    && formatter.options.wrapConditions == .beforeFirst
                            )
                        }
                        if shouldIndentLeadingDotStatement,
                           formatter.next(.nonSpace, after: i) == .operator(".", .infix),
                           let prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i),
                           case let lineStart = formatter.index(of: .linebreak, before: prevIndex + 1) ??
                           formatter.startOfLine(at: prevIndex),
                           let startIndex = formatter.index(of: .nonSpace, after: lineStart),
                           formatter.isStartOfStatement(at: startIndex) || (
                               (formatter.tokens[startIndex].isIdentifier || [
                                   .keyword("try"), .keyword("await"),
                               ].contains(formatter.tokens[startIndex]) ||
                                   formatter.isTrailingClosureLabel(at: startIndex)) &&
                                   formatter.last(.nonSpaceOrCommentOrLinebreak, before: startIndex).map {
                                       $0 != .keyword("return") && !$0.isOperator(ofType: .infix)
                                   } ?? false)
                        {
                            indent += formatter.options.indent
                            indentStack[indentStack.count - 1] = indent
                        }

                        // When inside conditionals, unindent after any commas (which separate conditions)
                        // that were indented by the block above
                        if !formatter.options.xcodeIndentation,
                           formatter.options.wrapConditions == .beforeFirst,
                           formatter.isConditionalStatement(at: i),
                           formatter.lastToken(before: i, where: {
                               $0.is(.nonSpaceOrCommentOrLinebreak)
                           }) == .delimiter(","),
                           let conditionBeginIndex = formatter.index(before: i, where: {
                               ["if", "guard", "while", "for"].contains($0.string)
                           }),
                           formatter.indentForLine(at: conditionBeginIndex)
                           .count < indent.count + formatter.options.indent.count
                        {
                            indent = formatter.indentForLine(at: conditionBeginIndex) + formatter.options.indent
                            indentStack[indentStack.count - 1] = indent
                        }

                        let startOfLineIndex = formatter.startOfLine(at: i, excludingIndent: true)
                        let startOfLine = formatter.tokens[startOfLineIndex]

                        if formatter.options.wrapTernaryOperators == .beforeOperators,
                           startOfLine == .operator(":", .infix) || startOfLine == .operator("?", .infix)
                        {
                            // Push a ? scope onto the stack so we can easily know
                            // that the next : is the closing operator of this ternary
                            if startOfLine.string == "?" {
                                // We smuggle the index of this operator in the scope stack
                                // so we can recover it trivially when handling the
                                // corresponding : operator.
                                scopeStack.append(.operator("?-\(startOfLineIndex)", .infix))
                            }

                            // Indent any operator-leading lines following a compomnent operator
                            // of a wrapped ternary operator expression, except for the :
                            // following a ?
                            if
                                let nextToken = formatter.next(.nonSpace, after: i),
                                nextToken.isOperator(ofType: .infix),
                                nextToken != .operator(":", .infix)
                            {
                                indent += formatter.options.indent
                                indentStack[indentStack.count - 1] = indent
                            }
                        }

                        // Make sure the indentation for this : operator matches
                        // the indentation of the previous ? operator
                        if formatter.options.wrapTernaryOperators == .beforeOperators,
                           formatter.next(.nonSpace, after: i) == .operator(":", .infix),
                           let scope = scopeStack.last,
                           scope.string.hasPrefix("?"),
                           scope.isOperator(ofType: .infix),
                           let previousOperatorIndex = scope.string.components(separatedBy: "-").last.flatMap({ Int($0) })
                        {
                            scopeStack.removeLast()
                            indent = formatter.indentForLine(at: previousOperatorIndex)
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
                            ["class", "actor", "struct", "enum", "protocol", "extension",
                             "func"].contains(keyword)
                        else {
                            return false
                        }

                        let end = formatter.endOfLine(at: i + 1)
                        guard let lastToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: end + 1),
                              [.startOfScope("{"), .endOfScope("}")].contains(lastToken) else { return false }

                        return true
                    }

                    // Don't indent line starting with dot if previous line was just a closing brace
                    var lastToken = formatter.tokens[lastNonSpaceOrLinebreakIndex]
                    if formatter.options.allmanBraces, nextToken == .startOfScope("{"),
                       formatter.isStartOfClosure(at: nextNonSpaceIndex)
                    {
                        // Don't indent further
                    } else if formatter.token(at: nextTokenIndex ?? -1) == .operator(".", .infix) ||
                        formatter.isLabel(at: nextTokenIndex ?? -1)
                    {
                        var lineStart = formatter.startOfLine(at: lastNonSpaceOrLinebreakIndex, excludingIndent: true)
                        let startToken = formatter.token(at: lineStart)
                        if let startToken = startToken, [
                            .startOfScope("#if"), .keyword("#else"), .keyword("#elseif"), .endOfScope("#endif")
                        ].contains(startToken) {
                            if let index = formatter.index(of: .nonSpaceOrLinebreak, before: lineStart) {
                                lastNonSpaceOrLinebreakIndex = index
                                lineStart = formatter.startOfLine(at: lastNonSpaceOrLinebreakIndex, excludingIndent: true)
                            }
                        }
                        if formatter.token(at: lineStart) == .operator(".", .infix),
                           [.keyword("#else"), .keyword("#elseif"), .endOfScope("#endif")].contains(startToken)
                        {
                            indent = formatter.indentForLine(at: lineStart)
                        } else if formatter.tokens[lineStart ..< lastNonSpaceOrLinebreakIndex].allSatisfy({
                            $0.isEndOfScope || $0.isSpaceOrComment
                        }) {
                            if lastToken.isEndOfScope {
                                indent = formatter.indentForLine(at: lastNonSpaceOrLinebreakIndex)
                            }
                            if !lastToken.isEndOfScope || lastToken == .endOfScope("case") ||
                                formatter.options.xcodeIndentation, ![
                                    .endOfScope("}"), .endOfScope(")")
                                ].contains(lastToken)
                            {
                                indent += formatter.options.indent
                            }
                        } else if !formatter.options.xcodeIndentation || !isWrappedDeclaration() {
                            indent += formatter.linewrapIndent(at: i)
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
                    if formatter.isLabel(at: nextNonSpaceIndex),
                       formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) == .endOfScope("}")
                    {
                        break
                    }
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

        if formatter.options.indentStrings {
            formatter.forEach(.startOfScope("\"\"\"")) { stringStartIndex, _ in
                let baseIndent = formatter.indentForLine(at: stringStartIndex)
                let expectedIndent = baseIndent + formatter.options.indent

                guard
                    let stringEndIndex = formatter.endOfScope(at: stringStartIndex),
                    // Preserve the default indentation if the opening """ is on a line by itself
                    formatter.startOfLine(at: stringStartIndex, excludingIndent: true) != stringStartIndex
                else { return }

                for linebreakIndex in (stringStartIndex ..< stringEndIndex).reversed()
                    where formatter.tokens[linebreakIndex].isLinebreak
                {
                    // If this line is completely blank, do nothing
                    //  - This prevents conflicts with the trailingSpace rule
                    if formatter.nextToken(after: linebreakIndex)?.isLinebreak == true {
                        continue
                    }

                    let indentIndex = linebreakIndex + 1
                    if formatter.tokens[indentIndex].is(.space) {
                        formatter.replaceToken(at: indentIndex, with: .space(expectedIndent))
                    } else {
                        formatter.insert(.space(expectedIndent), at: indentIndex)
                    }
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
                let ruleName = FormatRules.wrapMultilineStatementBraces.name
                if formatter.options.enabledRules.contains(ruleName),
                   formatter.shouldWrapMultilineStatementBrace(at: i)
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
                    if !formatter.options.allmanBraces {
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

    public let wrapConditionalBodies = FormatRule(
        help: "Wrap the bodies of inline conditional statements onto a new line.",
        disabledByDefault: true,
        sharedOptions: ["linebreaks", "indent"]
    ) { formatter in
        formatter.forEachToken { i, token in
            guard ["if", "else"].contains(token.string) else {
                return
            }

            guard var openBraceIndex = formatter.index(of: .startOfScope("{"), after: i) else {
                return
            }

            // We need to make sure to move past any closures in the conditional
            while formatter.isStartOfClosure(at: openBraceIndex) {
                guard let endOfClosureIndex = formatter.index(of: .endOfScope("}"), after: openBraceIndex) else {
                    return
                }
                guard let nextOpenBrace = formatter.index(of: .startOfScope("{"), after: endOfClosureIndex + 1) else {
                    return
                }
                openBraceIndex = nextOpenBrace
            }

            guard var indexOfFirstTokenInNewScope = formatter.index(of: .nonSpaceOrComment, after: openBraceIndex) else {
                // If there is only space or comments right after the opening brace we want to leave them alone
                return
            }

            guard !formatter.tokens[indexOfFirstTokenInNewScope].isEndOfScope else {
                // The scope is empty so just stop
                return
            }

            guard !formatter.tokens[indexOfFirstTokenInNewScope].isLinebreak else {
                // There is already a newline after the brace so we can just stop
                return
            }

            formatter.insertLinebreak(at: indexOfFirstTokenInNewScope)

            if formatter.tokens[indexOfFirstTokenInNewScope - 1].isSpace {
                // We left behind a trailing space on the previous line so we should clean it up
                formatter.removeToken(at: indexOfFirstTokenInNewScope - 1)
                indexOfFirstTokenInNewScope -= 1
            }

            let movedTokenIndex = indexOfFirstTokenInNewScope + 1

            // We want the token to be indented one level more than the conditional is
            let indent = formatter.indentForLine(at: i) + formatter.options.indent
            formatter.insertSpace(indent, at: movedTokenIndex)

            guard var closingBraceIndex = formatter.index(of: .endOfScope("}"), after: movedTokenIndex) else {
                return
            }

            let linebreakBeforeBrace = (movedTokenIndex ..< closingBraceIndex).contains(where: { formatter.tokens[$0].isLinebreak })

            guard !linebreakBeforeBrace else {
                // The closing brace is already on its own line so we don't need to do anything else
                return
            }

            formatter.insertLinebreak(at: closingBraceIndex)

            let lineBreakIndex = closingBraceIndex
            closingBraceIndex += 1

            let previousIndex = lineBreakIndex - 1
            if formatter.tokens[previousIndex].isSpace {
                // We left behind a trailing space on the previous line so we should clean it up
                formatter.removeToken(at: previousIndex)
                closingBraceIndex -= 1
            }

            // We want the closing brace at the same indentation level as conditional
            formatter.insertSpace(formatter.indentForLine(at: i), at: closingBraceIndex)
        }
    }

    /// Ensure that the last item in a multi-line array literal is followed by a comma.
    /// This is useful for preventing noise in commits when items are added to end of array.
    public let trailingCommas = FormatRule(
        help: "Add or remove trailing comma from the last item in a collection literal.",
        options: ["commas"]
    ) { formatter in
        formatter.forEach(.endOfScope("]")) { i, _ in
            guard let prevTokenIndex = formatter.index(of: .nonSpaceOrComment, before: i),
                  let scopeType = formatter.scopeType(at: i)
            else {
                return
            }
            switch scopeType {
            case .array, .dictionary:
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
            default:
                return
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
            if string.hasPrefix("/"), let scopeStart = formatter.index(of: .startOfScope, before: i, if: {
                $0 == .startOfScope("//")
            }) {
                if let prevLinebreak = formatter.index(of: .linebreak, before: scopeStart),
                   case .commentBody? = formatter.last(.nonSpace, before: prevLinebreak)
                {
                    return
                }
                if let nextLinebreak = formatter.index(of: .linebreak, after: i),
                   case .startOfScope("//")? = formatter.next(.nonSpace, after: nextLinebreak)
                {
                    return
                }
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
                let prevTokenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i)
                let prevToken = prevTokenIndex.map { formatter.tokens[$0] }
                if prevToken == nil || nextToken == .endOfScope("}") {
                    // Safe to remove
                    formatter.removeToken(at: i)
                } else if prevToken == .keyword("return") || (
                    formatter.options.swiftVersion < "3" &&
                        // Might be a traditional for loop (not supported in Swift 3 and above)
                        formatter.currentScope(at: i) == .startOfScope("(")
                ) {
                    // Not safe to remove or replace
                } else if case .identifier? = prevToken, formatter.last(
                    .nonSpaceOrCommentOrLinebreak, before: prevTokenIndex!
                ) == .keyword("var") {
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
            case "let", "func", "var", "class", "actor", "extension", "init", "enum",
                 "struct", "typealias", "subscript", "associatedtype", "protocol":
                break
            default:
                return
            }
            var modifiers = [String: [Token]]()
            var lastModifier: (name: String, tokens: [Token])?
            func pushModifier() {
                lastModifier.map { modifiers[$0.name] = $0.tokens }
            }
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
                    pushModifier()
                    lastModifier = (token.string, [Token](formatter.tokens[index ..< lastIndex]))
                    previousIndex = lastIndex
                    lastIndex = index
                case .endOfScope(")"):
                    if case let .identifier(param)? = formatter.last(.nonSpaceOrCommentOrLinebreak, before: index),
                       let openParenIndex = formatter.index(of: .startOfScope("("), before: index),
                       let index = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: openParenIndex),
                       let token = formatter.token(at: index), token.isModifierKeyword
                    {
                        pushModifier()
                        let modifier = token.string + (param == "set" ? "(set)" : "")
                        lastModifier = (modifier, [Token](formatter.tokens[index ..< lastIndex]))
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
            pushModifier()
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
            var isClosure = false
            let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: closingIndex) ?? .space("")
            switch nextToken {
            case .operator("->", .infix), .keyword("throws"), .keyword("rethrows"),
                 .identifier("async"), .keyword("in"):
                guard let prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i) else {
                    return
                }
                isClosure = formatter.tokens[prevIndex] == .endOfScope("]") ||
                    formatter.isStartOfClosure(at: prevIndex)
                if !isClosure, nextToken != .keyword("in") {
                    return // It's a closure type or function declaration
                }
            case .operator:
                if case let .operator(inner, _)? = formatter.last(.nonSpace, before: closingIndex),
                   !["?", "!"].contains(inner)
                {
                    return
                }
            default:
                break
            }
            let previousIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i) ?? -1
            let prevToken = formatter.token(at: previousIndex) ?? .space("")
            switch prevToken {
            case _ where isClosure:
                if formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i) == closingIndex ||
                    formatter.index(of: .delimiter(":"), in: i + 1 ..< closingIndex) != nil ||
                    formatter.tokens[i + 1 ..< closingIndex].contains(.identifier("self"))
                {
                    return
                }
                if let index = formatter.tokens[i + 1 ..< closingIndex].firstIndex(of: .identifier("_")),
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
                      ![.endOfScope("}"), .endOfScope(">")].contains(prevToken) ||
                      ![.startOfScope("{"), .delimiter(",")].contains(nextToken)
                else {
                    return
                }
                let string = prevToken.string
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
                if prevToken == .startOfScope("("),
                   formatter.last(.nonSpaceOrComment, before: previousIndex) == .identifier("Selector")
                {
                    return
                }
                if case .operator = formatter.tokens[closingIndex - 1],
                   case .operator(_, .infix)? = formatter.token(at: closingIndex + 1)
                {
                    return
                }
                let nextNonLinebreak = formatter.next(.nonSpaceOrComment, after: closingIndex)
                if let index = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i),
                   case .operator = formatter.tokens[index]
                {
                    if nextToken.isOperator(".") || (index == i + 1 &&
                        formatter.token(at: i - 1)?.isSpaceOrCommentOrLinebreak == false)
                    {
                        return
                    }
                    switch nextNonLinebreak {
                    case .startOfScope("[")?, .startOfScope("(")?, .operator(_, .postfix)?:
                        return
                    default:
                        break
                    }
                }
                guard formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i) != closingIndex,
                      formatter.index(in: i + 1 ..< closingIndex, where: {
                          switch $0 {
                          case .operator(_, .infix), .identifier("any"), .identifier("some"),
                               .keyword("as"), .keyword("is"), .keyword("try"), .keyword("await"):
                              switch prevToken {
                              // TODO: add option to always strip parens in this case (or only for boolean operators?)
                              case .operator("=", .infix) where $0 == .operator("->", .infix):
                                  break
                              case .operator(_, .prefix), .operator(_, .infix), .keyword("as"), .keyword("is"):
                                  return true
                              default:
                                  break
                              }
                              switch nextToken {
                              case .operator(_, .postfix), .operator(_, .infix), .keyword("as"), .keyword("is"):
                                  return true
                              default:
                                  break
                              }
                              switch nextNonLinebreak {
                              case .startOfScope("[")?, .startOfScope("(")?, .operator(_, .postfix)?:
                                  return true
                              default:
                                  return false
                              }
                          case .operator(_, .postfix):
                              switch prevToken {
                              case .operator(_, .prefix), .keyword("as"), .keyword("is"):
                                  return true
                              default:
                                  return false
                              }
                          case .delimiter(","), .delimiter(":"), .delimiter(";"),
                               .operator(_, .none), .startOfScope("{"):
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
               }), let openIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i, if: {
                   $0 == .startOfScope("{")
               }),
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
                    case .keyword("struct") where formatter.options.swiftVersion < "5.2":
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
                case .keyword("if"), .keyword("guard"), .keyword("while"), .identifier("async"),
                     .delimiter(",") where formatter.currentScope(at: i) != .startOfScope("("):
                    return
                default:
                    break
                }
            }
            // Crude check for Result Builder
            if formatter.isInResultBuilder(at: i) {
                return
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
                if let endOfScopeIndex = formatter.index(
                    before: prevIndex,
                    where: { tkn in tkn == .endOfScope("case") || tkn == .keyword("case") }
                ),
                    let varOrLetIndex = formatter.index(after: endOfScopeIndex, where: { tkn in
                        tkn == .keyword("let") || tkn == .keyword("var")
                    }),
                    let operatorIndex = formatter.index(of: .operator, before: prevIndex),
                    varOrLetIndex < operatorIndex
                {
                    formatter.removeTokens(in: varOrLetIndex ..< operatorIndex)
                }
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

    /// Remove redundant void return values for function and closure declarations
    public let redundantVoidReturnType = FormatRule(
        help: "Remove explicit `Void` return type.",
        options: ["closurevoid"]
    ) { formatter in
        formatter.forEach(.operator("->", .infix)) { i, _ in
            guard let startIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i),
                  let endIndex = formatter.endOfVoidType(at: startIndex)
            else {
                return
            }

            // If this is the explicit return type of a closure, it should
            // always be safe to remove
            if formatter.options.closureVoidReturn == .remove,
               formatter.next(.nonSpaceOrCommentOrLinebreak, after: endIndex) == .keyword("in")
            {
                formatter.removeTokens(in: i ..< formatter.index(of: .nonSpace, after: endIndex)!)
                return
            }

            guard
                formatter.next(.nonSpaceOrCommentOrLinebreak, after: endIndex) == .startOfScope("{")
            else { return }

            guard let prevIndex = formatter.index(of: .endOfScope(")"), before: i),
                  let parenIndex = formatter.index(of: .startOfScope("("), before: prevIndex),
                  let startToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: parenIndex),
                  startToken.isIdentifier || [.startOfScope("{"), .endOfScope("]")].contains(startToken)
            else {
                return
            }
            formatter.removeTokens(in: i ..< formatter.index(of: .nonSpace, after: endIndex)!)
        }
    }

    /// Remove redundant return keyword
    public let redundantReturn = FormatRule(
        help: "Remove unneeded `return` keyword."
    ) { formatter in
        // Explicit returns are redundant in closures, functions, etc with a single statement body
        formatter.forEach(.startOfScope("{")) { startOfScopeIndex, _ in
            // Make sure this is a type of scope that supports implicit returns
            if formatter.isConditionalStatement(at: startOfScopeIndex) ||
                ["do", "else", "catch"].contains(formatter.lastSignificantKeyword(at: startOfScopeIndex))
            {
                return
            }

            // Closures always supported implicit returns, but other types of scopes
            // only support implicit return in Swift 5.1+ (SE-0255)
            if !formatter.isStartOfClosure(at: startOfScopeIndex) {
                guard formatter.options.swiftVersion >= "5.1" else {
                    return
                }
            }

            // Make sure the body only has a single statement
            guard
                formatter.blockBodyHasSingleStatement(atStartOfScope: startOfScopeIndex)
            else { return }

            /// Removes return statements in the given single-statement scope
            func removeReturn(atStartOfScope startOfScopeIndex: Int) {
                // If this scope is a single-statement if or switch statement then we have to recursively
                // remove the return from each branch of the if statement
                let startOfBody = formatter.startOfBody(atStartOfScope: startOfScopeIndex)

                if let firstTokenInBody = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: startOfBody),
                   let conditionalBranches = formatter.conditionalBranches(at: firstTokenInBody)
                {
                    for branch in conditionalBranches {
                        removeReturn(atStartOfScope: branch.startOfBranch)
                    }
                }

                // Otherwise this is a simple case with a single return at the start of the scope
                else if
                    let endOfScopeIndex = formatter.endOfScope(at: startOfScopeIndex),
                    let returnIndex = formatter.index(of: .keyword("return"), after: startOfScopeIndex),
                    returnIndex < endOfScopeIndex,
                    let tokenIndexAfterReturn = formatter.index(of: .nonSpaceOrLinebreak, after: returnIndex)
                {
                    formatter.removeTokens(in: returnIndex ..< tokenIndexAfterReturn)
                }
            }

            removeReturn(atStartOfScope: startOfScopeIndex)
        }

        // Also handle redundant void returns in void functions, which can always be removed.
        //  - The following code is the original implementation of the `redundantReturn` rule
        //    and is partially redundant with the above code so could be simplified in the future.
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
                guard ![.delimiter(":"), .startOfScope("(")].contains(prevToken),
                      var prevKeywordIndex = formatter.indexOfLastSignificantKeyword(
                          at: startIndex, excluding: ["where"]
                      )
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
                case "func", "throws", "rethrows", "async", "init", "subscript":
                    if formatter.options.swiftVersion < "5.1",
                       formatter.next(.nonSpaceOrCommentOrLinebreak, after: i) != .endOfScope("}")
                    {
                        return
                    }
                default:
                    return
                }
            default:
                guard let endIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i, if: {
                    $0 == .endOfScope("}")
                }), let startIndex = formatter.index(of: .startOfScope("{"), before: endIndex) else {
                    return
                }
                if !formatter.isStartOfClosure(at: startIndex), !["func", "throws", "rethrows", "async"]
                    .contains(formatter.lastSignificantKeyword(at: startIndex, excluding: ["where"]) ?? "")
                {
                    return
                }
            }
            if formatter.index(of: .keyword("return"), after: i) != nil {
                return
            }
            if formatter.next(.nonSpaceOrLinebreak, after: i) == .endOfScope("}"),
               let startIndex = formatter.index(of: .nonSpaceOrLinebreak, before: i)
            {
                formatter.removeTokens(in: startIndex + 1 ... i)
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
                         typeStack: inout [(name: String, keyword: String)],
                         closureStack: inout [(allowsImplicitSelf: Bool, selfCapture: String?)],
                         membersByType: inout [String: Set<String>],
                         classMembersByType: inout [String: Set<String>],
                         usingDynamicLookup: Bool,
                         isTypeRoot: Bool,
                         isInit: Bool)
        {
            var explicitSelf: SelfMode { formatter.options.explicitSelf }
            let isWhereClause = index > 0 && formatter.tokens[index - 1] == .keyword("where")
            assert(isWhereClause || formatter.currentScope(at: index).map { token -> Bool in
                [.startOfScope("{"), .startOfScope(":"), .startOfScope("#if")].contains(token)
            } ?? true)
            let isCaseClause = !isWhereClause && index > 0 &&
                formatter.tokens[index - 1].isSwitchCaseOrDefault
            if explicitSelf == .remove {
                // Check if scope actually includes self before we waste a bunch of time
                var scopeStack: [Token] = []
                loop: for i in index ..< formatter.tokens.count {
                    let token = formatter.tokens[i]
                    switch token {
                    case .identifier("self"):
                        break loop // Contains self
                    case .startOfScope("{") where isWhereClause && scopeStack.isEmpty:
                        return // Does not contain self
                    case .startOfScope("{"), .startOfScope("("),
                         .startOfScope("["), .startOfScope(":"):
                        scopeStack.append(token)
                    case .endOfScope("}"), .endOfScope(")"), .endOfScope("]"),
                         .endOfScope("case"), .endOfScope("default"):
                        if scopeStack.isEmpty || (scopeStack == [.startOfScope(":")] && isCaseClause) {
                            index = i + 1
                            return // Does not contain self
                        }
                        _ = scopeStack.popLast()
                    default:
                        break
                    }
                }
            }
            let inClosureDisallowingImplicitSelf = closureStack.last?.allowsImplicitSelf == false
            /// Starting in Swift 5.8, self can be rebound using a `let self = self` unwrap condition
            /// within a weak self closure. This is the only place where defining a property
            /// named self affects the behavior of implicit self.
            let scopeAllowsImplicitSelfRebinding = formatter.options.swiftVersion >= "5.8"
                && closureStack.last?.selfCapture == "weak self"

            // Gather members & local variables
            let type = (isTypeRoot && typeStack.count == 1) ? typeStack.first : nil
            var members = (type?.name).flatMap { membersByType[$0] } ?? members
            var classMembers = (type?.name).flatMap { classMembersByType[$0] } ?? Set<String>()
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
                    case .keyword("if"), .keyword("for"), .keyword("while"):
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
                            let removeSelf = explicitSelf != .insert && !usingDynamicLookup && !inClosureDisallowingImplicitSelf
                            let onlyLocal = formatter.options.swiftVersion < "5"

                            formatter.processDeclaredVariables(at: &i, names: &localNames,
                                                               removeSelf: removeSelf,
                                                               onlyLocal: onlyLocal,
                                                               scopeAllowsImplicitSelfRebinding: scopeAllowsImplicitSelfRebinding)
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
                    case .startOfScope("//"), .startOfScope("/*"):
                        if case let .commentBody(comment)? = formatter.next(.nonSpace, after: i) {
                            formatter.processCommentBody(comment, at: i)
                            if token == .startOfScope("//") {
                                formatter.processLinebreak()
                            }
                        }
                        i = formatter.endOfScope(at: i) ?? (formatter.tokens.count - 1)
                    case .startOfScope:
                        classOrStatic = false
                        i = formatter.endOfScope(at: i) ?? (formatter.tokens.count - 1)
                    case .endOfScope("}"), .endOfScope("case"), .endOfScope("default"):
                        break outer
                    case .linebreak:
                        formatter.processLinebreak()
                    default:
                        break
                    }
                    i += 1
                }
            }
            if let type = type {
                membersByType[type.name] = members
                classMembersByType[type.name] = classMembers
            }
            // Remove or add `self`
            var lastKeyword = ""
            var lastKeywordIndex = 0
            var classOrStatic = false
            var scopeStack = [(
                token: Token.space(""),
                dynamicMemberTypes: Set<String>()
            )]

            while let token = formatter.token(at: index) {
                switch token {
                case .keyword("is"), .keyword("as"), .keyword("try"), .keyword("await"):
                    break
                case .keyword("init"), .keyword("subscript"),
                     .keyword("func") where lastKeyword != "import":
                    lastKeyword = ""
                    if classOrStatic {
                        processFunction(at: &index, localNames: localNames, members: classMembers,
                                        typeStack: &typeStack, closureStack: &closureStack, membersByType: &membersByType,
                                        classMembersByType: &classMembersByType,
                                        usingDynamicLookup: usingDynamicLookup)
                        classOrStatic = false
                    } else {
                        processFunction(at: &index, localNames: localNames, members: members,
                                        typeStack: &typeStack, closureStack: &closureStack, membersByType: &membersByType,
                                        classMembersByType: &classMembersByType,
                                        usingDynamicLookup: usingDynamicLookup)
                    }
                    assert(formatter.token(at: index) != .endOfScope("}"))
                    continue
                case .keyword("static"):
                    if !isTypeRoot {
                        return formatter.fatalError("Unexpected static keyword", at: index)
                    }
                    classOrStatic = true
                case .keyword("class") where
                    formatter.next(.nonSpaceOrCommentOrLinebreak, after: index)?.isIdentifier == false:
                    if formatter.last(.nonSpaceOrCommentOrLinebreak, before: index) != .delimiter(":") {
                        if !isTypeRoot {
                            return formatter.fatalError("Unexpected class keyword", at: index)
                        }
                        classOrStatic = true
                    }
                case .keyword("where") where lastKeyword == "protocol", .keyword("protocol"):
                    if let startIndex = formatter.index(of: .startOfScope("{"), after: index),
                       let endIndex = formatter.endOfScope(at: startIndex)
                    {
                        index = endIndex
                    }
                case .keyword("extension"), .keyword("struct"), .keyword("enum"), .keyword("class"), .keyword("actor"),
                     .keyword("where") where ["extension", "struct", "enum", "class", "actor"].contains(lastKeyword):
                    let keyword = formatter.tokens[index].string
                    guard formatter.last(.nonSpaceOrCommentOrLinebreak, before: index) != .keyword("import"),
                          let scopeStart = formatter.index(of: .startOfScope("{"), after: index)
                    else {
                        return
                    }
                    guard let nameToken = formatter.next(.identifier, after: index),
                          case let .identifier(name) = nameToken
                    else {
                        return
                    }
                    var usingDynamicLookup = formatter.modifiersForDeclaration(
                        at: index,
                        contains: "@dynamicMemberLookup"
                    )
                    if usingDynamicLookup {
                        scopeStack[scopeStack.count - 1].dynamicMemberTypes.insert(name)
                    } else if [token.string, lastKeyword].contains("extension"),
                              scopeStack.last!.dynamicMemberTypes.contains(name)
                    {
                        usingDynamicLookup = true
                    }
                    index = scopeStart + 1
                    typeStack.append((name: name, keyword: keyword))
                    processBody(at: &index, localNames: ["init"], members: [], typeStack: &typeStack,
                                closureStack: &closureStack, membersByType: &membersByType, classMembersByType: &classMembersByType,
                                usingDynamicLookup: usingDynamicLookup, isTypeRoot: true, isInit: false)
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
                    case "if", "while", "guard", "for":
                        assert(!isTypeRoot)
                        // Guard is included because it's an error to reference guard vars in body
                        var scopedNames = localNames
                        formatter.processDeclaredVariables(
                            at: &index, names: &scopedNames,
                            removeSelf: explicitSelf != .insert && !inClosureDisallowingImplicitSelf,
                            onlyLocal: false,
                            scopeAllowsImplicitSelfRebinding: scopeAllowsImplicitSelfRebinding
                        )
                        while let scope = formatter.currentScope(at: index) ?? formatter.token(at: index),
                              [.startOfScope("["), .startOfScope("(")].contains(scope),
                              let endIndex = formatter.endOfScope(at: index)
                        {
                            // TODO: find less hacky workaround
                            index = endIndex + 1
                        }
                        if scopeStack.last?.token == .startOfScope("(") {
                            scopeStack.removeLast()
                        }
                        guard var startIndex = formatter.token(at: index) == .startOfScope("{") ?
                            index : formatter.index(of: .startOfScope("{"), after: index)
                        else {
                            return formatter.fatalError("Expected {", at: index)
                        }
                        while formatter.isStartOfClosure(at: startIndex) {
                            guard let i = formatter.index(of: .endOfScope("}"), after: startIndex) else {
                                return formatter.fatalError("Expected }", at: startIndex)
                            }
                            guard let j = formatter.index(of: .startOfScope("{"), after: i) else {
                                return formatter.fatalError("Expected {", at: i)
                            }
                            startIndex = j
                        }
                        index = startIndex + 1
                        processBody(at: &index, localNames: scopedNames, members: members, typeStack: &typeStack,
                                    closureStack: &closureStack, membersByType: &membersByType, classMembersByType: &classMembersByType,
                                    usingDynamicLookup: usingDynamicLookup, isTypeRoot: false, isInit: isInit)
                        lastKeyword = ""
                    case "case" where ["if", "while", "guard", "for"].contains(lastKeyword):
                        break
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
                                closureStack: &closureStack, membersByType: &membersByType, classMembersByType: &classMembersByType,
                                usingDynamicLookup: usingDynamicLookup, isTypeRoot: false, isInit: isInit)
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
                case .startOfScope where token.isStringDelimiter, .startOfScope("#if"),
                     .startOfScope("["), .startOfScope("("):
                    scopeStack.append((token, []))
                case .startOfScope(":"):
                    lastKeyword = ""
                case .startOfScope("{") where lastKeyword == "catch":
                    lastKeyword = ""
                    var localNames = localNames
                    localNames.insert("error") // Implicit error argument
                    index += 1
                    processBody(at: &index, localNames: localNames, members: members, typeStack: &typeStack,
                                closureStack: &closureStack, membersByType: &membersByType, classMembersByType: &classMembersByType,
                                usingDynamicLookup: usingDynamicLookup, isTypeRoot: false, isInit: isInit)
                    continue
                case .startOfScope("{") where isWhereClause && scopeStack.count == 1:
                    return
                case .startOfScope("{") where lastKeyword == "switch":
                    lastKeyword = ""
                    index += 1
                    loop: while let token = formatter.token(at: index) {
                        index += 1
                        switch token {
                        case .endOfScope("case"), .endOfScope("default"):
                            let localNames = localNames
                            processBody(at: &index, localNames: localNames, members: members, typeStack: &typeStack, closureStack: &closureStack,
                                        membersByType: &membersByType, classMembersByType: &classMembersByType,
                                        usingDynamicLookup: usingDynamicLookup, isTypeRoot: false, isInit: isInit)
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
                                closureStack: &closureStack, membersByType: &membersByType, classMembersByType: &classMembersByType,
                                usingDynamicLookup: usingDynamicLookup, isTypeRoot: false, isInit: isInit)
                    continue
                case .startOfScope("{") where lastKeyword == "var":
                    lastKeyword = ""
                    if formatter.isStartOfClosure(at: index, in: scopeStack.last?.token) {
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
                                         typeStack: &typeStack, closureStack: &closureStack, membersByType: &membersByType,
                                         classMembersByType: &classMembersByType,
                                         usingDynamicLookup: usingDynamicLookup)
                    }
                    continue
                case .startOfScope("{") where formatter.isStartOfClosure(at: index):
                    // Parse the capture list and arguments list,
                    // and record the type of `self` capture used in the closure
                    var captureList: [Token]?
                    var parameterList: [Token]?

                    // Handle a capture list followed by an optional parameter list:
                    // `{ [self, foo] bar in` or `{ [self, foo] in` etc.
                    if let captureListStartIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index),
                       formatter.tokens[captureListStartIndex] == .startOfScope("["),
                       let captureListEndIndex = formatter.endOfScope(at: captureListStartIndex),
                       let inIndex = formatter.index(of: .keyword("in"), after: captureListEndIndex)
                    {
                        captureList = Array(formatter.tokens[(captureListStartIndex + 1) ..< captureListEndIndex])
                        parameterList = Array(formatter.tokens[(captureListEndIndex + 1) ..< inIndex])
                    }

                    // Handle a parameter list if present without a capture list
                    // e.g. `{ foo, bar in`
                    else if let firstTokenInClosure = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index),
                            formatter.isInClosureArguments(at: firstTokenInClosure),
                            let inIndex = formatter.index(of: .keyword("in"), after: index)
                    {
                        parameterList = Array(formatter.tokens[firstTokenInClosure ..< inIndex])
                    }

                    var captureListEntires = (captureList ?? []).split(separator: .delimiter(","), omittingEmptySubsequences: true)
                    let parameterListEntries = (parameterList ?? []).split(separator: .delimiter(","), omittingEmptySubsequences: true)

                    let supportedSelfCaptures = Set([
                        "self",
                        "unowned self",
                        "unowned(safe) self",
                        "unowned(unsafe) self",
                        "weak self",
                    ])

                    let captureEntryStrings = captureListEntires.map { captureListEntry in
                        captureListEntry
                            .map { $0.string }
                            .joined()
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                    }

                    let selfCapture = captureEntryStrings.first(where: {
                        supportedSelfCaptures.contains($0)
                    })

                    captureListEntires.removeAll(where: { captureListEntry in
                        let text = captureListEntry
                            .map { $0.string }
                            .joined()
                            .trimmingCharacters(in: .whitespacesAndNewlines)

                        return text == selfCapture
                    })

                    let localDefiningDeclarations = captureListEntires + parameterListEntries
                    var closureLocalNames = localNames

                    for tokens in localDefiningDeclarations {
                        guard let localIdentifier = tokens.first(where: { $0.isIdentifier }) else {
                            continue
                        }

                        closureLocalNames.insert(localIdentifier.string)
                    }

                    /// Whether or not the closure at the current index permits implicit self.
                    ///
                    /// SE-0269 (in Swift 5.3) allows implicit self when:
                    ///  - the closure captures self explicitly using [self] or [unowned self]
                    ///  - self is not a reference type
                    ///
                    /// SE-0365 (in Swift 5.8) additionally allows implicit self using
                    /// [weak self] captures after self has been unwrapped.
                    func closureAllowsImplicitSelf() -> Bool {
                        guard formatter.options.swiftVersion >= "5.3" else {
                            return false
                        }

                        // If self is a reference type, capturing it won't create a retain cycle,
                        // so the compiler lets us use implicit self
                        if let enclosingTypeKeyword = typeStack.last?.keyword,
                           enclosingTypeKeyword == "struct" || enclosingTypeKeyword == "enum"
                        {
                            return true
                        }

                        guard let selfCapture = selfCapture else {
                            return false
                        }

                        // If self is captured strongly, or using `unowned`, then the compiler
                        // lets us use implicit self since it's already clear that this closure
                        // captures self strongly
                        if selfCapture == "self"
                            || selfCapture == "unowned self"
                            || selfCapture == "unowned(safe) self"
                            || selfCapture == "unowned(unsafe) self"
                        {
                            return true
                        }

                        // This is also supported for `weak self` captures, but only
                        // in Swift 5.8 or later
                        if selfCapture == "weak self",
                           formatter.options.swiftVersion >= "5.8"
                        {
                            return true
                        }

                        return false
                    }

                    closureStack.append((allowsImplicitSelf: closureAllowsImplicitSelf(), selfCapture: selfCapture))
                    index += 1
                    processBody(at: &index, localNames: closureLocalNames, members: members, typeStack: &typeStack, closureStack: &closureStack,
                                membersByType: &membersByType, classMembersByType: &classMembersByType,
                                usingDynamicLookup: usingDynamicLookup, isTypeRoot: false, isInit: isInit)
                    index -= 1
                    closureStack.removeLast()
                case .startOfScope:
                    index = formatter.endOfScope(at: index) ?? (formatter.tokens.count - 1)
                case .identifier("self"):
                    guard formatter.isEnabled, explicitSelf != .insert, !isTypeRoot, !usingDynamicLookup,
                          let dotIndex = formatter.index(of: .nonSpaceOrLinebreak, after: index, if: {
                              $0 == .operator(".", .infix)
                          }),
                          let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: dotIndex)
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
                    if let closure = closureStack.last, !closure.allowsImplicitSelf {
                        break
                    }
                    _ = formatter.removeSelf(at: index, exclude: localNames)
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
                        case .identifier, .number, .endOfScope,
                             .operator where ![
                                 .operator("=", .infix), .operator(".", .prefix)
                             ].contains(prevToken):
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
                        while let scope = scopeStack.last?.token, scope != .space("") {
                            scopeStack.removeLast()
                            if scope != .startOfScope("#if") {
                                break
                            }
                        }
                    } else if let scope = scopeStack.last?.token, scope != .space("") {
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
                              typeStack: inout [(name: String, keyword: String)],
                              closureStack: inout [(allowsImplicitSelf: Bool, selfCapture: String?)],
                              membersByType: inout [String: Set<String>],
                              classMembersByType: inout [String: Set<String>],
                              usingDynamicLookup: Bool)
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
                            closureStack: &closureStack, membersByType: &membersByType, classMembersByType: &classMembersByType,
                            usingDynamicLookup: usingDynamicLookup, isTypeRoot: false, isInit: false)
            }
            if foundAccessors {
                guard let endIndex = formatter.index(of: .endOfScope("}"), after: index) else { return }
                index = endIndex + 1
            } else {
                index += 1
                localNames.insert(name)
                processBody(at: &index, localNames: localNames, members: members, typeStack: &typeStack,
                            closureStack: &closureStack, membersByType: &membersByType, classMembersByType: &classMembersByType,
                            usingDynamicLookup: usingDynamicLookup, isTypeRoot: false, isInit: false)
            }
        }
        func processFunction(at index: inout Int, localNames: Set<String>, members: Set<String>,
                             typeStack: inout [(name: String, keyword: String)],
                             closureStack: inout [(allowsImplicitSelf: Bool, selfCapture: String?)],
                             membersByType: inout [String: Set<String>],
                             classMembersByType: inout [String: Set<String>],
                             usingDynamicLookup: Bool)
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
                                 members: members, typeStack: &typeStack, closureStack: &closureStack, membersByType: &membersByType,
                                 classMembersByType: &classMembersByType,
                                 usingDynamicLookup: usingDynamicLookup)
            } else {
                index = bodyStartIndex + 1
                processBody(at: &index,
                            localNames: localNames,
                            members: members,
                            typeStack: &typeStack,
                            closureStack: &closureStack,
                            membersByType: &membersByType,
                            classMembersByType: &classMembersByType,
                            usingDynamicLookup: usingDynamicLookup,
                            isTypeRoot: false,
                            isInit: startToken == .keyword("init"))
            }
        }
        var typeStack = [(name: String, keyword: String)]()
        var closureStack = [(allowsImplicitSelf: Bool, selfCapture: String?)]()
        var membersByType = [String: Set<String>]()
        var classMembersByType = [String: Set<String>]()
        var index = 0
        processBody(at: &index, localNames: [], members: [], typeStack: &typeStack,
                    closureStack: &closureStack, membersByType: &membersByType, classMembersByType: &classMembersByType,
                    usingDynamicLookup: false, isTypeRoot: false, isInit: false)
    }

    /// Replace unused arguments with an underscore
    public let unusedArguments = FormatRule(
        help: "Mark unused function arguments with `_`.",
        options: ["stripunusedargs"]
    ) { formatter in
        guard !formatter.options.fragment else { return }

        func removeUsed<T>(from argNames: inout [String], with associatedData: inout [T],
                           locals: Set<String> = [], in range: CountableRange<Int>)
        {
            var isDeclaration = false
            var wasDeclaration = false
            var isConditional = false
            var isGuard = false
            var locals = locals
            var tempLocals = Set<String>()
            func pushLocals() {
                if isDeclaration, isConditional {
                    for name in tempLocals {
                        if let index = argNames.firstIndex(of: name),
                           !locals.contains(name)
                        {
                            argNames.remove(at: index)
                            associatedData.remove(at: index)
                        }
                    }
                }
                wasDeclaration = isDeclaration
                isDeclaration = false
                locals.formUnion(tempLocals)
                tempLocals.removeAll()
            }
            var i = range.lowerBound
            while i < range.upperBound {
                if formatter.isStartOfStatement(at: i) {
                    pushLocals()
                    wasDeclaration = false
                }
                let token = formatter.tokens[i]
                switch token {
                case .keyword("guard"):
                    isGuard = true
                case .keyword("let"), .keyword("var"), .keyword("func"), .keyword("for"):
                    isDeclaration = true
                    var i = i
                    while let scopeStart = formatter.index(of: .startOfScope("("), before: i) {
                        i = scopeStart
                    }
                    isConditional = formatter.isConditionalStatement(at: i)
                case .identifier:
                    let name = token.unescaped()
                    guard let index = argNames.firstIndex(of: name), !locals.contains(name) else {
                        break
                    }
                    if formatter.last(.nonSpaceOrCommentOrLinebreak, before: i)?.isOperator(".") == false,
                       formatter.next(.nonSpaceOrCommentOrLinebreak, after: i) != .delimiter(":") ||
                       formatter.currentScope(at: i) == .startOfScope("[")
                    {
                        if isDeclaration {
                            tempLocals.insert(name)
                            break
                        }
                        argNames.remove(at: index)
                        associatedData.remove(at: index)
                        if argNames.isEmpty {
                            return
                        }
                    }
                case .startOfScope("{"):
                    guard let endIndex = formatter.endOfScope(at: i) else {
                        argNames.removeAll()
                        return
                    }
                    if formatter.isStartOfClosure(at: i) {
                        removeUsed(from: &argNames, with: &associatedData,
                                   locals: locals, in: i + 1 ..< endIndex)
                    } else if isGuard {
                        removeUsed(from: &argNames, with: &associatedData,
                                   locals: locals, in: i + 1 ..< endIndex)
                        pushLocals()
                    } else {
                        let prevLocals = locals
                        pushLocals()
                        removeUsed(from: &argNames, with: &associatedData,
                                   locals: locals, in: i + 1 ..< endIndex)
                        locals = prevLocals
                    }

                    isGuard = false
                    i = endIndex
                case .endOfScope("case"), .endOfScope("default"):
                    pushLocals()
                    guard let colonIndex = formatter.index(of: .startOfScope(":"), after: i),
                          let endIndex = formatter.endOfScope(at: colonIndex)
                    else {
                        argNames.removeAll()
                        return
                    }
                    removeUsed(from: &argNames, with: &associatedData,
                               locals: locals, in: i + 1 ..< endIndex)
                    i = endIndex - 1
                case .operator("=", .infix), .delimiter(":"), .startOfScope(":"),
                     .keyword("in"), .keyword("where"):
                    wasDeclaration = isDeclaration
                    isDeclaration = false
                case .delimiter(","):
                    if let scope = formatter.currentScope(at: i), [
                        .startOfScope("("), .startOfScope("["), .startOfScope("<"),
                    ].contains(scope) {
                        break
                    }
                    if isConditional {
                        wasDeclaration = false
                    }
                    let _wasDeclaration = wasDeclaration
                    pushLocals()
                    isDeclaration = _wasDeclaration
                case .delimiter(";"):
                    pushLocals()
                    wasDeclaration = false
                default:
                    break
                }
                i += 1
            }
        }
        // Closure arguments
        formatter.forEach(.keyword("in")) { i, _ in
            var argNames = [String]()
            var nameIndexPairs = [(Int, Int)]()
            guard let start = formatter.index(of: .startOfScope("{"), before: i) else {
                return
            }
            var index = i - 1
            var argCountStack = [0]
            while index > start {
                let token = formatter.tokens[index]
                switch token {
                case .endOfScope("}"):
                    return
                case .endOfScope("]"):
                    // TODO: handle unused capture list arguments
                    index = formatter.index(of: .startOfScope("["), before: index) ?? index
                case .endOfScope(")"):
                    argCountStack.append(argNames.count)
                case .startOfScope("("):
                    argCountStack.removeLast()
                case .delimiter(","):
                    argCountStack[argCountStack.count - 1] = argNames.count
                case .identifier("async") where
                    formatter.last(.nonSpaceOrLinebreak, before: index)?.isIdentifier == true:
                    fallthrough
                case .operator("->", .infix), .keyword("throws"):
                    // Everything after this was part of return value
                    let count = argCountStack.last ?? 0
                    argNames.removeSubrange(count ..< argNames.count)
                    nameIndexPairs.removeSubrange(count ..< nameIndexPairs.count)
                case let .keyword(name) where
                    !token.isAttribute && !name.hasPrefix("#") && name != "inout":
                    return
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
                       let nextToken = formatter.token(at: nextIndex), case .identifier = nextToken,
                       formatter.next(.nonSpaceOrCommentOrLinebreak, after: nextIndex) == .delimiter(":")
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
        formatter.forEachToken { i, token in
            guard formatter.options.stripUnusedArguments != .closureOnly,
                  case let .keyword(keyword) = token, ["func", "init", "subscript"].contains(keyword),
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

    public let hoistTry = FormatRule(
        help: "Move inline `try` keyword(s) to start of expression."
    ) { formatter in
        formatter.forEach(.startOfScope("(")) { i, _ in
            func insertTry(at insertIndex: Int) {
                var insertIndex = insertIndex
                if formatter.tokens[insertIndex].isSpace {
                    insertIndex += 1
                }

                formatter.insert([.keyword("try")], at: insertIndex)

                if let nextToken = formatter.token(at: insertIndex + 1), !nextToken.isSpace {
                    formatter.insertSpace(" ", at: insertIndex + 1)
                } else {
                    formatter.insertSpace(" ", at: insertIndex)
                }
            }

            // TODO: find better approach
            func isThrowingAutoclosureFunction(_ token: Token) -> Bool {
                if case let .identifier(name) = token {
                    return name.hasPrefix("XCTAssert") || name == "expect"
                }
                return false
            }

            guard let endIndex = formatter.index(of: .endOfScope(")"), after: i) else {
                return
            }

            var tryIndexes: [Int] = []
            var index = i
            while let next = formatter.index(of: .keyword("try"), in: index + 1 ..< endIndex),
                  !formatter.tokens[next + 1].isUnwrapOperator // ignore try? or try!
            {
                tryIndexes.append(next)
                index = next
            }

            guard !tryIndexes.isEmpty else {
                return
            }

            tryIndexes.reversed().forEach {
                formatter.removeToken(at: $0)
                if formatter.token(at: $0)?.isSpace == true {
                    formatter.removeToken(at: $0)
                }
            }

            if var prevIndex = formatter.index(before: i, where: {
                $0.isDelimiter || $0.isLinebreak || $0.isStartOfScope ||
                    $0.isOperator("=") || ($0.isKeyword && ![
                        .keyword("is"), .keyword("as"), .keyword("await")
                    ].contains($0)) || isThrowingAutoclosureFunction($0)
            }) {
                if formatter.tokens[prevIndex] == .keyword("try") {
                    return
                }
                if isThrowingAutoclosureFunction(formatter.tokens[prevIndex]),
                   let index = formatter.index(of: .startOfScope("("), after: prevIndex)
                {
                    prevIndex = index
                }
                insertTry(at: prevIndex + 1)
            } else if formatter.token(at: i - 1)?.isStartOfScope == true {
                insertTry(at: i)
            } else {
                insertTry(at: 0)
            }
        }
    }

    /// Reposition `await` keyword outside of the current scope.
    public let hoistAwait = FormatRule(
        help: "Move inline `await` keyword(s) to start of expression."
    ) { formatter in
        guard formatter.options.swiftVersion >= "5.5" else { return }

        formatter.forEach(.startOfScope("(")) { i, _ in
            func insertAwait(at insertIndex: Int) {
                if let awaitIndex = formatter.index(of: .keyword("await"), before: i) {
                    guard formatter.tokens[awaitIndex ..< i].contains(where: {
                        $0.isStartOfScope || $0.isLinebreak
                    }) else {
                        return
                    }
                }

                var insertIndex = insertIndex
                if formatter.tokens[insertIndex].isSpace {
                    insertIndex += 1
                }

                formatter.insert([.keyword("await")], at: insertIndex)

                if let nextToken = formatter.token(at: insertIndex + 1), !nextToken.isSpace {
                    formatter.insertSpace(" ", at: insertIndex + 1)
                } else {
                    formatter.insertSpace(" ", at: insertIndex)
                }
            }

            guard let endIndex = formatter.index(of: .endOfScope(")"), after: i) else {
                return
            }

            var awaitIndexes: [Int] = []
            var index = i
            while let next = formatter.index(of: .keyword("await"), in: index + 1 ..< endIndex) {
                awaitIndexes.append(next)
                index = next
            }

            guard !awaitIndexes.isEmpty else {
                return
            }

            let prevIndex = formatter.index(before: i, where: {
                $0.isSpaceOrLinebreak
            })

            awaitIndexes.reversed().forEach {
                formatter.removeToken(at: $0)
                if formatter.token(at: $0)?.isSpace == true {
                    formatter.removeToken(at: $0)
                }
            }

            if let prevIndex = formatter.index(before: i, where: {
                $0.isDelimiter || $0.isLinebreak || $0.isStartOfScope ||
                    $0.isOperator("=") || ($0.isKeyword && ![
                        .keyword("is"), .keyword("as")
                    ].contains($0))
            }) {
                insertAwait(at: prevIndex + 1)
            } else if formatter.token(at: i - 1)?.isStartOfScope == true {
                insertAwait(at: i)
            } else {
                insertAwait(at: 0)
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
                      case .operator(".", _), .keyword("let"), .keyword("var"),
                           .endOfScope("*/"):
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
            let startIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: prevIndex)
                ?? (prevIndex + 1)
            if case let .keyword(keyword) = formatter.tokens[startIndex],
               ["let", "var"].contains(keyword)
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
                    case .identifier("_"), .identifier("true"), .identifier("false"), .identifier("nil"):
                        wasParenOrCommaOrLabel = false
                    case let .identifier(name) where wasParenOrCommaOrLabel:
                        wasParenOrCommaOrLabel = false
                        let next = formatter.next(.nonSpaceOrComment, after: index)
                        if next != .operator(".", .infix), next != .delimiter(":") {
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
                let range = ((formatter.index(of: .nonSpace, before: startIndex) ??
                        (prevIndex - 1)) + 1) ... startIndex
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
        options: ["maxwidth", "nowrapoperators", "assetliterals", "wrapternary"],
        sharedOptions: ["wraparguments", "wrapparameters", "wrapcollections", "closingparen", "indent",
                        "trimwhitespace", "linebreaks", "tabwidth", "maxwidth", "smarttabs", "wrapreturntype", "wrapconditions", "wraptypealiases", "wrapternary", "wrapeffects"]
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
                  "wrapreturntype", "wrapconditions", "wraptypealiases", "wrapeffects"],
        sharedOptions: ["indent", "trimwhitespace", "linebreaks",
                        "tabwidth", "maxwidth", "smarttabs", "assetliterals", "wrapternary"]
    ) { formatter in
        formatter.wrapCollectionsAndArguments(completePartialWrapping: true,
                                              wrapSingleArguments: false)
    }

    public let wrapMultilineStatementBraces = FormatRule(
        help: "Wrap the opening brace of multiline statements.",
        orderAfter: ["braces", "indent", "wrapArguments"],
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEach(.startOfScope("{")) { i, _ in
            guard formatter.last(.nonSpaceOrComment, before: i)?.isLinebreak == false,
                  formatter.shouldWrapMultilineStatementBrace(at: i),
                  let endIndex = formatter.endOfScope(at: i)
            else {
                return
            }
            let indent = formatter.indentForLine(at: endIndex)
            // Insert linebreak
            formatter.insertLinebreak(at: i)
            // Align the opening brace with closing brace
            formatter.insertSpace(indent, at: i + 1)
            // Clean up trailing space on the previous line
            if case .space? = formatter.token(at: i - 1) {
                formatter.removeToken(at: i - 1)
            }
        }
    }

    /// Formats enum cases declaration into one case per line
    public let wrapEnumCases = FormatRule(
        help: "Writes one enum case per line.",
        disabledByDefault: true,
        options: ["wrapenumcases"],
        sharedOptions: ["linebreaks"]
    ) { formatter in

        func shouldWrapCaseRangeGroup(_ caseRangeGroup: [Formatter.EnumCaseRange]) -> Bool {
            formatter.options.wrapEnumCases == .always
                || caseRangeGroup
                .first(
                    where: { formatter.tokens[$0.value].contains { token in
                        token == .startOfScope("(") || token == .operator("=", .infix)
                    }}
                ) != nil
        }

        formatter.parseEnumCaseRanges()
            .filter(shouldWrapCaseRangeGroup)
            .flatMap { $0 }
            .filter { $0.endOfCaseRangeToken == .delimiter(",") }
            .sorted()
            .reversed()
            .forEach { enumCase in
                guard var nextNonSpaceIndex = formatter.index(of: .nonSpace, after: enumCase.value.upperBound) else {
                    return
                }
                let caseIndex = formatter.lastIndex(of: .keyword("case"), in: 0 ..< enumCase.value.lowerBound)
                let indent = formatter.indentForLine(at: caseIndex ?? enumCase.value.lowerBound)

                if formatter.tokens[nextNonSpaceIndex] == .startOfScope("//") {
                    formatter.removeToken(at: enumCase.value.upperBound)
                    if formatter.token(at: enumCase.value.upperBound)?.isSpace == true,
                       formatter.token(at: enumCase.value.upperBound - 1)?.isSpace == true
                    {
                        formatter.removeToken(at: enumCase.value.upperBound - 1)
                    }
                    nextNonSpaceIndex = formatter.index(of: .linebreak, after: enumCase.value.upperBound) ?? nextNonSpaceIndex
                } else {
                    formatter.removeTokens(in: enumCase.value.upperBound ..< nextNonSpaceIndex)
                    nextNonSpaceIndex = enumCase.value.upperBound
                }

                if !formatter.tokens[nextNonSpaceIndex].isLinebreak {
                    formatter.insertLinebreak(at: nextNonSpaceIndex)
                }

                formatter.insertSpace(indent, at: nextNonSpaceIndex + 1)
                formatter.insert([.keyword("case")], at: nextNonSpaceIndex + 2)
                formatter.insertSpace(" ", at: nextNonSpaceIndex + 3)
            }
    }

    /// Wrap single-line comments that exceed given `FormatOptions.maxWidth` setting.
    public let wrapSingleLineComments = FormatRule(
        help: "Wrap single line `//` comments that exceed the specified `--maxwidth`.",
        sharedOptions: ["maxwidth", "indent", "tabwidth", "assetliterals", "linebreaks"]
    ) { formatter in
        let delimiterLength = "//".count
        var maxWidth = formatter.options.maxWidth
        guard maxWidth > 3 else {
            return
        }

        formatter.forEach(.startOfScope("//")) { i, _ in
            let startOfLine = formatter.startOfLine(at: i)
            let endOfLine = formatter.endOfLine(at: i)
            guard formatter.lineLength(from: startOfLine, upTo: endOfLine) > maxWidth else {
                return
            }

            guard let startIndex = formatter.index(of: .nonSpace, after: i),
                  case var .commentBody(comment) = formatter.tokens[startIndex],
                  !comment.isCommentDirective
            else {
                return
            }

            var words = comment.components(separatedBy: " ")
            comment = words.removeFirst()
            let commentPrefix = comment == "/" ? "/ " : comment.hasPrefix("/") ? "/" : ""
            let prefixLength = formatter.lineLength(upTo: startIndex)
            var length = prefixLength + comment.count
            while length <= maxWidth, let next = words.first,
                  length + next.count < maxWidth ||
                  // Don't wrap if next word won't fit on a line by itself anyway
                  prefixLength + commentPrefix.count + next.count > maxWidth
            {
                comment += " \(next)"
                length += next.count + 1
                words.removeFirst()
            }
            if words.isEmpty || comment == commentPrefix {
                return
            }
            var prefix = formatter.tokens[i ..< startIndex]
            if let token = formatter.token(at: startOfLine), case .space = token {
                prefix.insert(token, at: prefix.startIndex)
            }
            formatter.replaceTokens(in: startIndex ..< endOfLine, with: [
                .commentBody(comment), formatter.linebreakToken(for: startIndex),
            ] + prefix + [
                .commentBody(commentPrefix + words.joined(separator: " ")),
            ])
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
            case .operator("->", .infix), .keyword("throws"), .keyword("rethrows"), .identifier("async"):
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

        let hasLocalVoid: Bool = {
            for (i, token) in formatter.tokens.enumerated() where token == .identifier("Void") {
                if let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) {
                    switch prevToken {
                    case .keyword("typealias"), .keyword("struct"), .keyword("class"), .keyword("enum"):
                        return true
                    default:
                        break
                    }
                }
            }
            return false
        }()

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
                if isArgumentToken(at: nextIndex) || formatter.last(
                    .nonSpaceOrLinebreak,
                    before: prevIndex
                )?.isIdentifier == true {
                    if !formatter.options.useVoid, !hasLocalVoid {
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
                      [.operator(".", .prefix), .operator(".", .infix),
                       .keyword("typealias")].contains(prevToken)
            {
                return
            } else if formatter.next(.nonSpaceOrCommentOrLinebreak, after: i) ==
                .operator(".", .infix)
            {
                return
            } else if formatter.next(.nonSpace, after: i) == .startOfScope("(") {
                if !hasLocalVoid {
                    formatter.removeToken(at: i)
                }
            } else if !formatter.options.useVoid || isArgumentToken(at: i), !hasLocalVoid {
                // Convert to parens
                formatter.replaceToken(at: i, with: [.startOfScope("("), .endOfScope(")")])
            }
        }
        formatter.forEach(.startOfScope("(")) { i, _ in
            guard formatter.options.useVoid else {
                return
            }
            guard let endIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i, if: {
                $0 == .endOfScope(")")
            }), let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: i),
            !isArgumentToken(at: endIndex) else {
                return
            }
            if formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) == .operator("->", .infix) {
                if !hasLocalVoid {
                    formatter.replaceTokens(in: i ... endIndex, with: .identifier("Void"))
                }
            } else if prevToken == .startOfScope("<") ||
                (prevToken == .delimiter(",") && formatter.currentScope(at: i) == .startOfScope("<")),
                !hasLocalVoid
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
        var start = 0
        var lastHeaderTokenIndex = -1
        if var startIndex = formatter.index(of: .nonSpaceOrLinebreak, after: -1) {
            if formatter.tokens[startIndex] == .startOfScope("#!") {
                guard let endIndex = formatter.index(of: .linebreak, after: startIndex) else {
                    return
                }
                startIndex = formatter.index(of: .nonSpaceOrLinebreak, after: endIndex) ?? endIndex
                start = startIndex
                lastHeaderTokenIndex = startIndex - 1
            }
            switch formatter.tokens[startIndex] {
            case .startOfScope("//"):
                if case let .commentBody(body)? = formatter.next(.nonSpace, after: startIndex) {
                    formatter.processCommentBody(body, at: startIndex)
                    if !formatter.isEnabled || (body.hasPrefix("/") && !body.hasPrefix("//")) ||
                        body.hasPrefix("swift-tools-version")
                    {
                        return
                    } else if body.isCommentDirective {
                        break
                    }
                }
                var lastIndex = startIndex
                while let index = formatter.index(of: .linebreak, after: lastIndex) {
                    switch formatter.token(at: index + 1) ?? .space("") {
                    case .startOfScope("//"):
                        if case let .commentBody(body)? = formatter.next(.nonSpace, after: index + 1),
                           body.isCommentDirective
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
                    } else if body.isCommentDirective {
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
            formatter.removeTokens(in: start ..< lastHeaderTokenIndex + 1)
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
        if lastHeaderTokenIndex < formatter.tokens.count - 1 {
            headerTokens.append(.linebreak(formatter.options.linebreak, headerLinebreaks + 1))
            if lastHeaderTokenIndex < formatter.tokens.count - 2,
               !formatter.tokens[lastHeaderTokenIndex + 1 ... lastHeaderTokenIndex + 2].allSatisfy({
                   $0.isLinebreak
               })
            {
                headerTokens.append(.linebreak(formatter.options.linebreak, headerLinebreaks + 2))
            }
        }
        if let index = formatter.index(of: .nonSpace, after: lastHeaderTokenIndex, if: {
            $0.isLinebreak
        }) {
            lastHeaderTokenIndex = index
        }
        formatter.replaceTokens(in: start ..< lastHeaderTokenIndex + 1, with: headerTokens)
    }

    /// Strip redundant `.init` from type instantiations
    public let redundantInit = FormatRule(
        help: "Remove explicit `init` if not required."
    ) { formatter in
        formatter.forEach(.identifier("init")) { i, _ in
            guard let dotIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i, if: {
                $0 == .operator(".", .infix)
            }), let openParenIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i, if: {
                $0 == .startOfScope("(")
            }), let closeParenIndex = formatter.index(of: .endOfScope(")"), after: openParenIndex),
            formatter.last(.nonSpaceOrCommentOrLinebreak, before: closeParenIndex) != .delimiter(":"),
            let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: dotIndex),
            case let .identifier(name) = prevToken, let firstChar = name.first,
            firstChar != "$", String(firstChar).uppercased() == String(firstChar) else {
                return
            }
            var j = dotIndex
            while let prevIndex = formatter.index(
                of: prevToken, before: j
            ) ?? formatter.index(
                of: .startOfScope, before: j
            ) {
                j = prevIndex
                if prevToken == formatter.tokens[prevIndex],
                   let prevPrevToken = formatter.last(
                       .nonSpaceOrCommentOrLinebreak, before: prevIndex
                   ), [.keyword("let"), .keyword("var")].contains(prevPrevToken)
                {
                    return
                }
            }
            formatter.removeTokens(in: i + 1 ..< openParenIndex)
            formatter.removeTokens(in: dotIndex ... i)
        }
    }

    /// Sorts switch cases alphabetically
    public let sortedSwitchCases = FormatRule(
        help: "Sorts switch cases alphabetically.",
        disabledByDefault: true // TODO: enable by default in next major release
    ) { formatter in
        formatter.parseSwitchCaseRanges()
            .reversed() // don't mess with indexes
            .forEach { switchCaseRanges in
                guard switchCaseRanges.count > 1, // nothing to sort
                      let firstCaseIndex = switchCaseRanges.first?.beforeDelimiterRange.lowerBound else { return }

                let indentCounts = switchCaseRanges.map { formatter.indentForLine(at: $0.beforeDelimiterRange.lowerBound).count }
                let maxIndentCount = indentCounts.max() ?? 0

                func sortableValue(for token: Token) -> String? {
                    switch token {
                    case let .identifier(name):
                        return name
                    case let .stringBody(body):
                        return body
                    case let .number(value, .hex):
                        return Int(value.dropFirst(2), radix: 16)
                            .map(String.init) ?? value
                    case let .number(value, .octal):
                        return Int(value.dropFirst(2), radix: 8)
                            .map(String.init) ?? value
                    case let .number(value, .binary):
                        return Int(value.dropFirst(2), radix: 2)
                            .map(String.init) ?? value
                    case let .number(value, _):
                        return value
                    default:
                        return nil
                    }
                }

                let sorted = switchCaseRanges.sorted { case1, case2 -> Bool in
                    let lhs = formatter.tokens[case1.beforeDelimiterRange]
                        .compactMap(sortableValue)
                    let rhs = formatter.tokens[case2.beforeDelimiterRange]
                        .compactMap(sortableValue)
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

                let sortedTokens = sorted.map { formatter.tokens[$0.beforeDelimiterRange] }
                let sortedComments = sorted.map { formatter.tokens[$0.afterDelimiterRange] }

                // ignore if there's a where keyword and it is not in the last place.
                let firstWhereIndex = sortedTokens.firstIndex(where: { slice in slice.contains(.keyword("where")) })
                guard firstWhereIndex == nil || firstWhereIndex == sortedTokens.count - 1 else { return }

                for switchCase in switchCaseRanges.enumerated().reversed() {
                    let newTokens = Array(sortedTokens[switchCase.offset])
                    var newComments = Array(sortedComments[switchCase.offset])
                    let oldCommentsRange = sorted[switchCaseRanges.count - switchCase.offset - 1].afterDelimiterRange

                    let oldComments = formatter.tokens[oldCommentsRange]

                    var shouldInsertBreakLine = sortedComments[switchCaseRanges.count - switchCase.offset - 1].first?.isLinebreak == true

                    if newComments.last?.isLinebreak == oldComments.last?.isLinebreak {
                        formatter.replaceTokens(in: switchCaseRanges[switchCase.offset].afterDelimiterRange, with: newComments)
                    } else if newComments.count > 1,
                              newComments.last?.isLinebreak == true, oldComments.last?.isLinebreak == false
                    {
                        // indent the new content
                        newComments.append(.space(String(repeating: " ", count: maxIndentCount)))
                        formatter.replaceTokens(in: switchCaseRanges[switchCase.offset].afterDelimiterRange, with: newComments)
                    }

                    formatter.replaceTokens(in: switchCaseRanges[switchCase.offset].beforeDelimiterRange, with: newTokens)
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
            // TODO: need more general solution for handling other import attributes
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
                if Set(range.attributes).isSubset(of: range2.attributes) {
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
        help: "Remove whitespace inside empty braces.",
        options: ["emptybraces"],
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEach(.startOfScope("{")) { i, _ in
            guard let closingIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i, if: {
                $0 == .endOfScope("}")
            }) else {
                return
            }
            if let token = formatter.next(.nonSpaceOrComment, after: closingIndex),
               [.keyword("else"), .keyword("catch")].contains(token)
            {
                return
            }
            let range = i + 1 ..< closingIndex
            switch formatter.options.emptyBracesSpacing {
            case .noSpace:
                formatter.removeTokens(in: range)
            case .spaced:
                formatter.replaceTokens(in: range, with: .space(" "))
            case .linebreak:
                formatter.insertSpace(formatter.indentForLine(at: i), at: range.endIndex)
                formatter.replaceTokens(in: range, with: formatter.linebreakToken(for: i + 1))
            }
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
            if formatter.options.swiftVersion < "5.3", formatter.isInResultBuilder(at: i) {
                return
            }
            var index = i + 1
            var chevronIndex: Int?
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
                    if let chevronIndex = chevronIndex,
                       formatter.index(of: .operator(">", .infix), in: index ..< endIndex) != nil
                    {
                        // Check if this would cause ambiguity for chevrons
                        var tokens = Array(formatter.tokens[i ... endIndex])
                        tokens[index - i] = .delimiter(",")
                        tokens.append(.endOfScope("}"))
                        let reparsed = tokenize(sourceCode(for: tokens))
                        if reparsed[chevronIndex - i] == .startOfScope("<") {
                            return
                        }
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
                case .operator("<", .infix):
                    chevronIndex = index
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
                case .keyword("class"), .keyword("actor"), .keyword("enum"),
                     // Not actually allowed currently, but: future-proofing!
                     .keyword("protocol"), .keyword("struct"):
                    return
                case .keyword("private"), .keyword("fileprivate"):
                    if formatter.next(.nonSpaceOrComment, after: nextIndex) == .startOfScope("(") {
                        break
                    }
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
            case .keyword("class"), .keyword("actor"):
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
            let dotIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: endIndex, if: {
                $0.isOperator(".")
            })
            if let dotIndex = dotIndex, formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: dotIndex, if: {
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
            if let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: typeIndex) {
                switch prevToken {
                case .keyword("struct"), .keyword("class"), .keyword("actor"),
                     .keyword("enum"), .keyword("protocol"), .keyword("typealias"):
                    return
                default:
                    break
                }
            }
            switch formatter.tokens[typeIndex] {
            case .identifier("Array"):
                formatter.replaceTokens(in: typeIndex ... endIndex, with:
                    [.startOfScope("[")] + formatter.tokens[typeStart ... typeEnd] + [.endOfScope("]")])
            case .identifier("Dictionary"):
                guard let commaIndex = formatter.index(of: .delimiter(","), in: typeStart ..< typeEnd) else {
                    return
                }
                formatter.replaceToken(at: commaIndex, with: .delimiter(":"))
                formatter.replaceTokens(in: typeIndex ... endIndex, with:
                    [.startOfScope("[")] + formatter.tokens[typeStart ... typeEnd] + [.endOfScope("]")])
            case .identifier("Optional"):
                if formatter.options.shortOptionals == .exceptProperties,
                   let lastKeyword = formatter.lastSignificantKeyword(at: i),
                   ["var", "let"].contains(lastKeyword)
                {
                    return
                }
                if formatter.lastSignificantKeyword(at: i) == "case" ||
                    formatter.last(.endOfScope, before: i) == .endOfScope("case")
                {
                    // https://bugs.swift.org/browse/SR-13838
                    return
                }
                var typeTokens = formatter.tokens[typeStart ... typeEnd]
                if formatter.index(of: .operator("&", .infix), in: typeStart ..< typeEnd) != nil ||
                    formatter.index(of: .operator("->", .infix), in: typeStart ..< typeEnd) != nil
                {
                    typeTokens.insert(.startOfScope("("), at: typeTokens.startIndex)
                    typeTokens.append(.endOfScope(")"))
                }
                typeTokens.append(.operator("?", .postfix))
                formatter.replaceTokens(in: typeIndex ... endIndex, with: typeTokens)
            default:
                return
            }
            // Drop leading Swift. namespace
            if let dotIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: typeIndex, if: {
                $0.isOperator(".")
            }), let swiftTokenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: dotIndex, if: {
                $0 == .identifier("Swift")
            }) {
                formatter.removeTokens(in: swiftTokenIndex ..< typeIndex)
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
                case .keyword("struct"), .keyword("extension"), .keyword("enum"), .keyword("actor"),
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
                      ["class", "actor", "struct", "enum", "extension"].contains($0.string)
                  }), let nameIndex = formatter.index(of: .identifier, in: typeIndex ..< scopeIndex),
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
                  let opIndex = ["==", "!=", "<", "<=", ">", ">="].firstIndex(of: op),
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
            // Ignore sequential attributes
            guard let endIndex = formatter.endOfAttribute(at: i),
                  var keywordIndex = formatter.index(
                      of: .nonSpaceOrCommentOrLinebreak,
                      after: endIndex, if: { $0.isKeyword || $0.isModifierKeyword }
                  ),
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
            case "class", "actor", "struct", "enum", "protocol", "extension":
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
                    formatter.insertSpace(formatter.indentForLine(at: i), at: nextIndex)
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
                  var prevIndex = formatter.index(of: .nonSpaceOrLinebreak, before: i)
            else {
                return
            }
            var prevToken = formatter.tokens[prevIndex]
            var label: String?
            if prevToken == .delimiter(":"),
               let labelIndex = formatter.index(of: .nonSpace, before: prevIndex),
               case let .identifier(name) = formatter.tokens[labelIndex],
               let prevIndex2 = formatter.index(of: .nonSpaceOrLinebreak, before: labelIndex)
            {
                label = name
                prevToken = formatter.tokens[prevIndex2]
                prevIndex = prevIndex2
            }
            let parenthesized = prevToken == .startOfScope("(")
            if parenthesized {
                prevToken = formatter.last(.nonSpaceOrLinebreak, before: prevIndex) ?? prevToken
            }
            guard case let .identifier(name) = prevToken,
                  ["map", "flatMap", "compactMap", "allSatisfy", "filter", "contains"].contains(name),
                  let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i, if: {
                      $0 == .identifier("$0")
                  }),
                  let endIndex = formatter.endOfScope(at: i),
                  let lastIndex = formatter.index(of: .nonSpaceOrLinebreak, before: endIndex)
            else {
                return
            }
            if let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: endIndex),
               formatter.isLabel(at: nextIndex)
            {
                return
            }
            if name == "contains" {
                if label != "where" {
                    return
                }
            } else if label != nil {
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
            if let label = label {
                replacementTokens = [.identifier(label), .delimiter(":"), .space(" ")] + replacementTokens
            }
            if !parenthesized {
                replacementTokens = [.startOfScope("(")] + replacementTokens + [.endOfScope(")")]
            }
            formatter.replaceTokens(in: prevIndex + 1 ... endIndex, with: replacementTokens)
        }
    }

    public let organizeDeclarations = FormatRule(
        help: "Organizes declarations within class, struct, enum, actor, and extension bodies.",
        runOnceOnly: true,
        disabledByDefault: true,
        orderAfter: ["extensionAccessControl", "redundantFileprivate"],
        options: ["categorymark", "markcategories", "beforemarks", "lifecycle", "organizetypes",
                  "structthreshold", "classthreshold", "enumthreshold", "extensionlength"],
        sharedOptions: ["lineaftermarks"]
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
                   let delimiterIndex = declaration.openTokens.firstIndex(of: .delimiter(":")),
                   declaration.openTokens.firstIndex(of: .keyword("where")).map({ $0 > delimiterIndex }) ?? true
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
        options: ["marktypes", "typemark", "markextensions", "extensionmark", "groupedextension"],
        sharedOptions: ["lineaftermarks"]
    ) { formatter in
        var declarations = formatter.parseDeclarations()

        // Do nothing if there is only one top-level declaration in the file (excluding imports)
        let declarationsWithoutImports = declarations.filter { $0.keyword != "import" }
        guard declarationsWithoutImports.count > 1 else {
            return
        }

        for (index, declaration) in declarations.enumerated() {
            guard case let .type(kind, open, body, close) = declaration else { continue }

            guard var typeName = declaration.name else {
                continue
            }

            let markMode: MarkMode
            let commentTemplate: String
            let isGroupedExtension: Bool
            switch declaration.keyword {
            case "extension":
                // TODO: this should be stored in declaration at parse time
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
                    $0.name == typeName && $0.definesType
                }) {
                    let declarationsBetweenTypeAndExtension = declarations[indexOfExtendingType + 1 ..< index]
                    isGroupedWithExtendingType = declarationsBetweenTypeAndExtension.allSatisfy {
                        // Only treat the type and its extension as grouped if there aren't any other
                        // types or type-like declarations between them
                        if ["class", "actor", "enum", "protocol", "struct", "typealias"].contains($0.keyword) {
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
                    isGroupedExtension = true
                } else {
                    commentTemplate = "// \(formatter.options.extensionMarkComment)"
                    isGroupedExtension = false
                }
            default:
                markMode = formatter.options.markTypes
                commentTemplate = "// \(formatter.options.typeMarkComment)"
                isGroupedExtension = false
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

                // If this declaration is extension, check if it has any conformances
                var conformanceNames: String?
                if
                    declaration.keyword == "extension",
                    var conformanceSearchIndex = openingFormatter.index(of: .delimiter(":"), after: keywordIndex)
                {
                    var conformances = [String]()

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

                    if !conformances.isEmpty {
                        conformanceNames = conformances.joined(separator: ", ")
                    }
                }

                // Build the types expected mark comment by replacing `%t`s with the type name
                // and `%c`s with the list of conformances added in the extension (if applicable)
                var markForType: String?

                if !commentTemplate.contains("%c") {
                    markForType = commentTemplate.replacingOccurrences(of: "%t", with: typeName)
                } else if commentTemplate.contains("%c"), let conformanceNames = conformanceNames {
                    markForType = commentTemplate
                        .replacingOccurrences(of: "%t", with: typeName)
                        .replacingOccurrences(of: "%c", with: conformanceNames)
                }

                // If this is an extension without any conformances, but contains exactly
                // one body declaration (a type), we can mark the extension with the nested type's name
                // (e.g. `// MARK: Foo.Bar`).
                if
                    declaration.keyword == "extension",
                    conformanceNames == nil
                {
                    // Find all of the nested extensions, so we can form the fully qualified
                    // name of the inner-most type (e.g. `Foo.Bar.Baaz.Quux`).
                    var extensions = [declaration]

                    while
                        let innerExtension = extensions.last,
                        let extensionBody = innerExtension.body,
                        extensionBody.count == 1,
                        extensionBody[0].keyword == "extension"
                    {
                        extensions.append(extensionBody[0])
                    }

                    let innermostExtension = extensions.last!
                    let extensionNames = extensions.compactMap { $0.name }.joined(separator: ".")

                    if let extensionBody = innermostExtension.body,
                       extensionBody.count == 1,
                       let nestedType = extensionBody.first,
                       nestedType.definesType,
                       let nestedTypeName = nestedType.name
                    {
                        let fullyQualifiedName = "\(extensionNames).\(nestedTypeName)"

                        if isGroupedExtension {
                            markForType = "// \(formatter.options.groupedExtensionMarkComment)"
                                .replacingOccurrences(of: "%c", with: fullyQualifiedName)
                        } else {
                            markForType = "// \(formatter.options.typeMarkComment)"
                                .replacingOccurrences(of: "%t", with: fullyQualifiedName)
                        }
                    }
                }

                guard let expectedComment = markForType else {
                    return openingFormatter.tokens
                }

                // Remove any lines that have the same prefix as the comment template
                //  - We can't really do exact matches here like we do for `organizeDeclaration`
                //    category separators, because there's a much wider variety of options
                //    that a user could use the the type name (orphaned renames, etc.)
                var commentPrefixes = Set(["// MARK: ", "// MARK: - "])

                if let typeNameSymbolIndex = commentTemplate.firstIndex(of: "%") {
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
                let endMarkDeclaration = formatter.options.lineAfterMarks ? "\n\n" : "\n"
                openingFormatter.insert(tokenize("\(expectedComment)\(endMarkDeclaration)"), at: markInsertIndex)

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

    public let sortDeclarations = FormatRule(
        help: """
        Sorts the body of declarations with // swiftformat:sort
        and declarations between // swiftformat:sort:begin and
        // swiftformat:sort:end comments.
        """
    ) { formatter in
        formatter.forEachToken(
            where: { $0.isComment && $0.string.contains("swiftformat:sort") }
        ) { commentIndex, commentToken in

            let rangeToSort: ClosedRange<Int>
            let numberOfLeadingLinebreaks: Int

            // For `:sort:begin`, directives, we sort the declarations
            // between the `:begin` and and `:end` comments
            if commentToken.string.contains("swiftformat:sort:begin") {
                guard
                    let endCommentIndex = formatter.tokens[commentIndex...].firstIndex(where: {
                        $0.isComment && $0.string.contains("swiftformat:sort:end")
                    }),
                    let sortRangeStart = formatter.index(of: .nonSpaceOrComment, after: commentIndex),
                    let firstRangeToken = formatter.index(of: .nonLinebreak, after: sortRangeStart),
                    let lastRangeToken = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: endCommentIndex - 2)
                else { return }

                rangeToSort = sortRangeStart ... lastRangeToken
                numberOfLeadingLinebreaks = firstRangeToken - sortRangeStart
            }

            // For `:sort` directives, we sort the declarations
            // between the open and close brace of the following type
            else if
                !commentToken.string.contains(":sort:"),
                // This part of the rule conflicts with the organizeDeclarations rule.
                // Instead, that rule manually implements support for the :sort directive.
                !formatter.options.enabledRules.contains(FormatRules.organizeDeclarations.name)
            {
                guard
                    let typeOpenBrace = formatter.index(of: .startOfScope("{"), after: commentIndex),
                    let typeCloseBrace = formatter.endOfScope(at: typeOpenBrace),
                    let firstTypeBodyToken = formatter.index(of: .nonLinebreak, after: typeOpenBrace),
                    let lastTypeBodyToken = formatter.index(of: .nonLinebreak, before: typeCloseBrace),
                    lastTypeBodyToken > typeOpenBrace
                else { return }

                rangeToSort = typeOpenBrace + 1 ... lastTypeBodyToken
                numberOfLeadingLinebreaks = firstTypeBodyToken - typeOpenBrace - 1
            } else {
                return
            }

            var declarations = Formatter(Array(formatter.tokens[rangeToSort]))
                .parseDeclarations()
                .enumerated()
                .sorted(by: { lhs, rhs -> Bool in
                    let (lhsIndex, lhsDeclaration) = lhs
                    let (rhsIndex, rhsDeclaration) = rhs

                    // Primarily sort by name, to alphabetize
                    if
                        let lhsName = lhsDeclaration.name,
                        let rhsName = rhsDeclaration.name,
                        lhsName != rhsName
                    {
                        return lhsName.localizedCompare(rhsName) == .orderedAscending
                    }

                    // Otherwise preserve the existing order
                    else {
                        return lhsIndex < rhsIndex
                    }

                })
                .map { $0.element }

            // Make sure there's at least one newline between each declaration
            for i in 0 ..< max(0, declarations.count - 1) {
                let declaration = declarations[i]
                let nextDeclaration = declarations[i + 1]

                if declaration.tokens.last?.isLinebreak == false,
                   nextDeclaration.tokens.first?.isLinebreak == false
                {
                    declarations[i + 1] = formatter.mapOpeningTokens(in: nextDeclaration) { openTokens in
                        let openFormatter = Formatter(openTokens)
                        openFormatter.insertLinebreak(at: 0)
                        return openFormatter.tokens
                    }
                }
            }

            var sortedFormatter = Formatter(declarations.flatMap { $0.tokens })

            // Make sure the type has the same number of leading line breaks
            // as it did before sorting
            if let currentLeadingLinebreakCount = sortedFormatter.tokens.firstIndex(where: { !$0.isLinebreak }) {
                if numberOfLeadingLinebreaks != currentLeadingLinebreakCount {
                    sortedFormatter.removeTokens(in: 0 ..< currentLeadingLinebreakCount)

                    for _ in 0 ..< numberOfLeadingLinebreaks {
                        sortedFormatter.insertLinebreak(at: 0)
                    }
                }

            } else {
                for _ in 0 ..< numberOfLeadingLinebreaks {
                    sortedFormatter.insertLinebreak(at: 0)
                }
            }

            // There are always expected to be zero trailing line breaks,
            // so we remove any trailing line breaks
            // (this is because `typeBodyRange` specifically ends before the first
            // trailing linebreak)
            while sortedFormatter.tokens.last?.isLinebreak == true {
                sortedFormatter.removeLastToken()
            }

            if Array(formatter.tokens[rangeToSort]) != sortedFormatter.tokens {
                formatter.replaceTokens(
                    in: rangeToSort,
                    with: sortedFormatter.tokens
                )
            }
        }
    }

    public let assertionFailures = FormatRule(
        help: """
        Changes all instances of assert(false, ...) to assertionFailure(...)
        and precondition(false, ...) to preconditionFailure(...).
        """
    ) { formatter in
        formatter.forEachToken { i, token in
            switch token {
            case .identifier("assert"), .identifier("precondition"):
                guard let scopeStart = formatter.index(of: .nonSpace, after: i, if: {
                    $0 == .startOfScope("(")
                }), let identifierIndex = formatter.index(of: .nonSpaceOrLinebreak, after: scopeStart, if: {
                    $0 == .identifier("false")
                }), var endIndex = formatter.index(of: .nonSpaceOrLinebreak, after: identifierIndex) else {
                    return
                }

                // if there are more arguments, replace the comma and space as well
                if formatter.tokens[endIndex] == .delimiter(",") {
                    endIndex = formatter.index(of: .nonSpace, after: endIndex) ?? endIndex
                }

                let replacements = ["assert": "assertionFailure", "precondition": "preconditionFailure"]
                formatter.replaceTokens(in: i ..< endIndex, with: [
                    .identifier(replacements[token.string]!), .startOfScope("("),
                ])
            default:
                break
            }
        }
    }

    public let acronyms = FormatRule(
        help: "Capitalizes acronyms when the first character is capitalized.",
        disabledByDefault: true,
        options: ["acronyms"]
    ) { formatter in
        formatter.forEachToken { index, token in
            guard token.is(.identifier) || token.isComment else { return }

            var updatedText = token.string

            for acronym in formatter.options.acronyms {
                let find = acronym.capitalized
                let replace = acronym.uppercased()

                for replaceCandidateRange in token.string.ranges(of: find) {
                    let acronymShouldBeCapitalized: Bool

                    if replaceCandidateRange.upperBound < token.string.indices.last! {
                        let indexAfterMatch = replaceCandidateRange.upperBound
                        let characterAfterMatch = token.string[indexAfterMatch]

                        // Only treat this as an acronym if the next character is uppercased,
                        // to prevent "Id" from matching strings like "Identifier".
                        if characterAfterMatch.isUppercase || characterAfterMatch.isWhitespace {
                            acronymShouldBeCapitalized = true
                        }

                        // But if the next character is 's', and then the character after the 's' is uppercase,
                        // allow the acronym to be capitalized (to handle the plural case, `Ids` to `IDs`)
                        else if characterAfterMatch == Character("s") {
                            if indexAfterMatch < token.string.indices.last! {
                                let characterAfterNext = token.string[token.string.index(after: indexAfterMatch)]
                                acronymShouldBeCapitalized = (characterAfterNext.isUppercase || characterAfterNext.isWhitespace)
                            } else {
                                acronymShouldBeCapitalized = true
                            }
                        } else {
                            acronymShouldBeCapitalized = false
                        }
                    } else {
                        acronymShouldBeCapitalized = true
                    }

                    if acronymShouldBeCapitalized {
                        updatedText.replaceSubrange(replaceCandidateRange, with: replace)
                    }
                }
            }

            if token.string != updatedText {
                let updatedToken: Token
                switch token {
                case .identifier:
                    updatedToken = .identifier(updatedText)
                case .commentBody:
                    updatedToken = .commentBody(updatedText)
                default:
                    return
                }

                formatter.replaceToken(at: index, with: updatedToken)
            }
        }
    }

    public let blockComments = FormatRule(
        help: "Changes block comments to single line comments.",
        disabledByDefault: true
    ) { formatter in
        formatter.forEachToken { i, token in
            switch token {
            case .startOfScope("/*"):
                guard var endIndex = formatter.endOfScope(at: i) else {
                    return formatter.fatalError("Expected */", at: i)
                }

                // We can only convert block comments to single-line comments
                // if there are no non-comment tokens on the same line.
                //  - For example, we can't convert `if foo { /* code */ }`
                //    to a line comment because it would comment out the closing brace.
                //
                // To guard against this, we verify that there is only
                // comment or whitespace tokens on the remainder of this line
                guard formatter.next(.nonSpace, after: endIndex)?.isLinebreak != false else {
                    return
                }

                var isDocComment = false
                var stripLeadingStars = true
                func replaceCommentBody(at index: Int) -> Int {
                    var delta = 0
                    var space = ""
                    if case let .space(s) = formatter.tokens[index] {
                        formatter.removeToken(at: index)
                        space = s
                        delta -= 1
                    }
                    if case let .commentBody(body)? = formatter.token(at: index) {
                        var body = Substring(body)
                        if stripLeadingStars {
                            if body.hasPrefix("*") {
                                body = body.drop(while: { $0 == "*" })
                            } else {
                                stripLeadingStars = false
                            }
                        }
                        let prefix = isDocComment ? "/" : ""
                        if !prefix.isEmpty || !body.isEmpty, !body.hasPrefix(" ") {
                            space += " "
                        }
                        formatter.replaceToken(
                            at: index,
                            with: .commentBody(prefix + space + body)
                        )
                    } else if isDocComment {
                        formatter.insert(.commentBody("/"), at: index)
                        delta += 1
                    }
                    return delta
                }

                // Replace opening delimiter
                var startIndex = i
                let indent = formatter.indentForLine(at: i)
                if case let .commentBody(body) = formatter.tokens[i + 1] {
                    isDocComment = body.hasPrefix("*")
                    let commentBody = body.drop(while: { $0 == "*" })
                    formatter.replaceToken(at: i + 1, with: .commentBody("/" + commentBody))
                }
                formatter.replaceToken(at: i, with: .startOfScope("//"))
                if let nextToken = formatter.token(at: i + 1),
                   nextToken.isSpaceOrLinebreak || nextToken.string == (isDocComment ? "/" : ""),
                   let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i + 1),
                   nextIndex > i + 2
                {
                    let range = i + 1 ..< nextIndex
                    formatter.removeTokens(in: range)
                    endIndex -= range.count
                    startIndex = i + 1
                    endIndex += replaceCommentBody(at: startIndex)
                }

                // Replace ending delimiter
                if let i = formatter.index(of: .nonSpace, before: endIndex, if: {
                    $0.isLinebreak
                }) {
                    let range = i ... endIndex
                    formatter.removeTokens(in: range)
                    endIndex -= range.count
                }

                // remove /* and */
                var index = i
                while index <= endIndex {
                    switch formatter.tokens[index] {
                    case .startOfScope("/*"):
                        formatter.removeToken(at: index)
                        endIndex -= 1
                        if formatter.tokens[index - 1].isSpace {
                            formatter.removeToken(at: index - 1)
                            index -= 1
                            endIndex -= 1
                        }
                    case .endOfScope("*/"):
                        formatter.removeToken(at: index)
                        endIndex -= 1
                        if formatter.tokens[index - 1].isSpace {
                            formatter.removeToken(at: index - 1)
                            index -= 1
                            endIndex -= 1
                        }
                    case .linebreak:
                        endIndex += formatter.insertSpace(indent, at: index + 1)
                        guard let i = formatter.index(of: .nonSpace, after: index) else {
                            index += 1
                            continue
                        }
                        index = i
                        formatter.insert(.startOfScope("//"), at: index)
                        var delta = 1 + replaceCommentBody(at: index + 1)
                        index += delta
                        endIndex += delta
                    default:
                        index += 1
                    }
                }
            default:
                break
            }
        }
    }

    public let redundantClosure = FormatRule(
        help: """
        Removes redundant closures bodies, containing a single statement,
        which are called immediately.
        """,
        disabledByDefault: false,
        orderAfter: ["redundantReturn"]
    ) { formatter in
        formatter.forEach(.startOfScope("{")) { closureStartIndex, _ in
            if formatter.isStartOfClosure(at: closureStartIndex),
               var closureEndIndex = formatter.endOfScope(at: closureStartIndex),
               // Closures that are called immediately are redundant
               // (as long as there's exactly one statement inside them)
               var closureCallOpenParenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: closureEndIndex),
               var closureCallCloseParenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: closureCallOpenParenIndex),
               formatter.token(at: closureCallOpenParenIndex) == .startOfScope("("),
               formatter.token(at: closureCallCloseParenIndex) == .endOfScope(")"),
               // Make sure to exclude closures that are completely empty,
               // because removing them could break the build.
               formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: closureStartIndex) != closureEndIndex
            {
                guard formatter.blockBodyHasSingleStatement(atStartOfScope: closureStartIndex) else {
                    return
                }

                // This rule also doesn't support closures with an `in` token.
                //  - We can't just remove this, because it could have important type information.
                //    For example, `let double = { () -> Double in 100 }()` and `let double = 100` have different types.
                //  - We could theoretically support more sophisticated checks / transforms here,
                //    but this seems like an edge case so we choose not to handle it.
                for inIndex in closureStartIndex ... closureEndIndex
                    where formatter.token(at: inIndex) == .keyword("in")
                {
                    if !formatter.indexIsWithinNestedClosure(inIndex, startOfScopeIndex: closureStartIndex) {
                        return
                    }
                }

                // If the closure calls a single function, which throws or returns `Never`,
                // then removing the closure will cause a compilation failure.
                //  - We maintain a list of known functions that return `Never`.
                //    We could expand this to be user-provided if necessary.
                for i in closureStartIndex ... closureEndIndex {
                    switch formatter.tokens[i] {
                    case .identifier("fatalError"), .identifier("preconditionFailure"), .keyword("throw"):
                        if !formatter.indexIsWithinNestedClosure(i, startOfScopeIndex: closureStartIndex) {
                            return
                        }
                    default:
                        break
                    }
                }

                // If the closure is a property with an explicit `Void` type,
                // we can't remove the closure since the build would break
                // if the method is `@discardableResult`
                // https://github.com/nicklockwood/SwiftFormat/issues/1236
                if let equalsIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: closureStartIndex),
                   formatter.token(at: equalsIndex) == .operator("=", .infix),
                   let colonIndex = formatter.index(of: .delimiter(":"), before: equalsIndex),
                   let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: colonIndex),
                   formatter.endOfVoidType(at: nextIndex) != nil
                {
                    return
                }

                // First we remove the spaces and linebreaks between the { } and the remainder of the closure body
                //  - This requires a bit of bookkeeping, but makes sure we don't remove any
                //    whitespace characters outside of the closure itself
                while formatter.token(at: closureStartIndex + 1)?.isSpaceOrLinebreak == true {
                    formatter.removeToken(at: closureStartIndex + 1)

                    closureCallOpenParenIndex -= 1
                    closureCallCloseParenIndex -= 1
                    closureEndIndex -= 1
                }

                while formatter.token(at: closureEndIndex - 1)?.isSpaceOrLinebreak == true {
                    formatter.removeToken(at: closureEndIndex - 1)

                    closureCallOpenParenIndex -= 1
                    closureCallCloseParenIndex -= 1
                    closureEndIndex -= 1
                }

                // remove the { }() tokens
                formatter.removeToken(at: closureCallCloseParenIndex)
                formatter.removeToken(at: closureCallOpenParenIndex)
                formatter.removeToken(at: closureEndIndex)
                formatter.removeToken(at: closureStartIndex)

                // Remove the initial return token, and any trailing space, if present
                if let returnIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: closureStartIndex - 1),
                   formatter.token(at: returnIndex)?.string == "return"
                {
                    while formatter.token(at: returnIndex + 1)?.isSpaceOrLinebreak == true {
                        formatter.removeToken(at: returnIndex + 1)
                    }

                    formatter.removeToken(at: returnIndex)
                }
            }
        }
    }

    public let redundantOptionalBinding = FormatRule(
        help: "Removes redundant identifiers in optional binding conditions.",
        // We can convert `if let foo = self.foo` to just `if let foo`,
        // but only if `redundantSelf` can first remove the `self.`.
        orderAfter: ["redundantSelf"]
    ) { formatter in
        formatter.forEachToken { i, token in
            // `if let foo` conditions were added in Swift 5.7 (SE-0345)
            if formatter.options.swiftVersion >= "5.7",

               [.keyword("let"), .keyword("var")].contains(token),
               formatter.isConditionalStatement(at: i),

               let identiferIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i),
               let identifier = formatter.token(at: identiferIndex),

               let equalsIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: identiferIndex, if: {
                   $0 == .operator("=", .infix)
               }),

               let nextIdentifierIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: equalsIndex, if: {
                   $0 == identifier
               }),

               let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: nextIdentifierIndex),
               [.startOfScope("{"), .delimiter(","), .keyword("else")].contains(nextToken)
            {
                formatter.removeTokens(in: identiferIndex + 1 ... nextIdentifierIndex)
            }
        }
    }

    public let opaqueGenericParameters = FormatRule(
        help: """
        Use opaque generic parameters (`some Protocol`) instead of generic parameters
        with constraints (`T where T: Protocol`, etc) where equivalent. Also supports
        primary associated types for common standard library types, so definitions like
        `T where T: Collection, T.Element == Foo` are updated to `some Collection<Foo>`.
        """,
        options: ["someAny"]
    ) { formatter in
        formatter.forEach(.keyword) { keywordIndex, keyword in
            guard
                // Apply this rule to any function-like declaration
                ["func", "init", "subscript"].contains(keyword.string),
                // Opaque generic parameter syntax is only supported in Swift 5.7+
                formatter.options.swiftVersion >= "5.7",
                // Validate that this is a generic method using angle bracket syntax,
                // and find the indices for all of the key tokens
                let paramListStartIndex = formatter.index(of: .startOfScope("("), after: keywordIndex),
                let paramListEndIndex = formatter.endOfScope(at: paramListStartIndex),
                let genericSignatureStartIndex = formatter.index(of: .startOfScope("<"), after: keywordIndex),
                let genericSignatureEndIndex = formatter.endOfScope(at: genericSignatureStartIndex),
                genericSignatureStartIndex < paramListStartIndex,
                genericSignatureEndIndex < paramListStartIndex,
                let openBraceIndex = formatter.index(of: .startOfScope("{"), after: paramListEndIndex),
                let closeBraceIndex = formatter.endOfScope(at: openBraceIndex)
            else { return }

            var genericTypes = [Formatter.GenericType]()

            // Parse the generics in the angle brackets (e.g. `<T, U: Fooable>`)
            formatter.parseGenericTypes(
                from: genericSignatureStartIndex,
                to: genericSignatureEndIndex,
                into: &genericTypes
            )

            // Parse additional conformances and constraints after the `where` keyword if present
            // (e.g. `where Foo: Fooable, Foo.Bar: Barable, Foo.Baaz == Baazable`)
            var whereTokenIndex: Int?
            if let whereIndex = formatter.index(of: .keyword("where"), after: paramListEndIndex),
               whereIndex < openBraceIndex
            {
                whereTokenIndex = whereIndex
                formatter.parseGenericTypes(from: whereIndex, to: openBraceIndex, into: &genericTypes)
            }

            // Parse the return type if present
            var returnTypeTokens: [Token]?
            if let returnIndex = formatter.index(of: .operator("->", .infix), after: paramListEndIndex),
               returnIndex < openBraceIndex, returnIndex < whereTokenIndex ?? openBraceIndex
            {
                let returnTypeRange = (returnIndex + 1) ..< (whereTokenIndex ?? openBraceIndex)
                returnTypeTokens = Array(formatter.tokens[returnTypeRange])
            }

            let genericParameterListRange = (genericSignatureStartIndex + 1) ..< genericSignatureEndIndex
            let genericParameterListTokens = formatter.tokens[genericParameterListRange]

            let parameterListRange = (paramListStartIndex + 1) ..< paramListEndIndex
            let parameterListTokens = formatter.tokens[parameterListRange]

            let bodyRange = (openBraceIndex + 1) ..< closeBraceIndex
            let bodyTokens = formatter.tokens[bodyRange]

            for genericType in genericTypes {
                // If the generic type doesn't occur in the generic parameter list (<...>),
                // then we inherited it from the generic context and can't replace the type
                // with an opaque parameter.
                if !genericParameterListTokens.contains(where: { $0.string == genericType.name }) {
                    genericType.eligibleToRemove = false
                    continue
                }

                // If the generic type occurs multiple times in the parameter list,
                // it isn't eligible to be removed. For example `(T, T) where T: Foo`
                // requires the two params to be the same underlying type, but
                // `(some Foo, some Foo)` does not.
                let countInParameterList = parameterListTokens.filter { $0.string == genericType.name }.count
                if countInParameterList > 1 {
                    genericType.eligibleToRemove = false
                    continue
                }

                // If the generic type occurs in the body of the function, then it can't be removed
                if bodyTokens.contains(where: { $0.string == genericType.name }) {
                    genericType.eligibleToRemove = false
                    continue
                }

                // If the generic type is used in a constraint of any other generic type, then the type
                // can't be removed without breaking that other type
                let otherGenericTypes = genericTypes.filter { $0.name != genericType.name }
                let otherTypeConformances = otherGenericTypes.flatMap { $0.conformances }
                for otherTypeConformance in otherTypeConformances {
                    let conformanceTokens = formatter.tokens[otherTypeConformance.sourceRange]
                    if conformanceTokens.contains(where: { $0.string == genericType.name }) {
                        genericType.eligibleToRemove = false
                    }
                }

                // In some weird cases you can also have a generic constraint that references a generic
                // type from the parent context with the same name. We can't change these, since it
                // can cause the build to break
                for conformance in genericType.conformances {
                    if tokenize(conformance.name).contains(where: { $0.string == genericType.name }) {
                        genericType.eligibleToRemove = false
                    }
                }

                // A generic used as a return type is different from an opaque result type (SE-244).
                // For example in `-> T where T: Fooable`, the generic type is caller-specified,
                // but with `-> some Fooable` the generic type is specified by the function implementation.
                // Because those represent different concepts, we can't convert between them,
                // so have to mark the generic type as ineligible if it appears in the return type.
                if let returnTypeTokens = returnTypeTokens,
                   returnTypeTokens.contains(where: { $0.string == genericType.name })
                {
                    genericType.eligibleToRemove = false
                    continue
                }

                // If the method that generates the opaque parameter syntax doesn't succeed,
                // then this type is ineligible (because it used a generic constraint that
                // can't be represented using this syntax).
                // TODO: this option probably needs to be captured earlier to support comment directives
                if genericType.asOpaqueParameter(useSomeAny: formatter.options.useSomeAny) == nil {
                    genericType.eligibleToRemove = false
                    continue
                }

                // If the generic type is used as a closure type parameter, it can't be removed or the compiler
                // will emit a "'some' cannot appear in parameter position in parameter type <closure type>" error
                for tokenIndex in keywordIndex ... closeBraceIndex {
                    // Check if this is the start of a closure
                    if formatter.tokens[tokenIndex] == .startOfScope("("),
                       tokenIndex != paramListStartIndex,
                       let endOfScope = formatter.endOfScope(at: tokenIndex),
                       let tokenAfterParen = formatter.next(.nonSpaceOrCommentOrLinebreak, after: endOfScope),
                       [.operator("->", .infix), .keyword("throws"), .identifier("async")].contains(tokenAfterParen),
                       // Check if the closure type parameters contains this generic type
                       formatter.tokens[tokenIndex ... endOfScope].contains(where: { $0.string == genericType.name })
                    {
                        genericType.eligibleToRemove = false
                    }
                }

                // Extract the comma-separated list of function parameters,
                // so we can check conditions on the individual parameters
                let parameterListTokenIndices = (paramListStartIndex + 1) ..< paramListEndIndex

                // Split the parameter list at each comma that's directly within the paren list scope
                let parameters = parameterListTokenIndices
                    .split(whereSeparator: { index in
                        let token = formatter.tokens[index]
                        return token == .delimiter(",")
                            && formatter.endOfScope(at: index) == paramListEndIndex
                    })
                    .map { parameterIndices in
                        parameterIndices.map { index in
                            formatter.tokens[index]
                        }
                    }

                for parameterTokens in parameters {
                    // Variadic parameters don't support opaque generic syntax, so we have to check
                    // if any use cases of this type in the parameter list are variadic
                    if parameterTokens.contains(.operator("...", .postfix)),
                       parameterTokens.contains(.identifier(genericType.name))
                    {
                        genericType.eligibleToRemove = false
                    }
                }
            }

            let genericsEligibleToRemove = genericTypes.filter { $0.eligibleToRemove }
            let sourceRangesToRemove = Set(genericsEligibleToRemove.flatMap { type in
                [type.definitionSourceRange] + type.conformances.map { $0.sourceRange }
            })

            // We perform modifications to the function signature in reverse order
            // so we don't invalidate any of the indices we've recorded. So first
            // we remove components of the where clause.
            if let whereIndex = formatter.index(of: .keyword("where"), after: paramListEndIndex),
               whereIndex < openBraceIndex
            {
                let whereClauseSourceRanges = sourceRangesToRemove.filter { $0.lowerBound > whereIndex }
                formatter.removeTokens(in: Array(whereClauseSourceRanges))

                if let newOpenBraceIndex = formatter.index(of: .startOfScope("{"), after: whereIndex) {
                    // if where clause is completely empty, we need to remove the where token as well
                    if formatter.index(of: .nonSpaceOrLinebreak, after: whereIndex) == newOpenBraceIndex {
                        formatter.removeTokens(in: whereIndex ..< newOpenBraceIndex)
                    }
                    // remove trailing comma
                    else if let commaIndex = formatter.index(
                        of: .nonSpaceOrCommentOrLinebreak,
                        before: newOpenBraceIndex, if: { $0 == .delimiter(",") }
                    ) {
                        formatter.removeToken(at: commaIndex)
                        if formatter.tokens[commaIndex - 1].isSpace,
                           formatter.tokens[commaIndex].isSpaceOrLinebreak
                        {
                            formatter.removeToken(at: commaIndex - 1)
                        }
                    }
                }
            }

            // Replace all of the uses of generic types that are eligible to remove
            // with the corresponding opaque parameter declaration
            for index in parameterListRange.reversed() {
                if
                    let matchingGenericType = genericsEligibleToRemove.first(where: { $0.name == formatter.tokens[index].string }),
                    var opaqueParameter = matchingGenericType.asOpaqueParameter(useSomeAny: formatter.options.useSomeAny)
                {
                    // If this instance of the type is followed by a `.` or `?` then we have to wrap the new type in parens
                    // (e.g. changing `Foo.Type` to `some Any.Type` breaks the build, it needs to be `(some Any).Type`)
                    if let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: index),
                       [.operator(".", .infix), .operator("?", .postfix)].contains(nextToken)
                    {
                        opaqueParameter.insert(.startOfScope("("), at: 0)
                        opaqueParameter.append(.endOfScope(")"))
                    }

                    formatter.replaceToken(at: index, with: opaqueParameter)
                }
            }

            // Remove types from the generic parameter list
            let genericParameterListSourceRanges = sourceRangesToRemove.filter { $0.lowerBound < genericSignatureEndIndex }
            formatter.removeTokens(in: Array(genericParameterListSourceRanges))

            // If we left a dangling comma at the end of the generic parameter list, we need to clean it up
            if let newGenericSignatureEndIndex = formatter.endOfScope(at: genericSignatureStartIndex),
               let trailingCommaIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: newGenericSignatureEndIndex),
               formatter.tokens[trailingCommaIndex] == .delimiter(",")
            {
                formatter.removeTokens(in: trailingCommaIndex ..< newGenericSignatureEndIndex)
            }

            // If we removed all of the generic types, we also have to remove the angle brackets
            if let newGenericSignatureEndIndex = formatter.index(of: .nonSpaceOrLinebreak, after: genericSignatureStartIndex),
               formatter.token(at: newGenericSignatureEndIndex) == .endOfScope(">")
            {
                formatter.removeTokens(in: genericSignatureStartIndex ... newGenericSignatureEndIndex)
            }
        }
    }

    public let genericExtensions = FormatRule(
        help: """
        When extending generic types, use angle brackets (`extension Array<Foo>`)
        instead of generic type constraints (`extension Array where Element == Foo`).
        """,
        options: ["generictypes"]
    ) { formatter in
        formatter.forEach(.keyword("extension")) { extensionIndex, _ in
            guard
                // Angle brackets syntax in extensions is only supported in Swift 5.7+
                formatter.options.swiftVersion >= "5.7",
                let typeNameIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: extensionIndex),
                let extendedType = formatter.token(at: typeNameIndex)?.string,
                // If there's already an open angle bracket after the generic type name
                // then the extension is already using the target syntax, so there's
                // no work to do
                formatter.next(.nonSpaceOrCommentOrLinebreak, after: typeNameIndex) != .startOfScope("<"),
                let openBraceIndex = formatter.index(of: .startOfScope("{"), after: typeNameIndex),
                let whereIndex = formatter.index(of: .keyword("where"), after: typeNameIndex),
                whereIndex < openBraceIndex
            else { return }

            // Prepopulate a `Self` generic type, which is implicitly present in extension definitions
            let selfType = Formatter.GenericType(
                name: "Self",
                definitionSourceRange: typeNameIndex ... typeNameIndex,
                conformances: [
                    Formatter.GenericType.GenericConformance(
                        name: extendedType,
                        typeName: "Self",
                        type: .concreteType,
                        sourceRange: typeNameIndex ... typeNameIndex
                    ),
                ]
            )

            var genericTypes = [selfType]

            // Parse the generic constraints in the where clause
            formatter.parseGenericTypes(
                from: whereIndex,
                to: openBraceIndex,
                into: &genericTypes,
                qualifyGenericTypeName: { genericTypeName in
                    // In an extension all types implicitly refer to `Self`.
                    // For example, `Element == Foo` is actually fully-qualified as
                    // `Self.Element == Foo`. Using the fully-qualified `Self.Element` name
                    // here makes it so the generic constraint is populated as a child
                    // of `selfType`.
                    if !genericTypeName.hasPrefix("Self.") {
                        return "Self." + genericTypeName
                    } else {
                        return genericTypeName
                    }
                }
            )

            var knownGenericTypes: [(name: String, genericTypes: [String])] = [
                (name: "Collection", genericTypes: ["Element"]),
                (name: "Sequence", genericTypes: ["Element"]),
                (name: "Array", genericTypes: ["Element"]),
                (name: "Set", genericTypes: ["Element"]),
                (name: "Dictionary", genericTypes: ["Key", "Value"]),
                (name: "Optional", genericTypes: ["Wrapped"]),
            ]

            // Users can provide additional generic types via the `generictypes` option
            for userProvidedType in formatter.options.genericTypes.components(separatedBy: ";") {
                guard let openAngleBracket = userProvidedType.firstIndex(of: "<"),
                      let closeAngleBracket = userProvidedType.firstIndex(of: ">")
                else { continue }

                let typeName = String(userProvidedType[..<openAngleBracket])
                let genericParameters = String(userProvidedType[userProvidedType.index(after: openAngleBracket) ..< closeAngleBracket])
                    .components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

                knownGenericTypes.append((
                    name: typeName,
                    genericTypes: genericParameters
                ))
            }

            guard let requiredGenericTypes = knownGenericTypes.first(where: { $0.name == extendedType })?.genericTypes else {
                return
            }

            // Verify that a concrete type was provided for each of the generic subtypes
            // of the type being extended
            let providedGenericTypes = requiredGenericTypes.compactMap { requiredTypeName in
                selfType.conformances.first(where: { conformance in
                    conformance.type == .concreteType && conformance.typeName == "Self.\(requiredTypeName)"
                })
            }

            guard providedGenericTypes.count == requiredGenericTypes.count else {
                return
            }

            // Remove the now-unnecessary generic constraints from the where clause
            let sourceRangesToRemove = providedGenericTypes.map { $0.sourceRange }
            formatter.removeTokens(in: sourceRangesToRemove)

            // if the where clause is completely empty now, we need to the where token as well
            if let newOpenBraceIndex = formatter.index(of: .nonSpaceOrLinebreak, after: whereIndex),
               formatter.token(at: newOpenBraceIndex) == .startOfScope("{")
            {
                formatter.removeTokens(in: whereIndex ..< newOpenBraceIndex)
            }

            // Replace the extension typename with the fully-qualified generic angle bracket syntax
            let genericSubtypes = providedGenericTypes.map { $0.name }.joined(separator: ", ")
            let fullGenericType = "\(extendedType)<\(genericSubtypes)>"
            formatter.replaceToken(at: typeNameIndex, with: tokenize(fullGenericType))
        }
    }

    public let docComments = FormatRule(
        help: "Use doc comments for comments preceding declarations.",
        disabledByDefault: true,
        orderAfter: ["fileHeader"]
    ) { formatter in
        formatter.forEach(.startOfScope) { index, token in
            guard
                ["//", "/*"].contains(token.string),
                let endOfComment = formatter.endOfScope(at: index)
            else { return }

            let shouldBeDocComment: Bool = {
                guard let nextDeclarationIndex = formatter.index(
                    after: endOfComment,
                    where: { token in
                        // Check if this token defines a declaration that supports doc comments
                        token.isDeclarationTypeKeyword(excluding: ["import"])
                    }
                ) else { return false }

                // Only use doc comments on declarations in type bodies, or top-level declarations
                if let startOfEnclosingScope = formatter.index(of: .startOfScope("{"), before: index) {
                    guard let scopeKeyword = formatter.lastSignificantKeyword(at: startOfEnclosingScope, excluding: ["where"]) else {
                        return false
                    }

                    if !["class", "struct", "enum", "actor", "protocol", "extension"].contains(scopeKeyword) {
                        return false
                    }
                }

                // If there aren't any blank lines between the comment and declaration,
                // this comment is associated with that declaration
                let trailingTokens = formatter.tokens[(endOfComment - 1) ... nextDeclarationIndex]
                let lines = trailingTokens.split(omittingEmptySubsequences: false, whereSeparator: \.isLinebreak)
                let blankLineBeforeDeclaration = lines.contains(where: { line in
                    line.isEmpty || line.allSatisfy(\.isSpace)
                })

                if blankLineBeforeDeclaration {
                    return false
                }

                // Check if this is a special type of comment that isn't documentation
                if
                    let commentBodyIndex = formatter.index(after: index, where: { token in
                        if case .commentBody = token { return true }
                        else { return false }
                    }),
                    commentBodyIndex < endOfComment,
                    let commentBodyToken = formatter.token(at: commentBodyIndex)
                {
                    let commentBody = commentBodyToken.string.trimmingCharacters(in: .whitespaces)

                    // Don't modify directive comments like `// MARK: Section title`
                    // or `// swiftformat:disable rule`, since those tools expect
                    // regular comments and not doc comments.
                    for knownTag in ["mark", "swiftformat", "sourcery", "swiftlint"]
                        where commentBody.lowercased().hasPrefix(knownTag + ":")
                    {
                        return false
                    }
                }

                // Only comments at the start of a line can be doc comments
                if let previousToken = formatter.index(of: .nonSpaceOrLinebreak, before: index) {
                    let commentLine = formatter.startOfLine(at: index)
                    let previousTokenLine = formatter.startOfLine(at: previousToken)

                    if commentLine == previousTokenLine {
                        return false
                    }
                }

                return true
            }()

            // Doc comment tokens like `///` and `/**` aren't parsed as a
            // single `.startOfScope` token -- they're parsed as:
            // `.startOfScope("//"), .commentBody("/ ...")` or
            // `.startOfScope("/*"), .commentBody("* ...")`
            let startOfDocCommentBody: String
            switch token.string {
            case "//":
                startOfDocCommentBody = "/"
            case "/*":
                startOfDocCommentBody = "*"
            default:
                return
            }

            if
                let commentBody = formatter.token(at: index + 1),
                case .commentBody = commentBody
            {
                if shouldBeDocComment, !commentBody.string.hasPrefix(startOfDocCommentBody) {
                    let updatedCommentBody = "\(startOfDocCommentBody)\(commentBody.string)"
                    formatter.replaceToken(at: index + 1, with: .commentBody(updatedCommentBody))
                } else if !shouldBeDocComment, commentBody.string.hasPrefix(startOfDocCommentBody) {
                    let prefix = commentBody.string.prefix(while: { String($0) == startOfDocCommentBody })

                    // Do nothing if this is a unusual comment like `//////////////////`
                    // or `/****************`. We can't just remove one of the tokens, because
                    // that would make this rule have a different output each time, but we
                    // shouldn't remove all of them since that would be unexpected.
                    if prefix.count > 1 {
                        return
                    }

                    formatter.replaceToken(
                        at: index + 1,
                        with: .commentBody(String(commentBody.string.dropFirst()))
                    )
                }

            } else if shouldBeDocComment {
                formatter.insert(.commentBody(startOfDocCommentBody), at: index + 1)
            }
        }
    }

    public let conditionalAssignment = FormatRule(
        help: "Assign properties using if / switch expressions."
    ) { formatter in
        // If / switch expressions were added in Swift 5.8 (SE-0380)
        guard formatter.options.swiftVersion >= "5.8" else {
            return
        }

        formatter.forEach(.keyword) { introducerIndex, introducerToken in
            // Look for declarations of the pattern:
            //
            // let foo: Foo
            // if/switch...
            //
            guard
                ["let", "var"].contains(introducerToken.string),
                let identifierIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: introducerIndex),
                let identifier = formatter.token(at: identifierIndex),
                identifier.isIdentifier,
                let colonIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: identifierIndex),
                formatter.tokens[colonIndex] == .delimiter(":"),
                let startOfTypeIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: colonIndex)
            else { return }

            let (typeName, typeRange) = formatter.parseType(at: startOfTypeIndex)

            guard let startOfConditional = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: typeRange.upperBound),
                  let conditionalBranches = formatter.conditionalBranches(at: startOfConditional)
            else { return }

            /// Whether or not the conditional statement that starts at the given index
            /// has branches that are exhaustive
            func conditionalBranchesAreExhaustive(
                conditionKeywordIndex: Int,
                branches: [Formatter.ConditionalBranch]
            )
                -> Bool
            {
                // Switch statements are compiler-guaranteed to be exhaustive
                if formatter.tokens[conditionKeywordIndex] == .keyword("switch") {
                    return true
                }

                // If statements are only exhaustive if the last branch
                // is `else` (not `else if`).
                else if formatter.tokens[conditionKeywordIndex] == .keyword("if"),
                        let lastCondition = branches.last,
                        let tokenBeforeLastCondition = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: lastCondition.startOfBranch)
                {
                    return formatter.tokens[tokenBeforeLastCondition] == .keyword("else")
                }

                return false
            }

            // Whether or not the given conditional branch body qualifies as a single statement
            // that assigns a value to `identifier`. This is either:
            //  1. a single assignment to `identifier =`
            //  2. a single `if` or `switch` statement where each of the branches also qualify,
            //     and the statement is exhaustive.
            func isExhaustiveSingleStatementAssignment(_ branch: Formatter.ConditionalBranch) -> Bool {
                guard let firstTokenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: branch.startOfBranch) else { return false }

                // If this is an if/switch statement, verify that all of the branches are also
                // single-statement assignments and that the statement is exhaustive.
                if let conditionalBranches = formatter.conditionalBranches(at: firstTokenIndex),
                   let lastConditionalStatement = conditionalBranches.last
                {
                    let allBranchesAreExhaustiveSingleStatement = conditionalBranches.allSatisfy { branch in
                        isExhaustiveSingleStatementAssignment(branch)
                    }

                    let isOnlyStatementInScope = formatter.next(.nonSpaceOrCommentOrLinebreak, after: lastConditionalStatement.endOfBranch)?.isEndOfScope == true

                    let isExhaustive = conditionalBranchesAreExhaustive(
                        conditionKeywordIndex: firstTokenIndex,
                        branches: conditionalBranches
                    )

                    return allBranchesAreExhaustiveSingleStatement
                        && isOnlyStatementInScope
                        && isExhaustive
                }

                // Otherwise we expect this to be of the pattern `identifier = (statement)`
                else if formatter.tokens[firstTokenIndex] == identifier,
                        let equalsIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: firstTokenIndex),
                        formatter.tokens[equalsIndex] == .operator("=", .infix),
                        let valueStartIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: equalsIndex)
                {
                    // We know this branch starts with `identifier =`, but have to check that the
                    // remaining code in the branch is a single statement. To do that we can
                    // create a temporary formatter with the branch body _excluding_ `identifier =`.
                    let assignmentStatementRange = valueStartIndex ..< branch.endOfBranch
                    var tempScopeTokens = [Token]()
                    tempScopeTokens.append(.startOfScope("{"))
                    tempScopeTokens.append(contentsOf: formatter.tokens[assignmentStatementRange])
                    tempScopeTokens.append(.endOfScope("}"))

                    let tempFormatter = Formatter(tempScopeTokens, options: formatter.options)
                    return tempFormatter.blockBodyHasSingleStatement(atStartOfScope: 0)
                }

                return false
            }

            guard conditionalBranches.allSatisfy(isExhaustiveSingleStatementAssignment),
                  conditionalBranchesAreExhaustive(conditionKeywordIndex: startOfConditional, branches: conditionalBranches)
            else {
                return
            }

            // Remove the `identifier =` from each conditional branch,
            formatter.forEachRecursiveConditionalBranch(in: conditionalBranches) { branch in
                guard
                    let firstTokenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: branch.startOfBranch),
                    let equalsIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: firstTokenIndex),
                    formatter.tokens[equalsIndex] == .operator("=", .infix),
                    let valueStartIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: equalsIndex)
                else { return }

                formatter.removeTokens(in: firstTokenIndex ..< valueStartIndex)
            }

            // Lastly we have to insert an `=` between the type and the conditional
            let rangeBetweenTypeAndConditional = (typeRange.upperBound + 1) ..< startOfConditional

            // If there are no comments between the type and conditional,
            // we reformat it from:
            //
            // let foo: Foo\n
            // if condition {
            //
            // to:
            //
            // let foo: Foo = if condition {
            //
            if formatter.tokens[rangeBetweenTypeAndConditional].allSatisfy(\.isSpaceOrLinebreak) {
                formatter.replaceTokens(in: rangeBetweenTypeAndConditional, with: [
                    .space(" "),
                    .operator("=", .infix),
                    .space(" "),
                ])
            }

            // But if there are comments, then we shouldn't just delete them.
            // Instead we just insert `= ` after the type.
            else {
                formatter.insert([.operator("=", .infix), .space(" ")], at: startOfConditional)
            }
        }
    }
}
