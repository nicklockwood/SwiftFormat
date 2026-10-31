//
//  ResidualPrintTests.swift
//  SwiftFormatTests
//
//  Created by Yang Bai on 29/10/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class ResidualPrintTests: XCTestCase {
    func testPrintRemoved() {
        let input = """
        func loadUser(id: String) async throws -> User {
            let user = try await api.user(id: id)
            print("loaded user:", user)
            cache[id] = user
            return user
        }
        """
        let output = """
        func loadUser(id: String) async throws -> User {
            let user = try await api.user(id: id)
            cache[id] = user
            return user
        }
        """
        testFormatting(for: input, output, rule: .residualPrint)
    }

    func testDebugPrintRemoved() {
        let input = """
        func update() {
            debugPrint(self)
            refresh()
        }
        """
        let output = """
        func update() {
            refresh()
        }
        """
        testFormatting(for: input, output, rule: .residualPrint)
    }

    func testMultilinePrintRemoved() {
        let input = """
        func update() {
            refresh()
            print(
                "state:",
                state,
                separator: " "
            )
        }
        """
        let output = """
        func update() {
            refresh()
        }
        """
        testFormatting(for: input, output, rule: .residualPrint)
    }

    func testPrintInClosureRemoved() {
        let input = """
        let ids = items.map { item in
            print(item)
            return item.id
        }
        """
        let output = """
        let ids = items.map { item in
            item.id
        }
        """
        testFormatting(for: input, [output], rules: [.residualPrint, .redundantReturn])
    }

    func testPrintInSwitchCaseRemoved() {
        let input = """
        switch state {
        case .loading:
            print("loading")
            showSpinner()

        default:
            break
        }
        """
        let output = """
        switch state {
        case .loading:
            showSpinner()

        default:
            break
        }
        """
        testFormatting(for: input, output, rule: .residualPrint)
    }

    func testOnlyStatementInFunctionNotRemoved() {
        let input = """
        func log(_ message: String) {
            print(message)
        }
        """
        testFormatting(for: input, rule: .residualPrint)
    }

    func testOnlyStatementInSwitchCaseNotRemoved() {
        let input = """
        switch state {
        case .loading:
            print("loading")
        default:
            showSpinner()
        }
        """
        testFormatting(for: input, rule: .residualPrint)
    }

    func testOnlyStatementInClosureNotRemoved() {
        let input = """
        handler = { item in
            print(item)
        }
        """
        testFormatting(for: input, rule: .residualPrint)
    }

    func testLastRemainingStatementInSwitchCaseNotRemoved() {
        let input = """
        switch state {
        case .loading:
            print("loading")
            print(progress)

        default:
            showSpinner()
        }
        """
        let output = """
        switch state {
        case .loading:
            print(progress)

        default:
            showSpinner()
        }
        """
        testFormatting(for: input, output, rule: .residualPrint)
    }

    func testPrintUsingAnonymousClosureArgumentNotRemoved() {
        let input = """
        let ids = items.map {
            print("item: \\($0)")
            return $0.id
        }
        """
        testFormatting(for: input, rule: .residualPrint)
    }

    func testPrintToStreamNotRemoved() {
        let input = """
        func report() {
            print("done", to: &standardError)
            exit(0)
        }
        """
        testFormatting(for: input, rule: .residualPrint)
    }

    func testTopLevelPrintNotRemoved() {
        let input = """
        let greeting = "Hello"
        print(greeting)
        """
        testFormatting(for: input, rule: .residualPrint)
    }

    func testPrintInsideIfDirectiveNotRemoved() {
        let input = """
        func update() {
            #if DEBUG
                print(state)
            #endif
            refresh()
        }
        """
        testFormatting(for: input, rule: .residualPrint)
    }

    func testPrintWithTrailingCommentNotRemoved() {
        let input = """
        func update() {
            print(state) // keep until #123 is fixed
            refresh()
        }
        """
        testFormatting(for: input, rule: .residualPrint)
    }

    func testPrintSharingLineWithOtherCodeNotRemoved() {
        let input = """
        func update() {
            refresh(); print(state)
            redraw()
        }
        """
        testFormatting(for: input, rule: .residualPrint, exclude: [.semicolons])
    }

    func testPrintArgumentOfAnotherCallNotRemoved() {
        let input = """
        func update() {
            perform(
                print(state)
            )
            refresh()
        }
        """
        testFormatting(for: input, rule: .residualPrint)
    }

    func testPrintAfterOperatorNotRemoved() {
        let input = """
        func update() {
            let result = value ??
                print(state)
            refresh()
        }
        """
        testFormatting(for: input, rule: .residualPrint)
    }

    func testMemberPrintNotRemoved() {
        let input = """
        func update() {
            Swift.print(state)
            logger.print(state)
            refresh()
        }
        """
        testFormatting(for: input, rule: .residualPrint)
    }

    func testPrintNotRemovedWhenFileDeclaresPrintFunction() {
        let input = """
        struct Logger {
            func print(_ message: String) {
                lines.append(message)
            }

            func flush() {
                print("flushing")
                lines.removeAll()
            }
        }
        """
        testFormatting(for: input, rule: .residualPrint)
    }
}
