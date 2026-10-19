//
//  RedundantSwiftVersionCheck.swift
//  SwiftFormat
//
//  Created by Yang Bai on 18/10/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove `#if swift(...)` and `#if compiler(...)` checks that are always
    /// satisfied, or never satisfied, by the specified Swift version
    static let redundantSwiftVersionCheck = FormatRule(
        help: """
        Remove `#if swift(...)` and `#if compiler(...)` checks that are always true or always \
        false for the specified `--swift-version` and `--language-mode`.
        """
    ) { formatter in
        guard formatter.options.swiftVersion != .undefined else { return }
        formatter.forEach(.startOfScope("#if")) { ifIndex, _ in
            formatter.removeRedundantSwiftVersionChecks(at: ifIndex)
        }
    } examples: {
        """
        With `--swift-version 5.9` or later:

        ```diff
        - #if compiler(>=5.9)
          @Observable
          final class Model {}
        - #else
        - final class Model: ObservableObject {}
        - #endif
        ```

        ```diff
        - #if compiler(>=5.5) && canImport(_Concurrency)
        + #if canImport(_Concurrency)
          extension Client {
              func fetch() async throws -> Data { ... }
          }
          #endif
        ```

        `swift(...)` checks use the language mode. For example, a Swift 6 compiler
        in Swift 5 mode satisfies `swift(>=5.10)` but not `swift(>=6)`.
        """
    }
}

extension Formatter {
    /// A `#if`, `#elseif` or `#else` clause of a conditional compilation block
    struct ConditionalCompilationClause {
        /// The index of the `#if`, `#elseif` or `#else` token
        var keywordIndex: Int
        /// The range of the clause's condition, or `nil` for an `#else` clause
        var conditionRange: ClosedRange<Int>?
        /// Whether the condition is known to be true or false for the current Swift version
        var value: Bool?
    }

    /// Removes the redundant Swift version checks from the `#if` block at the given index,
    /// along with any branches that can never be compiled
    func removeRedundantSwiftVersionChecks(at ifIndex: Int) {
        guard let (clauses, endifIndex) = conditionalCompilationClauses(at: ifIndex) else { return }

        // Branches before the first satisfied one can't be compiled if their condition is false,
        // and branches after it can't be compiled at all
        var removedClauses = IndexSet()
        var firstKeptClause: Int?
        var satisfiedClause: Int?
        for (offset, clause) in clauses.enumerated() {
            if clause.value == false {
                removedClauses.insert(offset)
                continue
            }
            firstKeptClause = firstKeptClause ?? offset
            if clause.value == true {
                satisfiedClause = offset
                removedClauses.insert(integersIn: offset + 1 ..< clauses.count)
                break
            }
        }

        guard let firstKeptClause else {
            // No branch can be compiled, so remove the whole block
            removeLines(from: ifIndex, through: endifIndex)
            return
        }

        if satisfiedClause == firstKeptClause {
            // Only this branch can be compiled, so keep its body without the directives
            let keywordIndex = clauses[firstKeptClause].keywordIndex
            let endOfBody = clauses.indices.contains(firstKeptClause + 1)
                ? clauses[firstKeptClause + 1].keywordIndex : endifIndex
            removeLines(from: endOfBody, through: endifIndex)
            removeLines(from: ifIndex, through: keywordIndex)
            return
        }

        for (offset, clause) in clauses.enumerated().reversed() {
            let keywordIndex = clause.keywordIndex
            if removedClauses.contains(offset) {
                let nextKeywordIndex = clauses.indices.contains(offset + 1)
                    ? clauses[offset + 1].keywordIndex : endifIndex
                removeTokens(in: startOfLine(at: keywordIndex) ..< startOfLine(at: nextKeywordIndex))
            } else if let conditionRange = clause.conditionRange {
                if offset == satisfiedClause {
                    removeTokens(in: keywordIndex + 1 ... conditionRange.upperBound)
                    replaceToken(at: keywordIndex, with: .keyword("#else"))
                } else {
                    removeRedundantSwiftVersionChecks(inCondition: conditionRange)
                    if offset == firstKeptClause, tokens[keywordIndex] == .keyword("#elseif") {
                        replaceToken(at: keywordIndex, with: .startOfScope("#if"))
                    }
                }
            }
        }
    }

