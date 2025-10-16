// Created by Cal Stephens on 10/16/25.
// Copyright © 2025 Nick Lockwood. All rights reserved.

import XCTest
@testable import SwiftFormat

final class TestSuiteAccessControlTests: XCTestCase {
    // MARK: XCTest

    func testXCTestMethodsAreInternal() {
        let input = """
        import XCTest

        final class MyTests: XCTestCase {
            public func testExample() {
                XCTAssertTrue(true)
            }

            private func testHelper() {
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

            private func testHelper() {
                XCTAssertTrue(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
    }

    func testXCTestHelperMethodsArePrivate() {
        let input = """
        import XCTest

        final class MyTests: XCTestCase {
            func testExample() {
                helperMethod(arg: 0)
            }

            func helperMethod(arg: Int) {
                // helper code
            }

            public func publicHelper(arg: Int) {
                // helper code
            }
        }
        """

        let output = """
        import XCTest

        final class MyTests: XCTestCase {
            func testExample() {
                helperMethod(arg: 0)
            }

            private func helperMethod(arg: Int) {
                // helper code
            }

            private func publicHelper(arg: Int) {
                // helper code
            }
        }
        """

        testFormatting(for: input, output, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
    }

    func testXCTestPropertiesArePrivate() {
        let input = """
        import XCTest

        final class MyTests: XCTestCase {
            var someProperty: String = ""
            public var anotherProperty: Int = 0

            func testExample() {
                XCTAssertEqual(someProperty, "")
            }
        }
        """

        let output = """
        import XCTest

        final class MyTests: XCTestCase {
            private var someProperty: String = ""
            private var anotherProperty: Int = 0

            func testExample() {
                XCTAssertEqual(someProperty, "")
            }
        }
        """

        testFormatting(for: input, output, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
    }

    func testXCTestClassIsInternal() {
        let input = """
        import XCTest

        public final class MyTests: XCTestCase {
            func testExample() {
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

        testFormatting(for: input, output, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
    }

    func testXCTestInitializerIsInternal() {
        let input = """
        import XCTest

        final class MyTests: XCTestCase {
            private let dependency: Dependency

            public init(dependency: Dependency) {
                self.dependency = dependency
            }

            func testExample() {
                XCTAssertTrue(true)
            }
        }
        """

        let output = """
        import XCTest

        final class MyTests: XCTestCase {
            private let dependency: Dependency

            init(dependency: Dependency) {
                self.dependency = dependency
            }

            func testExample() {
                XCTAssertTrue(true)
            }
        }
        """

        testFormatting(for: input, output, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
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

        testFormatting(for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
    }

    func testXCTestPreservesStaticFunctions() {
        let input = """
        import XCTest

        final class MyTests: XCTestCase {
            func testExample() {
                XCTAssertTrue(true)
            }

            static func helperMethod() {
                // helper code
            }
        }
        """

        testFormatting(for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
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

        testFormatting(for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
    }

    func testXCTestPreservesOverrideMethods() {
        let input = """
        import XCTest

        class BaseTestCase: XCTestCase {
            func setUp() {
                // setup code
            }
        }

        class MyTests: BaseTestCase {
            override func setUp() {
                super.setUp()
            }

            func testExample() {
                XCTAssertTrue(true)
            }
        }
        """

        testFormatting(for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
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

        testFormatting(for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
    }

    func testXCTestHelperMethodWithTestPrefixAndParameters() {
        let input = """
        import XCTest

        final class MyTests: XCTestCase {
            func testExample() {
                testHelper(value: 5)
            }

            func testHelper(value: Int) {
                XCTAssertEqual(value, 5)
            }

            func testFormatter(string: String) -> String {
                return string.uppercased()
            }
        }
        """

        let output = """
        import XCTest

        final class MyTests: XCTestCase {
            func testExample() {
                testHelper(value: 5)
            }

            private func testHelper(value: Int) {
                XCTAssertEqual(value, 5)
            }

            private func testFormatter(string: String) -> String {
                return string.uppercased()
            }
        }
        """

        testFormatting(for: input, output, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
    }

    // MARK: Swift Testing

    func testSwiftTestingPropertiesArePrivate() {
        let input = """
        import Testing

        struct MyFeatureTests {
            var someProperty: String = ""
            public var anotherProperty: Int = 0

            @Test func featureWorks() {
                #expect(someProperty == "")
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            private var someProperty: String = ""
            private var anotherProperty: Int = 0

            @Test func featureWorks() {
                #expect(someProperty == "")
            }
        }
        """

        testFormatting(for: input, output, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
    }

    func testSwiftTestingHelperMethodsArePrivate() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test func featureWorks() {
                helperMethod()
            }

            func helperMethod() {
                // helper code
            }

            public func publicHelper() {
                // helper code
            }
        }
        """

        let output = """
        import Testing

        struct MyFeatureTests {
            @Test func featureWorks() {
                helperMethod()
            }

            private func helperMethod() {
                // helper code
            }

            private func publicHelper() {
                // helper code
            }
        }
        """

        testFormatting(for: input, output, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
    }

    func testSwiftTestingClassIsInternal() {
        let input = """
        import Testing

        public struct MyFeatureTests {
            @Test func featureWorks() {
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

        testFormatting(for: input, output, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
    }

    // MARK: Base Classes

    func testDoesNotApplyToBaseTestClasses() {
        let input = """
        import XCTest

        public class MyFeatureTestsBase: XCTestCase {
            public func helperMethod() {
                // helper code
            }

            public var someProperty: String = ""
        }
        """

        testFormatting(for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
    }

    func testDoesNotApplyToSwiftTestingBaseClasses() {
        let input = """
        import Testing

        public class MyFeatureTestsBase {
            public func helperMethod() {
                // helper code
            }

            public var someProperty: String = ""
        }
        """

        testFormatting(for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
    }

    func testDoesNotApplyToTestClassWithBaseInDocComment() {
        let input = """
        import XCTest

        /// Base class for feature tests.
        public class MyFeatureTests: XCTestCase {
            public func helperMethod() {
                // helper code
            }

            public var someProperty: String = ""
        }
        """

        testFormatting(for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
    }

    func testDoesNotApplyToTestClassWithSubclassInDocComment() {
        let input = """
        import XCTest

        /// Intended to be subclassed for specific feature tests.
        public class MyFeatureTests: XCTestCase {
            public func helperMethod() {
                // helper code
            }

            public var someProperty: String = ""
        }
        """

        testFormatting(for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
    }

    func testDoesNotApplyToSwiftTestingClassWithBaseInDocComment() {
        let input = """
        import Testing

        /// Base struct for testing features.
        public struct MyFeatureTests {
            public func helperMethod() {
                // helper code
            }
        }
        """

        testFormatting(for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
    }

    // MARK: Disabled Tests

    func testXCTestPreservesDisabledTestMethods() {
        let input = """
        import XCTest

        final class MyTests: XCTestCase {
            func disable_testExample() {
                XCTAssertTrue(true)
            }

            func skip_testFeature() {
                XCTAssertTrue(false)
            }
        }
        """

        testFormatting(for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
    }

    func testSwiftTestingPreservesDisabledTestMethods() {
        let input = """
        import Testing

        struct MyFeatureTests {
            func disable_featureWorks() {
                #expect(true)
            }

            func x_edgeCaseHandling() {
                #expect(false)
            }
        }
        """

        testFormatting(for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
    }

    func testXCTestPreservesCapitalizedDisabledTestMethods() {
        let input = """
        import XCTest

        final class MyTests: XCTestCase {
            func X_testExample() {
                XCTAssertTrue(true)
            }

            func DISABLE_testFeature() {
                XCTAssertTrue(false)
            }
        }
        """

        testFormatting(for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
    }

    func testSwiftTestingPreservesCapitalizedDisabledTestMethods() {
        let input = """
        import Testing

        struct MyFeatureTests {
            func SKIP_featureWorks() {
                #expect(true)
            }

            func DISABLED_edgeCaseHandling() {
                #expect(false)
            }
        }
        """

        testFormatting(for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases])
    }

    // MARK: Mixed Frameworks

    func testDoesNotApplyWhenBothTestingFrameworksAreImported() {
        let input = """
        import XCTest
        import Testing

        final class MyTests: XCTestCase {
            func testExample() {
                XCTAssertTrue(true)
            }

            func helperMethod() {
                // helper code
            }

            var someProperty: String = ""
        }
        """

        testFormatting(for: input, rule: .testSuiteAccessControl, exclude: [.unusedArguments, .validateTestCases, .sortImports])
    }
}
