// Created by Cal Stephens on 10/15/25.
// Copyright © 2025 Nick Lockwood. All rights reserved.

import XCTest
@testable import SwiftFormat

final class ValidateTestCasesTests: XCTestCase {
    // MARK: XCTest

    func testXCTestMethodsHaveTestPrefix() {
        let input = """
        import XCTest

        final class MyTests: XCTestCase {
            func example() {
                XCTAssertTrue(true)
            }
        }
        """

        let output = """
        import XCTest

        final class MyTests: XCTestCase {
            func testExample() {
                XCTAssertTrue(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .validateTestCases, exclude: [.unusedArguments, .testSuiteAccessControl])
    }

    // This test moved to TestSuiteAccessControlTests

    func testXCTestDoesNotAddPrefixToReferencedMethods() {
        let input = """
        import XCTest

        final class MyTests: XCTestCase {
            func testMain() {
                helperMethod()
            }

            func helperMethod() {
                // This is called, so don't add prefix
            }
        }
        """

        // No change expected - referenced methods don't get test prefix
        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments, .testSuiteAccessControl])
    }

    func testXCTestAddsPrefixToUnreferencedMethods() {
        let input = """
        import XCTest

        final class MyTests: XCTestCase {
            func example() {
                XCTAssertTrue(true)
            }

            func anotherExample() {
                XCTAssertTrue(true)
            }
        }
        """

        let output = """
        import XCTest

        final class MyTests: XCTestCase {
            func testExample() {
                XCTAssertTrue(true)
            }

            func testAnotherExample() {
                XCTAssertTrue(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .validateTestCases, exclude: [.unusedArguments, .testSuiteAccessControl])
    }

    // testXCTestPropertiesArePrivate moved to TestSuiteAccessControlTests
    // testXCTestClassIsInternal moved to TestSuiteAccessControlTests
    // testXCTestInitializerIsInternal moved to TestSuiteAccessControlTests

    func testXCTestPreservesOverrideMethods() {
        let input = """
        import XCTest

        final class MyTests: XCTestCase {
            override func setUp() {
                super.setUp()
            }

            override func tearDown() {
                super.tearDown()
            }

            func testExample() {
                XCTAssertTrue(true)
            }
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
    }

    func testXCTestPreservesObjcMethods() {
        let input = """
        import XCTest

        final class MyTests: XCTestCase {
            @objc func helperMethod() {
                // helper code
            }

            func testExample() {
                XCTAssertTrue(true)
            }
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
    }

    func testXCTestPreservesOpenTestClass() {
        let input = """
        import XCTest

        open class MyTests: XCTestCase {
            func testExample() {
                XCTAssertTrue(true)
            }
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
    }

    func testXCTestPreservesStaticProperties() {
        let input = """
        import XCTest

        final class MyTests: XCTestCase {
            static var sharedState: String = ""

            func testExample() {
                XCTAssertEqual(Self.sharedState, "")
            }
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
    }

    func testXCTestPreservesStaticFunctions() {
        let input = """
        import XCTest

        final class MyTests: XCTestCase {
            static func createFixture() -> String {
                return "fixture"
            }

            public static func publicHelper() -> String {
                return "helper"
            }

            func testExample() {
                XCTAssertEqual(Self.createFixture(), "fixture")
            }
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments, .redundantPublic])
    }

    // MARK: Swift Testing

    func testSwiftTestingMethodsHaveTestAttribute() {
        let input = """
        import Testing

        struct MyFeatureTests {
            func featureWorks() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            @Test func featureWorks() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .validateTestCases, exclude: [.unusedArguments, .testSuiteAccessControl])
    }

    // testSwiftTestingMethodsAreInternal moved to TestSuiteAccessControlTests
    // testSwiftTestingHelperMethodsArePrivate moved to TestSuiteAccessControlTests
    // testSwiftTestingPropertiesArePrivate moved to TestSuiteAccessControlTests
    // testSwiftTestingStructIsInternal moved to TestSuiteAccessControlTests

    // testSwiftTestingInitializerIsInternal moved to TestSuiteAccessControlTests

    func testSwiftTestingPreservesOpenTestClass() {
        let input = """
        import Testing

        open class MyFeatureTests {
            @Test func featureWorks() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
    }

    func testSwiftTestingPreservesStaticProperties() {
        let input = """
        import Testing

        struct MyFeatureTests {
            static var sharedState: String = ""

            @Test func featureWorks() {
                #expect(Self.sharedState == "")
            }
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
    }

    func testSwiftTestingPreservesStaticFunctions() {
        let input = """
        import Testing

        struct MyFeatureTests {
            static func createFixture() -> String {
                return "fixture"
            }

            public static func publicHelper() -> String {
                return "helper"
            }

            @Test func featureWorks() {
                #expect(Self.createFixture() == "fixture")
            }
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments, .redundantPublic])
    }

    func testSwiftTestingPreservesObjcMethods() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @objc func helperMethod() {
                // helper code
            }

            @Test func featureWorks() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
    }

    // MARK: Edge Cases

    func testOnlyAppliesToClassesWithTestSuffixes() {
        // Classes without valid test suffixes are ignored
        let input = """
        import XCTest

        final class SomeTestHelper {
            func example() {
                print("hello")
            }

            var someProperty: String = ""
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
    }

    // testAddsXCTestCaseConformanceToClassWithTestSuffix removed - XCTestCase conformance feature removed
    // testAddsXCTestCaseConformanceToClassWithTestCaseSuffix removed - XCTestCase conformance feature removed
    // testAddsXCTestCaseConformanceToClassWithSuiteSuffix removed - XCTestCase conformance feature removed

    func testDoesNotAddXCTestCaseWithExistingConformances() {
        // When there are existing conformances, we skip adding XCTestCase
        // since we can't reliably distinguish between a base class and protocols
        let input = """
        import XCTest

        final class MyTests: SomeProtocol {
            func example() {
                XCTAssertTrue(true)
            }
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
    }

    func testDoesNotValidateTestsWithOtherConformances() {
        // When a test class conforms to other protocols, we don't apply any changes
        // because methods could be protocol requirements
        let input = """
        import XCTest

        final class MyTests: XCTestCase, SomeProtocol {
            public func example() {
                XCTAssertTrue(true)
            }

            public func protocolMethod() {
                // This could be a protocol requirement
            }

            public var someProperty: String = ""
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments, .redundantPublic])
    }

    func testDoesNotAddXCTestCaseWhenBaseClassExists() {
        let input = """
        import XCTest

        final class MyTests: BaseTestClass {
            func example() {
                XCTAssertTrue(true)
            }
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
    }

    func testDoesNotAddXCTestCaseToStructs() {
        let input = """
        import XCTest

        struct MyTests {
            func example() {
                print("hello")
            }
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
    }

    func testXCTestCaseSubclass() {
        let input = """
        import XCTest

        final class SomeTests: XCTestCase {
            func example() {
                XCTAssertTrue(true)
            }
        }
        """

        let output = """
        import XCTest

        final class SomeTests: XCTestCase {
            func testExample() {
                XCTAssertTrue(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .validateTestCases, exclude: [.unusedArguments, .testSuiteAccessControl])
    }

    func testSwiftTestingOnlyAppliesToTypesWithTestSuffixes() {
        // Types without valid test suffixes are ignored
        let input = """
        import Testing

        struct FeatureTestHelper {
            func example() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
    }

    func testSwiftTestingStructWithTestsSuffix() {
        let input = """
        import Testing

        struct FeatureTests {
            func example() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct FeatureTests {
            @Test func example() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .validateTestCases, exclude: [.unusedArguments, .testSuiteAccessControl])
    }

    func testSwiftTestingStructWithTestCaseSuffix() {
        let input = """
        import Testing

        struct FeatureTestCase {
            func example() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct FeatureTestCase {
            @Test func example() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .validateTestCases, exclude: [.unusedArguments, .testSuiteAccessControl])
    }

    func testSwiftTestingStructWithSuiteSuffix() {
        let input = """
        import Testing

        struct FeatureSuite {
            func example() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct FeatureSuite {
            @Test func example() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .validateTestCases, exclude: [.unusedArguments, .testSuiteAccessControl])
    }

    func testDoesNotApplyToNonTestClasses() {
        let input = """
        import Foundation

        final class MyClass {
            func example() {
                print("hello")
            }

            var someProperty: String = ""
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
    }

    func testDoesNotApplyToHelperTypesWithTestInName() {
        // Types with "Test" in name but no test-like functions should be ignored
        let input = """
        import XCTest

        final class HelperForTests {
            func createFixture() -> String {
                return "fixture"
            }

            func setup(with data: Data) {
                // setup code
            }
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
    }

    func testDoesNotApplyToSwiftTestingHelperTypesWithTestInName() {
        // Types with "Test" in name but no test-like functions should be ignored
        let input = """
        import Testing

        struct TestHelpers {
            func createFixture() -> String {
                return "fixture"
            }

            func setup(with data: Data) {
                // setup code
            }
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
    }

    func testAppliesToTypesWithTestInNameAndTestLikeFunction() {
        // Type with "Test" suffix and at least one test-like function should be processed
        let input = """
        import XCTest

        final class HelperTests {
            func example() {
                XCTAssertTrue(true)
            }

            func createFixture() -> String {
                return "fixture"
            }
        }
        """

        let output = """
        import XCTest

        final class HelperTests {
            func testExample() {
                XCTAssertTrue(true)
            }

            func createFixture() -> String {
                return "fixture"
            }
        }
        """

        testFormatting(for: input, output, rule: .validateTestCases, exclude: [.unusedArguments, .testSuiteAccessControl])
    }

    func testDoesNotApplyWhenBothTestingFrameworksAreImported() {
        // When both Testing and XCTest are imported, it's ambiguous which framework to use
        let input = """
        import Testing
        import XCTest

        final class MyTests: XCTestCase {
            public func example() {
                XCTAssertTrue(true)
            }

            var someProperty: String = ""
        }
        """

        // Should not make any changes when both frameworks are imported
        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments, .redundantPublic])
    }

    func testDoesNotApplyToBaseTestClasses() {
        // Base test classes (with "Base" in name) should not have access control modified
        let input = """
        import XCTest

        open class MyFeatureTestsBase: XCTestCase {
            public func helperMethod() {
                // This should remain public for subclasses
            }

            public var sharedProperty: String = ""

            public func example() {
                XCTAssertTrue(true)
            }
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments, .redundantPublic])
    }

    func testDoesNotApplyToSwiftTestingBaseClasses() {
        // Base test classes (with "Base" in name) should not have access control modified
        let input = """
        import Testing

        open class FeatureTestBase {
            public func helperMethod() {
                // This should remain public for subclasses
            }

            public var sharedProperty: String = ""

            public func example() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments, .redundantPublic])
    }

    func testDoesNotApplyToTestClassWithBaseInDocComment() {
        // Test classes with "base" mentioned in doc comment should not be modified
        let input = """
        import XCTest

        /// Base class for feature tests
        open class MyFeatureTests: XCTestCase {
            public func helperMethod() {
                // This should remain public for subclasses
            }

            public var sharedProperty: String = ""

            public func example() {
                XCTAssertTrue(true)
            }
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments, .redundantPublic])
    }

    func testDoesNotApplyToTestClassWithSubclassInDocComment() {
        // Test classes with "subclass" mentioned in doc comment should not be modified
        let input = """
        import XCTest

        /// Meant to be subclassed by other test suites.
        /// Provides common test functionality.
        open class CommonTests: XCTestCase {
            public func helperMethod() {
                // This should remain public for subclasses
            }

            public var sharedProperty: String = ""

            public func example() {
                XCTAssertTrue(true)
            }
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments, .redundantPublic])
    }

    func testDoesNotApplyToSwiftTestingClassWithBaseInDocComment() {
        // Swift Testing classes with "base" in doc comment should not be modified
        let input = """
        import Testing

        /// Base test suite for features
        struct FeatureTests {
            public func helperMethod() {
                // This should remain public for subclasses
            }

            public var sharedProperty: String = ""

            public func example() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments, .redundantPublic])
    }

    func testXCTestPreservesDisabledTestMethods() {
        // Methods with disabled test prefixes should not have test prefix added
        let input = """
        import XCTest

        final class MyTests: XCTestCase {
            func disable_example() {
                XCTAssertTrue(true)
            }

            func disabled_anotherTest() {
                XCTAssertTrue(true)
            }

            func skip_thisTest() {
                XCTAssertTrue(true)
            }

            func skipped_obsolete() {
                XCTAssertTrue(true)
            }

            func x_broken() {
                XCTAssertTrue(true)
            }

            func testEnabled() {
                XCTAssertTrue(true)
            }
        }
        """

        // No changes expected - disabled test methods don't get test prefix
        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
    }

    func testSwiftTestingPreservesDisabledTestMethods() {
        // Methods with disabled test prefixes should not have @Test attribute added
        let input = """
        import Testing

        struct MyFeatureTests {
            func disable_example() {
                #expect(true)
            }

            func disabled_anotherTest() {
                #expect(true)
            }

            func skip_thisTest() {
                #expect(true)
            }

            func skipped_obsolete() {
                #expect(true)
            }

            func x_broken() {
                #expect(true)
            }

            func enabled() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            func disable_example() {
                #expect(true)
            }

            func disabled_anotherTest() {
                #expect(true)
            }

            func skip_thisTest() {
                #expect(true)
            }

            func skipped_obsolete() {
                #expect(true)
            }

            func x_broken() {
                #expect(true)
            }

            @Test func enabled() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .validateTestCases, exclude: [.unusedArguments, .testSuiteAccessControl])
    }

    func testSwiftTestingPreservesParameterizedTests() {
        // Parameterized tests with @Test(arguments:) should be left as-is
        let input = """
        import Testing

        struct FoodTests {
            @Test(arguments: [Food.burger, .iceCream, .burrito, .noodleBowl, .kebab])
            func foodAvailable(_ food: Food) async throws {
                let foodTruck = FoodTruck(selling: food)
                #expect(await foodTruck.cook(food))
            }

            @Test(arguments: [1, 2, 3, 4, 5])
            func numberIsValid(_ number: Int) {
                #expect(number > 0)
            }
        }
        """

        // Should not modify parameterized tests - they already have @Test
        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments, .redundantThrows])
    }

    func testXCTestPreservesCapitalizedDisabledTestMethods() {
        // Capitalized disabled test prefixes should also be preserved
        let input = """
        import XCTest

        final class MyTests: XCTestCase {
            func DISABLE_example() {
                XCTAssertTrue(true)
            }

            func X_broken() {
                XCTAssertTrue(true)
            }

            func Skip_ThisTest() {
                XCTAssertTrue(true)
            }

            func testEnabled() {
                XCTAssertTrue(true)
            }
        }
        """

        // No changes expected - disabled test methods don't get test prefix
        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
    }

    func testSwiftTestingPreservesCapitalizedDisabledTestMethods() {
        // Capitalized disabled test prefixes should also be preserved
        let input = """
        import Testing

        struct MyFeatureTests {
            func DISABLE_example() {
                #expect(true)
            }

            func X_broken() {
                #expect(true)
            }

            func Skip_ThisTest() {
                #expect(true)
            }

            func enabled() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            func DISABLE_example() {
                #expect(true)
            }

            func X_broken() {
                #expect(true)
            }

            func Skip_ThisTest() {
                #expect(true)
            }

            @Test func enabled() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .validateTestCases, exclude: [.unusedArguments, .testSuiteAccessControl])
    }

    // testXCTestHelperMethodWithTestPrefixAndParameters moved to TestSuiteAccessControlTests

    func testSwiftTestingAddsTestAttributeWhenNameMatchesIdentifier() {
        let input = """
        import Testing

        struct ComponentTests {
            func button() {
                let button = Button()
                #expect(button.isEnabled)
            }

            func slider() {
                let value = slider(initialValue: 50)
                #expect(value == 50)
            }
        }
        """

        let output = """
        import Testing

        struct ComponentTests {
            @Test func button() {
                let button = Button()
                #expect(button.isEnabled)
            }

            @Test func slider() {
                let value = slider(initialValue: 50)
                #expect(value == 50)
            }
        }
        """

        testFormatting(for: input, output, rule: .validateTestCases, exclude: [.unusedArguments, .testSuiteAccessControl])
    }

    func testXCTestPreservesPrivateFunctions() {
        // Private functions should not be treated as tests
        let input = """
        import XCTest

        final class MyTests: XCTestCase {
            func testExample() {
                XCTAssertTrue(true)
            }

            private func helperMethod() {
                // This is a helper, should stay private
            }
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
    }

    func testSwiftTestingPreservesPrivateFunctions() {
        // Private functions should not be treated as tests
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test func featureWorks() {
                #expect(true)
            }

            private func helperMethod() {
                // This is a helper, should stay private
            }
        }
        """

        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
    }

    func testXCTestPreservesUnderscorePrefixedFunctions() {
        // Functions starting with underscore are treated as disabled
        let input = """
        import XCTest

        final class MyTests: XCTestCase {
            func _temporarilyDisabled() {
                XCTAssertTrue(true)
            }

            func testEnabled() {
                XCTAssertTrue(true)
            }
        }
        """

        // No changes expected - underscore prefix means disabled
        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments])
    }

    func testSwiftTestingPreservesUnderscorePrefixedFunctions() {
        // Functions starting with underscore are treated as disabled
        let input = """
        import Testing

        struct MyFeatureTests {
            func _temporarilyDisabled() {
                #expect(true)
            }

            func enabled() {
                #expect(true)
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            func _temporarilyDisabled() {
                #expect(true)
            }

            @Test func enabled() {
                #expect(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .validateTestCases, exclude: [.unusedArguments, .testSuiteAccessControl])
    }

    func testXCTestIgnoresTypesWithParameterizedInit() {
        // Types with parameterized initializers are not test suites
        let input = """
        import XCTest

        final class MyTests: XCTestCase {
            let dependency: Dependency

            init(dependency: Dependency) {
                self.dependency = dependency
            }

            func example() {
                XCTAssertTrue(true)
            }
        }
        """

        // No changes expected - has parameterized init
        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments, .testSuiteAccessControl])
    }

    func testSwiftTestingIgnoresTypesWithParameterizedInit() {
        // Types with parameterized initializers are not test suites
        let input = """
        import Testing

        struct MyFeatureTests {
            let dependency: Dependency

            init(dependency: Dependency) {
                self.dependency = dependency
            }

            func example() {
                #expect(true)
            }
        }
        """

        // No changes expected - has parameterized init
        testFormatting(for: input, rule: .validateTestCases, exclude: [.unusedArguments, .testSuiteAccessControl, .redundantMemberwiseInit])
    }
}
