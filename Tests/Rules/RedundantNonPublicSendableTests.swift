//
//  RedundantNonPublicSendableTests.swift
//  SwiftFormatTests
//
//  Created by Codex on 2/20/2026.
//

import XCTest
@testable import SwiftFormat

final class RedundantNonPublicSendableTests: XCTestCase {
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
            rules: [.redundantNonPublicSendable],
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

        testFormatting(for: input, rules: [.redundantNonPublicSendable], exclude: [.simplifyGenericConstraints])
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

        testFormatting(for: input, rules: [.redundantNonPublicSendable], exclude: [.indent])
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

        testFormatting(for: input, [output], rules: [.redundantNonPublicSendable])
    }
}
