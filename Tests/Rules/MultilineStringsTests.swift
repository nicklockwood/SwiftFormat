//
//  MultilineStringsTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/26/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class MultilineStringsTests: XCTestCase {
    func testConvertsStringWithEscapedNewline() {
        let input = """
        let message = "Hello\\nWorld"
        """
        let output = """
        let message = \"\"\"
        Hello
        World
        \"\"\"
        """
        testFormatting(for: input, output, rule: .multilineStrings, exclude: [.indent])
    }

    func testConvertsStringWithMultipleEscapedNewlines() {
        let input = """
        let text = "Line 1\\nLine 2\\nLine 3"
        """
        let output = """
        let text = \"\"\"
        Line 1
        Line 2
        Line 3
        \"\"\"
        """
        testFormatting(for: input, output, rule: .multilineStrings, exclude: [.indent])
    }

    func testPreservesIndentation() {
        let input = """
        func test() {
            let message = "Hello\\nWorld"
        }
        """
        let output = """
        func test() {
            let message = \"\"\"
            Hello
            World
            \"\"\"
        }
        """
        testFormatting(for: input, output, rule: .multilineStrings, exclude: [.indent])
    }

    func testDoesNotAffectStringsWithoutNewlines() {
        let input = """
        let message = "Hello World"
        """
        testFormatting(for: input, rule: .multilineStrings)
    }

    func testDoesNotAffectExistingMultilineStrings() {
        let input = """
        let message = \"\"\"
        Hello
        World
        \"\"\"
        """
        testFormatting(for: input, rule: .multilineStrings)
    }

    func testConvertsStringInFunctionCall() {
        let input = """
        print("First line\\nSecond line")
        """
        let output = """
        print(\"\"\"
        First line
        Second line
        \"\"\")
        """
        testFormatting(for: input, output, rule: .multilineStrings, exclude: [.indent])
    }

    func testConvertsStringWithMixedContent() {
        let input = """
        let error = "Error occurred at line \\(lineNumber)\\nPlease check your input"
        """
        let output = """
        let error = \"\"\"
        Error occurred at line \\(lineNumber)
        Please check your input
        \"\"\"
        """
        testFormatting(for: input, output, rule: .multilineStrings, exclude: [.indent])
    }

    func testConvertsNestedString() {
        let input = """
        struct Config {
            let template = "Header\\nBody\\nFooter"
        }
        """
        let output = """
        struct Config {
            let template = \"\"\"
            Header
            Body
            Footer
            \"\"\"
        }
        """
        testFormatting(for: input, output, rule: .multilineStrings, exclude: [.indent])
    }

    func testDoesNotConvertWhitespaceOnlyStrings() {
        let input = #"""
        let newline = "\\n"
        let newlines = "\n\n"
        let whitespace = "\r\n\t"
        let mixed = "Content\nMore content"
        """#
        let output = #"""
        let newline = "\\n"
        let newlines = "\n\n"
        let whitespace = "\r\n\t"
        let mixed = """
        Content
        More content
        """
        """#
        testFormatting(for: input, output, rule: .multilineStrings, exclude: [.indent])
    }

    func testConvertsIndentedStringInStruct() {
        let input = """
        struct APIClient {
            private let baseURL = "https://api.example.com"

            func fetchData() {
                let request = "GET /users\\nHost: api.example.com\\nAuthorization: Bearer token"
                send(request)
            }
        }
        """
        let output = """
        struct APIClient {
            private let baseURL = "https://api.example.com"

            func fetchData() {
                let request = \"\"\"
                GET /users
                Host: api.example.com
                Authorization: Bearer token
                \"\"\"
                send(request)
            }
        }
        """
        testFormatting(for: input, output, rule: .multilineStrings, exclude: [.indent, .trailingSpace])
    }
}
