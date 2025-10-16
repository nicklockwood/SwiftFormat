// Created by Cal Stephens on 2/19/25.
// Copyright © 2025 Airbnb Inc. All rights reserved.

import XCTest
@testable import SwiftFormat

final class SwiftTestingTestCaseNamesTests: XCTestCase {
    func testRemovesTestPrefixFromMethod() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test func testMyFeatureHasNoBugs() {
                let myFeature = MyFeature()
                myFeature.runAction()
                #expect(!myFeature.hasBugs)
            }

            @Test("Features work as expected", arguments: [
                .foo,
                .bar,
                .baaz,
            ])
            func testFeatureWorksAsExpected(_ feature: Feature) {
                let myFeature = MyFeature()
                myFeature.run(feature)
                #expect(myFeature.worksAsExpected)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            @Test func myFeatureHasNoBugs() {
                let myFeature = MyFeature()
                myFeature.runAction()
                #expect(!myFeature.hasBugs)
            }

            @Test("Features work as expected", arguments: [
                .foo,
                .bar,
                .baaz,
            ])
            func featureWorksAsExpected(_ feature: Feature) {
                let myFeature = MyFeature()
                myFeature.run(feature)
                #expect(myFeature.worksAsExpected)
            }
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames)
    }

    func testRemovesTestPrefixFromMethodWithRawIdentifier() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test func `test my feature has no bugs`() {
                let myFeature = MyFeature()
                myFeature.runAction()
                #expect(!myFeature.hasBugs)
            }

            @Test("Features work as expected", arguments: [
                .foo,
                .bar,
                .baaz,
            ])
            func `Test Feature Works As Expected`(_ feature: Feature) {
                let myFeature = MyFeature()
                myFeature.run(feature)
                #expect(myFeature.worksAsExpected)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            @Test func `my feature has no bugs`() {
                let myFeature = MyFeature()
                myFeature.runAction()
                #expect(!myFeature.hasBugs)
            }

            @Test("Features work as expected", arguments: [
                .foo,
                .bar,
                .baaz,
            ])
            func `Feature Works As Expected`(_ feature: Feature) {
                let myFeature = MyFeature()
                myFeature.run(feature)
                #expect(myFeature.worksAsExpected)
            }
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames)
    }

    func testDoesntUpdateNameToIdentifierRequiringBackTicks() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test func test123() {
                #expect((1 + 2) == 3)
            }

            @Test func testInit() {
                #expect(Foo() != nil)
            }

            @Test func testSubscript() {
                #expect(foo[bar] != nil)
            }

            @Test func testNil() {
                #expect(foo.optionalFoo == nil)
            }

            @Test func test() {
                #expect(test.succeeds)
            }
        }
        """

        testFormatting(for: input, rule: .swiftTestingTestCaseNames)
    }

    func testDoesntUpTestNameToExistingFunctionName() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test func testOnePlusTwo() {
                #expect(onePlusTwo() == 3)
            }

            func onePlusTwo() -> Int {
                1 + 2
            }
        }
        """

        testFormatting(for: input, rule: .swiftTestingTestCaseNames, exclude: [.testSuiteAccessControl])
    }

    func testPreservesXCTestMethodNames() {
        let input = """
        import XCTest

        final class MyFeatureTests: XCTestCase {
            func testOnePlusTwo() {
                XCTAssertEqual(onePlusTwo(), 3)
            }
        }
        """

        testFormatting(for: input, rule: .swiftTestingTestCaseNames)
    }
}
