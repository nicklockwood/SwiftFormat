//
//  InferenceTests.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 21/10/2016.
//  Copyright © 2016 Nick Lockwood.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/SwiftFormat
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

@testable import SwiftFormat
import XCTest

class InferenceTests: XCTestCase {
    static let files: [String] = {
        var files = [String]()
        let inputURL = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent()

        _ = enumerateFiles(withInputURL: inputURL) { url, _, _ in
            return {
                if let source = try? String(contentsOf: url) {
                    files.append(source)
                }
            }
        }
        return files
    }()

    func testInferOptionsForProject() {
        let files = InferenceTests.files
        let tokens = files.flatMap { tokenize($0) }
        let options = Options(formatOptions: inferFormatOptions(from: tokens))
        let arguments = serialize(options: options, excludingDefaults: true, separator: " ")
        XCTAssertEqual(arguments, "--binarygrouping none --decimalgrouping none --hexgrouping none --octalgrouping none --wraparguments afterfirst --wrapcollections beforefirst")
    }

    // MARK: indent

    func testInferIndentLevel() {
        let input = """
        \t
        class Foo {
            func bar() {
                baz()
                quux()
                let foo = Foo()
            }
        }
        """
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.indent.count, 4)
    }

    func testInferIndentWithComment() {
        let input = """
        class Foo {
            /*
             A multiline comment
              which has unusual
               indenting that
                might screw up
                 the indent inference
             */
        }
        """
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.indent.count, 4)
    }

    func testInferIndentWithWrappedFunction() {
        let input = """
        class Foo {
            func foo(arg: Int,
                     arg: Int,
                     arg: Int) {}

            func bar(arg: Int,
                     arg: Int,
                     arg: Int) {}

            func baz(arg: Int,
                     arg: Int,
                     arg: Int) {}
        }
        """
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.indent.count, 4)
    }

    // MARK: linebreak

    func testInferLinebreaks() {
        let input = "foo\nbar\r\nbaz\rquux\r\n"
        let output = "\r\n"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.linebreak, output)
    }

    // MARK: spaceAroundRangeOperators

    func testInferSpaceAroundRangeOperators() {
        let input = "let foo = 0 ..< bar\n;let baz = 1...quux"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertTrue(options.spaceAroundRangeOperators)
    }

    func testInferNoSpaceAroundRangeOperators() {
        let input = "let foo = 0..<bar\n;let baz = 1...quux"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertFalse(options.spaceAroundRangeOperators)
    }

    // MARK: useVoid

    func testInferUseVoid() {
        let input = "func foo(bar: () -> (Void), baz: ()->(), quux: () -> Void) {}"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertTrue(options.useVoid)
    }

    func testInferDontUseVoid() {
        let input = "func foo(bar: () -> (), baz: ()->(), quux: () -> Void) {}"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertFalse(options.useVoid)
    }

    // MARK: trailingCommas

    func testInferTrailingCommas() {
        let input = "let foo = [\nbar,\n]\n let baz = [\nquux\n]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertTrue(options.trailingCommas)
    }

    func testInferNoTrailingCommas() {
        let input = "let foo = [\nbar\n]\n let baz = [\nquux\n]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertFalse(options.trailingCommas)
    }

    // MARK: indentComments

    func testInferIndentComments() {
        let input = "  /**\n  hello\n    - world\n  */"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertFalse(options.indentComments)
    }

    // MARK: truncateBlankLines

    func testInferNoTruncateBlanklines() {
        let input = "class Foo {\n    \nfunc bar() {\n        \n        //baz\n\n}\n    \n}"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertFalse(options.truncateBlankLines)
    }

    // MARK: allmanBraces

    func testInferAllmanComments() {
        let input = "func foo()\n{\n}\n\nfunc bar() {\n}\n\nfunc baz()\n{\n}"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertTrue(options.allmanBraces)
    }

    // MARK: ifdefIndent

    func testInferIfdefIndent() {
        let input = "#if foo\n    //foo\n#endif"
        let output = IndentMode.indent
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.ifdefIndent, output)
    }

    func testInferIdententIfdefIndent() {
        let input = "{\n    {\n#    if foo\n        //foo\n    #endif\n    }\n}"
        let output = IndentMode.indent
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.ifdefIndent, output)
    }

    func testInferIfdefNoIndent() {
        let input = "#if foo\n//foo\n#endif"
        let output = IndentMode.noIndent
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.ifdefIndent, output)
    }

    func testInferIdententIfdefNoIndent() {
        let input = "{\n    {\n    #if foo\n    //foo\n    #endif\n    }\n}"
        let output = IndentMode.noIndent
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.ifdefIndent, output)
    }

    func testInferIndentedIfdefOutdent() {
        let input = "{\n    {\n#if foo\n        //foo\n#endif\n    }\n}"
        let output = IndentMode.outdent
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.ifdefIndent, output)
    }

    // MARK: wrapArguments

    func testInferWrapBeforeFirstArgument() {
        let input = "func foo(\n    bar: Int,\n    baz: String) {}\nfunc foo(\n    bar: Int,\n    baz: String)"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.wrapArguments, .beforeFirst)
    }

    func testInferWrapAfterFirstArgument() {
        let input = "func foo(bar: Int,\n    baz: String,\n    quux: String) {}"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.wrapArguments, .afterFirst)
    }

    func testInferWrapPreserve() {
        let input = "func foo(bar: Int,\n    baz: String) {}\nfunc foo(\n    bar: Int,\n    baz: String) {}\nfunc foo(\n    bar: Int,\n    baz: String)\nfunc foo(bar: Int,\n    baz: String,\n    quux: String) {}"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.wrapArguments, .preserve)
    }

    // MARK: wrapCollections

    func testInferWrapElementsAfterFirstArgument() {
        let input = "[foo: 1,\n    bar: 2, baz: 3]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.wrapCollections, .afterFirst)
    }

    func testInferWrapElementsAfterSecondArgument() {
        let input = "[foo, bar,\n]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.wrapCollections, .afterFirst)
    }

    // MARK: closingParenOnSameLine

    func testInferParenOnSameLine() {
        let input = "func foo(\n    bar: Int,\n    baz: String) {\n}\nfunc foo(\n    bar: Int,\n    baz: String)"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertTrue(options.closingParenOnSameLine)
    }

    func testInferParenOnNextLine() {
        let input = "func foo(\n    bar: Int,\n    baz: String) {\n}\nfunc foo(\n    bar: Int,\n    baz: String\n)"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertFalse(options.closingParenOnSameLine)
    }

    // MARK: uppercaseHex

    func testInferUppercaseHex() {
        let input = "[0xFF00DD, 0xFF00ee, 0xff00ee"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertTrue(options.uppercaseHex)
    }

    func testInferLowercaseHex() {
        let input = "[0xff00dd, 0xFF00ee, 0xff00ee"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertFalse(options.uppercaseHex)
    }

    // MARK: uppercaseExponent

    func testInferUppercaseExponent() {
        let input = "[1.34E-5, 1.34E-5]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertTrue(options.uppercaseExponent)
    }

    func testInferLowercaseExponent() {
        let input = "[1.34E-5, 1.34e-5]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertFalse(options.uppercaseExponent)
    }

    func testInferUppercaseHexExponent() {
        let input = "[0xF1.34P5, 0xF1.34P5]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertTrue(options.uppercaseExponent)
    }

    func testInferLowercaseHexExponent() {
        let input = "[0xF1.34P5, 0xF1.34p5]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertFalse(options.uppercaseExponent)
    }

    // MARK: decimalGrouping

    func testInferThousands() {
        let input = "[100_000, 1_000, 1, 23, 50]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.decimalGrouping, .group(3, 4))
    }

    func testInferMillions() {
        let input = "[1_000_000, 1000, 1, 23, 50]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.decimalGrouping, .group(3, 7))
    }

    func testInferNoDecimalGrouping() {
        let input = "[100000, 1000, 1, 23, 50]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.decimalGrouping, .none)
    }

    func testInferIgnoreDecimalGrouping() {
        let input = "[1000_00, 1_000, 100, 23, 50]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.decimalGrouping, .ignore)
    }

    // MARK: fractionGrouping

    func testInferFractionGrouping() {
        let input = "[100.0_001, 1.00_002, 1.0, 23.001, 50]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertTrue(options.fractionGrouping)
    }

    func testInferFractionGrouping2() {
        let input = "[100.0_001, 1.00_002, 1_000.0, 23_234.001, 50]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertTrue(options.fractionGrouping)
    }

    func testInferNoFractionGrouping() {
        let input = "[1.00002, 1.0001, 1.103, 0.23, 0.50]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertFalse(options.fractionGrouping)
    }

    func testInferNoFractionGrouping2() {
        let input = "[1_000.00002, 1_123.0001, 1.103, 0.23, 0.50]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertFalse(options.fractionGrouping)
    }

    // MARK: binaryGrouping

    func testInferNibbleGrouping() {
        let input = "[0b100_0000, 0b1_0000, 0b1, 0b01, 0b11]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.binaryGrouping, .group(4, 5))
    }

    func testInferByteGrouping() {
        let input = "[0b1000_1101, 0b10010000, 0b1, 0b01, 0b11]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.binaryGrouping, .group(4, 8))
    }

    func testInferNoBinaryGrouping() {
        let input = "[0b1010100000, 0b100100, 0b1, 0b01, 0b11]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.binaryGrouping, .none)
    }

    func testInferIgnoreBinaryGrouping() {
        let input = "[0b10_000_00, 0b10_000, 0b1, 0b01, 0b11]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.binaryGrouping, .ignore)
    }

    // MARK: octalGrouping

    func testInferQuadOctalGrouping() {
        let input = "[0o123_4523, 0b1_4523, 0o5, 0o23, 0o14]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.octalGrouping, .group(4, 7))
    }

    func testInferOctetOctalGrouping() {
        let input = "[0o1123_4523_1123_4523, 0o12344563, 0o1, 0o01, 0o12]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.octalGrouping, .group(4, 16))
    }

    func testInferNoOctalGrouping() {
        let input = "[0o11234523, 0o112345, 0o1, 0o01, 0o21]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.octalGrouping, .none)
    }

    func testInferIgnoreOctalGrouping() {
        let input = "[0o11_2345_23, 0o1_0000, 0o1, 0o01, 0o11]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.octalGrouping, .ignore)
    }

    // MARK: hexGrouping

    func testInferQuadHexGrouping() {
        let input = "[0x123_FF23, 0x1_4523, 0x5, 0x23, 0x14]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.hexGrouping, .group(4, 5))
    }

    func testInferOctetHexGrouping() {
        let input = "[0x1123_45FF_112A_A523, 0x12344563, 0x1, 0x01, 0x12]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.hexGrouping, .group(4, 16))
    }

    func testInferNoHexGrouping() {
        let input = "[0x11234523, 0x112345, 0x1, 0x01, 0x21]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.hexGrouping, .none)
    }

    func testInferIgnoreHexGrouping() {
        let input = "[0x11_2345_23, 0x10_F00, 0x1, 0x01, 0x11]"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertEqual(options.hexGrouping, .ignore)
    }

    // MARK: hoistPatternLet

    func testInferHoisted() {
        let input = "if case let .foo(bar, baz) = quux {}"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertTrue(options.hoistPatternLet)
    }

    func testInferUnhoisted() {
        let input = "if case .foo(let bar, let baz) = quux {}"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertFalse(options.hoistPatternLet)
    }

    // MARK: removeSelf

    func testInferInsertSelf() {
        let input = """
        struct Foo {
            var foo: Int
            var bar: Int
            func baz() {
                self.foo()
                self.bar()
            }
        }
        """
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertFalse(options.removeSelf)
    }

    func testInferRemoveSelf() {
        let input = """
        struct Foo {
            var foo: Int
            var bar: Int
            func baz() {
                foo()
                bar()
            }
        }
        """
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertTrue(options.removeSelf)
    }

    func testInferRemoveSelf2() {
        let input = """
        struct Foo {
            var foo: Int
            var bar: Int
            func baz() {
                self.foo()
                bar()
            }
        }
        """
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertTrue(options.removeSelf)
    }

    // MARK: spaceAroundOperatorDeclarations

    func testInferSpaceAfterOperatorFunc() {
        let input = "func == (lhs: Int, rhs: Int) -> Bool {}"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertTrue(options.spaceAroundOperatorDeclarations)
    }

    func testInferNoSpaceAfterOperatorFunc() {
        let input = "func ==(lhs: Int, rhs: Int) -> Bool {}"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertFalse(options.spaceAroundOperatorDeclarations)
    }

    // MARK: elseOnNextLine

    func testInferElseOnNextLine() {
        let input = "if foo {\n}\nelse {}"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertTrue(options.elseOnNextLine)
    }

    func testInferElseOnSameLine() {
        let input = "if foo {\n} else {}"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertFalse(options.elseOnNextLine)
    }

    func testIgnoreInlineIfElse() {
        let input = "if foo {} else {}\nif foo {\n}\nelse {}"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertTrue(options.elseOnNextLine)
    }

    // MARK: indentCase

    func testInferIndentCase() {
        let input = "switch {\n    case foo: break\n}"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertTrue(options.indentCase)
    }

    func testInferNoIndentCase() {
        let input = "switch {\ncase foo: break\n}"
        let options = inferFormatOptions(from: tokenize(input))
        XCTAssertFalse(options.indentCase)
    }
}
