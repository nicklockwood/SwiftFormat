//
//  ProjectIndexTests.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 01/10/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class ProjectIndexTests: XCTestCase {
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
}
