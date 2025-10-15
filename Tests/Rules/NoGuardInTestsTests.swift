//
//  NoGuardInTestsTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 6/12/25.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import XCTest

final class NoGuardInTestsTests: XCTestCase {
    // MARK: - XCTest tests

    func testReplaceGuardXCTFailWithXCTUnwrap() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value = optionalValue else {
                    XCTFail()
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
        testFormatting(for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements])
    }

    func testReplaceGuardXCTFailWithMessageWithXCTUnwrap() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value = optionalValue else {
                    XCTFail("Expected value to be non-nil")
                    return
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
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    func testDoesNotReplaceNonTestFunction() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func helper() {
                guard let value = optionalValue else {
                    XCTFail()
                    return
                }
            }
        }
        """
        testFormatting(for: input, rule: .noGuardInTests)
    }

    func testDoesNotReplaceGuardWithDifferentElseBlock() {
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
        testFormatting(for: input, rule: .noGuardInTests)
    }

    func testReplacesGuardWithDifferentExpression() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value = getDifferentValue() else {
                    XCTFail()
                    return
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
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    func testDoesNotReplaceInClosure() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                doSomething {
                    guard let value = optionalValue else {
                        XCTFail()
                        return
                    }
                }
            }
        }
        """
        testFormatting(for: input, rule: .noGuardInTests)
    }

    func testDoesNotReplaceInNestedFunc() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                func doSomething() {
                    guard let value = optionalValue else {
                        XCTFail()
                        return
                    }
                }
            }
        }
        """
        testFormatting(for: input, rule: .noGuardInTests)
    }

    func testPreservesExistingThrows() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                guard let value = optionalValue else {
                    XCTFail()
                    return
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
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    func testHandlesAsyncFunction() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() async {
                let optionalValue = await function()
                guard let value = optionalValue else {
                    XCTFail()
                    return
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() async throws {
                let optionalValue = await function()
                let value = try XCTUnwrap(optionalValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    func testReplaceGuardReturnWithXCTUnwrap() {
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
        testFormatting(for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements])
    }

    func testMultipleGuardStatements() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value1 = optionalValue1 else {
                    XCTFail()
                    return
                }
                guard let value2 = optionalValue2 else {
                    XCTFail()
                    return
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
        testFormatting(for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements])
    }

    func testReplaceGuardWithMultipleConditionsXCTest() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value = optionalValue,
                      let other = otherValue else {
                    XCTFail()
                    return
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
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    func testDoesNotReplaceAllConditionsInMultipleGuard() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard someCondition,
                      let value = optionalValue else {
                    XCTFail()
                    return
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                XCTAssert(someCondition)
                let value = try XCTUnwrap(optionalValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    func testReplaceMultipleGuardConditionsWithMixedPatterns() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value = optionalValue,
                      someCondition,
                      let other = otherValue else {
                    XCTFail()
                    return
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value = try XCTUnwrap(optionalValue)
                XCTAssert(someCondition)
                let other = try XCTUnwrap(otherValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    func testSimpleMultipleConditions() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value = optionalValue, condition else {
                    XCTFail()
                    return
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value = try XCTUnwrap(optionalValue)
                XCTAssert(condition)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    func testSimpleMultipleConditions2() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard condition, 
                    let value = optionalValue
                else { XCTFail()
                    return }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                XCTAssert(condition)
                let value = try XCTUnwrap(optionalValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests, exclude: [.wrapConditionalBodies])
    }

    func testHandlesFiveConditions() {
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
                    return
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
        testFormatting(for: input, output, rule: .noGuardInTests, exclude: [.wrapMultilineStatementBraces, .elseOnSameLine, .blankLinesAfterGuardStatements, .wrapArguments])
    }

    func testHandlesTenConditions() {
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
                    return
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
        testFormatting(for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements, .acronyms])
    }

    func testHandlesMixedComplexConditions() {
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
                    return
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                XCTAssert(condition1)
                let value1 = try XCTUnwrap(optional1)
                XCTAssert(condition2)
                let value2 = try XCTUnwrap(optional2)
                let value3 = try XCTUnwrap(optional3)
                XCTAssert(condition3)
                let value4 = try XCTUnwrap(optional4)
                let value5 = try XCTUnwrap(optional5)
                XCTAssert(condition4)
                let value6 = try XCTUnwrap(optional6)
                XCTAssert(condition5)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests, exclude: [.wrapMultilineStatementBraces, .elseOnSameLine, .blankLinesAfterGuardStatements, .wrapArguments])
    }

    // MARK: - Swift Testing tests

    func testReplaceGuardReturnWithRequire() {
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
        testFormatting(for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements])
    }

    func testDoesNotReplaceNonTestFunctionSwiftTesting() {
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
        testFormatting(for: input, rule: .noGuardInTests)
    }

    func testDoesNotReplaceGuardWithDifferentElseBlockSwiftTesting() {
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
        testFormatting(for: input, rule: .noGuardInTests)
    }

    func testDoesNotReplaceInClosureSwiftTesting() {
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
        testFormatting(for: input, rule: .noGuardInTests)
    }

    func testSwiftTestingAddsThrows() {
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
        testFormatting(for: input, output, rule: .noGuardInTests, exclude: [.elseOnSameLine])
    }

    func testSwiftTestingPreservesExistingThrows() {
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
        testFormatting(for: input, output, rule: .noGuardInTests, exclude: [.elseOnSameLine])
    }

    func testSwiftTestingAsyncFunction() {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() async {
                let optionalValue = await function()
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
                let optionalValue = await function()
                let value = try #require(optionalValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    func testSwiftTestingMultipleGuardStatements() {
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
        testFormatting(for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements])
    }

    func testReplaceGuardWithMultipleConditionsSwiftTesting() {
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
                #expect(someCondition)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    func testReplaceMultipleOptionalBindingsSwiftTesting() {
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
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    func testReplaceGuardIssueRecordWithRequire() {
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
        testFormatting(for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements])
    }

    func testReplaceGuardIssueRecordWithMessageWithRequire() {
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
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    func testNonUnwrapConditionsDontInsertThrows() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard condition, optionalValue != nil else {
                    XCTFail()
                    return
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                XCTAssert(condition)
                XCTAssert(optionalValue != nil)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    // MARK: - Variable shadowing tests

    func testDoesNotReplaceWhenVariableShadowing() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                let foo: String? = ""
                guard let foo else {
                    XCTFail()
                    return
                }
            }
        }
        """
        testFormatting(for: input, rule: .noGuardInTests)
    }

    func testDoesNotReplaceWhenVariableShadowingWithReturn() {
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
        testFormatting(for: input, rule: .noGuardInTests)
    }

    func testHandlesGuardLetShorthand() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            var optionalValue: String?

            func test_something() {
                guard let optionalValue else {
                    XCTFail()
                    return
                }
                print(optionalValue)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            var optionalValue: String?

            func test_something() throws {
                let optionalValue = try XCTUnwrap(optionalValue)
                print(optionalValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements])
    }

    func testHandlesGuardLetShorthandSwiftTesting() {
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
        testFormatting(for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements])
    }

    func testHandlesExplicitTypeAnnotation() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard var foo: Foo = getFoo() else {
                    XCTFail()
                    return
                }
                foo = otherFoo
                print(foo)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                var foo: Foo = try XCTUnwrap(getFoo())
                foo = otherFoo
                print(foo)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements])
    }

    func testHandlesExplicitTypeAnnotationWithShorthand() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let foo, let bar: Bar else {
                    XCTFail()
                    return
                }
                print(foo, bar)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let foo = try XCTUnwrap(foo)
                let bar: Bar = try XCTUnwrap(bar)
                print(foo, bar)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements])
    }

    func testHandlesComplexTypeAnnotation() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let value: [String: Any] = getDictionary() else {
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
                let value: [String: Any] = try XCTUnwrap(getDictionary())
                print(value)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements])
    }

    func testHandlesTypeAnnotationSwiftTesting() {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() {
                guard let result: Result<String, Error> = getResult() else {
                    return
                }
                print(result)
            }
        }
        """
        let output = """
        import Testing

        struct SomeTests {
            @Test
            func something() throws {
                let result: Result<String, Error> = try #require(getResult())
                print(result)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements])
    }

    func testPreservesDependentConditions() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                let result = sut.contentAsGalleryMediaItems.first
                guard let result, let image = result.image else {
                    XCTFail("gallery media item expected to be an image type")
                    return
                }
                print(image)
            }
        }
        """
        testFormatting(for: input, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements])
    }

    func testConvertsBooleanConditionsToXCTAssert() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard someCondition,
                      let value = optionalValue else {
                    XCTFail()
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
                XCTAssert(someCondition)
                let value = try XCTUnwrap(optionalValue)
                print(value)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements, .unusedArguments])
    }

    func testConvertsBooleanConditionsToExpect() {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() {
                guard someCondition,
                      let value = optionalValue else {
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
                #expect(someCondition)
                let value = try #require(optionalValue)
                print(value)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements])
    }

    func testConvertsMultipleBooleanConditions() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard condition1,
                      condition2,
                      let value = optionalValue,
                      condition3 else {
                    XCTFail()
                    return
                }
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                XCTAssert(condition1)
                XCTAssert(condition2)
                let value = try XCTUnwrap(optionalValue)
                XCTAssert(condition3)
            }
        }
        """
        testFormatting(for: input, output, rule: .noGuardInTests)
    }

    func testPreservesGuardWithShadowedVariable() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                let foo = "existing"
                guard someCondition,
                      let foo = optionalFoo else {
                    XCTFail()
                    return
                }
                print(foo)
            }
        }
        """
        testFormatting(for: input, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements, .elseOnSameLine, .wrapMultilineStatementBraces])
    }

    func testPreservesGuardWithAnyShadowing() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                let bar = "existing"
                guard someCondition,
                      let foo = optionalFoo,
                      let bar = optionalBar else {
                    XCTFail()
                    return
                }
                print(foo, bar)
            }
        }
        """
        // Since bar is shadowed, we preserve the entire guard
        testFormatting(for: input, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements, .elseOnSameLine, .wrapMultilineStatementBraces])
    }

    func testPreservesGuardWithMixedCasePattern() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                guard let foo = optionalFoo,
                      case .success(let value) = result else {
                    XCTFail()
                    return
                }
                print(foo, value)
            }
        }
        """
        testFormatting(for: input, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements, .hoistPatternLet, .elseOnSameLine, .wrapMultilineStatementBraces])
    }

    // MARK: - Await tests

    func testPreservesGuardWithAwaitInCondition() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() async {
                guard let value = await getAsyncValue() else {
                    XCTFail()
                    return
                }
                print(value)
            }
        }
        """
        testFormatting(for: input, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements])
    }

    func testPreservesGuardWithAwaitInConditionSwiftTesting() {
        let input = """
        import Testing

        struct SomeTests {
            @Test
            func something() async {
                guard let value = await getAsyncValue() else {
                    return
                }
                print(value)
            }
        }
        """
        testFormatting(for: input, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements])
    }

    func testPreservesGuardWithAwaitInMultipleConditions() {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() async {
                guard let value1 = optionalValue,
                      let value2 = await getAsyncValue() else {
                    XCTFail()
                    return
                }
                print(value1, value2)
            }
        }
        """
        testFormatting(for: input, rule: .noGuardInTests, exclude: [.blankLinesAfterGuardStatements, .elseOnSameLine, .wrapMultilineStatementBraces])
    }

    // MARK: - No import tests

    func testDoesNothingWithoutImport() {
        let input = """
        func test_something() {
            guard let value = optionalValue else {
                return
            }
        }
        """
        testFormatting(for: input, rule: .noGuardInTests)
    }
}
