//
//  GenericExtensionsTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/18/22.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class GenericExtensionsTests: XCTestCase {
    func testUpdatesArrayGenericExtensionToAngleBracketSyntax() {
        let input = """
        extension Array where Element == Foo {}
        """
        let output = """
        extension Array<Foo> {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .genericExtensions, options: options, exclude: [.typeSugar, .emptyExtensions])
    }

    func testUpdatesOptionalGenericExtensionToAngleBracketSyntax() {
        let input = """
        extension Optional where Wrapped == Foo {}
        """
        let output = """
        extension Optional<Foo> {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .genericExtensions, options: options, exclude: [.typeSugar, .emptyExtensions])
    }

    func testUpdatesArrayGenericExtensionToAngleBracketSyntaxWithSelf() {
        let input = """
        extension Array where Self.Element == Foo {}
        """
        let output = """
        extension Array<Foo> {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .genericExtensions, options: options, exclude: [.typeSugar, .emptyExtensions])
    }

    func testUpdatesArrayWithGenericElement() {
        let input = """
        extension Array where Element == Foo<Bar> {}
        """
        let output = """
        extension Array<Foo<Bar>> {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .genericExtensions, options: options, exclude: [.typeSugar, .emptyExtensions])
    }

    func testUpdatesDictionaryGenericExtensionToAngleBracketSyntax() {
        let input = """
        extension Dictionary where Key == Foo, Value == Bar {}
        """
        let output = """
        extension Dictionary<Foo, Bar> {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .genericExtensions, options: options, exclude: [.typeSugar, .emptyExtensions])
    }

    func testRequiresAllGenericTypesToBeProvided() {
        // No type provided for `Value`, so we can't use the angle bracket syntax
        let input = """
        extension Dictionary where Key == Foo {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .genericExtensions, options: options, exclude: [.emptyExtensions])
    }

    func testHandlesNestedCollectionTypes() {
        let input = """
        extension Array where Element == [[Foo: Bar]] {}
        """
        let output = """
        extension Array<[[Foo: Bar]]> {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .genericExtensions, options: options, exclude: [.typeSugar, .emptyExtensions])
    }

    func testDoesntUpdateIneligibleConstraints() {
        // This could potentially by `extension Optional<some Fooable>` in a future language version
        // but that syntax isn't implemented as of Swift 5.7
        let input = """
        extension Optional where Wrapped: Fooable {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .genericExtensions, options: options, exclude: [.emptyExtensions])
    }

    func testPreservesOtherConstraintsInWhereClause() {
        let input = """
        extension Collection where Element == String, Index == Int {}
        """
        let output = """
        extension Collection<String> where Index == Int {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .genericExtensions, options: options, exclude: [.emptyExtensions])
    }

    func testPreservesOtherConstraintsBeforeGenericConstraintInWhereClause() {
        let input = """
        extension Collection where Self == [Path], Element == Path {}
        """
        let output = """
        extension Collection<Path> where Self == [Path] {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .genericExtensions, options: options, exclude: [.emptyExtensions])
    }

    func testSupportsUserProvidedGenericTypes() {
        let input = """
        extension StateStore where State == FooState, Action == FooAction {}
        extension LinkedList where Element == Foo {}
        """
        let output = """
        extension StateStore<FooState, FooAction> {}
        extension LinkedList<Foo> {}
        """

        let options = FormatOptions(
            genericTypes: "LinkedList<Element>;StateStore<State, Action>",
            swiftVersion: "5.7"
        )
        testFormatting(for: input, output, rule: .genericExtensions, options: options, exclude: [.emptyExtensions])
    }

    func testSupportsMultilineUserProvidedGenericTypes() {
        let input = """
        extension Reducer where
            State == MyFeatureState,
            Action == MyFeatureAction,
            Environment == ApplicationEnvironment
        {}
        """
        let output = """
        extension Reducer<MyFeatureState, MyFeatureAction, ApplicationEnvironment> {}
        """

        let options = FormatOptions(
            genericTypes: "Reducer<State, Action, Environment>",
            swiftVersion: "5.7"
        )
        testFormatting(for: input, output, rule: .genericExtensions, options: options, exclude: [.emptyExtensions])
    }

    func testUpdatesRangeReplaceableCollectionGenericExtension() {
        let input = """
        extension RangeReplaceableCollection where Element == Path {}
        """
        let output = """
        extension RangeReplaceableCollection<Path> {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .genericExtensions, options: options, exclude: [.emptyExtensions])
    }

    func testUpdatesBidirectionalCollectionGenericExtension() {
        let input = """
        extension BidirectionalCollection where Element == Foo {}
        """
        let output = """
        extension BidirectionalCollection<Foo> {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .genericExtensions, options: options, exclude: [.emptyExtensions])
    }

    func testUpdatesRandomAccessCollectionGenericExtension() {
        let input = """
        extension RandomAccessCollection where Element == Foo {}
        """
        let output = """
        extension RandomAccessCollection<Foo> {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .genericExtensions, options: options, exclude: [.emptyExtensions])
    }

    func testUpdatesMutableCollectionGenericExtension() {
        let input = """
        extension MutableCollection where Element == Foo {}
        """
        let output = """
        extension MutableCollection<Foo> {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .genericExtensions, options: options, exclude: [.emptyExtensions])
    }

    func testUpdatesClosedRangeGenericExtension() {
        let input = """
        extension ClosedRange where Bound == Int {}
        """
        let output = """
        extension ClosedRange<Int> {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .genericExtensions, options: options, exclude: [.emptyExtensions])
    }

    func testUpdatesRangeGenericExtension() {
        let input = """
        extension Range where Bound == Int {}
        """
        let output = """
        extension Range<Int> {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .genericExtensions, options: options, exclude: [.emptyExtensions])
    }

    func testUpdatesKeyValuePairsGenericExtension() {
        let input = """
        extension KeyValuePairs where Key == String, Value == Int {}
        """
        let output = """
        extension KeyValuePairs<String, Int> {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .genericExtensions, options: options, exclude: [.emptyExtensions])
    }

    func testUpdatesCollectionDifferenceGenericExtension() {
        let input = """
        extension CollectionDifference where ChangeElement == Foo {}
        """
        let output = """
        extension CollectionDifference<Foo> {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .genericExtensions, options: options, exclude: [.emptyExtensions])
    }
}
