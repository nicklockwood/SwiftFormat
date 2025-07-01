//
//  SinglePropertyPerLine.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 6/27/25.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let singlePropertyPerLine = FormatRule(
        help: "Use a separate let/var declaration on its own line for every property.",
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

            /// Handle declarations that define multiple properties like `let foo, bar: Int = 10`
            if let multiplePropertyDecl = formatter.parseMultiplePropertyDeclaration(at: i) {
                // In `let foo, bar: String` (when only the last property has a type, and it _doesn't_ have a default value),
                // the type applies to all of the properties.
                var sharedTypeTokens: [Token]?
                let lastProperty = multiplePropertyDecl.properties.last!
                let propertiesBeforeLast = multiplePropertyDecl.properties.dropLast()

                // If ONLY the final property has a type or default value, redistribute it to all properties
                let singleTypeSharedByAllProperties = propertiesBeforeLast.allSatisfy { $0.typeRange == nil && $0.valueRange == nil }
                    && lastProperty.typeRange != nil
                    && lastProperty.valueRange == nil

                if singleTypeSharedByAllProperties, let lastPropertyType = lastProperty.typeRange {
                    sharedTypeTokens = Array(formatter.tokens[lastPropertyType])
                }

                // Build replacement tokens for all declarations
                var allReplacementTokens: [Token] = []

                let startOfModifiers = formatter.startOfModifiers(at: i, includingAttributes: true)
                let modifierTokens = Array(formatter.tokens[startOfModifiers ..< i])
                let keywordToken = formatter.tokens[i]

                for (index, property) in multiplePropertyDecl.properties.enumerated() {
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
                    allReplacementTokens.append(.identifier(property.identifier))

                    // Add type annotation if available or shared
                    if let typeRange = property.typeRange {
                        allReplacementTokens.append(.delimiter(":"))
                        allReplacementTokens.append(.space(" "))
                        allReplacementTokens.append(contentsOf: formatter.tokens[typeRange])
                    } else if let sharedTypeTokens {
                        allReplacementTokens.append(.delimiter(":"))
                        allReplacementTokens.append(.space(" "))
                        allReplacementTokens.append(contentsOf: sharedTypeTokens)
                    }

                    // Add value assignment if available
                    if let valueRange = property.valueRange {
                        allReplacementTokens.append(.space(" "))
                        allReplacementTokens.append(.operator("=", .infix))
                        allReplacementTokens.append(.space(" "))
                        allReplacementTokens.append(contentsOf: formatter.tokens[valueRange])
                    }
                }

                // Replace the entire multiple property declaration with the new tokens
                formatter.replaceTokens(in: startOfModifiers ... multiplePropertyDecl.range.upperBound, with: allReplacementTokens)
            }

            // Handle tuple destructing properties like `let (foo, bar) = (1, 2)
            if let tupleDecl = formatter.parseTuplePropertyDeclaration(at: i) {
                // If the tuple property has a non-tuple type value, preserve it
                if tupleDecl.type != nil, tupleDecl.type?.tupleTypes == nil {
                    return
                }

                // If the tuple property has a non-tuple RHS value, preserve it
                if tupleDecl.value != nil, tupleDecl.value?.tupleValueRanges == nil {
                    return
                }

                // The property should have at least either a value or a type
                if tupleDecl.value == nil, tupleDecl.type == nil {
                    return
                }

                // Build replacement tokens for all declarations
                var allReplacementTokens: [Token] = []

                let startOfModifiers = formatter.startOfModifiers(at: i, includingAttributes: true)
                let modifierTokens = Array(formatter.tokens[startOfModifiers ..< i])
                let keywordToken = formatter.tokens[i]

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
                    if let types = tupleDecl.type?.tupleTypes, index < types.count {
                        allReplacementTokens.append(.delimiter(":"))
                        allReplacementTokens.append(.space(" "))
                        allReplacementTokens.append(.identifier(types[index].name))
                    }

                    // Add value assignment if available
                    if let value = tupleDecl.value?.tupleValueRanges, index < value.count {
                        let valueRange = value[index]
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

                // Replace the entire tuple declaration with the new tokens
                formatter.replaceTokens(in: startOfModifiers ... tupleDecl.range.upperBound, with: allReplacementTokens)
            }
        }
    } examples: {
        """
        ```diff
        - let a, b, c: Int
        + let a: Int
        + let b: Int

        - public var foo = 10, bar = false
        + public var foo = 10
        + public var bar = false

        - var (foo, bar) = ("foo", "bar")
        + var foo = "foo"
        + var bar = "bar"

        - private let (foo, bar): (Int, Bool) = (10, false)
        + private let foo: Int = 10
        + private let bar: Bool = false
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

        /// The range of this declaration
        var range: ClosedRange<Int> {
            guard let finalProperty = properties.last else {
                return introducerIndex ... introducerIndex
            }
            let endIndex = finalProperty.valueRange?.upperBound ?? finalProperty.typeRange?.upperBound ?? finalProperty.identifierIndex
            return introducerIndex ... endIndex
        }
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
        let type: (range: ClosedRange<Int>, tupleTypes: [(name: String, range: ClosedRange<Int>)]?)?
        let value: (range: ClosedRange<Int>, tupleValueRanges: [ClosedRange<Int>]?)?

        /// The range of this property
        var range: ClosedRange<Int> {
            if let value {
                return introducerIndex ... value.range.upperBound
            } else if let type {
                return introducerIndex ... type.range.upperBound
            } else {
                return introducerIndex ... ((identifiers.last?.index) ?? introducerIndex)
            }
        }
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

        guard var parseIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: endOfTuple) else { return nil }

        var propertyType: (range: ClosedRange<Int>, tupleTypes: [(name: String, range: ClosedRange<Int>)]?)?
        var propertyValue: (range: ClosedRange<Int>, tupleValueRanges: [ClosedRange<Int>]?)?

        // Parse the optional type, which can be a tuple or non-tuple
        if tokens[parseIndex] == .delimiter(":") {
            guard let typeStart = index(of: .nonSpaceOrCommentOrLinebreak, after: parseIndex),
                  let type = parseType(at: typeStart)
            else { return nil }

            // If the type is a tuple, parse the individual tuple types
            if tokens[typeStart] == .startOfScope("("), type.range.upperBound == endOfScope(at: typeStart) {
                let parsedTypes = parseTupleArguments(startOfScope: typeStart)
                propertyType = (range: type.range, tupleTypes: parsedTypes.map { type in
                    (name: type.value, range: type.valueRange)
                })
            } else {
                propertyType = (range: type.range, tupleTypes: nil)
            }

            if let nextIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: type.range.upperBound) {
                parseIndex = nextIndex
            } else {
                parseIndex = type.range.upperBound
            }
        }

        if tokens[parseIndex] == .operator("=", .infix) {
            guard let valueStart = index(of: .nonSpaceOrCommentOrLinebreak, after: parseIndex),
                  let expressionRange = parseExpressionRange(startingAt: valueStart, allowConditionalExpressions: true)
            else { return nil }

            // If the value is a tuple, parse the individual tuple values
            if tokens[valueStart] == .startOfScope("("), expressionRange.upperBound == endOfScope(at: valueStart) {
                let parsedValues = parseTupleArguments(startOfScope: valueStart)
                propertyValue = (range: expressionRange, tupleValueRanges: parsedValues.map { value in
                    value.valueRange
                })
            } else {
                propertyValue = (range: expressionRange, tupleValueRanges: nil)
            }
        }

        return TuplePropertyDeclaration(
            introducerIndex: introducerIndex,
            identifiers: identifiers,
            type: propertyType,
            value: propertyValue
        )
    }
}
