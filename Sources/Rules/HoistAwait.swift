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
        options: ["async-capturing"]
    ) { formatter in
        guard formatter.options.swiftVersion >= "5.5" else { return }

        var asyncCapturing = formatter.options.asyncCapturing
        formatter.forEach(.keyword("func")) { i, _ in
            guard let function = formatter.parseFunctionDeclaration(keywordIndex: i),
                  let name = function.name,
                  function.arguments.contains(where: { argument in
                      let typeTokens = argument.type.tokens
                      return typeTokens.contains(where: { $0.string == "@autoclosure" }) &&
                          typeTokens.contains(where: { $0.string == "async" })
                  })
            else { return }

            asyncCapturing.insert(name)
        }

        formatter.forEachToken(where: {
            $0 == .startOfScope("(") || $0 == .startOfScope("[")
        }) { i, _ in
            formatter.hoistEffectKeyword("await", inScopeAt: i) { prevIndex in
                formatter.isSymbol(at: prevIndex, in: asyncCapturing)
            }
        }
    } examples: {
        """
        ```diff
        - greet(await forename, await surname)
        + await greet(forename, surname)
        ```

        ```diff
        - let foo = String(try await getFoo())
        + let foo = await String(try getFoo())
        ```
        """
    }
}
