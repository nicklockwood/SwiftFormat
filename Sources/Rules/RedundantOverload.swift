//
//  RedundantOverload.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 10/6/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Replaces forwarding overloads with default arguments on the original declaration
    static let redundantOverload = FormatRule(
        help: "Replace forwarding overloads with default arguments.",
        usesProjectContext: true,
        options: ["overload-visibility"]
    ) { formatter in
        let candidates = formatter.redundantOverloadCandidates().filter { candidate in
            guard let fileURL = formatter.currentFileURL,
                  let projectIndex = formatter.projectIndex,
                  let function = formatter.parseFunctionDeclaration(keywordIndex: candidate.wrapper.keywordIndex),
                  let name = function.name
            else { return true }
            return !projectIndex.containsFunctionReference(
                named: name,
                argumentLabels: function.arguments.map(\.externalLabel),
                declaringType: candidate.wrapper.parentType?.fullyQualifiedName,
                declaringTypeKind: candidate.wrapper.parentType?.keyword,
                visibility: formatter.effectiveVisibility(of: candidate.wrapper),
                visibleFrom: fileURL
            )
        }

        // A pair of overloads can each appear to default a different argument of the
        // same declaration. Applying both would introduce a new call that omits both
        // arguments, so only update declarations with a single forwarding overload.
        let candidatesByTarget = Dictionary(grouping: candidates, by: { $0.target.identity })
        let unambiguousCandidates = candidates.filter { candidatesByTarget[$0.target.identity]?.count == 1 }

        for candidate in unambiguousCandidates.sorted(by: { $0.wrapper.range.lowerBound > $1.wrapper.range.lowerBound }) {
            guard let match = formatter.defaultArgumentMatch(
                wrapper: candidate.wrapper,
                target: candidate.target,
                kind: candidate.kind
            ) else { continue }

            formatter.insert([
                .space(" "),
                .operator("=", .infix),
                .space(" "),
            ] + Array(formatter.tokens[match.defaultValueRange]), at: match.insertionIndex)

            formatter.removeDeclarationAndAdjacentBlankLine(candidate.wrapper)
        }
    } examples: {
        """
        ```diff
          struct Loader {
        -     func load(path: String, timeout: TimeInterval) { ... }
        +     func load(path: String, timeout: TimeInterval = 30) { ... }
        -     func load(path: String) {
        -         load(path: path, timeout: 30)
        -     }
          }
        ```

        With `--swift-version 5.1` or later:

        ```diff
          enum Result<Value> {
        -     case success(value: Value, cached: Bool)
        +     case success(value: Value, cached: Bool = false)
          }

          extension Result {
        -     static func success(value: Value) -> Self {
        -         .success(value: value, cached: false)
        -     }
          }
        ```
        """
    }
}

extension Formatter {
    struct RedundantOverloadCandidate {
        enum Kind {
            case function
            case enumCase
        }

        let wrapper: Declaration
        let target: Declaration
        let kind: Kind
    }

    struct RedundantDefaultArgumentMatch {
        let insertionIndex: Int
        let defaultValueRange: ClosedRange<Int>
    }

    struct DefaultableParameter {
        let externalLabel: String?
        let internalName: String?
        let type: TypeName
        let attributes: [String]
        let hasDefaultValue: Bool
        let allowsDefaultValue: Bool
    }

    struct EnumCaseDeclaration {
        let name: String
        let declaration: Declaration
        let parameters: [DefaultableParameter]
    }

