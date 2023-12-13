//
//  SwiftFormatPluginXcode.swift
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

#if swift(>=5.6) && canImport(XcodeProjectPlugin)
    import XcodeProjectPlugin

    extension SwiftFormatPlugin: XcodeCommandPlugin {
        /// This entry point is called when operating on an Xcode project.
        func performCommand(context: XcodePluginContext, arguments: [String]) throws {
            if arguments.contains("--verbose") {
                print("Command plugin execution with arguments \(arguments.description) for Swift package \(context.xcodeProject.displayName). All target information: \(context.xcodeProject.targets.description)")
                print("Plugin will run for directory: \(context.xcodeProject.directory.description)")
            }

            var argExtractor = ArgumentExtractor(arguments)
            _ = argExtractor.extractOption(named: "target")

            try formatCode(in: context.xcodeProject.directory, context: context, arguments: argExtractor.remainingArguments)
        }
    }
#endif
