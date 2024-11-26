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
        let environmentKeys = Dictionary(uniqueKeysWithValues: formatter.findAllEnvironmentKeys(declarations).map { ($0.key, $0) })

        // Find all `EnvironmentValues` properties
        let environmentValuesProperties = formatter.findAllEnvironmentValuesProperties(declarations, referencing: environmentKeys)

        // Modify `EnvironmentValues` properties by removing its body and adding the @Entry macro
        formatter.modifyEnvironmentValuesProperties(environmentValuesProperties)

        // Remove `EnvironmentKey`s
        let updatedEnvironmentKeys = Set(environmentValuesProperties.map(\.key))
        formatter.removeEnvironmentKeys(updatedEnvironmentKeys)
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
    let defaultValueTokens: ArraySlice<Token>?
    let isMultilineDefaultValue: Bool
}

struct EnvironmentValueProperty {
    let key: String
    let associatedEnvironmentKey: EnvironmentKey
    let declaration: Declaration
}

extension Formatter {
    func findAllEnvironmentKeys(_ declarations: [Declaration]) -> [EnvironmentKey] {
        declarations.compactMap { declaration -> EnvironmentKey? in
            guard declaration.keyword == "struct" || declaration.keyword == "enum",
                  declaration.openTokens.contains(.identifier("EnvironmentKey")),
                  let keyName = declaration.openTokens.first(where: \.isIdentifier),
                  let structDeclarationBody = declaration.body,
                  structDeclarationBody.count == 1,
                  let defaultValueDeclaration = structDeclarationBody.first(where: {
                      ($0.keyword == "var" || $0.keyword == "let") && $0.name == "defaultValue"
                  }),
                  let (defaultValueTokens, isMultiline) = findEnvironmentKeyDefaultValue(defaultValueDeclaration)
            else { return nil }
            return EnvironmentKey(
                key: keyName.string,
                declaration: declaration,
                defaultValueTokens: defaultValueTokens,
                isMultilineDefaultValue: isMultiline
            )
        }
    }

