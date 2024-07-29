//
//  AndOperatorTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class AndOperatorTests: XCTestCase {
    func testIfAndReplaced() {
        let input = "if true && true {}"
        let output = "if true, true {}"
        testFormatting(for: input, output, rule: .andOperator)
    }

    func testGuardAndReplaced() {
        let input = "guard true && true\nelse { return }"
        let output = "guard true, true\nelse { return }"
        testFormatting(for: input, output, rule: .andOperator,
                       exclude: [.wrapConditionalBodies])
    }

    func testWhileAndReplaced() {
        let input = "while true && true {}"
        let output = "while true, true {}"
        testFormatting(for: input, output, rule: .andOperator)
    }

    func testIfDoubleAndReplaced() {
        let input = "if true && true && true {}"
        let output = "if true, true, true {}"
        testFormatting(for: input, output, rule: .andOperator)
    }

    func testIfAndParensReplaced() {
        let input = "if true && (true && true) {}"
        let output = "if true, (true && true) {}"
        testFormatting(for: input, output, rule: .andOperator,
                       exclude: [.redundantParens])
    }

    func testIfFunctionAndReplaced() {
        let input = "if functionReturnsBool() && true {}"
        let output = "if functionReturnsBool(), true {}"
        testFormatting(for: input, output, rule: .andOperator)
    }

    func testNoReplaceIfOrAnd() {
        let input = "if foo || bar && baz {}"
        testFormatting(for: input, rule: .andOperator)
    }

    func testNoReplaceIfAndOr() {
        let input = "if foo && bar || baz {}"
        testFormatting(for: input, rule: .andOperator)
    }

    func testIfAndReplacedInFunction() {
        let input = "func someFunc() { if bar && baz {} }"
        let output = "func someFunc() { if bar, baz {} }"
        testFormatting(for: input, output, rule: .andOperator)
    }

    func testNoReplaceIfCaseLetAnd() {
        let input = "if case let a = foo && bar {}"
        testFormatting(for: input, rule: .andOperator)
    }

    func testNoReplaceWhileCaseLetAnd() {
        let input = "while case let a = foo && bar {}"
        testFormatting(for: input, rule: .andOperator)
    }

    func testNoReplaceRepeatWhileAnd() {
        let input = """
        repeat {} while true && !false
        foo {}
        """
        testFormatting(for: input, rule: .andOperator)
    }

    func testNoReplaceIfLetAndLetAnd() {
        let input = "if let a = b && c, let d = e && f {}"
        testFormatting(for: input, rule: .andOperator)
    }

    func testNoReplaceIfTryAnd() {
        let input = "if try true && explode() {}"
        testFormatting(for: input, rule: .andOperator)
    }

    func testHandleAndAtStartOfLine() {
        let input = "if a == b\n    && b == c {}"
        let output = "if a == b,\n    b == c {}"
        testFormatting(for: input, output, rule: .andOperator, exclude: [.indent])
    }

    func testHandleAndAtStartOfLineAfterComment() {
        let input = "if a == b // foo\n    && b == c {}"
        let output = "if a == b, // foo\n    b == c {}"
        testFormatting(for: input, output, rule: .andOperator, exclude: [.indent])
    }

    func testNoReplaceAndOperatorWhereGenericsAmbiguous() {
        let input = "if x < y && z > (a * b) {}"
        testFormatting(for: input, rule: .andOperator)
    }

    func testNoReplaceAndOperatorWhereGenericsAmbiguous2() {
        let input = "if x < y && z && w > (a * b) {}"
        let output = "if x < y, z && w > (a * b) {}"
        testFormatting(for: input, output, rule: .andOperator)
    }

    func testAndOperatorCrash() {
        let input = """
        DragGesture().onChanged { gesture in
            if gesture.translation.width < 50 && gesture.translation.height > 50 {
                offset = gesture.translation
            }
        }
        """
        let output = """
        DragGesture().onChanged { gesture in
            if gesture.translation.width < 50, gesture.translation.height > 50 {
                offset = gesture.translation
            }
        }
        """
        testFormatting(for: input, output, rule: .andOperator)
    }

    func testNoReplaceAndInViewBuilder() {
        let input = """
        SomeView {
            if foo == 5 && bar {
                Text("5")
            } else {
                Text("Not 5")
            }
        }
        """
        testFormatting(for: input, rule: .andOperator)
    }

    func testNoReplaceAndInViewBuilder2() {
        let input = """
        var body: some View {
            ZStack {
                if self.foo && self.bar {
                    self.closedPath
                }
            }
        }
        """
        testFormatting(for: input, rule: .andOperator)
    }

    func testReplaceAndInViewBuilderInSwift5_3() {
        let input = """
        SomeView {
            if foo == 5 && bar {
                Text("5")
            } else {
                Text("Not 5")
            }
        }
        """
        let output = """
        SomeView {
            if foo == 5, bar {
                Text("5")
            } else {
                Text("Not 5")
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.3")
        testFormatting(for: input, output, rule: .andOperator, options: options)
    }
}
