//
//  redundantSelf.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

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
