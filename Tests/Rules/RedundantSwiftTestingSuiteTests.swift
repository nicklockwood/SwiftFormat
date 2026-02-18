//
//  RedundantSwiftTestingSuiteTests.swift
//  SwiftFormatTests
//
//  Created by GitHub Copilot on 2/18/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class RedundantSwiftTestingSuiteTests: XCTestCase {
    func testRemoveRedundantSuiteWithNoArguments() {
        let input = """
        import Testing

        @Suite
        struct MyFeatureTests {
            @Test func myFeature() {
                #expect(true)
            }
        }
        """
        let output = """
        import Testing

        struct MyFeatureTests {
            @Test func myFeature() {
                #expect(true)
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSwiftTestingSuite)
    }

    func testRemoveRedundantSuiteWithEmptyParentheses() {
        let input = """
        import Testing

        @Suite()
        struct OtherTests {
            @Test func otherFeature() {
                #expect(true)
            }
        }
        """
        let output = """
        import Testing

        struct OtherTests {
            @Test func otherFeature() {
                #expect(true)
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSwiftTestingSuite)
    }

    func testKeepSuiteWithArguments() {
        let input = """
        import Testing

        @Suite(.serialized)
        struct SerializedTests {
            @Test func feature() {
                #expect(true)
            }
        }
        """
        testFormatting(for: input, rule: .redundantSwiftTestingSuite)
    }

    func testKeepSuiteWithDisplayName() {
        let input = """
        import Testing

        @Suite("My Test Suite")
        struct MyTests {
            @Test func feature() {
                #expect(true)
            }
        }
        """
        testFormatting(for: input, rule: .redundantSwiftTestingSuite)
    }

    func testRemoveMultipleRedundantSuites() {
        let input = """
        import Testing

        @Suite
        struct FirstTests {
            @Test func first() {
                #expect(true)
            }
        }

        @Suite()
        struct SecondTests {
            @Test func second() {
                #expect(true)
            }
        }
        """
        let output = """
        import Testing

        struct FirstTests {
            @Test func first() {
                #expect(true)
            }
        }

        struct SecondTests {
            @Test func second() {
                #expect(true)
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSwiftTestingSuite)
    }

    func testNoRemovalWithoutTestingImport() {
        let input = """
        import XCTest

        @Suite
        struct MyTests {
            func test() {
                XCTAssertTrue(true)
            }
        }
        """
        testFormatting(for: input, rule: .redundantSwiftTestingSuite)
    }

    func testRemoveSuiteOnSameLineAsDeclaration() {
        let input = """
        import Testing

        @Suite struct MyTests {
            @Test func feature() {
                #expect(true)
            }
        }
        """
        let output = """
        import Testing

        struct MyTests {
            @Test func feature() {
                #expect(true)
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSwiftTestingSuite)
    }

    func testRemoveSuiteWithOtherAttributes() {
        let input = """
        import Testing

        @Suite
        @MainActor
        struct MyTests {
            @Test func feature() {
                #expect(true)
            }
        }
        """
        let output = """
        import Testing

        @MainActor
        struct MyTests {
            @Test func feature() {
                #expect(true)
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSwiftTestingSuite)
    }

    func testRemoveSuiteAfterOtherAttributes() {
        let input = """
        import Testing

        @MainActor
        @Suite
        struct MyTests {
            @Test func feature() {
                #expect(true)
            }
        }
        """
        let output = """
        import Testing

        @MainActor
        struct MyTests {
            @Test func feature() {
                #expect(true)
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSwiftTestingSuite)
    }

    func testKeepSuiteWithMultipleArguments() {
        let input = """
        import Testing

        @Suite("Display Name", .serialized)
        struct MyTests {
            @Test func feature() {
                #expect(true)
            }
        }
        """
        testFormatting(for: input, rule: .redundantSwiftTestingSuite)
    }

    func testKeepSuiteWithArgumentsAndComments() {
        let input = """
        import Testing

        @Suite(.serialized) // Run tests serially
        struct MyTests {
            @Test func feature() {
                #expect(true)
            }
        }
        """
        testFormatting(for: input, rule: .redundantSwiftTestingSuite)
    }
}