    func redundantOverloadCandidates() -> [RedundantOverloadCandidate] {
        let declarations = parseDeclarations()
        var typeDeclarationsByName = [String: [TypeDeclaration]]()

        declarations.forEachRecursiveDeclaration { declaration in
            guard let typeDeclaration = declaration.asTypeDeclaration,
                  let name = typeDeclaration.fullyQualifiedName
            else { return }
            typeDeclarationsByName[name, default: []].append(typeDeclaration)
        }

        var candidates = [RedundantOverloadCandidate]()

        for typeDeclarations in typeDeclarationsByName.values {
            // Protocol requirements can't have default arguments. Extensions of a
            // protocol are excluded as well, since they share the same qualified name.
            guard !typeDeclarations.contains(where: { $0.keyword == "protocol" }) else { continue }

            let functions = typeDeclarations.flatMap { typeDeclaration in
                typeDeclaration.body.filter { $0.keyword == "func" }
            }

            for wrapper in functions where !declarationIsObjectiveC(wrapper) &&
                effectiveVisibility(of: wrapper) <= options.overloadVisibility
            {
                let matchingFunctions = functions.filter { target in
                    target !== wrapper && defaultArgumentMatch(
                        wrapper: wrapper,
                        target: target,
                        kind: .function
                    ) != nil
                }

                if matchingFunctions.count == 1, let target = matchingFunctions.first {
                    candidates.append(.init(wrapper: wrapper, target: target, kind: .function))
                }
            }

            guard options.swiftVersion >= "5.1",
                  let enumDeclaration = typeDeclarations.first(where: { $0.keyword == "enum" })
            else { continue }

            let enumCases = enumDeclaration.body.compactMap(parseEnumCaseDeclaration)
            let extensionFunctions = typeDeclarations
                .filter { $0.keyword == "extension" }
                .flatMap { typeDeclaration in
                    typeDeclaration.body.filter { declaration in
                        declaration.keyword == "func" && declaration.hasModifier("static")
                    }
                }

            for wrapper in extensionFunctions where !declarationIsObjectiveC(wrapper) &&
                effectiveVisibility(of: wrapper) <= options.overloadVisibility
            {
                let matchingCases = enumCases.filter { enumCase in
                    defaultArgumentMatch(
                        wrapper: wrapper,
                        target: enumCase.declaration,
                        kind: .enumCase
                    ) != nil
                }

                if matchingCases.count == 1, let enumCase = matchingCases.first {
                    candidates.append(.init(wrapper: wrapper, target: enumCase.declaration, kind: .enumCase))
                }
            }
        }

        return candidates
    }

