//
//  WrapArguments.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 11/23/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Normalize argument wrapping style
    static let wrapArguments = FormatRule(
        help: "Align wrapped function arguments or collection elements.",
        orderAfter: [.wrap],
        options: ["wraparguments", "wrapparameters", "wrapcollections", "closingparen", "callsiteparen",
                  "wrapreturntype", "wrapconditions", "wraptypealiases", "wrapeffects"],
        sharedOptions: ["indent", "trimwhitespace", "linebreaks",
                        "tabwidth", "maxwidth", "smarttabs", "assetliterals", "wrapternary"]
    ) { formatter in
        formatter.wrapCollectionsAndArguments(completePartialWrapping: true,
                                              wrapSingleArguments: false)
    }
}
