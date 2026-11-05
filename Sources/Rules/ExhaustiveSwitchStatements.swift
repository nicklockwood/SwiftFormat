//
//  ExhaustiveSwitchStatements.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 11/05/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Replaces defaults with the remaining cases of a project-indexed enum.
    static let exhaustiveSwitchStatements = FormatRule(
        help: "Replace switch defaults with exhaustive cases from the project index.",
        disabledByDefault: true
    ) { formatter in
        guard formatter.tokens.contains(.endOfScope("default")),
              let fileURL = formatter.currentFileURL,
              let project = formatter.projectIndex(requiring: [.declarations]) else { return }
        let resolver = ProjectSymbolLookup(formatter: formatter, project: project, fileURL: fileURL)
        formatter.forEach(.keyword("switch")) { switchIndex, _ in
            formatter.expandSwitchDefault(at: switchIndex, resolver: resolver)
        }
    } examples: {
        """
        ```diff
          enum State { case idle, loading, loaded, failed }
          func render(_ state: State) {
              switch state {
              case .loaded:
                  showContent()
        -     default:
        +     case .idle, .loading, .failed:
                  showPlaceholder()
              }
          }
        ```

        Requires the project index. Unknown defaults and unresolved types are preserved.
        """
    }
}

extension Formatter {
    func exhaustiveSwitchEnumCases(for type: ProjectSymbolLookup.ResolvedType, resolver: ProjectSymbolLookup) -> [String]? {
        guard !type.isMetatype else { return nil }
        if let wrapped = resolver.unwrapped(type) {
            return exhaustiveSwitchEnumCases(for: wrapped, resolver: resolver).map { $0.map { "some(.\($0))" } + ["none"] }
        }
        guard let name = resolver.qualifiedName(for: type) else { return nil }
        if type.sourceFileURL == nil || type.sourceFileURL == resolver.fileURL, let local = resolver.localTypes[name], local.count == 1, let declaration = local.first {
            return indexedEnumCases(in: declaration)
        }
        return resolver.project.enumCases(named: name, visibleFrom: type.sourceFileURL ?? resolver.fileURL)
    }

    func expandSwitchDefault(at switchIndex: Int, resolver: ProjectSymbolLookup) {
        guard let openBrace = index(of: .startOfScope("{"), after: switchIndex),
              let closeBrace = endOfScope(at: openBrace),
              !tokens[openBrace ... closeBrace].contains(.startOfScope("#if")),
              let subject = index(of: .nonSpaceOrCommentOrLinebreak, after: switchIndex),
              let subjectEnd = index(of: .nonSpaceOrCommentOrLinebreak, before: openBrace),
              let type = resolver.expressionType(in: subject ... subjectEnd),
              let cases = exhaustiveSwitchEnumCases(for: type, resolver: resolver),
              let branches = switchStatementBranches(at: switchIndex)
        else { return }
        var defaultIndex: Int?
        var covered = Set<String>()
        for branch in branches {
            guard let keyword = index(before: branch.startOfBranch, where: { $0.isSwitchCaseOrDefault }) else { return }
            if tokens[keyword] == .endOfScope("default") {
                guard last(.nonSpaceOrCommentOrLinebreak, before: keyword) != .keyword("@unknown") else { return }
                defaultIndex = keyword
                continue
            }
            var start = keyword + 1
            while start < branch.startOfBranch {
                let end = index(of: .delimiter(","), in: start ..< branch.startOfBranch) ?? branch.startOfBranch
                covered.formUnion(exhaustiveSwitchCoveredCases(in: start ..< end, type: type, resolver: resolver, cases: cases))
                start = end + 1
            }
        }
        let remaining = cases.filter { !covered.contains($0) }
        // An unreachable default may contain comments or code; leave it intact.
        guard let defaultIndex, !remaining.isEmpty else { return }
        updateEnablement(at: defaultIndex)
        guard isEnabled(at: defaultIndex) else { return }
        let replacement = " " + remaining.map { ".\($0)" }.joined(separator: ", ")
        replaceToken(at: defaultIndex, with: [.endOfScope("case")] + tokenize(replacement))
    }

