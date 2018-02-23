//
//  RulesViewController.swift
//  SwiftFormat for Xcode
//
//  Created by Vincent Bernier on 27/01/18.
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

import Cocoa

/// Goal: Display Active & Inactive Rules and allow their state to be modified
final class RulesViewController: NSViewController {
    private var ruleViewModels = [UserSelectionType]()

    @IBOutlet var tableView: NSTableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let allRules = buildRules()
        let allOptions = buildOptions()

        let ruleHeader = UserSelectionType.none(UserSelection(identifier: "rule header",
                                                              title: "Rules",
                                                              description: nil))
        let optionHeader = UserSelectionType.none(UserSelection(identifier: "Option Header",
                                                                title: "Options",
                                                                description: nil))

        ruleViewModels = [ruleHeader] + allRules + [optionHeader] + allOptions
    }

    private func buildRules() -> [UserSelectionType] {
        let store = RulesStore()
        let rules: [UserSelectionType] = store
            .rules
            .sorted()
            .map { rule in
                let d = UserSelectionBinary(identifier: rule.name,
                                            title: rule.name,
                                            description: nil,
                                            selection: rule.isEnabled,
                                            observer: {
                                                var updatedRule = rule
                                                updatedRule.isEnabled = $0
                                                store.save(updatedRule)
                })
                return UserSelectionType.binary(d)
            }

        return rules
    }

    private func buildOptions() -> [UserSelectionType] {
        let store = OptionsStore()
        let result = store
            .options
            .sorted()
            .map { option -> UserSelectionType in
                let descriptor = option.descriptor
                let selection = option.argumentValue
                let observer: (String) -> Void = {
                    var opt = option
                    opt.argumentValue = $0
                    store.save(opt)
                }

                switch descriptor.type {
                case let .binary(t, f):
                    let list = UserSelectionList(identifier: descriptor.id,
                                                 title: descriptor.name,
                                                 description: nil,
                                                 selection: selection,
                                                 options: [t[0], f[0]],
                                                 observer: observer)
                    return UserSelectionType.list(list)

                case let .list(values):
                    let list = UserSelectionList(identifier: descriptor.id,
                                                 title: descriptor.name,
                                                 description: nil,
                                                 selection: selection,
                                                 options: values,
                                                 observer: observer)
                    return UserSelectionType.list(list)

                case let .freeText(validationStrategy: validation):
                    let freeText = UserSelectionFreeText(identifier: descriptor.id,
                                                         title: descriptor.name,
                                                         description: nil,
                                                         selection: selection,
                                                         observer: observer,
                                                         validationStrategy: validation)
                    return UserSelectionType.freeText(freeText)
                }
        }

        return result
    }

    func model(forRow row: Int) -> UserSelectionType {
        return ruleViewModels[row]
    }
}

// MARK: - Table View Data Source

extension RulesViewController: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        return ruleViewModels.count
    }

    func tableView(_: NSTableView, objectValueFor _: NSTableColumn?, row: Int) -> Any? {
        return model(forRow: row).associatedValue()
    }
}

// MARK: - Table View Delegate

extension RulesViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
        let model = self.model(forRow: row)
        let ID: NSUserInterfaceItemIdentifier
        switch model {
        case .none:
            ID = .headerTableCellView
        case .binary:
            ID = .mainBinarySelectionTableCellView
        case .list:
            ID = .listSelectionTableCellView
        case .freeText:
            ID = .freeTextTableCellView
        }

        return tableView.makeView(withIdentifier: ID, owner: self)
    }
}
