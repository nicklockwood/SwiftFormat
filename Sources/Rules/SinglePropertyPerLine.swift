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
            if let tupleDecl = formatter.parseTuplePropertyDeclaration(at: i) {
                // Get modifiers and keyword once
                let startOfModifiers = formatter.startOfModifiers(at: i, includingAttributes: true)
                let modifierTokens = Array(formatter.tokens[startOfModifiers ..< i])
                let keywordToken = formatter.tokens[i]

                // Build replacement tokens for all declarations
                var allReplacementTokens: [Token] = []

                for (index, identifier) in tupleDecl.identifiers.enumerated() {
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

                    // Add identifier
                    allReplacementTokens.append(.identifier(identifier.name))

                    // Add type annotation if available
                    if let types = tupleDecl.types, index < types.count {
                        allReplacementTokens.append(.delimiter(":"))
                        allReplacementTokens.append(.space(" "))
                        allReplacementTokens.append(.identifier(types[index].name))
                    }

                    // Add value assignment if available
                    if let value = tupleDecl.value, index < value.tupleValueRanges.count {
                        let valueRange = value.tupleValueRanges[index]
                        let valueTokens = Array(formatter.tokens[valueRange])

                        var cleanValueTokens = valueTokens
                        while cleanValueTokens.first?.isSpace == true {
                            cleanValueTokens.removeFirst()
                        }
                        while cleanValueTokens.last?.isSpace == true {
                            cleanValueTokens.removeLast()
                        }

                        allReplacementTokens.append(.space(" "))
                        allReplacementTokens.append(.operator("=", .infix))
                        allReplacementTokens.append(.space(" "))
                        allReplacementTokens.append(contentsOf: cleanValueTokens)
                    }
                }

                // Calculate the range to replace - need to include the entire type annotation
                var endIndex = tupleDecl.identifiers.last?.index ?? i
                if let types = tupleDecl.types {
                    // Find the actual end of the type annotation
                    var typeEndIndex = i
                    var currentIndex = i
                    var foundColon = false
                    var parenDepth = 0

                    while currentIndex < formatter.tokens.count {
                        let token = formatter.tokens[currentIndex]
                        if token == .delimiter(":"), !foundColon {
                            foundColon = true
                        } else if foundColon {
                            if token == .startOfScope("(") {
                                parenDepth += 1
                            } else if token == .endOfScope(")") {
                                parenDepth -= 1
                                if parenDepth == 0 {
                                    typeEndIndex = currentIndex
                                    break
                                }
                            }
                        }
                        currentIndex += 1
                    }
                    endIndex = typeEndIndex
                }
                if let value = tupleDecl.value {
                    endIndex = value.range.upperBound
                }
                let adjustedRange = startOfModifiers ... endIndex

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

    /// Parses a property declaration that contains multiple properties, like:
    /// ```
    /// let foo, bar: Bool
    /// let foo = true, bar = false
    /// let foo: Foo, bar: Bar
    /// let foo: Foo, bar = false
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

    /// A tuple destructuring property declaration
    struct TuplePropertyDeclaration {
        let introducerIndex: Int
        let identifiers: [(name: String, index: Int)]
        let types: [(name: String, range: Range<Int>)]?
        let value: (range: ClosedRange<Int>, tupleValueRanges: [ClosedRange<Int>])?
    }

    /// Parses tuple destructuring property declaration like:
    /// ````
    /// let (a, b, c) = (1, 2, 3)
    /// let (a, b): (Int, Bool)
    /// let (a, b) = foo.bar
    /// ```
    func parseTuplePropertyDeclaration(at introducerIndex: Int) -> TuplePropertyDeclaration? {
        guard ["let", "var"].contains(tokens[introducerIndex].string) else { return nil }

        // Look for opening parenthesis after let/var
        guard let parenIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: introducerIndex),
              tokens[parenIndex] == .startOfScope("("),
              let endOfTuple = endOfScope(at: parenIndex)
        else { return nil }

        // Parse identifiers from the pattern tuple
        var identifiers: [(name: String, index: Int)] = []
        var currentIndex = parenIndex + 1
        while currentIndex < endOfTuple {
            if let token = index(of: .nonSpaceOrCommentOrLinebreak, after: currentIndex - 1),
               token < endOfTuple
            {
                if tokens[token].isIdentifier {
                    identifiers.append((name: tokens[token].string, index: token))
                }
                currentIndex = token + 1
            } else {
                break
            }
        }

        guard identifiers.count > 1 else { return nil }

        // Check what comes after the tuple pattern
        guard let nextTokenIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: endOfTuple)
        else { return nil }

        var types: [(name: String, range: Range<Int>)]?
        var value: (range: ClosedRange<Int>, tupleValueRanges: [ClosedRange<Int>])?

        if tokens[nextTokenIndex] == .delimiter(":") {
            // Type annotation case: let (a, b): (Int, Bool)
            guard let typeStart = index(of: .nonSpaceOrCommentOrLinebreak, after: nextTokenIndex),
                  let type = parseType(at: typeStart)
            else { return nil }

            // Parse individual types from tuple type annotation
            if tokens[typeStart] == .startOfScope("(") {
                let parsedTypes = parseIndividualTypesFromTuple(Array(tokens[type.range]))
                types = parsedTypes.enumerated().map { _, typeToken in
                    (name: typeToken.string, range: typeStart ..< typeStart)
                }
            } else {
                // Single type annotation
                let typeString = tokens[type.range].map(\.string).joined().trimmingCharacters(in: .whitespaces)
                types = [(name: typeString, range: type.range.lowerBound ..< type.range.upperBound)]
            }

            // Check if there's also an assignment with tuple literal
            if let equalsIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: type.range.upperBound),
               tokens[equalsIndex] == .operator("=", .infix),
               let valueStart = index(of: .nonSpaceOrCommentOrLinebreak, after: equalsIndex),
               tokens[valueStart] == .startOfScope("("),
               let endOfValueTuple = endOfScope(at: valueStart)
            {
                let parsedValues = parseTupleValues(from: valueStart + 1, to: endOfValueTuple)
                let tupleValueRanges = calculateValueRanges(parsedValues, startFrom: valueStart + 1, endAt: endOfValueTuple)
                value = (range: valueStart ... endOfValueTuple, tupleValueRanges: tupleValueRanges)
            }
        } else if tokens[nextTokenIndex] == .operator("=", .infix) {
            // Assignment without type annotation: let (a, b) = (1, 2)
            guard let valueStart = index(of: .nonSpaceOrCommentOrLinebreak, after: nextTokenIndex)
            else { return nil }

            // Check if RHS is a tuple literal
            guard tokens[valueStart] == .startOfScope("("),
                  let endOfValueTuple = endOfScope(at: valueStart)
            else { return nil }

            let parsedValues = parseTupleValues(from: valueStart + 1, to: endOfValueTuple)
            let tupleValueRanges = calculateValueRanges(parsedValues, startFrom: valueStart + 1, endAt: endOfValueTuple)
            value = (range: valueStart ... endOfValueTuple, tupleValueRanges: tupleValueRanges)
        } else {
            return nil
        }

        return TuplePropertyDeclaration(
            introducerIndex: introducerIndex,
            identifiers: identifiers,
            types: types,
            value: value
        )
    }

    /// Calculate value ranges for tuple values
    func calculateValueRanges(_ parsedValues: [[Token]], startFrom startIndex: Int, endAt endIndex: Int) -> [ClosedRange<Int>] {
        guard !parsedValues.isEmpty else { return [] }

        var ranges: [ClosedRange<Int>] = []
        var currentIndex = startIndex

        for (index, valueTokens) in parsedValues.enumerated() {
            // Skip spaces and find the start of this value
            while currentIndex < endIndex, tokens[currentIndex].isSpaceOrLinebreak {
                currentIndex += 1
            }

            let valueStart = currentIndex
            let valueTokenCount = valueTokens.filter { !$0.isSpaceOrLinebreak }.count

            // Find the end of this value by counting non-space tokens
            var nonSpaceCount = 0
            while currentIndex < endIndex, nonSpaceCount < valueTokenCount {
                if !tokens[currentIndex].isSpaceOrLinebreak {
                    nonSpaceCount += 1
                }
                currentIndex += 1
            }

            // Back up to the last token of this value
            var valueEnd = currentIndex - 1
            while valueEnd > valueStart, tokens[valueEnd].isSpaceOrLinebreak {
                valueEnd -= 1
            }

            ranges.append(valueStart ... valueEnd)

            // Skip the comma if this isn't the last value
            if index < parsedValues.count - 1 {
                while currentIndex < endIndex, tokens[currentIndex].isSpaceOrLinebreak || tokens[currentIndex] == .delimiter(",") {
                    currentIndex += 1
                }
            }
        }

        return ranges
    }

    /// Parses tuple values like (1, 2, 3)
    func parseTupleValues(from startIndex: Int, to endIndex: Int) -> [[Token]] {
        var values: [[Token]] = []
        var currentValueTokens: [Token] = []
        var parenDepth = 0
        var currentIndex = startIndex

        while currentIndex < endIndex {
            let token = tokens[currentIndex]

            switch token {
            case .startOfScope("("), .startOfScope("["), .startOfScope("{"):
                parenDepth += 1
                currentValueTokens.append(token)
            case .endOfScope(")"), .endOfScope("]"), .endOfScope("}"):
                parenDepth -= 1
                currentValueTokens.append(token)
            case .delimiter(",") where parenDepth == 0:
                if !currentValueTokens.isEmpty {
                    values.append(currentValueTokens)
                    currentValueTokens = []
                }
            case .space:
                currentValueTokens.append(token)
            case .linebreak:
                break
            default:
                currentValueTokens.append(token)
            }

            currentIndex += 1
        }

        if !currentValueTokens.isEmpty {
            values.append(currentValueTokens)
        }

        return values
    }

    /// Parses types from tuple annotation (Int, Bool) using existing tuple arguments parser
    func parseIndividualTypesFromTuple(_ typeTokens: [Token]) -> [Token] {
        // Find the start of scope for the tuple type annotation
        guard let parenStart = typeTokens.firstIndex(of: .startOfScope("(")),
              let parenEnd = typeTokens.lastIndex(of: .endOfScope(")"))
        else {
            // Not a tuple type, return as single type
            let typeString = typeTokens.map(\.string).joined().trimmingCharacters(in: .whitespaces)
            return [.identifier(typeString)]
        }

        // Extract just the tokens inside the parentheses
        let innerTokens = Array(typeTokens[(parenStart + 1) ..< parenEnd])

        // Split on commas at depth 0
        var types: [Token] = []
        var currentTypeTokens: [Token] = []
        var depth = 0

        for token in innerTokens {
            switch token {
            case .startOfScope:
                depth += 1
                currentTypeTokens.append(token)
            case .endOfScope:
                depth -= 1
                currentTypeTokens.append(token)
            case .delimiter(",") where depth == 0:
                if !currentTypeTokens.isEmpty {
                    let typeString = currentTypeTokens.map(\.string).joined().trimmingCharacters(in: .whitespaces)
                    types.append(.identifier(typeString))
                    currentTypeTokens = []
                }
            default:
                currentTypeTokens.append(token)
            }
        }

        // Add the last type
        if !currentTypeTokens.isEmpty {
            let typeString = currentTypeTokens.map(\.string).joined().trimmingCharacters(in: .whitespaces)
            types.append(.identifier(typeString))
        }

        return types
    }
}
