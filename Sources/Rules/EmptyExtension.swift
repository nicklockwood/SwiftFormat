//
//  EmptyExtension.swift
//  SwiftFormat
//
// Created by manny_lopez on 7/29/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove empty, non-conforming, extensions
    static let emptyExtension = FormatRule(help: "Remove empty, non-conforming, extensions") { formatter in
        var emptyExtensions = [Declaration]()
        formatter.forEachRecursiveDeclaration { declaration in
            guard case let .type(_, open, body, _, _) = declaration,
                  declaration.keyword == "extension",
                  body.isEmpty,
                  !open.contains(where: { $0 == .delimiter(":") })
            else { return }

            emptyExtensions.append(declaration)
        }

        for declaration in emptyExtensions.reversed() {
            print(declaration.originalRange)
            formatter.removeTokens(in: declaration.originalRange)
        }
    }
}
