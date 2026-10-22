//
//  RedundantStaticMemberType.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 22/10/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Removes static member type qualifiers supplied by the surrounding context.
    static let redundantStaticMemberType = FormatRule(
        help: "Remove redundant type qualifiers from static member references.",
        orderAfter: [.redundantType, .propertyTypes, .redundantReturn]
    ) { formatter in
        let bindings = formatter.explicitBindingTypes()
        var shadowedFunctions = Set(bindings.keys)
        // The project index excludes private declarations; they may still affect overload resolution here.
        formatter.parseDeclarations().forEachRecursiveDeclaration { declaration in
            if declaration.keyword == "func",
               ([declaration] + declaration.parentDeclarations).contains(where: {
                   $0.visibility() == .private || $0.visibility() == .fileprivate
               }), let name = declaration.name
            {
                shadowedFunctions.insert(name)
            }
        }
        formatter.forEach(.keyword("func")) { i, _ in
            if formatter.declarationScope(at: i) == .local,
               let name = formatter.parseFunctionDeclaration(keywordIndex: i)?.name
            {
                shadowedFunctions.insert(name)
            }
        }
        let fileURL = formatter.currentFileURL ?? URL(fileURLWithPath: "/SwiftFormat/Input.swift")
        var project: ProjectIndex?
        func index() -> ProjectIndex {
            if let project {
                return project
            }
            let path = fileURL.standardizedFileURL.path
            let indexed = formatter.projectIndex(requiring: [.declarations]).flatMap {
                $0.files[path]?.moduleIdentifiers.isEmpty == false ? $0 : nil
            }
            let result = indexed ?? ProjectIndex(files: [path: makeSourceFileIndex(
                from: sourceCode(for: formatter.tokens), moduleIdentifiers: ["SwiftFormat.CurrentFile"],
                includeFunctionReferences: false, includeSymbolReferences: false
            )])
            project = result
            return result
        }
        formatter.forEach(.identifier) { i, token in
            guard bindings[token.string] == nil,
                  formatter.next(.nonSpace, after: i)?.isOperator(".") == true,
                  let previous = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i)
            else { return }
            let expectedType: String?
            switch formatter.tokens[previous] {
            case .keyword("return"):
                expectedType = formatter.staticMemberReturnType(at: i, implicit: false)
            case .startOfScope("{"):
                expectedType = formatter.staticMemberReturnType(at: i, implicit: true)
            case .operator("=", .infix):
                expectedType = formatter.staticMemberAssignmentType(
                    before: previous, bindings: bindings, project: index, fileURL: fileURL
                )
            case .startOfScope("("), .delimiter(","), .delimiter(":"):
                expectedType = formatter.staticMemberArgumentType(
                    at: i, project: index(), fileURL: fileURL, shadowedFunctions: shadowedFunctions
                )
            default:
                return
            }
            guard let expectedType else { return }
            formatter.removeStaticMemberType(at: i, expectedType: expectedType)
        }
    } examples: {
        """
        ```diff
          func foo() -> Bar {
        -     Bar.value
        +     .value
          }

          var foo: Bar
        - foo = Bar.value
        + foo = .value
        ```

        Uses explicit local types and unambiguous project-indexed property and parameter types.
        Unresolved types and overloaded function calls are preserved.
        """
    }
}

extension Formatter {
    func removeStaticMemberType(at start: Int, expectedType: String) {
        let typeTokens = tokenize(expectedType).filter { !$0.isSpaceOrLinebreak }
        // Optional promotion, generic substitutions and existential lookup need type checking.
        guard !typeTokens.isEmpty, typeTokens.allSatisfy({ $0.isIdentifier || $0.isOperator(".") }),
              !typeTokens.contains(.identifier("Self"))
        else { return }
        var cursor = start
        for token in typeTokens {
            guard tokens[cursor] == token,
                  let next = index(of: .nonSpace, after: cursor)
            else { return }
            cursor = next
        }
        guard tokens[cursor].isOperator("."),
              let member = index(of: .nonSpace, after: cursor), tokens[member].isIdentifier,
              tokens[member] != .identifier("self"),
              let expression = parseExpressionRange(startingAt: start)
        else { return }
        var end = member
        if let next = index(of: .nonSpaceOrCommentOrLinebreak, after: member),
           tokens[next] == .startOfScope("("), let close = endOfScope(at: next)
        {
            end = close
        }
        // Don't remove a qualifier from a subexpression whose context is different.
        guard expression.upperBound == end else { return }
        removeTokens(in: start ..< cursor)
    }

