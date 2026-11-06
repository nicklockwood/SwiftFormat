//
//  ProjectSymbolLookup.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 11/05/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

/// Resolves simple expressions through scoped bindings and indexed declarations, without guessing from case names.
final class ProjectSymbolLookup {
    struct TupleElement {
        var label: String?
        var type: ResolvedType
    }

    enum CollectionKind: String {
        case array = "Array"
        case dictionary = "Dictionary"
        case set = "Set"
        case arraySlice = "ArraySlice"
        case contiguousArray = "ContiguousArray"
        case dictionaryKeys = "Dictionary.Keys"
        case dictionaryValues = "Dictionary.Values"
        case enumeratedSequence = "EnumeratedSequence"
        case reversedCollection = "ReversedCollection"
        case slice = "Slice"
    }

    struct ElementBinding {
        var source: AutoUpdatingRange
        var tuplePath: [Int]
    }

    final class FunctionType {
        let parameters: [ResolvedType]
        let result: ResolvedType

        init(parameters: [ResolvedType], result: ResolvedType) {
            self.parameters = parameters
            self.result = result
        }
    }

    struct ResolvedType {
        var name: String
        var namespace: String?
        var sourceFileURL: URL?
        var genericArguments: [ResolvedType]?
        var isMetatype = false
        var functionType: FunctionType?
        var tupleElements: [TupleElement]?
        var collectionKind: CollectionKind?
        var genericBounds: [ResolvedType]?
    }

    struct PayloadBinding {
        var caseName: String
        var payloadIndex: Int
        var unwrapsOptional: Bool
    }

    struct PatternBinding {
        var source: AutoUpdatingRange
        var path: [PayloadBinding]
    }

    struct ClosureBinding {
        var location: AutoUpdatingRange
        var parameterIndex: Int
    }

    struct Binding {
        var element: ElementBinding?
        var closure: ClosureBinding?
        var pattern: PatternBinding?
        var wrapsOptional = false
        var location: AutoUpdatingRange
        var scope: AutoUpdatingRange
        var type: String?
        var value: AutoUpdatingRange?
        var namespace: String?
        var unwrapsOptional = false
        var requiresPrecedingDeclaration = false
        var isGlobal = false
        var typeRequiresGenericArguments = false
        var excludedScope: AutoUpdatingRange?

        func isVisible(at index: Int) -> Bool {
            scope.range.contains(index) && excludedScope?.range.contains(index) != true &&
                (!requiresPrecedingDeclaration || location.range.lowerBound < index)
        }
    }

    let formatter: Formatter
    let project: ProjectIndex
    let fileURL: URL
    let declarations: [Declaration]
    var bindings = [String: [Binding]]()
    var unavailableTypes = [String: [AutoUpdatingRange]]()

    var localTypes = [String: [TypeDeclaration]]()
    var unindexedFunctions = Set<String>()

