//
//  ParsingHelpers.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 08/04/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

import Foundation

// MARK: shared helper methods

extension Formatter {
    func specifiersForType(at index: Int, contains: (Int, Token) -> Bool) -> Bool {
        let allSpecifiers = _FormatRules.allSpecifiers
        var index = index
        while var prevIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, before: index) {
            switch tokens[prevIndex] {
            case let token where contains(prevIndex, token):
                return true
            case .endOfScope(")"):
                guard let startIndex = self.index(of: .startOfScope("("), before: prevIndex),
                    let index = self.index(of: .nonSpaceOrCommentOrLinebreak, before: startIndex, if: {
                        $0.isAttribute || _FormatRules.aclSpecifiers.contains($0.string)
                    }) else {
                    return false
                }
                prevIndex = index
            case let .keyword(name), let .identifier(name):
                if !allSpecifiers.contains(name), !name.hasPrefix("@") {
                    return false
                }
            default:
                return false
            }
            index = prevIndex
        }
        return false
    }

    func specifiersForType(at index: Int, contains: String) -> Bool {
        return specifiersForType(at: index, contains: { $1.string == contains })
    }

    // first index of specifier list
    func startOfSpecifiers(at index: Int) -> Int {
        var startIndex = index
        _ = specifiersForType(at: index, contains: { i, _ in
            startIndex = i
            return false
        })
        return startIndex
    }

    // gather declared name(s), starting at index of declaration keyword
    func namesInDeclaration(at index: Int) -> Set<String>? {
        guard case let .keyword(keyword)? = token(at: index) else {
            return nil
        }
        switch keyword {
        case "let", "var":
            var index = index + 1
            var names = Set<String>()
            processDeclaredVariables(at: &index, names: &names)
            return names
        case "func", "class", "struct", "enum":
            guard let name = next(.identifier, after: index) else {
                return nil
            }
            return [name.string]
        default:
            return nil
        }
    }

    // gather declared variable names, starting at index after let/var keyword
    func processDeclaredVariables(at index: inout Int, names: inout Set<String>) {
        while let token = self.token(at: index) {
            switch token {
            case .identifier where
                last(.nonSpaceOrCommentOrLinebreak, before: index)?.isOperator(".") == false:
                let name = token.unescaped()
                if name != "_" {
                    names.insert(name)
                }
                inner: while let nextIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, after: index) {
                    switch tokens[nextIndex] {
                    case .keyword("as"), .keyword("is"), .keyword("try"):
                        break
                    case .startOfScope("<"), .startOfScope("["), .startOfScope("("),
                         .startOfScope where token.isStringDelimiter:
                        guard let endIndex = endOfScope(at: nextIndex) else {
                            return // error
                        }
                        index = endIndex
                        continue
                    case .keyword, .startOfScope("{"), .endOfScope("}"), .startOfScope(":"):
                        return
                    case .delimiter(","):
                        index = nextIndex
                        break inner
                    default:
                        break
                    }
                    index = nextIndex
                }
            default:
                break
            }
            index += 1
        }
    }

    func isStartOfClosure(at i: Int) -> Bool {
        return isStartOfClosure(at: i, in: currentScope(at: i))
    }

    func isStartOfClosure(at i: Int, in scope: Token?) -> Bool {
        assert(tokens[i] == .startOfScope("{"))
        var i = i - 1
        var nextTokenIndex = i
        var foundEquals = false
        while let token = self.token(at: i) {
            let prevTokenIndex = index(before: i, where: {
                !$0.isSpaceOrComment && (!$0.isEndOfScope || $0 == .endOfScope("}"))
            }) ?? -1
            switch token {
            case let .keyword(string):
                switch string {
                case "var":
                    if !foundEquals {
                        fallthrough
                    }
                case "class", "struct", "enum", "protocol", "func":
                    return last(.nonSpaceOrCommentOrLinebreak, before: i) == .keyword("import")
                case "extension", "init", "subscript",
                     "if", "switch", "guard", "else",
                     "for", "while", "repeat",
                     "do", "catch":
                    return false
                default:
                    break
                }
            case .operator("=", _):
                foundEquals = true
            case .startOfScope:
                return true
            case .linebreak:
                var prevTokenIndex = prevTokenIndex
                if self.token(at: prevTokenIndex)?.isLinebreak == true {
                    prevTokenIndex = index(before: prevTokenIndex, where: {
                        !$0.isSpaceOrCommentOrLinebreak && (!$0.isEndOfScope || $0 == .endOfScope("}"))
                    }) ?? -1
                }
                // TODO: combine with keyword logic above and in redundantParens, etc
                if let keyword = lastSignificantKeyword(at: i),
                    ["in", "while", "if", "case", "switch", "where", "for", "guard"].contains(keyword) {
                    break
                }
                if isEndOfStatement(at: prevTokenIndex, in: scope),
                    isStartOfStatement(at: nextTokenIndex, in: scope) {
                    return true
                }
            default:
                break
            }
            nextTokenIndex = i
            i = prevTokenIndex
        }
        return true
    }

    func lastSignificantKeyword(at i: Int) -> String? {
        guard let index = self.index(of: .keyword, before: i + 1),
            case let .keyword(keyword) = tokens[index] else {
            return nil
        }
        switch keyword {
        case let name where name.hasPrefix("#") || name.hasPrefix("@"):
            fallthrough
        case "in", "as", "is", "try":
            return lastSignificantKeyword(at: index - 1)
        case let name:
            return name
        }
    }

    func isEndOfStatement(at i: Int, in scope: Token?) -> Bool {
        guard let token = self.token(at: i) else { return true }
        switch token {
        case .endOfScope("case"), .endOfScope("default"):
            return false
        case let .keyword(string):
            // TODO: handle in
            // TODO: handle context-specific keywords
            // associativity, convenience, dynamic, didSet, final, get, infix, indirect,
            // lazy, left, mutating, none, nonmutating, open, optional, override, postfix,
            // precedence, prefix, Protocol, required, right, set, Type, unowned, weak, willSet
            switch string {
            case "let", "func", "var", "if", "as", "import", "try", "guard", "case",
                 "for", "init", "switch", "throw", "where", "subscript", "is",
                 "while", "associatedtype", "inout":
                return false
            case "return":
                guard let nextToken = next(.nonSpaceOrCommentOrLinebreak, after: i) else {
                    return true
                }
                switch nextToken {
                case .keyword, .endOfScope("case"), .endOfScope("default"):
                    return true
                default:
                    return false
                }
            default:
                return true
            }
        case .delimiter(","):
            // For arrays or argument lists, we already indent
            return ["<", "[", "(", "case", "default"].contains(scope?.string ?? "")
        case .delimiter(":"):
            // For arrays or argument lists, we already indent
            return ["case", "default", "("].contains(scope?.string ?? "")
        case .operator(_, .infix), .operator(_, .prefix):
            return false
        case .operator("?", .postfix), .operator("!", .postfix):
            switch self.token(at: i - 1) {
            case .keyword("as")?, .keyword("try")?:
                return false
            default:
                return true
            }
        default:
            return true
        }
    }

    func isStartOfStatement(at i: Int, in scope: Token?) -> Bool {
        guard let token = self.token(at: i) else { return true }
        switch token {
        case let .keyword(string) where [ // TODO: handle "in"
            "where", "dynamicType", "rethrows", "throws",
        ].contains(string):
            return false
        case .keyword("as"), .keyword("in"):
            // For case statements, we already indent
            return currentScope(at: i)?.string == "case"
        case .delimiter(","):
            if ["<", "[", "(", "case"].contains(scope?.string ?? "") {
                // For arrays, dictionaries, cases, or argument lists, we already indent
                return true
            }
            return false
        case .delimiter, .operator(_, .infix), .operator(_, .postfix):
            return false
        default:
            return true
        }
    }

    func isSubscriptOrFunctionCall(at i: Int) -> Bool {
        guard case let .startOfScope(string)? = token(at: i), ["[", "("].contains(string),
            let prevToken = last(.nonSpaceOrComment, before: i) else {
            return false
        }
        switch prevToken {
        case .identifier, .operator(_, .postfix),
             .endOfScope("]"), .endOfScope(")"), .endOfScope("}"),
             .endOfScope where prevToken.isStringDelimiter:
            return true
        default:
            return false
        }
    }
}

