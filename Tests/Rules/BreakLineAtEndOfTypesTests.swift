//
//  BreakLineAtEndOfTypesTests.swift
//  SwiftFormatTests
//
//  Created by Amir Ardalani on 2024.
//  Copyright © 2024 Amir Ardalani. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class BreakLineAtEndOfTypesTests: XCTestCase {
    // MARK: - Test Helpers

    func testBreakLineAtEndOfClass() {
        let input = """
        class FooClass {
            func fooMethod() {}
        }
        """
        let output = """
        class FooClass {
            func fooMethod() {}

        }
        """
        testFormatting(for: input, output, rule: .breakLineAtEndOfTypes)
    }

    func testBreakLineAtEndOfStruct() {
        let input = """
        struct FooStruct {
            let property: String
        }
        """
        let output = """
        struct FooStruct {
            let property: String

        }
        """
        testFormatting(for: input, output, rule: .breakLineAtEndOfTypes)
    }

    func testBreakLineAtEndOfEnum() {
        let input = """
        enum FooEnum {
            case one
            case two
        }
        """
        let output = """
        enum FooEnum {
            case one
            case two

        }
        """
        testFormatting(for: input, output, rule: .breakLineAtEndOfTypes)
    }

    func testBreakLineAtEndOfProtocol() {
        let input = """
        protocol FooProtocol {
            func fooMethod()
        }
        """
        let output = """
        protocol FooProtocol {
            func fooMethod()

        }
        """
        testFormatting(for: input, output, rule: .breakLineAtEndOfTypes)
    }

    func testBreakLineAtEndOfExtension() {
        let input = """
        extension Array where Element == Foo {
            func fooMethod() {}
        }
        """
        let output = """
        extension Array where Element == Foo {
            func fooMethod() {}

        }
        """
        testFormatting(for: input, output, rule: .breakLineAtEndOfTypes)
    }

    func testBreakLineAtEndOfActor() {
        let input = """
        actor FooActor {
            func fooMethod() {}
        }
        """
        let output = """
        actor FooActor {
            func fooMethod() {}

        }
        """
        testFormatting(for: input, output, rule: .breakLineAtEndOfTypes)
    }

    func testNoBreakLineAtEndOfFunction() {
        let input = """
        class Foo {
            func bar() {
                print("hello world")
            }

        }
        """
        testFormatting(for: input, rule: .breakLineAtEndOfTypes)
    }

    func testPreserveExistingBlankLine() {
        let input = """
        class Foo {
            func bar() {}

        }
        """
        testFormatting(for: input, rule: .breakLineAtEndOfTypes)
    }

    func testNoBreakLineBeforeElse() {
        let input = """
        class Foo {
            func bar() {
                if x {
                    print("x")
                } else {
                    print("not x")
                }
            }

        }
        """
        testFormatting(for: input, rule: .breakLineAtEndOfTypes)
    }

    func testMultipleTypesInFile() {
        let input = """
        class FirstClass {
            let property: Int = 0
        }
        struct SecondStruct {
            let property: String = ""
        }
        """
        let output = """
        class FirstClass {
            let property: Int = 0

        }
        struct SecondStruct {
            let property: String = ""

        }
        """
        testFormatting(for: input, output, rule: .breakLineAtEndOfTypes)
    }

    func testDisabledOption() {
        let input = """
        class MyClass {
            // Implementation
        }
        """
        let options = FormatOptions(breakLineAtEndOfTypes: false)
        testFormatting(for: input, rule: .breakLineAtEndOfTypes, options: options)
    }
}