    init(formatter: Formatter, project: ProjectIndex, fileURL: URL) {
        self.formatter = formatter
        self.project = project
        self.fileURL = fileURL
        declarations = formatter.parseDeclarations()
        declarations.forEachRecursiveDeclaration { declaration in
            if let type = declaration.asTypeDeclaration {
                if type.definesType, let name = type.fullyQualifiedName {
                    self.localTypes[name, default: []].append(type)
                }
                if let parameters = type.genericParameters {
                    for parameter in parameters.types {
                        self.unavailableTypes[parameter.name, default: []].append(AutoUpdatingRange(range: type.range, formatter: formatter))
                    }
                }
            }
        }
        func lexicalScope(at index: Int) -> Int? {
            var start = formatter.startOfScope(at: index)
            while let scope = start, formatter.tokens[scope] != .startOfScope("{"), formatter.tokens[scope] != .startOfScope(":") {
                start = formatter.startOfScope(at: scope)
            }
            return start
        }
        formatter.forEachToken { i, token in
            guard ["typealias", "let", "var", "for", "class", "struct", "enum", "actor"].contains(token.string) ||
                token.isFunctionDeclarationKeyword || token == .startOfScope("{") else { return }
            let namespace = formatter.parseEnclosingType(containing: i, declarations: self.declarations)?.fullyQualifiedName
            if token == .keyword("typealias"), formatter.declarationScope(at: i) == .local,
               let name = formatter.next(.identifier, after: i)?.string
            {
                let scope = formatter.startOfScope(at: i) ?? 0
                self.unavailableTypes[name, default: []].append(AutoUpdatingRange(range: scope ... (formatter.endOfScope(at: scope) ?? formatter.tokens.count - 1), formatter: formatter))
            }
            if ["class", "struct", "enum", "actor"].contains(token.string), formatter.declarationScope(at: i) == .local,
               let name = formatter.next(.identifier, after: i)?.string
            {
                let scope = formatter.startOfScope(at: i) ?? 0
                self.unavailableTypes[name, default: []].append(AutoUpdatingRange(range: scope ... (formatter.endOfScope(at: scope) ?? formatter.tokens.count - 1), formatter: formatter))
            }
            if token == .keyword("let") || token == .keyword("var") {
                let scopeStart = formatter.startOfScope(at: i) ?? 0
                let scopeEnd = formatter.endOfScope(at: scopeStart) ?? formatter.tokens.count - 1
                var scope = scopeStart ... scopeEnd
                let conditional = formatter.startOfConditionalStatement(at: i).flatMap {
                    lexicalScope(at: $0) == lexicalScope(at: i) ? $0 : nil
                }
                let isPattern = formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) == .keyword("case") ||
                    formatter.startOfScope(at: i).map { formatter.tokens[$0] == .startOfScope("(") } == true
                guard !isPattern else { return }
                let property = formatter.parsePropertyDeclaration(atIntroducerIndex: i)
                let names = conditional != nil && property != nil ? [property!.identifier] : formatter.namesInDeclaration(at: i) ?? []
                var unwrapsOptional = false
                var excludedScope: ClosedRange<Int>?
                if let conditional,
                   [Token.keyword("if"), .keyword("guard"), .keyword("while")].contains(formatter.tokens[conditional]),
                   let body = formatter.startOfConditionalBranchBody(after: conditional),
                   let end = formatter.endOfScope(at: body)
                {
                    unwrapsOptional = true
                    let start = (property?.value?.expressionRange.upperBound ?? property?.identifierIndex ?? i) + 1
                    guard start <= body else { return }
                    if formatter.tokens[conditional] == .keyword("guard") {
                        let endOfScope = lexicalScope(at: conditional).flatMap { formatter.endOfScope(at: $0) } ?? formatter.tokens.count - 1
                        guard end <= endOfScope else { return }
                        scope = start ... endOfScope
                        excludedScope = body ... end
                    } else {
                        scope = start ... end
                    }
                }
                for name in names {
                    self.addBinding(name, at: i, scope: scope, type: names.count == 1 ? property?.type?.string : nil,
                                    value: names.count == 1 ? property?.value?.expressionRange : nil, namespace: namespace,
                                    unwrapsOptional: unwrapsOptional, requiresPrecedingDeclaration: formatter.declarationScope(at: i) == .local,
                                    isGlobal: formatter.declarationScope(at: i) == .global, excludedScope: excludedScope)
                }
            } else if token.isFunctionDeclarationKeyword,
                      let function = formatter.parseFunctionDeclaration(keywordIndex: i)
            {
                if formatter.declarationScope(at: i) == .local, let name = function.name {
                    self.unindexedFunctions.insert(name)
                }
                if let parameters = function.genericParameterRange {
                    let scope = i ... (function.bodyRange?.upperBound ?? parameters.upperBound)
                    for parameter in formatter.parseGenericTypes(from: parameters.lowerBound).types {
                        self.unavailableTypes[parameter.name, default: []].append(AutoUpdatingRange(range: scope, formatter: formatter))
                    }
                }
                guard let body = function.bodyRange else { return }
                for argument in function.arguments {
                    if let name = argument.internalLabel {
                        self.addBinding(name, at: argument.internalLabelIndex, scope: body, type: argument.type.string, namespace: namespace, typeRequiresGenericArguments: true)
                    }
                }
            } else if token == .startOfScope("{"), formatter.isStartOfClosure(at: i),
                      let arguments = formatter.parseClosureArguments(at: i), let end = formatter.endOfScope(at: i)
            {
                for (position, argument) in arguments.argumentIndices.enumerated() {
                    let colon = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: argument)
                    let annotation = colon.flatMap { formatter.tokens[$0] == .delimiter(":") ? formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: $0) : nil }
                        .flatMap { formatter.parseType(at: $0)?.string }
                    self.addBinding(formatter.tokens[argument].string, at: argument, scope: arguments.inKeywordIndex ... end,
                                    type: annotation, namespace: namespace,
                                    closure: ClosureBinding(location: AutoUpdatingRange(range: i ... i, formatter: formatter), parameterIndex: position))
                }
                if let captures = arguments.captureListRange {
                    var elements = formatter.commaSeparatedElementsInScope(startOfScope: captures.lowerBound)
                    if elements.isEmpty, let first = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: captures.lowerBound), first < captures.upperBound {
                        elements = [first ... first]
                    }
                    for element in elements {
                        guard var capture = formatter.index(of: .nonSpaceOrCommentOrLinebreak, in: Range(element)) else { continue }
                        if ["weak", "unowned"].contains(formatter.tokens[capture].string),
                           let next = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: capture), next <= element.upperBound,
                           formatter.tokens[next] != .operator("=", .infix)
                        {
                            let ownershipEnd = formatter.tokens[next] == .startOfScope("(") ? formatter.endOfScope(at: next) : nil
                            capture = ownershipEnd.flatMap { formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: $0) } ?? next
                        }
                        guard capture <= element.upperBound, formatter.tokens[capture].isIdentifier else { continue }
                        let value: ClosedRange<Int>?
                        if let equals = formatter.index(of: .operator("=", .infix), in: element),
                           let start = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: equals),
                           let last = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: element.upperBound + 1)
                        {
                            value = start ... last
                        } else {
                            value = capture ... capture
                        }
                        self.addBinding(formatter.tokens[capture].string, at: capture, scope: arguments.inKeywordIndex ... end, value: value,
                                        namespace: namespace, wrapsOptional: formatter.tokens[element].contains(.identifier("weak")))
                    }
                }
            } else if token == .keyword("for"),
                      let start = formatter.startOfForLoopPattern(after: i),
                      let end = formatter.index(of: .keyword("in"), after: i),
                      let body = formatter.startOfForLoopBody(after: i), let close = formatter.endOfScope(at: body)
            {
                let source = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: end)
                    .flatMap { formatter.parseExpressionRange(startingAt: $0) }
                func addElements(in range: ClosedRange<Int>, path: [Int]) {
                    guard let first = formatter.index(of: .nonSpaceOrCommentOrLinebreak, in: Range(range)),
                          let last = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: range.upperBound + 1), first <= last else { return }
                    if first == last, formatter.tokens[first].isIdentifier {
                        let element = source.map { ElementBinding(source: AutoUpdatingRange(range: $0, formatter: formatter), tuplePath: path) }
                        self.addBinding(formatter.tokens[first].string, at: first, scope: body ... close, namespace: namespace, element: element)
                    } else if formatter.tokens[first] == .startOfScope("("), formatter.endOfScope(at: first) == last {
                        for (position, argument) in formatter.parseTupleArguments(startOfScope: first).enumerated() {
                            addElements(in: argument.valueRange, path: path + [position])
                        }
                    } else {
                        for name in formatter.tokens[range] where name.isIdentifier {
                            self.addBinding(name.string, at: i, scope: body ... close, namespace: namespace)
                        }
                    }
                }
                if let last = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: end), start <= last {
                    addElements(in: start ... last, path: [])
                }
            }
        }
        var patterns = [(Range<Int>, ClosedRange<Int>, ClosedRange<Int>?, ClosedRange<Int>?)]()
        formatter.forEach(.keyword("switch")) { index, _ in
            for branch in formatter.switchStatementBranches(at: index) ?? [] {
                guard let keyword = formatter.index(before: branch.startOfBranch, where: { $0.isSwitchCaseOrDefault }) else { continue }
                let start = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index)
                let open = formatter.index(of: .startOfScope("{"), after: index)
                let end = open.flatMap { formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: $0) }
                let subject = start.flatMap { start in end.map { start ... $0 } }
                patterns.append((keyword + 1 ..< branch.startOfBranch, branch.startOfBranch ... branch.endOfBranch, subject, nil))
            }
        }
        formatter.forEachToken { index, token in
            guard ["catch", "if", "guard", "while"].contains(token.string),
                  let body = formatter.startOfConditionalBranchBody(after: index),
                  let end = formatter.endOfScope(at: body) else { return }
            if token == .keyword("catch") {
                self.addBinding("error", at: index, scope: body ... end, namespace: nil)
            }
            if token == .keyword("catch") || formatter.tokens[index ..< body].contains(.keyword("case")) {
                let scopeEnd = token == .keyword("guard")
                    ? formatter.endOfScope(at: formatter.startOfScope(at: index) ?? 0) ?? formatter.tokens.count - 1 : end
                let scope = token == .keyword("guard") ? end ... scopeEnd : body ... end
                var start = index + 1
                while start < body {
                    let separator = formatter.index(of: .delimiter(","), in: start ..< body) ?? body
                    let equals = formatter.index(of: .operator("=", .infix), in: start ..< separator)
                    let subject = equals.flatMap { formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: $0) }
                        .flatMap { formatter.parseExpressionRange(startingAt: $0) }
                    let bindingScope = subject.map { $0.upperBound + 1 ... scope.upperBound } ?? scope
                    patterns.append((start ..< (equals ?? separator), bindingScope, subject, token == .keyword("guard") ? body ... end : nil))
                    start = separator + 1
                }
            }
        }
        for (range, scope, source, excludedScope) in patterns {
            addPatternBindings(in: range, scope: scope, source: source, excludedScope: excludedScope)
        }
    }

    func addPatternBindings(in range: Range<Int>, scope: ClosedRange<Int>, source: ClosedRange<Int>?, excludedScope: ClosedRange<Int>? = nil) {
        var entries = [(String, Int)]()
        formatter.forEachToken(in: range, onlyWhereEnabled: false) { index, token in
            guard token == .keyword("let") || token == .keyword("var") else { return }
            entries += (formatter.namesInDeclaration(at: index) ?? []).map { ($0, index) }
        }
        for (name, index) in entries {
            var pattern: PatternBinding?
            var nameLocation: Int?
            formatter.forEachToken(in: index + 1 ..< range.upperBound, onlyWhereEnabled: false) { location, token in
                if nameLocation == nil, token == .identifier(name) {
                    nameLocation = location
                }
            }
            guard let location = nameLocation else { continue }
            if let source, let first = formatter.startOfScope(at: location), formatter.tokens[first] == .startOfScope("(") {
                let arguments = formatter.parseTupleArguments(startOfScope: first)
                if let argument = arguments.first(where: { $0.valueRange.contains(location) }),
                   formatter.tokens[argument.valueRange].filter({ !$0.isSpaceOrCommentOrLinebreak && $0 != .keyword("let") && $0 != .keyword("var") }).string == name
                {
                    var open: Int? = first
                    var path = [PayloadBinding]()
                    var valid = true
                    while let scope = open, scope >= range.lowerBound, scope < range.upperBound, formatter.tokens[scope] == .startOfScope("(") {
                        guard let caseIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: scope), formatter.tokens[caseIndex].isIdentifier,
                              let dot = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: caseIndex), formatter.tokens[dot].isOperator("."),
                              formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: dot).map({ !formatter.tokens[$0].isIdentifier }) != false,
                              let payloadIndex = formatter.parseTupleArguments(startOfScope: scope).firstIndex(where: { $0.valueRange.contains(location) }),
                              let close = formatter.endOfScope(at: scope) else { valid = false; break }
                        path.append(PayloadBinding(caseName: formatter.tokens[caseIndex].string, payloadIndex: payloadIndex,
                                                   unwrapsOptional: formatter.next(.nonSpaceOrCommentOrLinebreak, after: close)?.isOperator("?") == true))
                        open = formatter.startOfScope(at: dot)
                    }
                    if valid, !path.isEmpty {
                        pattern = PatternBinding(source: AutoUpdatingRange(range: source, formatter: formatter), path: path.reversed())
                    }
                }
            }
            addBinding(name, at: index, scope: scope, namespace: nil, pattern: pattern, excludedScope: excludedScope)
        }
    }

    func addBinding(_ name: String, at index: Int, scope: ClosedRange<Int>, type: String? = nil,
                    value: ClosedRange<Int>? = nil, namespace: String?, unwrapsOptional: Bool = false,
                    requiresPrecedingDeclaration: Bool = false, isGlobal: Bool = false, wrapsOptional: Bool = false, pattern: PatternBinding? = nil, closure: ClosureBinding? = nil, element: ElementBinding? = nil, typeRequiresGenericArguments: Bool = false, excludedScope: ClosedRange<Int>? = nil)
    {
        bindings[name, default: []].append(Binding(
            element: element, closure: closure, pattern: pattern, wrapsOptional: wrapsOptional, location: AutoUpdatingRange(range: index ... index, formatter: formatter),
            scope: AutoUpdatingRange(range: scope, formatter: formatter), type: type,
            value: value.map { AutoUpdatingRange(range: $0, formatter: formatter) }, namespace: namespace,
            unwrapsOptional: unwrapsOptional, requiresPrecedingDeclaration: requiresPrecedingDeclaration, isGlobal: isGlobal,
            typeRequiresGenericArguments: typeRequiresGenericArguments,
            excludedScope: excludedScope.map { AutoUpdatingRange(range: $0, formatter: formatter) }
        ))
    }

    /// Resolve an annotated type in its declaration's lexical namespace, including aliases.
    func type(named rawName: String, namespace: String?, at index: Int? = nil, sourceFileURL: URL? = nil, substitutions: [String: ResolvedType] = [:], requiresGenericArguments: Bool = false, depth: Int = 0) -> ResolvedType? {
        guard depth < 16 else { return nil }
        let tokens = tokenize(rawName).filter { !$0.isSpaceOrCommentOrLinebreak }
            .drop(while: { ["inout", "borrowing", "consuming", "sending", "any"].contains($0.string) })
        if let index, tokens.contains(where: { token in
            token.isIdentifier && (unavailableTypes[token.string] ?? []).contains { $0.range.contains(index) }
        }) {
            return nil
        }
        let name = tokens.string
        let optional = name.hasSuffix("?") || name.hasSuffix("!")
        let base = optional ? String(name.dropLast()) : name
        if base == "Self", let namespace,
           project.typeDeclaration(named: namespace, visibleFrom: sourceFileURL ?? fileURL)?.enumCases != nil ||
           localTypes[namespace]?.contains(where: { $0.keyword == "enum" }) == true
        {
            return type(named: namespace + (optional ? "?" : ""), namespace: nil, at: index,
                        sourceFileURL: sourceFileURL, substitutions: substitutions, depth: depth + 1)
        }
        if var substitution = substitutions[base] {
            if optional {
                substitution.name += "?"
            }
            return substitution
        }
        if base.hasSuffix(".Type"),
           var value = type(named: String(base.dropLast(5)), namespace: namespace, at: index,
                            sourceFileURL: sourceFileURL, substitutions: substitutions,
                            requiresGenericArguments: requiresGenericArguments, depth: depth + 1)
        {
            guard !value.isMetatype, unwrapped(value) == nil else { return nil }
            value.isMetatype = true
            if optional {
                value.name += "?"
            }
            return value
        }
        if let dot = base.firstIndex(of: "."), let owner = substitutions[String(base[..<dot])] {
            guard var value = dependentMemberType(String(base[base.index(after: dot)...]), of: owner, depth: depth + 1) else { return nil }
            if optional {
                value.name += "?"
            }
            return value
        }
        let grouped = Formatter(tokenize(base))
        if grouped.tokens.first == .startOfScope("("),
           let close = grouped.endOfScope(at: 0), close == grouped.tokens.count - 1,
           grouped.parseTupleArguments(startOfScope: 0).count == 1,
           let argument = grouped.parseTupleArguments(startOfScope: 0).first,
           var value = type(named: grouped.tokens[argument.valueRange].string, namespace: namespace, at: index,
                            sourceFileURL: sourceFileURL, substitutions: substitutions,
                            requiresGenericArguments: requiresGenericArguments, depth: depth + 1)
        {
            if optional {
                value.name += "?"
            }
            return value
        }
        if grouped.tokens.first == .startOfScope("["), grouped.endOfScope(at: 0) == grouped.tokens.count - 1 {
            let colon = grouped.index(of: .delimiter(":"), in: 1 ..< grouped.tokens.count - 1)
            let parts = colon.map { [1 ..< $0, $0 + 1 ..< grouped.tokens.count - 1] } ?? [1 ..< grouped.tokens.count - 1]
            let arguments = parts.compactMap {
                type(named: grouped.tokens[$0].string, namespace: namespace, at: index, sourceFileURL: sourceFileURL,
                     substitutions: substitutions, requiresGenericArguments: true, depth: depth + 1)
            }
            guard arguments.count == parts.count else { return nil }
            var result = collectionType(colon == nil ? .array : .dictionary, arguments: arguments)
            if optional {
                result.name += "?"
            }
            return result
        }
        guard let nominal = ProjectTypeReference(base) else {
            let signature = Formatter(tokenize(name))
            if let open = signature.index(of: .nonSpaceOrCommentOrLinebreak, after: -1),
               signature.tokens[open] == .startOfScope("("),
               let close = signature.endOfScope(at: open),
               close == signature.tokens.count - 1 || optional && close == signature.tokens.count - 2,
               signature.parseTupleArguments(startOfScope: open).count > 1
            {
                let parameters = signature.parseTupleArguments(startOfScope: open)
                let elements = parameters.compactMap { parameter -> TupleElement? in
                    guard let value = type(named: signature.tokens[parameter.valueRange].string,
                                           namespace: namespace, at: index, sourceFileURL: sourceFileURL,
                                           substitutions: substitutions, requiresGenericArguments: requiresGenericArguments,
                                           depth: depth + 1) else { return nil }
                    return TupleElement(label: parameter.label, type: value)
                }
                guard elements.count == parameters.count else { return nil }
                return ResolvedType(name: name, namespace: namespace, sourceFileURL: sourceFileURL, tupleElements: elements)
            }
            var functionType: FunctionType?
            var foundFunctionSignature = false
            signature.forEach(.startOfScope("(")) { open, _ in
                guard !foundFunctionSignature, signature.isStartOfClosureType(at: open),
                      let close = signature.endOfScope(at: open),
                      let arrow = signature.index(of: .operator("->", .infix), after: close) else { return }
                foundFunctionSignature = true
                let parameters = signature.parseTupleArguments(startOfScope: open)
                let resolved = parameters.compactMap {
                    type(named: signature.tokens[$0.valueRange].string, namespace: namespace, at: index,
                         sourceFileURL: sourceFileURL, substitutions: substitutions,
                         requiresGenericArguments: true, depth: depth + 1)
                }
                if resolved.count == parameters.count,
                   let result = type(named: signature.tokens[arrow + 1 ..< signature.tokens.count].string,
                                     namespace: namespace, at: index, sourceFileURL: sourceFileURL,
                                     substitutions: substitutions, requiresGenericArguments: true, depth: depth + 1)
                {
                    functionType = FunctionType(parameters: resolved, result: result)
                }
            }
            // A result's optional suffix belongs to the result, not to the function value.
            return ResolvedType(name: functionType == nil ? name : "(" + name + ")", namespace: namespace,
                                sourceFileURL: sourceFileURL, functionType: functionType)
        }

        let arguments = nominal.arguments.compactMap {
            type(named: $0, namespace: namespace, at: index, sourceFileURL: sourceFileURL, substitutions: substitutions, requiresGenericArguments: true, depth: depth + 1)
        }
        guard arguments.count == nominal.arguments.count,
              let lexical = qualifiedTypeName(for: ResolvedType(name: base, namespace: namespace, sourceFileURL: sourceFileURL)) else { return nil }
        let lexicalName = lexical.name
        let lexicalSource = lexical.sourceFileURL ?? sourceFileURL
        let builtinName = lexicalName.hasPrefix("Swift.") ? String(lexicalName.dropFirst(6)) : lexicalName
        if let kind = CollectionKind(rawValue: builtinName), ![.dictionaryKeys, .dictionaryValues].contains(kind),
           !nominal.hasGenericParent, arguments.count == (kind == .dictionary ? 2 : 1),
           project.isStandardLibraryTypeName(lexicalName, visibleFrom: lexicalSource ?? fileURL)
        {
            var result = collectionType(kind, arguments: arguments)
            if optional {
                result.name += "?"
            }
            return result
        }
        let symbol = !nominal.hasGenericParent && (requiresGenericArguments || !nominal.arguments.isEmpty)
            ? project.typeSymbol(named: lexicalName, genericArgumentCount: arguments.count, visibleFrom: lexicalSource ?? fileURL)
            : nil
        let qualified = symbol?.name ?? lexicalName
        let sourceFileURL = symbol?.fileURL ?? lexicalSource
        if let alias = project.typeAlias(named: qualified, visibleFrom: sourceFileURL ?? fileURL,
                                         compilationContext: index.map { formatter.indexedCompilationBranches(at: $0) } ?? [], contextFileURL: fileURL)
        {
            guard alias.hasUnresolvedConstraints != true, alias.genericParameters.count == arguments.count else { return nil }
            let owner = alias.name.contains(".") ? alias.name.split(separator: ".").dropLast().joined(separator: ".") : nil
            var aliasArguments = [String: ResolvedType]()
            if let owner, namespace == owner || namespace?.hasPrefix(owner + ".") == true {
                aliasArguments = substitutions
            }
            for (name, argument) in zip(alias.genericParameters, arguments) {
                aliasArguments[name] = argument
            }
            if let owner, let declaration = project.typeDeclaration(named: owner, visibleFrom: sourceFileURL ?? fileURL),
               !Set(declaration.genericParameters).isSubset(of: aliasArguments.keys)
            {
                return nil
            }
            guard let aliasSource = project.typeSourceFile(named: qualified, visibleFrom: sourceFileURL ?? fileURL),
                  var result = type(named: alias.type, namespace: owner, at: index,
                                    sourceFileURL: aliasSource,
                                    substitutions: aliasArguments, requiresGenericArguments: true, depth: depth + 1) else { return nil }
            if optional {
                result.name += "?"
            }
            return result
        }
        let argumentsSuffix = nominal.arguments.isEmpty ? "" : "<" + nominal.arguments.joined(separator: ",") + ">"
        return ResolvedType(name: qualified + argumentsSuffix + (optional ? String(name.suffix(1)) : ""), namespace: nil, sourceFileURL: sourceFileURL, genericArguments: arguments)
    }

    /// Context can specialize an omitted generic argument list, but cannot change a named type
    /// or replace explicit arguments. Compare declarations rather than unqualified spellings.
    func specializedType(_ value: ResolvedType, expected: ResolvedType?) -> ResolvedType {
        guard let expected = expected.flatMap({ unwrapped($0) ?? $0 }),
              let reference = ProjectTypeReference(value.name), reference.arguments.isEmpty, !reference.hasGenericParent,
              let name = qualifiedName(for: value), let expectedName = qualifiedName(for: expected),
              let identity = project.typeIdentity(named: name, visibleFrom: value.sourceFileURL ?? fileURL),
              identity == project.typeIdentity(named: expectedName, visibleFrom: expected.sourceFileURL ?? fileURL),
              let declaration = project.typeDeclaration(named: name, visibleFrom: value.sourceFileURL ?? fileURL),
              !declaration.genericParameters.isEmpty,
              expected.genericArguments?.count == declaration.genericParameters.count else { return value }
        var result = expected
        result.isMetatype = value.isMetatype
        return result
    }

    /// The nominal declaration name; optional, tuple and function types have no nominal result here.
    func qualifiedName(for type: ResolvedType) -> String? {
        qualifiedTypeName(for: type)?.name
    }

    /// Inherited names retain the declaration file even when only the conformance file imports it.
    func qualifiedTypeName(for type: ResolvedType) -> (name: String, sourceFileURL: URL?)? {
        guard let nominal = ProjectTypeReference(type.name) else { return nil }
        var namespace = type.namespace
        while let owner = namespace {
            if project.isModuleNamespace(owner, visibleFrom: type.sourceFileURL ?? fileURL) {
                break
            }
            let name = "\(owner).\(nominal.name)"
            if (type.sourceFileURL == nil || type.sourceFileURL?.standardizedFileURL == fileURL.standardizedFileURL) && localTypes[name] != nil || project.hasSymbolType(named: name, visibleFrom: type.sourceFileURL ?? fileURL) ||
                project.typeAlias(named: name, visibleFrom: type.sourceFileURL ?? fileURL) != nil
            {
                return (name, type.sourceFileURL)
            }
            let components = nominal.name.split(separator: ".")
            if let root = components.first {
                switch project.inheritedType(named: String(root), of: owner, visibleFrom: type.sourceFileURL ?? fileURL) {
                case let .type(name, source):
                    return (([name] + components.dropFirst().map(String.init)).joined(separator: "."), source)
                case .unknown: return nil
                case .absent: break
                }
            }
            namespace = owner.contains(".") ? owner.split(separator: ".").dropLast().joined(separator: ".") : nil
        }
        return (nominal.name, type.sourceFileURL)
    }

    /// Names alone cannot establish equality when imports introduce namesakes.
    func sameType(_ lhs: ResolvedType, as rhs: ResolvedType) -> Bool {
        guard lhs.isMetatype == rhs.isMetatype else { return false }
        if let left = unwrapped(lhs), let right = unwrapped(rhs) {
            return sameType(left, as: right)
        }
        guard unwrapped(lhs) == nil, unwrapped(rhs) == nil else { return false }
        if let kind = lhs.collectionKind {
            guard kind == rhs.collectionKind, let left = lhs.genericArguments, let right = rhs.genericArguments,
                  left.count == right.count else { return false }
            return zip(left, right).allSatisfy { sameType($0, as: $1) }
        }
        if let left = lhs.tupleElements, let right = rhs.tupleElements {
            return left.count == right.count && zip(left, right).allSatisfy { $0.label == $1.label && sameType($0.type, as: $1.type) }
        }
        if let left = lhs.functionType, let right = rhs.functionType {
            return left.parameters.count == right.parameters.count &&
                zip(left.parameters, right.parameters).allSatisfy { sameType($0, as: $1) } && sameType(left.result, as: right.result)
        }
        if let left = standardScalarName(lhs), let right = standardScalarName(rhs) {
            return left == right
        }
        guard let left = qualifiedName(for: lhs), let right = qualifiedName(for: rhs),
              let identity = project.typeIdentity(named: left, visibleFrom: lhs.sourceFileURL ?? fileURL),
              identity == project.typeIdentity(named: right, visibleFrom: rhs.sourceFileURL ?? fileURL) else { return false }
        let leftArguments = lhs.genericArguments ?? []
        let rightArguments = rhs.genericArguments ?? []
        return leftArguments.count == rightArguments.count && zip(leftArguments, rightArguments).allSatisfy { sameType($0, as: $1) }
    }

    /// Resolve a bare enum case in its declaration's scope without mistaking a local value for it.
    func unqualifiedEnumCase(named name: String, at index: Int) -> (name: String, type: ResolvedType, payloadTypes: [String])? {
        let name = name.replacingOccurrences(of: "`", with: "")
        let spellings = [name, "`\(name)`"]
        guard spellings.allSatisfy({ spelling in
                  !unindexedFunctions.contains(spelling) &&
                      unavailableTypes[spelling]?.contains(where: { $0.range.contains(index) }) != true &&
                      bindings[spelling]?.contains(where: { $0.isVisible(at: index) && !$0.isGlobal }) != true
              }),
              let owner = formatter.parseEnclosingType(containing: index, declarations: declarations)?.fullyQualifiedName,
              case .unqualified(_, true) = project.functionCallReceiver(at: index, in: formatter, visibleFrom: fileURL, declarations: declarations),
              // In a static context, the enum's own case takes precedence over inherited
              // protocol members. Unknown ancestry cannot introduce a shadow of that case.
              let caseName = project.enumCases(named: owner, visibleFrom: fileURL)?.first(where: {
                  $0.replacingOccurrences(of: "`", with: "") == name
              }),
              let payloads = project.typeDeclaration(named: owner, visibleFrom: fileURL)?.enumCasePayloads?[caseName],
              let type = type(named: owner, namespace: nil, at: index) else { return nil }
        return (caseName, type, payloads)
    }

    func bindingType(named name: String, at index: Int, depth: Int) -> ResolvedType? {
        guard depth < 32, !unindexedFunctions.contains(name),
              unavailableTypes[name]?.contains(where: { $0.range.contains(index) }) != true else { return nil }
        if name.hasPrefix("$"), let position = Int(name.dropFirst()) {
            var scope = formatter.startOfScope(at: index)
            while let open = scope {
                if formatter.tokens[open] == .startOfScope("{"), formatter.isStartOfClosure(at: open) {
                    guard formatter.parseClosureArguments(at: open) == nil else { return nil }
                    return closureParameterType(ClosureBinding(location: AutoUpdatingRange(range: open ... open, formatter: formatter), parameterIndex: position), depth: depth + 1)
                }
                scope = formatter.startOfScope(at: open)
            }
            return nil
        }
        let enclosingType = formatter.parseEnclosingType(containing: index, declarations: declarations)?.fullyQualifiedName
        let visible = (bindings[name] ?? []).filter {
            $0.isVisible(at: index)
        }
        if let owner = enclosingType, !visible.contains(where: { !$0.isGlobal }) {
            let receiver = project.functionCallReceiver(at: index, in: formatter, visibleFrom: fileURL, declarations: declarations)
            let isStatic: Bool
            if case let .unqualified(_, value) = receiver {
                isStatic = value
            } else {
                isStatic = false
            }
            if let member = memberType(owner: ResolvedType(name: owner, namespace: nil, isMetatype: isStatic), name: name, accessingType: enclosingType) {
                return member
            }
            guard project.isTypeWithoutInheritance(named: owner, visibleFrom: fileURL),
                  !project.isDynamicMemberLookupType(named: owner, visibleFrom: fileURL),
                  !project.hasProperty(owner: owner, member: name, visibleFrom: fileURL) else { return nil }
        }
        if let size = visible.map(\.scope.range.count).min() {
            let closest = visible.filter { $0.scope.range.count == size }
            let locals = closest.filter(\.requiresPrecedingDeclaration)
            guard let binding = locals.max(by: { $0.location.range.lowerBound < $1.location.range.lowerBound }) ??
                (closest.count == 1 ? closest.first : nil) else { return nil }
            var result: ResolvedType?
            if let annotation = binding.type {
                result = type(named: annotation, namespace: binding.namespace, at: binding.location.range.lowerBound, requiresGenericArguments: binding.typeRequiresGenericArguments)
            } else if let value = binding.value {
                result = expressionType(in: value.range, depth: depth + 1)
            } else if let element = binding.element,
                      let collection = expressionType(in: element.source.range, depth: depth + 1)
            {
                result = collectionElement(of: collection)
                for position in element.tuplePath {
                    result = result.flatMap { memberType(owner: $0, name: String(position)) }
                }
            } else if let closure = binding.closure {
                result = closureParameterType(closure, depth: depth + 1)
            } else if let pattern = binding.pattern,
                      let owner = expressionType(in: pattern.source.range, depth: depth + 1)
            {
                result = owner
                for payload in pattern.path {
                    guard let current = result else { break }
                    let owner = payload.unwrapsOptional ? unwrapped(current) : current
                    result = owner.flatMap { enumPayloadType(owner: $0, caseName: payload.caseName, at: payload.payloadIndex) }
                }
            } else if binding.unwrapsOptional {
                result = bindingType(named: name, at: binding.location.range.lowerBound, depth: depth + 1)
            }
            if binding.wrapsOptional, let current = result, !current.name.hasSuffix("?") {
                result?.name += "?"
            }
            if binding.unwrapsOptional, binding.type == nil, let current = result {
                result = unwrapped(current)
            }
            return result
        }
        guard let owner = enclosingType else { return nil }
        return memberType(owner: ResolvedType(name: owner, namespace: nil), name: name, accessingType: enclosingType)
    }

    func unwrapped(_ type: ResolvedType) -> ResolvedType? {
        guard type.name.hasSuffix("?") || type.name.hasSuffix("!") else { return nil }
        var result = type
        result.name = String(type.name.dropLast())
        return result
    }

    /// Project a receiver through its declared inheritance edges, preserving each edge's imports
    /// and substituting its arguments before proceeding to the next declaration.
    func projectedType(_ owner: ResolvedType, to name: String, source: URL, depth: Int = 0) -> ResolvedType? {
        guard depth < 16, let ownerName = qualifiedName(for: owner),
              let identity = project.typeIdentity(named: ownerName, visibleFrom: owner.sourceFileURL ?? fileURL),
              let targetType = type(named: name, namespace: nil, sourceFileURL: source),
              let targetName = qualifiedName(for: targetType),
              let target = project.typeIdentity(named: targetName, visibleFrom: targetType.sourceFileURL ?? source) else { return nil }
        if identity == target {
            return owner
        }
        guard let substitutions = nominalSubstitutions(for: owner),
              let parents = project.inheritedTypeReferences(owner: ownerName, visibleFrom: owner.sourceFileURL ?? fileURL) else { return nil }
        var result: ResolvedType?
        for parent in parents {
            guard let type = type(named: parent.name, namespace: parent.namespace, sourceFileURL: parent.fileURL,
                                  substitutions: substitutions, requiresGenericArguments: true, depth: depth + 1), let candidate = projectedType(type, to: name, source: source, depth: depth + 1) else { continue }
            guard result == nil || sameType(result!, as: candidate) else { return nil }
            result = candidate
        }
        return result
    }

    func nominalSubstitutions(for owner: ResolvedType) -> [String: ResolvedType]? {
        guard let name = qualifiedName(for: owner) else { return nil }
        if project.isProtocolDeclaration(named: name, visibleFrom: owner.sourceFileURL ?? fileURL) {
            return ["Self": owner]
        }
        guard let declaration = project.typeDeclaration(named: name, visibleFrom: owner.sourceFileURL ?? fileURL),
              declaration.genericParameters.count == (owner.genericArguments ?? []).count else { return nil }
        var result = Dictionary(uniqueKeysWithValues: zip(declaration.genericParameters, owner.genericArguments ?? []))
        result["Self"] = owner
        return result
    }

    /// A subclass can shadow a nested alias without changing its inherited protocol witness.
    /// Locate the declaration that introduces the conformance before looking up that witness.
    func conformanceOwner(_ owner: ResolvedType, to bound: ResolvedType, depth: Int) -> ResolvedType? {
        guard depth < 16, let name = qualifiedName(for: owner), let boundName = qualifiedName(for: bound),
              let substitutions = nominalSubstitutions(for: owner),
              let parents = project.inheritedTypeReferences(owner: name, visibleFrom: owner.sourceFileURL ?? fileURL) else { return nil }
        var result: ResolvedType?
        for parent in parents {
            guard let type = type(named: parent.name, namespace: parent.namespace, sourceFileURL: parent.fileURL,
                                  substitutions: substitutions, requiresGenericArguments: true, depth: depth + 1),
                let parentName = qualifiedName(for: type) else { return nil }
            let candidate: ResolvedType?
            if project.isProtocolDeclaration(named: parentName, visibleFrom: type.sourceFileURL ?? parent.fileURL) {
                candidate = projectedType(type, to: boundName, source: bound.sourceFileURL ?? fileURL, depth: depth + 1) == nil ? nil : owner
            } else {
                candidate = conformanceOwner(type, to: bound, depth: depth + 1)
            }
            guard let candidate else { continue }
            guard result == nil || sameType(result!, as: candidate) else { return nil }
            result = candidate
        }
        return result
    }

    /// Resolve dependent paths such as Model.State from concrete typealias witnesses. An inferred
    /// witness must be backed by concrete property declarations that agree on the same type.
    func dependentMemberType(_ path: String, of owner: ResolvedType, depth: Int) -> ResolvedType? {
        guard depth < 16, !owner.isMetatype, unwrapped(owner) == nil,
              let reference = ProjectTypeReference(path), reference.arguments.isEmpty,
              let component = reference.name.split(separator: ".").first,
              let name = qualifiedName(for: owner),
              let substitutions = nominalSubstitutions(for: owner) else { return nil }
        let member = String(component)
        if let bounds = owner.genericBounds {
            var result: ResolvedType?
            for bound in bounds {
                guard let boundName = qualifiedName(for: bound),
                      project.associatedTypeRequirements(named: member, of: boundName, visibleFrom: bound.sourceFileURL ?? fileURL) != nil else { continue }
                guard var concrete = conformanceOwner(owner, to: bound, depth: depth + 1) else { return nil }
                concrete.genericBounds = nil
                guard let witness = dependentMemberType(path, of: concrete, depth: depth + 1),
                      result == nil || sameType(result!, as: witness) else { return nil }
                result = witness
            }
            return result
        }
        let nestedName = name + "." + member
        var result: ResolvedType?
        if project.hasSymbolType(named: nestedName, visibleFrom: owner.sourceFileURL ?? fileURL) {
            result = type(named: nestedName, namespace: name, sourceFileURL: owner.sourceFileURL ?? fileURL,
                          substitutions: substitutions, requiresGenericArguments: true, depth: depth + 1)
        } else {
            guard let parents = project.inheritedTypeReferences(owner: name, visibleFrom: owner.sourceFileURL ?? fileURL) else { return nil }
            for parent in parents {
                guard let parentType = type(named: parent.name, namespace: parent.namespace, sourceFileURL: parent.fileURL,
                                            substitutions: substitutions, requiresGenericArguments: true, depth: depth + 1) else { return nil }
                if let witness = dependentMemberType(member, of: parentType, depth: depth + 1) {
                    guard result == nil || sameType(result!, as: witness) else { return nil }
                    result = witness
                }
                guard let parentName = qualifiedName(for: parentType),
                      let requirements = project.associatedTypeRequirements(named: member, of: parentName, visibleFrom: parentType.sourceFileURL ?? parent.fileURL) else { continue }
                for requirement in requirements {
                    guard let concrete = project.propertySymbol(owner: name, member: requirement.declaration.name,
                                                                isStatic: requirement.declaration.isStatic,
                                                                visibleFrom: owner.sourceFileURL ?? fileURL, accessedFrom: fileURL),
                        !project.isProtocolDeclaration(named: concrete.declaration.declaringType, visibleFrom: concrete.fileURL),
                        let witness = memberType(owner: owner, name: requirement.declaration.name, depth: depth + 1),
                        result == nil || sameType(result!, as: witness) else { return nil }
                    result = witness
                }
            }
        }
        guard let result else { return nil }
        let remaining = reference.name.split(separator: ".").dropFirst().joined(separator: ".")
        return remaining.isEmpty ? result : dependentMemberType(remaining, of: result, depth: depth + 1)
    }

    func memberType(owner: ResolvedType, name: String, accessingType: String? = nil, depth: Int = 0) -> ResolvedType? {
        guard depth < 16 else { return nil }
        if owner.collectionKind != nil, !owner.isMetatype, unwrapped(owner) == nil {
            return collectionMember(owner: owner, name: name)
        }
        if let elements = owner.tupleElements, !owner.isMetatype, unwrapped(owner) == nil {
            if let position = Int(name), elements.indices.contains(position) {
                return elements[position].type
            }
            return elements.first(where: { $0.label == name })?.type
        }
        guard let ownerName = qualifiedName(for: owner),
              let member = project.propertySymbol(owner: ownerName, member: name, isStatic: owner.isMetatype, visibleFrom: owner.sourceFileURL ?? fileURL, accessedFrom: fileURL, accessedFromType: accessingType),
              let declaringOwner = projectedType(owner, to: member.declaration.declaringType, source: member.fileURL, depth: depth + 1),
              var substitutions = nominalSubstitutions(for: declaringOwner) else { return nil }
        substitutions["Self"] = owner
        if let annotation = member.declaration.type {
            return type(named: annotation, namespace: member.declaration.declaringType, sourceFileURL: member.fileURL, substitutions: substitutions, depth: depth + 1)
        }
        guard let initializer = member.declaration.initializer else { return nil }
        return explicitInitializerType(initializer, namespace: member.declaration.declaringType, source: member.fileURL, substitutions: substitutions, depth: depth + 1)
    }

    /// An explicit constructor or payloadless enum case determines a stored value's type without
    /// evaluating its body. Keep the initializer's lexical scope and generic arguments intact.
    func explicitInitializerType(_ expression: String, namespace: String?, source: URL, substitutions: [String: ResolvedType], depth: Int = 0) -> ResolvedType? {
        guard depth < 16 else { return nil }
        let expression = Formatter(tokenize(expression), options: formatter.options)
        guard let first = expression.index(of: .nonSpaceOrCommentOrLinebreak, after: -1),
              let last = expression.index(of: .nonSpaceOrCommentOrLinebreak, before: expression.tokens.count) else { return nil }
        if let namespace, expression.tokens[first] != .startOfScope("["),
           project.isDynamicMemberLookupType(named: namespace, visibleFrom: source)
        {
            return nil
        }
        if let annotation = expression.parseType(at: first),
           let open = expression.index(of: .nonSpaceOrCommentOrLinebreak, after: annotation.range.upperBound),
           expression.tokens[open] == .startOfScope("("), expression.endOfScope(at: open) == last,
           var result = type(named: annotation.string, namespace: namespace, sourceFileURL: source, substitutions: substitutions, requiresGenericArguments: true, depth: depth + 1)
        {
            if let kind = result.collectionKind {
                guard expression.tokens[first] == .startOfScope("[") || initializerRootIsUnshadowed(annotation.string),
                      !project.hasCollectionMember(named: "init", kind: kind.rawValue, visibleFrom: source) else { return nil }
                return result
            }
            guard initializerRootIsUnshadowed(annotation.string), let name = qualifiedName(for: result),
                  let initializer = project.functionSymbol(named: "init", receiver: .type(name),
                                                           arguments: expression.parseFunctionCallArguments(startOfScope: open).map(\.label),
                                                           visibleFrom: result.sourceFileURL ?? source, accessedFrom: source, accessedFromType: namespace, kind: .initializer) else { return nil }
            if initializer.declaration.isFailable {
                result.name += "?"
            }
            return result
        }
        guard let dot = expression.index(of: .operator(".", .infix), before: last),
              expression.index(of: .nonSpaceOrCommentOrLinebreak, after: dot) == last,
              expression.tokens[last].isIdentifier else { return nil }
        let root = expression.tokens[first ..< dot].string
        guard initializerRootIsUnshadowed(root),
              let result = type(named: root, namespace: namespace, sourceFileURL: source, substitutions: substitutions, requiresGenericArguments: true, depth: depth + 1),
              unwrapped(result) == nil, let name = qualifiedName(for: result),
              let declaration = project.typeDeclaration(named: name, visibleFrom: result.sourceFileURL ?? source),
              declaration.enumCasePayloads?[expression.tokens[last].string] == [],
              !project.hasProperty(owner: name, member: expression.tokens[last].string, visibleFrom: result.sourceFileURL ?? source, accessedFrom: source) else { return nil }
        return result
    }

    /// A value or function along the qualified path can shadow a nominal initializer.
    func initializerRootIsUnshadowed(_ spelling: String) -> Bool {
        guard let reference = ProjectTypeReference(spelling) else { return false }
        return reference.name.split(separator: ".").allSatisfy {
            project.declarationCountsAreUnambiguous(for: String($0), includingAliases: true)
        }
    }

    /// Structural collection information is independent of the declaration context of each argument.
    func collectionType(_ kind: CollectionKind, arguments: [ResolvedType]) -> ResolvedType {
        let argumentsName = "<" + arguments.map(\.name).joined(separator: ",") + ">"
        let name: String
        if kind == .dictionaryKeys || kind == .dictionaryValues {
            name = "Swift.Dictionary" + argumentsName + (kind == .dictionaryKeys ? ".Keys" : ".Values")
        } else {
            name = "Swift.\(kind.rawValue)" + argumentsName
        }
        return ResolvedType(name: name, genericArguments: arguments, collectionKind: kind)
    }

    func collectionElement(of owner: ResolvedType) -> ResolvedType? {
        guard !owner.isMetatype, unwrapped(owner) == nil, let kind = owner.collectionKind,
              let arguments = owner.genericArguments else { return nil }
        if [.reversedCollection, .slice].contains(kind), arguments.count == 1 {
            return collectionElement(of: arguments[0])
        }
        if kind == .enumeratedSequence, arguments.count == 1, let element = collectionElement(of: arguments[0]) {
            return ResolvedType(name: "(offset: Swift.Int, element: \(element.name))",
                                tupleElements: [TupleElement(label: "offset", type: ResolvedType(name: "Swift.Int")),
                                                TupleElement(label: "element", type: element)])
        }
        if arguments.count == 2 {
            if kind == .dictionaryKeys {
                return arguments[0]
            }
            if kind == .dictionaryValues {
                return arguments[1]
            }
        }
        if kind == .dictionary, arguments.count == 2 {
            return ResolvedType(name: "(key: \(arguments[0].name), value: \(arguments[1].name))",
                                tupleElements: [TupleElement(label: "key", type: arguments[0]), TupleElement(label: "value", type: arguments[1])])
        }
        return arguments.count == 1 ? arguments.first : nil
    }

    func optionalType(_ type: ResolvedType) -> ResolvedType {
        var result = type
        result.name += "?"
        return result
    }

    func standardScalarName(_ value: ResolvedType) -> String? {
        guard !value.isMetatype, unwrapped(value) == nil, let name = qualifiedName(for: value) else { return nil }
        let shortName = name.hasPrefix("Swift.") ? String(name.dropFirst(6)) : name
        guard ["Int", "Int8", "Int16", "Int32", "Int64", "UInt", "UInt8", "UInt16", "UInt32", "UInt64",
               "String", "Character", "Bool", "Double", "Float"].contains(shortName),
            project.isStandardLibraryTypeName(name, visibleFrom: value.sourceFileURL ?? fileURL) else { return nil }
        return shortName
    }

    func collectionMember(owner: ResolvedType, name: String) -> ResolvedType? {
        guard let kind = owner.collectionKind, let element = collectionElement(of: owner),
              !project.hasCollectionMember(named: name, kind: kind.rawValue, visibleFrom: fileURL) else { return nil }
        if name == "first" || name == "last" && [.array, .arraySlice, .contiguousArray, .reversedCollection, .slice].contains(kind) {
            return optionalType(element)
        }
        if ["startIndex", "endIndex"].contains(name), [.array, .arraySlice, .contiguousArray].contains(kind) {
            return ResolvedType(name: "Swift.Int")
        }
        if kind == .dictionary, let arguments = owner.genericArguments, arguments.count == 2 {
            if name == "keys" {
                return collectionType(.dictionaryKeys, arguments: arguments)
            }
            if name == "values" {
                return collectionType(.dictionaryValues, arguments: arguments)
            }
        }
        return nil
    }

    func collectionSubscript(owner: ResolvedType, arguments: [Formatter.FunctionCallArgument], depth: Int) -> ResolvedType? {
        guard let kind = owner.collectionKind, let element = collectionElement(of: owner),
              !project.hasCollectionMember(named: "subscript", kind: kind.rawValue, visibleFrom: fileURL),
              let index = arguments.first, index.label == nil else { return nil }
        if kind == .dictionary, let types = owner.genericArguments, types.count == 2 {
            if arguments.count == 2, arguments[1].label == "default" {
                return types[1]
            }
            guard arguments.count == 1, let key = expressionType(in: index.valueRange, depth: depth + 1),
                  sameType(key, as: types[0]) else { return nil }
            return optionalType(types[1])
        }
        guard [.array, .arraySlice, .contiguousArray].contains(kind), arguments.count == 1 else { return nil }
        let meaningful = formatter.tokens[index.valueRange].filter { !$0.isSpaceOrCommentOrLinebreak }
        if meaningful.count == 1, case .number(_, .integer) = meaningful[0] {
            return element
        }
        guard let value = expressionType(in: index.valueRange, depth: depth + 1), standardScalarName(value) == "Int" else { return nil }
        return element
    }

    func collectionClosureParameter(owner: ResolvedType, name: String, arguments: [Formatter.FunctionCallArgument],
                                    closureArgument: Int, binding: ClosureBinding, trailing: Int?) -> ResolvedType?
    {
        guard arguments.count == 1, closureArgument == 0,
              arguments[0].label == nil || trailing == 0 || arguments[0].label == "where",
              ["forEach", "map", "compactMap", "flatMap", "filter", "first", "last", "contains", "allSatisfy", "prefix", "drop"].contains(name),
              let kind = owner.collectionKind,
              !project.hasCollectionMember(named: name, kind: kind.rawValue, visibleFrom: fileURL),
              let element = collectionElement(of: owner) else { return nil }
        let location = binding.location.range.lowerBound
        let arity = formatter.parseClosureArguments(at: location)?.argumentIndices.count ?? 1
        if arity == 1 {
            return binding.parameterIndex == 0 ? element : nil
        }
        // Swift permits a single tuple argument to be destructured into closure parameters.
        guard let elements = element.tupleElements, elements.count == arity, elements.indices.contains(binding.parameterIndex) else { return nil }
        return elements[binding.parameterIndex].type
    }

    /// Resolves a key path against an independently known root, retaining each member's
    /// declaring module. This is shared by standard collection transforms and other consumers.
    func keyPathValueType(in range: ClosedRange<Int>, root: ResolvedType) -> ResolvedType? {
        guard let slash = formatter.index(of: .nonSpaceOrCommentOrLinebreak, in: Range(range)),
              formatter.tokens[slash] == .operator("\\", .prefix),
              let first = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: slash), first <= range.upperBound else { return nil }
        var dot = first
        if !formatter.tokens[first].isOperator(".") {
            var cursor = first
            var rootEnd: Int?
            while let candidate = formatter.index(after: cursor, where: { $0.isOperator(".") }), candidate <= range.upperBound {
                let namespace = formatter.parseEnclosingType(containing: slash, declarations: declarations)?.fullyQualifiedName
                if let explicit = type(named: formatter.tokens[first ..< candidate].string, namespace: namespace, at: first, requiresGenericArguments: true),
                   sameType(explicit, as: root)
                {
                    rootEnd = candidate
                    break
                }
                cursor = candidate
            }
            guard let rootEnd else { return nil }
            dot = rootEnd
        }
        var value = root
        var optionalChain = false
        while dot <= range.upperBound {
            guard formatter.tokens[dot].isOperator("."),
                  let member = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: dot), member <= range.upperBound else { return nil }
            let name = formatter.tokens[member].string
            if name != "self" {
                let namespace = formatter.parseEnclosingType(containing: slash, declarations: declarations)?.fullyQualifiedName
                guard let result = memberType(owner: value, name: name, accessingType: namespace) else { return nil }
                value = result
            }
            guard let next = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: member), next <= range.upperBound else {
                return optionalChain && unwrapped(value) == nil ? optionalType(value) : value
            }
            if formatter.tokens[next].isUnwrapOperator {
                guard let wrapped = unwrapped(value),
                      let nextDot = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: next), nextDot <= range.upperBound else { return nil }
                optionalChain = optionalChain || formatter.tokens[next].isOperator("?")
                value = wrapped
                dot = nextDot
            } else {
                dot = next
            }
        }
        return nil
    }

    /// The result of a transform closure is resolved only from an explicit annotation or one
    /// expression. Multiple return paths require control-flow and common-supertype inference.
    func closureResultType(in range: ClosedRange<Int>, depth: Int) -> ResolvedType? {
        guard depth < 16, formatter.tokens[range.lowerBound] == .startOfScope("{"),
              formatter.endOfScope(at: range.lowerBound) == range.upperBound else { return nil }
        let arguments = formatter.parseClosureArguments(at: range.lowerBound)
        let signatureEnd = arguments?.inKeywordIndex ?? range.lowerBound
        if let arguments,
           let arrow = formatter.index(of: .operator("->", .infix), in: range.lowerBound + 1 ..< arguments.inKeywordIndex),
           let start = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: arrow),
           let annotation = formatter.parseType(at: start), annotation.range.upperBound < arguments.inKeywordIndex
        {
            let namespace = formatter.parseEnclosingType(containing: range.lowerBound, declarations: declarations)?.fullyQualifiedName
            return type(named: annotation.string, namespace: namespace, at: start, requiresGenericArguments: true)
        }
        guard var start = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: signatureEnd), start < range.upperBound else { return nil }
        if formatter.tokens[start] == .keyword("return") {
            guard let expression = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: start) else { return nil }
            start = expression
        }
        guard let expression = formatter.parseExpressionRange(startingAt: start),
              formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: expression.upperBound) == range.upperBound else { return nil }
        return expressionType(in: expression, depth: depth + 1)
    }

    /// EnumeratedSequence's conditional bidirectional conformance depends on deployment
    /// availability as well as the compiler. The index does not establish that availability.
    func collectionIsBidirectional(_ value: ResolvedType) -> Bool? {
        guard let kind = value.collectionKind else { return nil }
        switch kind {
        case .array, .arraySlice, .contiguousArray, .reversedCollection:
            return true
        case .slice:
            return value.genericArguments?.first.flatMap(collectionIsBidirectional)
        case .enumeratedSequence:
            guard let base = value.genericArguments?.first, let bidirectional = collectionIsBidirectional(base) else { return nil }
            if !bidirectional {
                return false
            }
            return nil
        case .dictionary, .dictionaryKeys, .dictionaryValues, .set:
            return false
        }
    }

    func collectionCall(owner: ResolvedType, name: String, arguments: [Formatter.FunctionCallArgument], depth: Int) -> ResolvedType? {
        guard let kind = owner.collectionKind, let element = collectionElement(of: owner),
              !project.hasCollectionMember(named: name, kind: kind.rawValue, visibleFrom: fileURL) else { return nil }
        if name == "filter", arguments.count == 1, arguments[0].label == nil {
            return kind == .dictionary || kind == .set ? owner : collectionType(.array, arguments: [element])
        }
        if ["first", "last"].contains(name), arguments.count == 1, arguments[0].label == "where" {
            return optionalType(element)
        }
        if name == "randomElement", arguments.isEmpty {
            return optionalType(element)
        }
        if name == "enumerated", arguments.isEmpty {
            return collectionType(.enumeratedSequence, arguments: [owner])
        }
        if name == "reversed", arguments.isEmpty {
            if kind == .reversedCollection {
                return owner.genericArguments?.first
            }
            guard let bidirectional = collectionIsBidirectional(owner) else { return nil }
            return bidirectional ? collectionType(.reversedCollection, arguments: [owner]) : collectionType(.array, arguments: [element])
        }
        if name == "sorted", arguments.isEmpty || arguments.count == 1 && arguments[0].label == "by" {
            return collectionType(.array, arguments: [element])
        }
        if ["prefix", "suffix", "dropFirst", "dropLast"].contains(name),
           [.array, .arraySlice, .contiguousArray].contains(kind),
           arguments.isEmpty && ["dropFirst", "dropLast"].contains(name) || arguments.count == 1 && arguments[0].label == nil
        {
            return collectionType(.arraySlice, arguments: [element])
        }
        if ["map", "compactMap", "flatMap"].contains(name), arguments.count == 1, arguments[0].label == nil,
           let result = closureResultType(in: arguments[0].valueRange, depth: depth + 1) ?? keyPathValueType(in: arguments[0].valueRange, root: element)
        {
            if name == "compactMap" {
                return collectionType(.array, arguments: [unwrapped(result) ?? result])
            }
            if name == "flatMap" {
                return collectionElement(of: result).map { collectionType(.array, arguments: [$0]) }
            }
            return collectionType(.array, arguments: [result])
        }
        return nil
    }

    /// The standard Result preserves each generic argument's original declaration context.
    func standardResultArguments(_ owner: ResolvedType) -> [ResolvedType]? {
        guard !owner.isMetatype, unwrapped(owner) == nil,
              let name = qualifiedName(for: owner), ["Result", "Swift.Result"].contains(name),
              project.isStandardLibraryTypeName(name, visibleFrom: owner.sourceFileURL ?? fileURL),
              let arguments = owner.genericArguments, arguments.count == 2 else { return nil }
        return arguments
    }

    func standardResultCall(owner: ResolvedType, name: String, arguments: [Formatter.FunctionCallArgument]) -> ResolvedType? {
        guard name == "get", arguments.isEmpty, let types = standardResultArguments(owner),
              !project.hasStandardLibraryMember(named: name, types: ["Result"], visibleFrom: fileURL) else { return nil }
        return types[0]
    }

    func enumPayloadType(owner: ResolvedType, caseName: String, at position: Int) -> ResolvedType? {
        if caseName == "some", position == 0, let wrapped = unwrapped(owner) {
            return wrapped
        }
        if let arguments = standardResultArguments(owner) {
            guard position == 0 else { return nil }
            switch caseName {
            case "success": return arguments[0]
            case "failure": return arguments[1]
            default: return nil
            }
        }
        guard let ownerName = qualifiedName(for: owner),
              let nominal = ProjectTypeReference(owner.name),
              let declaration = project.typeDeclaration(named: ownerName, visibleFrom: owner.sourceFileURL ?? fileURL),
              let payloads = declaration.enumCasePayloads?[caseName], payloads.indices.contains(position),
              let source = project.typeSourceFile(named: ownerName, visibleFrom: owner.sourceFileURL ?? fileURL) else { return nil }
        let arguments = owner.genericArguments ?? nominal.arguments.compactMap {
            type(named: $0, namespace: owner.namespace, sourceFileURL: owner.sourceFileURL)
        }
        guard arguments.count == declaration.genericParameters.count else { return nil }
        return type(named: payloads[position], namespace: declaration.name, sourceFileURL: source,
                    substitutions: Dictionary(uniqueKeysWithValues: zip(declaration.genericParameters, arguments)))
    }

    func applyGenericBounds(of symbol: ProjectIndex.FunctionSymbol, to substitutions: inout [String: ResolvedType]) -> Bool {
        for (name, constraints) in symbol.declaration.genericConstraints ?? [:] {
            guard var value = substitutions[name] else { continue }
            let bounds = constraints.compactMap {
                type(named: $0, namespace: symbol.declaration.declaringType, sourceFileURL: symbol.fileURL, requiresGenericArguments: true)
            }
            guard bounds.count == constraints.count else { return false }
            value.genericBounds = bounds
            substitutions[name] = value
        }
        return true
    }

    /// Propagate same-type requirements in both directions until no new substitution is known.
    /// Terms with unbound generic roots never become unrelated nominal declarations.
    func solveRequirements(of symbol: ProjectIndex.FunctionSymbol, substitutions: inout [String: ResolvedType], requiringProof: Bool = false, rejectingOnlyProvenMismatch: Bool = false) -> Bool {
        let requirements = (symbol.declaration.genericRequirements ?? []).filter(\.isSameType)
        let ownerParameters = symbol.declaration.declaringType.flatMap { project.typeDeclaration(named: $0, visibleFrom: symbol.fileURL)?.genericParameters } ?? []
        let names = Set(symbol.declaration.genericParameters + ownerParameters + ["Self"])
        func resolve(_ raw: String) -> ResolvedType? {
            guard !tokenize(raw).contains(where: { names.contains($0.string) && substitutions[$0.string] == nil && substitutions[raw] == nil }) else { return nil }
            return type(named: raw, namespace: symbol.declaration.declaringType, sourceFileURL: symbol.fileURL,
                        substitutions: substitutions, requiresGenericArguments: true)
        }
        func isVariable(_ raw: String) -> Bool {
            guard let reference = ProjectTypeReference(raw), reference.arguments.isEmpty,
                  let root = reference.name.split(separator: ".").first else { return false }
            return names.contains(String(root))
        }
        for _ in 0 ... requirements.count {
            var changed = false
            for requirement in requirements {
                let lhs = resolve(requirement.subject)
                let rhs = resolve(requirement.target)
                if let lhs, let rhs {
                    if !sameType(lhs, as: rhs), !rejectingOnlyProvenMismatch || argumentIsIncompatible(lhs, with: rhs) {
                        return false
                    }
                } else if let lhs, isVariable(requirement.target), substitutions[requirement.target] == nil {
                    substitutions[requirement.target] = lhs
                    changed = true
                } else if let rhs, isVariable(requirement.subject), substitutions[requirement.subject] == nil {
                    substitutions[requirement.subject] = rhs
                    changed = true
                }
            }
            if !changed {
                break
            }
        }
        if requiringProof {
            return (symbol.declaration.genericRequirements ?? []).allSatisfy { requirement in
                guard let subject = resolve(requirement.subject), let target = resolve(requirement.target) else { return false }
                return requirement.isSameType ? sameType(subject, as: target) : conformanceOwner(subject, to: target, depth: 0) != nil
            }
        }
        return true
    }

    func requirementsSatisfied(_ symbol: ProjectIndex.FunctionSymbol, owner: ResolvedType?) -> Bool {
        guard let owner, let name = symbol.declaration.declaringType,
              let projected = projectedType(owner, to: name, source: symbol.fileURL),
              var substitutions = nominalSubstitutions(for: projected) else { return false }
        substitutions["Self"] = owner
        return solveRequirements(of: symbol, substitutions: &substitutions, requiringProof: true)
    }

    /// Prove incompatibility only for known nominal values. Unknown types, existential conversion,
    /// class upcasts, and context-dependent literals must retain the competing overload.
    func argumentIsIncompatible(_ value: ResolvedType, with parameter: ResolvedType) -> Bool {
        if sameType(value, as: parameter) {
            return false
        }
        if let actual = standardScalarName(value), let formal = standardScalarName(parameter) {
            return actual != formal
        }
        if let wrapped = unwrapped(parameter) {
            return argumentIsIncompatible(unwrapped(value) ?? value, with: wrapped)
        }
        guard unwrapped(value) == nil, !value.isMetatype, !parameter.isMetatype,
              value.functionType == nil, parameter.functionType == nil,
              value.tupleElements == nil, parameter.tupleElements == nil,
              let actualName = qualifiedName(for: value), let formalName = qualifiedName(for: parameter),
              let actual = project.typeDeclaration(named: actualName, visibleFrom: value.sourceFileURL ?? fileURL),
              let formal = project.typeDeclaration(named: formalName, visibleFrom: parameter.sourceFileURL ?? fileURL),
              let actualKind = actual.kind, let formalKind = formal.kind,
              ["struct", "enum", "class", "actor"].contains(actualKind),
              ["struct", "enum", "class", "actor"].contains(formalKind),
              let actualIdentity = project.typeIdentity(named: actualName, visibleFrom: value.sourceFileURL ?? fileURL),
              let formalIdentity = project.typeIdentity(named: formalName, visibleFrom: parameter.sourceFileURL ?? fileURL)
        else { return false }
        if actualIdentity == formalIdentity {
            // Project nominal types are invariant. Standard collections retain their conversions.
            guard value.collectionKind == nil, parameter.collectionKind == nil,
                  project.typeSourceFile(named: actualName, visibleFrom: value.sourceFileURL ?? fileURL)?.pathExtension == "swift",
                  let actualArguments = value.genericArguments, let formalArguments = parameter.genericArguments,
                  actualArguments.count == formalArguments.count else { return false }
            return zip(actualArguments, formalArguments).contains { argumentIsIncompatible($0, with: $1) }
        }
        if actualKind == "class", formalKind == "class" {
            return false
        }
        return true
    }

    func viableOverload(_ symbol: ProjectIndex.FunctionSymbol, owner: ResolvedType?, arguments: [Formatter.FunctionCallArgument],
                        knownTypes: [Int: ResolvedType], ignoringLabelAt ignoredLabel: Int? = nil) -> Bool
    {
        guard let parameters = symbol.declaration.symbolArgumentTypes,
              let indices = symbol.declaration.parameterIndices(matching: arguments.map(\.label), ignoringLabelAt: ignoredLabel) else { return true }
        var substitutions = owner.flatMap { owner in
            symbol.declaration.declaringType.flatMap { projectedType(owner, to: $0, source: symbol.fileURL) }.flatMap(nominalSubstitutions)
        } ?? [:]
        for generic in symbol.declaration.genericParameters {
            substitutions.removeValue(forKey: generic)
        }
        let unknown = Set(symbol.declaration.genericParameters).subtracting(substitutions.keys)
        for (position, value) in knownTypes {
            guard indices.indices.contains(position), parameters.indices.contains(indices[position]) else { continue }
            let raw = parameters[indices[position]]
            // A bare generic parameter is fixed by the argument, and can feed equality requirements.
            if unknown.contains(raw) {
                if substitutions[raw] == nil {
                    substitutions[raw] = value
                }
                continue
            }
            guard !tokenize(raw).contains(where: { unknown.contains($0.string) }),
                  let formal = type(named: raw, namespace: symbol.declaration.declaringType, sourceFileURL: symbol.fileURL,
                                    substitutions: substitutions, requiresGenericArguments: true) else { continue }
            if argumentIsIncompatible(value, with: formal) {
                return false
            }
        }
        guard applyGenericBounds(of: symbol, to: &substitutions) else { return true }
        return solveRequirements(of: symbol, substitutions: &substitutions, rejectingOnlyProvenMismatch: true)
    }

    /// Most calls are eliminated by labels or visibility before argument inference is needed.
    func argumentTypeProvider(_ arguments: [Formatter.FunctionCallArgument], depth: Int) -> () -> [Int: ResolvedType] {
        var cached: [Int: ResolvedType]?
        return {
            if let cached {
                return cached
            }
            let result = self.knownArgumentTypes(arguments, depth: depth)
            cached = result
            return result
        }
    }

    func knownArgumentTypes(_ arguments: [Formatter.FunctionCallArgument], depth: Int) -> [Int: ResolvedType] {
        guard depth < 32 else { return [:] }
        var result = [Int: ResolvedType]()
        for (position, argument) in arguments.enumerated() {
            let token = formatter.tokens[argument.valueRange.lowerBound]
            // These expressions borrow parameter context; using it to select that parameter cycles.
            guard token.isIdentifier || token == .keyword("self") || token == .keyword("Self") else { continue }
            result[position] = expressionType(in: argument.valueRange, depth: depth + 1)
        }
        return result
    }

    /// Bind a declaration's generic parameters from a known receiver and the call's arguments.
    func substitutions(for symbol: ProjectIndex.FunctionSymbol, owner: ResolvedType?,
                       arguments: [Formatter.FunctionCallArgument], depth: Int, ignoringLabelAt ignoredLabel: Int? = nil, contextualClosureArgumentAt contextualArgument: Int? = nil) -> [String: ResolvedType]?
    {
        var substitutions = [String: ResolvedType]()
        if let name = symbol.declaration.declaringType, let owner {
            guard let declaringOwner = projectedType(owner, to: name, source: symbol.fileURL),
                  let values = nominalSubstitutions(for: declaringOwner) else { return nil }
            substitutions = values
            substitutions["Self"] = owner
        } else if let name = symbol.declaration.declaringType,
                  project.typeDeclaration(named: name, visibleFrom: symbol.fileURL)?.genericParameters.isEmpty == false
        {
            return nil
        }
        for name in symbol.declaration.genericParameters {
            substitutions.removeValue(forKey: name)
        }
        guard solveRequirements(of: symbol, substitutions: &substitutions) else { return nil }
        let genericNames = Set(symbol.declaration.genericParameters)
        var fixedGenericNames = Set(substitutions.keys)
        var contextualGenericNames = Set<String>()
        // Resolve the pattern with opaque placeholders so aliases, tuple labels and collection
        // sugar use the same parser and declaration provenance as all other type lookup.
        let placeholders = substitutions.merging(Dictionary(uniqueKeysWithValues: genericNames.map { ($0, ResolvedType(name: "$generic:" + $0)) })) { _, generic in generic }
        func match(_ pattern: ResolvedType, to value: ResolvedType, nesting: Int = 0, invariant: Bool = false) -> Bool {
            guard nesting < 16 else { return false }
            if !pattern.isMetatype, pattern.name.hasPrefix("$generic:"), genericNames.contains(String(pattern.name.dropFirst("$generic:".count))) {
                let name = String(pattern.name.dropFirst("$generic:".count))
                if let previous = substitutions[name], !sameType(previous, as: value) {
                    return false
                }
                substitutions[name] = value
                if invariant {
                    fixedGenericNames.insert(name)
                }
                return true
            }
            if let wrapped = unwrapped(pattern) {
                guard let actual = unwrapped(value) else { return false }
                return match(wrapped, to: actual, nesting: nesting + 1, invariant: invariant)
            }
            guard unwrapped(value) == nil else { return false }
            if pattern.isMetatype {
                guard value.isMetatype else { return false }
                var instancePattern = pattern
                var instanceValue = value
                instancePattern.isMetatype = false
                instanceValue.isMetatype = false
                return match(instancePattern, to: instanceValue, nesting: nesting + 1, invariant: invariant)
            }
            guard !value.isMetatype else { return false }
            if let elements = pattern.tupleElements {
                guard let actual = value.tupleElements, elements.count == actual.count else { return false }
                return zip(elements, actual).allSatisfy {
                    $0.label == $1.label && match($0.type, to: $1.type, nesting: nesting + 1, invariant: invariant)
                }
            }
            if let kind = pattern.collectionKind {
                guard kind == value.collectionKind, let formal = pattern.genericArguments, let actual = value.genericArguments,
                      formal.count == actual.count else { return false }
                // Standard collections can widen class/existential element types. Only an
                // enclosing invariant project wrapper makes these arguments fixed.
                return zip(formal, actual).allSatisfy { match($0, to: $1, nesting: nesting + 1, invariant: invariant) }
            }
            guard let formalName = qualifiedName(for: pattern), let actualName = qualifiedName(for: value),
                  let identity = project.typeIdentity(named: formalName, visibleFrom: pattern.sourceFileURL ?? symbol.fileURL),
                  identity == project.typeIdentity(named: actualName, visibleFrom: value.sourceFileURL ?? fileURL)
            else {
                return sameType(pattern, as: value)
            }
            let formal = pattern.genericArguments ?? []
            let actual = value.genericArguments ?? []
            guard formal.count == actual.count else { return false }
            let source = project.typeSourceFile(named: formalName, visibleFrom: pattern.sourceFileURL ?? symbol.fileURL)
            let fixed = invariant || source?.pathExtension == "swift"
            return zip(formal, actual).allSatisfy { match($0, to: $1, nesting: nesting + 1, invariant: fixed) }
        }
        func infer(_ pattern: String, from value: ResolvedType) -> Bool {
            guard let formal = type(named: pattern, namespace: symbol.declaration.declaringType, sourceFileURL: symbol.fileURL,
                                    substitutions: placeholders, requiresGenericArguments: true) else { return false }
            return match(formal, to: value)
        }
        if let parameters = symbol.declaration.symbolArgumentTypes,
           let indices = symbol.declaration.parameterIndices(matching: arguments.map(\.label), ignoringLabelAt: ignoredLabel)
        {
            for (position, entry) in zip(arguments, indices).enumerated() {
                let (argument, parameter) = entry
                var pattern = parameters[parameter]
                guard tokenize(pattern).contains(where: { genericNames.contains($0.string) }) else { continue }
                if position == contextualArgument {
                    // Infer from invariant value arguments, never from the callback body. This
                    // also supports aliased and nested callback parameters once their generics are fixed.
                    contextualGenericNames.formUnion(tokenize(pattern).map(\.string).filter { genericNames.contains($0) })
                    continue
                }
                if symbol.declaration.autoclosureArgumentIndices.contains(parameter) {
                    let signature = Formatter(tokenize(pattern))
                    guard let arrow = signature.index(of: .operator("->", .infix), after: -1) else { return nil }
                    pattern = signature.tokens[arrow + 1 ..< signature.tokens.count].string
                }
                guard let value = expressionType(in: argument.valueRange, depth: depth + 1),
                      infer(pattern, from: value) else { return nil }
            }
        }
        guard applyGenericBounds(of: symbol, to: &substitutions),
              solveRequirements(of: symbol, substitutions: &substitutions) else { return nil }
        // Equality with a fixed term also fixes callback generics. A dependent witness is fixed
        // by its protocol conformance; a bare covariant value argument can still widen.
        func isFixed(_ raw: String) -> Bool {
            let tokens = tokenize(raw).filter { !$0.isSpaceOrCommentOrLinebreak }
            return tokens.indices.filter { genericNames.contains(tokens[$0].string) }.allSatisfy { index in
                let name = tokens[index].string
                if fixedGenericNames.contains(name) {
                    return true
                }
                guard tokens.indices.contains(index + 2), tokens[index + 1].isOperator("."),
                      let value = substitutions[name], value.genericBounds != nil else { return false }
                return dependentMemberType(tokens[index + 2].string, of: value, depth: depth + 1) != nil
            }
        }
        let equalities = (symbol.declaration.genericRequirements ?? []).filter(\.isSameType)
        for _ in equalities {
            for equality in equalities {
                for (variable, term) in [(equality.subject, equality.target), (equality.target, equality.subject)] {
                    if genericNames.contains(variable), substitutions[variable] != nil, isFixed(term) {
                        fixedGenericNames.insert(variable)
                    }
                }
            }
        }
        // A contextual closure body may widen a type inferred from a covariant value argument.
        // Associated types remain fixed by the selected conformance, even through a superclass.
        let dependentNames: Set<String>
        if let contextualArgument, arguments.indices.contains(contextualArgument),
           let indices = symbol.declaration.parameterIndices(matching: arguments.map(\.label), ignoringLabelAt: ignoredLabel),
           let parameters = symbol.declaration.symbolArgumentTypes
        {
            let tokens = tokenize(parameters[indices[contextualArgument]]).filter { !$0.isSpaceOrCommentOrLinebreak }
            dependentNames = Set(contextualGenericNames.filter { name in
                let occurrences = tokens.indices.filter { tokens[$0].string == name }
                return !occurrences.isEmpty && occurrences.allSatisfy { index in
                    guard tokens.indices.contains(index + 2), tokens[index + 1].isOperator("."),
                          let value = substitutions[name], value.genericBounds != nil else { return false }
                    return dependentMemberType(tokens[index + 2].string, of: value, depth: depth + 1) != nil
                }
            })
        } else {
            dependentNames = []
        }
        guard contextualGenericNames.isSubset(of: fixedGenericNames.union(dependentNames)) else { return nil }
        return substitutions
    }

    func signatureType(_ raw: String, symbol: ProjectIndex.FunctionSymbol, substitutions: [String: ResolvedType]) -> ResolvedType? {
        let unknown = Set(symbol.declaration.genericParameters).subtracting(substitutions.keys)
        guard !tokenize(raw).contains(where: { $0.isIdentifier && unknown.contains($0.string) }) else { return nil }
        return type(named: raw, namespace: symbol.declaration.declaringType, sourceFileURL: symbol.fileURL, substitutions: substitutions, requiresGenericArguments: true)
    }

    struct ResolvedCall {
        var symbol: ProjectIndex.FunctionSymbol
        var owner: ResolvedType?
        var arguments: [Formatter.FunctionCallArgument]
        var trailingArgument: Int?
    }

    /// Resolves callable declarations once for both callback parameters and argument context.
    func resolvedCall(identifier: Int, scope: Int, depth: Int) -> ResolvedCall? {
        guard depth < 32 else { return nil }
        let name = formatter.tokens[identifier].string
        let arguments = formatter.parseFunctionCallArguments(startOfScope: scope)
        let knownTypes = argumentTypeProvider(arguments, depth: depth + 1)
        let closureArguments = Set(arguments.indices.filter {
            formatter.tokens[arguments[$0].valueRange.lowerBound] == .startOfScope("{")
        })
        let scopeEnd = formatter.endOfScope(at: scope) ?? scope
        let trailing = arguments.firstIndex { formatter.tokens[scope] == .startOfScope("{") || $0.valueRange.lowerBound > scopeEnd }
        let namespace = formatter.parseEnclosingType(containing: identifier, declarations: declarations)?.fullyQualifiedName
        let dot = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: identifier)
            .flatMap { formatter.tokens[$0].isOperator(".") ? $0 : nil }
        let receiverStart = dot.flatMap { dot in
            formatter.startOfMemberCallReceiver(endingAt: dot).flatMap { $0 < dot ? $0 : nil }
        }
        let start = receiverStart ?? identifier
        // A local callable value or factory can shadow an otherwise visible constructor/function.
        if dot == nil || receiverStart != nil {
            let root = formatter.tokens[start].string
            guard !unindexedFunctions.contains(root),
                  bindings[root]?.contains(where: { $0.isVisible(at: identifier) }) != true || dot != nil else { return nil }
        }
        var owner: ResolvedType?
        var receiver: ProjectIndex.FunctionCallReceiver?
        if name == "init", let dot {
            if let receiverStart {
                let root = formatter.tokens[receiverStart].string
                if !["self", "Self"].contains(root), bindings[root]?.contains(where: { $0.isVisible(at: identifier) }) != true,
                   let namespace,
                   !project.constructorRootIsUnshadowed(root, in: namespace, visibleFrom: fileURL)
                {
                    return nil
                }
                if let annotation = formatter.parseType(at: receiverStart), annotation.range.upperBound < dot,
                   bindings[formatter.tokens[receiverStart].string]?.contains(where: { $0.isVisible(at: identifier) }) != true,
                   namespace.map({ project.constructorRootIsUnshadowed(formatter.tokens[receiverStart].string, in: $0, visibleFrom: fileURL) }) ?? true
                {
                    owner = type(named: annotation.string, namespace: namespace, at: identifier, requiresGenericArguments: true)
                }
                if owner == nil, let value = expressionType(in: receiverStart ... dot - 1, depth: depth + 1), value.isMetatype {
                    owner = value
                }
            } else {
                owner = contextualType(at: dot, depth: depth + 1).flatMap { unwrapped($0) ?? $0 }
            }
        } else if let annotation = formatter.parseType(at: start),
                  let end = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: scope), annotation.range.upperBound == end,
                  bindings[formatter.tokens[start].string]?.contains(where: { $0.isVisible(at: identifier) }) != true,
                  let reference = ProjectTypeReference(annotation.string),
                  project.declarationCountsAreUnambiguous(for: String(reference.name.split(separator: ".").last ?? ""), includingAliases: true)
        {
            owner = type(named: annotation.string, namespace: namespace, at: identifier, requiresGenericArguments: true)
            if owner != nil, let namespace,
               !project.constructorRootIsUnshadowed(formatter.tokens[start].string, in: namespace, visibleFrom: fileURL)
            {
                return nil
            }
        }
        if let owner, let nominal = qualifiedName(for: owner),
           let symbol = project.functionSymbol(named: "init", receiver: .type(nominal), arguments: arguments.map(\.label),
                                               visibleFrom: owner.sourceFileURL ?? fileURL, ignoringLabelAt: trailing,
                                               accessedFrom: fileURL, accessedFromType: namespace, kind: .initializer, closureArguments: closureArguments,
                                               isViable: { self.viableOverload($0, owner: owner, arguments: arguments, knownTypes: knownTypes(), ignoringLabelAt: trailing) },
                                               requirementsSatisfied: { self.requirementsSatisfied($0, owner: owner) })
        {
            return ResolvedCall(symbol: symbol, owner: owner, arguments: arguments, trailingArgument: trailing)
        }
        guard name != "init" else { return nil }
        owner = nil
        if let dot, let receiverStart, receiverStart < dot {
            owner = expressionType(in: receiverStart ... dot - 1, depth: depth + 1)
            receiver = owner.flatMap { value in qualifiedName(for: value).map { value.isMetatype ? .type($0) : .instance(type: $0) } }
        } else {
            receiver = project.functionCallReceiver(at: identifier, in: formatter, visibleFrom: fileURL, declarations: declarations)
        }
        if case let .unqualified(owner, _) = receiver,
           let possibleType = type(named: name, namespace: owner, at: identifier),
           let nominal = qualifiedName(for: possibleType),
           project.hasSymbolType(named: nominal, visibleFrom: possibleType.sourceFileURL ?? fileURL)
        {
            return nil
        }
        guard let receiver,
              let symbol = project.functionSymbol(named: name, receiver: receiver, arguments: arguments.map(\.label),
                                                  visibleFrom: owner?.sourceFileURL ?? fileURL, ignoringLabelAt: trailing,
                                                  accessedFrom: fileURL, accessedFromType: namespace, closureArguments: closureArguments,
                                                  isViable: { self.viableOverload($0, owner: owner, arguments: arguments, knownTypes: knownTypes(), ignoringLabelAt: trailing) },
                                                  requirementsSatisfied: { self.requirementsSatisfied($0, owner: owner) }) else { return nil }
        if case let .unqualified(owner?, _) = receiver, symbol.declaration.declaringType == nil {
            guard project.isTypeWithoutInheritance(named: owner, visibleFrom: fileURL),
                  !project.isDynamicMemberLookupType(named: owner, visibleFrom: fileURL),
                  !project.hasProperty(owner: owner, member: name, visibleFrom: fileURL) else { return nil }
        }
        return ResolvedCall(symbol: symbol, owner: owner, arguments: arguments, trailingArgument: trailing)
    }

    func parameterType(of call: ResolvedCall, argument: Int, depth: Int) -> ResolvedType? {
        guard call.arguments.indices.contains(argument),
              let indices = call.symbol.declaration.parameterIndices(matching: call.arguments.map(\.label), ignoringLabelAt: call.trailingArgument),
              let parameterTypes = call.symbol.declaration.symbolArgumentTypes ?? call.symbol.declaration.argumentTypes,
              parameterTypes.indices.contains(indices[argument]),
              let substitutions = substitutions(for: call.symbol, owner: call.owner, arguments: call.arguments, depth: depth + 1,
                                                ignoringLabelAt: call.trailingArgument, contextualClosureArgumentAt: argument) else { return nil }
        return signatureType(parameterTypes[indices[argument]], symbol: call.symbol, substitutions: substitutions)
    }

    /// Expected types retain the declaration context and generic substitutions of the enclosing call.
    func contextualType(at expression: Int, depth: Int) -> ResolvedType? {
        guard depth < 32, let previous = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: expression) else { return nil }
        let namespace = formatter.parseEnclosingType(containing: expression, declarations: declarations)?.fullyQualifiedName
        switch formatter.tokens[previous] {
        case .keyword("return"), .startOfScope("{"):
            let implicit = formatter.tokens[previous] == .startOfScope("{")
            return formatter.staticMemberReturnType(at: expression, implicit: implicit)
                .flatMap { type(named: $0, namespace: namespace, at: expression, requiresGenericArguments: true) }
        case .operator("=", .infix):
            if let keyword = formatter.indexOfLastSignificantKeyword(at: previous),
               ["let", "var"].contains(formatter.tokens[keyword].string),
               let property = formatter.parsePropertyDeclaration(atIntroducerIndex: keyword),
               property.value?.expressionRange.lowerBound == expression
            {
                guard !formatter.modifiersForDeclaration(at: keyword, contains: { _, modifier in modifier.hasPrefix("@") }) else { return nil }
                return property.type.flatMap { type(named: $0.string, namespace: namespace, at: expression, requiresGenericArguments: true) }
            }
            guard let last = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: previous), formatter.tokens[last].isIdentifier else { return nil }
            let dot = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: last)
            let start = dot.flatMap { formatter.tokens[$0].isOperator(".") ? formatter.startOfMemberCallReceiver(endingAt: $0) : nil } ?? last
            return expressionType(in: start ... last, depth: depth + 1)
        case .startOfScope("("), .delimiter(","), .delimiter(":"):
            guard let scope = formatter.startOfScope(at: expression), formatter.tokens[scope] == .startOfScope("("),
                  let identifier = formatter.parseFunctionIdentifier(beforeStartOfScope: scope),
                  let call = resolvedCall(identifier: identifier, scope: scope, depth: depth + 1),
                  let argument = call.arguments.firstIndex(where: { $0.valueRange.lowerBound == expression }) else { return nil }
            if let indices = call.symbol.declaration.parameterIndices(matching: call.arguments.map(\.label), ignoringLabelAt: call.trailingArgument),
               call.symbol.declaration.autoclosureArgumentIndices.contains(indices[argument]),
               let raw = call.symbol.declaration.symbolArgumentTypes?[indices[argument]],
               let substitutions = substitutions(for: call.symbol, owner: call.owner, arguments: call.arguments, depth: depth + 1,
                                                 ignoringLabelAt: call.trailingArgument, contextualClosureArgumentAt: argument)
            {
                let signature = Formatter(tokenize(raw))
                guard let arrow = signature.index(of: .operator("->", .infix), after: -1) else { return nil }
                return signatureType(signature.tokens[arrow + 1 ..< signature.tokens.count].string, symbol: call.symbol, substitutions: substitutions)
            }
            return parameterType(of: call, argument: argument, depth: depth + 1)
        default:
            return nil
        }
    }

    func closureInputType(_ parameters: [ResolvedType], binding: ClosureBinding) -> ResolvedType? {
        let arity = formatter.parseClosureArguments(at: binding.location.range.lowerBound)?.argumentIndices.count ?? parameters.count
        if arity == parameters.count {
            return parameters.indices.contains(binding.parameterIndex) ? parameters[binding.parameterIndex] : nil
        }
        guard parameters.count == 1, let elements = parameters[0].tupleElements,
              elements.count == arity, elements.indices.contains(binding.parameterIndex) else { return nil }
        return elements[binding.parameterIndex].type
    }

    func closureParameterType(_ binding: ClosureBinding, depth: Int) -> ResolvedType? {
        let location = binding.location.range.lowerBound
        guard depth < 32 else { return nil }
        if let expected = contextualType(at: location, depth: depth + 1),
           let parameters = expected.functionType?.parameters,
           let parameter = closureInputType(parameters, binding: binding)
        {
            return parameter
        }
        guard let call = formatter.callContainingClosure(at: location) else { return nil }
        let arguments = formatter.parseFunctionCallArguments(startOfScope: call.scope)
        guard let argument = arguments.firstIndex(where: { $0.valueRange.lowerBound == location }) else { return nil }
        let scopeEnd = formatter.endOfScope(at: call.scope) ?? call.scope
        let trailing = arguments.firstIndex { formatter.tokens[call.scope] == .startOfScope("{") || $0.valueRange.lowerBound > scopeEnd }
        if let dot = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: call.identifier), formatter.tokens[dot].isOperator("."),
           let start = formatter.startOfMemberCallReceiver(endingAt: dot), start < dot,
           let owner = expressionType(in: start ... dot - 1, depth: depth + 1), owner.collectionKind != nil
        {
            return collectionClosureParameter(owner: owner, name: formatter.tokens[call.identifier].string,
                                              arguments: arguments, closureArgument: argument, binding: binding, trailing: trailing)
        }
        guard let resolved = resolvedCall(identifier: call.identifier, scope: call.scope, depth: depth + 1),
              let signature = parameterType(of: resolved, argument: argument, depth: depth + 1),
              let parameters = signature.functionType?.parameters else { return nil }
        return closureInputType(parameters, binding: binding)
    }

    func callType(name: String, receiver: ProjectIndex.FunctionCallReceiver, arguments: [Formatter.FunctionCallArgument],
                  sourceFileURL: URL? = nil, owner: ResolvedType? = nil, accessingType: String? = nil, depth: Int) -> ResolvedType?
    {
        let source = sourceFileURL ?? fileURL
        // A type's constructors participate in unqualified call overload resolution too.
        if case let .unqualified(namespace, _) = receiver,
           let possibleType = type(named: name, namespace: namespace, sourceFileURL: source),
           let nominal = qualifiedName(for: possibleType),
           project.hasSymbolType(named: nominal, visibleFrom: possibleType.sourceFileURL ?? source)
        {
            return nil
        }
        let knownTypes = argumentTypeProvider(arguments, depth: depth + 1)
        guard !unindexedFunctions.contains(name),
              let function = project.functionSymbol(named: name, receiver: receiver, arguments: arguments.map(\.label), visibleFrom: source, accessedFrom: fileURL, accessedFromType: accessingType,
                                                    isViable: { self.viableOverload($0, owner: owner, arguments: arguments, knownTypes: knownTypes()) },
                                                    requirementsSatisfied: { self.requirementsSatisfied($0, owner: owner) }),
              let returnType = function.declaration.symbolReturnType ?? function.declaration.returnType,
              let substitutions = substitutions(for: function, owner: owner, arguments: arguments, depth: depth + 1) else { return nil }
        if case let .unqualified(owner?, _) = receiver, function.declaration.declaringType == nil {
            guard project.isTypeWithoutInheritance(named: owner, visibleFrom: source),
                  !project.isDynamicMemberLookupType(named: owner, visibleFrom: source),
                  !project.hasProperty(owner: owner, member: name, visibleFrom: source) else { return nil }
        }
        return signatureType(returnType, symbol: function, substitutions: substitutions)
    }

    /// An explicit constructor fixes the result type independently of its argument expressions.
    /// Still resolve its initializer to distinguish failable construction and ambiguous signatures.
    func constructedType(named spelling: String, arguments: [Formatter.FunctionCallArgument], at index: Int,
                         namespace: String?, accessingType: String?, depth: Int) -> ResolvedType?
    {
        let knownTypes = argumentTypeProvider(arguments, depth: depth + 1)
        if let accessingType {
            guard let reference = ProjectTypeReference(spelling), let root = reference.name.split(separator: ".").first,
                  project.constructorRootIsUnshadowed(String(root), in: accessingType, visibleFrom: fileURL) else { return nil }
        }
        guard let reference = ProjectTypeReference(spelling),
              project.declarationCountsAreUnambiguous(for: String(reference.name.split(separator: ".").last ?? ""), includingAliases: true),
              var result = type(named: spelling, namespace: namespace, at: index, requiresGenericArguments: true),
              let name = qualifiedName(for: result),
              project.declarationCountsAreUnambiguous(for: String(name.split(separator: ".").last ?? "")),
              let initializer = project.functionSymbol(named: "init", receiver: .type(name), arguments: arguments.map(\.label),
                                                       visibleFrom: result.sourceFileURL ?? fileURL,
                                                       accessedFrom: fileURL, accessedFromType: accessingType, kind: .initializer,
                                                       isViable: { self.viableOverload($0, owner: result, arguments: arguments, knownTypes: knownTypes()) },
                                                       requirementsSatisfied: { self.requirementsSatisfied($0, owner: result) }) else { return nil }
        if initializer.declaration.isFailable {
            result.name += "?"
        }
        return result
    }

    func functionValueResult(_ value: ResolvedType, arguments: [Formatter.FunctionCallArgument]) -> ResolvedType? {
        guard !value.isMetatype, unwrapped(value) == nil, let signature = value.functionType,
              arguments.count == signature.parameters.count, arguments.allSatisfy({ $0.label == nil }) else { return nil }
        return signature.result
    }

    /// A shorthand case can borrow context from a separately resolved operand, never from
    /// its spelling alone. Payload constructors still require normal callable resolution.
    func implicitEnumCaseType(in range: ClosedRange<Int>, expected: ResolvedType) -> ResolvedType? {
        guard let first = formatter.index(of: .nonSpaceOrCommentOrLinebreak, in: Range(range)),
              formatter.tokens[first].isOperator("."),
              let member = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: first),
              let last = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: range.upperBound + 1), member == last,
              formatter.tokens[member].isIdentifier else { return nil }
        let wrapped = unwrapped(expected) ?? expected
        guard let name = qualifiedName(for: wrapped),
              let cases = project.enumCases(named: name, visibleFrom: wrapped.sourceFileURL ?? fileURL),
              cases.contains(formatter.tokens[member].string) else { return nil }
        // Optional.none / Optional.some must not be mistaken for wrapped enum cases.
        if unwrapped(expected) != nil, ["none", "some"].contains(formatter.tokens[member].string) {
            return nil
        }
        return expected
    }

    func commonType(_ lhs: ResolvedType, _ rhs: ResolvedType) -> ResolvedType? {
        if sameType(lhs, as: rhs) {
            return lhs
        }
        if let wrapped = unwrapped(lhs), sameType(wrapped, as: rhs) {
            return lhs
        }
        if let wrapped = unwrapped(rhs), sameType(lhs, as: wrapped) {
            return rhs
        }
        return nil
    }

    func branchExpressionType(first: Int, last: Int, depth: Int) -> ResolvedType? {
        if let question = formatter.index(of: .operator("?", .infix), in: first ..< last) {
            var cursor = question
            var nesting = 0
            var colon: Int?
            while let next = formatter.index(after: cursor, where: { $0 == .operator("?", .infix) || $0.isOperator(":") || $0 == .delimiter(":") }), next < last {
                if formatter.tokens[next] == .operator("?", .infix) {
                    nesting += 1
                } else if nesting == 0 {
                    colon = next
                    break
                } else {
                    nesting -= 1
                }
                cursor = next
            }
            guard let colon, question + 1 < colon, colon + 1 <= last else { return nil }
            let lhsRange = question + 1 ... colon - 1
            let rhsRange = colon + 1 ... last
            let lhs = expressionType(in: lhsRange, depth: depth + 1)
            let rhs = expressionType(in: rhsRange, depth: depth + 1)
            if let lhs, let rhs {
                return commonType(lhs, rhs)
            }
            if let lhs {
                return implicitEnumCaseType(in: rhsRange, expected: lhs)
            }
            if let rhs {
                return implicitEnumCaseType(in: lhsRange, expected: rhs)
            }
            return nil
        }
        guard let coalescing = formatter.index(of: .operator("??", .infix), in: first ..< last), coalescing > first,
              !project.hasOperatorFunction(named: "??", visibleFrom: fileURL),
              let lhs = expressionType(in: first ... coalescing - 1, depth: depth + 1), let wrapped = unwrapped(lhs) else { return nil }
        let rhsRange = coalescing + 1 ... last
        let rhs = expressionType(in: rhsRange, depth: depth + 1) ?? implicitEnumCaseType(in: rhsRange, expected: wrapped)
        guard let rhs else { return nil }
        return commonType(wrapped, rhs)
    }

    func expressionType(in range: ClosedRange<Int>, expected: ResolvedType? = nil, depth: Int = 0) -> ResolvedType? {
        guard depth < 32,
              let first = formatter.index(of: .nonSpaceOrCommentOrLinebreak, in: Range(range)),
              let last = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: range.upperBound + 1), first <= last else { return nil }
        let tokens = formatter.tokens
        if tokens[first] == .keyword("try") || tokens[first].string == "await" {
            guard var start = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: first), start <= last else { return nil }
            let isOptionalTry = tokens[first] == .keyword("try") && tokens[start].isOperator("?")
            if tokens[first] == .keyword("try"), tokens[start].isUnwrapOperator {
                guard let next = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: start), next <= last else { return nil }
                start = next
            }
            guard var result = expressionType(in: start ... last, depth: depth + 1) else { return nil }
            if isOptionalTry {
                if result.name.hasSuffix("?") || result.name.hasSuffix("!") {
                    guard formatter.options.swiftVersion >= "5" else { return nil }
                    result.name = String(result.name.dropLast()) + "?"
                } else {
                    result.name += "?"
                }
            }
            return result
        }
        if formatter.index(of: .operator("?", .infix), in: first ..< last) != nil ||
            formatter.index(of: .operator("??", .infix), in: first ..< last) != nil
        {
            return branchExpressionType(first: first, last: last, depth: depth + 1)
        }
        if let cast = formatter.index(of: .keyword("as"), in: first ..< last),
           formatter.index(in: first ..< cast, where: { token in
               token == .keyword("try") || token.isOperator && !token.isOperator(".") &&
                   token != .operator("?", .postfix) && token != .operator("!", .postfix)
           }) == nil,
           var start = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: cast)
        {
            let optionalCast = tokens[start].isOperator("?")
            if tokens[start].isUnwrapOperator {
                guard let next = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: start) else { return nil }
                start = next
            }
            if let annotation = formatter.parseType(at: start), annotation.range.upperBound == last {
                let namespace = formatter.parseEnclosingType(containing: cast, declarations: declarations)?.fullyQualifiedName
                guard var result = type(named: annotation.string, namespace: namespace, at: cast) else { return nil }
                if optionalCast {
                    guard !result.name.hasSuffix("?"), !result.name.hasSuffix("!") else { return nil }
                    result.name += "?"
                }
                return result
            }
        }
        if tokens[first] == .startOfScope("("), formatter.endOfScope(at: first) == last, first + 1 < last {
            let arguments = formatter.parseTupleArguments(startOfScope: first).filter { $0.valueRange.upperBound < last }
            if arguments.count > 1 {
                let elements = arguments.compactMap { argument -> TupleElement? in
                    guard let value = expressionType(in: argument.valueRange, depth: depth + 1) else { return nil }
                    return TupleElement(label: argument.label, type: value)
                }
                guard elements.count == arguments.count else { return nil }
                return ResolvedType(name: "(" + elements.map(\.type.name).joined(separator: ", ") + ")",
                                    tupleElements: elements)
            }
            return expressionType(in: first + 1 ... last - 1, depth: depth + 1)
        }
        guard tokens[first].isIdentifier || tokens[first] == .startOfScope("(") || tokens[first] == .startOfScope("[") else { return nil }
        let namespace = formatter.parseEnclosingType(containing: first, declarations: declarations)?.fullyQualifiedName
        let identifier = tokens[first].string
        var current: ResolvedType?
        var cursor = first
        if let member = formatter.index(in: Range(first ... last), where: { $0.string == "self" }),
           let dot = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: member), dot > first,
           tokens[dot].isOperator("."),
           let reference = ProjectTypeReference(tokens[first ..< dot].string), let root = reference.name.split(separator: ".").first,
           bindings[String(root)]?.contains(where: { $0.isVisible(at: first) }) != true,
           !unindexedFunctions.contains(String(root)),
           namespace.map({ project.constructorRootIsUnshadowed(String(root), in: $0, visibleFrom: fileURL) }) ?? true,
           initializerRootIsUnshadowed(tokens[first ..< dot].string),
           var metatype = type(named: tokens[first ..< dot].string, namespace: namespace, at: first, requiresGenericArguments: true),
           !metatype.isMetatype, unwrapped(metatype) == nil,
           let name = qualifiedName(for: metatype), project.hasSymbolType(named: name, visibleFrom: metatype.sourceFileURL ?? fileURL)
        {
            metatype.isMetatype = true
            current = metatype
            cursor = member
        } else if let annotation = formatter.parseType(at: first),
                  let open = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: annotation.range.upperBound),
                  tokens[open] == .startOfScope("("), let close = formatter.endOfScope(at: open), close <= last,
                  let collection = explicitInitializerType(formatter.tokens[first ... close].string, namespace: namespace, source: fileURL, substitutions: [:]),
                  collection.collectionKind != nil,
                  bindings[identifier]?.contains(where: { $0.isVisible(at: first) }) != true,
                  !unindexedFunctions.contains(identifier)
        {
            current = collection
            cursor = close
        } else if tokens[first].isIdentifier,
                  bindings[identifier]?.contains(where: { $0.isVisible(at: first) }) != true,
                  !unindexedFunctions.contains(identifier),
                  let annotation = formatter.parseType(at: first),
                  let open = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: annotation.range.upperBound),
                  tokens[open] == .startOfScope("("), let close = formatter.endOfScope(at: open), close <= last,
                  let constructed = constructedType(named: annotation.string,
                                                    arguments: formatter.parseFunctionCallArguments(startOfScope: open).filter { $0.valueRange.upperBound <= last },
                                                    at: first, namespace: namespace, accessingType: namespace, depth: depth + 1)
        {
            current = constructed
            cursor = close
        } else if tokens[first].isIdentifier,
                  bindings[identifier]?.contains(where: { $0.isVisible(at: first) }) != true,
                  !unindexedFunctions.contains(identifier),
                  unavailableTypes[identifier]?.contains(where: { $0.range.contains(first) }) != true,
                  namespace.map({ project.constructorRootIsUnshadowed(identifier, in: $0, visibleFrom: fileURL) }) ?? true,
                  let value = explicitInitializerType(tokens[first ... last].string, namespace: namespace, source: fileURL, substitutions: [:])
        {
            return specializedType(value, expected: expected ?? contextualType(at: first, depth: depth + 1))
        } else if tokens[first] == .startOfScope("("), let end = formatter.endOfScope(at: first), first + 1 < end, end < last {
            current = expressionType(in: first + 1 ... end - 1, depth: depth + 1)
            cursor = end
        } else if let open = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: first), open <= last,
                  tokens[open] == .startOfScope("("), let close = formatter.endOfScope(at: open), close <= last
        {
            guard !unindexedFunctions.contains(identifier),
                  unavailableTypes[identifier]?.contains(where: { $0.range.contains(first) }) != true else { return nil }
            let arguments = formatter.parseFunctionCallArguments(startOfScope: open).filter { $0.valueRange.upperBound <= last }
            if let value = bindingType(named: identifier, at: first, depth: depth + 1), value.functionType != nil {
                current = functionValueResult(value, arguments: arguments)
            } else {
                guard bindings[identifier]?.contains(where: { $0.isVisible(at: first) }) != true else { return nil }
                let receiver = project.functionCallReceiver(at: first, in: formatter, visibleFrom: fileURL, declarations: declarations)
                current = receiver.flatMap { callType(name: identifier, receiver: $0, arguments: arguments, accessingType: namespace, depth: depth + 1) }
            }
            cursor = arguments.last.map { max(close, $0.valueRange.upperBound) } ?? close
        } else if identifier == "self" || identifier == "Self" {
            let receiver = project.functionCallReceiver(at: first, in: formatter, visibleFrom: fileURL, declarations: declarations)
            let isStatic: Bool
            if case let .unqualified(_, value) = receiver {
                isStatic = value
            } else {
                isStatic = false
            }
            if identifier == "self", bindings[identifier]?.contains(where: { $0.isVisible(at: first) }) == true {
                current = bindingType(named: identifier, at: first, depth: depth + 1)
            } else {
                current = namespace.map { ResolvedType(name: $0, namespace: nil, isMetatype: identifier == "Self" || isStatic) }
            }
        } else if let enumCase = unqualifiedEnumCase(named: identifier, at: first) {
            current = enumCase.payloadTypes.isEmpty ? enumCase.type : nil
        } else {
            current = bindingType(named: identifier, at: first, depth: depth + 1)
            if current == nil, bindings[identifier]?.contains(where: { $0.isVisible(at: first) }) != true,
               initializerRootIsUnshadowed(identifier),
               namespace.map({ project.constructorRootIsUnshadowed(identifier, in: $0, visibleFrom: fileURL) }) ?? true,
               let possibleType = type(named: identifier, namespace: namespace, at: first), !possibleType.isMetatype, unwrapped(possibleType) == nil,
               let name = qualifiedName(for: possibleType), project.hasSymbolType(named: name, visibleFrom: fileURL)
            {
                var metatype = specializedType(possibleType, expected: expected ?? contextualType(at: first, depth: depth + 1))
                metatype.isMetatype = true
                current = metatype
            }
        }
        var optionalChain = false
        while var dot = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: cursor), dot <= last {
            if tokens[dot] == .operator("?", .postfix) || tokens[dot] == .operator("!", .postfix) {
                optionalChain = optionalChain || tokens[dot].isOperator("?")
                guard let value = current.flatMap(unwrapped) else { return nil }
                current = value
                if dot == last, tokens[dot].isOperator("!") {
                    break
                }
                guard let next = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: dot) else { return nil }
                dot = next
            } else if let value = current, value.name.hasSuffix("!") {
                current = unwrapped(value)
            }
            if [Token.startOfScope("("), .startOfScope("{")].contains(tokens[dot]),
               let close = formatter.endOfScope(at: dot), close <= last, let callable = current, callable.functionType != nil
            {
                let arguments = formatter.parseFunctionCallArguments(startOfScope: dot).filter { $0.valueRange.upperBound <= last }
                current = functionValueResult(callable, arguments: arguments)
                cursor = arguments.last.map { max(close, $0.valueRange.upperBound) } ?? close
                continue
            }
            if tokens[dot] == .startOfScope("["), let close = formatter.endOfScope(at: dot), close <= last,
               let owner = current, owner.collectionKind != nil
            {
                current = collectionSubscript(owner: owner, arguments: formatter.parseTupleArguments(startOfScope: dot), depth: depth + 1)
                cursor = close
                continue
            }
            guard dot <= last, tokens[dot].isOperator("."),
                  let member = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: dot), member <= last,
                  let owner = current else { return nil }
            let memberName = tokens[member].string
            if tokens[member].string == "self" {
                cursor = member
                continue
            }
            if owner.tupleElements != nil {
                current = memberType(owner: owner, name: memberName, accessingType: namespace)
                cursor = member
                continue
            }
            guard tokens[member].isIdentifier, let ownerName = qualifiedName(for: owner) else { return nil }
            if let open = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: member), open <= last,
               tokens[open] == .startOfScope("(") || tokens[open] == .startOfScope("{"),
               let close = formatter.endOfScope(at: open), close <= last
            {
                let arguments = formatter.parseFunctionCallArguments(startOfScope: open).filter { $0.valueRange.upperBound <= last }
                if owner.collectionKind != nil {
                    current = collectionCall(owner: owner, name: memberName, arguments: arguments, depth: depth + 1)
                } else if memberName == "get", arguments.isEmpty, standardResultArguments(owner) != nil {
                    current = standardResultCall(owner: owner, name: memberName, arguments: arguments)
                } else if project.hasProperty(owner: ownerName, member: memberName, visibleFrom: owner.sourceFileURL ?? fileURL, accessedFrom: fileURL) {
                    guard let value = memberType(owner: owner, name: memberName, accessingType: namespace) else { return nil }
                    current = functionValueResult(value, arguments: arguments)
                } else {
                    current = callType(name: memberName, receiver: owner.isMetatype ? .type(ownerName) : .instance(type: ownerName), arguments: arguments, sourceFileURL: owner.sourceFileURL, owner: owner, accessingType: namespace, depth: depth + 1)
                }
                cursor = arguments.last.map { max(close, $0.valueRange.upperBound) } ?? close
            } else {
                current = memberType(owner: owner, name: memberName, accessingType: namespace)
                if current == nil, owner.isMetatype, project.hasSymbolType(named: "\(ownerName).\(memberName)", visibleFrom: fileURL) {
                    current = ResolvedType(name: "\(ownerName).\(memberName)", namespace: nil, isMetatype: true)
                }
                if current == nil, owner.isMetatype,
                   project.enumCases(named: ownerName, visibleFrom: owner.sourceFileURL ?? fileURL)?.contains(memberName) == true
                {
                    current = ResolvedType(name: ownerName, namespace: nil, sourceFileURL: owner.sourceFileURL, genericArguments: owner.genericArguments)
                }
                cursor = member
            }
        }
        if optionalChain, var result = current {
            if !result.name.hasSuffix("?"), !result.name.hasSuffix("!") {
                result.name += "?"
            }
            return result
        }
        return current
    }
}

