//
//  PreferKeyPath.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 7/29/20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let preferKeyPath = FormatRule(
        help: "Convert trivial `map { $0.foo }` closures to keyPath-based syntax.",
        orderAfter: [.redundantCompactMap]
    ) { formatter in
        let bindings = formatter.tokens.contains(where: {
            $0 == .identifier("compactMap") || $0 == .identifier("flatMap")
        }) ? formatter.keyPathReceiverTypes() : [:]
        var project: ProjectIndex?
        formatter.forEach(.startOfScope("{")) { i, _ in
            guard formatter.options.swiftVersion >= "5.2",
                  var prevIndex = formatter.index(of: .nonSpaceOrLinebreak, before: i)
            else {
                return
            }
            var prevToken = formatter.tokens[prevIndex]
            var label: String?
            if prevToken == .delimiter(":"),
               let labelIndex = formatter.index(of: .nonSpace, before: prevIndex),
               case let .identifier(name) = formatter.tokens[labelIndex],
               let prevIndex2 = formatter.index(of: .nonSpaceOrLinebreak, before: labelIndex)
            {
                label = name
                prevToken = formatter.tokens[prevIndex2]
                prevIndex = prevIndex2
            }
            let parenthesized = prevToken == .startOfScope("(")
            if parenthesized {
                prevToken = formatter.last(.nonSpaceOrLinebreak, before: prevIndex) ?? prevToken
            }
            guard case let .identifier(name) = prevToken,
                  ["map", "flatMap", "compactMap", "allSatisfy", "filter", "contains"].contains(name),
                  let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i, if: {
                      $0 == .identifier("$0")
                  }),
                  let endIndex = formatter.endOfScope(at: i),
                  let lastIndex = formatter.index(of: .nonSpaceOrLinebreak, before: endIndex)
            else {
                return
            }
            if let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: endIndex),
               formatter.isLabel(at: nextIndex)
            {
                return
            }
            if name == "contains" {
                if label != "where" {
                    return
                }
            } else if label != nil {
                return
            }
            var replacementTokens: [Token]
            if nextIndex == lastIndex {
                // https://bugs.swift.org/browse/SR-12897
                guard formatter.options.swiftVersion >= "6" else { return }
                replacementTokens = tokenize("\\.self")
            } else {
                let tokens = formatter.tokens[nextIndex + 1 ... lastIndex]
                guard tokens.allSatisfy({ $0.isSpace || $0.isIdentifier || $0.isOperator(".") }) else {
                    return
                }
                replacementTokens = [.operator("\\", .prefix)] + tokens
            }
            if ["compactMap", "flatMap"].contains(name) {
                let functionIndex = parenthesized
                    ? formatter.index(of: .nonSpaceOrLinebreak, before: prevIndex) : prevIndex
                guard let functionIndex,
                      let dot = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: functionIndex),
                      formatter.tokens[dot].isOperator("."),
                      let receiver = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: dot),
                      formatter.tokens[receiver].isIdentifier,
                      formatter.last(.nonSpaceOrCommentOrLinebreak, before: receiver)?.isOperator(".") != true,
                      let types = bindings[formatter.tokens[receiver].string],
                      types.count == 1,
                      let receiverType = types.first, !receiverType.type.isEmpty,
                      receiverType.scope?.range.contains(receiver) != false
                else { return }
                let fileURL = formatter.currentFileURL ?? URL(fileURLWithPath: "/SwiftFormat/Input.swift")
                if project == nil {
                    project = formatter.projectIndex(requiring: [.declarations])
                    if project?.files[fileURL.standardizedFileURL.path]?.moduleIdentifiers.isEmpty != false {
                        project = ProjectIndex(files: [
                            fileURL.standardizedFileURL.path: makeSourceFileIndex(
                                from: sourceCode(for: formatter.tokens),
                                moduleIdentifiers: ["SwiftFormat.CurrentFile"],
                                includeFunctionReferences: false,
                                includeSymbolReferences: false
                            ),
                        ])
                    }
                }
                guard let project,
                      formatter.keyPathResultIsCompatible(
                          in: nextIndex ... lastIndex, receiverType: receiverType.type,
                          method: name, project: project, fileURL: fileURL
                      )
                else { return }
            }
            if let label {
                replacementTokens = [.identifier(label), .delimiter(":"), .space(" ")] + replacementTokens
            }
            if !parenthesized {
                replacementTokens = [.startOfScope("(")] + replacementTokens + [.endOfScope(")")]
            }
            formatter.replaceTokens(in: prevIndex + 1 ... endIndex, with: replacementTokens)
        }
    } examples: {
        """
        ```diff
        - let barArray = fooArray.map { $0.bar }
        + let barArray = fooArray.map(\\.bar)

        - let barArray = fooArray.compactMap { $0.optionalBar }
        + let barArray = fooArray.compactMap(\\.optionalBar)
        ```

        Closures for `compactMap` and `flatMap` are converted only when the return type
        can be determined. This uses the project index when available, otherwise it is
        limited to declarations in the current file.
        """
    }
}

