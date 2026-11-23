//
//  PreferOnChangeZeroArgumentTests.swift
//  SwiftFormatTests
//
//  Created by Miguel Jimenez on 2026-11-20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class PreferOnChangeZeroArgumentTests: XCTestCase {
    func testRemovesUnusedArguments() {
        let input = """
        content
            .onChange(of: store.items) { _, _ in
                scrollToBottom()
            }
        """
        let output = """
        content
            .onChange(of: store.items) {
                scrollToBottom()
            }
        """
        testFormatting(for: input, output, rule: .preferOnChangeZeroArgument)
    }

    func testRemovesUnusedArgumentsOnSingleLine() {
        let input = """
        content.onChange(of: store.items) { _, _ in scrollToBottom() }
        """
        let output = """
        content.onChange(of: store.items) { scrollToBottom() }
        """
        testFormatting(for: input, output, rule: .preferOnChangeZeroArgument)
    }

    func testRemovesUnusedArgumentsWithInitialParameter() {
        let input = """
        content
            .onChange(of: proxy.frame(in: .global), initial: true) { _, _ in
                updateLayout()
            }
        """
        let output = """
        content
            .onChange(of: proxy.frame(in: .global), initial: true) {
                updateLayout()
            }
        """
        testFormatting(for: input, output, rule: .preferOnChangeZeroArgument)
    }

    func testRemovesArgumentsOnTheirOwnLine() {
        let input = """
        content
            .onChange(of: store.items) {
                _, _ in
                scrollToBottom()
            }
        """
        let output = """
        content
            .onChange(of: store.items) {
                scrollToBottom()
            }
        """
        testFormatting(for: input, output, rule: .preferOnChangeZeroArgument)
    }

    func testReplacesNewValueWithStoredProperty() {
        let input = """
        struct ContentView: View {
            @State private var isOn = false

            var body: some View {
                Toggle("Notifications", isOn: $isOn)
                    .onChange(of: isOn) { _, newValue in
                        service.update(isEnabled: newValue)
                    }
            }
        }
        """
        let output = """
        struct ContentView: View {
            @State private var isOn = false

            var body: some View {
                Toggle("Notifications", isOn: $isOn)
                    .onChange(of: isOn) {
                        service.update(isEnabled: isOn)
                    }
            }
        }
        """
        testFormatting(for: input, output, rule: .preferOnChangeZeroArgument)
    }

    func testReplacesNewValueWithStoredPropertyUsingExplicitSelf() {
        let input = """
        struct ContentView: View {
            let query: String

            var body: some View {
                content
                    .onChange(of: self.query, initial: true) { _, query in
                        if query.isEmpty, !query.hasPrefix(prefix) {
                            reset(query: query)
                        }
                    }
            }
        }
        """
        let output = """
        struct ContentView: View {
            let query: String

            var body: some View {
                content
                    .onChange(of: self.query, initial: true) {
                        if self.query.isEmpty, !self.query.hasPrefix(prefix) {
                            reset(query: self.query)
                        }
                    }
            }
        }
        """
        testFormatting(for: input, output, rule: .preferOnChangeZeroArgument, exclude: [.redundantSelf])
    }

    func testReplacesNewValueWithStoredPropertyWithObservers() {
        let input = """
        struct ContentView: View {
            var width: CGFloat = 0 {
                didSet { invalidate() }
            }

            var body: some View {
                content
                    .onChange(of: width) { _, newWidth in
                        guard abs(containerWidth - newWidth) > 1 else { return }

                        updatePadding()
                    }
            }
        }
        """
        let output = """
        struct ContentView: View {
            var width: CGFloat = 0 {
                didSet { invalidate() }
            }

            var body: some View {
                content
                    .onChange(of: width) {
                        guard abs(containerWidth - width) > 1 else { return }

                        updatePadding()
                    }
            }
        }
        """
        testFormatting(for: input, output, rule: .preferOnChangeZeroArgument)
    }

    func testRemovesArgumentWithSameNameAsObservedValue() {
        let input = """
        struct ContentView: View {
            @Binding var isOn: Bool

            var body: some View {
                content
                    .onChange(of: isOn) { _, isOn in
                        service.update(isEnabled: isOn)
                    }
            }
        }
        """
        let output = """
        struct ContentView: View {
            @Binding var isOn: Bool

            var body: some View {
                content
                    .onChange(of: isOn) {
                        service.update(isEnabled: isOn)
                    }
            }
        }
        """
        testFormatting(for: input, output, rule: .preferOnChangeZeroArgument)
    }

    func testDoesNotReplaceMemberOrArgumentLabelWithSameName() {
        let input = """
        struct ContentView: View {
            let isOn: Bool

            var body: some View {
                content
                    .onChange(of: isOn) { _, value in
                        model.value.update(value: value)
                    }
            }
        }
        """
        let output = """
        struct ContentView: View {
            let isOn: Bool

            var body: some View {
                content
                    .onChange(of: isOn) {
                        model.value.update(value: isOn)
                    }
            }
        }
        """
        testFormatting(for: input, output, rule: .preferOnChangeZeroArgument)
    }

    func testReplacesNewValueInSeparateBranches() {
        let input = """
        struct ContentView: View {
            @State private var isOn = false

            var body: some View {
                content
                    .onChange(of: isOn) { _, newValue in
                        if newValue {
                            log("enabled")
                            refresh()
                        } else {
                            disable(newValue)
                        }
                    }
            }
        }
        """
        let output = """
        struct ContentView: View {
            @State private var isOn = false

            var body: some View {
                content
                    .onChange(of: isOn) {
                        if isOn {
                            log("enabled")
                            refresh()
                        } else {
                            disable(isOn)
                        }
                    }
            }
        }
        """
        testFormatting(for: input, output, rule: .preferOnChangeZeroArgument)
    }

    func testReplacesNewValueWithStoredPropertyOfExtendedType() {
        let input = """
        struct ContentView: View {
            @State private var isOn = false

            var body: some View {
                toggle
            }
        }

        extension ContentView {
            var toggle: some View {
                Toggle("Notifications", isOn: $isOn)
                    .onChange(of: isOn) { _, newValue in
                        service.update(isEnabled: newValue)
                    }
            }
        }
        """
        let output = """
        struct ContentView: View {
            @State private var isOn = false

            var body: some View {
                toggle
            }
        }

        extension ContentView {
            var toggle: some View {
                Toggle("Notifications", isOn: $isOn)
                    .onChange(of: isOn) {
                        service.update(isEnabled: isOn)
                    }
            }
        }
        """
        testFormatting(for: input, output, rule: .preferOnChangeZeroArgument)
    }

    func testPreservesNewValueOfComputedProperty() {
        let input = """
        struct ContentView: View {
            let items: [Item]

            var visibleItems: [Item] {
                items.filter(\\.isVisible)
            }

            var body: some View {
                content
                    .onChange(of: visibleItems) { _, newItems in
                        update(newItems)
                    }
            }
        }
        """
        testFormatting(for: input, rule: .preferOnChangeZeroArgument)
    }

    func testPreservesNewValueOfComputedPropertyOfExtendedType() {
        let input = """
        struct ContentView: View {
            var body: some View {
                toggle
            }
        }

        extension ContentView {
            var isOn: Bool {
                store.isOn
            }

            var toggle: some View {
                Toggle("Notifications", isOn: $isOn)
                    .onChange(of: isOn) { _, newValue in
                        service.update(isEnabled: newValue)
                    }
            }
        }
        """
        testFormatting(for: input, rule: .preferOnChangeZeroArgument)
    }

    func testPreservesNewValueOfPropertyDeclaredElsewhere() {
        let input = """
        struct ContentView: View {
            let store: Store

            var body: some View {
                content
                    .onChange(of: store.query) { _, query in
                        search(query)
                    }
                    .onChange(of: isOn) { _, newValue in
                        service.update(isEnabled: newValue)
                    }
            }
        }
        """
        testFormatting(for: input, rule: .preferOnChangeZeroArgument)
    }

    func testPreservesNewValueOutsideOfTypeBody() {
        let input = """
        content
            .onChange(of: isOn) { _, newValue in
                service.update(isEnabled: newValue)
            }
        """
        testFormatting(for: input, rule: .preferOnChangeZeroArgument)
    }

    func testPreservesClosureThatUsesOldValue() {
        let input = """
        content
            .onChange(of: isOn) { oldValue, newValue in
                service.update(from: oldValue, to: newValue)
            }
        """
        testFormatting(for: input, rule: .preferOnChangeZeroArgument)
    }

    func testPreservesDeprecatedSingleArgumentClosure() {
        let input = """
        content
            .onChange(of: isOn) { newValue in
                service.update(isEnabled: newValue)
            }
            .onChange(of: isOn) {
                service.update(isEnabled: $0)
            }
        """
        testFormatting(for: input, rule: .preferOnChangeZeroArgument)
    }

    func testPreservesObservedValueThatIsNotMemberAccessChain() {
        let input = """
        content
            .onChange(of: route == nil) { _, isDismissed in
                if isDismissed { onExit() }
            }
            .onChange(of: proxy.frame(in: .global)) { _, frame in
                self.frame = frame
            }
            .onChange(of: model?.title) { _, title in
                update(title)
            }
        """
        testFormatting(for: input, rule: .preferOnChangeZeroArgument)
    }

    func testPreservesNewValueUsedInNestedClosure() {
        let input = """
        struct ContentView: View {
            @State private var isOn = false

            var body: some View {
                content
                    .onChange(of: isOn) { _, newValue in
                        Task {
                            await service.update(isEnabled: newValue)
                        }
                    }
            }
        }
        """
        testFormatting(for: input, rule: .preferOnChangeZeroArgument)
    }

    func testPreservesNewValueUsedAfterFirstStatement() {
        let input = """
        struct ContentView: View {
            @State private var query = ""

            var body: some View {
                content
                    .onChange(of: query) { _, query in
                        store.reset()
                        search(query)
                    }
            }
        }
        """
        testFormatting(for: input, rule: .preferOnChangeZeroArgument)
    }

    func testPreservesNewValueUsedAfterStatementInConditionalBody() {
        let input = """
        struct ContentView: View {
            @State private var query = ""

            var body: some View {
                content
                    .onChange(of: query) { _, query in
                        if !query.isEmpty {
                            store.reset()
                            search(query)
                        }
                    }
            }
        }
        """
        testFormatting(for: input, rule: .preferOnChangeZeroArgument)
    }

    func testPreservesShadowedNewValue() {
        let input = """
        struct ContentView: View {
            @State private var selection: Set<Item>?

            var body: some View {
                content
                    .onChange(of: selection) { _, newValue in
                        guard let newValue else { return }
                    }
                    .onChange(of: selection) { _, newValue in
                        if let selection = newValue.first { select(selection) }
                    }
            }
        }
        """
        testFormatting(for: input, rule: .preferOnChangeZeroArgument)
    }

    func testPreservesClosureWithCaptureListOrTypes() {
        let input = """
        content
            .onChange(of: isOn) { [store] _, newValue in
                store.update(isEnabled: newValue)
            }
            .onChange(of: isOn) { (_: Bool, newValue: Bool) in
                service.update(isEnabled: newValue)
            }
            .onChange(of: isOn) { @MainActor _, _ in
                refresh()
            }
        """
        testFormatting(for: input, rule: .preferOnChangeZeroArgument)
    }

    func testPreservesOnChangeWithKeyPathOrOtherParameters() {
        let input = """
        reducer
            .onChange(of: \\.count) { _, _ in
                Reduce { _, _ in .none }
            }

        content
            .onChange(of: isOn, perform: { _, _ in refresh() })
            .onChange(isOn) { _, _ in refresh() }
        """
        testFormatting(for: input, rule: .preferOnChangeZeroArgument)
    }
}
