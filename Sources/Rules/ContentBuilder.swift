//
//  ContentBuilder.swift
//  SwiftFormat
//
//  Created by Ethan Pippin on 2026-09-29.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Add or remove SwiftUI result builder attributes, depending on the `--content-builder` option
    static let contentBuilder = FormatRule(
        help: "Use implicit or explicit SwiftUI result builder attributes like `@ContentBuilder`.",
        orderAfter: [.redundantSwiftUIGroup],
        options: ["content-builder"],
        sharedOptions: ["linebreaks"]
    ) { formatter in
        if formatter.options.contentBuilder.contains(.prefer) {
            formatter.replaceLegacyContentBuilderAttributes()
        }

        if formatter.options.contentBuilder.contains(.implicit) {
            formatter.removeRedundantContentBuilderAttributes()
        }

        if formatter.options.contentBuilder.contains(.explicit) {
            formatter.addExplicitContentBuilderAttributes()
        }
    } examples: {
        """
        With `--content-builder implicit` (default), removes result builder
        attributes that Swift applies implicitly, or that aren't needed:

        ```diff
          struct MyView: View {
        -   @ViewBuilder
            var body: some View {
              helper
            }

        -   @ViewBuilder
            var helper: some View {
              VStack {
                Text("baaz")
                Text("quux")
              }
            }

            // Not redundant - multiple top-level views
            @ViewBuilder
            var helper2: some View {
              Text("foo")
              Text("bar")
            }
          }
        ```

        With `--content-builder explicit`, instead adds an explicit result builder
        attribute to declarations that return SwiftUI content:

        ```diff
          struct MyView: View {
        +   @ContentBuilder
            var body: some View {
              content
            }

        +   @ContentBuilder
            var content: some View {
              if showDetail {
                Text("foo")
              }
            }

            // Not applied: an explicit `return` disables the result builder transform
            var footer: some View {
              return Text("bar")
            }
          }
        ```

        `prefer` replaces legacy result builders with the equivalent `@ContentBuilder`,
        which requires Swift 6.4 or later. It can be combined with either of the above,
        e.g. `--content-builder explicit,prefer`:

        ```diff
          struct MyView: View {
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
    /// The legacy result builder for each SwiftUI content type that `@ContentBuilder` can build.
    /// Other builders like `TabContentBuilder` and `KeyframeTrackContentBuilder` aren't supported
    /// by `@ContentBuilder`, so they're left alone.
    static let legacyContentBuilders = [
        "View": "ViewBuilder",
        "ToolbarContent": "ToolbarContentBuilder",
        "Commands": "CommandsBuilder",
    ]

    static let legacyContentBuilderNames = Set(legacyContentBuilders.values)

    /// Replaces legacy SwiftUI result builder attributes with the equivalent `@ContentBuilder`
    func replaceLegacyContentBuilderAttributes() {
        // @ContentBuilder requires the Swift 6.4 SDK (Xcode 27)
        guard options.swiftVersion >= "6.4" else { return }

        forEachToken(where: \.isAttribute) { i, _ in
            guard let nameIndex = self.indexOfLegacyContentBuilderName(forAttributeAt: i) else { return }
            if nameIndex == i {
                self.replaceToken(at: i, with: .keyword("@ContentBuilder"))
            } else {
                self.replaceToken(at: nameIndex, with: .identifier("ContentBuilder"))
            }
        }
    }

    /// If the attribute at the given index is a legacy SwiftUI result builder like `@ViewBuilder`
    /// or `@SwiftUI.ViewBuilder`, returns the index of the token containing the builder name
    func indexOfLegacyContentBuilderName(forAttributeAt attributeIndex: Int) -> Int? {
        if Formatter.legacyContentBuilderNames.contains(String(tokens[attributeIndex].string.dropFirst())) {
            return attributeIndex
        }

        guard ["@SwiftUI", "@SwiftUICore"].contains(tokens[attributeIndex].string),
              let dotIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: attributeIndex),
              tokens[dotIndex].isOperator("."),
              let nameIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: dotIndex),
              Formatter.legacyContentBuilderNames.contains(tokens[nameIndex].string)
        else { return nil }
        return nameIndex
    }

    /// Adds an explicit result builder attribute to declarations that return SwiftUI content
    func addExplicitContentBuilderAttributes() {
        parseDeclarations().forEachRecursiveDeclaration { declaration in
            guard !hasResultBuilderAttribute(declaration),
                  let target = resultBuilderTarget(of: declaration),
                  let attribute = contentBuilderAttribute(forReturnType: target.returnType),
                  scopeBodySupportsResultBuilder(at: target.scopeRange.lowerBound)
            else { return }

            insertResultBuilderAttribute(
                attribute,
                at: declaration.startOfModifiersIndex(includingAttributes: true)
            )
        }
    }

    /// The result builder attribute to apply to a declaration returning the given type, or `nil`
    /// if it isn't an opaque SwiftUI content type like `some View` that a result builder can build
    func contentBuilderAttribute(forReturnType type: TypeName) -> String? {
        guard tokens[type.range.lowerBound] == .identifier("some"),
              let nameIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: type.range.lowerBound),
              nameIndex == type.range.upperBound,
              let legacyBuilder = Formatter.legacyContentBuilders[tokens[nameIndex].string]
        else { return nil }

        // @ContentBuilder requires the Swift 6.4 SDK (Xcode 27)
        if options.contentBuilder.contains(.prefer), options.swiftVersion >= "6.4" {
            return "@ContentBuilder"
        } else {
            return "@" + legacyBuilder
        }
    }
}
