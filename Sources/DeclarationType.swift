//
//  DeclarationType.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 12/26/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

// MARK: - DeclarationType

/// The type of a declaration.
enum DeclarationType: String, CaseIterable {
    case beforeMarks
    case nestedType
    case staticProperty
    case staticPropertyWithBody
    case classPropertyWithBody
    case overriddenProperty
    case swiftUIPropertyWrapper
    case instanceProperty
    case instancePropertyWithBody
    case computedProperty
    case instanceLifecycle
    case swiftUIProperty
    case swiftUIMethod
    case overriddenMethod
    case staticMethod
    case classMethod
    case instanceMethod

    var markComment: String {
        switch self {
        case .beforeMarks:
            return "Before Marks"
        case .nestedType:
            return "Nested Types"
        case .staticProperty:
            return "Static Properties"
        case .staticPropertyWithBody:
            return "Static Computed Properties"
        case .classPropertyWithBody:
            return "Class Properties"
        case .overriddenProperty:
            return "Overridden Properties"
        case .instanceLifecycle:
            return "Lifecycle"
        case .overriddenMethod:
            return "Overridden Functions"
        case .swiftUIProperty:
            return "Content Properties"
        case .swiftUIMethod:
            return "Content Methods"
        case .swiftUIPropertyWrapper:
            return "SwiftUI Properties"
        case .instanceProperty:
            return "Properties"
        case .instancePropertyWithBody:
            return "Properties with Bodies"
        case .computedProperty:
            return "Computed Properties"
        case .staticMethod:
            return "Static Functions"
        case .classMethod:
            return "Class Functions"
        case .instanceMethod:
            return "Functions"
        }
    }

    static var essentialCases: [DeclarationType] {
        [
            .beforeMarks,
            .nestedType,
            .instanceLifecycle,
            .instanceProperty,
            .instanceMethod,
        ]
    }

    static func defaultOrdering(for mode: DeclarationOrganizationMode) -> [DeclarationType] {
        switch mode {
        case .type:
            return [
                .beforeMarks,
                .nestedType,
                .staticProperty,
                .staticPropertyWithBody,
                .classPropertyWithBody,
                .overriddenProperty,
                .swiftUIPropertyWrapper,
                .instanceProperty,
                .computedProperty,
                .instanceLifecycle,
                .swiftUIProperty,
                .swiftUIMethod,
                .overriddenMethod,
                .staticMethod,
                .classMethod,
                .instanceMethod,
            ]

        case .visibility:
            return [
                nestedType,
                staticProperty,
                staticPropertyWithBody,
                classPropertyWithBody,
                overriddenProperty,
                swiftUIPropertyWrapper,
                instanceProperty,
                instancePropertyWithBody,
                swiftUIProperty,
                swiftUIMethod,
                overriddenMethod,
                staticMethod,
                classMethod,
                instanceMethod,
            ]
        }
    }
}

