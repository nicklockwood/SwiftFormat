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
    let options: FormatOptions

    init(rules: [Rule], options: FormatOptions) {
        self.rules = rules
        self.options = options
    }

    func encoded() throws -> Data {
        var arguments = ""

        let rules = self.rules.sorted(by: { $0.name < $1.name })
        var defaultRules = Set(FormatRules.byName.map { $0.key })
        FormatRules.disabledByDefault.forEach { defaultRules.remove($0) }

        let enabled = rules.filter { $0.isEnabled && !defaultRules.contains($0.name) }
        if !enabled.isEmpty {
            arguments += "--enable \(enabled.map { $0.name }.joined(separator: ","))\n"
        }

        let disabled = rules.filter { !$0.isEnabled && defaultRules.contains($0.name) }
        if !disabled.isEmpty {
            arguments += "--disable \(disabled.map { $0.name }.joined(separator: ","))\n"
        }

        let options = commandLineArguments(for: self.options).map { "--\($0) \($1)" }.sorted()
        arguments += options.joined(separator: "\n")

        guard let result = arguments.data(using: .utf8) else {
            throw FormatError.writing("problem encoding configuration data")
        }
        return result
    }

    static func decoded(_ data: Data) throws -> SwiftFormatCLIArgumentsFile {
        guard let input = String(data: data, encoding: .utf8) else {
            throw FormatError.reading("unable to read data for configuration file")
        }

        do {
            let inputs = input.components(separatedBy: CharacterSet.whitespacesAndNewlines)
            let args = try preprocessArguments(inputs, commandLineArguments)

            let allRules = Set(FormatRules.byName.map { $0.key })
            func getRules(_ name: String) throws -> Set<String>? {
                guard let rules = args[name]?.components(separatedBy: ",") else {
                    return nil
                }
                try rules.forEach {
                    if !allRules.contains($0) {
                        throw FormatError.reading("unknown rule '\($0)' in --\(name)")
                    }
                }
                return Set(rules)
            }
            var ruleNames = try getRules("rules") ?? {
                var defaultRules = allRules
                FormatRules.disabledByDefault.forEach { defaultRules.remove($0) }
                return defaultRules
            }()
            try getRules("enable")?.forEach { ruleNames.insert($0) }
            try getRules("disable")?.forEach { ruleNames.remove($0) }
            let rules = allRules.map { Rule(name: $0, isEnabled: ruleNames.contains($0)) }

            CLI.print = { _, _ in } // Prevent crash if file contains deprecated rules
            let formatOptions = try formatOptionsFor(args)

            return SwiftFormatCLIArgumentsFile(rules: rules, options: formatOptions)
        } catch let error as FormatError {
            throw error
        } catch {
            throw FormatError.reading("unable to read data for configuration file")
        }
    }
}
