//
//  RedundantViewBuilderTests.swift
//  SwiftFormatTests
//
//  Created by Miguel Jimenez on 2025-12-14.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class RedundantViewBuilderTests: XCTestCase {
    // MARK: - View body tests

    func testRemoveRedundantViewBuilderOnViewBody() {
        let input = """
        struct MyView: View {
            @ViewBuilder
            var body: some View {
                Text("foo")
                Text("bar")
            }
        }
        """
        let output = """
        struct MyView: View {
            var body: some View {
                Text("foo")
                Text("bar")
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantViewBuilder)
    }

    func testRemoveRedundantViewBuilderOnViewModifierBody() {
        let input = """
        struct MyModifier: ViewModifier {
            @ViewBuilder
            func body(content: Content) -> some View {
                content
                    .foregroundColor(.red)
            }
        }
        """
        let output = """
        struct MyModifier: ViewModifier {
            func body(content: Content) -> some View {
                content
                    .foregroundColor(.red)
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantViewBuilder)
    }

    // MARK: - Single expression tests

    func testRemoveRedundantViewBuilderOnSingleExpression() {
        let input = """
        struct MyView: View {
            var body: some View {
                helper
            }

            @ViewBuilder
            var helper: some View {
                VStack {
                    Text("baaz")
                    Text("quux")
                }
            }
        }
        """
        let output = """
        struct MyView: View {
            var body: some View {
                helper
            }

            var helper: some View {
                VStack {
                    Text("baaz")
                    Text("quux")
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantViewBuilder)
    }

    func testRemoveRedundantViewBuilderOnSingleExpressionClosure() {
        let input = """
        struct MyView: View {
            @ViewBuilder
            var helper: some View {
                Color.red
            }
        }
        """
        let output = """
        struct MyView: View {
            var helper: some View {
                Color.red
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantViewBuilder)
    }

    // MARK: - Keep @ViewBuilder when needed

    func testKeepViewBuilderWithMultipleTopLevelViews() {
        let input = """
        struct MyView: View {
            @ViewBuilder
            var helper: some View {
                Text("foo")
                Text("bar")
            }
        }
        """
        testFormatting(for: input, rule: .redundantViewBuilder)
    }

    func testKeepViewBuilderWithIfElseExpression() {
        let input = """
        struct MyView: View {
            @ViewBuilder
            var helper: some View {
                if condition {
                    Text("foo")
                } else {
                    Image("bar")
                }
            }
        }
        """
        testFormatting(for: input, rule: .redundantViewBuilder)
    }

    func testKeepViewBuilderWithSwitchExpression() {
        let input = """
        struct MyView: View {
            @ViewBuilder
            var helper: some View {
                switch value {
                case .foo:
                    Text("foo")
                case .bar:
                    Image("bar")
                }
            }
        }
        """
        testFormatting(for: input, rule: .redundantViewBuilder)
    }

    func testKeepViewBuilderWithForEachAndViews() {
        let input = """
        struct MyView: View {
            @ViewBuilder
            var helper: some View {
                ForEach(items) { item in
                    Text(item.name)
                }
                Divider()
            }
        }
        """
        testFormatting(for: input, rule: .redundantViewBuilder)
    }

    // MARK: - Edge cases

    func testRemoveRedundantViewBuilderBeforeComputedProperty() {
        let input = """
        struct MyView: View {
            @ViewBuilder var body: some View {
                Text("Hello")
            }
        }
        """
        let output = """
        struct MyView: View {
            var body: some View {
                Text("Hello")
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantViewBuilder)
    }

    func testKeepViewBuilderOnNonBodyProperty() {
        let input = """
        struct MyView: View {
            var body: some View {
                content
            }

            @ViewBuilder
            var content: some View {
                Text("foo")
                Text("bar")
            }
        }
        """
        testFormatting(for: input, rule: .redundantViewBuilder)
    }

    func testRemoveRedundantViewBuilderInNestedType() {
        let input = """
        struct OuterView: View {
            var body: some View {
                InnerView()
            }

            struct InnerView: View {
                @ViewBuilder
                var body: some View {
                    Text("Inner")
                }
            }
        }
        """
        let output = """
        struct OuterView: View {
            var body: some View {
                InnerView()
            }

            struct InnerView: View {
                var body: some View {
                    Text("Inner")
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantViewBuilder)
    }

    func testKeepViewBuilderOnPropertyWithModifier() {
        let input = """
        struct MyView: View {
            @ViewBuilder
            private var content: some View {
                Text("foo")
                Text("bar")
            }
        }
        """
        testFormatting(for: input, rule: .redundantViewBuilder)
    }

    func testRemoveRedundantViewBuilderWithComplexSingleExpression() {
        let input = """
        struct MyView: View {
            @ViewBuilder
            var helper: some View {
                Text("Hello")
                    .font(.title)
                    .foregroundColor(.blue)
                    .padding()
            }
        }
        """
        let output = """
        struct MyView: View {
            var helper: some View {
                Text("Hello")
                    .font(.title)
                    .foregroundColor(.blue)
                    .padding()
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantViewBuilder)
    }
}
