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

    static let schemaVersion = 1

    var schemaVersion = SourceFileIndex.schemaVersion
    var contentHash: String
    var moduleIdentifier: String?
    var typeDeclarations: [TypeDeclaration]
}

/// A read-only view of all source summaries discovered for a formatting run.
struct ProjectIndex {
    private struct TypeKey: Hashable {
        var moduleIdentifier: String
        var name: String
    }

    let files: [String: SourceFileIndex]
    let fingerprint: String
    private let typeVisibilities: [TypeKey: Set<String>]

    init(files: [String: SourceFileIndex]) {
        self.files = files
        var typeVisibilities = [TypeKey: Set<String>]()
        for file in files.values {
            guard let moduleIdentifier = file.moduleIdentifier else { continue }
            for declaration in file.typeDeclarations {
                let key = TypeKey(moduleIdentifier: moduleIdentifier, name: declaration.name)
                typeVisibilities[key, default: []].insert(declaration.visibility)
            }
        }
        self.typeVisibilities = typeVisibilities
        let description = files.keys.sorted().compactMap { path -> String? in
            guard let file = files[path] else { return nil }
            let declarations = file.typeDeclarations
                .map { "\($0.name):\($0.visibility)" }
                .sorted()
                .joined(separator: ",")
            return "\(file.moduleIdentifier ?? ""):\(declarations)"
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
}

/// Extracts the subset of declarations required by the initial project-aware rules.
func makeSourceFileIndex(
    from source: String,
    moduleIdentifier: String?
) -> SourceFileIndex {
    let formatter = Formatter(tokenize(source))
    var typeDeclarations = [SourceFileIndex.TypeDeclaration]()
    formatter.parseDeclarations().forEachRecursiveDeclaration { declaration in
        guard let typeDeclaration = declaration.asTypeDeclaration,
              typeDeclaration.keyword != "extension",
              typeDeclaration.keyword != "protocol",
              let name = declaration.fullyQualifiedName
        else { return }

        let insidePublicExtension = declaration.parentDeclarations.contains(where: {
            $0.keyword == "extension" && $0.visibility() == .public
        })
        guard !insidePublicExtension else { return }

        typeDeclarations.append(.init(
            name: name,
            visibility: (declaration.visibility() ?? .internal).rawValue
        ))
    }
    formatter.clearDerivedCaches()
    return SourceFileIndex(
        contentHash: computeHash(source),
        moduleIdentifier: moduleIdentifier,
        typeDeclarations: typeDeclarations
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

/// Provides a conservative module identity from conventional project layout.
func moduleIdentifier(for fileURL: URL, in root: ProjectRoot) -> String? {
    let rootPath = root.url.standardizedFileURL.path
    let filePath = fileURL.standardizedFileURL.path
    guard filePath.hasPrefix(rootPath + "/") else { return nil }

    switch root.kind {
    case .swiftPackage:
        let relativePath = String(filePath.dropFirst(rootPath.count + 1))
        let components = relativePath.split(separator: "/").map(String.init)
        guard components.count >= 3, ["Sources", "Tests"].contains(components[0]) else {
            return nil
        }
        return "\(rootPath):\(components[0]):\(components[1])"
    case .xcodeProject:
        // Target membership cannot be inferred safely without parsing the project.
        return nil
    case .directory:
        return rootPath
    }
}
