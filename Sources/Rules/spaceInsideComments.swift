//
//  spaceInsideComments.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Add space inside comments, taking care not to mangle headerdoc or
    /// carefully preformatted comments, such as star boxes, etc.
    static let spaceInsideComments = FormatRule(
        help: "Add leading and/or trailing space inside comments."
    ) { formatter in
        formatter.forEach(.startOfScope("//")) { i, _ in
            guard case let .commentBody(string)? = formatter.token(at: i + 1),
                  let first = string.first else { return }
            if "/!:".contains(first) {
                let nextIndex = string.index(after: string.startIndex)
                if nextIndex < string.endIndex, case let next = string[nextIndex], !" \t/".contains(next) {
                    let string = String(string.first!) + " " + String(string.dropFirst())
                    formatter.replaceToken(at: i + 1, with: .commentBody(string))
                }
            } else if !" \t".contains(first), !string.hasPrefix("===") { // Special-case check for swift stdlib codebase
                formatter.insert(.space(" "), at: i + 1)
            }
        }
        formatter.forEach(.startOfScope("/*")) { i, _ in
            guard case let .commentBody(string)? = formatter.token(at: i + 1),
                  !string.hasPrefix("---"), !string.hasPrefix("@"), !string.hasSuffix("---"), !string.hasSuffix("@")
            else {
                return
            }
            if let first = string.first, "*!:".contains(first) {
                let nextIndex = string.index(after: string.startIndex)
                if nextIndex < string.endIndex, case let next = string[nextIndex],
                   !" /t".contains(next), !string.hasPrefix("**"), !string.hasPrefix("*/")
                {
                    let string = String(string.first!) + " " + String(string.dropFirst())
                    formatter.replaceToken(at: i + 1, with: .commentBody(string))
                }
            } else {
                formatter.insert(.space(" "), at: i + 1)
            }
            if let i = formatter.index(of: .endOfScope("*/"), after: i), let prevToken = formatter.token(at: i - 1) {
                if !prevToken.isSpaceOrLinebreak, !prevToken.string.hasSuffix("*"),
                   !prevToken.string.trimmingCharacters(in: .whitespaces).isEmpty
                {
                    formatter.insert(.space(" "), at: i)
                }
            }
        }
    }
}
