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
        testFormatting(for: input, output, rule: .preferRequire, exclude: [.blankLinesAfterGuardStatements, .unusedArguments])
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
        testFormatting(for: input, output, rule: .preferRequire, exclude: [.blankLinesAfterGuardStatements, .unusedArguments])
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
        testFormatting(for: input, output, rule: .preferRequire, exclude: [.blankLinesAfterGuardStatements, .unusedArguments])
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
        testFormatting(for: input, output, rule: .preferRequire, exclude: [.blankLinesAfterGuardStatements, .unusedArguments])
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
        testFormatting(for: input, output, rule: .preferRequire, exclude: [.blankLinesAfterGuardStatements, .unusedArguments])
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
        testFormatting(for: input, output, rule: .preferRequire, exclude: [.blankLinesAfterGuardStatements, .unusedArguments])
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

    func testHandlesFiveConditions() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value1 = optional1,
                      let value2 = optional2,
                      let value3 = optional3,
                      let value4 = optional4,
                      let value5 = optional5 else {
                    XCTFail()
                }
                print(value1, value2, value3, value4, value5)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value1 = try XCTUnwrap(optional1)
                let value2 = try XCTUnwrap(optional2)
                let value3 = try XCTUnwrap(optional3)
                let value4 = try XCTUnwrap(optional4)
                let value5 = try XCTUnwrap(optional5)
                print(value1, value2, value3, value4, value5)
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire, exclude: [.wrapMultilineStatementBraces, .elseOnSameLine, .blankLinesAfterGuardStatements, .wrapArguments])
    }

    func testHandlesTenConditions() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value1 = optional1,
                      let value2 = optional2,
                      let value3 = optional3,
                      let value4 = optional4,
                      let value5 = optional5,
                      let value6 = optional6,
                      let value7 = optional7,
                      let value8 = optional8,
                      let value9 = optional9,
                      let value10 = optional10 else {
                    XCTFail()
                }
                print(value1, value2, value3, value4, value5, value6, value7, value8, value9, value10)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value1 = try XCTUnwrap(optional1)
                let value2 = try XCTUnwrap(optional2)
                let value3 = try XCTUnwrap(optional3)
                let value4 = try XCTUnwrap(optional4)
                let value5 = try XCTUnwrap(optional5)
                let value6 = try XCTUnwrap(optional6)
                let value7 = try XCTUnwrap(optional7)
                let value8 = try XCTUnwrap(optional8)
                let value9 = try XCTUnwrap(optional9)
                let value10 = try XCTUnwrap(optional10)
                print(value1, value2, value3, value4, value5, value6, value7, value8, value9, value10)
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire, exclude: [.blankLinesAfterGuardStatements, .acronyms])
    }

    func testComplexRealWorldGuardStatement() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard
                      let userIdsForTransactionsQuery = queries[1].variables?["userIdsForTransactionsQuery"] as? [Int64],
                      let primaryHostUserId = queries[1].variables?["primaryHostUserId"] as? Int64,
                      let coHostUserId = queries[1].variables?["coHostUserId"] as? Int64,
                      let productTypeFilters = queries[1].variables?["productTypeFilters"] as? [[String: Any?]],
                      let firstFilter = productTypeFilters.first,
                      let productType = firstFilter["airbnbProductType"] as? String,
                      let airbnbProductIds = firstFilter["airbnbProductIds"] as? [Int64]

                    else {
                      XCTFail("The parameters of the executed dashboard query do not match the expected value")
                      return
                    }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let userIdsForTransactionsQuery = try XCTUnwrap(queries[1].variables?["userIdsForTransactionsQuery"] as? [Int64])
                let primaryHostUserId = try XCTUnwrap(queries[1].variables?["primaryHostUserId"] as? Int64)
                let coHostUserId = try XCTUnwrap(queries[1].variables?["coHostUserId"] as? Int64)
                let productTypeFilters = try XCTUnwrap(queries[1].variables?["productTypeFilters"] as? [[String: Any?]])
                let firstFilter = try XCTUnwrap(productTypeFilters.first)
                let productType = try XCTUnwrap(firstFilter["airbnbProductType"] as? String)
                let airbnbProductIds = try XCTUnwrap(firstFilter["airbnbProductIds"] as? [Int64])
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire, exclude: [.blankLinesAfterGuardStatements, .acronyms])
    }

    func testHandlesMixedComplexConditions() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard condition1,
                      let value1 = optional1,
                      condition2,
                      let value2 = optional2,
                      let value3 = optional3,
                      condition3,
                      let value4 = optional4,
                      let value5 = optional5,
                      condition4,
                      let value6 = optional6,
                      condition5 else {
                    XCTFail()
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value1 = try XCTUnwrap(optional1)
                let value2 = try XCTUnwrap(optional2)
                let value3 = try XCTUnwrap(optional3)
                let value4 = try XCTUnwrap(optional4)
                let value5 = try XCTUnwrap(optional5)
                let value6 = try XCTUnwrap(optional6)
                guard condition1, condition2, condition3, condition4, condition5 else {
                    XCTFail()
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire, exclude: [.wrapMultilineStatementBraces, .elseOnSameLine, .blankLinesAfterGuardStatements, .wrapArguments])
    }

    // MARK: - Variable shadowing tests

    func testDoesNotReplaceWhenVariableShadowing() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                let foo: String? = ""
                guard let foo else {
                    XCTFail()
                }
            }
        }
        """
        testFormatting(for: input, rule: .preferRequire)
    }

    func testDoesNotReplaceWhenVariableShadowingWithReturn() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                let value: String? = ""
                guard let value else {
                    return
                }
            }
        }
        """
        testFormatting(for: input, rule: .preferRequire)
    }

    func testHandlesGuardLetShorthand() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something(optionalValue: String?) {
                guard let optionalValue else {
                    XCTFail()
                }
                print(optionalValue)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something(optionalValue: String?) throws {
                let optionalValue = try XCTUnwrap(optionalValue)
                print(optionalValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire, exclude: [.blankLinesAfterGuardStatements, .unusedArguments])
    }

    func testHandlesGuardLetShorthandSwiftTesting() throws {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something(value: String?) {
                guard let value else {
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
            func something(value: String?) throws {
                let value = try #require(value)
                print(value)
            }
        }
        """
        testFormatting(for: input, output, rule: .preferRequire, exclude: [.blankLinesAfterGuardStatements, .unusedArguments])
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
