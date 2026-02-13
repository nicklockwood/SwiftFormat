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

    func testConvertsCamelCaseToRawIdentifier() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test
            func testMyTestCase() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func `my test case`() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(swiftVersion: "6.2"))
    }

    func testConvertsTestPrefixCamelCaseToRawIdentifier() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test
            func testMyFeatureHasNoBugs() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func `my feature has no bugs`() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(swiftVersion: "6.2"))
    }

    func testUsesDisplayNameForRawIdentifier() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test("My test case")
            func myTestCase() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func `My test case`() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(swiftVersion: "6.2"))
    }

    func testUsesDisplayNameForRawIdentifierWithExistingRawIdentifier() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test("My test case")
            func `my test case`() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func `My test case`() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(swiftVersion: "6.2"))
    }

    func testUsesDisplayNameForRawIdentifierWithTestPrefix() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test("My test case")
            func testMyTestCase() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func `My test case`() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(swiftVersion: "6.2"))
    }

    func testConvertsUnderscoresToSpacesInRawIdentifier() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test
            func test_myFeature_hasBehavior() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func `my feature has behavior`() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(swiftVersion: "6.2"))
    }

    func testUsesDisplayNameForRawIdentifierWithArguments() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test("Features work as expected", arguments: [
                .foo,
                .bar,
            ])
            func testFeatureWorksAsExpected(_ feature: Feature) {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            @Test(arguments: [
                .foo,
                .bar,
            ])
            func `Features work as expected`(_ feature: Feature) {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(swiftVersion: "6.2"),
                       exclude: [.unusedArguments])
    }

    func testRawIdentifiersFallsBackToPreserveBelowSwift6_2() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test
            func testMyFeatureHasNoBugs() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func myFeatureHasNoBugs() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(swiftVersion: "6.1"))
    }

    func testPreservesAlreadyCorrectRawIdentifier() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test
            func `my feature has no bugs`() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(swiftVersion: "6.2"))
    }

    func testRawIdentifiersPreservesNonTestMethod() {
        let input = """
        import Testing

        struct MyFeatureTests {
            func helperMethod() {
                // not a test
            }
        }
        """

        testFormatting(for: input, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(swiftVersion: "6.2"),
                       exclude: [.testSuiteAccessControl, .validateTestCases])
    }

    func testRawIdentifiersRemovesDisplayNameOnSameLine() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test("My test case")
            func myTestCase() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func `My test case`() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(swiftVersion: "6.2"))
    }

    func testRemovesBackticksFromTestName() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test("`MyFeature` works as expected")
            func myTestCase() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func `MyFeature works as expected`() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(swiftVersion: "6.2"))
    }

    func testPreserveOptionKeepsCamelCase() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test func myFeatureWorks() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(testCaseNameFormat: .preserve, swiftVersion: "6.2"))
    }

    func testDoesntCreateRawIdentifierTestFunctionWithSameNameAsExistingSymbol() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test("Test MyFeature")
            func myTestCase() {
                #expect(MyFeature().works)
            }

            @Test("MyFeature")
            func myOtherTestCase() {
                #expect(MyFeature().works)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func `Test MyFeature`() {
                #expect(MyFeature().works)
            }

            @Test
            func `my other test case`() {
                #expect(MyFeature().works)
            }
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(swiftVersion: "6.2"))
    }
}
