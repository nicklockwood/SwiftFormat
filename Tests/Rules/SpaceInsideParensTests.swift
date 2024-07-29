//
//  SpaceInsideParensTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 8/22/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class SpaceInsideParensTests: XCTestCase {
    func testSpaceInsideParens() {
        let input = "( 1, ( 2, 3 ) )"
        let output = "(1, (2, 3))"
        testFormatting(for: input, output, rule: .spaceInsideParens)
    }

    func testSpaceBeforeCommentInsideParens() {
        let input = "( /* foo */ 1, 2 )"
        let output = "( /* foo */ 1, 2)"
        testFormatting(for: input, output, rule: .spaceInsideParens)
    }
}
