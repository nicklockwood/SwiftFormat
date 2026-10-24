//
//  RedundantCompactMap.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 17/10/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Replaces compactMap with map when the transform cannot return nil.
    static let redundantCompactMap = FormatRule(
        help: "Replace `compactMap` with `map` when the transform returns non-optional values."
    ) { formatter in
        guard formatter.tokens.contains(.identifier("compactMap")) else { return }
        let fileURL = formatter.currentFileURL ?? URL(fileURLWithPath: "/SwiftFormat/Input.swift")
        let filePath = fileURL.standardizedFileURL.path
        let indexedProject = formatter.projectIndex(requiring: [.declarations]).flatMap { index in
            index.files[filePath]?.moduleIdentifiers.isEmpty == false ? index : nil
        }
        let project = indexedProject ?? ProjectIndex(files: [
            filePath: makeSourceFileIndex(
                from: sourceCode(for: formatter.tokens),
                moduleIdentifiers: ["SwiftFormat.CurrentFile"],
                includeFunctionReferences: false,
                includeSymbolReferences: false
            ),
        ])
        let shadowedNames = formatter.compactMapShadowedFunctionNames()
        formatter.forEach(.identifier("compactMap")) { i, _ in
            guard formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) == .operator(".", .infix),
                  let arguments = formatter.parseFunctionCallArguments(after: i),
                  arguments.count == 1, arguments[0].label == nil
            else { return }
            let valueRange = arguments[0].valueRange
            guard let start = formatter.index(
                of: .nonSpaceOrCommentOrLinebreak,
                in: valueRange.lowerBound ..< valueRange.upperBound + 1
            ), let end = formatter.index(
                of: .nonSpaceOrCommentOrLinebreak,
                before: valueRange.upperBound + 1
            ), start <= end else { return }
            let range = start ... end
            let returnsNonOptional: Bool
            if formatter.tokens[range.lowerBound] == .startOfScope("{") {
                guard formatter.endOfScope(at: start) == end else { return }
                returnsNonOptional = formatter.compactMapClosureReturnsNonOptional(
                    at: range.lowerBound, project: project, fileURL: fileURL, shadowedNames: shadowedNames
                )
            } else {
                returnsNonOptional = formatter.compactMapFunctionReturnsNonOptional(
                    in: range, project: project, fileURL: fileURL, shadowedNames: shadowedNames
                )
            }
            guard returnsNonOptional else { return }
            formatter.replaceToken(at: i, with: .identifier("map"))
        }
    } examples: {
        """
        ```diff
          func name(for value: Value) -> String { ... }
        - let names = values.compactMap { name(for: $0) }
        + let names = values.map { name(for: $0) }
        - let names = values.compactMap(name(for:))
        + let names = values.map(name(for:))
        - let names = values.compactMap(name)
        + let names = values.map(name)
        ```

        Uses project-indexed return types when available, otherwise declarations in the current file.
        Transforms with optional or unresolved results are preserved.
        """
    }
}

extension Formatter {
    func compactMapFunctionReturnsNonOptional(
        in range: ClosedRange<Int>,
        project: ProjectIndex,
        fileURL: URL,
        shadowedNames: Set<String>
    ) -> Bool {
        var nameIndex = range.lowerBound
        guard tokens[nameIndex].isIdentifier || ["self", "Self"].contains(tokens[nameIndex].string) else {
            return false
        }
        if let dot = index(of: .nonSpaceOrCommentOrLinebreak, after: nameIndex),
           tokens[dot] == .operator(".", .infix),
           let member = index(of: .nonSpaceOrCommentOrLinebreak, after: dot)
        {
            guard !shadowedNames.contains(tokens[nameIndex].string) else { return false }
            nameIndex = member
        }
        guard tokens[nameIndex].isIdentifier, !shadowedNames.contains(tokens[nameIndex].string) else {
            return false
        }
        let labels: [String?]?
        if nameIndex == range.upperBound {
            labels = nil
        } else {
            guard let open = index(of: .nonSpaceOrCommentOrLinebreak, after: nameIndex),
                  endOfScope(at: open) == range.upperBound,
                  let referenceLabels = parseFunctionReferenceLabels(at: open)
            else { return false }
            labels = referenceLabels
        }
        guard let receiver = project.functionCallReceiver(at: nameIndex, in: self, visibleFrom: fileURL),
              let declarations = project.resolveFunctionReference(
                  named: tokens[nameIndex].string, receiver: receiver,
                  argumentLabels: labels, visibleFrom: fileURL
              )
        else { return false }
        return declarations.allSatisfy {
            guard let type = $0.returnType else { return false }
            return project.isKnownNonOptionalType(type, visibleFrom: fileURL)
        }
    }

