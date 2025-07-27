//
//  StrongifiedSelfTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 1/24/19.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class StrongifiedSelfTests: XCTestCase {
    func testBacktickedSelfConvertedToSelfInGuard() {
        let input = """
        { [weak self] in
            guard let `self` = self else { return }
        }
        """
        let output = """
        { [weak self] in
            guard let self = self else { return }
        }
        """
        let options = FormatOptions(swiftVersion: "4.2")
        testFormatting(for: input, output, rule: .strongifiedSelf, options: options,
                       exclude: [.wrapConditionalBodies])
    }

    func testBacktickedSelfConvertedToSelfInIf() {
        let input = """
        { [weak self] in
            if let `self` = self else { print(self) }
        }
        """
        let output = """
        { [weak self] in
            if let self = self else { print(self) }
        }
        """
        let options = FormatOptions(swiftVersion: "4.2")
        testFormatting(for: input, output, rule: .strongifiedSelf, options: options,
                       exclude: [.wrapConditionalBodies])
    }

    func testBacktickedSelfNotConvertedIfVersionLessThan4_2() {
        let input = """
        { [weak self] in
            guard let `self` = self else { return }
        }
        """
        let options = FormatOptions(swiftVersion: "4.1.5")
        testFormatting(for: input, rule: .strongifiedSelf, options: options,
                       exclude: [.wrapConditionalBodies])
    }

    func testBacktickedSelfNotConvertedIfVersionUnspecified() {
        let input = """
        { [weak self] in
            guard let `self` = self else { return }
        }
        """
        testFormatting(for: input, rule: .strongifiedSelf,
                       exclude: [.wrapConditionalBodies])
    }

    func testBacktickedSelfNotConvertedIfNotConditional() {
        let input = """
        nonisolated(unsafe) let `self` = self
        """
        let options = FormatOptions(swiftVersion: "4.2")
        testFormatting(for: input, rule: .strongifiedSelf, options: options)
    }
}
