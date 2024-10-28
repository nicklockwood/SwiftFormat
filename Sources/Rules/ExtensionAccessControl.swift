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

        let declarations = formatter.parseDeclarations()
        let updatedDeclarations = declarations.mapRecursiveDeclarations { declaration in
            guard case let .type("extension", open, body, close, _) = declaration else {
                return declaration
            }

            let visibilityKeyword = declaration.visibility()
            // `private` visibility at top level of file is equivalent to `fileprivate`
            let extensionVisibility = (visibilityKeyword == .private) ? .fileprivate : visibilityKeyword

            switch formatter.options.extensionACLPlacement {
            // If all declarations in the extension have the same visibility,
            // remove the keyword from the individual declarations and
            // place it on the extension itself.
            case .onExtension:
                if extensionVisibility == nil,
                   let delimiterIndex = declaration.openTokens.firstIndex(of: .delimiter(":")),
                   declaration.openTokens.firstIndex(of: .keyword("where")).map({ $0 > delimiterIndex }) ?? true
                {
                    // Extension adds protocol conformance so can't have visibility modifier
                    return declaration
                }

                let visibilityOfBodyDeclarations = formatter
                    .mapDeclarationsExcludingTypeBodies(body) { declaration in
                        declaration.visibility() ?? extensionVisibility ?? .internal
                    }
                    .compactMap { $0 }

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
                else { return declaration }

                if memberVisibility > extensionVisibility ?? .internal {
                    // Check type being extended does not have lower visibility
                    for d in declarations where d.name == declaration.name {
                        if case let .type(kind, _, _, _, _) = d {
                            if kind != "extension", d.visibility() ?? .internal < memberVisibility {
                                // Cannot make extension with greater visibility than type being extended
                                return declaration
                            }
                            break
                        }
                    }
                }

                let extensionWithUpdatedVisibility: Declaration
                if memberVisibility == extensionVisibility ||
                    (memberVisibility == .internal && visibilityKeyword == nil)
                {
                    extensionWithUpdatedVisibility = declaration
                } else {
                    extensionWithUpdatedVisibility = declaration.add(memberVisibility)
                }

                return formatter.mapBodyDeclarationsExcludingTypeBodies(in: extensionWithUpdatedVisibility) { bodyDeclaration in
                    let visibility = bodyDeclaration.visibility()
                    if memberVisibility > visibility ?? extensionVisibility ?? .internal {
                        if visibility == nil {
                            return bodyDeclaration.add(.internal)
                        }
                        return bodyDeclaration
                    }
                    return bodyDeclaration.remove(memberVisibility)
                }

            // Move the extension's visibility keyword to each individual declaration
            case .onDeclarations:
                // If the extension visibility is unspecified then there isn't any work to do
                guard let extensionVisibility = extensionVisibility else {
                    return declaration
                }

                // Remove the visibility keyword from the extension declaration itself
                let extensionWithUpdatedVisibility = declaration.remove(visibilityKeyword!)

                // And apply the extension's visibility to each of its child declarations
                // that don't have an explicit visibility keyword
                return formatter.mapBodyDeclarationsExcludingTypeBodies(in: extensionWithUpdatedVisibility) { bodyDeclaration in
                    if bodyDeclaration.visibility() == nil {
                        // If there was no explicit visibility keyword, then this declaration
                        // was using the visibility of the extension itself.
                        return bodyDeclaration.add(extensionVisibility)
                    } else {
                        // Keep the existing visibility
                        return bodyDeclaration
                    }
                }
            }
        }

        let updatedTokens = updatedDeclarations.flatMap(\.tokens)
        formatter.replaceTokens(in: formatter.tokens.indices, with: updatedTokens)
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
