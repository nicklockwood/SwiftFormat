//
//  RedundantStaticSelfTests.swift
//  SwiftFormatTests
//
//  Created by Šimon Javora on 4/29/23.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class RedundantStaticSelfTests: XCTestCase {
    func testRedundantStaticSelfInStaticVar() {
        let input = """
        enum E { static var x: Int { Self.y } }
        """
        let output = """
        enum E { static var x: Int { y } }
        """
        testFormatting(for: input, output, rule: .redundantStaticSelf)
    }

    func testRedundantStaticSelfInStaticMethod() {
        let input = """
        enum E { static func foo() { Self.bar() } }
        """
        let output = """
        enum E { static func foo() { bar() } }
        """
        testFormatting(for: input, output, rule: .redundantStaticSelf)
    }

    func testRedundantStaticSelfOnNextLine() {
        let input = """
        enum E {
            static func foo() {
                Self
                    .bar()
            }
        }
        """
        let output = """
        enum E {
            static func foo() {
                bar()
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantStaticSelf)
    }

    func testRedundantStaticSelfWithReturn() {
        let input = """
        enum E { static func foo() { return Self.bar() } }
        """
        let output = """
        enum E { static func foo() { return bar() } }
        """
        testFormatting(for: input, output, rule: .redundantStaticSelf)
    }

    func testRedundantStaticSelfInConditional() {
        let input = """
        enum E {
            static func foo() {
                if Bool.random() {
                    Self.bar()
                }
            }
        }
        """
        let output = """
        enum E {
            static func foo() {
                if Bool.random() {
                    bar()
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantStaticSelf)
    }

    func testRedundantStaticSelfInNestedFunction() {
        let input = """
        enum E {
            static func foo() {
                func bar() {
                    Self.foo()
                }
            }
        }
        """
        let output = """
        enum E {
            static func foo() {
                func bar() {
                    foo()
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantStaticSelf)
    }

    func testRedundantStaticSelfInNestedType() {
        let input = """
        enum Outer {
            enum Inner {
                static func foo() {}
                static func bar() { Self.foo() }
            }
        }
        """
        let output = """
        enum Outer {
            enum Inner {
                static func foo() {}
                static func bar() { foo() }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantStaticSelf)
    }

    func testStaticSelfNotRemovedWhenUsedAsImplicitInitializer() {
        let input = """
        enum E { static func foo() { Self().bar() } }
        """
        testFormatting(for: input, rule: .redundantStaticSelf)
    }

    func testStaticSelfNotRemovedWhenUsedAsExplicitInitializer() {
        let input = """
        enum E { static func foo() { Self.init().bar() } }
        """
        testFormatting(for: input, rule: .redundantStaticSelf, exclude: [.redundantInit])
    }

    func testPreservesStaticSelfInFunctionAfterStaticVar() {
        let input = """
        enum MyFeatureCacheStrategy {
            case networkOnly
            case cacheFirst

            static let defaultCacheAge = TimeInterval.minutes(5)

            func requestStrategy<Outcome>() -> SingleRequestStrategy<Outcome> {
                switch self {
                case .networkOnly:
                    return .networkOnly(writeResultToCache: true)
                case .cacheFirst:
                    return .cacheFirst(maxCacheAge: Self.defaultCacheAge)
                }
            }
        }
        """
        testFormatting(for: input, rule: .redundantStaticSelf, exclude: [.propertyTypes])
    }

    func testPreserveStaticSelfInInstanceFunction() {
        let input = """
        enum Foo {
            static var value = 0

            func f() {
                Self.value = value
            }
        }
        """
        testFormatting(for: input, rule: .redundantStaticSelf)
    }

    func testPreserveStaticSelfForShadowedProperty() {
        let input = """
        enum Foo {
            static var value = 0

            static func f(value: Int) {
                Self.value = value
            }
        }
        """
        testFormatting(for: input, rule: .redundantStaticSelf)
    }

    func testPreserveStaticSelfInGetter() {
        let input = """
        enum Foo {
            static let foo: String = "foo"

            var sharedFoo: String {
                Self.foo
            }
        }
        """
        testFormatting(for: input, rule: .redundantStaticSelf)
    }

    func testRemoveStaticSelfInStaticGetter() {
        let input = """
        public enum Foo {
            static let foo: String = "foo"

            static var getFoo: String {
                Self.foo
            }
        }
        """
        let output = """
        public enum Foo {
            static let foo: String = "foo"

            static var getFoo: String {
                foo
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantStaticSelf)
    }

    func testPreserveStaticSelfInGuardLet() {
        let input = """
        class LocationDeeplink: Deeplink {
            convenience init?(warnRegion: String) {
                guard let value = Self.location(for: warnRegion) else {
                    return nil
                }

                self.init(location: value)
            }
        }
        """
        testFormatting(for: input, rule: .redundantStaticSelf)
    }

    func testPreserveStaticSelfInSingleLineClassInit() {
        let input = """
        class A { static let defaultName = "A"; let name: String; init() { name = Self.defaultName }}
        """
        testFormatting(for: input, rule: .redundantStaticSelf)
    }
}
