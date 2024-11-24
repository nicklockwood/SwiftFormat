//
//  GenericExtensionsTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/18/22.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class GenericExtensionsTests: XCTestCase {
    func testUpdatesArrayGenericExtensionToAngleBracketSyntax() {
        let input = "extension Array where Element == Foo {}"
        let output = "extension Array<Foo> {}"

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .genericExtensions, options: options, exclude: [.typeSugar, .emptyExtensions])
    }

    func testUpdatesOptionalGenericExtensionToAngleBracketSyntax() {
        let input = "extension Optional where Wrapped == Foo {}"
        let output = "extension Optional<Foo> {}"

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .genericExtensions, options: options, exclude: [.typeSugar, .emptyExtensions])
    }

    func testUpdatesArrayGenericExtensionToAngleBracketSyntaxWithSelf() {
        let input = "extension Array where Self.Element == Foo {}"
        let output = "extension Array<Foo> {}"

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .genericExtensions, options: options, exclude: [.typeSugar, .emptyExtensions])
    }

    func testUpdatesArrayWithGenericElement() {
        let input = "extension Array where Element == Foo<Bar> {}"
        let output = "extension Array<Foo<Bar>> {}"

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .genericExtensions, options: options, exclude: [.typeSugar, .emptyExtensions])
    }

    func testUpdatesDictionaryGenericExtensionToAngleBracketSyntax() {
        let input = "extension Dictionary where Key == Foo, Value == Bar {}"
        let output = "extension Dictionary<Foo, Bar> {}"

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .genericExtensions, options: options, exclude: [.typeSugar, .emptyExtensions])
    }

    func testRequiresAllGenericTypesToBeProvided() {
        // No type provided for `Value`, so we can't use the angle bracket syntax
        let input = "extension Dictionary where Key == Foo {}"

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .genericExtensions, options: options, exclude: [.emptyExtensions])
    }

    func testHandlesNestedCollectionTypes() {
        let input = "extension Array where Element == [[Foo: Bar]] {}"
        let output = "extension Array<[[Foo: Bar]]> {}"

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .genericExtensions, options: options, exclude: [.typeSugar, .emptyExtensions])
    }

    func testDoesntUpdateIneligibleConstraints() {
        // This could potentially by `extension Optional<some Fooable>` in a future language version
        // but that syntax isn't implemented as of Swift 5.7
        let input = "extension Optional where Wrapped: Fooable {}"

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .genericExtensions, options: options, exclude: [.emptyExtensions])
    }

    func testPreservesOtherConstraintsInWhereClause() {
        let input = "extension Collection where Element == String, Index == Int {}"
        let output = "extension Collection<String> where Index == Int {}"

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
}
