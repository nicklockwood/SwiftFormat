//
//  PropertyTypes.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 3/29/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let propertyTypes = FormatRule(
        help: "Control type annotations in variable declarations.",
        disabledByDefault: true,
        orderAfter: [.redundantType],
        options: ["property-types", "property-types-mode", "inferred-types", "preserved-property-types"],
        sharedOptions: ["init-types", "init-type-min-length"]
    ) { formatter in
        formatter.formatPropertyTypes()
    } examples: {
        """
        ```diff
          // --property-types inferred
        - let view: CustomView = CustomView()
        + let view = CustomView()

          // --property-types explicit
        - let view = CustomView()
        + let view: CustomView = CustomView()
        ```

        `infer-locals-only` uses inferred types in local scopes and explicit annotations on
        stored properties and globals. `--property-types-mode redundant-only` only removes
        redundant annotations, without moving a type that appears only once.

        Use `implicitMemberExpressions` to also shorten constructors to
        `.init()`. The `--init-types` and `--init-type-min-length` options control
        constructor spelling independently of annotation placement.
        """
    }
}

extension Formatter {
    func formatPropertyTypes() {
        removeRedundantPropertyTypes()
        guard options.propertyTypesMode == .always else { return }
        forEach(.operator("=", .infix)) { equalsIndex, _ in
            // Preserve all properties in conditional statements like `if let foo = Bar() { ... }`
            guard !isConditionalStatement(at: equalsIndex) else { return }

            // Determine whether the type should use the inferred syntax (`let foo = Foo()`)
            // of the explicit syntax (`let foo: Foo = .init()`).
            let useInferredType: Bool
            switch options.propertyTypes {
            case .inferred:
                useInferredType = true

            case .explicit:
                useInferredType = false

            case .inferLocalsOnly:
                switch declarationScope(at: equalsIndex) {
                case .global, .type:
                    useInferredType = false
                case .local:
                    useInferredType = true
                }
            }

            guard let introducerIndex = indexOfLastSignificantKeyword(at: equalsIndex),
                  ["var", "let"].contains(tokens[introducerIndex].string),
                  let property = parsePropertyDeclaration(atIntroducerIndex: introducerIndex),
                  let rhsExpressionRange = property.value?.expressionRange
            else { return }

            let rhsStartIndex = rhsExpressionRange.lowerBound
            var removesInitializerType = false

            if useInferredType {
                guard let type = property.type, let colonIndex = property.colonIndex else { return }

                // If the type is wrapped in redundant parens, retrieve the inner type value
                // before we check for types like `any Type` or `Type?`.
                let typeWithoutParens = type.withoutParens()

                // Preserve the existing formatting if the LHS type is optional.
                //  - `let foo: Foo? = .foo` is valid, but `let foo = Foo?.foo`
                //    is invalid if `.foo` is defined on `Foo` but not `Foo?`.
                guard typeWithoutParens.tokens.last?.isUnwrapOperator != true else { return }

                // Preserve the existing formatting if the LHS type is an existential (indicated with `any`)
                // or opaque type (indicated with `some`).
                //  - The `extension MyProtocol where Self == MyType { ... }` syntax
                //    creates static members where `let foo: any MyProtocol = .myType`
                //    is valid, but `let foo = (any MyProtocol).myType` isn't.
                guard typeWithoutParens.tokens.first?.string != "any",
                      typeWithoutParens.tokens.first?.string != "some"
                else { return }

                // Preserve the existing formatting if the RHS expression has a top-level infix operator.
                //  - `let value: ClosedRange<Int> = .zero ... 10` would not be valid to convert to
                //    `let value = ClosedRange<Int>.zero ... 10`.
                if let nextInfixOperatorIndex = index(after: rhsStartIndex, where: { token in
                       token.isOperator(ofType: .infix) && token != .operator(".", .infix)
                   }),
                   rhsExpressionRange.contains(nextInfixOperatorIndex)
                {
                    return
                }

                // Preserve the formatting as-is if the type is manually excluded
                if options.preservedPropertyTypes.contains(type.string) {
                    return
                }

                // If the RHS starts with a leading dot, then we know its accessing some static member on this type.
                if tokens[rhsStartIndex].isOperator(".") {
                    // Preserve the formatting as-is if the identifier is manually excluded
                    if let identifierAfterDot = index(of: .nonSpaceOrCommentOrLinebreak, after: rhsStartIndex),
                       options.preservedPropertyTypes.contains(tokens[identifierAfterDot].string)
                    {
                        return
                    }

                    // Update the . token from a prefix operator to an infix operator.
                    replaceToken(at: rhsStartIndex, with: .operator(".", .infix))

                    // Insert a copy of the type on the RHS before the dot
                    insert(type.tokens, at: rhsStartIndex)
                }

                // If the RHS is an if/switch expression, check that each branch starts with a leading dot
                else if options.inferredTypesInConditionalExpressions,
                        ["if", "switch"].contains(tokens[rhsStartIndex].string),
                        let conditonalBranches = conditionalBranches(at: rhsStartIndex)
                {
                    var hasInvalidConditionalBranch = false
                    forEachRecursiveConditionalBranch(in: conditonalBranches) { branch in
                        guard let firstTokenInBranch = index(of: .nonSpaceOrCommentOrLinebreak, after: branch.startOfBranch) else {
                            hasInvalidConditionalBranch = true
                            return
                        }

                        if !tokens[firstTokenInBranch].isOperator(".") {
                            hasInvalidConditionalBranch = true
                        }

                        // Preserve the formatting as-is if the identifier is manually excluded
                        if let identifierAfterDot = index(of: .nonSpaceOrCommentOrLinebreak, after: rhsStartIndex),
                           options.preservedPropertyTypes.contains(tokens[identifierAfterDot].string)
                        {
                            hasInvalidConditionalBranch = true
                        }
                    }

                    guard !hasInvalidConditionalBranch else { return }

                    // Insert a copy of the type on the RHS before the dot in each branch
                    forEachRecursiveConditionalBranch(in: conditonalBranches) { branch in
                        guard let dotIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: branch.startOfBranch) else { return }

                        // Update the . token from a prefix operator to an infix operator.
                        replaceToken(at: dotIndex, with: .operator(".", .infix))

                        // Insert a copy of the type on the RHS before the dot
                        insert(type.tokens, at: dotIndex)
                    }
                }

                // Convert `let array: [Foo] = []` to `let array = [Foo]()`
                else if type.isArray,
                        tokens[rhsStartIndex] == .startOfScope("["),
                        let nextToken = index(of: .nonSpaceOrCommentOrLinebreak, after: rhsStartIndex),
                        tokens[nextToken] == .endOfScope("]"),
                        rhsExpressionRange.upperBound == nextToken
                {
                    replaceTokens(in: rhsExpressionRange, with: tokenize("\(type.string)()"))
                }

                // Convert `let array: [Foo: Bar] = [:]` to `let array = [Foo: Bar]()`
                else if type.isDictionary,
                        tokens[rhsStartIndex] == .startOfScope("["),
                        let secondToken = index(of: .nonSpaceOrCommentOrLinebreak, after: rhsStartIndex),
                        tokens[secondToken] == .delimiter(":"),
                        let thirdToken = index(of: .nonSpaceOrCommentOrLinebreak, after: secondToken),
                        tokens[thirdToken] == .endOfScope("]"),
                        rhsExpressionRange.upperBound == thirdToken
                {
                    replaceTokens(in: rhsExpressionRange, with: tokenize("\(type.string)()"))
                }

                // Convert `let set: Set<Foo> = []` to `let set = Set<Foo>()`
                else if type.isSet,
                        tokens[rhsStartIndex] == .startOfScope("["),
                        let nextToken = index(of: .nonSpaceOrCommentOrLinebreak, after: rhsStartIndex),
                        tokens[nextToken] == .endOfScope("]"),
                        rhsExpressionRange.upperBound == nextToken
                {
                    replaceTokens(in: rhsExpressionRange, with: tokenize("\(type.string)()"))
                }

                else {
                    return
                }

                // Remove the colon and explicit type before the equals token
                removeTokens(in: colonIndex ... type.range.upperBound)
            }

            // If using explicit types, add an annotation without choosing qualifier spelling.
            else {
                guard // When parsing the type, exclude lowercase identifiers so `foo` isn't parsed as a type,
                    // and so `Foo.init` is parsed as `Foo` instead of `Foo.init`.
                    let rhsType = parseType(at: rhsStartIndex, excludeLowercaseIdentifiers: true),
                    property.type == nil,
                    let indexAfterIdentifier = index(of: .nonSpaceOrCommentOrLinebreak, after: property.identifierIndex),
                    tokens[indexAfterIdentifier] != .delimiter(":"),
                    let indexAfterType = index(of: .nonSpaceOrCommentOrLinebreak, after: rhsType.range.upperBound),
                    [.operator(".", .infix), .startOfScope("(")].contains(tokens[indexAfterType]),
                    !rhsType.string.contains(".")
                else { return }

                // Preserve the existing formatting if the RHS expression has a top-level operator.
                //  - `let foo = Foo.foo.bar` would not be valid to convert to `let foo: Foo = .foo.bar`.
                let operatorSearchIndex = tokens[indexAfterType].isStartOfScope ? (indexAfterType - 1) : indexAfterType
                if let nextInfixOperatorIndex = index(after: operatorSearchIndex, where: { token in
                       token.isOperator(ofType: .infix)
                   }),
                   rhsExpressionRange.contains(nextInfixOperatorIndex)
                {
                    return
                }

                // Preserve any types that have been manually excluded.
                // Preserve any `Void` types and tuples, since they're special and don't support things like `.init`
                guard !(options.preservedPropertyTypes + ["Void"]).contains(rhsType.string),
                      !rhsType.string.hasPrefix("(")
                else { return }

                // Constructor calls identify the annotation type. Collection and literal
                // initializers can also be simplified once that annotation is present.
                if tokens[indexAfterType] == .startOfScope("("),
                   let endOfInitCallScope = endOfScope(at: indexAfterType)
                {
                    // Preserve the existing format if `init` is manually excluded
                    if options.preservedPropertyTypes.contains("init") {
                        return
                    }

                    // The init call can be followed by trailing closures or a force unwrap, which are still
                    // valid after inserting `.init`. Preserve anything else, like `Foo(bar)[0]`, since the
                    // property may not have type `Foo`.
                    var endOfInitCall = parseFunctionCallArguments(startOfScope: indexAfterType).last
                        .map { max($0.valueRange.upperBound, endOfInitCallScope) } ?? endOfInitCallScope
                    if token(at: endOfInitCall + 1) == .operator("!", .postfix) {
                        endOfInitCall += 1
                    }
                    guard rhsExpressionRange.upperBound == endOfInitCall else { return }

                    let isInitCallOnly = endOfInitCall == endOfInitCallScope
                    let initializerHasNoArguments = isInitCallOnly &&
                        index(of: .nonSpaceOrCommentOrLinebreak, after: indexAfterType) == endOfInitCallScope

                    // If this is an empty array initializer, use `[]` instead of `.init()`
                    if rhsType.isArray, initializerHasNoArguments {
                        replaceTokens(in: indexAfterType ... endOfInitCallScope, with: tokenize("[]"))
                        removesInitializerType = true
                    }

                    // If this is an empty dictionary initializer, use `[:]` instead of `.init()`
                    else if rhsType.isDictionary, initializerHasNoArguments {
                        replaceTokens(in: indexAfterType ... endOfInitCallScope, with: tokenize("[:]"))
                        removesInitializerType = true
                    }

                    // If this is an empty set initializer, use `[]` instead of `.init()`
                    else if rhsType.isSet, initializerHasNoArguments {
                        replaceTokens(in: indexAfterType ... endOfInitCallScope, with: tokenize("[]"))
                        removesInitializerType = true
                    }

                    // If the type is ExpressibleBy...Literal and the init has a single matching
                    // literal argument, simplify `TypeName(literal)` to just the literal.
                    else if isInitCallOnly,
                            case let .identifier(typeName) = tokens[rhsType.range.lowerBound],
                            let literalRange = simplifiableLiteralRange(
                                forTypeName: typeName,
                                initOpenParen: indexAfterType
                            )
                    {
                        let typeTokens = Array(rhsType.tokens)
                        let literalTokens = Array(tokens[literalRange])
                        replaceTokens(in: rhsType.range.lowerBound ... endOfInitCallScope, with: literalTokens)
                        insert([.delimiter(":"), .space(" ")] + typeTokens, at: property.identifierIndex + 1)
                        return
                    }
                }

                // Preserve the qualifier when adding an annotation to a static member reference.
                else if tokens[indexAfterType] == .operator(".", .infix) {
                    // Exclude types with dots followed by a member access.
                    //  - For example with something like `Color.Theme.themeColor`, we don't know
                    //    if the property is `static var themeColor: Color` or `static var themeColor: Color.Theme`.
                    //  - This isn't a problem with something like `Color.Theme()`, which we can reasonably assume
                    //    is an initializer
                    if rhsType.string.contains(".") {
                        return
                    }

                    // Preserve the formatting as-is if the identifier is manually excluded.
                    // Don't convert `let foo = Foo.self` to `let foo: Foo = .self`, since `.self` returns the metatype
                    let symbolsToExclude = options.preservedPropertyTypes + ["self"]
                    if let indexAfterDot = index(of: .nonSpaceOrCommentOrLinebreak, after: indexAfterType),
                       symbolsToExclude.contains(tokens[indexAfterDot].string)
                    {
                        return
                    }
                }

                // Add the type annotation, removing the constructor type only for simplified literals.
                let typeTokens = tokens[rhsType.range]
                if removesInitializerType {
                    removeTokens(in: rhsType.range)
                }
                insert([.delimiter(":"), .space(" ")] + typeTokens, at: property.identifierIndex + 1)
            }
        }
    }
}
