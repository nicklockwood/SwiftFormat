//
//  RulesTests+Organize.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 04/09/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

extension RulesTests {
    // MARK: organizeDeclarations

    func testOrganizeClassDeclarationsIntoCategories() {
        let input = """
        class Foo {
            private func privateMethod() {}

            private let bar = 1
            public let baz = 1
            open var quack = 2
            var quux = 2

            // `open` is the only visibility keyword that
            // can also be used as an identifier.
            var open = 10

            /*
             * Block comment
             */

            init() {}

            /// Doc comment
            public func publicMethod() {}
        }
        """

        let output = """
        class Foo {

            // MARK: Lifecycle

            /*
             * Block comment
             */

            init() {}

            // MARK: Open

            open var quack = 2

            // MARK: Public

            public let baz = 1

            /// Doc comment
            public func publicMethod() {}

            // MARK: Internal

            var quux = 2

            // `open` is the only visibility keyword that
            // can also be used as an identifier.
            var open = 10

            // MARK: Private

            private let bar = 1

            private func privateMethod() {}

        }
        """

        testFormatting(
            for: input, output,
            rule: FormatRules.organizeDeclarations,
            exclude: ["blankLinesAtStartOfScope", "blankLinesAtEndOfScope"]
        )
    }

    func testClassNestedInClassIsOrganized() {
        let input = """
        public class Foo {
            public class Bar {
                fileprivate func baaz() {}
                public var quux: Int
                init() {}
                deinit {}
            }
        }
        """

        let output = """
        public class Foo {
            public class Bar {

                // MARK: Lifecycle

                init() {}
                deinit {}

                // MARK: Public

                public var quux: Int

                // MARK: Fileprivate

                fileprivate func baaz() {}
            }
        }
        """

        testFormatting(
            for: input, output,
            rule: FormatRules.organizeDeclarations,
            exclude: ["blankLinesAtStartOfScope", "enumNamespaces"]
        )
    }

    func testStructNestedInExtensionIsOrganized() {
        let input = """
        public extension Foo {
            struct Bar {
                private var foo: Int
                private let bar: Int

                public var foobar: (Int, Int) {
                    (foo, bar)
                }

                public init(foo: Int, bar: Int) {
                    self.foo = foo
                    self.bar = bar
                }
            }
        }
        """

        let output = """
        public extension Foo {
            struct Bar {

                // MARK: Lifecycle

                public init(foo: Int, bar: Int) {
                    self.foo = foo
                    self.bar = bar
                }

                // MARK: Public

                public var foobar: (Int, Int) {
                    (foo, bar)
                }

                // MARK: Private

                private var foo: Int
                private let bar: Int

            }
        }
        """

        testFormatting(
            for: input, output,
            rule: FormatRules.organizeDeclarations,
            exclude: ["blankLinesAtStartOfScope", "blankLinesAtEndOfScope"]
        )
    }

    func testOrganizePrivateSet() {
        let input = """
        class Foo {
            public private(set) var bar: Int
            private(set) var baz: Int
            internal private(set) var baz: Int
        }
        """

        let output = """
        class Foo {

            // MARK: Public

            public private(set) var bar: Int

            // MARK: Internal

            private(set) var baz: Int
            internal private(set) var baz: Int
        }
        """

        testFormatting(
            for: input, output,
            rule: FormatRules.organizeDeclarations,
            exclude: ["blankLinesAtStartOfScope"]
        )
    }

