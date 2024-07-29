//
//  AnyObjectProtocolTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 1/23/19.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class AnyObjectProtocolTests: XCTestCase {
    func testClassReplacedByAnyObject() {
        let input = "protocol Foo: class {}"
        let output = "protocol Foo: AnyObject {}"
        let options = FormatOptions(swiftVersion: "4.1")
        testFormatting(for: input, output, rule: .anyObjectProtocol, options: options)
    }

    func testClassReplacedByAnyObjectWithOtherProtocols() {
        let input = "protocol Foo: class, Codable {}"
        let output = "protocol Foo: AnyObject, Codable {}"
        let options = FormatOptions(swiftVersion: "4.1")
        testFormatting(for: input, output, rule: .anyObjectProtocol, options: options)
    }

    func testClassReplacedByAnyObjectImmediatelyAfterImport() {
        let input = "import Foundation\nprotocol Foo: class {}"
        let output = "import Foundation\nprotocol Foo: AnyObject {}"
        let options = FormatOptions(swiftVersion: "4.1")
        testFormatting(for: input, output, rule: .anyObjectProtocol, options: options,
                       exclude: [.blankLineAfterImports])
    }

    func testClassDeclarationNotReplacedByAnyObject() {
        let input = "class Foo: Codable {}"
        let options = FormatOptions(swiftVersion: "4.1")
        testFormatting(for: input, rule: .anyObjectProtocol, options: options)
    }

    func testClassImportNotReplacedByAnyObject() {
        let input = "import class Foo.Bar"
        let options = FormatOptions(swiftVersion: "4.1")
        testFormatting(for: input, rule: .anyObjectProtocol, options: options)
    }

    func testClassNotReplacedByAnyObjectIfSwiftVersionLessThan4_1() {
        let input = "protocol Foo: class {}"
        let options = FormatOptions(swiftVersion: "4.0")
        testFormatting(for: input, rule: .anyObjectProtocol, options: options)
    }
}
