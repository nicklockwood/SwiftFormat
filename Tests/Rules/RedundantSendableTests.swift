//
//  RedundantSendableTests.swift
//  SwiftFormatTests
//
//  Created by Nacho Soto on 2/20/2026.
//

import XCTest
@testable import SwiftFormat

final class RedundantSendableTests: XCTestCase {
    private func testProjectFormatting(
        for input: String,
        _ output: String? = nil,
        otherFile: String,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        _ = FormatRules.all
        let inputURL = URL(fileURLWithPath: "/Project/Sources/App/Input.swift")
        let otherURL = URL(fileURLWithPath: "/Project/Sources/App/Other.swift")
        let projectIndex = ProjectIndex(files: [
            inputURL.path: makeSourceFileIndex(from: input, moduleIdentifiers: ["App"]),
            otherURL.path: makeSourceFileIndex(from: otherFile, moduleIdentifiers: ["App"]),
        ])
        let result = try applyRules(
            [.redundantSendable],
            to: tokenize(input),
            with: .default,
            trackChanges: false,
            range: nil,
            context: FormattingContext(currentFileURL: inputURL, projectIndex: projectIndex)
        )
        XCTAssertEqual(sourceCode(for: result.tokens), output ?? input, file: file, line: line)
    }

    func testRemovesSendableFromNestedAndTopLevelNonPublicValueTypes() {
        let input = """
        struct Outer {
            enum NestedImplicitAccess: Sendable {}
            private struct NestedPrivate: Sendable {}
            @available(*, deprecated)
            enum NestedAttributed: Sendable {}
        }

        struct TopLevelImplicitAccess: Sendable {}
        fileprivate enum TopLevelFileprivate: Sendable {}
        """

        let output = """
        struct Outer {
            enum NestedImplicitAccess {}
            private struct NestedPrivate {}
            @available(*, deprecated)
            enum NestedAttributed {}
        }

        struct TopLevelImplicitAccess {}
        fileprivate enum TopLevelFileprivate {}
        """

        testFormatting(
            for: input,
            [output],
            rules: [.redundantSendable],
            exclude: [.enumNamespaces, .redundantFileprivate]
        )
    }

    func testDoesNotRemoveSendableFromValidCases() {
        let input = """
        public struct PublicValue: Sendable {}
        public enum PublicEnum: Sendable {}
        private final class PrivateReference: Sendable {}
        private struct PrivateUnchecked: @unchecked Sendable {}
        struct NoExplicitSendable {}
        struct Generic<T>: Equatable where T: Sendable {}
        """

        testFormatting(for: input, rules: [.redundantSendable], exclude: [.simplifyGenericConstraints])
    }

    func testDoesNotRemoveSendableFromIndirectEnum() {
        let input = """
        indirect enum TestIndirect: Sendable {
            case leaf
            case node(TestIndirect)
        }
        """

        testFormatting(for: input, rules: [.redundantSendable])
    }

    func testDoesNotRemoveSendableFromEnumWithIndirectCase() {
        // Removing `Sendable` here produces a warning in Swift 6.3
        // https://github.com/nicklockwood/SwiftFormat/issues/2563
        let input = """
        enum ValueType: Sendable, Hashable {
            case any
            indirect case list(ValueType)
        }
        """

        testFormatting(for: input, rules: [.redundantSendable])
    }

    func testDoesNotRemoveSendableFromUsableFromInlineTypes() {
        // `@usableFromInline` types aren't implicitly `Sendable`
        let input = """
        @usableFromInline
        enum Strategy: Sendable {
            case watermark(Int)
        }

        @usableFromInline
        struct Watermark: Sendable {
            let low: Int
        }
        """

        testFormatting(for: input, rules: [.redundantSendable])
    }

    func testIgnoresCommentsAndStrings() {
        let input = """
        func demo() {
            let example = \"\"\"
            enum FakeNested: Sendable {}
            private struct AlsoFake: Sendable {}
            \"\"\"
            _ = example
            // struct CommentFake: Sendable {}
            /*
             fileprivate enum BlockCommentFake: Sendable {}
            */
        }
        """

        testFormatting(for: input, rules: [.redundantSendable], exclude: [.indent])
    }

