//
//  SpaceInsideBracketsTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 8/22/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class SpaceInsideBracketsTests: XCTestCase {
    func testSpaceInsideBrackets() {
        let input = "foo[ 5 ]"
        let output = "foo[5]"
        testFormatting(for: input, output, rule: .spaceInsideBrackets)
    }

    func testSpaceInsideWrappedArray() {
        let input = "[ foo,\n bar ]"
        let output = "[foo,\n bar]"
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, output, rule: .spaceInsideBrackets, options: options)
    }

    func testSpaceBeforeCommentInsideWrappedArray() {
        let input = "[ // foo\n    bar,\n]"
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, rule: .spaceInsideBrackets, options: options)
    }
}
