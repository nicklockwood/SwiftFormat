//
//  RedundantStateInitTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 2026-06-04.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class RedundantStateInitTests: XCTestCase {
    func testRemovesRedundantStateInit() {
        let input = """
        struct MyView: View {
            init() {
                _foo = .init(initialValue: "foo")
                _foo = .init(wrappedValue: "foo")
                _baaz = .init(initialValue: MyObservableObject())
                _baaz = .init(wrappedValue: MyObservableObject())

                _foo = State(initialValue: "foo")
                _foo = State(wrappedValue: "foo")
                _baaz = ObservedObject(initialValue: MyObservableObject())
                _baaz = ObservedObject(wrappedValue: MyObservableObject())
            }

            var body: some View {}

            @State private var foo: String
            @ObservedObject private var baaz: MyObservableObject
        }
        """
        let output = """
        struct MyView: View {
            init() {
                foo = "foo"
                foo = "foo"
                baaz = MyObservableObject()
                baaz = MyObservableObject()

                foo = "foo"
                foo = "foo"
                baaz = MyObservableObject()
                baaz = MyObservableObject()
            }

            var body: some View {}

            @State private var foo: String
            @ObservedObject private var baaz: MyObservableObject
        }
        """
        testFormatting(for: input, [output], rules: [.redundantStateInit, .redundantSelf])
    }

    func testInsertsSelfWhenAssignmentWouldBeShadowed() {
        let input = """
        struct MyView: View {
            init(foo: String) {
                _foo = State(wrappedValue: foo)
            }

            var body: some View {}

            @State private var foo: String
        }
        """
        let output = """
        struct MyView: View {
            init(foo: String) {
                self.foo = foo
            }

            var body: some View {}

            @State private var foo: String
        }
        """
        testFormatting(for: input, [output], rules: [.redundantStateInit, .redundantSelf])
    }

    func testPreservesStateObjectInit() {
        let input = """
        struct MyView: View {
            init() {
                _bar = .init(wrappedValue: MyObservableObject())
                _bar = StateObject(wrappedValue: MyObservableObject())
            }

            var body: some View {}

            @StateObject private var bar: MyObservableObject
        }
        """
        testFormatting(for: input, rule: .redundantStateInit)
    }

    func testPreservesDirectAssignments() {
        let input = """
        struct MyView: View {
            init() {
                foo = "foo"
                baaz = MyObservableObject()
            }

            var body: some View {}

            @State private var foo: String
            @ObservedObject private var baaz: MyObservableObject
        }
        """
        testFormatting(for: input, rule: .redundantStateInit)
    }

    func testPreservesModuleQualifiedState() {
        let input = """
        struct MyView: View {
            init() {
                _foo = SwiftUI.State(wrappedValue: "foo")
            }

            var body: some View {}

            @State private var foo: String
        }
        """
        let output = """
        struct MyView: View {
            init() {
                foo = "foo"
            }

            var body: some View {}

            @State private var foo: String
        }
        """
        testFormatting(for: input, [output], rules: [.redundantStateInit, .redundantSelf])
    }

    func testRemovesGenericStateInit() {
        let input = """
        struct MyView: View {
            init() {
                _foo = State<String>(initialValue: "foo")
                _foo = State<String>(wrappedValue: "foo")
            }

            var body: some View {}

            @State private var foo: String
        }
        """
        let output = """
        struct MyView: View {
            init() {
                foo = "foo"
                foo = "foo"
            }

            var body: some View {}

            @State private var foo: String
        }
        """
        testFormatting(for: input, [output], rules: [.redundantStateInit, .redundantSelf])
    }

    func testPreservesUnrelatedWrapperInit() {
        let input = """
        struct MyView: View {
            init() {
                _foo = Binding(get: { "foo" }, set: { _ in })
            }

            var body: some View {}

            @Binding private var foo: String
        }
        """
        testFormatting(for: input, rule: .redundantStateInit)
    }

    func testPreservesWhenPropertyHasNoMatchingWrapper() {
        let input = """
        struct MyView: View {
            init() {
                _foo = State(wrappedValue: "foo")
            }

            var body: some View {}

            private var foo: String = ""
        }
        """
        testFormatting(for: input, rule: .redundantStateInit)
    }

    func testRewritesComplexWrappedValue() {
        let input = """
        struct MyView: View {
            init(model: Model) {
                _foo = State(wrappedValue: model.makeValue(with: 1, 2, 3))
            }

            var body: some View {}

            @State private var foo: String
        }
        """
        let output = """
        struct MyView: View {
            init(model: Model) {
                foo = model.makeValue(with: 1, 2, 3)
            }

            var body: some View {}

            @State private var foo: String
        }
        """
        testFormatting(for: input, [output], rules: [.redundantStateInit, .redundantSelf])
    }

    func testRemovesCommentOutsideValueWhenRewriting() {
        let input = """
        struct MyView: View {
            init() {
                _foo = State( /* discarded */ wrappedValue: "foo")
            }

            var body: some View {}

            @State private var foo: String
        }
        """
        let output = """
        struct MyView: View {
            init() {
                foo = "foo"
            }

            var body: some View {}

            @State private var foo: String
        }
        """
        testFormatting(for: input, [output], rules: [.redundantStateInit, .redundantSelf])
    }

    func testPreservesWhenPropertyHasDefaultValue() {
        let input = """
        struct MyView: View {
            init() {
                _foo = .init(initialValue: "foo from init")
                _foo = State(wrappedValue: "foo from init")
            }

            var body: some View {}

            @State private var foo = "foo from declaration"
        }
        """
        testFormatting(for: input, rule: .redundantStateInit)
    }

    func testDoesntRewriteRegularBackingPropertyAssignment() {
        let input = """
        struct Foo {
            init() {
                _foo = State(wrappedValue: "foo")
            }

            var _foo: String
        }
        """
        testFormatting(for: input, rule: .redundantStateInit)
    }
}
