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
                // Only process if we have more than one identifier
                guard tupleDecl.identifiers.count > 1 else { return }
                
                // If we have values, they must match the number of identifiers
                if let values = tupleDecl.values {
                    guard tupleDecl.identifiers.count == values.count else { return }
                }

                // Get modifiers and keyword once
                let startOfModifiers = formatter.startOfModifiers(at: i, includingAttributes: true)
                let modifierTokens = Array(formatter.tokens[startOfModifiers ..< i])
                let keywordToken = formatter.tokens[i] // Store before removal

                // Adjust the range to include modifiers
                let adjustedRange = startOfModifiers ... tupleDecl.range.upperBound

                // Build replacement tokens for all declarations
                var allReplacementTokens: [Token] = []
                
                // Parse individual types from type annotation if present
                var individualTypes: [Token]? = nil
                if let typeAnnotation = tupleDecl.typeAnnotation {
                    individualTypes = formatter.parseIndividualTypesFromTuple(typeAnnotation)
                }

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
                    allReplacementTokens.append(.identifier(identifier))
                    
                    // Add type annotation if available
                    if let individualTypes = individualTypes, index < individualTypes.count {
                        allReplacementTokens.append(.delimiter(":"))
                        allReplacementTokens.append(.space(" "))
                        allReplacementTokens.append(individualTypes[index])
                    }
                    
                    // Add value assignment if available
                    if let values = tupleDecl.values, index < values.count {
                        let valueTokens = values[index]
                        
                        // Clean up value tokens by removing leading/trailing spaces
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

    /// A tuple destructuring declaration like `let (a, b, c) = (1, 2, 3)` or `let (a, b): (Int, Bool)`
    struct TupleDeclaration {
        let introducerIndex: Int
        let identifiers: [String]
        let values: [[Token]]?
        let typeAnnotation: [Token]?
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

    /// Parses a tuple destructuring declaration like `let (a, b, c) = (1, 2, 3)` or `let (a, b): (Int, Bool)`
    func parseTupleDeclaration(at introducerIndex: Int) -> TupleDeclaration? {
        guard ["let", "var"].contains(tokens[introducerIndex].string) else { return nil }

        // Look for opening parenthesis after let/var
        guard let parenIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: introducerIndex),
              tokens[parenIndex] == .startOfScope("("),
              let endOfTuple = endOfScope(at: parenIndex)
        else { return nil }
        
        // Check what comes after the tuple pattern
        guard let nextTokenIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: endOfTuple)
        else { return nil }
        
        var typeAnnotation: [Token]?
        var values: [[Token]]?
        var endOfStatement = endOfTuple
        
        if tokens[nextTokenIndex] == .delimiter(":") {
            // Type annotation case: let (a, b): (Int, Bool)
            guard let typeStart = index(of: .nonSpaceOrCommentOrLinebreak, after: nextTokenIndex),
                  let type = parseType(at: typeStart)
            else { return nil }
            
            typeAnnotation = Array(tokens[type.range])
            endOfStatement = type.range.upperBound
            
            // Check if there's also an assignment
            if let equalsIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: type.range.upperBound),
               tokens[equalsIndex] == .operator("=", .infix),
               let valueStart = index(of: .nonSpaceOrCommentOrLinebreak, after: equalsIndex)
            {
                // Parse the value (could be a tuple literal or any expression)
                if tokens[valueStart] == .startOfScope("("),
                   let endOfValueTuple = endOfScope(at: valueStart)
                {
                    // Tuple literal case
                    values = parseTupleValues(from: valueStart + 1, to: endOfValueTuple)
                    endOfStatement = endOfValueTuple
                } else {
                    // Single expression case - parse as expression
                    if parseExpressionRange(startingAt: valueStart, allowConditionalExpressions: true) != nil {
                        // For non-tuple expressions, we can't split them, so return nil
                        return nil
                    }
                }
            }
        } else if tokens[nextTokenIndex] == .operator("=", .infix) {
            // Assignment without type annotation: let (a, b) = (1, 2)
            guard let valueStart = index(of: .nonSpaceOrCommentOrLinebreak, after: nextTokenIndex)
            else { return nil }
            
            // Check if RHS is a tuple literal
            guard tokens[valueStart] == .startOfScope("("),
                  let endOfValueTuple = endOfScope(at: valueStart)
            else { return nil }
            
            values = parseTupleValues(from: valueStart + 1, to: endOfValueTuple)
            endOfStatement = endOfValueTuple
        } else {
            // No type annotation or assignment - not a pattern we support
            return nil
        }

        // Parse identifiers from the pattern tuple
        let identifiers = parseTupleIdentifiers(from: parenIndex + 1, to: endOfTuple)
        
        guard identifiers.count > 1 else { return nil }

        return TupleDeclaration(
            introducerIndex: introducerIndex,
            identifiers: identifiers,
            values: values,
            typeAnnotation: typeAnnotation,
            range: introducerIndex ... endOfStatement
        )
    }
    
    /// Parses identifiers from a tuple pattern like (a, b, c)
    func parseTupleIdentifiers(from startIndex: Int, to endIndex: Int) -> [String] {
        var identifiers: [String] = []
        var currentIndex = startIndex

        while currentIndex < endIndex {
            if let token = index(of: .nonSpaceOrCommentOrLinebreak, after: currentIndex - 1),
               token < endIndex
            {
                if tokens[token].isIdentifier {
                    identifiers.append(tokens[token].string)
                }
                currentIndex = token + 1
            } else {
                break
            }
        }
        
        return identifiers
    }
    
    /// Parses value tokens from a tuple literal like (1, 2, 3)
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
        
        return values
    }
    
    /// Parses individual types from a tuple type annotation like (Int, Bool) -> [Int, Bool]
    func parseIndividualTypesFromTuple(_ typeTokens: [Token]) -> [Token] {
        var individualTypes: [Token] = []
        var currentTypeTokens: [Token] = []
        var parenDepth = 0
        
        // Skip the opening parenthesis and start parsing
        var startIndex = 0
        if typeTokens.first == .startOfScope("(") {
            startIndex = 1
        }
        
        var endIndex = typeTokens.count
        if typeTokens.last == .endOfScope(")") {
            endIndex = typeTokens.count - 1
        }
        
        for i in startIndex ..< endIndex {
            let token = typeTokens[i]
            
            switch token {
            case .startOfScope("("), .startOfScope("["), .startOfScope("<"):
                parenDepth += 1
                currentTypeTokens.append(token)
            case .endOfScope(")"), .endOfScope("]"), .endOfScope(">"):
                parenDepth -= 1
                currentTypeTokens.append(token)
            case .delimiter(",") where parenDepth == 0:
                // Found a type separator, save current type
                if !currentTypeTokens.isEmpty {
                    // Clean up the type tokens
                    var cleanTypeTokens = currentTypeTokens
                    while cleanTypeTokens.first?.isSpace == true {
                        cleanTypeTokens.removeFirst()
                    }
                    while cleanTypeTokens.last?.isSpace == true {
                        cleanTypeTokens.removeLast()
                    }
                    
                    if cleanTypeTokens.count == 1 {
                        individualTypes.append(cleanTypeTokens[0])
                    } else {
                        // For complex types, we need to join them back - this is a simplified approach
                        // In a real implementation, we'd want to preserve the structure better
                        let typeString = cleanTypeTokens.map { $0.string }.joined()
                        individualTypes.append(.identifier(typeString))
                    }
                    currentTypeTokens = []
                }
            case .space, .linebreak:
                // Handle whitespace - preserve if we're building a type
                if !currentTypeTokens.isEmpty {
                    currentTypeTokens.append(token)
                }
            default:
                currentTypeTokens.append(token)
            }
        }
        
        // Add the last type
        if !currentTypeTokens.isEmpty {
            // Clean up the type tokens
            var cleanTypeTokens = currentTypeTokens
            while cleanTypeTokens.first?.isSpace == true {
                cleanTypeTokens.removeFirst()
            }
            while cleanTypeTokens.last?.isSpace == true {
                cleanTypeTokens.removeLast()
            }
            
            if cleanTypeTokens.count == 1 {
                individualTypes.append(cleanTypeTokens[0])
            } else {
                // For complex types, we need to join them back
                let typeString = cleanTypeTokens.map { $0.string }.joined()
                individualTypes.append(.identifier(typeString))
            }
        }
        
        return individualTypes
    }
}
