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

    func testConvertsTestNameWithTrailingNumberToRawIdentifier() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test
            func testValueIsGreaterThan100() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func `value is greater than 100`() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(swiftVersion: "6.2"))
    }

    func testConvertsTestNameWithMiddleNumberToRawIdentifier() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test
            func testPhase2IsComplete() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func `phase 2 is complete`() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(swiftVersion: "6.2"))
    }

    func testConvertsTestNameWithLeadingNumberToRawIdentifier() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test
            func test100IsGreaterThan99() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func `100 is greater than 99`() {
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

    // MARK: - standard-identifiers for @Test

    func testStandardIdentifiersConvertsRawIdentifierToLowerCamelCase() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test
            func `my feature has no bugs`() {
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
                       options: FormatOptions(testCaseNameFormat: .standardIdentifiers, swiftVersion: "6.2"))
    }

    func testStandardIdentifiersRemovesDisplayNameFromTest() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test("My feature works")
            func myFeatureWorks() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func myFeatureWorks() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(testCaseNameFormat: .standardIdentifiers, swiftVersion: "6.2"))
    }

    func testStandardIdentifiersRemovesDisplayNameAndConvertsRawIdentifier() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test("My feature works")
            func `my feature works`() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func myFeatureWorks() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(testCaseNameFormat: .standardIdentifiers, swiftVersion: "6.2"))
    }

    func testStandardIdentifiersRemovesDisplayNameWithArguments() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test("Features work as expected", arguments: [
                .foo,
                .bar,
            ])
            func `features work as expected`(_ feature: Feature) {
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
            func featuresWorkAsExpected(_ feature: Feature) {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(testCaseNameFormat: .standardIdentifiers, swiftVersion: "6.2"),
                       exclude: [.unusedArguments])
    }

    func testStandardIdentifiersPreservesStandardIdentifierFunction() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test
            func myFeatureWorks() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(testCaseNameFormat: .standardIdentifiers, swiftVersion: "6.2"))
    }

    func testStandardIdentifiersStillRemovesTestPrefix() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test
            func testMyFeatureWorks() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func myFeatureWorks() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(testCaseNameFormat: .standardIdentifiers, swiftVersion: "6.2"))
    }

    // MARK: - @Suite with standard-identifiers (default)

    func testSuiteStandardIdentifiersRemovesDisplayName() {
        let input = """
        import Testing

        @Suite("My Feature Tests")
        struct MyFeatureTests {
            @Test func myTest() {}
        }
        """

        let output = """
        import Testing

        @Suite
        struct MyFeatureTests {
            @Test func myTest() {}
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(testCaseNameFormat: .preserve, swiftVersion: "6.2"),
                       exclude: [.redundantSwiftTestingSuite])
    }

    func testSuiteStandardIdentifiersConvertsRawIdentifier() {
        let input = """
        import Testing

        @Suite
        struct `My test suite` {
            @Test func myTest() {}
        }
        """

        let output = """
        import Testing

        @Suite
        struct MyTestSuite {
            @Test func myTest() {}
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(testCaseNameFormat: .preserve, swiftVersion: "6.2"),
                       exclude: [.redundantSwiftTestingSuite])
    }

    func testSuiteStandardIdentifiersRemovesDisplayNameAndConvertsRawIdentifier() {
        let input = """
        import Testing

        @Suite("My test suite")
        struct `My test suite` {
            @Test func myTest() {}
        }
        """

        let output = """
        import Testing

        @Suite
        struct MyTestSuite {
            @Test func myTest() {}
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(testCaseNameFormat: .preserve, swiftVersion: "6.2"),
                       exclude: [.redundantSwiftTestingSuite])
    }

    func testSuiteStandardIdentifiersPreservesStandardName() {
        let input = """
        import Testing

        @Suite
        struct MyFeatureTests {
            @Test func myTest() {}
        }
        """

        testFormatting(for: input, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(testCaseNameFormat: .preserve, swiftVersion: "6.2"),
                       exclude: [.redundantSwiftTestingSuite])
    }

    func testSuiteStandardIdentifiersRemovesDisplayNameWithOtherArgs() {
        let input = """
        import Testing

        @Suite("My Feature Tests", .serialized)
        struct MyFeatureTests {
            @Test func myTest() {}
        }
        """

        let output = """
        import Testing

        @Suite(.serialized)
        struct MyFeatureTests {
            @Test func myTest() {}
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(testCaseNameFormat: .preserve, swiftVersion: "6.2"))
    }

    // MARK: - @Suite with raw-identifiers

    func testSuiteRawIdentifiersConvertsCamelCase() {
        let input = """
        import Testing

        @Suite
        struct MyFeatureTests {
            @Test func myTest() {}
        }
        """

        let output = """
        import Testing

        @Suite
        struct `my feature tests` {
            @Test func myTest() {}
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(testCaseNameFormat: .preserve,
                                              suiteNameFormat: .rawIdentifiers,
                                              swiftVersion: "6.2"),
                       exclude: [.redundantSwiftTestingSuite])
    }

    func testSuiteRawIdentifiersUsesDisplayName() {
        let input = """
        import Testing

        @Suite("My Feature Tests")
        struct MyFeatureTests {
            @Test func myTest() {}
        }
        """

        let output = """
        import Testing

        @Suite
        struct `My Feature Tests` {
            @Test func myTest() {}
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(testCaseNameFormat: .preserve,
                                              suiteNameFormat: .rawIdentifiers,
                                              swiftVersion: "6.2"),
                       exclude: [.redundantSwiftTestingSuite])
    }

    func testSuiteRawIdentifiersFallsBackToPreserveBelowSwift6_2() {
        let input = """
        import Testing

        @Suite
        struct MyFeatureTests {
            @Test func myTest() {}
        }
        """

        testFormatting(for: input, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(testCaseNameFormat: .preserve,
                                              suiteNameFormat: .rawIdentifiers,
                                              swiftVersion: "6.1"),
                       exclude: [.redundantSwiftTestingSuite])
    }

    // MARK: - @Suite with preserve

    func testSuitePreserveKeepsEverything() {
        let input = """
        import Testing

        @Suite("My Feature Tests")
        struct MyFeatureTests {
            @Test func myTest() {}
        }
        """

        testFormatting(for: input, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(testCaseNameFormat: .preserve,
                                              suiteNameFormat: .preserve,
                                              swiftVersion: "6.2"))
    }

    func testSuitePreserveKeepsDisplayNameWithBothRules() {
        let input = """
        import Testing

        @Suite("My Feature Tests")
        struct MyFeatureTests {
            @Test func myTest() {}
        }
        """

        testFormatting(
            for: input,
            rules: [.swiftTestingTestCaseNames, .redundantSwiftTestingSuite],
            options: FormatOptions(testCaseNameFormat: .preserve,
                                   suiteNameFormat: .preserve,
                                   swiftVersion: "6.2")
        )
    }

    // MARK: - @Suite on class/actor/enum

    func testSuiteWorksWithClass() {
        let input = """
        import Testing

        @Suite("My Feature Tests")
        class MyFeatureTests {
            @Test func myTest() {}
        }
        """

        let output = """
        import Testing

        @Suite
        class MyFeatureTests {
            @Test func myTest() {}
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(testCaseNameFormat: .preserve, swiftVersion: "6.2"),
                       exclude: [.redundantSwiftTestingSuite])
    }

    func testSuiteWorksWithActor() {
        let input = """
        import Testing

        @Suite("My Feature Tests")
        actor MyFeatureTests {
            @Test func myTest() {}
        }
        """

        let output = """
        import Testing

        @Suite
        actor MyFeatureTests {
            @Test func myTest() {}
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(testCaseNameFormat: .preserve, swiftVersion: "6.2"),
                       exclude: [.redundantSwiftTestingSuite])
    }

    func testSuiteWorksWithEnum() {
        let input = """
        import Testing

        @Suite("My Feature Tests")
        enum MyFeatureTests {
            @Test static func myTest() {}
        }
        """

        let output = """
        import Testing

        @Suite
        enum MyFeatureTests {
            @Test static func myTest() {}
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(testCaseNameFormat: .preserve, swiftVersion: "6.2"),
                       exclude: [.redundantSwiftTestingSuite])
    }

    func testSuiteNameNotUpdatedWhenReferencedAsStaticMember() {
        let input = """
        import Testing

        @Suite("My Feature Tests")
        struct `My Feature Tests` {
            @Test func myTest() {}
        }

        func runTests() {
            `My Feature Tests`.runAll()
        }
        """

        let output = """
        import Testing

        @Suite
        struct `My Feature Tests` {
            @Test func myTest() {}
        }

        func runTests() {
            `My Feature Tests`.runAll()
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(testCaseNameFormat: .preserve, swiftVersion: "6.2"),
                       exclude: [.redundantSwiftTestingSuite])
    }

    // MARK: - Suite without @Suite macro

    func testSuiteWithoutMacroRawIdentifiersConvertsCamelCase() {
        let input = """
        import Testing

        struct my_feature_tests {
            @Test func myTest() {}
        }
        """

        let output = """
        import Testing

        struct `my feature tests` {
            @Test func myTest() {}
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(testCaseNameFormat: .preserve,
                                              suiteNameFormat: .rawIdentifiers,
                                              swiftVersion: "6.2"))
    }

    func testSuiteWithoutMacroStandardIdentifiersConvertsRawIdentifier() {
        let input = """
        import Testing

        struct `my feature tests` {
            @Test func myTest() {}
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            @Test func myTest() {}
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(testCaseNameFormat: .preserve,
                                              suiteNameFormat: .standardIdentifiers,
                                              swiftVersion: "6.2"))
    }

    func testSuiteWithoutMacroPreservesName() {
        let input = """
        import Testing

        struct my_feature_tests {
            @Test func myTest() {}
        }
        """

        testFormatting(for: input, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(testCaseNameFormat: .preserve,
                                              suiteNameFormat: .preserve,
                                              swiftVersion: "6.2"))
    }

    func testSuiteWithoutMacroNotRenamedWhenNoTestFunctions() {
        let input = """
        import Testing

        struct my_feature_tests {
            func myHelper() {}
        }
        """

        testFormatting(for: input, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(testCaseNameFormat: .preserve,
                                              suiteNameFormat: .rawIdentifiers,
                                              swiftVersion: "6.2"))
    }

    func testNestedSuiteWithoutMacroNotRenamedFromOuterType() {
        let input = """
        import Testing

        struct outer_tests {
            struct inner_tests {
                @Test func myTest() {}
            }
        }
        """

        let output = """
        import Testing

        struct outer_tests {
            struct `inner tests` {
                @Test func myTest() {}
            }
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(testCaseNameFormat: .preserve,
                                              suiteNameFormat: .rawIdentifiers,
                                              swiftVersion: "6.2"),
                       exclude: [.enumNamespaces])
    }

    func testConvertsAcronymAtStartToRawIdentifier() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test
            func testUUIDIsValid() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func `UUID is valid`() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(swiftVersion: "6.2"))
    }

    func testConvertsTrailingAcronymToRawIdentifier() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test
            func testAlphabetStartsWithABC() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func `alphabet starts with ABC`() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(swiftVersion: "6.2"))
    }

    func testConvertsMiddleAcronymToRawIdentifier() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test
            func testMyURLIsValid() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func `my URL is valid`() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .swiftTestingTestCaseNames,
                       options: FormatOptions(swiftVersion: "6.2"))
    }
}
