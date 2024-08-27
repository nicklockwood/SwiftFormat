//
//  SpaceAroundGenericsTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 8/22/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class SpaceAroundGenericsTests: XCTestCase {
    func testSpaceAroundGenerics() {
        let input = "Foo <Bar <Baz>>"
        let output = "Foo<Bar<Baz>>"
        testFormatting(for: input, output, rule: .spaceAroundGenerics)
    }

    func testSpaceAroundGenericsFollowedByAndOperator() {
        let input = "if foo is Foo<Bar> && baz {}"
        testFormatting(for: input, rule: .spaceAroundGenerics, exclude: [.andOperator])
    }

    func testSpaceAroundGenericResultBuilder() {
        let input = "func foo(@SomeResultBuilder<Self> builder: () -> Void) {}"
        testFormatting(for: input, rule: .spaceAroundGenerics)
    }
}