    /// Returns the clauses of the `#if` block at the given index, and the index of its `#endif`,
    /// or `nil` if the block can't safely be modified
    func conditionalCompilationClauses(at ifIndex: Int) -> (
        clauses: [ConditionalCompilationClause], endifIndex: Int
    )? {
        guard let directives = conditionalCompilationDirectives(at: ifIndex), let endifIndex = directives.last else {
            return nil
        }

        var clauses = [ConditionalCompilationClause]()
        for keywordIndex in directives {
            // Each directive must be on its own line, optionally followed by a comment
            guard startOfLine(at: keywordIndex, excludingIndent: true) == keywordIndex,
                  index(of: .linebreak, after: keywordIndex) ?? tokens.count == endOfLine(at: keywordIndex)
            else { return nil }

            guard keywordIndex != endifIndex else { continue }
            guard tokens[keywordIndex] != .keyword("#else") else {
                clauses.append(ConditionalCompilationClause(keywordIndex: keywordIndex, value: true))
                continue
            }
            let endOfLine = endOfLine(at: keywordIndex)
            guard let conditionStart = index(of: .nonSpaceOrComment, after: keywordIndex),
                  let conditionEnd = lastIndex(of: .nonSpaceOrComment, in: keywordIndex + 1 ..< endOfLine),
                  conditionStart <= conditionEnd
            else { return nil }
            let conditionRange = conditionStart ... conditionEnd
            clauses.append(ConditionalCompilationClause(
                keywordIndex: keywordIndex,
                conditionRange: conditionRange,
                value: swiftVersionConditionValue(in: conditionRange)
            ))
        }
        return (clauses, endifIndex)
    }

    /// Whether the conditional compilation condition in the given range is always true or always false
    /// for the current Swift version, or `nil` if that isn't known
    func swiftVersionConditionValue(in range: ClosedRange<Int>) -> Bool? {
        let disjuncts = conditionOperands(in: range, separatedBy: "||")
        if disjuncts.count > 1 {
            let values = disjuncts.map(swiftVersionConditionValue(in:))
            if values.contains(true) {
                return true
            }
            return values.allSatisfy { $0 == false } ? false : nil
        }

        let conjuncts = conditionOperands(in: range, separatedBy: "&&")
        if conjuncts.count > 1 {
            let values = conjuncts.map(swiftVersionConditionValue(in:))
            if values.contains(false) {
                return false
            }
            return values.allSatisfy { $0 == true } ? true : nil
        }

        if let operand = negatedOrParenthesizedCondition(in: range) {
            let value = swiftVersionConditionValue(in: operand)
            return tokens[range.lowerBound] == .operator("!", .prefix) ? value.map(!) : value
        }

        return versionCheckValue(in: range)
    }

    /// Whether the `swift(...)` or `compiler(...)` check in the given range is always true or always false
    /// for the current Swift version, or `nil` if that isn't known
    func versionCheckValue(in range: ClosedRange<Int>) -> Bool? {
        guard case let .identifier(name) = tokens[range.lowerBound],
              ["swift", "compiler"].contains(name),
              let openParenIndex = index(of: .nonSpaceOrComment, after: range.lowerBound),
              tokens[openParenIndex] == .startOfScope("("),
              endOfScope(at: openParenIndex) == range.upperBound,
              let operatorIndex = index(of: .nonSpaceOrComment, after: openParenIndex),
              case let .operator(comparison, _) = tokens[operatorIndex],
              [">=", "<"].contains(comparison),
              let versionStart = index(of: .nonSpaceOrComment, after: operatorIndex),
              let versionEnd = index(of: .nonSpaceOrComment, before: range.upperBound),
              versionStart <= versionEnd,
              let version = Version(rawValue: tokens[versionStart ... versionEnd].string)
        else { return nil }

        // The Swift version option is the oldest compiler the code is built with,
        // so only checks for that version or older have a known result
        let minimumVersion = name == "swift" ? minimumLanguageVersion : options.swiftVersion
        guard let isSatisfied = minimumVersion.isAtLeast(version), isSatisfied else { return nil }
        return comparison == ">="
    }

    /// The oldest language version that `swift(...)` checks can report for the current options
    var minimumLanguageVersion: Version {
        let compilerVersion = options.swiftVersion, languageMode = options.languageMode
        guard let compilerMajorVersion = compilerVersion.majorVersion,
              let languageMajorVersion = languageMode.majorVersion
        else { return .undefined }
        if languageMajorVersion >= compilerMajorVersion {
            return compilerVersion
        }
        // A Swift 6 compiler in Swift 5 mode reports a language version of 5.10
        return languageMajorVersion == 5 ? "5.10" : languageMode
    }

