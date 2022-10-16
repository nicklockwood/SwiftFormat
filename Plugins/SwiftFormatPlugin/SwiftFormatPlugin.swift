//
//  SwiftFormatPlugin.swift
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
    @main
    struct SwiftFormatPlugin: CommandPlugin {
        /// This entry point is called when operating on a Swift package.
        func performCommand(context: PluginContext, arguments: [String]) throws {
            if arguments.contains("--verbose") {
                print("Command plugin execution with arguments \(arguments.description) for Swift package \(context.package.displayName). All target information: \(context.package.targets.description)")
            }

            var targetsToProcess: [Target] = context.package.targets

            var argExtractor = ArgumentExtractor(arguments)

            let selectedTargets = argExtractor.extractOption(named: "target")

            if selectedTargets.isEmpty == false {
                targetsToProcess = context.package.targets.filter { selectedTargets.contains($0.name) }.map { $0 }
            }

            for target in targetsToProcess {
                guard let target = target as? SourceModuleTarget else { continue }

                try formatCode(in: target.directory, context: context, arguments: argExtractor.remainingArguments)
            }
        }
    }
#endif