    func testRemovesQualifiedSendableFromMixedConformanceLists() {
        let input = """
        struct First: Sendable, Codable {}
        struct Middle: Codable, Swift.Sendable, Hashable {}
        enum Last: CaseIterable, Sendable {
            case value
        }
        """

        let output = """
        struct First: Codable {}
        struct Middle: Codable, Hashable {}
        enum Last: CaseIterable {
            case value
        }
        """

        testFormatting(for: input, [output], rules: [.redundantSendable])
    }

    func testDoesNotRemoveSendableFromTypeInsidePublicExtension() {
        let input = """
        public struct OuterStruct {}

        public extension OuterStruct {
            struct InnerStruct: Sendable {}
            enum InnerEnum: Sendable {}
        }
        """

        testFormatting(for: input, rules: [.redundantSendable])
    }

    func testRemovesSendableFromTypeInsideInternalExtension() {
        let input = """
        struct OuterStruct {}

        extension OuterStruct {
            struct InnerStruct: Sendable {}
        }
        """

        let output = """
        struct OuterStruct {}

        extension OuterStruct {
            struct InnerStruct {}
        }
        """

        testFormatting(for: input, [output], rules: [.redundantSendable])
    }

    func testRemovesSendableFromPackageValueTypes() {
        let input = """
        package struct PackageStruct: Sendable {
            package let value: Int
        }

        package enum PackageEnum: Sendable {
            case value(Int)
        }
        """

        let output = """
        package struct PackageStruct {
            package let value: Int
        }

        package enum PackageEnum {
            case value(Int)
        }
        """

        testFormatting(for: input, [output], rules: [.redundantSendable])
    }

    func testRemovesSendableWithSpaceBeforeColon() {
        let input = """
        enum Bar : Sendable {
            case a
            case b(Int)
        }

        struct Foo : Sendable {
            let value: Int
        }
        """

        let output = """
        enum Bar {
            case a
            case b(Int)
        }

        struct Foo {
            let value: Int
        }
        """

        testFormatting(for: input, [output], rules: [.redundantSendable])
    }

    func testDoesNotRemoveSendableRequiredByConformanceInOtherFile() throws {
        let input = """
        struct MyModel: Equatable, Sendable {
            let id: Int
        }
        """
        let otherFile = """
        protocol Identified: Sendable {}
        protocol MyProtocol: Identified {}

        extension MyModel: MyProtocol {}
        """
        try testProjectFormatting(for: input, otherFile: otherFile)
    }

    func testDoesNotRemoveSendableRequiredByErrorConformanceInOtherFile() throws {
        let input = """
        struct MyModel: Equatable, Sendable {
            let id: Int
        }
        """
        let otherFile = """
        extension MyModel: Error {}
        """
        try testProjectFormatting(for: input, otherFile: otherFile)
    }

    func testDoesNotRemoveSendableWhenSameFileConformanceHasSameName() throws {
        let input = """
        enum Inner {
            protocol P {}
        }

        struct MyModel: Inner.P, Sendable {
            let id: Int
        }
        """
        let otherFile = """
        protocol P: Sendable {}

        extension MyModel: P {}
        """
        try testProjectFormatting(for: input, otherFile: otherFile)
    }

    func testRemovesSendableWhenConformanceInOtherFileDoesNotRequireIt() throws {
        let input = """
        struct MyModel: Equatable, Sendable {
            let id: Int
        }
        """
        let output = """
        struct MyModel: Equatable {
            let id: Int
        }
        """
        let otherFile = """
        protocol MyProtocol {}

        extension MyModel: MyProtocol {}
        """
        try testProjectFormatting(for: input, output, otherFile: otherFile)
    }

    func testRemovesSendableWhenSendableProtocolConformanceIsInSameFile() throws {
        let input = """
        struct MyModel: Equatable, Sendable {
            let id: Int
        }

        extension MyModel: MyProtocol {}
        """
        let output = """
        struct MyModel: Equatable {
            let id: Int
        }

        extension MyModel: MyProtocol {}
        """
        let otherFile = """
        protocol MyProtocol: Sendable {}
        """
        try testProjectFormatting(for: input, output, otherFile: otherFile)
    }
}
