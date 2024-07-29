//
//  RedundantLetErrorTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class RedundantLetErrorTests: XCTestCase {
    func testCatchLetError() {
        let input = "do {} catch let error {}"
        let output = "do {} catch {}"
        testFormatting(for: input, output, rule: .redundantLetError)
    }

    func testCatchLetErrorWithTypedThrows() {
        let input = "do throws(Foo) {} catch let error {}"
        let output = "do throws(Foo) {} catch {}"
        testFormatting(for: input, output, rule: .redundantLetError)
    }
}
