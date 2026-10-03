//
//  RepeatedGuard.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 10/3/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Merge consecutive guard statements that have identical bodies.
    static let repeatedGuard = FormatRule(
        help: "Merge consecutive guard statements that have identical bodies."
    ) { formatter in
        formatter.forEach(.keyword("guard")) { guardIndex, _ in
            while formatter.mergeGuardFollowingGuard(at: guardIndex) {}
        }
    } examples: {
        """
        ```diff
        - guard isValid else { return }
        - guard isEnabled else { return }
        + guard isValid, isEnabled else { return }
        ```
        """
    }
}

extension Formatter {
    /// Merges the guard immediately following the guard at `guardIndex`, if possible.
    func mergeGuardFollowingGuard(at guardIndex: Int) -> Bool {
        guard let firstGuard = repeatedGuardParts(at: guardIndex),
              let nextGuardIndex = index(of: .nonSpaceOrLinebreak, after: firstGuard.bodyRange.upperBound),
              tokens[nextGuardIndex] == .keyword("guard"),
              let secondGuard = repeatedGuardParts(at: nextGuardIndex),
              repeatedGuardBodiesMatch(firstGuard.bodyRange, secondGuard.bodyRange),
              let firstNames = namesDeclaredByRepeatedGuard(at: guardIndex),
              let secondNames = namesDeclaredByRepeatedGuard(at: nextGuardIndex),
              firstNames.isDisjoint(with: secondNames),
              !firstNames.contains(where: { name in
                  tokens[secondGuard.bodyRange].contains(.identifier(name))
              }),
              let firstConditionEnd = index(
                  of: .nonSpaceOrCommentOrLinebreak,
                  before: firstGuard.elseIndex
              )
        else {
            return false
        }

        let removalRange = firstConditionEnd + 1 ... nextGuardIndex
        guard !tokens[removalRange].contains(where: \.isComment) else {
            return false
        }

        replaceTokens(in: removalRange, with: .delimiter(","))
        return true
    }

    /// Returns the `else` keyword and body range for the guard at `guardIndex`.
    func repeatedGuardParts(at guardIndex: Int) -> (elseIndex: Int, bodyRange: ClosedRange<Int>)? {
        guard tokens[guardIndex] == .keyword("guard"),
              let elseIndex = index(of: .keyword("else"), after: guardIndex),
              let bodyStart = index(of: .startOfScope("{"), after: elseIndex),
              let bodyEnd = endOfScope(at: bodyStart)
        else {
            return nil
        }
        return (elseIndex, bodyStart ... bodyEnd)
    }

    /// Compares guard bodies without considering their whitespace formatting.
    func repeatedGuardBodiesMatch(_ lhs: ClosedRange<Int>, _ rhs: ClosedRange<Int>) -> Bool {
        let lhsTokens = tokens[lhs].filter { !$0.isSpaceOrLinebreak }
        let rhsTokens = tokens[rhs].filter { !$0.isSpaceOrLinebreak }
        guard !lhsTokens.contains(where: \.isComment),
              !rhsTokens.contains(where: \.isComment)
        else {
            return false
        }
        return lhsTokens == rhsTokens
    }

    /// Returns names introduced by a guard, or nil for patterns that can't be compared safely.
    func namesDeclaredByRepeatedGuard(at guardIndex: Int) -> Set<String>? {
        let conditions = parseConditionalStatement(at: guardIndex)
        guard !conditions.isEmpty else { return nil }

        var names = Set<String>()
        for condition in conditions {
            switch condition {
            case let .optionalBinding(_, property):
                names.insert(property.identifier)
            case .patternMatching:
                return nil
            case .availabilityCondition, .booleanExpression:
                break
            }
        }
        return names
    }
}