extension Formatter {
    struct KeyPathReceiverType {
        var type: String
        var scope: AutoUpdatingRange?
    }

    /// Only use unambiguous, explicitly typed bindings. Unknown and shadowed names
    /// are deliberately left alone rather than guessing the closure's input type.
    func keyPathReceiverTypes() -> [String: [KeyPathReceiverType]] {
        var types = [String: [KeyPathReceiverType]]()
        var genericNames = Set<String>()
        parseDeclarations().forEachRecursiveDeclaration { declaration in
            if let range = declaration.asTypeDeclaration?.genericParameters?.range {
                genericNames.formUnion(tokens[range].filter(\.isIdentifier).map(\.string))
            }
        }
        forEachToken { i, token in
            if token == .keyword("let") || token == .keyword("var") {
                let property = parsePropertyDeclaration(atIntroducerIndex: i)
                let names = namesInDeclaration(at: i) ?? []
                let scope = startOfScope(at: i).flatMap { start in
                    endOfScope(at: start).map { AutoUpdatingRange(range: start ... $0, formatter: self) }
                }
                for name in names {
                    types[name, default: []].append(.init(
                        type: names.count == 1 ? property?.type?.string ?? "" : "",
                        scope: scope
                    ))
                }
            } else if token.isFunctionDeclarationKeyword,
                      let function = parseFunctionDeclaration(keywordIndex: i)
            {
                if let range = function.genericParameterRange {
                    genericNames.formUnion(tokens[range].filter(\.isIdentifier).map(\.string))
                }
                for argument in function.arguments {
                    if let name = argument.internalLabel {
                        types[name, default: []].append(.init(
                            type: function.genericParameterRange == nil && function.bodyRange != nil ? argument.type.string : "",
                            scope: function.bodyRange.map { AutoUpdatingRange(range: $0, formatter: self) }
                        ))
                    }
                }
            } else if token == .keyword("for"),
                      let end = index(of: .keyword("in"), after: i)
            {
                for token in tokens[i ... end] where token.isIdentifier {
                    types[token.string, default: []].append(.init(type: ""))
                }
            } else if token == .startOfScope("{"), isStartOfClosure(at: i),
                      let arguments = parseClosureArguments(at: i)
            {
                for argument in arguments.argumentIndices {
                    types[tokens[argument].string, default: []].append(.init(type: ""))
                }
                if let captures = arguments.captureListRange {
                    for token in tokens[captures] where token.isIdentifier {
                        types[token.string, default: []].append(.init(type: ""))
                    }
                }
            }
        }
        return types.mapValues { values in
            values.map { value in
                var value = value
                if tokenize(value.type).contains(where: { $0.isIdentifier && genericNames.contains($0.string) }) {
                    value.type = ""
                }
                return value
            }
        }
    }

    func keyPathResultIsCompatible(
        in range: ClosedRange<Int>,
        receiverType: String,
        method: String,
        project: ProjectIndex,
        fileURL: URL
    ) -> Bool {
        let receiver = Formatter(tokenize(receiverType))
        guard let type = receiver.parseType(at: 0) else { return false }
        let isOptionalReceiver = type.isOptionalType
        let element: String
        if isOptionalReceiver {
            element = type.tokens.dropLast().string
        } else if type.isArray,
                  let start = receiver.index(of: .nonSpaceOrCommentOrLinebreak, after: type.range.lowerBound),
                  let elementType = receiver.parseType(at: start)
        {
            element = elementType.string
        } else {
            return false
        }
        let modules = Set(project.files[fileURL.standardizedFileURL.path]?.moduleIdentifiers ?? [])
        let properties = project.files.values
            .filter { !modules.isDisjoint(with: $0.moduleIdentifiers) }
            .flatMap(\.propertyDeclarations)
        var resultType = element
        for token in tokens[range].dropFirst() where token.isIdentifier {
            let matches = properties.filter {
                $0.declaringType == resultType && $0.name == token.string
            }
            guard matches.count == 1, let propertyType = matches.first?.type else { return false }
            resultType = propertyType
        }
        let result = Formatter(tokenize(resultType))
        guard let resultType = result.parseType(at: 0) else { return false }
        // Optional promotion performed for closures is not available to key paths.
        // Sequence.flatMap also accepts non-optional sequences, unlike Optional.flatMap.
        if resultType.isOptionalType {
            return true
        }
        return method == "flatMap" && !isOptionalReceiver &&
            (resultType.isArray || resultType.isDictionary)
    }
}
