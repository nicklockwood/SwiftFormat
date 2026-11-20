//
//  PreferZeroArgumentOnChangeTests.swift
//  SwiftFormatTests
//
//  Created by Miguel Jimenez on 2026-11-20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class PreferZeroArgumentOnChangeTests: XCTestCase {
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
        testFormatting(for: input, output, rule: .preferZeroArgumentOnChange)
    }

    func testRemovesUnusedArgumentsOnSingleLine() {
        let input = """
        content.onChange(of: store.items) { _, _ in scrollToBottom() }
        """
        let output = """
        content.onChange(of: store.items) { scrollToBottom() }
        """
        testFormatting(for: input, output, rule: .preferZeroArgumentOnChange)
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
        testFormatting(for: input, output, rule: .preferZeroArgumentOnChange)
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
        testFormatting(for: input, output, rule: .preferZeroArgumentOnChange)
    }

    func testReplacesNewValueWithObservedValue() {
        let input = """
        Toggle("Notifications", isOn: $isOn)
            .onChange(of: isOn) { _, newValue in
                service.update(isEnabled: newValue)
            }
        """
        let output = """
        Toggle("Notifications", isOn: $isOn)
            .onChange(of: isOn) {
                service.update(isEnabled: isOn)
            }
        """
        testFormatting(for: input, output, rule: .preferZeroArgumentOnChange)
    }

    func testReplacesNewValueWithMemberAccessChain() {
        let input = """
        content
            .onChange(of: store.state.query, initial: true) { _, query in
                if query.isEmpty, !query.hasPrefix(prefix) {
                    reset(query: query)
                }
            }
        """
        let output = """
        content
            .onChange(of: store.state.query, initial: true) {
                if store.state.query.isEmpty, !store.state.query.hasPrefix(prefix) {
                    reset(query: store.state.query)
                }
            }
        """
        testFormatting(for: input, output, rule: .preferZeroArgumentOnChange)
    }

    func testReplacesNewValueInFirstStatementOfLongerBody() {
        let input = """
        content
            .onChange(of: width) { _, newWidth in
                guard abs(containerWidth - newWidth) > 1 else { return }

                updatePadding()
            }
        """
        let output = """
        content
            .onChange(of: width) {
                guard abs(containerWidth - width) > 1 else { return }

                updatePadding()
            }
        """
        testFormatting(for: input, output, rule: .preferZeroArgumentOnChange)
    }

    func testRemovesArgumentWithSameNameAsObservedValue() {
        let input = """
        content
            .onChange(of: isOn) { _, isOn in
                service.update(isEnabled: isOn)
            }
        """
        let output = """
        content
            .onChange(of: isOn) {
                service.update(isEnabled: isOn)
            }
        """
        testFormatting(for: input, output, rule: .preferZeroArgumentOnChange)
    }

    func testDoesNotReplaceMemberOrArgumentLabelWithSameName() {
        let input = """
        content
            .onChange(of: isOn) { _, value in
                model.value.update(value: value)
            }
        """
        let output = """
        content
            .onChange(of: isOn) {
                model.value.update(value: isOn)
            }
        """
        testFormatting(for: input, output, rule: .preferZeroArgumentOnChange)
    }

    func testPreservesClosureThatUsesOldValue() {
        let input = """
        content
            .onChange(of: isOn) { oldValue, newValue in
                service.update(from: oldValue, to: newValue)
            }
        """
        testFormatting(for: input, rule: .preferZeroArgumentOnChange)
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
        testFormatting(for: input, rule: .preferZeroArgumentOnChange)
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
        testFormatting(for: input, rule: .preferZeroArgumentOnChange)
    }

    func testPreservesNewValueUsedInNestedClosure() {
        let input = """
        content
            .onChange(of: isOn) { _, newValue in
                Task {
                    await service.update(isEnabled: newValue)
                }
            }
        """
        testFormatting(for: input, rule: .preferZeroArgumentOnChange)
    }

    func testPreservesNewValueUsedAfterFirstStatement() {
        let input = """
        content
            .onChange(of: store.query) { _, query in
                store.reset()
                search(query)
            }
        """
        testFormatting(for: input, rule: .preferZeroArgumentOnChange)
    }

    func testPreservesNewValueUsedAfterStatementInConditionalBody() {
        let input = """
        content
            .onChange(of: store.query) { _, query in
                if !query.isEmpty {
                    store.reset()
                    search(query)
                }
            }
        """
        testFormatting(for: input, rule: .preferZeroArgumentOnChange)
    }

    func testReplacesNewValueInSeparateBranches() {
        let input = """
        content
            .onChange(of: isOn) { _, newValue in
                if newValue {
                    log("enabled")
                    refresh()
                } else {
                    disable(newValue)
                }
            }
        """
        let output = """
        content
            .onChange(of: isOn) {
                if isOn {
                    log("enabled")
                    refresh()
                } else {
                    disable(isOn)
                }
            }
        """
        testFormatting(for: input, output, rule: .preferZeroArgumentOnChange)
    }

    func testPreservesShadowedNewValue() {
        let input = """
        content
            .onChange(of: selection) { _, newValue in
                guard let newValue else { return }
            }
            .onChange(of: selection) { _, newValue in
                if let selection = newValue.first { select(selection) }
            }
        """
        testFormatting(for: input, rule: .preferZeroArgumentOnChange)
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
        testFormatting(for: input, rule: .preferZeroArgumentOnChange)
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
        testFormatting(for: input, rule: .preferZeroArgumentOnChange)
    }
}
