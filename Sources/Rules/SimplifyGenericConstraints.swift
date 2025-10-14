//
//  SimplifyGenericConstraints.swift
//  SwiftFormat
//
//  Created by Manuel Lopez on 10/8/25.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let simplifyGenericConstraints = FormatRule(
        help: """
        Use inline generic constraints (`<T: Foo>`) instead of where clauses
        (`<T> where T: Foo`) for simple protocol conformance constraints.
        """
    ) { formatter in
        formatter.forEach(.keyword) { keywordIndex, keyword in
            // Handle function declarations
            if keyword.string == "func" {
                guard let declaration = formatter.parseFunctionDeclaration(keywordIndex: keywordIndex),
                      let genericParameterRange = declaration.genericParameterRange,
                      let whereClauseRange = declaration.whereClauseRange
                else { return }

                formatter.simplifyGenericConstraints(
                    genericStartIndex: genericParameterRange.lowerBound,
                    genericEndIndex: genericParameterRange.upperBound,
                    whereIndex: whereClauseRange.lowerBound
                )
                return
            }

            // Apply this rule to type declarations
            guard ["struct", "class", "enum", "actor"].contains(keyword.string) else { return }

            // Find the type name
            guard let typeNameIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: keywordIndex)
            else { return }

            // Check for generic parameters
            guard let genericStartIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: typeNameIndex),
                  formatter.tokens[genericStartIndex] == .startOfScope("<"),
                  let genericEndIndex = formatter.endOfScope(at: genericStartIndex)
            else { return }

            // Find the where clause
            guard let whereIndex = formatter.index(of: .keyword("where"), after: genericEndIndex),
                  let openBraceIndex = formatter.index(of: .startOfScope("{"), after: genericEndIndex),
                  whereIndex < openBraceIndex
            else { return }

            formatter.simplifyGenericConstraints(
                genericStartIndex: genericStartIndex,
                genericEndIndex: genericEndIndex,
                whereIndex: whereIndex
            )
        }
    } examples: {
        """
        ```diff
        - struct Foo<T, U> where T: Hashable, U: Codable {}
        + struct Foo<T: Hashable, U: Codable> {}

        - class Bar<Element> where Element: Equatable {
        + class Bar<Element: Equatable> {
              // ...
          }

        - enum Result<Value, Error> where Value: Decodable, Error: Swift.Error {}
        + enum Result<Value: Decodable, Error: Swift.Error> {}

        - func process<T>(_ value: T) where T: Codable {}
        + func process<T: Codable>(_ value: T) {}
        ```
        """
    }
}

extension Formatter {
    func simplifyGenericConstraints(genericStartIndex: Int, genericEndIndex _: Int, whereIndex: Int) {
        // Parse generics from angle brackets
        var genericTypes = [Formatter.GenericType]()
        parseGenericTypes(
            from: genericStartIndex,
            into: &genericTypes
        )

        // Parse generics from where clause
        parseGenericTypes(
            from: whereIndex,
            into: &genericTypes
        )

        // Find constraints that can be moved inline
        // Only simple protocol conformances (T: Protocol) can be moved
        var constraintsToMove: [(genericType: Formatter.GenericType, conformance: Formatter.GenericType.GenericConformance)] = []

        for genericType in genericTypes {
            // Check if this generic type is declared in the current function's generic parameter list
            let isGenericDeclaredInline = isGenericTypeDeclared(genericType.name, in: genericStartIndex)

            // Check each conformance to see if it can be moved
            for conformance in genericType.conformances {
                // Only move if:
                // 1. It's a protocol constraint (not a concrete type with ==)
                // 2. The constraint is in the where clause (not already inline)
                // 3. The typeName matches the generic type name exactly (no associated types like T.Element)
                // 4. The generic type is declared in this function's generic parameters (not from enclosing type)
                guard conformance.type == .protocolConstraint,
                      conformance.sourceRange.lowerBound > whereIndex,
                      conformance.typeName == genericType.name,
                      isGenericDeclaredInline
                else { continue }

                // Skip multiline protocol compositions (e.g., ProviderA & ProviderB &\nProviderC)
                // Check if there's an `&` followed by a linebreak in the conformance tokens
                var hasMultilineComposition = false
                for i in conformance.sourceRange {
                    if tokens[i] == .operator("&", .infix),
                       let nextIndex = index(of: .nonSpace, after: i),
                       tokens[nextIndex].isLinebreak
                    {
                        hasMultilineComposition = true
                        break
                    }
                }
                guard !hasMultilineComposition else { continue }

                constraintsToMove.append((genericType: genericType, conformance: conformance))
            }
        }

        guard !constraintsToMove.isEmpty else { return }

        // Group constraints by generic type
        var constraintsByType: [String: [Formatter.GenericType.GenericConformance]] = [:]
        for item in constraintsToMove {
            constraintsByType[item.genericType.name, default: []].append(item.conformance)
        }

        // We perform modifications in reverse order to avoid invalidating indices

        // First, remove constraints from the where clause
        let whereClauseIndex = whereIndex.autoUpdating(in: self)
        let sourceRangesToRemove = constraintsToMove.map(\.conformance.sourceRange)
        removeTokens(in: sourceRangesToRemove)

        // Check if the where clause is now empty and remove it if so
        // Find the next significant token after the where keyword
        if let tokenAfterWhereIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: whereClauseIndex) {
            let tokenAfterWhere = tokens[tokenAfterWhereIndex]
            if tokenAfterWhere == .startOfScope("{") {
                // Where clause followed by opening brace - remove everything between where and {
                removeTokens(in: whereClauseIndex.index ..< tokenAfterWhereIndex)
            } else if tokenAfterWhere.isLinebreak || tokenAfterWhere == .endOfScope("}") {
                // Where clause followed by linebreak or closing brace - means it's empty
                // Remove the where keyword and any whitespace/linebreaks after it
                // Also remove the space before where if present
                let startIndex = (whereClauseIndex.index > 0 && tokens[whereClauseIndex.index - 1].isSpace)
                    ? whereClauseIndex.index - 1
                    : whereClauseIndex.index

                if let linebreakIndex = index(of: .linebreak, after: whereClauseIndex) {
                    removeTokens(in: startIndex ..< linebreakIndex)
                }
            }
        } else {
            // No non-whitespace token after where at all - remove where and trailing content
            // Also remove the space before where if present
            let startIndex = (whereClauseIndex.index > 0 && tokens[whereClauseIndex.index - 1].isSpace)
                ? whereClauseIndex.index - 1
                : whereClauseIndex.index

            var endIndex = whereClauseIndex.index + 1
            while endIndex < tokens.count, !tokens[endIndex].isLinebreak {
                endIndex += 1
            }
            removeTokens(in: startIndex ..< endIndex)
        }

