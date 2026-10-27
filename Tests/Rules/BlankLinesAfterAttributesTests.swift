//
//  BlankLinesAfterAttributesTests.swift
//  SwiftFormatTests
//
//  Created by Ethan Pippin on 2026-10-26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class BlankLinesAfterAttributesTests: XCTestCase {
    func testRemovesBlankLineAfterTypeAttribute() {
        let input = """
        @MainActor

        struct Foo {}
        """
        let output = """
        @MainActor
        struct Foo {}
        """
        testFormatting(for: input, output, rule: .blankLinesAfterAttributes)
    }

    func testRemovesMultipleBlankLinesAfterAttribute() {
        let input = """
        @MainActor


        struct Foo {}
        """
        let output = """
        @MainActor
        struct Foo {}
        """
        testFormatting(for: input, output, rule: .blankLinesAfterAttributes)
    }

    func testRemovesBlankLinesBetweenSequentialAttributes() {
        let input = """
        @objc

        @MainActor

        class Foo: NSObject {}
        """
        let output = """
        @objc
        @MainActor
        class Foo: NSObject {}
        """
        testFormatting(for: input, output, rule: .blankLinesAfterAttributes)
    }

    func testRemovesBlankLineAfterAttributeWithArguments() {
        let input = """
        @available(iOS 15, *)

        func foo() {}
        """
        let output = """
        @available(iOS 15, *)
        func foo() {}
        """
        testFormatting(for: input, output, rule: .blankLinesAfterAttributes)
    }

    func testRemovesBlankLineBeforeModifiers() {
        let input = """
        @objc

        public final class Foo: NSObject {}
        """
        let output = """
        @objc
        public final class Foo: NSObject {}
        """
        testFormatting(for: input, output, rule: .blankLinesAfterAttributes)
    }

    func testRemovesBlankLineAfterPropertyAttributeInTypeBody() {
        let input = """
        struct Foo: View {
            @State

            private var count = 0

            var body: some View {
                Text("\\(count)")
            }
        }
        """
        let output = """
        struct Foo: View {
            @State
            private var count = 0

            var body: some View {
                Text("\\(count)")
            }
        }
        """
        testFormatting(for: input, output, rule: .blankLinesAfterAttributes)
    }

    func testRemovesBlankLineAfterLocalPropertyAttribute() {
        let input = """
        #Preview {
            @Previewable

            @State var count = 0
            Text("\\(count)")
        }
        """
        let output = """
        #Preview {
            @Previewable
            @State var count = 0
            Text("\\(count)")
        }
        """
        testFormatting(for: input, output, rule: .blankLinesAfterAttributes)
    }

    func testRemovesBlankLineAfterAttributeWithTrailingComment() {
        let input = """
        @MainActor // Isolated to the main actor

        struct Foo {}
        """
        let output = """
        @MainActor // Isolated to the main actor
        struct Foo {}
        """
        testFormatting(for: input, output, rule: .blankLinesAfterAttributes)
    }

    func testPreservesBlankLineBeforeComment() {
        let input = """
        @MainActor

        // TODO: Remove main actor isolation
        struct Foo {}
        """
        testFormatting(for: input, rule: .blankLinesAfterAttributes)
    }

    func testPreservesAttributesWithoutBlankLines() {
        let input = """
        @MainActor
        struct Foo {
            @State private var count = 0
        }
        """
        testFormatting(for: input, rule: .blankLinesAfterAttributes)
    }

    func testPreservesBlankLineAfterNonDeclarationAttribute() {
        let input = """
        func foo(
            @ViewBuilder

            content: () -> some View
        ) -> some View {
            content()
        }
        """
        testFormatting(for: input, rule: .blankLinesAfterAttributes)
    }
}
