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

    init(load: @escaping () -> Value) {
        self.load = load
    }

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

/// Source summaries and query tables are partitioned by path, so an edit rebuilds only a fraction
/// of the index. Each instance serves one formatting run with fixed input sources. Immutable generations are published together through an atomic manifest update.
final class ProjectIndexSnapshotCache {
    struct Manifest: Codable {
        var version = 2
        var partitions: [String: ProjectIndexSnapshot]
    }

    private struct Update {
        var index: ProjectIndex
        var sources: [String: SourceFileIndex]
        var reuse: URL?
    }

    private let lock = NSRecursiveLock()
    private let directory: URL?
    private var previous: Manifest?
    private var legacySnapshot: ProjectIndexSnapshot?
    private var didLoad = false
    private var manifest = Manifest(partitions: [:])
    private var pending = [String: Update]()
    private var dirty = false

    init(cacheURL: URL?, roots: Set<ProjectRoot>) {
        let context = roots.map { "\($0.kind):\($0.url.standardizedFileURL.path)" }.sorted().joined(separator: "\n")
        directory = cacheURL.map { projectIndexTablesURL(for: $0).appendingPathComponent(computeHash(context)) }
    }

    private func loadManifest() {
        guard !didLoad else { return }
        didLoad = true
        guard let directory,
              let data = try? Data(contentsOf: directory.appendingPathComponent("manifest.json")) else { return }
        if let stored = try? JSONDecoder().decode(Manifest.self, from: data), stored.version == 2 {
            previous = stored
        } else {
            legacySnapshot = try? JSONDecoder().decode(ProjectIndexSnapshot.self, from: data)
        }
    }

    func index(
        sources: [String: String],
        hashes: [String: String],
        configuration: [String: String],
        features: Set<ProjectContextFeature>,
        localReferences: Set<String>,
        modules: () -> [String: Set<String>],
        legacy: @escaping (String) -> SourceFileIndex?
    ) -> ProjectIndex {
        lock.lock()
        defer { lock.unlock() }
        loadManifest()
        let grouped = Dictionary(grouping: sources.keys) { path in
            String(computeHash(path).utf8.reduce(0) { ($0 * 31 + Int($1)) % 32 })
        }
        let compatible = previous?.partitions.values.allSatisfy {
            $0.version == 1 && $0.sourceIndexVersion == SourceFileIndex.cacheVersion && $0.formatterVersion == swiftFormatVersion && $0.configurationHashes == configuration && UUID(uuidString: $0.generation) != nil
        } == true
        let oldFiles = compatible ? previous!.partitions.values.reduce(into: [String: ProjectIndex.File]()) { $0.merge($1.files) { _, new in new } } : [:]
        let needsModules = sources.keys.contains { oldFiles[$0] == nil }
        let assignments = needsModules ? modules() : oldFiles.mapValues { Set($0.moduleIdentifiers) }
        var partitions = [String: ProjectIndex]()
        for (key, paths) in grouped {
            let old = compatible ? previous?.partitions[key] : nil
            let oldURL = old.flatMap { snapshot in directory.map { $0.appendingPathComponent(snapshot.generation) } }
            let requested = features.union(old?.features ?? []).union([.declarations])
            let partitionHashes = Dictionary(uniqueKeysWithValues: paths.map { ($0, hashes[$0]!) })
            func matches(_ snapshot: ProjectIndexSnapshot) -> Bool {
                requested.isSubset(of: snapshot.features) && snapshot.configurationHashes == configuration &&
                    snapshot.files.mapValues(\.contentHash) == partitionHashes &&
                    paths.allSatisfy { path in
                        snapshot.files[path]?.moduleIdentifiers == (assignments[path] ?? []).sorted() &&
                            (!localReferences.contains(path) || snapshot.files[path]?.includesFunctionReferences == true)
                    }
            }
            // The fallback captures the exact input snapshot, even if formatting subsequently writes files.
            let rebuild: () -> ProjectIndex = {
                self.lock.lock()
                defer { self.lock.unlock() }
                if let update = self.pending[key],
                   let snapshot = self.manifest.partitions[key],
                   matches(snapshot)
                {
                    return update.index
                }
                let cached = self.pending[key]?.sources ?? oldURL.flatMap { try? Data(contentsOf: $0.appendingPathComponent("sources.json")) }
                    .flatMap { try? JSONDecoder().decode([String: SourceFileIndex].self, from: $0) } ?? [:]
                var summaries = [String: SourceFileIndex]()
                var uncachedPaths = [String]()
                for path in paths {
                    let modules = assignments[path] ?? []
                    let functions = requested.contains(.functionReferences) || localReferences.contains(path)
                    let symbols = requested.contains(.symbolReferences)
                    let candidate = cached[path] ?? (self.previous == nil ? legacy(path) : nil)
                    if let candidate, candidate.contentHash == hashes[path], candidate.moduleIdentifiers == modules.sorted(),
                       !functions || candidate.includesFunctionReferences, !symbols || candidate.includesSymbolReferences
                    {
                        summaries[path] = candidate
                    } else {
                        uncachedPaths.append(path)
                    }
                }
                // Preserve parallel parsing for cold caches and feature upgrades. A normal edit
                // reparses just one source and avoids dispatching work for the cached summaries.
                let summaryLock = NSLock()
                func parse(_ path: String) {
                    let summary = makeSourceFileIndex(
                        from: sources[path]!,
                        moduleIdentifiers: assignments[path] ?? [],
                        includeFunctionReferences: requested.contains(.functionReferences) || localReferences.contains(path),
                        includeSymbolReferences: requested.contains(.symbolReferences)
                    )
                    summaryLock.lock()
                    summaries[path] = summary
                    summaryLock.unlock()
                }
                if uncachedPaths.count == 1 {
                    parse(uncachedPaths[0])
                } else {
                    DispatchQueue.concurrentPerform(iterations: uncachedPaths.count) { parse(uncachedPaths[$0]) }
                }
                let index = ProjectIndex(files: summaries)
                var available = requested
                if index.files.values.allSatisfy(\.includesFunctionReferences) {
                    available.insert(.functionReferences)
                }
                if index.files.values.allSatisfy(\.includesSymbolReferences) {
                    available.insert(.symbolReferences)
                }
                self.manifest.partitions[key] = ProjectIndexSnapshot(generation: UUID().uuidString, features: available, configurationHashes: configuration, files: index.files, fingerprints: index.fingerprints)
                self.pending[key] = Update(index: index, sources: summaries, reuse: nil)
                self.dirty = true
                return index
            }
            if let update = pending[key], let snapshot = manifest.partitions[key], matches(snapshot) {
                partitions[key] = update.index
            } else if let old, let oldURL, matches(old) {
                manifest.partitions[key] = old
                let provider = ProjectIndexProvider { _ in rebuild() }
                partitions[key] = ProjectIndex(snapshot: old, directory: oldURL, rebuild: { provider.index(requiring: [.declarations])! })
            } else {
                let index = rebuild()
                partitions[key] = index
                if let old, let oldURL, old.fingerprints == index.fingerprints,
                   Set(old.files.keys) == Set(index.files.keys), old.features == manifest.partitions[key]?.features,
                   (try? FileManager.default.contentsOfDirectory(atPath: oldURL.path).count) == ProjectIndex.tableNames.count + 1
                {
                    pending[key]?.reuse = oldURL
                }
            }
        }
        if Set(previous?.partitions.keys.map { $0 } ?? []) != Set(grouped.keys) {
            dirty = true
        }
        manifest.partitions = manifest.partitions.filter { grouped[$0.key] != nil }
        return ProjectIndex(partitions: partitions)
    }

