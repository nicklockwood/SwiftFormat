//
//  SpaceAroundOperatorsTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 8/22/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class SpaceAroundOperatorsTests: XCTestCase {
    func testSpaceAfterColon() {
        let input = """
        let foo:Bar = 5
        """
        let output = """
        let foo: Bar = 5
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceBetweenOptionalAndDefaultValue() {
        let input = """
        let foo: String?=nil
        """
        let output = """
        let foo: String? = nil
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceBetweenImplictlyUnwrappedOptionalAndDefaultValue() {
        let input = """
        let foo: String!=nil
        """
        let output = """
        let foo: String! = nil
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpacePreservedBetweenOptionalTryAndDot() {
        let input = """
        let foo: Int = try? .init()
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testSpacePreservedBetweenForceTryAndDot() {
        let input = """
        let foo: Int = try! .init()
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testSpaceBetweenOptionalAndDefaultValueInFunction() {
        let input = """
        func foo(bar _: String?=nil) {}
        """
        let output = """
        func foo(bar _: String? = nil) {}
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testNoSpaceAddedAfterColonInSelector() {
        let input = """
        @objc(foo:bar:)
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testSpaceAfterColonInSwitchCase() {
        let input = """
        switch x { case .y:break }
        """
        let output = """
        switch x { case .y: break }
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceAfterColonInSwitchDefault() {
        let input = """
        switch x { default:break }
        """
        let output = """
        switch x { default: break }
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceAfterComma() {
        let input = """
        let foo = [1,2,3]
        """
        let output = """
        let foo = [1, 2, 3]
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceBetweenColonAndEnumValue() {
        let input = """
        [.Foo:.Bar]
        """
        let output = """
        [.Foo: .Bar]
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceBetweenCommaAndEnumValue() {
        let input = """
        [.Foo,.Bar]
        """
        let output = """
        [.Foo, .Bar]
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testNoRemoveSpaceAroundEnumInBrackets() {
        let input = """
        [ .red ]
        """
        testFormatting(for: input, rule: .spaceAroundOperators,
                       exclude: [.spaceInsideBrackets])
    }

    func testSpaceBetweenSemicolonAndEnumValue() {
        let input = """
        statement;.Bar
        """
        let output = """
        statement; .Bar
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpacePreservedBetweenEqualsAndEnumValue() {
        let input = """
        foo = .Bar
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testNoSpaceBeforeColon() {
        let input = """
        let foo : Bar = 5
        """
        let output = """
        let foo: Bar = 5
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpacePreservedBeforeColonInTernary() {
        let input = """
        foo ? bar : baz
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testSpacePreservedAroundEnumValuesInTernary() {
        let input = """
        foo ? .Bar : .Baz
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testSpaceBeforeColonInNestedTernary() {
        let input = """
        foo ? (hello + a ? b: c) : baz
        """
        let output = """
        foo ? (hello + a ? b : c) : baz
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testNoSpaceBeforeComma() {
        let input = """
        let foo = [1 , 2 , 3]
        """
        let output = """
        let foo = [1, 2, 3]
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceAtStartOfLine() {
        let input = """
        print(foo
              ,bar)
        """
        let output = """
        print(foo
              , bar)
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators,
                       exclude: [.leadingDelimiters])
    }

    func testSpaceAroundInfixMinus() {
        let input = """
        foo-bar
        """
        let output = """
        foo - bar
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testNoSpaceAroundPrefixMinus() {
        let input = """
        foo + -bar
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testSpaceAroundLessThan() {
        let input = """
        foo<bar
        """
        let output = """
        foo < bar
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testRemoveSpaceAroundDot() {
        let input = """
        foo . bar
        """
        let output = """
        foo.bar
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testNoSpaceAroundDotOnNewLine() {
        let input = """
        foo
            .bar
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testSpaceAroundEnumCase() {
        let input = """
        case .Foo,.Bar:
        """
        let output = """
        case .Foo, .Bar:
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSwitchWithEnumCases() {
        let input = """
        switch x {
        case.Foo:
            break
        default:
            break
        }
        """
        let output = """
        switch x {
        case .Foo:
            break
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceAroundEnumReturn() {
        let input = """
        return.Foo
        """
        let output = """
        return .Foo
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testNoSpaceAfterReturnAsIdentifier() {
        let input = """
        foo.return.Bar
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testSpaceAroundCaseLet() {
        let input = """
        case let.Foo(bar):
        """
        let output = """
        case let .Foo(bar):
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceAroundEnumArgument() {
        let input = """
        foo(with:.Bar)
        """
        let output = """
        foo(with: .Bar)
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceBeforeEnumCaseInsideClosure() {
        let input = """
        { .bar() }
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testNoSpaceAroundMultipleOptionalChaining() {
        let input = """
        foo??!?!.bar
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testNoSpaceAroundForcedChaining() {
        let input = """
        foo!.bar
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testNoSpaceAddedInOptionalChaining() {
        let input = """
        foo?.bar
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testSpaceRemovedInOptionalChaining() {
        let input = """
        foo? .bar
        """
        let output = """
        foo?.bar
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceRemovedInForcedChaining() {
        let input = """
        foo! .bar
        """
        let output = """
        foo!.bar
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceRemovedInMultipleOptionalChaining() {
        let input = """
        foo??! .bar
        """
        let output = """
        foo??!.bar
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testNoSpaceAfterOptionalInsideTernary() {
        let input = """
        x ? foo? .bar() : bar?.baz()
        """
        let output = """
        x ? foo?.bar() : bar?.baz()
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSplitLineOptionalChaining() {
        let input = """
        foo?
            .bar
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testSplitLineMultipleOptionalChaining() {
        let input = """
        foo??!
            .bar
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testSpaceBetweenNullCoalescingAndDot() {
        let input = """
        foo ?? .bar()
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testNoSpaceAroundFailableInit() {
        let input = """
        init?()
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testNoSpaceAroundImplictlyUnwrappedFailableInit() {
        let input = """
        init!()
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testNoSpaceAroundFailableInitWithGenerics() {
        let input = """
        init?<T>()
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testNoSpaceAroundImplictlyUnwrappedFailableInitWithGenerics() {
        let input = """
        init!<T>()
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testNoSpaceAroundInitWithGenericAndSuppressedConstraint() {
        let input = """
        init<T: ~Copyable>()
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testGenericBracketAroundAttributeNotConfusedWithLessThan() {
        let input = """
        Example<(@MainActor () -> Void)?>(nil)
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testSpaceAfterOptionalAs() {
        let input = """
        foo as?[String]
        """
        let output = """
        foo as? [String]
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceAfterForcedAs() {
        let input = """
        foo as![String]
        """
        let output = """
        foo as! [String]
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testNoSpaceAroundGenerics() {
        let input = """
        Foo<String>
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testNoSpaceAroundGenericsWithSuppressedConstraint() {
        let input = """
        Foo<String: ~Copyable>
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testSpaceAroundReturnTypeArrow() {
        let input = """
        foo() ->Bool
        """
        let output = """
        foo() -> Bool
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceAroundCommentInInfixExpression() {
        let input = """
        foo/* hello */-bar
        """
        let output = """
        foo/* hello */ -bar
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators,
                       exclude: [.spaceAroundComments])
    }

    func testSpaceAroundCommentsInInfixExpression() {
        let input = """
        a/* */+/* */b
        """
        let output = """
        a/* */ + /* */b
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators,
                       exclude: [.spaceAroundComments])
    }

    func testSpaceAroundCommentInPrefixExpression() {
        let input = """
        a + /* hello */ -bar
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testPrefixMinusBeforeMember() {
        let input = """
        -.foo
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testPostfixMinusBeforeMember() {
        let input = """
        foo-.bar
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testRemoveSpaceBeforeNegativeIndex() {
        let input = """
        foo[ -bar]
        """
        let output = """
        foo[-bar]
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testNoInsertSpaceBeforeUnlabelledAddressArgument() {
        let input = """
        foo(&bar)
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testRemoveSpaceBeforeUnlabelledAddressArgument() {
        let input = """
        foo( &bar, baz: &baz)
        """
        let output = """
        foo(&bar, baz: &baz)
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testRemoveSpaceBeforeKeyPath() {
        let input = """
        foo( \\.bar)
        """
        let output = """
        foo(\\.bar)
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testAddSpaceAfterFuncEquals() {
        let input = """
        func ==(lhs: Int, rhs: Int) -> Bool { return lhs === rhs }
        """
        let output = """
        func == (lhs: Int, rhs: Int) -> Bool { return lhs === rhs }
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators, exclude: [.wrapFunctionBodies])
    }

    func testRemoveSpaceAfterFuncEquals() {
        let input = """
        func == (lhs: Int, rhs: Int) -> Bool { return lhs === rhs }
        """
        let output = """
        func ==(lhs: Int, rhs: Int) -> Bool { return lhs === rhs }
        """
        let options = FormatOptions(spaceAroundOperatorDeclarations: .remove)
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options, exclude: [.wrapFunctionBodies])
    }

    func testPreserveSpaceAfterFuncEquals() {
        let input = """
        func == (lhs: Int, rhs: Int) -> Bool { return lhs === rhs }
        func !=(lhs: Int, rhs: Int) -> Bool { return lhs !== rhs }
        """
        let options = FormatOptions(spaceAroundOperatorDeclarations: .preserve)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options, exclude: [.wrapFunctionBodies])
    }

    func testAddSpaceAfterOperatorEquals() {
        let input = """
        operator =={}
        """
        let output = """
        operator == {}
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testNoRemoveSpaceAfterOperatorEqualsWhenSpaceAroundOperatorDeclarationsFalse() {
        let input = """
        operator == {}
        """
        let options = FormatOptions(spaceAroundOperatorDeclarations: .remove)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    func testNoAddSpaceAfterOperatorEqualsWithAllmanBrace() {
        let input = """
        operator ==
        {}
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testNoAddSpaceAroundOperatorInsideParens() {
        let input = """
        (!=)
        """
        testFormatting(for: input, rule: .spaceAroundOperators, exclude: [.redundantParens])
    }

    func testSpaceAroundPlusBeforeHash() {
        let input = """
        \"foo.\"+#file
        """
        let output = """
        \"foo.\" + #file
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceNotAddedAroundStarInAvailableAnnotation() {
        let input = """
        @available(*, deprecated, message: \"foo\")
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    func testAddSpaceAroundRange() {
        let input = """
        let a = b...c
        """
        let output = """
        let a = b ... c
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceRemovedInNestedPropertyWrapper() {
        let input = """
        @Encoded .Foo var foo: String
        """
        let output = """
        @Encoded.Foo var foo: String
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testSpaceNotAddedInKeyPath() {
        let input = """
        let a = b.map(\\.?.something)
        """
        testFormatting(for: input, rule: .spaceAroundOperators)
    }

    // noSpaceOperators

    func testNoAddSpaceAroundNoSpaceStar() {
        let input = """
        let a = b*c+d
        """
        let output = """
        let a = b*c + d
        """
        let options = FormatOptions(noSpaceOperators: ["*"])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    func testRemoveSpaceAroundNoSpaceStar() {
        let input = """
        let a = b * c + d
        """
        let output = """
        let a = b*c + d
        """
        let options = FormatOptions(noSpaceOperators: ["*"])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    func testNoRemoveSpaceAroundNoSpaceStarBeforePrefixOperator() {
        let input = """
        let a = b * -c
        """
        let options = FormatOptions(noSpaceOperators: ["*"])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    func testNoRemoveSpaceAroundNoSpaceStarAfterPostfixOperator() {
        let input = """
        let a = b% * c
        """
        let options = FormatOptions(noSpaceOperators: ["*"])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    func testRemoveSpaceAroundNoSpaceStarAfterUnwrapOperator() {
        let input = """
        let a = b! * c
        """
        let output = """
        let a = b!*c
        """
        let options = FormatOptions(noSpaceOperators: ["*"])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    func testNoAddSpaceAroundNoSpaceSlash() {
        let input = """
        let a = b/c+d
        """
        let output = """
        let a = b/c + d
        """
        let options = FormatOptions(noSpaceOperators: ["/"])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    func testNoAddSpaceAroundNoSpaceRange() {
        let input = """
        let a = b...c
        """
        let options = FormatOptions(noSpaceOperators: ["..."])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    func testNoAddSpaceAroundNoSpaceHalfOpenRange() {
        let input = """
        let a = b..<c
        """
        let options = FormatOptions(noSpaceOperators: ["..<"])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    func testRemoveSpaceAroundNoSpaceRange() {
        let input = """
        let a = b ... c
        """
        let output = """
        let a = b...c
        """
        let options = FormatOptions(noSpaceOperators: ["..."])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    func testNoRemoveSpaceAroundNoSpaceRangeBeforePrefixOperator() {
        let input = """
        let a = b ... -c
        """
        let options = FormatOptions(noSpaceOperators: ["..."])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    func testNoRemoveSpaceAroundTernaryColon() {
        let input = """
        let a = b ? c : d
        """
        let output = """
        let a = b ? c:d
        """
        let options = FormatOptions(noSpaceOperators: [":"])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    func testNoRemoveSpaceAroundTernaryQuestionMark() {
        let input = """
        let a = b ? c : d
        """
        let options = FormatOptions(noSpaceOperators: ["?"])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    func testSpaceOnOneSideOfPlusMatchedByLinebreakNotRemoved() {
        let input = """
        let range = 0 +
        4
        """
        let options = FormatOptions(noSpaceOperators: ["+"])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.indent])
    }

    func testSpaceOnOneSideOfPlusMatchedByLinebreakNotRemoved2() {
        let input = """
        let range = 0
        + 4
        """
        let options = FormatOptions(noSpaceOperators: ["+"])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.indent])
    }

    func testSpaceAroundPlusWithLinebreakOnOneSideNotRemoved() {
        let input = """
        let range = 0 + 
        4
        """
        let options = FormatOptions(noSpaceOperators: ["+"])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.indent, .trailingSpace])
    }

    func testSpaceAroundPlusWithLinebreakOnOneSideNotRemoved2() {
        let input = """
        let range = 0
         + 4
        """
        let options = FormatOptions(noSpaceOperators: ["+"])
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.indent])
    }

    func testAddSpaceEvenAfterLHSClosure() {
        let input = """
        let foo = { $0 }..bar
        """
        let output = """
        let foo = { $0 } .. bar
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testAddSpaceEvenBeforeRHSClosure() {
        let input = """
        let foo = bar..{ $0 }
        """
        let output = """
        let foo = bar .. { $0 }
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testAddSpaceEvenAfterLHSArray() {
        let input = """
        let foo = [42]..bar
        """
        let output = """
        let foo = [42] .. bar
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testAddSpaceEvenBeforeRHSArray() {
        let input = """
        let foo = bar..[42]
        """
        let output = """
        let foo = bar .. [42]
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testAddSpaceEvenAfterLHSParens() {
        let input = """
        let foo = (42, 1337)..bar
        """
        let output = """
        let foo = (42, 1337) .. bar
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testAddSpaceEvenBeforeRHSParens() {
        let input = """
        let foo = bar..(42, 1337)
        """
        let output = """
        let foo = bar .. (42, 1337)
        """
        testFormatting(for: input, output, rule: .spaceAroundOperators)
    }

    func testRemoveSpaceEvenAfterLHSClosure() {
        let input = """
        let foo = { $0 } .. bar
        """
        let output = """
        let foo = { $0 }..bar
        """
        let options = FormatOptions(noSpaceOperators: [".."])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    func testRemoveSpaceEvenBeforeRHSClosure() {
        let input = """
        let foo = bar .. { $0 }
        """
        let output = """
        let foo = bar..{ $0 }
        """
        let options = FormatOptions(noSpaceOperators: [".."])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    func testRemoveSpaceEvenAfterLHSArray() {
        let input = """
        let foo = [42] .. bar
        """
        let output = """
        let foo = [42]..bar
        """
        let options = FormatOptions(noSpaceOperators: [".."])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    func testRemoveSpaceEvenBeforeRHSArray() {
        let input = """
        let foo = bar .. [42]
        """
        let output = """
        let foo = bar..[42]
        """
        let options = FormatOptions(noSpaceOperators: [".."])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    func testRemoveSpaceEvenAfterLHSParens() {
        let input = """
        let foo = (42, 1337) .. bar
        """
        let output = """
        let foo = (42, 1337)..bar
        """
        let options = FormatOptions(noSpaceOperators: [".."])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    func testRemoveSpaceEvenBeforeRHSParens() {
        let input = """
        let foo = bar .. (42, 1337)
        """
        let output = """
        let foo = bar..(42, 1337)
        """
        let options = FormatOptions(noSpaceOperators: [".."])
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    func testSpaceNotInsertedInParameterPackGenericArgument() {
        let input = """
        func zip<Other, each Another>(
            with _: Optional<Other>,
            _: repeat Optional<each Another>
        ) -> Optional<(Wrapped, Other, repeat each Another)> {}
        """

        testFormatting(for: input, rule: .spaceAroundOperators, exclude: [.typeSugar])
    }

    // spaceAroundRangeOperators: .remove

    func testNoSpaceAroundRangeOperatorsWithCustomOptions() {
        let input = """
        foo ..< bar
        """
        let output = """
        foo..<bar
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(for: input, output, rule: .spaceAroundOperators, options: options)
    }

    func testSpaceNotRemovedBeforeLeadingRangeOperatorWithSpaceAroundRangeOperatorsFalse() {
        let input = """
        let range = ..<foo.endIndex
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    func testSpaceOnOneSideOfRangeMatchedByCommentNotRemoved() {
        let input = """
        let range = 0 .../* foo */4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.spaceAroundComments])
    }

    func testSpaceOnOneSideOfRangeMatchedByCommentNotRemoved2() {
        let input = """
        let range = 0/* foo */... 4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.spaceAroundComments])
    }

    func testSpaceAroundRangeWithCommentOnOneSideNotRemoved() {
        let input = """
        let range = 0 ... /* foo */4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.spaceAroundComments])
    }

    func testSpaceAroundRangeWithCommentOnOneSideNotRemoved2() {
        let input = """
        let range = 0/* foo */ ... 4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.spaceAroundComments])
    }

    func testSpaceOnOneSideOfRangeMatchedByLinebreakNotRemoved() {
        let input = """
        let range = 0 ...
        4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.indent])
    }

    func testSpaceOnOneSideOfRangeMatchedByLinebreakNotRemoved2() {
        let input = """
        let range = 0
        ... 4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.indent])
    }

    func testSpaceAroundRangeWithLinebreakOnOneSideNotRemoved() {
        let input = """
        let range = 0 ... 
        4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.indent, .trailingSpace])
    }

    func testSpaceAroundRangeWithLinebreakOnOneSideNotRemoved2() {
        let input = """
        let range = 0
         ... 4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options,
                       exclude: [.indent])
    }

    func testSpaceNotRemovedAroundRangeFollowedByPrefixOperator() {
        let input = """
        let range = 0 ... -4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    func testSpaceNotRemovedAroundRangePreceededByPostfixOperator() {
        let input = """
        let range = 0>> ... 4
        """
        let options = FormatOptions(spaceAroundRangeOperators: .remove)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    // spaceAroundRangeOperators: .preserve

    func testPreserveSpaceAroundRangeOperators() {
        let input = """
        let a = foo ..< bar
        let b = foo..<bar
        let c = foo ... bar
        let d = foo...bar
        """
        let options = FormatOptions(spaceAroundRangeOperators: .preserve)
        testFormatting(for: input, rule: .spaceAroundOperators, options: options)
    }

    func testSpaceAroundDataTypeDelimiterLeadingAdded() {
        let input = """
        class Implementation: ImplementationProtocol {}
        """
        let output = """
        class Implementation : ImplementationProtocol {}
        """
        let options = FormatOptions(typeDelimiterSpacing: .spaced)
        testFormatting(
            for: input,
            output,
            rule: .spaceAroundOperators,
            options: options
        )
    }

    func testSpaceAroundDataTypeDelimiterLeadingTrailingAdded() {
        let input = """
        class Implementation:ImplementationProtocol {}
        """
        let output = """
        class Implementation : ImplementationProtocol {}
        """
        let options = FormatOptions(typeDelimiterSpacing: .spaced)
        testFormatting(
            for: input,
            output,
            rule: .spaceAroundOperators,
            options: options
        )
    }

    func testSpaceAroundDataTypeDelimiterLeadingTrailingNotModified() {
        let input = """
        class Implementation : ImplementationProtocol {}
        """
        let options = FormatOptions(typeDelimiterSpacing: .spaced)
        testFormatting(
            for: input,
            rule: .spaceAroundOperators,
            options: options
        )
    }

    func testSpaceAroundDataTypeDelimiterTrailingAdded() {
        let input = """
        class Implementation:ImplementationProtocol {}
        """
        let output = """
        class Implementation: ImplementationProtocol {}
        """

        let options = FormatOptions(typeDelimiterSpacing: .spaceAfter)
        testFormatting(
            for: input,
            output,
            rule: .spaceAroundOperators,
            options: options
        )
    }

    func testSpaceAroundDataTypeDelimiterLeadingNotAdded() {
        let input = """
        class Implementation: ImplementationProtocol {}
        """
        let options = FormatOptions(typeDelimiterSpacing: .spaceAfter)
        testFormatting(
            for: input,
            rule: .spaceAroundOperators,
            options: options
        )
    }
}
