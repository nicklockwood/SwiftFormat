//
//  ProjectIndexSnapshot.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 10/11/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

/// A query table is decoded once, on first use. Missing or corrupt tables rebuild from the
/// same validated sources as the snapshot, rather than silently answering incomplete queries.
final class ProjectIndexTable<Value: Codable> {
    private let lock = NSLock()
    private var storedValue: Value?
    private var load: (() -> Value)?

    init(value: Value) {
        storedValue = value
        load = nil
    }

    init(url: URL, rebuild: @escaping () -> Value) {
        load = {
            (try? Data(contentsOf: url)).flatMap { try? JSONDecoder().decode(Value.self, from: $0) } ?? rebuild()
        }
    }

    var value: Value {
        lock.lock()
        defer { lock.unlock() }
        if let storedValue {
            return storedValue
        }
        let value = load!()
        storedValue = value
        load = nil
        return value
    }

    func write(to url: URL) throws {
        try JSONEncoder().encode(value).write(to: url, options: .atomic)
    }
}

struct ProjectIndexSnapshot: Codable {
    var version = 1
    var sourceIndexVersion = SourceFileIndex.cacheVersion
    var formatterVersion = swiftFormatVersion
    var generation: String
    var features: Set<ProjectContextFeature>
    var configurationHashes: [String: String]
    var files: [String: ProjectIndex.File]
    var fingerprints: ProjectIndex.Fingerprints
}

/// The manifest is small enough to validate without decoding any query tables or source summaries.
/// Each generation is immutable; the manifest is published only after every table has been written.
final class ProjectIndexSnapshotCache {
    private let lock = NSLock()
    private let directory: URL?
    private var snapshot: ProjectIndexSnapshot?
    private var didLoadSnapshot = false
    private var restoredIndex: ProjectIndex?
    private var pending: (ProjectIndex, Set<ProjectContextFeature>, [String: String])?

    init(cacheURL: URL?, roots: Set<ProjectRoot>) {
        let context = roots.map { "\($0.kind):\($0.url.standardizedFileURL.path)" }.sorted().joined(separator: "\n")
        directory = cacheURL.map { projectIndexTablesURL(for: $0).appendingPathComponent(computeHash(context)) }
    }

    func index(
        sourceHashes: [String: String],
        configurationHashes: [String: String],
        features: Set<ProjectContextFeature>,
        localFunctionReferencePaths: Set<String>,
        rebuild: @escaping (Set<ProjectContextFeature>) -> ProjectIndex
    ) -> ProjectIndex? {
        lock.lock()
        defer { lock.unlock() }
        guard let directory else { return nil }
        if !didLoadSnapshot {
            snapshot = (try? Data(contentsOf: directory.appendingPathComponent("manifest.json")))
                .flatMap { try? JSONDecoder().decode(ProjectIndexSnapshot.self, from: $0) }
            didLoadSnapshot = true
        }
        guard let snapshot,
              snapshot.version == 1,
              snapshot.sourceIndexVersion == SourceFileIndex.cacheVersion,
              snapshot.formatterVersion == swiftFormatVersion,
              UUID(uuidString: snapshot.generation) != nil,
              features.isSubset(of: snapshot.features),
              snapshot.configurationHashes == configurationHashes,
              snapshot.files.mapValues(\.contentHash) == sourceHashes,
              localFunctionReferencePaths.allSatisfy({ snapshot.files[$0]?.includesFunctionReferences == true })
        else { return nil }
        if let restoredIndex {
            return restoredIndex
        }
        let fallback = ProjectIndexProvider { rebuild($0) }
        let index = ProjectIndex(
            snapshot: snapshot,
            directory: directory.appendingPathComponent(snapshot.generation),
            rebuild: { fallback.index(requiring: snapshot.features)! }
        )
        restoredIndex = index
        return index
    }

    func record(_ index: ProjectIndex, features: Set<ProjectContextFeature>, configurationHashes: [String: String]) {
        guard directory != nil else { return }
        lock.lock()
        defer { lock.unlock() }
        var features = features.union([.declarations])
        if index.files.values.allSatisfy(\.includesFunctionReferences) {
            features.insert(.functionReferences)
        }
        if index.files.values.allSatisfy(\.includesSymbolReferences) {
            features.insert(.symbolReferences)
        }
        pending = (index, features, configurationHashes)
    }

    func save() throws {
        lock.lock()
        let update = pending
        lock.unlock()
        guard let directory, let (index, features, configurationHashes) = update else { return }
        let manager = FileManager.default
        let manifestURL = directory.appendingPathComponent("manifest.json")
        let previous = (try? Data(contentsOf: manifestURL))
            .flatMap { try? JSONDecoder().decode(ProjectIndexSnapshot.self, from: $0) }
        let generation = UUID().uuidString
        let generationURL = directory.appendingPathComponent(generation)
        try manager.createDirectory(at: generationURL, withIntermediateDirectories: true)
        var published = false
        defer {
            if !published {
                try? manager.removeItem(at: generationURL)
            }
        }
        try index.writeTables(to: generationURL)
        let manifest = ProjectIndexSnapshot(
            generation: generation, features: features, configurationHashes: configurationHashes,
            files: index.files, fingerprints: index.fingerprints
        )
        try JSONEncoder().encode(manifest).write(to: manifestURL, options: .atomic)
        published = true
        // Readers of the previous generation can recover through their validated-source fallback.
        if let previous, UUID(uuidString: previous.generation) != nil {
            try? manager.removeItem(at: directory.appendingPathComponent(previous.generation))
        }
    }
}

func projectIndexTablesURL(for cacheURL: URL) -> URL {
    cacheURL.appendingPathExtension("index-tables")
}
