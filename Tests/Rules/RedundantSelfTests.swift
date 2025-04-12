//
//  RedundantSelfTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 3/13/17.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class RedundantSelfTests: XCTestCase {
    // explicitSelf = .remove

    func testSimpleRemoveRedundantSelf() {
        let input = "func foo() { self.bar() }"
        let output = "func foo() { bar() }"
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testRemoveSelfInsideStringInterpolation() {
        let input = "class Foo {\n    var bar: String?\n    func baz() {\n        print(\"\\(self.bar)\")\n    }\n}"
        let output = "class Foo {\n    var bar: String?\n    func baz() {\n        print(\"\\(bar)\")\n    }\n}"
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testNoRemoveSelfForArgument() {
        let input = "func foo(bar: Int) { self.bar = bar }"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfForLocalVariable() {
        let input = "func foo() { var bar = self.bar }"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testRemoveSelfForLocalVariableOn5_4() {
        let input = "func foo() { var bar = self.bar }"
        let output = "func foo() { var bar = bar }"
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, output, rule: .redundantSelf,
                       options: options)
    }

    func testNoRemoveSelfForCommaDelimitedLocalVariables() {
        let input = "func foo() { let foo = self.foo, bar = self.bar }"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testRemoveSelfForCommaDelimitedLocalVariablesOn5_4() {
        let input = "func foo() { let foo = self.foo, bar = self.bar }"
        let output = "func foo() { let foo = self.foo, bar = bar }"
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, output, rule: .redundantSelf,
                       options: options)
    }

    func testNoRemoveSelfForCommaDelimitedLocalVariables2() {
        let input = "func foo() {\n    let foo: Foo, bar: Bar\n    foo = self.foo\n    bar = self.bar\n}"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfForTupleAssignedVariables() {
        let input = "func foo() { let (bar, baz) = (self.bar, self.baz) }"
        testFormatting(for: input, rule: .redundantSelf)
    }

    // TODO: make this work
//    func testRemoveSelfForTupleAssignedVariablesOn5_4() {
//        let input = "func foo() { let (bar, baz) = (self.bar, self.baz) }"
//        let output = "func foo() { let (bar, baz) = (bar, baz) }"
//        let options = FormatOptions(swiftVersion: "5.4")
//        testFormatting(for: input, output, rule: .redundantSelf,
//                       options: options)
//    }

    func testNoRemoveSelfForTupleAssignedVariablesFollowedByRegularVariable() {
        let input = "func foo() {\n    let (foo, bar) = (self.foo, self.bar), baz = self.baz\n}"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfForTupleAssignedVariablesFollowedByRegularLet() {
        let input = "func foo() {\n    let (foo, bar) = (self.foo, self.bar)\n    let baz = self.baz\n}"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveNonRedundantNestedFunctionSelf() {
        let input = "func foo() { func bar() { self.bar() } }"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveNonRedundantNestedFunctionSelf2() {
        let input = "func foo() {\n    func bar() {}\n    self.bar()\n}"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveNonRedundantNestedFunctionSelf3() {
        let input = "func foo() { let bar = 5; func bar() { self.bar = bar } }"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveClosureSelf() {
        let input = "func foo() { bar { self.bar = 5 } }"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfAfterOptionalReturn() {
        let input = "func foo() -> String? {\n    var index = startIndex\n    if !matching(self[index]) {\n        break\n    }\n    index = self.index(after: index)\n}"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveRequiredSelfInExtensions() {
        let input = "extension Foo {\n    func foo() {\n        var index = 5\n        if true {\n            break\n        }\n        index = self.index(after: index)\n    }\n}"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfBeforeInit() {
        let input = "convenience init() { self.init(5) }"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testRemoveSelfInsideSwitch() {
        let input = "func foo() {\n    switch self.bar {\n    case .foo:\n        self.baz()\n    }\n}"
        let output = "func foo() {\n    switch bar {\n    case .foo:\n        baz()\n    }\n}"
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testRemoveSelfInsideSwitchWhere() {
        let input = "func foo() {\n    switch self.bar {\n    case .foo where a == b:\n        self.baz()\n    }\n}"
        let output = "func foo() {\n    switch bar {\n    case .foo where a == b:\n        baz()\n    }\n}"
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testRemoveSelfInsideSwitchWhereAs() {
        let input = "func foo() {\n    switch self.bar {\n    case .foo where a == b as C:\n        self.baz()\n    }\n}"
        let output = "func foo() {\n    switch bar {\n    case .foo where a == b as C:\n        baz()\n    }\n}"
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testRemoveSelfInsideClassInit() {
        let input = "class Foo {\n    var bar = 5\n    init() { self.bar = 6 }\n}"
        let output = "class Foo {\n    var bar = 5\n    init() { bar = 6 }\n}"
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testNoRemoveSelfInClosureInsideIf() {
        let input = "if foo { bar { self.baz() } }"
        testFormatting(for: input, rule: .redundantSelf,
                       exclude: [.wrapConditionalBodies])
    }

    func testNoRemoveSelfForErrorInCatch() {
        let input = "do {} catch { self.error = error }"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfForErrorInDoThrowsCatch() {
        let input = "do throws(Foo) {} catch { self.error = error }"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfForNewValueInSet() {
        let input = "var foo: Int { set { self.newValue = newValue } get { return 0 } }"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfForCustomNewValueInSet() {
        let input = "var foo: Int { set(n00b) { self.n00b = n00b } get { return 0 } }"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfForNewValueInWillSet() {
        let input = "var foo: Int { willSet { self.newValue = newValue } }"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfForCustomNewValueInWillSet() {
        let input = "var foo: Int { willSet(n00b) { self.n00b = n00b } }"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfForOldValueInDidSet() {
        let input = "var foo: Int { didSet { self.oldValue = oldValue } }"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfForCustomOldValueInDidSet() {
        let input = "var foo: Int { didSet(oldz) { self.oldz = oldz } }"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfForIndexVarInFor() {
        let input = "for foo in bar { self.foo = foo }"
        testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapLoopBodies])
    }

    func testNoRemoveSelfForKeyValueTupleInFor() {
        let input = "for (foo, bar) in baz { self.foo = foo; self.bar = bar }"
        testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapLoopBodies])
    }

    func testRemoveSelfFromComputedVar() {
        let input = "var foo: Int { return self.bar }"
        let output = "var foo: Int { return bar }"
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testRemoveSelfFromOptionalComputedVar() {
        let input = "var foo: Int? { return self.bar }"
        let output = "var foo: Int? { return bar }"
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testRemoveSelfFromNamespacedComputedVar() {
        let input = "var foo: Swift.String { return self.bar }"
        let output = "var foo: Swift.String { return bar }"
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testRemoveSelfFromGenericComputedVar() {
        let input = "var foo: Foo<Int> { return self.bar }"
        let output = "var foo: Foo<Int> { return bar }"
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testRemoveSelfFromComputedArrayVar() {
        let input = "var foo: [Int] { return self.bar }"
        let output = "var foo: [Int] { return bar }"
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testRemoveSelfFromVarSetter() {
        let input = "var foo: Int { didSet { self.bar() } }"
        let output = "var foo: Int { didSet { bar() } }"
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testNoRemoveSelfFromVarClosure() {
        let input = "var foo = { self.bar }"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfFromLazyVar() {
        let input = "lazy var foo = self.bar"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testRemoveSelfFromLazyVar() {
        let input = "lazy var foo = self.bar"
        let output = "lazy var foo = bar"
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testNoRemoveSelfFromLazyVarImmediatelyAfterOtherVar() {
        let input = """
        var baz = bar
        lazy var foo = self.bar
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testRemoveSelfFromLazyVarImmediatelyAfterOtherVar() {
        let input = """
        var baz = bar
        lazy var foo = self.bar
        """
        let output = """
        var baz = bar
        lazy var foo = bar
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testNoRemoveSelfFromLazyVarClosure() {
        let input = "lazy var foo = { self.bar }()"
        testFormatting(for: input, rule: .redundantSelf, exclude: [.redundantClosure])
    }

    func testNoRemoveSelfFromLazyVarClosure2() {
        let input = "lazy var foo = { let bar = self.baz }()"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfFromLazyVarClosure3() {
        let input = "lazy var foo = { [unowned self] in let bar = self.baz }()"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testRemoveSelfFromVarInFuncWithUnusedArgument() {
        let input = "func foo(bar _: Int) { self.baz = 5 }"
        let output = "func foo(bar _: Int) { baz = 5 }"
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testRemoveSelfFromVarMatchingUnusedArgument() {
        let input = "func foo(bar _: Int) { self.bar = 5 }"
        let output = "func foo(bar _: Int) { bar = 5 }"
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testNoRemoveSelfFromVarMatchingRenamedArgument() {
        let input = "func foo(bar baz: Int) { self.baz = baz }"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfFromVarRedeclaredInSubscope() {
        let input = "func foo() {\n    if quux {\n        let bar = 5\n    }\n    let baz = self.bar\n}"
        let output = "func foo() {\n    if quux {\n        let bar = 5\n    }\n    let baz = bar\n}"
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testNoRemoveSelfFromVarDeclaredLaterInScope() {
        let input = "func foo() {\n    let bar = self.baz\n    let baz = quux\n}"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfFromVarDeclaredLaterInOuterScope() {
        let input = "func foo() {\n    if quux {\n        let bar = self.baz\n    }\n    let baz = 6\n}"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfInWhilePreceededByVarDeclaration() {
        let input = "var index = start\nwhile index < end {\n    index = self.index(after: index)\n}"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfInLocalVarPrecededByLocalVarFollowedByIfComma() {
        let input = "func foo() {\n    let bar = Bar()\n    let baz = Baz()\n    self.baz = baz\n    if let bar = bar, bar > 0 {}\n}"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfInLocalVarPrecededByIfLetContainingClosure() {
        let input = "func foo() {\n    if let bar = 5 { baz { _ in } }\n    let quux = self.quux\n}"
        testFormatting(for: input, rule: .redundantSelf,
                       exclude: [.wrapConditionalBodies])
    }

    func testNoRemoveSelfForVarCreatedInGuardScope() {
        let input = "func foo() {\n    guard let bar = 5 else {}\n    let baz = self.bar\n}"
        testFormatting(for: input, rule: .redundantSelf,
                       exclude: [.wrapConditionalBodies])
    }

    func testRemoveSelfForVarCreatedInIfScope() {
        let input = "func foo() {\n    if let bar = bar {}\n    let baz = self.bar\n}"
        let output = "func foo() {\n    if let bar = bar {}\n    let baz = bar\n}"
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testNoRemoveSelfForVarDeclaredInWhileCondition() {
        let input = "while let foo = bar { self.foo = foo }"
        testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapLoopBodies])
    }

    func testRemoveSelfForVarNotDeclaredInWhileCondition() {
        let input = "while let foo == bar { self.baz = 5 }"
        let output = "while let foo == bar { baz = 5 }"
        testFormatting(for: input, output, rule: .redundantSelf, exclude: [.wrapLoopBodies])
    }

    func testNoRemoveSelfForVarDeclaredInSwitchCase() {
        let input = "switch foo {\ncase bar: let baz = self.baz\n}"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfAfterGenericInit() {
        let input = "init(bar: Int) {\n    self = Foo<Bar>()\n    self.bar(bar)\n}"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testRemoveSelfInClassFunction() {
        let input = "class Foo {\n    class func foo() {\n        func bar() { self.foo() }\n    }\n}"
        let output = "class Foo {\n    class func foo() {\n        func bar() { foo() }\n    }\n}"
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testRemoveSelfInStaticFunction() {
        let input = "struct Foo {\n    static func foo() {\n        func bar() { self.foo() }\n    }\n}"
        let output = "struct Foo {\n    static func foo() {\n        func bar() { foo() }\n    }\n}"
        testFormatting(for: input, output, rule: .redundantSelf, exclude: [.enumNamespaces])
    }

    func testRemoveSelfInClassFunctionWithModifiers() {
        let input = "class Foo {\n    class private func foo() {\n        func bar() { self.foo() }\n    }\n}"
        let output = "class Foo {\n    class private func foo() {\n        func bar() { foo() }\n    }\n}"
        testFormatting(for: input, output, rule: .redundantSelf,
                       exclude: [.modifierOrder])
    }

    func testNoRemoveSelfInClassFunction() {
        let input = "class Foo {\n    class func foo() {\n        var foo: Int\n        func bar() { self.foo() }\n    }\n}"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfForVarDeclaredAfterRepeatWhile() {
        let input = "class Foo {\n    let foo = 5\n    func bar() {\n        repeat {} while foo\n        let foo = 6\n        self.foo()\n    }\n}"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfForVarInClosureAfterRepeatWhile() {
        let input = "class Foo {\n    let foo = 5\n    func bar() {\n        repeat {} while foo\n        ({ self.foo() })()\n    }\n}"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfInClosureAfterVar() {
        let input = "var foo: String\nbar { self.baz() }"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfInClosureAfterNamespacedVar() {
        let input = "var foo: Swift.String\nbar { self.baz() }"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfInClosureAfterOptionalVar() {
        let input = "var foo: String?\nbar { self.baz() }"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfInClosureAfterGenericVar() {
        let input = "var foo: Foo<Int>\nbar { self.baz() }"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfInClosureAfterArray() {
        let input = "var foo: [Int]\nbar { self.baz() }"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfInExpectFunction() { // Special case to support the Nimble framework
        let input = """
        class FooTests: XCTestCase {
            let foo = 1
            func testFoo() {
                expect(self.foo) == 1
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoRemoveNestedSelfInExpectFunction() {
        let input = """
        func testFoo() {
            expect(Foo.validate(bar: self.bar)).to(equal(1))
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoRemoveNestedSelfInArrayInExpectFunction() {
        let input = """
        func testFoo() {
            expect(Foo.validate(bar: [self.bar])).to(equal(1))
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoRemoveNestedSelfInSubscriptInExpectFunction() {
        let input = """
        func testFoo() {
            expect(Foo.validations[self.bar]).to(equal(1))
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoRemoveSelfInOSLogFunction() {
        let input = """
        func testFoo() {
            os_log("error: \\(self.bar) is nil")
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoRemoveSelfInExcludedFunction() {
        let input = """
        class Foo {
            let foo = 1
            func testFoo() {
                log(self.foo)
            }
        }
        """
        let options = FormatOptions(selfRequired: ["log"])
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoRemoveSelfForExcludedFunction() {
        let input = """
        class Foo {
            let foo = 1
            func testFoo() {
                self.log(foo)
            }
        }
        """
        let options = FormatOptions(selfRequired: ["log"])
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoRemoveSelfInInterpolatedStringInExcludedFunction() {
        let input = """
        class Foo {
            let foo = 1
            func testFoo() {
                log("\\(self.foo)")
            }
        }
        """
        let options = FormatOptions(selfRequired: ["log"])
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoRemoveSelfInExcludedInitializer() {
        let input = """
        let vc = UIHostingController(rootView: InspectionView(inspection: self.inspection))
        """
        let options = FormatOptions(selfRequired: ["InspectionView"])
        testFormatting(for: input, rule: .redundantSelf, options: options, exclude: [.propertyTypes])
    }

    func testSelfRemovedFromSwitchCaseWhere() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let foo where self.bar.baz:
                    return self.bar
                default:
                    return nil
                }
            }
        }
        """
        let output = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let foo where bar.baz:
                    return bar
                default:
                    return nil
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testSwitchCaseLetVarRecognized() {
        let input = """
        switch foo {
        case .bar:
            baz = nil
        case let baz:
            self.baz = baz
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testSwitchCaseHoistedLetVarRecognized() {
        let input = """
        switch foo {
        case .bar:
            baz = nil
        case let .foo(baz):
            self.baz = baz
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testSwitchCaseWhereMemberNotTreatedAsVar() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let bar where self.bar.baz:
                    return self.bar
                default:
                    return nil
                }
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testSelfNotRemovedInClosureAfterSwitch() {
        let input = """
        switch x {
        default:
            break
        }
        let foo = { y in
            switch y {
            default:
                self.bar()
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testSelfNotRemovedInClosureInCaseWithWhereClause() {
        let input = """
        switch foo {
        case bar where baz:
            quux = { self.foo }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testSelfRemovedInDidSet() {
        let input = """
        class Foo {
            var bar = false {
                didSet {
                    self.bar = !self.bar
                }
            }
        }
        """
        let output = """
        class Foo {
            var bar = false {
                didSet {
                    bar = !bar
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testSelfNotRemovedInGetter() {
        let input = """
        class Foo {
            var bar: Int {
                return self.bar
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testSelfNotRemovedInIfdef() {
        let input = """
        func foo() {
            #if os(macOS)
                let bar = self.bar
            #endif
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testRedundantSelfRemovedWhenFollowedBySwitchContainingIfdef() {
        let input = """
        struct Foo {
            func bar() {
                self.method(self.value)
                switch x {
                #if BAZ
                    case .baz:
                        break
                #endif
                default:
                    break
                }
            }
        }
        """
        let output = """
        struct Foo {
            func bar() {
                method(value)
                switch x {
                #if BAZ
                    case .baz:
                        break
                #endif
                default:
                    break
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testRedundantSelfRemovedInsideConditionalCase() {
        let input = """
        struct Foo {
            func bar() {
                let method2 = () -> Void
                switch x {
                #if BAZ
                    case .baz:
                        self.method1(self.value)
                #else
                    case .quux:
                        self.method2(self.value)
                #endif
                default:
                    break
                }
            }
        }
        """
        let output = """
        struct Foo {
            func bar() {
                let method2 = () -> Void
                switch x {
                #if BAZ
                    case .baz:
                        method1(value)
                #else
                    case .quux:
                        self.method2(value)
                #endif
                default:
                    break
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testRedundantSelfRemovedAfterConditionalLet() {
        let input = """
        class Foo {
            var bar: Int?
            var baz: Bool

            func foo() {
                if let bar = bar, self.baz {
                    // ...
                }
            }
        }
        """
        let output = """
        class Foo {
            var bar: Int?
            var baz: Bool

            func foo() {
                if let bar = bar, baz {
                    // ...
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testNestedClosureInNotMistakenForForLoop() {
        let input = """
        func f() {
            let str = "hello"
            try! str.withCString(encodedAs: UTF8.self) { _ throws in
                try! str.withCString(encodedAs: UTF8.self) { _ throws in }
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testTypedThrowingNestedClosureInNotMistakenForForLoop() {
        let input = """
        func f() {
            let str = "hello"
            try! str.withCString(encodedAs: UTF8.self) { _ throws(Foo) in
                try! str.withCString(encodedAs: UTF8.self) { _ throws(Foo) in }
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testRedundantSelfPreservesSelfInClosureWithExplicitStrongCaptureBefore5_3() {
        let input = """
        class Foo {
            let bar: Int

            func baaz() {
                closure { [self] in
                    print(self.bar)
                }
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testRedundantSelfRemovesSelfInClosureWithExplicitStrongCapture() {
        let input = """
        class Foo {
            let foo: Int

            func baaz() {
                closure { [self, bar] baaz, quux in
                    print(self.foo)
                }
            }
        }
        """

        let output = """
        class Foo {
            let foo: Int

            func baaz() {
                closure { [self, bar] baaz, quux in
                    print(foo)
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.3")
        testFormatting(for: input, output, rule: .redundantSelf, options: options, exclude: [.unusedArguments])
    }

    func testRedundantSelfRemovesSelfInClosureWithNestedExplicitStrongCapture() {
        let input = """
        class Foo {
            let bar: Int

            func baaz() {
                closure {
                    print(self.bar)
                    closure { [self] in
                        print(self.bar)
                    }
                    print(self.bar)
                }
            }
        }
        """

        let output = """
        class Foo {
            let bar: Int

            func baaz() {
                closure {
                    print(self.bar)
                    closure { [self] in
                        print(bar)
                    }
                    print(self.bar)
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.3")
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testRedundantSelfKeepsSelfInNestedClosureWithNoExplicitStrongCapture() {
        let input = """
        class Foo {
            let bar: Int
            let baaz: Int?

            func baaz() {
                closure { [self] in
                    print(self.bar)
                    closure {
                        print(self.bar)
                        if let baaz = self.baaz {
                            print(baaz)
                        }
                    }
                    print(self.bar)
                    if let baaz = self.baaz {
                        print(baaz)
                    }
                }
            }
        }
        """

        let output = """
        class Foo {
            let bar: Int
            let baaz: Int?

            func baaz() {
                closure { [self] in
                    print(bar)
                    closure {
                        print(self.bar)
                        if let baaz = self.baaz {
                            print(baaz)
                        }
                    }
                    print(bar)
                    if let baaz = baaz {
                        print(baaz)
                    }
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.3")
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testRedundantSelfRemovesSelfInClosureCapturingStruct() {
        let input = """
        struct Foo {
            let bar: Int

            func baaz() {
                closure {
                    print(self.bar)
                }
            }
        }
        """

        let output = """
        struct Foo {
            let bar: Int

            func baaz() {
                closure {
                    print(bar)
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.3")
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testRedundantSelfRemovesSelfInClosureCapturingSelfWeakly() {
        let input = """
        class Foo {
            let bar: Int

            func baaz() {
                closure { [weak self] in
                    print(self?.bar)
                    guard let self else {
                        return
                    }
                    print(self.bar)
                    closure {
                        print(self.bar)
                    }
                    closure { [self] in
                        print(self.bar)
                    }
                    print(self.bar)
                }

                closure { [weak self] in
                    guard let self = self else {
                        return
                    }

                    print(self.bar)
                }

                closure { [weak self] in
                    guard let self = self ?? somethingElse else {
                        return
                    }

                    print(self.bar)
                }
            }
        }
        """

        let output = """
        class Foo {
            let bar: Int

            func baaz() {
                closure { [weak self] in
                    print(self?.bar)
                    guard let self else {
                        return
                    }
                    print(bar)
                    closure {
                        print(self.bar)
                    }
                    closure { [self] in
                        print(bar)
                    }
                    print(bar)
                }

                closure { [weak self] in
                    guard let self = self else {
                        return
                    }

                    print(bar)
                }

                closure { [weak self] in
                    guard let self = self ?? somethingElse else {
                        return
                    }

                    print(self.bar)
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.8")
        testFormatting(for: input, output, rule: .redundantSelf,
                       options: options, exclude: [.redundantOptionalBinding])
    }

    func testWeakSelfNotRemovedIfNotUnwrapped() {
        let input = """
        class A {
            weak var delegate: ADelegate?

            func testFunction() {
                DispatchQueue.main.async { [weak self] in
                    self.flatMap { $0.delegate?.aDidSomething($0) }
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.8")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testClosureParameterListShadowingPropertyOnSelf() {
        let input = """
        class Foo {
            var bar = "bar"

            func method() {
                closure { [self] bar in
                    self.bar = bar
                }
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.3")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testClosureParameterListShadowingPropertyOnSelfInStruct() {
        let input = """
        struct Foo {
            var bar = "bar"

            func method() {
                closure { bar in
                    self.bar = bar
                }
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.3")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testClosureCaptureListShadowingPropertyOnSelf() {
        let input = """
        class Foo {
            var bar = "bar"
            var baaz = "baaz"

            func method() {
                closure { [self, bar, baaz = bar] in
                    self.bar = bar
                    self.baaz = baaz
                }
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.3")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testRedundantSelfKeepsSelfInClosureCapturingSelfWeaklyBefore5_8() {
        let input = """
        class Foo {
            let bar: Int

            func baaz() {
                closure { [weak self] in
                    print(self?.bar)
                    guard let self else {
                        return
                    }
                    print(self.bar)
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNonRedundantSelfNotRemovedAfterConditionalLet() {
        let input = """
        class Foo {
            var bar: Int?
            var baz: Bool

            func foo() {
                let baz = 5
                if let bar = bar, self.baz {
                    // ...
                }
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testRedundantSelfDoesntGetStuckIfNoParensFound() {
        let input = "init<T>_ foo: T {}"
        testFormatting(for: input, rule: .redundantSelf,
                       exclude: [.spaceAroundOperators])
    }

    func testNoRemoveSelfInIfLetSelf() {
        let input = """
        func foo() {
            if let self = self as? Foo {
                self.bar()
            }
            self.bar()
        }
        """
        let output = """
        func foo() {
            if let self = self as? Foo {
                self.bar()
            }
            bar()
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testNoRemoveSelfInIfLetEscapedSelf() {
        let input = """
        func foo() {
            if let `self` = self as? Foo {
                self.bar()
            }
            self.bar()
        }
        """
        let output = """
        func foo() {
            if let `self` = self as? Foo {
                self.bar()
            }
            bar()
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testNoRemoveSelfAfterGuardLetSelf() {
        let input = """
        func foo() {
            guard let self = self as? Foo else {
                return
            }
            self.bar()
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfInClosureInIfCondition() {
        let input = """
        class Foo {
            func foo() {
                if bar({ self.baz() }) {}
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfInTrailingClosureInVarAssignment() {
        let input = """
        func broken() {
            var bad = abc {
                self.foo()
                self.bar
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testSelfNotRemovedWhenPropertyIsKeyword() {
        let input = """
        class Foo {
            let `default` = 5
            func foo() {
                print(self.default)
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testSelfNotRemovedWhenPropertyIsContextualKeyword() {
        let input = """
        class Foo {
            let `self` = 5
            func foo() {
                print(self.self)
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testSelfRemovedForContextualKeywordThatRequiresNoEscaping() {
        let input = """
        class Foo {
            let get = 5
            func foo() {
                print(self.get)
            }
        }
        """
        let output = """
        class Foo {
            let get = 5
            func foo() {
                print(get)
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testRemoveSelfForMemberNamedLazy() {
        let input = "func foo() { self.lazy() }"
        let output = "func foo() { lazy() }"
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testRemoveRedundantSelfInArrayLiteral() {
        let input = """
        class Foo {
            func foo() {
                print([self.bar.x, self.bar.y])
            }
        }
        """
        let output = """
        class Foo {
            func foo() {
                print([bar.x, bar.y])
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testRemoveRedundantSelfInArrayLiteralVar() {
        let input = """
        class Foo {
            func foo() {
                var bars = [self.bar.x, self.bar.y]
                print(bars)
            }
        }
        """
        let output = """
        class Foo {
            func foo() {
                var bars = [bar.x, bar.y]
                print(bars)
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testRemoveRedundantSelfInGuardLet() {
        let input = """
        class Foo {
            func foo() {
                guard let bar = self.baz else {
                    return
                }
            }
        }
        """
        let output = """
        class Foo {
            func foo() {
                guard let bar = baz else {
                    return
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testSelfNotRemovedInClosureInIf() {
        let input = """
        if let foo = bar(baz: { [weak self] in
            guard let self = self else { return }
            _ = self.myVar
        }) {}
        """
        testFormatting(for: input, rule: .redundantSelf,
                       exclude: [.wrapConditionalBodies])
    }

    func testStructSelfRemovedInTrailingClosureInIfCase() {
        let input = """
        struct A {
            func doSomething() {
                B.method { mode in
                    if case .edit = mode {
                        self.doA()
                    } else {
                        self.doB()
                    }
                }
            }

            func doA() {}
            func doB() {}
        }
        """
        let output = """
        struct A {
            func doSomething() {
                B.method { mode in
                    if case .edit = mode {
                        doA()
                    } else {
                        doB()
                    }
                }
            }

            func doA() {}
            func doB() {}
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf,
                       options: FormatOptions(swiftVersion: "5.8"))
    }

    func testSelfNotRemovedInDynamicMemberLookup() {
        let input = """
        @dynamicMemberLookup
        struct Foo {
            subscript(dynamicMember foo: String) -> String {
                foo + "bar"
            }

            func bar() {
                if self.foo == "foobar" {
                    return
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testSelfNotRemovedInDeclarationWithDynamicMemberLookup() {
        let input = """
        @dynamicMemberLookup
        struct Foo {
            subscript(dynamicMember foo: String) -> String {
                foo + "bar"
            }

            func bar() {
                let foo = self.foo
                print(foo)
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testSelfNotRemovedInExtensionOfTypeWithDynamicMemberLookup() {
        let input = """
        @dynamicMemberLookup
        struct Foo {}

        extension Foo {
            subscript(dynamicMember foo: String) -> String {
                foo + "bar"
            }

            func bar() {
                if self.foo == "foobar" {
                    return
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testSelfRemovedInNestedExtensionOfTypeWithDynamicMemberLookup() {
        let input = """
        @dynamicMemberLookup
        struct Foo {
            var foo: Int
            struct Foo {}
            extension Foo {
                func bar() {
                    if self.foo == "foobar" {
                        return
                    }
                }
            }
        }
        """
        let output = """
        @dynamicMemberLookup
        struct Foo {
            var foo: Int
            struct Foo {}
            extension Foo {
                func bar() {
                    if foo == "foobar" {
                        return
                    }
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, output, rule: .redundantSelf,
                       options: options)
    }

    func testNoRemoveSelfAfterGuardCaseLetWithExplicitNamespace() {
        let input = """
        class Foo {
            var name: String?

            func bug(element: Something) {
                guard case let Something.a(name) = element
                else { return }
                self.name = name
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf,
                       exclude: [.wrapConditionalBodies])
    }

    func testNoRemoveSelfInAssignmentInsideIfAsStatement() {
        let input = """
        if let foo = foo as? Foo, let bar = baz {
            self.bar = bar
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testNoRemoveSelfInAssignmentInsideIfLetWithPostfixOperator() {
        let input = """
        if let foo = baz?.foo, let bar = baz?.bar {
            self.foo = foo
            self.bar = bar
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testRedundantSelfParsingBug() {
        let input = """
        private class Foo {
            mutating func bar() -> Statement? {
                let start = self
                guard case Token.identifier(let name)? = self.popFirst() else {
                    self = start
                    return nil
                }
                return Statement.declaration(name: name)
            }
        }
        """
        let output = """
        private class Foo {
            mutating func bar() -> Statement? {
                let start = self
                guard case Token.identifier(let name)? = popFirst() else {
                    self = start
                    return nil
                }
                return Statement.declaration(name: name)
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf,
                       exclude: [.hoistPatternLet])
    }

    func testRedundantSelfParsingBug2() {
        let input = """
        extension Foo {
            private enum NonHashableEnum: RawRepresentable {
                case foo
                case bar

                var rawValue: RuntimeTypeTests.TestStruct {
                    return TestStruct(foo: 0)
                }

                init?(rawValue: RuntimeTypeTests.TestStruct) {
                    switch rawValue.foo {
                    case 0:
                        self = .foo
                    case 1:
                        self = .bar
                    default:
                        return nil
                    }
                }
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testRedundantSelfWithStaticMethodAfterForLoop() {
        let input = """
        struct Foo {
            init() {
                for foo in self.bar {}
            }

            static func foo() {}
        }

        """
        let output = """
        struct Foo {
            init() {
                for foo in bar {}
            }

            static func foo() {}
        }

        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testRedundantSelfWithStaticMethodAfterForWhereLoop() {
        let input = """
        struct Foo {
            init() {
                for foo in self.bar where !bar.isEmpty {}
            }

            static func foo() {}
        }

        """
        let output = """
        struct Foo {
            init() {
                for foo in bar where !bar.isEmpty {}
            }

            static func foo() {}
        }

        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testRedundantSelfRuleDoesntErrorInForInTryLoop() {
        let input = "for foo in try bar() {}"
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testRedundantSelfInInitWithActorLabel() {
        let input = """
        class Foo {
            init(actor: Actor, bar: Bar) {
                self.actor = actor
                self.bar = bar
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testRedundantSelfRuleFailsInGuardWithParenthesizedClosureAfterComma() {
        let input = """
        guard let foo = bar, foo.bar(baz: { $0 }) else {
            return nil
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testMinSelfNotRemoved() {
        let input = """
        extension Array where Element: Comparable {
            func foo() -> Int {
                self.min()
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testMinSelfNotRemovedOnSwift5_4() {
        let input = """
        extension Array where Element == Foo {
            func smallest() -> Foo? {
                let bar = self.min(by: { rect1, rect2 -> Bool in
                    rect1.perimeter < rect2.perimeter
                })
                return bar
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options, exclude: [.redundantProperty])
    }

    func testDisableRedundantSelfDirective() {
        let input = """
        func smallest() -> Foo? {
            // swiftformat:disable:next redundantSelf
            let bar = self.foo { rect1, rect2 -> Bool in
                rect1.perimeter < rect2.perimeter
            }
            return bar
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options, exclude: [.redundantProperty])
    }

    func testDisableRedundantSelfDirective2() {
        let input = """
        func smallest() -> Foo? {
            let bar =
                // swiftformat:disable:next redundantSelf
                self.foo { rect1, rect2 -> Bool in
                    rect1.perimeter < rect2.perimeter
                }
            return bar
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options, exclude: [.redundantProperty])
    }

    func testSelfInsertDirective() {
        let input = """
        func smallest() -> Foo? {
            // swiftformat:options:next --self insert
            let bar = self.foo { rect1, rect2 -> Bool in
                rect1.perimeter < rect2.perimeter
            }
            return bar
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options, exclude: [.redundantProperty])
    }

    func testNoRemoveVariableShadowedLaterInScopeInOlderSwiftVersions() {
        let input = """
        func foo() -> Bar? {
            guard let baz = self.bar else {
                return nil
            }

            let bar = Foo()
            return Bar(baz)
        }
        """
        let options = FormatOptions(swiftVersion: "4.2")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testStillRemoveVariableShadowedInSameDecalarationInOlderSwiftVersions() {
        let input = """
        func foo() -> Bar? {
            guard let bar = self.bar else {
                return nil
            }
            return bar
        }
        """
        let output = """
        func foo() -> Bar? {
            guard let bar = bar else {
                return nil
            }
            return bar
        }
        """
        let options = FormatOptions(swiftVersion: "5.0")
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testShadowedSelfRemovedInGuardLet() {
        let input = """
        func foo() {
            guard let optional = self.optional else {
                return
            }
            print(optional)
        }
        """
        let output = """
        func foo() {
            guard let optional = optional else {
                return
            }
            print(optional)
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testShadowedStringValueNotRemovedInInit() {
        let input = """
        init() {
            let value = "something"
            self.value = value
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testShadowedIntValueNotRemovedInInit() {
        let input = """
        init() {
            let value = 5
            self.value = value
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testShadowedPropertyValueNotRemovedInInit() {
        let input = """
        init() {
            let value = foo
            self.value = value
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testShadowedFuncCallValueNotRemovedInInit() {
        let input = """
        init() {
            let value = foo()
            self.value = value
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testShadowedFuncParamRemovedInInit() {
        let input = """
        init() {
            let value = foo(self.value)
        }
        """
        let output = """
        init() {
            let value = foo(value)
        }
        """
        let options = FormatOptions(swiftVersion: "5.4")
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testNoRemoveSelfInMacro() {
        let input = """
        struct MyStruct {
            private var __myVar: String
            var myVar: String {
                @storageRestrictions(initializes: self.__myVar)
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    // explicitSelf = .insert

    func testInsertSelf() {
        let input = "class Foo {\n    let foo: Int\n    init() { foo = 5 }\n}"
        let output = "class Foo {\n    let foo: Int\n    init() { self.foo = 5 }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testInsertSelfInActor() {
        let input = "actor Foo {\n    let foo: Int\n    init() { foo = 5 }\n}"
        let output = "actor Foo {\n    let foo: Int\n    init() { self.foo = 5 }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testInsertSelfAfterReturn() {
        let input = "class Foo {\n    let foo: Int\n    func bar() -> Int { return foo }\n}"
        let output = "class Foo {\n    let foo: Int\n    func bar() -> Int { return self.foo }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testInsertSelfInsideStringInterpolation() {
        let input = "class Foo {\n    var bar: String?\n    func baz() {\n        print(\"\\(bar)\")\n    }\n}"
        let output = "class Foo {\n    var bar: String?\n    func baz() {\n        print(\"\\(self.bar)\")\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testNoInterpretGenericTypesAsMembers() {
        let input = "class Foo {\n    let foo: Bar<Int, Int>\n    init() { self.foo = Int(5) }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testInsertSelfForStaticMemberInClassFunction() {
        let input = "class Foo {\n    static var foo: Int\n    class func bar() { foo = 5 }\n}"
        let output = "class Foo {\n    static var foo: Int\n    class func bar() { self.foo = 5 }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testNoInsertSelfForInstanceMemberInClassFunction() {
        let input = "class Foo {\n    var foo: Int\n    class func bar() { foo = 5 }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoInsertSelfForStaticMemberInInstanceFunction() {
        let input = "class Foo {\n    static var foo: Int\n    func bar() { foo = 5 }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoInsertSelfForShadowedClassMemberInClassFunction() {
        let input = "class Foo {\n    class func foo() {\n        var foo: Int\n        func bar() { foo = 5 }\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoInsertSelfInForLoopTuple() {
        let input = "class Foo {\n    var bar: Int\n    func foo() { for (bar, baz) in quux {} }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoInsertSelfForTupleTypeMembers() {
        let input = "class Foo {\n    var foo: (Int, UIColor) {\n        let bar = UIColor.red\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoInsertSelfForArrayElements() {
        let input = "class Foo {\n    var foo = [1, 2, nil]\n    func bar() { baz(nil) }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoInsertSelfForNestedVarReference() {
        let input = "class Foo {\n    func bar() {\n        var bar = 5\n        repeat { bar = 6 } while true\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options, exclude: [.wrapLoopBodies])
    }

    func testNoInsertSelfInSwitchCaseLet() {
        let input = "class Foo {\n    var foo: Bar? {\n        switch bar {\n        case let .baz(foo, _):\n            return nil\n        }\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoInsertSelfInFuncAfterImportedClass() {
        let input = "import class Foo.Bar\nfunc foo() {\n    var bar = 5\n    if true {\n        bar = 6\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options,
                       exclude: [.blankLineAfterImports])
    }

    func testNoInsertSelfForSubscriptGetSet() {
        let input = "class Foo {\n    func get() {}\n    func set() {}\n    subscript(key: String) -> String {\n        get { return get(key) }\n        set { set(key, newValue) }\n    }\n}"
        let output = "class Foo {\n    func get() {}\n    func set() {}\n    subscript(key: String) -> String {\n        get { return self.get(key) }\n        set { self.set(key, newValue) }\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testNoInsertSelfInIfCaseLet() {
        let input = "enum Foo {\n    case bar(Int)\n    var value: Int? {\n        if case let .bar(value) = self { return value }\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options,
                       exclude: [.wrapConditionalBodies])
    }

    func testNoInsertSelfForPatternLet() {
        let input = "class Foo {\n    func foo() {}\n    func bar() {\n        switch x {\n        case .bar(let foo, var bar): print(foo + bar)\n        }\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoInsertSelfForPatternLet2() {
        let input = "class Foo {\n    func foo() {}\n    func bar() {\n        switch x {\n        case let .foo(baz): print(baz)\n        case .bar(let foo, var bar): print(foo + bar)\n        }\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoInsertSelfForTypeOf() {
        let input = "class Foo {\n    var type: String?\n    func bar() {\n        print(\"\\(type(of: self))\")\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoInsertSelfForConditionalLocal() {
        let input = "class Foo {\n    func foo() {\n        #if os(watchOS)\n            var foo: Int\n        #else\n            var foo: Float\n        #endif\n        print(foo)\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testInsertSelfInExtension() {
        let input = """
        struct Foo {
            var bar = 5
        }

        extension Foo {
            func baz() {
                bar = 6
            }
        }
        """
        let output = """
        struct Foo {
            var bar = 5
        }

        extension Foo {
            func baz() {
                self.bar = 6
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testGlobalAfterTypeNotTreatedAsMember() {
        let input = """
        struct Foo {
            var foo = 1
        }

        var bar = 5

        extension Foo {
            func baz() {
                bar = 6
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testForWhereVarNotTreatedAsMember() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                for bar in self where bar.baz {
                    return bar
                }
                return nil
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testSwitchCaseWhereVarNotTreatedAsMember() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let bar where bar.baz:
                    return bar
                default:
                    return nil
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testSwitchCaseVarDoesntLeak() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let bar:
                    return bar
                default:
                    return bar
                }
            }
        }
        """
        let output = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let bar:
                    return bar
                default:
                    return self.bar
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testSelfInsertedInSwitchCaseLet() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let foo:
                    return bar
                default:
                    return bar
                }
            }
        }
        """
        let output = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let foo:
                    return self.bar
                default:
                    return self.bar
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testSelfInsertedInSwitchCaseWhere() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let foo where bar.baz:
                    return bar
                default:
                    return bar
                }
            }
        }
        """
        let output = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let foo where self.bar.baz:
                    return self.bar
                default:
                    return self.bar
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testSelfInsertedInDidSet() {
        let input = """
        class Foo {
            var bar = false {
                didSet {
                    bar = !bar
                }
            }
        }
        """
        let output = """
        class Foo {
            var bar = false {
                didSet {
                    self.bar = !self.bar
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testSelfInsertedAfterLet() {
        let input = """
        struct Foo {
            let foo = "foo"
            func bar() {
                let x = foo
                baz(x)
            }

            func baz(_: String) {}
        }
        """
        let output = """
        struct Foo {
            let foo = "foo"
            func bar() {
                let x = self.foo
                self.baz(x)
            }

            func baz(_: String) {}
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testSelfNotInsertedInParameterNames() {
        let input = """
        class Foo {
            let a: String

            func bar() {
                foo(a: a)
            }
        }
        """
        let output = """
        class Foo {
            let a: String

            func bar() {
                foo(a: self.a)
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testSelfNotInsertedInCaseLet() {
        let input = """
        class Foo {
            let a: String?
            let b: String

            func bar() {
                if case let .some(a) = self.a, case var .some(b) = self.b {}
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testSelfNotInsertedInCaseLet2() {
        let input = """
        class Foo {
            let a: String?
            let b: String

            func baz() {
                if case let .foos(a, b) = foo, case let .bars(a, b) = bar {}
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testSelfInsertedInTupleAssignment() {
        let input = """
        class Foo {
            let a: String?
            let b: String

            func bar() {
                (a, b) = ("foo", "bar")
            }
        }
        """
        let output = """
        class Foo {
            let a: String?
            let b: String

            func bar() {
                (self.a, self.b) = ("foo", "bar")
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testSelfNotInsertedInTupleAssignment() {
        let input = """
        class Foo {
            let a: String?
            let b: String

            func bar() {
                let (a, b) = (self.a, self.b)
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testInsertSelfForMemberNamedLazy() {
        let input = """
        class Foo {
            var lazy = "foo"
            func foo() {
                print(lazy)
            }
        }
        """
        let output = """
        class Foo {
            var lazy = "foo"
            func foo() {
                print(self.lazy)
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testNoInsertSelfForVarDefinedInIfCaseLet() {
        let input = """
        struct A {
            var localVar = ""

            var B: String {
                if case let .c(localVar) = self.d, localVar == .e {
                    print(localVar)
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoInsertSelfForVarDefinedInUnhoistedIfCaseLet() {
        let input = """
        struct A {
            var localVar = ""

            var B: String {
                if case .c(let localVar) = self.d, localVar == .e {
                    print(localVar)
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options,
                       exclude: [.hoistPatternLet])
    }

    func testNoInsertSelfForVarDefinedInFor() {
        let input = """
        struct A {
            var localVar = ""

            var B: String {
                for localVar in 0 ..< 6 where localVar < 5 {
                    print(localVar)
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoInsertSelfForVarDefinedInWhileLet() {
        let input = """
        struct A {
            var localVar = ""

            var B: String {
                while let localVar = self.localVar, localVar < 5 {
                    print(localVar)
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoInsertSelfInCaptureList() {
        let input = """
        class Thing {
            var a: String? { nil }

            func foo() {
                let b = ""
                { [weak a = b] _ in }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoInsertSelfInCaptureList2() {
        let input = """
        class Thing {
            var a: String? { nil }

            func foo() {
                { [weak a] _ in }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoInsertSelfInCaptureList3() {
        let input = """
        class A {
            var thing: B? { fatalError() }

            func foo() {
                let thing2 = B()
                let _: (Bool) -> Void = { [weak thing = thing2] _ in
                    thing?.bar()
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testBodilessFunctionDoesntBreakParser() {
        let input = """
        @_silgen_name("foo")
        func foo(_: CFString, _: CFTypeRef) -> Int?

        enum Bar {
            static func baz() {
                fatalError()
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoInsertSelfBeforeSet() {
        let input = """
        class Foo {
            var foo: Bool

            var bar: Bool {
                get { self.foo }
                set { self.foo = newValue }
            }

            required init() {}

            func set() {}
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoInsertSelfInMacro() {
        let input = """
        struct MyStruct {
            private var __myVar: String
            var myVar: String {
                @storageRestrictions(initializes: __myVar)
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoInsertSelfBeforeBinding() {
        let input = """
        struct MyView: View {
            @Environment(ViewModel.self) var viewModel

            var body: some View {
                @Bindable var viewModel = self.viewModel
                ZStack {
                    MySubview(
                        navigationPath: $viewModel.navigationPath
                    )
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert, swiftVersion: "5.10")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoInsertSelfInKeyPath() {
        let input = """
        class UserScreenPresenter: ScreenPresenter {
            func onAppear() {
                self.sessionInteractor.stage.compactMap(\\.?.session).latestValues(on: .main)
            }

            private var session: Session?
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    // explicitSelf = .initOnly

    func testPreserveSelfInsideClassInit() {
        let input = """
        class Foo {
            var bar = 5
            init() {
                self.bar = 6
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testRemoveSelfIfNotInsideClassInit() {
        let input = """
        class Foo {
            var bar = 5
            func baz() {
                self.bar = 6
            }
        }
        """
        let output = """
        class Foo {
            var bar = 5
            func baz() {
                bar = 6
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testInsertSelfInsideClassInit() {
        let input = """
        class Foo {
            var bar = 5
            init() {
                bar = 6
            }
        }
        """
        let output = """
        class Foo {
            var bar = 5
            init() {
                self.bar = 6
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testNoInsertSelfInsideClassInitIfNotLvalue() {
        let input = """
        class Foo {
            var bar = 5
            let baz = 6
            init() {
                bar = baz
            }
        }
        """
        let output = """
        class Foo {
            var bar = 5
            let baz = 6
            init() {
                self.bar = baz
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testRemoveSelfInsideClassInitIfNotLvalue() {
        let input = """
        class Foo {
            var bar = 5
            let baz = 6
            init() {
                self.bar = self.baz
            }
        }
        """
        let output = """
        class Foo {
            var bar = 5
            let baz = 6
            init() {
                self.bar = baz
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testSelfDotTypeInsideClassInitEdgeCase() {
        let input = """
        class Foo {
            let type: Int

            init() {
                self.type = 5
            }

            func baz() {
                switch type {}
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testSelfInsertedInTupleInInit() {
        let input = """
        class Foo {
            let a: String?
            let b: String

            init() {
                (a, b) = ("foo", "bar")
            }
        }
        """
        let output = """
        class Foo {
            let a: String?
            let b: String

            init() {
                (self.a, self.b) = ("foo", "bar")
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testSelfInsertedAfterLetInInit() {
        let input = """
        class Foo {
            var foo: String
            init(bar: Bar) {
                let baz = bar.quux
                foo = baz
            }
        }
        """
        let output = """
        class Foo {
            var foo: String
            init(bar: Bar) {
                let baz = bar.quux
                self.foo = baz
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, output, rule: .redundantSelf, options: options)
    }

    func testRedundantSelfRuleDoesntErrorForStaticFuncInProtocolWithWhere() {
        let input = """
        protocol Foo where Self: Bar {
            static func baz() -> Self
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testRedundantSelfRuleDoesntErrorForStaticFuncInStructWithWhere() {
        let input = """
        struct Foo<T> where T: Bar {
            static func baz() -> Foo {}
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testRedundantSelfRuleDoesntErrorForClassFuncInClassWithWhere() {
        let input = """
        class Foo<T> where T: Bar {
            class func baz() -> Foo {}
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testRedundantSelfRuleFailsInInitOnlyMode() {
        let input = """
        class Foo {
            func foo() -> Foo? {
                guard let bar = { nil }() else {
                    return nil
                }
            }

            static func baz() -> String? {}
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, rule: .redundantSelf, options: options, exclude: [.redundantClosure])
    }

    func testRedundantSelfRuleFailsInInitOnlyMode2() {
        let input = """
        struct Mesh {
            var storage: Storage
            init(vertices: [Vertex]) {
                let isConvex = pointsAreConvex(vertices)
                storage = Storage(vertices: vertices)
            }
        }
        """
        let output = """
        struct Mesh {
            var storage: Storage
            init(vertices: [Vertex]) {
                let isConvex = pointsAreConvex(vertices)
                self.storage = Storage(vertices: vertices)
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, output, rule: .redundantSelf,
                       options: options)
    }

    func testSelfNotRemovedInInitForSwift5_4() {
        let input = """
        init() {
            let foo = 1234
            self.bar = foo
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly, swiftVersion: "5.4")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testPropertyInitNotInterpretedAsTypeInit() {
        let input = """
        struct MyStruct {
            private var __myVar: String
            var myVar: String {
                @storageRestrictions(initializes: __myVar)
                init(initialValue) {
                    __myVar = initialValue
                }
                set {
                    __myVar = newValue
                }
                get {
                    __myVar
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testPropertyInitNotInterpretedAsTypeInit2() {
        let input = """
        struct MyStruct {
            private var __myVar: String
            var myVar: String {
                @storageRestrictions(initializes: __myVar)
                init {
                    __myVar = newValue
                }
                set {
                    __myVar = newValue
                }
                get {
                    __myVar
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    // parsing bugs

    func testSelfRemovalParsingBug() {
        let input = """
        extension Dictionary where Key == String {
            func requiredValue<T>(for keyPath: String) throws -> T {
                return keyPath as! T
            }

            func optionalValue<T>(for keyPath: String) throws -> T? {
                guard let anyValue = self[keyPath] else {
                    return nil
                }
                guard let value = anyValue as? T else {
                    return nil
                }
                return value
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testSelfRemovalParsingBug2() {
        let input = """
        if let test = value()["hi"] {
            print("hi")
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testSelfRemovalParsingBug3() {
        let input = """
        func handleGenericError(_ error: Error) {
            if let requestableError = error as? RequestableError,
               case let .underlying(error as NSError) = requestableError,
               error.code == NSURLErrorNotConnectedToInternet
            {}
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testSelfRemovalParsingBug4() {
        let input = """
        struct Foo {
            func bar() {
                for flag in [] where [].filter({ true }) {}
            }

            static func baz() {}
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testSelfRemovalParsingBug5() {
        let input = """
        extension Foo {
            func method(foo: Bar) {
                self.foo = foo

                switch foo {
                case let .foo(bar):
                    closure {
                        Foo.draw()
                    }
                }
            }

            private static func draw() {}
        }
        """

        testFormatting(for: input, rule: .redundantSelf)
    }

    func testSelfRemovalParsingBug6() {
        let input = """
        something.do(onSuccess: { result in
            if case .success((let d, _)) = result {
                self.relay.onNext(d)
            }
        })
        """
        testFormatting(for: input, rule: .redundantSelf,
                       exclude: [.hoistPatternLet])
    }

    func testSelfRemovalParsingBug7() {
        let input = """
        extension Dictionary where Key == String {
            func requiredValue<T>(for keyPath: String) throws(Foo) -> T {
                return keyPath as! T
            }

            func optionalValue<T>(for keyPath: String) throws(Foo) -> T? {
                guard let anyValue = self[keyPath] else {
                    return nil
                }
                guard let value = anyValue as? T else {
                    return nil
                }
                return value
            }
        }
        """
        testFormatting(for: input, rule: .redundantSelf)
    }

    func testSelfNotRemovedInCaseIfElse() {
        let input = """
        class Foo {
            let bar = true
            let someOptionalBar: String? = "bar"

            func test() {
                guard let bar: String = someOptionalBar else {
                    return
                }

                let result = Result<Any, Error>.success(bar)
                switch result {
                case let .success(value):
                    if self.bar {
                        if self.bar {
                            print(self.bar)
                        }
                    } else {
                        if self.bar {
                            print(self.bar)
                        }
                    }

                case .failure:
                    if self.bar {
                        print(self.bar)
                    }
                }
            }
        }
        """

        testFormatting(for: input, rule: .redundantSelf)
    }

    func testSelfCallAfterIfStatementInSwitchStatement() {
        let input = """
        closure { [weak self] in
            guard let self else {
                return
            }

            switch result {
            case let .success(value):
                if value != nil {
                    if value != nil {
                        self.method()
                    }
                }
                self.method()

            case .failure:
                break
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.3")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testSelfNotRemovedFollowingNestedSwitchStatements() {
        let input = """
        class Foo {
            let bar = true
            let someOptionalBar: String? = "bar"

            func test() {
                guard let bar: String = someOptionalBar else {
                    return
                }

                let result = Result<Any, Error>.success(bar)
                switch result {
                case let .success(value):
                    switch result {
                    case .success:
                        print("success")
                    case .value:
                        print("value")
                    }

                case .failure:
                    guard self.bar else {
                        print(self.bar)
                        return
                    }
                    print(self.bar)
                }
            }
        }
        """

        testFormatting(for: input, rule: .redundantSelf)
    }

    func testRedundantSelfWithStaticAsyncSendableClosureFunction() {
        let input = """
        class Foo: Bar {
            static func bar(
                _ closure: @escaping @Sendable () async -> Foo
            ) -> @Sendable () async -> Foo {
                self.foo = closure
                return closure
            }

            static func bar() {}
        }
        """
        let output = """
        class Foo: Bar {
            static func bar(
                _ closure: @escaping @Sendable () async -> Foo
            ) -> @Sendable () async -> Foo {
                foo = closure
                return closure
            }

            static func bar() {}
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    // enable/disable

    func testDisableRemoveSelf() {
        let input = """
        class Foo {
            var bar: Int
            func baz() {
                // swiftformat:disable redundantSelf
                self.bar = 1
                // swiftformat:enable redundantSelf
                self.bar = 2
            }
        }
        """
        let output = """
        class Foo {
            var bar: Int
            func baz() {
                // swiftformat:disable redundantSelf
                self.bar = 1
                // swiftformat:enable redundantSelf
                bar = 2
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testDisableRemoveSelfCaseInsensitive() {
        let input = """
        class Foo {
            var bar: Int
            func baz() {
                // swiftformat:disable redundantself
                self.bar = 1
                // swiftformat:enable RedundantSelf
                self.bar = 2
            }
        }
        """
        let output = """
        class Foo {
            var bar: Int
            func baz() {
                // swiftformat:disable redundantself
                self.bar = 1
                // swiftformat:enable RedundantSelf
                bar = 2
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testDisableNextRemoveSelf() {
        let input = """
        class Foo {
            var bar: Int
            func baz() {
                // swiftformat:disable:next redundantSelf
                self.bar = 1
                self.bar = 2
            }
        }
        """
        let output = """
        class Foo {
            var bar: Int
            func baz() {
                // swiftformat:disable:next redundantSelf
                self.bar = 1
                bar = 2
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testMultilineDisableRemoveSelf() {
        let input = """
        class Foo {
            var bar: Int
            func baz() {
                /* swiftformat:disable redundantSelf */ self.bar = 1 /* swiftformat:enable all */
                self.bar = 2
            }
        }
        """
        let output = """
        class Foo {
            var bar: Int
            func baz() {
                /* swiftformat:disable redundantSelf */ self.bar = 1 /* swiftformat:enable all */
                bar = 2
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testMultilineDisableNextRemoveSelf() {
        let input = """
        class Foo {
            var bar: Int
            func baz() {
                /* swiftformat:disable:next redundantSelf */
                self.bar = 1
                self.bar = 2
            }
        }
        """
        let output = """
        class Foo {
            var bar: Int
            func baz() {
                /* swiftformat:disable:next redundantSelf */
                self.bar = 1
                bar = 2
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testRemovesSelfInNestedFunctionInStrongSelfClosure() {
        let input = """
        class Test {
            func doWork(_ escaping: @escaping () -> Void) {
                escaping()
            }

            func test() {
                doWork { [self] in
                    doWork {
                        // Not allowed. Warning in Swift 5 and error in Swift 6.
                        self.test()
                    }

                    func innerFunc() {
                        // Allowed: https://forums.swift.org/t/why-does-se-0269-have-different-rules-for-inner-closures-vs-inner-functions/64334/2
                        self.test()
                    }

                    innerFunc()
                }
            }
        }
        """

        let output = """
        class Test {
            func doWork(_ escaping: @escaping () -> Void) {
                escaping()
            }

            func test() {
                doWork { [self] in
                    doWork {
                        // Not allowed. Warning in Swift 5 and error in Swift 6.
                        self.test()
                    }

                    func innerFunc() {
                        // Allowed: https://forums.swift.org/t/why-does-se-0269-have-different-rules-for-inner-closures-vs-inner-functions/64334/2
                        test()
                    }

                    innerFunc()
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf, options: FormatOptions(swiftVersion: "5.8"))
    }

    func testPreservesSelfInNestedFunctionInWeakSelfClosure() {
        let input = """
        class Test {
            func doWork(_ escaping: @escaping () -> Void) {
                escaping()
            }

            func test() {
                doWork { [weak self] in
                    func innerFunc() {
                        self?.test()
                    }

                    guard let self else {
                        return
                    }

                    self.test()

                    func innerFunc() {
                        self.test()
                    }

                    self.test()
                }
            }
        }
        """

        let output = """
        class Test {
            func doWork(_ escaping: @escaping () -> Void) {
                escaping()
            }

            func test() {
                doWork { [weak self] in
                    func innerFunc() {
                        self?.test()
                    }

                    guard let self else {
                        return
                    }

                    test()

                    func innerFunc() {
                        self.test()
                    }

                    test()
                }
            }
        }
        """

        testFormatting(for: input, output, rule: .redundantSelf,
                       options: FormatOptions(swiftVersion: "5.8"))
    }

    func testRedundantSelfAfterScopedImport() {
        let input = """
        import struct Foundation.Date

        struct Foo {
            let foo: String
            init(bar: String) {
                self.foo = bar
            }
        }
        """
        let output = """
        import struct Foundation.Date

        struct Foo {
            let foo: String
            init(bar: String) {
                foo = bar
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantSelf)
    }

    func testRedundantSelfNotConfusedByParameterPack() {
        let input = """
        func pairUp<each T, each U>(firstPeople: repeat each T, secondPeople: repeat each U) -> (repeat (first: each T, second: each U)) {
            (repeat (each firstPeople, each secondPeople))
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testRedundantSelfNotConfusedByStaticAfterSwitch() {
        let input = """
        public final class MyClass {
            private static func privateStaticFunction1() -> Bool {
                switch Result(catching: { try someThrowingFunction() }) {
                case .success:
                    return true
                case .failure:
                    return false
                }
            }

            private static func privateStaticFunction2() -> Bool {
                return false
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options, exclude: [.enumNamespaces])
    }

    func testRedundantSelfNotConfusedByMainActor() {
        let input = """
        class Test {
            private var p: Int

            func f() {
                self.f2(
                    closure: { @MainActor [weak self] p in
                        print(p)
                    }
                )
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: .redundantSelf, options: options)
    }

    func testNoMistakeProtocolClassModifierForClassFunction() {
        let input = "protocol Foo: class {}\nfunc bar() {}"
        XCTAssertNoThrow(try format(input, rules: [.redundantSelf]))
        XCTAssertNoThrow(try format(input, rules: FormatRules.all))
    }

    func testRedundantSelfParsingBug3() {
        let input = """
        final class ViewController {
          private func bottomBarModels() -> [BarModeling] {
            if let url = URL(string: "..."){
              // ...
            }

            models.append(
              Footer.barModel(
                content: FooterContent(
                  primaryTitleText: "..."),
                style: style)
                .setBehaviors { context in
                  context.view.primaryButtonState = self.isLoading ? .waiting : .normal
                  context.view.primaryActionHandler = { [weak self] _ in
                    self?.acceptButtonWasTapped()
                  }
                })
          }

        }
        """
        XCTAssertNoThrow(try format(input, rules: [.redundantSelf]))
    }

    func testRedundantSelfParsingBug4() {
        let input = """
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            guard let row: Row = promotionSections[indexPath.section][indexPath.row] else { return UITableViewCell() }
            let cell = tableView.dequeueReusable(RowTableViewCell.self, forIndexPath: indexPath)
            cell.update(row: row)
            return cell
        }
        """
        XCTAssertNoThrow(try format(input, rules: [.redundantSelf]))
    }

    func testRedundantSelfParsingBug5() {
        let input = """
        Button.primary(
            title: "Title",
            tapHandler: { [weak self] in
                self?.dismissBlock? {
                    // something
                }
            }
        )
        """
        XCTAssertNoThrow(try format(input, rules: [.redundantSelf]))
    }

    func testRedundantSelfParsingBug6() {
        let input = """
        if let foo = bar, foo.tracking[jsonDict: "something"] != nil {}
        """
        XCTAssertNoThrow(try format(input, rules: [.redundantSelf]))
    }

    func testUnderstandsParameterPacks_issue_1992() {
        let input = """
        @resultBuilder
        public enum DirectoryContentBuilder {
            public static func buildPartialBlock<each Accumulated>(
                accumulated: repeat each Accumulated,
                next: some DirectoryContent
            ) -> some DirectoryContent where repeat each Accumulated: DirectoryContent {
                Accumulate(
                    accumulated: repeat each accumulated,
                    next: next
                )
            }

            public static func buildEither<First, Second>(
                first component: First
            ) -> _Either<First, Second> where First: DirectoryContent, Second: DirectoryContent {
                .first(component)
            }

            struct List<Element>: DirectoryContent where Element: DirectoryContent {
                init(_ list: [Element]) {
                    self._list = list
                }

                private let _list: [Element]
            }
        }
        """

        let output = """
        @resultBuilder
        public enum DirectoryContentBuilder {
            public static func buildPartialBlock<each Accumulated>(
                accumulated: repeat each Accumulated,
                next: some DirectoryContent
            ) -> some DirectoryContent where repeat each Accumulated: DirectoryContent {
                Accumulate(
                    accumulated: repeat each accumulated,
                    next: next
                )
            }

            public static func buildEither<First, Second>(
                first component: First
            ) -> _Either<First, Second> where First: DirectoryContent, Second: DirectoryContent {
                .first(component)
            }

            struct List<Element>: DirectoryContent where Element: DirectoryContent {
                init(_ list: [Element]) {
                    _list = list
                }

                private let _list: [Element]
            }
        }
        """

        testFormatting(for: input, output, rule: .redundantSelf)
    }
}