        // Clean up any trailing commas before the opening brace or end of declaration
        if let openBraceIndex = index(of: .startOfScope("{"), after: whereClauseIndex.index) {
            // Search backwards from the brace to find any trailing comma
            if let commaIndex = index(
                of: .nonSpaceOrCommentOrLinebreak,
                before: openBraceIndex,
                if: { $0 == .delimiter(",") }
            ) {
                removeToken(at: commaIndex)
                // Clean up extra whitespace around the removed comma
                if tokens[commaIndex - 1].isSpace,
                   tokens[commaIndex].isSpaceOrLinebreak
                {
                    removeToken(at: commaIndex - 1)
                }
            }
        }

        // Now update the generic parameter list to add constraints
        let updatedGenericStartIndex = genericStartIndex.autoUpdating(in: self)

        for (typeName, conformances) in constraintsByType {
            // Recalculate the end index after each modification
            guard let updatedGenericEndIndex = endOfScope(at: updatedGenericStartIndex.index)
            else { return }

            // Find where this generic parameter is defined in the angle brackets
            var currentIndex = updatedGenericStartIndex.index + 1

            while currentIndex < updatedGenericEndIndex {
                guard let typeIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: currentIndex - 1),
                      typeIndex < updatedGenericEndIndex
                else { break }

                if tokens[typeIndex].string == typeName {
                    // Check if this generic parameter already has inline constraints
                    let hasInlineConstraints = index(of: .nonSpaceOrCommentOrLinebreak, after: typeIndex)
                        .map { tokens[$0] == .delimiter(":") } ?? false

                    // Find the end of this generic parameter declaration
                    // It ends at a comma or the closing >
                    var endIndex = typeIndex
                    while let nextIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: endIndex),
                          nextIndex < updatedGenericEndIndex,
                          tokens[nextIndex] != .delimiter(",")
                    {
                        endIndex = nextIndex
                    }

                    // Build the constraint suffix
                    let protocolNames = conformances.map(\.name)
                    let constraintSuffix: String
                    if hasInlineConstraints {
                        // Append with & if there are already constraints
                        constraintSuffix = " & \(protocolNames.joined(separator: " & "))"
                    } else {
                        // Add with : if this is the first constraint
                        constraintSuffix = ": \(protocolNames.joined(separator: " & "))"
                    }

                    // Insert the constraint after the type parameter
                    insert(tokenize(constraintSuffix), at: endIndex + 1)
                    break
                }

                // Move to the next parameter (skip to next comma)
                if let commaIndex = index(of: .delimiter(","), after: typeIndex) {
                    currentIndex = commaIndex + 1
                } else {
                    break
                }
            }
        }
    }

    /// Checks if a generic type is declared in the generic parameter list at the given index
    func isGenericTypeDeclared(_ typeName: String, in genericStartIndex: Int) -> Bool {
        guard let genericEndIndex = endOfScope(at: genericStartIndex) else {
            return false
        }

        var currentIndex = genericStartIndex + 1
        while currentIndex < genericEndIndex {
            guard let typeIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: currentIndex - 1),
                  typeIndex < genericEndIndex
            else { break }

            if tokens[typeIndex].string == typeName {
                return true
            }

            // Move to next parameter
            if let commaIndex = index(of: .delimiter(","), after: typeIndex) {
                currentIndex = commaIndex + 1
            } else {
                break
            }
        }

        return false
    }
}
