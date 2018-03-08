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

struct SwiftFormatFile: Codable {
    private struct Version: Codable {
        let version: Int
    }

    static let `extension` = "sfxx" //  TODO: Define the official extension

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
