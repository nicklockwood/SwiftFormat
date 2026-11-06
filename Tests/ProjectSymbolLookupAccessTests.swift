//
//  ProjectSymbolLookupAccessTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 11/05/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//
import Foundation
import XCTest
@testable import SwiftFormat

final class ProjectSymbolLookupAccessTests: XCTestCase {
    private func check(_ input: String, _ output: String? = nil, sources: [String: (String, String)] = [:]) throws {
        let url = URL(fileURLWithPath: "/Project/Input.swift")
        var files = [url.path: makeSourceFileIndex(from: input, moduleIdentifiers: ["App"], moduleNames: ["App": "App"])]
        for (path, value) in sources {
            files[path] = makeSourceFileIndex(from: value.1, moduleIdentifiers: [value.0], moduleNames: [value.0: value.0])
        }
        let result = try applyRules([.exhaustiveSwitchStatements], to: tokenize(input), with: .default, trackChanges: false, range: nil, context: FormattingContext(currentFileURL: url, projectIndex: ProjectIndex(files: files)))
        XCTAssertEqual(sourceCode(for: result.tokens), output ?? input)
    }

    func testAliasWithMultipleDeclaringFilesDoesNotResolveInTheCallersNamespace() throws {
        let input = """
        import Models
        enum State { case unrelated }
        func render(_ state: Phase) {
            switch state {
            default: print(state)
            }
        }
        """
        let url = URL(fileURLWithPath: "/Project/Input.swift")
        let project = ProjectIndex(files: [
            url.path: makeSourceFileIndex(from: input, moduleIdentifiers: ["App"], moduleNames: ["App": "App"]),
            "/Project/First.swift": makeSourceFileIndex(from: "public typealias Phase = State", moduleIdentifiers: ["First"], moduleNames: ["First": "Models"]),
            "/Project/Second.swift": makeSourceFileIndex(from: "public typealias Phase = State", moduleIdentifiers: ["Second"], moduleNames: ["Second": "Models"]),
        ])
        let result = try applyRules([.exhaustiveSwitchStatements], to: tokenize(input), with: .default, trackChanges: false, range: nil, context: FormattingContext(currentFileURL: url, projectIndex: project))
        XCTAssertEqual(sourceCode(for: result.tokens), input)
    }

    func testPrivatePropertyDoesNotHideAnAccessibleProtocolDefault() throws {
        try check("""
        enum State { case hidden }
        enum Other { case visible }
        protocol P {}
        extension P { var state: Other { .visible } }
        struct Source: P { private var state: State { .hidden } }
        func render(_ source: Source) {
            switch source.state {
            default: print("fallback")
            }
        }
        """, """
        enum State { case hidden }
        enum Other { case visible }
        protocol P {}
        extension P { var state: Other { .visible } }
        struct Source: P { private var state: State { .hidden } }
        func render(_ source: Source) {
            switch source.state {
            case .visible: print("fallback")
            }
        }
        """)
    }

    func testPrivateMethodDoesNotHideAnAccessibleProtocolDefault() throws {
        try check("""
        enum State { case hidden }
        enum Other { case visible }
        protocol P {}
        extension P { func read() -> Other { .visible } }
        struct Source: P { private func read() -> State { .hidden } }
        func render(_ source: Source) {
            switch source.read() {
            default: print("fallback")
            }
        }
        """, """
        enum State { case hidden }
        enum Other { case visible }
        protocol P {}
        extension P { func read() -> Other { .visible } }
        struct Source: P { private func read() -> State { .hidden } }
        func render(_ source: Source) {
            switch source.read() {
            case .visible: print("fallback")
            }
        }
        """)
    }

    func testPrivateExtensionMethodIsNotVisibleFromAnotherFile() throws {
        try check("""
        func render(_ source: Source) {
            switch source.read() {
            default: print("fallback")
            }
        }
        """, """
        func render(_ source: Source) {
            switch source.read() {
            case .visible: print("fallback")
            }
        }
        """, sources: ["/Project/Source.swift": ("App", """
        enum State { case hidden }
        enum Other { case visible }
        protocol P {}
        extension P { func read() -> Other { .visible } }
        struct Source: P {}
        private extension Source { func read() -> State { .hidden } }
        """)])
    }

    func testPrivateAliasInAnotherFileDoesNotShadowImportedEnum() throws {
        try check("""
        import Domain
        func render(_ state: State) {
            switch state {
            default: print(state)
            }
        }
        """, """
        import Domain
        func render(_ state: State) {
            switch state {
            case .visible: print(state)
            }
        }
        """, sources: [
            "/Project/Hidden.swift": ("App", """
            private typealias State = Hidden
            enum Hidden { case hidden }
            """),
            "/Project/Domain.swift": ("Domain", """
            public enum State { case visible }
            """),
        ])
    }

    func testImportedOverloadsInSameFileRemainAmbiguous() throws {
        try check("""
        import Domain
        func render() {
            switch load(1) {
            default: print("fallback")
            }
        }
        """, sources: ["/Project/Domain.swift": ("Domain", """
        public enum State { case loaded }
        public func load(_ value: Int) -> State { .loaded }
        public func load(_ value: String) -> State { .loaded }
        """)])
    }

    func testPrivateInheritedAliasDoesNotShadowGlobalEnum() throws {
        try check("""
        enum State { case visible }
        enum Hidden { case hidden }
        class Base { private typealias State = Hidden }
        class Child: Base {
            func render(_ state: State) {
                switch state {
                default: print(state)
                }
            }
        }
        """, """
        enum State { case visible }
        enum Hidden { case hidden }
        class Base { private typealias State = Hidden }
        class Child: Base {
            func render(_ state: State) {
                switch state {
                case .visible: print(state)
                }
            }
        }
        """)
    }

    func testPrivateInheritedNestedTypeDoesNotShadowGlobalEnum() throws {
        try check("""
        enum State { case visible }
        class Base { private enum State { case hidden } }
        class Child: Base {
            func render(_ state: State) {
                switch state {
                default: print(state)
                }
            }
        }
        """, """
        enum State { case visible }
        class Base { private enum State { case hidden } }
        class Child: Base {
            func render(_ state: State) {
                switch state {
                case .visible: print(state)
                }
            }
        }
        """)
    }

    func testFileprivateInheritedNestedTypeRemainsVisibleInSameFile() throws {
        try check("""
        enum State { case unrelated }
        class Base { fileprivate enum State { case visible } }
        class Child: Base {
            fileprivate func render(_ state: State) {
                switch state {
                default: print(state)
                }
            }
        }
        """, """
        enum State { case unrelated }
        class Base { fileprivate enum State { case visible } }
        class Child: Base {
            fileprivate func render(_ state: State) {
                switch state {
                case .visible: print(state)
                }
            }
        }
        """)
    }
}
