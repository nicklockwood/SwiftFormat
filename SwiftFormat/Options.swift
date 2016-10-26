//
//  Options.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 21/10/2016.
//  Copyright © 2016 Nick Lockwood. All rights reserved.
//

/// Configuration options for formatting. These aren't actually used by the
/// Formatter class itself, but it makes them available to the format rules.
public struct FormatOptions {
    public var indent: String
    public var linebreak: String
    public var allowInlineSemicolons: Bool
    public var spaceAroundRangeOperators: Bool
    public var useVoid: Bool
    public var trailingCommas: Bool
    public var indentComments: Bool
    public var truncateBlankLines: Bool
    public var insertBlankLines: Bool
    public var removeBlankLines: Bool
    public var experimentalRules: Bool
    public var fragment: Bool

    public init(indent: String = "    ",
                linebreak: String = "\n",
                allowInlineSemicolons: Bool = true,
                spaceAroundRangeOperators: Bool = true,
                useVoid: Bool = true,
                trailingCommas: Bool = true,
                indentComments: Bool = true,
                truncateBlankLines: Bool = true,
                insertBlankLines: Bool = true,
                removeBlankLines: Bool = true,
                experimentalRules: Bool = false,
                fragment: Bool = false) {

        self.indent = indent
        self.linebreak = linebreak
        self.allowInlineSemicolons = allowInlineSemicolons
        self.spaceAroundRangeOperators = spaceAroundRangeOperators
        self.useVoid = useVoid
        self.trailingCommas = trailingCommas
        self.indentComments = indentComments
        self.truncateBlankLines = truncateBlankLines
        self.experimentalRules = experimentalRules
        self.insertBlankLines = insertBlankLines
        self.removeBlankLines = removeBlankLines
        self.fragment = fragment
    }
}

/// Infer default options by examining the existing source
public func inferOptions(_ tokens: [Token]) -> FormatOptions {
    let formatter = Formatter(tokens)
    var options = FormatOptions()

    options.linebreak = {
        var cr: Int = 0, lf: Int = 0, crlf: Int = 0
        formatter.forEachToken(ofType: .linebreak) { i, token in
            switch token.string {
            case "\n":
                lf += 1
            case "\r":
                cr += 1
            case "\r\n":
                crlf += 1
            default:
                assertionFailure()
            }
        }
        var max = lf
        var linebreak = "\n"
        if cr > max {
            max = cr
            linebreak = "\r"
        }
        if crlf > max {
            max = crlf
            linebreak = "\r\n"
        }
        return linebreak
    }()

    options.spaceAroundRangeOperators = {
        var spaced = 0, unspaced = 0
        formatter.forEachToken(ofType: .symbol) { i, token in
            if token.string == "..." || token.string == "..<" {
                if let nextToken = formatter.nextNonWhitespaceOrCommentOrLinebreakToken(fromIndex: i) {
                    if nextToken.string != ")" && nextToken.string != "," {
                        if formatter.tokenAtIndex(i + 1)?.isWhitespaceOrLinebreak == true {
                            spaced += 1
                        } else {
                            unspaced += 1
                        }
                    }
                }
            }
        }
        return spaced >= unspaced
    }()

    options.useVoid = {
        var voids = 0, tuples = 0
        formatter.forEachToken("Void", ofType: .identifier) { i, token in
            if let prevToken = formatter.previousNonWhitespaceOrCommentOrLinebreakToken(fromIndex: i),
                prevToken.string == "." || prevToken.string == "typealias" {
                return
            }
            voids += 1
        }
        formatter.forEachToken("(", ofType: .startOfScope) { i, token in
            if let prevIndex = formatter.indexOfPreviousToken(fromIndex: i, matching: { !$0.isWhitespaceOrCommentOrLinebreak }),
                let prevToken = formatter.tokenAtIndex(prevIndex), prevToken.string == "->",
                let nextIndex = formatter.indexOfNextToken(fromIndex: i, matching: { !$0.isWhitespaceOrLinebreak }),
                let nextToken = formatter.tokenAtIndex(nextIndex), nextToken.string == ")",
                formatter.nextNonWhitespaceOrCommentOrLinebreakToken(fromIndex: nextIndex)?.string != "->" {
                tuples += 1
            }
        }
        return voids >= tuples
    }()

    options.trailingCommas = {
        var trailing = 0, noTrailing = 0
        formatter.forEachToken("]") { i, token in
            if let linebreakIndex = formatter.indexOfPreviousToken(fromIndex: i, matching: {
                return !$0.isWhitespaceOrComment
            }), formatter.tokenAtIndex(linebreakIndex)?.type == .linebreak {
                if let previousTokenIndex = formatter.indexOfPreviousToken(fromIndex: linebreakIndex + 1, matching: {
                    return !$0.isWhitespaceOrCommentOrLinebreak
                }), let token = formatter.tokenAtIndex(previousTokenIndex) {
                    switch token.string {
                    case "[", ":":
                        break // do nothing
                    case ",":
                        trailing += 1
                    default:
                        noTrailing += 1
                    }
                }
            }
        }
        return trailing >= noTrailing
    }()

    options.indentComments = {
        var shouldIndent = true
        var nestedComments = 0
        var prevIndent: Int?
        var lastToken = Token(.whitespace, "")
        for token in formatter.tokens {
            switch token.type {
            case .startOfScope:
                if token.string == "/*" {
                    nestedComments += 1
                }
                prevIndent = nil
            case .endOfScope:
                if token.string == "*/" {
                    if nestedComments > 0 {
                        if lastToken.type == .linebreak {
                            if prevIndent != nil && prevIndent! >= 2 {
                                shouldIndent = false
                                break
                            }
                            prevIndent = 0
                        }
                        nestedComments -= 1
                    } else {
                        break // might be fragment, or syntax error
                    }
                }
                prevIndent = nil
            case .whitespace:
                if nestedComments > 0 && lastToken.type == .linebreak {
                    let indent = token.string.characters.count
                    if prevIndent != nil && abs(prevIndent! - indent) >= 2 {
                        shouldIndent = false
                        break
                    }
                    prevIndent = indent
                }
            case .commentBody:
                if nestedComments > 0 && lastToken.type == .linebreak {
                    if prevIndent != nil && prevIndent! >= 2 {
                        shouldIndent = false
                        break
                    }
                    prevIndent = 0
                }
            default:
                break
            }
            lastToken = token
        }
        return shouldIndent
    }()

    return options
}
