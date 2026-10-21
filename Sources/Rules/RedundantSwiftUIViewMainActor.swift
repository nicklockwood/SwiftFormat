//
//  RedundantSwiftUIViewMainActor.swift
//  SwiftFormat
//
//  Created by Ethan Pippin on 2026-10-18.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove redundant main actor isolation from SwiftUI view types.
    static let redundantSwiftUIViewMainActor = FormatRule(
        help: "Remove redundant @MainActor attributes from types that conform to SwiftUI.View.",
        disabledByDefault: true
    ) { formatter in
        formatter.parseDeclarations().forEachRecursiveDeclaration { declaration in
            // Conformances declared in extensions don't imply isolation of the whole type.
            guard let type = declaration.asTypeDeclaration,
                  ["struct", "class", "enum"].contains(type.keyword),
                  type.conformances.contains(where: {
                      ["View", "SwiftUI.View", "SwiftUICore.View", "SwiftUI::View", "SwiftUICore::View"]
                          .contains($0.conformance.string)
                  }),
                  let attributeIndex = ["@MainActor", "@Swift.MainActor", "@_Concurrency.MainActor",
                                        "@Swift::MainActor", "@_Concurrency::MainActor"]
                      .compactMap({ formatter.indexOfModifier($0, forDeclarationAt: type.keywordIndex) }).first
            else { return }

            // A line-scoped directive can disable the attribute without disabling the type keyword.
            formatter.updateEnablement(at: attributeIndex)
            // View inherits @MainActor isolation starting with the Swift 6.0 SDK (Xcode 16).
            guard formatter.isEnabled(at: attributeIndex),
                  formatter.options.swiftVersion >= "6.0"
            else { return }

            formatter.removeAttributeWithLinebreak(at: attributeIndex)
        }
    } examples: {
        """
        Requires Swift 6.0 or later, using the SwiftUI SDK from Xcode 16 or later.
        Only direct `View` conformances on a type declaration are considered.

        ```diff
        - @MainActor
          struct FooView: View {
              var body: some View { Text("Hello") }
          }

        - @MainActor struct BarView: View {
        + struct BarView: View {
              var body: some View { Text("World") }
          }
        ```
        """
    }
}
