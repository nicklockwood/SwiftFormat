import XCTest

class TestCase: XCTestCase {
    func test_something() throws {
        let value = try XCTUnwrap(optionalValue)
    }
}
