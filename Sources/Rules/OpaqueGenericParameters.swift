//
//  OpaqueGenericParameters.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/5/22.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let opaqueGenericParameters = FormatRule(
        help: """
        Use opaque generic parameters (`some Protocol`) instead of generic parameters
        with constraints (`T where T: Protocol`, etc) where equivalent. Also supports
        primary associated types for common standard library types, so definitions like
        `T where T: Collection, T.Element == Foo` are updated to `some Collection<Foo>`.
        """,
        examples: """
        ```diff
        - func handle<T: Fooable>(_ value: T) {
        + func handle(_ value: some Fooable) {
              print(value)
          }

        - func handle<T>(_ value: T) where T: Fooable, T: Barable {
        + func handle(_ value: some Fooable & Barable) {
              print(value)
          }

        - func handle<T: Collection>(_ value: T) where T.Element == Foo {
        + func handle(_ value: some Collection<Foo>) {
              print(value)
          }

        // With `--someany enabled` (the default)
        - func handle<T>(_ value: T) {
        + func handle(_ value: some Any) {
              print(value)
          }
        ```
        """,
        options: ["someany"]
    ) { formatter in
        formatter.forEach(.keyword) { keywordIndex, keyword in
            guard // Opaque generic parameter syntax is only supported in Swift 5.7+
                formatter.options.swiftVersion >= "5.7",
                // Apply this rule to any function-like declaration
                [.keyword("func"), .keyword("init"), .keyword("subscript")].contains(keyword),
                // Validate that this is a generic method using angle bracket syntax,
                // and find the indices for all of the key tokens
                let paramListStartIndex = formatter.index(of: .startOfScope("("), after: keywordIndex),
                let paramListEndIndex = formatter.endOfScope(at: paramListStartIndex),
                let genericSignatureStartIndex = formatter.index(of: .startOfScope("<"), after: keywordIndex),
                let genericSignatureEndIndex = formatter.endOfScope(at: genericSignatureStartIndex),
                genericSignatureStartIndex < paramListStartIndex,
                genericSignatureEndIndex < paramListStartIndex,
                let openBraceIndex = formatter.index(of: .startOfScope("{"), after: paramListEndIndex),
                let closeBraceIndex = formatter.endOfScope(at: openBraceIndex)
            else { return }

            var genericTypes = [Formatter.GenericType]()

            // Parse the generics in the angle brackets (e.g. `<T, U: Fooable>`)
            formatter.parseGenericTypes(
                from: genericSignatureStartIndex,
                to: genericSignatureEndIndex,
                into: &genericTypes
            )

            // Parse additional conformances and constraints after the `where` keyword if present
            // (e.g. `where Foo: Fooable, Foo.Bar: Barable, Foo.Baaz == Baazable`)
            var whereTokenIndex: Int?
            if let whereIndex = formatter.index(of: .keyword("where"), after: paramListEndIndex),
               whereIndex < openBraceIndex
            {
                whereTokenIndex = whereIndex
                formatter.parseGenericTypes(from: whereIndex, to: openBraceIndex, into: &genericTypes)
            }

            // Parse the return type if present
            var returnTypeTokens: [Token]?
            if let returnIndex = formatter.index(of: .operator("->", .infix), after: paramListEndIndex),
               returnIndex < openBraceIndex, returnIndex < whereTokenIndex ?? openBraceIndex
            {
                let returnTypeRange = (returnIndex + 1) ..< (whereTokenIndex ?? openBraceIndex)
                returnTypeTokens = Array(formatter.tokens[returnTypeRange])
            }

            let genericParameterListRange = (genericSignatureStartIndex + 1) ..< genericSignatureEndIndex
            let genericParameterListTokens = formatter.tokens[genericParameterListRange]

            let parameterListRange = (paramListStartIndex + 1) ..< paramListEndIndex
            let parameterListTokens = formatter.tokens[parameterListRange]

            let bodyRange = (openBraceIndex + 1) ..< closeBraceIndex
            let bodyTokens = formatter.tokens[bodyRange]

            for genericType in genericTypes {
                // If the generic type doesn't occur in the generic parameter list (<...>),
                // then we inherited it from the generic context and can't replace the type
                // with an opaque parameter.
                if !genericParameterListTokens.contains(where: { $0.string == genericType.name }) {
                    genericType.eligibleToRemove = false
                    continue
                }

                // We can only remove the generic type if it appears exactly once in the parameter list.
                //  - If the generic type occurs _multiple_ times in the parameter list,
                //    it isn't eligible to be removed. For example `(T, T) where T: Foo`
                //    requires the two params to be the same underlying type, but
                //    `(some Foo, some Foo)` does not.
                //  - If the generic type occurs _zero_ times in the parameter list
                //    then removing the generic parameter would also remove any
                //    potentially-important constraints (for example, if the type isn't
                //    used in the function parameters / body and is only constrained relative
                //    to generic types in the parent type scope). If this generic parameter
                //    is truly unused and redundant then the compiler would emit an error.
                let countInParameterList = parameterListTokens.filter { $0.string == genericType.name }.count
                if countInParameterList != 1 {
                    genericType.eligibleToRemove = false
                    continue
                }

                // If the generic type occurs in the body of the function, then it can't be removed
                if bodyTokens.contains(where: { $0.string == genericType.name }) {
                    genericType.eligibleToRemove = false
                    continue
                }

                // If the generic type is referenced in any attributes, then it can't be removed
                let startOfModifiers = formatter.startOfModifiers(at: keywordIndex, includingAttributes: true)
                let modifierTokens = formatter.tokens[startOfModifiers ..< keywordIndex]
                if modifierTokens.contains(where: { $0.string == genericType.name }) {
                    genericType.eligibleToRemove = false
                    continue
                }

                // If the generic type is used in a constraint of any other generic type, then the type
                // can't be removed without breaking that other type
                let otherGenericTypes = genericTypes.filter { $0.name != genericType.name }
                let otherTypeConformances = otherGenericTypes.flatMap { $0.conformances }
                for otherTypeConformance in otherTypeConformances {
                    let conformanceTokens = formatter.tokens[otherTypeConformance.sourceRange]
                    if conformanceTokens.contains(where: { $0.string == genericType.name }) {
                        genericType.eligibleToRemove = false
                    }
                }

                // In some weird cases you can also have a generic constraint that references a generic
                // type from the parent context with the same name. We can't change these, since it
                // can cause the build to break
                for conformance in genericType.conformances {
                    if tokenize(conformance.name).contains(where: { $0.string == genericType.name }) {
                        genericType.eligibleToRemove = false
                    }
                }

                // A generic used as a return type is different from an opaque result type (SE-244).
                // For example in `-> T where T: Fooable`, the generic type is caller-specified,
                // but with `-> some Fooable` the generic type is specified by the function implementation.
                // Because those represent different concepts, we can't convert between them,
                // so have to mark the generic type as ineligible if it appears in the return type.
                if let returnTypeTokens = returnTypeTokens,
                   returnTypeTokens.contains(where: { $0.string == genericType.name })
                {
                    genericType.eligibleToRemove = false
                    continue
                }

                // If the method that generates the opaque parameter syntax doesn't succeed,
                // then this type is ineligible (because it used a generic constraint that
                // can't be represented using this syntax).
                // TODO: this option probably needs to be captured earlier to support comment directives
                if genericType.asOpaqueParameter(useSomeAny: formatter.options.useSomeAny) == nil {
                    genericType.eligibleToRemove = false
                    continue
                }

                // If the generic type is used as a closure type parameter, it can't be removed or the compiler
                // will emit a "'some' cannot appear in parameter position in parameter type <closure type>" error
                for tokenIndex in keywordIndex ... closeBraceIndex {
                    // Check if this is the start of a closure
                    if formatter.tokens[tokenIndex] == .startOfScope("("),
                       tokenIndex != paramListStartIndex,
                       let endOfScope = formatter.endOfScope(at: tokenIndex),
                       let tokenAfterParen = formatter.next(.nonSpaceOrCommentOrLinebreak, after: endOfScope),
                       [.operator("->", .infix), .keyword("throws"), .identifier("async")].contains(tokenAfterParen),
                       // Check if the closure type parameters contains this generic type
                       formatter.tokens[tokenIndex ... endOfScope].contains(where: { $0.string == genericType.name })
                    {
                        genericType.eligibleToRemove = false
                    }
                }

                // Extract the comma-separated list of function parameters,
                // so we can check conditions on the individual parameters
                let parameterListTokenIndices = (paramListStartIndex + 1) ..< paramListEndIndex

                // Split the parameter list at each comma that's directly within the paren list scope
                let parameters = parameterListTokenIndices
                    .split(whereSeparator: { index in
                        let token = formatter.tokens[index]
                        return token == .delimiter(",")
                            && formatter.endOfScope(at: index) == paramListEndIndex
                    })
                    .map { parameterIndices in
                        parameterIndices.map { index in
                            formatter.tokens[index]
                        }
                    }

                for parameterTokens in parameters {
                    // Variadic parameters don't support opaque generic syntax, so we have to check
                    // if any use cases of this type in the parameter list are variadic
                    if parameterTokens.contains(.operator("...", .postfix)),
                       parameterTokens.contains(.identifier(genericType.name))
                    {
                        genericType.eligibleToRemove = false
                    }
                }
            }

            let genericsEligibleToRemove = genericTypes.filter { $0.eligibleToRemove }
            let sourceRangesToRemove = Set(genericsEligibleToRemove.flatMap { type in
                [type.definitionSourceRange] + type.conformances.map { $0.sourceRange }
            })

            // We perform modifications to the function signature in reverse order
            // so we don't invalidate any of the indices we've recorded. So first
            // we remove components of the where clause.
            if let whereIndex = formatter.index(of: .keyword("where"), after: paramListEndIndex),
               whereIndex < openBraceIndex
            {
                let whereClauseSourceRanges = sourceRangesToRemove.filter { $0.lowerBound > whereIndex }
                formatter.removeTokens(in: Array(whereClauseSourceRanges))

                if let newOpenBraceIndex = formatter.index(of: .startOfScope("{"), after: whereIndex) {
                    // if where clause is completely empty, we need to remove the where token as well
                    if formatter.index(of: .nonSpaceOrLinebreak, after: whereIndex) == newOpenBraceIndex {
                        formatter.removeTokens(in: whereIndex ..< newOpenBraceIndex)
                    }
                    // remove trailing comma
                    else if let commaIndex = formatter.index(
                        of: .nonSpaceOrCommentOrLinebreak,
                        before: newOpenBraceIndex, if: { $0 == .delimiter(",") }
                    ) {
                        formatter.removeToken(at: commaIndex)
                        if formatter.tokens[commaIndex - 1].isSpace,
                           formatter.tokens[commaIndex].isSpaceOrLinebreak
                        {
                            formatter.removeToken(at: commaIndex - 1)
                        }
                    }
                }
            }

            // Replace all of the uses of generic types that are eligible to remove
            // with the corresponding opaque parameter declaration
            for index in parameterListRange.reversed() {
                if let matchingGenericType = genericsEligibleToRemove.first(where: { $0.name == formatter.tokens[index].string }),
                   var opaqueParameter = matchingGenericType.asOpaqueParameter(useSomeAny: formatter.options.useSomeAny)
                {
                    // If this instance of the type is followed by a `.` or `?` then we have to wrap the new type in parens
                    // (e.g. changing `Foo.Type` to `some Any.Type` breaks the build, it needs to be `(some Any).Type`)
                    if let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: index),
                       [.operator(".", .infix), .operator("?", .postfix)].contains(nextToken)
                    {
                        opaqueParameter.insert(.startOfScope("("), at: 0)
                        opaqueParameter.append(.endOfScope(")"))
                    }

                    formatter.replaceToken(at: index, with: opaqueParameter)
                }
            }

            // Remove types from the generic parameter list
            let genericParameterListSourceRanges = sourceRangesToRemove.filter { $0.lowerBound < genericSignatureEndIndex }
            formatter.removeTokens(in: Array(genericParameterListSourceRanges))

            // If we left a dangling comma at the end of the generic parameter list, we need to clean it up
            if let newGenericSignatureEndIndex = formatter.endOfScope(at: genericSignatureStartIndex),
               let trailingCommaIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: newGenericSignatureEndIndex),
               formatter.tokens[trailingCommaIndex] == .delimiter(",")
            {
                formatter.removeTokens(in: trailingCommaIndex ..< newGenericSignatureEndIndex)
            }

            // If we removed all of the generic types, we also have to remove the angle brackets
            if let newGenericSignatureEndIndex = formatter.index(of: .nonSpaceOrLinebreak, after: genericSignatureStartIndex),
               formatter.token(at: newGenericSignatureEndIndex) == .endOfScope(">")
            {
                formatter.removeTokens(in: genericSignatureStartIndex ... newGenericSignatureEndIndex)
            }
        }
    }
}
