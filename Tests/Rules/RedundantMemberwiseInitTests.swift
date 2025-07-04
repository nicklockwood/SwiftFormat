//
//  RedundantMemberwiseInitTests.swift
//  SwiftFormatTests
//
//  Created by Miguel Jimenez on 6/17/25.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class RedundantMemberwiseInitTests: XCTestCase {
    func testRemoveRedundantMemberwiseInit() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            init(name: String, age: Int) {
                self.name = name
                self.age = age
            }
        }
        """
        let output = """
        struct Person {
            var name: String
            var age: Int
        }
        """
        testFormatting(for: input, output, rule: .redundantMemberwiseInit)
    }

    func testRemoveRedundantMemberwiseInitWithLetProperties() {
        let input = """
        struct Point {
            let x: Double
            let y: Double

            init(x: Double, y: Double) {
                self.x = x
                self.y = y
            }
        }
        """
        let output = """
        struct Point {
            let x: Double
            let y: Double
        }
        """
        testFormatting(for: input, output, rule: .redundantMemberwiseInit)
    }

    func testRemoveRedundantMemberwiseInitMixedProperties() {
        let input = """
        struct User {
            let id: Int
            var name: String
            var email: String

            init(id: Int, name: String, email: String) {
                self.id = id
                self.name = name
                self.email = email
            }
        }
        """
        let output = """
        struct User {
            let id: Int
            var name: String
            var email: String
        }
        """
        testFormatting(for: input, output, rule: .redundantMemberwiseInit)
    }

    func testDontRemoveCustomInit() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            init(name: String, age: Int) {
                self.name = name.uppercased()
                self.age = age
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemoveInitWithAdditionalLogic() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            init(name: String, age: Int) {
                self.name = name
                self.age = age
                print("Person created")
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemoveInitWithDifferentParameterNames() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            init(fullName: String, yearsOld: Int) {
                self.name = fullName
                self.age = yearsOld
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemoveInitWithDifferentParameterTypes() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            init(name: String, age: Double) {
                self.name = name
                self.age = Int(age)
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemovePrivateInit() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            private init(name: String, age: Int) {
                self.name = name
                self.age = age
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testRemovePublicInitFromPublicStructDuplicate() {
        let input = """
        public struct Person {
            var name: String
            var age: Int

            public init(name: String, age: Int) {
                self.name = name
                self.age = age
            }
        }
        """
        let output = """
        public struct Person {
            var name: String
            var age: Int
        }
        """
        testFormatting(for: input, output, rule: .redundantMemberwiseInit)
    }

    func testRemoveInitWithComputedProperties() {
        let input = """
        struct Person {
            var name: String
            var age: Int
            var isAdult: Bool {
                return age >= 18
            }

            init(name: String, age: Int) {
                self.name = name
                self.age = age
            }
        }
        """
        let output = """
        struct Person {
            var name: String
            var age: Int
            var isAdult: Bool {
                return age >= 18
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantMemberwiseInit)
    }

    func testDontRemoveInitWithComputedPropertyInitialization() {
        let input = """
        struct Person {
            var name: String
            var age: Int
            var isAdult: Bool

            init(name: String, age: Int) {
                self.name = name
                self.age = age
                self.isAdult = age >= 18
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testRemoveInitWithStaticProperties() {
        let input = """
        struct Person {
            var name: String
            var age: Int
            static var defaultAge = 0

            init(name: String, age: Int) {
                self.name = name
                self.age = age
            }
        }
        """
        let output = """
        struct Person {
            var name: String
            var age: Int
            static var defaultAge = 0
        }
        """
        testFormatting(for: input, output, rule: .redundantMemberwiseInit, exclude: [.redundantSelf])
    }

    func testDontRemoveInitWithPrivateProperties() {
        let input = """
        struct Person {
            private var name: String
            var age: Int

            init(name: String, age: Int) {
                self.name = name
                self.age = age
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemoveInitWithPartialParameterMatch() {
        let input = """
        struct Person {
            var name: String
            var age: Int
            var city: String

            init(name: String, age: Int) {
                self.name = name
                self.age = age
                self.city = "Unknown"
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontAffectClass() {
        let input = """
        class Person {
            var name: String
            var age: Int

            init(name: String, age: Int) {
                self.name = name
                self.age = age
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontAffectEnum() {
        let input = """
        enum Color {
            case red
            case blue

            init() {
                self = .red
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.trailingSpace])
    }

    func testHandleEmptyStruct() {
        let input = """
        struct Empty {
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.emptyBraces])
    }

    func testHandleStructWithOnlyComputedProperties() {
        let input = """
        struct Calculator {
            var result: Int {
                return 42
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testRemoveRedundantInitWithComplexTypes() {
        let input = """
        struct Container {
            var items: [String]
            var metadata: [String: Any]

            init(items: [String], metadata: [String: Any]) {
                self.items = items
                self.metadata = metadata
            }
        }
        """
        let output = """
        struct Container {
            var items: [String]
            var metadata: [String: Any]
        }
        """
        testFormatting(for: input, output, rule: .redundantMemberwiseInit)
    }

    func testRemoveRedundantInitWithOptionalTypes() {
        let input = """
        struct Person {
            var name: String?
            var age: Int?

            init(name: String?, age: Int?) {
                self.name = name
                self.age = age
            }
        }
        """
        let output = """
        struct Person {
            var name: String?
            var age: Int?
        }
        """
        testFormatting(for: input, output, rule: .redundantMemberwiseInit)
    }

    func testDontRemoveInitWithMethodCall() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            init(name: String, age: Int) {
                self.name = name
                self.age = age
                self.validate()
            }

            func validate() {}
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemoveInitWithMethodCallBefore() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            init(name: String, age: Int) {
                setupDefaults()
                self.name = name
                self.age = age
            }

            func setupDefaults() {}
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemoveInitWithPrintStatement() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            init(name: String, age: Int) {
                print("Creating person: \\(name)")
                self.name = name
                self.age = age
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemoveInitWithMultipleStatements() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            init(name: String, age: Int) {
                self.name = name
                self.age = age
                print("Person created")
                NotificationCenter.default.post(name: .personCreated, object: nil)
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemoveInitWithGuardStatement() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            init(name: String, age: Int) {
                guard age >= 0 else { fatalError("Invalid age") }
                self.name = name
                self.age = age
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent, .blankLinesAfterGuardStatements, .wrapConditionalBodies])
    }

    func testDontRemoveInitWithComments() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            init(name: String, age: Int) {
                // Initialize properties
                self.name = name
                self.age = age
                // Initialization complete
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemoveInitWithConditionalLogic() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            init(name: String, age: Int) {
                self.name = name
                if age < 0 {
                    self.age = 0
                } else {
                    self.age = age
                }
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemoveInitWithDefaultArguments() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            init(name: String, age: Int = 0) {
                self.name = name
                self.age = age
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemoveInitWithMultipleDefaultArguments() {
        let input = """
        struct Person {
            var name: String
            var age: Int
            var city: String

            init(name: String, age: Int = 0, city: String = "Unknown") {
                self.name = name
                self.age = age
                self.city = city
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemoveInitWithDifferentExternalLabels() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            init(withName name: String, andAge age: Int) {
                self.name = name
                self.age = age
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemoveInitWithMixedExternalLabels() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            init(name: String, withAge age: Int) {
                self.name = name
                self.age = age
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemoveInitWithUnderscoreExternalLabel() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            init(_ name: String, _ age: Int) {
                self.name = name
                self.age = age
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemoveInternalInitFromPublicStruct() {
        let input = """
        public struct Person {
            var name: String
            var age: Int

            init(name: String, age: Int) {
                self.name = name
                self.age = age
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testRemovePublicInitFromPublicStruct() {
        let input = """
        public struct Person {
            var name: String
            var age: Int

            public init(name: String, age: Int) {
                self.name = name
                self.age = age
            }
        }
        """
        let output = """
        public struct Person {
            var name: String
            var age: Int
        }
        """
        testFormatting(for: input, output, rule: .redundantMemberwiseInit)
    }

    func testDontRemoveInitWhenMultipleInitsExist() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            init(name: String, age: Int) {
                self.name = name
                self.age = age
            }

            init(name: String) {
                self.name = name
                self.age = 0
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemoveInitWhenThreeInitsExist() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            init(name: String, age: Int) {
                self.name = name
                self.age = age
            }

            init(name: String) {
                self.name = name
                self.age = 0
            }

            init() {
                self.name = "Unknown"
                self.age = 0
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testRemoveInitWithAttributes() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            @inlinable
            init(name: String, age: Int) {
                self.name = name
                self.age = age
            }
        }
        """
        let output = """
        struct Person {
            var name: String
            var age: Int
        }
        """
        testFormatting(for: input, output, rule: .redundantMemberwiseInit)
    }

    func testRemoveInitWithMultipleAttributes() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            @inlinable
            @available(iOS 13.0, *)
            init(name: String, age: Int) {
                self.name = name
                self.age = age
            }
        }
        """
        let output = """
        struct Person {
            var name: String
            var age: Int
        }
        """
        testFormatting(for: input, output, rule: .redundantMemberwiseInit)
    }

    func testRemoveInitWithAttributesAndComments() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            /// Initializes a person with name and age
            @inlinable
            internal init(name: String, age: Int) {
                self.name = name
                self.age = age
            }
        }
        """
        let output = """
        struct Person {
            var name: String
            var age: Int
        }
        """
        testFormatting(for: input, output, rule: .redundantMemberwiseInit)
    }

    func testDontRemoveInitWithPrivateStoredProperty() {
        let input = """
        struct Person {
            var name: String
            var age: Int
            private var id: String

            init(name: String, age: Int, id: String) {
                self.name = name
                self.age = age
                self.id = id
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemoveInitWithFileprivateStoredProperty() {
        let input = """
        struct Person {
            var name: String
            var age: Int
            fileprivate var secret: String

            init(name: String, age: Int, secret: String) {
                self.name = name
                self.age = age
                self.secret = secret
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testRemovePrivateInitWithPrivateStoredProperty() {
        let input = """
        struct Person {
            var name: String
            var age: Int
            private var id: String

            private init(name: String, age: Int, id: String) {
                self.name = name
                self.age = age
                self.id = id
            }
        }
        """
        let output = """
        struct Person {
            var name: String
            var age: Int
            private var id: String
        }
        """
        testFormatting(for: input, output, rule: .redundantMemberwiseInit)
    }

    func testDontRemovePublicInitWithPrivateStoredProperty() {
        let input = """
        public struct Person {
            var name: String
            var age: Int
            private var id: String

            public init(name: String, age: Int, id: String) {
                self.name = name
                self.age = age
                self.id = id
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemoveInitWhenPrivatePropertiesWithDefaultValues() {
        let input = """
        struct PayoutView {
            let dataModel: String
            private var style = DefaultStyle()

            init(dataModel: String) {
                self.dataModel = dataModel
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent, .propertyTypes])
    }

    func testDontRemoveInitWhenPrivatePropertiesHaveNoDefaultValues() {
        let input = """
        struct PayoutView {
            let dataModel: String
            private var shadowedStyle: ShadowedStyle

            init(dataModel: String, shadowedStyle: ShadowedStyle) {
                self.dataModel = dataModel
                self.shadowedStyle = shadowedStyle
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemoveInitWhenAllPropertiesInitialized() {
        let input = """
        struct Person {
            let name: String
            let age: Int
            private var id: String = "default"

            init(name: String, age: Int) {
                self.name = name
                self.age = age
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemoveInitWhenPrivatePropertiesWithDefaultsMakesSynthesizedInitPrivate() {
        let input = """
        struct Person {
            let name: String
            let age: Int
            private var id: String = "default"

            init(name: String, age: Int) {
                self.name = name
                self.age = age
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemoveInitWithDocumentationComments() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            /// Creates a Person with the specified name and age
            init(name: String, age: Int) {
                self.name = name  
                self.age = age
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemoveInitWithMultiLineDocumentationComments() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            /**
             * Creates a Person with the specified name and age.
             * - Parameter name: The person's full name
             * - Parameter age: The person's age in years
             */
            init(name: String, age: Int) {
                self.name = name
                self.age = age
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testRemoveInitWithRegularComments() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            // This is just a regular comment
            init(name: String, age: Int) {
                self.name = name
                self.age = age
            }
        }
        """
        let output = """
        struct Person {
            var name: String
            var age: Int
        }
        """
        testFormatting(for: input, output, rule: .redundantMemberwiseInit)
    }

    func testRemoveRedundantPublicMemberwiseInitWithProperFormattingOfFirstProperty() {
        let input = """
        public struct CardViewAnimationState {
            public init(
            style: CardStyle,
            backgroundColor: UIColor?
            ) {
            self.style = style
            self.backgroundColor = backgroundColor
            }

            public let style: CardStyle
            public let backgroundColor: UIColor?
        }
        """
        let output = """
        public struct CardViewAnimationState {
            public let style: CardStyle
            public let backgroundColor: UIColor?
        }
        """
        testFormatting(for: input, output, rule: .redundantMemberwiseInit)
    }

    func testRemoveRedundantMemberwiseInitWithComplexStruct() {
        let input = """
        public struct Foo {

          // MARK: Lifecycle

          public init(
            name: String,
            value: Int,
            isEnabled: Bool
          ) {
            self.name = name
            self.value = value
            self.isEnabled = isEnabled
          }

          // MARK: Public

          public let name: String
          public let value: Int
          public let isEnabled: Bool
        }

        public struct Bar: Equatable {

          // MARK: Lifecycle

          public init(
            id: String,
            count: Int
          ) {
            self.id = id
            self.count = count
          }

          // MARK: Public

          public let id: String
          public let count: Int
        }

        // MARK: - Baz

        public struct Baz: Equatable {

          // MARK: Lifecycle

          public init(
            title: String,
            subtitle: String?,
            data: [String]
          ) {
            self.title = title
            self.subtitle = subtitle
            self.data = data
          }

          // MARK: Public

          public let title: String
          public let subtitle: String?
          public let data: [String]
        }

        // MARK: - Qux

        public struct Qux: Equatable {

          // MARK: Lifecycle

          public init(
            key: String,
            value: String?
          ) {
            self.key = key
            self.value = value
          }

          // MARK: Public

          public let key: String
          public let value: String?
        }

        // MARK: - Widget

        public struct Widget: Equatable {

          // MARK: Lifecycle

          public init(
            name: String,
            color: String,
            size: Int
          ) {
            self.name = name
            self.color = color
            self.size = size
          }

          // MARK: Public

          public let name: String
          public let color: String
          public let size: Int
        }

        // MARK: - Item

        public struct Item: Equatable {

          // MARK: Lifecycle

          public init(
            identifier: String,
            label: String
          ) {
            self.identifier = identifier
            self.label = label
          }

          // MARK: Public

          public let identifier: String
          public let label: String
        }

        // MARK: - Component

        public struct Component: Equatable {
          public init(type: String, config: [String: Any]) {
            self.type = type
            self.config = config
          }

          public let type: String
          public let config: [String: Any]
        }

        // MARK: - Element

        public struct Element: Equatable {

          // MARK: Lifecycle

          public init(
            tag: String,
            attributes: [String]?,
            content: String
          ) {
            self.tag = tag
            self.attributes = attributes
            self.content = content
          }

          // MARK: Public

          public let tag: String
          public let attributes: [String]?
          public let content: String
        }

        // MARK: - Node

        public struct Node: Equatable {

          // MARK: Lifecycle

          public init(id: String, parent: String?, children: [String]) {
            self.id = id
            self.parent = parent
            self.children = children
          }

          // MARK: Public

          public let id: String
          public let parent: String?
          public let children: [String]
        }

        // MARK: - Record

        public struct Record: Equatable {

          // MARK: Lifecycle

          public init(
            timestamp: Double,
            message: String
          ) {
            self.timestamp = timestamp
            self.message = message
          }

          // MARK: Public

          public let timestamp: Double
          public let message: String
        }
        """
        let output = """
        public struct Foo {

          // MARK: Public

          public let name: String
          public let value: Int
          public let isEnabled: Bool
        }

        public struct Bar: Equatable {

          // MARK: Public

          public let id: String
          public let count: Int
        }

        // MARK: - Baz

        public struct Baz: Equatable {

          // MARK: Public

          public let title: String
          public let subtitle: String?
          public let data: [String]
        }

        // MARK: - Qux

        public struct Qux: Equatable {

          // MARK: Public

          public let key: String
          public let value: String?
        }

        // MARK: - Widget

        public struct Widget: Equatable {

          // MARK: Public

          public let name: String
          public let color: String
          public let size: Int
        }

        // MARK: - Item

        public struct Item: Equatable {

          // MARK: Public

          public let identifier: String
          public let label: String
        }

        // MARK: - Component

        public struct Component: Equatable {
          public let type: String
          public let config: [String: Any]
        }

        // MARK: - Element

        public struct Element: Equatable {

          // MARK: Public

          public let tag: String
          public let attributes: [String]?
          public let content: String
        }

        // MARK: - Node

        public struct Node: Equatable {

          // MARK: Public

          public let id: String
          public let parent: String?
          public let children: [String]
        }

        // MARK: - Record

        public struct Record: Equatable {

          // MARK: Public

          public let timestamp: Double
          public let message: String
        }
        """
        testFormatting(for: input, output, rule: .redundantMemberwiseInit, exclude: [.indent, .acronyms, .blankLinesAtStartOfScope])
    }
}
