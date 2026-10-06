//
//  ProjectIndex.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 10/01/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation
#if canImport(FoundationXML)
    import FoundationXML
#endif

/// Immutable project information available to rules while formatting a file.
struct FormattingContext {
    static let empty = FormattingContext()

    let currentFileURL: URL?
    let projectIndex: ProjectIndex?

    init(currentFileURL: URL? = nil, projectIndex: ProjectIndex? = nil) {
        self.currentFileURL = currentFileURL
        self.projectIndex = projectIndex
    }
}

/// A compact, persistent summary of the declarations in a source file.
struct SourceFileIndex: Codable, Equatable {
    struct TypeDeclaration: Codable, Equatable {
        var name: String
        var visibility: String
    }

    struct FunctionDeclaration: Codable, Equatable {
        enum Kind: String, Codable {
            case function
            case initializer
            case subscriptDeclaration
        }

        var name: String
        var kind: Kind
        var declaringType: String?
        var isStatic: Bool
        var visibility: String
        var argumentLabels: [String?]
        var defaultArgumentIndices: [Int]
        var closureArgumentIndices: [Int]
        var autoclosureArgumentIndices: [Int]

        init(
            name: String,
            kind: Kind = .function,
            declaringType: String? = nil,
            isStatic: Bool = false,
            visibility: String = Visibility.internal.rawValue,
            argumentLabels: [String?],
            defaultArgumentIndices: [Int] = [],
            closureArgumentIndices: [Int] = [],
            autoclosureArgumentIndices: [Int]
        ) {
            self.name = name
            self.kind = kind
            self.declaringType = declaringType
            self.isStatic = isStatic
            self.visibility = visibility
            self.argumentLabels = argumentLabels
            self.defaultArgumentIndices = defaultArgumentIndices
            self.closureArgumentIndices = closureArgumentIndices
            self.autoclosureArgumentIndices = autoclosureArgumentIndices
        }

        private enum CodingKeys: CodingKey {
            case name
            case kind
            case declaringType
            case isStatic
            case visibility
            case argumentLabels
            case defaultArgumentIndices
            case closureArgumentIndices
            case autoclosureArgumentIndices
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            kind = try container.decodeIfPresent(Kind.self, forKey: .kind) ?? .function
            declaringType = try container.decodeIfPresent(String.self, forKey: .declaringType)
            isStatic = try container.decodeIfPresent(Bool.self, forKey: .isStatic) ?? false
            visibility = try container.decodeIfPresent(String.self, forKey: .visibility) ?? Visibility.internal.rawValue
            argumentLabels = try container.decode([String?].self, forKey: .argumentLabels)
            defaultArgumentIndices = try container.decodeIfPresent(
                [Int].self,
                forKey: .defaultArgumentIndices
            ) ?? []
            closureArgumentIndices = try container.decodeIfPresent(
                [Int].self,
                forKey: .closureArgumentIndices
            ) ?? []
            autoclosureArgumentIndices = try container.decode(
                [Int].self,
                forKey: .autoclosureArgumentIndices
            )
        }
    }

    struct FunctionReference: Codable, Hashable {
        var name: String
        /// `nil` when the function signature isn't explicit, as with a bare name or key path.
        var argumentLabels: [String?]?
        /// A receiver or enclosing type that can be established without type checking.
        var receiverType: String?
        /// Whether an unqualified reference is known to be in global scope.
        var isUnqualifiedGlobal: Bool

        init(
            name: String,
            argumentLabels: [String?]?,
            receiverType: String? = nil,
            isUnqualifiedGlobal: Bool = false
        ) {
            self.name = name
            self.argumentLabels = argumentLabels
            self.receiverType = receiverType
            self.isUnqualifiedGlobal = isUnqualifiedGlobal
        }

        private enum CodingKeys: CodingKey {
            case name
            case argumentLabels
            case receiverType
            case isUnqualifiedGlobal
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            argumentLabels = try container.decodeIfPresent([String?].self, forKey: .argumentLabels)
            receiverType = try container.decodeIfPresent(String.self, forKey: .receiverType)
            isUnqualifiedGlobal = try container.decodeIfPresent(
                Bool.self,
                forKey: .isUnqualifiedGlobal
            ) ?? false
        }
    }

    struct TypeMembers: Codable, Equatable {
        var typeName: String
        var instanceMembers: [String]
        var staticMembers: [String]
    }

    struct SymbolDeclaration: Codable, Equatable {
        var name: String
        var visibility: String
        var canBeRenamed: Bool
    }

    static let schemaVersion = 9

    var schemaVersion = SourceFileIndex.schemaVersion
    var contentHash: String
    var moduleIdentifiers: [String]
    var typeDeclarations: [TypeDeclaration]
    var functionDeclarations: [FunctionDeclaration]
    var typeMembers: [TypeMembers]
    var symbolDeclarations: [SymbolDeclaration]
    var functionReferences: [FunctionReference]

    init(
        contentHash: String,
        moduleIdentifiers: Set<String>,
        typeDeclarations: [TypeDeclaration],
        functionDeclarations: [FunctionDeclaration],
        typeMembers: [TypeMembers],
        symbolDeclarations: [SymbolDeclaration],
        functionReferences: [FunctionReference] = []
    ) {
        self.contentHash = contentHash
        self.moduleIdentifiers = moduleIdentifiers.sorted()
        self.typeDeclarations = typeDeclarations
        self.functionDeclarations = functionDeclarations
        self.typeMembers = typeMembers
        self.symbolDeclarations = symbolDeclarations
        self.functionReferences = functionReferences
    }

    private enum CodingKeys: CodingKey {
        case schemaVersion
        case contentHash
        case moduleIdentifiers
        case moduleIdentifier
        case typeDeclarations
        case functionDeclarations
        case typeMembers
        case symbolDeclarations
        case functionReferences
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        contentHash = try container.decode(String.self, forKey: .contentHash)
        if let identifiers = try container.decodeIfPresent([String].self, forKey: .moduleIdentifiers) {
            moduleIdentifiers = Set(identifiers).sorted()
        } else {
            moduleIdentifiers = try container.decodeIfPresent(String.self, forKey: .moduleIdentifier).map { [$0] } ?? []
        }
        typeDeclarations = try container.decode([TypeDeclaration].self, forKey: .typeDeclarations)
        functionDeclarations = try container.decodeIfPresent(
            [FunctionDeclaration].self,
            forKey: .functionDeclarations
        ) ?? []
        typeMembers = try container.decodeIfPresent([TypeMembers].self, forKey: .typeMembers) ?? []
        symbolDeclarations = try container.decodeIfPresent(
            [SymbolDeclaration].self,
            forKey: .symbolDeclarations
        ) ?? []
        functionReferences = try container.decodeIfPresent(
            [FunctionReference].self,
            forKey: .functionReferences
        ) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(contentHash, forKey: .contentHash)
        try container.encode(moduleIdentifiers, forKey: .moduleIdentifiers)
        try container.encode(typeDeclarations, forKey: .typeDeclarations)
        try container.encode(functionDeclarations, forKey: .functionDeclarations)
        try container.encode(typeMembers, forKey: .typeMembers)
        try container.encode(symbolDeclarations, forKey: .symbolDeclarations)
        try container.encode(functionReferences, forKey: .functionReferences)
    }
}

