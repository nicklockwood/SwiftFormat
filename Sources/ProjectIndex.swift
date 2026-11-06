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

enum ProjectContextFeature: String, Codable, Hashable {
    case declarations
    case functionReferences
    case symbolReferences
}

struct ProjectIndexDependency: Codable, Equatable {
    var features: Set<ProjectContextFeature>
    var fingerprint: String?
}

/// Builds a project index the first time a rule requests it. Concurrent callers
/// wait for the in-flight build instead of starting duplicate work.
final class ProjectIndexProvider {
    typealias Builder = (Set<ProjectContextFeature>) -> ProjectIndex?

    private let condition = NSCondition()
    private let builder: Builder
    private var index: ProjectIndex?
    private var availableFeatures = Set<ProjectContextFeature>()
    private var isBuilding = false

    init(builder: @escaping Builder) {
        self.builder = builder
    }

    func index(requiring features: Set<ProjectContextFeature>) -> ProjectIndex? {
        condition.lock()
        while isBuilding {
            condition.wait()
        }
        if features.isSubset(of: availableFeatures) {
            let index = index
            condition.unlock()
            return index
        }
        isBuilding = true
        let requestedFeatures = availableFeatures.union(features)
        condition.unlock()

        let index = builder(requestedFeatures)

        condition.lock()
        self.index = index
        availableFeatures = requestedFeatures
        isBuilding = false
        condition.broadcast()
        condition.unlock()
        return index
    }
}

/// Tracks the project information actually requested while formatting one file.
final class ProjectIndexAccess {
    private let provider: ProjectIndexProvider?
    private(set) var dependency: ProjectIndexDependency?
    private(set) var lastIndex: ProjectIndex?

    init(provider: ProjectIndexProvider?) {
        self.provider = provider
    }

    func index(requiring features: Set<ProjectContextFeature>) -> ProjectIndex? {
        let index = provider?.index(requiring: features)
        lastIndex = index
        let requestedFeatures = dependency?.features.union(features) ?? features
        dependency = ProjectIndexDependency(
            features: requestedFeatures,
            fingerprint: index?.fingerprint(for: requestedFeatures)
        )
        return index
    }
}

/// Lazily builds the current file's function-reference index if a rule needs it.
final class SourceFileIndexAccess {
    private let builder: () -> SourceFileIndex?
    private(set) var index: SourceFileIndex?
    private(set) var wasRequested = false

    init(index: SourceFileIndex? = nil, builder: @escaping () -> SourceFileIndex? = { nil }) {
        self.index = index
        self.builder = builder
    }

    func get(preferredIndex: SourceFileIndex? = nil) -> SourceFileIndex? {
        wasRequested = true
        if index == nil {
            index = preferredIndex ?? builder()
        }
        return index
    }
}

/// Project information available to rules while formatting a file.
struct FormattingContext {
    static let empty = FormattingContext()

    let currentFileURL: URL?
    let projectIndexAccess: ProjectIndexAccess
    let sourceFileIndexAccess: SourceFileIndexAccess

    init(
        currentFileURL: URL? = nil,
        projectIndexProvider: ProjectIndexProvider? = nil,
        sourceFileIndex: SourceFileIndex? = nil
    ) {
        self.currentFileURL = currentFileURL
        projectIndexAccess = ProjectIndexAccess(provider: projectIndexProvider)
        sourceFileIndexAccess = SourceFileIndexAccess(index: sourceFileIndex)
    }

    init(
        currentFileURL: URL?,
        projectIndexAccess: ProjectIndexAccess,
        sourceFileIndexAccess: SourceFileIndexAccess = SourceFileIndexAccess()
    ) {
        self.currentFileURL = currentFileURL
        self.projectIndexAccess = projectIndexAccess
        self.sourceFileIndexAccess = sourceFileIndexAccess
    }

    init(currentFileURL: URL? = nil, projectIndex: ProjectIndex?) {
        self.currentFileURL = currentFileURL
        projectIndexAccess = ProjectIndexAccess(provider: projectIndex.map { projectIndex in
            ProjectIndexProvider { _ in projectIndex }
        })
        sourceFileIndexAccess = SourceFileIndexAccess()
    }
}

/// A compact, persistent summary of the declarations in a source file.
struct SourceFileIndex: Codable, Equatable {
    struct TypeDeclaration: Codable, Equatable {
        var name: String
        var visibility: String
        var isGeneric: Bool = false
        var isResultBuilder: Bool = false
        var isDynamicMemberLookup: Bool = false
        var isNoncopyable: Bool = false
        var enumCases: [String]? = nil
        var hasUnknownEnumCases: Bool? = nil
        var enumCasePayloads: [String: [String]]? = nil
        var genericParameters: [String] = []
    }

    struct ClassInheritance: Codable, Equatable {
        var className: String
        var inheritedTypes: [String]
    }

    /// The conformances and superclass declared by a type or extension.
    struct TypeConformance: Codable, Equatable {
        var typeName: String
        var conformances: [String]
    }

    /// Full parent spellings are needed when projecting a specialized receiver onto an ancestor.
    struct InheritanceDeclaration: Codable, Equatable {
        var owner: String
        var types: [String]
        var associatedTypeNames: [String] = []
        var propertyRequirements: [String] = []
        var isExtension: Bool? = nil
        var hasUnresolvedConstraints: Bool? = nil
    }

    struct ProtocolDeclaration: Codable, Equatable {
        var name: String
        var inheritedProtocols: [String]
        var attributedRequirements: [AttributedRequirement] = []
        var nestedTypeNames: [String] = []
        var visibility: String = Visibility.internal.rawValue
        var hasRequirements: Bool? = nil
    }

    struct AttributedRequirement: Codable, Equatable {
        var name: String
        var kind: String
        var isStatic: Bool
        var argumentLabels: [String?]
        var attributes: [String]
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
        var attributedArgumentIndices: [Int]
        var returnType: String?
        var isFailable: Bool
        var argumentTypes: [String]?
        var symbolArgumentTypes: [String]?
        var symbolReturnType: String?
        var symbolHasUnresolvedConstraints: Bool?
        var genericParameters: [String]
        var genericConstraints: [String: [String]]? = nil

        init(
            name: String,
            kind: Kind = .function,
            declaringType: String? = nil,
            isStatic: Bool = false,
            visibility: String = Visibility.internal.rawValue,
            argumentLabels: [String?],
            defaultArgumentIndices: [Int] = [],
            closureArgumentIndices: [Int] = [],
            autoclosureArgumentIndices: [Int],
            attributedArgumentIndices: [Int] = [],
            returnType: String? = nil,
            isFailable: Bool = false,
            argumentTypes: [String]? = nil,
            symbolArgumentTypes: [String]? = nil,
            symbolReturnType: String? = nil,
            symbolHasUnresolvedConstraints: Bool? = nil,
            genericParameters: [String] = []
        ) {
            self.name = name
            self.kind = kind
            self.declaringType = declaringType
            self.isStatic = isStatic
            self.visibility = visibility
            self.argumentLabels = argumentLabels
            self.defaultArgumentIndices = defaultArgumentIndices
            self.closureArgumentIndices = closureArgumentIndices
            self.attributedArgumentIndices = attributedArgumentIndices
            self.autoclosureArgumentIndices = autoclosureArgumentIndices
            self.returnType = returnType
            self.isFailable = isFailable
            self.argumentTypes = argumentTypes
            self.symbolArgumentTypes = symbolArgumentTypes
            self.symbolReturnType = symbolReturnType
            self.symbolHasUnresolvedConstraints = symbolHasUnresolvedConstraints
            self.genericParameters = genericParameters
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
        var kind: String? = nil
    }

    struct PropertyDeclaration: Codable, Equatable {
        var name: String
        var declaringType: String
        var type: String?
        var isStatic: Bool = false
        var visibility: String? = nil
        var hasUnresolvedConstraints: Bool? = nil
        var initializer: String? = nil
    }

    struct TypeAliasDeclaration: Codable, Equatable {
        var name: String
        var type: String
        var genericParameters: [String] = []
        var visibility: String = Visibility.internal.rawValue
        var hasUnresolvedConstraints: Bool? = nil
    }

    static let cacheVersion = 28

    var contentHash: String
    var moduleIdentifiers: [String]
    var moduleNames: [String: String]
    var imports: [String]
    var exportedImports: [String]
    var implementationOnlyImports: [String]
    var typeDeclarations: [TypeDeclaration]
    var classInheritances: [ClassInheritance]
    var typeConformances: [TypeConformance]
    var protocolDeclarations: [ProtocolDeclaration]
    var symbolProtocolDeclarations: [ProtocolDeclaration]?
    var inheritanceDeclarations: [InheritanceDeclaration]?
    var functionDeclarations: [FunctionDeclaration]
    var symbolFunctionDeclarations: [FunctionDeclaration]?
    var propertyDeclarations: [PropertyDeclaration]
    var typeAliasDeclarations: [TypeAliasDeclaration]
    var typeMembers: [TypeMembers]
    var symbolDeclarations: [SymbolDeclaration]
    var functionReferences: [FunctionReference]
    var symbolReferences: [String]
    var includesFunctionReferences: Bool
    var includesSymbolReferences: Bool

