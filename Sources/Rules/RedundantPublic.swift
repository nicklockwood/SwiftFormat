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
        help: "Remove redundant public access control from declarations in internal types or extensions."
    ) { formatter in
        let declarations = formatter.parseDeclarations()

        // Process all declarations recursively
        declarations.forEachRecursiveDeclaration { declaration in
            // Skip if the declaration doesn't have public visibility
            guard declaration.visibility() == .public else { return }

            // Find the parent type or extension
            var currentParent = declaration.parent
            while let parent = currentParent {
                if let parentType = parent.asTypeDeclaration {
                    // Check if the parent type/extension has an explicit visibility
                    let parentVisibility = parent.visibility() ?? .internal

                    // If the parent is internal (explicitly or by default),
                    // then public on child declarations is redundant
                    if parentVisibility == .internal {
                        declaration.removeVisibility(.public)
                        return
                    }

                    // If we found a parent type/extension with non-internal visibility,
                    // the public modifier is not redundant
                    return
                }

                currentParent = parent.parent
            }
        }
    } examples: {
        """
        ```diff
        struct Foo {
        -   public let bar: Bar
        +   let bar: Bar
        -   public func baz() {}
        +   func baz() {}
        }

        internal class Example {
        -   public var value: Int
        +   var value: Int
        }

        // Public modifier is not removed in public types
        public struct PublicType {
            public let value: String // This remains public
        }
        ```
        """
    }
}