/// A read-only view of all source summaries discovered for a formatting run.
struct ProjectIndex {
    enum FunctionCallReceiver: Equatable {
        /// A call without an explicit receiver. `nil` represents a free function.
        case unqualified(declaringType: String?, isStatic: Bool)
        /// A call through `self` or another known instance.
        case instance(type: String)
        /// A call through `Self` or an explicit type name.
        case type(String)
    }

    struct ResolvedFunctionCall: Equatable {
        struct Match: Equatable {
            var declaration: SourceFileIndex.FunctionDeclaration
            var parameterIndices: [Int]
        }

        var matches: [Match]
    }

    struct MemberNamesByType: Equatable {
        static let empty = MemberNamesByType()

        var instance = [String: Set<String>]()
        var staticOrClass = [String: Set<String>]()
    }

    struct DeclarationNames: Equatable {
        var declared: Set<String>
        var eligible: Set<String>
        var protected: Set<String>
    }

    private struct TypeKey: Hashable {
        var moduleIdentifier: String
        var name: String
    }

    let files: [String: SourceFileIndex]
    let fingerprint: String
    private let typeVisibilities: [TypeKey: Set<String>]
    private let functionDeclarationsByModule: [String: [String: [SourceFileIndex.FunctionDeclaration]]]
    private let functionReferencesByModule: [String: [String: [SourceFileIndex.FunctionReference]]]
    private let memberNamesByModule: [String: MemberNamesByType]
    private let symbolDeclarationsByModule: [String: [SourceFileIndex.SymbolDeclaration]]

    init(files: [String: SourceFileIndex]) {
        self.files = files
        var typeVisibilities = [TypeKey: Set<String>]()
        var functionDeclarationsByModule = [String: [String: [SourceFileIndex.FunctionDeclaration]]]()
        var functionReferencesByModule = [String: [String: [SourceFileIndex.FunctionReference]]]()
        var memberNamesByModule = [String: MemberNamesByType]()
        var symbolDeclarationsByModule = [String: [SourceFileIndex.SymbolDeclaration]]()
        for file in files.values {
            for moduleIdentifier in file.moduleIdentifiers {
                for declaration in file.typeDeclarations {
                    let key = TypeKey(moduleIdentifier: moduleIdentifier, name: declaration.name)
                    typeVisibilities[key, default: []].insert(declaration.visibility)
                }
                for declaration in file.functionDeclarations {
                    functionDeclarationsByModule[moduleIdentifier, default: [:]][declaration.name, default: []]
                        .append(declaration)
                }
                for reference in file.functionReferences {
                    functionReferencesByModule[moduleIdentifier, default: [:]][reference.name, default: []]
                        .append(reference)
                }
                for members in file.typeMembers {
                    if !members.instanceMembers.isEmpty {
                        memberNamesByModule[moduleIdentifier, default: .empty]
                            .instance[members.typeName, default: []]
                            .formUnion(members.instanceMembers)
                    }
                    if !members.staticMembers.isEmpty {
                        memberNamesByModule[moduleIdentifier, default: .empty]
                            .staticOrClass[members.typeName, default: []]
                            .formUnion(members.staticMembers)
                    }
                }
                symbolDeclarationsByModule[moduleIdentifier, default: []].append(
                    contentsOf: file.symbolDeclarations
                )
            }
        }
        self.typeVisibilities = typeVisibilities
        self.functionDeclarationsByModule = functionDeclarationsByModule
        self.functionReferencesByModule = functionReferencesByModule
        self.memberNamesByModule = memberNamesByModule
        self.symbolDeclarationsByModule = symbolDeclarationsByModule
        let description = files.keys.sorted().compactMap { path -> String? in
            guard let file = files[path] else { return nil }
            let types = file.typeDeclarations
                .map { "\($0.name):\($0.visibility)" }
                .sorted()
                .joined(separator: ",")
            let functions = file.functionDeclarations
                .map { declaration in
                    let labels = declaration.argumentLabels.map { $0 ?? "_" }.joined(separator: ",")
                    let defaults = declaration.defaultArgumentIndices.map(String.init).joined(separator: ",")
                    let closures = declaration.closureArgumentIndices.map(String.init).joined(separator: ",")
                    let indices = declaration.autoclosureArgumentIndices.map(String.init).joined(separator: ",")
                    return "\(declaration.visibility):\(declaration.isStatic):\(declaration.kind.rawValue):" +
                        "\(declaration.declaringType ?? "").\(declaration.name)(\(labels)):\(defaults):\(closures):\(indices)"
                }
                .sorted()
                .joined(separator: ",")
            let members = file.typeMembers
                .map { members in
                    let instance = members.instanceMembers.sorted().joined(separator: ",")
                    let staticMembers = members.staticMembers.sorted().joined(separator: ",")
                    return "\(members.typeName):\(instance):\(staticMembers)"
                }
                .sorted()
                .joined(separator: ",")
            let symbolDeclarations = file.symbolDeclarations
                .map { "\($0.name):\($0.visibility):\($0.canBeRenamed)" }
                .sorted()
                .joined(separator: ",")
            let functionReferences = file.functionReferences
                .map { reference in
                    let labels = reference.argumentLabels?.map { $0 ?? "_" }.joined(separator: ",") ?? "*"
                    let receiver = reference.receiverType ?? (reference.isUnqualifiedGlobal ? "<global>" : "?")
                    return "\(receiver).\(reference.name)(\(labels))"
                }
                .sorted()
                .joined(separator: ",")
            return "\(file.moduleIdentifiers.joined(separator: ",")):\(types):\(functions):" +
                "\(members):\(symbolDeclarations):\(functionReferences)"
        }.joined(separator: ";")
        fingerprint = computeHash(description)
    }

    /// Whether a function is used as a value in any module containing the current file.
    func containsFunctionReference(
        named name: String,
        argumentLabels: [String?],
        declaringType: String?,
        declaringTypeKind: String?,
        visibility: Visibility,
        visibleFrom fileURL: URL
    ) -> Bool {
        let path = fileURL.standardizedFileURL.path
        let references: [SourceFileIndex.FunctionReference]
        if visibility <= .fileprivate {
            references = files[path]?.functionReferences.filter { $0.name == name } ?? []
        } else {
            guard let moduleIdentifiers = files[path]?.moduleIdentifiers else { return false }
            references = moduleIdentifiers.flatMap {
                functionReferencesByModule[$0]?[name] ?? []
            }
        }
        return references.contains { reference in
            guard reference.argumentLabels == nil || reference.argumentLabels == argumentLabels else {
                return false
            }
            guard let declaringType else { return true }
            if reference.isUnqualifiedGlobal {
                return false
            }
            guard let receiverType = reference.receiverType else {
                return true
            }
            if receiverType == declaringType ||
                declaringType.split(separator: ".").last.map(String.init) == receiverType
            {
                return true
            }
            return !["actor", "enum", "struct"].contains(declaringTypeKind)
        }
    }

