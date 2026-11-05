//
//  ExhaustiveSwitchStatements.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 11/05/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Replaces defaults with the remaining cases of a project-indexed enum.
    static let exhaustiveSwitchStatements = FormatRule(
        help: "Replace switch defaults with exhaustive cases from the project index.",
        disabledByDefault: true
    ) { formatter in
        guard formatter.tokens.contains(.endOfScope("default")),
              let fileURL = formatter.currentFileURL,
              let project = formatter.projectIndex(requiring: [.declarations]) else { return }
        let resolver = ExhaustiveSwitchTypeResolver(formatter: formatter, project: project, fileURL: fileURL)
        formatter.forEach(.keyword("switch")) { switchIndex, _ in
            formatter.expandSwitchDefault(at: switchIndex, resolver: resolver)
        }
    } examples: {
        """
        ```diff
          enum State { case idle, loading, loaded, failed }
          func render(_ state: State) {
              switch state {
              case .loaded:
                  showContent()
        -     default:
        +     case .idle, .loading, .failed:
                  showPlaceholder()
              }
          }
        ```

        Requires the project index. Unknown defaults and unresolved types are preserved.
        """
    }
}

extension Formatter {
    func expandSwitchDefault(at switchIndex: Int, resolver: ExhaustiveSwitchTypeResolver) {
        guard let openBrace = index(of: .startOfScope("{"), after: switchIndex),
              let closeBrace = endOfScope(at: openBrace),
              !tokens[openBrace ... closeBrace].contains(.startOfScope("#if")),
              let subject = index(of: .nonSpaceOrCommentOrLinebreak, after: switchIndex),
              let subjectEnd = index(of: .nonSpaceOrCommentOrLinebreak, before: openBrace),
              let type = resolver.expressionType(in: subject ... subjectEnd),
              let cases = resolver.enumCases(for: type),
              let branches = switchStatementBranches(at: switchIndex)
        else { return }
        var defaultIndex: Int?
        var covered = Set<String>()
        for branch in branches {
            guard let keyword = index(before: branch.startOfBranch, where: { $0.isSwitchCaseOrDefault }) else { return }
            if tokens[keyword] == .endOfScope("default") {
                guard last(.nonSpaceOrCommentOrLinebreak, before: keyword) != .keyword("@unknown") else { return }
                defaultIndex = keyword
                continue
            }
            // A where clause only handles a subset of its case.
            if index(of: .keyword("where"), in: keyword + 1 ..< branch.startOfBranch) != nil {
                continue
            }
            var start = keyword + 1
            while start < branch.startOfBranch {
                let end = index(of: .delimiter(","), in: start ..< branch.startOfBranch) ?? branch.startOfBranch
                if let name = exhaustiveSwitchCoveredCase(in: start ..< end, type: type, resolver: resolver, cases: cases) {
                    covered.insert(name)
                }
                start = end + 1
            }
        }
        let remaining = cases.filter { !covered.contains($0) }
        // An unreachable default may contain comments or code; leave it intact.
        guard let defaultIndex, !remaining.isEmpty else { return }
        updateEnablement(at: defaultIndex)
        guard isEnabled(at: defaultIndex) else { return }
        let replacement = " " + remaining.map { ".\($0)" }.joined(separator: ", ")
        replaceToken(at: defaultIndex, with: [.endOfScope("case")] + tokenize(replacement))
    }

