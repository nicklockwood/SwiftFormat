//
//  EmptyExtension.swift
//  SwiftFormat
//
//  Created by manny_lopez on 7/29/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove empty, non-conforming, extensions.
    static let emptyExtension = FormatRule(
        help: "Remove empty, non-conforming, extensions.",
        examples: """
        ```diff
        - extension String {}
        -
          extension String: Equatable {}
        ```
        """,
        orderAfter: [.unusedPrivateDeclaration]
    ) { formatter in
        var emptyExtensions = [Declaration]()

        formatter.forEachRecursiveDeclaration { declaration in
            let declarationModifiers = Set(declaration.modifiers)
            guard declaration.keyword == "extension",
                  let declarationBody = declaration.body,
                  declarationBody.isEmpty,
                  // Ensure that it is not a macro
                  !declarationModifiers.contains(where: { $0.first == "@" })
            else { return }

            // Ensure that the extension does not conform to any protocols
            let parser = Formatter(declaration.openTokens)
            guard let extensionIndex = parser.index(of: .keyword("extension"), after: -1),
                  let typeNameIndex = parser.index(of: .nonSpaceOrLinebreak, after: extensionIndex),
                  let type = parser.parseType(at: typeNameIndex),
                  let indexAfterType = parser.index(of: .nonSpaceOrCommentOrLinebreak, after: type.range.upperBound),
                  parser.tokens[indexAfterType] != .delimiter(":")
            else { return }

            emptyExtensions.append(declaration)
        }

        for declaration in emptyExtensions.reversed() {
            formatter.removeTokens(in: declaration.originalRange)
        }
    }
}
