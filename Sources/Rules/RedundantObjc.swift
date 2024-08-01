//
//  RedundantObjc.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove redundant @objc annotation
    static let redundantObjc = FormatRule(
        help: "Remove redundant `@objc` annotations."
    ) { formatter in
        let objcAttributes = [
            "@IBOutlet", "@IBAction", "@IBSegueAction",
            "@IBDesignable", "@IBInspectable", "@GKInspectable",
            "@NSManaged",
        ]

        formatter.forEach(.keyword("@objc")) { i, _ in
            guard formatter.next(.nonSpaceOrCommentOrLinebreak, after: i) != .startOfScope("(") else {
                return
            }
            var index = i
            loop: while var nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index) {
                switch formatter.tokens[nextIndex] {
                case .keyword("class"), .keyword("actor"), .keyword("enum"),
                     // Not actually allowed currently, but: future-proofing!
                     .keyword("protocol"), .keyword("struct"):
                    return
                case .keyword("private"), .keyword("fileprivate"):
                    if formatter.next(.nonSpaceOrComment, after: nextIndex) == .startOfScope("(") {
                        break
                    }
                    // Can't safely remove objc from private members
                    return
                case let token where token.isAttribute:
                    if let startIndex = formatter.index(of: .startOfScope("("), after: nextIndex),
                       let endIndex = formatter.index(of: .endOfScope(")"), after: startIndex)
                    {
                        nextIndex = endIndex
                    }
                case let token:
                    guard token.isModifierKeyword else {
                        break loop
                    }
                }
                index = nextIndex
            }
            if formatter.last(.nonSpaceOrCommentOrLinebreak, before: i, if: {
                $0.isAttribute && objcAttributes.contains($0.string)
            }) != nil || formatter.next(.nonSpaceOrCommentOrLinebreak, after: i, if: {
                $0.isAttribute && objcAttributes.contains($0.string)
            }) != nil {
                formatter.removeAttribute(at: i)
                return
            }
            guard let scopeStart = formatter.index(of: .startOfScope("{"), before: i),
                  let keywordIndex = formatter.index(of: .keyword, before: scopeStart)
            else {
                return
            }
            switch formatter.tokens[keywordIndex] {
            case .keyword("class"), .keyword("actor"):
                if formatter.modifiersForDeclaration(at: keywordIndex, contains: "@objcMembers") {
                    formatter.removeAttribute(at: i)
                }
            case .keyword("extension"):
                if formatter.modifiersForDeclaration(at: keywordIndex, contains: "@objc") {
                    formatter.removeAttribute(at: i)
                }
            default:
                break
            }
        }
    }
}

extension Formatter {
    func removeAttribute(at i: Int) {
        removeToken(at: i)
        if token(at: i)?.isSpace == true {
            removeToken(at: i)
        } else if token(at: i - 1)?.isSpace == true {
            removeToken(at: i - 1)
        }
    }
}
