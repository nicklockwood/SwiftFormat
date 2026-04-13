import XCTest
@testable import SwiftFormat

class TokenDebugTests: XCTestCase {
    func testTokenize() {
        let input = """
        if let value = someOptional,
           let result: String? = switch value {
           case .a: "hello"
           case .b: "world"
           }, let result
        {
            print(result)
        }
        """
        let tokens = tokenize(input)
        for (i, token) in tokens.enumerated() {
            print("\(i): \(token)")
        }
        XCTFail("Intentional failure to see output")
    }
}
