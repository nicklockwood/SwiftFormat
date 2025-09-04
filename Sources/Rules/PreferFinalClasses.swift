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
        // Parse all declarations to understand inheritance relationships
        let declarations = formatter.parseDeclarations()

        // Find all class names that are inherited from in this file
        var classesWithSubclasses = Set<String>()
        declarations.forEachRecursiveDeclaration { declaration in
            guard declaration.keyword == "class" else { return }

            // Check all conformances - any of them could be a superclass
            let conformances = formatter.parseConformancesOfType(atKeywordIndex: declaration.keywordIndex)
            for conformance in conformances {
                // Extract base class name from generic types like "Container<String>" -> "Container"
                let baseClassName = conformance.conformance.tokens.first?.string ?? conformance.conformance.string
                classesWithSubclasses.insert(baseClassName)
            }
        }

        // Now process each class declaration
        declarations.forEachRecursiveDeclaration { declaration in
            guard declaration.keyword == "class",
                  let className = declaration.name else { return }

            let keywordIndex = declaration.keywordIndex

            // Check if class already has final or open modifiers
            let hasFinalModifier = formatter.modifiersForDeclaration(at: keywordIndex, contains: "final")
            let hasOpenModifier = formatter.modifiersForDeclaration(at: keywordIndex, contains: "open")

            // Only add final if the class doesn't already have final or open
            guard !hasFinalModifier, !hasOpenModifier else { return }

            // Don't add final if this class is inherited from in the same file
            guard !classesWithSubclasses.contains(className) else { return }

            // Don't add final to classes that contain "Base" (they're likely meant to be subclassed)
            guard !className.contains("Base") else { return }

            // Don't add final to classes with a comment like "// Base class for XYZ functionality"
            if let docCommentRange = declaration.docCommentRange {
                let subclassRelatedTerms = ["base", "subclass"]
                let docComment = formatter.tokens[docCommentRange].string.lowercased()

                for term in subclassRelatedTerms {
                    if docComment.contains(term) {
                        return
                    }
                }
            }

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
