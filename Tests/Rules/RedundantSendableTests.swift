//
//  RedundantSendableTests.swift
//  SwiftFormatTests
//
//  Created by Nacho Soto on 2/20/2026.
//

import XCTest
@testable import SwiftFormat

final class RedundantSendableTests: XCTestCase {
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
}
