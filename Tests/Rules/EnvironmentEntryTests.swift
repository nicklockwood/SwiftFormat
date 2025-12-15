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
        testFormatting(for: input, rule: .environmentEntry, options: FormatOptions(swiftVersion: "6.0"), exclude: [.wrapFunctionBodies, .wrapPropertyBodies])
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

    func testEnvironmentKeyWithMultipleDefinitionsIsNotRemoved() {
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
        testFormatting(for: input, rule: .environmentEntry, options: FormatOptions(swiftVersion: "6.0"), exclude: [.wrapFunctionBodies, .wrapPropertyBodies])
    }

    func testEntryMacroReplacementWhenDefaultValueIsNotComputed() {
        let input = """
        struct ScreenStyleEnvironmentKey: EnvironmentKey {
            static var defaultValue: ScreenStyle = ScreenStyle()
        }

        extension EnvironmentValues {
            var screenStyle: ScreenStyle {
                get { self[ScreenStyleEnvironmentKey.self] }
                set { self[ScreenStyleEnvironmentKey.self] = newValue }
            }
        }
        """
        let output = """
        extension EnvironmentValues {
            @Entry var screenStyle: ScreenStyle = ScreenStyle()
        }
        """
        testFormatting(
            for: input, output,
            rule: .environmentEntry,
            options: FormatOptions(swiftVersion: "6.0"),
            exclude: [.redundantType]
        )
    }

    func testEntryMacroReplacementWhenPropertyIsPublic() {
        let input = """
        struct ScreenStyleEnvironmentKey: EnvironmentKey {
            static var defaultValue: ScreenStyle { .init() }
        }

        extension EnvironmentValues {
            public var screenStyle: ScreenStyle {
                get { self[ScreenStyleEnvironmentKey.self] }
                set { self[ScreenStyleEnvironmentKey.self] = newValue }
            }
        }
        """
        let output = """
        extension EnvironmentValues {
            @Entry public var screenStyle: ScreenStyle = .init()
        }
        """
        testFormatting(
            for: input, output,
            rule: .environmentEntry,
            options: FormatOptions(swiftVersion: "6.0")
        )
    }

    func testEntryMacroReplacementWhenKeyDoesntHaveEnvironmentKeySuffix() {
        let input = """
        struct ScreenStyle: EnvironmentKey {
            static var defaultValue: Style { .init() }
        }

        extension EnvironmentValues {
            public var screenStyle: Style {
                get { self[ScreenStyle.self] }
                set { self[ScreenStyle.self] = newValue }
            }
        }
        """
        let output = """
        extension EnvironmentValues {
            @Entry public var screenStyle: Style = .init()
        }
        """
        testFormatting(for: input, output, rule: .environmentEntry, options: FormatOptions(swiftVersion: "6.0"))
    }

    func testEntryMacroReplacementWithEnumEnvironmentKey() {
        let input = """
        private enum InputShouldChangeKey: EnvironmentKey {
            static var defaultValue: InputShouldChangeHandler { nil }
        }

        extension EnvironmentValues {
            public var inputShouldChange: InputShouldChangeHandler {
                get { self[InputShouldChangeKey.self] }
                set { self[InputShouldChangeKey.self] = newValue }
            }
        }
        """
        let output = """
        extension EnvironmentValues {
            @Entry public var inputShouldChange: InputShouldChangeHandler = nil
        }
        """
        testFormatting(for: input, output, rule: .environmentEntry, options: FormatOptions(swiftVersion: "6.0"))
    }

    func testEntryMacroReplacementWhenDefaultValueIsLet() {
        let input = """
        private struct ScreenStyleKey: EnvironmentKey {
            static let defaultValue: Style = .init()
        }

        extension EnvironmentValues {
            public var screenStyle: Style {
                get { self[ScreenStyleKey.self] }
                set { self[ScreenStyleKey.self] = newValue }
            }
        }
        """
        let output = """
        extension EnvironmentValues {
            @Entry public var screenStyle: Style = .init()
        }
        """
        testFormatting(for: input, output, rule: .environmentEntry, options: FormatOptions(swiftVersion: "6.0"))
    }

    func testEntryMacroReplacementWithoutExplicitTypeAnnotation() {
        let input = """
        private struct ScreenStyleKey: EnvironmentKey {
            static let defaultValue = Style()
        }

        extension EnvironmentValues {
            public var screenStyle: Style {
                get { self[ScreenStyleKey.self] }
                set { self[ScreenStyleKey.self] = newValue }
            }
        }
        """
        let output = """
        extension EnvironmentValues {
            @Entry public var screenStyle: Style = Style()
        }
        """
        testFormatting(
            for: input, output,
            rule: .environmentEntry,
            options: FormatOptions(swiftVersion: "6.0"),
            exclude: [.redundantType]
        )
    }

    func testEnvironmentValuesPropertyWithoutSetterIsNotModified() {
        let input = """
        struct AEnvironmentKey: EnvironmentKey {
            static var defaultValue: A = .default
        }

        extension EnvironmentValues {
            public var fallbackA: A {
                if self[AEnvironmentKey.self] {
                    A()
                } else {
                    something()
                }
            }
        }
        """
        testFormatting(
            for: input,
            rule: .environmentEntry,
            options: FormatOptions(swiftVersion: "6.0"),
            exclude: [.redundantType]
        )
    }
}
