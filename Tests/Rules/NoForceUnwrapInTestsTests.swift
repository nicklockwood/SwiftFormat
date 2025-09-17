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
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry, .noGuardInTests])
    }

    func testSimpleForceCast() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                let result = foo as! Foo
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let result = try XCTUnwrap(foo as? Foo)
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests)
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
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry, .noGuardInTests])
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
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry, .noGuardInTests])
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
                XCTAssertEqual(try XCTUnwrap(result?.property), "expected")
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry, .noGuardInTests])
    }

    func testForceUnwrapInIfStatement() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_ifStatement() {
                if myOptional!.value == someValue {
                    // do something
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_ifStatement() throws {
                if try XCTUnwrap(myOptional?.value) == someValue {
                    // do something
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry, .noGuardInTests])
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
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry, .noGuardInTests])
    }

    func testForceUnwrapInGuardStatement() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_guardStatement() {
                guard myOptional!.value == someValue else {
                    return
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_guardStatement() throws {
                guard try XCTUnwrap(myOptional?.value) == someValue else {
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
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry, .noGuardInTests])
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
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry, .noGuardInTests])
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
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry, .noGuardInTests])
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
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry, .noGuardInTests])
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
        testFormatting(for: input, rule: .noForceUnwrapInTests, exclude: [.hoistTry, .noGuardInTests])
    }

    func testForceUnwrapInClosureIsNotModified() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_closure() {
                someFunction {
                    let result = myOptional!
                }
            }
        }
        """
        testFormatting(for: input, rule: .noForceUnwrapInTests, exclude: [.hoistTry, .noGuardInTests])
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
        testFormatting(for: input, rule: .noForceUnwrapInTests, exclude: [.hoistTry, .noGuardInTests])
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
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry, .noGuardInTests])
    }

    func testAsyncThrowingFunction() {
        let input = """
        import Testing

        struct TestCase {
            @Test func asyncTest() async {
                let result = myOptional!
            }
        }
        """
        let output = """
        import Testing

        struct TestCase {
            @Test func asyncTest() async throws {
                let result = try #require(myOptional)
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry, .noGuardInTests])
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
                    try XCTUnwrap(myDictionary["key"]?.processedValue(with: try XCTUnwrap(parameter))),
                    expectedResult
                )
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry, .noGuardInTests])
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
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry, .noGuardInTests])
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
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry, .noGuardInTests])
    }

    func testForceCastExpressions() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_forceCasts() {
                XCTAssertEqual(route.query as! [String: String], ["a": "b"])
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_forceCasts() throws {
                XCTAssertEqual(try XCTUnwrap(route.query as? [String: String]), ["a": "b"])
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry, .noGuardInTests])
    }
}
