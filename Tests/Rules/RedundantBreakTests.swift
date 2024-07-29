//
//  RedundantBreakTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 1/23/19.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class RedundantBreakTests: XCTestCase {
    func testRedundantBreaksRemoved() {
        let input = """
        switch x {
        case foo:
            print("hello")
            break
        case bar:
            print("world")
            break
        default:
            print("goodbye")
            break
        }
        """
        let output = """
        switch x {
        case foo:
            print("hello")
        case bar:
            print("world")
        default:
            print("goodbye")
        }
        """
        testFormatting(for: input, output, rule: .redundantBreak)
    }

    func testBreakInEmptyCaseNotRemoved() {
        let input = """
        switch x {
        case foo:
            break
        case bar:
            break
        default:
            break
        }
        """
        testFormatting(for: input, rule: .redundantBreak)
    }

    func testConditionalBreakNotRemoved() {
        let input = """
        switch x {
        case foo:
            if bar {
                break
            }
        }
        """
        testFormatting(for: input, rule: .redundantBreak)
    }

    func testBreakAfterSemicolonNotMangled() {
        let input = """
        switch foo {
        case 1: print(1); break
        }
        """
        let output = """
        switch foo {
        case 1: print(1);
        }
        """
        testFormatting(for: input, output, rule: .redundantBreak, exclude: [.semicolons])
    }
}
