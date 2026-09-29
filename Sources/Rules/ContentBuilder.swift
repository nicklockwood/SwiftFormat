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
        help: "Use implicit or explicit SwiftUI result builder attributes like `@ViewBuilder`.",
        orderAfter: [.redundantSwiftUIGroup, .preferContentBuilder],
        options: ["content-builder"],
        sharedOptions: ["linebreaks"]
    ) { formatter in
        switch formatter.options.contentBuilder {
        case .implicit:
            formatter.removeRedundantContentBuilderAttributes()
        case .explicit:
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

        With `--content-builder explicit`, instead adds an explicit
        `@ContentBuilder` attribute to declarations that return SwiftUI content
        (requires Swift 6.4 or later):

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
        """
    }
}

extension Formatter {
    /// SwiftUI content types that `@ContentBuilder` can build
    static let contentBuilderResultTypes: Set<String> = [
        "View",
        "ToolbarContent",
        "Commands",
    ]

    /// Adds an explicit `@ContentBuilder` attribute to declarations that return SwiftUI content
    func addExplicitContentBuilderAttributes() {
        // @ContentBuilder requires the Swift 6.4 SDK (Xcode 27)
        guard options.swiftVersion >= "6.4" else { return }

        parseDeclarations().forEachRecursiveDeclaration { declaration in
            guard !hasResultBuilderAttribute(declaration),
                  let target = resultBuilderTarget(of: declaration),
                  isContentBuilderResultType(target.returnType),
                  scopeBodySupportsResultBuilder(at: target.scopeRange.lowerBound)
            else { return }

            insertResultBuilderAttribute(
                "@ContentBuilder",
                at: declaration.startOfModifiersIndex(includingAttributes: true)
            )
        }
    }

    /// Whether the given type is an opaque SwiftUI content type like `some View`
    func isContentBuilderResultType(_ type: TypeName) -> Bool {
        guard tokens[type.range.lowerBound] == .identifier("some"),
              let nameIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: type.range.lowerBound),
              nameIndex == type.range.upperBound
        else { return false }

        return Formatter.contentBuilderResultTypes.contains(tokens[nameIndex].string)
    }
}