    /// Whether the given type is unambiguously internal in every module containing the current file.
    func isInternalType(named name: String, from fileURL: URL) -> Bool {
        let path = fileURL.standardizedFileURL.path
        guard let moduleIdentifiers = files[path]?.moduleIdentifiers, !moduleIdentifiers.isEmpty else {
            return false
        }
        return moduleIdentifiers.allSatisfy { moduleIdentifier in
            let key = TypeKey(moduleIdentifier: moduleIdentifier, name: name)
            return typeVisibilities[key] == [Visibility.internal.rawValue]
        }
    }

    /// Whether the given type is declared in every module containing the current file.
    func containsType(named name: String, visibleFrom fileURL: URL) -> Bool {
        let path = fileURL.standardizedFileURL.path
        guard let moduleIdentifiers = files[path]?.moduleIdentifiers,
              !moduleIdentifiers.isEmpty
        else { return false }
        return moduleIdentifiers.allSatisfy { moduleIdentifier in
            typeVisibilities[TypeKey(moduleIdentifier: moduleIdentifier, name: name)] != nil
        }
    }

    /// Resolves a project-defined function call in every module containing the current file.
    ///
    /// Resolution is intentionally conservative. Calls with an unknown receiver or multiple
    /// matching overloads aren't resolved, since the index doesn't contain type information.
    func resolveFunctionCall(
        named name: String,
        receiver: FunctionCallReceiver,
        argumentLabels: [String?],
        visibleFrom fileURL: URL
    ) -> ResolvedFunctionCall? {
        guard let matchesByModule = functionCallMatches(
            named: name,
            receiver: receiver,
            argumentLabels: argumentLabels,
            visibleFrom: fileURL
        ), matchesByModule.allSatisfy({ $0.count == 1 })
        else { return nil }
        return ResolvedFunctionCall(matches: matchesByModule.compactMap(\.first))
    }

    private func functionCallMatches(
        named name: String,
        receiver: FunctionCallReceiver,
        argumentLabels: [String?],
        visibleFrom fileURL: URL
    ) -> [[ResolvedFunctionCall.Match]]? {
        let path = fileURL.standardizedFileURL.path
        guard let moduleIdentifiers = files[path]?.moduleIdentifiers,
              !moduleIdentifiers.isEmpty
        else { return nil }

        var matchesByModule = [[ResolvedFunctionCall.Match]]()
        for moduleIdentifier in moduleIdentifiers {
            let declarations = functionDeclarationsByModule[moduleIdentifier]?[name] ?? []
            func matches(for receiver: FunctionCallReceiver) -> [ResolvedFunctionCall.Match] {
                declarations.compactMap { declaration -> ResolvedFunctionCall.Match? in
                    guard declaration.kind == .function,
                          declaration.matches(receiver: receiver),
                          let parameterIndices = declaration.parameterIndices(matching: argumentLabels)
                    else { return nil }
                    return .init(declaration: declaration, parameterIndices: parameterIndices)
                }
            }
            var matching = matches(for: receiver)
            if matching.isEmpty,
               case .unqualified(declaringType: .some, isStatic: _) = receiver
            {
                matching = matches(for: .unqualified(declaringType: nil, isStatic: false))
            }
            guard !matching.isEmpty else { return nil }
            matchesByModule.append(matching)
        }
        return matchesByModule
    }

    /// Whether a same-module declaration makes removing the final closure label unambiguous.
    func supportsTrailingClosure(
        functionNamed name: String,
        receiver: FunctionCallReceiver,
        argumentLabels: [String?],
        visibleFrom fileURL: URL
    ) -> Bool {
        let path = fileURL.standardizedFileURL.path
        guard let moduleIdentifiers = files[path]?.moduleIdentifiers,
              !moduleIdentifiers.isEmpty,
              let finalArgumentIndex = argumentLabels.indices.last
        else { return false }

        guard let resolvedCall = resolveFunctionCall(
            named: name,
            receiver: receiver,
            argumentLabels: argumentLabels,
            visibleFrom: fileURL
        ), resolvedCall.matches.allSatisfy({ match in
            guard let parameterIndex = match.parameterIndices.last else { return false }
            return match.declaration.closureArgumentIndices.contains(parameterIndex)
        }) else { return false }

        return moduleIdentifiers.allSatisfy { moduleIdentifier in
            let allDeclarations = functionDeclarationsByModule[moduleIdentifier]?[name] ?? []
            func matching(_ receiver: FunctionCallReceiver) -> [SourceFileIndex.FunctionDeclaration] {
                allDeclarations.filter { declaration in
                    declaration.kind == .function && declaration.matches(receiver: receiver) &&
                        declaration.parameterIndices(
                            matching: argumentLabels,
                            ignoringLabelAt: finalArgumentIndex
                        ) != nil
                }
            }
            var declarations = matching(receiver)
            if declarations.isEmpty,
               case .unqualified(declaringType: .some, isStatic: _) = receiver
            {
                declarations = matching(.unqualified(declaringType: nil, isStatic: false))
            }
            return declarations.count == 1 && declarations[0].argumentLabels[
                declarations[0].parameterIndices(
                    matching: argumentLabels,
                    ignoringLabelAt: finalArgumentIndex
                )![finalArgumentIndex]
            ] == argumentLabels[finalArgumentIndex]
        }
    }

    /// Classifies the receiver of a call when it can be established without type checking.
    func functionCallReceiver(
        at identifierIndex: Int,
        in formatter: Formatter,
        visibleFrom fileURL: URL,
        declarations: [Declaration]? = nil
    ) -> FunctionCallReceiver? {
        let enclosingType = formatter.parseEnclosingType(containing: identifierIndex, declarations: declarations)
        let enclosingTypeName = enclosingType?.fullyQualifiedName
        if let dotIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: identifierIndex),
           formatter.tokens[dotIndex] == .operator(".", .infix)
        {
            guard let receiverIndex = formatter.index(
                of: .nonSpaceOrCommentOrLinebreak,
                before: dotIndex
            ) else { return nil }
            switch formatter.tokens[receiverIndex].string {
            case "self":
                return enclosingTypeName.map(FunctionCallReceiver.instance(type:))
            case "Self":
                return enclosingTypeName.map(FunctionCallReceiver.type)
            case let typeName where containsType(named: typeName, visibleFrom: fileURL):
                return .type(typeName)
            default:
                return nil
            }
        }

