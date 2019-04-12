//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest

class ReturnCodeTests: XCTestCase {
    func testReturnsSuccessCodeForExpectedInput() {
        XCTAssertEqual(processArguments(["LayoutTool", "version"]), .success)
    }

    func testReturnsErrorCodeWhenErrorsOccur() {
        XCTAssertEqual(processArguments(["LayoutTool"]), .failure)
        XCTAssertEqual(processArguments(["LayoutTool", "format"]), .failure)
    }
}
