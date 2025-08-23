//
//  RedundantNilInit.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 12/5/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove or insert  redundant `= nil` initialization for Optional properties
    static let redundantNilInit = FormatRule(
        help: "Remove/insert redundant `nil` default value (Optional vars are nil by default).",
        options: ["nil-init"]
    ) { formatter in
        let declarations = formatter.parseDeclarations()
        declarations.forEachRecursiveDeclaration { declaration in
            // Only process var declarations
            guard declaration.keyword == "var" else { return }

            let varIndex = declaration.keywordIndex

            // Check modifiers don't include `lazy` or property wrappers
            if declaration.modifiers.contains(where: {
                $0 == "lazy" || ($0 != "@objc" && $0.hasPrefix("@"))
            }) {
                return
            }

            // Preserve as-is in result builders
            if formatter.isInResultBuilder(at: varIndex) {
                return
            }

            if let parentType = declaration.parentType {
                // Check if this is in a Codable type
                if parentType.conformances.contains(where: {
                    ["Codable", "Decodable"].contains($0.conformance.string)
                }) {
                    return
                }

                // Preserve the value if the struct has a synthesized memberwise init
                // before Swift 5.2
                if parentType.keyword == "struct",
                   formatter.index(of: .keyword("init"), after: parentType.openBraceIndex) == nil,
                   formatter.options.swiftVersion < "5.2"
                {
                    return
                }
            }

            guard let propertyDeclaration = formatter.parsePropertyDeclaration(atIntroducerIndex: varIndex),
                  let type = propertyDeclaration.type,
                  type.string.hasSuffix("?") || type.string.hasSuffix("!")
            else { return }

            switch formatter.options.nilInit {
            case .remove:
                // Remove `= nil` if it exists
                if let valueInfo = propertyDeclaration.value,
                   formatter.tokens[valueInfo.expressionRange] == [.identifier("nil")]
                {
                    // Remove from the space before = to the end of the value
                    let startIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: valueInfo.assignmentIndex, if: { !$0.isSpaceOrCommentOrLinebreak }) ?? valueInfo.assignmentIndex - 1
                    formatter.removeTokens(in: startIndex + 1 ... valueInfo.expressionRange.upperBound)
                }

            case .insert:
                // Insert `= nil` if it doesn't exist and this is a stored property
                if propertyDeclaration.value == nil, declaration.isStoredProperty {
                    let tokens: [Token] = [.space(" "), .operator("=", .infix), .space(" "), .identifier("nil")]
                    formatter.insert(tokens, at: type.range.upperBound + 1)
                }
            }
        }

    } examples: {
        """
        `--nil-init remove`

        ```diff
        - var foo: Int? = nil
        + var foo: Int?
        ```

        ```diff
          // doesn't apply to `let` properties
          let foo: Int? = nil
        ```

        ```diff
          // doesn't affect non-nil initialization
          var foo: Int? = 0
        ```

        `--nil-init insert`

        ```diff
        - var foo: Int?
        + var foo: Int? = nil
        ```
        """
    }
}
