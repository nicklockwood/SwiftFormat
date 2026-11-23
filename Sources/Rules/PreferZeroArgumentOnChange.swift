//
//  PreferZeroArgumentOnChange.swift
//  SwiftFormat
//
//  Created by Miguel Jimenez on 2026-11-20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Prefer the zero-argument `onChange(of:)` closure when the old value is ignored
    static let preferZeroArgumentOnChange = FormatRule(
        help: "Prefer the zero-argument SwiftUI `onChange(of:)` closure when the old value is unused.",
        disabledByDefault: true
    ) { formatter in
        formatter.forEach(.identifier("onChange")) { onChangeIndex, _ in
            guard let onChange = formatter.parseOnChangeIgnoringOldValue(at: onChangeIndex),
                  let newValueUsages = formatter.replaceableNewValueUsages(in: onChange)
            else { return }

            // Replace usages of the new value argument with the observed value.
            // Work from the end of the closure so the earlier indices remain valid.
            let observedValue = Array(formatter.tokens[onChange.observedValueRange])
            if [onChange.newValueName] != observedValue.map(\.string) {
                for usageIndex in newValueUsages.reversed() {
                    formatter.replaceToken(at: usageIndex, with: observedValue)
                }
            }

            formatter.removeClosureArguments(in: onChange.argumentsRange)
        }
    } examples: {
        """
        ```diff
          struct SettingsView: View {
            @State private var isOn = false

            var body: some View {
              Toggle("Notifications", isOn: $isOn)
        -       .onChange(of: isOn) { _, newValue in
        -         service.update(isEnabled: newValue)
        +       .onChange(of: isOn) {
        +         service.update(isEnabled: isOn)
                }
            }
          }
        ```

        ```diff
          ScrollView { content }
        -   .onChange(of: store.items) { _, _ in
        +   .onChange(of: store.items) {
              scrollToBottom()
            }
        ```
        """
    }
}

extension Formatter {
    /// A SwiftUI `onChange(of:initial:_:)` call with a trailing closure
    /// that takes two arguments and ignores the old value: `{ _, newValue in ... }`
    struct OnChangeIgnoringOldValue {
        /// The range of the value passed to the `of:` parameter
        let observedValueRange: ClosedRange<Int>
        /// The index of the `{` token of the trailing closure
        let closureStartIndex: Int
        /// The range of the closure arguments, from the first argument to the `in` keyword
        let argumentsRange: ClosedRange<Int>
        /// The name of the closure argument for the new value, which may be `_`
        let newValueName: String
    }

    /// Parses the `onChange(of:initial:_:)` call at the given `onChange` identifier,
    /// if its trailing closure is of the form `{ _, newValue in ... }`.
    func parseOnChangeIgnoringOldValue(at onChangeIndex: Int) -> OnChangeIgnoringOldValue? {
        guard let dotIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: onChangeIndex),
              tokens[dotIndex].isOperator("."),
              let startOfArguments = index(of: .nonSpaceOrCommentOrLinebreak, after: onChangeIndex),
              tokens[startOfArguments] == .startOfScope("("),
              let endOfArguments = endOfScope(at: startOfArguments)
        else { return nil }

        // The call must be `onChange(of: value) { ... }` or `onChange(of: value, initial: bool) { ... }`
        let arguments = parseFunctionCallArguments(startOfScope: startOfArguments)
        guard let observedValue = arguments.first,
              observedValue.label == "of",
              let closure = arguments.last,
              closure.label == nil,
              closure.valueRange.lowerBound > endOfArguments,
              arguments.dropFirst().dropLast().map(\.label) == Array(["initial"].prefix(arguments.count - 2))
        else { return nil }

        // Other libraries define `onChange(of:)` methods where the value is a key path or closure
        // and the two-argument closure is the only supported form, so only handle plain values.
        guard !tokens[observedValue.valueRange.lowerBound].isOperator("\\"),
              tokens[observedValue.valueRange.lowerBound] != .startOfScope("{")
        else { return nil }

        // The closure must be exactly `{ _, newValue in`, with no capture list, attributes, or types
        let closureStartIndex = closure.valueRange.lowerBound
        guard let closureArguments = parseClosureArguments(at: closureStartIndex),
              closureArguments.captureListRange == nil,
              closureArguments.globalActorIndex == nil,
              closureArguments.returnTypeRange == nil,
              closureArguments.argumentIndices.count == 2,
              let parametersRange = closureArguments.parametersRange,
              parametersRange.lowerBound == closureArguments.argumentIndices[0],
              tokens[closureArguments.argumentIndices[0]] == .identifier("_"),
              index(of: .nonSpaceOrLinebreak, after: parametersRange.upperBound) == closureArguments.inKeywordIndex,
              !tokens[parametersRange].contains(where: \.isComment)
        else { return nil }

