//
//  CompilerTests.swift
//  ConsumerTests
//
//  Created by Nick Lockwood on 03/03/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/Consumer
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

import Foundation
import XCTest
@testable import Consumer

class CompilerTests: XCTestCase {
    func testString() throws {
        try compile(.string("foo"))
        XCTAssertEqual(try parse("foo"), "foo")
        XCTAssertThrowsError(try parse("foo ")) { error in
            XCTAssert("\(error)".contains("Unexpected token ' ' at 1:4"))
        }
        XCTAssertThrowsError(try parse("bar")) { error in
            XCTAssert("\(error)".contains("Unexpected token 'bar' at 1:1 (expected test)"))
        }
    }

    func testCodePoint() throws {
        try compile(.character(in: "A" ... "F"))
        XCTAssertEqual(try parse("B"), "B")
        XCTAssertThrowsError(try parse("a "))
        XCTAssertThrowsError(try parse("z"))
    }

    func testAny() throws {
        try compile("foo" | "bar")
        XCTAssertEqual(try parse("foo"), "foo")
        XCTAssertEqual(try parse("bar"), "bar")
        XCTAssertThrowsError(try parse("foo "))
        XCTAssertThrowsError(try parse("foobar"))
    }

    func testSequence() throws {
        try compile(["foo", "bar"])
        XCTAssertEqual(try parse("foobar"), "foobar")
        XCTAssertThrowsError(try parse("foo"))
        XCTAssertThrowsError(try parse("bar"))
        XCTAssertThrowsError(try parse("barfoo"))
        XCTAssertThrowsError(try parse("foobar "))
    }

    func testZeroOrMore() throws {
        try compile(.zeroOrMore("foo"))
        XCTAssertEqual(try parse("foo"), "foo")
        XCTAssertEqual(try parse(""), "")
        XCTAssertThrowsError(try parse("foo "))
        XCTAssertThrowsError(try parse(" "))
    }

    // MARK: Edge cases with optionals

    func testReplaceOptional() throws {
        // Replacement is applied even if nothing is matched
        try compile(.replace(.optional("foo"), "bar"))
        XCTAssertEqual(try parse("foo"), "bar")
        XCTAssertEqual(try parse(""), "bar")
        XCTAssertThrowsError(try parse("bar"))
    }

    func testDiscardOptional() throws {
        try compile(.discard(.optional("foo")))
        XCTAssertEqual(try parse("foo"), "")
        XCTAssertEqual(try parse(""), "")
        XCTAssertThrowsError(try parse("bar"))
    }

    func testOneOrMoreOptionals() throws {
        try compile(.oneOrMore(.optional("foo")))
        XCTAssertEqual(try parse(""), "")
        XCTAssertEqual(try parse("foo"), "foo")
        XCTAssertEqual(try parse("foofoo"), "foofoo")
    }

    func testFlattenOneOrMoreOptionals() throws {
        try compile(.flatten(.oneOrMore(.optional("foo"))))
        XCTAssertEqual(try parse(""), "")
        XCTAssertEqual(try parse("foo"), "foo")
        XCTAssertEqual(try parse("foofoo"), "foofoo")
    }

    func testDiscardOneOrMoreOptionals() throws {
        try compile(.discard(.oneOrMore(.optional("foo"))))
        XCTAssertEqual(try parse(""), "")
        XCTAssertEqual(try parse("foo"), "")
        XCTAssertEqual(try parse("foofoo"), "")
    }

    func testOneOrMoreReplaceOptionals() throws {
        // This behavior sort of makes sense, but is very weird
        try compile(.oneOrMore(.replace(.optional("foo"), "bar")))
        XCTAssertEqual(try parse(""), "bar")
        XCTAssertEqual(try parse("foo"), "barbar")
        XCTAssertEqual(try parse("foofoo"), "barbarbar")
    }

    func testFlattenOneOrMoreReplaceOptionals() throws {
        try compile(.flatten(.oneOrMore(.replace(.optional("foo"), "bar"))))
        XCTAssertEqual(try parse(""), "bar")
        XCTAssertEqual(try parse("foo"), "barbar")
        XCTAssertEqual(try parse("foofoo"), "barbarbar")
    }

    func testOneOrMoreZeroOrMores() throws {
        try compile(.oneOrMore(.zeroOrMore("foo")))
        XCTAssertEqual(try parse(""), "")
        XCTAssertEqual(try parse("foo"), "foo")
        XCTAssertEqual(try parse("foofoo"), "foofoo")
    }

    func testAnyOptionals() throws {
        try compile(.optional("foo") | .optional("bar"))
        XCTAssertEqual(try parse(""), "")
        XCTAssertEqual(try parse("foo"), "foo")
        XCTAssertEqual(try parse("bar"), "bar")
    }