extension DeclarationV2 {
    /// The `DeclarationType` of the given `Declaration`
    func declarationType(
        allowlist availableTypes: [DeclarationType],
        beforeMarks: Set<String>,
        lifecycleMethods: Set<String>
    ) -> DeclarationType {
        switch kind {
        case .type:
            return beforeMarks.contains(keyword) ? .beforeMarks : .nestedType

        case .conditionalCompilation:
            // Prefer treating conditional compilation blocks as having
            // the property type of the first declaration in their body.
            guard let firstDeclarationInBlock = body?.first else {
                // It's unusual to have an empty conditional compilation block.
                // Pick an arbitrary declaration type as a fallback.
                return .nestedType
            }

            return firstDeclarationInBlock.declarationType(
                allowlist: availableTypes,
                beforeMarks: beforeMarks,
                lifecycleMethods: lifecycleMethods
            )

        case .declaration:
            let rangeBeforeKeyword = range.lowerBound ..< keywordIndex
            let rangeAfterKeyword = Range(keywordIndex ... range.upperBound)

            if keyword == "case" || beforeMarks.contains(keyword) {
                return .beforeMarks
            }

            let isStaticDeclaration = formatter.lastIndex(
                of: .keyword("static"),
                in: rangeBeforeKeyword
            ) != nil

            let isClassDeclaration = formatter.lastIndex(
                of: .keyword("class"),
                in: rangeBeforeKeyword
            ) != nil

            let isOverriddenDeclaration = formatter.lastIndex(
                of: .identifier("override"),
                in: rangeBeforeKeyword
            ) != nil

            let propertyDeclaration = parsePropertyDeclaration()
            let isPropertyWithBody = propertyDeclaration?.body != nil

            // A property with a body is either a computed property,
            // or a stored property with a willSet or didSet.
            let isComputedProperty = isPropertyWithBody && !isStoredProperty

            let isViewDeclaration: Bool = {
                guard let someKeywordIndex = formatter.index(
                    of: .identifier("some"), in: rangeAfterKeyword
                ) else { return false }

                return formatter.index(of: .identifier("View"), in: someKeywordIndex ..< range.upperBound) != nil
            }()

            let isSwiftUIPropertyWrapper = swiftUIPropertyWrapper != nil

            switch keyword {
            // Properties and property-like declarations
            case "let", "var", "operator", "precedencegroup":

                if isOverriddenDeclaration, availableTypes.contains(.overriddenProperty) {
                    return .overriddenProperty
                }
                if isStaticDeclaration, isPropertyWithBody, availableTypes.contains(.staticPropertyWithBody) {
                    return .staticPropertyWithBody
                }
                if isStaticDeclaration, availableTypes.contains(.staticProperty) {
                    return .staticProperty
                }
                if isClassDeclaration, availableTypes.contains(.classPropertyWithBody) {
                    // Interestingly, Swift does not support stored class properties
                    // so there's no such thing as a class property without a body.
                    // https://forums.swift.org/t/class-properties/16539/11
                    return .classPropertyWithBody
                }
                if isViewDeclaration, availableTypes.contains(.swiftUIProperty) {
                    return .swiftUIProperty
                }
                if !isPropertyWithBody, isSwiftUIPropertyWrapper, availableTypes.contains(.swiftUIPropertyWrapper) {
                    return .swiftUIPropertyWrapper
                }
                if isComputedProperty, availableTypes.contains(.computedProperty) {
                    return .computedProperty
                }
                if isPropertyWithBody, availableTypes.contains(.instancePropertyWithBody) {
                    return .instancePropertyWithBody
                }

                return .instanceProperty

            // Functions and function-like declarations
            case "func", "subscript":
                // The user can also provide specific instance method names to place in Lifecycle
                //  - In the function declaration grammar, the function name always
                //    immediately follows the `func` keyword:
                //    https://docs.swift.org/swift-book/ReferenceManual/Declarations.html#grammar_function-name
                let methodName = formatter.next(.nonSpaceOrCommentOrLinebreak, after: keywordIndex)
                if let methodName = methodName, lifecycleMethods.contains(methodName.string) {
                    return .instanceLifecycle
                }
                if isOverriddenDeclaration, availableTypes.contains(.overriddenMethod) {
                    return .overriddenMethod
                }
                if isStaticDeclaration, availableTypes.contains(.staticMethod) {
                    return .staticMethod
                }
                if isClassDeclaration, availableTypes.contains(.classMethod) {
                    return .classMethod
                }
                if isViewDeclaration, availableTypes.contains(.swiftUIMethod) {
                    return .swiftUIMethod
                }

                return .instanceMethod

            case "init", "deinit":
                return .instanceLifecycle

            // Type-like declarations
            case "typealias":
                return .nestedType

            case "case":
                return .beforeMarks

            default:
                return .beforeMarks
            }
        }
    }

    var swiftUIPropertyWrapper: String? {
        modifiers.first { modifier in
            swiftUIPropertyWrappers.contains(modifier)
        }
    }

    /// Represents all the native SwiftUI property wrappers that conform to `DynamicProperty` and cause a SwiftUI view to re-render.
    /// Most of these are listed here: https://developer.apple.com/documentation/swiftui/dynamicproperty
    private var swiftUIPropertyWrappers: Set<String> {
        [
            "@AccessibilityFocusState",
            "@AppStorage",
            "@Binding",
            "@Environment",
            "@EnvironmentObject",
            "@NSApplicationDelegateAdaptor",
            "@FetchRequest",
            "@FocusedBinding",
            "@FocusState",
            "@FocusedValue",
            "@FocusedObject",
            "@GestureState",
            "@Namespace",
            "@ObservedObject",
            "@PhysicalMetric",
            "@Query",
            "@ScaledMetric",
            "@SceneStorage",
            "@SectionedFetchRequest",
            "@State",
            "@StateObject",
            "@UIApplicationDelegateAdaptor",
            "@WKExtensionDelegateAdaptor",
        ]
    }
}
