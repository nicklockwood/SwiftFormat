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
        help: "Use a separate let/var declaration on its own line for every property definition.",
        disabledByDefault: true,
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEachToken { i, token in
            guard ["let", "var"].contains(token.string) else { return }

            // Skip if this is part of a guard, if, or while statement
            if formatter.isConditionalStatement(at: i) {
                return
            }

            // Skip `async let` declarations
            if formatter.modifiersForDeclaration(at: i, contains: "async") {
                return
            }

            // If this property is within a parenthesis scope, this is probably
            // within a switch case like `case (let foo, bar):`
            if let startOfScope = formatter.startOfScope(at: i),
               formatter.tokens[startOfScope] == .startOfScope("(")
            {
                return
            }

            // Handle declarations that define multiple properties like `let foo, bar: Int = 10`
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
        + let c: Int
        ```

        ```diff
        - public var foo = 10, bar = false
        + public var foo = 10
        + public var bar = false
        ```

        ```diff
        - var (foo, bar) = ("foo", "bar")
        + var foo = "foo"
        + var bar = "bar"
        ```

        ```diff
        - private let (foo, bar): (Int, Bool) = (10, false)
        + private let foo: Int = 10
        + private let bar: Bool = false
        ```

        ```diff
          // Preserved:
          let (foo, bar) = methodCallWithPossibleSideEffects()
        ```
        """
    }
}
