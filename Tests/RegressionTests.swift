//
//  RegressionTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 28/03/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

// Split into separate classes for parallelization
class SnapshotRegressionTests: XCTestCase {
    func testRegressionSuite() {
        CLI.print = { message, _ in
            Swift.print(message)
        }
        // NOTE: to update regression suite, run again without `--lint` argument
        XCTAssertEqual(CLI.run(in: projectDirectory.path, with: "Snapshots --unexclude Snapshots --symlinks follow --cache ignore --lint"), .ok)
    }
}

class SourcesRegressionTests: XCTestCase {
    func testRegressionSuite() {
        CLI.print = { message, _ in
            Swift.print(message)
        }
        // NOTE: to update regression suite, run again without `--lint` argument
        XCTAssertEqual(CLI.run(in: projectDirectory.path, with: "Sources --symlinks follow --cache ignore --lint"), .ok)
    }
}

class CacheRegressionTests: XCTestCase {
    func testCache() {
        CLI.print = { message, _ in
            Swift.print(message)
        }
        // NOTE: to update regression suite, run again without `--lint` argument
        let result = CLI.run(in: rulesDirectory.path, with: ". --cache clear --lint")
        XCTAssertEqual(result, .ok)

        // Test cache
        if result == .ok {
            var messages = [String]()
            CLI.print = { message, _ in
                Swift.print(message)
                messages.append(message)
            }
            XCTAssertEqual(CLI.run(in: rulesDirectory.path, with: ". --symlinks follow --lint --verbose"), .ok)
            XCTAssert(messages.contains("-- no changes (cached)"))
        }
    }
}

class InferenceRegressionTests: XCTestCase {
    func testInferOptionsForProject() {
        let tokens = allRuleFiles.flatMap { file -> [Token] in
            guard let contents = try? String(contentsOf: file, encoding: .utf8) else { return [] }
            return tokenize(contents)
        }

        let options = Options(formatOptions: inferFormatOptions(from: tokens))
        let arguments = serialize(options: options, excludingDefaults: true, separator: " ")
        XCTAssertEqual(arguments, "--binary-grouping none --decimal-grouping none --hex-grouping none --octal-grouping none --semicolons never")
    }
}

class RegressionSuiteEnabledTests: XCTestCase {
    func testRegressionSuiteNotDisabled() throws {
        let fileContents = try String(contentsOf: URL(fileURLWithPath: #file))
        let lines = fileContents.components(separatedBy: .newlines)

        // Find all lines containing CLI.run calls
        let cliRunLines = lines.filter { line in
            line.contains("CLI.run" + "(")
        }

        // Ensure each CLI.run line contains --lint
        for line in cliRunLines {
            XCTAssert(line.contains("--lint"))
        }

        // Ensure we found at least the expected CLI.run calls
        XCTAssert(cliRunLines.count >= 4, "Expected at least 4 CLI.run calls with --lint, found \(cliRunLines.count)")
    }
}
