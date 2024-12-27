// Created by miguel_jimenez on 10/11/24.
// Copyright © 2024 Airbnb Inc. All rights reserved.

import Foundation

public extension FormatRule {
    /// Removes types conforming `EnvironmentKey` and replaces them with the @Entry macro
    static let environmentEntry = FormatRule(
        help: "Updates SwiftUI `EnvironmentValues` definitions to use the @Entry macro.",
        disabledByDefault: true
    ) { formatter in
        // The @Entry macro is only available in Xcode 16 therefore this rule requires the same Xcode version to work.
        guard formatter.options.swiftVersion >= "6.0" else { return }

        let declarations = formatter.parseDeclarations()

        // Find all structs that conform to `EnvironmentKey`
        let environmentKeys = formatter.findAllEnvironmentKeys(declarations)

        // Find all `EnvironmentValues` properties
        let environmentValuesProperties = formatter.findAllEnvironmentValuesProperties(declarations, referencing: environmentKeys)

        // Modify `EnvironmentValues` properties by removing its body and adding the @Entry macro
        formatter.modifyEnvironmentValuesProperties(environmentValuesProperties)

        // Remove `EnvironmentKey`s
        for environmentValuesProperty in environmentValuesProperties {
            if let environmentKey = environmentKeys[environmentValuesProperty.key] {
                environmentKey.declaration.remove()
            }
        }

    } examples: {
        """
        ```diff
        - struct ScreenNameEnvironmentKey: EnvironmentKey {
        -   static var defaultValue: Identifier? {
        -      .init("undefined") 
        -     }
        -   }

           extension EnvironmentValues {
        -    var screenName: Identifier? {
        -      get { self[ScreenNameEnvironmentKey.self] }
        -      set { self[ScreenNameEnvironmentKey.self] = newValue }
        -    }
        +    @Entry var screenName: Identifier? = .init("undefined")
           }
        ```
        """
    }
}

struct EnvironmentKey {
    let key: String
    let declaration: Declaration
    let defaultValueTokens: [Token]?
}

struct EnvironmentValueProperty {
    let key: String
    let associatedEnvironmentKey: EnvironmentKey
    let declaration: Declaration
}

extension Formatter {
    func findAllEnvironmentKeys(_ declarations: [Declaration]) -> [String: EnvironmentKey] {
        var environmentKeys = [String: EnvironmentKey]()

        for declaration in declarations {
            guard let typeDeclaration = declaration.asTypeDeclaration,
                  typeDeclaration.keyword == "struct" || typeDeclaration.keyword == "enum",
                  typeDeclaration.conformances.contains(where: { $0.conformance == "EnvironmentKey" }),
                  let keyName = typeDeclaration.name,
                  typeDeclaration.body.count == 1,
                  let defaultValueDeclaration = typeDeclaration.body.first(where: {
                      ($0.keyword == "var" || $0.keyword == "let") && $0.name == "defaultValue"
                  })
            else { continue }

            environmentKeys[keyName] = EnvironmentKey(
                key: keyName,
                declaration: typeDeclaration,
                defaultValueTokens: findEnvironmentKeyDefaultValue(defaultValueDeclaration)
            )
        }

        return environmentKeys
    }

    func findEnvironmentKeyDefaultValue(_ defaultValueDeclaration: Declaration) -> [Token]? {
        guard let property = defaultValueDeclaration.parsePropertyDeclaration() else { return nil }

        if let valueRange = property.value?.expressionRange {
            return Array(tokens[valueRange])
        }

        else if let body = property.body {
            // If the body contains multiple expressions, the final output will need to be wrapped
            // in an immediately-executed closure.
            if !scopeBodyIsSingleExpression(at: body.scopeRange.lowerBound) {
                let existingBodyScope = Array(tokens[body.scopeRange])
                return existingBodyScope + [.startOfScope("("), .endOfScope(")")]
            } else {
                return Array(tokens[body.range])
            }
        }

        return nil
    }

    func findAllEnvironmentValuesProperties(
        _ declarations: [Declaration],
        referencing environmentKeys: [String: EnvironmentKey]
    ) -> [EnvironmentValueProperty] {
        declarations
            .filter {
                $0.keyword == "extension" && $0.name == "EnvironmentValues"
            }.compactMap { environmentValuesDeclaration -> [EnvironmentValueProperty]? in
                environmentValuesDeclaration.body?.compactMap { propertyDeclaration -> (EnvironmentValueProperty)? in
                    guard propertyDeclaration.keyword == "var",
                          let key = propertyDeclaration.tokens.first(where: { environmentKeys[$0.string] != nil })?.string,
                          let environmentKey = environmentKeys[key]
                    else { return nil }

                    // Ensure the property has a setter and a getter, this can avoid edge cases where
                    // a property references a `EnvironmentKey` and consumes it to perform some computation.
                    guard let bodyRange = propertyDeclaration.parsePropertyDeclaration()?.body?.range,
                          let indexOfSetter = index(of: .identifier("set"), in: Range(bodyRange)),
                          isAccessorKeyword(at: indexOfSetter)
                    else { return nil }

                    return EnvironmentValueProperty(
                        key: key,
                        associatedEnvironmentKey: environmentKey,
                        declaration: propertyDeclaration
                    )
                }
            }.flatMap { $0 }
    }

    func modifyEnvironmentValuesProperties(_ environmentValuesPropertiesDeclarations: [EnvironmentValueProperty]) {
        for envProperty in environmentValuesPropertiesDeclarations {
            guard let propertyDeclaration = envProperty.declaration.parsePropertyDeclaration(),
                  let bodyScopeRange = propertyDeclaration.body?.scopeRange
            else { continue }

            // Remove `EnvironmentValues.property` getter and setters
            if let nonSpaceTokenIndexBeforeBody = index(of: .nonSpaceOrLinebreak, before: bodyScopeRange.lowerBound), nonSpaceTokenIndexBeforeBody != bodyScopeRange.lowerBound {
                // There are some spaces between the property body and the property type definition, we should remove the extra spaces.
                removeTokens(in: nonSpaceTokenIndexBeforeBody + 1 ... bodyScopeRange.upperBound)
            } else {
                removeTokens(in: bodyScopeRange)
            }
            // Add `EnvironmentKey.defaultValue` to `EnvironmentValues property`
            if let defaultValueTokens = envProperty.associatedEnvironmentKey.defaultValueTokens {
                let defaultValueTokens = [.space(" "), .operator("=", .infix), .space(" ")] + defaultValueTokens
                insert(defaultValueTokens, at: endOfLine(at: propertyDeclaration.range.lowerBound))
            }
            // Add @Entry Macro
            insert([.identifier("@Entry"), .space(" ")], at: propertyDeclaration.range.lowerBound)
        }
    }
}
