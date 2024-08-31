//
//  RedundantSelf.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 3/13/17.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Insert or remove redundant self keyword
    static let redundantSelf = FormatRule(
        help: "Insert/remove explicit `self` where applicable.",
        options: ["self", "selfrequired"]
    ) { formatter in
        _ = formatter.options.selfRequired
        _ = formatter.options.explicitSelf
        formatter.addOrRemoveSelf(static: false)
    }
}
