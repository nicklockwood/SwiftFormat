//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest
@testable import Layout

class OptionSetExpressionTests: XCTestCase {
    func testSingleDataDetectorType() {
        let node = LayoutNode(
            view: UITextView(),
            expressions: [
                "dataDetectorTypes": "phoneNumber",
            ]
        )
        XCTAssertEqual(try node.value(forSymbol: "dataDetectorTypes") as? UIDataDetectorTypes, .phoneNumber)
    }

    func testMultipleDataDetectorTypes() {
        let node = LayoutNode(
            view: UITextView(),
            expressions: [
                "dataDetectorTypes": "phoneNumber, address, link",
            ]
        )
        XCTAssertEqual(try node.value(forSymbol: "dataDetectorTypes") as? UIDataDetectorTypes, [.phoneNumber, .address, .link])
    }
}