    /// Splits the condition in the given range at each of its top-level `operator` tokens
    func conditionOperands(in range: ClosedRange<Int>, separatedBy operator: String) -> [ClosedRange<Int>] {
        var operands = [ClosedRange<Int>]()
        var operandStart = range.lowerBound
        while let operatorIndex = index(in: operandStart ..< range.upperBound, where: {
            $0 == .operator(`operator`, .infix)
        }) {
            guard let operandEnd = index(of: .nonSpaceOrComment, before: operatorIndex),
                  let nextOperandStart = index(of: .nonSpaceOrComment, after: operatorIndex),
                  operandStart <= operandEnd, nextOperandStart <= range.upperBound
            else { return [range] }
            operands.append(operandStart ... operandEnd)
            operandStart = nextOperandStart
        }
        operands.append(operandStart ... range.upperBound)
        return operands
    }

    /// Removes the satisfied operands of `&&` conditions, and the unsatisfied operands of `||` conditions,
    /// from the condition in the given range
    func removeRedundantSwiftVersionChecks(inCondition range: ClosedRange<Int>) {
        for (separator, redundantValue) in [("||", false), ("&&", true)] {
            let operands = conditionOperands(in: range, separatedBy: separator)
            guard operands.count > 1 else { continue }
            let isRedundant = operands.map { swiftVersionConditionValue(in: $0) == redundantValue }
            guard let firstKeptOperand = isRedundant.firstIndex(of: false) else { return }
            for offset in (firstKeptOperand ..< operands.count).reversed() {
                if isRedundant[offset] {
                    removeTokens(in: operands[offset - 1].upperBound + 1 ... operands[offset].upperBound)
                } else {
                    removeRedundantSwiftVersionChecks(inCondition: operands[offset])
                }
            }
            if firstKeptOperand > 0 {
                removeTokens(in: operands[0].lowerBound ..< operands[firstKeptOperand].lowerBound)
            }
            return
        }
        if let operand = negatedOrParenthesizedCondition(in: range) {
            removeRedundantSwiftVersionChecks(inCondition: operand)
        }
    }

    /// Returns the range of the operand of a `!` condition, or the contents of a parenthesized condition
    func negatedOrParenthesizedCondition(in range: ClosedRange<Int>) -> ClosedRange<Int>? {
        switch tokens[range.lowerBound] {
        case .operator("!", .prefix):
            guard let operandIndex = index(of: .nonSpaceOrComment, after: range.lowerBound),
                  operandIndex <= range.upperBound
            else { return nil }
            return operandIndex ... range.upperBound
        case .startOfScope("("):
            guard endOfScope(at: range.lowerBound) == range.upperBound,
                  let firstIndex = index(of: .nonSpaceOrComment, after: range.lowerBound),
                  let lastIndex = index(of: .nonSpaceOrComment, before: range.upperBound),
                  firstIndex <= lastIndex
            else { return nil }
            return firstIndex ... lastIndex
        default:
            return nil
        }
    }

    /// Removes the lines from the one containing `startIndex` to the one containing `endIndex`, inclusive
    func removeLines(from startIndex: Int, through endIndex: Int) {
        let startOfLine = startOfLine(at: startIndex)
        let endOfLine = endOfLine(at: endIndex)
        if endOfLine < tokens.count {
            removeTokens(in: startOfLine ... endOfLine)
        } else {
            // There's no linebreak after the last line, so remove the one before the first line
            removeTokens(in: max(0, startOfLine - 1) ..< tokens.count)
        }
    }
}

extension Version {
    /// The major version number, if numeric
    var majorVersion: Int? {
        rawValue.split(separator: ".").first.flatMap { Int($0) }
    }

    /// Whether this version is the same as or newer than the given version, treating
    /// missing components as zero, or `nil` if either version is non-numeric
    func isAtLeast(_ other: Version) -> Bool? {
        func components(of version: Version) -> [Int]? {
            var components = [Int]()
            for part in version.rawValue.split(separator: ".", omittingEmptySubsequences: false) {
                guard let component = Int(part) else { return nil }
                components.append(component)
            }
            while components.last == 0 {
                components.removeLast()
            }
            return components
        }
        guard let lhs = components(of: self), let rhs = components(of: other) else { return nil }
        return !lhs.lexicographicallyPrecedes(rhs)
    }
}
