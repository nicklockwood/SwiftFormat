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
    struct ResolvedType {
        var name: String
        var namespace: String?
        var sourceFileURL: URL?
        var genericArguments: [ResolvedType]?
        var isMetatype = false
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
                for name in formatter.tokens[start ..< end] where name.isIdentifier {
                    self.addBinding(name.string, at: i, scope: body ... close, namespace: namespace)
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
                    requiresPrecedingDeclaration: Bool = false, isGlobal: Bool = false, wrapsOptional: Bool = false, pattern: PatternBinding? = nil, closure: ClosureBinding? = nil, typeRequiresGenericArguments: Bool = false, excludedScope: ClosedRange<Int>? = nil)
    {
        bindings[name, default: []].append(Binding(
            closure: closure, pattern: pattern, wrapsOptional: wrapsOptional, location: AutoUpdatingRange(range: index ... index, formatter: formatter),
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
            .drop(while: { ["inout", "borrowing", "consuming", "sending"].contains($0.string) })
        if let index, tokens.contains(where: { token in
            token.isIdentifier && (unavailableTypes[token.string] ?? []).contains { $0.range.contains(index) }
        }) {
            return nil
        }
        let name = tokens.string
        let optional = name.hasSuffix("?") || name.hasSuffix("!")
        let base = optional ? String(name.dropLast()) : name
        if var substitution = substitutions[base] {
            if optional {
                substitution.name += "?"
            }
            return substitution
        }
        guard let nominal = ProjectTypeReference(base) else { return ResolvedType(name: name, namespace: namespace, sourceFileURL: sourceFileURL) }
        let arguments = nominal.arguments.compactMap {
            type(named: $0, namespace: namespace, at: index, sourceFileURL: sourceFileURL, substitutions: substitutions, requiresGenericArguments: true, depth: depth + 1)
        }
        guard arguments.count == nominal.arguments.count,
              let lexicalName = qualifiedName(for: ResolvedType(name: base, namespace: namespace, sourceFileURL: sourceFileURL)) else { return nil }
        let symbol = !nominal.hasGenericParent && (requiresGenericArguments || !nominal.arguments.isEmpty)
            ? project.typeSymbol(named: lexicalName, genericArgumentCount: arguments.count, visibleFrom: sourceFileURL ?? fileURL)
            : nil
        let qualified = symbol?.name ?? lexicalName
        let sourceFileURL = symbol?.fileURL ?? sourceFileURL
        if let alias = project.typeAlias(named: qualified, visibleFrom: sourceFileURL ?? fileURL) {
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

    /// The nominal declaration name; optional, tuple and function types have no nominal result here.
    func qualifiedName(for type: ResolvedType) -> String? {
        guard let nominal = ProjectTypeReference(type.name) else { return nil }
        var namespace = type.namespace
        while let owner = namespace {
            let name = "\(owner).\(nominal.name)"
            if localTypes[name] != nil || project.hasSymbolType(named: name, visibleFrom: type.sourceFileURL ?? fileURL) ||
                project.typeAlias(named: name, visibleFrom: type.sourceFileURL ?? fileURL) != nil
            {
                return name
            }
            if !nominal.name.contains(".") {
                switch project.inheritedType(named: nominal.name, of: owner, visibleFrom: type.sourceFileURL ?? fileURL) {
                case let .type(name): return name
                case .unknown: return nil
                case .absent: break
                }
            }
            namespace = owner.contains(".") ? owner.split(separator: ".").dropLast().joined(separator: ".") : nil
        }
        return nominal.name
    }

    /// Names alone cannot establish equality when imports introduce namesakes.
    func sameType(_ lhs: ResolvedType, as rhs: ResolvedType) -> Bool {
        guard let left = qualifiedName(for: lhs), let right = qualifiedName(for: rhs),
              let identity = project.typeIdentity(named: left, visibleFrom: lhs.sourceFileURL ?? fileURL),
              identity == project.typeIdentity(named: right, visibleFrom: rhs.sourceFileURL ?? fileURL) else { return false }
        let leftArguments = lhs.genericArguments ?? []
        let rightArguments = rhs.genericArguments ?? []
        return leftArguments.count == rightArguments.count && zip(leftArguments, rightArguments).allSatisfy { sameType($0, as: $1) }
    }

    func bindingType(named name: String, at index: Int, depth: Int) -> ResolvedType? {
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
        return ResolvedType(name: String(type.name.dropLast()), namespace: type.namespace, sourceFileURL: type.sourceFileURL, genericArguments: type.genericArguments)
    }

    func memberType(owner: ResolvedType, name: String, accessingType: String? = nil) -> ResolvedType? {
        guard let ownerName = qualifiedName(for: owner),
              let nominal = ProjectTypeReference(owner.name),
              let declaration = project.typeDeclaration(named: ownerName, visibleFrom: owner.sourceFileURL ?? fileURL),
              let member = project.propertyType(owner: ownerName, member: name, isStatic: owner.isMetatype, visibleFrom: owner.sourceFileURL ?? fileURL, accessedFrom: fileURL, accessedFromType: accessingType) else { return nil }
        let arguments = owner.genericArguments ?? nominal.arguments.compactMap {
            type(named: $0, namespace: owner.namespace, sourceFileURL: owner.sourceFileURL)
        }
        guard declaration.genericParameters.count == arguments.count else { return nil }
        let substitutions = Dictionary(uniqueKeysWithValues: zip(declaration.genericParameters, arguments))
        return type(named: member.name, namespace: member.namespace, sourceFileURL: member.fileURL, substitutions: substitutions)
    }

    func enumPayloadType(owner: ResolvedType, caseName: String, at position: Int) -> ResolvedType? {
        if caseName == "some", position == 0, let wrapped = unwrapped(owner) {
            return wrapped
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

    /// Bind a declaration's generic parameters from a known receiver and the call's arguments.
    func substitutions(for symbol: ProjectIndex.FunctionSymbol, owner: ResolvedType?,
                       arguments: [Formatter.FunctionCallArgument], depth: Int, ignoringLabelAt ignoredLabel: Int? = nil, contextualClosureArgumentAt contextualArgument: Int? = nil) -> [String: ResolvedType]?
    {
        var substitutions = [String: ResolvedType]()
        if let name = symbol.declaration.declaringType,
           let declaration = project.typeDeclaration(named: name, visibleFrom: symbol.fileURL), !declaration.genericParameters.isEmpty
        {
            guard let owner, let arguments = owner.genericArguments, arguments.count == declaration.genericParameters.count else { return nil }
            substitutions = Dictionary(uniqueKeysWithValues: zip(declaration.genericParameters, arguments))
        }
        for name in symbol.declaration.genericParameters {
            substitutions.removeValue(forKey: name)
        }
        let genericNames = Set(symbol.declaration.genericParameters)
        var fixedGenericNames = Set<String>()
        var contextualGenericNames = Set<String>()
        func infer(_ pattern: String, from value: ResolvedType, nesting: Int = 0, invariant: Bool = false) -> Bool {
            guard nesting < 8 else { return false }
            let pattern = tokenize(pattern).filter { !$0.isSpaceOrCommentOrLinebreak }.string
            if genericNames.contains(pattern) {
                if let previous = substitutions[pattern], !sameType(previous, as: value) {
                    return false
                }
                substitutions[pattern] = value
                if invariant {
                    fixedGenericNames.insert(pattern)
                }
                return true
            }
            if pattern.hasSuffix("?") || pattern.hasSuffix("!") {
                guard let wrapped = unwrapped(value) else { return false }
                return infer(String(pattern.dropLast()), from: wrapped, nesting: nesting + 1, invariant: invariant)
            }
            guard let reference = ProjectTypeReference(pattern), !reference.hasGenericParent,
                  let actual = ProjectTypeReference(value.name), !actual.hasGenericParent,
                  let formal = type(named: reference.name, namespace: symbol.declaration.declaringType, sourceFileURL: symbol.fileURL),
                  let formalName = qualifiedName(for: formal), let actualName = qualifiedName(for: value),
                  let identity = project.typeIdentity(named: formalName, visibleFrom: formal.sourceFileURL ?? symbol.fileURL),
                  identity == project.typeIdentity(named: actualName, visibleFrom: value.sourceFileURL ?? fileURL) else { return false }
            let arguments = value.genericArguments ?? actual.arguments.compactMap {
                type(named: $0, namespace: value.namespace, sourceFileURL: value.sourceFileURL)
            }
            guard arguments.count == reference.arguments.count else { return false }
            let declarationSource = project.typeSourceFile(named: formalName, visibleFrom: formal.sourceFileURL ?? symbol.fileURL)
            let fixed = invariant || declarationSource?.pathExtension == "swift"
            return zip(reference.arguments, arguments).allSatisfy { infer($0.0, from: $0.1, nesting: nesting + 1, invariant: fixed) }
        }
        if let parameters = symbol.declaration.symbolArgumentTypes,
           let indices = symbol.declaration.parameterIndices(matching: arguments.map(\.label), ignoringLabelAt: ignoredLabel)
        {
            for (position, entry) in zip(arguments, indices).enumerated() {
                let (argument, parameter) = entry
                var pattern = parameters[parameter]
                guard tokenize(pattern).contains(where: { genericNames.contains($0.string) }) else { continue }
                if position == contextualArgument {
                    let signature = Formatter(tokenize(pattern))
                    guard let open = signature.index(of: .startOfScope("("), after: -1),
                          let close = signature.endOfScope(at: open),
                          let arrow = signature.index(of: .nonSpaceOrCommentOrLinebreak, after: close), signature.tokens[arrow].isOperator("->"),
                          !signature.tokens[arrow + 1 ..< signature.tokens.count].contains(where: { genericNames.contains($0.string) }),
                          !signature.tokens.contains(.keyword("inout")),
                          !formatter.tokens[argument.valueRange].contains(where: { $0.isOperator("&") }) else { return nil }
                    // Invariant callback inputs can constrain the generic parameter from the body.
                    for parameter in signature.parseTupleArguments(startOfScope: open) {
                        let tokens = signature.tokens[parameter.valueRange].filter { !$0.isSpaceOrCommentOrLinebreak }
                        if tokens.contains(where: { genericNames.contains($0.string) }),
                           !(tokens.count == 1 && genericNames.contains(tokens[0].string))
                        {
                            return nil
                        }
                    }
                    contextualGenericNames.formUnion(signature.tokens.map(\.string).filter { genericNames.contains($0) })
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
        // A contextual closure body may widen a type inferred from a covariant value argument.
        guard contextualGenericNames.isSubset(of: fixedGenericNames) else { return nil }
        return substitutions
    }

    func signatureType(_ raw: String, symbol: ProjectIndex.FunctionSymbol, substitutions: [String: ResolvedType]) -> ResolvedType? {
        let unknown = Set(symbol.declaration.genericParameters).subtracting(substitutions.keys)
        guard !tokenize(raw).contains(where: { $0.isIdentifier && unknown.contains($0.string) }) else { return nil }
        return type(named: raw, namespace: symbol.declaration.declaringType, sourceFileURL: symbol.fileURL, substitutions: substitutions, requiresGenericArguments: true)
    }

    func closureParameterType(_ binding: ClosureBinding, depth: Int) -> ResolvedType? {
        let location = binding.location.range.lowerBound
        guard depth < 12, let call = formatter.callContainingClosure(at: location),
              !unindexedFunctions.contains(formatter.tokens[call.identifier].string),
              bindings[formatter.tokens[call.identifier].string]?.contains(where: { $0.isVisible(at: call.identifier) }) != true else { return nil }
        let arguments = formatter.parseFunctionCallArguments(startOfScope: call.scope)
        guard let argument = arguments.firstIndex(where: { $0.valueRange.lowerBound == location }) else { return nil }
        let scopeEnd = formatter.endOfScope(at: call.scope) ?? call.scope
        let trailing = arguments.firstIndex { formatter.tokens[call.scope] == .startOfScope("{") || $0.valueRange.lowerBound > scopeEnd }
        var owner: ResolvedType?
        let receiver: ProjectIndex.FunctionCallReceiver?
        if let dot = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: call.identifier), formatter.tokens[dot].isOperator("."),
           let start = formatter.startOfMemberCallReceiver(endingAt: dot), start < dot
        {
            owner = expressionType(in: start ... dot - 1, depth: depth + 1)
            receiver = owner.flatMap { value in qualifiedName(for: value).map { value.isMetatype ? .type($0) : .instance(type: $0) } }
        } else {
            receiver = project.functionCallReceiver(at: call.identifier, in: formatter, visibleFrom: fileURL, declarations: declarations)
        }
        guard let receiver,
              let symbol = project.functionSymbol(named: formatter.tokens[call.identifier].string, receiver: receiver,
                                                  arguments: arguments.map(\.label), visibleFrom: owner?.sourceFileURL ?? fileURL, ignoringLabelAt: trailing, accessedFrom: fileURL, accessedFromType: formatter.parseEnclosingType(containing: location, declarations: declarations)?.fullyQualifiedName),
              let indices = symbol.declaration.parameterIndices(matching: arguments.map(\.label), ignoringLabelAt: trailing),
              let parameterTypes = symbol.declaration.symbolArgumentTypes ?? symbol.declaration.argumentTypes,
              parameterTypes.indices.contains(indices[argument]),
              let substitutions = substitutions(for: symbol, owner: owner, arguments: arguments, depth: depth + 1, ignoringLabelAt: trailing, contextualClosureArgumentAt: argument) else { return nil }
        if case let .unqualified(owner?, _) = receiver, symbol.declaration.declaringType == nil {
            guard project.isTypeWithoutInheritance(named: owner, visibleFrom: fileURL),
                  !project.isDynamicMemberLookupType(named: owner, visibleFrom: fileURL),
                  !project.hasProperty(owner: owner, member: formatter.tokens[call.identifier].string, visibleFrom: fileURL) else { return nil }
        }
        let signature = Formatter(tokenize(parameterTypes[indices[argument]]))
        guard let open = signature.index(of: .startOfScope("("), after: -1),
              let close = signature.endOfScope(at: open),
              signature.next(.nonSpaceOrCommentOrLinebreak, after: close)?.isOperator("->") == true else { return nil }
        let parameters = signature.parseTupleArguments(startOfScope: open)
        guard parameters.indices.contains(binding.parameterIndex) else { return nil }
        return signatureType(signature.tokens[parameters[binding.parameterIndex].valueRange].string, symbol: symbol, substitutions: substitutions)
    }

    func callType(name: String, receiver: ProjectIndex.FunctionCallReceiver, arguments: [Formatter.FunctionCallArgument],
                  sourceFileURL: URL? = nil, owner: ResolvedType? = nil, accessingType: String? = nil, depth: Int) -> ResolvedType?
    {
        let source = sourceFileURL ?? fileURL
        guard !unindexedFunctions.contains(name),
              let function = project.functionSymbol(named: name, receiver: receiver, arguments: arguments.map(\.label), visibleFrom: source, accessedFrom: fileURL, accessedFromType: accessingType),
              let returnType = function.declaration.symbolReturnType ?? function.declaration.returnType,
              let substitutions = substitutions(for: function, owner: owner, arguments: arguments, depth: depth + 1) else { return nil }
        if case let .unqualified(owner?, _) = receiver, function.declaration.declaringType == nil {
            guard project.isTypeWithoutInheritance(named: owner, visibleFrom: source),
                  !project.isDynamicMemberLookupType(named: owner, visibleFrom: source),
                  !project.hasProperty(owner: owner, member: name, visibleFrom: source) else { return nil }
        }
        return signatureType(returnType, symbol: function, substitutions: substitutions)
    }

    func expressionType(in range: ClosedRange<Int>, depth: Int = 0) -> ResolvedType? {
        guard depth < 12,
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
            return expressionType(in: first + 1 ... last - 1, depth: depth + 1)
        }
        guard tokens[first].isIdentifier || tokens[first] == .startOfScope("(") else { return nil }
        let namespace = formatter.parseEnclosingType(containing: first, declarations: declarations)?.fullyQualifiedName
        let identifier = tokens[first].string
        var current: ResolvedType?
        var cursor = first
        if tokens[first] == .startOfScope("("), let end = formatter.endOfScope(at: first), first + 1 < end, end < last {
            current = expressionType(in: first + 1 ... end - 1, depth: depth + 1)
            cursor = end
        } else if let open = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: first), open <= last,
                  tokens[open] == .startOfScope("("), let close = formatter.endOfScope(at: open), close <= last
        {
            guard bindings[identifier]?.contains(where: { $0.isVisible(at: first) }) != true else { return nil }
            let receiver = project.functionCallReceiver(at: first, in: formatter, visibleFrom: fileURL, declarations: declarations)
            current = receiver.flatMap { callType(name: identifier, receiver: $0, arguments: formatter.parseFunctionCallArguments(startOfScope: open).filter { $0.valueRange.upperBound <= last }, accessingType: namespace, depth: depth + 1) }
            cursor = close
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
        } else {
            current = bindingType(named: identifier, at: first, depth: depth + 1)
            if current == nil, bindings[identifier]?.contains(where: { $0.isVisible(at: first) }) != true,
               let possibleType = type(named: identifier, namespace: namespace, at: first),
               let name = qualifiedName(for: possibleType), project.hasSymbolType(named: name, visibleFrom: fileURL)
            {
                var metatype = possibleType
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
            guard dot <= last, tokens[dot].isOperator("."),
                  let member = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: dot), member <= last,
                  tokens[member].isIdentifier, let owner = current, let ownerName = qualifiedName(for: owner) else { return nil }
            let memberName = tokens[member].string
            if let open = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: member), open <= last,
               tokens[open] == .startOfScope("("), let close = formatter.endOfScope(at: open), close <= last
            {
                let arguments = formatter.parseFunctionCallArguments(startOfScope: open).filter { $0.valueRange.upperBound <= last }
                current = callType(name: memberName, receiver: owner.isMetatype ? .type(ownerName) : .instance(type: ownerName), arguments: arguments, sourceFileURL: owner.sourceFileURL, owner: owner, accessingType: namespace, depth: depth + 1)
                cursor = close
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
