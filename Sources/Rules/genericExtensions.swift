//
//  genericExtensions.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let genericExtensions = FormatRule(
        help: """
        Use angle brackets (`extension Array<Foo>`) for generic type extensions
        instead of type constraints (`extension Array where Element == Foo`).
        """,
        options: ["generictypes"]
    ) { formatter in
        formatter.forEach(.keyword("extension")) { extensionIndex, _ in
            guard // Angle brackets syntax in extensions is only supported in Swift 5.7+
                formatter.options.swiftVersion >= "5.7",
                let typeNameIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: extensionIndex),
                let extendedType = formatter.token(at: typeNameIndex)?.string,
                // If there's already an open angle bracket after the generic type name
                // then the extension is already using the target syntax, so there's
                // no work to do
                formatter.next(.nonSpaceOrCommentOrLinebreak, after: typeNameIndex) != .startOfScope("<"),
                let openBraceIndex = formatter.index(of: .startOfScope("{"), after: typeNameIndex),
                let whereIndex = formatter.index(of: .keyword("where"), after: typeNameIndex),
                whereIndex < openBraceIndex
            else { return }

            // Prepopulate a `Self` generic type, which is implicitly present in extension definitions
            let selfType = Formatter.GenericType(
                name: "Self",
                definitionSourceRange: typeNameIndex ... typeNameIndex,
                conformances: [
                    Formatter.GenericType.GenericConformance(
                        name: extendedType,
                        typeName: "Self",
                        type: .concreteType,
                        sourceRange: typeNameIndex ... typeNameIndex
                    ),
                ]
            )

            var genericTypes = [selfType]

            // Parse the generic constraints in the where clause
            formatter.parseGenericTypes(
                from: whereIndex,
                to: openBraceIndex,
                into: &genericTypes,
                qualifyGenericTypeName: { genericTypeName in
                    // In an extension all types implicitly refer to `Self`.
                    // For example, `Element == Foo` is actually fully-qualified as
                    // `Self.Element == Foo`. Using the fully-qualified `Self.Element` name
                    // here makes it so the generic constraint is populated as a child
                    // of `selfType`.
                    if !genericTypeName.hasPrefix("Self.") {
                        return "Self." + genericTypeName
                    } else {
                        return genericTypeName
                    }
                }
            )

            var knownGenericTypes: [(name: String, genericTypes: [String])] = [
                (name: "Collection", genericTypes: ["Element"]),
                (name: "Sequence", genericTypes: ["Element"]),
                (name: "Array", genericTypes: ["Element"]),
                (name: "Set", genericTypes: ["Element"]),
                (name: "Dictionary", genericTypes: ["Key", "Value"]),
                (name: "Optional", genericTypes: ["Wrapped"]),
            ]

            // Users can provide additional generic types via the `generictypes` option
            for userProvidedType in formatter.options.genericTypes.components(separatedBy: ";") {
                guard let openAngleBracket = userProvidedType.firstIndex(of: "<"),
                      let closeAngleBracket = userProvidedType.firstIndex(of: ">")
                else { continue }

                let typeName = String(userProvidedType[..<openAngleBracket])
                let genericParameters = String(userProvidedType[userProvidedType.index(after: openAngleBracket) ..< closeAngleBracket])
                    .components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

                knownGenericTypes.append((
                    name: typeName,
                    genericTypes: genericParameters
                ))
            }

            guard let requiredGenericTypes = knownGenericTypes.first(where: { $0.name == extendedType })?.genericTypes else {
                return
            }

            // Verify that a concrete type was provided for each of the generic subtypes
            // of the type being extended
            let providedGenericTypes = requiredGenericTypes.compactMap { requiredTypeName in
                selfType.conformances.first(where: { conformance in
                    conformance.type == .concreteType && conformance.typeName == "Self.\(requiredTypeName)"
                })
            }

            guard providedGenericTypes.count == requiredGenericTypes.count else {
                return
            }

            // Remove the now-unnecessary generic constraints from the where clause
            let sourceRangesToRemove = providedGenericTypes.map { $0.sourceRange }
            formatter.removeTokens(in: sourceRangesToRemove)

            // if the where clause is completely empty now, we need to the where token as well
            if let newOpenBraceIndex = formatter.index(of: .nonSpaceOrLinebreak, after: whereIndex),
               formatter.token(at: newOpenBraceIndex) == .startOfScope("{")
            {
                formatter.removeTokens(in: whereIndex ..< newOpenBraceIndex)
            }

            // Replace the extension typename with the fully-qualified generic angle bracket syntax
            let genericSubtypes = providedGenericTypes.map { $0.name }.joined(separator: ", ")
            let fullGenericType = "\(extendedType)<\(genericSubtypes)>"
            formatter.replaceToken(at: typeNameIndex, with: tokenize(fullGenericType))
        }
    }
}
