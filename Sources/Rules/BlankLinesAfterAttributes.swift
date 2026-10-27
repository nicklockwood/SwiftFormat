//
//  BlankLinesAfterAttributes.swift
//  SwiftFormat
//
//  Created by Ethan Pippin on 2026-10-26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove blank lines between an attribute and the declaration it applies to
    static let blankLinesAfterAttributes = FormatRule(
        help: "Remove blank lines between attributes and the declaration they apply to."
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
            else { return }

            formatter.removeTokens(in: linebreakIndex + 1 ... lastLinebreakIndex)
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
        """
    }
}

extension Formatter {
    /// Whether the attribute at the given index applies to a declaration
    func isDeclarationAttribute(at attributeIndex: Int) -> Bool {
        guard let keywordIndex = index(after: attributeIndex, where: \.isDeclarationTypeKeyword) else {
            return false
        }
        return startOfModifiers(at: keywordIndex, includingAttributes: true) <= attributeIndex
    }
}