    func defaultArgumentMatch(
        wrapper: Declaration,
        target: Declaration,
        kind: RedundantOverloadCandidate.Kind
    ) -> RedundantDefaultArgumentMatch? {
        guard wrapper.isValid, target.isValid,
              !wrapper.tokens.contains(where: \.isComment),
              let wrapperFunction = parseFunctionDeclaration(keywordIndex: wrapper.keywordIndex),
              wrapperFunction.bodyRange != nil,
              let call = forwardingCall(in: wrapperFunction)
        else { return nil }

        let targetName: String
        let targetParameters: [DefaultableParameter]
        let insertionIndexForParameter: (Int) -> Int?

        switch kind {
        case .function:
            guard !declarationIsObjectiveC(target),
                  let targetFunction = parseFunctionDeclaration(keywordIndex: target.keywordIndex),
                  targetFunction.bodyRange != nil,
                  matchingFunctionSignatures(wrapperFunction, targetFunction),
                  matchingNonVisibilityModifiers(wrapper, target),
                  wrapperVisibilityDoesNotExceedTarget(wrapper, target)
            else { return nil }

            targetName = targetFunction.name ?? ""
            targetParameters = defaultableParameters(in: targetFunction)
            insertionIndexForParameter = { index in
                targetParameters.indices.contains(index) ? targetParameters[index].type.range.upperBound + 1 : nil
            }

        case .enumCase:
            guard options.swiftVersion >= "5.1",
                  wrapper.hasModifier("static"),
                  wrapper.parentType.map({ extensionIsUnconstrained($0) }) == true,
                  wrapper.modifiers.allSatisfy({
                      $0 == "static" || Visibility(rawValue: $0) != nil
                  }),
                  let enumCase = parseEnumCaseDeclaration(target),
                  let enumDeclaration = enumCase.declaration.parentType,
                  effectiveVisibility(of: wrapper) <= effectiveVisibility(of: enumDeclaration),
                  wrapperFunction.returnType.map({ ["Self", wrapper.parentType?.name].compactMap { $0 }.contains($0.string) }) == true
            else { return nil }

            targetName = enumCase.name
            targetParameters = enumCase.parameters
            insertionIndexForParameter = { index in
                targetParameters.indices.contains(index) ? targetParameters[index].type.range.upperBound + 1 : nil
            }
        }

        guard wrapperFunction.name == targetName,
              call.name == targetName,
              wrapperFunction.arguments.count + 1 == targetParameters.count,
              call.arguments.count == targetParameters.count
        else { return nil }

        let wrapperParameters = defaultableParameters(in: wrapperFunction)
        guard wrapperParameters.count == wrapperFunction.arguments.count else { return nil }

        var wrapperParameterIndex = 0
        var defaultParameterIndex: Int?
        var defaultValueRange: ClosedRange<Int>?

        for (targetParameterIndex, targetParameter) in targetParameters.enumerated() {
            let callArgument = call.arguments[targetParameterIndex]
            guard callArgument.label == targetParameter.externalLabel else { return nil }

            if wrapperParameters.indices.contains(wrapperParameterIndex) {
                let wrapperParameter = wrapperParameters[wrapperParameterIndex]
                let forwardedTokens = tokens[callArgument.valueRange].filter { !$0.isSpaceOrCommentOrLinebreak }

                if let internalName = wrapperParameter.internalName,
                   forwardedTokens == [.identifier(internalName)],
                   wrapperParameter.externalLabel == targetParameter.externalLabel,
                   wrapperParameter.type.string == targetParameter.type.string,
                   wrapperParameter.attributes == targetParameter.attributes
                {
                    wrapperParameterIndex += 1
                    continue
                }
            }

            guard defaultParameterIndex == nil,
                  !targetParameter.hasDefaultValue,
                  targetParameter.allowsDefaultValue,
                  validDefaultArgumentExpression(
                      in: callArgument.valueRange,
                      parameterNames: Set(targetParameters.compactMap(\.internalName))
                  )
            else { return nil }

            defaultParameterIndex = targetParameterIndex
            defaultValueRange = callArgument.valueRange
        }

        guard wrapperParameterIndex == wrapperParameters.count,
              let defaultParameterIndex,
              let defaultValueRange,
              let insertionIndex = insertionIndexForParameter(defaultParameterIndex)
        else { return nil }

        return RedundantDefaultArgumentMatch(
            insertionIndex: insertionIndex,
            defaultValueRange: defaultValueRange
        )
    }

    func matchingFunctionSignatures(
        _ wrapper: FunctionDeclaration,
        _ target: FunctionDeclaration
    ) -> Bool {
        guard wrapper.name == target.name,
              wrapper.effects == target.effects,
              wrapper.returnType?.string == target.returnType?.string,
              tokenString(in: wrapper.genericParameterRange) == tokenString(in: target.genericParameterRange),
              tokenString(in: wrapper.whereClauseRange) == tokenString(in: target.whereClauseRange)
        else { return false }

        return true
    }

    func tokenString(in range: ClosedRange<Int>?) -> String? {
        range.map { tokens[$0].filter { !$0.isSpaceOrCommentOrLinebreak }.map(\.string).joined() }
    }

    func defaultableParameters(in function: FunctionDeclaration) -> [DefaultableParameter] {
        let elements = commaSeparatedElementsInScope(startOfScope: function.argumentsRange.lowerBound)
        guard elements.count == function.arguments.count else { return [] }

        return zip(function.arguments, elements).map { argument, element in
            let trailingTokens = tokens[argument.type.range.upperBound + 1 ..< element.upperBound + 1]
            return DefaultableParameter(
                externalLabel: argument.externalLabel,
                internalName: argument.internalLabel,
                type: argument.type,
                attributes: argument.attributes,
                hasDefaultValue: trailingTokens.contains(.operator("=", .infix)),
                allowsDefaultValue: !argument.type.string.hasPrefix("inout ") &&
                    !trailingTokens.contains(.operator("...", .postfix))
            )
        }
    }

