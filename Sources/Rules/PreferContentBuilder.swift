//
//  PreferContentBuilder.swift
//  SwiftFormat
//
//  Created by Miguel Jimenez on 2026-09-23.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Replace @ViewBuilder with the equivalent @ContentBuilder
    static let preferContentBuilder = FormatRule(
        help: "Replace `@ViewBuilder` with the equivalent `@ContentBuilder` attribute (requires Xcode 27 or later).",
        disabledByDefault: true,
        orderAfter: [.redundantSwiftUIGroup]
    ) { formatter in
        formatter.forEach(.keyword("@ViewBuilder")) { i, _ in
            formatter.replaceToken(at: i, with: .keyword("@ContentBuilder"))
        }
    } examples: {
        """
        ```diff
          struct MyView: View {
        -   @ViewBuilder
        +   @ContentBuilder
            var content: some View {
              Text("foo")
              Text("bar")
            }
          }
        ```
        """
    }
}