    func testSortDeclarationTypes() {
        let input = """
        class Foo {
            static var a1: Int = 1
            static var a2: Int = 2
            var d1: CGFloat {
                3.141592653589
            }

            class var b2: String {
                "class computed property"
            }

            func g() -> Int {
                10
            }

            let c: String = String {
                "closure body"
            }()

            static func e() {}

            typealias Bar = Int

            static var b1: String {
                "static computed property"
            }

            class func f() -> Foo {
                Foo()
            }

            enum NestedEnum {}

            var d2: CGFloat = 3.141592653589 {
                didSet {}
            }
        }
        """

        let output = """
        class Foo {
            typealias Bar = Int

            enum NestedEnum {}

            static var a1: Int = 1
            static var a2: Int = 2

            static var b1: String {
                "static computed property"
            }

            class var b2: String {
                "class computed property"
            }

            let c: String = String {
                "closure body"
            }()

            var d1: CGFloat {
                3.141592653589
            }

            var d2: CGFloat = 3.141592653589 {
                didSet {}
            }

            static func e() {}

            class func f() -> Foo {
                Foo()
            }

            func g() -> Int {
                10
            }

        }
        """

        testFormatting(
            for: input, output,
            rule: FormatRules.organizeDeclarations,
            exclude: ["blankLinesAtEndOfScope", "redundantType"]
        )
    }

    func testOrganizeEnumCasesFirst() {
        let input = """
        enum Foo {
            init?(rawValue: String) {
                return nil
            }

            case bar
            case baz
            case quux
        }
        """

        let output = """
        enum Foo {
            case bar
            case baz
            case quux

            // MARK: Lifecycle

            init?(rawValue: String) {
                return nil
            }

        }
        """

        testFormatting(
            for: input, output,
            rule: FormatRules.organizeDeclarations,
            exclude: ["blankLinesAtEndOfScope", "unusedArguments"]
        )
    }

    func testPlacingCustomDeclarationsBeforeMarks() {
        let input = """
        struct Foo {

            public init() {}

            public typealias Bar = Int

            public struct Baz {}

        }
        """

        let output = """
        struct Foo {

            public typealias Bar = Int

            public struct Baz {}

            // MARK: Lifecycle

            public init() {}

        }
        """

        testFormatting(
            for: input, output,
            rule: FormatRules.organizeDeclarations,
            options: FormatOptions(beforeMarks: ["typealias", "struct"]),
            exclude: ["blankLinesAtStartOfScope", "blankLinesAtEndOfScope"]
        )
    }

    func testCustomLifecycleMethods() {
        let input = """
        class ViewController: UIViewController {

            public init() {
                super.init(nibName: nil, bundle: nil)
            }

            func viewDidLoad() {
                super.viewDidLoad()
            }

            func internalInstanceMethod() {}

            func viewDidAppear(_ animated: Bool) {
                super.viewDidAppear(animated)
            }

        }
        """

        let output = """
        class ViewController: UIViewController {

            // MARK: Lifecycle

            public init() {
                super.init(nibName: nil, bundle: nil)
            }

            func viewDidLoad() {
                super.viewDidLoad()
            }

            func viewDidAppear(_ animated: Bool) {
                super.viewDidAppear(animated)
            }

            // MARK: Internal

            func internalInstanceMethod() {}

        }
        """

        testFormatting(
            for: input, output,
            rule: FormatRules.organizeDeclarations,
            options: FormatOptions(lifecycleMethods: ["viewDidLoad", "viewWillAppear", "viewDidAppear"]),
            exclude: ["blankLinesAtStartOfScope", "blankLinesAtEndOfScope"]
        )
    }

    func testCustomCategoryMarkTemplate() {
        let input = """
        struct Foo {
            public init() {}
            public func publicInstanceMethod() {}
        }
        """

        let output = """
        struct Foo {

            // - Lifecycle

            public init() {}

            // - Public

            public func publicInstanceMethod() {}
        }
        """

        testFormatting(
            for: input, output,
            rule: FormatRules.organizeDeclarations,
            options: FormatOptions(categoryMarkComment: "- %c"),
            exclude: ["blankLinesAtStartOfScope"]
        )
    }

    func testBelowCustomStructOrganizationThreshold() {
        let input = """
        struct StructBelowThreshold {
            init() {}
        }
        """

        testFormatting(
            for: input,
            rule: FormatRules.organizeDeclarations,
            options: FormatOptions(organizeStructThreshold: 2)
        )
    }