        guard let enclosingType else {
            return .unqualified(declaringType: nil, isStatic: false)
        }
        let containingDeclaration = enclosingType.body.declaration(containing: identifierIndex)
        let parentDeclarations = containingDeclaration.map {
            Array($0.parentDeclarations.reversed())
        } ?? []
        let declarations = (containingDeclaration.map { [$0] } ?? []) +
            parentDeclarations
        let isStatic = declarations.contains(where: {
            $0.modifiers.contains("static") || $0.modifiers.contains("class")
        })
        return .unqualified(declaringType: enclosingTypeName, isStatic: isStatic)
    }

    /// Whether an expression is nested inside a resolved `@autoclosure` argument.
    func isAutoclosureArgument(
        containing expressionIndex: Int,
        in formatter: Formatter,
        visibleFrom fileURL: URL
    ) -> Bool {
        var scopeIndex = expressionIndex
        while let startOfScope = formatter.index(of: .startOfScope, before: scopeIndex) {
            defer { scopeIndex = startOfScope }
            guard formatter.tokens[startOfScope] == .startOfScope("("),
                  let identifierIndex = formatter.parseFunctionIdentifier(
                      beforeStartOfScope: startOfScope
                  )
            else { continue }
            let arguments = formatter.parseFunctionCallArguments(startOfScope: startOfScope)
            guard let argumentIndex = arguments.firstIndex(where: { argument in
                argument.valueRange.contains(expressionIndex)
            }),
                let receiver = functionCallReceiver(
                    at: identifierIndex,
                    in: formatter,
                    visibleFrom: fileURL
                ),
                let matchesByModule = functionCallMatches(
                    named: formatter.tokens[identifierIndex].string,
                    receiver: receiver,
                    argumentLabels: arguments.map(\.label),
                    visibleFrom: fileURL
                )
            else { continue }
            if matchesByModule.joined().contains(where: { match in
                match.declaration.autoclosureArgumentIndices.contains(
                    match.parameterIndices[argumentIndex]
                )
            }) {
                return true
            }
        }
        return false
    }

    /// Project-defined members available in every module containing the current file, grouped by type.
    func memberNamesByType(visibleFrom fileURL: URL) -> MemberNamesByType {
        let path = fileURL.standardizedFileURL.path
        guard let moduleIdentifiers = files[path]?.moduleIdentifiers,
              let firstModule = moduleIdentifiers.first
        else {
            return .empty
        }
        return moduleIdentifiers.dropFirst().reduce(memberNamesByModule[firstModule] ?? .empty) {
            members, moduleIdentifier in
            let other = memberNamesByModule[moduleIdentifier] ?? .empty
            return MemberNamesByType(
                instance: members.instance.intersectingValues(with: other.instance),
                staticOrClass: members.staticOrClass.intersectingValues(with: other.staticOrClass)
            )
        }
    }

    /// Project declaration names that can participate in coordinated renaming.
    func declarationNames(upTo visibility: Visibility, visibleFrom fileURL: URL) -> DeclarationNames? {
        let path = fileURL.standardizedFileURL.path
        guard let moduleIdentifiers = files[path]?.moduleIdentifiers,
              let firstModule = moduleIdentifiers.first
        else { return nil }

        func names(in moduleIdentifier: String) -> DeclarationNames {
            let declarations = symbolDeclarationsByModule[moduleIdentifier] ?? []
            let declared = Set(declarations.map(\.name))
            let eligible = Set(declarations.compactMap { declaration -> String? in
                guard declaration.canBeRenamed,
                      let declarationVisibility = Visibility(rawValue: declaration.visibility),
                      declarationVisibility <= visibility
                else { return nil }
                return declaration.name
            })
            return DeclarationNames(
                declared: declared,
                eligible: eligible,
                protected: declared.subtracting(eligible)
            )
        }

        let first = names(in: firstModule)
        return moduleIdentifiers.dropFirst().reduce(first) { result, moduleIdentifier in
            let other = names(in: moduleIdentifier)
            return DeclarationNames(
                declared: result.declared.union(other.declared),
                eligible: result.eligible.intersection(other.eligible),
                protected: result.protected.union(other.protected)
            )
        }
    }
}

private extension SourceFileIndex.FunctionDeclaration {
    func matches(receiver: ProjectIndex.FunctionCallReceiver) -> Bool {
        switch receiver {
        case let .unqualified(declaringType, isStatic):
            return self.declaringType == declaringType && self.isStatic == isStatic
        case let .instance(type):
            return declaringType == type && !isStatic
        case let .type(type):
            return declaringType == type && isStatic
        }
    }

    func parameterIndices(
        matching callLabels: [String?],
        ignoringLabelAt ignoredCallIndex: Int? = nil
    ) -> [Int]? {
        func match(
            callIndex: Int,
            parameterIndex: Int,
            parameterIndices: [Int]
        ) -> [Int]? {
            guard callIndex < callLabels.count else {
                return argumentLabels.indices.dropFirst(parameterIndex)
                    .allSatisfy(defaultArgumentIndices.contains) ? parameterIndices : nil
            }
            guard parameterIndex < argumentLabels.count else { return nil }

            if callIndex == ignoredCallIndex || argumentLabels[parameterIndex] == callLabels[callIndex],
               let result = match(
                   callIndex: callIndex + 1,
                   parameterIndex: parameterIndex + 1,
                   parameterIndices: parameterIndices + [parameterIndex]
               )
            {
                return result
            }
            if defaultArgumentIndices.contains(parameterIndex) {
                return match(
                    callIndex: callIndex,
                    parameterIndex: parameterIndex + 1,
                    parameterIndices: parameterIndices
                )
            }
            return nil
        }
        return match(callIndex: 0, parameterIndex: 0, parameterIndices: [])
    }
}

