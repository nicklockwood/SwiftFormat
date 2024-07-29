//
//  EmptyExtension.swift
//  SwiftFormat
//
// Created by manny_lopez on 7/29/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove empty, non-conforming, extensions.
    static let emptyExtension = FormatRule(help: "Remove empty, non-conforming, extensions.") { formatter in

        var emptyExtensions = [Declaration]()

        formatter.forEachRecursiveDeclaration { declaration in
            let declarationModifiers = Set(declaration.modifiers)
            guard let declarationBody = declaration.body,
                  declaration.keyword == "extension",
                  declarationBody.isEmpty,
                  // Ensure that the extension does not conform to any protocols
                  !declaration.openTokens.contains(where: { $0 == .delimiter(":") }),
                  // Ensure that it is not a macro
                  !(declarationModifiers.contains { $0.first == "@" })
            else { return }

            emptyExtensions.append(declaration)
        }

        for declaration in emptyExtensions.reversed() {
            print(declaration.originalRange)
            formatter.removeTokens(in: declaration.originalRange)
        }
    }
}
