//
//  hoistAwait.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

public extension FormatRule {
    /// Reposition `await` keyword outside of the current scope.
    static let hoistAwait = FormatRule(
        help: "Move inline `await` keyword(s) to start of expression.",
        options: ["asynccapturing"]
    ) { formatter in
        guard formatter.options.swiftVersion >= "5.5" else { return }

        formatter.forEachToken(where: {
            $0 == .startOfScope("(") || $0 == .startOfScope("[")
        }) { i, _ in
            formatter.hoistEffectKeyword("await", inScopeAt: i) { prevIndex in
                formatter.isSymbol(at: prevIndex, in: formatter.options.asyncCapturing)
            }
        }
    }
}