/// Extracts the subset of declarations required by the initial project-aware rules.
func makeSourceFileIndex(
    from source: String,
    moduleIdentifiers: Set<String>
) -> SourceFileIndex {
    let formatter = Formatter(tokenize(source))
    var typeDeclarations = [SourceFileIndex.TypeDeclaration]()
    var functionDeclarations = [SourceFileIndex.FunctionDeclaration]()
    var typeMembers = [SourceFileIndex.TypeMembers]()
    var symbolDeclarations = [SourceFileIndex.SymbolDeclaration]()
    let declarations = formatter.parseDeclarations()
    let functionReferences = formatter.indexedFunctionReferences(declarations: declarations)
    declarations.forEachRecursiveDeclaration { declaration in
        let symbolNames = formatter.namesInDeclaration(at: declaration.keywordIndex)
            ?? declaration.name.map { [$0] }
            ?? []
        let canBeRenamed = formatter.declarationCanBeRenamed(
            declaration,
            upTo: nil
        )
        let symbolVisibility = formatter.effectiveVisibility(of: declaration).rawValue
        symbolDeclarations.append(contentsOf: symbolNames.map {
            .init(name: $0, visibility: symbolVisibility, canBeRenamed: canBeRenamed)
        })
        if ["func", "init", "subscript"].contains(declaration.keyword),
           let function = formatter.parseFunctionDeclaration(keywordIndex: declaration.keywordIndex)
        {
            symbolDeclarations.append(contentsOf: function.arguments.flatMap { argument in
                [argument.externalLabel, argument.internalLabel].compactMap { $0 }.map {
                    .init(name: $0, visibility: symbolVisibility, canBeRenamed: canBeRenamed)
                }
            })
        }

        if let typeDeclaration = declaration.asTypeDeclaration,
           let name = declaration.fullyQualifiedName
        {
            if typeDeclaration.keyword != "extension", typeDeclaration.keyword != "protocol" {
                let insidePublicExtension = declaration.parentDeclarations.contains(where: {
                    $0.keyword == "extension" && $0.visibility() == .public
                })
                if !insidePublicExtension {
                    typeDeclarations.append(.init(
                        name: name,
                        visibility: (declaration.visibility() ?? .internal).rawValue
                    ))
                }
            }

            var instanceMembers = Set<String>()
            var staticMembers = Set<String>()
            func collectMembers(in declarations: [Declaration]) {
                for declaration in declarations {
                    if case let .conditionalCompilation(conditionalCompilation) = declaration.kind {
                        collectMembers(in: conditionalCompilation.body)
                    } else if ["let", "var", "func"].contains(declaration.keyword),
                              !([declaration.visibility()] + declaration.parentDeclarations.compactMap { parent in
                                  parent.asTypeDeclaration?.visibility()
                              }).contains(where: { $0 == .private || $0 == .fileprivate }),
                              let names = formatter.namesInDeclaration(at: declaration.keywordIndex)
                    {
                        if declaration.modifiers.contains("static") || declaration.modifiers.contains("class") {
                            staticMembers.formUnion(names)
                        } else {
                            instanceMembers.formUnion(names)
                        }
                    }
                }
            }
            collectMembers(in: typeDeclaration.body)
            if !instanceMembers.isEmpty || !staticMembers.isEmpty {
                typeMembers.append(.init(
                    typeName: name,
                    instanceMembers: instanceMembers.sorted(),
                    staticMembers: staticMembers.sorted()
                ))
            }
        }

        let declarationVisibilities = [declaration.visibility()] + declaration.parentDeclarations.compactMap {
            $0.asTypeDeclaration?.visibility()
        }
        guard ["func", "init", "subscript"].contains(declaration.keyword),
              !declaration.parentDeclarations.contains(where: {
                  ["func", "init", "subscript"].contains($0.keyword)
              }),
              !declarationVisibilities.contains(where: {
                  $0 == .private || $0 == .fileprivate
              }),
              let function = formatter.parseFunctionDeclaration(keywordIndex: declaration.keywordIndex)
        else { return }
        let kind: SourceFileIndex.FunctionDeclaration.Kind
        let name: String
        switch declaration.keyword {
        case "init":
            kind = .initializer
            name = "init"
        case "subscript":
            kind = .subscriptDeclaration
            name = "subscript"
        default:
            guard let functionName = function.name else { return }
            kind = .function
            name = functionName
        }
        let defaultArgumentIndices = function.arguments.indices.filter { index in
            let argument = function.arguments[index]
            let endOfArgument = formatter.index(
                of: .delimiter(","),
                in: argument.type.range.upperBound + 1 ..< function.argumentsRange.upperBound
            ) ?? function.argumentsRange.upperBound
            return formatter.index(
                of: .operator("=", .infix),
                in: argument.type.range.upperBound + 1 ..< endOfArgument
            ) != nil
        }
        let autoclosureArgumentIndices = function.arguments.indices.filter { index in
            function.arguments[index].type.tokens.contains { $0.string == "@autoclosure" }
        }
        let closureArgumentIndices = function.arguments.indices.filter { index in
            !autoclosureArgumentIndices.contains(index) &&
                function.arguments[index].type.tokens.contains { $0.string == "->" }
        }
        functionDeclarations.append(.init(
            name: name,
            kind: kind,
            declaringType: declaration.parentType?.fullyQualifiedName,
            isStatic: declaration.modifiers.contains("static") || declaration.modifiers.contains("class"),
            visibility: (declaration.visibility() ?? .internal).rawValue,
            argumentLabels: function.arguments.map(\.externalLabel),
            defaultArgumentIndices: defaultArgumentIndices,
            closureArgumentIndices: closureArgumentIndices,
            autoclosureArgumentIndices: autoclosureArgumentIndices
        ))
    }
    formatter.clearDerivedCaches()
    return SourceFileIndex(
        contentHash: computeHash(source),
        moduleIdentifiers: moduleIdentifiers,
        typeDeclarations: typeDeclarations,
        functionDeclarations: functionDeclarations,
        typeMembers: typeMembers,
        symbolDeclarations: symbolDeclarations,
        functionReferences: functionReferences
    )
}

extension Formatter {
    /// Function-value references whose signatures can be identified without type checking.
    func indexedFunctionReferences(declarations: [Declaration]) -> [SourceFileIndex.FunctionReference] {
        var references = [SourceFileIndex.FunctionReference]()
        var explicitReferenceRanges = [ClosedRange<Int>]()
        var localDeclarations = [String: [Int]]()

        forEachToken(where: { ["let", "var", "func"].contains($0.string) }) { index, _ in
            guard declarationScope(at: index) == .local else { return }
            namesInDeclaration(at: index)?.forEach { name in
                localDeclarations[name, default: []].append(index)
            }
        }

        // An explicitly qualified function value, such as `someMethod(_:)`.
        forEach(.startOfScope("(")) { openParen, _ in
            guard let identifierIndex = parseFunctionIdentifier(beforeStartOfScope: openParen),
                  let closeParen = endOfScope(at: openParen)
            else {
                return
            }
            let significantTokens = tokens[(openParen + 1) ..< closeParen]
                .filter { !$0.isSpaceOrCommentOrLinebreak }
            var labels = [String?]()
            var pendingLabel: Token?
            for token in significantTokens {
                if let labelToken = pendingLabel {
                    guard token == .delimiter(":") else { return }
                    labels.append(labelToken.string == "_" ? nil : labelToken.string)
                    pendingLabel = nil
                } else {
                    guard token.isIdentifier || token.isKeyword else { return }
                    pendingLabel = token
                }
            }
            guard !labels.isEmpty, pendingLabel == nil else { return }
            explicitReferenceRanges.append(openParen ... closeParen)
            let receiver = indexedFunctionReferenceReceiver(
                at: identifierIndex,
                declarations: declarations
            )
            references.append(.init(
                name: tokens[identifierIndex].string,
                argumentLabels: labels,
                receiverType: receiver.type,
                isUnqualifiedGlobal: receiver.isGlobal
            ))
        }

        // A bare identifier can be inferred as a function value from context, as in
        // `values.map(transform)`. Without type information, conservatively treat any
        // non-type identifier that isn't plainly a call or member receiver as a reference.
        forEach(.identifier) { identifierIndex, token in
            guard !explicitReferenceRanges.contains(where: { $0.contains(identifierIndex) }),
                  !isTypePosition(at: identifierIndex)
            else { return }
            if let previousIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: identifierIndex),
               [.keyword("let"), .keyword("var")].contains(tokens[previousIndex])
            {
                return
            }
            if let nextIndex = index(of: .nonSpaceOrComment, after: identifierIndex) {
                guard tokens[nextIndex] != .startOfScope("("),
                      !tokens[nextIndex].isOperator("."),
                      tokens[nextIndex] != .delimiter(".")
                else { return }
            }
            let receiver = indexedFunctionReferenceReceiver(
                at: identifierIndex,
                declarations: declarations
            )
            guard receiver.isExplicit || !localDeclarationShadowsReference(
                named: token.string,
                at: identifierIndex,
                declarations: declarations,
                localDeclarations: localDeclarations[token.string] ?? []
            ) else { return }
            references.append(.init(
                name: token.string,
                argumentLabels: nil,
                receiverType: receiver.type,
                isUnqualifiedGlobal: receiver.isGlobal
            ))
        }

