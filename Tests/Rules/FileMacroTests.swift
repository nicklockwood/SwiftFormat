//
//  FileMacroTests.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 9/14/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class FileMacroTests: XCTestCase {
    func testPreservesFileMacroInSwift5Mode() {
        let input = """
        func foo(file: StaticString = #fileID) {
            print(file)
        }

        func bar(file: StaticString = #file) {
            print(file)
        }
        """

        let options = FormatOptions(languageMode: "5")
        testFormatting(for: input, rule: .fileMacro, options: options)
    }

    func testUpdatesFileIDInSwift6Mode() {
        let input = """
        func foo(file: StaticString = #fileID) {
            print(file)
        }
        """

        let output = """
        func foo(file: StaticString = #file) {
            print(file)
        }
        """

        let options = FormatOptions(preferFileMacro: true, languageMode: "6")
        testFormatting(for: input, output, rule: .fileMacro, options: options)
    }

    func testPreferFileID() {
        let input = """
        func foo(file: StaticString = #file) {
            print(file)
        }
        """

        let output = """
        func foo(file: StaticString = #fileID) {
            print(file)
        }
        """

        let options = FormatOptions(preferFileMacro: false, languageMode: "6")
        testFormatting(for: input, output, rule: .fileMacro, options: options)
    }
}
