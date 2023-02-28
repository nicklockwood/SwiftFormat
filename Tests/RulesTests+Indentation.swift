//
//  RulesTests+Indent.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 04/09/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class IndentTests: RulesTests {
    // MARK: - indent

    func testReduceIndentAtStartOfFile() {
        let input = "    foo()"
        let output = "foo()"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testReduceIndentAtEndOfFile() {
        let input = "foo()\n   bar()"
        let output = "foo()\nbar()"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    // indent parens

    func testSimpleScope() {
        let input = "foo(\nbar\n)"
        let output = "foo(\n    bar\n)"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testNestedScope() {
        let input = "foo(\nbar {\n}\n)"
        let output = "foo(\n    bar {\n    }\n)"
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["emptyBraces"])
    }

    func testNestedScopeOnSameLine() {
        let input = "foo(bar(\nbaz\n))"
        let output = "foo(bar(\n    baz\n))"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testNestedScopeOnSameLine2() {
        let input = "foo(bar(in:\nbaz))"
        let output = "foo(bar(in:\n    baz))"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentNestedArrayLiteral() {
        let input = "foo(bar: [\n.baz,\n])"
        let output = "foo(bar: [\n    .baz,\n])"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testClosingScopeAfterContent() {
        let input = "foo(\nbar\n)"
        let output = "foo(\n    bar\n)"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testClosingNestedScopeAfterContent() {
        let input = "foo(bar(\nbaz\n))"
        let output = "foo(bar(\n    baz\n))"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedFunctionArguments() {
        let input = "foo(\nbar,\nbaz\n)"
        let output = "foo(\n    bar,\n    baz\n)"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testFunctionArgumentsWrappedAfterFirst() {
        let input = "func foo(bar: Int,\nbaz: Int)"
        let output = "func foo(bar: Int,\n         baz: Int)"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentPreservedForNestedWrappedParameters() {
        let input = """
        let loginResponse = LoginResponse(status: .success(.init(accessToken: session,
                                                                 status: .enabled)),
                                          invoicingURL: .invoicing,
                                          paymentFormURL: .paymentForm)
        """
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIndentPreservedForNestedWrappedParameters2() {
        let input = """
        let loginResponse = LoginResponse(status: .success(.init(accessToken: session,
                                                                 status: .enabled),
                                                           invoicingURL: .invoicing,
                                                           paymentFormURL: .paymentForm))
        """
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIndentPreservedForNestedWrappedParameters3() {
        let input = """
        let loginResponse = LoginResponse(
            status: .success(.init(accessToken: session,
                                   status: .enabled),
                             invoicingURL: .invoicing,
                             paymentFormURL: .paymentForm)
        )
        """
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIndentTrailingClosureInParensContainingUnwrappedArguments() {
        let input = """
        let foo = bar(baz {
            quux(foo, bar)
        })
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentTrailingClosureInParensContainingWrappedArguments() {
        let input = """
        let foo = bar(baz {
            quux(foo,
                 bar)
        })
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentTrailingClosureInParensContainingWrappedArguments2() {
        let input = """
        let foo = bar(baz {
            quux(
                foo,
                bar
            )
        })
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentImbalancedNestedClosingParens() {
        let input = """
        Foo(bar:
            Bar(
                baz: quux
            ))
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentChainedCallAfterClosingParen() {
        let input = """
        foo(
            bar: { baz in
                baz()
            })
            .quux {
                View()
            }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentChainedCallAfterClosingParen2() {
        let input = """
        func makeEpoxyModel() -> EpoxyModeling {
            LegacyEpoxyModelBuilder<BasicRow>(
                dataID: DataID.dismissModalBody.rawValue,
                content: .init(titleText: content.title, subtitleText: content.bodyHtml),
                style: Style.standard
                    .with(property: newValue)
                    .with(anotherProperty: newValue))
                .with(configurer: { view, content, _, _ in
                    view.setHTMLText(content.subtitleText?.unstyledText)
                })
                .build()
        }
        """
        let options = FormatOptions(closingParenOnSameLine: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    // indent modifiers

    func testNoIndentWrappedModifiersForProtocol() {
        let input = "@objc\nprivate\nprotocol Foo {}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    // indent braces

    func testElseClauseIndenting() {
        let input = "if x {\nbar\n} else {\nbaz\n}"
        let output = "if x {\n    bar\n} else {\n    baz\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testNoIndentBlankLines() {
        let input = "{\n\n// foo\n}"
        let output = "{\n\n    // foo\n}"
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["blankLinesAtStartOfScope"])
    }

    func testNestedBraces() {
        let input = "({\n// foo\n}, {\n// bar\n})"
        let output = "({\n    // foo\n}, {\n    // bar\n})"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testBraceIndentAfterComment() {
        let input = "if foo { // comment\nbar\n}"
        let output = "if foo { // comment\n    bar\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testBraceIndentAfterClosingScope() {
        let input = "foo(bar(baz), {\nquux\nbleem\n})"
        let output = "foo(bar(baz), {\n    quux\n    bleem\n})"
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["trailingClosures"])
    }

    func testBraceIndentAfterLineWithParens() {
        let input = "({\nfoo()\nbar\n})"
        let output = "({\n    foo()\n    bar\n})"
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["redundantParens"])
    }

    func testUnindentClosingParenAroundBraces() {
        let input = """
        quux(success: {
            self.bar()
                })
        """
        let output = """
        quux(success: {
            self.bar()
        })
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentDoubleParenthesizedClosures() {
        let input = """
        foo(bar: Foo(success: { _ in
            self.bar()
        }, failure: { _ in
            self.baz()
        }))
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentUnbalancedBraces() {
        let input = """
        foo(bar()
            .map {
                .baz($0)
            })
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentClosureArguments() {
        let input = """
        quux(bar: {
          print(bar)
        },
        baz: {
          print(baz)
        })
        """
        let output = """
        quux(bar: {
                 print(bar)
             },
             baz: {
                 print(baz)
             })
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentClosureArguments2() {
        let input = """
        foo(bar: {
                print(bar)
            },
            baz: {
                print(baz)
            }
        )
        """
        testFormatting(for: input, rule: FormatRules.indent, exclude: ["wrapArguments"])
    }

    func testIndentWrappedClosureParameters() {
        let input = """
        foo { (
            bar: Int,
            baz: Int
        ) in
            print(bar + baz)
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentWrappedClosureCaptureList() {
        let input = """
        foo { [
            title = title,
            weak topView = topView
        ] in
            print(title)
            _ = topView
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    // TODO: add `unwrap` rule to improve this case
    func testIndentWrappedClosureCaptureList2() {
        let input = """
        class A {}
        let a = A()
        let f = { [
            weak a
        ]
        (
            x: Int,
            y: Int
        )
            throws
            ->
            Int
        in
            print("Hello, World! " + String(x + y))
            return x + y
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentWrappedClosureCaptureListWithUnwrappedParameters() {
        let input = """
        foo { [
            title = title,
            weak topView = topView
        ] (bar: Int) in
            print(title, bar)
            _ = topView
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentTrailingClosureArgumentsAfterFunction() {
        let input = """
        var epoxyViewportLogger = EpoxyViewportLogger(
            debounceInterval: 0.5,
            viewportStartImpressionHandler: { [weak self] _, viewportLoggingContext in
                self?.viewportLoggingRegistry.logViewportSessionStart(with: viewportLoggingContext)
            }) { [weak self] _, viewportLoggingContext in
                self?.viewportLoggingRegistry.logViewportSessionEnd(with: viewportLoggingContext)
            }
        """
        let options = FormatOptions(closingParenOnSameLine: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIndentAllmanTrailingClosureArguments() {
        let input = """
        let foo = Foo
            .bar
            { _ in
                bar()
            }
            .baz(5)
            {
                baz()
            }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIndentAllmanTrailingClosureArguments2() {
        let input = """
        DispatchQueue.main.async
        {
            foo()
        }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIndentAllmanTrailingClosureArgumentsAfterFunction() {
        let input = """
        func foo()
        {
            return
        }

        Foo
            .bar()
            .baz
            {
                baz()
            }
            .quux
            {
                quux()
            }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options,
                       exclude: ["redundantReturn"])
    }

    func testNoDoubleIndentClosureArguments() {
        let input = """
        let foo = foo(bar(
            { baz },
            { quux }
        ))
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentLineAfterIndentedWrappedClosure() {
        let input = """
        func foo(for bar: String) -> UIViewController {
            let viewController = Builder().build(
                bar: bar) { viewController in
                    viewController.dismiss(animated, true)
                }

            return viewController
        }
        """
        testFormatting(for: input, rule: FormatRules.indent,
                       exclude: ["braces", "wrapMultilineStatementBraces"])
    }

    func testIndentLineAfterIndentedInlineClosure() {
        let input = """
        func foo(for bar: String) -> UIViewController {
            let viewController = foo(Builder().build(
                bar: bar)) { _ in ViewController() }

            return viewController
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentLineAfterNonIndentedClosure() {
        let input = """
        func foo(for bar: String) -> UIViewController {
            let viewController = Builder().build(bar: bar) { viewController in
                viewController.dismiss(animated, true)
            }

            return viewController
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentMultilineStatementDoesntFailToTerminate() {
        let input = """
        foo(one: 1,
            two: 2).bar { _ in
            "one"
        }
        """
        let options = FormatOptions(
            wrapArguments: .afterFirst,
            closingParenOnSameLine: true
        )
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    // indent switch/case

    func testSwitchCaseIndenting() {
        let input = "switch x {\ncase foo:\nbreak\ncase bar:\nbreak\ndefault:\nbreak\n}"
        let output = "switch x {\ncase foo:\n    break\ncase bar:\n    break\ndefault:\n    break\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testSwitchWrappedCaseIndenting() {
        let input = "switch x {\ncase foo,\nbar,\n    baz:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\ncase foo,\n     bar,\n     baz:\n    break\ndefault:\n    break\n}"
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["sortedSwitchCases"])
    }

    func testSwitchWrappedEnumCaseIndenting() {
        let input = "switch x {\ncase .foo,\n.bar,\n    .baz:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\ncase .foo,\n     .bar,\n     .baz:\n    break\ndefault:\n    break\n}"
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["sortedSwitchCases"])
    }

    func testSwitchWrappedEnumCaseIndentingVariant2() {
        let input = "switch x {\ncase\n.foo,\n.bar,\n    .baz:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\ncase\n    .foo,\n    .bar,\n    .baz:\n    break\ndefault:\n    break\n}"
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["sortedSwitchCases"])
    }

    func testSwitchWrappedEnumCaseIsIndenting() {
        let input = "switch x {\ncase is Foo.Type,\n    is Bar.Type:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\ncase is Foo.Type,\n     is Bar.Type:\n    break\ndefault:\n    break\n}"
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["sortedSwitchCases"])
    }

    func testSwitchCaseIsDictionaryIndenting() {
        let input = "switch x {\ncase foo is [Key: Value]:\nfallthrough\ndefault:\nbreak\n}"
        let output = "switch x {\ncase foo is [Key: Value]:\n    fallthrough\ndefault:\n    break\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testEnumCaseIndenting() {
        let input = "enum Foo {\ncase Bar\ncase Baz\n}"
        let output = "enum Foo {\n    case Bar\n    case Baz\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testEnumCaseIndentingCommas() {
        let input = "enum Foo {\ncase Bar,\nBaz\n}"
        let output = """
        enum Foo {
            case Bar,
                 Baz
        }
        """
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["wrapEnumCases"])
    }

    func testGenericEnumCaseIndenting() {
        let input = "enum Foo<T> {\ncase Bar\ncase Baz\n}"
        let output = "enum Foo<T> {\n    case Bar\n    case Baz\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentSwitchAfterRangeCase() {
        let input = "switch x {\ncase 0 ..< 2:\n    switch y {\n    default:\n        break\n    }\ndefault:\n    break\n}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentEnumDeclarationInsideSwitchCase() {
        let input = "switch x {\ncase y:\nenum Foo {\ncase z\n}\nbar()\ndefault: break\n}"
        let output = "switch x {\ncase y:\n    enum Foo {\n        case z\n    }\n    bar()\ndefault: break\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentEnumCaseBodyAfterWhereClause() {
        let input = "switch foo {\ncase _ where baz < quux:\n    print(1)\n    print(2)\ndefault:\n    break\n}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentSwitchCaseCommentsCorrectly() {
        let input = """
        switch x {
        // comment
        case y:
        // comment
        break
        // comment
        case z:
        break
        }
        """
        let output = """
        switch x {
        // comment
        case y:
            // comment
            break
        // comment
        case z:
            break
        }
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentMultilineSwitchCaseCommentsCorrectly() {
        let input = """
        switch x {
        /*
         * comment
         */
        case y:
        break
        /*
         * comment
         */
        default:
        break
        }
        """
        let output = """
        switch x {
        /*
         * comment
         */
        case y:
            break
        /*
         * comment
         */
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentEnumCaseComment() {
        let input = """
        enum Foo {
           /// bar
           case bar
        }
        """
        let output = """
        enum Foo {
            /// bar
            case bar
        }
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentMultipleSingleLineSwitchCaseCommentsCorrectly() {
        let input = "switch x {\n// comment 1\n// comment 2\ncase y:\n// comment\nbreak\n}"
        let output = "switch x {\n// comment 1\n// comment 2\ncase y:\n    // comment\n    break\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentIfCase() {
        let input = "{\nif case let .foo(msg) = error {}\n}"
        let output = "{\n    if case let .foo(msg) = error {}\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentGuardCase() {
        let input = "{\nguard case .Foo = error else {}\n}"
        let output = "{\n    guard case .Foo = error else {}\n}"
        testFormatting(for: input, output, rule: FormatRules.indent,
                       exclude: ["wrapConditionalBodies"])
    }

    func testIndentIfElse() {
        let input = """
        if foo {
        } else if let bar = baz,
                  let baz = quux {}
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testNestedIndentIfElse() {
        let input = """
        if bar {} else if baz,
                          quux
        {
            if foo {
            } else if let bar = baz,
                      let baz = quux {}
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentIfCaseLet() {
        let input = """
        if case let foo = foo,
           let bar = bar {}
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentMultipleIfLet() {
        let input = """
        if let foo = foo, let bar = bar,
           let baz = baz {}
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentWrappedConditionAlignsWithParen() {
        let input = """
        do {
            if let foo = foo(
                bar: 5
            ), let bar = bar,
            baz == quux {
                baz()
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentWrappedConditionAlignsWithParen2() {
        let input = """
        do {
            if let foo = foo({
                bar()
            }), bar == baz,
            let quux == baz {
                baz()
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentUnknownDefault() {
        let input = """
        switch foo {
            case .bar:
                break
            @unknown default:
                break
        }
        """
        let output = """
        switch foo {
        case .bar:
            break
        @unknown default:
            break
        }
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentUnknownDefaultOnOwnLine() {
        let input = """
        switch foo {
            case .bar:
                break
            @unknown
            default:
                break
        }
        """
        let output = """
        switch foo {
        case .bar:
            break
        @unknown
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentUnknownCase() {
        let input = """
        switch foo {
            case .bar:
                break
            @unknown case _:
                break
        }
        """
        let output = """
        switch foo {
        case .bar:
            break
        @unknown case _:
            break
        }
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentUnknownCaseOnOwnLine() {
        let input = """
        switch foo {
            case .bar:
                break
            @unknown
            case _:
                break
        }
        """
        let output = """
        switch foo {
        case .bar:
            break
        @unknown
        case _:
            break
        }
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedClassDeclaration() {
        let input = """
        class Foo: Bar,
            Baz {
            init() {}
        }
        """
        testFormatting(for: input, rule: FormatRules.indent,
                       exclude: ["wrapMultilineStatementBraces"])
    }

    func testWrappedClassDeclarationLikeXcode() {
        let input = """
        class Foo: Bar,
            Baz {
            init() {}
        }
        """
        let output = """
        class Foo: Bar,
        Baz {
            init() {}
        }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testWrappedClassDeclarationWithBracesOnSameLineLikeXcode() {
        let input = """
        class Foo: Bar,
        Baz {}
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testWrappedClassDeclarationWithBraceOnNextLineLikeXcode() {
        let input = """
        class Foo: Bar,
            Baz
        {
            init() {}
        }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testWrappedClassWhereDeclarationLikeXcode() {
        let input = """
        class Foo<T>: Bar
            where T: Baz {
            init() {}
        }
        """
        let output = """
        class Foo<T>: Bar
        where T: Baz {
            init() {}
        }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIndentSwitchCaseDo() {
        let input = """
        switch foo {
        case .bar: do {
                baz()
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    // indentCase = true

    func testSwitchCaseWithIndentCaseTrue() {
        let input = "switch x {\ncase foo:\nbreak\ncase bar:\nbreak\ndefault:\nbreak\n}"
        let output = "switch x {\n    case foo:\n        break\n    case bar:\n        break\n    default:\n        break\n}"
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testSwitchWrappedEnumCaseWithIndentCaseTrue() {
        let input = "switch x {\ncase .foo,\n.bar,\n    .baz:\n    break\ndefault:\n    break\n}"
        let output = "switch x {\n    case .foo,\n         .bar,\n         .baz:\n        break\n    default:\n        break\n}"
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options, exclude: ["sortedSwitchCases"])
    }

    func testIndentMultilineSwitchCaseCommentsWithIndentCaseTrue() {
        let input = "switch x {\n/*\n * comment\n */\ncase y:\nbreak\n/*\n * comment\n */\ndefault:\nbreak\n}"
        let output = "switch x {\n    /*\n     * comment\n     */\n    case y:\n        break\n    /*\n     * comment\n     */\n    default:\n        break\n}"
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testNoMangleLabelWhenIndentCaseTrue() {
        let input = "foo: while true {\n    break foo\n}"
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIndentMultipleSingleLineSwitchCaseCommentsWithCommentsIgnoredCorrectlyWhenIndentCaseTrue() {
        let input = """
        switch x {
            // bar
            case .y: return 1
            // baz
            case .z: return 2
        }
        """
        let options = FormatOptions(indentCase: true, indentComments: false)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIndentUnknownDefaultCorrectlyWhenIndentCaseTrue() {
        let input = """
        switch foo {
        case .bar:
            break
        @unknown default:
            break
        }
        """
        let output = """
        switch foo {
            case .bar:
                break
            @unknown default:
                break
        }
        """
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIndentUnknownCaseCorrectlyWhenIndentCaseTrue() {
        let input = """
        switch foo {
        case .bar:
            break
        @unknown case _:
            break
        }
        """
        let output = """
        switch foo {
            case .bar:
                break
            @unknown case _:
                break
        }
        """
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIndentSwitchCaseDoWhenIndentCaseTrue() {
        let input = """
        switch foo {
            case .bar: do {
                    baz()
                }
        }
        """
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    // indent wrapped lines

    func testWrappedLineAfterOperator() {
        let input = "if x {\nlet y = foo +\nbar\n}"
        let output = "if x {\n    let y = foo +\n        bar\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedLineAfterComma() {
        let input = "let a = b,\nb = c"
        let output = "let a = b,\n    b = c"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedBeforeComma() {
        let input = "let a = b\n, b = c"
        let output = "let a = b\n    , b = c"
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["leadingDelimiters"])
    }

    func testWrappedLineAfterCommaInsideArray() {
        let input = "[\nfoo,\nbar,\n]"
        let output = "[\n    foo,\n    bar,\n]"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedLineBeforeCommaInsideArray() {
        let input = "[\nfoo\n, bar,\n]"
        let output = "[\n    foo\n    , bar,\n]"
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options,
                       exclude: ["leadingDelimiters"])
    }

    func testWrappedLineAfterCommaInsideInlineArray() {
        let input = "[foo,\nbar]"
        let output = "[foo,\n bar]"
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testWrappedLineBeforeCommaInsideInlineArray() {
        let input = "[foo\n, bar]"
        let output = "[foo\n , bar]"
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options,
                       exclude: ["leadingDelimiters"])
    }

    func testWrappedLineAfterColonInFunction() {
        let input = "func foo(bar:\nbaz)"
        let output = "func foo(bar:\n    baz)"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testNoDoubleIndentOfWrapAfterAsAfterOpenScope() {
        let input = "(foo as\nBar)"
        let output = "(foo as\n    Bar)"
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["redundantParens"])
    }

    func testNoDoubleIndentOfWrapBeforeAsAfterOpenScope() {
        let input = "(foo\nas Bar)"
        let output = "(foo\n    as Bar)"
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["redundantParens"])
    }

    func testDoubleIndentWhenScopesSeparatedByWrap() {
        let input = """
        (foo
        as Bar {
        baz
        })
        """
        let output = """
        (foo
            as Bar {
                baz
            })
        """
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["redundantParens"])
    }

    func testNoDoubleIndentWhenScopesSeparatedByWrap() {
        let input = "(foo\nas Bar {\nbaz\n}\n)"
        let output = "(foo\n    as Bar {\n        baz\n    }\n)"
        testFormatting(for: input, output, rule: FormatRules.indent,
                       exclude: ["wrapArguments", "redundantParens"])
    }

    func testNoPermanentReductionInScopeAfterWrap() {
        let input = "{ foo\nas Bar\nlet baz = 5\n}"
        let output = "{ foo\n    as Bar\n    let baz = 5\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedLineBeforeOperator() {
        let input = "if x {\nlet y = foo\n+ bar\n}"
        let output = "if x {\n    let y = foo\n        + bar\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedLineBeforeIsOperator() {
        let input = "if x {\nlet y = foo\nis Bar\n}"
        let output = "if x {\n    let y = foo\n        is Bar\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedLineAfterForKeyword() {
        let input = "for\ni in range {}"
        let output = "for\n    i in range {}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedLineAfterInKeyword() {
        let input = "for i in\nrange {}"
        let output = "for i in\n    range {}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedLineAfterDot() {
        let input = "let foo = bar.\nbaz"
        let output = "let foo = bar.\n    baz"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedLineBeforeDot() {
        let input = "let foo = bar\n.baz"
        let output = "let foo = bar\n    .baz"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedLineBeforeWhere() {
        let input = "let foo = bar\nwhere foo == baz"
        let output = "let foo = bar\n    where foo == baz"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedLineAfterWhere() {
        let input = "let foo = bar where\nfoo == baz"
        let output = "let foo = bar where\n    foo == baz"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedLineBeforeGuardElse() {
        let input = "guard let foo = bar\nelse { return }"
        testFormatting(for: input, rule: FormatRules.indent,
                       exclude: ["wrapConditionalBodies"])
    }

    func testWrappedLineAfterGuardElse() {
        // Don't indent because this case is handled by braces rule
        let input = "guard let foo = bar else\n{ return }"
        testFormatting(for: input, rule: FormatRules.indent,
                       exclude: ["elseOnSameLine", "wrapConditionalBodies"])
    }

    func testWrappedLineAfterComment() {
        let input = "foo = bar && // comment\nbaz"
        let output = "foo = bar && // comment\n    baz"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedLineInClosure() {
        let input = "forEach { item in\nprint(item)\n}"
        let output = "forEach { item in\n    print(item)\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedGuardInClosure() {
        let input = """
        forEach { foo in
            guard let foo = foo,
                  let bar = bar else { break }
        }
        """
        testFormatting(for: input, rule: FormatRules.indent,
                       exclude: ["wrapMultilineStatementBraces", "wrapConditionalBodies"])
    }

    func testConsecutiveWraps() {
        let input = "let a = b +\nc +\nd"
        let output = "let a = b +\n    c +\n    d"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrapReset() {
        let input = "let a = b +\nc +\nd\nlet a = b +\nc +\nd"
        let output = "let a = b +\n    c +\n    d\nlet a = b +\n    c +\n    d"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentElseAfterComment() {
        let input = "if x {}\n// comment\nelse {}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testWrappedLinesWithComments() {
        let input = "let foo = bar ||\n // baz||\nquux"
        let output = "let foo = bar ||\n    // baz||\n    quux"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testNoIndentAfterAssignOperatorToVariable() {
        let input = "let greaterThan = >\nlet lessThan = <"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testNoIndentAfterDefaultAsIdentifier() {
        let input = "let foo = FileManager.default\n/// Comment\nlet bar = 0"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentClosureStartingOnIndentedLine() {
        let input = "foo\n.bar {\nbaz()\n}"
        let output = "foo\n    .bar {\n        baz()\n    }"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentClosureStartingOnIndentedLineInVar() {
        let input = "var foo = foo\n.bar {\nbaz()\n}"
        let output = "var foo = foo\n    .bar {\n        baz()\n    }"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentClosureStartingOnIndentedLineInLet() {
        let input = "let foo = foo\n.bar {\nbaz()\n}"
        let output = "let foo = foo\n    .bar {\n        baz()\n    }"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentClosureStartingOnIndentedLineInTypedVar() {
        let input = "var: Int foo = foo\n.bar {\nbaz()\n}"
        let output = "var: Int foo = foo\n    .bar {\n        baz()\n    }"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentClosureStartingOnIndentedLineInTypedLet() {
        let input = "let: Int foo = foo\n.bar {\nbaz()\n}"
        let output = "let: Int foo = foo\n    .bar {\n        baz()\n    }"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testNestedWrappedIfIndents() {
        let input = "if foo {\nif bar &&\n(baz ||\nquux) {\nfoo()\n}\n}"
        let output = """
        if foo {
            if bar &&
                (baz ||
                    quux) {
                foo()
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["andOperator", "wrapMultilineStatementBraces"])
    }

    func testWrappedEnumThatLooksLikeIf() {
        let input = "foo &&\n bar.if {\nfoo()\n}"
        let output = "foo &&\n    bar.if {\n        foo()\n    }"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testChainedClosureIndents() {
        let input = "foo\n.bar {\nbaz()\n}\n.bar {\nbaz()\n}"
        let output = "foo\n    .bar {\n        baz()\n    }\n    .bar {\n        baz()\n    }"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testChainedClosureIndentsAfterIfCondition() {
        let input = "if foo {\nbar()\n.baz()\n}\n\nfoo\n.bar {\nbaz()\n}\n.bar {\nbaz()\n}"
        let output = "if foo {\n    bar()\n        .baz()\n}\n\nfoo\n    .bar {\n        baz()\n    }\n    .bar {\n        baz()\n    }"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testChainedClosureIndentsAfterIfCondition2() {
        let input = """
        if foo {
        bar()
        .baz()
        }

        foo
        .bar {
        baz()
        }.bar {
        baz()
        }
        """
        let output = """
        if foo {
            bar()
                .baz()
        }

        foo
            .bar {
                baz()
            }.bar {
                baz()
            }
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testChainedClosureIndentsAfterVarDeclaration() {
        let input = "var foo: Int\nfoo\n.bar {\nbaz()\n}\n.bar {\nbaz()\n}"
        let output = "var foo: Int\nfoo\n    .bar {\n        baz()\n    }\n    .bar {\n        baz()\n    }"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testChainedClosureIndentsAfterLetDeclaration() {
        let input = "let foo: Int\nfoo\n.bar {\nbaz()\n}\n.bar {\nbaz()\n}"
        let output = "let foo: Int\nfoo\n    .bar {\n        baz()\n    }\n    .bar {\n        baz()\n    }"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testChainedClosureIndentsSeparatedByComments() {
        let input = """
        foo {
            doFoo()
        }
        // bar
        .bar {
            doBar()
        }
        // baz
        .baz {
            doBaz($0)
        }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options,
                       exclude: ["blankLinesBetweenScopes"])
    }

    func testChainedFunctionIndents() {
        let input = """
        Button(action: {
            print("foo")
        })
        .buttonStyle(bar())
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testChainedFunctionIndentWithXcodeIndentation() {
        let input = """
        Button(action: {
            print("foo")
        })
        .buttonStyle(bar())
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testWrappedClosureIndentAfterAssignment() {
        let input = """
        let bar =
            baz { _ in
                print("baz")
            }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testChainedFunctionsInPropertySetter() {
        let input = """
        private let foo = bar(a: "A", b: "B")
        .baz()!
        .quux
        """
        let output = """
        private let foo = bar(a: "A", b: "B")
            .baz()!
            .quux
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testChainedFunctionsInPropertySetterOnNewLine() {
        let input = """
        private let foo =
        bar(a: "A", b: "B")
        .baz()!
        .quux
        """
        let output = """
        private let foo =
            bar(a: "A", b: "B")
                .baz()!
                .quux
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testChainedFunctionsInsideIf() {
        let input = "if foo {\nreturn bar()\n.baz()\n}"
        let output = "if foo {\n    return bar()\n        .baz()\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testChainedFunctionsInsideForLoop() {
        let input = "for x in y {\nfoo\n.bar {\nbaz()\n}\n.quux()\n}"
        let output = "for x in y {\n    foo\n        .bar {\n            baz()\n        }\n        .quux()\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testChainedFunctionsAfterAnIfStatement() {
        let input = "if foo {}\nbar\n.baz {\n}\n.quux()"
        let output = "if foo {}\nbar\n    .baz {\n    }\n    .quux()"
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["emptyBraces"])
    }

    func testIndentInsideWrappedIfStatementWithClosureCondition() {
        let input = "if foo({ 1 }) ||\nbar {\nbaz()\n}"
        let output = "if foo({ 1 }) ||\n    bar {\n    baz()\n}"
        testFormatting(for: input, output, rule: FormatRules.indent, exclude: ["wrapMultilineStatementBraces"])
    }

    func testIndentInsideWrappedClassDefinition() {
        let input = "class Foo\n: Bar {\nbaz()\n}"
        let output = "class Foo\n    : Bar {\n    baz()\n}"
        testFormatting(for: input, output, rule: FormatRules.indent,
                       exclude: ["leadingDelimiters", "wrapMultilineStatementBraces"])
    }

    func testIndentInsideWrappedProtocolDefinition() {
        let input = "protocol Foo\n: Bar, Baz {\nbaz()\n}"
        let output = "protocol Foo\n    : Bar, Baz {\n    baz()\n}"
        testFormatting(for: input, output, rule: FormatRules.indent,
                       exclude: ["leadingDelimiters", "wrapMultilineStatementBraces"])
    }

    func testIndentInsideWrappedVarStatement() {
        let input = "var Foo:\nBar {\nreturn 5\n}"
        let output = "var Foo:\n    Bar {\n    return 5\n}"
        testFormatting(for: input, output, rule: FormatRules.indent,
                       exclude: ["wrapMultilineStatementBraces"])
    }

    func testNoIndentAfterOperatorDeclaration() {
        let input = "infix operator ?=\nfunc ?= (lhs _: Int, rhs _: Int) -> Bool {}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testNoIndentAfterChevronOperatorDeclaration() {
        let input = "infix operator =<<\nfunc =<< <T>(lhs _: T, rhs _: T) -> T {}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentWrappedStringDictionaryKeysAndValues() {
        let input = "[\n\"foo\":\n\"bar\",\n\"baz\":\n\"quux\",\n]"
        let output = "[\n    \"foo\":\n        \"bar\",\n    \"baz\":\n        \"quux\",\n]"
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIndentWrappedEnumDictionaryKeysAndValues() {
        let input = "[\n.foo:\n.bar,\n.baz:\n.quux,\n]"
        let output = "[\n    .foo:\n        .bar,\n    .baz:\n        .quux,\n]"
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIndentWrappedFunctionArgument() {
        let input = "foobar(baz: a &&\nb)"
        let output = "foobar(baz: a &&\n    b)"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentWrappedFunctionClosureArgument() {
        let input = "foobar(baz: { a &&\nb })"
        let output = "foobar(baz: { a &&\n        b })"
        testFormatting(for: input, output, rule: FormatRules.indent,
                       exclude: ["trailingClosures", "braces"])
    }

    func testIndentWrappedFunctionWithClosureArgument() {
        let input = """
        foo(bar: { bar in
                bar()
            },
            baz: baz)
        """
        let options = FormatOptions(closingParenOnSameLine: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIndentClassDeclarationContainingComment() {
        let input = "class Foo: Bar,\n    // Comment\n    Baz {}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testWrappedLineAfterTypeAttribute() {
        let input = """
        let f: @convention(swift)
            (Int) -> Int = { x in x }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testWrappedLineAfterTypeAttribute2() {
        let input = """
        func foo(_: @escaping
            (Int) -> Int) {}
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testWrappedLineAfterNonTypeAttribute() {
        let input = """
        @discardableResult
        func foo() -> Int { 5 }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentWrappedClosureAfterSwitch() {
        let input = """
        switch foo {
        default:
            break
        }
        bar
            .map {
                // baz
            }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testSingleIndentTrailingClosureBody() {
        let input = """
        func foo() {
            method(
                withParameter: 1,
                otherParameter: 2
            ) { [weak self] in
                guard let error = error else { return }
                print("and a trailing closure")
            }
        }
        """
        let options = FormatOptions(wrapArguments: .disabled, closingParenOnSameLine: false)
        testFormatting(for: input, rule: FormatRules.indent, options: options,
                       exclude: ["wrapConditionalBodies"])
    }

    func testSingleIndentTrailingClosureBody2() {
        let input = """
        func foo() {
            method(withParameter: 1,
                   otherParameter: 2) { [weak self] in
                guard let error = error else { return }
                print("and a trailing closure")
            }
        }
        """
        let options = FormatOptions(wrapArguments: .disabled, closingParenOnSameLine: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options,
                       exclude: ["wrapConditionalBodies", "wrapMultilineStatementBraces"])
    }

    func testDoubleIndentTrailingClosureBody() {
        let input = """
        func foo() {
            method(
                withParameter: 1,
                otherParameter: 2) { [weak self] in
                    guard let error = error else { return }
                    print("and a trailing closure")
                }
        }
        """
        let options = FormatOptions(wrapArguments: .disabled, closingParenOnSameLine: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options,
                       exclude: ["wrapConditionalBodies", "wrapMultilineStatementBraces"])
    }

    func testDoubleIndentTrailingClosureBody2() {
        let input = """
        extension Foo {
            func bar() -> Bar? {
                return Bar(with: Baz(
                    baz: baz)) { _ in
                        print("hello")
                    }
            }
        }
        """
        let options = FormatOptions(wrapArguments: .disabled, closingParenOnSameLine: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options,
                       exclude: ["wrapMultilineStatementBraces"])
    }

    func testNoDoubleIndentTrailingClosureBodyIfLineStartsWithClosingBrace() {
        let input = """
        let alert = Foo.alert(buttonCallback: {
            okBlock()
        }, cancelButtonTitle: cancelTitle) {
            cancelBlock()
        }
        """
        let options = FormatOptions(wrapArguments: .disabled, closingParenOnSameLine: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testSingleIndentTrailingClosureBodyThatStartsOnFollowingLine() {
        let input = """
        func foo() {
            method(
                withParameter: 1,
                otherParameter: 2)
            { [weak self] in
                guard let error = error else { return }
                print("and a trailing closure")
            }
        }
        """
        let options = FormatOptions(wrapArguments: .disabled, closingParenOnSameLine: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options,
                       exclude: ["braces", "wrapConditionalBodies"])
    }

    func testSingleIndentTrailingClosureBodyOfShortMethod() {
        let input = """
        method(withParameter: 1) { [weak self] in
            guard let error = error else { return }
            print("and a trailing closure")
        }
        """
        let options = FormatOptions(wrapArguments: .disabled, closingParenOnSameLine: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options,
                       exclude: ["wrapConditionalBodies"])
    }

    func testNoDoubleIndentInInsideClosure() {
        let input = """
        let foo = bar({ baz
            in
            baz
        })
        """
        testFormatting(for: input, rule: FormatRules.indent,
                       exclude: ["trailingClosures"])
    }

    func testNoDoubleIndentInInsideClosure2() {
        let input = """
        foo(where: { _ in
            bar()
        }) { _ in
            print("and a trailing closure")
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testNoDoubleIndentInInsideClosure3() {
        let input = """
        foo {
            [weak self] _ in
            self?.bar()
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testNoDoubleIndentInInsideClosure4() {
        let input = """
        foo {
            (baz: Int) in
            self?.bar(baz)
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testNoDoubleIndentInInsideClosure5() {
        let input = """
        foo { [weak self] bar in
            for baz in bar {
                self?.print(baz)
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testNoDoubleIndentInInsideClosure6() {
        let input = """
        foo { (bar: [Int]) in
            for baz in bar {
                print(baz)
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testNoDoubleIndentForInInsideFunction() {
        let input = """
        func foo() { // comment here
            for idx in 0 ..< 100 {
                print(idx)
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testNoUnindentTrailingClosure() {
        let input = """
        private final class Foo {
            func animateTransition() {
                guard let fromVC = transitionContext.viewController(forKey: .from),
                      let toVC = transitionContext.viewController(forKey: .to) else {
                    return
                }

                UIView.transition(
                    with: transitionContext.containerView,
                    duration: transitionDuration(using: transitionContext),
                    options: []) {
                        fromVC.view.alpha = 0
                        transitionContext.containerView.addSubview(toVC.view)
                        toVC.view.frame = transitionContext.finalFrame(for: toVC)
                        toVC.view.alpha = 1
                    } completion: { _ in
                        transitionContext.completeTransition(true)
                        fromVC.view.removeFromSuperview()
                    }
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.indent,
                       exclude: ["wrapArguments", "wrapMultilineStatementBraces"])
    }

    func testIndentChainedPropertiesAfterFunctionCall() {
        let input = """
        let foo = Foo(
            bar: baz
        )
        .bar
        .baz
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentChainedPropertiesAfterFunctionCallWithXcodeIndentation() {
        let input = """
        let foo = Foo(
            bar: baz
        )
        .bar
        .baz
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIndentChainedPropertiesAfterFunctionCall2() {
        let input = """
        let foo = Foo({
            print("")
        })
        .bar
        .baz
        """
        testFormatting(for: input, rule: FormatRules.indent,
                       exclude: ["trailingClosures"])
    }

    func testIndentChainedPropertiesAfterFunctionCallWithXcodeIndentation2() {
        let input = """
        let foo = Foo({
            print("")
        })
        .bar
        .baz
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options,
                       exclude: ["trailingClosures"])
    }

    func testIndentChainedMethodsAfterTrailingClosure() {
        let input = """
        func foo() -> some View {
            HStack(spacing: 0) {
                foo()
            }
            .bar()
            .baz()
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentChainedMethodsAfterTrailingClosureWithXcodeIndentation() {
        let input = """
        func foo() -> some View {
            HStack(spacing: 0) {
                foo()
            }
            .bar()
            .baz()
        }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIndentChainedMethodsAfterWrappedMethodAfterTrailingClosure() {
        let input = """
        func foo() -> some View {
            HStack(spacing: 0) {
                foo()
            }
            .bar(foo: 1,
                 bar: baz ? 2 : 3)
            .baz()
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentChainedMethodsAfterWrappedMethodAfterTrailingClosureWithXcodeIndentation() {
        let input = """
        func foo() -> some View {
            HStack(spacing: 0) {
                foo()
            }
            .bar(foo: 1,
                 bar: baz ? 2 : 3)
            .baz()
        }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testChainedFunctionOnNewLineWithXcodeIndentation() {
        let input = """
        bar(a: "A", b: "B")
        .baz()!
        .quux
        """
        let output = """
        bar(a: "A", b: "B")
            .baz()!
            .quux
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testChainedFunctionOnNewLineWithXcodeIndentation2() {
        let input = """
        let foo = bar
            .baz { _ in
                true
            }
            .quux { _ in
                false
            }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testCommentSeparatedChainedFunctionAfterBraceWithXcodeIndentation() {
        let input = """
        func foo() {
            bar {
                doSomething()
            }
            // baz
            .baz()
        }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testChainedFunctionsInPropertySetterOnNewLineWithXcodeIndentation() {
        let input = """
        private let foo =
        bar(a: "A", b: "B")
        .baz()!
        .quux
        """
        let output = """
        private let foo =
            bar(a: "A", b: "B")
            .baz()!
            .quux
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testChainedFunctionsInFunctionWithReturnOnNewLineWithXcodeIndentation() {
        let input = """
        func foo() -> Bool {
        return
        bar(a: "A", b: "B")
        .baz()!
        .quux
        }
        """
        let output = """
        func foo() -> Bool {
            return
                bar(a: "A", b: "B")
                .baz()!
                .quux
        }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testChainedFunctionInGuardIndentation() {
        let input = """
        guard
            let baz = foo
            .bar
            .baz
        else { return }
        """
        testFormatting(for: input, rule: FormatRules.indent,
                       exclude: ["wrapConditionalBodies"])
    }

    func testChainedFunctionInGuardWithXcodeIndentation() {
        let input = """
        guard
            let baz = foo
            .bar
            .baz
        else { return }
        """
        let output = """
        guard
            let baz = foo
                .bar
                .baz
        else { return }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, output, rule: FormatRules.indent,
                       options: options, exclude: ["wrapConditionalBodies"])
    }

    func testChainedFunctionInGuardIndentation2() {
        let input = """
        guard aBool,
              anotherBool,
              aTestArray
              .map { $0 * 2 }
              .filter { $0 == 4 }
              .isEmpty,
              yetAnotherBool
        else { return }
        """
        testFormatting(for: input, rule: FormatRules.indent,
                       exclude: ["wrapConditionalBodies"])
    }

    func testChainedFunctionInGuardWithXcodeIndentation2() {
        let input = """
        guard aBool,
              anotherBool,
              aTestArray
              .map { $0 * 2 }
            .filter { $0 == 4 }
            .isEmpty,
            yetAnotherBool
        else { return }
        """
        // TODO: fix indent for `yetAnotherBool`
        let output = """
        guard aBool,
              anotherBool,
              aTestArray
                  .map { $0 * 2 }
                  .filter { $0 == 4 }
                  .isEmpty,
                  yetAnotherBool
        else { return }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, output, rule: FormatRules.indent,
                       options: options, exclude: ["wrapConditionalBodies"])
    }

    func testWrappedChainedFunctionsWithNestedScopeIndent() {
        let input = """
        var body: some View {
            VStack {
                ZStack {
                    Text()
                }
                .gesture(DragGesture()
                    .onChanged { value in
                        print(value)
                    })
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testConditionalCompiledWrappedChainedFunctionIndent() {
        let input = """
        var body: some View {
            VStack {
                // some view
            }
            #if os(macOS)
                .frame(minWidth: 200)
            #endif
        }
        """
        let output = """
        var body: some View {
            VStack {
                // some view
            }
            #if os(macOS)
            .frame(minWidth: 200)
            #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .indent)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testConditionalCompiledWrappedChainedFunctionWithIfdefNoIndent() {
        let input = """
        var body: some View {
            VStack {
                // some view
            }
            #if os(macOS)
                .frame(minWidth: 200)
            #endif
        }
        """
        let output = """
        var body: some View {
            VStack {
                // some view
            }
            #if os(macOS)
            .frame(minWidth: 200)
            #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testConditionalCompiledWrappedChainedFunctionWithIfdefOutdent() {
        let input = """
        var body: some View {
            VStack {
                // some view
            }
        #if os(macOS)
        .frame(minWidth: 200)
        #endif
        }
        """
        let output = """
        var body: some View {
            VStack {
                // some view
            }
        #if os(macOS)
            .frame(minWidth: 200)
        #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testChainedOrOperatorsInFunctionWithReturnOnNewLine() {
        let input = """
        func foo(lhs: Bool, rhs: Bool) -> Bool {
        return
        lhs == rhs &&
        lhs == rhs &&
        lhs == rhs
        }
        """
        let output = """
        func foo(lhs: Bool, rhs: Bool) -> Bool {
            return
                lhs == rhs &&
                lhs == rhs &&
                lhs == rhs
        }
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testWrappedSingleLineClosureOnNewLine() {
        let input = """
        func foo() {
            let bar =
                { print("foo") }
        }
        """
        testFormatting(for: input, rule: FormatRules.indent, exclude: ["braces"])
    }

    func testWrappedMultilineClosureOnNewLine() {
        let input = """
        func foo() {
            let bar =
                {
                    print("foo")
                }
        }
        """
        testFormatting(for: input, rule: FormatRules.indent, exclude: ["braces"])
    }

    func testWrappedMultilineClosureOnNewLineWithAllmanBraces() {
        let input = """
        func foo() {
            let bar =
            {
                print("foo")
            }
        }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options,
                       exclude: ["braces"])
    }

    func testIndentChainedPropertiesAfterMultilineStringXcode() {
        let input = """
        let foo = \"\""
        bar
        \"\""
            .bar
            .baz
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testWrappedExpressionIndentAfterTryInClosure() {
        let input = """
        getter = { in
            try foo ??
                bar
        }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testNoIndentTryAfterCommaInCollection() {
        let input = """
        let expectedTabs: [Pet] = [
            viewModel.bird,
            try XCTUnwrap(viewModel.cat),
            try XCTUnwrap(viewModel.dog),
            viewModel.snake,
        ]
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentChainedFunctionAfterTryInParens() {
        let input = """
        func fooify(_ array: [FooBar]) -> [Foo] {
            return (
                try? array
                    .filter { !$0.isBar }
                    .compactMap { $0.foo }
            ) ?? []
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentLabelledTrailingClosure() {
        let input = """
        var buttonLabel: some View {
            self.label()
                .if(self.isInline) {
                    $0.font(.hsBody)
                }
                else: {
                    $0.font(.hsControl)
                }
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentLinewrappedMultipleTrailingClosures() {
        let input = """
        UIView.animate(withDuration: 0) {
            fromView.transform = .identity
        }
        completion: { finished in
            context.completeTransition(finished)
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentLinewrappedMultipleTrailingClosures2() {
        let input = """
        func foo() {
            UIView.animate(withDuration: 0) {
                fromView.transform = .identity
            }
            completion: { finished in
                context.completeTransition(finished)
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    // indent comments

    func testCommentIndenting() {
        let input = "/* foo\nbar */"
        let output = "/* foo\n bar */"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testCommentIndentingWithTrailingClose() {
        let input = "/*\nfoo\n*/"
        let output = "/*\n foo\n */"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testCommentIndentingWithTrailingClose2() {
        let input = "/* foo\n*/"
        let output = "/* foo\n */"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testNestedCommentIndenting() {
        let input = """
        /*
         class foo() {
             /*
              * Nested comment
              */
             bar {}
         }
         */
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testNestedCommentIndenting2() {
        let input = """
        /*
        Some description;
        ```
        func foo() {
            bar()
        }
        ```
        */
        """
        let output = """
        /*
         Some description;
         ```
         func foo() {
             bar()
         }
         ```
         */
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testCommentedCodeBlocksNotIndented() {
        let input = "func foo() {\n//    var foo: Int\n}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testBlankCodeCommentBlockLinesNotIndented() {
        let input = "func foo() {\n//\n}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    // TODO: maybe need special case handling for this?
    func testIndentWrappedTrailingComment() {
        let input = """
        let foo = 5 // a wrapped
                    // comment
                    // block
        """
        let output = """
        let foo = 5 // a wrapped
        // comment
        // block
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    // indent multiline strings

    func testSimpleMultilineString() {
        let input = "\"\"\"\n    hello\n    world\n\"\"\""
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentIndentedSimpleMultilineString() {
        let input = "{\n\"\"\"\n    hello\n    world\n    \"\"\"\n}"
        let output = "{\n    \"\"\"\n    hello\n    world\n    \"\"\"\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testMultilineStringWithEscapedLinebreak() {
        let input = "\"\"\"\n    hello \\n    world\n\"\"\""
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentMultilineStringWrappedAfter() {
        let input = """
        foo(baz:
            \"\""
            baz
            \"\"")
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentMultilineStringInNestedCalls() {
        let input = """
        foo(bar(\"\""
        baz
        \"\""))
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentMultilineStringInFunctionWithfollowingArgument() {
        let input = """
        foo(bar(\"\""
        baz
        \"\"", quux: 5))
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testReduceIndentForMultilineString() {
        let input = """
        switch foo {
            case bar:
                return \"\""
                baz
                \"\""
        }
        """
        let output = """
        switch foo {
        case bar:
            return \"\""
            baz
            \"\""
        }
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testReduceIndentForMultilineString2() {
        let input = """
            foo(\"\""
            bar
            \"\"")
        """
        let output = """
        foo(\"\""
        bar
        \"\"")
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentMultilineStringWithMultilineInterpolation() {
        let input = """
        func foo() {
            \"\""
                bar
                    \\(bar.map {
                        baz
                    })
                quux
            \"\""
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentMultilineStringWithMultilineNestedInterpolation() {
        let input = """
        func foo() {
            \"\""
                bar
                    \\(bar.map {
                        \"\""
                            quux
                        \"\""
                    })
                quux
            \"\""
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentMultilineStringWithMultilineNestedInterpolation2() {
        let input = """
        func foo() {
            \"\""
                bar
                    \\(bar.map {
                        \"\""
                            quux
                        \"\""
                    }
                    )
                quux
            \"\""
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    // indentStrings = true

    func testIndentMultilineStringInMethod() {
        let input = #"""
        func foo() {
            let sql = """
            SELECT *
            FROM authors
            WHERE authors.name LIKE '%David%'
            """
        }
        """#
        let output = #"""
        func foo() {
            let sql = """
                SELECT *
                FROM authors
                WHERE authors.name LIKE '%David%'
                """
        }
        """#
        let options = FormatOptions(indentStrings: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testNoIndentMultilineStringWithOmittedReturn() {
        let input = #"""
        var string: String {
            """
            SELECT *
            FROM authors
            WHERE authors.name LIKE '%David%'
            """
        }
        """#
        let options = FormatOptions(indentStrings: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testNoIndentMultilineStringOnOwnLineInMethodCall() {
        let input = #"""
        XCTAssertEqual(
            loggingService.assertions,
            """
            My long mutli-line assertion.
            This error was not recoverable.
            """
        )
        """#
        let options = FormatOptions(indentStrings: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIndentMultilineStringInMethodCall() {
        let input = #"""
        XCTAssertEqual(loggingService.assertions, """
        My long mutli-line assertion.
        This error was not recoverable.
        """)
        """#
        let output = #"""
        XCTAssertEqual(loggingService.assertions, """
            My long mutli-line assertion.
            This error was not recoverable.
            """)
        """#
        let options = FormatOptions(indentStrings: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIndentMultilineStringAtTopLevel() {
        let input = #"""
        let sql = """
        SELECT *
        FROM  authors,
              books
        WHERE authors.name LIKE '%David%'
             AND pubdate < $1
        """
        """#
        let output = #"""
        let sql = """
          SELECT *
          FROM  authors,
                books
          WHERE authors.name LIKE '%David%'
               AND pubdate < $1
          """
        """#
        let options = FormatOptions(indent: "  ", indentStrings: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIndentMultilineStringWithBlankLine() {
        let input = #"""
        let generatedClass = """
        import UIKit

        class ViewController: UIViewController { }
        """
        """#

        let output = #"""
        let generatedClass = """
            import UIKit

            class ViewController: UIViewController { }
            """
        """#
        let options = FormatOptions(indentStrings: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIndentMultilineStringPreservesBlankLines() {
        let input = #"""
        let generatedClass = """
            import UIKit

            class ViewController: UIViewController { }
            """
        """#
        let options = FormatOptions(indentStrings: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testUnindentMultilineStringAtTopLevel() {
        let input = #"""
        let sql = """
          SELECT *
          FROM  authors,
                books
          WHERE authors.name LIKE '%David%'
               AND pubdate < $1
          """
        """#
        let output = #"""
        let sql = """
        SELECT *
        FROM  authors,
              books
        WHERE authors.name LIKE '%David%'
             AND pubdate < $1
        """
        """#
        let options = FormatOptions(indent: "  ", indentStrings: false)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    // indent multiline raw strings

    func testIndentIndentedSimpleRawMultilineString() {
        let input = "{\n##\"\"\"\n    hello\n    world\n    \"\"\"##\n}"
        let output = "{\n    ##\"\"\"\n    hello\n    world\n    \"\"\"##\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    // indent multiline regex literals

    func testIndentMultilineRegularExpression() {
        let input = """
        let regex = #/
            (foo+)
            [bar]*
            (baz?)
        /#
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testNoMisindentCasePath() {
        let input = """
        reducer.pullback(
            casePath: /Action.action,
            environment: {}
        )
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    // indent #if/#else/#elseif/#endif (mode: indent)

    func testIfEndifIndenting() {
        let input = "#if x\n// foo\n#endif"
        let output = "#if x\n    // foo\n#endif"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentedIfEndifIndenting() {
        let input = "{\n#if x\n// foo\nfoo()\n#endif\n}"
        let output = "{\n    #if x\n        // foo\n        foo()\n    #endif\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIfElseEndifIndenting() {
        let input = "#if x\n    // foo\nfoo()\n#else\n    // bar\n#endif"
        let output = "#if x\n    // foo\n    foo()\n#else\n    // bar\n#endif"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testEnumIfCaseEndifIndenting() {
        let input = "enum Foo {\ncase bar\n#if x\ncase baz\n#endif\n}"
        let output = "enum Foo {\n    case bar\n    #if x\n        case baz\n    #endif\n}"
        let options = FormatOptions(indentCase: false)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testSwitchIfCaseEndifIndenting() {
        let input = "switch foo {\ncase .bar: break\n#if x\ncase .baz: break\n#endif\n}"
        let output = "switch foo {\ncase .bar: break\n#if x\n    case .baz: break\n#endif\n}"
        let options = FormatOptions(indentCase: false)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testSwitchIfCaseEndifIndenting2() {
        let input = "switch foo {\ncase .bar: break\n#if x\ncase .baz: break\n#endif\n}"
        let output = "switch foo {\n    case .bar: break\n    #if x\n        case .baz: break\n    #endif\n}"
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testSwitchIfCaseEndifIndenting3() {
        let input = "switch foo {\n#if x\ncase .bar: break\ncase .baz: break\n#endif\n}"
        let output = "switch foo {\n#if x\n    case .bar: break\n    case .baz: break\n#endif\n}"
        let options = FormatOptions(indentCase: false)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testSwitchIfCaseEndifIndenting4() {
        let input = "switch foo {\n#if x\ncase .bar:\nbreak\ncase .baz:\nbreak\n#endif\n}"
        let output = "switch foo {\n    #if x\n        case .bar:\n            break\n        case .baz:\n            break\n    #endif\n}"
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testSwitchIfCaseElseCaseEndifIndenting() {
        let input = "switch foo {\n#if x\ncase .bar: break\n#else\ncase .baz: break\n#endif\n}"
        let output = "switch foo {\n#if x\n    case .bar: break\n#else\n    case .baz: break\n#endif\n}"
        let options = FormatOptions(indentCase: false)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testSwitchIfCaseElseCaseEndifIndenting2() {
        let input = "switch foo {\n#if x\ncase .bar: break\n#else\ncase .baz: break\n#endif\n}"
        let output = "switch foo {\n    #if x\n        case .bar: break\n    #else\n        case .baz: break\n    #endif\n}"
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testSwitchIfEndifInsideCaseIndenting() {
        let input = "switch foo {\ncase .bar:\n#if x\nbar()\n#endif\nbaz()\ncase .baz: break\n}"
        let output = "switch foo {\ncase .bar:\n    #if x\n        bar()\n    #endif\n    baz()\ncase .baz: break\n}"
        let options = FormatOptions(indentCase: false)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testSwitchIfEndifInsideCaseIndenting2() {
        let input = "switch foo {\ncase .bar:\n#if x\nbar()\n#endif\nbaz()\ncase .baz: break\n}"
        let output = "switch foo {\n    case .bar:\n        #if x\n            bar()\n        #endif\n        baz()\n    case .baz: break\n}"
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIfUnknownCaseEndifIndenting() {
        let input = """
        switch foo {
        case .bar: break
        #if x
            @unknown case _: break
        #endif
        }
        """
        let options = FormatOptions(indentCase: false, ifdefIndent: .indent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIfUnknownCaseEndifIndenting2() {
        let input = """
        switch foo {
            case .bar: break
            #if x
                @unknown case _: break
            #endif
        }
        """
        let options = FormatOptions(indentCase: true, ifdefIndent: .indent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIfEndifInsideEnumIndenting() {
        let input = """
        enum Foo {
            case bar
            #if x
                case baz
            #endif
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIfEndifInsideEnumWithTrailingCommentIndenting() {
        let input = """
        enum Foo {
            case bar
            #if x
                case baz
            #endif // ends
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testNoIndentCommentBeforeIfdefAroundCase() {
        let input = """
        switch x {
        // foo
        case .foo:
            break
        // conditional
        // bar
        #if BAR
            case .bar:
                break
        // baz
        #else
            case .baz:
                break
        #endif
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testNoIndentCommentedCodeBeforeIfdefAroundCase() {
        let input = """
        func foo() {
        //    foo()
            #if BAR
        //        bar()
            #else
        //        baz()
            #endif
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testNoIndentIfdefFollowedByCommentAroundCase() {
        let input = """
        switch x {
        case .foo:
            break
        #if BAR
            // bar
            case .bar:
                break
        #else
            // baz
            case .baz:
                break
        #endif
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentIfDefPostfixMemberSyntax() {
        let input = """
        class Bar {
            func foo() {
                Text("Hello")
                #if os(iOS)
                .font(.largeTitle)
                #elseif os(macOS)
                        .font(.headline)
                #else
                    .font(.headline)
                #endif
            }
        }
        """
        let output = """
        class Bar {
            func foo() {
                Text("Hello")
                #if os(iOS)
                    .font(.largeTitle)
                #elseif os(macOS)
                    .font(.headline)
                #else
                    .font(.headline)
                #endif
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentIfDefPostfixMemberSyntax2() {
        let input = """
        class Bar {
            func foo() {
                Text("Hello")
                #if os(iOS)
                    .font(.largeTitle)
                #endif
                    .color(.red)
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    // indent #if/#else/#elseif/#endif (mode: noindent)

    func testIfEndifNoIndenting() {
        let input = "#if x\n// foo\n#endif"
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIndentedIfEndifNoIndenting() {
        let input = "{\n#if x\n// foo\n#endif\n}"
        let output = "{\n    #if x\n    // foo\n    #endif\n}"
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIfElseEndifNoIndenting() {
        let input = "#if x\n// foo\n#else\n// bar\n#endif"
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIfCaseEndifNoIndenting() {
        let input = "switch foo {\ncase .bar: break\n#if x\ncase .baz: break\n#endif\n}"
        let options = FormatOptions(indentCase: false, ifdefIndent: .noIndent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIfCaseEndifNoIndenting2() {
        let input = "switch foo {\ncase .bar: break\n#if x\ncase .baz: break\n#endif\n}"
        let output = "switch foo {\n    case .bar: break\n    #if x\n    case .baz: break\n    #endif\n}"
        let options = FormatOptions(indentCase: true, ifdefIndent: .noIndent)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIfUnknownCaseEndifNoIndenting() {
        let input = """
        switch foo {
        case .bar: break
        #if x
        @unknown case _: break
        #endif
        }
        """
        let options = FormatOptions(indentCase: false, ifdefIndent: .noIndent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIfUnknownCaseEndifNoIndenting2() {
        let input = """
        switch foo {
            case .bar: break
            #if x
            @unknown case _: break
            #endif
        }
        """
        let options = FormatOptions(indentCase: true, ifdefIndent: .noIndent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIfEndifInsideCaseNoIndenting() {
        let input = "switch foo {\ncase .bar:\n#if x\nbar()\n#endif\nbaz()\ncase .baz: break\n}"
        let output = "switch foo {\ncase .bar:\n    #if x\n    bar()\n    #endif\n    baz()\ncase .baz: break\n}"
        let options = FormatOptions(indentCase: false, ifdefIndent: .noIndent)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIfEndifInsideCaseNoIndenting2() {
        let input = "switch foo {\ncase .bar:\n#if x\nbar()\n#endif\nbaz()\ncase .baz: break\n}"
        let output = "switch foo {\n    case .bar:\n        #if x\n        bar()\n        #endif\n        baz()\n    case .baz: break\n}"
        let options = FormatOptions(indentCase: true, ifdefIndent: .noIndent)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testSwitchCaseInIfEndif() {
        let input = """
        func baz(value: Example) -> String {
            #if DEBUG
                switch value {
                    case .foo: return "foo"
                    case .bar: return "bar"
                    @unknown default: return "unknown"
                }
            #else
                switch value {
                    case .foo: return "foo"
                    case .bar: return "bar"
                    @unknown default: return "unknown"
                }
            #endif
        }
        """
        let options = FormatOptions(indentCase: true, ifdefIndent: .indent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testSwitchCaseInIfEndifNoIndenting() {
        let input = """
        func baz(value: Example) -> String {
            #if DEBUG
            switch value {
                case .foo: return "foo"
                case .bar: return "bar"
                @unknown default: return "unknown"
            }
            #else
            switch value {
                case .foo: return "foo"
                case .bar: return "bar"
                @unknown default: return "unknown"
            }
            #endif
        }
        """
        let options = FormatOptions(indentCase: true, ifdefIndent: .noIndent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIfEndifInsideEnumNoIndenting() {
        let input = """
        enum Foo {
            case bar
            #if x
            case baz
            #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIfEndifInsideEnumWithTrailingCommentNoIndenting() {
        let input = """
        enum Foo {
            case bar
            #if x
            case baz
            #endif // ends
        }
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIfDefPostfixMemberSyntaxNoIndenting() {
        let input = """
        class Bar {
            func foo() {
                Text("Hello")
                #if os(iOS)
                    .font(.largeTitle)
                #elseif os(macOS)
                    .font(.headline)
                #else
                    .font(.headline)
                #endif
            }
        }
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    // indent #if/#else/#elseif/#endif (mode: outdent)

    func testIfEndifOutdenting() {
        let input = "#if x\n// foo\n#endif"
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIndentedIfEndifOutdenting() {
        let input = "{\n#if x\n// foo\n#endif\n}"
        let output = "{\n#if x\n    // foo\n#endif\n}"
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIfElseEndifOutdenting() {
        let input = "#if x\n// foo\n#else\n// bar\n#endif"
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIndentedIfElseEndifOutdenting() {
        let input = "{\n#if x\n// foo\nfoo()\n#else\n// bar\n#endif\n}"
        let output = "{\n#if x\n    // foo\n    foo()\n#else\n    // bar\n#endif\n}"
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIfElseifEndifOutdenting() {
        let input = "#if x\n// foo\n#elseif y\n// bar\n#endif"
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIndentedIfElseifEndifOutdenting() {
        let input = "{\n#if x\n// foo\nfoo()\n#elseif y\n// bar\n#endif\n}"
        let output = "{\n#if x\n    // foo\n    foo()\n#elseif y\n    // bar\n#endif\n}"
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testNestedIndentedIfElseifEndifOutdenting() {
        let input = "{\n#if x\n#if y\n// foo\nfoo()\n#elseif y\n// bar\n#endif\n#endif\n}"
        let output = "{\n#if x\n#if y\n    // foo\n    foo()\n#elseif y\n    // bar\n#endif\n#endif\n}"
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testDoubleNestedIndentedIfElseifEndifOutdenting() {
        let input = "{\n#if x\n#if y\n#if z\n// foo\nfoo()\n#elseif y\n// bar\n#endif\n#endif\n#endif\n}"
        let output = "{\n#if x\n#if y\n#if z\n    // foo\n    foo()\n#elseif y\n    // bar\n#endif\n#endif\n#endif\n}"
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIfCaseEndifOutdenting() {
        let input = "switch foo {\ncase .bar: break\n#if x\ncase .baz: break\n#endif\n}"
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIfEndifInsideEnumOutdenting() {
        let input = """
        enum Foo {
            case bar
        #if x
            case baz
        #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIfEndifInsideEnumWithTrailingCommentOutdenting() {
        let input = """
        enum Foo {
            case bar
        #if x
            case baz
        #endif // ends
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIfDefPostfixMemberSyntaxOutdenting() {
        let input = """
        class Bar {
            func foo() {
                Text("Hello")
        #if os(iOS)
                    .font(.largeTitle)
        #elseif os(macOS)
                    .font(.headline)
        #else
                    .font(.headline)
        #endif
            }
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    // indent expression after return

    func testIndentIdentifierAfterReturn() {
        let input = "if foo {\n    return\n        bar\n}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentEnumValueAfterReturn() {
        let input = "if foo {\n    return\n        .bar\n}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentMultilineExpressionAfterReturn() {
        let input = "if foo {\n    return\n        bar +\n        baz\n}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testDontIndentClosingBraceAfterReturn() {
        let input = "if foo {\n    return\n}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testDontIndentCaseAfterReturn() {
        let input = "switch foo {\ncase bar:\n    return\ncase baz:\n    return\n}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testDontIndentCaseAfterWhere() {
        let input = "switch foo {\ncase bar\nwhere baz:\nreturn\ndefault:\nreturn\n}"
        let output = "switch foo {\ncase bar\n    where baz:\n    return\ndefault:\n    return\n}"
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testDontIndentIfAfterReturn() {
        let input = "if foo {\n    return\n    if bar {}\n}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testDontIndentFuncAfterReturn() {
        let input = "if foo {\n    return\n    func bar() {}\n}"
        testFormatting(for: input, rule: FormatRules.indent)
    }

    // indent fragments

    func testIndentFragment() {
        let input = "   func foo() {\nbar()\n}"
        let output = "   func foo() {\n       bar()\n   }"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testIndentFragmentAfterBlankLines() {
        let input = "\n\n   func foo() {\nbar()\n}"
        let output = "\n\n   func foo() {\n       bar()\n   }"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testUnterminatedFragment() {
        let input = "class Foo {\n\n  func foo() {\nbar()\n}"
        let output = "class Foo {\n\n    func foo() {\n        bar()\n    }"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options,
                       exclude: ["blankLinesAtStartOfScope"])
    }

    func testOverTerminatedFragment() {
        let input = "   func foo() {\nbar()\n}\n\n}"
        let output = "   func foo() {\n       bar()\n   }\n\n}"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testDontCorruptPartialFragment() {
        let input = "    } foo {\n        bar\n    }\n}"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testDontCorruptPartialFragment2() {
        let input = "        return completionHandler(nil)\n    }\n}"
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    // indent with tabs

    func testTabIndentWrappedTupleWithSmartTabs() {
        let input = """
        let foo = (bar: Int,
                   baz: Int)
        """
        let options = FormatOptions(indent: "\t", tabWidth: 2, smartTabs: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testTabIndentWrappedTupleWithoutSmartTabs() {
        let input = """
        let foo = (bar: Int,
                   baz: Int)
        """
        let output = """
        let foo = (bar: Int,
        \t\t\t\t\t baz: Int)
        """
        let options = FormatOptions(indent: "\t", tabWidth: 2, smartTabs: false)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options)
    }

    func testTabIndentCaseWithSmartTabs() {
        let input = """
        switch x {
        case .foo,
             .bar:
          break
        }
        """
        let output = """
        switch x {
        case .foo,
             .bar:
        \tbreak
        }
        """
        let options = FormatOptions(indent: "\t", tabWidth: 2, smartTabs: true)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options, exclude: ["sortedSwitchCases"])
    }

    func testTabIndentCaseWithoutSmartTabs() {
        let input = """
        switch x {
        case .foo,
             .bar:
          break
        }
        """
        let output = """
        switch x {
        case .foo,
        \t\t .bar:
        \tbreak
        }
        """
        let options = FormatOptions(indent: "\t", tabWidth: 2, smartTabs: false)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options, exclude: ["sortedSwitchCases"])
    }

    func testTabIndentCaseWithoutSmartTabs2() {
        let input = """
        switch x {
            case .foo,
                 .bar:
              break
        }
        """
        let output = """
        switch x {
        \tcase .foo,
        \t\t\t .bar:
        \t\tbreak
        }
        """
        let options = FormatOptions(indent: "\t", indentCase: true,
                                    tabWidth: 2, smartTabs: false)
        testFormatting(for: input, output, rule: FormatRules.indent, options: options, exclude: ["sortedSwitchCases"])
    }

    // indent blank lines

    func testTruncateBlankLineBeforeIndenting() {
        let input = """
        func foo() {
        \tguard bar = baz else { return }
        \t
        \tquux()
        }
        """
        let rules = [FormatRules.indent, FormatRules.trailingSpace]
        let options = FormatOptions(indent: "\t", truncateBlankLines: true, tabWidth: 2)
        XCTAssertEqual(try lint(input, rules: rules, options: options), [
            Formatter.Change(line: 3, rule: FormatRules.trailingSpace, filePath: nil),
        ])
    }

    func testNoIndentBlankLinesIfTrimWhitespaceDisabled() {
        let input = """
        func foo() {
        \tguard bar = baz else { return }
        \t

        \tquux()
        }
        """
        let options = FormatOptions(indent: "\t", truncateBlankLines: false, tabWidth: 2)
        testFormatting(for: input, rule: FormatRules.indent, options: options,
                       exclude: ["consecutiveBlankLines", "wrapConditionalBodies"])
    }

    // async

    func testAsyncThrowsNotUnindented() {
        let input = """
        func multilineFunction(
            foo _: String,
            bar _: String)
            async throws -> String {}
        """
        let options = FormatOptions(closingParenOnSameLine: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }

    func testIndentAsyncLet() {
        let input = """
        func foo() async {
                async let bar = baz()
        async let baz = quux()
        }
        """
        let output = """
        func foo() async {
            async let bar = baz()
            async let baz = quux()
        }
        """
        testFormatting(for: input, output, rule: FormatRules.indent)
    }

    func testIndentAsyncLetAfterLet() {
        let input = """
        func myFunc() {
            let x = 1
            async let foo = bar()
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testIndentAsyncLetAfterBrace() {
        let input = """
        func myFunc() {
            let x = 1
            enum Baz {
                case foo
            }
            async let foo = bar()
        }
        """
        testFormatting(for: input, rule: FormatRules.indent)
    }

    func testAsyncFunctionArgumentLabelNotIndented() {
        let input = """
        func multilineFunction(
            foo _: String,
            async _: String)
            -> String {}
        """
        let options = FormatOptions(closingParenOnSameLine: true)
        testFormatting(for: input, rule: FormatRules.indent, options: options)
    }
}
