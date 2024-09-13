//
//  PrivateStateVariablesTests.swift
//  SwiftFormatTests
//
//  Created by Dave Paul on 9/9/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class PrivateStateVariablesTests: XCTestCase {
    func testPrivateState() {
        let input = """
        @State var counter: Int
        """
        let output = """
        @State private var counter: Int
        """
        testFormatting(for: input, output, rule: .privateStateVariables)
    }

    func testPrivateStateObject() {
        let input = """
        @StateObject var counter: Int
        """
        let output = """
        @StateObject private var counter: Int
        """
        testFormatting(for: input, output, rule: .privateStateVariables)
    }

    func testUseExisting() {
        let input = """
        @State private var counter: Int
        """
        testFormatting(for: input, rule: .privateStateVariables)
    }

    func testRespectingPublicOverride() {
        let input = """
        @StateObject public var counter: Int
        """
        testFormatting(for: input, rule: .privateStateVariables)
    }

    func testRespectingPackageOverride() {
        let input = """
        @State package var counter: Int
        """
        testFormatting(for: input, rule: .privateStateVariables)
    }

    func testRespectingOverrideWithSetterModifier() {
        let input = """
        @State private(set) var counter: Int
        """
        testFormatting(for: input, rule: .privateStateVariables)
    }

    func testRespectingOverrideWithExistingAccessAndSetterModifier() {
        let input = """
        @StateObject public private(set) var counter: Int
        """
        testFormatting(for: input, rule: .privateStateVariables)
    }

    func testStateVariableOnPreviousLine() {
        let input = """
        @State
        var counter: Int
        """
        let output = """
        @State
        private var counter: Int
        """
        testFormatting(for: input, output, rule: .privateStateVariables)
    }

    func testWithPreviewable() {
        // Don't add `private` to @Previewable property wrappers:
        let input = """
        @Previewable @StateObject var counter: Int
        """
        testFormatting(for: input, rule: .privateStateVariables)
    }
}
