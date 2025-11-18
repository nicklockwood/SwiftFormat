//
//  RedundantNilInitTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 12/5/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class RedundantNilInitTests: XCTestCase {
    func testRemoveRedundantNilInit() {
        let input = """
        var foo: Int? = nil
        let bar: Int? = nil
        """
        let output = """
        var foo: Int?
        let bar: Int? = nil
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(for: input, output, rule: .redundantNilInit,
                       options: options)
    }

    func testNoRemoveLetNilInitAfterVar() {
        let input = """
        var foo: Int
        let bar: Int? = nil
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    func testNoRemoveNonNilInit() {
        let input = """
        var foo: Int? = 0
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    func testRemoveRedundantImplicitUnwrapInit() {
        let input = """
        var foo: Int! = nil
        """
        let output = """
        var foo: Int!
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(for: input, output, rule: .redundantNilInit,
                       options: options)
    }

    func testNoRemoveLazyVarNilInit() {
        let input = """
        lazy var foo: Int? = nil
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    func testNoRemoveLazyPublicPrivateSetVarNilInit() {
        let input = """
        lazy private(set) public var foo: Int? = nil
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(for: input, rule: .redundantNilInit, options: options,
                       exclude: [.modifierOrder])
    }

    func testNoRemoveCodableNilInit() {
        let input = """
        struct Foo: Codable, Bar {
            enum CodingKeys: String, CodingKey {
                case bar = \"_bar\"
            }

            var bar: Int?
            var baz: String? = nil
        }
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    func testNoRemoveNilInitWithPropertyWrapper() {
        let input = """
        @Foo var foo: Int? = nil
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    func testNoRemoveNilInitWithLowercasePropertyWrapper() {
        let input = """
        @foo var foo: Int? = nil
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    func testNoRemoveNilInitWithPropertyWrapperWithArgument() {
        let input = """
        @Foo(bar: baz) var foo: Int? = nil
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    func testNoRemoveNilInitWithLowercasePropertyWrapperWithArgument() {
        let input = """
        @foo(bar: baz) var foo: Int? = nil
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    func testRemoveNilInitWithObjcAttributes() {
        let input = """
        @objc var foo: Int? = nil
        """
        let output = """
        @objc var foo: Int?
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(for: input, output, rule: .redundantNilInit,
                       options: options)
    }

    func testNoRemoveNilInitInStructWithDefaultInit() {
        let input = """
        struct Foo {
            var bar: String? = nil
        }
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    func testRemoveNilInitInStructWithDefaultInitInSwiftVersion5_2() {
        let input = """
        struct Foo {
            var bar: String? = nil
        }
        """
        let output = """
        struct Foo {
            var bar: String?
        }
        """
        let options = FormatOptions(nilInit: .remove, swiftVersion: "5.2")
        testFormatting(for: input, output, rule: .redundantNilInit,
                       options: options)
    }

    func testRemoveNilInitInStructWithCustomInit() {
        let input = """
        struct Foo {
            var bar: String? = nil
            init() {
                bar = "bar"
            }
        }
        """
        let output = """
        struct Foo {
            var bar: String?
            init() {
                bar = "bar"
            }
        }
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(for: input, output, rule: .redundantNilInit,
                       options: options)
    }

    func testNoRemoveNilInitInViewBuilder() {
        let input = """
        struct TestView: View {
            var body: some View {
                var foo: String? = nil
                Text(foo ?? "")
            }
        }
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    func testNoRemoveNilInitInIfStatementInViewBuilder() {
        let input = """
        struct TestView: View {
            var body: some View {
                if true {
                    var foo: String? = nil
                    Text(foo ?? "")
                } else {
                    EmptyView()
                }
            }
        }
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    func testNoRemoveNilInitInSwitchStatementInViewBuilder() {
        let input = """
        struct TestView: View {
            var body: some View {
                switch foo {
                case .bar:
                    var foo: String? = nil
                    Text(foo ?? "")

                default:
                    EmptyView()
                }
            }
        }
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    // --nilInit insert

    func testInsertNilInit() {
        let input = """
        var foo: Int?
        let bar: Int? = nil
        """
        let output = """
        var foo: Int? = nil
        let bar: Int? = nil
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, output, rule: .redundantNilInit,
                       options: options)
    }

    func testInsertNilInitBeforeLet() {
        let input = """
        var foo: Int?
        let bar: Int? = nil
        """
        let output = """
        var foo: Int? = nil
        let bar: Int? = nil
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, output, rule: .redundantNilInit,
                       options: options)
    }

    func testInsertNilInitAfterLet() {
        let input = """
        let bar: Int? = nil
        var foo: Int?
        """
        let output = """
        let bar: Int? = nil
        var foo: Int? = nil
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, output, rule: .redundantNilInit,
                       options: options)
    }

    func testNoInsertNonNilInit() {
        let input = """
        var foo: Int? = 0
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    func testInsertRedundantImplicitUnwrapInit() {
        let input = """
        var foo: Int!
        """
        let output = """
        var foo: Int! = nil
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, output, rule: .redundantNilInit,
                       options: options)
    }

    func testNoInsertLazyVarNilInit() {
        let input = """
        lazy var foo: Int?
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    func testNoInsertLazyPublicPrivateSetVarNilInit() {
        let input = """
        lazy private(set) public var foo: Int?
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, rule: .redundantNilInit, options: options,
                       exclude: [.modifierOrder])
    }

    func testNoInsertCodableNilInit() {
        let input = """
        struct Foo: Codable, Bar {
            enum CodingKeys: String, CodingKey {
                case bar = \"_bar\"
            }

            var bar: Int?
            var baz: String? = nil
        }
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    func testNoInsertNilInitWithPropertyWrapper() {
        let input = """
        @Foo var foo: Int?
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    func testNoInsertNilInitWithLowercasePropertyWrapper() {
        let input = """
        @foo var foo: Int?
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    func testNoInsertNilInitWithPropertyWrapperWithArgument() {
        let input = """
        @Foo(bar: baz) var foo: Int?
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    func testNoInsertNilInitWithLowercasePropertyWrapperWithArgument() {
        let input = """
        @foo(bar: baz) var foo: Int?
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    func testInsertNilInitWithObjcAttributes() {
        let input = """
        @objc var foo: Int?
        """
        let output = """
        @objc var foo: Int? = nil
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, output, rule: .redundantNilInit,
                       options: options)
    }

    func testNoInsertNilInitForClosureReturningOptional() {
        let input = """
        private var receiverSelector: @MainActor (IntrospectionPlatformViewController) -> Target?
        private var ancestorSelector: @MainActor (IntrospectionPlatformViewController) -> Target?
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, rule: .redundantNilInit, options: options)
    }

    func testNoInsertNilInitForClosureReturningOptionalWithAsyncThrows() {
        let input = """
        var fetcher: () async throws -> Response?
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, rule: .redundantNilInit, options: options)
    }

    func testNoInsertNilInitForClosureReturningOptionalWithGenericArgument() {
        let input = """
        var reducer: (Result<String, Error>) -> State?
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, rule: .redundantNilInit, options: options)
    }

    func testNoInsertNilInitForClosureReturningOptionalWithNestedClosureParameter() {
        let input = """
        var completion: (@MainActor () async -> Void) -> Result<Void, Error>?
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, rule: .redundantNilInit, options: options)
    }

    func testInsertNilInitForOptionalClosureProperty() {
        let input = """
        var handler: (() -> Void)?
        """
        let output = """
        var handler: (() -> Void)? = nil
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, output, rule: .redundantNilInit,
                       options: options)
    }

    func testNoInsertNilInitInStructWithDefaultInit() {
        let input = """
        struct Foo {
            var bar: String?
        }
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    func testInsertNilInitInStructWithDefaultInitInSwiftVersion5_2() {
        let input = """
        struct Foo {
            var bar: String?
            var foo: String? = nil
        }
        """
        let output = """
        struct Foo {
            var bar: String? = nil
            var foo: String? = nil
        }
        """
        let options = FormatOptions(nilInit: .insert, swiftVersion: "5.2")
        testFormatting(for: input, output, rule: .redundantNilInit,
                       options: options)
    }

    func testInsertNilInitInStructWithCustomInit() {
        let input = """
        struct Foo {
            var bar: String?
            var foo: String? = nil
            init() {
                bar = "bar"
                foo = "foo"
            }
        }
        """
        let output = """
        struct Foo {
            var bar: String? = nil
            var foo: String? = nil
            init() {
                bar = "bar"
                foo = "foo"
            }
        }
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, output, rule: .redundantNilInit,
                       options: options)
    }

    func testNoInsertNilInitInViewBuilder() {
        // Not insert `nil` in result builder
        let input = """
        struct TestView: View {
            var body: some View {
                var foo: String?
                Text(foo ?? "")
            }
        }
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    func testNoInsertNilInitInIfStatementInViewBuilder() {
        // Not insert `nil` in result builder
        let input = """
        struct TestView: View {
            var body: some View {
                if true {
                    var foo: String?
                    Text(foo ?? "")
                } else {
                    EmptyView()
                }
            }
        }
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    func testNoInsertNilInitInSwitchStatementInViewBuilder() {
        // Not insert `nil` in result builder
        let input = """
        struct TestView: View {
            var body: some View {
                switch foo {
                case .bar:
                    var foo: String?
                    Text(foo ?? "")

                default:
                    EmptyView()
                }
            }
        }
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    func testNoInsertNilInitInSingleLineComputedProperty() {
        let input = """
        var bar: String? { "some string" }
        var foo: String? { nil }
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    func testNoInsertNilInitInMultilineComputedProperty() {
        let input = """
        var foo: String? {
            print("some")
        }

        var bar: String? {
            nil
        }
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    func testNoInsertNilInitInCustomGetterAndSetterProperty() {
        let input = """
        var _foo: String? = nil
        var foo: String? {
            set { _foo = newValue }
            get { newValue }
        }
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    func testInsertNilInitInInstancePropertyWithBody() {
        let input = """
        var foo: String? {
            didSet { print(foo) }
        }
        """

        let output = """
        var foo: String? = nil {
            didSet { print(foo) }
        }
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, output, rule: .redundantNilInit,
                       options: options)
    }

    func testNoInsertNilInitInAs() {
        let input = """
        let json: Any = ["key": 1]
        var jsonObject = json as? [String: Int]
        """
        let options = FormatOptions(nilInit: .insert)
        testFormatting(for: input, rule: .redundantNilInit,
                       options: options)
    }

    func testRemoveRedundantNilInitInSubclass() {
        let input = """
        class SomeClass2: SomeClass {
            var optionalString2: String? = nil
        }
        """
        let output = """
        class SomeClass2: SomeClass {
            var optionalString2: String?
        }
        """
        let options = FormatOptions(nilInit: .remove)
        testFormatting(for: input, output, rule: .redundantNilInit,
                       options: options)
    }
}
