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

        // Find all struct conforming `EnvironmentKey`
        let environmentKeysDict = formatter.findAllEnvironmentKeyDeclarations(declarations)

        // Find all `EnvironmentValues` properties
        let environmentKeys = Set(environmentKeysDict.keys)
        let environmentValuesPropertiesDeclarations = formatter.findAllEnvironmentValuesPropertyDeclarations(declarations, referencing: environmentKeys)

        for (environmentKey, propertyDeclaration) in environmentValuesPropertiesDeclarations {
            guard let propertyBodyStartIndex = formatter.index(of: .startOfScope("{"), after: propertyDeclaration.originalRange.lowerBound),
                  let propertyBodyEndIndex = formatter.endOfScope(at: propertyBodyStartIndex),
                  let keywordIndex = formatter.index(of: .keyword("var"), after: propertyDeclaration.originalRange.lowerBound),
                  let keyDeclaration = environmentKeysDict[environmentKey]
            else {
                continue
            }
            // Remove `EnvironmentValues.property` getter and setters
            formatter.removeTokens(in: propertyBodyStartIndex ... propertyBodyEndIndex)
            // Add `EnvironmentKey.defaultValue` to `EnvironmentValues.property`
            formatter.insert(
                [.space(" "), .keyword("="), .space(" ")] + keyDeclaration.defaultValueTokens,
                at: formatter.endOfLine(at: keywordIndex) - 1
            )
            // Add @Entry Macro
            formatter.replaceToken(at: keywordIndex, with: [.identifier("@Entry"), .space(" "), .identifier("var")])
        }
        // After modifying the EnvironmentValues properties, generate parse declarations again to delete the keys in their new position.
        let newDeclarations = formatter.parseDeclarations()
        for declaration in formatter.findAllEnvironmentKeyDeclarations(newDeclarations).reversed() {
            formatter.removeTokens(in: declaration.value.keyDeclaration.originalRange)
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
    let keyDeclaration: Declaration
    let defaultValueTokens: ArraySlice<Token>
}

private extension Formatter {
    func findAllEnvironmentKeyDeclarations(_ declarations: [Declaration]) -> [String: EnvironmentKeyDeclaration] {
        let environmentKeyDeclarations = declarations.compactMap { declaration -> (String, EnvironmentKeyDeclaration)? in
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
            return (keyName.string, EnvironmentKeyDeclaration(keyDeclaration: declaration, defaultValueTokens: defaultValueTokens))
        }
        return Dictionary(uniqueKeysWithValues: environmentKeyDeclarations)
    }

    func findAllEnvironmentValuesPropertyDeclarations(_ declarations: [Declaration], referencing environmentKeys: Set<String>)
        -> [(environmentKey: String, propertyDeclaration: Declaration)]
    {
        declarations
            .filter {
                $0.keyword == "extension" && $0.openTokens.contains(.identifier("EnvironmentValues"))
            }.compactMap { environmentValuesDeclaration -> [(String, Declaration)]? in
                guard let body = environmentValuesDeclaration.body else { return nil }
                return body.compactMap { propertyDeclaration -> (String, Declaration)? in
                    guard propertyDeclaration.isSimpleDeclaration,
                          propertyDeclaration.keyword == "var",
                          let key = propertyDeclaration.tokens.first(where: { environmentKeys.contains($0.string) }),
                          propertyDeclaration.name == key.string.removingSuffix("EnvironmentKey")
                    else { return nil }
                    return (key.string, propertyDeclaration)
                }
            }.flatMap { $0 }
    }
}
