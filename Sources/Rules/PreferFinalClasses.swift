//
//  PreferFinalClasses.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 2025-08-25.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Add the `final` keyword to all classes that are not declared as `open`
    static let preferFinalClasses = FormatRule(
        help: """
        Prefer defining `final` classes. To suppress this rule, add "Base" to the class name, \
        add a doc comment with mentioning "base class" or "subclass", make the class `open`, \
        or use a `// swiftformat:disable:next preferFinalClasses` directive.
        """,
        disabledByDefault: true
    ) { formatter in
        let declarations = formatter.parseDeclarations()

        declarations.forEachRecursiveDeclaration { declaration in
            guard declaration.keyword == "class",
                  let typeDecl = declaration as? TypeDeclaration else { return }

            let keywordIndex = declaration.keywordIndex

            // Check if class already has final or open modifiers
            let hasFinalModifier = formatter.modifiersForDeclaration(at: keywordIndex, contains: "final")
            let hasOpenModifier = formatter.modifiersForDeclaration(at: keywordIndex, contains: "open")

            // Only add final if the class doesn't already have final or open
            guard !hasFinalModifier, !hasOpenModifier else { return }

            // Don't add final to classes likely to be subclassed
            guard !formatter.isLikelyToBeSubclassed(typeDecl) else { return }

            formatter.insert(tokenize("final "), at: keywordIndex)

            // Convert any open direct child declarations to public (since final classes can't have open members)
            if let classBody = declaration.body {
                for childDeclaration in classBody {
                    guard formatter.modifiersForDeclaration(at: childDeclaration.keywordIndex, contains: "open") else { continue }

                    // Replace "open" with "public" for direct child declarations
                    if let openIndex = formatter.indexOfModifier("open", forDeclarationAt: childDeclaration.keywordIndex) {
                        formatter.replaceToken(at: openIndex, with: .keyword("public"))
                    }
                }
            }
        }
    } examples: {
        """
        ```diff
        - class Foo {}
        + final class Foo {}
        ```

        ```diff
        - public class Bar {}
        + public final class Bar {}
        ```

        ```diff
          // Preserved classes:
          open class Baz {}

          class BaseClass {}

          class MyClass {} // Subclassed in this file
          class MySubclass: MyClass {}

          /// Base class to be subclassed by other features
          class MyCustomizationPoint {}
        ```
        """
    }
}