    init(
        contentHash: String,
        moduleIdentifiers: Set<String>,
        moduleNames: [String: String] = [:],
        imports: [String] = [],
        exportedImports: [String] = [],
        implementationOnlyImports: [String] = [],
        typeDeclarations: [TypeDeclaration],
        classInheritances: [ClassInheritance] = [],
        typeConformances: [TypeConformance] = [],
        protocolDeclarations: [ProtocolDeclaration] = [],
        functionDeclarations: [FunctionDeclaration],
        propertyDeclarations: [PropertyDeclaration] = [],
        typeAliasDeclarations: [TypeAliasDeclaration] = [],
        typeMembers: [TypeMembers],
        symbolDeclarations: [SymbolDeclaration],
        functionReferences: [FunctionReference] = [],
        symbolReferences: [String] = [],
        includesFunctionReferences: Bool = true,
        includesSymbolReferences: Bool = true,
        symbolFunctionDeclarations: [FunctionDeclaration]? = nil,
        symbolProtocolDeclarations: [ProtocolDeclaration]? = nil,
        inheritanceDeclarations: [InheritanceDeclaration]? = nil
    ) {
        self.contentHash = contentHash
        self.moduleIdentifiers = moduleIdentifiers.sorted()
        self.moduleNames = moduleNames
        self.imports = imports.sorted()
        self.exportedImports = exportedImports.sorted()
        self.implementationOnlyImports = implementationOnlyImports.sorted()
        self.typeDeclarations = typeDeclarations
        self.classInheritances = classInheritances
        self.typeConformances = typeConformances
        self.protocolDeclarations = protocolDeclarations
        self.symbolProtocolDeclarations = symbolProtocolDeclarations
        self.inheritanceDeclarations = inheritanceDeclarations
        self.functionDeclarations = functionDeclarations
        self.symbolFunctionDeclarations = symbolFunctionDeclarations
        self.propertyDeclarations = propertyDeclarations
        self.typeAliasDeclarations = typeAliasDeclarations
        self.typeMembers = typeMembers
        self.symbolDeclarations = symbolDeclarations
        self.functionReferences = functionReferences
        self.symbolReferences = symbolReferences
        self.includesFunctionReferences = includesFunctionReferences
        self.includesSymbolReferences = includesSymbolReferences
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

    enum ConformanceRequirementStatus: Equatable {
        /// A protocol or superclass declares a matching function.
        case required
        /// Every protocol and superclass is known, and none declares a matching function.
        case notRequired
        /// A protocol or superclass isn't a unique project declaration, so its requirements aren't known.
        case unknown
    }

    private struct TypeKey: Hashable {
        var moduleIdentifier: String
        var name: String
    }

    let files: [String: SourceFileIndex]
    let fingerprint: String
    private let declarationsFingerprint: String
    private let functionReferencesFingerprint: String
    private let symbolReferencesFingerprint: String
    private let typeSourceFilesByModule: [TypeKey: Set<String>]
    private let typeVisibilitiesByModule: [TypeKey: [(source: String, visibility: String)]]
    private let propertySourceFilesByModule: [TypeKey: Set<String>]
    private let symbolFunctionsByModule: [String: [String: [FunctionSymbol]]]
    private let symbolPropertiesByModule: [String: [String: [PropertySymbol]]]
    private let importsByModule: [String: Set<String>]
    private let memberImportsByModuleName: [String: Set<String>]
    private let exportsByModuleName: [String: Set<String>]
    private let moduleNamesByIdentifier: [String: String]
    private let modulesByName: [String: Set<String>]
    private let typeVisibilities: [TypeKey: Set<String>]
    private let aliasesByModule: [TypeKey: [SourceFileIndex.TypeAliasDeclaration]]
    private let typesByModule: [TypeKey: [SourceFileIndex.TypeDeclaration]]
    private let protocolsByModule: Set<TypeKey>
    private let protocolDeclarationsByModule: [TypeKey: [SourceFileIndex.ProtocolDeclaration]]
    private let symbolProtocolDeclarationsByModule: [TypeKey: [SourceFileIndex.ProtocolDeclaration]]
    private let conformancesByModule: [TypeKey: Set<String>]
    private let conformanceSourcesByModule: [TypeKey: [(source: URL, parents: [String])]]
    private let inheritanceDeclarationsByModule: [TypeKey: [(declaration: SourceFileIndex.InheritanceDeclaration, source: URL)]]
    private let conformanceOwnersByModule: [String: [TypeKey]]
    private let propertiesByModule: [TypeKey: [SourceFileIndex.PropertyDeclaration]]
    private let staticPropertiesByModule: [TypeKey: [SourceFileIndex.PropertyDeclaration]]
    private let inheritedClassNamesByModule: [String: Set<String>]
    private let inheritedClassNames: Set<String>
    private let inheritedNamesByTypeName: [String: Set<String>]
    private let typeAndProtocolCountsByModule: [TypeKey: Int]
    private let functionDeclarationsByModule: [String: [String: [SourceFileIndex.FunctionDeclaration]]]
    private let functionReferencesByModule: [String: [String: [SourceFileIndex.FunctionReference]]]
    private let memberNamesByModule: [String: MemberNamesByType]
    private let dynamicMemberLookupTypesByModule: [String: Set<String>]
    private let noncopyableTypesByModule: [String: Set<String>]
    private let symbolDeclarationsByModule: [String: [SourceFileIndex.SymbolDeclaration]]
    private let symbolDeclarationCountsByName: [String: Int]
    private let typeDeclarationCountsByShortName: [String: Int]
    private let typeAliasDeclarationCountsByShortName: [String: Int]
    private let symbolDeclarationNames: Set<String>

    /// All index inputs are immutable. Cache pure lookups across files without holding a lock
    /// while resolving recursive aliases or conformances; duplicate concurrent work is harmless.
    private final class LookupCache<Key: Hashable, Value> {
        private let lock = NSLock()
        private var values = [Key: Value]()

        func value(for key: Key, compute: () -> Value) -> Value {
            lock.lock()
            if let value = values[key] {
                lock.unlock()
                return value
            }
            lock.unlock()
            let value = compute()
            lock.lock()
            values[key] = .some(value)
            lock.unlock()
            return value
        }
    }

    private struct MemberOwnerKey: Hashable {
        var name: String
        var sourcePath: String
        var module: String?
    }

    private struct StandardMemberKey: Hashable {
        var name: String
        var types: [String]
        var sourcePath: String
    }

    private struct InheritedFunctionKey: Hashable {
        var name: String
        var owner: TypeKey
        var sourcePath: String
        var callerPath: String
        var includingProperties: Bool
    }

    private struct InheritanceKey: Hashable {
        var owner: TypeKey
        var callerPath: String
    }

    private typealias InheritanceEntry = (declaration: SourceFileIndex.InheritanceDeclaration, source: URL)
    private let inheritanceEntryCache = LookupCache<InheritanceKey, [InheritanceEntry]?>()
    private typealias MemberOwner = (keys: Set<TypeKey>, constrained: Bool)
    private let memberModuleCache = LookupCache<String, Set<String>>()
    private let memberOwnerCache = LookupCache<MemberOwnerKey, MemberOwner?>()
    private let standardMemberCache = LookupCache<StandardMemberKey, Bool>()
    private let inheritedFunctionCache = LookupCache<InheritedFunctionKey, Bool>()

    init(files: [String: SourceFileIndex]) {
        self.files = files
        var moduleNamesByIdentifier = [String: String]()
        var modulesByName = [String: Set<String>]()
        var exportsByModuleName = [String: Set<String>]()
        var importsByModule = [String: Set<String>]()
        var memberImportsByModuleName = [String: Set<String>]()
        for file in files.values {
            for identifier in file.moduleIdentifiers {
                importsByModule[identifier, default: []].formUnion(file.imports)
            }
            for (identifier, name) in file.moduleNames {
                modulesByName[name, default: []].insert(identifier)
                moduleNamesByIdentifier[identifier] = name
                exportsByModuleName[name, default: []].formUnion(file.exportedImports)
                memberImportsByModuleName[name, default: []].formUnion(Set(file.imports).subtracting(file.implementationOnlyImports))
            }
        }
        self.modulesByName = modulesByName
        self.moduleNamesByIdentifier = moduleNamesByIdentifier
        self.exportsByModuleName = exportsByModuleName
        self.importsByModule = importsByModule
        self.memberImportsByModuleName = memberImportsByModuleName
        var typeVisibilities = [TypeKey: Set<String>]()
        var inheritedClassNamesByModule = [String: Set<String>]()
        var typeAndProtocolCountsByModule = [TypeKey: Int]()
        var functionDeclarationsByModule = [String: [String: [SourceFileIndex.FunctionDeclaration]]]()
        var functionReferencesByModule = [String: [String: [SourceFileIndex.FunctionReference]]]()
        var memberNamesByModule = [String: MemberNamesByType]()
        var dynamicMemberLookupTypesByModule = [String: Set<String>]()
        var noncopyableTypesByModule = [String: Set<String>]()
        var symbolDeclarationsByModule = [String: [SourceFileIndex.SymbolDeclaration]]()
        // Resolve extension targets across files before trusting their return types.
        // A generic parameter can shadow a nominal type with the same name.
        var typeSourceFilesByModule = [TypeKey: Set<String>]()
        var typeVisibilitiesByModule = [TypeKey: [(source: String, visibility: String)]]()
        var propertySourceFilesByModule = [TypeKey: Set<String>]()
        var symbolFunctionsByModule = [String: [String: [FunctionSymbol]]]()
        var symbolPropertiesByModule = [String: [String: [PropertySymbol]]]()
        var aliasesByModule = [TypeKey: [SourceFileIndex.TypeAliasDeclaration]]()
        var typesByModule = [TypeKey: [SourceFileIndex.TypeDeclaration]]()
        var protocolsByModule = Set<TypeKey>()
        var protocolDeclarationsByModule = [TypeKey: [SourceFileIndex.ProtocolDeclaration]]()
        var symbolProtocolDeclarationsByModule = [TypeKey: [SourceFileIndex.ProtocolDeclaration]]()
        var inheritanceDeclarationsByModule = [TypeKey: [(declaration: SourceFileIndex.InheritanceDeclaration, source: URL)]]()
        var conformancesByModule = [TypeKey: Set<String>]()
        var conformanceSourcesByModule = [TypeKey: [(source: URL, parents: [String])]]()
        var propertiesByModule = [TypeKey: [SourceFileIndex.PropertyDeclaration]]()
        var staticPropertiesByModule = [TypeKey: [SourceFileIndex.PropertyDeclaration]]()
        for (path, file) in files {
            for module in file.moduleIdentifiers {
                for function in file.symbolFunctionDeclarations ?? file.functionDeclarations {
                    symbolFunctionsByModule[module, default: [:]][function.name, default: []].append(
                        FunctionSymbol(declaration: function, fileURL: URL(fileURLWithPath: path))
                    )
                }
                let typeVisibilities = file.typeDeclarations.map { ($0.name, $0.visibility) } +
                    (file.symbolProtocolDeclarations ?? file.protocolDeclarations).map { ($0.name, $0.visibility) } + file.typeAliasDeclarations.map { ($0.name, $0.visibility) }
                for (name, visibility) in typeVisibilities {
                    let key = TypeKey(moduleIdentifier: module, name: name)
                    typeSourceFilesByModule[key, default: []].insert(path)
                    typeVisibilitiesByModule[key, default: []].append((path, visibility))
                }
                for property in file.propertyDeclarations {
                    symbolPropertiesByModule[module, default: [:]][property.name, default: []].append(
                        PropertySymbol(declaration: property, fileURL: URL(fileURLWithPath: path))
                    )
                    propertySourceFilesByModule[TypeKey(moduleIdentifier: module, name: "\(property.declaringType).\(property.name)"), default: []].insert(path)
                }
                for alias in file.typeAliasDeclarations {
                    aliasesByModule[TypeKey(moduleIdentifier: module, name: alias.name), default: []].append(alias)
                }
                for declaration in file.protocolDeclarations {
                    let key = TypeKey(moduleIdentifier: module, name: declaration.name)
                    protocolDeclarationsByModule[key, default: []].append(declaration)
                }
                for declaration in file.symbolProtocolDeclarations ?? file.protocolDeclarations {
                    let key = TypeKey(moduleIdentifier: module, name: declaration.name)
                    protocolsByModule.insert(key)
                    symbolProtocolDeclarationsByModule[key, default: []].append(declaration)
                    if !["private", "fileprivate"].contains(declaration.visibility) {
                        conformancesByModule[key, default: []].formUnion(declaration.inheritedProtocols)
                    }
                    conformanceSourcesByModule[key, default: []].append((URL(fileURLWithPath: path), declaration.inheritedProtocols))
                }
                for declaration in file.inheritanceDeclarations ?? [] {
                    let key = TypeKey(moduleIdentifier: module, name: declaration.owner)
                    inheritanceDeclarationsByModule[key, default: []].append((declaration, URL(fileURLWithPath: path)))
                }
                for conformance in file.typeConformances {
                    let key = TypeKey(moduleIdentifier: module, name: conformance.typeName)
                    conformancesByModule[key, default: []].formUnion(conformance.conformances)
                    conformanceSourcesByModule[key, default: []].append((URL(fileURLWithPath: path), conformance.conformances))
                }
                for property in file.propertyDeclarations {
                    let key = TypeKey(moduleIdentifier: module, name: "\(property.declaringType).\(property.name)")
                    propertiesByModule[key, default: []].append(property)
                    if property.isStatic {
                        staticPropertiesByModule[key, default: []].append(property)
                    }
                }
                for type in file.typeDeclarations {
                    typesByModule[TypeKey(moduleIdentifier: module, name: type.name), default: []].append(type)
                    if type.isDynamicMemberLookup {
                        dynamicMemberLookupTypesByModule[module, default: []].insert(type.name)
                    }
                    if type.isNoncopyable {
                        noncopyableTypesByModule[module, default: []].insert(type.name.unqualifiedTypeName)
                    }
                }
            }
        }
        for file in files.values {
            for moduleIdentifier in file.moduleIdentifiers {
                for declaration in file.typeDeclarations {
                    let key = TypeKey(moduleIdentifier: moduleIdentifier, name: declaration.name)
                    typeVisibilities[key, default: []].insert(declaration.visibility)
                }
                for name in file.typeDeclarations.map(\.name) + file.protocolDeclarations.map(\.name) {
                    let key = TypeKey(moduleIdentifier: moduleIdentifier, name: name.unqualifiedTypeName)
                    typeAndProtocolCountsByModule[key, default: 0] += 1
                }
                for inheritance in file.classInheritances {
                    for inheritedType in inheritance.inheritedTypes {
                        inheritedClassNamesByModule[moduleIdentifier, default: []].insert(inheritedType)
                        if let unqualifiedName = inheritedType.split(separator: ".").last {
                            inheritedClassNamesByModule[moduleIdentifier, default: []].insert(
                                String(unqualifiedName)
                            )
                        }
                    }
                }
                for var declaration in file.functionDeclarations {
                    if let owner = declaration.declaringType {
                        let types = typesByModule[TypeKey(moduleIdentifier: moduleIdentifier, name: owner)] ?? []
                        if types.count != 1 || types[0].isGeneric {
                            declaration.returnType = nil
                            declaration.argumentTypes = nil
                        }
                    }
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
        var symbolDeclarationCountsByName = [String: Int]()
        var typeDeclarationCountsByShortName = [String: Int]()
        var typeAliasDeclarationCountsByShortName = [String: Int]()
        var inheritedNamesByTypeName = [String: Set<String>]()
        for file in files.values {
            for declaration in file.symbolDeclarations where declaration.kind != "extension" && declaration.kind != "import" {
                symbolDeclarationCountsByName[declaration.name, default: 0] += 1
            }
            for declaration in file.typeDeclarations {
                let name = declaration.name.split(separator: ".").last.map(String.init) ?? declaration.name
                typeDeclarationCountsByShortName[name, default: 0] += 1
            }
            for declaration in file.typeAliasDeclarations {
                typeAliasDeclarationCountsByShortName[declaration.name.unqualifiedTypeName, default: 0] += 1
            }
            // A type can be extended with more conformances in any file, so these aren't scoped to a module.
            for conformance in file.typeConformances {
                inheritedNamesByTypeName[conformance.typeName.unqualifiedTypeName, default: []]
                    .formUnion(conformance.conformances.inheritedNamesToResolve)
            }
            for declaration in file.protocolDeclarations {
                inheritedNamesByTypeName[declaration.name.unqualifiedTypeName, default: []]
                    .formUnion(declaration.inheritedProtocols.inheritedNamesToResolve)
            }
        }
        self.symbolFunctionsByModule = symbolFunctionsByModule
        self.symbolPropertiesByModule = symbolPropertiesByModule
        self.typeSourceFilesByModule = typeSourceFilesByModule
        self.typeVisibilitiesByModule = typeVisibilitiesByModule
        self.propertySourceFilesByModule = propertySourceFilesByModule
        self.typesByModule = typesByModule
        self.aliasesByModule = aliasesByModule
        self.protocolsByModule = protocolsByModule
        self.protocolDeclarationsByModule = protocolDeclarationsByModule
        self.symbolProtocolDeclarationsByModule = symbolProtocolDeclarationsByModule
        self.conformancesByModule = conformancesByModule
        self.conformanceSourcesByModule = conformanceSourcesByModule
        self.inheritanceDeclarationsByModule = inheritanceDeclarationsByModule
        conformanceOwnersByModule = Dictionary(grouping: conformanceSourcesByModule.keys, by: \.moduleIdentifier)
        self.propertiesByModule = propertiesByModule
        self.staticPropertiesByModule = staticPropertiesByModule
        self.typeVisibilities = typeVisibilities
        self.inheritedClassNamesByModule = inheritedClassNamesByModule
        inheritedClassNames = inheritedClassNamesByModule.values.reduce(into: []) {
            $0.formUnion($1)
        }
        self.inheritedNamesByTypeName = inheritedNamesByTypeName
        self.typeAndProtocolCountsByModule = typeAndProtocolCountsByModule
        self.functionDeclarationsByModule = functionDeclarationsByModule
        self.functionReferencesByModule = functionReferencesByModule
        self.memberNamesByModule = memberNamesByModule
        self.dynamicMemberLookupTypesByModule = dynamicMemberLookupTypesByModule
        self.noncopyableTypesByModule = noncopyableTypesByModule
        self.symbolDeclarationsByModule = symbolDeclarationsByModule
        self.symbolDeclarationCountsByName = symbolDeclarationCountsByName
        self.typeDeclarationCountsByShortName = typeDeclarationCountsByShortName
        self.typeAliasDeclarationCountsByShortName = typeAliasDeclarationCountsByShortName
        symbolDeclarationNames = Set(symbolDeclarationCountsByName.keys)
        let descriptions = files.keys.sorted().compactMap { path -> (String, String, String)? in
            guard let file = files[path] else { return nil }
            let types = file.typeDeclarations
                .map { declaration in
                    let payloads = declaration.enumCasePayloads.map { payloads in
                        payloads.keys.sorted().map { $0 + ":" + payloads[$0]!.joined(separator: ",") }.joined(separator: ";")
                    } ?? "?"
                    return "\(declaration.name):\(declaration.visibility):\(declaration.isGeneric):\(declaration.isResultBuilder):\(declaration.isDynamicMemberLookup):\(declaration.isNoncopyable):\(declaration.enumCases?.joined(separator: ",") ?? "?"):\(declaration.hasUnknownEnumCases == true):\(declaration.genericParameters.joined(separator: ",")):\(payloads)"
                }
                .sorted()
                .joined(separator: ",")
            let classInheritances = file.classInheritances
                .map { "\($0.className):\($0.inheritedTypes.joined(separator: ","))" }
                .sorted()
                .joined(separator: ",")
            let inheritance = (file.inheritanceDeclarations ?? []).map {
                "\($0.owner):\($0.types.joined(separator: ",")):\($0.associatedTypeNames.joined(separator: ",")):\($0.propertyRequirements.joined(separator: ",")):\($0.isExtension == true):\($0.hasUnresolvedConstraints == true)"
            }.sorted().joined(separator: ",")
            let typeConformances = (file.typeConformances
                .map { "\($0.typeName):\($0.conformances.joined(separator: ","))" }
                .sorted()
                .joined(separator: ",")) + inheritance
            let protocolDeclarations = (file.symbolProtocolDeclarations ?? file.protocolDeclarations)
                .map { declaration in
                    let requirements = declaration.attributedRequirements.map {
                        "\($0.kind):\($0.name):\($0.isStatic):\($0.argumentLabels.map { $0 ?? "_" }.joined(separator: ",")):\($0.attributes.joined(separator: ","))"
                    }.sorted().joined(separator: ";")
                    return "\(declaration.name):\(declaration.inheritedProtocols.joined(separator: ",")):\(requirements):\(declaration.nestedTypeNames.joined(separator: ",")):\(declaration.visibility):\(declaration.hasRequirements == true)"
                }
                .sorted()
                .joined(separator: ",")
            let functions = (file.symbolFunctionDeclarations ?? file.functionDeclarations)
                .map { declaration in
                    let labels = declaration.argumentLabels.map { $0 ?? "_" }.joined(separator: ",")
                    let defaults = declaration.defaultArgumentIndices.map(String.init).joined(separator: ",")
                    let closures = declaration.closureArgumentIndices.map(String.init).joined(separator: ",")
                    let attributes = declaration.attributedArgumentIndices.map(String.init).joined(separator: ",")
                    let indices = declaration.autoclosureArgumentIndices.map(String.init).joined(separator: ",")
                    let constraints = (declaration.genericConstraints ?? [:]).keys.sorted().map {
                        $0 + ":" + (declaration.genericConstraints?[$0] ?? []).joined(separator: "&")
                    }.joined(separator: ";")
                    return "\(declaration.visibility):\(declaration.isStatic):\(declaration.isFailable):\(declaration.kind.rawValue):" +
                        "\(declaration.declaringType ?? "").\(declaration.name)(\(labels)):\(defaults):\(closures):\(attributes):\(indices):\(declaration.returnType ?? ""):\(declaration.argumentTypes?.joined(separator: ",") ?? ""):\(declaration.symbolArgumentTypes?.joined(separator: ",") ?? ""):\(declaration.symbolReturnType ?? ""):\(declaration.symbolHasUnresolvedConstraints == true):\(declaration.genericParameters.joined(separator: ",")):\(constraints)"
                }
                .sorted()
                .joined(separator: ",")
            let properties = file.propertyDeclarations
                .map { "\($0.declaringType).\($0.name):\($0.isStatic):\($0.type ?? ""):\($0.visibility ?? ""):\($0.hasUnresolvedConstraints == true):\($0.initializer ?? "")" }
                .sorted().joined(separator: ",")
            let members = file.typeMembers
                .map { members in
                    let instance = members.instanceMembers.sorted().joined(separator: ",")
                    let staticMembers = members.staticMembers.sorted().joined(separator: ",")
                    return "\(members.typeName):\(instance):\(staticMembers)"
                }
                .sorted()
                .joined(separator: ",")
            let symbolDeclarations = file.symbolDeclarations
                .map { "\($0.name):\($0.visibility):\($0.canBeRenamed):\($0.kind ?? "")" }
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
            let aliases = file.typeAliasDeclarations.map {
                "\($0.name)<\($0.genericParameters.joined(separator: ","))>=\($0.type):\($0.visibility):\($0.hasUnresolvedConstraints == true)"
            }.sorted().joined(separator: ",")
            let moduleNames = file.moduleNames.keys.sorted().map { "\($0)=\(file.moduleNames[$0]!)" }.joined(separator: ",")
            let declarations = "\(moduleNames):\(file.imports.joined(separator: ",")):\(file.exportedImports.joined(separator: ",")):\(file.implementationOnlyImports.joined(separator: ",")):\(file.moduleIdentifiers.joined(separator: ",")):\(types):\(classInheritances):" +
                "\(typeConformances):\(protocolDeclarations):\(functions):\(members):\(properties):\(symbolDeclarations):\(aliases)"
            let symbolReferences = file.symbolReferences.sorted().joined(separator: ",")
            return (declarations, functionReferences, symbolReferences)
        }
        declarationsFingerprint = computeHash(descriptions.map(\.0).joined(separator: ";"))
        functionReferencesFingerprint = computeHash(
            descriptions.map { "\($0.0):\($0.1)" }.joined(separator: ";")
        )
        symbolReferencesFingerprint = computeHash(
            descriptions.map { "\($0.0):\($0.2)" }.joined(separator: ";")
        )
        fingerprint = computeHash(
            descriptions.map { "\($0.0):\($0.1):\($0.2)" }.joined(separator: ";")
        )
    }

    func fingerprint(for features: Set<ProjectContextFeature>) -> String {
        switch (features.contains(.functionReferences), features.contains(.symbolReferences)) {
        case (true, true):
            return fingerprint
        case (true, false):
            return functionReferencesFingerprint
        case (false, true):
            return symbolReferencesFingerprint
        case (false, false):
            return declarationsFingerprint
        }
    }

    /// Whether another indexed file contains a possible reference to the declaration.
    /// Name-only matching is intentionally conservative: ambiguous references preserve declarations.
    func containsSymbolReference(
        named name: String,
        visibility: Visibility,
        visibleFrom fileURL: URL
    ) -> Bool? {
        let path = fileURL.standardizedFileURL.path
        guard visibility > .fileprivate,
              let file = files[path],
              file.includesSymbolReferences
        else { return nil }
        let moduleIdentifiers = Set(file.moduleIdentifiers)
        if visibility == .internal, moduleIdentifiers.isEmpty {
            return nil
        }
        let variants = Set([name, "_\(name)", "$\(name)", "`\(name)`"])
        return files.contains { candidatePath, candidate in
            guard candidatePath != path,
                  candidate.includesSymbolReferences,
                  visibility != .internal || !moduleIdentifiers.isDisjoint(with: candidate.moduleIdentifiers)
            else { return false }
            return !variants.isDisjoint(with: candidate.symbolReferences)
        }
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

    /// Only trust one accessible declaration with the same cases in every compilation context.
    func enumCases(named name: String, visibleFrom fileURL: URL, requiringExhaustive: Bool = false) -> [String]? {
        guard let keys = symbolTypeKeys(named: name, visibleFrom: fileURL), !keys.isEmpty else { return nil }
        var result: [String]?
        for key in keys {
            let declarations = typesByModule[key] ?? []
            guard declarations.count == 1, let declaration = declarations.first,
                  declaration.visibility != Visibility.private.rawValue && declaration.visibility != Visibility.fileprivate.rawValue ||
                  typeSourceFilesByModule[key] == [fileURL.standardizedFileURL.path],
                  !requiringExhaustive || declaration.hasUnknownEnumCases != true,
                  let cases = declaration.enumCases, !cases.isEmpty,
                  result == nil || result == cases else { return nil }
            result = cases
        }
        return result
    }

    /// A property can shadow a global value or function even if its type is unknown.
    func hasProperty(owner: String, member: String, visibleFrom fileURL: URL, accessedFrom accessURL: URL? = nil) -> Bool {
        guard let keys = symbolTypeKeys(named: owner, visibleFrom: fileURL) else { return true }
        return keys.contains {
            propertyCandidates(named: member, owner: $0, visibleFrom: accessURL ?? fileURL, accessingType: owner)?.isEmpty != true
        }
    }

    struct SymbolType {
        var name: String
        var namespace: String?
        var fileURL: URL
    }

    /// A member's annotation must be interpreted using the imports in its declaring source file.
    func propertySymbol(owner: String, member: String, isStatic: Bool, visibleFrom fileURL: URL, accessedFrom accessURL: URL? = nil, accessedFromType accessType: String? = nil) -> PropertySymbol? {
        guard let keys = symbolTypeKeys(named: owner, visibleFrom: fileURL), !keys.isEmpty else { return nil }
        var result: PropertySymbol?
        for key in keys {
            guard typesByModule[key]?.count == 1 || symbolProtocolDeclarationsByModule[key]?.count == 1,
                  let matches = propertyCandidates(named: member, owner: key, visibleFrom: accessURL ?? fileURL, accessingType: accessType),
                  matches.count == 1, let symbol = matches.first,
                  symbol.declaration.isStatic == isStatic,
                  symbol.declaration.hasUnresolvedConstraints != true,
                  result == nil || result?.declaration == symbol.declaration && result?.fileURL == symbol.fileURL else { return nil }
            result = symbol
        }
        return result
    }

    /// Inherited nested types and associated types require compiler name lookup.
    func isTypeWithoutInheritance(named name: String, visibleFrom fileURL: URL) -> Bool {
        guard let modules = files[fileURL.standardizedFileURL.path]?.moduleIdentifiers,
              !modules.isEmpty else { return false }
        return modules.allSatisfy { module in
            let key = TypeKey(moduleIdentifier: module, name: name)
            return typesByModule[key]?.count == 1 && (conformancesByModule[key] ?? []).isEmpty
        }
    }

    /// A constructor reference remains usable inside a conforming type when known inherited
    /// declarations cannot introduce a callable value, factory, or unresolved nested type.
    func constructorRootIsUnshadowed(_ root: String, in owner: String, visibleFrom caller: URL) -> Bool {
        guard !isDynamicMemberLookupType(named: owner, visibleFrom: caller),
              !hasProperty(owner: owner, member: root, visibleFrom: caller) else { return false }
        if isTypeWithoutInheritance(named: owner, visibleFrom: caller) {
            return true
        }
        guard let keys = symbolTypeKeys(named: owner, visibleFrom: caller), !keys.isEmpty,
              inheritedType(named: root, of: owner, visibleFrom: caller) == .absent else { return false }
        return keys.allSatisfy { key in
            memberFunctions(named: root, owner: key, visibleFrom: caller)?.isEmpty == true &&
                hasNoInheritedFunction(named: root, owner: key, sourcePath: typeSourceFilesByModule[key]?.first ?? caller.path,
                                       accessedFrom: caller, includingProperties: true)
        }
    }

    func declarationCountsAreUnambiguous(for shortName: String, includingAliases: Bool = false) -> Bool {
        symbolDeclarationCountsByName[shortName, default: 0] ==
            typeDeclarationCountsByShortName[shortName, default: 0] +
            (includingAliases ? typeAliasDeclarationCountsByShortName[shortName, default: 0] : 0)
    }

    func containsSymbolDeclaration(named name: String) -> Bool {
        symbolDeclarationNames.contains(name)
    }

    /// Whether the class is subclassed anywhere allowed by its visibility.
    /// Short-name matches are deliberately conservative when qualification is ambiguous.
    func isClassSubclassed(
        named name: String,
        visibility: Visibility,
        visibleFrom fileURL: URL
    ) -> Bool {
        let path = fileURL.standardizedFileURL.path
        guard let moduleIdentifiers = files[path]?.moduleIdentifiers,
              !moduleIdentifiers.isEmpty
        else { return false }
        let unqualifiedName = name.split(separator: ".").last.map(String.init) ?? name
        if visibility == .package {
            return inheritedClassNames.contains(name) || inheritedClassNames.contains(unqualifiedName)
        }
        return moduleIdentifiers.contains { moduleIdentifier in
            let inheritedNames = inheritedClassNamesByModule[moduleIdentifier] ?? []
            return inheritedNames.contains(name) || inheritedNames.contains(unqualifiedName)
        }
    }

    /// Whether a protocol or superclass of the type declares a function with the given signature.
    ///
    /// Protocol inheritance and superclasses are followed. Any protocol or superclass that isn't a
    /// uniquely named project declaration is `unknown`, since its requirements can't be seen.
    func conformanceRequirementStatus(
        forType typeName: String,
        functionName: String,
        isStatic: Bool,
        argumentLabels: [String?],
        visibleFrom fileURL: URL
    ) -> ConformanceRequirementStatus {
        guard let moduleIdentifiers = files[fileURL.standardizedFileURL.path]?.moduleIdentifiers,
              !moduleIdentifiers.isEmpty
        else { return .unknown }
        // Methods in an extension of a project protocol may be default implementations of its requirements.
        guard !files.values.contains(where: { file in
            file.protocolDeclarations.contains { $0.name.unqualifiedTypeName == typeName.unqualifiedTypeName }
        }) else { return .unknown }
        var visitedNames = Set<String>()
        var pendingNames = inheritedNamesByTypeName[typeName.unqualifiedTypeName] ?? []
        var status = ConformanceRequirementStatus.notRequired
        while let name = pendingNames.popFirst() {
            guard visitedNames.insert(name).inserted else { continue }
            guard moduleIdentifiers.allSatisfy({
                typeAndProtocolCountsByModule[TypeKey(moduleIdentifier: $0, name: name)] == 1
            }) else {
                status = .unknown
                continue
            }
            let isRequired = moduleIdentifiers.contains { moduleIdentifier in
                functionDeclarationsByModule[moduleIdentifier]?[functionName]?.contains {
                    $0.kind == .function && $0.isStatic == isStatic && $0.argumentLabels == argumentLabels &&
                        $0.declaringType?.unqualifiedTypeName == name
                } == true
            }
            if isRequired {
                return .required
            }
            pendingNames.formUnion(inheritedNamesByTypeName[name] ?? [])
        }
        return status
    }

    /// Standard library and Foundation protocols that inherit from `Sendable`
    private static let sendableProtocols: Set<String> = [
        "Sendable", "Error", "LocalizedError", "CustomNSError", "RecoverableError", "CodingKey",
    ]

    /// Whether another file conforms the type to a protocol that inherits from `Sendable`.
    /// The type's `Sendable` conformance then can't be implicit, since the compiler requires it
    /// to "occur in the same source file" as the type.
    func requiresExplicitSendable(forType typeName: String, visibleFrom fileURL: URL) -> Bool {
        let path = fileURL.standardizedFileURL.path
        guard let file = files[path], !file.moduleIdentifiers.isEmpty else { return false }
        let sameFileConformances = file.typeConformances.filter { $0.typeName == typeName }
            .flatMap(\.conformances.inheritedNamesToResolve)
        return file.moduleIdentifiers.contains { module in
            var pending = (conformancesByModule[TypeKey(moduleIdentifier: module, name: typeName)] ?? [])
                .subtracting(sameFileConformances)
                .map { (name: $0, owner: typeName) }
            var visited = Set<String>()
            while let next = pending.popLast() {
                if Self.sendableProtocols.contains(next.name) {
                    return true
                }
                let key = declarationTypeKey(named: next.name, relativeTo: next.owner, in: module)
                guard visited.insert(key.name).inserted else { continue }
                for declaration in protocolDeclarationsByModule[key] ?? [] {
                    pending += declaration.inheritedProtocols.map { (name: $0, owner: key.name) }
                }
            }
            return false
        }
    }

    /// Whether a matching protocol requirement can supply a result builder to this body.
    /// Parameter types aren't used to disambiguate overloads: preserving a possible builder is safer.
    func hasInheritedResultBuilder(at scope: Int, in formatter: Formatter, visibleFrom fileURL: URL) -> Bool {
        let declarations = formatter.parseDeclarations(_useForEachToken: false)
        guard let type = formatter.parseEnclosingType(containing: scope, declarations: declarations),
              let owner = type.fullyQualifiedName,
              let declaration = type.body.declaration(containing: scope),
              let modules = files[fileURL.standardizedFileURL.path]?.moduleIdentifiers
        else { return false }
        let body: ClosedRange<Int>?
        let labels: [String?]
        switch declaration.keyword {
        case "func", "subscript":
            let function = formatter.parseFunctionDeclaration(keywordIndex: declaration.keywordIndex)
            body = function?.bodyRange
            labels = function?.arguments.map(\.externalLabel) ?? []
        case "var":
            body = declaration.parsePropertyDeclaration()?.body?.scopeRange
            labels = []
        default:
            return false
        }
        guard let body, formatter.getterScope(inBodyScope: body)?.lowerBound == scope else { return false }
        let isStatic = declaration.modifiers.contains("static") || declaration.modifiers.contains("class")
        let memberName = declaration.name ?? declaration.keyword
        return modules.contains { module in
            var pending = Set([owner])
            var visited = Set<String>()
            while let name = pending.popFirst() {
                guard visited.insert(name).inserted else { continue }
                let key = TypeKey(moduleIdentifier: module, name: name)
                let protocols = protocolDeclarationsByModule[key] ?? []
                if protocols.count == 1, let proto = protocols.first,
                   proto.attributedRequirements.contains(where: { requirement in
                       requirement.kind == declaration.keyword && requirement.name == memberName &&
                           requirement.isStatic == isStatic && requirement.argumentLabels == labels &&
                           requirement.attributes.contains(where: { attribute in
                               let builderName = String(attribute.dropFirst())
                               let builderKey = declarationTypeKey(named: builderName, relativeTo: name, in: module)
                               return builderName.hasSuffix("Builder") ||
                                   typesByModule[builderKey]?
                                   .contains(where: \.isResultBuilder) == true
                           })
                   })
                {
                    return true
                }
                pending.formUnion((conformancesByModule[key] ?? []).map {
                    declarationTypeKey(named: $0, relativeTo: name, in: module).name
                })
            }
            return false
        }
    }

    /// Resolve a name in its enclosing namespace before considering a top-level declaration.
    private func declarationTypeKey(named name: String, relativeTo owner: String, in module: String, visibleFrom source: URL? = nil) -> TypeKey {
        var namespace = owner.split(separator: ".").dropLast()
        while !namespace.isEmpty {
            let key = TypeKey(moduleIdentifier: module, name: namespace.joined(separator: ".") + "." + name)
            let protocols = source == nil ? protocolDeclarationsByModule[key] : symbolProtocolDeclarationsByModule[key]
            if typesByModule[key] != nil || protocols != nil || aliasesByModule[key] != nil,
               source.map({ accessibleTypeKey(key, from: $0.standardizedFileURL.path) }) ?? true
            {
                return key
            }
            namespace = namespace.dropLast()
        }
        return TypeKey(moduleIdentifier: module, name: name)
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

    /// Resolves a function value, whose labels must match exactly (defaults aren't omitted).
    func resolveFunctionReference(
        named name: String,
        receiver: FunctionCallReceiver,
        argumentLabels: [String?]?,
        visibleFrom fileURL: URL
    ) -> [SourceFileIndex.FunctionDeclaration]? {
        guard let modules = files[fileURL.standardizedFileURL.path]?.moduleIdentifiers,
              !modules.isEmpty
        else { return nil }
        var resolved = [SourceFileIndex.FunctionDeclaration]()
        for module in modules {
            let matches = (functionDeclarationsByModule[module]?[name] ?? []).filter {
                $0.kind == .function && $0.matches(receiver: receiver) &&
                    (argumentLabels == nil || $0.argumentLabels == argumentLabels)
            }
            guard matches.count == 1, let declaration = matches.first else { return nil }
            resolved.append(declaration)
        }
        return resolved
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
              let finalArgumentIndex = argumentLabels.indices.last, let resolvedCall = resolveFunctionCall(
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

    /// Classify a closure only when every containing module has one matching declaration.
    /// Unknown parameter attributes may be custom builders, regardless of their name.
    func isResultBuilderClosure(at closure: Int, in formatter: Formatter, visibleFrom fileURL: URL) -> Bool? {
        guard let call = formatter.callContainingClosure(at: closure),
              let modules = files[fileURL.standardizedFileURL.path]?.moduleIdentifiers,
              !modules.isEmpty,
              let receiver = functionCallReceiver(at: call.identifier, in: formatter, visibleFrom: fileURL)
        else { return nil }
        let name = formatter.tokens[call.identifier].unescaped()
        let isInitializer = containsType(named: name, visibleFrom: fileURL)
        if isInitializer, formatter.last(.nonSpaceOrCommentOrLinebreak, before: call.identifier)?.isOperator(".") == true {
            return nil
        }
        let arguments = formatter.parseFunctionCallArguments(startOfScope: call.scope)
        guard let argumentIndex = arguments.firstIndex(where: { $0.valueRange.lowerBound == closure }) else { return nil }
        let scopeEnd = formatter.endOfScope(at: call.scope) ?? call.scope
        let trailingIndex = arguments.firstIndex {
            formatter.tokens[call.scope] == .startOfScope("{") || $0.valueRange.lowerBound > scopeEnd
        }
        var isBuilder = false
        for module in modules {
            let declarations = functionDeclarationsByModule[module]?[isInitializer ? "init" : name] ?? []
            let matches = declarations.compactMap { declaration -> (SourceFileIndex.FunctionDeclaration, Int)? in
                let matchesReceiver = isInitializer
                    ? declaration.kind == .initializer && declaration.declaringType == name
                    : declaration.kind == .function && declaration.matches(receiver: receiver)
                guard matchesReceiver, let parameters = declaration.parameterIndices(
                    matching: arguments.map(\.label), ignoringLabelAt: trailingIndex
                )
                else { return nil }
                return (declaration, parameters[argumentIndex])
            }
            guard matches.count == 1, let (declaration, parameter) = matches.first else { return nil }
            guard declaration.closureArgumentIndices.contains(parameter),
                  trailingIndex == nil || Set(declaration.defaultArgumentIndices)
                      .isDisjoint(with: declaration.closureArgumentIndices)
            else { return nil }
            isBuilder = isBuilder || declaration.attributedArgumentIndices.contains(parameter)
        }
        let localDeclarations = formatter.tokens.enumerated().compactMap { index, token -> Int? in
            guard ["let", "var", "func"].contains(token.string),
                  formatter.namesInDeclaration(at: index)?.contains(name) == true else { return nil }
            return index
        }
        // Private overloads and local function values aren't represented in the project index.
        if localDeclarations.contains(where: {
            formatter.tokens[$0] == .keyword("func")
                ? formatter.declarationScope(at: $0) == .local
                : formatter.declarationScope(at: $0) != .local
        }) {
            return nil
        }
        let declarations = formatter.parseDeclarations(in: formatter.tokens.indices, _useForEachToken: false)
        var hasPrivateOverload = false
        declarations.forEachRecursiveDeclaration { declaration in
            if declaration.name == name || isInitializer && declaration.keyword == "init" && declaration.parentType?.fullyQualifiedName == name,
               ([declaration] + declaration.parentDeclarations).contains(where: {
                   [Visibility.private, .fileprivate].contains($0.visibility() ?? .internal)
               })
            {
                hasPrivateOverload = true
            }
        }
        if hasPrivateOverload {
            return nil
        }
        if formatter.localDeclarationShadowsReference(
            named: name, at: call.identifier,
            declarations: declarations,
            localDeclarations: localDeclarations
        ) {
            return nil
        }
        return isBuilder
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

    /// Whether a project-defined type with the given name is declared with `@dynamicMemberLookup`
    /// in any module containing the current file.
    func isDynamicMemberLookupType(named name: String, visibleFrom fileURL: URL) -> Bool {
        let moduleIdentifiers = files[fileURL.standardizedFileURL.path]?.moduleIdentifiers ?? []
        return moduleIdentifiers.contains { dynamicMemberLookupTypesByModule[$0]?.contains(name) == true }
    }

    /// Whether a project-defined type with the given unqualified name is declared `~Copyable`
    /// in any module containing the current file.
    func isNoncopyableType(named name: String, visibleFrom fileURL: URL) -> Bool {
        let moduleIdentifiers = files[fileURL.standardizedFileURL.path]?.moduleIdentifiers ?? []
        return moduleIdentifiers.contains { noncopyableTypesByModule[$0]?.contains(name) == true }
    }

    /// Project declaration names that can participate in coordinated renaming.
    func declarationNames(upTo visibility: VisibilityThreshold, visibleFrom fileURL: URL) -> DeclarationNames? {
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
                      visibility.includes(declarationVisibility)
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

extension SourceFileIndex.FunctionDeclaration {
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
    moduleIdentifiers: Set<String>,
    moduleNames: [String: String] = [:],
    includeFunctionReferences: Bool = true,
    includeSymbolReferences: Bool = true,
    isSwiftInterface: Bool = false
) -> SourceFileIndex {
    // Newer SDK interfaces spell module-qualified types with `::`.
    let formatter = Formatter(tokenize(isSwiftInterface ? source.replacingOccurrences(of: "::", with: ".") : source))
    var typeDeclarations = [SourceFileIndex.TypeDeclaration]()
    var classInheritances = [SourceFileIndex.ClassInheritance]()
    var typeConformances = [SourceFileIndex.TypeConformance]()
    var inheritanceDeclarations = [SourceFileIndex.InheritanceDeclaration]()
    var protocolDeclarations = [SourceFileIndex.ProtocolDeclaration]()
    var symbolProtocolDeclarations = [SourceFileIndex.ProtocolDeclaration]()
    var functionDeclarations = [SourceFileIndex.FunctionDeclaration]()
    var symbolFunctionDeclarations = [SourceFileIndex.FunctionDeclaration]()
    var propertyDeclarations = [SourceFileIndex.PropertyDeclaration]()
    var typeAliasDeclarations = [SourceFileIndex.TypeAliasDeclaration]()
    var typeMembers = [SourceFileIndex.TypeMembers]()
    var symbolDeclarations = [SourceFileIndex.SymbolDeclaration]()
    let declarations = formatter.parseDeclarations()
    var imports = Set<String>()
    var exportedImports = Set<String>()
    var implementationOnlyImports = Set<String>()
    var ordinaryImports = Set<String>()
    declarations.forEachRecursiveDeclaration { declaration in
        guard declaration.keyword == "import",
              let index = formatter.index(of: .identifier, in: declaration.keywordIndex ..< declaration.range.upperBound + 1) else { return }
        let name = formatter.tokens[index].string
        imports.insert(name)
        if declaration.attributes.contains("@_exported") {
            exportedImports.insert(name)
        }
        if declaration.attributes.contains("@_implementationOnly") {
            implementationOnlyImports.insert(name)
        } else {
            ordinaryImports.insert(name)
        }
    }
    implementationOnlyImports.subtract(ordinaryImports)
    let functionReferences = includeFunctionReferences ?
        formatter.indexedFunctionReferences(declarations: declarations) : []
    let symbolReferences = includeSymbolReferences ? formatter.indexedSymbolReferences() : []
    declarations.forEachRecursiveDeclaration { declaration in
        let symbolNames = formatter.namesInDeclaration(at: declaration.keywordIndex)
            ?? declaration.name.map { [$0] }
            ?? []
        let canBeRenamed = formatter.declarationCanBeRenamed(
            declaration,
            upTo: nil
        )
        let symbolVisibility = formatter.effectiveVisibility(of: declaration).rawValue
        let hasUnresolvedConstraints = ([declaration] + declaration.parentDeclarations).contains { parent in
            if parent.keyword == "#if" || parent.attributes.contains(where: { $0.hasPrefix("@available") }) {
                return true
            }
            guard let type = parent.asTypeDeclaration, type.keyword == "extension" else { return false }
            return formatter.index(of: .keyword("where"), in: type.keywordIndex ..< type.openBraceIndex) != nil ||
                formatter.index(of: .startOfScope("<"), in: type.keywordIndex ..< type.openBraceIndex) != nil
        }
        symbolDeclarations.append(contentsOf: symbolNames.map {
            .init(name: $0, visibility: symbolVisibility, canBeRenamed: canBeRenamed, kind: declaration.keyword)
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

        if declaration.keyword == "typealias", let name = declaration.fullyQualifiedName,
           let equals = formatter.index(of: .operator("=", .infix), in: declaration.range),
           let start = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: equals),
           let type = formatter.parseType(at: start)
        {
            let parameters = formatter.index(of: .startOfScope("<"), in: declaration.keywordIndex ..< equals)
                .flatMap { formatter.parseGenericTypes(from: $0).types.map(\.name) } ?? []
            typeAliasDeclarations.append(.init(name: name, type: type.string, genericParameters: parameters, visibility: symbolVisibility, hasUnresolvedConstraints: hasUnresolvedConstraints ? true : nil))
        }

        let declarationVisibilities = [declaration.visibility()] + declaration.parentDeclarations.compactMap {
            $0.asTypeDeclaration?.visibility()
        }
        if let typeDeclaration = declaration.asTypeDeclaration,
           let name = declaration.fullyQualifiedName
        {
            let inheritedTypes = Array(Set(typeDeclaration.conformances.flatMap(\.conformance.indexedNominalTypeNames))).sorted()
            inheritanceDeclarations.append(.init(
                owner: name, types: typeDeclaration.conformances.map(\.conformance.string),
                associatedTypeNames: typeDeclaration.body.filter { $0.keyword == "associatedtype" }.compactMap(\.name),
                propertyRequirements: typeDeclaration.keyword == "protocol" ? typeDeclaration.body.filter { $0.keyword == "var" }.compactMap(\.name) : [],
                isExtension: typeDeclaration.keyword == "extension" ? true : nil,
                hasUnresolvedConstraints: hasUnresolvedConstraints ? true : nil
            ))
            if typeDeclaration.keyword == "class" {
                classInheritances.append(.init(className: name, inheritedTypes: inheritedTypes))
            }
            if typeDeclaration.keyword == "protocol" {
                // Constraints on associated types do not introduce inherited names. Constraints involving
                // Self may introduce additional requirements, so leave those protocols unresolved.
                let whereClause = formatter.index(of: .keyword("where"), in: declaration.keywordIndex ..< typeDeclaration.openBraceIndex)
                let constrainsSelf = whereClause.map {
                    formatter.tokens[$0 ..< typeDeclaration.openBraceIndex].contains { $0.string == "Self" }
                } ?? false
                if !constrainsSelf {
                    var requirements = [SourceFileIndex.AttributedRequirement]()
                    var nestedTypeNames = [String]()
                    typeDeclaration.body.forEachRecursiveDeclaration { requirement in
                        if requirement.parentType?.fullyQualifiedName == name,
                           ["associatedtype", "typealias", "class", "struct", "enum", "actor", "protocol"].contains(requirement.keyword),
                           let name = requirement.name
                        {
                            nestedTypeNames.append(name)
                        }
                        guard requirement.parentType?.fullyQualifiedName == name,
                              ["func", "var", "subscript"].contains(requirement.keyword),
                              !requirement.attributes.isEmpty else { return }
                        let function = requirement.keyword == "var" ? nil :
                            formatter.parseFunctionDeclaration(keywordIndex: requirement.keywordIndex)
                        requirements.append(.init(
                            name: requirement.name ?? requirement.keyword,
                            kind: requirement.keyword,
                            isStatic: requirement.modifiers.contains("static") || requirement.modifiers.contains("class"),
                            argumentLabels: function?.arguments.map(\.externalLabel) ?? [],
                            attributes: requirement.attributes
                        ))
                    }
                    let symbolProtocol = SourceFileIndex.ProtocolDeclaration(
                        name: name, inheritedProtocols: inheritedTypes, attributedRequirements: requirements,
                        nestedTypeNames: Array(Set(nestedTypeNames)).sorted(),
                        visibility: symbolVisibility,
                        hasRequirements: typeDeclaration.body.contains {
                            ["associatedtype", "func", "var", "init", "subscript"].contains($0.keyword)
                        } ? true : nil
                    )
                    symbolProtocolDeclarations.append(symbolProtocol)
                    if !declarationVisibilities.contains(where: { $0 == .private || $0 == .fileprivate }) {
                        protocolDeclarations.append(symbolProtocol)
                    }
                }
            } else {
                typeConformances.append(.init(typeName: name, conformances: inheritedTypes))
            }
            if typeDeclaration.keyword != "extension", typeDeclaration.keyword != "protocol" {
                let insidePublicOrPackageExtension = declaration.parentDeclarations.contains(where: {
                    $0.keyword == "extension" && ($0.visibility() ?? .internal) > .internal
                })
                if !insidePublicOrPackageExtension {
                    typeDeclarations.append(.init(
                        name: name,
                        visibility: symbolVisibility,
                        isGeneric: typeDeclaration.genericParameters != nil ||
                            declaration.parentDeclarations.contains(where: {
                                $0.asTypeDeclaration?.genericParameters != nil || $0.keyword == "extension"
                            }),
                        isResultBuilder: declaration.attributes.contains("@resultBuilder"),
                        isDynamicMemberLookup: declaration.attributes.contains("@dynamicMemberLookup"),
                        isNoncopyable: typeDeclaration.conformances.contains { $0.conformance.string == "~Copyable" },
                        enumCases: formatter.indexedEnumCases(in: typeDeclaration),
                        hasUnknownEnumCases: isSwiftInterface && typeDeclaration.keyword == "enum" && !declaration.attributes.contains("@frozen") ? true : nil,
                        enumCasePayloads: formatter.indexedEnumCasePayloads(in: typeDeclaration),
                        genericParameters: typeDeclaration.genericParameters?.types.map(\.name) ?? []
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

        if ["let", "var"].contains(declaration.keyword),
           let owner = declaration.parentType,
           let ownerName = owner.fullyQualifiedName
        {
            propertyDeclarations.append(.init(
                name: declaration.name ?? "",
                declaringType: ownerName,
                type: declaration.parsePropertyDeclaration()?.type?.string,
                isStatic: declaration.modifiers.contains("static") || declaration.modifiers.contains("class"),
                visibility: symbolVisibility,
                hasUnresolvedConstraints: hasUnresolvedConstraints ? true : nil,
                initializer: declaration.parsePropertyDeclaration()?.value.map { formatter.tokens[$0.expressionRange].string }
            ))
        }

        guard ["func", "init", "subscript"].contains(declaration.keyword),
              !declaration.parentDeclarations.contains(where: {
                  ["func", "init", "subscript"].contains($0.keyword)
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
        var signature = SourceFileIndex.FunctionDeclaration(
            name: name,
            kind: kind,
            declaringType: declaration.parentType?.fullyQualifiedName,
            isStatic: declaration.modifiers.contains("static") || declaration.modifiers.contains("class"),
            visibility: symbolVisibility,
            argumentLabels: function.arguments.map(\.externalLabel),
            defaultArgumentIndices: defaultArgumentIndices,
            closureArgumentIndices: closureArgumentIndices,
            autoclosureArgumentIndices: autoclosureArgumentIndices,
            attributedArgumentIndices: function.arguments.indices.filter {
                !function.arguments[$0].attributes.isEmpty
            },
            returnType: function.genericParameterRange == nil &&
                !declaration.parentDeclarations.contains(where: {
                    $0.asTypeDeclaration?.genericParameters != nil
                })
                ? function.returnType?.string : nil,
            isFailable: kind == .initializer &&
                formatter.next(.nonSpaceOrCommentOrLinebreak, after: declaration.keywordIndex)?.isUnwrapOperator == true,
            argumentTypes: function.genericParameterRange == nil &&
                !declaration.parentDeclarations.contains(where: {
                    $0.asTypeDeclaration?.genericParameters != nil
                })
                ? function.arguments.map(\.type.string) : nil,
            symbolArgumentTypes: function.arguments.map(\.type.string),
            symbolReturnType: function.returnType?.string,
            genericParameters: function.genericParameterRange.map { formatter.parseGenericTypes(from: $0.lowerBound).types.map(\.name) } ?? []
        )
        var generics = function.genericParameterRange.map { formatter.parseGenericTypes(from: $0.lowerBound).types } ?? []
        if let whereClause = function.whereClauseRange {
            formatter.parseGenericTypes(from: whereClause.lowerBound, into: &generics)
        }
        let constraints = Dictionary(uniqueKeysWithValues: generics.compactMap { generic -> (String, [String])? in
            guard signature.genericParameters.contains(generic.name) else { return nil }
            let bounds = generic.conformances.filter { $0.type == .protocolConstraint && $0.typeName == generic.name }.map(\.name)
            return bounds.isEmpty ? nil : (generic.name, bounds.sorted())
        })
        signature.genericConstraints = constraints.isEmpty ? nil : constraints
        signature.symbolHasUnresolvedConstraints = hasUnresolvedConstraints ? true : nil
        symbolFunctionDeclarations.append(signature)
        if !declarationVisibilities.contains(where: { $0 == .private || $0 == .fileprivate }) {
            var conservativeSignature = signature
            conservativeSignature.visibility = (declaration.visibility() ?? .internal).rawValue
            conservativeSignature.symbolArgumentTypes = nil
            conservativeSignature.symbolReturnType = nil
            conservativeSignature.symbolHasUnresolvedConstraints = nil
            conservativeSignature.genericParameters = []
            conservativeSignature.genericConstraints = nil
            functionDeclarations.append(conservativeSignature)
        }
    }
    formatter.clearDerivedCaches()
    return SourceFileIndex(
        contentHash: computeHash(source),
        moduleIdentifiers: moduleIdentifiers,
        moduleNames: moduleNames,
        imports: Array(imports),
        exportedImports: Array(exportedImports),
        implementationOnlyImports: Array(implementationOnlyImports),
        typeDeclarations: typeDeclarations,
        classInheritances: classInheritances,
        typeConformances: typeConformances,
        protocolDeclarations: protocolDeclarations,
        functionDeclarations: functionDeclarations,
        propertyDeclarations: propertyDeclarations,
        typeAliasDeclarations: typeAliasDeclarations,
        typeMembers: typeMembers,
        symbolDeclarations: symbolDeclarations,
        functionReferences: functionReferences,
        symbolReferences: symbolReferences,
        includesFunctionReferences: includeFunctionReferences,
        includesSymbolReferences: includeSymbolReferences,
        symbolFunctionDeclarations: symbolFunctionDeclarations,
        symbolProtocolDeclarations: symbolProtocolDeclarations,
        inheritanceDeclarations: inheritanceDeclarations
    )
}

extension Formatter {
    func indexedEnumCasePayloads(in declaration: TypeDeclaration) -> [String: [String]]? {
        guard indexedEnumCases(in: declaration) != nil else { return nil }
        var result = [String: [String]]()
        for member in declaration.body where member.keyword == "case" {
            for range in enumCaseRanges(at: member.keywordIndex) {
                let name = tokens[range.lowerBound].string
                guard let open = index(of: .startOfScope("("), in: range) else {
                    result[name] = []
                    continue
                }
                var types = [String]()
                for argument in parseTupleArguments(startOfScope: open) {
                    guard let type = parseType(at: argument.valueRange.lowerBound) else { return nil }
                    types.append(type.string)
                }
                result[name] = types
            }
        }
        return result
    }

    /// Conditional and availability-dependent cases cannot safely replace a default.
    func indexedEnumCases(in declaration: TypeDeclaration) -> [String]? {
        guard declaration.keyword == "enum",
              !([declaration] + declaration.parentDeclarations).contains(where: {
                  $0.attributes.contains(where: { $0.hasPrefix("@available") })
              }),
              !declaration.parentDeclarations.contains(where: {
                  $0.keyword == "#if" || ($0.keyword == "extension" && ($0.visibility() ?? .internal) <= .fileprivate)
              }),
              !declaration.body.contains(where: { $0.keyword == "#if" })
        else { return nil }
        var names = [String]()
        for member in declaration.body where member.keyword == "case" {
            guard member.attributes.isEmpty else { return nil }
            for range in enumCaseRanges(at: member.keywordIndex) {
                guard let name = token(at: range.lowerBound), name.isIdentifier else { return nil }
                names.append(name.string)
            }
        }
        return Set(names).count == names.count ? names : nil
    }
}

extension String {
    /// The last component of a qualified type name, ignoring generic arguments.
    var unqualifiedTypeName: String {
        prefix { $0 != "<" }.split(separator: ".").last.map(String.init) ?? self
    }
}

private extension [String] {
    /// Inherited names that are looked up in the index. A qualified name like `SDK.Loading` is kept as is,
    /// so it never matches a project declaration, and the unqualified form recorded alongside it is dropped.
    var inheritedNamesToResolve: [String] {
        filter { name in !contains { $0.hasSuffix(".\(name)") } }
    }
}

private extension TypeName {
    /// Qualified and unqualified nominal names in an inherited type, excluding generic arguments.
    var indexedNominalTypeNames: [String] {
        tokens.split(separator: .operator("&", .infix)).flatMap { component -> [String] in
            let identifiers = component
                .prefix { $0 != .startOfScope("<") }
                .compactMap { $0.isIdentifier ? $0.string : nil }
            guard let unqualifiedName = identifiers.last else { return [] }
            let qualifiedName = identifiers.joined(separator: ".")
            return qualifiedName == unqualifiedName ? [unqualifiedName] : [qualifiedName, unqualifiedName]
        }
    }
}

extension Formatter {
    /// Finds the call for a parenthesized or trailing closure argument.
    func callContainingClosure(at closure: Int) -> (identifier: Int, scope: Int)? {
        guard let previous = index(of: .nonSpaceOrCommentOrLinebreak, before: closure) else { return nil }
        if tokens[previous] == .delimiter(":"),
           let label = index(of: .nonSpaceOrCommentOrLinebreak, before: previous),
           isTrailingClosureLabel(at: label),
           let end = index(of: .nonSpaceOrCommentOrLinebreak, before: label),
           tokens[end] == .endOfScope("}"), let start = startOfScope(at: end)
        {
            return callContainingClosure(at: start)
        }
        if tokens[previous] == .endOfScope(")"), let scope = startOfScope(at: previous),
           let identifier = parseFunctionIdentifier(beforeStartOfScope: scope)
        {
            return (identifier, scope)
        }
        if let identifier = parseCallableIdentifier(before: closure) {
            return (identifier, closure)
        }
        if let scope = startOfScope(at: closure), tokens[scope] == .startOfScope("("),
           let identifier = parseFunctionIdentifier(beforeStartOfScope: scope)
        {
            return (identifier, scope)
        }
        return nil
    }

    /// All identifier spellings that may refer to a declaration in another source file.
    func indexedSymbolReferences() -> [String] {
        var references = Set<String>()
        forEach(.identifier) { _, token in
            references.insert(token.string)
        }
        return references.sorted()
    }

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
                  let closeParen = endOfScope(at: openParen),
                  let labels = parseFunctionReferenceLabels(at: openParen)
            else { return }
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

/// Shared locations that should not be searched for an enclosing project.
func projectRootSearchBoundaries(
    homeDirectory home: URL = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true),
    environment: [String: String] = ProcessInfo.processInfo.environment
) -> [URL] {
    let manager = FileManager.default
    var directories = [home, home.deletingLastPathComponent(), URL(fileURLWithPath: NSTemporaryDirectory())]
    let userDirectories: [FileManager.SearchPathDirectory] = [
        .desktopDirectory, .documentDirectory, .downloadsDirectory,
        .libraryDirectory, .cachesDirectory, .applicationSupportDirectory,
        .moviesDirectory, .musicDirectory, .picturesDirectory, .sharedPublicDirectory,
    ]
    for directory in userDirectories {
        directories += manager.urls(for: directory, in: .userDomainMask)
    }
    // Environment paths cover redirected profiles and XDG locations that Foundation
    // may not expose. Windows environment variable names are case-insensitive.
    let environmentVariables = [
        "USERPROFILE", "PUBLIC", "PROGRAMDATA", "ALLUSERSPROFILE", "APPDATA", "LOCALAPPDATA",
        "TEMP", "TMP", "XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME", "XDG_STATE_HOME",
        "XDG_RUNTIME_DIR",
    ]
    for name in environmentVariables {
        let path = name.hasPrefix("XDG_") ? environment[name] :
            environment.first { $0.key.caseInsensitiveCompare(name) == .orderedSame }?.value
        if let path, (path as NSString).isAbsolutePath {
            directories.append(URL(fileURLWithPath: path, isDirectory: true))
        }
    }
    #if os(Windows)
        directories += ["Desktop", "Documents", "Downloads", "Pictures", "Music", "Videos", "AppData"]
            .map { home.appendingPathComponent($0, isDirectory: true) }
    #elseif os(Linux)
        directories += ["/home", "/tmp", "/var/tmp", "/mnt", "/media", "/run/user"]
            .map { URL(fileURLWithPath: $0, isDirectory: true) }
        let xdgDefaults = [
            "XDG_CONFIG_HOME": ".config", "XDG_DATA_HOME": ".local/share",
            "XDG_CACHE_HOME": ".cache", "XDG_STATE_HOME": ".local/state",
        ]
        for (name, path) in xdgDefaults {
            if !(environment[name, default: ""] as NSString).isAbsolutePath {
                directories.append(home.appendingPathComponent(path, isDirectory: true))
            }
        }
        for (name, fallback) in ["XDG_CONFIG_DIRS": "/etc/xdg", "XDG_DATA_DIRS": "/usr/local/share:/usr/share"] {
            let value = environment[name].flatMap { $0.isEmpty ? nil : $0 } ?? fallback
            directories += value.split(separator: ":").filter { $0.hasPrefix("/") }
                .map { URL(fileURLWithPath: String($0), isDirectory: true) }
        }
    #else
        directories += ["/Users", "/tmp", "/var/tmp", "/Volumes"]
            .map { URL(fileURLWithPath: $0, isDirectory: true) }
    #endif
    return directories
}

private let defaultProjectRootSearchBoundaries = projectRootSearchBoundaries()

/// Finds the project root containing an input using filesystem markers where possible.
func projectRoot(
    for inputURL: URL,
    stoppingAt boundaries: [URL] = defaultProjectRootSearchBoundaries
) -> ProjectRoot {
    let manager = FileManager.default
    var isDirectory: ObjCBool = false
    let standardizedURL = inputURL.standardizedFileURL
    var directory = standardizedURL
    if !manager.fileExists(atPath: standardizedURL.path, isDirectory: &isDirectory) || !isDirectory.boolValue {
        directory.deleteLastPathComponent()
    }
    let fallback = directory
    func comparisonPath(_ url: URL) -> String {
        let path = url.standardizedFileURL.path
        #if os(Windows)
            return path.lowercased()
        #else
            return path
        #endif
    }
    let boundaryPaths = Set(boundaries.flatMap {
        [comparisonPath($0), comparisonPath($0.resolvingSymlinksInPath())]
    })

    // Older Foundation versions append ".." when deleting the root's last path component.
    // Do not enumerate shared locations or let unrelated markers there capture inputs.
    while directory.pathComponents.count > 1, !boundaryPaths.contains(comparisonPath(directory)) {
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
    projectModuleMembership(for: fileURLs, in: root).files
}

struct ProjectModuleMembership {
    var files: [String: Set<String>]
    var names: [String: String] = [:]
}

/// Build tools can provide exact module membership without generating an Xcode project.
/// Source paths and globs are relative to the manifest, or absolute. A file may belong to multiple modules.
struct ProjectIndexManifest: Decodable {
    struct Module: Decodable {
        var name: String
        var id: String
        var sources: [String]
    }

    var modules: [Module]

    func membership(relativeTo directory: URL) throws -> ProjectModuleMembership {
        var result = ProjectModuleMembership(files: [:])
        for module in modules {
            guard !module.name.isEmpty, !module.id.isEmpty,
                  result.names[module.id] == nil
            else {
                throw FormatError.options("Project index manifest requires unique, nonempty module IDs and names")
            }
            result.names[module.id] = module.name
            for source in module.sources {
                let urls: [URL]
                if pathContainsGlobSyntax(source) {
                    let matches = try matchGlobs(parseGlobs(source, in: directory.path, splitOnCommas: false), in: "/", includingDirectories: false, skipUnreadableDirectories: false)
                    urls = matches.filter { ["swift", "swiftinterface"].contains($0.pathExtension) }
                    guard !urls.isEmpty else {
                        throw FormatError.options("Project index manifest glob did not match Swift source or interfaces: \(source)")
                    }
                } else {
                    let url = expandPath(source, in: directory.path).standardizedFileURL
                    guard ["swift", "swiftinterface"].contains(url.pathExtension) else {
                        throw FormatError.options("Project index manifest source must be Swift source or an interface: \(source)")
                    }
                    urls = [url]
                }
                for url in urls {
                    result.files[url.standardizedFileURL.path, default: []].insert(module.id)
                }
            }
        }
        return result
    }
}

func projectModuleMembership(for fileURLs: [URL], in root: ProjectRoot) -> ProjectModuleMembership {
    let rootPath = root.url.standardizedFileURL.path

    switch root.kind {
    case .swiftPackage:
        let files: [String: Set<String>] = Dictionary(uniqueKeysWithValues: fileURLs.compactMap { fileURL in
            let filePath = fileURL.standardizedFileURL.path
            guard filePath.hasPrefix(rootPath + "/") else { return nil }
            let relativePath = String(filePath.dropFirst(rootPath.count + 1))
            let components = relativePath.split(separator: "/").map(String.init)
            guard components.count >= 3, ["Sources", "Tests"].contains(components[0]) else {
                return nil
            }
            return (filePath, ["\(rootPath):\(components[0]):\(components[1])"])
        })
        let identifiers = Set(files.values.flatMap { $0 })
        return ProjectModuleMembership(files: files, names: Dictionary(uniqueKeysWithValues: identifiers.map {
            ($0, String($0.split(separator: ":").last ?? ""))
        }))
    case .xcodeProject:
        let projectURLs = xcodeProjectURLs(in: root.url)
        var targetsByFile = [String: Set<String>]()
        var names = [String: String]()
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
            for (targetID, name) in project.moduleNamesByTarget {
                names["\(projectIdentifier):\(targetID)"] = name
            }
            for (filePath, targetIDs) in project.targetIDsByFile {
                targetsByFile[filePath, default: []].formUnion(targetIDs.map {
                    "\(projectIdentifier):\($0)"
                })
            }
        }
        return ProjectModuleMembership(files: targetsByFile, names: names)
    case .gitRepository, .directory:
        return ProjectModuleMembership(files: Dictionary(uniqueKeysWithValues: fileURLs.compactMap { fileURL in
            let path = fileURL.standardizedFileURL.path
            return path.hasPrefix(rootPath + "/") ? (path, [rootPath]) : nil
        }))
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
    var moduleNamesByTarget: [String: String] = [:]

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
            if let name = string("productName", in: target) ?? string("name", in: target) {
                let configurations = string("buildConfigurationList", in: target).flatMap { dictionary(for: $0) }
                    .map { strings("buildConfigurations", in: $0) } ?? []
                let moduleNames = Set(configurations.compactMap { configuration -> String? in
                    guard let configuration = dictionary(for: configuration),
                          case let .dictionary(settings)? = configuration["buildSettings"] else { return nil }
                    return string("PRODUCT_MODULE_NAME", in: settings)
                })
                if moduleNames.isEmpty {
                    moduleNamesByTarget[targetID] = name
                } else if moduleNames.count == 1, let module = moduleNames.first, !module.contains("$") {
                    moduleNamesByTarget[targetID] = module
                }
            }
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

extension ProjectIndex {
    enum PropertyTypeResult {
        case unknown
        case unsafe
        case type(String)
    }

    /// Resolve without using the property's annotation to select an overload.
    func propertyValueType(
        owner: String, member: String, argumentLabels: [String?]?, visibleFrom fileURL: URL
    ) -> PropertyTypeResult {
        guard let modules = files[fileURL.standardizedFileURL.path]?.moduleIdentifiers,
              !modules.isEmpty else { return .unknown }
        var resultTypes = Set<String>()
        for module in modules {
            let ownerKey = TypeKey(moduleIdentifier: module, name: owner)
            // A protocol existential is not the concrete Self used by a constrained extension.
            if protocolsByModule.contains(ownerKey) {
                return .unsafe
            }
            let owners = typesByModule[ownerKey] ?? []
            if owners.count > 1 || owners.contains(where: \.isGeneric) {
                return .unsafe
            }
            let type: String?
            if let argumentLabels {
                let candidates = (functionDeclarationsByModule[module]?[member] ?? []).filter {
                    $0.declaringType == owner &&
                        (member == "init" ? $0.kind == .initializer : $0.kind == .function && $0.isStatic) &&
                        $0.parameterIndices(matching: argumentLabels) != nil
                }
                guard !candidates.isEmpty else { return modules.count == 1 ? .unknown : .unsafe }
                guard candidates.count == 1, let candidate = candidates.first,
                      !candidate.isFailable else { return .unsafe }
                type = member == "init" ? owner : candidate.returnType
            } else {
                let key = TypeKey(moduleIdentifier: module, name: "\(owner).\(member)")
                let candidates = staticPropertiesByModule[key] ?? []
                guard !candidates.isEmpty else { return modules.count == 1 ? .unknown : .unsafe }
                guard candidates.count == 1 else { return .unsafe }
                type = candidates.first?.type
            }
            guard let type, !type.hasSuffix("!"), type != "Self",
                  !containsType(named: "\(owner).\(type)", visibleFrom: fileURL),
                  isKnownNonOptionalType(type, visibleFrom: fileURL)
            else { return .unsafe }
            let typeTokens = tokenize(type)
            let referencedTypes = typeTokens.filter(\.isIdentifier).map(\.string)
            // A member's nested types and aliases may not be available unqualified at the use site.
            guard !referencedTypes.contains(where: {
                containsType(named: "\(owner).\($0)", visibleFrom: fileURL) ||
                    (typeTokens.contains(where: \.isStartOfScope) && !isKnownNonOptionalType($0, visibleFrom: fileURL))
            }) else { return .unsafe }
            resultTypes.insert(type)
        }
        guard resultTypes.count == 1, let type = resultTypes.first else { return .unsafe }
        return .type(type)
    }
}

extension ProjectIndex {
    /// A missing `?` alone is not proof: typealiases and generic parameters can be optional.
    func isKnownNonOptionalType(_ name: String, visibleFrom fileURL: URL) -> Bool {
        let formatter = Formatter(tokenize(name))
        guard let type = formatter.parseType(at: 0), !type.isOptionalType else { return false }
        if type.isArray || type.isDictionary {
            return formatter.endOfScope(at: type.range.lowerBound) == type.range.upperBound
        }
        if type.isTuple || type.isClosure {
            return true
        }
        let name = type.withoutParens().string
        let shortName = name.split(separator: ".").last.map(String.init) ?? name
        if containsType(named: name, visibleFrom: fileURL),
           declarationCountsAreUnambiguous(for: shortName)
        {
            return true
        }
        let standardTypes: Set = [
            "Bool", "String", "Character", "Int", "Int8", "Int16", "Int32", "Int64",
            "UInt", "UInt8", "UInt16", "UInt32", "UInt64", "Float", "Double", "Void",
        ]
        if name.hasPrefix("Swift.") {
            return standardTypes.contains(String(name.dropFirst(6)))
        }
        // A local or project declaration can shadow a standard-library type.
        return standardTypes.contains(name) && !containsSymbolDeclaration(named: name)
    }
}

extension ProjectIndex {
    /// A missing name is different from an inherited name that requires type checking.
    enum InheritedTypeLookup: Equatable {
        case absent
        case type(String, sourceFileURL: URL)
        case unknown
    }

    /// Resolve lexical type lookup through known superclass and protocol declarations.
    func inheritedType(named member: String, of owner: String, visibleFrom fileURL: URL) -> InheritedTypeLookup {
        guard let roots = symbolTypeKeys(named: owner, visibleFrom: fileURL), !roots.isEmpty else { return .unknown }
        func lookup(_ owner: String, module: String, sourcePath: String, visited: Set<String>) -> InheritedTypeLookup {
            guard !visited.contains(module + ":" + owner), visited.count < 32 else { return .unknown }
            // AnyObject is a compiler builtin exposed through the standard library's alias.
            if owner == "Builtin.AnyObject", moduleNamesByIdentifier[module] == "Swift" {
                return .absent
            }
            let key = TypeKey(moduleIdentifier: module, name: owner)
            let nested = TypeKey(moduleIdentifier: module, name: "\(owner).\(member)")
            if accessibleTypeKey(nested, from: fileURL.standardizedFileURL.path, inherited: true) {
                guard let paths = typeSourceFilesByModule[nested], paths.count == 1, let path = paths.first else { return .unknown }
                let moduleName = typeSourceFilesByModule[nested]?.first.flatMap { files[$0]?.moduleNames[module] }
                return .type(moduleName.map { "\($0).\(nested.name)" } ?? nested.name, sourceFileURL: URL(fileURLWithPath: path))
            }
            if let aliases = aliasesByModule[key] {
                guard aliases.count == 1, let alias = aliases.first, alias.genericParameters.isEmpty,
                      let target = ProjectTypeReference(alias.type), target.arguments.isEmpty,
                      let paths = typeSourceFilesByModule[key], paths.count == 1, let path = paths.first else { return .unknown }
                let parent = declarationTypeKey(named: target.name, relativeTo: alias.name, in: module, visibleFrom: URL(fileURLWithPath: path)).name
                return lookup(parent, module: module, sourcePath: path, visited: visited.union([module + ":" + owner]))
            }
            if let protocols = symbolProtocolDeclarationsByModule[key] {
                guard !protocols.contains(where: { $0.nestedTypeNames.contains(member) }) else { return .unknown }
            } else if typesByModule[key]?.count != 1 {
                let imports = files[sourcePath]?.imports ?? []
                if let candidates = symbolTypeKeys(named: owner, in: module, imports: imports, sourcePath: sourcePath), !candidates.isEmpty {
                    let results = candidates.map { candidate in
                        lookup(candidate.name, module: candidate.moduleIdentifier,
                               sourcePath: typeSourceFilesByModule[candidate]?.first ?? sourcePath, visited: visited.union([module + ":" + owner]))
                    }
                    return results.dropFirst().allSatisfy { $0 == results.first } ? results[0] : .unknown
                }
                // These standard conformances cannot introduce arbitrary nested type names.
                let members: [String: Set<String>] = [
                    "AnyObject": [], "Equatable": [], "Hashable": [], "Encodable": [], "Decodable": [], "Codable": [],
                    "Sendable": [], "CaseIterable": ["AllCases"], "RawRepresentable": ["RawValue"],
                    "Identifiable": ["ID"], "CustomStringConvertible": [], "CustomDebugStringConvertible": [],
                    "Error": [], "LocalizedError": [], "String": [], "Int": [], "UInt": [],
                    "Int8": [], "Int16": [], "Int32": [], "Int64": [], "UInt8": [], "UInt16": [], "UInt32": [], "UInt64": [],
                ]
                return members[owner].map { $0.contains(member) ? .unknown : .absent } ?? .unknown
            }
            var result = InheritedTypeLookup.absent
            // A conformance extension can import protocols absent from the nominal's own file.
            // Resolve each inherited name using the imports where that conformance was written.
            for entry in conformanceSourcesByModule[key] ?? [] {
                for inherited in entry.parents.sorted().inheritedNamesToResolve {
                    let parent = declarationTypeKey(named: inherited, relativeTo: owner, in: module, visibleFrom: entry.source).name
                    let candidate = lookup(parent, module: module, sourcePath: entry.source.path, visited: visited.union([module + ":" + owner]))
                    switch candidate {
                    case .absent: continue
                    case .unknown: return .unknown
                    case .type:
                        guard result == .absent || result == candidate else { return .unknown }
                        result = candidate
                    }
                }
            }
            return result
        }
        let results = roots.map { lookup($0.name, module: $0.moduleIdentifier, sourcePath: typeSourceFilesByModule[$0]?.first ?? fileURL.path, visited: []) }
        return results.dropFirst().allSatisfy { $0 == results.first } ? results[0] : .unknown
    }

    /// Ambiguous extension names can still be ruled out when every possible alias target is
    /// a different nominal declaration. Unknown or cyclic alias paths cannot prove absence.
    private func extensionOwnerMayRefer(to owner: TypeKey, named name: String, in module: String, source: URL, visited: Set<TypeKey> = []) -> Bool {
        guard visited.count < 32, let reference = ProjectTypeReference(name), !reference.hasGenericParent,
              let file = files[source.standardizedFileURL.path],
              let keys = symbolTypeKeys(named: reference.name, in: module, imports: file.imports, sourcePath: source.standardizedFileURL.path,
                                        allowingAmbiguity: true), !keys.isEmpty else { return true }
        return keys.contains { key in
            guard key != owner, !visited.contains(key) else { return true }
            guard let aliases = aliasesByModule[key] else { return false }
            guard let paths = typeSourceFilesByModule[key], paths.count == 1, let path = paths.first else { return true }
            let aliasSource = URL(fileURLWithPath: path)
            return aliases.contains { alias in
                guard let target = ProjectTypeReference(alias.type) else { return true }
                let targetName = declarationTypeKey(named: target.name, relativeTo: alias.name, in: key.moduleIdentifier, visibleFrom: aliasSource).name
                return extensionOwnerMayRefer(to: owner, named: targetName, in: key.moduleIdentifier, source: aliasSource, visited: visited.union([key]))
            }
        }
    }

    /// Conformance extensions may qualify or alias a type from another imported module.
    /// Resolve those owners once rather than assuming their spelling is the nominal identity.
    private func inheritanceEntries(owner: TypeKey, accessedFrom caller: URL) -> [InheritanceEntry]? {
        inheritanceEntryCache.value(for: InheritanceKey(owner: owner, callerPath: caller.standardizedFileURL.path)) {
            guard var result = inheritanceDeclarationsByModule[owner] else { return nil }
            for module in memberModules(visibleFrom: caller) {
                for candidate in conformanceOwnersByModule[module] ?? [] where candidate != owner {
                    for var entry in inheritanceDeclarationsByModule[candidate] ?? [] where !entry.declaration.types.isEmpty {
                        // An extension cannot target a declaration inaccessible from its own file,
                        // including through an unresolved alias in a different module.
                        guard accessibleTypeKey(owner, from: entry.source.standardizedFileURL.path) else { continue }
                        guard let target = memberOwner(named: candidate.name, visibleFrom: entry.source, in: module) else {
                            if extensionOwnerMayRefer(to: owner, named: candidate.name, in: module, source: entry.source) {
                                return nil
                            }
                            continue
                        }
                        guard target.keys.contains(owner) else { continue }
                        if target.constrained {
                            entry.declaration.hasUnresolvedConstraints = true
                        }
                        if !result.contains(where: { $0.declaration == entry.declaration && $0.source == entry.source }) {
                            result.append(entry)
                        }
                    }
                }
            }
            return result
        }
    }

    struct InheritedTypeReference: Equatable {
        var name: String
        var namespace: String?
        var fileURL: URL
    }

    /// Retain generic arguments and the imports where each conformance was written.
    /// An empty result proves no parents; nil means the declaration or a conformance is ambiguous.
    func inheritedTypeReferences(owner: String, visibleFrom fileURL: URL) -> [InheritedTypeReference]? {
        guard let keys = symbolTypeKeys(named: owner, visibleFrom: fileURL), !keys.isEmpty else { return nil }
        var result: [InheritedTypeReference]?
        for key in keys {
            guard typesByModule[key]?.count == 1 || symbolProtocolDeclarationsByModule[key]?.count == 1,
                  let entries = inheritanceEntries(owner: key, accessedFrom: fileURL),
                  entries.allSatisfy({ $0.declaration.types.isEmpty || $0.declaration.hasUnresolvedConstraints != true }) else { return nil }
            let references = entries.flatMap { entry in
                entry.declaration.types.map {
                    InheritedTypeReference(name: $0, namespace: entry.declaration.owner, fileURL: entry.source)
                }
            }.sorted { ($0.fileURL.path, $0.name) < ($1.fileURL.path, $1.name) }
            guard result == nil || result == references else { return nil }
            result = references
        }
        return result
    }

    /// Property requirements provide evidence for a concrete associated-type witness. A caller
    /// must still resolve every concrete witness and require their types to agree.
    func associatedTypeRequirements(named member: String, of owner: String, visibleFrom fileURL: URL) -> [PropertySymbol]? {
        guard let roots = symbolTypeKeys(named: owner, visibleFrom: fileURL), !roots.isEmpty else { return nil }
        var associatedOwners = Set<TypeKey>()
        func requirements(_ key: TypeKey, visited: Set<TypeKey>) -> [PropertySymbol]? {
            guard visited.count < 32, !visited.contains(key), symbolProtocolDeclarationsByModule[key]?.count == 1,
                  let allEntries = inheritanceDeclarationsByModule[key],
                  case let entries = allEntries.filter({ $0.declaration.isExtension != true }), entries.count == 1, let entry = entries.first,
                  entry.declaration.hasUnresolvedConstraints != true else { return nil }
            var result = [PropertySymbol]()
            if entry.declaration.associatedTypeNames.contains(member) {
                associatedOwners.insert(key)
            } else if symbolProtocolDeclarationsByModule[key]?.first?.nestedTypeNames.contains(member) == true {
                return nil
            }
            for name in entry.declaration.propertyRequirements {
                guard let properties = memberProperties(named: name, owner: key, visibleFrom: fileURL) else { return nil }
                for property in properties {
                    let annotation = property.declaration.type.map { tokenize($0).filter { !$0.isSpaceOrCommentOrLinebreak }.string }
                    if !property.declaration.isStatic, property.declaration.hasUnresolvedConstraints != true,
                       annotation == member || annotation == "Self." + member,
                       !result.contains(where: { $0.declaration == property.declaration && $0.fileURL == property.fileURL })
                    {
                        result.append(property)
                    }
                }
            }
            for inherited in entry.declaration.types {
                guard let reference = ProjectTypeReference(inherited), reference.arguments.isEmpty,
                      let parent = lexicalMemberOwner(named: reference.name, namespace: entry.declaration.owner, visibleFrom: entry.source),
                      !parent.constrained, !parent.keys.isEmpty else { return nil }
                for parentKey in parent.keys {
                    guard let inherited = requirements(parentKey, visited: visited.union([key])) else { return nil }
                    for property in inherited where !result.contains(where: { $0.declaration == property.declaration && $0.fileURL == property.fileURL }) {
                        result.append(property)
                    }
                }
            }
            return result
        }
        var result: [PropertySymbol]?
        for key in roots {
            associatedOwners.removeAll()
            guard let properties = requirements(key, visited: []), associatedOwners.count == 1 else { return nil }
            if let previous = result {
                guard previous.count == properties.count,
                      previous.allSatisfy({ candidate in properties.contains { $0.declaration == candidate.declaration && $0.fileURL == candidate.fileURL } }) else { return nil }
            }
            result = properties
        }
        return result
    }

    /// Lookup metadata for a nominal type without conflating symbols from unrelated modules.
    func typeDeclaration(named name: String, visibleFrom fileURL: URL) -> SourceFileIndex.TypeDeclaration? {
        guard let keys = symbolTypeKeys(named: name, visibleFrom: fileURL), !keys.isEmpty else { return nil }
        var result: SourceFileIndex.TypeDeclaration?
        for key in keys {
            let candidates = typesByModule[key] ?? []
            guard candidates.count == 1, let declaration = candidates.first,
                  result == nil || result == declaration else { return nil }
            result = declaration
        }
        return result
    }

    /// Protocol receivers can expose concrete member annotations without solving associated types.
    func isProtocolDeclaration(named name: String, visibleFrom fileURL: URL) -> Bool {
        guard let keys = symbolTypeKeys(named: name, visibleFrom: fileURL), !keys.isEmpty else { return false }
        return keys.allSatisfy { symbolProtocolDeclarationsByModule[$0]?.count == 1 && typesByModule[$0] == nil }
    }

    func typeAlias(named name: String, visibleFrom fileURL: URL) -> SourceFileIndex.TypeAliasDeclaration? {
        guard let keys = symbolTypeKeys(named: name, visibleFrom: fileURL), !keys.isEmpty else { return nil }
        var result: SourceFileIndex.TypeAliasDeclaration?
        for key in keys {
            let candidates = aliasesByModule[key] ?? []
            guard candidates.count == 1, let declaration = candidates.first,
                  result == nil || result == declaration else { return nil }
            result = declaration
        }
        return result
    }

    func hasSymbolType(named name: String, visibleFrom fileURL: URL) -> Bool {
        guard let keys = symbolTypeKeys(named: name, visibleFrom: fileURL) else { return true }
        return !keys.isEmpty
    }

    struct FunctionSymbol: Equatable {
        var declaration: SourceFileIndex.FunctionDeclaration
        var fileURL: URL
    }

    struct PropertySymbol {
        var declaration: SourceFileIndex.PropertyDeclaration
        var fileURL: URL
    }

    /// Extension members are visible throughout a module and through ordinary transitive imports.
    /// Implementation-only imports can contribute inside their own module, but do not propagate.
    private func memberModuleContexts(visibleFrom fileURL: URL) -> [Set<String>] {
        guard let file = files[fileURL.standardizedFileURL.path] else { return [] }
        return file.moduleIdentifiers.map { module in
            memberModuleCache.value(for: module) {
                var names = (importsByModule[module] ?? []).union(["Swift"])
                var pending = Array(names)
                while let name = pending.popLast() {
                    for imported in memberImportsByModuleName[name] ?? [] where names.insert(imported).inserted {
                        pending.append(imported)
                    }
                }
                return Set([module]).union(names.flatMap { modulesByName[$0] ?? [] })
            }
        }
    }

    private func memberModules(visibleFrom fileURL: URL) -> Set<String> {
        memberModuleContexts(visibleFrom: fileURL).reduce(into: []) { $0.formUnion($1) }
    }

    private func memberIsAvailableInEveryContext(source: URL, visibility: String, caller: URL, owner: TypeKey? = nil, declaringType: String? = nil) -> Bool {
        guard let declaration = files[source.standardizedFileURL.path],
              let access = files[caller.standardizedFileURL.path], !access.moduleIdentifiers.isEmpty else { return false }
        let publicAccess = ["public", "open", "package"].contains(visibility)
        return zip(access.moduleIdentifiers, memberModuleContexts(visibleFrom: caller)).allSatisfy { module, visible in
            declaration.moduleIdentifiers.contains { declarationModule in
                guard visible.contains(declarationModule), publicAccess || declarationModule == module else { return false }
                guard let owner, let declaringType else { return true }
                guard let target = memberOwner(named: declaringType, visibleFrom: source, in: declarationModule) else { return false }
                return target.keys.contains { candidate in
                    candidate == owner || candidate.name == owner.name &&
                        typeSourceFilesByModule[candidate]?.count == 1 && typeSourceFilesByModule[candidate] == typeSourceFilesByModule[owner]
                }
            }
        }
    }

    /// Resolve an extension's owner in its own file, so equally named types in other modules
    /// cannot contribute members. Specialized aliases remain candidates but cannot supply a type.
    private func memberOwner(named name: String, visibleFrom fileURL: URL, in module: String? = nil, visited: Set<TypeKey> = []) -> MemberOwner? {
        // Cycle and depth failures depend on the ancestor set. Cache only root lookups.
        guard visited.isEmpty else {
            return resolveMemberOwner(named: name, visibleFrom: fileURL, in: module, visited: visited)
        }
        return memberOwnerCache.value(for: MemberOwnerKey(name: name, sourcePath: fileURL.standardizedFileURL.path, module: module)) {
            resolveMemberOwner(named: name, visibleFrom: fileURL, in: module, visited: [])
        }
    }

    private func resolveMemberOwner(named name: String, visibleFrom fileURL: URL, in module: String?, visited: Set<TypeKey>) -> MemberOwner? {
        guard visited.count < 32 else { return nil }
        guard let reference = ProjectTypeReference(name) else { return ([], true) }
        let keys: [TypeKey]?
        if let module, let file = files[fileURL.standardizedFileURL.path] {
            keys = symbolTypeKeys(named: reference.name, in: module, imports: file.imports, sourcePath: fileURL.standardizedFileURL.path)
        } else {
            keys = symbolTypeKeys(named: reference.name, visibleFrom: fileURL)
        }
        guard let keys else { return nil }
        var result = Set<TypeKey>()
        var constrained = !reference.arguments.isEmpty || reference.hasGenericParent
        for key in keys {
            guard !visited.contains(key) else { return nil }
            if let aliases = aliasesByModule[key] {
                guard aliases.count == 1, let alias = aliases.first,
                      let paths = typeSourceFilesByModule[key], paths.count == 1, let path = paths.first else { return nil }
                guard let reference = ProjectTypeReference(alias.type) else { continue }
                let targetName = declarationTypeKey(named: reference.name, relativeTo: alias.name, in: key.moduleIdentifier, visibleFrom: URL(fileURLWithPath: path)).name
                guard let target = memberOwner(named: targetName, visibleFrom: URL(fileURLWithPath: path), in: key.moduleIdentifier, visited: visited.union([key])) else { return nil }
                result.formUnion(target.keys)
                constrained = constrained || target.constrained || !alias.genericParameters.isEmpty ||
                    !reference.arguments.isEmpty || alias.hasUnresolvedConstraints == true
            } else {
                result.insert(key)
            }
        }
        return (result, constrained)
    }

    private func memberIsAccessible(visibility: String, owner: TypeKey, source: URL, module: String, caller: URL, accessingType: String?) -> Bool {
        if ["private", "fileprivate"].contains(visibility) {
            guard source.standardizedFileURL == caller.standardizedFileURL else { return false }
            if visibility == "private" {
                guard let accessingType else { return false }
                var name: String? = accessingType
                while let current = name {
                    if memberOwner(named: current, visibleFrom: caller)?.keys.contains(owner) == true {
                        return true
                    }
                    name = current.contains(".") ? current.split(separator: ".").dropLast().joined(separator: ".") : nil
                }
                return false
            }
            return true
        }
        return files[caller.standardizedFileURL.path]?.moduleIdentifiers.contains(module) == true ||
            ["public", "open", "package"].contains(visibility)
    }

    private func memberFunctions(named name: String, owner: TypeKey, visibleFrom caller: URL, accessingType: String? = nil) -> [FunctionSymbol]? {
        var result = [FunctionSymbol]()
        for module in memberModules(visibleFrom: caller) {
            for var symbol in symbolFunctionsByModule[module]?[name] ?? [] {
                guard let name = symbol.declaration.declaringType, accessibleTypeKey(owner, from: symbol.fileURL.standardizedFileURL.path) else { continue }
                guard let target = memberOwner(named: name, visibleFrom: symbol.fileURL, in: module) else {
                    guard !extensionOwnerMayRefer(to: owner, named: name, in: module, source: symbol.fileURL) else { return nil }
                    continue
                }
                guard target.keys.contains(owner),
                      memberIsAccessible(visibility: symbol.declaration.visibility, owner: owner, source: symbol.fileURL,
                                         module: module, caller: caller, accessingType: accessingType) else { continue }
                if target.constrained {
                    symbol.declaration.symbolHasUnresolvedConstraints = true
                }
                if !result.contains(symbol) {
                    result.append(symbol)
                }
            }
        }
        return result
    }

    private func memberProperties(named name: String, owner: TypeKey, visibleFrom caller: URL, accessingType: String? = nil) -> [PropertySymbol]? {
        var result = [PropertySymbol]()
        for module in memberModules(visibleFrom: caller) {
            for var symbol in symbolPropertiesByModule[module]?[name] ?? [] {
                guard accessibleTypeKey(owner, from: symbol.fileURL.standardizedFileURL.path) else { continue }
                guard let target = memberOwner(named: symbol.declaration.declaringType, visibleFrom: symbol.fileURL, in: module) else {
                    guard !extensionOwnerMayRefer(to: owner, named: symbol.declaration.declaringType, in: module, source: symbol.fileURL) else { return nil }
                    continue
                }
                guard target.keys.contains(owner),
                      memberIsAccessible(visibility: symbol.declaration.visibility ?? "internal", owner: owner, source: symbol.fileURL,
                                         module: module, caller: caller, accessingType: accessingType) else { continue }
                if target.constrained {
                    symbol.declaration.hasUnresolvedConstraints = true
                }
                if !result.contains(where: { $0.declaration == symbol.declaration && $0.fileURL == symbol.fileURL }) {
                    result.append(symbol)
                }
            }
        }
        return result
    }

    /// Resolve each parent in the declaration's lexical scope. Generic arguments are retained
    /// separately for receiver projection; member discovery only needs declaration identities.
    private func parentOwners(of owner: TypeKey, accessedFrom caller: URL, propertyName: String? = nil, functionName: String? = nil) -> [(key: TypeKey, source: URL)]? {
        guard let entries = inheritanceEntries(owner: owner, accessedFrom: caller) else {
            guard inheritanceDeclarationsByModule[owner] == nil else { return nil }
            // Hand-built indexes without generic metadata retain the conservative legacy path.
            guard let entries = conformanceSourcesByModule[owner] else { return [] }
            var result = [(key: TypeKey, source: URL)]()
            for entry in entries {
                for name in entry.parents.inheritedNamesToResolve {
                    let parentName = declarationTypeKey(named: name, relativeTo: owner.name, in: owner.moduleIdentifier, visibleFrom: entry.source).name
                    guard let parent = memberOwner(named: parentName, visibleFrom: entry.source, in: owner.moduleIdentifier),
                          !parent.constrained else { return nil }
                    if parent.keys.isEmpty {
                        guard propertyName.map({ standardInheritedPropertyIsAbsent(named: $0, owner: parentName, visibleFrom: caller) }) ?? true,
                              functionName.map({ standardInheritedFunctionIsAbsent(named: $0, owner: parentName, visibleFrom: caller) }) ?? true else { return nil }
                    }
                    result += parent.keys.map { ($0, entry.source) }
                }
            }
            return result
        }
        var result = [(key: TypeKey, source: URL)]()
        for entry in entries where !entry.declaration.types.isEmpty {
            guard entry.declaration.hasUnresolvedConstraints != true else { return nil }
            for inherited in entry.declaration.types {
                guard let reference = ProjectTypeReference(inherited),
                      let parent = lexicalMemberOwner(named: reference.name, namespace: entry.declaration.owner, visibleFrom: entry.source),
                      !parent.constrained else { return nil }
                if parent.keys.isEmpty {
                    // Known marker/value conformances have no arbitrary project members.
                    let standard: Set = ["AnyObject", "Sendable", "Equatable", "Hashable", "Encodable", "Decodable", "Codable", "Error", "LocalizedError", "CaseIterable", "RawRepresentable", "Identifiable", "CustomStringConvertible", "CustomDebugStringConvertible", "String", "Int", "UInt", "Int8", "Int16", "Int32", "Int64", "UInt8", "UInt16", "UInt32", "UInt64"]
                    let name = reference.name.hasPrefix("Swift.") ? String(reference.name.dropFirst(6)) : reference.name
                    guard standard.contains(name), isStandardLibraryTypeName(reference.name, visibleFrom: entry.source),
                          propertyName.map({ standardInheritedPropertyIsAbsent(named: $0, owner: reference.name, visibleFrom: caller) }) ?? true,
                          functionName.map({ standardInheritedFunctionIsAbsent(named: $0, owner: reference.name, visibleFrom: caller) }) ?? true else { return nil }
                    continue
                }
                guard parent.keys.allSatisfy({ typesByModule[$0]?.count == 1 || symbolProtocolDeclarationsByModule[$0]?.count == 1 }) else { return nil }
                result += parent.keys.map { ($0, entry.source) }
            }
        }
        return result
    }

    /// A property's declaration owner is retained so generic arguments can be projected along
    /// superclass chains. Direct properties shadow inherited requirements; ambiguous paths decline.
    private func propertyCandidates(named name: String, owner: TypeKey, visibleFrom caller: URL,
                                    accessingType: String?, visited: Set<TypeKey> = []) -> [PropertySymbol]?
    {
        guard visited.count < 32, !visited.contains(owner),
              let direct = memberProperties(named: name, owner: owner, visibleFrom: caller, accessingType: accessingType) else { return nil }
        if !direct.isEmpty {
            guard direct.allSatisfy({
                memberIsAvailableInEveryContext(source: $0.fileURL, visibility: $0.declaration.visibility ?? "internal", caller: caller,
                                                owner: owner, declaringType: $0.declaration.declaringType)
            }) else { return nil }
            return direct
        }
        guard let parents = parentOwners(of: owner, accessedFrom: caller, propertyName: name) else { return nil }
        var result = [PropertySymbol]()
        for parent in parents {
            guard typesByModule[parent.key]?.count == 1 || symbolProtocolDeclarationsByModule[parent.key]?.count == 1,
                  let symbols = propertyCandidates(named: name, owner: parent.key, visibleFrom: caller,
                                                   accessingType: accessingType, visited: visited.union([owner])) else { return nil }
            for symbol in symbols where !result.contains(where: { $0.declaration == symbol.declaration && $0.fileURL == symbol.fileURL }) {
                result.append(symbol)
            }
        }
        return result
    }

    /// Overloads participate across the complete indexed ancestry, including declarations whose
    /// labels differ. A same-named callable property or an unknown ancestor prevents selection.
    private func functionCandidates(named name: String, owner: TypeKey, visibleFrom caller: URL,
                                    accessingType: String?, visited: Set<TypeKey> = []) -> [FunctionSymbol]?
    {
        guard visited.count < 32, !visited.contains(owner),
              typesByModule[owner]?.count == 1 || symbolProtocolDeclarationsByModule[owner]?.count == 1,
              let direct = memberFunctions(named: name, owner: owner, visibleFrom: caller, accessingType: accessingType),
              let properties = memberProperties(named: name, owner: owner, visibleFrom: caller, accessingType: accessingType),
              properties.isEmpty, let parents = parentOwners(of: owner, accessedFrom: caller, functionName: name),
              direct.allSatisfy({
                  memberIsAvailableInEveryContext(source: $0.fileURL, visibility: $0.declaration.visibility, caller: caller,
                                                  owner: owner, declaringType: $0.declaration.declaringType)
              }) else { return nil }
        var result = direct
        for parent in parents {
            guard let inherited = functionCandidates(named: name, owner: parent.key, visibleFrom: caller,
                                                     accessingType: accessingType, visited: visited.union([owner])) else { return nil }
            for symbol in inherited where !result.contains(symbol) {
                result.append(symbol)
            }
        }
        return result
    }

    /// Standard protocol requirements are known even when the standard library isn't indexed.
    /// A project extension can still add a property, so absence requires checking those too.
    private func standardInheritedPropertyIsAbsent(named name: String, owner: String, visibleFrom caller: URL) -> Bool {
        let properties: [String: Set<String>] = [
            "AnyObject": [], "Sendable": [], "Equatable": [], "Hashable": ["hashValue"],
            "Encodable": [], "Decodable": [], "Codable": [], "Error": ["_domain", "_code", "_userInfo"],
            "CaseIterable": ["allCases"], "RawRepresentable": ["rawValue"], "Identifiable": ["id"],
            "CustomStringConvertible": ["description"], "CustomDebugStringConvertible": ["debugDescription"],
        ]
        let unqualified = owner.hasPrefix("Swift.") ? String(owner.dropFirst(6)) : owner
        guard let members = properties[unqualified], !members.contains(name) else { return false }
        return !hasStandardLibraryMember(named: name, types: [unqualified], visibleFrom: caller)
    }

    private func standardInheritedFunctionIsAbsent(named name: String, owner: String, visibleFrom caller: URL) -> Bool {
        let functions: [String: Set<String>] = [
            "AnyObject": [], "Sendable": [], "Equatable": ["==", "!="], "Hashable": ["hash", "hashValue"],
            "Encodable": ["encode"], "Decodable": ["init"], "Codable": ["init", "encode"],
            "Error": [], "LocalizedError": [], "CaseIterable": [], "RawRepresentable": ["init"],
            "Identifiable": [], "CustomStringConvertible": [], "CustomDebugStringConvertible": [],
            "String": [], "Int": [], "UInt": [], "Int8": [], "Int16": [], "Int32": [], "Int64": [],
            "UInt8": [], "UInt16": [], "UInt32": [], "UInt64": [],
        ]
        let unqualified = owner.hasPrefix("Swift.") ? String(owner.dropFirst(6)) : owner
        guard let members = functions[unqualified], !members.contains(name) else { return false }
        return !hasStandardLibraryMember(named: name, types: [unqualified], visibleFrom: caller)
    }

    /// Labels alone cannot select a method while inherited overloads may participate.
    private func hasNoInheritedFunction(named name: String, owner: TypeKey, sourcePath: String, accessedFrom caller: URL, visited: Set<TypeKey> = [], includingProperties: Bool = false) -> Bool {
        guard visited.isEmpty else {
            return resolveNoInheritedFunction(named: name, owner: owner, sourcePath: sourcePath, accessedFrom: caller, visited: visited, includingProperties: includingProperties)
        }
        return inheritedFunctionCache.value(for: InheritedFunctionKey(name: name, owner: owner, sourcePath: sourcePath, callerPath: caller.standardizedFileURL.path, includingProperties: includingProperties)) {
            resolveNoInheritedFunction(named: name, owner: owner, sourcePath: sourcePath, accessedFrom: caller, visited: [], includingProperties: includingProperties)
        }
    }

    private func resolveNoInheritedFunction(named name: String, owner: TypeKey, sourcePath _: String, accessedFrom caller: URL, visited: Set<TypeKey>, includingProperties: Bool) -> Bool {
        guard visited.count < 32, !visited.contains(owner),
              let parents = parentOwners(of: owner, accessedFrom: caller,
                                         propertyName: includingProperties ? name : nil, functionName: name) else { return false }
        for parent in parents {
            if includingProperties {
                guard dynamicMemberLookupTypesByModule[parent.key.moduleIdentifier]?.contains(parent.key.name) != true,
                      memberProperties(named: name, owner: parent.key, visibleFrom: caller)?.isEmpty == true else { return false }
            }
            guard memberFunctions(named: name, owner: parent.key, visibleFrom: caller)?.isEmpty == true,
                  hasNoInheritedFunction(named: name, owner: parent.key, sourcePath: parent.source.path,
                                         accessedFrom: caller, visited: visited.union([owner]), includingProperties: includingProperties) else { return false }
        }
        return true
    }

    /// Whether a known standard-library spelling is unshadowed in this source context.
    func isStandardLibraryTypeName(_ name: String, visibleFrom source: URL) -> Bool {
        if name.hasPrefix("Swift."), hasSymbolType(named: "Swift", visibleFrom: source) {
            return false
        }
        guard typeAlias(named: name, visibleFrom: source) == nil else { return false }
        if let identity = typeIdentity(named: name, visibleFrom: source) {
            return !identity.isEmpty && identity.allSatisfy { $0.hasPrefix("Swift:") }
        }
        return !hasSymbolType(named: name, visibleFrom: source)
    }

    /// Project extensions may overload standard-library collection operations. Without an indexed
    /// standard-library signature, their presence prevents assuming the built-in operation's type.
    func hasCollectionMember(named name: String, kind: String, visibleFrom fileURL: URL) -> Bool {
        hasStandardLibraryMember(named: name, types: [kind, "Sequence", "Collection", "BidirectionalCollection", "RandomAccessCollection",
                                                      "MutableCollection", "RangeReplaceableCollection"], visibleFrom: fileURL)
    }

    /// Project members, including alias and protocol extensions, can override a known builtin signature.
    func hasStandardLibraryMember(named name: String, types: [String], visibleFrom fileURL: URL) -> Bool {
        standardMemberCache.value(for: StandardMemberKey(name: name, types: types, sourcePath: fileURL.standardizedFileURL.path)) {
            resolveStandardLibraryMember(named: name, types: types, visibleFrom: fileURL)
        }
    }

    private func resolveStandardLibraryMember(named name: String, types: [String], visibleFrom fileURL: URL) -> Bool {
        guard files[fileURL.standardizedFileURL.path] != nil else { return true }
        let roots = Set(types + types.map { "Swift." + $0 })
        let modules = memberModules(visibleFrom: fileURL)
        var pending = Set<TypeKey>()
        func enqueue(_ parents: [String], relativeTo owner: String, in source: URL) {
            for parent in parents.inheritedNamesToResolve {
                if let keys = symbolTypeKeys(named: parent, visibleFrom: source) {
                    pending.formUnion(keys)
                }
                // An unqualified nested protocol may need the declaration's lexical namespace.
                if !parent.contains("."), let sourceFile = files[source.standardizedFileURL.path] {
                    for module in sourceFile.moduleIdentifiers {
                        let key = declarationTypeKey(named: parent, relativeTo: owner, in: module, visibleFrom: source)
                        if protocolsByModule.contains(key) || aliasesByModule[key] != nil {
                            pending.insert(key)
                        }
                    }
                }
            }
        }
        for module in modules {
            for root in roots {
                let key = TypeKey(moduleIdentifier: module, name: root)
                for entry in conformanceSourcesByModule[key] ?? [] where isStandardLibraryTypeName(root, visibleFrom: entry.source) {
                    enqueue(entry.parents, relativeTo: root, in: entry.source)
                }
            }
        }
        var visited = Set<TypeKey>()
        while let key = pending.popFirst() {
            guard visited.insert(key).inserted else { continue }
            for entry in conformanceSourcesByModule[key] ?? [] {
                enqueue(entry.parents, relativeTo: key.name, in: entry.source)
            }
            for alias in aliasesByModule[key] ?? [] {
                let formatter = Formatter(tokenize(alias.type))
                guard alias.genericParameters.isEmpty, alias.hasUnresolvedConstraints != true,
                      let reference = formatter.parseType(at: 0),
                      let source = typeSourceFilesByModule[key]?.first else { return true }
                enqueue(reference.indexedNominalTypeNames, relativeTo: key.name, in: URL(fileURLWithPath: source))
            }
        }
        func isRelevantOwner(_ owner: String, source: URL, aliasesVisited: Set<TypeKey> = []) -> Bool {
            if roots.contains(owner), isStandardLibraryTypeName(owner, visibleFrom: source) {
                return true
            }
            guard let keys = symbolTypeKeys(named: owner, visibleFrom: source) else { return true }
            if keys.contains(where: { visited.contains($0) }) {
                return true
            }
            for key in keys where !aliasesVisited.contains(key) {
                for alias in aliasesByModule[key] ?? [] {
                    guard let path = typeSourceFilesByModule[key]?.first else { return true }
                    let aliasSource = URL(fileURLWithPath: path)
                    let tokens = tokenize(alias.type).filter { !$0.isSpaceOrCommentOrLinebreak }
                    if tokens.first == .startOfScope("[") {
                        return types.contains("Sequence")
                    }
                    if let target = ProjectTypeReference(alias.type),
                       isRelevantOwner(target.name, source: aliasSource, aliasesVisited: aliasesVisited.union([key]))
                    {
                        return true
                    }
                }
            }
            return false
        }
        let qualifiedOwners = visited.compactMap { key in moduleNamesByIdentifier[key.moduleIdentifier].map { $0 + "." + key.name } }
        let aliasOwners = aliasesByModule.keys.filter { modules.contains($0.moduleIdentifier) }.flatMap { key in
            [key.name] + (moduleNamesByIdentifier[key.moduleIdentifier].map { [$0 + "." + key.name] } ?? [])
        }
        let ownerNames = roots.union(visited.map(\.name)).union(qualifiedOwners).union(aliasOwners)
        for module in modules where moduleNamesByIdentifier[module] != "Swift" {
            for candidate in symbolFunctionsByModule[module]?[name] ?? [] {
                if let owner = candidate.declaration.declaringType, isRelevantOwner(owner, source: candidate.fileURL) {
                    return true
                }
            }
            for owner in ownerNames {
                let key = TypeKey(moduleIdentifier: module, name: owner + "." + name)
                if propertySourceFilesByModule[key]?.contains(where: { isRelevantOwner(owner, source: URL(fileURLWithPath: $0)) }) == true {
                    return true
                }
            }
        }
        return false
    }

    /// A generic bound is written in its callable's lexical scope, where aliases and inherited
    /// names can shadow a top-level protocol with the same spelling.
    private func lexicalMemberOwner(named name: String, namespace: String?, visibleFrom source: URL) -> MemberOwner? {
        guard let reference = ProjectTypeReference(name), reference.arguments.isEmpty, !reference.hasGenericParent else { return nil }
        var namespace = namespace
        while let owner = namespace {
            let qualified = owner + "." + name
            if hasSymbolType(named: qualified, visibleFrom: source) || typeAlias(named: qualified, visibleFrom: source) != nil {
                return memberOwner(named: qualified, visibleFrom: source)
            }
            let components = name.split(separator: ".")
            if let root = components.first {
                switch inheritedType(named: String(root), of: owner, visibleFrom: source) {
                case let .type(inherited, inheritedSource):
                    return memberOwner(named: ([inherited] + components.dropFirst().map(String.init)).joined(separator: "."), visibleFrom: inheritedSource)
                case .unknown: return nil
                case .absent: break
                }
            }
            namespace = owner.contains(".") ? owner.split(separator: ".").dropLast().joined(separator: ".") : nil
        }
        return memberOwner(named: name, visibleFrom: source)
    }

    /// Resolve a function signature through its receiver or the caller's explicit imports.
    func functionSymbol(named name: String, receiver: FunctionCallReceiver, arguments: [String?],
                        visibleFrom fileURL: URL, ignoringLabelAt ignoredLabel: Int? = nil, accessedFrom accessURL: URL? = nil, accessedFromType accessType: String? = nil,
                        kind: SourceFileIndex.FunctionDeclaration.Kind = .function, closureArguments: Set<Int> = []) -> FunctionSymbol?
    {
        guard let file = files[fileURL.standardizedFileURL.path], !file.moduleIdentifiers.isEmpty else { return nil }
        let caller = accessURL ?? fileURL
        func acceptsClosureArguments(_ symbol: FunctionSymbol) -> Bool {
            guard !closureArguments.isEmpty,
                  let indices = symbol.declaration.parameterIndices(matching: arguments, ignoringLabelAt: ignoredLabel),
                  let types = symbol.declaration.symbolArgumentTypes else { return true }
            return closureArguments.allSatisfy { position in
                guard indices.indices.contains(position), types.indices.contains(indices[position]),
                      let bounds = symbol.declaration.genericConstraints?[types[indices[position]]] else { return true }
                // A function value cannot supply a nominal protocol's methods or associated types.
                // Unknown bounds and marker protocols remain possible overloads.
                return !bounds.contains { bound in
                    guard let target = lexicalMemberOwner(named: bound, namespace: symbol.declaration.declaringType, visibleFrom: symbol.fileURL),
                          !target.constrained, !target.keys.isEmpty else { return false }
                    return target.keys.allSatisfy { key in
                        let declarations = symbolProtocolDeclarationsByModule[key] ?? []
                        return declarations.count == 1 && declarations[0].hasRequirements == true
                    }
                }
            }
        }
        func matches(in module: String, receiver: FunctionCallReceiver) -> [FunctionSymbol] {
            (symbolFunctionsByModule[module]?[name] ?? []).filter {
                let visibility = $0.declaration.visibility
                let accessible = ["private", "fileprivate"].contains(visibility)
                    ? $0.fileURL.standardizedFileURL == caller.standardizedFileURL
                    : files[caller.standardizedFileURL.path]?.moduleIdentifiers.contains(module) == true || ["public", "open", "package"].contains(visibility)
                if visibility == "private", let owner = $0.declaration.declaringType,
                   accessType != owner, accessType?.hasPrefix(owner + ".") != true
                {
                    return false
                }
                let matchesReceiver: Bool
                if kind == .initializer, case let .type(owner) = receiver {
                    matchesReceiver = $0.declaration.declaringType == owner
                } else {
                    matchesReceiver = $0.declaration.matches(receiver: receiver)
                }
                return accessible && $0.declaration.kind == kind && matchesReceiver && acceptsClosureArguments($0) &&
                    $0.declaration.parameterIndices(matching: arguments, ignoringLabelAt: ignoredLabel) != nil
            }
        }
        var candidates = [FunctionSymbol]()
        switch receiver {
        case let .instance(owner), let .type(owner):
            guard let keys = symbolTypeKeys(named: owner, visibleFrom: fileURL) else { return nil }
            for key in keys {
                let members = kind == .initializer
                    ? memberFunctions(named: name, owner: key, visibleFrom: caller, accessingType: accessType)
                    : functionCandidates(named: name, owner: key, visibleFrom: caller, accessingType: accessType)
                guard let members else { return nil }
                let matching = members.filter { symbol in
                    guard let owner = symbol.declaration.declaringType, symbol.declaration.kind == kind, acceptsClosureArguments(symbol),
                          symbol.declaration.parameterIndices(matching: arguments, ignoringLabelAt: ignoredLabel) != nil else { return false }
                    if kind == .initializer, case .type = receiver {
                        return true
                    }
                    let normalized: FunctionCallReceiver
                    if case .type = receiver {
                        normalized = .type(owner)
                    } else {
                        normalized = .instance(type: owner)
                    }
                    return symbol.declaration.matches(receiver: normalized)
                }
                guard matching.count == 1, let selected = matching.first,
                      memberIsAvailableInEveryContext(source: selected.fileURL, visibility: selected.declaration.visibility, caller: caller),
                      kind != .initializer || hasNoInheritedFunction(named: name, owner: key, sourcePath: typeSourceFilesByModule[key]?.first ?? fileURL.path, accessedFrom: caller) else { return nil }
                candidates += matching
            }
        case let .unqualified(owner, isStatic):
            for module in file.moduleIdentifiers {
                var local = [FunctionSymbol]()
                if let owner {
                    guard let keys = symbolTypeKeys(named: owner, visibleFrom: fileURL), !keys.isEmpty else { return nil }
                    for key in keys {
                        guard let members = functionCandidates(named: name, owner: key, visibleFrom: caller, accessingType: accessType) else { return nil }
                        let matching = members.filter { symbol in
                            symbol.declaration.kind == kind && acceptsClosureArguments(symbol) &&
                                symbol.declaration.matches(receiver: .unqualified(declaringType: symbol.declaration.declaringType, isStatic: isStatic)) &&
                                symbol.declaration.parameterIndices(matching: arguments, ignoringLabelAt: ignoredLabel) != nil
                        }
                        guard matching.allSatisfy({ symbol in
                            memberIsAvailableInEveryContext(source: symbol.fileURL, visibility: symbol.declaration.visibility, caller: caller)
                        }) else { return nil }
                        local += matching
                    }
                } else {
                    local = matches(in: module, receiver: .unqualified(declaringType: nil, isStatic: false))
                }
                if local.isEmpty, owner != nil {
                    local = matches(in: module, receiver: .unqualified(declaringType: nil, isStatic: false))
                }
                if local.isEmpty {
                    var imported = [[FunctionSymbol]]()
                    for importedName in importedModuleNames(file.imports) {
                        let matches = (modulesByName[importedName] ?? []).flatMap {
                            matches(in: $0, receiver: .unqualified(declaringType: nil, isStatic: false)).filter {
                                ["public", "open", "package"].contains($0.declaration.visibility)
                            }
                        }
                        if !matches.isEmpty {
                            imported.append(matches)
                        }
                    }
                    guard imported.count == 1, let matches = imported.first else { return nil }
                    local = matches.reduce(into: []) { unique, candidate in
                        if !unique.contains(candidate) {
                            unique.append(candidate)
                        }
                    }
                }
                guard local.count == 1 else { return nil }
                candidates += local
            }
        }
        guard let first = candidates.first, first.declaration.symbolHasUnresolvedConstraints != true,
              candidates.allSatisfy({ $0 == first }),
              first.declaration.declaringType == nil ||
              memberIsAvailableInEveryContext(source: first.fileURL, visibility: first.declaration.visibility, caller: caller) else { return nil }
        return first
    }

    /// Operator syntax alone cannot establish that the standard-library overload is selected.
    func hasOperatorFunction(named name: String, visibleFrom fileURL: URL) -> Bool {
        guard let file = files[fileURL.standardizedFileURL.path] else { return true }
        let modules = Set(file.moduleIdentifiers + importedModuleNames(file.imports).flatMap { modulesByName[$0] ?? [] })
        for module in modules where moduleNamesByIdentifier[module] != "Swift" {
            if (symbolFunctionsByModule[module]?[name] ?? []).contains(where: { symbol in
                let visibility = symbol.declaration.visibility
                if ["private", "fileprivate"].contains(visibility) {
                    return symbol.fileURL.standardizedFileURL == fileURL.standardizedFileURL
                }
                return file.moduleIdentifiers.contains(module) || ["public", "open", "package"].contains(visibility)
            }) {
                return true
            }
        }
        return false
    }

    /// The declaration and compilation modules that a resolved nominal type refers to.
    func typeIdentity(named name: String, visibleFrom fileURL: URL) -> Set<String>? {
        guard let keys = symbolTypeKeys(named: name, visibleFrom: fileURL), !keys.isEmpty else { return nil }
        var result = Set<String>()
        for key in keys {
            guard let paths = typeSourceFilesByModule[key], paths.count == 1, let path = paths.first else { return nil }
            let module = files[path]?.moduleNames[key.moduleIdentifier] ?? key.moduleIdentifier
            result.insert("\(module):\(path):\(key.name)")
        }
        return result
    }

    func typeSourceFile(named name: String, visibleFrom fileURL: URL) -> URL? {
        guard let keys = symbolTypeKeys(named: name, visibleFrom: fileURL), !keys.isEmpty else { return nil }
        let paths = keys.reduce(into: Set<String>()) { $0.formUnion(typeSourceFilesByModule[$1] ?? []) }
        return paths.count == 1 ? paths.first.map { URL(fileURLWithPath: $0) } : nil
    }

    /// Disambiguate imported types by arity, retaining the selected declaration's lookup context.
    func typeSymbol(named name: String, genericArgumentCount: Int, visibleFrom fileURL: URL) -> SymbolType? {
        guard let keys = symbolTypeKeys(named: name, visibleFrom: fileURL, genericArgumentCount: genericArgumentCount), !keys.isEmpty else { return nil }
        var result: SymbolType?
        for key in keys {
            guard let paths = typeSourceFilesByModule[key], paths.count == 1, let path = paths.first,
                  result == nil || result?.name == key.name && result?.fileURL.path == path else { return nil }
            result = SymbolType(name: key.name, namespace: nil, fileURL: URL(fileURLWithPath: path))
        }
        return result
    }

    private func symbolTypeKeys(named name: String, visibleFrom fileURL: URL, genericArgumentCount: Int? = nil) -> [TypeKey]? {
        guard let file = files[fileURL.standardizedFileURL.path], !file.moduleIdentifiers.isEmpty else { return nil }
        var result = [TypeKey]()
        var missing = false
        for module in file.moduleIdentifiers {
            guard let keys = symbolTypeKeys(named: name, in: module, imports: file.imports, sourcePath: fileURL.standardizedFileURL.path, genericArgumentCount: genericArgumentCount) else { return nil }
            missing = missing || keys.isEmpty
            result += keys
        }
        return missing && !result.isEmpty ? nil : result
    }

    private func accessibleTypeKey(_ key: TypeKey, from path: String, inherited: Bool = false) -> Bool {
        let sameModule = files[path]?.moduleIdentifiers.contains(key.moduleIdentifier) == true
        return (typeVisibilitiesByModule[key] ?? []).contains { source, visibility in
            if inherited, visibility == "private" {
                return false
            }
            return source == path || sameModule && !["private", "fileprivate"].contains(visibility) ||
                ["public", "open", "package"].contains(visibility)
        }
    }

    /// A module qualifier is not an enclosing nominal scope and cannot introduce inherited names.
    func isModuleNamespace(_ name: String, visibleFrom fileURL: URL) -> Bool {
        guard !name.contains("."), let file = files[fileURL.standardizedFileURL.path],
              let keys = symbolTypeKeys(named: name, visibleFrom: fileURL), keys.isEmpty else { return false }
        return file.moduleIdentifiers.contains { moduleNamesByIdentifier[$0] == name } ||
            importedModuleNames(file.imports).contains(name)
    }

    private func importedModuleNames(_ imports: [String]) -> Set<String> {
        var result = Set(imports).union(["Swift"])
        var pending = imports + ["Swift"]
        while let name = pending.popLast() {
            for exported in exportsByModuleName[name] ?? [] where result.insert(exported).inserted {
                pending.append(exported)
            }
        }
        return result
    }

    private func symbolTypeKeys(named name: String, in module: String, imports: [String], sourcePath: String, genericArgumentCount: Int? = nil, allowingAmbiguity: Bool = false) -> [TypeKey]? {
        func matchesArity(_ key: TypeKey) -> Bool {
            guard let count = genericArgumentCount else { return true }
            let declarations = typesByModule[key] ?? []
            let aliases = aliasesByModule[key] ?? []
            return declarations.contains(where: { $0.genericParameters.count == count }) ||
                aliases.contains(where: { $0.genericParameters.count == count }) || protocolsByModule.contains(key)
        }
        let direct = TypeKey(moduleIdentifier: module, name: name)
        if accessibleTypeKey(direct, from: sourcePath) {
            return [direct]
        }
        // A local nominal root shadows an imported namesake even when the requested nested
        // declaration is absent. A value member must not turn into an unrelated imported type.
        if let root = name.split(separator: ".").first, name.contains("."),
           accessibleTypeKey(TypeKey(moduleIdentifier: module, name: String(root)), from: sourcePath)
        {
            return []
        }
        let prefix = moduleNamesByIdentifier[module].map { $0 + "." }
        let localName = prefix.flatMap { name.hasPrefix($0) ? String(name.dropFirst($0.count)) : nil } ?? name
        let local = TypeKey(moduleIdentifier: module, name: localName)
        if accessibleTypeKey(local, from: sourcePath) {
            return [local]
        }
        if localName != name, let root = localName.split(separator: ".").first,
           accessibleTypeKey(TypeKey(moduleIdentifier: module, name: String(root)), from: sourcePath)
        {
            return []
        }
        var matches = [[TypeKey]]()
        for imported in importedModuleNames(imports) {
            let qualifiedPrefix = imported + "."
            let importedName = name.hasPrefix(qualifiedPrefix) ? String(name.dropFirst(qualifiedPrefix.count)) : name
            let keys = (modulesByName[imported] ?? []).map { TypeKey(moduleIdentifier: $0, name: importedName) }
                .filter { accessibleTypeKey($0, from: sourcePath) && matchesArity($0) }
            if !keys.isEmpty {
                matches.append(keys)
            }
        }
        guard allowingAmbiguity || matches.count <= 1 else { return nil }
        return matches.flatMap { $0 }
    }
}
