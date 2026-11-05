//
//  ProjectSymbolLookupIntegrationTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 11/05/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation
import XCTest
@testable import SwiftFormat

final class ProjectSymbolLookupIntegrationTests: XCTestCase {
    func check(_ input: String, expectedOutput: String? = nil, sources: [String: (String, String)], label: String) throws {
        let url = URL(fileURLWithPath: "/Project/Input.swift")
        var files = [url.path: makeSourceFileIndex(from: input, moduleIdentifiers: ["App"], moduleNames: ["App": "App"])]
        for (path, value) in sources {
            files[path] = makeSourceFileIndex(from: value.1, moduleIdentifiers: [value.0], moduleNames: [value.0: value.0])
        }
        let project = ProjectIndex(files: files)
        let result = try applyRules([.exhaustiveSwitchStatements], to: tokenize(input), with: .default, trackChanges: false, range: nil, context: FormattingContext(currentFileURL: url, projectIndex: project))
        let output = sourceCode(for: result.tokens)
        XCTAssertEqual(output, expectedOutput ?? input, label)
    }

    func testInheritedImportedNestedType() throws {
        try check("""
        import Domain
        enum State { case unrelated }
        class Child: Base {
            func render(_ state: State) {
                switch state {
                default: print(state)
                }
            }
        }
        """, expectedOutput: """
        import Domain
        enum State { case unrelated }
        class Child: Base {
            func render(_ state: State) {
                switch state {
                case .idle, .loaded: print(state)
                }
            }
        }
        """, sources: ["/Project/Base.swift": ("Domain", """
        open class Base {
            public enum State { case idle, loaded }
        }
        """)], label: "imported nested")
    }

    func testGenericParameterCannotResolveThroughBox() throws {
        try check("""
        enum T { case unrelated }
        struct Box<Value> { let value: Value }
        func render<T>(_ model: Box<T>) {
            switch model.value {
            default: print(model.value)
            }
        }
        """, sources: [:], label: "generic argument")
    }

    func testQualifiedPatternMustMatchSubjectModule() throws {
        try check("""
        import Models
        import Domain
        enum State { case idle }
        func ~= (_ pattern: State, _ value: Domain.State) -> Bool { false }
        func render(_ model: Model) {
            switch model.state {
            case State.idle: print("pattern")
            default: print("fallback")
            }
        }
        """, expectedOutput: """
        import Models
        import Domain
        enum State { case idle }
        func ~= (_ pattern: State, _ value: Domain.State) -> Bool { false }
        func render(_ model: Model) {
            switch model.state {
            case State.idle: print("pattern")
            case .idle, .loaded: print("fallback")
            }
        }
        """, sources: [
            "/Project/Model.swift": ("Models", """
            import Domain
            public struct Model { public let state: State }
            """),
            "/Project/State.swift": ("Domain", """
            public enum State { case idle, loaded }
            """),
        ], label: "pattern provenance")
    }

    func testGenericArgumentRetainsUseSiteModule() throws {
        try check("""
        import Models
        enum State { case local }
        func render(_ model: Box<State>) {
            switch model.value {
            default: print(model.value)
            }
        }
        """, expectedOutput: """
        import Models
        enum State { case local }
        func render(_ model: Box<State>) {
            switch model.value {
            case .local: print(model.value)
            }
        }
        """, sources: [
            "/Project/Box.swift": ("Models", """
            import Domain
            public struct Box<Value> { public let value: Value }
            """),
            "/Project/State.swift": ("Domain", """
            public enum State { case imported }
            """),
        ], label: "generic argument provenance")
    }

    func testInheritedAlias() throws {
        try check("""
        enum State { case unrelated }
        enum Actual { case idle, loaded }
        class Base { typealias State = Actual }
        class Child: Base {
            func render(_ state: State) {
                switch state {
                default: print(state)
                }
            }
        }
        """, expectedOutput: """
        enum State { case unrelated }
        enum Actual { case idle, loaded }
        class Base { typealias State = Actual }
        class Child: Base {
            func render(_ state: State) {
                switch state {
                case .idle, .loaded: print(state)
                }
            }
        }
        """, sources: [:], label: "inherited alias")
    }
}
