//
//  RedundantEnumeratedTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 05/10/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class RedundantEnumeratedTests: XCTestCase {
    func testDiscardedIndex() {
        let input = """
        for (_, element) in elements.enumerated() {
            print(element)
        }
        """
        let output = """
        for element in elements {
            print(element)
        }
        """
        testFormatting(for: input, output, rule: .redundantEnumerated)
    }

    func testUnusedNamedIndex() {
        let input = """
        for (index, element) in elements.enumerated() {
            print(element)
        }
        """
        let output = """
        for element in elements {
            print(element)
        }
        """
        testFormatting(for: input, output, rule: .redundantEnumerated)
    }

    func testUsedIndex() {
        let input = """
        for (index, element) in elements.enumerated() {
            print(index, element)
        }
        """
        testFormatting(for: input, rule: .redundantEnumerated)
    }

    func testIndexUsedInWhere() {
        let input = """
        for (index, element) in elements.enumerated() where index > 0 {
            print(element)
        }
        """
        testFormatting(for: input, rule: .redundantEnumerated)
    }

    func testElementUsedInWhere() {
        let input = """
        for (_, element) in elements.enumerated() where element.isEnabled {
            print(element)
        }
        """
        let output = """
        for element in elements where element.isEnabled {
            print(element)
        }
        """
        testFormatting(for: input, output, rule: .redundantEnumerated)
    }

    func testIndexUsedInClosure() {
        let input = """
        for (index, element) in elements.enumerated() {
            consume { print(index, element) }
        }
        """
        testFormatting(for: input, rule: .redundantEnumerated)
    }

    func testIndexUsedInInterpolation() {
        let input = """
        for (index, element) in elements.enumerated() {
            print("\\(index): \\(element)")
        }
        """
        testFormatting(for: input, rule: .redundantEnumerated)
    }

    func testChainedReceiver() {
        let input = """
        for (_, element) in object.elements.reversed().enumerated() {
            print(element)
        }
        """
        let output = """
        for element in object.elements.reversed() {
            print(element)
        }
        """
        testFormatting(for: input, output, rule: .redundantEnumerated)
    }

    func testReversedAfterEnumerated() {
        let input = """
        for (_, element) in elements.enumerated().reversed() {
            print(element)
        }
        """
        let output = """
        for element in elements.reversed() {
            print(element)
        }
        """
        testFormatting(for: input, output, rule: .redundantEnumerated)
    }

    func testReversedWithUnusedNamedIndex() {
        let input = """
        for (index, element) in elements.enumerated().reversed() where element.isEnabled {
            print(element)
        }
        """
        let output = """
        for element in elements.reversed() where element.isEnabled {
            print(element)
        }
        """
        testFormatting(for: input, output, rule: .redundantEnumerated)
    }

    func testReversedWithUsedIndex() {
        let input = """
        for (index, element) in elements.enumerated().reversed() {
            print(index, element)
        }
        """
        testFormatting(for: input, rule: .redundantEnumerated)
    }

    func testReversedWithIndexUsedInWhere() {
        let input = """
        for (index, element) in elements.enumerated().reversed() where index > 0 {
            print(element)
        }
        """
        testFormatting(for: input, rule: .redundantEnumerated)
    }

    func testRepeatedReversed() {
        let input = """
        for (_, element) in elements.enumerated().reversed().reversed() {
            print(element)
        }
        """
        let output = """
        for element in elements.reversed().reversed() {
            print(element)
        }
        """
        testFormatting(for: input, output, rule: .redundantEnumerated)
    }

    func testReversedPreservesComments() {
        let input = """
        for (_, element) in elements.enumerated().reversed( /* comment */ ) {
            print(element)
        }
        """
        let output = """
        for element in elements.reversed( /* comment */ ) {
            print(element)
        }
        """
        testFormatting(for: input, output, rule: .redundantEnumerated)
    }

    func testFilterAfterEnumerated() {
        let input = """
        for (_, element) in elements.enumerated().filter({ $0.offset > 2 }).reversed() {
            print(element)
        }
        """
        testFormatting(for: input, rule: .redundantEnumerated)
    }

    func testOtherMethodAfterEnumerated() {
        let input = """
        for (_, element) in elements.enumerated().something() {
            print(element)
        }
        """
        testFormatting(for: input, rule: .redundantEnumerated)
    }

    func testReversedWithArgument() {
        let input = """
        for (_, element) in elements.enumerated().reversed(custom: true) {
            print(element)
        }
        """
        testFormatting(for: input, rule: .redundantEnumerated)
    }

    func testOtherMethod() {
        let input = """
        for (_, element) in elements.something() {
            print(element)
        }
        """
        testFormatting(for: input, rule: .redundantEnumerated)
    }

    func testSingleBinding() {
        let input = """
        for element in elements.enumerated() {
            print(element)
        }
        """
        testFormatting(for: input, rule: .redundantEnumerated)
    }

    func testUnusedElement() {
        let input = """
        for (index, _) in elements.enumerated() {
            print(index)
        }
        """
        testFormatting(for: input, rule: .redundantEnumerated)
    }

    func testBothDiscarded() {
        let input = """
        for (_, _) in elements.enumerated() {
            print("hello")
        }
        """
        let output = """
        for _ in elements {
            print("hello")
        }
        """
        testFormatting(for: input, output, rule: .redundantEnumerated)
    }

    func testPatternComment() {
        let input = """
        for ( /* index */ _, element) in elements.enumerated() {
            print(element)
        }
        """
        testFormatting(for: input, rule: .redundantEnumerated)
    }

    func testCallComment() {
        let input = """
        for (_, element) in elements.enumerated( /* comment */ ) {
            print(element)
        }
        """
        testFormatting(for: input, rule: .redundantEnumerated)
    }

    func testPreserveBodyComment() {
        let input = """
        for (_, element) in elements.enumerated() {
            // Keep this comment
            print(element)
        }
        """
        let output = """
        for element in elements {
            // Keep this comment
            print(element)
        }
        """
        testFormatting(for: input, output, rule: .redundantEnumerated)
    }

    func testNestedTuple() {
        let input = """
        for (index, (key, value)) in elements.enumerated() {
            print(index, key, value)
        }
        """
        testFormatting(for: input, rule: .redundantEnumerated)
    }

    func testCallWithArgument() {
        let input = """
        for (_, element) in elements.enumerated(start: 1) {
            print(element)
        }
        """
        testFormatting(for: input, rule: .redundantEnumerated)
    }

    func testCasePattern() {
        let input = """
        for case let (_, element) in elements.enumerated() {
            print(element)
        }
        """
        testFormatting(for: input, rule: .redundantEnumerated)
    }

    func testNestedLoops() {
        let input = """
        for (_, elements) in groups.enumerated() {
            for (_, element) in elements.enumerated() {
                print(element)
            }
        }
        """
        let output = """
        for elements in groups {
            for element in elements {
                print(element)
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantEnumerated)
    }
}
