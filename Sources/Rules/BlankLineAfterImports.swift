//
//  BlankLineAfterImports.swift
//  SwiftFormat
//
//  Created by Tsungyu Yu on 5/1/22.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Insert blank line after import statements
    static let blankLineAfterImports = FormatRule(
        help: "Insert blank line after import statements.",
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEach(.keyword("import")) { currentImportIndex, _ in
            guard let endOfLine = formatter.index(of: .linebreak, after: currentImportIndex),
                  var nextIndex = formatter.index(of: .nonSpace, after: endOfLine)
            else {
                return
            }
            var keyword: Token = formatter.tokens[nextIndex]
            while keyword == .startOfScope("#if") || formatter.isModifier(at: nextIndex) || keyword.isAttribute,
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
    } examples: {
        """
        ```diff
          import A
          import B
          @testable import D
        +
          class Foo {
            // foo
          }
        ```
        """
    }
}
