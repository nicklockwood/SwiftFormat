//
//  WrapSwitchCasesTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 8/28/20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class WrapSwitchCasesTests: XCTestCase {
    func testMultilineSwitchCases() {
        let input = """
        func foo() {
            switch bar {
            case .a(_), .b, "c":
                print("")
            case .d:
                print("")
            }
        }
        """
        let output = """
        func foo() {
            switch bar {
            case .a(_),
                 .b,
                 "c":
                print("")
            case .d:
                print("")
            }
        }
        """
        testFormatting(for: input, output, rule: .wrapSwitchCases)
    }

    func testIfAfterSwitchCaseNotWrapped() {
        let input = """
        switch foo {
        case "foo":
            print("")
        default:
            print("")
        }
        if let foo = bar, foo != .baz {
            throw error
        }
        """
        testFormatting(for: input, rule: .wrapSwitchCases)
    }
}
