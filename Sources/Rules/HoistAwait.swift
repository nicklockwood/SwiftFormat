//
//  HoistAwait.swift
//  SwiftFormat
//
//  Created by Facundo Menzella on 2/9/23.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Reposition `await` keyword outside of the current scope.
    static let hoistAwait = FormatRule(
        help: "Move inline `await` keyword(s) to start of expression.",
        examples: """
        ```diff
        - greet(await forename, await surname)
        + await greet(forename, surname)
        ```

        ```diff
        - let foo = String(try await getFoo())
        + let foo = await String(try getFoo())
        ```
        """,
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
