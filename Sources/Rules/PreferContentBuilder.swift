//
//  PreferContentBuilder.swift
//  SwiftFormat
//
//  Created by Kim Devos on 2026-09-25.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Use the SwiftUI content builder name available when building with Xcode 27 or later.
    static let preferContentBuilder = FormatRule(
        help: "Replace @ViewBuilder with @ContentBuilder for projects built with Xcode 27 or later.",
        disabledByDefault: true,
        orderAfter: [.redundantSwiftUIGroup, .redundantViewBuilder]
    ) { formatter in
        formatter.forEach(.keyword("@ViewBuilder")) { index, _ in
            formatter.replaceToken(at: index, with: .keyword("@ContentBuilder"))
        }
    } examples: {
        """
        ```diff
        - @ViewBuilder var content: some View {
        + @ContentBuilder var content: some View {
            Text("Hello")
            Text("World")
          }
        ```
        """
    }
}
