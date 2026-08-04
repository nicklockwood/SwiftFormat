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
        options: ["preserve-decls", "preserve-equatable-properties", "preserve-hashable-properties"]
    ) { formatter in
        guard !formatter.options.fragment else { return }

        let declarations = formatter.parseDeclarations()
        var synthesizedConformanceTypes = (equatable: Set<String>(), hashable: Set<String>())
        if formatter.options.preserveEquatableProperties || formatter.options.preserveHashableProperties {
            synthesizedConformanceTypes = formatter.synthesizedEquatableAndHashableTypes(in: declarations)
        }

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
            var participatesInPreservedConformance = false
            if declaration.isStoredInstanceProperty, let parentTypeName {
                participatesInPreservedConformance =
                    formatter.options.preserveEquatableProperties && synthesizedConformanceTypes.equatable.contains(parentTypeName)
                        || formatter.options.preserveHashableProperties && synthesizedConformanceTypes.hashable.contains(parentTypeName)
            }

            guard allowlist.contains(declaration.keyword),
                  let name = declaration.name,
                  !name.isOperator,
                  !formatter.options.preservedPrivateDeclarations.contains(name),
                  !participatesInPreservedConformance,
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
    func synthesizedEquatableAndHashableTypes(in declarations: [Declaration]) -> (equatable: Set<String>, hashable: Set<String>) {
        var structNames = Set<String>()
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
                let conformances = typeDeclaration.conformances.map(\.conformance.string)
                let hasEquatableConformance = conformances.contains("Equatable") || conformances.contains("Swift.Equatable")
                let hasHashableConformance = conformances.contains("Hashable") || conformances.contains("Swift.Hashable")
                if hasEquatableConformance || hasHashableConformance {
                    equatableConformances.insert(typeName)
                }
                if hasHashableConformance {
                    hashableConformances.insert(typeName)
                }
            }

            guard declaration.keyword == "func",
                  let parentTypeName = declaration.parentType?.fullyQualifiedName
            else { return }

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
                       || parentTypeName.hasSuffix("." + argumentType)
               })
            {
                manualEquatableImplementations.insert(parentTypeName)
            }

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

        return (
            equatable: structNames.intersection(equatableConformances).subtracting(manualEquatableImplementations),
            hashable: structNames.intersection(hashableConformances).subtracting(manualHashableImplementations)
        )
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
}