/// A nominal type spelling and its generic arguments, shared by symbol lookup consumers.
struct ProjectTypeReference {
    var name: String
    var arguments: [String]
    var hasGenericParent: Bool

    init?(_ spelling: String) {
        let formatter = Formatter(tokenize(spelling))
        guard !formatter.tokens.isEmpty else { return nil }
        var components = [String]()
        var arguments = [String]()
        var hasGenericParent = false
        var skipThrough = -1
        var valid = true
        formatter.forEachToken { index, token in
            guard index > skipThrough, !token.isSpaceOrCommentOrLinebreak else { return }
            if token == .startOfScope("<"), let end = formatter.endOfScope(at: index) {
                hasGenericParent = hasGenericParent || formatter.next(.nonSpaceOrCommentOrLinebreak, after: end)?.isOperator(".") == true
                let elements = formatter.commaSeparatedElementsInScope(startOfScope: index)
                if elements.isEmpty {
                    let argument = formatter.tokens[index + 1 ..< end].filter { !$0.isSpaceOrCommentOrLinebreak }.string
                    if !argument.isEmpty {
                        arguments.append(argument)
                    }
                } else {
                    arguments += elements.map { formatter.tokens[$0].string }
                }
                skipThrough = end
            } else if token.isIdentifier || token.isOperator(".") {
                components.append(token.string)
            } else {
                valid = false
            }
        }
        guard valid, !components.isEmpty, components.first != ".", components.last != "." else { return nil }
        name = components.joined()
        self.arguments = arguments
        self.hasGenericParent = hasGenericParent
    }
}
