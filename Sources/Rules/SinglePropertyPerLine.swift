//
//  SinglePropertyPerLine.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 6/27/25.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Separate multiple property declarations on the same line into separate lines
    static let singlePropertyPerLine = FormatRule(
        help: "Place each property declaration on its own line.",
        disabledByDefault: true,
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEachToken { i, token in
            guard ["let", "var"].contains(token.string) else { return }

            // Skip if this is part of a guard, if, or while statement
            if formatter.isConditionalStatement(at: i) {
                return
            }

            // If this property is within a parenthesis scope, this is probably
            // within a switch case like `case (let foo, bar):`
            if let startOfScope = formatter.startOfScope(at: i),
               formatter.tokens[startOfScope] == .startOfScope("(")
            {
                return
            }

            guard let multiplePropertyDecl = formatter.parseMultiplePropertyDeclaration(at: i) else { return }

            // Check if we need to redistribute type/default value from the final property to all properties
            var sharedTypeTokens: [Token]?
            let lastProperty = multiplePropertyDecl.properties.last!
            let propertiesBeforeLast = multiplePropertyDecl.properties.dropLast()

            // If ONLY the final property has a type or default value, redistribute it to all properties
            let onlyLastPropertyHasTypeOrDefault = propertiesBeforeLast.allSatisfy { $0.typeRange == nil && $0.valueRange == nil }
                && (lastProperty.typeRange != nil || lastProperty.valueRange != nil)

            if onlyLastPropertyHasTypeOrDefault, let lastPropertyType = lastProperty.typeRange {
                // Extract the type tokens to redistribute
                sharedTypeTokens = Array(formatter.tokens[lastPropertyType])

                // Remove the type annotation from the final property (it will be re-added to all properties)
                let colonIndex = formatter.index(of: .delimiter(":"), before: lastPropertyType.lowerBound)!
                formatter.removeTokens(in: colonIndex ... lastPropertyType.upperBound)
            }

            // Process commas from right to left
            for property in multiplePropertyDecl.properties.reversed() {
                guard let commaIndex = property.trailingCommaIndex else { continue }

                // Replace comma with newline + indentation + declaration
                formatter.replaceToken(at: commaIndex, with: .linebreak(formatter.options.linebreak, 1))

                let indent = formatter.currentIndentForLine(at: i)
                if !indent.isEmpty {
                    formatter.insert(.space(indent), at: commaIndex + 1)
                }

                // Insert modifiers and keyword
                let startOfModifiers = formatter.startOfModifiers(at: i, includingAttributes: true)
                let insertPoint = commaIndex + (indent.isEmpty ? 1 : 2)

                for j in startOfModifiers ... i {
                    formatter.insert(formatter.tokens[j], at: insertPoint + (j - startOfModifiers))
                }
            }

            // Add shared type to all properties
            if let sharedTypeTokens {
                // Find all property identifiers that need the shared type
                // Search in reverse order to avoid index invalidation
                let propertyNames = multiplePropertyDecl.properties.map(\.identifier).reversed()

                for propertyName in propertyNames {
                    // Find this property identifier after the current position
                    var searchIndex = i
                    while searchIndex < formatter.tokens.count {
                        if formatter.tokens[searchIndex].isIdentifier,
                           formatter.tokens[searchIndex].string == propertyName
                        {
                            // Check if this identifier already has a type
                            if let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: searchIndex),
                               formatter.tokens[nextIndex] == .delimiter(":")
                            {
                                // Already has type, skip to next occurrence
                                searchIndex += 1
                                continue
                            }

                            // Add type annotation
                            formatter.insert(.delimiter(":"), at: searchIndex + 1)
                            formatter.insert(.space(" "), at: searchIndex + 2)
                            for (offset, token) in sharedTypeTokens.enumerated() {
                                formatter.insert(token, at: searchIndex + 3 + offset)
                            }
                            break
                        }
                        searchIndex += 1
                    }
                }
            }
        }
    } examples: {
        """
        ```diff
        - let a: Int, b: Int
        + let a: Int
        + let b: Int
        ```

        ```diff
        - public var c = 10, d = false, e = "string"
        + public var c = 10
        + public var d = false
        + public var e = "string"
        ```

        ```diff
        - @objc var f = true, g: Bool
        + @objc var f = true
        + @objc var g: Bool
        ```
        """
    }
}

extension Formatter {
    /// A let/var declaration that defines multiple properties
    struct MultiplePropertyDeclaration {
        struct Property {
            let identifier: String
            let identifierIndex: Int
            let typeRange: ClosedRange<Int>?
            let valueRange: ClosedRange<Int>?
            let trailingCommaIndex: Int?
        }

        let introducerIndex: Int
        let properties: [Property]
    }

    /// Parses a property declaration that contains multiple properties, like:
    /// ```
    /// let foo, bar: Bool
    /// let foo = false, bar = 21
    /// let foo: Foo, bar: Bar, baaz = baaz, quux: Quux
    /// ```
    func parseMultiplePropertyDeclaration(at introducerIndex: Int) -> MultiplePropertyDeclaration? {
        guard ["let", "var"].contains(tokens[introducerIndex].string) else { return nil }

        var properties = [MultiplePropertyDeclaration.Property]()
        guard var searchIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: introducerIndex) else {
            return nil
        }

        while tokens[searchIndex].isIdentifier {
            let propertyIdentifierIndex = searchIndex
            var typeInformation: (colonIndex: Int, name: String, range: ClosedRange<Int>)?

            if let colonIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: propertyIdentifierIndex),
               tokens[colonIndex] == .delimiter(":"),
               let startOfTypeIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: colonIndex),
               let type = parseType(at: startOfTypeIndex)
            {
                typeInformation = (
                    colonIndex: colonIndex,
                    name: type.name,
                    range: type.range
                )
            }

            let endOfTypeOrIdentifier = typeInformation?.range.upperBound ?? propertyIdentifierIndex
            var valueInformation: (assignmentIndex: Int, expressionRange: ClosedRange<Int>)?

            if let assignmentIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: endOfTypeOrIdentifier),
               tokens[assignmentIndex] == .operator("=", .infix),
               let startOfExpression = index(of: .nonSpaceOrCommentOrLinebreak, after: assignmentIndex),
               let expressionRange = parseExpressionRange(startingAt: startOfExpression, allowConditionalExpressions: true)
            {
                valueInformation = (
                    assignmentIndex: assignmentIndex,
                    expressionRange: expressionRange
                )
            }

            var trailingCommaIndex: Int?
            let lastTokenInProperty = valueInformation?.expressionRange.last ?? typeInformation?.range.last ?? propertyIdentifierIndex
            if let nextToken = index(of: .nonSpaceOrCommentOrLinebreak, after: lastTokenInProperty),
               tokens[nextToken] == .delimiter(",")
            {
                trailingCommaIndex = nextToken
            }

            properties.append(MultiplePropertyDeclaration.Property(
                identifier: tokens[propertyIdentifierIndex].string,
                identifierIndex: propertyIdentifierIndex,
                typeRange: typeInformation?.range,
                valueRange: valueInformation?.expressionRange,
                trailingCommaIndex: trailingCommaIndex
            ))

            guard let trailingCommaIndex, let followingIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: trailingCommaIndex) else {
                break
            }

            searchIndex = followingIndex
        }

        // Only return if we found multiple properties
        guard properties.count > 1 else { return nil }

        return MultiplePropertyDeclaration(
            introducerIndex: introducerIndex,
            properties: properties
        )
    }
}