        // Key paths don't encode a callable signature, so conservatively protect every
        // overload with the same name as any of their components.
        forEach(.operator("\\", .prefix)) { backslashIndex, _ in
            var componentIndex = backslashIndex
            var isAfterDot = false
            while let nextIndex = index(of: .nonSpaceOrComment, after: componentIndex) {
                let token = tokens[nextIndex]
                guard !token.isLinebreak else { break }
                if token.isOperator(".") {
                    isAfterDot = true
                } else if isAfterDot, token.isIdentifier || token.isKeyword {
                    references.append(.init(
                        name: token.string,
                        argumentLabels: nil
                    ))
                    isAfterDot = false
                } else if nextIndex == index(of: .nonSpaceOrComment, after: backslashIndex),
                          token.isIdentifier || token.isKeyword
                {
                    // A root type in a fully qualified key path, such as `Type` in `\Type.value`.
                } else if token.isOperator("?") || token.isOperator("!") {
                    // Optional chaining between key-path components.
                } else {
                    break
                }
                componentIndex = nextIndex
            }
        }

        var seen = Set<SourceFileIndex.FunctionReference>()
        return references.filter { seen.insert($0).inserted }
    }

    func indexedFunctionReferenceReceiver(
        at identifierIndex: Int,
        declarations: [Declaration]
    ) -> (type: String?, isGlobal: Bool, isExplicit: Bool) {
        let enclosingType = parseEnclosingType(
            containing: identifierIndex,
            declarations: declarations
        )?.fullyQualifiedName
        guard let dotIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: identifierIndex),
              tokens[dotIndex].isOperator(".") || tokens[dotIndex] == .delimiter(".")
        else {
            return (enclosingType, enclosingType == nil, false)
        }
        guard let receiverIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: dotIndex) else {
            return (nil, false, true)
        }
        switch tokens[receiverIndex].string {
        case "self", "Self":
            return (enclosingType, false, true)
        default:
            return (nil, false, true)
        }
    }

    func localDeclarationShadowsReference(
        named name: String,
        at referenceIndex: Int,
        declarations: [Declaration],
        localDeclarations: [Int]
    ) -> Bool {
        guard let containingDeclaration = declarations.declaration(containing: referenceIndex),
              let functionDeclaration = ([containingDeclaration] + containingDeclaration.parentDeclarations)
              .first(where: { ["func", "init", "subscript"].contains($0.keyword) }),
              let function = parseFunctionDeclaration(keywordIndex: functionDeclaration.keywordIndex)
        else { return false }

        if function.arguments.contains(where: { $0.internalLabel == name }) {
            return true
        }

        var enclosingScopes = Set<Int>()
        var scopeSearchIndex = referenceIndex
        while let scopeIndex = startOfScope(at: scopeSearchIndex) {
            enclosingScopes.insert(scopeIndex)
            scopeSearchIndex = scopeIndex
        }

        for scopeIndex in enclosingScopes where tokens[scopeIndex] == .startOfScope("{") {
            if parseClosureArguments(at: scopeIndex)?.argumentIndices.contains(where: {
                tokens[$0].unescaped() == name
            }) == true {
                return true
            }
        }

        for declarationIndex in localDeclarations
            where declarationIndex > functionDeclaration.keywordIndex && declarationIndex < referenceIndex
        {
            if let declarationScopeIndex = startOfScope(at: declarationIndex),
               enclosingScopes.contains(declarationScopeIndex)
            {
                return true
            }
        }
        return false
    }
}

struct ProjectRoot: Hashable {
    enum Kind {
        case swiftPackage
        case xcodeProject
        case gitRepository
        case directory
    }

    var url: URL
    var kind: Kind
}

/// Finds the project root containing an input using filesystem markers where possible.
func projectRoot(for inputURL: URL) -> ProjectRoot {
    let manager = FileManager.default
    var isDirectory: ObjCBool = false
    let standardizedURL = inputURL.standardizedFileURL
    var directory = standardizedURL
    if !manager.fileExists(atPath: standardizedURL.path, isDirectory: &isDirectory) || !isDirectory.boolValue {
        directory.deleteLastPathComponent()
    }
    let fallback = directory

    while directory.path != directory.deletingLastPathComponent().path {
        if manager.fileExists(atPath: directory.appendingPathComponent("Package.swift").path) {
            return ProjectRoot(url: directory, kind: .swiftPackage)
        }
        if let contents = try? manager.contentsOfDirectory(atPath: directory.path),
           contents.contains(where: { $0.hasSuffix(".xcodeproj") || $0.hasSuffix(".xcworkspace") })
        {
            return ProjectRoot(url: directory, kind: .xcodeProject)
        }
        if manager.fileExists(atPath: directory.appendingPathComponent(".git").path) {
            return ProjectRoot(url: directory, kind: .gitRepository)
        }
        directory.deleteLastPathComponent()
    }
    return ProjectRoot(url: fallback, kind: .directory)
}

/// Best-effort discovery of Swift source files beneath a project root.
func discoverSourceFiles(in root: ProjectRoot) -> [URL] {
    var sourceRoots = [root.url]
    if root.kind == .xcodeProject {
        sourceRoots.append(contentsOf: xcodeProjectURLs(in: root.url).map { $0.deletingLastPathComponent() })
    }
    var filesByPath = [String: URL]()
    for sourceRoot in Set(sourceRoots.map(\.standardizedFileURL)) {
        for fileURL in discoverSourceFiles(beneath: sourceRoot) {
            filesByPath[fileURL.path] = fileURL
        }
    }
    return filesByPath.values.sorted { $0.path < $1.path }
}

private func discoverSourceFiles(beneath rootURL: URL) -> [URL] {
    let manager = FileManager.default
    let skippedDirectories: Set = [
        ".build", ".git", ".swiftpm", "DerivedData",
    ]
    guard let enumerator = manager.enumerator(
        at: rootURL,
        includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey],
        options: [.skipsHiddenFiles]
    ) else { return [] }

    var files = [URL]()
    for case let url as URL in enumerator {
        guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey]) else {
            continue
        }
        if values.isDirectory == true {
            if skippedDirectories.contains(url.lastPathComponent) || values.isSymbolicLink == true {
                enumerator.skipDescendants()
            }
        } else if values.isRegularFile == true, url.pathExtension == "swift" {
            files.append(url.standardizedFileURL)
        }
    }
    return files.sorted { $0.path < $1.path }
}

