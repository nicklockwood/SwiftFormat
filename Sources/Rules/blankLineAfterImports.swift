//
//  blankLineAfterImports.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

public extension FormatRule {
    /// Insert blank line after import statements
    static let blankLineAfterImports = FormatRule(
        help: """
        Insert blank line after import statements.
        """,
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEach(.keyword("import")) { currentImportIndex, _ in
            guard let endOfLine = formatter.index(of: .linebreak, after: currentImportIndex),
                  var nextIndex = formatter.index(of: .nonSpace, after: endOfLine)
            else {
                return
            }
            var keyword: Token = formatter.tokens[nextIndex]
            while keyword == .startOfScope("#if") || keyword.isModifierKeyword || keyword.isAttribute,
                  let index = formatter.index(of: .keyword, after: nextIndex)
            {
                nextIndex = index
                keyword = formatter.tokens[nextIndex]
            }
            switch formatter.tokens[nextIndex] {
            case .linebreak, .keyword("import"), .keyword("#else"), .keyword("#elseif"), .endOfScope("#endif"):
                break
            default:
                formatter.insertLinebreak(at: endOfLine)
            }
        }
    }
}
