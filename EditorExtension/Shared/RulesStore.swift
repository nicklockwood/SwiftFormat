//
//  RulesStore.swift
//  SwiftFormat
//
//  Created by Vincent Bernier on 28-01-18.
//  Copyright 2018 Nick Lockwood
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

extension UserDefaults {
    static let groupDomain = "com.charcoaldesign.SwiftFormat"

    func clearAll(in domainName: String) {
        persistentDomain(forName: domainName)?.forEach {
            removeObject(forKey: $0.key)
        }
    }
}

struct Rule {
    let name: String
    var isEnabled: Bool
}

extension Rule: Comparable {
    /// Looks up and returns a format rule, if found.
    var formatRule: FormatRule? {
        FormatRules.byName[name]
    }

    var isDeprecated: Bool {
        formatRule?.isDeprecated == true
    }

    /// Space-separated, lowercased text terms that this rule might by found by.
    var searchableText: String {
        var items = [name]
        if let formatRule = formatRule {
            items.append(formatRule.help)
            items.append(formatRule.options.joined(separator: " "))
            items.append(formatRule.sharedOptions.joined(separator: " "))
        }
        return items.joined(separator: " ").lowercased()
    }

    static func < (lhs: Rule, rhs: Rule) -> Bool {
        if lhs.name == rhs.name {
            return lhs.isEnabled
        }

        return lhs.name < rhs.name
    }
}

private extension Rule {
    init(_ ruleRep: (String, Bool)) {
        self.init(name: ruleRep.0, isEnabled: ruleRep.1)
    }
}

struct RulesStore {
    private typealias RuleName = String
    private typealias RuleIsEnabled = Bool
    private typealias RulesRepresentation = [RuleName: RuleIsEnabled]
    private let rulesKey = "rules"
    private let store: UserDefaults

    private static var defaultStore: UserDefaults = {
        guard let defaults = UserDefaults(suiteName: UserDefaults.groupDomain) else {
            fatalError("The UserDefaults Store is invalid")
        }
        return defaults
    }()

    init(_ store: UserDefaults = RulesStore.defaultStore) {
        self.store = store
        setupDefaultValuesIfNeeded()
    }

    var rules: [Rule] {
        load()
            .map { Rule($0) }
            .filter { !$0.isDeprecated }
    }

    func save(_ rule: Rule) {
        save([rule])
    }

    func save(_ rules: [Rule]) {
        var active = Set<String>()
        var disabled = Set<String>()

        for rule in rules {
            if rule.isEnabled {
                active.insert(rule.name)
            } else {
                disabled.insert(rule.name)
            }
        }
        save(active: active, disabled: disabled)
    }

    func restore(_ rules: [Rule]) {
        clear()
        save(rules)
        addNewRulesIfNeeded()
    }

    func resetRulesToDefaults() {
        let allRuleNames = Set(FormatRules.byName.keys)
        let disabledRules = Set(FormatRules.disabledByDefault)
        let activeRules = allRuleNames.subtracting(disabledRules)

        clear()
        save(active: activeRules, disabled: disabledRules)
    }
}

// MARK: - Business Rules

extension RulesStore {
    private func setupDefaultValuesIfNeeded() {
        //  check if first time
        if store.value(forKey: rulesKey) == nil {
            resetRulesToDefaults()
        } else {
            addNewRulesIfNeeded()
        }
    }

    private func addNewRulesIfNeeded() {
        let currentRules = load()
        let currentRuleNames = Set(currentRules.keys)
        let allRuleNames = Set(FormatRules.byName.keys)
        let newRuleNames = allRuleNames.subtracting(currentRuleNames)
        if newRuleNames.isEmpty {
            return
        }

        let disabledRules = Set(FormatRules.disabledByDefault)
        var rules = currentRules
        newRuleNames.forEach {
            rules[$0] = !disabledRules.contains($0)
        }

        save(rules)
    }
}

// MARK: - Store Interactions

extension RulesStore {
    private func clear() {
        store.set(nil, forKey: rulesKey)
    }

    private func load() -> RulesRepresentation {
        guard let rules = store.value(forKey: rulesKey) as? RulesRepresentation else {
            return RulesRepresentation()
        }
        return rules
    }

    /// Save the provided rules
    /// Will only override the rules in the params
    private func save(active: Set<String>, disabled: Set<String>) {
        var rules = load()
        active.forEach { rules[$0] = true }
        disabled.forEach { rules[$0] = false }
        save(rules)
    }

    /// Will replace the rules with the param
    private func save(_ rules: RulesRepresentation) {
        store.set(rules, forKey: rulesKey)
    }
}
