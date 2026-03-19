import XCTest
@testable import SwiftFormat

class ReproTest: XCTestCase {
    // What does trailingCommas do to > when it's on its own line in expression context?
    func testGenericAngleBracketsInExpressionContext6_2() {
        // Array<Int>() - expression context
        // When > is on its own line, does trailingCommas add a comma?
        let input = """
        private let value: Int = Array<
            Int
        >()
        """
        // In Swift 6.2, generic argument list in expression context should NOT get trailing comma
        // (only allowed in Swift 6.3+)
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, rule: .trailingCommas, options: options, exclude: [.typeSugar, .propertyTypes])
    }
    
    func testGenericAngleBracketsInTypeContext6_2() {
        // Array<Int> - type context (type annotation)
        // When > is on its own line, trailing commas ARE allowed in Swift 6.2
        let input = """
        private let value: Array<
            Int
        > = Array<Int>()
        """
        let output = """
        private let value: Array<
            Int,
        > = Array<Int>()
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options, exclude: [.typeSugar, .propertyTypes])
    }
}