    /// Without lexical name resolution, a binding can hide an indexed function.
    func compactMapShadowedFunctionNames() -> Set<String> {
        var names = Set<String>()
        parseDeclarations().forEachRecursiveDeclaration { declaration in
            if let range = declaration.asTypeDeclaration?.genericParameters?.range {
                names.formUnion(tokens[range].filter(\.isIdentifier).map(\.string))
            }
        }
        forEachToken { i, token in
            if token == .keyword("let") || token == .keyword("var") {
                names.formUnion(namesInDeclaration(at: i) ?? [])
            } else if token.isFunctionDeclarationKeyword,
                      let function = parseFunctionDeclaration(keywordIndex: i)
            {
                names.formUnion(function.arguments.compactMap(\.internalLabel))
                if let range = function.genericParameterRange {
                    names.formUnion(tokens[range].filter(\.isIdentifier).map(\.string))
                }
                if declarationScope(at: i) == .local ||
                    modifiersForDeclaration(at: i, contains: "private") ||
                    modifiersForDeclaration(at: i, contains: "fileprivate")
                {
                    if let name = function.name {
                        names.insert(name)
                    }
                }
            } else if token == .startOfScope("{"), isStartOfClosure(at: i),
                      let arguments = parseClosureArguments(at: i)
            {
                names.formUnion(arguments.argumentIndices.map { tokens[$0].string })
                if let captures = arguments.captureListRange {
                    names.formUnion(tokens[captures].filter(\.isIdentifier).map(\.string))
                }
            } else if token == .keyword("for"),
                      let patternStart = startOfForLoopPattern(after: i),
                      let inIndex = index(of: .keyword("in"), in: patternStart ..< tokens.count)
            {
                names.formUnion(tokens[patternStart ..< inIndex].filter(\.isIdentifier).map(\.string))
            }
        }
        return names
    }

    func compactMapClosureReturnsNonOptional(
        at start: Int,
        project: ProjectIndex,
        fileURL: URL,
        shadowedNames: Set<String>
    ) -> Bool {
        guard let end = endOfScope(at: start) else { return false }
        let arguments = parseClosureArguments(at: start)
        if let returnRange = arguments?.returnTypeRange {
            guard let arrow = index(of: .operator("->", .infix), in: returnRange),
                  let typeStart = index(of: .nonSpaceOrCommentOrLinebreak, after: arrow),
                  let type = parseType(at: typeStart)
            else { return false }
            return !shadowedNames.contains(type.withoutParens().string) &&
                project.isKnownNonOptionalType(type.string, visibleFrom: fileURL)
        }
        guard var first = index(of: .nonSpaceOrCommentOrLinebreak, after: arguments?.inKeywordIndex ?? start),
              let last = index(of: .nonSpaceOrCommentOrLinebreak, before: end), first <= last
        else { return false }
        if tokens[first] == .keyword("return") {
            guard let value = index(of: .nonSpaceOrCommentOrLinebreak, after: first) else { return false }
            first = value
        }
        return compactMapExpressionIsNonOptional(in: first ... last, project: project,
                                                 fileURL: fileURL, shadowedNames: shadowedNames)
    }

    func compactMapExpressionIsNonOptional(
        in range: ClosedRange<Int>,
        project: ProjectIndex,
        fileURL: URL,
        shadowedNames: Set<String>
    ) -> Bool {
        let start = range.lowerBound, end = range.upperBound
        if start == end {
            return tokens[start].isNumber || ["true", "false"].contains(tokens[start].string)
        }
        if tokens[start].isStringDelimiter, endOfScope(at: start) == end {
            return true
        }
        if tokens[start] == .startOfScope("("), endOfScope(at: start) == end,
           let first = index(of: .nonSpaceOrCommentOrLinebreak, after: start),
           let last = index(of: .nonSpaceOrCommentOrLinebreak, before: end), first <= last
        {
            return compactMapExpressionIsNonOptional(in: first ... last, project: project,
                                                     fileURL: fileURL, shadowedNames: shadowedNames)
        }
        if ["try", "await"].contains(tokens[start].string),
           let value = index(of: .nonSpaceOrCommentOrLinebreak, after: start),
           !tokens[value].isUnwrapOperator
        {
            return compactMapExpressionIsNonOptional(in: value ... end, project: project,
                                                     fileURL: fileURL, shadowedNames: shadowedNames)
        }
        // Only a complete, unambiguously resolved call is safe. In particular, don't
        // infer the result of optional chaining, casts, subscripts, or operators.
        guard tokens[end] == .endOfScope(")"),
              let open = startOfScope(at: end),
              let nameIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: open),
              tokens[nameIndex].isIdentifier,
              !shadowedNames.contains(tokens[nameIndex].string),
              nameIndex == start || (
                  !shadowedNames.contains(tokens[start].string) &&
                      index(of: .nonSpaceOrCommentOrLinebreak, after: start).map {
                          tokens[$0] == .operator(".", .infix) &&
                              index(of: .nonSpaceOrCommentOrLinebreak, after: $0) == nameIndex
                      } == true
              ),
              let receiver = project.functionCallReceiver(at: nameIndex, in: self, visibleFrom: fileURL),
              let call = project.resolveFunctionCall(
                  named: tokens[nameIndex].string,
                  receiver: receiver,
                  argumentLabels: parseFunctionCallArguments(startOfScope: open).map(\.label),
                  visibleFrom: fileURL
              )
        else { return false }
        // An inherited member may shadow a free function. The index cannot resolve
        // that lookup, so don't use its global fallback as proof of a return type.
        if case let .unqualified(declaringType, _) = receiver,
           call.matches.contains(where: { $0.declaration.declaringType != declaringType })
        {
            return false
        }
        return call.matches.allSatisfy {
            guard let type = $0.declaration.returnType else { return false }
            return project.isKnownNonOptionalType(type, visibleFrom: fileURL)
        }
    }
}
