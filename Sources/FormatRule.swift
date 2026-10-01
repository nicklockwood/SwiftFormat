//
//  FormatRule.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 12/08/2016.
//  Copyright 2016 Nick Lockwood
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/SwiftFormat
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

public final class FormatRule: Hashable, Comparable, CustomStringConvertible {
    static let unnamedRule = "[unnamed rule]"

    private let fn: (Formatter) -> Void
    fileprivate(set) var name = FormatRule.unnamedRule
    fileprivate(set) var index = 0
    fileprivate(set) var directiveNames = Set<String>()
    let help: String
    let examples: String?
    let runOnceOnly: Bool
    let disabledByDefault: Bool
    let usesProjectContext: Bool
    let orderAfter: [FormatRule]
    let options: [String]
    let sharedOptions: [String]
    fileprivate(set) var deprecationMessage: String?
    let renamedTo: FormatRule?

    /// Null rule, used for testing
    static let none: FormatRule = .init(help: "") { _ in } examples: { nil }

    var isDeprecated: Bool {
        deprecationMessage != nil || renamedTo != nil
    }

    var canonicalRule: FormatRule {
        var rule = self
        var visited = Set<ObjectIdentifier>()
        while let renamedTo = rule.renamedTo,
              visited.insert(ObjectIdentifier(rule)).inserted
        {
            rule = renamedTo
        }
        return rule
    }

    public var description: String {
        name
    }

    init(help: String,
         deprecationMessage: String? = nil,
         renamedTo: FormatRule? = nil,
         runOnceOnly: Bool = false,
         disabledByDefault: Bool = false,
         usesProjectContext: Bool = false,
         orderAfter: [FormatRule] = [],
         options: [String] = [],
         sharedOptions: [String] = [],
         _ fn: @escaping (Formatter) -> Void,
         examples: () -> String?)
    {
        self.fn = fn
        self.help = help
        self.runOnceOnly = runOnceOnly
        self.disabledByDefault = disabledByDefault || deprecationMessage != nil || renamedTo != nil
        self.usesProjectContext = usesProjectContext
        self.orderAfter = orderAfter
        self.options = options
        self.sharedOptions = sharedOptions
        self.deprecationMessage = deprecationMessage
        self.renamedTo = renamedTo
        self.examples = examples()
    }

    public func apply(with formatter: Formatter) {
        formatter.currentRule = self
        fn(formatter)
        formatter.currentRule = nil
    }

    public static func == (lhs: FormatRule, rhs: FormatRule) -> Bool {
        lhs === rhs
    }

    public static func < (lhs: FormatRule, rhs: FormatRule) -> Bool {
        lhs.index < rhs.index
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

public let FormatRules = _FormatRules()

private let rulesByName: [String: FormatRule] = {
    var rules = [String: FormatRule]()
    for (name, rule) in ruleRegistry {
        rule.name = name
        rules[name] = rule
    }
    for rule in rules.values {
        assert(rule.name != "[unnamed rule]")
        if rule.deprecationMessage == nil, let renamedTo = rule.renamedTo {
            rule.deprecationMessage = "Renamed to `\(renamedTo.name)`."
        }
        rule.canonicalRule.directiveNames.insert(rule.name.lowercased())
    }
    let values = rules.values.sorted(by: { $0.name < $1.name })
    for (index, value) in values.enumerated() {
        value.index = index * 10
    }
    var changedOrder = true
    while changedOrder {
        changedOrder = false
        for value in values {
            for rule in value.orderAfter {
                if rule.index >= value.index {
                    value.index = rule.index + 1
                    changedOrder = true
                }
            }
        }
    }
    return rules
}()

private func allRules(except rules: [FormatRule]) -> [FormatRule] {
    _allRules.filter { !rules.contains($0) }
}

private let _allRules = rulesByName.sorted(by: { $0.key < $1.key }).map(\.value)
private let _deprecatedRules = _allRules.filter(\.isDeprecated)
private let _disabledByDefault = _allRules.filter(\.disabledByDefault)
private let _defaultRules = allRules(except: _disabledByDefault)

public extension _FormatRules {
    /// A Dictionary of rules by name
    var byName: [String: FormatRule] {
        rulesByName
    }

    /// All rules
    var all: [FormatRule] {
        _allRules
    }

    /// Default active rules
    var `default`: [FormatRule] {
        _defaultRules
    }

    /// Rules that are disabled by default
    var disabledByDefault: [FormatRule] {
        _disabledByDefault
    }

    /// Rules that are deprecated
    var deprecated: [FormatRule] {
        _deprecatedRules
    }

    /// Just the specified rules
    func named(_ names: [String]) -> [FormatRule] {
        Array(Set(names.compactMap { rulesByName[$0]?.canonicalRule })).sorted()
    }

    /// All rules except those specified
    func all(except rules: [FormatRule]) -> [FormatRule] {
        allRules(except: rules)
    }
}

extension _FormatRules {
    /// Resolve renamed rules to their canonical replacement names.
    func canonicalNames(_ names: some Sequence<String>) -> Set<String> {
        Set(names.map { rulesByName[$0]?.canonicalRule.name ?? $0 })
    }

    /// Lowercased current and deprecated names that refer to the same rule.
    func directiveNames(for rule: FormatRule) -> Set<String> {
        rule.canonicalRule.directiveNames
    }

    /// Get all format options used by a given set of rules
    func optionsForRules(_ rules: [FormatRule]) -> [String] {
        var options = Set<String>()
        for rule in rules {
            options.formUnion(rule.options + rule.sharedOptions)
        }
        return options.sorted()
    }

    /// Get shared-only options for a given set of rules
    func sharedOptionsForRules(_ rules: [FormatRule]) -> [String] {
        var options = Set<String>()
        var sharedOptions = Set<String>()
        for rule in rules {
            options.formUnion(rule.options)
            sharedOptions.formUnion(rule.sharedOptions)
        }
        sharedOptions.subtract(options)
        return sharedOptions.sorted()
    }
}

public struct _FormatRules {
    fileprivate init() {}
}
