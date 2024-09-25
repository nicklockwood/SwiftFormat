// Created by Cal Stephens on 9/25/24.
// Copyright © 2024 Airbnb Inc. All rights reserved.

public extension FormatRule {
    static let redundantEquatable = FormatRule(
        help: "Omit a hand-written Equatable implementation when the compiler-synthesized conformance would be equivalent."
    ) { formatter in
        let declarations = formatter.parseDeclarations()
        let equatableTypes = formatter.manuallyImplementedEquatableTypes(in: declarations)

        var declarationsToRemove = [Declaration]()

        for equatableType in equatableTypes {
            // The compiler only synthesizes Equatable implementations for structs
            guard equatableType.typeDeclaration.keyword == "struct",
                  let typeBody = equatableType.typeDeclaration.body
            else { continue }

            // Find all of the stored instance properties in this type.
            // The synthesized Equatable implementation would compare each of these.
            let storedInstanceProperties = Set(typeBody.filter(\.isStoredInstanceProperty).map(\.name))

            // Find all of the properties compared using `lhs.{property} == rhs.{property}`
            let comparedProperties = formatter.comparedProperties(in: equatableType.equatableFunction)

            // If the set of compared properties match the set of stored instance properties,
            // then the manually implemented `==` function is redundant and can be removed.
            if comparedProperties == storedInstanceProperties {
                declarationsToRemove.append(equatableType.equatableFunction)
            }
        }

        // Remove the declarations in backwards order to avoid invalidating existing indices
        for declarationToRemove in declarationsToRemove.reversed() {
            formatter.removeTokens(in: declarationToRemove.originalRange)
        }
    } examples: {
        """
          struct Foo: Equatable {
              let bar: Bar
              let baaz: Baaz

        -     static func ==(_ lhs: Foo, _ rhs: Foo) -> Bool {
        -         lhs.bar == rhs.bar 
        -             && lhs.baaz == rhs.baaz
        -     }
          }

          class Bar: Equatable {
              let baaz: Baaz

              static func ==(_ lhs: Foo, _ rhs: Foo) -> Bool {
                  lhs.baaz == rhs.baaz
              }
          }
        """
    }
}

extension Formatter {
    struct EquatableType {
        /// The main type declaration of the type that has an Equatable conformance
        let typeDeclaration: Declaration
        /// The Equatable `static func ==` implementation, which could be defined in an extension.
        let equatableFunction: Declaration
        /// The index of the `: Equatable` conformance, which could be defined in an extension.
        let equatableConformanceIndex: Int
    }

    /// Finds all of the types in the current file with an Equatable conformance,
    /// which also have a manually-implemented `static func ==` method.
    func manuallyImplementedEquatableTypes(in declarations: [Declaration]) -> [EquatableType] {
        var typeDeclarationsByName: [String: Declaration] = [:]
        var typesWithEquatableConformances: [(typeName: String, equatableConformanceIndex: Int)] = []
        var equatableImplementations: [String: Declaration] = [:]

        declarations.forEachRecursiveDeclaration { declaration, parentDeclaration in
            guard let declarationName = declaration.name else { return }

            if declaration.definesType {
                typeDeclarationsByName[declarationName] = declaration
            }

            // Support the Equatable conformance being declared in an extension
            // separately from the Equatable
            if declaration.definesType || declaration.keyword == "extension",
               let keywordIndex = declaration.originalKeywordIndex(in: self)
            {
                let conformances = parseConformancesOfType(atKeywordIndex: keywordIndex)

                // Both an Equatable and Hashable conformance will cause the Equatable conformance to be synthesized
                if let equatableConformance = conformances.first(where: {
                    $0.conformance == "Equatable" || $0.conformance == "Hashable"
                }) {
                    typesWithEquatableConformances.append(
                        (typeName: declarationName, equatableConformanceIndex: equatableConformance.index))
                }
            }

            if declaration.keyword == "func",
               declarationName == "==",
               let funcKeywordIndex = declaration.originalKeywordIndex(in: self),
               modifiersForDeclaration(at: funcKeywordIndex, contains: "static"),
               let startOfArguments = index(of: .startOfScope("("), after: funcKeywordIndex)
            {
                let functionArguments = parseFunctionDeclarationArguments(startOfScope: startOfArguments)

                if functionArguments.count == 2,
                   functionArguments[0].externalLabel == nil,
                   functionArguments[0].internalLabel == "lhs",
                   functionArguments[1].externalLabel == nil,
                   functionArguments[1].internalLabel == "rhs",
                   functionArguments[0].type == functionArguments[1].type
                {
                    var typeName = functionArguments[0].type

                    // If the function uses `Self`, resolve that to the name of the parent type
                    if typeName == "Self", let parentDeclarationName = parentDeclaration?.name {
                        typeName = parentDeclarationName
                    }

                    equatableImplementations[typeName] = declaration
                }
            }
        }

        return typesWithEquatableConformances.compactMap { typeName, equatableConformanceIndex in
            guard let typeDeclaration = typeDeclarationsByName[typeName],
                  let equatableImplementation = equatableImplementations[typeName]
            else { return nil }

            return EquatableType(
                typeDeclaration: typeDeclaration,
                equatableFunction: equatableImplementation,
                equatableConformanceIndex: equatableConformanceIndex
            )
        }
    }