/// Provides conservative module identities from conventional project layout or Xcode target membership.
func moduleIdentifiers(for fileURLs: [URL], in root: ProjectRoot) -> [String: Set<String>] {
    let rootPath = root.url.standardizedFileURL.path

    switch root.kind {
    case .swiftPackage:
        return Dictionary(uniqueKeysWithValues: fileURLs.compactMap { fileURL in
            let filePath = fileURL.standardizedFileURL.path
            guard filePath.hasPrefix(rootPath + "/") else { return nil }
            let relativePath = String(filePath.dropFirst(rootPath.count + 1))
            let components = relativePath.split(separator: "/").map(String.init)
            guard components.count >= 3, ["Sources", "Tests"].contains(components[0]) else {
                return nil
            }
            return (filePath, ["\(rootPath):\(components[0]):\(components[1])"])
        })
    case .xcodeProject:
        let projectURLs = xcodeProjectURLs(in: root.url)
        var targetsByFile = [String: Set<String>]()
        for projectURL in projectURLs {
            let projectFileURL = projectURL.appendingPathComponent("project.pbxproj")
            let sourceRoot = projectURL.deletingLastPathComponent()
            guard let contents = try? String(contentsOf: projectFileURL),
                  let project = XcodeProject(
                      contents: contents,
                      sourceRoot: sourceRoot,
                      sourceFiles: fileURLs
                  )
            else { continue }
            let projectIdentifier = projectURL.standardizedFileURL.path
            for (filePath, targetIDs) in project.targetIDsByFile {
                targetsByFile[filePath, default: []].formUnion(targetIDs.map {
                    "\(projectIdentifier):\($0)"
                })
            }
        }
        return targetsByFile
    case .gitRepository, .directory:
        return Dictionary(uniqueKeysWithValues: fileURLs.compactMap { fileURL in
            let path = fileURL.standardizedFileURL.path
            return path.hasPrefix(rootPath + "/") ? (path, [rootPath]) : nil
        })
    }
}

private func xcodeProjectURLs(in rootURL: URL) -> [URL] {
    let manager = FileManager.default
    let contents = (try? manager.contentsOfDirectory(
        at: rootURL,
        includingPropertiesForKeys: nil
    )) ?? []
    var projectsByPath = [String: URL]()
    for projectURL in contents where projectURL.pathExtension == "xcodeproj" {
        let projectURL = projectURL.standardizedFileURL
        projectsByPath[projectURL.path] = projectURL
    }
    for workspaceURL in contents where workspaceURL.pathExtension == "xcworkspace" {
        let dataURL = workspaceURL.appendingPathComponent("contents.xcworkspacedata")
        guard let parser = XMLParser(contentsOf: dataURL) else { continue }
        let delegate = XcodeWorkspaceParser(rootURL: workspaceURL.deletingLastPathComponent())
        parser.delegate = delegate
        guard parser.parse() else { continue }
        for projectURL in delegate.projectURLs {
            projectsByPath[projectURL.path] = projectURL
        }
    }
    return projectsByPath.values.sorted { $0.path < $1.path }
}

private final class XcodeWorkspaceParser: NSObject, XMLParserDelegate {
    private let rootURL: URL
    private var groupURLs: [URL]
    var projectURLs = [URL]()

    init(rootURL: URL) {
        self.rootURL = rootURL.standardizedFileURL
        groupURLs = [self.rootURL]
    }

    func parser(
        _: XMLParser,
        didStartElement elementName: String,
        namespaceURI _: String?,
        qualifiedName _: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        if elementName == "Group" {
            let url = attributeDict["location"].flatMap(resolve) ?? groupURLs.last!
            groupURLs.append(url)
        } else if elementName == "FileRef",
                  let location = attributeDict["location"],
                  let url = resolve(location),
                  url.pathExtension == "xcodeproj"
        {
            projectURLs.append(url.standardizedFileURL)
        }
    }

    func parser(
        _: XMLParser,
        didEndElement elementName: String,
        namespaceURI _: String?,
        qualifiedName _: String?
    ) {
        if elementName == "Group", groupURLs.count > 1 {
            groupURLs.removeLast()
        }
    }

    private func resolve(_ location: String) -> URL? {
        guard let separator = location.firstIndex(of: ":") else { return nil }
        let type = String(location[..<separator])
        let path = String(location[location.index(after: separator)...])
        switch type {
        case "group":
            return groupURLs.last?.appendingPathComponent(path).standardizedFileURL
        case "container", "self":
            return rootURL.appendingPathComponent(path).standardizedFileURL
        case "absolute":
            return URL(fileURLWithPath: path).standardizedFileURL
        default:
            return nil
        }
    }
}

private extension Dictionary where Value == Set<String> {
    func intersectingValues(with other: Self) -> Self {
        reduce(into: [:]) { result, entry in
            let values = entry.value.intersection(other[entry.key] ?? [])
            if !values.isEmpty {
                result[entry.key] = values
            }
        }
    }
}

private struct XcodeProject {
    var targetIDsByFile: [String: Set<String>]

