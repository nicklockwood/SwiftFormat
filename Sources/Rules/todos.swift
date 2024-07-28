//
//  todos.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Ensure that TODO, MARK and FIXME comments are followed by a : as required
    static let todos = FormatRule(
        help: "Use correct formatting for `TODO:`, `MARK:` or `FIXME:` comments."
    ) { formatter in
        formatter.forEachToken { i, token in
            guard case var .commentBody(string) = token else {
                return
            }
            var removedSpace = false
            if string.hasPrefix("/"), let scopeStart = formatter.index(of: .startOfScope, before: i, if: {
                $0 == .startOfScope("//")
            }) {
                if let prevLinebreak = formatter.index(of: .linebreak, before: scopeStart),
                   case .commentBody? = formatter.last(.nonSpace, before: prevLinebreak)
                {
                    return
                }
                if let nextLinebreak = formatter.index(of: .linebreak, after: i),
                   case .startOfScope("//")? = formatter.next(.nonSpace, after: nextLinebreak)
                {
                    return
                }
                removedSpace = true
                string = string.replacingOccurrences(of: "^/(\\s+)", with: "", options: .regularExpression)
            }
            for pair in [
                "todo:": "TODO:",
                "todo :": "TODO:",
                "fixme:": "FIXME:",
                "fixme :": "FIXME:",
                "mark:": "MARK:",
                "mark :": "MARK:",
                "mark-": "MARK: -",
                "mark -": "MARK: -",
            ] where string.lowercased().hasPrefix(pair.0) {
                string = pair.1 + string.dropFirst(pair.0.count)
            }
            guard let tag = ["TODO", "MARK", "FIXME"].first(where: { string.hasPrefix($0) }) else {
                return
            }
            var suffix = String(string[tag.endIndex ..< string.endIndex])
            if let first = suffix.unicodeScalars.first, !" :".unicodeScalars.contains(first) {
                // If not followed by a space or :, don't mess with it as it may be a custom format
                return
            }
            while let first = suffix.unicodeScalars.first, " :".unicodeScalars.contains(first) {
                suffix = String(suffix.dropFirst())
            }
            if tag == "MARK", suffix.hasPrefix("-"), suffix != "-", !suffix.hasPrefix("- ") {
                suffix = "- " + suffix.dropFirst()
            }
            formatter.replaceToken(at: i, with: .commentBody(tag + ":" + (suffix.isEmpty ? "" : " \(suffix)")))
            if removedSpace {
                formatter.insertSpace(" ", at: i)
            }
        }
    }
}
