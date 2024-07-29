//
//  HeaderFileNameTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class HeaderFileNameTests: XCTestCase {
    func testHeaderFileNameReplaced() {
        let input = """
        // MyFile.swift

        let foo = bar
        """
        let output = """
        // YourFile.swift

        let foo = bar
        """
        let options = FormatOptions(fileInfo: FileInfo(filePath: "~/YourFile.swift"))
        testFormatting(for: input, output, rule: .headerFileName, options: options)
    }
}
