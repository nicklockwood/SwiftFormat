//
//  PreferStructSwiftTestingSuites.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 9/3/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let preferStructSwiftTestingSuites = FormatRule(
        help: "Use structs for Swift Testing suites where possible.",
        disabledByDefault: true,
        orderAfter: [.preferSwiftTesting]
    ) { formatter in
        guard formatter.hasImport("Testing") else { return }

        formatter.parseDeclarations().forEachRecursiveDeclaration { declaration in
            guard let typeDeclaration = declaration.asTypeDeclaration,
                  formatter.isSwiftTestingSuite(typeDeclaration)
            else { return }

            switch typeDeclaration.keyword {
            case "class":
                guard !typeDeclaration.body.containsMutableStoredInstanceVar else { return }
                guard typeDeclaration.conformances.isEmpty else { return }
                var keywordIndex = typeDeclaration.keywordIndex

                if let finalIndex = formatter.indexOfModifier("final", forDeclarationAt: keywordIndex),
                   let nextIndex = formatter.index(of: .nonSpace, after: finalIndex)
                {
                    formatter.removeTokens(in: finalIndex ..< nextIndex)
                    keywordIndex = typeDeclaration.keywordIndex
                }
                formatter.replaceToken(at: keywordIndex, with: .keyword("struct"))

            case "enum":
                guard !typeDeclaration.body.containsEnumCaseDeclaration else { return }
                formatter.replaceToken(at: typeDeclaration.keywordIndex, with: .keyword("struct"))

            default:
                break
            }
        }
    } examples: {
        """
        ```diff
          import Testing

        - final class FeatureTests {
        + struct FeatureTests {
              @Test func featureWorks() {}
          }
        ```
        """
    }
}

extension Formatter {
    func isSwiftTestingSuite(_ typeDeclaration: TypeDeclaration) -> Bool {
        guard ["class", "enum"].contains(typeDeclaration.keyword) else { return false }

        var hasSuiteAttribute = false
        _ = modifiersForDeclaration(at: typeDeclaration.keywordIndex, contains: { _, modifier in
            if modifier.hasPrefix("@Suite") {
                hasSuiteAttribute = true
                return true
            }
            return false
        })

        if hasSuiteAttribute {
            return true
        }

        return typeDeclaration.body.contains { declaration in
            declaration.keyword == "func" && declaration.modifiers.contains(where: { $0.hasPrefix("@Test") })
        }
    }
}

extension Collection<Declaration> {
    var containsMutableStoredInstanceVar: Bool {
        containsRecursiveDeclaration { declaration in
            declaration.keyword == "var" && declaration.isStoredInstanceProperty
        }
    }

    var containsEnumCaseDeclaration: Bool {
        containsRecursiveDeclaration { declaration in
            declaration.keyword == "case"
        }
    }

    func containsRecursiveDeclaration(_ predicate: (Declaration) -> Bool) -> Bool {
        for declaration in self {
            if predicate(declaration) || declaration.body?.containsRecursiveDeclaration(predicate) == true {
                return true
            }
        }
        return false
    }
}
