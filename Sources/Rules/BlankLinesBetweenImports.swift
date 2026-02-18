//
//  BlankLinesBetweenImports.swift
//  SwiftFormat
//
//  Created by Huy Vo on 9/28/21.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove blank lines between import statements
    static let blankLinesBetweenImports = FormatRule(
        help: "Remove blank lines between import statements.",
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

            // Preserve indentation at the start of the next import line
            let nextLineIndent = formatter.currentIndentForLine(at: nextImportIndex)
            var replacementTokens = [formatter.linebreakToken(for: currentImportIndex + 1)]
            if !nextLineIndent.isEmpty {
                replacementTokens.append(.space(nextLineIndent))
            }
            formatter.replaceTokens(in: endOfLine ..< nextImportIndex, with: replacementTokens)
        }
    } examples: {
        """
        ```diff
          import A
        -
          import B
          import C
        -
        -
          @testable import D
          import E
        ```
        """
    }
}
