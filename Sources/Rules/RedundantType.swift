//
//  RedundantType.swift
//  SwiftFormat
//
//  Created by Facundo Menzella on 8/20/20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Removes explicit type declarations from initialization declarations
    static let redundantType = FormatRule(
        help: "Remove redundant type from variable declarations.",
        options: ["property-types"]
    ) { formatter in
        formatter.forEach(.operator("=", .infix)) { i, _ in
            guard let keyword = formatter.lastSignificantKeyword(at: i),
                  ["var", "let"].contains(keyword)
            else {
                return
            }

            let equalsIndex = i
            guard let colonIndex = formatter.index(before: i, where: {
                [.delimiter(":"), .operator("=", .infix)].contains($0)
            }), formatter.tokens[colonIndex] == .delimiter(":"),
            let typeEndIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: equalsIndex)
            else { return }

            // The implementation of RedundantType uses inferred or explicit,
            // potentially depending on the context.
            let isInferred: Bool
            let declarationKeywordIndex: Int?
            switch formatter.options.propertyTypes {
            case .inferred:
                isInferred = true
                declarationKeywordIndex = nil
            case .explicit:
                isInferred = false
                declarationKeywordIndex = formatter.declarationIndexAndScope(at: equalsIndex).index
            case .inferLocalsOnly:
                let (index, scope) = formatter.declarationIndexAndScope(at: equalsIndex)
                switch scope {
                case .global, .type:
                    isInferred = false
                    declarationKeywordIndex = index
                case .local:
                    isInferred = true
                    declarationKeywordIndex = nil
                }
            }

            // Explicit type can't be safely removed from @Model classes
            // https://github.com/nicklockwood/SwiftFormat/issues/1649
            if !isInferred,
               let declarationKeywordIndex,
               formatter.modifiersForDeclaration(at: declarationKeywordIndex, contains: "@Model")
            {
                return
            }

            /// Removes a type already processed by `compare(typeStartingAfter:withTypeStartingAfter:)`
            func removeType(after indexBeforeStartOfType: Int, i: Int, j: Int, wasValue: Bool) {
                if isInferred {
                    formatter.removeTokens(in: colonIndex ... typeEndIndex)
                    if formatter.tokens[colonIndex - 1].isSpace {
                        formatter.removeToken(at: colonIndex - 1)
                    }
                } else if !wasValue, let valueStartIndex = formatter
                    .index(of: .nonSpaceOrCommentOrLinebreak, after: indexBeforeStartOfType),
                    !formatter.isConditionalStatement(at: i),
                    let endIndex = formatter.endOfExpression(at: j, upTo: []),
                    endIndex > j
                {
                    let allowChains = formatter.options.swiftVersion >= "5.4"
                    if formatter.next(.nonSpaceOrComment, after: j) == .startOfScope("(") {
                        // Check if TypeName(literal) can be simplified to just the literal,
                        // because the type conforms to the corresponding ExpressibleBy...Literal protocol.
                        if let parenIndex = formatter.index(of: .nonSpaceOrComment, after: j),
                           let closeParen = formatter.endOfScope(at: parenIndex),
                           closeParen >= endIndex,
                           let typeStartIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: colonIndex),
                           case let .identifier(typeName) = formatter.tokens[typeStartIndex],
                           let literalRange = formatter.simplifiableLiteralRange(
                               forTypeName: typeName,
                               initOpenParen: parenIndex
                           )
                        {
                            let literalTokens = Array(formatter.tokens[literalRange])
                            formatter.replaceTokens(in: valueStartIndex ... closeParen, with: literalTokens)
                        } else if allowChains || formatter.index(
                            of: .operator(".", .infix),
                            in: j ..< endIndex
                        ) == nil {
                            formatter.replaceTokens(in: valueStartIndex ... j, with: [
                                .operator(".", .infix), .identifier("init"),
                            ])
                        }
                    } else if let nextIndex = formatter.index(
                        of: .nonSpaceOrCommentOrLinebreak,
                        after: j,
                        if: { $0 == .operator(".", .infix) }
                    ), allowChains || formatter.index(
                        of: .operator(".", .infix),
                        in: (nextIndex + 1) ..< endIndex
                    ) == nil {
                        formatter.removeTokens(in: valueStartIndex ... j)
                    }
                }
            }

            // In Swift 5.9+ (SE-0380) we need to handle if / switch expressions by checking each branch
            if let tokenAfterEquals = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: equalsIndex),
               let conditionalBranches = formatter.conditionalBranches(at: tokenAfterEquals),
               formatter.allRecursiveConditionalBranches(
                   in: conditionalBranches,
                   satisfy: { branch in
                       formatter.compare(typeStartingAfter: branch.startOfBranch, withTypeStartingAfter: colonIndex, typeEndIndex: typeEndIndex).matches
                   }
               )
            {
                if isInferred {
                    formatter.removeTokens(in: colonIndex ... typeEndIndex)
                    if formatter.tokens[colonIndex - 1].isSpace {
                        formatter.removeToken(at: colonIndex - 1)
                    }
                } else {
                    formatter.forEachRecursiveConditionalBranch(in: conditionalBranches) { branch in
                        let (_, i, j, wasValue) = formatter.compare(
                            typeStartingAfter: branch.startOfBranch,
                            withTypeStartingAfter: colonIndex,
                            typeEndIndex: typeEndIndex
                        )

                        removeType(after: branch.startOfBranch, i: i, j: j, wasValue: wasValue)
                    }
                }
            }

            // Otherwise this is just a simple assignment expression where the RHS is a single value
            else {
                let (matches, i, j, wasValue) = formatter.compare(typeStartingAfter: equalsIndex, withTypeStartingAfter: colonIndex, typeEndIndex: typeEndIndex)
                if matches {
                    removeType(after: equalsIndex, i: i, j: j, wasValue: wasValue)
                } else if isInferred,
                          let tokenAfterEquals = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: equalsIndex),
                          formatter.tokens[tokenAfterEquals] == .startOfScope("["),
                          let (baseTypeIndex, openAngle, argTypeIndex) = formatter.singleGenericArgType(afterColon: colonIndex, typeEndIndex: typeEndIndex),
                          formatter.tokens[baseTypeIndex] == .identifier("Set"),
                          let elementType = formatter.inferredArrayLiteralElementType(at: tokenAfterEquals),
                          formatter.tokens[argTypeIndex] == elementType
                {
                    // The generic argument is redundant (inferred from the array literal)
                    formatter.removeTokens(in: openAngle ... typeEndIndex)
                }
            }
        }
    } examples: {
        """
        ```diff
          // with --propertytypes inferred
        - let view: UIView = UIView()
        + let view = UIView()

          // with --propertytypes explicit
        - let view: UIView = UIView()
        + let view: UIView = .init()

          // with --propertytypes infer-locals-only
          class Foo {
        -     let view: UIView = UIView()
        +     let view: UIView = .init()

              func method() {
        -         let view: UIView = UIView()
        +         let view = UIView()
              }
          }
        ```
        """
    }
}