    init?(contents: String, sourceRoot: URL, sourceFiles: [URL]) {
        var parser = OpenStepPropertyListParser(contents)
        guard case let .dictionary(root) = parser.parse(),
              case let .dictionary(objects)? = root["objects"]
        else { return nil }

        func dictionary(for identifier: String) -> [String: OpenStepPropertyListValue]? {
            guard case let .dictionary(dictionary)? = objects[identifier] else { return nil }
            return dictionary
        }

        func string(_ key: String, in dictionary: [String: OpenStepPropertyListValue]) -> String? {
            guard case let .string(value)? = dictionary[key] else { return nil }
            return value
        }

        func strings(_ key: String, in dictionary: [String: OpenStepPropertyListValue]) -> [String] {
            guard case let .array(values)? = dictionary[key] else { return [] }
            return values.compactMap {
                guard case let .string(value) = $0 else { return nil }
                return value
            }
        }

        var parentGroupByChild = [String: String]()
        for (identifier, value) in objects {
            guard case let .dictionary(object) = value,
                  ["PBXGroup", "PBXVariantGroup"].contains(string("isa", in: object))
            else { continue }
            for child in strings("children", in: object) {
                parentGroupByChild[child] = identifier
            }
        }

        var cachedGroupURLs = [String: URL]()
        var resolvingGroups = Set<String>()
        func groupURL(for identifier: String) -> URL? {
            if let url = cachedGroupURLs[identifier] {
                return url
            }
            guard !resolvingGroups.contains(identifier),
                  let group = dictionary(for: identifier)
            else { return nil }
            resolvingGroups.insert(identifier)
            defer { resolvingGroups.remove(identifier) }

            let sourceTree = string("sourceTree", in: group) ?? "<group>"
            let baseURL: URL
            switch sourceTree {
            case "SOURCE_ROOT":
                baseURL = sourceRoot
            case "<group>":
                if let parent = parentGroupByChild[identifier] {
                    guard let parentURL = groupURL(for: parent) else { return nil }
                    baseURL = parentURL
                } else {
                    baseURL = sourceRoot
                }
            case "<absolute>":
                baseURL = URL(fileURLWithPath: "/")
            default:
                return nil
            }
            let path = string("path", in: group)
            let url = path.map { baseURL.appendingPathComponent($0) } ?? baseURL
            cachedGroupURLs[identifier] = url.standardizedFileURL
            return url.standardizedFileURL
        }

        var filePathsByReference = [String: String]()
        for (identifier, value) in objects {
            guard case let .dictionary(object) = value,
                  string("isa", in: object) == "PBXFileReference",
                  let path = string("path", in: object) ?? string("name", in: object)
            else { continue }
            let sourceTree = string("sourceTree", in: object) ?? "<group>"
            let fileURL: URL?
            switch sourceTree {
            case "SOURCE_ROOT":
                fileURL = sourceRoot.appendingPathComponent(path)
            case "<group>":
                fileURL = parentGroupByChild[identifier]
                    .flatMap(groupURL(for:))?
                    .appendingPathComponent(path)
            case "<absolute>":
                fileURL = URL(fileURLWithPath: path)
            default:
                fileURL = nil
            }
            if let fileURL {
                filePathsByReference[identifier] = fileURL.standardizedFileURL.path
            }
        }

        var fileReferenceByBuildFile = [String: String]()
        for (identifier, value) in objects {
            guard case let .dictionary(object) = value,
                  string("isa", in: object) == "PBXBuildFile",
                  let fileReference = string("fileRef", in: object)
            else { continue }
            fileReferenceByBuildFile[identifier] = fileReference
        }

        var result = [String: Set<String>]()
        var targetBySourcesBuildPhase = [String: String]()
        var targetsBySynchronizedGroup = [String: Set<String>]()
        for (targetID, value) in objects {
            guard case let .dictionary(target) = value,
                  string("isa", in: target) == "PBXNativeTarget"
            else { continue }
            for groupID in strings("fileSystemSynchronizedGroups", in: target) {
                targetsBySynchronizedGroup[groupID, default: []].insert(targetID)
            }
            for phaseID in strings("buildPhases", in: target) {
                guard let phase = dictionary(for: phaseID),
                      string("isa", in: phase) == "PBXSourcesBuildPhase"
                else { continue }
                targetBySourcesBuildPhase[phaseID] = targetID
                for buildFileID in strings("files", in: phase) {
                    guard let fileReference = fileReferenceByBuildFile[buildFileID],
                          let path = filePathsByReference[fileReference],
                          path.hasSuffix(".swift")
                    else { continue }
                    result[path, default: []].insert(targetID)
                }
            }
        }

        for (groupID, value) in objects {
            guard case let .dictionary(group) = value,
                  string("isa", in: group) == "PBXFileSystemSynchronizedRootGroup",
                  let groupURL = groupURL(for: groupID)
            else { continue }
            let groupPath = groupURL.standardizedFileURL.path
            var targetMembershipExceptions = [(path: String, targetID: String)]()
            for exceptionID in strings("exceptions", in: group) {
                guard let exception = dictionary(for: exceptionID) else { continue }
                let targetID: String?
                switch string("isa", in: exception) {
                case "PBXFileSystemSynchronizedBuildFileExceptionSet":
                    targetID = string("target", in: exception)
                case "PBXFileSystemSynchronizedGroupBuildPhaseMembershipExceptionSet":
                    targetID = string("buildPhase", in: exception).flatMap {
                        targetBySourcesBuildPhase[$0]
                    }
                default:
                    targetID = nil
                }
                guard let targetID else { continue }
                targetMembershipExceptions.append(contentsOf:
                    strings("membershipExceptions", in: exception).map { ($0, targetID) })
            }

            for fileURL in sourceFiles {
                let filePath = fileURL.standardizedFileURL.path
                guard filePath.hasPrefix(groupPath + "/") else { continue }
                let relativePath = String(filePath.dropFirst(groupPath.count + 1))
                var targetIDs = targetsBySynchronizedGroup[groupID] ?? []
                for exception in targetMembershipExceptions where
                    relativePath == exception.path || relativePath.hasPrefix(exception.path + "/")
                {
                    if targetIDs.contains(exception.targetID) {
                        targetIDs.remove(exception.targetID)
                    } else {
                        targetIDs.insert(exception.targetID)
                    }
                }
                result[filePath, default: []].formUnion(targetIDs)
            }
        }
        targetIDsByFile = result
    }
}

private indirect enum OpenStepPropertyListValue {
    case string(String)
    case array([OpenStepPropertyListValue])
    case dictionary([String: OpenStepPropertyListValue])
}

private struct OpenStepPropertyListParser {
    private enum Token: Equatable {
        case string(String)
        case symbol(Character)
    }

    private var tokens: [Token]
    private var index = 0

    init(_ source: String) {
        tokens = Self.tokenize(source)
    }

    mutating func parse() -> OpenStepPropertyListValue? {
        parseValue()
    }

    private mutating func parseValue() -> OpenStepPropertyListValue? {
        guard index < tokens.count else { return nil }
        switch tokens[index] {
        case .symbol("{"):
            index += 1
            var dictionary = [String: OpenStepPropertyListValue]()
            while index < tokens.count, tokens[index] != .symbol("}") {
                guard case let .string(key) = tokens[index] else { return nil }
                index += 1
                guard consume("="), let value = parseValue(), consume(";") else { return nil }
                dictionary[key] = value
            }
            guard consume("}") else { return nil }
            return .dictionary(dictionary)
        case .symbol("("):
            index += 1
            var array = [OpenStepPropertyListValue]()
            while index < tokens.count, tokens[index] != .symbol(")") {
                guard let value = parseValue() else { return nil }
                array.append(value)
                _ = consume(",")
            }
            guard consume(")") else { return nil }
            return .array(array)
        case let .string(value):
            index += 1
            return .string(value)
        case .symbol:
            return nil
        }
    }

    private mutating func consume(_ symbol: Character) -> Bool {
        guard index < tokens.count, tokens[index] == .symbol(symbol) else { return false }
        index += 1
        return true
    }

    private static func tokenize(_ source: String) -> [Token] {
        let characters = Array(source)
        var tokens = [Token]()
        var index = 0
        while index < characters.count {
            if characters[index].isWhitespace {
                index += 1
            } else if characters[index] == "/", index + 1 < characters.count,
                      characters[index + 1] == "/"
            {
                index += 2
                while index < characters.count, characters[index] != "\n" {
                    index += 1
                }
            } else if characters[index] == "/", index + 1 < characters.count,
                      characters[index + 1] == "*"
            {
                index += 2
                while index + 1 < characters.count,
                      !(characters[index] == "*" && characters[index + 1] == "/")
                {
                    index += 1
                }
                index = min(index + 2, characters.count)
            } else if characters[index] == "\"" {
                index += 1
                var value = ""
                while index < characters.count, characters[index] != "\"" {
                    if characters[index] == "\\", index + 1 < characters.count {
                        index += 1
                    }
                    value.append(characters[index])
                    index += 1
                }
                index = min(index + 1, characters.count)
                tokens.append(.string(value))
            } else if "{}()=;,".contains(characters[index]) {
                tokens.append(.symbol(characters[index]))
                index += 1
            } else {
                let start = index
                while index < characters.count,
                      !characters[index].isWhitespace,
                      !"{}()=;,\"".contains(characters[index])
                {
                    index += 1
                }
                tokens.append(.string(String(characters[start ..< index])))
            }
        }
        return tokens
    }
}
