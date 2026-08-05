//
//  UnusedPrivateDeclarations.swift
//  SwiftFormat
//
//  Created by Manny Lopez on 7/17/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove unused private and fileprivate declarations
    static let unusedPrivateDeclarations = FormatRule(
        help: "Remove unused private and fileprivate declarations.",
        disabledByDefault: true,
        options: ["preserve-decls"]
    ) { formatter in
        guard !formatter.options.fragment else { return }

        let declarations = formatter.parseDeclarations()
        let synthesizedConformanceTypes = formatter.synthesizedEquatableAndHashableTypes(in: declarations)

        // Only remove unused properties, functions, or typealiases.
        //  - This rule doesn't currently support removing unused types,
        //    and it's more difficult to track the usage of other declaration
        //    types like `init`, `subscript`, `operator`, etc.
        let allowlist = ["let", "var", "func", "typealias"]
        let disallowedModifiers = ["override", "@objc", "@IBAction", "@IBSegueAction", "@IBOutlet", "@IBDesignable", "@IBInspectable", "@NSManaged", "@GKInspectable", "@Test"]

        // Collect all of the `private` or `fileprivate` declarations in the file
        var privateDeclarations: [Declaration] = []
        declarations.forEachRecursiveDeclaration { declaration in
            let declarationModifiers = Set(declaration.modifiers)
            let hasDisallowedModifiers = disallowedModifiers.contains(where: { declarationModifiers.contains($0) })
            let parentTypeName = declaration.parentType?.fullyQualifiedName
            var participatesInSynthesizedConformance = false
            if declaration.isStoredInstanceProperty, let parentTypeName {
                participatesInSynthesizedConformance = synthesizedConformanceTypes.contains(parentTypeName)
            }

            guard allowlist.contains(declaration.keyword),
                  let name = declaration.name,
                  !name.isOperator,
                  !formatter.options.preservedPrivateDeclarations.contains(name),
                  !participatesInSynthesizedConformance,
                  !hasDisallowedModifiers
            else { return }

            switch declaration.visibility() {
            case .fileprivate, .private:
                privateDeclarations.append(declaration)
            case .none, .open, .public, .package, .internal:
                break
            }
        }

        // Count the usage of each identifier in the file
        var usage: [String: Int] = [:]
        formatter.forEachToken(onlyWhereEnabled: false) { _, token in
            if case let .identifier(name) = token {
                usage[name, default: 0] += 1
            }
        }

        // Remove any private or fileprivate declaration whose name only
        // appears a single time in the source file
        for declaration in privateDeclarations {
            // Strip backticks from name for a normalized base name for cases like `default`
            guard let name = declaration.name?.trimmingCharacters(in: CharacterSet(charactersIn: "`")) else { continue }
            // Check for regular usage, common property wrapper prefixes, and protected names
            let variants = [name, "_\(name)", "$\(name)", "`\(name)`"]
            let count = variants.compactMap { usage[$0] }.reduce(0, +)
            if count <= 1 {
                declaration.remove()
            }
        }
    } examples: {
        """
        ```diff
          struct Foo {
        -     fileprivate var foo = "foo"
        -     fileprivate var baz = "baz"
              var bar = "bar"
          }
        ```
        """
    }
}

