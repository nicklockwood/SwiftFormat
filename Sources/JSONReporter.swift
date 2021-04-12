//
//  CommandLine.swift
//  SwiftFormat
//
//  Created by Daniele Formichelli on 09/04/2021.
//  Copyright 2021 Nick Lockwood
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

class JSONReporter {
  let outputURL: URL
  var changes: [Formatter.Change] = []

  init(outputURL: URL) {
    self.outputURL = outputURL
  }

  func report(_ changes: [Formatter.Change]) {
    self.changes.append(contentsOf: changes)
  }

  func write() throws {
    try JSONEncoder().encode(self.changes).write(to: self.outputURL)
  }
}

extension Formatter.Change: Encodable {
  enum CodingKeys: String, CodingKey {
    case file
    case line
    case reason
    case ruleID = "rule_id"
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    if let filePath = self.filePath {
      try container.encode(filePath, forKey: .file)
    }
    try container.encode(self.line, forKey: .line)
    try container.encode(self.help, forKey: .reason)
    try container.encode(self.rule.name, forKey: .rule_id)
  }
}
