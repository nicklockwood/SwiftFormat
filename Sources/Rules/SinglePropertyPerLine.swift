//
//  SinglePropertyPerLine.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 12/26/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Separate multiple property declarations on the same line into separate lines
    static let singlePropertyPerLine = FormatRule(
        help: "Place each property declaration on its own line.",
        disabledByDefault: true,
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEach(.keyword) { i, token in
            guard ["let", "var"].contains(token.string) else { return }

            // Skip if this is part of a guard, if, or while statement
            if formatter.isConditionalStatement(at: i) {
                return
            }

            // MUST USE THE PARSING HELPER
            guard let multiplePropertyDecl = formatter.parseMultiplePropertyDeclaration(at: i) else { return }

            // Find shared type using the parsed information
            var sharedTypeTokens: [Token]?
            let lastProperty = multiplePropertyDecl.properties.last!
            let afterLastProperty = lastProperty.defaultValueRange?.upperBound ?? lastProperty.type?.range.upperBound ?? lastProperty.identifierIndex

            // Look for a shared type annotation only if it's directly after the last property
            // and within the bounds of this property declaration
            let endOfThisDeclaration = formatter.endOfLine(at: i)
            if let colonIndex = formatter.index(of: .delimiter(":"), after: afterLastProperty),
               colonIndex <= endOfThisDeclaration
            {
                // Ensure there's no comma between the last property and this colon
                let hasCommaBetween = formatter.index(of: .delimiter(","), in: afterLastProperty ..< colonIndex) != nil

                // Also ensure the last property doesn't already have an individual type
                let lastPropertyHasType = lastProperty.type != nil

                // Check if the colon is directly after the last property identifier
                // AND there are properties before it that have their own types/values (making it individual, not shared)
                let colonDirectlyAfterIdentifier = (afterLastProperty == lastProperty.identifierIndex) &&
                    formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: lastProperty.identifierIndex) == colonIndex

                let propertiesBeforeLastWithTypesOrValues = multiplePropertyDecl.properties.dropLast().filter {
                    $0.type != nil || $0.defaultValueRange != nil
                }
                let hasPropertiesWithOwnDefinitions = !propertiesBeforeLastWithTypesOrValues.isEmpty

                // Check if there are any properties that would benefit from a shared type
                let propertiesNeedingType = multiplePropertyDecl.properties.filter { $0.type == nil }
                let hasPropertiesNeedingType = !propertiesNeedingType.isEmpty

                if !hasCommaBetween, !lastPropertyHasType, hasPropertiesNeedingType,
                   !(colonDirectlyAfterIdentifier && hasPropertiesWithOwnDefinitions),
                   let typeStartIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: colonIndex),
                   let typeInfo = formatter.parseType(at: typeStartIndex)
                {
                    sharedTypeTokens = Array(formatter.tokens[typeStartIndex ... typeInfo.range.upperBound])

                    // Remove ONLY the shared type annotation (colon + type), not the identifier
                    formatter.removeTokens(in: colonIndex ... typeInfo.range.upperBound)
                }
            }

            // Find and process commas from right to left
            var commaIndices: [Int] = []
            var searchIndex = i + 1

            // Find the end of the property declaration (could span multiple lines)
            var endOfDeclaration = formatter.tokens.count - 1
            if let nextDeclarationIndex = formatter.index(after: i, where: {
                $0.isDeclarationTypeKeyword || $0 == .startOfScope("#if")
            }) {
                endOfDeclaration = nextDeclarationIndex - 1
            }

            // Collect comma indices up to the end of the declaration
            while let commaIndex = formatter.index(of: .delimiter(","), after: searchIndex - 1) {
                if commaIndex > endOfDeclaration { break }

                // Skip commas inside function calls, arrays, closures, etc.
                if !formatter.isInClosureArguments(at: commaIndex),
                   !formatter.isInFunctionCall(at: commaIndex),
                   !formatter.isInArrayOrDictionary(at: commaIndex)
                {
                    commaIndices.append(commaIndex)
                }
                searchIndex = commaIndex + 1
            }

            // Process commas from right to left
            for commaIndex in commaIndices.reversed() {
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

            // Add shared type to properties that need it (must find fresh indices)
            if let sharedTypeTokens {
                // Find all property identifiers that need shared type (from right to left)
                let propertiesNeedingType = multiplePropertyDecl.properties.filter { $0.type == nil }

                for property in propertiesNeedingType.reversed() {
                    // Find the property identifier by name, not by stored index
                    var searchIndex = i + 1
                    while searchIndex < formatter.tokens.count {
                        if formatter.tokens[searchIndex].isIdentifier,
                           formatter.tokens[searchIndex].string == property.identifier
                        {
                            // Check if this identifier already has a type
                            if let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: searchIndex),
                               formatter.tokens[nextIndex] == .delimiter(":")
                            {
                                // Already has type, skip
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
            let type: (name: String, range: ClosedRange<Int>)?
            let defaultValueRange: ClosedRange<Int>?
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

        var properties: [MultiplePropertyDeclaration.Property] = []
        var searchIndex = introducerIndex + 1

        // Parse the first property
        guard let firstPropertyIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: introducerIndex),
              tokens[firstPropertyIndex].isIdentifier else { return nil }

        let firstProperty = parsePropertyAtIndex(firstPropertyIndex, searchIndex: &searchIndex)
        properties.append(firstProperty)

        // Look for commas and additional properties
        while let commaIndex = index(of: .delimiter(","), after: searchIndex - 1) {
            // Stop if we hit a line break or new declaration
            if index(of: .linebreak, in: searchIndex ..< commaIndex) != nil {
                break
            }
            if index(of: .keyword, in: searchIndex ..< commaIndex, if: {
                ["let", "var", "func", "class", "struct", "enum"].contains($0.string)
            }) != nil {
                break
            }

            // Check if this comma belongs to our property declaration
            guard !isInClosureArguments(at: commaIndex),
                  let identifierIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: commaIndex),
                  tokens[identifierIndex].isIdentifier
            else {
                searchIndex = commaIndex + 1
                break
            }

            searchIndex = commaIndex + 1
            let property = parsePropertyAtIndex(identifierIndex, searchIndex: &searchIndex)
            properties.append(property)
        }

        // Only return if we found multiple properties
        guard properties.count > 1 else { return nil }

        return MultiplePropertyDeclaration(
            introducerIndex: introducerIndex,
            properties: properties
        )
    }

    private func parsePropertyAtIndex(_ identifierIndex: Int, searchIndex: inout Int) -> MultiplePropertyDeclaration.Property {
        let identifier = tokens[identifierIndex].string
        searchIndex = identifierIndex + 1

        // Look for type annotation (only if immediately following the identifier, not preceded by a comma)
        var type: (name: String, range: ClosedRange<Int>)?

        // Check for immediate type annotation (identifier: Type)
        if let colonIndex = index(of: .delimiter(":"), after: identifierIndex),
           // No comma between identifier and colon = individual type
           index(of: .delimiter(","), in: identifierIndex ..< colonIndex) == nil,
           let startOfTypeIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: colonIndex),
           let typeInfo = parseType(at: startOfTypeIndex)
        {
            // Check if this type is followed by a comma (individual) or nothing (possibly shared)
            let nextSignificantIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: typeInfo.range.upperBound)

            // If the next significant token is a comma, this is definitely individual
            if let nextIndex = nextSignificantIndex, tokens[nextIndex] == .delimiter(",") {
                type = (name: typeInfo.name, range: typeInfo.range)
                searchIndex = typeInfo.range.upperBound + 1
            }
            // If there's no comma after this type, it might be shared - don't assign it yet
        }

        // Look for default value
        var defaultValueRange: ClosedRange<Int>?
        let searchFromIndex = type?.range.upperBound ?? identifierIndex
        if let assignmentIndex = index(of: .operator("=", .infix), after: searchFromIndex),
           // Check if there's a comma between search point and assignment - if so, skip this assignment
           index(of: .delimiter(","), in: searchFromIndex ..< assignmentIndex) == nil,
           let startOfExpression = index(of: .nonSpaceOrCommentOrLinebreak, after: assignmentIndex),
           let expressionRange = parseExpressionRange(startingAt: startOfExpression, allowConditionalExpressions: true)
        {
            defaultValueRange = assignmentIndex ... expressionRange.upperBound
            searchIndex = expressionRange.upperBound + 1
        }

        return MultiplePropertyDeclaration.Property(
            identifier: identifier,
            identifierIndex: identifierIndex,
            type: type,
            defaultValueRange: defaultValueRange
        )
    }

    /// Helper to check if a comma is inside a function call
    func isInFunctionCall(at index: Int) -> Bool {
        guard tokens[index] == .delimiter(",") else { return false }

        // Find the nearest enclosing parentheses
        var searchIndex = index
        var parenDepth = 0

        while searchIndex >= 0 {
            let token = tokens[searchIndex]
            if token == .endOfScope(")") {
                parenDepth += 1
            } else if token == .startOfScope("(") {
                if parenDepth == 0 {
                    // Check if this is a function call by looking before the (
                    if let prevIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, before: searchIndex),
                       tokens[prevIndex].isIdentifier || tokens[prevIndex] == .endOfScope(")")
                    {
                        return true
                    }
                    return false
                }
                parenDepth -= 1
            }
            searchIndex -= 1
        }
        return false
    }

    /// Helper to check if a comma is inside an array or dictionary literal
    func isInArrayOrDictionary(at index: Int) -> Bool {
        guard tokens[index] == .delimiter(",") else { return false }

        // Find the nearest enclosing brackets
        var searchIndex = index
        var bracketDepth = 0

        while searchIndex >= 0 {
            let token = tokens[searchIndex]
            if token == .endOfScope("]") {
                bracketDepth += 1
            } else if token == .startOfScope("[") {
                if bracketDepth == 0 {
                    return true
                }
                bracketDepth -= 1
            }
            searchIndex -= 1
        }
        return false
    }
}