extension Formatter {
    /// The structs in this file that use compiler-synthesized `Equatable` or `Hashable` requirements.
    func synthesizedEquatableAndHashableTypes(in declarations: [Declaration]) -> Set<String> {
        var structNames = Set<String>()
        var conformancesByTypeName: [String: Set<String>] = [:]
        var conformanceDependenciesByName: [String: Set<String>] = [:]
        var equatableConformances = Set<String>()
        var hashableConformances = Set<String>()
        var manualEquatableImplementations = Set<String>()
        var manualHashableImplementations = Set<String>()

        declarations.forEachRecursiveDeclaration { declaration in
            if declaration.keyword == "struct", let typeName = declaration.fullyQualifiedName {
                structNames.insert(typeName)
            }

            if let typeDeclaration = declaration.asTypeDeclaration,
               let typeName = typeDeclaration.fullyQualifiedName
            {
                let conformances = Set(typeDeclaration.conformances.map(\.conformance.string))
                if declaration.keyword == "protocol" {
                    conformanceDependenciesByName[typeName, default: []].formUnion(conformances)
                    if let name = declaration.name {
                        conformanceDependenciesByName[name, default: []].formUnion(conformances)
                    }
                } else {
                    conformancesByTypeName[typeName, default: []].formUnion(conformances)
                }
            }

            // For the purpose of this function, a typealias is treated as a conformance to the aliased types.
            if declaration.keyword == "typealias",
               let typeName = declaration.fullyQualifiedName
            {
                let aliasedTypes = aliasedTypes(in: declaration)
                conformanceDependenciesByName[typeName, default: []].formUnion(aliasedTypes)
                if let name = declaration.name {
                    conformanceDependenciesByName[name, default: []].formUnion(aliasedTypes)
                }
            }

            guard declaration.keyword == "func",
                  let parentTypeName = declaration.parentType?.fullyQualifiedName
            else { return }

            // Find manual implementations of `==` that satisfy the `Equatable` conformance.
            if declaration.name == "==",
               declaration.hasModifier("static"),
               let function = parseFunctionDeclaration(keywordIndex: declaration.keywordIndex),
               isUnconditionalProtocolWitnessCandidate(declaration, function: function),
               function.arguments.count == 2,
               ["Bool", "Swift.Bool"].contains(function.returnType?.string),
               function.arguments.allSatisfy({ argument in
                   let argumentType = argument.type.string
                   return argumentType == "Self"
                       || argumentType == parentTypeName
                       || parentTypeName.hasSuffix("." + argumentType) // Unqualified spelling of a nested type.
               })
            {
                manualEquatableImplementations.insert(parentTypeName)
            }

            // Find manual implementations of `hash(into:)` that satisfy the `Hashable` conformance.
            if declaration.name == "hash",
               !declaration.hasModifier("static"),
               !declaration.hasModifier("mutating"),
               !declaration.hasModifier("consuming"),
               let function = parseFunctionDeclaration(keywordIndex: declaration.keywordIndex),
               isUnconditionalProtocolWitnessCandidate(declaration, function: function),
               function.arguments.count == 1,
               function.arguments[0].externalLabel == "into",
               ["inout Hasher", "inout Swift.Hasher"].contains(function.arguments[0].type.string),
               [nil, "Void", "Swift.Void", "()"].contains(function.returnType?.string)
            {
                manualHashableImplementations.insert(parentTypeName)
            }
        }

        let equatableProtocols = Set(["Equatable", "Swift.Equatable", "Hashable", "Swift.Hashable"])
        let hashableProtocols = Set(["Hashable", "Swift.Hashable"])

        // Build sets of types that conform to `Equatable` or `Hashable`, either directly or indirectly.
        for (typeName, conformances) in conformancesByTypeName {
            if conformances.contains(where: { conformance in
                var visitedProtocols = Set<String>()
                return conformanceNamed(
                    conformance,
                    resolvesToAnyOf: equatableProtocols,
                    in: conformanceDependenciesByName,
                    visited: &visitedProtocols
                )
            }) {
                equatableConformances.insert(typeName)
            }

            if conformances.contains(where: { conformance in
                var visitedProtocols = Set<String>()
                return conformanceNamed(
                    conformance,
                    resolvesToAnyOf: hashableProtocols,
                    in: conformanceDependenciesByName,
                    visited: &visitedProtocols
                )
            }) {
                hashableConformances.insert(typeName)
            }
        }

        // A type is "synthesized" iff it conforms to `Equatable` without a manual implementation
        // of `==`, or it conforms to `Hashable` without a manual implementation of `hash(into:)`.
        let synthesizedEquatableTypes = structNames.intersection(equatableConformances)
            .subtracting(manualEquatableImplementations)
        let synthesizedHashableTypes = structNames.intersection(hashableConformances)
            .subtracting(manualHashableImplementations)
        return synthesizedEquatableTypes.union(synthesizedHashableTypes)
    }

    /// The types referenced by a typealias, split into individual protocol-composition elements.
    func aliasedTypes(in declaration: Declaration) -> Set<String> {
        guard let equalsIndex = index(
            of: .operator("=", .infix),
            in: declaration.keywordIndex ..< declaration.range.upperBound
        ) else { return [] }

        let andTokenIndices = parseProtocolCompositionTypealias(at: declaration.keywordIndex)?.andTokenIndices ?? []
        return Set(([equalsIndex] + andTokenIndices).compactMap { delimiterIndex in
            guard let typeIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: delimiterIndex) else { return nil }
            return parseType(at: typeIndex, excludeProtocolCompositions: true)?.string
        })
    }

    /// Whether this function can unambiguously serve as an unconditional protocol witness.
    func isUnconditionalProtocolWitnessCandidate(_ declaration: Declaration, function: FunctionDeclaration) -> Bool {
        guard declaration.attributes.isEmpty,
              !declaration.parentDeclarations.contains(where: { $0.keyword == "#if" }),
              function.genericParameterRange == nil,
              function.whereClauseRange == nil,
              function.effects.isEmpty,
              let parentType = declaration.parentType
        else { return false }

        if parentType.keyword == "extension" {
            // A method in a constrained extension may not serve as the witness for every specialization.
            guard let startOfBody = index(of: .startOfScope("{"), after: parentType.keywordIndex) else { return false }
            return index(of: .keyword("where"), in: parentType.keywordIndex ..< startOfBody) == nil
        }

        return true
    }

    /// Whether a conformance resolves to any of the given protocols through typealiases or protocol refinements.
    func conformanceNamed(
        _ conformanceName: String,
        resolvesToAnyOf expectedProtocols: Set<String>,
        in conformanceDependenciesByName: [String: Set<String>],
        visited: inout Set<String>
    ) -> Bool {
        if expectedProtocols.contains(conformanceName) {
            return true
        }

        // Stop if malformed source contains a cyclic chain of aliases or protocol refinements.
        guard visited.insert(conformanceName).inserted,
              let dependencies = conformanceDependenciesByName[conformanceName]
        else { return false }

        return dependencies.contains { dependency in
            conformanceNamed(
                dependency,
                resolvesToAnyOf: expectedProtocols,
                in: conformanceDependenciesByName,
                visited: &visited
            )
        }
    }
}
