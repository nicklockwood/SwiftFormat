//
//  UnusedArguments.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Replace unused arguments with an underscore
    static let unusedArguments = FormatRule(
        help: "Mark unused function arguments with `_`.",
        options: ["stripunusedargs"]
    ) { formatter in
        guard !formatter.options.fragment else { return }

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
            formatter.removeUsed(from: &argNames, with: &nameIndexPairs, in: i + 1 ..< bodyEndIndex)
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
            formatter.removeUsed(from: &argNames, with: &nameIndexPairs, in: bodyStartIndex + 1 ..< bodyEndIndex)
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
}

extension Formatter {
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
            if isStartOfStatement(at: i, treatingCollectionKeysAsStart: false),
               // Immediately following an `=` operator, if or switch keywords
               // are expressions rather than statements.
               lastToken(before: i, where: { !$0.isSpaceOrCommentOrLinebreak })?.isOperator("=") != true
            {
                pushLocals()
                wasDeclaration = false
            }
            let token = tokens[i]
            outer: switch token {
            case .keyword("guard"):
                isGuard = true
            case .keyword("let"), .keyword("var"), .keyword("func"), .keyword("for"):
                isDeclaration = true
                var i = i
                while let scopeStart = index(of: .startOfScope("("), before: i) {
                    i = scopeStart
                }
                isConditional = isConditionalStatement(at: i)
            case .identifier:
                let name = token.unescaped()
                guard let index = argNames.firstIndex(of: name), !locals.contains(name) else {
                    break
                }
                if last(.nonSpaceOrCommentOrLinebreak, before: i)?.isOperator(".") == false,
                   next(.nonSpaceOrCommentOrLinebreak, after: i) != .delimiter(":") ||
                   [.startOfScope("("), .startOfScope("[")].contains(currentScope(at: i) ?? .space(""))
                {
                    if isDeclaration {
                        switch next(.nonSpaceOrCommentOrLinebreak, after: i) {
                        case .endOfScope(")")?, .operator("=", .infix)?,
                             .delimiter(",")? where !isConditional:
                            tempLocals.insert(name)
                            break outer
                        default:
                            break
                        }
                    }
                    argNames.remove(at: index)
                    associatedData.remove(at: index)
                    if argNames.isEmpty {
                        return
                    }
                }
            case .startOfScope("{"):
                guard let endIndex = endOfScope(at: i) else {
                    return fatalError("Expected }", at: i)
                }
                if isStartOfClosure(at: i) {
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
                guard let colonIndex = index(of: .startOfScope(":"), after: i) else {
                    return fatalError("Expected :", at: i)
                }
                guard let endIndex = endOfScope(at: colonIndex) else {
                    return fatalError("Expected end of case statement",
                                      at: colonIndex)
                }
                removeUsed(from: &argNames, with: &associatedData,
                           locals: locals, in: i + 1 ..< endIndex)
                i = endIndex - 1
            case .operator("=", .infix), .delimiter(":"), .startOfScope(":"),
                 .keyword("in"), .keyword("where"):
                wasDeclaration = isDeclaration
                isDeclaration = false
            case .delimiter(","):
                if let scope = currentScope(at: i), [
                    .startOfScope("("), .startOfScope("["), .startOfScope("<"),
                ].contains(scope) {
                    break
                }
                if isConditional {
                    if isGuard, wasDeclaration {
                        pushLocals()
                    }
                    wasDeclaration = false
                } else {
                    let _wasDeclaration = wasDeclaration
                    pushLocals()
                    isDeclaration = _wasDeclaration
                }
            case .delimiter(";"):
                pushLocals()
                wasDeclaration = false
            default:
                break
            }
            i += 1
        }
    }
}
