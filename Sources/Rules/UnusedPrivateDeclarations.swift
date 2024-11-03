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
        options: ["preservedecls"]
    ) { formatter in
        guard !formatter.options.fragment else { return }

        // Only remove unused properties, functions, or typealiases.
        //  - This rule doesn't currently support removing unused types,
        //    and it's more difficult to track the usage of other declaration
        //    types like `init`, `subscript`, `operator`, etc.
        let allowlist = ["let", "var", "func", "typealias"]
        let disallowedModifiers = ["override", "@objc", "@IBAction", "@IBSegueAction", "@IBOutlet", "@IBDesignable", "@IBInspectable", "@NSManaged", "@GKInspectable"]

        // Collect all of the `private` or `fileprivate` declarations in the file
        var privateDeclarations: [Declaration] = []
        formatter.forEachRecursiveDeclaration { declaration in
            let declarationModifiers = Set(declaration.modifiers)
            let hasDisallowedModifiers = disallowedModifiers.contains(where: { declarationModifiers.contains($0) })

            guard allowlist.contains(declaration.keyword),
                  let name = declaration.name,
                  !name.isOperator,
                  !formatter.options.preservedPrivateDeclarations.contains(name),
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
        formatter.forEach(.identifier) { _, token in
            usage[token.string, default: 0] += 1
        }

        // Remove any private or fileprivate declaration whose name only
        // appears a single time in the source file
        for declaration in privateDeclarations.reversed() {
            // Strip backticks from name for a normalized base name for cases like `default`
            guard let name = declaration.name?.trimmingCharacters(in: CharacterSet(charactersIn: "`")) else { continue }
            // Check for regular usage, common property wrapper prefixes, and protected names
            let variants = [name, "_\(name)", "$\(name)", "`\(name)`"]
            let count = variants.compactMap { usage[$0] }.reduce(0, +)
            if count <= 1 {
                formatter.removeTokens(in: declaration.originalRange)
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
