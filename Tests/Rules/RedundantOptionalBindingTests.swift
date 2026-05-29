//
//  RedundantOptionalBindingTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 8/1/22.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class RedundantOptionalBindingTests: XCTestCase {
    func testRemovesRedundantOptionalBindingsInSwift5_7() {
        let input = """
        if let foo = foo {
            print(foo)
        }

        else if var bar = bar {
            print(bar)
        }

        guard let self = self else {
            return
        }

        while var quux = quux {
            break
        }
        """

        let output = """
        if let foo {
            print(foo)
        }

        else if var bar {
            print(bar)
        }

        guard let self else {
            return
        }

        while var quux {
            break
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .redundantOptionalBinding, options: options, exclude: [.elseOnSameLine])
    }

    func testRemovesMultipleOptionalBindings() {
        let input = """
        if let foo = foo, let bar = bar, let baaz = baaz {
            print(foo, bar, baaz)
        }

        guard let foo = foo, let bar = bar, let baaz = baaz else {
            return
        }
        """

        let output = """
        if let foo, let bar, let baaz {
            print(foo, bar, baaz)
        }

        guard let foo, let bar, let baaz else {
            return
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .redundantOptionalBinding, options: options)
    }

    func testRemovesMultipleOptionalBindingsOnSeparateLines() {
        let input = """
        if
          let foo = foo,
          let bar = bar,
          let baaz = baaz
        {
          print(foo, bar, baaz)
        }

        guard
          let foo = foo,
          let bar = bar,
          let baaz = baaz
        else {
          return
        }
        """

        let output = """
        if
          let foo,
          let bar,
          let baaz
        {
          print(foo, bar, baaz)
        }

        guard
          let foo,
          let bar,
          let baaz
        else {
          return
        }
        """

        let options = FormatOptions(indent: "  ", swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .redundantOptionalBinding, options: options)
    }

    func testKeepsRedundantOptionalBeforeSwift5_7() {
        let input = """
        if let foo = foo {
            print(foo)
        }
        """

        let options = FormatOptions(swiftVersion: "5.6")
        testFormatting(for: input, rule: .redundantOptionalBinding, options: options)
    }

    func testRenamesWhenOnlyNewNameUsedInIfBody() {
        let input = """
        if let foo = bar {
            print(foo)
        }
        """
        let output = """
        if let bar {
            print(bar)
        }
        """
        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .redundantOptionalBinding, options: options)
    }

    func testKeepsOptionalNotEligibleForShorthand() {
        let input = """
        if let foo = self.foo, let bar = bar(), let baaz = baaz[0] {
            print(foo, bar, baaz)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .redundantOptionalBinding, options: options, exclude: [.redundantSelf])
    }

    func testRedundantSelfAndRedundantOptionalTogether() {
        let input = """
        if let foo = self.foo {
            print(foo)
        }
        """

        let output = """
        if let foo {
            print(foo)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, [output], rules: [.redundantOptionalBinding, .redundantSelf], options: options)
    }

    func testDoesntRemoveShadowingOutsideOfOptionalBinding() {
        let input = """
        let foo = foo

        if let bar = baaz({
            let foo = foo
            print(foo)
        }) {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .redundantOptionalBinding, options: options)
    }

    func testDoesNotRenameWhenNewNameAlreadyReferencedInBody() {
        // We can't safely rename `foo` → `bar` because `bar` is already referenced in the body
        // and the new binding would shadow the outer `bar`, silently changing what `bar` refers to.
        let input = """
        if let foo = bar {
            baaz(bar)
        }
        """
        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .redundantOptionalBinding, options: options)
    }

    func testRenamesBindingWhenOldNameNotUsedInIfBodyAndRhsIsUsed() {
        let input = """
        if let foo = bar {
            return foo
        }
        """
        let output = """
        if let bar {
            return bar
        }
        """
        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .redundantOptionalBinding, options: options)
    }

    func testDoesNotRenameBindingWhenOldNameUsedInIfBody() {
        let input = """
        if let foo = bar {
            baaz(foo, bar)
        }
        """
        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .redundantOptionalBinding, options: options)
    }

    func testRenamesGuardBindingDirectlyInFunctionBody() {
        let input = """
        func foo() -> Int? {
            guard let foo = bar else {
                return nil
            }
            return foo
        }
        """
        let output = """
        func foo() -> Int? {
            guard let bar else {
                return nil
            }
            return bar
        }
        """
        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .redundantOptionalBinding, options: options, exclude: [.blankLinesAfterGuardStatements])
    }

    func testRenamesGuardBindingInComputedPropertyBody() {
        let input = """
        var foo: Int? {
            guard let foo = bar else {
                return nil
            }
            return foo
        }
        """
        let output = """
        var foo: Int? {
            guard let bar else {
                return nil
            }
            return bar
        }
        """
        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .redundantOptionalBinding, options: options, exclude: [.blankLinesAfterGuardStatements])
    }

    func testDoesNotRenameGuardBindingInsideSwitchCase() {
        // The guard's continuation extends to the end of the enclosing function, not the case.
        // Renaming `media` could affect references in sibling functions inside the same enum/class.
        let input = """
        enum Handler {
            static func handle(_ action: Action) {
                switch action {
                case .reorder(let mediaItem):
                    guard let media = mediaItem else { return }
                    moveMedia(media)
                }
            }
            static func moveMedia(_ media: MediaItem) {
                use(media.id)
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .redundantOptionalBinding, options: options,
                       exclude: [.blankLinesAfterGuardStatements, .blankLinesBetweenScopes,
                                 .hoistPatternLet, .wrapConditionalBodies])
    }

    func testRenamesBindingWhenOldNameUsedInSubsequentCondition() {
        let input = """
        if let foo = bar, foo.isValid {
            use(foo)
        }
        """
        let output = """
        if let bar, bar.isValid {
            use(bar)
        }
        """
        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .redundantOptionalBinding, options: options)
    }

    func testDoesNotRenameArgumentLabelsMatchingBindingName() {
        let input = """
        func foo() -> MigrationPlan? {
            if let from = fromValue, let to = toValue {
                return MigrationPlan(from: from, to: to)
            }
            return nil
        }
        """
        let output = """
        func foo() -> MigrationPlan? {
            if let fromValue, let toValue {
                return MigrationPlan(from: fromValue, to: toValue)
            }
            return nil
        }
        """
        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .redundantOptionalBinding, options: options)
    }

    func testDoesNotRenameDictionaryKeyMatchingBindingName() {
        let input = """
        if let foo = bar {
            let dict = [foo: "value"]
            use(dict)
        }
        """
        let output = """
        if let bar {
            let dict = [bar: "value"]
            use(dict)
        }
        """
        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .redundantOptionalBinding, options: options)
    }

    func testDoesNotRenameToClosureShorthandParameter() {
        // `if let $0` is invalid Swift — closure shorthand parameters can't be used as binding names.
        let input = """
        let result = items.compactMap {
            if let value = $0 {
                return value
            }
            return nil
        }
        """
        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .redundantOptionalBinding, options: options)
    }

    func testDoesNotRenameImplicitMemberExpressionMatchingBindingName() {
        // `.url(...)` is an implicit member expression (enum case), not a value reference.
        // Renaming the binding `url` → `value` should not affect `.url`.
        let input = """
        if let url = value {
            return .url(url)
        }
        """
        let output = """
        if let value {
            return .url(value)
        }
        """
        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .redundantOptionalBinding, options: options)
    }
}
