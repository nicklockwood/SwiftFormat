//
//  RedundantSwiftUIGroupTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 2025-12-19.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class RedundantSwiftUIGroupTests: XCTestCase {
    func testRemoveRedundantGroupInViewBody() {
        let input = """
        struct MyView: View {
            var body: some View {
                Group {
                    Text("foo")
                    Text("bar")
                }
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
        testFormatting(for: input, [output], rules: [.redundantSwiftUIGroup, .indent])
    }

    func testRemoveRedundantGroupInViewModifierBody() {
        let input = """
        struct MyModifier: ViewModifier {
            func body(content: Content) -> some View {
                Group {
                    content
                    Text("overlay")
                }
            }
        }
        """
        let output = """
        struct MyModifier: ViewModifier {
            func body(content: Content) -> some View {
                content
                Text("overlay")
            }
        }
        """
        testFormatting(for: input, [output], rules: [.redundantSwiftUIGroup, .indent])
    }

    func testKeepGroupWithModifiers() {
        let input = """
        struct MyView: View {
            var body: some View {
                Group {
                    Text("foo")
                    Text("bar")
                }
                .foregroundColor(.red)
            }
        }
        """
        testFormatting(for: input, rule: .redundantSwiftUIGroup)
    }

    func testKeepGroupWithPaddingModifier() {
        let input = """
        struct MyView: View {
            var body: some View {
                Group {
                    Text("foo")
                    Text("bar")
                }
                .padding()
            }
        }
        """
        testFormatting(for: input, rule: .redundantSwiftUIGroup)
    }

    func testRemoveGroupWithSingleViewAndModifiers() {
        let input = """
        struct MyView: View {
            var body: some View {
                Group {
                    Text(status)
                }
                .padding(.horizontal, 8)
                .background(.thinMaterial, in: Capsule())
            }
        }
        """
        let output = """
        struct MyView: View {
            var body: some View {
                Text(status)
                    .padding(.horizontal, 8)
                    .background(.thinMaterial, in: Capsule())
            }
        }
        """
        testFormatting(for: input, [output], rules: [.redundantSwiftUIGroup, .indent])
    }

    func testKeepGroupWithMultipleViewsAndModifiers() {
        // Modifiers apply to each view individually if the Group is removed
        let input = """
        struct MyView: View {
            var body: some View {
                Group {
                    Text("foo")
                    Text("bar")
                }
                .padding(.horizontal, 8)
                .background(.thinMaterial, in: Capsule())
            }
        }
        """
        testFormatting(for: input, rules: [.redundantSwiftUIGroup, .indent])
    }

    func testKeepGroupWithConditionalAndModifiers() {
        // A conditional needs the Group to combine branches into a single modifiable view
        let input = """
        struct MyView: View {
            var body: some View {
                Group {
                    if condition {
                        Text("foo")
                    } else {
                        Text("bar")
                    }
                }
                .padding()
            }
        }
        """
        testFormatting(for: input, rules: [.redundantSwiftUIGroup, .indent])
    }

    func testRemoveGroupWithForEachAndModifiers() {
        // ForEach is itself a single view, so the modifiers apply to it as a whole
        let input = """
        struct MyView: View {
            var body: some View {
                Group {
                    ForEach(items) { item in
                        Text(item.name)
                    }
                }
                .padding()
            }
        }
        """
        let output = """
        struct MyView: View {
            var body: some View {
                ForEach(items) { item in
                    Text(item.name)
                }
                .padding()
            }
        }
        """
        testFormatting(for: input, [output], rules: [.redundantSwiftUIGroup, .indent])
    }

    func testRemoveGroupWithViewContainingTrailingClosureAndModifiers() {
        let input = """
        struct MyView: View {
            var body: some View {
                Group {
                    Button("Tap") {
                        handleTap()
                    }
                }
                .padding()
            }
        }
        """
        let output = """
        struct MyView: View {
            var body: some View {
                Button("Tap") {
                    handleTap()
                }
                .padding()
            }
        }
        """
        testFormatting(for: input, [output], rules: [.redundantSwiftUIGroup, .indent])
    }

    func testRemoveGroupWithSingleExpression() {
        let input = """
        struct MyView: View {
            var body: some View {
                Group {
                    Text("Hello")
                }
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
        testFormatting(for: input, [output], rules: [.redundantSwiftUIGroup, .indent])
    }

    func testRemoveGroupInHelperPropertyWithViewBuilder() {
        let input = """
        struct MyView: View {
            var body: some View {
                content
            }

            @ViewBuilder
            var content: some View {
                Group {
                    Text("foo")
                    Text("bar")
                }
            }
        }
        """
        let output = """
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
        testFormatting(for: input, [output], rules: [.redundantSwiftUIGroup, .indent])
    }

    func testAddViewBuilderWhenRemovingGroupFromHelper() {
        // Without @ViewBuilder, we need to add it when removing Group with multiple views
        let input = """
        struct MyView: View {
            var body: some View {
                content
            }

            var content: some View {
                Group {
                    Text("foo")
                    Text("bar")
                }
            }
        }
        """
        let output = """
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
        testFormatting(for: input, [output], rules: [.redundantSwiftUIGroup, .indent])
    }

    func testAddViewBuilderAfterComment() {
        // @ViewBuilder should be added after comments, not before
        let input = """
        struct MyView: View {
            var body: some View {
                content
            }

            // MARK: Private

            private var content: some View {
                Group {
                    Text("foo")
                    Text("bar")
                }
            }
        }
        """
        let output = """
        struct MyView: View {
            var body: some View {
                content
            }

            // MARK: Private

            @ViewBuilder
            private var content: some View {
                Text("foo")
                Text("bar")
            }
        }
        """
        testFormatting(for: input, [output], rules: [.redundantSwiftUIGroup, .indent])
    }

    func testAddViewBuilderDoesntInsertBlankLineWithOrganizeDeclarations() {
        // Inserting @ViewBuilder must not leave the declaration line unindented, which
        // previously combined with organizeDeclarations to produce a spurious blank line
        // between the attribute and the declaration.
        let input = """
        struct MyView: View {
          @FocusState private var streetFieldFocused: Bool
          @AccessibilityFocusState private var isExpandedContentFocused: Bool

          private var formGroup: some View {
            Group {
              Text("foo")
              Text("bar")
            }
          }
        }
        """
        let output = """
        struct MyView: View {
          @FocusState private var streetFieldFocused: Bool
          @AccessibilityFocusState private var isExpandedContentFocused: Bool

          @ViewBuilder
          private var formGroup: some View {
            Text("foo")
            Text("bar")
          }
        }
        """
        var options = FormatOptions.default
        options.indent = "  "
        testFormatting(
            for: input, [output],
            rules: [.redundantSwiftUIGroup, .organizeDeclarations, .indent],
            options: options,
            exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope]
        )
    }

    func testRemoveGroupInHelperPropertyWithSingleExpression() {
        // Single expression doesn't need @ViewBuilder, so Group can be removed
        let input = """
        struct MyView: View {
            var body: some View {
                content
            }

            var content: some View {
                Group {
                    Text("Hello")
                }
            }
        }
        """
        let output = """
        struct MyView: View {
            var body: some View {
                content
            }

            var content: some View {
                Text("Hello")
            }
        }
        """
        testFormatting(for: input, [output], rules: [.redundantSwiftUIGroup, .indent])
    }

    func testRemoveGroupWithParentheses() {
        let input = """
        struct MyView: View {
            var body: some View {
                Group() {
                    Text("foo")
                    Text("bar")
                }
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
        testFormatting(for: input, [output], rules: [.redundantSwiftUIGroup, .indent])
    }

    func testRemoveGroupWithContentLabel() {
        let input = """
        struct MyView: View {
            var body: some View {
                Group(content: {
                    Text("foo")
                    Text("bar")
                })
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
        testFormatting(for: input, [output], rules: [.redundantSwiftUIGroup, .indent])
    }

    func testKeepGroupWhenNotTopLevel() {
        let input = """
        struct MyView: View {
            var body: some View {
                VStack {
                    Group {
                        Text("foo")
                        Text("bar")
                    }
                }
            }
        }
        """
        testFormatting(for: input, rule: .redundantSwiftUIGroup)
    }

    func testKeepGroupInNonViewType() {
        let input = """
        struct MyHelper {
            var content: some View {
                Group {
                    Text("foo")
                    Text("bar")
                }
            }
        }
        """
        testFormatting(for: input, rule: .redundantSwiftUIGroup)
    }

    func testRemoveGroupInNestedView() {
        let input = """
        struct OuterView: View {
            var body: some View {
                InnerView()
            }

            struct InnerView: View {
                var body: some View {
                    Group {
                        Text("Inner")
                    }
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
        testFormatting(for: input, [output], rules: [.redundantSwiftUIGroup, .indent])
    }

    func testAddViewBuilderWhenRemovingGroupWithConditional() {
        // Conditional expressions need @ViewBuilder, so add it when removing Group
        let input = """
        struct MyView: View {
            var body: some View {
                content
            }

            var content: some View {
                Group {
                    if condition {
                        Text("foo")
                    } else {
                        Text("bar")
                    }
                }
            }
        }
        """
        let output = """
        struct MyView: View {
            var body: some View {
                content
            }

            @ViewBuilder
            var content: some View {
                if condition {
                    Text("foo")
                } else {
                    Text("bar")
                }
            }
        }
        """
        testFormatting(for: input, [output], rules: [.redundantSwiftUIGroup, .indent])
    }

    func testRemoveGroupWithConditionalInViewBody() {
        // View.body has implied @ViewBuilder, so Group can be removed
        let input = """
        struct MyView: View {
            var body: some View {
                Group {
                    if condition {
                        Text("foo")
                    } else {
                        Text("bar")
                    }
                }
            }
        }
        """
        let output = """
        struct MyView: View {
            var body: some View {
                if condition {
                    Text("foo")
                } else {
                    Text("bar")
                }
            }
        }
        """
        testFormatting(for: input, [output], rules: [.redundantSwiftUIGroup, .indent])
    }

    func testKeepGroupWithSubviewsArgument() {
        let input = """
        struct SeparatedHStack: View {
            var body: some View {
                Group(subviews: content) { subviews in
                    HStack {
                        ForEach(subviews.indices, id: \\.self) { index in
                            subviews[index]
                        }
                    }
                }
            }
        }
        """
        testFormatting(for: input, rule: .redundantSwiftUIGroup)
    }

    func testKeepGroupWithSectionsArgument() {
        let input = """
        struct MyList: View {
            var body: some View {
                Group(sections: content) { sections in
                    ForEach(sections) { section in
                        Text(section.header)
                    }
                }
            }
        }
        """
        testFormatting(for: input, rule: .redundantSwiftUIGroup)
    }
}