    /// Finds the set of properties that are compared in the given Equatable `func`,
    /// following the pattern `lhs.{property} == rhs.{property}`.
    ///  - Returns `nil` if there are any comparisons that don't match this pattern.
    func comparedProperties(in equatableImplementation: Declaration) -> Set<String>? {
        guard let funcIndex = equatableImplementation.originalKeywordIndex(in: self),
              let startOfBody = index(of: .startOfScope("{"), after: funcIndex),
              let firstIndexInBody = index(of: .nonSpaceOrCommentOrLinebreak, after: startOfBody),
              let endOfBody = endOfScope(at: startOfBody)
        else { return nil }

        var validComparedProperties = Set<String>()
        var currentIndex = firstIndexInBody

        // Skip over any `return` keyword that may be present
        if tokens[currentIndex] == .keyword("return"),
           let nextIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: currentIndex)
        {
            currentIndex = nextIndex
        }

        while currentIndex < endOfBody {
            // Parse the current `lhs.{property} == rhs.{property}` pattern
            guard tokens[currentIndex] == .identifier("lhs"),
                  let lhsDotIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: currentIndex),
                  tokens[lhsDotIndex] == .operator(".", .infix),
                  let lhsPropertyName = index(of: .nonSpaceOrCommentOrLinebreak, after: lhsDotIndex),
                  tokens[lhsPropertyName].isIdentifierOrKeyword,
                  let equalsIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: lhsPropertyName),
                  tokens[equalsIndex] == .operator("==", .infix),
                  let rhsIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: equalsIndex),
                  tokens[rhsIndex] == .identifier("rhs"),
                  let rhsDotIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: rhsIndex),
                  tokens[rhsDotIndex] == .operator(".", .infix),
                  let rhsPropertyName = index(of: .nonSpaceOrCommentOrLinebreak, after: rhsDotIndex),
                  tokens[rhsPropertyName] == tokens[lhsPropertyName],
                  let indexAfterComparison = index(of: .nonSpaceOrCommentOrLinebreak, after: rhsPropertyName)
            else {
                // If we find a non-matching comparison, we have to avoid modifying this declaration
                return nil
            }

            validComparedProperties.insert(tokens[lhsPropertyName].string)

            // Skip over any `&&` operators connecting two comparisons
            if tokens[indexAfterComparison] == .operator("&&", .infix),
               let indexAfterAndOperator = index(of: .nonSpaceOrCommentOrLinebreak, after: indexAfterComparison)
            {
                currentIndex = indexAfterAndOperator
            }

            else {
                currentIndex = indexAfterComparison
            }
        }

        return validComparedProperties
    }
}
