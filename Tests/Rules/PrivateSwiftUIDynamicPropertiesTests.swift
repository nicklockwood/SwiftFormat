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
    func testPrivateDynamicProperties() {
        let input = """
        struct ContentView {
            @AppStorage("isVisible") var isVisible: Bool
            @Binding var isPresented: Bool
            @Environment(\\.openURL) var openURL
            @EnvironmentObject var store: Store
            @ObservedObject var viewModel: ViewModel
            @StateObject var model: Model
        }
        """
        let output = """
        struct ContentView {
            @AppStorage("isVisible") private var isVisible: Bool
            @Binding var isPresented: Bool
            @Environment(\\.openURL) private var openURL
            @EnvironmentObject private var store: Store
            @ObservedObject private var viewModel: ViewModel
            @StateObject private var model: Model
        }
        """
        testFormatting(for: input, output, rule: .privateSwiftUIDynamicProperties)
    }

    func testDoesNotMakeBindingPrivateInInternalType() {
        let input = """
        struct ContentView {
            @Binding var isPresented: Bool
        }
        """
        testFormatting(for: input, rule: .privateSwiftUIDynamicProperties)
    }

    func testMakesBindingPrivateInPublicOrOpenType() {
        let input = """
        public struct PublicContentView {
            @Binding var text: String
        }

        open class OpenContentView {
            @Binding var text: String
        }
        """
        let output = """
        public struct PublicContentView {
            @Binding private var text: String
        }

        open class OpenContentView {
            @Binding private var text: String
        }
        """
        testFormatting(for: input, output, rule: .privateSwiftUIDynamicProperties)
    }

    func testPrivateNamespacedDynamicProperty() {
        let input = """
        struct ContentView {
            @SwiftUI::State var counter: Int
        }
        """
        let output = """
        struct ContentView {
            @SwiftUI::State private var counter: Int
        }
        """
        testFormatting(for: input, output, rule: .privateSwiftUIDynamicProperties)
    }

    func testUseExistingAccessControl() {
        let input = """
        struct ContentView {
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
        struct ContentView {
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
        struct ContentView {
            @State
            var counter: Int
        }
        """
        let output = """
        struct ContentView {
            @State
            private var counter: Int
        }
        """
        testFormatting(for: input, output, rule: .privateSwiftUIDynamicProperties)
    }

    func testWithPreviewableOnSameLine() {
        // Don't add `private` to @Previewable property wrappers:
        let input = """
        struct ContentView {
            @Previewable @StateObject var counter: Int
        }
        """
        testFormatting(for: input, rule: .privateSwiftUIDynamicProperties)
    }

    func testWithPreviewableOnPreviousLine() {
        // Don't add `private` to @Previewable property wrappers:
        let input = """
        struct ContentView {
            @Previewable
            @State var counter: Int
        }
        """
        testFormatting(for: input, rule: .privateSwiftUIDynamicProperties)
    }

    func testPrivateStateVariablesIsDeprecated() {
        XCTAssert(FormatRules.byName["privateStateVariables"]?.isDeprecated == true)
    }

    func testPrivateStateVariablesForwardsToPrivateSwiftUIDynamicProperties() {
        let input = """
        struct ContentView {
            @State var counter: Int
        }
        """
        let output = """
        struct ContentView {
            @State private var counter: Int
        }
        """
        testFormatting(for: input, output, rule: .privateStateVariables)
    }
}
