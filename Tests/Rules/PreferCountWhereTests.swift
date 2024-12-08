//
//  PreferCountWhereTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 12/7/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation
import XCTest
@testable import SwiftFormat

final class PreferCountWhereTests: XCTestCase {
    func testConvertFilterToCountWhere() {
        let input = """
        planets.filter({ !$0.moons.isEmpty }).count
        """

        let output = """
        planets.count(where: { !$0.moons.isEmpty })
        """

        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, output, rule: .preferCountWhere, options: options)
    }

    func testConvertFilterTrailingClosureToCountWhere() {
        let input = """
        planets.filter { !$0.moons.isEmpty }.count
        """

        let output = """
        planets.count(where: { !$0.moons.isEmpty })
        """

        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, output, rule: .preferCountWhere, options: options)
    }

    func testConvertNestedFilter() {
        let input = """
        planets.filter { planet in
            planet.moons.filter { moon in
                moon.hasAtmosphere
            }.count > 1
        }.count
        """

        let output = """
        planets.count(where: { planet in
            planet.moons.count(where: { moon in
                moon.hasAtmosphere
            }) > 1
        })
        """

        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, output, rule: .preferCountWhere, options: options)
    }

    func testPreservesFilterBeforeSwift6() {
        let input = """
        planets.filter { !$0.moons.isEmpty }.count
        """

        let options = FormatOptions(swiftVersion: "5.10")
        testFormatting(for: input, rule: .preferCountWhere, options: options)
    }

    func testPreservesCountMethod() {
        let input = """
        planets.filter { !$0.moons.isEmpty }.count(of: earth)
        """

        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, rule: .preferCountWhere, options: options)
    }
}
