//
//  WrapLoopBodiesTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 1/3/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class WrapLoopBodiesTests: XCTestCase {
    func testWrapUnsafeForLoop() {
        let input = """
        for unsafe child in unsafe $0.children { child.gatherStatistics(level.descend(), &stats) }
        """
        let output = """
        for unsafe child in unsafe $0.children {
            child.gatherStatistics(level.descend(), &stats)
        }
        """
        testFormatting(for: input, output, rule: .wrapLoopBodies)
    }

    func testWrapForLoop() {
        let input = """
        for foo in bar { print(foo) }
        """
        let output = """
        for foo in bar {
            print(foo)
        }
        """
        testFormatting(for: input, output, rule: .wrapLoopBodies)
    }

    func testWrapWhileLoop() {
        let input = """
        while let foo = bar.next() { print(foo) }
        """
        let output = """
        while let foo = bar.next() {
            print(foo)
        }
        """
        testFormatting(for: input, output, rule: .wrapLoopBodies)
    }

    func testWrapRepeatWhileLoop() {
        let input = """
        repeat { print(foo) } while condition()
        """
        let output = """
        repeat {
            print(foo)
        } while condition()
        """
        testFormatting(for: input, output, rule: .wrapLoopBodies)
    }
}
