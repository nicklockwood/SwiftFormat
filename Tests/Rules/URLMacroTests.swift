//
//  URLMacroTests.swift
//  SwiftFormatTests
//
//  Created by Manuel Lopez on 6/17/25.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class URLMacroTests: XCTestCase {
    func testBasicURLStringForceUnwrapConverted() {
        let input = """
        let url = URL(string: "https://example.com")!
        """
        let output = """
        import URLFoundation

        let url = #URL("https://example.com")
        """
        testFormatting(for: input, output, rule: .uRLMacro, options: FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation")), exclude: [.blankLineAfterImports, .redundantInit, .propertyTypes, .trailingSpace, .indent, .spaceInsideParens])
    }

    func testURLStringForceUnwrapInReturnStatement() {
        let input = """
        func getURL() -> URL {
            return URL(string: "https://api.example.com/users")!
        }
        """
        let output = """
        import URLFoundation

        func getURL() -> URL {
            return #URL("https://api.example.com/users")
        }
        """
        testFormatting(for: input, output, rule: .uRLMacro, options: FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation")), exclude: [.blankLineAfterImports, .redundantInit, .propertyTypes, .trailingSpace, .indent, .spaceInsideParens])
    }

    func testURLStringForceUnwrapInAssignment() {
        let input = """
        var baseURL: URL
        baseURL = URL(string: "https://api.service.com")!
        """
        let output = """
        import URLFoundation

        var baseURL: URL
        baseURL = #URL("https://api.service.com")
        """
        testFormatting(for: input, output, rule: .uRLMacro, options: FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation")), exclude: [.blankLineAfterImports, .redundantInit, .propertyTypes, .trailingSpace, .indent, .spaceInsideParens])
    }

    func testURLStringForceUnwrapWithComplexString() {
        let input = """
        let complexURL = URL(string: "https://example.com/path?param=value&other=123")!
        """
        let output = """
        import URLFoundation

        let complexURL = #URL("https://example.com/path?param=value&other=123")
        """
        testFormatting(for: input, output, rule: .uRLMacro, options: FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation")), exclude: [.blankLineAfterImports, .redundantInit, .propertyTypes, .trailingSpace, .indent, .spaceInsideParens])
    }

    func testURLStringForceUnwrapWithSpacing() {
        let input = """
        let url = URL(string: "https://example.com" )!
        """
        let output = """
        import URLFoundation

        let url = #URL("https://example.com" )
        """
        testFormatting(for: input, output, rule: .uRLMacro, options: FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation")), exclude: [.blankLineAfterImports, .redundantInit, .propertyTypes, .trailingSpace, .indent, .spaceInsideParens])
    }

    func testMultipleURLStringForceUnwraps() {
        let input = """
        let url1 = URL(string: "https://example.com")!
        let url2 = URL(string: "https://other.com")!
        """
        let output = """
        import URLFoundation

        let url1 = #URL("https://example.com")
        let url2 = #URL("https://other.com")
        """
        testFormatting(for: input, output, rule: .uRLMacro, options: FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation")), exclude: [.blankLineAfterImports, .redundantInit, .propertyTypes, .trailingSpace, .indent, .spaceInsideParens])
    }

    func testURLStringOptionalNotConverted() {
        let input = """
        let url = URL(string: "https://example.com")
        """
        testFormatting(for: input, rule: .uRLMacro, options: FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation")), exclude: [.blankLineAfterImports, .redundantInit, .propertyTypes, .trailingSpace, .indent, .spaceInsideParens])
    }

    func testURLStringOptionalWithNilCoalescingNotConverted() {
        let input = """
        let url = URL(string: "https://example.com") ?? URL(fileURLWithPath: "/")
        """
        testFormatting(for: input, rule: .uRLMacro, options: FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation")), exclude: [.blankLineAfterImports, .redundantInit, .propertyTypes, .trailingSpace, .indent, .spaceInsideParens])
    }

    func testURLFileURLWithPathNotConverted() {
        let input = """
        let url = URL(fileURLWithPath: "/path/to/file")!
        """
        testFormatting(for: input, rule: .uRLMacro, options: FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation")), exclude: [.blankLineAfterImports, .redundantInit, .propertyTypes, .trailingSpace, .indent, .spaceInsideParens])
    }

    func testURLWithOtherInitializerNotConverted() {
        let input = """
        let url = URL(string: "https://example.com", relativeTo: baseURL)!
        """
        testFormatting(for: input, rule: .uRLMacro, options: FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation")), exclude: [.blankLineAfterImports, .redundantInit, .propertyTypes, .trailingSpace, .indent, .spaceInsideParens])
    }

    func testExistingURLFoundationImportNotDuplicated() {
        let input = """
        import URLFoundation
        let url = URL(string: "https://example.com")!
        """
        let output = """
        import URLFoundation
        let url = #URL("https://example.com")
        """
        testFormatting(for: input, output, rule: .uRLMacro, options: FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation")), exclude: [.blankLineAfterImports, .redundantInit, .propertyTypes, .trailingSpace, .indent, .spaceInsideParens])
    }

    func testURLInDifferentContexts() {
        let input = """
        class NetworkService {
            private let baseURL = URL(string: "https://api.example.com")!

            func makeRequest() {
                let url = URL(string: "https://api.example.com/endpoint")!
                // Use url...
            }
        }
        """
        let output = """
        import URLFoundation

        class NetworkService {
            private let baseURL = #URL("https://api.example.com")

            func makeRequest() {
                let url = #URL("https://api.example.com/endpoint")
                // Use url...
            }
        }
        """
        testFormatting(for: input, output, rule: .uRLMacro, options: FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation")), exclude: [.blankLineAfterImports, .redundantInit, .propertyTypes, .trailingSpace, .indent, .spaceInsideParens])
    }

    func testURLWithEscapedCharacters() {
        let input = """
        let url = URL(string: "https://example.com/path with spaces")!
        """
        let output = """
        import URLFoundation

        let url = #URL("https://example.com/path with spaces")
        """
        testFormatting(for: input, output, rule: .uRLMacro, options: FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation")), exclude: [.blankLineAfterImports, .redundantInit, .propertyTypes, .trailingSpace, .indent, .spaceInsideParens])
    }

    func testNoTransformationWhenMacroNotConfigured() {
        let input = """
        let url = URL(string: "https://example.com")!
        """
        testFormatting(for: input, rule: .uRLMacro, options: FormatOptions(urlMacro: .none), exclude: [.blankLineAfterImports, .redundantInit, .propertyTypes, .trailingSpace, .indent, .spaceInsideParens])
    }

    func testCustomMacroConfiguration() {
        let input = """
        let url = URL(string: "https://example.com")!
        """
        let output = """
        import CustomURLLib

        let url = @CustomURL("https://example.com")
        """
        testFormatting(for: input, output, rule: .uRLMacro, options: FormatOptions(urlMacro: .macro("@CustomURL", module: "CustomURLLib")), exclude: [.blankLineAfterImports, .redundantInit, .propertyTypes, .trailingSpace, .indent, .spaceInsideParens])
    }
}
