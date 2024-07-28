//
//  blankLinesBetweenImports.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove blank lines between import statements
    static let blankLinesBetweenImports = FormatRule(
        help: """
        Remove blank lines between import statements.
        """,
        disabledByDefault: true,
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
    }
}
