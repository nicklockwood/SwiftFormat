//
//  PreferLazyMapTests.swift
//  SwiftFormatTests
//
//  Created by Jon Parise on 8/19/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation
import XCTest
@testable import SwiftFormat

final class PreferLazyMapTests: XCTestCase {
    func testInsertsLazyBeforeMin() {
        let input = """
        let minY = vertices.map { $0.y }.min()
        """

        let output = """
        let minY = vertices.lazy.map { $0.y }.min()
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyBeforeMax() {
        let input = """
        let maxX = boxes.map { $0.maxX }.max()
        """

        let output = """
        let maxX = boxes.lazy.map { $0.maxX }.max()
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyBeforeMinWithComparator() {
        let input = """
        let earliest = events.map { $0.date }.min(by: { $0 < $1 })
        """

        let output = """
        let earliest = events.lazy.map { $0.date }.min(by: { $0 < $1 })
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyBeforeReduce() {
        let input = """
        let total = items.map { $0.price }.reduce(0, +)
        """

        let output = """
        let total = items.lazy.map { $0.price }.reduce(0, +)
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyBeforeJoined() {
        let input = """
        let names = users.map { $0.name }.joined(separator: ", ")
        """

        let output = """
        let names = users.lazy.map { $0.name }.joined(separator: ", ")
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyBeforeContains() {
        let input = """
        let hasZero = items.map { $0.count }.contains(0)
        """

        let output = """
        let hasZero = items.lazy.map { $0.count }.contains(0)
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyBeforeContainsWhere() {
        let input = """
        let hasEmpty = rows.map { $0.title }.contains(where: { $0.isEmpty })
        """

        let output = """
        let hasEmpty = rows.lazy.map { $0.title }.contains(where: { $0.isEmpty })
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyBeforeAllSatisfy() {
        let input = """
        let allPositive = items.map { $0.value }.allSatisfy { $0 > 0 }
        """

        let output = """
        let allPositive = items.lazy.map { $0.value }.allSatisfy { $0 > 0 }
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyBeforeFirstWhere() {
        let input = """
        let firstEmpty = rows.map { $0.title }.first(where: { $0.isEmpty })
        """

        let output = """
        let firstEmpty = rows.lazy.map { $0.title }.first(where: { $0.isEmpty })
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyBeforeFirstWithTrailingClosure() {
        let input = """
        let firstEmpty = rows.map { $0.title }.first { $0.isEmpty }
        """

        let output = """
        let firstEmpty = rows.lazy.map { $0.title }.first { $0.isEmpty }
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyWithNilCoalescing() {
        let input = """
        let floorOffset = amenities.map { $0.box.minY }.min() ?? 0
        """

        let output = """
        let floorOffset = amenities.lazy.map { $0.box.minY }.min() ?? 0
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyForComputedExpressionBody() {
        let input = """
        let area = boxes.map { $0.width * $0.height }.max()
        """

        let output = """
        let area = boxes.lazy.map { $0.width * $0.height }.max()
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyForNamedClosureParameter() {
        let input = """
        let minY = vertices.map { item in item.y }.min()
        """

        let output = """
        let minY = vertices.lazy.map { item in item.y }.min()
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyForChainedReceiver() {
        let input = """
        let minY = model.scene.vertices.map { $0.y }.min()
        """

        let output = """
        let minY = model.scene.vertices.lazy.map { $0.y }.min()
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testPreservesIdentityMap() {
        let input = """
        let smallest = values.map { $0 }.min()
        """

        testFormatting(for: input, rule: .preferLazyMap)
    }

    func testPreservesJoinedWithoutSeparator() {
        let input = """
        let combined = parts.map { $0.title }.joined()
        """

        testFormatting(for: input, rule: .preferLazyMap)
    }

    func testPreservesImplicitSelfMethodCall() {
        let input = """
        final class Generator {
            func render(_ value: Int) -> String {
                "\\(value)"
            }

            func synthesize() -> String {
                values.map { render($0) }.joined(separator: ",")
            }
        }
        """

        testFormatting(for: input, rule: .preferLazyMap)
    }

    func testInsertsLazyForArgumentOnlyBodyInClass() {
        let input = """
        final class Generator {
            func smallest() -> Double? {
                vertices.map { $0.y }.min()
            }
        }
        """

        let output = """
        final class Generator {
            func smallest() -> Double? {
                vertices.lazy.map { $0.y }.min()
            }
        }
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyForImplicitSelfInStruct() {
        let input = """
        struct Generator {
            func render(_ value: Int) -> String {
                "\\(value)"
            }

            func synthesize() -> String {
                values.map { render($0) }.joined(separator: ",")
            }
        }
        """

        let output = """
        struct Generator {
            func render(_ value: Int) -> String {
                "\\(value)"
            }

            func synthesize() -> String {
                values.lazy.map { render($0) }.joined(separator: ",")
            }
        }
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyForImplicitSelfInEnum() {
        let input = """
        enum Generator {
            static func synthesize() -> String {
                values.map { "\\(indentation)\\($0)" }.joined(separator: ",")
            }
        }
        """

        let output = """
        enum Generator {
            static func synthesize() -> String {
                values.lazy.map { "\\(indentation)\\($0)" }.joined(separator: ",")
            }
        }
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyForBareNameOutsideAnyType() {
        let input = """
        func synthesize() -> String {
            values.map { render($0) }.joined(separator: ",")
        }
        """

        let output = """
        func synthesize() -> String {
            values.lazy.map { render($0) }.joined(separator: ",")
        }
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testPreservesImplicitSelfInStructNestedInClass() {
        let input = """
        final class Outer {
            struct Inner {
                func render(_ value: Int) -> String {
                    "\\(value)"
                }
            }

            func synthesize() -> String {
                values.map { render($0) }.joined(separator: ",")
            }
        }
        """

        testFormatting(for: input, rule: .preferLazyMap)
    }

    func testInsertsLazyForImplicitSelfInStructNestedInClass() {
        let input = """
        final class Outer {
            let id = 0

            struct Inner {
                func synthesize() -> String {
                    values.map { render($0) }.joined(separator: ",")
                }
            }
        }
        """

        let output = """
        final class Outer {
            let id = 0

            struct Inner {
                func synthesize() -> String {
                    values.lazy.map { render($0) }.joined(separator: ",")
                }
            }
        }
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testPreservesImplicitSelfInClassNestedInStruct() {
        let input = """
        struct Outer {
            let id = 0

            final class Inner {
                func synthesize() -> String {
                    values.map { render($0) }.joined(separator: ",")
                }
            }
        }
        """

        testFormatting(for: input, rule: .preferLazyMap)
    }

    func testPreservesImplicitSelfInClassWithWhereClause() {
        let input = """
        final class Generator<T: Collection> where T.Element: Equatable {
            func synthesize() -> String {
                values.map { render($0) }.joined(separator: ",")
            }
        }
        """

        testFormatting(for: input, rule: .preferLazyMap)
    }

    func testPreservesImplicitSelfInProtocolExtension() {
        let input = """
        extension Generating where Self: AnyObject {
            func synthesize() -> String {
                values.map { render($0) }.joined(separator: ",")
            }
        }
        """

        testFormatting(for: input, rule: .preferLazyMap)
    }

    func testPreservesImplicitSelfInExtension() {
        let input = """
        extension Generator {
            func synthesize() -> String {
                values.map { render($0) }.joined(separator: ",")
            }
        }
        """

        testFormatting(for: input, rule: .preferLazyMap)
    }

    func testPreservesImplicitSelfInActor() {
        let input = """
        actor Generator {
            func synthesize() -> String {
                values.map { render($0) }.joined(separator: ",")
            }
        }
        """

        testFormatting(for: input, rule: .preferLazyMap)
    }

    func testPreservesImplicitSelfPropertyReference() {
        let input = """
        final class Generator {
            func synthesize() -> String {
                values.map { "\\(indentation)\\($0)" }.joined(separator: ",")
            }
        }
        """

        testFormatting(for: input, rule: .preferLazyMap)
    }

    func testInsertsLazyForGlobalFunctionCallOutsideAnyType() {
        let input = """
        let closest = points.map { hypot($0.x, $0.y) }.min()
        """

        let output = """
        let closest = points.lazy.map { hypot($0.x, $0.y) }.min()
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testInsertsLazyForTypeConversionOutsideAnyType() {
        let input = """
        let joined = ids.map { String($0) }.joined(separator: ",")
        """

        let output = """
        let joined = ids.lazy.map { String($0) }.joined(separator: ",")
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testPreservesGlobalFunctionCallInClass() {
        let input = """
        final class Distances {
            func closest() -> Double? {
                points.map { hypot($0.x, $0.y) }.min()
            }
        }
        """

        testFormatting(for: input, rule: .preferLazyMap)
    }

    func testInsertsLazyForArgumentLabelInMemberCall() {
        let input = """
        let names = users.map { $0.name(includingMiddle: true) }.joined(separator: ", ")
        """

        let output = """
        let names = users.lazy.map { $0.name(includingMiddle: true) }.joined(separator: ", ")
        """

        testFormatting(for: input, output, rule: .preferLazyMap)
    }

    func testPreservesFirstProperty() {
        let input = """
        let firstY = vertices.map { $0.y }.first
        """

        testFormatting(for: input, rule: .preferLazyMap)
    }

    func testPreservesAlreadyLazyReceiver() {
        let input = """
        let minY = vertices.lazy.map { $0.y }.min()
        """

        testFormatting(for: input, rule: .preferLazyMap)
    }

    func testPreservesLazyReceiverReachedByOptionalChaining() {
        let input = """
        let first = listing.edges?.lazy.map { $0.node }.first(where: { $0.id == target })
        """

        testFormatting(for: input, rule: .preferLazyMap)
    }

    func testPreservesReceiverMadeLazyEarlierInTheChain() {
        let input = """
        let minY = vertices.lazy.filter { $0.isVisible }.map { $0.y }.min()
        """

        testFormatting(for: input, rule: .preferLazyMap)
    }

    func testPreservesSorted() {
        let input = """
        let sortedYs = vertices.map { $0.y }.sorted()
        """

        testFormatting(for: input, rule: .preferLazyMap)
    }

    func testPreservesCount() {
        let input = """
        let count = vertices.map { $0.y }.count
        """

        testFormatting(for: input, rule: .preferLazyMap)
    }

    func testPreservesUncalledMinReference() {
        let input = """
        let findMin = vertices.map { $0.y }.min
        """

        testFormatting(for: input, rule: .preferLazyMap)
    }

    func testPreservesNonTrailingClosureMapCall() {
        let input = """
        let minY = vertices.map(projection).min()
        """

        testFormatting(for: input, rule: .preferLazyMap)
    }
}
