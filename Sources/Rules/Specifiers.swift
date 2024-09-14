//
//  Specifiers.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 9/6/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Deprecated
    static let specifiers = FormatRule(
        help: "Use consistent ordering for member modifiers.",
        deprecationMessage: "Use modifierOrder instead.",
        options: ["modifierorder"]
    ) { formatter in
        _ = formatter.options.modifierOrder
        FormatRule.modifierOrder.apply(with: formatter)
    } examples: {
        nil
    }
}
