//
//  NoFileIDTests.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 9/14/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class NoFileIDTests: XCTestCase {
    func testPreservesFileIDInSwift5Mode() {
        let input = """
        func foo(file: StaticString = #fileID) {
            print(file)
        }
        """

        let options = FormatOptions(languageMode: "5")
        testFormatting(for: input, rule: .noFileID, options: options)
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

        let options = FormatOptions(languageMode: "6")
        testFormatting(for: input, output, rule: .noFileID, options: options)
    }
}
