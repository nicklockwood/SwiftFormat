//
//  RedundantMemberwiseInit.swift
//  SwiftFormat
//
//  Created by Miguel Jimenez on 6/17/25.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove redundant explicit memberwise initializers from structs
    static let redundantMemberwiseInit = FormatRule(
        help: "Remove explicit internal memberwise initializers that are redundant.",
        orderAfter: [.redundantInit],
        options: ["prefer-synthesized-init-for-internal-structs"]
    ) { formatter in
        // Parse all struct declarations
        let allDeclarations = formatter.parseDeclarations()

        for declaration in allDeclarations where declaration.keyword == "struct" {
            guard let structDeclaration = declaration.asTypeDeclaration else { continue }

            // Get the struct's access level
            let structAccessLevel = declaration.accessLevel()

            // Collect stored properties from the struct body
            var storedProperties = [(name: String, type: TypeName, declaration: Declaration)]()

            for childDeclaration in structDeclaration.body {
                guard ["var", "let"].contains(childDeclaration.keyword),
                      let property = formatter.parsePropertyDeclaration(atIntroducerIndex: childDeclaration.keywordIndex),
                      let type = property.type,
                      childDeclaration.isStoredInstanceProperty
                else { continue }
                storedProperties.append((name: property.identifier, type: type, declaration: childDeclaration))
            }

            guard !storedProperties.isEmpty else { continue }

            // Find all init declarations in the struct body
            let allInitDeclarations = structDeclaration.body.filter { $0.keyword == "init" }

            // If there are multiple inits, don't remove any memberwise init
            // as the compiler won't synthesize it
            guard allInitDeclarations.count == 1 else { continue }

            // Find init declarations in the struct body
            for initDeclaration in structDeclaration.body where initDeclaration.keyword == "init" {
                // Get the init's access level
                let initAccessLevel = initDeclaration.accessLevel()

                // Don't remove public or package inits
                // (compiler won't generate public memberwise init)
                if initAccessLevel == .public || initAccessLevel == .package {
                    continue
                }

                // Determine if we should try to remove private access control from properties
                let shouldRemovePrivateACL = formatter.shouldPreferSynthesizedInit(
                    for: structDeclaration,
                    structAccessLevel: structAccessLevel,
                    initAccessLevel: initAccessLevel
                )

                // Compute what visibility the synthesized init would have after any modifications.
                // The synthesized init has the minimum visibility of all stored properties in the memberwise init.
                // We can only remove private ACL from properties that don't have SwiftUI attributes (like @State).
                let synthesizedInitVisibility: Visibility = structDeclaration.body.reduce(.internal) { minVisibility, childDeclaration in
                    guard ["var", "let"].contains(childDeclaration.keyword),
                          childDeclaration.isStoredInstanceProperty
                    else { return minVisibility }

                    let accessLevel = childDeclaration.accessLevel()
                    guard accessLevel == .private || accessLevel == .fileprivate else { return minVisibility }

                    // @Environment properties are NOT part of memberwise init
                    if childDeclaration.hasModifier("@Environment") {
                        return minVisibility
                    }

                    let property = formatter.parsePropertyDeclaration(atIntroducerIndex: childDeclaration.keywordIndex)
                    let hasDefaultValue = property?.value != nil

                    // Private `let` with default value is NOT in memberwise init
                    if childDeclaration.keyword == "let", hasDefaultValue {
                        return minVisibility
                    }

                    // If we're not removing private ACL, this property affects init visibility
                    guard shouldRemovePrivateACL else {
                        return min(minVisibility, accessLevel)
                    }

                    // Private property with SwiftUI property wrapper (and no default) - we won't modify it
                    if childDeclaration.swiftUIPropertyWrapper != nil, !hasDefaultValue {
                        return min(minVisibility, accessLevel)
                    }

                    // We'll remove private ACL from this property, so it won't affect visibility
                    return minVisibility
                }

                // Don't remove init if it would change the access level
                // Only remove if explicit init visibility matches synthesized init visibility
                if initAccessLevel != synthesizedInitVisibility {
                    continue
                }

                // Don't remove init if it has a doc comment
                if let docCommentRange = initDeclaration.docCommentRange,
                   formatter.isDocComment(startOfComment: docCommentRange.lowerBound)
                {
                    continue
                }

                // Don't remove failable inits (init? or init!)
                // Check if there's a ? or ! after the init keyword
                if let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: initDeclaration.keywordIndex),
                   let nextToken = formatter.token(at: nextIndex),
                   nextToken.isOperator("?") || nextToken.isOperator("!")
                {
                    continue
                }

                // Don't remove inits that have attributes (e.g. @usableFromInline, @inlinable)
                // since these attributes can't be applied to synthesized memberwise inits
                if !initDeclaration.attributes.isEmpty {
                    continue
                }

                // Parse the init function using the parseFunctionDeclaration helper
                guard let functionDecl = formatter.parseFunctionDeclaration(keywordIndex: initDeclaration.keywordIndex),
                      let bodyRange = functionDecl.bodyRange
                else { continue }

                // Check if parameters match stored properties exactly
                let parameters = functionDecl.arguments.compactMap { arg -> Formatter.InitParameter? in
                    guard let name = arg.internalLabel else { return nil }

                    // Check for default value by looking for '=' after the type
                    let hasDefaultValue = formatter.checkForDefaultValue(arg: arg)

                    // Check if the property has a result builder attribute
                    let resultBuilderAttribute = arg.attributes.first(where: { $0.contains("Builder") })

                    return Formatter.InitParameter(
                        name: name,
                        type: arg.type,
                        externalLabel: arg.externalLabel,
                        hasDefaultValue: hasDefaultValue,
                        resultBuilderAttribute: resultBuilderAttribute
                    )
                }

                // Don't remove if init has more arguments than we can process
                // (e.g., parameters with `_` internal labels are filtered out above)
                guard functionDecl.arguments.count == parameters.count else { continue }

                // Don't remove if any parameter has a default value
                guard !parameters.contains(where: \.hasDefaultValue) else { continue }

                // Don't remove if any parameter has different external and internal labels
                // This includes cases where external label is explicitly different or uses underscore
                guard !parameters.contains(where: { param in
                    // If externalLabel is nil, it means underscore was used (different from internal name)
                    // If externalLabel exists and is different from internal name, it's also different
                    param.externalLabel == nil || (param.externalLabel != nil && param.externalLabel != param.name)
                }) else { continue }

                // Before Swift 6.4 there's a bug where synthesized inits with result builder attributes
                // in _non-generic structs_ behave incorrectly and can crash at runtime:
                // https://github.com/swiftlang/swift/pull/86272
                // Only apply this change to generic structs before Swift 6.4.
                if formatter.options.swiftVersion < "6.4",
                   parameters.contains(where: { $0.resultBuilderAttribute != nil })
                {
                    guard structDeclaration.genericParameters != nil else { continue }
                }

                // Only consider properties that don't have default values for memberwise init comparison
                // Properties with default values are optional in memberwise init
                let propertiesWithoutDefaults = storedProperties.filter { prop in
                    // Check if this stored property has a default value
                    !formatter.hasDefaultValue(propertyName: prop.name, in: structDeclaration)
                }

                guard parameters.count == propertiesWithoutDefaults.count,
                      zip(parameters, propertiesWithoutDefaults).allSatisfy({ formatter.parameterMatchesProperty($0, property: $1) })
                else { continue }

                // Check if body only contains memberwise assignments
                let bodyStart = bodyRange.lowerBound + 1
                let bodyEnd = bodyRange.upperBound
                var isRedundant = true
                var bodyIndex = bodyStart
                var assignmentCount = 0

                // Check for any comments in the body first - if present, don't remove
                for tokenIndex in bodyStart ..< bodyEnd {
                    let token = formatter.tokens[tokenIndex]
                    if token.isComment {
                        isRedundant = false
                        break
                    }
                }

                // Track which parameters need result builder attributes transferred to the property
                var assignmentsNeedingResultBuilder = Set<String>()

                if isRedundant {
                    while let nextToken = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: bodyIndex - 1),
                          nextToken < bodyEnd
                    {
                        let token = formatter.tokens[nextToken]

                        if token == .identifier("self") {
                            guard let dotIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: nextToken, if: {
                                $0.isOperator(".")
                            }),
                                let propIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: dotIndex),
                                let propToken = formatter.token(at: propIndex),
                                propToken.isIdentifier,
                                let equalsIndex = formatter.index(of: .operator("=", .infix), after: propIndex),
                                let valueIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: equalsIndex),
                                let valueToken = formatter.token(at: valueIndex),
                                valueToken.isIdentifier,
                                propToken.string == valueToken.string,
                                propertiesWithoutDefaults.contains(where: { $0.name == propToken.string })
                            else {
                                isRedundant = false
                                break
                            }

                            // Check if this is a closure invocation: `self.prop = param()`
                            var nextAfterValue = valueIndex + 1
                            if let parenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: valueIndex),
                               formatter.tokens[parenIndex] == .startOfScope("("),
                               let endParen = formatter.endOfScope(at: parenIndex),
                               formatter.index(of: .nonSpaceOrCommentOrLinebreak, in: parenIndex + 1 ..< endParen) == nil
                            {
                                // This is `param()` - a closure invocation with no arguments
                                assignmentsNeedingResultBuilder.insert(propToken.string)
                                nextAfterValue = endParen + 1
                            } else if let param = parameters.first(where: { $0.name == propToken.string }),
                                      param.resultBuilderAttribute != nil
                            {
                                // This is a direct closure assignment with a result builder attribute
                                assignmentsNeedingResultBuilder.insert(propToken.string)
                            }

                            assignmentCount += 1
                            bodyIndex = nextAfterValue
                        } else {
                            isRedundant = false
                            break
                        }
                    }
                }

                // Remove redundant init if all assignments match (only for properties without defaults)
                if isRedundant, assignmentCount == propertiesWithoutDefaults.count {
                    // Add result builder attribute to properties that need them
                    // This includes both closure invocations (self.prop = param()) and direct assignments (self.prop = param)
                    for property in propertiesWithoutDefaults {
                        guard assignmentsNeedingResultBuilder.contains(property.name),
                              let attribute = parameters.first(where: { $0.name == property.name })?.resultBuilderAttribute
                        else { continue }

                        let insertIndex = property.declaration.startOfModifiersIndex(includingAttributes: true)
                        formatter.insert(tokenize(attribute) + [.space(" ")], at: insertIndex)
                    }

                    // Remove private access control from eligible properties
                    // (only when option is enabled and synthesized init would be internal)
                    if shouldRemovePrivateACL, synthesizedInitVisibility == .internal {
                        for childDeclaration in structDeclaration.body {
                            guard ["var", "let"].contains(childDeclaration.keyword),
                                  childDeclaration.isStoredInstanceProperty
                            else { continue }

                            // Don't remove private from properties with SwiftUI property wrappers (like @State)
                            guard childDeclaration.swiftUIPropertyWrapper == nil else { continue }

                            // Don't remove private from `let` properties with default values
                            // (they're not in the memberwise init)
                            if childDeclaration.keyword == "let" {
                                let prop = formatter.parsePropertyDeclaration(atIntroducerIndex: childDeclaration.keywordIndex)
                                if prop?.value != nil {
                                    continue
                                }
                            }

                            if childDeclaration.visibility() == .private {
                                childDeclaration.removeVisibility(.private)
                            } else if childDeclaration.visibility() == .fileprivate {
                                childDeclaration.removeVisibility(.fileprivate)
                            }
                        }
                    }

                    // Re-calculate the removal range after potential insertions and ACL removals
                    // Use the declaration's range which includes leading comments
                    let startRemovalIndex = initDeclaration.range.lowerBound
                    let updatedBodyRange = formatter.parseFunctionDeclaration(keywordIndex: initDeclaration.keywordIndex)?.bodyRange ?? bodyRange
                    let endRemovalIndex = updatedBodyRange.upperBound

                    // Find the range including preceding whitespace, but be conservative about trailing
                    var actualStartIndex = startRemovalIndex
                    var actualEndIndex = endRemovalIndex

                    // Include preceding spaces and blank line
                    while actualStartIndex > 0 {
                        if let prevToken = formatter.token(at: actualStartIndex - 1), prevToken.isSpace {
                            actualStartIndex -= 1
                        } else {
                            break
                        }
                    }
                    if actualStartIndex > 0 {
                        if let prevToken = formatter.token(at: actualStartIndex - 1), prevToken.isLinebreak {
                            actualStartIndex -= 1
                        }
                    }

                    // Include trailing spaces and one newline to clean up properly
                    while actualEndIndex + 1 < formatter.tokens.count {
                        let next = formatter.token(at: actualEndIndex + 1)!
                        if next.isSpace {
                            actualEndIndex += 1
                        } else if next.isLinebreak {
                            // Include one newline to clean up, but stop there
                            actualEndIndex += 1
                            break
                        } else {
                            break
                        }
                    }

                    // Remove the init
                    formatter.removeTokens(in: actualStartIndex ... actualEndIndex)
                }
            }
        }
    } examples: {
        """
        ```diff
          struct User {
              var name: String
              var age: Int

        -     init(name: String, age: Int) {
        -         self.name = name
        -         self.age = age
        -     }
          }
        ```

        ```diff
          struct MyView<Content: View>: View {
        +     @ViewBuilder let content: Content
        -     let content: Content
        -
        -     init(@ViewBuilder content: () -> Content) {
        -         self.content = content()
        -     }

              var body: some View {
                  content
              }
          }
        ```

        `--prefer-synthesized-init-for-internal-structs View,ViewModifier`:

        ```diff
          struct ProfileView: View {
        -     init(user: User, settings: Settings) {
        -         self.user = user
        -         self.settings = settings
        -     }
        -
        -     private let user: User
        -     private let settings: Settings
        +     let user: User
        +     let settings: Settings

              var body: some View { ... }
          }
        ```
        """
    }
}