    func testAboveCustomStructOrganizationThreshold() {
        let input = """
        struct StructAboveThreshold {
            init() {}
            public func instanceMethod() {}
        }
        """

        let output = """
        struct StructAboveThreshold {

            // MARK: Lifecycle

            init() {}

            // MARK: Public

            public func instanceMethod() {}
        }
        """

        testFormatting(
            for: input, output,
            rule: FormatRules.organizeDeclarations,
            options: FormatOptions(organizeStructThreshold: 2),
            exclude: ["blankLinesAtStartOfScope"]
        )
    }

    func testCustomClassOrganizationThreshold() {
        let input = """
        class ClassBelowThreshold {
            init() {}
        }
        """

        testFormatting(
            for: input,
            rule: FormatRules.organizeDeclarations,
            options: FormatOptions(organizeClassThreshold: 2)
        )
    }

    func testCustomEnumOrganizationThreshold() {
        let input = """
        enum EnumBelowThreshold {
            case enumCase
        }
        """

        testFormatting(
            for: input,
            rule: FormatRules.organizeDeclarations,
            options: FormatOptions(organizeEnumThreshold: 2)
        )
    }

    func testPreservesExistingMarks() {
        let input = """
        class Foo {

            // MARK: Lifecycle

            init(json: JSONObject) throws {
                bar = try json.value(for: "bar")
                baz = try json.value(for: "baz")
            }

            // MARK: Internal

            let bar: String
            let baz: Int?
        }
        """
        testFormatting(for: input, rule: FormatRules.organizeDeclarations,
                       exclude: ["blankLinesAtStartOfScope"])
    }

    func testUpdatesMalformedMarks() {
        let input = """
        struct Foo {

            // MARK: lifecycle

            // MARK: Lifeycle

            init() {}

            // Public

            // - Public

            public func bar() {}

            // MARK: - Internal

            func baaz() {}

            // mrak: privat

            // Pulse

            private func quux() {}
        }
        """

        let output = """
        struct Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Public

            public func bar() {}

            // MARK: Internal

            func baaz() {}

            // MARK: Private

            // Pulse

            private func quux() {}
        }
        """

        testFormatting(for: input, output, rule: FormatRules.organizeDeclarations,
                       exclude: ["blankLinesAtStartOfScope"])
    }

    func testDoesntAttemptToUpdateMarksNotAtTopLevel() {
        let input = """
        class Foo {

            // MARK: Lifecycle

            public init() {
                foo = ["foo"]
            }

            // Comment at bottom of lifecycle category

            // MARK: Private

            @annotation // Private
            // Private
            private var foo: [String] = []

            private func bar() {
                // Private
                guard let baz = bar else {
                    return
                }
            }
        }
        """

        testFormatting(for: input, rule: FormatRules.organizeDeclarations,
                       exclude: ["blankLinesAtStartOfScope"])
    }

    func testHandlesTrailingCommentCorrectly() {
        let input = """
        class Foo {
            var bar = "bar"
            /// Leading comment
            public var baaz = "baaz" // Trailing comment
            var quux = "quux"
        }
        """

        let output = """
        class Foo {

            // MARK: Public

            /// Leading comment
            public var baaz = "baaz" // Trailing comment

            // MARK: Internal

            var bar = "bar"
            var quux = "quux"
        }
        """

        testFormatting(for: input, output, rule: FormatRules.organizeDeclarations,
                       exclude: ["blankLinesAtStartOfScope"])
    }

    func testDoesntInsertMarkWhenOnlyOneCategory() {
        let input = """
        class Foo {
            var bar: Int
            var baaz: Int
            func instanceMethod() {}
        }
        """

        let output = """
        class Foo {
            var bar: Int
            var baaz: Int

            func instanceMethod() {}
        }
        """

        testFormatting(for: input, output, rule: FormatRules.organizeDeclarations)
    }

