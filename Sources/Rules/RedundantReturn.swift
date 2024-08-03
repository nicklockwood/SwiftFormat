//
//  RedundantReturn.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove redundant return keyword
    static let redundantReturn = FormatRule(
        help: "Remove unneeded `return` keyword."
    ) { formatter in
        // indices of returns that are safe to remove
        var returnIndices = [Int]()

        // Also handle redundant void returns in void functions, which can always be removed.
        //  - The following code is the original implementation of the `redundantReturn` rule
        //    and is partially redundant with the below code so could be simplified in the future.
        formatter.forEach(.keyword("return")) { i, _ in
            guard let startIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i) else {
                return
            }
            defer {
                // Check return wasn't removed already
                if formatter.token(at: i) == .keyword("return") {
                    returnIndices.append(i)
                }
            }
            switch formatter.tokens[startIndex] {
            case .keyword("in"):
                break
            case .startOfScope("{"):
                guard var prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: startIndex) else {
                    break
                }
                if formatter.options.swiftVersion < "5.1", formatter.isAccessorKeyword(at: prevIndex) {
                    return
                }
                if formatter.tokens[prevIndex] == .endOfScope(")"),
                   let j = formatter.index(of: .startOfScope("("), before: prevIndex)
                {
                    prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: j) ?? j
                    if formatter.tokens[prevIndex] == .operator("?", .postfix) {
                        prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: prevIndex) ?? prevIndex
                    }
                    let prevToken = formatter.tokens[prevIndex]
                    guard prevToken.isIdentifier || prevToken == .keyword("init") else {
                        return
                    }
                }
                let prevToken = formatter.tokens[prevIndex]
                guard ![.delimiter(":"), .startOfScope("(")].contains(prevToken),
                      var prevKeywordIndex = formatter.indexOfLastSignificantKeyword(
                          at: startIndex, excluding: ["where"]
                      )
                else {
                    break
                }
                switch formatter.tokens[prevKeywordIndex].string {
                case "let", "var":
                    guard formatter.options.swiftVersion >= "5.1" || prevToken == .operator("=", .infix) ||
                        formatter.lastIndex(of: .operator("=", .infix), in: prevKeywordIndex + 1 ..< prevIndex) != nil,
                        !formatter.isConditionalStatement(at: prevKeywordIndex)
                    else {
                        return
                    }
                case "func", "throws", "rethrows", "init", "subscript":
                    if formatter.options.swiftVersion < "5.1",
                       formatter.next(.nonSpaceOrCommentOrLinebreak, after: i) != .endOfScope("}")
                    {
                        return
                    }
                default:
                    return
                }
            default:
                guard let endIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i, if: {
                    $0 == .endOfScope("}")
                }), let startIndex = formatter.index(of: .startOfScope("{"), before: endIndex) else {
                    return
                }
                if !formatter.isStartOfClosure(at: startIndex), !["func", "throws", "rethrows"]
                    .contains(formatter.lastSignificantKeyword(at: startIndex, excluding: ["where"]) ?? "")
                {
                    return
                }
            }
            // Don't remove return if it's followed by more code
            guard let endIndex = formatter.endOfScope(at: i),
                  formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i) == endIndex
            else {
                return
            }
            if formatter.index(of: .nonSpaceOrLinebreak, after: i) == endIndex,
               let startIndex = formatter.index(of: .nonSpaceOrLinebreak, before: i)
            {
                formatter.removeTokens(in: startIndex + 1 ... i)
                return
            }
            formatter.removeToken(at: i)
            if var nextIndex = formatter.index(of: .nonSpace, after: i - 1, if: { $0.isLinebreak }) {
                if let i = formatter.index(of: .nonSpaceOrLinebreak, after: nextIndex) {
                    nextIndex = i - 1
                }
                formatter.removeTokens(in: i ... nextIndex)
            } else if formatter.token(at: i)?.isSpace == true {
                formatter.removeToken(at: i)
            }
        }

        // Explicit returns are redundant in closures, functions, etc with a single statement body
        formatter.forEach(.startOfScope("{")) { startOfScopeIndex, _ in
            // Closures always supported implicit returns, but other types of scopes
            // only support implicit return in Swift 5.1+ (SE-0255)
            let isClosure = formatter.isStartOfClosure(at: startOfScopeIndex)
            if formatter.options.swiftVersion < "5.1", !isClosure {
                return
            }

            // Make sure this is a type of scope that supports implicit returns
            if !isClosure, formatter.isConditionalStatement(at: startOfScopeIndex, excluding: ["where"]) ||
                ["do", "else", "catch"].contains(formatter.lastSignificantKeyword(at: startOfScopeIndex, excluding: ["throws"]))
            {
                return
            }

            // Only strip return from conditional block if conditionalAssignment rule is enabled
            let stripConditionalReturn = formatter.options.enabledRules.contains("conditionalAssignment")

            // Make sure the body only has a single statement
            guard formatter.blockBodyHasSingleStatement(
                atStartOfScope: startOfScopeIndex,
                includingConditionalStatements: true,
                includingReturnStatements: true,
                includingReturnInConditionalStatements: stripConditionalReturn
            ) else {
                return
            }

            // Make sure we aren't in a failable `init?`, where explicit return is required unless it's the only statement
            if !isClosure, let lastSignificantKeywordIndex = formatter.indexOfLastSignificantKeyword(at: startOfScopeIndex),
               formatter.next(.nonSpaceOrCommentOrLinebreak, after: startOfScopeIndex) != .keyword("return"),
               formatter.tokens[lastSignificantKeywordIndex] == .keyword("init"),
               let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: lastSignificantKeywordIndex),
               nextToken == .operator("?", .postfix)
            {
                return
            }

            // Find all of the return keywords to remove before we remove any of them,
            // so we can apply additional validation first.
            guard let returnKeywordRangesToRemove = formatter.returnKeywordRangesToRemove(atStartOfScope: startOfScopeIndex, returnIndices: &returnIndices) else { return }

            for returnKeywordRangeToRemove in returnKeywordRangesToRemove.sorted(by: { $0.startIndex > $1.startIndex }) {
                formatter.removeTokens(in: returnKeywordRangeToRemove)
            }
        }
    }
}

