// Created by miguel_jimenez on 10/11/24.
// Copyright © 2024 Airbnb Inc. All rights reserved.

import Foundation

let maxDepth = 5

public extension FormatRule {
    /// Remove redundant void return values for function and closure declarations
    static let replaceEnvironmentKeyForEntryMacro = FormatRule(
        help: "Replaces EnvironmentKey for @Entry macro",
        disabledByDefault: true
    ) { formatter in
        let declarations = formatter.parseDeclarations()

        // Find all structs conforming `EnvironmentKey`
        let environmentKeys = Dictionary(uniqueKeysWithValues: formatter.findAllEnvironmentKeyDeclarations(declarations).map { ($0.environmentKey, $0) })

        // Find all `EnvironmentValues` properties
        let environmentValuesPropertiesDeclarations = formatter.findAllEnvironmentValuesPropertyDeclarations(declarations, referencing: environmentKeys)

        // Modify `EnvironmentValues` properties by removing its body and adding the @Entry macro
        formatter.modifyEnvironmentValuesProperties(environmentValuesPropertiesDeclarations)

        let updatedEnvironmentKeys = Set(environmentValuesPropertiesDeclarations.map(\.environmentKey))
        guard !updatedEnvironmentKeys.isEmpty else { return }

        // After modifying the EnvironmentValues properties, parse declarations again to delete the Environment keys in their new position.
        let newDeclarations = formatter.parseDeclarations()
        let newEnvironmentKeyDeclarations = formatter.findAllEnvironmentKeyDeclarations(newDeclarations)

        // Loop the collection in reverse to avoid invalidating the declaration indexes as we remove EnvironmentKey
        for declaration in newEnvironmentKeyDeclarations.reversed() where updatedEnvironmentKeys.contains(declaration.environmentKey) {
            formatter.removeTokens(in: declaration.keyDeclaration.originalRange)
        }
    } examples: {
        """
        ```diff
        - struct ScreenNameEnvironmentKey: EnvironmentKey {
        -   static var defaultValue: Identifier? {
        -      .init("undefined") 
        -     }
        -   }

        -  extension EnvironmentValues {
        -    var screenName: Identifier? {
        -      get { self[ScreenNameEnvironmentKey.self] }
        -      set { self[ScreenNameEnvironmentKey.self] = newValue }
        -    }
        -  }

        +  extension EnvironmentValues {
        +    @Entry var screenName: Identifier? = .init("undefined")
        +  }
        ```
        """
    }
}

private struct EnvironmentKeyDeclaration {
    let environmentKey: String
    let keyDeclaration: Declaration
    let defaultValueTokens: ArraySlice<Token>
}

private struct EnvironmentValueProperty {
    let environmentKey: String
    let associatedEnvironmentKeyDeclaration: EnvironmentKeyDeclaration
    let declaration: Declaration
}

private extension Formatter {
    func findAllEnvironmentKeyDeclarations(_ declarations: [Declaration]) -> [EnvironmentKeyDeclaration] {
        declarations.compactMap { declaration -> EnvironmentKeyDeclaration? in
            guard declaration.keyword == "struct",
                  declaration.openTokens.contains(.identifier("EnvironmentKey")),
                  let keyName = declaration.openTokens.first(where: \.isIdentifier),
                  let defaultValueDeclaration = declaration.body?.first(where: {
                      $0.keyword == "var" && $0.name == "defaultValue"
                  }),
                  let valueEndOfScopeIndex = endOfScope(at: defaultValueDeclaration.originalRange.upperBound - 1),
                  let valueStartOfScope = startOfScope(at: valueEndOfScopeIndex),
                  let valueStartIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: valueStartOfScope),
                  let valueEndIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: valueEndOfScopeIndex)
            else { return nil }
            let defaultValueTokens = tokens[valueStartIndex ... valueEndIndex]
            return EnvironmentKeyDeclaration(
                environmentKey: keyName.string,
                keyDeclaration: declaration,
                defaultValueTokens: defaultValueTokens
            )
        }
    }

    func findAllEnvironmentValuesPropertyDeclarations(_ declarations: [Declaration], referencing environmentKeys: [String: EnvironmentKeyDeclaration])
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
                          propertyDeclaration.name == key.removingSuffix("EnvironmentKey")
                    else { return nil }
                    return EnvironmentValueProperty(
                        environmentKey: key,
                        associatedEnvironmentKeyDeclaration: environmentKeys[key]!,
                        declaration: propertyDeclaration
                    )
                }
            }.flatMap { $0 }
    }

    func modifyEnvironmentValuesProperties(_ environmentValuesPropertiesDeclarations: [EnvironmentValueProperty]) {
        // Loop the collection in reverse to avoid invalidating the declaration indexes as we modify the property
        for envPropertyDeclaration in environmentValuesPropertiesDeclarations.reversed() {
            let propertyDeclaration = envPropertyDeclaration.declaration
            guard let propertyBodyStartIndex = index(of: .startOfScope("{"), after: propertyDeclaration.originalRange.lowerBound),
                  let propertyBodyEndIndex = endOfScope(at: propertyBodyStartIndex),
                  let keywordIndex = index(of: .keyword("var"), after: propertyDeclaration.originalRange.lowerBound)
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
            insert(
                [.space(" "), .keyword("="), .space(" ")] + envPropertyDeclaration.associatedEnvironmentKeyDeclaration.defaultValueTokens,
                at: endOfLine(at: keywordIndex)
            )
            // Add @Entry Macro
            replaceToken(at: keywordIndex, with: [.identifier("@Entry"), .space(" "), .identifier("var")])
        }
    }
}
