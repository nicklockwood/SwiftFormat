//
//  ProjectIndex.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 10/01/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

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
        var name: String
        var declaringType: String?
        var argumentLabels: [String?]
        var closureArgumentIndices: [Int]
        var autoclosureArgumentIndices: [Int]

        init(
            name: String,
            declaringType: String? = nil,
            argumentLabels: [String?],
            closureArgumentIndices: [Int] = [],
            autoclosureArgumentIndices: [Int]
        ) {
            self.name = name
            self.declaringType = declaringType
            self.argumentLabels = argumentLabels
            self.closureArgumentIndices = closureArgumentIndices
            self.autoclosureArgumentIndices = autoclosureArgumentIndices
        }

        private enum CodingKeys: CodingKey {
            case name
            case declaringType
            case argumentLabels
            case closureArgumentIndices
            case autoclosureArgumentIndices
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            declaringType = try container.decodeIfPresent(String.self, forKey: .declaringType)
            argumentLabels = try container.decode([String?].self, forKey: .argumentLabels)
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

    struct TypeMembers: Codable, Equatable {
        var typeName: String
        var instanceMembers: [String]
        var staticMembers: [String]
    }

    static let schemaVersion = 4

    var schemaVersion = SourceFileIndex.schemaVersion
    var contentHash: String
    var moduleIdentifier: String?
    var typeDeclarations: [TypeDeclaration]
    var functionDeclarations: [FunctionDeclaration]
    var typeMembers: [TypeMembers]

    init(
        contentHash: String,
        moduleIdentifier: String?,
        typeDeclarations: [TypeDeclaration],
        functionDeclarations: [FunctionDeclaration],
        typeMembers: [TypeMembers]
    ) {
        self.contentHash = contentHash
        self.moduleIdentifier = moduleIdentifier
        self.typeDeclarations = typeDeclarations
        self.functionDeclarations = functionDeclarations
        self.typeMembers = typeMembers
    }

    private enum CodingKeys: CodingKey {
        case schemaVersion
        case contentHash
        case moduleIdentifier
        case typeDeclarations
        case functionDeclarations
        case typeMembers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        contentHash = try container.decode(String.self, forKey: .contentHash)
        moduleIdentifier = try container.decodeIfPresent(String.self, forKey: .moduleIdentifier)
        typeDeclarations = try container.decode([TypeDeclaration].self, forKey: .typeDeclarations)
        functionDeclarations = try container.decodeIfPresent(
            [FunctionDeclaration].self,
            forKey: .functionDeclarations
        ) ?? []
        typeMembers = try container.decodeIfPresent([TypeMembers].self, forKey: .typeMembers) ?? []
    }
}

/// A read-only view of all source summaries discovered for a formatting run.
struct ProjectIndex {
    struct MemberNamesByType: Equatable {
        static let empty = MemberNamesByType()

        var instance = [String: Set<String>]()
        var staticOrClass = [String: Set<String>]()
    }

    private struct TypeKey: Hashable {
        var moduleIdentifier: String
        var name: String
    }

    let files: [String: SourceFileIndex]
    let fingerprint: String
    private let typeVisibilities: [TypeKey: Set<String>]
    private let autoclosureFunctionNamesByModule: [String: Set<String>]
    private let functionDeclarationsByModule: [String: [String: [SourceFileIndex.FunctionDeclaration]]]
    private let memberNamesByModule: [String: MemberNamesByType]

