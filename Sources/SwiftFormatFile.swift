//
//  SwiftFormatFile.swift
//  SwiftFormat for Xcode
//
//  Created by Vincent Bernier on 08-03-18.
//  Copyright © 2018 Nick Lockwood.
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

let swiftFormatFileExtension = "swiftformat"

struct SwiftFormatCLIArgumentsFile {
    let rules: [Rule]
    let options: FormatOptions?

    init(rules: [Rule], options: FormatOptions?) {
        self.rules = rules
        self.options = options
    }

    func encoded() -> Data {
        var arguments = ""

        if let options = options {
            arguments += commandLineArguments(for: options).map { "--\($0) \($1)\n" }.sorted().joined()
        }

        let rules = self.rules.sorted(by: { $0.name < $1.name })
        var defaultRules = Set(FormatRules.byName.keys)
        FormatRules.disabledByDefault.forEach { defaultRules.remove($0) }

        let enabled = rules.filter { $0.isEnabled && !defaultRules.contains($0.name) }
        if !enabled.isEmpty {
            arguments += "--enable \(enabled.map { $0.name }.joined(separator: ","))\n"
        }

        let disabled = rules.filter { !$0.isEnabled && defaultRules.contains($0.name) }
        if !disabled.isEmpty {
            arguments += "--disable \(disabled.map { $0.name }.joined(separator: ","))\n"
        }

        return Data(arguments.utf8)
    }

    static func decoded(_ data: Data) throws -> SwiftFormatCLIArgumentsFile {
        let args = try parseConfigFile(data)

        let allRules = Set(FormatRules.byName.keys)
        var ruleNames = try args["rules"].map {
            try Set(parseRules($0))
        } ?? allRules.subtracting(FormatRules.disabledByDefault)
        try args["enable"].map {
            try ruleNames.formUnion(parseRules($0))
        }
        try args["disable"].map {
            try ruleNames.subtract(parseRules($0))
        }
        let rules = allRules.map {
            Rule(name: $0, isEnabled: ruleNames.contains($0))
        }

        CLI.print = { _, _ in } // Prevent crash if file contains deprecated rules
        return try SwiftFormatCLIArgumentsFile(rules: rules, options: formatOptionsFor(args))
    }
}
