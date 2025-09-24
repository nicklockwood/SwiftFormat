// Created by Cal Stephens on 2025-09-16.
// Copyright © 2025 Airbnb Inc. All rights reserved.

import XCTest

final class NoForceUnwrapInTestsTests: XCTestCase {
    func testSimpleForceUnwrapInXCTest() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                let result = myOptional!.with.nested!.property!
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let result = try XCTUnwrap(myOptional?.with.nested?.property)
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testSimpleForceCast() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                let result = fooBar(foo as! Foo)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let result = fooBar(try XCTUnwrap(foo as? Foo))
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testSimpleForceUnwrapInSwiftTesting() {
        let input = """
        import Testing

        struct TestCase {
            @Test func something() {
                let result = myOptional!.with.nested!.property!
            }
        }
        """
        let output = """
        import Testing

        struct TestCase {
            @Test func something() throws {
                let result = try #require(myOptional?.with.nested?.property)
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testForceUnwrapInAssignment() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_assignment() {
                let foo = someOptional!
                var bar = anotherOptional!
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_assignment() throws {
                let foo = try XCTUnwrap(someOptional)
                var bar = try XCTUnwrap(anotherOptional)
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testForceUnwrapInFunctionCallArguments() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_functionCall() {
                someFunction(myOptional!, anotherOptional!)
                XCTAssertEqual(result!.property, "expected")
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_functionCall() throws {
                someFunction(try XCTUnwrap(myOptional), try XCTUnwrap(anotherOptional))
                XCTAssertEqual(result?.property, "expected")
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testForceUnwrapInIfStatement() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_ifStatement() {
                if
                    foo!.bar(),
                    myOptional!.value == someValue
                {
                    // do something
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_ifStatement() throws {
                if
                    try XCTUnwrap(foo?.bar()),
                    myOptional?.value == someValue
                {
                    // do something
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testForceUnwrapInIfStatementWithMultipleOperators() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_ifStatement() {
                if (myOptional!.value + 10) == (someValue!.bar + 12) {
                    // do something
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_ifStatement() throws {
                if (try XCTUnwrap(myOptional?.value) + 10) == (try XCTUnwrap(someValue?.bar) + 12) {
                    // do something
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testForceUnwrapInGuardStatement() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_guardStatement() {
                guard
                    foo!.bar(),
                    myOptional!.value == someValue
                else {
                    return
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_guardStatement() throws {
                guard
                    try XCTUnwrap(foo?.bar()),
                    myOptional?.value == someValue
                else {
                    return
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry, .noGuardInTests])
    }

    func testForceUnwrapInArraySubscript() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_arraySubscript() {
                let element = array[myOptional!]
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_arraySubscript() throws {
                let element = array[try XCTUnwrap(myOptional)]
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testForceUnwrapInReturnStatement() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_return() {
                return myOptional!.array!.first(where: { foo.bar == baaz })
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_return() throws {
                return try XCTUnwrap(myOptional?.array?.first(where: { foo.bar == baaz }))
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testMultipleForceUnwrapsInExpression() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_multipleForceUnwraps() {
                let result = myOptional! + anotherOptional!
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_multipleForceUnwraps() throws {
                let result = try XCTUnwrap(myOptional) + anotherOptional!
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testForceUnwrapWithPropertyAccess() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_propertyAccess() {
                let result = object!.property!
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_propertyAccess() throws {
                let result = try XCTUnwrap(object?.property)
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testNonTestFunctionIsNotModified() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func something() {
                let result = myOptional!
            }
        }
        """
        testFormatting(for: input, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testForceUnwrapInClosureIsNotModified() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func testReturnValue() -> Bool {
                foo!.bar!
            }

            func notATest() {
                print(foo!.bar!)
            }
        }
        """
        testFormatting(for: input, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testForceUnwrapInStringInterpolationIsNotModified() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_closure() {
                // Can't be try since string interpolation is a non-throwing autoclosure
                print("foo \\(bar!)")
                print("foo \\(foo!.bar!.baaz == quux)")
            }
        }
        """
        testFormatting(for: input, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testForceUnwrapInNestedFunctionIsNotModified() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_nestedFunction() {
                func helper() {
                    let result = myOptional!
                }
            }
        }
        """
        testFormatting(for: input, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testAlreadyThrowingFunction() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_alreadyThrowing() throws {
                let result = myOptional!
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_alreadyThrowing() throws {
                let result = try XCTUnwrap(myOptional)
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testAsyncThrowingFunction() {
        let input = """
        import Testing

        struct TestCase {
            @Test func asyncTest() async {
                let myOptional = await function()
                let result = myOptional!
            }
        }
        """
        let output = """
        import Testing

        struct TestCase {
            @Test func asyncTest() async throws {
                let myOptional = await function()
                let result = try #require(myOptional)
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testComplexExpression() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_complexExpression() {
                XCTAssertEqual(
                    myDictionary["key"]!.processedValue(with: parameter!),
                    expectedResult
                )
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_complexExpression() throws {
                XCTAssertEqual(
                    myDictionary["key"]?.processedValue(with: try XCTUnwrap(parameter)),
                    expectedResult
                )
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testSwiftTestingWithMultipleAttributes() {
        let input = """
        import Testing

        struct TestCase {
            @Test
            @available(iOS 14.0, *)
            func multipleAttributes() {
                let result = myOptional!
            }
        }
        """
        let output = """
        import Testing

        struct TestCase {
            @Test
            @available(iOS 14.0, *)
            func multipleAttributes() throws {
                let result = try #require(myOptional)
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testImplicitlyUnwrappedOptionalTypesAreNotModified() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_implicitlyUnwrappedOptionals() {
                let foo: String! = "test"
                var bar: Int! = 42
                let result = foo! + "suffix"
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_implicitlyUnwrappedOptionals() throws {
                let foo: String! = "test"
                var bar: Int! = 42
                let result = try XCTUnwrap(foo) + "suffix"
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testForceCastExpressions() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_forceCasts() {
                XCTAssertEqual(route.query as! [String: String], ["a": "b"])
                XCTAssert((foo! as! Bar).baaz!)
                XCTAssert((foo! as! Bar).baaz)
            }

            func testMoreComplexForceCasts() throws {
                XCTAssert(((foo! as! Bar).baaz as! Baaz)())
                XCTAssert((foo as! [String: Any])["bar"])
                XCTAssert(foo!.baaz! is Bar)
                XCTAssert(foo!.baaz! as Bar)
                XCTAssertTrue((font.attributeDictionary[NSAttributedString.Key.font] as! UIFont).pointSize > 20)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_forceCasts() throws {
                XCTAssertEqual(route.query as? [String: String], ["a": "b"])
                XCTAssert(try XCTUnwrap((foo as? Bar)?.baaz))
                XCTAssert(try XCTUnwrap((foo as? Bar)?.baaz))
            }

            func testMoreComplexForceCasts() throws {
                XCTAssert(try XCTUnwrap(((foo as? Bar)?.baaz as? Baaz)?()))
                XCTAssert(try XCTUnwrap((foo as? [String: Any])?["bar"]))
                XCTAssert(try XCTUnwrap(foo?.baaz) is Bar)
                XCTAssert(try XCTUnwrap(foo?.baaz) as Bar)
                XCTAssertTrue(try XCTUnwrap((font.attributeDictionary[NSAttributedString.Key.font] as? UIFont)?.pointSize) > 20)
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testForceTryExpressions() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_force_try() {
                let foo = try! foo.bar() // preserved
                let bar = try! bar!.baaz()!
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_force_try() throws {
                let foo = try! foo.bar() // preserved
                let bar = try XCTUnwrap(try bar?.baaz())
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry, .noForceTryInTests])
    }

    func testForceUnwrapInAssignmentLHS() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func testForceUnwrapInAssignment() {
                foo!.bar!.baaz = quux
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func testForceUnwrapInAssignment() {
                foo?.bar?.baaz = quux
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests)
    }

    func testForceUnwrapWithPrefixOperator() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func testForceUnwrapWithPrefixOperator() throws {
                let foo = !foo!.bar!.boolean
                let bar: URL = .init(string: "foo.com")!
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func testForceUnwrapWithPrefixOperator() throws {
                let foo = !(try XCTUnwrap(foo?.bar?.boolean))
                let bar: URL = try XCTUnwrap(.init(string: "foo.com"))
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry, .propertyTypes])
    }

    func testForceUnwrapInForceUnwrappedMethodCall() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_alreadyThrowing() throws {
                let foo = foo!(bar: (foo as! Bar).quux)
                    .baaz["quux"](baaz: baaz!)
                    .quux[quux!]!
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_alreadyThrowing() throws {
                let foo = try XCTUnwrap(foo?(bar: try XCTUnwrap((foo as? Bar)?.quux))
                    .baaz["quux"](baaz: try XCTUnwrap(baaz))
                    .quux[try XCTUnwrap(quux)])
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testDisableRule() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                // swiftformat:disable:next noForceUnwrapInTests
                let result = myOptional!.with.nested!.property!
            }
        }
        """

        testFormatting(for: input, rule: .noForceUnwrapInTests)
    }

    func testForceUnwrappedMethodCallBase() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func testForceUnwrappedMethodCallBase() throws {
                foo!.prepareA()
                foo!.prepareB()
                XCTAssertNotNil(foo!.bar)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func testForceUnwrappedMethodCallBase() throws {
                foo?.prepareA()
                foo?.prepareB()
                XCTAssertNotNil(try XCTUnwrap(foo?.bar))
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests)
    }

    func testXCTAssertEqual_KeepsForceUnwrapsAsOptionalChaining() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                XCTAssertEqual(foo!.bar, baaz!.quux)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                XCTAssertEqual(foo?.bar, baaz?.quux)
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests)
    }

    func testXCTAssertNil_KeepsForceUnwrapsAsOptionalChaining() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                XCTAssertNil(foo!.bar)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                XCTAssertNil(foo?.bar)
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests)
    }

    func testEqualityComparison_KeepsForceUnwrapsAsOptionalChaining() throws {
        let input = """
        import Testing

        @Test func something() {
            #expect(foo!.bar == baaz)
        }
        """
        let output = """
        import Testing

        @Test func something() {
            #expect(foo?.bar == baaz)
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests)
    }

    func testEqualityComparisonWithNil_KeepsForceUnwrapsAsOptionalChaining() throws {
        let input = """
        import Testing

        @Test func something() {
            #expect(foo!.bar == nil)
        }
        """
        let output = """
        import Testing

        @Test func something() {
            #expect(foo?.bar == nil)
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests)
    }

    func testXCTAssertEqualWithAccuracy_RequiresXCTUnwrap() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                XCTAssertEqual(foo!.value, 3.14, accuracy: 0.01)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                XCTAssertEqual(try XCTUnwrap(foo?.value), 3.14, accuracy: 0.01)
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests)
    }

    func testForceUnwrapWithOperatorFollowing_RequiresXCTUnwrap() throws {
        let input = """
        import Testing

        @Test func something() {
            #expect(foo!.bar + 2 == 3)
        }
        """
        let output = """
        import Testing

        @Test func something() throws {
            #expect(try #require(foo?.bar) + 2 == 3)
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests)
    }
}