    /// Only subtract patterns that cover the entire case, including all of its payloads.
    func exhaustiveSwitchCoveredCase(in range: Range<Int>, type: ExhaustiveSwitchTypeResolver.ResolvedType,
                                     resolver: ExhaustiveSwitchTypeResolver, cases: [String]) -> String?
    {
        let payload = index(of: .startOfScope("("), in: range)
        let head = tokens[range.lowerBound ..< (payload ?? range.upperBound)]
            .filter { !$0.isSpaceOrCommentOrLinebreak && $0 != .keyword("let") && $0 != .keyword("var") }
            .string.replacingOccurrences(of: "`", with: "")
        guard let name = cases.first(where: { name in
            let unescaped = name.replacingOccurrences(of: "`", with: "")
            if head == ".\(unescaped)" {
                return true
            }
            guard head.hasSuffix(".\(unescaped)"),
                  let end = index(of: .nonSpaceOrCommentOrLinebreak, before: payload ?? range.upperBound),
                  let dot = index(of: .nonSpaceOrCommentOrLinebreak, before: end), tokens[dot].isOperator("."),
                  let start = index(in: range, where: { !$0.isSpaceOrCommentOrLinebreak && $0 != .keyword("let") && $0 != .keyword("var") }),
                  start < dot, let prefix = resolver.expressionType(in: start ... dot - 1), prefix.isMetatype
            else { return false }
            return resolver.qualifiedName(for: prefix) == resolver.qualifiedName(for: type)
        }) else { return nil }
        guard let payload else { return name }
        guard let end = endOfScope(at: payload),
              index(of: .nonSpaceOrCommentOrLinebreak, in: end + 1 ..< range.upperBound) == nil else { return nil }
        let bindsAll = tokens[range.lowerBound ..< payload].contains(.keyword("let")) ||
            tokens[range.lowerBound ..< payload].contains(.keyword("var"))
        for argument in parseTupleArguments(startOfScope: payload) {
            let value = tokens[argument.valueRange].filter { !$0.isSpaceOrCommentOrLinebreak }
            if value == [.identifier("_")] {
                continue
            }
            if value.count == 1, value.first?.isIdentifier == true, value.first?.isLiteralIdentifier == false, bindsAll {
                continue
            }
            if value.count == 2, [.keyword("let"), .keyword("var")].contains(value[0]), value[1].isIdentifier, !value[1].isLiteralIdentifier {
                continue
            }
            return nil
        }
        return name
    }
}

/// Resolves simple expressions through scoped bindings and indexed declarations, without guessing from case names.
final class ExhaustiveSwitchTypeResolver {
    struct ResolvedType {
        var name: String
        var namespace: String?
        var isMetatype = false
    }

    struct Binding {
        var location: AutoUpdatingRange
        var scope: AutoUpdatingRange
        var type: String?
        var value: AutoUpdatingRange?
        var namespace: String?
        var unwrapsOptional = false
        var requiresPrecedingDeclaration = false
        var isGlobal = false
    }