    func testOrganizesTypesWithinConditionalCompilationBlock() {
        let input = """
        #if DEBUG
        struct DebugFoo {
            init() {}
            public func instanceMethod() {}
        }
        #else
        struct ProductionFoo {
            init() {}
            public func instanceMethod() {}
        }
        #endif
        """

        let output = """
        #if DEBUG
        struct DebugFoo {

            // MARK: Lifecycle

            init() {}

            // MARK: Public

            public func instanceMethod() {}
        }
        #else
        struct ProductionFoo {

            // MARK: Lifecycle

            init() {}

            // MARK: Public

            public func instanceMethod() {}
        }
        #endif
        """

        testFormatting(for: input, output, rule: FormatRules.organizeDeclarations,
                       options: FormatOptions(ifdefIndent: .noIndent),
                       exclude: ["blankLinesAtStartOfScope"])
    }

    func testOrganizesTypesBelowConditionalCompilationBlock() {
        let input = """
        #if canImport(UIKit)
        import UIKit
        #endif

        struct Foo {
            init() {}
            public func instanceMethod() {}
        }
        """

        let output = """
        #if canImport(UIKit)
        import UIKit
        #endif

        struct Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Public

            public func instanceMethod() {}
        }
        """

        testFormatting(for: input, output, rule: FormatRules.organizeDeclarations,
                       options: FormatOptions(ifdefIndent: .noIndent),
                       exclude: ["blankLinesAtStartOfScope"])
    }

    func testOrganizesNestedTypesWithinConditionalCompilationBlock() {
        let input = """
        public struct Foo {

            public var bar = "bar"
            var baaz = "baaz"

            #if DEBUG
            public struct DebugFoo {
                init() {}
                var debugBar = "debug"
            }

            static let debugFoo = DebugFoo()

            private let other = "other"
            #endif

            init() {}

            var quuz = "quux"
        }
        """

        let output = """
        public struct Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Public

            public var bar = "bar"

            #if DEBUG
            public struct DebugFoo {

                // MARK: Lifecycle

                init() {}

                // MARK: Internal

                var debugBar = "debug"
            }

            static let debugFoo = DebugFoo()

            private let other = "other"
            #endif

            // MARK: Internal

            var baaz = "baaz"

            var quuz = "quux"
        }
        """

        testFormatting(for: input, output, rule: FormatRules.organizeDeclarations,
                       options: FormatOptions(ifdefIndent: .noIndent),
                       exclude: ["blankLinesAtStartOfScope"])
    }

    func testOrganizesTypeBelowSymbolImport() {
        let input = """
        import protocol SomeModule.SomeProtocol
        import class SomeModule.SomeClass
        import enum SomeModule.SomeEnum
        import struct SomeModule.SomeStruct
        import typealias SomeModule.SomeTypealias
        import let SomeModule.SomeGlobalConstant
        import var SomeModule.SomeGlobalVariable
        import func SomeModule.SomeFunc

        struct Foo {
            init() {}
            public func instanceMethod() {}
        }
        """

        let output = """
        import protocol SomeModule.SomeProtocol
        import class SomeModule.SomeClass
        import enum SomeModule.SomeEnum
        import struct SomeModule.SomeStruct
        import typealias SomeModule.SomeTypealias
        import let SomeModule.SomeGlobalConstant
        import var SomeModule.SomeGlobalVariable
        import func SomeModule.SomeFunc

        struct Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Public

            public func instanceMethod() {}
        }
        """

        testFormatting(
            for: input, output, rule: FormatRules.organizeDeclarations,
            exclude: ["blankLinesAtStartOfScope", "sortedImports"]
        )
    }

    func testDoesntBreakStructSynthesizedMemberwiseInitializer() {
        let input = """
        struct Foo {
            var bar: Int {
                didSet {}
            }

            var baaz: Int
            public let quux: Int
        }

        Foo(bar: 1, baaz: 2, quux: 3)
        """

        testFormatting(for: input, rule: FormatRules.organizeDeclarations)
    }