    func staticMemberReturnType(at expression: Int, implicit: Bool) -> String? {
        var cursor = expression
        while let scope = startOfScope(at: cursor) {
            guard !isStartOfClosure(at: scope),
                  let keyword = indexOfLastSignificantKeyword(at: scope, excluding: ["where", "throws"])
            else { return nil }
            if implicit {
                guard index(of: .nonSpaceOrCommentOrLinebreak, after: scope) == expression,
                      blockBodyHasSingleStatement(atStartOfScope: scope, includingConditionalStatements: false,
                                                  includingReturnStatements: false)
                else { return nil }
            }
            if tokens[keyword].isFunctionDeclarationKeyword,
               let function = parseFunctionDeclaration(keywordIndex: keyword),
               function.bodyRange?.lowerBound == scope
            {
                guard function.genericParameterRange == nil,
                      !modifiersForDeclaration(at: keyword, contains: { _, modifier in modifier.hasPrefix("@") })
                else { return nil }
                return function.returnType?.string
            }
            if tokens[keyword] == .keyword("var") || tokens[keyword] == .keyword("let"),
               let property = parsePropertyDeclaration(atIntroducerIndex: keyword),
               property.body?.scopeRange.lowerBound == scope
            {
                guard !modifiersForDeclaration(at: keyword, contains: { _, modifier in modifier.hasPrefix("@") }) else {
                    return nil
                }
                return property.type?.string
            }
            // Implicit returns only apply to the immediately enclosing body.
            // Observers and setters never inherit their enclosing function's result type.
            if implicit || ["set", "willSet", "didSet"].contains(tokens[keyword].string) {
                return nil
            }
            cursor = scope
        }
        return nil
    }

    func staticMemberBindingType(
        named name: String, at index: Int, bindings: [String: [ExplicitBindingType]]
    ) -> String? {
        guard let matches = bindings[name], matches.count == 1, let binding = matches.first,
              !binding.type.isEmpty, binding.scope?.range.contains(index) != false
        else { return nil }
        return tokenize(binding.type).drop(while: {
            $0.isSpace || ["inout", "borrowing", "consuming", "sending"].contains($0.string)
        }).string
    }

    func staticMemberAssignmentType(
        before equals: Int, bindings: [String: [ExplicitBindingType]],
        project: () -> ProjectIndex, fileURL: URL
    ) -> String? {
        guard let name = index(of: .nonSpaceOrCommentOrLinebreak, before: equals), tokens[name].isIdentifier else {
            return nil
        }
        if let dot = index(of: .nonSpaceOrCommentOrLinebreak, before: name), tokens[dot].isOperator(".") {
            guard let receiver = index(of: .nonSpaceOrCommentOrLinebreak, before: dot),
                  last(.nonSpaceOrCommentOrLinebreak, before: receiver)?.isOperator(".") != true
            else { return nil }
            let owner = tokens[receiver] == .identifier("self")
                ? parseEnclosingType(containing: equals)?.fullyQualifiedName
                : staticMemberBindingType(named: tokens[receiver].string, at: equals, bindings: bindings)
            guard let owner else { return nil }
            let project = project()
            let modules = Set(project.files[fileURL.standardizedFileURL.path]?.moduleIdentifiers ?? [])
            let properties = project.files.values.filter { !modules.isDisjoint(with: $0.moduleIdentifiers) }
                .flatMap(\.propertyDeclarations).filter { $0.declaringType == owner && $0.name == tokens[name].string }
            guard properties.count == 1 else { return nil }
            return properties.first?.type
        }
        // Declarations belong to redundantType / propertyTypes, not this rule.
        guard let previous = index(of: .nonSpaceOrCommentOrLinebreak, before: name),
              ![Token.keyword("let"), .keyword("var"), .delimiter(":"), .operator("=", .infix)].contains(tokens[previous])
        else { return nil }
        return staticMemberBindingType(named: tokens[name].string, at: equals, bindings: bindings)
    }

    func staticMemberArgumentType(
        at expression: Int, project: ProjectIndex, fileURL: URL, shadowedFunctions: Set<String>
    ) -> String? {
        guard let scope = startOfScope(at: expression), tokens[scope] == .startOfScope("("),
              let function = parseFunctionIdentifier(beforeStartOfScope: scope),
              !shadowedFunctions.contains(tokens[function].string),
              let receiver = project.functionCallReceiver(at: function, in: self, visibleFrom: fileURL)
        else { return nil }
        let arguments = parseFunctionCallArguments(startOfScope: scope)
        guard let argument = arguments.firstIndex(where: { $0.valueRange.lowerBound == expression }),
              let resolved = project.resolveFunctionCall(
                  named: tokens[function].string, receiver: receiver,
                  argumentLabels: arguments.map(\.label), visibleFrom: fileURL
              )
        else { return nil }
        let types = resolved.matches.compactMap { match -> String? in
            let parameter = match.parameterIndices[argument]
            guard let types = match.declaration.argumentTypes, types.indices.contains(parameter) else { return nil }
            return types[parameter]
        }
        guard types.count == resolved.matches.count, Set(types).count == 1 else { return nil }
        return types.first
    }
}
