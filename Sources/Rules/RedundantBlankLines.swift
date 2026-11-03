//
//  RedundantBlankLines.swift
//  SwiftFormat
//
//  Created by Ethan Pippin on 2026-10-26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove blank lines that separate tightly connected syntax
    static let redundantBlankLines = FormatRule(
        help: """
        Remove redundant blank lines within declaration and control-flow headers, \
        and between expression prefixes and their operands.
        """
    ) { formatter in
        formatter.forEach(.attribute) { i, _ in
            guard let endOfAttribute = formatter.endOfAttribute(at: i),
                  let linebreakIndex = formatter.index(of: .nonSpaceOrComment, after: endOfAttribute),
                  formatter.tokens[linebreakIndex].isLinebreak,
                  let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: linebreakIndex),
                  // Preserve blank lines before comments
                  !formatter.tokens[nextIndex].isComment,
                  let lastLinebreakIndex = formatter.index(of: .linebreak, before: nextIndex),
                  lastLinebreakIndex > linebreakIndex,
                  formatter.isDeclarationAttribute(at: i)
                  || formatter.isNonDeclarationAttribute(at: i, followedBy: nextIndex)
            else { return }

            formatter.removeTokens(in: linebreakIndex + 1 ... lastLinebreakIndex)
        }
        formatter.forEach(.linebreak) { i, _ in
            guard let previous = formatter.index(of: .nonSpace, before: i),
                  !formatter.tokens[previous].isLinebreak,
                  let next = formatter.index(of: .nonSpaceOrLinebreak, after: i),
                  let lastLinebreak = formatter.index(of: .linebreak, before: next),
                  lastLinebreak > i,
                  formatter.blankLineSeparatesConnectedSyntax(previous, next)
            else { return }
            formatter.removeTokens(in: i + 1 ... lastLinebreak)
        }
    } examples: {
        """
        ```diff
          @MainActor
        -
          struct Foo {
              @State
        -
              var bar = 0
          }
        ```

        ```diff
          public
        -
          final class Foo {}

          let value = try
        -
              await load()
        ```

        ```diff
          let value:
        -
              Int =
        -
              0

          func foo() -> some
        -
              View { content }
        ```

        Ordinary line wrapping is preserved. Blank lines between statements, arguments,
        collection elements, and at scope boundaries are left to other rules.
        """
    }
}

extension Formatter {
    func isNonDeclarationAttribute(at attribute: Int, followedBy next: Int) -> Bool {
        if tokens[attribute].string == "@unknown", tokens[next] == .endOfScope("default") {
            return true
        }
        if tokens[next].string.hasPrefix("#"), !["#if", "#elseif", "#else", "#endif"].contains(tokens[next].string) {
            return true
        }
        return tokens[next].isPropertyAccessorKeyword && isAccessorKeyword(
            at: startOfModifiers(at: next, includingAttributes: true), checkKeyword: false
        )
    }

    /// Whether the attribute at the given index applies to a declaration
    func isDeclarationAttribute(at attributeIndex: Int) -> Bool {
        guard let keywordIndex = index(after: attributeIndex, where: \.isDeclarationTypeKeyword) else {
            return false
        }
        return startOfModifiers(at: keywordIndex, includingAttributes: true) <= attributeIndex
    }
}
