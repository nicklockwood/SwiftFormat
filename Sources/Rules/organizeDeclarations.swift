//
//  OrganizeDeclarations.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let organizeDeclarations = FormatRule(
        help: "Organize declarations within class, struct, enum, actor, and extension bodies.",
        runOnceOnly: true,
        disabledByDefault: true,
        orderAfter: [.extensionAccessControl, .redundantFileprivate],
        options: [
            "categorymark", "markcategories", "beforemarks",
            "lifecycle", "organizetypes", "structthreshold", "classthreshold",
            "enumthreshold", "extensionlength", "organizationmode",
            "visibilityorder", "typeorder", "visibilitymarks", "typemarks",
        ],
        sharedOptions: ["sortedpatterns", "lineaftermarks"]
    ) { formatter in
        guard !formatter.options.fragment else { return }

        formatter.mapRecursiveDeclarations { declaration in
            switch declaration {
            // Organize the body of type declarations
            case let .type(kind, open, body, close, originalRange):
                let organizedType = formatter.organizeDeclaration((kind, open, body, close))
                return .type(
                    kind: organizedType.kind,
                    open: organizedType.open,
                    body: organizedType.body,
                    close: organizedType.close,
                    originalRange: originalRange
                )

            case .conditionalCompilation, .declaration:
                return declaration
            }
        }
    }
}
