//
//  RulesTests+Organize.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 04/09/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class OrganizationTests: RulesTests {
    // MARK: organizeDeclarations

    func testOrganizeClassDeclarationsIntoCategories() {
        let input = """
        class Foo {
            private func privateMethod() {}

            private let bar = 1
            public let baz = 1
            open var quack = 2
            var quux = 2

            /// `open` is the only visibility keyword that
            /// can also be used as an identifier.
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

            /// `open` is the only visibility keyword that
            /// can also be used as an identifier.
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
                fileprivate func baz() {}
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

                fileprivate func baz() {}
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
            exclude: ["blankLinesAtEndOfScope", "redundantType", "redundantClosure"]
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

    func testBelowCustomExtensionOrganizationThreshold() {
        let input = """
        extension FooBelowThreshold {
            func bar() {}
        }
        """

        testFormatting(
            for: input,
            rule: FormatRules.organizeDeclarations,
            options: FormatOptions(
                organizeTypes: ["class", "struct", "enum", "extension"],
                organizeExtensionThreshold: 2
            )
        )
    }

    func testAboveCustomExtensionOrganizationThreshold() {
        let input = """
        extension FooBelowThreshold {
            public func bar() {}
            func baz() {}
            private func quux() {}
        }
        """

        let output = """
        extension FooBelowThreshold {

            // MARK: Public

            public func bar() {}

            // MARK: Internal

            func baz() {}

            // MARK: Private

            private func quux() {}
        }
        """

        testFormatting(
            for: input, output,
            rule: FormatRules.organizeDeclarations,
            options: FormatOptions(
                organizeTypes: ["class", "struct", "enum", "extension"],
                organizeExtensionThreshold: 2
            ), exclude: ["blankLinesAtStartOfScope"]
        )
    }

    func testPreservesExistingMarks() {
        let input = """
        actor Foo {

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
        actor Foo {

            // MARK: lifecycle

            // MARK: Lifeycle

            init() {}

            // Public

            // - Public

            public func bar() {}

            // MARK: - Internal

            func baz() {}

            // mrak: privat

            // Pulse

            private func quux() {}
        }
        """

        let output = """
        actor Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Public

            public func bar() {}

            // MARK: Internal

            func baz() {}

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
            /// Private
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
            public var baz = "baz" // Trailing comment
            var quux = "quux"
        }
        """

        let output = """
        class Foo {

            // MARK: Public

            /// Leading comment
            public var baz = "baz" // Trailing comment

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
            var baz: Int
            func instanceMethod() {}
        }
        """

        let output = """
        class Foo {
            var bar: Int
            var baz: Int

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
            var baz = "baz"

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

            var baz = "baz"

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

            var baz: Int
            public let quux: Int
        }

        Foo(bar: 1, baz: 2, quux: 3)
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
            var baz: Int
            var quux: Int {
                didSet {}
            }
        }

        Foo(bar: 1, baz: 2, quux: 3)
        """

        let output = """
        struct Foo {

            // MARK: Public

            public let bar: Int

            // MARK: Internal

            var baz: Int

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

        Foo(bar: 1, baz: 2, quux: 3)
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

            var baz: Int
        }

        Foo(bar: 1, baz: 2, quux: 3)
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

            var baz = 1

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

            var baz = 1

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

        testFormatting(for: input, rule: FormatRules.organizeDeclarations, exclude: ["redundantClosure"])
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

    func testOrganizeRuleNotConfusedByClassProtocol() {
        let input = """
        protocol Foo: class {
            func foo()
        }

        class Bar {
            // MARK: Fileprivate

            private var baz: Int

            // MARK: Private

            private let quux: String
        }
        """

        let output = """
        protocol Foo: class {
            func foo()
        }

        class Bar {
            private var baz: Int

            private let quux: String
        }
        """

        testFormatting(for: input, output, rule: FormatRules.organizeDeclarations,
                       exclude: ["blankLinesAtStartOfScope"])
    }

    func testOrganizeClassDeclarationsIntoCategoriesWithNoBlankLineAfterMark() {
        let input = """
        class Foo {
            private func privateMethod() {}

            private let bar = 1
            public let baz = 1
            open var quack = 2
            var quux = 2

            init() {}

            /// Doc comment
            public func publicMethod() {}
        }
        """

        let output = """
        class Foo {

            // MARK: Lifecycle
            init() {}

            // MARK: Open
            open var quack = 2

            // MARK: Public
            public let baz = 1

            /// Doc comment
            public func publicMethod() {}

            // MARK: Internal
            var quux = 2

            // MARK: Private
            private let bar = 1

            private func privateMethod() {}

        }
        """
        let options = FormatOptions(lineAfterMarks: false)
        testFormatting(
            for: input, output,
            rule: FormatRules.organizeDeclarations,
            options: options,
            exclude: ["blankLinesAtStartOfScope", "blankLinesAtEndOfScope"]
        )
    }

    func testOrganizeWithNoCategoryMarks_noSpacesBetweenDeclarations() {
        let input = """
        class Foo {
            private func privateMethod() {}
            private let bar = 1
            public let baz = 1
        }
        """

        let output = """
        class Foo {
            public let baz = 1

            private let bar = 1

            private func privateMethod() {}
        }
        """

        testFormatting(
            for: input, output,
            rule: FormatRules.organizeDeclarations,
            options: FormatOptions(markCategories: false)
        )
    }

    func testOrganizeWithNoCategoryMarks_withSpacesBetweenDeclarations() {
        let input = """
        class Foo {
            private func privateMethod() {}

            private let bar = 1

            public let baz = 1

            private func anotherPrivateMethod() {}
        }
        """

        let output = """
        class Foo {
            public let baz = 1

            private let bar = 1

            private func privateMethod() {}

            private func anotherPrivateMethod() {}
        }
        """

        testFormatting(
            for: input, output,
            rule: FormatRules.organizeDeclarations,
            options: FormatOptions(markCategories: false)
        )
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
                var baz: Int
                var quux: Int
            }
        }
        """

        let output = """
        extension Foo {
            public struct Bar {
                var baz: Int
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
            func baz() {}
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
            func baz() -> Int { 10 }

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
            public func baz() -> Int { 10 }

            @objc public func quux() {}
            @available(iOS 10.0, *) public func quixotic() {}
        }
        """

        testFormatting(
            for: input, output, rule: FormatRules.extensionAccessControl,
            options: FormatOptions(extensionACLPlacement: .onDeclarations)
        )
    }

    func testConvertsExtensionPrivateToMemberFileprivate() {
        let input = """
        private extension Foo {
            var bar: Int
        }

        let bar = Foo().bar
        """

        let output = """
        extension Foo {
            fileprivate var bar: Int
        }

        let bar = Foo().bar
        """

        testFormatting(
            for: input, output, rule: FormatRules.extensionAccessControl,
            options: FormatOptions(extensionACLPlacement: .onDeclarations, swiftVersion: "4")
        )
    }

    // MARK: extensionAccessControl .onExtension

    func testUpdatedVisibilityOfExtension() {
        let input = """
        extension Foo {
            public func bar() {}
            public var baz: Int { 10 }

            public struct Foo2 {
                var quux: Int
            }
        }
        """

        let output = """
        public extension Foo {
            func bar() {}
            var baz: Int { 10 }

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
                public var baz: Int { 10 }
            #endif
        }
        """

        let output = """
        public extension Foo {
            #if DEBUG
                func bar() {}
                var baz: Int { 10 }
            #endif
        }
        """

        testFormatting(for: input, output, rule: FormatRules.extensionAccessControl)
    }

    func testDoesntUpdateExtensionVisibilityWithoutMajorityBodyVisibility() {
        let input = """
        extension Foo {
            public func foo() {}
            public func bar() {}
            var baz: Int { 10 }
            var quux: Int { 5 }
        }
        """

        testFormatting(for: input, rule: FormatRules.extensionAccessControl)
    }

    func testUpdateExtensionVisibilityWithMajorityBodyVisibility() {
        let input = """
        extension Foo {
            public func foo() {}
            public func bar() {}
            public var baz: Int { 10 }
            var quux: Int { 5 }
        }
        """

        let output = """
        public extension Foo {
            func foo() {}
            func bar() {}
            var baz: Int { 10 }
            internal var quux: Int { 5 }
        }
        """

        testFormatting(for: input, output, rule: FormatRules.extensionAccessControl)
    }

    func testDoesntUpdateExtensionVisibilityWhenMajorityBodyVisibilityIsntMostVisible() {
        let input = """
        extension Foo {
            func foo() {}
            func bar() {}
            public var baz: Int { 10 }
        }
        """

        testFormatting(for: input, rule: FormatRules.extensionAccessControl)
    }

    func testDoesntUpdateExtensionVisibilityWithInternalDeclarations() {
        let input = """
        extension Foo {
            func bar() {}
            var baz: Int { 10 }
        }
        """

        testFormatting(for: input, rule: FormatRules.extensionAccessControl)
    }

    func testDoesntUpdateExtensionThatAlreadyHasCorrectVisibilityKeyword() {
        let input = """
        public extension Foo {
            func bar() {}
            func baz() {}
        }
        """

        testFormatting(for: input, rule: FormatRules.extensionAccessControl)
    }

    func testUpdatesExtensionThatHasHigherACLThanBodyDeclarations() {
        let input = """
        public extension Foo {
            fileprivate func bar() {}
            fileprivate func baz() {}
        }
        """

        let output = """
        fileprivate extension Foo {
            func bar() {}
            func baz() {}
        }
        """

        testFormatting(for: input, output, rule: FormatRules.extensionAccessControl,
                       exclude: ["redundantFileprivate"])
    }

    func testDoesntHoistPrivateVisibilityFromExtensionBodyDeclarations() {
        let input = """
        extension Foo {
            private var bar() {}
            private func baz() {}
        }
        """

        testFormatting(for: input, rule: FormatRules.extensionAccessControl)
    }

    func testDoesntUpdatesExtensionThatHasLowerACLThanBodyDeclarations() {
        let input = """
        private extension Foo {
            public var bar() {}
            public func baz() {}
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
            public func baz() {}
        }
        """

        let output = """
        public extension Foo {
            func bar() {}
            func baz() {}
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

    func testDontChangePrivateExtensionToFileprivate() {
        let input = """
        private extension Foo {
            func bar() {}
        }
        """
        testFormatting(for: input, rule: FormatRules.extensionAccessControl)
    }

    func testDontRemoveInternalKeywordFromExtension() {
        let input = """
        internal extension Foo {
            func bar() {}
        }
        """
        testFormatting(for: input, rule: FormatRules.extensionAccessControl)
    }

    func testNoHoistAccessModifierForExtensionThatAddsProtocolConformance() {
        let input = """
        extension Foo: Bar {
            public func bar() {}
        }
        """
        testFormatting(for: input, rule: FormatRules.extensionAccessControl)
    }

    func testProtocolConformanceCheckNotFooledByWhereClause() {
        let input = """
        extension Foo where Self: Bar {
            public func bar() {}
        }
        """
        let output = """
        public extension Foo where Self: Bar {
            func bar() {}
        }
        """
        testFormatting(for: input, output, rule: FormatRules.extensionAccessControl)
    }

    func testAccessNotHoistedIfTypeVisibilityIsLower() {
        let input = """
        class Foo {}

        extension Foo {
            public func bar() {}
        }
        """
        testFormatting(for: input, rule: FormatRules.extensionAccessControl)
    }

    // MARK: markTypes

    func testAddsMarkBeforeTypes() {
        let input = """
        struct Foo {}
        class Bar {}
        enum Baz {}
        protocol Quux {}
        """

        let output = """
        // MARK: - Foo

        struct Foo {}

        // MARK: - Bar

        class Bar {}

        // MARK: - Baz

        enum Baz {}

        // MARK: - Quux

        protocol Quux {}
        """

        testFormatting(for: input, output, rule: FormatRules.markTypes)
    }

    func testDoesntAddMarkBeforeStructWithExistingMark() {
        let input = """
        // MARK: - Foo

        struct Foo {}
        extension Foo {}
        """

        testFormatting(for: input, rule: FormatRules.markTypes)
    }

    func testCorrectsTypoInTypeMark() {
        let input = """
        // mark: foo

        struct Foo {}
        extension Foo {}
        """

        let output = """
        // MARK: - Foo

        struct Foo {}
        extension Foo {}
        """

        testFormatting(for: input, output, rule: FormatRules.markTypes)
    }

    func testUpdatesMarkAfterTypeIsRenamed() {
        let input = """
        // MARK: - FooBarControllerFactory

        struct FooBarControllerBuilder {}
        extension FooBarControllerBuilder {}
        """

        let output = """
        // MARK: - FooBarControllerBuilder

        struct FooBarControllerBuilder {}
        extension FooBarControllerBuilder {}
        """

        testFormatting(for: input, output, rule: FormatRules.markTypes)
    }

    func testAddsMarkBeforeTypeWithDocComment() {
        let input = """
        /// This is a doc comment with several
        /// lines of prose at the start
        ///  - And then, after the prose,
        ///  - a few bullet points just for fun
        actor Foo {}
        extension Foo {}
        """

        let output = """
        // MARK: - Foo

        /// This is a doc comment with several
        /// lines of prose at the start
        ///  - And then, after the prose,
        ///  - a few bullet points just for fun
        actor Foo {}
        extension Foo {}
        """

        testFormatting(for: input, output, rule: FormatRules.markTypes)
    }

    func testCustomTypeMark() {
        let input = """
        struct Foo {}
        extension Foo {}
        """

        let output = """
        // TYPE DEFINITION: Foo

        struct Foo {}
        extension Foo {}
        """

        testFormatting(
            for: input, output, rule: FormatRules.markTypes,
            options: FormatOptions(typeMarkComment: "TYPE DEFINITION: %t")
        )
    }

    func testDoesNothingForExtensionWithoutProtocolConformance() {
        let input = """
        extension Foo {}
        extension Foo {}
        """

        testFormatting(for: input, rule: FormatRules.markTypes)
    }

    func preservesExistingCommentForExtensionWithNoConformances() {
        let input = """
        // MARK: Description of extension

        extension Foo {}
        extension Foo {}
        """

        testFormatting(for: input, rule: FormatRules.markTypes)
    }

    func testAddsMarkCommentForExtensionWithConformance() {
        let input = """
        extension Foo: BarProtocol {}
        extension Foo {}
        """

        let output = """
        // MARK: - Foo + BarProtocol

        extension Foo: BarProtocol {}
        extension Foo {}
        """

        testFormatting(for: input, output, rule: FormatRules.markTypes)
    }

    func testUpdatesExtensionMarkToCorrectMark() {
        let input = """
        // MARK: - BarProtocol

        extension Foo: BarProtocol {}
        extension Foo {}
        """

        let output = """
        // MARK: - Foo + BarProtocol

        extension Foo: BarProtocol {}
        extension Foo {}
        """

        testFormatting(for: input, output, rule: FormatRules.markTypes)
    }

    func testAddsMarkCommentForExtensionWithMultipleConformances() {
        let input = """
        extension Foo: BarProtocol, BazProtocol {}
        extension Foo {}
        """

        let output = """
        // MARK: - Foo + BarProtocol, BazProtocol

        extension Foo: BarProtocol, BazProtocol {}
        extension Foo {}
        """

        testFormatting(for: input, output, rule: FormatRules.markTypes)
    }

    func testUpdatesMarkCommentWithCorrectConformances() {
        let input = """
        // MARK: - Foo + BarProtocol

        extension Foo: BarProtocol, BazProtocol {}
        extension Foo {}
        """

        let output = """
        // MARK: - Foo + BarProtocol, BazProtocol

        extension Foo: BarProtocol, BazProtocol {}
        extension Foo {}
        """

        testFormatting(for: input, output, rule: FormatRules.markTypes)
    }

    func testCustomExtensionMarkComment() {
        let input = """
        struct Foo {}
        extension Foo: BarProtocol {}
        extension String: BarProtocol {}
        """

        let output = """
        // MARK: - Foo

        struct Foo {}

        // EXTENSION: - BarProtocol

        extension Foo: BarProtocol {}

        // EXTENSION: - String: BarProtocol

        extension String: BarProtocol {}
        """

        testFormatting(
            for: input, output, rule: FormatRules.markTypes,
            options: FormatOptions(
                extensionMarkComment: "EXTENSION: - %t: %c",
                groupedExtensionMarkComment: "EXTENSION: - %c"
            )
        )
    }

    func testTypeAndExtensionMarksTogether() {
        let input = """
        struct Foo {}
        extension Foo: Bar {}
        extension String: Bar {}
        """

        let output = """
        // MARK: - Foo

        struct Foo {}

        // MARK: Bar

        extension Foo: Bar {}

        // MARK: - String + Bar

        extension String: Bar {}
        """

        testFormatting(for: input, output, rule: FormatRules.markTypes)
    }

    func testFullyQualifiedTypeNames() {
        let input = """
        extension MyModule.Foo: MyModule.MyNamespace.BarProtocol, QuuxProtocol {}
        extension MyModule.Foo {}
        """

        let output = """
        // MARK: - MyModule.Foo + MyModule.MyNamespace.BarProtocol, QuuxProtocol

        extension MyModule.Foo: MyModule.MyNamespace.BarProtocol, QuuxProtocol {}
        extension MyModule.Foo {}
        """

        testFormatting(for: input, output, rule: FormatRules.markTypes)
    }

    func testWhereClauseConformanceWithExactConstraint() {
        let input = """
        extension Array: BarProtocol where Element == String {}
        extension Array {}
        """

        let output = """
        // MARK: - Array + BarProtocol

        extension Array: BarProtocol where Element == String {}
        extension Array {}
        """

        testFormatting(for: input, output, rule: FormatRules.markTypes)
    }

    func testWhereClauseConformanceWithConformanceConstraint() {
        let input = """
        extension Array: BarProtocol where Element: BarProtocol {}
        extension Array {}
        """

        let output = """
        // MARK: - Array + BarProtocol

        extension Array: BarProtocol where Element: BarProtocol {}
        extension Array {}
        """

        testFormatting(for: input, output, rule: FormatRules.markTypes)
    }

    func testWhereClauseWithExactConstraint() {
        let input = """
        extension Array where Element == String {}
        extension Array {}
        """

        testFormatting(for: input, rule: FormatRules.markTypes)
    }

    func testWhereClauseWithConformanceConstraint() {
        let input = """
        // MARK: [BarProtocol] helpers

        extension Array where Element: BarProtocol {}
        extension Rules {}
        """

        testFormatting(for: input, rule: FormatRules.markTypes)
    }

    func testPlacesMarkAfterImports() {
        let input = """
        import Foundation
        import os

        /// All of SwiftFormat's Rule implementation
        class Rules {}
        extension Rules {}
        """

        let output = """
        import Foundation
        import os

        // MARK: - Rules

        /// All of SwiftFormat's Rule implementation
        class Rules {}
        extension Rules {}
        """

        testFormatting(for: input, output, rule: FormatRules.markTypes)
    }

    func testPlacesMarkAfterFileHeader() {
        let input = """
        //  Created by Nick Lockwood on 12/08/2016.
        //  Copyright 2016 Nick Lockwood

        /// All of SwiftFormat's Rule implementation
        class Rules {}
        extension Rules {}
        """

        let output = """
        //  Created by Nick Lockwood on 12/08/2016.
        //  Copyright 2016 Nick Lockwood

        // MARK: - Rules

        /// All of SwiftFormat's Rule implementation
        class Rules {}
        extension Rules {}
        """

        testFormatting(for: input, output, rule: FormatRules.markTypes)
    }

    func testPlacesMarkAfterFileHeaderAndImports() {
        let input = """
        //  Created by Nick Lockwood on 12/08/2016.
        //  Copyright 2016 Nick Lockwood

        import Foundation
        import os

        /// All of SwiftFormat's Rule implementation
        class Rules {}
        extension Rules {}
        """

        let output = """
        //  Created by Nick Lockwood on 12/08/2016.
        //  Copyright 2016 Nick Lockwood

        import Foundation
        import os

        // MARK: - Rules

        /// All of SwiftFormat's Rule implementation
        class Rules {}
        extension Rules {}
        """

        testFormatting(for: input, output, rule: FormatRules.markTypes)
    }

    func testDoesNothingIfOnlyOneDeclaration() {
        let input = """
        //  Created by Nick Lockwood on 12/08/2016.
        //  Copyright 2016 Nick Lockwood

        import Foundation
        import os

        /// All of SwiftFormat's Rule implementation
        class Rules {}
        """

        testFormatting(for: input, rule: FormatRules.markTypes)
    }

    func testMultipleExtensionsOfSameType() {
        let input = """
        extension Foo: BarProtocol {}
        extension Foo: QuuxProtocol {}
        """

        let output = """
        // MARK: - Foo + BarProtocol

        extension Foo: BarProtocol {}

        // MARK: - Foo + QuuxProtocol

        extension Foo: QuuxProtocol {}
        """

        testFormatting(for: input, output, rule: FormatRules.markTypes)
    }

    func testNeverMarkTypes() {
        let input = """
        struct EmptyFoo {}
        struct EmptyBar { }
        struct EmptyBaz {

        }
        struct Quux {
            let foo = 1
        }
        """

        let options = FormatOptions(markTypes: .never)
        testFormatting(
            for: input, rule: FormatRules.markTypes, options: options,
            exclude: ["emptyBraces", "blankLinesAtStartOfScope", "blankLinesAtEndOfScope", "blankLinesBetweenScopes"]
        )
    }

    func testMarkTypesIfNotEmpty() {
        let input = """
        struct EmptyFoo {}
        struct EmptyBar { }
        struct EmptyBaz {

        }
        struct Quux {
            let foo = 1
        }
        """

        let output = """
        struct EmptyFoo {}
        struct EmptyBar { }
        struct EmptyBaz {

        }

        // MARK: - Quux

        struct Quux {
            let foo = 1
        }
        """

        let options = FormatOptions(markTypes: .ifNotEmpty)
        testFormatting(
            for: input, output, rule: FormatRules.markTypes, options: options,
            exclude: ["emptyBraces", "blankLinesAtStartOfScope", "blankLinesAtEndOfScope", "blankLinesBetweenScopes"]
        )
    }

    func testNeverMarkExtensions() {
        let input = """
        extension EmptyFoo: FooProtocol {}
        extension EmptyBar: BarProtocol { }
        extension EmptyBaz: BazProtocol {

        }
        extension Quux: QuuxProtocol {
            let foo = 1
        }
        """

        let options = FormatOptions(markExtensions: .never)
        testFormatting(
            for: input, rule: FormatRules.markTypes, options: options,
            exclude: ["emptyBraces", "blankLinesAtStartOfScope", "blankLinesAtEndOfScope", "blankLinesBetweenScopes"]
        )
    }

    func testMarkExtensionsIfNotEmpty() {
        let input = """
        extension EmptyFoo: FooProtocol {}
        extension EmptyBar: BarProtocol { }
        extension EmptyBaz: BazProtocol {

        }
        extension Quux: QuuxProtocol {
            let foo = 1
        }
        """

        let output = """
        extension EmptyFoo: FooProtocol {}
        extension EmptyBar: BarProtocol { }
        extension EmptyBaz: BazProtocol {

        }

        // MARK: - Quux + QuuxProtocol

        extension Quux: QuuxProtocol {
            let foo = 1
        }
        """

        let options = FormatOptions(markExtensions: .ifNotEmpty)
        testFormatting(
            for: input, output, rule: FormatRules.markTypes, options: options,
            exclude: ["emptyBraces", "blankLinesAtStartOfScope", "blankLinesAtEndOfScope", "blankLinesBetweenScopes"]
        )
    }

    func testMarkExtensionsDisabled() {
        let input = """
        extension Foo: FooProtocol {}

        // swiftformat:disable markTypes

        extension Bar: BarProtocol {}

        // swiftformat:enable markTypes

        extension Baz: BazProtocol {}

        extension Quux: QuuxProtocol {}
        """

        let output = """
        // MARK: - Foo + FooProtocol

        extension Foo: FooProtocol {}

        // swiftformat:disable markTypes

        extension Bar: BarProtocol {}

        // MARK: - Baz + BazProtocol

        // swiftformat:enable markTypes

        extension Baz: BazProtocol {}

        // MARK: - Quux + QuuxProtocol

        extension Quux: QuuxProtocol {}
        """

        testFormatting(for: input, output, rule: FormatRules.markTypes)
    }

    func testExtensionMarkWithImportOfSameName() {
        let input = """
        import MagazineLayout

        // MARK: - MagazineLayout + FooProtocol

        extension MagazineLayout: FooProtocol {}

        // MARK: - MagazineLayout + BarProtocol

        extension MagazineLayout: BarProtocol {}
        """

        testFormatting(for: input, rule: FormatRules.markTypes)
    }

    func testDoesntUseGroupedMarkTemplateWhenSeparatedByOtherType() {
        let input = """
        // MARK: - MyComponent

        class MyComponent {}

        // MARK: - MyComponentContent

        struct MyComponentContent {}

        // MARK: - MyComponent + ContentConfigurableView

        extension MyComponent: ContentConfigurableView {}
        """

        testFormatting(for: input, rule: FormatRules.markTypes)
    }

    func testUsesGroupedMarkTemplateWhenSeparatedByExtensionOfSameType() {
        let input = """
        // MARK: - MyComponent

        class MyComponent {}

        // MARK: Equatable

        extension MyComponent: Equatable {}

        // MARK: ContentConfigurableView

        extension MyComponent: ContentConfigurableView {}
        """

        testFormatting(for: input, rule: FormatRules.markTypes)
    }

    func testDoesntUseGroupedMarkTemplateWhenSeparatedByExtensionOfOtherType() {
        let input = """
        // MARK: - MyComponent

        class MyComponent {}

        // MARK: - OtherComponent + Equatable

        extension OtherComponent: Equatable {}

        // MARK: - MyComponent + ContentConfigurableView

        extension MyComponent: ContentConfigurableView {}
        """

        testFormatting(for: input, rule: FormatRules.markTypes)
    }

    func testAddsMarkBeforeTypesWithNoBlankLineAfterMark() {
        let input = """
        struct Foo {}
        class Bar {}
        enum Baz {}
        protocol Quux {}
        """

        let output = """
        // MARK: - Foo
        struct Foo {}

        // MARK: - Bar
        class Bar {}

        // MARK: - Baz
        enum Baz {}

        // MARK: - Quux
        protocol Quux {}
        """
        let options = FormatOptions(lineAfterMarks: false)
        testFormatting(for: input, output, rule: FormatRules.markTypes, options: options)
    }

    func testAddsMarkForTypeInExtension() {
        let input = """
        enum Foo {}

        extension Foo {
            struct Bar {
                let baaz: Baaz
            }
        }
        """

        let output = """
        // MARK: - Foo

        enum Foo {}

        // MARK: Foo.Bar

        extension Foo {
            struct Bar {
                let baaz: Baaz
            }
        }
        """

        testFormatting(for: input, output, rule: FormatRules.markTypes)
    }

    func testDoesntAddsMarkForMultipleTypesInExtension() {
        let input = """
        enum Foo {}

        extension Foo {
            struct Bar {
                let baaz: Baaz
            }

            struct Quux {
                let baaz: Baaz
            }
        }
        """

        let output = """
        // MARK: - Foo

        enum Foo {}

        extension Foo {
            struct Bar {
                let baaz: Baaz
            }

            struct Quux {
                let baaz: Baaz
            }
        }
        """

        testFormatting(for: input, output, rule: FormatRules.markTypes)
    }

    func testAddsMarkForTypeInExtensionNotFollowingTypeBeingExtended() {
        let input = """
        struct Baaz {}

        extension Foo {
            struct Bar {
                let baaz: Baaz
            }
        }
        """

        let output = """
        // MARK: - Baaz

        struct Baaz {}

        // MARK: - Foo.Bar

        extension Foo {
            struct Bar {
                let baaz: Baaz
            }
        }
        """

        testFormatting(for: input, output, rule: FormatRules.markTypes)
    }

    func testHandlesMultipleLayersOfExtensionNesting() {
        let input = """
        enum Foo {}

        extension Foo {
            enum Bar {}
        }

        extension Foo {
            extension Bar {
                struct Baaz {
                    let quux: Quux
                }
            }
        }
        """

        let output = """
        // MARK: - Foo

        enum Foo {}

        // MARK: Foo.Bar

        extension Foo {
            enum Bar {}
        }

        // MARK: Foo.Bar.Baaz

        extension Foo {
            extension Bar {
                struct Baaz {
                    let quux: Quux
                }
            }
        }
        """

        testFormatting(for: input, output, rule: FormatRules.markTypes)
    }

    // MARK: - sortedImports

    func testSortedImportsSimpleCase() {
        let input = "import Foo\nimport Bar"
        let output = "import Bar\nimport Foo"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testSortedImportsKeepsPreviousCommentWithImport() {
        let input = "import Foo\n// important comment\n// (very important)\nimport Bar"
        let output = "// important comment\n// (very important)\nimport Bar\nimport Foo"
        testFormatting(for: input, output, rule: FormatRules.sortedImports,
                       exclude: ["blankLineAfterImports"])
    }

    func testSortedImportsKeepsPreviousCommentWithImport2() {
        let input = "// important comment\n// (very important)\nimport Foo\nimport Bar"
        let output = "import Bar\n// important comment\n// (very important)\nimport Foo"
        testFormatting(for: input, output, rule: FormatRules.sortedImports,
                       exclude: ["blankLineAfterImports"])
    }

    func testSortedImportsDoesntMoveHeaderComment() {
        let input = "// header comment\n\nimport Foo\nimport Bar"
        let output = "// header comment\n\nimport Bar\nimport Foo"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testSortedImportsDoesntMoveHeaderCommentFollowedByImportComment() {
        let input = "// header comment\n\n// important comment\nimport Foo\nimport Bar"
        let output = "// header comment\n\nimport Bar\n// important comment\nimport Foo"
        testFormatting(for: input, output, rule: FormatRules.sortedImports,
                       exclude: ["blankLineAfterImports"])
    }

    func testSortedImportsOnSameLine() {
        let input = "import Foo; import Bar\nimport Baz"
        let output = "import Baz\nimport Foo; import Bar"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testSortedImportsWithSemicolonAndCommentOnSameLine() {
        let input = "import Foo; // foobar\nimport Bar\nimport Baz"
        let output = "import Bar\nimport Baz\nimport Foo; // foobar"
        testFormatting(for: input, output, rule: FormatRules.sortedImports, exclude: ["semicolons"])
    }

    func testSortedImportEnum() {
        let input = "import enum Foo.baz\nimport Foo.bar"
        let output = "import Foo.bar\nimport enum Foo.baz"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testSortedImportFunc() {
        let input = "import func Foo.baz\nimport Foo.bar"
        let output = "import Foo.bar\nimport func Foo.baz"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testAlreadySortedImportsDoesNothing() {
        let input = "import Bar\nimport Foo"
        testFormatting(for: input, rule: FormatRules.sortedImports)
    }

    func testPreprocessorSortedImports() {
        let input = "#if os(iOS)\n    import Foo2\n    import Bar2\n#else\n    import Foo1\n    import Bar1\n#endif\nimport Foo3\nimport Bar3"
        let output = "#if os(iOS)\n    import Bar2\n    import Foo2\n#else\n    import Bar1\n    import Foo1\n#endif\nimport Bar3\nimport Foo3"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testTestableSortedImports() {
        let input = "@testable import Foo3\nimport Bar3"
        let output = "import Bar3\n@testable import Foo3"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testLengthSortedImports() {
        let input = "import Foo\nimport Module\nimport Bar3"
        let output = "import Foo\nimport Bar3\nimport Module"
        let options = FormatOptions(importGrouping: .length)
        testFormatting(for: input, output, rule: FormatRules.sortedImports, options: options)
    }

    func testTestableImportsWithTestableOnPreviousLine() {
        let input = "@testable\nimport Foo3\nimport Bar3"
        let output = "import Bar3\n@testable\nimport Foo3"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testTestableImportsWithGroupingTestableBottom() {
        let input = "@testable import Bar\nimport Foo\n@testable import UIKit"
        let output = "import Foo\n@testable import Bar\n@testable import UIKit"
        let options = FormatOptions(importGrouping: .testableLast)
        testFormatting(for: input, output, rule: FormatRules.sortedImports, options: options)
    }

    func testTestableImportsWithGroupingTestableTop() {
        let input = "@testable import Bar\nimport Foo\n@testable import UIKit"
        let output = "@testable import Bar\n@testable import UIKit\nimport Foo"
        let options = FormatOptions(importGrouping: .testableFirst)
        testFormatting(for: input, output, rule: FormatRules.sortedImports, options: options)
    }

    func testCaseInsensitiveSortedImports() {
        let input = "import Zlib\nimport lib"
        let output = "import lib\nimport Zlib"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testCaseInsensitiveCaseDifferingSortedImports() {
        let input = "import c\nimport B\nimport A.a\nimport A.A"
        let output = "import A.A\nimport A.a\nimport B\nimport c"
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testNoDeleteCodeBetweenImports() {
        let input = "import Foo\nfunc bar() {}\nimport Bar"
        testFormatting(for: input, rule: FormatRules.sortedImports,
                       exclude: ["blankLineAfterImports"])
    }

    func testNoDeleteCodeBetweenImports2() {
        let input = "import Foo\nimport Bar\nfoo = bar\nimport Bar"
        let output = "import Bar\nimport Foo\nfoo = bar\nimport Bar"
        testFormatting(for: input, output, rule: FormatRules.sortedImports,
                       exclude: ["blankLineAfterImports"])
    }

    func testNoDeleteCodeBetweenImports3() {
        let input = """
        import Z

        // one

        #if FLAG
            print("hi")
        #endif

        import A
        """
        testFormatting(for: input, rule: FormatRules.sortedImports)
    }

    func testSortContiguousImports() {
        let input = "import Foo\nimport Bar\nfunc bar() {}\nimport Quux\nimport Baz"
        let output = "import Bar\nimport Foo\nfunc bar() {}\nimport Baz\nimport Quux"
        testFormatting(for: input, output, rule: FormatRules.sortedImports,
                       exclude: ["blankLineAfterImports"])
    }

    func testNoMangleImportsPrecededByComment() {
        let input = """
        // evil comment

        #if canImport(Foundation)
            import Foundation
            #if canImport(UIKit) && canImport(AVFoundation)
                import UIKit
                import AVFoundation
            #endif
        #endif
        """
        let output = """
        // evil comment

        #if canImport(Foundation)
            import Foundation
            #if canImport(UIKit) && canImport(AVFoundation)
                import AVFoundation
                import UIKit
            #endif
        #endif
        """
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    func testNoMangleFileHeaderNotFollowedByLinebreak() {
        let input = """
        //
        //  Code.swift
        //  Module
        //
        //  Created by Someone on 4/30/20.
        //
        import AModuleUI
        import AModule
        import AModuleHelper
        import SomeOtherModule
        """
        let output = """
        //
        //  Code.swift
        //  Module
        //
        //  Created by Someone on 4/30/20.
        //
        import AModule
        import AModuleHelper
        import AModuleUI
        import SomeOtherModule
        """
        testFormatting(for: input, output, rule: FormatRules.sortedImports)
    }

    // MARK: - sortedSwitchCases

    func testSortedSwitchCaseNestedSwitchOneCaseDoesNothing() {
        let input = """
        switch result {
        case let .success(value):
            switch result {
            case .success:
                print("success")
            case .value:
                print("value")
            }
        case .failure:
            guard self.bar else {
                print(self.bar)
                return
            }
            print(self.bar)
        }
        """

        testFormatting(for: input, rule: FormatRules.sortedSwitchCases, exclude: ["redundantSelf"])
    }

    func testSortedSwitchCaseMultilineWithOneComment() {
        let input = """
        switch self {
        case let .type, // something
             let .conditionalCompilation:
            break
        }
        """
        let output = """
        switch self {
        case let .conditionalCompilation,
             let .type: // something
            break
        }
        """
        testFormatting(for: input, output, rule: FormatRules.sortedSwitchCases)
    }

    func testSortedSwitchCaseMultilineWithComments() {
        let input = """
        switch self {
        case let .type, // typeComment
             let .conditionalCompilation: // conditionalCompilationComment
            break
        }
        """
        let output = """
        switch self {
        case let .conditionalCompilation, // conditionalCompilationComment
             let .type: // typeComment
            break
        }
        """
        testFormatting(for: input, output, rule: FormatRules.sortedSwitchCases, exclude: ["indent"])
    }

    func testSortedSwitchCaseMultilineWithCommentsAndMoreThanOneCasePerLine() {
        let input = """
        switch self {
        case let .type, // typeComment
             let .type1, .type2,
             let .conditionalCompilation: // conditionalCompilationComment
            break
        }
        """
        let output = """
        switch self {
        case let .conditionalCompilation, // conditionalCompilationComment
             let .type, // typeComment
             let .type1,
             .type2:
            break
        }
        """
        testFormatting(for: input, output, rule: FormatRules.sortedSwitchCases)
    }

    func testSortedSwitchCaseMultiline() {
        let input = """
        switch self {
        case let .type,
             let .conditionalCompilation:
            break
        }
        """
        let output = """
        switch self {
        case let .conditionalCompilation,
             let .type:
            break
        }
        """
        testFormatting(for: input, output, rule: FormatRules.sortedSwitchCases)
    }

    func testSortedSwitchCaseMultipleAssociatedValues() {
        let input = """
        switch self {
        case let .b(whatever, whatever2), .a(whatever):
            break
        }
        """
        let output = """
        switch self {
        case .a(whatever), let .b(whatever, whatever2):
            break
        }
        """
        testFormatting(for: input, output, rule: FormatRules.sortedSwitchCases,
                       exclude: ["wrapSwitchCases"])
    }

    func testSortedSwitchCaseOneLineWithoutSpaces() {
        let input = """
        switch self {
        case .b,.a:
            break
        }
        """
        let output = """
        switch self {
        case .a,.b:
            break
        }
        """
        testFormatting(for: input, output, rule: FormatRules.sortedSwitchCases,
                       exclude: ["wrapSwitchCases", "spaceAroundOperators"])
    }

    func testSortedSwitchCaseLet() {
        let input = """
        switch self {
        case let .b(whatever), .a(whatever):
            break
        }
        """
        let output = """
        switch self {
        case .a(whatever), let .b(whatever):
            break
        }
        """
        testFormatting(for: input, output, rule: FormatRules.sortedSwitchCases,
                       exclude: ["wrapSwitchCases"])
    }

    func testSortedSwitchCaseOneCaseDoesNothing() {
        let input = """
        switch self {
        case "a":
            break
        }
        """
        testFormatting(for: input, rule: FormatRules.sortedSwitchCases)
    }

    func testSortedSwitchStrings() {
        let input = """
        switch self {
        case "GET", "POST", "PUT", "DELETE":
            break
        }
        """
        let output = """
        switch self {
        case "DELETE", "GET", "POST", "PUT":
            break
        }
        """
        testFormatting(for: input, output, rule: FormatRules.sortedSwitchCases,
                       exclude: ["wrapSwitchCases"])
    }

    func testSortedSwitchWhereConditionNotLastCase() {
        let input = """
        switch self {
        case .b, .c, .a where isTrue:
            break
        }
        """
        testFormatting(for: input,
                       rule: FormatRules.sortedSwitchCases,
                       exclude: ["wrapSwitchCases"])
    }

    func testSortedSwitchWhereConditionLastCase() {
        let input = """
        switch self {
        case .b, .c where isTrue, .a:
            break
        }
        """
        let output = """
        switch self {
        case .a, .b, .c where isTrue:
            break
        }
        """
        testFormatting(for: input, output, rule: FormatRules.sortedSwitchCases,
                       exclude: ["wrapSwitchCases"])
    }

    func testSortNumericSwitchCases() {
        let input = """
        switch foo {
        case 12, 3, 5, 7, 8, 10, 1:
            break
        }
        """
        let output = """
        switch foo {
        case 1, 3, 5, 7, 8, 10, 12:
            break
        }
        """
        testFormatting(for: input, output, rule: FormatRules.sortedSwitchCases,
                       exclude: ["wrapSwitchCases"])
    }

    func testSortedSwitchTuples() {
        let input = """
        switch foo {
        case (.foo, _),
             (.bar, _),
             (.baz, _),
             (_, .foo):
        }
        """
        let output = """
        switch foo {
        case (_, .foo),
             (.bar, _),
             (.baz, _),
             (.foo, _):
        }
        """
        testFormatting(for: input, output, rule: FormatRules.sortedSwitchCases)
    }

    func testSortedSwitchTuples2() {
        let input = """
        switch self {
        case (.quux, .bar),
             (_, .foo),
             (_, .bar),
             (_, .baz),
             (.foo, .bar):
        }
        """
        let output = """
        switch self {
        case (_, .bar),
             (_, .baz),
             (_, .foo),
             (.foo, .bar),
             (.quux, .bar):
        }
        """
        testFormatting(for: input, output, rule: FormatRules.sortedSwitchCases)
    }

    func testSortedSwitchCasesShortestFirst() {
        let input = """
        switch foo {
        case let .fooAndBar(baz, quux),
             let .foo(baz):
        }
        """
        let output = """
        switch foo {
        case let .foo(baz),
             let .fooAndBar(baz, quux):
        }
        """
        testFormatting(for: input, output, rule: FormatRules.sortedSwitchCases)
    }

    func testSortHexLiteralCasesInAscendingOrder() {
        let input = """
        switch value {
        case 0x30 ... 0x39, // 0-9
             0x0300 ... 0x036F,
             0x1DC0 ... 0x1DFF,
             0x20D0 ... 0x20FF,
             0xFE20 ... 0xFE2F:
            return true
        default:
            return false
        }
        """
        testFormatting(for: input, rule: FormatRules.sortedSwitchCases)
    }

    func testMixedOctalHexIntAndBinaryLiteralCasesInAscendingOrder() {
        let input = """
        switch value {
        case 0o3,
             0x20,
             110,
             0b1111110:
            return true
        default:
            return false
        }
        """
        testFormatting(for: input, rule: FormatRules.sortedSwitchCases)
    }

    // MARK: - modifierOrder

    func testVarModifiersCorrected() {
        let input = "unowned private static var foo"
        let output = "private unowned static var foo"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: FormatRules.modifierOrder, options: options)
    }

    func testPrivateSetModifierNotMangled() {
        let input = "private(set) public weak lazy var foo"
        let output = "public private(set) lazy weak var foo"
        testFormatting(for: input, output, rule: FormatRules.modifierOrder)
    }

    func testUnownedUnsafeModifierNotMangled() {
        let input = "unowned(unsafe) lazy var foo"
        let output = "lazy unowned(unsafe) var foo"
        testFormatting(for: input, output, rule: FormatRules.modifierOrder)
    }

    func testPrivateRequiredStaticFuncModifiers() {
        let input = "required static private func foo()"
        let output = "private required static func foo()"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: FormatRules.modifierOrder, options: options)
    }

    func testPrivateConvenienceInit() {
        let input = "convenience private init()"
        let output = "private convenience init()"
        testFormatting(for: input, output, rule: FormatRules.modifierOrder)
    }

    func testSpaceInModifiersLeftIntact() {
        let input = "weak private(set) /* read-only */\npublic var"
        let output = "public private(set) /* read-only */\nweak var"
        testFormatting(for: input, output, rule: FormatRules.modifierOrder)
    }

    func testPrefixModifier() {
        let input = "prefix public static func - (rhs: Foo) -> Foo"
        let output = "public static prefix func - (rhs: Foo) -> Foo"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: FormatRules.modifierOrder, options: options)
    }

    func testModifierOrder() {
        let input = "override public var foo: Int { 5 }"
        let output = "public override var foo: Int { 5 }"
        let options = FormatOptions(modifierOrder: ["public", "override"])
        testFormatting(for: input, output, rule: FormatRules.modifierOrder, options: options)
    }

    func testNoConfusePostfixIdentifierWithKeyword() {
        let input = "var foo = .postfix\noverride init() {}"
        testFormatting(for: input, rule: FormatRules.modifierOrder)
    }

    func testNoConfusePostfixIdentifierWithKeyword2() {
        let input = "var foo = postfix\noverride init() {}"
        testFormatting(for: input, rule: FormatRules.modifierOrder)
    }

    func testNoConfuseCaseWithModifier() {
        let input = """
        enum Foo {
            case strong
            case weak
            public init() {}
        }
        """
        testFormatting(for: input, rule: FormatRules.modifierOrder)
    }

    // MARK: - sortDeclarations

    func testSortEnumBody() {
        let input = """
        // swiftformat:sort
        enum FeatureFlags {
            case upsellB
            case fooFeature(
                fooConfiguration: Foo,
                barConfiguration: Bar
            )
            case barFeature // Trailing comment -- bar feature
            /// Leading comment -- upsell A
            case upsellA(
                fooConfiguration: Foo,
                barConfiguration: Bar
            )
        }

        enum NextType {
            case foo
            case bar
        }
        """

        let output = """
        // swiftformat:sort
        enum FeatureFlags {
            case barFeature // Trailing comment -- bar feature
            case fooFeature(
                fooConfiguration: Foo,
                barConfiguration: Bar
            )
            /// Leading comment -- upsell A
            case upsellA(
                fooConfiguration: Foo,
                barConfiguration: Bar
            )
            case upsellB
        }

        enum NextType {
            case foo
            case bar
        }
        """

        testFormatting(for: input, output, rule: FormatRules.sortDeclarations)
    }

    func testSortEnumBodyWithOnlyOneCase() {
        let input = """
        // swiftformat:sort
        enum FeatureFlags {
            case upsellB
        }
        """

        testFormatting(for: input, rule: FormatRules.sortDeclarations)
    }

    func testSortEnumBodyWithoutCase() {
        let input = """
        // swiftformat:sort
        enum FeatureFlags {}
        """

        testFormatting(for: input, rule: FormatRules.sortDeclarations)
    }

    func testNoSortUnannotatedType() {
        let input = """
        enum FeatureFlags {
            case upsellB
            case fooFeature
            case barFeature
            case upsellA
        }
        """

        testFormatting(for: input, rule: FormatRules.sortDeclarations)
    }

    func testPreservesSortedBody() {
        let input = """
        // swiftformat:sort
        enum FeatureFlags {
            case barFeature
            case fooFeature
            case upsellA
            case upsellB
        }
        """

        testFormatting(for: input, rule: FormatRules.sortDeclarations)
    }

    func testTypeBodyWithBlankLines() {
        let input = """
        // swiftformat:sort
        enum FeatureFlags {

            case upsellB

            case fooFeature

            case barFeature

            case upsellA

        }
        """

        let output = """
        // swiftformat:sort
        enum FeatureFlags {

            case barFeature

            case fooFeature

            case upsellA

            case upsellB

        }
        """

        testFormatting(for: input, output, rule: FormatRules.sortDeclarations, exclude: ["blankLinesAtStartOfScope", "blankLinesAtEndOfScope"])
    }

    func testSortClassWithMixedDeclarationTypes() {
        let input = """
        // swiftformat:sort
        class Foo {
            let quuxProperty = Quux()
            let barProperty = Bar()

            var fooComputedProperty: Foo {
                Foo()
            }

            func baazFunction() -> Baaz {
                Baaz()
            }
        }
        """

        let output = """
        // swiftformat:sort
        class Foo {
            func baazFunction() -> Baaz {
                Baaz()
            }
            let barProperty = Bar()

            var fooComputedProperty: Foo {
                Foo()
            }

            let quuxProperty = Quux()
        }
        """

        testFormatting(for: input, [output],
                       rules: [FormatRules.sortDeclarations, FormatRules.consecutiveBlankLines],
                       exclude: ["blankLinesBetweenScopes"])
    }

    func testSortBetweenDirectiveCommentsInType() {
        let input = """
        enum FeatureFlags {
            // swiftformat:sort:begin
            case upsellB
            case fooFeature
            case barFeature
            case upsellA
            // swiftformat:sort:end

            var anUnsortedProperty: Foo {
                Foo()
            }
        }
        """

        let output = """
        enum FeatureFlags {
            // swiftformat:sort:begin
            case barFeature
            case fooFeature
            case upsellA
            case upsellB
            // swiftformat:sort:end

            var anUnsortedProperty: Foo {
                Foo()
            }
        }
        """

        testFormatting(for: input, output, rule: FormatRules.sortDeclarations)
    }

    func testSortTopLevelDeclarations() {
        let input = """
        let anUnsortedGlobal = 0

        // swiftformat:sort:begin
        let sortThisGlobal = 1
        public let thisGlobalIsSorted = 2
        private let anotherSortedGlobal = 5
        let sortAllOfThem = 8
        // swiftformat:sort:end

        let anotherUnsortedGlobal = 9
        """

        let output = """
        let anUnsortedGlobal = 0

        // swiftformat:sort:begin
        private let anotherSortedGlobal = 5
        let sortAllOfThem = 8
        let sortThisGlobal = 1
        public let thisGlobalIsSorted = 2
        // swiftformat:sort:end

        let anotherUnsortedGlobal = 9
        """

        testFormatting(for: input, output, rule: FormatRules.sortDeclarations)
    }

    func testDoesntConflictWithOrganizeDeclarations() {
        let input = """
        // swiftformat:sort
        enum FeatureFlags {
            case barFeature
            case fooFeature
            case upsellA
            case upsellB

            // MARK: Internal

            var anUnsortedProperty: Foo {
                Foo()
            }

            var unsortedProperty: Foo {
                Foo()
            }
        }
        """

        testFormatting(for: input, rule: FormatRules.organizeDeclarations)
    }

    func testSortsWithinOrganizeDeclarations() {
        let input = """
        // swiftformat:sort
        enum FeatureFlags {
            case fooFeature
            case barFeature
            case upsellB
            case upsellA

            // MARK: Internal

            var sortedProperty: Foo {
                Foo()
            }

            var aSortedProperty: Foo {
                Foo()
            }
        }
        """

        let output = """
        // swiftformat:sort
        enum FeatureFlags {
            case barFeature
            case fooFeature
            case upsellA

            case upsellB

            // MARK: Internal

            var aSortedProperty: Foo {
                Foo()
            }

            var sortedProperty: Foo {
                Foo()
            }

        }
        """

        testFormatting(for: input, [output],
                       rules: [FormatRules.organizeDeclarations, FormatRules.blankLinesBetweenScopes],
                       exclude: ["blankLinesAtEndOfScope"])
    }

    func testSortDeclarationsUsesLocalizedCompare() {
        let input = """
        // swiftformat:sort
        enum FeatureFlags {
            case upsella
            case upsellA
            case upsellb
            case upsellB
        }
        """

        testFormatting(for: input, rule: FormatRules.sortDeclarations)
    }

    func testOrganizeDeclarationsSortUsesLocalizedCompare() {
        let input = """
        // swiftformat:sort
        enum FeatureFlags {
            case upsella
            case upsellA
            case upsellb
            case upsellB
        }
        """

        testFormatting(for: input, rule: FormatRules.organizeDeclarations)
    }
}
