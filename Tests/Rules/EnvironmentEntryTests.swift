// Created by miguel_jimenez on 10/16/24.
// Copyright © 2024 Airbnb Inc. All rights reserved.

import SwiftFormat
import XCTest

final class EnvironmentEntryTests: XCTestCase {
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
        testFormatting(for: input, output, rule: .environmentEntry, options: FormatOptions(swiftVersion: "6.0"))
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
                .environmentEntry,
                .blankLinesBetweenScopes,
                .consecutiveBlankLines,
                .blankLinesAtEndOfScope,
                .blankLinesAtStartOfScope,
            ],
            options: FormatOptions(swiftVersion: "6.0")
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
                .environmentEntry,
                .blankLinesBetweenScopes,
                .blankLinesAtEndOfScope,
                .blankLinesAtStartOfScope,
                .consecutiveBlankLines,
            ],
            options: FormatOptions(swiftVersion: "6.0")
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
                .environmentEntry,
                .blankLinesBetweenScopes,
                .blankLinesAtEndOfScope,
                .blankLinesAtStartOfScope,
                .consecutiveBlankLines,
            ],
            options: FormatOptions(swiftVersion: "6.0")
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
        testFormatting(for: input, rule: .environmentEntry, options: FormatOptions(swiftVersion: "6.0"))
    }

    func testReplaceEnvironmentKeyWithMultipleLinesInDefaultValue() {
        let input = """
        struct ScreenNameEnvironmentKey: EnvironmentKey {
            static var defaultValue: Identifier? {
                let domain = "com.mycompany.myapp"
                let base = "undefined"
                return .init("\\(domain).\\(base)")
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
            @Entry var screenName: Identifier? = {
                let domain = "com.mycompany.myapp"
                let base = "undefined"
                return .init("\\(domain).\\(base)")
            }()
        }
        """
        testFormatting(for: input, output, rule: .environmentEntry, options: FormatOptions(swiftVersion: "6.0"))
    }

    func testReplaceEnvironmentKeyWithImplicitNilDefaultValue() {
        let input = """
        struct ScreenNameEnvironmentKey: EnvironmentKey {
            static var defaultValue: Identifier?
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
            @Entry var screenName: Identifier?
        }
        """
        testFormatting(for: input, output, rule: .environmentEntry, options: FormatOptions(swiftVersion: "6.0"))
    }

    func testEnvironmentPropertyWithCommentsPreserved() {
        let input = """
        struct ScreenNameEnvironmentKey: EnvironmentKey {
            static var defaultValue: Identifier? {
                .init("undefined")
            }
        }

        extension EnvironmentValues {
            /// The name provided to the outer most view representing a full screen width
            var screenName: Identifier? {
                get { self[ScreenNameEnvironmentKey.self] }
                set { self[ScreenNameEnvironmentKey.self] = newValue }
            }
        }
        """
        let output = """
        extension EnvironmentValues {
            /// The name provided to the outer most view representing a full screen width
            @Entry var screenName: Identifier? = .init("undefined")
        }
        """
        testFormatting(
            for: input, output,
            rule: .environmentEntry,
            options: FormatOptions(swiftVersion: "6.0"),
            exclude: [.docComments]
        )
    }

    func testEnvironmentKeyWithMultupleDefinitionsIsNotRemoved() {
        let input = """
        extension EnvironmentValues {
            var isSelected: Bool {
                get { self[IsSelectedEnvironmentKey.self] }
                set { self[IsSelectedEnvironmentKey.self] = newValue }
            }

            var doSomething() {
                print("do some work")
            }
        }

        struct SelectedEnvironmentKey: EnvironmentKey {
            static var defaultValue: Bool { false }
        }
        """
        testFormatting(for: input, rule: .environmentEntry, options: FormatOptions(swiftVersion: "6.0"))
    }
}
