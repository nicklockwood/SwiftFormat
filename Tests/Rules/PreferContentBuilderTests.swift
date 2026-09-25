//
//  PreferContentBuilderTests.swift
//  SwiftFormatTests
//
//  Created by Kim Devos on 2026-09-25.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class PreferContentBuilderTests: XCTestCase {
    func testRuleIsOptIn() {
        XCTAssertTrue(FormatRules.disabledByDefault.contains(.preferContentBuilder))
    }

    func testComputedPropertyAndAdjacentAttribute() {
        let input = """
        struct Example: View {
            @MainActor @ViewBuilder
            var content: some View {
                Text("Hello")
                Text("World")
            }
        }
        """
        let output = """
        struct Example: View {
            @MainActor @ContentBuilder
            var content: some View {
                Text("Hello")
                Text("World")
            }
        }
        """
        testFormatting(for: input, output, rule: .preferContentBuilder)
    }

    func testClosureParameterAndProtocolRequirement() {
        let input = """
        protocol Container {
            @ViewBuilder var content: Content { get }
            func makeContent(@ViewBuilder content: () -> Content)
        }

        struct Example {
            let content: Content

            init(@ViewBuilder content: () -> Content) {
                self.content = content()
            }
        }
        """
        let output = """
        protocol Container {
            @ContentBuilder var content: Content { get }
            func makeContent(@ContentBuilder content: () -> Content)
        }

        struct Example {
            let content: Content

            init(@ContentBuilder content: () -> Content) {
                self.content = content()
            }
        }
        """
        testFormatting(for: input, output, rule: .preferContentBuilder)
    }

    func testPreservesOtherTextAndQualifiedAttribute() {
        let input = """
        // @ViewBuilder remains in comments.
        let text = "@ViewBuilder"
        let name = ViewBuilder

        @ContentBuilder var current: some View {
            Text("Current")
        }

        @OtherViewBuilder var other: some View {
            Text("Other")
        }

        @SwiftUI.ViewBuilder var qualified: some View {
            Text("Qualified")
        }
        """
        testFormatting(for: input, rule: .preferContentBuilder)
    }

    func testRunsAfterExistingSwiftUIRules() {
        let input = """
        struct Example: View {
            @ViewBuilder var body: some View {
                Text("Body")
            }

            var content: some View {
                Group {
                    Text("Hello")
                    Text("World")
                }
            }
        }
        """
        let output = """
        struct Example: View {
            var body: some View {
                Text("Body")
            }

            @ContentBuilder
            var content: some View {
                Text("Hello")
                Text("World")
            }
        }
        """
        testFormatting(
            for: input, [output],
            rules: [.redundantSwiftUIGroup, .redundantViewBuilder, .preferContentBuilder, .indent]
        )
    }
}
