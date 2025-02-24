//
//  WrapMultilineFunctionChains.swift
//  SwiftFormat
//
//  Created by Eric Horacek on 2/20/2025
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let wrapMultilineFunctionChains = FormatRule(
        help: "Wraps chained function calls to either all on the same line, or one per line.",
        disabledByDefault: true,
        orderAfter: [.braces, .indent],
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEach(.operator(".", .infix)) { operatorIndex, _ in
            if formatter.isInReturnType(at: operatorIndex) {
                return
            }

            var foundFunctionCall = false
            var dots: [Int] = []
            let chainStartIndex = formatter.chainStartIndex(forOperatorAtIndex: operatorIndex, foundFunctionCall: &foundFunctionCall, dots: &dots)
            dots.append(operatorIndex)
            let chainEndIndex = formatter.chainEndIndex(forOperatorAtIndex: operatorIndex, foundFunctionCall: &foundFunctionCall, dots: &dots)

            // Ensure we have at least one function call in the chain and two dots.
            guard foundFunctionCall, dots.count > 1 else {
                return
            }

            // Only wrap function chains that start on a new line from their base. If the token
            // preceding the chain’s start is on the same line, we assume this is a single line
            // chain.
            let startOfLine = formatter.startOfLine(at: chainStartIndex)
            if dots.allSatisfy({ formatter.startOfLine(at: $0) == startOfLine }) {
                return
            }

            // If a closing scope immediately precedes this operator on the same line, insert a
            // line break
            if let previousNonSpaceIndex = formatter.index(of: .nonSpaceOrComment, before: operatorIndex),
               previousNonSpaceIndex > chainStartIndex,
               case .endOfScope = formatter.token(at: previousNonSpaceIndex),
               formatter.onSameLine(previousNonSpaceIndex, operatorIndex)
            {
                formatter.insertLinebreak(at: operatorIndex)
                return
            }

            if let nextOperatorIndex = formatter.index(of: .operator(".", .infix), after: operatorIndex),
               nextOperatorIndex < chainEndIndex,
               formatter.onSameLine(operatorIndex, nextOperatorIndex)
            {
                formatter.insertLinebreak(at: nextOperatorIndex)
            }
        }
    } examples: {
        """
        ```diff
          let evenSquaresSum = [20, 17, 35, 4]
        -   .filter { $0 % 2 == 0 }.map { $0 * $0 }
            .reduce(0, +)

          let evenSquaresSum = [20, 17, 35, 4]
        +   .filter { $0 % 2 == 0 }
        +   .map { $0 * $0 }
            .reduce(0, +)
        ```
        """
    }
}

extension Formatter {
    func chainStartIndex(forOperatorAtIndex operatorIndex: Int, foundFunctionCall: inout Bool, dots: inout [Int]) -> Int {
        var chainStartIndex = operatorIndex
        var penultimateToken: Token?
        walk: while let prevIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: chainStartIndex),
                    let prevToken = token(at: prevIndex)
        {
            defer { penultimateToken = prevToken }

            switch (prevToken, penultimateToken) {
            case (.endOfScope, .identifier),
                 (.endOfScope, .number),
                 (.identifier, .number),
                 (.number, .identifier),
                 (.identifier, .identifier),
                 (.number, .number):
                break walk
            default:
                break
            }

            switch prevToken {
            case .endOfScope(")"):
                // Function call: jump to the matching opening parenthesis.
                if let openParenIndex = index(of: .startOfScope("("), before: prevIndex) {
                    chainStartIndex = openParenIndex
                    foundFunctionCall = true
                    continue
                } else {
                    break walk
                }

            case .endOfScope("]"):
                // Subscript call: jump to the matching opening bracket.
                if let openBracketIndex = index(of: .startOfScope("["), before: prevIndex) {
                    chainStartIndex = openBracketIndex
                    continue
                } else {
                    break walk
                }

            case .endOfScope("}"):
                // Trailing closure end: jump to the matching opening brace.
                if let openBraceIndex = index(of: .startOfScope("{"), before: prevIndex) {
                    chainStartIndex = openBraceIndex
                    foundFunctionCall = true
                    continue
                } else {
                    break walk
                }

            case let .operator(op, opType) where (op == "." && opType == .infix) || (op == "?" && opType == .postfix):
                // Property access or infix chaining operator.
                if op == "." {
                    dots.append(prevIndex)
                }
                chainStartIndex = prevIndex
                continue

            case .identifier, .number:
                // Identifiers and numbers may form the base of a chain.
                chainStartIndex = prevIndex
                continue

            default:
                // Any other token ends the backward walk.
                break walk
            }
        }
        return chainStartIndex
    }

    func chainEndIndex(forOperatorAtIndex operatorIndex: Int, foundFunctionCall: inout Bool, dots: inout [Int]) -> Int {
        var chainEndIndex = operatorIndex
        var previousToken: Token?
        walk: while let nextIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: chainEndIndex),
                    let nextToken = token(at: nextIndex)
        {
            defer { previousToken = nextToken }

            switch (previousToken, nextToken) {
            case (.startOfScope, .identifier),
                 (.startOfScope, .number),
                 (.identifier, .number),
                 (.number, .identifier),
                 (.identifier, .identifier),
                 (.number, .number):
                break walk
            default:
                break
            }

            switch nextToken {
            case .startOfScope("("):
                // Function call: jump to the matching closing parenthesis.
                if let closeParenIndex = index(of: .endOfScope(")"), after: nextIndex) {
                    chainEndIndex = closeParenIndex
                    foundFunctionCall = true
                    continue
                } else {
                    break walk
                }

            case .startOfScope("["):
                // Subscript call: jump to the matching closing bracket.
                if let closeBracketIndex = index(of: .endOfScope("]"), after: nextIndex) {
                    chainEndIndex = closeBracketIndex
                    continue
                } else {
                    break walk
                }

            case .startOfScope("{"):
                // Trailing closure: jump to the matching closing brace.
                if let closeBraceIndex = index(of: .endOfScope("}"), after: nextIndex) {
                    chainEndIndex = closeBraceIndex
                    foundFunctionCall = true
                    continue
                } else {
                    break walk
                }

            case let .operator(op, opType) where (op == "." && opType == .infix) || (op == "?" && opType == .postfix):
                if op == "." {
                    dots.append(nextIndex)
                }
                // Property access or infix chaining operator.
                chainEndIndex = nextIndex
                continue

            case .identifier, .number:
                // Identifiers and numbers may form the base of a chain.
                chainEndIndex = nextIndex
                continue

            default:
                // Any other token ends the forwards walk.
                break walk
            }
        }
        return chainEndIndex
    }
}
