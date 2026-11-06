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
        let qualifiers: [String]
        let requiresArgumentProof: Bool

        init(parameters: [ResolvedType], result: ResolvedType, qualifiers: [String], requiresArgumentProof: Bool = false) {
            self.parameters = parameters
            self.result = result
            self.qualifiers = qualifiers
            self.requiresArgumentProof = requiresArgumentProof
        }
    }

    final class EnclosingType {
        let type: ResolvedType

        init(_ type: ResolvedType) {
            self.type = type
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
        var isAbstractProtocol = false
        var isAbstract: Bool {
            genericParameterScope != nil || isAbstractProtocol
        }

        var genericParameterScope: AutoUpdatingRange?
        var genericUseSite: AutoUpdatingRange?
        var enclosingType: EnclosingType?
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
        var tuplePath = [Int]()
        var namespace: String?
        var unwrapsOptional = false
        var requiresPrecedingDeclaration = false
        var isGlobal = false
        var typeRequiresGenericArguments = false
        var excludedScope: AutoUpdatingRange?

        func isVisible(at index: Int) -> Bool {
            scope.range.contains(index) && excludedScope?.range.contains(index) != true &&
                (!requiresPrecedingDeclaration || (value?.range.upperBound ?? location.range.lowerBound) < index)
        }
    }

    struct GenericContext {
        var scope: AutoUpdatingRange
        var namespace: String?
        var requirements: [SourceFileIndex.GenericRequirement]
    }

    struct RequirementQuery: Hashable {
        var scope: ObjectIdentifier
        var name: String
    }

    let formatter: Formatter
    let project: ProjectIndex
    let fileURL: URL
    let declarations: [Declaration]
    var bindings = [String: [Binding]]()
    var unavailableTypes = [String: [AutoUpdatingRange]]()
    var genericParameterScopes = [String: [AutoUpdatingRange]]()
    var genericTypeScopes = [String: [(range: AutoUpdatingRange, parameters: [String])]]()

    var localTypes = [String: [TypeDeclaration]]()
    var localFunctionScopes = [String: [AutoUpdatingRange]]()
    var activeBindings = Set<ObjectIdentifier>()
    var activeAliases = Set<String>()
    var genericContexts = [GenericContext]()
    var activeRequirements = Set<RequirementQuery>()
    var conditionalExpressions = [AutoUpdatingRange]()

    init(formatter: Formatter, project: ProjectIndex, fileURL: URL) {
        self.formatter = formatter
        self.project = project
        self.fileURL = fileURL
        declarations = formatter.parseDeclarations()
        declarations.forEachRecursiveDeclaration { declaration in
            if let type = declaration.asTypeDeclaration,
               let openingBrace = formatter.index(of: .startOfScope("{"), in: type.keywordIndex ..< type.range.upperBound)
            {
                self.addGenericContext(type.genericParameters?.types ?? [],
                                       whereClause: formatter.index(of: .keyword("where"), in: type.keywordIndex ..< openingBrace),
                                       scope: type.range, namespace: type.fullyQualifiedName)
                if type.definesType, let name = type.fullyQualifiedName {
                    self.localTypes[name, default: []].append(type)
                }
                if let name = type.fullyQualifiedName {
                    let parameters = type.genericParameters?.types.map(\.name) ??
                        (type.keyword == "extension" ? project.typeDeclaration(named: name, visibleFrom: fileURL)?.genericParameters : nil) ?? []
                    if !parameters.isEmpty {
                        let scope = AutoUpdatingRange(range: type.range, formatter: formatter)
                        self.genericTypeScopes[name, default: []].append((scope, parameters))
                        for parameter in parameters {
                            self.unavailableTypes[parameter, default: []].append(scope)
                            self.genericParameterScopes[parameter, default: []].append(scope)
                        }
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
            if token == .keyword("if") || token == .keyword("switch"),
               self.conditionalValueRanges(at: i) != nil,
               let end = formatter.conditionalBranches(at: i)?.last?.endOfBranch
            {
                self.conditionalExpressions.append(AutoUpdatingRange(range: i ... end, formatter: formatter))
            }
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
                if conditional == nil, self.addTupleDeclarationBindings(at: i, scope: scope, namespace: namespace) {
                    return
                }
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
                if formatter.declarationScope(at: i) == .local, let name = function.name,
                   let start = lexicalScope(at: i), let end = formatter.endOfScope(at: start)
                {
                    self.localFunctionScopes[name.replacingOccurrences(of: "`", with: ""), default: []]
                        .append(AutoUpdatingRange(range: start ... end, formatter: formatter))
                }
                self.addGenericContext(function.genericParameterRange.map { formatter.parseGenericTypes(from: $0.lowerBound).types } ?? [],
                                       whereClause: function.whereClauseRange?.lowerBound,
                                       scope: i ... (function.bodyRange?.upperBound ?? function.whereClauseRange?.upperBound ?? i), namespace: namespace)
                if let parameters = function.genericParameterRange {
                    let scope = i ... (function.bodyRange?.upperBound ?? parameters.upperBound)
                    for parameter in formatter.parseGenericTypes(from: parameters.lowerBound).types {
                        let range = AutoUpdatingRange(range: scope, formatter: formatter)
                        self.unavailableTypes[parameter.name, default: []].append(range)
                        self.genericParameterScopes[parameter.name, default: []].append(range)
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
                let patternEnd = formatter.index(of: .keyword("where"), in: index + 1 ..< body) ?? body
                if !formatter.tokens[index + 1 ..< patternEnd].contains(where: { $0 == .keyword("let") || $0 == .keyword("var") }) {
                    self.addBinding("error", at: index, scope: body ... end, namespace: nil)
                }
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

    /// Destructured declarations retain the tuple's annotation or initializer and project
    /// each binding from that shared source. Initializers are evaluated before the new names.
    private func addTupleDeclarationBindings(at index: Int, scope: ClosedRange<Int>, namespace: String?) -> Bool {
        guard let open = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index),
              formatter.tokens[open] == .startOfScope("(") else { return false }
        var pattern: Int? = open
        while let start = pattern {
            guard let close = formatter.tokens[start] == .startOfScope("(") ? formatter.endOfScope(at: start) : start,
                  formatter.tokens[start].isIdentifier || formatter.tokens[start] == .startOfScope("(") else { break }
            var end = close
            var tail = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: close)
            var annotation: String?
            if let colon = tail, formatter.tokens[colon] == .delimiter(":"),
               let start = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: colon), let type = formatter.parseType(at: start)
            {
                annotation = type.string
                end = type.range.upperBound
                tail = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: end)
            }
            let value = tail.flatMap { formatter.tokens[$0] == .operator("=", .infix) ? formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: $0) : nil }
                .flatMap { formatter.parseExpressionRange(startingAt: $0, allowConditionalExpressions: true) }
            func add(in range: ClosedRange<Int>, path: [Int]) {
                guard let first = formatter.index(of: .nonSpaceOrCommentOrLinebreak, in: Range(range)),
                      let last = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: range.upperBound + 1), first <= last else { return }
                if first == last, formatter.tokens[first].isIdentifier, formatter.tokens[first].string != "_" {
                    addBinding(formatter.tokens[first].string, at: index, scope: scope, type: annotation, value: value, tuplePath: path,
                               namespace: namespace, requiresPrecedingDeclaration: formatter.declarationScope(at: index) == .local,
                               isGlobal: formatter.declarationScope(at: index) == .global)
                } else if formatter.tokens[first] == .startOfScope("("), formatter.endOfScope(at: first) == last {
                    for (position, element) in formatter.parseTupleArguments(startOfScope: first).enumerated() {
                        add(in: element.valueRange, path: path + [position])
                    }
                }
            }
            add(in: start ... close, path: [])
            guard let comma = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: value?.upperBound ?? end),
                  formatter.tokens[comma] == .delimiter(",") else { break }
            pattern = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: comma)
        }
        return true
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
            let cast = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: location)
                .flatMap { formatter.tokens[$0] == .keyword("as") ? formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: $0) : nil }
                .flatMap { formatter.parseType(at: $0) }
            let annotation = cast.flatMap { $0.range.upperBound < range.upperBound ? $0.string : nil }
            let namespace = formatter.parseEnclosingType(containing: index, declarations: declarations)?.fullyQualifiedName
            addBinding(name, at: index, scope: scope, type: annotation, namespace: namespace, pattern: pattern, excludedScope: excludedScope)
        }
    }

    func addBinding(_ name: String, at index: Int, scope: ClosedRange<Int>, type: String? = nil,
                    value: ClosedRange<Int>? = nil, tuplePath: [Int] = [], namespace: String?, unwrapsOptional: Bool = false,
                    requiresPrecedingDeclaration: Bool = false, isGlobal: Bool = false, wrapsOptional: Bool = false, pattern: PatternBinding? = nil, closure: ClosureBinding? = nil, element: ElementBinding? = nil, typeRequiresGenericArguments: Bool = false, excludedScope: ClosedRange<Int>? = nil)
    {
        bindings[name, default: []].append(Binding(
            element: element, closure: closure, pattern: pattern, wrapsOptional: wrapsOptional, location: AutoUpdatingRange(range: index ... index, formatter: formatter),
            scope: AutoUpdatingRange(range: scope, formatter: formatter), type: type,
            value: value.map { AutoUpdatingRange(range: $0, formatter: formatter) }, tuplePath: tuplePath, namespace: namespace,
            unwrapsOptional: unwrapsOptional, requiresPrecedingDeclaration: requiresPrecedingDeclaration, isGlobal: isGlobal,
            typeRequiresGenericArguments: typeRequiresGenericArguments,
            excludedScope: excludedScope.map { AutoUpdatingRange(range: $0, formatter: formatter) }
        ))
    }

    private func addGenericContext(_ parameters: [Formatter.GenericType], whereClause: Int?, scope: ClosedRange<Int>, namespace: String?) {
        var generics = parameters
        if let whereClause {
            formatter.parseGenericTypes(from: whereClause, into: &generics)
        }
        let requirements = generics.flatMap(\.conformances).flatMap(\.indexedRequirements)
        if !requirements.isEmpty {
            genericContexts.append(GenericContext(scope: AutoUpdatingRange(range: scope, formatter: formatter),
                                                  namespace: namespace, requirements: requirements))
        }
    }

    /// A same-type requirement is usable only in its lexical scope. Resolve each target
    /// where the requirement was written, so nested scopes cannot capture its type names.
    private func lexicalEqualityType(named name: String, scope: AutoUpdatingRange, at index: Int, depth: Int) -> ResolvedType? {
        guard depth < 16, let root = name.split(separator: ".").first else { return nil }
        let query = RequirementQuery(scope: ObjectIdentifier(scope), name: name)
        guard activeRequirements.insert(query).inserted else { return nil }
        defer { activeRequirements.remove(query) }
        var result: ResolvedType?
        for context in genericContexts where context.scope.range.contains(index) {
            let declarationIndex = context.scope.range.lowerBound
            guard unavailableTypes[String(root)]?.filter({ $0.range.contains(declarationIndex) })
                .min(by: { $0.range.count < $1.range.count }) === scope else { continue }
            for requirement in context.requirements where requirement.isSameType {
                let target: String
                if requirement.subject == name {
                    target = requirement.target
                } else if requirement.target == name {
                    target = requirement.subject
                } else {
                    continue
                }
                var resolved: ResolvedType?
                if let reference = ProjectTypeReference(target), reference.arguments.isEmpty,
                   let root = reference.name.split(separator: ".").first,
                   let targetScope = unavailableTypes[String(root)]?.filter({ $0.range.contains(declarationIndex) })
                       .min(by: { $0.range.count < $1.range.count }),
                   genericParameterScopes[String(root)]?.contains(where: { $0 === targetScope }) == true
                {
                    // Generic paths keep their declaration identity but can use additional
                    // requirements that are visible at the original expression.
                    resolved = lexicalEqualityType(named: target, scope: targetScope, at: index, depth: depth + 1)
                }
                guard let resolved = resolved ?? type(named: target, namespace: context.namespace, at: declarationIndex,
                                                      requiresGenericArguments: true, depth: depth + 1),
                    !resolved.isAbstract else { continue }
                guard result == nil || sameType(result!, as: resolved) else { return nil }
                result = resolved
            }
        }
        return result
    }

    /// Bounds belong to the generic declaration, while refinements belong to the use site.
    /// Keep both so a constrained receiver never becomes an unrelated nominal namesake.
    private func abstractGenericType(named name: String, scope: AutoUpdatingRange, at index: Int, depth: Int) -> ResolvedType {
        var bounds = [ResolvedType]()
        var complete = depth < 16
        for context in genericContexts where context.scope.range.contains(index) {
            let declarationIndex = context.scope.range.lowerBound
            guard unavailableTypes[name]?.filter({ $0.range.contains(declarationIndex) })
                .min(by: { $0.range.count < $1.range.count }) === scope else { continue }
            for requirement in context.requirements where !requirement.isSameType && requirement.subject == name {
                if let resolved = protocolBounds(named: requirement.target, namespace: context.namespace,
                                                 at: declarationIndex, depth: depth + 1)
                {
                    bounds.append(contentsOf: resolved)
                } else {
                    complete = false
                }
            }
        }
        return ResolvedType(name: name, sourceFileURL: fileURL, genericBounds: complete ? bounds : nil,
                            genericParameterScope: scope, genericUseSite: AutoUpdatingRange(range: index ... index, formatter: formatter))
    }

    /// Resolve every component in its declaration context. A missing bound can contain a
    /// competing member, so partial resolution cannot establish a usable abstract receiver.
    private func protocolBounds(named spelling: String, namespace: String?, at index: Int?, sourceFileURL: URL? = nil,
                                substitutions: [String: ResolvedType] = [:], depth: Int) -> [ResolvedType]?
    {
        guard depth < 16, let names = Formatter(tokenize(spelling)).indexedProtocolBounds() else { return nil }
        var bounds = [ResolvedType]()
        for name in names {
            guard let bound = type(named: name, namespace: namespace, at: index, sourceFileURL: sourceFileURL,
                                   substitutions: substitutions, requiresGenericArguments: true, depth: depth + 1) else { return nil }
            if bound.isAbstractProtocol, let nested = bound.genericBounds {
                bounds.append(contentsOf: nested)
            } else {
                guard let nominal = qualifiedName(for: bound),
                      project.isProtocolDeclaration(named: nominal, visibleFrom: bound.sourceFileURL ?? fileURL) ||
                      project.typeDeclaration(named: nominal, visibleFrom: bound.sourceFileURL ?? fileURL)?.kind == "class" else { return nil }
                bounds.append(bound)
            }
        }
        return bounds
    }

    /// A binding's generic identity comes from its annotation; visible constraints come from
    /// the expression using it. Refresh structural arguments without rebinding their names.
    private func typeAtUseSite(_ value: ResolvedType, at index: Int, depth: Int) -> ResolvedType {
        guard depth < 16 else { return value }
        var result = value
        if let scope = value.genericParameterScope {
            let optional = unwrapped(value)
            let name = optional?.name ?? value.name
            if var concrete = lexicalEqualityType(named: name, scope: scope, at: index, depth: depth + 1) {
                concrete.isMetatype = value.isMetatype
                if optional != nil {
                    concrete.name += String(value.name.suffix(1))
                }
                return concrete
            }
            result = abstractGenericType(named: name, scope: scope, at: index, depth: depth + 1)
            result.isMetatype = value.isMetatype
            if optional != nil {
                result.name += String(value.name.suffix(1))
            }
        }
        result.genericArguments = result.genericArguments?.map { typeAtUseSite($0, at: index, depth: depth + 1) }
        result.genericBounds = result.genericBounds?.map { typeAtUseSite($0, at: index, depth: depth + 1) }
        result.tupleElements = result.tupleElements?.map { TupleElement(label: $0.label, type: typeAtUseSite($0.type, at: index, depth: depth + 1)) }
        if let signature = result.functionType {
            result.functionType = FunctionType(parameters: signature.parameters.map { typeAtUseSite($0, at: index, depth: depth + 1) },
                                               result: typeAtUseSite(signature.result, at: index, depth: depth + 1), qualifiers: signature.qualifiers, requiresArgumentProof: signature.requiresArgumentProof)
        }
        if let enclosing = result.enclosingType {
            result.enclosingType = EnclosingType(typeAtUseSite(enclosing.type, at: index, depth: depth + 1))
        }
        return result
    }

    /// Resolve an annotated type in its declaration's lexical namespace, including aliases.
    func type(named rawName: String, namespace: String?, at index: Int? = nil, sourceFileURL: URL? = nil, substitutions: [String: ResolvedType] = [:], requiresGenericArguments: Bool = false, depth: Int = 0) -> ResolvedType? {
        guard depth < 16 else { return nil }
        let isLocalReference = sourceFileURL == nil || sourceFileURL?.standardizedFileURL == fileURL.standardizedFileURL
        let prefixTokens = tokenize(rawName).filter { !$0.isSpaceOrCommentOrLinebreak }
            .drop(while: { ["inout", "borrowing", "consuming", "sending"].contains($0.string) })
        let isOpaque = prefixTokens.first?.string == "some"
        let tokens = prefixTokens.drop(while: { ["any", "some"].contains($0.string) })
        // Nested type prefixes still need a word boundary after whitespace normalization.
        let prefixes = Set(["any", "some", "inout", "borrowing", "consuming", "sending", "async", "throws", "rethrows", "repeat", "each"])
        let name = tokens.map { $0.string + (prefixes.contains($0.string) ? " " : "") }.joined()
        let optional = name.hasSuffix("?") || name.hasSuffix("!")
        let base = optional ? String(name.dropLast()) : name
        if var substitution = substitutions[base] {
            if base == "Self" {
                substitution.isMetatype = false
            }
            if optional {
                substitution.name += "?"
            }
            return substitution
        }
        if base == "Self", let namespace,
           project.typeDeclaration(named: namespace, visibleFrom: sourceFileURL ?? fileURL)?.enumCases != nil ||
           localTypes[namespace]?.contains(where: { $0.keyword == "enum" }) == true
        {
            return type(named: namespace + (optional ? "?" : ""), namespace: nil, at: index,
                        sourceFileURL: sourceFileURL, substitutions: substitutions, depth: depth + 1)
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
        // Generic arguments may remain abstract while the surrounding nominal declaration is
        // known. Keep the parameter's lexical identity so it cannot become a namesake type.
        if let index, sourceFileURL == nil || sourceFileURL?.standardizedFileURL == fileURL.standardizedFileURL,
           let reference = ProjectTypeReference(base), let root = reference.name.split(separator: ".").first,
           let scope = unavailableTypes[String(root)]?.filter({ $0.range.contains(index) }).min(by: { $0.range.count < $1.range.count })
        {
            guard genericParameterScopes[String(root)]?.contains(where: { $0 === scope }) == true else { return nil }
            var value = lexicalEqualityType(named: base, scope: scope, at: index, depth: depth + 1)
            if value == nil, base != root, reference.arguments.isEmpty, let parent = reference.parent, let member = reference.member,
               let owner = type(named: parent, namespace: namespace, at: index, substitutions: substitutions, depth: depth + 1)
            {
                value = dependentMemberType(member, of: owner, depth: depth + 1)
            }
            if var value {
                if optional {
                    value.name += "?"
                }
                return value
            }
            guard base == root else { return nil }
            var result = abstractGenericType(named: base, scope: scope, at: index, depth: depth + 1)
            if optional {
                result.name += String(name.suffix(1))
            }
            return result
        }
        if let dot = base.firstIndex(of: "."), let owner = substitutions[String(base[..<dot])] {
            guard var value = dependentMemberType(String(base[base.index(after: dot)...]), of: owner, depth: depth + 1) else { return nil }
            if optional {
                value.name += "?"
            }
            return value
        }
        if let namespace, let owner = substitutions["Self"],
           let reference = ProjectTypeReference(base), reference.arguments.isEmpty,
           let root = reference.name.split(separator: ".").first,
           project.associatedTypeRequirements(named: String(root), of: namespace, visibleFrom: sourceFileURL ?? fileURL) != nil
        {
            guard var value = dependentMemberType(base, of: owner, depth: depth + 1) else { return nil }
            if optional {
                value.name += "?"
            }
            return value
        }
        // Opaque types and protocol compositions expose the same indexed bounds as named
        // generics. They never acquire a nominal identity or an invented associated witness.
        if isOpaque || Formatter(tokenize(base)).index(of: .operator("&", .infix), after: -1) != nil {
            guard let bounds = protocolBounds(named: base, namespace: namespace, at: index,
                                              sourceFileURL: sourceFileURL, substitutions: substitutions, depth: depth + 1),
                !bounds.isEmpty else { return nil }
            return ResolvedType(name: name, sourceFileURL: sourceFileURL, genericBounds: bounds, isAbstractProtocol: true)
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
                    func conventions(in range: Range<Int>) -> String {
                        signature.tokens[range].filter { !$0.isSpaceOrCommentOrLinebreak }
                            .prefix { ["inout", "borrowing", "consuming", "sending", "isolated", "__shared", "__owned"].contains($0.string) }.string
                    }
                    // Equality requires the same effects and ownership conventions, even when
                    // the parameter and result types themselves have the same nominal identity.
                    let qualifiers = [signature.tokens[..<open].filter { !$0.isSpaceOrCommentOrLinebreak }.string,
                                      signature.tokens[close + 1 ..< arrow].filter { !$0.isSpaceOrCommentOrLinebreak }.string] +
                        parameters.map { conventions(in: Range($0.valueRange)) } + [conventions(in: arrow + 1 ..< signature.tokens.count)]
                    functionType = FunctionType(parameters: resolved, result: result, qualifiers: qualifiers)
                }
            }
            // A result's optional suffix belongs to the result, not to the function value.
            return ResolvedType(name: functionType == nil ? name : "(" + name + ")", namespace: namespace,
                                sourceFileURL: sourceFileURL, functionType: functionType)
        }

        if nominal.hasGenericParent {
            guard var nested = nestedType(nominal, namespace: namespace, at: index, sourceFileURL: sourceFileURL,
                                          substitutions: substitutions, depth: depth + 1) else { return nil }
            if optional {
                nested.name += "?"
            }
            return nested
        }
        guard let lexical = qualifiedTypeName(for: ResolvedType(name: base, namespace: namespace, sourceFileURL: sourceFileURL)) else { return nil }
        if nominal.arguments.isEmpty, !nominal.hasGenericParent, lexical.name == namespace,
           let owner = substitutions["Self"],
           var projected = projectedType(owner, to: lexical.name, source: lexical.sourceFileURL ?? sourceFileURL ?? fileURL, depth: depth + 1),
           projected.genericArguments?.isEmpty == false
        {
            projected.isMetatype = false
            if optional {
                projected.name += "?"
            }
            return projected
        }
        var argumentNames = nominal.arguments
        var arguments: [ResolvedType]
        if argumentNames.isEmpty, let index,
           sourceFileURL == nil || sourceFileURL?.standardizedFileURL == fileURL.standardizedFileURL,
           let scope = genericTypeScopes[lexical.name]?.filter({ $0.range.range.contains(index) }).min(by: { $0.range.range.count < $1.range.range.count })
        {
            // A bare reference to the enclosing generic type denotes its current specialization.
            // Bind its own parameters, even when a nested function shadows their spellings.
            argumentNames = scope.parameters
            arguments = scope.parameters.map {
                abstractGenericType(named: $0, scope: scope.range, at: index, depth: depth + 1)
            }
        } else {
            arguments = argumentNames.compactMap {
                type(named: $0, namespace: namespace, at: index, sourceFileURL: sourceFileURL, substitutions: substitutions, requiresGenericArguments: true, depth: depth + 1)
            }
        }
        guard arguments.count == argumentNames.count else { return nil }
        let lexicalName = lexical.name
        let lexicalSource = lexical.sourceFileURL ?? sourceFileURL
        // An alias can appear in the middle of a qualified path, including an extension's
        // lexical owner. Resolve its members using the target's original declaration context.
        if nominal.arguments.isEmpty, !nominal.hasGenericParent,
           !project.hasSymbolType(named: lexicalName, visibleFrom: lexicalSource ?? fileURL)
        {
            let components = lexicalName.split(separator: ".")
            for position in components.indices.dropFirst().reversed() {
                let prefix = components[..<position].joined(separator: ".")
                guard let alias = project.typeAlias(named: prefix, visibleFrom: lexicalSource ?? fileURL),
                      alias.genericParameters.isEmpty else { continue }
                guard let owner = type(named: prefix, namespace: nil, at: index, sourceFileURL: lexicalSource,
                                       substitutions: substitutions, depth: depth + 1),
                    var result = dependentMemberType(components[position...].joined(separator: "."), of: owner, depth: depth + 1)
                else { return nil }
                if optional {
                    result.name += "?"
                }
                return result
            }
        }
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
            let identity = (sourceFileURL ?? fileURL).standardizedFileURL.path + ":" + qualified
            guard activeAliases.insert(identity).inserted else { return nil }
            defer { activeAliases.remove(identity) }
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
        let argumentsSuffix = argumentNames.isEmpty ? "" : "<" + argumentNames.joined(separator: ",") + ">"
        var result = ResolvedType(name: qualified + argumentsSuffix + (optional ? String(name.suffix(1)) : ""), namespace: nil, sourceFileURL: sourceFileURL, genericArguments: arguments)
        if let dot = qualified.lastIndex(of: ".") {
            let parentName = String(qualified[..<dot])
            let source = sourceFileURL ?? fileURL
            if let parentDeclaration = project.typeDeclaration(named: parentName, visibleFrom: source), parentDeclaration.isGeneric {
                // The parent owns a separate specialization. Its parameters must not be
                // counted as arguments of the nested type, or lost when resolving members.
                guard let owner = enclosingGenericType(named: parentName, declaration: parentDeclaration,
                                                       at: isLocalReference ? index : nil, source: source,
                                                       substitutions: substitutions, depth: depth + 1) else { return nil }
                result.enclosingType = EnclosingType(owner)
            }
        }
        return result
    }

    /// Arguments written on the nested member belong to the caller's lexical context;
    /// its declaration and inherited parent specialization belong to the parent's context.
    private func nestedType(_ reference: ProjectTypeReference, namespace: String?, at index: Int?,
                            sourceFileURL: URL?, substitutions: [String: ResolvedType], depth: Int) -> ResolvedType?
    {
        guard depth < 16, let parent = reference.parent, let member = reference.member,
              let memberType = ProjectTypeReference(member),
              let owner = type(named: parent, namespace: namespace, at: index, sourceFileURL: sourceFileURL,
                               substitutions: substitutions, requiresGenericArguments: true, depth: depth + 1),
              let ownerName = qualifiedName(for: owner), var context = nominalSubstitutions(for: owner) else { return nil }
        let arguments = memberType.arguments.compactMap {
            type(named: $0, namespace: namespace, at: index, sourceFileURL: sourceFileURL,
                 substitutions: substitutions, requiresGenericArguments: true, depth: depth + 1)
        }
        guard arguments.count == memberType.arguments.count else { return nil }
        let placeholders = arguments.indices.map { "$nestedArgument" + String($0) }
        for (key, argument) in zip(placeholders, arguments) {
            context[key] = argument
        }
        let suffix = placeholders.isEmpty ? "" : "<" + placeholders.joined(separator: ",") + ">"
        let name = ownerName + "." + memberType.name
        guard var nested = type(named: name + suffix, namespace: ownerName, at: index,
                                sourceFileURL: owner.sourceFileURL ?? sourceFileURL,
                                substitutions: context, requiresGenericArguments: true, depth: depth + 1) else { return nil }
        if project.typeDeclaration(named: name, visibleFrom: owner.sourceFileURL ?? fileURL) != nil {
            nested.name = name + (arguments.isEmpty ? "" : "<" + arguments.map(\.name).joined(separator: ",") + ">")
        }
        return nested
    }

    private func enclosingGenericType(named name: String, declaration: SourceFileIndex.TypeDeclaration,
                                      at index: Int?, source: URL, substitutions: [String: ResolvedType], depth: Int) -> ResolvedType?
    {
        guard depth < 16 else { return nil }
        var owner = substitutions["Self"]
        let identity = project.typeIdentity(named: name, visibleFrom: source)
        while let candidate = owner {
            if let name = qualifiedName(for: candidate), let identity,
               project.typeIdentity(named: name, visibleFrom: candidate.sourceFileURL ?? fileURL) == identity
            {
                break
            }
            owner = candidate.enclosingType?.type
        }
        if owner == nil, let index {
            owner = type(named: name, namespace: nil, at: index, substitutions: substitutions,
                         requiresGenericArguments: true, depth: depth + 1)
        }
        if owner == nil, !declaration.genericParameters.isEmpty,
           declaration.genericParameters.allSatisfy({ substitutions[$0] != nil })
        {
            owner = type(named: name + "<" + declaration.genericParameters.joined(separator: ",") + ">",
                         namespace: nil, sourceFileURL: source, substitutions: substitutions,
                         requiresGenericArguments: true, depth: depth + 1)
        }
        guard let owner, nominalSubstitutions(for: owner) != nil else { return nil }
        return owner
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
        guard !type.isAbstract, let nominal = ProjectTypeReference(type.name) else { return nil }
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
        if let scope = lhs.genericParameterScope {
            return scope === rhs.genericParameterScope && lhs.name == rhs.name && lhs.sourceFileURL == rhs.sourceFileURL
        }
        guard !lhs.isAbstract, !rhs.isAbstract else { return false }
        if let kind = lhs.collectionKind {
            guard kind == rhs.collectionKind, let left = lhs.genericArguments, let right = rhs.genericArguments,
                  left.count == right.count else { return false }
            return zip(left, right).allSatisfy { sameType($0, as: $1) }
        }
        if let left = lhs.tupleElements, let right = rhs.tupleElements {
            return left.count == right.count && zip(left, right).allSatisfy { $0.label == $1.label && sameType($0.type, as: $1.type) }
        }
        if let left = lhs.functionType, let right = rhs.functionType {
            return left.qualifiers == right.qualifiers && left.parameters.count == right.parameters.count &&
                zip(left.parameters, right.parameters).allSatisfy { sameType($0, as: $1) } && sameType(left.result, as: right.result)
        }
        if let left = standardScalarName(lhs), let right = standardScalarName(rhs) {
            return left == right
        }
        guard let left = qualifiedName(for: lhs), let right = qualifiedName(for: rhs),
              let identity = project.typeIdentity(named: left, visibleFrom: lhs.sourceFileURL ?? fileURL),
              identity == project.typeIdentity(named: right, visibleFrom: rhs.sourceFileURL ?? fileURL) else { return false }
        if let parent = lhs.enclosingType {
            guard let other = rhs.enclosingType, sameType(parent.type, as: other.type) else { return false }
        } else if rhs.enclosingType != nil {
            return false
        }
        let leftArguments = lhs.genericArguments ?? []
        let rightArguments = rhs.genericArguments ?? []
        return leftArguments.count == rightArguments.count && zip(leftArguments, rightArguments).allSatisfy { sameType($0, as: $1) }
    }

    /// Local functions are hoisted within their lexical scope, including before their declaration.
    func hasLocalFunction(named name: String, at index: Int) -> Bool {
        localFunctionScopes[name.replacingOccurrences(of: "`", with: "")]?.contains { $0.range.contains(index) } == true
    }

    /// Resolve a bare enum case in its declaration's scope without mistaking a local value for it.
    func unqualifiedEnumCase(named name: String, at index: Int) -> (name: String, type: ResolvedType, payloadTypes: [String])? {
        let name = name.replacingOccurrences(of: "`", with: "")
        let spellings = [name, "`\(name)`"]
        guard spellings.allSatisfy({ spelling in
                  !hasLocalFunction(named: spelling, at: index) &&
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
        guard depth < 32, !hasLocalFunction(named: name, at: index),
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
            if var receiver = type(named: owner, namespace: nil, at: index) {
                receiver.isMetatype = isStatic
                if let member = memberType(owner: receiver, name: name, accessingType: enclosingType) {
                    return member
                }
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
            let identity = ObjectIdentifier(binding.location)
            guard activeBindings.insert(identity).inserted else { return nil }
            defer { activeBindings.remove(identity) }
            var result: ResolvedType?
            var tuplePath = binding.tuplePath
            if let annotation = binding.type {
                result = type(named: annotation, namespace: binding.namespace, at: binding.location.range.lowerBound, requiresGenericArguments: binding.typeRequiresGenericArguments)
            } else if let value = binding.value {
                result = expressionType(in: value.range, projecting: tuplePath, depth: depth + 1)
                tuplePath = []
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
            for position in tuplePath {
                result = result.flatMap { memberType(owner: $0, name: String(position)) }
            }
            if binding.wrapsOptional, let current = result, !current.name.hasSuffix("?") {
                result?.name += "?"
            }
            if binding.unwrapsOptional, binding.type == nil, let current = result {
                result = unwrapped(current)
            }
            return result.map { typeAtUseSite($0, at: index, depth: depth + 1) }
        }
        guard let owner = enclosingType.flatMap({ type(named: $0, namespace: nil, at: index) }) else { return nil }
        return memberType(owner: owner, name: name, accessingType: enclosingType)
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
        guard depth < 16 else { return nil }
        if owner.isAbstract {
            guard let bounds = owner.genericBounds else { return nil }
            var result: ResolvedType?
            for bound in bounds {
                guard let candidate = projectedType(bound, to: name, source: source, depth: depth + 1) else { continue }
                guard result == nil || sameType(result!, as: candidate) else { return nil }
                result = candidate
            }
            return result
        }
        guard let ownerName = qualifiedName(for: owner),
              let identity = project.typeIdentity(named: ownerName, visibleFrom: owner.sourceFileURL ?? fileURL) else { return nil }
        let target: Set<String>
        if project.typeDeclaration(named: name, visibleFrom: source) != nil,
           let nominalIdentity = project.typeIdentity(named: name, visibleFrom: source)
        {
            // Projection needs declaration identity, not an unspecialized instance of a
            // nested generic type. Aliases still resolve in their declaration context.
            target = nominalIdentity
        } else {
            guard let targetType = type(named: name, namespace: nil, sourceFileURL: source, depth: depth + 1),
                  let targetName = qualifiedName(for: targetType),
                  let targetIdentity = project.typeIdentity(named: targetName, visibleFrom: targetType.sourceFileURL ?? source) else { return nil }
            target = targetIdentity
        }
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
        var result: [String: ResolvedType] = [:]
        if let parent = owner.enclosingType {
            guard let context = nominalSubstitutions(for: parent.type) else { return nil }
            result = context
        }
        for (name, argument) in zip(declaration.genericParameters, owner.genericArguments ?? []) {
            result[name] = argument
        }
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
        guard depth < 16, !owner.isMetatype, unwrapped(owner) == nil else { return nil }
        if let scope = owner.genericParameterScope, let index = owner.genericUseSite?.range.lowerBound {
            let components = path.split(separator: ".")
            for end in components.indices.reversed() {
                let prefix = components[...end].joined(separator: ".")
                guard let value = lexicalEqualityType(named: owner.name + "." + prefix, scope: scope, at: index, depth: depth + 1) else { continue }
                let remaining = components.suffix(from: end + 1).joined(separator: ".")
                return remaining.isEmpty ? value : dependentMemberType(remaining, of: value, depth: depth + 1)
            }
        }
        if owner.isAbstract {
            return abstractAssociatedType(path, owner: owner, depth: depth + 1)
        }
        guard let reference = ProjectTypeReference(path), reference.arguments.isEmpty,
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

    /// An associated type can be concrete even when its receiver is abstract: every conformer
    /// must satisfy its protocol's same-type requirements, including inherited refinements.
    private func abstractAssociatedType(_ path: String, owner: ResolvedType, depth: Int) -> ResolvedType? {
        guard depth < 16, let bounds = owner.genericBounds,
              let member = path.split(separator: ".").first else { return nil }
        var values = [ResolvedType]()
        func collect(_ bound: ResolvedType, depth: Int) -> Bool {
            guard depth < 16, let name = qualifiedName(for: bound),
                  let requirements = project.genericTypeRequirements(of: name, visibleFrom: bound.sourceFileURL ?? fileURL),
                  let parents = project.inheritedTypeReferences(owner: name, visibleFrom: bound.sourceFileURL ?? fileURL),
                  var substitutions = nominalSubstitutions(for: bound) else { return false }
            substitutions["Self"] = owner
            if project.associatedTypeRequirements(named: String(member), of: name, visibleFrom: bound.sourceFileURL ?? fileURL) != nil {
                for entry in requirements where entry.requirement.isSameType {
                    let equality = entry.requirement
                    for (subject, target) in [(equality.subject, equality.target), (equality.target, equality.subject)]
                        where subject == member || subject == "Self." + member
                    {
                        if let value = type(named: target, namespace: entry.owner, sourceFileURL: entry.fileURL,
                                            substitutions: substitutions, requiresGenericArguments: true, depth: depth + 1), !value.isAbstract
                        {
                            values.append(value)
                        }
                    }
                }
            }
            for parent in parents {
                guard let inherited = type(named: parent.name, namespace: parent.namespace, sourceFileURL: parent.fileURL,
                                           substitutions: substitutions, requiresGenericArguments: true, depth: depth + 1),
                    collect(inherited, depth: depth + 1) else { return false }
            }
            return true
        }
        guard bounds.allSatisfy({ collect($0, depth: depth + 1) }), let value = values.first,
              values.dropFirst().allSatisfy({ sameType(value, as: $0) }) else { return nil }
        let remaining = path.split(separator: ".").dropFirst().joined(separator: ".")
        return remaining.isEmpty ? value : dependentMemberType(remaining, of: value, depth: depth + 1)
    }

    func memberType(owner: ResolvedType, name: String, accessingType: String? = nil, accessedFrom: URL? = nil, depth: Int = 0) -> ResolvedType? {
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
        if owner.isAbstract {
            guard unwrapped(owner) == nil, let bounds = owner.genericBounds else { return nil }
            var result: ResolvedType?
            for bound in bounds {
                guard let boundName = qualifiedName(for: bound) else { return nil }
                guard project.hasProperty(owner: boundName, member: name, visibleFrom: bound.sourceFileURL ?? fileURL, accessedFrom: accessedFrom ?? fileURL) else { continue }
                guard let member = project.propertySymbol(owner: boundName, member: name, isStatic: owner.isMetatype,
                                                          visibleFrom: bound.sourceFileURL ?? fileURL, accessedFrom: accessedFrom ?? fileURL, accessedFromType: accessingType),
                    let value = propertyType(member, owner: owner, depth: depth + 1),
                    result == nil || sameType(result!, as: value) else { return nil }
                result = value
            }
            return result.map { callablePropertyType($0, owner: owner, member: name, accessingType: accessingType, accessedFrom: accessedFrom ?? fileURL) }
        }
        guard let ownerName = qualifiedName(for: owner),
              let member = project.propertySymbol(owner: ownerName, member: name, isStatic: owner.isMetatype, visibleFrom: owner.sourceFileURL ?? fileURL, accessedFrom: accessedFrom ?? fileURL, accessedFromType: accessingType),
              let value = propertyType(member, owner: owner, depth: depth + 1) else { return nil }
        return callablePropertyType(value, owner: owner, member: name, accessingType: accessingType, accessedFrom: accessedFrom ?? fileURL)
    }

    /// Parentheses and inferred bindings retain the need to distinguish a property from methods.
    private func callablePropertyType(_ value: ResolvedType, owner: ResolvedType, member: String,
                                      accessingType: String?, accessedFrom caller: URL) -> ResolvedType
    {
        guard let signature = value.functionType else { return value }
        let methodsAreAbsent = (owner.genericBounds ?? [owner]).allSatisfy { bound in
            guard let name = qualifiedName(for: bound) else { return false }
            return project.memberFunctionIsAbsent(named: member, owner: name, visibleFrom: bound.sourceFileURL ?? fileURL,
                                                  accessedFrom: caller, accessedFromType: accessingType)
        }
        guard !methodsAreAbsent else { return value }
        var result = value
        result.functionType = FunctionType(parameters: signature.parameters, result: signature.result, qualifiers: signature.qualifiers, requiresArgumentProof: true)
        return result
    }

    private func propertyType(_ member: ProjectIndex.PropertySymbol, owner: ResolvedType, depth: Int) -> ResolvedType? {
        guard depth < 16,
              let declaringOwner = projectedType(owner, to: member.declaration.declaringType, source: member.fileURL, depth: depth + 1),
              var substitutions = nominalSubstitutions(for: declaringOwner) else { return nil }
        substitutions["Self"] = owner
        if let annotation = member.declaration.type {
            return type(named: annotation, namespace: member.declaration.declaringType, sourceFileURL: member.fileURL, substitutions: substitutions, depth: depth + 1)
        }
        guard let initializer = member.declaration.initializer else { return nil }
        return explicitInitializerType(initializer, namespace: member.declaration.declaringType, source: member.fileURL, substitutions: substitutions, depth: depth + 1)
    }

    /// An explicit constructor or indexed static member determines a stored value's type without
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
                guard expression.tokens[first] == .startOfScope("[") || initializerRootIsUnshadowed(annotation.string, namespace: namespace, source: source),
                      !project.hasCollectionMember(named: "init", kind: kind.rawValue, visibleFrom: source) else { return nil }
                return result
            }
            guard initializerRootIsUnshadowed(annotation.string, namespace: namespace, source: source), let name = qualifiedName(for: result),
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
        guard initializerRootIsUnshadowed(root, namespace: namespace, source: source),
              let result = type(named: root, namespace: namespace, sourceFileURL: source, substitutions: substitutions, requiresGenericArguments: true, depth: depth + 1),
              unwrapped(result) == nil, let name = qualifiedName(for: result) else { return nil }
        var receiver = result
        receiver.isMetatype = true
        if let property = memberType(owner: receiver, name: expression.tokens[last].string, accessingType: namespace, accessedFrom: source, depth: depth + 1) {
            return property
        }
        guard let declaration = project.typeDeclaration(named: name, visibleFrom: result.sourceFileURL ?? source),
              declaration.enumCasePayloads?[expression.tokens[last].string] == [],
              !project.hasProperty(owner: name, member: expression.tokens[last].string, visibleFrom: result.sourceFileURL ?? source, accessedFrom: source) else { return nil }
        return result
    }

    /// Check the expression's actual path, rather than every namesake in the project.
    /// Alias targets are type annotations and do not introduce additional value lookups.
    func initializerRootIsUnshadowed(_ spelling: String, namespace: String? = nil, source: URL? = nil) -> Bool {
        let source = source ?? fileURL
        guard let reference = ProjectTypeReference(spelling) else { return false }
        if let parent = reference.parent, let member = reference.member.flatMap(ProjectTypeReference.init) {
            guard initializerRootIsUnshadowed(parent, namespace: namespace, source: source) else { return false }
            if project.isModuleNamespace(parent, visibleFrom: source) {
                return project.globalValueIsAbsent(named: member.name, inModule: parent, visibleFrom: source)
            }
            guard let owner = type(named: parent, namespace: namespace, sourceFileURL: source),
                  let name = qualifiedName(for: owner) else { return false }
            return project.constructorRootIsUnshadowed(member.name, in: name, visibleFrom: owner.sourceFileURL ?? source,
                                                       accessedFrom: source, accessedFromType: namespace)
        }
        guard project.globalValueIsAbsent(named: reference.name, visibleFrom: source) else { return false }
        var namespace = namespace
        while let owner = namespace, !project.isModuleNamespace(owner, visibleFrom: source) {
            guard project.constructorRootIsUnshadowed(reference.name, in: owner, visibleFrom: source) else { return false }
            namespace = owner.contains(".") ? owner.split(separator: ".").dropLast().joined(separator: ".") : nil
        }
        return true
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
              let declaration = project.typeDeclaration(named: ownerName, visibleFrom: owner.sourceFileURL ?? fileURL),
              let payloads = declaration.enumCasePayloads?[caseName], payloads.indices.contains(position),
              let source = project.typeSourceFile(named: ownerName, visibleFrom: owner.sourceFileURL ?? fileURL),
              let substitutions = nominalSubstitutions(for: owner) else { return nil }
        return type(named: payloads[position], namespace: declaration.name, sourceFileURL: source, substitutions: substitutions)
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
        func infer(_ raw: String, from value: ResolvedType) -> Bool {
            let missing = names.subtracting(substitutions.keys)
            guard !missing.isEmpty else { return false }
            let placeholders = substitutions.merging(Dictionary(uniqueKeysWithValues: missing.map {
                ($0, ResolvedType(name: "$generic:" + $0))
            })) { _, generic in generic }
            guard let pattern = type(named: raw, namespace: symbol.declaration.declaringType, sourceFileURL: symbol.fileURL,
                                     substitutions: placeholders, requiresGenericArguments: true) else { return false }
            // Matching may bind several variables before a later component conflicts. Commit
            // substitutions only after the entire equality has matched successfully.
            var inferred = substitutions
            guard matchGenericType(pattern, to: value, genericNames: missing, source: symbol.fileURL, bind: { name, value, _ in
                if let previous = inferred[name], !sameType(previous, as: value) {
                    return false
                }
                inferred[name] = value
                return true
            }), inferred.count > substitutions.count else { return false }
            substitutions = inferred
            return true
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
                } else if let lhs, infer(requirement.target, from: lhs) {
                    changed = true
                } else if let rhs, infer(requirement.subject, from: rhs) {
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
        if unwrapped(value) == nil, value.isMetatype, parameter.isMetatype {
            var actual = value
            var formal = parameter
            actual.isMetatype = false
            formal.isMetatype = false
            return argumentIsIncompatible(actual, with: formal)
        }
        if let actual = value.tupleElements, let formal = parameter.tupleElements,
           unwrapped(value) == nil, !value.isMetatype, !parameter.isMetatype
        {
            return actual.count != formal.count || zip(actual, formal).contains { argumentIsIncompatible($0.type, with: $1.type) }
        }
        if let kind = value.collectionKind, kind == parameter.collectionKind,
           unwrapped(value) == nil, !value.isMetatype, !parameter.isMetatype,
           let actual = value.genericArguments, let formal = parameter.genericArguments, actual.count == formal.count
        {
            return zip(actual, formal).contains { argumentIsIncompatible($0, with: $1) }
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
            if let parent = value.enclosingType, let other = parameter.enclosingType,
               argumentIsIncompatible(parent.type, with: other.type)
            {
                return true
            }
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
        if let owner {
            substitutions["Self"] = owner
        }
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
            // An invariant project wrapper fixes its generic arguments, including through
            // aliases and nested tuple/collection structure. Never retain a partial match.
            let missing = unknown.subtracting(substitutions.keys)
            if !missing.isEmpty {
                let placeholders = substitutions.merging(Dictionary(uniqueKeysWithValues: missing.map {
                    ($0, ResolvedType(name: "$generic:" + $0))
                })) { _, placeholder in placeholder }
                if let pattern = type(named: raw, namespace: symbol.declaration.declaringType, sourceFileURL: symbol.fileURL,
                                      substitutions: placeholders, requiresGenericArguments: true)
                {
                    var inferred = substitutions
                    if matchGenericType(pattern, to: value, genericNames: missing, source: symbol.fileURL, bind: { name, value, invariant in
                        if invariant {
                            if let previous = inferred[name], !self.sameType(previous, as: value) {
                                return false
                            }
                            inferred[name] = value
                        }
                        return true
                    }) {
                        substitutions = inferred
                    }
                }
            }
            guard !tokenize(raw).contains(where: { unknown.contains($0.string) && substitutions[$0.string] == nil }),
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
            // These expressions borrow parameter context; using it to select that parameter cycles.
            guard argumentHasIndependentRoot(in: argument.valueRange, depth: depth + 1) else { continue }
            result[position] = expressionType(in: argument.valueRange, depth: depth + 1)
        }
        return result
    }

    private func argumentHasIndependentRoot(in range: ClosedRange<Int>, depth: Int) -> Bool {
        guard depth < 32,
              let first = formatter.index(of: .nonSpaceOrCommentOrLinebreak, in: Range(range)),
              let last = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: range.upperBound + 1) else { return false }
        let token = formatter.tokens[first]
        if token == .startOfScope("("), formatter.endOfScope(at: first) == last {
            let arguments = formatter.parseTupleArguments(startOfScope: first)
            return !arguments.isEmpty && arguments.allSatisfy { argumentHasIndependentRoot(in: $0.valueRange, depth: depth + 1) }
        }
        return token.isIdentifier || token == .keyword("self") || token == .keyword("Self")
    }

    /// Match type structure without choosing conversions. The caller decides how to retain
    /// inferred variables and whether an invariant path fixes their eventual specialization.
    func matchGenericType(_ pattern: ResolvedType, to value: ResolvedType, genericNames: Set<String>, source: URL,
                          bind: (String, ResolvedType, Bool) -> Bool) -> Bool
    {
        func match(_ pattern: ResolvedType, to value: ResolvedType, nesting: Int = 0, invariant: Bool = false) -> Bool {
            guard nesting < 16 else { return false }
            if !pattern.isMetatype, pattern.name.hasPrefix("$generic:"), genericNames.contains(String(pattern.name.dropFirst("$generic:".count))) {
                let name = String(pattern.name.dropFirst("$generic:".count))
                return bind(name, value, invariant)
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
            if let signature = pattern.functionType {
                guard let actual = value.functionType, signature.qualifiers == actual.qualifiers,
                      signature.parameters.count == actual.parameters.count else { return false }
                return zip(signature.parameters, actual.parameters).allSatisfy {
                    match($0, to: $1, nesting: nesting + 1, invariant: invariant)
                } && match(signature.result, to: actual.result, nesting: nesting + 1, invariant: invariant)
            }
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
                  let identity = project.typeIdentity(named: formalName, visibleFrom: pattern.sourceFileURL ?? source),
                  identity == project.typeIdentity(named: actualName, visibleFrom: value.sourceFileURL ?? fileURL)
            else {
                return sameType(pattern, as: value)
            }
            if let parent = pattern.enclosingType {
                guard let other = value.enclosingType,
                      match(parent.type, to: other.type, nesting: nesting + 1, invariant: true) else { return false }
            } else if value.enclosingType != nil {
                return false
            }
            let formal = pattern.genericArguments ?? []
            let actual = value.genericArguments ?? []
            guard formal.count == actual.count else { return false }
            let source = project.typeSourceFile(named: formalName, visibleFrom: pattern.sourceFileURL ?? source)
            let fixed = invariant || source?.pathExtension == "swift"
            return zip(formal, actual).allSatisfy { match($0, to: $1, nesting: nesting + 1, invariant: fixed) }
        }
        return match(pattern, to: value)
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
        func infer(_ pattern: String, from value: ResolvedType) -> Bool {
            guard let formal = type(named: pattern, namespace: symbol.declaration.declaringType, sourceFileURL: symbol.fileURL,
                                    substitutions: placeholders, requiresGenericArguments: true) else { return false }
            return matchGenericType(formal, to: value, genericNames: genericNames, source: symbol.fileURL) { name, value, invariant in
                if let previous = substitutions[name], !sameType(previous, as: value) {
                    return false
                }
                substitutions[name] = value
                if invariant {
                    fixedGenericNames.insert(name)
                }
                return true
            }
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
                    guard isFixed(term) else { continue }
                    if genericNames.contains(variable), substitutions[variable] != nil {
                        fixedGenericNames.insert(variable)
                    } else if let pattern = type(named: variable, namespace: symbol.declaration.declaringType, sourceFileURL: symbol.fileURL,
                                                 substitutions: placeholders, requiresGenericArguments: true),
                        let value = signatureType(term, symbol: symbol, substitutions: substitutions)
                    {
                        var fixed = Set<String>()
                        if matchGenericType(pattern, to: value, genericNames: genericNames, source: symbol.fileURL, bind: { name, value, _ in
                            guard let inferred = substitutions[name], sameType(inferred, as: value) else { return false }
                            fixed.insert(name)
                            return true
                        }) {
                            fixedGenericNames.formUnion(fixed)
                        }
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

    /// Implicit method calls use the same specialized receiver as explicit self access.
    func implicitReceiver(for receiver: ProjectIndex.FunctionCallReceiver?, at index: Int) -> ResolvedType? {
        guard case let .unqualified(name?, isStatic) = receiver,
              var owner = type(named: name, namespace: nil, at: index) else { return nil }
        owner.isMetatype = isStatic
        return owner
    }

    /// Abstract receivers expose their indexed bounds without acquiring a nominal identity.
    func functionReceiver(for owner: ResolvedType) -> ProjectIndex.FunctionCallReceiver? {
        guard unwrapped(owner) == nil else { return nil }
        if let name = qualifiedName(for: owner) {
            return owner.isMetatype ? .type(name) : .instance(type: name)
        }
        guard owner.isAbstract, let bounds = owner.genericBounds, !bounds.isEmpty else { return nil }
        let constraints = bounds.compactMap { bound -> ProjectIndex.FunctionCallReceiver.Constraint? in
            guard let name = qualifiedName(for: bound) else { return nil }
            return .init(name: name, fileURL: bound.sourceFileURL ?? fileURL)
        }
        guard constraints.count == bounds.count else { return nil }
        return .constrained(constraints, isStatic: owner.isMetatype)
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
            guard !hasLocalFunction(named: root, at: identifier),
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
                  initializerRootIsUnshadowed(annotation.string, namespace: namespace)
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
        var receiverSource = fileURL
        if let dot, let receiverStart, receiverStart < dot {
            owner = expressionType(in: receiverStart ... dot - 1, depth: depth + 1)
            receiver = owner.flatMap(functionReceiver)
            receiverSource = owner?.sourceFileURL ?? fileURL
        } else {
            receiver = project.functionCallReceiver(at: identifier, in: formatter, visibleFrom: fileURL, declarations: declarations)
            owner = implicitReceiver(for: receiver, at: identifier)
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
                                                  visibleFrom: receiverSource, ignoringLabelAt: trailing,
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
    /// A cast or suffix constrains the expression's result, not the input of a closure
    /// or initializer at its start. Do not skip across that boundary to an outer annotation.
    func contextualValueIsTransformed(at expression: Int) -> Bool {
        var end: Int?
        if [Token.startOfScope("("), .startOfScope("{"), .startOfScope("[")].contains(formatter.tokens[expression]) {
            end = formatter.endOfScope(at: expression)
        } else if formatter.tokens[expression].isOperator("."),
                  let member = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: expression)
        {
            if let open = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: member),
               formatter.tokens[open] == .startOfScope("(")
            {
                end = formatter.endOfScope(at: open)
            } else {
                end = member
            }
        }
        guard let end, let next = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: end) else { return false }
        let token = formatter.tokens[next]
        if token == .startOfScope("{"), formatter.tokens[expression].isStartOfScope {
            return true
        }
        return [Token.keyword("as"), .keyword("is"), .startOfScope("("), .startOfScope("[")].contains(token) ||
            token.isOperator(".") || token.isOperator(ofType: .postfix) ||
            token.isOperator(ofType: .infix) && !["?", ":"].contains(token.string)
    }

    /// Only grouping and ternary result branches preserve their enclosing expected type.
    /// Calls, tuple elements and conditional operands keep their own parameter contexts.
    func enclosingContextualExpression(at expression: Int) -> Int? {
        guard let previous = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: expression) else { return nil }
        if formatter.tokens[previous] == .startOfScope("("),
           formatter.parseFunctionIdentifier(beforeStartOfScope: previous) == nil,
           let close = formatter.endOfScope(at: previous),
           let range = formatter.parseExpressionRange(startingAt: expression),
           formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: range.upperBound) == close
        {
            return previous
        }
        if formatter.tokens[previous] == .startOfScope("{") || formatter.tokens[previous] == .startOfScope(":") {
            for conditional in conditionalExpressions.filter({ $0.range.contains(expression) }).sorted(by: { $0.range.count < $1.range.count }) {
                let keyword = conditional.range.lowerBound
                if conditionalValueRanges(at: keyword)?.contains(where: { $0.lowerBound == expression }) == true {
                    return keyword
                }
            }
        }
        var question: Int?
        if formatter.tokens[previous] == .operator("?", .infix) {
            question = previous
        } else if formatter.tokens[previous] == .operator(":", .infix) {
            var cursor = previous
            while let candidate = formatter.index(of: .operator("?", .infix), before: cursor) {
                if formatter.findTernaryColon(after: candidate) == previous {
                    question = candidate
                    break
                }
                cursor = candidate
            }
        }
        guard let question, let end = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: question),
              let condition = formatter.parseExpressionRange(endingAt: end), condition.lowerBound < expression else { return nil }
        return condition.lowerBound
    }

    /// Aggregate literals preserve each element's declared context. Subscripts and calls
    /// have their own signatures; custom literal conformances do not imply collection elements.
    func aggregateElementType(at expression: Int, depth: Int) -> ResolvedType? {
        guard let scope = formatter.startOfScope(at: expression),
              [Token.startOfScope("("), .startOfScope("[")].contains(formatter.tokens[scope]),
              !formatter.isSubscriptOrFunctionCall(at: scope),
              let expected = contextualType(at: scope, depth: depth + 1) else { return nil }
        let aggregate = unwrapped(expected) ?? expected
        if formatter.tokens[scope] == .startOfScope("(") {
            let arguments = formatter.parseTupleArguments(startOfScope: scope)
            guard let elements = aggregate.tupleElements, arguments.count == elements.count,
                  let position = arguments.firstIndex(where: { $0.valueRange.lowerBound == expression }),
                  arguments[position].label == nil || arguments[position].label == elements[position].label else { return nil }
            return elements[position].type
        }
        guard let kind = aggregate.collectionKind, let arguments = aggregate.genericArguments else { return nil }
        for entry in formatter.commaSeparatedElementsInScope(startOfScope: scope) {
            if kind == .dictionary {
                guard arguments.count == 2,
                      let colon = formatter.index(of: .delimiter(":"), in: Range(entry)),
                      let key = formatter.index(of: .nonSpaceOrCommentOrLinebreak, in: entry.lowerBound ..< colon),
                      let value = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: colon) else { return nil }
                if expression == key {
                    return arguments[0]
                }
                if expression == value {
                    return arguments[1]
                }
            } else if [.array, .arraySlice, .contiguousArray, .set].contains(kind), arguments.count == 1,
                      formatter.index(of: .nonSpaceOrCommentOrLinebreak, in: Range(entry)) == expression
            {
                return arguments[0]
            }
        }
        return nil
    }

    func contextualType(at expression: Int, depth: Int) -> ResolvedType? {
        guard depth < 32, !contextualValueIsTransformed(at: expression),
              let previous = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: expression) else { return nil }
        if let outer = enclosingContextualExpression(at: expression),
           let expected = contextualType(at: outer, depth: depth + 1)
        {
            return expected
        }
        if let element = aggregateElementType(at: expression, depth: depth + 1) {
            return element
        }
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
        guard let function = project.functionSymbol(named: name, receiver: receiver, arguments: arguments.map(\.label), visibleFrom: source, accessedFrom: fileURL, accessedFromType: accessingType,
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
        guard initializerRootIsUnshadowed(spelling, namespace: namespace),
              var result = type(named: spelling, namespace: namespace, at: index, requiresGenericArguments: true),
              let name = qualifiedName(for: result),
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

    func functionValueResult(_ value: ResolvedType, arguments: [Formatter.FunctionCallArgument], depth: Int) -> ResolvedType? {
        guard depth < 32, !value.isMetatype, unwrapped(value) == nil, let signature = value.functionType,
              arguments.count == signature.parameters.count, arguments.allSatisfy({ $0.label == nil }) else { return nil }
        let known = knownArgumentTypes(arguments, depth: depth + 1)
        guard !known.contains(where: { argumentIsIncompatible($0.value, with: signature.parameters[$0.key]) }) else { return nil }
        // Swift can choose a method when a same-named property's parameter cannot accept
        // the argument. Mere lack of a proven mismatch does not establish applicability.
        if signature.requiresArgumentProof {
            guard known.count == arguments.count,
                  known.allSatisfy({ sameType($0.value, as: signature.parameters[$0.key]) }) else { return nil }
        }
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

    /// A conditional value has one expression per exhaustive branch. Statements, directives,
    /// and unresolved branches cannot supply a common type just because another branch can.
    func conditionalValueRanges(at keyword: Int) -> [ClosedRange<Int>]? {
        guard let branches = formatter.conditionalBranches(at: keyword), let last = branches.last,
              formatter.conditionalBranchesAreExhaustive(conditionKeywordIndex: keyword, branches: branches),
              !formatter.tokens[keyword ... last.endOfBranch].contains(.startOfScope("#if")) else { return nil }
        let ranges = branches.compactMap { branch -> ClosedRange<Int>? in
            guard let first = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: branch.startOfBranch),
                  first < branch.endOfBranch,
                  let range = formatter.parseExpressionRange(startingAt: first, allowConditionalExpressions: true),
                  formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: range.upperBound) == branch.endOfBranch else { return nil }
            return range
        }
        return ranges.count == branches.count ? ranges : nil
    }

    func conditionalExpressionType(first: Int, last: Int, depth: Int) -> ResolvedType? {
        guard formatter.conditionalBranches(at: first)?.last?.endOfBranch == last,
              let ranges = conditionalValueRanges(at: first) else { return nil }
        let values = ranges.map { expressionType(in: $0, depth: depth + 1) }
        guard var result = values.compactMap({ $0 }).first else { return nil }
        for (range, value) in zip(ranges, values) {
            guard let branch = value ?? implicitEnumCaseType(in: range, expected: result),
                  let common = commonType(result, branch) else { return nil }
            result = common
        }
        return result
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

    /// Prove that an expression root names a nominal type before using it as a static receiver.
    func nominalMetatype(in range: ClosedRange<Int>, namespace: String?) -> ResolvedType? {
        let spelling = formatter.tokens[range].string
        guard let reference = ProjectTypeReference(spelling), let root = reference.name.split(separator: ".").first,
              bindings[String(root)]?.contains(where: { $0.isVisible(at: range.lowerBound) }) != true,
              !hasLocalFunction(named: String(root), at: range.lowerBound),
              namespace.map({ project.constructorRootIsUnshadowed(String(root), in: $0, visibleFrom: fileURL) }) ?? true,
              initializerRootIsUnshadowed(spelling, namespace: namespace),
              var metatype = type(named: spelling, namespace: namespace, at: range.lowerBound, requiresGenericArguments: true),
              !metatype.isMetatype, unwrapped(metatype) == nil,
              let name = qualifiedName(for: metatype), project.hasSymbolType(named: name, visibleFrom: metatype.sourceFileURL ?? fileURL) else { return nil }
        metatype.isMetatype = true
        return metatype
    }

    func expressionType(in range: ClosedRange<Int>, projecting tuplePath: [Int] = [], expected: ResolvedType? = nil, depth: Int = 0) -> ResolvedType? {
        guard depth < 32,
              let first = formatter.index(of: .nonSpaceOrCommentOrLinebreak, in: Range(range)),
              let last = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: range.upperBound + 1), first <= last else { return nil }
        let tokens = formatter.tokens
        if let position = tuplePath.first {
            if tokens[first] == .startOfScope("("), formatter.endOfScope(at: first) == last {
                let arguments = formatter.parseTupleArguments(startOfScope: first)
                if arguments.count == 1, let argument = arguments.first, argument.label == nil {
                    return expressionType(in: argument.valueRange, projecting: tuplePath, depth: depth + 1)
                }
                guard arguments.indices.contains(position) else { return nil }
                return expressionType(in: arguments[position].valueRange, projecting: Array(tuplePath.dropFirst()), depth: depth + 1)
            }
            var result = expressionType(in: first ... last, depth: depth + 1)
            for position in tuplePath {
                result = result.flatMap { memberType(owner: $0, name: String(position)) }
            }
            return result
        }
        if tokens[first] == .keyword("if") || tokens[first] == .keyword("switch") {
            return conditionalExpressionType(first: first, last: last, depth: depth + 1)
        }
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
           let metatype = nominalMetatype(in: first ... dot - 1, namespace: namespace)
        {
            current = metatype
            cursor = member
        } else if let open = formatter.index(of: .startOfScope("<"), in: first ..< last),
                  let close = formatter.endOfScope(at: open), close < last,
                  formatter.next(.nonSpaceOrCommentOrLinebreak, after: close)?.isOperator(".") == true,
                  let metatype = nominalMetatype(in: first ... close, namespace: namespace)
        {
            current = metatype
            cursor = close
        } else if let annotation = formatter.parseType(at: first),
                  let open = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: annotation.range.upperBound),
                  tokens[open] == .startOfScope("("), let close = formatter.endOfScope(at: open), close <= last,
                  let collection = explicitInitializerType(formatter.tokens[first ... close].string, namespace: namespace, source: fileURL, substitutions: [:]),
                  collection.collectionKind != nil,
                  bindings[identifier]?.contains(where: { $0.isVisible(at: first) }) != true,
                  !hasLocalFunction(named: identifier, at: first)
        {
            current = collection
            cursor = close
        } else if tokens[first].isIdentifier,
                  bindings[identifier]?.contains(where: { $0.isVisible(at: first) }) != true,
                  !hasLocalFunction(named: identifier, at: first),
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
                  !hasLocalFunction(named: identifier, at: first),
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
            guard !hasLocalFunction(named: identifier, at: first),
                  unavailableTypes[identifier]?.contains(where: { $0.range.contains(first) }) != true else { return nil }
            let arguments = formatter.parseFunctionCallArguments(startOfScope: open).filter { $0.valueRange.upperBound <= last }
            if let value = bindingType(named: identifier, at: first, depth: depth + 1), value.functionType != nil {
                current = functionValueResult(value, arguments: arguments, depth: depth + 1)
            } else {
                guard bindings[identifier]?.contains(where: { $0.isVisible(at: first) }) != true else { return nil }
                let receiver = project.functionCallReceiver(at: first, in: formatter, visibleFrom: fileURL, declarations: declarations)
                current = receiver.flatMap {
                    callType(name: identifier, receiver: $0, arguments: arguments, owner: implicitReceiver(for: $0, at: first), accessingType: namespace, depth: depth + 1)
                }
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
                current = namespace.flatMap { type(named: $0, namespace: nil, at: first) }
                current?.isMetatype = identifier == "Self" || isStatic
            }
        } else if bindings[identifier]?.contains(where: { $0.isVisible(at: first) }) != true,
                  !hasLocalFunction(named: identifier, at: first),
                  var generic = type(named: identifier, namespace: namespace, at: first),
                  generic.genericParameterScope != nil, unwrapped(generic) == nil
        {
            generic.isMetatype = true
            current = generic
        } else if let enumCase = unqualifiedEnumCase(named: identifier, at: first) {
            current = enumCase.payloadTypes.isEmpty ? enumCase.type : nil
        } else {
            current = bindingType(named: identifier, at: first, depth: depth + 1)
            if current == nil, bindings[identifier]?.contains(where: { $0.isVisible(at: first) }) != true,
               !hasLocalFunction(named: identifier, at: first),
               initializerRootIsUnshadowed(identifier, namespace: namespace),
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
                current = functionValueResult(callable, arguments: arguments, depth: depth + 1)
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
            guard tokens[member].isIdentifier else { return nil }
            if owner.isAbstract {
                if let open = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: member), open <= last,
                   tokens[open] == .startOfScope("(") || tokens[open] == .startOfScope("{"),
                   let close = formatter.endOfScope(at: open), close <= last
                {
                    let arguments = formatter.parseFunctionCallArguments(startOfScope: open).filter { $0.valueRange.upperBound <= last }
                    if let callable = memberType(owner: owner, name: memberName, accessingType: namespace, depth: depth + 1) {
                        current = functionValueResult(callable, arguments: arguments, depth: depth + 1)
                    } else if let receiver = functionReceiver(for: owner) {
                        current = callType(name: memberName, receiver: receiver, arguments: arguments, owner: owner,
                                           accessingType: namespace, depth: depth + 1)
                    } else {
                        return nil
                    }
                    cursor = arguments.last.map { max(close, $0.valueRange.upperBound) } ?? close
                } else {
                    current = memberType(owner: owner, name: memberName, accessingType: namespace, depth: depth + 1)
                    cursor = member
                }
                continue
            }
            guard let ownerName = qualifiedName(for: owner) else { return nil }
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
                    current = functionValueResult(value, arguments: arguments, depth: depth + 1)
                } else {
                    current = callType(name: memberName, receiver: owner.isMetatype ? .type(ownerName) : .instance(type: ownerName), arguments: arguments, sourceFileURL: owner.sourceFileURL, owner: owner, accessingType: namespace, depth: depth + 1)
                }
                cursor = arguments.last.map { max(close, $0.valueRange.upperBound) } ?? close
            } else {
                current = memberType(owner: owner, name: memberName, accessingType: namespace)
                if current == nil, owner.isMetatype, project.hasSymbolType(named: "\(ownerName).\(memberName)", visibleFrom: fileURL) {
                    var instance = owner
                    instance.isMetatype = false
                    if var nested = dependentMemberType(memberName, of: instance, depth: depth + 1) {
                        nested.isMetatype = true
                        current = nested
                    }
                }
                if current == nil, owner.isMetatype,
                   project.typeDeclaration(named: ownerName, visibleFrom: owner.sourceFileURL ?? fileURL)?.enumCasePayloads?[memberName] == [],
                   !project.hasProperty(owner: ownerName, member: memberName, visibleFrom: owner.sourceFileURL ?? fileURL, accessedFrom: fileURL)
                {
                    var value = owner
                    value.isMetatype = false
                    current = value
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
    var parent: String?
    var member: String?

    init?(_ spelling: String) {
        let formatter = Formatter(tokenize(spelling))
        guard !formatter.tokens.isEmpty else { return nil }
        var components = [String]()
        var arguments = [String]()
        var hasGenericParent = false
        var lastDot: Int?
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
                if token.isOperator(".") {
                    lastDot = index
                }
                components.append(token.string)
            } else {
                valid = false
            }
        }
        guard valid, !components.isEmpty, components.first != ".", components.last != "." else { return nil }
        name = components.joined()
        self.arguments = arguments
        self.hasGenericParent = hasGenericParent
        if let lastDot {
            parent = formatter.tokens[..<lastDot].string
            member = formatter.tokens[lastDot + 1 ..< formatter.tokens.count].string
        }
    }
}
