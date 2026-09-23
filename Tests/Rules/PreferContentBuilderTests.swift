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
        testFormatting(for: input, output, rule: .preferContentBuilder)
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
        testFormatting(for: input, output, rule: .preferContentBuilder)
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
        testFormatting(for: input, output, rule: .preferContentBuilder)
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
        testFormatting(for: input, [output], rules: [.preferContentBuilder, .redundantSwiftUIGroup, .indent])
    }
}
