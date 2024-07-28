//
//  redundantStaticSelf.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

extension FormatRule {
    /// Remove redundant Self keyword
    public static let redundantStaticSelf = FormatRule(
        help: "Remove explicit `Self` where applicable."
    ) { formatter in
        formatter.addOrRemoveSelf(static: true)
    }
}
