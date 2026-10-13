//
//  UnusedPrivateDeclarations.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 10/11/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Deprecated
    static let unusedPrivateDeclarations = FormatRule(
        help: "Remove unused private and fileprivate declarations.",
        renamedTo: .unusedDeclarations,
        disabledByDefault: true
    ) { formatter in
        FormatRule.unusedDeclarations.apply(with: formatter)
    } examples: {
        nil
    }
}
