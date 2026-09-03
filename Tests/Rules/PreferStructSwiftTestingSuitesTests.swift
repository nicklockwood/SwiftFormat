//
//  PreferStructSwiftTestingSuitesTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 9/3/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class PreferStructSwiftTestingSuitesTests: XCTestCase {
    func testConvertsFinalClassSuiteToStruct() {
        let input = """
        import Testing

        final class MyFeatureTests {
            @Test func testFeature() {}
        }
        """
        let output = """
        import Testing

        struct MyFeatureTests {
            @Test func testFeature() {}
        }
        """
        testFormatting(
            for: input,
            output,
            rule: .preferStructSwiftTestingSuites,
            exclude: [.swiftTestingTestCaseNames, .testSuiteAccessControl, .redundantSwiftTestingSuite]
        )
    }

    func testConvertsClassSuiteWithImmutableStoredPropertyToStruct() {
        let input = """
        import Testing

        class MyFeatureTests {
            let value = 1
            @Test func testFeature() {}
        }
        """
        let output = """
        import Testing

        struct MyFeatureTests {
            let value = 1
            @Test func testFeature() {}
        }
        """
        testFormatting(
            for: input,
            output,
            rule: .preferStructSwiftTestingSuites,
            exclude: [.swiftTestingTestCaseNames, .testSuiteAccessControl, .redundantSwiftTestingSuite]
        )
    }

    func testDoesNotConvertClassSuiteWithMutableStoredInstanceVar() {
        let input = """
        import Testing

        class MyFeatureTests {
            var value = 1
            @Test func testFeature() {}
        }
        """
        testFormatting(
            for: input,
            rule: .preferStructSwiftTestingSuites,
            exclude: [.swiftTestingTestCaseNames, .testSuiteAccessControl, .redundantSwiftTestingSuite]
        )
    }

    func testConvertsSuiteEnumWithoutCasesToStruct() {
        let input = """
        import Testing

        @Suite enum MyFeatureTests {
            @Test static func testFeature() {}
        }
        """
        let output = """
        import Testing

        @Suite struct MyFeatureTests {
            @Test static func testFeature() {}
        }
        """
        testFormatting(
            for: input,
            output,
            rule: .preferStructSwiftTestingSuites,
            exclude: [.swiftTestingTestCaseNames, .testSuiteAccessControl, .redundantSwiftTestingSuite]
        )
    }

    func testDoesNotConvertSuiteEnumWithCases() {
        let input = """
        import Testing

        @Suite enum MyFeatureTests {
            case parameterized(Int)

            @Test static func testFeature() {}
        }
        """
        testFormatting(
            for: input,
            rule: .preferStructSwiftTestingSuites,
            exclude: [.swiftTestingTestCaseNames, .testSuiteAccessControl, .redundantSwiftTestingSuite]
        )
    }

    func testConvertsXCTestClassToSwiftTestingStructWhenCombinedWithPreferSwiftTesting() {
        let input = """
        import XCTest

        final class MyFeatureTests: XCTestCase {
            func testFeature() {
                XCTAssertTrue(true)
            }
        }
        """
        let output = """
        import Foundation
        import Testing

        struct MyFeatureTests {
            @Test func feature() {
                #expect(true)
            }
        }
        """
        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, [output], rules: [.preferSwiftTesting, .preferStructSwiftTestingSuites, .sortImports], options: options)
    }
}