    func parseEnumCaseDeclaration(_ declaration: Declaration) -> EnumCaseDeclaration? {
        guard declaration.keyword == "case",
              declaration.parentType?.keyword == "enum",
              let nameIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: declaration.keywordIndex),
              tokens[nameIndex].isIdentifier,
              let openParen = index(of: .nonSpaceOrCommentOrLinebreak, after: nameIndex),
              tokens[openParen] == .startOfScope("("),
              let closeParen = endOfScope(at: openParen),
              index(of: .delimiter(","), in: closeParen + 1 ..< declaration.range.upperBound + 1) == nil
        else { return nil }

        let elements = commaSeparatedElementsInScope(startOfScope: openParen)
        var parameters = [DefaultableParameter]()

        for element in elements {
            let colonIndex = index(of: .delimiter(":"), in: element)
            let externalLabel: String?
            let typeStart: Int

            if let colonIndex,
               let labelIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: colonIndex),
               element.contains(labelIndex),
               let start = index(of: .nonSpaceOrCommentOrLinebreak, after: colonIndex)
            {
                externalLabel = tokens[labelIndex].string == "_" ? nil : tokens[labelIndex].unescaped()
                typeStart = start
            } else if let start = index(of: .nonSpaceOrCommentOrLinebreak, after: element.lowerBound - 1) {
                externalLabel = nil
                typeStart = start
            } else {
                return nil
            }

