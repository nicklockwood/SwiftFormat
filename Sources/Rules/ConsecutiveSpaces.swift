//
//  ConsecutiveSpaces.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 8/30/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Collapse all consecutive space characters to a single space, except at
    /// the start of a line or inside a comment or string, as these have no semantic
    /// meaning and lead to noise in commits.
    static let consecutiveSpaces = FormatRule(
        help: "Replace consecutive spaces with a single space."
    ) { formatter in
        formatter.forEach(.space) { i, token in
            switch token {
            case .space(""):
                formatter.removeToken(at: i)
            case .space(" "):
                break
            default:
                guard let prevToken = formatter.token(at: i - 1),
                      let nextToken = formatter.token(at: i + 1)
                else {
                    return
                }
                switch prevToken {
                case .linebreak, .startOfScope("/*"), .startOfScope("//"), .commentBody:
                    return
                case .endOfScope("*/") where nextToken == .startOfScope("/*") &&
                    formatter.currentScope(at: i) == .startOfScope("/*"):
                    return
                default:
                    break
                }
                switch nextToken {
                case .linebreak, .endOfScope("*/"), .commentBody:
                    return
                default:
                    formatter.replaceToken(at: i, with: .space(" "))
                }
            }
        }
    }
}
