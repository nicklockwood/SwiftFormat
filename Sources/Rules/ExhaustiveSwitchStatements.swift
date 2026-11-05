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
        let bindings = formatter.explicitBindingTypes()
        let declarations = formatter.parseDeclarations()
        var aliases = Set<String>()
        formatter.forEach(.keyword("typealias")) { i, _ in
            if let name = formatter.next(.identifier, after: i)?.string {
                aliases.insert(name)
            }
        }
        formatter.forEach(.keyword("switch")) { switchIndex, _ in
            formatter.expandSwitchDefault(at: switchIndex, bindings: bindings, declarations: declarations, aliases: aliases, project: project, fileURL: fileURL)
        }
    } examples: {
        """
        ```diff
          enum State { case idle, loading, loaded, failed }
          func render(_ state: State) {
              switch state {
              case .loaded: showContent()
        -     default: showPlaceholder()
        +     case .idle, .loading, .failed: showPlaceholder()
              }
          }
        ```

        Requires the project index. Unknown defaults and unresolved types are preserved.
        """
    }
}

extension Formatter {
    func expandSwitchDefault(
        at switchIndex: Int, bindings: [String: [ExplicitBindingType]], declarations: [Declaration], aliases: Set<String>, project: ProjectIndex, fileURL: URL
    ) {
        guard let openBrace = index(of: .startOfScope("{"), after: switchIndex),
              let closeBrace = endOfScope(at: openBrace),
              !tokens[openBrace ... closeBrace].contains(.startOfScope("#if")),
              let subject = index(of: .nonSpaceOrCommentOrLinebreak, after: switchIndex),
              let subjectEnd = index(of: .nonSpaceOrCommentOrLinebreak, before: openBrace),
              let type = exhaustiveSwitchSubjectType(in: subject ... subjectEnd, bindings: bindings, declarations: declarations),
              !tokenize(type).contains(where: { $0.isIdentifier && aliases.contains($0.string) }),
              let cases = exhaustiveSwitchEnumCases(
                  named: type, at: bindings[tokens[subject].string]?.first?.scope.map { $0.range.lowerBound + 1 },
                  declarations: declarations, project: project, fileURL: fileURL
              ),
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
            // A where clause only handles a subset of its case.
            if index(of: .keyword("where"), in: keyword + 1 ..< branch.startOfBranch) != nil {
                continue
            }
            var start = keyword + 1
            while start < branch.startOfBranch {
                let end = index(of: .delimiter(","), in: start ..< branch.startOfBranch) ?? branch.startOfBranch
                if let name = exhaustiveSwitchCoveredCase(in: start ..< end, type: type, cases: cases) {
                    covered.insert(name)
                }
                start = end + 1
            }
        }
        let remaining = cases.filter { !covered.contains($0) }
        // An unreachable default may contain comments or code; leave it intact.
        guard let defaultIndex, !remaining.isEmpty else { return }
        updateEnablement(at: defaultIndex)
        guard isEnabled(at: defaultIndex) else { return }
        let replacement = "case " + remaining.map { ".\($0)" }.joined(separator: ", ")
        replaceToken(at: defaultIndex, with: tokenize(replacement))
    }

    /// A nested type shadows the same name at module scope, even when it is not an enum.
    func exhaustiveSwitchEnumCases(
        named name: String, at index: Int?, declarations: [Declaration], project: ProjectIndex, fileURL: URL
    ) -> [String]? {
        var namespace = index.flatMap { parseEnclosingType(containing: $0, declarations: declarations)?.fullyQualifiedName }
        while let owner = namespace {
            let qualified = "\(owner).\(name)"
            if project.containsType(named: qualified, visibleFrom: fileURL) {
                return project.enumCases(named: qualified, visibleFrom: fileURL)
            }
            guard project.isTypeWithoutInheritance(named: owner, visibleFrom: fileURL) else { return nil }
            namespace = owner.contains(".") ? owner.split(separator: ".").dropLast().joined(separator: ".") : nil
        }
        return project.enumCases(named: name, visibleFrom: fileURL)
    }

    /// Restrict the prototype to explicit, unambiguous bindings and `self`.
    func exhaustiveSwitchSubjectType(
        in range: ClosedRange<Int>, bindings: [String: [ExplicitBindingType]], declarations: [Declaration]
    ) -> String? {
        if range.lowerBound == range.upperBound {
            let subject = tokens[range.lowerBound]
            if subject == .identifier("self") {
                return parseEnclosingType(containing: range.lowerBound, declarations: declarations)?.fullyQualifiedName
            }
            guard subject.isIdentifier else { return nil }
            return staticMemberBindingType(named: subject.string, at: range.lowerBound, bindings: bindings)
        }
        return nil
    }

    /// Only subtract patterns that cover the entire case, including all of its payloads.
    func exhaustiveSwitchCoveredCase(in range: Range<Int>, type: String, cases: [String]) -> String? {
        let payload = index(of: .startOfScope("("), in: range)
        let head = tokens[range.lowerBound ..< (payload ?? range.upperBound)]
            .filter { !$0.isSpaceOrCommentOrLinebreak && $0 != .keyword("let") && $0 != .keyword("var") }
            .string
        guard let name = cases.first(where: { head == ".\($0)" || head == "\(type).\($0)" }) else { return nil }
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
