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
        let options = [FormatOptions.lineBreakDescriptor, FormatOptions.useVoidDescriptor]

        let result = options.map { descriptor -> UserSelectionType in

            switch descriptor.type {
            case let .binary(t, f):
                let binary = UserSelectionBinary(identifier: descriptor.propertyName,
                                                 title: descriptor.name,
                                                 description: nil,
                                                 selection: descriptor.default as! Bool,
                                                 observer: { print("\(descriptor.name) new value == \($0 ? t[0] : f[0])")
                })
                return UserSelectionType.binary(binary)

            case let .list(values):
                let list = UserSelectionList(identifier: descriptor.propertyName,
                                             title: descriptor.name,
                                             description: nil,
                                             selection: descriptor.default as! String,
                                             options: values,
                                             observer: { print("\(descriptor.name) new value == \($0)")
                })
                return UserSelectionType.list(list)
            }
        }

        let wrapArguments = UserSelectionType.list(UserSelectionList(identifier: "wrapArguments",
                                                                     title: "wrapArguments",
                                                                     description: nil,
                                                                     selection: "afterfirst",
                                                                     options: ["beforefirst", "afterfirst", "disabled"],
                                                                     observer: { print("wrapArguments -> new value == \($0)") }))

        let freeTextTest = UserSelectionType.freeText(UserSelectionFreeText(identifier: "freeTextTest",
                                                                            title: "Test",
                                                                            description: nil,
                                                                            selection: "some text",
                                                                            observer: {
                                                                                //  should throttle the saving to not save at every key stroke
                                                                                print("test new value == \($0)")
                                                                            },
                                                                            validationStrategy: { value in
                                                                                value == "bob"
        }))

        return result + [wrapArguments, freeTextTest]
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