            guard let type = parseType(at: typeStart) else { return nil }
            parameters.append(DefaultableParameter(
                externalLabel: externalLabel,
                internalName: nil,
                type: type,
                attributes: [],
                hasDefaultValue: index(of: .operator("=", .infix), in: type.range.upperBound + 1 ..< element.upperBound + 1) != nil,
                allowsDefaultValue: true
            ))
        }

        return EnumCaseDeclaration(
            name: tokens[nameIndex].unescaped(),
            declaration: declaration,
            parameters: parameters
        )
    }

    func forwardingCall(in function: FunctionDeclaration) -> (name: String, arguments: [FunctionCallArgument])? {
        guard let bodyRange = function.bodyRange,
              var callStart = index(of: .nonSpaceOrCommentOrLinebreak, after: bodyRange.lowerBound),
              callStart < bodyRange.upperBound
        else { return nil }

        if tokens[callStart] == .keyword("return") {
            guard let next = index(of: .nonSpaceOrCommentOrLinebreak, after: callStart) else { return nil }
            callStart = next
        }

        for effect in ["try", "await"] where tokens[callStart].string == effect {
            guard let next = index(of: .nonSpaceOrCommentOrLinebreak, after: callStart) else { return nil }
            callStart = next
        }

        guard let openParen = index(of: .startOfScope("("), after: callStart - 1),
              openParen < bodyRange.upperBound,
              let closeParen = endOfScope(at: openParen),
              index(of: .nonSpaceOrCommentOrLinebreak, after: closeParen) == bodyRange.upperBound
        else { return nil }

        let calleeTokens = tokens[callStart ..< openParen]
            .filter { !$0.isSpaceOrCommentOrLinebreak }
            .map(\.string)

        let name: String
        if calleeTokens.count == 1 {
            name = calleeTokens[0]
        } else if calleeTokens.count == 2, calleeTokens[0] == "." {
            name = calleeTokens[1]
        } else if calleeTokens.count == 3,
                  calleeTokens[1] == ".",
                  calleeTokens[0] == "self" || calleeTokens[0] == "Self" || calleeTokens[0].first?.isUppercase == true
        {
            name = calleeTokens[2]
        } else {
            return nil
        }

        return (name, parseFunctionCallArguments(startOfScope: openParen))
    }

    func validDefaultArgumentExpression(
        in range: ClosedRange<Int>,
        parameterNames: Set<String>
    ) -> Bool {
        for index in range {
            let token = tokens[index]
            guard !token.isComment else { return false }

            if ["super", "try", "await", "throw", "inout", "Self"].contains(token.string) {
                return false
            }

            if token.string == "self" {
                let previous = self.index(of: .nonSpaceOrCommentOrLinebreak, before: index)
                guard previous.map({ range.contains($0) && tokens[$0].string == "." }) == true else {
                    return false
                }
            }

            guard token.isIdentifier else {
                if token == .operator("=", .infix) || token == .operator("&", .prefix) {
                    return false
                }
                continue
            }

            let name = token.unescaped()
            if ["nil", "true", "false"].contains(name) {
                continue
            }

            let previous = self.index(of: .nonSpaceOrCommentOrLinebreak, before: index)
            if previous.map({ range.contains($0) && tokens[$0].string == "." }) == true {
                continue
            }

            let next = self.index(of: .nonSpaceOrCommentOrLinebreak, after: index)
            if next.map({ range.contains($0) && tokens[$0] == .delimiter(":") }) == true {
                continue
            }

            guard !parameterNames.contains(name), name.first?.isUppercase == true else {
                return false
            }
        }

        return parseExpressionRange(startingAt: range.lowerBound) == range
    }

    func declarationIsObjectiveC(_ declaration: Declaration) -> Bool {
        let objectiveCModifiers = [
            "@IBAction", "@IBDesignable", "@IBInspectable", "@IBOutlet",
            "@IBSegueAction", "@GKInspectable", "@NSManaged", "dynamic",
        ]
        if declaration.modifiers.contains(where: {
            objectiveCModifiers.contains($0) || $0.hasPrefix("@objc")
        }) {
            return true
        }

        return declaration.parentDeclarations.contains { parent in
            parent.modifiers.contains(where: { $0 == "@objcMembers" || $0.hasPrefix("@objc") })
        }
    }

    func matchingNonVisibilityModifiers(_ lhs: Declaration, _ rhs: Declaration) -> Bool {
        lhs.modifiers.filter { Visibility(rawValue: $0) == nil } ==
            rhs.modifiers.filter { Visibility(rawValue: $0) == nil }
    }

    func wrapperVisibilityDoesNotExceedTarget(_ wrapper: Declaration, _ target: Declaration) -> Bool {
        guard effectiveVisibility(of: wrapper) <= effectiveVisibility(of: target) else {
            return false
        }

        // An unmodified member of a `private extension` can be accessed from
        // elsewhere in the file, whereas an explicitly private member can't.
        if target.visibility() == .private, wrapper.visibility() != .private {
            return false
        }
        return true
    }

    func extensionIsUnconstrained(_ declaration: TypeDeclaration) -> Bool {
        declaration.keyword == "extension" &&
            index(of: .keyword("where"), in: declaration.keywordIndex ..< declaration.openBraceIndex) == nil
    }

    func removeDeclarationAndAdjacentBlankLine(_ declaration: Declaration) {
        let previousLinebreak = index(of: .linebreak, before: declaration.range.lowerBound)
        let precedingBlankLine = previousLinebreak.flatMap { linebreak -> Int? in
            guard let previousToken = index(of: .nonSpace, before: linebreak),
                  tokens[previousToken].isLinebreak
            else { return nil }
            return linebreak
        }

        let nextLinebreak = index(of: .linebreak, after: declaration.range.upperBound)
        let followingBlankLine = nextLinebreak.flatMap { linebreak -> Int? in
            guard let nextToken = index(of: .nonSpace, after: linebreak),
                  tokens[nextToken].isLinebreak
            else { return nil }
            return linebreak
        }

        let siblings = declaration.parent?.body ?? []
        let siblingIndex = siblings.firstIndex { $0 === declaration }
        let blankLine: Int?
        if let siblingIndex {
            if siblingIndex == siblings.startIndex {
                blankLine = followingBlankLine
            } else if siblingIndex == siblings.index(before: siblings.endIndex) {
                blankLine = precedingBlankLine
            } else {
                blankLine = nil
            }
        } else {
            blankLine = nil
        }

        if let blankLine {
            removeToken(at: blankLine)
        }
        declaration.remove()
    }
}
