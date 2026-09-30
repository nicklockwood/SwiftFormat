//
//  WrapSingleLineStrings.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 9/30/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Convert single-line string literals that exceed the configured maximum width to multiline strings.
    static let wrapSingleLineStrings = FormatRule(
        help: "Wrap single-line string literals that exceed the specified `--max-width`.",
        disabledByDefault: true,
        orderAfter: [.indent],
        sharedOptions: ["max-width", "indent", "indent-strings", "tab-width", "linebreaks", "asset-literals"]
    ) { formatter in
        guard formatter.options.maxWidth > 0 else {
            return
        }

        formatter.forEach(.startOfScope) { startIndex, token in
            guard token.isStringDelimiter, !token.isMultilineStringDelimiter else {
                return
            }
            formatter.wrapSingleLineString(at: startIndex)
        }
    } examples: {
        #"""
        `--max-width 40 --indent-strings enabled`

        ```diff
        - let message = "This is a long string that exceeds the maximum width"
        + let message = """
        +     This is a long string that exceeds \
        +     the maximum width
        +     """
        ```
        """#
    }
}

extension Formatter {
    /// Converts an over-width single-line string literal to a wrapped multiline string.
    func wrapSingleLineString(at startIndex: Int) {
        let openingDelimiter = tokens[startIndex].string
        guard !openingDelimiter.contains("/"),
              let quoteIndex = openingDelimiter.firstIndex(of: "\""),
              let endIndex = endOfScope(at: startIndex),
              !isInStringInterpolation(at: startIndex),
              lineLength(at: startIndex) > options.maxWidth
        else {
            return
        }

        let literalContents = (startIndex + 1) ..< endIndex
        guard !literalContents.contains(where: { tokens[$0].isLinebreak }) else {
            return
        }

        let source = sourceCode(for: Array(tokens[literalContents]))
        var breakpoints: [Int] = []
        var nextBodyIndex = index(in: literalContents, where: \.isStringBody)
        while let bodyIndex = nextBodyIndex {
            if case let .stringBody(body) = tokens[bodyIndex], startOfScope(at: bodyIndex) == startIndex {
                let offset = tokens[(startIndex + 1) ..< bodyIndex].reduce(0) { $0 + $1.string.count }
                for (characterOffset, character) in body.enumerated() {
                    if character == " " || character == "\t" {
                        breakpoints.append(offset + characterOffset + 1)
                    }
                }
            }
            nextBodyIndex = bodyIndex + 1 < endIndex ?
                index(in: (bodyIndex + 1) ..< endIndex, where: \.isStringBody) : nil
        }

        let hashes = String(openingDelimiter[..<quoteIndex])
        let continuation = "\\" + hashes
        let stringIndent = currentIndentForLine(at: startIndex) + (options.indentStrings ? options.indent : "")
        let indentWidth = Token.space(stringIndent).columnWidth(tabWidth: options.tabWidth)
        let continuedLineWidth = options.maxWidth - indentWidth - continuation.count
        let finalLineWidth = options.maxWidth - indentWidth
        guard continuedLineWidth > 0, finalLineWidth > 0 else {
            return
        }

        func width(of characters: ArraySlice<Character>) -> Int {
            Token.stringBody(String(characters)).columnWidth(tabWidth: options.tabWidth)
        }

        var characters = Array(source)
        var lines: [String] = []
        while width(of: characters[...]) > finalLineWidth {
            let breakpoint = breakpoints.last(where: {
                $0 < characters.count && width(of: characters[..<$0]) <= continuedLineWidth
            }) ?? breakpoints.first(where: { $0 < characters.count })
            guard let breakpoint else {
                return
            }

            lines.append(String(characters[..<breakpoint]))
            characters.removeFirst(breakpoint)
            breakpoints = breakpoints.compactMap { point in
                let point = point - breakpoint
                return point > 0 ? point : nil
            }
        }
        lines.append(String(characters))
        guard lines.count > 1 else {
            return
        }

        let linebreak = linebreakToken(for: startIndex).string
        var replacement = hashes + "\"\"\"" + linebreak
        for (lineIndex, line) in lines.enumerated() {
            let isContinuation = lineIndex < lines.count - 1
            replacement += stringIndent + line + (isContinuation ? continuation : "") + linebreak
        }
        replacement += stringIndent + "\"\"\"" + hashes
        replaceTokens(in: startIndex ... endIndex, with: tokenize(replacement))
    }
}
