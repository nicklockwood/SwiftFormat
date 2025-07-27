//
//  SpaceInsideGenericsTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 8/22/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class SpaceInsideGenericsTests: XCTestCase {
    func testSpaceInsideGenerics() {
        let input = """
        Foo< Bar< Baz > >
        """
        let output = """
        Foo<Bar<Baz>>
        """
        testFormatting(for: input, output, rule: .spaceInsideGenerics)
    }
}
