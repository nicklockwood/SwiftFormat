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

        formatter.forEach(.startOfScope("(")) { functionOpenParen, _ in
            guard let identifierIndex = formatter.parseFunctionIdentifier(beforeStartOfScope: functionOpenParen) else { return }
            let name = formatter.tokens[identifierIndex].string

            guard !nonTrailing.contains(name), !formatter.isConditionalStatement(at: functionOpenParen) else {
                return
            }

            // Parse all arguments to detect multiple trailing closures
            let arguments = formatter.parseFunctionCallArguments(startOfScope: functionOpenParen)

            let trailingClosures = arguments.suffix(while: { arg in
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
            })

            // Ensure the function doesn't already have a trailing closure
            guard let functionCallClosingParen = formatter.endOfScope(at: functionOpenParen),
                  formatter.next(.nonSpaceOrCommentOrLinebreak, after: functionCallClosingParen) != .startOfScope("{")
            else { return }

            // Handle a single trailing closure
            if trailingClosures.count == 1 {
                guard trailingClosures[0].label == nil || useTrailing.contains(name) else { return }

                let closure = trailingClosures[0]
                let range = closure.valueRange
                guard let closingBraceIndex = formatter.index(of: .nonSpaceOrComment, before: functionCallClosingParen, if: { $0 == .endOfScope("}") }),
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
                    } else if formatter.index(of: .startOfScope("("), before: openingBraceIndex) == functionOpenParen {
                        startIndex = functionOpenParen
                    } else {
                        return
                    }
                default:
                    return
                }
                let wasParen = (startIndex == functionOpenParen)
                formatter.removeParen(at: functionCallClosingParen)
                formatter.replaceTokens(in: startIndex ..< openingBraceIndex, with:
                    wasParen ? [.space(" ")] : [.endOfScope(")"), .space(" ")])
                return
            }

            else if trailingClosures.count >= 2 {
                guard trailingClosures[0].label == nil,
                      trailingClosures.dropFirst().allSatisfy({ $0.label != nil })
                else { return }

                // Remove the closing paren and any trailing comma.
                // If the closing paren is on its own line, remove the whole line.
                let lineWithClosingParen = formatter.startOfLine(at: functionCallClosingParen) ... formatter.endOfLine(at: functionCallClosingParen)
                let tokenBeforeClosingParen = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: functionCallClosingParen)

                if formatter.tokens(in: lineWithClosingParen)?.string.trimmingCharacters(in: .whitespacesAndNewlines) == ")" {
                    formatter.removeTokens(in: lineWithClosingParen)
                } else {
                    formatter.removeToken(at: functionCallClosingParen)
                }

                if let tokenBeforeClosingParen, formatter.tokens[tokenBeforeClosingParen] == .delimiter(",") {
                    formatter.removeToken(at: tokenBeforeClosingParen)
                }

                // Remove the comma before each closure
                for (index, closure) in trailingClosures.enumerated().reversed() {
                    let closureRange = closure.valueRange.autoUpdating(in: formatter)
                    let closureOnOneLine = formatter.onSameLine(closureRange.lowerBound, closureRange.upperBound)

                    if index == trailingClosures.indices.first,
                       let indexBeforeFirstClosure = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: closure.valueRange.lowerBound)
                    {
                        // If all of the arguments were closures, remove the parens completely
                        if formatter.tokens[indexBeforeFirstClosure] == .startOfScope("(") {
                            formatter.removeToken(at: indexBeforeFirstClosure)
                        }

                        // Otherwise, the previous comma becomes the new closing paren
                        else if formatter.tokens[indexBeforeFirstClosure] == .delimiter(",") {
                            formatter.replaceToken(at: indexBeforeFirstClosure, with: .endOfScope(")"))
                        }

                        // Unwrap the line so the trailing closure label immediately follows the closing paren
                        if !formatter.onSameLine(indexBeforeFirstClosure, closure.valueRange.lowerBound) {
                            formatter.unwrapLine(before: closureRange.lowerBound, preservingComments: true)
                        }
                    }

                    else if let closureLabelIndex = closure.labelIndex?.autoUpdating(in: formatter),
                            let commaIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: closureLabelIndex),
                            formatter.tokens[commaIndex] == .delimiter(",")
                    {
                        let commaWasOnPreviousLine = !formatter.onSameLine(commaIndex, closureLabelIndex.index)
                        formatter.removeToken(at: commaIndex)

                        // Unwrap the line so the trailing closure label immediately follows the previous end of scope
                        if commaWasOnPreviousLine {
                            formatter.unwrapLine(before: closureLabelIndex.index, preservingComments: true)
                        }
                    }

                    // If the closure was originally written on a single line, wrap it now.
                    if closureOnOneLine {
                        formatter.wrapLine(before: closureRange.upperBound)
                        formatter.wrapLine(before: closureRange.lowerBound + 1)
                    }
                }
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

extension Collection {
    func suffix(while condition: (Element) -> Bool) -> [Element] {
        reversed().prefix(while: condition).reversed()
    }
}
