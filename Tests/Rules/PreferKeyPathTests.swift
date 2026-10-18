//
//  PreferKeyPathTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 7/29/20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class PreferKeyPathTests: XCTestCase {
    func testMapPropertyToKeyPath() {
        let input = """
        let foo = bar.map { $0.foo }
        """
        let output = """
        let foo = bar.map(\\.foo)
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, output, rule: .preferKeyPath,
                       options: options)
    }

    func testCompactMapPropertyToKeyPath() {
        let input = """
        struct Item {
            let foo: Int?
        }

        let bar: [Item] = []
        let foo = bar.compactMap { $0.foo }
        """
        let output = """
        struct Item {
            let foo: Int?
        }

        let bar: [Item] = []
        let foo = bar.compactMap(\\.foo)
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, output, rule: .preferKeyPath,
                       options: options)
    }

    func testFlatMapPropertyToKeyPath() {
        let input = """
        struct Item {
            let foo: Int?
        }

        let bar: [Item] = []
        let foo = bar.flatMap { $0.foo }
        """
        let output = """
        struct Item {
            let foo: Int?
        }

        let bar: [Item] = []
        let foo = bar.flatMap(\\.foo)
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, output, rule: .preferKeyPath,
                       options: options)
    }

    func testMapNestedPropertyWithSpacesToKeyPath() {
        let input = """
        let foo = bar.map { $0 . foo . bar }
        """
        let output = """
        let foo = bar.map(\\ . foo . bar)
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, output, rule: .preferKeyPath,
                       options: options, exclude: [.spaceAroundOperators])
    }

    func testMultilineMapPropertyToKeyPath() {
        let input = """
        let foo = bar.map {
            $0.foo
        }
        """
        let output = """
        let foo = bar.map(\\.foo)
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, output, rule: .preferKeyPath,
                       options: options)
    }

    func testParenthesizedMapPropertyToKeyPath() {
        let input = """
        let foo = bar.map({ $0.foo })
        """
        let output = """
        let foo = bar.map(\\.foo)
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, output, rule: .preferKeyPath,
                       options: options)
    }

    func testNoMapSelfToKeyPath() {
        let input = """
        let foo = bar.map { $0 }
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: .preferKeyPath, options: options)
    }

    func testNoMapPropertyToKeyPathForSwiftLessThan5_2() {
        let input = """
        let foo = bar.map { $0.foo }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, rule: .preferKeyPath, options: options)
    }

    func testNoMapPropertyToKeyPathForFunctionCalls() {
        let input = """
        let foo = bar.map { $0.foo() }
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: .preferKeyPath, options: options)
    }

    func testNoMapPropertyToKeyPathForCompoundExpressions() {
        let input = """
        let foo = bar.map { $0.foo || baz }
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: .preferKeyPath, options: options)
    }

    func testNoMapPropertyToKeyPathForOptionalChaining() {
        let input = """
        let foo = bar.map { $0?.foo }
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: .preferKeyPath, options: options)
    }

    func testNoMapPropertyToKeyPathForTrailingContains() {
        let input = """
        let foo = bar.contains { $0.foo }
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: .preferKeyPath, options: options)
    }

    func testMapPropertyToKeyPathForContainsWhere() {
        let input = """
        let foo = bar.contains(where: { $0.foo })
        """
        let output = """
        let foo = bar.contains(where: \\.foo)
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, output, rule: .preferKeyPath, options: options)
    }

    func testMultipleTrailingClosuresNotConvertedToKeyPath() {
        let input = """
        foo.map { $0.bar } reverse: { $0.bar }
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: .preferKeyPath, options: options)
    }

    func testSelfNotConvertedToKeyPathBeforeSwift6() {
        // https://bugs.swift.org/browse/SR-12897
        let input = """
        let foo = bar.compactMap { $0 }
        """
        let options = FormatOptions(swiftVersion: "5.10")
        testFormatting(for: input, rule: .preferKeyPath, options: options)
    }

    func testSelfConvertedToKeyPath() {
        let input = """
        let bar: [Int?] = []
        let foo = bar.compactMap { $0 }
        """
        let output = """
        let bar: [Int?] = []
        let foo = bar.compactMap(\\.self)
        """
        let options = FormatOptions(swiftVersion: "6")
        testFormatting(for: input, output, rule: .preferKeyPath, options: options)
    }

    func testNonOptionalAndUnknownPropertiesKeepClosures() {
        let input = """
        struct Item {
            let foo: Int
        }

        let items: [Item] = []
        let a = items.compactMap { $0.foo }
        let b = items.flatMap { $0.foo }
        let c = unknown.compactMap { $0.foo }
        let d = unknown.flatMap { $0.foo }
        """
        testFormatting(for: input, rule: .preferKeyPath, options: FormatOptions(swiftVersion: "5.2"))
    }

    func testFlatMapCollectionProperty() {
        let input = """
        struct Item {
            let values: [Int]
        }

        let items: [Item] = []
        let a = items.flatMap { $0.values }
        let b = items.compactMap { $0.values }
        let item: Item? = nil
        let c = item.flatMap { $0.values }
        """
        let output = """
        struct Item {
            let values: [Int]
        }

        let items: [Item] = []
        let a = items.flatMap(\\.values)
        let b = items.compactMap { $0.values }
        let item: Item? = nil
        let c = item.flatMap { $0.values }
        """
        testFormatting(for: input, output, rule: .preferKeyPath, options: FormatOptions(swiftVersion: "5.2"))
    }

    func testNestedOptionalPropertyFromProjectIndex() throws {
        let declarations = """
        struct Item {
            let detail: Detail
        }
        struct Detail {
            let value: Int?
        }
        """
        let input = """
        let items: [Item] = []
        let a = items.compactMap { $0.detail.value }
        let b = items.compactMap({ $0.detail.value })
        """
        let output = """
        let items: [Item] = []
        let a = items.compactMap(\\.detail.value)
        let b = items.compactMap(\\.detail.value)
        """
        _ = FormatRules.all
        let fileURL = URL(fileURLWithPath: "/Project/Call.swift")
        let project = ProjectIndex(files: [
            "/Project/Types.swift": makeSourceFileIndex(from: declarations, moduleIdentifiers: ["App"]),
            fileURL.path: makeSourceFileIndex(from: input, moduleIdentifiers: ["App"]),
        ])
        let result = try applyRules(
            [.preferKeyPath], to: tokenize(input), with: FormatOptions(swiftVersion: "5.2"),
            trackChanges: false, range: nil,
            context: FormattingContext(currentFileURL: fileURL, projectIndex: project)
        )
        XCTAssertEqual(sourceCode(for: result.tokens), output)
    }

    func testRunsAfterRedundantCompactMap() {
        _ = FormatRules.all
        XCTAssertLessThan(
            FormatRule.redundantCompactMap.index,
            FormatRule.preferKeyPath.index
        )
    }

    func testAmbiguousAndGenericPropertyTypesKeepClosures() {
        let input = """
        struct Item<T> {
            let value: T
        }

        func values<T>(items: [Item<T>]) {
            let result = items.compactMap { $0.value }
        }
        """
        testFormatting(for: input, rule: .preferKeyPath, options: FormatOptions(swiftVersion: "5.2"))
    }

    func testPropertyTypeChangesInvalidateIndex() {
        let input = """
        struct Item { let value: Int? }
        """
        let output = """
        struct Item { let value: Int }
        """
        let first = ProjectIndex(files: [
            "/Project/Types.swift": makeSourceFileIndex(from: input, moduleIdentifiers: ["App"]),
        ])
        let second = ProjectIndex(files: [
            "/Project/Types.swift": makeSourceFileIndex(from: output, moduleIdentifiers: ["App"]),
        ])
        XCTAssertNotEqual(first.fingerprint(for: [.declarations]), second.fingerprint(for: [.declarations]))
    }

    func testTypedFunctionArgument() {
        let input = """
        struct Item {
            var value: Int? {
                nil
            }
        }

        func values(items: [Item]) -> [Int] {
            items.compactMap { $0.value }
        }
        """
        let output = """
        struct Item {
            var value: Int? {
                nil
            }
        }

        func values(items: [Item]) -> [Int] {
            items.compactMap(\\.value)
        }
        """
        testFormatting(for: input, output, rule: .preferKeyPath, options: FormatOptions(swiftVersion: "5.2"))
    }

    func testShadowedReceiverKeepsClosure() {
        let input = """
        struct Item {
            let value: Int?
        }

        let items: [Item] = []
        let result = other.map { items in
            items.compactMap { $0.value }
        }
        """
        testFormatting(for: input, rule: .preferKeyPath, options: FormatOptions(swiftVersion: "5.2"))
    }

    func testNonOptionalIdentityKeepsClosure() {
        let input = """
        let items: [Int] = []
        let result = items.compactMap { $0 }
        let unknown = other.compactMap { $0 }
        """
        testFormatting(for: input, rule: .preferKeyPath, options: FormatOptions(swiftVersion: "6"))
    }

    func testTupleBindingShadowsReceiver() {
        let input = """
        struct Item {
            let value: Int?
        }

        let items: [Item] = []
        do {
            let (items, _) = other
            let result = items.compactMap { $0.value }
        }
        """
        testFormatting(for: input, rule: .preferKeyPath, options: FormatOptions(swiftVersion: "5.2"))
    }

    func testReceiverFromUnrelatedScopeIsNotUsed() {
        let input = """
        struct Item {
            let value: Int?
        }

        func first(items: [Item]) {
            print(items)
        }

        func second() {
            let result = items.compactMap { $0.value }
        }
        """
        testFormatting(for: input, rule: .preferKeyPath, options: FormatOptions(swiftVersion: "5.2"))
    }
}
