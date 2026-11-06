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
    func exhaustiveSwitchCases(for type: ProjectSymbolLookup.ResolvedType, resolver: ProjectSymbolLookup) -> [String]? {
        guard !type.isMetatype else { return nil }
        if let wrapped = resolver.unwrapped(type) {
            return exhaustiveSwitchCases(for: wrapped, resolver: resolver).map { cases in
                cases.map { "some(\(exhaustiveSwitchPattern(for: $0, type: wrapped, resolver: resolver)))" } + ["none"]
            }
        }
        if let elements = type.tupleElements {
            guard let domains = exhaustiveSwitchTupleDomains(for: elements, resolver: resolver) else { return nil }
            var combinations = [[String]()]
            for (element, cases) in zip(elements, domains) {
                combinations = combinations.flatMap { prefix in
                    cases.map { prefix + [exhaustiveSwitchPattern(for: $0, type: element.type, resolver: resolver)] }
                }
            }
            return combinations.map { "(" + $0.joined(separator: ", ") + ")" }
        }
        guard let name = resolver.qualifiedName(for: type) else { return nil }
        if type.sourceFileURL == nil || type.sourceFileURL == resolver.fileURL, let local = resolver.localTypes[name], local.count == 1, let declaration = local.first {
            return indexedEnumCases(in: declaration)
        }
        return resolver.project.enumCases(named: name, visibleFrom: type.sourceFileURL ?? resolver.fileURL, requiringExhaustive: true)
    }

    /// Swift's exhaustiveness checker also has a budget for Cartesian products. Compact
    /// Optional axes first; preserve a default if the remaining product is still too large.
    func exhaustiveSwitchTupleDomains(for elements: [ProjectSymbolLookup.TupleElement],
                                      resolver: ProjectSymbolLookup) -> [[String]]?
    {
        var domains = elements.compactMap { exhaustiveSwitchCases(for: $0.type, resolver: resolver) }
        guard domains.count == elements.count else { return nil }
        func patternComplexity() -> Double {
            let count = domains.reduce(1.0) { $0 * Double($1.count) }
            let nodes = zip(elements, domains).reduce(1) { total, entry in
                let (element, cases) = entry
                return total + (cases.map {
                    tokenize(exhaustiveSwitchPattern(for: $0, type: element.type, resolver: resolver))
                        .filter { !$0.isSpaceOrCommentOrLinebreak }.count
                }.max() ?? 0)
            }
            return count * Double(nodes)
        }
        if patternComplexity() > 512 {
            domains = zip(elements, domains).map { element, cases in
                resolver.unwrapped(element.type) == nil ? cases : ["some", "none"]
            }
        }
        guard patternComplexity() <= 512 else { return nil }
        return domains
    }

    func expandSwitchDefault(at switchIndex: Int, resolver: ProjectSymbolLookup) {
        guard let openBrace = index(of: .startOfScope("{"), after: switchIndex),
              let closeBrace = endOfScope(at: openBrace),
              !tokens[openBrace ... closeBrace].contains(.startOfScope("#if")),
              let subject = index(of: .nonSpaceOrCommentOrLinebreak, after: switchIndex),
              let subjectEnd = index(of: .nonSpaceOrCommentOrLinebreak, before: openBrace),
              let type = resolver.expressionType(in: subject ... subjectEnd),
              let cases = exhaustiveSwitchCases(for: type, resolver: resolver),
              let branches = switchStatementBranches(at: switchIndex)
        else { return }
        // Earlier patterns consume the compiler's exhaustiveness budget too. A 9-by-9
        // equality switch can exceed it even though the same default-only product compiles.
        guard type.tupleElements == nil || branches.count == 1 || cases.count <= 64 else { return }
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
        // Swift cannot prove exhaustiveness for large nested Optional pattern sets. Enumerate
        // Optional's own cases in that situation; previous branches still match first.
        let remaining: [String]
        if resolver.unwrapped(type) != nil, branches.count == 1 || cases.count > 512 {
            remaining = (cases.contains(where: { $0 != "none" && !covered.contains($0) }) ? ["some"] : []) +
                (covered.contains("none") ? [] : ["none"])
        } else {
            remaining = cases.filter { !covered.contains($0) }
        }
        // An unreachable default may contain comments or code; leave it intact.
        guard let defaultIndex, !remaining.isEmpty else { return }
        updateEnablement(at: defaultIndex)
        guard isEnabled(at: defaultIndex) else { return }
        let replacement = " " + remaining.map { exhaustiveSwitchPattern(for: $0, type: type, resolver: resolver) }.joined(separator: ", ")
        replaceToken(at: defaultIndex, with: [.endOfScope("case")] + tokenize(replacement))
    }

    /// Render Optional patterns explicitly so a wrapped enum's `none` and `some` cases cannot collide.
    func exhaustiveSwitchPattern(for name: String, type: ProjectSymbolLookup.ResolvedType,
                                 resolver: ProjectSymbolLookup) -> String
    {
        if type.tupleElements != nil, resolver.unwrapped(type) == nil {
            return name
        }
        guard let wrapped = resolver.unwrapped(type) else { return ".\(name)" }
        if name == "none" {
            return "nil"
        }
        if name == "some" {
            return "_?"
        }
        if name.hasPrefix("some("), name.hasSuffix(")") {
            let payload = String(name.dropFirst(5).dropLast())
            if wrapped.tupleElements != nil, resolver.unwrapped(wrapped) == nil {
                return ".some(\(payload))"
            }
            let canonical = payload == "nil" ? "none" : String(payload.dropFirst())
            return ".some(\(exhaustiveSwitchPattern(for: canonical, type: wrapped, resolver: resolver)))"
        }
        return ".\(name)"
    }

    func exhaustiveSwitchCoveredCases(in range: Range<Int>, type: ProjectSymbolLookup.ResolvedType,
                                      resolver: ProjectSymbolLookup, cases: [String], bindsPayloads: Bool = false) -> [String]
    {
        guard index(of: .keyword("where"), in: range) == nil else { return [] }
        let significant = tokens[range].filter { !$0.isSpaceOrCommentOrLinebreak }
        if significant == [.identifier("_")] ||
            significant.count == 2 && [.keyword("let"), .keyword("var")].contains(significant[0]) &&
            significant[1].isIdentifier && !significant[1].isLiteralIdentifier ||
            bindsPayloads && significant.count == 1 && significant[0].isIdentifier && !significant[0].isLiteralIdentifier
        {
            return cases
        }
        if let elements = type.tupleElements, resolver.unwrapped(type) == nil {
            guard let open = index(of: .startOfScope("("), in: range),
                  tokens[range.lowerBound ..< open].allSatisfy({ $0.isSpaceOrCommentOrLinebreak || $0 == .keyword("let") || $0 == .keyword("var") }),
                  let close = endOfScope(at: open),
                  index(of: .nonSpaceOrCommentOrLinebreak, in: close + 1 ..< range.upperBound) == nil else { return [] }
            let arguments = parseTupleArguments(startOfScope: open)
            guard arguments.count == elements.count else { return [] }
            let bindsAll = bindsPayloads || tokens[range.lowerBound ..< open].contains(.keyword("let")) ||
                tokens[range.lowerBound ..< open].contains(.keyword("var"))
            var combinations = [[String]()]
            guard let domains = exhaustiveSwitchTupleDomains(for: elements, resolver: resolver) else { return [] }
            for ((argument, element), domain) in zip(zip(arguments, elements), domains) {
                let covered = exhaustiveSwitchCoveredCases(in: Range(argument.valueRange), type: element.type,
                                                           resolver: resolver, cases: domain, bindsPayloads: bindsAll)
                combinations = combinations.flatMap { prefix in
                    covered.map { prefix + [exhaustiveSwitchPattern(for: $0, type: element.type, resolver: resolver)] }
                }
            }
            return combinations.map { "(" + $0.joined(separator: ", ") + ")" }
        }
        guard let wrapped = resolver.unwrapped(type),
              let wrappedCases = exhaustiveSwitchCases(for: wrapped, resolver: resolver)
        else {
            return exhaustiveSwitchCoveredCase(in: range, type: type, resolver: resolver, cases: cases, bindsPayloads: bindsPayloads).map { [$0] } ?? []
        }
        let unbound = significant.filter { $0 != .keyword("let") && $0 != .keyword("var") }
        if unbound.string == "nil" || unbound.string == ".none" {
            return ["none"]
        }
        if exhaustiveSwitchCoveredCase(in: range, type: type, resolver: resolver, cases: ["some"]) != nil {
            return cases.filter { $0 != "none" }
        }
        if let open = index(of: .startOfScope("("), in: range),
           tokens[range.lowerBound ..< open].filter({ !$0.isSpaceOrCommentOrLinebreak && $0 != .keyword("let") && $0 != .keyword("var") }).string == ".some",
           let close = endOfScope(at: open), open + 1 < close,
           index(of: .nonSpaceOrCommentOrLinebreak, in: close + 1 ..< range.upperBound) == nil,
           close < range.upperBound
        {
            return exhaustiveSwitchCoveredCases(in: open + 1 ..< close, type: wrapped, resolver: resolver,
                                                cases: wrappedCases, bindsPayloads: bindsPayloads || tokens[range.lowerBound ..< open].contains(.keyword("let")) ||
                                                    tokens[range.lowerBound ..< open].contains(.keyword("var"))).map {
                "some(\(exhaustiveSwitchPattern(for: $0, type: wrapped, resolver: resolver)))"
            }
        }
        let end = unbound.last?.isOperator("?") == true
            ? index(of: .nonSpaceOrCommentOrLinebreak, before: range.upperBound) ?? range.upperBound : range.upperBound
        return exhaustiveSwitchCoveredCases(in: range.lowerBound ..< end, type: wrapped, resolver: resolver,
                                            cases: wrappedCases, bindsPayloads: bindsPayloads).map {
            "some(\(exhaustiveSwitchPattern(for: $0, type: wrapped, resolver: resolver)))"
        }
    }

    /// Only subtract patterns that cover the entire case, including all of its payloads.
    func exhaustiveSwitchCoveredCase(in range: Range<Int>, type: ProjectSymbolLookup.ResolvedType,
                                     resolver: ProjectSymbolLookup, cases: [String], bindsPayloads: Bool = false) -> String?
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
            if head == unescaped,
               let start = index(of: .nonSpaceOrCommentOrLinebreak, in: range),
               let reference = resolver.unqualifiedEnumCase(named: head, at: start),
               resolver.sameType(reference.type, as: type)
            {
                return true
            }
            guard head.hasSuffix(".\(unescaped)"),
                  let end = index(of: .nonSpaceOrCommentOrLinebreak, before: payload ?? range.upperBound),
                  let dot = index(of: .nonSpaceOrCommentOrLinebreak, before: end), tokens[dot].isOperator("."),
                  let start = index(in: range, where: { !$0.isSpaceOrCommentOrLinebreak && $0 != .keyword("let") && $0 != .keyword("var") }),
                  start < dot, var prefix = resolver.expressionType(in: start ... dot - 1), prefix.isMetatype
            else { return false }
            // A qualified case uses the enum's metatype to name a case of its instance type.
            prefix.isMetatype = false
            return resolver.sameType(prefix, as: type)
        }) else { return nil }
        guard let payload else { return name }
        guard let end = endOfScope(at: payload),
              index(of: .nonSpaceOrCommentOrLinebreak, in: end + 1 ..< range.upperBound) == nil else { return nil }
        let bindsAll = bindsPayloads || tokens[range.lowerBound ..< payload].contains(.keyword("let")) ||
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
