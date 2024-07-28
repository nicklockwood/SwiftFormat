//
//  hoistTry.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let hoistTry = FormatRule(
        help: "Move inline `try` keyword(s) to start of expression.",
        options: ["throwcapturing"]
    ) { formatter in
        let names = formatter.options.throwCapturing.union(["expect"])
        formatter.forEachToken(where: {
            $0 == .startOfScope("(") || $0 == .startOfScope("[")
        }) { i, _ in
            formatter.hoistEffectKeyword("try", inScopeAt: i) { prevIndex in
                guard case let .identifier(name) = formatter.tokens[prevIndex] else {
                    return false
                }
                return name.hasPrefix("XCTAssert") || formatter.isSymbol(at: prevIndex, in: names)
            }
        }
    }
}
