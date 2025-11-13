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

            formatter.replaceTokens(in: endOfLine ..< nextImportIndex, with: formatter.linebreakToken(for: currentImportIndex + 1))
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
