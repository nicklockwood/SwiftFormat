// Created by miguel_jimenez on 10/16/24.
// Copyright © 2024 Airbnb Inc. All rights reserved.

import XCTest

final class ReplaceEnvironmentKeyForEntryMacroTests: XCTestCase {
    func testReplaceEnvironmentKeyDefinitionForEntryMacro() {
        let input = """
        struct ScreenNameEnvironmentKey: EnvironmentKey {
            static var defaultValue: Identifier? {
                .init("undefined")
            }
        }

        extension EnvironmentValues {
            var screenName: Identifier? {
                get { self[ScreenNameEnvironmentKey.self] }
                set { self[ScreenNameEnvironmentKey.self] = newValue }
            }
        }
        """
        let output = """
        extension EnvironmentValues {
            @Entry var screenName: Identifier? = .init("undefined")
        }
        """
        testFormatting(for: input, output, rule: .replaceEnvironmentKeyForEntryMacro)
    }

    func testReplaceEnvironmentKeyDefinitionForEntryMacroWithKeyDefinitionAfterEnvironmentValue() {
        let input = """
        extension EnvironmentValues {
            var screenName: Identifier? {
                get { self[ScreenNameEnvironmentKey.self] }
                set { self[ScreenNameEnvironmentKey.self] = newValue }
            }
        }

        struct ScreenNameEnvironmentKey: EnvironmentKey {
            static var defaultValue: Identifier? {
                .init("undefined")
            }
        }
        """
        let output = """
        extension EnvironmentValues {
            @Entry var screenName: Identifier? = .init("undefined")
        }

        """
        testFormatting(
            for: input, [output],
            rules: [
                .replaceEnvironmentKeyForEntryMacro,
                .blankLinesBetweenScopes,
                .blankLinesAtEndOfScope,
                .blankLinesAtStartOfScope,
                .consecutiveBlankLines,
            ]
        )
    }

    func testReplaceMultipleEnvironmentKeyDefinitionForEntryMacro() {
        let input = """
        extension EnvironmentValues {
            var isSelected: Bool {
                get { self[IsSelectedEnvironmentKey.self] }
                set { self[IsSelectedEnvironmentKey.self] = newValue }
            }
        }

        struct IsSelectedEnvironmentKey: EnvironmentKey {
            static var defaultValue: Bool { false }
        }

        extension EnvironmentValues {
            var screenName: Identifier? {
                get { self[ScreenNameEnvironmentKey.self] }
                set { self[ScreenNameEnvironmentKey.self] = newValue }
            }
        }

        struct ScreenNameEnvironmentKey: EnvironmentKey {
            static var defaultValue: Identifier? {
                .init("undefined")
            }
        }
        """
        let output = """
        extension EnvironmentValues {
            @Entry var isSelected: Bool = false
        }

        extension EnvironmentValues {
            @Entry var screenName: Identifier? = .init("undefined")
        }

        """
        testFormatting(
            for: input, [output],
            rules: [
                .replaceEnvironmentKeyForEntryMacro,
                .blankLinesBetweenScopes,
                .blankLinesAtEndOfScope,
                .blankLinesAtStartOfScope,
                .consecutiveBlankLines,
            ]
        )
    }

    func testReplaceMultipleEnvironmentKeyPropertiesInSameEnvironmentValuesExtension() {
        let input = """
        extension EnvironmentValues {
            var isSelected: Bool {
                get { self[IsSelectedEnvironmentKey.self] }
                set { self[IsSelectedEnvironmentKey.self] = newValue }
            }

            var screenName: Identifier? {
                get { self[ScreenNameEnvironmentKey.self] }
                set { self[ScreenNameEnvironmentKey.self] = newValue }
            }
        }

        struct IsSelectedEnvironmentKey: EnvironmentKey {
            static var defaultValue: Bool { false }
        }

        struct ScreenNameEnvironmentKey: EnvironmentKey {
            static var defaultValue: Identifier? {
                .init("undefined")
            }
        }
        """
        let output = """
        extension EnvironmentValues {
            @Entry var isSelected: Bool = false

            @Entry var screenName: Identifier? = .init("undefined")
        }

        """
        testFormatting(
            for: input, [output],
            rules: [
                .replaceEnvironmentKeyForEntryMacro,
                .blankLinesBetweenScopes,
                .blankLinesAtEndOfScope,
                .blankLinesAtStartOfScope,
                .consecutiveBlankLines,
            ]
        )
    }

    func testEnvironmentKeyIsNotRemovedWhenPropertyAndKeyDontMatch() {
        let input = """
        extension EnvironmentValues {
            var isSelected: Bool {
                get { self[IsSelectedEnvironmentKey.self] }
                set { self[IsSelectedEnvironmentKey.self] = newValue }
            }
        }

        struct SelectedEnvironmentKey: EnvironmentKey {
            static var defaultValue: Bool { false }
        }
        """
        testFormatting(for: input, rule: .replaceEnvironmentKeyForEntryMacro)
    }
}
