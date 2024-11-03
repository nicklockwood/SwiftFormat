//
//  ExtensionAccessControl.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 9/25/20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let extensionAccessControl = FormatRule(
        help: "Configure the placement of an extension's access control keyword.",
        options: ["extensionacl"]
    ) { formatter in
        guard !formatter.options.fragment else { return }

        let declarations = formatter.parseDeclarationsV2()
        declarations.forEachRecursiveDeclaration { declaration in
            guard let extensionDeclaration = declaration as? TypeDeclaration,
                  extensionDeclaration.keyword == "extension"
            else { return }

            let visibilityKeyword = declaration.visibility()

            // `private` visibility at top level of file is equivalent to `fileprivate`
            let extensionVisibility = (visibilityKeyword == .private) ? .fileprivate : visibilityKeyword

            switch formatter.options.extensionACLPlacement {
            // If all declarations in the extension have the same visibility,
            // remove the keyword from the individual declarations and
            // place it on the extension itself.
            case .onExtension:
                // If this type has any conformances, then we shouldn't change its visibility.
                if extensionVisibility == nil, !extensionDeclaration.conformances.isEmpty {
                    return
                }

                var visibilityOfBodyDeclarations = [Visibility]()
                extensionDeclaration.body.forEachRecursiveDeclarationExcludingTypeBodies { childDeclaration in
                    let visibility = childDeclaration.visibility() ?? extensionVisibility ?? .internal
                    visibilityOfBodyDeclarations.append(visibility)
                }

                let counts = Set(visibilityOfBodyDeclarations).sorted().map { visibility in
                    (visibility, count: visibilityOfBodyDeclarations.filter { $0 == visibility }.count)
                }

                guard let memberVisibility = counts.max(by: { $0.count < $1.count })?.0,
                      memberVisibility <= extensionVisibility ?? .public,
                      // Check that most common level is also most visible
                      memberVisibility == visibilityOfBodyDeclarations.max(),
                      // `private` can't be hoisted without changing code behavior
                      // (private applied at extension level is equivalent to `fileprivate`)
                      memberVisibility > .private
                else { return }

                if memberVisibility > extensionVisibility ?? .internal {
                    // Check type being extended does not have lower visibility
                    for extendedType in declarations where extendedType.name == extensionDeclaration.name {
                        guard let type = extendedType as? TypeDeclaration else { continue }

                        if extendedType.keyword != "extension",
                           extendedType.visibility() ?? .internal < memberVisibility
                        {
                            // Cannot make extension with greater visibility than type being extended
                            return
                        }

                        break
                    }
                }

                if memberVisibility != extensionVisibility,
                   !(memberVisibility == .internal && visibilityKeyword == nil)
                {
                    extensionDeclaration.addVisibility(memberVisibility)
                }

                extensionDeclaration.body.forEachRecursiveDeclarationExcludingTypeBodies { bodyDeclaration in

                    let visibility = bodyDeclaration.visibility()
                    if memberVisibility > visibility ?? extensionVisibility ?? .internal {
                        if visibility == nil {
                            bodyDeclaration.addVisibility(.internal)
                        }
                        return
                    }
                    bodyDeclaration.removeVisibility(memberVisibility)
                }

            // Move the extension's visibility keyword to each individual declaration
            case .onDeclarations:
                // If the extension visibility is unspecified then there isn't any work to do
                guard let extensionVisibility = extensionVisibility else { return }

                // Remove the visibility keyword from the extension declaration itself
                extensionDeclaration.removeVisibility(visibilityKeyword!)

                // And apply the extension's visibility to each of its child declarations
                // that don't have an explicit visibility keyword
                extensionDeclaration.body.forEachRecursiveDeclarationExcludingTypeBodies { bodyDeclaration in
                    if bodyDeclaration.visibility() == nil {
                        // If there was no explicit visibility keyword, then this declaration
                        // was using the visibility of the extension itself.
                        bodyDeclaration.addVisibility(extensionVisibility)
                    }
                }
            }
        }
    } examples: {
        """
        `--extensionacl on-extension` (default)

        ```diff
        - extension Foo {
        -     public func bar() {}
        -     public func baz() {}
          }

        + public extension Foo {
        +     func bar() {}
        +     func baz() {}
          }
        ```

        `--extensionacl on-declarations`

        ```diff
        - public extension Foo {
        -     func bar() {}
        -     func baz() {}
        -     internal func quux() {}
          }

        + extension Foo {
        +     public func bar() {}
        +     public func baz() {}
        +     func quux() {}
          }
        ```
        """
    }
}

extension Collection where Element == DeclarationV2 {
    // Performs the given operation for each declaration in this tree of declarations,
    // including the body of any child conditional compilation blocks,
    // but not the body of any child types. All of the iterated declarations belong
    // directly to the parent scope holding this array of declarations.
    func forEachRecursiveDeclarationExcludingTypeBodies(_ operation: (DeclarationV2) -> Void) {
        for declaration in self {
            switch declaration.kind {
            case let .declaration(declaration):
                operation(declaration)

            case let .type(type):
                operation(type)

            case let .conditionalCompilation(conditionalCompilation):
                conditionalCompilation.body.forEachRecursiveDeclarationExcludingTypeBodies(operation)
            }
        }
    }
}
