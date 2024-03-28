//
//  ZRegressionTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 28/03/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

private let projectDirectory = URL(fileURLWithPath: #file)
    .deletingLastPathComponent().deletingLastPathComponent()

private let projectFiles: [String] = {
    var files = [String]()
    _ = enumerateFiles(withInputURL: projectDirectory) { url, _, _ in
        {
            if let source = try? String(contentsOf: url) {
                files.append(source)
            }
        }
    }
    return files
}()

// Note: Z prefix ensures these run last
class ZRegressionTests: XCTestCase {
    // MARK: infererence

    func testInferOptionsForProject() {
        let tokens = projectFiles.flatMap { tokenize($0) }
        let options = Options(formatOptions: inferFormatOptions(from: tokens))
        let arguments = serialize(options: options, excludingDefaults: true, separator: " ")
        XCTAssertEqual(arguments, "--binarygrouping none --decimalgrouping none --hexgrouping none --octalgrouping none --semicolons never")
    }

    // MARK: snapshot/regression tests

    func testRegressionSuite() {
        CLI.print = { message, _ in
            Swift.print(message)
        }
        // NOTE: to update regression suite, run again without `--lint` argument
        XCTAssertEqual(CLI.run(in: projectDirectory.path, with: "Sources,Tests,Snapshots --unexclude Snapshots --symlinks follow --cache ignore --lint"), .ok)
    }

    func testRegressionSuiteNotDisabled() throws {
        let commandLineTests = try String(contentsOf: URL(fileURLWithPath: #file))
        let range = try XCTUnwrap(
            commandLineTests.range(of: "testRegressionSuiteNotDisabled()")
        )
        XCTAssert(commandLineTests[..<range.lowerBound].contains("""
        with: "Sources,Tests,Snapshots --unexclude Snapshots --symlinks follow --cache ignore --lint")
        """))
    }
}
