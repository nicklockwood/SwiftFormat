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

let swiftFormatFileExtension = "sfxx"

struct SwiftFormatFile: Codable {
    private struct Version: Codable {
        let version: Int
    }

    private let version: Int
    let rules: [Rule]
    let options: [SavedOption]

    init(rules: [Rule], options: [SavedOption]) {
        self.init(version: 1, rules: rules, options: options)
    }

    private init(version: Int, rules: [Rule], options: [SavedOption]) {
        self.version = version
        self.rules = rules
        self.options = options
    }

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let dataToWrite: Data
        do {
            dataToWrite = try encoder.encode(self)
        } catch let error {
            throw FormatError.writing("Problem while encoding configuration data. [\(error)]")
        }

        return dataToWrite
    }

    static func decoded(_ data: Data) throws -> SwiftFormatFile {
        let decoder = JSONDecoder()
        let result: SwiftFormatFile
        do {
            let version = try decoder.decode(Version.self, from: data)
            if version.version != 1 {
                throw FormatError.parsing("Unsupported version number: \(version.version)")
            }
            result = try decoder.decode(SwiftFormatFile.self, from: data)
        } catch let error {
            throw FormatError.parsing("Problem while decoding data. [\(error)]")
        }

        return result
    }
}

struct SwiftFormatCLIArgumentsFile {
    let rules: [Rule]
    let options: [SavedOption]

    init(rules: [Rule], options: [SavedOption]) {
        self.rules = rules
        self.options = options
    }

    func encoded() throws -> Data {
        let ruleEnabled = rules
            .filter { $0.isEnabled }
            .map { $0.name }
            .joined(separator: ",")
            .reduce("--enable ", { (acc: String, char: Character) in
                acc.appending(String(char))
            })
        let ruleDisabled = rules
            .filter { !$0.isEnabled }
            .map { $0.name }
            .joined(separator: ",")
            .reduce("--disable ", { (acc: String, char: Character) in
                acc.appending(String(char))
            })
        let optionsValues = options
            .map { "--" + $0.descriptor.argumentName + " " + $0.argumentValue }
            .joined(separator: "\n")

        let content = [
            ruleEnabled,
            ruleDisabled,
            optionsValues,
        ].joined(separator: "\n")

        guard let result = content.data(using: .utf8) else {
            throw FormatError.writing("Problem while encoding configuration data for bash file.")
        }
        return result
    }

    static func decoded(_ data: Data) throws -> SwiftFormatCLIArgumentsFile {
        guard let input = String(data: data, encoding: .utf8) else {
            throw FormatError.reading("Not able to read data for configuration file")
        }

        do {
            let inputs = input.components(separatedBy: CharacterSet.whitespacesAndNewlines)
            let args = try preprocessArguments(inputs, commandLineArguments)

            let formatOptions = try formatOptionsFor(args)
            let descriptors = FormatOptions.Descriptor.all
            var optionMap = [String: FormatOptions.Descriptor]()
            descriptors.forEach { optionMap[$0.argumentName] = $0 }

            let options: [SavedOption] = descriptors.map {
                let value = $0.fromOptions(formatOptions)
                return SavedOption(argumentValue: value, descriptor: $0)
            }

            let enabled: [String] = args["enable"]?.components(separatedBy: ",") ?? []
            let disabled: [String] = args["disable"]?.components(separatedBy: ",") ?? []
            var ruleNames = Set(FormatRules.byName.map { $0.key })

            let enabledRules = try enabled.map { name -> Rule in
                if ruleNames.remove(name) == nil {
                    throw FormatError.reading("Unsupported Rule provided in 'enable' configuration")
                }
                return Rule(name: name, isEnabled: true)
            }
            let disabledRules = try disabled.map { name -> Rule in
                if ruleNames.remove(name) == nil {
                    throw FormatError.reading("Unsupported Rule provided in 'disable' configuration")
                }
                return Rule(name: name, isEnabled: false)
            }

            var rules = enabledRules + disabledRules
            if !ruleNames.isEmpty {
                //  deal with newer rules by setting default values
                let disabledByDefault = Set(FormatRules.disabledByDefault)
                for unSepcifiedRule in ruleNames {
                    let rule = Rule(name: unSepcifiedRule, isEnabled: !disabledByDefault.contains(unSepcifiedRule))
                    rules.append(rule)
                }
            }

            return SwiftFormatCLIArgumentsFile(rules: rules, options: options)
        } catch let error as FormatError {
            throw error
        } catch {
            throw FormatError.reading("Not able to read data for configuration file")
        }
    }
}