extension Declaration {
    /// Helper function to get the access level of a declaration
    func accessLevel() -> Visibility {
        visibility() ?? .internal
    }
}

extension Formatter {
    /// A parsed init parameter with additional metadata
    struct InitParameter {
        let name: String
        let type: TypeName
        let externalLabel: String?
        let hasDefaultValue: Bool
        let resultBuilderAttribute: String?
    }

    /// Helper function to check if a stored property has a default value
    func hasDefaultValue(propertyName: String, in structDeclaration: TypeDeclaration) -> Bool {
        for childDeclaration in structDeclaration.body {
            guard ["var", "let"].contains(childDeclaration.keyword),
                  let property = parsePropertyDeclaration(atIntroducerIndex: childDeclaration.keywordIndex),
                  property.identifier == propertyName,
                  property.value != nil
            else { continue }
            return true
        }
        return false
    }

    /// Helper function to check if a function argument has a default value
    func checkForDefaultValue(arg: Formatter.FunctionArgument) -> Bool {
        // Start searching after the internal label index
        let searchIndex = arg.internalLabelIndex + 1

        // Find the colon
        guard let colonIndex = index(of: .delimiter(":"), after: searchIndex - 1) else {
            return false
        }

        // Find the end of the type after the colon
        guard let typeStartIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: colonIndex) else {
            return false
        }

