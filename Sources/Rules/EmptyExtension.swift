//
//  EmptyExtension.swift
//  SwiftFormat
//
//  Created by Manny Lopez on 7/30/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove empty, non-conforming, extensions.
    static let emptyExtension = FormatRule(
        help: "Remove empty, non-conforming, extensions.",
        orderAfter: [.unusedPrivateDeclarations]
    ) { formatter in
        var emptyExtensions = [TypeDeclaration]()

        for declaration in formatter.parseDeclarationsV2() {
            guard declaration.keyword == "extension",
                  let extensionDeclaration = declaration.asTypeDeclaration,
                  extensionDeclaration.body.isEmpty,
                  // Ensure that it is not a macro
                  !extensionDeclaration.modifiers.contains(where: { $0.first == "@" })
            else { continue }

            // Ensure that the extension does not conform to any protocols
            guard extensionDeclaration.conformances.isEmpty else { continue }

            emptyExtensions.append(extensionDeclaration)
        }

        for emptyExtension in emptyExtensions {
            emptyExtension.remove()
        }
    } examples: {
        """
        ```diff
        - extension String {}
        -
          extension String: Equatable {}
        ```
        """
    }
}