extension Formatter {
    func returnKeywordRangesToRemove(atStartOfScope startOfScopeIndex: Int, returnIndices: inout [Int]) -> [Range<Int>]? {
        var returnKeywordRangesToRemove = [Range<Int>]()

        // If this scope is a single-statement if or switch statement then we have to recursively
        // remove the return from each branch of the if statement
        let startOfBody = self.startOfBody(atStartOfScope: startOfScopeIndex)

        if let firstTokenInBody = index(of: .nonSpaceOrCommentOrLinebreak, after: startOfBody),
           let conditionalBranches = conditionalBranches(at: firstTokenInBody)
        {
            for branch in conditionalBranches.reversed() {
                // In Swift 5.9, there's a bug that prevents you from writing an
                // if or switch expression using an `as?` on one of the branches:
                // https://github.com/apple/swift/issues/68764
                //
                //  if condition {
                //    foo as? String
                //  } else {
                //    "bar"
                //  }
                //
                if conditionalBranchHasUnsupportedCastOperator(
                    startOfScopeIndex: branch.startOfBranch)
                {
                    return nil
                }

                returnKeywordRangesToRemove.append(contentsOf: self.returnKeywordRangesToRemove(atStartOfScope: branch.startOfBranch, returnIndices: &returnIndices) ?? [])
            }
        }

        // Otherwise this is a simple case with a single return at the start of the scope
        else if let endOfScopeIndex = endOfScope(at: startOfScopeIndex),
                let returnIndex = index(of: .keyword("return"), after: startOfScopeIndex),
                returnIndices.contains(returnIndex),
                returnIndex < endOfScopeIndex,
                let nextIndex = index(of: .nonSpaceOrLinebreak, after: returnIndex),
                index(of: .nonSpaceOrCommentOrLinebreak, after: returnIndex)! < endOfScopeIndex
        {
            let range = returnIndex ..< nextIndex
            for (i, index) in returnIndices.enumerated().reversed() {
                if range.contains(index) {
                    returnIndices.remove(at: i)
                } else if index > returnIndex {
                    returnIndices[i] -= range.count
                }
            }
            returnKeywordRangesToRemove.append(range)
        }

        return returnKeywordRangesToRemove
    }
}
