//
//  main.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 12/08/2016.
//  Copyright 2016 Nick Lockwood
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

#if os(macOS)
    import Darwin.POSIX
#elseif os(Windows)
    import ucrt
#else
    import Glibc
#endif

#if SWIFT_PACKAGE
    import SwiftFormat
#endif

extension String {
    var inDefault: String { "\u{001B}[39m\(self)" }
    var inRed: String { "\u{001B}[31m\(self)\u{001B}[0m" }
    var inGreen: String { "\u{001B}[32m\(self)\u{001B}[0m" }
    var inYellow: String { "\u{001B}[33m\(self)\u{001B}[0m" }
}

extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        write(Data(string.utf8))
    }
}

private var stderr = FileHandle.standardError

private let stderrIsTTY = isatty(STDERR_FILENO) != 0

private let printQueue = DispatchQueue(label: "swiftformat.print")

CLI.print = { message, type in
    printQueue.sync {
        switch type {
        case .info:
            print(message, to: &stderr)
        case .success:
            print(stderrIsTTY ? message.inGreen : message, to: &stderr)
        case .error:
            print(stderrIsTTY ? message.inRed : message, to: &stderr)
        case .warning:
            print(stderrIsTTY ? message.inYellow : message, to: &stderr)
        case .content:
            print(message)
        case .raw:
            print(message, terminator: "")
        }
    }
}

let currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).standardizedFileURL

exit(CLI.run(in: currentDirectory.path).rawValue)
