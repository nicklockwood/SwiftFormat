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

            // Check for tuple destructuring pattern: let (a, b, c) = ...
            if let tupleDecl = formatter.parseTupleDeclaration(at: i) {
                // Only process if RHS is a tuple literal
                guard tupleDecl.identifiers.count > 1,
                      tupleDecl.identifiers.count == tupleDecl.values.count else { return }

                // Get modifiers and keyword once
                let startOfModifiers = formatter.startOfModifiers(at: i, includingAttributes: true)
                let modifierTokens = Array(formatter.tokens[startOfModifiers ..< i])
                let keywordToken = formatter.tokens[i] // Store before removal

                // Adjust the range to include modifiers
                let adjustedRange = startOfModifiers ... tupleDecl.range.upperBound

                // Build replacement tokens for all declarations
                var allReplacementTokens: [Token] = []

                for (index, (identifier, valueTokens)) in zip(tupleDecl.identifiers, tupleDecl.values).enumerated() {
                    // Clean up value tokens by removing leading/trailing spaces
                    var cleanValueTokens = valueTokens
                    while cleanValueTokens.first?.isSpace == true {
                        cleanValueTokens.removeFirst()
                    }
                    while cleanValueTokens.last?.isSpace == true {
                        cleanValueTokens.removeLast()
                    }
                    // Add newline and indentation before each declaration except the first
                    if index > 0 {
                        allReplacementTokens.append(.linebreak(formatter.options.linebreak, 1))

                        let indent = formatter.currentIndentForLine(at: i)
                        if !indent.isEmpty {
                            allReplacementTokens.append(.space(indent))
                        }
                    }

                    // Add modifiers and keyword
                    allReplacementTokens.append(contentsOf: modifierTokens)
                    allReplacementTokens.append(keywordToken)
                    allReplacementTokens.append(.space(" "))

                    // Add identifier = value
                    allReplacementTokens.append(.identifier(identifier))
                    allReplacementTokens.append(.space(" "))
                    allReplacementTokens.append(.operator("=", .infix))
                    allReplacementTokens.append(.space(" "))

                    // Add value tokens
                    allReplacementTokens.append(contentsOf: cleanValueTokens)
                }

                // Replace the entire tuple declaration with the new tokens
                formatter.replaceTokens(in: adjustedRange, with: allReplacementTokens)

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
                sharedTypeTokens = Array(formatter.tokens[lastPropertyType])
            }

            // Get modifiers and keyword once
            let startOfModifiers = formatter.startOfModifiers(at: i, includingAttributes: true)
            let modifierTokens = Array(formatter.tokens[startOfModifiers ..< i])
            let keywordToken = formatter.tokens[i]

            // Process commas from right to left
            for (index, property) in multiplePropertyDecl.properties.enumerated().reversed() {
                guard let commaIndex = property.trailingCommaIndex else { continue }

                // The property after this comma is at index + 1
                let nextPropertyIndex = index + 1
                guard nextPropertyIndex < multiplePropertyDecl.properties.count else { continue }
                let nextProperty = multiplePropertyDecl.properties[nextPropertyIndex]

                // First, add type annotation if needed (before replacing comma)
                if let sharedTypeTokens, nextProperty.typeRange == nil {
                    // Insert type annotation after the next property's identifier
                    var typeAnnotation = [Token.delimiter(":"), Token.space(" ")]
                    typeAnnotation.append(contentsOf: sharedTypeTokens)
                    formatter.insert(typeAnnotation, at: nextProperty.identifierIndex + 1)
                }

                // Replace comma with newline
                formatter.replaceToken(at: commaIndex, with: .linebreak(formatter.options.linebreak, 1))

                // Add indentation
                let indent = formatter.currentIndentForLine(at: i)
                if !indent.isEmpty {
                    formatter.insert(.space(indent), at: commaIndex + 1)
                }

                // Insert modifiers and keyword, removing any existing space after the comma
                let insertPoint = commaIndex + (indent.isEmpty ? 1 : 2)

                // Check if there's already a space token after the insertion point
                if formatter.token(at: insertPoint)?.isSpace == true {
                    formatter.removeToken(at: insertPoint)
                }

                var tokensToInsert = modifierTokens
                tokensToInsert.append(keywordToken)
                tokensToInsert.append(.space(" "))
                formatter.insert(tokensToInsert, at: insertPoint)
            }

            // Handle the first property - add type if needed
            if let sharedTypeTokens, let firstProperty = multiplePropertyDecl.properties.first {
                if firstProperty.typeRange == nil {
                    // Insert type annotation after the first property's identifier
                    var typeAnnotation = [Token.delimiter(":"), Token.space(" ")]
                    typeAnnotation.append(contentsOf: sharedTypeTokens)
                    formatter.insert(typeAnnotation, at: firstProperty.identifierIndex + 1)
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

    /// A tuple destructuring declaration like `let (a, b, c) = (1, 2, 3)`
    struct TupleDeclaration {
        let introducerIndex: Int
        let identifiers: [String]
        let values: [[Token]]
        let range: ClosedRange<Int>
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

    /// Parses a tuple destructuring declaration like `let (a, b, c) = (1, 2, 3)`
    func parseTupleDeclaration(at introducerIndex: Int) -> TupleDeclaration? {
        guard ["let", "var"].contains(tokens[introducerIndex].string) else { return nil }

        // Look for opening parenthesis after let/var
        guard let parenIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: introducerIndex),
              tokens[parenIndex] == .startOfScope("("),
              let endOfTuple = endOfScope(at: parenIndex),
              let equalsIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: endOfTuple),
              tokens[equalsIndex] == .operator("=", .infix),
              let valueStart = index(of: .nonSpaceOrCommentOrLinebreak, after: equalsIndex)
        else { return nil }

        // Check if RHS is a tuple literal
        guard tokens[valueStart] == .startOfScope("("),
              let endOfValueTuple = endOfScope(at: valueStart)
        else { return nil }

        // Parse identifiers from the pattern tuple
        var identifiers: [String] = []
        var currentIndex = parenIndex + 1

        while currentIndex < endOfTuple {
            if let token = index(of: .nonSpaceOrCommentOrLinebreak, after: currentIndex - 1),
               token < endOfTuple
            {
                if tokens[token].isIdentifier {
                    identifiers.append(tokens[token].string)
                }
                currentIndex = token + 1
            } else {
                break
            }
        }

        // Parse value tokens from the value tuple
        var values: [[Token]] = []
        var currentValueTokens: [Token] = []
        var parenDepth = 0
        currentIndex = valueStart + 1

        while currentIndex < endOfValueTuple {
            let token = tokens[currentIndex]

            switch token {
            case .startOfScope("("), .startOfScope("["), .startOfScope("{"):
                parenDepth += 1
                currentValueTokens.append(token)
            case .endOfScope(")"), .endOfScope("]"), .endOfScope("}"):
                parenDepth -= 1
                currentValueTokens.append(token)
            case .delimiter(",") where parenDepth == 0:
                // Found a value separator, save current value
                if !currentValueTokens.isEmpty {
                    values.append(currentValueTokens)
                    currentValueTokens = []
                }
            case .space:
                // Preserve spaces for proper formatting
                currentValueTokens.append(token)
            case .linebreak:
                // Skip linebreaks in values for cleaner output
                break
            default:
                currentValueTokens.append(token)
            }

            currentIndex += 1
        }

        // Add the last value
        if !currentValueTokens.isEmpty {
            values.append(currentValueTokens)
        }

        // Find the end of the statement
        let endOfStatement = endOfValueTuple

        return TupleDeclaration(
            introducerIndex: introducerIndex,
            identifiers: identifiers,
            values: values,
            range: introducerIndex ... endOfStatement
        )
    }
}
