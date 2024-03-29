//
//  CommandErrors.swift
//  Swift Formatter
//
//  Created by Tony Arnold on 6/10/16.
//  Copyright 2016 Nick Lockwood
//
//  Distributed under the permissive MIY license
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

enum FormatCommandError: Error, LocalizedError, CustomNSError {
    case notSwiftLanguage
    case noSelection
    case invalidSelection
    case lintWarnings([Formatter.Change])

    var localizedDescription: String {
        switch self {
        case .notSwiftLanguage:
            return "Error: not a Swift source file."
        case .noSelection:
            return "Error: no text selected."
        case .invalidSelection:
            return "Error: invalid selection."
        case let .lintWarnings(changes):
            let change = changes.first!
            let rule = change.rule
            let message = "Warning: \(rule.name) violation on line \(change.line). \(rule.help)"
            switch changes.count - 1 {
            case 0:
                return message
            case 1:
                return "\(message) (+ 1 other warning)"
            case let n:
                return "\(message) (+ \(n) other warnings)"
            }
        }
    }

    var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: localizedDescription]
    }
}