    init(files: [String: SourceFileIndex]) {
        self.files = files
        var typeVisibilities = [TypeKey: Set<String>]()
        var autoclosureFunctionNamesByModule = [String: Set<String>]()
        var functionDeclarationsByModule = [String: [String: [SourceFileIndex.FunctionDeclaration]]]()
        var memberNamesByModule = [String: MemberNamesByType]()
        for file in files.values {
            guard let moduleIdentifier = file.moduleIdentifier else { continue }
            for declaration in file.typeDeclarations {
                let key = TypeKey(moduleIdentifier: moduleIdentifier, name: declaration.name)
                typeVisibilities[key, default: []].insert(declaration.visibility)
            }
            for declaration in file.functionDeclarations {
                if !declaration.autoclosureArgumentIndices.isEmpty {
                    autoclosureFunctionNamesByModule[moduleIdentifier, default: []].insert(declaration.name)
                }
                functionDeclarationsByModule[moduleIdentifier, default: [:]][declaration.name, default: []]
                    .append(declaration)
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
        }
        self.typeVisibilities = typeVisibilities
        self.autoclosureFunctionNamesByModule = autoclosureFunctionNamesByModule
        self.functionDeclarationsByModule = functionDeclarationsByModule
        self.memberNamesByModule = memberNamesByModule
        let description = files.keys.sorted().compactMap { path -> String? in
            guard let file = files[path] else { return nil }
            let types = file.typeDeclarations
                .map { "\($0.name):\($0.visibility)" }
                .sorted()
                .joined(separator: ",")
            let functions = file.functionDeclarations
                .map { declaration in
                    let labels = declaration.argumentLabels.map { $0 ?? "_" }.joined(separator: ",")
                    let closures = declaration.closureArgumentIndices.map(String.init).joined(separator: ",")
                    let indices = declaration.autoclosureArgumentIndices.map(String.init).joined(separator: ",")
                    return "\(declaration.declaringType ?? "").\(declaration.name)(\(labels)):\(closures):\(indices)"
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
            return "\(file.moduleIdentifier ?? ""):\(types):\(functions):\(members)"
        }.joined(separator: ";")
        fingerprint = computeHash(description)
    }

    /// Whether the given type is unambiguously internal in the current file's module.
    func isInternalType(named name: String, from fileURL: URL) -> Bool {
        let path = fileURL.standardizedFileURL.path
        guard let moduleIdentifier = files[path]?.moduleIdentifier else {
            return false
        }
        let key = TypeKey(moduleIdentifier: moduleIdentifier, name: name)
        return typeVisibilities[key] == [Visibility.internal.rawValue]
    }

    /// Project functions in the current file's module that have at least one `@autoclosure` argument.
    func autoclosureFunctionNames(visibleFrom fileURL: URL) -> Set<String> {
        let path = fileURL.standardizedFileURL.path
        guard let moduleIdentifier = files[path]?.moduleIdentifier else {
            return []
        }
        return autoclosureFunctionNamesByModule[moduleIdentifier] ?? []
    }

    /// Whether a same-module declaration makes removing the final closure label unambiguous.
    func supportsTrailingClosure(
        functionNamed name: String,
        declaredInType declaringType: String?,
        argumentLabels: [String?],
        visibleFrom fileURL: URL
    ) -> Bool {
        let path = fileURL.standardizedFileURL.path
        guard let moduleIdentifier = files[path]?.moduleIdentifier,
              let declarations = functionDeclarationsByModule[moduleIdentifier]?[name]?
              .filter({ $0.declaringType == declaringType }),
              let finalArgumentIndex = argumentLabels.indices.last,
              declarations.contains(where: {
                  $0.argumentLabels == argumentLabels &&
                      $0.closureArgumentIndices.contains(finalArgumentIndex)
              })
        else { return false }

        let precedingLabels = argumentLabels.dropLast()
        return declarations.allSatisfy { declaration in
            guard declaration.argumentLabels.count == argumentLabels.count,
                  declaration.argumentLabels.dropLast().elementsEqual(precedingLabels),
                  declaration.closureArgumentIndices.contains(finalArgumentIndex)
            else { return true }
            return declaration.argumentLabels.last == argumentLabels.last
        }
    }

    /// Project-defined instance and static/class members grouped by type in the current file's module.
    func memberNamesByType(visibleFrom fileURL: URL) -> MemberNamesByType {
        let path = fileURL.standardizedFileURL.path
        guard let moduleIdentifier = files[path]?.moduleIdentifier else {
            return .empty
        }
        return memberNamesByModule[moduleIdentifier] ?? .empty
    }
}

/// Extracts the subset of declarations required by the initial project-aware rules.
func makeSourceFileIndex(
    from source: String,
    moduleIdentifier: String?
) -> SourceFileIndex {
    let formatter = Formatter(tokenize(source))
    var typeDeclarations = [SourceFileIndex.TypeDeclaration]()
    var functionDeclarations = [SourceFileIndex.FunctionDeclaration]()
    var typeMembers = [SourceFileIndex.TypeMembers]()
    formatter.parseDeclarations().forEachRecursiveDeclaration { declaration in
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

        guard declaration.keyword == "func",
              ![Visibility.private, .fileprivate].contains(declaration.visibility()),
              let function = formatter.parseFunctionDeclaration(keywordIndex: declaration.keywordIndex),
              let name = function.name
        else { return }
        let autoclosureArgumentIndices = function.arguments.indices.filter { index in
            function.arguments[index].type.tokens.contains { $0.string == "@autoclosure" }
        }
        let closureArgumentIndices = function.arguments.indices.filter { index in
            !autoclosureArgumentIndices.contains(index) &&
                function.arguments[index].type.tokens.contains { $0.string == "->" }
        }
        guard !closureArgumentIndices.isEmpty || !autoclosureArgumentIndices.isEmpty else { return }
        functionDeclarations.append(.init(
            name: name,
            declaringType: declaration.parentType?.fullyQualifiedName,
            argumentLabels: function.arguments.map(\.externalLabel),
            closureArgumentIndices: closureArgumentIndices,
            autoclosureArgumentIndices: autoclosureArgumentIndices
        ))
    }
    formatter.clearDerivedCaches()
    return SourceFileIndex(
        contentHash: computeHash(source),
        moduleIdentifier: moduleIdentifier,
        typeDeclarations: typeDeclarations,
        functionDeclarations: functionDeclarations,
        typeMembers: typeMembers
    )
}

struct ProjectRoot: Hashable {
    enum Kind {
        case swiftPackage
        case xcodeProject
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
        directory.deleteLastPathComponent()
    }
    return ProjectRoot(url: fallback, kind: .directory)
}

/// Best-effort discovery of Swift source files beneath a project root.
func discoverSourceFiles(in root: ProjectRoot) -> [URL] {
    let manager = FileManager.default
    let skippedDirectories: Set = [
        ".build", ".git", ".swiftpm", "DerivedData",
    ]
    guard let enumerator = manager.enumerator(
        at: root.url,
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
func moduleIdentifiers(for fileURLs: [URL], in root: ProjectRoot) -> [String: String] {
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
            return (filePath, "\(rootPath):\(components[0]):\(components[1])")
        })
    case .xcodeProject:
        let projectURLs = (try? FileManager.default.contentsOfDirectory(
            at: root.url,
            includingPropertiesForKeys: nil
        ))?.filter { $0.pathExtension == "xcodeproj" } ?? []
        var targetsByFile = [String: Set<String>]()
        for projectURL in projectURLs {
            let projectFileURL = projectURL.appendingPathComponent("project.pbxproj")
            guard let contents = try? String(contentsOf: projectFileURL),
                  let project = XcodeProject(contents: contents, sourceRoot: root.url)
            else { continue }
            let projectIdentifier = projectURL.standardizedFileURL.path
            for (filePath, targetIDs) in project.targetIDsByFile {
                targetsByFile[filePath, default: []].formUnion(targetIDs.map {
                    "\(projectIdentifier):\($0)"
                })
            }
        }
        return Dictionary(uniqueKeysWithValues: targetsByFile.compactMap { path, targetIDs in
            guard targetIDs.count == 1, let targetID = targetIDs.first else { return nil }
            return (path, targetID)
        })
    case .directory:
        return Dictionary(uniqueKeysWithValues: fileURLs.compactMap { fileURL in
            let path = fileURL.standardizedFileURL.path
            return path.hasPrefix(rootPath + "/") ? (path, rootPath) : nil
        })
    }
}

private struct XcodeProject {
    var targetIDsByFile: [String: Set<String>]

    init?(contents: String, sourceRoot: URL) {
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
        for (targetID, value) in objects {
            guard case let .dictionary(target) = value,
                  string("isa", in: target) == "PBXNativeTarget"
            else { continue }
            for phaseID in strings("buildPhases", in: target) {
                guard let phase = dictionary(for: phaseID),
                      string("isa", in: phase) == "PBXSourcesBuildPhase"
                else { continue }
                for buildFileID in strings("files", in: phase) {
                    guard let fileReference = fileReferenceByBuildFile[buildFileID],
                          let path = filePathsByReference[fileReference],
                          path.hasSuffix(".swift")
                    else { continue }
                    result[path, default: []].insert(targetID)
                }
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
