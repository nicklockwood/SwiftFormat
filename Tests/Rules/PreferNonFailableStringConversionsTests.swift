//
//  PreferNonFailableStringConversionsTests.swift
//  SwiftFormatTests
//
//  Created by Yang Bai on 17/10/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class PreferNonFailableStringConversionsTests: XCTestCase {
    func testForceUnwrappedDataConversion() {
        let input = """
        func foo() {
            let data = string.data(using: .utf8)!
        }
        """
        let output = """
        func foo() {
            let data = Data(string.utf8)
        }
        """
        testFormatting(for: input, output, rule: .preferNonFailableStringConversions)
    }

    func testForceUnwrappedStringConversion() {
        let input = """
        func foo() {
            let string = String(data: data, encoding: .utf8)!
        }
        """
        let output = """
        func foo() {
            let string = String(decoding: data, as: UTF8.self)
        }
        """
        testFormatting(for: input, output, rule: .preferNonFailableStringConversions)
    }

    func testFullyQualifiedEncodingConverted() {
        let input = """
        func foo() {
            let data = string.data(using: String.Encoding.utf8)!
            let string = String(data: data, encoding: String.Encoding.utf8)!
        }
        """
        let output = """
        func foo() {
            let data = Data(string.utf8)
            let string = String(decoding: data, as: UTF8.self)
        }
        """
        testFormatting(for: input, output, rule: .preferNonFailableStringConversions)
    }

    func testMemberChainReceiverConverted() {
        let input = """
        func foo() {
            let encoded = user.name.data(using: .utf8)!.base64EncodedString()
        }
        """
        let output = """
        func foo() {
            let encoded = Data(user.name.utf8).base64EncodedString()
        }
        """
        testFormatting(for: input, output, rule: .preferNonFailableStringConversions)
    }

    func testCallReceiverConverted() {
        let input = """
        func foo() {
            let data = String(describing: value).data(using: .utf8)!
        }
        """
        let output = """
        func foo() {
            let data = Data(String(describing: value).utf8)
        }
        """
        testFormatting(for: input, output, rule: .preferNonFailableStringConversions)
    }

    func testStringLiteralReceiverConverted() {
        let input = """
        func foo() {
            let data = "foo".data(using: .utf8)!
        }
        """
        let output = """
        func foo() {
            let data = Data("foo".utf8)
        }
        """
        testFormatting(for: input, output, rule: .preferNonFailableStringConversions)
    }

    func testMultilineStringLiteralReceiverConverted() {
        let input = #"""
        func foo() {
            let data = """
            {"foo": "bar"}
            """.data(using: .utf8)!
        }
        """#
        let output = #"""
        func foo() {
            let data = Data("""
            {"foo": "bar"}
            """.utf8)
        }
        """#
        testFormatting(for: input, output, rule: .preferNonFailableStringConversions)
    }

    func testStringConversionInsideExpressionConverted() {
        let input = """
        print(String(data: response.body, encoding: .utf8)!.count)
        """
        let output = """
        print(String(decoding: response.body, as: UTF8.self).count)
        """
        testFormatting(for: input, output, rule: .preferNonFailableStringConversions)
    }

    func testTryXCTUnwrapDataConversion() {
        let input = """
        func testFoo() throws {
            let data = try XCTUnwrap(string.data(using: .utf8))
        }
        """
        let output = """
        func testFoo() throws {
            let data = Data(string.utf8)
        }
        """
        testFormatting(for: input, output, rule: .preferNonFailableStringConversions)
    }

    func testTryRequireStringConversion() {
        let input = """
        func foo() throws {
            let string = try #require(String(data: data, encoding: .utf8))
        }
        """
        let output = """
        func foo() throws {
            let string = String(decoding: data, as: UTF8.self)
        }
        """
        testFormatting(for: input, output, rule: .preferNonFailableStringConversions)
    }

    func testTryXCTUnwrapWithMessageNotConverted() {
        let input = """
        func testFoo() throws {
            let data = try XCTUnwrap(string.data(using: .utf8), "Invalid string")
        }
        """
        testFormatting(for: input, rule: .preferNonFailableStringConversions)
    }

    func testTryXCTUnwrapWithCallInOperandNotConverted() {
        // The call might throw, so the `try` can't be removed
        let input = """
        func testFoo() throws {
            let string = try XCTUnwrap(String(data: loadData(), encoding: .utf8))
        }
        """
        testFormatting(for: input, rule: .preferNonFailableStringConversions)
    }

    func testTryXCTUnwrapFollowedByMemberCallNotConverted() {
        // The `try` also covers the member call, which might throw
        let input = """
        func testFoo() throws {
            let json = try XCTUnwrap(string.data(using: .utf8)).decoded()
        }
        """
        testFormatting(for: input, rule: .preferNonFailableStringConversions)
    }

    func testOptionalTryXCTUnwrapNotConverted() {
        let input = """
        func testFoo() {
            let data = try? XCTUnwrap(string.data(using: .utf8))
        }
        """
        testFormatting(for: input, rule: .preferNonFailableStringConversions)
    }

    func testGuardStringConversion() {
        let input = """
        func decode(_ data: Data) {
            guard let string = String(data: data, encoding: .utf8) else { return }

            print(string)
        }
        """
        let output = """
        func decode(_ data: Data) {
            let string = String(decoding: data, as: UTF8.self)

            print(string)
        }
        """
        testFormatting(for: input, output, rule: .preferNonFailableStringConversions)
    }

    func testGuardDataConversionWithMultilineElse() {
        let input = """
        func encode(_ string: String) throws -> Data {
            guard var data = string.data(using: .utf8) else {
                throw EncodingError.invalidString
            }

            data.append(0)
            return data
        }
        """
        let output = """
        func encode(_ string: String) throws -> Data {
            var data = Data(string.utf8)

            data.append(0)
            return data
        }
        """
        testFormatting(for: input, output, rule: .preferNonFailableStringConversions)
    }

    func testGuardWithMultipleConditionsNotConverted() {
        let input = """
        func decode(_ data: Data?) {
            guard let data, let string = String(data: data, encoding: .utf8) else { return }

            print(string)
        }
        """
        testFormatting(for: input, rule: .preferNonFailableStringConversions)
    }

    func testGuardWithCommentInElseNotConverted() {
        let input = """
        func decode(_ data: Data) {
            guard let string = String(data: data, encoding: .utf8) else {
                // Not UTF-8
                return
            }

            print(string)
        }
        """
        testFormatting(for: input, rule: .preferNonFailableStringConversions)
    }

    func testIfLetNotConverted() {
        let input = """
        if let string = String(data: data, encoding: .utf8) {
            print(string)
        }
        """
        testFormatting(for: input, rule: .preferNonFailableStringConversions)
    }

    func testOptionalConversionsNotConverted() {
        let input = """
        func foo() {
            let data = string.data(using: .utf8)
            let string = String(data: data, encoding: .utf8) ?? ""
            let count = String(data: data, encoding: .utf8)?.count ?? 0
        }
        """
        testFormatting(for: input, rule: .preferNonFailableStringConversions)
    }

    func testOtherEncodingsNotConverted() {
        let input = """
        func foo() {
            let data = string.data(using: .ascii)!
            let string = String(data: data, encoding: .utf16)!
        }
        """
        testFormatting(for: input, rule: .preferNonFailableStringConversions)
    }

    func testLossyConversionNotConverted() {
        let input = """
        func foo() {
            let data = string.data(using: .utf8, allowLossyConversion: true)!
        }
        """
        testFormatting(for: input, rule: .preferNonFailableStringConversions)
    }

    func testOptionalChainedReceiverNotConverted() {
        let input = """
        func foo() {
            let data = user?.name.data(using: .utf8)!
        }
        """
        testFormatting(for: input, rule: .preferNonFailableStringConversions)
    }

    func testImplicitSelfReceiverNotConverted() {
        let input = """
        extension String {
            func bytes() -> Data {
                data(using: .utf8)!
            }
        }
        """
        testFormatting(for: input, rule: .preferNonFailableStringConversions)
    }

    func testCommentInConversionNotConverted() {
        let input = """
        func foo() {
            let string = String(data: data /* response body */, encoding: .utf8)!
        }
        """
        testFormatting(for: input, rule: .preferNonFailableStringConversions)
    }
}
