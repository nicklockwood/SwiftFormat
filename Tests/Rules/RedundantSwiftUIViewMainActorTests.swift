//
//  RedundantSwiftUIViewMainActorTests.swift
//  SwiftFormatTests
//
//  Created by Ethan Pippin on 2026-10-18.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class RedundantSwiftUIViewMainActorTests: XCTestCase {
    func testMainActorOnSeparateLine() {
        let input = """
        @MainActor
        struct FooView: View {
            var body: some View {
                Text("Hello")
            }
        }
        """
        let output = """
        struct FooView: View {
            var body: some View {
                Text("Hello")
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSwiftUIViewMainActor,
                       options: FormatOptions(swiftVersion: "6.0"))
    }

    func testMainActorOnSameLine() {
        let input = """
        @MainActor public struct FooView: View {}
        """
        let output = """
        public struct FooView: View {}
        """
        testFormatting(for: input, output, rule: .redundantSwiftUIViewMainActor,
                       options: FormatOptions(swiftVersion: "6.0"))
    }

    func testQualifiedViewConformances() {
        let input = """
        @MainActor struct FooView: SwiftUI.View {}
        @MainActor struct BarView: SwiftUICore.View {}
        @MainActor struct BazView: SwiftUI::View {}
        @MainActor struct QuxView: SwiftUICore::View {}
        """
        let output = """
        struct FooView: SwiftUI.View {}
        struct BarView: SwiftUICore.View {}
        struct BazView: SwiftUI::View {}
        struct QuxView: SwiftUICore::View {}
        """
        testFormatting(for: input, output, rule: .redundantSwiftUIViewMainActor,
                       options: FormatOptions(swiftVersion: "6.4"))
    }

    func testQualifiedMainActorAttributes() {
        let input = """
        @Swift.MainActor struct FooView: View {}
        @_Concurrency.MainActor struct BarView: View {}
        @Swift::MainActor struct BazView: View {}
        @_Concurrency::MainActor struct QuxView: View {}
        """
        let output = """
        struct FooView: View {}
        struct BarView: View {}
        struct BazView: View {}
        struct QuxView: View {}
        """
        testFormatting(for: input, output, rule: .redundantSwiftUIViewMainActor,
                       options: FormatOptions(swiftVersion: "6.4"))
    }

    func testGenericViewWithMultipleConformances() {
        let input = """
        @MainActor
        struct FooView<Content: View>: Equatable, View where Content.Body == EmptyView {
            let content: Content
        }
        """
        let output = """
        struct FooView<Content: View>: Equatable, View where Content.Body == EmptyView {
            let content: Content
        }
        """
        testFormatting(for: input, output, rule: .redundantSwiftUIViewMainActor,
                       options: FormatOptions(swiftVersion: "6.0"))
    }

    func testClassAndEnumViews() {
        let input = """
        @MainActor final class FooView: View {}
        @MainActor enum BarView: View {}
        """
        let output = """
        final class FooView: View {}
        enum BarView: View {}
        """
        testFormatting(for: input, output, rule: .redundantSwiftUIViewMainActor,
                       options: FormatOptions(swiftVersion: "6.0"))
    }

    func testNestedViewsAndConditionalCompilation() {
        let input = """
        #if canImport(SwiftUI)
            @MainActor
            struct OuterView: View {
                @MainActor
                struct InnerView: View {}
            }
        #endif
        """
        let output = """
        #if canImport(SwiftUI)
            struct OuterView: View {
                struct InnerView: View {}
            }
        #endif
        """
        testFormatting(for: input, output, rule: .redundantSwiftUIViewMainActor,
                       options: FormatOptions(swiftVersion: "6.0"))
    }

    func testOtherAttributes() {
        let input = """
        @available(iOS 18, *) @MainActor
        struct FooView: View {}

        @MainActor @available(iOS 18, *)
        struct BarView: View {}

        @available(iOS 18, *)
        @MainActor
        public struct BazView: View {}
        """
        let output = """
        @available(iOS 18, *)
        struct FooView: View {}

        @available(iOS 18, *)
        struct BarView: View {}

        @available(iOS 18, *)
        public struct BazView: View {}
        """
        testFormatting(for: input, output, rule: .redundantSwiftUIViewMainActor,
                       options: FormatOptions(swiftVersion: "6.0"))
    }

    func testPreservesComments() {
        let input = """
        /// A view.
        @MainActor // Keep this comment.
        struct FooView: View {}

        @MainActor /* Keep this too. */ struct BarView: View {}

        @MainActor
        // A comment between the attribute and declaration.
        struct BazView: View {}
        """
        let output = """
        /// A view.
        // Keep this comment.
        struct FooView: View {}

        /* Keep this too. */ struct BarView: View {}

        // A comment between the attribute and declaration.
        struct BazView: View {}
        """
        let allRulesOutput = """
        /// A view.
        /// Keep this comment.
        struct FooView: View {}

        /** Keep this too. */ struct BarView: View {}

        /// A comment between the attribute and declaration.
        struct BazView: View {}
        """
        testFormatting(for: input, [output, allRulesOutput], rules: [.redundantSwiftUIViewMainActor],
                       options: FormatOptions(swiftVersion: "6.0"))
    }

    func testPreservesCommentWithinQualifiedAttribute() {
        let input = """
        @Swift /* Keep this comment. */ .MainActor
        struct FooView: View {}
        """
        testFormatting(for: input, rule: .redundantSwiftUIViewMainActor,
                       options: FormatOptions(swiftVersion: "6.0"))
    }

    func testPreservesMemberAndNestedNonViewIsolation() {
        let input = """
        @MainActor
        struct FooView: View {
            @MainActor var body: some View {
                Text("Hello")
            }

            @MainActor func update() {}

            @MainActor
            class Model {}
        }
        """
        let output = """
        struct FooView: View {
            @MainActor var body: some View {
                Text("Hello")
            }

            @MainActor func update() {}

            @MainActor
            class Model {}
        }
        """
        testFormatting(for: input, output, rule: .redundantSwiftUIViewMainActor,
                       options: FormatOptions(swiftVersion: "6.0"))
    }

    func testPreservesExtensions() {
        let input = """
        @MainActor
        struct FooView {}

        @MainActor
        extension FooView: View {}

        @MainActor
        extension View {
            func update() {}
        }
        """
        testFormatting(for: input, rule: .redundantSwiftUIViewMainActor,
                       options: FormatOptions(swiftVersion: "6.0"))
    }

    func testPreservesUnrelatedTypesAndConstraints() {
        let input = """
        @MainActor class Model: ObservableObject {}
        @MainActor struct FooView: OtherModule.View {}
        @MainActor struct BarView: ViewModifier {}
        @MainActor struct Container<Content: View> {}
        @MainActor struct OtherContainer<Content: Collection> where Content.Element: View {}
        @MainActor protocol CustomView: View {}
        """
        testFormatting(for: input, rule: .redundantSwiftUIViewMainActor,
                       options: FormatOptions(swiftVersion: "6.0"))
    }

    func testPreservesOtherActorAndUnsafeAttributes() {
        let input = """
        @CustomActor struct FooView: View {}
        @OtherModule.MainActor struct BarView: View {}
        @MainActor (unsafe) struct BazView: View {}
        """
        testFormatting(for: input, rule: .redundantSwiftUIViewMainActor,
                       options: FormatOptions(swiftVersion: "6.0"))
    }

    func testViewWithoutAttribute() {
        let input = """
        struct FooView: View {}
        """
        testFormatting(for: input, rule: .redundantSwiftUIViewMainActor,
                       options: FormatOptions(swiftVersion: "6.0"))
    }

    func testPreservesAttributeBeforeSwift6() {
        let input = """
        @MainActor
        struct FooView: View {}
        """
        testFormatting(for: input, rule: .redundantSwiftUIViewMainActor,
                       options: FormatOptions(swiftVersion: "5.10"))
    }

    func testPreservesAttributeWithUnspecifiedSwiftVersion() {
        let input = """
        @MainActor
        struct FooView: View {}
        """
        testFormatting(for: input, rule: .redundantSwiftUIViewMainActor)
    }

    func testDisableNext() {
        let input = """
        // swiftformat:disable:next redundantSwiftUIViewMainActor
        @MainActor struct FooView: View {}
        @MainActor struct BarView: View {}
        """
        let output = """
        // swiftformat:disable:next redundantSwiftUIViewMainActor
        @MainActor struct FooView: View {}
        struct BarView: View {}
        """
        testFormatting(for: input, output, rule: .redundantSwiftUIViewMainActor,
                       options: FormatOptions(swiftVersion: "6.0"))
    }

    func testDisableNextOnSeparateLine() {
        let input = """
        // swiftformat:disable:next redundantSwiftUIViewMainActor
        @MainActor
        struct FooView: View {}

        @MainActor
        struct BarView: View {}
        """
        let output = """
        // swiftformat:disable:next redundantSwiftUIViewMainActor
        @MainActor
        struct FooView: View {}

        struct BarView: View {}
        """
        testFormatting(for: input, output, rule: .redundantSwiftUIViewMainActor,
                       options: FormatOptions(swiftVersion: "6.0"))
    }

    func testInlineSwiftVersionOption() {
        let input = """
        // swiftformat:options --swiftversion 5.10
        @MainActor struct FooView: View {}

        // swiftformat:options --swiftversion 6.0
        @MainActor struct BarView: View {}
        """
        let output = """
        // swiftformat:options --swiftversion 5.10
        @MainActor struct FooView: View {}

        // swiftformat:options --swiftversion 6.0
        struct BarView: View {}
        """
        testFormatting(for: input, output, rule: .redundantSwiftUIViewMainActor)
    }
}