        // Parse the type to find its end
        guard let typeInfo = parseType(at: typeStartIndex) else {
            return false
        }
        let typeEndIndex = typeInfo.range.upperBound

        // Look for '=' token after the type
        if let equalsIndex = index(of: .operator("=", .infix), after: typeEndIndex),
           index(of: .nonSpaceOrCommentOrLinebreak, in: typeEndIndex + 1 ..< equalsIndex) == nil
        {
            return true
        }

        return false
    }

    /// Determines whether we should prefer synthesized init for the given struct
    func shouldPreferSynthesizedInit(
        for structDeclaration: TypeDeclaration,
        structAccessLevel: Visibility,
        initAccessLevel: Visibility
    ) -> Bool {
        // Must be internal or lower access level
        guard structAccessLevel != .public,
              structAccessLevel != .package,
              initAccessLevel != .public,
              initAccessLevel != .package
        else { return false }

        switch options.preferSynthesizedInitForInternalStructs {
        case .never:
            return false
        case .always:
            return true
        case let .conformances(requiredConformances):
            let structConformances = Set(structDeclaration.conformances.map(\.conformance.string))
            return requiredConformances.contains { structConformances.contains($0) }
        }
    }

    /// Collects all tokens for an attribute starting at the given index.
    /// Handles generic attributes like @ArrayBuilder<String> by including the generic clause.
    func collectAttributeTokens(startingAt index: Int) -> [Token] {
        var result = [tokens[index]]

        // Check if there's a generic clause following the attribute
        if let nextIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, after: index),
           tokens[nextIndex] == .startOfScope("<"),
           let endOfGeneric = endOfScope(at: nextIndex)
        {
            // Include all tokens from attribute to end of generic clause
            for i in (index + 1) ... endOfGeneric {
                result.append(tokens[i])
            }
        }

        return result
    }

    /// Checks if a parameter matches a property, accounting for result builder closure patterns
    func parameterMatchesProperty(
        _ param: InitParameter,
        property: (name: String, type: TypeName, declaration: Declaration)
    ) -> Bool {
        // Names must match
        guard param.name == property.name else { return false }

        // If it's a result builder parameter with a closure type, check if the closure's return type matches the property type
        if param.resultBuilderAttribute != nil,
           param.type.string == "() -> \(property.type.string)"
        {
            return true
        }

        // Check if types match exactly
        if param.type == property.type {
            return true
        }

        // Check if types match after stripping @escaping from the parameter type.
        // Stored closure properties are implicitly escaping, so `@escaping () -> Void` parameter
        // is equivalent to `() -> Void` property.
        let paramTypeWithoutEscaping = param.type.string
            .replacingOccurrences(of: "@escaping ", with: "")
        if paramTypeWithoutEscaping == property.type.string {
            return true
        }

        return false
    }
}
