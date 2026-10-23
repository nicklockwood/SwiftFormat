//
//  AlignAssignmentsTests.swift
//  SwiftFormatTests
//
//  Created by Ethan Pippin on 2026-10-20.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class AlignAssignmentsTests: XCTestCase {
    func testAlignPropertyDeclarations() {
        let input = """
        func buildDeathStar() -> DeathStar {
            let capacity = 25000
            let isIndestructible = false
            let hasOnlyOneWeakPoint = true
            return .init(capacity, isIndestructible, hasOnlyOneWeakPoint)
        }
        """
        let output = """
        func buildDeathStar() -> DeathStar {
            let capacity            = 25000
            let isIndestructible    = false
            let hasOnlyOneWeakPoint = true
            return .init(capacity, isIndestructible, hasOnlyOneWeakPoint)
        }
        """
        testFormatting(for: input, output, rule: .alignAssignments)
    }

    func testAlignAssignmentStatements() {
        let input = """
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        view.layer.cornerRadius = 8
        """
        let output = """
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor                           = .black
        view.layer.cornerRadius                        = 8
        """
        testFormatting(for: input, output, rule: .alignAssignments)
    }

    func testAlignDeclarationsWithAssignmentStatements() {
        let input = """
        init(name: String, age: Int) {
            self.name = name
            self.age = age
            let names: [String] = []
            isRegistered = false
        }
        """
        let output = """
        init(name: String, age: Int) {
            self.name           = name
            self.age            = age
            let names: [String] = []
            isRegistered        = false
        }
        """
        // The propertyTypes rule shortens the declaration, so the group is realigned
        let output2 = """
        init(name: String, age: Int) {
            self.name    = name
            self.age     = age
            let names    = [String]()
            isRegistered = false
        }
        """
        testFormatting(for: input, [output, output2], rules: [.alignAssignments])
    }

    func testAlignDeclarationsWithModifiersAndAttributes() {
        let input = """
        struct ContentView: View {
            @State private var isPresented = false
            @State private var text = ""
            static let maxCount = 10
        }
        """
        let output = """
        struct ContentView: View {
            @State private var isPresented = false
            @State private var text        = ""
            static let maxCount            = 10
        }
        """
        testFormatting(for: input, output, rule: .alignAssignments)
    }

    func testAlignDeclarationsWithAttributesOnPreviousLine() {
        let input = """
        @Published
        var isLoading = false
        @Published
        var title = ""
        """
        let output = """
        @Published
        var isLoading = false
        @Published
        var title     = ""
        """
        testFormatting(for: input, output, rule: .alignAssignments)
    }

    func testAlignEnumCaseRawValues() {
        let input = """
        enum Planet: Int {
            case mercury = 1
            case venus = 2
            case earth = 3
        }
        """
        let output = """
        enum Planet: Int {
            case mercury = 1
            case venus   = 2
            case earth   = 3
        }
        """
        testFormatting(for: input, output, rule: .alignAssignments)
    }

    func testCommentsDoNotSeparateAssignments() {
        let input = """
        struct DeathStar {
            /// The number of crew members
            let capacity = 25000 // excluding droids
            /// Whether the station can be destroyed
            let isIndestructible = false
        }
        """
        let output = """
        struct DeathStar {
            /// The number of crew members
            let capacity         = 25000 // excluding droids
            /// Whether the station can be destroyed
            let isIndestructible = false
        }
        """
        testFormatting(for: input, output, rule: .alignAssignments)
    }

    func testBlankLineSeparatesAssignments() {
        let input = """
        let a = 1
        let bb = 2

        let cccc = 3
        let ddddd = 4
        """
        let output = """
        let a  = 1
        let bb = 2

        let cccc  = 3
        let ddddd = 4
        """
        testFormatting(for: input, output, rule: .alignAssignments)
    }

    func testAlignsAcrossOtherStatements() {
        let input = """
        let a = 1
        print(a)
        let bbbb = 2
        """
        let output = """
        let a    = 1
        print(a)
        let bbbb = 2
        """
        testFormatting(for: input, output, rule: .alignAssignments)
    }

    func testCompoundAssignmentsNotAligned() {
        let input = """
        foo = 1
        barBaz += 2
        quxQuux = 3
        """
        let output = """
        foo     = 1
        barBaz += 2
        quxQuux = 3
        """
        testFormatting(for: input, output, rule: .alignAssignments)
    }

    func testRemovesSpacingFromPreviouslyAlignedAssignments() {
        let input = """
        let a          = 1
        let bb         = 2

        let ccc     = 3
        """
        let output = """
        let a  = 1
        let bb = 2

        let ccc = 3
        """
        testFormatting(for: input, output, rule: .alignAssignments)
    }

    func testAlignsAcrossMultilineValue() {
        let input = """
        let a = 1
        let bb = [
            1,
            2,
        ]
        let cccc = 3
        let d = 4
        """
        let output = """
        let a    = 1
        let bb   = [
            1,
            2,
        ]
        let cccc = 3
        let d    = 4
        """
        testFormatting(for: input, output, rule: .alignAssignments)
    }

    func testAssignmentsInNestedScopeAlignedSeparately() {
        let input = """
        func setUp() {
            let view = UIView()
            let label = makeLabel {
                $0.text = "Hello"
                $0.textAlignment = .center
            }
        }
        """
        let output = """
        func setUp() {
            let view  = UIView()
            let label = makeLabel {
                $0.text          = "Hello"
                $0.textAlignment = .center
            }
        }
        """
        testFormatting(for: input, output, rule: .alignAssignments)
    }

    func testConditionsNotAligned() {
        let input = """
        if let foo = bar,
           let bazQux = quux
        {
            print(foo, bazQux)
        }

        guard let value = optional else { return }

        if case .foo = bar,
           case .bazQux = quux
        {
            print(bar)
        }

        let result = value
        let longerName = value
        """
        let output = """
        if let foo = bar,
           let bazQux = quux
        {
            print(foo, bazQux)
        }

        guard let value = optional else { return }

        if case .foo = bar,
           case .bazQux = quux
        {
            print(bar)
        }

        let result     = value
        let longerName = value
        """
        let options = FormatOptions(alignAssignments: .scope)
        testFormatting(for: input, output, rule: .alignAssignments, options: options)
    }

    func testDefaultArgumentsNotAligned() {
        let input = """
        func foo(
            bar: Int = 0,
            bazQux: String = ""
        ) {
            print(bar, bazQux)
        }
        """
        testFormatting(for: input, rule: .alignAssignments)
    }

    func testAlignmentPreservesArgumentAlignment() {
        let input = """
        let aaaaaaa = 1
        let b = foo(x: 1,
                    y: 2)
        """
        let output = """
        let aaaaaaa = 1
        let b       = foo(x: 1,
                          y: 2)
        """
        testFormatting(for: input, [output], rules: [.alignAssignments, .indent])
    }

    func testDoesNotAlignPastMaxWidth() {
        let input = """
        let a = 1
        let bbbbbbbbbbbbbbbb = 2
        let c = "hello world!"
        let dd = 3
        """
        let output = """
        let a                = 1
        let bbbbbbbbbbbbbbbb = 2
        let c  = "hello world!"
        let dd = 3
        """
        let options = FormatOptions(maxWidth: 25)
        testFormatting(for: input, output, rule: .alignAssignments, options: options)
    }

    func testAlignsLineAfterWrappingToMaxWidth() {
        let input = """
        let a = 1
        let bbbbbbbb = foo(first: 1, second: 2)
        let cc = 3
        """
        let output = """
        let a        = 1
        let bbbbbbbb = foo(
            first: 1,
            second: 2
        )
        let cc       = 3
        """
        let options = FormatOptions(maxWidth: 30)
        testFormatting(for: input, [output], rules: [.alignAssignments, .wrap, .indent], options: options)
    }

    func testAlignsAcrossDeclarationsWithoutValues() {
        let input = """
        struct User {
            let id: UUID
            var name = ""
            let createdAt: Date
            var isEnabled = false

            var loginCount = 0
        }
        """
        let output = """
        struct User {
            let id: UUID
            var name      = ""
            let createdAt: Date
            var isEnabled = false

            var loginCount = 0
        }
        """
        testFormatting(for: input, output, rule: .alignAssignments)
    }

    func testScopeModeAlignsAllAssignmentsInScope() {
        let input = """
        struct Foo {
            let a = 1

            var bbbb = 2

            func foo() {
                let x = 1
                let yyyyyy = 2
                print(x, yyyyyy)
            }

            let cc = 3
        }
        """
        let output = """
        struct Foo {
            let a    = 1

            var bbbb = 2

            func foo() {
                let x      = 1
                let yyyyyy = 2
                print(x, yyyyyy)
            }

            let cc   = 3
        }
        """
        let options = FormatOptions(alignAssignments: .scope)
        testFormatting(for: input, output, rule: .alignAssignments, options: options)
    }

    func testScopeModeDoesNotAlignAcrossSwitchCases() {
        let input = """
        switch value {
        case .a:
            foo = 1
        case .b:
            barBaz = 2
        }
        """
        let options = FormatOptions(alignAssignments: .scope)
        testFormatting(for: input, rule: .alignAssignments, options: options)
    }

    func testConsecutiveSpacesPreservesAlignmentWhenEnabled() {
        let input = """
        let a    = 1
        let bbbb = 2
        let c  =  3
        """
        let output = """
        let a    = 1
        let bbbb = 2
        let c    = 3
        """
        testFormatting(for: input, [output], rules: [.alignAssignments, .consecutiveSpaces])
    }
}
