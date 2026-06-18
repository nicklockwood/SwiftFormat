//
//  WrapConditionalBodiesTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 11/6/21.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class WrapConditionalBodiesTests: XCTestCase {
    func testWrapConditionalBodiesIsDeprecated() {
        XCTAssert(FormatRules.byName["wrapConditionalBodies"]?.isDeprecated == true)
    }
}