extension _FormatRules {
    // Short date formater. Used by fileHeader rule
    static var shortDateFormatter: (Date) -> String = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return { formatter.string(from: $0) }
    }()

    // Year formater. Used by fileHeader rule
    static var yearFormatter: (Date) -> String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return { formatter.string(from: $0) }
    }()

    // Current year. Used by fileHeader rule
    static var currentYear: String = {
        yearFormatter(Date())
    }()

    // Shared import rules implementation
    typealias ImportRange = (String, Range<Int>)
    static func parseImports(_ formatter: Formatter) -> [[ImportRange]] {
        var importStack = [[ImportRange]]()
        var importRanges = [ImportRange]()
        formatter.forEach(.keyword("import")) { i, _ in

            func pushStack() {
                importStack.append(importRanges)
                importRanges.removeAll()
            }

            // Get start of line
            var startIndex = formatter.index(of: .linebreak, before: i) ?? 0
            // Check for attributes
            var previousKeywordIndex = formatter.index(of: .keyword, before: i)
            while let previousIndex = previousKeywordIndex {
                var nextStart: Int? // workaround for Swift Linux bug
                if formatter.tokens[previousIndex].isAttribute {
                    if previousIndex < startIndex {
                        nextStart = formatter.index(of: .linebreak, before: previousIndex) ?? 0
                    }
                    previousKeywordIndex = formatter.index(of: .keyword, before: previousIndex)
                    startIndex = nextStart ?? startIndex
                } else if previousIndex >= startIndex {
                    // Can't handle another keyword on same line as import
                    return
                } else {
                    break
                }
            }
            // Gather comments
            var prevIndex = formatter.index(of: .linebreak, before: startIndex) ?? 0
            while startIndex > 0,
                formatter.next(.nonSpace, after: prevIndex)?.isComment == true,
                formatter.next(.nonSpaceOrComment, after: prevIndex)?.isLinebreak == true {
                startIndex = prevIndex
                prevIndex = formatter.index(of: .linebreak, before: startIndex) ?? 0
            }
            // Get end of line
            let endIndex = formatter.index(of: .linebreak, after: i) ?? formatter.tokens.count
            // Get name
            if let firstPartIndex = formatter.index(of: .identifier, after: i) {
                var name = formatter.tokens[firstPartIndex].string
                var partIndex = firstPartIndex
                loop: while let nextPartIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: partIndex) {
                    switch formatter.tokens[nextPartIndex] {
                    case .operator(".", .infix):
                        name += "."
                    case let .identifier(string):
                        name += string
                    default:
                        break loop
                    }
                    partIndex = nextPartIndex
                }
                importRanges.append((name, startIndex ..< endIndex as Range))
            } else {
                // Error
                pushStack()
                return
            }
            if formatter.next(.spaceOrCommentOrLinebreak, after: endIndex)?.isLinebreak == true {
                // Blank line after - consider this the end of a block
                pushStack()
                return
            }
            if var nextTokenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: endIndex) {
                while formatter.tokens[nextTokenIndex].isAttribute {
                    guard let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: nextTokenIndex) else {
                        // End of imports
                        pushStack()
                        return
                    }
                    nextTokenIndex = nextIndex
                }
                if formatter.tokens[nextTokenIndex] != .keyword("import") {
                    // End of imports
                    pushStack()
                    return
                }
            }
        }
        // End of imports
        importStack.append(importRanges)
        return importStack
    }

    // All specifiers
    static let allSpecifiers = Set(specifierOrder)

    // ACL specifiers
    static let aclSpecifiers = ["private", "fileprivate", "internal", "public"]

    // Swift specifier keywords, in preferred order
    static let specifierOrder = [
        "private", "fileprivate", "internal", "public", "open",
        "private(set)", "fileprivate(set)", "internal(set)", "public(set)",
        "final", "dynamic", // Can't be both
        "optional", "required",
        "convenience",
        "override",
        "indirect",
        "lazy",
        "weak", "unowned",
        "static", "class",
        "mutating", "nonmutating",
        "prefix", "postfix",
    ]
}