    @discardableResult
    func save() throws -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard let directory, dirty else { return false }
        let manager = FileManager.default
        var created = [URL]()
        var published = false
        defer {
            if !published {
                for url in created {
                    try? manager.removeItem(at: url)
                }
            }
        }
        for (key, update) in pending {
            guard let snapshot = manifest.partitions[key] else { continue }
            let destination = directory.appendingPathComponent(snapshot.generation)
            created.append(destination)
            try manager.createDirectory(at: destination, withIntermediateDirectories: true)
            if let reuse = update.reuse {
                for name in ProjectIndex.tableNames {
                    let source = reuse.appendingPathComponent(name + ".json")
                    let target = destination.appendingPathComponent(name + ".json")
                    do { try manager.linkItem(at: source, to: target) }
                    catch { try manager.copyItem(at: source, to: target) }
                }
            } else {
                try update.index.writeTables(to: destination)
            }
            try JSONEncoder().encode(update.sources).write(to: destination.appendingPathComponent("sources.json"), options: .atomic)
        }
        try manager.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(manifest).write(to: directory.appendingPathComponent("manifest.json"), options: .atomic)
        published = true
        let retained = Set(manifest.partitions.values.map(\.generation))
        for old in (previous?.partitions.values.map { $0 } ?? []) + (legacySnapshot.map { [$0] } ?? []) where UUID(uuidString: old.generation) != nil && !retained.contains(old.generation) {
            try? manager.removeItem(at: directory.appendingPathComponent(old.generation))
        }
        previous = manifest
        pending.removeAll()
        legacySnapshot = nil
        dirty = false
        return true
    }
}

func projectIndexTablesURL(for cacheURL: URL) -> URL {
    cacheURL.appendingPathExtension("index-tables")
}
