//
//  RedundantMemberwiseInitTests.swift
//  SwiftFormatTests
//
//  Created by Miguel Jimenez on 6/17/25.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class RedundantMemberwiseInitTests: XCTestCase {
    func testRemoveRedundantMemberwiseInit() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            init(name: String, age: Int) {
                self.name = name
                self.age = age
            }
        }
        """
        let output = """
        struct Person {
            var name: String
            var age: Int
        }
        """
        testFormatting(for: input, output, rule: .redundantMemberwiseInit)
    }

    func testRemoveRedundantMemberwiseInitWithLetProperties() {
        let input = """
        struct Point {
            let x: Double
            let y: Double

            init(x: Double, y: Double) {
                self.x = x
                self.y = y
            }
        }
        """
        let output = """
        struct Point {
            let x: Double
            let y: Double
        }
        """
        testFormatting(for: input, output, rule: .redundantMemberwiseInit)
    }

    func testRemoveRedundantMemberwiseInitMixedProperties() {
        let input = """
        struct User {
            let id: Int
            var name: String
            var email: String

            init(id: Int, name: String, email: String) {
                self.id = id
                self.name = name
                self.email = email
            }
        }
        """
        let output = """
        struct User {
            let id: Int
            var name: String
            var email: String
        }
        """
        testFormatting(for: input, output, rule: .redundantMemberwiseInit)
    }

    func testDontRemoveCustomInit() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            init(name: String, age: Int) {
                self.name = name.uppercased()
                self.age = age
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemoveInitWithAdditionalLogic() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            init(name: String, age: Int) {
                self.name = name
                self.age = age
                print("Person created")
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemoveInitWithDifferentParameterNames() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            init(fullName: String, yearsOld: Int) {
                self.name = fullName
                self.age = yearsOld
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemoveInitWithDifferentParameterTypes() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            init(name: String, age: Double) {
                self.name = name
                self.age = Int(age)
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemovePrivateInit() {
        let input = """
        struct Person {
            var name: String
            var age: Int

            private init(name: String, age: Int) {
                self.name = name
                self.age = age
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemovePublicInitFromPublicStruct() {
        let input = """
        public struct Person {
            var name: String
            var age: Int

            public init(name: String, age: Int) {
                self.name = name
                self.age = age
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testRemoveInternalInitFromPublicStruct() {
        let input = """
        public struct Person {
            init(name: String, age: Int) {
                self.name = name
                self.age = age
            }

            public let name: String
            public let age: Int
        }
        """
        let output = """
        public struct Person {
            public let name: String
            public let age: Int
        }
        """
        testFormatting(for: input, output, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testRemoveInternalInitFromPublicStructWithInternalProperties() {
        let input = """
        public struct Foo {
            init(a: Int, b: Bool) {
                self.a = a
                self.b = b
            }

            let a: Int
            let b: Bool
        }
        """
        let output = """
        public struct Foo {
            let a: Int
            let b: Bool
        }
        """
        testFormatting(for: input, output, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemovePrivateInitFromInternalStruct() {
        let input = """
        struct Bar {
            private init(a: Int, b: Bool) {
                self.a = a
                self.b = b
            }

            let a: Int
            let b: Bool
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontRemoveInitWithPrivateProperties() {
        let input = """
        struct Person {
            private var name: String
            var age: Int

            init(name: String, age: Int) {
                self.name = name
                self.age = age
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontAffectClass() {
        let input = """
        class Person {
            var name: String
            var age: Int

            init(name: String, age: Int) {
                self.name = name
                self.age = age
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.redundantSelf, .trailingSpace, .indent])
    }

    func testDontAffectEnum() {
        let input = """
        enum Color {
            case red
            case blue

            init() {
                self = .red
            }
        }
        """
        testFormatting(for: input, rule: .redundantMemberwiseInit, exclude: [.trailingSpace])
    }

    func testRemoveRedundantMemberwiseInitWithComplexStruct() {
        let input = """
        struct Foo {

          // MARK: Lifecycle

          init(
            name: String,
            value: Int,
            isEnabled: Bool
          ) {
            self.name = name
            self.value = value
            self.isEnabled = isEnabled
          }

          // MARK: Public

          let name: String
          let value: Int
          let isEnabled: Bool
        }

        struct Bar: Equatable {

          // MARK: Lifecycle

          init(
            id: String,
            count: Int
          ) {
            self.id = id
            self.count = count
          }

          // MARK: Public

          let id: String
          let count: Int
        }

        // MARK: - Baz

        struct Baz: Equatable {

          // MARK: Lifecycle

          init(
            title: String,
            subtitle: String?,
            data: [String]
          ) {
            self.title = title
            self.subtitle = subtitle
            self.data = data
          }

          // MARK: Public

          let title: String
          let subtitle: String?
          let data: [String]
        }

        // MARK: - Component

        struct Component: Equatable {
          init(type: String, config: [String: Any]) {
            self.type = type
            self.config = config
          }

          let type: String
          let config: [String: Any]
        }
        """
        let output = """
        struct Foo {

          // MARK: Public

          let name: String
          let value: Int
          let isEnabled: Bool
        }

        struct Bar: Equatable {

          // MARK: Public

          let id: String
          let count: Int
        }

        // MARK: - Baz

        struct Baz: Equatable {

          // MARK: Public

          let title: String
          let subtitle: String?
          let data: [String]
        }

        // MARK: - Component

        struct Component: Equatable {
          let type: String
          let config: [String: Any]
        }
        """
        testFormatting(for: input, output, rule: .redundantMemberwiseInit, exclude: [.indent, .acronyms, .blankLinesAtStartOfScope])
    }
}