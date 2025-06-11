//
//  PreferRequireTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 11/6/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest

final class PreferRequireTests: XCTestCase {
    // MARK: - XCTest tests

    func testReplaceGuardXCTFailWithXCTUnwrap() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value = optionalValue else {
                    XCTFail()
                }
                print(value)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value = try XCTUnwrap(optionalValue)
                print(value)
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire, exclude: [.blankLinesAfterGuardStatements])
    }

    func testReplaceGuardXCTFailWithMessageWithXCTUnwrap() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value = optionalValue else {
                    XCTFail("Expected value to be non-nil")
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value = try XCTUnwrap(optionalValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire)
    }

    func testDoesNotReplaceNonTestFunction() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func helper() {
                guard let value = optionalValue else {
                    XCTFail()
                }
            }
        }
        """
        testFormatting(for: input, rule: .preferRequire)
    }

    func testDoesNotReplaceGuardWithDifferentElseBlock() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value = optionalValue else {
                    print("no value")
                    return
                }
            }
        }
        """
        testFormatting(for: input, rule: .preferRequire)
    }

    func testReplacesGuardWithDifferentExpression() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value = getDifferentValue() else {
                    XCTFail()
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value = try XCTUnwrap(getDifferentValue())
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire)
    }

    func testDoesNotReplaceInClosure() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                doSomething {
                    guard let value = optionalValue else {
                        XCTFail()
                    }
                }
            }
        }
        """
        testFormatting(for: input, rule: .preferRequire)
    }

    func testPreservesExistingThrows() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                guard let value = optionalValue else {
                    XCTFail()
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value = try XCTUnwrap(optionalValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire)
    }

    func testHandlesAsyncFunction() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() async {
                guard let value = optionalValue else {
                    XCTFail()
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() async throws {
                let value = try XCTUnwrap(optionalValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire)
    }

    func testReplaceGuardReturnWithXCTUnwrap() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value = optionalValue else {
                    return
                }
                print(value)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value = try XCTUnwrap(optionalValue)
                print(value)
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire, exclude: [.blankLinesAfterGuardStatements])
    }

    func testMultipleGuardStatements() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value1 = optionalValue1 else {
                    XCTFail()
                }
                guard let value2 = optionalValue2 else {
                    XCTFail()
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value1 = try XCTUnwrap(optionalValue1)
                let value2 = try XCTUnwrap(optionalValue2)
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire, exclude: [.blankLinesAfterGuardStatements])
    }

    // MARK: - Swift Testing tests

    func testReplaceGuardReturnWithRequire() throws {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() {
                guard let value = optionalValue else {
                    return
                }
                print(value)
            }
        }
        """
        let output = """
        import Testing

        struct SomeTests {
            @Test
            func something() throws {
                let value = try #require(optionalValue)
                print(value)
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire, exclude: [.blankLinesAfterGuardStatements])
    }

    func testDoesNotReplaceNonTestFunctionSwiftTesting() throws {
        let input = """
        import Testing

        struct SomeTests {
            func helper() {
                guard let value = optionalValue else {
                    return
                }
            }
        }
        """
        testFormatting(for: input, rule: .preferRequire)
    }

    func testDoesNotReplaceGuardWithDifferentElseBlockSwiftTesting() throws {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() {
                guard let value = optionalValue else {
                    print("no value")
                    return
                }
            }
        }
        """
        testFormatting(for: input, rule: .preferRequire)
    }

    func testDoesNotReplaceInClosureSwiftTesting() throws {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() {
                doSomething {
                    guard let value = optionalValue else {
                        return
                    }
                }
            }
        }
        """
        testFormatting(for: input, rule: .preferRequire)
    }

    func testSwiftTestingAddsThrows() throws {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() {
                guard let value = optionalValue else {
                    return
                }
            }
        }
        """
        let output = """
        import Testing

        struct SomeTests {
            @Test
            func something() throws {
                let value = try #require(optionalValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire)
    }

    func testSwiftTestingPreservesExistingThrows() throws {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() throws {
                guard let value = optionalValue else {
                    return
                }
            }
        }
        """
        let output = """
        import Testing

        struct SomeTests {
            @Test
            func something() throws {
                let value = try #require(optionalValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire)
    }

    func testSwiftTestingAsyncFunction() throws {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() async {
                guard let value = optionalValue else {
                    return
                }
            }
        }
        """
        let output = """
        import Testing

        struct SomeTests {
            @Test
            func something() async throws {
                let value = try #require(optionalValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire)
    }

    func testSwiftTestingMultipleGuardStatements() throws {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() {
                guard let value1 = optionalValue1 else {
                    return
                }
                guard let value2 = optionalValue2 else {
                    return
                }
            }
        }
        """
        let output = """
        import Testing

        struct SomeTests {
            @Test
            func something() throws {
                let value1 = try #require(optionalValue1)
                let value2 = try #require(optionalValue2)
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire, exclude: [.blankLinesAfterGuardStatements])
    }

    func testReplaceGuardWithMultipleConditionsXCTest() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value = optionalValue,
                      let other = otherValue else {
                    XCTFail()
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value = try XCTUnwrap(optionalValue)
                let other = try XCTUnwrap(otherValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire)
    }

    func testDoesNotReplaceAllConditionsInMultipleGuard() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard someCondition,
                      let value = optionalValue else {
                    XCTFail()
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value = try XCTUnwrap(optionalValue)
                guard someCondition else {
                    XCTFail()
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire)
    }

    func testReplaceMultipleGuardConditionsWithMixedPatterns() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value = optionalValue,
                      someCondition,
                      let other = otherValue else {
                    XCTFail()
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value = try XCTUnwrap(optionalValue)
                let other = try XCTUnwrap(otherValue)
                guard someCondition else {
                    XCTFail()
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire)
    }

    func testReplaceGuardWithMultipleConditionsSwiftTesting() throws {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() {
                guard let value = optionalValue,
                      someCondition else {
                    return
                }
            }
        }
        """
        let output = """
        import Testing

        struct SomeTests {
            @Test
            func something() throws {
                let value = try #require(optionalValue)
                guard someCondition else {
                    return
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire)
    }

    func testReplaceMultipleOptionalBindingsSwiftTesting() throws {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() {
                guard let value = optionalValue,
                      let other = otherValue else {
                    return
                }
            }
        }
        """
        let output = """
        import Testing

        struct SomeTests {
            @Test
            func something() throws {
                let value = try #require(optionalValue)
                let other = try #require(otherValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire)
    }

    func testSimpleMultipleConditions() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value = optionalValue, condition else {
                    XCTFail()
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value = try XCTUnwrap(optionalValue)
                guard condition else {
                    XCTFail()
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire)
    }

    func testSimpleMultipleConditions2() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard condition, 
                    let value = optionalValue
                else { XCTFail() }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value = try XCTUnwrap(optionalValue)
                guard condition else { XCTFail() }
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire, exclude: [.wrapConditionalBodies])
    }

    func testReplaceGuardIssueRecordWithRequire() throws {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() {
                guard let value = optionalValue else {
                    Issue.record()
                    return
                }
                print(value)
            }
        }
        """
        let output = """
        import Testing

        struct SomeTests {
            @Test
            func something() throws {
                let value = try #require(optionalValue)
                print(value)
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire, exclude: [.blankLinesAfterGuardStatements])
    }

    func testReplaceGuardIssueRecordWithMessageWithRequire() throws {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() {
                guard let value = optionalValue else {
                    Issue.record("Expected value to be non-nil")
                    return
                }
            }
        }
        """
        let output = """
        import Testing

        struct SomeTests {
            @Test
            func something() throws {
                let value = try #require(optionalValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire)
    }

    // MARK: - No import tests

    func testDoesNothingWithoutImport() throws {
        let input = """
        func test_something() {
            guard let value = optionalValue else {
                return
            }
        }
        """
        testFormatting(for: input, rule: .preferRequire)
    }
}
