//
//  EmptyCollectionInits.swift
//  SwiftFormat
//
//  Created by Guy Kogus on 8/21/25.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Replace empty array and dictionary literals with type initializers when type is explicitly declared
    static let emptyCollectionInits = FormatRule(
        help: "Replace empty collection literals with explicit initializer syntax.",
        orderAfter: [.redundantType, .propertyTypes]
    ) { formatter in
        formatter.forEach(.startOfScope("[")) { startIndex, _ in
            // Make sure this is an empty array or dictionary literal
            guard let endIndex = formatter.endOfScope(at: startIndex) else { return }

            // Check what's inside the brackets
            let contentsRange = startIndex + 1 ..< endIndex
            let nonSpaceContents = formatter.tokens[contentsRange].filter { !$0.isSpaceOrCommentOrLinebreak }

            let isEmptyArray = nonSpaceContents.isEmpty
            let isEmptyDictionary = nonSpaceContents.count == 1 && nonSpaceContents[0] == .delimiter(":")

            guard isEmptyArray || isEmptyDictionary else { return }

            // Look backwards to find if this is part of a variable assignment with type annotation
            guard let assignmentIndex = formatter.index(of: .operator("=", .infix), before: startIndex),
                  let colonIndex = formatter.index(before: assignmentIndex, where: {
                      [.delimiter(":"), .operator("=", .infix)].contains($0)
                  }), formatter.tokens[colonIndex] == .delimiter(":"),
                  let declarationKeyword = formatter.lastSignificantKeyword(at: assignmentIndex),
                  ["var", "let"].contains(declarationKeyword)
            else { return }

            // Verify this literal is immediately after the assignment operator
            guard let valueStartIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: assignmentIndex),
                  valueStartIndex == startIndex
            else { return }

            // Get the type annotation between colon and equals
            guard let typeStartIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: colonIndex),
                  let typeEndIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: assignmentIndex)
            else { return }

            // Extract the type from the type annotation
            let typeTokens = formatter.tokens[typeStartIndex ... typeEndIndex]

            // Verify this is an array or dictionary type
            guard let firstTypeToken = typeTokens.first,
                  firstTypeToken == .startOfScope("["),
                  let lastTypeToken = typeTokens.last,
                  lastTypeToken == .endOfScope("]")
            else { return }

            // Check if type contains a colon (dictionary) or not (array)
            let typeContents = Array(typeTokens.dropFirst().dropLast())
            let typeHasColon = typeContents.contains { $0 == .delimiter(":") }

            // Verify the literal type matches the declared type
            if isEmptyArray, typeHasColon {
                return // Array literal but dictionary type
            }
            if isEmptyDictionary, !typeHasColon {
                return // Dictionary literal but array type
            }

            // Build the replacement: [Type]() or [Key: Value]()
            var replacementTokens = [Token]()
            replacementTokens.append(contentsOf: typeTokens)
            replacementTokens.append(.startOfScope("("))
            replacementTokens.append(.endOfScope(")"))

            // Replace the empty literal with type initializer
            formatter.replaceTokens(in: startIndex ... endIndex, with: replacementTokens)

            // Remove type annotation (from colon to just before equals)
            // Find the last non-space token before equals
            let lastNonSpaceBeforeEquals = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: assignmentIndex) ?? assignmentIndex - 1

            // Remove from colon through the type
            formatter.removeTokens(in: colonIndex ... lastNonSpaceBeforeEquals)
        }
    } examples: {
        """
        ```diff
        - let array: [Int] = []
        + let array = [Int]()
        ```

        ```diff
        - let dictionary: [String: Int] = [:]
        + let dictionary = [String: Int]()
        ```

        ```diff
        - var numbers: [Double] = []
        + var numbers = [Double]()
        ```
        """
    }
}