    func findEnvironmentKeyDefaultValue(_ defaultValueDeclaration: Declaration) -> (tokens: ArraySlice<Token>?, isMultiline: Bool)? {
        if defaultValueDeclaration.isStaticStoredProperty,
           let equalsIndex = index(of: .operator("=", .infix), after: defaultValueDeclaration.originalRange.lowerBound),
           equalsIndex <= defaultValueDeclaration.originalRange.upperBound,
           let valueStartIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: equalsIndex),
           let valueEndIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: defaultValueDeclaration.originalRange.upperBound)
        {
            // Default value is stored property, not computed (e.g. static var defaultValue: Bool = false)
            return (tokens[valueStartIndex ... valueEndIndex], false)
        } else if let valueEndOfScopeIndex = endOfScope(at: defaultValueDeclaration.originalRange.upperBound - 1),
                  let valueStartOfScopeIndex = startOfScope(at: valueEndOfScopeIndex),
                  let valueStartIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: valueStartOfScopeIndex),
                  let valueEndIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: valueEndOfScopeIndex)
        {
            let defaultValueDeclarations = parseDeclarations(in: valueStartIndex ... valueEndIndex)
            let isMultilineDeclaration = defaultValueDeclarations.count > 1
            if defaultValueDeclarations.count <= 1 {
                if defaultValueDeclarations.first?.name == "defaultValue" {
                    // Default value is implicitly `nil` (e.g. static var defaultValue: Bool?)
                    return (nil, false)
                } else {
                    // Default value is a computed property with a single value (e.g. static var defaultValue: Bool { false })
                    return (tokens[valueStartIndex ... valueEndIndex], isMultilineDeclaration)
                }
            } else {
                // Default value is a multiline computed property:
                // ```
                // static var defaultValue: Bool {
                //   let computedValue = compute()
                //   return computedValue
                // }
                // ```
                return (tokens[valueStartOfScopeIndex ... valueEndOfScopeIndex], isMultilineDeclaration)
            }
        } else { return nil }
    }

    func findAllEnvironmentValuesProperties(_ declarations: [Declaration], referencing environmentKeys: [String: EnvironmentKey])
        -> [EnvironmentValueProperty]
    {
        declarations
            .filter {
                $0.keyword == "extension" && $0.openTokens.contains(.identifier("EnvironmentValues"))
            }.compactMap { environmentValuesDeclaration -> [EnvironmentValueProperty]? in
                environmentValuesDeclaration.body?.compactMap { propertyDeclaration -> (EnvironmentValueProperty)? in
                    guard propertyDeclaration.isSimpleDeclaration,
                          propertyDeclaration.keyword == "var",
                          let key = propertyDeclaration.tokens.first(where: { environmentKeys[$0.string] != nil })?.string,
                          let environmentKey = environmentKeys[key]
                    else { return nil }

                    // Ensure the property has a setter and a getter, this can avoid edge cases where
                    // a property references a `EnvironmentKey` and consumes it to perform some computation.
                    let propertyFormatter = Formatter(propertyDeclaration.tokens)
                    guard let indexOfSetter = propertyDeclaration.tokens.firstIndex(where: { $0 == .identifier("set") }),
                          propertyFormatter.isAccessorKeyword(at: indexOfSetter)
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
        // Loop the collection in reverse to avoid invalidating the declaration indexes as we modify the property
        for envProperty in environmentValuesPropertiesDeclarations.reversed() {
            let propertyDeclaration = envProperty.declaration
            guard let propertyBodyStartIndex = index(of: .startOfScope("{"), after: propertyDeclaration.originalRange.lowerBound),
                  let propertyBodyEndIndex = endOfScope(at: propertyBodyStartIndex),
                  let propertyStartIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: propertyDeclaration.originalRange.lowerBound)
            else {
                continue
            }
            // Remove `EnvironmentValues.property` getter and setters
            if let nonSpaceTokenIndexBeforeBody = index(of: .nonSpaceOrLinebreak, before: propertyBodyStartIndex), nonSpaceTokenIndexBeforeBody != propertyBodyStartIndex {
                // There are some spaces between the property body and the property type definition, we should remove the extra spaces.
                let propertyBodyStartIndex = nonSpaceTokenIndexBeforeBody + 1
                removeTokens(in: propertyBodyStartIndex ... propertyBodyEndIndex)
            } else {
                removeTokens(in: propertyBodyStartIndex ... propertyBodyEndIndex)
            }
            // Add `EnvironmentKey.defaultValue` to `EnvironmentValues property`
            if let defaultValueTokens = envProperty.associatedEnvironmentKey.defaultValueTokens {
                var defaultValueTokens = [.space(" "), .operator("=", .infix), .space(" ")] + defaultValueTokens

                if envProperty.associatedEnvironmentKey.isMultilineDefaultValue {
                    defaultValueTokens.append(contentsOf: [.endOfScope("("), .endOfScope(")")])
                }
                insert(defaultValueTokens, at: endOfLine(at: propertyStartIndex))
            }
            // Add @Entry Macro
            insert([.identifier("@Entry"), .space(" ")], at: propertyStartIndex)
        }
    }

    func removeEnvironmentKeys(_ updatedEnvironmentKeys: Set<String>) {
        guard !updatedEnvironmentKeys.isEmpty else { return }

        // After modifying the EnvironmentValues properties, parse declarations again to delete the Environment keys in their new position.
        let repositionedEnvironmentKeys = findAllEnvironmentKeys(parseDeclarations())

        // Loop the collection in reverse to avoid invalidating the declaration indexes as we remove EnvironmentKey
        for declaration in repositionedEnvironmentKeys.reversed() where updatedEnvironmentKeys.contains(declaration.key) {
            removeTokens(in: declaration.declaration.originalRange)
        }
    }
}
