//
//  OrganizeDeclarationsTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 8/16/20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class OrganizeDeclarationsTests: XCTestCase {
    func testOrganizeClassDeclarationsIntoCategories() {
        let input = """
        public class Foo {
            private func privateMethod() {}

            private let bar = 1
            public let baz = 1
            open var quack = 2
            package func packageMethod() {}
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

            #if DEBUG
                private var foo: Foo? { nil }
            #endif
        }

        enum Bar {
            private var bar: Bar { Bar() }
            case enumCase
        }
        """

        let output = """
        public class Foo {

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

            // MARK: Package

            package func packageMethod() {}

            // MARK: Internal

            var quux = 2

            /// `open` is the only visibility keyword that
            /// can also be used as an identifier.
            var open = 10

            // MARK: Private

            private let bar = 1

            #if DEBUG
                private var foo: Foo? { nil }
            #endif

            private func privateMethod() {}

        }

        enum Bar {
            case enumCase

            // MARK: Private

            private var bar: Bar { Bar() }
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .wrapPropertyBodies]
        )
    }

    func testOrganizeClassDeclarationsIntoCategoriesWithCustomTypeOrder() {
        let input = """
        public class Foo {
            private func privateMethod() {}

            private let bar = 1
            public let baz = 1
            open var quack = 2
            package func packageMethod() {}
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

            #if DEBUG
                private var foo: Foo? { nil }
            #endif
        }

        enum Bar {
            private var bar: Bar { Bar() }
            case enumCase
        }
        """

        let output = """
        public class Foo {

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

            // MARK: Package

            package func packageMethod() {}

            // MARK: Internal

            var quux = 2

            /// `open` is the only visibility keyword that
            /// can also be used as an identifier.
            var open = 10

            // MARK: Private

            private let bar = 1

            #if DEBUG
                private var foo: Foo? { nil }
            #endif

            private func privateMethod() {}

        }

        enum Bar {
            case enumCase

            // MARK: Private

            private var bar: Bar { Bar() }
        }
        """

        // The configuration used in Airbnb's Swift Style Guide,
        // as defined here: https://github.com/airbnb/swift#subsection-organization
        let airbnbVisibilityOrder = """
        beforeMarks,instanceLifecycle,open,public,package,internal,private,fileprivate
        """
        let airbnbTypeOrder = """
        nestedType,staticProperty,staticPropertyWithBody,classPropertyWithBody,instanceProperty,instancePropertyWithBody,staticMethod,classMethod,instanceMethod
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                visibilityOrder: airbnbVisibilityOrder.components(separatedBy: ","),
                typeOrder: airbnbTypeOrder.components(separatedBy: ",")
            ),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .wrapPropertyBodies]
        )
    }

    func testOrganizeClassDeclarationsIntoCategoriesInTypeOrder() {
        let input = """
        public class Foo {
            private func privateMethod() {}

            private let bar = 1
            public let baz = 1
            open var quack = 2
            package func packageMethod() {}
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
        public class Foo {

            // MARK: Properties

            open var quack = 2

            public let baz = 1

            var quux = 2

            /// `open` is the only visibility keyword that
            /// can also be used as an identifier.
            var open = 10

            private let bar = 1

            // MARK: Lifecycle

            /*
             * Block comment
             */

            init() {}

            // MARK: Functions

            /// Doc comment
            public func publicMethod() {}

            package func packageMethod() {}

            private func privateMethod() {}

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(categoryMarkComment: "MARK: %c", organizationMode: .type),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope]
        )
    }

    func testOrganizeTypeWithOverridenFieldsInVisibilityOrder() {
        let input = """
        class Test {

            override var b: Any? { nil }

            var a = ""

            override func bar() -> Bar {
                Bar()
            }

            func foo() -> Foo {
                Foo()
            }

            func baaz() -> Baaz {
                Baaz()
            }

        }
        """

        testFormatting(
            for: input, rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .sortImports, .wrapPropertyBodies]
        )
    }

    func testOrganizeTypeWithOverridenFieldsInTypeOrder() {
        let input = """
        class Test {

            var a = ""

            override var b: Any? { nil }

            func foo() -> Foo {
                Foo()
            }

            override func bar() -> Bar {
                Bar()
            }

            func baaz() -> Baaz {
                Baaz()
            }

        }
        """

        let output = """
        class Test {

            // MARK: Overridden Properties

            override var b: Any? { nil }

            // MARK: Properties

            var a = ""

            // MARK: Overridden Functions

            override func bar() -> Bar {
                Bar()
            }

            // MARK: Functions

            func foo() -> Foo {
                Foo()
            }

            func baaz() -> Baaz {
                Baaz()
            }

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(organizationMode: .type),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .sortImports, .wrapPropertyBodies]
        )
    }

    func testOrganizeTypeWithSwiftUIMethodInVisibilityOrder() {
        let input = """
        class Test {

            func bar() -> some View {
                EmptyView()
            }

            func foo() -> Foo {
                Foo()
            }

            func baaz() -> Baaz {
                Baaz()
            }

        }
        """

        testFormatting(
            for: input, rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .sortImports]
        )
    }

    func testOrganizeSwiftUIViewInTypeOrder() {
        let input = """
        struct ContentView: View {

            private var label: String

            @State
            var isOn: Bool = false

            @ViewBuilder
            private var toggle: some View {
                Toggle(label, isOn: $isOn)
                    .fixedSize()
            }

            init(label: String) {
                self.label = label
            }

            @ViewBuilder
            var body: some View {
                toggle
            }
        }
        """

        let output = """
        struct ContentView: View {

            // MARK: SwiftUI Properties

            @State
            var isOn: Bool = false

            // MARK: Properties

            private var label: String

            // MARK: Lifecycle

            init(label: String) {
                self.label = label
            }

            // MARK: Content Properties

            @ViewBuilder
            var body: some View {
                toggle
            }

            @ViewBuilder
            private var toggle: some View {
                Toggle(label, isOn: $isOn)
                    .fixedSize()
            }

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(categoryMarkComment: "MARK: %c", organizationMode: .type),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .privateStateVariables, .redundantViewBuilder]
        )
    }

    func testOrganizeSwiftUIViewModifierInTypeOrder() {
        let input = """
        struct Modifier: ViewModifier {

            private var label: String

            @State
            var isOn: Bool = false

            @ViewBuilder
            private var toggle: some View {
                Toggle(label, isOn: $isOn)
                    .fixedSize()
            }

            func body(content: Content) -> some View {
                content
                    .overlay {
                        toggle
                    }
            }

            init(label: String) {
                self.label = label
            }
        }
        """

        let output = """
        struct Modifier: ViewModifier {

            // MARK: SwiftUI Properties

            @State
            var isOn: Bool = false

            // MARK: Properties

            private var label: String

            // MARK: Lifecycle

            init(label: String) {
                self.label = label
            }

            // MARK: Content Properties

            @ViewBuilder
            private var toggle: some View {
                Toggle(label, isOn: $isOn)
                    .fixedSize()
            }

            // MARK: Content Methods

            func body(content: Content) -> some View {
                content
                    .overlay {
                        toggle
                    }
            }

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(categoryMarkComment: "MARK: %c", organizationMode: .type),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .privateStateVariables, .redundantViewBuilder]
        )
    }

    func testCustomOrganizationInVisibilityOrder() {
        let input = """
        public class Foo {
            public func bar() {}
            func baz() {}
            private func quux() {}
        }
        """

        let output = """
        public class Foo {

            // MARK: Private

            private func quux() {}

            // MARK: Internal

            func baz() {}

            // MARK: Public

            public func bar() {}
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                visibilityOrder: ["private", "internal", "public"],
                typeOrder: DeclarationType.allCases.map(\.rawValue)
            ),
            exclude: [.blankLinesAtStartOfScope, .privateStateVariables]
        )
    }

    func testCustomOrganizationInVisibilityOrderWithParametrizedTypeOrder() {
        let input = """
        public class Foo {

            // MARK: Private

            private func quux() {}

            // MARK: Internal

            var baaz: Baaz

            func baz() {}

            // MARK: Public

            public func bar() {}
        }
        """

        let output = """
        public class Foo {

            // MARK: Private

            private func quux() {}

            // MARK: Internal

            func baz() {}

            var baaz: Baaz

            // MARK: Public

            public func bar() {}
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                visibilityOrder: ["private", "internal", "public"],
                typeOrder: ["beforeMarks", "nestedType", "instanceLifecycle", "instanceMethod", "instanceProperty"]
            ),
            exclude: [.blankLinesAtStartOfScope]
        )
    }

    func testCustomOrganizationInTypeOrder() {
        let input = """
        public class Foo {
            private func quux() {}
            var baaz: Baaz
            func baz() {}
            init()
            override public func baar()
            public func bar() {}
        }
        """

        let output = """
        public class Foo {

            // MARK: Lifecycle

            init()

            // MARK: Functions

            public func bar() {}

            func baz() {}

            private func quux() {}

            // MARK: Properties

            var baaz: Baaz

            // MARK: Overridden Functions

            override public func baar()
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                organizationMode: .type,
                typeOrder: ["beforeMarks", "instanceLifecycle", "instanceMethod", "nestedType", "instanceProperty", "overriddenMethod"]
            ),
            exclude: [.blankLinesAtStartOfScope]
        )
    }

    func testOrganizeDeclarationsIgnoresNotDefinedCategories() {
        let input = """
        public class Foo {
            private func quux() {}
            var baaz: Baaz
            func baz() {}
            init()
            override public func baar()
            public func bar() {}
        }
        """

        let output = """
        public class Foo {

            // MARK: Lifecycle

            init()

            // MARK: Functions

            override public func baar()
            public func bar() {}

            func baz() {}

            private func quux() {}

            // MARK: Properties

            var baaz: Baaz
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                organizationMode: .type,
                typeOrder: ["beforeMarks", "nestedType", "instanceLifecycle", "instanceMethod", "instanceProperty"]
            ),
            exclude: [.blankLinesAtStartOfScope]
        )
    }

    func testCustomOrganizationInTypeOrderWithParametrizedVisibilityOrder() {
        let input = """
        public class Foo {
            private func quux() {}
            var baaz: Baaz
            private var fooo: Fooo
            func baz() {}
            init()
            override public func baar()
            public func bar() {}
        }
        """

        let output = """
        public class Foo {

            // MARK: Lifecycle

            init()

            // MARK: Functions

            private func quux() {}

            func baz() {}

            public func bar() {}

            // MARK: Properties

            private var fooo: Fooo

            var baaz: Baaz

            // MARK: Overridden Functions

            override public func baar()
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                organizationMode: .type,
                visibilityOrder: ["private", "internal", "public"],
                typeOrder: ["beforeMarks", "nestedType", "instanceLifecycle", "instanceMethod", "instanceProperty", "overriddenMethod"]
            ),
            exclude: [.blankLinesAtStartOfScope]
        )
    }

    func testCustomDeclarationTypeUsedAsTopLevelCategory() {
        let input = """
        class Test {
            private let foo = "foo"
            func bar() {}
        }
        """

        let output = """
        class Test {

            // MARK: Functions

            func bar() {}

            // MARK: Private

            private let foo = "foo"
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                organizationMode: .visibility,
                visibilityOrder: ["instanceMethod"] + Visibility.allCases.map(\.rawValue),
                typeOrder: DeclarationType.allCases.map(\.rawValue).filter { $0 != "instanceMethod" }
            ),
            exclude: [.blankLinesAtStartOfScope]
        )
    }

    func testVisibilityModeWithoutInstanceLifecycle() {
        let input = """
        class Test {
            init() {}
            private func bar() {}
        }
        """

        let output = """
        class Test {

            // MARK: Internal

            init() {}

            // MARK: Private

            private func bar() {}
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                organizationMode: .visibility,
                visibilityOrder: Visibility.allCases.map(\.rawValue),
                typeOrder: DeclarationType.allCases.map(\.rawValue)
            ),
            exclude: [.blankLinesAtStartOfScope]
        )
    }

    func testCustomCategoryNamesInVisibilityOrder() {
        let input = """
        public class Foo {
            public var bar: Bar
            init(bar: Bar) {
                self.bar = bar
            }
            func baaz() {}
        }
        """

        let output = """
        public class Foo {

            // MARK: Init

            init(bar: Bar) {
                self.bar = bar
            }

            // MARK: Public_Group

            public var bar: Bar

            // MARK: Internal

            func baaz() {}
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                organizationMode: .visibility,
                customVisibilityMarks: ["instanceLifecycle:Init", "public:Public_Group"]
            ),
            exclude: [.blankLinesAtStartOfScope]
        )
    }

    func testCustomCategoryNamesInTypeOrder() {
        let input = """
        public class Foo {
            public var bar: Bar
            init(bar: Bar) {
                self.bar = bar
            }
            func baaz() {}
        }
        """

        let output = """
        public class Foo {

            // MARK: Bar_Bar

            public var bar: Bar

            // MARK: Init

            init(bar: Bar) {
                self.bar = bar
            }

            // MARK: Buuuz Lightyeeeaaar

            func baaz() {}
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                organizationMode: .type,
                customTypeMarks: ["instanceLifecycle:Init", "instanceProperty:Bar_Bar", "instanceMethod:Buuuz Lightyeeeaaar"]
            ),
            exclude: [.blankLinesAtStartOfScope]
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
            rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope, .enumNamespaces]
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
            rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope]
        )
    }

    func testOrganizePrivateSet() {
        let input = """
        public class Foo {
            public private(set) var bar: Int
            private(set) var baz: Int
            internal private(set) var baz: Int
        }
        """

        let output = """
        public class Foo {

            // MARK: Public

            public private(set) var bar: Int

            // MARK: Internal

            private(set) var baz: Int
            internal private(set) var baz: Int
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope, .redundantInternal]
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
            rule: .organizeDeclarations,
            exclude: [.blankLinesAtEndOfScope, .redundantType, .redundantClosure]
        )
    }

    func testSortDeclarationTypesByType() {
        let input = """
        class Foo {
            var a: Int
            init(a: Int) {
                self.a = a
            }
            private convenience init() {
                self.init(a: 0)
            }

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

            // MARK: Nested Types

            typealias Bar = Int

            enum NestedEnum {}

            // MARK: Static Properties

            static var a1: Int = 1
            static var a2: Int = 2

            // MARK: Static Computed Properties

            static var b1: String {
                "static computed property"
            }

            // MARK: Class Properties

            class var b2: String {
                "class computed property"
            }

            // MARK: Properties

            var a: Int
            let c: String = String {
                "closure body"
            }()

            var d2: CGFloat = 3.141592653589 {
                didSet {}
            }

            // MARK: Computed Properties

            var d1: CGFloat {
                3.141592653589
            }

            // MARK: Lifecycle

            init(a: Int) {
                self.a = a
            }

            private convenience init() {
                self.init(a: 0)
            }

            // MARK: Static Functions

            static func e() {}

            // MARK: Class Functions

            class func f() -> Foo {
                Foo()
            }

            // MARK: Functions

            func g() -> Int {
                10
            }

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(categoryMarkComment: "MARK: %c", organizationMode: .type),
            exclude: [.blankLinesAtEndOfScope, .blankLinesAtStartOfScope, .redundantType, .redundantClosure]
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
            rule: .organizeDeclarations,
            exclude: [.blankLinesAtEndOfScope, .unusedArguments]
        )
    }

    func testPlacingCustomDeclarationsBeforeMarks() {
        let input = """
        public struct Foo {

            public init() {}

            public typealias Bar = Int

            public struct Baz {}

        }
        """

        let output = """
        public struct Foo {

            public typealias Bar = Int

            public struct Baz {}

            // MARK: Lifecycle

            public init() {}

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(beforeMarks: ["typealias", "struct"]),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope]
        )
    }

    func testCustomLifecycleMethods() {
        let input = """
        public class ViewController: UIViewController {

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
        public class ViewController: UIViewController {

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
            rule: .organizeDeclarations,
            options: FormatOptions(lifecycleMethods: ["viewDidLoad", "viewWillAppear", "viewDidAppear"]),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope]
        )
    }

    func testCustomCategoryMarkTemplate() {
        let input = """
        public struct Foo {
            public init() {}
            public func publicInstanceMethod() {}
        }
        """

        let output = """
        public struct Foo {

            // - Lifecycle

            public init() {}

            // - Public

            public func publicInstanceMethod() {}
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(categoryMarkComment: "- %c"),
            exclude: [.blankLinesAtStartOfScope]
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
            rule: .organizeDeclarations,
            options: FormatOptions(organizeStructThreshold: 2)
        )
    }

    func testAboveCustomStructOrganizationThreshold() {
        let input = """
        public struct StructAboveThreshold {
            init() {}
            public func instanceMethod() {}
        }
        """

        let output = """
        public struct StructAboveThreshold {

            // MARK: Lifecycle

            init() {}

            // MARK: Public

            public func instanceMethod() {}
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(organizeStructThreshold: 2),
            exclude: [.blankLinesAtStartOfScope]
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
            rule: .organizeDeclarations,
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
            rule: .organizeDeclarations,
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
            rule: .organizeDeclarations,
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
            rule: .organizeDeclarations,
            options: FormatOptions(
                organizeTypes: ["class", "struct", "enum", "extension"],
                organizeExtensionThreshold: 2
            ), exclude: [.blankLinesAtStartOfScope]
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
        testFormatting(for: input, rule: .organizeDeclarations,
                       exclude: [.blankLinesAtStartOfScope])
    }

    func testUpdatesMalformedMarks() {
        let input = """
        public actor Foo {

            // MARK: lifecycle

            // MARK: Lifeycle

            init() {}

            // mark: Public

            // mark - Public

            public func bar() {}

            // MARK: - Internal

            func baz() {}

            // mrak: privat

            // Pulse

            private func quux() {}
        }
        """

        let output = """
        public actor Foo {

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

        testFormatting(for: input, output, rule: .organizeDeclarations,
                       exclude: [.blankLinesAtStartOfScope])
    }

    func testDoesntAttemptToUpdateMarksNotAtTopLevel() {
        let input = """
        public class Foo {

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

        testFormatting(for: input, rule: .organizeDeclarations,
                       exclude: [.blankLinesAtStartOfScope, .docCommentsBeforeModifiers])
    }

    func testHandlesTrailingCommentCorrectly() {
        let input = """
        public class Foo {
            var bar = "bar"
            /// Leading comment
            public var baz = "baz" // Trailing comment
            var quux = "quux"
        }
        """

        let output = """
        public class Foo {

            // MARK: Public

            /// Leading comment
            public var baz = "baz" // Trailing comment

            // MARK: Internal

            var bar = "bar"
            var quux = "quux"
        }
        """

        testFormatting(for: input, output, rule: .organizeDeclarations,
                       exclude: [.blankLinesAtStartOfScope])
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

        testFormatting(for: input, output, rule: .organizeDeclarations)
    }

    func testOrganizesTypesWithinConditionalCompilationBlock() {
        let input = """
        #if DEBUG
        public struct DebugFoo {
            init() {}
            public func instanceMethod() {}
        }
        #else
        public struct ProductionFoo {
            init() {}
            public func instanceMethod() {}
        }
        #endif
        """

        let output = """
        #if DEBUG
        public struct DebugFoo {

            // MARK: Lifecycle

            init() {}

            // MARK: Public

            public func instanceMethod() {}
        }
        #else
        public struct ProductionFoo {

            // MARK: Lifecycle

            init() {}

            // MARK: Public

            public func instanceMethod() {}
        }
        #endif
        """

        testFormatting(for: input, output, rule: .organizeDeclarations,
                       options: FormatOptions(ifdefIndent: .noIndent),
                       exclude: [.blankLinesAtStartOfScope])
    }

    func testOrganizesTypesBelowConditionalCompilationBlock() {
        let input = """
        #if canImport(UIKit)
        import UIKit
        #endif

        public struct Foo {
            init() {}
            public func instanceMethod() {}
        }
        """

        let output = """
        #if canImport(UIKit)
        import UIKit
        #endif

        public struct Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Public

            public func instanceMethod() {}
        }
        """

        testFormatting(for: input, output, rule: .organizeDeclarations,
                       options: FormatOptions(ifdefIndent: .noIndent),
                       exclude: [.blankLinesAtStartOfScope])
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

            #if DEBUG
            struct Test {
                let foo: Bar
            }
            #endif
        }
        """

        let output = """
        public struct Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Public

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

            public var bar = "bar"

            // MARK: Internal

            #if DEBUG
            struct Test {
                let foo: Bar
            }
            #endif

            var baz = "baz"

            var quuz = "quux"

        }
        """

        testFormatting(for: input, output, rule: .organizeDeclarations,
                       options: FormatOptions(ifdefIndent: .noIndent),
                       exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .propertyTypes])
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

        public struct Foo {
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

        public struct Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Public

            public func instanceMethod() {}
        }
        """

        testFormatting(
            for: input, output, rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope, .sortImports]
        )
    }

    func testDoesntBreakStructSynthesizedMemberwiseInitializer() {
        let input = """
        public struct Foo {
            var bar: Int {
                didSet {}
            }

            var baz: Int
            public let quux: Int
        }

        Foo(bar: 1, baz: 2, quux: 3)
        """

        testFormatting(for: input, rule: .organizeDeclarations)
    }

    func testOrganizesStructPropertiesThatDontBreakMemberwiseInitializer() {
        let input = """
        public struct Foo {
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
        public struct Foo {

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
            for: input, output, rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope]
        )
    }

    func testPreservesCategoryMarksInStructWithIncorrectSubcategoryOrdering() {
        let input = """
        public struct Foo {

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
            for: input, rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope]
        )
    }

    func testPreservesCommentsAtBottomOfCategory() {
        let input = """
        public struct Foo {

            // MARK: Lifecycle

            init() {}

            // Important comment at end of section!

            // MARK: Public

            public let bar = 1
        }
        """

        testFormatting(
            for: input, rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope]
        )
    }

    func testPreservesCommentsAtBottomOfCategoryWhenReorganizing() {
        let input = """
        public struct Foo {

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
        public struct Foo {

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
            for: input, output, rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope]
        )
    }

    func testDoesntRemoveCategorySeparatorsFromBodyNotBeingOrganized() {
        let input = """
        public struct Foo {

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
            for: input, rule: .organizeDeclarations,
            options: FormatOptions(organizeStructThreshold: 20),
            exclude: [.blankLinesAtStartOfScope, .wrapPropertyBodies]
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

        testFormatting(for: input, rule: .organizeDeclarations, exclude: [.redundantClosure, .wrapPropertyBodies])
    }

    func testFuncWithNestedInitNotTreatedAsLifecycle() {
        let input = """
        public struct Foo {

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

        testFormatting(for: input, rule: .organizeDeclarations,
                       exclude: [.blankLinesAtStartOfScope])
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

        testFormatting(for: input, output, rule: .organizeDeclarations,
                       exclude: [.blankLinesAtStartOfScope])
    }

    func testOrganizeClassDeclarationsIntoCategoriesWithNoBlankLineAfterMark() {
        let input = """
        public class Foo {
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
        public class Foo {

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
            rule: .organizeDeclarations,
            options: options,
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope]
        )
    }

    func testOrganizeWithNoCategoryMarks_noSpacesBetweenDeclarations() {
        let input = """
        public class Foo {
            private func privateMethod() {}
            private let bar = 1
            public let baz = 1
        }
        """

        let output = """
        public class Foo {
            public let baz = 1

            private let bar = 1

            private func privateMethod() {}
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(markCategories: false)
        )
    }

    func testOrganizeWithNoCategoryMarks_withSpacesBetweenDeclarations() {
        let input = """
        public class Foo {
            private func privateMethod() {}

            private let bar = 1

            public let baz = 1

            private func anotherPrivateMethod() {}
        }
        """

        let output = """
        public class Foo {
            public let baz = 1

            private let bar = 1

            private func privateMethod() {}

            private func anotherPrivateMethod() {}
        }
        """

        // easy to start with?
        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(markCategories: false)
        )
    }

    func testOrganizeConditionalInitDeclaration() {
        let input = """
        class Foo {

            // MARK: Lifecycle

            init() {}

            #if DEBUG
            init() {
                print("Debug")
            }
            #endif

            // MARK: Internal

            func test() {}
        }
        """

        testFormatting(for: input, rule: .organizeDeclarations, options: FormatOptions(ifdefIndent: .noIndent), exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    func testOrganizeConditionalPublicFunction() {
        let input = """
        public class Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Public

            #if DEBUG
            public func publicTest() {}
            #endif

            // MARK: Internal

            func internalTest() {}
        }
        """

        testFormatting(for: input, rule: .organizeDeclarations, options: FormatOptions(ifdefIndent: .noIndent), exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
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

        testFormatting(for: input, rule: .organizeDeclarations)
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
                       rules: [.organizeDeclarations, .blankLinesBetweenScopes],
                       exclude: [.blankLinesAtEndOfScope])
    }

    func testSortsWithinOrganizeDeclarationsByClassName() {
        let input = """
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
                       rules: [.organizeDeclarations, .blankLinesBetweenScopes],
                       options: .init(alphabeticallySortedDeclarationPatterns: ["FeatureFlags"]),
                       exclude: [.blankLinesAtEndOfScope])
    }

    func testSortsWithinOrganizeDeclarationsByPartialClassName() {
        let input = """
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
                       rules: [.organizeDeclarations, .blankLinesBetweenScopes],
                       options: .init(alphabeticallySortedDeclarationPatterns: ["ureFla"]),
                       exclude: [.blankLinesAtEndOfScope])
    }

    func testDontSortsWithinOrganizeDeclarationsByClassNameInComment() {
        let input = """
        /// Comment
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

        testFormatting(for: input,
                       rules: [.organizeDeclarations, .blankLinesBetweenScopes],
                       options: .init(alphabeticallySortedDeclarationPatterns: ["Comment"]),
                       exclude: [.blankLinesAtEndOfScope])
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

        testFormatting(for: input, rule: .organizeDeclarations)
    }

    func testSortDeclarationsSortsExtensionBody() {
        let input = """
        public enum Namespace {}

        // swiftformat:sort
        extension Namespace {
            static let foo = "foo"
            public static let bar = "bar"
            static let baaz = "baaz"
        }
        """

        let output = """
        public enum Namespace {}

        // swiftformat:sort
        extension Namespace {
            static let baaz = "baaz"
            public static let bar = "bar"
            static let foo = "foo"
        }
        """

        // organizeTypes doesn't include "extension". So even though the
        // organizeDeclarations rule is enabled, the extension should be
        // sorted by the sortDeclarations rule.
        let options = FormatOptions(organizeTypes: ["class"])
        testFormatting(for: input, [output], rules: [.sortDeclarations, .organizeDeclarations], options: options)
    }

    func testOrganizeDeclarationsSortsExtensionBody() {
        let input = """
        public enum Namespace {}

        // swiftformat:sort
        extension Namespace {
            static let foo = "foo"
            public static let bar = "bar"
            static let baaz = "baaz"
        }
        """

        let output = """
        public enum Namespace {}

        // swiftformat:sort
        extension Namespace {

            // MARK: Public

            public static let bar = "bar"

            // MARK: Internal

            static let baaz = "baaz"
            static let foo = "foo"
        }
        """

        let options = FormatOptions(organizeTypes: ["extension"])
        testFormatting(for: input, output, rule: .organizeDeclarations, options: options,
                       exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    func testOrganizeDeclarationsContainingNonisolated() {
        let input = """
        public class Test {
            public static func test1() {}

            private nonisolated(unsafe) static var test3: ((
                _ arg1: Bool,
                _ arg2: Int
            ) -> Bool)?

            static func test2() {}
        }
        """
        let output = """
        public class Test {

            // MARK: Public

            public static func test1() {}

            // MARK: Internal

            static func test2() {}

            // MARK: Private

            private nonisolated(unsafe) static var test3: ((
                _ arg1: Bool,
                _ arg2: Int
            ) -> Bool)?

        }
        """
        testFormatting(for: input, output, rule: .organizeDeclarations,
                       exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    func testSortStructPropertiesWithAttributes() {
        let input = """
        // swiftformat:sort
        struct BookReaderView {
          @Namespace private var animation
          @State private var animationContent: Bool = false
          @State private var offsetY: CGFloat = 0
          @Bindable var model: Book
          @Query(
            filter: #Predicate<TextContent> { $0.progress_ < 1 },
            sort: \\.updatedAt_,
            order: .reverse
          ) private var incompleteTextContents: [TextContent]
        }
        """
        let output = """
        // swiftformat:sort
        struct BookReaderView {

          // MARK: Internal

          @Bindable var model: Book

          // MARK: Private

          @Namespace private var animation
          @State private var animationContent: Bool = false
          @Query(
            filter: #Predicate<TextContent> { $0.progress_ < 1 },
            sort: \\.updatedAt_,
            order: .reverse
          ) private var incompleteTextContents: [TextContent]
          @State private var offsetY: CGFloat = 0
        }
        """
        let options = FormatOptions(indent: "  ", organizeTypes: ["struct"])
        testFormatting(for: input, output, rule: .organizeDeclarations,
                       options: options, exclude: [.blankLinesAtStartOfScope])
    }

    func testSortSingleSwiftUIPropertyWrapper() {
        let input = """
        struct ContentView: View {

            init(label: String) {
                self.label = label
            }

            private var label: String

            @State
            private var isOn: Bool = false

            private var foo = true

            @ViewBuilder
            private var toggle: some View {
                Toggle(label, isOn: $isOn)
            }

            @ViewBuilder
            var body: some View {
                toggle
            }
        }
        """

        let output = """
        struct ContentView: View {

            // MARK: Lifecycle

            init(label: String) {
                self.label = label
            }

            // MARK: Internal

            @ViewBuilder
            var body: some View {
                toggle
            }

            // MARK: Private

            @State
            private var isOn: Bool = false

            private var label: String

            private var foo = true

            @ViewBuilder
            private var toggle: some View {
                Toggle(label, isOn: $isOn)
            }

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(organizeTypes: ["struct"], organizationMode: .visibility),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .privateStateVariables, .redundantViewBuilder]
        )
    }

    func testSortMultipleSwiftUIPropertyWrappers() {
        let input = """
        struct ContentView: View {

            init(foo: Foo, baaz: Baaz) {
                self.foo = foo
                self.baaz = baaz
            }

            let foo: Foo
            @State var bar = true
            let baaz: Baaz
            @State var quux = true

            @ViewBuilder
            private var toggle: some View {
                Toggle(label, isOn: $isOn)
            }

            @ViewBuilder
            var body: some View {
                toggle
            }
        }
        """

        let output = """
        struct ContentView: View {

            // MARK: Lifecycle

            init(foo: Foo, baaz: Baaz) {
                self.foo = foo
                self.baaz = baaz
            }

            // MARK: Internal

            @State var bar = true
            @State var quux = true

            let foo: Foo
            let baaz: Baaz

            @ViewBuilder
            var body: some View {
                toggle
            }

            // MARK: Private

            @ViewBuilder
            private var toggle: some View {
                Toggle(label, isOn: $isOn)
            }

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(organizeTypes: ["struct"], organizationMode: .visibility),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .privateStateVariables, .redundantMemberwiseInit, .redundantViewBuilder]
        )
    }

    func testSortSwiftUIPropertyWrappersWithDifferentVisibility() {
        let input = """
        struct ContentView: View {

            init(foo: Foo, baaz: Baaz, isOn: Binding<Bool>) {
                self.foo = foo
                self.baaz = baaz
                self_.isOn = isOn
            }

            let foo: Foo
            @State private var bar = 0
            private let baaz: Baaz
            @Binding var isOn: Bool

            @ViewBuilder
            private var toggle: some View {
                Toggle(label, isOn: $isOn)
            }

            @ViewBuilder
            var body: some View {
                toggle
            }
        }
        """

        let output = """
        struct ContentView: View {

            // MARK: Lifecycle

            init(foo: Foo, baaz: Baaz, isOn: Binding<Bool>) {
                self.foo = foo
                self.baaz = baaz
                self_.isOn = isOn
            }

            // MARK: Internal

            @Binding var isOn: Bool

            let foo: Foo

            @ViewBuilder
            var body: some View {
                toggle
            }

            // MARK: Private

            @State private var bar = 0

            private let baaz: Baaz

            @ViewBuilder
            private var toggle: some View {
                Toggle(label, isOn: $isOn)
            }

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(organizeTypes: ["struct"], organizationMode: .visibility),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .redundantViewBuilder]
        )
    }

    func testSortSwiftUIPropertyWrappersWithArguments() {
        let input = """
        struct ContentView: View {

            init(foo: Foo, baaz: Baaz) {
                self.foo = foo
                self.baaz = baaz
            }

            let foo: Foo
            @Environment(\\.colorScheme) var colorScheme
            let baaz: Baaz
            @Environment(\\.quux) let quux: Quux

            @ViewBuilder
            private var toggle: some View {
                Toggle(label, isOn: $isOn)
            }

            @ViewBuilder
            var body: some View {
                toggle
            }
        }
        """

        let output = """
        struct ContentView: View {

            // MARK: Lifecycle

            init(foo: Foo, baaz: Baaz) {
                self.foo = foo
                self.baaz = baaz
            }

            // MARK: Internal

            @Environment(\\.colorScheme) var colorScheme
            @Environment(\\.quux) let quux: Quux

            let foo: Foo
            let baaz: Baaz

            @ViewBuilder
            var body: some View {
                toggle
            }

            // MARK: Private

            @ViewBuilder
            private var toggle: some View {
                Toggle(label, isOn: $isOn)
            }

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(organizeTypes: ["struct"], organizationMode: .visibility),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .redundantViewBuilder]
        )
    }

    func testDoesntAddUnexpectedBlankLinesDueToBlankLinesWithSpaces() {
        // The blank lines in this input code are indented with four spaces.
        // Done using string interpolation in the input code to make this
        // more clear, and to prevent the spaces from being removed automatically.
        let input = """
        public class TestClass {
            var variable01 = 1
            var variable02 = 2
            var variable03 = 3
            var variable04 = 4
            var variable05 = 5
        \("    ")
            public func foo() {}
        \("    ")
            func bar() {}
        \("    ")
            private func baz() {}
        }
        """

        let output = """
        public class TestClass {

            // MARK: Public

            public func foo() {}
        \("    ")
            // MARK: Internal

            var variable01 = 1
            var variable02 = 2
            var variable03 = 3
            var variable04 = 4
            var variable05 = 5
        \("    ")
            func bar() {}
        \("    ")
            // MARK: Private

            private func baz() {}
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .consecutiveBlankLines, .trailingSpace, .consecutiveSpaces, .indent]
        )
    }

    func testSortSwiftUIPropertyWrappersSubCategoryAlphabetically() {
        let input = """
        struct ContentView: View {
            init() {}

            @Environment(\\.colorScheme) var colorScheme
            @State var foo: Foo
            @Binding var isOn: Bool
            @Environment(\\.quux) var quux: Quux
            @Bindable var model: MyModel

            @ViewBuilder
            var body: some View {
                Toggle(label, isOn: $isOn)
            }
        }
        """

        let output = """
        struct ContentView: View {

            // MARK: Lifecycle

            init() {}

            // MARK: Internal

            @Bindable var model: MyModel
            @Binding var isOn: Bool
            @Environment(\\.colorScheme) var colorScheme
            @Environment(\\.quux) var quux: Quux
            @State var foo: Foo

            @ViewBuilder
            var body: some View {
                Toggle(label, isOn: $isOn)
            }
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                organizeTypes: ["struct"],
                organizationMode: .visibility,
                blankLineAfterSubgroups: false,
                swiftUIPropertiesSortMode: .alphabetize
            ),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .privateStateVariables, .redundantViewBuilder]
        )
    }

    func testSortSwiftUIWrappersByTypeAndMaintainGroupSpacingAlphabetically() {
        let input = """
        struct ContentView: View {
            init() {}

            @State var foo: Foo
            @State var bar: Bar

            @Environment(\\.colorScheme) var colorScheme
            @Environment(\\.quux) var quux: Quux

            @Binding var isOn: Bool

            @ViewBuilder
            var body: some View {
                Toggle(label, isOn: $isOn)
            }
        }
        """

        let output = """
        struct ContentView: View {

            // MARK: Lifecycle

            init() {}

            // MARK: Internal

            @Binding var isOn: Bool

            @Environment(\\.colorScheme) var colorScheme
            @Environment(\\.quux) var quux: Quux

            @State var foo: Foo
            @State var bar: Bar

            @ViewBuilder
            var body: some View {
                Toggle(label, isOn: $isOn)
            }
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                organizeTypes: ["struct"],
                organizationMode: .visibility,
                blankLineAfterSubgroups: false,
                swiftUIPropertiesSortMode: .alphabetize
            ),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .privateStateVariables, .redundantViewBuilder]
        )
    }

    func testSortSwiftUIPropertyWrappersSubCategoryPreservingGroupPosition() {
        let input = """
        struct ContentView: View {
            init() {}

            @Environment(\\.colorScheme) var colorScheme
            @State var foo: Foo
            @Binding var isOn: Bool
            @Environment(\\.quux) var quux: Quux

            @ViewBuilder
            var body: some View {
                Toggle(label, isOn: $isOn)
            }
        }
        """

        let output = """
        struct ContentView: View {

            // MARK: Lifecycle

            init() {}

            // MARK: Internal

            @Environment(\\.colorScheme) var colorScheme
            @Environment(\\.quux) var quux: Quux
            @State var foo: Foo
            @Binding var isOn: Bool

            @ViewBuilder
            var body: some View {
                Toggle(label, isOn: $isOn)
            }
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                organizeTypes: ["struct"],
                organizationMode: .visibility,
                blankLineAfterSubgroups: false,
                swiftUIPropertiesSortMode: .firstAppearanceSort
            ),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .privateStateVariables, .redundantViewBuilder]
        )
    }

    func testSortSwiftUIWrappersByTypeAndMaintainGroupSpacingAndPosition() {
        let input = """
        struct ContentView: View {
            init() {}

            @State var foo: Foo
            @State var bar: Bar

            @Environment(\\.colorScheme) var colorScheme
            @Environment(\\.quux) var quux: Quux

            @Binding var isOn: Bool

            @ViewBuilder
            var body: some View {
                Toggle(label, isOn: $isOn)
            }
        }
        """

        let output = """
        struct ContentView: View {

            // MARK: Lifecycle

            init() {}

            // MARK: Internal

            @State var foo: Foo
            @State var bar: Bar

            @Environment(\\.colorScheme) var colorScheme
            @Environment(\\.quux) var quux: Quux

            @Binding var isOn: Bool

            @ViewBuilder
            var body: some View {
                Toggle(label, isOn: $isOn)
            }
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                organizeTypes: ["struct"],
                organizationMode: .visibility,
                blankLineAfterSubgroups: false,
                swiftUIPropertiesSortMode: .firstAppearanceSort
            ),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .privateStateVariables, .redundantViewBuilder]
        )
    }

    func testPreservesBlockOfConsecutivePropertiesWithoutBlankLinesBetweenSubgroups1() {
        let input = """
        class Foo {
            init() {}

            let foo: Foo
            let baaz: Baaz
            static let bar: Bar

        }
        """

        let output = """
        class Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Internal

            static let bar: Bar
            let foo: Foo
            let baaz: Baaz

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(blankLineAfterSubgroups: false),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope]
        )
    }

    func testPreservesBlockOfConsecutivePropertiesWithoutBlankLinesBetweenSubgroups2() {
        let input = """
        class Foo {
            init() {}

            let foo: Foo
            let baaz: Baaz
            static let bar: Bar

            static let quux: Quux
            let fooBar: FooBar
            let baazQuux: BaazQuux

        }
        """

        let output = """
        class Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Internal

            static let bar: Bar
            static let quux: Quux
            let foo: Foo
            let baaz: Baaz

            let fooBar: FooBar
            let baazQuux: BaazQuux

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(blankLineAfterSubgroups: false),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope]
        )
    }

    func testPreservesBlockOfConsecutiveProperties() {
        let input = """
        class Foo {
            init() {}

            let foo: Foo
            let baaz: Baaz
            static let bar: Bar

        }
        """

        let output = """
        class Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Internal

            static let bar: Bar

            let foo: Foo
            let baaz: Baaz

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope]
        )
    }

    func testPreservesBlockOfConsecutiveProperties2() {
        let input = """
        class Foo {
            init() {}

            let foo: Foo
            let baaz: Baaz
            static let bar: Bar

            static let quux: Quux
            let fooBar: FooBar
            let baazQuux: BaazQuux

        }
        """

        let output = """
        class Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Internal

            static let bar: Bar
            static let quux: Quux

            let foo: Foo
            let baaz: Baaz

            let fooBar: FooBar
            let baazQuux: BaazQuux

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope]
        )
    }

    func testPreservesCommentAtEndOfTypeBody() {
        let input = """
        class Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Internal

            let bar: Bar
            let baaz: Baaz

            // Comment at end of file

        }
        """

        testFormatting(
            for: input,
            rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope]
        )
    }

    func testSwiftUIPropertyWrappersSortDoesntBreakViewSynthesizedMemberwiseInitializer() {
        // @Environment properties don't affect memberwise init, so they can be freely reordered.
        // The stored properties (foo, baaz) maintain their relative order to preserve memberwise init.
        let input = """
        struct ContentView: View {

            let foo: Foo
            @Environment(\\.colorScheme) private var colorScheme
            let baaz: Baaz
            @Environment(\\.quux) private let quux: Quux

            @ViewBuilder
            private var toggle: some View {
                Toggle(label, isOn: $isOn)
            }

            @ViewBuilder
            var body: some View {
                toggle
            }
        }
        """

        let output = """
        struct ContentView: View {

            // MARK: Internal

            let foo: Foo
            let baaz: Baaz

            @ViewBuilder
            var body: some View {
                toggle
            }

            // MARK: Private

            @Environment(\\.colorScheme) private var colorScheme
            @Environment(\\.quux) private let quux: Quux

            @ViewBuilder
            private var toggle: some View {
                Toggle(label, isOn: $isOn)
            }

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(organizeTypes: ["struct"], organizationMode: .visibility),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .redundantViewBuilder]
        )
    }

    func testReorderingPropertiesCreatesFormatterChanges() {
        let input = """
        struct Test {
            var bar: Bar { "Bar" }

            var foo: Foo

            func test() {}
        }
        """

        let output = """
        struct Test {
            var foo: Foo

            var bar: Bar { "Bar" }

            func test() {}
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations, exclude: [.wrapPropertyBodies]
        )
    }

    func testIssue1907() {
        let input = """
        public final class Test: ObservableObject {
            var someProperty: Int? = 0

            // MARK: - Public -

            public func somePublicFunction() {
                print("Hello")
                print("Hello")
                print("Hello")
                print("Hello")
                print("Hello")
            }

            // MARK: - Internal -

            func someInternalFunction() {
                guard let someProperty else {
                    return
                }

                print("Hello")
                print("Hello")
                print("Hello")
                print("Hello")
                print("Hello")
            }

            // MARK: - Private -

            private func somePrivateFunction() {
                print("Hello")
                print("Hello")
            }
        }
        """

        let options = FormatOptions(
            categoryMarkComment: "MARK: - %c -",
            beforeMarks: ["class", "let", "var"]
        )

        testFormatting(for: input, rule: .organizeDeclarations, options: options)
    }

    func testFixesSpacingAfterMarks() {
        let input = """
        class Foo {
            // MARK: Lifecycle
            init() {}
            // MARK: Internal
            let bar = "bar"
        }
        """

        let output = """
        class Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Internal

            let bar = "bar"
        }
        """

        testFormatting(for: input, output, rule: .organizeDeclarations, exclude: [.blankLinesAtStartOfScope])
    }

    func testRemovesUnnecessaryMark() {
        let input = """
        class Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Internal

            // MARK: Internal

            let bar = "bar"

            // MARK: Internal

            let baaz = "baaz"
        }
        """

        let output = """
        class Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Internal

            let bar = "bar"

            let baaz = "baaz"
        }
        """

        testFormatting(for: input, output, rule: .organizeDeclarations, exclude: [.blankLinesAtStartOfScope])
    }

    func testPreservesUnrelatedComments() {
        let input = """
        enum Test {
            /// Test Properties
            static let foo = "foo"
            static let bar = "bar"
            static let baaz = "baaz"
        }
        """

        testFormatting(for: input, rule: .organizeDeclarations)
    }

    func testNoCrashWhenSortingNestedTypeDeclarations1() {
        let input = """
        public struct MyType {
            var foo: Foo {
                .foo
            }

            public let a: A
            public let b: B
            public let c: C
            public let d: D
            public let e: E

            public enum Foo {
                case foo
                case bar
                case baaz
            }
        }
        """

        let output = """
        public struct MyType {

            // MARK: Public

            public enum Foo {
                case foo
                case bar
                case baaz
            }

            public let a: A
            public let b: B
            public let c: C
            public let d: D
            public let e: E

            // MARK: Internal

            var foo: Foo {
                .foo
            }

        }
        """

        let options = FormatOptions(organizeStructThreshold: 0)
        testFormatting(for: input, output, rule: .organizeDeclarations, options: options, exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    func testNoCrashWhenSortingNestedTypeDeclarations2() {
        let input = """
        public struct MyType {
            public let a: A
            public let b: B
            public let c: C
            public let d: D
            public let e: E

            public enum Foo {
                case foo
                case bar
                case baaz
            }
        }
        """

        let output = """
        public struct MyType {
            public enum Foo {
                case foo
                case bar
                case baaz
            }

            public let a: A
            public let b: B
            public let c: C
            public let d: D
            public let e: E

        }
        """

        let options = FormatOptions(organizeStructThreshold: 0)
        testFormatting(for: input, output, rule: .organizeDeclarations, options: options, exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    func testSortsMultipleLayersOfNestedTypes() {
        let input = """
        public struct MyType {
            public let a: A
            public let b: B
            public let c: C
            public let d: D
            public let e: E

            public class Foo {
                class Baaz {
                    let b: B
                    public let a: A

                    public class Quux {
                        let b: B
                        public let a: A
                    }
                }

                let bar: Bar
                let baaz: Baaz

                public class Bar {
                    let b: B
                    public let a: A
                }
            }
        }
        """

        let output = """
        public struct MyType {
            public class Foo {

                // MARK: Public

                public class Bar {

                    // MARK: Public

                    public let a: A

                    // MARK: Internal

                    let b: B
                }

                // MARK: Internal

                class Baaz {

                    // MARK: Public

                    public class Quux {

                        // MARK: Public

                        public let a: A

                        // MARK: Internal

                        let b: B
                    }

                    public let a: A

                    // MARK: Internal

                    let b: B

                }

                let bar: Bar
                let baaz: Baaz

            }

            public let a: A
            public let b: B
            public let c: C
            public let d: D
            public let e: E

        }
        """

        testFormatting(for: input, output, rule: .organizeDeclarations, exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .redundantPublic])
    }

    func testOrganizeDeclarationsSortsEnumNamespace() {
        let input = """
        // swiftformat:sort
        public enum Constants {
            public static let foo = "foo"
            public static let bar = "bar"
            public static let baaz = "baaz"
        }
        """

        let output = """
        // swiftformat:sort
        public enum Constants {
            public static let baaz = "baaz"
            public static let bar = "bar"
            public static let foo = "foo"
        }
        """

        testFormatting(for: input, [output], rules: [.organizeDeclarations, .sortDeclarations])
    }

    func testIssue2045() {
        let input = """
        public final class A {

          // MARK: Lifecycle

          public init(a _: Int) {}

          convenience init() {
            self.init(a: 0)
          }

          // MARK: Public

          public func a() {}

          // MARK: Private

          private enum Error: Swift.Error {
            case e
          }

          private let a1: Float = 0
          private lazy var b: String? = ""
          private let a2 = 0

          private lazy var x: [Any] =
            if let b {
              [b]
            } else if false {
              []
            } else {
              [1, 2]
            }

          private lazy var y = f()

          private var z: Set<String> = []
        }

        func f() -> Int { 0 }
        """

        let options = FormatOptions(indent: "  ")
        testFormatting(for: input, rule: .organizeDeclarations, options: options, exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .wrapFunctionBodies])
    }

    func testOrganizesProtocol() {
        let input = """
        protocol Foo {
            func foo()
            var bar: Bar { get }
            func baaz()
            associatedtype Baaz
            var quux: Quux { get set }
            associatedtype Quux
        }
        """

        let output = """
        protocol Foo {
            associatedtype Baaz
            associatedtype Quux

            var bar: Bar { get }
            var quux: Quux { get set }

            func foo()
            func baaz()
        }
        """

        let options = FormatOptions(organizeTypes: ["protocol"])
        testFormatting(for: input, output, rule: .organizeDeclarations, options: options)
    }

    func testOrganizesProtocolWithInit() {
        let input = """
        public protocol Foo {
            func foo()
            func bar()
            init()
        }
        """

        let output = """
        public protocol Foo {
            init()

            func foo()
            func bar()
        }
        """

        let options = FormatOptions(organizeTypes: ["protocol"])
        testFormatting(for: input, output, rule: .organizeDeclarations, options: options)
    }

    func testBelowCustomStructMarkThreshold() {
        let input = """
        struct SmallStruct {
            func foo() {}
            let a = 1
            private let b = 2
        }
        """

        let output = """
        struct SmallStruct {
            let a = 1

            func foo() {}

            private let b = 2
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(markStructThreshold: 20),
            exclude: [.blankLinesAtStartOfScope]
        )
    }

    func testOrganizedStructNowOverMarkThreshold() {
        let input = """
        struct SmallStruct {
            func foo() {}
            let a = 1
            private let b = 2
        }
        """

        let output = """
        struct SmallStruct {

            // MARK: Internal

            let a = 1

            func foo() {}

            // MARK: Private

            private let b = 2
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(markStructThreshold: 4),
            exclude: [.blankLinesAtStartOfScope]
        )
    }

    func testBelowCustomStructMarkThresholdDoesntRemoveMarks() {
        let input = """
        struct SmallStruct {

            // MARK: Internal

            let a = 1

            func foo() {}

            // MARK: Private

            private let b = 2
        }
        """

        testFormatting(
            for: input,
            rule: .organizeDeclarations,
            options: FormatOptions(markStructThreshold: 20),
            exclude: [.blankLinesAtStartOfScope]
        )
    }

    func testAboveCustomStructMarkThreshold() {
        let input = """
        public struct LargeStruct {
            let a = 1
            let b = 2
            let c = 3
            public func foo() {}
            public func bar() {}
            public func baz() {}
        }
        """

        let output = """
        public struct LargeStruct {

            // MARK: Public

            public func foo() {}
            public func bar() {}
            public func baz() {}

            // MARK: Internal

            let a = 1
            let b = 2
            let c = 3
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(markStructThreshold: 5),
            exclude: [.blankLinesAtStartOfScope]
        )
    }

    func testTypeBodyMarksPreserved() {
        let input = """
        class Foo {

            // MARK: Unexpected comment

            var bar: String = "bar"

            // MARK: Some other comment

            func baz() {}

            // MARK: Lifecycle
            init() {}
        }
        """

        let output = """
        class Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Internal

            // MARK: Unexpected comment

            var bar: String = "bar"

            // MARK: Some other comment

            func baz() {}

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(typeBodyMarks: .preserve),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .blankLinesAroundMark]
        )
    }

    func testTypeBodyMarksRemoved() {
        let input = """
        class Foo {

            // MARK: Unexpected comment

            var bar: String = "bar"

            // MARK: Some other comment

            func baz() {}

            // MARK: Lifecycle

            init() {}
        }
        """

        let output = """
        class Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Internal

            var bar: String = "bar"

            func baz() {}

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(typeBodyMarks: .remove),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope]
        )
    }

    func testTypeBodyMarksPreserveValidMarks() {
        let input = """
        class Foo {

            // MARK: Some unexpected comment

            var bar: String = "bar"

            // MARK: Internal

            func validComment() {}

            init() {}
        }
        """

        let output = """
        class Foo {

            // MARK: Lifecycle

            init() {}

            // MARK: Internal

            var bar: String = "bar"

            func validComment() {}

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(typeBodyMarks: .remove),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope]
        )
    }

    func testTypeBodyMarksWithTypeMode() {
        let input = """
        class Foo {

            // MARK: Unexpected section

            var bar: String = "bar"

            // MARK: Not a function category
            func baz() {}

            init() {}

        }
        """

        let output = """
        class Foo {

            // MARK: Properties

            var bar: String = "bar"

            // MARK: Lifecycle

            init() {}

            // MARK: Functions

            func baz() {}

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(
                categoryMarkComment: "MARK: %c",
                organizationMode: .type,
                typeBodyMarks: .remove
            ),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope]
        )
    }

    func testRemovesAllUnnecessaryMarkAfterStandardMark() {
        let input = """
        public class Foo {

            // MARK: Public

            public func bar() {}

            // MARK: Internal

            // MARK: Implementation

            func method() {}

            // MARK: Testing

            func testMethod() {}

        }
        """

        let output = """
        public class Foo {

            // MARK: Public

            public func bar() {}

            // MARK: Internal

            func method() {}

            func testMethod() {}

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(typeBodyMarks: .remove),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope]
        )
    }

    func testOrganizesProtocolWithAsync() {
        // Async variables are not allowed in protocols
        let input = """
        protocol Foo {
            func foo() async
            var bar: Bar { get }

            func baaz()
                async
            var quux: Quux { get }
        }
        """

        let output = """
        protocol Foo {
            var bar: Bar { get }

            var quux: Quux { get }

            func foo() async
            func baaz()
                async
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            options: FormatOptions(organizeTypes: ["protocol"]),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope]
        )
    }

    func testHandlesMalformedPropertyType() {
        let input = """
        extension Foo {
            /// Invalid type, should still get handled properly
            private var foo: FooBar++ {
                guard
                    let foo = foo.bar,
                    let bar = foo.bar
                else {
                    return nil
                }

                return bar
            }
        }

        extension Foo {
            /// Invalid type, should still get handled properly
            func foo() -> FooBar++ {
                guard
                    let foo = foo.bar,
                    let bar = foo.bar
                else {
                    return nil
                }

                return bar
            }
        }
        """

        testFormatting(
            for: input,
            rule: .organizeDeclarations,
            options: FormatOptions(organizeTypes: ["extension"]),
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope]
        )
    }

    func testMovesInternalPropertyOutOfPrivateSection() {
        // Internal property `placement` should be moved from Private section to Internal section
        let input = """
        private struct Foo: View {

            // MARK: Internal

            var body: some View {
                EmptyView()
            }

            // MARK: Private

            @Environment(\\.bar) private var bar
            @Environment(\\.baz) private var baz

            let placement: Placement

        }
        """

        let output = """
        private struct Foo: View {

            // MARK: Internal

            let placement: Placement

            var body: some View {
                EmptyView()
            }

            // MARK: Private

            @Environment(\\.bar) private var bar
            @Environment(\\.baz) private var baz

        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope]
        )
    }

    func testPrivateVarWithDefaultValuePreventsReordering() {
        // private var with default value is still part of memberwise init (optional param),
        // so reordering stored properties would break the init.
        // Section headers can be added, but the order must be preserved (bar before baz).
        let input = """
        struct Foo {
            let bar: Bar
            private var baz = Baz()
        }
        """

        let output = """
        struct Foo {

            // MARK: Internal

            let bar: Bar

            // MARK: Private

            private var baz = Baz()
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .propertyTypes]
        )
    }

    func testPrivateLetWithDefaultValueAllowsReordering() {
        // private let with default value is NOT part of memberwise init,
        // so it can be freely reordered (baz moves after bar)
        let input = """
        struct Foo {
            private let baz = Baz()
            let bar: Bar
        }
        """

        let output = """
        struct Foo {

            // MARK: Internal

            let bar: Bar

            // MARK: Private

            private let baz = Baz()
        }
        """

        testFormatting(
            for: input, output,
            rule: .organizeDeclarations,
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .propertyTypes]
        )
    }
}
