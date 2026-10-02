//
//  RedundantViewBuilder.swift
//  SwiftFormat
//
//  Created by Miguel Jimenez on 2025-12-14.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Deprecated
    static let redundantViewBuilder = FormatRule(
        help: "Remove redundant @ViewBuilder attribute when it's not needed.",
        deprecationMessage: "Use contentBuilder with `--content-builder implicit` instead."
    ) { formatter in
        formatter.removeRedundantContentBuilderAttributes()
    } examples: {
        nil
    }
}
