//
//  TrailingClosures.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 1/17/17.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Convert closure arguments to trailing closure syntax where possible
    static let trailingClosures = FormatRule(
        help: "Use trailing closure syntax where applicable.",
        options: ["trailing-closures", "never-trailing"]
    ) { formatter in
        let useTrailing = Set([
            "async", "asyncAfter", "sync", "autoreleasepool",
        ] + formatter.options.trailingClosures)

        let nonTrailing = Set([
            "performBatchUpdates",
            "expect", // Special case to support autoclosure arguments in the Nimble framework
        ] + formatter.options.neverTrailing)

        formatter.forEach(.startOfScope("(")) { i, _ in
            guard let identifierIndex = formatter.parseFunctionIdentifier(beforeStartOfScope: i) else { return }
            let name = formatter.tokens[identifierIndex].string

            guard !nonTrailing.contains(name), !formatter.isConditionalStatement(at: i) else {
                return
            }

            // Parse all arguments to detect multiple trailing closures
            let arguments = formatter.parseFunctionCallArguments(startOfScope: i)
            let closures = arguments.filter { arg in
                let range = arg.valueRange
                guard let first = formatter.index(of: .nonSpaceOrCommentOrLinebreak, in: range.lowerBound ..< range.upperBound + 1),
                      let last = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: range.upperBound + 1, if: { _ in true }),
                      formatter.tokens[first] == .startOfScope("{"),
                      formatter.tokens[last] == .endOfScope("}"),
                      formatter.index(of: .endOfScope("}"), after: first) == last
                else {
                    return false
                }
                return true
            }

            // Determine if we should apply trailing closure transformation
            let shouldTransform: Bool
            if closures.count > 1 {
                // Multiple closures: first must be unlabeled, subsequent must be labeled
                shouldTransform = closures[0].label == nil && closures.dropFirst().allSatisfy { $0.label != nil }
            } else if closures.count == 1 {
                // Single closure: check if it should be made trailing
                let closure = closures[0]
                if closure.label == nil {
                    // Unlabeled single closure
                    shouldTransform = true
                } else {
                    // Labeled single closure: only if function is in useTrailing list
                    shouldTransform = useTrailing.contains(name)
                }
            } else {
                shouldTransform = false
            }

            guard shouldTransform else { return }
            guard let closingIndex = formatter.index(of: .endOfScope(")"), after: i) else { return }
            guard formatter.next(.nonSpaceOrCommentOrLinebreak, after: closingIndex) != .startOfScope("{") else { return }

            // Handle a single trailing closure
            if closures.count == 1 {
                let closure = closures[0]
                let range = closure.valueRange
                guard let closingBraceIndex = formatter.index(of: .nonSpaceOrComment, before: closingIndex, if: { $0 == .endOfScope("}") }),
                      let openingBraceIndex = formatter.index(of: .startOfScope("{"), before: closingBraceIndex),
                      formatter.index(of: .endOfScope("}"), before: openingBraceIndex) == nil,
                      var startIndex = formatter.index(of: .nonSpaceOrLinebreak, before: openingBraceIndex)
                else { return }

                switch formatter.tokens[startIndex] {
                case .delimiter(","), .startOfScope("("):
                    break
                case .delimiter(":"):
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
                return
            }

            // Handle multiple trailing closures
            var transformations: [(range: Range<Int>, tokens: [Token])] = []
            transformations.append((range: closingIndex ..< closingIndex + 1, tokens: []))

            for (index, closure) in closures.enumerated() {
                let range = closure.valueRange
                guard range.lowerBound < formatter.tokens.count,
                      range.upperBound < formatter.tokens.count,
                      let openBrace = formatter.index(of: .nonSpaceOrCommentOrLinebreak, in: range.lowerBound ..< range.upperBound + 1),
                      openBrace < formatter.tokens.count,
                      formatter.tokens[openBrace] == .startOfScope("{"),
                      let beforeBrace = formatter.index(of: .nonSpaceOrLinebreak, before: openBrace),
                      beforeBrace < formatter.tokens.count else { continue }

                if closure.label == nil {
                    // First (unlabeled) closure
                    if formatter.tokens[beforeBrace] == .delimiter(",") {
                        let existingTokens = Array(formatter.tokens[(beforeBrace + 1) ..< openBrace])
                        let hasLineBreak = existingTokens.contains { $0.isLinebreak }

                        if hasLineBreak {
                            transformations.append((range: beforeBrace ..< openBrace, tokens: [
                                .linebreak("\n", 0), .endOfScope(")"), .space(" "),
                            ]))
                        } else {
                            transformations.append((range: beforeBrace ..< openBrace, tokens: [
                                .endOfScope(")"), .space(" "),
                            ]))
                        }
                    } else if formatter.tokens[beforeBrace] == .startOfScope("(") {
                        transformations.append((range: beforeBrace ..< openBrace, tokens: [.space(" ")]))
                    }
                } else {
                    // Labeled closure
                    if let labelIndex = closure.labelIndex,
                       let commaIndex = formatter.index(of: .delimiter(","), before: labelIndex),
                       commaIndex < formatter.tokens.count
                    {
                        let hasLineBreakAfterComma = formatter.tokens[(commaIndex + 1) ..< labelIndex].contains { $0.isLinebreak }

                        if hasLineBreakAfterComma {
                            transformations.append((range: commaIndex ..< commaIndex + 1, tokens: []))
                        } else {
                            let nextTokenIndex = commaIndex + 1
                            if nextTokenIndex < labelIndex, formatter.tokens[nextTokenIndex].isSpace {
                                transformations.append((range: commaIndex ..< commaIndex + 1, tokens: []))
                            } else {
                                transformations.append((range: commaIndex ..< commaIndex + 1, tokens: [.space(" ")]))
                            }
                        }
                    }
                }

                // Remove trailing comma after last closure
                if index == closures.count - 1 {
                    if let closingBrace = formatter.index(of: .endOfScope("}"), after: range.upperBound - 1),
                       let commaAfter = formatter.index(of: .delimiter(","), after: closingBrace),
                       commaAfter < closingIndex
                    {
                        transformations.append((range: commaAfter ..< commaAfter + 1, tokens: []))
                    }
                }
            }

            // Apply transformations from right to left
            for transformation in transformations.sorted(by: { $0.range.lowerBound > $1.range.lowerBound }) {
                formatter.replaceTokens(in: transformation.range, with: transformation.tokens)
            }
        }
    } examples: {
        """
        ```diff
        - DispatchQueue.main.async(execute: { ... })
        + DispatchQueue.main.async {
        ```

        ```diff
        - let foo = bar.map({ ... }).joined()
        + let foo = bar.map { ... }.joined()
        ```

        ```diff
        - withAnimation(.spring, {
        -   isVisible = true
        - }, completion: {
        -   handleCompletion()
        - })
        + withAnimation(.spring) {
        +   isVisible = true
        + } completion: {
        +   handleCompletion()
        + }
        ```
        """
    }
}
