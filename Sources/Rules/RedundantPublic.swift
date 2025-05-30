//
//  RedundantPublic.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 5/30/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let redundantPublic = FormatRule(
        help: "Remove redundant public access control from declarations in internal types."
    ) { formatter in
        let declarations = formatter.parseDeclarations()

        // Process all declarations recursively
        declarations.forEachRecursiveDeclaration { declaration in
            // Skip if the declaration doesn't have public visibility
            guard declaration.visibility() == .public else { return }

            // Walk up the parent chain
            var parent = declaration.parent
            var enclosingType: TypeDeclaration?
            var hasPublicExtension = false
            var insideExtension = false

            while let currentParent = parent {
                switch currentParent.keyword {
                case "extension":
                    insideExtension = true
                    if currentParent.visibility() == .public {
                        hasPublicExtension = true
                    }

                default:
                    if let typeDeclaration = currentParent.asTypeDeclaration {
                        // Found a type declaration (class, struct, enum)
                        enclosingType = typeDeclaration
                        // Stop looking once we find a concrete type
                        break
                    }
                }
                parent = currentParent.parent
            }

            // Remove public only if the enclosing type is internal and not in a public extension
            if let enclosingType,
               enclosingType.visibility() ?? .internal == .internal,
               !hasPublicExtension
            {
                declaration.removeVisibility(.public)
            }
        }
    } examples: {
        """
        ```diff
          struct Foo {
        -     public let bar: Bar
        +     let bar: Bar
        -     public func baz() {}
        +     func baz() {}
          }

          internal class Example {
        -     public var value: Int
        +     var value: Int
          }
        ```
        """
    }
}
