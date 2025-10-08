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

            // Parse generics from angle brackets
            var genericTypes = [Formatter.GenericType]()
            formatter.parseGenericTypes(
                from: genericStartIndex,
                into: &genericTypes
            )

            // Parse generics from where clause
            formatter.parseGenericTypes(
                from: whereIndex,
                into: &genericTypes
            )

            // Find constraints that can be moved inline
            // Only simple protocol conformances (T: Protocol) can be moved
            var constraintsToMove: [(genericType: Formatter.GenericType, conformance: Formatter.GenericType.GenericConformance)] = []

            for genericType in genericTypes {
                // Check each conformance to see if it can be moved
                for conformance in genericType.conformances {
                    // Only move if:
                    // 1. It's a protocol constraint (not a concrete type with ==)
                    // 2. The constraint is in the where clause (not already inline)
                    // 3. The typeName matches the generic type name exactly (no associated types like T.Element)
                    guard conformance.type == .protocolConstraint,
                          conformance.sourceRange.lowerBound > whereIndex,
                          conformance.typeName == genericType.name
                    else { continue }

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
            let whereClauseIndex = whereIndex.autoUpdating(in: formatter)
            let sourceRangesToRemove = constraintsToMove.map(\.conformance.sourceRange)
            formatter.removeTokens(in: sourceRangesToRemove)

            // Check if the where clause is now empty and remove it if so
            if let tokenAfterWhere = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: whereClauseIndex),
               formatter.tokens[tokenAfterWhere] == .startOfScope("{")
            {
                formatter.removeTokens(in: whereClauseIndex.index ..< tokenAfterWhere)
            }
            // Otherwise, clean up any trailing comma
            else if let commaIndex = formatter.index(
                of: .nonSpaceOrCommentOrLinebreak,
                before: whereClauseIndex.index + 1,
                if: { $0 == .delimiter(",") }
            ) {
                formatter.removeToken(at: commaIndex)
                if formatter.tokens[commaIndex - 1].isSpace,
                   formatter.tokens[commaIndex].isSpaceOrLinebreak
                {
                    formatter.removeToken(at: commaIndex - 1)
                }
            }

            // Now update the generic parameter list to add constraints
            let updatedGenericStartIndex = genericStartIndex.autoUpdating(in: formatter)

            for (typeName, conformances) in constraintsByType {
                // Recalculate the end index after each modification
                guard let updatedGenericEndIndex = formatter.endOfScope(at: updatedGenericStartIndex.index)
                else { return }

                // Find where this generic parameter is defined in the angle brackets
                var currentIndex = updatedGenericStartIndex.index + 1

                while currentIndex < updatedGenericEndIndex {
                    guard let typeIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: currentIndex - 1),
                          typeIndex < updatedGenericEndIndex
                    else { break }

                    if formatter.tokens[typeIndex].string == typeName {
                        // Find the end of this generic parameter declaration
                        // It ends at a comma or the closing >
                        var endIndex = typeIndex
                        while let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: endIndex),
                              nextIndex < updatedGenericEndIndex,
                              formatter.tokens[nextIndex] != .delimiter(",")
                        {
                            endIndex = nextIndex
                        }

                        // Build the constraint suffix (: Protocol & OtherProtocol)
                        let protocolNames = conformances.map(\.name)
                        let constraintSuffix = ": \(protocolNames.joined(separator: " & "))"

                        // Insert the constraint after the type parameter
                        formatter.insert(tokenize(constraintSuffix), at: endIndex + 1)
                        break
                    }

                    // Move to the next parameter (skip to next comma)
                    if let commaIndex = formatter.index(of: .delimiter(","), after: typeIndex) {
                        currentIndex = commaIndex + 1
                    } else {
                        break
                    }
                }
            }
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
        ```
        """
    }
}
