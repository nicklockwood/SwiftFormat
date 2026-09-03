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
        testFormatting(for: input, output, rule: .preferStructSwiftTestingSuites)
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
        testFormatting(for: input, output, rule: .preferStructSwiftTestingSuites)
    }

    func testDoesNotConvertClassSuiteWithMutableStoredInstanceVar() {
        let input = """
        import Testing

        class MyFeatureTests {
            var value = 1
            @Test func testFeature() {}
        }
        """
        testFormatting(for: input, rule: .preferStructSwiftTestingSuites)
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
        testFormatting(for: input, output, rule: .preferStructSwiftTestingSuites)
    }

    func testDoesNotConvertSuiteEnumWithCases() {
        let input = """
        import Testing

        @Suite enum MyFeatureTests {
            case parameterized(Int)

            @Test static func testFeature() {}
        }
        """
        testFormatting(for: input, rule: .preferStructSwiftTestingSuites)
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
