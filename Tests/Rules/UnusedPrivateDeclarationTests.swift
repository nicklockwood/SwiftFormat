//
//  UnusedPrivateDeclarationTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class UnusedPrivateDeclarationTests: XCTestCase {
    func testRemoveUnusedPrivate() {
        let input = """
        struct Foo {
            private var foo = "foo"
            var bar = "bar"
        }
        """
        let output = """
        struct Foo {
            var bar = "bar"
        }
        """
        testFormatting(for: input, output, rule: .unusedPrivateDeclaration)
    }

    func testRemoveUnusedFilePrivate() {
        let input = """
        struct Foo {
            fileprivate var foo = "foo"
            var bar = "bar"
        }
        """
        let output = """
        struct Foo {
            var bar = "bar"
        }
        """
        testFormatting(for: input, output, rule: .unusedPrivateDeclaration)
    }

    func testDoNotRemoveUsedFilePrivate() {
        let input = """
        struct Foo {
            fileprivate var foo = "foo"
            var bar = "bar"
        }

        struct Hello {
            let localFoo = Foo().foo
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclaration)
    }

    func testRemoveMultipleUnusedFilePrivate() {
        let input = """
        struct Foo {
            fileprivate var foo = "foo"
            fileprivate var baz = "baz"
            var bar = "bar"
        }
        """
        let output = """
        struct Foo {
            var bar = "bar"
        }
        """
        testFormatting(for: input, output, rule: .unusedPrivateDeclaration)
    }

    func testRemoveMixedUsedAndUnusedFilePrivate() {
        let input = """
        struct Foo {
            fileprivate var foo = "foo"
            var bar = "bar"
            fileprivate var baz = "baz"
        }

        struct Hello {
            let localFoo = Foo().foo
        }
        """
        let output = """
        struct Foo {
            fileprivate var foo = "foo"
            var bar = "bar"
        }

        struct Hello {
            let localFoo = Foo().foo
        }
        """
        testFormatting(for: input, output, rule: .unusedPrivateDeclaration)
    }

    func testDoNotRemoveFilePrivateUsedInSameStruct() {
        let input = """
        struct Foo {
            fileprivate var foo = "foo"
            var bar = "bar"

            func useFoo() {
                print(foo)
            }
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclaration)
    }

    func testRemoveUnusedFilePrivateInNestedStruct() {
        let input = """
        struct Foo {
            var bar = "bar"

            struct Inner {
                fileprivate var foo = "foo"
            }
        }
        """
        let output = """
        struct Foo {
            var bar = "bar"

            struct Inner {
            }
        }
        """
        testFormatting(for: input, output, rule: .unusedPrivateDeclaration, exclude: [.emptyBraces])
    }

    func testDoNotRemoveFilePrivateUsedInNestedStruct() {
        let input = """
        struct Foo {
            var bar = "bar"

            struct Inner {
                fileprivate var foo = "foo"
                func useFoo() {
                    print(foo)
                }
            }
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclaration)
    }

    func testRemoveUnusedFileprivateFunction() {
        let input = """
        struct Foo {
            var bar = "bar"

            fileprivate func sayHi() {
                print("hi")
            }
        }
        """
        let output = """
        struct Foo {
            var bar = "bar"
        }
        """
        testFormatting(for: input, [output], rules: [.unusedPrivateDeclaration, .blankLinesAtEndOfScope])
    }

    func testDoNotRemoveUnusedFileprivateOperatorDefinition() {
        let input = """
        private class Foo: Equatable {
            fileprivate static func == (_: Foo, _: Foo) -> Bool {
                return true
            }
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclaration)
    }

    func testRemovePrivateDeclarationButDoNotRemoveUnusedPrivateType() {
        let input = """
        private struct Foo {
            private func bar() {
                print("test")
            }
        }
        """
        let output = """
        private struct Foo {
        }
        """

        testFormatting(for: input, output, rule: .unusedPrivateDeclaration, exclude: [.emptyBraces])
    }

    func testRemovePrivateDeclarationButDoNotRemovePrivateExtension() {
        let input = """
        private extension Foo {
            private func doSomething() {}
            func anotherFunction() {}
        }
        """
        let output = """
        private extension Foo {
            func anotherFunction() {}
        }
        """

        testFormatting(for: input, output, rule: .unusedPrivateDeclaration)
    }

    func testRemovesPrivateTypealias() {
        let input = """
        enum Foo {
            struct Bar {}
            private typealias Baz = Bar
        }
        """
        let output = """
        enum Foo {
            struct Bar {}
        }
        """
        testFormatting(for: input, output, rule: .unusedPrivateDeclaration)
    }

    func testDoesntRemoveFileprivateInit() {
        let input = """
        struct Foo {
            fileprivate init() {}
            static let foo = Foo()
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclaration, exclude: [.propertyType])
    }

    func testCanDisableUnusedPrivateDeclarationRule() {
        let input = """
        private enum Foo {
            // swiftformat:disable:next unusedPrivateDeclaration
            fileprivate static func bar() {}
        }
        """

        testFormatting(for: input, rule: .unusedPrivateDeclaration)
    }

    func testDoesNotRemovePropertyWrapperPrefixesIfUsed() {
        let input = """
        struct ContentView: View {
            public init() {
                _showButton = .init(initialValue: false)
            }

            @State private var showButton: Bool
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclaration)
    }

    func testDoesNotRemoveUnderscoredDeclarationIfUsed() {
        let input = """
        struct Foo {
            private var _showButton: Bool = true
            print(_showButton)
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclaration)
    }

    func testDoesNotRemoveBacktickDeclarationIfUsed() {
        let input = """
        struct Foo {
            fileprivate static var `default`: Bool = true
            func printDefault() {
                print(Foo.default)
            }
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclaration)
    }

    func testDoesNotRemoveBacktickUsage() {
        let input = """
        struct Foo {
            fileprivate static var foo = true
            func printDefault() {
                print(Foo.`foo`)
            }
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclaration, exclude: [.redundantBackticks])
    }

    func testDoNotRemovePreservedPrivateDeclarations() {
        let input = """
        enum Foo {
            private static let registryAssociation = false
        }
        """
        let options = FormatOptions(preservedPrivateDeclarations: ["registryAssociation", "hello"])
        testFormatting(for: input, rule: .unusedPrivateDeclaration, options: options)
    }

    func testDoNotRemoveOverridePrivateMethodDeclarations() {
        let input = """
        class Poodle: Dog {
            override private func makeNoise() {
                print("Yip!")
            }
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclaration)
    }

    func testDoNotRemoveOverridePrivatePropertyDeclarations() {
        let input = """
        class Poodle: Dog {
            override private var age: Int {
                7
            }
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclaration)
    }

    func testDoNotRemoveObjcPrivatePropertyDeclaration() {
        let input = """
        struct Foo {
            @objc
            private var bar = "bar"
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclaration)
    }

    func testDoNotRemoveObjcPrivateFunctionDeclaration() {
        let input = """
        struct Foo {
            @objc
            private func doSomething() {}
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclaration)
    }

    func testDoNotRemoveIBActionPrivateFunctionDeclaration() {
        let input = """
        class FooViewController: UIViewController {
            @IBAction private func buttonPressed(_: UIButton) {
                print("Button pressed!")
            }
        }
        """
        testFormatting(for: input, rule: .unusedPrivateDeclaration)
    }

    func testRemoveUnusedRecursivePrivateDeclaration() {
        let input = """
        struct Planet {
            private typealias Dependencies = UniverseBuilderProviding // unused
            private var mass: Double // unused
            private func distance(to: Planet) { } // unused
            private func gravitationalForce(between other: Planet) -> Double {
                (G * mass * other.mass) / distance(to: other).squared()
            } // unused

            var ageInBillionYears: Double {
                ageInMillionYears / 1000
            }
        }
        """
        let output = """
        struct Planet {
            var ageInBillionYears: Double {
                ageInMillionYears / 1000
            }
        }
        """
        testFormatting(for: input, output, rule: .unusedPrivateDeclaration)
    }
}
