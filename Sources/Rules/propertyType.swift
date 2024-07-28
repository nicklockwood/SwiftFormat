//
//  propertyType.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

extension FormatRule {
    public static let propertyType = FormatRule(
        help: "Convert property declarations to use inferred types (`let foo = Foo()`) or explicit types (`let foo: Foo = .init()`).",
        disabledByDefault: true,
        orderAfter: ["redundantType"],
        options: ["inferredtypes", "preservesymbols"],
        sharedOptions: ["redundanttype"]
    ) { formatter in
        formatter.forEach(.operator("=", .infix)) { equalsIndex, _ in
            // Preserve all properties in conditional statements like `if let foo = Bar() { ... }`
            guard !formatter.isConditionalStatement(at: equalsIndex) else { return }

            // Determine whether the type should use the inferred syntax (`let foo = Foo()`)
            // of the explicit syntax (`let foo: Foo = .init()`).
            let useInferredType: Bool
            switch formatter.options.redundantType {
            case .inferred:
                useInferredType = true

            case .explicit:
                useInferredType = false

            case .inferLocalsOnly:
                switch formatter.declarationScope(at: equalsIndex) {
                case .global, .type:
                    useInferredType = false
                case .local:
                    useInferredType = true
                }
            }

            guard let introducerIndex = formatter.indexOfLastSignificantKeyword(at: equalsIndex),
                  ["var", "let"].contains(formatter.tokens[introducerIndex].string),
                  let property = formatter.parsePropertyDeclaration(atIntroducerIndex: introducerIndex),
                  let rhsExpressionRange = property.value?.expressionRange
            else { return }

            let rhsStartIndex = rhsExpressionRange.lowerBound

            if useInferredType {
                guard let type = property.type else { return }
                let typeTokens = formatter.tokens[type.range]

                // Preserve the existing formatting if the LHS type is optional.
                //  - `let foo: Foo? = .foo` is valid, but `let foo = Foo?.foo`
                //    is invalid if `.foo` is defined on `Foo` but not `Foo?`.
                guard !["?", "!"].contains(typeTokens.last?.string ?? "") else { return }

                // Preserve the existing formatting if the LHS type is an existential (indicated with `any`).
                //  - The `extension MyProtocol where Self == MyType { ... }` syntax
                //    creates static members where `let foo: any MyProtocol = .myType`
                //    is valid, but `let foo = (any MyProtocol).myType` isn't.
                guard typeTokens.first?.string != "any" else { return }

                // Preserve the existing formatting if the RHS expression has a top-level infix operator.
                //  - `let value: ClosedRange<Int> = .zero ... 10` would not be valid to convert to
                //    `let value = ClosedRange<Int>.zero ... 10`.
                if let nextInfixOperatorIndex = formatter.index(after: rhsStartIndex, where: { token in
                    token.isOperator(ofType: .infix) && token != .operator(".", .infix)
                }),
                    rhsExpressionRange.contains(nextInfixOperatorIndex)
                {
                    return
                }

                // Preserve the formatting as-is if the type is manually excluded
                if formatter.options.preserveSymbols.contains(type.name) {
                    return
                }

                // If the RHS starts with a leading dot, then we know its accessing some static member on this type.
                if formatter.tokens[rhsStartIndex].isOperator(".") {
                    // Preserve the formatting as-is if the identifier is manually excluded
                    if let identifierAfterDot = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: rhsStartIndex),
                       formatter.options.preserveSymbols.contains(formatter.tokens[identifierAfterDot].string)
                    { return }

                    // Update the . token from a prefix operator to an infix operator.
                    formatter.replaceToken(at: rhsStartIndex, with: .operator(".", .infix))

                    // Insert a copy of the type on the RHS before the dot
                    formatter.insert(typeTokens, at: rhsStartIndex)
                }

                // If the RHS is an if/switch expression, check that each branch starts with a leading dot
                else if formatter.options.inferredTypesInConditionalExpressions,
                        ["if", "switch"].contains(formatter.tokens[rhsStartIndex].string),
                        let conditonalBranches = formatter.conditionalBranches(at: rhsStartIndex)
                {
                    var hasInvalidConditionalBranch = false
                    formatter.forEachRecursiveConditionalBranch(in: conditonalBranches) { branch in
                        guard let firstTokenInBranch = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: branch.startOfBranch) else {
                            hasInvalidConditionalBranch = true
                            return
                        }

                        if !formatter.tokens[firstTokenInBranch].isOperator(".") {
                            hasInvalidConditionalBranch = true
                        }

                        // Preserve the formatting as-is if the identifier is manually excluded
                        if let identifierAfterDot = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: rhsStartIndex),
                           formatter.options.preserveSymbols.contains(formatter.tokens[identifierAfterDot].string)
                        {
                            hasInvalidConditionalBranch = true
                        }
                    }

                    guard !hasInvalidConditionalBranch else { return }

                    // Insert a copy of the type on the RHS before the dot in each branch
                    formatter.forEachRecursiveConditionalBranch(in: conditonalBranches) { branch in
                        guard let dotIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: branch.startOfBranch) else { return }

                        // Update the . token from a prefix operator to an infix operator.
                        formatter.replaceToken(at: dotIndex, with: .operator(".", .infix))

                        // Insert a copy of the type on the RHS before the dot
                        formatter.insert(typeTokens, at: dotIndex)
                    }
                }

                else {
                    return
                }

                // Remove the colon and explicit type before the equals token
                formatter.removeTokens(in: type.colonIndex ... type.range.upperBound)
            }

            // If using explicit types, convert properties to the format `let foo: Foo = .init()`.
            else {
                guard // When parsing the type, exclude lowercase identifiers so `foo` isn't parsed as a type,
                    // and so `Foo.init` is parsed as `Foo` instead of `Foo.init`.
                    let rhsType = formatter.parseType(at: rhsStartIndex, excludeLowercaseIdentifiers: true),
                    property.type == nil,
                    let indexAfterIdentifier = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: property.identifierIndex),
                    formatter.tokens[indexAfterIdentifier] != .delimiter(":"),
                    let indexAfterType = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: rhsType.range.upperBound),
                    [.operator(".", .infix), .startOfScope("(")].contains(formatter.tokens[indexAfterType]),
                    !rhsType.name.contains(".")
                else { return }

                // Preserve the existing formatting if the RHS expression has a top-level operator.
                //  - `let foo = Foo.foo.bar` would not be valid to convert to `let foo: Foo = .foo.bar`.
                let operatorSearchIndex = formatter.tokens[indexAfterType].isStartOfScope ? (indexAfterType - 1) : indexAfterType
                if let nextInfixOperatorIndex = formatter.index(after: operatorSearchIndex, where: { token in
                    token.isOperator(ofType: .infix)
                }),
                    rhsExpressionRange.contains(nextInfixOperatorIndex)
                {
                    return
                }

                // Preserve any types that have been manually excluded.
                // Preserve any `Void` types and tuples, since they're special and don't support things like `.init`
                guard !(formatter.options.preserveSymbols + ["Void"]).contains(rhsType.name),
                      !rhsType.name.hasPrefix("(")
                else { return }

                // A type name followed by a `(` is an implicit `.init(`. Insert a `.init`
                // so that the init call stays valid after we move the type to the LHS.
                if formatter.tokens[indexAfterType] == .startOfScope("(") {
                    // Preserve the existing format if `init` is manually excluded
                    if formatter.options.preserveSymbols.contains("init") {
                        return
                    }

                    formatter.insert([.operator(".", .prefix), .identifier("init")], at: indexAfterType)
                }

                // If the type name is followed by an infix `.` operator, convert it to a prefix operator.
                else if formatter.tokens[indexAfterType] == .operator(".", .infix) {
                    // Exclude types with dots followed by a member access.
                    //  - For example with something like `Color.Theme.themeColor`, we don't know
                    //    if the property is `static var themeColor: Color` or `static var themeColor: Color.Theme`.
                    //  - This isn't a problem with something like `Color.Theme()`, which we can reasonably assume
                    //    is an initializer
                    if rhsType.name.contains(".") { return }

                    // Preserve the formatting as-is if the identifier is manually excluded.
                    // Don't convert `let foo = Foo.self` to `let foo: Foo = .self`, since `.self` returns the metatype
                    let symbolsToExclude = formatter.options.preserveSymbols + ["self"]
                    if let indexAfterDot = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: indexAfterType),
                       symbolsToExclude.contains(formatter.tokens[indexAfterDot].string)
                    { return }

                    formatter.replaceToken(at: indexAfterType, with: .operator(".", .prefix))
                }

                // Move the type name to the LHS of the property, followed by a colon
                let typeTokens = formatter.tokens[rhsType.range]
                formatter.removeTokens(in: rhsType.range)
                formatter.insert([.delimiter(":"), .space(" ")] + typeTokens, at: property.identifierIndex + 1)
            }
        }
    }

}