    let formatter: Formatter
    let project: ProjectIndex
    let fileURL: URL
    let declarations: [Declaration]
    var bindings = [String: [Binding]]()
    var aliases = Set<String>()
    var genericNames = Set<String>()
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
                    self.genericNames.formUnion(formatter.tokens[parameters.range].filter(\.isIdentifier).map(\.string))
                }
            }
        }
        declarations.forEachRecursiveDeclaration { declaration in
            if declaration.keyword == "func", let name = declaration.name,
               ([declaration] + declaration.parentDeclarations).contains(where: {
                   [.private, .fileprivate].contains($0.visibility() ?? .internal)
               })
            {
                self.unindexedFunctions.insert(name)
            }
        }
        formatter.forEachToken { i, token in
            guard ["typealias", "let", "var", "for", "class", "struct", "enum", "actor"].contains(token.string) ||
                token.isFunctionDeclarationKeyword || token == .startOfScope("{") else { return }
            let namespace = formatter.parseEnclosingType(containing: i, declarations: self.declarations)?.fullyQualifiedName
            if token == .keyword("typealias"), let name = formatter.next(.identifier, after: i)?.string {
                self.aliases.insert(name)
            }
            if ["class", "struct", "enum", "actor"].contains(token.string), formatter.declarationScope(at: i) == .local,
               let name = formatter.next(.identifier, after: i)?.string
            {
                self.aliases.insert(name)
            }
            if token == .keyword("let") || token == .keyword("var") {
                let scopeStart = formatter.startOfScope(at: i) ?? 0
                let scopeEnd = formatter.endOfScope(at: scopeStart) ?? formatter.tokens.count - 1
                var scope = scopeStart ... scopeEnd
                let conditional = formatter.startOfConditionalStatement(at: i)
                let isPattern = formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) == .keyword("case") ||
                    formatter.startOfScope(at: i).map { formatter.tokens[$0] == .startOfScope("(") } == true
                let property = isPattern ? nil : formatter.parsePropertyDeclaration(atIntroducerIndex: i)
                let names = formatter.namesInDeclaration(at: i) ?? []
                var unwrapsOptional = false
                if let conditional,
                   [Token.keyword("if"), .keyword("guard"), .keyword("while")].contains(formatter.tokens[conditional]),
                   let body = formatter.startOfConditionalBranchBody(after: conditional),
                   let end = formatter.endOfScope(at: body)
                {
                    unwrapsOptional = !isPattern
                    scope = formatter.tokens[conditional] == .keyword("guard") ? end ... scopeEnd : body ... end
                }
                for name in names {
                    self.addBinding(name, at: i, scope: scope, type: names.count == 1 ? property?.type?.string : nil,
                                    value: names.count == 1 ? property?.value?.expressionRange : nil, namespace: namespace,
                                    unwrapsOptional: unwrapsOptional, requiresPrecedingDeclaration: formatter.declarationScope(at: i) == .local,
                                    isGlobal: formatter.declarationScope(at: i) == .global)
                }
            } else if token.isFunctionDeclarationKeyword,
                      let function = formatter.parseFunctionDeclaration(keywordIndex: i)
            {
                if formatter.declarationScope(at: i) == .local, let name = function.name {
                    self.unindexedFunctions.insert(name)
                }
                if let parameters = function.genericParameterRange {
                    self.genericNames.formUnion(formatter.tokens[parameters].filter(\.isIdentifier).map(\.string))
                }
                guard let body = function.bodyRange else { return }
                for argument in function.arguments {
                    if let name = argument.internalLabel {
                        self.addBinding(name, at: argument.internalLabelIndex, scope: body, type: argument.type.string, namespace: namespace)
                    }
                }
            } else if token == .startOfScope("{"), formatter.isStartOfClosure(at: i),
                      let arguments = formatter.parseClosureArguments(at: i), let end = formatter.endOfScope(at: i)
            {
                for argument in arguments.argumentIndices {
                    self.addBinding(formatter.tokens[argument].string, at: argument, scope: i ... end, namespace: namespace)
                }
                if let captures = arguments.captureListRange {
                    for capture in captures where formatter.tokens[capture].isIdentifier {
                        self.addBinding(formatter.tokens[capture].string, at: capture, scope: i ... end, namespace: namespace)
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
        var patterns = [(Range<Int>, ClosedRange<Int>)]()
        formatter.forEach(.keyword("switch")) { index, _ in
            for branch in formatter.switchStatementBranches(at: index) ?? [] {
                guard let keyword = formatter.index(before: branch.startOfBranch, where: { $0.isSwitchCaseOrDefault }) else { continue }
                patterns.append((keyword + 1 ..< branch.startOfBranch, branch.startOfBranch ... branch.endOfBranch))
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
                patterns.append((index + 1 ..< body, token == .keyword("guard") ? end ... scopeEnd : body ... end))
            }
        }
        for (range, scope) in patterns {
            addPatternBindings(in: range, scope: scope)
        }
    }

    func addPatternBindings(in range: Range<Int>, scope: ClosedRange<Int>) {
        formatter.forEachToken(in: range, onlyWhereEnabled: false) { index, token in
            guard token == .keyword("let") || token == .keyword("var") else { return }
            for name in formatter.namesInDeclaration(at: index) ?? [] {
                self.addBinding(name, at: index, scope: scope, namespace: nil)
            }
        }
    }

    func addBinding(_ name: String, at index: Int, scope: ClosedRange<Int>, type: String? = nil,
                    value: ClosedRange<Int>? = nil, namespace: String?, unwrapsOptional: Bool = false,
                    requiresPrecedingDeclaration: Bool = false, isGlobal: Bool = false)
    {
        bindings[name, default: []].append(Binding(
            location: AutoUpdatingRange(range: index ... index, formatter: formatter),
            scope: AutoUpdatingRange(range: scope, formatter: formatter), type: type,
            value: value.map { AutoUpdatingRange(range: $0, formatter: formatter) }, namespace: namespace,
            unwrapsOptional: unwrapsOptional, requiresPrecedingDeclaration: requiresPrecedingDeclaration, isGlobal: isGlobal
        ))
    }

    func type(named rawName: String, namespace: String?) -> ResolvedType? {
        let tokens = tokenize(rawName).filter { !$0.isSpaceOrCommentOrLinebreak }
            .drop(while: { ["inout", "borrowing", "consuming", "sending"].contains($0.string) })
        guard !tokens.contains(where: { $0.isIdentifier && (aliases.contains($0.string) || genericNames.contains($0.string)) }) else { return nil }
        return ResolvedType(name: tokens.string, namespace: namespace)
    }

    func qualifiedName(for type: ResolvedType) -> String? {
        guard !type.name.isEmpty,
              tokenize(type.name).allSatisfy({ $0.isIdentifier || $0.isOperator(".") }) else { return nil }
        var namespace = type.namespace
        while let owner = namespace {
            let name = "\(owner).\(type.name)"
            if localTypes[name] != nil || project.containsType(named: name, visibleFrom: fileURL) {
                return name
            }
            // Explicitly qualified names already identify their namespace.
            if !type.name.contains("."), !project.isTypeWithoutInheritance(named: owner, visibleFrom: fileURL) {
                return nil
            }
            namespace = owner.contains(".") ? owner.split(separator: ".").dropLast().joined(separator: ".") : nil
        }
        return type.name
    }

    func enumCases(for type: ResolvedType) -> [String]? {
        guard !type.isMetatype, let name = qualifiedName(for: type) else { return nil }
        if let local = localTypes[name], local.count == 1, let declaration = local.first {
            return formatter.indexedEnumCases(in: declaration)
        }
        return project.enumCases(named: name, visibleFrom: fileURL)
    }

    func bindingType(named name: String, at index: Int, depth: Int) -> ResolvedType? {
        let enclosingType = formatter.parseEnclosingType(containing: index, declarations: declarations)?.fullyQualifiedName
        let visible = (bindings[name] ?? []).filter {
            $0.scope.range.contains(index) && (!$0.requiresPrecedingDeclaration || $0.location.range.lowerBound < index)
        }
        if let owner = enclosingType, !visible.contains(where: { !$0.isGlobal }) {
            let receiver = project.functionCallReceiver(at: index, in: formatter, visibleFrom: fileURL, declarations: declarations)
            let isStatic: Bool
            if case let .unqualified(_, value) = receiver {
                isStatic = value
            } else {
                isStatic = false
            }
            if let member = memberType(owner: ResolvedType(name: owner, namespace: nil, isMetatype: isStatic), name: name) {
                return member
            }
            guard project.isTypeWithoutInheritance(named: owner, visibleFrom: fileURL),
                  !project.isDynamicMemberLookupType(named: owner, visibleFrom: fileURL),
                  !project.exhaustiveSwitchHasProperty(owner: owner, member: name, visibleFrom: fileURL) else { return nil }
        }
        if let size = visible.map(\.scope.range.count).min() {
            let closest = visible.filter { $0.scope.range.count == size }
            let locals = closest.filter(\.requiresPrecedingDeclaration)
            guard let binding = locals.max(by: { $0.location.range.lowerBound < $1.location.range.lowerBound }) ??
                (closest.count == 1 ? closest.first : nil) else { return nil }
            var result: ResolvedType?
            if let annotation = binding.type {
                result = type(named: annotation, namespace: binding.namespace)
            } else if let value = binding.value {
                result = expressionType(in: value.range, depth: depth + 1)
            } else if binding.unwrapsOptional {
                result = bindingType(named: name, at: binding.location.range.lowerBound, depth: depth + 1)
            }
            if binding.unwrapsOptional, let current = result {
                result = unwrapped(current)
            }
            return result
        }
        guard let owner = enclosingType else { return nil }
        return memberType(owner: ResolvedType(name: owner, namespace: nil), name: name)
    }

    func unwrapped(_ type: ResolvedType) -> ResolvedType? {
        guard type.name.hasSuffix("?") || type.name.hasSuffix("!") else { return nil }
        return ResolvedType(name: String(type.name.dropLast()), namespace: type.namespace)
    }

    func memberType(owner: ResolvedType, name: String) -> ResolvedType? {
        guard let ownerName = qualifiedName(for: owner),
              let memberType = project.exhaustiveSwitchPropertyType(owner: ownerName, member: name, isStatic: owner.isMetatype, visibleFrom: fileURL) else { return nil }
        return type(named: memberType, namespace: ownerName)
    }

    func callType(name: String, receiver: ProjectIndex.FunctionCallReceiver, arguments: [String?]) -> ResolvedType? {
        guard !unindexedFunctions.contains(name), let call = project.resolveFunctionCall(named: name, receiver: receiver, argumentLabels: arguments, visibleFrom: fileURL),
              let first = call.matches.first,
              let returnType = first.declaration.returnType,
              call.matches.allSatisfy({ $0.declaration.returnType == returnType && $0.declaration.declaringType == first.declaration.declaringType }) else { return nil }
        if case let .unqualified(owner?, _) = receiver, first.declaration.declaringType == nil {
            guard project.isTypeWithoutInheritance(named: owner, visibleFrom: fileURL),
                  !project.isDynamicMemberLookupType(named: owner, visibleFrom: fileURL),
                  !project.exhaustiveSwitchHasProperty(owner: owner, member: name, visibleFrom: fileURL) else { return nil }
        }
        return type(named: returnType, namespace: first.declaration.declaringType)
    }

    func expressionType(in range: ClosedRange<Int>, depth: Int = 0) -> ResolvedType? {
        guard depth < 12,
              let first = formatter.index(of: .nonSpaceOrCommentOrLinebreak, in: Range(range)),
              let last = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: range.upperBound + 1), first <= last else { return nil }
        let tokens = formatter.tokens
        if tokens[first] == .startOfScope("("), formatter.endOfScope(at: first) == last, first + 1 < last {
            return expressionType(in: first + 1 ... last - 1, depth: depth + 1)
        }
        if tokens[last] == .operator("!", .postfix), first < last,
           let wrapped = expressionType(in: first ... last - 1, depth: depth + 1)
        {
            return unwrapped(wrapped)
        }
        guard tokens[first].isIdentifier else { return nil }
        let namespace = formatter.parseEnclosingType(containing: first, declarations: declarations)?.fullyQualifiedName
        let identifier = tokens[first].string
        var current: ResolvedType?
        var cursor = first
        if let open = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: first), open <= last,
           tokens[open] == .startOfScope("("), let close = formatter.endOfScope(at: open), close <= last
        {
            guard bindings[identifier]?.contains(where: { $0.scope.range.contains(first) }) != true else { return nil }
            let receiver = project.functionCallReceiver(at: first, in: formatter, visibleFrom: fileURL, declarations: declarations)
            current = receiver.flatMap { callType(name: identifier, receiver: $0, arguments: formatter.parseFunctionCallArguments(startOfScope: open).filter { $0.valueRange.upperBound <= last }.map(\.label)) }
            cursor = close
        } else if identifier == "self" || identifier == "Self" {
            let receiver = project.functionCallReceiver(at: first, in: formatter, visibleFrom: fileURL, declarations: declarations)
            let isStatic: Bool
            if case let .unqualified(_, value) = receiver {
                isStatic = value
            } else {
                isStatic = false
            }
            current = namespace.map { ResolvedType(name: $0, namespace: nil, isMetatype: identifier == "Self" || isStatic) }
        } else {
            current = bindingType(named: identifier, at: first, depth: depth + 1)
            if current == nil, bindings[identifier]?.contains(where: { $0.scope.range.contains(first) }) != true,
               let possibleType = type(named: identifier, namespace: namespace),
               let name = qualifiedName(for: possibleType), project.containsType(named: name, visibleFrom: fileURL)
            {
                current = ResolvedType(name: name, namespace: nil, isMetatype: true)
            }
        }
        while let dot = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: cursor), dot <= last {
            guard tokens[dot].isOperator("."),
                  let member = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: dot), member <= last,
                  tokens[member].isIdentifier, let owner = current, let ownerName = qualifiedName(for: owner) else { return nil }
            let memberName = tokens[member].string
            if let open = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: member), open <= last,
               tokens[open] == .startOfScope("("), let close = formatter.endOfScope(at: open), close <= last
            {
                let labels = formatter.parseFunctionCallArguments(startOfScope: open).filter { $0.valueRange.upperBound <= last }.map(\.label)
                current = callType(name: memberName, receiver: owner.isMetatype ? .type(ownerName) : .instance(type: ownerName), arguments: labels)
                cursor = close
            } else {
                current = memberType(owner: owner, name: memberName)
                if current == nil, owner.isMetatype, project.containsType(named: "\(ownerName).\(memberName)", visibleFrom: fileURL) {
                    current = ResolvedType(name: "\(ownerName).\(memberName)", namespace: nil, isMetatype: true)
                }
                if current == nil, owner.isMetatype,
                   enumCases(for: ResolvedType(name: ownerName, namespace: nil))?.contains(memberName) == true
                {
                    current = ResolvedType(name: ownerName, namespace: nil)
                }
                cursor = member
            }
        }
        return current
    }
}
