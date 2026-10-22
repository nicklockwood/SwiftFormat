//
//  ProjectIndexTests.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 01/10/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

private func withProjectIndexTmpDirectory(
    _ files: [String: String],
    fn: (URL) throws -> Void
) throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    for (path, contents) in files {
        let fileURL = directory.appendingPathComponent(path)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try contents.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    try fn(directory)
}

final class ProjectIndexTests: XCTestCase {
    func testProjectIndexProviderBuildsOnDemandAndReusesFeatures() {
        var requestedFeatures = [Set<ProjectContextFeature>]()
        let provider = ProjectIndexProvider { features in
            requestedFeatures.append(features)
            return ProjectIndex(files: [:])
        }

        XCTAssertTrue(requestedFeatures.isEmpty)
        XCTAssertNotNil(provider.index(requiring: [.declarations]))
        XCTAssertEqual(requestedFeatures, [[.declarations]])
        XCTAssertNotNil(provider.index(requiring: [.declarations]))
        XCTAssertEqual(requestedFeatures, [[.declarations]])
        XCTAssertNotNil(provider.index(requiring: [.functionReferences]))
        XCTAssertEqual(requestedFeatures, [
            [.declarations],
            [.declarations, .functionReferences],
        ])
    }

    func testParameterTypesAffectDeclarationFingerprint() throws {
        let first = """
        func consume(_ value: First) {}
        """
        let second = """
        func consume(_ value: Second) {}
        """
        let file = makeSourceFileIndex(from: first, moduleIdentifiers: ["App"])
        XCTAssertEqual(file.functionDeclarations.first?.argumentTypes, ["First"])
        let encoded = try JSONEncoder().encode(file)
        XCTAssertEqual(try JSONDecoder().decode(SourceFileIndex.self, from: encoded), file)
        XCTAssertNotEqual(
            ProjectIndex(files: ["/Project/Input.swift": file]).fingerprint(for: [.declarations]),
            ProjectIndex(files: ["/Project/Input.swift": makeSourceFileIndex(
                from: second, moduleIdentifiers: ["App"]
            )]).fingerprint(for: [.declarations])
        )
    }

    func testDeclarationFingerprintDoesNotDependOnFunctionReferences() {
        let source = "let callback = perform(value:)"
        let declarationsOnly = ProjectIndex(files: [
            "/Project/Input.swift": makeSourceFileIndex(
                from: source,
                moduleIdentifiers: ["App"],
                includeFunctionReferences: false
            ),
        ])
        let complete = ProjectIndex(files: [
            "/Project/Input.swift": makeSourceFileIndex(
                from: source,
                moduleIdentifiers: ["App"],
                includeFunctionReferences: true
            ),
        ])

        XCTAssertEqual(
            declarationsOnly.fingerprint(for: [.declarations]),
            complete.fingerprint(for: [.declarations])
        )
        XCTAssertNotEqual(declarationsOnly.fingerprint, complete.fingerprint)
    }

    func testConcurrentProjectIndexRequestsShareBuild() {
        let lock = NSLock()
        var buildCount = 0
        let buildStarted = DispatchSemaphore(value: 0)
        let finishBuild = DispatchSemaphore(value: 0)
        let provider = ProjectIndexProvider { _ in
            lock.lock()
            buildCount += 1
            lock.unlock()
            buildStarted.signal()
            finishBuild.wait()
            return ProjectIndex(files: [:])
        }
        let group = DispatchGroup()
        for _ in 0 ..< 8 {
            DispatchQueue.global().async(group: group) {
                _ = provider.index(requiring: [.declarations])
            }
        }

        XCTAssertEqual(buildStarted.wait(timeout: .now() + 1), .success)
        finishBuild.signal()
        XCTAssertEqual(group.wait(timeout: .now() + 1), .success)
        XCTAssertEqual(buildCount, 1)
    }

    func testProjectRootStopsAtFilesystemRoot() {
        let root = projectRoot(for: URL(fileURLWithPath: "/", isDirectory: true))

        XCTAssertEqual(root.url.path, "/")
        XCTAssertEqual(root.kind, .directory)
    }

    func testProjectRootStopsBeforeSharedTemporaryDirectory() throws {
        try withProjectIndexTmpDirectory([
            "Package.swift": "// Unrelated project marker",
            "Temporary/Input.swift": "struct Input {}",
        ]) { directory in
            let sourceDirectory = directory.appendingPathComponent("Temporary")
            let root = projectRoot(
                for: sourceDirectory.appendingPathComponent("Input.swift"),
                stoppingAt: [directory]
            )
            XCTAssertEqual(root.url.path, sourceDirectory.path)
            XCTAssertEqual(root.kind, .directory)
        }
    }

    func testProjectRootFindsProjectInsideTemporaryDirectory() throws {
        try withProjectIndexTmpDirectory([
            "Project/Package.swift": "// Package marker",
            "Project/Sources/Input.swift": "struct Input {}",
        ]) { directory in
            let root = projectRoot(
                for: directory.appendingPathComponent("Project/Sources/Input.swift"),
                stoppingAt: [directory]
            )
            XCTAssertEqual(root.url.path, directory.appendingPathComponent("Project").path)
            XCTAssertEqual(root.kind, .swiftPackage)
        }
    }

