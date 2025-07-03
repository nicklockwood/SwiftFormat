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
        let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
        testFormatting(for: input, output, rule: .urlMacro, options: options, exclude: [.propertyTypes])
    }

    func testImportNotAddedInFragment() {
        let input = """
        let url = URL(string: "https://example.com")!
        """
        let output = """
        let url = #URL("https://example.com")
        """
        let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"), fragment: true)
        testFormatting(for: input, output, rule: .urlMacro, options: options, exclude: [.propertyTypes])
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
        let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
        testFormatting(for: input, output, rule: .urlMacro, options: options, exclude: [.propertyTypes])
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
        let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
        testFormatting(for: input, output, rule: .urlMacro, options: options, exclude: [.propertyTypes])
    }

    func testURLStringForceUnwrapWithComplexString() {
        let input = """
        let complexURL = URL(string: "https://example.com/path?param=value&other=123")!
        """
        let output = """
        import URLFoundation

        let complexURL = #URL("https://example.com/path?param=value&other=123")
        """
        let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
        testFormatting(for: input, output, rule: .urlMacro, options: options, exclude: [.propertyTypes])
    }

    func testURLStringForceUnwrapWithSpacing() {
        let input = """
        let url = URL(string: "https://example.com" )!
        """
        let output = """
        import URLFoundation

        let url = #URL("https://example.com" )
        """
        let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
        testFormatting(for: input, output, rule: .urlMacro, options: options, exclude: [.propertyTypes, .spaceInsideParens])
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
        let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
        testFormatting(for: input, output, rule: .urlMacro, options: options, exclude: [.propertyTypes])
    }

    func testURLStringOptionalNotConverted() {
        let input = """
        let url = URL(string: "https://example.com")
        """
        let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
        testFormatting(for: input, rule: .urlMacro, options: options, exclude: [.propertyTypes])
    }

    func testURLStringOptionalWithNilCoalescingNotConverted() {
        let input = """
        let url = URL(string: "https://example.com") ?? URL(fileURLWithPath: "/")
        """
        let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
        testFormatting(for: input, rule: .urlMacro, options: options, exclude: [.propertyTypes])
    }

    func testURLFileURLWithPathNotConverted() {
        let input = """
        let url = URL(fileURLWithPath: "/path/to/file")!
        """
        let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
        testFormatting(for: input, rule: .urlMacro, options: options, exclude: [.propertyTypes])
    }

    func testURLWithOtherInitializerNotConverted() {
        let input = """
        let url = URL(string: "https://example.com", relativeTo: baseURL)!
        """
        let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
        testFormatting(for: input, rule: .urlMacro, options: options, exclude: [.propertyTypes])
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
        let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
        testFormatting(for: input, output, rule: .urlMacro, options: options, exclude: [.propertyTypes])
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
        let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
        testFormatting(for: input, output, rule: .urlMacro, options: options, exclude: [.propertyTypes])
    }

    func testURLWithEscapedCharacters() {
        let input = """
        let url = URL(string: "https://example.com/path with spaces")!
        """
        let output = """
        import URLFoundation

        let url = #URL("https://example.com/path with spaces")
        """
        let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
        testFormatting(for: input, output, rule: .urlMacro, options: options, exclude: [.propertyTypes])
    }

    func testNoTransformationWhenMacroNotConfigured() {
        let input = """
        let url = URL(string: "https://example.com")!
        """
        testFormatting(for: input, rule: .urlMacro, exclude: [.propertyTypes])
    }

    func testCustomMacroConfiguration() {
        let input = """
        let url = URL(string: "https://example.com")!
        """
        let output = """
        import CustomURLLib

        let url = #CustomURL("https://example.com")
        """
        let options = FormatOptions(urlMacro: .macro("#CustomURL", module: "CustomURLLib"))
        testFormatting(for: input, output, rule: .urlMacro, options: options, exclude: [.propertyTypes])
    }

    func testStringInterpolationNotConverted() {
        let input = """
        let domain = "example.com"
        let url = URL(string: "https://\\(domain)/path")!
        """
        let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
        testFormatting(for: input, rule: .urlMacro, options: options, exclude: [.propertyTypes])
    }

    func testStringConcatenationNotConverted() {
        let input = """
        let baseURL = "https://api.example.com"
        let url = URL(string: baseURL + "/endpoint")!
        """
        let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
        testFormatting(for: input, rule: .urlMacro, options: options, exclude: [.propertyTypes])
    }

    func testComplexStringExpressionNotConverted() {
        let input = """
        let clientID = "12345"
        let url = URL(string: "com.googleusercontent.apps.\\(clientID):/oauth2redirect/google")!
        """
        let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
        testFormatting(for: input, rule: .urlMacro, options: options, exclude: [.propertyTypes])
    }
}
