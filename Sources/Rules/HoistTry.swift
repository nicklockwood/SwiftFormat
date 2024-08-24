//
//  HoistTry.swift
//  SwiftFormat
//
//  Created by Facundo Menzella on 2/25/23.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let hoistTry = FormatRule(
        help: "Move inline `try` keyword(s) to start of expression.",
        examples: """
        ```diff
        - foo(try bar(), try baz())
        + try foo(bar(), baz())
        ```

        ```diff
        - let foo = String(try await getFoo())
        + let foo = try String(await getFoo())
        ```
        """,
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
