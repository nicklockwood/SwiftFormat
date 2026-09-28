//
//  PreferContentBuilderTests.swift
//  SwiftFormatTests
//
//  Created by Miguel Jimenez on 2026-09-23.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class PreferContentBuilderTests: XCTestCase {
    func testReplaceViewBuilderOnProperty() {
        let input = """
        struct MyView: View {
            var body: some View {
                content
            }

            @ViewBuilder
            var content: some View {
                Text("foo")
                Text("bar")
            }
        }
        """
        let output = """
        struct MyView: View {
            var body: some View {
                content
            }

            @ContentBuilder
            var content: some View {
                Text("foo")
                Text("bar")
            }
        }
        """
        let options = FormatOptions(swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .preferContentBuilder, options: options)
    }

    func testDoesntReplaceViewBuilderBeforeSwift6_4() {
        let input = """
        struct MyView: View {
            var body: some View {
                content
            }

            @ViewBuilder
            var content: some View {
                Text("foo")
                Text("bar")
            }
        }
        """
        let options = FormatOptions(swiftVersion: "6.3")
        testFormatting(for: input, rule: .preferContentBuilder, options: options)
    }

    func testReplaceViewBuilderOnFunction() {
        let input = """
        @MainActor @ViewBuilder
        func makeContent(showBar: Bool) -> some View {
            Text("foo")
            if showBar {
                Text("bar")
            }
        }
        """
        let output = """
        @MainActor @ContentBuilder
        func makeContent(showBar: Bool) -> some View {
            Text("foo")
            if showBar {
                Text("bar")
            }
        }
        """
        let options = FormatOptions(swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .preferContentBuilder, options: options)
    }

    func testReplaceViewBuilderOnStoredProperty() {
        let input = """
        struct Card<Content: View>: View {
            @ViewBuilder let content: Content

            var body: some View {
                content
            }
        }
        """
        let output = """
        struct Card<Content: View>: View {
            @ContentBuilder let content: Content

            var body: some View {
                content
            }
        }
        """
        let options = FormatOptions(swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .preferContentBuilder, options: options)
    }

    func testReplaceViewBuilderOnInitParameters() {
        let input = """
        struct Card<Content: View, Footer: View>: View {
            let title: String
            let content: Content
            let footer: () -> Footer

            init(title: String, @ViewBuilder content: () -> Content, @ViewBuilder footer: @escaping () -> Footer) {
                self.title = title.uppercased()
                self.content = content()
                self.footer = footer
            }

            var body: some View {
                Text(title)
                content
                footer()
            }
        }
        """
        let output = """
        struct Card<Content: View, Footer: View>: View {
            let title: String
            let content: Content
            let footer: () -> Footer

            init(title: String, @ContentBuilder content: () -> Content, @ContentBuilder footer: @escaping () -> Footer) {
                self.title = title.uppercased()
                self.content = content()
                self.footer = footer
            }

            var body: some View {
                Text(title)
                content
                footer()
            }
        }
        """
        let options = FormatOptions(swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .preferContentBuilder, options: options)
    }

    func testReplaceToolbarContentBuilderAndCommandsBuilder() {
        let input = """
        @ToolbarContentBuilder
        var toolbarItems: some ToolbarContent {
            ToolbarItem { Button("Save") {} }
            ToolbarItem { Button("Cancel") {} }
        }

        @CommandsBuilder
        var commands: some Commands {
            CommandMenu("File") { Button("Open") {} }
            CommandMenu("Edit") { Button("Undo") {} }
        }
        """
        let output = """
        @ContentBuilder
        var toolbarItems: some ToolbarContent {
            ToolbarItem { Button("Save") {} }
            ToolbarItem { Button("Cancel") {} }
        }

        @ContentBuilder
        var commands: some Commands {
            CommandMenu("File") { Button("Open") {} }
            CommandMenu("Edit") { Button("Undo") {} }
        }
        """
        let options = FormatOptions(swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .preferContentBuilder, options: options)
    }

    func testDoesntReplaceUnsupportedResultBuilders() {
        let input = """
        @TabContentBuilder<Int>
        var tabs: some TabContent<Int> {
            Tab("Home", systemImage: "house", value: 0) { Text("Home") }
            Tab("Settings", systemImage: "gear", value: 1) { Text("Settings") }
        }

        @KeyframeTrackContentBuilder<Double>
        var keyframes: some KeyframeTrackContent<Double> {
            LinearKeyframe(1.0, duration: 0.5)
            LinearKeyframe(2.0, duration: 0.5)
        }
        """
        let options = FormatOptions(swiftVersion: "6.4")
        testFormatting(for: input, rule: .preferContentBuilder, options: options)
    }

    func testReplaceFullyQualifiedResultBuilders() {
        let input = """
        @SwiftUI.ViewBuilder
        var content: some View {
            Text("foo")
            Text("bar")
        }

        @SwiftUICore.ViewBuilder
        var otherContent: some View {
            Text("foo")
            Text("bar")
        }

        @SwiftUI.ToolbarContentBuilder
        var toolbarItems: some ToolbarContent {
            ToolbarItem { Button("Save") {} }
            ToolbarItem { Button("Cancel") {} }
        }
        """
        let output = """
        @SwiftUI.ContentBuilder
        var content: some View {
            Text("foo")
            Text("bar")
        }

        @SwiftUICore.ContentBuilder
        var otherContent: some View {
            Text("foo")
            Text("bar")
        }

        @SwiftUI.ContentBuilder
        var toolbarItems: some ToolbarContent {
            ToolbarItem { Button("Save") {} }
            ToolbarItem { Button("Cancel") {} }
        }
        """
        let options = FormatOptions(swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .preferContentBuilder, options: options)
    }

    func testDoesntReplaceCustomResultBuilderWithSameName() {
        let input = """
        enum Custom {
            @resultBuilder
            enum ViewBuilder {
                static func buildBlock(_ components: Int...) -> [Int] {
                    components
                }
            }
        }

        @Custom.ViewBuilder
        var numbers: [Int] {
            1
            2
        }
        """
        let options = FormatOptions(swiftVersion: "6.4")
        testFormatting(for: input, rule: .preferContentBuilder, options: options)
    }

    func testReplaceViewBuilderInsertedByRedundantSwiftUIGroup() {
        let input = """
        struct MyView: View {
            var body: some View {
                content
            }

            var content: some View {
                Group {
                    Text("foo")
                    Text("bar")
                }
            }
        }
        """
        let output = """
        struct MyView: View {
            var body: some View {
                content
            }

            @ContentBuilder
            var content: some View {
                Text("foo")
                Text("bar")
            }
        }
        """
        let options = FormatOptions(swiftVersion: "6.4")
        testFormatting(for: input, [output], rules: [.preferContentBuilder, .redundantSwiftUIGroup, .indent], options: options)
    }
}
