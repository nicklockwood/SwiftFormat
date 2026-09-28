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
            @ViewBuilder
            var content: some View {
                Text("foo")
                Text("bar")
            }
        }
        """
        let output = """
        struct MyView: View {
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

    func testReplaceViewBuilderOnInitParameterAndStoredProperty() {
        let input = """
        struct Card<Content: View, Footer: View>: View {
            @ViewBuilder let content: Content
            let footer: () -> Footer

            init(@ViewBuilder content: () -> Content, footer: @escaping @ViewBuilder () -> Footer) {
                self.content = content()
                self.footer = footer
            }

            var body: some View {
                content
            }
        }
        """
        let output = """
        struct Card<Content: View, Footer: View>: View {
            @ContentBuilder let content: Content
            let footer: () -> Footer

            init(@ContentBuilder content: () -> Content, footer: @escaping @ContentBuilder () -> Footer) {
                self.content = content()
                self.footer = footer
            }

            var body: some View {
                content
            }
        }
        """
        let options = FormatOptions(swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .preferContentBuilder, options: options)
    }

    func testReplaceLegacyResultBuilders() {
        let input = """
        @ToolbarContentBuilder
        var toolbarItems: some ToolbarContent {}

        @CommandsBuilder
        var commands: some Commands {}

        @TabContentBuilder
        var tabs: some TabContent<Never> {}

        @KeyframeTrackContentBuilder
        var keyframes: some KeyframeTrackContent<Double> {}

        @CompositorContentBuilder
        var compositorContent: some CompositorContent {}
        """
        let output = """
        @ContentBuilder
        var toolbarItems: some ToolbarContent {}

        @ContentBuilder
        var commands: some Commands {}

        @ContentBuilder
        var tabs: some TabContent<Never> {}

        @ContentBuilder
        var keyframes: some KeyframeTrackContent<Double> {}

        @ContentBuilder
        var compositorContent: some CompositorContent {}
        """
        let options = FormatOptions(swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .preferContentBuilder, options: options)
    }

    func testDoesntReplaceResultBuildersWithGenericArguments() {
        let input = """
        @TabContentBuilder<Int>
        var tabs: some TabContent<Int> {}

        @SwiftUI.KeyframeTrackContentBuilder<Double>
        var keyframes: some KeyframeTrackContent<Double> {}
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

        @SwiftUI.ToolbarContentBuilder
        var toolbarItems: some ToolbarContent {}
        """
        let output = """
        @SwiftUI.ContentBuilder
        var content: some View {
            Text("foo")
            Text("bar")
        }

        @SwiftUI.ContentBuilder
        var toolbarItems: some ToolbarContent {}
        """
        let options = FormatOptions(swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .preferContentBuilder, options: options)
    }

    func testDoesntReplaceCustomResultBuilders() {
        let input = """
        @MyModule.ViewBuilder
        var content: some View {
            Text("foo")
        }

        @ArrayBuilder<String>
        var strings: [String] {
            "foo"
            "bar"
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
