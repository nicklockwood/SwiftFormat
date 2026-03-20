//
//  RedundantEmptyViewTests.swift
//  SwiftFormatTests
//
//  Created by Manuel Lopez on 2026-03-19.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class RedundantEmptyViewTests: XCTestCase {
    func testRemoveRedundantEmptyViewElseInViewBody() {
        let input = """
        struct ContentView: View {
            var body: some View {
                if condition {
                    Text("Hello")
                } else {
                    EmptyView()
                }
            }
        }
        """
        let output = """
        struct ContentView: View {
            var body: some View {
                if condition {
                    Text("Hello")
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantEmptyView)
    }

    func testRemoveInlineRedundantEmptyViewElseInViewBuilderProperty() {
        let input = """
        struct ContentView: View {
            @ViewBuilder
            var description: some View {
                if condition {
                    Text("Hello")
                } else { 
                    EmptyView() 
                }
            }
        }
        """
        let output = """
        struct ContentView: View {
            @ViewBuilder
            var description: some View {
                if condition {
                    Text("Hello")
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantEmptyView)
    }

    func testRemoveRedundantEmptyViewElseInNestedResultBuilder() {
        let input = """
        struct ContentView: View {
            let items: [Bool]

            var body: some View {
                ForEach(items.indices, id: \\.self) { index in
                    if items[index] {
                        Text("\\(index)")
                    } else {
                        EmptyView()
                    }
                }
            }
        }
        """
        let output = """
        struct ContentView: View {
            let items: [Bool]

            var body: some View {
                ForEach(items.indices, id: \\.self) { index in
                    if items[index] {
                        Text("\\(index)")
                    }
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantEmptyView)
    }

    func testDoNotRemoveRedundantEmptyViewElseOutsideResultBuilder() {
        let input = """
        func render(condition: Bool) {
            if condition {
                print("Hello")
            } else {
                EmptyView()
            }
        }
        """
        testFormatting(for: input, rule: .redundantEmptyView)
    }

    func testDoNotRemoveElseContainingComment() {
        let input = """
        struct ContentView: View {
            var body: some View {
                if condition {
                    Text("Hello")
                } else {
                    // Keep this branch for documentation
                    EmptyView()
                }
            }
        }
        """
        testFormatting(for: input, rule: .redundantEmptyView)
    }

    func testRemoveRedundantEmptyViewElseInIfElseIfElseChain() {
        let input = """
        struct ContentView: View {
            var body: some View {
                ForEach(items, id: \\.self) { item in
                    if item.type == .primary {
                        PrimaryView(item: item)
                    } else if item.type == .secondary {
                        SecondaryView(item: item)
                    } else {
                        EmptyView()
                    }
                }
            }
        }
        """
        let output = """
        struct ContentView: View {
            var body: some View {
                ForEach(items, id: \\.self) { item in
                    if item.type == .primary {
                        PrimaryView(item: item)
                    } else if item.type == .secondary {
                        SecondaryView(item: item)
                    }
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantEmptyView)
    }

    func testRemoveOnlyInnerRedundantEmptyViewElseInNestedIf() {
        let input = """
        struct ContentView: View {
            @ViewBuilder
            func visibleSection(fieldID: String?, makeSection: () -> some View) -> some View {
                if let fieldID {
                    if isVisible(fieldID) {
                        makeSection()
                    } else {
                        EmptyView()
                    }
                } else {
                    makeSection()
                }
            }
        }
        """
        let output = """
        struct ContentView: View {
            @ViewBuilder
            func visibleSection(fieldID: String?, makeSection: () -> some View) -> some View {
                if let fieldID {
                    if isVisible(fieldID) {
                        makeSection()
                    }
                } else {
                    makeSection()
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantEmptyView)
    }

    func testRemoveFullyQualifiedSwiftUIEmptyView() {
        let input = """
        struct ContentView: View {
            var body: some View {
                if condition {
                    Text("Hello")
                } else {
                    SwiftUI.EmptyView()
                }
            }
        }
        """
        let output = """
        struct ContentView: View {
            var body: some View {
                if condition {
                    Text("Hello")
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantEmptyView)
    }

    func testDoNotRemoveElseWithModifiedEmptyView() {
        let input = """
        struct ContentView: View {
            var body: some View {
                if condition {
                    Text("Hello")
                } else {
                    EmptyView()
                        .hidden()
                }
            }
        }
        """
        testFormatting(for: input, rule: .redundantEmptyView)
    }
}
