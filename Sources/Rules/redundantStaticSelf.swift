//
//  RedundantStaticSelf.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove redundant Self keyword
    static let redundantStaticSelf = FormatRule(
        help: "Remove explicit `Self` where applicable."
    ) { formatter in
        formatter.addOrRemoveSelf(static: true)
    }
}
