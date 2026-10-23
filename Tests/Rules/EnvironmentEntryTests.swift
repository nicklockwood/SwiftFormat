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
        testFormatting(for: input, rule: .environmentEntry, options: FormatOptions(swiftVersion: "6.0"), exclude: [.wrapPropertyBodies])
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
        testFormatting(for: input, rule: .environmentEntry, options: FormatOptions(swiftVersion: "6.0"), exclude: [.wrapPropertyBodies])
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

    func testEntryMacroReplacementWhenPropertyHasAttributeOnPreviousLine() {
        let input = """
        struct ScreenNameEnvironmentKey: EnvironmentKey {
            static var defaultValue: String { "home" }
        }

        extension EnvironmentValues {
            @_spi(Internals)
            public var screenName: String {
                get { self[ScreenNameEnvironmentKey.self] }
                set { self[ScreenNameEnvironmentKey.self] = newValue }
            }
        }
        """
        let output = """
        extension EnvironmentValues {
            @Entry @_spi(Internals)
            public var screenName: String = "home"
        }
        """
        testFormatting(for: input, output, rule: .environmentEntry, options: FormatOptions(swiftVersion: "6.0"))
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

    func testPropertyWithCustomFallbackCodeNotModified() {
        let input = """
        /// Do this manually instead of using `@Entry` so the getter can fall back to
        /// the real `dismiss` action when no explicit `customDismiss` was set.
        private struct CustomDismissActionKey: EnvironmentKey {
            static var defaultValue: CustomDismissAction {
                .init(fallback: true, body: {})
            }
        }

        public extension EnvironmentValues {
            /// An action that dismisses the current presentation.
            var customDismiss: CustomDismissAction {
                get {
                    let dismiss = self[CustomDismissActionKey.self]

                    if dismiss.fallback {
                        let trueDismiss = self.dismiss
                        return .init(fallback: false, body: {
                            trueDismiss()
                        })
                    } else {
                        return dismiss
                    }
                }
                set {
                    self[CustomDismissActionKey.self] = newValue
                }
            }
        }
        """

        testFormatting(for: input, rule: .environmentEntry, options: FormatOptions(swiftVersion: "6.0"))
    }

    func testPreservesEnvironmentVarWithCustomSetAccessControl() {
        let input = """
        /// Do this manually instead of using `@Entry` so that we can do package(set).
        private enum ThemingKey: EnvironmentKey {
            static var defaultValue: Theme {
                _currentTheme
            }
        }

        public extension EnvironmentValues {
            package(set) var theme: Theme {
                get {
                    self[ThemingKey.self]
                }
                set {
                    self[ThemingKey.self] = newValue
                }
            }
        }
        """

        testFormatting(for: input, rule: .environmentEntry, options: FormatOptions(swiftVersion: "6.0"))
    }

    func testReplaceEnvironmentKeyWithReturnInIfExpressionDefaultValue() {
        let input = """
        struct IsEnabledKey: EnvironmentKey {
            static var defaultValue: Bool {
                if ProcessInfo.processInfo.arguments.contains("-enabled") {
                    log("Enabled from launch arguments")
                    return true
                } else {
                    return false
                }
            }
        }

        extension EnvironmentValues {
            var isEnabled: Bool {
                get { self[IsEnabledKey.self] }
                set { self[IsEnabledKey.self] = newValue }
            }
        }
        """
        let output = """
        extension EnvironmentValues {
            @Entry var isEnabled: Bool = {
                if ProcessInfo.processInfo.arguments.contains("-enabled") {
                    log("Enabled from launch arguments")
                    return true
                } else {
                    return false
                }
            }()
        }
        """
        testFormatting(for: input, output, rule: .environmentEntry, options: FormatOptions(swiftVersion: "6.0"))
    }

    func testReplaceEnvironmentKeyWithIfdefDefaultValue() {
        let input = """
        struct IsDebugKey: EnvironmentKey {
            static var defaultValue: Bool {
                #if DEBUG
                    true
                #else
                    false
                #endif
            }
        }

        extension EnvironmentValues {
            var isDebug: Bool {
                get { self[IsDebugKey.self] }
                set { self[IsDebugKey.self] = newValue }
            }
        }
        """
        let output = """
        extension EnvironmentValues {
            @Entry var isDebug: Bool = {
                #if DEBUG
                    true
                #else
                    false
                #endif
            }()
        }
        """
        testFormatting(for: input, output, rule: .environmentEntry, options: FormatOptions(swiftVersion: "6.0"))
    }

    func testReplaceEnvironmentKeyWithPostfixIfdefDefaultValue() {
        let input = """
        struct ThemeKey: EnvironmentKey {
            static var defaultValue: Theme {
                makeDefaultTheme()
                #if DEBUG
                    .withDebugColors()
                #endif
            }
        }

        extension EnvironmentValues {
            var theme: Theme {
                get { self[ThemeKey.self] }
                set { self[ThemeKey.self] = newValue }
            }
        }
        """
        let output = """
        extension EnvironmentValues {
            @Entry var theme: Theme = makeDefaultTheme()
            #if DEBUG
                .withDebugColors()
            #endif
        }
        """
        testFormatting(for: input, [output], rules: [.environmentEntry, .indent], options: FormatOptions(swiftVersion: "6.0"))
    }

    func testReplaceEnvironmentKeyWithDefaultValueWithoutSpaces() {
        let input = """
        struct ThemeKey: EnvironmentKey {
            static var defaultValue: Theme {makeDefaultTheme()}
        }

        extension EnvironmentValues {
            var theme: Theme {
                get { self[ThemeKey.self] }
                set { self[ThemeKey.self] = newValue }
            }
        }
        """
        let output = """
        extension EnvironmentValues {
            @Entry var theme: Theme = makeDefaultTheme()
        }
        """
        testFormatting(for: input, output, rule: .environmentEntry, options: FormatOptions(swiftVersion: "6.0"))
    }

    func testReplaceEnvironmentKeyWithIfExpressionDefaultValue() {
        let input = """
        struct IsEnabledKey: EnvironmentKey {
            static var defaultValue: Bool {
                if ProcessInfo.processInfo.arguments.contains("-enabled") {
                    true
                } else {
                    false
                }
            }
        }

        extension EnvironmentValues {
            var isEnabled: Bool {
                get { self[IsEnabledKey.self] }
                set { self[IsEnabledKey.self] = newValue }
            }
        }
        """
        let output = """
        extension EnvironmentValues {
            @Entry var isEnabled: Bool = if ProcessInfo.processInfo.arguments.contains("-enabled") {
                true
            } else {
                false
            }
        }
        """
        testFormatting(
            for: input, [output],
            rules: [.environmentEntry, .indent],
            options: FormatOptions(swiftVersion: "6.0"),
            exclude: [.wrapMultilineConditionalAssignment]
        )
    }

    func testReplaceEnvironmentKeyWithIfExpressionWithIfdefBranchDefaultValue() {
        let input = """
        struct IsEnabledKey: EnvironmentKey {
            static var defaultValue: Bool {
                if isFeatureAvailable {
                    #if DEBUG
                        true
                    #else
                        false
                    #endif
                } else {
                    false
                }
            }
        }

        extension EnvironmentValues {
            var isEnabled: Bool {
                get { self[IsEnabledKey.self] }
                set { self[IsEnabledKey.self] = newValue }
            }
        }
        """
        let output = """
        extension EnvironmentValues {
            @Entry var isEnabled: Bool = if isFeatureAvailable {
                #if DEBUG
                    true
                #else
                    false
                #endif
            } else {
                false
            }
        }
        """
        testFormatting(
            for: input, [output],
            rules: [.environmentEntry, .indent],
            options: FormatOptions(swiftVersion: "6.0"),
            exclude: [.wrapMultilineConditionalAssignment]
        )
    }

    func testReplaceEnvironmentKeyWithSwitchExpressionDefaultValue() {
        let input = """
        struct SpacingKey: EnvironmentKey {
            static var defaultValue: Double {
                switch Platform.current {
                case .iOS:
                    8
                case .macOS:
                    12
                }
            }
        }

        extension EnvironmentValues {
            var spacing: Double {
                get { self[SpacingKey.self] }
                set { self[SpacingKey.self] = newValue }
            }
        }
        """
        let output = """
        extension EnvironmentValues {
            @Entry var spacing: Double = switch Platform.current {
            case .iOS:
                8
            case .macOS:
                12
            }
        }
        """
        testFormatting(
            for: input, [output],
            rules: [.environmentEntry, .indent],
            options: FormatOptions(swiftVersion: "6.0"),
            exclude: [.wrapMultilineConditionalAssignment]
        )
    }

    func testReplaceEnvironmentKeyWithNestedPostfixIfdefDefaultValue() {
        let input = """
        struct ThemeKey: EnvironmentKey {
            static var defaultValue: Theme {
                makeDefaultTheme()
                #if DEBUG
                    #if targetEnvironment(simulator)
                        .withSimulatorColors()
                    #endif
                    .withDebugColors()
                #endif
            }
        }

        extension EnvironmentValues {
            var theme: Theme {
                get { self[ThemeKey.self] }
                set { self[ThemeKey.self] = newValue }
            }
        }
        """
        let output = """
        extension EnvironmentValues {
            @Entry var theme: Theme = makeDefaultTheme()
            #if DEBUG
                #if targetEnvironment(simulator)
                    .withSimulatorColors()
                #endif
                    .withDebugColors()
            #endif
        }
        """
        testFormatting(for: input, [output], rules: [.environmentEntry, .indent], options: FormatOptions(swiftVersion: "6.0"))
    }
}