    func testFlattenAnyOptionals() throws {
        try compile(.flatten(.optional("foo") | .optional("bar")))
        XCTAssertEqual(try parse(""), "")
        XCTAssertEqual(try parse("foo"), "foo")
        XCTAssertEqual(try parse("bar"), "bar")
    }

    func testDiscardAnyOptionals() throws {
        try compile(.discard(.optional("foo") | .optional("bar")))
        XCTAssertEqual(try parse(""), "")
        XCTAssertEqual(try parse("foo"), "")
        XCTAssertEqual(try parse("bar"), "")
    }

    func testSequenceOfOptionals() throws {
        try compile([.optional("foo"), .optional("bar")])
        XCTAssertEqual(try parse(""), "")
        XCTAssertEqual(try parse("foo"), "foo")
        XCTAssertEqual(try parse("bar"), "bar")
        XCTAssertEqual(try parse("foobar"), "foobar")
    }

    func testFlattenSequenceOfOptionals() throws {
        try compile(.flatten([.optional("foo"), .optional("bar")]))
        XCTAssertEqual(try parse(""), "")
        XCTAssertEqual(try parse("foo"), "foo")
        XCTAssertEqual(try parse("bar"), "bar")
        XCTAssertEqual(try parse("foobar"), "foobar")
    }

    func testDiscardSequenceOfOptionals() throws {
        try compile(.discard([.optional("foo"), .optional("bar")]))
        XCTAssertEqual(try parse(""), "")
        XCTAssertEqual(try parse("foo"), "")
        XCTAssertEqual(try parse("bar"), "")
        XCTAssertEqual(try parse("foobar"), "")
    }

    func testEmptyAny() throws {
        try compile(.any([]))
        XCTAssertEqual(try parse(""), "")
    }

    func testFlattenEmptyAny() throws {
        try compile(.flatten(.any([])))
        XCTAssertEqual(try parse(""), "")
    }

    func testDiscardEmptyAny() throws {
        try compile(.discard(.any([])))
        XCTAssertEqual(try parse(""), "")
    }

    func testEmptySequence() throws {
        try compile(.sequence([]))
        XCTAssertEqual(try parse(""), "")
    }

    func testFlattenEmptySequence() throws {
        try compile(.flatten(.sequence([])))
        XCTAssertEqual(try parse(""), "")
    }

    func testDiscardEmptySequence() throws {
        try compile(.discard(.sequence([])))
        XCTAssertEqual(try parse(""), "")
    }

    func testOneOrMoreAnyOptionals() throws {
        try compile(.oneOrMore(.optional("foo") | .optional("bar")))
        XCTAssertEqual(try parse(""), "")
        XCTAssertEqual(try parse("foo"), "foo")
        XCTAssertEqual(try parse("bar"), "bar")
        XCTAssertEqual(try parse("barfoo"), "barfoo")
    }
}

// MARK: helpers

private let outputDirectory = URL(fileURLWithPath: #file).deletingLastPathComponent()
private let compiledSwiftFile = outputDirectory.appendingPathComponent("compiled.swift")
private let consumerLibraryFile = outputDirectory.deletingLastPathComponent()
    .appendingPathComponent("Sources").appendingPathComponent("Consumer.swift")

private func parse(_ input: String) throws -> String {
    let data = try shell("/usr/bin/swift", compiledSwiftFile.path, input)
    return String(data: data, encoding: .utf8) ?? ""
}

private func compile(_ consumer: Consumer<String>) throws {
    let compiled = """
    \(try! String(contentsOf: consumerLibraryFile))

    \(Consumer<String>.label("test", consumer).compile("parseTest"))

    let match = try! parseTest(CommandLine.arguments[1])
    print(match.transform { _, values in (values as! [String]).joined() }!, terminator: "")
    """
    try compiled.write(to: compiledSwiftFile, atomically: true, encoding: .utf8)
}

private func shell(_ cmd: String, _ args: String...) throws -> Data {
    let task = Process()
    task.launchPath = cmd
    task.arguments = args

    let outpipe = Pipe()
    task.standardOutput = outpipe
    let errpipe = Pipe()
    task.standardError = errpipe

    task.launch()

    let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
    let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
    if var string = String(data: errdata, encoding: .utf8) {
        string = string.trimmingCharacters(in: .newlines)
        if !string.isEmpty {
            throw NSError(domain: cmd, code: 0, userInfo: [NSLocalizedDescriptionKey: string])
        }
    }

    task.waitUntilExit()
    let status = task.terminationStatus
    if status != 0 {
        throw NSError(domain: cmd, code: Int(status), userInfo: nil)
    }

    return outdata
}