    func exhaustiveSwitchCoveredCases(in range: Range<Int>, type: ProjectSymbolLookup.ResolvedType,
                                      resolver: ProjectSymbolLookup, cases: [String]) -> [String]
    {
        guard index(of: .keyword("where"), in: range) == nil else { return [] }
        guard let wrapped = resolver.unwrapped(type),
              let wrappedCases = exhaustiveSwitchEnumCases(for: wrapped, resolver: resolver)
        else {
            return exhaustiveSwitchCoveredCase(in: range, type: type, resolver: resolver, cases: cases).map { [$0] } ?? []
        }
        let significant = tokens[range].filter { !$0.isSpaceOrCommentOrLinebreak && $0 != .keyword("let") && $0 != .keyword("var") }
        if significant.string == "nil" || significant.string == ".none" {
            return ["none"]
        }
        if exhaustiveSwitchCoveredCase(in: range, type: type, resolver: resolver, cases: ["some"]) != nil {
            return cases.filter { $0 != "none" }
        }
        if let open = index(of: .startOfScope("("), in: range),
           tokens[range.lowerBound ..< open].filter({ !$0.isSpaceOrCommentOrLinebreak && $0 != .keyword("let") && $0 != .keyword("var") }).string == ".some",
           let close = endOfScope(at: open), open + 1 < close,
           index(of: .nonSpaceOrCommentOrLinebreak, in: close + 1 ..< range.upperBound) == nil,
           let name = exhaustiveSwitchCoveredCase(in: open + 1 ..< close, type: wrapped, resolver: resolver, cases: wrappedCases)
        {
            return ["some(.\(name))"]
        }
        let end = significant.last?.isOperator("?") == true
            ? index(of: .nonSpaceOrCommentOrLinebreak, before: range.upperBound) ?? range.upperBound : range.upperBound
        if let name = exhaustiveSwitchCoveredCase(in: range.lowerBound ..< end, type: wrapped, resolver: resolver, cases: wrappedCases) {
            return ["some(.\(name))"]
        }
        return []
    }

    /// Only subtract patterns that cover the entire case, including all of its payloads.
    func exhaustiveSwitchCoveredCase(in range: Range<Int>, type: ProjectSymbolLookup.ResolvedType,
                                     resolver: ProjectSymbolLookup, cases: [String]) -> String?
    {
        // A where clause guards only its own comma-separated pattern.
        guard index(of: .keyword("where"), in: range) == nil else { return nil }
        let payload = index(of: .startOfScope("("), in: range)
        let head = tokens[range.lowerBound ..< (payload ?? range.upperBound)]
            .filter { !$0.isSpaceOrCommentOrLinebreak && $0 != .keyword("let") && $0 != .keyword("var") }
            .string.replacingOccurrences(of: "`", with: "")
        guard let name = cases.first(where: { name in
            let unescaped = name.replacingOccurrences(of: "`", with: "")
            if head == ".\(unescaped)" {
                return true
            }
            guard head.hasSuffix(".\(unescaped)"),
                  let end = index(of: .nonSpaceOrCommentOrLinebreak, before: payload ?? range.upperBound),
                  let dot = index(of: .nonSpaceOrCommentOrLinebreak, before: end), tokens[dot].isOperator("."),
                  let start = index(in: range, where: { !$0.isSpaceOrCommentOrLinebreak && $0 != .keyword("let") && $0 != .keyword("var") }),
                  start < dot, let prefix = resolver.expressionType(in: start ... dot - 1), prefix.isMetatype
            else { return false }
            return resolver.sameType(prefix, as: type)
        }) else { return nil }
        guard let payload else { return name }
        guard let end = endOfScope(at: payload),
              index(of: .nonSpaceOrCommentOrLinebreak, in: end + 1 ..< range.upperBound) == nil else { return nil }
        let bindsAll = tokens[range.lowerBound ..< payload].contains(.keyword("let")) ||
            tokens[range.lowerBound ..< payload].contains(.keyword("var"))
        for argument in parseTupleArguments(startOfScope: payload) {
            let value = tokens[argument.valueRange].filter { !$0.isSpaceOrCommentOrLinebreak }
            if value == [.identifier("_")] {
                continue
            }
            if value.count == 1, value.first?.isIdentifier == true, value.first?.isLiteralIdentifier == false, bindsAll {
                continue
            }
            if value.count == 2, [.keyword("let"), .keyword("var")].contains(value[0]), value[1].isIdentifier, !value[1].isLiteralIdentifier {
                continue
            }
            return nil
        }
        return name
    }
}
