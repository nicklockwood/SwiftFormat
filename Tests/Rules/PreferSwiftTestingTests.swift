//
//  PreferSwiftTestingTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 1/25/25.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class PreferSwiftTestingTests: XCTestCase {
    func testConvertsSimpleTestSuite() {
        let input = """
        @testable import MyFeatureLib
        import XCTest

        final class MyFeatureTests: XCTestCase {
            func testMyFeatureWorks() {
                let myFeature = MyFeature()
                myFeature.runAction()
                XCTAssertTrue(myFeature.worksProperly)
                XCTAssertEqual(myFeature.screens.count, 8)
            }

            func testMyFeatureHasNoBugs() {
                let myFeature = MyFeature()
                myFeature.runAction()
                XCTAssertFalse(myFeature.hasBugs, "My feature has no bugs")
                XCTAssertEqual(myFeature.crashes.count, 0, "My feature doesn't crash")
                XCTAssertNil(myFeature.crashReport)
            }
        }
        """

        let output = """
        import Foundation
        @testable import MyFeatureLib
        import Testing

        @MainActor @Suite(.serialized)
        final class MyFeatureTests {
            @Test func myFeatureWorks() {
                let myFeature = MyFeature()
                myFeature.runAction()
                #expect(myFeature.worksProperly)
                #expect(myFeature.screens.count == 8)
            }

            @Test func myFeatureHasNoBugs() {
                let myFeature = MyFeature()
                myFeature.runAction()
                #expect(!myFeature.hasBugs, "My feature has no bugs")
                #expect(myFeature.crashes.isEmpty, "My feature doesn't crash")
                #expect(myFeature.crashReport == nil)
            }
        }
        """

        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, [output], rules: [.preferSwiftTesting, .sortImports, .isEmpty], options: options)
    }

    func testConvertsTestSuiteWithSetUpTearDown() {
        let input = """
        @testable import MyFeatureLib
        import XCTest

        final class MyFeatureTests: XCTestCase {
            var myFeature: MyFeature!

            override func setUp() async throws {
                try await super.setUp()
                myFeature = try await MyFeature()
            }

            override func tearDown() {
                super.tearDown()
                myFeature = nil
            }

            func testMyFeatureHasNoBugs() {
                myFeature.runAction()
                XCTAssertFalse(myFeature.hasBugs, "My feature has no bugs")
                XCTAssertEqual(myFeature.crashes.count, 0, "My feature doesn't crash")
                XCTAssertNil(myFeature.crashReport)
            }
        }
        """

        let output = """
        import Foundation
        @testable import MyFeatureLib
        import Testing

        @MainActor @Suite(.serialized)
        final class MyFeatureTests {
            var myFeature: MyFeature!

            init() async throws {
                myFeature = try await MyFeature()
            }

            deinit {
                myFeature = nil
            }

            @Test func myFeatureHasNoBugs() {
                myFeature.runAction()
                #expect(!myFeature.hasBugs, "My feature has no bugs")
                #expect(myFeature.crashes.isEmpty, "My feature doesn't crash")
                #expect(myFeature.crashReport == nil)
            }
        }
        """

        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, [output], rules: [.preferSwiftTesting, .sortImports, .isEmpty], options: options)
    }

    func testConvertsSimpleXCTestHelpers() {
        let input = """
        import XCTest

        class HelperConversionTests: XCTestCase {
            func testConvertsSimpleXCTestHelpers() throws {
                XCTAssert(foo)
                XCTAssert(foo, "foo is true")
                XCTAssert(foo, "foo" + " is true")
                XCTAssertTrue(foo)
                XCTAssertTrue(foo, "foo is true")
                XCTAssertFalse(foo)
                XCTAssertFalse(foo, "foo is false")
                XCTAssertFalse(foo() == bar(), "foo is not equal to bar")
                XCTAssertFalse(Foo(hasBar: foo == bar).isValid)
                XCTAssertFalse(try foo)
                XCTAssertFalse(try! foo.bar.baz())
                XCTAssertFalse(foo is Bar)
                XCTAssertNil(foo)
                XCTAssertNil(foo, "foo is nil")
                XCTAssertNotNil(foo)
                XCTAssertNotNil(foo, "foo is not nil")
                XCTAssertEqual(foo, bar)
                XCTAssertEqual(foo, bar, "foo and bar are equal")
                XCTAssertEqual(foo, bar, "foo and bar" + " are equal")
                XCTAssertEqual(foo == bar, foo == baaz)
                XCTAssertEqual(foo is Bar, false)
                XCTAssertNotEqual(foo == bar, foo == baaz)
                XCTAssertNotEqual(foo, bar)
                XCTAssertNotEqual(foo, bar, "foo and bar are different")
                XCTAssertIdentical(foo, bar)
                XCTAssertIdentical(foo, bar, "foo and bar are the same reference")
                XCTAssertNotIdentical(foo, bar)
                XCTAssertNotIdentical(foo, bar, "foo and bar are different references")
                XCTAssertGreaterThan(foo, bar)
                XCTAssertGreaterThan(foo, bar, "foo is greater than bar")
                XCTAssertGreaterThanOrEqual(foo, bar)
                XCTAssertGreaterThanOrEqual(foo, bar, "foo is greater than or equal bar")
                XCTAssertLessThan(foo, bar)
                XCTAssertLessThan(foo, bar, "foo is less than bar")
                XCTAssertLessThanOrEqual(foo, bar)
                XCTAssertLessThanOrEqual(foo, bar, "foo is less than or equal bar")
                XCTFail()
                XCTFail("Unexpected issue")
                XCTFail("Unexpected" + " " + "issue")
                XCTFail(someStringValue)
                try XCTUnwrap(foo)
                try XCTUnwrap(foo, "foo should not be nil")
                XCTAssertThrowsError(try foo.bar)
                XCTAssertThrowsError(try foo.bar, "foo.bar should throw an error")
                XCTAssertNoThrow(try foo.bar)
                XCTAssertNoThrow(try foo.bar, "foo.bar should not throw an error")
            }
        }
        """

        let output = """
        import Foundation
        import Testing

        @MainActor @Suite(.serialized)
        class HelperConversionTests {
            @Test func convertsSimpleXCTestHelpers() throws {
                #expect(foo)
                #expect(foo, "foo is true")
                #expect(foo, Comment(rawValue: "foo" + " is true"))
                #expect(foo)
                #expect(foo, "foo is true")
                #expect(!foo)
                #expect(!foo, "foo is false")
                #expect(!(foo() == bar()), "foo is not equal to bar")
                #expect(!Foo(hasBar: foo == bar).isValid)
                #expect(try !foo)
                #expect(!(try! foo.bar.baz()))
                #expect(!(foo is Bar))
                #expect(foo == nil)
                #expect(foo == nil, "foo is nil")
                #expect(foo != nil)
                #expect(foo != nil, "foo is not nil")
                #expect(foo == bar)
                #expect(foo == bar, "foo and bar are equal")
                #expect(foo == bar, Comment(rawValue: "foo and bar" + " are equal"))
                #expect((foo == bar) == (foo == baaz))
                #expect((foo is Bar) == false)
                #expect((foo == bar) != (foo == baaz))
                #expect(foo != bar)
                #expect(foo != bar, "foo and bar are different")
                #expect(foo === bar)
                #expect(foo === bar, "foo and bar are the same reference")
                #expect(foo !== bar)
                #expect(foo !== bar, "foo and bar are different references")
                #expect(foo > bar)
                #expect(foo > bar, "foo is greater than bar")
                #expect(foo >= bar)
                #expect(foo >= bar, "foo is greater than or equal bar")
                #expect(foo < bar)
                #expect(foo < bar, "foo is less than bar")
                #expect(foo <= bar)
                #expect(foo <= bar, "foo is less than or equal bar")
                Issue.record()
                Issue.record("Unexpected issue")
                Issue.record(Comment(rawValue: "Unexpected" + " " + "issue"))
                Issue.record(Comment(rawValue: someStringValue))
                try #require(foo)
                try #require(foo, "foo should not be nil")
                #expect(throws: Error.self) { try foo.bar }
                #expect(throws: Error.self, "foo.bar should throw an error") { try foo.bar }
                #expect(throws: Never.self) { try foo.bar }
                #expect(throws: Never.self, "foo.bar should not throw an error") { try foo.bar }
            }
        }
        """

        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, [output], rules: [.preferSwiftTesting, .wrapArguments, .indent, .redundantParens, .hoistTry], options: options, exclude: [.throwingTests])
    }

    func testConvertsMultilineXCTestHelpers() {
        let input = """
        import XCTest

        class HelperConversionTests: XCTestCase {
            func test_converts_multiline_XCTest_helpers() {
                XCTAssert(foo.bar(
                    baaz: "baaz",
                    quux: "quux"))

                XCTAssertEqual(
                    // Comment before first argument
                    foo.bar.baaz("quux"),
                    // Comment before second argument
                    Foo(bar: "bar", baaz: "Baaz"))

                XCTAssert(
                    // Comment before first argument
                    foo.bar(baaz: "baaz", quux: "quux"),
                    // Comment before message
                    "foo is valid")

                XCTAssertEqual(
                    // Comment before first argument
                    foo.bar.baaz("quux"),
                    // Comment before second argument
                    Foo(bar: "bar", baaz: "Baaz"),
                    // Comment before message
                    "foo matches expected value")

                XCTFail(
                    // Comment before multiline string
                    #\"\"\"
                    Multiline string
                    in method call
                    \"\"\"#)

                XCTAssertFalse(
                    // Comment before first argument
                    foo.bar.baaz.quux,
                    // Comment before second argument
                    "foo.bar.baaz.quux is false")
            }
        }
        """

        let output = """
        import Foundation
        import Testing

        @MainActor @Suite(.serialized)
        class HelperConversionTests {
            @Test func converts_multiline_XCTest_helpers() {
                #expect(foo.bar(
                    baaz: "baaz",
                    quux: "quux"))

                #expect(
                    // Comment before first argument
                    foo.bar.baaz("quux") ==
                        // Comment before second argument
                        Foo(bar: "bar", baaz: "Baaz"))

                #expect(
                    // Comment before first argument
                    foo.bar(baaz: "baaz", quux: "quux"),
                    // Comment before message
                    "foo is valid")

                #expect(
                    // Comment before first argument
                    foo.bar.baaz("quux") ==
                        // Comment before second argument
                        Foo(bar: "bar", baaz: "Baaz"),
                    // Comment before message
                    "foo matches expected value")

                Issue.record(
                    // Comment before multiline string
                    #\"\"\"
                    Multiline string
                    in method call
                    \"\"\"#)

                #expect(
                    // Comment before first argument
                    !foo.bar.baaz.quux,
                    // Comment before second argument
                    "foo.bar.baaz.quux is false")
            }
        }
        """

        let options = FormatOptions(closingParenPosition: .sameLine, swiftVersion: "6.0")
        testFormatting(for: input, [output], rules: [.preferSwiftTesting, .wrapArguments, .indent, .trailingSpace], options: options)
    }

    func testPreservesUnsupportedExpectationHelpers() {
        let input = """
        @testable import MyFeatureLib
        import XCTest

        final class MyFeatureTests: XCTestCase {
            func testMyAsyncFeatureWorks() {
                let expectation = expectation(description: "my feature runs async")
                MyFeature().run {
                    expectation.fulfill()
                }
                wait(for: [expectation])
            }
        }
        """

        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, rule: .preferSwiftTesting, options: options)
    }

    func testPreservesUnsupportedUITestHelpers() {
        let input = """
        @testable import MyFeatureLib
        import XCTest

        final class MyFeatureTests: XCTestCase {
            func testUITest() {
                let app = XCUIApplication()
                app.buttons["Learn More"].tap()
                XCTAssert(app.staticTexts["Success"].exists)
            }
        }
        """

        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, rule: .preferSwiftTesting, options: options)
    }

    func testPreservesUnsupportedPerformanceTestHelpers() {
        let input = """
        @testable import MyFeatureLib
        import XCTest

        final class MyFeatureTests: XCTestCase {
            func testPerformance() {
                measure {
                    MyFeature.expensiveOperation()
                }
            }
        }
        """

        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, rule: .preferSwiftTesting, options: options)
    }

    func testPreservesAsyncOrThrowsTearDown() {
        let input = """
        @testable import MyFeatureLib
        import XCTest

        final class MyFeatureTests: XCTestCase {
            var myFeature: MyFeature!

            override func setUp() async throws {
                try await super.setUp()
                myFeature = try await MyFeature()
            }

            /// deinit can't be async / throws
            override func tearDown() async throws {
                super.tearDown()
                try await myFeature.cleanUp()
            }

            func testMyFeatureHasNoBugs() {
                myFeature.runAction()
                XCTAssertFalse(myFeature.hasBugs)
            }
        }
        """

        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, rule: .preferSwiftTesting, options: options)
    }

    func testPreservesUnsupportedMethodOverride() {
        let input = """
        @testable import MyFeatureLib
        import XCTest

        final class MyFeatureTests: XCTestCase {
            func testMyFeatureWorks() {
                let myFeature = MyFeature()
                myFeature.runAction()
                XCTAssertTrue(myFeature.worksProperly)
            }

            override func someUnknownOveride() {
                super.someUnknownOveride()
                print("test")
            }
        }
        """

        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, rule: .preferSwiftTesting, options: options)
    }

    func testConvertsHelpersInHelperMethods() {
        let input = """
        @testable import MyFeatureLib
        import XCTest

        final class MyFeatureTests: XCTestCase {
            func testMyFeatureWorks() {
                let myFeature = MyFeature()
                assertMyFeatureWorks(myFeature)
            }
        }

        func assertMyFeatureWorks(_ feature: MyFeature) {
            XCTAssert(feature.works)
        }
        """

        let output = """
        import Foundation
        @testable import MyFeatureLib
        import Testing

        @MainActor @Suite(.serialized)
        final class MyFeatureTests {
            @Test func myFeatureWorks() {
                let myFeature = MyFeature()
                assertMyFeatureWorks(myFeature)
            }
        }

        func assertMyFeatureWorks(_ feature: MyFeature) {
            #expect(feature.works)
        }
        """

        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, [output], rules: [.preferSwiftTesting, .sortImports], options: options)
    }

    func testPreservesHelpersWithLineFileParams() {
        let input = """
        @testable import MyFeatureLib
        import XCTest

        final class MyFeatureTests: XCTestCase {
            func testMyFeatureWorks() {
                let myFeature = MyFeature()
                assertMyFeatureWorks(myFeature)
            }
        }

        func assertMyFeatureWorks(_ feature: MyFeature, file: StaticString = #file, line: UInt = #line) {
            XCTAssert(feature.works, file: file, line: line)
        }
        """

        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, rule: .preferSwiftTesting, options: options)
    }

    func testDoesntUpdateNameToIdentifierRequiringBackTicks() {
        let input = """
        import XCTest

        final class MyFeatureTests: XCTestCase {
            func test123() {
                XCTAssertEqual(1 + 2, 3)
            }

            func testInit() {
                XCTAssertNotNil(Foo())
            }

            func testSubscript() {
                XCTAssertNotNil(foo[bar])
            }

            func testNil() {
                XCTAssertNil(foo.optionalFoo)
            }
        }
        """

        let output = """
        import Foundation
        import Testing

        @MainActor @Suite(.serialized)
        final class MyFeatureTests {
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
        }
        """

        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, [output], rules: [.preferSwiftTesting, .sortImports], options: options)
    }

    func testDoesntUpTestNameToExistingFunctionName() {
        let input = """
        import XCTest

        final class MyFeatureTests: XCTestCase {
            func testOnePlusTwo() {
                XCTAssertEqual(onePlusTwo(), 3)
            }

            func onePlusTwo() -> Int {
                1 + 2
            }
        }
        """

        let output = """
        import Foundation
        import Testing

        @MainActor @Suite(.serialized)
        final class MyFeatureTests {
            @Test func testOnePlusTwo() {
                #expect(onePlusTwo() == 3)
            }

            func onePlusTwo() -> Int {
                1 + 2
            }
        }
        """

        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, [output], rules: [.preferSwiftTesting, .sortImports], options: options)
    }

    func testPreservesTestMethodWithArguments() {
        let input = """
        import XCTest

        final class MyFeatureTests: XCTestCase {
            func testMyFeatureWorks() {
                testMyFeatureWorks(MyFeature())
            }

            func testMyFeatureWorks(_ feature: Feature) {
                feature.runAction()
                XCTAssertTrue(feature.worksProperly)
            }
        }
        """

        let output = """
        import Foundation
        import Testing

        @MainActor @Suite(.serialized)
        final class MyFeatureTests {
            @Test func myFeatureWorks() {
                testMyFeatureWorks(MyFeature())
            }

            func testMyFeatureWorks(_ feature: Feature) {
                feature.runAction()
                #expect(feature.worksProperly)
            }
        }
        """

        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, [output], rules: [.preferSwiftTesting, .sortImports], options: options)
    }

    func testAddsThrowingEffectIfNeeded() {
        // XCTest helpers all have throwing autoclosure params,
        // so can have `try` without the test case being `throws`.
        // #exect doesn't work like this, so the test case has to be throwing.
        let input = """
        import XCTest

        final class MyFeatureTests: XCTestCase {
            func testMyFeatureWorks() {
                let myFeature = MyFeature()
                XCTAssertTrue(try feature.worksProperly)
            }

            func testMyFeatureWorksAsync() async {
                let myFeature = await MyFeature()
                XCTAssertTrue(try feature.worksProperly)
            }
        }
        """

        let output = """
        import Foundation
        import Testing

        @MainActor @Suite(.serialized)
        final class MyFeatureTests {
            @Test func myFeatureWorks() throws {
                let myFeature = MyFeature()
                #expect(try feature.worksProperly)
            }

            @Test func myFeatureWorksAsync() async throws {
                let myFeature = await MyFeature()
                #expect(try feature.worksProperly)
            }
        }
        """

        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, [output], rules: [.preferSwiftTesting, .sortImports], options: options)
    }

    func testPreservesAdditionalXCTestSymbols() {
        let input = """
        @testable import MyFeatureLib
        import XCTest

        final class MyFeatureTests: XCTestCase {
            func testMyFeatureWorks() {
                let myFeature = MyFeature()
                myCustomTestHelper(myFeature) // XCTest-based helper defined in another file
            }
        }
        """

        let options = FormatOptions(additionalXCTestSymbols: ["myCustomTestHelper"], swiftVersion: "6.0")
        testFormatting(for: input, rule: .preferSwiftTesting, options: options)
    }

    func testPreservesXCTestCaseExtension() {
        let input = """
        @testable import MyFeatureLib
        import XCTest

        final class MyFeatureTests: XCTestCase {
            func testMyFeatureWorks() {
                let myFeature = MyFeature()
                myHelper()
                XCTAssert(myFeature.works)
            }
        }

        extension XCTestCase {
            func myHelper() {
                print("...")
            }
        }

        """

        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, rule: .preferSwiftTesting, options: options)
    }

    func testAddsUIKitImportIfNeeded() {
        let input = """
        import XCTest

        final class MyFeatureTests: XCTestCase {
            func testMyFeatureWorks() {
                let viewController = UIViewController()
                XCTAssertNotNil(viewController.view)
            }
        }
        """

        let output = """
        import Foundation
        import Testing
        import UIKit

        @MainActor @Suite(.serialized)
        final class MyFeatureTests {
            @Test func myFeatureWorks() {
                let viewController = UIViewController()
                #expect(viewController.view != nil)
            }
        }
        """

        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, [output], rules: [.preferSwiftTesting, .sortImports], options: options)
    }
}
