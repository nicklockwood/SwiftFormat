//
//  PrivateSwiftUIDynamicPropertiesTests.swift
//  SwiftFormatTests
//
//  Created by Kim de Vos on 9/1/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class PrivateSwiftUIDynamicPropertiesTests: XCTestCase {
    func testStateOnlyPreservesInjectedAndOtherDynamicProperties() {
        let input = """
        public struct ContentView: View {
            @State var counter = 0
            @StateObject var model = Model()
            @Bindable var viewModel: ViewModel
            @ObservedObject var store: Store
            @Binding var isPresented: Bool
            @Environment(\\.openURL) var openURL
            @EnvironmentObject var settings: Settings
            @AppStorage("isVisible") var isVisible = true
            @SceneStorage("text") var text = ""
            @FocusState var isFocused: Bool
            @GestureState var isDragging = false
            @Namespace var namespace
        }
        """
        let output = """
        public struct ContentView: View {
            @State private var counter = 0
            @StateObject private var model = Model()
            @Bindable var viewModel: ViewModel
            @ObservedObject var store: Store
            @Binding var isPresented: Bool
            @Environment(\\.openURL) var openURL
            @EnvironmentObject var settings: Settings
            @AppStorage("isVisible") var isVisible = true
            @SceneStorage("text") var text = ""
            @FocusState var isFocused: Bool
            @GestureState var isDragging = false
            @Namespace var namespace
        }
        """
        let options = FormatOptions(privateSwiftUIProperties: .stateOnly)
        testFormatting(for: input, output, rule: .privateSwiftUIDynamicProperties, options: options)
        testFormatting(for: input, output, rule: .privateStateVariables, options: options)
    }

    func testStateOnlyInViewModifierWithNamespacedWrappers() {
        let input = """
        struct ContentModifier: ViewModifier {
            @SwiftUI::State var counter = 0
            @SwiftUI::StateObject var model = Model()
            @SwiftUI::Bindable var viewModel: ViewModel
            @SwiftUI::Environment(\\.openURL) var openURL
        }
        """
        let output = """
        struct ContentModifier: ViewModifier {
            @SwiftUI::State private var counter = 0
            @SwiftUI::StateObject private var model = Model()
            @SwiftUI::Bindable var viewModel: ViewModel
            @SwiftUI::Environment(\\.openURL) var openURL
        }
        """
        let options = FormatOptions(privateSwiftUIProperties: .stateOnly)
        testFormatting(for: input, output, rule: .privateSwiftUIDynamicProperties, options: options)
    }

    func testStateOnlyPreservesAccessControlAndPreviewable() {
        let input = """
        struct ContentView: View {
            @State internal var counter = 0
            @StateObject private(set) var model = Model()
            @Previewable @State var isEnabled = true
            @Previewable @StateObject var previewModel = Model()
        }
        """
        let options = FormatOptions(privateSwiftUIProperties: .stateOnly)
        testFormatting(for: input, rule: .privateSwiftUIDynamicProperties, options: options)
    }

    func testPrivateDynamicProperties() {
        let input = """
        struct ContentView: View {
            @AppStorage("isVisible") var isVisible: Bool
            @Binding var isPresented: Bool
            @Environment(\\.openURL) var openURL
            @EnvironmentObject var store: Store
            @ObservedObject var viewModel: ViewModel
            @StateObject var model: Model
        }
        """
        let output = """
        struct ContentView: View {
            @AppStorage("isVisible") private var isVisible: Bool
            @Binding var isPresented: Bool
            @Environment(\\.openURL) private var openURL
            @EnvironmentObject private var store: Store
            @ObservedObject private var viewModel: ViewModel
            @StateObject private var model: Model
        }
        """
        testFormatting(for: input, output, rule: .privateSwiftUIDynamicProperties)
        let options = FormatOptions(privateSwiftUIProperties: .all)
        testFormatting(for: input, output, rule: .privateSwiftUIDynamicProperties, options: options)
    }

    func testDoesNotMakeBindingPrivateInInternalType() {
        let input = """
        struct ContentView: View {
            @Binding var isPresented: Bool
        }
        """
        testFormatting(for: input, rule: .privateSwiftUIDynamicProperties)
    }

    func testMakesBindingPrivateInPublicOrOpenType() {
        let input = """
        public struct PublicContentView: View {
            @Binding var text: String
        }

        open class OpenContentView: View {
            @Binding var text: String
        }
        """
        let output = """
        public struct PublicContentView: View {
            @Binding private var text: String
        }

        open class OpenContentView: View {
            @Binding private var text: String
        }
        """
        testFormatting(for: input, output, rule: .privateSwiftUIDynamicProperties)
    }

    func testPrivateNamespacedDynamicProperty() {
        let input = """
        struct ContentView: View {
            @SwiftUI::State var counter: Int
        }
        """
        let output = """
        struct ContentView: View {
            @SwiftUI::State private var counter: Int
        }
        """
        testFormatting(for: input, output, rule: .privateSwiftUIDynamicProperties)
    }

    func testUseExistingAccessControl() {
        let input = """
        struct ContentView: View {
            @State private var counter: Int
            @StateObject public var model: Model
            @State package var count: Int
            @State private(set) var isEnabled: Bool
            @StateObject public private(set) var viewModel: ViewModel
            private @State var value: Int
        }
        """
        testFormatting(for: input, rule: .privateSwiftUIDynamicProperties, exclude: [.redundantPublic])
    }

    func testDoesNotModifyNonStoredProperties() {
        let input = """
        struct ContentView: View {
            @State static var counter: Int

            func update() {
                @State var localCounter: Int
            }
        }
        """
        testFormatting(for: input, rule: .privateSwiftUIDynamicProperties)
    }

    func testStateVariableOnPreviousLine() {
        let input = """
        struct ContentView: View {
            @State
            var counter: Int
        }
        """
        let output = """
        struct ContentView: View {
            @State
            private var counter: Int
        }
        """
        testFormatting(for: input, output, rule: .privateSwiftUIDynamicProperties)
    }

    func testWithPreviewableOnSameLine() {
        // Don't add `private` to @Previewable property wrappers:
        let input = """
        struct ContentView: View {
            @Previewable @StateObject var counter: Int
        }
        """
        testFormatting(for: input, rule: .privateSwiftUIDynamicProperties)
    }

    func testWithPreviewableOnPreviousLine() {
        // Don't add `private` to @Previewable property wrappers:
        let input = """
        struct ContentView: View {
            @Previewable
            @State var counter: Int
        }
        """
        testFormatting(for: input, rule: .privateSwiftUIDynamicProperties)
    }

    func testAppStorageInObservableObjectRemainsUnchanged() {
        let input = """
        final class ViewModel: ObservableObject {
            @AppStorage("soundEffectsEnabled")
            var soundEffectsEnabled = true
        }
        """
        testFormatting(for: input, rule: .privateSwiftUIDynamicProperties)
        testFormatting(for: input, rule: .privateStateVariables)
    }

    func testAppStorageInUnrelatedStructRemainsUnchanged() {
        let input = """
        struct Settings {
            @AppStorage("soundEffectsEnabled")
            var soundEffectsEnabled = true
        }
        """
        testFormatting(for: input, rule: .privateSwiftUIDynamicProperties)
        testFormatting(for: input, rule: .privateStateVariables)
    }

    func testAppStorageInViewAndViewModifierBecomesPrivate() {
        let input = """
        struct AppSettingsScreen: View {
            @AppStorage("soundEffectsEnabled")
            var soundEffectsEnabled = true
        }

        struct SoundEffectsModifier: ViewModifier {
            @AppStorage("soundEffectsEnabled")
            var soundEffectsEnabled = true
        }
        """
        let output = """
        struct AppSettingsScreen: View {
            @AppStorage("soundEffectsEnabled")
            private var soundEffectsEnabled = true
        }

        struct SoundEffectsModifier: ViewModifier {
            @AppStorage("soundEffectsEnabled")
            private var soundEffectsEnabled = true
        }
        """
        testFormatting(for: input, output, rule: .privateSwiftUIDynamicProperties)
        testFormatting(for: input, output, rule: .privateStateVariables)
    }

    func testNestedTypesDoNotInheritViewEligibility() {
        let input = """
        struct AppSettingsScreen: View {
            @AppStorage("soundEffectsEnabled") var soundEffectsEnabled = true

            final class ViewModel: ObservableObject {
                @AppStorage("soundEffectsEnabled") var soundEffectsEnabled = true
            }

            struct Settings {
                @AppStorage("soundEffectsEnabled") var soundEffectsEnabled = true
            }

            struct NestedView: View {
                @AppStorage("soundEffectsEnabled") var soundEffectsEnabled = true
            }
        }
        """
        let output = """
        struct AppSettingsScreen: View {
            @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled = true

            final class ViewModel: ObservableObject {
                @AppStorage("soundEffectsEnabled") var soundEffectsEnabled = true
            }

            struct Settings {
                @AppStorage("soundEffectsEnabled") var soundEffectsEnabled = true
            }

            struct NestedView: View {
                @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled = true
            }
        }
        """
        testFormatting(for: input, output, rule: .privateSwiftUIDynamicProperties)
        testFormatting(for: input, output, rule: .privateStateVariables)
    }

    func testNestedTypesInExtensionsUseTheirOwnConformances() {
        let input = """
        struct AppSettingsScreen: View {}

        extension AppSettingsScreen {
            final class ViewModel: ObservableObject {
                @AppStorage("soundEffectsEnabled") var soundEffectsEnabled = true
            }

            struct NestedModifier: ViewModifier {
                @AppStorage("soundEffectsEnabled") var soundEffectsEnabled = true
            }
        }

        extension AppSettingsScreen.ViewModel {
            struct Settings {
                @AppStorage("soundEffectsEnabled") var soundEffectsEnabled = true
            }
        }
        """
        let output = """
        struct AppSettingsScreen: View {}

        extension AppSettingsScreen {
            final class ViewModel: ObservableObject {
                @AppStorage("soundEffectsEnabled") var soundEffectsEnabled = true
            }

            struct NestedModifier: ViewModifier {
                @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled = true
            }
        }

        extension AppSettingsScreen.ViewModel {
            struct Settings {
                @AppStorage("soundEffectsEnabled") var soundEffectsEnabled = true
            }
        }
        """
        testFormatting(for: input, output, rule: .privateSwiftUIDynamicProperties)
        testFormatting(for: input, output, rule: .privateStateVariables)
    }

    func testPrivateStateVariablesIsDeprecated() {
        XCTAssert(FormatRules.byName["privateStateVariables"]?.isDeprecated == true)
    }

    func testPrivateStateVariablesForwardsToPrivateSwiftUIDynamicProperties() {
        let input = """
        struct ContentView: View {
            @State var counter: Int
        }
        """
        let output = """
        struct ContentView: View {
            @State private var counter: Int
        }
        """
        testFormatting(for: input, output, rule: .privateStateVariables)
    }
}
