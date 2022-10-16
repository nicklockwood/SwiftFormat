//
//  CommandPlugin+Extension.swift
//  SwiftFormat
//
//  Created by Marco Eidinger
//  Copyright 2022 Nick Lockwood
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

#if swift(>=5.6)
    extension CommandPlugin {
        func formatCode(in directory: PackagePlugin.Path, context: PluginToolProviding, arguments: [String]) throws {
            let tool = try context.tool(named: "CommandLineTool")
            let toolURL = URL(fileURLWithPath: tool.path.string)

            var processArguments = [directory.string]
            processArguments.append(contentsOf: arguments)

            let process = Process()
            process.executableURL = toolURL
            process.arguments = processArguments

            try process.run()
            process.waitUntilExit()

            if process.terminationReason == .exit, process.terminationStatus == 0 {
                print("Formatted the source code in \(directory.string).")
            } else {
                let problem = "\(process.terminationReason):\(process.terminationStatus)"
                Diagnostics.error("swiftformat invocation failed: \(problem)")
            }
        }
    }
#endif
