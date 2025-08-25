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
        make the class `open`, or use a `// swiftformat:disable:next` directive. 
        """
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
                let baseClassName = conformance.conformance.components(separatedBy: "<").first ?? conformance.conformance
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

            // Insert final before the class keyword
            formatter.insert([.keyword("final"), .space(" ")], at: keywordIndex)

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
        // Does not modify open classes
        open class Baz {}
        ```

        ```diff
        // Does not modify classes that are already final
        final class Qux {}
        ```

        ```diff
        // Does not modify classes that have subclasses in the same file
        class BaseClass {}
        - class SubClass: BaseClass {}
        + final class SubClass: BaseClass {}
        ```

        ```diff
        // Handles generic classes correctly
        class Container<T> {}
        - class StringContainer: Container<String> {}
        + final class StringContainer: Container<String> {}
        ```

        ```diff
        // Does not modify classes with "Base" prefix or suffix
        class BaseClass {}
        class UtilityBase {}
        - class RegularClass {}
        + final class RegularClass {}
        ```

        ```diff
        // Converts open members to public when making class final
        - class MyClass {
        -     open var property: String = ""
        -     open func method() {}
        - }
        + final class MyClass {
        +     public var property: String = ""
        +     public func method() {}
        + }
        ```
        """
    }
}
