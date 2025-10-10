//
//  Plugin.swift
//  SwiftFormat
//
//  Created by Baptiste Clarey Sjöstrand
//  Copyright 2025 Nick Lockwood
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/SwiftFormat
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import PackagePlugin

@main
struct Plugin: BuildToolPlugin {
    static let configFileName = ".swiftformat"

    /// Creates build commands to run SwiftFormat on the target's swift files.
    func createBuildCommands(
        context: PluginContext,
        target: Target,
    ) async throws -> [Command] {
        try makeCommand(
            executable: context.tool(named: "swiftformat"),
            swiftFiles: (target as? SourceModuleTarget).flatMap(swiftFiles) ?? [],
            buildEnvironment: createBuildEnvironment(context: context, target: target),
            pluginWorkDirectory: context.pluginWorkDirectory,
        )
    }

    private func createBuildEnvironment(
        context: PluginContext,
        target: Target,
    ) throws -> [String: String] {
        let workingDirectory: Path = try target.directory.resolveWorkingDirectory(in: context.package.directory)
        // The BUILD_WORKSPACE_DIRECTORY environment variable is used by SwiftFormat to find the configuration file.
        return ["BUILD_WORKSPACE_DIRECTORY": "\(workingDirectory)"]
    }

    private func makeCommand(
        executable: PluginContext.Tool,
        swiftFiles: [Path],
        buildEnvironment: [String: String],
        pluginWorkDirectory path: Path,
    ) throws -> [Command] {
        guard !swiftFiles.isEmpty else {
            return []
        }
        print("Environment:", buildEnvironment)
        let arguments: [String] = [
            "--lint", // Report errors for unformatted files.
        ]
        let outputPath: Path = path.appending("Output")
        try FileManager.default.createDirectory(atPath: outputPath.string, withIntermediateDirectories: true)
        return [
            .prebuildCommand(
                displayName: "SwiftFormat",
                executable: executable.path,
                arguments: arguments + swiftFiles.map(\.string),
                environment: buildEnvironment,
                outputFilesDirectory: outputPath,
            ),
        ]
    }

    private func swiftFiles(from target: SourceModuleTarget) -> [Path] {
        target.sourceFiles(withSuffix: "swift").map(\.path)
    }
}

#if canImport(XcodeProjectPlugin)
    import XcodeProjectPlugin

    extension Plugin: XcodeBuildToolPlugin {
        /// Creates build commands to run SwiftFormat on the target's swift files within an Xcode project.
        func createBuildCommands(
            context: XcodePluginContext,
            target: XcodeTarget,
        ) throws -> [Command] {
            try makeCommand(
                executable: context.tool(named: "swiftformat"),
                swiftFiles: swiftFiles(from: target),
                buildEnvironment: createBuildEnvironment(context: context, target: target),
                pluginWorkDirectory: context.pluginWorkDirectory,
            )
        }

        private func createBuildEnvironment(
            context: XcodePluginContext,
            target: XcodeTarget,
        ) throws -> [String: String] {
            let projectDirectory = context.xcodeProject.directory
            let swiftFiles = swiftFiles(from: target)
            let externalSwiftFiles = swiftFiles.filter { !$0.string.hasPrefix("\(projectDirectory)") }
            guard externalSwiftFiles.isEmpty else {
                throw PluginError.swiftFilesNotInProjectDirectory(projectDirectory)
            }

            // When formatting files in an Xcode project, we need to find a common ancestor directory that contains
            // a .swiftformat file. This ensures that the correct formatting rules are applied to all files.
            let directories = try swiftFiles.map { try $0.resolveWorkingDirectory(in: projectDirectory) }
            let workingDirectory = directories.min { $0.depth < $1.depth } ?? projectDirectory

            let filesOutsideWorkingDirectory = swiftFiles.filter { !$0.string.hasPrefix("\(workingDirectory)") }
            guard filesOutsideWorkingDirectory.isEmpty else {
                throw PluginError.swiftFilesNotInWorkingDirectory(workingDirectory)
            }

            // The BUILD_WORKSPACE_DIRECTORY environment variable is used by SwiftFormat to find the configuration file.
            return ["BUILD_WORKSPACE_DIRECTORY": "\(workingDirectory)"]
        }

        private func swiftFiles(from target: XcodeTarget) -> [Path] {
            target.inputFiles.filter { $0.type == .source && $0.path.extension == "swift" }.map(\.path)
        }
    }
#endif