    func testOrganizesStructPropertiesThatDontBreakMemberwiseInitializer() {
        let input = """
        struct Foo {
            var computed: String {
                let didSet = "didSet"
                let willSet = "willSet"
                return didSet + willSet
            }

            private func instanceMethod() {}
            public let bar: Int
            var baaz: Int
            var quux: Int {
                didSet {}
            }
        }

        Foo(bar: 1, baaz: 2, quux: 3)
        """

        let output = """
        struct Foo {

            // MARK: Public

            public let bar: Int

            // MARK: Internal

            var baaz: Int

            var computed: String {
                let didSet = "didSet"
                let willSet = "willSet"
                return didSet + willSet
            }

            var quux: Int {
                didSet {}
            }

            // MARK: Private

            private func instanceMethod() {}
        }

        Foo(bar: 1, baaz: 2, quux: 3)
        """

        testFormatting(
            for: input, output, rule: FormatRules.organizeDeclarations,
            exclude: ["blankLinesAtStartOfScope"]
        )
    }

    func testPreservesCategoryMarksInStructWithIncorrectSubcategoryOrdering() {
        let input = """
        struct Foo {

            // MARK: Public

            public let quux: Int

            // MARK: Internal

            var bar: Int {
                didSet {}
            }

            var baaz: Int
        }

        Foo(bar: 1, baaz: 2, quux: 3)
        """

        testFormatting(
            for: input, rule: FormatRules.organizeDeclarations,
            exclude: ["blankLinesAtStartOfScope"]
        )
    }

    func testPreservesCommentsAtBottomOfCategory() {
        let input = """
        struct Foo {

            // MARK: Lifecycle

            init() {}

            // Important comment at end of section!

            // MARK: Public

            public let bar = 1
        }
        """

        testFormatting(
            for: input, rule: FormatRules.organizeDeclarations,
            exclude: ["blankLinesAtStartOfScope"]
        )
    }

    func testPreservesCommentsAtBottomOfCategoryWhenReorganizing() {
        let input = """
        struct Foo {

            // MARK: Lifecycle

            init() {}

            // Important comment at end of section!

            // MARK: Internal

            // Important comment at start of section!

            var baaz = 1

            public let bar = 1
        }
        """

        let output = """
        struct Foo {

            // MARK: Lifecycle

            init() {}

            // Important comment at end of section!

            // MARK: Public

            public let bar = 1

            // MARK: Internal

            // Important comment at start of section!

            var baaz = 1

        }
        """

        testFormatting(
            for: input, output, rule: FormatRules.organizeDeclarations,
            exclude: ["blankLinesAtStartOfScope", "blankLinesAtEndOfScope"]
        )
    }

    func testDoesntRemoveCategorySeparatorsFromBodyNotBeingOrganized() {
        let input = """
        struct Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Public

            public var bar = 10
        }

        extension Foo {

            // MARK: Public

            public var baz: Int { 20 }

            // MARK: Internal

            var quux: Int { 30 }
        }
        """

        testFormatting(
            for: input, rule: FormatRules.organizeDeclarations,
            options: FormatOptions(organizeStructThreshold: 20),
            exclude: ["blankLinesAtStartOfScope"]
        )
    }

    func testParsesPropertiesWithBodies() {
        let input = """
        class Foo {
            // Instance properties without bodies:

            let propertyWithoutBody1 = 10

            let propertyWithoutBody2: String = {
                "bar"
            }()

            let propertyWithoutBody3: () -> String = {
                "bar"
            }

            // Instance properties with bodies:

            var withBody1: String {
                "bar"
            }

            var withBody2: String {
                didSet { print("didSet") }
            }

            var withBody3: String = "bar" {
                didSet { print("didSet") }
            }

            var withBody4: String = "bar" {
                didSet { print("didSet") }
            }

            var withBody5: () -> String = { "bar" } {
                didSet { print("didSet") }
            }

            var withBody6: String = { "bar" }() {
                didSet { print("didSet") }
            }
        }
        """

        testFormatting(for: input, rule: FormatRules.organizeDeclarations)
    }

