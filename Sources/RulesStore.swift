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
    static let groupDomain = "com.charcoaldesign.xcode-swift-formatter"

    /// Nuke for dev purposes
    func clearAll(in domainName: String) {
        guard let entries = persistentDomain(forName: domainName) else { return }
        for (key, _) in entries {
            set(nil, forKey: key)
        }
    }
}

struct Rule {
    let name: String
    var isActive: Bool
}

extension Rule: Comparable {
    static func < (lhs: Rule, rhs: Rule) -> Bool {
        if lhs.name == rhs.name {
            return lhs.isActive
        }

        return lhs.name < rhs.name
    }

    static func == (lhs: Rule, rhs: Rule) -> Bool {
        return
            lhs.name == rhs.name &&
            lhs.isActive == rhs.isActive
    }
}

extension Rule {
    fileprivate init(_ ruleRep: (String, Bool)) {
        self.init(name: ruleRep.0, isActive: ruleRep.1)
    }
}

struct RulesStore {

    private typealias RulesRepresentation = [String: Bool]
    private let rulesKey = "rules"
    private let store: UserDefaults

    init(_ store: UserDefaults? = UserDefaults(suiteName: UserDefaults.groupDomain)) {
        guard let store = store else {
            fatalError("The UserDefaults Store is invalid")
        }
        self.store = store
        setupDefaultValuesIfNeeded()
    }

    var rules: [Rule] {
        return load().map { Rule($0) }
    }

    func save(_ rule: Rule) {
        var active = Set<String>()
        var disabled = Set<String>()
        if rule.isActive {
            active.insert(rule.name)
        } else {
            disabled.insert(rule.name)
        }
        save(active: active, disabled: disabled)
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

    private func resetRulesToDefaults() {
        let allRuleNames = Set(FormatRules.byName.keys)
        let disabledRules = Set(FormatRules.disabledByDefault)
        let activeRules = allRuleNames.subtracting(disabledRules)

        clear()
        save(active: activeRules, disabled: disabledRules)
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

    /// Will replace rhe rules with the param
    private func save(_ rules: RulesRepresentation) {
        store.set(rules, forKey: rulesKey)
    }
}
