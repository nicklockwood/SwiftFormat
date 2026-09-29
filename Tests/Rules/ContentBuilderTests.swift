//
//  ContentBuilderTests.swift
//  SwiftFormatTests
//
//  Created by Miguel Jimenez on 2025-12-14.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class ContentBuilderTests: XCTestCase {
    func testRemoveRedundantViewBuilderOnViewBody() {
        let input = """
        struct MyView: View {
            @ViewBuilder
            var body: some View {
                Text("foo")
                Text("bar")
            }
        }
        """
        let output = """
        struct MyView: View {
            var body: some View {
                Text("foo")
                Text("bar")
            }
        }
        """
        testFormatting(for: input, output, rule: .contentBuilder)
    }

    func testRemoveRedundantContentBuilder() {
        let input = """
        struct MyView: View {
            @ContentBuilder
            var body: some View {
                Text("foo")
                Text("bar")
            }

            @ContentBuilder
            var helper: some View {
                Text("baaz")
            }

            @ContentBuilder
            var helper2: some View {
                Text("foo")
                Text("bar")
            }
        }
        """
        let output = """
        struct MyView: View {
            var body: some View {
                Text("foo")
                Text("bar")
            }

            var helper: some View {
                Text("baaz")
            }

            @ContentBuilder
            var helper2: some View {
                Text("foo")
                Text("bar")
            }
        }
        """
        testFormatting(for: input, output, rule: .contentBuilder)
    }

    func testRemoveRedundantViewBuilderOnViewModifierBody() {
        let input = """
        struct MyModifier: ViewModifier {
            @ViewBuilder
            func body(content: Content) -> some View {
                content
                    .foregroundColor(.red)
            }
        }
        """
        let output = """
        struct MyModifier: ViewModifier {
            func body(content: Content) -> some View {
                content
                    .foregroundColor(.red)
            }
        }
        """
        testFormatting(for: input, output, rule: .contentBuilder)
    }

    func testRemoveRedundantViewBuilderOnSingleExpression() {
        let input = """
        struct MyView: View {
            var body: some View {
                helper
            }

            @ViewBuilder
            var helper: some View {
                VStack {
                    Text("baaz")
                    Text("quux")
                }
            }
        }
        """
        let output = """
        struct MyView: View {
            var body: some View {
                helper
            }

            var helper: some View {
                VStack {
                    Text("baaz")
                    Text("quux")
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .contentBuilder)
    }

    func testRemoveRedundantViewBuilderOnSingleExpressionClosure() {
        let input = """
        struct MyView: View {
            @ViewBuilder
            var helper: some View {
                Color.red
            }
        }
        """
        let output = """
        struct MyView: View {
            var helper: some View {
                Color.red
            }
        }
        """
        testFormatting(for: input, output, rule: .contentBuilder)
    }

    func testKeepViewBuilderWithMultipleTopLevelViews() {
        let input = """
        struct MyView: View {
            @ViewBuilder
            var helper: some View {
                Text("foo")
                Text("bar")
            }
        }
        """
        testFormatting(for: input, rule: .contentBuilder)
    }

    func testKeepViewBuilderWithIfElseExpression() {
        let input = """
        struct MyView: View {
            @ViewBuilder
            var helper: some View {
                if condition {
                    Text("foo")
                } else {
                    Image("bar")
                }
            }
        }
        """
        testFormatting(for: input, rule: .contentBuilder)
    }

    func testKeepViewBuilderWithSwitchExpression() {
        let input = """
        struct MyView: View {
            @ViewBuilder
            var helper: some View {
                switch value {
                case .foo:
                    Text("foo")
                case .bar:
                    Image("bar")
                }
            }
        }
        """
        testFormatting(for: input, rule: .contentBuilder)
    }

    func testKeepViewBuilderWithForEachAndViews() {
        let input = """
        struct MyView: View {
            @ViewBuilder
            var helper: some View {
                ForEach(items) { item in
                    Text(item.name)
                }
                Divider()
            }
        }
        """
        testFormatting(for: input, rule: .contentBuilder)
    }

    func testRemoveRedundantViewBuilderBeforeComputedProperty() {
        let input = """
        struct MyView: View {
            @ViewBuilder var body: some View {
                Text("Hello")
            }
        }
        """
        let output = """
        struct MyView: View {
            var body: some View {
                Text("Hello")
            }
        }
        """
        testFormatting(for: input, output, rule: .contentBuilder)
    }

    func testKeepViewBuilderOnNonBodyProperty() {
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
        testFormatting(for: input, rule: .contentBuilder)
    }

    func testRemoveRedundantViewBuilderInNestedType() {
        let input = """
        struct OuterView: View {
            var body: some View {
                InnerView()
            }

            struct InnerView: View {
                @ViewBuilder
                var body: some View {
                    Text("Inner")
                }
            }
        }
        """
        let output = """
        struct OuterView: View {
            var body: some View {
                InnerView()
            }

            struct InnerView: View {
                var body: some View {
                    Text("Inner")
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .contentBuilder)
    }

    func testKeepViewBuilderOnPropertyWithModifier() {
        let input = """
        struct MyView: View {
            @ViewBuilder
            private var content: some View {
                Text("foo")
                Text("bar")
            }
        }
        """
        testFormatting(for: input, rule: .contentBuilder)
    }

    func testRemoveRedundantViewBuilderWithComplexSingleExpression() {
        let input = """
        struct MyView: View {
            @ViewBuilder
            var helper: some View {
                Text("Hello")
                    .font(.title)
                    .foregroundColor(.blue)
                    .padding()
            }
        }
        """
        let output = """
        struct MyView: View {
            var helper: some View {
                Text("Hello")
                    .font(.title)
                    .foregroundColor(.blue)
                    .padding()
            }
        }
        """
        testFormatting(for: input, output, rule: .contentBuilder)
    }

    func testKeepViewBuilderOnHelperFuncWithIfWithoutElse() {
        let input = """
        struct Foo: View {
            var body: some View {
                if let bar {
                    baz(bar: bar)
                }
            }

            @ViewBuilder
            func baz(bar: Bar) -> some View {
                if bar.useA {
                    ViewA()
                }
            }
        }
        """
        testFormatting(for: input, rule: .contentBuilder)
    }

    func testKeepViewBuilderOnFuncNamedBodyInView() {
        // A function named "body" in a View is NOT the View.body protocol requirement
        // (which must be a property), so @ViewBuilder should be preserved if needed
        let input = """
        struct Foo: View {
            var body: some View {
                if let bar {
                    body(bar: bar)
                }
            }

            @ViewBuilder
            func body(bar: Bar) -> some View {
                if bar.useA {
                    ViewA()
                }
            }
        }
        """
        testFormatting(for: input, rule: .contentBuilder)
    }

    func testKeepViewBuilderOnVarNamedBodyInViewModifier() {
        // A property named "body" in a ViewModifier is NOT the ViewModifier.body protocol requirement
        // (which must be a function), so @ViewBuilder should be preserved if needed
        let input = """
        struct Foo: ViewModifier {
            func body(content: Content) -> some View {
                content
                    .overlay(overlay)
            }

            @ViewBuilder
            var body: some View {
                if condition {
                    ViewA()
                }
            }
        }
        """
        testFormatting(for: input, rule: .contentBuilder)
    }

    func testRemoveRedundantViewBuilderAfterMainActorOnSameLine() {
        let input = """
        struct MyView: View {
            var body: some View {
                testView()
            }

            @MainActor @ViewBuilder
            func testView() -> some View {
                Text("Hello")
            }
        }
        """
        let output = """
        struct MyView: View {
            var body: some View {
                testView()
            }

            @MainActor
            func testView() -> some View {
                Text("Hello")
            }
        }
        """
        testFormatting(for: input, output, rule: .contentBuilder)
    }

    func testRemoveRedundantViewBuilderAfterMainActorOnSameLineAsDeclaration() {
        let input = """
        struct MyView: View {
            var body: some View {
                testView()
            }

            @MainActor @ViewBuilder func testView() -> some View {
                Text("Hello")
            }
        }
        """
        let output = """
        struct MyView: View {
            var body: some View {
                testView()
            }

            @MainActor func testView() -> some View {
                Text("Hello")
            }
        }
        """
        testFormatting(for: input, output, rule: .contentBuilder)
    }

    func testRemoveRedundantViewBuilderBeforeMainActorOnSameLine() {
        let input = """
        struct MyView: View {
            var body: some View {
                testView()
            }

            @ViewBuilder @MainActor
            func testView() -> some View {
                Text("Hello")
            }
        }
        """
        let output = """
        struct MyView: View {
            var body: some View {
                testView()
            }

            @MainActor
            func testView() -> some View {
                Text("Hello")
            }
        }
        """
        testFormatting(for: input, output, rule: .contentBuilder)
    }

    func testRemoveRedundantViewBuilderBeforeMainActorOnSameLineAsDeclaration() {
        let input = """
        struct MyView: View {
            var body: some View {
                testView()
            }

            @ViewBuilder @MainActor func testView() -> some View {
                Text("Hello")
            }
        }
        """
        let output = """
        struct MyView: View {
            var body: some View {
                testView()
            }

            @MainActor func testView() -> some View {
                Text("Hello")
            }
        }
        """
        testFormatting(for: input, output, rule: .contentBuilder)
    }

    func testRemoveRedundantViewBuilderAfterMainActorOnSeparateLines() {
        let input = """
        struct MyView: View {
            var body: some View {
                testView()
            }

            @MainActor
            @ViewBuilder
            func testView() -> some View {
                Text("Hello")
            }
        }
        """
        let output = """
        struct MyView: View {
            var body: some View {
                testView()
            }

            @MainActor
            func testView() -> some View {
                Text("Hello")
            }
        }
        """
        testFormatting(for: input, output, rule: .contentBuilder)
    }

    func testRemoveRedundantViewBuilderBeforeMainActorOnSeparateLines() {
        let input = """
        struct MyView: View {
            var body: some View {
                testView()
            }

            @ViewBuilder
            @MainActor
            func testView() -> some View {
                Text("Hello")
            }
        }
        """
        let output = """
        struct MyView: View {
            var body: some View {
                testView()
            }

            @MainActor
            func testView() -> some View {
                Text("Hello")
            }
        }
        """
        testFormatting(for: input, output, rule: .contentBuilder)
    }

    func testKeepViewBuilderOnProtocolMember() {
        // Protocol members with @ViewBuilder should not have it removed,
        // as conforming types rely on the implicit result builder
        let input = """
        protocol Foo {
            associatedtype MyFoo: View

            @ViewBuilder
            var myBody: MyFoo { get }
        }
        """
        testFormatting(for: input, rule: .contentBuilder)
    }

    func testKeepViewBuilderOnProtocolFunction() {
        let input = """
        protocol ViewProvider {
            @ViewBuilder
            func makeView() -> some View
        }
        """
        testFormatting(for: input, rule: .contentBuilder)
    }

    func testKeepViewBuilderOnProtocolComputedProperty() {
        let input = """
        protocol ContentProvider {
            @ViewBuilder
            var content: some View { get }
        }

        struct MyContent: ContentProvider {
            var content: some View {
                Text("Hello")
                Text("World")
            }
        }
        """
        testFormatting(for: input, rule: .contentBuilder)
    }

    func testAddsContentBuilderToProperty() {
        let input = """
        struct MyView: View {
            var body: some View {
                content
            }

            var content: some View {
                Text("foo")
            }
        }
        """
        let output = """
        struct MyView: View {
            @ContentBuilder
            var body: some View {
                content
            }

            @ContentBuilder
            var content: some View {
                Text("foo")
            }
        }
        """
        let options = FormatOptions(contentBuilder: .explicit, swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .contentBuilder, options: options)
    }

    func testAddsContentBuilderToFunctionAndSubscript() {
        let input = """
        extension MyView {
            func makeContent(showBar: Bool) -> some View {
                if showBar {
                    Text("bar")
                }
            }

            subscript(index: Int) -> some View {
                Text("\\(index)")
            }
        }
        """
        let output = """
        extension MyView {
            @ContentBuilder
            func makeContent(showBar: Bool) -> some View {
                if showBar {
                    Text("bar")
                }
            }

            @ContentBuilder
            subscript(index: Int) -> some View {
                Text("\\(index)")
            }
        }
        """
        let options = FormatOptions(contentBuilder: .explicit, swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .contentBuilder, options: options)
    }

    func testAddsContentBuilderToOtherContentTypes() {
        let input = """
        struct MyView: View {
            var toolbarItems: some ToolbarContent {
                ToolbarItem { Button("Save") {} }
            }

            var commands: some Commands {
                CommandMenu("Help") {}
            }
        }
        """
        let output = """
        struct MyView: View {
            @ContentBuilder
            var toolbarItems: some ToolbarContent {
                ToolbarItem { Button("Save") {} }
            }

            @ContentBuilder
            var commands: some Commands {
                CommandMenu("Help") {}
            }
        }
        """
        let options = FormatOptions(contentBuilder: .explicit, swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .contentBuilder, options: options)
    }

    func testAddsContentBuilderToTopLevelDeclarations() {
        let input = """
        var content: some View {
            Text("foo")
        }

        func makeContent() -> some View {
            Text("bar")
        }
        """
        let output = """
        @ContentBuilder
        var content: some View {
            Text("foo")
        }

        @ContentBuilder
        func makeContent() -> some View {
            Text("bar")
        }
        """
        let options = FormatOptions(contentBuilder: .explicit, swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .contentBuilder, options: options)
    }

    func testAddsContentBuilderToStaticAndClassMembers() {
        let input = """
        enum MyViews {
            static var placeholder: some View {
                Text("foo")
            }

            static func makeContent() -> some View {
                Text("bar")
            }
        }

        class MyOtherViews {
            class var placeholder: some View {
                Text("baaz")
            }

            class func makeContent() -> some View {
                Text("quux")
            }
        }
        """
        let output = """
        enum MyViews {
            @ContentBuilder
            static var placeholder: some View {
                Text("foo")
            }

            @ContentBuilder
            static func makeContent() -> some View {
                Text("bar")
            }
        }

        class MyOtherViews {
            @ContentBuilder
            class var placeholder: some View {
                Text("baaz")
            }

            @ContentBuilder
            class func makeContent() -> some View {
                Text("quux")
            }
        }
        """
        let options = FormatOptions(contentBuilder: .explicit, swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .contentBuilder, options: options)
    }

    func testAddsContentBuilderToMembersOfNestedTypes() {
        let input = """
        struct Outer: View {
            var body: some View {
                Inner()
            }

            struct Inner: View {
                var body: some View {
                    Text("foo")
                }
            }
        }
        """
        let output = """
        struct Outer: View {
            @ContentBuilder
            var body: some View {
                Inner()
            }

            struct Inner: View {
                @ContentBuilder
                var body: some View {
                    Text("foo")
                }
            }
        }
        """
        let options = FormatOptions(contentBuilder: .explicit, swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .contentBuilder, options: options)
    }

    func testAddsContentBuilderToGenericFunctionWithWhereClause() {
        let input = """
        extension MyView {
            func rows<C: Collection>(_ items: C) -> some View where C.Element: View {
                Text("Rows")
                ForEach(Array(items), id: \\.self) { item in
                    item
                }
            }
        }
        """
        let output = """
        extension MyView {
            @ContentBuilder
            func rows<C: Collection>(_ items: C) -> some View where C.Element: View {
                Text("Rows")
                ForEach(Array(items), id: \\.self) { item in
                    item
                }
            }
        }
        """
        let options = FormatOptions(contentBuilder: .explicit, swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .contentBuilder, options: options)
    }

    func testAddsContentBuilderToSubscriptWithExplicitGetter() {
        let input = """
        extension MyView {
            subscript(index: Int) -> some View {
                get {
                    Text("\\(index)")
                }
            }
        }
        """
        let output = """
        extension MyView {
            @ContentBuilder
            subscript(index: Int) -> some View {
                get {
                    Text("\\(index)")
                }
            }
        }
        """
        let options = FormatOptions(contentBuilder: .explicit, swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .contentBuilder,
                       options: options, exclude: [.redundantGet])
    }

    func testAddsContentBuilderToFunctionsReturningOtherContentTypes() {
        let input = """
        extension MyView {
            func toolbarItems() -> some ToolbarContent {
                ToolbarItem { Button("Save") {} }
                ToolbarItem { Button("Cancel") {} }
            }

            func commands() -> some Commands {
                CommandMenu("Help") {}
            }
        }
        """
        let output = """
        extension MyView {
            @ContentBuilder
            func toolbarItems() -> some ToolbarContent {
                ToolbarItem { Button("Save") {} }
                ToolbarItem { Button("Cancel") {} }
            }

            @ContentBuilder
            func commands() -> some Commands {
                CommandMenu("Help") {}
            }
        }
        """
        let options = FormatOptions(contentBuilder: .explicit, swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .contentBuilder, options: options)
    }

    func testAddsContentBuilderBeforeExistingAttributes() {
        let input = """
        @MainActor private var content: some View {
            Text("foo")
        }
        """
        let output = """
        @ContentBuilder
        @MainActor private var content: some View {
            Text("foo")
        }
        """
        let options = FormatOptions(contentBuilder: .explicit, swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .contentBuilder, options: options)
    }

    func testAddsContentBuilderToExplicitGetter() {
        let input = """
        var content: some View {
            get {
                Text("foo")
            }
        }
        """
        let output = """
        @ContentBuilder
        var content: some View {
            get {
                Text("foo")
            }
        }
        """
        let options = FormatOptions(contentBuilder: .explicit, swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .contentBuilder,
                       options: options, exclude: [.redundantGet])
    }

    func testPreservesReturnInNestedClosure() {
        let input = """
        var content: some View {
            Button(action: { return performAction() }) {
                Text("foo")
            }
        }
        """
        let output = """
        @ContentBuilder
        var content: some View {
            Button(action: { return performAction() }) {
                Text("foo")
            }
        }
        """
        let options = FormatOptions(contentBuilder: .explicit, swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .contentBuilder,
                       options: options, exclude: [.redundantReturn])
    }

    func testAddsContentBuilderToSwitchBodyAndBuilderParameter() {
        let input = """
        struct MyView: View {
            var body: some View {
                switch state {
                case .loading:
                    ProgressView()
                case .loaded:
                    content { Text("foo") }
                }
            }

            func content(@ViewBuilder label: () -> some View) -> some View {
                label()
            }
        }
        """
        let output = """
        struct MyView: View {
            @ContentBuilder
            var body: some View {
                switch state {
                case .loading:
                    ProgressView()
                case .loaded:
                    content { Text("foo") }
                }
            }

            @ContentBuilder
            func content(@ContentBuilder label: () -> some View) -> some View {
                label()
            }
        }
        """
        let options = FormatOptions(contentBuilder: .explicit, swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .contentBuilder, options: options)
    }

    func testPreservesReturnInNestedDeclarations() {
        let input = """
        struct MyView: View {
            var body: some View {
                func label(for value: Int) -> String {
                    return "\\(value)"
                }

                var subtitle: String {
                    return "foo"
                }

                Text(label(for: 1))
                Text(subtitle)
            }
        }
        """
        let output = """
        struct MyView: View {
            @ContentBuilder
            var body: some View {
                func label(for value: Int) -> String {
                    return "\\(value)"
                }

                var subtitle: String {
                    return "foo"
                }

                Text(label(for: 1))
                Text(subtitle)
            }
        }
        """
        let options = FormatOptions(contentBuilder: .explicit, swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .contentBuilder,
                       options: options, exclude: [.redundantReturn, .redundantProperty])
    }

    func testPreservesUnsupportedStatementsInNestedDeclarations() {
        let input = """
        struct MyView: View {
            var body: some View {
                func titles(for values: [Int]) -> [String] {
                    var result = [String]()
                    for value in values {
                        guard value > 0 else { continue }

                        result.append("\\(value)")
                    }
                    return result
                }

                ForEach(titles(for: values), id: \\.self) { title in
                    Text(title)
                }
            }
        }
        """
        let output = """
        struct MyView: View {
            @ContentBuilder
            var body: some View {
                func titles(for values: [Int]) -> [String] {
                    var result = [String]()
                    for value in values {
                        guard value > 0 else { continue }

                        result.append("\\(value)")
                    }
                    return result
                }

                ForEach(titles(for: values), id: \\.self) { title in
                    Text(title)
                }
            }
        }
        """
        let options = FormatOptions(contentBuilder: .explicit, swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .contentBuilder, options: options)
    }

    func testDoesntAddContentBuilderWithReturnInConditionalBinding() {
        let input = """
        struct MyView: View {
            var body: some View {
                if let title, !title.isEmpty {
                    return AnyView(Text(title))
                }

                return AnyView(EmptyView())
            }
        }
        """
        let options = FormatOptions(contentBuilder: .explicit, swiftVersion: "6.4")
        testFormatting(for: input, rule: .contentBuilder, options: options)
    }

    func testDoesntAddContentBuilderWithReturnInSwitchCase() {
        let input = """
        struct MyView: View {
            var body: some View {
                switch state {
                case let .loaded(value):
                    return AnyView(Text(value))
                case .loading:
                    return AnyView(ProgressView())
                }
            }
        }
        """
        let options = FormatOptions(contentBuilder: .explicit, swiftVersion: "6.4")
        testFormatting(for: input, rule: .contentBuilder, options: options,
                       exclude: [.redundantReturn])
    }

    func testDoesntAddContentBuilderToBodyWithExplicitReturn() {
        let input = """
        struct MyView: View {
            var body: some View {
                let title = "foo"
                return Text(title)
            }

            func makeContent(showBar: Bool) -> some View {
                if showBar {
                    return AnyView(Text("bar"))
                } else {
                    return AnyView(EmptyView())
                }
            }
        }
        """
        let options = FormatOptions(contentBuilder: .explicit, swiftVersion: "6.4")
        testFormatting(for: input, rule: .contentBuilder, options: options)
    }

    func testDoesntAddContentBuilderToBodyWithUnsupportedStatements() {
        let input = """
        struct MyView: View {
            var body: some View {
                for item in items {
                    Text(item)
                }
            }

            var list: some View {
                do {
                    try validate()
                } catch {}
                VStack {}
            }

            var guarded: some View {
                guard isEnabled else { fatalError() }

                Text("foo")
            }
        }
        """
        let options = FormatOptions(contentBuilder: .explicit, swiftVersion: "6.4")
        testFormatting(for: input, rule: .contentBuilder, options: options,
                       exclude: [.wrapLoopBodies])
    }

    func testDoesntAddContentBuilderWhenAlreadyPresent() {
        let input = """
        struct MyView: View {
            @ViewBuilder
            var content: some View {
                Text("foo")
            }

            @ContentBuilder
            var other: some View {
                Text("bar")
            }

            @ToolbarContentBuilder
            var toolbarItems: some ToolbarContent {
                ToolbarItem { Button("Save") {} }
            }
        }
        """
        let output = """
        struct MyView: View {
            @ContentBuilder
            var content: some View {
                Text("foo")
            }

            @ContentBuilder
            var other: some View {
                Text("bar")
            }

            @ContentBuilder
            var toolbarItems: some ToolbarContent {
                ToolbarItem { Button("Save") {} }
            }
        }
        """
        let options = FormatOptions(contentBuilder: .explicit, swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .contentBuilder, options: options)
    }

    func testDoesntAddContentBuilderToNonContentTypes() {
        let input = """
        struct MyView: View {
            var title: String {
                "foo"
            }

            var shape: some Shape {
                Circle()
            }

            func makeText() -> Text {
                Text("foo")
            }
        }
        """
        let options = FormatOptions(contentBuilder: .explicit, swiftVersion: "6.4")
        testFormatting(for: input, rule: .contentBuilder, options: options)
    }

    func testDoesntAddContentBuilderToStoredPropertyOrSetter() {
        let input = """
        struct MyView: View {
            var stored: some View = Text("foo")

            var observed: some View = Text("bar") {
                didSet { update() }
            }

            var settable: some View {
                get { storage }
                set { storage = newValue }
            }
        }
        """
        let options = FormatOptions(contentBuilder: .explicit, swiftVersion: "6.4")
        testFormatting(for: input, rule: .contentBuilder, options: options,
                       exclude: [.propertyTypes, .redundantType])
    }

    func testDoesntAddContentBuilderToProtocolRequirement() {
        let input = """
        protocol ContentProviding {
            var content: some View { get }

            func makeContent() -> some View
        }
        """
        let options = FormatOptions(contentBuilder: .explicit, swiftVersion: "6.4")
        testFormatting(for: input, rule: .contentBuilder, options: options)
    }

    func testDoesntAddContentBuilderBeforeSwift6_4() {
        let input = """
        struct MyView: View {
            var body: some View {
                Text("foo")
            }
        }
        """
        let options = FormatOptions(contentBuilder: .explicit, swiftVersion: "6.3")
        testFormatting(for: input, rule: .contentBuilder, options: options)
    }

    func testReplacesViewBuilderOnProperty() {
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
        let options = FormatOptions(contentBuilder: .prefer, swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .contentBuilder, options: options)
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
        let options = FormatOptions(contentBuilder: .prefer, swiftVersion: "6.3")
        testFormatting(for: input, rule: .contentBuilder, options: options)
    }

    func testReplacesViewBuilderOnFunction() {
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
        let options = FormatOptions(contentBuilder: .prefer, swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .contentBuilder, options: options)
    }

    func testReplacesViewBuilderOnStoredProperty() {
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
        let options = FormatOptions(contentBuilder: .prefer, swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .contentBuilder, options: options)
    }

    func testReplacesViewBuilderOnInitParameters() {
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
        let options = FormatOptions(contentBuilder: .prefer, swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .contentBuilder, options: options)
    }

    func testReplacesToolbarContentBuilderAndCommandsBuilder() {
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
        let options = FormatOptions(contentBuilder: .prefer, swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .contentBuilder, options: options)
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
        let options = FormatOptions(contentBuilder: .prefer, swiftVersion: "6.4")
        testFormatting(for: input, rule: .contentBuilder, options: options)
    }

    func testReplacesFullyQualifiedResultBuilders() {
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
        let options = FormatOptions(contentBuilder: .prefer, swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .contentBuilder, options: options)
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
        let options = FormatOptions(contentBuilder: .prefer, swiftVersion: "6.4")
        testFormatting(for: input, rule: .contentBuilder, options: options)
    }

    func testReplacesViewBuilderInsertedByRedundantSwiftUIGroup() {
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
        let options = FormatOptions(contentBuilder: .prefer, swiftVersion: "6.4")
        testFormatting(for: input, [output], rules: [.contentBuilder, .redundantSwiftUIGroup, .indent], options: options)
    }

    func testExplicitModeAlsoReplacesLegacyBuilders() {
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
            @ContentBuilder
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
        let options = FormatOptions(contentBuilder: .explicit, swiftVersion: "6.4")
        testFormatting(for: input, output, rule: .contentBuilder, options: options)
    }

    func testImplicitModeDoesntReplaceLegacyBuilders() {
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
        let options = FormatOptions(contentBuilder: .implicit, swiftVersion: "6.4")
        testFormatting(for: input, rule: .contentBuilder, options: options)
    }
}
