//
//  ProjectFilePaths.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 8/3/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation
@testable import SwiftFormat

let projectDirectory = URL(fileURLWithPath: #file)
    .deletingLastPathComponent().deletingLastPathComponent()

let projectURL = projectDirectory
    .appendingPathComponent("SwiftFormat.xcodeproj")
    .appendingPathComponent("project.pbxproj")

let allSourceFiles = allSwiftFiles(inDirectory: "Sources")
let allRuleFiles = allSwiftFiles(inDirectory: "Sources/Rules")

let allTestFiles = allSwiftFiles(inDirectory: "Tests")
let allRuleTestFiles = allSwiftFiles(inDirectory: "Tests/Rules")

let changeLogURL =
    projectDirectory.appendingPathComponent("CHANGELOG.md")

let podspecURL =
    projectDirectory.appendingPathComponent("SwiftFormat.podspec.json")

let rulesURL =
    projectDirectory.appendingPathComponent("Rules.md")

let rulesFile =
    try! String(contentsOf: rulesURL, encoding: .utf8)

let ruleRegistryURL =
    projectDirectory.appendingPathComponent("Sources/RuleRegistry.generated.swift")

private func allSwiftFiles(inDirectory directory: String) -> [URL] {
    var swiftFiles: [URL] = []
    let directory = projectDirectory.appendingPathComponent(directory)
    let options = Options(fileOptions: .init(supportedFileExtensions: ["swift"]))
    let errors = enumerateFiles(withInputURLs: [directory], options: options) { fileURL, _, _ in
        {
            swiftFiles.append(fileURL)
        }
    }
    assert(errors.isEmpty, "Encountered errors accessing files in \(directory): \(errors)")
    assert(!swiftFiles.isEmpty, "Could not load files in \(directory)")
    return swiftFiles
}
