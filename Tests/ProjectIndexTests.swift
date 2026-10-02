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
    func testSourceFileIndexDecodesFunctionDeclarationFromPreviousSchema() throws {
        let data = Data("""
        {
            "schemaVersion": 3,
            "contentHash": "hash",
            "moduleIdentifier": "App",
            "typeDeclarations": [],
            "functionDeclarations": [{
                "name": "evaluate",
                "argumentLabels": [null],
                "autoclosureArgumentIndices": [0]
            }],
            "typeMembers": []
        }
        """.utf8)

        let index = try JSONDecoder().decode(SourceFileIndex.self, from: data)

        XCTAssertEqual(index.moduleIdentifiers, ["App"])
        XCTAssertEqual(index.typoDeclarations, [])
        XCTAssertEqual(index.functionDeclarations, [
            .init(name: "evaluate", argumentLabels: [nil], autoclosureArgumentIndices: [0]),
        ])
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
            .init(name: "expect", argumentLabels: [nil], autoclosureArgumentIndices: [0]),
            .init(name: "require", argumentLabels: ["message", nil], autoclosureArgumentIndices: [1]),
            .init(
                name: "evaluate",
                argumentLabels: [nil],
                closureArgumentIndices: [0],
                autoclosureArgumentIndices: []
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
                autoclosureArgumentIndices: []
            ),
            .init(
                name: "optional",
                argumentLabels: ["completion"],
                closureArgumentIndices: [0],
                autoclosureArgumentIndices: []
            ),
            .init(name: "evaluate", argumentLabels: [nil], autoclosureArgumentIndices: [0]),
            .init(name: "identity", argumentLabels: ["value"], autoclosureArgumentIndices: []),
            .init(
                name: "run",
                declaringType: "Worker",
                argumentLabels: ["completion"],
                closureArgumentIndices: [0],
                autoclosureArgumentIndices: []
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
                autoclosureArgumentIndices: []
            ),
            .init(
                name: "make",
                declaringType: "Worker",
                isStatic: true,
                visibility: Visibility.package.rawValue,
                argumentLabels: ["configuration"],
                defaultArgumentIndices: [0],
                autoclosureArgumentIndices: []
            ),
            .init(
                name: "init",
                kind: .initializer,
                declaringType: "Worker",
                argumentLabels: ["value"],
                defaultArgumentIndices: [0],
                autoclosureArgumentIndices: []
            ),
            .init(
                name: "subscript",
                kind: .subscriptDeclaration,
                declaringType: "Worker",
                argumentLabels: ["index"],
                autoclosureArgumentIndices: []
            ),
            .init(
                name: "outer",
                declaringType: "Worker",
                argumentLabels: [],
                autoclosureArgumentIndices: []
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

    func testProjectIndexReturnsTypoDeclarationsFromCurrentModuleOnly() throws {
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

        let names = try XCTUnwrap(projectIndex.typoNames(upTo: .internal, visibleFrom: callURL))
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
}
