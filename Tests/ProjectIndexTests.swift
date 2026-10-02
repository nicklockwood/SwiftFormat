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
                "\(projectPath):APP_TARGET"
            )
            XCTAssertEqual(
                identifiers[directory.appendingPathComponent("Tests/AppTests.swift").path],
                "\(projectPath):TEST_TARGET"
            )
            XCTAssertNil(identifiers[directory.appendingPathComponent("Shared/Shared.swift").path])
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

        let index = makeSourceFileIndex(from: source, moduleIdentifier: "App")

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

        let index = makeSourceFileIndex(from: source, moduleIdentifier: "App")

        XCTAssertEqual(index.functionDeclarations, [
            .init(name: "expect", argumentLabels: [nil], autoclosureArgumentIndices: [0]),
            .init(name: "require", argumentLabels: ["message", nil], autoclosureArgumentIndices: [1]),
        ])
    }

    func testProjectIndexReturnsAutoclosureFunctionsFromCurrentModuleOnly() {
        let appURL = URL(fileURLWithPath: "/Project/Sources/App/App.swift")
        let libraryURL = URL(fileURLWithPath: "/Project/Sources/Library/Library.swift")
        let appIndex = makeSourceFileIndex(
            from: "func appExpect(_ expression: @autoclosure () -> Bool) {}",
            moduleIdentifier: "App"
        )
        let libraryIndex = makeSourceFileIndex(
            from: "func libraryExpect(_ expression: @autoclosure () -> Bool) {}",
            moduleIdentifier: "Library"
        )
        let projectIndex = ProjectIndex(files: [
            appURL.path: appIndex,
            libraryURL.path: libraryIndex,
        ])

        XCTAssertEqual(projectIndex.autoclosureFunctionNames(visibleFrom: appURL), ["appExpect"])
        XCTAssertEqual(projectIndex.autoclosureFunctionNames(visibleFrom: libraryURL), ["libraryExpect"])
        XCTAssertEqual(
            projectIndex.autoclosureFunctionNames(visibleFrom: URL(fileURLWithPath: "/unknown.swift")),
            []
        )
    }

    func testProjectIndexReturnsTypeMembersFromCurrentModuleOnly() {
        let typeURL = URL(fileURLWithPath: "/Project/Sources/App/Type.swift")
        let extensionURL = URL(fileURLWithPath: "/Project/Sources/App/Extension.swift")
        let libraryURL = URL(fileURLWithPath: "/Project/Sources/Library/Library.swift")
        let projectIndex = ProjectIndex(files: [
            typeURL.path: makeSourceFileIndex(
                from: "struct Foo { var value = 1; static var shared = 2 }",
                moduleIdentifier: "App"
            ),
            extensionURL.path: makeSourceFileIndex(
                from: "extension Foo { func run() {}; static func make() {} }",
                moduleIdentifier: "App"
            ),
            libraryURL.path: makeSourceFileIndex(
                from: "struct Foo { var libraryValue = 1 }",
                moduleIdentifier: "Library"
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
}
