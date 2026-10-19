//
//  RedundantSwiftVersionCheckTests.swift
//  SwiftFormatTests
//
//  Created by Yang Bai on 18/10/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class RedundantSwiftVersionCheckTests: XCTestCase {
    func testRemoveSatisfiedCompilerCheck() {
        let input = """
        #if compiler(>=5.9)
            foo()
        #endif
        """
        let output = """
            foo()
        """
        let output2 = """
        foo()
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output, output2], rules: [.redundantSwiftVersionCheck], options: options)
    }

    func testRemoveSatisfiedSwiftCheckAndElseBranch() {
        let input = """
        struct Foo {
            #if swift(>=5.2)
                func bar() {}
            #else
                func baz() {}
            #endif
        }
        """
        let output = """
        struct Foo {
                func bar() {}
        }
        """
        let output2 = """
        struct Foo {
            func bar() {}
        }
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, [output, output2], rules: [.redundantSwiftVersionCheck], options: options)
    }

    func testKeepElseBranchOfUnsatisfiedCheck() {
        let input = """
        foo()
        #if swift(<5.9)
            bar()
        #else
            baz()
        #endif
        quux()
        """
        let output = """
        foo()
            baz()
        quux()
        """
        let output2 = """
        foo()
        baz()
        quux()
        """
        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, [output, output2], rules: [.redundantSwiftVersionCheck], options: options)
    }

    func testRemoveNegatedCheckWithoutElseBranch() {
        let input = """
        foo()
        #if !compiler(>=5.9)
            bar()
        #endif
        baz()
        """
        let output = """
        foo()
        baz()
        """
        let options = FormatOptions(swiftVersion: "5.10")
        testFormatting(for: input, output, rule: .redundantSwiftVersionCheck, options: options)
    }

    func testRemoveUnsatisfiedCheckAtEndOfFile() {
        let input = """
        foo()
        #if compiler(<5.9)
            bar()
        #endif
        """
        let output = """
        foo()
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .redundantSwiftVersionCheck, options: options)
    }

    func testCheckForNewerVersionNotRemoved() {
        let input = """
        #if compiler(>=6.0)
            foo()
        #else
            bar()
        #endif
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantSwiftVersionCheck, options: options)
    }

    func testCheckForNewerPatchVersionNotRemoved() {
        let input = """
        #if swift(>=5.9.2)
            foo()
        #endif
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantSwiftVersionCheck, options: options)
    }

    func testMajorVersionCheckRemoved() {
        let input = """
        #if compiler(>=5)
            foo()
        #endif
        """
        let output = """
            foo()
        """
        let output2 = """
        foo()
        """
        let options = FormatOptions(swiftVersion: "5.0")
        testFormatting(for: input, [output, output2], rules: [.redundantSwiftVersionCheck], options: options)
    }

    func testNoChangesWithoutSwiftVersion() {
        let input = """
        #if compiler(>=5.9)
            foo()
        #endif
        """
        testFormatting(for: input, rule: .redundantSwiftVersionCheck)
    }

    func testSwiftCheckUsesSwift5LanguageMode() {
        // A Swift 6 compiler in Swift 5 mode reports a language version of 5.10
        let input = """
        #if swift(>=5.10)
            foo()
        #endif
        #if swift(>=6.0)
            bar()
        #endif
        """
        let output = """
            foo()
        #if swift(>=6.0)
            bar()
        #endif
        """
        let output2 = """
        foo()
        #if swift(>=6.0)
            bar()
        #endif
        """
        let options = FormatOptions(swiftVersion: "6.2", languageMode: "5")
        testFormatting(for: input, [output, output2], rules: [.redundantSwiftVersionCheck], options: options)
    }

    func testSwiftCheckUsesSwift6LanguageMode() {
        let input = """
        #if swift(>=6.0)
            foo()
        #endif
        #if swift(>=6.3)
            bar()
        #endif
        """
        let output = """
            foo()
        #if swift(>=6.3)
            bar()
        #endif
        """
        let output2 = """
        foo()
        #if swift(>=6.3)
            bar()
        #endif
        """
        let options = FormatOptions(swiftVersion: "6.2", languageMode: "6")
        testFormatting(for: input, [output, output2], rules: [.redundantSwiftVersionCheck], options: options)
    }

    func testSwiftCheckUsesSwift4LanguageMode() {
        let input = """
        #if swift(>=4.2)
            foo()
        #endif
        """
        let options = FormatOptions(swiftVersion: "5.9", languageMode: "4")
        testFormatting(for: input, rule: .redundantSwiftVersionCheck, options: options)
    }

    func testSatisfiedElseifBecomesElse() {
        let input = """
        #if swift(>=6)
            foo()
        #elseif compiler(>=6)
            bar()
        #else
            baz()
        #endif
        """
        let output = """
        #if swift(>=6)
            foo()
        #else
            bar()
        #endif
        """
        let options = FormatOptions(swiftVersion: "6.0", languageMode: "5")
        testFormatting(for: input, output, rule: .redundantSwiftVersionCheck, options: options)
    }

    func testElseifAfterUnsatisfiedCheckBecomesIf() {
        let input = """
        #if swift(<5.9)
            foo()
        #elseif os(iOS)
            bar()
        #else
            baz()
        #endif
        """
        let output = """
        #if os(iOS)
            bar()
        #else
            baz()
        #endif
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .redundantSwiftVersionCheck, options: options)
    }

    func testUnsatisfiedElseifRemoved() {
        let input = """
        #if os(iOS)
            foo()
        #elseif compiler(<5.9)
            bar()
        #endif
        """
        let output = """
        #if os(iOS)
            foo()
        #endif
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .redundantSwiftVersionCheck, options: options)
    }

    func testElseifAfterUnsatisfiedCheckSimplified() {
        let input = """
        #if swift(<5.9)
            foo()
        #elseif compiler(>=5.5) && os(iOS)
            bar()
        #elseif compiler(<5.0)
            baz()
        #endif
        """
        let output = """
        #if os(iOS)
            bar()
        #endif
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .redundantSwiftVersionCheck, options: options)
    }

    func testEmptySatisfiedCheckRemoved() {
        let input = """
        foo()
        #if compiler(>=5.9)
        #endif
        bar()
        """
        let output = """
        foo()
        bar()
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .redundantSwiftVersionCheck, options: options)
    }

    func testSatisfiedConjunctRemoved() {
        let input = """
        #if compiler(>=5.5) && canImport(_Concurrency)
            foo()
        #endif
        """
        let output = """
        #if canImport(_Concurrency)
            foo()
        #endif
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .redundantSwiftVersionCheck, options: options)
    }

    func testUnsatisfiedDisjunctRemoved() {
        let input = """
        #if os(Linux) || swift(<5.9)
            foo()
        #endif
        """
        let output = """
        #if os(Linux)
            foo()
        #endif
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .redundantSwiftVersionCheck, options: options)
    }

    func testUnsatisfiedConjunctRemovesBlock() {
        let input = """
        foo()
        #if os(iOS) && !swift(>=5.9)
            bar()
        #endif
        """
        let output = """
        foo()
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .redundantSwiftVersionCheck, options: options)
    }

    func testParenthesizedAndNegatedConditions() {
        let input = """
        #if (compiler(>=5.9) || os(iOS)) && !(swift(<5) && os(Linux))
            foo()
        #endif
        """
        let output = """
            foo()
        """
        let output2 = """
        foo()
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output, output2], rules: [.redundantSwiftVersionCheck], options: options)
    }

    func testNestedOperandsRemoved() {
        let input = """
        #if (os(macOS) || compiler(>=5.5) && canImport(Foo)) && compiler(>=5.9)
            foo()
        #endif
        """
        let output = """
        #if (os(macOS) || canImport(Foo))
            foo()
        #endif
        """
        let output2 = """
        #if os(macOS) || canImport(Foo)
            foo()
        #endif
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output, output2], rules: [.redundantSwiftVersionCheck], options: options)
    }

    func testMixedOperatorsSimplified() {
        let input = """
        #if compiler(>=5.9) && os(iOS) || os(macOS)
            foo()
        #endif
        """
        let output = """
        #if os(iOS) || os(macOS)
            foo()
        #endif
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .redundantSwiftVersionCheck, options: options)
    }

    func testParenthesizedElseifConditionSimplified() {
        let input = """
        #if os(Windows)
            foo()
        #elseif (compiler(<6.1) && !os(WASI)) || (compiler(>=6.1) && _runtime(_multithreaded))
            bar()
        #endif
        """
        let output = """
        #if os(Windows)
            foo()
        #elseif (_runtime(_multithreaded))
            bar()
        #endif
        """
        let options = FormatOptions(swiftVersion: "6.1")
        testFormatting(for: input, output, rule: .redundantSwiftVersionCheck, options: options)
    }

    func testNegatedConditionSimplified() {
        let input = """
        #if !(compiler(>=5.9) && os(iOS))
            foo()
        #endif
        """
        let output = """
        #if !(os(iOS))
            foo()
        #endif
        """
        let output2 = """
        #if !os(iOS)
            foo()
        #endif
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output, output2], rules: [.redundantSwiftVersionCheck], options: options)
    }

    func testOtherConditionsNotChanged() {
        let input = """
        #if DEBUG && canImport(UIKit)
            foo()
        #elseif os(iOS)
            bar()
        #endif
        """
        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, rule: .redundantSwiftVersionCheck, options: options)
    }

    func testNestedChecksRemoved() {
        let input = """
        #if canImport(Foo)
            #if compiler(>=5.9)
                import Foo
            #endif
        #endif
        """
        let output = """
        #if canImport(Foo)
                import Foo
        #endif
        """
        let output2 = """
        #if canImport(Foo)
            import Foo
        #endif
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output, output2], rules: [.redundantSwiftVersionCheck], options: options)
    }

    func testCommentsInBodyPreserved() {
        let input = """
        #if compiler(>=5.9) // Swift 5.9 or later
            // Use the new API
            foo()
        #else
            bar()
        #endif // compiler(>=5.9)
        """
        let output = """
            // Use the new API
            foo()
        """
        let output2 = """
        // Use the new API
        foo()
        """
        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, [output, output2], rules: [.redundantSwiftVersionCheck], options: options)
    }

    func testCommentOnElseifKeptWhenItBecomesElse() {
        let input = """
        #if os(iOS)
            foo()
        #elseif compiler(>=5.9) // newer compilers
            bar()
        #endif
        """
        let output = """
        #if os(iOS)
            foo()
        #else // newer compilers
            bar()
        #endif
        """
        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, output, rule: .redundantSwiftVersionCheck, options: options)
    }

    func testCheckAroundSwitchCaseRemoved() {
        let input = """
        switch foo {
        case .bar:
            break
        #if compiler(>=5.9)
            case .baz:
                break
        #endif
        default:
            break
        }
        """
        let output = """
        switch foo {
        case .bar:
            break
            case .baz:
                break
        default:
            break
        }
        """
        let output2 = """
        switch foo {
        case .bar:
            break
        case .baz:
            break
        default:
            break
        }
        """
        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, [output, output2], rules: [.redundantSwiftVersionCheck], options: options)
    }

    func testCheckDisabledWithDirective() {
        let input = """
        // swiftformat:disable:next redundantSwiftVersionCheck
        #if compiler(>=5.9)
            foo()
        #endif
        """
        let options = FormatOptions(swiftVersion: "6.0")
        testFormatting(for: input, rule: .redundantSwiftVersionCheck, options: options)
    }
}