        return OnChangeIgnoringOldValue(
            observedValueRange: observedValue.valueRange,
            closureStartIndex: closureStartIndex,
            argumentsRange: parametersRange.lowerBound ... closureArguments.inKeywordIndex,
            newValueName: tokens[closureArguments.argumentIndices[1]].string
        )
    }

    /// The indices in the closure body where the new value argument is used, if each of
    /// them can be replaced with the observed value without changing the behavior of the code.
    /// Returns `nil` if the closure should be left as-is.
    func replaceableNewValueUsages(in onChange: OnChangeIgnoringOldValue) -> [Int]? {
        guard let endOfClosure = endOfScope(at: onChange.closureStartIndex) else { return nil }
        let bodyRange = (onChange.argumentsRange.upperBound + 1) ..< endOfClosure
        let newValue = Token.identifier(onChange.newValueName)

        var usages = [Int]()
        for index in bodyRange where tokens[index] == newValue {
            // `foo.newValue` and `foo(newValue: bar)` aren't usages of the closure argument
            if last(.nonSpaceOrCommentOrLinebreak, before: index)?.isOperator(".") == true {
                continue
            }
            if next(.nonSpaceOrCommentOrLinebreak, after: index) == .delimiter(":") {
                guard currentScope(at: index) == .startOfScope("(") else { return nil }
                continue
            }
            usages.append(index)
        }

        // If the new value is unused then the arguments can simply be removed
        if newValue == .identifier("_") || usages.isEmpty {
            return []
        }

        // The observed value is read again wherever the argument was used, so it must be a stored
        // property. Reading a computed property again could be expensive or return a different value.
        let observedValue = tokens[onChange.observedValueRange]
        guard isStoredPropertyOfEnclosingType(observedValue, at: onChange.closureStartIndex) else { return nil }

        // A local declaration that shadows the argument, or the root of the observed value,
        // means later references may no longer refer to the same value.
        let shadowableNames = [newValue, observedValue.first(where: { $0 != .identifier("self") }) ?? newValue]
        for index in bodyRange where [.keyword("let"), .keyword("var"), .keyword("for")].contains(tokens[index]) {
            let endOfPattern = self.index(after: index, where: {
                $0.isLinebreak || $0.isOperator("=") || $0 == .keyword("in") || $0 == .keyword("else") || $0 == .startOfScope("{")
            }) ?? endOfClosure
            if tokens[index ..< endOfPattern].contains(where: shadowableNames.contains) {
                return nil
            }
        }

        // The argument is a snapshot of the new value, but the observed value is read again each
        // time it's used. Only replace usages that are evaluated immediately when the closure is
        // called: those that aren't in a nested closure and aren't preceded by another statement.
        for usage in usages {
            guard !isInNestedClosure(at: usage, closureStartIndex: onChange.closureStartIndex),
                  !isPrecededByStatement(at: usage, in: bodyRange)
            else { return nil }
        }

        return usages
    }

    /// Whether the given tokens are a reference to a stored property of the type that contains
    /// the given index, like `foo` or `self.foo`, where the property is declared in the same file.
    /// Other values, like `foo.bar`, may be computed properties declared in another file.
    func isStoredPropertyOfEnclosingType(_ observedValue: ArraySlice<Token>, at index: Int) -> Bool {
        let components = observedValue.map(\.string)
        guard components.count == 1 || (components.count == 3 && components[0] == "self" && components[1] == "."),
              let propertyToken = observedValue.last,
              propertyToken.isIdentifier,
              propertyToken != .identifier("self"),
              !propertyToken.string.hasPrefix("$")
        else { return false }

        // Find the body of the type that contains the `onChange` call
        var scopeIndex = startOfScope(at: index)
        while let currentScopeIndex = scopeIndex, !isStartOfTypeBody(at: currentScopeIndex) {
            scopeIndex = startOfScope(at: currentScopeIndex)
        }
        guard let typeBodyStart = scopeIndex,
              let typeBodyEnd = endOfScope(at: typeBodyStart)
        else { return false }

        var typeBodies = [typeBodyStart ... typeBodyEnd]

        // The stored properties of an extended type are declared in the type itself
        if lastSignificantKeyword(at: typeBodyStart, excluding: ["where"]) == "extension" {
            guard let extensionIndex = indexOfLastSignificantKeyword(at: typeBodyStart, excluding: ["where"]),
                  let typeNameIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, after: extensionIndex),
                  tokens[typeNameIndex].isIdentifier,
                  next(.nonSpaceOrCommentOrLinebreak, after: typeNameIndex)?.isOperator(".") != true
            else { return false }

            let extendedTypeBodies = tokens.indices.compactMap { keywordIndex -> ClosedRange<Int>? in
                guard ["struct", "class", "actor", "enum"].contains(tokens[keywordIndex].string),
                      tokens[keywordIndex].isKeyword,
                      next(.nonSpaceOrCommentOrLinebreak, after: keywordIndex) == tokens[typeNameIndex],
                      let bodyStart = self.index(of: .startOfScope("{"), after: keywordIndex),
                      isStartOfTypeBody(at: bodyStart),
                      indexOfLastSignificantKeyword(at: bodyStart, excluding: ["where"]) == keywordIndex,
                      let bodyEnd = endOfScope(at: bodyStart)
                else { return nil }
                return bodyStart ... bodyEnd
            }

            guard extendedTypeBodies.count == 1 else { return false }
            typeBodies += extendedTypeBodies
        }

        // The type must declare a stored property with this name, and no other declaration
        // with the same name in the type can be a computed property that would shadow it.
        var hasStoredProperty = false
        for typeBody in typeBodies {
            for introducerIndex in typeBody where [.keyword("let"), .keyword("var")].contains(tokens[introducerIndex]) {
                guard let property = parsePropertyDeclaration(atIntroducerIndex: introducerIndex),
                      property.identifier == propertyToken.string
                else { continue }

                guard isStoredProperty(atIntroducerIndex: introducerIndex) else { return false }

                if startOfScope(at: introducerIndex) == typeBody.lowerBound {
                    hasStoredProperty = true
                }
            }
        }

        return hasStoredProperty
    }

    /// Whether a complete statement in the given closure body is executed before the token at the given index
    func isPrecededByStatement(at index: Int, in bodyRange: Range<Int>) -> Bool {
        // The scopes that contain the given index. Statements in other scopes,
        // like a different branch of an `if` statement, aren't executed before it.
        var enclosingScopes = Set<Int>()
        var scopeIndex = startOfScope(at: index)
        while let currentScopeIndex = scopeIndex, currentScopeIndex >= bodyRange.lowerBound - 1 {
            enclosingScopes.insert(currentScopeIndex)
            scopeIndex = startOfScope(at: currentScopeIndex)
        }
        if let closureStartIndex = scopeIndex {
            enclosingScopes.insert(closureStartIndex)
        }

        for separatorIndex in bodyRange.lowerBound ..< index
            where tokens[separatorIndex].isLinebreak || tokens[separatorIndex] == .delimiter(";")
        {
            guard let scope = startOfScope(at: separatorIndex),
                  enclosingScopes.contains(scope),
                  let previousToken = self.index(of: .nonSpaceOrCommentOrLinebreak, before: separatorIndex),
                  previousToken >= bodyRange.lowerBound,
                  !tokens[previousToken].isStartOfScope,
                  let nextToken = self.index(of: .nonSpaceOrCommentOrLinebreak, after: separatorIndex)
            else { continue }

            if tokens[separatorIndex] == .delimiter(";")
                || (isEndOfStatement(at: previousToken) && isStartOfStatement(at: nextToken))
            {
                return true
            }
        }
        return false
    }

    /// Whether the given index is inside a closure nested within the closure at the given index
    func isInNestedClosure(at index: Int, closureStartIndex: Int) -> Bool {
        var scopeIndex = startOfScope(at: index)
        while let currentScopeIndex = scopeIndex, currentScopeIndex > closureStartIndex {
            if isStartOfClosure(at: currentScopeIndex) {
                return true
            }
            scopeIndex = startOfScope(at: currentScopeIndex)
        }
        return false
    }

    /// Removes the closure arguments in the given range, which ends with the `in` keyword,
    /// along with the whitespace that separated them from the rest of the closure.
    func removeClosureArguments(in argumentsRange: ClosedRange<Int>) {
        removeTokens(in: argumentsRange)

        // `{ _, _ in foo() }` -> `{ foo() }` and `{ _, _ in⏎` -> `{⏎`
        var index = argumentsRange.lowerBound
        if token(at: index - 1)?.isSpace == true, token(at: index)?.isSpaceOrLinebreak == true {
            removeToken(at: index - 1)
            index -= 1
        }

        // `{⏎ _, _ in⏎ foo()` -> `{⏎ foo()`
        if token(at: index - 1)?.isLinebreak == true, token(at: index)?.isLinebreak == true {
            removeToken(at: index)
        }
    }
}