    func testFuncWithNestedInitNotTreatedAsLifecycle() {
        let input = """
        struct Foo {

            // MARK: Public

            public func baz() {}

            // MARK: Internal

            func bar() {
                class NestedClass {
                    init() {}
                }

                // ...
            }
        }
        """

        testFormatting(for: input, rule: FormatRules.organizeDeclarations,
                       exclude: ["blankLinesAtStartOfScope"])
    }

    // MARK: extensionAccessControl .onDeclarations

    func testUpdatesVisibilityOfExtensionMembers() {
        let input = """
        private extension Foo {
            var publicProperty: Int { 10 }
            public func publicFunction1() {}
            func publicFunction2() {}
            internal func internalFunction() {}
            private func privateFunction() {}
            fileprivate var privateProperty: Int { 10 }
        }
        """

        let output = """
        extension Foo {
            fileprivate var publicProperty: Int { 10 }
            public func publicFunction1() {}
            fileprivate func publicFunction2() {}
            internal func internalFunction() {}
            private func privateFunction() {}
            fileprivate var privateProperty: Int { 10 }
        }
        """

        testFormatting(
            for: input, output, rule: FormatRules.extensionAccessControl,
            options: FormatOptions(extensionACLPlacement: .onDeclarations)
        )
    }

    func testUpdatesVisibilityOfExtensionInConditionalCompilationBlock() {
        let input = """
        #if DEBUG
            public extension Foo {
                var publicProperty: Int { 10 }
            }
        #endif
        """

        let output = """
        #if DEBUG
            extension Foo {
                public var publicProperty: Int { 10 }
            }
        #endif
        """

        testFormatting(
            for: input, output, rule: FormatRules.extensionAccessControl,
            options: FormatOptions(extensionACLPlacement: .onDeclarations)
        )
    }

    func testUpdatesVisibilityOfExtensionMembersInConditionalCompilationBlock() {
        let input = """
        public extension Foo {
            #if DEBUG
                var publicProperty: Int { 10 }
            #endif
        }
        """

        let output = """
        extension Foo {
            #if DEBUG
                public var publicProperty: Int { 10 }
            #endif
        }
        """

        testFormatting(
            for: input, output, rule: FormatRules.extensionAccessControl,
            options: FormatOptions(extensionACLPlacement: .onDeclarations)
        )
    }

    func testDoesntUpdateDeclarationsInsideTypeInsideExtension() {
        let input = """
        public extension Foo {
            struct Bar {
                var baaz: Int
                var quux: Int
            }
        }
        """

        let output = """
        extension Foo {
            public struct Bar {
                var baaz: Int
                var quux: Int
            }
        }
        """

        testFormatting(
            for: input, output, rule: FormatRules.extensionAccessControl,
            options: FormatOptions(extensionACLPlacement: .onDeclarations)
        )
    }

    func testDoesNothingForInternalExtension() {
        let input = """
        extension Foo {
            func bar() {}
            func baaz() {}
            public func quux() {}
        }
        """

        testFormatting(
            for: input, rule: FormatRules.extensionAccessControl,
            options: FormatOptions(extensionACLPlacement: .onDeclarations)
        )
    }

    func testPlacesVisibilityKeywordAfterAnnotations() {
        let input = """
        public extension Foo {
            @discardableResult
            func bar() -> Int { 10 }

            /// Doc comment
            @discardableResult
            @available(iOS 10.0, *)
            func baaz() -> Int { 10 }

            @objc func quux() {}
            @available(iOS 10.0, *) func quixotic() {}
        }
        """

        let output = """
        extension Foo {
            @discardableResult
            public func bar() -> Int { 10 }

            /// Doc comment
            @discardableResult
            @available(iOS 10.0, *)
            public func baaz() -> Int { 10 }

            @objc public func quux() {}
            @available(iOS 10.0, *) public func quixotic() {}
        }
        """

        testFormatting(
            for: input, output, rule: FormatRules.extensionAccessControl,
            options: FormatOptions(extensionACLPlacement: .onDeclarations)
        )
    }