extension Formatter {
    /// Compares whether or not two types are equivalent
    func compare(typeStartingAfter j: Int, withTypeStartingAfter i: Int, typeEndIndex: Int)
        -> (matches: Bool, i: Int, j: Int, wasValue: Bool)
    {
        var i = i, j = j, wasValue = false

        while let typeIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: i),
              typeIndex <= typeEndIndex,
              let valueIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: j)
        {
            let typeToken = tokens[typeIndex]
            let valueToken = tokens[valueIndex]
            if !wasValue {
                switch valueToken {
                case _ where valueToken.isStringDelimiter, .number,
                     .identifier("true"), .identifier("false"):
                    if options.propertyTypes == .explicit {
                        // We never remove the value in this case, so exit early
                        return (false, i, j, wasValue)
                    }
                    wasValue = true
                default:
                    break
                }
            }
            guard typeToken == self.typeToken(forValueToken: valueToken) else {
                return (false, i, j, wasValue)
            }
            // Avoid introducing "inferred to have type 'Void'" warning
            if options.propertyTypes == .inferred, typeToken == .identifier("Void") ||
                typeToken == .endOfScope(")") && tokens[i] == .startOfScope("(")
            {
                return (false, i, j, wasValue)
            }
            i = typeIndex
            j = valueIndex
            if tokens[j].isStringDelimiter, let next = endOfScope(at: j) {
                j = next
            }
        }
        guard i == typeEndIndex else {
            return (false, i, j, wasValue)
        }

        // Check for ternary
        if let endOfExpression = endOfExpression(at: j, upTo: [.operator("?", .infix)]),
           next(.nonSpaceOrCommentOrLinebreak, after: endOfExpression) == .operator("?", .infix)
        {
            return (false, i, j, wasValue)
        }

        return (true, i, j, wasValue)
    }

    /// For a type annotation of the form `TypeName<SingleArg>`, returns the indices of
    /// the base type, the opening `<`, and the generic argument token.
    /// Returns nil if the type has multiple generic arguments, a complex argument type,
    /// or no generic argument at all.
    func singleGenericArgType(afterColon colonIndex: Int, typeEndIndex: Int)
        -> (baseTypeIndex: Int, openAngle: Int, argTypeIndex: Int)?
    {
        guard let baseTypeIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: colonIndex),
              case .identifier = tokens[baseTypeIndex],
              let openAngle = index(of: .nonSpaceOrCommentOrLinebreak, after: baseTypeIndex),
              tokens[openAngle] == .startOfScope("<"),
              let argTypeIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: openAngle),
              case .identifier = tokens[argTypeIndex],
              let closeAngle = index(of: .nonSpaceOrCommentOrLinebreak, after: argTypeIndex),
              closeAngle == typeEndIndex,
              tokens[closeAngle] == .endOfScope(">")
        else {
            return nil
        }
        return (baseTypeIndex, openAngle, argTypeIndex)
    }

    /// Returns the inferred element type for a homogeneous array literal, or nil if the
    /// array is empty, contains non-literal elements, or has mixed element types.
    func inferredArrayLiteralElementType(at index: Int) -> Token? {
        guard tokens[index] == .startOfScope("["),
              let endIndex = endOfScope(at: index)
        else { return nil }

        var elementType: Token? = nil
        var i = index

        while let nextIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, after: i),
              nextIndex < endIndex
        {
            let token = tokens[nextIndex]

            if token == .delimiter(",") {
                i = nextIndex
                continue
            }

            let inferred = typeToken(forValueToken: token)
            // typeToken returns the token unchanged for non-literals; skip those
            guard inferred != token else { return nil }

            if let existing = elementType {
                if existing != inferred {
                    return nil
                }
            } else {
                elementType = inferred
            }
            i = token.isStringDelimiter ? (endOfScope(at: nextIndex) ?? nextIndex) : nextIndex
        }

        return elementType
    }

    /// Returns the equivalent type token for a given value token
    func typeToken(forValueToken token: Token) -> Token {
        switch token {
        case let .number(_, type):
            switch type {
            case .decimal:
                return .identifier("Double")
            default:
                return .identifier("Int")
            }
        case let .identifier(name):
            return ["true", "false"].contains(name) ? .identifier("Bool") : .identifier(name)
        case let token:
            return token.isStringDelimiter ? .identifier("String") : token
        }
    }

    // MARK: - Literal-expressible types

    /// Standard library types known to conform to `ExpressibleByIntegerLiteral`
    static let integerLiteralTypes: Set<String> = [
        "Int", "Int8", "Int16", "Int32", "Int64", "Int128",
        "UInt", "UInt8", "UInt16", "UInt32", "UInt64", "UInt128",
        "Double", "Float", "Float16", "Float80",
        "StaticBigInt",
    ]

    /// Standard library types known to conform to `ExpressibleByFloatLiteral`
    static let floatLiteralTypes: Set<String> = [
        "Double", "Float", "Float16", "Float80",
    ]

    /// Standard library types known to conform to `ExpressibleByStringLiteral`
    static let stringLiteralTypes: Set<String> = [
        "String", "Substring", "StaticString",
    ]

    /// Standard library types known to conform to `ExpressibleByArrayLiteral`
    static let arrayLiteralTypes: Set<String> = [
        "ArraySlice", "ContiguousArray", "Set",
        "SIMD2", "SIMD3", "SIMD4", "SIMD8", "SIMD16", "SIMD32", "SIMD64",
        "SIMDMask",
    ]

    /// For an init call like `TypeName(singleLiteral)`, checks if the type is known
    /// to conform to the corresponding `ExpressibleBy...Literal` protocol and the init
    /// call can be simplified to just the literal value.
    /// Returns the range of the literal tokens if simplification is possible, nil otherwise.
    func simplifiableLiteralRange(
        forTypeName typeName: String,
        initOpenParen parenIndex: Int
    ) -> ClosedRange<Int>? {
        guard let closeParen = endOfScope(at: parenIndex) else { return nil }

        guard let argStart = index(of: .nonSpaceOrCommentOrLinebreak, after: parenIndex),
              argStart < closeParen
        else { return nil }

        let argToken = tokens[argStart]

        // Determine the end of the single argument
        let argEnd: Int
        switch argToken {
        case .number:
            argEnd = argStart
        case .identifier("true"), .identifier("false"):
            argEnd = argStart
        case _ where argToken.isStringDelimiter:
            guard let end = endOfScope(at: argStart) else { return nil }
            argEnd = end
        case .startOfScope("["):
            guard let end = endOfScope(at: argStart) else { return nil }
            argEnd = end
        default:
            return nil
        }

        // Ensure the literal is the only argument (no trailing comma, label, or extra args)
        guard let afterArg = index(of: .nonSpaceOrCommentOrLinebreak, after: argEnd),
              afterArg == closeParen
        else { return nil }

        // Check if the type conforms to the matching ExpressibleBy...Literal protocol
        switch argToken {
        case let .number(_, numType):
            switch numType {
            case .decimal:
                guard Formatter.floatLiteralTypes.contains(typeName) else { return nil }
            default:
                guard Formatter.integerLiteralTypes.contains(typeName) else { return nil }
            }
        case _ where argToken.isStringDelimiter:
            guard Formatter.stringLiteralTypes.contains(typeName) else { return nil }
        case .identifier("true"), .identifier("false"):
            guard typeName == "Bool" else { return nil }
        case .startOfScope("["):
            guard Formatter.arrayLiteralTypes.contains(typeName) else { return nil }
        default:
            return nil
        }

        return argStart ... argEnd
    }
}
