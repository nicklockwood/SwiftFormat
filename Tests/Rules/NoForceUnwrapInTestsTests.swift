// Created by Cal Stephens on 2025-09-16
// Copyright © 2025 Airbnb Inc. All rights reserved.

import XCTest

final class NoForceUnwrapInTestsTests: XCTestCase {
    func testReplaceForceUnwrapWithXCTUnwrapInAssignment() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                let value = optionalValue!
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
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testReplaceForceUnwrapWithRequireInAssignment() throws {
        let input = """
        import Testing

        @Test func something() {
            let value = optionalValue!
        }
        """
        let output = """
        import Testing

        @Test func something() throws {
            let value = try #require(optionalValue)
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testReplaceForceUnwrapInFunctionCallArgument() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                doSomething(optionalValue!)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                doSomething(try XCTUnwrap(optionalValue))
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testReplaceForceUnwrapInFunctionCallArgumentWithSwiftTesting() throws {
        let input = """
        import Testing

        @Test func something() {
            doSomething(optionalValue!)
        }
        """
        let output = """
        import Testing

        @Test func something() throws {
            doSomething(try #require(optionalValue))
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testReplaceMultipleForcUnwrapsInChain() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                let value = obj?.property!.anotherProperty!
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value = try XCTUnwrap(obj?.property?.anotherProperty)
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testReplaceMultipleForcUnwrapsInChainWithSwiftTesting() throws {
        let input = """
        import Testing

        @Test func something() {
            let value = obj?.property!.anotherProperty!
        }
        """
        let output = """
        import Testing

        @Test func something() throws {
            let value = try #require(obj?.property?.anotherProperty)
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testReplaceMultipleForceUnwrapsInSeparateAssignments() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                let value1 = optionalValue1!
                let value2 = optionalValue2!
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
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testReplaceForceUnwrapInVariableAssignment() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                var value = optionalValue!
                value = anotherOptionalValue!
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                var value = try XCTUnwrap(optionalValue)
                value = try XCTUnwrap(anotherOptionalValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testReplaceForceUnwrapWithTypeAnnotation() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                let value: String = optionalValue!
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value: String = try XCTUnwrap(optionalValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testDoNotAddThrowsWhenFunctionAlreadyThrows() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value = optionalValue!
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
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testDoNotApplyToNonTestFunction() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func someHelper() {
                let value = optionalValue!
            }
        }
        """
        testFormatting(for: input, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testDoNotApplyToNonTestFunctionInSwiftTesting() throws {
        let input = """
        import Testing

        func someHelper() {
            let value = optionalValue!
        }
        """
        testFormatting(for: input, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testDoNotApplyInsideClosures() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                someFunction {
                    let value = optionalValue!
                }
            }
        }
        """
        testFormatting(for: input, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testDoNotApplyInsideNestedFunctions() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                func helper() {
                    let value = optionalValue!
                }
            }
        }
        """
        testFormatting(for: input, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testReplaceForceUnwrapAfterOptionalChaining() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                let value = obj?.property!
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value = try XCTUnwrap(obj?.property)
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }


    func testReplaceForceUnwrapInArraySubscript() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                let value = array[index]!
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value = try XCTUnwrap(array[index])
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testReplaceForceUnwrapInDictionarySubscript() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                let value = dict["key"]!
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value = try XCTUnwrap(dict["key"])
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testReplaceForceUnwrapInReturnStatement() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                return optionalValue!
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                return try XCTUnwrap(optionalValue)
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testReplaceForceUnwrapWithForceCastInExpression() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                let value = (someDict["key"]! as! String).count
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                let value = try XCTUnwrap((someDict["key"] as? String).count)
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testReplaceForceUnwrapWithForceCastInFunctionArgument() throws {
        let input = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() {
                doSomething(optionalValue! as! String)
            }
        }
        """
        let output = """
        import XCTest

        class TestCase: XCTestCase {
            func test_something() throws {
                doSomething(try XCTUnwrap(optionalValue) as! String)
            }
        }
        """
        testFormatting(for: input, output, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }

    func testDoNotApplyOutsideOfTestFrameworks() throws {
        let input = """
        func someFunction() {
            let value = optionalValue!
        }
        """
        testFormatting(for: input, rule: .noForceUnwrapInTests, exclude: [.hoistTry])
    }
}
