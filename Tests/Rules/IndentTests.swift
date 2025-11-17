//
//  IndentTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 8/22/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class IndentTests: XCTestCase {
    func testReduceIndentAtStartOfFile() {
        let input = """
            foo()
        """
        let output = """
        foo()
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testReduceIndentAtEndOfFile() {
        let input = """
        foo()
           bar()
        """
        let output = """
        foo()
        bar()
        """
        testFormatting(for: input, output, rule: .indent)
    }

    // indent parens

    func testSimpleScope() {
        let input = """
        foo(
        bar
        )
        """
        let output = """
        foo(
            bar
        )
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testNestedScope() {
        let input = """
        foo(
        bar {
        }
        )
        """
        let output = """
        foo(
            bar {
            }
        )
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.emptyBraces])
    }

    func testNestedScopeOnSameLine() {
        let input = """
        foo(bar(
        baz
        ))
        """
        let output = """
        foo(bar(
            baz
        ))
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testNestedScopeOnSameLine2() {
        let input = """
        foo(bar(in:
        baz))
        """
        let output = """
        foo(bar(in:
            baz))
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testIndentNestedArrayLiteral() {
        let input = """
        foo(bar: [
        .baz,
        ])
        """
        let output = """
        foo(bar: [
            .baz,
        ])
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testClosingScopeAfterContent() {
        let input = """
        foo(
        bar
        )
        """
        let output = """
        foo(
            bar
        )
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testClosingNestedScopeAfterContent() {
        let input = """
        foo(bar(
        baz
        ))
        """
        let output = """
        foo(bar(
            baz
        ))
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testWrappedFunctionArguments() {
        let input = """
        foo(
        bar,
        baz
        )
        """
        let output = """
        foo(
            bar,
            baz
        )
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testFunctionArgumentsWrappedAfterFirst() {
        let input = """
        func foo(bar: Int,
        baz: Int)
        """
        let output = """
        func foo(bar: Int,
                 baz: Int)
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testIndentPreservedForNestedWrappedParameters() {
        let input = """
        let loginResponse = LoginResponse(status: .success(.init(accessToken: session,
                                                                 status: .enabled)),
                                          invoicingURL: .invoicing,
                                          paymentFormURL: .paymentForm)
        """
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, rule: .indent, options: options, exclude: [.propertyTypes])
    }

    func testIndentPreservedForNestedWrappedParameters2() {
        let input = """
        let loginResponse = LoginResponse(status: .success(.init(accessToken: session,
                                                                 status: .enabled),
                                                           invoicingURL: .invoicing,
                                                           paymentFormURL: .paymentForm))
        """
        let options = FormatOptions(wrapParameters: .preserve)
        testFormatting(for: input, rule: .indent, options: options, exclude: [.propertyTypes])
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
        testFormatting(for: input, rule: .indent, options: options, exclude: [.propertyTypes])
    }

    func testIndentTrailingClosureInParensContainingUnwrappedArguments() {
        let input = """
        let foo = bar(baz {
            quux(foo, bar)
        })
        """
        testFormatting(for: input, rule: .indent)
    }

    func testIndentTrailingClosureInParensContainingWrappedArguments() {
        let input = """
        let foo = bar(baz {
            quux(foo,
                 bar)
        })
        """
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, rule: .indent)
    }

    func testIndentImbalancedNestedClosingParens() {
        let input = """
        Foo(bar:
            Bar(
                baz: quux
            ))
        """
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, rule: .indent)
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
        let options = FormatOptions(closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options)
    }

    // indent modifiers

    func testNoIndentWrappedModifiersForProtocol() {
        let input = """
        @objc
        private
        protocol Foo {}
        """
        testFormatting(for: input, rule: .indent, exclude: [.modifiersOnSameLine])
    }

    // indent braces

    func testElseClauseIndenting() {
        let input = """
        if x {
        bar
        } else {
        baz
        }
        """
        let output = """
        if x {
            bar
        } else {
            baz
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testNoIndentBlankLines() {
        let input = """
        {

        // foo
        }
        """
        let output = """
        {

            // foo
        }
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.blankLinesAtStartOfScope])
    }

    func testNestedBraces() {
        let input = """
        ({
        // foo
        }, {
        // bar
        })
        """
        let output = """
        ({
            // foo
        }, {
            // bar
        })
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testBraceIndentAfterComment() {
        let input = """
        if foo { // comment
        bar
        }
        """
        let output = """
        if foo { // comment
            bar
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testBraceIndentAfterClosingScope() {
        let input = """
        foo(bar(baz), {
        quux
        bleem
        })
        """
        let output = """
        foo(bar(baz), {
            quux
            bleem
        })
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.trailingClosures])
    }

    func testBraceIndentAfterLineWithParens() {
        let input = """
        ({
        foo()
        bar
        })
        """
        let output = """
        ({
            foo()
            bar
        })
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.redundantParens])
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
        testFormatting(for: input, output, rule: .indent)
    }

    func testIndentDoubleParenthesizedClosures() {
        let input = """
        foo(bar: Foo(success: { _ in
            self.bar()
        }, failure: { _ in
            self.baz()
        }))
        """
        testFormatting(for: input, rule: .indent)
    }

    func testIndentUnbalancedBraces() {
        let input = """
        foo(bar()
            .map {
                .baz($0)
            })
        """
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, output, rule: .indent)
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
        testFormatting(for: input, rule: .indent, exclude: [.wrapArguments])
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
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, rule: .indent, exclude: [.propertyTypes])
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
        testFormatting(for: input, rule: .indent)
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
        let options = FormatOptions(closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options, exclude: [.propertyTypes])
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
        testFormatting(for: input, rule: .indent, options: options, exclude: [.propertyTypes])
    }

    func testIndentAllmanTrailingClosureArguments2() {
        let input = """
        DispatchQueue.main.async
        {
            foo()
        }
        """
        let options = FormatOptions(allmanBraces: true)
        testFormatting(for: input, rule: .indent, options: options)
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
        testFormatting(for: input, rule: .indent, options: options,
                       exclude: [.redundantReturn])
    }

    func testNoDoubleIndentClosureArguments() {
        let input = """
        let foo = foo(bar(
            { baz },
            { quux }
        ))
        """
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, rule: .indent,
                       exclude: [.braces, .wrapMultilineStatementBraces, .redundantProperty])
    }

    func testIndentLineAfterIndentedInlineClosure() {
        let input = """
        func foo(for bar: String) -> UIViewController {
            let viewController = foo(Builder().build(
                bar: bar)) { _ in ViewController() }

            return viewController
        }
        """
        testFormatting(for: input, rule: .indent, exclude: [.redundantProperty])
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
        testFormatting(for: input, rule: .indent, exclude: [.redundantProperty])
    }

    func testIndentMultilineStatementDoesntFailToTerminate() {
        let input = """
        foo(one: 1,
            two: 2).bar { _ in
            "one"
        }
        """
        let options = FormatOptions(wrapArguments: .afterFirst, closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options)
    }

    // indent switch/case

    func testSwitchCaseIndenting() {
        let input = """
        switch x {
        case foo:
        break
        case bar:
        break
        default:
        break
        }
        """
        let output = """
        switch x {
        case foo:
            break
        case bar:
            break
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testSwitchWrappedCaseIndenting() {
        let input = """
        switch x {
        case foo,
        bar,
            baz:
            break
        default:
            break
        }
        """
        let output = """
        switch x {
        case foo,
             bar,
             baz:
            break
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.sortSwitchCases])
    }

    func testSwitchWrappedEnumCaseIndenting() {
        let input = """
        switch x {
        case .foo,
        .bar,
            .baz:
            break
        default:
            break
        }
        """
        let output = """
        switch x {
        case .foo,
             .bar,
             .baz:
            break
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.sortSwitchCases])
    }

    func testSwitchWrappedEnumCaseIndentingVariant2() {
        let input = """
        switch x {
        case
        .foo,
        .bar,
            .baz:
            break
        default:
            break
        }
        """
        let output = """
        switch x {
        case
            .foo,
            .bar,
            .baz:
            break
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.sortSwitchCases])
    }

    func testSwitchWrappedEnumCaseIsIndenting() {
        let input = """
        switch x {
        case is Foo.Type,
            is Bar.Type:
            break
        default:
            break
        }
        """
        let output = """
        switch x {
        case is Foo.Type,
             is Bar.Type:
            break
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.sortSwitchCases])
    }

    func testSwitchCaseIsDictionaryIndenting() {
        let input = """
        switch x {
        case foo is [Key: Value]:
        fallthrough
        default:
        break
        }
        """
        let output = """
        switch x {
        case foo is [Key: Value]:
            fallthrough
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testEnumCaseIndenting() {
        let input = """
        enum Foo {
        case Bar
        case Baz
        }
        """
        let output = """
        enum Foo {
            case Bar
            case Baz
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testEnumCaseIndentingCommas() {
        let input = """
        enum Foo {
        case Bar,
        Baz
        }
        """
        let output = """
        enum Foo {
            case Bar,
                 Baz
        }
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.wrapEnumCases])
    }

    func testGenericEnumCaseIndenting() {
        let input = """
        enum Foo<T> {
        case Bar
        case Baz
        }
        """
        let output = """
        enum Foo<T> {
            case Bar
            case Baz
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testIndentSwitchAfterRangeCase() {
        let input = """
        switch x {
        case 0 ..< 2:
            switch y {
            default:
                break
            }
        default:
            break
        }
        """
        testFormatting(for: input, rule: .indent, exclude: [.blankLineAfterSwitchCase])
    }

    func testIndentEnumDeclarationInsideSwitchCase() {
        let input = """
        switch x {
        case y:
        enum Foo {
        case z
        }
        bar()
        default: break
        }
        """
        let output = """
        switch x {
        case y:
            enum Foo {
                case z
            }
            bar()
        default: break
        }
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.blankLineAfterSwitchCase])
    }

    func testIndentEnumCaseBodyAfterWhereClause() {
        let input = """
        switch foo {
        case _ where baz < quux:
            print(1)
            print(2)
        default:
            break
        }
        """
        testFormatting(for: input, rule: .indent, exclude: [.blankLineAfterSwitchCase])
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
        testFormatting(for: input, output, rule: .indent, exclude: [.blankLineAfterSwitchCase])
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
        testFormatting(for: input, output, rule: .indent)
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
        testFormatting(for: input, output, rule: .indent)
    }

    func testIndentMultipleSingleLineSwitchCaseCommentsCorrectly() {
        let input = """
        switch x {
        // comment 1
        // comment 2
        case y:
        // comment
        break
        }
        """
        let output = """
        switch x {
        // comment 1
        // comment 2
        case y:
            // comment
            break
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testIndentIfCase() {
        let input = """
        {
        if case let .foo(msg) = error {}
        }
        """
        let output = """
        {
            if case let .foo(msg) = error {}
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testIndentGuardCase() {
        let input = """
        {
        guard case .Foo = error else {}
        }
        """
        let output = """
        {
            guard case .Foo = error else {}
        }
        """
        testFormatting(for: input, output, rule: .indent,
                       exclude: [.wrapConditionalBodies])
    }

    func testIndentIfElse() {
        let input = """
        if foo {
        } else if let bar = baz,
                  let baz = quux {}
        """
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, rule: .indent)
    }

    func testIndentIfCaseLet() {
        let input = """
        if case let foo = foo,
           let bar = bar {}
        """
        testFormatting(for: input, rule: .indent)
    }

    func testIndentMultipleIfLet() {
        let input = """
        if let foo = foo, let bar = bar,
           let baz = baz {}
        """
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, output, rule: .indent)
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
        testFormatting(for: input, output, rule: .indent)
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
        testFormatting(for: input, output, rule: .indent)
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
        testFormatting(for: input, output, rule: .indent)
    }

    func testWrappedClassDeclaration() {
        let input = """
        class Foo: Bar,
            Baz {
            init() {}
        }
        """
        testFormatting(for: input, rule: .indent,
                       exclude: [.wrapMultilineStatementBraces])
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
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testWrappedClassDeclarationWithBracesOnSameLineLikeXcode() {
        let input = """
        class Foo: Bar,
        Baz {}
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: .indent, options: options)
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
        testFormatting(for: input, rule: .indent, options: options)
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
        testFormatting(for: input, output, rule: .indent, options: options, exclude: [.simplifyGenericConstraints])
    }

    func testIndentSwitchCaseDo() {
        let input = """
        switch foo {
        case .bar: do {
                baz()
            }
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    // indentCase = true

    func testSwitchCaseWithIndentCaseTrue() {
        let input = """
        switch x {
        case foo:
        break
        case bar:
        break
        default:
        break
        }
        """
        let output = """
        switch x {
            case foo:
                break
            case bar:
                break
            default:
                break
        }
        """
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testSwitchWrappedEnumCaseWithIndentCaseTrue() {
        let input = """
        switch x {
        case .foo,
        .bar,
            .baz:
            break
        default:
            break
        }
        """
        let output = """
        switch x {
            case .foo,
                 .bar,
                 .baz:
                break
            default:
                break
        }
        """
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: .indent, options: options, exclude: [.sortSwitchCases])
    }

    func testIndentMultilineSwitchCaseCommentsWithIndentCaseTrue() {
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
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testNoMangleLabelWhenIndentCaseTrue() {
        let input = """
        foo: while true {
            break foo
        }
        """
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, rule: .indent, options: options)
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
        testFormatting(for: input, rule: .indent, options: options)
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
        testFormatting(for: input, output, rule: .indent, options: options)
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
        testFormatting(for: input, output, rule: .indent, options: options)
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
        testFormatting(for: input, rule: .indent, options: options)
    }

    // indent wrapped lines

    func testWrappedLineAfterOperator() {
        let input = """
        if x {
        let y = foo +
        bar
        }
        """
        let output = """
        if x {
            let y = foo +
                bar
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testWrappedLineAfterComma() {
        let input = """
        let a = b,
        b = c
        """
        let output = """
        let a = b,
            b = c
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.singlePropertyPerLine])
    }

    func testWrappedBeforeComma() {
        let input = """
        let a = b
        , b = c
        """
        let output = """
        let a = b
            , b = c
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.leadingDelimiters, .singlePropertyPerLine])
    }

    func testWrappedLineAfterCommaInsideArray() {
        let input = """
        [
        foo,
        bar,
        ]
        """
        let output = """
        [
            foo,
            bar,
        ]
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testWrappedLineBeforeCommaInsideArray() {
        let input = """
        [
        foo
        , bar,
        ]
        """
        let output = """
        [
            foo
            , bar,
        ]
        """
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, output, rule: .indent, options: options,
                       exclude: [.leadingDelimiters])
    }

    func testWrappedLineAfterCommaInsideInlineArray() {
        let input = """
        [foo,
        bar]
        """
        let output = """
        [foo,
         bar]
        """
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testWrappedLineBeforeCommaInsideInlineArray() {
        let input = """
        [foo
        , bar]
        """
        let output = """
        [foo
         , bar]
        """
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, output, rule: .indent, options: options,
                       exclude: [.leadingDelimiters])
    }

    func testWrappedLineAfterColonInFunction() {
        let input = """
        func foo(bar:
        baz)
        """
        let output = """
        func foo(bar:
            baz)
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testNoDoubleIndentOfWrapAfterAsAfterOpenScope() {
        let input = """
        (foo as
        Bar)
        """
        let output = """
        (foo as
            Bar)
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.redundantParens])
    }

    func testNoDoubleIndentOfWrapBeforeAsAfterOpenScope() {
        let input = """
        (foo
        as Bar)
        """
        let output = """
        (foo
            as Bar)
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.redundantParens])
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
        testFormatting(for: input, output, rule: .indent, exclude: [.redundantParens])
    }

    func testNoDoubleIndentWhenScopesSeparatedByWrap() {
        let input = """
        (foo
        as Bar {
        baz
        }
        )
        """
        let output = """
        (foo
            as Bar {
                baz
            }
        )
        """
        testFormatting(for: input, output, rule: .indent,
                       exclude: [.wrapArguments, .redundantParens])
    }

    func testNoPermanentReductionInScopeAfterWrap() {
        let input = """
        { foo
        as Bar
        let baz = 5
        }
        """
        let output = """
        { foo
            as Bar
            let baz = 5
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testWrappedLineBeforeOperator() {
        let input = """
        if x {
        let y = foo
        + bar
        }
        """
        let output = """
        if x {
            let y = foo
                + bar
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testWrappedLineBeforeIsOperator() {
        let input = """
        if x {
        let y = foo
        is Bar
        }
        """
        let output = """
        if x {
            let y = foo
                is Bar
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testWrappedLineAfterForKeyword() {
        let input = """
        for
        i in range {}
        """
        let output = """
        for
            i in range {}
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testWrappedLineAfterInKeyword() {
        let input = """
        for i in
        range {}
        """
        let output = """
        for i in
            range {}
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testWrappedLineAfterDot() {
        let input = """
        let foo = bar.
        baz
        """
        let output = """
        let foo = bar.
            baz
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testWrappedLineBeforeDot() {
        let input = """
        let foo = bar
        .baz
        """
        let output = """
        let foo = bar
            .baz
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testWrappedLineBeforeWhere() {
        let input = """
        let foo = bar
        where foo == baz
        """
        let output = """
        let foo = bar
            where foo == baz
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testWrappedLineAfterWhere() {
        let input = """
        let foo = bar where
        foo == baz
        """
        let output = """
        let foo = bar where
            foo == baz
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testWrappedLineBeforeGuardElse() {
        let input = """
        guard let foo = bar
        else { return }
        """
        testFormatting(for: input, rule: .indent,
                       exclude: [.wrapConditionalBodies])
    }

    func testWrappedLineAfterGuardElse() {
        // Don't indent because this case is handled by braces rule
        let input = """
        guard let foo = bar else
        { return }
        """
        testFormatting(for: input, rule: .indent,
                       exclude: [.elseOnSameLine, .wrapConditionalBodies])
    }

    func testWrappedLineAfterComment() {
        let input = """
        foo = bar && // comment
        baz
        """
        let output = """
        foo = bar && // comment
            baz
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testWrappedLineInClosure() {
        let input = """
        forEach { item in
        print(item)
        }
        """
        let output = """
        forEach { item in
            print(item)
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testWrappedGuardInClosure() {
        let input = """
        forEach { foo in
            guard let foo = foo,
                  let bar = bar else { break }
        }
        """
        testFormatting(for: input, rule: .indent,
                       exclude: [.wrapMultilineStatementBraces, .wrapConditionalBodies])
    }

    func testConsecutiveWraps() {
        let input = """
        let a = b +
        c +
        d
        """
        let output = """
        let a = b +
            c +
            d
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testWrapReset() {
        let input = """
        let a = b +
        c +
        d
        let a = b +
        c +
        d
        """
        let output = """
        let a = b +
            c +
            d
        let a = b +
            c +
            d
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testIndentElseAfterComment() {
        let input = """
        if x {}
        // comment
        else {}
        """
        testFormatting(for: input, rule: .indent)
    }

    func testWrappedLinesWithComments() {
        let input = """
        let foo = bar ||
         // baz||
        quux
        """
        let output = """
        let foo = bar ||
            // baz||
            quux
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testNoIndentAfterAssignOperatorToVariable() {
        let input = """
        let greaterThan = >
        let lessThan = <
        """
        testFormatting(for: input, rule: .indent)
    }

    func testNoIndentAfterDefaultAsIdentifier() {
        let input = """
        let foo = FileManager.default
        /// Comment
        let bar = 0
        """
        testFormatting(for: input, rule: .indent, exclude: [.propertyTypes])
    }

    func testIndentClosureStartingOnIndentedLine() {
        let input = """
        foo
        .bar {
        baz()
        }
        """
        let output = """
        foo
            .bar {
                baz()
            }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testIndentClosureStartingOnIndentedLineInVar() {
        let input = """
        var foo = foo
        .bar {
        baz()
        }
        """
        let output = """
        var foo = foo
            .bar {
                baz()
            }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testIndentClosureStartingOnIndentedLineInLet() {
        let input = """
        let foo = foo
        .bar {
        baz()
        }
        """
        let output = """
        let foo = foo
            .bar {
                baz()
            }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testIndentClosureStartingOnIndentedLineInTypedVar() {
        let input = """
        var: Int foo = foo
        .bar {
        baz()
        }
        """
        let output = """
        var: Int foo = foo
            .bar {
                baz()
            }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testIndentClosureStartingOnIndentedLineInTypedLet() {
        let input = """
        let: Int foo = foo
        .bar {
        baz()
        }
        """
        let output = """
        let: Int foo = foo
            .bar {
                baz()
            }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testNestedWrappedIfIndents() {
        let input = """
        if foo {
        if bar &&
        (baz ||
        quux) {
        foo()
        }
        }
        """
        let output = """
        if foo {
            if bar &&
                (baz ||
                    quux) {
                foo()
            }
        }
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.andOperator, .wrapMultilineStatementBraces])
    }

    func testWrappedEnumThatLooksLikeIf() {
        let input = """
        foo &&
         bar.if {
        foo()
        }
        """
        let output = """
        foo &&
            bar.if {
                foo()
            }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testChainedClosureIndents() {
        let input = """
        foo
        .bar {
        baz()
        }
        .bar {
        baz()
        }
        """
        let output = """
        foo
            .bar {
                baz()
            }
            .bar {
                baz()
            }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testChainedClosureIndentsAfterIfCondition() {
        let input = """
        if foo {
        bar()
        .baz()
        }

        foo
        .bar {
        baz()
        }
        .bar {
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
            }
            .bar {
                baz()
            }
        """
        testFormatting(for: input, output, rule: .indent)
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
        testFormatting(for: input, output, rule: .indent, exclude: [.wrapMultilineFunctionChains])
    }

    func testChainedClosureIndentsAfterVarDeclaration() {
        let input = """
        var foo: Int
        foo
        .bar {
        baz()
        }
        .bar {
        baz()
        }
        """
        let output = """
        var foo: Int
        foo
            .bar {
                baz()
            }
            .bar {
                baz()
            }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testChainedClosureIndentsAfterLetDeclaration() {
        let input = """
        let foo: Int
        foo
        .bar {
        baz()
        }
        .bar {
        baz()
        }
        """
        let output = """
        let foo: Int
        foo
            .bar {
                baz()
            }
            .bar {
                baz()
            }
        """
        testFormatting(for: input, output, rule: .indent)
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
        testFormatting(for: input, rule: .indent, options: options,
                       exclude: [.blankLinesBetweenScopes])
    }

    func testChainedFunctionIndents() {
        let input = """
        Button(action: {
            print("foo")
        })
        .buttonStyle(bar())
        """
        testFormatting(for: input, rule: .indent)
    }

    func testChainedFunctionIndentWithXcodeIndentation() {
        let input = """
        Button(action: {
            print("foo")
        })
        .buttonStyle(bar())
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testWrappedClosureIndentAfterAssignment() {
        let input = """
        let bar =
            baz { _ in
                print("baz")
            }
        """
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, output, rule: .indent)
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
        testFormatting(for: input, output, rule: .indent)
    }

    func testChainedFunctionsInsideIf() {
        let input = """
        if foo {
        return bar()
        .baz()
        }
        """
        let output = """
        if foo {
            return bar()
                .baz()
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testChainedFunctionsInsideForLoop() {
        let input = """
        for x in y {
        foo
        .bar {
        baz()
        }
        .quux()
        }
        """
        let output = """
        for x in y {
            foo
                .bar {
                    baz()
                }
                .quux()
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testChainedFunctionsAfterAnIfStatement() {
        let input = """
        if foo {}
        bar
        .baz {
        }
        .quux()
        """
        let output = """
        if foo {}
        bar
            .baz {
            }
            .quux()
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.emptyBraces])
    }

    func testIndentInsideWrappedIfStatementWithClosureCondition() {
        let input = """
        if foo({ 1 }) ||
        bar {
        baz()
        }
        """
        let output = """
        if foo({ 1 }) ||
            bar {
            baz()
        }
        """
        testFormatting(for: input, output, rule: .indent, exclude: [.wrapMultilineStatementBraces])
    }

    func testIndentInsideWrappedClassDefinition() {
        let input = """
        class Foo
        : Bar {
        baz()
        }
        """
        let output = """
        class Foo
            : Bar {
            baz()
        }
        """
        testFormatting(for: input, output, rule: .indent,
                       exclude: [.leadingDelimiters, .wrapMultilineStatementBraces])
    }

    func testIndentInsideWrappedProtocolDefinition() {
        let input = """
        protocol Foo
        : Bar, Baz {
        baz()
        }
        """
        let output = """
        protocol Foo
            : Bar, Baz {
            baz()
        }
        """
        testFormatting(for: input, output, rule: .indent,
                       exclude: [.leadingDelimiters, .wrapMultilineStatementBraces])
    }

    func testIndentInsideWrappedVarStatement() {
        let input = """
        var Foo:
        Bar {
        return 5
        }
        """
        let output = """
        var Foo:
            Bar {
            return 5
        }
        """
        testFormatting(for: input, output, rule: .indent,
                       exclude: [.wrapMultilineStatementBraces])
    }

    func testNoIndentAfterOperatorDeclaration() {
        let input = """
        infix operator ?=
        func ?= (lhs _: Int, rhs _: Int) -> Bool {}
        """
        testFormatting(for: input, rule: .indent)
    }

    func testNoIndentAfterChevronOperatorDeclaration() {
        let input = """
        infix operator =<<
        func =<< <T>(lhs _: T, rhs _: T) -> T {}
        """
        testFormatting(for: input, rule: .indent)
    }

    func testIndentWrappedStringDictionaryKeysAndValues() {
        let input = """
        [
        \"foo\":
        \"bar\",
        \"baz\":
        \"quux\",
        ]
        """
        let output = """
        [
            \"foo\":
                \"bar\",
            \"baz\":
                \"quux\",
        ]
        """
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testIndentWrappedEnumDictionaryKeysAndValues() {
        let input = """
        [
        .foo:
        .bar,
        .baz:
        .quux,
        ]
        """
        let output = """
        [
            .foo:
                .bar,
            .baz:
                .quux,
        ]
        """
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testIndentWrappedFunctionArgument() {
        let input = """
        foobar(baz: a &&
        b)
        """
        let output = """
        foobar(baz: a &&
            b)
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testIndentWrappedFunctionClosureArgument() {
        let input = """
        foobar(baz: { a &&
        b })
        """
        let output = """
        foobar(baz: { a &&
                b })
        """
        testFormatting(for: input, output, rule: .indent,
                       exclude: [.trailingClosures, .braces])
    }

    func testIndentWrappedFunctionWithClosureArgument() {
        let input = """
        foo(bar: { bar in
                bar()
            },
            baz: baz)
        """
        let options = FormatOptions(closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testIndentClassDeclarationContainingComment() {
        let input = """
        class Foo: Bar,
            // Comment
            Baz {}
        """
        testFormatting(for: input, rule: .indent)
    }

    func testWrappedLineAfterTypeAttribute() {
        let input = """
        let f: @convention(swift)
            (Int) -> Int = { x in x }
        """
        testFormatting(for: input, rule: .indent)
    }

    func testWrappedLineAfterTypeAttribute2() {
        let input = """
        func foo(_: @escaping
            (Int) -> Int) {}
        """
        testFormatting(for: input, rule: .indent)
    }

    func testWrappedLineAfterNonTypeAttribute() {
        let input = """
        @discardableResult
        func foo() -> Int { 5 }
        """
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, rule: .indent)
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
        let options = FormatOptions(wrapArguments: .disabled, closingParenPosition: .balanced)
        testFormatting(for: input, rule: .indent, options: options,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
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
        let options = FormatOptions(wrapArguments: .disabled, closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options,
                       exclude: [.wrapConditionalBodies, .wrapMultilineStatementBraces, .blankLinesAfterGuardStatements])
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
        let options = FormatOptions(wrapArguments: .disabled, closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options,
                       exclude: [.wrapConditionalBodies, .wrapMultilineStatementBraces, .blankLinesAfterGuardStatements])
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
        let options = FormatOptions(wrapArguments: .disabled, closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options,
                       exclude: [.wrapMultilineStatementBraces])
    }

    func testIndentTrailingClosureAfterChainedMethodCall() {
        let input = """
        Foo()
            .bar(
                baaz: baaz,
                quux: quux)
            {
                print("Trailing closure")
            }
            .methodCallAfterTrailingClosure()

        Foo().bar(baaz: baaz, quux, quux) {
            print("Trailing closure")
        }
        """

        let options = FormatOptions(closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testIndentNonTrailingClosureAfterChainedMethodCall() {
        let input = """
        Foo()
            .bar(
                baaz: baaz,
                quux: quux,
                closure: {
                    print("Trailing closure")
                })

        Foo().bar(baaz: baaz, quux, quux, closure: {
            print("Trailing closure")
        })
        """

        let options = FormatOptions(closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testIndentTrailingClosureAfterNonChainedMethodCall() {
        let input = """
        Foo(
            baaz: baaz,
            quux: quux)
        {
            print("Trailing closure")
        }
        .methodCallAfterTrailingClosure()

        Foo().bar(baaz: baaz, quux, quux, closure: {
            print("Trailing closure")
        })
        """

        let options = FormatOptions(closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testNoDoubleIndentTrailingClosureBodyIfLineStartsWithClosingBrace() {
        let input = """
        let alert = Foo.alert(buttonCallback: {
            okBlock()
        }, cancelButtonTitle: cancelTitle) {
            cancelBlock()
        }
        """
        let options = FormatOptions(wrapArguments: .disabled, closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options, exclude: [.propertyTypes])
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
        let options = FormatOptions(wrapArguments: .disabled, closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options,
                       exclude: [.braces, .wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testSingleIndentTrailingClosureBodyOfShortMethod() {
        let input = """
        method(withParameter: 1) { [weak self] in
            guard let error = error else { return }
            print("and a trailing closure")
        }
        """
        let options = FormatOptions(wrapArguments: .disabled, closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testNoDoubleIndentInInsideClosure() {
        let input = """
        let foo = bar({ baz
            in
            baz
        })
        """
        testFormatting(for: input, rule: .indent,
                       exclude: [.trailingClosures])
    }

    func testNoDoubleIndentInInsideClosure2() {
        let input = """
        foo(where: { _ in
            bar()
        }) { _ in
            print("and a trailing closure")
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    func testNoDoubleIndentInInsideClosure3() {
        let input = """
        foo {
            [weak self] _ in
            self?.bar()
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    func testNoDoubleIndentInInsideClosure4() {
        let input = """
        foo {
            (baz: Int) in
            self?.bar(baz)
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    func testNoDoubleIndentInInsideClosure5() {
        let input = """
        foo { [weak self] bar in
            for baz in bar {
                self?.print(baz)
            }
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    func testNoDoubleIndentInInsideClosure6() {
        let input = """
        foo { (bar: [Int]) in
            for baz in bar {
                print(baz)
            }
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    func testNoDoubleIndentForInInsideFunction() {
        let input = """
        func foo() { // comment here
            for idx in 0 ..< 100 {
                print(idx)
            }
        }
        """
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, rule: .indent,
                       exclude: [.wrapArguments, .wrapMultilineStatementBraces])
    }

    func testIndentChainedPropertiesAfterFunctionCall() {
        let input = """
        let foo = Foo(
            bar: baz
        )
        .bar
        .baz
        """
        testFormatting(for: input, rule: .indent, exclude: [.propertyTypes])
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
        testFormatting(for: input, rule: .indent, options: options, exclude: [.propertyTypes])
    }

    func testIndentChainedPropertiesAfterFunctionCall2() {
        let input = """
        let foo = Foo({
            print("")
        })
        .bar
        .baz
        """
        testFormatting(for: input, rule: .indent,
                       exclude: [.trailingClosures, .propertyTypes])
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
        testFormatting(for: input, rule: .indent, options: options,
                       exclude: [.trailingClosures, .propertyTypes])
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
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, rule: .indent, options: options)
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
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, rule: .indent, options: options)
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
        testFormatting(for: input, output, rule: .indent, options: options)
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
        testFormatting(for: input, rule: .indent, options: options)
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
        testFormatting(for: input, rule: .indent, options: options)
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
        testFormatting(for: input, output, rule: .indent, options: options)
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
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testChainedFunctionInGuardIndentation() {
        let input = """
        guard
            let baz = foo
            .bar
            .baz
        else { return }
        """
        testFormatting(for: input, rule: .indent,
                       exclude: [.wrapConditionalBodies])
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
        testFormatting(for: input, output, rule: .indent,
                       options: options, exclude: [.wrapConditionalBodies])
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
        testFormatting(for: input, rule: .indent,
                       exclude: [.wrapConditionalBodies])
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
        testFormatting(for: input, output, rule: .indent,
                       options: options, exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
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
        testFormatting(for: input, rule: .indent)
    }

    func testConditionalInitArgumentIndentAfterBrace() {
        let input = """
        struct Foo: Codable {
            let value: String
            let number: Int

            enum CodingKeys: String, CodingKey {
                case value
                case number
            }

            #if DEBUG
                init(
                    value: String,
                    number: Int
                ) {
                    self.value = value
                    self.number = number
                }
            #endif
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    func testConditionalInitArgumentIndentAfterBraceNoIndent() {
        let input = """
        struct Foo: Codable {
            let value: String
            let number: Int

            enum CodingKeys: String, CodingKey {
                case value
                case number
            }

            #if DEBUG
            init(
                value: String,
                number: Int
            ) {
                self.value = value
                self.number = number
            }
            #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testConditionalCompiledWrappedChainedFunctionIndent() {
        let input = """
        var body: some View {
            VStack {
                // some view
            }
            #if os(macOS)
                .frame(minWidth: 200)
            #elseif os(macOS)
                    .frame(minWidth: 150)
            #else
                        .frame(minWidth: 0)
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
            #elseif os(macOS)
            .frame(minWidth: 150)
            #else
            .frame(minWidth: 0)
            #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .indent)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testConditionalCompiledWrappedChainedFunctionIndent2() {
        let input = """
        var body: some View {
            Text(
                "Hello"
            )
            #if os(macOS)
                .frame(minWidth: 200)
            #elseif os(macOS)
                    .frame(minWidth: 150)
            #else
                        .frame(minWidth: 0)
            #endif
        }
        """
        let output = """
        var body: some View {
            Text(
                "Hello"
            )
            #if os(macOS)
            .frame(minWidth: 200)
            #elseif os(macOS)
            .frame(minWidth: 150)
            #else
            .frame(minWidth: 0)
            #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .indent)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testConditionalCompiledWrappedChainedFunctionWithIfdefNoIndent() {
        let input = """
        var body: some View {
            VStack {
                // some view
            }
            #if os(macOS)
                .frame(minWidth: 200)
            #elseif os(macOS)
                    .frame(minWidth: 150)
            #else
                        .frame(minWidth: 0)
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
            #elseif os(macOS)
            .frame(minWidth: 150)
            #else
            .frame(minWidth: 0)
            #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testConditionalCompiledWrappedChainedFunctionWithIfdefOutdent() {
        let input = """
        var body: some View {
            VStack {
                // some view
            }
        #if os(macOS)
        .frame(minWidth: 200)
        #elseif os(macOS)
                .frame(minWidth: 150)
        #else
                    .frame(minWidth: 0)
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
        #elseif os(macOS)
            .frame(minWidth: 150)
        #else
            .frame(minWidth: 0)
        #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, output, rule: .indent, options: options)
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
        testFormatting(for: input, output, rule: .indent)
    }

    func testWrappedSingleLineClosureOnNewLine() {
        let input = """
        func foo() {
            let bar =
                { print("foo") }
        }
        """
        testFormatting(for: input, rule: .indent, exclude: [.braces])
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
        testFormatting(for: input, rule: .indent, exclude: [.braces])
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
        testFormatting(for: input, rule: .indent, options: options,
                       exclude: [.braces])
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
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testWrappedExpressionIndentAfterTryInClosure() {
        let input = """
        getter = { in
            try foo ??
                bar
        }
        """
        let options = FormatOptions(xcodeIndentation: true)
        testFormatting(for: input, rule: .indent, options: options)
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
        testFormatting(for: input, rule: .indent, exclude: [.hoistTry])
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
        testFormatting(for: input, rule: .indent)
    }

    func testIndentLabelledTrailingClosure() {
        let input = """
        var buttonLabel: some View {
            label()
                .if(isInline) {
                    $0.font(.hsBody)
                }
                else: {
                    $0.font(.hsControl)
                }
        }
        """
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, rule: .indent)
    }

    // indent comments

    func testCommentIndenting() {
        let input = """
        /* foo
        bar */
        """
        let output = """
        /* foo
         bar */
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testCommentIndentingWithTrailingClose() {
        let input = """
        /*
        foo
        */
        """
        let output = """
        /*
         foo
         */
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testCommentIndentingWithTrailingClose2() {
        let input = """
        /* foo
        */
        """
        let output = """
        /* foo
         */
        """
        testFormatting(for: input, output, rule: .indent)
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
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, output, rule: .indent)
    }

    func testCommentedCodeBlocksNotIndented() {
        let input = """
        func foo() {
        //    var foo: Int
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    func testBlankCodeCommentBlockLinesNotIndented() {
        let input = """
        func foo() {
        //
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    func testCommentedCodeAfterBracketNotIndented() {
        let input = """
        let foo = [
        //    first,
            second,
        ]
        """
        testFormatting(for: input, rule: .indent)
    }

    func testCommentedCodeAfterBracketNotIndented2() {
        let input = """
        let foo = [first,
        //           second,
                   third]
        """
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, output, rule: .indent)
    }

    // indent multiline strings

    func testSimpleMultilineString() {
        let input = """
        \"\"\"
            hello
            world
        \"\"\"
        """
        testFormatting(for: input, rule: .indent)
    }

    func testIndentIndentedSimpleMultilineString() {
        let input = """
        {
        \"\"\"
            hello
            world
            \"\"\"
        }
        """
        let output = """
        {
            \"\"\"
            hello
            world
            \"\"\"
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testMultilineStringWithEscapedLinebreak() {
        let input = """
        \"\"\"
            hello \
            world
        \"\"\"
        """
        testFormatting(for: input, rule: .indent)
    }

    func testIndentMultilineStringWrappedAfter() {
        let input = """
        foo(baz:
            \"\""
            baz
            \"\"")
        """
        testFormatting(for: input, rule: .indent)
    }

    func testIndentMultilineStringInNestedCalls() {
        let input = """
        foo(bar(\"\""
        baz
        \"\""))
        """
        testFormatting(for: input, rule: .indent)
    }

    func testIndentMultilineStringInFunctionWithfollowingArgument() {
        let input = """
        foo(bar(\"\""
        baz
        \"\"", quux: 5))
        """
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, output, rule: .indent)
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
        testFormatting(for: input, output, rule: .indent)
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
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, output, rule: .indent, options: options)
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
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testNoIndentMultilineStringOnOwnLineInMethodCall() {
        let input = #"""
        XCTAssertEqual(
            loggingService.assertions,
            """
            My long multi-line assertion.
            This error was not recoverable.
            """
        )
        """#
        let options = FormatOptions(indentStrings: true)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testIndentMultilineStringInMethodCall() {
        let input = #"""
        XCTAssertEqual(loggingService.assertions, """
        My long multi-line assertion.
        This error was not recoverable.
        """)
        """#
        let output = #"""
        XCTAssertEqual(loggingService.assertions, """
            My long multi-line assertion.
            This error was not recoverable.
            """)
        """#
        let options = FormatOptions(indentStrings: true)
        testFormatting(for: input, output, rule: .indent, options: options)
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
        testFormatting(for: input, output, rule: .indent, options: options)
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
        \#("    ")
            class ViewController: UIViewController { }
            """
        """#
        let options = FormatOptions(truncateBlankLines: false, indentStrings: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testIndentMultilineStringPreservesBlankLines() {
        let input = #"""
        let generatedClass = """
            import UIKit
        \#("    ")
            class ViewController: UIViewController { }
            """
        """#
        let options = FormatOptions(truncateBlankLines: false, indentStrings: true)
        testFormatting(for: input, rule: .indent, options: options)
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
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testIndentUnderIndentedMultilineStringPreservesBlankLineIndent() {
        let input = #"""
        class Main {
            func main() {
                print("""
            That've been not indented at all.
            \#n\#  
            After SwiftFormat it causes a compiler error in the line above.
            """)
            }
        }
        """#
        let output = #"""
        class Main {
            func main() {
                print("""
                That've been not indented at all.
                \#n\#
                After SwiftFormat it causes a compiler error in the line above.
                """)
            }
        }
        """#
        let options = FormatOptions(truncateBlankLines: false)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testIndentUnderIndentedMultilineStringDoesntAddIndent() {
        let input = #"""
        class Main {
            func main() {
                print("""
            That've been not indented at all.

            After SwiftFormat it causes a compiler error in the line above.
            """)
            }
        }
        """#
        let output = #"""
        class Main {
            func main() {
                print("""
                That've been not indented at all.
            \#("    ")
                After SwiftFormat it causes a compiler error in the line above.
                """)
            }
        }
        """#
        let options = FormatOptions(truncateBlankLines: false)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    // indent multiline raw strings

    func testIndentIndentedSimpleRawMultilineString() {
        let input = """
        {
        ##\"\"\"
            hello
            world
            \"\"\"##
        }
        """
        let output = """
        {
            ##\"\"\"
            hello
            world
            \"\"\"##
        }
        """
        testFormatting(for: input, output, rule: .indent)
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
        testFormatting(for: input, rule: .indent)
    }

    func testNoMisindentCasePath() {
        let input = """
        reducer.pullback(
            casePath: /Action.action,
            environment: {}
        )
        """
        testFormatting(for: input, rule: .indent)
    }

    // indent #if/#else/#elseif/#endif

    func testIfDefIndentModes() {
        let input = """
        struct ContentView: View {
            var body: some View {
                // swiftformat:options --ifdef indent

                Text("Hello, world!")
                // Comment above
                #if os(macOS)
                    .padding()
                #endif

                Text("Hello, world!")
                #if os(macOS)
                    // Comment inside
                    .padding()
                #endif

                // swiftformat:options --ifdef no-indent

                Text("Hello, world!")
                // Comment above
                #if os(macOS)
                    .padding()
                #endif

                Text("Hello, world!")
                #if os(macOS)
                    // Comment inside
                    .padding()
                #endif

                // swiftformat:options --ifdef outdent

                Text("Hello, world!")
                // Comment above
                #if os(macOS)
                    .padding()
                #endif

                Text("Hello, world!")
                #if os(macOS)
                    // Comment inside
                    .padding()
                #endif
            }
        }
        """
        let output = """
        struct ContentView: View {
            var body: some View {
                // swiftformat:options --ifdef indent

                Text("Hello, world!")
                // Comment above
                #if os(macOS)
                    .padding()
                #endif

                Text("Hello, world!")
                #if os(macOS)
                    // Comment inside
                    .padding()
                #endif

                // swiftformat:options --ifdef no-indent

                Text("Hello, world!")
                // Comment above
                #if os(macOS)
                    .padding()
                #endif

                Text("Hello, world!")
                #if os(macOS)
                    // Comment inside
                    .padding()
                #endif

                // swiftformat:options --ifdef outdent

                Text("Hello, world!")
        // Comment above
        #if os(macOS)
                    .padding()
        #endif

                Text("Hello, world!")
        #if os(macOS)
                    // Comment inside
                    .padding()
        #endif
            }
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    // indent #if/#else/#elseif/#endif (mode: indent)

    func testIfEndifIndenting() {
        let input = """
        #if x
        // foo
        #endif
        """
        let output = """
        #if x
            // foo
        #endif
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testIndentedIfEndifIndenting() {
        let input = """
        {
        #if x
        // foo
        foo()
        #endif
        }
        """
        let output = """
        {
            #if x
                // foo
                foo()
            #endif
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testIfElseEndifIndenting() {
        let input = """
        #if x
            // foo
        foo()
        #else
            // bar
        #endif
        """
        let output = """
        #if x
            // foo
            foo()
        #else
            // bar
        #endif
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testEnumIfCaseEndifIndenting() {
        let input = """
        enum Foo {
        case bar
        #if x
        case baz
        #endif
        }
        """
        let output = """
        enum Foo {
            case bar
            #if x
                case baz
            #endif
        }
        """
        let options = FormatOptions(indentCase: false)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testSwitchIfCaseEndifIndenting() {
        let input = """
        switch foo {
        case .bar: break
        #if x
        case .baz: break
        #endif
        }
        """
        let output = """
        switch foo {
        case .bar: break
        #if x
            case .baz: break
        #endif
        }
        """
        let options = FormatOptions(indentCase: false)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testSwitchIfCaseEndifIndenting2() {
        let input = """
        switch foo {
        case .bar: break
        #if x
        case .baz: break
        #endif
        }
        """
        let output = """
        switch foo {
            case .bar: break
            #if x
                case .baz: break
            #endif
        }
        """
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testSwitchIfCaseEndifIndenting3() {
        let input = """
        switch foo {
        #if x
        case .bar: break
        case .baz: break
        #endif
        }
        """
        let output = """
        switch foo {
        #if x
            case .bar: break
            case .baz: break
        #endif
        }
        """
        let options = FormatOptions(indentCase: false)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testSwitchIfCaseEndifIndenting4() {
        let input = """
        switch foo {
        #if x
        case .bar:
        break
        case .baz:
        break
        #endif
        }
        """
        let output = """
        switch foo {
            #if x
                case .bar:
                    break
                case .baz:
                    break
            #endif
        }
        """
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testSwitchIfCaseElseCaseEndifIndenting() {
        let input = """
        switch foo {
        #if x
        case .bar: break
        #else
        case .baz: break
        #endif
        }
        """
        let output = """
        switch foo {
        #if x
            case .bar: break
        #else
            case .baz: break
        #endif
        }
        """
        let options = FormatOptions(indentCase: false)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testSwitchIfCaseElseCaseEndifIndenting2() {
        let input = """
        switch foo {
        #if x
        case .bar: break
        #else
        case .baz: break
        #endif
        }
        """
        let output = """
        switch foo {
            #if x
                case .bar: break
            #else
                case .baz: break
            #endif
        }
        """
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testSwitchIfEndifInsideCaseIndenting() {
        let input = """
        switch foo {
        case .bar:
        #if x
        bar()
        #endif
        baz()
        case .baz: break
        }
        """
        let output = """
        switch foo {
        case .bar:
            #if x
                bar()
            #endif
            baz()
        case .baz: break
        }
        """
        let options = FormatOptions(indentCase: false)
        testFormatting(for: input, output, rule: .indent, options: options, exclude: [.blankLineAfterSwitchCase])
    }

    func testSwitchIfEndifInsideCaseIndenting2() {
        let input = """
        switch foo {
        case .bar:
        #if x
        bar()
        #endif
        baz()
        case .baz: break
        }
        """
        let output = """
        switch foo {
            case .bar:
                #if x
                    bar()
                #endif
                baz()
            case .baz: break
        }
        """
        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, output, rule: .indent, options: options, exclude: [.blankLineAfterSwitchCase])
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
        testFormatting(for: input, rule: .indent, options: options)
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
        testFormatting(for: input, rule: .indent, options: options)
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
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, output, rule: .indent)
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
        testFormatting(for: input, rule: .indent)
    }

    func testNoIndentDotExpressionInsideIfdef() {
        let input = """
        let current: Platform = {
            #if os(macOS)
                .mac
            #elseif os(Linux)
                .linux
            #elseif os(Windows)
                .windows
            #else
                fatalError("Unknown OS not supported")
            #endif
        }()
        """
        testFormatting(for: input, rule: .indent)
    }

    // indent #if/#else/#elseif/#endif (mode: noindent)

    func testIfEndifNoIndenting() {
        let input = """
        #if x
        // foo
        #endif
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testIndentedIfEndifNoIndenting() {
        let input = """
        {
        #if x
        // foo
        #endif
        }
        """
        let output = """
        {
            #if x
            // foo
            #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testIfElseEndifNoIndenting() {
        let input = """
        #if x
        // foo
        #else
        // bar
        #endif
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testIfCaseEndifNoIndenting() {
        let input = """
        switch foo {
        case .bar: break
        #if x
        case .baz: break
        #endif
        }
        """
        let options = FormatOptions(indentCase: false, ifdefIndent: .noIndent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testIfCaseEndifNoIndenting2() {
        let input = """
        switch foo {
        case .bar: break
        #if x
        case .baz: break
        #endif
        }
        """
        let output = """
        switch foo {
            case .bar: break
            #if x
            case .baz: break
            #endif
        }
        """
        let options = FormatOptions(indentCase: true, ifdefIndent: .noIndent)
        testFormatting(for: input, output, rule: .indent, options: options)
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
        testFormatting(for: input, rule: .indent, options: options)
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
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testIfEndifInsideCaseNoIndenting() {
        let input = """
        switch foo {
        case .bar:
        #if x
        bar()
        #endif
        baz()
        case .baz: break
        }
        """
        let output = """
        switch foo {
        case .bar:
            #if x
            bar()
            #endif
            baz()
        case .baz: break
        }
        """
        let options = FormatOptions(indentCase: false, ifdefIndent: .noIndent)
        testFormatting(for: input, output, rule: .indent, options: options, exclude: [.blankLineAfterSwitchCase])
    }

    func testIfEndifInsideCaseNoIndenting2() {
        let input = """
        switch foo {
        case .bar:
        #if x
        bar()
        #endif
        baz()
        case .baz: break
        }
        """
        let output = """
        switch foo {
            case .bar:
                #if x
                bar()
                #endif
                baz()
            case .baz: break
        }
        """
        let options = FormatOptions(indentCase: true, ifdefIndent: .noIndent)
        testFormatting(for: input, output, rule: .indent, options: options, exclude: [.blankLineAfterSwitchCase])
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
        testFormatting(for: input, rule: .indent, options: options)
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
        testFormatting(for: input, rule: .indent, options: options)
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
        testFormatting(for: input, rule: .indent, options: options)
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
        testFormatting(for: input, rule: .indent, options: options)
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
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testIfDefPostfixMemberSyntaxNoIndenting2() {
        let input = """
        func foo() {
            Button {
                "Hello"
            }
            #if DEBUG
            .foo()
            #else
            .bar()
            #endif
            .baz()
        }
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testIfDefPostfixMemberSyntaxNoIndenting3() {
        let input = """
        func foo() {
            Text(
                "Hello"
            )
            #if DEBUG
            .foo()
            #else
            .bar()
            #endif
            .baz()
        }
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testNoIndentDotInitInsideIfdef() {
        let input = """
        func myFunc() -> String {
            #if DEBUG
            .init("foo")
            #elseif PROD
            .init("bar")
            #else
            .init("baz")
            #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testNoIndentDotInitInsideIfdef2() {
        let input = """
        var title: Font {
            #if os(iOS)
            .init(style: .title2)
            #else
            .init(style: .title2, size: 40)
            #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .noIndent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testIfDefPostfixMemberSyntaxPreserveKeepsAlignment() {
        let input = """
        struct Example: View {
            var body: some View {
                Text("Example")
                    .frame(maxWidth: 500, alignment: .leading)
                    #if !os(tvOS)
                    .font(.system(size: 14, design: .monospaced))
                    #endif
                    .padding(10)
            }
        }
        """
        let options = FormatOptions(ifdefIndent: .preserve)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testIfDefPreserveWithinIndentedChain() {
        let input = """
        struct ContentView: View {
            var body: some View {
                VStack {
                    Text("Hello World")
                }
                .foregroundStyle(Color.white)
                #if os(iOS)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                #endif
            }
        }
        """
        let options = FormatOptions(ifdefIndent: .preserve)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testIfDefPreserveWithinNestedChainBlock() {
        let input = """
        struct ContentView: View {
            var body: some View {
                VStack {
                    Text("Hello World")
                }
                .foregroundStyle(Color.white)
                #if os(iOS)
                .background {
                    Color.black
                }
                #endif
            }
        }
        """
        let options = FormatOptions(ifdefIndent: .preserve)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testIfDefPreserveWithinNestedChainBlock2() {
        let input = """
        struct ContentView: View {
            var body: some View {
                VStack {
                    Text("Hello World")
                }
                .foregroundStyle(Color.white)
                #if os(iOS)
                .background {
                    Color.black
                        .overlay {
                            Color.white
                        }
                }
                #endif
            }
        }
        """
        let options = FormatOptions(ifdefIndent: .preserve)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testIfDefPreserveWithinNestedChainBlock3() {
        let input = """
        struct ContentView: View {
            var body: some View {
                VStack {
                    Text("Hello World")
                }
                .foregroundStyle(Color.white)
                #if os(iOS)
                .background {
                    Color.black
                        .overlay {
                            Color.white
                                .mask {
                                    Circle()
                                }
                        }
                }
                #endif
            }
        }
        """
        let options = FormatOptions(ifdefIndent: .preserve)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testIfDefPreserveWithinNestedChainBlock4() {
        let input = """
        struct ContentView: View {
            var body: some View {
                VStack {
                    Text("Hello World")
                }
                .foregroundStyle(Color.white)
                #if os(iOS)
                .background {
                    Color.black
                        .overlay {
                            Color.white
                                .mask {
                                    Circle()
                                        .overlay {
                                            Rectangle()
                                        }
                                }
                        }
                }
                #endif
            }
        }
        """
        let options = FormatOptions(ifdefIndent: .preserve)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testIfDefPreserveMultipleModifiersInChain() {
        let input = """
        struct ContentView: View {
            var body: some View {
                Text("Example")
                    .frame(maxWidth: 200)
                    #if os(iOS)
                    .padding(4)
                    .background {
                        Color.red
                            .overlay {
                                Text("Inner")
                            }
                    }
                    .cornerRadius(8)
                    #endif
            }
        }
        """
        let options = FormatOptions(ifdefIndent: .preserve)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testIfDefPreserveWithElseIfBranches() {
        let input = """
        struct ContentView: View {
            var body: some View {
                Text("Example")
                    .frame(maxWidth: 200)
                    #if os(iOS)
                    .padding(4)
                        .background {
                            Color.red
                        }
                    #elseif os(macOS)
                    .padding(10)
                        .background {
                            Color.blue
                                .overlay {
                                    Circle()
                                }
                        }
                    #else
                    .foregroundColor(.gray)
                        .shadow(radius: 2)
                    #endif
            }
        }
        """
        let options = FormatOptions(ifdefIndent: .preserve)
        testFormatting(for: input, rule: .indent, options: options)
    }

    // indent #if/#else/#elseif/#endif (mode: outdent)

    func testIfEndifOutdenting() {
        let input = """
        #if x
        // foo
        #endif
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testIndentedIfEndifOutdenting() {
        let input = """
        {
        #if x
        // foo
        #endif
        }
        """
        let output = """
        {
        #if x
            // foo
        #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testIfElseEndifOutdenting() {
        let input = """
        #if x
        // foo
        #else
        // bar
        #endif
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testIndentedIfElseEndifOutdenting() {
        let input = """
        {
        #if x
        // foo
        foo()
        #else
        // bar
        #endif
        }
        """
        let output = """
        {
        #if x
            // foo
            foo()
        #else
            // bar
        #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testIfElseifEndifOutdenting() {
        let input = """
        #if x
        // foo
        #elseif y
        // bar
        #endif
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testIndentedIfElseifEndifOutdenting() {
        let input = """
        {
        #if x
        // foo
        foo()
        #elseif y
        // bar
        #endif
        }
        """
        let output = """
        {
        #if x
            // foo
            foo()
        #elseif y
            // bar
        #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testNestedIndentedIfElseifEndifOutdenting() {
        let input = """
        {
        #if x
        #if y
        // foo
        foo()
        #elseif y
        // bar
        #endif
        #endif
        }
        """
        let output = """
        {
        #if x
        #if y
            // foo
            foo()
        #elseif y
            // bar
        #endif
        #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testDoubleNestedIndentedIfElseifEndifOutdenting() {
        let input = """
        {
        #if x
        #if y
        #if z
        // foo
        foo()
        #elseif y
        // bar
        #endif
        #endif
        #endif
        }
        """
        let output = """
        {
        #if x
        #if y
        #if z
            // foo
            foo()
        #elseif y
            // bar
        #endif
        #endif
        #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testIfCaseEndifOutdenting() {
        let input = """
        switch foo {
        case .bar: break
        #if x
        case .baz: break
        #endif
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: .indent, options: options)
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
        testFormatting(for: input, rule: .indent, options: options)
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
        testFormatting(for: input, rule: .indent, options: options)
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
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testIfDefPostfixMemberSyntaxOutdenting2() {
        let input = """
        func foo() {
            Button {
                "Hello"
            }
        #if DEBUG
            .foo()
        #else
            .bar()
        #endif
            .baz()
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testIfDefPostfixMemberSyntaxOutdenting3() {
        let input = """
        func foo() {
            Text(
                "Hello"
            )
        #if DEBUG
            .foo()
        #else
            .bar()
        #endif
            .baz()
        }
        """
        let options = FormatOptions(ifdefIndent: .outdent)
        testFormatting(for: input, rule: .indent, options: options)
    }

    // indent expression after return

    func testIndentIdentifierAfterReturn() {
        let input = """
        if foo {
            return
                bar
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    func testIndentEnumValueAfterReturn() {
        let input = """
        if foo {
            return
                .bar
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    func testIndentMultilineExpressionAfterReturn() {
        let input = """
        if foo {
            return
                bar +
                baz
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    func testDontIndentClosingBraceAfterReturn() {
        let input = """
        if foo {
            return
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    func testDontIndentCaseAfterReturn() {
        let input = """
        switch foo {
        case bar:
            return
        case baz:
            return
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    func testDontIndentCaseAfterWhere() {
        let input = """
        switch foo {
        case bar
        where baz:
        return
        default:
        return
        }
        """
        let output = """
        switch foo {
        case bar
            where baz:
            return
        default:
            return
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }

    func testDontIndentIfAfterReturn() {
        let input = """
        if foo {
            return
            if bar {}
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    func testDontIndentFuncAfterReturn() {
        let input = """
        if foo {
            return
            func bar() {}
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    // indent fragments

    func testIndentFragment() {
        let input = """
           func foo() {
        bar()
        }
        """
        let output = """
           func foo() {
               bar()
           }
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testIndentFragmentAfterBlankLines() {
        let input = """


           func foo() {
        bar()
        }
        """
        let output = """


           func foo() {
               bar()
           }
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testUnterminatedFragment() {
        let input = """
        class Foo {

          func foo() {
        bar()
        }
        """
        let output = """
        class Foo {

            func foo() {
                bar()
            }
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: .indent, options: options,
                       exclude: [.blankLinesAtStartOfScope])
    }

    func testOverTerminatedFragment() {
        let input = """
           func foo() {
        bar()
        }

        }
        """
        let output = """
           func foo() {
               bar()
           }

        }
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: .indent, options: options)
    }

    func testDontCorruptPartialFragment() {
        let input = """
            } foo {
                bar
            }
        }
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testDontCorruptPartialFragment2() {
        let input = """
                return completionHandler(nil)
            }
        }
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testDontCorruptPartialFragment3() {
        let input = """
            foo: bar,
            foo1: bar2,
            foo2: bar3
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: .indent, options: options)
    }

    // indent with tabs

    func testTabIndentWrappedTupleWithSmartTabs() {
        let input = """
        let foo = (bar: Int,
                   baz: Int)
        """
        let options = FormatOptions(indent: "\t", tabWidth: 2, smartTabs: true)
        testFormatting(for: input, rule: .indent, options: options)
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
        testFormatting(for: input, output, rule: .indent, options: options)
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
        testFormatting(for: input, output, rule: .indent, options: options, exclude: [.sortSwitchCases])
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
        testFormatting(for: input, output, rule: .indent, options: options, exclude: [.sortSwitchCases])
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
        testFormatting(for: input, output, rule: .indent, options: options, exclude: [.sortSwitchCases])
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
        let options = FormatOptions(indent: "\t", truncateBlankLines: true, tabWidth: 2)
        XCTAssertEqual(try lint(input, rules: [.indent, .trailingSpace], options: options), [
            Formatter.Change(line: 3, rule: .trailingSpace, filePath: nil, isMove: false),
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
        testFormatting(for: input, rule: .indent, options: options,
                       exclude: [.consecutiveBlankLines, .wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    // async

    func testAsyncThrowsNotUnindented() {
        let input = """
        func multilineFunction(
            foo _: String,
            bar _: String)
            async throws -> String {}
        """
        let options = FormatOptions(closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testAsyncTypedThrowsNotUnindented() {
        let input = """
        func multilineFunction(
            foo _: String,
            bar _: String)
            async throws(Foo) -> String {}
        """
        let options = FormatOptions(closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options)
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
        testFormatting(for: input, output, rule: .indent)
    }

    func testIndentAsyncLetAfterLet() {
        let input = """
        func myFunc() {
            let x = 1
            async let foo = bar()
        }
        """
        testFormatting(for: input, rule: .indent)
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
        testFormatting(for: input, rule: .indent)
    }

    func testAsyncFunctionArgumentLabelNotIndented() {
        let input = """
        func multilineFunction(
            foo _: String,
            async _: String)
            -> String {}
        """
        let options = FormatOptions(closingParenPosition: .sameLine)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testIndentIfExpressionAssignmentOnNextLine() {
        let input = """
        let foo =
        if let bar = someBar {
            bar
        } else if let baaz = someBaaz {
            baaz
        } else if let quux = someQuux {
            if let foo = someFoo {
                foo
            } else {
                quux
            }
        } else {
            foo2
        }

        print(foo)
        """

        let output = """
        let foo =
            if let bar = someBar {
                bar
            } else if let baaz = someBaaz {
                baaz
            } else if let quux = someQuux {
                if let foo = someFoo {
                    foo
                } else {
                    quux
                }
            } else {
                foo2
            }

        print(foo)
        """

        testFormatting(for: input, output, rule: .indent, exclude: [.wrapMultilineStatementBraces])
    }

    func testIndentIfExpressionAssignmentOnSameLine() {
        let input = """
        let foo = if let bar {
            bar
        } else if let baaz {
            baaz
        } else if let quux {
            if let foo {
                foo
            } else {
                quux
            }
        }
        """

        testFormatting(for: input, rule: .indent, exclude: [.wrapMultilineConditionalAssignment])
    }

    func testIndentSwitchExpressionAssignment() {
        let input = """
        let foo =
        switch bar {
        case true:
            bar
        case baaz:
            baaz
        }
        """

        let output = """
        let foo =
            switch bar {
            case true:
                bar
            case baaz:
                baaz
            }
        """

        testFormatting(for: input, output, rule: .indent)
    }

    func testIndentSwitchExpressionAssignmentInNestedScope() {
        let input = """
        class Foo {
            func foo() -> Foo {
                let foo =
                switch bar {
                case true:
                    bar
                case baaz:
                    baaz
                }

                return foo
            }
        }
        """

        let output = """
        class Foo {
            func foo() -> Foo {
                let foo =
                    switch bar {
                    case true:
                        bar
                    case baaz:
                        baaz
                    }

                return foo
            }
        }
        """

        testFormatting(for: input, output, rule: .indent, exclude: [.redundantProperty])
    }

    func testIndentNestedSwitchExpressionAssignment() {
        let input = """
        let foo =
        switch bar {
        case true:
            bar
        case baaz:
            switch bar {
            case true:
                bar
            case baaz:
                baaz
            }
        }
        """

        let output = """
        let foo =
            switch bar {
            case true:
                bar
            case baaz:
                switch bar {
                case true:
                    bar
                case baaz:
                    baaz
                }
            }
        """

        testFormatting(for: input, output, rule: .indent)
    }

    func testIndentSwitchExpressionAssignmentWithComments() {
        let input = """
        let foo =
        // There is a comment before the switch statement
        switch bar {
        // Plus a comment before each case
        case true:
            bar
        // Plus a comment before each case
        case baaz:
            baaz
        }

        print(foo)
        """

        let output = """
        let foo =
            // There is a comment before the switch statement
            switch bar {
            // Plus a comment before each case
            case true:
                bar
            // Plus a comment before each case
            case baaz:
                baaz
            }

        print(foo)
        """

        testFormatting(for: input, output, rule: .indent)
    }

    func testIndentIfExpressionWithSingleComment() {
        let input = """
        let foo =
            // There is a comment before the first branch
            if let foo {
                foo
            } else {
                bar
            }

        print(foo)
        """

        testFormatting(for: input, rule: .indent)
    }

    func testIndentIfExpressionWithComments() {
        let input = """
        let foo =
            // There is a comment before the first branch
            if let foo {
                foo
            }
            // There is a comment before the second branch
            else {
                bar
            }

        print(foo)
        """

        testFormatting(for: input, rule: .indent, exclude: [.wrapMultilineStatementBraces])
    }

    func testIndentMultilineIfExpression() {
        let input = """
        let foo =
            if
                let foo,
                foo != disallowedFoo
            {
                foo
            }
            // There is a comment before the second branch
            else {
                bar
            }

        print(foo)
        print(foo)
        """

        testFormatting(for: input, rule: .indent, exclude: [.braces])
    }

    func testIndentNestedIfExpressionWithComments() {
        let input = """
        let foo =
            // There is a comment before the first branch
            if let foo {
                foo
            }
            // There is a comment before the second branch
            else {
                // And a comment before each of these nested branches
                if let bar {
                    bar
                }
                // And a comment before each of these nested branches
                else {
                    baaz
                }
            }

        print(foo)
        """

        testFormatting(for: input, rule: .indent, exclude: [.wrapMultilineStatementBraces])
    }

    func testIndentIfExpressionWithMultilineComments() {
        let input = """
        let foo =
            // There is a comment before the first branch
            // which spans across multiple lines
            if let foo {
                foo
            }
            // And also a comment before the second branch
            // which spans across multiple lines
            else {
                bar
            }
        """

        testFormatting(for: input, rule: .indent)
    }

    func testSE0380Example() {
        let input = """
        let bullet =
            if isRoot && (count == 0 || !willExpand) { "" }
            else if count == 0 { "- " }
            else if maxDepth <= 0 { "▹ " }
            else { "▿ " }

        print(bullet)
        """
        let options = FormatOptions()
        testFormatting(for: input, rule: .indent, options: options, exclude: [.wrapConditionalBodies, .andOperator, .redundantParens])
    }

    func testWrappedTernaryOperatorIndentsChainedCalls() {
        let input = """
        let ternary = condition
            ? values
                .map { $0.bar }
                .filter { $0.hasFoo }
                .last
            : other.values
                .compactMap { $0 }
                .first?
                .with(property: updatedValue)
        """

        let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 60)
        testFormatting(for: input, rule: .indent, options: options)
    }

    func testIndentSwitchCaseWhere() {
        let input = """
        switch testKey {
            case "organization"
            where testValues.map(String.init).compactMap { try? Entity.ID($0, format: .number) }
            .contains(Self.sessionInteractor.stage.value?.membership?.organization.id ?? .zero): // 2
                continue

            case "user"
            where testValues.map(String.init).compactMap { try? Entity.ID($0, format: .number) }
            .contains(Self.sessionInteractor.stage.value?.session?.user.id ?? .zero): // 3
                continue
        }
        """

        let options = FormatOptions(indentCase: true)
        testFormatting(for: input, rule: .indent, options: options, exclude: [.wrap, .wrapMultilineFunctionChains])
    }

    func testGuardElseIndentAfterParenthesizedExpression() {
        let input = """
        func format() {
            guard
                let result = foo(
                    bar: 5,
                    baz: 6
                )
            else {
                return
            }

            print(result)
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    func testGuardElseIndentAfterSwitchExpression() {
        let input = """
        func format(foo: String?) {
            guard
                let result =
                    switch foo {
                    case .none: "none"
                    case .some: "some"
                    }
            else {
                return
            }

            print(result)
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    func testGuardElseIndentAfterIfExpression() {
        let input = """
        func format(foo: Bool) {
            guard
                let result =
                    if foo {
                        bar
                    } else {
                        nil
                    }
            else {
                return
            }

            print(result)
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    func testIfElseIndentAfterSwitchExpression() {
        let input = """
        func format(foo: String?) {
            if
                let result =
                    switch foo {
                    case .none: "none"
                    case .some: "some"
                    }
            {
                return true
            } else {
                return false
            }

            print(result)
        }
        """
        testFormatting(for: input, rule: .indent)
    }

    func testIndentConditionalCompiledMacroInvocations() {
        let input = """
        #if true
            #warning("Warning")
        #else
            #warning("Warning")
        #endif
        """
        testFormatting(for: input, rule: .indent)
    }

    func testIndentMacroInvocationsInCollection() {
        let input = """
        let urls = [
            googleURL,
            #URL("github.com"),
            #URL("apple.com"),
        ]
        """
        testFormatting(for: input, rule: .indent)
    }

    func testReturnMacroInvocation() {
        let input = """
        func foo() {
            return
            #URL("github.com")
        }
        """
        let output = """
        func foo() {
            return
                #URL("github.com")
        }
        """
        testFormatting(for: input, output, rule: .indent)
    }
}
