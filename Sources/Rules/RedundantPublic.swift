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
        help: "Remove redundant public access control from declarations in internal or private types."
    ) { formatter in
        let declarations = formatter.parseDeclarations()

        // Find all internally declared types in the file
        var internalTypes = Set<String>()
        declarations.forEachRecursiveDeclaration { declaration in
            if let typeDecl = declaration.asTypeDeclaration,
               typeDecl.keyword != "extension" && typeDecl.keyword != "protocol",
               let typeName = declaration.fullyQualifiedName,
               declaration.visibility() == .internal || declaration.visibility() == nil
            {
                // Inside public extensions, types with no access control modifier are public.
                // This case is handled by the extensionAccessControl rule.
                let insidePublicExtension = declaration.parentDeclarations.contains(where: {
                    $0.keyword == "extension" && $0.visibility() == .public
                })

                if !insidePublicExtension {
                    internalTypes.insert(typeName)
                }
            }
        }

        // Process all declarations recursively
        declarations.forEachRecursiveDeclaration { declaration in
            guard declaration.visibility() == .public,
                  let parentType = declaration.parentType
            else { return }

            // Inside public extensions, types with no access control modifier are public.
            // This case is handled by the extensionAccessControl rule.
            let insidePublicExtension = declaration.parentDeclarations.contains(where: {
                $0.keyword == "extension" && $0.visibility() == .public
            })

            if insidePublicExtension {
                return
            }

            if declaration.modifiers.contains("@_spi") {
                return
            }

            switch parentType.keyword {
            case "extension":
                // Inside an extension where the extended type is internal, any `public` modifier has no effect.
                // We can only handle this case if the extension and type are defined in the same file.
                if let extendedTypeName = parentType.name,
                   internalTypes.contains(extendedTypeName)
                {
                    declaration.removeVisibility(.public)
                }

            // Inside an internal or private type, any `public` modifier has no effect
            default:
                if (parentType.visibility() ?? .internal) <= .internal {
                    declaration.removeVisibility(.public)
                }
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

          extension Foo {
        -     public func quux() {}
        +     func quux() {}
          }
        ```
        """
    }
}
