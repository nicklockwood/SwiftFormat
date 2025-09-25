//
//  RedundantLetTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 12/14/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class RedundantLetTests: XCTestCase {
    func testRemoveRedundantLet() {
        let input = """
        let _ = bar {}
        """
        let output = """
        _ = bar {}
        """
        testFormatting(for: input, output, rule: .redundantLet)
    }

    func testNoRemoveLetWithType() {
        let input = """
        let _: String = bar {}
        """
        testFormatting(for: input, rule: .redundantLet)
    }

    func testRemoveRedundantLetInCase() {
        let input = """
        if case .foo(let _) = bar {}
        """
        let output = """
        if case .foo(_) = bar {}
        """
        testFormatting(for: input, output, rule: .redundantLet, exclude: [.redundantPattern])
    }

    func testRemoveRedundantVarsInCase() {
        let input = """
        if case .foo(var _, var /* unused */ _) = bar {}
        """
        let output = """
        if case .foo(_, /* unused */ _) = bar {}
        """
        testFormatting(for: input, output, rule: .redundantLet)
    }

    func testNoRemoveLetInIf() {
        let input = """
        if let _ = foo {}
        """
        testFormatting(for: input, rule: .redundantLet)
    }

    func testNoRemoveLetInMultiIf() {
        let input = """
        if foo == bar, /* comment! */ let _ = baz {}
        """
        testFormatting(for: input, rule: .redundantLet)
    }

    func testNoRemoveLetInGuard() {
        let input = """
        guard let _ = foo else {}
        """
        testFormatting(for: input, rule: .redundantLet,
                       exclude: [.wrapConditionalBodies])
    }

    func testNoRemoveLetInWhile() {
        let input = """
        while let _ = foo {}
        """
        testFormatting(for: input, rule: .redundantLet)
    }

    func testNoRemoveLetInViewBuilder() {
        let input = """
        HStack {
            let _ = print("Hi")
            Text("Some text")
        }
        """
        testFormatting(for: input, rule: .redundantLet)
    }

    func testNoRemoveLetInViewBuilderModifier() {
        let input = """
        VStack {
            Text("Some text")
        }
        .overlay(
            HStack {
                let _ = print("")
            }
        )
        """
        testFormatting(for: input, rule: .redundantLet)
    }

    func testNoRemoveLetInIfStatementInViewBuilder() {
        let input = """
        VStack(spacing: 0) {
            if visible == "YES" {
                let _ = print("")
            }
        }
        """
        testFormatting(for: input, rule: .redundantLet)
    }

    func testNoRemoveLetInCondIfStatementInViewBuilder() {
        let input = """
        VStack {
            #if VIEW_PERF_LOGGING
                let _ = Self._printChanges()
            #else
                let _ = Self._printChanges()
            #endif
            let _ = Self._printChanges()
        }
        """
        testFormatting(for: input, rule: .redundantLet)
    }

    func testNoRemoveLetInSwitchStatementInViewBuilder() {
        let input = """
        struct TestView: View {
            var body: some View {
                #if DEBUG
                    let _ = Self._printChanges()
                #endif
                var foo = ""
                switch (self.min, self.max) {
                case let (nil, max as Int):
                    let _ = {
                        foo = "\\(max)"
                    }()

                default:
                    EmptyView()
                }

                Text(foo)
            }
        }
        """
        testFormatting(for: input, rule: .redundantLet)
    }

    func testNoRemoveAsyncLet() {
        let input = """
        async let _ = foo()
        """
        testFormatting(for: input, rule: .redundantLet)
    }

    func testNoRemoveLetImmediatelyAfterMainActorAttribute() {
        let input = """
        let foo = bar { @MainActor
            let _ = try await baz()
        }
        """
        testFormatting(for: input, rule: .redundantLet)
    }

    func testNoRemoveLetImmediatelyAfterSendableAttribute() {
        let input = """
        let foo = bar { @Sendable
            let _ = try await baz()
        }
        """
        testFormatting(for: input, rule: .redundantLet)
    }

    func testPreserveLetInPreviewMacro() {
        let input = """
        #Preview {
            let _ = 1234
            Text("Test")
        }

        #Preview(name: "Test") {
            let _ = 1234
            Text("Test")
        }
        """
        testFormatting(for: input, rule: .redundantLet)
    }
}
