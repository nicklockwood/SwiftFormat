//
//  TrailingCommasTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 8/22/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class TrailingCommasTests: XCTestCase {
    func testCommaAddedToSingleItem() {
        let input = """
        [
            foo
        ]
        """
        let output = """
        [
            foo,
        ]
        """
        testFormatting(for: input, output, rule: .trailingCommas)
    }

    func testCommaAddedToLastItem() {
        let input = """
        [
            foo,
            bar
        ]
        """
        let output = """
        [
            foo,
            bar,
        ]
        """
        testFormatting(for: input, output, rule: .trailingCommas)
    }

    func testCommaAddedToLastItemCollectionsOnly() {
        let input = """
        [
            foo,
            bar
        ]
        """
        let output = """
        [
            foo,
            bar,
        ]
        """
        let options = FormatOptions(trailingCommas: .collectionsOnly)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testCommaAddedToDictionary() {
        let input = """
        [
            foo: bar
        ]
        """
        let output = """
        [
            foo: bar,
        ]
        """
        testFormatting(for: input, output, rule: .trailingCommas)
    }

    func testCommaNotAddedToInlineArray() {
        let input = """
        [foo, bar]
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testCommaNotAddedToInlineDictionary() {
        let input = """
        [foo: bar]
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testCommaNotAddedToSubscript() {
        let input = """
        foo[bar]
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testCommaAddedBeforeComment() {
        let input = """
        [
            foo // comment
        ]
        """
        let output = """
        [
            foo, // comment
        ]
        """
        testFormatting(for: input, output, rule: .trailingCommas)
    }

    func testCommaNotAddedAfterComment() {
        let input = """
        [
            foo, // comment
        ]
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testCommaNotAddedInsideEmptyArrayLiteral() {
        let input = """
        foo = [
        ]
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testCommaNotAddedInsideEmptyDictionaryLiteral() {
        let input = """
        foo = [:
        ]
        """
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testTrailingCommaRemovedInInlineArray() {
        let input = """
        [foo,]
        """
        let output = """
        [foo]
        """
        testFormatting(for: input, output, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToSubscript() {
        let input = """
        foo[
            bar
        ]
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToSubscript2() {
        let input = """
        foo?[
            bar
        ]
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToSubscript3() {
        let input = """
        foo()[
            bar
        ]
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToSubscriptInsideArrayLiteral() {
        let input = """
        let array = [
            foo
                .bar[
                    0
                ]
                .baz,
        ]
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaAddedToArrayLiteralInsideTuple() {
        let input = """
        let arrays = ([
            foo
        ], [
            bar
        ])
        """
        let output = """
        let arrays = ([
            foo,
        ], [
            bar,
        ])
        """
        testFormatting(for: input, output, rule: .trailingCommas)
    }

    func testNoTrailingCommaAddedToArrayLiteralInsideTuple() {
        let input = """
        let arrays = ([
            Int
        ], [
            Int
        ]).self
        """
        testFormatting(for: input, rule: .trailingCommas, exclude: [.propertyTypes])
    }

    func testTrailingCommaNotAddedToTypeDeclaration() {
        let input = """
        var foo: [
            Int:
                String
        ]
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToTypeDeclaration2() {
        let input = """
        func foo(bar: [
            Int:
                String
        ])
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToTypeDeclaration3() {
        let input = """
        func foo() -> [
            String: String
        ]
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToTypeDeclaration4() {
        let input = """
        func foo() -> [String: [
            String: Int
        ]]
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToTypeDeclaration5() {
        let input = """
        let foo = [String: [
            String: Int
        ]]()
        """
        testFormatting(for: input, rule: .trailingCommas, exclude: [.propertyTypes])
    }

    func testTrailingCommaNotAddedToTypeDeclaration6() {
        let input = """
        let foo = [String: [
            (Foo<[
                String
            ]>, [
                Int
            ])
        ]]()
        """
        testFormatting(for: input, rule: .trailingCommas, exclude: [.propertyTypes])
    }

    func testTrailingCommaNotAddedToTypeDeclaration7() {
        let input = """
        func foo() -> Foo<[String: [
            String: Int
        ]]>
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToTypeDeclaration8() {
        let input = """
        extension Foo {
            var bar: [
                Int
            ] {
                fatalError()
            }
        }
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToTypealias() {
        let input = """
        typealias Foo = [
            Int
        ]
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToCaptureList() {
        let input = """
        let foo = { [
            self
        ] in }
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToCaptureListWithComment() {
        let input = """
        let foo = { [
            self // captures self
        ] in }
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToCaptureListWithMainActor() {
        let input = """
        let closure = { @MainActor [
            foo = state.foo,
            baz = state.baz
        ] _ in }
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    func testTrailingCommaNotAddedToArrayExtension() {
        let input = """
        extension [
            Int
        ] {
            func foo() {}
        }
        """
        testFormatting(for: input, rule: .trailingCommas)
    }

    // trailingCommas = false

    func testCommaNotAddedToLastItem() {
        let input = """
        [
            foo,
            bar
        ]
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testCommaRemovedFromLastItem() {
        let input = """
        [
            foo,
            bar,
        ]
        """
        let output = """
        [
            foo,
            bar
        ]
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToFunctionParameters() {
        let input = """
        struct Foo {
            func foo(
                bar: Int,
                baaz: Int
            ) -> Int {
                bar + baaz
            }
        }
        """
        let output = """
        struct Foo {
            func foo(
                bar: Int,
                baaz: Int,
            ) -> Int {
                bar + baaz
            }
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromFunctionParametersOnUnsupportedSwiftVersion() {
        let input = """
        struct Foo {
            func foo(
                bar: Int,
                baaz: Int,
            ) -> Int {
                bar + baaz
            }
        }
        """
        let output = """
        struct Foo {
            func foo(
                bar: Int,
                baaz: Int
            ) -> Int {
                bar + baaz
            }
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.0")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToGenericFunctionParameters() {
        let input = """
        struct Foo {
            func foo<
                Bar,
                Baaz
            >(
                bar: Bar,
                baaz: Baaz
            ) -> Int {
                bar + baaz
            }
        }
        """
        let output = """
        struct Foo {
            func foo<
                Bar,
                Baaz,
            >(
                bar: Bar,
                baaz: Baaz,
            ) -> Int {
                bar + baaz
            }
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options, exclude: [.opaqueGenericParameters])
    }

    func testTrailingCommasNotAddedToFunctionParametersBeforeSwift6_1() {
        let input = """
        func foo(
            bar _: Int
        ) {}
        """
        let options = FormatOptions(trailingCommas: .always)
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromFunctionParameters() {
        let input = """
        func foo(
            bar _: Int,
        ) {}
        """
        let output = """
        func foo(
            bar _: Int
        ) {}
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromFunctionParametersWithParenOnSameLine_trailingCommasDisabled() {
        let input = """
        func foo(
            bar _: Int,
            baaz _: Int,)
        {}
        """
        let output = """
        func foo(
            bar _: Int,
            baaz _: Int)
        {}
        """
        let options = FormatOptions(trailingCommas: .never, closingParenPosition: .sameLine)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromFunctionParametersWithParenOnSameLine_trailingCommasEnabled() {
        let input = """
        func foo(
            bar _: Int,
            baaz _: Int,)
        {}
        """
        let output = """
        func foo(
            bar _: Int,
            baaz _: Int)
        {}
        """
        let options = FormatOptions(trailingCommas: .always, closingParenPosition: .sameLine)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToFunctionArguments() {
        let input = """
        foo(
            bar _: Int
        ) {}
        """
        let output = """
        foo(
            bar _: Int,
        ) {}
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromFunctionArguments() {
        let input = """
        foo(
            bar _: Int,
        ) {}
        """
        let output = """
        foo(
            bar _: Int
        ) {}
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToEnumCaseAssociatedValue() {
        let input = """
        enum Foo {
            case bar(
                baz: String
            )
        }
        """
        let output = """
        enum Foo {
            case bar(
                baz: String,
            )
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromEnumCaseAssociatedValue() {
        let input = """
        enum Foo {
            case bar(
                baz: String,
            )
        }
        """
        let output = """
        enum Foo {
            case bar(
                baz: String
            )
        }
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToInitializer() {
        let input = """
        let foo: Foo = .init(
            1
        )
        """
        let output = """
        let foo: Foo = .init(
            1,
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromInitializer() {
        let input = """
        let foo: Foo = .init(
            1,
        )
        """
        let output = """
        let foo: Foo = .init(
            1
        )
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToTuple() {
        let input = """
        var foo = (
            bar: 0,
            baz: 1
        )

        foo = (
            bar: 1,
            baz: 2
        )
        """
        let output = """
        var foo = (
            bar: 0,
            baz: 1,
        )

        foo = (
            bar: 1,
            baz: 2,
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToTupleReturnedFromFunction() {
        let input = """
        func foo() -> (bar: Int, baz: Int) {
            (
                bar: 0,
                baz: 1
            )
        }

        func bar() -> (bar: Int, baz: Int) {
            return (
                bar: 0,
                baz: 1
            )
        }
        """
        let output = """
        func foo() -> (bar: Int, baz: Int) {
            (
                bar: 0,
                baz: 1,
            )
        }

        func bar() -> (bar: Int, baz: Int) {
            return (
                bar: 0,
                baz: 1,
            )
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options, exclude: [.redundantReturn])
    }

    func testTrailingCommasAddedToTupleInFunctionCall() {
        let input = """
        foo(
            bar: bar,
            baaz: (
                quux: quux,
                foobar: foobar
            )
        )
        """

        let output = """
        foo(
            bar: bar,
            baaz: (
                quux: quux,
                foobar: foobar,
            ),
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options, exclude: [.redundantReturn])
    }

    func testTrailingCommasAddedToTupleInGenericInitCall() {
        let input = """
        let setModeSwizzle = Swizzle<AVAudioSession>(
            instance: instance,
            original: #selector(AVAudioSession.setMode(_:)),
            swizzled: #selector(AVAudioSession.swizzled_setMode(_:))
        )
        """

        let output = """
        let setModeSwizzle = Swizzle<AVAudioSession>(
            instance: instance,
            original: #selector(AVAudioSession.setMode(_:)),
            swizzled: #selector(AVAudioSession.swizzled_setMode(_:)),
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options, exclude: [.redundantReturn, .propertyTypes])
    }

    func testTrailingCommasAddedToParensAroundSingleValue() {
        let input = """
        let foo = (
            0
        )
        """
        let output = """
        let foo = (
            0,
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options, exclude: [.redundantParens])
    }

    func testTrailingCommasAddedToTupleWithNoArguments() {
        let input = """
        let foo = (
            0,
            1
        )
        """
        let output = """
        let foo = (
            0,
            1,
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromTuple() {
        let input = """
        let foo = (
            bar: 0,
            baz: 1,
        )
        """
        let output = """
        let foo = (
            bar: 0,
            baz: 1
        )
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasPreservedInTupleTypeInSwift6_1() {
        // Trailing commas are unexpectedly not supported in tuple types in Swift 6.1
        // https://github.com/swiftlang/swift/issues/81485
        let input = """
        let foo: (
            bar: String,
            quux: String // trailing comma not supported
        )
        """

        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasPreservedInTupleTypeInSwift6_1_multiElementLists() {
        // Trailing commas are unexpectedly not supported in tuple types in Swift 6.1
        // https://github.com/swiftlang/swift/issues/81485
        let input = """
        let foo: (
            bar: String,
            quux: String // trailing comma not supported
        )
        """

        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasPreservedInTupleTypeInArrayInSwift6_1() {
        // Trailing commas are unexpectedly not supported in tuple types in Swift 6.1
        // https://github.com/swiftlang/swift/issues/81485
        let input = """
        let foo: [[(
            bar: String,
            quux: String // trailing comma not supported
        )]]

        let foo = [[(
            bar: String,
            quux: String // trailing comma not supported
        )]]()
        """

        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options, exclude: [.propertyTypes])
    }

    func testTrailingCommasPreservedInTupleTypeInGenericBracketsInSwift6_1() {
        // Trailing commas are unexpectedly not supported in tuple types in Swift 6.1
        // https://github.com/swiftlang/swift/issues/81485
        let input = """
        let foo: Array<(
            bar: String,
            quux: String // trailing comma not supported
        )>

        let foo = Array<(
            bar: String,
            quux: String // trailing comma not supported
        )>()
        """

        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options, exclude: [.typeSugar, .propertyTypes])
    }

    func testPreservesTrailingCommaInTupleFunctionArgumentInSwift6_1_issue_2050() {
        let input = """
        func updateBackgroundMusic(
            inputs _: (
                isFullyVisible: Bool,
                currentLevel: LevelsService.Level?,
                isAudioEngineRunningInForeground: Bool,
                cameraMode: EnvironmentCameraMode // <--- trailing comma does not compile
            ),
        ) {}
        """

        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasPreservedInClosureTypeInSwift6_1() {
        // Trailing commas are unexpectedly not supported in closure types in Swift 6.1
        // https://github.com/swiftlang/swift/issues/81485
        let input = """
        let closure: (
            String,
            String // trailing comma not supported
        ) -> (
            bar: String,
            quux: String // trailing comma not supported
        )

        let closure: @Sendable (
            String,
            String // trailing comma not supported
        ) -> (
            bar: String,
            quux: String // trailing comma not supported
        )

        let closure: (
            String,
            String // trailing comma not supported
        ) async -> (
            bar: String,
            quux: String // trailing comma not supported
        )

        let closure: (
            String,
            String // trailing comma not supported
        ) async throws -> (
            bar: String,
            quux: String // trailing comma not supported
        )

        func foo(_: @escaping (
            String,
            String // trailing comma not supported
        ) -> Void) {}
        """

        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasPreservedInClosureTypeInSwift6_1_multiElementList() {
        // Trailing commas are unexpectedly not supported in closure types in Swift 6.1
        // https://github.com/swiftlang/swift/issues/81485
        let input = """
        let closure: (
            String,
            String // trailing comma not supported
        ) -> (
            bar: String,
            quux: String // trailing comma not supported
        )

        let closure: @Sendable (
            String // trailing comma not supported
        ) -> (
            bar: String,
            quux: String // trailing comma not supported
        )
        """

        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasPreservedInOptionalClosureTypeInSwift6_1() {
        let input = """
        public func requestLocationAuthorizationAndAccuracy(completion _: (
            (
                _ authorizationStatus: CLAuthorizationStatus?,
                _ accuracyAuthorization: CLAccuracyAuthorization?,
                _ error: LocationServiceError?
            ) -> Void
        )?) {}
        """

        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasPreservedInClosureTupleTypealiasesInSwift6_1() {
        let input = """
        public typealias StringToInt = (
            String
        ) -> Int

        public enum Toster {
            public typealias StringToInt = ((
                String
            ) -> Int)?
        }

        public typealias Tuple = (
            foo: String,
            bar: Int
        )

        public typealias OptionalTuple = (
            foo: String,
            bar: Int,
            baaz: Bool
        )?
        """

        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToReturnTuple() {
        let input = """
        func foo() -> (Int, Int) {
            let bar = 0
            let baz = 1

            return (
                bar,
                baz
            )
        }
        """
        let output = """
        func foo() -> (Int, Int) {
            let bar = 0
            let baz = 1

            return (
                bar,
                baz,
            )
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromReturnTuple() {
        let input = """
        func foo() -> (Int, Int) {
            let bar = 0
            let baz = 1

            return (
                bar,
                baz,
            )
        }
        """
        let output = """
        func foo() -> (Int, Int) {
            let bar = 0
            let baz = 1

            return (
                bar,
                baz
            )
        }
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToThrow() {
        let input = """
        enum FooError: Error {
            case bar
        }

        func baz() throws {
            throw (
                FooError.bar
            )
        }
        """
        let output = """
        enum FooError: Error {
            case bar
        }

        func baz() throws {
            throw (
                FooError.bar,
            )
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromThrow() {
        let input = """
        enum FooError: Error {
            case bar
        }

        func baz() throws {
            throw (
                FooError.bar,
            )
        }
        """
        let output = """
        enum FooError: Error {
            case bar
        }

        func baz() throws {
            throw (
                FooError.bar
            )
        }
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToSwitch() {
        let input = """
        let foo = (
            bar: 0,
            baz: 1
        )
        switch (
            foo.bar,
            foo.baz
        ) {
        case (
            0,
            1
        ): break
        default: break
        }
        """
        let output = """
        let foo = (
            bar: 0,
            baz: 1,
        )
        switch (
            foo.bar,
            foo.baz,
        ) {
        case (
            0,
            1,
        ): break
        default: break
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasNotAddedToTypeAnnotation() {
        let input = """
        let foo: (
            bar: Int,
            baz: Int
        )
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromCaseLet() {
        let input = """
        let foo = (0, 1)
        switch foo {
        case let (
            bar,
            baz,
        ): break
        }
        """
        let output = """
        let foo = (0, 1)
        switch foo {
        case let (
            bar,
            baz
        ): break
        }
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommaRemovedFromDestructuringLetTuple() {
        let input = """
        let (
            foo,
            bar,
        ) = (0, 1)
        """
        let output = """
        let (
            foo,
            bar
        ) = (0, 1)
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options, exclude: [.singlePropertyPerLine])
    }

    func testTrailingCommasNotAddedToEmptyParentheses() {
        let input = """
        let foo = (

        )
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, rule: .trailingCommas,
                       options: options, exclude: [
                           .blankLinesAtEndOfScope,
                           .blankLinesAtStartOfScope,
                       ])
    }

    func testTrailingCommasRemovedFromStringInterpolation() {
        let input = """
        let foo = \"""
        Foo: \\(
            1,
            2,
        )
        \"""
        """
        let output = """
        let foo = \"""
        Foo: \\(
            1,
            2
        )
        \"""
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToAttribute() {
        let input = """
        @Foo(
            "bar",
            "baz"
        )
        struct Qux {}
        """
        let output = """
        @Foo(
            "bar",
            "baz",
        )
        struct Qux {}
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasNotAddedToBuiltInAttributesInSwift6_1() {
        // Built-in attributes unexpectedly don't support trailing commas in Swift 6.1.
        // Property wrappers and macros are supported properly.
        // https://github.com/swiftlang/swift/issues/81475
        let input = """
        @available(
            *,
            deprecated,
            renamed: "bar"
        )
        func foo() {}

        @backDeployed(
            before: iOS 17 // trailing comma not allowed
        )
        public func foo() {}

        @objc(
            custom_objc_name
        )
        class MyClass: NSObject()

        @freestanding(
            declaration,
            names: named(CodingKeys)
        )
        macro FreestandingMacro() = #externalMacro(module: "Macros", type: "")

        @attached(
            extension,
            names: arbitrary
        )
        macro AttachedMacro() = #externalMacro(module: "Macros", type: "")

        @_originallyDefinedIn(
            module: "Foo",
            macOS 10.0
        )
        extension CoreFoundation.CGFloat: Swift.SignedNumeric {}
        """

        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasNotAddedToBuiltInAttributesInSwift6_1_multiElementList() {
        // Built-in attributes unexpectedly don't support trailing commas in Swift 6.1.
        // Property wrappers and macros are supported properly.
        // https://github.com/swiftlang/swift/issues/81475
        let input = """
        @available(
            *,
            deprecated,
            renamed: "bar"
        )
        func foo() {}

        @objc(
            custom_objc_name
        )
        class MyClass: NSObject()
        """

        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromAttribute() {
        let input = """
        @Foo(
            "bar",
            "baz",
        )
        struct Qux {}
        """
        let output = """
        @Foo(
            "bar",
            "baz"
        )
        struct Qux {}
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToMacro() {
        let input = """
        #foo(
            "bar",
            "baz"
        )
        """
        let output = """
        #foo(
            "bar",
            "baz",
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromMacro() {
        let input = """
        #foo(
            "bar",
            "baz",
        )
        """
        let output = """
        #foo(
            "bar",
            "baz"
        )
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToGenericList() {
        let input = """
        struct S<
            T1,
            T2,
            T3
        > {}

        typealias T<
            T1,
            T2
        > = S<T1, T2, Bool>

        func foo<
            T1,
            T2,
        >() -> (T1, T2) {}
        """
        let output = """
        struct S<
            T1,
            T2,
            T3,
        > {}

        typealias T<
            T1,
            T2,
        > = S<T1, T2, Bool>

        func foo<
            T1,
            T2,
        >() -> (T1, T2) {}
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasNotAddedToGenericTypesInSwift6_1() {
        // Trailing commas are not supported in types in Swift 6.1
        // https://github.com/swiftlang/swift/issues/81474
        let input = """
        public final class TestThing: GenericThing<
            Test1,
            Test2,
            Test3
        > {}

        func foo(_: GenericThing<
            Test1,
            Test2,
            Test3
        >) {}

        typealias T<
            T1,
            T2,
        > = S<
            T1,
            T2,
            Bool
        >

        extension Dictionary<
            String,
            Any
        > {}

        protocol MyProtocolWithAssociatedTypes<
            Foo,
            Bar
        > {}
        """

        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options, exclude: [.emptyExtensions, .typeSugar])
    }

    func testTrailingCommasRemovedFromGenericList() {
        let input = """
        struct S<
            T1,
            T2,
            T3,
        > {}
        """
        let output = """
        struct S<
            T1,
            T2,
            T3
        > {}
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromSingleLineGenericList() {
        let input = """
        struct S<T1, T2, T3,> {}
        """
        let output = """
        struct S<T1, T2, T3> {}
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToCaptureList() {
        let input = """
        { [
            capturedValue1,
            capturedValue2
        ] in
        }
        """
        let output = """
        { [
            capturedValue1,
            capturedValue2,
        ] in
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromSingleElementCaptureList() {
        let input = """
        { [
            capturedValue1,
        ] in
        }
        """
        let output = """
        { [
            capturedValue1
        ] in
        }
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromCaptureList() {
        let input = """
        { [
            capturedValue1,
            capturedValue2,
        ] in
        }
        """
        let output = """
        { [
            capturedValue1,
            capturedValue2
        ] in
        }
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromSingleLineCaptureList() {
        let input = """
        { [capturedValue1, capturedValue2,] in
            print(capturedValue1, capturedValue2)
        }
        """
        let output = """
        { [capturedValue1, capturedValue2] in
            print(capturedValue1, capturedValue2)
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToSubscript() {
        let input = """
        let value = m[
            x,
            y
        ]
        """
        let output = """
        let value = m[
            x,
            y,
        ]
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemoveFromSubscriptWhenCollectionsOnly() {
        let input = """
        let value = m[
            x,
            y,
        ]
        """
        let output = """
        let value = m[
            x,
            y
        ]
        """
        let options = FormatOptions(trailingCommas: .collectionsOnly, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromSubscript() {
        let input = """
        let value = m[
            x,
            y,
        ]
        """
        let output = """
        let value = m[
            x,
            y
        ]
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromSingleLineSubscript() {
        let input = """
        let value = m[x, y,]
        """
        let output = """
        let value = m[x, y]
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testAddingTrailingCommaDoesntConflictWithOpaqueGenericParametersRule() {
        let input = """
        private func foo<
            Foo: Bar,
            Bar: Baaz
        >(a: Foo, b: Foo)
            where Foo == Bar
        {
            print(a, b)
        }
        """

        let output = """
        private func foo<
            Foo: Bar,
            Bar: Baaz,
        >(a: Foo, b: Foo)
            where Foo == Bar
        {
            print(a, b)
        }
        """

        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testSingleLineArrayWithMultipleElements() {
        let input = """
        for file in files where
            file != "build" && !file.hasPrefix(".") && ![
                ".build", ".app", ".framework", ".xcodeproj", ".xcassets",
            ].contains(where: { file.hasSuffix($0) }) {}
        """

        let options = FormatOptions(trailingCommas: .always)
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testSingleLineArrayWithMultipleElementsFollowingNotOperator() {
        let input = """
        for file in files where
            file != "build" && !file.hasPrefix(".") && ![
                ".build", ".app", ".framework", ".xcodeproj", ".xcassets",
            ].contains(where: { file.hasSuffix($0) }) {}
        """

        let options = FormatOptions(trailingCommas: .always)
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testSingleLineArrayWithMultipleElementsFollowingForceTry() {
        let input = """
        let foo = try! [
            ".build", ".app", ".framework", ".xcodeproj", ".xcassets",
        ].throwingOperation()

        let bar = try? [
            ".build", ".app", ".framework", ".xcodeproj", ".xcassets",
        ].throwingOperation()
        """

        let options = FormatOptions(trailingCommas: .always)
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testCollectionsOnlyAddsCollectionCommasAndRemovesNonCollectionCommas() {
        let input = """
        let array = [
            1,
            2
        ]

        func foo(
            a: Int,
            b: Int,
        ) {
            print(a, b)
        }
        """
        let output = """
        let array = [
            1,
            2,
        ]

        func foo(
            a: Int,
            b: Int
        ) {
            print(a, b)
        }
        """
        let options = FormatOptions(trailingCommas: .collectionsOnly, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasNotRemovedFromInitParametersWithAlwaysOption() {
        let input = """
        public init(
            parameter: Parameter,
        ) {
            // test
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options, exclude: [.unusedArguments])
    }

    func testTrailingCommasAddedToInitParametersWithAlwaysOption() {
        let input = """
        public init(
            parameter: Parameter
        ) {
            // test
        }
        """
        let output = """
        public init(
            parameter: Parameter,
        ) {
            // test
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options, exclude: [.unusedArguments])
    }

    // MARK: - Multi-element lists tests

    func testMultiElementListsAddsCommaToMultiElementArray() {
        let input = """
        let array = [
            1,
            2
        ]
        """
        let output = """
        let array = [
            1,
            2,
        ]
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testMultiElementListsDoesNotAddCommaToSingleElementArray() {
        let input = """
        let array = [
            1
        ]
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testMultiElementListsAddsCommaToMultiElementFunction() {
        let input = """
        func foo(
            a: Int,
            b: Int
        ) {
            print(a, b)
        }
        """
        let output = """
        func foo(
            a: Int,
            b: Int,
        ) {
            print(a, b)
        }
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testMultiElementListsDoesNotAddCommaToSingleElementFunction() {
        let input = """
        func foo(
            a: Int
        ) {
            print(a)
        }

        init(
            a: Int
        ) {
            print(a)
        }
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testMultiElementListsAddsCommaToMultiElementFunctionCall() {
        let input = """
        foo(
            a: 1,
            b: 2
        )
        """
        let output = """
        foo(
            a: 1,
            b: 2,
        )
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testMultiElementListsDoesNotAddCommaToSingleElementFunctionCall() {
        let input = """
        foo(
            a: 1
        )
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testMultiElementListsAddsCommaToMultiElementGenericList() {
        let input = """
        struct Foo<
            T,
            U
        > {}
        """
        let output = """
        struct Foo<
            T,
            U,
        > {}
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testMultiElementListsDoesNotAddCommaToSingleElementGenericList() {
        let input = """
        struct Foo<
            T
        > {}
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testMultiElementListsRemovesCommaFromSingleElementArray() {
        let input = """
        let array = [
            1,
        ]
        """
        let output = """
        let array = [
            1
        ]
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testMultiElementListsRemovesCommaFromSingleElementFunction() {
        let input = """
        func foo(
            a: Int,
        ) {
            print(a)
        }
        """
        let output = """
        func foo(
            a: Int
        ) {
            print(a)
        }
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testMultiElementListsRemovesCommaFromSingleElementInit() {
        let input = """
        public init(
            a: Int,
        ) {
            print(a)
        }
        """
        let output = """
        public init(
            a: Int
        ) {
            print(a)
        }
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testMultiElementListsAddCommaToInit() {
        let input = """
        public init(
            a: Int,
            b: Int
        ) {
            print(a, b)
        }
        """
        let output = """
        public init(
            a: Int,
            b: Int,
        ) {
            print(a, b)
        }
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommaNotRemovedFromTupleAndClosureTypesSwift6_1() {
        let input = """
        let foo: (
            bar: String,
            quux: String,
        )

        let bar: (
            bar: String,
            baaz: String,
        ) -> Void

        public func testClosureArgumentInTuple() {
            _ = object.methodWithTupleArgument((
                closureArgument: { capturedObject in
                    _ = capturedObject
                },
            ))
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testTrailingCommaNotAddedToTupleAndClosureTypesSwift6_1() {
        let input = """
        let foo: (
            bar: String,
            quux: String
        )

        let bar: (
            bar: String,
            baaz: String
        ) -> Void

        public func testClosureArgumentInTuple() {
            _ = object.methodWithTupleArgument((
                closureArgument: { capturedObject in
                    _ = capturedObject
                },
            ))
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testMultiElementListsTrailingCommaNotRemovedFromClosureTypeSwift6_1() {
        let input = """
        let foo: (
            bar: String,
        ) -> Void

        let foo: (
            bar: String,
            baaz: String,
        ) -> Void
        """
        let output = """
        let foo: (
            bar: String
        ) -> Void

        let foo: (
            bar: String,
            baaz: String,
        ) -> Void
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testMultiElementListsTrailingCommaNotAddedToTupleAndClosureTypesSwift6_1() {
        let input = """
        let bar: (
            bar: String,
            baaz: String
        )

        let bar: (
            bar: String,
            baaz: String
        ) -> Void
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToOptionalClosureCall() {
        let input = """
        myClosure?(
            foo: 5,
            bar: 10
        )
        """
        let output = """
        myClosure?(
            foo: 5,
            bar: 10,
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromOptionalClosureCall() {
        let input = """
        myClosure!(
            foo: 5,
            bar: 10,
        )
        """
        let output = """
        myClosure!(
            foo: 5,
            bar: 10
        )
        """
        let options = FormatOptions(trailingCommas: .never)
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToOptionalClosureCallSingleParameter() {
        let input = """
        myClosure?(
            foo: 5
        )
        """
        let output = """
        myClosure?(
            foo: 5,
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasMultiElementListsOptionalClosureCall() {
        let input = """
        myClosure?(
            foo: 5,
        )

        otherClosure?(
            foo: 5,
            bar: 10
        )
        """
        let output = """
        myClosure?(
            foo: 5
        )

        otherClosure?(
            foo: 5,
            bar: 10,
        )
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasInTupleTypeCastNotRemovedSwift6_1() {
        // Unexpectedly not supported in Swift 6.1
        let input = """
        let foo = bar as? (
            Foo,
            Bar
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testIssue2142() {
        let input = """
        public func bindExitButton<T: Presenter>(
            action: T.Action,
            withIdentifier identifier: UIAction.Identifier? = nil,
            on controlEvents: UIControl.Event = .primaryActionTriggered,
            to presenter: T,
        ) {
            _ = action
            _ = identifier
            _ = controlEvents
            _ = presenter
        }

        let setModeSwizzle = Swizzle<AVAudioSession>(
            instance: instance,
            original: #selector(AVAudioSession.setMode(_:)),
            swizzled: #selector(AVAudioSession.swizzled_setMode(_:)),
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options, exclude: [.propertyTypes])
    }

    func testIssue2143() {
        let input = """
        public func testClosureArgumentInTuple() {
            _ = object.methodWithTupleArgument((
                closureArgument: { capturedObject in
                    _ = capturedObject
                },
            ))
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToFunctionParametersSwift6_2() {
        let input = """
        struct Foo {
            func foo(
                bar: Int,
                baaz: Int
            ) -> Int {
                bar + baaz
            }
        }
        """
        let output = """
        struct Foo {
            func foo(
                bar: Int,
                baaz: Int,
            ) -> Int {
                bar + baaz
            }
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToGenericFunctionParametersSwift6_2() {
        let input = """
        struct Foo {
            func foo<
                Bar,
                Baaz
            >(
                bar: Bar,
                baaz: Baaz
            ) -> Int {
                bar + baaz
            }
        }
        """
        let output = """
        struct Foo {
            func foo<
                Bar,
                Baaz,
            >(
                bar: Bar,
                baaz: Baaz,
            ) -> Int {
                bar + baaz
            }
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options, exclude: [.opaqueGenericParameters])
    }

    func testTrailingCommasAddedToFunctionArgumentsSwift6_2() {
        let input = """
        foo(
            bar _: Int
        ) {}
        """
        let output = """
        foo(
            bar _: Int,
        ) {}
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToEnumCaseAssociatedValueSwift6_2() {
        let input = """
        enum Foo {
            case bar(
                baz: String
            )
        }
        """
        let output = """
        enum Foo {
            case bar(
                baz: String,
            )
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToInitializerSwift6_2() {
        let input = """
        let foo: Foo = .init(
            1
        )
        """
        let output = """
        let foo: Foo = .init(
            1,
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToTupleSwift6_2() {
        let input = """
        var foo = (
            bar: 0,
            baz: 1
        )

        foo = (
            bar: 1,
            baz: 2
        )
        """
        let output = """
        var foo = (
            bar: 0,
            baz: 1,
        )

        foo = (
            bar: 1,
            baz: 2,
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToTupleReturnedFromFunctionSwift6_2() {
        let input = """
        func foo() -> (bar: Int, baz: Int) {
            (
                bar: 0,
                baz: 1
            )
        }

        func bar() -> (bar: Int, baz: Int) {
            return (
                bar: 0,
                baz: 1
            )
        }
        """
        let output = """
        func foo() -> (bar: Int, baz: Int) {
            (
                bar: 0,
                baz: 1,
            )
        }

        func bar() -> (bar: Int, baz: Int) {
            return (
                bar: 0,
                baz: 1,
            )
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options, exclude: [.redundantReturn])
    }

    func testTrailingCommasAddedToTupleInFunctionCallSwift6_2() {
        let input = """
        foo(
            bar: bar,
            baaz: (
                quux: quux,
                foobar: foobar
            )
        )
        """

        let output = """
        foo(
            bar: bar,
            baaz: (
                quux: quux,
                foobar: foobar,
            ),
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options, exclude: [.redundantReturn])
    }

    func testTrailingCommasAddedToTupleInGenericInitCallSwift6_2() {
        let input = """
        let setModeSwizzle = Swizzle<AVAudioSession>(
            instance: instance,
            original: #selector(AVAudioSession.setMode(_:)),
            swizzled: #selector(AVAudioSession.swizzled_setMode(_:))
        )
        """

        let output = """
        let setModeSwizzle = Swizzle<AVAudioSession>(
            instance: instance,
            original: #selector(AVAudioSession.setMode(_:)),
            swizzled: #selector(AVAudioSession.swizzled_setMode(_:)),
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options, exclude: [.redundantReturn, .propertyTypes])
    }

    func testTrailingCommasAddedToParensAroundSingleValueSwift6_2() {
        let input = """
        let foo = (
            0
        )
        """

        let output = """
        let foo = (
            0,
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options, exclude: [.redundantParens])
    }

    func testTrailingCommasAddedToTupleWithNoArgumentsSwift6_2() {
        let input = """
        let foo = (
            0,
            1
        )
        """
        let output = """
        let foo = (
            0,
            1,
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToTupleTypesInSwift6_2() {
        // Trailing commas are now supported in tuple types in Swift 6.2
        let input = """
        let foo: (
            bar: String,
            quux: String
        )
        """
        let output = """
        let foo: (
            bar: String,
            quux: String,
        )
        """

        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToTupleTypesInSwift6_2_multiElementLists() {
        // Trailing commas are now supported in tuple types in Swift 6.2
        let input = """
        let foo: (
            bar: String,
            quux: String
        )
        """
        let output = """
        let foo: (
            bar: String,
            quux: String,
        )
        """

        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToTupleTypeInArrayInSwift6_2() {
        // Trailing commas are now supported in tuple types in Swift 6.2
        let input = """
        let foo: [[(
            bar: String,
            quux: String
        )]]

        let foo = [[(
            bar: String,
            quux: String
        )]]()
        """
        let output = """
        let foo: [[(
            bar: String,
            quux: String,
        )]]

        let foo = [[(
            bar: String,
            quux: String,
        )]]()
        """

        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options, exclude: [.propertyTypes])
    }

    func testTrailingCommasAddedToTupleTypeInGenericBracketsInSwift6_2() {
        // Trailing commas are now supported in tuple types in Swift 6.2
        let input = """
        let foo: Array<(
            bar: String,
            quux: String
        )>

        let foo = Array<(
            bar: String,
            quux: String
        )>()
        """
        let output = """
        let foo: Array<(
            bar: String,
            quux: String,
        )>

        let foo = Array<(
            bar: String,
            quux: String,
        )>()
        """

        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options, exclude: [.typeSugar, .propertyTypes])
    }

    func testTrailingCommasAddedToTupleFunctionArgumentInSwift6_2() {
        let input = """
        func updateBackgroundMusic(
            inputs _: (
                isFullyVisible: Bool,
                currentLevel: LevelsService.Level?,
                isAudioEngineRunningInForeground: Bool,
                cameraMode: EnvironmentCameraMode
            ),
        ) {}
        """
        let output = """
        func updateBackgroundMusic(
            inputs _: (
                isFullyVisible: Bool,
                currentLevel: LevelsService.Level?,
                isAudioEngineRunningInForeground: Bool,
                cameraMode: EnvironmentCameraMode,
            ),
        ) {}
        """

        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToClosureTypeInSwift6_2() {
        // Trailing commas are now supported in closure types in Swift 6.2
        let input = """
        let closure: (
            String,
            String
        ) -> (
            bar: String,
            quux: String
        )

        let closure: @Sendable (
            String,
            String
        ) -> (
            bar: String,
            quux: String
        )

        let closure: (
            String,
            String
        ) async -> (
            bar: String,
            quux: String
        )

        let closure: (
            String,
            String
        ) async throws -> (
            bar: String,
            quux: String
        )

        func foo(_: @escaping (
            String,
            String
        ) -> Void) {}
        """
        let output = """
        let closure: (
            String,
            String,
        ) -> (
            bar: String,
            quux: String,
        )

        let closure: @Sendable (
            String,
            String,
        ) -> (
            bar: String,
            quux: String,
        )

        let closure: (
            String,
            String,
        ) async -> (
            bar: String,
            quux: String,
        )

        let closure: (
            String,
            String,
        ) async throws -> (
            bar: String,
            quux: String,
        )

        func foo(_: @escaping (
            String,
            String,
        ) -> Void) {}
        """

        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToClosureTypeInSwift6_2_multiElementList() {
        // Trailing commas are now supported in closure types in Swift 6.2
        let input = """
        let closure: (
            String,
            String
        ) -> (
            bar: String,
            quux: String
        )

        let closure: @Sendable (
            String
        ) -> (
            bar: String,
            quux: String
        )
        """
        let output = """
        let closure: (
            String,
            String,
        ) -> (
            bar: String,
            quux: String,
        )

        let closure: @Sendable (
            String
        ) -> (
            bar: String,
            quux: String,
        )
        """

        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToOptionalClosureTypeInSwift6_2() {
        let input = """
        public func requestLocationAuthorizationAndAccuracy(completion _: (
            (
                _ authorizationStatus: CLAuthorizationStatus?,
                _ accuracyAuthorization: CLAccuracyAuthorization?,
                _ error: LocationServiceError?
            ) -> Void
        )?) {}
        """
        let output = """
        public func requestLocationAuthorizationAndAccuracy(completion _: (
            (
                _ authorizationStatus: CLAuthorizationStatus?,
                _ accuracyAuthorization: CLAccuracyAuthorization?,
                _ error: LocationServiceError?,
            ) -> Void
        )?) {}
        """

        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToClosureTupleTypealiasesInSwift6_2() {
        let input = """
        public typealias StringToInt = (
            String
        ) -> Int

        public enum Toster {
            public typealias StringToInt = ((
                String
            ) -> Int)?
        }

        public typealias Tuple = (
            foo: String,
            bar: Int
        )

        public typealias OptionalTuple = (
            foo: String,
            bar: Int,
            baaz: Bool
        )?
        """
        let output = """
        public typealias StringToInt = (
            String,
        ) -> Int

        public enum Toster {
            public typealias StringToInt = ((
                String,
            ) -> Int)?
        }

        public typealias Tuple = (
            foo: String,
            bar: Int,
        )

        public typealias OptionalTuple = (
            foo: String,
            bar: Int,
            baaz: Bool,
        )?
        """

        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToReturnTupleSwift6_2() {
        let input = """
        func foo() -> (Int, Int) {
            let bar = 0
            let baz = 1

            return (
                bar,
                baz
            )
        }
        """
        let output = """
        func foo() -> (Int, Int) {
            let bar = 0
            let baz = 1

            return (
                bar,
                baz,
            )
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToThrowSwift6_2() {
        let input = """
        enum FooError: Error {
            case bar
        }

        func baz() throws {
            throw (
                FooError.bar
            )
        }
        """

        let output = """
        enum FooError: Error {
            case bar
        }

        func baz() throws {
            throw (
                FooError.bar,
            )
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToSwitchSwift6_2() {
        let input = """
        let foo = (
            bar: 0,
            baz: 1
        )
        switch (
            foo.bar,
            foo.baz
        ) {
        case (
            0,
            1
        ): break
        default: break
        }
        """
        let output = """
        let foo = (
            bar: 0,
            baz: 1,
        )
        switch (
            foo.bar,
            foo.baz,
        ) {
        case (
            0,
            1,
        ): break
        default: break
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToAttributeSwift6_2() {
        let input = """
        @Foo(
            "bar",
            "baz"
        )
        struct Qux {}
        """
        let output = """
        @Foo(
            "bar",
            "baz",
        )
        struct Qux {}
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasNotAddedToBuiltInAttributesInSwift6_2() {
        let input = """
        @available(
            *,
            deprecated,
            renamed: "bar"
        )
        func foo() {}

        @backDeployed(
            before: iOS 17
        )
        public func foo() {}

        @objc(
            custom_objc_name
        )
        class MyClass: NSObject()

        @freestanding(
            declaration,
            names: named(CodingKeys)
        )
        macro FreestandingMacro() = #externalMacro(module: "Macros", type: "")

        @attached(
            extension,
            names: arbitrary
        )
        macro AttachedMacro() = #externalMacro(module: "Macros", type: "")

        @_originallyDefinedIn(
            module: "Foo",
            macOS 10.0
        )
        extension CoreFoundation.CGFloat: Swift.SignedNumeric {}
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToMacroSwift6_2() {
        let input = """
        #foo(
            "bar",
            "baz"
        )
        """
        let output = """
        #foo(
            "bar",
            "baz",
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToGenericListSwift6_2() {
        let input = """
        struct S<
            T1,
            T2,
            T3
        > {}

        typealias T<
            T1,
            T2
        > = S<T1, T2, Bool>

        func foo<
            T1,
            T2,
        >() -> (T1, T2) {}
        """
        let output = """
        struct S<
            T1,
            T2,
            T3,
        > {}

        typealias T<
            T1,
            T2,
        > = S<T1, T2, Bool>

        func foo<
            T1,
            T2,
        >() -> (T1, T2) {}
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToGenericTypesInSwift6_2() {
        // Trailing commas are now supported in generic types in Swift 6.2
        let input = """
        public final class TestThing: GenericThing<
            Test1,
            Test2,
            Test3
        > {}

        func foo(_: GenericThing<
            Test1,
            Test2,
            Test3
        >) {}

        typealias T<
            T1,
            T2,
        > = S<
            T1,
            T2,
            Bool
        >

        extension Dictionary<
            String,
            Any
        > {}

        protocol MyProtocolWithAssociatedTypes<
            Foo,
            Bar
        > {}
        """
        let output = """
        public final class TestThing: GenericThing<
            Test1,
            Test2,
            Test3,
        > {}

        func foo(_: GenericThing<
            Test1,
            Test2,
            Test3,
        >) {}

        typealias T<
            T1,
            T2,
        > = S<
            T1,
            T2,
            Bool,
        >

        extension Dictionary<
            String,
            Any,
        > {}

        protocol MyProtocolWithAssociatedTypes<
            Foo,
            Bar,
        > {}
        """

        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options, exclude: [.emptyExtensions, .typeSugar])
    }

    func testTrailingCommasRemovedFromSingleLineGenericListSwift6_2() {
        let input = """
        struct S<T1, T2, T3,> {}
        """
        let output = """
        struct S<T1, T2, T3> {}
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToCaptureListSwift6_2() {
        let input = """
        { [
            capturedValue1,
            capturedValue2
        ] in
        }
        """
        let output = """
        { [
            capturedValue1,
            capturedValue2,
        ] in
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromSingleElementCaptureListSwift6_2() {
        let input = """
        { [
            capturedValue1,
        ] in
        }
        """
        let output = """
        { [
            capturedValue1
        ] in
        }
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromSingleLineCaptureListSwift6_2() {
        let input = """
        { [capturedValue1, capturedValue2,] in
            print(capturedValue1, capturedValue2)
        }
        """
        let output = """
        { [capturedValue1, capturedValue2] in
            print(capturedValue1, capturedValue2)
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToSubscriptSwift6_2() {
        let input = """
        let value = m[
            x,
            y
        ]
        """
        let output = """
        let value = m[
            x,
            y,
        ]
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemoveFromSubscriptWhenCollectionsOnlySwift6_2() {
        let input = """
        let value = m[
            x,
            y,
        ]
        """
        let output = """
        let value = m[
            x,
            y
        ]
        """
        let options = FormatOptions(trailingCommas: .collectionsOnly, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasRemovedFromSingleLineSubscriptSwift6_2() {
        let input = """
        let value = m[x, y,]
        """
        let output = """
        let value = m[x, y]
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testAddingTrailingCommaDoesntConflictWithOpaqueGenericParametersRuleSwift6_2() {
        let input = """
        private func foo<
            Foo: Bar,
            Bar: Baaz
        >(a: Foo, b: Foo)
            where Foo == Bar
        {
            print(a, b)
        }
        """

        let output = """
        private func foo<
            Foo: Bar,
            Bar: Baaz,
        >(a: Foo, b: Foo)
            where Foo == Bar
        {
            print(a, b)
        }
        """

        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testCollectionsOnlyAddsCollectionCommasAndRemovesNonCollectionCommasSwift6_2() {
        let input = """
        let array = [
            1,
            2
        ]

        func foo(
            a: Int,
            b: Int,
        ) {
            print(a, b)
        }
        """
        let output = """
        let array = [
            1,
            2,
        ]

        func foo(
            a: Int,
            b: Int
        ) {
            print(a, b)
        }
        """
        let options = FormatOptions(trailingCommas: .collectionsOnly, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasNotRemovedFromInitParametersWithAlwaysOptionSwift6_2() {
        let input = """
        public init(
            parameter: Parameter,
        ) {
            // test
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, rule: .trailingCommas, options: options, exclude: [.unusedArguments])
    }

    func testTrailingCommasAddedToInitParametersWithAlwaysOptionSwift6_2() {
        let input = """
        public init(
            parameter: Parameter
        ) {
            // test
        }
        """
        let output = """
        public init(
            parameter: Parameter,
        ) {
            // test
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options, exclude: [.unusedArguments])
    }

    func testMultiElementListsAddsCommaToMultiElementArraySwift6_2() {
        let input = """
        let array = [
            1,
            2
        ]
        """
        let output = """
        let array = [
            1,
            2,
        ]
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testMultiElementListsDoesNotAddCommaToSingleElementArraySwift6_2() {
        let input = """
        let array = [
            1
        ]
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testMultiElementListsAddsCommaToMultiElementFunctionSwift6_2() {
        let input = """
        func foo(
            a: Int,
            b: Int
        ) {
            print(a, b)
        }
        """
        let output = """
        func foo(
            a: Int,
            b: Int,
        ) {
            print(a, b)
        }
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testMultiElementListsDoesNotAddCommaToSingleElementFunctionSwift6_2() {
        let input = """
        func foo(
            a: Int
        ) {
            print(a)
        }

        init(
            a: Int
        ) {
            print(a)
        }
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testMultiElementListsAddsCommaToMultiElementFunctionCallSwift6_2() {
        let input = """
        foo(
            a: 1,
            b: 2
        )
        """
        let output = """
        foo(
            a: 1,
            b: 2,
        )
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testMultiElementListsDoesNotAddCommaToSingleElementFunctionCallSwift6_2() {
        let input = """
        foo(
            a: 1
        )
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testMultiElementListsAddsCommaToMultiElementGenericListSwift6_2() {
        let input = """
        struct Foo<
            T,
            U
        > {}
        """
        let output = """
        struct Foo<
            T,
            U,
        > {}
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testMultiElementListsDoesNotAddCommaToSingleElementGenericListSwift6_2() {
        let input = """
        struct Foo<
            T
        > {}
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }

    func testMultiElementListsRemovesCommaFromSingleElementArraySwift6_2() {
        let input = """
        let array = [
            1,
        ]
        """
        let output = """
        let array = [
            1
        ]
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testMultiElementListsRemovesCommaFromSingleElementFunctionSwift6_2() {
        let input = """
        func foo(
            a: Int,
        ) {
            print(a)
        }
        """
        let output = """
        func foo(
            a: Int
        ) {
            print(a)
        }
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testMultiElementListsRemovesCommaFromSingleElementInitSwift6_2() {
        let input = """
        public init(
            a: Int,
        ) {
            print(a)
        }
        """
        let output = """
        public init(
            a: Int
        ) {
            print(a)
        }
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testMultiElementListsAddCommaToInitSwift6_2() {
        let input = """
        public init(
            a: Int,
            b: Int
        ) {
            print(a, b)
        }
        """
        let output = """
        public init(
            a: Int,
            b: Int,
        ) {
            print(a, b)
        }
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommaAddedToTupleAndClosureTypesSwift6_2() {
        let input = """
        let foo: (
            bar: String,
            quux: String
        )

        let bar: (
            bar: String,
            baaz: String
        ) -> Void

        public func testClosureArgumentInTuple() {
            _ = object.methodWithTupleArgument((
                closureArgument: { capturedObject in
                    _ = capturedObject
                },
            ))
        }
        """
        let output = """
        let foo: (
            bar: String,
            quux: String,
        )

        let bar: (
            bar: String,
            baaz: String,
        ) -> Void

        public func testClosureArgumentInTuple() {
            _ = object.methodWithTupleArgument((
                closureArgument: { capturedObject in
                    _ = capturedObject
                },
            ))
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testMultiElementListsTrailingCommasAddedToClosureTypeSwift6_2() {
        let input = """
        let foo: (
            bar: String
        ) -> Void

        let foo: (
            bar: String,
            baaz: String
        ) -> Void
        """
        let output = """
        let foo: (
            bar: String
        ) -> Void

        let foo: (
            bar: String,
            baaz: String,
        ) -> Void
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testMultiElementListsTrailingCommasAddedToTupleAndClosureTypesSwift6_2() {
        let input = """
        let bar: (
            bar: String,
            baaz: String
        )

        let bar: (
            bar: String,
            baaz: String
        ) -> Void
        """
        let output = """
        let bar: (
            bar: String,
            baaz: String,
        )

        let bar: (
            bar: String,
            baaz: String,
        ) -> Void
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToOptionalClosureCallSwift6_2() {
        let input = """
        myClosure?(
            foo: 5,
            bar: 10
        )
        """
        let output = """
        myClosure?(
            foo: 5,
            bar: 10,
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasAddedToOptionalClosureCallSingleParameterSwift6_2() {
        let input = """
        myClosure?(
            foo: 5
        )
        """
        let output = """
        myClosure?(
            foo: 5,
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasMultiElementListsOptionalClosureCallSwift6_2() {
        let input = """
        myClosure?(
            foo: 5,
        )

        otherClosure?(
            foo: 5,
            bar: 10
        )
        """
        let output = """
        myClosure?(
            foo: 5
        )

        otherClosure?(
            foo: 5,
            bar: 10,
        )
        """
        let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testTrailingCommasInTupleTypeCastAddedSwift6_2() {
        // Now supported in Swift 6.2
        let input = """
        let foo = bar as? (
            Foo,
            Bar
        )
        """
        let output = """
        let foo = bar as? (
            Foo,
            Bar,
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, output, rule: .trailingCommas, options: options)
    }

    func testIssue2142Swift6_2() {
        let input = """
        public func bindExitButton<T: Presenter>(
            action: T.Action,
            withIdentifier identifier: UIAction.Identifier? = nil,
            on controlEvents: UIControl.Event = .primaryActionTriggered,
            to presenter: T,
        ) {
            _ = action
            _ = identifier
            _ = controlEvents
            _ = presenter
        }

        let setModeSwizzle = Swizzle<AVAudioSession>(
            instance: instance,
            original: #selector(AVAudioSession.setMode(_:)),
            swizzled: #selector(AVAudioSession.swizzled_setMode(_:)),
        )
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, rule: .trailingCommas, options: options, exclude: [.propertyTypes])
    }

    func testIssue2143Swift6_2() {
        let input = """
        public func testClosureArgumentInTuple() {
            _ = object.methodWithTupleArgument((
                closureArgument: { capturedObject in
                    _ = capturedObject
                },
            ))
        }
        """
        let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
        testFormatting(for: input, rule: .trailingCommas, options: options)
    }
}
