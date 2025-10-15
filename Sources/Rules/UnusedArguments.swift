//
//  UnusedArguments.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 1/3/17.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Replace unused arguments with an underscore
    static let unusedArguments = FormatRule(
        help: "Mark unused function arguments with `_`.",
        options: ["strip-unused-args"]
    ) { formatter in
        guard !formatter.options.fragment else { return }

        // Function arguments
        formatter.forEach(.keyword) { i, token in
            guard formatter.options.stripUnusedArguments != .closureOnly,
                  ["func", "init", "subscript"].contains(token.string)
            else { return }

            // In subscripts and operators, external function labels are unnecessary
            let isOperator = (token.string == "subscript") ||
                (token.string == "func" && formatter.next(.nonSpaceOrCommentOrLinebreak, after: i)?.isOperator == true)

            guard let declaration = formatter.parseFunctionDeclaration(keywordIndex: i),
                  let bodyRange = declaration.bodyRange
            else { return }

            var arguments = declaration.arguments.filter { $0.internalLabel != nil }
            var argNames = arguments.compactMap(\.internalLabel)

            formatter.removeUsed(from: &argNames, with: &arguments, in: bodyRange.lowerBound + 1 ..< bodyRange.upperBound)
            for argument in arguments.reversed() {
                // In subscripts and operators, external function labels are unnecessary
                if isOperator {
                    // Convert `_ name:` to just `_:`
                    if let externalLabelIndex = argument.externalLabelIndex, argument.externalLabel == nil {
                        formatter.removeTokens(in: (externalLabelIndex + 1) ... argument.internalLabelIndex)
                    }

                    // Convert `name:` to just `_:`
                    else {
                        formatter.replaceToken(at: argument.internalLabelIndex, with: .identifier("_"))
                    }
                }

                // When using --stripunusedargs unnamed-only, only remove the internal label
                // when the external label is already explicitly removed.
                else if formatter.options.stripUnusedArguments == .unnamedOnly {
                    // Convert `_ name:` to just `_:`
                    if let externalLabelIndex = argument.externalLabelIndex, argument.externalLabel == nil {
                        formatter.removeTokens(in: (externalLabelIndex + 1) ... argument.internalLabelIndex)
                    }
                }

                else {
                    // Convert `_ name:` to just `_:`
                    if let externalLabelIndex = argument.externalLabelIndex, argument.externalLabel == nil {
                        formatter.removeTokens(in: (externalLabelIndex + 1) ... argument.internalLabelIndex)
                    }

                    // Convert `name:` to `name _:`,
                    else if argument.externalLabelIndex == nil, !isOperator {
                        formatter.insert([.space(" "), .identifier("_")], at: argument.internalLabelIndex + 1)
                    }

                    // Convert `in name:` to `in _:`
                    else {
                        formatter.replaceToken(at: argument.internalLabelIndex, with: .identifier("_"))
                    }
                }
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
                case let .keyword(name) where !token.isAttribute && !token.isMacro && name != "inout":
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
    } examples: {
        """
        ```diff
        - func foo(bar: Int, baz: String) {
            print("Hello \\(baz)")
          }

        + func foo(bar _: Int, baz: String) {
            print("Hello \\(baz)")
          }
        ```

        ```diff
        - func foo(_ bar: Int) {
            ...
          }

        + func foo(_: Int) {
            ...
          }
        ```

        ```diff
        - request { response, data in
            self.data += data
          }

        + request { _, data in
            self.data += data
          }
        ```
        """
    }
}

extension Formatter {
    func removeUsed(from argNames: inout [String], with associatedData: inout [some Any],
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
                   next(.nonSpaceOrCommentOrLinebreak, after: i) != .delimiter(":") || startOfScope(at: i).map({
                       scopeType(at: $0) == .dictionary
                   }) ?? false
                {
                    if isDeclaration {
                        switch next(.nonSpaceOrCommentOrLinebreak, after: i) {
                        case .delimiter(",")? where !isConditional, .endOfScope(")")?, .operator("=", .infix)?:
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
            case .keyword("if"), .keyword("switch"):
                guard isConditionalAssignment(at: i),
                      let conditinalBranches = conditionalBranches(at: i),
                      let endIndex = conditinalBranches.last?.endOfBranch
                else { fallthrough }

                removeUsed(from: &argNames, with: &associatedData,
                           locals: locals, in: i + 1 ..< endIndex)
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
