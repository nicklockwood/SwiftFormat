//
//  OptionsTests.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 21/10/2016.
//  Copyright © 2016 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class OptionsTests: XCTestCase {

    // MARK: indent

    func testInferIndentLevel() {
        let input = "\t\nclass Foo {\n   func bar() {\n      //baz\n}\n}"
        let options = inferOptions(from: tokenize(input))
        XCTAssertEqual(options.indent, "   ")
    }

    // MARK: linebreak

    func testInferLinebreaks() {
        let input = "foo\nbar\r\nbaz\rquux\r\n"
        let output = "\r\n"
        let options = inferOptions(from: tokenize(input))
        XCTAssertEqual(options.linebreak, output)
    }

    // MARK: spaceAroundRangeOperators

    func testInferSpaceAroundRangeOperators() {
        let input = "let foo = 0 ..< bar\n;let baz = 1...quux"
        let output = true
        let options = inferOptions(from: tokenize(input))
        XCTAssertEqual(options.spaceAroundRangeOperators, output)
    }

    func testInferNoSpaceAroundRangeOperators() {
        let input = "let foo = 0..<bar\n;let baz = 1...quux"
        let output = false
        let options = inferOptions(from: tokenize(input))
        XCTAssertEqual(options.spaceAroundRangeOperators, output)
    }

    // MARK: useVoid

    func testInferUseVoid() {
        let input = "func foo(bar: () -> (Void), baz: ()->(), quux: () -> Void) {}"
        let output = true
        let options = inferOptions(from: tokenize(input))
        XCTAssertEqual(options.useVoid, output)
    }

    func testInferDontUseVoid() {
        let input = "func foo(bar: () -> (), baz: ()->(), quux: () -> Void) {}"
        let output = false
        let options = inferOptions(from: tokenize(input))
        XCTAssertEqual(options.useVoid, output)
    }

    // MARK: trailingCommas

    func testInferTrailingCommas() {
        let input = "let foo = [\nbar,\n]\n let baz = [\nquux\n]"
        let output = true
        let options = inferOptions(from: tokenize(input))
        XCTAssertEqual(options.trailingCommas, output)
    }

    func testInferNoTrailingCommas() {
        let input = "let foo = [\nbar\n]\n let baz = [\nquux\n]"
        let output = false
        let options = inferOptions(from: tokenize(input))
        XCTAssertEqual(options.trailingCommas, output)
    }

    // MARK: indentComments

    func testInferIndentComments() {
        let input = "  /**\n  hello\n    - world\n  */"
        let output = false
        let options = inferOptions(from: tokenize(input))
        XCTAssertEqual(options.indentComments, output)
    }

    // MARK: truncateBlankLines

    func testInferNoTruncateBlanklines() {
        let input = "class Foo {\n    \nfunc bar() {\n        \n        //baz\n\n}\n    \n}"
        let output = false
        let options = inferOptions(from: tokenize(input))
        XCTAssertEqual(options.truncateBlankLines, output)
    }

    // MARK: allmanBraces

    func testInferAllmanComments() {
        let input = "func foo()\n{\n}\n\nfunc bar() {\n}\n\nfunc baz()\n{\n}"
        let output = true
        let options = inferOptions(from: tokenize(input))
        XCTAssertEqual(options.allmanBraces, output)
    }

    // MARK: ifdefIndent

    func testInferIfdefIndent() {
        let input = "#if foo\n    //foo\n#endif"
        let output = IndentMode.indent
        let options = inferOptions(from: tokenize(input))
        XCTAssertEqual(options.ifdefIndent, output)
    }

    func testInferIdententIfdefIndent() {
        let input = "{\n    {\n#    if foo\n        //foo\n    #endif\n    }\n}"
        let output = IndentMode.indent
        let options = inferOptions(from: tokenize(input))
        XCTAssertEqual(options.ifdefIndent, output)
    }

    func testInferIfdefNoIndent() {
        let input = "#if foo\n//foo\n#endif"
        let output = IndentMode.noIndent
        let options = inferOptions(from: tokenize(input))
        XCTAssertEqual(options.ifdefIndent, output)
    }

    func testInferIdententIfdefNoIndent() {
        let input = "{\n    {\n    #if foo\n    //foo\n    #endif\n    }\n}"
        let output = IndentMode.noIndent
        let options = inferOptions(from: tokenize(input))
        XCTAssertEqual(options.ifdefIndent, output)
    }

    func testInferIndentedIfdefOutdent() {
        let input = "{\n    {\n#if foo\n        //foo\n#endif\n    }\n}"
        let output = IndentMode.outdent
        let options = inferOptions(from: tokenize(input))
        XCTAssertEqual(options.ifdefIndent, output)
    }

    // MARK: wrapArguments

    func testInferWrapBeforeFirstArgument() {
        let input = "func foo(bar: Int,\n    baz: String) {\n}\nfunc foo(\n    bar: Int,\n    baz: String) {\n}\nfunc foo(\n    bar: Int,\n    baz: String)"
        let output = WrapMode.beforeFirst
        let options = inferOptions(from: tokenize(input))
        XCTAssertEqual(options.wrapArguments, output)
    }

    func testInferWrapAfterFirstArgument() {
        let input = "func foo(bar: Int,\n    baz: String,\n    quux: String) {\n}"
        let output = WrapMode.afterFirst
        let options = inferOptions(from: tokenize(input))
        XCTAssertEqual(options.wrapArguments, output)
    }

    func testInferWrapDisabled() {
        let input = "func foo(bar: Int, baz: String,\n    quux: String) {\n}"
        let output = WrapMode.disabled
        let options = inferOptions(from: tokenize(input))
        XCTAssertEqual(options.wrapArguments, output)
    }

    // MARK: wrapElements

    func testInferWrapElementsAfterFirstArgument() {
        let input = "[foo: 1,\n    bar: 2, baz: 3]"
        let output = WrapMode.afterFirst
        let options = inferOptions(from: tokenize(input))
        XCTAssertEqual(options.wrapElements, output)
    }
}