    // MARK: extensionAccessControl .onExtension

    func testUpdatedVisibilityOfExtension() {
        let input = """
        extension Foo {
            public func bar() {}
            public var baaz: Int { 10 }

            public struct Foo2 {
                var quux: Int
            }
        }
        """

        let output = """
        public extension Foo {
            func bar() {}
            var baaz: Int { 10 }

            struct Foo2 {
                var quux: Int
            }
        }
        """

        testFormatting(for: input, output, rule: FormatRules.extensionAccessControl)
    }

    func testUpdatedVisibilityOfExtensionWithDeclarationsInConditionalCompilation() {
        let input = """
        extension Foo {
            #if DEBUG
                public func bar() {}
                public var baaz: Int { 10 }
            #endif
        }
        """

        let output = """
        public extension Foo {
            #if DEBUG
                func bar() {}
                var baaz: Int { 10 }
            #endif
        }
        """

        testFormatting(for: input, output, rule: FormatRules.extensionAccessControl)
    }

    func testDoesntUpdateExtensionVisibilityWithMultipleBodyVisibilities() {
        let input = """
        extension Foo {
            public func bar() {}
            var baaz: Int { 10 }
        }
        """

        testFormatting(for: input, rule: FormatRules.extensionAccessControl)
    }

    func testDoesntUpdateExtensionVisibilityWithInternalDeclarations() {
        let input = """
        extension Foo {
            func bar() {}
            var baaz: Int { 10 }
        }
        """

        testFormatting(for: input, rule: FormatRules.extensionAccessControl)
    }

    func testDoesntUpdateExtensionThatAlreadyHasCorrectVisibilityKeyword() {
        let input = """
        public extension Foo {
            func bar() {}
            func baaz() {}
        }
        """

        testFormatting(for: input, rule: FormatRules.extensionAccessControl)
    }

    func testUpdatesExtensionThatHasHigherACLThanBodyDeclarations() {
        let input = """
        public extension Foo {
            fileprivate func bar() {}
            fileprivate func baaz() {}
        }
        """

        let output = """
        fileprivate extension Foo {
            func bar() {}
            func baaz() {}
        }
        """

        testFormatting(for: input, output, rule: FormatRules.extensionAccessControl,
                       exclude: ["redundantFileprivate"])
    }

    func testDoesntHoistPrivateVisibilityFromExtensionBodyDeclarations() {
        let input = """
        extension Foo {
            private var bar() {}
            private func baaz() {}
        }
        """

        testFormatting(for: input, rule: FormatRules.extensionAccessControl)
    }

    func testDoesntUpdatesExtensionThatHasLowerACLThanBodyDeclarations() {
        let input = """
        private extension Foo {
            public var bar() {}
            public func baaz() {}
        }
        """

        testFormatting(for: input, rule: FormatRules.extensionAccessControl)
    }

    func testDoesntReduceVisibilityOfImplicitInternalDeclaration() {
        let input = """
        extension Foo {
            fileprivate var bar() {}
            func baz() {}
        }
        """

        testFormatting(for: input, rule: FormatRules.extensionAccessControl)
    }

    func testUpdatesExtensionThatHasRedundantACLOnBodyDeclarations() {
        let input = """
        public extension Foo {
            func bar() {}
            public func baaz() {}
        }
        """

        let output = """
        public extension Foo {
            func bar() {}
            func baaz() {}
        }
        """

        testFormatting(for: input, output, rule: FormatRules.extensionAccessControl)
    }

    func testNoHoistAccessModifierForOpenMethod() {
        let input = """
        extension Foo {
            open func bar() {}
        }
        """
        testFormatting(for: input, rule: FormatRules.extensionAccessControl)
    }
}
