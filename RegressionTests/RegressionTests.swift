//
//  RegressionTests.swift
//  RegressionTests
//
//  Created by Nick Lockwood on 28/03/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import SwiftFormat
import XCTest

let projectDirectory = URL(fileURLWithPath: #file)
    .deletingLastPathComponent().deletingLastPathComponent()

private let projectFiles: [String] = {
    var files = [String]()
    let options = Options(fileOptions: .init(supportedFileExtensions: ["swift"]))
    _ = enumerateFiles(withInputURLs: [projectDirectory], options: options) { url, _, _ in
        {
            if let source = try? String(contentsOf: url, encoding: .utf8) {
                files.append(source)
            }
        }
    }
    return files
}()

final class RegressionTests: XCTestCase {
    func testRegressionSuite() {
        CLI.print = { message, _ in
            Swift.print(message)
        }
        // NOTE: to update regression suite, run again without `--lint` argument
        XCTAssertEqual(CLI.run(in: projectDirectory.path, with: "Snapshots --unexclude Snapshots --symlinks follow --cache ignore --lint"), .ok)
    }

    func testCache() {
        CLI.print = { message, _ in
            Swift.print(message)
        }
        // NOTE: to update regression suite, run again without `--lint` argument
        let result = CLI.run(in: projectDirectory.path, with: "Snapshots --unexclude Snapshots --cache clear --lint")
        XCTAssertEqual(result, .ok)

        // Test cache
        if result == .ok {
            var messages = [String]()
            CLI.print = { message, _ in
                Swift.print(message)
                messages.append(message)
            }
            XCTAssertEqual(CLI.run(in: projectDirectory.path, with: "Snapshots --unexclude Snapshots --symlinks follow --lint --verbose"), .ok)
            XCTAssert(messages.contains("-- no changes (cached)"))
        }
    }

    func testInferOptionsForProject() {
        let tokens = projectFiles.flatMap { tokenize($0) }
        let options = Options(formatOptions: inferFormatOptions(from: tokens))
        let arguments = serialize(options: options, excludingDefaults: true, separator: " ")
        XCTAssertEqual(arguments, "--binary-grouping none --decimal-grouping none --hex-grouping none --octal-grouping none --semicolons never")
    }

    func testRegressionSuiteNotDisabled() throws {
        let fileContents = try String(contentsOf: URL(fileURLWithPath: #file), encoding: .utf8)
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
        XCTAssert(cliRunLines.count >= 3, "Expected at least 4 CLI.run calls with --lint, found \(cliRunLines.count)")
    }
}