    func testProjectRootStopsAtResolvedTemporaryDirectory() throws {
        try withProjectIndexTmpDirectory([
            "Temporary/Package.swift": "// Unrelated project marker",
            "Temporary/Files/Input.swift": "struct Input {}",
        ]) { directory in
            let temporaryDirectory = directory.appendingPathComponent("Temporary")
            let alias = directory.appendingPathComponent("Alias")
            try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: temporaryDirectory)
            let sourceDirectory = temporaryDirectory.appendingPathComponent("Files").resolvingSymlinksInPath()
            let root = projectRoot(
                for: sourceDirectory.appendingPathComponent("Input.swift"),
                stoppingAt: [alias]
            )
            XCTAssertEqual(root.url.path, sourceDirectory.path)
            XCTAssertEqual(root.kind, .directory)
        }
    }

    func testProjectRootStopsBeforeCommonUserDirectories() {
        let manager = FileManager.default
        let home = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
        let directories = [home, home.deletingLastPathComponent()] +
            manager.urls(for: .documentDirectory, in: .userDomainMask) +
            manager.urls(for: .downloadsDirectory, in: .userDomainMask) +
            manager.urls(for: .desktopDirectory, in: .userDomainMask)
        for directory in directories {
            let root = projectRoot(for: directory.appendingPathComponent("SwiftFormat-\(UUID()).swift"))
            XCTAssertEqual(root.url.path, directory.path)
            XCTAssertEqual(root.kind, .directory)
        }
    }

    func testProjectRootDoesNotTreatProjectFolderNamesAsBoundaries() throws {
        try withProjectIndexTmpDirectory([
            "Package.swift": "// Package marker",
            "Documents/Input.swift": "struct Input {}",
        ]) { directory in
            let root = projectRoot(for: directory.appendingPathComponent("Documents/Input.swift"))
            XCTAssertEqual(root.url.path, directory.path)
            XCTAssertEqual(root.kind, .swiftPackage)
        }
    }

    func testProjectRootBoundariesIncludeRedirectedEnvironmentDirectories() throws {
        try withProjectIndexTmpDirectory([:]) { directory in
            let names = ["USERPROFILE", "PUBLIC", "ProgramData", "APPDATA", "LOCALAPPDATA",
                         "TEMP", "XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME",
                         "XDG_STATE_HOME", "XDG_RUNTIME_DIR"]
            let environment = Dictionary(uniqueKeysWithValues: names.map {
                ($0, directory.appendingPathComponent($0).path)
            })
            let paths = Set(projectRootSearchBoundaries(environment: environment).map(\.path))
            for path in environment.values {
                XCTAssert(paths.contains(path), "Missing boundary: \(path)")
            }
        }
    }

    func testProjectRootBoundariesIgnoreRelativeEnvironmentDirectories() {
        let boundaries = projectRootSearchBoundaries(environment: ["XDG_DATA_HOME": "relative", "APPDATA": ""])
        XCTAssertFalse(boundaries.contains { $0.lastPathComponent == "relative" })
    }

    #if os(Linux)
        func testProjectRootBoundariesUseXDGDefaults() {
            let home = URL(fileURLWithPath: "/home/test")
            let paths = Set(projectRootSearchBoundaries(homeDirectory: home, environment: [:]).map(\.path))
            for path in ["/home/test/.config", "/home/test/.local/share", "/home/test/.cache",
                         "/home/test/.local/state", "/etc/xdg", "/usr/local/share", "/usr/share"]
            {
                XCTAssert(paths.contains(path))
            }
        }

        func testProjectRootBoundariesHonorXDGSearchPaths() {
            let paths = Set(projectRootSearchBoundaries(environment: [
                "XDG_CONFIG_DIRS": "/custom/config:/other/config",
                "XDG_DATA_DIRS": "/custom/data:relative",
            ]).map(\.path))
            XCTAssert(paths.contains("/custom/config"))
            XCTAssert(paths.contains("/other/config"))
            XCTAssert(paths.contains("/custom/data"))
            XCTAssertFalse(paths.contains { $0.hasSuffix("/relative") })
        }
    #endif

    #if os(Windows)
        func testProjectRootBoundariesIgnoreWindowsPathCase() throws {
            try withProjectIndexTmpDirectory([
                "Package.swift": "// Unrelated project marker",
                "Files/Input.swift": "struct Input {}",
            ]) { directory in
                let root = projectRoot(
                    for: directory.appendingPathComponent("Files/Input.swift"),
                    stoppingAt: [URL(fileURLWithPath: directory.path.uppercased())]
                )
                XCTAssertEqual(root.kind, .directory)
            }
        }
    #endif

    func testProjectRootFallsBackToInputDirectory() throws {
        try withProjectIndexTmpDirectory([
            "Sources/Input.swift": "struct Input {}",
        ]) { directory in
            let sourceDirectory = directory.appendingPathComponent("Sources")
            let sourceFile = sourceDirectory.appendingPathComponent("Input.swift")
            let fileRoot = projectRoot(for: sourceFile)
            let directoryRoot = projectRoot(for: sourceDirectory)

            XCTAssertEqual(fileRoot.url.path, sourceDirectory.path)
            XCTAssertEqual(fileRoot.kind, .directory)
            XCTAssertEqual(directoryRoot.url.path, sourceDirectory.path)
            XCTAssertEqual(directoryRoot.kind, .directory)
        }
    }

    func testProjectRootIsSharedByTargetedFilesAndDirectories() throws {
        try withProjectIndexTmpDirectory([
            "Package.swift": "// Package marker",
            "Sources/App/Input.swift": "struct Input {}",
        ]) { directory in
            let sourceDirectory = directory.appendingPathComponent("Sources/App")
            let sourceFile = sourceDirectory.appendingPathComponent("Input.swift")
            let fileRoot = projectRoot(for: sourceFile)
            let directoryRoot = projectRoot(for: sourceDirectory)

            XCTAssertEqual(fileRoot.url.path, directory.path)
            XCTAssertEqual(fileRoot.kind, .swiftPackage)
            XCTAssertEqual(directoryRoot.url.path, directory.path)
            XCTAssertEqual(directoryRoot.kind, .swiftPackage)
        }
    }

    func testProjectRootUsesGitRepositoryAsFallback() throws {
        try withProjectIndexTmpDirectory([
            ".git/config": "",
            "Sources/App/Input.swift": "struct Input {}",
        ]) { directory in
            let sourceFile = directory.appendingPathComponent("Sources/App/Input.swift")

            let root = projectRoot(for: sourceFile)

            XCTAssertEqual(root.url.path, directory.path)
            XCTAssertEqual(root.kind, .gitRepository)
        }
    }

    func testSourceFileIndexExtractsFunctionValueReferences() {
        let source = """
        let unlabeled = someMethod(_:)
        let labeled = Type.someMethod(value:options:)
        let call = someMethod(1)
        let keyPath = \\Type.someMethod
        let inferred = values.map(otherMethod)
        """

        let index = makeSourceFileIndex(from: source, moduleIdentifiers: ["App"])

        XCTAssertEqual(index.functionReferences, [
            .init(name: "someMethod", argumentLabels: [nil], isUnqualifiedGlobal: true),
            .init(
                name: "someMethod",
                argumentLabels: ["value", "options"]
            ),
            .init(name: "someMethod", argumentLabels: nil),
            .init(name: "otherMethod", argumentLabels: nil, isUnqualifiedGlobal: true),
        ])
    }

    func testSourceFileIndexExtractsClassInheritance() {
        let source = """
        class Child<Element>: Module.Parent<Element>, SomeProtocol {}
        """

        let index = makeSourceFileIndex(from: source, moduleIdentifiers: ["App"])

        XCTAssertEqual(index.classInheritances, [
            .init(
                className: "Child",
                inheritedTypes: ["Module.Parent", "Parent", "SomeProtocol"]
            ),
        ])
    }

    func testDeclarationFingerprintIncludesClassInheritance() {
        let base = ProjectIndex(files: [
            "/Project/Input.swift": makeSourceFileIndex(
                from: "class Child: Parent {}",
                moduleIdentifiers: ["App"]
            ),
        ])
        let changed = ProjectIndex(files: [
            "/Project/Input.swift": makeSourceFileIndex(
                from: "class Child: OtherParent {}",
                moduleIdentifiers: ["App"]
            ),
        ])

        XCTAssertNotEqual(
            base.fingerprint(for: [.declarations]),
            changed.fingerprint(for: [.declarations])
        )
    }

    func testSourceFileIndexExtractsTypeConformances() {
        let source = """
        struct Item: Identifiable, Module.Named {
            struct Detail: Hashable {}
        }
        enum Mode: String {}
        class Child: Parent {}
        actor Worker {}
        extension Item: Equatable {}
        """

        let index = makeSourceFileIndex(from: source, moduleIdentifiers: ["App"])

        XCTAssertEqual(index.typeConformances, [
            .init(typeName: "Item", conformances: ["Identifiable", "Module.Named", "Named"]),
            .init(typeName: "Item.Detail", conformances: ["Hashable"]),
            .init(typeName: "Mode", conformances: ["String"]),
            .init(typeName: "Child", conformances: ["Parent"]),
            .init(typeName: "Worker", conformances: []),
            .init(typeName: "Item", conformances: ["Equatable"]),
        ])
    }

    func testSourceFileIndexExtractsProtocolInheritance() {
        let source = """
        protocol Refined: Base, Module.Other {}
        public protocol Plain {}
        fileprivate protocol Hidden: Base {}
        """

        let index = makeSourceFileIndex(from: source, moduleIdentifiers: ["App"])

        XCTAssertEqual(index.protocolDeclarations, [
            .init(name: "Refined", inheritedProtocols: ["Base", "Module.Other", "Other"]),
            .init(name: "Plain", inheritedProtocols: []),
        ])
        XCTAssertEqual(index.typeConformances, [])
    }

    func testSourceFileIndexRoundTripsConformancesThroughCodable() throws {
        let index = makeSourceFileIndex(
            from: """
            struct Item: Named {}
            protocol Named: Base {}
            """,
            moduleIdentifiers: ["App"]
        )

        XCTAssertEqual(SourceFileIndex.cacheVersion, 6)
        XCTAssertEqual(try JSONDecoder().decode(
            SourceFileIndex.self,
            from: JSONEncoder().encode(index)
        ), index)
    }

    func testDeclarationFingerprintIncludesTypeConformancesAndProtocolInheritance() {
        func fingerprint(_ source: String) -> String {
            ProjectIndex(files: [
                "/Project/Input.swift": makeSourceFileIndex(from: source, moduleIdentifiers: ["App"]),
            ]).fingerprint(for: [.declarations])
        }

        XCTAssertNotEqual(
            fingerprint("extension Item: Named {}"),
            fingerprint("extension Item: Other {}")
        )
        XCTAssertNotEqual(
            fingerprint("protocol Named: Base {}"),
            fingerprint("protocol Named: Other {}")
        )
    }

    private func conformanceRequirementStatus(
        forType typeName: String = "Loader",
        isStatic: Bool = false,
        argumentLabels: [String?] = ["path"],
        in sources: [String]
    ) -> ProjectIndex.ConformanceRequirementStatus {
        let fileURLs = sources.indices.map { URL(fileURLWithPath: "/Project/Sources/App/File\($0).swift") }
        let projectIndex = ProjectIndex(files: Dictionary(uniqueKeysWithValues: zip(fileURLs, sources).map {
            ($0.path, makeSourceFileIndex(from: $1, moduleIdentifiers: ["App"]))
        }))
        return projectIndex.conformanceRequirementStatus(
            forType: typeName,
            functionName: "load",
            isStatic: isStatic,
            argumentLabels: argumentLabels,
            visibleFrom: fileURLs[0]
        )
    }

    func testConformanceRequirementStatusFindsRequirementsInProjectDeclarations() {
        let protocolSource = "protocol Base { func load(path: String) }"

        XCTAssertEqual(conformanceRequirementStatus(in: [
            "struct Loader: Refined {}", protocolSource, "protocol Refined: Base {}",
        ]), .required)
        XCTAssertEqual(conformanceRequirementStatus(in: [
            "struct Loader {}", protocolSource, "extension Loader: Base {}",
        ]), .required)
        XCTAssertEqual(conformanceRequirementStatus(in: [
            "class Loader: Child {}", "class Child: Parent {}", "class Parent: Base {}", protocolSource,
        ]), .required)
        XCTAssertEqual(conformanceRequirementStatus(in: [
            "class Loader: Parent {}", "class Parent { func load(path: String) {} }",
        ]), .required)
        XCTAssertEqual(conformanceRequirementStatus(in: [
            "struct Loader: Equatable, Base {}", protocolSource,
        ]), .required)
    }

    func testConformanceRequirementStatusIsNotRequiredForOtherSignatures() {
        let protocolSource = "protocol Base { func load(path: String) }"

        XCTAssertEqual(conformanceRequirementStatus(in: ["struct Loader {}"]), .notRequired)
        XCTAssertEqual(conformanceRequirementStatus(in: [
            "struct Loader: Base {}", "protocol Base { func reset() }",
        ]), .notRequired)
        XCTAssertEqual(conformanceRequirementStatus(argumentLabels: ["file"], in: [
            "struct Loader: Base {}", protocolSource,
        ]), .notRequired)
        XCTAssertEqual(conformanceRequirementStatus(isStatic: true, in: [
            "struct Loader: Base {}", protocolSource,
        ]), .notRequired)
        XCTAssertEqual(conformanceRequirementStatus(in: [
            "struct Loader: First {}", "protocol First: Second {}", "protocol Second: First {}",
        ]), .notRequired)
    }

    func testConformanceRequirementStatusIsUnknownForExternalOrAmbiguousDeclarations() {
        XCTAssertEqual(conformanceRequirementStatus(in: ["struct Loader: Equatable {}"]), .unknown)
        XCTAssertEqual(conformanceRequirementStatus(in: [
            "struct Loader: Base {}", "protocol Base: Sendable {}",
        ]), .unknown)
        XCTAssertEqual(conformanceRequirementStatus(in: [
            "struct Loader: Base {}", "protocol Base {}", "protocol Base {}",
        ]), .unknown)
        XCTAssertEqual(conformanceRequirementStatus(in: [
            "struct Loader: Base {}", "private protocol Base { func reset() }",
        ]), .unknown)
    }

    func testSourceFileIndexCanOmitFunctionReferences() throws {
        let source = """
        struct Example {
            var value = 0
            func perform(_ body: @autoclosure () -> Int) {}
        }
        let callback = Example.perform
        """
        let complete = makeSourceFileIndex(from: source, moduleIdentifiers: ["App"])
        let partial = makeSourceFileIndex(
            from: source,
            moduleIdentifiers: ["App"],
            includeFunctionReferences: false
        )
        XCTAssertTrue(complete.includesFunctionReferences)
        XCTAssertFalse(complete.functionReferences.isEmpty)
        var expected = complete
        expected.functionReferences = []
        expected.includesFunctionReferences = false
        XCTAssertEqual(partial, expected)
        XCTAssertEqual(try JSONDecoder().decode(
            SourceFileIndex.self,
            from: JSONEncoder().encode(partial)
        ), partial)

        let empty = makeSourceFileIndex(from: "", moduleIdentifiers: [])
        XCTAssertTrue(empty.includesFunctionReferences)
        XCTAssertTrue(empty.functionReferences.isEmpty)
    }

    func testSourceFileIndexHandlesNestedTypesInsideLocalTypes() {
        for nestedDeclaration in ["struct Nested {}", "struct Nested { let nested = 1 }"] {
            let source = """
            func example() {
                struct Local {
                    \(nestedDeclaration)
                    let value = 1
                    func get() -> Int { value }
                }
            }
            """
            let index = makeSourceFileIndex(from: source, moduleIdentifiers: ["App"])
            XCTAssertTrue(index.functionReferences.contains { $0.name == "value" })
        }
    }

    func testSourceFileIndexHandlesConditionalCompilationInsideLocalTypes() {
        for body in ["", "let debugValue = 1"] {
            let source = """
            func example() {
                struct Local {
                    #if DEBUG
                    \(body)
                    #endif
                    let value = 1
                    func get() -> Int { value }
                }
            }
            """
            let index = makeSourceFileIndex(from: source, moduleIdentifiers: ["App"])
            XCTAssertTrue(index.functionReferences.contains { $0.name == "value" })
        }
    }

    func testXcodeProjectModuleIdentifiersUseTargetMembership() throws {
        try withProjectIndexTmpDirectory([
            "App/App.swift": "struct App {}",
            "Shared/Shared.swift": "struct Shared {}",
            "Tests/AppTests.swift": "struct AppTests {}",
            "Example.xcodeproj/project.pbxproj": """
            // !$*UTF8*$!
            {
                objects = {
                    APP_FILE = { isa = PBXFileReference; path = App.swift; sourceTree = "<group>"; };
                    SHARED_FILE = { isa = PBXFileReference; path = Shared.swift; sourceTree = "<group>"; };
                    TEST_FILE = { isa = PBXFileReference; path = AppTests.swift; sourceTree = "<group>"; };
                    APP_BUILD = { isa = PBXBuildFile; fileRef = APP_FILE; };
                    SHARED_APP_BUILD = { isa = PBXBuildFile; fileRef = SHARED_FILE; };
                    SHARED_TEST_BUILD = { isa = PBXBuildFile; fileRef = SHARED_FILE; };
                    TEST_BUILD = { isa = PBXBuildFile; fileRef = TEST_FILE; };
                    ROOT_GROUP = {
                        isa = PBXGroup;
                        children = (APP_GROUP, SHARED_GROUP, TEST_GROUP,);
                        sourceTree = "<group>";
                    };
                    APP_GROUP = { isa = PBXGroup; children = (APP_FILE,); path = App; sourceTree = "<group>"; };
                    SHARED_GROUP = { isa = PBXGroup; children = (SHARED_FILE,); path = Shared; sourceTree = "<group>"; };
                    TEST_GROUP = { isa = PBXGroup; children = (TEST_FILE,); path = Tests; sourceTree = "<group>"; };
                    APP_SOURCES = { isa = PBXSourcesBuildPhase; files = (APP_BUILD, SHARED_APP_BUILD,); };
                    TEST_SOURCES = { isa = PBXSourcesBuildPhase; files = (SHARED_TEST_BUILD, TEST_BUILD,); };
                    APP_TARGET = { isa = PBXNativeTarget; buildPhases = (APP_SOURCES,); name = App; };
                    TEST_TARGET = { isa = PBXNativeTarget; buildPhases = (TEST_SOURCES,); name = AppTests; };
                };
            }
            """,
        ]) { directory in
            let root = ProjectRoot(url: directory, kind: .xcodeProject)
            let fileURLs = discoverSourceFiles(in: root)
            let identifiers = moduleIdentifiers(for: fileURLs, in: root)

            let projectPath = directory.appendingPathComponent("Example.xcodeproj").path
            XCTAssertEqual(
                identifiers[directory.appendingPathComponent("App/App.swift").path],
                ["\(projectPath):APP_TARGET"]
            )
            XCTAssertEqual(
                identifiers[directory.appendingPathComponent("Tests/AppTests.swift").path],
                ["\(projectPath):TEST_TARGET"]
            )
            XCTAssertEqual(
                identifiers[directory.appendingPathComponent("Shared/Shared.swift").path],
                ["\(projectPath):APP_TARGET", "\(projectPath):TEST_TARGET"]
            )
        }
    }

    func testXcodeProjectModuleIdentifiersUseSynchronizedGroupsAndExceptions() throws {
        try withProjectIndexTmpDirectory([
            "Sync/Included.swift": "struct Included {}",
            "Sync/Excluded.swift": "struct Excluded {}",
            "Sync/Shared.swift": "struct Shared {}",
            "Sync/PhaseOnly.swift": "struct PhaseOnly {}",
            "Example.xcodeproj/project.pbxproj": """
            // !$*UTF8*$!
            {
                objects = {
                    APP_EXCEPTIONS = {
                        isa = PBXFileSystemSynchronizedBuildFileExceptionSet;
                        membershipExceptions = (Excluded.swift,);
                        target = APP_TARGET;
                    };
                    TEST_EXCEPTIONS = {
                        isa = PBXFileSystemSynchronizedBuildFileExceptionSet;
                        membershipExceptions = (Shared.swift,);
                        target = TEST_TARGET;
                    };
                    TEST_PHASE_EXCEPTIONS = {
                        isa = PBXFileSystemSynchronizedGroupBuildPhaseMembershipExceptionSet;
                        buildPhase = TEST_SOURCES;
                        membershipExceptions = (PhaseOnly.swift,);
                    };
                    SYNC_GROUP = {
                        isa = PBXFileSystemSynchronizedRootGroup;
                        exceptions = (APP_EXCEPTIONS, TEST_EXCEPTIONS, TEST_PHASE_EXCEPTIONS,);
                        path = Sync;
                        sourceTree = "<group>";
                    };
                    ROOT_GROUP = {
                        isa = PBXGroup;
                        children = (SYNC_GROUP,);
                        sourceTree = "<group>";
                    };
                    APP_SOURCES = { isa = PBXSourcesBuildPhase; files = (); };
                    TEST_SOURCES = { isa = PBXSourcesBuildPhase; files = (); };
                    APP_TARGET = {
                        isa = PBXNativeTarget;
                        buildPhases = (APP_SOURCES,);
                        fileSystemSynchronizedGroups = (SYNC_GROUP,);
                        name = App;
                    };
                    TEST_TARGET = {
                        isa = PBXNativeTarget;
                        buildPhases = (TEST_SOURCES,);
                        name = AppTests;
                    };
                };
            }
            """,
        ]) { directory in
            let root = ProjectRoot(url: directory, kind: .xcodeProject)
            let identifiers = moduleIdentifiers(for: discoverSourceFiles(in: root), in: root)
            let projectPath = directory.appendingPathComponent("Example.xcodeproj").path
            let app = "\(projectPath):APP_TARGET"
            let tests = "\(projectPath):TEST_TARGET"

            XCTAssertEqual(identifiers[directory.appendingPathComponent("Sync/Included.swift").path], [app])
            XCTAssertEqual(identifiers[directory.appendingPathComponent("Sync/Excluded.swift").path], [])
            XCTAssertEqual(identifiers[directory.appendingPathComponent("Sync/Shared.swift").path], [app, tests])
            XCTAssertEqual(identifiers[directory.appendingPathComponent("Sync/PhaseOnly.swift").path], [app, tests])
        }
    }

    func testXcodeWorkspaceDiscoversProjectsInNestedGroups() throws {
        try withProjectIndexTmpDirectory([
            "Example.xcworkspace/contents.xcworkspacedata": """
            <?xml version="1.0" encoding="UTF-8"?>
            <Workspace version="1.0">
                <Group location="group:Projects" name="Projects">
                    <FileRef location="group:App/App.xcodeproj"></FileRef>
                </Group>
            </Workspace>
            """,
            "Projects/App/Sources/App.swift": "struct App {}",
            "Projects/App/App.xcodeproj/project.pbxproj": """
            // !$*UTF8*$!
            {
                objects = {
                    APP_FILE = { isa = PBXFileReference; path = App.swift; sourceTree = "<group>"; };
                    APP_BUILD = { isa = PBXBuildFile; fileRef = APP_FILE; };
                    ROOT_GROUP = {
                        isa = PBXGroup;
                        children = (SOURCES_GROUP,);
                        sourceTree = "<group>";
                    };
                    SOURCES_GROUP = {
                        isa = PBXGroup;
                        children = (APP_FILE,);
                        path = Sources;
                        sourceTree = "<group>";
                    };
                    APP_SOURCES = { isa = PBXSourcesBuildPhase; files = (APP_BUILD,); };
                    APP_TARGET = { isa = PBXNativeTarget; buildPhases = (APP_SOURCES,); name = App; };
                };
            }
            """,
        ]) { directory in
            let root = ProjectRoot(url: directory, kind: .xcodeProject)
            let sourceURL = directory.appendingPathComponent("Projects/App/Sources/App.swift")
            let fileURLs = discoverSourceFiles(in: root)
            let identifiers = moduleIdentifiers(for: fileURLs, in: root)
            let projectPath = directory.appendingPathComponent("Projects/App/App.xcodeproj").path

            XCTAssertTrue(fileURLs.contains(sourceURL))
            XCTAssertEqual(identifiers[sourceURL.path], ["\(projectPath):APP_TARGET"])
        }
    }

    func testSourceFileIndexExtractsTypeMemberNames() {
        let source = """
        class Foo {
            let value = 1
            var computed: Int { value }
            static let shared = Foo()
            private let secret = 1
            fileprivate func hidden() {}
            func run() {}
            class func make() -> Foo { Foo() }

            struct Nested {
                var nestedValue = 1
            }
        }

        extension Foo {
            var extensionValue: Int { value }
            static func extensionFunction() {}
            #if DEBUG
                func debugOnly() {}
            #endif
        }

        private extension Foo {
            func privateExtensionFunction() {}
        }
        """

        let index = makeSourceFileIndex(from: source, moduleIdentifiers: ["App"])

        XCTAssertEqual(index.typeMembers, [
            .init(
                typeName: "Foo",
                instanceMembers: ["computed", "run", "value"],
                staticMembers: ["make", "shared"]
            ),
            .init(typeName: "Foo.Nested", instanceMembers: ["nestedValue"], staticMembers: []),
            .init(
                typeName: "Foo",
                instanceMembers: ["debugOnly", "extensionValue"],
                staticMembers: ["extensionFunction"]
            ),
        ])
    }

    func testSourceFileIndexExtractsAutoclosureFunctionSignatures() {
        let source = """
        func expect(_ expression: @autoclosure () -> Bool) {}
        func require(message: String, _ expression: @escaping @autoclosure () async -> Bool) {}
        func evaluate(_ expression: () -> Bool) {}
        """

        let index = makeSourceFileIndex(from: source, moduleIdentifiers: ["App"])

        XCTAssertEqual(index.functionDeclarations, [
            .init(name: "expect", argumentLabels: [nil], autoclosureArgumentIndices: [0], argumentTypes: ["@autoclosure () -> Bool"]),
            .init(name: "require", argumentLabels: ["message", nil], autoclosureArgumentIndices: [1],
                  argumentTypes: ["String", "@escaping @autoclosure () async -> Bool"]),
            .init(
                name: "evaluate",
                argumentLabels: [nil],
                closureArgumentIndices: [0],
                autoclosureArgumentIndices: [],
                argumentTypes: ["() -> Bool"]
            ),
        ])
    }

    func testSourceFileIndexExtractsClosureFunctionSignatures() {
        let source = """
        func perform(value: Int, completion: () -> Void) {}
        func optional(completion: (() -> Void)?) {}
        func evaluate(_ expression: @autoclosure () -> Bool) {}
        func identity(value: Int) -> Int { value }
        struct Worker {
            func run(completion: () -> Void) {}
        }
        """

        let index = makeSourceFileIndex(from: source, moduleIdentifiers: ["App"])

        XCTAssertEqual(index.functionDeclarations, [
            .init(
                name: "perform",
                argumentLabels: ["value", "completion"],
                closureArgumentIndices: [1],
                autoclosureArgumentIndices: [],
                argumentTypes: ["Int", "() -> Void"]
            ),
            .init(
                name: "optional",
                argumentLabels: ["completion"],
                closureArgumentIndices: [0],
                autoclosureArgumentIndices: [],
                argumentTypes: ["(() -> Void)?"]
            ),
            .init(name: "evaluate", argumentLabels: [nil], autoclosureArgumentIndices: [0], argumentTypes: ["@autoclosure () -> Bool"]),
            .init(name: "identity", argumentLabels: ["value"], autoclosureArgumentIndices: [], returnType: "Int", argumentTypes: ["Int"]),
            .init(
                name: "run",
                declaringType: "Worker",
                argumentLabels: ["completion"],
                closureArgumentIndices: [0],
                autoclosureArgumentIndices: [],
                argumentTypes: ["() -> Void"]
            ),
        ])
    }

    func testSourceFileIndexExtractsCallableSignatures() {
        let source = """
        public func load(_ path: String, retries: Int = 3) {}
        struct Worker {
            package static func make(configuration: Configuration = .default) -> Worker { Worker() }
            init(value: Int = 0) {}
            subscript(index: Int) -> Int { index }
            private func hidden() {}
            func outer() {
                func local() {}
            }
        }
        private extension Worker {
            func extensionHidden() {}
        }
        """

        let index = makeSourceFileIndex(from: source, moduleIdentifiers: ["App"])

        XCTAssertEqual(index.functionDeclarations, [
            .init(
                name: "load",
                visibility: Visibility.public.rawValue,
                argumentLabels: [nil, "retries"],
                defaultArgumentIndices: [1],
                autoclosureArgumentIndices: [],
                argumentTypes: ["String", "Int"]
            ),
            .init(
                name: "make",
                declaringType: "Worker",
                isStatic: true,
                visibility: Visibility.package.rawValue,
                argumentLabels: ["configuration"],
                defaultArgumentIndices: [0],
                autoclosureArgumentIndices: [],
                returnType: "Worker",
                argumentTypes: ["Configuration"]
            ),
            .init(
                name: "init",
                kind: .initializer,
                declaringType: "Worker",
                argumentLabels: ["value"],
                defaultArgumentIndices: [0],
                autoclosureArgumentIndices: [],
                argumentTypes: ["Int"]
            ),
            .init(
                name: "subscript",
                kind: .subscriptDeclaration,
                declaringType: "Worker",
                argumentLabels: ["index"],
                autoclosureArgumentIndices: [],
                returnType: "Int",
                argumentTypes: ["Int"]
            ),
            .init(
                name: "outer",
                declaringType: "Worker",
                argumentLabels: [],
                autoclosureArgumentIndices: [],
                argumentTypes: []
            ),
        ])
    }

    func testProjectIndexIdentifiesUnambiguousTrailingClosureSignatures() {
        let sourceURL = URL(fileURLWithPath: "/Project/Sources/App/Functions.swift")
        let callURL = URL(fileURLWithPath: "/Project/Sources/App/Call.swift")
        let projectIndex = ProjectIndex(files: [
            sourceURL.path: makeSourceFileIndex(
                from: """
                func perform(value: Int, completion: () -> Void) {}
                func ambiguous(value: Int, completion: () -> Void) {}
                func ambiguous(value: Int, handler: () -> Void) {}
                func evaluate(expression: @autoclosure () -> Bool) {}
                """,
                moduleIdentifiers: ["App"]
            ),
            callURL.path: makeSourceFileIndex(from: "", moduleIdentifiers: ["App"]),
        ])

        XCTAssertTrue(projectIndex.supportsTrailingClosure(
            functionNamed: "perform",
            receiver: .unqualified(declaringType: nil, isStatic: false),
            argumentLabels: ["value", "completion"],
            visibleFrom: callURL
        ))
        XCTAssertFalse(projectIndex.supportsTrailingClosure(
            functionNamed: "ambiguous",
            receiver: .unqualified(declaringType: nil, isStatic: false),
            argumentLabels: ["value", "completion"],
            visibleFrom: callURL
        ))
        XCTAssertFalse(projectIndex.supportsTrailingClosure(
            functionNamed: "evaluate",
            receiver: .unqualified(declaringType: nil, isStatic: false),
            argumentLabels: ["expression"],
            visibleFrom: callURL
        ))
    }

    func testProjectIndexResolvesCallsWithDefaultArguments() throws {
        let declarationsURL = URL(fileURLWithPath: "/Project/Sources/App/Functions.swift")
        let callURL = URL(fileURLWithPath: "/Project/Sources/App/Call.swift")
        let projectIndex = ProjectIndex(files: [
            declarationsURL.path: makeSourceFileIndex(
                from: """
                func perform(value: Int = 0, completion: () -> Void) {}
                struct Worker {
                    func run(value: Int = 0, completion: () -> Void) {}
                    static func make(value: Int = 0, completion: () -> Void) {}
                }
                """,
                moduleIdentifiers: ["App"]
            ),
            callURL.path: makeSourceFileIndex(from: "", moduleIdentifiers: ["App"]),
        ])

        let freeFunction = try XCTUnwrap(projectIndex.resolveFunctionCall(
            named: "perform",
            receiver: .unqualified(declaringType: nil, isStatic: false),
            argumentLabels: ["completion"],
            visibleFrom: callURL
        ))
        XCTAssertEqual(freeFunction.matches.map(\.parameterIndices), [[1]])

        XCTAssertNotNil(projectIndex.resolveFunctionCall(
            named: "run",
            receiver: .instance(type: "Worker"),
            argumentLabels: ["completion"],
            visibleFrom: callURL
        ))
        XCTAssertNotNil(projectIndex.resolveFunctionCall(
            named: "make",
            receiver: .type("Worker"),
            argumentLabels: ["completion"],
            visibleFrom: callURL
        ))
        XCTAssertNil(projectIndex.resolveFunctionCall(
            named: "run",
            receiver: .type("Worker"),
            argumentLabels: ["completion"],
            visibleFrom: callURL
        ))
    }

    func testProjectIndexDoesNotResolveAmbiguousOverloads() {
        let declarationsURL = URL(fileURLWithPath: "/Project/Sources/App/Functions.swift")
        let callURL = URL(fileURLWithPath: "/Project/Sources/App/Call.swift")
        let projectIndex = ProjectIndex(files: [
            declarationsURL.path: makeSourceFileIndex(
                from: """
                func perform(value: Int, completion: () -> Void) {}
                func perform(value: String, completion: () -> Void) {}
                """,
                moduleIdentifiers: ["App"]
            ),
            callURL.path: makeSourceFileIndex(from: "", moduleIdentifiers: ["App"]),
        ])

        XCTAssertNil(projectIndex.resolveFunctionCall(
            named: "perform",
            receiver: .unqualified(declaringType: nil, isStatic: false),
            argumentLabels: ["value", "completion"],
            visibleFrom: callURL
        ))
    }

    func testProjectIndexReturnsTypeMembersFromCurrentModuleOnly() {
        let typeURL = URL(fileURLWithPath: "/Project/Sources/App/Type.swift")
        let extensionURL = URL(fileURLWithPath: "/Project/Sources/App/Extension.swift")
        let libraryURL = URL(fileURLWithPath: "/Project/Sources/Library/Library.swift")
        let projectIndex = ProjectIndex(files: [
            typeURL.path: makeSourceFileIndex(
                from: "struct Foo { var value = 1; static var shared = 2 }",
                moduleIdentifiers: ["App"]
            ),
            extensionURL.path: makeSourceFileIndex(
                from: "extension Foo { func run() {}; static func make() {} }",
                moduleIdentifiers: ["App"]
            ),
            libraryURL.path: makeSourceFileIndex(
                from: "struct Foo { var libraryValue = 1 }",
                moduleIdentifiers: ["Library"]
            ),
        ])

        XCTAssertEqual(
            projectIndex.memberNamesByType(visibleFrom: extensionURL),
            .init(
                instance: ["Foo": ["run", "value"]],
                staticOrClass: ["Foo": ["make", "shared"]]
            )
        )
        XCTAssertEqual(
            projectIndex.memberNamesByType(visibleFrom: libraryURL),
            .init(instance: ["Foo": ["libraryValue"]])
        )
        XCTAssertEqual(
            projectIndex.memberNamesByType(visibleFrom: URL(fileURLWithPath: "/unknown.swift")),
            .empty
        )
    }

    func testProjectIndexReturnsRenameableDeclarationsFromCurrentModuleOnly() throws {
        let callURL = URL(fileURLWithPath: "/Project/Sources/App/Call.swift")
        let appURL = URL(fileURLWithPath: "/Project/Sources/App/App.swift")
        let libraryURL = URL(fileURLWithPath: "/Project/Sources/Library/Library.swift")
        let projectIndex = ProjectIndex(files: [
            callURL.path: makeSourceFileIndex(from: "", moduleIdentifiers: ["App"]),
            appURL.path: makeSourceFileIndex(
                from: "struct AppReciever {}",
                moduleIdentifiers: ["App"]
            ),
            libraryURL.path: makeSourceFileIndex(
                from: "struct LibraryReciever {}",
                moduleIdentifiers: ["Library"]
            ),
        ])

        let names = try XCTUnwrap(projectIndex.declarationNames(upTo: .internal, visibleFrom: callURL))
        XCTAssertTrue(names.eligible.contains("AppReciever"))
        XCTAssertFalse(names.declared.contains("LibraryReciever"))
    }

    func testProjectIndexRequiresFactsInEveryModuleForSharedFiles() {
        let callURL = URL(fileURLWithPath: "/Project/Shared/Call.swift")
        let appURL = URL(fileURLWithPath: "/Project/App/App.swift")
        let sharedURL = URL(fileURLWithPath: "/Project/Shared/Declarations.swift")
        let projectIndex = ProjectIndex(files: [
            callURL.path: makeSourceFileIndex(from: "", moduleIdentifiers: ["App", "Library"]),
            appURL.path: makeSourceFileIndex(
                from: """
                struct AppType { var appValue = 0 }
                func appVerify(_ expression: @autoclosure () -> Bool) {}
                func appPerform(completion: () -> Void) {}
                """,
                moduleIdentifiers: ["App"]
            ),
            sharedURL.path: makeSourceFileIndex(
                from: """
                struct SharedType { var sharedValue = 0 }
                func sharedVerify(_ expression: @autoclosure () -> Bool) {}
                func sharedPerform(completion: () -> Void) {}
                """,
                moduleIdentifiers: ["App", "Library"]
            ),
        ])

        XCTAssertFalse(projectIndex.isInternalType(named: "AppType", from: callURL))
        XCTAssertTrue(projectIndex.isInternalType(named: "SharedType", from: callURL))
        XCTAssertFalse(projectIndex.supportsTrailingClosure(
            functionNamed: "appPerform",
            receiver: .unqualified(declaringType: nil, isStatic: false),
            argumentLabels: ["completion"],
            visibleFrom: callURL
        ))
        XCTAssertTrue(projectIndex.supportsTrailingClosure(
            functionNamed: "sharedPerform",
            receiver: .unqualified(declaringType: nil, isStatic: false),
            argumentLabels: ["completion"],
            visibleFrom: callURL
        ))
        XCTAssertEqual(
            projectIndex.memberNamesByType(visibleFrom: callURL),
            .init(instance: ["SharedType": ["sharedValue"]])
        )
    }

    func testGenericTypeContextAffectsDeclarationFingerprint() {
        let concrete = """
        struct Transform {}
        """
        let generic = """
        struct Transform<String> {}
        """
        let first = ProjectIndex(files: [
            "/Project/Types.swift": makeSourceFileIndex(from: concrete, moduleIdentifiers: ["App"]),
        ])
        let second = ProjectIndex(files: [
            "/Project/Types.swift": makeSourceFileIndex(from: generic, moduleIdentifiers: ["App"]),
        ])
        XCTAssertNotEqual(first.fingerprint(for: [.declarations]), second.fingerprint(for: [.declarations]))
    }
}
