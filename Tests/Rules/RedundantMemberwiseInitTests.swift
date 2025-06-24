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
        // MARK: - WalleStepContent

        public struct WalleStepContent {

          // MARK: Lifecycle

          public init(
            componentContents: [WalleComponentViewModel],
            nextButtonContent: WalleActionButtonContent,
            secondaryButtonContent: WalleActionButtonContent?,
            exitButtonContent: WalleExitButtonContent,
            loggingInfo: WalleStepLoggingInfo,
            saveMode: WalleFlowSaveModeDataType,
            hideDiscardWarning: Bool,
            clearAnswersOnBackPress: Bool,
            progress: CGFloat?
          ) {
            self.componentContents = componentContents
            self.nextButtonContent = nextButtonContent
            self.secondaryButtonContent = secondaryButtonContent
            self.exitButtonContent = exitButtonContent
            self.loggingInfo = loggingInfo
            self.saveMode = saveMode
            self.hideDiscardWarning = hideDiscardWarning
            self.clearAnswersOnBackPress = clearAnswersOnBackPress
            self.progress = progress
          }

          // MARK: Public

          public let componentContents: [WalleComponentViewModel]
          public let nextButtonContent: WalleActionButtonContent
          public let secondaryButtonContent: WalleActionButtonContent?
          public let exitButtonContent: WalleExitButtonContent
          public let loggingInfo: WalleStepLoggingInfo
          public let saveMode: WalleFlowSaveModeDataType
          public let hideDiscardWarning: Bool
          public let clearAnswersOnBackPress: Bool
          public let progress: CGFloat?
        }

        // MARK: - WalleRadioButtonGroupContent

        public struct WalleRadioButtonGroupContent: Equatable {

          // MARK: Lifecycle

          public init(
            id: String,
            title: String?,
            subtitle: String?,
            contents: [WalleComponentViewModel],
            impressionContext: MagicalImpressionContext?
          ) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.contents = contents
            self.impressionContext = impressionContext
          }

          // MARK: Public

          public let id: String
          public let title: String?
          public let subtitle: String?
          public let contents: [WalleComponentViewModel]
          public let impressionContext: MagicalImpressionContext?


        }

        // MARK: - WalleRadioButtonRowContent

        public struct WalleRadioButtonRowContent: Equatable {

          // MARK: Lifecycle

          public init(
            id: String,
            title: String,
            subtitle: String?,
            imageURL: URL?,
            questionValue: String,
            contents: [WalleComponentViewModel],
            isSelected: Bool,
            answerContext: FlowAnswerContext
          ) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.imageURL = imageURL
            self.questionValue = questionValue
            self.contents = contents
            self.isSelected = isSelected
            self.answerContext = answerContext
          }

          // MARK: Public

          public let id: String
          public let title: String
          public let subtitle: String?
          public let imageURL: URL?
          public let questionValue: String
          public let contents: [WalleComponentViewModel]
          public let isSelected: Bool
          public let answerContext: FlowAnswerContext


        }

        // MARK: - WalleRadioToggleButtonGroupContent

        public struct WalleRadioToggleButtonGroupContent: Equatable {

          // MARK: Lifecycle

          public init(
            id: String,
            title: String?,
            subtitle: String?,
            contents: [WalleRadioToggleButtonContent],
            impressionContext: MagicalImpressionContext?
          ) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.contents = contents
            self.impressionContext = impressionContext
          }

          // MARK: Public

          public let id: String
          public let title: String?
          public let subtitle: String?
          public let contents: [WalleRadioToggleButtonContent]
          public let impressionContext: MagicalImpressionContext?


        }

        // MARK: - WalleButtonRowContent

        public struct WalleButtonRowContent: Equatable {

          // MARK: Lifecycle

          public init(
            id: String,
            title: String,
            mobileAction: WalleFlowMobileAction,
            styles: [String]?,
            loggingContext: MagicalActionContext?
          ) {
            self.id = id
            self.title = title
            self.mobileAction = mobileAction
            self.styles = styles
            self.loggingContext = loggingContext
          }

          // MARK: Public

          public let id: String
          public let title: String
          public let mobileAction: WalleFlowMobileAction
          public let styles: [String]?
          public let loggingContext: MagicalActionContext?


        }

        // MARK: - WalleLinkRowContent

        public struct WalleLinkRowContent: Equatable {

          // MARK: Lifecycle

          public init(
            id: String,
            title: String,
            mobileAction: WalleFlowMobileAction,
            styles: [String]?,
            loggingContext: MagicalActionContext?
          ) {
            self.id = id
            self.title = title
            self.mobileAction = mobileAction
            self.styles = styles
            self.loggingContext = loggingContext
          }

          // MARK: Public

          public let id: String
          public let title: String
          public let mobileAction: WalleFlowMobileAction
          public let styles: [String]?
          public let loggingContext: MagicalActionContext?


        }

        // MARK: - WalleProfileHeaderRowContent

        public struct WalleProfileHeaderRowContent: Equatable {
          public init(id: String, title: String, captions: [String]?, imageURL: URL?) {
            self.id = id
            self.title = title
            self.captions = captions
            self.imageURL = imageURL
          }


          public let id: String
          public let title: String
          public let captions: [String]?
          public let imageURL: URL?
        }

        // MARK: - WalleProfileActionRowContent

        public struct WalleProfileActionRowContent: Equatable {

          // MARK: Lifecycle

          public init(
            id: String,
            title: String,
            subtitle: String,
            action: String,
            captions: [String]?,
            iconName: String?,
            iconColor: String?,
            imageURL: URL?,
            mobileAction: WalleFlowMobileAction?
          ) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.action = action
            self.captions = captions
            self.iconName = iconName
            self.iconColor = iconColor
            self.imageURL = imageURL
            self.mobileAction = mobileAction
          }

          // MARK: Public

          public let id: String
          public let title: String
          public let subtitle: String
          public let action: String
          public let captions: [String]?
          public let iconName: String?
          public let iconColor: String?
          public let imageURL: URL?
          public let mobileAction: WalleFlowMobileAction?


        }

        // MARK: - WalleRadioToggleButtonContent

        public struct WalleRadioToggleButtonContent: Equatable {

          // MARK: Lifecycle

          public init(id: String, title: String, questionValue: String, answerContext: FlowAnswerContext, isSelected: Bool) {
            self.id = id
            self.title = title
            self.questionValue = questionValue
            self.answerContext = answerContext
            self.isSelected = isSelected
          }

          // MARK: Public

          public let id: String
          public let title: String
          public let questionValue: String
          public let answerContext: FlowAnswerContext
          public let isSelected: Bool


        }

        // MARK: - WalleCheckBoxRowContent

        public struct WalleCheckBoxRowContent: Equatable {

          // MARK: Lifecycle

          public init(
            id: String,
            title: String,
            subtitle: String?,
            imageURL: URL?,
            contents: [WalleComponentViewModel],
            isSelected: Bool,
            answerContext: FlowAnswerContext,
            groupId: String?,
            subGroupId: String?
          ) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.imageURL = imageURL
            self.contents = contents
            self.isSelected = isSelected
            self.answerContext = answerContext
            self.groupId = groupId
            self.subGroupId = subGroupId
          }

          // MARK: Public

          public let id: String
          public let title: String
          public let subtitle: String?
          public let imageURL: URL?
          public let contents: [WalleComponentViewModel]
          public let isSelected: Bool
          public let answerContext: FlowAnswerContext
          public let groupId: String?
          public let subGroupId: String?
        }

        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [])
    }

    func testRemoveRedundantMemberwiseInitWithLargeStruct() {
        let input = """
        public struct WalleStepContent {
          public init(
            componentContents: [WalleComponentViewModel],
            nextButtonContent: WalleActionButtonContent,
            secondaryButtonContent: WalleActionButtonContent?,
            exitButtonContent: WalleExitButtonContent,
            loggingInfo: WalleStepLoggingInfo,
            saveMode: WalleFlowSaveModeDataType,
            hideDiscardWarning: Bool,
            clearAnswersOnBackPress: Bool,
            progress: CGFloat?
          ) {
            self.componentContents = componentContents
            self.nextButtonContent = nextButtonContent
            self.secondaryButtonContent = secondaryButtonContent
            self.exitButtonContent = exitButtonContent
            self.loggingInfo = loggingInfo
            self.saveMode = saveMode
            self.hideDiscardWarning = hideDiscardWarning
            self.clearAnswersOnBackPress = clearAnswersOnBackPress
            self.progress = progress
          }

          public let componentContents: [WalleComponentViewModel]
          public let nextButtonContent: WalleActionButtonContent
          public let secondaryButtonContent: WalleActionButtonContent?
          public let exitButtonContent: WalleExitButtonContent
          public let loggingInfo: WalleStepLoggingInfo
          public let saveMode: WalleFlowSaveModeDataType
          public let hideDiscardWarning: Bool
          public let clearAnswersOnBackPress: Bool
          public let progress: CGFloat?
        }
        """
        let output = """
        public struct WalleStepContent {
          public let componentContents: [WalleComponentViewModel]
          public let nextButtonContent: WalleActionButtonContent
          public let secondaryButtonContent: WalleActionButtonContent?
          public let exitButtonContent: WalleExitButtonContent
          public let loggingInfo: WalleStepLoggingInfo
          public let saveMode: WalleFlowSaveModeDataType
          public let hideDiscardWarning: Bool
          public let clearAnswersOnBackPress: Bool
          public let progress: CGFloat?
        }
        """
        testFormatting(for: input, output, rule: .redundantMemberwiseInit, exclude: [.indent])
    }
}
