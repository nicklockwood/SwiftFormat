//
//  PreferContentBuilder.swift
//  SwiftFormat
//
//  Created by Miguel Jimenez on 2026-09-23.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Replace legacy SwiftUI result builder attributes with the equivalent @ContentBuilder
    static let preferContentBuilder = FormatRule(
        help: "Replace legacy SwiftUI result builder attributes like `@ViewBuilder` with the equivalent `@ContentBuilder`.",
        orderAfter: [.redundantSwiftUIGroup]
    ) { formatter in
        // @ContentBuilder requires the Swift 6.4 SDK (Xcode 27)
        guard formatter.options.swiftVersion >= "6.4" else { return }

        formatter.forEachToken(where: \.isAttribute) { i, _ in
            guard let nameIndex = formatter.indexOfLegacyContentBuilderName(forAttributeAt: i) else { return }
            if nameIndex == i {
                formatter.replaceToken(at: i, with: .keyword("@ContentBuilder"))
            } else {
                formatter.replaceToken(at: nameIndex, with: .identifier("ContentBuilder"))
            }
        }
    } examples: {
        """
        ```diff
          struct MyView: View {
            var body: some View {
              NavigationStack {
                content
              }
              .toolbar { toolbarItems }
            }

        -   @ViewBuilder
        +   @ContentBuilder
            var content: some View {
              Text("foo")
              Text("bar")
            }

        -   @ToolbarContentBuilder
        +   @ContentBuilder
            var toolbarItems: some ToolbarContent {
              ToolbarItem { Button("Save") {} }
              ToolbarItem { Button("Cancel") {} }
            }
          }
        ```
        """
    }
}

extension Formatter {
    /// SwiftUI result builders that `@ContentBuilder` can replace. Other builders like
    /// `TabContentBuilder` and `KeyframeTrackContentBuilder` aren't supported by `@ContentBuilder`.
    static let legacyContentBuilders: Set<String> = [
        "ViewBuilder",
        "ToolbarContentBuilder",
        "CommandsBuilder",
    ]

    /// If the attribute at the given index is a legacy SwiftUI result builder like `@ViewBuilder`
    /// or `@SwiftUI.ViewBuilder`, returns the index of the token containing the builder name
    func indexOfLegacyContentBuilderName(forAttributeAt attributeIndex: Int) -> Int? {
        if Formatter.legacyContentBuilders.contains(String(tokens[attributeIndex].string.dropFirst())) {
            return attributeIndex
        }

        guard ["@SwiftUI", "@SwiftUICore"].contains(tokens[attributeIndex].string),
              let dotIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: attributeIndex),
              tokens[dotIndex].isOperator("."),
              let nameIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: dotIndex),
              Formatter.legacyContentBuilders.contains(tokens[nameIndex].string)
        else { return nil }
        return nameIndex
    }
}
